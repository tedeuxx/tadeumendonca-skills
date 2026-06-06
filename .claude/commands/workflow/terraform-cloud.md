Use Terraform Cloud (TFC) in tadeumendonca infrastructure (state backend).

Context: $ARGUMENTS

TFC is the **remote state backend only** — not the execution engine.

## Setup
- Org **`tadeumendonca-io`**. The `iac` repo's `cloud{}` block: `workspaces { tags = ["tadeumendonca-iac"] }`.
- **One workspace per environment:** `tadeumendonca-iac-staging`, `tadeumendonca-iac-production`.
- **Execution mode: Local** — TFC stores + locks state; **GitHub Actions runs `plan`/`apply`** (TFC does not execute runs).

## CI selection
```bash
TF_WORKSPACE=tadeumendonca-iac-staging terraform init
terraform plan  -var-file=env/stg.tfvars
terraform apply -var-file=env/stg.tfvars
```
CI authenticates with the `TFC_API_TOKEN` secret (read+write on both workspaces).

## Conventions
- **No local state, no S3/Dynamo backend** — TFC is the single state store; state never committed.
- Workspaces are created once as a bootstrap step (plan runbook), not by Terraform.
- Non-secret inputs via `-var-file`; AWS access via OIDC at apply time — not TFC variable sets.
- See `/infrastructure/terraform` (overall usage) and `/workflow/github-actions` (the runner).
