Use AWS Lambda in tadeumendonca infrastructure.

Context: $ARGUMENTS

Module: `terraform-aws-modules/lambda/aws ~> 7.0` (`/infrastructure/module-policy`).

## Standard config (the BFF Lambda; og-edge is the edge exception)
```hcl
runtime       = "nodejs22.x"
architectures = ["arm64"]          # Graviton — ~20% cheaper, equal/better perf
timeout       = 29                 # API GW max
memory_size   = 256                # the BFF bundles satori/resvg (OG image module)
tracing_mode  = "Active"           # X-Ray

vpc_subnet_ids         = module.vpc.private_subnets
vpc_security_group_ids = [aws_security_group.lambda.id]
attach_network_policy  = true

environment_variables    = { ENVIRONMENT, LOG_LEVEL, POWERTOOLS_SERVICE_NAME, *_SECRET_ARN, ... }
attach_policy_statements = true    # least privilege: secretsmanager:GetSecretValue, s3:PutObject (scoped),
                                   # cloudwatch:PutMetricData — never "*" on "*"
```

## Conventions
- **arm64** always; **in-VPC** (private subnets) for DocDB/Redis access; least-privilege `policy_statements`.
- Code/deploy via **Pattern B** (`/infrastructure/lambda-pattern-b`); handler code via `/backend/framework`.
- **Lambda@Edge** (og-edge) is the exception: us-east-1, `publish = true`, no VPC (`/backend/og-edge-handler`).
- Env from IaC + Secrets Manager (`/backend/environment-config`, `/backend/secrets-management`); logs/metrics → `/infrastructure/cloudwatch`.
