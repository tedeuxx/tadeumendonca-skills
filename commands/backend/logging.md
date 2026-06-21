Implement or review structured logging in `apps/bff`.

Context: $ARGUMENTS

Conceptual skill — the logging standard. The framework-specific context wiring (the middleware that attaches the Lambda context per request) lives in `/backend/framework-hono`.

## Standard: AWS Lambda Powertools Logger
Structured JSON logs via Powertools Logger (framework-agnostic). **Never `console.log`** in VPC handlers.
```typescript
import { Logger } from '@aws-lambda-powertools/logger';
export const logger = new Logger({
  serviceName: process.env.POWERTOOLS_SERVICE_NAME,    // <project>-bff, set by IaC
  logLevel: (process.env.LOG_LEVEL ?? 'INFO') as any,  // WARN prod, DEBUG staging (IaC)
});
```

## Usage
```typescript
logger.appendKeys({ action_type: 'posts_list' });
logger.info('listing posts', { cursor, limit });
logger.error('dynamodb query failed', { error });
```

## Conventions
- JSON only; custom fields **snake_case**.
- Never log the raw event or the Authorization header (PII/JWT).
- Attach the Lambda context (cold-start, request id) **once per request** and reset appended keys afterward — that wiring is framework-specific (`/backend/framework-hono`).
- Levels via `LOG_LEVEL`: DEBUG (staging) / WARN (production) — `/backend/environment-config`.
- `og-edge` (Lambda@Edge) has no Powertools — minimal `console` only.

## Decision & trade-off
- **Structured JSON via Powertools Logger — never `console.log`.** One toolkit owns Logger/Metrics/Tracer, JSON lines are queryable in CloudWatch Logs Insights and double as the EMF metric carrier (`/backend/metrics`). *Trade-off:* structured-logging discipline (append keys, don't string-concat) for machine-queryable logs with no separate log backend.
- **Level per env via `LOG_LEVEL` (DEBUG staging / WARN production); never log the raw event or `Authorization` header.** *Trade-off:* less verbosity in prod (cheaper retention, fewer leaks) at the cost of needing a redeploy/log-level change to capture DEBUG in production.

## Pros & cons
**Pros**
- Structured JSON logs, correlation ids, per-env level; integrates with metrics/tracer.
- PII/Authorization never logged.
**Cons**
- Requires structured-logging discipline.
- Verbose logs carry a retention cost.
