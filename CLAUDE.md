# tadeumendonca-skills

Claude Code **plugin** (slash-command library) for the **tadeumendonca.io** platform — distributed
via the **marketplace in this repo** and consumed by **`tadeumendonca-io`** (the static site SPA in
`apps/fed` + its Terraform in `iac/`).
The commands are generic, reusable implementation guides (no AWS dependency to run).

Each command is a per-component guide: when the owner runs `/tadeumendonca-skills:framework-react`,
Claude reads the guide and knows exactly how to implement that piece following this project's
established patterns (custom Tailwind design system, snake_case contracts, Terraform parametrization,
numeric SemVer, etc.).

> **The library is broader than its current consumer.** The `backend` family and several `infrastructure`
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
- `skills/vpc/SKILL.md` is the **density exemplar** — match it.

**Deep-dive authoring process (done in-place here):**
1. **Scaffold** the scenario space (Claude drafts the dense structure from sound practice + the platform repos).
2. **Elicit the owner's layer** — ask a few sharp questions (default posture? real triggers to deviate? rule
   of thumb? a war story?) and weave the answers into a **"My take / preference"** section.
3. Iterate per skill until it reads like a senior engineer's knowledge transfer. Go skill by skill / by domain.

**Hard principles:** **project-agnostic** — generic `<project>` / `<apex-domain>` placeholders, **NO** real
names/domains/ARNs/ids; **English** (it's published); **additive density** (deepen; never thin out good content).

**State (re-verified 2026-08-10, unchanged in substance since 2026-06-21):** the thin
`## Decision & trade-off` baseline has landed for the `infrastructure` and `backend` families, plus the
`vpc` deep exemplar; **the `frontend` family is still effectively unstarted — exactly one file in it
carries a trade-off in any form** (`grep -rl '^family: frontend' skills | xargs grep -il trade-off` → 1,
`authentication`; against the count published below). **The command carries `-i`, and that is a
correction rather than a flourish:** the form published here until #164 was
`grep -rl trade-off commands/frontend/`, which returns **zero** — the one occurrence is written
`Trade-off`. The figure was right and the command beside it did not produce it, which is the exact
failure this repo's "publish the number with its command" rule exists to make visible. The
**deep-dive above is the active workstream**; those baseline sections are scaffolding to deepen, not the
goal.

*The date was re-checked rather than re-stamped.* A `State (…)` marker whose date is refreshed without
re-measuring is worse than a stale one: it converts an aging claim into a confidently wrong one, and the
reader has no way to tell which happened. The measurement is written next to the claim so the next
person can falsify it in one command instead of trusting the date.

---

## Installation (Claude Code plugin)

This repo is a **Claude Code plugin + marketplace** — the native way to reuse skills across
projects. The skill library lives in `skills/`, one directory per skill holding a `SKILL.md`, and the two
commands a human types live in `commands/`; `.claude-plugin/marketplace.json` is the catalog and
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

### What is a command and what is a skill — three rules, and only one of them is a mechanism

This took a full session to arrive at and was written down nowhere. **Measured, not read from docs.**

**1 · The folder is for the human. It is not a mechanism.**
`commands/` and `skills/` are two top-level directories because a reader opening this repo should not
meet a library and a control surface in the same pile — the owner's reason, in his words: *"o problema é
a contaminação na leitura do repositório por humanos se tudo ficar no mesmo lugar."* **The loader does
not distinguish them.** `claude plugin details` on the split tree reports **`Skills (71)`** — the 69
under `skills/` **plus the 2 under `commands/`**, counted alike, reachable alike.

**2 · DECLARATION is what registers a skill. The root is only the default.**

~~**The root is for the loader's SKILL INDEX. Nesting kept the 69 out of it — and only out of it.**
Before the split the same command reported `Skills (2)` — `autonomy-on` and `new-issue`, the only two
files not inside a family.~~ ~~Nested skills were measured to resolve under **no** spelling — not
`/plugin:nested`, not `/plugin:fam/nested`, not `/plugin:fam:nested`, and **not the `Skill` tool**
either.~~

**STRUCK 2026-08-10 — the second sentence is FALSE, and it was published to this branch before it was
tested.** It is struck rather than deleted because anyone who read it took a design decision from it: it
is the sentence that forced the flat tree.

**What is actually true, measured on #182 — probe against control, one variable:**

| probe plugin | `skills` array in `plugin.json` | nested `skills/fam/nested/SKILL.md` | flat `skills/flatctl/SKILL.md` |
|---|---|---|---|
| `nestprobe` | **present** — `["./skills/fam/nested", "./skills/flatctl"]` | **resolved**, returned its body nonce | resolved |
| `nestprobectl` | **absent**, tree otherwise identical | **`SKILL-NOT-AVAILABLE`** | resolved |

**An explicit `skills` array loads a nested skill, and the identifier stays the BARE innermost directory
name** — `nestprobe:nested`, never `nestprobe:fam/nested` (that spelling was measured falling through as
prompt text, which is rule 3's side effect below, from the other side). **Nesting was never blocked; it
was blocked by omission** — the root is what a manifest with no `skills` key scans, and that is the whole
of what "the root registers" ever meant.

**What the original claim got right, and it is the half worth keeping.** The consumer that a
non-registered skill loses is **the model's own discovery** — the skill index is what lets the model see
that a `vpc` skill exists and reach for it, and it is the only consumer of a `description:`. Everything a
human or a brief addresses **by name** was unaffected then and is unaffected now: typed invocation, and
`skills:` preloading. So the failure this rule guards is still the same one, and it is still silent —
only its cause is a missing line in `plugin.json` rather than a directory.

**Which is why the array is gated in both directions** (`hooks/scripts/inventory-counts.test.sh`): every
declared path must resolve to a real `SKILL.md`, and every `SKILL.md` in the tree must be declared. A
skill added and not declared does not exist to the model, and nothing else anywhere would say so.

**3 · `argument-hint` is the contract. It is the only real distinction, and it is semantic.**

| | a **command** | a **skill** |
|---|---|---|
| what it is | a file a human **types**, with arguments | a body of knowledge the model **reaches for** |
| declares `argument-hint` | **yes** — it is what the human sees while typing | **no** |
| lives in | `commands/<name>.md` | `skills/<family>/<name>/SKILL.md`, declared in `plugin.json` |
| invocable as `/plugin:<name>` | yes | yes |
| reachable by the `Skill` tool | yes | yes |
| preloadable via a persona's `skills:` | yes | yes |
| `$ARGUMENTS` interpolates | yes | yes — measured, with `$NOTAVARIABLE` surviving literally as the control |

**The last four rows are identical on purpose: there is no mechanical difference left.** What separates
the two is what the file is *for*, and `hooks/scripts/inventory-counts.test.sh` asserts it **in both
directions** — removing `argument-hint` from a typed command reddens, and adding one to a skill reddens.
The distinction is gated, not conventional.

**The cost this makes visible:** the 69 descriptions total ~28 KB and are now **always-on**, about
**+9,919 tokens per session** (`Skills (2)` ≈ 1,444 tok → `Skills (71)` ≈ 11,363 tok). ADR-0009 made
those descriptions dense deliberately; **that decision was free while nothing loaded them and is not
free now.** Nobody has revisited it at this price — that is an open decision, not a settled one.

### Usage

Plugin commands and skills are **namespaced under the plugin name**, with **no family segment** — the
name is the file's own **innermost** directory (`skills/infrastructure/vpc/SKILL.md` → `vpc`). The family
directory is for the human reading the library and is **not** part of any identifier. Type it and pass
context after it (received as `$ARGUMENTS`):

```
/tadeumendonca-skills:lambda-handler posts
/tadeumendonca-skills:cognito staging
/tadeumendonca-skills:devops production
```

**A side effect of losing the family segment, and it is the best one:** an unresolved identifier
**without** a slash returns `Unknown command:`, while one **with** a slash is not recognised as a command
at all — it falls through as ordinary prompt text and the model improvises a plausible answer. Every
identifier this plugin published used to contain a slash. **None does now**, so a broken invocation
fails loudly instead of silently. **The family directories coming back on #182 did not cost this**, which
is the reason the identifiers were kept bare rather than re-qualified: the loader takes the innermost
directory either way, so the tree regained a reading structure and the namespace did not change at all.

### Releasing a version

**Trunk-based** (`trunk-single-env`, consumed-artifact variant) — this repo is a *consumed dependency*
(by `tadeumendonca-io`), not an app with environments, so it does **not** use GitFlow. There is one long-lived branch, **`main`**: skill
work lands via short-lived `feature/*` / `docs/*` PRs, and `main` is always releasable. Pushing to
`main` does **not** auto-version — the version is a deliberate, consumer-facing decision decoupled
from integration.

A release is cut **on demand** from the `release` workflow (numeric SemVer, `/versioning`):

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

### principles (2) — the drift-reducer

The harness's **principles layer**: how the owner builds software, so an agent's behavior doesn't drift. Cross-cutting (applies to every repo), distinct from the per-component how-to skills. Canonical summary in the README's *engineering floor* section; deep validation via the subagent that **owns** the decision — `tech-lead` against the principles and the ADR library at design time, `quality-assurance` against the Definition of Done once it is built (`plan-reviewer`, named here until 2026-08-03, was retired outright and invoking it fails); irreversible-floor enforcement via the shipped PreToolUse guard (`hooks/`).

The **agentic dev-loop** (methodology ADRs `docs/adr/`, design in `docs/proposals/agentic-dev-loop.md`): a team of per-task subagents in `agents/`, materialized lazily.

The **agentic dev-loop** (methodology ADRs `docs/adr/`): per-task subagents in `agents/`, materialized lazily and **cut when they do not run**.

**Five personas, down from nineteen** — `product-lead`, `tech-lead` and `harness-lead` above the build, `developer` building, `quality-assurance` gating. The roster was modelling an org's ROLES, one per concern. The owner's criterion replaced that: **a persona exists only where conflict is wanted** — where someone should be arguing against someone else. Everything that generated no disagreement was a handoff, and the handoff was why it never ran. See ADR-0002's seventh amendment for the measurement.

**That one-line rule was struck on 2026-08-04 and survives as the first of four**, because it could not explain either move made that day: `harness-lead` was added although it argues with the *owner* rather than with another persona, and `security` was merged away although it produced real disagreement. A persona now exists for one of four reasons — **disagreement is wanted · a fresh context is wanted · the context window is the constraint · the capability should be smaller** — and the half that decides where one may be ADDED is that **reconciliation cost is paid within a tier, not across tiers**. The reasoning is in ADR-0002's tenth amendment and [`docs/dev-loop-design.md`](./docs/dev-loop-design.md) §2; it is not repeated here.

**The 2026-08-04 merge is a different argument and is recorded as one.** `marketing-lead` → `product-lead`, on the owner's decision: **the product IS the site and the site IS his professional presence** — one object, one lead — and fewer lead profiles means fewer agent outputs to reconcile at review time. The clause he ratified, which is not optional: the copy lens keeps a **BLOCKING veto on published claims**. `product-lead` was purely advisory; the merged persona is advisory on order, scope and craft, and **blocking on the truth of anything published**. It returns the two classes separately and labelled, because the split used to be structural (two personas) and is now a discipline of how the report is written.

The shape, and the harness-agnostic design is in [`docs/dev-loop-design.md`](./docs/dev-loop-design.md):

| layer | who | why separate |
|---|---|---|
| **two leads** — disagree by design, then consolidate **ONE demand** | `product-lead` (reader, value, order, slice size — **and** positioning, voice, cross-surface coherence, the owner's career; its truth findings on published copy are **blocking**) · `tech-lead` (architecture, measurement, sequencing; **writes the product/system ADRs** — `harness-lead` writes the loop/machinery ones, split by domain since #223; leads the developer) | product-and-market vs system are genuinely different optimisations; where they agree the owner learns little |
| **the owner's pair on the MACHINERY** — same tier as the leads, and it takes no part in a story's intake | `harness-lead` — hooks, settings and permissions, agent briefs, skills, commands, the plugin, MCP; returns the scenarios a harness proposal does not cover, **before anything is built**, each with how to check it or labelled a hypothesis | the owner is CEO **and** harness engineer, and this is their pair in the second role only. It **gates nothing** — no merge request, no merge, no Issue — so it costs the leads nothing to reconcile: it never runs on the same work they do. It exists because second-order effects of a configuration change are invisible from inside the change; four were found by accident, after implementation, in a single day. *Cost:* nothing enforces a dispatch, and there is no gate behind it, so an undispatched lens is indistinguishable from a clean one |
| **one builder** | `developer` — app, infrastructure, pipeline, tests inline | splitting it created a handoff decision, and none of the three specialists was ever dispatched |
| **one gatekeeper** | `quality-assurance` — technical delivery against the DoD, **the cause of any failing gate**, **and** *can this cause a problem in production* (the floor, with its own veto) | it exists to fight the builder, on both axes at once. The two are different in kind — one has a ruler external to the gate (the requirements the leads agreed), the other has none and cannot, since *can this break production* is not enumerable in advance. So it holds **two lenses in one pass** and labels every finding with the one it came from; `agents/quality-assurance.md` carries what that costs and the behaviours that compensate |

**Absorbed rather than retired**, because the competence was kept and only the handoff was cut: `debugger` → `quality-assurance` (authorship bias corrupts *judgement*, not *investigation*, so the gate is already the right context to diagnose) · `security` → `quality-assurance` (the mandate moved whole; the **Edit** grant did not — that persona could edit precisely because it could not merge) · `adr-author` → `tech-lead` (whoever holds the decision writes its record, in the same MR as the change) · `brand-guardian` + `editor` + `recruiter` → `marketing-lead`, **and then `marketing-lead` → `product-lead` on 2026-08-04**, so all three now live there · `product-manager` + `product-owner` + `scrum-master` → `product-lead` · `analytics` → `tech-lead` · `frontend-react` + `iac-terraform-aws` + `devops-cicd` + `qa-e2e` + `sonar-remediator` + `performance` → `developer`.

**Retired outright:** `planner` and `plan-reviewer` — the owner writes the specs, in the Issues, in more detail than a planner would produce. The intake happens upstream of the loop, done by the person closest to it.

Two rules the owner set for the loop, above every persona's own checklist: **it is a machine for grinding work down, not for generating it** (twenty-two findings on a documentation PR is one slice converted into fifteen), and **nothing ships half-done** — close what can be closed, and say plainly what could not.

The lesson worth keeping: **a persona earns its place by generating a disagreement someone needs to hear**, not by completing an org chart. A mandate with no trigger is a document; a persona with no counterpart is a handoff. `harness-lead` is not the exception it looks like — its counterpart is **the owner**, wearing the harness-engineer hat, which is the one role in this loop that had nobody to argue with.

**The orchestrator is the main session itself — one name, not a sixth persona** (ADR-0013). It is not
dispatchable: no `Task` invocation ever targets it, and it satisfies none of the four reasons a persona
exists (amendment #10 above). Its **duties**: dispatches every persona (no persona talks to another
directly); commits and pushes on the loop's behalf; applies the `ready` label once the two intake leads
have closed an Issue's description; applies the ADR-0012 routing label (`product`/`content`/`loop`); and
decides, in the moment, whether a given review specialist needs dispatching at all — a real judgment
call, not a formality.

Its **boundary is stated in two honest parts, not one.** Mechanically enforced, for exactly two acts:
merge and direct push to the trunk — `hooks/scripts/permission-guard.sh` leaves the orchestrator's
`agent_type` empty by design, and rules 7 (trunk push) and 7b (merge) fire against that empty value.
**Not enforced, and not claimed to be:** label application — `gh issue edit`/`gh label` sit in the global
allow, unscoped to who calls them — and the dispatch-omission judgment call, which is a different failure
shape than "decides the irreversible": an omission nobody can see happened or didn't, not a decision on
an irreversible act. See ADR-0013 for the full record.

| Command | Purpose |
|---|---|
| `/harness-engineering` | **The universal preload, carried by all 5 profiles.** Names the discipline the whole plugin runs — Agent Harness Engineering / AI-DLC (the owner's central identity term, with Claude Code & Kiro) — and is the loop itself: the state machine (issue types, states, who acts, what artifact records it), the intake chain, the inner-loop steps, **and** the 11 engineering principles in two tiers (non-negotiable floor + risk-calibrated judgment) that shape every decision inside it. Merges the former `dev-loop`, `loop-engineering` and `engineering-philosophy` into one file (#224). The branching/topology diagrams (`gitflow-multi-env`, `trunk-single-env`) and the permission model live in `/devops` (#227), not here. |
| `/verification-and-gates` | What "done" means: the thesis, Definition of Done, the 100% functional-regression invariant, the gate tables per loop model |

### backend (19)

| Command | Purpose |
|---|---|
| `/framework-hono` | Hono framework + middleware wiring (logger/error/audit/authorize); routing, zod-openapi |
| `/openapi` | Contract auto-maintained from code (agnostic): versioned, committed root copy, AWS overlay |
| `/bff` | Backend-for-Frontend: API GW fronts only it (root routes); auth external, no auth code |
| `/lambda-handler` | Implement a BFF domain module (Hono routes + audit + DynamoDB) |
| `/audit-middleware` | Audit trail (conceptual): what's captured + the audits document shape |
| `/action-types` | Action types (conceptual): audit + RBAC + feature toggles |
| `/error-handling` | Throw AppError/NotFoundError/Unauthorized — never return 4xx |
| `/logging` | Structured logging via Powertools Logger (JSON, level per env) |
| `/metrics` | OTel metrics → ADOT collector → CloudWatch (awsemf), no AMP |
| `/tracing` | Powertools Tracer / X-Ray: segments, annotations, downstream capture |
| `/environment-config` | Config both sides: dotenv + typed accessor at runtime, parameter store baked into the bundle at build |
| `/secrets-management` | Sensitive values from Secrets Manager at runtime (cached) |
| `/redis-cache` | ElastiCache Redis cache-aside, fail-open, TTLs, invalidation |
| `/notifications` | Email via SES + SNS async fan-out; subscriptions |
| `/og-image-generator` | OG image: satori JSX→SVG + resvg→PNG + S3 cache |
| `/og-edge-handler` | Lambda@Edge 3-way: human passthrough / social OG / SEO crawler |
| `/prerender` | Bot API: og-meta (head) + prerender (full HTML + JSON-LD) from DynamoDB |
| `/postman` | API/contract tests (reference pattern — the current consumer has no API): Bearer JWT auth, collection run in CI |
| `/coverage` | Quality/test/security gates for BOTH stacks, one threshold: lint, typecheck, ≥85% cov, E2E + contract, audit, Sonar |

### frontend (15)

| Command | Purpose |
|---|---|
| `/framework-react` | React+Vite impl home: providers, Amplify, React Query, api client, routing (only place with React snippets) |
| `/authentication` | SPA auth (concept): Cognito SDK holds JWT → Bearer; API GW authorizer validates |
| `/authorization` | SPA UI gating by groups/claims (cosmetic); real authz is server-side |
| `/routing` | Route map + patterns: nested layouts, lazy, guards, 404, scroll (concept) |
| `/state` | State ownership: server→React Query, UI→Zustand, session→SDK |
| `/api-client` | BFF calls (concept): base URL from SSM, Bearer, 401, queries/mutations + invalidation |
| `/pagination` | Cursor pagination contract + infinite-scroll UX (concept) |
| `/forms` | Admin forms: controlled inputs + zod (mirrors BFF) → mutation |
| `/markdown` | Article markdown render: highlight + sanitize; consistent with edge prerender |
| `/design-system` | Cloudscape: which component per UI pattern (CV / feed / articles) |
| `/storybook` | Component library: stories, autodocs, interaction/visual tests |
| `/ux-states` | Loading/empty/error states + ErrorBoundary (consistent async UX) |
| `/analytics` | GA4 (concept): SPA page_view per route + events |
| `/seo` | Client SEO (concept): per-route meta + sitemap/robots + JSON-LD |
| `/playwright` | E2E browser tests (lives in `apps/fed`): login via Cognito SDK, critical journeys |

### infrastructure (21)

One skill per AWS service / tool used — each is the canonical parametrization + usage pattern (Terraform-resource detail). Cross-cutting policies are folded into their owning service (module sourcing + tagging → `terraform`; domain model → `route53`; encryption → `kms`; IAM authoring + OIDC roles → `iam`).

| Command | Purpose |
|---|---|
| `/terraform` | Terraform overall: versions/providers, TFC state, layout, **module-sourcing policy**, **tagging**, tfvars, CI |
| `/vpc` | VPC: subnets/NAT, S3 endpoint, lambda SG, traffic design (off-NAT) |
| `/route53` | Route53: **per-env domain model** + hosted-zone data source + A-alias records |
| `/acm` | ACM: per-env wildcard certs (reused, out-of-band), us-east-1, resolved by domain |
| `/s3` | S3: frontend(OAC)/artifacts/og-images + SSE + SSM |
| `/cloudfront` | CloudFront: OAC, TLS, cache policies, **SPA error routing + /og/***, Lambda@Edge, WAF |
| `/waf` | WAF CLOUDFRONT + REGIONAL (shared by API GW + Cognito) |
| `/lambda` | Lambda: nodejs22/arm64, non-VPC by default (VPC on demand), **Pattern B**, tracing; og-edge exception |
| `/api-gateway` | API GW (REST v1): fronts only the BFF, per-route Cognito authorizer, WAF-fronted, **contract via put-rest-api** |
| `/cognito` | Cognito: user pool, 3 groups, PKCE public client, **custom domain** |
| `/dynamodb` | DynamoDB end to end: per-entity tables, on-demand, GSIs, PITR, IAM access, client singleton, GSI queries, cursor pagination |
| `/elasticache` | ElastiCache Redis + AUTH in Secrets Manager + SSM |
| `/ses` | SES: domain verify + DKIM |
| `/sns` | SNS: async domain-event fan-out (notifications); cheapest pub/sub |
| `/iam` | IAM: **canonical role/policy authoring catalog** + OIDC deploy roles |
| `/secrets-manager` | Secrets Manager (provision): naming, jsonencode, ARN-only to SSM |
| `/ssm` | SSM Parameter Store: cross-repo config bus (namespace, read at deploy) |
| `/kms` | KMS + **encryption**: in-transit/at-rest matrix, AWS-managed vs CMK, rotation |
| `/cloudwatch` | CloudWatch: log groups/retention, flow logs, EMF metrics, alarms |
| `/cloudwatch-rum` | RUM end to end: app monitor + Cognito guest identity pool, and the browser client that reports to it |
| `/cloudwatch-xray` | X-Ray: active tracing (API GW+Lambda), sampling rules, service map |

### workflow (9)

DevOps tooling. `devops` is the umbrella (#227) — GitHub/CI-CD (OIDC, secrets/environments, the deploy workflows, the Issues backlog), Terraform Cloud as the state backend, branching per loop model, and the permission model that keeps IaC pipeline-only, all in one skill, preloaded by `developer` and `harness-lead`. The numeric-SemVer tagging rules are their own skill (`versioning`). Test runners live with their repo (`/postman`, `/playwright`); the gate policy they feed is one stack-agnostic skill (`/coverage`); IaC checkov is in `/terraform`. Architecturally-significant decisions are recorded via `adr`, split by domain (#223). Working-files and shell-command discipline — transversal across the whole roster, not DevOps-specific — is `command-hygiene`.

| Command | Purpose |
|---|---|
| `/devops` | GitHub Actions + Terraform Cloud + the permission model: OIDC, secrets/envs, branching per loop model, deploy workflows, TFC state backend, pipeline-only IaC |
| `/adr` | Architecture Decision Records: MADR format, two libraries (methodology/product), light significance gate, supersede-never-delete — authorship split by domain (#223) |
| `/command-hygiene` | Where scratch files go, one atomic Bash call, the `gh --repo` flag position, `--body-file` always — preloaded by all 5 personas |
| `/versioning` | Semantic versioning + tags: numeric SemVer via bump-my-version, loop guard, PR labels |
| `/sonarcloud` | SonarCloud quality gate (SAST + coverage + smells), blocks merge |
| `/claude-code` | Claude GitHub App: `@claude` assistant + automatic PR review (advisory, non-blocking) |
| `/code-review` | Author-side completeness pass before opening the MR: anticipates both gates, verifies the DoD with evidence |
| `/documentation-standard` | Markdown + Mermaid only; diagram types per repo |
| `/license` | Licensing standard: MIT `LICENSE` + manifest license field in every repo |

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
   See `/devops`.

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
| lens and gate verdicts | **the PR comment.** It is the durable record for both — and the **gate** verdict is additionally machine-read by `session-wip.sh`, which matches the `gatekeeper-verdict: quality-assurance` marker and nothing else; a lens verdict has no reader but a human. A file copy is a second source of truth with no reader either way — and it is what broke: the file handoff failed twice while `SendMessage` failed zero times. |
| interview transcripts, raw source material | **`.brand/` in `tadeumendonca-io`** — private and gitignored *there*, which is the documented home for exactly this. **It is NOT gitignored in this repo**, so the path is only safe in the repo that ignores it; writing private material to `.brand/` here puts it in a tracked path in a public repo. |
| a measurement instrument | **a repo script with a test, if and only if a gate will run it.** Otherwise discard. "It worked once" is not "it must persist". |
| an isolated checkout | **not a scratch class.** Use the repo — WIP=1 already serialises — or a git worktree with its own install. |

**Why a hook and not a discipline** (this is the part that generalises): of the delete spellings #155
measured — `rm -rf`, `rm -r`, `git clean -fdX`, `find -delete` — the first three are denied by the floor
or ask the human, and `find -delete` passes with no decision from any layer. So "the agent tidies up
after itself" resolves to "the agent reaches for the delete nothing watches". **The claim is those
spellings, measured — not the class**: `permission-guard.sh` deliberately does not chase the
interpreters, and `Bash(python3:*)` / `Bash(node:*)` are in `allow`, so a `shutil.rmtree` is a recursive
delete that no layer sees either. That gap is priced, not closed, and the hook does not depend on it
being closed. The measurements are in #155; the reasoning is in the hook's own header.

**`/clear` sweeps too**, and it is the one sweep a human triggers deliberately, mid-work — a PR body
written, then `/clear`, then "post it" is the same loss in a smaller box. The spared cases are `resume`
and `compact` only; do not complete the set by symmetry.

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
