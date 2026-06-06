Implement or review distributed tracing in tadeumendonca-api.

Context: $ARGUMENTS

The third observability pillar (with `/backend/logging` + `/backend/metrics`): **AWS Lambda Powertools Tracer** over **X-Ray** — see a request across the BFF and its downstream calls (DocumentDB, Redis, SES, future microservices).

## Standard: Powertools Tracer
```typescript
import { Tracer } from '@aws-lambda-powertools/tracer';
export const tracer = new Tracer({ serviceName: process.env.POWERTOOLS_SERVICE_NAME });
```
- Enable **active tracing** on the Lambda (`tracing_mode = "Active"` — `/infrastructure/lambda`) and the API GW stage; sampling rules + service map are the service side (`/infrastructure/cloudwatch-xray`).
- The framework wiring (a middleware that opens a segment per request, marks cold start + response, closes on error) lives in `/backend/hono`.

## Usage
```typescript
const sub = tracer.getSegment()?.addNewSubsegment('docdb.posts.list');
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
