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
  [ADR-0001]-era decisions; the trigger, not the scheme, is what this changes.

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
