---
description: Publish non-sensitive configuration to SSM Parameter Store with Terraform as a cross-repo config bus — the path namespace, which component owns which parameter, and how deploy jobs read them. Use when infrastructure must hand a value to an application repo, naming a parameter, or deciding a value is not sensitive enough to need more. Not for sensitive values (see secrets-manager) or how an application reads them (see environment-config).
---

Use AWS SSM Parameter Store in <project> infrastructure (the cross-repo config bus).

Context: $ARGUMENTS

SSM Parameter Store is how IaC publishes non-sensitive infra outputs for the **application deploy jobs** (the API's and the SPA's, wherever they live) to read at deploy time — the single source of truth, no GitHub secret to rotate. Secrets stay in Secrets Manager (`/secrets-manager`).

The bus is defined by **producer and consumer roles, not by repository layout**: one writer (the IaC that owns the resource) and any number of readers. That is deliberately independent of whether the apps are one monorepo, several repos or a single repo with the IaC beside them — the parameter path is the contract, so changing the layout never changes the wiring.

## Path structure & naming
Same idea as the log-path convention (`/cloudwatch`): the **first levels make ownership obvious at a glance**. Shape:

`/{env}/{component}/{name}`
- **L1 `{env}`** — environment scope: `staging` | `production` (matches `var.environment`). A hard isolation boundary — no parameter is shared across environments.
- **L2 `{component}`** — the workload area that **owns** the value: `frontend` · `api` · `auth` · `data` · `cache` · `storage` · `iam` · `events`. Names the producer/consumer at a glance.
- **L3 `{name}`** — the specific parameter, **kebab-case**, descriptive (`cloudfront-distribution-id`, `bff-function-name`).

Rules: type **`String`** only (never `SecureString` — runtime secrets live in Secrets Manager); values are ARNs / ids / endpoints / names, never sensitive material; one value per parameter; **IaC writes, the application deploy jobs read**.

## Parameters by component
| Component | Parameters |
|---|---|
| `frontend` | `s3-bucket-name`, `cloudfront-distribution-id`, `ga-measurement-id`, `rum-app-monitor-id`, `rum-identity-pool-id` |
| `api` | `gateway-url`, `gateway-id`, `bff-function-name`, `lambda-edge-og-qualified-arn` |
| `auth` | `cognito-user-pool-id`, `cognito-client-id`, `cognito-domain`, `cognito-hosted-ui-url`, `waf-regional-arn` |
| `data` | `profile-table-name`, `posts-table-name`, `articles-table-name`, `subscriptions-table-name`, `audits-table-name` *(DynamoDB table names — access is pure IAM, no secret)* |
| `cache` | `redis-endpoint` *(AUTH token stays in Secrets Manager)* |
| `storage` | `artifacts-bucket-name`, `og-images-bucket-name` |
| `iam` | `github-actions-api-role-arn`, `github-actions-fed-role-arn` |
| `events` | `topic-arn` *(SNS domain events — `/sns`)* |

## What stays in Secrets Manager (sensitive)
- `<project>/{env}/redis` — auth_token.
- *(DynamoDB has no secret — access is pure IAM on the table ARNs, `/iam`.)*
- Never store passwords/tokens in SSM (even SecureString) — only the **ARN** of the secret goes in SSM.

## How the app deploy jobs read at deploy (GitHub Actions)
```bash
S3_BUCKET=$(aws ssm get-parameter --name /$ENV_NAME/storage/artifacts-bucket-name --query 'Parameter.Value' --output text)
```
Every `aws_ssm_parameter` in IaC writes the corresponding module output; the application deploy jobs only read.

## Rationale
Non-sensitive infra outputs in SSM Standard String (free); secrets in Secrets Manager. IaC is the single source of truth — the application deploy jobs read current values at deploy with no GitHub secret to rotate. Access is HTTPS/TLS by default (`/kms`).
## Decision & trade-off
- **SSM is the config bus between workloads — NO `terraform_remote_state`.** Cross-repo wiring (shared infra → app workloads) is an **acyclic DAG**: a producer writes a parameter, consumers read it at deploy. *Why over remote state:* it **decouples the repos** — the shared side never references app resources, so apply order is simply shared→app (destroy app→shared), and neither repo's state depends on the other's internals.
- *Trade-off:* the coupling is **eventual / ordering-sensitive** — a consumer reads whatever value exists at deploy time, so the producer must be applied first, and a changed value needs a consumer redeploy to take effect (reads are eventually consistent).
- **String only, never SecureString.** Values are non-sensitive ids/ARNs/endpoints/names; secrets live in Secrets Manager and only their **ARN** is published here. Keeps the bus free (Standard tier) and out of the rotation surface.

## Pros & cons
**Pros**
- Free config bus; IaC is the single source of truth; no GitHub secret to rotate.
- Clear `env/component/name` paths make ownership obvious.
**Cons**
- Not for secrets (Secrets Manager handles those).
- App reads at deploy — a changed value needs a redeploy; reads are eventually consistent.
