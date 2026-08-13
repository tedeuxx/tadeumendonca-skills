---
description: Operate the DevOps capability for a `<project>` repo — GitHub Actions CI/CD, Terraform Cloud as the state backend, the branching model per loop mode, and the permission floor keeping IaC pipeline-only. Use when wiring a pipeline, granting CI a role, or choosing a repo's branching/protection. Not for the Terraform configuration itself (see cloud-infrastructure), the loop's state machine (see harness-engineering), or SemVer tagging (see versioning).
---

Operate the DevOps capability for any `<project>` repo — GitHub Actions, Terraform Cloud, branching, and
the permission floor that keeps infrastructure mutation pipeline-only. Pick the repo's loop model first —
everything below (branching, environments, the permission boundary) follows from it.

Context: $ARGUMENTS

Pipelines are **independent per repo** — never trigger one repo's pipeline from another.

## Pick the model first

Determine the repo's loop model (`/harness-engineering`) before configuring protection, writing a deploy
workflow, or writing a single allow/deny entry. **How to tell:** the repo's `CLAUDE.md` states it.
Otherwise, count environments — more than one → `gitflow-multi-env`; one (or none, for a consumed
artifact) → `trunk-single-env`.

## Branching and environments — the two models

### `trunk-single-env` (the active model — `-io` and the skills plugin)
```
main ←── feature/*
```
- **feature/*** (and `fix/*`, `docs/*`, `chore/*`): cut from `main`; PR → `main` required. Short-lived.
- **main**: the **only** long-lived branch, and the **working** branch. Protected (PR required, 0
  approvals, no force-push/deletion), `enforce_admins=false` for the owner and the version-bump actor.
- **No `develop`, no `release/*`, no `hotfix/*`.** A hotfix is just another short-lived branch off `main`.
- **All required checks sit on the PR to `main`**: lint + typecheck + coverage + quality gate + security
  + the full regression. There is no downstream tier to defer any of them to.
- **The merge deploys**, so it is the go/no-go. Never configure auto-merge into `main`.
- **Merge strategy: real merge commits, never squash.** Squashing collapses the per-commit
  conventional-commit history the categorized release notes are built from. See
  [[merge-strategy-no-squash]].
- **Two variants of what "ships" means:** a *deployed app* (`-io`) — merge triggers the deploy, patch
  bumps automatically on push; a *marketplace-distributed plugin* (the skills repo) — every merge to
  `main` auto-bumps the patch and publishes a Release, since the marketplace only serves published
  versions — adoption is the consumer's opt-in, so publishing ≠ forcing. Deliberate minor/major via
  `release.yml`.

### `gitflow-multi-env` (backend-ful reference — OFF in a static repo)
```
main ←── release/* ←── develop ←── feature/*
     ←── hotfix/*
```
- **feature/***: from `develop`; PR → `develop`. **develop**: default branch; protected; auto-deploy to
  staging on merge. **main**: protected; production deploy requires GitHub Environment approval +
  reviewer. **hotfix/***: from `main`; merged to both `main` and `develop`.
- Protection on `main` + `develop`: require PR, 0 approvals, `enforce_admins=false` so the owner and the
  `VERSION_BUMP_TOKEN` actor push directly; no force-push/deletion.
- **Environments are decided by git branch**: `develop` → staging, `main` → production. The pipeline
  deploys on merge; the agent never deploys. Locally there is only ever staging — production is
  unreachable by construction, so production credentials are never on the laptop.

**Versioning & tags** — numeric SemVer via bump-my-version, with the `bump:` loop guard. Under
`trunk-single-env`, on every push to `main` (patch); under `gitflow-multi-env`, on every push to
`develop` (patch) and on `main` via a PR `semver:` label. All the rules live in `/versioning`. See
[[versioning-numeric-semver]].

## GitHub Actions — OIDC, secrets, the workflow set

**Pipeline roles & AWS auth (OIDC).** Every pipeline assumes a dedicated AWS role via GitHub OIDC
(`aws-actions/configure-aws-credentials` + `permissions: id-token: write`) — **no `AWS_ACCESS_KEY_ID`
secrets**. A deploy role has two halves: the trust policy (WHO may assume — the repo's **immutable** OIDC
subject `repo:<org>@<org_id>/<repo>@<repo_id>:*` on the pre-existing GitHub OIDC provider, see `/iam`) and
a least-privilege permissions policy (WHAT it may do).

**Active roles for a static site (`-io`):** an **infra runner** (`github-actions-<project>-iac`, broad
provisioning, bootstrapped out-of-band since it provisions everything and can't self-manage) and a **fed
deploy** role (`s3:PutObject`/`DeleteObject`/`ListBucket`; `cloudfront:CreateInvalidation`, created by
Terraform). Under `gitflow-multi-env`, roles are per-env (`github-actions-{iac,bff,fed}-<env>`) so a
leaked staging token can't assume the prod role.

**Runner-policy gotcha — role deletion:** the runner must be able to delete every resource it creates,
including IAM roles. AWS calls `iam:ListInstanceProfilesForRole` before `iam:DeleteRole` — grant that
(+ `iam:ListRoleTags`) from the start, or a `terraform destroy` of any role fails `AccessDenied`
mid-apply, orphaning the role.

**Secrets — one standard, never decided per repo.** Two axes: SCOPE (does the value change per
environment?) and NAME. **Environment secret** = every AWS OIDC role ARN. **Repository secret** = the
same value for every environment, reserved for account/org-wide tooling tokens (`TFC_API_TOKEN`,
`SONAR_TOKEN`, `CLAUDE_CODE_OAUTH_TOKEN`, `VERSION_BUMP_TOKEN`). Naming: `AWS_<LAYER>_OIDC_ROLE_ARN`
(`LAYER` ∈ `INFRA`/`FED`/`BFF`) — no legacy `AWS_ROLE_ARN`, no generic `AWS_OIDC_ROLE_ARN`. See
[[secrets-scope-naming-standard]]. Audit with `gh secret list -R <repo>` and `--env <name>`.

**Workflow set (per repo):** the build/test gate (`build-test.yml` on PR — lint, typecheck, coverage
≥85%, E2E, SonarCloud, path-filtered) and the infra gate (`infra-plan.yml` — checkov, `fmt`/`validate`,
`plan`, path-filtered to `iac/`); deploy workflows (`deploy.yml`, `infra-apply.yml` on merge to `main`);
`version-main.yml` (numeric SemVer bump); `claude.yml`/`claude-code-review.yml` (`/claude-code`).
`concurrency` groups to avoid overlapping deploys; SHA-pin third-party actions; `npm ci --ignore-scripts`;
least-privilege `permissions:` per job.

**Required check + trigger `paths:` filter gotcha.** If a *required* status check is gated by a
trigger-level `on.pull_request.paths:` filter, a PR touching none of those paths (a docs-only PR) never
starts the workflow, so branch protection leaves it permanently `BLOCKED`. **Fix:** drop `paths:` from
the `pull_request` trigger so the job always runs and reports, then gate the heavy *steps* inside it with
a `dorny/paths-filter@v3` step + `if:`. Keep the `push` trigger's `paths:` (SonarCloud baseline only on
real changes).

## Terraform Cloud — the state backend

TFC is the **remote state backend only**, not the execution engine. Org, one workspace per environment
(`<project>-iac-staging`, `<project>-iac-production`), **execution mode: Local** — TFC stores + locks
state, GitHub Actions runs `plan`/`apply` (`TF_WORKSPACE=<project>-iac-staging terraform init`), auth via
the `TFC_API_TOKEN` secret. **The workspace name is load-bearing** — a rename desyncs state and `plan`
proposes recreating everything.

No local state, no S3/DynamoDB backend — TFC is the single state store. Workspaces are created once as a
bootstrap step, not by Terraform. Non-secret inputs via `-var-file`; AWS access via OIDC at apply time.

## Execution policy — pipeline only, both models

**Every state mutation goes through the pipeline. A human/agent NEVER runs `terraform apply` or
`terraform destroy` from a laptop.** `plan` on PR, `apply` on merge. Local is read-only at most (`fmt`,
`validate`, an inspection `plan`). **Destroying live infra = code + merge** — remove the resource from
config and merge; a full teardown uses a dedicated, reviewed `destroy` workflow
(`workflow_dispatch`), never a laptop.

**Infra-first ordering:** a capability needing new infrastructure ships its IaC slice first (PR →
pipeline applies); only then can the app slice be developed and validated against it — a real dependency
edge in the loop.

## The permission model — the tolerance test and the two layers

**Anything tracked and reversible via git is tolerable.** The danger is never "low environment" — it is
irreversibility that escapes git: cloud/infra state, remote refs on protected branches, secrets, live
traffic. Effect contained in the git-tracked tree → allow freely; effect that escapes git → gate. This
test is model-independent; what changes between models is only *which command* crosses the line.

**`gitflow-multi-env` zones:**

| Zone | Contents |
|---|---|
| **Allow** | Edit/Write · git on feature branches · `gh pr` create/view/diff/checks + merge to `develop` · issue ops · npm/npx · test runners · node/tsx/python3 · `terraform fmt/validate/plan` · `aws` read-only · curl local |
| **Ask** | `gh pr merge --base main` (promotion) · the release action |
| **Deny** | push/merge to `main` · `terraform apply`/`destroy` · direct `aws` mutations · `--force`/`git reset --hard` · `rm -rf` · secrets writes · anything targeting production · `--dangerously-skip-permissions` |

**`trunk-single-env` zones:**

| Zone | Contents |
|---|---|
| **Allow** | Edit/Write · git on feature branches (incl. push) · `gh pr` create/view/diff/checks · issue ops · npm/npx · test runners · node/tsx/python3 · `terraform fmt/validate/plan` · `aws` read-only · curl local |
| **Ask** | the release action |
| **Deny** | direct `git push` to `main` · `terraform apply`/`destroy` · direct `aws` mutations · `--force`/`git reset --hard` · `rm -rf` · secrets writes · `--dangerously-skip-permissions` |

**`gh pr merge` is deliberately NOT in the Ask row (#62).** It used to sit there as *"this is the deploy,
so it is the go/no-go"* — true about the merge, wrong about the mechanism, and it contradicted
`quality-assurance`, which merges the safe class by its own definition. The reason it cannot be a
permission rule is structural: whether a merge needs the human depends on the **class** of the change,
and a permission matcher reads a command string — `gh pr merge 331 --merge` looks identical whether the
diff is a typo fix or a Terraform change. So **the classification is the gate, and `quality-assurance`
holds it**: it merges the safe class once both lenses are green, never the boundary class. This is a
persona-level guarantee, not a mechanical one — accepted deliberately, which is why the irreversible
floor stays in Deny rather than moving to this layer.

**Do not carry `gitflow-multi-env` zones into `trunk-single-env`**: don't pre-authorize merges to
`develop` (the branch doesn't exist); don't deny working on `main` (it's the working branch); don't add
`*prd*` deny patterns for environments the repo doesn't have.

**Two layers.** Global (`~/.claude/settings.json`): the universal floor — deny the always-forbidden and
register the guard hook, protecting every repo even with no local config. Per-project (committed
`.claude/settings.json`): the inner-loop allow for that repo's stack — a versioned repo contract, never
`settings.local.json`. **Deny from any layer wins**, so the global floor is inescapable and the project
layer only adds autonomy. **Never `--dangerously-skip-permissions`.**

**Enforcement = static deny + the guard hook.** Static allow/deny covers every case where the target is
visible in the command string. The `PreToolUse` guard hook (`hooks/permission-guard.sh`, matcher `Bash`)
is the backstop for the irreversible floor in every repo regardless of model — inspects the command
string only, fails open on a parse error by design. **It is deliberately branch-agnostic**: no `git
branch`/`rev-parse` call, no environment-name matching, so the same hook is correct under both models —
a branch-dependent rule belongs in the repo's own `settings.json`, never the shared hook.

## Why this doesn't cost cadence

Strong local validation is the keystone: the agent proves "done" locally without ever needing the denied
boundary, so the deny costs ~zero velocity. Cut local validation and you'd be forced to either loosen the
boundary (risky) or gate everything (slow) — both break cadence.

## Issues & backlog

GitHub Issues per repository — no central backlog repo. Review open issues at session start; on
delivering a plan item, open/close its issue. Product ownership stays with the human. The live label
vocabulary is `product`/`content`/`ready`/`blocked`/`reader-facing` — see `/harness-engineering`. (The
retired `type:`/`priority:`/`phase:` scheme is documented in `github-actions`'s own history if you need
the shape a `semver:`-labeled `gitflow-multi-env` repo still uses.)

## Repo metadata

GitHub repo descriptions follow one format — lead with the platform name, concise, no marketing fluff:
`<apex-domain> — <repo role>: <stack/scope>`. Every repo in a platform leads with the same `<apex-domain>`
deliberately — the description is read in search results and on a profile, detached from other repos, so
the shared prefix is what tells a reader they're one system.

## Language

Everything published on GitHub is in **English** — repo descriptions, READMEs, `docs/`, `CLAUDE.md`,
commit and PR text, Issues. Product UI content language is a separate concern.

## Pros & cons
**Pros**
- One capability for OIDC, secrets/environments, branching, deploys, TFC state, and the permission floor.
- No long-lived AWS keys (OIDC); pipelines independent per repo; managed state with per-env workspaces.
**Cons**
- A large umbrella skill covering many concerns.
- GitHub-platform + TFC lock-in.
