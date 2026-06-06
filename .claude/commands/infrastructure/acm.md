Use AWS Certificate Manager (ACM) in tadeumendonca infrastructure.

Context: $ARGUMENTS

## How we use ACM
- Certs are **pre-created out-of-band and DNS-validated once** — never created/validated inside Terraform (`wait_for_validation` blocks `apply` and couples the cert lifecycle to the infra).
- **us-east-1** for CloudFront, API GW custom domains, and Cognito custom domains (all require it there).
- Resolved at runtime **by domain name** via `data "aws_acm_certificate"` — no ARNs in tfvars (nothing sensitive in the repo).
- One cert with **wildcard SANs** covers every env/service host: `{apex}`, `*.{apex}`, `*.staging.{apex}`, `*.production.{apex}`.

```hcl
data "aws_acm_certificate" "main" {
  provider    = aws.us_east_1
  domain      = "tadeumendonca.io"
  statuses    = ["ISSUED"]
  most_recent = true
}
# use: data.aws_acm_certificate.main.arn
```

## Conventions
- Issuing/validating a cert is a **one-time task** (plan bootstrap runbook), not Terraform.
- New subdomain → ensure it's in the cert SANs (`/infrastructure/environment-domains`).
- Consumed by `/infrastructure/cloudfront`, `/infrastructure/api-gateway`, `/infrastructure/cognito`.
