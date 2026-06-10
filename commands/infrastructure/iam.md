Author or review any IAM role/policy in <project> infrastructure.

Context: $ARGUMENTS

**Canonical authoring reference for RUNTIME IAM** — the roles the *running application + its services* use (Lambda exec role, Lambda@Edge role, and an identity-pool role IF/when browser-direct AWS access is added). Service skills (`dynamodb`, `s3`, `sns`, `lambda`, …) **do not embed policy JSON** — they state what a role needs and point here.

> **Pipeline/deploy roles are NOT here.** The iac-runner + api/fed OIDC deploy roles are **CI concerns** (their trust = the GitHub-OIDC handshake) and live in **`/workflow/github-actions`** — even though the api/fed ones are Terraform-authored in `iam.tf`. This catalog is runtime identity only.

Modules: `terraform-aws-modules/iam/aws//modules/iam-policy` for customer-managed policies (`/infrastructure/terraform`); Lambda exec policies via the lambda module's `attach_policy_statements` / `policy_statements`.

## Principles
- **Least privilege** — scope every statement to specific `Action`s and `Resource` ARNs. `Resource = "*"` is allowed **only** for actions with no resource-level permission, and must carry a `# no resource-level support` comment.
- **No long-lived keys** — GitHub pipelines assume roles via **OIDC**; humans via SSO/console. No IAM users, no access keys.
- **Roles, not users** — Lambda exec roles + (future) identity-pool roles here; pipeline/deploy roles in `/workflow/github-actions`. Never attach policies to users.
- **No permission boundaries / no inline user policies** at this scale — managed (AWS) + customer-managed (our `iam-policy`) only.

## Authoring conventions
- **Statement shape:** `{ Sid, Effect="Allow", Action=[...], Resource=[...], Condition? }`. One Sid per concern (e.g. `ReadRedisSecret`, `DataTableAccess`, `WriteOgCache`).
- **ARN scoping:** parametrize by env — `arn:aws:secretsmanager:${region}:${account}:secret:<project>/${env}/*`, `arn:aws:s3:::<project>-og-images-${env}/*`, SSM `arn:aws:ssm:${region}:${account}:parameter/${env}/*`. Use `data.aws_caller_identity`/`data.aws_region`.
- **Confused-deputy guard:** resource-based trust (Lambda@Edge, cross-service) carries `Condition.StringEquals` on `aws:SourceArn`/`aws:SourceAccount`. OIDC trust uses `StringLike` on `token.actions.githubusercontent.com:sub`.
- **Managed vs customer-managed:** lean on AWS-managed policies for boilerplate (logs, VPC ENIs, X-Ray); write a customer-managed `iam-policy` only for app-specific grants.
- **Naming:** roles `<project>-${purpose}-${env}` / `github-actions-${repo}-${env}`; policies `<project>-${purpose}-deploy-${env}`.
- **Region:** Lambda@Edge roles/policies are **global** (created in us-east-1 with the function); everything else is regional.

## AWS-managed policies we rely on
| Managed policy | Attached to | Grants |
|---|---|---|
| `AWSLambdaBasicExecutionRole` | every Lambda role | CloudWatch Logs create/put |
| `AWSLambdaVPCAccessExecutionRole` | BFF role **only when in-VPC** | ENI create/describe/delete |
| `AWSXRayDaemonWriteAccess` | BFF role | `xray:PutTraceSegments`/`PutTelemetryRecords` |

---

## Role catalog

### 1. BFF Lambda execution role
Hono BFF Lambda (`/infrastructure/lambda`, `/backend/bff`). Trust = `lambda.amazonaws.com`. Managed: BasicExecution + XRayDaemonWrite (**+ VPCAccess only if the BFF is in-VPC** — it's non-VPC by default, see `/infrastructure/lambda` "VPC posture"). Customer-managed inline statements (via lambda module `attach_policy_statements = true`, `policy_statements = {...}`):
```hcl
policy_statements = {
  read_secrets = {                         # redis AUTH token (/infrastructure/secrets-manager)
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:${region}:${account}:secret:<project>/${env}/*"]
  }
  data_tables = {                          # DynamoDB data tier — pure IAM, no secret (/infrastructure/dynamodb)
    effect  = "Allow"
    actions = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem",
               "dynamodb:DeleteItem", "dynamodb:Query", "dynamodb:BatchGetItem"]   # no Scan in hot paths
    resources = [                          # the five per-entity tables + their GSIs — never dynamodb:* on *
      "arn:aws:dynamodb:${region}:${account}:table/<project>-*-${env}",        # <project>-<entity>-<env>
      "arn:aws:dynamodb:${region}:${account}:table/<project>-*-${env}/index/*"
    ]
  }
  read_ssm = {                             # config bus (/infrastructure/ssm)
    effect    = "Allow"
    actions   = ["ssm:GetParameter", "ssm:GetParametersByPath"]
    resources = ["arn:aws:ssm:${region}:${account}:parameter/${env}/*"]
  }
  og_cache = {                             # og-image PNG cache (/infrastructure/s3)
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::<project>-og-images-${env}/*"]
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
- Inline: `s3:GetObject` on `arn:aws:s3:::<project>-og-images-${env}/*` (serve cached OG images). It calls the BFF's **public** routes over HTTPS — no IAM for that.
- Created in **us-east-1** (global).

### 3. Cognito trigger role (fn-cognito-groups)
Trust = `lambda.amazonaws.com`. Managed: `AWSLambdaBasicExecutionRole`. Inline — assign federated users to groups (`/infrastructure/cognito`), scoped to the pool ARN:
```hcl
{ effect = "Allow",
  actions = ["cognito-idp:AdminAddUserToGroup", "cognito-idp:AdminListGroupsForUser"],
  resources = ["arn:aws:cognito-idp:${region}:${account}:userpool/${pool_id}"] }
```
Non-VPC. The **admin allowlist** (which emails get `admin`) is the trigger's config, not an IAM concern.

### 4. RUM guest identity-pool role — NOT BUILT (future / only if CloudWatch RUM is added)
> We currently have **only a Cognito User Pool** (authentication — issues JWTs the SPA sends to the API GW authorizer). There is **NO identity pool** deployed. An **identity pool is a different service**: it vends **temporary AWS credentials** (via STS) so a *browser* can call AWS APIs **directly**. The only reason to add one is **CloudWatch RUM** (real-user monitoring — the browser calls `rum:PutRumEvents`). RUM is not in Phases 1-3, so this role does not exist yet.

When/if RUM lands: a Cognito **identity pool** unauthenticated (guest) role (`/infrastructure/cloudwatch-rum`). Trust = `cognito-identity.amazonaws.com` with `Condition.StringEquals "cognito-identity.amazonaws.com:aud" = <identity_pool_id>` and `ForAnyValue:StringLike "amr" = "unauthenticated"`. Inline: `rum:PutRumEvents` scoped to the app-monitor ARN. **User-Pool-only is the default** — add an identity pool solely for a browser-direct-AWS feature like RUM.

### Pipeline/deploy roles → `/workflow/github-actions`
The iac-runner + **api/fed OIDC deploy roles** (trust = OIDC handshake; permissions = least-privilege deploy grants) are documented in `/workflow/github-actions`. Their Terraform still lives in `iam.tf` (`iam-policy` + `iam-assumable-role-with-oidc` submodules, ARNs → SSM `/{env}/iam/github-actions-{api,fed}-role-arn`), but as **pipeline** concerns they're described there, not in this runtime catalog.

## Conventions
- Role ARNs → SSM for app repos to assume at deploy (`/infrastructure/ssm`); app repos read `AWS_OIDC_ROLE_ARN`, never a rotatable GitHub secret.
- Key choice + encryption requirements follow `/infrastructure/kms`; tagging via provider `default_tags` (`/infrastructure/terraform`).
## Pros & cons
**Pros**
- One canonical authoring catalog — no policy JSON scattered across service skills.
- Least-privilege + OIDC (no long-lived keys); per-service permission sets.
**Cons**
- The central file must stay in sync with each service's needs.
- Least-privilege requires upkeep as features change.
