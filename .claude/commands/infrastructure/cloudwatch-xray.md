Use AWS X-Ray in <project> infrastructure (distributed tracing service).

Context: $ARGUMENTS

The tracing **service** side — the backend instrumentation is `/backend/tracing`. Gives a **service map** + traces across API GW → BFF → downstream (DocumentDB/Redis/SES), and — with RUM — browser → backend end-to-end.

## Enable active tracing
- **Lambda** (BFF, og-edge): `tracing_mode = "Active"` (`/infrastructure/lambda`); role gets `xray:PutTraceSegments` + `xray:PutTelemetryRecords`.
- **API Gateway:** enable X-Ray on the stage so the edge span starts the trace.
- **RUM:** `enable_xray = true` joins client traces (`/infrastructure/cloudwatch-rum`).

## Sampling
```hcl
resource "aws_xray_sampling_rule" "default" {
  rule_name      = "<project>-${var.environment}"
  priority       = 1000
  fixed_rate     = 0.1            # 10% (+ reservoir) — cost control
  reservoir_size = 1
  service_name = "*"; http_method = "*"; url_path = "*"; host = "*"; service_type = "*"; resource_arn = "*"
}
```

## Conventions
- **Sampling controls cost** (X-Ray bills per recorded trace) — `fixed_rate` low in prod.
- Annotations (indexed, low-cardinality) vs metadata — set in `/backend/tracing`; no PII.
- The **service map** is the payoff: latency/error hotspots across the request path.
- Pairs with `/infrastructure/cloudwatch` (logs/metrics) + `/infrastructure/cloudwatch-rum` (RUM) for full observability.
## Pros & cons
**Pros**
- Native end-to-end tracing API GW → Lambda → browser (RUM), no extra vendor.
- Sampling rules control cost.
**Cons**
- Less rich than a dedicated APM (Datadog/Honeycomb).
- Sampling can drop the trace you wanted; some instrumentation overhead.
