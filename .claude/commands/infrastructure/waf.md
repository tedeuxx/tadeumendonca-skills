Implement or review the WAF WebACLs (CLOUDFRONT + REGIONAL) in tadeumendonca-iac.

Context: $ARGUMENTS

Two WebACLs via `aws-ia/waf/aws` (~> 1.0). CLOUDFRONT scope **must** use the us-east-1 provider alias.

## CLOUDFRONT scope (frontend.tf)

```hcl
module "waf_cloudfront" {
  source    = "aws-ia/waf/aws"
  version   = "~> 1.0"
  providers = { aws = aws.us_east_1 }          # CLOUDFRONT scope requires us-east-1
  name      = "tadeumendonca-cloudfront-${var.environment}"
  scope     = "CLOUDFRONT"
  managed_rule_groups = [{ name = "AWSManagedRulesCommonRuleSet", vendor_name = "AWS", priority = 1 }]
}
# Attached to CloudFront via web_acl_id = module.waf_cloudfront.web_acl_arn
```

## REGIONAL scope (auth.tf) — shared by API GW + Cognito

```hcl
module "waf_regional" {
  source  = "aws-ia/waf/aws"
  version = "~> 1.0"
  name    = "tadeumendonca-regional-${var.environment}"
  scope   = "REGIONAL"
  managed_rule_groups = [
    { name = "AWSManagedRulesCommonRuleSet",         vendor_name = "AWS", priority = 1 },
    { name = "AWSManagedRulesKnownBadInputsRuleSet", vendor_name = "AWS", priority = 2 }
  ]
}
```

## Associations (raw — no native WAF attribute on these resources)

```hcl
# Cognito hosted UI (auth.tf) — fronts the open self-signup flow
resource "aws_wafv2_web_acl_association" "cognito" {
  resource_arn = module.cognito.user_pool_arn
  web_acl_arn  = module.waf_regional.web_acl_arn
}
# API GW v2 stage (api.tf) — aws_apigatewayv2_stage has no native WAF arg
resource "aws_wafv2_web_acl_association" "api_gw" {
  resource_arn = module.apigw.stage_arn
  web_acl_arn  = module.waf_regional.web_acl_arn
}
```

## Notes
- CLOUDFRONT WAF protects the SPA distribution; REGIONAL WAF is **shared** by the API GW stage and the Cognito hosted UI (mitigates abuse on open signup).
- SSM: `/{env}/auth/waf-regional-arn = module.waf_regional.web_acl_arn` (so api.tf can reference it across files).
- `aws_wafv2_web_acl_association` is a justified raw resource — no community module abstracts the stage/user-pool association.
