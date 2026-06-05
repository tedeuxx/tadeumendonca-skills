Implement or review metrics in tadeumendonca-api (OpenTelemetry → ADOT → CloudWatch).

Context: $ARGUMENTS

## Architecture

Lambda is ephemeral, so the Prometheus *pull* model doesn't apply — metrics are **pushed**. Instrument once with OpenTelemetry (Prometheus-style counters/histograms); the **ADOT collector** (Lambda layer) receives them via OTLP and exports to **CloudWatch via the `awsemf` exporter** (Embedded Metric Format). **No Amazon Managed Prometheus needed.**

> Changing destination later is a collector-config change only (`awsemf` → CloudWatch, or `prometheusremotewrite` → AMP). The code instrumentation does not change.

## Setup (api.tf, per VPC function)
- Add the **ADOT Lambda layer** and set `AWS_LAMBDA_EXEC_WRAPPER=/opt/otel-handler`.
- Bundle a collector config and point at it: `OPENTELEMETRY_COLLECTOR_CONFIG_URI=/var/task/collector.yaml`.

## collector.yaml (awsemf → CloudWatch)

```yaml
receivers:
  otlp: { protocols: { http: {}, grpc: {} } }
exporters:
  awsemf:
    namespace: tadeumendonca/${ENVIRONMENT}
    dimension_rollup_option: NoDimensionRollup
service:
  pipelines:
    metrics: { receivers: [otlp], exporters: [awsemf] }
```

## Instrumentation: src/shared/metrics.ts

```typescript
import { metrics } from '@opentelemetry/api';
const meter = metrics.getMeter('tadeumendonca-api');

export const requestCount   = meter.createCounter('requests_total');
export const requestLatency = meter.createHistogram('request_duration_ms');
export const cacheHits      = meter.createCounter('cache_hits_total');
export const cacheMisses    = meter.createCounter('cache_misses_total');

// low-cardinality attributes only
requestCount.add(1, { action_type, environment: process.env.ENVIRONMENT });
```

## Conventions
- Keep **cardinality low** — attributes: `action_type`, `environment`, `function`. Never user_id or id-bearing paths as a dimension.
- IAM: Lambda role needs `cloudwatch:PutMetricData` (`policy_statements`, api.tf).
- Suggested metrics: request count + latency, cache hit/miss (`/backend/redis-cache`), DocDB query duration, handler errors.
- `fn-og-edge` emits no metrics (Lambda@Edge constraints).
