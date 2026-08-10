---
description: Provision and use DynamoDB end to end — per-entity tables in Terraform rather than single-table design, on-demand billing, GSIs, PITR and TTL, the IAM grant that turns a Scan into a runtime failure, the client singleton, key and sparse-GSI queries, and cursor pagination over LastEvaluatedKey. Use when adding a table or index, replacing a Scan, choosing a billing mode, or paginating a list endpoint. Not for the cache tier beside it (see redis-cache, elasticache).
---

Provision, model and query DynamoDB — the whole lifecycle of one table.

Context: $ARGUMENTS

**One skill, both sides**, because in DynamoDB they are not separable: the access pattern decides the
key schema, the key schema is declared in Terraform, and the IAM grant written beside the table is what
makes a wrong query fail at runtime rather than merely run slowly. Provisioning module:
**`terraform-aws-modules/dynamodb-table/aws ~> 4.0`** (one call per table). DynamoDB replaces DocumentDB
here — chosen for cost: **on-demand (`PAY_PER_REQUEST`) is ~$0 at idle**, where a DocumentDB cluster is
a fixed ~$54/mo always-on instance that spiky, low-volume traffic cannot justify.

## Per-entity tables (not single-table)

One table per entity — maps 1:1 to the domain aggregates, each evolves independently, and on-demand
makes the extra tables free at rest. Single-table design is the at-scale DynamoDB pattern; a workload
of this size does not need its modeling complexity.

**Entity names are always English** — the table, its hash/range keys, GSI partition values, and the
matching TS type/repository all use the English domain noun (`polls`/`poll_id`/`gsi_pk="POLL"`, never a
localized spelling), **even when the product surface is in another language** (the UI label can be
translated; the data entity stays `polls`). This keeps the schema, code, IAM ARNs, and parameter-store
keys in one language and consistent with the snake_case-everywhere rule. Why English: the AWS/TS
ecosystem and most contributors default to it, and mixing languages in identifiers is the kind of drift
that is expensive to undo once tables exist (rename = new table + backfill). The repository and TS type
names follow the table, not the UI.

| Table | Hash / Range | GSIs | Purpose |
|---|---|---|---|
| `profile` | `profile_id` | — | the CV document (effectively one item) |
| `posts` | `post_id` | `by-created` (`gsi_pk`="POST" / `created_at`) | feed, newest-first via cursor |
| `articles` | `article_id` | `by-slug` (`slug`), `by-tag` (`tag` / `created_at`) | slug routing + tag queries |
| `subscriptions` | `email` | `by-status` (`status` / `email`), `by-cognito` (`cognito_sub`) | newsletter opt-ins |
| `audits` | `audit_id` | `by-entity` (`entity` / `created_at`), `by-actor` (`actor` / `created_at`) | audit trail (`/audit-middleware`) |

Feed ordering uses a GSI with a **constant partition** (`gsi_pk="POST"`) + `created_at` range so a
single `Query` returns newest-first; fine at this scale (revisit if a single partition gets hot).

## Table configuration (the arguments set on every table)

```hcl
module "posts_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 4.0"

  name         = "<project>-posts-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"            # on-demand — ~$0 idle, no capacity planning

  hash_key  = "post_id"
  attributes = [
    { name = "post_id",    type = "S" },
    { name = "gsi_pk",     type = "S" },
    { name = "created_at", type = "S" },
  ]
  global_secondary_indexes = [{
    name            = "by-created"
    hash_key        = "gsi_pk"
    range_key       = "created_at"
    projection_type = "ALL"
  }]

  # encryption at rest — AWS-managed aws/dynamodb KMS key ("" CMK = managed; /kms)
  server_side_encryption_enabled     = true
  server_side_encryption_kms_key_arn = null

  # continuous backups / restore
  point_in_time_recovery_enabled = true

  deletion_protection_enabled = var.environment == "production"
}
```

**Choices that matter:** `PAY_PER_REQUEST` (the whole reason for the pivot — no idle cost, no RCU/WCU
planning); **per-entity tables**; GSIs `projection_type = "ALL"` (read-through without a second fetch —
storage is cheap at this volume); **PITR on** (continuous backup, 35-day window, restore = new table);
`deletion_protection` gated on env.

**Only key attributes are declared.** DynamoDB is **schemaless except for keys**, so `attributes` lists
exactly the table and GSI keys and nothing else — the rest of the aggregate is just stored. This is the
seam between the two halves of this skill: adding a field is a code-only change, adding a *query* is a
Terraform change.

## TTL (where it applies)

```hcl
# audits table only — expire trail entries after the retention window
ttl_enabled        = true
ttl_attribute_name = "ttl"      # epoch seconds; the app sets it on write (/audit-middleware)
```

TTL is a table argument and an application obligation at once: Terraform enables it and names the
attribute, and the write path has to actually set it. Enabling it alone expires nothing.

## Access is IAM — and that is why `Scan` is a hard error, not a slow one

DynamoDB has **no master user and no connection secret**. The function's execution role gets
`dynamodb:GetItem|PutItem|UpdateItem|DeleteItem|Query|BatchGetItem` scoped to **exactly these table ARNs
plus their `/index/*`** (`/iam`) — never `dynamodb:*` on `*`, and **never `Scan`**. So
there is no Secrets Manager entry for the data tier and nothing to rotate.

The consequence is the single most useful thing to know about this pair of concerns:

> **A `Scan` does not degrade — it fails.** The role grants no `dynamodb:Scan`, so a Scan raises
> `AccessDeniedException` and surfaces as a 500. There is **no "low-volume exception"**: this exact trap
> once took a feed down, because a list endpoint Scanned a table everyone agreed was small.

A Scan would be wrong even if it were permitted — it reads the WHOLE table and filters after, so cost
and latency scale with table **size**, not with the result. The grant is what makes the rule
unavoidable instead of merely advised, and it is the reason a new query shape is a **Terraform** change:
you cannot work around a missing index in application code.

## Client singleton

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

`@aws-sdk/lib-dynamodb` (`DynamoDBDocumentClient`) marshals plain JS objects ⇄ DynamoDB attribute
types, so repositories work in snake_case JS and never touch `{ S: ... }` wire shapes.

## Table names travel through the config bus

Infrastructure writes them, the deploy job reads them, the code never spells them. Both ends of that
path are here so neither can drift:

```hcl
# infrastructure writes the names (/ssm) — non-sensitive, names only
# /${env}/data/profile-table-name       = module.profile_table.dynamodb_table_id
# /${env}/data/posts-table-name         = module.posts_table.dynamodb_table_id
# /${env}/data/articles-table-name      = module.articles_table.dynamodb_table_id
# /${env}/data/subscriptions-table-name = module.subscriptions_table.dynamodb_table_id
# /${env}/data/audits-table-name        = module.audits_table.dynamodb_table_id
```

```typescript
// the application deploy job reads them into the function environment; one accessor, no literals
export const TABLES = {
  profile:       process.env.PROFILE_TABLE!,
  posts:         process.env.POSTS_TABLE!,
  articles:      process.env.ARTICLES_TABLE!,
  subscriptions: process.env.SUBSCRIPTIONS_TABLE!,
  audits:        process.env.AUDITS_TABLE!,
} as const;
```

Repositories reference `TABLES.x` — no scattered table-name string literals in handlers, and a table
renamed in Terraform reaches the code without a code change (`/environment-config`).

## Item conventions

- **snake_case attributes** everywhere (table = TS type = JSON) — no mapping layer.
- Each table's hash key is the entity id (`profile_id`, `post_id`, `article_id`); `subscriptions` is
  keyed by `email`. Timestamps `created_at` / `updated_at` as ISO-8601 strings (sortable).
- Attributes that are not keys exist only in the code's type — see the schemaless note above.

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

**`Query`/`GetItem` only.** Every list access has a matching GSI declared in the table configuration
above. Read-heavy reads go through cache-aside (`/redis-cache`).

### "List all published, newest-first" — sparse `by-created` GSI (NOT a Scan)

The pattern used by both `posts` and `articles`, and the clearest case of the two halves meeting. A
constant partition key (`gsi_pk = "POST"` / `"ARTICLE"`) is written **only when the item should appear
in the list** (i.e. iff `published`), with `created_at` as the range key. The index is **sparse**
(drafts carry no `gsi_pk`, so they are absent), so a single `Query` returns exactly the published items,
newest-first, paginated — no Scan, no `FilterExpression`.

```typescript
// write: set the sparse key iff published; removeUndefinedValues drops it when not (→ leaves the index)
const item = { ...entity, gsi_pk: entity.published ? 'ARTICLE' : undefined };
// read: Query the sparse GSI (no Scan, no filter)
await ddb.send(new QueryCommand({
  TableName: TABLES.articles, IndexName: 'by-created', ScanIndexForward: false, Limit,
  KeyConditionExpression: 'gsi_pk = :pk', ExpressionAttributeValues: { ':pk': 'ARTICLE' },
}));
```

Adding such a GSI to an existing table is online in Terraform, but **backfill** the key on already-stored
rows (a one-off migration) or they will not appear until the next write. Sparseness is a property of the
data, not of the index declaration — nothing in the HCL says "only published", so a bug that always sets
`gsi_pk` silently publishes drafts.

## Cursor pagination (server-side — `LastEvaluatedKey`)

The opaque cursor is the base64 of DynamoDB's `LastEvaluatedKey`; feed lists use the `by-created` GSI
(constant PK + `created_at`):

```typescript
const res = await ddb.send(new QueryCommand({
  TableName: TABLES.posts, IndexName: 'by-created', ScanIndexForward: false, Limit: limit,
  KeyConditionExpression: 'gsi_pk = :p', ExpressionAttributeValues: { ':p': 'POST' },
  ExclusiveStartKey: cursor ? JSON.parse(Buffer.from(cursor, 'base64').toString()) : undefined,
}));
const next_cursor = res.LastEvaluatedKey
  ? Buffer.from(JSON.stringify(res.LastEvaluatedKey)).toString('base64') : null;
return { items: res.Items ?? [], next_cursor };   // snake_case; client side = /pagination
```

Cursor-native — `LastEvaluatedKey` is exactly a continuation token (no offset/skip, no count query).

## Writes & consistency

- **Create with a guard:** `PutCommand` + `ConditionExpression: 'attribute_not_exists(post_id)'` so a
  retry does not clobber.
- **Partial update:** `UpdateCommand` with `SET`/`REMOVE` expressions — never read-modify-write a whole
  item.
- **Optimistic concurrency** where needed: a `version` attribute + `ConditionExpression: 'version = :v'`.
- Throw `AppError`/`NotFoundError` — never return 4xx (`/error-handling`).

## Network

DynamoDB is a **regional service**. With the function non-VPC (the default), it is reached over the
**public DynamoDB endpoint with IAM** (no NAT, no VPC endpoint — there is no VPC). **When in-VPC** (e.g.
once Redis or a relational store forces a VPC), it is reached over a **Gateway VPC endpoint** (like S3)
— traffic stays on the AWS backbone, **off the NAT path** (`/vpc` declares the `dynamodb`
Gateway endpoint alongside `s3`). HTTPS/TLS in transit by default either way (`/kms`).

## Gotchas

- **No `Scan`** in request paths; design a GSI instead. Each GSI costs storage + write amplification —
  add only for a real access pattern.
- Restore = launch a **new** table from PITR or a backup (no in-place restore) — update the published
  table name after, or the code keeps reading the old one.
- **Lambda@Edge cannot reach DynamoDB at low latency** — prerender/OG data is served by the regional
  API, not the edge (`/og-edge-handler`).
- A single-partition GSI (feed `gsi_pk="POST"`) is fine at this scale; shard the PK if it ever gets hot.
- Tags via provider `default_tags` (`/terraform`); encryption stance
  `/kms` (AWS-managed `aws/dynamodb` key, no CMK).

## Rationale — DynamoDB over DocumentDB (cost-driven reversal)

DocumentDB is a fixed-cost always-on cluster (~$54/mo for a small instance, before replicas/backup) —
unviable for a low, spiky workload. DynamoDB on-demand bills per request and **costs effectively nothing
at idle**, scales to zero operationally, is IAM-auth (no creds/secret/SG), and needs no VPC instance.
Trade-off: access patterns must be designed up front (no ad-hoc queries or joins); rich document
querying gives way to key+GSI access. For known patterns (profile read, feed list, article
by-slug/by-tag) that fits cleanly.

## Decision & trade-off

- **Per-entity tables + GSIs over single-table design.** One table per domain aggregate, with a GSI per
  access pattern. *Why:* simpler mental model, each entity evolves and is capacity-isolated
  independently, and on-demand makes the extra tables free at rest. *Trade-off:* gives up single-table's
  cross-entity transactional reads and its at-scale efficiency — and there is no cross-entity
  transactional read in one call, so aggregation happens in the API's shaping layer (`/bff`).
- **On-demand (`PAY_PER_REQUEST`) over provisioned = scale-to-zero.** Bills per request, ~$0 idle, no
  RCU/WCU planning. *Trade-off:* per-request pricing is **costlier than provisioned at sustained high
  steady load** — not this traffic regime, so the trade is worth it.
- **Access patterns are fixed at design time, and the IAM grant enforces it.** Key + GSI only; a new
  query shape means a new GSI (+ possible backfill) and therefore a Terraform change, not a code
  change. *Trade-off:* no ad-hoc queries or joins — modeling rigidity in exchange for cost and latency
  that track the result, not the table. This is the one decision that cannot be taken on either side
  alone, which is why the two halves are one skill.
- **Per-entity repositories over a shared data layer; one module owns one entity's access.** Keeps the
  modular monolith clean and each entity's keys and GSIs local to the code that needs them.
  *Trade-off:* the mapping from table to repository is a convention, not something the compiler checks.
- **Cursor pagination via the opaque base64 `LastEvaluatedKey`** — the continuation token IS the cursor,
  so there is no offset/skip and no count query. *Trade-off:* no random-access "page N" jumps;
  forward/continuation paging only (the contract the client consumes — `/pagination`).

## Pros & cons

**Pros**
- On-demand = ~$0 idle, no capacity planning; scales automatically.
- IAM-auth end to end — no credentials, no Secrets Manager entry, no security group, nothing to rotate;
  a Gateway endpoint keeps traffic off NAT when in-VPC.
- Client singleton reused across invocations; snake_case items with no mapping layer.
- Cursor-native pagination (`LastEvaluatedKey`); managed PITR; encryption at rest + TLS by default.

**Cons**
- Access patterns fixed at design time — a new query shape needs a new GSI, a backfill, and an
  infrastructure deploy before the code can use it.
- No joins or ad-hoc queries; `Scan` is an anti-pattern **and** an `AccessDeniedException`.
- Per-request cost can exceed provisioned at sustained high volume (not this workload).
- Sparse-index correctness lives in application code, so infrastructure review cannot catch it.
