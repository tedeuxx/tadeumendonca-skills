Use Amazon Cognito in <project> infrastructure.

Context: $ARGUMENTS

Module: **`lgallard/cognito-user-pool/aws`** (auth.tf) — there is **no** official `terraform-aws-modules` Cognito module, so we use lgallard, the established community one (`/infrastructure/terraform` module policy). Cognito issues the JWT the API GW authorizer validates; the SPA holds it via the Cognito SDK / Amplify (`/frontend/authentication`).

## Identity model — social-only (Google), two profiles
- **Sign-in is social-only via Google** — no native username/password. Native self-signup is **disabled**; users are auto-provisioned on first Google login (federation). *Trade-off:* lower friction + no password to store/leak, but a hard dependency on Google and **no email/password fallback**. (Other IdPs are drop-in — see "Adding providers".)
- **Two authenticated profiles (groups):** `admin` + `registered`. **Public = unauthenticated** (no group — every public GET needs no auth). Group assignment is automatic via a Cognito trigger (below).
- **MFA: OFF in Cognito.** For federated users Cognito does **not** apply its own MFA — the second factor is the **IdP's** (enable 2FA on the admin's Google account). *Trade-off:* MFA isn't centrally controlled; if native users are ever added, switch MFA back to TOTP.

## Configuration — user pool + Google IdP + client + custom domain
```hcl
# The Google OAuth client_secret lives in Secrets Manager (out-of-band; the client_id is non-secret).
data "aws_secretsmanager_secret_version" "google_oauth" { secret_id = "<project>/${var.environment}/google-oauth" }

module "cognito" {
  source  = "lgallard/cognito-user-pool/aws"
  version = "~> 0.31"

  user_pool_name           = "<project>-${var.environment}"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  mfa_configuration        = "OFF"                                    # federated → MFA at the IdP (Google 2FA)
  admin_create_user_config = { allow_admin_create_user_only = true } # NO native self-signup; federation provisions users

  # Threat protection (adaptive auth + leaked-credential checks) — ENFORCED. Requires the Plus feature tier (~$0.05/MAU).
  user_pool_add_ons = { advanced_security_mode = "ENFORCED" }

  # Email via the verified SES domain identity (no 50/day cap, branded from-address) — /infrastructure/ses
  email_configuration = {
    email_sending_account = "DEVELOPER"
    from_email_address    = "no-reply@${local.frontend_host}"
    source_arn            = "arn:aws:ses:${var.aws_region}:${local.account}:identity/${local.frontend_host}"
  }

  # captured attributes — email (verified by Google) + name (mapped from the IdP below)
  schemas = [
    { name = "email", attribute_data_type = "String", required = true,  mutable = true },
    { name = "name",  attribute_data_type = "String", required = false, mutable = true },
  ]

  user_groups = [{ name = "admin", precedence = 1 }, { name = "registered", precedence = 10 }]

  # Google as the (only) identity provider — social-only
  identity_providers = [{
    provider_name     = "Google"
    provider_type     = "Google"
    authorize_scopes  = "openid email profile"
    client_id         = var.google_client_id
    client_secret     = jsondecode(data.aws_secretsmanager_secret_version.google_oauth.secret_string)["client_secret"]
    attribute_mapping = { email = "email", name = "name", username = "sub" }
  }]

  # Cognito trigger Lambda — group assignment + claims (/infrastructure/lambda)
  lambda_config = {
    post_authentication  = module.fn_cognito_groups.lambda_function_arn  # assign 'registered' (+ 'admin' by allowlist)
    pre_token_generation = module.fn_cognito_groups.lambda_function_arn  # ensure cognito:groups in the first token
  }

  # single PUBLIC SPA client — PKCE, Google-only
  client_name                                 = "spa"
  client_generate_secret                      = false
  client_allowed_oauth_flows                  = ["code"]            # Authorization Code + PKCE
  client_allowed_oauth_flows_user_pool_client = true
  client_allowed_oauth_scopes                 = ["openid", "email", "profile"]
  client_callback_urls                        = var.callback_urls
  client_logout_urls                          = var.logout_urls
  client_supported_identity_providers         = ["Google"]         # NOT "COGNITO" → login is Google-only
  client_explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
  # token validity: defaults (access/id 60min, refresh 30d) — tune client_*_token_validity to change

  domain                 = var.auth_domain_name               # auth.{env}.<apex-domain>
  domain_certificate_arn = data.aws_acm_certificate.main.arn  # ISSUED cert in us-east-1 (/infrastructure/acm)
}
```
**Key knobs:** social-only (`client_supported_identity_providers=["Google"]`, no `"COGNITO"`); MFA `OFF` (federated); advanced security **ENFORCED** (Plus tier); **SES** email; PKCE public client; custom hosted-UI domain (us-east-1 ISSUED cert).

## Group assignment — the Cognito trigger (`fn-cognito-groups`)
Federated users aren't auto-grouped, so a small Lambda does it (`/infrastructure/lambda`):
- **post-authentication:** add the user to `registered`; if the email is in the **admin allowlist** (`var.admin_emails`), also add to `admin`. Idempotent (`AdminAddUserToGroup` no-ops if already a member).
- **pre-token-generation:** post-auth runs *after* the token is built, so to land the group in the **first** token, inject/ensure the `cognito:groups` claim here.
- Exec role: `cognito-idp:AdminAddUserToGroup` + `AdminListGroupsForUser` scoped to the pool ARN (`/infrastructure/iam`).
*Why a Lambda:* Cognito has no declarative "federated → group" rule; the trigger is the supported mechanism. The **admin allowlist** is the single source of truth for who's admin — never hand-edit group membership.

## Hosted UI — custom branding
Use **managed login branding** (logo + brand colors), not the default. The sign-in screen shows **"Continue with Google"** as the only action. *Trade-off:* needs brand assets + a branding config; the plain managed login is zero-effort if branding slips.

## Adding providers later (drop-in)
Each = an extra `identity_providers` entry + its name in `client_supported_identity_providers`; each needs an OAuth app registered with that provider (client id/secret → Secrets Manager), redirect `https://{auth_domain}/oauth2/idpresponse`:
- **Native** (`provider_type` = the name): Google (have), Apple (Apple Developer + signing key), Facebook, Amazon.
- **OIDC** (`provider_type="OIDC"` + issuer/endpoints): Microsoft/Entra (consumer + work), LinkedIn, GitHub, GitLab, …
- **SAML:** enterprise IdPs (Okta, Entra SAML) — B2B, not a consumer audience.

## Auth is external to the BFF
The **SPA runs the Authorization Code + PKCE flow via the Cognito SDK / Amplify** and holds/refreshes the JWT; it sends `Authorization: Bearer` to the API GW, whose **Cognito JWT authorizer** validates per route (`/infrastructure/api-gateway`). The **BFF has no auth code** — it only reads claims. No client secret exists (public client).

## Route53 alias + SSM (auth.tf)
```hcl
resource "aws_route53_record" "auth" {                       # /infrastructure/route53
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.auth_domain_name
  type    = "A"
  alias { name = module.cognito.domain_cloudfront_distribution            # lgallard output
          zone_id = "Z2FDTNDATAQYW2", evaluate_target_health = false }
}
# SSM (/infrastructure/ssm): /{env}/auth/cognito-user-pool-id, cognito-client-id, cognito-domain,
#   cognito-hosted-ui-url = https://{auth_domain_name}  (custom domain — the standard)
```

## Conventions
- **Profiles:** public (no auth, no group) / `registered` (any Google sign-in) / `admin` (email allowlist). REGIONAL WAF fronts the hosted UI (`/infrastructure/waf`).
- The Google **client_secret** lives in Secrets Manager (`<project>/${env}/google-oauth`), provisioned out-of-band; only the non-secret **client_id** is a tfvar. The owner creates the Google OAuth client + provides them.
- Pool/client ids → SSM for app repos; the SPA reads them at build (`/frontend/environment-config`).
- New environment → its own pool + custom domain + its own Google OAuth client (distinct redirect host).

## Pros & cons
**Pros**
- No passwords (social-only) — nothing to leak/rotate; low signup friction; MFA delegated to Google.
- Native API GW JWT authorizer + hosted UI; SES email; adaptive auth (threat protection ENFORCED).
**Cons**
- Hard dependency on Google (no email/password fallback); federated users need a trigger for groups.
- Threat protection costs per-MAU (Plus tier), and its leaked-credential check doesn't apply to federated (no stored password) — only adaptive auth does.
- AWS lock-in; less UI flexibility than Auth0.
