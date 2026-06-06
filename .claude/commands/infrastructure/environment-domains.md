Apply the per-environment domain/subdomain naming pattern.

Context: $ARGUMENTS

## Pattern: one apex per product, environment-scoped subdomains

Each service gets a stable subdomain and the **environment is encoded in the host**. Production uses the bare apex (+ `api.` / `auth.`); non-prod nests the service under an environment label.

| Service | Production | Staging |
|---|---|---|
| Frontend (SPA) | `tadeumendonca.io` | `staging.tadeumendonca.io` |
| API | `api.tadeumendonca.io` | `api.staging.tadeumendonca.io` |
| Auth (Cognito hosted UI) | `auth.tadeumendonca.io` | `auth.staging.tadeumendonca.io` |

General form: production `{service?}.{apex}`, non-prod `{service?}.{environment}.{apex}` (the frontend has no service prefix).

## Wiring — per-env tfvars
```hcl
# env/prd.tfvars                         # env/stg.tfvars
domain_name      = "tadeumendonca.io"          # "staging.tadeumendonca.io"
api_domain_name  = "api.tadeumendonca.io"      # "api.staging.tadeumendonca.io"
auth_domain_name = "auth.tadeumendonca.io"     # "auth.staging.tadeumendonca.io"
```
These vars feed CloudFront aliases, the API GW custom domain, the Cognito custom domain, and the Route53 records.

## ACM coverage
A single cert per apex covers every service/env host: `{apex}`, `*.{apex}`, `*.staging.{apex}`, `*.production.{apex}` (us-east-1, out-of-band — `/infrastructure/terraform`).

## Conventions
- The **subdomain is the environment boundary** — never an env query param/header.
- Callback/logout URLs follow the frontend host (`https://{frontend-host}/callback`).
- New service → add `{service}.{...}` following the table and include it in the cert SANs.
- **Reusable across future products** — swap the apex, keep the structure.
- Records via `/infrastructure/dns`; custom domains via `/infrastructure/cloudfront-spa`, `/infrastructure/api-gw-contract`, `/infrastructure/cognito-custom-domain`.
