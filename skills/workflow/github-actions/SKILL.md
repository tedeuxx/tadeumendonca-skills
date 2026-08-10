---
description: Wire GitHub Actions for a repo — per-job OIDC into AWS, secrets and environments, the branching model, the build and deploy workflows, and the Issues backlog conventions. Use when adding or reviewing a workflow, granting CI a role to assume, or setting up a repo's branching and protection. Not for the tagging rules (see versioning), the loop model itself (see dev-loop), or the Terraform configuration CI runs (see terraform).
---

Use GitHub for <project> repos — the CI/CD capability (Actions, branching + versioning, deploys, issues). Branching comes in **two models** — see *Branching* below; pick the repo's before configuring anything.

Context: $ARGUMENTS

The single GitHub/CI-CD capability skill: the Actions platform, the branching + numeric-versioning model, the per-repo deploy workflows, and the Issues backlog all live here. Pipelines are **independent per repo** — never trigger one repo's pipeline from another.

> **How to read this skill.** Like the roster's OFF personas, it **defines** the full CI/CD capability so it's reusable, but a given repo **enables** only what its architecture needs. The **active** shape for a static, backend-less, single-environment site is the frontend deploy + the infra runner under `trunk-single-env`. The **backend-ful / multi-env** pieces (the BFF deploy role and section, the monorepo, `TEST_USER_*`, `gitflow` staging→production) are marked **“backend-ful reference (OFF in a static repo)”** — kept for a project that turns them on, not describing the static repo.

## Pipeline roles & AWS auth (OIDC) — what CI can do in the account
Every pipeline assumes a dedicated AWS role via **GitHub OIDC** (`aws-actions/configure-aws-credentials` + `permissions: id-token: write`) — **no `AWS_ACCESS_KEY_ID` secrets**. A deploy role has two halves: the **trust policy = the OIDC handshake** (WHO may assume — the repo's **immutable** OIDC subject `repo:<org>@<org_id>/<repo>@<repo_id>:*` on the pre-existing GitHub OIDC provider, see `/iam`) and a **least-privilege permissions policy** (WHAT it may do). All of this is a pipeline concern and lives here.

**Active roles for a static site (`-io`):**

| Pipeline role | Trust (OIDC subject) | Permissions (scoped, least-privilege) | Authored |
|---|---|---|---|
| **infra runner** `github-actions-<project>-iac` | the repo's immutable subject | broad provisioning — creates/updates/**deletes** all infra | **out-of-band** (it provisions everything, so can't self-manage) |
| **fed deploy** `github-actions-fed` | the repo's immutable subject | `s3:PutObject`/`DeleteObject`/`ListBucket` (site bucket); `cloudfront:CreateInvalidation` | Terraform (`iam.tf`) |

- The **fed deploy** role is created by the **iac Terraform** (`iam.tf`) and assumed via the `AWS_FED_OIDC_ROLE_ARN` env-scoped secret. The **infra runner** is bootstrapped **out-of-band** (chicken-and-egg — it provisions everything, so can't self-manage); its ARN is the `AWS_INFRA_OIDC_ROLE_ARN` env-scoped secret.
- **Runner-policy gotcha — role deletion:** the runner must be able to **delete** every resource it creates, including IAM roles. The AWS provider calls **`iam:ListInstanceProfilesForRole`** (to detach instance profiles) **before** `iam:DeleteRole` — if the policy has `CreateRole`/`DeleteRole` but not `ListInstanceProfilesForRole` (+ `iam:ListRoleTags`), a `terraform destroy` of any role fails with `AccessDenied` **mid-apply**, orphaning the role + leaving inconsistent state. Grant those from the start.
- The **GitHub OIDC provider** itself is **pre-existing** (landing zone), referenced by `provider_url`, not created. Confused-deputy guard: OIDC trust uses `StringLike` on `token.actions.githubusercontent.com:sub`.

> **Backend-ful reference (OFF in a static repo).** A project with a backend adds a **bff deploy** role `github-actions-api-<env>` (`lambda:UpdateFunctionCode`/`PublishVersion`/`GetFunction*`; `apigateway:PUT`/`POST`/`GET` on `/restapis/*`; `s3` artifacts; `ssm:GetParameter*` on `/{env}/*`), assumed via `AWS_BFF_OIDC_ROLE_ARN`. Under `gitflow-multi-env` every role is also **per-env** (`github-actions-{…-iac,bff,fed}-<env>`) so a leaked staging token can't assume the prod role, and each role's trust can be branch-pinned (`:ref:refs/heads/develop`→staging, `…/main`→production).

## Secrets & environments
**ONE standard across every repo — never decide per repo.** A secret has two independent axes, each fixed by rule: **SCOPE** (repository vs environment secret) and **NAME**. Audit a repo by listing both levels: `gh secret list -R <repo>` **and** `gh secret list -R <repo> --env <name>`. See [[secrets-scope-naming-standard]].

**SCOPE — repository vs environment secret — decided by ONE question: does the value change per environment?**
- **Environment secret** (a GitHub Environment scopes it, same name / different value per env) = **every AWS OIDC role ARN** — `AWS_INFRA_OIDC_ROLE_ARN`, `AWS_FED_OIDC_ROLE_ARN` (and `AWS_BFF_OIDC_ROLE_ARN` when there's a backend).
- **Repository secret** = the SAME value for every environment — reserved for the account/org-wide **tooling tokens only**: `TFC_API_TOKEN`, `SONAR_TOKEN`, `CLAUDE_CODE_OAUTH_TOKEN`, `VERSION_BUMP_TOKEN`.
- **Rule of thumb:** value differs per env (every deploy/runner role) → **environment** secret (same name in each Environment, **no** `-staging`/`-production` suffix — the Environment supplies it). Single value shared across all envs → **repository** secret.

**NAME — one scheme:**
- **AWS OIDC role ARNs:** `AWS_<LAYER>_OIDC_ROLE_ARN`, `LAYER` ∈ `INFRA` (infra runner) · `FED` (· `BFF` when there's a backend) — **all environment-scoped**. **No legacy `AWS_ROLE_ARN`** and **no** generic `AWS_OIDC_ROLE_ARN` — the layer in the name keeps distinct least-privilege roles unambiguous.
- **Third-party credentials:** keep the name the consuming action mandates (`SONAR_TOKEN`, `CLAUDE_CODE_OAUTH_TOKEN`); otherwise `<PROVIDER>_<KIND>_TOKEN` — `TFC_API_TOKEN`, `VERSION_BUMP_TOKEN`.

**Canonical per-repo set — every repo audits against this one list:**

| Secret | Scope | static site (`-io`) | skills plugin | backend-ful reference |
|---|---|:--:|:--:|:--:|
| `AWS_INFRA_OIDC_ROLE_ARN` | environment | ✓ | — | ✓ |
| `AWS_FED_OIDC_ROLE_ARN` | environment | ✓ | — | ✓ |
| `AWS_BFF_OIDC_ROLE_ARN` | environment | — | — | ✓ *(bff)* |
| `TFC_API_TOKEN` | repository | ✓ | — | ✓ |
| `SONAR_TOKEN` | repository | ✓ | — | ✓ |
| `CLAUDE_CODE_OAUTH_TOKEN` | repository | ✓ | ✓ | ✓ |
| `VERSION_BUMP_TOKEN` | repository | ✓ | ✓ | ✓ |
| `TEST_USER_USERNAME` / `TEST_USER_PASSWORD` | environment | — *(no auth)* | — | ✓ *(authed e2e)* |

- **Trade-off / migration:** re-scoping a secret (repo→environment) or renaming it means the GitHub secret store AND the consuming jobs change **together** — the deploy/apply jobs declare `environment:`, so the same `secrets.AWS_*_OIDC_ROLE_ARN` ref resolves from the Environment once the env secret exists; sequence: **add** the env secret → prove on a PR/apply → **remove** the old repo-level secret last.
- **Durable facts:** `VERSION_BUMP_TOKEN` is a fine-grained PAT of its own (name it for its job — `<project>-version-bump` — so a token audit can tell at a glance what breaks if it is revoked) — perms MUST be Contents:write + Workflows:write (a missing Workflows scope 403s the bump). The **owner** runs `gh secret set` for any credential value (the agent can't handle it); `claude setup-token` needs a real TTY.

**Environments:** under `trunk-single-env` there is a **single** GitHub Environment (it scopes the role ARNs as env secrets) and **no** approval gate at the environment level — the gate is the merge itself. Under `gitflow-multi-env`, `staging` (no rules) + `production` (required reviewer) — production deploys gate on environment approval. Either way **every** role ARN lives as an environment secret.

## Workflow set (per repo)
- **The build/test gate** — for the static site it's **`build-test.yml`** (PR): lint + typecheck + tests (coverage ≥85%) + build + **Playwright E2E** + **SonarCloud** gate, path-filtered to the SPA's directory. (A backend-ful repo names it `ci.yml` and adds `/coverage`.) The infra gate is **`infra-plan.yml`** (checkov + `fmt`/`validate`/`plan`), path-filtered to `iac/`.
- **Required check + trigger `paths:` filter = docs PRs BLOCKED forever (gotcha).** If a *required* status check is gated by a trigger-level `on.pull_request.paths:` filter, a PR touching none of those paths (a docs-only `CLAUDE.md` PR) never starts the workflow, so the required check never reports — branch protection then leaves the PR permanently `BLOCKED` (and `--admin` bypass defeats the gate). **Fix:** drop `paths:` from the `pull_request` trigger so the job ALWAYS runs (and always reports), then gate the heavy steps inside the job with a `dorny/paths-filter@v3` step + `if: steps.changes.outputs.<filter> == 'true'`. Docs-only PRs run the job and finish **green** in seconds. Keep the `push` trigger's `paths:` (SonarCloud baseline only on real changes). Don't gate the whole *job* with `if:` — gate the *steps* so the job still reports success.
- **Deploy** — for the static site, **`deploy.yml`** (one job on merge to `main`) + **`infra-apply.yml`** (Terraform apply on merge, when `iac/` changed). Under `gitflow-multi-env` a `deploy.yml` does develop→staging (auto), main→production (approval).
- **`version-main.yml`** — numeric SemVer bump (below). `trunk-single-env` needs only the `main` one; `gitflow-multi-env` adds `version-develop.yml`.
- **`claude.yml` + `claude-code-review.yml`** — Claude GitHub App (assistant + auto review) — `/claude-code`.
- **`concurrency`** groups to avoid overlapping deploys/version bumps (`cancel-in-progress: false`); **SHA-pin** third-party actions (supply-chain); `npm ci --ignore-scripts`; least-privilege `permissions:` per job (`id-token: write` only where OIDC is needed).

## Branching — pick the loop model first
Branching follows the repo's loop model (`/dev-loop`). **Determine it before configuring protection or writing a deploy workflow** — a GitFlow layout on a single-environment repo creates a `develop` branch nothing merges to, and moves the required checks off the PR that actually ships.

**How to tell:** the repo's `CLAUDE.md` states it. Otherwise, count environments — **more than one → `gitflow-multi-env`; one (or none, for a consumed artifact) → `trunk-single-env`.**

### `trunk-single-env` (the active model — `-io` and the skills plugin)
```
main ←── feature/*
```
- **feature/*** (and `fix/*`, `docs/*`, `chore/*`): cut from `main`; PR → `main` required. Short-lived.
- **main**: the **only** long-lived branch, and the **working** branch. Protected (PR required, 0 approvals, no force-push/deletion), `enforce_admins=false` for the owner and the version-bump actor.
- **No `develop`, no `release/*`, no `hotfix/*`.** A hotfix is just another short-lived branch off `main`.
- **All required checks sit on the PR to `main`**: lint + typecheck + coverage + quality gate + security + the full regression. There is no downstream tier to defer any of them to, so a check moved off this PR is a check that never runs.
- **The merge deploys**, so it is the go/no-go. Never configure auto-merge into `main`.
- **Two variants of what "ships" means:**
  - *Deployed app* (`-io`) — merge to `main` triggers the deploy, and the version bump is automatic on push (patch), tagging `vX.Y.Z` + publishing a Release.
  - *Marketplace-distributed plugin* (the skills repo) — **every merge to `main` auto-bumps the patch and publishes a Release** (`version-main.yml`), because the marketplace only serves published versions; adoption is the consumer's opt-in (`/plugin update`), so publishing ≠ forcing. Deliberate minor/major via `release.yml`. (A *semver-pinned library*, by contrast, releases deliberately — its tag is a consumer lockfile.) See `/versioning` + methodology ADR-0005.
- **Merge strategy: real merge commits, never squash.** Set the default merge method to **merge commit** and **disable squash merging**; merge with `gh pr merge --merge`. Squashing collapses the per-commit **conventional-commit** history the categorized release notes are built from (`git log --no-merges`, see `/versioning`). See [[merge-strategy-no-squash]].

### `gitflow-multi-env` (backend-ful reference — OFF in a static repo)
```
main ←── release/* ←── develop ←── feature/*
     ←── hotfix/*
```
- **feature/***: from `develop`; PR → `develop`. **develop**: default branch; protected; auto-deploy to staging on merge. **main**: protected; production deploy requires GitHub Environment approval + reviewer. **hotfix/***: from `main`; merged to both `main` and `develop`.
- Protection on `main` + `develop`: require PR, **0 approvals**, `enforce_admins=false` so the owner and the `VERSION_BUMP_TOKEN` actor push directly; no force-push/deletion.

**Versioning & tags** — numeric SemVer via bump-my-version, with the `bump:` loop guard. Under `trunk-single-env`, on every push to `main` (patch) for a deployed app **or a marketplace plugin** (`version-main.yml`) — deliberate minor/major via `release.yml`; a semver-pinned library releases deliberately instead. Under `gitflow-multi-env`, on every push to `develop` (patch) and on `main` via a PR `semver:` label. All the rules live in **`/versioning`**. See [[versioning-numeric-semver]].

## Deploy — iac (Terraform)
Uses the **infra runner** OIDC role (see the roles table above — out-of-band, broad provisioning, role-deletion gotcha). State + locking live in Terraform Cloud, execution mode **Local** — GitHub runs `plan`/`apply` (`/terraform-cloud`); the `TFC_API_TOKEN` secret authenticates to TFC. The TFC **workspace name is load-bearing** — it selects the live state; a rename desync points Terraform at an empty workspace and `plan` proposes recreating everything.
- **`infra-plan.yml` (PR):** `checkov` (block on HIGH) → `terraform fmt -check` + `validate` → `plan` → post the plan as a PR comment.
- **`infra-apply.yml` (merge to `main`):** `apply` to the single environment. (Under `gitflow-multi-env`: merge to `develop` → apply staging (auto); merge to `main` → apply production, gated by the `production` Environment approval.)
- SonarCloud IaC analysis scans the Terraform in addition to checkov (complementary — `/sonarcloud`).

## Deploy — fed (the static site)
Role from the `AWS_FED_OIDC_ROLE_ARN` env secret.
```bash
# 1. build (Vite) + prerender each route (Playwright snapshot of vite preview) → the deploy artifact
npm ci --ignore-scripts && npm run build:static
# 2. S3 sync with split cache headers
aws s3 sync dist/ s3://$S3_BUCKET/ --delete --exclude index.html --cache-control "public,max-age=31536000,immutable"
aws s3 cp dist/index.html s3://$S3_BUCKET/index.html --cache-control "no-cache,no-store,must-revalidate"
# 3. CloudFront invalidation
aws cloudfront create-invalidation --distribution-id $CF_DIST_ID --paths "/*"
```
Hashed assets are immutable (content hash in filename); `index.html` is always `no-cache` so it references fresh asset hashes. There is **no runtime config to inject** — the site is static, content is markdown-in-repo prerendered at build time (no API URL, no Cognito). E2E + coverage are the **PR gate** (`build-test.yml`), not a post-deploy gate — a red gate blocks the merge, and the merge is the deploy.

> **Backend-ful reference (OFF in a static repo) — Deploy — api (the BFF).** A backend project deploys one BFF Lambda (+ an og-edge Lambda@Edge for external-URL unfurl) with the `AWS_BFF_OIDC_ROLE_ARN` role: build with esbuild → `aws lambda update-function-code` for the BFF and the edge fn (`publish-version` for the qualified edge ARN) → republish the API-Gateway contract generated from code (`/openapi`). A static site has none of this — it's here as the reusable pattern, not an active pipeline.

## Issues & backlog (GitHub Issues, per repo)
The product backlog is **GitHub Issues per repository** — no central backlog repo. Review open issues at session start (status/labels, close stale); on delivering a plan item, open/close its issue. Product ownership + prioritization stay with the **human** (the loop owns *how*, not *what*).

| Group | Labels |
|---|---|
| `type:` | `feature` · `bug` · `chore` · `docs` · `infra` |
| `priority:` | `high` · `medium` · `low` |
| `semver:` | `major` · `minor` (default) · `patch` — drives the bump on release to `main` |
| `status:` | `blocked` |

- **Conventions:** title `[area] short description`; set `type:`/`semver:` on creation, `priority:` when known; translate a plan's deliverables into one issue each at the start of implementation. (Milestones + `phase:` labels are optional and per-project — don't hardcode a retired roadmap.)

> **This label set is RETIRED in the owner's own repos (2026-08-02), and it is retired for a reason worth reading before copying it.** `type:` and `priority:` restate what a title and a stated order already say; `phase:` described a roadmap that ended; `status:blocked` survives as a bare `blocked`. Measured before deleting: of the fifteen labels, **eleven had never been applied to anything.**
>
> The live vocabulary is five labels, each with a named consumer — `product`, `content`, `ready`, `blocked`, `reader-facing`. See `/dev-loop`, *One vocabulary across every repo*, and the test a label has to pass: **something must query it, or it is decoration that ages.**
>
> The table above is **kept, not corrected**, because `semver:` is load-bearing under `gitflow-multi-env` — there the merged PR's label drives the bump (`/versioning`). A `trunk-single-env` artifact repo picks its part at dispatch and reads no label, which is why it went unused here. Read the table as *what this convention looks like where it applies*, not as a set to create by default.

## Repo metadata
GitHub repo **descriptions** follow one format — lead with the platform name (`<apex-domain>`), concise, no marketing fluff:
```
<apex-domain> — <repo role>: <stack/scope>
```
- Static site — `<apex-domain> — proof-of-engineering site: static SPA (React/Vite) on S3+CloudFront`
- Skills plugin — `<apex-domain> — Claude Code skills library: reusable engineering workflows`

Every repo in a platform leads with the **same** `<apex-domain>`, deliberately: the description is read in search results and on a profile, where repos appear detached from each other, so the shared prefix is what tells a reader they are one system rather than five side projects.
- *(Backend-ful reference)* App monorepo — `<apex-domain> — product monorepo: PWA (React) + BFF (Hono/Lambda) + app infra (Terraform)`

## Language
Everything published on GitHub is in **English** — repo descriptions, READMEs, `docs/` + `CLAUDE.md`, commit and PR text, and Issues. The product **UI content is pt-BR** and is a separate concern (it never dictates the language of the engineering artifacts).

## Pros & cons
**Pros**
- One capability for OIDC, secrets/environments, branching (both models), deploys, and the Issues backlog.
- No long-lived AWS keys (OIDC); pipelines independent per repo.
**Cons**
- A large umbrella skill covering many concerns.
- GitHub-platform lock-in.
