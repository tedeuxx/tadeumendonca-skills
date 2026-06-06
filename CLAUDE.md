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
| `/architecture/fed-spa-bff-monolith` | Blueprint: SPA + BFF + modular-monolith backend (auth external); links component skills |

### backend/ (16)

| Command | Purpose |
|---|---|
| `/backend/hono` | Hono framework + middleware wiring (logger/error/audit/authorize); routing, zod-openapi |
| `/backend/openapi` | Contract auto-maintained from code (agnostic): versioned, committed root copy, AWS overlay |
| `/backend/bff` | Backend-for-Frontend: API GW fronts only it (root routes); auth external, no auth code |
| `/backend/lambda-handler` | Implement a BFF domain module (Hono routes + audit + DocumentDB) |
| `/backend/docdb-connection` | DocumentDB TLS singleton + Secrets Manager pattern |
| `/backend/audit-middleware` | Audit trail (conceptual): what's captured + the audits document shape |
| `/backend/action-types` | Action types (conceptual): audit + RBAC + feature toggles |
| `/backend/error-handling` | Throw AppError/NotFoundError/Unauthorized — never return 4xx |
| `/backend/logging` | Structured logging via Powertools Logger (JSON, level per env) |
| `/backend/metrics` | OTel metrics → ADOT collector → CloudWatch (awsemf), no AMP |
| `/backend/environment-config` | dotenv per env + typed config accessor (non-secrets only) |
| `/backend/secrets-management` | Sensitive values from Secrets Manager at runtime (cached) |
| `/backend/redis-cache` | ElastiCache Redis cache-aside, fail-open, TTLs, invalidation |
| `/backend/og-image-generator` | OG image: satori JSX→SVG + resvg→PNG + S3 cache |
| `/backend/og-edge-handler` | Lambda@Edge 3-way: human passthrough / social OG / SEO crawler |
| `/backend/prerender` | Bot API: og-meta (head) + prerender (full HTML + JSON-LD) from DocDB |

### frontend/ (7)

| Command | Purpose |
|---|---|
| `/frontend/framework` | React + Vite SPA stack: router, React Query, Zustand, Cloudscape |
| `/frontend/cognito-pkce` | SPA auth via Cognito SDK (Amplify); JWT validated by the API GW authorizer |
| `/frontend/react-query-cursor` | Cursor-based pagination: useInfiniteQuery + infinite scroll |
| `/frontend/cloudscape-patterns` | Which Cloudscape components for CV sections, feed, articles |
| `/frontend/environment-config` | Vite VITE_* build-time env via typed env.ts (from SSM) |
| `/frontend/analytics` | Google Analytics (GA4): SPA page_view per route + events |
| `/frontend/seo` | Client-side SEO: react-helmet-async meta + sitemap + robots + JSON-LD |

### infrastructure/ (28)

**Services** — how we use each tool/AWS service (reusable):

| Command | Purpose |
|---|---|
| `/infrastructure/terraform` | Terraform overall: versions, providers, state(TFC), layout, tfvars, CI |
| `/infrastructure/terraform-cloud` | TFC as remote-state backend; per-env workspaces; Local execution |
| `/infrastructure/vpc-networking` | VPC: subnets/NAT, S3 endpoint, lambda SG, traffic design (off-NAT) |
| `/infrastructure/dns` | Route53: hosted-zone data source + A-alias records |
| `/infrastructure/acm` | ACM: out-of-band certs, us-east-1, resolved by domain (no ARNs in tfvars) |
| `/infrastructure/s3-buckets` | S3: frontend(OAC)/artifacts/og-images + SSM |
| `/infrastructure/cloudfront` | CloudFront: OAC, TLS, cache policies, Lambda@Edge, WAF assoc |
| `/infrastructure/waf` | WAF CLOUDFRONT + REGIONAL (shared by API GW + Cognito) |
| `/infrastructure/lambda` | Lambda: nodejs22/arm64, in-VPC, tracing, least-priv policy_statements |
| `/infrastructure/api-gateway` | API GW v2 HTTP: fronts only the BFF, custom domain, CORS, per-route JWT authorizer |
| `/infrastructure/cognito` | Cognito: user pool, 3 groups, PKCE public client, hosted UI |
| `/infrastructure/documentdb-cluster` | DocumentDB: cloudposse cluster + Secrets Manager + SSM |
| `/infrastructure/elasticache-redis` | ElastiCache Redis + AUTH in Secrets Manager + SSM |
| `/infrastructure/ses-email` | SES: domain verify + DKIM |
| `/infrastructure/iam` | IAM: least privilege, roles-not-users, OIDC for pipelines |
| `/infrastructure/secrets-manager` | Secrets Manager (provision): naming, jsonencode, ARN-only to SSM |
| `/infrastructure/cloudwatch` | CloudWatch: log groups/retention, flow logs, EMF metrics, alarms |
| `/infrastructure/kms` | KMS: AWS-managed by default, CMK only when needed, rotation |

**Patterns & policies** — compositions and cross-cutting decisions:

| Command | Purpose |
|---|---|
| `/infrastructure/module-policy` | Module sourcing: official-first, trusted non-official, no L3, raw as glue |
| `/infrastructure/environment-domains` | Per-env domain/subdomain naming (apex + service subdomains) |
| `/infrastructure/cloudfront-spa` | SPA delivery on CloudFront: error routing, /og/*, cache split |
| `/infrastructure/lambda-pattern-b` | Pattern B: IaC owns config, api repo ships code |
| `/infrastructure/api-gw-contract` | IaC seed shell + generated OpenAPI reimported by api repo |
| `/infrastructure/ssm-config-bus` | SSM as cross-repo config bus (namespace, read at deploy) |
| `/infrastructure/cognito-custom-domain` | Cognito hosted-UI custom domain + Route53 + SSM |
| `/infrastructure/iam-oidc-roles` | GitHub OIDC deploy roles (api, fed) + deploy policies |
| `/infrastructure/encryption` | TLS in-transit + at-rest everywhere |
| `/infrastructure/tagging` | Mandatory tags via default_tags (shared account) |

### workflow/ (8)

| Command | Purpose |
|---|---|
| `/workflow/gitflow` | GitFlow + numeric SemVer (develop=patch, main=label bump), loop guard |
| `/workflow/github-actions` | CI/CD platform: OIDC to AWS, secrets, environments, workflow set |
| `/workflow/sonarcloud` | SonarCloud quality gate (SAST + coverage + smells), blocks merge |
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
