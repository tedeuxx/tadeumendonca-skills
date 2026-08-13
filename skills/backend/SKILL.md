---
description: Implement a BFF-on-Lambda backend as a reference pattern — the Hono modular monolith, cross-cutting middleware (errors, logging, metrics, tracing, audit, action types), Redis cache-aside, config/secrets, the generated OpenAPI contract + Postman tests, notifications, and OG-image + bot-rendering. Use when a project actually needs a BFF and its cross-cutting shape. Not for the AWS resources it runs on (see cloud-infrastructure) or the SPA calling it (see frontend).
---

# Backend (BFF-on-Lambda)

Context: $ARGUMENTS

> **Reference-only, kept deliberately.** This documents a BFF-on-Lambda + DynamoDB + Cognito
> architecture that this plugin's own current consumer has since **retired** in favor of a fully static
> site, with no API and no Lambda — see this plugin's own project root for which architecture, if any, a
> given consumer actually runs today. Nothing here describes anything live; it is kept as a
> knowledge-transfer artifact — a senior-engineer reference pattern for the next `<project>` that does
> need a BFF. Never infer a consumer's architecture from this file; read the consumer's own project docs.

**Curated, not exhaustive** — consolidated from 19 former per-concern skills (`action-types`,
`audit-middleware`, `bff`, `coverage`, `environment-config`, `error-handling`, `framework-hono`,
`lambda-handler`, `logging`, `metrics`, `notifications`, `og-edge-handler`, `og-image-generator`,
`openapi`, `postman`, `prerender`, `redis-cache`, `secrets-management`, `tracing`) into the sections
below, one `##` per original topic. The standing curation criterion (ADR-0011): *"the more a technical
skill reads like documentation about the technology, the less of a skill it is."* Applied here with
**extra weight** versus the `cloud-infrastructure` consolidation, because nothing exercises this content
live to keep it honest — so each section keeps the owner's **opinionated shape**, the **concrete code
pattern actually used**, the **why**, and any Decision/trade-off framing; it drops narration of how the
underlying technology works in general. Code blocks are kept verbatim where they show the actual pattern
— that IS the content, not filler around it.

---

## BFF — the umbrella pattern

A **BFF is the single backend that exists to serve one frontend.** API Gateway fronts **only the
BFF** — there is no other public backend for the SPA — so its **routes live at the root** (`/profile`,
`/posts`, …); the whole API *is* the BFF. **One BFF per SPA** (1:1, never shared). Its job: expose
endpoints **shaped for this frontend's screens** and **orchestrate/aggregate** the domain logic behind
it — one round trip per screen instead of the SPA fanning out to many resource APIs.

**Auth/authz are EXTERNAL to the BFF** — it contains no authentication or authorization code:
- **Frontend:** the **Cognito SDK** (AWS Amplify Auth / `amazon-cognito-identity-js`) runs login and
  **holds + refreshes the JWT**; the SPA sends `Authorization: Bearer <access_token>`.
- **API Gateway:** a **Cognito JWT authorizer** validates the token on every request before it reaches
  the BFF (see `cloud-infrastructure`).
- The BFF just **reads the validated claims** from the authorizer context (`sub`, `email`,
  `cognito:groups`) and uses them for shaping/RBAC. No token exchange, no session store, no PKCE in the
  BFF. This deliberately trades the "no-tokens-in-browser" BFF-session variant for **much simpler
  code**.

**Topology:**
```
SPA ─(Cognito SDK: login + holds JWT)─► Cognito
SPA ─Bearer JWT─► API Gateway (Cognito JWT authorizer) ─► BFF Lambda (Hono, non-VPC, root routes)
                                                            ├ reads claims (no auth code)
                                                            └ domain logic / microservices ─► DynamoDB · Redis (cache) · S3
```
**Request lifecycle:** SPA authenticates via the SDK → calls the BFF with the bearer token → API GW
authorizer validates it and injects claims → the BFF handler reads claims (RBAC/shaping), calls the
domain logic, **aggregates** into a screen-shaped payload, returns it → cross-cutting concerns (audit,
log, metrics) run as standard middleware.

**Shaping & aggregation is the BFF's core job.** Endpoints are **per screen, not per resource** — the
BFF composes one response from what a view needs: aggregate from several modules/sources into one
payload (a feed item = post + author summary + counts), trim to only the fields the screen renders
(projections, snake_case, never leaking internal document structure), and prefer one composed endpoint
over the SPA fanning out N calls. Keep aggregation/shaping in the BFF; keep **domain rules** in the
modules/services.

**Communicating with microservices (now → future).** Domain logic can live **inside** the BFF (modular
monolith — fastest to ship). As it grows, split into microservices the BFF calls, keeping the SPA
contract stable: **sync** via direct Lambda invoke or a private/internal API GW (VPC link), propagating
user claims explicitly — internal services trust the BFF (network + IAM), they don't re-validate the
JWT; **async** via SNS pub/sub fire-and-forget (see the Notifications section). The **BFF owns the
public contract** (its OpenAPI at root — see the Contract section); microservices keep internal
contracts, so changing one never changes the SPA while the BFF endpoint is stable.

### Decision & trade-off
- **A modular monolith BFF — one Hono app, route modules, one Lambda — behind a single API Gateway that
  fronts ONLY the BFF.** Fastest to ship; one deploy, one fault domain; a module can later be carved into
  a microservice the BFF calls without changing the SPA contract. *Trade-off:* monolith simplicity now
  (one Lambda is a shared fault/resource domain for every route) vs. real service boundaries later.
- **Auth is fully external (Cognito SDK in the SPA + GW JWT authorizer); the BFF holds NO auth code** —
  it only reads verified claims. *Trade-off:* gives up the "no-tokens-in-browser" server-session BFF
  variant in exchange for far simpler code — the BFF stays pure orchestration.
- **Endpoints are shaped per screen, not per resource** (aggregate + trim → one round trip per view).
  *Trade-off:* a payload tailored to one consumer doesn't suit many external clients, and there's a
  standing "god BFF" risk — keep domain rules in the modules/services, not in the shaping layer.

### Pros & cons
**Pros:** tailored payloads + fewer round trips; backend evolves freely behind a stable contract; clear
1:1 ownership; auth kept out of app code; one narrow public surface; one deploy, simple ops now, splits
to microservices later.
**Cons:** an extra hop/Lambda to operate; risk of a "god BFF" if business rules creep into the shaping
layer; per-SPA duplication with many frontends; tokens live in the browser (accepted trade for simpler
code); a single Lambda is a shared fault domain for all routes.

---

## Framework — Hono on Lambda

Hono owns the request lifecycle inside the **single BFF Lambda** — routing + middleware + error
handling; it **replaces middy**. One `OpenAPIHono` app with routes at the **root**; domain features
register as modules (see the Handler pattern section below). Cross-cutting concerns are
framework-agnostic (audit, action types, logging, error shape, …) — this is where they get **wired** as
Hono middleware.

**App + Lambda adapter (`src/index.ts`):**
```typescript
import { OpenAPIHono } from '@hono/zod-openapi';
import { handle, type LambdaBindings } from 'hono/aws-lambda';
import { loggerContext } from './shared/middleware/logger';
import { errorHandler } from './shared/middleware/error';
import { registerPosts } from './modules/posts/routes';

const app = new OpenAPIHono<{ Bindings: LambdaBindings }>();
app.use('*', loggerContext());        // Powertools logger context
app.onError(errorHandler);            // AppError → HTTP response
registerPosts(app);                   // each domain module mounts its root routes
export const handler = handle(app);   // the one BFF handler
```

**Routes & validation — `@hono/zod-openapi`.** Documented routes use `createRoute` + zod via
`app.openapi(route, handler)` — the **same schema validates the request AND generates the OpenAPI**
(`app.getOpenAPI31Document`; the version-stamping/committed-copy discipline is in the Contract section
below). Read validated input with `c.req.valid('json'|'query'|'param')`:
```typescript
import { createRoute, z } from '@hono/zod-openapi';
const createPost = createRoute({
  method: 'post', path: '/posts',
  request: { body: { content: { 'application/json': { schema: z.object({ title: z.string(), body_markdown: z.string() }) } } } },
  responses: { 201: { description: 'Created' } },
});
app.openapi(createPost, (c) => { const body = c.req.valid('json'); /* … */ });
```

**Middleware wiring — where every cross-cutting concern plugs in:**
```typescript
// logger context
export const loggerContext = (): MiddlewareHandler<{ Bindings: LambdaBindings }> => async (c, next) => {
  logger.addContext(c.env.lambdaContext); logger.appendKeys({ path: c.req.path, method: c.req.method });
  await next(); logger.resetKeys();
};
// error handler
export const errorHandler: ErrorHandler = (err, c) => c.json(toErrorBody(err), statusOf(err));
// audit — capture after the handler
export const audit = (action: ActionType): MiddlewareHandler => async (c, next) => {
  const start = Date.now(); await next(); await writeAudit(c, action, start);   // builds + Puts the audit item
};
// RBAC guard — reads validated claims, no auth here
export const authorize = (action: ActionType): MiddlewareHandler => async (c, next) => {
  const groups = (c.env.event.requestContext.authorizer?.jwt?.claims?.['cognito:groups'] as string[]) ?? [];
  if (!isAllowed(groups, action)) throw new UnauthorizedError();
  await next();
};
// route wiring:
app.use('/posts', authorize(ActionType.POSTS_CREATE), audit(ActionType.POSTS_CREATE));
app.openapi(createPost, createPostHandler);
```
**Middleware order:** logger → authorize → audit → handler; `app.onError` centralizes errors.

**Claims (auth is external):**
```typescript
const claims = c.env.event.requestContext.authorizer?.jwt?.claims ?? {};  // validated by the API GW authorizer
```

**Testing (vitest).** Unit/integration tests run on vitest; the coverage gate (≥ 85%, see the Quality
gates section) is enforced via `vitest.config.ts`:
```ts
test: { coverage: { provider: 'v8', thresholds: { lines: 85, functions: 85, branches: 85, statements: 85 } } }
```
Test routes with `app.request(...)` (no network); mock DynamoDB/secrets at the module boundary. lcov
feeds SonarCloud. Contract/smoke tests run separately (see the Contract section).

Deps: `hono`, `@hono/zod-openapi`, `zod`. No `@middy/core`. og-edge is **not** Hono (see the OG-image +
bot-rendering section).

### Decision & trade-off
- **One Hono `OpenAPIHono` app — a modular monolith — replaces middy.** Routing + middleware + error
  handling live in one coherent model; cross-cutting concerns stay framework-agnostic and get *wired*
  here as middleware. *Trade-off:* the BFF is the one place intentionally coupled to a framework (and a
  smaller ecosystem than Express), in exchange for one tiny, Web-standard request lifecycle.
- **The schema both validates the request AND generates the OpenAPI.** The contract can't drift from the
  handler because they share the source of truth. *Trade-off:* routes must be authored the zod-openapi
  way (every input is a declared schema) rather than reading raw `req`.
- **No auth code in the framework** — middleware only reads claims the API GW authorizer already
  validated. *Trade-off:* the BFF trusts the GW authorizer absolutely (it must front every route).
- **snake_case end-to-end, no mapping layer** — DB item, TS type, and request/response JSON use the
  identical field names. *Trade-off:* couples the public API shape to the storage shape, traded for zero
  mapping/DTO code.

### Pros & cons
**Pros:** tiny, fast, Web-standard router; `@hono/zod-openapi` generates the contract from code;
replaces middy with one coherent middleware model.
**Cons:** smaller ecosystem than Express; the single place intentionally coupled to a framework.

---

## Handler pattern — a domain module

A feature is a **domain module** that registers its routes onto the one BFF app — **not** a separate
Lambda. The single entry (`src/index.ts`, above) creates the app, wires the middleware, and registers
every module's routes; a module just exposes a `register{Name}(app)` that mounts onto that app.

**Files per module — `src/modules/{name}/`:**
- **`routes.ts`** — `register{Name}(app)`: mounts the module's routes and attaches `audit`/`authorize`
  per route (the `createRoute` + zod + middleware pattern is in the Framework section above). **Public**
  routes (public GETs, `/og-meta`, `/prerender`, `/health`) carry no authorizer; **mutations** are
  admin-only.
- **`handler.ts`** — route handlers (request → repository), shaped for the SPA.
- **`repository.ts`** — DynamoDB access (`getDocClient()` from `shared/db`); `Get`/`Query` only, never
  `Scan` in a hot path; cache-aside where read-heavy (see Redis cache section).
- **`__tests__/`** — vitest unit tests.

**Mandatory conventions:**
- snake_case everywhere (DB = TS = JSON, no mapping layer).
- **Opaque path ids** — a resource is addressed by a **slug** (articles) or a generated **hashid/nanoid
  `public_id`** (posts/etc.), **never** a sequential integer (non-enumerable, no information leak). Use
  the `public_id`/slug as the table key (or a GSI partition key). RESTful nouns, kebab-case paths.
- ActionType declared centrally, passed statically to `audit()` — never derived from method/path (see
  the Action types section).
- HTTP errors: throw `AppError`/`NotFoundError`/`UnauthorizedError` — never inline 4xx; the central
  handler maps it (see the Error handling section, wired in the Framework section).
- SDK clients (DynamoDBDocumentClient, SecretsManager, Redis) module-level, never inside a handler.
- **No auth code** — requests are already validated by the API GW Cognito authorizer; read claims from
  `c.env.event.requestContext.authorizer?.jwt?.claims` (e.g. `cognito:groups`) for RBAC/shaping.
- Sensitive values from Secrets Manager (see Secrets section); non-secret config from the Config section.
- The domain is a **modular monolith** now; a module can later become a microservice the BFF calls —
  without changing the SPA.
- og-edge is the exception: NO Hono / VPC — it's Lambda@Edge (see OG-image + bot-rendering section).

### Decision & trade-off
- **A feature is a module that registers routes onto the one BFF app — never its own Lambda.** Keeps the
  modular monolith (one deploy, one cold-start budget) and lets a module graduate to a microservice later
  without an SPA change. *Trade-off:* modules share the BFF Lambda's resources/limits and fault domain.
- **The handler reads claims and orchestrates; it never authenticates and never touches `process.env`
  directly.** Auth is the GW authorizer's job; non-secret config comes from the typed `config` accessor
  and sensitive values from Secrets Manager at runtime. *Trade-off:* a little indirection (config +
  secrets accessors) for one consistent, testable module shape.
- **SDK clients are module-level singletons, reused across warm invocations — never constructed in a
  handler.** *Trade-off:* the client lives for the container lifetime (rotation picked up on the next
  cold start) in exchange for connection reuse and lower per-request latency.

### Pros & cons
**Pros:** consistent module shape (routes + audit + DynamoDB) that registers into the one app; testable
in-process with `app.request()`.
**Cons:** a convention to learn; modules share the BFF Lambda's resources/limits.

---

## Error handling

**Mandatory rule: throw typed errors — never return an inline 4xx.** A single central handler (wired in
the Framework section) maps thrown errors to the HTTP response; handlers stay on the happy path.

**Error classes (`src/shared/errors/http-errors.ts`):**
```typescript
export class AppError extends Error {
  constructor(public statusCode: number, public code: string, message: string) {
    super(message); this.name = this.constructor.name;
  }
}
export class NotFoundError extends AppError { constructor(m = 'Resource not found') { super(404, 'not_found', m); } }
export class UnauthorizedError extends AppError { constructor(m = 'Unauthorized') { super(401, 'unauthorized', m); } }
// ValidationError → 400, ForbiddenError → 403 follow the same pattern.
```

**Response shape (every error)** — snake_case body, consistent across the API; status = the error's
`statusCode`:
```jsonc
{ "error": "not_found", "message": "Post not found" }
```
The central handler maps `AppError` → its `statusCode` + `{ error: code, message }`; anything else →
`500` `internal_error` with a generic message (real cause logged, never leaked).

**Usage in handlers:**
```typescript
const post = await repository.get(slug);
if (!post) throw new NotFoundError('Post not found');
if (!groups.includes('admin')) throw new UnauthorizedError();
```

Schema-validation failures map to a `400` `ValidationError` so they share the shape.

### Decision & trade-off
- **Throw typed errors; never return an inline 4xx.** One central middleware is the **single source of
  truth** for status code + body shape. *Trade-off:* discipline — every failure path must `throw` (a
  stray `return c.json(..., 400)` silently bypasses the contract) — in exchange for one place owning
  status/shape.
- **`AppError` carries `(statusCode, code, message)`; anything unrecognized → `500 internal_error`.**
  Unknown exceptions never leak internals. *Trade-off:* a genuinely-expected non-2xx must be modeled as
  an `AppError` subclass, or it degrades to a 500.
- **Schema-validation failures fold into the same `{ error, message }` body** (zod → `400
  ValidationError`), so the SPA parses one error contract everywhere. *Trade-off:* the validation layer
  is adapted to the error model rather than surfacing the framework's default 400.

### Pros & cons
**Pros:** uniform error→HTTP mapping in one middleware; consistent `{ error, message }` body for the
SPA.
**Cons:** relies on a central error middleware being wired; custom error classes to maintain.

---

## Logging

**Standard: AWS Lambda Powertools Logger** — structured JSON logs, framework-agnostic. **Never
`console.log`** in VPC handlers.
```typescript
import { Logger } from '@aws-lambda-powertools/logger';
export const logger = new Logger({
  serviceName: process.env.POWERTOOLS_SERVICE_NAME,    // <project>-bff, set by IaC
  logLevel: (process.env.LOG_LEVEL ?? 'INFO') as any,  // WARN prod, DEBUG staging (IaC)
});
```
```typescript
logger.appendKeys({ action_type: 'posts_list' });
logger.info('listing posts', { cursor, limit });
logger.error('dynamodb query failed', { error });
```

**Conventions:** JSON only, custom fields snake_case; never log the raw event or the `Authorization`
header (PII/JWT); attach the Lambda context (cold-start, request id) once per request and reset
appended keys afterward (wired in the Framework section); levels via `LOG_LEVEL`: DEBUG (staging) / WARN
(production). `og-edge` (Lambda@Edge) has no Powertools — minimal `console` only.

### Decision & trade-off
- **Structured JSON via Powertools Logger — never `console.log`.** One toolkit owns Logger/Metrics/Tracer;
  JSON lines are queryable in CloudWatch Logs Insights and double as the EMF metric carrier (see Metrics
  section). *Trade-off:* structured-logging discipline (append keys, don't string-concat) for
  machine-queryable logs with no separate log backend.
- **Level per env via `LOG_LEVEL` (DEBUG staging / WARN production); never log the raw event or
  `Authorization` header.** *Trade-off:* less verbosity in prod (cheaper retention, fewer leaks) at the
  cost of needing a redeploy/log-level change to capture DEBUG in production.

### Pros & cons
**Pros:** structured JSON logs, correlation ids, per-env level; integrates with metrics/tracer;
PII/Authorization never logged.
**Cons:** requires structured-logging discipline; verbose logs carry a retention cost.

---

## Metrics

**Why EMF, not Prometheus, not a collector.** Lambda is ephemeral — Prometheus' pull/scrape model
doesn't apply (no stable endpoint to scrape), and a long-running collector adds cost. Metrics are
**pushed as EMF (Embedded Metric Format)**: the function writes a structured JSON log line with embedded
metrics to its log group; CloudWatch **auto-extracts** them as metrics. No ADOT collector, no Amazon
Managed Prometheus.

**Powertools Metrics (`src/shared/metrics.ts`):**
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
**Flush once per invocation** — call `metrics.publishStoredMetrics()` in a `finally`, wired in the Hono
handler/middleware; optionally `metrics.captureColdStartMetric()`. The EMF lands in the BFF log group;
CloudWatch extracts metrics under the project/env namespace.

**Conventions:** **no `cloudwatch:PutMetricData`** — EMF metrics are extracted from logs, so the exec
role needs no metrics IAM action; **low cardinality** — dimensions limited to `action_type` /
`environment` / `service`, never `user_id` or id-bearing paths. Suggested metrics: request count +
latency, cache hit/miss (see Redis cache section), DynamoDB query duration, handler errors. `og-edge`
emits no metrics (edge constraints).

### Decision & trade-off
- **EMF over a separate metrics backend/collector.** The function writes a structured log line and
  CloudWatch auto-extracts the metrics — no ADOT collector, no Amazon Managed Prometheus, no scrape
  endpoint (which an ephemeral Lambda can't host anyway). *Trade-off:* metrics surface only after log
  ingestion (slight delay) and you live within CloudWatch Metrics, not a richer dedicated TSDB — accepted
  for cost/simplicity.
- **No `cloudwatch:PutMetricData` IAM action** — metrics ride the log stream, so the exec role needs only
  basic logs perms. *Trade-off:* tied to the log-extraction path; a metric is only as timely as its log
  line.
- **Low-cardinality dimensions only.** *Trade-off:* you can't slice by high-cardinality identity, in
  exchange for predictable metric cost (cardinality is the cost driver).

### Pros & cons
**Pros:** serverless-native EMF — no collector, no `PutMetricData` IAM; low-cardinality discipline keeps
cost predictable.
**Cons:** metrics surface only after log ingestion (slight delay); cardinality limits constrain
dimensions.

---

## Tracing

The third observability pillar (with Logging + Metrics): **AWS Lambda Powertools Tracer** over
**X-Ray** — see a request across the BFF and its downstream calls (DynamoDB, Redis, SES, future
microservices).
```typescript
import { Tracer } from '@aws-lambda-powertools/tracer';
export const tracer = new Tracer({ serviceName: process.env.POWERTOOLS_SERVICE_NAME });
```
Enable **active tracing** on the Lambda and the API GW stage; sampling rules + service map are the
infrastructure side (see `cloud-infrastructure`). The framework wiring (a middleware that opens a
segment per request, marks cold start + response, closes on error) lives in the Framework section above.

```typescript
const sub = tracer.getSegment()?.addNewSubsegment('dynamodb.posts.query');
try { /* query */ } finally { sub?.close(); }
tracer.putAnnotation('action_type', 'posts_list');   // indexed → filterable in X-Ray
tracer.putMetadata('cursor', cursor);                // non-indexed context
// auto-capture downstream as subsegments:
const db = tracer.captureAWSv3Client(new SESv2Client({}));
```

**Conventions:** **annotations** = indexed, low-cardinality (`action_type`, `success`) for filtering;
**metadata** = rich context — never PII. Correlate with logs/audit via the same `request_id`. `og-edge`
has no Powertools — no tracing there.

### Decision & trade-off
- **Powertools Tracer over X-Ray — the native AWS tracer, no dedicated APM.** Same Powertools toolkit as
  Logger/Metrics, zero extra infrastructure, and it auto-instruments downstream AWS SDK calls.
  *Trade-off:* X-Ray is less rich than a dedicated APM and sampling can miss a trace — accepted for
  cost/simplicity, consistent with the EMF-not-Prometheus call.
- **Annotations are indexed + low-cardinality; metadata is rich context; neither carries PII.** Only
  annotations are filterable in X-Ray, so identity/raw context goes in metadata. *Trade-off:* you choose
  at write time what's queryable vs. merely attached.

### Pros & cons
**Pros:** end-to-end traces (API GW→Lambda→browser), annotations, downstream capture; correlates with
RUM for full-stack visibility.
**Cons:** sampling can miss a trace; minor runtime overhead; X-Ray is less rich than a dedicated APM.

---

## Audit trail

Every user interaction produces **one audit item** in the `audits` DynamoDB table, written **after** the
handler runs: the request is timed, then the request/response + the caller's claims + the route's
`action_type` are assembled into an item and `Put`. Audit failures are **fail-open** (logged, never
breaking the request). The `Authorization` header and any credential material are excluded. `og-edge`
writes no audit.

**Identity — from the validated token, no session store.** The "who" comes from the **JWT claims** the
API GW Cognito authorizer already validated and injected into the request (`sub`, `cognito:groups`) —
read per request, **zero lookup, no session cache**. This is why the BFF stays stateless and Redis is
cache-only. `user_id = sub` is the canonical reference (always present); `email` is usually not in the
*access* token — include it via a Cognito Pre-Token-Generation trigger, or enrich `sub → profile` on
demand (optionally cached in Redis with a TTL).

**Item shape (`audits` table)** — one item per user interaction, all fields snake_case:
```jsonc
{
  "audit_id": "nanoid",                   // partition key
  "timestamp": "2026-06-06T12:00:00.000Z", // ISO-8601 string, when the request completed
  "ttl": 1717675200,                      // epoch seconds — DynamoDB TTL set on write (retention)
  "action_type": "posts_create",          // the route's declared action
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
**Access:** `Get` by `audit_id`; lists go through a `by-entity` GSI (e.g. `user.user_id` or
`action_type` as GSI partition key, `timestamp` as sort key) — `Query` only, **never `Scan`**. Retention
is the `ttl` epoch attribute the app sets on write (DynamoDB TTL), not a TTL index.

The Hono middleware `audit(action)` that runs after the handler and writes this item is defined in the
Framework section above; the action constants are the next section.

### Pros & cons
**Pros:** automatic, uniform audit trail with no per-handler code; identity comes from the JWT claims;
queryable history of every state-changing interaction; lives next to the data (same DynamoDB), reached
with the same SDK v3 client.
**Cons:** a write per request adds latency + DynamoDB write cost on hot paths (mitigate: fire-and-forget,
or batch/async via a queue if volume grows); coupled to the request DB (fail open); stores PII (set the
`ttl` retention attribute + access controls); captures response **status only** by default — add body
capture deliberately, with truncation + redaction; the document shape must evolve carefully (snake_case,
no mapping layer).

---

## Action types

Action types are the stable identifier behind **three things**: (1) **audit identification** — every
user interaction is written to `audits` classified by `action_type`; (2) **RBAC composition** — the
**unit of authorization**; (3) **feature toggling per profile** — each capability is a named action, so
a profile's enabled set can flip on/off per role, no deploy. **One constant, used by all three**, so
audit, authz and flags never drift.

**Mandatory rule:** every action is declared **statically** as a central constant and attached to its
route — **never derived from the HTTP method/path at runtime**.

**Central definition (`src/shared/constants/action-types.ts`):**
```typescript
// TypeScript const = SCREAMING_SNAKE_CASE; stored DB value = snake_case (audits.action_type)
export const ActionType = {
  PROFILE_GET:        'profile_get',
  POSTS_LIST:         'posts_list',
  POSTS_CREATE:       'posts_create',
  POSTS_UPDATE:       'posts_update',
  POSTS_DELETE:       'posts_delete',
  ARTICLES_LIST:      'articles_list',
  ARTICLES_GET:       'articles_get',
  SUBSCRIBERS_CREATE: 'subscribers_create',
  OG_IMAGE_GENERATE:  'og_image_generate',
} as const;
export type ActionType = (typeof ActionType)[keyof typeof ActionType];
```

**RBAC composition (when authorization is needed).** Authorization is expressed as a **map of role →
allowed action types**: the route's declared action type is checked against the caller's role (groups),
so the same constant drives both audit and authz. `admin` → all actions · `registered` → e.g.
`subscribers_create` · `public` → the open reads. A request is authorized iff one of its groups grants
the route's action type; otherwise `UnauthorizedError`. Use it **only when needed** — a simple group
check (the three Cognito profiles) is often enough; promote to an action-type map when permissions get
finer-grained. **Feature toggles:** make the map **config-driven** to flip a profile's allowed set at
runtime (no deploy); expose the user's allowed actions (a `/me` route) so the SPA renders UI
accordingly.

**Conventions:** constant **name** SCREAMING_SNAKE_CASE, stored **value** snake_case — same value
everywhere, no mapping. One action type per handler action; add the constant **before** wiring a route —
never inline a string literal. `og-edge` writes no audit and declares no action type. The Hono
middleware that attaches `audit(action)`/`authorize(action)` to routes is in the Framework section above.

### Pros & cons
**Pros:** single source of truth for "what actions exist" — drives audit, RBAC and flags consistently;
authorization decoupled from method/path; explicit, greppable, testable; type-safe — handlers reference
constants, not strings.
**Cons:** manual upkeep (every new action needs a constant + RBAC entry); coarse-grained (action-level,
not row/attribute-level — "edit *own* post" needs an extra ownership check); overkill for tiny surfaces;
a shared enum couples modules to one list.

---

## Redis cache

**Pattern: cache-aside (lazy), fail-open.** Read public, read-heavy data through Redis; on miss, read
DynamoDB and populate with a TTL. **If Redis is unavailable, fall back to the database — a cache error
must never fail the request.** Redis is VPC-only, so enabling it puts the BFF in-VPC (it is non-VPC by
default).

**Client singleton (`src/shared/cache/client.ts`):**
```typescript
import Redis from 'ioredis';
import { getSecret } from '../secrets';
import { config } from '../config';
import { logger } from '../middleware/powertools';

let client: Redis | null = null;

export async function getCache(): Promise<Redis | null> {
  if (client) return client;
  try {
    const { auth_token } = config.redisSecretArn
      ? await getSecret<{ auth_token: string }>(config.redisSecretArn) : { auth_token: undefined };
    client = new Redis({
      host: config.redisEndpoint, port: 6379,
      password: auth_token, tls: auth_token ? {} : undefined,   // in-transit encryption
      lazyConnect: true, enableOfflineQueue: false,
      maxRetriesPerRequest: 1, commandTimeout: 200,             // fail fast → fall back to DB
    });
    client.on('error', (e) => logger.warn('redis error', { error: e.message }));
    await client.connect();
  } catch { client = null; }
  return client;
}
```

**Cache-aside helper:**
```typescript
export async function cached<T>(key: string, ttl: number, load: () => Promise<T>): Promise<T> {
  const redis = await getCache();
  if (redis) { try { const hit = await redis.get(key); if (hit) { cacheHits.add(1); return JSON.parse(hit); } } catch {} }
  cacheMisses.add(1);
  const value = await load();                                            // DynamoDB
  if (redis) redis.set(key, JSON.stringify(value), 'EX', ttl).catch(() => {});  // best-effort
  return value;
}
```

**Key convention + TTLs — `{env}:{resource}:{id}` (snake_case):**

| Key | TTL | Notes |
|---|---|---|
| `{env}:profile:default` | 3600s | CV rarely changes |
| `{env}:posts:list:{cursor}` | 60s | feed, short TTL |
| `{env}:article:{slug}` | 300s | long-form |

Never cache `subscribers`, `audits`, or any per-user authenticated mutation.

**Invalidation on writes.** Admin mutations delete affected keys (don't wait for TTL). Prefer a
**version/namespace bump** over `KEYS *` scans in production:
```typescript
// posts_create / posts_update / posts_delete → bump the list namespace version
await redis?.incr(`${env}:posts:list:version`);
```

**Conventions:** connection reused across warm invocations (singleton, `lazyConnect`) — never connect
per request; reached in-VPC over the cluster SG (port 6379, off the NAT path) — DynamoDB, by contrast, is
reached over its VPC gateway endpoint, not the cluster SG; AUTH token from Secrets Manager (see Secrets
section), endpoint from `REDIS_ENDPOINT` (IaC); emits `cache_hits_total`/`cache_misses_total`.

### Pros & cons
**Pros:** cuts latency and DB load; fail-open (cache down is not an outage); TTL + invalidation; in-VPC,
low latency.
**Cons:** a staleness window between writes and invalidation; invalidation is per-write/manual; one more
dependency.

---

## Config

**One contract, two delivery mechanisms.** Both sides obey the same three rules — a single typed
accessor, non-secret values only, and the same key present in every environment — and differ only in
*when* the value arrives:

> **Can the consumer read a value at the moment it runs?** A server process can, so its config is
> **runtime**. A static bundle already sitting in a browser cannot, so its config is **build-time** —
> baked in, public, and changed only by rebuilding.

Sensitive values follow neither path (see the Secrets section); the parameters themselves are written by
infrastructure (`cloud-infrastructure`).

**Server side — `.env.{environment}` (dotenv) + one typed accessor.** Non-secret, per-environment config
lives in committed `.env.{environment}` files; a single `config` module is the only place that reads
`process.env`.
```
.env.staging       # non-secret defaults for staging
.env.production    # non-secret defaults for production
.env.local         # local dev overrides (gitignored)
```
Loading (local + tests only — deployed functions get these keys injected by IaC env vars):
```typescript
import dotenv from 'dotenv';
dotenv.config({ path: `.env.${process.env.ENVIRONMENT ?? 'local'}` });
```
**Typed accessor** — the only module that touches `process.env`, and the only place a missing key is
allowed to be discovered:
```typescript
function required(name: string): string {
  const v = process.env[name];
  if (!v) throw new Error(`Missing required env var: ${name}`);
  return v;
}

export const config = {
  environment:    required('ENVIRONMENT'),          // staging | production
  logLevel:       process.env.LOG_LEVEL ?? 'INFO',
  ogImagesBucket: required('OG_IMAGES_BUCKET'),
  redisEndpoint:  required('REDIS_ENDPOINT'),
  redisSecretArn: process.env.REDIS_SECRET_ARN,     // secret ARN — the value is fetched at runtime
  // table names (IaC injects them from the parameter store); access is pure IAM, no secret
  profileTable:       required('PROFILE_TABLE'),
  postsTable:         required('POSTS_TABLE'),
  articlesTable:      required('ARTICLES_TABLE'),
  subscriptionsTable: required('SUBSCRIPTIONS_TABLE'),
  auditsTable:        required('AUDITS_TABLE'),
} as const;
```
`required()` throwing at module load is the point: the process fails on the first invocation with a
clear message, rather than at 3am inside a handler with an `undefined` in a table name. **Two sources,
one shape:** `.env.{environment}` populates `process.env` locally; in the cloud the **same keys** are
injected by IaC — the `config` module does not care which.

**Client side — parameter store → CI → `VITE_*` at build.** A static bundle has no runtime config
source, so CI reads the values and injects them as `VITE_*` **before** the build; a single typed
accessor is again the only place that reads them. Source of truth = the parameter store (written by
infrastructure); typical keys: API base URL, identity-provider ids and hosted-UI domain, analytics
measurement id, RUM app-monitor and identity-pool ids, region. **A value change requires a rebuild and
redeploy** — there is no way to change a baked value in place.

**Conventions:** nothing sensitive on either path, for two different reasons — server secrets are
fetched at runtime from a secret store, and in a bundle **everything shipped to a browser is public**,
so a secret in a `VITE_*` variable is already disclosed; one accessor per side; the same key exists in
every environment, even when the value differs; `.env.*` files are not a deploy artifact; local overrides
(`.env.local`) are gitignored.

### Pros & cons
**Pros:** one typed, validated accessor per side; a missing key fails fast and by name; single source of
truth both mechanisms draw from; local and deployed runs share a key shape, so a local reproduction is
meaningful.
**Cons:** client values are build-time only — changing one needs a rebuild and redeploy; the "is this
really non-secret" judgement is load-bearing and easy to get wrong under time pressure; drift risk if a
variable is added in one environment but not another; a deploy misconfiguration surfaces as an
application bug rather than a pipeline failure.

---

## Secrets

**Rule: every sensitive value comes from Secrets Manager at runtime** — never from `.env`, SSM plain
text, hardcode, or tfvars. IaC stores only the **ARN** (env var / SSM); the Lambda fetches the value on
cold start and caches it in memory. In Secrets Manager: the Redis AUTH token, third-party API keys (e.g.
an out-of-band GIF-search proxy key), and any future tokens. The **data tier has no secret** —
DynamoDB access is pure IAM via the Lambda exec role, so there's no DB credential to fetch here.
Non-secret config stays in `.env`/IaC env vars (see the Config section).

**Singleton + in-memory cache (`src/shared/secrets.ts`):**
```typescript
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

const sm = new SecretsManagerClient({});             // module-level, reused across invocations
const cache = new Map<string, unknown>();

export async function getSecret<T>(secretArn: string): Promise<T> {
  if (cache.has(secretArn)) return cache.get(secretArn) as T;
  const { SecretString } = await sm.send(new GetSecretValueCommand({ SecretId: secretArn }));
  const value = JSON.parse(SecretString!) as T;
  cache.set(secretArn, value);                       // cache for the warm container lifetime
  return value;
}
```
```typescript
const { auth_token } = await getSecret(config.redisSecretArn);                       // redis client
```

**Conventions:** secret JSON fields are snake_case (`auth_token`, `dbname`); fetch by **ARN** from
`config` (the ARN itself is non-sensitive); Lambda role needs `secretsmanager:GetSecretValue` scoped to
`<project>/{env}/*`; cache in memory for the container lifetime — never re-fetch per request, rotation is
picked up on the next cold start; naming: `<project>/{env}/{component}`.

### Decision & trade-off
- **Pattern B for secrets: IaC owns the config (the ARN in env/SSM); code reads the value at runtime.**
  The secret value never sits in the env, the bundle, tfvars, or state — only the non-sensitive ARN
  travels there. *Trade-off:* a runtime fetch (one cold-start round trip to Secrets Manager) instead of
  baking the value into an env var.
- **Fetched once per cold start, then cached in process memory**, never re-fetched per request.
  *Trade-off:* a rotation is only picked up on the next cold start — acceptable for tokens that rotate
  rarely; force a new deploy to roll one immediately.
- **Only genuinely-secret values go here; the data tier has none.** DynamoDB is pure IAM. *Trade-off:* a
  clear two-bucket split to maintain — putting a non-secret in Secrets Manager wastes a fetch, putting a
  secret in env leaks it.

### Pros & cons
**Pros:** secrets never in env/code; fetched at runtime and cached in memory; only the ARN travels via
env/SSM.
**Cons:** cold-fetch latency on first use; cache must be invalidated on rotation.

---

## Contract — OpenAPI

**Principle: the contract is maintained automatically by the backend.** It is generated from the code
itself on every change (`@hono/zod-openapi`, see the Framework section — `app.getOpenAPI31Document`), so
the OpenAPI can **never drift** from the implementation — there is no manual update step to forget.

1. **Generated from code, never hand-written** — the route/schema definitions are the single source of
   truth.
2. **Versioned with the backend** — the generated spec's `info.version` is stamped with the backend's
   current **VERSION** (the SemVer tag, `/devops`). Each release's contract carries the same version as
   the code that produced it.
3. **A committed copy lives at the repo root** — the generated `openapi.json` is written to the root and
   committed, so it's diffable in PRs, reviewable, and consumable without running the app.

**Generation (CI + local):**
```bash
VERSION=$(cat VERSION)
<gen-command> --version "$VERSION" --out openapi.json     # framework adapter → version-stamped root copy
```
Runs on build/deploy **and** as a CI/pre-commit check: regenerate and **fail if the root `openapi.json`
is out of date** (contract-drift guard).

**Two artifacts.** The **root `openapi.json` is vendor-neutral** — pure paths + schemas + security scheme
references; this is the reviewable/consumable contract. **When publishing to AWS API Gateway**, the spec
must carry AWS-specific extensions, produced as an overlay on top of the neutral contract, not committed
at root: `x-amazon-apigateway-integration` per route → the Lambda invoke ARN (single BFF integration);
`x-amazon-apigateway-authorizer` + `securitySchemes` → the Cognito authorizer (provider ARN = the user
pool, from SSM); CORS via an `OPTIONS` (MOCK) per route + `x-amazon-apigateway-gateway-responses`, with
the BFF echoing the origin on 2xx. Applied at deploy (envsubst) → `aws apigateway put-rest-api --mode
overwrite` + `create-deployment` (`/devops`, `cloud-infrastructure`).

**Downstream:** API Gateway re-imports the root contract + AWS overlay; clients/tests read the committed
root copy (see the Postman section below).

**Conventions:** `info.version == backend VERSION`, `info.title == the service name`; regenerated +
committed every release, a stale root copy is a failing gate; snake_case schemas; **never hand-edit** the
generated file, keep AWS extensions in the overlay template out of the neutral root copy.

### Pros & cons
**Pros:** contract generated from code — no drift; version-stamped, committed root copy; AWS overlay
applied only at deploy (clean source contract).
**Cons:** a generation step in CI; zod-openapi annotations to maintain.

---

## Contract tests — Postman

Postman collections document and smoke/contract-test the API; run headless via **newman** in CI.

**Files** — a `postman/` directory at the API app's root, versioned by the same commit as the code it
checks:
- `<project>-api.postman_collection.json` — all routes + request examples + test scripts (`pm.test(...)`).
- **One environment file per environment** — `local`/`staging`/`production` `.postman_environment.json`,
  each with `base_url` + a `token` var (**no secrets committed**). One command targets local or any AWS
  env.
- `package.json` scripts (`api-test:local` / `:staging` / `:production`) run `newman run <collection> -e
  postman/<env>.postman_environment.json`, injecting the auth token at runtime.

**Standard: every feature ships its regression.** Adding/changing an endpoint MUST add/update its
Postman request + `pm.test` assertions in the same PR (smoke + contract + the auth path). A new entity =
new requests for its public GETs, admin writes (401 without token, 200/201 with), and the response
shape.

**Auth on social-only Cognito (Google) needs a NATIVE test user.** Google sign-in can't be automated, so
an interactive token won't do. Use an **admin-created native Cognito user** + a client with
`USER_PASSWORD_AUTH` to mint a token via `InitiateAuth` (no Google) — a `cloud-infrastructure` change.
Store the token as a CI secret (`TEST_USER_TOKEN`) injected via `--env-var token=...`. Until it exists,
the authed-write checks stay skipped (the `401-without-token` check runs everywhere).

**What it covers:** smoke (`GET /health`, `GET /profile` → 200 + expected shape), contract (response
bodies match the generated OpenAPI, snake_case fields), auth (protected routes → 401 without a bearer
token, 200 with a valid one).

**CI (newman)** — post-deploy smoke against the just-deployed env, as the last step of the deploy
workflow:
```yaml
- name: API smoke (newman) against the deployed environment
  run: |
    sleep 5 # let the new stage settle
    npm run "api-test:$ENV_NAME" -- --env-var "token=${{ secrets.TEST_USER_TOKEN }}"
```
A red smoke surfaces a regression the just-shipped deploy introduced; can also run **locally against any
env**.

**Conventions:** keep the collection in sync with the generated OpenAPI (no divergent hand-maintained
spec); no secrets in the committed environment file; treat it as smoke/contract, not full coverage —
vitest owns coverage (see Quality gates below).

### Pros & cons
**Pros:** black-box contract checks against a real deployed BFF; covers the Bearer-JWT auth path; lives
in the BFF next to the code it checks.
**Cons:** smoke/contract only — not a coverage substitute; needs a running environment + tokens.

---

## Notifications

The `notifications` module of the BFF — emails registered subscribers (e.g. on a new post) and manages
subscriptions.

**Send via SES (SDK v3):**
```typescript
import { SESv2Client, SendEmailCommand } from '@aws-sdk/client-sesv2';
const ses = new SESv2Client({});                              // module-level singleton

export async function sendEmail(to: string, subject: string, html: string) {
  await ses.send(new SendEmailCommand({
    FromEmailAddress: process.env.SES_FROM_ADDRESS,           // no-reply@<apex-domain> (IaC)
    Destination: { ToAddresses: [to] },
    Content: { Simple: { Subject: { Data: subject }, Body: { Html: { Data: html } } } },
  }));
}
```
Lambda role needs `ses:SendEmail`; reaches SES over the public AWS endpoint (non-VPC, no NAT; via NAT
only if the BFF is in-VPC). Templates: simple HTML strings now; move to SES **templates**/`SendBulkEmail`
when volume/variety grows.

**Subscriptions (table `subscribers`):**
```jsonc
{ "cognito_sub": "…", "email": "…", "status": "active | unsubscribed", "created_at": "2026-01-01T00:00:00Z" }
```
`POST /subscriptions` upserts an `active` subscriber (from the validated claims); `DELETE /subscriptions`
(or a one-click unsubscribe link/token) sets `status = "unsubscribed"`. Partition key `cognito_sub`;
query active subscribers via a `status` GSI.

**Sync vs async — never block the request.** A publish that notifies **N** subscribers must **not** run
inline — fan-out is slow and fails partially. **Now (monolith):** publish a `post_published` domain
event to an **SNS** topic and return immediately; an SNS-subscribed Lambda fans out the emails, with a
**DLQ** on the subscription for failed deliveries — the cheapest/simplest fan-out. **Idempotency:**
dedupe by `(post_id, subscriber_id)` so retries don't double-send; fan-out reads `subscribers` where
`status = "active"` and batches.

**Conventions:** snake_case payloads; from-address + region from env; **SES sandbox** — new accounts only
send to verified addresses, production access is a one-time manual request; audit the action
(`subscribers_create`, etc.), identity from claims.

### Decision & trade-off
- **SES for delivery + SNS for async fan-out — a notify-N publish never runs inline.** The request
  publishes one domain event and returns; a subscribed Lambda fans out the emails with a DLQ for
  failures. *Trade-off:* delivery is eventual (failures land in the DLQ, not in the response), in
  exchange for a fast request and partial-failure isolation. SNS is the cheapest pub/sub for this.
- **Scheduled digests are EventBridge-cron-driven, not a long-running worker** — the schedule fires a
  Lambda (pay-on-fire), so there's ~$0 idle cost. *Trade-off:* batch cadence (cron granularity) rather
  than real-time, which is exactly what a digest wants.
- **Fan-out is idempotent** (dedupe by `(post_id, subscriber_id)`) so retries don't double-send.
  *Trade-off:* a dedupe key to maintain, for at-least-once delivery safety.

### Pros & cons
**Pros:** SNS async fan-out decouples producers from consumers; SES delivers email; subscriptions + DLQ
handle retries/failures.
**Cons:** SES sandbox + deliverability concerns; delivery is eventual, failures land in the DLQ, not
inline.

---

## OG-image generation

Module at `src/modules/og-image/` under the BFF app's root. **Pattern: generate PNG on-demand, cache in
S3, serve via the CDN.**

**Route** (`routes.ts`) — public BFF route `GET /og/{type}/{slug}.png` (no authorizer), cache-aside:
1. S3 key = **`og/{type}/{slug}.png`** — the FULL public path. CloudFront's `/og/*` behavior forwards the
   URI **verbatim** to the S3 origin (it does NOT strip the matched prefix), so the object must live
   under `og/…` or the CDN 404s. *(This bit everyone once: storing `{type}/{slug}.png` makes the API 302
   fine but the CDN serve a 403→SPA fallback.)*
2. `objectExists(key)` via `HeadObject`. **Hit** → 302 to `${spaOrigin}/${key}`.
3. **Miss** → `getProfile()` → generate → `PutObject(key)` → 302 to `${spaOrigin}/${key}`.

The PNG bytes are **never** served through API Gateway — the BFF 302s to the CloudFront `/og/*` behavior
(→ S3), so the binary rides the CDN and the API stays JSON-only.
```typescript
const key = `og/${type}/${slug}.png`;
if (!(await objectExists(key))) {
  const profile = await getProfile();
  if (!profile) throw new NotFoundError('profile not found');
  const { generateOgImage } = await import('./generator'); // lazy — see bundling below
  await putImage(key, await generateOgImage(profile));
}
return c.redirect(`${config.spaOrigin}/${key}`, 302);
```

**`generator.ts`** — satori (element tree → SVG) + **`@resvg/resvg-wasm`** (SVG → PNG):
```typescript
import satori from 'satori';
import { initWasm, Resvg } from '@resvg/resvg-wasm';
import resvgWasm from '@resvg/resvg-wasm/index_bg.wasm';        // → Uint8Array (esbuild binary loader)
import interRegular from '@fontsource/inter/files/inter-latin-400-normal.woff';
import interBold from '@fontsource/inter/files/inter-latin-700-normal.woff';

let wasmReady: Promise<void> | undefined;                       // initWasm throws if called twice — memoise
const ensureWasm = () => (wasmReady ??= initWasm(resvgWasm as unknown as ArrayBuffer));

export async function generateOgImage(profile: Profile): Promise<Uint8Array> {
  const svg = await satori(card(profile), {                     // card() = plain {type,props} tree, no JSX
    width: 1200, height: 630,                                   // OG standard size
    fonts: [{ name: 'Inter', data: interRegular as any, weight: 400, style: 'normal' },
            { name: 'Inter', data: interBold    as any, weight: 700, style: 'normal' }],
  });
  await ensureWasm();
  return new Resvg(svg, { fitTo: { mode: 'width', value: 1200 } }).render().asPng();
}
```
Build a plain element tree (no React/JSX). Every node with >1 child MUST set `display:'flex'` — satori
only lays out flexbox.

**WASM, not the native build (deliberate).** Use `@resvg/resvg-wasm`, not `@resvg/resvg-js` — the native
package ships a per-platform `.node` binary that esbuild can't bundle and needs per-arch optional-dep
juggling on CI. The WASM build + the Inter `.woff` fonts embed into one self-contained bundle via
esbuild's **binary loader** — no runtime file reads, no native binary:
```js
// esbuild.config.mjs
loader: { '.wasm': 'binary', '.woff': 'binary' },
```
Bundle ≈ 5 MB (≈1.7 MB zipped), well within Lambda limits.

**Bundling + testing gotchas.** **Lazy-import the generator** from the route — its top-level
`.wasm`/`.woff` imports break any tool that loads the app without that loader (the deploy's contract
generation step, and vitest, both throw `ERR_UNKNOWN_FILE_EXTENSION`); keeping the generator behind a
dynamic import means only a live `/og` request resolves the binaries. **Exclude `generator.ts` from
coverage** (vitest + Sonar) — its binary imports can't load under vitest; validate it with a build smoke
test (bundle a temp entry with the real loaders, render a PNG, assert the signature) + the live deploy.

**IAM.** The BFF exec role needs `s3:GetObject` + `s3:PutObject` on the og-images bucket, plus
**`s3:ListBucket` on the bucket ARN** — without it, `HeadObject` on a MISSING key returns **403** (S3
hides existence), not 404, so the cache-aside 500s on the very first request instead of generating. This
is the #1 og-image footgun.

**URL convention:** `https://api.<host>/og/{type}/{slug}.png` (the BFF route) → 302 →
`https://<host>/og/{type}/{slug}.png` (CloudFront `/og/*` → S3). Deterministic: same type+slug → same
URL. Regenerate = overwrite the key + CloudFront invalidation.

### Decision & trade-off
- **Generate the PNG once, cache it in S3, serve it from the CDN — never regenerate per request.** The
  BFF route is cache-aside (HeadObject → 302 on hit; generate → Put → 302 on miss), so the expensive
  satori→SVG→resvg→PNG path runs only on the first scrape of a given `{type}/{slug}`. *Trade-off:* a
  stored object to invalidate on content change in exchange for ~zero per-request cost/latency
  thereafter.
- **Render in-process with satori + resvg-wasm — no headless browser, and the bytes never traverse API
  Gateway.** The 302 hands the scraper a CloudFront URL so the binary rides the CDN and the API stays
  JSON-only. *Trade-off:* satori is flexbox-only with a fixed font set (lower fidelity than a real
  browser) and adds bundle/memory weight — accepted because images are cached and regenerated rarely.
- **WASM build over the native `.node` binary** so the whole thing (incl. fonts) embeds into one esbuild
  bundle with no per-arch juggling. *Trade-off:* WASM renders a touch slower — irrelevant given the S3
  cache.

### Pros & cons
**Pros:** dynamic OG images from code, cached in S3, served from the same CloudFront distribution; no
headless browser; binaries never touch API GW.
**Cons:** satori/resvg-wasm bundle size + memory (256 MB is the floor for 1200×630 — bump if it OOMs);
font/layout fidelity is limited vs a real browser.

---

## Bot rendering — og-meta + prerender

Serves the HTML the Lambda@Edge handler (below) returns to bots. Two endpoints, same data source
(DynamoDB), **no React on the server** — this is content templating, not SSR.

- `GET /og-meta/{type}/{slug}` → JSON meta for **social** scrapers: `{ title, description, image_url,
  url }`. Lightweight, no body render.
- `GET /prerender/{type}/{slug}` → **full HTML** for **search crawlers**: `<head>` (title, description,
  canonical, OG, Twitter, JSON-LD) + `<body>` with the real content + a bootstrap `<script>` that loads
  the SPA for any human who lands on it.

`{type}` ∈ `profile` (home/CV), `posts`, `articles`.

**Shared render module (`src/shared/render/`):**
```typescript
import MarkdownIt from 'markdown-it';
const md = new MarkdownIt();

export function renderArticleHtml(a: Article): string {
  const body = md.render(a.body_markdown);                 // markdown → HTML, server-side
  return htmlDoc({
    title: a.title,
    description: a.excerpt,
    canonical: `https://<apex-domain>/articles/${a.slug}`,
    ogImage: `https://<apex-domain>/og/articles/${a.slug}.png`,
    jsonLd: blogPostingJsonLd(a),
    body: `<article><h1>${a.title}</h1>${body}</article>`,
  });
}
```

**JSON-LD:** `profile` → `Person` (name, jobTitle, sameAs links); `articles` → `BlogPosting`/`Article`
(headline, datePublished, author, keywords from tags); `posts` → minimal `Article`/`SocialMediaPosting`.

**Conventions:** these are **public root routes of the BFF** (no authorizer), reusing the domain
repositories; markdown deps isolated in `shared/render`; content fields are snake_case
(`body_markdown`, `published_at`, `image_url`); HTML must mirror what the SPA renders (same content) —
not cloaking, so keep `og-meta`/`prerender` titles/descriptions identical to the client SEO output;
cached at the edge (`max-age=300`), hit/miss feeds Metrics. The OG PNG itself comes from the OG-image
section above; prerender only references its URL.

### Inbound serving vs. outbound scraping — two different things

*This serves our own content to crawlers/scrapers. Resolving a **third-party** URL's preview (link
unfurl) is the opposite direction — **outbound scraping** — and follows different rules.*

Fetching an external URL's Open Graph data is outbound scraping, distinct from serving our own pages. The
real gotcha: a **datacenter IP + a generic User-Agent** frequently gets a consent/interstitial page or a
`403`, so the OG tags aren't there. **Sending a recognized crawler User-Agent** (e.g. a
`facebookexternalhit`-style token, honestly suffixed with your own `+URL`) makes most sites serve their
OG page from the same IP — exactly how chat apps build rich cards. *Trade-off/caveat:* respect
`robots`/ToS and keep the UA honestly attributable; some providers (e.g. login-walled social) still
degrade and need their paid official API — ship a clean fallback card and leave that seam.

**All outbound fetches go through an SSRF-guarded, bounded fetcher** (allow only http/https, re-resolve +
reject private/loopback/link-local/metadata IPs on **every** redirect hop, cap time + bytes).
Server-side fetching of arbitrary URLs is a classic SSRF vector even when only an admin submits the URL.
*Trade-off:* manual redirect handling + a DNS check per hop, for a closed egress surface.

### Decision & trade-off
- **The bot API mirrors what the SPA renders from the SAME data store — it is content templating, not
  SSR and not cloaking.** `og-meta` (JSON for social) + `prerender` (full HTML + JSON-LD for crawlers)
  read the domain repositories directly; no React on the server. *Trade-off:* a **second render path**
  that must stay in lockstep with the client SEO output — keep titles/descriptions/JSON-LD identical or
  it drifts toward cloaking.
- **Public root routes, no authorizer, edge-cached (`max-age=300`)** — only bots hit them; humans get the
  SPA. *Trade-off:* anything served here is world-readable (it's for crawlers), so never include
  non-public fields.

### Pros & cons
**Pros:** crawlable HTML + JSON-LD for bots without SSR; reuses the DynamoDB data; only bots hit it —
humans get the SPA.
**Cons:** a second rendering path to keep consistent with the SPA; bot detection is heuristic.

---

## Edge classification — og-edge (Lambda@Edge)

**It lives with the Terraform, not with the API application** (`iac/lambda-src/og-edge/index.js`) — see
"Where the code lives" below. The edge does a **3-way classification** at CloudFront Viewer Request —
humans get the SPA, bots get server-built HTML: **OG previews** for social scrapers, and **dynamic
rendering** for SEO crawlers.

**Lambda@Edge constraints (mandatory):**
- NO VPC / NO Hono / NO audit / NO DynamoDB — runs at the CloudFront PoP.
- NO `process.env` at runtime → **derive the API base from the request `Host` header**:
  `https://api.${host}`. This is the project's domain convention (api.<frontend-host>), so the SAME
  artifact works in staging and production with zero build-time injection. *Trade-off:* couples the
  function to that subdomain convention — if the API ever moves off `api.<frontend-host>`, switch to a
  CloudFront custom-header origin config.
- Handler signature: `CloudFrontRequestEvent`. Generated viewer-request responses are capped at **40
  KB** (headers+body) — guard on `Buffer.byteLength` and fall back to passthrough if exceeded.
  *Trade-off:* the origin-request-rewrite alternative (point the request at the API GW origin, 1 MB cap,
  CloudFront-cacheable) is heavier infra — defer it until a rendered page approaches 40 KB.
- **Zero dependencies** — only Node built-ins (global `fetch`). Nothing to bundle: Terraform zips the
  single `index.js` directly. *Trade-off:* no TypeScript at the edge; keep the file small and plain CJS
  (`exports.handler`).
- Always **fall back to passthrough** (return the request unchanged) on any fetch error/timeout/oversize/
  unmapped path — the SPA shell is always a valid response. Use an `AbortController` with a short
  timeout (~1.5s) well under the 5s viewer-request ceiling.

**Classification (`iac/lambda-src/og-edge/index.js`, plain CJS, zero deps):**
```javascript
'use strict';
const MAX_BODY = 40000;          // viewer-request generated-response ceiling (bytes)
const TIMEOUT_MS = 1500;         // well under the 5s viewer-request ceiling
const SOCIAL  = /facebookexternalhit|twitterbot|linkedinbot|whatsapp|telegrambot|slackbot|discordbot|pinterest|redditbot|skypeuripreview|embedly/i;
const CRAWLER = /googlebot|bingbot|duckduckbot|yandex|baiduspider|applebot|petalbot|google-inspectiontool/i;

const route = (uri) => (uri === '/' || uri === '/index.html' ? { type: 'profile', slug: 'me' } : null); // Phase 1: only the homepage
const hdr = (req, n) => req.headers[n]?.[0]?.value;

async function fetchText(url) {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), TIMEOUT_MS);
  try { const r = await fetch(url, { signal: ctrl.signal }); return r.ok ? await r.text() : null; }
  catch { return null; } finally { clearTimeout(t); }
}
const html = (body) => Buffer.byteLength(body, 'utf8') > MAX_BODY ? null : ({
  status: '200', statusDescription: 'OK',
  headers: {
    'content-type':  [{ key: 'Content-Type', value: 'text/html; charset=utf-8' }],
    'cache-control': [{ key: 'Cache-Control', value: 'public, max-age=300' }],
    'x-prerendered-by': [{ key: 'X-Prerendered-By', value: 'og-edge' }],
  }, body,
});

exports.handler = async (event) => {
  const req = event.Records[0].cf.request;
  const ua  = hdr(req, 'user-agent') ?? '';
  const kind = SOCIAL.test(ua) ? 'social' : CRAWLER.test(ua) ? 'crawler' : 'human';
  if (kind === 'human') return req;                        // 3) → S3 SPA (CSR), passthrough

  const t = route(req.uri); const host = hdr(req, 'host');
  if (!t || !host) return req;
  const api = `https://api.${host}`;                       // Host-derived base, no env vars

  if (kind === 'social') {                                 // 1) social scrapers → OG-only <head>
    const j = await fetchText(`${api}/og-meta/${t.type}/${t.slug}`);
    let meta; try { meta = JSON.parse(j); } catch { return req; }
    return html(buildOgHead(meta)) || req;
  }
  const page = await fetchText(`${api}/prerender/${t.type}/${t.slug}`); // 2) crawlers → full HTML
  return page ? (html(page) || req) : req;
};
```

**The two functionalities:**

| | Social (web scraping) | SEO (search crawlers) |
|---|---|---|
| UA | facebook/linkedin/whatsapp/x… | googlebot/bingbot/… |
| Calls | `GET /og-meta/{type}/{slug}` | `GET /prerender/{type}/{slug}` |
| Returns | `<head>` only: OG/Twitter tags | full HTML: head + **content body** + JSON-LD |
| Goal | rich share card | indexable page (no SSR) |

Both come from the API (DynamoDB) — see the Bot rendering section above. The React app and the human
path are unchanged (CSR). Not cloaking: crawler and user resolve to the same content.

**Where the code lives + deploy (IaC owns it — Pattern-B exception).** Unlike the BFF (whose pipeline
ships code while IaC owns config — Pattern B), the **edge code lives inside the IaC tree**
(`iac/lambda-src/og-edge/`) and Terraform owns its full lifecycle. *The placement rule generalises:*
code belongs to whichever pipeline can deploy it **atomically with the resource that must point at it**
— everywhere else that is the app pipeline, and here it is Terraform, for the reason below. *Why:*
CloudFront must reference a **specific published version** (a qualified ARN — `$LATEST` is rejected), so
every code change must publish a new version **and** repoint the distribution. Terraform does both in
one apply:
```hcl
module "fn_og_edge" {
  source    = "terraform-aws-modules/lambda/aws"
  version   = "~> 7.0"
  providers = { aws = aws.us_east_1 }            # Lambda@Edge MUST be us-east-1
  function_name  = "${var.project}-og-edge-${var.environment}"
  handler        = "index.handler"
  runtime        = "nodejs22.x"
  architectures  = ["x86_64"]                    # Lambda@Edge does NOT support arm64
  timeout = 5; memory_size = 128                 # viewer-request ceilings
  lambda_at_edge = true                          # dual-trust + publish a version (qualified ARN)
  create_package = true                          # IaC owns the code: source hash → new version
  source_path    = "${path.module}/lambda-src/og-edge"   # single zero-dep index.js, no build step
  # no VPC, no environment_variables
}
# qualified_arn flows straight into the CloudFront viewer-request association;
# code change → new hash → new version → new qualified_arn → distribution updated, all in one apply.
resource "aws_ssm_parameter" "lambda_edge_og_qualified_arn" { value = module.fn_og_edge.lambda_function_qualified_arn /* … */ }
```
*Trade-off:* an edge code change is a `terraform apply` (not the application deploy pipeline).
Acceptable — the edge is bot/SEO-only and changes rarely. The rejected alternative (an app-pipeline
`update-function-code` + `publish-version`, then a separate CloudFront `update-distribution`) would
fight the CloudFront module's state permanently, since Terraform reconciles the association back to the
version it knows. With `create_package=true` + `source_path` there's no esbuild — the zero-dep file is
zipped as-is.

After apply, CloudFront propagation + Lambda@Edge replication take several minutes; verify with `curl -A
Googlebot` once the distribution is `Deployed` (look for `x-prerendered-by: og-edge`).

### Decision & trade-off
- **Classify the viewer at the edge and do the MINIMUM for humans.** A viewer-request Lambda@Edge does a
  3-way User-Agent split: **humans pass straight through** to the SPA (CSR, untouched), **social
  scrapers** get a lightweight OG `<head>`, **search crawlers** get full prerendered HTML + JSON-LD.
  *Why at the edge:* serve bots server-rendered content **without paying for SSR on human traffic**.
  *Cost trade-off:* L@E runs on **every** viewer request and is pricier than regular Lambda, so the human
  path is a bare pass-through and real work happens only for bot UAs.
- **Not cloaking — bot and human resolve to the same content** (the edge fetches the same data the SPA
  renders, via the BFF bot API). *Trade-off:* a second render path that must stay in sync with the SPA.
- **The edge code is IaC-owned (the Pattern-B exception)** — CloudFront must reference a specific
  published version, so Terraform publishes the version AND repoints the distribution in one apply,
  rather than the application deploy pipeline. *Trade-off:* an edge change is a `terraform apply` with
  slow CloudFront/replication propagation — acceptable because it's bot/SEO-only and changes rarely.

### Pros & cons
**Pros:** SEO/social crawling without SSR; runs at the edge (fast); 3-way UA routing; human traffic
passes straight through to the SPA.
**Cons:** Lambda@Edge constraints (no VPC, us-east-1, slow deploys, size limits); UA classification is
heuristic.

