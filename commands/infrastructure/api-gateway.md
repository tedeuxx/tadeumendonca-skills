Use API Gateway (REST API, v1) in <project> infrastructure.

Context: $ARGUMENTS

**REST API (v1), REGIONAL endpoint** — the conventional, full-featured gateway: it supports **WAF**, usage plans + API keys, request/response validation, and resource policies (an HTTP API/v2 has none of these). The API **fronts only the BFF** (`/backend/bff`): one `AWS_PROXY` (Lambda proxy) integration, routes at the **root** (the API *is* the BFF). No official `terraform-aws-modules` REST module fits the OpenAPI-body + Pattern-B reimport flow cleanly, so we use **raw `aws_api_gateway_*`** resources (justified glue — `/infrastructure/terraform`).

## Configuration (api.tf)
```hcl
# REST API — body is the OpenAPI spec; IaC seeds GET /health, the api repo owns the full contract.
resource "aws_api_gateway_rest_api" "this" {
  name = "<project>-${var.environment}"
  endpoint_configuration { types = ["REGIONAL"] }     # REGIONAL (not EDGE) — WAF + regional cert
  body = templatefile("${path.module}/bootstrap/openapi-health.json.tftpl", {
    health_integration_uri = module.bff.lambda_function_invoke_arn   # seed GET /health → BFF
  })
  lifecycle { ignore_changes = [body] }               # the api repo owns the body after first apply (put-rest-api)
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  triggers    = { redeploy = sha1(aws_api_gateway_rest_api.this.body) }   # redeploy when the seed body changes
  lifecycle { create_before_destroy = true }
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id           = aws_api_gateway_rest_api.this.id
  deployment_id         = aws_api_gateway_deployment.this.id
  stage_name            = "live"
  xray_tracing_enabled  = true
  # access logs → /infrastructure/cloudwatch
}

# stage throttling + per-method metrics (the conventional rate guard; usage plans/keys are also available)
resource "aws_api_gateway_method_settings" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"
  settings { throttling_rate_limit = 1000, throttling_burst_limit = 2000, metrics_enabled = true }
}

# custom domain (REGIONAL) — the generated execute-api endpoint is never the public URL
resource "aws_api_gateway_domain_name" "this" {
  domain_name              = var.api_domain_name                  # api.{env}.<apex-domain>
  regional_certificate_arn = data.aws_acm_certificate.main.arn    # us-east-1 regional cert (/infrastructure/acm)
  endpoint_configuration { types = ["REGIONAL"] }
  security_policy = "TLS_1_2"
}
resource "aws_api_gateway_base_path_mapping" "this" {
  api_id      = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  domain_name = aws_api_gateway_domain_name.this.domain_name
}

# broad invoke permission so reimported routes need no new grant
resource "aws_lambda_permission" "apigw_bff" {
  action = "lambda:InvokeFunction"; function_name = module.bff.lambda_function_name
  principal = "apigateway.amazonaws.com"; source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

# REGIONAL WAF → the stage (REST stages ARE WAF-associable, unlike HTTP APIs) — /infrastructure/waf
resource "aws_wafv2_web_acl_association" "api_gw" {
  resource_arn = aws_api_gateway_stage.this.arn
  web_acl_arn  = module.waf_regional.arn
}
```
**Key knobs:** `endpoint_configuration = REGIONAL` (EDGE would force the cert to us-east-1 *edge* + its own CloudFront — REGIONAL keeps it simple and WAF-associable with a regional WebACL); `lifecycle.ignore_changes = [body]` so an IaC apply never fights the api repo's `put-rest-api`; deployment redeploys on seed-body change; custom domain on the reused us-east-1 **regional** cert; `aws_api_gateway_method_settings` for stage throttling.

## Auth — Cognito authorizer (`COGNITO_USER_POOLS`), per route
The OpenAPI body carries an `x-amazon-apigateway-authorizer` of type `cognito_user_pools` (provider ARN = the user pool) + per-route `security`. Public routes (health, public GETs, `/og-meta`, `/prerender`) open; mutations require the JWT. The SPA sends `Authorization: Bearer` (Cognito SDK); the BFF has **no auth code** — it reads `requestContext.authorizer.claims` (`/frontend/authentication`, `/backend/bff`).

## CORS — owned by the API Gateway, defined in the OpenAPI body
A REST API has **no `cors_configuration`** knob (that's an HTTP-API feature); CORS is the **gateway's** job here, expressed **in the OpenAPI body** so it is reproducible and survives every `put-rest-api --mode overwrite`:
- An **`OPTIONS`** method per resource with a **MOCK** integration returns the preflight headers (`Access-Control-Allow-Origin` = the exact SPA host per env — never `*`, since we send `Authorization`; `-Allow-Methods`, `-Allow-Headers: authorization,content-type`; `Max-Age: 300`). The other methods proxy to the BFF.
- **Gateway responses** (`DEFAULT_4XX`/`DEFAULT_5XX`) add `Access-Control-Allow-Origin` so error responses are also CORS-valid.
- **`@hono/zod-openapi` generates this into the spec** (`/backend/openapi`); the iac seed body includes it for `GET /health`. **The BFF does NOT set CORS** (one owner), and CORS is **never** configured by hand in the console — `put-rest-api` would wipe a manual config on the next deploy.

## Rate limiting — stage throttling + usage plans (REST has both)
- **Stage throttling** (`aws_api_gateway_method_settings`, `*/*`): a token bucket — `throttling_rate_limit` (steady req/s) + `throttling_burst_limit` (spike depth); over-limit → **429**. Per-method overrides via a specific `method_path`. Aggregate per stage, not per-client.
- **Usage plans + API keys** (`aws_api_gateway_usage_plan` + `_api_key` + `_usage_plan_key`): per-key quotas + throttles — REST-only. Not needed while the only consumer is the co-owned fed SPA (it authenticates with Cognito JWT, not API keys), but available if an external/partner consumer appears.
- **WAF** rate-based rules (per-IP) front the stage via the REGIONAL WebACL (`/infrastructure/waf`) — the per-IP guard the HTTP API couldn't have.

## Contract ownership — IaC owns the shell, api repo owns the contract
- **IaC (api.tf):** seed spec `bootstrap/openapi-health.json.tftpl` with only `GET /health`; `lifecycle.ignore_changes=[body]`.
- **api repo:** owns the full root route set + authorizer. The OpenAPI is **generated from the Hono code** (`@hono/zod-openapi`, `/backend/openapi`) — not hand-written. On every deploy it generates the spec, overlays the **single AWS integration (the BFF Lambda)** + the Cognito authorizer, then **overwrites + redeploys**:
```bash
API_ID=$(aws ssm get-parameter --name /$ENV_NAME/api/gateway-id --query 'Parameter.Value' --output text)
npx tsx scripts/gen-openapi.ts --version "$(cat VERSION)" --out openapi.json   # version-stamped root copy
envsubst < openapi/openapi.aws.tftpl.json > openapi/openapi.resolved.json      # overlay integration + issuer/audience
aws apigateway put-rest-api --rest-api-id "$API_ID" --mode overwrite --body fileb://openapi/openapi.resolved.json
aws apigateway create-deployment --rest-api-id "$API_ID" --stage-name live      # publish the new spec
```
Placeholders resolved at deploy: `${INVOKE_ARN_bff}` (every route → the one BFF Lambda), `${COGNITO_POOL_ARN}` = the user-pool ARN, `${COGNITO_CLIENT_ID}` (audience).

**Pipeline independence:** if a future IaC apply resets the body to the seed, the api deploy is re-run manually — no cross-repo trigger (intentional).

**No API versioning (Phase 1-3):** single co-owned consumer (the fed); versioning is overhead that only pays off with external consumers. Evolution: add a `/v2/` base path + a new Lambda alias when needed.

## Conventions
- Cert via `/infrastructure/acm` (regional cert in us-east-1); custom-domain naming via `/infrastructure/route53` (alias → `aws_api_gateway_domain_name.regional_domain_name` / `regional_zone_id`); ids to SSM (`gateway-id` = REST API id, `gateway-url`) via `/infrastructure/ssm`. Contract generation: `/backend/openapi`.
- Raw `aws_api_gateway_*` is justified glue (no official module fits the OpenAPI-body + reimport flow) — `/infrastructure/terraform`.
## Pros & cons
**Pros**
- REST API is **WAF-associable** (per-IP managed rules + rate limiting) and supports usage plans / API keys / request validation — the conventional, full-featured choice.
- Per-route Cognito authorizer keeps auth out of the BFF code; contract generated from code (no hand-written drift).
**Cons**
- ~3.5× the per-request cost of an HTTP API and a bit more latency; more moving resources (raw `aws_api_gateway_*`).
- All routing lives inside the BFF; the put-rest-api + create-deployment step couples deploy to the generated spec.
