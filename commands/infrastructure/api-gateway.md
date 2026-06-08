Use API Gateway v2 (HTTP API) in <project> infrastructure.

Context: $ARGUMENTS

Module: `terraform-aws-modules/apigateway-v2/aws ~> 5.0` (the 6.x line requires the **aws v6 provider**, which conflicts with the project-wide `aws ~> 5.0` pin — `/infrastructure/terraform`; 5.x is the aws-5-compatible line). The API **fronts only the BFF** (`/backend/bff`): one `AWS_PROXY` integration, routes at the **root** (the API *is* the BFF).

## Configuration (api.tf)
```hcl
module "apigw" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 6.0"

  protocol_type = "HTTP"                                       # HTTP API ($default stage, auto-deploy)

  # custom domain is the STANDARD — the generated execute-api endpoint is never the public URL
  domain_name                 = var.api_domain_name            # api.{env}.<apex-domain> (/infrastructure/route53)
  domain_name_certificate_arn = data.aws_acm_certificate.main.arn  # us-east-1 (/infrastructure/acm)
  create_certificate          = false                          # reuse the existing cert; do NOT let the module issue one

  cors_configuration = {
    allow_origins = ["https://${var.domain_name}"]             # the SPA host only
    allow_methods = ["GET","POST","PUT","DELETE","OPTIONS"]
    allow_headers = ["authorization","content-type"]
    max_age       = 300
  }

  # IaC seeds the shell; the api repo owns the full contract
  create_routes_and_integrations = false
  body = templatefile("${path.module}/bootstrap/openapi-health.json.tftpl", {
    health_integration_uri = module.bff.lambda_function_invoke_arn          # seed GET /health
  })
}
# broad invoke permission so reimported routes need no new grant
resource "aws_lambda_permission" "apigw_bff" {
  action = "lambda:InvokeFunction"; function_name = module.bff.lambda_function_name
  principal = "apigateway.amazonaws.com"; source_arn = "${module.apigw.api_execution_arn}/*/*"
}
```
**Key knobs:** `protocol_type="HTTP"` (HTTP API, cheaper/faster than REST; no API key/usage plans needed), `$default` auto-deploy stage, `create_routes_and_integrations=false` (Terraform does **not** manage routes), single integration → BFF, CORS locked to the SPA host. **Stage throttling** (`stage_default_route_settings` — e.g. 1000 rate / 2000 burst) is the rate guard.

> **No WAF on an HTTP API.** WAFv2 can't associate with API Gateway **v2 (HTTP APIs)** — only REST (v1) / ALB / CloudFront / Cognito. So the API is **not** WAF-fronted: it relies on **stage throttling** + the per-route **Cognito JWT authorizer** (below). The REGIONAL WAF covers the Cognito hosted UI only (`/infrastructure/waf`). If true WAF on the API is ever required, switch to a REST API or front the HTTP API with CloudFront.

Also set `create_domain_records = false` on the module — it derives its own hosted zone from `domain_name` and mis-looks-it-up for a multi-level host; the A-alias is created explicitly in `/infrastructure/route53`.

## Auth — Cognito JWT authorizer, per route
`x-amazon-apigateway-authorizer`: issuer = pool URL, audience = client id (from SSM). Applied **per route**: public routes (health, public GETs, `/og-meta`, `/prerender`) open; mutations require the JWT. The SPA sends `Authorization: Bearer` (Cognito SDK); the BFF has **no auth code** — it reads `requestContext.authorizer.jwt.claims` (`/frontend/authentication`, `/backend/bff`).

## Rate limiting — stage throttling (the HTTP API's only native rate guard)
HTTP APIs have **no usage plans / API keys** (a REST-only feature) and **can't be WAF-fronted** — so throttling is the one native control. It's a **token bucket** on the `$default` stage, set via the module's `stage_default_route_settings`:
```hcl
stage_default_route_settings = {
  throttling_rate_limit  = 1000   # steady-state requests/second (bucket refill rate)
  throttling_burst_limit = 2000   # max burst (bucket depth) — short spikes above the rate
  detailed_metrics_enabled = true # per-route CloudWatch metrics (tune limits from real traffic)
}
```
- **Scope = per stage, account-wide aggregate — NOT per client/IP.** All callers share one bucket; over-limit requests get **HTTP 429**. A single abusive client can consume the budget, so this is overload protection, not per-IP abuse protection.
- **`rate` vs `burst`:** `rate` is sustained throughput; `burst` absorbs short spikes (a page load firing several calls). Set `burst ≥ rate`; size both to expected peak concurrency, not averages. AWS account default is 10000 rate / 5000 burst — we set lower (e.g. 1000/2000) as a deliberate cost/abuse ceiling for a low-traffic site.
- **Per-route overrides** are possible (`route_settings` per `METHOD /path`) — e.g. tighter limits on mutations, looser on `GET /health`. Default-stage settings suffice until a hot route needs its own.
- **For real per-IP / per-client limiting** you need REST + usage plans, or **CloudFront + WAF rate-based rules** in front of the API (`/infrastructure/waf`) — not in scope for Phase 1-3.

## Contract ownership — IaC owns the shell, api repo owns the contract
- **IaC (api.tf):** seed spec `bootstrap/openapi-health.json.tftpl` with only `GET /health`; `create_routes_and_integrations = false`.
- **api repo:** owns the full root route set + authorizer. The OpenAPI is **generated from the Hono code** (`@hono/zod-openapi`, `/backend/openapi`) — not hand-written. On every deploy it generates the spec, overlays the **single AWS integration (the BFF Lambda)** + authorizer, and runs `reimport-api`:
```bash
API_ID=$(aws ssm get-parameter --name /$ENV_NAME/api/gateway-id --query 'Parameter.Value' --output text)
npx tsx scripts/gen-openapi.ts --version "$(cat VERSION)" --out openapi.json   # version-stamped root copy
envsubst < openapi/openapi.aws.tftpl.json > openapi/openapi.resolved.json      # overlay integration + issuer/audience
aws apigatewayv2 reimport-api --api-id "$API_ID" --body file://openapi/openapi.resolved.json
```
Placeholders resolved at deploy: `${INVOKE_ARN_bff}` (every route → the one BFF Lambda), `${COGNITO_ISSUER}` = `https://cognito-idp.{region}.amazonaws.com/{pool-id}`, `${COGNITO_CLIENT_ID}`.

**Pipeline independence:** if a future IaC apply resets the body to the seed, the api deploy is re-run manually — no cross-repo trigger (intentional).

**No API versioning (Phase 1-3):** single co-owned consumer (the fed); versioning is overhead that only pays off with external consumers. Evolution: add a `/v2/` prefix + a new Lambda alias when needed.

## Conventions
- Cert via `/infrastructure/acm`; custom-domain naming via `/infrastructure/route53`; ids to SSM (`gateway-id`, `gateway-url`) via `/infrastructure/ssm`. Contract generation: `/backend/openapi`.
## Pros & cons
**Pros**
- HTTP API is cheaper/faster than REST; fronts only the BFF (one integration).
- Per-route Cognito JWT authorizer keeps auth out of the BFF code.
- Contract generated from code — no hand-written drift.
**Cons**
- HTTP API lacks REST features (request validation, usage plans, API keys) and **can't be WAF-fronted** — rate control is **per-stage throttling only** (aggregate, not per-IP).
- All routing lives inside the BFF; the reimport step couples deploy to the generated spec.
