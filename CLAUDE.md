# tadeumendonca-skills

Claude Code **plugin** (slash-command library) for the **tadeumendonca.io** platform — distributed
via the **marketplace in this repo** and consumed by **`tadeumendonca-io`** (the static site SPA in
`apps/fed` + its Terraform in `iac/`).
The commands are generic, reusable implementation guides (no AWS dependency to run).

Each command is a per-component guide: when the owner runs `/tadeumendonca-skills:frontend`,
Claude reads the guide and knows exactly how to implement that piece following this project's
established patterns (custom Tailwind design system, snake_case contracts, Terraform parametrization,
numeric SemVer, etc.).

> **The library is broader than its current consumer.** The `backend` skill and parts of `cloud-infrastructure`
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
- The VPC section of `skills/cloud-infrastructure/SKILL.md` (formerly the standalone
  `skills/vpc/SKILL.md`, folded in by #229) is the **density exemplar** — match it, at section-grain now
  rather than file-grain.

**Deep-dive authoring process (done in-place here):**
1. **Scaffold** the scenario space (Claude drafts the dense structure from sound practice + the platform repos).
2. **Elicit the owner's layer** — ask a few sharp questions (default posture? real triggers to deviate? rule
   of thumb? a war story?) and weave the answers into a **"My take / preference"** section.
3. Iterate per skill until it reads like a senior engineer's knowledge transfer. Go skill by skill / by domain.

**This process governs `agents/` as well as `commands/` (#162) — the same elicitation, aimed at the
behaviour layer instead of the knowledge layer.** A persona brief's own "My take" section is calibrated
the same way: a few sharp questions, woven in, not invented. No standing interview program is scheduled
— per #162's own recorded disagreement, calibrating six briefs because there are six treats the roster
as a checklist. Keep a running note of the specific moments a persona decided something the owner would
have decided differently, and calibrate from that note when material accumulates, not on a fixed cadence.

**Hard principles:** **project-agnostic** — generic `<project>` / `<apex-domain>` placeholders, **NO** real
names/domains/ARNs/ids; **English** (it's published); **additive density** (deepen; never thin out good content).

**State (last measured 2026-08-10 — re-verified, not re-stamped; one figure WITHDRAWN 2026-08-15, see
below):** the thin `## Decision & trade-off` baseline has landed across the **`cloud-infrastructure`**
and **`backend`** skills, including the VPC deep-dive **section** that is this repo's density exemplar.
The **deep-dive above is the active workstream**; those baseline sections are scaffolding to deepen, not
the goal.

~~the `infrastructure` and `backend` **families**, plus the `vpc` deep exemplar~~ — **struck #286, and
both halves were wrong in different ways.** *Families:* there are none; the tree is one level (see
*Command reference* below), and `infrastructure` was the directory name, never a skill's — the skill is
`cloud-infrastructure`. *The `vpc` exemplar:* `skills/vpc/SKILL.md` stopped being a file at **#229**,
when 21 per-service files became sections of one skill; the exemplar survives at section grain
(`skills/cloud-infrastructure/SKILL.md`), which is what the Mission section above already says. **The
`vpc` half was dead for six days before this slice and is fixed here because this slice is what made
someone read the sentence** — the drift is #286's only in the family half.

~~**the `frontend` family is still effectively unstarted — exactly one file in it carries a trade-off in
any form** (`grep -rl '^family: frontend' skills | xargs grep -il trade-off` → 1, `authentication`;
against the count published below).~~

**WITHDRAWN 2026-08-15, and deliberately not restated.** The measurement was taken on **2026-08-10**
against a **15-file** `frontend` family. It is withdrawn against this repo's own
**"publish the number with its command"** rule — *a measured number ships with the command that
produced it, inline and runnable, **or not at all*** — which it failed three ways at once, each a
different failure:

- **The falsifier is dead.** `family:` frontmatter went away at #182, so the published command matches
  nothing and emits nothing at head. A falsifier that fails open reads to whoever runs it as *"nothing
  to worry about"*, which is worse than publishing no command at all — and is exactly what the rule
  stated one paragraph above forbids.
- **`authentication` is not a file.** The family consolidated into a single `skills/frontend/SKILL.md`
  at **#231 (2026-08-13)**; what the figure counted is now a *section* of that file
  (`skills/frontend/SKILL.md:202`).
- **The denominator moved 15 → 1, which INVERTED the sentence.** "exactly one file in it" was one of
  **fifteen**. The family is now **one** file, so the same words read *one of one* — 100% of the family
  — while still being cited as the evidence that the family is "effectively unstarted". The number never
  became false; it started arguing the opposite of what it was published for, which is strictly harder
  to notice than a wrong number.

**No current figure replaces it, and that is the honest form rather than a thinning.** Restating it
would require judging where the `frontend` deep-dive now stands against one consolidated file — a
workstream call, the owner's to make, not a measurement anyone can re-run. Withdrawing a measurement
whose denominator moved is the same call the token-price paragraph below makes, for the same reason.

*The 2026-08-10 figure's own correction, kept as the record of the defect class and not as anything to
run:* the form published here until #164 was `grep -rl trade-off commands/frontend/`, which returned
**zero** — the one occurrence is written `Trade-off`, so the replacement carried `-i`. The figure was
right and the command beside it did not produce it — the exact failure that rule exists to make
visible. **Both spellings are dead at head.** That this
block's own header claimed re-verification while its published command returned nothing is that same
failure one layer up, and it is why the header now dates the measurement instead of asserting it.

*The date was re-checked rather than re-stamped.* A `State (…)` marker whose date is refreshed without
re-measuring is worse than a stale one: it converts an aging claim into a confidently wrong one, and the
reader has no way to tell which happened. The measurement is written next to the claim so the next
person can falsify it in one command instead of trusting the date.

---

## Installation (Claude Code plugin)

This repo is a **Claude Code plugin + marketplace** — the native way to reuse skills across
projects. The skill library lives in `skills/`, one directory per skill holding a `SKILL.md`, and the three
commands a human types live in `commands/` (`autonomy-on`, `autonomy-off`, `new-issue`);
`.claude-plugin/marketplace.json` is the catalog and
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
not distinguish them.** **Measured on 2026-08-10**, `claude plugin details` on the split tree reported
**`Skills (71)`** — the 69 the library held under `skills/` then, **plus the 2 then under `commands/`**,
counted alike, reachable alike. **Both denominators have moved since** — the library consolidated to 13
(`jq -r '.skills[]' .claude-plugin/plugin.json | wc -l` → 13, re-run #286) and `commands/` holds 3
(`ls commands/` → `autonomy-off.md autonomy-on.md new-issue.md`, re-run #286) — so read the 71 as the
measurement that established the rule, not as today's inventory. **The rule is what survives the
denominators:** the loader counts both directories alike.

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
| lives in | `commands/<name>.md` | `skills/<name>/SKILL.md` — one level, no families since #286 — declared in `plugin.json` |
| invocable as `/plugin:<name>` | yes | yes |
| reachable by the `Skill` tool | yes | yes |
| preloadable via a persona's `skills:` | yes | yes |
| `$ARGUMENTS` interpolates | yes | yes — measured, with `$NOTAVARIABLE` surviving literally as the control |

**The last four rows are identical on purpose: there is no mechanical difference left.** What separates
the two is what the file is *for*, and `hooks/scripts/inventory-counts.test.sh` asserts it **in both
directions** — removing `argument-hint` from a typed command reddens, and adding one to a skill reddens.
The distinction is gated, not conventional.

**The cost this makes visible, measured on 2026-08-10 against the 69 descriptions the library held
then:** those 69 totalled ~28 KB and became **always-on**, about **+9,919 tokens per session**
(`Skills (2)` ≈ 1,444 tok → `Skills (71)` ≈ 11,363 tok). The trigger-description standard — record 0009
until 2026-08-20, now a section of [ADR-0011](./docs/adr/0011-skills-and-preload.md) — made those
descriptions dense deliberately; **that decision was free while nothing loaded them and stopped being free once they
loaded.** Nobody has revisited it — that is an open decision, not a settled one.

**That figure is the price at its measurement, not the price today, and the denominator is why.** The
library has consolidated to **13** since (`jq -r '.skills[]' .claude-plugin/plugin.json | wc -l` → 13,
the same figure the sections below list), so the per-session cost is smaller by some amount
this file deliberately does not state. Re-measuring and publishing a current number would swap a
checkable historical claim — 69 descriptions, one date, one command — for a current one sourced to a
machine no reader and no gate can re-run. `tadeumendonca-io`'s `/architecture` gave the same figure the
same treatment for the same reason.

### Usage

Plugin commands and skills are **namespaced under the plugin name**, and the name is the file's own
**innermost** directory (`skills/cloud-infrastructure/SKILL.md` → `cloud-infrastructure`). Since #286
that is also the ONLY directory — the tree is one level — but the rule was never about the tree's shape:
the loader read the innermost name at every depth this library has had. Type it and pass context after
it (received as `$ARGUMENTS`):

```
/tadeumendonca-skills:backend posts
/tadeumendonca-skills:cloud-infrastructure staging
/tadeumendonca-skills:devops production
```

**A side effect of losing the family segment, and it is the best one:** an unresolved identifier
**without** a slash returns `Unknown command:`, while one **with** a slash is not recognised as a command
at all — it falls through as ordinary prompt text and the model improvises a plausible answer. Every
identifier this plugin published used to contain a slash. **None does now**, so a broken invocation
fails loudly instead of silently. **Neither the family directories arriving on #182 nor their removal on
#286 cost this**, which is the reason the identifiers were kept bare rather than re-qualified: the loader
takes the innermost directory either way, so the tree has changed shape three times and the namespace has
not changed once.

### Releasing a version

**Trunk-based** (`trunk-single-env`, consumed-artifact variant) — this repo is a *consumed dependency*
(by `tadeumendonca-io`), not an app with environments, so it does **not** use GitFlow. There is one long-lived branch, **`main`**: skill
work lands via short-lived `feature/*` / `docs/*` PRs, and `main` is always releasable. Pushing to
`main` does **not** auto-version — the version is a deliberate, consumer-facing decision decoupled
from integration.

A release is cut **on demand** from the `release` workflow (numeric SemVer, see `/devops`'s "Versioning
& tags" section):

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

**13 skills, one directory each, at ONE level under `skills/` (#286)** — the owner's decision: *"o que
eu quero é que todas skills estejam no mesmo nível hierárquico de diretórios."* **The headings below are
a reading structure in this document and nothing else.** They were directories until #286 (`principles/`,
`backend/`, `frontend/`, `infrastructure/`, `workflow/`), and the reason they were is recorded in the
next paragraph rather than deleted, because it is a measurement and it is still true about the tree it
was made on.

**Why the directories existed, and why that reason lapsed.** They came back at #182 on the owner's call,
for the human reading the library: a category teaches what a skill IS in a way an alphabetical list of
**69** does not. That argument was about a denominator. The library is **13**
(`jq -r '.skills[]' .claude-plugin/plugin.json | wc -l` → 13), after `#229`/`#230`/`#231` consolidated
21, 19 and 15 files into one skill each — so the pile the grouping protected a reader from no longer
exists. **What did NOT change is the identifier**: the loader reads the innermost directory name at any
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

**Six personas, down from nineteen, plus one added back deliberately (#187).** `product-lead`, `tech-lead` and `harness-lead` above the build, `developer` and `writer` building, `quality-assurance` gating. The roster was modelling an org's ROLES, one per concern. The owner's criterion replaced that: **a persona exists only where conflict is wanted** — where someone should be arguing against someone else. Everything that generated no disagreement was a handoff, and the handoff was why it never ran. See ADR-0002's seventh amendment for the measurement, and its later amendment recording `writer`'s addition (#187) — a content-scoped second builder, added because a `content`-typed Issue had no mechanical builder at all, not because it argues with anyone.

**That one-line rule was struck on 2026-08-04 and survives as the first of four**, because it could not explain either move made that day: `harness-lead` was added although it argues with the *owner* rather than with another persona, and `security` was merged away although it produced real disagreement. A persona now exists for one of four reasons — **disagreement is wanted · a fresh context is wanted · the context window is the constraint · the capability should be smaller** — and the half that decides where one may be ADDED is that **reconciliation cost is paid within a tier, not across tiers**. The reasoning is in ADR-0002's tenth amendment and [`README.md`](./README.md#the-roster-and-what-each-tier-holds); it is not repeated here.

**The 2026-08-04 merge is a different argument and is recorded as one.** `marketing-lead` → `product-lead`, on the owner's decision: **the product IS the site and the site IS his professional presence** — one object, one lead — and fewer lead profiles means fewer agent outputs to reconcile at review time. The clause he ratified, which is not optional: the copy lens keeps a **BLOCKING veto on published claims**. `product-lead` was purely advisory; the merged persona is advisory on order, scope and craft, and **blocking on the truth of anything published**. It returns the two classes separately and labelled, because the split used to be structural (two personas) and is now a discipline of how the report is written.

The shape, and the harness-agnostic design (#261, [ADR-0002](./docs/adr/0002-roster-and-dev-loop.md)) is in
[`README.md`](./README.md), the single canonical source since `docs/dev-loop-design.md` was retired to a
pointer stub:

| layer | who | why separate |
|---|---|---|
| **two leads** — disagree by design, then consolidate **ONE demand** | `product-lead` (reader, value, order, slice size — **and** positioning, voice, cross-surface coherence, the owner's career; its truth findings on published copy are **blocking**) · `tech-lead` (architecture, measurement, sequencing; **writes the product/system ADRs** — `harness-lead` writes the loop/machinery ones, split by domain since #223; leads the developer) | product-and-market vs system are genuinely different optimisations; where they agree the owner learns little |
| **the owner's pair on the MACHINERY** — same tier as the leads, and it takes no part in a story's intake | `harness-lead` — hooks, settings and permissions, agent briefs, skills, commands, the plugin, MCP; returns the scenarios a harness proposal does not cover, **before anything is built**, each with how to check it or labelled a hypothesis | the owner is CEO **and** harness engineer, and this is their pair in the second role only. It **gates nothing** — no merge request, no merge, no Issue — so it costs the leads nothing to reconcile: it never runs on the same work they do. It exists because second-order effects of a configuration change are invisible from inside the change; four were found by accident, after implementation, in a single day. *Cost:* nothing enforces a dispatch, and there is no gate behind it, so an undispatched lens is indistinguishable from a clean one |
| **one builder** | `developer` — app, infrastructure, pipeline, tests inline | splitting it created a handoff decision, and none of the three specialists was ever dispatched |
| **a second builder, content-scoped** | `writer` — drafts articles, site copy and social-post language (LinkedIn/X) in the owner's voice: shapes, cuts, structures and translates an experience he already has, never originates one. Contained the same way `product-lead` is (`permission-guard.sh` rule 5e denies it direct posting) since it reads the same private positioning layer to draft | a `content`-typed Issue had no mechanical builder before #187 — `product-lead` holds no `Write`, `developer` is never dispatched there. Not folded into `developer`: the sourcing discipline (private material, validate-always, no autonomous-inference tier) is a different failure mode than code review, and `product-lead` already carries advisory truth-gating over what it drafts |
| **one gatekeeper** | `quality-assurance` — technical delivery against the DoD, **the cause of any failing gate**, **and** *can this cause a problem in production* (the floor, with its own veto) | it exists to fight the builder, on both axes at once. The two are different in kind — one has a ruler external to the gate (the requirements the leads agreed), the other has none and cannot, since *can this break production* is not enumerable in advance. So it holds **two lenses in one pass** and labels every finding with the one it came from; `agents/quality-assurance.md` carries what that costs and the behaviours that compensate |

**Absorbed rather than retired**, because the competence was kept and only the handoff was cut: `debugger` → `quality-assurance` (authorship bias corrupts *judgement*, not *investigation*, so the gate is already the right context to diagnose) · `security` → `quality-assurance` (the mandate moved whole; the **Edit** grant did not — that persona could edit precisely because it could not merge) · `adr-author` → `tech-lead` (whoever holds the decision writes its record, in the same MR as the change) · `brand-guardian` + `editor` + `recruiter` → `marketing-lead`, **and then `marketing-lead` → `product-lead` on 2026-08-04**, so all three now live there · `product-manager` + `product-owner` + `scrum-master` → `product-lead` · `analytics` → `tech-lead` · `frontend-react` + `iac-terraform-aws` + `devops-cicd` + `qa-e2e` + `sonar-remediator` + `performance` → `developer`.

**Retired outright:** `planner` and `plan-reviewer` — the owner writes the specs, in the Issues, in more detail than a planner would produce. The intake happens upstream of the loop, done by the person closest to it.

Two rules the owner set for the loop, above every persona's own checklist: **it is a machine for grinding work down, not for generating it** (twenty-two findings on a documentation PR is one slice converted into fifteen), and **nothing ships half-done** — close what can be closed, and say plainly what could not.

The lesson worth keeping: **a persona earns its place by generating a disagreement someone needs to hear**, not by completing an org chart. A mandate with no trigger is a document; a persona with no counterpart is a handoff. `harness-lead` is not the exception it looks like — its counterpart is **the owner**, wearing the harness-engineer hat, which is the one role in this loop that had nobody to argue with.

**The orchestrator is the main session itself — one name, not a sixth persona** (ADR-0002). It is not
dispatchable: no `Task` invocation ever targets it, and it satisfies none of the four reasons a persona
exists (amendment #10 above). Its **duties**: dispatches every persona (no persona talks to another
directly); commits and pushes on the loop's behalf; applies the `ready` label once the two intake leads
have closed an Issue's description; applies the ADR-0002 routing label (`product`/`content`/`loop`); and
decides, in the moment, whether a given review specialist needs dispatching at all — a real judgment
call, not a formality.

Its **boundary is stated in two honest parts, not one.** Mechanically enforced, for exactly two acts:
merge and direct push to the trunk — `hooks/scripts/permission-guard.sh` leaves the orchestrator's
`agent_type` empty by design, and rules 7 (trunk push) and 7b (merge) fire against that empty value.
**Not enforced, and not claimed to be:** label application — `gh issue edit`/`gh label` sit in the global
allow, unscoped to who calls them — and the dispatch-omission judgment call, which is a different failure
shape than "decides the irreversible": an omission nobody can see happened or didn't, not a decision on
an irreversible act. See ADR-0002 for the full record.

| Command | Purpose |
|---|---|
| `/definition-of-done` | SDLC-generic: what makes a Definition of Done a real ruler rather than a phrase, how to design one from scratch for a new project (starting from the project's own purpose, never from a generic/corporate template), what makes a criterion well-formed (objective, falsifiable, evidence-producing), the common DoD shapes (fixed checklist / per-item-type / automated gate) and the four failure modes of a badly-made one. Explicitly cross-referenced to `/definition-of-ready` — a DoD cannot rescue an item that was never properly ready. This repo's own concrete DoD and gate policy is ONE application of it — see `/quality-gates` (#265) |
| `/definition-of-ready` | SDLC-generic: what makes a work item ready to build, the checklist shape conditional on project surfaces (UI-heavy / backend / CLI-library), the flagship failure (scope fragmented across overlapping issues), and how it relates to estimation. This repo's own two-lead intake mechanism and `ready` label are ONE application of it — see `/harness-engineering` for that mechanism (#264) |
| `/harness-engineering` | **The universal preload, carried by all 6 profiles.** Names the discipline the whole plugin runs — Agent Harness Engineering / AI-DLC (the owner's central identity term, with Claude Code & Kiro) — and is the loop itself: the state machine (issue types, states, who acts, what artifact records it), the intake chain, the inner-loop steps, **and** the 11 engineering principles in two tiers (non-negotiable floor + risk-calibrated judgment) that shape every decision inside it. Merges the former `dev-loop`, `loop-engineering` and `engineering-philosophy` into one file (#224). The branching/topology diagrams (`gitflow-multi-env`, `trunk-single-env`) and the permission model live in `/devops` (#227), not here. |
| `/quality-gates` | THIS loop's concrete Definition of Done AND the gate policy that proves it, as two clearly-headed parts of one file: the thesis, the actual DoD, the 100% functional-regression invariant, the gate tables per loop model (Part I) — plus the stack-agnostic thresholds (lint=0, unit coverage ≥85%, contract/E2E, dependency + secret scanning, SAST) formerly the standalone `coverage` skill, folded in at #257. The generic concept of what a DoD is and how to design one moved to `/definition-of-done` (#265) |
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

DevOps tooling. `devops` is the umbrella (#227) — GitHub/CI-CD (OIDC, secrets/environments, the deploy workflows, the Issues backlog, the Claude Code GitHub App automation folded in at #256), Terraform Cloud as the state backend, branching per loop model, the permission model that keeps IaC pipeline-only, the numeric-SemVer tagging rules (`versioning`, folded in at #258 since the trigger workflows it describes are pipeline wiring, the same object as everything else in this skill), and the SonarCloud quality-gate mechanics (`sonarcloud`, folded in at #259 for the same reason — the CI step it wires is pipeline wiring, not a separate capability), all in one skill, preloaded by `developer` and `harness-lead`. Test runners live with their repo (the backend's Postman collection is a section of `/backend`, `/playwright` is standalone); the stack-agnostic gate policy that used to be its own skill (`coverage`, extracted at #230) is now a section of `/quality-gates` — folded in at #257 once the two skills sat next to each other under near-identical names, still preloaded on every merge review regardless of stack because it travels with the skill every reviewing persona already carries; IaC checkov is in `/cloud-infrastructure`'s Terraform section. Architecturally-significant decisions are recorded via `documentation-standard`'s ADR section, split by domain (#223) — `adr` folded into `documentation-standard` at #260, as two clearly-headed parts of one file rather than two skills sharing a boundary that always needed a judgment call. Working-files and shell-command discipline — transversal across the whole roster, not DevOps-specific — is `command-hygiene`.

| Command | Purpose |
|---|---|
| `/devops` | GitHub Actions + Terraform Cloud + the permission model: OIDC, secrets/envs, branching per loop model, deploy workflows, TFC state backend, pipeline-only IaC, numeric SemVer versioning/tagging (bump-my-version, loop guard, PR labels), the Claude Code GitHub App (`@claude` assistant + automatic PR review, advisory/non-blocking), and the SonarCloud quality-gate mechanics (per-repo setup, the CI step, coverage import, blocking-gate wiring) |
| `/documentation-standard` | Repository documentation end to end, in two parts: Part I general docs (Markdown + Mermaid only, diagram types, where a doc lives); Part II Architecture Decision Records (MADR format, two libraries — methodology/product, light significance gate, authorship split by domain #223, and the **current-codebase rule** that replaced supersede-never-delete at #281 — a reversed record is deleted with an **always-mandatory** History row, plus a `## What this replaced` fold into the superseding record **wherever there is one to fold into** — and where there is no fold target and no row is written, it is not deleted at all; citations quote the clause rather than a line number) — merged from the standalone `adr` skill at #260 |
| `/command-hygiene` | Where scratch files go, one atomic Bash call, the `gh --repo` flag position, `--body-file` always — preloaded by all 6 personas |
| `/code-review` | Author-side completeness pass before opening the MR: anticipates both gates, verifies the DoD with evidence |
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

## Scratch — the session scratchpad, not a repo directory (#245)

**A repo-root `.scratch/` used to be the documented place for throwaway files. It is retired.** It was
designed on the belief that WHERE a scratch file lives affects permission friction; measured directly on
#230/#231/#244, it does not — the friction (a prompt on `command > newfile`) fires the same regardless
of destination, and #244 already closed the actual cause (`permission-guard.sh` now denies the
redirect outright, everywhere). Carrying a repo-side scratch directory bought nothing that fix didn't
already buy, and cost a sweep hook, a gitignore entry, and a rule that only lived in agent-brief prose —
exactly the shape #164 already named as the failure mode this repo tries hardest to avoid.

**Use the harness's own session scratchpad instead** — the path it hands you at session start,
session-specific and isolated from the tracked tree by construction. No repo directory to document, no
sweep hook to maintain: the harness owns that lifecycle, not this plugin.

**The taxonomy still matters, only the location column changed:**

| what | where |
|---|---|
| PR bodies, commit messages | **the session scratchpad** — written once, consumed by `--body-file`, discarded when the session ends. |
| lens and gate verdicts | **the PR comment.** It is the durable record for both — and the **gate** verdict is additionally machine-read by `session-wip.sh`, which matches the `gatekeeper-verdict: quality-assurance` marker and nothing else; a lens verdict has no reader but a human. A file copy is a second source of truth with no reader either way — and it is what broke: the file handoff failed twice while `SendMessage` failed zero times. |
| interview transcripts, raw source material | **`.brand/` in `tadeumendonca-io`** — private and gitignored *there*, which is the documented home for exactly this. **It is NOT gitignored in this repo**, so the path is only safe in the repo that ignores it; writing private material to `.brand/` here puts it in a tracked path in a public repo. |
| a measurement instrument | **a repo script with a test, if and only if a gate will run it.** Otherwise discard. "It worked once" is not "it must persist". |
| an isolated checkout | **not a scratch class.** Use the repo — WIP=1 already serialises — or a git worktree with its own install. |

**What this drops, and why it's safe to drop.** `session-scratch.sh` (a `SessionStart` hook that swept
`<repo-root>/.scratch/`, plus its test suite) is deleted outright rather than repointed — it existed
only because the scratch lived inside the tracked tree, where nothing else would ever clean it up. The
session scratchpad has no such gap: it is not part of any repo, so there is nothing here for a repo-side
hook to own.

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
