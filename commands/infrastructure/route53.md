Use Amazon Route53 in <project> infrastructure (DNS records + the per-env domain model).

Context: $ARGUMENTS

## Domain model — one apex per product, environment-scoped subdomains
The **environment is encoded in the host**. Production uses the bare apex (+ `api.`/`auth.`); non-prod nests the service under an environment label. The **subdomain is the environment boundary** — never an env query param/header.

| Service | Production | Staging |
|---|---|---|
| Frontend (SPA) | `<apex-domain>` | `staging.<apex-domain>` |
| API | `api.<apex-domain>` | `api.staging.<apex-domain>` |
| Auth (Cognito hosted UI) | `auth.<apex-domain>` | `auth.staging.<apex-domain>` |

General form: production `{service?}.{apex}`, non-prod `{service?}.{environment}.{apex}` (the frontend has no service prefix). Per-env tfvars:
```hcl
# env/prd.tfvars                              # env/stg.tfvars
domain_name      = "<apex-domain>"              # "staging.<apex-domain>"
api_domain_name  = "api.<apex-domain>"          # "api.staging.<apex-domain>"
auth_domain_name = "auth.<apex-domain>"         # "auth.staging.<apex-domain>"
```
These feed CloudFront aliases, the API GW custom domain, the Cognito custom domain, and the Route53 records below. Callback/logout URLs follow the frontend host (`https://{frontend-host}/callback`). Cert coverage per env → `/infrastructure/acm`. **Reusable across future products** — swap the apex, keep the structure.

## Hosted zone — pre-existing, referenced by data source
The `<apex-domain>` hosted zone is created out-of-band (registrar + NS delegation) and referenced once at the root; this stack creates **records only, never the zone**:
```hcl
data "aws_route53_zone" "main" { name = "<apex-domain>" }
```

## A-alias records (one per public-facing service)
Each fronting service gets an **A-alias** in its layer's `.tf`, using `data.aws_route53_zone.main.zone_id`:
```hcl
# frontend.tf — SPA via CloudFront
resource "aws_route53_record" "frontend" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name                  # staging.<apex-domain> | <apex-domain>
  type    = "A"
  alias { name = module.cloudfront.cloudfront_distribution_domain_name
          zone_id = "Z2FDTNDATAQYW2"          # CloudFront's constant hosted-zone id
          evaluate_target_health = false }
}

# api.tf — API GW (REST, REGIONAL) custom domain
resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.api_domain_name              # api.{env}.<apex-domain>
  type    = "A"
  alias { name = aws_api_gateway_domain_name.this.regional_domain_name
          zone_id = aws_api_gateway_domain_name.this.regional_zone_id
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

## Pros & cons
**Pros**
- A-alias is free, resolves at the apex (a CNAME can't), and is health-aware.
- Pre-existing hosted zone means a stack rebuild never destroys DNS / mail delegation.
**Cons**
- Alias targets must be AWS resources.
- The zone lifecycle is out-of-band, not captured in this stack.
