Configure Cognito custom domain for tadeumendonca.io.

Environment: $ARGUMENTS (staging | production)

## Module configuration (auth.tf)

```hcl
module "cognito" {
  source  = "terraform-aws-modules/cognito-idp/aws"
  version = "~> 8.0"
  ...
  domain          = "auth-${var.environment}-tadeumendonca"   # fallback Cognito-managed prefix
  custom_domain   = var.auth_domain_name                      # auth.staging.tadeumendonca.io
  certificate_arn = data.aws_acm_certificate.main.arn         # us-east-1, pre-created out-of-band
}
```

## Route53 alias (auth.tf)

```hcl
resource "aws_route53_record" "auth" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.auth_domain_name
  type    = "A"
  alias {
    name                   = module.cognito.user_pool_domain_cloudfront_distribution_arn
    zone_id                = "Z2FDTNDATAQYW2"   # CloudFront hosted zone (constant)
    evaluate_target_health = false
  }
}
```

## SSM outputs

```hcl
resource "aws_ssm_parameter" "cognito_domain" {
  name  = "/${var.environment}/auth/cognito-domain"
  value = module.cognito.domain   # Cognito-managed prefix (fallback)
}
resource "aws_ssm_parameter" "cognito_hosted_ui_url" {
  name  = "/${var.environment}/auth/cognito-hosted-ui-url"
  value = "https://${var.auth_domain_name}"   # FQDN for the custom domain
}
```

## ACM requirement

Cognito custom domain requires a certificate in **us-east-1** (same region as CloudFront). Use `data.aws_acm_certificate.main.arn` — pre-created, domain `tadeumendonca.io`, covers all subdomains.

## Rationale — three user profiles
public / registered (self-signup) / admin. `allow_admin_create_user_only = false` lets registered users self-signup via the hosted UI (auto-verified email) to receive notifications; the single `admin` is created manually. REGIONAL WAF fronts the hosted UI to mitigate abuse on the open signup. Public users need no auth for any GET.
