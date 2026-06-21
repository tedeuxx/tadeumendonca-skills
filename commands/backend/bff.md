Implement or review the Backend-for-Frontend (BFF) pattern.

Context: $ARGUMENTS

## What a BFF is
A **BFF is the single backend that exists to serve one frontend.** API Gateway fronts **only the BFF** — there is no other public backend for this SPA — so the BFF's **routes live at the root** (`/profile`, `/posts`, …); the whole API *is* the BFF. **One BFF per SPA** (1:1, never shared — `/architecture/fed-spa-bff`). Its job: expose endpoints **shaped for this frontend's screens** and **orchestrate/aggregate** the domain logic / downstream microservices behind it — one round trip per screen instead of the SPA fanning out to many resource APIs.

## Auth/authz are EXTERNAL to the BFF (kept simple)
The BFF contains **no authentication or authorization code**. Auth is handled outside it:
- **Frontend:** the **Cognito SDK** (AWS Amplify Auth / `amazon-cognito-identity-js`) runs login and **holds + refreshes the JWT**; the SPA sends `Authorization: Bearer <access_token>`.
- **API Gateway:** a **Cognito JWT authorizer** validates the token on every request before it reaches the BFF (`/infrastructure/api-gateway`).
- The BFF just **reads the validated claims** from the authorizer context (`requestContext.authorizer.jwt.claims` — `sub`, `email`, `cognito:groups`) and uses them for shaping/RBAC. No token exchange, no session store, no PKCE in the BFF.

> This deliberately trades the "no-tokens-in-browser" BFF-session variant for **much simpler code**: the Cognito SDK + GW authorizer own auth; the BFF stays pure orchestration.

## Topology
```
SPA ─(Cognito SDK: login + holds JWT)─► Cognito
SPA ─Bearer JWT─► API Gateway (Cognito JWT authorizer) ─► BFF Lambda (Hono, non-VPC, root routes)
                                                            ├ reads claims (no auth code)
                                                            └ domain logic / microservices ─► DynamoDB · Redis (cache) · S3
```

## How it works (request lifecycle)
1. SPA authenticates with Cognito via the SDK → gets a JWT (the SDK refreshes it).
2. SPA calls the BFF (`/posts`) with `Authorization: Bearer <jwt>`.
3. **API GW authorizer** validates the JWT (issuer = pool URL, audience = client id) → injects claims.
4. BFF handler reads claims (RBAC/shaping — `/backend/action-types`), calls the domain logic / microservices, **aggregates** into a screen-shaped payload, returns it.
5. Cross-cutting (audit/log/metrics) via the standard Hono middleware.

## Shaping & aggregation (the BFF's core job)
Endpoints are **per screen, not per resource** — the BFF composes one response from what a view needs, so the SPA makes **one call per screen** and stays decoupled from the data model.
- **Aggregate** from several modules/sources (later: microservices) into one payload — e.g. a feed item = post + author summary + counts.
- **Shape/trim** to only the fields the screen renders (projections), snake_case; never leak internal/document structure.
- **One round trip** — prefer a single composed endpoint over the SPA fanning out N calls.
Keep aggregation/shaping here; keep **domain rules** in the modules/services.

## Communicating with microservices (now → future)
Today the domain logic can live **inside** the BFF (modular monolith — fastest to ship). As it grows, split into **microservices the BFF calls**, keeping the SPA contract stable:
- **Sync:** direct **Lambda invoke** (`InvokeCommand`) or a **private/internal API GW** (VPC link). Propagate the user claims explicitly; internal services trust the BFF (network + IAM), they don't re-validate the JWT.
- **Async:** **SNS** pub/sub for fire-and-forget (e.g. notifications) — the BFF publishes a domain event, a subscribed Lambda consumes (+ DLQ). See `/infrastructure/sns`, `/backend/notifications`.
- The **BFF owns the public contract** (its OpenAPI at root — `/backend/openapi`); microservices keep internal contracts. Changing a microservice never changes the SPA while the BFF endpoint is stable.

## Why use a BFF
- **Frontend-shaped API** — endpoints tailored to screens; one call per view, not many resource calls.
- **Decouples the SPA from backend topology** — monolith today, microservices tomorrow, no SPA change.
- **Aggregation/composition server-side** — lower latency, less chatter, no business logic leaking into the SPA.
- **Simple auth** — delegated to the Cognito SDK + GW authorizer; the BFF code stays focused on orchestration.

## Pros / cons
**Pros:** tailored payloads + fewer round trips; backend evolves freely; clear 1:1 ownership; auth kept out of app code; one narrow public surface.
**Cons:** an extra hop/Lambda to operate; risk of a "god BFF" if business rules creep in (keep it orchestration + shaping; push domain rules into the services); per-SPA duplication with many frontends; tokens live in the browser (the Cognito SDK manages them — accepted trade for simpler code vs. a server-side session BFF).

## Conventions
- Built on Hono (`/backend/framework-hono`), non-VPC by default, Pattern B; **routes at root**; OpenAPI generated from them (`/backend/openapi`) = the contract API GW imports (`/infrastructure/api-gateway`).
- **No auth code in the BFF** — claims come from the API GW Cognito authorizer (`/infrastructure/api-gateway`, `/infrastructure/cognito`); the SPA holds the JWT via the Cognito SDK (`/frontend/authentication`).
- One BFF per SPA. Keep it thin: read claims → orchestrate → shape. Domain rules belong in the domain logic/microservices.

## Pros & cons
**Pros**
- One contract tailored to the SPA; auth is external so the BFF has no auth code.
- Modular monolith = one deploy, simple ops; split to microservices later.
**Cons**
- A single Lambda is a shared fault domain for all routes.
- A BFF tailored to one consumer does not suit many external clients.
