# Command reference — the skill library, the roster it serves, and how the tree got this shape

**This file was `CLAUDE.md`'s `## Command reference` section until 2026-09-22.** It moved because
`CLAUDE.md` crossed the harness's 150,000-character limit and this section was the largest block in
that file binding nobody: 32,539 characters, 21.5% of 151,076. **The command that produced both
figures is in `CLAUDE.md`'s pointer section, and it reads the pre-cut commit rather than the
working tree** — the base of the measurement is inside the diff that moved it, so a selector run
against head would refute a true claim.

**The cut that produced this file, so a later reader can re-apply it rather than re-derive it.**
`CLAUDE.md` is the only brief that reaches the ORCHESTRATOR — the main session, which is dispatched
by nobody and preloads nothing (#409, one nonce per candidate surface: a repo-root `CLAUDE.md`
reaches that context, a skill body does not, `AGENTS.md` does not). So every paragraph was asked one
question: **is this an obligation the orchestrator must obey, or a reading structure for a human?**
Reading structure is what is here. The obligations that were sitting inside this section — the
orchestrator's own duties and its two mechanically-enforced acts, and the two rules the owner set
above every persona's checklist — **stayed in `CLAUDE.md`**, under *The orchestrator, and the two
rules above every persona's checklist*.

**Nothing below was rewritten.** Every strike (`~~…~~`) and every STRUCK paragraph travelled with the
content it annotates, per this repository's own convention: a correction recorded in place is part of
the record, not tidying to be done while moving house.

**One sentence did NOT travel, because `README.md` already carries it.** *"15 skills, one directory
each, at one level under `skills/`"* is `README.md:1141`. That section also carries a **generated**
per-skill table (`skill | what it decides | whose domain`, written by
`hooks/scripts/skills-table.py`) and the per-persona preload lists. **The table below is AUTHORED and
that one is DERIVED** — two statements of one inventory, with nothing asserting they agree. Said here
rather than left for a reader to trip on. `hooks/scripts/inventory-counts.test.sh` reads **this**
file for a row per skill, precisely because an authored table is the one an author can forget to
update.

---

**15 skills, one directory each, at ONE level under `skills/` (#286)** — the owner's decision: *"o que
eu quero é que todas skills estejam no mesmo nível hierárquico de diretórios."* **The headings below are
a reading structure in this document and nothing else.** They were directories until #286 (`principles/`,
`backend/`, `frontend/`, `infrastructure/`, `workflow/`), and the reason they were is recorded in the
next paragraph rather than deleted, because it is a measurement and it is still true about the tree it
was made on.

**Why the directories existed, and why that reason lapsed.** They came back at #182 on the owner's call,
for the human reading the library: a category teaches what a skill IS in a way an alphabetical list of
**69** does not. That argument was about a denominator. The library is **15**
(`jq -r '.skills[]' .claude-plugin/plugin.json | wc -l` → 15) — 14 after `#229`/`#230`/`#231`
consolidated 21, 19 and 15 files into one skill each, plus `content-publishing` added 2026-09-02 — so
the pile the grouping protected a reader from no longer exists. **What did NOT change is the identifier**: the loader reads the innermost directory name at any
depth, so `/tadeumendonca-skills:cloud-infrastructure` is the same string before and after, and this
slice is a PATCH rather than a breaking change. Re-measured on #286 rather than inherited from #182 —
one probe plugin, one skill body, only the depth varying:

```
claude --plugin-dir <probe> -p "/probeplug:probealpha"   # skills/fam/probealpha -> the nonce
claude --plugin-dir <probe> -p "/probeplug:probealpha"   # skills/probealpha     -> the same nonce
```

### the harness and process skills — the drift-reducer

The harness's **principles layer**: how the owner builds software, so an agent's behavior doesn't drift. Cross-cutting (applies to every repo), distinct from the per-component how-to skills. Canonical summary in the README's *engineering floor* section; deep validation via the subagent that **owns** the decision — `tech-lead` against the principles and the ADR library at design time, `quality-assurance` against the Definition of Done once it is built (`plan-reviewer`, named here until 2026-08-03, was retired outright and invoking it fails); irreversible-floor enforcement via the shipped PreToolUse guard (`hooks/`).

The **agentic dev-loop** (methodology ADRs `docs/adr/`, design in `README.md`): per-task subagents in `agents/`, materialized lazily and **cut when they do not run**.

**~~Six~~ ~~Seven~~ Eight personas, down from nineteen, plus three added back deliberately (#187, #317, #375).** `product-lead`, `tech-lead`, `agents-lead` and `scrum-master` above the build, `developer`, `content-writer` and `content-reviewer` building, `quality-assurance` gating. **The eighth, `scrum-master` (#375), holds NO tools at all — declared as `tools: []`, never as an absent key, because an absent key inherits every tool the parent holds (#386)** — it ranks the eligible pool, names one profile plus one stage in a selection record, and the main session executes it; the reason it could be added is exactly that a profile holding nothing cannot enlarge the capability surface, which was the intake's objection to it. **`content-writer` was named `writer` until #317**, when the content pair landed; the rename rode in that slice rather than standing alone, because every roster surface was already being touched and paying the sweep twice buys nothing. The roster was modelling an org's ROLES, one per concern. The owner's criterion replaced that: **a persona exists only where conflict is wanted** — where someone should be arguing against someone else. Everything that generated no disagreement was a handoff, and the handoff was why it never ran. See ADR-0002's seventh amendment for the measurement, and its later amendment recording `writer`'s addition (#187) — a content-scoped second builder, added because a `content`-typed Issue had no mechanical builder at all, not because it argues with anyone.

**That one-line rule was struck on 2026-08-04 and survives as the first of four**, because it could not explain either move made that day: `agents-lead` was added although it argues with the *owner* rather than with another persona, and `security` was merged away although it produced real disagreement. A persona now exists for one of four reasons — **disagreement is wanted · a fresh context is wanted · the context window is the constraint · the capability should be smaller** — and the half that decides where one may be ADDED is that **reconciliation cost is paid within a tier, not across tiers**. The reasoning is in ADR-0002's tenth amendment and [`README.md`](../README.md#the-roster-and-what-each-tier-holds); it is not repeated here.

**The 2026-08-04 merge is a different argument and is recorded as one.** `marketing-lead` → `product-lead`, on the owner's decision: **the product IS the site and the site IS his professional presence** — one object, one lead — and fewer lead profiles means fewer agent outputs to reconcile at review time. The clause he ratified, which is not optional: the copy lens keeps a **BLOCKING veto on published claims**. `product-lead` was purely advisory; the merged persona is advisory on order, scope and craft, and **blocking on the truth of anything published** — **narrowed 2026-09-03: that veto no longer reaches the `content` stream, where the copy lens is `content-reviewer`'s and is exercised as a repair rather than a veto. It is unchanged everywhere else, and `content` intake is unchanged too** (ADR-0002, thirty-second amendment). It returns the two classes separately and labelled, because the split used to be structural (two personas) and is now a discipline of how the report is written.

The shape, and the harness-agnostic design (#261, [ADR-0002](./adr/0002-roster-and-dev-loop.md)) is in
[`README.md`](../README.md), the single canonical source since `docs/dev-loop-design.md` was retired to a
pointer stub:

| layer | who | why separate |
|---|---|---|
| **two leads** — disagree by design, then consolidate **ONE demand** | `product-lead` (reader, value, order, slice size — **and** positioning, voice, cross-surface coherence, the owner's career; its truth findings on published copy are **blocking**) · `tech-lead` (architecture, measurement, sequencing; **writes the product/system ADRs** — `agents-lead` writes the loop/machinery ones, split by domain since #223; leads the developer) | product-and-market vs system are genuinely different optimisations; where they agree the owner learns little |
| **the owner's pair on the MACHINERY** — same tier as the leads, and it takes no part in a story's intake | `agents-lead` — hooks, settings and permissions, agent briefs, skills, commands, the plugin, MCP; returns the scenarios a harness proposal does not cover, **before anything is built**, each with how to check it or labelled a hypothesis | the owner is CEO **and** harness engineer, and this is their pair in the second role only. It **gates nothing** — no merge request, no merge, no Issue — so it costs the leads nothing to reconcile: it never runs on the same work they do. It exists because second-order effects of a configuration change are invisible from inside the change; four were found by accident, after implementation, in a single day. *Cost:* ~~nothing enforces a dispatch, and there is no gate behind it, so an undispatched lens is indistinguishable from a clean one~~ **struck 2026-08-20 (#294) — a `Stop`-hook mitigation now exists** (`hooks/scripts/zombie-loop-detect.sh`), reading the same ADR-0006 `gatekeeper-verdict` artifact `session-wip.sh` already read at `SessionStart`, but at the end of every turn instead: an outstanding REQUEST-CHANGES/APPROVE-PENDING-HUMAN/APPROVE-EXECUTOR-BLOCKED verdict on the current PR head now surfaces one turn late, not one session late. It is detection, never prevention, and it never parses prose — it cannot tell narration from a tool call that was never attempted, only read committed loop state; see `README.md`'s hooks section for the full scope |
| **the process guardian, and the only profile that holds NOTHING** | `scrum-master` (#375) — `tools: []`, an explicit empty grant: no dispatch, no `Edit`, no `Bash`, no label, no milestone. **Explicit because omitting the key inherits everything** — measured through `Task` on build 2.1.252 (#386); in agent frontmatter, absence is inheritance. Derives and ranks the eligible pool from what it is shown, selects ONE profile plus stage, and returns a **selection record** the orchestrator executes and lands at `docs/selection/<iteration>.md`. Its mandate is the owner's, verbatim: *«a principal missao do SM é manter o loop rodando em formato scrum sem problemas»* — the rites happen, in order; the states move; nothing is skipped | **reason #2 of the four — a fresh context is wanted.** Selection is otherwise decided by the orchestrator, the context least able to see its own bias in a ranking. It reverses part of amendment #7 — which absorbed the old `scrum-master` into `product-lead` for producing no disagreement — and that finding still stands for what it measured: what returns is not ceremony facilitation or an ordering opinion (both still `product-lead`'s) but a written record naming who acts next, which nothing produced. **The overlap with the six hooks that already guard parts of "the loop runs in Scrum format" is decided rather than inherited** and is listed in its own brief; four states have no carrier at all and only those are its object. *Cost:* nothing dispatches it, nothing reads `SELECTION-RECORD`, and nothing verifies the pool it was shown — it is an influence mechanism, not a control, and it replaces a lock (`orchestrator-write-guard.sh`, removed in the same slice) with detection |
| **one builder** | `developer` — app, infrastructure, pipeline, tests inline | splitting it created a handoff decision, and none of the three specialists was ever dispatched |
| **a second builder, content-scoped** | `content-writer` (named `writer` until #317) — drafts articles, site copy and social-post language (LinkedIn/X) in the owner's voice: shapes, cuts, structures and translates an experience he already has, never originates one. Contained the same way `product-lead` is (`permission-guard.sh` rule 5e denies it direct posting) since it reads the same private positioning layer to draft | a `content`-typed Issue had no mechanical builder before #187 — `product-lead` holds no `Write`, `developer` is never dispatched there. Not folded into `developer`: the sourcing discipline (private material, validate-always, no autonomous-inference tier) is a different failure mode than code review, and `product-lead` already carries advisory truth-gating over what it drafts |
| **the pair that argues with it** — same tier, and the roster's first true pair | `content-reviewer` (#317) — reads a draft against `published-voice`, the same skill `content-writer` drafted against, for **at most two rounds**; since 2026-09-03 it **REPAIRS the draft in place** on exactly two grounds — it can **quote a clause** of that skill, or the claim is **false against the source** — and everything else is labelled advisory-and-droppable with the prose left alone. ~~may block only where it can quote a clause~~ — struck, there is no copy block on this lane at all. Terminal on the first round with no citable finding, or on the second round, whichever comes first. Contained by rule 5e like the other two, and its rounds land in a tracked file (`docs/content-review/<slug>.md`) rather than a comment | **reason #1 of the four — disagreement is wanted**, and it is the first persona added on that reason since the four-reason rule replaced the one-line one. The owner's ask: raise the bar of a draft *before* it reaches him. It is not a second gatekeeper — it runs pre-merge on the draft, `quality-assurance` runs post-build on the diff. **`product-lead` left the drafting flow at #317 (only the craft opinion), and left the COPY LENS entirely on 2026-09-03 — *«o content-reviewer pode assumir isso»*. Its `content` intake did not move; its veto elsewhere did not move.** The check became a repair rather than disappearing; what genuinely went unreplaced on this lane is the world-check (ADR-0002, thirty-second amendment) |
| **one gatekeeper** | `quality-assurance` — technical delivery against the DoD, **the cause of any failing gate**, **and** *can this cause a problem in production* (the floor, with its own veto) | it exists to fight the builder, on both axes at once. The two are different in kind — one has a ruler external to the gate (the requirements the leads agreed), the other has none and cannot, since *can this break production* is not enumerable in advance. So it holds **two lenses in one pass** and labels every finding with the one it came from; `agents/quality-assurance.md` carries what that costs and the behaviours that compensate |

**Absorbed rather than retired**, because the competence was kept and only the handoff was cut: `debugger` → `quality-assurance` (authorship bias corrupts *judgement*, not *investigation*, so the gate is already the right context to diagnose) · `security` → `quality-assurance` (the mandate moved whole; the **Edit** grant did not — that persona could edit precisely because it could not merge) · `adr-author` → `tech-lead` (whoever holds the decision writes its record, in the same MR as the change) · `brand-guardian` + `editor` + `recruiter` → `marketing-lead`, **and then `marketing-lead` → `product-lead` on 2026-08-04**, so all three now live there · `product-manager` + `product-owner` + `scrum-master` → `product-lead` · `analytics` → `tech-lead` · `frontend-react` + `iac-terraform-aws` + `devops-cicd` + `qa-e2e` + `sonar-remediator` + `performance` → `developer`.

**Retired outright:** `planner` and `plan-reviewer` — the owner writes the specs, in the Issues, in more detail than a planner would produce. The intake happens upstream of the loop, done by the person closest to it.


The lesson worth keeping: **a persona earns its place by generating a disagreement someone needs to hear**, not by completing an org chart. A mandate with no trigger is a document; a persona with no counterpart is a handoff. `agents-lead` is not the exception it looks like — its counterpart is **the owner**, wearing the harness-engineer hat, which is the one role in this loop that had nobody to argue with.

| Command | Purpose |
|---|---|
| `/definition-of-done` | SDLC-generic: what makes a Definition of Done a real ruler rather than a phrase, how to design one from scratch for a new project (starting from the project's own purpose, never from a generic/corporate template), what makes a criterion well-formed (objective, falsifiable, evidence-producing), the common DoD shapes (fixed checklist / per-item-type / automated gate) and the four failure modes of a badly-made one. Explicitly cross-referenced to `/definition-of-ready` — a DoD cannot rescue an item that was never properly ready. **AND, since #380, THIS loop's own concrete Definition of Done** — the criteria (including row 9, #362's *Reach*, which no gate can prove), the 100% functional-regression invariant, local and post-deploy validation, and the seam table naming **which criteria a gate proves and which nothing proves**. ~~This repo's own concrete DoD and gate policy is ONE application of it — see `/quality-gates` (#265)~~ — **struck #380: the DoD is here now; `/quality-gates` keeps the CI/CD half**, on the owner's own definitions (*«quality gates … metricas de ci/cd; definition of done … completude de um issue»*) |
| `/definition-of-ready` | SDLC-generic: what makes a work item ready to build, the checklist shape conditional on project surfaces (UI-heavy / backend / CLI-library), the flagship failure (scope fragmented across overlapping issues), and how it relates to estimation. **AND, since #380, THIS loop's own concrete readiness bar** — what the `ready` label asserts, the five items a closed description carries here, and the seam sentence naming which of them a mechanism checks and which nothing does. ~~This repo's own two-lead intake mechanism and `ready` label are ONE application of it — see `/agents-configuration` for that mechanism (#264)~~ — **struck #380 in its second half only: the BAR is here; the state machine of who acts at each transition stays in `/agents-configuration`**, where #329 put it on the argument that the universal preload is what every persona reads at the moment it dispatches |
| `/agents-configuration` | **The universal preload, carried by all ~~6~~ 8 profiles** — the figure was stale from #317, corrected at #375, and re-derived here against `ls agents/*.md | wc -l`. Names the discipline the whole plugin runs — Agent Harness Engineering / AI-DLC (the owner's central identity term, with Claude Code & Kiro) — and is **this loop's intentional design**: why it is shaped this way, the state machine (issue types, states, who acts, what artifact records it), the intake chain, the iteration axis, the inner-loop steps. It merged the former `dev-loop`, `loop-engineering` and `engineering-philosophy` into one file as `harness-engineering` (#224), and **#381 renamed it and split the judgment out** — the 12 principles are `/engineering-standards` now. The branching/topology diagrams (`gitflow-multi-env`, `trunk-single-env`) and the permission model live in `/devops` (#227), not here. |
| `/engineering-standards` | The **portable** half of that split (#381) — the owner's engineering preferences *«de forma mais abrangente»*: the two tiers (non-negotiable floor + risk-calibrated judgment), the **12** principles ~~with their triggers to deviate~~ — **struck #410: it read as *each carries one*, and one of eleven did; two of twelve do now (principles 1 and 12), and four cannot, because the floor is the tier that never bends. The falsifier ships with the claim, in the skill itself** — delivery against hygiene, what an agent does while blocked, and the human residual. **The cut test, applied paragraph by paragraph: would this still be true in a project that does not run this loop?** The operational ruler it was applied with is stated in the file — nothing in it names a persona, a hook, an ADR or an Issue of this repo. Preloaded by all 8 profiles too: the owner's default was *yes unless a persona demonstrably never needs the principles*, and none does. |
| `/quality-gates` | THIS loop's **CI/CD gate policy**, as two clearly-headed parts of one file: the verification thesis, the gate tables per loop model and the merge-class rules (Part I) — plus the stack-agnostic thresholds (lint=0, unit coverage ≥85%, contract/E2E, dependency + secret scanning, SAST) formerly the standalone `coverage` skill, folded in at #257. **Both halves of the Definition of Done are gone from here**: the generic concept left at #265, ~~THIS loop's concrete Definition of Done … the actual DoD, the 100% functional-regression invariant~~ **left at #380** — both now in `/definition-of-done`. No threshold moved and no gate changed; it was a relocation on the owner's definitions, not a retuning |
| `/planning-poker` | SDLC-generic: consensus estimation with a team — the simultaneous-reveal mechanic, the owner's own reframe (the specific unit barely matters; the real payoff is a long-run team-velocity signal, not per-item accuracy), when the ceremony is worth it versus a coarser gut-call or t-shirt-size pass, the four named failure modes (anchoring, poker on a badly-scoped story, false-fast convergence, the empty ritual), and its explicit dependency on `/definition-of-ready`. Reference pattern — this repo's own loop runs no human estimation ceremony (#266) |

### backend

The prior one-per-concern layout (19 files) consolidated into a single skill, `backend` (#230) — the former family
directory itself became the skill (`skills/backend/SKILL.md`), same naming pattern the issue set for
`frontend` (#231). Curated per ADR-0011's own test — *"the more a technical skill reads like
documentation about the technology, the less of a skill it is"* — applied with extra weight here
because this is a **reference with no live consumer**: `tadeumendonca-io` retired the BFF-on-Lambda +
DynamoDB + Cognito architecture this skill documents; it is kept deliberately as a knowledge-transfer
pattern, not a description of anything currently deployed.

| Command | Purpose |
|---|---|
| `/backend` | Implement a BFF-on-Lambda backend end to end: the Hono modular monolith, cross-cutting middleware (errors, logging, metrics, tracing, audit, action types), Redis cache-aside, config/secrets, the generated OpenAPI contract + Postman tests, notifications, OG-image + bot-rendering, and the shared quality gate |

### frontend

The prior one-per-concern layout (15 files) consolidated into a single skill, `frontend` (#231) — the
former family directory itself became the skill, same shape as `backend`. Live/active content, kept at full depth
(unlike `backend`, this documents the current consumer's actual stack): framework-react (the only
section with React/library snippets) → routing → state → api-client → authentication → authorization →
forms → pagination → design-system → storybook → ux-states → markdown → seo → analytics → playwright.

| Command | Purpose |
|---|---|
| `/frontend` | The React + Vite SPA end to end: bootstrap/providers, routing, state ownership, the typed BFF client, auth + cosmetic UI gating, forms, cursor pagination, the design system, Storybook, async UX states, markdown, SEO, GA4 analytics, and Playwright E2E |

### cloud-infrastructure

The prior one-per-service layout (21 files) consolidated into a single skill, `cloud-infrastructure` (#229) — same
consolidation pattern as `harness-engineering` (#224) and `devops` (#227): one section per AWS
service/capability (network, identity/security, config/secrets bus, data + cache, storage, compute, API
+ CDN edge, certificates, DNS, email/event fan-out, observability), each kept at the density the old
`vpc` exemplar set, now applied at section-grain rather than file-grain. Named provider-agnostically
(`cloud-infrastructure`, not `aws`) per the owner's 2026-08-13 decision — the content itself names AWS
explicitly as the CSP covered, since that's what all 21 source files documented.

| Command | Purpose |
|---|---|
| `/cloud-infrastructure` | AWS infrastructure end to end, one section per service: VPC, IAM, KMS, Secrets Manager, SSM, Cognito, WAF, DynamoDB, ElastiCache, S3, Lambda, API Gateway, CloudFront, ACM, Route53, SES, SNS, CloudWatch, CloudWatch RUM, CloudWatch X-Ray, and the Terraform setup that carries them all |

### DevOps and repo-practice skills

DevOps tooling. `devops` is the umbrella (#227) — GitHub/CI-CD (OIDC, secrets/environments, the deploy workflows, the Issues backlog, the Claude Code GitHub App automation folded in at #256), Terraform Cloud as the state backend, branching per loop model, the permission model that keeps IaC pipeline-only, the numeric-SemVer tagging rules (`versioning`, folded in at #258 since the trigger workflows it describes are pipeline wiring, the same object as everything else in this skill), and the SonarCloud quality-gate mechanics (`sonarcloud`, folded in at #259 for the same reason — the CI step it wires is pipeline wiring, not a separate capability), all in one skill, preloaded by `developer` and `agents-lead`. Test runners live with their repo (the backend's Postman collection is a section of `/backend`, `/playwright` is standalone); the stack-agnostic gate policy that used to be its own skill (`coverage`, extracted at #230) is now a section of `/quality-gates` — folded in at #257 once the two skills sat next to each other under near-identical names, still preloaded on every merge review regardless of stack because it travels with the skill every reviewing persona already carries; IaC checkov is in `/cloud-infrastructure`'s Terraform section. Architecturally-significant decisions are recorded via `documentation-standard`'s ADR section, split by domain (#223) — `adr` folded into `documentation-standard` at #260, as two clearly-headed parts of one file rather than two skills sharing a boundary that always needed a judgment call. Working-files and shell-command discipline — transversal across the whole roster, not DevOps-specific — is `shell`.

| Command | Purpose |
|---|---|
| `/devops` | GitHub Actions + Terraform Cloud + the permission model: OIDC, secrets/envs, branching per loop model, deploy workflows, TFC state backend, pipeline-only IaC, numeric SemVer versioning/tagging (bump-my-version, loop guard, PR labels), the Claude Code GitHub App (`@claude` assistant + automatic PR review, advisory/non-blocking), and the SonarCloud quality-gate mechanics (per-repo setup, the CI step, coverage import, blocking-gate wiring) |
| `/documentation-standard` | Repository documentation end to end, in two parts: Part I general docs (Markdown + Mermaid only, diagram types, where a doc lives, **and the MIT licensing standard — the `LICENSE` file plus the manifest field, folded in from the standalone `license` skill at #384 on the owner's ruling *«deveria»*: a `LICENSE` is a document at the repository root, which is the object Part I already governs**); Part II Architecture Decision Records (MADR format, two libraries — methodology/product, light significance gate, authorship split by domain #223, and the **current-codebase rule** that replaced supersede-never-delete at #281 — a reversed record is deleted with an **always-mandatory** History row, plus a `## What this replaced` fold into the superseding record **wherever there is one to fold into** — and where there is no fold target and no row is written, it is not deleted at all; citations quote the clause rather than a line number) — merged from the standalone `adr` skill at #260 |
| `/shell` | Where scratch files go, one atomic Bash call, the `gh --repo` flag position, `--body-file` always — ~~preloaded by all 7 personas~~ **preloaded by 7 of the 8 (#375): every persona that writes a file or runs a shell command.** `scrum-master` holds neither `Write` nor `Bash`, so the rule has no subject there and preloading it would be bytes with nothing to govern |
| `/code-review` | Author-side completeness pass before opening the MR: anticipates both gates, verifies the DoD with evidence |

### the content skills — the ruler two personas share, and the lane they share it inside

**Two skills since 2026-09-02, and they are split on OBJECT rather than on size:** `published-voice`
judges the **text**, `content-publishing` **moves** it. Both are carried by both halves of the pair, which
the gate below already required of any addition to either list.

One skill, and it exists to be **shared** rather than to be complete. `published-voice` holds every rule
a piece of published prose is judged against; `agents/content-writer.md` and
`agents/content-reviewer.md` hold what each persona *is* and may do.
The split is the point: the drafter and the ~~**content reviewer the owner has decided on and not yet
built**~~ **reviewer, built at #317,** must judge against the same sentences, or the pair produces two
opinions instead of a conflict. **The identity of the two `skills:` lists is gated**
(`hooks/scripts/inventory-counts.test.sh`, the *content pair* arms), which is what turns that sentence
from an intention into a mechanism.

**It is an acknowledged exception to ADR-0011's transversality test** — *if changing a persona's mandate
would change the rule, it is not transversal* — taken as *"extracted ahead of a decided second
consumer"* and recorded as such in ADR-0011's 2026-08-23 amendment, rather than as a new class of
single-consumer skill. **It is not a token saving and is not sold as one:** a preloaded skill is exactly
as always-on for a subagent as the brief text it replaces, and its `description` is additionally
always-on in every session that loads the library.

| Command | Purpose |
|---|---|
| `/published-voice` | The ruler for anything published in the owner's voice: the three anchors and their precedence, the goal/filter/byproduct block, the journey rule and its two corollaries, his voice in his own words, the 26-article Medium corpus and the half not to reproduce, the sourcing constraint and the subject bound, the three-clause title gate and the six ranked criteria it runs ahead of, and the teaser rules for a LinkedIn/X post that points at a piece |
| `/content-publishing` | The LANE a piece travels, end to end, with each step marked AFK / HITL / unbuilt: the interview at capture, the description closed by one lead, **the owner's selection — this lane is selected and never drained, so `ready` here is not a queue**, the draft, the two-round review bound, **the reviewer's repair-in-place on two named grounds** (~~the truth veto at the merge gate~~ — struck 2026-09-03: the copy lens moved to `content-reviewer` and there is no copy block left on this lane), the held preview at the real URL, release, and the LinkedIn + X pair in the same batch. Its flagship trade-off is **isolation is not privacy** — a held piece's text ships in the public bundle — and it names what nothing enforces: nothing fires it, nothing checks a held piece was read, nothing verifies the social pair shipped |
