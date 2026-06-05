Reference guide for the GitFlow workflow in tadeumendonca.io repositories.

Repo: $ARGUMENTS

## Branch structure

```
main ←── release/* ←── develop ←── feature/*
     ←── hotfix/*
```

## Branch rules

- **feature/***: branches from `develop`; PR → `develop` required
- **develop**: default branch; protected (PR required); auto-deploy to staging on merge
- **main**: protected (PR required); deploy to production requires GitHub Environment approval + reviewer
- **hotfix/***: branches from `main`; merged to both `main` and `develop`

Protection on `main` + `develop`: require PR before merge, **0 approvals** (solo dev can't self-approve), `enforce_admins=false` so the owner and the `VERSION_BUMP_TOKEN` actor (version bot) push directly; no force-push/deletion.

## Versioning (bump-my-version) — purely numeric SemVer, no pre-release

Versions are `MAJOR.MINOR.PATCH` only — **no `-dev` suffix**. (`.bumpversion.toml`: `serialize = ["{major}.{minor}.{patch}"]`.)

**On push to develop:** `version-develop.yml` runs `bump-my-version bump patch` → `0.1.0 → 0.1.1 → …` → commit + tag `vX.Y.Z`.

**On push to main:** `version-main.yml` reads the merged PR label and bumps that part (resetting lower parts), then tags + creates a GitHub Release:
- `semver:major` → bump major
- `semver:minor` → bump minor (default)
- `semver:patch` → bump patch

## Loop guard (critical)

Bump commits use message `bump: {current} → {new}`; both workflows skip commits starting with `bump:`. Since the workflows push with a PAT (which retriggers CI), this message MUST stay aligned to the guard — otherwise CI loops infinitely. Set `message`/`tag_message` in `.bumpversion.toml`.

## Required secrets per repo

- `VERSION_BUMP_TOKEN` — GitHub fine-grained PAT with `contents: write` + `workflows: write` (lets the bump commit/tag push, and bypass the PR protection as an admin actor)

## PR labels (required on all repos)

`semver:major` | `semver:minor` | `semver:patch` — must be set before merge to main.
