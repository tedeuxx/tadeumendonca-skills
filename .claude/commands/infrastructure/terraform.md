Use Terraform in tadeumendonca infrastructure (how we use it as a whole).

Context: $ARGUMENTS

The single `tadeumendonca-iac` repo provisions everything. This is the end-to-end Terraform usage; module sourcing/customization is its own policy (`/infrastructure/module-policy`).

## Versions & providers
```hcl
terraform {
  required_version = ">= 1.9"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
  cloud { organization = "tadeumendonca-io", workspaces { tags = ["tadeumendonca-iac"] } }
}
provider "aws" { region = var.aws_region; default_tags { tags = { /* /infrastructure/tagging */ } } }
provider "aws" { alias = "us_east_1"; region = "us-east-1"; default_tags { /* ... */ } }  # CloudFront/WAF/ACM
```
Pin provider + module versions with `~>`. Two providers: default + `us_east_1` alias.

## State management (TFC)
Remote state only — **Terraform Cloud is the state backend** (`cloud{}`); no local state, no S3/Dynamo backend, state never committed. **One workspace per environment** (`tadeumendonca-iac-{staging|production}`, tagged). Execution mode **Local**: TFC stores/locks state, **GitHub Actions runs `plan`/`apply`**. CI selects the target with `TF_WORKSPACE` + matching `-var-file`.
> Inherited from the now-decommissioned landing-zone project.

## Repo layout (single canonical root)
One `terraform/` root, **never duplicated per env** — only the `.tfvars` differs at plan/apply (`-var-file=env/stg.tfvars`). One `.tf` per layer (vpc/storage/data/cache/auth/api/frontend/iam) + `versions`/`providers`/`variables`/`outputs` + `env/*.tfvars` + `bootstrap/`. Public modules called **directly** at root, glue inline — no L3 wrappers (`/infrastructure/module-policy`).

## Variables & data sources
`variables.tf` is canonical (`aws_region`, `environment`, `vpc_cidr`, `azs`, `domain_name`, `api/auth_domain_name`, `callback/logout_urls`, `ses_from_address`). **No** `account_id` (→ `data.aws_caller_identity`), **no** ACM ARNs (→ `data.aws_acm_certificate` by domain — `/infrastructure/acm`). `data.aws_route53_zone.main` declared once at root.

## Conventions
- Per-env differences via `var.environment == "production"` conditionals — avoid extra variables.
- Resource names `tadeumendonca-{...}-${var.environment}`; tags via `default_tags` only (`/infrastructure/tagging`).
- Raw glue resources only where no module abstracts (`aws_route53_record`, `aws_lambda_permission`, `aws_wafv2_web_acl_association`, lambda SG).

## CI/CD (.github/workflows)
- `terraform-plan.yml` (PR): `checkov -d terraform/` (block on HIGH) → `validate` → `plan` → comment.
- `terraform-deploy.yml`: develop → staging auto-apply; main → production (Environment approval).
- `version-develop/main.yml`: numeric SemVer (`/workflow/gitflow`).

See `/infrastructure/module-policy`, `/infrastructure/environment-domains`, and the per-service skills.
