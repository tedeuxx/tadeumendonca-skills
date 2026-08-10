---
description: Apply purely numeric SemVer with bump-my-version — what major, minor and patch mean for the artifact, the tag name and bump-commit loop guard, and the token the bump push needs. Use when cutting a release, deciding which part to bump, or debugging a version workflow that re-triggers itself. Not for the pipeline wiring around it (see github-actions).
family: workflow
---

Apply the semantic-versioning + tagging rules (bump-my-version) in any <project> repo.

Context: $ARGUMENTS

The single source of truth for **versioning and git tags** across the repos. The numeric-SemVer **scheme** is identical everywhere; the **trigger model differs by repo role** — every repo whose `main` produces something consumable auto-bumps on merge (`version-main.yml`, or `version-develop.yml` under GitFlow), and a deliberate minor/major is cut on demand via `release.yml`. `/github-actions` owns the branch model.

**A consumed artifact is not one thing — split by how it's consumed:**
- **Marketplace-distributed plugin** (`<project>-skills`) — **auto-bumps the PATCH on every merge to `main`** (`version-main.yml`) and publishes a Release, because the marketplace only serves *published* versions and an unreleased `main` is invisible to the installed plugin. **Publishing ≠ forcing adoption:** each consumer opts in via `/plugin update`, so publishing on every merge has no downside and removes the "merged but never shipped" failure mode. Deliberate minor/major via `release.yml`. (Methodology ADR-0005.)
- **Semver-pinned library** (an npm dependency a consumer locks) — releases **deliberately**, because its tag *is* a consumer lockfile and every tag invites a version resolution. Here `release.yml` (`workflow_dispatch`) is the trigger and pushes do not auto-bump.

A **deployed** repo — a site or service whose merge to `main` *is* the deploy — is a **deploy-model** repo: `main` auto-bumps the patch on merge (`version-main.yml`), because the version's job there is to name what is live, and something went live either way. The test is not what the repo contains but **who acts on the number**: a consumer resolving a dependency (deliberate release) or an operator identifying a running build (auto-bump).

## Scheme — purely numeric SemVer
`MAJOR.MINOR.PATCH` only — **no `-dev` / pre-release suffix** (explicitly rejected). `VERSION` starts at `0.1.0`. Tags are `vX.Y.Z`.

## `.bumpversion.toml` (same in every repo)
```toml
[tool.bumpversion]
current_version = "0.1.0"
parse           = "(?P<major>\\d+)\\.(?P<minor>\\d+)\\.(?P<patch>\\d+)"
serialize       = ["{major}.{minor}.{patch}"]     # numeric only — no pre-release part
tag             = true
tag_name        = "v{new_version}"
commit          = true
message         = "bump: {current_version} → {new_version}"   # MUST match the loop guard
tag_message     = "bump: {current_version} → {new_version}"
allow_dirty     = false

[[tool.bumpversion.files]]
filename = "VERSION"
```
> Add a `[[tool.bumpversion.files]]` entry per file that **also** carries the version (e.g. `package.json`, `openapi.json`, or — in the skills repo — `.claude-plugin/plugin.json`) so they bump in lockstep with `VERSION`.

## When each part bumps
- **push to `develop`** → `version-develop.yml` runs `bump-my-version bump patch` → `0.1.0 → 0.1.1 → …` → commit + tag `vX.Y.Z`.
- **push to `main`** → `version-main.yml` reads the merged PR's `semver:` label and bumps **that** part (resetting lower parts), then tags **and** creates a GitHub Release:
  - `semver:major` → major · `semver:minor` → minor (**default**) · `semver:patch` → patch.
- PR labels `semver:major | semver:minor | semver:patch` are required before merge to `main` (label set owned by the Issues backlog — `/github-actions`).

## Release notes (the GitHub Release)
`version-main` publishes a **GitHub Release** for the tag with notes **auto-categorized from the conventional-commit subjects** in the commit range since the **previous release** — `feat`→Features, `fix`→Fixes, `docs`→Documentation, `refactor`→Refactoring, `ci|chore|build|test`→CI & chores, plus a "Full changelog" compare link. Two reasons it uses the *previous release* (via `gh release list`) and not the previous **tag**: (a) `develop` auto-tags **every** commit (`v0.1.x`), so a tag-to-tag range between releases is ~empty; only `main` publishes Releases. (b) GitFlow ships **one** release PR, so notes come from the **commit log**, not the single PR. Net: **commit messages _are_ the changelog** — write `type: subject` (conventional commits). (`--generate-notes` alone would show only the lone release PR.)

## Loop guard (critical)
Bump commits use message `bump: {current} → {new}`; **both workflows skip any commit whose message starts with `bump:`**. The workflows push with the `VERSION_BUMP_TOKEN` PAT (which retriggers CI), so this message MUST stay aligned with the guard via `message`/`tag_message` above — otherwise CI loops infinitely.

## Required secret
`VERSION_BUMP_TOKEN` — a GitHub fine-grained PAT with `contents: write` + `workflows: write` (lets the bump commit/tag push and bypass PR protection as an admin actor). See `/github-actions` for secrets/environments.

## Conventions
- Same scheme/threshold in all repos — never a per-repo variant.
- The version is the contract stamp: the API's OpenAPI `info.version` == the `VERSION` file of the repo that ships it (`/openapi`) — generated from it at build time, never typed twice, so a published contract can always be traced back to the exact tag that produced it.

## Post-release: back-merge `main → develop`
After a release to `main`, the version-bump commit + tag live only on `main`, so `develop`'s `VERSION` lags. **Back-merge `main` into `develop`** so the lineage reconciles and the next dev work continues from the released version (e.g. `0.2.0` → next `develop` push → `0.2.1`):
```bash
git checkout develop && git merge --no-ff origin/main -m "chore: back-merge main into develop" && git push
```
Skipping it leaves `develop` on an older minor (e.g. `0.1.x`) while `main` is `0.2.x` — harmless for consumers (they pin `main` tags) but confusing. Do it **once per release**.

## Pros & cons
**Pros**
- Automated, consistent numeric tags across all repos; loop-guarded; PR-label-driven on main.
**Cons**
- Numeric-only — no pre-release channel (a deliberate rejection of `-dev`).
- Requires the `VERSION_BUMP_TOKEN` PAT.
