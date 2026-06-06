Provision secrets in AWS Secrets Manager (<project> infrastructure).

Context: $ARGUMENTS

This is the **provisioning** (IaC) side. The runtime **consumption** side is `/backend/secrets-management`.

## What & how
- Every sensitive value lives here — never in SSM plain text, tfvars, or code.
- Naming: `<project>/{env}/{component}` (e.g. `…/redis`).
- Value is `jsonencode({...})` with **snake_case** fields (`auth_token`, `username`, `password`, `host`, `port`, `dbname`).

```hcl
resource "aws_secretsmanager_secret" "x" {
  name                    = "<project>/${var.environment}/x"
  recovery_window_in_days = var.environment == "production" ? 7 : 0
}
resource "aws_secretsmanager_secret_version" "x" {
  secret_id     = aws_secretsmanager_secret.x.id
  secret_string = jsonencode({ /* snake_case fields */ })
}
# publish only the ARN to SSM / Lambda env — never the value
```

## Conventions
- Encrypted with the **AWS-managed key** by default (`/infrastructure/kms`); CMK only if cross-account/audit is needed.
- Only the **ARN** is non-sensitive (fine in env var / SSM). The Lambda role gets `secretsmanager:GetSecretValue` scoped to `<project>/{env}/*` (`/infrastructure/iam`).
- Provisioned today for: Redis AUTH (`/infrastructure/elasticache`); any future API keys/tokens as needed. (The DynamoDB data tier needs **no secret** — access is pure IAM, `/infrastructure/dynamodb`. The Cognito app client is public/PKCE — no client secret; the BFF keeps no session — `/backend/bff`.)

## Path structure & naming
Same shape as the SSM config bus (`/infrastructure/ssm`) — first levels make ownership obvious. Secret name: `<project>/{env}/{component}`
- **L1 `<project>`** — workload slug. **L2 `{env}`** — `staging` | `production` (hard isolation; never shared across envs). **L3 `{component}`** — the owning area (`redis`, …); one secret per component, its JSON holds the fields.
- Only the **ARN** (`arn:aws:secretsmanager:{region}:{account}:secret:<project>/{env}/{component}-*`) is non-sensitive → goes to SSM / Lambda env. The Lambda role is scoped to `<project>/{env}/*` (`/infrastructure/iam`).

## Pros & cons
**Pros**
- Native rotation hooks, fine-grained IAM, and access auditing.
- Only ARNs leave the boundary — the value never lands in SSM/tfvars/code.
**Cons**
- ~$0.40/secret/month vs free SSM.
- One more service to reason about than plain env vars.
