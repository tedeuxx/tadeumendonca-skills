Use SSM Parameter Store as cross-repo config bus in tadeumendonca.io.

Context: $ARGUMENTS

## Namespace convention

`/{env}/component/param-name` where `{env}` = `staging` | `production`

## What goes in SSM (non-sensitive)

```
/{env}/frontend/s3-bucket-name
/{env}/frontend/cloudfront-distribution-id
/{env}/api/gateway-url
/{env}/api/gateway-id
/{env}/api/lambda-function-name-{profile|posts|articles|og-image|notifications}
/{env}/api/lambda-edge-og-qualified-arn
/{env}/auth/cognito-user-pool-id
/{env}/auth/cognito-client-id
/{env}/auth/cognito-domain
/{env}/auth/cognito-hosted-ui-url
/{env}/data/docdb-cluster-endpoint
/{env}/data/docdb-secret-arn       ← ARN of the secret, NOT the secret itself
/{env}/cache/redis-endpoint        ← ElastiCache Redis endpoint (AUTH token in Secrets Manager)
/{env}/storage/artifacts-bucket-name
/{env}/storage/og-images-bucket-name
/{env}/iam/github-actions-api-role-arn
/{env}/iam/github-actions-fed-role-arn
```

## What stays in Secrets Manager (sensitive)

- `tadeumendonca/{env}/docdb` — username, password, host, port, dbname
- `tadeumendonca/{env}/redis` — auth_token (Redis in-transit AUTH)
- Never store passwords or tokens in SSM (even SecureString for runtime secrets)

## How app repos read SSM at deploy time (GitHub Actions)

```bash
S3_BUCKET=$(aws ssm get-parameter --name /$ENV_NAME/storage/artifacts-bucket-name \
  --query 'Parameter.Value' --output text)
```

## IaC writes all SSM params after provisioning

Every `aws_ssm_parameter` resource in IaC writes the output of the corresponding module. App repos never write to SSM — they only read at deploy time.

## Rationale
Non-sensitive infra outputs go in SSM Standard String (free); secrets stay in Secrets Manager. This makes IaC the single source of truth — app repos read current values at deploy with no GitHub secret to rotate, and never write to SSM.
