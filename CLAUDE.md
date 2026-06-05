# tadeumendonca-skills

Claude Code custom slash command library for the **tadeumendonca.io** platform.
No AWS dependencies — these are project-specific **implementation guides** consumed by
developers (via Claude Code) while building `tadeumendonca-iac`, `-api`, and `-fed`.

Each command is a per-component guide: when the owner runs `/backend/lambda-handler posts`,
Claude reads the guide and knows exactly how to implement that piece following this project's
established patterns (middy, powertools, audit middleware, DocumentDB, snake_case, Pattern B,
SSM config bus, GitFlow, etc.).

All skills are created up front (before `v0.2.0`) and validated by the owner before each phase
starts — none are created ad-hoc during development.

---

## Installation

The commands live under `.claude/commands/`. Install by either symlinking or copying that
directory into the scope you want.

**Per-project (recommended — keeps the guides versioned alongside the consuming repo):**

```bash
# from inside a consuming repo (e.g. tadeumendonca-api)
ln -s ../tadeumendonca-skills/.claude/commands .claude/commands
# or copy instead of symlink:
cp -R ../tadeumendonca-skills/.claude/commands .claude/commands
```

**Global (available in every project on this machine):**

```bash
ln -s ~/git-reps/tadeumendonca-skills/.claude/commands ~/.claude/commands
# or copy:
cp -R ~/git-reps/tadeumendonca-skills/.claude/commands ~/.claude/commands
```

Once installed, the commands appear in Claude Code as slash commands grouped by capability
(`/backend/...`, `/frontend/...`, `/infrastructure/...`, `/workflow/...`).

### Usage

Type the command and pass context after it — Claude receives it as `$ARGUMENTS`:

```
/backend/lambda-handler posts
/frontend/react-query-cursor articles
/infrastructure/cognito-custom-domain staging
/workflow/deploy-api production
```

---

## Command reference

### backend/ (5)

| Command | Purpose |
|---|---|
| `/backend/lambda-handler` | Implement a Lambda fn: middy + powertools + audit + DocumentDB |
| `/backend/docdb-connection` | DocumentDB TLS singleton + Secrets Manager pattern |
| `/backend/audit-middleware` | Audit collection: actionType config, capture, collection schema |
| `/backend/og-image-generator` | OG image: satori JSX→SVG + resvg→PNG + S3 cache |
| `/backend/og-edge-handler` | Lambda@Edge: bot UA detection + `/og-meta` call + OG HTML |

### frontend/ (3)

| Command | Purpose |
|---|---|
| `/frontend/cognito-pkce` | PKCE auth: authStore (Zustand) + CallbackPage + RequireAuth |
| `/frontend/react-query-cursor` | Cursor-based pagination: useInfiniteQuery + infinite scroll |
| `/frontend/cloudscape-patterns` | Which Cloudscape components for CV sections, feed, articles |

### infrastructure/ (4)

| Command | Purpose |
|---|---|
| `/infrastructure/lambda-pattern-b` | Pattern B: IaC owns config, api repo ships code |
| `/infrastructure/api-gw-contract` | Seed spec in IaC + `openapi.yaml` ownership in api repo |
| `/infrastructure/ssm-config-bus` | SSM namespace, what to store, how repos read at deploy |
| `/infrastructure/cognito-custom-domain` | Module config + Route53 alias + SSM outputs |

### workflow/ (3)

| Command | Purpose |
|---|---|
| `/workflow/gitflow` | GitFlow: feature → develop → main + bump-my-version |
| `/workflow/deploy-api` | api deploy: esbuild → zip → S3 → update-function-code + reimport |
| `/workflow/deploy-fed` | fed deploy: vite build → S3 sync (split headers) → CF invalidation |

---

## Project conventions (enforced by every skill)

1. **No solo architectural decisions** — when ambiguous, ask the owner before deciding.
2. **Pipelines are independent per repository** — triggering one repo's pipeline from another
   is an antipattern. Never couple them.
3. **snake_case everywhere** — DB fields, TypeScript interfaces, request/response JSON. No
   mapping layer.
4. **REST** — resources are nouns; HTTP verbs express the action; paths and parameters in
   kebab-case.

---

## Versioning

Same automated semantic-versioning standard as every repo on the platform, via
`bump-my-version`:

- `VERSION` — current version (starts at `0.1.0`).
- `.bumpversion.toml` — bump config (parse/serialize, `tag_name = v{new_version}`).
- `.github/workflows/version-develop.yml` — on push to `develop`: `bump-my-version bump pre_n`
  → `vX.Y.Z-dev.N` → commit + tag.
- `.github/workflows/version-main.yml` — on push to `main`: reads the merged PR's semver label
  (`semver:major` | `semver:minor` (default) | `semver:patch`) → bump → `vX.Y.Z` → commit +
  tag + GitHub Release.

**Required secret:** `VERSION_BUMP_TOKEN` — a GitHub fine-grained PAT with `contents: write` +
`workflows: write`, so the version-bump commit does not retrigger CI in a loop.

**Required PR labels:** `semver:major` | `semver:minor` | `semver:patch` — set before merging
to `main`.
