Understand or implement the API GW contract ownership pattern for tadeumendonca.io.

Context: $ARGUMENTS

## IaC owns the shell; api repo owns the contract

**IaC (api.tf):** provisions API GW with a seed spec (`bootstrap/openapi-health.json.tftpl`) containing only `GET /health`. Sets `create_routes_and_integrations = false` — Terraform does NOT manage routes.

**api repo (contract as code):** owns the full route set + Cognito JWT authorizer. The OpenAPI is **generated from the Hono code** (`@hono/zod-openapi`) — see `/backend/openapi` — not hand-written. On every deploy the api repo generates the spec, overlays the AWS integration + authorizer, and runs `reimport-api`.

## Seed spec (IaC side)

```hcl
module "apigw" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 6.0"
  body                           = templatefile("${path.module}/bootstrap/openapi-health.json.tftpl", {
    health_integration_uri = module.fn["profile"].lambda_function_invoke_arn
  })
  create_routes_and_integrations = false
  ...
}
```

## Reimport (api repo side, deploy.yml)

```bash
API_ID=$(aws ssm get-parameter --name /$ENV_NAME/api/gateway-id --query 'Parameter.Value' --output text)
npx tsx scripts/gen-openapi.ts                       # generate openapi.gen.json from the Hono code
# overlay AWS integration + Cognito issuer/audience + Lambda invoke ARNs via envsubst
envsubst < openapi/openapi.aws.tftpl.json > openapi/openapi.resolved.json
aws apigatewayv2 reimport-api --api-id "$API_ID" --body file://openapi/openapi.resolved.json
```

## openapi.yaml placeholders (resolved at deploy)
- `${INVOKE_ARN_profile}`, `${INVOKE_ARN_posts}`, etc.
- `${COGNITO_ISSUER}` = `https://cognito-idp.{region}.amazonaws.com/{pool-id}`
- `${COGNITO_CLIENT_ID}` = Cognito app client ID

## Pipeline independence

If a future IaC apply resets the API GW body (seed spec replaces full contract), the api deploy pipeline is re-run manually. No cross-repo trigger. This is intentional.

## Rationale — no API versioning (Phase 1-3)
Single co-owned consumer (the fed). Versioning is operational overhead that only pays off with external consumers. Evolution path: add a `/v2/` route prefix + a new Lambda alias when needed.
