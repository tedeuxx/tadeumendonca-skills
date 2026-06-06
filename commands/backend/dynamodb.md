Connect to and access DynamoDB in <project>-api.

Context: $ARGUMENTS

The data layer for the BFF: one DynamoDB **client singleton**, **per-entity repositories**, key/GSI access, snake_case items, and cursor pagination. Provisioning + table/GSI design is `/infrastructure/dynamodb`. **No credentials** — access is IAM via the Lambda exec role (`/infrastructure/iam`); there is no Secrets Manager entry for the data tier.

## Client singleton: `src/shared/db/client.ts`
```typescript
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb';

// Module-level singleton — reused across warm invocations (connection keep-alive). Never construct
// inside a handler. No connect()/secret: the SDK signs with the exec-role creds from the runtime.
const base = new DynamoDBClient({});
export const ddb = DynamoDBDocumentClient.from(base, {
  marshallOptions: { removeUndefinedValues: true },
});
```
`@aws-sdk/lib-dynamodb` (`DynamoDBDocumentClient`) marshals plain JS objects ⇄ DynamoDB attribute types, so repositories work in snake_case JS and never touch `{ S: ... }` wire shapes.

## Table-name accessor: `src/shared/db/tables.ts`
```typescript
// Names come from SSM → Lambda env at deploy (/infrastructure/ssm). Never hardcode.
export const TABLES = {
  profile:       process.env.PROFILE_TABLE!,
  posts:         process.env.POSTS_TABLE!,
  articles:      process.env.ARTICLES_TABLE!,
  subscriptions: process.env.SUBSCRIPTIONS_TABLE!,
  audits:        process.env.AUDITS_TABLE!,
} as const;
```
Repositories reference `TABLES.x` — no scattered table-name string literals in handlers.

## Item conventions
- **snake_case attributes** everywhere (table = TS type = JSON) — no mapping layer.
- Each table's hash key is the entity id (`profile_id`, `post_id`, `article_id`); `subscriptions` is keyed by `email`. Timestamps `created_at` / `updated_at` as ISO-8601 strings (sortable).
- DynamoDB is **schemaless except for keys** — only key/GSI attributes are declared in IaC; the rest of the aggregate is just stored.

## Queries (repository pattern, per module)
```typescript
import { GetCommand, PutCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';

// profile (single item)
await ddb.send(new GetCommand({ TableName: TABLES.profile, Key: { profile_id: 'me' } }));

// article by slug — GSI by-slug (slug is unique)
await ddb.send(new QueryCommand({
  TableName: TABLES.articles, IndexName: 'by-slug',
  KeyConditionExpression: 'slug = :s', ExpressionAttributeValues: { ':s': slug }, Limit: 1,
}));

// articles by tag, newest-first — GSI by-tag (tag / created_at)
await ddb.send(new QueryCommand({
  TableName: TABLES.articles, IndexName: 'by-tag', ScanIndexForward: false,
  KeyConditionExpression: 'tag = :t', ExpressionAttributeValues: { ':t': tag },
}));
```
**`Query`/`GetItem` only — never `Scan` in a hot path** (it reads the whole table). Every list access has a matching GSI (`/infrastructure/dynamodb`). Read-heavy reads go through cache-aside (`/backend/redis-cache`). The BFF shapes responses (`/backend/bff`).

## Cursor pagination (server-side — `LastEvaluatedKey`)
The opaque cursor is the base64 of DynamoDB's `LastEvaluatedKey`; feed lists via the `by-created` GSI (constant PK + `created_at`):
```typescript
const res = await ddb.send(new QueryCommand({
  TableName: TABLES.posts, IndexName: 'by-created', ScanIndexForward: false, Limit: limit,
  KeyConditionExpression: 'gsi_pk = :p', ExpressionAttributeValues: { ':p': 'POST' },
  ExclusiveStartKey: cursor ? JSON.parse(Buffer.from(cursor, 'base64').toString()) : undefined,
}));
const next_cursor = res.LastEvaluatedKey
  ? Buffer.from(JSON.stringify(res.LastEvaluatedKey)).toString('base64') : null;
return { items: res.Items ?? [], next_cursor };   // snake_case; frontend side = /frontend/pagination
```
Cursor-native — `LastEvaluatedKey` is exactly a continuation token (no offset/skip).

## Writes & consistency
- **Create with a guard:** `PutCommand` + `ConditionExpression: 'attribute_not_exists(post_id)'` so a retry doesn't clobber.
- **Partial update:** `UpdateCommand` with `SET`/`REMOVE` expressions — never read-modify-write a whole item.
- **Optimistic concurrency** where needed: a `version` attribute + `ConditionExpression: 'version = :v'`.
- Throw `AppError`/`NotFoundError` — never return 4xx (`/backend/error-handling`).

## Gotchas
- **No `Scan`** in request paths; design a GSI instead. Each GSI costs storage + write amplification — add only for a real access pattern.
- Table names come from env (`POSTS_TABLE`, …) set by IaC (api.tf from SSM) — never hardcode.
- **og-edge (Lambda@Edge) cannot reach DynamoDB at low latency** — prerender/OG data is served by the BFF, not the edge (`/backend/og-edge-handler`).
- A single-partition GSI (feed `gsi_pk="POST"`) is fine at this scale; shard the PK if it ever gets hot.

## Pros & cons
**Pros**
- IAM-auth (no creds/secret/SG); client singleton reused across invocations; snake_case items, no mapping.
- Cursor-native pagination (`LastEvaluatedKey`); on-demand scales to zero cost.
**Cons**
- Access patterns fixed up front — a new query shape needs a new GSI (+ backfill).
- No joins / ad-hoc queries; `Scan` is an anti-pattern.
