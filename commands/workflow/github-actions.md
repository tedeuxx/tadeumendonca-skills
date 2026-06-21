Use GitHub for <project> repos — the CI/CD capability (Actions, GitFlow + versioning, deploys, issues).

Context: $ARGUMENTS

The single GitHub/CI-CD capability skill: the Actions platform, the branching + numeric-versioning model, the per-repo deploy workflows, and the Issues backlog all live here. Pipelines are **independent per repo** — never trigger one repo's pipeline from another.

## Pipeline roles & AWS auth (OIDC) — what CI can do in the account
Every pipeline assumes a dedicated AWS role via **GitHub OIDC** (`aws-actions/configure-aws-credentials` + `permissions: id-token: write`) — **no `AWS_ACCESS_KEY_ID` secrets**. A deploy role has two halves: the **trust policy = the OIDC handshake** (WHO may assume — `repo:<github-org>/<repo>:*` on the pre-existing GitHub OIDC provider) and a **least-privilege permissions policy** (WHAT it may do). All of this is a pipeline concern and lives here; **runtime IAM** (the Lambda exec role, the Cognito identity-pool role — what the *running app* uses) is `/infrastructure/iam`.

| Pipeline role | Trust (OIDC subject) | Permissions (scoped, least-privilege) | Authored |
|---|---|---|---|
| **iac runner** `github-actions-<project>-iac-<env>` | `repo:<org>/<project>-iac:*` (+ the app-infra repo if a monorepo owns infra), optionally pinned per env by branch | broad provisioning — creates/updates/**deletes** all infra **in that env** | **out-of-band** (it provisions everything, so can't self-manage) |
| **bff deploy** `github-actions-api-<env>` | `repo:<org>/<project>-pwa:*` (the monorepo `apps/bff` deploy job) | `lambda:UpdateFunctionCode`/`PublishVersion`/`GetFunction*` on `<project>-*-<env>`; `apigateway:PUT`/`POST`/`GET` on `/restapis/*`; `s3:PutObject`/`GetObject` (artifacts bucket); `ssm:GetParameter*` on `/{env}/*` | Terraform (`iam.tf`) |
| **fed deploy** `github-actions-fed-<env>` | `repo:<org>/<project>-pwa:*` (the monorepo `apps/fed` deploy job) | `s3:PutObject`/`DeleteObject`/`ListBucket` (fed bucket); `cloudfront:CreateInvalidation`; `ssm:GetParameter*` on `/{env}/*` | Terraform (`iam.tf`) |

- **api/fed roles** are created by the **iac Terraform** (`iam.tf`, `iam-policy` + `iam-assumable-role-with-oidc` submodules) and their ARNs written to SSM `/{env}/iam/github-actions-{api,fed}-role-arn`; the app pipelines assume `AWS_BFF_OIDC_ROLE_ARN` / `AWS_FED_OIDC_ROLE_ARN` (env-scoped secrets; the SSM copy is for reference, never a rotatable key). The Terraform lives in `iam.tf`, but the role is a **pipeline** concept — documented here.
- **iac runner** roles are **per-env** (`github-actions-<project>-iac-<env>`), bootstrapped **out-of-band** (chicken-and-egg); their `<project>-iac-deploy` policy is maintained out-of-band. Their ARNs are the **environment-scoped** `AWS_INFRA_OIDC_ROLE_ARN` secret (one value per Environment) — same treatment as the BFF/FED deploy roles. **Runner-policy gotcha — role deletion:** the runner must be able to **delete** every resource it creates, including IAM roles. The AWS provider calls **`iam:ListInstanceProfilesForRole`** (to detach instance profiles) **before** `iam:DeleteRole` — if the policy has `CreateRole`/`DeleteRole` but not `ListInstanceProfilesForRole` (+ `iam:ListRoleTags`), a `terraform destroy` of any role (e.g. a VPC's flow-log role) fails with `AccessDenied` **mid-apply**, orphaning the role + leaving inconsistent state. Grant those from the start.
- The **GitHub OIDC provider** itself is **pre-existing** (landing zone), referenced by `provider_url`, not created. Confused-deputy guard: OIDC trust uses `StringLike` on `token.actions.githubusercontent.com:sub`.

## Secrets & environments
**ONE standard across every repo — never decide per repo.** A secret has two independent axes, each
fixed by rule: **SCOPE** (repository vs environment secret) and **NAME**. Audit a repo by listing both
levels: `gh secret list -R <repo>` **and** `gh secret list -R <repo> --env <staging|production>`.

**SCOPE — repository vs environment secret — decided by ONE question: does the value change per environment?**
- **Environment secret** (GitHub Environments `staging`/`production`, **same name in each, different value
  per env**) = **every AWS OIDC role ARN** — `AWS_INFRA_OIDC_ROLE_ARN`, `AWS_BFF_OIDC_ROLE_ARN`,
  `AWS_FED_OIDC_ROLE_ARN` — plus per-env test fixtures `TEST_USER_*` (staging). Each role is **per-env**
  (`github-actions-{<project>-iac,bff,fed}-<env>`), **including the iac runner**: split it per env so a
  leaked staging OIDC token can't assume the production role, and the prod role is released only after the
  `production` Environment's required-reviewer approval. (Terraform needs broad provisioning rights, so the
  per-env infra split buys **credential isolation + the approval gate**, not tighter permissions — but that
  isolation matters most precisely on the most powerful role.) Optionally pin each role's trust by branch
  (`:ref:refs/heads/develop`→staging, `…/main`→production).
- **Repository secret** = the SAME value for every environment — reserved for the account/org-wide **tooling
  tokens only**: `TFC_API_TOKEN`, `SONAR_TOKEN`, `CLAUDE_CODE_OAUTH_TOKEN`, `VERSION_BUMP_TOKEN`.
- **Rule of thumb:** if the value differs per environment (every deploy/runner role does), it's an
  **environment** secret — same name in each Environment, **no** `-staging`/`-production` suffix (the
  Environment supplies it). Only a single value shared across all envs is a **repository** secret.

**NAME — one scheme:**
- **AWS OIDC role ARNs:** `AWS_<SCOPE>_OIDC_ROLE_ARN`, `SCOPE` ∈ `INFRA` (iac runner) · `BFF` · `FED` — **all
  environment-scoped**. **No legacy `AWS_ROLE_ARN`** and **no** generic `AWS_OIDC_ROLE_ARN` — the scope in the
  name keeps a monorepo's three distinct (least-privilege) roles unambiguous.
- **Third-party credentials:** keep the name the consuming action mandates (`SONAR_TOKEN`,
  `CLAUDE_CODE_OAUTH_TOKEN`); otherwise `<PROVIDER>_<KIND>_TOKEN` — `TFC_API_TOKEN`, `VERSION_BUMP_TOKEN`.
- **Test fixtures:** `TEST_<SUBJECT>_<FIELD>` — `TEST_USER_USERNAME`, `TEST_USER_PASSWORD` (staging only).

**Canonical per-repo set — every repo audits against this one list:**

| Secret | Scope | iac repo | app repo (api/fed/pwa) | skills |
|---|---|:--:|:--:|:--:|
| `AWS_INFRA_OIDC_ROLE_ARN` | environment | ✓ | ✓ *(only if it owns app-infra, e.g. the pwa monorepo)* | — |
| `AWS_BFF_OIDC_ROLE_ARN` | environment | — | ✓ *(bff)* | — |
| `AWS_FED_OIDC_ROLE_ARN` | environment | — | ✓ *(fed)* | — |
| `TFC_API_TOKEN` | repository | ✓ | ✓ *(if it owns terraform)* | — |
| `SONAR_TOKEN` | repository | ✓ | ✓ | — |
| `CLAUDE_CODE_OAUTH_TOKEN` | repository | ✓ | ✓ | ✓ |
| `VERSION_BUMP_TOKEN` | repository | ✓ | ✓ | ✓ |
| `TEST_USER_USERNAME` / `TEST_USER_PASSWORD` | environment *(staging)* | — | ✓ *(fed e2e)* | — |

- **Choice:** **every** OIDC role is per-env + environment-scoped (uniform across INFRA/BFF/FED), so credential
  isolation and the prod approval gate apply to *all* pipelines — including the most powerful one (infra);
  repository scope is reserved for genuinely cross-env tooling tokens. **Trade-off / migration:** re-scoping a
  secret (repo→environment) or renaming it means the GitHub secret store AND the consuming jobs change
  **together** — the deploy/apply jobs already declare `environment:`, so the same `secrets.AWS_*_OIDC_ROLE_ARN`
  ref resolves from the Environment once the env secret exists; sequence: **add** the env secret in each
  Environment → prove on a PR/apply → **remove** the old repo-level secret last.
- **Plan-time caveat:** a read-only `plan` job on a PR also assumes a role. Give it the matching env's role
  with read access **without** gating PRs behind prod approval — e.g. plan against the staging role, or a
  dedicated non-gated read-only role — so opening a PR never blocks on the `production` reviewer.

**Environments:** `staging` (no rules) + `production` (required reviewer) — production deploys gate on
environment approval. **Every** role ARN lives as an **environment secret** (same name, different value per env).

## Workflow set (per repo)
- `ci.yml` (api/fed) — **PR + push to develop/main**: lint + typecheck + tests + **SonarCloud** gate + security gates (`/backend/coverage`, `/frontend/coverage`, `/workflow/sonarcloud`). Push to develop/main sets SonarCloud's new-code baseline. iac has no `ci.yml` — its gates are `terraform-plan.yml` (checkov) + `sonar.yml` (SonarCloud IaC).
- **Required check + trigger `paths:` filter = docs PRs BLOCKED forever (gotcha).** If a *required* status check (`build-test`, `sonar`) is gated by a trigger-level `on.pull_request.paths:` filter, a PR that touches none of those paths (a docs-only `CLAUDE.md` PR) never starts the workflow, so the required check never reports — branch protection then leaves the PR permanently `BLOCKED` (and `--admin` bypass defeats the gate). **Fix:** drop `paths:` from the `pull_request` trigger so the job ALWAYS runs (and always reports the required check), then gate the heavy steps inside the job with a `dorny/paths-filter@v3` step + `if: steps.changes.outputs.<filter> == 'true'`. Docs-only PRs run the job and finish **green** in seconds without the toolchain (free on public repos). Keep the `push` trigger's `paths:` (SonarCloud baseline only on real changes). Don't gate the whole *job* with `if:` (skipped-required-job behavior is surprising) — gate the *steps* so the job itself still reports success.
- `deploy.yml` — develop→staging (auto), main→production (approval); iac uses `terraform-plan.yml` + `terraform-deploy.yml` (`/workflow/terraform-cloud`).
- `version-develop.yml` / `version-main.yml` — numeric SemVer bump (below).
- `claude.yml` + `claude-code-review.yml` — Claude GitHub App (assistant + auto review) — `/workflow/claude-code`.
- **`concurrency`** groups to avoid overlapping deploys/version bumps (`cancel-in-progress: false`); pin action versions (`@v4`); least-privilege `permissions:` per job (`id-token: write` only where OIDC is needed).

## Branching (GitFlow)
```
main ←── release/* ←── develop ←── feature/*
     ←── hotfix/*
```
- **feature/***: from `develop`; PR → `develop` required.
- **develop**: default branch; protected (PR required); auto-deploy to staging on merge.
- **main**: protected (PR required); production deploy requires GitHub Environment approval + reviewer.
- **hotfix/***: from `main`; merged to both `main` and `develop`.
- Protection on `main` + `develop`: require PR, **0 approvals** (solo dev can't self-approve), `enforce_admins=false` so the owner and the `VERSION_BUMP_TOKEN` actor push directly; no force-push/deletion.
- **Merge strategy: real merge commits, never squash.** Set each repo's default merge method to **merge commit** and **disable squash merging**, so MRs are not opened/merged as a squash by default; merge with `gh pr merge --merge`, never `--squash`. Squashing collapses the per-commit **conventional-commit** history that the categorized release notes are built from (`git log --no-merges`, see `/workflow/versioning`) and erases the slice-by-slice trail. (Rebase-merge is acceptable when strictly linear history is wanted; squash is not.)
- **Where this GitFlow applies:** `<project>-iac` and `<project>-pwa` use the **deploy** model above — `develop`→staging (auto), `main`→prod (Environment approval). **`<project>-skills` (this plugin) does NOT** — it has no Environments/deploy, so `develop` is empty ceremony for it. It is **trunk-based**: a single long-lived `main` (feature branches → PR → `main`), and a deliberate release is cut on demand via `release.yml` (`workflow_dispatch`, choose major/minor/patch) which **tags `vX.Y.Z`** (the version consumers pin in their marketplace `ref`). No app/infra is deployed; the "release" is the tag itself. Why the divergence: a consumed artifact's tags are a consumer lockfile, so versioning is deliberate (release-only), never auto-bump-on-push (`/workflow/versioning`).

**Versioning & tags** — numeric SemVer via bump-my-version on every push to `develop` (patch) / `main` (PR `semver:` label), with the `bump:` loop guard. All the rules live in **`/workflow/versioning`**; `version-develop.yml` / `version-main.yml` run it.

## Deploy — iac (Terraform)
Uses the **iac runner** OIDC role (see the pipeline-roles table above — out-of-band, broad provisioning, role-deletion gotcha). State + locking live in Terraform Cloud, execution mode **Local** — GitHub runs `plan`/`apply` (`/workflow/terraform-cloud`); the `TFC_API_TOKEN` secret authenticates to TFC.
- **`terraform-plan.yml` (PR):** `checkov -d terraform/` (block on HIGH) → `terraform fmt -check` + `validate` → `plan` (`TF_WORKSPACE=<project>-iac-<env>`, `-var-file=env/<env>.tfvars`) → post the plan as a PR comment.
- **`terraform-deploy.yml`:** merge to `develop` → `apply` to **staging** (auto); merge to `main` → `apply` to **production**, gated by the `production` GitHub Environment approval.
- **`sonar.yml` (PR + push to develop/main):** standalone **SonarCloud IaC** quality gate on `terraform/` (`/workflow/sonarcloud`) — separate from `terraform-plan.yml` so push runs the scan without the AWS-OIDC plan; checkov stays in `terraform-plan.yml` (complementary).
- On apply, IaC writes all SSM params → the `apps/bff` + `apps/fed` deploy jobs read current values at their own deploy (`/infrastructure/ssm`). Pipelines stay **independent** — IaC never triggers the app deploy jobs.

## Deploy — api (the BFF)
The api is **one BFF Lambda** (+ the separate og-edge Lambda@Edge). Role from SSM `/{env}/iam/github-actions-api-role-arn`.
```bash
# 1. build (esbuild) → one BFF bundle + edge bundle (minified, node22, arm64)
node esbuild.config.mjs ; node esbuild.config.mjs --edge
# 2. deploy BFF (single)
BFF_NAME=$(aws ssm get-parameter --name /$ENV_NAME/api/bff-function-name --query Parameter.Value --output text)
( cd dist && zip -r ../bff.zip . ) ; aws s3 cp bff.zip s3://$S3_BUCKET/bff/latest.zip
aws lambda update-function-code --function-name "$BFF_NAME" --s3-bucket "$S3_BUCKET" --s3-key bff/latest.zip
# 3. deploy og-edge (us-east-1) + publish a new version (qualified ARN)
aws lambda update-function-code --function-name "$EDGE_FN_NAME" --s3-bucket "$S3_BUCKET" --s3-key og-edge/latest.zip
aws lambda publish-version --function-name "$EDGE_FN_NAME"
# 4. republish the contract (generated from code, /backend/openapi) — REST API put + deploy
API_ID=$(aws ssm get-parameter --name /$ENV_NAME/api/gateway-id --query Parameter.Value --output text)
npx tsx scripts/gen-openapi.ts --version "$(cat VERSION)" --out openapi.json
export COGNITO_POOL_ARN=... COGNITO_CLIENT_ID=... INVOKE_ARN_bff=...   # overlay integration + authorizer + CORS
envsubst < openapi/openapi.aws.tftpl.json > openapi/openapi.resolved.json
aws apigateway put-rest-api --rest-api-id "$API_ID" --mode overwrite --body fileb://openapi/openapi.resolved.json
aws apigateway create-deployment --rest-api-id "$API_ID" --stage-name live   # publish the new spec
```

## Deploy — fed
Role from SSM `/{env}/iam/github-actions-fed-role-arn`. Build-time `VITE_*` from SSM (`/frontend/environment-config`).
```bash
# 1. config from SSM: frontend/s3-bucket-name, frontend/cloudfront-distribution-id, api/gateway-url, cognito-*
# 2. build (Vite — env injected at build time)
npm ci && npm run build
# 3. S3 sync with split cache headers
aws s3 sync dist/ s3://$S3_BUCKET/ --delete --exclude index.html --cache-control "public,max-age=31536000,immutable"
aws s3 cp dist/index.html s3://$S3_BUCKET/index.html --cache-control "no-cache,no-store,must-revalidate"
# 4. CloudFront invalidation
aws cloudfront create-invalidation --distribution-id $CF_DIST_ID --paths "/*"
```
Hashed assets are immutable (content hash in filename); `index.html` is always `no-cache` so it references fresh asset hashes. CI blocks deploy on coverage < 85% or failing Playwright E2E (`/frontend/playwright`, `/frontend/coverage`).

## Issues & backlog (GitHub Issues, per repo)
The product backlog is **GitHub Issues per repository** — no central backlog repo. Claude maintains it automatically: at session start review open issues (status/labels, close stale); on delivering a plan item, open/close its issue unprompted.

| Group | Labels |
|---|---|
| `type:` | `feature` · `bug` · `chore` · `docs` · `infra` |
| `phase:` | `1` (CV/v0.2.0) · `2` (Feed/v0.3.0) · `3` (Articles/v0.4.0) |
| `priority:` | `high` (blocks phase) · `medium` · `low` |
| `semver:` | `major` · `minor` (default) · `patch` — drives the bump on release to `main` |
| `status:` | `blocked` |

- **Milestones:** `v0.1.0 Bootstrap` (iac) · `v0.2.0 Phase 1` (all) · `v0.3.0 Phase 2` · `v0.4.0 Phase 3` · `v1.0.0 GA`.
- **Templates** (`.github/ISSUE_TEMPLATE/`): `task.md` (`type:feature, semver:minor`; What/Why/Acceptance/Phase·Milestone), `bug.md` (`type:bug, semver:patch, priority:high`; Expected/Actual/Steps/Environment).
- **Conventions:** title `[area] short description`; always set `type:`/`phase:`/`semver:` on creation, `priority:` when known; translate plan deliverables into one issue each at the start of implementation.

## Repo metadata
GitHub repo **descriptions** follow one format — lead with the platform name (`<apex-domain>`), concise, no marketing fluff:
```
<apex-domain> — <repo role>: <stack/scope>
```
- App monorepo — `<apex-domain> — product monorepo: PWA (React) + BFF (Hono/Lambda) + app infra (Terraform)`
- Shared infra — `<apex-domain> — shared infrastructure: regional WAF baseline (Terraform)`
- Skills plugin — `<apex-domain> — Claude Code skills library: reusable engineering workflows`

## Language
Everything published on GitHub is in **English** — repo descriptions, READMEs, `docs/` + `CLAUDE.md`, commit and PR text, and Issues. The product **UI content is pt-BR** and is a separate concern (it never dictates the language of the engineering artifacts).

## Pros & cons
**Pros**
- One capability for OIDC, secrets/environments, GitFlow, deploys, and the Issues backlog.
- No long-lived AWS keys (OIDC); pipelines independent per repo.
**Cons**
- A large umbrella skill covering many concerns.
- GitHub-platform lock-in.
