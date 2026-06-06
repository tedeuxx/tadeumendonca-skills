Implement or review the VPC and networking layer (vpc.tf) in tadeumendonca-iac.

Context: $ARGUMENTS

## Module: terraform-aws-modules/vpc/aws (~> 5.0)

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "tadeumendonca-${var.environment}"
  cidr = var.vpc_cidr   # 10.0.0.0/16

  azs             = var.azs
  public_subnets  = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 8, i + 1)]
  private_subnets = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 8, i + 11)]

  # NAT: 1 total in staging (cost), 1 per AZ in production (HA)
  enable_nat_gateway     = true
  single_nat_gateway     = var.environment != "production"
  one_nat_gateway_per_az = var.environment == "production"

  # S3 Gateway endpoint — keeps S3 traffic on AWS backbone (free). No DynamoDB endpoint (data = DocumentDB).
  vpc_endpoints = { s3 = { service = "s3", service_type = "Gateway" } }

  # VPC Flow Logs → CloudWatch
  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true
  flow_log_traffic_type                = "ALL"
}
```

## Lambda security group (raw — app-specific, out of VPC module scope)

```hcl
resource "aws_security_group" "lambda" {
  name   = "tadeumendonca-lambda-${var.environment}"
  vpc_id = module.vpc.vpc_id
  egress {
    from_port = 443, to_port = 443, protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS egress (S3 via endpoint; Cognito/Secrets/SES via NAT)"
  }
  # DocumentDB (27017) reached via the cluster SG, which allows this SG as source.
}
```

## Downstream references (other .tf files)
- `module.vpc.vpc_id` → docdb, docdb SG
- `module.vpc.private_subnets` → lambda `vpc_subnet_ids`, docdb `subnet_ids`
- `aws_security_group.lambda.id` → lambda `vpc_security_group_ids`, docdb `allowed_security_groups`

## Traffic design — communication preferences
- **S3** from Lambda routes via the **S3 Gateway endpoint** (free, AWS backbone) — never via NAT or the public internet.
- **DocumentDB (27017)** and **Redis (6379)** are reached **in-VPC over their security groups**, off the NAT path.
- Only **Cognito JWT validation, Secrets Manager, and SES** egress go via **NAT** — minimize what crosses NAT (low volume).
- Lambda ENIs live in **private subnets**; API GW v2 and CloudFront are AWS-edge managed (not in the VPC).
- NAT sizing: **single** in staging (cost) vs **one per AZ** in production (HA).

## Notes
- Lambda SG egress is limited to HTTPS (443); inbound to DocDB/Redis is granted by their cluster SGs allowing the Lambda SG as source.
- This VPC topology was established in the (now-decommissioned) landing-zone project and re-created inline — the migration itself is a one-time task tracked in the plan, not a skill.
