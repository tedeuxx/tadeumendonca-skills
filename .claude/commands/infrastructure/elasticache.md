Provision or review the ElastiCache for Redis cluster (cache.tf) in <project>-iac.

Context: $ARGUMENTS

Distributed cache (cache-aside in front of DocumentDB), in-VPC and SG-gated like the database. Module: **`cloudposse/elasticache-redis/aws ~> 1.0`** (`/infrastructure/terraform`). The api-side client lives in `/backend/redis-cache`.

## Configuration (every argument we set)
```hcl
module "redis" {
  source  = "cloudposse/elasticache-redis/aws"
  version = "~> 1.0"

  name = "<project>-${var.environment}"

  # engine
  engine_version = "7.1"
  family         = "redis7"
  port           = 6379

  # network (VPC-only, private)
  vpc_id                  = module.vpc.vpc_id
  subnets                 = module.vpc.private_subnets
  allowed_security_groups = [aws_security_group.lambda.id]      # inbound 6379 only from the Lambda SG

  # sizing / HA
  instance_type              = "cache.t4g.micro"               # Graviton; the floor
  cluster_size               = var.environment == "production" ? 2 : 1   # 1 primary + N-1 replicas
  cluster_mode_enabled       = false                           # single shard (no sharding need)
  automatic_failover_enabled = var.environment == "production" # requires cluster_size >= 2
  multi_az_enabled           = var.environment == "production"

  # encryption (MANDATORY — both axes; /infrastructure/kms)
  transit_encryption_enabled = true                            # TLS in transit
  at_rest_encryption_enabled = true                            # KMS at rest
  auth_token                 = random_password.redis_auth.result   # AUTH, carried over TLS
  kms_key_id                 = ""                              # "" = AWS-managed key; CMK ARN when required

  # maintenance / backup
  apply_immediately          = var.environment != "production"
  maintenance_window         = "sun:05:00-sun:06:00"
  auto_minor_version_upgrade = true
  snapshot_window            = "03:00-05:00"
  snapshot_retention_limit   = var.environment == "production" ? 7 : 0   # days (0 = no backups in stg)

  # parameters
  parameter = [{ name = "maxmemory-policy", value = "allkeys-lru" }]      # evict LRU when full (it's a cache)

  # logs → CloudWatch (/infrastructure/cloudwatch)
  log_delivery_configuration = [
    { destination = "/aws/elasticache/<project>-${var.environment}/slow-log",
      destination_type = "cloudwatch-logs", log_format = "json", log_type = "slow-log" },
    { destination = "/aws/elasticache/<project>-${var.environment}/engine-log",
      destination_type = "cloudwatch-logs", log_format = "json", log_type = "engine-log" }
  ]
}
resource "random_password" "redis_auth" { length = 32, special = false }
```
**Choices that matter:** Redis `7.1`/`redis7`; **single shard** (`cluster_mode_enabled=false`); HA only in prod (`automatic_failover` + `multi_az` need `cluster_size>=2`); `maxmemory-policy=allkeys-lru` (cache eviction, not a datastore); snapshots prod 7d / stg off; **encryption mandatory on both axes** — TLS + AUTH in transit, KMS at rest (AWS-managed key default, CMK per `/infrastructure/kms`).

## AUTH token → Secrets Manager (never SSM/tfvars)
```hcl
resource "aws_secretsmanager_secret" "redis" { name = "<project>/${var.environment}/redis" }
resource "aws_secretsmanager_secret_version" "redis" {
  secret_id     = aws_secretsmanager_secret.redis.id
  secret_string = jsonencode({ auth_token = random_password.redis_auth.result })
}
# SSM (non-sensitive): /{env}/cache/redis-endpoint = module.redis.endpoint
```

## Wire into the BFF (api.tf)
- `environment_variables`: `REDIS_ENDPOINT = module.redis.endpoint`, `REDIS_SECRET_ARN = aws_secretsmanager_secret.redis.arn`.
- Exec role: `secretsmanager:GetSecretValue` on the redis secret (`/infrastructure/iam`).

## Notes
- Private subnets, port 6379, reached in-VPC over the SG — off the NAT path (like DocumentDB).
- Prod = 1 primary + 1 replica (Multi-AZ failover); staging = single node. `cache.t4g.micro` (Graviton).
- Fail-open is enforced on the api side — see `/backend/redis-cache`.
