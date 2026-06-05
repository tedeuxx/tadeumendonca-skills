Run or review the landing-zone migration + manual bootstrap before the first IaC apply.

Context: $ARGUMENTS

These are **one-time, out-of-band** steps (not Terraform-managed) that must exist before `tadeumendonca-iac` can apply.

## 1. Landing zone migration

```bash
cd tadeumendonca-io-aws-landing-zone/terraform
TF_WORKSPACE=tadeumendonca-lz-stg terraform destroy -auto-approve -var-file=env/main.tfvars
TF_WORKSPACE=tadeumendonca-lz-prd terraform destroy -var-file=env/main.tfvars   # manual confirm
```
Then **archive the repo** (GitHub → Settings → Archive). `vpc.tf` in `iac` re-creates the VPC with the same topology inline. The serverless stack is created fresh — **no state import**.

## 2. TFC workspaces
Create `tadeumendonca-iac-staging` + `tadeumendonca-iac-production` in org `tadeumendonca-io`, execution mode **Local** (TFC = state backend only; GitHub Actions runs plan/apply). CI selects with `TF_WORKSPACE` + matching `-var-file`.

## 3. ACM certificates
Pre-created + DNS-validated **once**, never in tfvars. The existing us-east-1 cert covers `tadeumendonca.io`, `*.tadeumendonca.io`, `*.staging.tadeumendonca.io`, `*.production.tadeumendonca.io` (frontend, api, auth, all envs). Resolved at runtime via `data "aws_acm_certificate" "main"`.

## 4. IaC repo OIDC role (manual — chicken-and-egg)
Role `github-actions-tadeumendonca-iac`, trust `token.actions.githubusercontent.com` scoped to `tadeumendonca/tadeumendonca-iac:*`. Policy: S3, CloudFront, Lambda, APIGW v2, Cognito, DocumentDB/RDS, EC2 (VPC), Secrets Manager, Route53, WAF, SSM, IAM (create/pass roles), CloudWatch Logs, OIDC provider read.

## 5. GitHub secrets
- **iac:** `TFC_API_TOKEN`, `AWS_ROLE_ARN` (`arn:aws:iam::858049036700:role/github-actions-tadeumendonca-iac`), `VERSION_BUMP_TOKEN`, `CLAUDE_CODE_OAUTH_TOKEN`.
- **api / fed** (after first IaC apply): `AWS_OIDC_ROLE_ARN` ← read from SSM `/{env}/iam/github-actions-{api|fed}-role-arn`; plus `VERSION_BUMP_TOKEN`, `CLAUDE_CODE_OAUTH_TOKEN`.

## 6. GitHub environments + branch protection
- Environments: `staging` (no rules), `production` (required reviewer = owner).
- `main` + `develop`: require PR before merge; `enforce_admins=false` so the owner and the `VERSION_BUMP_TOKEN` actor (version bot) can push directly; no force-push/deletion. See `/workflow/gitflow`.

## 7. Verification
```bash
TF_WORKSPACE=tadeumendonca-iac-staging terraform plan -var-file=env/stg.tfvars   # valid plan
# merge to develop → staging auto-applies → SSM params created
aws ssm get-parameter --name /staging/frontend/s3-bucket-name   # returns bucket name
curl https://api.staging.tadeumendonca.io/health                # 200 from seed route
```
