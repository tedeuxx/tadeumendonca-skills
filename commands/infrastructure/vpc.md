Implement or review the VPC and networking layer (vpc.tf) in <project>-iac.

Context: $ARGUMENTS

Module: **`terraform-aws-modules/vpc/aws ~> 5.0`** (`/infrastructure/terraform`).

> **First decide IF you need a VPC at all — it's a security × cost trade-off, ASK the owner.** A VPC is only required when something must be **in-VPC** (ElastiCache/Redis, RDS, a private ALB). The BFF Lambda can run **non-VPC** and still reach DynamoDB/S3/SES/Cognito over public AWS endpoints with IAM (`/infrastructure/lambda` "VPC posture"). The cost driver is the **NAT Gateway (~$33/mo per env, ~$66 prod one-per-AZ)** — pure overhead if nothing genuinely needs the private network. The security side is network isolation + SG egress control + flow logs. Lay out both options (per "no solo architectural decisions") and let the owner choose — possibly differently per env. If they choose non-VPC and nothing else needs the network, **skip `vpc.tf` entirely** (no VPC ⇒ no NAT, no Gateway endpoints, no flow logs, no lambda SG). The config below applies once a VPC is warranted.

## Configuration
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "<project>-${var.environment}"
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

  # VPC Flow Logs → CloudWatch (encrypted log group, /infrastructure/cloudwatch)
  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true
  flow_log_traffic_type                = "ALL"
  flow_log_max_aggregation_interval    = 60
  flow_log_cloudwatch_log_group_retention_in_days = var.environment == "production" ? 90 : 30
}

# S3 + DynamoDB Gateway endpoints — keep that traffic on the AWS backbone (free). In v5 the main vpc
# module no longer accepts endpoints, so this is the standalone submodule. DynamoDB is the data tier
# (reached via its Gateway endpoint, off the NAT path — like S3).
module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.0"
  vpc_id  = module.vpc.vpc_id
  endpoints = {
    s3       = { service = "s3", service_type = "Gateway", route_table_ids = module.vpc.private_route_table_ids }
    dynamodb = { service = "dynamodb", service_type = "Gateway", route_table_ids = module.vpc.private_route_table_ids }
  }
}
```
**Choices that matter:** 2 AZs; `/16` VPC, `/24` subnets (8-bit, public `+1..`, private `+11..`); `map_public_ip_on_launch=false` + locked default SG (nothing reachable by accident); NAT single (stg) vs per-AZ (prod); **S3 + DynamoDB Gateway endpoints** (always — they're free); **Interface endpoints vs NAT is an owner choice — see "Egress posture" below**; flow logs ALL with 60s aggregation, retention per env.

## Lambda security group (raw — app-specific, out of module scope)
```hcl
resource "aws_security_group" "lambda" {
  name   = "<project>-lambda-${var.environment}"
  vpc_id = module.vpc.vpc_id
  egress {
    from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS egress (S3 + DynamoDB via endpoints; Cognito/Secrets/SES via NAT)"
  }
  # inbound to Redis (6379) is granted by its cluster SG allowing this SG as source. DynamoDB needs no
  # inbound rule — it's reached over the Gateway endpoint (HTTPS egress), not an in-VPC SG.
}
```
Downstream: `module.vpc.vpc_id` → redis SG · `module.vpc.private_subnets` → lambda/redis subnets · `aws_security_group.lambda.id` → lambda `vpc_security_group_ids`, redis `allowed_security_groups`.

## Egress posture for AWS service APIs — a security × cost decision (ASK the owner)
Once in-VPC, **how the Lambda reaches AWS service APIs** (SES, Cognito-idp, SSM, Secrets Manager, STS, logs, X-Ray, KMS) is itself a trade-off — present both, same rule as the non-VPC question (`/infrastructure/lambda`). S3 + DynamoDB always use the **free Gateway endpoints** either way.

**Option 1 — NAT Gateway:** one flat egress path to all of AWS (and the internet). *Pro:* simple, reaches anything, ~$33/mo (stg single) regardless of how many services. *Con:* traffic leaves the VPC to public endpoints (not "private"), ~$66/mo prod, + $/GB processed.

**Option 2 — Interface VPC Endpoints (PrivateLink):** one endpoint per service (`com.amazonaws.<region>.<service>`), traffic stays **fully on the AWS backbone — never the public internet** (strongest network posture; often a compliance requirement). *Pro:* private, can **drop the NAT entirely** if every service the BFF calls has an endpoint. *Con:* **~$7/mo per endpoint per AZ + $0.01/GB** — cost scales with the number of distinct services × AZs, so it's *cheaper* than NAT for a couple of services but *pricier* for many. No internet egress (can't call non-AWS APIs).
```hcl
# add to the vpc-endpoints module alongside the S3/DynamoDB Gateway entries:
#   secretsmanager = { service = "secretsmanager", service_type = "Interface", subnet_ids = module.vpc.private_subnets, security_group_ids = [aws_security_group.endpoints.id], private_dns_enabled = true }
#   ses, ssm, sts, logs, xray, kms, cognito-idp … one per service the BFF actually calls
```
Rule of thumb: **few AWS services + need privacy → Interface endpoints (no NAT); many services or need internet egress → NAT; no in-VPC dependency at all → non-VPC** (`/infrastructure/lambda`).

## Traffic design (in-VPC)
- **S3** and **DynamoDB** route via their **Gateway endpoints** (free, AWS backbone over HTTPS) — never via NAT or the public internet, under any posture.
- **Redis (6379)** is reached **in-VPC over its security group** (off the NAT path), over TLS.
- Other AWS APIs (Cognito, Secrets Manager, SES, …) egress via **NAT or Interface endpoints** per the posture chosen above.
- Lambda ENIs live in **private subnets**; API GW and CloudFront are AWS-edge managed (not in the VPC).

## Notes
- Lambda SG egress is limited to HTTPS (443) — **everything that crosses the VPC boundary is TLS** (`/infrastructure/kms`); flow logs are encrypted at the CloudWatch group.
- This topology was established in the (now-decommissioned) landing-zone project and re-created inline — the migration is a one-time task tracked in the plan, not a skill.
## Managed prefix lists (SG perimeters)
Define **customer-managed prefix lists** (`aws_ec2_managed_prefix_list`) for logical perimeters (e.g. `admin-cidrs`) and reference the **prefix-list id** in security-group rules instead of inlining CIDRs — maintenance happens in one place (update the list; every SG that references it follows, no rule edits).
```hcl
resource "aws_ec2_managed_prefix_list" "admin" {
  name           = "<project>-admin-${var.environment}"
  address_family = "IPv4"
  max_entries    = 16
  entry { cidr = var.admin_cidr, description = "admin access" }
}
# SG rule:  ingress { prefix_list_ids = [aws_ec2_managed_prefix_list.admin.id] }
```
Also use the **AWS-managed** prefix lists (S3 / DynamoDB) in egress rules instead of wide CIDRs.

## Decision & trade-off
- **Non-VPC by default; no `vpc.tf` at all.** The deployable set is a stateless function that reaches every dependency (DynamoDB/S3/SES/Cognito/SSM/Secrets) over **public AWS service endpoints scoped by IAM** — so there is nothing to put on a private network. A VPC is provisioned **only on demand**, when a genuinely VPC-only resource (RDS, ElastiCache/Redis, a private ALB) is introduced.
- **The driver is a cost ↔ isolation trade-off.** The **NAT Gateway is the single largest line item** (~$33/mo/env, ~$66/mo prod one-per-AZ + $/GB) — pure overhead if nothing needs the private network. Dropping the VPC drops the NAT, the private subnets, the endpoints, the flow logs, and the lambda SG. **Traded away:** no network-layer isolation, no SG egress control, no VPC flow logs for the function.
- **Acceptable because** access is already IAM-auth'd + TLS end to end, and the function has no inbound path either way; the weaker network posture is compensated elsewhere by the IAM role boundary (`/infrastructure/iam`, `/workflow/github-actions`), not by the network.
- **Revisit only** when an in-VPC dependency lands — that flips Lambda to in-VPC and reintroduces the NAT-vs-Interface-endpoint sub-decision above.

## Pros & cons
**Pros**
- Private subnets + SG-gated cache; S3 + DynamoDB Gateway endpoints (free, off-NAT).
- Flow logs for forensics.
**Cons**
- NAT cost (especially one-per-AZ in production); in-VPC Lambda ENI/cold-start overhead.
- 2 AZs trades some resilience for cost.
