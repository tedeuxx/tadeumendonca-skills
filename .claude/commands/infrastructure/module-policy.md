Apply the Terraform module sourcing & customization policy in tadeumendonca-iac.

Context: $ARGUMENTS

## Sourcing priority

1. **Official first** — prefer **official `terraform-aws-modules/*`** modules (HashiCorp-verified / AWS-maintained) for any resource that has one: `vpc`, `s3-bucket`, `cloudfront`, `cognito-idp`, `apigateway-v2`, `lambda`, `iam`.
2. **Trusted non-official next** — only when no official module exists, use public modules from **trusted, established sources** with a real track record: `cloudposse/*` (documentdb, elasticache-redis, ses), `aws-ia/*` (waf). Never a low-reputation / unmaintained / single-author module.
3. **Raw `aws_*` last** — only as justified glue where no module abstracts the need: `aws_lambda_permission`, `aws_wafv2_web_acl_association`, the app-specific lambda SG, `aws_route53_record`, `aws_ssm_parameter`, `aws_secretsmanager_secret`. Note which gap each one fills.

## Customization policy

- **Avoid customizing public modules** — use them **integrally**, through their documented inputs. Do not fork, patch, or wrap a module just to tweak behavior.
- **No L3 wrapper modules by default** — call public modules **directly at the root** and compose them with `local`/resource references + glue inline (`frontend.tf`, `api.tf` wire several modules together). No `module "frontend"` / `module "api"` abstraction layers.
- **If a wrapper is truly unavoidable**, build it as a **complete, self-contained L3 pattern** (full inputs/outputs, documented, versioned) — never a thin/leaky partial wrapper that only passes values through.
- **Pin versions** with `~>` (`terraform-aws-modules/vpc/aws ~> 5.0`); no floating / `latest`.

## Why
Official and trusted-source modules carry maintenance, security review, and community scrutiny we don't have to own. Using them integrally (no forks/wrappers) keeps upgrades a one-line version bump and avoids drift. Wrappers and raw resources are debt — taken on only when a module genuinely can't express the need, and then done fully. See `/infrastructure/terraform-repo-structure`.
