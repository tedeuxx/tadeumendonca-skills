Implement or review structured logging in tadeumendonca-api.

Context: $ARGUMENTS

## Standard: AWS Lambda Powertools Logger

Structured JSON logs, one logger per function, level driven by env var. **Never `console.log`** in VPC handlers.

## Setup: src/shared/middleware/powertools.ts

```typescript
import { Logger } from '@aws-lambda-powertools/logger';
import { injectLambdaContext } from '@aws-lambda-powertools/logger/middleware';

export const logger = new Logger({
  serviceName: process.env.POWERTOOLS_SERVICE_NAME,   // tadeumendonca-{fn}, set by IaC
  logLevel: (process.env.LOG_LEVEL ?? 'INFO') as any, // WARN in prod, DEBUG in staging (IaC)
});

// middy: stamps cold-start flag, function name, request id on every line
export const loggerMiddleware = injectLambdaContext(logger, { logEvent: false, clearState: true });
```

## Usage

```typescript
logger.appendKeys({ action_type: ActionType.POSTS_LIST });   // correlate by domain field
logger.info('listing posts', { cursor, limit });
logger.error('docdb query failed', { error });
```

## Conventions
- JSON only; custom fields **snake_case** (consistent with the rest of the API).
- `logEvent: false` — never log the raw event (JWT/PII). The Authorization header is never logged.
- `clearState: true` so appended keys don't leak across warm invocations.
- Levels via `LOG_LEVEL` env var: `DEBUG` (staging) / `WARN` (production) — see `/backend/environment-config`.
- `fn-og-edge` (Lambda@Edge) has no Powertools — minimal `console` only (no middy, size-constrained).
