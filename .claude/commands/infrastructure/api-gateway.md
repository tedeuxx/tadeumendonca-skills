Use API Gateway v2 (HTTP API) in tadeumendonca infrastructure.

Context: $ARGUMENTS

Module: `terraform-aws-modules/apigateway-v2/aws ~> 6.0`.

## Standard config
```hcl
protocol_type = "HTTP"                                      # HTTP API ($default stage, auto-deploy)
domain_name                 = var.api_domain_name           # custom domain + mapping
domain_name_certificate_arn = data.aws_acm_certificate.main.arn
cors_configuration = {
  allow_origins = ["https://${var.domain_name}"], allow_methods = [...], allow_headers = [...], max_age = 300
}
create_routes_and_integrations = false                      # IaC seeds the shell; api repo owns the contract
body = templatefile("bootstrap/openapi-health.json.tftpl", { ... })   # seed GET /health
```

## Fronts only the BFF
The API covers a **single backend — the BFF** (`/backend/bff`): one `AWS_PROXY` integration to the BFF Lambda, routes at the **root**. A broad `/*/*` invoke permission means reimported routes need no new grant.

## Auth & integration
- **Cognito JWT authorizer** (`x-amazon-apigateway-authorizer`): issuer = pool URL, audience = client id (from SSM) — **applied per route**: public routes (health, public GETs, `/og-meta`, `/prerender`) are open; mutations require the JWT. The SPA sends `Authorization: Bearer` (Cognito SDK); the BFF has no auth code.
- **REGIONAL WAF** associated with the stage (`/infrastructure/waf`).

## Conventions
- IaC owns the shell; the **contract is generated from code** and reimported by the api repo (`/infrastructure/api-gw-contract`, `/backend/openapi`).
- Cert via `/infrastructure/acm`; custom-domain naming via `/infrastructure/environment-domains`; ids to SSM (`/infrastructure/ssm-config-bus`).
