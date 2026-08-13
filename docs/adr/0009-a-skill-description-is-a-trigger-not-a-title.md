# 0009. A skill's `description` is a **trigger**, not a title — the canonical form every skill is written to, and an enforcement boundary that refuses a quality score

- **Status:** accepted
- **Date:** 2026-08-09
- **Deciders:** the owner (the standard is his, posted as [#166's closing comment](https://github.com/tedeuxx/tadeumendonca-skills/issues/166#issuecomment-5232005136) and ratified by labelling the Issue `ready`); drafted by `harness-lead`; recorded by `tech-lead`
- **Supersedes / superseded by:** —
- **Driven by:** [#166](https://github.com/tedeuxx/tadeumendonca-skills/issues/166) and its implementation [PR #168](https://github.com/tedeuxx/tadeumendonca-skills/pull/168), where `quality-assurance` blocked on the absence of this record (finding **B2**) and the builder conceded rather than argued

## Context & problem

The platform **merged commands and skills into one system**. The 75 files under `commands/` are already
skills, and a skill is loaded two ways: a human types its name, or a model matches it. **The model
matches on the `description` frontmatter field** — and, per the measurement reported on #166, a skill
with no description **does not appear in the discoverable listing at all**: it is reachable only by
explicit name.

That is the world this library was authored for. In June a human typed the name, so the first line of
each file was written as a **title** — *"Frontend routing in `<project>` (concept)."* — which answers
*"what is this?"*. A matcher needs the answer to a different question: **"I am doing this — are you
it?"**

**Measured against the tree rather than relayed:** at `593886b~1`, exactly **2 of 75** files under
`commands/` carried a `description:` line (`autonomy-on`, `new-issue`); the other **73 had no
frontmatter at all**. So for 73 of 75 skills, the model-invoked half of the loading contract was not
merely weak — it did not exist.

**The second problem is where the answer lives.** #166 closed with a complete standard, and that
standard is the ruler for all 75 descriptions **and for every skill added from now on**. It lives in a
comment on a closed Issue. This repo has already booked that failure under its own name — *a comment
cannot hold a control* — and the concrete exposure is that the next author adding a skill has **no path
from the repo to the standard**. Checked before writing this: `docs/adr/` holds 0001–0008 and **none of
them covers the description field, the trigger form, or the cluster rule.**

## Decision drivers

- **The field has two readers with opposite needs, and only one of them was served.** A title serves the
  reader who already chose; a trigger serves the matcher that has not. The field is the matcher's.
- **This binds every skill added from now on.** That is the *cross-cutting pattern* arm of the
  significance test in `/workflow/adr`, and it is why a record is owed rather than a "no ADR" line.
- **A description must survive the tree.** [#164](https://github.com/tedeuxx/tadeumendonca-skills/issues/164)
  may flatten or merge families; a description that depends on its folder to convey its layer breaks
  silently when it moves.
- **Disambiguation is a property of the set, not of the file.** Six clusters compete on overlapping
  subjects; no per-file rule can make a member distinguishable from its neighbours.
- **An enforcement mechanism that is wrong more often than right gets silenced.** This library has
  already recorded that cost once, for a hook that guessed intent from a command string
  ([ADR-0008](./0008-which-layer-carries-a-control.md)). Any check proposed here inherits it.

## Considered options

1. **Trigger-form descriptions on all 75, enforced mechanically only where a check cannot be wrong**
   *(chosen)* — a canonical sentence shape with a mandatory `Use when`, a cluster-scoped
   `Not for … (see X)`, and assertions covering presence, parse, bounds and set symmetry.
   *Trade-off:* 75 hand-authored 300–500 character sentences, an **authorial half that no gate covers**,
   and four descriptions that are superseded the day the #164 family merges happen.

2. **Reuse the existing first line as the description** — zero authoring, one generator change.
   *Why not:* those first lines are the defect. They are titles, measured as such across all 75, and
   they answer the question the matcher does not ask. The two objects are also mechanically different
   sizes: the README's generated inventory column is capped at 150 characters, and the descriptions this
   standard produces measure **305–485**, so every one would be cut mid-clause. A field that is both the
   table cell and the matcher's input serves neither.

3. **Score description quality** — keyword count, noun density, embedding similarity between the
   description and the body. This is the only option that would put a mechanism on the *authorial* half,
   which is the half that actually decides whether the field works.
   *Why not, and it is refused by name so nobody rebuilds it:* **all three pass on keyword salad**, which
   is the exact betrayal this standard exists to prevent. A description stuffed with body nouns and
   naming no situation scores well on every one of them. Buying a green that is achievable by the failure
   mode is worse than having no check, because it converts an open question into a reported answer.

4. **Defer the four duplicated families until #164 decides** — write 71 now, and the four pairs after the
   merges. *Why not:* the merged file needs a **third** description covering both sides of its axis,
   which is written during the merge regardless — so deferring saves nothing and blocks the other 71.
   Four sentences discarded later is the cheaper cost, and each side declaring what it is for is exactly
   the material that makes those merges judgeable.

## Decision outcome

Chosen: **option 1.** The standard in #166's closing comment is adopted whole and is reproduced here in
the form a future author needs — this record, not the Issue comment, is now the ruler.

**The canonical form:**

    <ACT> <CONCRETE OBJECT> <WHERE, in nouns rather than folders>.
    Use when <situation 1>, <situation 2>, or <situation 3>.
    Not for <neighbouring situation> (see <rival>)[, or <another> (see <rival2>)].

The constraints that make two authors converge, with the reason each exists:

| # | rule | why |
|---|---|---|
| 1 | Open on **act + object**, never the filename | the first tokens are the discriminating ones |
| 2 | **The layer lives in the nouns, never the folder** — *"in a React SPA"*, *"in server handler code"*, *"in Terraform"* | the folder disappears when the tree flattens; the description must survive that alone |
| 3 | **Technology proper nouns come from the body** | every token is then checkable against the file — this is what stops keyword salad |
| 4 | **`Use when` is mandatory**, 2–3 situations in task language | the clause that converts a title into a trigger, and **the only one that cannot be satisfied by accident** |
| 5 | **`Not for … (see X)` is mandatory** for any file in a cluster | disambiguation is a property of the set |
| 6 | **Generic placeholders** — never a real consumer path | the repo's hard project-agnostic rule, now on a published surface |
| 7 | **One physical line, no unquoted `:`, no markdown, no `$ARGUMENTS`** | a description that is not one line is read whole by YAML and half by every check |

**The cluster rule.** Six clusters compete on overlapping subjects — observability (8), config and
secrets (5), gates (5), data (4), auth (4), delivery (5). **Every member names its separating axis in
its own description and names at least one rival by name**, and the naming must be **mutual**. Three
axes cover the whole library: **use vs provision · which surface · decide vs implement vs verify.**

**The enforcement boundary, which is deliberately partial and is the second half of this decision.**
Gated: frontmatter presence and parse, `description` present and non-empty, **one physical line**,
length bounds, the literal `Use when`, ~~the frontmatter-scoped consumer-path ban~~ **the consumer-path
ban — whole-file since [PR #169](https://github.com/tedeuxx/tadeumendonca-skills/pull/169), and its own
block rather than part of this list's L2; see the amendment of 2026-08-09 below**, no `(concept)`, no
description opening with its own stem, `argument-hint` on the two typed commands and nowhere else,
cluster symmetry, and every `(see X)` resolving to a file. **Refused: any quality score**, per option 3.

*The struck scope was chosen, not defaulted to, and the amendment keeps the reason it was chosen. What
changed is that its precondition was discharged — the widening is strictly wider, so nothing this
sentence gated when it was written is ungated now.*

## The plain-path deviation — recorded as a live tension, not resolved

The implementation writes rivals as **`see backend/metrics`**, a plain `family/stem` path, rather than
as the backticked bare stem `` see `metrics` `` that the standard's own worked examples use. Bare stems
appear only where the file has no family, which at this head is exactly the two top-level commands
(`autonomy-on`, `new-issue`). **This is a deviation from the standard's own constraint 7, and it is
upheld — for a reason stronger than the one the builder gave.**

The builder's reasons were that constraint 7 (*no markdown*) contradicts the three worked examples that
use backticks, and that a bare stem is ambiguous. Both hold. **The decisive reason is a third one, and
it belongs to the gate:** the plain-path form makes a pointer **machine-resolvable**.

~~**Re-derived at `596481e` rather than relayed** (`.scratch/verify-pointers.py`, discarded after use):
**112** `(see X)` pointers across the 75 descriptions, resolving to files with **zero dangling**; and
**four stems occur in two families each** — `cloudwatch-rum`, `coverage`, `dynamodb`,
`environment-config`. Under bare stems that resolution check **could not exist** for those four, and the
ambiguity falls exactly where disambiguation is the job: the two `cloudwatch-rum` files sit on
**opposite sides of their own cluster's separating axis** (browser client versus Terraform
provisioning), so a bare pointer would name both and separate neither.~~

**Struck 2026-08-09 — the measurement is false at this head, and it was the decisive argument.** [PR
#174](https://github.com/tedeuxx/tadeumendonca-skills/pull/174) merged all four pairs, so **zero stems
occur in two families**. The paragraph is kept because it is the reason the form was chosen and a reader
who applies it today would be applying a reason that has expired. **The form itself is unchanged and the
decision stands** — see the second amendment of 2026-08-09 below for what now holds it up, and what does
not.

**The cost this buys, stated because it points the other way:** `backend/metrics` **embeds a folder
path in the description**, which is precisely what constraint 2 warns against. Today that is free. **If
the tree flattens under #164, 112 pointers rot at once.**

> **This record does not resolve that tension and must not.** #164 is undecided, and a record that
> pre-empted it would be deciding the tree's shape as a side effect of deciding a sentence's
> punctuation — the failure ADR-0008 exists to name. What is decided here is the **form as it stands**
> and the fact that its cost is **known and dated**. Whichever way #164 goes, this section is
> **amended**, not rewritten: a flattening MR owes an amendment here, and it is cheap only if it is
> written at the time.

## The half no assertion covers, and the instrument that has never been run

Named explicitly so nobody builds a metric out of it, and so nobody reads the green as coverage it does
not have. **Irreducibly authorial:**

- whether the situation named is the **right** one,
- whether the technology nouns are the ones a **real task** would contain,
- whether `not for` points at the **nearest** rival rather than the most convenient one,
- whether the description is **true about the body**.

**The standard's own instrument for this is not an assertion — it is a dispatch:** roughly ten real task
sentences run against the library, to see which skill each one matches. Measurable, repeatable, and the
owner's rather than a gate's.

> **It has never been run.** Stated plainly, because it is also the only thing that would confirm the
> premise the whole slice rests on — **that model-invoked loading matches on `description`**, and that a
> description written this way is the one that fires. That premise is **unverified anywhere in this
> repo**, and both `quality-assurance` and the builder said so on #168. Nothing here converts it.
> **An unverified premise recorded as verified is the exact defect this library is about**, and this
> paragraph is the record refusing to commit it about itself.

The sampling that *was* done bounds the claim rather than establishing it: 12 files across all five
families, roughly 40 asserted technology nouns grepped against the body each describes, none invented.
That shows the descriptions were written **from** the bodies rather than **about** the filenames. It
does not show that any of them matches a task.

## Consequences

**Good**

- **The ruler has a home in the repo.** The next author adding a skill reads this file, not a comment on
  a closed Issue, and `/workflow/adr`'s significance test has a worked precedent for a cross-cutting
  pattern that is a *writing* standard rather than a *system* one.
- **The mechanical half exists and was proven by mutation**, not by reading — the recurring defect in
  this workspace is an assertion that cannot fail, and #168 broke the source in twenty-three places to
  find out.
- **The `(see X)` graph is checkable**, which is a property the chosen spelling created and the
  alternative would have foreclosed.

**Bad / accepted costs**

- **The premise is unverified**, per the section above. Every benefit claimed for this standard is
  conditional on it.
- **The authorial half has no gate and never will**, because the only mechanisms available for it pass
  on the failure they exist to catch.
- **The cluster table is hand-maintained and cannot catch an ADDITION.** A new file dropped into a
  cluster nobody adds to the table stays uncovered. Deletion and rename go red; addition is uncovered
  **on purpose**, since deriving cluster membership from paths would be the refused quality score in
  another shape.
- **The pointers embed folder paths**, and #164 can invalidate ~~112~~ **98** of them in one merge.
  *(The count moved with the merges — PR #174; the exposure did not.)*
- ~~**Four descriptions are already known to be superseded** — one from each of the `dynamodb`,
  `coverage`, `cloudwatch-rum` and `environment-config` pairs — the day #164's merges land, and each
  merged file will need a **third** description, written to this same standard, covering both sides of
  its axis.~~ **Discharged 2026-08-09 by PR #174** — the four third descriptions exist and are named in
  the second amendment below. The bullet is struck because the cost was *paid*, not because it was
  wrong.
- **The gate's runtime grew**, and the cost is uneven: roughly a minute on macOS from process-spawn
  cost, about eight seconds on the CI runner where the gate actually decides anything.

## Links

- Driving Issue [#166](https://github.com/tedeuxx/tadeumendonca-skills/issues/166) and its closing
  comment, which is the standard this record adopts and replaces as the durable location · implemented
  in [PR #168](https://github.com/tedeuxx/tadeumendonca-skills/pull/168), where finding **B2** is the
  obligation this file discharges.
- Open and deliberately **not** pre-empted:
  [#164](https://github.com/tedeuxx/tadeumendonca-skills/issues/164) (family merges / tree shape — the
  plain-path tension above) and
  ~~[#167](https://github.com/tedeuxx/tadeumendonca-skills/issues/167) (consumer paths in **bodies**; the
  ban recorded here is frontmatter-scoped, which is what kept this slice one slice).~~ **Struck
  2026-08-09 — #167 is no longer deferred.** It is implemented by
  [PR #169](https://github.com/tedeuxx/tadeumendonca-skills/pull/169), open at the time of writing, which
  cleaned the bodies and widened the ban to the whole file. The sentence was true when written and the
  scoping reasoning is preserved in the amendment below rather than deleted, because a scope
  deliberately chosen and later discharged is a different thing from a scope that was always this.
  **#164 remains open and remains deliberately not pre-empted.**
- Related: [ADR-0008](./0008-which-layer-carries-a-control.md) for *a check that is wrong more often
  than right trains the loop to silence it*, which is the reason option 3 is refused rather than
  deferred; and [ADR-0003](./0003-mr-definition-of-done.md), whose *decision recorded* criterion is what
  made this record's absence a blocking finding.
- **Evidence re-derived at `596481e`, not relayed:** `git grep -c "^description:" 593886b~1 -- commands/`
  → two files, against 75 today, for the 73-with-no-frontmatter figure; and a scan of the 75
  frontmatter blocks for the **112** pointers, **zero** dangling, and the **four** duplicated stems
  (`cloudwatch-rum`, `coverage`, `dynamodb`, `environment-config`).

## Amendment (2026-08-09) — the consumer-path ban is now whole-file; the scope this record chose was discharged, not wrong

Everything above stands as the decision. **Two of its sentences are stale** — the enforcement list in
**Decision outcome** and the #167 bullet in **Links** — and both are struck in place rather than
rewritten. What changed is not the reasoning; it is the reasoning's precondition.

### 1 · Why the ban was frontmatter-scoped, which is the half worth keeping

[PR #168](https://github.com/tedeuxx/tadeumendonca-skills/pull/168) gated the consumer-path ban on the
`description` field only. That was a **sequencing decision taken in the standard**, not an oversight in
the check: the bodies were dirty, and a file-wide assertion would have turned the suite red against work
nobody had scheduled — one slice becoming five, and a gate arriving already failing. This library has
already recorded what an enforcement mechanism that cannot be satisfied costs
([ADR-0008](./0008-which-layer-carries-a-control.md)): it gets silenced, and a silenced check still
looks like coverage. So the scope was drawn where the check could be **green and honest on the same
day**.

**Re-derived at `485b97e` (this record's merge base) rather than relayed:**

    git grep -nIoE 'apps/(fed|bff)|tadeumendonca(\.[A-Za-z]+|-[A-Za-z]+)?' 485b97e -- commands/ \
      | grep -vE ':tadeumendonca-skills$'

→ **80 occurrences on 73 lines across 45 files.** Broken down: `apps/bff` 45, `apps/fed` 26,
`tadeumendonca.io` 4, `tadeumendonca-io` 3, `tadeumendonca-version` 1, bare `tadeumendonca` 1. The
**43 files** figure carried in the check's own comment and in #167's title is the `apps/…` subset alone;
both numbers are true, of different sets, and the difference is the six files whose only leak was a
`tadeumendonca…` token. *(#169's description reports 72 occurrences. The file count reproduces exactly;
the occurrence count does not, and the command above is the one this record stands behind rather than
the prose it was relayed from.)*

### 2 · What discharged it

PR #169, implementing [#167](https://github.com/tedeuxx/tadeumendonca-skills/issues/167), cleaned the
bodies to **zero by the same command at branch head**, and widened the assertion from the frontmatter to
the whole file. The widening is **mutation-proven, not read**: a consumer path injected at
`commands/frontend/state.md:28` — a body line the frontmatter-scoped check structurally could not see —
fails red naming file and line, and the negative control (`tadeumendonca-skills`, three live
occurrences) stays green. That matters here because the recurring defect this repo keeps finding is an
assertion that cannot fail, and a *widened* assertion is exactly where that defect hides.

**The distinction that decided the judgement calls, recorded because it is the one a future author will
have to make again.** Of the nine `tadeumendonca…` occurrences that were not `-skills`, **seven** were
`tadeumendonca-io` (3) or `tadeumendonca.io` (4) — one consumer's repo and one consumer's domain — and
they go. **`tadeumendonca-skills` stays**, because it is the plugin **naming its own invocation
surface**: `/tadeumendonca-skills:infrastructure/vpc` is what every consumer types, identically, and
scrubbing it would make the install and invocation instructions wrong. That is why the allowance is
spelled as an **exact token rather than a prefix** — `tadeumendonca-<anything-else>` is a leak until
someone argues otherwise, in an MR, on the record. The remaining two occurrences are consumer facts as
well and also went: the PAT name `tadeumendonca-version-bump`, and the bare `tadeumendonca` used as an
example Terraform `project` value.

### 3 · The gate as it now stands, so the enumerated list above stays true rather than generous

- The consumer-path check has **moved out of L2 into its own block**. The rest of L2 stays
  description-scoped, because *"is this a trigger and not a title"* is a question about the description
  only.
- Its scan set is **`commands/**/*.md` and nothing else** — `agents/`, the README and these ADRs
  describe *this* repo and are entitled to name it; the skills are the artefact that travels.
- Its match is **tokenised rather than substring**, so a genuine leak cannot hide on a line that also
  carries a legitimate self-reference, and trailing punctuation cannot turn an allowed token into a
  false failure.
- An **empty scan set fails loudly** rather than passing.
- The widening is **strictly wider**: the frontmatter is part of the file, so nothing this record gated
  when it was written is ungated now.

### 4 · A bound on that claim, because the widened gate reads stronger than it is

Project-agnosticism is now mechanised for **literal** consumer identifiers only. Measured at branch
head, `git grep -lE '<project>-(pwa|iac)' -- commands/` returns **11 files**, of which three carry
`<project>-pwa` (`infrastructure/elasticache`, `infrastructure/terraform`, `infrastructure/waf`). Those
pass the check **correctly** — they name nothing that exists in exactly one project — and they
nevertheless assert **one specific two-repo topology** (a monorepo `<project>-pwa/iac` beside a separate
shared `<project>-iac`) as though it were the pattern, which is the same failure #167 names, wearing a
placeholder.

**Ruled out of scope for this record and out of scope for #167, deliberately.** Not this record's,
because its subject is the `description` field and **zero** of those 11 occurrences are in a
description — every one is in a first body line or below (measured, not assumed). Not #167's, because
#167's question is *literal identifiers*, and widening its vocabulary mid-slice to cover a placeholder
would be answering a different question under a closed one's name. It is a **content** question — what a
deliberately-retained reference-pattern skill may assume about repo layout — it sits beside
[#164](https://github.com/tedeuxx/tadeumendonca-skills/issues/164), and it is the owner's to open or
not. Named here so a later reader does not mistake a green consumer-path check for the whole of the
project-agnostic rule.

### 5 · A cost this record did not carry, and option 2 is where it came from

Rejecting *"reuse the existing first line as the description"* (**Considered options**, option 2) was
right for the reason given, and it left a consequence the record did not book: **every skill now has two
independently authored descriptions** — the `description` field, and the **first body line**, which
`hooks/scripts/skills-table.py` publishes as **column 2 of the README's skill table**. They can drift
from each other and from the body, and nothing reconciles them.

#169 edited body first lines and therefore changed published README rows. It regenerated with the
committed generator, and that is verified rather than trusted: every row emitted by `skills-table.py` at
branch head appears verbatim in `README.md` (73 rows, `grep -Fxv -f README.md` over the generator's
output returns nothing). **The table is correct today.**

**What has no guard is that it stays correct.** `hooks/scripts/inventory-counts.test.sh` asserts the
table in both directions — every skill file has a row, every row names a skill file — but **keys on
cells 1 and 3 only** (skill, family), which the generator's own docstring states. So the description
cell is unasserted. **Mutation-proven, not inferred:** replacing the `vpc` row's cell 2 with
`TOTALLY WRONG DESCRIPTION THAT IS NOT THE FIRST BODY LINE` leaves the suite at **62 passed, 0 failed**,
both table assertions green. A fabricated published description passes.

**Recorded as a cost, not as a decision.** Closing it is a routine assertion — regenerate and diff the
table, which also subsumes both existing directions — and it is below `/workflow/adr`'s significance
bar: no public contract, no fixed decision altered, no new dependency, no cross-cutting pattern. Folding
it in as a decision would put a **second decision** in a record whose entire subject is one field, and
one decision per ADR is the rule this library does not bend. It belongs here only as the consequence of
option 2 that this record failed to name, and it is the same class as the three defects #168 found
inside itself: **a green that was never observed to go red is not a gate.**

**Links added by this amendment**

- [PR #169](https://github.com/tedeuxx/tadeumendonca-skills/pull/169), implementing
  [#167](https://github.com/tedeuxx/tadeumendonca-skills/issues/167) — the bodies cleaned and the ban
  widened. The *"frontmatter-scoped"* wording in **Decision outcome** and in **Links** above is
  superseded by this amendment.
- **Narrows no claim in [ADR-0008](./0008-which-layer-carries-a-control.md)** and leans on it twice: for
  *why the original scope was narrow* (§1) and for the standing refusal to call a pattern-matching
  control *closed* — §3 states what the widened check scans and how it matches, not that consumer
  leakage is now impossible.
- **Evidence re-derived on this branch, not relayed:** the `485b97e` grep in §1; the same grep returning
  zero at branch head; `git grep -lE '<project>-(pwa|iac)'` → 11 files in §4; and the README cell-2
  mutation in §5, run against `hooks/scripts/inventory-counts.test.sh` with the tree otherwise clean and
  reverted afterwards.

## Amendment (2026-08-09, second) — the four family merges discharge one booked cost and dissolve the decisive argument for the plain-path form

**The decision is unchanged.** The canonical form, the seven constraints, the cluster rule, the refusal
of a quality score and the enforcement boundary all stand exactly as written. What this amendment
records is that **two of this record's load-bearing measurements are now false**, that **one booked cost
has been paid**, and that **the reason the plain-path deviation was upheld no longer exists** — while
the deviation itself does.

[PR #174](https://github.com/tedeuxx/tadeumendonca-skills/pull/174), step 1 of
[#164](https://github.com/tedeuxx/tadeumendonca-skills/issues/164), merged the four cross-family pairs
into one file each: `dynamodb` and `cloudwatch-rum` into `infrastructure/`, `coverage` and
`environment-config` into `backend/`.

### 1 · What is now false, measured at `78f4e5b` rather than relayed

    git ls-tree -r --name-only <ref> commands/ | sed 's#.*/##' | sort | uniq -d
      origin/main -> cloudwatch-rum.md coverage.md dynamodb.md environment-config.md   (4)
      78f4e5b     -> (nothing)                                                          (0)

    git grep -h '^description:' <ref> -- commands/ \
      | grep -oE '\(see [^)]*\)' | tr ',' '\n' | grep -coE '[a-z-]+/[a-z0-9-]+'
      origin/main -> 110
      78f4e5b     -> 98

**Two figures rather than one, on purpose.** This record states **112** pointers, derived on #168 by
`.scratch/verify-pointers.py`, which was discarded after use. The command above — the only instrument
that still exists — returns **110** on the same tree. The difference is two pointers and its cause is
not recoverable, because the original instrument is gone. **The 112 is not corrected to 110**; both are
recorded, with the command that produced the survivor, so the next reader re-derives rather than
inherits. That a discarded instrument leaves an unverifiable number behind is a real cost of this
repo's *discard the scratch* rule, and it is worth naming once.

The **cluster table** moved with the tree: **31 members → 27**, four clusters each losing their
duplicate (`observability`, `config-and-secrets`, `gates`, `data`).

### 2 · The plain-path deviation stands, and its decisive argument does not

The section above upheld `see backend/metrics` over the backticked bare stem on one argument the record
called **decisive**: four stems were ambiguous under bare stems, so the `(see X)` resolution check
*could not exist* for them. **That argument is gone.** All 71 stems are unique at this head, so a bare
stem resolves as deterministically as a path.

**The deviation is nevertheless upheld, on the two reasons this record called weaker and the builder
gave first:** constraint 7 forbids markdown, so the backticked spelling contradicts the standard's own
rule; and the plain path is what the 98 live pointers are written in, so changing the spelling now is 98
edits buying nothing today.

**And the tension this record refused to resolve has inverted, which is the part a flattening MR needs.**
When this was written, the folder path was the *cheap* spelling and flattening was the threat. Now the
bare stem is **available** — it was not before — and it is the spelling that survives a flat tree
unchanged. So the choice #164 step 3 faces is no longer *rot 98 pointers or keep an ambiguity*; it is
**a mechanical, deterministic rewrite of 98 pointers from `family/stem` to `stem`**, which is what
#164's own closing comment concluded from the owner's merge ruling.

> **Still not resolved here, and still deliberately.** This amendment records that the option set
> changed; it does not pick from it. Step 3 has not been decided, and a record that pre-empted it would
> be deciding the tree's shape as a side effect of a sentence's punctuation — the same refusal as
> before, for the same reason.

### 3 · The booked cost is paid, and paying it exposed something about the cluster rule

The **Bad / accepted costs** bullet promising four superseded descriptions and four *third* descriptions
is discharged. The four exist, each written to this standard, each passing the mechanical gate
(presence, one line, bounds, `Use when`, resolving `(see X)`, cluster reciprocity): `backend/coverage`,
`backend/environment-config`, `infrastructure/dynamodb`, `infrastructure/cloudwatch-rum`.

**What was not foreseen, and it is a real bound on the cluster rule rather than a defect in it:** all
four merged files now **span the very axis their cluster uses to separate members**, and two of the
three axes are affected.

| merged skill | cluster | the axis it now spans | how the description says so |
|---|---|---|---|
| `infrastructure/dynamodb` | data | **use vs provision** | *"Provision and use DynamoDB end to end"* |
| `infrastructure/cloudwatch-rum` | observability | **use vs provision** | *"Provision and instrument … the Terraform app monitor … the browser client"* |
| `backend/environment-config` | config-and-secrets | **which surface** | server runtime **and** build-time browser bundle |
| `backend/coverage` | gates | **which surface** | *"for both stacks"* |

This is not incidental. **The families WERE the axis** — the pairs existed in two families precisely
because each concept had a provisioning half and a using half, or a server half and a browser half.
Merging them is the owner's ruling, and it necessarily produces members that straddle.

**The rule survives it, narrowly.** Each of the four still names a rival in its own cluster and the
naming is still mutual, so the gate is green and honest. What is weaker is the *third* axis of
separation for those four: a matcher deciding between `infrastructure/dynamodb` and
`infrastructure/elasticache` can no longer be helped by *provision or use*, only by *which datastore*.
**Booked as an accepted cost, not a decision** — no rule changes, and inventing an axis to restore the
separation would be authoring a taxonomy to fit a check, which is the shape option 3 was refused for.
It gets broader, predictably, at step 3: a flat tree removes the folder as a hint for **every** skill,
which is the situation constraint 2 was written for.

### 4 · What is deliberately NOT recorded, here or anywhere — the family-choice rule

PR #174 invented a rule to decide which family keeps each merged file: **the family whose charter covers
the merged scope; on a tie, the side with more inbound references.** It killed four published invocation
names (`/backend/dynamodb`, `/frontend/cloudwatch-rum`, `/frontend/coverage`,
`/frontend/environment-config`). **The ruling is *no ADR*, and it is stated rather than left silent**,
because a published cost with no record is the shape the significance gate exists for and a reader is
owed the reason it did not fire.

`/workflow/adr`'s five arms, applied:

- **`iac/`** — not touched.
- **A public contract changes** — **yes, and it is already recorded.** The invocation surface is the
  contract, and the four deaths are *entailed* by the owner's ruling *merge the overlapping pairs rather
  than rename them apart*. Merging two files necessarily kills one of two names; the rule chose **which**
  one, not **whether**. The decision, its MAJOR, and the sequencing that cuts it are in #164.
- **A fixed decision is altered** — **yes, this record**, which is why this amendment exists rather than
  a new ADR.
- **A new dependency or tool-class** — none.
- **A cross-cutting pattern others will follow** — **no, and this is the arm that decides it.** The rule
  governs a taxonomy that #164 step 3 abolishes. It was applied four times, to four files, and there is
  no future case for it to bind. A record that outlives its subject trains readers to skim the library,
  which is the cost `/workflow/adr` names for an ADR written for a routine change.

**The weakest link is `coverage`**, where neither charter fit and `workflow/` was rejected because
re-homing into a third family was not authorised. That rejection is the correct move — deferring a
taxonomy decision to the owner rather than taking it inside an implementation slice — and it is exactly
why the rule is not a decision worth a record: it is the *absence* of one, held for three steps.

### Links added by this amendment

- [PR #174](https://github.com/tedeuxx/tadeumendonca-skills/pull/174), step 1 of
  [#164](https://github.com/tedeuxx/tadeumendonca-skills/issues/164) — the four merges. The
  *"four stems occur in two families each"* paragraph and the four-superseded-descriptions bullet above
  are superseded by this amendment.
- **#164 remains open** and steps 2–6 remain deliberately not pre-empted, per the refusal in §2.
- Related: [ADR-0008](./0008-which-layer-carries-a-control.md) for *a measurement to re-derive rather
  than a verdict to read*, which is why §1 ships the command and both figures instead of one corrected
  number.
- **Evidence re-derived at `78f4e5b`, not relayed:** the two commands in §1, each run against
  `origin/main` and the branch head; the cluster-member counts by extracting the `CLUSTERS` table from
  `hooks/scripts/inventory-counts.test.sh` on both refs (31 and 27); and the four descriptions in §3
  read from the tree rather than from the PR description.
