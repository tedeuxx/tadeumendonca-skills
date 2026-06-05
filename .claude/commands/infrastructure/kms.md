Apply the KMS key policy across tadeumendonca-iac.

Context: $ARGUMENTS

## Policy
- **Default to AWS-managed keys** (`aws/s3`, `aws/secretsmanager`, `aws/rds`, `aws/elasticache`) for at-rest encryption — zero key management, no extra cost, sufficient for this workload.
- **Use a customer-managed key (CMK)** only when you need one of: cross-account/grant control, custom rotation schedule, key-usage auditing (CloudTrail), or one shared key across resources. Provision via `terraform-aws-modules/kms/aws` (`/infrastructure/module-policy`).
- **Rotation:** any CMK sets `enable_key_rotation = true`.
- **Least privilege:** a CMK key policy grants `kms:Decrypt`/`Encrypt`/`GenerateDataKey` only to the roles that need it (e.g. the Lambda exec role for Secrets/Redis/DocDB data keys) — never `kms:*` to `*`.

## Current stance
Phase 1-3 use **AWS-managed keys** everywhere (DocDB, Redis, S3, Secrets Manager) — no CMK yet. Revisit if a compliance or key-sharing requirement appears.

## Conventions
- Never disable encryption to avoid key setup — use the AWS-managed key.
- Tag CMKs per `/infrastructure/tagging`; pair with the at-rest requirements in `/infrastructure/encryption`.
