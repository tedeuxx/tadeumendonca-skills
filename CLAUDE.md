# tadeumendonca-skills

Claude Code **plugin** (slash-command library) for the **tadeumendonca.io** platform — distributed
via the **marketplace in this repo** and reused across `tadeumendonca-pwa` (the product monorepo:
`apps/fed` + `apps/bff` + `iac/`) and `tadeumendonca-iac` (shared regional WAF only).
The commands are generic, reusable implementation guides (no AWS dependency to run).

Each command is a per-component guide: when the owner runs `/tadeumendonca-skills:backend/lambda-handler posts`,
Claude reads the guide and knows exactly how to implement that piece following this project's
established patterns (Hono, powertools, audit middleware, DynamoDB, snake_case, Pattern B,
SSM config bus, GitFlow, etc.).

---

## Mission — this repo is a CV differentiator (read this first)
This skills library is the owner's **public knowledge-transfer artifact**: a dense dump of his senior-engineer
**experience + implementation preferences**, externalized in public as proof of depth (he is repositioning
from "Architect / AWS Professional Services" to **Senior Software Engineer** at product companies — see the
strategic context). It is NOT a thin "what this project did" doc — each skill is a **dense, scenario-covering
architecture guide** that demonstrates judgment.

**The depth bar (how every AWS-service skill should read):**
- **The scenario space, not one config** — *when* to pick each option, as a decision tree.
- **Decision criteria + multi-dimensional trade-offs** — cost / security / scale / latency / ops — with rough
  numbers where they drive the call (e.g. NAT ≈ $33/mo/AZ; Interface endpoint ≈ $7/mo/AZ).
- **The owner's opinionated default + when he deviates** (the "My take" layer) — THIS is the differentiator;
  generic best-practice alone is not enough.
- **The nuances that bite** — the gotchas / war stories worth materializing.
- `commands/infrastructure/vpc.md` is the **density exemplar** — match it.

**Deep-dive authoring process (done in-place here):**
1. **Scaffold** the scenario space (Claude drafts the dense structure from sound practice + the platform repos).
2. **Elicit the owner's layer** — ask a few sharp questions (default posture? real triggers to deviate? rule
   of thumb? a war story?) and weave the answers into a **"My take / preference"** section.
3. Iterate per skill until it reads like a senior engineer's knowledge transfer. Go skill by skill / by domain.

**Hard principles:** **project-agnostic** — generic `<project>` / `<apex-domain>` placeholders, **NO** real
names/domains/ARNs/ids; **English** (it's published); **additive density** (deepen; never thin out good content).

**State (2026-06-21):** a thin `## Decision & trade-off` baseline has landed for `infrastructure/*` and
`backend/*`, plus the `vpc` deep exemplar; `frontend/*` is not started yet. The **deep-dive above is the
active workstream** — those baseline sections are scaffolding to deepen, not the goal.

---

## Installation (Claude Code plugin)

This repo is a **Claude Code plugin + marketplace** — the native way to reuse skills across
projects. Commands live in `commands/`; `.claude-plugin/marketplace.json` is the catalog and
`.claude-plugin/plugin.json` the manifest. **Nothing is published outside this git repo** — the
marketplace is just a metadata file the consumer points at.

**Consume it in a repo (`-pwa`, `-iac`)** — add the marketplace from this git + install:

```bash
claude plugin marketplace add tedeuxx/tadeumendonca-skills
claude plugin install tadeumendonca-skills@tadeumendonca
# or interactively: /plugin marketplace add tedeuxx/tadeumendonca-skills  then  /plugin install …
```

**Version it per repo (recommended):** commit a `.claude/settings.json` so every dev + CI on that
repo auto-gets the plugin when they trust the folder (copy the one in this repo):

```json
{
  "extraKnownMarketplaces": {
    "tadeumendonca": { "source": { "source": "github", "repo": "tedeuxx/tadeumendonca-skills" } }
  },
  "enabledPlugins": { "tadeumendonca-skills@tadeumendonca": true }
}
```

By default this tracks `main` (= the latest release). To **pin a release**, add `"ref": "v0.2.0"`
to the marketplace `source`. Refresh with `/plugin marketplace update` (or `claude plugin
marketplace update`). For **local skill authoring** (test edits to this repo, unpinned):
`claude --plugin-dir .`

The skills are **generic** (`<project>` / `<apex-domain>` placeholders) — Claude substitutes the
real values per project (in `-pwa/iac` and `-iac`, they become `var.project` / `var.apex_domain`).

### Usage

Plugin commands are **namespaced under the plugin name**. Type the command and pass context after
it (received as `$ARGUMENTS`):

```
/tadeumendonca-skills:backend/lambda-handler posts
/tadeumendonca-skills:infrastructure/cognito staging
/tadeumendonca-skills:workflow/github-actions production
```

### Releasing a version

**Trunk-based** — this repo is a *consumed dependency* (by `-pwa` + `-iac`), not an app with
environments, so it does **not** use GitFlow. There is one long-lived branch, **`main`**: skill
work lands via short-lived `feature/*` / `docs/*` PRs, and `main` is always releasable. Pushing to
`main` does **not** auto-version — the version is a deliberate, consumer-facing decision decoupled
from integration.

A release is cut **on demand** from the `release` workflow (numeric SemVer, `/workflow/versioning`):

```
GitHub → Actions → release → Run workflow → choose part (major | minor | patch)
# bumps VERSION + plugin.json, tags vX.Y.Z, pushes to main, publishes the GitHub Release.
```

What the SemVer part means **for a skills library** (the contract is the *invocation surface*):
- **major** — breaking: a command renamed/removed, a `$ARGUMENTS` contract changed, the namespace
  or `plugin.json` `name` restructured.
- **minor** — additive: a new skill/command, or substantial new capability.
- **patch** — content fix/deepening that does not change which commands exist or how they're called.

Consumers tracking `main` get the latest on the next `/plugin marketplace update`; **pinned
consumers** (recommended — the `ref` is their lockfile) bump their `ref` to the new tag deliberately.
Because tags are only ever cut by this workflow, **every `vX.Y.Z` tag is a reviewed release** and a
safe pin (no mid-development tags pollute the namespace).

---

## Command reference

### principles/ (4) — the drift-reducer

The harness's **principles layer**: how the owner builds software, so an agent's behavior doesn't drift. Cross-cutting (applies to every repo), distinct from the per-component how-to skills. Canonical summary in the root `PRINCIPLES.md`; deep validation via the `principles-guide` subagent (`agents/`); irreversible-floor enforcement via the shipped PreToolUse guard (`hooks/`).

| Command | Purpose |
|---|---|
| `/principles/engineering-philosophy` | The 11 principles in two tiers (non-negotiable floor + risk-calibrated judgment); the agent-led/human-residual spine |
| `/principles/verification-and-gates` | What "done" means: the thesis, Definition of Done, the 100% E2E+API regression invariant, gates by environment |
| `/principles/dev-loop` | End-to-end flow: roadmap intake → thin slice → local validate → staging → promote → prod; failure = revert + re-release |
| `/principles/permissions-and-environments` | Environment = git branch; IaC pipeline-only + infra-first; staging-backed local; allow/ask/deny zones; global + per-project; the guard hook |

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
| `/backend/lambda-handler` | Implement a BFF domain module (Hono routes + audit + DynamoDB) |
| `/backend/dynamodb` | DynamoDB: client singleton, per-entity tables, key/GSI access, cursor pagination (LastEvaluatedKey) |
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
| `/backend/prerender` | Bot API: og-meta (head) + prerender (full HTML + JSON-LD) from DynamoDB |
| `/backend/postman` | API/contract tests (lives in `apps/bff`): Bearer JWT auth, collection run in CI |
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
| `/frontend/playwright` | E2E browser tests (lives in `apps/fed`): login via Cognito SDK, critical journeys |
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
| `/infrastructure/lambda` | Lambda: nodejs22/arm64, non-VPC by default (VPC on demand), **Pattern B**, tracing; og-edge exception |
| `/infrastructure/api-gateway` | API GW (REST v1): fronts only the BFF, per-route Cognito authorizer, WAF-fronted, **contract via put-rest-api** |
| `/infrastructure/cognito` | Cognito: user pool, 3 groups, PKCE public client, **custom domain** |
| `/infrastructure/dynamodb` | DynamoDB: per-entity tables, on-demand, GSIs, PITR, IAM access, SSM table names |
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

### workflow/ (7)

DevOps tooling. The GitHub/CI-CD capability (`github-actions`) is the umbrella for OIDC, secrets/environments, GitFlow branching, the `apps/bff` + `apps/fed` deploy workflows, and the Issues backlog; the numeric-SemVer tagging rules are their own skill (`versioning`). Test-runner + gate skills live with their repo (`/backend/postman` + `/backend/coverage`, `/frontend/playwright` + `/frontend/coverage`); IaC checkov is in `/infrastructure/terraform`.

| Command | Purpose |
|---|---|
| `/workflow/github-actions` | GitHub/CI-CD capability: OIDC, secrets/envs, GitFlow branching, `apps/bff` + `apps/fed` deploys, Issues backlog |
| `/workflow/versioning` | Semantic versioning + tags: numeric SemVer via bump-my-version, loop guard, PR labels |
| `/workflow/terraform-cloud` | TFC remote-state backend; per-env workspaces; Local execution; **pipeline-only apply/destroy** |
| `/workflow/sonarcloud` | SonarCloud quality gate (SAST + coverage + smells), blocks merge |
| `/workflow/claude-code` | Claude GitHub App: `@claude` assistant + automatic PR review (advisory, non-blocking) |
| `/workflow/documentation-standard` | Markdown + Mermaid only; diagram types per repo |
| `/workflow/license` | Licensing standard: MIT `LICENSE` + manifest license field in every repo |

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
5. **IaC mutations are pipeline-only** — `terraform apply`/`destroy` run **only in CI** (plan on PR,
   apply on merge); never from a laptop. Local is read-only (`fmt`/`validate`/inspection `plan`).
   Destroying live infra = remove from config + merge (or a reviewed `workflow_dispatch` teardown).
   See `/workflow/terraform-cloud`.

---

## Versioning

Numeric SemVer via `bump-my-version`. **This repo deliberately diverges from the platform's
app-style "auto-bump on every push" standard** — because it is a *consumed plugin*, not a deployed
app, its version is a dependency contract, so it is bumped **only at an intentional release**, never
on integration. (Same reasoning that makes it trunk-based: policy follows the artifact's role.)

Purely **numeric SemVer** `MAJOR.MINOR.PATCH` — no `-dev` pre-release suffix.

- `VERSION` — current version.
- `.bumpversion.toml` — bump config; `parse`/`serialize` numeric only, `tag_name = v{new_version}`,
  `message = tag_message = "bump: {current_version} → {new_version}"` (CI loop guard); bumps
  `VERSION` + `.claude-plugin/plugin.json` in lockstep.
- `.github/workflows/release.yml` — **`workflow_dispatch` only** (Actions → release → Run workflow):
  takes a `part` input (`major` | `minor` (default) | `patch`) → bump → `vX.Y.Z` → commit on `main`
  → tag → GitHub Release with categorized notes. **No push trigger exists** — integration never
  versions; only this manual run does. Every tag is therefore a reviewed, pinnable release.

**Required secret:** `VERSION_BUMP_TOKEN` — a GitHub fine-grained PAT with `contents: write` +
`workflows: write` (used so the release push/tag can write protected `main`).

**Why no auto-bump:** a consumed artifact's tags are its consumers' lockfile. Auto-bumping on push
inflates the number meaninglessly and pollutes the tag namespace with mid-development states that
look pinnable but aren't. Deliberate releases keep `vX.Y.Z` ≡ "a release a consumer can trust".
