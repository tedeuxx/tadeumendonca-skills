Provision or review SES (domain verification + DKIM) in <project>-iac (auth.tf).

Context: $ARGUMENTS

Module: **`cloudposse/ses/aws ~> 0.25`** (`/infrastructure/terraform`). Phase 1 verifies the domain identity + DKIM; sending lands in Phase 2 via the BFF notifications module (`/backend/notifications`).

## Configuration
```hcl
module "ses" {
  source  = "cloudposse/ses/aws"
  version = "~> 0.25"

  domain        = "<apex-domain>"                 # root identity — shared across environments
  zone_id       = data.aws_route53_zone.main.zone_id # module writes verification + DKIM records here
  verify_domain = true
  verify_dkim   = true

  ses_user_enabled = false                           # NO SMTP IAM user — the BFF role sends via the SES API
  ses_group_enabled = false
}
```
**Choices that matter:**
- **`ses_user_enabled = false`** — we do **not** create an SES SMTP IAM user/credentials; the BFF Lambda sends through the SES API using its exec role (`ses:SendEmail` scoped to the identity ARN — `/infrastructure/iam`). No long-lived SMTP secret.
- **Root domain identity** (`<apex-domain>`), not per-env — one verified domain; the from-address is `var.ses_from_address` (default `no-reply@<apex-domain>`).
- `verify_dkim = true` — DKIM CNAMEs are auto-created in Route53 (`/infrastructure/route53`), required for deliverability.

## Available but not used (yet)
- **Custom MAIL FROM domain** (`mail.<apex-domain>`) — improves SPF alignment; add when deliverability tuning is needed.
- **Configuration set + event destination** (SNS/CloudWatch) for bounce/complaint tracking — wire when sending volume grows (`/infrastructure/sns`).

## Notes
- New AWS accounts start in the **SES sandbox** (send only to verified addresses) — requesting production access is a manual, out-of-band step, not Terraform.
- The BFF reaches SES via **NAT egress** (it's a public AWS endpoint, no VPC endpoint here) — `/infrastructure/vpc`.
- **Encryption:** SES API is **TLS/SSL by default** (HTTPS), and outbound mail is sent with TLS to recipient MTAs. SES holds no at-rest datastore in our usage; if a configuration-set archive / S3 export is added later it must be **KMS-encrypted** (`/infrastructure/kms`).

## Pros & cons
**Pros**
- No SMTP credential to store/rotate — the BFF role sends via the SES API.
- One shared domain verification + DKIM across environments.
**Cons**
- Sending is tied to the Lambda role rather than portable SMTP creds.
- Less env isolation of the sending identity; sandbox→production is a manual step.
