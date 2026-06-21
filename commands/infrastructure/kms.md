Apply the encryption + KMS key policy across <project>-iac.

Context: $ARGUMENTS

**Canonical encryption skill.** Everything is encrypted **in transit AND at rest** — no plaintext data path, no unencrypted storage. **Every service that encrypts data references this skill** for the key choice (AWS-managed vs CMK); they do not restate it.

**Mandate (no exceptions):** every service is **KMS-encrypted at rest** (AWS-managed key by default, CMK when required) **and TLS/SSL-encrypted in transit — SSL by default across the whole architecture.** No plaintext path, ever. A service skill states its mechanism and points here; it never opts out.

## Rule
Verify **both axes** for every new resource before merge. `checkov` enforces many of these (`/infrastructure/terraform`).

## In transit (TLS)
| Service | How | Skill |
|---|---|---|
| CloudFront | `minimum_protocol_version = "TLSv1.2_2021"`, `viewer_protocol_policy = redirect-to-https` | `/infrastructure/cloudfront` |
| API GW (REST) | HTTPS-only custom domain (ACM); no HTTP | `/infrastructure/api-gateway` |
| Cognito hosted UI | HTTPS (ACM, us-east-1) | `/infrastructure/cognito` |
| DynamoDB | reached over HTTPS via the Gateway VPC endpoint (AWS SDK TLS by default) | `/infrastructure/dynamodb`, `/backend/dynamodb` |
| Redis | `transit_encryption_enabled = true` + AUTH token | `/infrastructure/elasticache` |
| S3 | reached only via CloudFront OAC over HTTPS; bucket policy denies `aws:SecureTransport = false` | `/infrastructure/s3` |

## At rest
| Service | How | Skill |
|---|---|---|
| DynamoDB | encrypted at rest by default (AWS-managed `aws/dynamodb` key) | `/infrastructure/dynamodb` |
| Redis | `at_rest_encryption_enabled = true` | `/infrastructure/elasticache` |
| S3 artifacts | **SSE-KMS** (`aws/s3` key + bucket keys) | `/infrastructure/s3` |
| S3 fed + og-images | **SSE-S3 (AES256)** — CloudFront OAC can't decrypt the `aws/s3` KMS key (see note) | `/infrastructure/s3` |
| Secrets Manager | KMS (`aws/secretsmanager`) by default | `/infrastructure/secrets-manager` |
| SNS topic + SQS DLQ | `kms_master_key_id` (`aws/sns`, `aws/sqs`) | `/infrastructure/sns` |
| CloudWatch Logs | encrypted (CMK when required) | `/infrastructure/cloudwatch` |
| Lambda env vars | AWS-managed Lambda key (`kms_key_arn` for a CMK) | `/infrastructure/lambda` |

> **No customer-KMS surface (AWS encrypts internally):** Cognito user pool, API Gateway, CloudFront, Route53, WAF, ACM — there's no key to choose; the at-rest mandate is met by AWS's own encryption. Every service that *does* expose a key surface is listed above and states its choice.

> All AWS API calls (Secrets Manager, SNS, SES, SSM, S3, STS…) are HTTPS/TLS by default — the SSL-by-default mandate holds end to end.

## Key choice — AWS-managed vs CMK
- **Default to AWS-managed keys** (`aws/s3`, `aws/secretsmanager`, `aws/dynamodb`, `aws/elasticache`) — zero key management, no extra cost, sufficient for this workload. On the Terraform side this means leaving `kms_key_id` empty/unset.
- **Use a customer-managed key (CMK)** only when you need one of: cross-account/grant control, custom rotation schedule, key-usage auditing (CloudTrail), or one shared key across resources. Provision via `terraform-aws-modules/kms/aws` (`/infrastructure/terraform`).
- **Rotation:** any CMK sets `enable_key_rotation = true`.
- **Least privilege:** a CMK key policy grants `kms:Decrypt`/`Encrypt`/`GenerateDataKey` only to the roles that need it (e.g. the BFF exec role for Secrets/Redis/DynamoDB data keys — `/infrastructure/iam`) — never `kms:*` to `*`.

## Current stance
Phase 1-3 use **AWS-managed keys** everywhere (DynamoDB, Redis, Secrets Manager, CloudWatch Logs, the artifacts S3 bucket) — **no CMK yet**. Revisit if a compliance or key-sharing requirement appears.

> **CloudFront-served buckets are the one at-rest exception — SSE-S3, not KMS.** CloudFront **OAC cannot decrypt** objects encrypted with the AWS-managed `aws/s3` KMS key: that key's policy is AWS-owned and can't grant the `cloudfront.amazonaws.com` service principal `kms:Decrypt`, so the origin 403s. So the **fed + og-images** buckets use **SSE-S3 (AES256)** (still encryption-at-rest; their content is public anyway). The KMS-preserving alternative is a **customer CMK** whose key policy grants CloudFront `kms:Decrypt` with a `Condition.StringEquals "AWS:SourceArn" = <distribution-arn>` — adopt that only if these buckets ever need KMS (it's the one case where a CMK buys something AWS-managed keys can't).

## Conventions
- Never disable encryption to avoid key setup — use the AWS-managed key.
- A service needing `kms:Decrypt` adds it to its exec-role statements **only when using a CMK** (`/infrastructure/iam`); with AWS-managed keys no explicit grant is needed.
- Tag CMKs via provider `default_tags` (`/infrastructure/terraform`).
## Decision & trade-off
- **AWS-managed keys everywhere by default; no CMK in Phase 1-3.** *Why:* zero key management and **no extra key cost**, sufficient for this workload. *Traded away:* the CMK-only capabilities — custom rotation schedule, CloudTrail key-usage auditing, cross-account/grant control, one shared key. Adopt a CMK only when a compliance or key-sharing requirement actually appears (a migration at that point, not free to retrofit).
- **CloudFront-served buckets are the one at-rest exception — SSE-S3 (AES256), not KMS.** CloudFront OAC can't `kms:Decrypt` under the AWS-managed `aws/s3` key (its policy can't grant the CloudFront service principal), so SSE-KMS 403s the origin. The content is public, so AES256 is the correct stance; the KMS-preserving alternative (a CMK whose policy grants CloudFront `kms:Decrypt` scoped to the distribution `SourceArn`) is the *only* case where a CMK buys something AWS-managed keys can't.
- **S3 Bucket Keys on the KMS buckets** cut KMS API calls (cost) — kept on by default.

## Pros & cons
**Pros**
- Encryption everywhere by default (at rest + TLS); one canonical policy.
- AWS-managed keys = zero key operations and no extra key cost.
**Cons**
- AWS-managed keys lack CMK audit/rotation/cross-account control.
- Always-encrypt adds minor cost (KMS calls; mitigated by S3 bucket keys); moving to CMK later is a migration.
