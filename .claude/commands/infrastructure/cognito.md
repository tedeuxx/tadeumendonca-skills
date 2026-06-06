Use Amazon Cognito in tadeumendonca infrastructure.

Context: $ARGUMENTS

Module: `terraform-aws-modules/cognito-idp/aws ~> 8.0`.

## User pool standard
```hcl
username_attributes      = ["email"]
auto_verified_attributes = ["email"]
mfa_configuration        = "OPTIONAL"
password_policy          = { minimum_length = 12, require_uppercase = true, require_numbers = true, require_symbols = true }
admin_create_user_config = { allow_admin_create_user_only = false }    # registered users self-signup
groups                   = { admin = {...}, registered = {...} }
clients = {
  spa = { generate_secret = false, allowed_oauth_flows = ["code"],     # PKCE, public client
          allowed_oauth_scopes = ["openid","email","profile"], callback_urls, logout_urls }
}
```

## Conventions
- **Three profiles:** public (no auth) / registered (self-signup, auto-verified email) / admin (created manually). REGIONAL WAF fronts the open hosted-UI signup (`/infrastructure/waf`).
- App client is **public (no secret), Authorization Code + PKCE** — but the SPA never runs PKCE directly; the **BFF** does (`/backend/bff`). Cognito issues the JWT the API GW authorizer validates.
- Hosted-UI **custom domain** + Route53 alias + us-east-1 cert → `/infrastructure/cognito-custom-domain`, `/infrastructure/acm`.
- Pool/client ids published to SSM for app repos (`/infrastructure/ssm-config-bus`).
