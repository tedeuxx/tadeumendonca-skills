Use Amazon Route53 in ${var.project} infrastructure (DNS records + the per-env domain model).

Context: $ARGUMENTS

## Domain model — one apex per product, environment-scoped subdomains
The **environment is encoded in the host**. Production uses the bare apex (+ `api.`/`auth.`); non-prod nests the service under an environment label. The **subdomain is the environment boundary** — never an env query param/header.

| Service | Production | Staging |
|---|---|---|
| Frontend (SPA) | `${var.apex_domain}` | `staging.${var.apex_domain}` |
| API | `api.${var.apex_domain}` | `api.staging.${var.apex_domain}` |
| Auth (Cognito hosted UI) | `auth.${var.apex_domain}` | `auth.staging.${var.apex_domain}` |

General form: production `{service?}.{apex}`, non-prod `{service?}.{environment}.{apex}` (the frontend has no service prefix). Per-env tfvars:
```hcl
# env/prd.tfvars                              # env/stg.tfvars
domain_name      = "${var.apex_domain}"              # "staging.${var.apex_domain}"
api_domain_name  = "api.${var.apex_domain}"          # "api.staging.${var.apex_domain}"
auth_domain_name = "auth.${var.apex_domain}"         # "auth.staging.${var.apex_domain}"
```
These feed CloudFront aliases, the API GW custom domain, the Cognito custom domain, and the Route53 records below. Callback/logout URLs follow the frontend host (`https://{frontend-host}/callback`). Cert coverage per env → `/infrastructure/acm`. **Reusable across future products** — swap the apex, keep the structure.

## Hosted zone — pre-existing, referenced by data source
The `${var.apex_domain}` hosted zone is created out-of-band (registrar + NS delegation) and referenced once at the root; this stack creates **records only, never the zone**:
```hcl
data "aws_route53_zone" "main" { name = "${var.apex_domain}" }
```

## A-alias records (one per public-facing service)
Each fronting service gets an **A-alias** in its layer's `.tf`, using `data.aws_route53_zone.main.zone_id`:
```hcl
# frontend.tf — SPA via CloudFront
resource "aws_route53_record" "frontend" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name                  # staging.${var.apex_domain} | ${var.apex_domain}
  type    = "A"
  alias { name = module.cloudfront.cloudfront_distribution_domain_name
          zone_id = "Z2FDTNDATAQYW2"          # CloudFront's constant hosted-zone id
          evaluate_target_health = false }
}

# api.tf — API GW v2 custom domain
resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.api_domain_name              # api.{env}.${var.apex_domain}
  type    = "A"
  alias { name = module.apigw.domain_name_configuration[0].target_domain_name
          zone_id = module.apigw.domain_name_configuration[0].hosted_zone_id
          evaluate_target_health = false }
}

# auth.tf — Cognito hosted UI (Cognito provisions its own CloudFront)
resource "aws_route53_record" "auth" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.auth_domain_name
  type    = "A"
  alias { name = module.cognito.user_pool_domain_cloudfront_distribution_arn
          zone_id = "Z2FDTNDATAQYW2"
          evaluate_target_health = false }
}
```

## Conventions
- `aws_route53_record` is justified raw glue (no module abstracts a single alias) — `/infrastructure/terraform`.
- `Z2FDTNDATAQYW2` is the fixed CloudFront hosted-zone id (frontend SPA + Cognito hosted UI). API GW exposes its own `hosted_zone_id` via the module.
- New service → add `{service}.{...}` following the table and include the host in the env's ACM cert (`/infrastructure/acm`).
- SES verification + DKIM records are created by the SES module (`/infrastructure/ses`), not here. ACM DNS-validation records are out-of-band/one-time.
