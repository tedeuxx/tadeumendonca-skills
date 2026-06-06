Use GitHub Actions in tadeumendonca repos (CI/CD platform conventions).

Context: $ARGUMENTS

The CI/CD platform for every repo. How we use it:

## Auth to AWS — OIDC, no long-lived keys
Workflows assume an AWS role via **GitHub OIDC** (`aws-actions/configure-aws-credentials` with `role-to-assume` + `permissions: id-token: write`). The role ARN comes from SSM (`/infrastructure/iam-oidc-roles`). **No `AWS_ACCESS_KEY_ID` secrets.**

## Secrets & environments
- Repo secrets: `VERSION_BUMP_TOKEN`, `CLAUDE_CODE_OAUTH_TOKEN`, `SONAR_TOKEN`, `TFC_API_TOKEN` (iac), `AWS_OIDC_ROLE_ARN` (api/fed).
- **Environments:** `staging` (no rules) + `production` (required reviewer) — production deploys gate on environment approval.

## Workflow set (per repo)
- `ci.yml` — PR: lint + typecheck + tests + **SonarCloud** scan + security gates (`/workflow/testing-coverage`, `/workflow/sonarcloud`).
- `deploy.yml` — develop→staging (auto), main→production (approval) (`/workflow/deploy-api`, `/workflow/deploy-fed`); iac uses `terraform-plan.yml` + `terraform-deploy.yml`.
- `version-develop.yml` / `version-main.yml` — numeric SemVer bump (`/workflow/gitflow`).
- `claude.yml` + `claude-code-review.yml` — Claude GitHub App (assistant + auto review).

## Conventions
- **`concurrency`** groups to avoid overlapping deploys/version bumps (`cancel-in-progress: false` for version/deploy).
- Pin action versions (`@v4`); least-privilege `permissions:` per job (default read-only; `id-token: write` only where OIDC is needed).
- The version-bump commit (message `bump:`) is skipped by the version workflows to avoid CI loops (`/workflow/gitflow`).
- Pipelines are **independent per repo** — never trigger one repo's pipeline from another.
