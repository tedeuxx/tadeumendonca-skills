Author or review any IAM role/policy in tadeumendonca infrastructure.

Context: $ARGUMENTS

**Canonical IAM authoring reference.** Every role/policy we create is catalogued here with its exact permission set + a ready example. Service skills (`documentdb`, `s3`, `sns`, `lambda`, …) **do not embed policy JSON** — they state what a role needs and point here.

Modules: `terraform-aws-modules/iam/aws` submodules `iam-policy` + `iam-assumable-role-with-oidc` (`/infrastructure/terraform`). Lambda exec policies via the lambda module's `attach_policy_statements` / `policy_statements`.

## Principles
- **Least privilege** — scope every statement to specific `Action`s and `Resource` ARNs. `Resource = "*"` is allowed **only** for actions with no resource-level permission, and must carry a `# no resource-level support` comment.
- **No long-lived keys** — GitHub pipelines assume roles via **OIDC**; humans via SSO/console. No IAM users, no access keys.
- **Roles, not users** — Lambda exec roles, deploy roles, service identity-pool roles. Never attach policies to users.
- **No permission boundaries / no inline user policies** at this scale — managed (AWS) + customer-managed (our `iam-policy`) only.

## Authoring conventions
- **Statement shape:** `{ Sid, Effect="Allow", Action=[...], Resource=[...], Condition? }`. One Sid per concern (e.g. `ReadDocdbSecret`, `WriteOgCache`).
- **ARN scoping:** parametrize by env — `arn:aws:secretsmanager:${region}:${account}:secret:tadeumendonca/${env}/*`, `arn:aws:s3:::tadeumendonca-og-images-${env}/*`, SSM `arn:aws:ssm:${region}:${account}:parameter/${env}/*`. Use `data.aws_caller_identity`/`data.aws_region`.
- **Confused-deputy guard:** resource-based trust (Lambda@Edge, cross-service) carries `Condition.StringEquals` on `aws:SourceArn`/`aws:SourceAccount`. OIDC trust uses `StringLike` on `token.actions.githubusercontent.com:sub`.
- **Managed vs customer-managed:** lean on AWS-managed policies for boilerplate (logs, VPC ENIs, X-Ray); write a customer-managed `iam-policy` only for app-specific grants.
- **Naming:** roles `tadeumendonca-${purpose}-${env}` / `github-actions-${repo}-${env}`; policies `tadeumendonca-${purpose}-deploy-${env}`.
- **Region:** Lambda@Edge roles/policies are **global** (created in us-east-1 with the function); everything else is regional.

## AWS-managed policies we rely on
| Managed policy | Attached to | Grants |
|---|---|---|
| `AWSLambdaBasicExecutionRole` | every Lambda role | CloudWatch Logs create/put |
| `AWSLambdaVPCAccessExecutionRole` | BFF role (in-VPC) | ENI create/describe/delete |
| `AWSXRayDaemonWriteAccess` | BFF role | `xray:PutTraceSegments`/`PutTelemetryRecords` |

---

## Role catalog

### 1. BFF Lambda execution role
In-VPC Hono Lambda (`/infrastructure/lambda`, `/backend/bff`). Trust = `lambda.amazonaws.com`. Managed: BasicExecution + VPCAccess + XRayDaemonWrite. Customer-managed inline statements (via lambda module `attach_policy_statements = true`, `policy_statements = {...}`):
```hcl
policy_statements = {
  read_secrets = {                         # docdb + redis creds (/infrastructure/secrets-manager)
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:${region}:${account}:secret:tadeumendonca/${env}/*"]
  }
  read_ssm = {                             # config bus (/infrastructure/ssm)
    effect    = "Allow"
    actions   = ["ssm:GetParameter", "ssm:GetParametersByPath"]
    resources = ["arn:aws:ssm:${region}:${account}:parameter/${env}/*"]
  }
  og_cache = {                             # og-image PNG cache (/infrastructure/s3)
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::tadeumendonca-og-images-${env}/*"]
  }
  publish_events = {                       # async domain events (/infrastructure/sns)
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [module.sns_domain_events.topic_arn]
  }
  # metrics need NO statement — Powertools emits EMF to logs; CloudWatch extracts them (/backend/metrics)
}
```
- **KMS:** add `kms:Decrypt` (scoped to the CMK ARN) **only** if the secret/bucket uses a CMK; AWS-managed keys need no explicit grant (`/infrastructure/kms`).
- **Redis:** ElastiCache uses an AUTH token (from Secrets Manager) — **no IAM data-plane permission** required.
- **SES:** if the notifications module sends mail directly, add `ses:SendEmail`/`SendRawEmail` scoped to the verified identity ARN (`/infrastructure/ses`); if it only publishes to SNS, the `publish_events` statement suffices.

### 2. Lambda@Edge (og-edge) execution role
Replicated edge function (`/backend/og-edge-handler`). **Dual trust** — both principals required:
```hcl
assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{
  Effect = "Allow", Action = "sts:AssumeRole",
  Principal = { Service = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"] }
}]})
```
- Managed: `AWSLambdaBasicExecutionRole` (logs land in each edge region). **No VPC** (edge functions can't be in a VPC).
- Inline: `s3:GetObject` on `arn:aws:s3:::tadeumendonca-og-images-${env}/*` (serve cached OG images). It calls the BFF's **public** routes over HTTPS — no IAM for that.
- Created in **us-east-1** (global).

### 3. GitHub OIDC deploy roles (api, fed) — iam.tf
IaC creates a **deploy policy** (`iam-policy` submodule) + an **OIDC-assumable role** (`iam-assumable-role-with-oidc`) per app repo, then writes the role ARNs to SSM. Trust = the **pre-existing** GitHub OIDC provider, scoped to `repo:tadeumendonca/<repo>:*`.
```hcl
module "policy_api_deploy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.0"
  name    = "tadeumendonca-api-deploy-${var.environment}"
  policy  = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect = "Allow"
    Action = ["lambda:UpdateFunctionCode", "lambda:PublishVersion",   # BFF code + og-edge version
              "apigateway:PUT", "apigateway:POST",                    # reimport OpenAPI
              "s3:PutObject", "s3:GetObject",                         # artifacts bucket
              "ssm:GetParameter", "ssm:GetParametersByPath"]
    Resource = "*"                                                    # scope to artifacts/bff/api ARNs where supported
  }]})
}
module "policy_fed_deploy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"; version = "~> 5.0"
  name   = "tadeumendonca-fed-deploy-${var.environment}"
  policy = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect = "Allow"
    Action = ["s3:PutObject", "s3:DeleteObject", "s3:ListBucket",     # site sync
              "cloudfront:CreateInvalidation",
              "ssm:GetParameter", "ssm:GetParametersByPath"]
    Resource = "*" }]})
}
module "oidc_api" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.0"
  create_role                  = true
  role_name                    = "github-actions-api-${var.environment}"
  provider_url                 = "token.actions.githubusercontent.com"   # pre-existing provider
  oidc_subjects_with_wildcards = ["repo:tadeumendonca/tadeumendonca-api:*"]
  role_policy_arns             = [module.policy_api_deploy.arn]
}
module "oidc_fed" { /* same shape, fed repo + module.policy_fed_deploy.arn */ }
# SSM (/infrastructure/ssm): /{env}/iam/github-actions-api-role-arn, /{env}/iam/github-actions-fed-role-arn
```
- **api-deploy** permissions: `lambda:UpdateFunctionCode`/`PublishVersion`, `apigateway:PUT`/`POST`, `s3:PutObject`/`GetObject`, `ssm:GetParameter`/`GetParametersByPath`.
- **fed-deploy** permissions: `s3:PutObject`/`DeleteObject`/`ListBucket`, `cloudfront:CreateInvalidation`, `ssm:GetParameter`/`GetParametersByPath`.
- The GitHub OIDC provider is **pre-existing** (landing zone) — referenced by `provider_url`, not created. App repos read `AWS_OIDC_ROLE_ARN` from SSM at deploy — never a rotatable secret (`/workflow/github-actions`).

### 4. RUM guest identity-pool role
Cognito **identity pool** unauthenticated role used by CloudWatch RUM to put events (`/infrastructure/cloudwatch-rum`). Trust = `cognito-identity.amazonaws.com` with `Condition.StringEquals "cognito-identity.amazonaws.com:aud" = <identity_pool_id>` and `ForAnyValue:StringLike "amr" = "unauthenticated"`. Inline: `rum:PutRumEvents` scoped to the app-monitor ARN.

### 5. iac repo's own deploy role
`github-actions-tadeumendonca-iac` is **bootstrapped out-of-band** (chicken-and-egg) — a one-time landing-zone task in the plan, not Terraform-managed here.

## Conventions
- Role ARNs → SSM for app repos to assume at deploy (`/infrastructure/ssm`); app repos read `AWS_OIDC_ROLE_ARN`, never a rotatable GitHub secret.
- Key choice + encryption requirements follow `/infrastructure/kms`; tagging via provider `default_tags` (`/infrastructure/terraform`).
