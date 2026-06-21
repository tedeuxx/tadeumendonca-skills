Implement or review metrics in `apps/bff` (Powertools Metrics → EMF → CloudWatch).

Context: $ARGUMENTS

## Why EMF (not Prometheus, not a collector)
Lambda is ephemeral — Prometheus' pull/scrape model doesn't apply (no stable endpoint to scrape), and a long-running collector adds cost. Metrics are **pushed as EMF (Embedded Metric Format)**: the function writes a structured JSON log line with embedded metrics to its log group; CloudWatch **auto-extracts** them as metrics. No ADOT collector, no Amazon Managed Prometheus.

## Powertools Metrics (src/shared/metrics.ts)
```typescript
import { Metrics, MetricUnit } from '@aws-lambda-powertools/metrics';

export const metrics = new Metrics({
  namespace:   `<project>/${process.env.ENVIRONMENT}`,
  serviceName: process.env.POWERTOOLS_SERVICE_NAME,   // = "bff"
});

// in a module:
metrics.addDimension('action_type', action_type);     // low-cardinality only
metrics.addMetric('requests_total',      MetricUnit.Count,        1);
metrics.addMetric('request_duration_ms', MetricUnit.Milliseconds, ms);
```
- **Flush once per invocation** — call `metrics.publishStoredMetrics()` in a `finally`, wired in the Hono handler/middleware (`/backend/framework-hono`); optionally `metrics.captureColdStartMetric()`.
- The EMF lands in the BFF log group `/aws/lambda/<project>-bff-${env}`; CloudWatch extracts metrics under namespace `<project>/${env}` (`/infrastructure/cloudwatch`).

## Conventions
- **No `cloudwatch:PutMetricData`** — EMF metrics are extracted from logs, so the exec role needs no metrics IAM action (basic logs perms suffice). See `/infrastructure/iam`.
- **Low cardinality** — dimensions limited to `action_type` / `environment` / `service`. Never `user_id` or id-bearing paths.
- Suggested metrics: request count + latency, cache hit/miss (`/backend/redis-cache`), DynamoDB query duration, handler errors.
- `og-edge` (Lambda@Edge) emits no metrics (edge constraints).
- Powertools owns Logger / Metrics / Tracer uniformly (`/backend/logging`, `/backend/tracing`).

## Pros & cons
**Pros**
- Serverless-native EMF — no collector, no `PutMetricData` IAM.
- Low-cardinality discipline keeps cost predictable.
**Cons**
- Metrics surface only after log ingestion (slight delay).
- Cardinality limits constrain dimensions.
