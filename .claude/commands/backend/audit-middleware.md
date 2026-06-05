Implement or configure the audit middleware (Hono) for a Lambda handler.

Handler/context: $ARGUMENTS

## Hono middleware: `src/shared/middleware/audit.ts`

Captures every request/response → writes to the `audits` DocumentDB collection. Applied per route with a static `ActionType`.

```typescript
import { MiddlewareHandler } from 'hono';
import type { LambdaBindings } from 'hono/aws-lambda';

export const audit = (actionType: ActionType): MiddlewareHandler<{ Bindings: LambdaBindings }> =>
  async (c, next) => {
    const start = Date.now();
    await next();                                   // run the handler first
    const claims = c.env.event.requestContext?.authorizer?.jwt?.claims ?? {};
    const { audits } = await getCollections();
    await audits.insertOne({
      timestamp: new Date(),
      action_type: actionType,
      user: {
        user_id: claims.sub ?? null,
        email: claims.email ?? null,
        groups: (claims['cognito:groups'] as string[]) ?? [],
        ip_address: c.env.event.requestContext.http.sourceIp,
        user_agent: c.req.header('user-agent') ?? null,
      },
      request: {
        method: c.req.method,
        path: c.req.path,
        query_params: c.req.queries(),
        // Authorization header intentionally excluded
      },
      response: { status_code: c.res.status },
      http_status_code: c.res.status,
      success: c.res.status >= 200 && c.res.status < 300,
      duration_ms: Date.now() - start,
      request_id: c.env.event.requestContext.requestId,
    });
  };
```

## Per-route usage (index.ts)

```typescript
app.post('/posts', audit(ActionType.POSTS_CREATE), createPosts);
```

Declare the actionType in `action-types.ts` first (`/backend/action-types`). Never derive from path.

## og-edge exception: NO audit
`fn-og-edge` runs as Lambda@Edge — no VPC, no DocumentDB, no Hono. Do NOT add audit.
