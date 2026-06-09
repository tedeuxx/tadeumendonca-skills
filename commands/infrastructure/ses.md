Provision or review SES (domain verification + DKIM) in <project>-iac (auth.tf).

Context: $ARGUMENTS

Module: **`cloudposse/ses/aws ~> 0.25`** (`/infrastructure/terraform`), in its own `ses.tf`. Verifies the sending domain identity + DKIM; sending lands in Phase 2 via the BFF notifications module (`/backend/notifications`).

## Configuration
```hcl
module "ses" {
  source  = "cloudposse/ses/aws"
  version = "~> 0.25"

  domain        = local.frontend_host             # PER-ENV identity (staging.<apex> / <apex>) — see below
  zone_id       = data.aws_route53_zone.main.zone_id # module writes verification + DKIM records here
  verify_domain = true
  verify_dkim   = true

  ses_user_enabled  = false                          # NO SMTP IAM user — the BFF role sends via the SES API
  ses_group_enabled = false
  name = "ses"; stage = var.environment; enabled = true
}
```
**Choices that matter:**
- **`ses_user_enabled = false`** — we do **not** create an SES SMTP IAM user/credentials; the BFF Lambda sends through the SES API using its exec role (`ses:SendEmail` scoped to the identity ARN — `/infrastructure/iam`). No long-lived SMTP secret.
- **PER-ENV domain identity** (`local.frontend_host` = `staging.<apex>` / `<apex>`), NOT a single apex identity. *Why:* the two environments are **independent Terraform workspaces** and cannot both own the same apex SES identity in one account/region without colliding. Per-env identities isolate them; from-address = `no-reply@<frontend_host>` (a `local`). Trade-off: two verifications instead of one. (To share one identity instead, create it in ONE place and have the other env read it via a data source — never let both workspaces manage it.)
- `verify_dkim = true` — DKIM CNAMEs are auto-created in Route53 (`/infrastructure/route53`), required for deliverability. Verification + DKIM flip to `Success` a few minutes after apply (Route53 propagation); the BFF can send once verified.

## Sending architecture (the full deliverability + ops picture)
Beyond domain verification, a production sender needs:
- **Auth records (Route53):** **DKIM** (signing, module-created) + **SPF** (TXT `v=spf1 include:amazonses.com -all`) + **DMARC** (`_dmarc` TXT, e.g. `v=DMARC1; p=quarantine; rua=mailto:…`). Add SPF/DMARC for inbox placement.
- **Custom MAIL FROM** (`mail.<apex-domain>`): aligns SPF + Return-Path to your domain instead of amazonses.com — recommended once sending starts.
- **Configuration set + event destination:** route **bounces / complaints / deliveries** to SNS (or CloudWatch) so the app suppresses bad addresses and watches reputation. AWS **requires** handling bounces/complaints — high rates get sending paused (`/infrastructure/sns`).
- **Account suppression list:** SES auto-suppresses known bounces/complaints account-wide; honor it (don't re-send).
- **Sandbox → production + limits:** new accounts are sandboxed (verified recipients only, tiny quota). Request production access (manual, out-of-band), then respect the **sending quota + max send rate** — throttle the SNS→notifications fan-out accordingly (`/backend/notifications`).
- **Sending path:** the BFF calls `ses:SendEmail` (role-scoped, `/infrastructure/iam`), reaches SES via NAT (`/infrastructure/vpc`), TLS in transit by default.

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
