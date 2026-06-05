Apply the encryption policy (in transit + at rest) across tadeumendonca-iac.

Context: $ARGUMENTS

## Rule

**Everything encrypted in transit AND at rest** — no plaintext data path, no unencrypted storage. Verify both axes for every new resource.

## In transit (TLS)
- **CloudFront:** `minimum_protocol_version = "TLSv1.2_2021"`, `viewer_protocol_policy = redirect-to-https` (`/infrastructure/cloudfront-spa`).
- **API GW v2:** HTTPS-only custom domain (ACM); no HTTP.
- **Cognito hosted UI:** HTTPS (ACM, us-east-1).
- **DocumentDB:** client connects `tls: true` + CA bundle (`/backend/docdb-connection`); cluster requires TLS.
- **Redis:** `transit_encryption_enabled = true` + AUTH token (`/infrastructure/elasticache-redis`).
- **S3:** reached only via CloudFront OAC over HTTPS; bucket policy denies `aws:SecureTransport = false`.

## At rest
- **DocumentDB:** `storage_encrypted = true`.
- **Redis:** `at_rest_encryption_enabled = true`.
- **S3 (×3 buckets):** server-side encryption enabled.
- **Secrets Manager:** encrypted by default (KMS).
- **CloudWatch Logs / EBS:** encrypted.

## Conventions
- New resource → confirm transit **and** rest before merge; `checkov` enforces many of these (`/workflow/testing-coverage`).
- Key choice (AWS-managed vs CMK) follows `/infrastructure/kms`.
