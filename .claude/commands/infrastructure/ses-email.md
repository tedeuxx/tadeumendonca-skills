Provision or review SES (domain verification + DKIM) in tadeumendonca-iac (auth.tf).

Context: $ARGUMENTS

## Module: cloudposse/ses/aws (~> 0.25)

```hcl
module "ses" {
  source  = "cloudposse/ses/aws"
  version = "~> 0.25"

  domain        = "tadeumendonca.io"
  zone_id       = data.aws_route53_zone.main.zone_id
  verify_domain = true
  verify_dkim   = true            # module auto-creates the Route53 verification + DKIM records
}
```

## Notes
- The module creates the domain-identity verification record and the DKIM CNAME records in Route53 automatically (`zone_id` from the shared `data.aws_route53_zone.main`).
- Domain identity is on the **root** `tadeumendonca.io` (shared across environments); the from-address is `var.ses_from_address` (default `no-reply@tadeumendonca.io`).
- Consumed by **`fn-notifications`** (Phase 2) to email registered subscribers on new posts. The Lambda needs `ses:SendEmail` in its `policy_statements` (api.tf) and reaches SES via NAT egress.
- New AWS accounts start in the **SES sandbox** (can only send to verified addresses) — requesting production access is a manual, out-of-band step, not Terraform.
- Phase 1 only verifies the domain/DKIM; actual sending lands in Phase 2 (v0.3.0).
