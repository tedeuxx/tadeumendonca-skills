# 0009. A skill's `description` is a **trigger**, not a title — the canonical form every skill is written to, and an enforcement boundary that refuses a quality score

- **Status:** accepted
- **Date:** 2026-08-09
- **Deciders:** the owner (the standard is his, posted as [#166's closing comment](https://github.com/tedeuxx/tadeumendonca-skills/issues/166#issuecomment-5232005136) and ratified by labelling the Issue `ready`); drafted by `harness-reviewer`; recorded by `tech-lead`
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
length bounds, the literal `Use when`, the frontmatter-scoped consumer-path ban, no `(concept)`, no
description opening with its own stem, `argument-hint` on the two typed commands and nowhere else,
cluster symmetry, and every `(see X)` resolving to a file. **Refused: any quality score**, per option 3.

## The plain-path deviation — recorded as a live tension, not resolved

The implementation writes rivals as **`see backend/metrics`**, a plain `family/stem` path, rather than
as the backticked bare stem `` see `metrics` `` that the standard's own worked examples use. Bare stems
appear only where the file has no family, which at this head is exactly the two top-level commands
(`autonomy-on`, `new-issue`). **This is a deviation from the standard's own constraint 7, and it is
upheld — for a reason stronger than the one the builder gave.**

The builder's reasons were that constraint 7 (*no markdown*) contradicts the three worked examples that
use backticks, and that a bare stem is ambiguous. Both hold. **The decisive reason is a third one, and
it belongs to the gate:** the plain-path form makes a pointer **machine-resolvable**.

**Re-derived at `596481e` rather than relayed** (`.scratch/verify-pointers.py`, discarded after use):
**112** `(see X)` pointers across the 75 descriptions, resolving to files with **zero dangling**; and
**four stems occur in two families each** — `cloudwatch-rum`, `coverage`, `dynamodb`,
`environment-config`. Under bare stems that resolution check **could not exist** for those four, and the
ambiguity falls exactly where disambiguation is the job: the two `cloudwatch-rum` files sit on
**opposite sides of their own cluster's separating axis** (browser client versus Terraform
provisioning), so a bare pointer would name both and separate neither.

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
- **The pointers embed folder paths**, and #164 can invalidate 112 of them in one merge.
- **Four descriptions are already known to be superseded** — one from each of the `dynamodb`,
  `coverage`, `cloudwatch-rum` and `environment-config` pairs — the day #164's merges land, and each
  merged file will need a **third** description, written to this same standard, covering both sides of
  its axis.
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
  [#167](https://github.com/tedeuxx/tadeumendonca-skills/issues/167) (consumer paths in **bodies**; the
  ban recorded here is frontmatter-scoped, which is what kept this slice one slice).
- Related: [ADR-0008](./0008-which-layer-carries-a-control.md) for *a check that is wrong more often
  than right trains the loop to silence it*, which is the reason option 3 is refused rather than
  deferred; and [ADR-0003](./0003-mr-definition-of-done.md), whose *decision recorded* criterion is what
  made this record's absence a blocking finding.
- **Evidence re-derived at `596481e`, not relayed:** `git grep -c "^description:" 593886b~1 -- commands/`
  → two files, against 75 today, for the 73-with-no-frontmatter figure; and a scan of the 75
  frontmatter blocks for the **112** pointers, **zero** dangling, and the **four** duplicated stems
  (`cloudwatch-rum`, `coverage`, `dynamodb`, `environment-config`).
