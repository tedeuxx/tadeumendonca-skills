Implement or review the IAM deploy policies + GitHub OIDC roles (iam.tf) in tadeumendonca-iac.

Context: $ARGUMENTS

IaC creates the per-repo **deploy policies** and **OIDC-assumable roles** for the `api` and `fed` repos, then writes the role ARNs to SSM. The `iac` repo's own role is bootstrapped out-of-band.

## Deploy policies — iam-policy submodule (×2)

```hcl
module "policy_api_deploy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.0"
  name    = "tadeumendonca-api-deploy-${var.environment}"
  policy  = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect = "Allow"
    Action = ["lambda:UpdateFunctionCode", "lambda:PublishVersion",
              "apigateway:PUT", "apigateway:POST",
              "s3:PutObject", "s3:GetObject",
              "ssm:GetParameter", "ssm:GetParametersByPath"]
    Resource = "*"
  }]})
}
module "policy_fed_deploy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.0"
  name    = "tadeumendonca-fed-deploy-${var.environment}"
  policy  = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect = "Allow"
    Action = ["s3:PutObject", "s3:DeleteObject", "s3:ListBucket",
              "cloudfront:CreateInvalidation",
              "ssm:GetParameter", "ssm:GetParametersByPath"]
    Resource = "*"
  }]})
}
```

## OIDC roles — iam-assumable-role-with-oidc submodule (×2)

```hcl
module "oidc_api" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.0"
  create_role                  = true
  role_name                    = "github-actions-api-${var.environment}"
  provider_url                 = "token.actions.githubusercontent.com"
  oidc_subjects_with_wildcards = ["repo:tadeumendonca/tadeumendonca-api:*"]
  role_policy_arns             = [module.policy_api_deploy.arn]
}
module "oidc_fed" { /* same shape, fed repo + module.policy_fed_deploy.arn */ }
```

## SSM outputs

```hcl
# /{env}/iam/github-actions-api-role-arn = module.oidc_api.iam_role_arn
# /{env}/iam/github-actions-fed-role-arn = module.oidc_fed.iam_role_arn
```

## Notes
- The GitHub OIDC provider (`token.actions.githubusercontent.com`) is **pre-existing** (created once out-of-band / from the landing zone) — the module references it by `provider_url`, it does not create it.
- The `iac` repo's own deploy role (`github-actions-tadeumendonca-iac`) is bootstrapped manually outside Terraform (chicken-and-egg) — a one-time task tracked in the plan.
- `api`/`fed` repos read `AWS_OIDC_ROLE_ARN` from SSM at deploy time — never a GitHub secret to rotate. See `/infrastructure/ssm-config-bus`.
