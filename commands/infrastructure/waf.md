Implement or review the WAF WebACLs (CLOUDFRONT + REGIONAL) across the two repos that own them.

Context: $ARGUMENTS

Two WebACLs via **`cloudposse/waf/aws ~> 1.0`** (`/infrastructure/terraform`), split by ownership:
- **REGIONAL** (shared) lives in **`<project>-iac`** — the shared regional WAF baseline. Its ARN is **published to SSM** (`/{env}/auth/waf-regional-arn`) for workloads to consume; the `<project>-pwa/iac` deploy reads that SSM value to associate the REST API stage + Cognito hosted UI.
- **CLOUDFRONT** (the SPA WebACL) lives in **`<project>-pwa/iac`**, defined alongside the CloudFront distribution it protects.

CLOUDFRONT scope **must** use the us-east-1 provider alias. Inputs below follow the module's schema.

## Common knobs (both WebACLs)
```hcl
default_action = "allow"                              # allow unless a rule blocks (block-listing model)
visibility_config = {                                 # CloudWatch metrics + sampled requests for tuning
  cloudwatch_metrics_enabled = true
  sampled_requests_enabled   = true
  metric_name                = "<project>-${scope}-${var.environment}"
}
# rate limiting — blunt DoS / brute-force guard (limit + key nest inside `statement`)
rate_based_statement_rules = [
  { name = "rate-limit", priority = 10, action = "block",
    statement = { limit = 2000, aggregate_key_type = "IP" } }
]
# logging → the AWS-mandated `aws-waf-logs-` group (/infrastructure/cloudwatch)
logging_enabled         = true
log_destination_configs = [aws_cloudwatch_log_group.waf.arn]   # name MUST start with aws-waf-logs-
```

## CLOUDFRONT scope (`<project>-pwa/iac`, frontend.tf) — us-east-1
```hcl
module "waf_cloudfront" {
  source    = "cloudposse/waf/aws"
  version   = "~> 1.0"
  providers = { aws = aws.us_east_1 }                # CLOUDFRONT scope requires us-east-1
  name      = "<project>-cloudfront-${var.environment}"
  scope     = "CLOUDFRONT"
  default_action = "allow"
  managed_rule_group_statement_rules = [
    { name = "common", priority = 1, override_action = "none",
      statement = { name = "AWSManagedRulesCommonRuleSet", vendor_name = "AWS" } }
  ]
  # + visibility_config, rate_based_statement_rules, logging (above)
}
# attached to CloudFront via web_acl_id = module.waf_cloudfront.web_acl_arn
```

## REGIONAL scope (`<project>-iac`, shared) — associated to API GW (REST) stage + Cognito hosted UI
```hcl
module "waf_regional" {
  source  = "cloudposse/waf/aws"
  version = "~> 1.0"
  name    = "<project>-regional-${var.environment}"
  scope   = "REGIONAL"
  default_action = "allow"
  managed_rule_group_statement_rules = [
    { name = "common",         priority = 1, override_action = "none",
      statement = { name = "AWSManagedRulesCommonRuleSet",         vendor_name = "AWS" } },
    { name = "known-bad",      priority = 2, override_action = "none",
      statement = { name = "AWSManagedRulesKnownBadInputsRuleSet", vendor_name = "AWS" } }
  ]
  # + visibility_config, rate_based_statement_rules, logging (above)
}
```
**Choices that matter:** `default_action="allow"` (we block-list via rules, not allow-list); `override_action="none"` per managed group = the group's rules **block** (use `"count"` to tune a noisy group without blocking); rate-limit 2000 req / 5 min / IP; metrics + sampled requests on for tuning; REGIONAL adds KnownBadInputs on top of Common.

The REGIONAL WAF is **shared** by the **REST API stage** (`/infrastructure/api-gateway`) and the **Cognito hosted UI**. WAFv2 REGIONAL associates with API Gateway **REST (v1)**, ALB, AppSync, Cognito user pools, App Runner — note it does **not** support API Gateway **v2 (HTTP APIs)**; using a REST API is partly what makes this per-IP protection on the API possible.

## Associations (raw — no native WAF attribute on these resources)
```hcl
resource "aws_wafv2_web_acl_association" "cognito" {     # auth.tf — Cognito hosted UI (open self-signup)
  resource_arn = module.cognito.arn                      # lgallard user-pool ARN output
  web_acl_arn  = module.waf_regional.arn
}
resource "aws_wafv2_web_acl_association" "api_gw" {       # api.tf — REST API stage (WAF-associable)
  resource_arn = aws_api_gateway_stage.this.arn
  web_acl_arn  = module.waf_regional.arn
}
```

## Notes
- CLOUDFRONT WAF (in `<project>-pwa/iac`) protects the SPA distribution; the REGIONAL WAF (in `<project>-iac`) is **shared** by the REST API stage + the Cognito hosted UI (mitigates abuse on open signup + the public API surface).
- SSM: `<project>-iac` publishes `/{env}/auth/waf-regional-arn = module.waf_regional.arn`; the `<project>-pwa/iac` deploy reads it to associate the API GW stage + Cognito user pool.
- Logs go to an `aws-waf-logs-<project>-${env}` group (mandated prefix — `/infrastructure/cloudwatch`); WAF holds no at-rest data of its own. TLS is terminated at CloudFront / API GW, which enforce TLS 1.2+ (`/infrastructure/kms`).
- `aws_wafv2_web_acl_association` is justified raw glue — no module abstracts the stage/user-pool association.

## Managed rules & OWASP coverage
**Use AWS managed rule groups wherever possible** — AWS maintains the signatures, minimizing our operational overhead (no custom-rule upkeep). The chosen groups give **baseline OWASP Top 10-aligned coverage**:
- **`AWSManagedRulesCommonRuleSet`** (both scopes) — core protections across common OWASP categories (XSS, LFI/RFI, oversized payloads, bad bots).
- **`AWSManagedRulesKnownBadInputsRuleSet`** (REGIONAL) — known-exploit / SSRF / Log4j-style inputs.
- **Optional add-ons** per surface: `AWSManagedRulesSQLiRuleSet` (SQLi — for rich API query input), `AWSManagedRulesAmazonIpReputationList`, `AWSManagedRulesAnonymousIpList`.
Write a custom rule **only** when no managed group covers the need; tune a noisy managed rule with `override_action="count"` rather than replacing it.

## Pros & cons
**Pros**
- AWS-maintained managed rule groups + rate limit — OWASP-ish coverage for free.
- `default_action=allow` (block-list) doesn't break legitimate traffic.
- One CLOUDFRONT + one REGIONAL WebACL (SPA edge + REST API stage + Cognito hosted UI) — managed rules, low upkeep.
**Cons**
- Less precise than hand-written rules.
- A novel attack not matched by a rule passes (rate limit is the backstop).
- One shared REGIONAL WebACL for the REST API + Cognito — can't tune those surfaces independently.
