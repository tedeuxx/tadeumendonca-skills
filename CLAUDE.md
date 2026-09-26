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

## `AGENTS.md` is a SECOND root brief, it is AUTHORED, and it is not this file (#411)

**`AGENTS.md` at this repo's root is the whole brief for any harness that reads that filename — and one
of them reads THIS file never.** Measured against Kiro `1.0.437`'s shipped bundle: `grep -c 'CLAUDE\.md'`
over its agent extension returns **0**, while `AGENTS.md` is a bundle constant resolved at the workspace
root with `inclusion:"always"`. So it is not a compatibility copy of this file; for that reader it is the
only brief there is.

**It is authored beside this file. It is NOT generated from it, and a generator is not available as a
fallback** — Kiro truncates `AGENTS.md` at **50,000 characters**, logging the loss on a debug channel
and appending a literal `[Truncated: …]` marker into the text the model reads (so the LOSS is announced
to the reader, never to a human watching, and never says WHAT was lost), while this file is far past
that, so a rename-only transform cannot produce a loadable
artifact at all. Both figures with the command that produced them:

```
python3 -c "
for p in ['AGENTS.md','CLAUDE.md']:
    print(p, len(open(p,encoding='utf-8').read()))"
```

**The 50,000 budget is ONE consumer's measured floor, not a standard**, read out of a shipped bundle on
a machine where that tool has never authenticated. Every other harness's budget is unmeasured.

**Three rules, and the first two are what a substitution pass violates.** The brief states the floor as
**obligations addressed to the agent, never as descriptions of the enforcement** — the test is *would
this sentence still be true on a harness with no hooks?* It names **no Claude-Code-shaped token**: a
substitution renames the token and leaves the mechanism, which is how the pre-#411 file came to instruct
its reader to open `.Codex-plugin/plugin.json` and three sibling identifiers that exist nowhere. And it
is **tracked**, which is the precondition for the other two being reviewable at all — it was untracked
and referenced by nothing until #411, so no PR ever contained it.

`hooks/scripts/agents-md.test.sh` gates four mechanical properties (tracked · under budget with headroom
· no declared harness-specific token · every repo-relative path resolves). **It cannot assert that the
brief is true, or that it is neutral rather than merely token-free** — a sentence describing one
harness's mechanism without naming it passes every arm. That half is held by review.

**`tadeumendonca-io` is to carry the same artifact under the same rule** — in its own merge request
(`-io`#610), which had not landed when this sentence was written, so read it as the rule and not as a
description of that repository's `main`. Every sentence crossing the repository boundary is true on
the day **its own** repository merges, never on the day the other one does.

**What is shared with its checker at `scripts/agents-md.test.sh` is the executable BODY, not the
file.** The invariant a sync maintains is that everything below the first column-zero `set -uo` line
is byte-for-byte identical — an obligation, not a claim about either copy's current state, which
nothing here can check. The header deliberately differs, because the duplication cost is a fact about
that copy and has no subject here.
So a sync copies the body, never the file — copying the whole file destroys the sibling's header,
which is the artifact that records the cost and carries its own falsifier. From a workspace holding
both checkouts:

```
diff <(sed -n '/^set -uo/,$p' hooks/scripts/agents-md.test.sh) \
     <(sed -n '/^set -uo/,$p' ../tadeumendonca-io/scripts/agents-md.test.sh)
```

Nothing makes the two copies move together — a pipeline is independent per repo — so a change to the
token list, the fixtures or the budget is a two-repo batch, and until the sibling's merge request
lands that command is expected to print the body changes made here.

---

## Installation (Claude Code plugin)

This repo is a **Claude Code plugin + marketplace** — the native way to reuse skills across
projects. The skill library lives in `skills/`, one directory per skill holding a `SKILL.md`, and the
**seven** command files a human types live in `commands/` (`ls commands/` → `autonomy.md blueprint.md
funnel-review.md new-issue.md sprint-planning.md sprint-retrospective.md sprint-review.md`), carrying
**nine** non-help
typed forms — `autonomy on`, `autonomy off`, `new-issue`, `blueprint export`, `blueprint import`,
`sprint-review`, `sprint-retrospective`, `sprint-planning`, `funnel-review` — because
`autonomy` and `blueprint` each carry modes and a bare invocation of either only prints help;
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

**`powers/` is a SECOND distribution surface and is GENERATED — never edit it (#287).** It holds the
Kiro Power export (`powers/tadeumendonca-skills/`), written from `skills/` by
`hooks/scripts/kiro-power-build.py` and gated by `hooks/scripts/kiro-power.test.sh`, which regenerates
into a temp directory and diffs. Editing the export by hand turns that gate red; edit
`skills/<name>/SKILL.md` and regenerate. **It carries the skills and nothing else, by choice** — the
enforcement layer is Claude-Code-shaped (`hooks.json`, `PreToolUse` matchers, an `agent_type` the harness
stamps) and porting it is work nobody has done, so the export is this harness's knowledge layer without
its enforcement layer. ~~**Whether a Kiro build implementing the Agent Plugins format would carry
`agents/`, `hooks/` or `commands/` is NOT measured and is claimed in neither direction** — the only
installer this repo has read belongs to a build predating that format.~~ **Measured 2026-08-23 (#287)
against Kiro `1.0.337` (`quality: stable`, bundle 2026-08-18), and the answer splits in two:
transport yes, activation no.** The installer copies a package's whole tree minus `.git`
(`AGENT_PLUGIN_EXCLUDED_DIRS = new Set([".git"])`), so `agents/` and `hooks/` would arrive; the loader
resolves only `plugin.json`, `skills/`, `mcp.json` and `dev.kiro/`, and `~/.kiro/powers/` is never
scanned for a persona or a hook — so they would arrive **inert**. **Keep the two words apart: that is
the whole reason shipping `agents/` would be worse than not shipping it** — a missing directory
announces itself, a copied-but-never-read one reads as installed, which is this repo's own named
failure shape. **Read out of the shipped bundle, not from a live install** — nothing here was
exercised in an authenticated Kiro session and no Power has ever been installed on the measuring
machine. The command, the evidence, the element-by-element gap and the Kiro CLI-vs-IDE distinction are
in [`README.md`](./README.md); the decision is ADR-0005's 2026-08-21 amendment, unchanged by this
measurement.

### What is a command and what is a skill — three rules, and only one of them is a mechanism

This took a full session to arrive at and was written down nowhere. **Measured, not read from docs.**

**1 · The folder is for the human. It is not a mechanism.**
`commands/` and `skills/` are two top-level directories because a reader opening this repo should not
meet a library and a control surface in the same pile — the owner's reason, in his words: *"o problema é
a contaminação na leitura do repositório por humanos se tudo ficar no mesmo lugar."* **The loader does
not distinguish them.** **Measured on 2026-08-10**, `claude plugin details` on the split tree reported
**`Skills (71)`** — the 69 the library held under `skills/` then, **plus the 2 then under `commands/`**,
counted alike, reachable alike. **Both denominators have moved since** — the library consolidated to 14
and has since gained one (`jq -r '.skills[]' .claude-plugin/plugin.json | wc -l` → 15, re-run
2026-09-02) and `commands/` holds 7
(`ls commands/` → `autonomy.md blueprint.md funnel-review.md new-issue.md sprint-planning.md
sprint-retrospective.md sprint-review.md`, re-run 2026-09-11) — so read the 71 as the
measurement that established the rule, not as today's inventory. **The rule is what survives the
denominators:** the loader counts both directories alike.

**2 · DECLARATION is what registers a skill. The root is only the default.**

~~**The root is for the loader's SKILL INDEX. Nesting kept the 69 out of it — and only out of it.**
Before the split the same command reported `Skills (2)` — `autonomy on` and `new-issue`, the only two
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

**A second field is gated the same way and applies to BOTH columns — `purpose:` (#313).** Every
mechanism this plugin ships — a hook **registered in `hooks/hooks.json`**, a persona in `agents/`, a
typed command, a skill **declared in `plugin.json`** — carries exactly one `purpose:` line, and every
declaration must name a mechanism that exists. **It is not `description:` and the gate asserts the two
differ:** `description:` is a *trigger* addressed to the model (*when do I reach for this*), `purpose:`
is an *obligation* addressed to an engineer on a harness nobody here has measured (*why does this exist,
and what is lost without it*). **The declaration is positional** — line 2 of a hook script, a frontmatter
key in a markdown mechanism — because `# purpose:` already occurred at column 0 as ordinary wrapped
prose in this tree, found by the arm's first run. **No count is published here**, deliberately: the
number moves with every mechanism added, and a prose figure beside a derived one is the arrangement this
repo's own gate exists because it rots. The decision, the discharged `-io` deferral and the rejected
option are ADR-0021's 2026-08-28 amendment; what the green does *not* mean — nothing can tell a true
purpose from a plausible one — is stated in the gate's own header.

**The cost this makes visible, measured on 2026-08-10 against the 69 descriptions the library held
then:** those 69 totalled ~28 KB and became **always-on**, about **+9,919 tokens per session**
(`Skills (2)` ≈ 1,444 tok → `Skills (71)` ≈ 11,363 tok). The trigger-description standard — record 0009
until 2026-08-20, now a section of [ADR-0011](./docs/adr/0011-skills-and-preload.md) — made those
descriptions dense deliberately; **that decision was free while nothing loaded them and stopped being free once they
loaded.** Nobody has revisited it — that is an open decision, not a settled one.

**That figure is the price at its measurement, not the price today, and the denominator is why.** The
library has consolidated and then grown again to **15** since (`jq -r '.skills[]'
.claude-plugin/plugin.json | wc -l` → 15,
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

## Command reference — the catalogue is `docs/command-reference.md` now

**The per-skill catalogue left this file on 2026-09-22, and the reason is a budget with a hard edge.**
`CLAUDE.md` had crossed the harness's 150,000-character limit, and this section was the largest block
in it that binds nobody. Both figures with the command that produced them:

```
git show c3bb1838:CLAUDE.md | python3 -c "
import sys; s=sys.stdin.read(); i=s.index('## Command reference')
print(len(s), len(s[i:s.index(chr(10)+'## ', i+1)+1]))"
# -> 151076 32539   (the section was 21.5% of the file)
```

**The base of that measurement is INSIDE this diff, which is why it reads `c3bb1838` — the commit
before the cut — rather than the working tree.** Run against the working tree the same selector returns
the post-cut length and a pointer-sized section, so a reader who took the obvious spelling would be
told the published figures are wrong. This repo's own rule is that a number ships with the command that
produced it; where the subject moved in the same slice, the command has to name the state it was
measured on or it is a falsifier that refutes a true claim.

**The cut test is the one the four blocks below are already written against.** `CLAUDE.md` is the only
brief that reaches the ORCHESTRATOR — the main session, dispatched by nobody and preloading nothing
(#409, one nonce per candidate surface: a repo-root `CLAUDE.md` reaches that context, a skill body does
not, `AGENTS.md` does not). So each paragraph was asked *is this an obligation the orchestrator must
obey, or a reading structure for a human?* **Reading structure moved. The obligations stayed, in the
section immediately below**, which is where they always belonged and never sat.

**What moved, verbatim and with every strike intact:** the **15 skills** inventory and the one-level
tree decision (#286), the family-heading history (#182), the consolidation narratives
(#229/#230/#231), the roster narrative with its layer table, the absorbed-and-retired lists, and all
six per-skill `| Command | Purpose |` tables. Read it at
[`docs/command-reference.md`](./docs/command-reference.md).

**And one fact was PULLED BACK OUT of the move, by the gate rather than by the cut test.** The name of
the discipline this whole plugin runs — **Agent Harness Engineering**, the owner's own term, with AI-DLC
as its industry-facing synonym — occurred in this file exactly once, inside the `/agents-configuration`
row of a table. `hooks/scripts/inventory-counts.test.sh` requires this file to name it, and reddened on
the first pass of this cut. It is stated here now rather than delegated: what the loop is called is not
a reading structure, and it does not belong to the catalogue of what each command does.

**One sentence was DELETED rather than moved, because `README.md` already carried it** — *"15 skills,
one directory each, at one level under `skills/`"* is `README.md:1141`. **The rest is a RELOCATION and
not a deduplication**, which is worth saying because the two documents overlap without agreeing: that
README section carries a **generated** per-skill table (`skill | what it decides | whose domain`,
written by `hooks/scripts/skills-table.py`, whose third column is a truncated first line of body) and
the per-persona preload lists; the relocated file carries the **authored** purpose prose and the
history. Nothing asserts the two agree.

**Why `docs/` and not `README.md`, since both were on the table.** README already holds both halves of
this in derived form — the roster shape, which the relocated narrative's own preamble already defers to
as *"the single canonical source"*, and that generated table. Appending an authored catalogue beside a
generated one, in one file, with nothing checking their agreement, is the arrangement this repo's own
gate exists because it rots. It also keeps the gate arm meaningful: `inventory-counts.test.sh` asserts
a row per skill, and pointed at README it would be asserting against a table a script writes — a green
that could never redden for the reason the arm exists, which is an author adding a skill and forgetting
the row. It now reads `docs/command-reference.md`.

**What is NOT claimed: that this bought headroom for good.** The file is 127,322 characters after the
cut (`python3 -c "print(len(open('CLAUDE.md',encoding='utf-8').read()))"`), about 85% of the limit.
Four of the remaining blocks are byte-shared with `tadeumendonca-io` and may not be split unilaterally,
so the next time this file grows past the edge the cut will have to come out of something that binds.

## The orchestrator, and the two rules above every persona's checklist

**This section is what the cut above left behind, and it is left behind on the test rather than on
where it happened to sit.** Every paragraph here addresses the main session: what it must do, which two
of its acts a layer refuses, and which of its habits nothing is watching. It lived inside *Command
reference* only because the roster narrative wandered into it.

**The eight personas it dispatches**, since *"dispatches every persona"* below names a set
(`ls agents/*.md | wc -l` -> 8): `product-lead`, `tech-lead`, `agents-lead` and `scrum-master` above
the build · `developer`, `content-writer` and `content-reviewer` building · `quality-assurance`
gating. **Why each exists and what each holds is NOT here** — it is
[`docs/command-reference.md`](./docs/command-reference.md), and canonically
[`README.md`](./README.md#the-roster-and-what-each-tier-holds). The roll-call stays because it is the
operand of a duty stated below, not because the roster is orchestrator-binding.

**The orchestrator is the main session itself — one name, not a sixth persona** (ADR-0002). It is not
dispatchable: no `Task` invocation ever targets it, and it satisfies none of the four reasons a persona
exists (amendment #10 above). Its **duties**: dispatches every persona (no persona talks to another
directly); commits and pushes on the loop's behalf; applies the `ready` label once the two intake leads
have closed an Issue's description; applies the ADR-0002 routing label (`product`/`content`/`loop`); and
decides, in the moment, whether a given review specialist needs dispatching at all — a real judgment
call, not a formality.

Its **boundary is stated in two honest parts, not one.** Mechanically enforced, for ~~exactly two
acts~~ ~~three~~ **exactly two acts again since #375**: merge and direct push to the trunk —
`hooks/scripts/permission-guard.sh` leaves the orchestrator's `agent_type` empty by design, and rules 7
(trunk push) and 7b (merge) fire against that empty value.

~~**and, since #319, editing a file inside a git working tree**
(`hooks/scripts/orchestrator-write-guard.sh`, a second `PreToolUse` hook on the
`Edit|Write|MultiEdit|NotebookEdit` matcher, keyed on the same empty `agent_type`). The third is a
**routing** rule, not a floor one: the identical edit goes through the moment the persona that owns it
makes it, and the session scratchpad stays open because it holds no repository.~~ **STRUCK 2026-08-31
(#375) — the hook is DELETED, and this is the sentence that told every reader the routing was
mechanical**, which is why it is struck in place rather than edited away. The owner's diagnosis:
*«entendi que foi uma contingencia entao, nao era intencional. entao esse hook nao deveria existir.»*
**Nothing now prevents the main session from editing a repository file.** What replaces the lock is
`scrum-master`'s selection record naming who should act before acting — **detection, not prevention**,
and self-attested at that, since the orchestrator lands the record itself and nothing reads it.

Its ~~pair~~ former pair, `hooks/scripts/orchestrator-tool-census.sh` (`Stop`), reports the rest —
write/post class separated from reads — and **gates nothing**; reads and the `gh …comment` routes rule
5e allows are deliberately left as a habit, not mechanised (ADR-0004's 2026-08-23 amendment). Since the
guard's removal it is not half of a pair at all: it is the whole of the mechanical half, and it fires
after the act.
**Not enforced, and not claimed to be:** label application — `gh issue edit`/`gh label` sit in the global
allow, unscoped to who calls them — and the dispatch-omission judgment call, which is a different failure
shape than "decides the irreversible": an omission nobody can see happened or didn't, not a decision on
an irreversible act. See ADR-0002 for the full record.

Two rules the owner set for the loop, above every persona's own checklist: **it is a machine for grinding work down, not for generating it** (twenty-two findings on a documentation PR is one slice converted into fifteen), and **nothing ships half-done** — close what can be closed, and say plainly what could not.

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

<!-- hitl-escalation-format -->
## The HITL escalation format — five rules, and they bind THIS context (tedeuxx/tadeumendonca-skills#409)

**These rules address the ORCHESTRATOR — the main session — and this file is their carrier.** The
orchestrator is not a persona, is dispatched by nobody and preloads nothing, so it is the one actor in
this loop that no brief reaches. Measured with one nonce per candidate surface, read back by a headless
main session on build `2.1.263`: a repo-root `CLAUDE.md` reaches this context, a **skill body does not**
(only its name and its `description` do), and neither does `AGENTS.md`. So the rules are written here,
in the imperative, rather than in the skill library — **a rule preloaded by every profile and binding on
none of them is the shape this repository already fails at.**

**Scope: an escalation rising out of a running loop.** Not every question anyone has for the owner — a
design conversation, an interview, an ad-hoc request typed at the terminal is none of them an
escalation, whatever its subject. What makes something qualify is the escalation standard's five
clauses; what follows is the FORM, once it does.

### The five rules

1. **One decision per activation.** Two, however short, is a decision list — he has to rebuild context
   twice. Ask the first; carry the second to its own activation.
2. **The activation is a tweet. The context lives in the OPTIONS.** Terse is not context-free: each
   option states its own consequence, and that is the whole preamble. The reasoning belongs in an
   artifact he can open, never in the interruption.
3. **A picker, never prose numbering. At most four options** — a ceiling, not a target. **Bounded:**
   `AskUserQuestion` is absent from a headless session (`claude -p`), where the model degrades silently
   to exactly the prose numbering this rule forbids. Every escalation path today is interactive, so the
   rule is obeyable today; a headless path added later would break it and nothing would say so.
4. **A merge is an order plus a link, not a question.** The test: *is there a second option you would
   actually defend?* If not it is an instruction — one line, the act and the object, no options and no
   recommendation. The tell in a bad one is that every option is the same act at a different time.
5. **An interview question takes NO options; an escalation always does.** Opposite rules, different
   acts: an interview elicits what he thinks, and a menu puts words in his mouth; an activation asks him
   to take a decision the loop has already reduced, and the options are what make it fast.

### Rule 4 was BUILT as a hook and DELETED — do not build it again

It shipped as `hooks/scripts/action-pendency-guard.sh` in `tedeuxx/tadeumendonca-skills` and was deleted
at `bce25676` on the owner's ruling. Three successive narrowings were each found refusing a genuine
decision, ending with all four of this loop's own merge-gate holds and with `Merge it / Request changes`
— the class its verb set excluded `approve` in order to protect. It classified by **label spelling**
rather than by **choice shape**, so the narrowings were a search over spellings and not a convergence.

**The transferable half: a preventive control whose false positives are unobservable by the person it
protects is worse than no control, however good its true positives.** A `PreToolUse` denial lands before
he sees anything, so a suppressed decision reaches him as prose that reads like a decision already taken
— the defect the control existed to prevent, produced by the control, where nobody can see it. **Rule 4
is held by review, and landing it as text is precisely what survived that deletion.**

### Rule 4 does not contradict the two PR-link hooks — it governs a case they do not reach

`hooks/scripts/premature-pr-link-detect.sh` and `hooks/scripts/owed-pr-link-detect.sh`, both in
`tedeuxx/tadeumendonca-skills`, answer **may** a link go at all: the PR is open, every check concluded
successfully, and the gate's verdict at that head is one of the two terminal literals. Rule 4 answers
**in what form**, once it may. A link failing their predicate never reaches rule 4; a link passing it is
still free to arrive as a four-option picker, which rule 4 forbids and neither hook observes.
`premature-pr-link-detect.sh`'s own header already names rule 4's test as a limb it cannot implement —
*"'Is this ask a decision he holds' is not knowable at any layer, and making it guessable would be
theatre."* **So rule 4 supplies vocabulary for a hole that hook already admits, rather than a second
opinion about a question it already answers.**

### This block is rule 5's CANONICAL statement

Rule 5 already existed, operatively, in two files of `tedeuxx/tadeumendonca-skills` —
`commands/new-issue.md`'s interview constraint and `commands/sprint-planning.md`'s
interview-versus-activation split, the second the fuller of the two. **Both now cite this block rather
than state the rule independently**, because a third independent statement with no canonical home is the
drift this repository has already paid for once. **There is deliberately no string-identity gate arm:**
with one copy of the sentence there is nothing for two copies to disagree about. The cost is the mirror
of that — nothing mechanical stops a fourth restatement appearing, and only review will catch it.

### What enforces this — PER RULE, and the answers differ

**Do not flatten these into *nothing enforces this*.** That sentence is false, and false in the
permissive direction: it reads as *do not try*, and one of the five is cheaply detectable.

- **Rule 1 is a COUNT, and detection is possible.** An activation is an `AskUserQuestion` tool-use block
  written to the transcript in full, so `questions | length != 1` is a predicate rather than a judgement
  about what an option *means* — precisely the property the deleted guard lacked. **The detector is NOT
  built and is a separate slice**, with its own predicate, test file and calibration. That is a forward
  reference and not a promise with a date: it is possible, and today it does not exist.
- **Rule 3's option ceiling has never been violated, and rule 2's mechanical half is clean too** — no
  question has ever carried more than four options, and no option has ever carried an empty description.
  A gate on either would be a green that has never been red.
- **Rule 2's live half — the preamble — is HYPOTHESIS-GRADE and no threshold may be built on it.** The
  characters preceding an activation can be counted, but no layer separates an escalation's preamble
  from ordinary work narration, so the number is not a predicate.
- **Rules 2, 4 and 5 are held by REVIEW.** That is their ceiling, and saying so is the point.

**The three figures above, with the command that produced them** — measured 2026-09-07 over this
machine's own transcripts, a corpus that grows, so read them as a snapshot rather than as a constant:

```
jq -rs '[.[]|select(.type=="assistant")|.message.content[]?
        |select(.type=="tool_use" and .name=="AskUserQuestion")|.input.questions]
        |"activations=\(length) multi_question=\(map(select(length!=1))|length)"' \
   ~/.claude/projects/<project-dirs>/*.jsonl
# activations=199 multi_question=16      -> rule 1: an 8% live base rate
# swap the trailing filter for `.[]?|.options` and count `select(length>4)` -> 0 of 225 questions
#                                        and count options with an empty `.description`   -> 0 of 633
```

**Both zeroes were calibrated rather than trusted:** loosening the ceiling from `length>4` to `length>3`
returns **25**, and counting options whose description is *non*-empty returns **633 of 633** — so each
selector can produce a non-zero answer and the zero is a real zero rather than a dead pattern.

### The two copies of this block must stay identical

**It is shared, byte for byte, between `CLAUDE.md` at the root of `tedeuxx/tadeumendonca-skills` and
`CLAUDE.md` at the root of `tedeuxx/tadeumendonca-io`** — the escalation precondition is a running loop,
a loop is two milestone objects in two repositories, and a session rooted in one repository does not
load the other's `CLAUDE.md`. A rule landed in one is half a rule. From a workspace holding both
checkouts:

```
diff <(sed -n '/^<!-- hitl-escalation-format -->$/,/^<!-- \/hitl-escalation-format -->$/p' tadeumendonca-skills/CLAUDE.md) \
     <(sed -n '/^<!-- hitl-escalation-format -->$/,/^<!-- \/hitl-escalation-format -->$/p' tadeumendonca-io/CLAUDE.md)
```

**That is an OBLIGATION and not a claim about either copy's current state — nothing checks it, and
nothing makes the two move together.** Pipelines are independent per repository, so a change to these
rules is a two-repository batch, and the command above is expected to print a difference in the window
between the two merges.
<!-- /hitl-escalation-format -->

---

<!-- review-chain-routing -->
## The review chain is routed by TYPE — one table, and it binds THIS context (tedeuxx/tadeumendonca-skills#393)

**Like the block above, these rules address the ORCHESTRATOR — the main session — and this file is
their carrier.** The orchestrator is not a persona, is dispatched by nobody and preloads nothing, so a
brief cannot reach it and neither can a skill body. **Every persona that loads the states table is a
dispatchee, and a dispatchee cannot select its own dispatch.** That is why the operative wording is
here and the `agents-configuration` states table carries a pointer instead.

**Re-measured 2026-09-08 on build `2.1.263` rather than inherited from #409** — three headless probes,
every tool disallowed, each asking only whether a heading unique to one repository's root brief was in
the loaded context:

```
cat <prompt-file> | claude -p --disallowed-tools Read Grep Glob Bash Task Edit Write
# rooted in -skills                            -> SKILLS=YES  IO=NO
# rooted in -skills, --add-dir <the -io path>  -> SKILLS=YES  IO=NO
# rooted in -io                                -> SKILLS=NO   IO=YES
```

**The middle row is the one that is not obvious, and it is why this block lives in two repositories
rather than one:** an additional working directory does **not** bring its `CLAUDE.md` with it. A
session can read, edit and commit in a sibling checkout while loading none of that repository's root
brief. A rule landed in one repository is half a rule.

### The table

| type | which lenses run on the review |
|---|---|
| **`loop`** | **one lens pass — `agents-lead` — plus `quality-assurance`.** No copy lens, no `tech-lead` |
| **`product`** | **the full chain** — the leads' lenses as the slice warrants, plus `quality-assurance` |
| **`content`** | **the content pair** — `content-writer` drafts, `content-reviewer` repairs in place, at most two rounds — plus `quality-assurance` |

**`quality-assurance` appears in every row and is not a variable.** It runs on every merge request
under both its lenses, whatever the type. **Nothing in this table narrows a gate, removes a hold or
changes a verdict literal.** In particular the `loop` row does not relax hold 2 — a harness diff still
needs an `agents-lead` verdict marker **on the PR** before the gate may merge it — it says that the
marker plus the gate is the *whole* chain rather than the first half of a longer one.

**It is a routing default, not a lock.** `CLAUDE.md` already leaves the orchestrator the judgment of
whether a given review specialist needs dispatching **at all** on a particular diff; this table
answers *which lenses are eligible for this type*, and that judgment still runs inside the row.
**Adding a lens that the row does not name is the deviation this table exists to make visible** —
so if a `loop` diff genuinely needs a second opinion, say why in the dispatch rather than letting the
default drift back to the full ceremony.

### It is NOT an alternative to the terminal instruction — the two answer different questions

`agents/agents-lead.md` and `agents/product-lead.md` carry a terminal condition: **a lens now knows how
to stop.** This table decides **which lenses run at all.** They compose — one bounds the length of a
pass, the other bounds how many passes there are — and a reader who meets the table without this
sentence will read the two as competing remedies for the same nineteen rounds and pick one.

### What this buys is DURABILITY, not behaviour — and the measurement says so plainly

**Across the nine merge requests measured on 2026-09-07, ZERO copy-lens verdicts ran.** The chain that
actually executed was `agents-lead` marker → gate, which is exactly what the `loop` row above
prescribes — **with nothing anywhere routing it.**

**So this table changes nothing about today.** It makes the current practice survive the orchestrator
forgetting it, and that is the whole of the claim. **Do not read it as fixing a live misrouting; there
is none to fix.** What it removes is the dependency on a fresh context happening to know the rule,
which is the dependency that failed five times.

### And it is text — the Issue's own admission, carried rather than buried

**A correct rule saying the same thing already existed and was overridden five times running.** It
lived in the orchestrator's memory and in a retrospective; no artifact the loop reads carried it.
**`CLAUDE.md` is the carrier because it is the surface the measurement above shows actually reaches
this context — not because text became enforcement.** By this loop's own test — *would something stop
me, or only my memory?* — **this is an instruction**, and it is the right kind, because the failure it
prevents is delay rather than escape.

### The `content` row does NOT touch criterion 10, and must never be read as narrowing it

Criterion 10 fires on a reader-facing diff regardless of type, and it is deliberately phrased to fail
closed. **It did not fire on the `loop` diffs measured because the gate reasoned about it explicitly
and ruled correctly, not because the trigger is loose** — `-io#616`'s verdict states the reasoning on
the record. **A routing label that could override a fail-closed copy trigger would be a loosening
disguised as a routing change.** This table names which lenses are dispatched; it says nothing about
which criteria the gate applies, and the gate's criteria are untouched by it.

### No round counter, and no gate arm — both refusals are deliberate

**No rule here is keyed on a round number.** *After N rounds, lower the bar* decays with the count and
hands a gate a reason to wave through the thing it exists to catch.

**And nothing gates this table.** A string-drift arm asserting the block exists and carries its three
rows is buildable and is deliberately not built here — but note what even that would and would not
buy: **nothing can observe which chain a dispatch actually ran.** No artifact records a dispatch, and
the one lens whose participation would be visible posts nothing at all — `permission-guard.sh` rule 5e
denies `product-lead` the comment subcommands, so its findings reach a PR only quoted inside the
gate's own marker. **A green here could only ever mean the rule is written down.** That is the same
limit the `filed → description closed` rows already carry in their own words.

### The two copies of this block must stay identical

**It is shared, byte for byte, between `CLAUDE.md` at the root of `tedeuxx/tadeumendonca-skills` and
`CLAUDE.md` at the root of `tedeuxx/tadeumendonca-io`**, for the reason the probe above measured: a
session rooted in one repository loads neither the other's root brief nor the sibling's, even with the
sibling added as a working directory. And **the routing types are not repository-scoped** — `-io`
carries `loop` Issues too (`gh issue list --repo tedeuxx/tadeumendonca-io --state all --label loop
--limit 200 --json number --jq 'length'` → **3** on 2026-09-08), so no row here is dead in either
tree. From a workspace holding both checkouts:

```
diff <(sed -n '/^<!-- review-chain-routing -->$/,/^<!-- \/review-chain-routing -->$/p' tadeumendonca-skills/CLAUDE.md) \
     <(sed -n '/^<!-- review-chain-routing -->$/,/^<!-- \/review-chain-routing -->$/p' tadeumendonca-io/CLAUDE.md)
```

**That is an OBLIGATION and not a claim about either copy's current state — nothing checks it, and
nothing makes the two move together.** Pipelines are independent per repository, so a change to these
rules is a two-repository batch, and the command above is expected to print a difference in the window
between the two merges.
<!-- /review-chain-routing -->

---

<!-- loop-mode-contract -->
## The loop MODE is a NAMED agile method — and this is the contract's UNTOUCHABLE list (tedeuxx/tadeumendonca-skills#406)

**Third block in a row addressing the ORCHESTRATOR, and it is here for the same reason as the other
two.** A mode is not something a persona applies — it selects a pool predicate and a ceremony set
**before** any dispatch happens, so the only context that can run one is the main session, which is
dispatched by nobody and preloads nothing. **A skill body cannot carry a mode rule**: the block above
measured, on build `2.1.263`, that a repo-root `CLAUDE.md` reaches this context and that adding a
sibling checkout as a working directory does not bring its brief; #409 measured, with one nonce per
candidate surface, that a skill body does not reach it at all — only the skill's name and its
`description` do. **Neither measurement was re-run for this block**, and both are cited rather than
re-derived; the falsifier is in each block's own text.

### What a mode IS, and what it may contain

**A mode names a widely-known agile method and fixes exactly two things: what the CONTAINER MEANS, and
the CEREMONY SET that runs at its edges.** The owner's decision is that the configuration surface is an
enum of industry names rather than an invented vocabulary — *«faria mto sentido a configuracao de loop
remeter a modos de trabalho agil conhecidos amplamente»* — so a third mode later is a new member of a
documented set, not a new design.

**The container is NOT replaced by the lighter mode. It is DEMOTED** — owner ruling, 2026-09-09,
unprompted: *«nao tem problema numero da iteracao ser utilizado nos dois modos»*. The milestone does
two jobs and the ruling keeps one and drops the other:

- **as an IDENTIFIER it is kept in BOTH modes** — it names a period, groups the work, and gives the two
  repositories one string to pair on. Dropping it would have cost the loop its only cross-repo grouping
  for no gain;
- **as a BATCH BOUNDARY it is what `kanban` drops** — in `scrum` it is a scope commitment whose
  exhaustion is the terminal condition; in `kanban` it is a period label and **nothing depends on its
  emptiness**.

**So the `iteration` axis is *commitment versus label*, never *present versus absent*.** That is
sharper than #406's body proposed and it makes the enum smaller.

| mode | the container | ceremony set | ordering |
|---|---|---|---|
| **`scrum`** | a **commitment** — the milestone bounds a batch, and its exhaustion is the terminal condition | planning · review · retrospective | ranked at planning |
| **`kanban`** | a **label** — the same milestone names a period and bounds nothing | **none run at a boundary** — see the clock rule below | **FIFO within a partition**: `loop` in arrival order, then `product` in arrival order |

**Two mechanical consequences, and the second is where this leaks if nobody writes it down.**

1. ~~**The pool predicate needs no per-mode branch for the milestone.** Both modes carry it, so
   *enumerate-then-select* and the rule that no milestone name is ever typed into a query stand
   unmodified in both.~~ **STRUCK 2026-09-09 (#406 slice B) — it contradicts the table three rows
   above, and the table is the half that is right.** That row says `kanban`'s container **"bounds
   nothing"**; a limb of the pool predicate bounds the pool, which is the only thing a container could
   bound here. The owner's words settle it and were available the whole time: *«nao ter os ritos do
   agil e **enforcement de iteracao no github issues** quando trabalhando em modo kanban»* — **a
   predicate limb IS that enforcement.** Ruling 3 makes the iteration NUMBER usable in both modes; it
   does not make the milestone a filter in both. Struck rather than edited because it merged, was
   published to the marketplace, and is the sentence slice B would have built the wrong predicate
   from. **The defect originates in the ruling-3 intake comment on #406, not in slice A's authoring** —
   slice A carried it forward accurately.

   **The correct rule, and both predicates are published in full in `docs/loop-mode.md` rather than as
   an edit to one another:** in **`scrum`** the milestone is a limb and the active-iteration derivation
   selects it, so *enumerate-then-select* and the never-type-a-milestone-name rule stand unmodified
   **there**; in **`kanban`** the milestone is not consulted, so those two rules have **no subject**
   rather than standing unmodified. **The `ready` limb does not vary in either direction** (ruling 2).

   **This is what makes the mode operative rather than declarative, and it is measurable at head:** one
   tracker state, read under the two predicates, returns an empty pool under `scrum` and a four-item
   pool under `kanban` — because zero open items in either repository carry a milestone. **A mode
   nobody had recorded was already selecting which of those two answers the loop got.**
2. **Whatever later builds the cadence trigger must key on THE CLOCK and never on the pool being
   empty.** In `scrum` an empty active milestone is the terminal condition; in `kanban` it means
   nothing at all, and a rite firing on it would be firing on noise. **A trigger keyed on emptiness
   makes `kanban` silently inherit `scrum`'s trigger under a different name** — the exact failure this
   contract exists to make visible.

**Unchanged by the ruling:** nothing enters a running iteration automatically, and composing one is
the owner's act, in both modes. A period label is still placed by him.

~~**`kanban` is SPECIFIED here and is not operative.** The pool predicate, the drain and the two gate
arms that pin the Scrum wording are slice B of #406 and have not landed. **Do not read this table as a
switch that has been thrown**; read it as the contract a switch would have to honour.~~ **Struck
2026-09-09 — slice B landed and `kanban` IS operative**, which is what that paragraph promised would
change. Struck rather than deleted because it stood in a marketplace-published version and a reader who
took *"not operative"* from it would not look for a record that now exists.

**The mode of record is `docs/loop-mode.md`** — a tracked file carrying the value, the enum, the
back-dated start and both per-mode pool predicates in full. **It is READ before any pool query and never
inferred from one**, and the only thing that reads it is `commands/autonomy.md`, which is a rule a
session executes rather than a mechanism. **Nothing mechanical reads it, deliberately** — see the
untouchable-list measurement below, which the moment a hook is taught the mode stops being true.

**What slice B did NOT do**, so the table is not read as more than it is: it built ~~**no cadence
trigger** (slice C, authorised and not yet built)~~ **no cadence trigger — slice C built it on
2026-09-09 (`hooks/scripts/cadence-notice.sh`, `docs/loop-cadence.md`), and the strike is here rather
than a deletion because this sentence is what told a reader the carrier did not exist**, **no gate arm**
asserting the record exists or parses, and it decided **no `wip` value** (`#385`). And the two gate arms
that pin the Scrum wording did not move, because the Scrum wording did not move — the additions are
additive and the drift check is blind to all of it.

**What slice C did NOT do either, said in the same breath so the carrier is not over-read.** It decided
**no interval** — that was never asked and is not inferred, so its record ships with the value
undeclared and the carrier refuses to conclude rather than defaulting. It **added no gate arm** and is
**not a gate**: it reports elapsed time and every exit path is success. And it **does not read this
contract, the mode record, a container, a label or the queue** — which is what keeps the untouchable
list's measurement below a measurement.

**And the honest starting state, because it is the argument for writing the contract down rather than
a hypothetical about the future: the loop is already running with no container and no ceremony, and
nothing anywhere records that.** Measured 2026-09-09, both repositories:

```
gh issue list --repo <owner>/<repo> --state open --limit 300 --json number,labels,milestone \
  --jq '[.[]|{l:[.labels[].name],m:.milestone}] | {open:length,
        ready:[.[]|select(.l|index("ready"))]|length,
        milestoned:[.[]|select(.m!=null)]|length,
        sp:[.[]|select(.l|map(startswith("sp:"))|any)]|length}'
# -skills -> {"open":8,"ready":1,"milestoned":0,"sp":0}
# -io     -> {"open":45,"ready":16,"milestoned":0,"sp":0}
```

**Both zeroes are calibrated rather than trusted** — the same two selectors over `--state all` in
`-skills` return **17** milestoned and **12** carrying `sp:N`, so neither is a dead pattern. **A mode
record must therefore be dated and back-dated honestly when one is introduced**, never written as
though the day it lands is the first day of the mode it names.

**`ready` in `-skills` read `0` earlier in this same slice and reads `1` now**, because the owner
closed #406's description while it was being built. **That is the figure demonstrating its own rule:
re-derive a number when the text around it changes, rather than restating the one you already had.**
And the `1` carries no `sp:` label, which by the bar below is an unmet readiness item — a fact about
the queue, not about this block, and not repaired here.

### The UNTOUCHABLE list — and it is a MEASUREMENT, not an intention

| a mode MAY vary | a mode may NEVER touch |
|---|---|
| what the container MEANS — a batch commitment, or a period label | **the permission floor** — every rule of `hooks/scripts/permission-guard.sh`, under both loop models |
| whether the three rites run, and what fires them | **the merge gate** and both of its lenses, on every diff |
| the ordering act — ranked at planning, or FIFO within the `loop`/`product` partition | **head-scoped verdicts** — a verdict names the commit it read, in every mode |
| `wip` (the slot only — see below) | **only-the-owner-opens-work** (`permission-guard.sh` rules 5c/5d) |
| — | **the READINESS BAR** — `sp:N` stays in both modes (2026-09-09) |
| — | the `product`/`content`/`loop` routing labels · **`content` has no second mode** · **the container's EXISTENCE**, as against its meaning |

**Two rows moved right on 2026-09-09, and a mode config that loses axes is the design working rather
than shrinking.**

- **The readiness bar does NOT vary by mode.** Owner ruling: *«Mantém o `sp:N` nos dois modos»*.
  ~~The estimate is kept as a **size signal**, not as a velocity input — which is what it already was here,
  since `/planning-poker` sits in the library as a reference pattern and no velocity is collected in
  either mode.~~ **Struck 2026-09-23 (#499): prospective team velocity is now selected.** The estimate
  remains the readiness signal and planning input it was, and its value is frozen by the first explicit
  worklog implementation-start event rather than reread from a mutable label. `/definition-of-ready`
  still needs no per-mode branch: `ready` asserts the same thing
  in both, and there is one fewer place for the two modes to drift apart. ~~**The cost, recorded rather
  than absorbed:** the lighter mode carries a ceremony its own method does not ask for, and the loop
  pays two estimator dispatches per item in a mode that collects no velocity. He was told that and
  took it.~~ **Struck with #499:** the two estimator dispatches remain, but prospective velocity now
  consumes their median in both modes; there is no longer a mode that collects no velocity.
- **The container's EXISTENCE is untouchable; only its MEANING varies.** Ruling 3 above. A mode that
  could delete the milestone would take the only string the two repositories pair on with it.

**The one sentence to keep verbatim, because it is the failure this whole surface can produce:** *a
mode selects a predicate and a ceremony set; it never selects a permission rule.* **A configuration
surface that can reach the irreversible floor is a hole with a nice name.**

**Today that separation is structural rather than merely intended, and this is the command that says
so.** Across all **15** registrations in `hooks/hooks.json` — resolving to **14** distinct script
files, because `preflight.sh` is registered twice — every occurrence of the mode vocabulary is a
comment or a deny-message string, and **no registered hook selects a `milestone` or a `labels` field
or passes a `--milestone`/`--label` flag**:

~~Across all **fourteen** hook registrations~~ — **struck 2026-09-14 (#463), and the strike is worth
more than the digit.** It was **true when it landed** (14 registrations of 13 scripts) and went false
on 2026-09-11, when `worktree-notice.sh` was registered and the pair moved to 15 of 14. **It went
false INTO a coincidence, which is what made it survive a green suite and two reviews:** *fourteen* is
now exactly the count of distinct **scripts** — the object the commands below actually iterate, since
each ends in `sort -u` — so the stale sentence reads as a correct claim about the wrong noun, and a
reader who checks it against the pipeline beneath it is told it holds. **Both nouns are stated from
here on, and each is derived separately rather than as one figure:**

```
jq '[.hooks|to_entries[]|.value[]|.hooks[]]|length' hooks/hooks.json                  # -> 15 registrations
jq -r '.hooks|to_entries[]|.value[]|.hooks[]|.command' hooks/hooks.json \
  | sed 's|.*/hooks/scripts/|hooks/scripts/|; s|"$||' | sort -u | wc -l               # -> 14 scripts
jq -r '.hooks|to_entries[]|.value[]|.hooks[]|.command' hooks/hooks.json \
  | sed 's|.*/hooks/scripts/|hooks/scripts/|; s|"$||' | sort | uniq -d                # -> preflight.sh
```

**The third command is the calibration and it is not decoration:** the first two agreeing at some
future head would prove nothing on its own — a duplicate is exactly what makes them differ, so the
selector that NAMES the duplicate is what shows the 15-versus-14 gap is real rather than arithmetic.

**AND NONE OF THESE COMMANDS RUNS IN `tadeumendonca-io` — which this block has never said, while the
sibling's own mode record has had to say it since 2026-09-09.** The block is byte-identical across the
two repositories and every selector in this section is **repo-relative**, but `-io` carries no `hooks/`
directory at all: `ls hooks/` there returns *"No such file or directory"*, and each **pipeline** above
produces **no stdout and exit 1**. Say *pipeline*, not `jq`: the `jq` itself exits **2**, with
*"Could not open file hooks/hooks.json"* on stderr — but a pipeline's status is its last stage's, and
what a reader sees is exit 1 and an empty result. In that copy the commands are
indistinguishable, on stdout and on exit code, from commands that ran and found nothing — which is this
platform's own named worst shape, a falsifier that fails open. `tedeuxx/tadeumendonca-io`'s
`docs/loop-mode.md` records exactly that, in its own words: *"here it means nothing was scanned."*
**That note is `-io`-only, so a reader of the `-skills` copy of this block had nowhere to learn it**,
which is why the fact is stated here rather than left to one repository.

**Every figure in this section is a fact about the `-skills` tree, quoted verbatim in the sibling.**
Measured 2026-09-14; **not repaired here**, because the repair is either a per-repository divergence
inside a block whose only instrument is `diff`, or a sentence in `-io` saying its own falsifiers are
inert. That is its own decision and it is the owner's.

```
jq -r '.hooks|to_entries[]|.value[]|.hooks[]|.command' hooks/hooks.json \
  | sed 's|.*/hooks/scripts/|hooks/scripts/|; s|"$||' | sort -u \
  | xargs grep -nE -- '--milestone|--label|--json [^|"]*(milestone|labels)' \
  | grep -vE ':[0-9]+:[[:space:]]*#'
# -> no output

jq -r '.hooks|to_entries[]|.value[]|.hooks[]|.command' hooks/hooks.json \
  | sed 's|.*/hooks/scripts/|hooks/scripts/|; s|"$||' | sort -u \
  | xargs grep -nE 'milestone|iteration|sprint' \
  | grep -vE ':[0-9]+:[[:space:]]*#' | grep -vE 'deny "'
# -> no output

# the denominator, so "no output" is read against a non-empty set rather than against nothing:
jq -r '.hooks|to_entries[]|.value[]|.hooks[]|.command' hooks/hooks.json \
  | sed 's|.*/hooks/scripts/|hooks/scripts/|; s|"$||' | sort -u \
  | xargs grep -hcE 'milestone|iteration|sprint' | paste -sd+ - | bc
# -> 28        (26 comments + the 2 deny strings the filter above excluded)
```

~~`# -> 25        (23 comments + the 2 deny strings the filter above excluded)`~~ — **struck
2026-09-14 (#463), and the delta is fully accounted rather than merely re-measured:** `permission-guard.sh`
gained one comment line (15 → 16) and the newly-registered `worktree-notice.sh` brought two. **Both
zeroes above are unchanged, re-derived at this head** — which is the only thing the denominator exists
to make readable, and it is why the figure moving is not a finding while the zeroes moving would be.

~~`# -> 22        (20 comments + the 2 deny strings the filter above excluded)`~~ — **struck 2026-09-09
(#406 slice C), and the STRIKE is worth more than the new figure.** The denominator moved because the
cadence carrier's header names the rite artifact roots in three comment lines. **Nothing about the
property changed** — both zeroes above are unchanged, re-derived at that slice's head — but a reader who
saw only the number move would have to work out which. **So the standing warning is this: the second
command is a VOCABULARY grep, and vocabulary is a PROXY for the property rather than the property.** A
hook that names a rite in a *code* line would turn it red without reading any object a mode varies, and
a hook that read the queue through an interpolated path would leave it green. **The first command —
selecting `--milestone`/`--label`/`--json …` field names — targets the property directly and is the one
to trust when the two disagree.**

**Both zeroes are calibrated, in the direction that matters — a selector that cannot go non-zero is
not a check.** The two calibrations are written out in full below rather than described as edits to
the commands above, because *"swap X for Y"* is ambiguous and this parenthetical published a wrong
number twice while saying so:

```
# calibration A — the same selector against field names that ARE live code:
jq -r '.hooks|to_entries[]|.value[]|.hooks[]|.command' hooks/hooks.json \
  | sed 's|.*/hooks/scripts/|hooks/scripts/|; s|"$||' | sort -u \
  | xargs grep -nE -- '--milestone|--label|--json [^|"]*(headRefOid|comments)' \
  | grep -vE ':[0-9]+:[[:space:]]*#'
# -> 10 lines, across 6 files
#
#    THE FILE COUNT IS A PROPERTY OF THE FILTERED RUN, and re-deriving it without the filter gives 7.
#    Both figures published in full, because a described mutation of a command is not a command:
#      as written above, ending in `grep -vE ':[0-9]+:[[:space:]]*#'`   -> 10 lines, 6 files
#      the same selector with that final `grep -vE` removed              -> 14 lines, 7 files
#    The 7th file is `cadence-notice.sh`, whose single match is a comment quoting this very selector —
#    exactly what the filter exists to remove. So a reader who reaches for `grep -l` (which lists a
#    file on ANY match, comments included) gets 7 and concludes the 6 is stale. It is not, at either
#    head this figure has been checked against. Re-derive with the pipeline as printed, filter and all.

# calibration B — the second command with its `deny "` filter removed:
jq -r '.hooks|to_entries[]|.value[]|.hooks[]|.command' hooks/hooks.json \
  | sed 's|.*/hooks/scripts/|hooks/scripts/|; s|"$||' | sort -u \
  | xargs grep -nE 'milestone|iteration|sprint' | grep -vE ':[0-9]+:[[:space:]]*#'
# -> 2 lines, the deny strings the filter was excluding
```

**Why they are spelled out, and it is a finding rather than tidiness.** *"Swap `milestone|labels` for
`headRefOid|comments`"* has two readings — replace only the parenthesised group, or replace the whole
pattern — and they return **different numbers** with the comment filter removed. Both readings return
**10** with the filter in place, which is why the figure above was right while the sentence describing
how to reach it was not. **A described mutation of a published command is not a published command.**

**What these commands do NOT say, stated here so the list does not inherit an overclaim that is
already in circulation.** They do **not** say that no hook reads an Issue. Two registered hooks make
live `gh issue` **reads** — `hooks/scripts/closure-artifact-guard.sh` resolves an Issue body
(`gh issue view --json body,title`) and lists recently-closed Issues by a rolling date window
(`gh issue list --state closed --search "closed:>=…"`). **Neither selects a label or a milestone**, and
a date window is not a queue predicate, so the mode-blindness above survives them intact. **The
sentence that does not survive is the falsifier published beside it elsewhere:** *"every `gh issue`
call in `hooks/scripts/` is a write path"* is **false at head** — the two reads above are the
counter-example — **and its scope is TREE-WIDE rather than one file.** ~~it is repeated in
`skills/agents-configuration/SKILL.md` at four sites~~ ~~at three sites~~ — **struck 2026-09-09 (#406
slice C), twice, and the second strike is the one worth reading.** The first figure was carried; the
second was *derived from a superset* — a line-oriented `grep` for `reads the queue|write path`, which
matches two neighbouring sentences that are TRUE and need no sweep, and which counts **lines** rather
than occurrences, so a site that wraps is counted twice or split in half. **The conclusion the clause
supports still stands and its stated reason does not** — ~~correcting it is still its own slice~~,
**that slice ran on 2026-09-09 (#406 slice D) and is recorded immediately below**; the list above was
written so that it does not depend on it, and still does not.

**THE SWEEP IS DONE (#406 slice D, 2026-09-09), and what it found first was that the instrument
published here was wrong in three ways — each in the permissive direction.** The paragraphs below are
rewritten rather than annotated: a deferral left standing beside a discharged obligation is a reader
stopping at it and waiting.

~~**The instrument, not the digits — the selector below picks the clause itself, and it is
WRAP-INSENSITIVE.**~~ **Struck: wrap-insensitive was one of three properties it needed and the only
one it had.** It collapsed whitespace before matching, because this repository had already paid for a
line-oriented sweep that returned two hits and missed the broken file (#410) — correct, and
insufficient. Re-derived against a hardened selector on the same tree, it **under-counted by four**:

| what it missed | why | cost |
|---|---|---|
| a sentence-initial `Every …` in `docs/adr/0002` | it was **case-sensitive** | 14 found, 15 present |
| three occurrences inside `hooks/scripts/inventory-counts.test.sh` | it was scoped to `'*.md'`, and one of the three wraps across two `#`-prefixed comment lines, so the collapsed body reads `every # ` + backtick + `gh issue` and `\W?` matches **one** character | 15 found, 18 present |

**Two of those three misses are the same lesson at different grains, and the third is the sharper
one.** A sweep's instrument scoped to one file extension is an enumeration claiming to be a rule; and
**the extension it excluded was `.sh`, which is where this repository's own GATE lives** — so three
false claims sat in the comments of the file whose job is catching drift, invisible to the command
published to find them.

**The corrected instrument is published in full rather than as a mutation of the one above**, per the
rule this file already carries: *a described mutation of a published command is not a published
command.* It strips a leading comment marker per line **before** collapsing whitespace, matches
case-insensitively, and reads every tracked file:

```
git ls-files -z | xargs -0 python3 -c '
import re, sys
claim = re.compile(r"every \W{0,3}gh issue\W{0,3} call [^.]*? is a write path", re.I)
for p in sys.argv[1:]:
    try: raw = open(p, encoding="utf-8").read()
    except Exception: continue
    body = re.sub(r"\s+", " ", " ".join(re.sub(r"^\s*#\s?", "", l) for l in raw.split("\n")))
    n = len(claim.findall(body))
    if n: print(str(n) + "\t" + p)
'
```

**`\W{0,3}` stands in for a backtick — optionally preceded by a stripped comment marker's residue —
because a backtick in a command string is refused by this harness's own guard.**

**The scope it returned, and it is bigger than the deferral claimed: 16 assertions across 10 authored
files** (18 occurrences, minus `CLAUDE.md`'s own quotation and the generated `powers/` mirror). The
four the old selector could not see were the `docs/adr/0002` sentence-initial one and the three in
`hooks/scripts/inventory-counts.test.sh`.

**What no selector of this shape CAN distinguish, unchanged and now load-bearing** — the same
citation-versus-discussion blindness `documentation-standard` records about the record-citation gate.
**Every corrected site now QUOTES the clause in order to strike it**, per this repository's
struck-not-deleted convention, so the occurrence count did **not** go to zero and must not be expected
to: it went from 18 asserted to 15 quoted-and-repudiated. **A bare absence check would therefore demand
deleting the very sentences that record the correction**, which is why the gate arm added in this slice
requires a repudiation marker within 120 characters of each occurrence rather than requiring absence.

**What the repair WAS, per site rather than uniform.** Each site used the clause as a falsifier for a
different conclusion, and a single replacement string pasted sixteen times would have turned sixteen
true sentences into sixteen plausible ones. The conclusions all survive; the reason they now give is
the property rather than the proxy — **no registered hook selects a `--label` or a `--milestone`**,
which is the first command in this section and is directly falsifiable, where *"every call is a write
path"* was a proxy for it and was false.

**One conclusion did NOT survive, and it is a finding rather than a failure.**
`commands/sprint-review.md` read *"No hook can be built for it"* — an absolute the cadence carrier
falsified in the same way it falsified the preload's *"no hook can be built for either rite"*. It is
corrected on the same split — **and for THIS rite both halves are negative, which is sharper than the
preload's case and was got wrong once before the gate caught it.** `docs/loop-cadence.md` declares
`/sprint-review`'s artifact root `sibling`, so `hooks/scripts/cadence-notice.sh` names the rite and
reports it *"in the CONSUMING repository. Not observable from this tree"*, returning before it reads any
date: **NOTICING is built for the two rites declared `here` and is declared INERT for this one; FIRING
is not built for any of the three and did not move.** What the strike buys is that a row for this rite
**exists and is handled**, not that it is noticed. The identical absolute one line away in
`docs/adr/0002-roster-and-dev-loop.md` was corrected with it, for the reason slice C already gave about
this exact class: dropping a known-false absolute out of a section being rewritten anyway is cheaper
than leaving it and cheaper than a round about it.

**And the arm is calibrated by planting, not by reading.** `hooks/scripts/inventory-counts.test.sh`
carries a tree-wide arm asserting the clause never appears unrepudiated. It was confirmed red twice by
mutating the **source**: a plain occurrence appended to `README.md`, and a capital-`E` occurrence
wrapped across two shell-comment lines appended to `hooks/scripts/preflight.sh` — the second exercising
all three properties the old selector lacked at once. Both restored, both re-greened. It also carries a
**vacuity guard**, and that guard earned its place immediately: the arm's first form piped `git
ls-files` through `xargs` into `python3 -` with the script as a heredoc, **and `xargs` won the contest
for stdin**, so the script never arrived and the arm matched nothing. A bare-count-of-zero would have
read as *clean*.

**So the property to preserve is deliberate, not inherited.** Slice B adds a mode-dependent predicate;
the moment any hook is made to read it, the floor stops being mode-blind and this table stops being a
measurement. **If a later slice needs a hook to know the mode, that is the review that has to happen
before it is written, not after.**

### `wip` is a SLOT here — the VALUE and the topology are `#385`

**`WIP=1` is transitional scaffolding with a stated exit condition, not a pull-system choice.** The
owner's correction, before #406 was filed: *«hoje o nosso scrum trabalha em wip=1 devido a necessidade
de apurar o modelo antes de paralelizar a camada de developers»* · *«mas nao tem intuito de seguir
assim»*. So **WIP is a parameter of the mode, not a constant of the loop** — and a mode contract that
hard-coded it would bake the scaffolding into the configuration.

**The boundary with `#385`, open since 2026-08-31, and it is stated in both bodies rather than one:**

- **`#406` owns the SLOT** — that `wip` is a declared parameter of a mode. It decides **no value**, no
  topology and nothing about what may run together.
- **`#385` owns the VALUE and the topology** — worktrees, file collision, gate throughput, and what
  parallel work actually costs.

**Reading them against each other is the only instrument that finds this**, and it is
`/definition-of-ready`'s named flagship failure occurring live between two individually well-formed
Issues.

**THE VALUE IS `wip: 2`, decided 2026-09-11 (#385) and recorded in `docs/loop-mode.md`, not here.** The
contract owns the slot; the record owns the value, exactly as it owns `loop-mode:` — a value published
in two places is two sources of truth for one fact. **The basis:** the only instrument that can size
this is `hooks/scripts/dispatch-metrics-stop.sh`, and over the 40 most recent Issues — 23 of which carry
records, 286 records, 198.16 h — the **builder is 2.5% of dispatch time** (`developer` 4.88 h;
`agents-lead` 129.78 h, `quality-assurance` 59.67 h). Ruling 1 keeps the gate serial and the lens is
serial too, so parallelism is applied to that 2.5% while the rest stays serial — **Amdahl's law with a
measured fraction, and `wip: 2` is where it stops paying.** The command is in `docs/loop-mode.md`
beside the figure, with the window-by-window table showing the conclusion does not depend on the
corpus chosen.

~~aggregated over the 33 records on `#406` the **builder is 11% of dispatch time**~~ — **struck
2026-09-11: TRUE of that one Issue and published as though it were the basis.** `#406`'s own figure
reproduces exactly and is kept, scoped to `#406`, in the record. The corpus-wide number is **lower**,
so the correction moves the argument in its own favour — which is the only reason it is safe to make
in the same slice that relies on it.

~~**Bound that figure hard: it is TWO Issues, not a sample.** Re-derived across fourteen recent Issues,
**two** carry dispatch records at all (`#406` with 33, `#437` with 3) and twelve carry none — and
`#437`'s split has **zero** builder dispatches, so it lowers the builder's share rather than raising
it. **Nothing can size `wip` from data until the instrument is written on most work**, and fixing that
is not this slice.~~

**STRUCK 2026-09-11 — FALSE, it shipped without the command that produced it, and its error ran in the
direction that excused this slice's own scope.** The gate falsified it: over the fourteen most recent
**closed** Issues, **nine** carry dispatch records, not two. Re-derived here rather than accepted —
that window reproduces exactly (`#438` 8 · `#437` 3 · `#434` 3 · `#426` 1 · `#423` 1 · `#421` 5 ·
`#419` 3 · `#416` 6 · `#413` 12 = **42 records**). **The instrument is written on most work, and the
sentence claiming otherwise was propping up a convenient conclusion.**

**The corrected basis, with the command that produced it, over the widest corpus that can be
enumerated in one pass:**

```
python3 -c '
import subprocess, json, re, collections
R = "tedeuxx/tadeumendonca-skills"
g = lambda *a: subprocess.check_output(["gh"] + list(a), text=True)
nums = json.loads(g("issue","list","--repo",R,"--state","all","--limit","40",
                    "--json","number","--jq","[.[].number]"))
agg, cnt, carry = collections.Counter(), collections.Counter(), 0
for n in nums:
    bodies = json.loads(g("issue","view",str(n),"--repo",R,"--json","comments","--jq",
        "[.comments[]|select(.body|contains(\"dispatch-metrics:\"))|.body]"))
    if bodies: carry += 1
    for b in bodies:
        for a, d in zip(re.findall(r"agent_type:\s*([^\n]+)", b),
                        re.findall(r"duration_seconds:\s*([0-9.]+)", b)):
            k = a.strip().strip("`"); agg[k] += float(d); cnt[k] += 1
t = sum(agg.values())
print("issues=%d carrying=%d records=%d total=%.2fh" % (len(nums), carry, sum(cnt.values()), t/3600))
for k in sorted(agg, key=lambda x: -agg[x]):
    print("  %-40s n=%-4d %7.2fh %5.1f%%" % (k, cnt[k], agg[k]/3600, 100*agg[k]/t))
'
# issues=40 carrying=23 records=286 total=198.16h
#   agents-lead        n=154  129.78h  65.5%
#   quality-assurance  n=84    59.67h  30.1%
#   developer          n=18     4.88h   2.5%   <- the only share parallel DEVELOPMENT touches
#   product-lead       n=20     2.95h   1.5%
#   tech-lead          n=6      0.82h   0.4%
```

**The builder is 2.5% of dispatch time over that corpus** — not 11.07%, and **lower**, which is why
the conclusion survives its own correction: parallelising the builder pays *less* than the first
delivery claimed, so **`wip: 2` is conservative rather than aggressive.**

**The conclusion does not depend on the window, and that is worth more than any single figure.** Every
corpus that can be constructed here puts the builder at or below the original 11.07%:

| corpus | issues carrying records | records | builder share |
|---|---|---|---|
| `#406` alone | 1 | 33 | **11.07%** |
| 14 most recent **all-state** | 7 | 24 | **0.0%** |
| 14 most recent **closed** (the gate's window) | 9 | 42 | **4.4%** |
| 40 most recent **all-state** | 23 | 286 | **2.5%** |

**One disagreement recorded rather than absorbed.** The gate's finding is correct on the half that
blocks — *"nine of fourteen, not two"* — and I reproduce that exactly. Its **replacement aggregate does
not reproduce**: it published *"across all nine … 89 records, 30.48 h … 9.6%"*, while the nine Issues
it itself lists sum to **42** records and **12.61 h**, giving **4.4%**. I could not construct any
window that returns 89. **The direction is identical and every window agrees with it**, so nothing
downstream changes; the figures above are mine, with the command, and the gate's are cited as its own.

**What is still true, and it is the part the struck sentence buried:** `#406`'s own 11.07% is sound and
is kept **scoped to one Issue**, where it was measured. `loop`-typed Issues run heavy lens work, so the
builder's share is smaller there than on `product` or `content` — which is the one direction that would
argue `wip` **up**, and it is bounded by the 2.5% corpus above, which already mixes the lanes.

**What breaks FIRST at WIP > 1, priced here because it is a contract input — and it is not the gate.**
`permission-guard.sh` rule 7c head-scopes the **gatekeeper's** verdict per PR: it fetches `headRefOid`
and the comment list in one call, and an unreadable head denies. **It is the `agents-lead` verdict
marker**, which every reader treats as presence-only. Measured at head — every occurrence of the
literal outside a test file is a **counter** (`hooks/scripts/dispatch-metrics-stop.sh`), a **comment**
(`hooks/scripts/zombie-loop-detect.sh`, `hooks/scripts/permission-guard.sh`) or the prose of hold 2 in
`agents/quality-assurance.md`:

```
grep -rn 'harness-lead-verdict' hooks/scripts/ agents/ | grep -v '\.test\.'
```

**No rule reads it, and that is still true at head.**

~~**At WIP > 1 two concurrent harness diffs would each satisfy hold 2 with the other's marker.** That
is the check to run **before** relaxing WIP, in either mode; it is a named residual today and
parallelism is what makes it live.~~

**STRUCK 2026-09-11 (#385) — IT IS MECHANICALLY IMPOSSIBLE, and the strike is kept because this
sentence is the one a reader would have taken the whole hazard from.** A marker is a **comment on one
pull request**, and two pull requests share no comment thread, so no marker of PR A is ever visible to
a read scoped to PR B. Re-derived at head:

```
for n in 454 439 436; do gh pr view $n --repo tedeuxx/tadeumendonca-skills --json comments \
  --jq '[.comments[]|select(.body|test("harness-lead-verdict"))]|length'; done
# -> 3, 1, 1      each PR carries its own
# calibration — total comments per PR: 6, 2, 2, so a zero would have been readable
```

**What is real, and the struck sentence was pointing near it, is STALENESS WITHIN ONE PR.** Hold 2 was
satisfied by **presence**, so a marker posted at an early commit cleared it for everything that landed
after. **Measured on the same PR, and it is live rather than hypothetical:**

```
# STRUCK 2026-09-22 — DO NOT RUN THIS FORM. Kept rather than deleted because it merged, was
# published to the marketplace, and a reader who ran it got a clean answer without being told
# which way it was wrong.
gh pr view 454 --repo tedeuxx/tadeumendonca-skills --json headRefOid,comments --jq '
  .headRefOid as $h
  | {markers_total:   [.comments[]|select(.body|test("harness-lead-verdict"))]|length,
     markers_at_head: [.comments[]|select(.body|test("harness-lead-verdict"))
                                 |select(.body|contains($h))]|length}'
# -> {"markers_total":3,"markers_at_head":1}      re-derived 2026-09-22 at head c0ed67d9: unchanged
```

~~`|select(.body|contains($h))`~~ — **the LIMB is struck, and it is wrong in BOTH directions, found
two days apart. The FIGURE above is not wrong**: PR 454 returns 3 and 1 under the struck limb and 3
and 1 under the corrected one. **That agreement is why the defect survived two weeks — the example
published beside the instrument is one where the two forms cannot disagree, so running it proved
nothing.**

- **It can UNDER-count.** `headRefOid` is forty characters and `contains` is an exact substring test,
  so a marker whose `commit:` line carries an ABBREVIATED SHA fails it. The writer's contract in
  `agents/agents-lead.md` asked only for *the SHA of the repo state you reviewed*, which permitted the
  abbreviation — so the writer's contract and the reader's instrument disagreed, and the disagreement
  reads to the gate as a MISSING REVIEWER. **Closed on the WRITER's side** — that brief now requires
  the full forty — and deliberately not by loosening the reader to a prefix test, which would count a
  marker naming an ancestor commit.
- **It can OVER-count, and this half is measured live below.** `contains` matches the SHA ANYWHERE in
  the body, so a marker that MENTIONS an older SHA in its prose — to say that an earlier marker does
  not attest this diff — is counted as attesting it. **The over-count is CAUSED by the marker obeying
  its own instruction to be explicit about which head it does not attest**, which is the whole of why
  it was invisible: the better-behaved the lens, the more the instrument over-reads.

**The RULE was already right and is not what changed.** `agents/quality-assurance.md` hold 2 already
says the marker's **`commit:` line** must name the `headRefOid`. The command published beside it did
not implement that sentence. **This is the instrument being made to match the rule.**

**The corrected form captures the `commit:` line instead of searching the body, and it tolerates
MARKUP between `commit:` and the forty characters:**

```
gh pr view 493 --repo tedeuxx/tadeumendonca-skills --json headRefOid,comments --jq '
  .headRefOid as $h
  | {markers_total:   [.comments[]|select(.body|test("harness-lead-verdict"))]|length,
     markers_at_head: [.comments[]|select(.body|test("harness-lead-verdict"))
                                 |select(.body|test("(^|\n)commit:[^0-9a-f\n]*" + $h))]|length}'
# -> {"markers_total":2,"markers_at_head":1}   measured 2026-09-22, head ee0ca4698b4f3a18…
```

**`[^0-9a-f\n]*` IS THE WHOLE OF THE TOLERANCE, and it is LEXICAL rather than SEMANTIC — which is the
distinction this decision turns on.** It admits the **same forty characters** wrapped in backticks or
bold, and **no other SHA**: any hex character between `commit:` and the SHA stops the class, so an
abbreviated line cannot slide into a longer match, and `\n` in the class stops it running to a SHA on
a later line. Contrast a **prefix** test, which was considered and rejected: that admits a different
commit — an ANCESTOR — which is the exact staleness the hold exists to catch.

**Why the tolerance is on the READER and not left to the writer's discipline.** Measured 2026-09-22
over the 148 markers on the 80 most recent PRs of `tedeuxx/tadeumendonca-skills`:

```
# 130  commit: <40 bare>        pass every form
#   9  commit: <40 in backticks>  passed the struck limb, FAIL a bare-only capture   <- this class
#   9  commit: <abbreviated>      failed the struck limb too; unchanged by any of this
```

**The nine backticked markers are not historical** — they run from PR 417 to PR 484, the most recent
one merged the day before this was written. A bare-only reader converts a spelling nine lenses have
actually used into a **false missing-reviewer**, which the gate reads as hold 2 and answers with
`APPROVE-PENDING-HUMAN` on a diff that WAS reviewed.

**And the layer argument that would have sent this to the writer does not survive contact: NEITHER
side is enforcement here.** No **rule** reads this marker — and *"no hook reads it"* would be FALSE,
which is the whole of the carve-out: `hooks/scripts/zombie-loop-detect.sh` is registered on **`Stop`**
(`hooks/hooks.json`) and its `harness_stale` arm genuinely READS the marker, then **reports** a PR
whose markers are all stale, one turn late, **denying nothing**. So the reader is a command a persona
runs by hand and the writer's contract is a paragraph in a brief. **Both are instructions, both ship
on the same `/plugin update`.** Classify the mentions rather than trusting any tally, this one
included:

```
grep -rn 'harness-lead-verdict' hooks/scripts/ | grep -v '\.test\.' \
  | awk -F: '{l=$0; sub(/^[^:]*:[^:]*:/,"",l); gsub(/^[ \t]*/,"",l);
              print (l ~ /^#/ ? "COMMENT" : "CODE   ") " " $1 ":" $2}'
# -> 11 lines across 3 files: 8 COMMENT, 3 CODE. The three CODE lines are
#    zombie-loop-detect.sh:350 (the read), :402 (the notice it prints) and
#    dispatch-metrics-stop.sh:330 (a counter). NOT ONE of the three denies anything.
```

With the layer question answered *neither*, the deciding test is this repository's own — *which
direction do the errors run, and who sees them?* A bare-only reader errs toward refusing a real review; the tolerance
has no error direction that any of the ten spellings below could produce.

**The writer's contract is still tightened, and NOT to the same degree in both directions**, because
the two defects are not symmetric: **abbreviation is forbidden** — no reader tolerance can absorb it
without admitting an ancestor — while **bare is asked for and no longer load-bearing**. Saying it
was forbidden would be a claim this instrument now falsifies, and a brief that states a consequence
its own reader does not produce is the defect this whole section exists about.

**THE CALIBRATION DISCRIMINATES, which the struck one never did — same PR, same corpus, the two
limbs returning DIFFERENT numbers.** The stale SHA is DERIVED FROM THE ARTIFACT rather than typed,
and no reader is told to mutate anything: PR 493 carries two markers, each naming its own head, so
the honest answer at either head is **1**.

```
gh pr view 493 --repo tedeuxx/tadeumendonca-skills --json comments --jq '
  ([.comments[]|select(.body|test("harness-lead-verdict"))
    |(.body|capture("(^|\n)commit:[^0-9a-f\n]*(?<c>[0-9a-f]{40})").c)]|first) as $stale
  | {stale: $stale,
     struck_limb:    [.comments[]|select(.body|test("harness-lead-verdict"))
                                |select(.body|contains($stale))]|length,
     corrected_limb: [.comments[]|select(.body|test("harness-lead-verdict"))
                                |select(.body|test("(^|\n)commit:[^0-9a-f\n]*" + $stale))]|length}'
# -> {"stale":"10c640e27d909512a4b9c96fdcc0671ffa0e63ff","struck_limb":2,"corrected_limb":1}
#    the struck limb OVER-READS a marker that merely mentions that SHA while attesting another.

# VACUITY GUARD — the corrected limb against a SHA no marker names. A selector that cannot return
# zero is not a check:
gh pr view 493 --repo tedeuxx/tadeumendonca-skills --json comments --jq '
  ("0" * 40) as $absent
  | [.comments[]|select(.body|test("harness-lead-verdict"))
               |select(.body|test("(^|\n)commit:[^0-9a-f\n]*" + $absent))]|length'
# -> 0
```

**What the corrected limb still does NOT do, said here rather than left to be found.** It reads a
comment body, so a marker whose `commit:` line names a SHA the lens never actually read is
indistinguishable from an honest one, and nothing anywhere compares a marker's claim against what was
reviewed. **It is an instrument a human runs, not a bound** — the paragraphs below are unchanged, and
nothing here denies a merge.

**THIS IS NOT A PARALLELISM DEFECT AND MUST NOT BE SOLD AS ONE.** It bites identically at `wip: 1`.
What `wip` > 1 changes is the **rate**: a serial gate queues merge requests, so a PR sits open longer
between its lens pass and its merge, and heads move more in that window.

**The repair, landed in this slice:** hold 2 now requires a marker **naming the head being merged**
(`agents/quality-assurance.md`), and `hooks/scripts/zombie-loop-detect.sh` — registered on **`Stop`**
in `hooks/hooks.json` — reports a PR whose markers are **all** stale at the end of a turn. **Neither is
a bound.** The rule is the gate persona's discipline; the notice is detection one turn late and cannot
reach a turn that already merged. **A `PreToolUse` deny was rejected on a measurement, not deferred on
cost:** hold 2's trigger is a path predicate over the diff, `gh pr view --json files` pages at 100, and
a large harness diff would therefore classify as non-harness and fail open — inert exactly where it is
most needed.

### The REVIEW GATE IS SERIAL, and that is what makes parallel development safe (#385, owner ruling 1)

**Development parallelises. The gate does not.** The owner's words, 2026-09-10: *«o gate de revisao ser
serial acho que simplifica. o que me incomoda mais é paralelismo de desenvolvimento»* — so **at most one
merge request is in review at a time, whatever `wip` says**, and the next one is not dispatched to
`quality-assurance` until the previous one has merged or been sent back.

**This rule is HERE rather than in a brief, and the reason is mechanical.** Selecting a review chain is
the **orchestrator's** act; the orchestrator preloads nothing and is dispatched by nobody, so a skill
body and an agent brief both fail to reach it — measured in the two blocks above, which this block
cites rather than re-deriving. **Every persona that could read a brief is a dispatchee, and a
dispatchee cannot select its own dispatch.**

**What seriality BUYS is the composition hazard, and it buys it CONDITIONALLY rather than by
construction.** The hazard at `wip` > 1 is not two markers on one PR — it is that each verdict attests
a head that does **not** contain the other branch's diff, so merging both yields a configuration no
reviewer ever read.

~~Under a serial gate the second merge request is always read against a trunk already containing the
first.~~ **STRUCK 2026-09-21 — FALSE, and it is struck in place rather than edited away because it is
the sentence the parallel-development design rests on.** A reader who took *by construction* from it
concluded that ruling 1 alone closes the hazard, and it does not. **Seriality guarantees the
composition property ONLY when the second branch is rebased onto the trunk after the first merge
lands, and nothing enforces that rebase** — a branch cut from an older trunk is reviewed, attested and
merged with every check green.

**Note the shape of the defect rather than only the word.** The struck sentence shipped WITH a
measurement, and the measurement is sound: the 451/454 check below genuinely returns CONTAINED. **A
true measurement of two cases was published as an unconditional property of the mechanism**, and the
falsifier passed every time it was run because it was only ever run against the cases it came from.
Read a published command as testing the SCOPE it was taken on, never the claim it sits beside.

**The two measurements below are one TRUE case and one FALSE case, and the second is why *always* had
to go.** The first is unchanged, re-derived at head, and scoped to what it measured — two consecutive
merges where the rebase happened to have been done:

```
gh pr view 451 --repo tedeuxx/tadeumendonca-skills --json headRefOid,mergeCommit,mergedAt
gh pr view 454 --repo tedeuxx/tadeumendonca-skills --json headRefOid,mergeCommit,mergedAt
git merge-base --is-ancestor 6dd54992 c0ed67d9 && echo CONTAINED
# -> CONTAINED        #454's REVIEWED head already carried #451's merge commit
git merge-base --is-ancestor e44c8de3 ed1c751e || echo "NOT CONTAINED (expected)"
# -> NOT CONTAINED (expected)   the inverse, so the predicate can answer both ways
```

**The counter-example is on this repository's own history, under a serial gate, eleven minutes apart
— re-derived 2026-09-21:**

```
gh pr view 484 --repo tedeuxx/tadeumendonca-skills --json mergedAt,mergeCommit
# -> merged 2026-09-21T15:33:44Z, merge commit 01e11d74
gh pr view 488 --repo tedeuxx/tadeumendonca-skills --json createdAt,headRefOid
# -> opened 2026-09-21T15:44:26Z — AFTER 484 merged — reviewed head 41f1a954
git merge-base --is-ancestor 01e11d74 41f1a954 || echo "NOT CONTAINED"
# -> NOT CONTAINED               the gate attested a head that did not carry #484
git merge-base --is-ancestor 959e8470 41f1a954 && echo "CONTAINED (calibration)"
# -> CONTAINED (calibration)     an older trunk commit IS an ancestor, so the predicate answers both ways
git log -1 --format='%p' 37a3da04
# -> e824507f 41f1a954            the merge's parents: trunk tip, and the reviewed head that lacked it
```

**#488's branch was cut from an older trunk and never rebased**, so the two diffs were composed at
merge with no reviewer having read them together — **in the same two files**
(`hooks/scripts/permission-guard.sh` and its suite). It came out clean, and the gate verified that
**after** the irreversible act.

**The operative check is the transferable half, and it is not the one that was run: *has the trunk
moved since the head I attested?*, never *does the named concurrent branch overlap?*** #488's gate
verified the named concurrent branch, found zero overlap, and missed the trunk entirely — **the trunk
is not a branch anybody names in a dispatch**, so a check phrased over concurrent branches is blind by
construction to the one commit that actually composed.

**Composition does NOT cover this, and must never be cited as covering it.** Planning for disjoint
files prevents **merge conflicts** — textual disjointness is precisely the condition under which git
stays silent — while the composition hazard is **semantic** and invisible to git. ~~**Ruling 1 covers
it alone.**~~ **Struck with the sentence above and for the same reason: ruling 1 PLUS the rebase is
what covers it, and ruling 1 is the only half anybody has ruled on.** Nothing here weakens ruling 1 —
the serial gate stands as the owner decided it, and what is corrected is a claim about what it buys
unaided.

**Conflicts are resolved at MR time by the slice's author** (owner ruling 2 — *«os conflitos deveriam
ser resolvidos em tempo de MR»*), and seriality changes when that happens: the second author rebases
onto a trunk that **already moved**, so *"at MR time"* means after the first merge lands, not at
PR-open.

**The sequence inside an iteration is the machine's** (owner ruling 5 — *«nao preciso participar dessa
decisao quanto a sequencia de trabalho dentro do sprint»*). `scrum-master` proposes the set, the
orchestrator opens the worktrees and dispatches, and **there is no per-item approval**. **That removes
the one human checkpoint that would have caught a bad set, and he took it knowingly** — recorded here
so nobody re-derives it later as an oversight. The deliberate contrast with the `content` lane, which
is selected one piece at a time and never drained, is design rather than inconsistency.

**Isolation is `git worktree`** (owner ruling 4), reversing the 2026-08-13 rule that permitted only one.
**The hook layer is already worktree-ready and that was measured rather than assumed:**

```
jq -r '.hooks|to_entries[]|.value[]|.hooks[]|.command' hooks/hooks.json   | sed 's|.*/hooks/scripts/|hooks/scripts/|' | sort -u | xargs grep -l 'rev-parse --git-dir'
# -> 6 of the 14 distinct SCRIPTS behind those 15 registrations key their state on the worktree's
#    OWN git dir (the pipeline ends in `sort -u`, so scripts is the noun), so two worktrees
#    never share a debounce namespace:
#    cadence-notice - closure-artifact-guard - orchestrator-tool-census
#    owed-pr-link-detect - premature-pr-link-detect - zombie-loop-detect

# and NOT ONE registered hook walks for a `.git` DIRECTORY, which is the class #439 repaired
# (in a linked worktree `.git` is a FILE, so such a walk runs off the top of the tree):
... | xargs grep -nE '\-d "[^"]*\.git"'
# -> no output
# calibration - the denominator is non-empty: the same pipeline without a grep lists 14 scripts.
```

**`#385`'s own body said *seven of thirteen*; at `eda00c41` the criterion above returns SIX of
FOURTEEN.** Both the numerator and the denominator moved, so the figure is re-derived here with the
selector that produced it rather than carried. **The conclusion is unchanged and does not rest on the
count**: the hooks that keep per-checkout state already scope it per worktree, and none of the other
eight keeps any.

**What holds ANY of the five rulings: nothing.** No layer observes which chain a dispatch ran, no
artifact records a dispatch, and `gh pr create` is allowlisted in **both** settings layers, so a second
concurrent merge request executes silently. By this loop's own test — *would something stop me, or only
my memory?* — **every one of the five is an instruction**, and that is why each is written where the
actor who must obey it actually reads.

### Rule 7c's ref residual, RE-PRICED at `wip` > 1 — the old hole is closed and a new one is named (#385)

**This is the one part of `#385` that touches the irreversible floor, and the re-pricing is owed
because the residual's published cost was stated AS A FUNCTION OF WIP=1.** The guard's own comment
priced it *"almost always the PR being merged"* — a property of how the loop happened to be run, not of
the rule.

**The flag-before-ref hole is CLOSED, and the check was re-run at head rather than inherited.** `#441`
(`dc480e16`, 2026-09-10) repaired it, and `#385`'s own body measured the pre-repair behaviour. Fed to
the guard with a namespaced `agent_type` so rule 7b does not short-circuit:

| payload | verdict at `eda00c41` |
|---|---|
| `gh pr merge 999999 --merge` | **deny** — names no pull request (the control) |
| `gh pr merge -t subjecttext 999999 --merge` | **deny** — *"puts a flag before the pull-request reference … cannot prove WHICH pull request"* |
| `gh pr merge --merge` | reaches the verdict read, and denies on it (the no-ref form is untouched) |

**`#385`'s body measured the middle row as ALLOW. It is DENY now.** The three verdicts differ by
message, not only by outcome, so the rows are distinguishable rather than collapsed into one — which is
what makes this a check rather than a coincidence. **The three priced options in the body — extend the
flag strip, write an argv parser, or accept it — are all moot: `#441` chose a fourth, "deny what cannot
be parsed", and it closes the class rather than enumerating it.**

**What `wip` > 1 DOES make live, and it is a different residual that nobody had named.** `gh pr merge`
with **no reference** merges *the current branch's PR*, and rule 7c reads that same PR's verdict — so
guard and act agree, which is why the no-ref form is correctly left alone. **But "the current branch"
is a property of the CWD**, and under one worktree per slice the cwd is no longer unique. Measured from
this slice's own linked worktree:

```
git -C <worktree> branch --show-current   # -> loop/wip-parallel-385
git -C <primary>  branch --show-current   # -> main
# `gh pr merge --merge` evaluated with cwd = the worktree resolves against the WORKTREE's branch:
# -> "this command carries NO --repo, so 'gh' resolve[d]" against that branch's PR, and denied
#    because that branch has none.
```

**So at `wip` > 1 a no-ref merge issued from the wrong checkout merges a DIFFERENT slice's pull
request, and rule 7c validates it consistently** — it reads the verdict of the PR `gh` will actually
merge, so the floor is not bypassed and nothing fails open. **The failure is a correct merge of the
wrong thing**, which no layer can detect because both halves agree.

**The mitigation is an instruction and it is cheap: a gate dispatch names the PR number positionally,
first.** `gh pr merge <number> --merge`. **What holds it: nothing** — the no-ref form is a legal,
allowlisted invocation that this floor deliberately permits, and making it deny would break the
single-checkout case the loop still uses. **Accepted with its cost stated**, which is the honest form
when there is no cheap mitigation.

### What nothing enforces — per decision, because "nothing enforces this" flattened is false

| decision | what actually holds it |
|---|---|
| the mode is recorded at all | ~~**nothing reads the record**~~ — **corrected 2026-09-09 (slice B): `commands/autonomy.md` reads it, which is a rule a session executes and not a mechanism.** Nothing MECHANICAL reads it, and no gate asserts the record exists or parses. `git log` over one path still gives the proportion to a human |
| the mode is read BEFORE any pool query | **an instruction.** No layer sees a query's intent |
| the two repositories agree on the mode | ~~**nothing.**~~ **Narrowed 2026-09-09 (slice B): an instruction, in one context only.** The drain already reads both trees, so it compares the two records at entry and stops on a disagreement. **Every other context — a rite, an ad-hoc session, a dispatched persona — still has nothing**, and a hook cannot close it: it receives one `cwd`, so it would have to guess where the sibling tree is in order to compare a string, which is assuming what it checks |
| loop-first survives in either mode | **the ordered artifact, and awkwardness.** #339 already measured this ungateable at every layer |
| the rites run at all | **nothing today, in either mode** |
| `wip` is honoured | **nothing.** `wip-guard.sh` was deleted at #383 and nothing bounds work in progress. **Unchanged by #385 giving `wip` a value** — `gh pr create` is allowlisted in both settings layers, so an (N+1)th concurrent merge request executes silently, with no prompt and no record |
| the review gate stays serial | **an instruction, in this block** (#385, owner ruling 1). Nothing observes how many reviews are in flight: a dispatch leaves no artifact, and the one lens whose participation would be visible on a PR posts nothing at all — rule 5e denies `product-lead` the comment subcommands |
| a branch is rebased onto the trunk before its gate dispatch | **nothing, and this is a NAMED RESIDUAL since 2026-09-21 rather than a property of the serial gate.** Seriality composes safely only across a rebase, and no layer observes one: a branch cut from an older trunk is reviewed, attested and merged with every check green — measured on `#484`/`#488`, eleven minutes apart, in the same two files. The operative question is *has the trunk moved since the head I attested?*, which no dispatch phrased over concurrent branches reaches |
| the composed set does not collide | **nothing.** `scrum-master` holds `tools: []`, `SELECTION-RECORD` has no consumer, and nothing verifies the pool it was shown. Ruling 5 removed the per-item human checkpoint deliberately, so a bad set runs |
| the `agents-lead` marker names the head being merged | **the gate persona, plus one detector.** `agents/quality-assurance.md`'s hold 2 requires it and nothing denies on it; `hooks/scripts/zombie-loop-detect.sh`, registered on **`Stop`**, REPORTS a PR whose markers are all stale — one turn late, and never a bound on the merge |
| worktrees are cleaned up after merge | **nothing mechanical.** `#437` closed the lifecycle question and `hooks/scripts/worktree-notice.sh` REPORTS; it removes nothing. Re-derived 2026-09-11: `-io` carried 28 linked worktrees and `-skills` 5, before this slice added one to each |
| a cadence trigger keys on the CLOCK and not on the pool being empty | ~~**nothing — and the carrier is not built yet, so this is a rule written before its object**~~ — **the object exists since 2026-09-09 (#406 slice C), and the row splits.** *For the carrier that exists:* it is held by **construction plus a test** — `hooks/scripts/cadence-notice.sh` makes no tracker call at all, and its suite asserts that with a recorder on `PATH` in place of `gh` rather than by removing `gh`, so the zero is a real zero. *For any FUTURE trigger:* still **nothing**. No layer reads a hook's intent, and a second carrier keyed on emptiness would be caught by review or by nobody |

~~**Six of seven are instructions and one is a report.**~~ **Struck 2026-09-09 (slice B): the tally is
stale and a tally beside a table is a second source of truth for one fact, which is the arrangement
this repository's own gate exists because it rots.** The criterion is what survives: **not one row is
held by a layer that could stop the act — every entry is an instruction, an artifact a human reads, or
nothing at all.** Read the column and count if a number is wanted.

By this loop's own test — *would something stop me, or only my memory?* — **the mode contract is not
engineered, and it is not presented as if it were.** A configuration surface invites the reading that
something reads it. ~~nothing does~~ — **corrected: `commands/autonomy.md` does, and no mechanism
does.** That distinction is the whole of what slice B changed here, and collapsing it in either
direction is wrong: claiming nothing reads the record understates it, and calling a rule a session
executes a mechanism overstates it.

**One rule in that table is worth stating twice, because it is the only place in this design where a
wrong guess is SILENT: the mode is read from its record before any pool query, and nothing may infer
the mode from what a pool query returns.** Measured — the active-iteration derivation prints nothing
and exits 0 when the eligible set is empty; `echo '[]' | jq 'min'` returns `null`, exit 0.

**Ruling 3 did not remove that ambiguity — it MOVED it, and the new form is harder to see.** Before,
the reading was *"no milestone at all"* versus *"Scrum with its milestones dropped"*. Now **both modes
carry a milestone**, so the confusable pair is *an empty active milestone in `kanban`*, where it means
nothing whatever, against *an empty active milestone in `scrum`*, where it is the terminal condition
that hands off to the closing rites. **The two produce a byte-identical query result and opposite
correct behaviours.** A drain that infers its mode from the result either reports a healthy queue over
a dark one or fires a ceremony on noise, with every check green either way.

### The three rulings this block is written against — all 2026-09-09, none of them decided here

**This section named two decisions as OPEN until the owner answered them mid-build, and it is rewritten
rather than annotated because a contract carrying a stale *"open"* is worse than one carrying a stale
answer: a reader stops at it and waits.**

1. **The cadence carrier is BUILT** — *«Constrói o gatilho por relógio»*. A `SessionStart` notice when
   the interval has elapsed, **never a control**, on the honest comparison of **clock versus nothing**:
   the boundary trigger it replaces has never fired either. **It is NOT built in this slice and must
   not be** — a contract says what a mode may vary; a trigger is a mechanism, and keeping the two apart
   is the whole point of writing the contract first. **What the ruling did not decide: the interval**,
   which was not asked and is not inferred here. **BUILT 2026-09-09 in its own slice, as the sentence
   above required** — `hooks/scripts/cadence-notice.sh` plus `docs/loop-cadence.md`. The *"not in this
   slice"* clause is left standing rather than struck: it was, and remains, true of the slice it was
   written in, and it is the reason the carrier is a separate merge request rather than a paragraph of
   this one. **The interval is still not decided** — the carrier ships with it undeclared and reports
   that fact once a day instead of choosing a number.
2. **`sp:N` stays in BOTH modes** — *«Mantém o `sp:N` nos dois modos»*. Recorded in the untouchable
   list above with its cost, and it removes an axis rather than adding one.
3. **The iteration NUMBER is used in both modes** — *«nao tem problema numero da iteracao ser utilizado
   nos dois modos»*, unprompted. Recorded in the enum above as *commitment versus label*.

**Rulings 2 and 3 each REMOVED an axis a mode may vary.** That is the useful shape to notice: a mode
config gets better by shrinking, because every axis is a place the two modes can drift apart with
nothing watching.

### The two copies of this block must stay identical

**A mode is a WORKSPACE property, and a session rooted in one repository loads neither the other's root
brief nor a sibling's** — measured in the block above. So this block is shared, byte for byte, between
`CLAUDE.md` at the root of `tedeuxx/tadeumendonca-skills` and `CLAUDE.md` at the root of
`tedeuxx/tadeumendonca-io`. From a workspace holding both checkouts:

```
diff <(sed -n '/^<!-- loop-mode-contract -->$/,/^<!-- \/loop-mode-contract -->$/p' tadeumendonca-skills/CLAUDE.md) \
     <(sed -n '/^<!-- loop-mode-contract -->$/,/^<!-- \/loop-mode-contract -->$/p' tadeumendonca-io/CLAUDE.md)
```

**That is an OBLIGATION and not a claim about either copy's current state — nothing checks it, and
nothing makes the two move together.** The sibling's merge request had not landed when this was
written, so the command above is expected to print the whole block. **This is now the THIRD
hand-maintained two-repository block in this file**, and that is a cost stated rather than discovered:
each one is a place where two files can disagree in silence, and the only instrument is a `diff`
somebody has to remember to run.

**`AGENTS.md` deliberately does NOT carry this block**, and the reason is its own rule rather than
budget: that brief states obligations addressed to an agent, never descriptions of enforcement, and the
untouchable list above is a measurement of this harness's own hook layer. **The portable statement of
the same contract is `docs/prompts/loop-mode-contract.md`**, which is what another harness adopts.
**The residual: if a mode ever gains an operative rule a session on other machinery must obey, that
rule is owed to `AGENTS.md` as an obligation, and nothing will say so.**
<!-- /loop-mode-contract -->

---

<!-- dive-deep-orchestrator -->
## A premise you assert in a dispatch brief BECOMES the design (tedeuxx/tadeumendonca-skills#426)

**Fourth block in this file addressing the ORCHESTRATOR — the main session — and it is here for the
reason the three above are.** `#410` landed *dive deep* as the twelfth principle in the
`engineering-standards` skill, which all eight profiles preload. **The orchestrator preloads nothing**:
`#409` measured, one nonce per candidate surface, that a skill body does not reach this context while a
repo-root `CLAUDE.md` does. So the principle whose motivating failure was the orchestrator's own was
readable by every context except that one.

### The rule

> **Do not assert in a dispatch brief a premise you have not measured. Measure it and carry the
> command, or write it into the brief as a premise the dispatch must VERIFY — never as a fact it may
> inherit.**

**This is narrower than the skill's principle and must not be flattened back into it.** That one
addresses a builder deciding how deep to investigate a symptom in code. This one addresses a single
act: **composing a brief.** A dispatch brief is not a claim someone will later check — it is the
specification the dispatch builds against, so a false premise in it is not a wrong answer, it is a
wrong design, and the dispatch executes it faithfully.

**The tell is the twelfth principle's own: an answer that is TRUE and closes the inquiry.** *"The
failure was mine, no configuration causes it"* is the shape it takes in this context — always
available, never falsifiable, and it ends the investigation exactly where the mechanism begins.

### This carrier is WEAKER than the three above it, and the block says so rather than implying otherwise

`#409` measured this file reaching the orchestrator's **context**. It did not measure it reaching the
**turn**, and those are different claims: a brief is composed hundreds of turns after the file loaded.
**The three blocks above at least attach to an act some layer can see** — a command string, a picker
payload, a pool query. **This one attaches to text being composed, and no layer observes that.**
`SubagentStart` carries `session_id`, `transcript_path`, `cwd`, `prompt_id`, `agent_id`, `agent_type`
and `hook_event_name`, and **no prompt text** (`#209`, quoted in the metrics hook's own header).

**Do not read that as *ungateable* — that is the same over-claim pointing the other way.** A dispatch
is a tool call, so a `PreToolUse` matcher on it would see the brief's text; that is **available and
unmeasured**, named here rather than claimed. What no layer reaches either way is the half that
matters — **whether a premise inside the brief is TRUE** — which is not a string property, and a
detector for it would fail open.

**So this is an instruction, and it is the weakest of the four.** By this loop's own test — *would
something stop me, or only my memory?* — nothing stops it. It lands anyway on `#393`'s argument: it
removes the dependency on a fresh context happening to know the rule, and that dependency has now
failed six times, every one caught by a dispatch or a gate and none by the orchestrator.

### The two copies of this block must stay identical — and the falsifier ships with a CONTROL

**Shared byte for byte between `CLAUDE.md` at the root of `tedeuxx/tadeumendonca-skills` and
`CLAUDE.md` at the root of `tedeuxx/tadeumendonca-io`**, for the reason `#393`'s probe measured: a
session rooted in one repository loads neither the other's root brief nor a sibling's, even with the
sibling added as a working directory.

**Run the CONTROL first. A `sed` range whose pattern matches nothing emits nothing, so an absent block
and an identical one produce the same silent exit 0** — confirmed 2026-09-10 by running the diff below
against a delimiter name present in neither file: no output, exit 0, indistinguishable from a pass.
From a workspace holding both checkouts:

```
# CONTROL — both sides must report 2 (one opening and one closing delimiter).
# A 0 or 1 on either side means the diff below CANNOT fail, whatever it prints.
grep -c -E '^<!-- /?dive-deep-orchestrator -->$' \
  tadeumendonca-skills/CLAUDE.md tadeumendonca-io/CLAUDE.md

diff <(sed -n '/^<!-- dive-deep-orchestrator -->$/,/^<!-- \/dive-deep-orchestrator -->$/p' tadeumendonca-skills/CLAUDE.md) \
     <(sed -n '/^<!-- dive-deep-orchestrator -->$/,/^<!-- \/dive-deep-orchestrator -->$/p' tadeumendonca-io/CLAUDE.md)
```

**The three blocks above publish their diff WITHOUT that control, so all three read green vacuously if
a delimiter is ever renamed or dropped.** Verified 2026-09-10 that all three are genuinely identical at
head — six delimiter lines in each file, every diff clean — so that is a defect in the published
instrument, not a live drift. **Repairing those three is its own slice:** it edits three byte-identical
spans in two files each, and a one-byte slip there breaks the falsifiers it exists to fix.

**That is an OBLIGATION and not a claim about either copy's current state — nothing checks it, and
nothing makes the two move together.** Pipelines are independent per repository, so a change to this
block is a two-repository batch, and the command above is expected to print a difference in the window
between the two merges.

**`AGENTS.md` deliberately does NOT carry this block.** That brief states obligations addressed to an
agent on machinery nobody here has measured; this one names `SubagentStart`, a payload field set and a
tool matcher, which are descriptions of this harness's own enforcement layer. The obligation is
portable; the enforcement analysis around it is not.
<!-- /dive-deep-orchestrator -->

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
| interview transcripts, raw source material | **`.brand/` in `tadeumendonca-io`** — private and gitignored *there*, which is the documented home for exactly this. ~~**It is NOT gitignored in this repo**, so the path is only safe in the repo that ignores it; writing private material to `.brand/` here puts it in a tracked path in a public repo.~~ **Struck by this slice's own `.gitignore` entry — `.brand/` is ignored in THIS repo too now.** Struck rather than deleted because this is the sentence that told every reader the path was unsafe here, and a reader who acted on it deserves to find out it changed. **The home is still `tadeumendonca-io`, and the ignore stops a COMMIT, not a PASTE** — private text has reached public GitHub through an Issue body and a PR comment, which no `.gitignore` observes and whose edit history is not repairable. |
| a measurement instrument | **a repo script with a test, if and only if a gate will run it.** Otherwise discard. "It worked once" is not "it must persist". |
| an isolated checkout | **not a scratch class.** Use the repo — WIP=1 already serialises — or a git worktree with its own install. |
| continuity state that must survive the session | **not a scratch class either — the Issue being worked, as a worklog `handoff` or `checkpoint` event** (#514), prepared with `scripts/worklog.py prepare-event` and posted with `--body-file`. **Never a file in a shared temporary directory**: that is how sprint state was carried across sessions once, and the fifth such file resumed a session with its words glued together. The format is bounded because the Issue is public: facts and one `next_act`, one line each, no private reasoning. The contract and the resume command are in `docs/worklog/README.md`. |

### `.brand/` — THIS section is the canonical home of that fact, and the other four are pointers (#479)

**The fact, stated once and completely: `.brand/` is the owner's private positioning source, and it is
gitignored in BOTH repositories** — in `tadeumendonca-io` since that repo was stood up, and here since
#477 (`.gitignore:17`). Its documented home is still `tadeumendonca-io`; this repo ignores it
preventively and has never held one.

**Why it needed a ruling: the fact lived in five places and two of them disagreed.** On 2026-09-20
`README.md` listed `.brand/` among this repo's gitignored paths — **false until #477 merged**, hours
earlier — while the taxonomy row above said the opposite and was right. **Neither noticed the other,
and the false one was the PERMISSIVE one**, claiming a protection that did not exist.

**Why the canonical home is here, and the second reason is mechanical.** The scratch taxonomy above
already owns this fact — it is the table that says where raw source material goes. And **this is the
only brief that reaches the ORCHESTRATOR**: #409 measured, one nonce per candidate surface, that a
repo-root `CLAUDE.md` reaches that context while a skill body does not and `AGENTS.md` does not. The
context that pasted private material onto a public surface was the orchestrator. **A canonical
statement the leaking context cannot read is not canonical for the failure it exists to prevent.**

**The four pointers — `README.md`, `agents/product-lead.md`, `.gitignore`'s own comment, and `-io`'s
side — and one of them cannot be a bare pointer.** **`-io` does not load this file**: #393 measured
that a session rooted in one repository loads neither the other's root brief nor a sibling's, **even
with the sibling added as a working directory**. So `-io`'s statement must stand on its own as a
complete sentence rather than as *"see the plugin repo"*. **That is a pointer in intent and a
restatement in fact**, said here rather than papered over — and **no fifth hand-maintained
two-repository block is created for it**, because four is already a cost this file names in its own
words.

**What enforces any of this: nothing, and no gate arm is added.** An arm asserting that one sentence
exists in one file is a green that has never been red, and the failure it would have to catch — two
surfaces disagreeing about one fact — is a cross-file consistency check nothing here has the shape
for. **And the ignore stops a COMMIT, not a PASTE**, which the row above already says and which is the
route by which private text has actually reached public GitHub.

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
