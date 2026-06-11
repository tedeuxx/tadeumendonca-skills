Use Terraform in <project> infrastructure (how we use it as a whole).

Context: $ARGUMENTS

The single `<project>-iac` repo provisions everything. This is the end-to-end Terraform usage — versions, state, layout, **module sourcing/customization policy**, and **tagging** (both folded in here).

## Versions & providers
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

## State management (TFC)
Remote state only — **Terraform Cloud is the state backend** (`cloud{}`); no local state, no S3/Dynamo backend, state never committed. **One workspace per environment** (`<project>-iac-{staging|production}`, tagged). Execution mode **Local**: TFC stores/locks state, **GitHub Actions runs `plan`/`apply`**. CI selects the target with `TF_WORKSPACE` + matching `-var-file`. Details: `/workflow/terraform-cloud`.
> Inherited from the now-decommissioned landing-zone project.

## Repo layout (single canonical root)
One `terraform/` root, **never duplicated per env** — only the `.tfvars` differs at plan/apply (`-var-file=env/stg.tfvars`). One `.tf` per layer (vpc/storage/data/cache/auth/api/frontend/iam) + `versions`/`providers`/`variables`/`outputs` + `env/*.tfvars` + `bootstrap/`. Public modules called **directly** at root, glue inline — no L3 wrappers (see policy below).

## Project parameterization (reusable across projects)
These skills are **project-agnostic templates**. Workload-specific values appear as **`<…>` placeholders** (a universal notation that reads correctly in HCL, TypeScript, bash, and prose) — substitute them per project. In your IaC each maps to a real variable:

| Placeholder | Backing variable | Used in |
|---|---|---|
| `<project>` | `var.project` | every resource name / SSM path / secret name (`<project>-bff-…`, `<project>/{env}/redis`) |
| `<apex-domain>` | `var.apex_domain` | the registrable apex; per-env hosts derive from it (`/infrastructure/route53`) |
| `<github-org>` | `var.github_org` | OIDC trust subjects `repo:<github-org>/<project>-api:*` (`/infrastructure/iam`) |
| `<tfc-org>` | `var.tfc_organization` | the `cloud{}` block |
| `<account-id>` | `data.aws_caller_identity` | prose only — never hardcoded in config |

The **example instance** is `project = tadeumendonca`, `apex_domain = tadeumendonca.io`. The per-environment value (`var.environment` = `staging`/`production`) is a **real variable**, not a placeholder — it's `${var.environment}` in HCL, `process.env.ENVIRONMENT` in TS, `$ENV_NAME` in bash.
> The `cloud{}` block + workspace tags **can't interpolate variables** (parsed before vars resolve) — substitute `<tfc-org>`/`<project>` literally there, or pass via partial config / `TF_WORKSPACE`. Everywhere else uses the variables directly.

## Variables & data sources
`variables.tf` is canonical (`project`, `apex_domain`, `github_org`, `tfc_organization`, `aws_region`, `environment`, `vpc_cidr`, `azs`, `domain_name`, `api/auth_domain_name`, `acm_certificate_domain`, `callback/logout_urls`, `ses_from_address`). **No** `account_id` (→ `data.aws_caller_identity`), **no** ACM ARNs (→ `data.aws_acm_certificate` by `var.acm_certificate_domain` — `/infrastructure/acm`). `data.aws_route53_zone.main` declared once at root.

## Input validation (variables)
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

## Module sourcing & customization policy
**Sourcing priority:**
1. **Official first** — prefer official `terraform-aws-modules/*` (HashiCorp/AWS-maintained) for any resource that has one: `vpc`, `s3-bucket`, `cloudfront`, `lambda`, `iam`, `kms`, `dynamodb-table` (`~> 4.0`).
2. **Trusted non-official next** — only when no official module exists, use established sources with a track record: `cloudposse/*` (elasticache, ses, waf), `lgallard/*` (cognito — there is no official Cognito module). Never a low-reputation / unmaintained / single-author module.
3. **Raw `aws_*` last** — justified glue only where no module abstracts the need: **`aws_api_gateway_*`** (the REST API — no official module fits the OpenAPI-body + reimport flow, `/infrastructure/api-gateway`), `aws_lambda_permission`, `aws_wafv2_web_acl_association`, the app-specific lambda SG, `aws_route53_record`, `aws_ssm_parameter`, `aws_secretsmanager_secret`. Note which gap each fills.

**Customization:**
- **Use public modules integrally** through their documented inputs — do not fork, patch, or wrap to tweak behavior.
- **No L3 wrapper modules by default** — call public modules **directly at root**, compose with `local`/resource refs + inline glue (`frontend.tf`, `api.tf`). No `module "frontend"` / `module "api"` abstraction layers.
- **If a wrapper is truly unavoidable**, build a **complete, self-contained L3 pattern** (full inputs/outputs, documented, versioned) — never a thin/leaky passthrough.
- **Pin versions** with `~>`; no floating / `latest`.

*Why:* official/trusted modules carry maintenance and security review we don't own; using them integrally keeps upgrades a one-line bump and avoids drift. Wrappers/raw resources are debt — taken only when a module genuinely can't express the need, then done fully.

## Tagging (shared AWS account)
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

## Conventions
- Per-env differences via `var.environment == "production"` conditionals — avoid extra variables.
- Resource names `<project>-{...}-${var.environment}`; tags via `default_tags` only.
- Raw glue resources only where no module abstracts (`aws_route53_record`, `aws_lambda_permission`, `aws_wafv2_web_acl_association`, lambda SG).

## CI/CD (.github/workflows)
- `terraform-plan.yml` (PR): `checkov -d terraform/` (fail on any unsuppressed finding) → `fmt -check` → `validate` → `plan` → comment.
- `sonar.yml` (PR + push to develop/main): **SonarCloud IaC** scan of `terraform/` (`/workflow/sonarcloud`) — code smells + security hotspots, gate blocks. **Complementary to checkov, not a replacement** (checkov = policy/security; Sonar = maintainability + the quality gate). Kept standalone (not a job in `terraform-plan.yml`) so it can run on push for the new-code baseline without firing the AWS-OIDC plan.
- `terraform-deploy.yml`: develop → staging auto-apply; main → production (Environment approval).
- `version-develop/main.yml`: numeric SemVer (`/workflow/github-actions`).

See `/workflow/terraform-cloud`, `/infrastructure/route53`, and the per-service skills.
## Pros & cons
**Pros**
- Single canonical root (no per-env duplication); TFC remote state + locking.
- Official-first modules used integrally = low maintenance, one-line upgrades.
**Cons**
- The `cloud{}` block can't interpolate variables.
- One root = a larger blast radius per apply; pinned module versions need periodic bumps.
