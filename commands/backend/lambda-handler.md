Implement a domain module in the BFF (`apps/bff`).

Module: $ARGUMENTS (e.g., "posts", "articles", "notifications")

The api is **one BFF Lambda** — a single Hono app with routes at the **root** (`/backend/bff`, `/backend/framework-hono`). Add a feature as a **domain module** that registers its routes onto that app — **not** as a separate Lambda.

## The BFF entry
The single entry (`src/index.ts`) creates the app, wires the middleware, and registers every module's routes — that **framework setup lives in `/backend/framework-hono`**. A module just exposes a `register{Name}(app)` that mounts its routes onto the BFF app.

## Files per module — `src/modules/{name}/`
- **`routes.ts`** — `register{Name}(app)`: mounts the module's routes and attaches `audit`/`authorize` per route (the `createRoute` + zod + middleware pattern is `/backend/framework-hono`). **Public** routes (public GETs, `/og-meta`, `/prerender`, `/health`) carry no authorizer; **mutations** are admin-only.
- **`handler.ts`** — route handlers (request → repository), shaped for the SPA.
- **`repository.ts`** — DynamoDB access (`getDocClient()` from `shared/db`); `Get`/`Query` only, never `Scan` in a hot path; cache-aside where read-heavy (`/backend/redis-cache`).
- **`__tests__/`** — vitest unit tests.

## Mandatory conventions
- snake_case everywhere (DB = TS = JSON, no mapping layer).
- **Opaque path ids** — a resource is addressed by a **slug** (articles) or a generated **hashid/nanoid `public_id`** (posts/etc.), **never** a sequential integer (non-enumerable, no information leak). Use the `public_id`/slug as the table key (or a GSI partition key) and look up by it (`/backend/dynamodb`). RESTful nouns, kebab-case paths.
- ActionType declared in `action-types.ts`, passed statically to `audit()` — never derived from method/path (`/backend/action-types`).
- HTTP errors: throw `AppError`/`NotFoundError`/`UnauthorizedError` — never inline 4xx; the central handler maps it (`/backend/error-handling`, wired in `/backend/framework-hono`).
- SDK clients (DynamoDBDocumentClient, SecretsManager, Redis) module-level, never inside a handler.
- **No auth code** — requests are already validated by the API GW Cognito authorizer; read claims from `c.env.event.requestContext.authorizer?.jwt?.claims` (e.g. `cognito:groups`) for RBAC/shaping (`/backend/bff`).
- Sensitive values from Secrets Manager (`/backend/secrets-management`); non-secret config from `/backend/environment-config`.
- The domain is a **modular monolith** now; a module can later become a microservice the BFF calls — without changing the SPA (`/backend/bff`).
- og-edge is the exception: NO Hono / VPC — it's Lambda@Edge (`/backend/og-edge-handler`).

## Decision & trade-off
- **A feature is a module that registers routes onto the one BFF app — never its own Lambda.** Keeps the modular monolith (one deploy, one cold-start budget) and lets a module graduate to a microservice later without an SPA change (`/backend/bff`). *Trade-off:* modules share the BFF Lambda's resources/limits and fault domain.
- **The handler reads claims and orchestrates; it never authenticates and never touches `process.env` directly.** Auth is the GW authorizer's job (`/backend/bff`); non-secret config comes from the typed `config` accessor (`/backend/environment-config`) and sensitive values from Secrets Manager at runtime (`/backend/secrets-management`). *Trade-off:* a little indirection (config + secrets accessors) for one consistent, testable module shape.
- **SDK clients are module-level singletons, reused across warm invocations — never constructed in a handler.** *Trade-off:* the client lives for the container lifetime (rotation picked up on the next cold start) in exchange for connection reuse and lower per-request latency.

## Pros & cons
**Pros**
- Consistent module shape (routes + audit + DynamoDB) that registers into the one app.
- Testable in-process with `app.request()`.
**Cons**
- A convention to learn.
- Modules share the BFF Lambda resources/limits.
