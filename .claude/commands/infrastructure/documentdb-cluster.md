Provision or review the DocumentDB cluster (data.tf) in tadeumendonca-iac.

Context: $ARGUMENTS

This is the **infra side** (cluster provisioning + Secrets Manager + SSM). The api-side TLS client singleton lives in `/backend/docdb-connection`.

## Module: cloudposse/documentdb-cluster/aws (~> 1.0)

Handles cluster + instances + security group + subnet group.

```hcl
module "docdb" {
  source  = "cloudposse/documentdb-cluster/aws"
  version = "~> 1.0"

  name               = "tadeumendonca-${var.environment}"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets
  instance_class     = "db.t4g.medium"
  cluster_size       = var.environment == "production" ? 2 : 1   # primary + replica in prod
  master_username    = "admin"
  storage_encrypted  = true
  deletion_protection = var.environment == "production"

  allowed_security_groups = [aws_security_group.lambda.id]   # inbound 27017 only from Lambda SG

  retention_period    = var.environment == "production" ? 7 : 1
  skip_final_snapshot = var.environment != "production"
}
```

## Credentials → Secrets Manager (NEVER SSM plain text)

```hcl
resource "aws_secretsmanager_secret" "docdb" {
  name                    = "tadeumendonca/${var.environment}/docdb"
  recovery_window_in_days = var.environment == "production" ? 7 : 0
}
resource "aws_secretsmanager_secret_version" "docdb" {
  secret_id     = aws_secretsmanager_secret.docdb.id
  secret_string = jsonencode({
    username = "admin"
    password = module.docdb.master_password   # cloudposse generates a random password
    host     = module.docdb.endpoint
    port     = 27017
    dbname   = "tadeumendonca"
  })
}
```

## SSM — references only (the ARN, never the secret)

```hcl
resource "aws_ssm_parameter" "docdb_secret_arn" {
  name = "/${var.environment}/data/docdb-secret-arn"
  type = "String"; value = aws_secretsmanager_secret.docdb.arn
}
resource "aws_ssm_parameter" "docdb_endpoint" {
  name = "/${var.environment}/data/docdb-cluster-endpoint"
  type = "String"; value = module.docdb.endpoint
}
```

## Notes
- `db.t4g.medium` (Graviton). Prod = 1 primary + 1 replica; staging = 1 instance.
- VPC-only (private subnets, port 27017) — never publicly reachable.
- Lambdas read creds at runtime from `DOCDB_SECRET_ARN` (set by IaC in api.tf), not from SSM. See `/infrastructure/ssm-config-bus`.

## Rationale — DocumentDB over DynamoDB
The document model fits nested CV data (experience/roles/tech as sub-docs) and articles (body/tags/metadata in one doc). DynamoDB single-table design adds key-construction complexity with no benefit at portfolio scale. DocumentDB is VPC-only (aligns with the private-subnet backend). Tradeoff: higher fixed cost (~$54/mo `db.t4g.medium`), no pay-per-request. Prod 1 primary + 1 replica; staging single.
