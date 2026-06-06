Apply the encryption + KMS key policy across tadeumendonca-iac.

Context: $ARGUMENTS

**Canonical encryption skill.** Everything is encrypted **in transit AND at rest** — no plaintext data path, no unencrypted storage. **Every service that encrypts data references this skill** for the key choice (AWS-managed vs CMK); they do not restate it.

**Mandate (no exceptions):** every service is **KMS-encrypted at rest** (AWS-managed key by default, CMK when required) **and TLS/SSL-encrypted in transit — SSL by default across the whole architecture.** No plaintext path, ever. A service skill states its mechanism and points here; it never opts out.

## Rule
Verify **both axes** for every new resource before merge. `checkov` enforces many of these (`/infrastructure/terraform`).

## In transit (TLS)
| Service | How | Skill |
|---|---|---|
| CloudFront | `minimum_protocol_version = "TLSv1.2_2021"`, `viewer_protocol_policy = redirect-to-https` | `/infrastructure/cloudfront` |
| API GW v2 | HTTPS-only custom domain (ACM); no HTTP | `/infrastructure/api-gateway` |
| Cognito hosted UI | HTTPS (ACM, us-east-1) | `/infrastructure/cognito` |
| DocumentDB | client `tls: true` + CA bundle; cluster enforces TLS | `/infrastructure/documentdb`, `/backend/document-db` |
| Redis | `transit_encryption_enabled = true` + AUTH token | `/infrastructure/elasticache` |
| S3 | reached only via CloudFront OAC over HTTPS; bucket policy denies `aws:SecureTransport = false` | `/infrastructure/s3` |

## At rest
| Service | How | Skill |
|---|---|---|
| DocumentDB | `storage_encrypted = true` | `/infrastructure/documentdb` |
| Redis | `at_rest_encryption_enabled = true` | `/infrastructure/elasticache` |
| S3 (×3) | **SSE-KMS** (`aws/s3` key + bucket keys) | `/infrastructure/s3` |
| Secrets Manager | KMS (`aws/secretsmanager`) by default | `/infrastructure/secrets-manager` |
| SNS topic + SQS DLQ | `kms_master_key_id` (`aws/sns`, `aws/sqs`) | `/infrastructure/sns` |
| CloudWatch Logs | encrypted (CMK when required) | `/infrastructure/cloudwatch` |

> All AWS API calls (Secrets Manager, SNS, SES, SSM, S3, STS…) are HTTPS/TLS by default — the SSL-by-default mandate holds end to end.

## Key choice — AWS-managed vs CMK
- **Default to AWS-managed keys** (`aws/s3`, `aws/secretsmanager`, `aws/rds`, `aws/elasticache`) — zero key management, no extra cost, sufficient for this workload. On the Terraform side this means leaving `kms_key_id` empty/unset.
- **Use a customer-managed key (CMK)** only when you need one of: cross-account/grant control, custom rotation schedule, key-usage auditing (CloudTrail), or one shared key across resources. Provision via `terraform-aws-modules/kms/aws` (`/infrastructure/terraform`).
- **Rotation:** any CMK sets `enable_key_rotation = true`.
- **Least privilege:** a CMK key policy grants `kms:Decrypt`/`Encrypt`/`GenerateDataKey` only to the roles that need it (e.g. the BFF exec role for Secrets/Redis/DocDB data keys — `/infrastructure/iam`) — never `kms:*` to `*`.

## Current stance
Phase 1-3 use **AWS-managed keys** everywhere (DocDB, Redis, S3, Secrets Manager, CloudWatch Logs) — **no CMK yet**. Revisit if a compliance or key-sharing requirement appears.

## Conventions
- Never disable encryption to avoid key setup — use the AWS-managed key.
- A service needing `kms:Decrypt` adds it to its exec-role statements **only when using a CMK** (`/infrastructure/iam`); with AWS-managed keys no explicit grant is needed.
- Tag CMKs via provider `default_tags` (`/infrastructure/terraform`).
