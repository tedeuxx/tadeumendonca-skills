Implement a domain module in the BFF (tadeumendonca-api).

Module: $ARGUMENTS (e.g., "posts", "articles", "notifications")

The api is **one BFF Lambda** — a single Hono app with routes at the **root** (`/backend/bff`, `/backend/framework`). Add a feature as a **domain module** that registers its routes onto that app — **not** as a separate Lambda.

## The single BFF entry: `src/index.ts`
```typescript
import { OpenAPIHono } from '@hono/zod-openapi';
import { handle, type LambdaBindings } from 'hono/aws-lambda';
import { loggerContext } from './shared/middleware/logger';
import { errorHandler } from './shared/middleware/error';
import { registerPosts } from './modules/posts/routes';
// + registerProfile, registerArticles, registerOgImage, registerPrerender, registerNotifications

const app = new OpenAPIHono<{ Bindings: LambdaBindings }>();
app.use('*', loggerContext());
app.onError(errorHandler);
registerPosts(app);                 // each module mounts its root routes
// …register the rest
export const handler = handle(app); // the one BFF handler
```

## Files per module — `src/modules/{name}/`
- **`routes.ts`** — `register{Name}(app)`: declares the module's routes (`createRoute` + zod), wires `audit(ActionType.{NAME}_*)` + handlers. **Public** routes (public GETs, `/og-meta`, `/prerender`, `/health`) carry no authorizer; **mutations** are admin-only.
- **`handler.ts`** — route handlers (Hono context → repository), shaped for the SPA.
- **`repository.ts`** — DocumentDB queries (`getCollections()` from `shared/db`); cache-aside where read-heavy (`/backend/redis-cache`).
- **`__tests__/`** — vitest unit tests.

## Mandatory conventions
- snake_case everywhere (DB = TS = JSON, no mapping layer).
- ActionType declared in `action-types.ts`, passed statically to `audit()` — never derived from method/path (`/backend/action-types`).
- HTTP errors: throw `AppError`/`NotFoundError`/`UnauthorizedError` — never inline 4xx; `app.onError` maps it (`/backend/error-handling`).
- SDK clients (Mongo, SecretsManager, Redis) module-level, never inside a handler.
- **No auth code** — requests are already validated by the API GW Cognito authorizer; read claims from `c.env.event.requestContext.authorizer?.jwt?.claims` (e.g. `cognito:groups`) for RBAC/shaping (`/backend/bff`).
- Sensitive values from Secrets Manager (`/backend/secrets-management`); non-secret config from `/backend/environment-config`.
- The domain is a **modular monolith** now; a module can later become a microservice the BFF calls — without changing the SPA (`/backend/bff`).
- og-edge is the exception: NO Hono / VPC — it's Lambda@Edge (`/backend/og-edge-handler`).
