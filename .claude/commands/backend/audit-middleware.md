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

## How it works

The middleware **wraps** the handler: it records `start`, calls `await next()` to run the route, then — **after** the response is set — reads the JWT claims from the API GW authorizer context (`c.env.event.requestContext.authorizer.jwt.claims`), assembles the audit document, and `insertOne`s it into the `audits` collection. One row is written **per request**, capturing who/what/when/outcome. It's a normal awaited insert; wrap it in try/catch + log if you want audit to **never fail the request** (fail-open). The Authorization header and any credential material are intentionally excluded.

## Document shape (`audits` collection)

One document per user interaction (all fields snake_case):

```jsonc
{
  "_id": "ObjectId",
  "timestamp": "ISODate",                 // when the request completed
  "action_type": "posts_create",          // the route's declared ActionType (/backend/action-types)
  "user": {
    "user_id": "cognito-sub | null",      // null when public/unauthenticated
    "email": "string | null",
    "groups": ["admin"],                  // cognito:groups claim
    "ip_address": "203.0.113.7",
    "user_agent": "Mozilla/5.0 …"
  },
  "request": {
    "method": "POST",
    "path": "/posts",
    "query_params": { "cursor": "…" }
    // body optional + truncated/redacted if enabled; Authorization header never stored
  },
  "response": { "status_code": 201 },
  "http_status_code": 201,
  "success": true,                        // 2xx
  "duration_ms": 42,
  "request_id": "api-gw-request-id"       // correlates with CloudWatch logs / X-Ray
}
```

**Indexes** (DocumentDB): `{ "user.user_id": 1, "timestamp": -1 }` (per-user activity), `{ "action_type": 1, "timestamp": -1 }` (by action), `{ "timestamp": -1 }` (recent). Add a **TTL index** on `timestamp` for retention/auto-expiry.

## Per-route usage (index.ts)

```typescript
app.post('/posts', audit(ActionType.POSTS_CREATE), createPosts);
```

Declare the actionType in `action-types.ts` first (`/backend/action-types`). Never derive from path.

## Pros / cons

**Pros**
- **Uniform + declarative** — one middleware, one row per request, applied per route with its action type; no per-handler boilerplate.
- Full who/what/when/outcome (+ `request_id`) for forensics, per-user activity, and usage metrics — keyed by `action_type` (`/backend/action-types`).
- Lives next to the data (same DocumentDB) — queryable with the same driver, no extra service.

**Cons**
- **A write per request** adds latency + DocDB write load on hot paths (mitigate: fire-and-forget the insert, or batch/async via a queue if volume grows).
- **Coupled to the request DB** — a DocDB blip can affect the request if the insert is awaited (use try/catch to fail open).
- **Stores PII** (email/IP/user-agent) — set a retention TTL + access controls; never store secrets or credential-bearing bodies.
- Captures response **status only** by default — add body capture deliberately, with truncation + redaction.

## og-edge exception: NO audit
`fn-og-edge` runs as Lambda@Edge — no VPC, no DocumentDB, no Hono. Do NOT add audit.
