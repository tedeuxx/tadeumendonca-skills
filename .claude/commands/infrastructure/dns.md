Implement or review Route53 DNS records in tadeumendonca-iac.

Context: $ARGUMENTS

## Hosted zone — pre-existing, referenced by data source

The `tadeumendonca.io` hosted zone is created out-of-band (registrar + NS delegation) and referenced once at the root; this stack creates **records only, never the zone**:
```hcl
data "aws_route53_zone" "main" { name = "tadeumendonca.io" }
```

## A-alias records (one per public-facing service)

Each fronting service gets an **A-alias** in its layer's `.tf`, using `data.aws_route53_zone.main.zone_id`:

```hcl
# frontend.tf — SPA via CloudFront
resource "aws_route53_record" "frontend" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name                  # staging.tadeumendonca.io | tadeumendonca.io
  type    = "A"
  alias { name    = module.cloudfront.cloudfront_distribution_domain_name
          zone_id = "Z2FDTNDATAQYW2"         # CloudFront's constant hosted-zone id
          evaluate_target_health = false }
}

# api.tf — API GW v2 custom domain
resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.api_domain_name              # api.{env}.tadeumendonca.io
  type    = "A"
  alias { name    = module.apigw.domain_name_configuration[0].target_domain_name
          zone_id = module.apigw.domain_name_configuration[0].hosted_zone_id
          evaluate_target_health = false }
}

# auth.tf — Cognito hosted UI (Cognito provisions its own CloudFront)
resource "aws_route53_record" "auth" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.auth_domain_name
  type    = "A"
  alias { name    = module.cognito.user_pool_domain_cloudfront_distribution_arn
          zone_id = "Z2FDTNDATAQYW2"
          evaluate_target_health = false }
}
```

## Conventions
- `aws_route53_record` is justified raw glue (no module abstracts a single alias) — `/infrastructure/module-policy`.
- `Z2FDTNDATAQYW2` is the fixed CloudFront hosted-zone id (frontend SPA + Cognito hosted UI). API GW exposes its own `hosted_zone_id` via the module.
- SES verification + DKIM records are created by the SES module (`/infrastructure/ses-email`), not here.
- ACM DNS-validation records are out-of-band/one-time (`/infrastructure/terraform-repo-structure`).
