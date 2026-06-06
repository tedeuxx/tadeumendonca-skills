Implement or review structured logging in tadeumendonca-api.

Context: $ARGUMENTS

Conceptual skill — the logging standard. The framework-specific context wiring (the middleware that attaches the Lambda context per request) lives in `/backend/hono`.

## Standard: AWS Lambda Powertools Logger
Structured JSON logs via Powertools Logger (framework-agnostic). **Never `console.log`** in VPC handlers.
```typescript
import { Logger } from '@aws-lambda-powertools/logger';
export const logger = new Logger({
  serviceName: process.env.POWERTOOLS_SERVICE_NAME,    // tadeumendonca-bff, set by IaC
  logLevel: (process.env.LOG_LEVEL ?? 'INFO') as any,  // WARN prod, DEBUG staging (IaC)
});
```

## Usage
```typescript
logger.appendKeys({ action_type: 'posts_list' });
logger.info('listing posts', { cursor, limit });
logger.error('docdb query failed', { error });
```

## Conventions
- JSON only; custom fields **snake_case**.
- Never log the raw event or the Authorization header (PII/JWT).
- Attach the Lambda context (cold-start, request id) **once per request** and reset appended keys afterward — that wiring is framework-specific (`/backend/hono`).
- Levels via `LOG_LEVEL`: DEBUG (staging) / WARN (production) — `/backend/environment-config`.
- `og-edge` (Lambda@Edge) has no Powertools — minimal `console` only.
