Use AWS SSM Parameter Store in tadeumendonca infrastructure (the cross-repo config bus).

Context: $ARGUMENTS

SSM Parameter Store is how IaC publishes non-sensitive infra outputs for the app repos to read at deploy time — the single source of truth, no GitHub secret to rotate. Secrets stay in Secrets Manager (`/infrastructure/secrets-manager`).

## Path structure & naming
Same idea as the log-path convention (`/infrastructure/cloudwatch`): the **first levels make ownership obvious at a glance**. Shape:

`/{env}/{component}/{name}`
- **L1 `{env}`** — environment scope: `staging` | `production` (matches `var.environment`). A hard isolation boundary — no parameter is shared across environments.
- **L2 `{component}`** — the workload area that **owns** the value: `frontend` · `api` · `auth` · `data` · `cache` · `storage` · `iam` · `events`. Names the producer/consumer at a glance.
- **L3 `{name}`** — the specific parameter, **kebab-case**, descriptive (`cloudfront-distribution-id`, `bff-function-name`).

Rules: type **`String`** only (never `SecureString` — runtime secrets live in Secrets Manager); values are ARNs / ids / endpoints / names, never sensitive material; one value per parameter; **IaC writes, app repos read**.

## Parameters by component
| Component | Parameters |
|---|---|
| `frontend` | `s3-bucket-name`, `cloudfront-distribution-id`, `ga-measurement-id`, `rum-app-monitor-id`, `rum-identity-pool-id` |
| `api` | `gateway-url`, `gateway-id`, `bff-function-name`, `lambda-edge-og-qualified-arn` |
| `auth` | `cognito-user-pool-id`, `cognito-client-id`, `cognito-domain`, `cognito-hosted-ui-url`, `waf-regional-arn` |
| `data` | `docdb-cluster-endpoint`, `docdb-secret-arn` *(ARN of the secret, not the secret)* |
| `cache` | `redis-endpoint` *(AUTH token stays in Secrets Manager)* |
| `storage` | `artifacts-bucket-name`, `og-images-bucket-name` |
| `iam` | `github-actions-api-role-arn`, `github-actions-fed-role-arn` |
| `events` | `topic-arn` *(SNS domain events — `/infrastructure/sns`)* |

## What stays in Secrets Manager (sensitive)
- `tadeumendonca/{env}/docdb` — username, password, host, port, dbname.
- `tadeumendonca/{env}/redis` — auth_token.
- Never store passwords/tokens in SSM (even SecureString) — only the **ARN** of the secret goes in SSM.

## How app repos read at deploy (GitHub Actions)
```bash
S3_BUCKET=$(aws ssm get-parameter --name /$ENV_NAME/storage/artifacts-bucket-name --query 'Parameter.Value' --output text)
```
Every `aws_ssm_parameter` in IaC writes the corresponding module output; app repos only read.

## Rationale
Non-sensitive infra outputs in SSM Standard String (free); secrets in Secrets Manager. IaC is the single source of truth — app repos read current values at deploy with no GitHub secret to rotate. Access is HTTPS/TLS by default (`/infrastructure/kms`).
