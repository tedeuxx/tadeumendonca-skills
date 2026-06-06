Use Amazon Cognito in ${var.project} infrastructure.

Context: $ARGUMENTS

Module: `terraform-aws-modules/cognito-idp/aws ~> 8.0` (auth.tf). Cognito issues the JWT the API GW authorizer validates; the SPA holds it via the Cognito SDK (`/frontend/authentication`).

## Configuration — user pool + client + custom domain
```hcl
module "cognito" {
  source  = "terraform-aws-modules/cognito-idp/aws"
  version = "~> 8.0"

  user_pool_name           = "${var.project}-${var.environment}"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  mfa_configuration        = "OPTIONAL"
  password_policy = { minimum_length = 12, require_uppercase = true, require_lowercase = true,
                      require_numbers = true, require_symbols = true }
  admin_create_user_config = { allow_admin_create_user_only = false }   # registered users self-signup

  groups = { admin = { precedence = 1 }, registered = { precedence = 10 } }   # public = no group

  clients = {
    spa = {
      generate_secret              = false                  # PUBLIC client (PKCE, no secret)
      allowed_oauth_flows          = ["code"]               # Authorization Code + PKCE
      allowed_oauth_flows_user_pool_client = true
      allowed_oauth_scopes         = ["openid","email","profile"]
      callback_urls                = var.callback_urls      # https://{frontend-host}/callback
      logout_urls                  = var.logout_urls
      supported_identity_providers = ["COGNITO"]
      explicit_auth_flows          = ["ALLOW_REFRESH_TOKEN_AUTH","ALLOW_USER_SRP_AUTH"]
    }
  }

  domain          = "auth-${var.environment}-${var.project}"   # Cognito-managed prefix (fallback)
  custom_domain   = var.auth_domain_name                      # auth.{env}.${var.apex_domain}
  certificate_arn = data.aws_acm_certificate.main.arn         # us-east-1, pre-created (/infrastructure/acm)
}
```
**Key knobs:** app client is **public** (`generate_secret=false`) → Authorization Code + **PKCE**, no client secret anywhere; `mfa_configuration="OPTIONAL"`; 12-char password policy; `allow_admin_create_user_only=false` (self-signup). Custom domain needs the cert in **us-east-1** (same as CloudFront).

## Auth is external to the BFF
The **SPA runs the Authorization Code + PKCE flow via the Cognito SDK** and holds/refreshes the JWT; it sends `Authorization: Bearer` to the API GW, whose **Cognito JWT authorizer** validates per route (`/infrastructure/api-gateway`). The **BFF has no auth code** — it only reads claims. No client secret exists (public client).

## Route53 alias + SSM (auth.tf)
```hcl
resource "aws_route53_record" "auth" {                       # /infrastructure/route53
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.auth_domain_name
  type    = "A"
  alias { name = module.cognito.user_pool_domain_cloudfront_distribution_arn
          zone_id = "Z2FDTNDATAQYW2", evaluate_target_health = false }
}
# SSM (/infrastructure/ssm): /{env}/auth/cognito-user-pool-id, cognito-client-id,
#   cognito-domain (managed prefix), cognito-hosted-ui-url = https://{auth_domain_name}
```

## Conventions
- **Three profiles:** public (no auth, no group) / registered (self-signup, auto-verified email) / admin (created manually, single). REGIONAL WAF fronts the open hosted-UI signup to mitigate abuse (`/infrastructure/waf`); public users need no auth for any GET.
- Pool/client ids → SSM for app repos (`/infrastructure/ssm`); the SPA reads them at build (`/frontend/environment-config`).
- New environment → its own pool + custom domain under the env subdomain; cert per env (`/infrastructure/acm`, `/infrastructure/route53`).
