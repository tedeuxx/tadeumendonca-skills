Implement or review distributed tracing in `apps/bff`.

Context: $ARGUMENTS

The third observability pillar (with `/backend/logging` + `/backend/metrics`): **AWS Lambda Powertools Tracer** over **X-Ray** — see a request across the BFF and its downstream calls (DynamoDB, Redis, SES, future microservices).

## Standard: Powertools Tracer
```typescript
import { Tracer } from '@aws-lambda-powertools/tracer';
export const tracer = new Tracer({ serviceName: process.env.POWERTOOLS_SERVICE_NAME });
```
- Enable **active tracing** on the Lambda (`tracing_mode = "Active"` — `/infrastructure/lambda`) and the API GW stage; sampling rules + service map are the service side (`/infrastructure/cloudwatch-xray`).
- The framework wiring (a middleware that opens a segment per request, marks cold start + response, closes on error) lives in `/backend/framework-hono`.

## Usage
```typescript
const sub = tracer.getSegment()?.addNewSubsegment('dynamodb.posts.query');
try { /* query */ } finally { sub?.close(); }
tracer.putAnnotation('action_type', 'posts_list');   // indexed → filterable in X-Ray
tracer.putMetadata('cursor', cursor);                // non-indexed context
// auto-capture downstream as subsegments:
const db = tracer.captureAWSv3Client(new SESv2Client({}));
```

## Conventions
- **Annotations** = indexed, low-cardinality (`action_type`, `success`) for filtering; **metadata** = rich context — never PII.
- Correlate with logs/audit via the same `request_id` (`/backend/logging`, `/backend/audit-middleware`).
- `og-edge` (Lambda@Edge) has no Powertools — no tracing there.

## Decision & trade-off
- **Powertools Tracer over X-Ray — the native AWS tracer, no dedicated APM.** Same Powertools toolkit as Logger/Metrics, zero extra infrastructure, and it auto-instruments downstream AWS SDK calls. *Trade-off:* X-Ray is less rich than a dedicated APM and sampling can miss a trace — accepted for cost/simplicity, consistent with the EMF-not-Prometheus call (`/backend/metrics`).
- **Annotations are indexed + low-cardinality; metadata is rich context; neither carries PII.** Only annotations are filterable in X-Ray, so identity/raw context goes in metadata. *Trade-off:* you choose at write time what's queryable vs. merely attached.

## Pros & cons
**Pros**
- End-to-end traces (API GW→Lambda→browser), annotations, downstream capture.
- Correlates with RUM for full-stack visibility.
**Cons**
- Sampling can miss a trace; minor runtime overhead.
- X-Ray is less rich than a dedicated APM.
