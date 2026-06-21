Use AWS Lambda in <project> infrastructure.

Context: $ARGUMENTS

Module: `terraform-aws-modules/lambda/aws ~> 7.0` (`/infrastructure/terraform`). The deployable set is **one BFF Lambda** (modular monolith — API GW fronts only it) **+ og-edge** (Lambda@Edge, separate) **+ fn-cognito-groups** (a small Cognito trigger that assigns federated users to `registered`/`admin` — `/infrastructure/cognito`). Exec-role permissions: `/infrastructure/iam`. The BFF config below is the canonical example; the others reuse the same module + Pattern-B/non-VPC choices.

## Configuration — the BFF Lambda (api.tf)
```hcl
module "bff" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  function_name = "<project>-bff-${var.environment}"
  handler       = "index.handler"
  runtime       = "nodejs22.x"
  architectures = ["arm64"]          # Graviton — ~20% cheaper, equal/better Node perf
  timeout       = 29                 # API GW max
  memory_size   = 256                # bundles satori/resvg (OG image module)
  tracing_mode  = "Active"           # X-Ray (/infrastructure/cloudwatch-xray)

  # Pattern B — IaC owns config, apps/bff ships code (module built-in)
  create_package          = false
  ignore_source_code_hash = true
  s3_existing_package     = { bucket = module.artifacts_bucket.s3_bucket_id, key = "bff/bootstrap.zip" }

  # NON-VPC by default — see "VPC decision" below. (Add only when an in-VPC dependency like Redis lands:
  #   vpc_subnet_ids = module.vpc.private_subnets
  #   vpc_security_group_ids = [aws_security_group.lambda.id]
  #   attach_network_policy = true )  # AWSLambdaVPCAccessExecutionRole (ENIs)

  environment_variables = {          # non-secret config + table names + secret ARNs (/backend/environment-config)
    ENVIRONMENT = var.environment, LOG_LEVEL = "INFO", POWERTOOLS_SERVICE_NAME = "bff",
    PROFILE_TABLE_NAME = module.profile_table.dynamodb_table_id,            # DynamoDB tables (pure IAM, no secret)
    POSTS_TABLE_NAME = module.posts_table.dynamodb_table_id,
    ARTICLES_TABLE_NAME = module.articles_table.dynamodb_table_id,
    SUBSCRIPTIONS_TABLE_NAME = module.subscriptions_table.dynamodb_table_id,
    AUDITS_TABLE_NAME = module.audits_table.dynamodb_table_id,
    OG_IMAGES_BUCKET = module.og_images_bucket.s3_bucket_id,
    # REDIS_ENDPOINT / REDIS_SECRET_ARN / SNS_TOPIC_ARN added when those components land (Redis forces in-VPC).
  }

  # least-privilege exec role — statements defined in /infrastructure/iam (BFF role)
  attach_policy_statements = true
  policy_statements        = local.bff_policy_statements
}
```
**Key knobs:** `architectures=["arm64"]` always; `timeout=29` (API GW ceiling); `memory_size=256` (OG image deps); `tracing_mode="Active"`; **VPC posture is an owner choice** (see below). Provisioned concurrency: **none** (cost). Never `Resource="*"` policies — see `/infrastructure/iam`.

## VPC posture — a security × cost decision (ASK the owner; can differ per env)
This is **not** a fixed default — it's a deliberate trade-off the owner picks (per the project's "no solo architectural decisions" rule), and it may differ per environment (e.g. non-VPC staging for cost, in-VPC production for posture). Present both:

**Option A — Non-VPC** (Lambda on AWS-managed networking)
- *Cost/perf (pro):* **no NAT Gateway** (~$33/mo per env, ~$66/mo prod one-per-AZ) and **faster cold starts** (no ENI attach).
- *Security (con):* egress goes straight to AWS **service endpoints** (still IAM-auth'd + TLS; Lambda has no inbound either way) — but **no private-subnet isolation, no SG egress control, no VPC flow logs** for the function. Cannot reach VPC-only resources.
- *Mechanics:* omit `vpc_subnet_ids`/`vpc_security_group_ids`/`attach_network_policy`. If the BFF is the only would-be VPC consumer, **don't create `vpc.tf` at all** (no VPC ⇒ no NAT). DynamoDB/S3 Gateway endpoints are a latency/data-cost nicety, **not** a reason to be in-VPC.

**Option B — In-VPC** (private subnets)
- *Security (pro):* network isolation, **SG-based egress control + flow logs**, and the **only** way to reach in-VPC resources (ElastiCache/**Redis**, RDS, private ALB). Often a compliance/posture requirement.
- *Cost (con):* ENI cold-start latency + the egress cost below.
- *Mechanics:* add the three vpc_* knobs + the lambda SG + the VPC (`/infrastructure/vpc`). **Mandatory** once an in-VPC dependency exists.
- *Egress sub-choice (also security × cost):* reach AWS service APIs via a **NAT Gateway** (~$33–66/mo flat, leaves the VPC) **or** **Interface VPC Endpoints/PrivateLink** (fully private on the AWS backbone, ~$7/mo per service per AZ — can drop the NAT). S3/DynamoDB always use the free Gateway endpoints. See `/infrastructure/vpc` "Egress posture".

Switching A↔B later is a clean, reversible change. **Lambda@Edge (og-edge) is always non-VPC** (the edge can't be in a VPC — not a choice).

## Pattern B — IaC owns config, `apps/bff` ships code
IaC provisions the Lambda with a placeholder zip; `apps/bff` deploys code via `update-function-code`. Terraform never manages the code artifact after first apply.
- `create_package = false`, `ignore_source_code_hash = true`, `s3_existing_package → bff/bootstrap.zip` (a minimal `index.js` exporting `handler` returning 503, uploaded before first apply).
- **Lifecycle:** IaC apply sets config (memory/VPC/env/IAM) — never code; api deploy `update-function-code --s3-key bff/latest.zip` — code only. The two never collide.
- *Why:* a code change never triggers a TFC plan/apply round-trip; the module's built-in `ignore_source_code_hash` is the supported mechanism (no raw resource). Handler code via `/backend/framework-hono`; deploy via `/workflow/github-actions`.

## Lambda@Edge (og-edge) — the exception
Same Pattern B, but: `publish = true`, `lambda_at_edge = true`, provider `aws.us_east_1`, **no VPC** (edge can't be in a VPC), dual-trust exec role (`/infrastructure/iam`). After `update-function-code`, the api deploy also calls `publish-version` to get a new qualified ARN. See `/backend/og-edge-handler`.

## Conventions
- Env from IaC + Secrets Manager (`/backend/environment-config`, `/backend/secrets-management`); logs/metrics → `/infrastructure/cloudwatch`, tracing → `/infrastructure/cloudwatch-xray`.
- Function name to SSM `/{env}/api/bff-function-name` (`/infrastructure/ssm`).
## Encryption
- **Env vars** are encrypted at rest with the **AWS-managed Lambda key** by default — kept (no CMK), because the env holds only non-secret config + **secret ARNs** (the secrets live in Secrets Manager, `/backend/secrets-management`). Set `kms_key_arn` only if a CMK is mandated (`/infrastructure/kms`).
- In transit: everything the BFF calls is TLS (DynamoDB, AWS APIs). Non-VPC by default (`/infrastructure/vpc`); in private subnets only when an in-VPC dependency forces it.

## Pros & cons
**Pros**
- arm64 (Graviton) — cheaper, equal/better perf. Non-VPC by default → no NAT, faster cold starts.
- Pattern B decouples code deploys from IaC (no TFC round-trip per code change).
**Cons**
- 29s API GW timeout ceiling; one BFF Lambda = a shared fault domain for all routes.
- Going in-VPC later (for Redis/RDS) reintroduces ENI cold-start overhead + the NAT cost.
