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
| `<project>` | `var.project` | every resource name / SSM path / secret name (`<project>-bff-…`, `<project>/{env}/docdb`) |
| `<apex-domain>` | `var.apex_domain` | the registrable apex; per-env hosts derive from it (`/infrastructure/route53`) |
| `<github-org>` | `var.github_org` | OIDC trust subjects `repo:<github-org>/<project>-api:*` (`/infrastructure/iam`) |
| `<tfc-org>` | `var.tfc_organization` | the `cloud{}` block |
| `<account-id>` | `data.aws_caller_identity` | prose only — never hardcoded in config |

The **example instance** is `project = tadeumendonca`, `apex_domain = tadeumendonca.io`. The per-environment value (`var.environment` = `staging`/`production`) is a **real variable**, not a placeholder — it's `${var.environment}` in HCL, `process.env.ENVIRONMENT` in TS, `$ENV_NAME` in bash.
> The `cloud{}` block + workspace tags **can't interpolate variables** (parsed before vars resolve) — substitute `<tfc-org>`/`<project>` literally there, or pass via partial config / `TF_WORKSPACE`. Everywhere else uses the variables directly.

## Variables & data sources
`variables.tf` is canonical (`project`, `apex_domain`, `github_org`, `tfc_organization`, `aws_region`, `environment`, `vpc_cidr`, `azs`, `domain_name`, `api/auth_domain_name`, `acm_certificate_domain`, `callback/logout_urls`, `ses_from_address`). **No** `account_id` (→ `data.aws_caller_identity`), **no** ACM ARNs (→ `data.aws_acm_certificate` by `var.acm_certificate_domain` — `/infrastructure/acm`). `data.aws_route53_zone.main` declared once at root.

## Module sourcing & customization policy
**Sourcing priority:**
1. **Official first** — prefer official `terraform-aws-modules/*` (HashiCorp/AWS-maintained) for any resource that has one: `vpc`, `s3-bucket`, `cloudfront`, `cognito-idp`, `apigateway-v2`, `lambda`, `iam`, `kms`.
2. **Trusted non-official next** — only when no official module exists, use established sources with a track record: `cloudposse/*` (documentdb, elasticache-redis, ses), `aws-ia/*` (waf). Never a low-reputation / unmaintained / single-author module.
3. **Raw `aws_*` last** — justified glue only where no module abstracts the need: `aws_lambda_permission`, `aws_wafv2_web_acl_association`, the app-specific lambda SG, `aws_route53_record`, `aws_ssm_parameter`, `aws_secretsmanager_secret`. Note which gap each fills.

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
- `terraform-plan.yml` (PR): `checkov -d terraform/` (block on HIGH) → `validate` → `plan` → comment.
- `terraform-deploy.yml`: develop → staging auto-apply; main → production (Environment approval).
- `version-develop/main.yml`: numeric SemVer (`/workflow/github-actions`).

See `/workflow/terraform-cloud`, `/infrastructure/route53`, and the per-service skills.
