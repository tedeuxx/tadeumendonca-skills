Use Amazon Cognito in <project> infrastructure.

Context: $ARGUMENTS

Module: **`lgallard/cognito-user-pool/aws`** (auth.tf) — there is **no** official `terraform-aws-modules` Cognito module, so we use lgallard, the established community one (`/infrastructure/terraform` module policy). Cognito issues the JWT the API GW authorizer validates; the SPA holds it via the Cognito SDK (`/frontend/authentication`).

## Configuration — user pool + client + custom domain
```hcl
module "cognito" {
  source  = "lgallard/cognito-user-pool/aws"
  version = "~> 0.31"                          # community module — pin the current 0.x

  user_pool_name           = "<project>-${var.environment}"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  mfa_configuration        = "OPTIONAL"
  password_policy = { minimum_length = 12, require_uppercase = true, require_lowercase = true,
                      require_numbers = true, require_symbols = true }
  admin_create_user_config = { allow_admin_create_user_only = false }   # registered users self-signup

  user_groups = [{ name = "admin", precedence = 1 }, { name = "registered", precedence = 10 }]   # list; public = no group

  # single app client (the SPA) — the module's top-level client_* inputs
  client_name                                 = "spa"
  client_generate_secret                      = false   # PUBLIC client (PKCE, no secret)
  client_allowed_oauth_flows                  = ["code"] # Authorization Code + PKCE
  client_allowed_oauth_flows_user_pool_client = true
  client_allowed_oauth_scopes                 = ["openid", "email", "profile"]
  client_callback_urls                        = var.callback_urls   # https://{frontend-host}/callback
  client_logout_urls                          = var.logout_urls
  client_supported_identity_providers         = ["COGNITO"]
  client_explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"]

  # custom hosted-UI domain is the STANDARD — not the Cognito-generated prefix
  domain                 = var.auth_domain_name               # auth.{env}.<apex-domain>
  domain_certificate_arn = data.aws_acm_certificate.main.arn  # ISSUED cert in us-east-1 (/infrastructure/acm)
}
```
**Key knobs:** public client (`client_generate_secret=false`) → Authorization Code + **PKCE**, no secret anywhere; `mfa_configuration="OPTIONAL"`; 12-char password policy; self-signup. **The custom hosted-UI domain is the default** (`domain` = the FQDN + `domain_certificate_arn`, an ISSUED cert in **us-east-1**) — never the Cognito-generated `*.auth.<region>.amazoncognito.com` prefix.

## Auth is external to the BFF
The **SPA runs the Authorization Code + PKCE flow via the Cognito SDK** and holds/refreshes the JWT; it sends `Authorization: Bearer` to the API GW, whose **Cognito JWT authorizer** validates per route (`/infrastructure/api-gateway`). The **BFF has no auth code** — it only reads claims. No client secret exists (public client).

## Route53 alias + SSM (auth.tf)
```hcl
resource "aws_route53_record" "auth" {                       # /infrastructure/route53
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.auth_domain_name
  type    = "A"
  alias { name = module.cognito.domain_cloudfront_distribution_arn   # Cognito custom-domain CloudFront dist (lgallard output)
          zone_id = "Z2FDTNDATAQYW2", evaluate_target_health = false }
}
# SSM (/infrastructure/ssm): /{env}/auth/cognito-user-pool-id, cognito-client-id,
#   cognito-hosted-ui-url = https://{auth_domain_name}  (custom domain — the standard)
```

## Conventions
- **Three profiles:** public (no auth, no group) / registered (self-signup, auto-verified email) / admin (created manually, single). REGIONAL WAF fronts the open hosted-UI signup to mitigate abuse (`/infrastructure/waf`); public users need no auth for any GET.
- Pool/client ids → SSM for app repos (`/infrastructure/ssm`); the SPA reads them at build (`/frontend/environment-config`).
- New environment → its own pool + custom domain under the env subdomain; cert per env (`/infrastructure/acm`, `/infrastructure/route53`).

## Pros & cons
**Pros**
- Native API GW JWT authorizer + hosted UI, no extra vendor/cost.
- Public PKCE client — no secret to leak from the SPA.
- Self-signup lets registered users subscribe themselves.
**Cons**
- Less flexible UI/flows than Auth0; AWS lock-in.
- No confidential / `client_credentials` flow from the SPA.
- Open signup surface — needs the REGIONAL WAF + email verification.
