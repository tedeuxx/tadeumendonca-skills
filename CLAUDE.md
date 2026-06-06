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

These are Claude Code slash-commands under `.claude/commands/`. A consuming repo (`-iac`, `-api`,
`-fed`) needs that directory present so Claude Code picks the commands up when you work inside it.

**Recommended — vendor a pinned release (reproducible):** copy `.claude/commands` from a tagged
release into the consuming repo and **commit it**, so every dev + CI gets the exact same guidance.
Update with a controlled bump via a small script in the consuming repo:

```bash
# scripts/sync-skills.sh — pins the consuming repo to a skills version
REF="${1:-v0.2.0}"
TMP=$(mktemp -d)
git clone --depth 1 --branch "$REF" https://github.com/<github-org>/tadeumendonca-skills "$TMP"
rm -rf .claude/commands && cp -R "$TMP/.claude/commands" .claude/commands
echo "$REF" > .claude/SKILLS_VERSION        # record the pinned version in the repo
rm -rf "$TMP" && git add .claude && echo "skills synced to $REF"
```

**Local dev / skill authoring — symlink (always tip, not pinned):**

```bash
ln -s ../tadeumendonca-skills/.claude/commands .claude/commands             # per-repo
ln -s ~/git-reps/tadeumendonca-skills/.claude/commands ~/.claude/commands   # global (all projects)
```

**Git submodule** — add the repo as a submodule at a tag and symlink `.claude/commands` to it
(explicit pin without vendoring the content).

Once present, the commands appear in Claude Code grouped by capability (`/architecture/...`,
`/backend/...`, `/frontend/...`, `/infrastructure/...`, `/workflow/...`). The skills are **generic**
(`<project>` / `<apex-domain>` placeholders) — Claude substitutes the real values per project
(in `-iac`, these become `var.project` / `var.apex_domain`).

### Usage

Type the command and pass context after it — Claude receives it as `$ARGUMENTS`:

```
/backend/lambda-handler posts
/frontend/pagination articles
/infrastructure/cognito staging
/workflow/github-actions production
```

### Releasing a version

Numeric SemVer, automated (`/workflow/versioning`). `develop` auto-bumps **patch** on each push.
To cut a deliberate release, open a PR `develop → main` with the bump label:

```bash
gh pr create --base main --head develop --title "release: v0.2.0" --label semver:minor
# on merge, version-main.yml bumps the version, tags vX.Y.Z, and creates the GitHub Release
```

Consuming repos then run `scripts/sync-skills.sh vX.Y.Z` to adopt it. Pin to a tag for
reproducibility; never depend on `develop` tip in CI.

---

## Command reference

### architecture/ (1)

| Command | Purpose |
|---|---|
| `/architecture/fed-spa-bff` | Blueprint: SPA + BFF + modular-monolith backend (auth external); links component skills |

### backend/ (20)

| Command | Purpose |
|---|---|
| `/backend/framework-hono` | Hono framework + middleware wiring (logger/error/audit/authorize); routing, zod-openapi |
| `/backend/openapi` | Contract auto-maintained from code (agnostic): versioned, committed root copy, AWS overlay |
| `/backend/bff` | Backend-for-Frontend: API GW fronts only it (root routes); auth external, no auth code |
| `/backend/lambda-handler` | Implement a BFF domain module (Hono routes + audit + DocumentDB) |
| `/backend/document-db` | DocumentDB: connection singleton, collections, queries, indexes, cursor pagination |
| `/backend/audit-middleware` | Audit trail (conceptual): what's captured + the audits document shape |
| `/backend/action-types` | Action types (conceptual): audit + RBAC + feature toggles |
| `/backend/error-handling` | Throw AppError/NotFoundError/Unauthorized — never return 4xx |
| `/backend/logging` | Structured logging via Powertools Logger (JSON, level per env) |
| `/backend/metrics` | OTel metrics → ADOT collector → CloudWatch (awsemf), no AMP |
| `/backend/tracing` | Powertools Tracer / X-Ray: segments, annotations, downstream capture |
| `/backend/environment-config` | dotenv per env + typed config accessor (non-secrets only) |
| `/backend/secrets-management` | Sensitive values from Secrets Manager at runtime (cached) |
| `/backend/redis-cache` | ElastiCache Redis cache-aside, fail-open, TTLs, invalidation |
| `/backend/notifications` | Email via SES + SNS async fan-out; subscriptions |
| `/backend/og-image-generator` | OG image: satori JSX→SVG + resvg→PNG + S3 cache |
| `/backend/og-edge-handler` | Lambda@Edge 3-way: human passthrough / social OG / SEO crawler |
| `/backend/prerender` | Bot API: og-meta (head) + prerender (full HTML + JSON-LD) from DocDB |
| `/backend/postman` | API/contract tests (lives in api repo): Bearer JWT auth, collection run in CI |
| `/backend/coverage` | Backend quality/test/security gates (agnostic): lint, typecheck, ≥85% cov, audit, Sonar |

### frontend/ (18)

| Command | Purpose |
|---|---|
| `/frontend/framework-react` | React+Vite impl home: providers, Amplify, React Query, api client, routing (only place with React snippets) |
| `/frontend/authentication` | SPA auth (concept): Cognito SDK holds JWT → Bearer; API GW authorizer validates |
| `/frontend/authorization` | SPA UI gating by groups/claims (cosmetic); real authz is server-side |
| `/frontend/routing` | Route map + patterns: nested layouts, lazy, guards, 404, scroll (concept) |
| `/frontend/state` | State ownership: server→React Query, UI→Zustand, session→SDK |
| `/frontend/api-client` | BFF calls (concept): base URL from SSM, Bearer, 401, queries/mutations + invalidation |
| `/frontend/pagination` | Cursor pagination contract + infinite-scroll UX (concept) |
| `/frontend/forms` | Admin forms: controlled inputs + zod (mirrors BFF) → mutation |
| `/frontend/markdown` | Article markdown render: highlight + sanitize; consistent with edge prerender |
| `/frontend/design-system` | Cloudscape: which component per UI pattern (CV / feed / articles) |
| `/frontend/storybook` | Component library: stories, autodocs, interaction/visual tests |
| `/frontend/ux-states` | Loading/empty/error states + ErrorBoundary (consistent async UX) |
| `/frontend/environment-config` | Build-time VITE_* from SSM (concept); typed accessor |
| `/frontend/analytics` | GA4 (concept): SPA page_view per route + events |
| `/frontend/cloudwatch-rum` | RUM (concept): web vitals, JS errors, http; X-Ray end-to-end |
| `/frontend/seo` | Client SEO (concept): per-route meta + sitemap/robots + JSON-LD |
| `/frontend/playwright` | E2E browser tests (lives in fed repo): login via Cognito SDK, critical journeys |
| `/frontend/coverage` | Frontend quality/test/security gates (agnostic): lint, typecheck, ≥85% cov, E2E, audit, Sonar |

### infrastructure/ (21)

One skill per AWS service / tool used — each is the canonical parametrization + usage pattern (Terraform-resource detail). Cross-cutting policies are folded into their owning service (module sourcing + tagging → `terraform`; domain model → `route53`; encryption → `kms`; IAM authoring + OIDC roles → `iam`).

| Command | Purpose |
|---|---|
| `/infrastructure/terraform` | Terraform overall: versions/providers, TFC state, layout, **module-sourcing policy**, **tagging**, tfvars, CI |
| `/infrastructure/vpc` | VPC: subnets/NAT, S3 endpoint, lambda SG, traffic design (off-NAT) |
| `/infrastructure/route53` | Route53: **per-env domain model** + hosted-zone data source + A-alias records |
| `/infrastructure/acm` | ACM: per-env wildcard certs (reused, out-of-band), us-east-1, resolved by domain |
| `/infrastructure/s3` | S3: frontend(OAC)/artifacts/og-images + SSE + SSM |
| `/infrastructure/cloudfront` | CloudFront: OAC, TLS, cache policies, **SPA error routing + /og/***, Lambda@Edge, WAF |
| `/infrastructure/waf` | WAF CLOUDFRONT + REGIONAL (shared by API GW + Cognito) |
| `/infrastructure/lambda` | Lambda: nodejs22/arm64, in-VPC, **Pattern B**, tracing; og-edge exception |
| `/infrastructure/api-gateway` | API GW v2 HTTP: fronts only the BFF, per-route JWT authorizer, **contract reimport** |
| `/infrastructure/cognito` | Cognito: user pool, 3 groups, PKCE public client, **custom domain** |
| `/infrastructure/documentdb` | DocumentDB: cloudposse cluster params + TLS + Secrets Manager + SSM |
| `/infrastructure/elasticache` | ElastiCache Redis + AUTH in Secrets Manager + SSM |
| `/infrastructure/ses` | SES: domain verify + DKIM |
| `/infrastructure/sns` | SNS: async domain-event fan-out (notifications); cheapest pub/sub |
| `/infrastructure/iam` | IAM: **canonical role/policy authoring catalog** + OIDC deploy roles |
| `/infrastructure/secrets-manager` | Secrets Manager (provision): naming, jsonencode, ARN-only to SSM |
| `/infrastructure/ssm` | SSM Parameter Store: cross-repo config bus (namespace, read at deploy) |
| `/infrastructure/kms` | KMS + **encryption**: in-transit/at-rest matrix, AWS-managed vs CMK, rotation |
| `/infrastructure/cloudwatch` | CloudWatch: log groups/retention, flow logs, EMF metrics, alarms |
| `/infrastructure/cloudwatch-rum` | RUM: app monitor + Cognito guest identity pool (real-user monitoring) |
| `/infrastructure/cloudwatch-xray` | X-Ray: active tracing (API GW+Lambda), sampling rules, service map |

### workflow/ (6)

DevOps tooling. The GitHub/CI-CD capability (`github-actions`) is the umbrella for OIDC, secrets/environments, GitFlow branching, the api/fed deploy workflows, and the Issues backlog; the numeric-SemVer tagging rules are their own skill (`versioning`). Test-runner + gate skills live with their repo (`/backend/postman` + `/backend/coverage`, `/frontend/playwright` + `/frontend/coverage`); IaC checkov is in `/infrastructure/terraform`.

| Command | Purpose |
|---|---|
| `/workflow/github-actions` | GitHub/CI-CD capability: OIDC, secrets/envs, GitFlow branching, api/fed deploys, Issues backlog |
| `/workflow/versioning` | Semantic versioning + tags: numeric SemVer via bump-my-version, loop guard, PR labels |
| `/workflow/terraform-cloud` | TFC as remote-state backend; per-env workspaces; Local execution mode |
| `/workflow/sonarcloud` | SonarCloud quality gate (SAST + coverage + smells), blocks merge |
| `/workflow/claude-code` | Claude GitHub App: `@claude` assistant + automatic PR review (advisory, non-blocking) |
| `/workflow/documentation-standard` | Markdown + Mermaid only; diagram types per repo |

---

## Project conventions (enforced by every skill)

1. **No solo architectural decisions** — when ambiguous, ask the owner before deciding.
2. **Pipelines are independent per repository** — triggering one repo's pipeline from another
   is an antipattern. Never couple them.
3. **snake_case everywhere** — DB fields, TypeScript interfaces, request/response JSON. No
   mapping layer.
4. **REST** — resources are nouns; HTTP verbs express the action; paths and parameters in
   kebab-case. Resource ids in paths are **opaque** (slug or hashid/nanoid `public_id`), never
   enumerable/sequential.

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
