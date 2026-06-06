Use AWS Certificate Manager (ACM) in <project> infrastructure.

Context: $ARGUMENTS

## How we use ACM
- Certs **already exist in the account and are provided for reuse** — pre-created out-of-band and DNS-validated once. Terraform **never** creates/validates them (`wait_for_validation` would block `apply` and couple the cert lifecycle to the infra).
- All in **us-east-1** (CloudFront, API GW custom domains, and Cognito custom domains all require the cert there).
- Resolved at runtime **by domain name** via `data "aws_acm_certificate"` — no ARNs in tfvars.

## Certificate format — one wildcard cert per environment
The environment is the subdomain boundary (`/infrastructure/route53`), so there is **one ACM certificate per environment**, each a wildcard over that environment's subdomain plus the environment's own host:

| Environment | Primary domain | SANs | Covers |
|---|---|---|---|
| production | `<apex-domain>` | `*.<apex-domain>` | apex (SPA), `api.<apex-domain>`, `auth.<apex-domain>` |
| staging | `staging.<apex-domain>` | `*.staging.<apex-domain>` | `staging.` (SPA), `api.staging.`, `auth.staging.` |

> A wildcard matches exactly **one** label, so the environment host itself (`<apex-domain>`, `staging.<apex-domain>`) must be its own SAN — the wildcard alone doesn't cover it. That's why each cert carries `{env-host}` **and** `*.{env-host}`.

## Resolution — per-env data source (resolve by the env's domain)
```hcl
# env/prd.tfvars → acm_certificate_domain = "<apex-domain>"
# env/stg.tfvars → acm_certificate_domain = "staging.<apex-domain>"

data "aws_acm_certificate" "main" {
  provider    = aws.us_east_1
  domain      = var.acm_certificate_domain   # the cert's primary domain for this env
  statuses    = ["ISSUED"]
  most_recent = true
}
# use: data.aws_acm_certificate.main.arn
```
Each per-env workspace resolves **its own** cert by its primary domain — no cross-env ARNs, nothing sensitive in the repo.

## Conventions
- Issuing/validating a cert is a **one-time task** (plan bootstrap runbook), not Terraform.
- New host under an existing env → already covered by that env's `*.{env-host}` wildcard (no cert change). A **new environment** → a new wildcard cert for its subdomain.
- Consumed by `/infrastructure/cloudfront`, `/infrastructure/api-gateway`, `/infrastructure/cognito`.
## Pros & cons
**Pros**
- Reused certs — no in-stack issuance/validation that would block `apply`.
- Per-env wildcard covers every host of the env with one cert; resolved by domain (no ARNs in tfvars).
**Cons**
- Cert lifecycle is out-of-band / manual.
- A wildcard doesn't cover the apex host (needs an explicit SAN); a new environment needs a new cert.
