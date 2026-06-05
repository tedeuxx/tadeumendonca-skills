Reference guide for the GitFlow workflow in tadeumendonca.io repositories.

Repo: $ARGUMENTS

## Branch structure

```
main ←── release/* ←── develop ←── feature/*
     ←── hotfix/*
```

## Branch rules

- **feature/***: branches from `develop`; PR → `develop` required
- **develop**: protected; auto-deploy to staging on merge
- **main**: protected; deploy to production requires GitHub Environment approval + reviewer
- **hotfix/***: branches from `main`; merged to both `main` and `develop`

## Versioning (bump-my-version)

**On merge to develop:** `version-develop.yml` runs `bump-my-version bump pre_n` → `v0.2.0-dev.3` → commit + tag

**On merge to main:** `version-main.yml` reads PR label:
- `semver:major` → bump major
- `semver:minor` → bump minor (default)
- `semver:patch` → bump patch

Produces `v0.2.0` → commit + tag + GitHub Release.

## Required secrets per repo

- `VERSION_BUMP_TOKEN` — GitHub fine-grained PAT with `contents: write` + `workflows: write` (prevents CI loop on version bump commit)

## PR labels (required on all repos)

`semver:major` | `semver:minor` | `semver:patch` — must be set before merge to main.
