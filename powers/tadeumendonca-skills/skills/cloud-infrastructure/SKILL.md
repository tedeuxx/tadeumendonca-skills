---
name: cloud-infrastructure
description: Provision AWS infrastructure in Terraform end to end, one section per service — network, identity and encryption, the config/secrets bus, data stores and cache, storage, compute, API and CDN edge, certificates, DNS, email and event fan-out, and observability. Use when provisioning any AWS resource, choosing between two services, or tracing a cross-service reference. Not for the CI/CD pipeline that runs plan and apply, branching, or the permission model (see devops).
---

# Cloud infrastructure (AWS)

Consolidated infrastructure skill for <project> — every AWS service the platform provisions in Terraform,
merged from the former one-skill-per-service layout into a single reference (#229). The skill's own name,
`cloud-infrastructure`, is deliberately **provider-agnostic** — that is an explicit owner decision made
2026-08-13, leaving room to document a different cloud provider here later without a rename. What follows,
today, documents **AWS specifically** — Terraform, the AWS provider, and AWS-managed services end to end.
Nothing below should be read as multi-cloud guidance; it is the AWS footprint, in depth, one `##` section
per service or capability.

Context: $ARGUMENTS

**Reference vocabulary, not a structure.** Every `### Decision & trade-off` below is tagged with the
dominant **AWS Well-Architected Framework** pillar it optimises for (Cost Optimization, Security,
Reliability, Performance Efficiency, Operational Excellence, Sustainability) — a secondary pillar where
the trade-off genuinely spans two. The tag is a lens for the reader, borrowed to place the owner's
already-made decisions against a shared vocabulary; it is not a pillar-by-pillar audit, and the sections
are not reorganized around the six pillars — that would re-introduce the generic survey this
consolidation was curated to avoid (ADR-0011's 2026-08-13 amendment).

Sections are ordered by architectural layer: Terraform practice (foundation) → network (VPC) → identity,
encryption and the config/secrets bus (IAM, KMS, Secrets Manager, SSM) → Cognito → WAF → data stores
(DynamoDB, ElastiCache) → storage (S3) → compute (Lambda) → API and CDN edge (API Gateway, CloudFront,
ACM, Route53) → email and event fan-out (SES, SNS) → observability (CloudWatch, CloudWatch RUM,
CloudWatch X-Ray). Each section keeps the full depth of its source skill — HCL, "Choices that matter",
"Decision & trade-off", "Pros & cons" — reorganized under one file rather than trimmed. A cross-reference that used to point at one of these 21 skills as its own file (e.g. `/acm`, `/vpc`) now
reads as a reference to the section below/above that covers it instead. References to skills **outside**
this merge (`/devops`, `/agents-configuration`,
`/lambda-handler`, `/redis-cache`, `/notifications`, `/og-edge-handler`, `/environment-config`,
`/secrets-management`, `/authentication`, `/bff`, `/metrics`, `/logging`, `/tracing`, `/pagination`,
`/openapi`, `/devops`, …) are unchanged.

## Terraform

*Set up Terraform for a project as a whole — version and provider pinning, repo layout, project parameterization, input validation, the module-sourcing policy, tagging through default_tags in a shared account, and tfvars per environment. Use when starting an infrastructure repo, deciding whether to adopt a community module, or adding a validated variable. Not for the state backend or the pipeline that runs plan and apply (see devops).*

Terraform provisions the app infra from `<project>-pwa/iac` (the monorepo); the separate `<project>-iac` holds only shared regional infra (the WAF). This is the end-to-end Terraform usage — versions, state, layout, **module sourcing/customization policy**, and **tagging** (both folded in here).

### Versions & providers
```hcl
terraform {
  required_version = ">= 1.9"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
  cloud { organization = "<tfc-org>", workspaces { tags = ["<project>-iac"] } }
}
provider "aws" { region = var.aws_region; default_tags { tags = local.tags } }
provider "aws" { alias = "us_east_1"; region = "us-east-1"; default_tags { tags = local.tags } }  # CloudFront/WAF/ACM
```
Pin provider + module versions with `~>`. Two providers: default + `us_east_1` alias (CloudFront, WAF CLOUDFRONT, ACM, Cognito custom domain).

### State management (TFC)
Remote state only — **Terraform Cloud is the state backend** (`cloud{}`); no local state, no S3/Dynamo backend, state never committed. **One workspace per environment** (`<project>-iac-{staging|production}`, tagged). Execution mode **Local**: TFC stores/locks state, **GitHub Actions runs `plan`/`apply`**. CI selects the target with `TF_WORKSPACE` + matching `-var-file`. Details: `/devops`.
> Inherited from the now-decommissioned landing-zone project.

### Repo layout (single canonical root)
One `terraform/` root, **never duplicated per env** — only the `.tfvars` differs at plan/apply (`-var-file=env/stg.tfvars`). One `.tf` per layer (vpc/storage/data/cache/auth/api/frontend/iam) + `versions`/`providers`/`variables`/`outputs` + `env/*.tfvars` + `bootstrap/`. Public modules called **directly** at root, glue inline — no L3 wrappers (see policy below).

### Project parameterization (reusable across projects)
These skills are **project-agnostic templates**. Workload-specific values appear as **`<…>` placeholders** (a universal notation that reads correctly in HCL, TypeScript, bash, and prose) — substitute them per project. In your IaC each maps to a real variable:

| Placeholder | Backing variable | Used in |
|---|---|---|
| `<project>` | `var.project` | every resource name / SSM path / secret name (`<project>-bff-…`, `<project>/{env}/redis`) |
| `<apex-domain>` | `var.apex_domain` | the registrable apex; per-env hosts derive from it (the Route53 section) |
| `<github-org>` | `var.github_org` | OIDC trust subjects `repo:<github-org>/<project>-pwa:*` (the IAM section) |
| `<tfc-org>` | `var.tfc_organization` | the `cloud{}` block |
| `<account-id>` | `data.aws_caller_identity` | prose only — never hardcoded in config |

Each placeholder is substituted **once, at bootstrap**, by a `terraform.tfvars` value — and `project` is the one worth thinking about before typing, because it is prefixed onto dozens of resource names, SSM paths and secret names: keep it short, lowercase and DNS-safe, since some of those names are length-capped (an IAM role at 64 chars, an ALB target group at 32) and a long project token silently eats the budget the *resource* name needed. The per-environment value (`var.environment` = `staging`/`production`) is a **real variable**, not a placeholder — it's `${var.environment}` in HCL, `process.env.ENVIRONMENT` in TS, `$ENV_NAME` in bash.
> The `cloud{}` block + workspace tags **can't interpolate variables** (parsed before vars resolve) — substitute `<tfc-org>`/`<project>` literally there, or pass via partial config / `TF_WORKSPACE`. Everywhere else uses the variables directly.

### Variables & data sources
`variables.tf` is canonical (`project`, `apex_domain`, `github_org`, `tfc_organization`, `aws_region`, `environment`, `vpc_cidr`, `azs`, `domain_name`, `api/auth_domain_name`, `acm_certificate_domain`, `callback/logout_urls`, `ses_from_address`). **No** `account_id` (→ `data.aws_caller_identity`), **no** ACM ARNs (→ `data.aws_acm_certificate` by `var.acm_certificate_domain` — the ACM section). `data.aws_route53_zone.main` declared once at root.

### Input validation (variables)
**Every input variable declares a `type` and a `validation` block that enforces its domain** — fail fast at `plan`, never discover a bad value at `apply`. This applies to the root variables (the root is the project's own module) **and** to any custom/L3 module you productize (`module sourcing policy` below). Use **`regex`** for format, `contains([...])` for enums, `cidrhost()`/`cidrsubnet()` for networks, comparisons for ranges.
```hcl
variable "project" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}[a-z0-9]$", var.project))
    error_message = "project must be lowercase kebab-case (a-z, 0-9, -), 3–32 chars."
  }
}
variable "environment" {
  type = string
  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "environment must be 'staging' or 'production'."
  }
}
variable "vpc_cidr" {
  type = string
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}
variable "apex_domain" {
  type = string
  validation {
    condition     = can(regex("^([a-z0-9-]+\\.)+[a-z]{2,}$", var.apex_domain))
    error_message = "apex_domain must be a valid domain name (e.g. example.com)."
  }
}
```
- **One concern per `validation` block** (a variable may have several), each with a **clear, actionable `error_message`**.
- Prefer `can(regex(...))` so a non-match becomes a friendly error rather than a crash.
- A custom module is **not productized until every input is typed + domain-validated** — part of the "complete, self-contained L3 pattern" bar below.

### Module sourcing & customization policy
**Sourcing priority:**
1. **Official first** — prefer official `terraform-aws-modules/*` (HashiCorp/AWS-maintained) for any resource that has one: `vpc`, `s3-bucket`, `cloudfront`, `lambda`, `iam`, `kms`, `dynamodb-table` (`~> 4.0`).
2. **Trusted non-official next** — only when no official module exists, use established sources with a track record: `cloudposse/*` (elasticache, ses, waf), `lgallard/*` (cognito — there is no official Cognito module). Never a low-reputation / unmaintained / single-author module.
3. **Raw `aws_*` last** — justified glue only where no module abstracts the need: **`aws_api_gateway_*`** (the REST API — no official module fits the OpenAPI-body + reimport flow, the API Gateway section), `aws_lambda_permission`, `aws_wafv2_web_acl_association`, the app-specific lambda SG, `aws_route53_record`, `aws_ssm_parameter`, `aws_secretsmanager_secret`. Note which gap each fills.

**Customization:**
- **Use public modules integrally** through their documented inputs — do not fork, patch, or wrap to tweak behavior.
- **No L3 wrapper modules by default** — call public modules **directly at root**, compose with `local`/resource refs + inline glue (`frontend.tf`, `api.tf`). No `module "frontend"` / `module "api"` abstraction layers.
- **If a wrapper is truly unavoidable**, build a **complete, self-contained L3 pattern** (full inputs/outputs, documented, versioned) — never a thin/leaky passthrough.
- **Pin versions** with `~>`; no floating / `latest`.

*Why:* official/trusted modules carry maintenance and security review we don't own; using them integrally keeps upgrades a one-line bump and avoids drift. Wrappers/raw resources are debt — taken only when a module genuinely can't express the need, then done fully.

### Tagging (shared AWS account)
The account (`<account-id>`) hosts **multiple workloads/environments**; consistent tags keep them distinguishable, drive cost allocation, and make ownership clear.

| Tag | Value | Why |
|---|---|---|
| `Project` | `<project>` | workload boundary — separates this from other workloads in the account |
| `Environment` | `staging` \| `production` | env isolation + cost split |
| `ManagedBy` | `terraform` | provenance (vs console / other tooling) |

```hcl
locals { tags = { Project = "<project>", Environment = var.environment, ManagedBy = "terraform" } }
# applied once via default_tags on BOTH providers (default + us_east_1) — never per resource
```
- **Set tags once** via `default_tags`; add a resource-level tag only for a specific need (e.g. `Name`).
- The **`Project` tag is the workload boundary** — every new workload uses its own `Project` value.
- Activate `Project` + `Environment` as **cost-allocation tags** in Billing; keep values lowercase and stable.

### Conventions
- Per-env differences via `var.environment == "production"` conditionals — avoid extra variables.
- Resource names `<project>-{...}-${var.environment}`; tags via `default_tags` only.
- Raw glue resources only where no module abstracts (`aws_route53_record`, `aws_lambda_permission`, `aws_wafv2_web_acl_association`, lambda SG).

### CI/CD (.github/workflows)
- `terraform-plan.yml` (PR): `checkov -d terraform/` (fail on any unsuppressed finding) → `fmt -check` → `validate` → `plan` → comment.
- `sonar.yml` (PR + push to develop/main): **SonarCloud IaC** scan of `terraform/` (`/devops`) — code smells + security hotspots, gate blocks. **Complementary to checkov, not a replacement** (checkov = policy/security; Sonar = maintainability + the quality gate). Kept standalone (not a job in `terraform-plan.yml`) so it can run on push for the new-code baseline without firing the AWS-OIDC plan.
- `terraform-deploy.yml`: develop → staging auto-apply; main → production (Environment approval).
- `version-develop/main.yml`: numeric SemVer (`/github-actions`).

See `/devops`, the Route53 section, and the per-service skills.
### Decision & trade-off
*Well-Architected pillar: **Cost Optimization (secondary: Operational Excellence)**.*

- **Single shared AWS account for all environments — no account-level isolation.** A cost decision: a multi-account org adds real overhead/cost not justified for a solo product. Env separation is done with the `Project`/`Environment` tags, per-env resource names (`*-staging`/`*-production`), and per-env TFC workspaces — **not** separate Organizations accounts.
- **The IAM role boundary is the isolation that compensates.** Because there is no account boundary, **least-privilege per-job + per-env OIDC roles are the primary isolation mechanism** (a leaked staging token can't assume the prod role; the prod role is gated by the `production` Environment approval). Cross-ref `/github-actions` (the full secrets/role/OIDC model) and the IAM section (runtime roles) — not restated here.
- **Validate at plan, not apply.** Every input variable carries a `type` + a `validation` block so a bad value fails at `plan` (fast, cheap) rather than mid-`apply` (partial state). *Trade-off:* a little authoring overhead per variable for a much tighter failure mode.
- *Blast radius:* one canonical root per repo means a larger blast radius per apply (vs many small states) — accepted for the simplicity of a single, non-duplicated layout.

### Pros & cons
**Pros**
- Single canonical root (no per-env duplication); TFC remote state + locking.
- Official-first modules used integrally = low maintenance, one-line upgrades.
**Cons**
- The `cloud{}` block can't interpolate variables.
- One root = a larger blast radius per apply; pinned module versions need periodic bumps.


## VPC

*Design or review the VPC layer in Terraform — subnet tiers, NAT gateway versus S3 and DynamoDB Gateway endpoints, Lambda security groups, managed prefix lists, and keeping traffic off NAT. Use when provisioning network topology, deciding whether a Lambda belongs in the VPC at all, or auditing egress cost. Not for IAM policy authoring (see iam) or edge routing (see cloudfront).*

Module: **`terraform-aws-modules/vpc/aws ~> 5.0`** (the Terraform section).

> **First decide IF you need a VPC at all — it's a security × cost trade-off, ASK the owner.** A VPC is only required when something must be **in-VPC** (ElastiCache/Redis, RDS, a private ALB). The BFF Lambda can run **non-VPC** and still reach DynamoDB/S3/SES/Cognito over public AWS endpoints with IAM (the Lambda section "VPC posture"). The cost driver is the **NAT Gateway (~$33/mo per env, ~$66 prod one-per-AZ)** — pure overhead if nothing genuinely needs the private network. The security side is network isolation + SG egress control + flow logs. Lay out both options (per "no solo architectural decisions") and let the owner choose — possibly differently per env. If they choose non-VPC and nothing else needs the network, **skip `vpc.tf` entirely** (no VPC ⇒ no NAT, no Gateway endpoints, no flow logs, no lambda SG). The config below applies once a VPC is warranted.

### Configuration
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

  # VPC Flow Logs → CloudWatch (encrypted log group, /cloudwatch)
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

### Lambda security group (raw — app-specific, out of module scope)
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

### Egress posture for AWS service APIs — a security × cost decision (ASK the owner)
Once in-VPC, **how the Lambda reaches AWS service APIs** (SES, Cognito-idp, SSM, Secrets Manager, STS, logs, X-Ray, KMS) is itself a trade-off — present both, same rule as the non-VPC question (the Lambda section). S3 + DynamoDB always use the **free Gateway endpoints** either way.

**Option 1 — NAT Gateway:** one flat egress path to all of AWS (and the internet). *Pro:* simple, reaches anything, ~$33/mo (stg single) regardless of how many services. *Con:* traffic leaves the VPC to public endpoints (not "private"), ~$66/mo prod, + $/GB processed.

**Option 2 — Interface VPC Endpoints (PrivateLink):** one endpoint per service (`com.amazonaws.<region>.<service>`), traffic stays **fully on the AWS backbone — never the public internet** (strongest network posture; often a compliance requirement). *Pro:* private, can **drop the NAT entirely** if every service the BFF calls has an endpoint. *Con:* **~$7/mo per endpoint per AZ + $0.01/GB** — cost scales with the number of distinct services × AZs, so it's *cheaper* than NAT for a couple of services but *pricier* for many. No internet egress (can't call non-AWS APIs).
```hcl
# add to the vpc-endpoints module alongside the S3/DynamoDB Gateway entries:
#   secretsmanager = { service = "secretsmanager", service_type = "Interface", subnet_ids = module.vpc.private_subnets, security_group_ids = [aws_security_group.endpoints.id], private_dns_enabled = true }
#   ses, ssm, sts, logs, xray, kms, cognito-idp … one per service the BFF actually calls
```
Rule of thumb: **few AWS services + need privacy → Interface endpoints (no NAT); many services or need internet egress → NAT; no in-VPC dependency at all → non-VPC** (the Lambda section).

### Traffic design (in-VPC)
- **S3** and **DynamoDB** route via their **Gateway endpoints** (free, AWS backbone over HTTPS) — never via NAT or the public internet, under any posture.
- **Redis (6379)** is reached **in-VPC over its security group** (off the NAT path), over TLS.
- Other AWS APIs (Cognito, Secrets Manager, SES, …) egress via **NAT or Interface endpoints** per the posture chosen above.
- Lambda ENIs live in **private subnets**; API GW and CloudFront are AWS-edge managed (not in the VPC).

### Connecting beyond a single VPC (hybrid / multi-VPC scenarios)
When a workload must reach **another VPC or on-prem**, the mechanism is again a cost × topology trade-off:
- **VPC Peering** — a 1:1 private link between two VPCs. Cheap (no hourly charge, just $/GB for cross-AZ), but **non-transitive** (A–B + B–C does **not** give A–C) and requires **non-overlapping CIDRs**. Right for a couple of VPCs.
- **Transit Gateway (TGW)** — a hub-and-spoke router; **transitive**, scales to many VPCs/accounts and consolidates VPN/DX. Costs **~$/attachment/hr (≈$36/mo each) + $/GB**. Reach for it past a handful of VPCs or for hybrid consolidation.
- **PrivateLink (Interface endpoint to a service)** — expose/consume **one service** privately across VPC/account boundaries **without joining networks** (no CIDR coordination). Use when you need a service, not full connectivity.
- **VPN vs Direct Connect** — to on-prem: Site-to-Site VPN (encrypted over the internet, cheap, variable latency) vs Direct Connect (dedicated line, consistent latency/throughput, pricier, lead time). Terminate on a TGW or VGW.
- **CIDR planning up front:** size the `/16` and pick ranges that won't overlap future peers/on-prem — **overlapping CIDRs are the #1 thing that blocks peering/TGW later** (and can't be changed without re-addressing).

### Further nuances (the scenarios that bite)
- **Static egress IP** — a 3rd party that **IP-allowlists** you needs a stable source IP: a NAT Gateway's EIP gives one per AZ (pin them). A **non-VPC Lambda has no stable egress IP** — that single requirement can force a VPC.
- **Endpoint policies** — both Gateway and Interface endpoints accept an **IAM-style resource policy** restricting which principals/resources may use them (e.g. an S3 Gateway endpoint scoped to only your buckets) — a least-privilege layer on the data path itself.
- **NACLs vs Security Groups** — SGs (stateful, instance-level) are the primary control; **NACLs** (stateless, subnet-level, ordered allow/deny) are a coarse second layer — most designs leave NACLs open and rely on SGs, using NACLs only for subnet-wide blocks (e.g. deny an IP range). Stateless means you must allow **ephemeral return ports** explicitly.
- **Isolated subnets** — a third tier with **no egress at all** (no IGW, no NAT route) for data stores that must never reach the internet — stricter than "private".
- **Centralized egress** (multi-account scale) — route all spoke VPCs' egress through a **shared NAT in a central network-account VPC** via TGW, collapsing N NATs into one. Overkill for a single account; the pattern to know once the org grows.
- **IPv6** — dual-stack VPCs use an **egress-only Internet Gateway** (the IPv6 analog of NAT) for outbound-only IPv6 — and it is **free**, a way to avoid NAT cost for IPv6-capable egress.

### Notes
- Lambda SG egress is limited to HTTPS (443) — **everything that crosses the VPC boundary is TLS** (the KMS section); flow logs are encrypted at the CloudWatch group.
- This topology was established in the (now-decommissioned) landing-zone project and re-created inline — the migration is a one-time task tracked in the plan, not a skill.
### Managed prefix lists (SG perimeters)
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

### Decision & trade-off
*Well-Architected pillar: **Cost Optimization (secondary: Security)**.*

- **Non-VPC by default; no `vpc.tf` at all.** The deployable set is a stateless function that reaches every dependency (DynamoDB/S3/SES/Cognito/SSM/Secrets) over **public AWS service endpoints scoped by IAM** — so there is nothing to put on a private network. A VPC is provisioned **only on demand**, when a genuinely VPC-only resource (RDS, ElastiCache/Redis, a private ALB) is introduced.
- **The driver is a cost ↔ isolation trade-off.** The **NAT Gateway is the single largest line item** (~$33/mo/env, ~$66/mo prod one-per-AZ + $/GB) — pure overhead if nothing needs the private network. Dropping the VPC drops the NAT, the private subnets, the endpoints, the flow logs, and the lambda SG. **Traded away:** no network-layer isolation, no SG egress control, no VPC flow logs for the function.
- **Acceptable because** access is already IAM-auth'd + TLS end to end, and the function has no inbound path either way; the weaker network posture is compensated elsewhere by the IAM role boundary (the IAM section, `/github-actions`), not by the network.
- **Revisit only** when an in-VPC dependency lands — that flips Lambda to in-VPC and reintroduces the NAT-vs-Interface-endpoint sub-decision above.

### Pros & cons
**Pros**
- Private subnets + SG-gated cache; S3 + DynamoDB Gateway endpoints (free, off-NAT).
- Flow logs for forensics.
**Cons**
- NAT cost (especially one-per-AZ in production); in-VPC Lambda ENI/cold-start overhead.
- 2 AZs trades some resilience for cost.


## IAM

*Author IAM roles and policies in Terraform — least-privilege principles, authoring conventions, which AWS-managed policies are relied on, the role catalog per workload, and the OIDC deploy roles CI assumes. Use when a workload needs a permission, reviewing a policy for over-grant, or pinning an OIDC trust to an immutable subject. Not for the workflow that assumes the role (see devops).*

**Canonical authoring reference for RUNTIME IAM** — the roles the *running application + its services* use (Lambda exec role, Lambda@Edge role, and an identity-pool role IF/when browser-direct AWS access is added). Service skills (`dynamodb`, `s3`, `sns`, `lambda`, …) **do not embed policy JSON** — they state what a role needs and point here.

> **Pipeline/deploy roles are NOT here.** The iac-runner + api/fed OIDC deploy roles are **CI concerns** (their trust = the GitHub-OIDC handshake) and live in **`/github-actions`** — even though the api/fed ones are Terraform-authored in `iam.tf`. This catalog is runtime identity only.

Modules: `terraform-aws-modules/iam/aws//modules/iam-policy` for customer-managed policies (the Terraform section); Lambda exec policies via the lambda module's `attach_policy_statements` / `policy_statements`.

### Principles
- **Least privilege** — scope every statement to specific `Action`s and `Resource` ARNs. `Resource = "*"` is allowed **only** for actions with no resource-level permission, and must carry a `# no resource-level support` comment.
- **No long-lived keys** — GitHub pipelines assume roles via **OIDC**; humans via SSO/console. No IAM users, no access keys.
- **Roles, not users** — Lambda exec roles + (future) identity-pool roles here; pipeline/deploy roles in `/github-actions`. Never attach policies to users.
- **No permission boundaries / no inline user policies** at this scale — managed (AWS) + customer-managed (our `iam-policy`) only.

### Authoring conventions
- **Statement shape:** `{ Sid, Effect="Allow", Action=[...], Resource=[...], Condition? }`. One Sid per concern (e.g. `ReadRedisSecret`, `DataTableAccess`, `WriteOgCache`).
- **ARN scoping:** parametrize by env — `arn:aws:secretsmanager:${region}:${account}:secret:<project>/${env}/*`, `arn:aws:s3:::<project>-og-images-${env}/*`, SSM `arn:aws:ssm:${region}:${account}:parameter/${env}/*`. Use `data.aws_caller_identity`/`data.aws_region`.
- **Confused-deputy guard:** resource-based trust (Lambda@Edge, cross-service) carries `Condition.StringEquals` on `aws:SourceArn`/`aws:SourceAccount`. OIDC trust uses `StringLike` on `token.actions.githubusercontent.com:sub`.
- **Managed vs customer-managed:** lean on AWS-managed policies for boilerplate (logs, VPC ENIs, X-Ray); write a customer-managed `iam-policy` only for app-specific grants.
- **Naming:** roles `<project>-${purpose}-${env}` / `github-actions-${repo}-${env}`; policies `<project>-${purpose}-deploy-${env}`.
- **Region:** Lambda@Edge roles/policies are **global** (created in us-east-1 with the function); everything else is regional.

### AWS-managed policies we rely on
| Managed policy | Attached to | Grants |
|---|---|---|
| `AWSLambdaBasicExecutionRole` | every Lambda role | CloudWatch Logs create/put |
| `AWSLambdaVPCAccessExecutionRole` | BFF role **only when in-VPC** | ENI create/describe/delete |
| `AWSXRayDaemonWriteAccess` | BFF role | `xray:PutTraceSegments`/`PutTelemetryRecords` |

---

### Role catalog

### 1. BFF Lambda execution role
Hono BFF Lambda (the Lambda section, `/bff`). Trust = `lambda.amazonaws.com`. Managed: BasicExecution + XRayDaemonWrite (**+ VPCAccess only if the BFF is in-VPC** — it's non-VPC by default, see the Lambda section "VPC posture"). Customer-managed inline statements (via lambda module `attach_policy_statements = true`, `policy_statements = {...}`):
```hcl
policy_statements = {
  read_secrets = {                         # redis AUTH token (/secrets-manager)
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:${region}:${account}:secret:<project>/${env}/*"]
  }
  data_tables = {                          # DynamoDB data tier — pure IAM, no secret (/dynamodb)
    effect  = "Allow"
    actions = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem",
               "dynamodb:DeleteItem", "dynamodb:Query", "dynamodb:BatchGetItem"]   # no Scan in hot paths
    resources = [                          # the five per-entity tables + their GSIs — never dynamodb:* on *
      "arn:aws:dynamodb:${region}:${account}:table/<project>-*-${env}",        # <project>-<entity>-<env>
      "arn:aws:dynamodb:${region}:${account}:table/<project>-*-${env}/index/*"
    ]
  }
  read_ssm = {                             # config bus (/ssm)
    effect    = "Allow"
    actions   = ["ssm:GetParameter", "ssm:GetParametersByPath"]
    resources = ["arn:aws:ssm:${region}:${account}:parameter/${env}/*"]
  }
  og_cache = {                             # og-image PNG cache (/s3)
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::<project>-og-images-${env}/*"]
  }
  publish_events = {                       # async domain events (/sns)
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [module.sns_domain_events.topic_arn]
  }
  # metrics need NO statement — Powertools emits EMF to logs; CloudWatch extracts them (/metrics)
}
```
- **KMS:** add `kms:Decrypt` (scoped to the CMK ARN) **only** if the secret/bucket uses a CMK; AWS-managed keys need no explicit grant (the KMS section).
- **Redis:** ElastiCache uses an AUTH token (from Secrets Manager) — **no IAM data-plane permission** required.
- **SES:** if the notifications module sends mail directly, add `ses:SendEmail`/`SendRawEmail` scoped to the verified identity ARN (the SES section); if it only publishes to SNS, the `publish_events` statement suffices.

### 2. Lambda@Edge (og-edge) execution role
Replicated edge function (`/og-edge-handler`). **Dual trust** — both principals required:
```hcl
assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{
  Effect = "Allow", Action = "sts:AssumeRole",
  Principal = { Service = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"] }
}]})
```
- Managed: `AWSLambdaBasicExecutionRole` (logs land in each edge region). **No VPC** (edge functions can't be in a VPC).
- Inline: `s3:GetObject` on `arn:aws:s3:::<project>-og-images-${env}/*` (serve cached OG images). It calls the BFF's **public** routes over HTTPS — no IAM for that.
- Created in **us-east-1** (global).

### 3. Cognito trigger role (fn-cognito-groups)
Trust = `lambda.amazonaws.com`. Managed: `AWSLambdaBasicExecutionRole`. Inline — assign federated users to groups (the Cognito section), scoped to the pool ARN:
```hcl
{ effect = "Allow",
  actions = ["cognito-idp:AdminAddUserToGroup", "cognito-idp:AdminListGroupsForUser"],
  resources = ["arn:aws:cognito-idp:${region}:${account}:userpool/${pool_id}"] }
```
Non-VPC. The **admin allowlist** (which emails get `admin`) is the trigger's config, not an IAM concern.

### 4. RUM guest identity-pool role — NOT BUILT (future / only if CloudWatch RUM is added)
> We currently have **only a Cognito User Pool** (authentication — issues JWTs the SPA sends to the API GW authorizer). There is **NO identity pool** deployed. An **identity pool is a different service**: it vends **temporary AWS credentials** (via STS) so a *browser* can call AWS APIs **directly**. The only reason to add one is **CloudWatch RUM** (real-user monitoring — the browser calls `rum:PutRumEvents`). RUM is not in Phases 1-3, so this role does not exist yet.

When/if RUM lands: a Cognito **identity pool** unauthenticated (guest) role (the CloudWatch RUM section). Trust = `cognito-identity.amazonaws.com` with `Condition.StringEquals "cognito-identity.amazonaws.com:aud" = <identity_pool_id>` and `ForAnyValue:StringLike "amr" = "unauthenticated"`. Inline: `rum:PutRumEvents` scoped to the app-monitor ARN. **User-Pool-only is the default** — add an identity pool solely for a browser-direct-AWS feature like RUM.

### Pipeline/deploy roles → `/github-actions`
The iac-runner + **api/fed OIDC deploy roles** (trust = OIDC handshake; permissions = least-privilege deploy grants) are documented in `/github-actions`. Their Terraform still lives in `iam.tf` (`iam-policy` + `iam-assumable-role-with-oidc` submodules, ARNs → SSM `/{env}/iam/github-actions-{api,fed}-role-arn`), but as **pipeline** concerns they're described there, not in this runtime catalog.

### Conventions
- Role ARNs → SSM for app deploy jobs to assume at deploy (the SSM section); app deploy jobs read the env-scoped `AWS_BFF_OIDC_ROLE_ARN` / `AWS_FED_OIDC_ROLE_ARN` (environment secrets; see `/github-actions`), never a rotatable static GitHub secret.
- Key choice + encryption requirements follow the KMS section; tagging via provider `default_tags` (the Terraform section).
### Decision & trade-off
*Well-Architected pillar: **Security**.*

- **The IAM role boundary substitutes for the missing account boundary.** Because all environments share one AWS account (a cost decision — the Terraform section), IAM is the **primary** isolation mechanism, not an optional hardening. This applies to runtime roles here AND to the deploy/CI roles in `/github-actions`.
- **Least-privilege per-JOB roles:** each pipeline gets a minimal role (iac-runner may create/delete; bff-deploy may only update its Lambda code; fed-deploy may only sync its bucket + invalidate CloudFront), so a bug or compromise in one pipeline can't touch another's resources. Per-ENV roles restore the env isolation the single account gave up. *Trade-off:* more roles/policies to author and keep in sync as features change.
- The full secrets/OIDC/per-env model is in `/github-actions` — **cross-referenced, not duplicated here** (this catalog is runtime identity only).

### Pros & cons
**Pros**
- One canonical authoring catalog — no policy JSON scattered across service skills.
- Least-privilege + OIDC (no long-lived keys); per-service permission sets.
**Cons**
- The central file must stay in sync with each service's needs.
- Least-privilege requires upkeep as features change.


## KMS

*Apply the encryption posture across Terraform — the in-transit and at-rest matrix per service, AWS-managed keys versus a customer-managed CMK, key policies and rotation. Use when a resource needs encryption configured, justifying a CMK against its monthly cost, or auditing a service for unencrypted storage. Not for where secret values are kept (see secrets-manager).*

**Canonical encryption skill.** Everything is encrypted **in transit AND at rest** — no plaintext data path, no unencrypted storage. **Every service that encrypts data references this skill** for the key choice (AWS-managed vs CMK); they do not restate it.

**Mandate (no exceptions):** every service is **KMS-encrypted at rest** (AWS-managed key by default, CMK when required) **and TLS/SSL-encrypted in transit — SSL by default across the whole architecture.** No plaintext path, ever. A service skill states its mechanism and points here; it never opts out.

### Rule
Verify **both axes** for every new resource before merge. `checkov` enforces many of these (the Terraform section).

### In transit (TLS)
| Service | How | Skill |
|---|---|---|
| CloudFront | `minimum_protocol_version = "TLSv1.2_2021"`, `viewer_protocol_policy = redirect-to-https` | the CloudFront section |
| API GW (REST) | HTTPS-only custom domain (ACM); no HTTP | the API Gateway section |
| Cognito hosted UI | HTTPS (ACM, us-east-1) | the Cognito section |
| DynamoDB | reached over HTTPS via the Gateway VPC endpoint (AWS SDK TLS by default) | the DynamoDB section |
| Redis | `transit_encryption_enabled = true` + AUTH token | the ElastiCache section |
| S3 | reached only via CloudFront OAC over HTTPS; bucket policy denies `aws:SecureTransport = false` | the S3 section |

### At rest
| Service | How | Skill |
|---|---|---|
| DynamoDB | encrypted at rest by default (AWS-managed `aws/dynamodb` key) | the DynamoDB section |
| Redis | `at_rest_encryption_enabled = true` | the ElastiCache section |
| S3 artifacts | **SSE-KMS** (`aws/s3` key + bucket keys) | the S3 section |
| S3 fed + og-images | **SSE-S3 (AES256)** — CloudFront OAC can't decrypt the `aws/s3` KMS key (see note) | the S3 section |
| Secrets Manager | KMS (`aws/secretsmanager`) by default | the Secrets Manager section |
| SNS topic + SQS DLQ | `kms_master_key_id` (`aws/sns`, `aws/sqs`) | the SNS section |
| CloudWatch Logs | encrypted (CMK when required) | the CloudWatch section |
| Lambda env vars | AWS-managed Lambda key (`kms_key_arn` for a CMK) | the Lambda section |

> **No customer-KMS surface (AWS encrypts internally):** Cognito user pool, API Gateway, CloudFront, Route53, WAF, ACM — there's no key to choose; the at-rest mandate is met by AWS's own encryption. Every service that *does* expose a key surface is listed above and states its choice.

> All AWS API calls (Secrets Manager, SNS, SES, SSM, S3, STS…) are HTTPS/TLS by default — the SSL-by-default mandate holds end to end.

### Key choice — AWS-managed vs CMK
- **Default to AWS-managed keys** (`aws/s3`, `aws/secretsmanager`, `aws/dynamodb`, `aws/elasticache`) — zero key management, no extra cost, sufficient for this workload. On the Terraform side this means leaving `kms_key_id` empty/unset.
- **Use a customer-managed key (CMK)** only when you need one of: cross-account/grant control, custom rotation schedule, key-usage auditing (CloudTrail), or one shared key across resources. Provision via `terraform-aws-modules/kms/aws` (the Terraform section).
- **Rotation:** any CMK sets `enable_key_rotation = true`.
- **Least privilege:** a CMK key policy grants `kms:Decrypt`/`Encrypt`/`GenerateDataKey` only to the roles that need it (e.g. the BFF exec role for Secrets/Redis/DynamoDB data keys — the IAM section) — never `kms:*` to `*`.

### Current stance
Phase 1-3 use **AWS-managed keys** everywhere (DynamoDB, Redis, Secrets Manager, CloudWatch Logs, the artifacts S3 bucket) — **no CMK yet**. Revisit if a compliance or key-sharing requirement appears.

> **CloudFront-served buckets are the one at-rest exception — SSE-S3, not KMS.** CloudFront **OAC cannot decrypt** objects encrypted with the AWS-managed `aws/s3` KMS key: that key's policy is AWS-owned and can't grant the `cloudfront.amazonaws.com` service principal `kms:Decrypt`, so the origin 403s. So the **fed + og-images** buckets use **SSE-S3 (AES256)** (still encryption-at-rest; their content is public anyway). The KMS-preserving alternative is a **customer CMK** whose key policy grants CloudFront `kms:Decrypt` with a `Condition.StringEquals "AWS:SourceArn" = <distribution-arn>` — adopt that only if these buckets ever need KMS (it's the one case where a CMK buys something AWS-managed keys can't).

### Conventions
- Never disable encryption to avoid key setup — use the AWS-managed key.
- A service needing `kms:Decrypt` adds it to its exec-role statements **only when using a CMK** (the IAM section); with AWS-managed keys no explicit grant is needed.
- Tag CMKs via provider `default_tags` (the Terraform section).
### Decision & trade-off
*Well-Architected pillar: **Security (secondary: Cost Optimization)**.*

- **AWS-managed keys everywhere by default; no CMK in Phase 1-3.** *Why:* zero key management and **no extra key cost**, sufficient for this workload. *Traded away:* the CMK-only capabilities — custom rotation schedule, CloudTrail key-usage auditing, cross-account/grant control, one shared key. Adopt a CMK only when a compliance or key-sharing requirement actually appears (a migration at that point, not free to retrofit).
- **CloudFront-served buckets are the one at-rest exception — SSE-S3 (AES256), not KMS.** CloudFront OAC can't `kms:Decrypt` under the AWS-managed `aws/s3` key (its policy can't grant the CloudFront service principal), so SSE-KMS 403s the origin. The content is public, so AES256 is the correct stance; the KMS-preserving alternative (a CMK whose policy grants CloudFront `kms:Decrypt` scoped to the distribution `SourceArn`) is the *only* case where a CMK buys something AWS-managed keys can't.
- **S3 Bucket Keys on the KMS buckets** cut KMS API calls (cost) — kept on by default.

### Pros & cons
**Pros**
- Encryption everywhere by default (at rest + TLS); one canonical policy.
- AWS-managed keys = zero key operations and no extra key cost.
**Cons**
- AWS-managed keys lack CMK audit/rotation/cross-account control.
- Always-encrypt adds minor cost (KMS calls; mitigated by S3 bucket keys); moving to CMK later is a migration.


## Secrets Manager

*Provision secrets in Secrets Manager with Terraform — naming, jsonencode for structured values, third-party secrets created out of band, and publishing only the ARN so a plaintext value never reaches a function's environment or Terraform state. Use when a workload needs a credential, registering an out-of-band secret, or keeping a value out of state. Not for fetching it at runtime (see secrets-management) or non-sensitive config (see ssm).*

This is the **provisioning** (IaC) side. The runtime **consumption** side is `/secrets-management`.

### What & how
- Every sensitive value lives here — never in SSM plain text, tfvars, or code.
- Naming: `<project>/{env}/{component}` (e.g. `…/redis`).
- Value is `jsonencode({...})` with **snake_case** fields (`auth_token`, `username`, `password`, `host`, `port`, `dbname`).

```hcl
resource "aws_secretsmanager_secret" "x" {
  name                    = "<project>/${var.environment}/x"
  recovery_window_in_days = var.environment == "production" ? 7 : 0
}
resource "aws_secretsmanager_secret_version" "x" {
  secret_id     = aws_secretsmanager_secret.x.id
  secret_string = jsonencode({ /* snake_case fields */ })
}
# publish only the ARN to SSM / Lambda env — never the value
```

### Out-of-band (third-party) secrets

Credentials **issued by a third party** (Google OAuth client, Giphy/Stripe/… API keys) are **not** created
by a `aws_secretsmanager_secret` resource — the value originates outside AWS. Create the secret **out-of-band**
(console or `aws secretsmanager create-secret`, one per env, same `<project>/{env}/{component}` naming) and
have Terraform only **reference** it via a data source:

```hcl
# ARN only — when a Lambda fetches the value at runtime (/secrets-management). Preferred.
data "aws_secretsmanager_secret" "giphy" { name = "<project>/${var.environment}/giphy-api-key" }
# → env = data.aws_secretsmanager_secret.giphy.arn ; Lambda role gets GetSecretValue on <project>/{env}/*

# Value — ONLY when Terraform itself consumes it (e.g. an OAuth client wired into Cognito), never to
# hand a plaintext secret to a Lambda env. Reading the value pulls it into TF state.
data "aws_secretsmanager_secret_version" "google_oauth" { secret_id = "<project>/${var.environment}/google-oauth" }
```

**Every out-of-band secret MUST be documented as a prerequisite in the consuming repo's README**
(how to obtain it + the `create-secret` command + JSON shape) — `terraform apply` fails with
`ResourceNotFoundException` if it doesn't already exist for that environment, and there's no resource in
code to hint at it. Create the **production** copy before promoting to prod.

### Conventions
- Encrypted with the **AWS-managed key** by default (the KMS section); CMK only if cross-account/audit is needed.
- Only the **ARN** is non-sensitive (fine in env var / SSM). The Lambda role gets `secretsmanager:GetSecretValue` scoped to `<project>/{env}/*` (the IAM section).
- Provisioned today: Redis AUTH (the ElastiCache section, TF-created); out-of-band third-party keys — the Google OAuth client (→ Cognito) and the Giphy API key (→ BFF GIF-search proxy); any future API keys/tokens as needed. (The DynamoDB data tier needs **no secret** — access is pure IAM, the DynamoDB section. The Cognito app client is public/PKCE — no client secret; the BFF keeps no session — `/bff`.)

### Path structure & naming
Same shape as the SSM config bus (the SSM section) — first levels make ownership obvious. Secret name: `<project>/{env}/{component}`
- **L1 `<project>`** — workload slug. **L2 `{env}`** — `staging` | `production` (hard isolation; never shared across envs). **L3 `{component}`** — the owning area (`redis`, …); one secret per component, its JSON holds the fields.
- Only the **ARN** (`arn:aws:secretsmanager:{region}:{account}:secret:<project>/{env}/{component}-*`) is non-sensitive → goes to SSM / Lambda env. The Lambda role is scoped to `<project>/{env}/*` (the IAM section).

### Pros & cons
**Pros**
- Native rotation hooks, fine-grained IAM, and access auditing.
- Only ARNs leave the boundary — the value never lands in SSM/tfvars/code.
**Cons**
- ~$0.40/secret/month vs free SSM.
- One more service to reason about than plain env vars.


## SSM

*Publish non-sensitive configuration to SSM Parameter Store with Terraform as a cross-repo config bus — the path namespace, which component owns which parameter, and how deploy jobs read them. Use when infrastructure must hand a value to an application repo, naming a parameter, or deciding a value is not sensitive enough to need more. Not for sensitive values (see secrets-manager) or how an application reads them (see environment-config).*

SSM Parameter Store is how IaC publishes non-sensitive infra outputs for the **application deploy jobs** (the API's and the SPA's, wherever they live) to read at deploy time — the single source of truth, no GitHub secret to rotate. Secrets stay in Secrets Manager (the Secrets Manager section).

The bus is defined by **producer and consumer roles, not by repository layout**: one writer (the IaC that owns the resource) and any number of readers. That is deliberately independent of whether the apps are one monorepo, several repos or a single repo with the IaC beside them — the parameter path is the contract, so changing the layout never changes the wiring.

### Path structure & naming
Same idea as the log-path convention (the CloudWatch section): the **first levels make ownership obvious at a glance**. Shape:

`/{env}/{component}/{name}`
- **L1 `{env}`** — environment scope: `staging` | `production` (matches `var.environment`). A hard isolation boundary — no parameter is shared across environments.
- **L2 `{component}`** — the workload area that **owns** the value: `frontend` · `api` · `auth` · `data` · `cache` · `storage` · `iam` · `events`. Names the producer/consumer at a glance.
- **L3 `{name}`** — the specific parameter, **kebab-case**, descriptive (`cloudfront-distribution-id`, `bff-function-name`).

Rules: type **`String`** only (never `SecureString` — runtime secrets live in Secrets Manager); values are ARNs / ids / endpoints / names, never sensitive material; one value per parameter; **IaC writes, the application deploy jobs read**.

### Parameters by component
| Component | Parameters |
|---|---|
| `frontend` | `s3-bucket-name`, `cloudfront-distribution-id`, `ga-measurement-id`, `rum-app-monitor-id`, `rum-identity-pool-id` |
| `api` | `gateway-url`, `gateway-id`, `bff-function-name`, `lambda-edge-og-qualified-arn` |
| `auth` | `cognito-user-pool-id`, `cognito-client-id`, `cognito-domain`, `cognito-hosted-ui-url`, `waf-regional-arn` |
| `data` | `profile-table-name`, `posts-table-name`, `articles-table-name`, `subscriptions-table-name`, `audits-table-name` *(DynamoDB table names — access is pure IAM, no secret)* |
| `cache` | `redis-endpoint` *(AUTH token stays in Secrets Manager)* |
| `storage` | `artifacts-bucket-name`, `og-images-bucket-name` |
| `iam` | `github-actions-api-role-arn`, `github-actions-fed-role-arn` |
| `events` | `topic-arn` *(SNS domain events — the SNS section)* |

### What stays in Secrets Manager (sensitive)
- `<project>/{env}/redis` — auth_token.
- *(DynamoDB has no secret — access is pure IAM on the table ARNs, the IAM section.)*
- Never store passwords/tokens in SSM (even SecureString) — only the **ARN** of the secret goes in SSM.

### How the app deploy jobs read at deploy (GitHub Actions)
```bash
S3_BUCKET=$(aws ssm get-parameter --name /$ENV_NAME/storage/artifacts-bucket-name --query 'Parameter.Value' --output text)
```
Every `aws_ssm_parameter` in IaC writes the corresponding module output; the application deploy jobs only read.

### Rationale
Non-sensitive infra outputs in SSM Standard String (free); secrets in Secrets Manager. IaC is the single source of truth — the application deploy jobs read current values at deploy with no GitHub secret to rotate. Access is HTTPS/TLS by default (the KMS section).
### Decision & trade-off
*Well-Architected pillar: **Operational Excellence**.*

- **SSM is the config bus between workloads — NO `terraform_remote_state`.** Cross-repo wiring (shared infra → app workloads) is an **acyclic DAG**: a producer writes a parameter, consumers read it at deploy. *Why over remote state:* it **decouples the repos** — the shared side never references app resources, so apply order is simply shared→app (destroy app→shared), and neither repo's state depends on the other's internals.
- *Trade-off:* the coupling is **eventual / ordering-sensitive** — a consumer reads whatever value exists at deploy time, so the producer must be applied first, and a changed value needs a consumer redeploy to take effect (reads are eventually consistent).
- **String only, never SecureString.** Values are non-sensitive ids/ARNs/endpoints/names; secrets live in Secrets Manager and only their **ARN** is published here. Keeps the bus free (Standard tier) and out of the rotation surface.

### Pros & cons
**Pros**
- Free config bus; IaC is the single source of truth; no GitHub secret to rotate.
- Clear `env/component/name` paths make ownership obvious.
**Cons**
- Not for secrets (Secrets Manager handles those).
- App reads at deploy — a changed value needs a redeploy; reads are eventually consistent.


## Cognito

*Provision Cognito in Terraform — a user pool with a social-only Google identity provider, a public PKCE client, groups assigned by a trigger function, a custom hosted-UI domain and its Route53 alias. Use when standing up authentication, adding an identity provider, or getting group claims into tokens. Not for consuming the session in a client (see authentication) or the server-side permission model (see action-types).*

Module: **`lgallard/cognito-user-pool/aws`** (auth.tf) — there is **no** official `terraform-aws-modules` Cognito module, so we use lgallard, the established community one (the Terraform section module policy). Cognito issues the JWT the API GW authorizer validates; the SPA holds it via the Cognito SDK / Amplify (`/authentication`).

### Identity model — social-only (Google), two profiles
- **Sign-in is social-only via Google** — no native username/password. Native self-signup is **disabled**; users are auto-provisioned on first Google login (federation). *Trade-off:* lower friction + no password to store/leak, but a hard dependency on Google and **no email/password fallback**. (Other IdPs are drop-in — see "Adding providers".)
- **Two authenticated profiles (groups):** `admin` + `registered`. **Public = unauthenticated** (no group — every public GET needs no auth). Group assignment is automatic via a Cognito trigger (below).
- **MFA: OFF in Cognito.** For federated users Cognito does **not** apply its own MFA — the second factor is the **IdP's** (enable 2FA on the admin's Google account). *Trade-off:* MFA isn't centrally controlled; if native users are ever added, switch MFA back to TOTP.

### Configuration — user pool + Google IdP + client + custom domain
```hcl
# The Google OAuth client_secret lives in Secrets Manager (out-of-band; the client_id is non-secret).
data "aws_secretsmanager_secret_version" "google_oauth" { secret_id = "<project>/${var.environment}/google-oauth" }

module "cognito" {
  source  = "lgallard/cognito-user-pool/aws"
  version = "~> 0.31"

  user_pool_name           = "<project>-${var.environment}"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  mfa_configuration        = "OFF"                                    # federated → MFA at the IdP (Google 2FA)
  admin_create_user_config = { allow_admin_create_user_only = true } # NO native self-signup; federation provisions users

  # Threat protection (adaptive auth + leaked-credential checks) — ENFORCED. Requires the Plus feature tier (~$0.05/MAU).
  user_pool_add_ons = { advanced_security_mode = "ENFORCED" }

  # Email via the verified SES domain identity (no 50/day cap, branded from-address) — /ses
  email_configuration = {
    email_sending_account = "DEVELOPER"
    from_email_address    = "no-reply@${local.frontend_host}"
    source_arn            = "arn:aws:ses:${var.aws_region}:${local.account}:identity/${local.frontend_host}"
  }

  # captured attributes — email (verified by Google) + name (mapped from the IdP below)
  schemas = [
    { name = "email", attribute_data_type = "String", required = true,  mutable = true },
    { name = "name",  attribute_data_type = "String", required = false, mutable = true },
  ]

  user_groups = [{ name = "admin", precedence = 1 }, { name = "registered", precedence = 10 }]

  # Google as the (only) identity provider — social-only
  identity_providers = [{
    provider_name     = "Google"
    provider_type     = "Google"
    authorize_scopes  = "openid email profile"
    client_id         = var.google_client_id
    client_secret     = jsondecode(data.aws_secretsmanager_secret_version.google_oauth.secret_string)["client_secret"]
    attribute_mapping = { email = "email", name = "name", username = "sub" }
  }]

  # Cognito trigger Lambda — group assignment + claims (/lambda)
  lambda_config = {
    post_authentication  = module.fn_cognito_groups.lambda_function_arn  # assign 'registered' (+ 'admin' by allowlist)
    pre_token_generation = module.fn_cognito_groups.lambda_function_arn  # ensure cognito:groups in the first token
  }

  # single PUBLIC SPA client — PKCE, Google-only
  client_name                                 = "spa"
  client_generate_secret                      = false
  client_allowed_oauth_flows                  = ["code"]            # Authorization Code + PKCE
  client_allowed_oauth_flows_user_pool_client = true
  client_allowed_oauth_scopes                 = ["openid", "email", "profile"]
  client_callback_urls                        = var.callback_urls
  client_logout_urls                          = var.logout_urls
  client_supported_identity_providers         = ["Google"]         # NOT "COGNITO" → login is Google-only
  client_explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
  # token validity: defaults (access/id 60min, refresh 30d) — tune client_*_token_validity to change

  domain                 = var.auth_domain_name               # auth.{env}.<apex-domain>
  domain_certificate_arn = data.aws_acm_certificate.main.arn  # ISSUED cert in us-east-1 (/acm)
}
```
**Key knobs:** social-only (`client_supported_identity_providers=["Google"]`, no `"COGNITO"`); MFA `OFF` (federated); advanced security **ENFORCED** (Plus tier); **SES** email; PKCE public client; custom hosted-UI domain (us-east-1 ISSUED cert).

### Group assignment — the Cognito trigger (`fn-cognito-groups`)
Federated users aren't auto-grouped, so a small Lambda does it (the Lambda section):
- **post-authentication:** add the user to `registered`; if the email is in the **admin allowlist** (`var.admin_emails`), also add to `admin`. Idempotent (`AdminAddUserToGroup` no-ops if already a member).
- **pre-token-generation:** post-auth runs *after* the token is built, so to land the group in the **first** token, inject/ensure the `cognito:groups` claim here.
- Exec role: `cognito-idp:AdminAddUserToGroup` + `AdminListGroupsForUser` scoped to the pool ARN (the IAM section).
*Why a Lambda:* Cognito has no declarative "federated → group" rule; the trigger is the supported mechanism. The **admin allowlist** is the single source of truth for who's admin — never hand-edit group membership.

### Hosted UI — custom branding
Use **managed login branding** (logo + brand colors), not the default. The sign-in screen shows **"Continue with Google"** as the only action. *Trade-off:* needs brand assets + a branding config; the plain managed login is zero-effort if branding slips.

### Adding providers later (drop-in)
Each = an extra `identity_providers` entry + its name in `client_supported_identity_providers`; each needs an OAuth app registered with that provider (client id/secret → Secrets Manager), redirect `https://{auth_domain}/oauth2/idpresponse`:
- **Native** (`provider_type` = the name): Google (have), Apple (Apple Developer + signing key), Facebook, Amazon.
- **OIDC** (`provider_type="OIDC"` + issuer/endpoints): Microsoft/Entra (consumer + work), LinkedIn, GitHub, GitLab, …
- **SAML:** enterprise IdPs (Okta, Entra SAML) — B2B, not a consumer audience.

### Auth is external to the BFF
The **SPA runs the Authorization Code + PKCE flow via the Cognito SDK / Amplify** and holds/refreshes the JWT; it sends `Authorization: Bearer` to the API GW, whose **Cognito JWT authorizer** validates per route (the API Gateway section). The **BFF has no auth code** — it only reads claims. No client secret exists (public client).

### Route53 alias + SSM (auth.tf)
```hcl
resource "aws_route53_record" "auth" {                       # /route53
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.auth_domain_name
  type    = "A"
  alias { name = module.cognito.domain_cloudfront_distribution            # lgallard output
          zone_id = "Z2FDTNDATAQYW2", evaluate_target_health = false }
}
# SSM (/ssm): /{env}/auth/cognito-user-pool-id, cognito-client-id, cognito-domain,
#   cognito-hosted-ui-url = https://{auth_domain_name}  (custom domain — the standard)
```

### Conventions
- **Profiles:** public (no auth, no group) / `registered` (any Google sign-in) / `admin` (email allowlist). REGIONAL WAF fronts the hosted UI (the WAF section).
- The Google **client_secret** lives in Secrets Manager (`<project>/${env}/google-oauth`), provisioned out-of-band; only the non-secret **client_id** is a tfvar. The owner creates the Google OAuth client + provides them.
- Pool/client ids → SSM for app repos; the SPA reads them at build (`/environment-config`).
- New environment → its own pool + custom domain + its own Google OAuth client (distinct redirect host).

### Decision & trade-off
*Well-Architected pillar: **Security**.*

- **Social-only (federated) auth.** Lower friction, no password to store/leak; *trade-off:* a hard dependency on the IdP (Google) with no email/password fallback. MFA is delegated to the IdP (Cognito MFA is `OFF` for federated users).
- **PLUS tier with threat protection ENFORCED is a deliberately accepted cost.** Threat protection (adaptive auth + leaked-credential checks) requires the PLUS tier (~$0.05/MAU) — chosen over the free ESSENTIALS tier, **traded for the security posture** (part of what compensates for the cost-driven single-account/non-VPC choices). *Note:* the leaked-credential check doesn't apply to federated users (no stored password); adaptive auth still does.
- **Cognito is workload-specific** (a pool dedicated to this app) → it lives **with the app**, not in shared infra. The shared REGIONAL WAF fronts the hosted UI, read via the SSM config bus.
- **Per-env `deletion_protection`** (ACTIVE in production, INACTIVE in staging) guards the real user pool while keeping staging freely recreatable. The **custom hosted-UI domain is stable across pool recreation**, so the Google OAuth redirect URI never has to change.

### Pros & cons
**Pros**
- No passwords (social-only) — nothing to leak/rotate; low signup friction; MFA delegated to Google.
- Native API GW JWT authorizer + hosted UI; SES email; adaptive auth (threat protection ENFORCED).
**Cons**
- Hard dependency on Google (no email/password fallback); federated users need a trigger for groups.
- Threat protection costs per-MAU (Plus tier), and its leaked-credential check doesn't apply to federated (no stored password) — only adaptive auth does.
- AWS lock-in; less UI flexibility than Auth0.


## WAF

*Provision WAF WebACLs in Terraform in both scopes — CLOUDFRONT in us-east-1 for the distribution, and REGIONAL shared by an API Gateway stage and the Cognito hosted UI — with managed rule groups, rate limiting and logging. Use when adding request filtering, tuning a rule that blocks legitimate traffic, or checking OWASP coverage. Not for the distribution it attaches to (see cloudfront).*

Two WebACLs via **`cloudposse/waf/aws ~> 1.0`** (the Terraform section), split by ownership:
- **REGIONAL** (shared) lives in **`<project>-iac`** — the shared regional WAF baseline. Its ARN is **published to SSM** (`/{env}/auth/waf-regional-arn`) for workloads to consume; the `<project>-pwa/iac` deploy reads that SSM value to associate the REST API stage + Cognito hosted UI.
- **CLOUDFRONT** (the SPA WebACL) lives in **`<project>-pwa/iac`**, defined alongside the CloudFront distribution it protects.

CLOUDFRONT scope **must** use the us-east-1 provider alias. Inputs below follow the module's schema.

### Common knobs (both WebACLs)
```hcl
default_action = "allow"                              # allow unless a rule blocks (block-listing model)
visibility_config = {                                 # CloudWatch metrics + sampled requests for tuning
  cloudwatch_metrics_enabled = true
  sampled_requests_enabled   = true
  metric_name                = "<project>-${scope}-${var.environment}"
}
# rate limiting — blunt DoS / brute-force guard (limit + key nest inside `statement`)
rate_based_statement_rules = [
  { name = "rate-limit", priority = 10, action = "block",
    statement = { limit = 2000, aggregate_key_type = "IP" } }
]
# logging → the AWS-mandated `aws-waf-logs-` group (/cloudwatch)
logging_enabled         = true
log_destination_configs = [aws_cloudwatch_log_group.waf.arn]   # name MUST start with aws-waf-logs-
```

### CLOUDFRONT scope (`<project>-pwa/iac`, frontend.tf) — us-east-1
```hcl
module "waf_cloudfront" {
  source    = "cloudposse/waf/aws"
  version   = "~> 1.0"
  providers = { aws = aws.us_east_1 }                # CLOUDFRONT scope requires us-east-1
  name      = "<project>-cloudfront-${var.environment}"
  scope     = "CLOUDFRONT"
  default_action = "allow"
  managed_rule_group_statement_rules = [
    { name = "common", priority = 1, override_action = "none",
      statement = { name = "AWSManagedRulesCommonRuleSet", vendor_name = "AWS" } }
  ]
  # + visibility_config, rate_based_statement_rules, logging (above)
}
# attached to CloudFront via web_acl_id = module.waf_cloudfront.web_acl_arn
```

### REGIONAL scope (`<project>-iac`, shared) — associated to API GW (REST) stage + Cognito hosted UI
```hcl
module "waf_regional" {
  source  = "cloudposse/waf/aws"
  version = "~> 1.0"
  name    = "<project>-regional-${var.environment}"
  scope   = "REGIONAL"
  default_action = "allow"
  managed_rule_group_statement_rules = [
    { name = "common",         priority = 1, override_action = "none",
      statement = { name = "AWSManagedRulesCommonRuleSet",         vendor_name = "AWS" } },
    { name = "known-bad",      priority = 2, override_action = "none",
      statement = { name = "AWSManagedRulesKnownBadInputsRuleSet", vendor_name = "AWS" } }
  ]
  # + visibility_config, rate_based_statement_rules, logging (above)
}
```
**Choices that matter:** `default_action="allow"` (we block-list via rules, not allow-list); `override_action="none"` per managed group = the group's rules **block** (use `"count"` to tune a noisy group without blocking); rate-limit 2000 req / 5 min / IP; metrics + sampled requests on for tuning; REGIONAL adds KnownBadInputs on top of Common.

The REGIONAL WAF is **shared** by the **REST API stage** (the API Gateway section) and the **Cognito hosted UI**. WAFv2 REGIONAL associates with API Gateway **REST (v1)**, ALB, AppSync, Cognito user pools, App Runner — note it does **not** support API Gateway **v2 (HTTP APIs)**; using a REST API is partly what makes this per-IP protection on the API possible.

### Associations (raw — no native WAF attribute on these resources)
```hcl
resource "aws_wafv2_web_acl_association" "cognito" {     # auth.tf — Cognito hosted UI (open self-signup)
  resource_arn = module.cognito.arn                      # lgallard user-pool ARN output
  web_acl_arn  = module.waf_regional.arn
}
resource "aws_wafv2_web_acl_association" "api_gw" {       # api.tf — REST API stage (WAF-associable)
  resource_arn = aws_api_gateway_stage.this.arn
  web_acl_arn  = module.waf_regional.arn
}
```

### Notes
- CLOUDFRONT WAF (in `<project>-pwa/iac`) protects the SPA distribution; the REGIONAL WAF (in `<project>-iac`) is **shared** by the REST API stage + the Cognito hosted UI (mitigates abuse on open signup + the public API surface).
- SSM: `<project>-iac` publishes `/{env}/auth/waf-regional-arn = module.waf_regional.arn`; the `<project>-pwa/iac` deploy reads it to associate the API GW stage + Cognito user pool.
- Logs go to an `aws-waf-logs-<project>-${env}` group (mandated prefix — the CloudWatch section); WAF holds no at-rest data of its own. TLS is terminated at CloudFront / API GW, which enforce TLS 1.2+ (the KMS section).
- `aws_wafv2_web_acl_association` is justified raw glue — no module abstracts the stage/user-pool association.

### Managed rules & OWASP coverage
**Use AWS managed rule groups wherever possible** — AWS maintains the signatures, minimizing our operational overhead (no custom-rule upkeep). The chosen groups give **baseline OWASP Top 10-aligned coverage**:
- **`AWSManagedRulesCommonRuleSet`** (both scopes) — core protections across common OWASP categories (XSS, LFI/RFI, oversized payloads, bad bots).
- **`AWSManagedRulesKnownBadInputsRuleSet`** (REGIONAL) — known-exploit / SSRF / Log4j-style inputs.
- **Optional add-ons** per surface: `AWSManagedRulesSQLiRuleSet` (SQLi — for rich API query input), `AWSManagedRulesAmazonIpReputationList`, `AWSManagedRulesAnonymousIpList`.
Write a custom rule **only** when no managed group covers the need; tune a noisy managed rule with `override_action="count"` rather than replacing it.

### Decision & trade-off
*Well-Architected pillar: **Security (secondary: Cost Optimization)**.*

- **The shared-vs-workload split is a COST decision.** A WAF web ACL costs ~$5/mo + ~$1/rule/mo + ~$0.60/M requests. Provisioning **one** shared REGIONAL WAF (in `<project>-iac`) and reusing it across workloads (API GW stages, Cognito hosted UIs) via the SSM config bus **avoids duplicating that cost per workload** — which is exactly why "reusable security baseline → shared repo" is the dividing line.
- **Workload-bound WAFs live with the workload.** The CLOUDFRONT WAF is defined alongside the SPA distribution it protects (`<project>-pwa/iac`), because it is specific to that distribution, not a reusable baseline.
- **WAF is kept despite the cost (security posture).** It is a deliberate defensible-posture investment, not cut for cost — part of what compensates for the single-account / non-VPC cost choices made elsewhere.
- *Trade-off:* one shared REGIONAL WebACL means the REST API and Cognito hosted UI can't be tuned independently; the managed-rule + rate-limit baseline is less precise than hand-written rules (the rate limit is the backstop for novel attacks).

### Pros & cons
**Pros**
- AWS-maintained managed rule groups + rate limit — OWASP-ish coverage for free.
- `default_action=allow` (block-list) doesn't break legitimate traffic.
- One CLOUDFRONT + one REGIONAL WebACL (SPA edge + REST API stage + Cognito hosted UI) — managed rules, low upkeep.
**Cons**
- Less precise than hand-written rules.
- A novel attack not matched by a rule passes (rate limit is the backstop).
- One shared REGIONAL WebACL for the REST API + Cognito — can't tune those surfaces independently.


## DynamoDB

*Provision and use DynamoDB end to end — per-entity tables in Terraform rather than single-table design, on-demand billing, GSIs, PITR and TTL, the IAM grant that turns a Scan into a runtime failure, the client singleton, key and sparse-GSI queries, and cursor pagination over LastEvaluatedKey. Use when adding a table or index, replacing a Scan, choosing a billing mode, or paginating a list endpoint. Not for the cache tier beside it (see redis-cache, elasticache).*

**One skill, both sides**, because in DynamoDB they are not separable: the access pattern decides the
key schema, the key schema is declared in Terraform, and the IAM grant written beside the table is what
makes a wrong query fail at runtime rather than merely run slowly. Provisioning module:
**`terraform-aws-modules/dynamodb-table/aws ~> 4.0`** (one call per table). DynamoDB replaces DocumentDB
here — chosen for cost: **on-demand (`PAY_PER_REQUEST`) is ~$0 at idle**, where a DocumentDB cluster is
a fixed ~$54/mo always-on instance that spiky, low-volume traffic cannot justify.

### Per-entity tables (not single-table)

One table per entity — maps 1:1 to the domain aggregates, each evolves independently, and on-demand
makes the extra tables free at rest. Single-table design is the at-scale DynamoDB pattern; a workload
of this size does not need its modeling complexity.

**Entity names are always English** — the table, its hash/range keys, GSI partition values, and the
matching TS type/repository all use the English domain noun (`polls`/`poll_id`/`gsi_pk="POLL"`, never a
localized spelling), **even when the product surface is in another language** (the UI label can be
translated; the data entity stays `polls`). This keeps the schema, code, IAM ARNs, and parameter-store
keys in one language and consistent with the snake_case-everywhere rule. Why English: the AWS/TS
ecosystem and most contributors default to it, and mixing languages in identifiers is the kind of drift
that is expensive to undo once tables exist (rename = new table + backfill). The repository and TS type
names follow the table, not the UI.

| Table | Hash / Range | GSIs | Purpose |
|---|---|---|---|
| `profile` | `profile_id` | — | the CV document (effectively one item) |
| `posts` | `post_id` | `by-created` (`gsi_pk`="POST" / `created_at`) | feed, newest-first via cursor |
| `articles` | `article_id` | `by-slug` (`slug`), `by-tag` (`tag` / `created_at`) | slug routing + tag queries |
| `subscriptions` | `email` | `by-status` (`status` / `email`), `by-cognito` (`cognito_sub`) | newsletter opt-ins |
| `audits` | `audit_id` | `by-entity` (`entity` / `created_at`), `by-actor` (`actor` / `created_at`) | audit trail (`/audit-middleware`) |

Feed ordering uses a GSI with a **constant partition** (`gsi_pk="POST"`) + `created_at` range so a
single `Query` returns newest-first; fine at this scale (revisit if a single partition gets hot).

### Table configuration (the arguments set on every table)

```hcl
module "posts_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 4.0"

  name         = "<project>-posts-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"            # on-demand — ~$0 idle, no capacity planning

  hash_key  = "post_id"
  attributes = [
    { name = "post_id",    type = "S" },
    { name = "gsi_pk",     type = "S" },
    { name = "created_at", type = "S" },
  ]
  global_secondary_indexes = [{
    name            = "by-created"
    hash_key        = "gsi_pk"
    range_key       = "created_at"
    projection_type = "ALL"
  }]

  # encryption at rest — AWS-managed aws/dynamodb KMS key ("" CMK = managed; /kms)
  server_side_encryption_enabled     = true
  server_side_encryption_kms_key_arn = null

  # continuous backups / restore
  point_in_time_recovery_enabled = true

  deletion_protection_enabled = var.environment == "production"
}
```

**Choices that matter:** `PAY_PER_REQUEST` (the whole reason for the pivot — no idle cost, no RCU/WCU
planning); **per-entity tables**; GSIs `projection_type = "ALL"` (read-through without a second fetch —
storage is cheap at this volume); **PITR on** (continuous backup, 35-day window, restore = new table);
`deletion_protection` gated on env.

**Only key attributes are declared.** DynamoDB is **schemaless except for keys**, so `attributes` lists
exactly the table and GSI keys and nothing else — the rest of the aggregate is just stored. This is the
seam between the two halves of this skill: adding a field is a code-only change, adding a *query* is a
Terraform change.

### TTL (where it applies)

```hcl
# audits table only — expire trail entries after the retention window
ttl_enabled        = true
ttl_attribute_name = "ttl"      # epoch seconds; the app sets it on write (/audit-middleware)
```

TTL is a table argument and an application obligation at once: Terraform enables it and names the
attribute, and the write path has to actually set it. Enabling it alone expires nothing.

### Access is IAM — and that is why `Scan` is a hard error, not a slow one

DynamoDB has **no master user and no connection secret**. The function's execution role gets
`dynamodb:GetItem|PutItem|UpdateItem|DeleteItem|Query|BatchGetItem` scoped to **exactly these table ARNs
plus their `/index/*`** (the IAM section) — never `dynamodb:*` on `*`, and **never `Scan`**. So
there is no Secrets Manager entry for the data tier and nothing to rotate.

The consequence is the single most useful thing to know about this pair of concerns:

> **A `Scan` does not degrade — it fails.** The role grants no `dynamodb:Scan`, so a Scan raises
> `AccessDeniedException` and surfaces as a 500. There is **no "low-volume exception"**: this exact trap
> once took a feed down, because a list endpoint Scanned a table everyone agreed was small.

A Scan would be wrong even if it were permitted — it reads the WHOLE table and filters after, so cost
and latency scale with table **size**, not with the result. The grant is what makes the rule
unavoidable instead of merely advised, and it is the reason a new query shape is a **Terraform** change:
you cannot work around a missing index in application code.

### Client singleton

```typescript
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb';

// Module-level singleton — reused across warm invocations (connection keep-alive). Never construct
// inside a handler. No connect()/secret: the SDK signs with the exec-role creds from the runtime.
const base = new DynamoDBClient({});
export const ddb = DynamoDBDocumentClient.from(base, {
  marshallOptions: { removeUndefinedValues: true },
});
```

`@aws-sdk/lib-dynamodb` (`DynamoDBDocumentClient`) marshals plain JS objects ⇄ DynamoDB attribute
types, so repositories work in snake_case JS and never touch `{ S: ... }` wire shapes.

### Table names travel through the config bus

Infrastructure writes them, the deploy job reads them, the code never spells them. Both ends of that
path are here so neither can drift:

```hcl
# infrastructure writes the names (/ssm) — non-sensitive, names only
# /${env}/data/profile-table-name       = module.profile_table.dynamodb_table_id
# /${env}/data/posts-table-name         = module.posts_table.dynamodb_table_id
# /${env}/data/articles-table-name      = module.articles_table.dynamodb_table_id
# /${env}/data/subscriptions-table-name = module.subscriptions_table.dynamodb_table_id
# /${env}/data/audits-table-name        = module.audits_table.dynamodb_table_id
```

```typescript
// the application deploy job reads them into the function environment; one accessor, no literals
export const TABLES = {
  profile:       process.env.PROFILE_TABLE!,
  posts:         process.env.POSTS_TABLE!,
  articles:      process.env.ARTICLES_TABLE!,
  subscriptions: process.env.SUBSCRIPTIONS_TABLE!,
  audits:        process.env.AUDITS_TABLE!,
} as const;
```

Repositories reference `TABLES.x` — no scattered table-name string literals in handlers, and a table
renamed in Terraform reaches the code without a code change (`/environment-config`).

### Item conventions

- **snake_case attributes** everywhere (table = TS type = JSON) — no mapping layer.
- Each table's hash key is the entity id (`profile_id`, `post_id`, `article_id`); `subscriptions` is
  keyed by `email`. Timestamps `created_at` / `updated_at` as ISO-8601 strings (sortable).
- Attributes that are not keys exist only in the code's type — see the schemaless note above.

### Queries (repository pattern, per module)

```typescript
import { GetCommand, PutCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';

// profile (single item)
await ddb.send(new GetCommand({ TableName: TABLES.profile, Key: { profile_id: 'me' } }));

// article by slug — GSI by-slug (slug is unique)
await ddb.send(new QueryCommand({
  TableName: TABLES.articles, IndexName: 'by-slug',
  KeyConditionExpression: 'slug = :s', ExpressionAttributeValues: { ':s': slug }, Limit: 1,
}));

// articles by tag, newest-first — GSI by-tag (tag / created_at)
await ddb.send(new QueryCommand({
  TableName: TABLES.articles, IndexName: 'by-tag', ScanIndexForward: false,
  KeyConditionExpression: 'tag = :t', ExpressionAttributeValues: { ':t': tag },
}));
```

**`Query`/`GetItem` only.** Every list access has a matching GSI declared in the table configuration
above. Read-heavy reads go through cache-aside (`/redis-cache`).

### "List all published, newest-first" — sparse `by-created` GSI (NOT a Scan)

The pattern used by both `posts` and `articles`, and the clearest case of the two halves meeting. A
constant partition key (`gsi_pk = "POST"` / `"ARTICLE"`) is written **only when the item should appear
in the list** (i.e. iff `published`), with `created_at` as the range key. The index is **sparse**
(drafts carry no `gsi_pk`, so they are absent), so a single `Query` returns exactly the published items,
newest-first, paginated — no Scan, no `FilterExpression`.

```typescript
// write: set the sparse key iff published; removeUndefinedValues drops it when not (→ leaves the index)
const item = { ...entity, gsi_pk: entity.published ? 'ARTICLE' : undefined };
// read: Query the sparse GSI (no Scan, no filter)
await ddb.send(new QueryCommand({
  TableName: TABLES.articles, IndexName: 'by-created', ScanIndexForward: false, Limit,
  KeyConditionExpression: 'gsi_pk = :pk', ExpressionAttributeValues: { ':pk': 'ARTICLE' },
}));
```

Adding such a GSI to an existing table is online in Terraform, but **backfill** the key on already-stored
rows (a one-off migration) or they will not appear until the next write. Sparseness is a property of the
data, not of the index declaration — nothing in the HCL says "only published", so a bug that always sets
`gsi_pk` silently publishes drafts.

### Cursor pagination (server-side — `LastEvaluatedKey`)

The opaque cursor is the base64 of DynamoDB's `LastEvaluatedKey`; feed lists use the `by-created` GSI
(constant PK + `created_at`):

```typescript
const res = await ddb.send(new QueryCommand({
  TableName: TABLES.posts, IndexName: 'by-created', ScanIndexForward: false, Limit: limit,
  KeyConditionExpression: 'gsi_pk = :p', ExpressionAttributeValues: { ':p': 'POST' },
  ExclusiveStartKey: cursor ? JSON.parse(Buffer.from(cursor, 'base64').toString()) : undefined,
}));
const next_cursor = res.LastEvaluatedKey
  ? Buffer.from(JSON.stringify(res.LastEvaluatedKey)).toString('base64') : null;
return { items: res.Items ?? [], next_cursor };   // snake_case; client side = /pagination
```

Cursor-native — `LastEvaluatedKey` is exactly a continuation token (no offset/skip, no count query).

### Writes & consistency

- **Create with a guard:** `PutCommand` + `ConditionExpression: 'attribute_not_exists(post_id)'` so a
  retry does not clobber.
- **Partial update:** `UpdateCommand` with `SET`/`REMOVE` expressions — never read-modify-write a whole
  item.
- **Optimistic concurrency** where needed: a `version` attribute + `ConditionExpression: 'version = :v'`.
- Throw `AppError`/`NotFoundError` — never return 4xx (`/error-handling`).

### Network

DynamoDB is a **regional service**. With the function non-VPC (the default), it is reached over the
**public DynamoDB endpoint with IAM** (no NAT, no VPC endpoint — there is no VPC). **When in-VPC** (e.g.
once Redis or a relational store forces a VPC), it is reached over a **Gateway VPC endpoint** (like S3)
— traffic stays on the AWS backbone, **off the NAT path** (the VPC section declares the `dynamodb`
Gateway endpoint alongside `s3`). HTTPS/TLS in transit by default either way (the KMS section).

### Gotchas

- **No `Scan`** in request paths; design a GSI instead. Each GSI costs storage + write amplification —
  add only for a real access pattern.
- Restore = launch a **new** table from PITR or a backup (no in-place restore) — update the published
  table name after, or the code keeps reading the old one.
- **Lambda@Edge cannot reach DynamoDB at low latency** — prerender/OG data is served by the regional
  API, not the edge (`/og-edge-handler`).
- A single-partition GSI (feed `gsi_pk="POST"`) is fine at this scale; shard the PK if it ever gets hot.
- Tags via provider `default_tags` (the Terraform section); encryption stance
  the KMS section (AWS-managed `aws/dynamodb` key, no CMK).

### Rationale — DynamoDB over DocumentDB (cost-driven reversal)

DocumentDB is a fixed-cost always-on cluster (~$54/mo for a small instance, before replicas/backup) —
unviable for a low, spiky workload. DynamoDB on-demand bills per request and **costs effectively nothing
at idle**, scales to zero operationally, is IAM-auth (no creds/secret/SG), and needs no VPC instance.
Trade-off: access patterns must be designed up front (no ad-hoc queries or joins); rich document
querying gives way to key+GSI access. For known patterns (profile read, feed list, article
by-slug/by-tag) that fits cleanly.

### Decision & trade-off
*Well-Architected pillar: **Cost Optimization (secondary: Performance Efficiency)**.*


- **Per-entity tables + GSIs over single-table design.** One table per domain aggregate, with a GSI per
  access pattern. *Why:* simpler mental model, each entity evolves and is capacity-isolated
  independently, and on-demand makes the extra tables free at rest. *Trade-off:* gives up single-table's
  cross-entity transactional reads and its at-scale efficiency — and there is no cross-entity
  transactional read in one call, so aggregation happens in the API's shaping layer (`/bff`).
- **On-demand (`PAY_PER_REQUEST`) over provisioned = scale-to-zero.** Bills per request, ~$0 idle, no
  RCU/WCU planning. *Trade-off:* per-request pricing is **costlier than provisioned at sustained high
  steady load** — not this traffic regime, so the trade is worth it.
- **Access patterns are fixed at design time, and the IAM grant enforces it.** Key + GSI only; a new
  query shape means a new GSI (+ possible backfill) and therefore a Terraform change, not a code
  change. *Trade-off:* no ad-hoc queries or joins — modeling rigidity in exchange for cost and latency
  that track the result, not the table. This is the one decision that cannot be taken on either side
  alone, which is why the two halves are one skill.
- **Per-entity repositories over a shared data layer; one module owns one entity's access.** Keeps the
  modular monolith clean and each entity's keys and GSIs local to the code that needs them.
  *Trade-off:* the mapping from table to repository is a convention, not something the compiler checks.
- **Cursor pagination via the opaque base64 `LastEvaluatedKey`** — the continuation token IS the cursor,
  so there is no offset/skip and no count query. *Trade-off:* no random-access "page N" jumps;
  forward/continuation paging only (the contract the client consumes — `/pagination`).

### Pros & cons

**Pros**
- On-demand = ~$0 idle, no capacity planning; scales automatically.
- IAM-auth end to end — no credentials, no Secrets Manager entry, no security group, nothing to rotate;
  a Gateway endpoint keeps traffic off NAT when in-VPC.
- Client singleton reused across invocations; snake_case items with no mapping layer.
- Cursor-native pagination (`LastEvaluatedKey`); managed PITR; encryption at rest + TLS by default.

**Cons**
- Access patterns fixed at design time — a new query shape needs a new GSI, a backfill, and an
  infrastructure deploy before the code can use it.
- No joins or ad-hoc queries; `Scan` is an anti-pattern **and** an `AccessDeniedException`.
- Per-request cost can exceed provisioned at sustained high volume (not this workload).
- Sparse-index correctness lives in application code, so infrastructure review cannot catch it.


## ElastiCache

*Provision an ElastiCache for Redis cluster in Terraform — every argument set, the AUTH token kept in Secrets Manager rather than tfvars or the parameter store, the endpoint published as non-sensitive config, and backup retention. Use when a workload needs a cache tier, rotating an AUTH token, or wiring a function to Redis. Not for the durable store (see dynamodb) or the cache-aside code (see redis-cache).*

Distributed cache (cache-aside in front of DynamoDB), in-VPC and SG-gated. Redis is a VPC-only service, so adding it **forces the BFF into a VPC** (the BFF is non-VPC by default — this is the in-VPC case). Module: **`cloudposse/elasticache-redis/aws ~> 1.0`** (the Terraform section). The application-side client lives in `/redis-cache`.

### Configuration (every argument we set)
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
  allowed_security_group_ids = [aws_security_group.lambda.id]  # inbound 6379 only from the Lambda SG

  # sizing / HA
  instance_type              = "cache.t4g.micro"               # Graviton; the floor
  cluster_size               = var.environment == "production" ? 2 : 1   # 1 primary + N-1 replicas
  cluster_mode_enabled       = false                           # single shard (no sharding need)
  automatic_failover_enabled = var.environment == "production" # requires cluster_size >= 2
  multi_az_enabled           = var.environment == "production"

  # encryption (MANDATORY — both axes; /kms)
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

  # logs → CloudWatch (/cloudwatch)
  log_delivery_configuration = [
    { destination = "/aws/elasticache/<project>-${var.environment}/slow-log",
      destination_type = "cloudwatch-logs", log_format = "json", log_type = "slow-log" },
    { destination = "/aws/elasticache/<project>-${var.environment}/engine-log",
      destination_type = "cloudwatch-logs", log_format = "json", log_type = "engine-log" }
  ]
}
resource "random_password" "redis_auth" { length = 32, special = false }
```
**Choices that matter:** Redis `7.1`/`redis7`; **single shard** (`cluster_mode_enabled=false`); HA only in prod (`automatic_failover` + `multi_az` need `cluster_size>=2`); `maxmemory-policy=allkeys-lru` (cache eviction, not a datastore); snapshots prod 7d / stg off; **encryption mandatory on both axes** — TLS + AUTH in transit, KMS at rest (AWS-managed key default, CMK per the KMS section).

### AUTH token → Secrets Manager (never SSM/tfvars)
```hcl
resource "aws_secretsmanager_secret" "redis" { name = "<project>/${var.environment}/redis" }
resource "aws_secretsmanager_secret_version" "redis" {
  secret_id     = aws_secretsmanager_secret.redis.id
  secret_string = jsonencode({ auth_token = random_password.redis_auth.result })
}
# SSM (non-sensitive): /{env}/cache/redis-endpoint = module.redis.endpoint
```

### Wire into the BFF (api.tf)
- `environment_variables`: `REDIS_ENDPOINT = module.redis.endpoint`, `REDIS_SECRET_ARN = aws_secretsmanager_secret.redis.arn`.
- Exec role: `secretsmanager:GetSecretValue` on the redis secret (the IAM section).

### Notes
- Private subnets, port 6379, reached in-VPC over the SG — off the NAT path (DynamoDB is off-NAT too, via its Gateway endpoint).
- Prod = 1 primary + 1 replica (Multi-AZ failover); staging = single node. `cache.t4g.micro` (Graviton).
- Fail-open is enforced on the application side, not by the cluster — see `/redis-cache`.
### Backup & retention
- **Daily automatic snapshots:** `snapshot_retention_limit` = **7d production / 0 (disabled) staging**, window `snapshot_window`; snapshots KMS-encrypted.
- **It's a cache, not a system of record** — DynamoDB is the source of truth, so snapshots are a warm-restart convenience, not durability. Losing the cache is safe: the BFF is fail-open and repopulates cache-aside (`/redis-cache`).
- Restore = create a replacement cluster from a snapshot, or simply let it refill on demand.
### Pros & cons
**Pros**
- In-VPC low-latency cache; managed Redis with Multi-AZ failover (prod).
- `maxmemory-policy=allkeys-lru` evicts cleanly under pressure.
**Cons**
- Fixed node cost even when idle; single-shard = vertical scaling only.
- Cache invalidation/staleness is the application's responsibility.


## S3

*Provision S3 buckets in Terraform — the shared baseline of blocked public access, ownership-enforced ACLs, encryption at rest and a bucket policy denying non-TLS access, plus per-bucket configuration for a private SPA origin behind OAC, build artifacts and a generated-image cache. Use when adding a bucket, hardening one, or wiring its policy to a distribution. Not for the distribution in front of it (see cloudfront).*

Three buckets via **`terraform-aws-modules/s3-bucket/aws ~> 4.0`** (the Terraform section). All share the same hardened baseline; only purpose-specific args differ. Exec-role access: the IAM section; encryption stance: the KMS section.

### Shared baseline (every bucket sets these)
```hcl
force_destroy = var.environment != "production"        # stg can be torn down; prod protected

# ACLs disabled — ownership-enforced (no ACLs, bucket-policy only)
control_object_ownership = true
object_ownership         = "BucketOwnerEnforced"

# public access fully blocked
block_public_acls       = true
block_public_policy     = true
ignore_public_acls      = true
restrict_public_buckets = true

# encryption at rest — SSE-KMS for non-public buckets (artifacts); SSE-S3 (AES256) for the
# CloudFront-served public buckets (fed, og-images) — see the OAC note below — /kms
server_side_encryption_configuration = {
  rule = {
    apply_server_side_encryption_by_default = { sse_algorithm = "aws:kms" }   # artifacts; fed/og use "AES256"
    bucket_key_enabled = true                          # S3 Bucket Keys — fewer KMS calls (cost)
  }
}

# deny non-TLS access (SSL/TLS in transit, mandatory)
attach_deny_insecure_transport_policy = true
```

### Bucket naming
**Every object bucket name starts with the account id** for global-namespace isolation (S3 bucket names are globally unique across all of AWS): `<account-id>-<project>-<purpose>-<env>`, with `<account-id> = data.aws_caller_identity.current.account_id`. Purposes: **`fed`** (the SPA origin), `artifacts`, `og-images`. The **fed** bucket name is **decoupled from the domain** — with CloudFront OAC the bucket is not a website endpoint, so it need not match the host (and prefixing with the account id avoids any global collision).

### Per-bucket configuration
```hcl
# 1. Frontend (fed) SPA origin — private, reached only via CloudFront OAC
module "frontend_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"; version = "~> 4.0"
  bucket    = "${data.aws_caller_identity.current.account_id}-<project>-fed-${var.environment}"   # account-id prefix → globally unique
  versioning = { enabled = true }                      # rollback safety for the site
  attach_policy = true                                 # OAC read policy (CloudFront SourceArn) — /cloudfront
  policy        = data.aws_iam_policy_document.frontend_oac.json
}

# 2. Lambda code artifacts (Pattern B bootstrap + deploy zips)
module "artifacts_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"; version = "~> 4.0"
  bucket     = "${data.aws_caller_identity.current.account_id}-<project>-artifacts-${var.environment}"
  versioning = { enabled = true }                      # keep prior bundles for rollback
  lifecycle_rule = [{ id = "expire-old-versions", enabled = true,
                      noncurrent_version_expiration = { days = 30 } }]
}

# 3. Generated OG images cache — served via the main CloudFront /og/* behavior
module "og_images_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"; version = "~> 4.0"
  bucket     = "${data.aws_caller_identity.current.account_id}-<project>-og-images-${var.environment}"
  versioning = { enabled = false }                     # regenerable cache — no versioning
  lifecycle_rule = [{ id = "expire", enabled = true, expiration = { days = 90 } }]   # purge stale OG PNGs
  attach_policy = true; policy = data.aws_iam_policy_document.og_oac.json            # CloudFront OAC read
}
```
**Choices that matter:** `BucketOwnerEnforced` (ACLs off — policy-only access); all four public-access blocks on; `versioning` on for site+artifacts (rollback) / off for the regenerable OG cache; `force_destroy` gated on env; lifecycle expiry on the OG cache (90d) and artifact old-versions (30d). **Encryption is mandatory on every bucket — at rest AND TLS/SSL in transit (deny non-TLS); never disabled.** At-rest cipher by bucket role:
- **artifacts** (not public): **SSE-KMS** (`aws/s3` key + bucket keys; CMK per the KMS section).
- **fed + og-images** (served publicly via **CloudFront OAC**): **SSE-S3 (AES256)** — *not* SSE-KMS. CloudFront OAC **cannot decrypt** objects under the AWS-managed `aws/s3` KMS key (its key policy can't grant the CloudFront service principal `kms:Decrypt`), so SSE-KMS 403s the site. The content is public, so AES256 is the correct at-rest stance. (A customer **CMK** whose key policy grants CloudFront `kms:Decrypt` (with the distribution `SourceArn` condition) is the KMS alternative — the KMS section; not used in Phase 1-3.)

### SSM outputs
```hcl
# /{env}/frontend/s3-bucket-name       = module.frontend_bucket.s3_bucket_id
# /{env}/storage/artifacts-bucket-name = module.artifacts_bucket.s3_bucket_id
# /{env}/storage/og-images-bucket-name = module.og_images_bucket.s3_bucket_id
```

### Conventions
- **frontend + og-images stay private** — CloudFront reaches them via Origin Access Control (OAC); the bucket policy allows only the distribution `aws:SourceArn` (the CloudFront section).
- **artifacts** holds `bff/bootstrap.zip` (first apply, Pattern B) + `bff/latest.zip` / `og-edge/latest.zip` (deploy `update-function-code`) — the Lambda section, `/github-actions`.
- **og-images** is written by the og-image module (`s3:PutObject`, key `/{type}/{slug}.png`) and read by the `/og/*` behavior (`/og-image-generator`).

### Pros & cons
**Pros**
- SSE-KMS + bucket keys: meets the KMS mandate with CloudTrail visibility at low extra cost.
- Private buckets + CloudFront OAC — nothing is publicly reachable.
- Versioning where it matters (site/artifacts), off on the regenerable OG cache.
**Cons**
- KMS is slightly costlier/more complex than SSE-S3 (AES256).
- OAC wiring is more setup than a one-line public website bucket.
- Versioning carries a storage cost.


## Lambda

*Provision Lambda functions in Terraform — nodejs22 on arm64, non-VPC by default with in-VPC as a deliberate security versus cost call, Pattern B where infrastructure owns config and the app ships code, tracing and encryption. Use when adding a function, deciding its VPC posture, or wiring its environment and role. Not for the execution role's policy (see iam) or the handler code inside it (see lambda-handler).*

Module: `terraform-aws-modules/lambda/aws ~> 7.0` (the Terraform section). The deployable set is **one BFF Lambda** (modular monolith — API GW fronts only it) **+ og-edge** (Lambda@Edge, separate) **+ fn-cognito-groups** (a small Cognito trigger that assigns federated users to `registered`/`admin` — the Cognito section). Exec-role permissions: the IAM section. The BFF config below is the canonical example; the others reuse the same module + Pattern-B/non-VPC choices.

### Configuration — the BFF Lambda (api.tf)
```hcl
module "bff" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  function_name = "<project>-bff-${var.environment}"
  handler       = "index.handler"
  runtime       = "nodejs22.x"
  architectures = ["arm64"]          # Graviton — ~20% cheaper, equal/better Node perf
  timeout       = 29                 # API GW max
  memory_size   = 256                # bundles satori/resvg (OG image module)
  tracing_mode  = "Active"           # X-Ray (/cloudwatch-xray)

  # Pattern B — IaC owns config, the app pipeline ships code (module built-in)
  create_package          = false
  ignore_source_code_hash = true
  s3_existing_package     = { bucket = module.artifacts_bucket.s3_bucket_id, key = "bff/bootstrap.zip" }

  # NON-VPC by default — see "VPC decision" below. (Add only when an in-VPC dependency like Redis lands:
  #   vpc_subnet_ids = module.vpc.private_subnets
  #   vpc_security_group_ids = [aws_security_group.lambda.id]
  #   attach_network_policy = true )  # AWSLambdaVPCAccessExecutionRole (ENIs)

  environment_variables = {          # non-secret config + table names + secret ARNs (/environment-config)
    ENVIRONMENT = var.environment, LOG_LEVEL = "INFO", POWERTOOLS_SERVICE_NAME = "bff",
    PROFILE_TABLE_NAME = module.profile_table.dynamodb_table_id,            # DynamoDB tables (pure IAM, no secret)
    POSTS_TABLE_NAME = module.posts_table.dynamodb_table_id,
    ARTICLES_TABLE_NAME = module.articles_table.dynamodb_table_id,
    SUBSCRIPTIONS_TABLE_NAME = module.subscriptions_table.dynamodb_table_id,
    AUDITS_TABLE_NAME = module.audits_table.dynamodb_table_id,
    OG_IMAGES_BUCKET = module.og_images_bucket.s3_bucket_id,
    # REDIS_ENDPOINT / REDIS_SECRET_ARN / SNS_TOPIC_ARN added when those components land (Redis forces in-VPC).
  }

  # least-privilege exec role — statements defined in /iam (BFF role)
  attach_policy_statements = true
  policy_statements        = local.bff_policy_statements
}
```
**Key knobs:** `architectures=["arm64"]` always; `timeout=29` (API GW ceiling); `memory_size=256` (OG image deps); `tracing_mode="Active"`; **VPC posture is an owner choice** (see below). Provisioned concurrency: **none** (cost). Never `Resource="*"` policies — see the IAM section.

### VPC posture — a security × cost decision (ASK the owner; can differ per env)
This is **not** a fixed default — it's a deliberate trade-off the owner picks (per the project's "no solo architectural decisions" rule), and it may differ per environment (e.g. non-VPC staging for cost, in-VPC production for posture). Present both:

**Option A — Non-VPC** (Lambda on AWS-managed networking)
- *Cost/perf (pro):* **no NAT Gateway** (~$33/mo per env, ~$66/mo prod one-per-AZ) and **faster cold starts** (no ENI attach).
- *Security (con):* egress goes straight to AWS **service endpoints** (still IAM-auth'd + TLS; Lambda has no inbound either way) — but **no private-subnet isolation, no SG egress control, no VPC flow logs** for the function. Cannot reach VPC-only resources.
- *Mechanics:* omit `vpc_subnet_ids`/`vpc_security_group_ids`/`attach_network_policy`. If the BFF is the only would-be VPC consumer, **don't create `vpc.tf` at all** (no VPC ⇒ no NAT). DynamoDB/S3 Gateway endpoints are a latency/data-cost nicety, **not** a reason to be in-VPC.

**Option B — In-VPC** (private subnets)
- *Security (pro):* network isolation, **SG-based egress control + flow logs**, and the **only** way to reach in-VPC resources (ElastiCache/**Redis**, RDS, private ALB). Often a compliance/posture requirement.
- *Cost (con):* ENI cold-start latency + the egress cost below.
- *Mechanics:* add the three vpc_* knobs + the lambda SG + the VPC (the VPC section). **Mandatory** once an in-VPC dependency exists.
- *Egress sub-choice (also security × cost):* reach AWS service APIs via a **NAT Gateway** (~$33–66/mo flat, leaves the VPC) **or** **Interface VPC Endpoints/PrivateLink** (fully private on the AWS backbone, ~$7/mo per service per AZ — can drop the NAT). S3/DynamoDB always use the free Gateway endpoints. See the VPC section "Egress posture".

Switching A↔B later is a clean, reversible change. **Lambda@Edge (og-edge) is always non-VPC** (the edge can't be in a VPC — not a choice).

### Pattern B — IaC owns config, the app pipeline ships code
IaC provisions the Lambda with a placeholder zip; the application's own deploy job pushes code via `update-function-code`. Terraform never manages the code artifact after first apply. **The split is by artifact, not by repository** — one side owns everything the console calls *configuration*, the other owns the zip — so it holds whether the app and the IaC are two repos or one.
- `create_package = false`, `ignore_source_code_hash = true`, `s3_existing_package → bff/bootstrap.zip` (a minimal `index.js` exporting `handler` returning 503, uploaded before first apply).
- **Lifecycle:** IaC apply sets config (memory/VPC/env/IAM) — never code; api deploy `update-function-code --s3-key bff/latest.zip` — code only. The two never collide.
- *Why:* a code change never triggers a TFC plan/apply round-trip; the module's built-in `ignore_source_code_hash` is the supported mechanism (no raw resource). Handler code via `/framework-hono`; deploy via `/github-actions`.

### Lambda@Edge (og-edge) — the exception
Same Pattern B, but: `publish = true`, `lambda_at_edge = true`, provider `aws.us_east_1`, **no VPC** (edge can't be in a VPC), dual-trust exec role (the IAM section). After `update-function-code`, the api deploy also calls `publish-version` to get a new qualified ARN. See `/og-edge-handler`.

### Conventions
- Env from IaC + Secrets Manager (`/environment-config`, `/secrets-management`); logs/metrics → the CloudWatch section, tracing → the CloudWatch X-Ray section.
- Function name to SSM `/{env}/api/bff-function-name` (the SSM section).
### Encryption
- **Env vars** are encrypted at rest with the **AWS-managed Lambda key** by default — kept (no CMK), because the env holds only non-secret config + **secret ARNs** (the secrets live in Secrets Manager, `/secrets-management`). Set `kms_key_arn` only if a CMK is mandated (the KMS section).
- In transit: everything the BFF calls is TLS (DynamoDB, AWS APIs). Non-VPC by default (the VPC section); in private subnets only when an in-VPC dependency forces it.

### Decision & trade-off
*Well-Architected pillar: **Cost Optimization (secondary: Performance Efficiency)**.*

- **Non-VPC by default — the function never gets a VPC unless a VPC-only dependency forces it** (the VPC section). Driver is a cost ↔ isolation trade-off: **no VPC ⇒ no NAT Gateway** (the largest line item) and faster cold starts (no ENI attach); traded away is network isolation / SG egress / flow logs — acceptable for a stateless, IAM-auth'd function. Lambda@Edge is **always** non-VPC (the edge can't be in a VPC — not a choice).
- **Pattern B is a deliberate code/config split:** Terraform owns the function CONFIG with a bootstrap placeholder + `ignore_source_code_hash`; the deploy pipeline ships the CODE via `update-function-code`. **Trade-off:** a `terraform apply` never reverts deployed code and a code change never triggers a TFC plan — the two ownership halves never collide. Cost is a one-time bootstrap-zip + the discipline of remembering IaC does not manage the artifact.
- **Lambda@Edge is the Pattern-B exception:** the edge code IS IaC-owned (a hash change publishes a new version and atomically repoints CloudFront in one apply), because CloudFront must reference a specific published version — a separate code pipeline would fight the distribution's state.

### Pros & cons
**Pros**
- arm64 (Graviton) — cheaper, equal/better perf. Non-VPC by default → no NAT, faster cold starts.
- Pattern B decouples code deploys from IaC (no TFC round-trip per code change).
**Cons**
- 29s API GW timeout ceiling; one BFF Lambda = a shared fault domain for all routes.
- Going in-VPC later (for Redis/RDS) reintroduces ENI cold-start overhead + the NAT cost.


## API Gateway

*Provision a REST API Gateway in Terraform — the OpenAPI body imported as the contract, a per-route Cognito authorizer, stage throttling and usage plans, a REGIONAL custom domain, CORS in the spec and a WAF association. Use when exposing a backend, adding an authorizer, or splitting contract ownership between infrastructure and the application. Not for authoring the contract itself (see openapi).*

**REST API (v1), REGIONAL endpoint** — the conventional, full-featured gateway: it supports **WAF**, usage plans + API keys, request/response validation, and resource policies (an HTTP API/v2 has none of these). The API **fronts only the BFF** (`/bff`): one `AWS_PROXY` (Lambda proxy) integration, routes at the **root** (the API *is* the BFF). No official `terraform-aws-modules` REST module fits the OpenAPI-body + Pattern-B reimport flow cleanly, so we use **raw `aws_api_gateway_*`** resources (justified glue — the Terraform section).

### Configuration (api.tf)
```hcl
# REST API — body is the OpenAPI spec; IaC seeds GET /health, the API app owns the full contract.
resource "aws_api_gateway_rest_api" "this" {
  name = "<project>-${var.environment}"
  endpoint_configuration { types = ["REGIONAL"] }     # REGIONAL (not EDGE) — WAF + regional cert
  body = templatefile("${path.module}/bootstrap/openapi-health.json.tftpl", {
    health_integration_uri = module.bff.lambda_function_invoke_arn   # seed GET /health → BFF
  })
  lifecycle { ignore_changes = [body] }               # the API app owns the body after first apply (put-rest-api)
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  triggers    = { redeploy = sha1(aws_api_gateway_rest_api.this.body) }   # redeploy when the seed body changes
  lifecycle { create_before_destroy = true }
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id           = aws_api_gateway_rest_api.this.id
  deployment_id         = aws_api_gateway_deployment.this.id
  stage_name            = "live"
  xray_tracing_enabled  = true
  # access logs → /cloudwatch
}

# stage throttling + per-method metrics (the conventional rate guard; usage plans/keys are also available)
resource "aws_api_gateway_method_settings" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"
  settings { throttling_rate_limit = 1000, throttling_burst_limit = 2000, metrics_enabled = true }
}

# custom domain (REGIONAL) — the generated execute-api endpoint is never the public URL
resource "aws_api_gateway_domain_name" "this" {
  domain_name              = var.api_domain_name                  # api.{env}.<apex-domain>
  regional_certificate_arn = data.aws_acm_certificate.main.arn    # us-east-1 regional cert (/acm)
  endpoint_configuration { types = ["REGIONAL"] }
  security_policy = "TLS_1_2"
}
resource "aws_api_gateway_base_path_mapping" "this" {
  api_id      = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  domain_name = aws_api_gateway_domain_name.this.domain_name
}

# broad invoke permission so reimported routes need no new grant
resource "aws_lambda_permission" "apigw_bff" {
  action = "lambda:InvokeFunction"; function_name = module.bff.lambda_function_name
  principal = "apigateway.amazonaws.com"; source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

# REGIONAL WAF → the stage (REST stages ARE WAF-associable, unlike HTTP APIs) — /waf
resource "aws_wafv2_web_acl_association" "api_gw" {
  resource_arn = aws_api_gateway_stage.this.arn
  web_acl_arn  = module.waf_regional.arn
}
```
**Key knobs:** `endpoint_configuration = REGIONAL` (EDGE would force the cert to us-east-1 *edge* + its own CloudFront — REGIONAL keeps it simple and WAF-associable with a regional WebACL); `lifecycle.ignore_changes = [body]` so an IaC apply never fights the API app's `put-rest-api`; deployment redeploys on seed-body change; custom domain on the reused us-east-1 **regional** cert; `aws_api_gateway_method_settings` for stage throttling.

### Auth — Cognito authorizer (`COGNITO_USER_POOLS`), per route
The OpenAPI body carries an `x-amazon-apigateway-authorizer` of type `cognito_user_pools` (provider ARN = the user pool) + per-route `security`. Public routes (health, public GETs, `/og-meta`, `/prerender`) open; mutations require the JWT. The SPA sends `Authorization: Bearer` (Cognito SDK); the BFF has **no auth code** — it reads `requestContext.authorizer.claims` (`/authentication`, `/bff`).

### CORS — in the OpenAPI body (preflight + errors), echoed by the BFF (success)
A REST API has **no `cors_configuration`** knob (that's an HTTP-API feature), and with a single **Lambda-proxy** integration CORS is **necessarily split** — the gateway can't inject headers into a proxy *success* response. Put **everything reproducible in the OpenAPI body** (so it survives every `put-rest-api --mode overwrite` — never hand-configure CORS in the console):

1. **Preflight** — an `OPTIONS` method per resource with a **MOCK** integration returns the headers (no Lambda call):
```json
"options": {
  "responses": { "200": { "description": "CORS preflight",
    "headers": { "Access-Control-Allow-Origin": {"schema":{"type":"string"}},
                 "Access-Control-Allow-Methods": {"schema":{"type":"string"}},
                 "Access-Control-Allow-Headers": {"schema":{"type":"string"}} } } },
  "x-amazon-apigateway-integration": {
    "type": "mock", "requestTemplates": { "application/json": "{\"statusCode\":200}" },
    "responses": { "default": { "statusCode": "200", "responseParameters": {
      "method.response.header.Access-Control-Allow-Origin":  "'https://${spa_host}'",   /* exact host, never * */
      "method.response.header.Access-Control-Allow-Methods": "'GET,POST,PUT,DELETE,OPTIONS'",
      "method.response.header.Access-Control-Allow-Headers": "'authorization,content-type'" } } } } }
```
2. **Error responses** — gateway responses add the origin to `4XX`/`5XX` (e.g. a 401 from the authorizer is gateway-generated, not from the BFF):
```json
"x-amazon-apigateway-gateway-responses": {
  "DEFAULT_4XX": { "responseParameters": { "gatewayresponse.header.Access-Control-Allow-Origin": "'https://${spa_host}'" } },
  "DEFAULT_5XX": { "responseParameters": { "gatewayresponse.header.Access-Control-Allow-Origin": "'https://${spa_host}'" } } }
```
3. **Success responses** — the proxy returns the **BFF's** response verbatim, so the BFF must set `Access-Control-Allow-Origin` on its 2xx (a one-line Hono `cors`/header — `/bff`). The gateway can't add it to a proxy success.

`@hono/zod-openapi` generates (1)+(2) into the overlay (`/openapi`); the iac seed body includes them for `GET /health`. `${spa_host}` is the exact per-env SPA origin (`<apex-domain>` / `staging.<apex-domain>`) — **never `*`** (we send `Authorization`).

### Rate limiting — stage throttling + usage plans (REST has both)
- **Stage throttling** (`aws_api_gateway_method_settings`, `*/*`): a token bucket — `throttling_rate_limit` (steady req/s) + `throttling_burst_limit` (spike depth); over-limit → **429**. Per-method overrides via a specific `method_path`. Aggregate per stage, not per-client.
- **Usage plans + API keys** (`aws_api_gateway_usage_plan` + `_api_key` + `_usage_plan_key`): per-key quotas + throttles — REST-only. Not needed while the only consumer is the co-owned fed SPA (it authenticates with Cognito JWT, not API keys), but available if an external/partner consumer appears.
- **WAF** rate-based rules (per-IP) front the stage via the REGIONAL WebACL (the WAF section) — the per-IP guard the HTTP API couldn't have.

### Contract ownership — IaC owns the shell, the API app owns the contract
- **IaC (api.tf):** seed spec `bootstrap/openapi-health.json.tftpl` with only `GET /health`; `lifecycle.ignore_changes=[body]`.
- **The API application:** owns the full root route set + authorizer. The OpenAPI is **generated from the Hono code** (`@hono/zod-openapi`, `/openapi`) — not hand-written. On every deploy it generates the spec, overlays the **single AWS integration (the BFF Lambda)** + the Cognito authorizer, then **overwrites + redeploys**:
```bash
API_ID=$(aws ssm get-parameter --name /$ENV_NAME/api/gateway-id --query 'Parameter.Value' --output text)
npx tsx scripts/gen-openapi.ts --version "$(cat VERSION)" --out openapi.json   # version-stamped root copy
envsubst < openapi/openapi.aws.tftpl.json > openapi/openapi.resolved.json      # overlay integration + issuer/audience
aws apigateway put-rest-api --rest-api-id "$API_ID" --mode overwrite --body fileb://openapi/openapi.resolved.json
sleep 15                                                                         # see "deploy reliability" below
aws apigateway create-deployment --rest-api-id "$API_ID" --stage-name live      # publish the new spec
```
Placeholders resolved at deploy: `${INVOKE_ARN_bff}` (every route → the one BFF Lambda), `${COGNITO_POOL_ARN}` = the user-pool ARN, `${COGNITO_CLIENT_ID}` (audience).

**Deploy reliability — two real gotchas (both cost a debugging cycle):**
1. **Settle before deploying.** `put-rest-api --mode overwrite` returns synchronously but the resource graph settles **asynchronously** — an *immediate* `create-deployment` can snapshot BEFORE the newly-added routes register, so the live stage serves **403 "Missing Authentication Token"** for the new paths (old routes keep working, which is the confusing part). Sleep ~15s after `put-rest-api`, then deploy.
2. **Deploy exactly ONCE.** `CreateDeployment` is aggressively rate-limited account-wide — two back-to-back calls trip **`TooManyRequestsException`**. Do not "deploy twice to be safe"; the settle in (1) is what fixes the race, not a second deployment.

**Pipeline independence:** if a future IaC apply resets the body to the seed, the api deploy is re-run manually — no cross-repo trigger (intentional).

**No API versioning (Phase 1-3):** single co-owned consumer (the fed); versioning is overhead that only pays off with external consumers. Evolution: add a `/v2/` base path + a new Lambda alias when needed.

### Conventions
- Cert via the ACM section (regional cert in us-east-1); custom-domain naming via the Route53 section (alias → `aws_api_gateway_domain_name.regional_domain_name` / `regional_zone_id`); ids to SSM (`gateway-id` = REST API id, `gateway-url`) via the SSM section. Contract generation: `/openapi`.
- Raw `aws_api_gateway_*` is justified glue (no official module fits the OpenAPI-body + reimport flow) — the Terraform section.
### Pros & cons
**Pros**
- REST API is **WAF-associable** (per-IP managed rules + rate limiting) and supports usage plans / API keys / request validation — the conventional, full-featured choice.
- Per-route Cognito authorizer keeps auth out of the BFF code; contract generated from code (no hand-written drift).
**Cons**
- ~3.5× the per-request cost of an HTTP API and a bit more latency; more moving resources (raw `aws_api_gateway_*`).
- All routing lives inside the BFF; the put-rest-api + create-deployment step couples deploy to the generated spec.


## CloudFront

*Provision a CloudFront distribution in Terraform — origin access control to a private S3 origin, TLS, managed cache policies, SPA error routing, an extra behaviour for generated images, a viewer-request Lambda at Edge association and a WAF WebACL. Use when serving a static site, adding a path behaviour, or debugging why a deep link returns 404. Not for the edge function's code (see og-edge-handler) or the WebACL rules (see waf).*

Module: `terraform-aws-modules/cloudfront/aws ~> 3.0`. Composes WAF(CLOUDFRONT) + CloudFront + S3(OAC) + Route53, public modules called directly (`frontend.tf`).

### WAF CLOUDFRONT (us-east-1 alias required)
```hcl
module "waf_cloudfront" {                            # full config in /waf
  source    = "cloudposse/waf/aws"
  version   = "~> 1.0"
  providers = { aws = aws.us_east_1 }
  name      = "<project>-cloudfront-${var.environment}"
  scope     = "CLOUDFRONT"
  default_action = "allow"
  managed_rule_group_statement_rules = [
    { name = "common", priority = 1, override_action = "none",
      statement = { name = "AWSManagedRulesCommonRuleSet", vendor_name = "AWS" } }
  ]
}
```

### CloudFront distribution (full config)
```hcl
module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 3.0"

  aliases      = [var.domain_name]
  http_version = "http2and3"
  price_class  = "PriceClass_100"                 # NA + EU edges only (cheapest); cf PriceClass_All
  web_acl_id   = module.waf_cloudfront.web_acl_arn # CLOUDFRONT WAF (us-east-1)

  viewer_certificate = {
    acm_certificate_arn      = data.aws_acm_certificate.main.arn   # us-east-1, looked up by domain (/acm)
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"      # TLS in-transit floor (/kms)
  }

  origin_access_control = {                        # OAC — S3 stays private (not OAI). Referenced by origins below.
    s3_oac = { description = "", origin_type = "s3", signing_behavior = "always", signing_protocol = "sigv4" }
  }
  origin = {
    s3 = { domain_name = module.frontend_bucket.s3_bucket_bucket_regional_domain_name
           origin_access_control = "s3_oac" }
    og = { domain_name = module.og_images_bucket.s3_bucket_bucket_regional_domain_name
           origin_access_control = "s3_oac" }       # /og/* origin
  }

  default_cache_behavior = {
    target_origin_id       = "s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    compress               = true
    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"  # managed CachingOptimized
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"  # managed SecurityHeadersPolicy
    lambda_function_association = {
      viewer-request = { lambda_arn = module.fn_og_edge.lambda_function_qualified_arn, include_body = false }
    }
  }
  ordered_cache_behavior = [                        # OG PNGs from the same distribution (no subdomain)
    { path_pattern = "/og/*", target_origin_id = "og", viewer_protocol_policy = "redirect-to-https",
      allowed_methods = ["GET","HEAD"], compress = true,
      cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" }
  ]

  custom_error_response = [                         # SPA routing: serve index.html on 403/404
    { error_code = 403, response_code = 200, response_page_path = "/index.html" },
    { error_code = 404, response_code = 200, response_page_path = "/index.html" }
  ]
}
```

### Managed policies (managed-first, like WAF)
Prefer AWS **managed** CloudFront policies — no custom policy to maintain. What we use, by managed id:
| Type | Policy | Managed id | Where |
|---|---|---|---|
| Cache | `CachingOptimized` | `658327ea-f89d-4fab-a63d-7e88639e58f6` | default + `/og/*` — honors origin `Cache-Control` (immutable hashed assets vs `no-cache` index.html, set by `/github-actions`) |
| Response headers | `SecurityHeadersPolicy` | `67f7725c-6f97-4210-82d7-5512b31e9d03` | default — adds HSTS, X-Content-Type-Options, X-Frame-Options, Referrer-Policy |
| Origin request | none | — | S3 + OAC needs none; add `CORS-S3Origin` only if cross-origin reads appear |

`CachingDisabled` (`4135ea2d-6df8-44a3-9df3-4b5a84be39ad`) is the managed choice for any never-cache behavior. Write a **custom** policy only when no managed one fits.

### Route53 A-alias → CloudFront
`aws_route53_record` type `A`, alias target = `module.cloudfront.cloudfront_distribution_domain_name`, `zone_id = "Z2FDTNDATAQYW2"` (CloudFront constant). See the Route53 section.

### Conventions
- **OAC, not OAI** — origin S3 buckets stay private; reach them via `s3_bucket_bucket_regional_domain_name` (the S3 section). **OAC origins must be SSE-S3 (AES256), not SSE-KMS** under the `aws/s3` key — OAC can't `kms:Decrypt` it (the origin 403s); use a CMK granting CloudFront if KMS is required (the KMS section).
- TLS ≥ `TLSv1.2_2021`, HTTPS redirect, compression on; encryption stance the KMS section.
- **Lambda@Edge (og-edge)** at Viewer Request via `lambda_function_qualified_arn` — bot UA detection for OG/SEO, no SSR (`/og-edge-handler`). CloudFront Functions only for trivial header/redirect logic.
- **`/og/*` behavior** routes to the `og-images` bucket so OG PNGs serve from the same distribution.
- **Cache-header split** (immutable hashed assets vs `no-cache` index.html) is set by the **fed deploy**, not here (`/github-actions`).
- CLOUDFRONT-scope WAF requires the us-east-1 alias (the WAF section); cert via the ACM section; distribution id to SSM `/{env}/frontend/cloudfront-distribution-id` (the SSM section).
### Custom domain (standard)
The distribution serves the **custom domain** — `aliases = [var.domain_name]` (`<apex-domain>` / `staging.<apex-domain>`). The generated `*.cloudfront.net` host is **never** the public URL. Cert via the ACM section (us-east-1, `sni-only`); the Route53 A-alias to the distribution is in the Route53 section.

### Decision & trade-off
*Well-Architected pillar: **Cost Optimization (secondary: Performance Efficiency)**.*

- **`PriceClass_100` (NA + EU edges only) is the cheapest tier.** *Trade-off:* no APAC/SA edge locations — higher latency for those regions, accepted for cost. Switch to `PriceClass_All` only if the audience warrants global reach.
- **Ordered cache behaviors are FIRST-MATCH — order is load-bearing.** A broad pattern (e.g. `/assets/*` → the SPA build bucket) will **shadow** a more specific prefix that needs a different origin (e.g. `/assets/avatars/*` → an asset store). List the **specific prefix FIRST**; a misordering is a real, silent bug (the specific prefix routes to the wrong origin). When adding a new sub-prefix under an existing broad pattern, insert it before the broad one — or reserve the broad prefix for one origin and move the other to its own path.
- **SPA routing is 403/404 → 200 `/index.html`.** *Gotcha:* because a missing path returns the SPA shell with HTTP 200, **a 200 does not prove the app actually loaded** — health checks must assert on rendered content, not just the status code.

### Pros & cons
**Pros**
- Global TLS edge with OAC — origin S3 stays private.
- Lambda@Edge enables SEO/social crawling without SSR.
- One distribution serves the SPA + `/og/*`.
**Cons**
- Lambda@Edge constraints: no VPC, us-east-1 only, slow propagation.
- Cache invalidation/propagation latency.
- PriceClass_100 = fewer edge locations (cost vs reach).


## ACM

*Resolve TLS certificates in Terraform — one wildcard certificate per environment, issued out of band and reused, required in us-east-1 for CloudFront, and looked up by the environment's domain through a data source. Use when a distribution or custom domain needs a certificate, or when a lookup fails because the certificate is in the wrong region. Not for the DNS records that point at it (see route53).*

### How we use ACM
- Certs **already exist in the account and are provided for reuse** — pre-created out-of-band and DNS-validated once. Terraform **never** creates/validates them (`wait_for_validation` would block `apply` and couple the cert lifecycle to the infra).
- All in **us-east-1** (CloudFront, API GW custom domains, and Cognito custom domains all require the cert there).
- Resolved at runtime **by domain name** via `data "aws_acm_certificate"` — no ARNs in tfvars.

### Certificate format — one wildcard cert per environment
The environment is the subdomain boundary (the Route53 section), so there is **one ACM certificate per environment**, each a wildcard over that environment's subdomain plus the environment's own host:

| Environment | Primary domain | SANs | Covers |
|---|---|---|---|
| production | `<apex-domain>` | `*.<apex-domain>` | apex (SPA), `api.<apex-domain>`, `auth.<apex-domain>` |
| staging | `staging.<apex-domain>` | `*.staging.<apex-domain>` | `staging.` (SPA), `api.staging.`, `auth.staging.` |

> A wildcard matches exactly **one** label, so the environment host itself (`<apex-domain>`, `staging.<apex-domain>`) must be its own SAN — the wildcard alone doesn't cover it. That's why each cert carries `{env-host}` **and** `*.{env-host}`.

### Resolution — per-env data source (resolve by the env's domain)
```hcl
# env/prd.tfvars → acm_certificate_domain = "<apex-domain>"
# env/stg.tfvars → acm_certificate_domain = "staging.<apex-domain>"

data "aws_acm_certificate" "main" {
  provider    = aws.us_east_1
  domain      = var.acm_certificate_domain   # the cert's primary domain for this env
  statuses    = ["ISSUED"]
  most_recent = true
}
# use: data.aws_acm_certificate.main.arn
```
Each per-env workspace resolves **its own** cert by its primary domain — no cross-env ARNs, nothing sensitive in the repo.

### Conventions
- Issuing/validating a cert is a **one-time task** (plan bootstrap runbook), not Terraform.
- New host under an existing env → already covered by that env's `*.{env-host}` wildcard (no cert change). A **new environment** → a new wildcard cert for its subdomain.
- Consumed by the CloudFront section, the API Gateway section, the Cognito section.
### Pros & cons
**Pros**
- Reused certs — no in-stack issuance/validation that would block `apply`.
- Per-env wildcard covers every host of the env with one cert; resolved by domain (no ARNs in tfvars).
**Cons**
- Cert lifecycle is out-of-band / manual.
- A wildcard doesn't cover the apex host (needs an explicit SAN); a new environment needs a new cert.


## Route53

*Model DNS in Terraform — one apex per product with environment-scoped subdomains, a pre-existing hosted zone read through a data source, and one A-alias record per public-facing service. Use when exposing a new service on a domain, adding an environment, or tracing which record points at which distribution. Not for the certificate that domain needs (see acm).*

### Domain model — one apex per product, environment-scoped subdomains
The **environment is encoded in the host**. Production uses the bare apex (+ `api.`/`auth.`); non-prod nests the service under an environment label. The **subdomain is the environment boundary** — never an env query param/header.

| Service | Production | Staging |
|---|---|---|
| Frontend (SPA) | `<apex-domain>` | `staging.<apex-domain>` |
| API | `api.<apex-domain>` | `api.staging.<apex-domain>` |
| Auth (Cognito hosted UI) | `auth.<apex-domain>` | `auth.staging.<apex-domain>` |

General form: production `{service?}.{apex}`, non-prod `{service?}.{environment}.{apex}` (the frontend has no service prefix). Per-env tfvars:
```hcl
# env/prd.tfvars                              # env/stg.tfvars
domain_name      = "<apex-domain>"              # "staging.<apex-domain>"
api_domain_name  = "api.<apex-domain>"          # "api.staging.<apex-domain>"
auth_domain_name = "auth.<apex-domain>"         # "auth.staging.<apex-domain>"
```
These feed CloudFront aliases, the API GW custom domain, the Cognito custom domain, and the Route53 records below. Callback/logout URLs follow the frontend host (`https://{frontend-host}/callback`). Cert coverage per env → the ACM section. **Reusable across future products** — swap the apex, keep the structure.

### Hosted zone — pre-existing, referenced by data source
The `<apex-domain>` hosted zone is created out-of-band (registrar + NS delegation) and referenced once at the root; this stack creates **records only, never the zone**:
```hcl
data "aws_route53_zone" "main" { name = "<apex-domain>" }
```

### A-alias records (one per public-facing service)
Each fronting service gets an **A-alias** in its layer's `.tf`, using `data.aws_route53_zone.main.zone_id`:
```hcl
# frontend.tf — SPA via CloudFront
resource "aws_route53_record" "frontend" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name                  # staging.<apex-domain> | <apex-domain>
  type    = "A"
  alias { name = module.cloudfront.cloudfront_distribution_domain_name
          zone_id = "Z2FDTNDATAQYW2"          # CloudFront's constant hosted-zone id
          evaluate_target_health = false }
}

# api.tf — API GW (REST, REGIONAL) custom domain
resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.api_domain_name              # api.{env}.<apex-domain>
  type    = "A"
  alias { name = aws_api_gateway_domain_name.this.regional_domain_name
          zone_id = aws_api_gateway_domain_name.this.regional_zone_id
          evaluate_target_health = false }
}

# auth.tf — Cognito hosted UI (Cognito provisions its own CloudFront)
resource "aws_route53_record" "auth" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.auth_domain_name
  type    = "A"
  alias { name = module.cognito.user_pool_domain_cloudfront_distribution_arn
          zone_id = "Z2FDTNDATAQYW2"
          evaluate_target_health = false }
}
```

### Conventions
- `aws_route53_record` is justified raw glue (no module abstracts a single alias) — the Terraform section.
- `Z2FDTNDATAQYW2` is the fixed CloudFront hosted-zone id (frontend SPA + Cognito hosted UI). API GW exposes its own `hosted_zone_id` via the module.
- New service → add `{service}.{...}` following the table and include the host in the env's ACM cert (the ACM section).
- SES verification + DKIM records are created by the SES module (the SES section), not here. ACM DNS-validation records are out-of-band/one-time.

### Pros & cons
**Pros**
- A-alias is free, resolves at the apex (a CNAME can't), and is health-aware.
- Pre-existing hosted zone means a stack rebuild never destroys DNS / mail delegation.
**Cons**
- Alias targets must be AWS resources.
- The zone lifecycle is out-of-band, not captured in this stack.


## SES

*Provision SES in Terraform — domain verification, DKIM records, and the deliverability and operations picture around actually sending. Use when a product must send email, when messages land in spam, or when moving a domain out of the sandbox. Not for the code that composes and sends (see notifications).*

Module: **`cloudposse/ses/aws ~> 0.25`** (the Terraform section), in its own `ses.tf`. Verifies the sending domain identity + DKIM; sending lands in Phase 2 via the BFF notifications module (`/notifications`).

### Configuration
```hcl
module "ses" {
  source  = "cloudposse/ses/aws"
  version = "~> 0.25"

  domain        = local.frontend_host             # PER-ENV identity (staging.<apex> / <apex>) — see below
  zone_id       = data.aws_route53_zone.main.zone_id # module writes verification + DKIM records here
  verify_domain = true
  verify_dkim   = true

  ses_user_enabled  = false                          # NO SMTP IAM user — the BFF role sends via the SES API
  ses_group_enabled = false
  name = "ses"; stage = var.environment; enabled = true
}
```
**Choices that matter:**
- **`ses_user_enabled = false`** — we do **not** create an SES SMTP IAM user/credentials; the BFF Lambda sends through the SES API using its exec role (`ses:SendEmail` scoped to the identity ARN — the IAM section). No long-lived SMTP secret.
- **PER-ENV domain identity** (`local.frontend_host` = `staging.<apex>` / `<apex>`), NOT a single apex identity. *Why:* the two environments are **independent Terraform workspaces** and cannot both own the same apex SES identity in one account/region without colliding. Per-env identities isolate them; from-address = `no-reply@<frontend_host>` (a `local`). Trade-off: two verifications instead of one. (To share one identity instead, create it in ONE place and have the other env read it via a data source — never let both workspaces manage it.)
- `verify_dkim = true` — DKIM CNAMEs are auto-created in Route53 (the Route53 section), required for deliverability. Verification + DKIM flip to `Success` a few minutes after apply (Route53 propagation); the BFF can send once verified.

### Sending architecture (the full deliverability + ops picture)
Beyond domain verification, a production sender needs:
- **Auth records (Route53):** **DKIM** (signing, module-created) + **SPF** (TXT `v=spf1 include:amazonses.com -all`) + **DMARC** (`_dmarc` TXT, e.g. `v=DMARC1; p=quarantine; rua=mailto:…`). Add SPF/DMARC for inbox placement.
- **Custom MAIL FROM** (`mail.<apex-domain>`): aligns SPF + Return-Path to your domain instead of amazonses.com — recommended once sending starts.
- **Configuration set + event destination:** route **bounces / complaints / deliveries** to SNS (or CloudWatch) so the app suppresses bad addresses and watches reputation. AWS **requires** handling bounces/complaints — high rates get sending paused (the SNS section).
- **Account suppression list:** SES auto-suppresses known bounces/complaints account-wide; honor it (don't re-send).
- **Sandbox → production + limits:** new accounts are sandboxed (verified recipients only, tiny quota). Request production access (manual, out-of-band), then respect the **sending quota + max send rate** — throttle the SNS→notifications fan-out accordingly (`/notifications`).
- **Sending path:** the BFF calls `ses:SendEmail` (role-scoped, the IAM section) over the **public AWS endpoint** (non-VPC, no NAT); via NAT only if the BFF is in-VPC (the VPC section). TLS in transit by default.

### Notes
- New AWS accounts start in the **SES sandbox** (send only to verified addresses) — requesting production access is a manual, out-of-band step, not Terraform.
- The BFF reaches SES over the **public AWS endpoint** (non-VPC, no NAT); via NAT only if the BFF is in-VPC (there is no SES VPC endpoint here) — the VPC section.
- **Encryption:** SES API is **TLS/SSL by default** (HTTPS), and outbound mail is sent with TLS to recipient MTAs. SES holds no at-rest datastore in our usage; if a configuration-set archive / S3 export is added later it must be **KMS-encrypted** (the KMS section).

### Decision & trade-off
*Well-Architected pillar: **Operational Excellence (secondary: Security)**.*

- **SES is workload-bound — the domain identity lives with the app, not in shared infra.** Sending is specific to this workload's domain, so it's owned here (like Cognito), not in the shared repo. Per-env DOMAIN identity (not one apex identity), because the two envs are independent TF workspaces that can't both own the same apex identity in one account/region without colliding — *trade-off:* two verifications instead of one.
- **The non-VPC BFF reaches SES over the public AWS endpoint (no NAT).** Consistent with the non-VPC Lambda choice (the VPC section) — there is no SES VPC endpoint in play; the path is via NAT only if the BFF is ever forced in-VPC. TLS in transit by default.
- **No SMTP IAM user/credential** (`ses_user_enabled = false`) — the Lambda role sends via the SES API (`ses:SendEmail` scoped to the identity ARN). *Trade-off:* sending is tied to the role rather than portable SMTP creds; nothing to store or rotate.

### Pros & cons
**Pros**
- No SMTP credential to store/rotate — the BFF role sends via the SES API.
- One shared domain verification + DKIM across environments.
**Cons**
- Sending is tied to the Lambda role rather than portable SMTP creds.
- Less env isolation of the sending identity; sandbox→production is a manual step.


## SNS

*Provision SNS in Terraform for asynchronous domain-event fan-out — the topic, its subscriptions, and a mandatory dead-letter queue on every subscription so no event is silently lost. Use when decoupling a side effect from a request, adding a subscriber, or picking the cheapest pub/sub. Not for the publisher code (see notifications).*

SNS is the **simplest, lowest-cost** pub/sub for async fan-out — domain events like `post_published` that trigger notifications (`/notifications`). Chosen over EventBridge for cost/simplicity (no content routing / replay needed at this scale).

### Configuration
```hcl
resource "aws_sns_topic" "events" {
  name              = "<project>-events-${var.environment}"
  display_name      = "<project> events"
  fifo_topic        = false                           # standard topic — cheapest; no strict ordering need
  kms_master_key_id = "alias/aws/sns"                 # SSE at rest, MANDATORY (/kms)
}

# DLQ — MANDATORY on every SNS→Lambda subscription (no event silently lost)
resource "aws_sqs_queue" "events_dlq" {
  name                      = "<project>-events-dlq-${var.environment}"
  message_retention_seconds = 1209600                 # 14 days
  kms_master_key_id         = "alias/aws/sqs"         # SSE at rest
}

resource "aws_sns_topic_subscription" "notifications" {
  topic_arn      = aws_sns_topic.events.arn
  protocol       = "lambda"
  endpoint       = module.bff.lambda_function_arn     # the notifications consumer
  filter_policy  = jsonencode({ type = ["post_published"] })                        # only what this consumer wants
  redrive_policy = jsonencode({ deadLetterTargetArn = aws_sqs_queue.events_dlq.arn })  # failures → DLQ
}

resource "aws_lambda_permission" "sns" {
  action        = "lambda:InvokeFunction"
  principal     = "sns.amazonaws.com"
  function_name = module.bff.lambda_function_name
  source_arn    = aws_sns_topic.events.arn
}
# SSM: /{env}/events/topic-arn = aws_sns_topic.events.arn ; the BFF role gets sns:Publish (/iam)
```
**Choices that matter:** standard topic (`fifo_topic=false`); **KMS SSE on the topic AND the DLQ** (mandatory); **`redrive_policy` → SQS DLQ is mandatory** on every subscription; `filter_policy` so a consumer only gets the event types it wants.

### DLQ pattern (mandatory)
- Every SNS→Lambda subscription carries a `redrive_policy` to an **SQS DLQ**. SNS retries Lambda deliveries automatically; once retries are exhausted the message lands in the DLQ (14-day retention) instead of being lost — the DLQ is **never** the primary path.
- Alarm on the DLQ depth (`ApproximateNumberOfMessagesVisible` > 0 → notify the owner via this topic). Reprocess by redriving from the DLQ.
- The DLQ is KMS-encrypted at rest (`aws/sqs`).

### Conventions
- Message = a small JSON domain event (`{ "type": "post_published", "post_id": "…" }`, snake_case).
- Producer (BFF module) publishes; consumers subscribe (`/notifications`). TLS in transit by default (the KMS section).
- Scale-up path: if content routing / replay / many event types appear, revisit EventBridge.
### Pros & cons
**Pros**
- Cheapest, simplest pub/sub; KMS SSE on topic + DLQ.
- Mandatory SQS DLQ — no event is silently lost.
**Cons**
- No replay / event store (vs EventBridge).
- Routing limited to filter policies; standard topic = no strict ordering.


## CloudWatch

*Provision CloudWatch in Terraform — log group naming and retention, VPC flow logs, custom metrics derived from EMF output, and alarms and dashboards. Use when logs are unbounded or missing, setting a retention window, or adding an alarm. Not for emitting the log lines (see logging) or the metrics (see metrics), and not for browser telemetry (see cloudwatch-rum).*

### Log group & stream naming
**Path shape:** `/aws/<service>/<project>-<workload>-<env>[/<sub>]` — the **first path levels identify the AWS service** at a glance (`/aws/<service>/`), then a **specific workload** (`<project>-<workload>-<env>`). We keep the `/aws/<service>/` prefix even on groups we create ourselves, so every log group is self-describing: service first, workload next, env last.

| Source | Log group | Created by | Streams |
|---|---|---|---|
| BFF Lambda | `/aws/lambda/<project>-bff-${env}` | Lambda (auto) | `YYYY/MM/DD/[$LATEST]{exec-id}` — app logs **+ EMF metrics** land here |
| og-edge (Lambda@Edge) | `/aws/lambda/us-east-1.<project>-og-edge-${env}` | Lambda@Edge (auto, replicated per edge region) | `{region}/YYYY/MM/DD/...` |
| API GW access logs | `/aws/apigateway/<project>-api-${env}` | us (`aws_cloudwatch_log_group`) | per-stage; `$context.requestId` per entry |
| VPC Flow Logs | `/aws/vpc/flow-logs/<project>-${env}` | us | per-ENI |
| WAF (CLOUDFRONT + REGIONAL) | `aws-waf-logs-<project>-${env}` | us | per-webacl |

- **AWS-mandated exceptions:** Lambda auto-names `/aws/lambda/<function-name>` — so we name the *function* `<project>-bff-${env}` and the group follows the convention for free. **WAF requires the `aws-waf-logs-` prefix** (it can't use `/aws/waf/`), so the workload identifier moves right after that mandated prefix.
- **Env is always the last token** of the workload segment; any sub-stream qualifier comes after the workload.
- Retention per env (30d staging / 90d production) via `var.environment`; **encrypted** — key choice in the KMS section.
- Structured app logs come from Powertools Logger (`/logging`).

### Metrics — EMF (Powertools), no collector
- App metrics are **EMF** emitted by **Powertools Metrics** straight into the BFF Lambda log group; CloudWatch auto-extracts them under namespace `<project>/${env}` — **no ADOT collector, no AMP, no Prometheus** (`/metrics`).
- Because EMF is extracted from logs, the Lambda role needs **no `cloudwatch:PutMetricData`** (the IAM section).
- AWS service metrics (Lambda, API GW, DynamoDB, CloudFront, ElastiCache) are available out of the box — DynamoDB observability is CloudWatch metrics (+ optional Contributor Insights), with **no DB log groups** (on-demand DynamoDB has no audit/profiler log exports).

### Log retention policy
- **Every log group sets `retention_in_days`** — never the default *never-expire*, which grows storage cost unbounded.
- Per env: **30 days staging / 90 days production** (driven by `var.environment`); raise a specific group only where an audit/incident need justifies it.
- Module-created groups (lambda / flow-log) set retention via the module input; standalone `aws_cloudwatch_log_group` resources set it directly. All groups are KMS-encrypted (the KMS section).
- **Long-term archive (optional, not default):** for retention beyond 90d, export a group to S3 with a lifecycle to cheaper storage classes — enable only when a compliance need appears.

### Alarms & dashboards (as needed)
- Alarms on error rate / p99 latency / 5xx / DLQ depth → SNS to the owner (the SNS section).
- One dashboard per env composing the key Lambda / API GW / DynamoDB / CloudFront widgets.

### Conventions
- Never log PII or the Authorization header (`/logging`).
- Tag log groups / alarms via `default_tags` (the Terraform section); retention via `var.environment` conditionals (no extra variable).

### Decision & trade-off
*Well-Architected pillar: **Operational Excellence (secondary: Cost Optimization)**.*

- **EMF via Powertools, no collector.** App metrics are emitted as EMF into the Lambda log group and auto-extracted — **no ADOT collector / no AMP / no Prometheus**, and the role needs no `cloudwatch:PutMetricData`. *Trade-off:* CloudWatch metric queries are less expressive than PromQL, accepted for the zero-ops, serverless-native fit.
- **Retention is per-env and always set (never never-expire).** 30 days staging / 90 days production via `var.environment` — a deliberate storage-cost control; default never-expire grows cost unbounded. Long-term archive (export to S3) is opt-in, only when a compliance need appears.

### Pros & cons
**Pros**
- Serverless-native EMF — no collector/scrape; one backend for logs + metrics.
- Service-first log-group paths make ownership obvious at a glance.
**Cons**
- Metric queries less expressive than PromQL.
- Retention is a recurring storage cost; WAF's group can't follow the `/aws/` convention (AWS-mandated prefix).


## CloudWatch RUM

*Provision and instrument real-user monitoring end to end — the Terraform app monitor, a Cognito guest identity pool whose role can only put RUM events, the browser client reporting web vitals, JS errors and HTTP latency, and the sampling that bounds the bill. Use when field performance is unknown or a browser error is invisible server-side. Not for product analytics (see analytics) or server-side logs, alarms and traces (see cloudwatch, cloudwatch-xray).*

**One skill for both halves**, because neither is usable alone: the app monitor is inert until a browser
sends to it, and the browser client cannot initialize without two ids that only the monitor's Terraform
produces. The seam between them — monitor id and identity-pool id travelling through the config bus —
is where this actually goes wrong, and it is in this file rather than split across two.

Real-user monitoring captures **web vitals, JS errors, HTTP latency and sessions**, and correlates them
with **X-Ray** for a browser → API → service trace. It is field telemetry, not product analytics
(`/analytics` is the latter, and they answer different questions).

### App monitor + guest identity (Terraform)

```hcl
resource "aws_rum_app_monitor" "web" {
  name   = "<project>-${var.environment}"
  domain = var.domain_name                          # the environment's hostname
  app_monitor_configuration {
    session_sample_rate = 0.1                        # cost control — see the sampling section
    telemetries         = ["performance", "errors", "http"]
    identity_pool_id    = aws_cognito_identity_pool.rum.id
    enable_xray         = true                       # end-to-end with /cloudwatch-xray
  }
  cw_log_enabled = true
}
# Cognito identity pool; its unauthenticated role grants rum:PutRumEvents on this monitor only
resource "aws_cognito_identity_pool" "rum" { allow_unauthenticated_identities = true /* … */ }
```

**Why an identity pool at all:** the reporting client is an anonymous visitor's browser, so there are no
credentials to give it. The guest identity pool is what lets an unauthenticated page obtain short-lived
credentials scoped to a single action. That is also what makes it an **open ingest surface** — anyone
can obtain those credentials — so the guest role is the only boundary and must grant exactly
`rum:PutRumEvents` on this monitor's ARN and nothing else (the IAM section).

### The two ids the browser needs

Terraform publishes them to the parameter store; the build reads them and bakes them into the bundle:

```hcl
# /{env}/frontend/rum-app-monitor-id
# /{env}/frontend/rum-identity-pool-id
```

The client is then initialized with the monitor id, the identity pool id and the region, the same three
telemetries declared above, and `enableXRay` matching the monitor's setting. Both ids are **non-secret**
— they are published to every visitor's browser by design, which is why they travel as ordinary
build-time configuration (`/environment-config`) rather than as secrets. The client snippet
itself lives with the framework (`/framework-react`).

**The failure this pairing prevents:** the two `enable_xray` / `enableXRay` settings and the two
telemetry lists have to agree. When they were documented in separate files, they disagreed silently —
the monitor accepted events it was not configured to correlate, and the trace simply had a gap.

### Sampling and cost

RUM **bills per event**, so `session_sample_rate` is the cost control and it is the one number worth
thinking about. At `0.1` the bill is small and **most sessions are never seen** — which is fine for
aggregate web vitals and actively bad for debugging a specific user's report, because the odds are the
session was not recorded. Raise it temporarily when hunting a field bug; do not leave it raised.

### Conventions

- A **separate monitor per environment**; never one monitor fed by several environments.
- **No PII** in any custom attribute. The events leave the user's browser and land in a log group.
- Production primarily — a low-traffic non-production environment produces sampled noise and a bill.
- Encrypted log group and tagged like everything else (the KMS section,
  the Terraform section).
- Pairs with the CloudWatch X-Ray section for the server half of the trace, and with
  the CloudWatch section for server-side logs and alarms.

### Pros & cons

**Pros**
- Native CloudWatch and X-Ray correlation — one bill, one console, no extra vendor.
- A guest identity pool lets anonymous visitors report real-user data with no login.
- Cheap at low session sampling, and the cost lever is a single number.
- Provisioning and instrumentation stay in step, including the settings that must match on both sides.

**Cons**
- Fewer product-analytics and session-replay features than a dedicated RUM vendor.
- Unauthenticated ingest is an open surface, bounded only by the least-privilege guest role.
- Sampling at 10% misses most sessions, so it answers aggregate questions far better than individual
  ones.
- Adds a client script and its initialization cost to every page load.


## CloudWatch X-Ray

*Enable X-Ray in Terraform — active tracing on API Gateway and Lambda, sampling rules, and the service map that results. Use when a request path must be traceable across services, tuning sampling for cost, or working out why a segment is missing. Not for the in-code instrumentation (see tracing) or the browser half of the trace (see cloudwatch-rum).*

The tracing **service** side — the backend instrumentation is `/tracing`. Gives a **service map** + traces across API GW → BFF → downstream (DynamoDB/Redis/SES), and — with RUM — browser → backend end-to-end.

### Enable active tracing
- **Lambda** (BFF, og-edge): `tracing_mode = "Active"` (the Lambda section); role gets `xray:PutTraceSegments` + `xray:PutTelemetryRecords`.
- **API Gateway:** enable X-Ray on the stage so the edge span starts the trace.
- **RUM:** `enable_xray = true` joins client traces (the CloudWatch RUM section).

### Sampling
```hcl
resource "aws_xray_sampling_rule" "default" {
  rule_name      = "<project>-${var.environment}"
  priority       = 1000
  fixed_rate     = 0.1            # 10% (+ reservoir) — cost control
  reservoir_size = 1
  service_name = "*"; http_method = "*"; url_path = "*"; host = "*"; service_type = "*"; resource_arn = "*"
}
```

### Conventions
- **Sampling controls cost** (X-Ray bills per recorded trace) — `fixed_rate` low in prod.
- Annotations (indexed, low-cardinality) vs metadata — set in `/tracing`; no PII.
- The **service map** is the payoff: latency/error hotspots across the request path.
- Pairs with the CloudWatch section (logs/metrics) + the CloudWatch RUM section (RUM) for full observability.
### Pros & cons
**Pros**
- Native end-to-end tracing API GW → Lambda → browser (RUM), no extra vendor.
- Sampling rules control cost.
**Cons**
- Less rich than a dedicated APM (Datadog/Honeycomb).
- Sampling can drop the trace you wanted; some instrumentation overhead.


