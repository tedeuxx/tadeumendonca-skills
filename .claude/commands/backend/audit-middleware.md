Define or review the audit trail in tadeumendonca-api.

Context: $ARGUMENTS

Conceptual skill — *what* an audit record is and how the trail works. The framework-specific wiring (the Hono middleware that captures and writes it) lives in `/backend/hono`.

## How it works (concept)

Every user interaction produces **one audit document** in the `audits` DocumentDB collection. The audit is taken **after** the handler runs: the request is timed, then the request/response + the caller's claims + the route's `action_type` are assembled into a document and inserted. Audit failures should be **fail-open** (logged, never breaking the request). The Authorization header and any credential material are excluded. `og-edge` (Lambda@Edge) writes no audit.

## Document shape (`audits` collection)

One document per user interaction (all fields snake_case):
```jsonc
{
  "_id": "ObjectId",
  "timestamp": "ISODate",                 // when the request completed
  "action_type": "posts_create",          // the route's declared action (/backend/action-types)
  "user": {
    "user_id": "cognito-sub | null",      // null when public/unauthenticated
    "email": "string | null",
    "groups": ["admin"],                  // cognito:groups claim
    "ip_address": "203.0.113.7",
    "user_agent": "Mozilla/5.0 …"
  },
  "request": {
    "method": "POST",
    "path": "/posts",
    "query_params": { "cursor": "…" }
    // body optional + truncated/redacted if enabled; Authorization header never stored
  },
  "response": { "status_code": 201 },
  "http_status_code": 201,
  "success": true,                        // 2xx
  "duration_ms": 42,
  "request_id": "api-gw-request-id"       // correlates with CloudWatch logs / X-Ray
}
```

**Indexes** (DocumentDB): `{ "user.user_id": 1, "timestamp": -1 }` (per-user activity), `{ "action_type": 1, "timestamp": -1 }` (by action), `{ "timestamp": -1 }` (recent). Add a **TTL index** on `timestamp` for retention.

## Pros / cons
**Pros:** uniform, one row per request keyed by `action_type` — full who/what/when/outcome for forensics, per-user activity, and usage metrics; lives next to the data (same DocumentDB), queryable with the same driver.
**Cons:** a write per request adds latency + DocDB load on hot paths (mitigate: fire-and-forget, or batch/async via a queue if volume grows); coupled to the request DB (fail open); stores PII (set a retention TTL + access controls); captures response **status only** by default — add body capture deliberately, with truncation + redaction.

## Wiring
The Hono middleware `audit(action)` that runs after the handler and inserts this document is defined in `/backend/hono`; the action constants in `/backend/action-types`; the collection access/connection in `/backend/docdb-connection`.
