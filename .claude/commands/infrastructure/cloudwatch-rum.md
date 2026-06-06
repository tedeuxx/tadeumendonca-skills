Provision CloudWatch RUM (app monitor) in tadeumendonca-iac.

Context: $ARGUMENTS

The real-user-monitoring app monitor the SPA sends to (`/frontend/cloudwatch-rum`). RUM needs a **Cognito identity pool** so unauthenticated (guest) browser clients can put RUM events.

## App monitor + guest identity (Terraform)
```hcl
resource "aws_rum_app_monitor" "fed" {
  name   = "tadeumendonca-${var.environment}"
  domain = var.domain_name                          # staging.tadeumendonca.io | tadeumendonca.io
  app_monitor_configuration {
    session_sample_rate = 0.1                        # cost control
    telemetries         = ["performance", "errors", "http"]
    identity_pool_id    = aws_cognito_identity_pool.rum.id
    enable_xray         = true                       # end-to-end with /infrastructure/cloudwatch-xray
  }
  cw_log_enabled = true
}
# Cognito identity pool; its unauthenticated role grants rum:PutRumEvents on this monitor only
resource "aws_cognito_identity_pool" "rum" { allow_unauthenticated_identities = true /* … */ }
```
Publish to SSM: `/{env}/frontend/rum-app-monitor-id`, `/{env}/frontend/rum-identity-pool-id` (read by the fed build).

## Conventions
- Separate monitor **per environment**; keep `session_sample_rate` low (RUM bills per event).
- Guest role is least-privilege — only `rum:PutRumEvents` on this monitor's ARN (`/infrastructure/iam`).
- Encrypted log group + tagged (`/infrastructure/encryption`, `/infrastructure/tagging`).
- Pairs with `/infrastructure/cloudwatch-xray` for browser→backend traces.
