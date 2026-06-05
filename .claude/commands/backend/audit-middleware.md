Implement or configure the audit middleware for a Lambda handler.

Handler/context: $ARGUMENTS

## Middleware: `src/shared/middleware/audit.ts`

Captures every request/response → writes to `audits` DocumentDB collection.

```typescript
export function auditMiddleware(options: { actionType: ActionType }): middy.MiddlewareObj {
  return {
    after: async (request) => {
      const { event, response, context } = request;
      const claims = event.requestContext?.authorizer?.jwt?.claims ?? {};
      const { audits } = await getCollections();
      await audits.insertOne({
        timestamp: new Date(),
        action_type: options.actionType,
        user: {
          user_id: claims.sub ?? null,
          email: claims.email ?? null,
          groups: (claims['cognito:groups'] as string[] | undefined) ?? [],
          ip_address: event.requestContext.http.sourceIp,
          user_agent: event.requestContext.http.userAgent,
        },
        request: {
          method: event.requestContext.http.method,
          path: event.requestContext.http.path,
          query_params: event.queryStringParameters ?? {},
          body: event.body ? JSON.parse(event.body) : null,
          // Authorization header intentionally excluded
        },
        response: {
          status_code: response.statusCode,
          body: truncateBody(response.body, 4096),
        },
        http_status_code: response.statusCode,
        success: response.statusCode >= 200 && response.statusCode < 300,
        duration_ms: Date.now() - Number(context.startTime ?? 0),
        function_name: context.functionName,
        request_id: event.requestContext.requestId,
      });
    },
  };
}
```

## Per-handler usage (in index.ts)

```typescript
.use(auditMiddleware({ actionType: ActionType.POSTS_LIST }))
```

Declare actionType in `src/shared/constants/action-types.ts` first. Never derive from path.

## og-edge exception: NO audit

`fn-og-edge` runs as Lambda@Edge — no VPC, no DocumentDB access. Do NOT add audit middleware.
