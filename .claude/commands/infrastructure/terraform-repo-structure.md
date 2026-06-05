Set up or review the Terraform repo structure and conventions in tadeumendonca-iac.

Context: $ARGUMENTS

## Canonical root + per-env tfvars

Single `terraform/` root, **never duplicated per environment**. The only thing that differs between staging and production is the `.tfvars` passed at plan/apply time (`-var-file=env/stg.tfvars`). Public modules are called **directly** — no custom L3 wrapper modules; `frontend.tf`/`api.tf` compose several public modules + glue inline.

## Directory structure

```
terraform/
├── versions.tf      # terraform{} + required_providers + cloud{}
├── providers.tf     # aws (default) + aws.us_east_1 alias
├── variables.tf     # ALL input variables (canonical)
├── vpc.tf           # terraform-aws-modules/vpc + raw lambda SG
├── storage.tf       # s3-bucket ×3 (frontend, artifacts, og-images) + SSM
├── data.tf          # documentdb-cluster + Secrets Manager + SSM
├── auth.tf          # cognito-idp + ses + waf (REGIONAL) + SSM
├── api.tf           # apigateway-v2 + lambda ×6 + lambda_permission + WAF assoc + SSM
├── frontend.tf      # waf (CLOUDFRONT) + cloudfront + Route53 + SSM
├── iam.tf           # iam-policy ×2 + iam-assumable-role-with-oidc ×2 + SSM
├── outputs.tf
├── bootstrap/placeholder.zip   # minimal Lambda zip for first apply (Pattern B)
└── env/{stg,prd}.tfvars
```

## versions.tf / providers.tf

```hcl
terraform {
  required_version = ">= 1.9"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
  cloud {
    organization = "tadeumendonca-io"
    workspaces { tags = ["tadeumendonca-iac"] }   # TF_WORKSPACE selects workspace at CI time
  }
}

provider "aws" {
  region       = var.aws_region
  default_tags { tags = { Environment = var.environment, Project = "tadeumendonca", ManagedBy = "terraform" } }
}

# CloudFront + WAF(CLOUDFRONT) + ACM(CloudFront) require us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags { tags = { Environment = var.environment, Project = "tadeumendonca", ManagedBy = "terraform" } }
}
```

## variables.tf (canonical)

`aws_region`, `environment`, `vpc_cidr` (default `10.0.0.0/16`), `azs`, `domain_name`, `api_domain_name`, `auth_domain_name`, `callback_urls`, `logout_urls`, `ses_from_address`. **No** `account_id` (→ `data.aws_caller_identity`), **no** ACM ARNs (→ `data.aws_acm_certificate`, looked up by domain — never in tfvars).

## TFC workspace selection

`cloud{}` uses `workspaces { tags = ["tadeumendonca-iac"] }`; execution mode **Local** (TFC = state backend only, GitHub Actions runs plan/apply). CI picks the target with `TF_WORKSPACE=tadeumendonca-iac-{staging|production}` paired with the matching `-var-file`. `var.environment` uses the full word (`staging`/`production`).

## CI/CD workflows (.github/workflows)

- `terraform-plan.yml` — on PR to develop/main: **`checkov -d terraform/ --framework terraform --compact`** (blocks on HIGH `FAILED`) → `terraform validate` → `terraform plan` → comment plan on PR.
- `terraform-deploy.yml` — push develop → staging auto-apply; push main → production (GitHub Environment approval gate).
- `version-develop.yml` / `version-main.yml` — numeric SemVer (see `/workflow/gitflow`).

## Conventions
- Public modules called directly; glue (`aws_route53_record`, `aws_lambda_permission`, `aws_wafv2_web_acl_association`, raw lambda SG) only where no module abstracts it.
- `data "aws_route53_zone" "main"`, `data "aws_acm_certificate" "main"` (us-east-1), `data "aws_caller_identity" "current"` declared once at root (in `data.tf`).
- Per-env differences expressed via `var.environment == "production"` conditionals — avoid extra variables.

## Rationale — ACM out-of-band
DNS validation inside Terraform (`wait_for_validation`) blocks `apply` and couples the cert lifecycle to the infra. Certs are created/validated once outside Terraform; ARNs resolve at runtime via `data "aws_acm_certificate"` (by domain) — no sensitive ARNs in tfvars. `account_id` likewise via `data "aws_caller_identity"`.
