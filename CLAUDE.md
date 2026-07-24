# tadeumendonca-skills

Claude Code **plugin** (slash-command library) for the **tadeumendonca.io** platform — distributed
via the **marketplace in this repo** and consumed by **`tadeumendonca-io`** (the static site SPA in
`apps/fed` + its Terraform in `iac/`).
The commands are generic, reusable implementation guides (no AWS dependency to run).

Each command is a per-component guide: when the owner runs `/tadeumendonca-skills:frontend/framework-react`,
Claude reads the guide and knows exactly how to implement that piece following this project's
established patterns (custom Tailwind design system, snake_case contracts, Terraform parametrization,
numeric SemVer, etc.).

> **The library is broader than its current consumer.** `backend/*` and several `infrastructure/*`
> skills document a BFF-on-Lambda + DynamoDB + Cognito architecture that `tadeumendonca-io` **retired**
> — it is now fully static. Those skills are kept **deliberately, as reference patterns**, not as a
> description of the live platform. Never infer the consumer's architecture from them; read the
> consumer's own `CLAUDE.md`.

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

**Consume it in a repo (`tadeumendonca-io`)** — add the marketplace from this git + install:

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
real values per project (in `tadeumendonca-io/iac`, they become `var.project` / `var.apex_domain`).

### Usage

Plugin commands are **namespaced under the plugin name**. Type the command and pass context after
it (received as `$ARGUMENTS`):

```
/tadeumendonca-skills:backend/lambda-handler posts
/tadeumendonca-skills:infrastructure/cognito staging
/tadeumendonca-skills:workflow/github-actions production
```

### Releasing a version

**Trunk-based** (`trunk-single-env`, consumed-artifact variant) — this repo is a *consumed dependency*
(by `tadeumendonca-io`), not an app with environments, so it does **not** use GitFlow. There is one long-lived branch, **`main`**: skill
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

The harness's **principles layer**: how the owner builds software, so an agent's behavior doesn't drift. Cross-cutting (applies to every repo), distinct from the per-component how-to skills. Canonical summary in the root `PRINCIPLES.md`; deep validation via the `plan-reviewer` subagent (`agents/`); irreversible-floor enforcement via the shipped PreToolUse guard (`hooks/`).

The **agentic dev-loop** (methodology ADRs `docs/adr/`, design in `docs/proposals/agentic-dev-loop.md`): a team of per-task subagents in `agents/`, materialized lazily. Built so far — the design→build→verify spine, process side: **`planner`** (intake — turns a backlog Issue into a spec in plan mode: one thin slice with testable acceptance criteria that become E2E stories, flags ADR-needs, asks on boundaries; read-only, never builds), **`plan-reviewer`** (design-time — reviews that plan/spec against the principles + the ADR library for drift, flags ADR-needs; the evolution of the former `principles-guide`), **`adr-author`** (records a significant decision in MADR — picks library + next number, drafts at `proposed`, updates the index; never merges, per `/workflow/adr`), and **`critical-reviewer`** (code-time — reviews an MR against the Definition of Done, ADR-0003; approves+merges the safe class, escalates the boundary, ADR-0004). Together: intake → plan-review → (build) → record → code-review. Plus the frontend trident's build+verify pair: **`frontend-react`** (build specialist — implements the approved spec under `apps/fed/src/**`, writing unit/component tests inline to coverage ≥85%, TDD; respects the fixed stack decisions, never touches `iac/`, never merges; `/frontend/*`) and **`qa-e2e`** (turns the spec's acceptance criteria into Playwright user-story journeys and audits the 100%-of-user-visible-features regression invariant; edits within the E2E glob, runs the suite, never merges; `/frontend/playwright`) — the middle and verification ends of the frontend trident (`ux → frontend-react → qa-e2e`), closing the loop with the `planner`'s criteria. Plus the infra build specialist: **`iac-terraform-aws`** (implements the approved spec under `iac/**`, least-privilege + checkov-clean, validated **read-only** locally — fmt/validate/plan; honors the load-bearing invariants: pipeline-only apply, immutable OIDC subject, the TFC workspace name; never runs a local apply/destroy, never merges — any `iac/` change is boundary-class; `/infrastructure/*`) — the same shape as `frontend-react` on the infra glob. Plus the pipeline build specialist: **`devops-cicd`** (implements the approved spec under `.github/workflows/**`, least-privilege per-job OIDC + minimal `permissions:`, supply-chain-safe (SHA-pinned actions, `--ignore-scripts`), gates kept blocking; never authors IAM roles — it wires the ARN as a secret ref and hands the role to `iac-terraform-aws`; never merges — a pipeline change is boundary-class; `/workflow/*`) — completing the three build globs (app / infra / pipeline), disjoint by construction. Plus the quality-gate remediator: **`sonar-remediator`** (captures a red SonarCloud gate's findings and fixes their **cause** within the slice — never games the gate: no unjustified `NOSONAR`/exclusion, no threshold-lowering; coverage misses become tests, not exclusions; re-runs for evidence; edits flagged lines but authors nothing (`Edit`, no `Write`) and never merges; `/workflow/sonarcloud`) — cheap/fast, the mechanical counterpart that keeps the blocking gate honest. Plus the first cross-cutting lens: **`security`** (AppSec at two altitudes — a light threat model on a plan at design-time, and a dependency-audit / SAST / IAM-least-privilege / secret-hygiene / supply-chain review on an MR at code-time; gives the repo's diffuse security concerns a single owner, calibrated to the real surface of a public/static/backend-less site; remediates within its concern — dep bumps, IAM tightening, SHA-pinning, secret removal — but authors nothing (`Edit`, no `Write`), escalates the architectural security call, never merges; owns closing the no-package-vuln-scanning gap). And the second cross-cutting lens: **`performance`** (owns the performance budget as a gate — a budget check on a plan at design-time, and a CWV / bundle-size / Lighthouse / asset-loading review on an MR at code-time; calibrated to a reader-first static content site where perf *is* the thesis (the ~609 kB bundle is live signal); remediates within its concern — code-splitting, import narrowing, font/image fixes — but authors nothing (`Edit`, no `Write`), escalates budget-changing trade-offs, never merges). And the reviewer of what the code *says* rather than what it does: **`product-owner`** (guards reader-facing copy against the owner's private positioning source — unearned claims, unsourced quantification, precision drift against the canonical CV data, cross-surface incoherence, confidentiality, third-party naming, durability; runs where a repo marks content boundary **by path**). It exists because the DoD has **no criterion for what the words claim**, so on a presence where the copy is the product a positioning breach ships green — `critical-reviewer` catches it only by accident. Two properties are load-bearing: it has **no write capability at all** (`Read, Grep, Glob` — it cannot edit copy, merge, or even post its own findings; the voice stays the owner's and the private source stays unpublishable), and its **trigger lives in `critical-reviewer`**, the only persona guaranteed to run on every MR — a content-path diff is incomplete until `product-owner` returns a verdict, because a mandate with no trigger is a document, not a gate. "Product ownership stays human" holds, narrowed to product *decisions* (ADR-0002 amendment). Alongside it, the layer that **prepares** the owner's decisions rather than making them — the owner is the CEO of this initiative and the final word is theirs: **`product-manager`** (proposes the ORDER of work — opportunity cost against the live queue, what a slice leaves half-done, cross-repo sequencing, whether the outcome is observable; every verdict is a proposal, it writes nothing) and **`analytics`** (owns *how would we know this worked* — the measurement plan, and first of all whether the instrumentation the guide **claims** actually exists; it found the consuming repo asserting Google Analytics in its DoD with no analytics in the app at all. Treats cookie-vs-cookieless as an owner decision it **surfaces**, since on a site whose property is that nothing third-party loads until asked, a tracker is architecture, not config). Plus the escalation persona: **`debugger`** (hypothesis-driven diagnosis of a non-trivial failure — a gate that broke for no obvious reason, green locally and red in CI, a flaky suite. Its output is a **cause with evidence, never a patch**, because a context committed to a fix stops looking for the cause the moment its fix works; it lists hypotheses *before* testing them and reports what it **eliminated**, which is the half normally lost). Roster enabled in `-io` — process (4) + build (3) + verification (2) + cross-cutting (2) + product (2) + measurement (1) + escalation (1) = **15 subagents**. **`ux` stays defined-but-not-materialized**: no evidence it would fire, and enabling a persona with no work is theatre. The remaining OFF personas (backend-node, api-design, api-testing, data-modeling, observability, sre, ux, debugger) are defined in the proposal but carry no work on a static/backend-less site; a project enables the subset its blast-radius justifies.

| Command | Purpose |
|---|---|
| `/principles/engineering-philosophy` | The 11 principles in two tiers (non-negotiable floor + risk-calibrated judgment); the agent-led/human-residual spine |
| `/principles/verification-and-gates` | What "done" means: the thesis, Definition of Done, the 100% functional-regression invariant, the gate tables per loop model |
| `/principles/dev-loop` | End-to-end flow in **two models** — `gitflow-multi-env` (staging → promote → prod) and `trunk-single-env` (PR → `main` → live); how to tell which applies; failure = revert + forward fix |
| `/principles/permissions-and-environments` | The permission zones **per loop model**; git-reversibility tolerance test; IaC pipeline-only + infra-first; global + per-project layering; what the guard hook actually enforces (and why it stays branch-agnostic) |

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
| `/backend/postman` | API/contract tests (reference pattern — the current consumer has no API): Bearer JWT auth, collection run in CI |
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

### workflow/ (8)

DevOps tooling. The GitHub/CI-CD capability (`github-actions`) is the umbrella for OIDC, secrets/environments, branching (both loop models), the deploy workflows, and the Issues backlog; the numeric-SemVer tagging rules are their own skill (`versioning`). Test-runner + gate skills live with their repo (`/backend/postman` + `/backend/coverage`, `/frontend/playwright` + `/frontend/coverage`); IaC checkov is in `/infrastructure/terraform`. Architecturally-significant decisions are recorded via `adr`.

| Command | Purpose |
|---|---|
| `/workflow/github-actions` | GitHub/CI-CD capability: OIDC, secrets/envs, branching per loop model, the deploy workflows, Issues backlog |
| `/workflow/adr` | Architecture Decision Records: MADR format, two libraries (methodology/product), light significance gate, supersede-never-delete |
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

Numeric SemVer via `bump-my-version`. **Every merge to `main` auto-bumps the PATCH and publishes a
Release** — because this plugin is distributed through a marketplace, and the marketplace only serves
*published* versions: an unreleased `main` is invisible to the installed plugin (a restart reloads the
installed cache, not `main`). Publishing on every merge is safe because **publishing ≠ forcing adoption**
— each consumer opts in with `/plugin update`, so a merge that never publishes is work that silently never
ships. (Methodology **ADR-0005**, which supersedes the earlier release-only model.)

Purely **numeric SemVer** `MAJOR.MINOR.PATCH` — no `-dev` pre-release suffix.

- `VERSION` — current version; `.claude-plugin/plugin.json` bumps in lockstep (the marketplace serves this).
- `.bumpversion.toml` — bump config; numeric only, `tag_name = v{new_version}`,
  `message = "bump: {current_version} → {new_version}"` (CI loop guard); bumps `VERSION` +
  `.claude-plugin/plugin.json` in lockstep.
- `.github/workflows/version-main.yml` — **push to `main`**: skips `bump:` commits, bumps **patch**, tags
  `vX.Y.Z`, pushes, publishes a Release with categorized notes. The default, automatic path.
- `.github/workflows/release.yml` — **`workflow_dispatch` only**, for a **deliberate minor/major** milestone
  (`part` = major | minor | patch). Its `bump:` commit is skipped by `version-main.yml`'s loop guard.

**Required secret:** `VERSION_BUMP_TOKEN` — a GitHub fine-grained PAT with `contents: write` +
`workflows: write` (so the bump push/tag can write protected `main`).

**Consumers pull deliberately:** `/plugin marketplace update tadeumendonca` (refresh the marketplace to the
latest `main`) then `/plugin` → update `tadeumendonca-skills` to the new version. This is the only step the
plugin's *installation* needs — merging publishes the version; adoption is always the consumer's call.
