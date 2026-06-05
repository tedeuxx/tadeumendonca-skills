Implement or review Pattern B Lambda configuration in tadeumendonca-iac.

Lambda function: $ARGUMENTS

## Pattern B: IaC owns config, api repo ships code

IaC provisions the Lambda with a placeholder zip. The api repo deploys code independently via `update-function-code`. Terraform never manages the code artifact after initial apply.

## Terraform module configuration (api.tf)

```hcl
module "fn" {
  source   = "terraform-aws-modules/lambda/aws"
  version  = "~> 7.0"
  for_each = toset(local.vpc_functions)

  function_name = "tadeumendonca-fn-${each.value}-${var.environment}"
  handler       = "index.handler"
  runtime       = "nodejs22.x"
  architectures = ["arm64"]
  timeout       = 29
  memory_size   = local.fn_memory[each.value]

  # Pattern B — module built-in support
  create_package          = false
  ignore_source_code_hash = true
  s3_existing_package     = {
    bucket = module.artifacts_bucket.s3_bucket_id
    key    = "${each.value}/bootstrap.zip"
  }

  vpc_subnet_ids         = module.vpc.private_subnets
  vpc_security_group_ids = [aws_security_group.lambda.id]
  attach_network_policy  = true
  tracing_mode           = "Active"
  ...
}
```

## bootstrap/placeholder.zip

A minimal `index.js` that exports `handler` returning 503. Uploaded to S3 before first IaC apply. Purpose: allow IaC to provision the Lambda without real code.

## Lifecycle after first apply

- IaC apply: sets config (memory, VPC, env vars, IAM role) — never touches code
- api deploy: `update-function-code --s3-bucket $BUCKET --s3-key {fn}/latest.zip` — code only
- If IaC apply changes env vars → Lambda config updated, code unchanged
- If api deploys new code → Lambda code updated, config unchanged

## Lambda@Edge variant

Same pattern, but: `publish = true`, `lambda_at_edge = true`, provider `aws.us_east_1`. After `update-function-code`, api deploy must also call `publish-version` to get a new qualified ARN.

## Rationale
- **Pattern B** keeps code out of Terraform so a code change never triggers a TFC plan/apply round-trip — IaC owns config (memory/VPC/IAM/env), the api repo ships code via `update-function-code`. The module's built-in `ignore_source_code_hash` is the supported mechanism (no raw resource).
- **arm64 (Graviton2):** ~20% cheaper per GB-second, equal-or-better Node.js performance; esbuild output is platform-agnostic JS — zero cost to adopt.
