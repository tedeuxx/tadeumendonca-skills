Use AWS Lambda in tadeumendonca infrastructure.

Context: $ARGUMENTS

Module: `terraform-aws-modules/lambda/aws ~> 7.0` (`/infrastructure/terraform`). The deployable set is **one BFF Lambda** (modular monolith — API GW fronts only it) **+ og-edge** (Lambda@Edge, separate). Exec-role permissions: `/infrastructure/iam`.

## Configuration — the BFF Lambda (api.tf)
```hcl
module "bff" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  function_name = "tadeumendonca-bff-${var.environment}"
  handler       = "index.handler"
  runtime       = "nodejs22.x"
  architectures = ["arm64"]          # Graviton — ~20% cheaper, equal/better Node perf
  timeout       = 29                 # API GW max
  memory_size   = 256                # bundles satori/resvg (OG image module)
  tracing_mode  = "Active"           # X-Ray (/infrastructure/cloudwatch-xray)

  # Pattern B — IaC owns config, api repo ships code (module built-in)
  create_package          = false
  ignore_source_code_hash = true
  s3_existing_package     = { bucket = module.artifacts_bucket.s3_bucket_id, key = "bff/bootstrap.zip" }

  # in-VPC (private subnets) for DocDB/Redis
  vpc_subnet_ids         = module.vpc.private_subnets
  vpc_security_group_ids = [aws_security_group.lambda.id]
  attach_network_policy  = true      # AWSLambdaVPCAccessExecutionRole (ENIs)

  environment_variables = {          # non-secret config + secret ARNs (/backend/environment-config)
    ENVIRONMENT = var.environment, LOG_LEVEL = "INFO", POWERTOOLS_SERVICE_NAME = "bff",
    DOCDB_SECRET_ARN = aws_secretsmanager_secret.docdb.arn,
    REDIS_ENDPOINT = module.redis.endpoint, REDIS_SECRET_ARN = aws_secretsmanager_secret.redis.arn,
    OG_IMAGES_BUCKET = module.og_images_bucket.s3_bucket_id, SNS_TOPIC_ARN = module.sns_domain_events.topic_arn
  }

  # least-privilege exec role — statements defined in /infrastructure/iam (BFF role)
  attach_policy_statements = true
  policy_statements        = local.bff_policy_statements
}
```
**Key knobs:** `architectures=["arm64"]` always; `timeout=29` (API GW ceiling); `memory_size=256` (OG image deps); `tracing_mode="Active"`; in-VPC (private subnets + lambda SG). Provisioned concurrency: **none** (cost). Never `Resource="*"` policies — see `/infrastructure/iam`.

## Pattern B — IaC owns config, api repo ships code
IaC provisions the Lambda with a placeholder zip; the api repo deploys code via `update-function-code`. Terraform never manages the code artifact after first apply.
- `create_package = false`, `ignore_source_code_hash = true`, `s3_existing_package → bff/bootstrap.zip` (a minimal `index.js` exporting `handler` returning 503, uploaded before first apply).
- **Lifecycle:** IaC apply sets config (memory/VPC/env/IAM) — never code; api deploy `update-function-code --s3-key bff/latest.zip` — code only. The two never collide.
- *Why:* a code change never triggers a TFC plan/apply round-trip; the module's built-in `ignore_source_code_hash` is the supported mechanism (no raw resource). Handler code via `/backend/framework-hono`; deploy via `/workflow/github-actions`.

## Lambda@Edge (og-edge) — the exception
Same Pattern B, but: `publish = true`, `lambda_at_edge = true`, provider `aws.us_east_1`, **no VPC** (edge can't be in a VPC), dual-trust exec role (`/infrastructure/iam`). After `update-function-code`, the api deploy also calls `publish-version` to get a new qualified ARN. See `/backend/og-edge-handler`.

## Conventions
- Env from IaC + Secrets Manager (`/backend/environment-config`, `/backend/secrets-management`); logs/metrics → `/infrastructure/cloudwatch`, tracing → `/infrastructure/cloudwatch-xray`.
- Function name to SSM `/{env}/api/bff-function-name` (`/infrastructure/ssm`).
