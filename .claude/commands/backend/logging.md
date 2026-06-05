Implement or review structured logging in tadeumendonca-api.

Context: $ARGUMENTS

## Standard: AWS Lambda Powertools Logger (utility, attached via a Hono middleware)

Structured JSON logs, level from `LOG_LEVEL`. Powertools is framework-agnostic — a small Hono middleware attaches the Lambda context to the logger. **Never `console.log`** in VPC handlers.

## Logger + context middleware: src/shared/middleware/logger.ts

```typescript
import { Logger } from '@aws-lambda-powertools/logger';
import { MiddlewareHandler } from 'hono';
import type { LambdaBindings } from 'hono/aws-lambda';

export const logger = new Logger({
  serviceName: process.env.POWERTOOLS_SERVICE_NAME,    // tadeumendonca-{fn}, set by IaC
  logLevel: (process.env.LOG_LEVEL ?? 'INFO') as any,  // WARN prod, DEBUG staging (IaC)
});

export const loggerContext = (): MiddlewareHandler<{ Bindings: LambdaBindings }> =>
  async (c, next) => {
    logger.addContext(c.env.lambdaContext);            // cold-start flag, function name, request id
    logger.appendKeys({ path: c.req.path, method: c.req.method });
    await next();
    logger.resetKeys();                                // don't leak across warm invocations
  };
```

## Usage

```typescript
logger.appendKeys({ action_type: ActionType.POSTS_LIST });
logger.info('listing posts', { cursor, limit });
logger.error('docdb query failed', { error });
```

## Conventions
- JSON only; custom fields **snake_case**.
- Never log the raw event or the Authorization header (PII/JWT).
- `resetKeys()` after the request so appended keys don't leak across warm invocations.
- Levels via `LOG_LEVEL`: `DEBUG` (staging) / `WARN` (production) — see `/backend/environment-config`.
- `fn-og-edge` (Lambda@Edge) has no Powertools/Hono — minimal `console` only.
