Implement a Lambda function in tadeumendonca-api.

Function: $ARGUMENTS (e.g., "posts", "articles", "notifications")

## Files to create

**`src/functions/{name}/index.ts`** — entry point with middy:
```typescript
import middy from '@middy/core';
import { handler as routeHandler } from './handler';
import { powertoolsMiddleware } from '../../shared/middleware/powertools';
import { auditMiddleware } from '../../shared/middleware/audit';
import { ActionType } from '../../shared/constants/action-types';

export const handler = middy(routeHandler)
  .use(powertoolsMiddleware())
  .use(auditMiddleware({ actionType: ActionType.{NAME_VERB} }));
```

**`src/functions/{name}/handler.ts`** — route dispatch by method + path:
```typescript
export async function handler(event: APIGatewayProxyEventV2): Promise<APIGatewayProxyResultV2> {
  const { method, path } = event.requestContext.http;
  if (method === 'GET') return list(event);
  if (method === 'POST') return create(event);
  throw new NotFoundError('Route not found');
}
```

**`src/functions/{name}/repository.ts`** — DocumentDB queries (use `getCollections()` from shared/db).

**`src/functions/{name}/__tests__/handler.test.ts`** — vitest unit tests.

## Mandatory conventions
- All fields: snake_case — DB field = TypeScript type field = JSON response field (no mapping layer)
- ActionType: declare in `action-types.ts`, pass statically to `auditMiddleware` — NEVER derive from HTTP method/path
- HTTP errors: throw `AppError` / `NotFoundError` / `UnauthorizedError` — never `return { statusCode: 4xx }` directly
- SDK clients (MongoClient, SecretsManagerClient): module-level, NOT inside handler
- JWT group check before mutation: `event.requestContext.authorizer?.jwt?.claims?.['cognito:groups']`
- og-edge: NO middy, NO audit middleware, NO VPC access — it's Lambda@Edge
