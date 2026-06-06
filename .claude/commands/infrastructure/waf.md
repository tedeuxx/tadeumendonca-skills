Implement or review the WAF WebACLs (CLOUDFRONT + REGIONAL) in <project>-iac.

Context: $ARGUMENTS

Two WebACLs via **`cloudposse/waf/aws ~> 1.0`** (`/infrastructure/terraform`). CLOUDFRONT scope **must** use the us-east-1 provider alias. Inputs below follow the module's schema.

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

## CLOUDFRONT scope (frontend.tf) — us-east-1
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

## REGIONAL scope (auth.tf) — shared by API GW + Cognito
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

## Associations (raw — no native WAF attribute on these resources)
```hcl
resource "aws_wafv2_web_acl_association" "cognito" {     # Cognito hosted UI — open self-signup
  resource_arn = module.cognito.user_pool_arn
  web_acl_arn  = module.waf_regional.web_acl_arn
}
resource "aws_wafv2_web_acl_association" "api_gw" {       # aws_apigatewayv2_stage has no native WAF arg
  resource_arn = module.apigw.stage_arn
  web_acl_arn  = module.waf_regional.web_acl_arn
}
```

## Notes
- CLOUDFRONT WAF protects the SPA distribution; REGIONAL WAF is **shared** by the API GW stage + Cognito hosted UI (mitigates abuse on open signup).
- SSM: `/{env}/auth/waf-regional-arn = module.waf_regional.web_acl_arn` (cross-file reference).
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
- One shared REGIONAL WebACL for API GW + Cognito — one rule set, one bill.
**Cons**
- Less precise than hand-written rules.
- A novel attack not matched by a rule passes (rate limit is the backstop).
- Can't tune the API vs Cognito surfaces independently.
