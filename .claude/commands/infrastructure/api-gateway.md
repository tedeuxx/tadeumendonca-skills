Use API Gateway v2 (HTTP API) in <project> infrastructure.

Context: $ARGUMENTS

Module: `terraform-aws-modules/apigateway-v2/aws ~> 6.0`. The API **fronts only the BFF** (`/backend/bff`): one `AWS_PROXY` integration, routes at the **root** (the API *is* the BFF).

## Configuration (api.tf)
```hcl
module "apigw" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 6.0"

  protocol_type = "HTTP"                                       # HTTP API ($default stage, auto-deploy)

  domain_name                 = var.api_domain_name            # custom domain + mapping
  domain_name_certificate_arn = data.aws_acm_certificate.main.arn  # us-east-1 (/infrastructure/acm)

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
**Key knobs:** `protocol_type="HTTP"` (HTTP API, cheaper/faster than REST; no API key/usage plans needed), `$default` auto-deploy stage, `create_routes_and_integrations=false` (Terraform does **not** manage routes), single integration → BFF, CORS locked to the SPA host. **REGIONAL WAF** associated with the stage (`/infrastructure/waf`).

## Auth — Cognito JWT authorizer, per route
`x-amazon-apigateway-authorizer`: issuer = pool URL, audience = client id (from SSM). Applied **per route**: public routes (health, public GETs, `/og-meta`, `/prerender`) open; mutations require the JWT. The SPA sends `Authorization: Bearer` (Cognito SDK); the BFF has **no auth code** — it reads `requestContext.authorizer.jwt.claims` (`/frontend/authentication`, `/backend/bff`).

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
- HTTP API lacks REST features (request validation, usage plans, API keys).
- All routing lives inside the BFF; the reimport step couples deploy to the generated spec.
