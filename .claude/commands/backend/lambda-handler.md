Implement a domain module in the BFF (<project>-api).

Module: $ARGUMENTS (e.g., "posts", "articles", "notifications")

The api is **one BFF Lambda** — a single Hono app with routes at the **root** (`/backend/bff`, `/backend/framework-hono`). Add a feature as a **domain module** that registers its routes onto that app — **not** as a separate Lambda.

## The BFF entry
The single entry (`src/index.ts`) creates the app, wires the middleware, and registers every module's routes — that **framework setup lives in `/backend/framework-hono`**. A module just exposes a `register{Name}(app)` that mounts its routes onto the BFF app.

## Files per module — `src/modules/{name}/`
- **`routes.ts`** — `register{Name}(app)`: mounts the module's routes and attaches `audit`/`authorize` per route (the `createRoute` + zod + middleware pattern is `/backend/framework-hono`). **Public** routes (public GETs, `/og-meta`, `/prerender`, `/health`) carry no authorizer; **mutations** are admin-only.
- **`handler.ts`** — route handlers (request → repository), shaped for the SPA.
- **`repository.ts`** — DocumentDB queries (`getCollections()` from `shared/db`); cache-aside where read-heavy (`/backend/redis-cache`).
- **`__tests__/`** — vitest unit tests.

## Mandatory conventions
- snake_case everywhere (DB = TS = JSON, no mapping layer).
- ActionType declared in `action-types.ts`, passed statically to `audit()` — never derived from method/path (`/backend/action-types`).
- HTTP errors: throw `AppError`/`NotFoundError`/`UnauthorizedError` — never inline 4xx; the central handler maps it (`/backend/error-handling`, wired in `/backend/framework-hono`).
- SDK clients (Mongo, SecretsManager, Redis) module-level, never inside a handler.
- **No auth code** — requests are already validated by the API GW Cognito authorizer; read claims from `c.env.event.requestContext.authorizer?.jwt?.claims` (e.g. `cognito:groups`) for RBAC/shaping (`/backend/bff`).
- Sensitive values from Secrets Manager (`/backend/secrets-management`); non-secret config from `/backend/environment-config`.
- The domain is a **modular monolith** now; a module can later become a microservice the BFF calls — without changing the SPA (`/backend/bff`).
- og-edge is the exception: NO Hono / VPC — it's Lambda@Edge (`/backend/og-edge-handler`).
