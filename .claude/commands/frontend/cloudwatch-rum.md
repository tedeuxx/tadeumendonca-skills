Instrument the frontend with CloudWatch RUM in tadeumendonca-fed.

Context: $ARGUMENTS

Real-user monitoring (RUM) for the SPA — **web vitals, JS errors, page loads, http latency, sessions** — and **end-to-end correlation with X-Ray** (browser → API GW → BFF → DocumentDB). Complements GA4 (`/frontend/analytics`), which is product analytics, not performance/errors. Provisioned in `/infrastructure/cloudwatch-rum`.

## Setup: aws-rum-web
```typescript
import { AwsRum, type AwsRumConfig } from 'aws-rum-web';

const config: AwsRumConfig = {
  sessionSampleRate: 0.1,                      // sample to control cost
  identityPoolId: env.rumIdentityPoolId,       // guest auth (from SSM)
  endpoint: `https://dataplane.rum.${env.region}.amazonaws.com`,
  telemetries: ['performance', 'errors', 'http'],
  allowCookies: true,
  enableXRay: true,                            // link client traces to backend X-Ray
};
new AwsRum(env.rumAppMonitorId, '1.0.0', env.region, config);   // ids from SSM (build-time)
```

## Captured
- **Performance / web vitals** (LCP, INP, CLS) + page-load timings.
- **JS errors** + unhandled rejections (stack traces).
- **HTTP** requests (latency, status) — with `enableXRay`, a client segment that joins the backend X-Ray trace.
- **Sessions** + page-view on route change (SPA-aware, like `/frontend/analytics`).

## Conventions
- `app-monitor id`, `identity pool id`, region from **SSM** at build time (`/frontend/environment-config`) — never hardcoded.
- **Cost:** RUM bills per event — keep `sessionSampleRate` low (e.g. 0.1) and prune telemetries to what you use.
- No PII in custom events/metadata.
- Production primarily (or a separate monitor per env) to avoid staging noise/cost.
