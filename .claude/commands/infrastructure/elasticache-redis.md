Provision or review the ElastiCache for Redis cluster (cache.tf) in tadeumendonca-iac.

Context: $ARGUMENTS

Distributed cache for the backend (cache-aside in front of DocumentDB). Same in-VPC, SG-gated pattern as the database. The api-side client + cache-aside usage lives in `/backend/redis-cache`.

## Module: cloudposse/elasticache-redis/aws (~> 1.0)

```hcl
module "redis" {
  source  = "cloudposse/elasticache-redis/aws"
  version = "~> 1.0"

  name       = "tadeumendonca-${var.environment}"
  vpc_id     = module.vpc.vpc_id
  subnets    = module.vpc.private_subnets
  allowed_security_groups = [aws_security_group.lambda.id]   # inbound 6379 from Lambda SG

  instance_type        = "cache.t4g.micro"
  cluster_size         = var.environment == "production" ? 2 : 1   # primary + replica in prod
  cluster_mode_enabled = false

  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  auth_token                 = random_password.redis_auth.result   # in-transit AUTH
}
```

## AUTH token → Secrets Manager (never SSM/tfvars)

```hcl
resource "random_password" "redis_auth" { length = 32; special = false }

resource "aws_secretsmanager_secret" "redis" {
  name = "tadeumendonca/${var.environment}/redis"
}
resource "aws_secretsmanager_secret_version" "redis" {
  secret_id     = aws_secretsmanager_secret.redis.id
  secret_string = jsonencode({ auth_token = random_password.redis_auth.result })
}
```

## SSM (non-sensitive endpoint only)

```hcl
resource "aws_ssm_parameter" "redis_endpoint" {
  name = "/${var.environment}/cache/redis-endpoint"
  type = "String"; value = module.redis.endpoint
}
```

## Wire into Lambdas (api.tf `environment_variables`)
- `REDIS_ENDPOINT   = module.redis.endpoint`
- `REDIS_SECRET_ARN = aws_secretsmanager_secret.redis.arn`
- Lambda role `policy_statements`: `secretsmanager:GetSecretValue` on the redis secret.

## Notes
- Private subnets, port 6379, reached in-VPC over the SG — off the NAT path (like DocumentDB).
- Prod = 1 primary + 1 replica; staging = single node. `cache.t4g.micro` (Graviton).
- Fail-open is enforced on the api side — see `/backend/redis-cache`.
