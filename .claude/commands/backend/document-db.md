Connect to and access DocumentDB in tadeumendonca-api.

Context: $ARGUMENTS

The MongoDB-compatible data layer for the BFF: connection, collections, document conventions, queries, indexes, and cursor pagination. Provisioning is `/infrastructure/documentdb-cluster`; creds come via `/backend/secrets-management`.

## Connection singleton: `src/shared/db/client.ts`
```typescript
import { MongoClient } from 'mongodb';
import { getSecret } from '../secrets';                       // /backend/secrets-management

let client: MongoClient | null = null;
export async function getDb() {
  if (!client) {
    const { username, password, host, port, dbname } = await getSecret(process.env.DOCDB_SECRET_ARN!);
    client = new MongoClient(`mongodb://${username}:${encodeURIComponent(password)}@${host}:${port}/${dbname}`, {
      tls: true,
      tlsCAFile: '/etc/pki/tls/certs/ca-bundle.crt',
      retryWrites: false,      // DocumentDB: not supported
      directConnection: true,  // DocumentDB: required in Lambda
    });
    await client.connect();
  }
  return client.db('tadeumendonca');
}
```
Module-level singleton — reused across warm invocations; never connect inside a handler.

## Collections accessor: `src/shared/db/collections.ts`
```typescript
export async function getCollections() {
  const db = await getDb();
  return {
    profiles:    db.collection<Profile>('profiles'),
    posts:       db.collection<Post>('posts'),
    articles:    db.collection<Article>('articles'),
    subscribers: db.collection<Subscriber>('subscribers'),
    audits:      db.collection<Audit>('audits'),
  };
}
```
Repositories use this accessor — no scattered `db.collection('…')` string literals in handlers.

## Document conventions
- **snake_case fields** everywhere (DB = TS type = JSON) — no mapping layer.
- `_id`: ObjectId, or a domain slug for articles (`_id = slug`); timestamps `created_at` / `updated_at` (ISODate).
- One document models the whole aggregate (nested sub-docs) — the reason for DocumentDB over DynamoDB (`/infrastructure/documentdb-cluster`).

## Queries (repository pattern, per module)
```typescript
posts.find({ status: 'published' }).sort({ created_at: -1 }).limit(20).toArray();  // feed
articles.findOne({ _id: slug });                                                   // by slug (unique)
articles.find({ status: 'published', tags: tag }).sort({ created_at: -1 });        // by tag (multikey)
```
Project only what the screen needs — the BFF shapes responses (`/backend/bff`). Read-heavy queries go through cache-aside (`/backend/redis-cache`).

## Cursor pagination (server-side — not offset)
Opaque cursor over the **indexed** sort key; the range query stays index-efficient (`.skip(n)` scans and discards):
```typescript
const filter = cursor ? { _id: { $lt: new ObjectId(cursor) } } : {};
const page = await posts.find({ status: 'published', ...filter }).sort({ _id: -1 }).limit(limit + 1).toArray();
const next_cursor = page.length > limit ? page.pop()!._id.toString() : null;
return { items: page, next_cursor };          // snake_case; frontend side = /frontend/pagination
```
Cursors survive re-ordering where offset breaks.

## Indexes
- `posts`: `{ status: 1, created_at: -1 }`, `{ _id: -1 }`.
- `articles`: `_id` (slug, unique), `{ status: 1, tags: 1, created_at: -1 }`.
- `subscribers`: `{ cognito_sub: 1 }` (unique), `{ status: 1 }`.
- `audits`: see `/backend/audit-middleware` (+ TTL).
Define them in `shared/db/indexes.ts`, ensured at cold start or by the seed script.

## Gotchas
- `retryWrites: false` mandatory (DocumentDB doesn't support retryable writes).
- `directConnection: true` avoids topology-discovery issues in Lambda.
- `DOCDB_SECRET_ARN` set by IaC (api.tf) — never hardcode; creds via `/backend/secrets-management`.
- TLS CA path is for the Lambda runtime; **og-edge (Lambda@Edge) cannot reach DocumentDB** (no VPC).
