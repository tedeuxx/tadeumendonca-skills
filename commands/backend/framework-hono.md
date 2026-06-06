Implement or review the Hono backend framework for <project>-api (the BFF).

Context: $ARGUMENTS

## Hono on AWS Lambda

Hono owns the request lifecycle inside the **single BFF Lambda** — routing + middleware + error handling. It **replaces middy**. The api is one `OpenAPIHono` app with routes at the **root**; domain features register as modules (`/backend/lambda-handler`). The infra/cross-cutting concerns are **framework-agnostic** skills (`/backend/audit-middleware`, `/backend/action-types`, `/backend/logging`, `/backend/error-handling`, `/backend/dynamodb`, …) — **this skill is where they get wired** as Hono middleware.

## App + Lambda adapter: src/index.ts
```typescript
import { OpenAPIHono } from '@hono/zod-openapi';
import { handle, type LambdaBindings } from 'hono/aws-lambda';
import { loggerContext } from './shared/middleware/logger';
import { errorHandler } from './shared/middleware/error';
import { registerPosts } from './modules/posts/routes';

const app = new OpenAPIHono<{ Bindings: LambdaBindings }>();
app.use('*', loggerContext());        // Powertools logger context (/backend/logging)
app.onError(errorHandler);            // AppError → HTTP response (/backend/error-handling)
registerPosts(app);                   // each domain module mounts its root routes
export const handler = handle(app);   // the one BFF handler
```

## Routes & validation: @hono/zod-openapi
Documented routes use `createRoute` + zod via `app.openapi(route, handler)` — the **same schema validates the request AND generates the OpenAPI**. Read validated input with `c.req.valid('json'|'query'|'param')`. This skill is the **generation impl** (`app.getOpenAPI31Document`); the framework-agnostic contract discipline (version stamping + committed root copy) is `/backend/openapi`.
```typescript
import { createRoute, z } from '@hono/zod-openapi';
const createPost = createRoute({
  method: 'post', path: '/posts',
  request: { body: { content: { 'application/json': { schema: z.object({ title: z.string(), body_markdown: z.string() }) } } } },
  responses: { 201: { description: 'Created' } },
});
app.openapi(createPost, (c) => { const body = c.req.valid('json'); /* … */ });
```

## Middleware wiring — where the agnostic concerns plug in
The concern skills define *what* each does; here is *how* they attach in Hono:
```typescript
// logger context (/backend/logging)
export const loggerContext = (): MiddlewareHandler<{ Bindings: LambdaBindings }> => async (c, next) => {
  logger.addContext(c.env.lambdaContext); logger.appendKeys({ path: c.req.path, method: c.req.method });
  await next(); logger.resetKeys();
};
// error handler (/backend/error-handling)
export const errorHandler: ErrorHandler = (err, c) => c.json(toErrorBody(err), statusOf(err));
// audit — capture after the handler (/backend/audit-middleware)
export const audit = (action: ActionType): MiddlewareHandler => async (c, next) => {
  const start = Date.now(); await next(); await writeAudit(c, action, start);   // builds + Puts the audit item
};
// RBAC guard — reads validated claims, no auth here (/backend/action-types, /backend/bff)
export const authorize = (action: ActionType): MiddlewareHandler => async (c, next) => {
  const groups = (c.env.event.requestContext.authorizer?.jwt?.claims?.['cognito:groups'] as string[]) ?? [];
  if (!isAllowed(groups, action)) throw new UnauthorizedError();
  await next();
};
// route wiring:
app.use('/posts', authorize(ActionType.POSTS_CREATE), audit(ActionType.POSTS_CREATE));
app.openapi(createPost, createPostHandler);
```
**Middleware order:** logger → authorize → audit → handler; `app.onError` centralizes errors.

## Claims (auth is external — /backend/bff)
```typescript
const claims = c.env.event.requestContext.authorizer?.jwt?.claims ?? {};  // validated by the API GW authorizer
```

## Testing (vitest)
Unit/integration tests run on **vitest**; the coverage gate (≥ 85%) is the agnostic policy in `/backend/coverage`. Thresholds in `vitest.config.ts`:
```ts
test: { coverage: { provider: 'v8', thresholds: { lines: 85, functions: 85, branches: 85, statements: 85 } } }
```
Test routes with `app.request(...)` (no network); mock DynamoDB/secrets at the module boundary. lcov feeds SonarCloud (`/workflow/sonarcloud`). Contract/smoke tests are Postman/newman (`/backend/postman`).

## Conventions
- One `OpenAPIHono` app (the BFF), routes at root; modules register their routes (`/backend/lambda-handler`).
- Infra/cross-cutting concerns stay **framework-agnostic**; this skill holds the Hono-specific glue.
- Deps: `hono`, `@hono/zod-openapi`, `zod`. No `@middy/core`. og-edge is **not** Hono (`/backend/og-edge-handler`).

## Pros & cons
**Pros**
- Tiny, fast, Web-standard router; `@hono/zod-openapi` generates the contract from code.
- Replaces middy with one coherent middleware model.
**Cons**
- Smaller ecosystem than Express.
- The single place intentionally coupled to a framework.
