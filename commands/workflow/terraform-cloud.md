Use Terraform Cloud (TFC) in <project> infrastructure (state backend).

Context: $ARGUMENTS

TFC is the **remote state backend only** — not the execution engine.

## Setup
- Org **`<tfc-org>`**. The `iac` repo's `cloud{}` block: `workspaces { tags = ["<project>-iac"] }`.
- **One workspace per environment:** `<project>-iac-staging`, `<project>-iac-production`.
- **Execution mode: Local** — TFC stores + locks state; **GitHub Actions runs `plan`/`apply`** (TFC does not execute runs).

## CI selection
```bash
TF_WORKSPACE=<project>-iac-staging terraform init
terraform plan  -var-file=env/stg.tfvars
terraform apply -var-file=env/stg.tfvars
```
CI authenticates with the `TFC_API_TOKEN` secret (read+write on both workspaces).

## Execution policy — pipeline only (no local apply/destroy)
**Every state mutation goes through the pipeline. A human/agent NEVER runs `terraform apply` or
`terraform destroy` from a laptop.** `plan` on PR, `apply` on merge (develop→staging, main→production).
- **Local is read-only at most** — `fmt`, `validate`, or a `plan` for inspection. The commands above run
  **in CI**, not on a workstation.
- **Destroying live infra = code + merge**, not an ad-hoc command: remove the resource from config and
  merge — the pipeline's `apply` destroys it. A full teardown uses a dedicated, reviewed `destroy`
  workflow (manual `workflow_dispatch`), never a laptop.
- **Choice:** CI-only execution makes every change reviewed (PR plan), audited (Actions log), and run by
  the least-privilege OIDC role under the TFC lock — not a human's broad local creds.
- **Trade-off:** slower iteration (no instant local apply); emergency fixes still go through a PR/merge
  (or a break-glass `workflow_dispatch`), never a laptop. Worth it for audit + blast-radius control.

## Conventions
- **No local state, no S3/Dynamo backend** — TFC is the single state store; state never committed.
- Workspaces are created once as a bootstrap step (plan runbook), not by Terraform.
- Non-secret inputs via `-var-file`; AWS access via OIDC at apply time — not TFC variable sets.
- See `/infrastructure/terraform` (overall usage) and `/workflow/github-actions` (the runner).

## Pros & cons
**Pros**
- Managed remote state + locking; per-env workspaces; no S3/DynamoDB backend to operate.
**Cons**
- A TFC dependency (and cost beyond the free tier).
- The `cloud{}` block can't interpolate variables; Local execution means GitHub runs plan/apply.
