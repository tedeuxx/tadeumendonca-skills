Frontend real-user monitoring (CloudWatch RUM) in <project>-fed (concept).

Context: $ARGUMENTS

Conceptual skill — what RUM captures. The `aws-rum-web` snippet lives in `/frontend/framework-react`; provisioning in `/infrastructure/cloudwatch-rum`.

Real-user monitoring: **web vitals, JS errors, http latency, sessions**, and **end-to-end correlation with X-Ray** (browser → API GW → BFF). Complements GA4 (`/frontend/analytics`), which is product analytics.

## Contract
- Initialize the RUM web client with the **app monitor id + identity pool** (guest auth) from SSM (`/frontend/environment-config`).
- Telemetries: performance / errors / http; `enableXRay` for the end-to-end trace.
- **Sampling** controls cost (RUM bills per event).

## Conventions
- No PII. Production primarily. Pairs with `/infrastructure/cloudwatch-xray` for the backend half of the trace.

## Pros & cons
**Pros**
- Real-user web-vitals / JS errors / HTTP, correlated with X-Ray end-to-end; native AWS.
**Cons**
- Adds a client script + sampling.
- Guest ingest is an open surface (bounded on the infra side).
