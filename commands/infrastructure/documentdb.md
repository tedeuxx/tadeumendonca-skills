Provision or review the DocumentDB cluster (data.tf) in <project>-iac.

Context: $ARGUMENTS

Infra side (cluster + parameter group + Secrets Manager + SSM). The api-side TLS client is `/backend/document-db`. Module: **`cloudposse/documentdb-cluster/aws ~> 1.0`** (cluster + instances + SG + subnet group).

## Configuration (every argument we set)
```hcl
module "docdb" {
  source  = "cloudposse/documentdb-cluster/aws"
  version = "~> 1.0"

  # identity / engine
  name            = "<project>"           # + namespace/stage via context; → <project>-${env}
  stage           = var.environment
  engine          = "docdb"
  engine_version  = "5.0.0"                    # DocumentDB 5.0 (parameter family docdb5.0)
  cluster_family  = "docdb5.0"
  db_port         = 27017

  # sizing
  instance_class  = "db.t4g.medium"           # Graviton; smallest is db.t3.medium — t4g cheaper
  cluster_size    = var.environment == "production" ? 2 : 1   # 1 primary + N-1 replicas

  # network (VPC-only, private)
  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.private_subnets
  allowed_security_groups = [aws_security_group.lambda.id]    # inbound 27017 only from Lambda SG
  allowed_cidr_blocks     = []                                # none — SG-gated only

  # credentials
  master_username = "admin"
  master_password = random_password.docdb.result             # 32-char, stored in Secrets Manager (below)

  # encryption (at rest)
  storage_encrypted = true
  kms_key_id        = ""                       # "" = AWS-managed aws/rds key (/infrastructure/kms)

  # backup / maintenance
  retention_period            = var.environment == "production" ? 7 : 1      # days
  preferred_backup_window     = "03:00-04:00"
  preferred_maintenance_window = "sun:04:30-sun:05:30"
  skip_final_snapshot         = var.environment != "production"
  apply_immediately           = var.environment != "production"               # prod waits for window
  auto_minor_version_upgrade  = true
  deletion_protection         = var.environment == "production"

  # parameter group — TLS enforced, audit logs on
  cluster_parameters = [
    { name = "tls",                          value = "enabled",  apply_method = "pending-reboot" },
    { name = "audit_logs",                   value = "enabled",  apply_method = "pending-reboot" },
    { name = "ttl_monitor",                  value = "enabled",  apply_method = "pending-reboot" },
  ]
  enabled_cloudwatch_logs_exports = ["audit", "profiler"]      # → /infrastructure/cloudwatch
}

resource "random_password" "docdb" { length = 32, special = false }
```

**Choices that matter:** `instance_class` (t4g.medium is the floor that supports Graviton; bump for load), `cluster_size` (prod 2 = HA replica, stg 1 = cost), `tls=enabled` (mandatory — client connects with TLS, `/backend/document-db`), `kms_key_id` empty = AWS-managed key (CMK only per `/infrastructure/kms`), `deletion_protection` + `skip_final_snapshot` gated on env.

## Credentials → Secrets Manager (never SSM plaintext)
```hcl
resource "aws_secretsmanager_secret" "docdb" {
  name                    = "<project>/${var.environment}/docdb"
  recovery_window_in_days = var.environment == "production" ? 7 : 0
}
resource "aws_secretsmanager_secret_version" "docdb" {
  secret_id     = aws_secretsmanager_secret.docdb.id
  secret_string = jsonencode({ username = "admin", password = random_password.docdb.result,
                               host = module.docdb.endpoint, port = 27017, dbname = "<project>" })
}
```

## SSM — references only (the ARN + endpoint, never the secret)
```hcl
# /${env}/data/docdb-secret-arn      = aws_secretsmanager_secret.docdb.arn
# /${env}/data/docdb-cluster-endpoint = module.docdb.endpoint
```

## Notes
- VPC-only (private subnets, 27017) — never publicly reachable; reached over the Lambda SG.
- Lambdas read creds at runtime from `DOCDB_SECRET_ARN` (api.tf env), not SSM (`/infrastructure/ssm`).
- Tags via provider `default_tags` (`/infrastructure/terraform`); encryption requirements `/infrastructure/kms`.

## Rationale — DocumentDB over DynamoDB
Document model fits nested CV/article data; DynamoDB single-table adds key complexity with no benefit at this scale. VPC-only aligns with the private-subnet backend. Tradeoff: fixed cost (~$54/mo `db.t4g.medium`), no pay-per-request.
## Backup & retention
- **Continuous automated backups + point-in-time restore (PITR)** within `retention_period` (**7d production / 1d staging**; AWS allows 1–35). Daily window via `preferred_backup_window`; snapshots KMS-encrypted.
- **Final snapshot on delete in production** (`skip_final_snapshot=false` + `final_snapshot_identifier`); staging skips it for fast teardown. `deletion_protection` on in prod.
- **Take a manual snapshot before risky migrations.** Restore = launch a **new** cluster from a snapshot or a PITR timestamp (no in-place restore) — update the SSM endpoint after.
## Pros & cons
**Pros**
- Mongo-compatible document model fits nested CV/article aggregates.
- VPC-only (private); managed PITR + HA replica.
**Cons**
- Higher fixed cost (~$54/mo `db.t4g.medium`, no pay-per-request).
- VPC-only adds NAT/ENI complexity; not a true MongoDB (feature/version gaps).
