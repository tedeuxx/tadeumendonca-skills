Define or review the audit trail in `apps/bff`.

Context: $ARGUMENTS

Conceptual skill — *what* an audit record is and how the trail works. The framework-specific wiring (the Hono middleware that captures and writes it) lives in `/backend/framework-hono`.

## How it works (concept)

Every user interaction produces **one audit item** in the `audits` DynamoDB table. The audit is taken **after** the handler runs: the request is timed, then the request/response + the caller's claims + the route's `action_type` are assembled into an item and `Put`. Audit failures should be **fail-open** (logged, never breaking the request). The Authorization header and any credential material are excluded. `og-edge` (Lambda@Edge) writes no audit.

## Identity — from the validated token, no session store
The "who" comes from the **JWT claims** the API GW Cognito authorizer already validated and injected into the request (`sub`, `cognito:groups`) — read per request, **zero lookup, no session cache**. This is why the BFF stays stateless and Redis is cache-only (`/backend/redis-cache`).
- **`user_id` = `sub`** is the canonical reference (always present).
- **`email`** is usually not in the *access* token (it's in the id token) — include it via a Cognito **Pre-Token-Generation** trigger, or leave it null and **enrich `sub → profile` on demand** (that optional enrichment may be cached in Redis with a TTL — optional, not required for the audit "who").

## Item shape (`audits` table)

One item per user interaction (all fields snake_case):
```jsonc
{
  "audit_id": "nanoid",                   // partition key
  "timestamp": "2026-06-06T12:00:00.000Z", // ISO-8601 string, when the request completed
  "ttl": 1717675200,                      // epoch seconds — DynamoDB TTL set on write (retention)
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

**Access** (DynamoDB): `Get` by `audit_id`; lists go through the `by-entity` GSI (e.g. `user.user_id` or `action_type` as the GSI partition key, `timestamp` as the sort key) — `Query` only, **never `Scan`**. Retention is the `ttl` epoch attribute the app sets on write (DynamoDB TTL), not a TTL index.

## Pros / cons
**Pros:** uniform, one item per request keyed by `action_type` — full who/what/when/outcome for forensics, per-user activity, and usage metrics; lives next to the data (same DynamoDB), reached with the same SDK v3 client.
**Cons:** a write per request adds latency + DynamoDB write cost on hot paths (mitigate: fire-and-forget, or batch/async via a queue if volume grows); coupled to the request DB (fail open); stores PII (set the `ttl` retention attribute + access controls); captures response **status only** by default — add body capture deliberately, with truncation + redaction.

## Wiring
The Hono middleware `audit(action)` that runs after the handler and `Put`s this item is defined in `/backend/framework-hono`; the action constants in `/backend/action-types`; the table access/client in `/backend/dynamodb`.

## Pros & cons
**Pros**
- Automatic, uniform audit trail with no per-handler code; identity comes from the JWT claims.
- Queryable history of every state-changing interaction.
**Cons**
- A write per request adds latency + storage.
- The audit document shape must evolve carefully (snake_case, no mapping layer).
