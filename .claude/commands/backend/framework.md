Define or review the backend framework (Hono) for tadeumendonca-api Lambdas.

Context: $ARGUMENTS

## Framework: Hono on AWS Lambda

Hono owns the request lifecycle inside each Lambda — **routing + middleware + error handling**. It **replaces middy**. Powertools (Logger/Tracer) and OpenTelemetry metrics are used as framework-agnostic utilities. API GW v2 routes a resource prefix (e.g. `/posts*`) to the function; Hono matches the exact route inside.

## App + Lambda adapter: src/functions/{name}/index.ts

```typescript
import { Hono } from 'hono';
import { handle, type LambdaBindings } from 'hono/aws-lambda';
import { loggerContext } from '../../shared/middleware/logger';
import { errorHandler } from '../../shared/middleware/error';
import { audit } from '../../shared/middleware/audit';
import { requireGroup } from '../../shared/middleware/auth';
import { zValidator } from '@hono/zod-validator';
import { ActionType } from '../../shared/constants/action-types';
import { listPosts, createPosts } from './handler';

const app = new Hono<{ Bindings: LambdaBindings }>();

app.use('*', loggerContext());        // Powertools context (cold start, request id)
app.onError(errorHandler);            // AppError → HTTP response

app.get('/posts',  audit(ActionType.POSTS_LIST), listPosts);
app.post('/posts', requireGroup('admin'), zValidator('json', postSchema),
                   audit(ActionType.POSTS_CREATE), createPosts);

export const handler = handle(app);
```

## Handlers: src/functions/{name}/handler.ts

```typescript
import type { Context } from 'hono';
import type { LambdaBindings } from 'hono/aws-lambda';

export const listPosts = async (c: Context<{ Bindings: LambdaBindings }>) => {
  const posts = await repository.list(c.req.query('cursor'));
  return c.json(posts);                 // snake_case body
};
```

## Validation: @hono/zod-validator + zod

```typescript
import { z } from 'zod';
const postSchema = z.object({ title: z.string(), body_markdown: z.string() });  // snake_case
// route: app.post('/posts', zValidator('json', postSchema), ...)
// access: const { title } = c.req.valid('json');
```

## JWT claims (API GW authorizer)

```typescript
const claims = c.env.event.requestContext.authorizer?.jwt?.claims ?? {};
const groups = (claims['cognito:groups'] as string[]) ?? [];   // requireGroup('admin') guards mutations
```

## Conventions
- One Hono app per function; its routes mirror what the function owns in `openapi.yaml`.
- Middleware order: **logger → auth/validation → audit → handler**; `app.onError` centralizes errors (`/backend/error-handling`).
- Bodies snake_case (`/backend/lambda-handler`); SDK clients module-level.
- Powertools Logger/Tracer + OTel metrics are utilities, not middy — `/backend/logging`, `/backend/metrics`.
- `fn-og-edge` does NOT use Hono — Lambda@Edge uses a raw `CloudFrontRequestHandler` (`/backend/og-edge-handler`).
- Deps: `hono`, `@hono/zod-validator`, `zod`. No `@middy/core`.
