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
This **harness** is the owner's **public knowledge-transfer artifact** — the personas and hooks as much as
the skills, since the reviewable loop is the differentiator and the skill library is its least distinctive
third: a dense dump of his senior-engineer
**experience + implementation preferences**, externalized in public as proof of depth. It is NOT a thin
"what this project did" doc — each skill is a **dense, scenario-covering architecture guide** that
demonstrates judgment.

**The repositioning this artifact backs:** from **Cloud Application Architect (AWS Professional
Services)** to **AI Engineer — agentic development and AI-native automations**, anchored in SDLC and
distributed systems. Explicitly **not** ML or data science; that is a different role and claiming it
would be a false claim on a surface whose whole thesis is rigor.

~~*to "Senior Software Engineer" at product companies*~~ — **that was wrong and had been public for a
while** (#81), which is the part that matters: this is the section declaring the repo a
knowledge-transfer artifact and proof of depth, so a reader who took that claim seriously read the very
next sentence to learn what the owner is repositioning *toward*, and got a role he is not targeting.
Not a stale line in a doc — the artifact misstating its own thesis. Struck rather than deleted, because
anyone who read the old value deserves to find out it changed rather than to find it silently gone.

The authoritative value lives in the owner's **private, gitignored** positioning source, and it is read
there rather than written from memory. Only the *role* appears here — it is already public, on the site
and on LinkedIn. The reasoning behind it stays in the private source and is never quoted into this repo.

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

**State (re-verified 2026-08-02, unchanged in substance since 2026-06-21):** the thin
`## Decision & trade-off` baseline has landed for `infrastructure/*` and `backend/*`, plus the `vpc` deep
exemplar; **`frontend/*` is still effectively unstarted — exactly one file under it carries a trade-off
in any form** (`grep -rl trade-off commands/frontend/`, against the count published below). The
**deep-dive above is the active workstream**; those baseline sections are scaffolding to deepen, not the
goal.

*The date was re-checked rather than re-stamped.* A `State (…)` marker whose date is refreshed without
re-measuring is worse than a stale one: it converts an aging claim into a confidently wrong one, and the
reader has no way to tell which happened. The measurement is written next to the claim so the next
person can falsify it in one command instead of trusting the date.

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

### principles/ (5) — the drift-reducer

The harness's **principles layer**: how the owner builds software, so an agent's behavior doesn't drift. Cross-cutting (applies to every repo), distinct from the per-component how-to skills. Canonical summary in the README's *engineering floor* section; deep validation via the subagent that **owns** the decision — `tech-lead` against the principles and the ADR library at design time, `quality-assurance` against the Definition of Done once it is built (`plan-reviewer`, named here until 2026-08-03, was retired outright and invoking it fails); irreversible-floor enforcement via the shipped PreToolUse guard (`hooks/`).

The **agentic dev-loop** (methodology ADRs `docs/adr/`, design in `docs/proposals/agentic-dev-loop.md`): a team of per-task subagents in `agents/`, materialized lazily.

The **agentic dev-loop** (methodology ADRs `docs/adr/`): per-task subagents in `agents/`, materialized lazily and **cut when they do not run**.

**Five personas, down from nineteen** — `product-lead`, `tech-lead` and `harness-reviewer` above the build, `developer` building, `quality-assurance` gating. The roster was modelling an org's ROLES, one per concern. The owner's criterion replaced that: **a persona exists only where conflict is wanted** — where someone should be arguing against someone else. Everything that generated no disagreement was a handoff, and the handoff was why it never ran. See ADR-0002's seventh amendment for the measurement.

**That one-line rule was struck on 2026-08-04 and survives as the first of four**, because it could not explain either move made that day: `harness-reviewer` was added although it argues with the *owner* rather than with another persona, and `security` was merged away although it produced real disagreement. A persona now exists for one of four reasons — **disagreement is wanted · a fresh context is wanted · the context window is the constraint · the capability should be smaller** — and the half that decides where one may be ADDED is that **reconciliation cost is paid within a tier, not across tiers**. The reasoning is in ADR-0002's tenth amendment and [`docs/dev-loop-design.md`](./docs/dev-loop-design.md) §2; it is not repeated here.

**The 2026-08-04 merge is a different argument and is recorded as one.** `marketing-lead` → `product-lead`, on the owner's decision: **the product IS the site and the site IS his professional presence** — one object, one lead — and fewer lead profiles means fewer agent outputs to reconcile at review time. The clause he ratified, which is not optional: the copy lens keeps a **BLOCKING veto on published claims**. `product-lead` was purely advisory; the merged persona is advisory on order, scope and craft, and **blocking on the truth of anything published**. It returns the two classes separately and labelled, because the split used to be structural (two personas) and is now a discipline of how the report is written.

The shape, and the harness-agnostic design is in [`docs/dev-loop-design.md`](./docs/dev-loop-design.md):

| layer | who | why separate |
|---|---|---|
| **two leads** — disagree by design, then consolidate **ONE demand** | `product-lead` (reader, value, order, slice size — **and** positioning, voice, cross-surface coherence, the owner's career; its truth findings on published copy are **blocking**) · `tech-lead` (architecture, measurement, sequencing; **writes the ADRs**; leads the developer) | product-and-market vs system are genuinely different optimisations; where they agree the owner learns little |
| **the owner's pair on the MACHINERY** — same tier as the leads, and it takes no part in a story's intake | `harness-reviewer` — hooks, settings and permissions, agent briefs, skills, commands, the plugin, MCP; returns the scenarios a harness proposal does not cover, **before anything is built**, each with how to check it or labelled a hypothesis | the owner is CEO **and** harness engineer, and this is their pair in the second role only. It **gates nothing** — no merge request, no merge, no Issue — so it costs the leads nothing to reconcile: it never runs on the same work they do. It exists because second-order effects of a configuration change are invisible from inside the change; four were found by accident, after implementation, in a single day. *Cost:* nothing enforces a dispatch, and there is no gate behind it, so an undispatched lens is indistinguishable from a clean one |
| **one builder** | `developer` — app, infrastructure, pipeline, tests inline | splitting it created a handoff decision, and none of the three specialists was ever dispatched |
| **one gatekeeper** | `quality-assurance` — technical delivery against the DoD, **the cause of any failing gate**, **and** *can this cause a problem in production* (the floor, with its own veto) | it exists to fight the builder, on both axes at once. The two are different in kind — one has a ruler external to the gate (the requirements the leads agreed), the other has none and cannot, since *can this break production* is not enumerable in advance. So it holds **two lenses in one pass** and labels every finding with the one it came from; `agents/quality-assurance.md` carries what that costs and the behaviours that compensate |

**Absorbed rather than retired**, because the competence was kept and only the handoff was cut: `debugger` → `quality-assurance` (authorship bias corrupts *judgement*, not *investigation*, so the gate is already the right context to diagnose) · `security` → `quality-assurance` (the mandate moved whole; the **Edit** grant did not — that persona could edit precisely because it could not merge) · `adr-author` → `tech-lead` (whoever holds the decision writes its record, in the same MR as the change) · `brand-guardian` + `editor` + `recruiter` → `marketing-lead`, **and then `marketing-lead` → `product-lead` on 2026-08-04**, so all three now live there · `product-manager` + `product-owner` + `scrum-master` → `product-lead` · `analytics` → `tech-lead` · `frontend-react` + `iac-terraform-aws` + `devops-cicd` + `qa-e2e` + `sonar-remediator` + `performance` → `developer`.

**Retired outright:** `planner` and `plan-reviewer` — the owner writes the specs, in the Issues, in more detail than a planner would produce. The intake happens upstream of the loop, done by the person closest to it.

Two rules the owner set for the loop, above every persona's own checklist: **it is a machine for grinding work down, not for generating it** (twenty-two findings on a documentation PR is one slice converted into fifteen), and **nothing ships half-done** — close what can be closed, and say plainly what could not.

The lesson worth keeping: **a persona earns its place by generating a disagreement someone needs to hear**, not by completing an org chart. A mandate with no trigger is a document; a persona with no counterpart is a handoff. `harness-reviewer` is not the exception it looks like — its counterpart is **the owner**, wearing the harness-engineer hat, which is the one role in this loop that had nobody to argue with.

| Command | Purpose |
|---|---|
| `/principles/loop-engineering` | **Names the discipline the whole plugin runs — Agent Harness Engineering / AI-DLC** (the owner's central identity term, with Claude Code & Kiro): the AI-native loop treated as the engineered artifact — its cadence, its gates-as-a-system, the harness itself. The other four principles skills are its parts. |
| `/principles/engineering-philosophy` | The 11 principles in two tiers (non-negotiable floor + risk-calibrated judgment); the agent-led/human-residual spine |
| `/principles/verification-and-gates` | What "done" means: the thesis, Definition of Done, the 100% functional-regression invariant, the gate tables per loop model |
| `/principles/dev-loop` | End-to-end flow in **two models** — `gitflow-multi-env` (staging → promote → prod) and `trunk-single-env` (PR → `main` → live); how to tell which applies; failure = revert + forward fix |
| `/principles/permissions-and-environments` | The permission zones **per loop model**; git-reversibility tolerance test; IaC pipeline-only + infra-first; global + per-project layering; what the guard hook actually enforces (and why it stays branch-agnostic) |

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

### workflow/ (9)

DevOps tooling. The GitHub/CI-CD capability (`github-actions`) is the umbrella for OIDC, secrets/environments, branching (both loop models), the deploy workflows, and the Issues backlog; the numeric-SemVer tagging rules are their own skill (`versioning`). Test-runner + gate skills live with their repo (`/backend/postman` + `/backend/coverage`, `/frontend/playwright` + `/frontend/coverage`); IaC checkov is in `/infrastructure/terraform`. Architecturally-significant decisions are recorded via `adr`.

| Command | Purpose |
|---|---|
| `/workflow/github-actions` | GitHub/CI-CD capability: OIDC, secrets/envs, branching per loop model, the deploy workflows, Issues backlog |
| `/workflow/adr` | Architecture Decision Records: MADR format, two libraries (methodology/product), light significance gate, supersede-never-delete |
| `/workflow/versioning` | Semantic versioning + tags: numeric SemVer via bump-my-version, loop guard, PR labels |
| `/workflow/terraform-cloud` | TFC remote-state backend; per-env workspaces; Local execution; **pipeline-only apply/destroy** |
| `/workflow/sonarcloud` | SonarCloud quality gate (SAST + coverage + smells), blocks merge |
| `/workflow/claude-code` | Claude GitHub App: `@claude` assistant + automatic PR review (advisory, non-blocking) |
| `/workflow/code-review` | Author-side completeness pass before opening the MR: anticipates both gates, verifies the DoD with evidence |
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

## Scratch — `<repo-root>/.scratch/`, and nothing survives a new session

**`.scratch/` at the repo root is the ONE place for throwaway files.** Gitignored, never committed,
never referenced by anything that has to still work tomorrow. Not `/tmp`, not the session scratchpad
directory, not a stray path in the tracked tree.

`session-scratch.sh` empties it at the start of every new session, so the guarantee is a bound, not
a promise: **write it, use it, and expect it gone.** A resumed or compacted session does not sweep —
a pause is not a new session, and the PR body written before it is still owed to the command that
consumes it.

**The taxonomy matters more than the location**, because most of what accumulated there never
belonged in a scratch at all:

| what | where |
|---|---|
| PR bodies, commit messages | **`.scratch/`** — written once, consumed by `--body-file`, discarded. The only use that matches the purpose. |
| lens and gate verdicts | **the PR comment.** It is already the durable record and is already machine-read by `session-wip.sh`. A file copy is a second source of truth with no reader — and it is what broke: the file handoff failed twice while `SendMessage` failed zero times. |
| interview transcripts, raw source material | **`.brand/`** — private, gitignored, already the documented home for exactly this. |
| a measurement instrument | **a repo script with a test, if and only if a gate will run it.** Otherwise discard. "It worked once" is not "it must persist". |
| an isolated checkout | **not a scratch class.** Use the repo — WIP=1 already serialises — or a git worktree with its own install. |

**Why a hook and not a discipline** (this is the part that generalises): every recursive delete the
agent can issue is either denied by the floor or asks the human, *except* `find -delete`. So "the
agent tidies up after itself" resolves to "the agent reaches for the one delete nothing watches".
The measurements behind all of this are in #155; the reasoning is in the hook's own header.

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
