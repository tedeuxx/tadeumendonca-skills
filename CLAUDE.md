# tadeumendonca-skills

Claude Code custom slash command library for the **tadeumendonca.io** platform.
No AWS dependencies — these are project-specific **implementation guides** consumed by
developers (via Claude Code) while building `tadeumendonca-iac`, `-api`, and `-fed`.

Each command is a per-component guide: when the owner runs `/backend/lambda-handler posts`,
Claude reads the guide and knows exactly how to implement that piece following this project's
established patterns (Hono, powertools, audit middleware, DocumentDB, snake_case, Pattern B,
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

### architecture/ (1)

| Command | Purpose |
|---|---|
| `/architecture/fed-spa` | Blueprint: SPA + BFF + serverless backend; links every component skill |

### backend/ (16)

| Command | Purpose |
|---|---|
| `/backend/framework` | Hono on Lambda: OpenAPIHono adapter, routing, middleware, zod-openapi |
| `/backend/openapi` | Auto-generate OpenAPI from Hono+zod (createRoute); spec for API GW reimport |
| `/backend/bff` | Backend-for-Frontend: server-side OIDC PKCE + session cookie + API proxy |
| `/backend/lambda-handler` | Implement a Lambda fn: Hono app + routes + audit + DocumentDB |
| `/backend/docdb-connection` | DocumentDB TLS singleton + Secrets Manager pattern |
| `/backend/audit-middleware` | Audit collection: actionType config, capture, collection schema |
| `/backend/action-types` | Central action-type constants, declared statically per handler |
| `/backend/error-handling` | Throw AppError/NotFoundError/Unauthorized — never return 4xx |
| `/backend/logging` | Structured logging via Powertools Logger (JSON, level per env) |
| `/backend/metrics` | OTel metrics → ADOT collector → CloudWatch (awsemf), no AMP |
| `/backend/environment-config` | dotenv per env + typed config accessor (non-secrets only) |
| `/backend/secrets-management` | Sensitive values from Secrets Manager at runtime (cached) |
| `/backend/redis-cache` | ElastiCache Redis cache-aside, fail-open, TTLs, invalidation |
| `/backend/og-image-generator` | OG image: satori JSX→SVG + resvg→PNG + S3 cache |
| `/backend/og-edge-handler` | Lambda@Edge 3-way: human passthrough / social OG / SEO crawler |
| `/backend/prerender` | Bot API: og-meta (head) + prerender (full HTML + JSON-LD) from DocDB |

### frontend/ (6)

| Command | Purpose |
|---|---|
| `/frontend/framework` | React + Vite SPA stack: router, React Query, Zustand, Cloudscape |
| `/frontend/cognito-pkce` | SPA auth via BFF session (OIDC PKCE handled by /backend/bff) |
| `/frontend/react-query-cursor` | Cursor-based pagination: useInfiniteQuery + infinite scroll |
| `/frontend/cloudscape-patterns` | Which Cloudscape components for CV sections, feed, articles |
| `/frontend/environment-config` | Vite VITE_* build-time env via typed env.ts (from SSM) |
| `/frontend/seo` | Client-side SEO: react-helmet-async meta + sitemap + robots + JSON-LD |

### infrastructure/ (19)

| Command | Purpose |
|---|---|
| `/infrastructure/module-policy` | Module sourcing: official-first, trusted non-official, no L3, raw as glue |
| `/infrastructure/terraform-repo-structure` | Canonical root, per-env tfvars, providers, TFC remote state/workspaces, checkov |
| `/infrastructure/vpc-networking` | vpc.tf: subnets/NAT, S3 endpoint, lambda SG, traffic design (off-NAT) |
| `/infrastructure/dns` | Route53: hosted-zone data source + A-alias records (CF/API/Cognito) |
| `/infrastructure/documentdb-cluster` | data.tf: cloudposse docdb + Secrets Manager + SSM |
| `/infrastructure/elasticache-redis` | cache.tf: cloudposse redis + AUTH in Secrets Manager + SSM |
| `/infrastructure/s3-buckets` | storage.tf: frontend(OAC)/artifacts/og-images + SSM |
| `/infrastructure/cloudfront-spa` | frontend.tf: CloudFront + OAC + Lambda@Edge + SPA error routing |
| `/infrastructure/waf` | WAF CLOUDFRONT + REGIONAL (shared by API GW + Cognito) |
| `/infrastructure/iam-oidc-roles` | iam.tf: deploy policies + assumable-role-with-oidc (api, fed) |
| `/infrastructure/ses-email` | auth.tf: SES domain verify + DKIM (fn-notifications) |
| `/infrastructure/lambda-pattern-b` | Pattern B: IaC owns config, api repo ships code |
| `/infrastructure/api-gw-contract` | IaC seed shell + generated OpenAPI (from code) reimported by api repo |
| `/infrastructure/ssm-config-bus` | SSM namespace, what to store, how repos read at deploy |
| `/infrastructure/cognito-custom-domain` | Module config + Route53 alias + SSM outputs |
| `/infrastructure/environment-domains` | Per-env domain/subdomain naming pattern (apex + service subdomains) |
| `/infrastructure/encryption` | TLS in-transit + at-rest everywhere (CF/API/DocDB/Redis/S3/Secrets) |
| `/infrastructure/kms` | KMS policy: AWS-managed by default, CMK only when needed, rotation |
| `/infrastructure/tagging` | Mandatory tags via default_tags for a shared account (Project/Env/ManagedBy) |

### workflow/ (6)

| Command | Purpose |
|---|---|
| `/workflow/gitflow` | GitFlow + numeric SemVer (develop=patch, main=label bump), loop guard |
| `/workflow/deploy-api` | api deploy: esbuild → zip → S3 → update-function-code + reimport |
| `/workflow/deploy-fed` | fed deploy: vite build → S3 sync (split headers) → CF invalidation |
| `/workflow/issue-backlog` | GitHub Issues: labels, milestones, templates, auto-maintained backlog |
| `/workflow/testing-coverage` | Quality/test/security gates: lint, typecheck, ≥85% cov, E2E, checkov, audit |
| `/workflow/documentation-standard` | Markdown + Mermaid only; diagram types per repo |

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

Purely **numeric SemVer** `MAJOR.MINOR.PATCH` — no `-dev` pre-release suffix.

- `VERSION` — current version (starts at `0.1.0`).
- `.bumpversion.toml` — bump config; `parse`/`serialize` numeric only, `tag_name = v{new_version}`,
  `message = tag_message = "bump: {current_version} → {new_version}"` (CI loop guard).
- `.github/workflows/version-develop.yml` — on push to `develop`: `bump-my-version bump patch`
  → `0.1.0 → 0.1.1 → …` → commit + tag.
- `.github/workflows/version-main.yml` — on push to `main`: reads the merged PR's semver label
  (`semver:major` | `semver:minor` (default) | `semver:patch`) → bump → `vX.Y.Z` → commit +
  tag + GitHub Release.

**Required secret:** `VERSION_BUMP_TOKEN` — a GitHub fine-grained PAT with `contents: write` +
`workflows: write`. The workflows skip commits whose message starts with `bump:`, so the
version-bump commit does not retrigger CI in a loop.

**Required PR labels:** `semver:major` | `semver:minor` | `semver:patch` — set before merging
to `main`.
