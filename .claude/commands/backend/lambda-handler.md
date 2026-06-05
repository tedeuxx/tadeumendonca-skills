Implement a Lambda function in tadeumendonca-api.

Function: $ARGUMENTS (e.g., "posts", "articles", "notifications")

Built on **Hono** — see `/backend/framework` for the app/adapter/middleware pattern.

## Files to create

**`src/functions/{name}/index.ts`** — Hono app + routes + aws-lambda adapter:
```typescript
import { Hono } from 'hono';
import { handle, type LambdaBindings } from 'hono/aws-lambda';
import { loggerContext } from '../../shared/middleware/logger';
import { errorHandler } from '../../shared/middleware/error';
import { audit } from '../../shared/middleware/audit';
import { ActionType } from '../../shared/constants/action-types';
import { list, create } from './handler';

const app = new Hono<{ Bindings: LambdaBindings }>();
app.use('*', loggerContext());
app.onError(errorHandler);

app.get('/{name}',  audit(ActionType.{NAME}_LIST),   list);
app.post('/{name}', audit(ActionType.{NAME}_CREATE), create);

export const handler = handle(app);
```

**`src/functions/{name}/handler.ts`** — Hono route handlers (context → repository):
```typescript
export const list = async (c: Context<{ Bindings: LambdaBindings }>) =>
  c.json(await repository.list(c.req.query('cursor')));
```

**`src/functions/{name}/repository.ts`** — DocumentDB queries (`getCollections()` from shared/db); cache-aside where read-heavy (`/backend/redis-cache`).

**`src/functions/{name}/__tests__/handler.test.ts`** — vitest unit tests.

## Mandatory conventions
- snake_case everywhere — DB field = TS field = JSON field (no mapping layer).
- ActionType declared in `action-types.ts`, passed statically to `audit()` — never derived from method/path (`/backend/action-types`).
- HTTP errors: throw `AppError`/`NotFoundError`/`UnauthorizedError` — never `c.json({...}, 4xx)` inline; let `app.onError` map it (`/backend/error-handling`).
- SDK clients (Mongo, SecretsManager, Redis) module-level, never inside a handler.
- JWT group check before mutation via `c.env.event.requestContext.authorizer?.jwt?.claims['cognito:groups']`.
- Sensitive values from Secrets Manager (`/backend/secrets-management`); non-secret config from `/backend/environment-config`.
- og-edge: NO Hono / middleware / VPC — it's Lambda@Edge (`/backend/og-edge-handler`).
