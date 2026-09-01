# 0005. The plugin auto-versions on every merge; adoption is the consumer's opt-in

- **Capability:** plugin-distribution
- **Status:** accepted
- **Date:** 2026-07-23
- **Deciders:** the owner
- **Supersedes:** the informal "trunk-based release-only" model (introduced by commit `90a2fec`, never recorded as an ADR)

## Context & problem
This repo is a Claude Code **plugin distributed through a marketplace**. Consumers install it and pull new
versions with `/plugin update`; the marketplace serves the plugin at the version in `.claude-plugin/plugin.json`.

A prior change (`90a2fec`, "trunk-based release model for the skills plugin") removed the auto-bump workflow and
made releases **deliberate-only** (`release.yml`, `workflow_dispatch`), on the reasoning that "a consumed
artifact's tags are a consumer lockfile, so it never auto-bumps on push." That reasoning fits a **semver-pinned
library** (npm dependency), but it is wrong for a **marketplace-distributed plugin**, and it produced a concrete
failure: 36 commits of real improvement — the entire agentic dev-loop roster (11 subagents) plus reconciled
skills — sat on `main` at an unchanged version `0.4.0`, never released, and therefore **never reachable by the
installed plugin**. A restart didn't help, because a restart reloads the *installed* (cached, pinned) plugin, not
`main`. The machine existed in git but not in the harness.

The confusion was conflating **publishing a version** with **forcing adoption**. They are separate: publishing is
cheap; whether to adopt a new version is *always* the consumer's decision (`/plugin update` is opt-in). So there
is no cost to publishing on every merge, and a real cost to not doing so.

## Decision drivers
- A marketplace plugin is only consumable at a *published version* — an unreleased `main` is invisible to it.
- Publishing ≠ forcing: adoption is the consumer's opt-in, so frequent publishing has no downside for consumers.
- The failure mode of deliberate-only is silent: work merges, looks done, and never ships to the harness.
- Consistency with the deploy-model repos (`-io` auto-bumps patch on merge via `version-main.yml`).

## Considered options
1. **Auto-bump PATCH + publish a Release on every merge to `main`; deliberate minor/major on demand** (chosen)
   — a `version-main.yml` mirrors the deploy-model repos: every non-`bump:` push to `main` bumps the patch,
   tags `vX.Y.Z`, and publishes a Release. `release.yml` is kept for a deliberate minor/major milestone. *Trade-off:*
   the version number churns fast (every docs typo is a new patch), and tag history is noisy. Accepted because
   adoption is opt-in — a consumer simply skips versions it doesn't want.
2. **Deliberate release-only** (the prior model, `release.yml` only) — *Why not:* it caused this exact incident.
   It optimizes for a semver-pinned-library consumer this plugin does not have, at the cost of work silently never
   reaching the marketplace.
3. **Auto-bump but suppress the Release for trivial commits** (e.g. only `feat:`/`fix:` publish) — *Why not:* adds
   a classification gate and a judgment call for marginal benefit; the churn it avoids is free to the consumer
   anyway (opt-in adoption). Keep the rule dumb and predictable: every merge publishes.

## Decision outcome
Chosen: **every merge to `main` auto-bumps the patch and publishes a Release** (`version-main.yml`), with
`release.yml` retained for deliberate minor/major. This makes the plugin **continuously releasable** so
improvements reach consumers as fast as they choose to pull them, and it removes the silent "merged but never
shipped" failure mode. The distinction the prior model missed is now explicit in `/workflow/versioning`: a
**marketplace plugin** auto-publishes (adoption is opt-in); a **semver-pinned library** releases deliberately (its
tag is a consumer lockfile).

## Consequences
**Good**
- No work is ever stranded on `main` — a merge is a published version a consumer can pull.
- Publishing and adoption are cleanly separated; the owner never has to remember to cut a release for changes to ship.
- Consistent versioning trigger with the deploy-model repos.

**Bad / accepted costs**
- Version numbers and tags churn quickly; a patch is not a curated milestone (minor/major via `release.yml` are).
- Release notes are per-merge and small; the categorized changelog still groups by conventional-commit type.
- A consumer that wants stability must pin a version deliberately rather than tracking latest.

## Links
- Supersedes the informal release-only model (`90a2fec`); reconciles `/workflow/versioning` and
  `/workflow/github-actions` (which stated "a consumed artifact never auto-bumps"). Same numeric-SemVer scheme as
  record-0001-era decisions (now [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md));
  the trigger, not the scheme, is what this changes.

---

## Amendment (2026-08-10) — a follow-on PATCH may carry the remainder of an already-announced break, and this one is a MAJOR being dodged

**The decision above is unchanged.** The trigger stands: every merge auto-bumps the patch and publishes,
adoption stays the consumer's opt-in. What this amendment adds is the axis the original record left to
`/workflow/versioning` and `CLAUDE.md` — **which part** is honest — for one case they do not cover: the
**second half of a break whose first half already shipped under a MAJOR**.

**Why this record and not another.** This is the only ADR in the methodology library that holds the
version-number contract, and its own outcome already splits the space into *auto-patch* and *deliberate
minor/major*. The rule being recorded sits exactly on that seam. `CLAUDE.md`'s *Releasing a version*
section states what each part means and is **not restated here**; this amendment records only when a
follow-on PATCH is the honest carrier, and it does not amend that rule.

Decided by the owner at
[#164 comment 5240908344](https://github.com/tedeuxx/tadeumendonca-skills/issues/164#issuecomment-5240908344),
authorised at [comment 5245299011](https://github.com/tedeuxx/tadeumendonca-skills/issues/164#issuecomment-5245299011),
implemented by [PR #182](https://github.com/tedeuxx/tadeumendonca-skills/pull/182), which this amendment
rides in.

### 1 · The two readings, and the one the repo acts on

**The owner recorded this as an interpretation, in those words, and it is kept as one.** Two readings fit
the same commits and **nothing in the tree decides between them**:

- **One contract change, cut halfway** (chosen). `#174` and the directory split were decided together as
  one move — merge the colliding stems, then flatten. `1.0.0` shipped the first half. On this reading the
  remainder is **bugfix flow**: the version meant to carry the whole break carried part of it, the rule
  that *a command renamed or removed is a major* was **satisfied at `1.0.0` rather than waived**, and
  cutting `2.0.0` would announce a second break where one happened.
- **Two separate breaks.** `#174` removed four commands; the split renames sixty-nine. Read strictly each
  is independently major, and the second is **absorbed rather than announced**.

**Neither is provable from the record**, and that is the honest state rather than a gap to be closed. The
owner's comment additionally carries a **struck earlier version** that asserted the second reading as the
grounds; it is struck, not deleted, because the difference between the two arguments is the substance
here. A reader who takes only the outcome from this amendment will think the call was mechanical. It was
not.

One fact worth having while judging it, checkable in one command: `7590a14` is `bump: 0.4.60 → 1.0.0`,
cut by `release.yml` **on top of** the auto-patch that #174's own merge had already published. So `1.0.0`
carried **no content of its own** — it was an announcement, deliberately, which is what makes "the
version that announced the break" a coherent thing to point at.

### 2 · The escape that is not available, stated plainly

There is a reading under which PATCH is uncontroversial: **if `commands/` kept existing and `skills/`
were purely additive, nothing would rename.** That reading is **not available here** and this record does
not lean on it. Measured on the implementing branch:

    ls commands/            -> autonomy-on.md  new-issue.md            (2)
    ls skills/ | wc -l      -> 69

`commands/` is emptied of the 69 and `/<plugin>:infrastructure/vpc` becomes `/<plugin>:vpc`,
sixty-nine times. **So the PATCH is being justified in the case where the names actually change** — i.e.
on the first reading it is a rule already satisfied, and **on the second reading it is a deviation from
the rule, taken knowingly.** Both sentences are true of the same act; which one applies depends on a
reading the record cannot settle.

### 3 · What makes it affordable is a fact about today's consumer, not a property of the policy

The single consumer is the owner's own and is **pinned**: `~/.claude/plugins/installed_plugins.json`
resolves the plugin to a per-version cache path (`…/tadeumendonca-skills/1.0.5`, and `1.0.0` for one
project entry), and `/plugin update` is opt-in. **A pin is a lockfile**, so nobody is carried across a
break they did not choose.

**This is stated as a circumstance, not a rule.** It licenses this instance; it does not license absorbing
breaks in general, and it stops licensing anything the day a second consumer exists that this repo does
not control. Any future appeal to this amendment must re-derive the consumer set rather than cite it.

### 4 · The capability change the number does not carry

The split is not only a rename. Measured in #182 by the builder with `claude plugin details`, treatment
against control, one variable — **relayed here, not re-derived by this record**:

| tree | loader inventory | always-on |
|---|---|---|
| `commands/<family>/<name>.md` | **`Skills (2)`** | ~1,444 tok |
| flat `skills/<name>/SKILL.md` | **`Skills (71)`** | ~11,363 tok |

**+9,919 always-on tokens per session, and 69 files reachable as skills for the first time.** A PATCH
shipping a capability change of that size is worth naming under either reading — it is the strongest
single argument the *two breaks* reading has, and it is recorded here rather than left to the Issue.

### 5 · The second renamed surface — the `skills:` identifier — and how it is weighed

`CLAUDE.md`'s new *What is a command and what is a skill* section records that nesting broke **only** the
model's own discovery: typed invocation worked, and **`skills:` preloading worked with the family in the
identifier**. That is verifiable across the split:

    git show main:agents/tech-lead.md   -> skills: workflow:adr, principles:engineering-philosophy, …
    agents/tech-lead.md (this branch)   -> skills: adr, engineering-philosophy, …

So **two published surfaces rename, not one.** Weighed, since it could cut either way:

- **It strengthens the *two breaks* reading on the facts** — the change is broader than the slash surface,
  and the additive escape of §2 is closed twice over rather than once.
- **It does not strengthen it in the SemVer sense**, and this is the part that decides the part. The
  `skills:` identifier has exactly **one author today**: `agents/**` inside this repo. The consumer has no
  `.claude/agents/` at all (checked on the local checkout of `tadeumendonca-io`), so no external file
  names one. And where it is authored, it is **gated** — `hooks/scripts/skills-resolve.test.sh` assertion
  5 rejects a family-qualified identifier by name and cites #164 in the failure text, which converts the
  loader's silent 0-byte failure into a red build.
- **The residual cost is real and belongs to a future consumer, not to this repo.** A persona brief
  written elsewhere against a family-qualified identifier fails at **0 bytes of stderr** ([ADR-0011](./0011-skills-and-preload.md), its *A persona's startup context is a curated preload (absorbed 2026-08-20, record 0010)* section), and
  the only instrument that can see it lives here. That is an argument for the announcement, not for the
  number.

**Ruling: it does not move the version part; it widens what the announcement must say.** The release note
owed below covers **both** surfaces or it is incomplete.

### 6 · The release-note obligation, and where the proposed assertion belongs

The owner's comment states the obligation: **the release carrying the split must name the rename in the
first line of its notes, because the number will not.** `quality-assurance` proposed an unbuilt
mechanism — an assertion that a release carrying a rename says so in its first release-note line.

**Ruled: not in this MR, and not anywhere in the proposed form.** The reason is a property of the
generator, read at `.github/workflows/version-main.yml:57-91` rather than assumed:

- The body is **generated in full** from conventional-commit subjects, grouped into fixed sections, and
  written to `RELEASE_NOTES.md` seconds before `gh release create`. **Nobody authors release notes in
  this repo.** An obligation phrased as "the notes must say X" therefore has no author to bind.
- `git log --no-merges` excludes the merge commit, so **the PR title never appears** — and #182's title
  is the only string in the whole chain that says the tree flattened.
- The first line is a **section heading**, never prose. For this branch's commits the generated body opens
  `### 🐛 Fixes`, and the rename appears third, under `### ♻️ Refactoring`, as *"the library moves to a
  flat skills/"* — which does not say that an invocation name changed.
- The check would also run **after** the bump has pushed and tagged, where a red build stops nothing and
  repairs nothing. Per [ADR-0004](./0004-controls-and-enforcement.md), that is the wrong layer: the
  only layer that can carry it is the one where a subject line is still editable, which is **PR time**.

**A follow-up may hold a re-specified version of it** — asserted against the **commit subjects** of a PR
that moves or deletes a published skill or command, where a red is fixable — and this record does not
pre-approve that design; whether the trigger is decidable from a diff is the open question, and it is not
this MR's.

**What makes the obligation survive without a reader — honestly: nothing automatic does.** The one act
available is human and after the fact: **`gh release edit vX.Y.Z --notes-file …`** rewrites a published
release body, so the owner can prepend the rename to the notes of the version that carries this merge.
Its cost is exact and is booked rather than glossed: a consumer who pulls in the interval between publish
and edit sees the un-annotated notes, and nothing records that the edit was owed except this paragraph.
**Naming it here is the weakest of the three options and is chosen because the other two are worse** —
an unbuildable assertion in this MR, or an obligation handed forward silently, which is a failure class
this repo has already paid for.

### 7 · Considered and rejected

1. **Cut `2.0.0`** — the strict reading of §1. *Why not:* on the owner's decision, it announces a second
   break where the first announcement was already paid for, and `1.0.0` had no content precisely because
   it existed to announce. *Cost of the rejection, stated:* if the *two breaks* reading is the true one,
   the repo has absorbed a rename of 69 invocation names plus an identifier contract into a patch, and
   the only thing standing between that and a broken consumer is the pin of §3.
2. **A MINOR as a middle position** — bigger than a patch, short of a break. *Why not:* SemVer has no
   part meaning *"announced elsewhere"*; a minor asserts backwards compatibility, which is **false** here
   under either reading. It would buy a signal by making the number lie.
3. **Hand-author the release notes for this one version** — *Why not:* the generator overwrites
   `RELEASE_NOTES.md` unconditionally on the merge push, so there is no pre-publish seam to write into.
   That is why §6 lands on the post-publish edit rather than on authorship.

### 8 · Consequences

**Good**
- The interpretive call is on the record with **both** readings, so the next reader can disagree with the
  chosen one instead of inheriting it as mechanics.
- The rule is narrow and stated with its precondition: a follow-on PATCH is honest **only** for the
  remainder of a break whose announcement already shipped, and only while the consumer set is pinned and
  controlled.

**Bad / accepted costs**
- **The version number does not carry the largest surface change this plugin has made.** That is the
  price of the chosen reading, paid in full.
- **The announcement it is traded for has no mechanism** (§6), and the fallback is a human act nothing
  checks.
- **`1.0.0` now reads as covering more than it shipped.** Its release notes describe #174; the record that
  it was also the announcement for the split lives only here and in #164.

## Amendment (2026-08-21) — a SECOND distribution target, and only the knowledge layer travels to it

**Deciders:** the owner (*"quero manter compatibilidade tanto com kiro como claudecode com seus
mecanismos nativos"*) · pre-implementation stress test and implementation by `agents-lead` · Issue #287.

### 1 · What changed

This repository is now installable by **two** harnesses through **two** native mechanisms, from one
tree, at the same time:

- **Claude Code** — unchanged. `.claude-plugin/marketplace.json` + `.claude-plugin/plugin.json` with its
  `skills` array. Nothing in this amendment touches that path.
- **Kiro** — a **Power** at `powers/tadeumendonca-skills/`, installed from the Powers panel via
  *Add Custom Power → Import power from GitHub* against
  `https://github.com/tedeuxx/tadeumendonca-skills/tree/main/powers/tadeumendonca-skills`.

The two do not collide because Kiro resolves a **package root**, not a repository root — its docs state
*"Each power must have a valid `plugin.json` or `POWER.md` file at its package root. A single repository
can contain multiple powers, each in its own directory."* So the repository root remains a Claude Code
plugin and a sibling directory is a Kiro package.

### 2 · Decision drivers

- The owner's ask is compatibility with **both native mechanisms**, not a single artifact both read.
  There is no such artifact: the two manifests share no schema (the Agent Plugins 1.0.0 manifest
  declares `"additionalProperties": false` and has no `skills` key at all), and hiding the seam behind
  an adapter would conceal which half is enforced.
- A **second distribution surface is a distribution decision**, which is why this is an amendment to the
  `plugin-distribution` record rather than a new one.
- The export must be **installable from the repository as it stands**, because Kiro's installer clones a
  ref and reads files. There is no build step it could run.

### 3 · Considered options

1. **Generate the Kiro package into a committed sibling directory, gated by a regeneration diff**
   (chosen). *Trade-off:* generated output in the tree, which is a second copy of every skill and
   therefore a drift risk. Accepted because the risk is fully removed by the gate — `kiro-power.test.sh`
   re-runs the generator into a temp dir and diffs — and because the consumer leaves no alternative.
2. **Hand-maintain a parallel Kiro-shaped tree.** *Why not:* two sources of truth for the same 13
   documents, and the formats are **not** the same, which makes hand-maintenance actively wrong rather
   than merely tedious — measured, **none** of the 13 source files carries the `name:` key Kiro
   validates, and five distinct relative ADR links break at the new depth.
3. **Generate on demand, do not commit.** *Why not:* it is not installable. Kiro fetches files from a
   clone; an artifact that only exists after someone runs a script is an artifact no Kiro user can
   install.
4. **Make the repository root itself the Kiro package** (root `plugin.json` + the existing `skills/`,
   zero duplication). *Why not, and it is the closest call on this list:* it is genuinely elegant — the
   two manifests live at different paths and neither harness reads the other's — but it installs from a
   **bare** repo URL only, puts a second manifest at the root of a repo whose root is already a
   published surface, and leaves nowhere to state the Power's own scope. Rejected on legibility, not on
   mechanics; the mechanics would have worked.

### 4 · Decision outcome

Option 1. `hooks/scripts/kiro-power-build.py` projects `skills/` into the Agent Plugins format —
synthesising the `name` frontmatter key from the directory, rewriting relative links to absolute
`blob/main` URLs, and authoring a Kiro-specific manifest `description` rather than reusing the Claude
Code one, which describes personas and hooks the Power does not ship.
`hooks/scripts/kiro-power.test.sh` gates it in both directions and runs in `hooks-test.yml`.
`.bumpversion.toml` bumps the second manifest in lockstep, so a release cannot leave the Kiro package on
a version that no longer exists.

### 5 · Consequences

**Good**
- A second harness installs this library through its own native path, with no manual copying and no
  intermediate packaging.
- The two trees **cannot** drift: a change to either side reddens the same assertion.
- The projection is where the format differences are stated once and mechanically, instead of thirteen
  times by hand.

**Bad / accepted costs**
- **Only the knowledge layer travels, and that is a CHOICE this amendment takes rather than a limit it
  measured.** `agents/`, `hooks/` and `commands/` are not exported because the enforcement layer is
  Claude-Code-shaped and porting it is work nobody has done. ~~**Whether an installer at or above
  `1.0.288` would carry them is not measured and is claimed in neither direction** — the only installer
  read here belongs to a build predating that format, so it is evidence about a pre-support build and
  is cited only as that.~~ **Struck 2026-08-23 — see the amendment below; it is measured, and the
  answer splits transport from activation.** The decision this bullet records is unchanged: only the
  knowledge layer travels, still by choice. Either way, what a Kiro user installs is the advice without the denies — worth
  naming plainly in a repository whose thesis is *every guarantee is mechanical or it is not real*,
  which is why the README carries the element-by-element gap rather than a footnote.
  *(Scoped 2026-08-21 on `quality-assurance`'s B4, PR #306: the claim was first published attributing
  the limit to a docs page, then to the manifest schema, then — correctly measured but wrongly
  scoped — to a build that cannot install this package. The third failure is the instructive one: a
  real measurement offered as the ground for a claim about a different object.)*
- **Generated output is committed**, which is a shape this repo otherwise avoids. Forced by the
  consumer, not chosen.
- **Nothing here was exercised live.** Every Kiro claim is read from the shipped bundle and the
  published docs; the Kiro install used to measure them has no authenticated session, so no install was
  observed succeeding. **This half of the residual is UNCHANGED at 2026-08-23** — the re-measurement
  below is another bundle reading, not a live install. ~~**The strongest form of this residual:** on
  the build measured (0.12.333, `stable`) the Power installer's copy allow-list is `POWER.md` /
  `mcp.json` / `steering/` and the string `plugin.json` does not occur in the extension bundle at
  all — that build would report a successful install and copy nothing.~~ **Struck 2026-08-23 as the
  build this export is measured against, and KEPT as a finding** — it stays true of `0.12.333` and of
  every build below `1.0.288`; the installed build is now `1.0.337`, where `plugin.json` *does* occur
  and the legacy allow-list is the branch not taken for this package. The export targets the
  **current documented** format on purpose; an older build fails soft rather than loud, and the README
  says so.
- **The measurement ages fast.** Kiro's Power format changed on 2026-08-07. Every claim here is dated
  2026-08-21 and should be re-measured, not re-stamped.

### 6 · What is deliberately NOT decided here

**The direct-copy install into a user's own `.kiro/`** — converting `agents/` to Kiro agent definitions
with `permissions.rules[]`, `commands/` to steering, and shipping a hash-verified copy script — is a
separate decision and is not taken by this amendment. It rests on capability that has **not** been
exercised (no live deny observed), and it turns on a distinction this amendment's own scope does not
need: Kiro's agent `hooks` field can block, and is marked *"CLI only - IDE ignores this field"*, so the
same configuration is an enforcement on one target and inert on the other. Deciding that in the same
record as a skills-only export would put an unverified enforcement claim inside a verified distribution
one.

## Amendment (2026-08-23) — the ground under one accepted cost was re-measured; the decision is unchanged

**Nothing in the decision moves.** The export still carries the knowledge layer and not the enforcement
layer, still by choice, and no option reconsidered here. What changes is the **ground** the 2026-08-21
amendment gave for that cost, which the record's own last bullet asked for in as many words —
*"re-measured, not re-stamped"*. Two clauses above are struck in place rather than rewritten.

**What was re-measured.** The 2026-08-21 reading was taken against Kiro **`0.12.333`**, a build that
predates the Agent Plugins format and therefore could not install this package at all. The installed
build is now **`1.0.337`** (`quality: stable`, bundle built 2026-08-18), which does implement it.

**What the re-measurement says, and it is why the old clause could not simply be updated:** the
question *"would an installer carry `agents/` and `hooks/`?"* has two halves with **opposite** answers,
and the old clause asked it as one. The full derivation, with the bundle symbols it was read from, is
in [`README.md`](../../README.md)'s *"Transport is not activation, and this is the distinction the old
question was missing"* section, cited by heading rather than by line per this repo's citation rule:

- **Transport — yes.** The whole package tree is copied with `.git` as the sole exclusion.
- **Activation — no.** No loader path enumerates or walks `agents/`, `hooks/` or `commands/`.

**Why that strengthens this record's cost rather than softening it.** The accepted cost was *"the
advice without the denies."* It is now worse-shaped than that sentence implied and better-grounded: an
exported enforcement layer would **arrive on disk and never run**, sitting next to skills that do load.
That is this repo's own named failure — *presenting a prompt-level instruction as an enforcement* — so
the omission the 2026-08-21 amendment took as a preference is, at `1.0.337`, a measured reason.

**The live-exercise residual is not discharged and is not claimed to be.** This is a bundle reading.
No Power from this repository has ever been installed; nothing was observed loading, activating or
denying. What would settle it is named in `README.md` and in the generator's own docstring: an
authenticated session, *Powers → Add Custom Power → Import power from local folder*, sentinels planted
in `agents/` and `hooks/`, then read `~/.kiro/powers/` for what arrived and the agent's behaviour for
what activated.

**Significance:** no arm of the significance test fires on this amendment on its own — it records no
new decision, changes no contract and establishes no pattern. It is written because the record was
carrying a **false ground** for a live cost, which the current-codebase rule treats as a defect in a
live record rather than as a new decision. Authored by `agents-lead` per the domain split (#223): the
subject is the harness's own distribution machinery.

## Amendment (2026-09-01) — *«a pin is a lockfile»* is NARROWED: the pin is written by a side effect and never surfaced again

**What moves:** the third section of the 2026-08-10 amendment, *"What makes it affordable is a fact
about today's consumer, not a property of the policy"*. Its clause **`A pin is a lockfile`, so nobody is
carried across a break they did not choose** is narrowed here. **What does NOT move:** the decision this
record holds — the plugin auto-versions on every merge, adoption stays the consumer's opt-in. Nothing in
*Decision outcome* is touched, and no option is reconsidered.

That section explicitly demanded this: *"Any future appeal to this amendment must re-derive the consumer
set rather than cite it."* This amendment discharges that clause, and the re-derivation refutes part of
what was cited.

### What was re-derived, and it is the same file the old clause named

`~/.claude/plugins/installed_plugins.json`, read on 2026-08-31 (#370). It held **three** records for
`tadeumendonca-skills@tadeumendonca`, not one:

| scope | projectPath | version | lastUpdated |
|---|---|---|---|
| project | `…/tadeumendonca-io` | **1.0.16** | 2026-08-14 |
| user | — | 1.1.51 | 2026-08-31 |
| project | `…/tadeumendonca-skills` | 1.1.51 | 2026-08-31 |

~~**Thirty-five versions and seventeen days apart, on one machine, for one consumer.**~~ **Struck the
day it was written: 35 is not a version count, it is `51 − 16` — a subtraction of PATCH components
across a MINOR boundary, which is arithmetic on a string rather than a measurement.** #370's intake
published it, this amendment inherited it, and it survived until someone ran the command:

```
git tag --list 'v*' --sort=v:refname \
  | awk '/^v1\.0\.16$/{f=1;next} /^v1\.1\.51$/{print;f=0} f{print}' | wc -l
→ 69
```

**Sixty-nine published releases and seventeen days apart, on one machine, for one consumer** — twice
the gap the figure claimed, in the direction that makes the argument stronger, which is exactly why it
went unchallenged.

**Two caveats on the replacement, because a corrected figure inherits the obligation the wrong one
failed.** First, the `awk` above **fails open in the inflating direction**: given an upper bound that
does not exist it falls through to EOF and returns a larger number with exit 0 and no error
(substituting `v9.9.9` returns 74). Check that both bounds are real tags before trusting the count.
Second, `69` was confirmed against a **second instrument** — `gh release list --limit 400` over the
same range also gives 69, from a different source than `git tag`, on a repository holding 226 tags and
153 releases overall. That is why the wording is *"published releases"* rather than *"versions"*: the
replacement does not share the old figure's property of being an artifact of how it was computed.

**And the table above is machine-local with no disclosure, unlike the other machine-local figure in
this batch — the asymmetry is named rather than left.** `~/.claude/plugins/installed_plugins.json` is
in no repository; read today it holds all three records at `1.1.53`, so the `1.0.16 / 2026-08-14` row
no longer exists anywhere but a stale directory in the plugin cache. The table is **dated**, which makes
it honest as history and is why it stands — but the 61-programs figure three sections away in
`docs/adr/0004-controls-and-enforcement.md` carries an explicit *"not reproducible from a clone"*
caveat and this one did not. It does now. Kept as a struck line rather than silently corrected, because a wrong number nobody
could re-run is the defect this record is *about*: an install lag nobody could see. The 2026-08-10
amendment had already seen the shape and read it as unremarkable — it records *"`1.0.5`, and `1.0.0` for
one project entry"* in passing, treating the divergence as a detail of the pinning rather than as the
thing worth watching.

### The premise that failed, stated as narrowly as it actually failed

**A pin is a lockfile for a consumer who knows the pin exists and moves it deliberately.** The CLI writes
a per-project record as a **side effect of `install`** and never surfaces it again: nothing prints it at
session start, nothing reports it as drift, and `/plugin marketplace update` moves the shared clone while
leaving every record where it was.

So the protective reading — *nobody is carried across a break they did not choose* — is true in the
letter and inverted in effect. Nobody was carried across the break; **one project was left behind it**,
which the pin argument counted as safety and this record now counts as the cost it actually is. What that
`-io` session ran for seventeen days had no `agents-lead`, no `content-writer`, no `content-reviewer`, no
merge floor (rule 7c) and no milestone rule (rule 10) — five superseded rule-sets, live, with every gate
in this repository green.

### The narrowed clause, in one sentence

**A pin bounds a break; it does not bound a LAG, and only the first was ever argued for here.** The
auto-version-on-merge decision remains licensed by the pin exactly as recorded — a consumer is not
carried anywhere by a merge. What the pin never licensed, and was read as licensing, is the silence: an
un-surfaced pin makes *installed* and *published* diverge without limit, and the divergence is invisible
from both sides.

### What discharges it, and what it deliberately does not do

`hooks/scripts/session-plugin-version.sh` now reads **the running build's own manifest**, derived from
`$0` — `hooks/hooks.json` registers every hook by interpolated absolute path, so `$0` *is* the build in
play — and carries a second arm that reads the registry to report **project-scope records that differ
from the reference**, from whichever session happens to be open. The full reasoning, including the
registry-matching design that was refuted, is in that file's own header.

**This is detection and it is deliberately not prevention.** Nothing here blocks a session on a stale
install, nothing updates a record, and the hook still never blocks anything — a session must always be
able to start. By this loop's own test, *would something stop me, or only my memory?*, a stale install is
still held by nobody; what changed is that it is now **visible from a session that is not the stale one**,
which is the only place it was ever going to be seen.

**Two residuals, named rather than closed.** The primary arm reports from inside the stale session, which
is precisely the session nobody opens. And the cross-project arm is `jq`-gated — on a machine without
`jq` it does not run, and says so inside the notice that already fires there.

### Significance

Arm: **alters a previously-recorded decision.** It narrows a load-bearing ground of the 2026-08-10
amendment — the clause that licensed a PATCH for a break — without touching the decision that ground
supports. No deletion or fold question arises: the record is live, the decision is in force, and the
convention inside a live record is *amend by appending, strike in place, never rewrite*. Authored by
`agents-lead` per the domain split (#223); the subject is the harness's own install machinery.
