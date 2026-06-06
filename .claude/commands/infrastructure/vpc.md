Implement or review the VPC and networking layer (vpc.tf) in ${var.project}-iac.

Context: $ARGUMENTS

Module: **`terraform-aws-modules/vpc/aws ~> 5.0`** (`/infrastructure/terraform`).

## Configuration
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project}-${var.environment}"
  cidr = var.vpc_cidr                                  # 10.0.0.0/16

  azs             = var.azs                            # 2 AZs
  public_subnets  = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 8, i + 1)]
  private_subnets = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 8, i + 11)]

  # DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # subnets: no auto public IPs (nothing public lives in a subnet — edge is AWS-managed)
  map_public_ip_on_launch = false

  # NAT: single in staging (cost) vs one-per-AZ in production (HA)
  enable_nat_gateway     = true
  single_nat_gateway     = var.environment != "production"
  one_nat_gateway_per_az = var.environment == "production"

  # lock the default SG to nothing (no rules) — least privilege
  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  # S3 Gateway endpoint — S3 traffic stays on the AWS backbone (free); no DynamoDB endpoint (data = DocumentDB)
  vpc_endpoints = { s3 = { service = "s3", service_type = "Gateway" } }

  # VPC Flow Logs → CloudWatch (encrypted log group, /infrastructure/cloudwatch)
  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true
  flow_log_traffic_type                = "ALL"
  flow_log_max_aggregation_interval    = 60
  flow_log_cloudwatch_log_group_retention_in_days = var.environment == "production" ? 90 : 30
}
```
**Choices that matter:** 2 AZs; `/16` VPC, `/24` subnets (8-bit, public `+1..`, private `+11..`); `map_public_ip_on_launch=false` + locked default SG (nothing reachable by accident); NAT single (stg) vs per-AZ (prod); **only an S3 Gateway endpoint** (no interface endpoints — low cross-NAT volume doesn't justify the cost); flow logs ALL with 60s aggregation, retention per env.

## Lambda security group (raw — app-specific, out of module scope)
```hcl
resource "aws_security_group" "lambda" {
  name   = "${var.project}-lambda-${var.environment}"
  vpc_id = module.vpc.vpc_id
  egress {
    from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS egress (S3 via endpoint; Cognito/Secrets/SES via NAT)"
  }
  # inbound to DocumentDB (27017) / Redis (6379) is granted by their cluster SGs allowing this SG as source.
}
```
Downstream: `module.vpc.vpc_id` → docdb/redis SGs · `module.vpc.private_subnets` → lambda/docdb/redis subnets · `aws_security_group.lambda.id` → lambda `vpc_security_group_ids`, docdb/redis `allowed_security_groups`.

## Traffic design — communication preferences
- **S3** from Lambda routes via the **S3 Gateway endpoint** (free, AWS backbone over HTTPS) — never via NAT or the public internet.
- **DocumentDB (27017)** and **Redis (6379)** are reached **in-VPC over their security groups** (off the NAT path), both over TLS.
- Only **Cognito JWT validation, Secrets Manager, and SES** egress via **NAT** (low volume, all HTTPS).
- Lambda ENIs live in **private subnets**; API GW v2 and CloudFront are AWS-edge managed (not in the VPC).

## Notes
- Lambda SG egress is limited to HTTPS (443) — **everything that crosses the VPC boundary is TLS** (`/infrastructure/kms`); flow logs are encrypted at the CloudWatch group.
- This topology was established in the (now-decommissioned) landing-zone project and re-created inline — the migration is a one-time task tracked in the plan, not a skill.
