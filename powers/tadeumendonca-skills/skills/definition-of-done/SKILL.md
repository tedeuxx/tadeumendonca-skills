---
name: definition-of-done
description: Design or evaluate a Definition of Done — the criteria a slice, release or project calls finished. Use when building a DoD from scratch, choosing its shape (fixed checklist, per-item-type criteria, automated gate), or diagnosing why review still reads as subjective. Not for this loop's own concrete DoD and gate thresholds (see quality-gates), or a work item's readiness to be built (see definition-of-ready).
---

# Definition of Done — the ruler that decides when work stops

Apply this SDLC-generic concept in any `<project>` — it defines what makes a Definition of Done a real
mechanism rather than a phrase, independent of which loop, tracker or team runs it. `/definition-of-ready`
and this skill are the two ends of the same lifecycle: **ready** is the entry gate to building, **done**
is the exit gate out of it. Neither substitutes for the other, and a project that only builds one of them
fails at the end it left open — a strong DoD cannot rescue a story that was ambiguous when the builder
started (see *Ready is a precondition of done*, below), and a strong Definition of Ready does not verify
what was actually shipped.

Context: $ARGUMENTS

## Why a Definition of Done is a mechanism, not a phrase

**"Done" is a claim, and a claim needs a ruler or it is just an assertion.** Without one, "done" is
decided by whoever is reviewing, on however much they happened to notice that day — which is a different
bar every time, set by mood and attention rather than by anything the team agreed. A DoD exists to move
that decision from a person's impression to a checkable list: an item either satisfies each stated
criterion or it does not, and the criteria were agreed **before** the work started, not invented while
reading the diff.

That is the whole mechanism, and it is worth stating plainly because it is easy to build a DoD that looks
like this and is not one — see *Failure modes*, below, for the three shapes that fail while still calling
themselves a Definition of Done.

## Designing a DoD from scratch

**The central mistake is starting from the wrong source.** The instinct is to reach for a generic,
industry-standard checklist — or worse, to inherit whatever a previous team or a corporate template
already had — and adopt it wholesale. That checklist was written against a different project's actual
surfaces, and a criterion is only meaningful against what a *specific* project actually delivers. Design
starts from the project's own purpose, not from a template that precedes it — see *My take*, below, for
this stated as the owner's own diagnosis of the failure, in his words.

**The concrete process, once the source is right:**

1. **Read what the project actually produces.** A service with no UI has no screen to certify as
   finished; a library with no runtime has no deploy smoke to run. A criterion naming a surface the
   project does not have is not a stricter bar — it is an unsatisfiable one, and an unsatisfiable
   criterion teaches the team to rubber-stamp it or skip it quietly. This is the same discipline
   `/definition-of-ready` applies on the other end of the lifecycle, and for the same reason.
2. **Ask, for each candidate criterion: is it objective, falsifiable and evidence-producing?** See
   *What makes a criterion well-formed*, below — this is the test that separates a real gate from a
   phrase that sounds like one.
3. **Ask who checks each criterion, and how.** A criterion nobody actually checks is not a criterion,
   it is a sentence — see the second failure mode below for what a DoD that is never actually verified
   looks like in practice.
4. **Know the DoD is complete when every criterion traces to a real cost of skipping it.** If a
   criterion cannot be tied to a specific, nameable failure the project has had or would plausibly have —
   a bug that shipped, a regression nobody caught, a decision nobody could reconstruct — it is decoration,
   and decoration is exactly what makes a DoD heavy enough that a team routes around it (the fourth
   failure mode below).

## What makes a DoD criterion well-formed

**Objective, falsifiable, evidence-producing** — the same three properties, stated once so every
project-specific DoD can be checked against them rather than re-derived. A criterion is well-formed when:

- **Objective** — two different reviewers, reading the same evidence, reach the same verdict. "Works
  well" fails this; "the suite named in the CI config is green" does not.
- **Falsifiable** — there exists a concrete way for the criterion to be *unmet*, and that way is
  checkable by someone who disagrees with the reviewer. A criterion that is always satisfied whatever
  the diff contains is not a criterion; it is a formality wearing a checkbox.
- **Evidence-producing** — satisfying it leaves behind something a later reader can point at: a command's
  real output, a passing check's name, a line in the diff. "I looked and it's fine" is not evidence; a
  named artifact is.

**A concrete instance of this rule, rather than an abstract restatement of it:** this plugin's own
`quality-gates` skill states its review discipline as *"a finding blocks only if it names a criterion and
a falsifier"* — the exact same property, applied at the point a finding is judged rather than at the
point a criterion is written. Read that skill for the worked, mechanical form (evidence required per
criterion, a stated falsifier, severity set by whoever found it) rather than re-deriving it here; this
skill states the general rule, `quality-gates` is one project's concrete implementation of it.

## Common DoD shapes

There is no one correct shape — the right one depends on how many kinds of work the DoD has to cover and
how much the team can afford to run per item.

- **A fixed checklist.** One list, applied identically to every item — lint clean, tests written,
  reviewed, documented. Simple to state and simple to audit, and it is where most teams start. It
  breaks down when the work is heterogeneous: a checklist item that makes sense for a feature ("user-
  visible change has an end-to-end test") is either vacuous or actively wrong for a dependency bump or a
  documentation fix, and a DoD that cannot tell the two apart either exempts items informally (which
  erodes the checklist's authority) or blocks trivial work on decoration.
- **Per-item-type criteria.** The checklist branches on what kind of item it is — a feature's criteria
  differ from a bugfix's, which differ from an infrastructure change's, which differ from a
  content/copy change's. This is heavier to design and maintain (more than one list to keep current), but
  it is what an unsatisfiable-criterion problem actually asks for: the criteria that apply are the ones
  that make sense for the surface the item touches. This plugin's own loop is an instance of a related
  idea one level up — its gate table branches on loop model rather than item type, but the principle
  (branch on what actually varies, rather than force one list to cover everything) is the same move.
- **An automated gate.** The criteria are encoded as CI checks, and "done" is defined as "every required
  check is green." This is the strongest form of *objective and evidence-producing* — a human cannot
  misjudge a check that either ran and passed or did not — but it only covers what can be automated, and
  a criterion nobody wrote a check for silently has no enforcement at all, however confidently the team
  believes it is covered. The trade-off worth naming explicitly: automation converts "was this checked"
  from a judgment call into a fact, at the cost of upfront engineering per criterion, and it can quietly
  narrow "done" to "what the pipeline happens to measure" if nobody periodically asks what the pipeline
  is *not* measuring.

**These are not mutually exclusive, and most working DoDs are a fixed core plus one of the other two
layered on top** — a small fixed checklist that applies to everything (lint, review, a merge to the
trunk), with either type-specific additions or automated enforcement carrying the weight for what the
fixed core cannot express on its own.

## Failure modes of a badly-made DoD

Four, named together rather than ranked — a real DoD can fail any of these independently, and a DoD that
avoids one is not thereby safe from the others.

- **Vague, unfalsifiable criteria.** "Works well," "is stable," "looks good" — nothing here is
  objectively testable, so the criterion decides nothing; it just relocates the same impression-based
  judgment the DoD exists to remove, now wearing a checkbox.
- **A DoD nobody actually checks item-by-item.** The list exists, and review happens anyway as "looks
  good to me" rather than as a walk through each stated criterion. The DoD is real on paper and
  ceremonial in practice — which is worse than no DoD, because it lets everyone believe a check happened
  that did not.
- **A DoD copied from another team or project without adapting it.** The criteria were well-formed
  *somewhere else*, against a different project's surfaces, and inherited wholesale rather than checked
  against what this project actually delivers. This is the central mistake named in *Designing a DoD from
  scratch* above, and it is listed again here as a failure mode because it is also the most common
  starting condition of a DoD that later exhibits the other three.
- **A DoD so heavy the team routes around it.** Every criterion added has a cost paid on every item, and
  a checklist that grew past what any given item actually needs teaches the team to fill it in
  perfunctorily or skip it under deadline pressure. A DoD that is honored in the breach is functionally
  no different from having none, except that it also cost the discipline of maintaining it.

**The common thread across all four:** each one produces a DoD that *looks* like a mechanism — a
document, a checklist, a gate in CI — while not actually functioning as the ruler it claims to be. The
test in *Why a Definition of Done is a mechanism, not a phrase* (does a criterion decide, or does a
person still decide and the criterion just gets cited afterwards?) is what separates a real DoD from any
of these four.

## Ready is a precondition of done

**A DoD cannot rescue an item that was never properly ready.** This is not a general truism weakened for
effect — it is a specific, observed failure: a project whose User Stories were never well-defined, only
arbitrary Acceptance Criteria attached to something that stayed ambiguous throughout, reaches the point
where *any* DoD applied at the end is inert. The checklist can be perfectly well-formed and still certify
nothing, because there was never a stable, agreed statement of what "this item" was for the checklist to
be checked against. See *My take*, below, for this stated in the owner's own words, and
`/definition-of-ready` for the entry-gate discipline this depends on.

**The practical implication:** when a DoD seems to be failing — findings keep surfacing that no criterion
anticipated, review keeps re-litigating scope — the fix is not always a heavier DoD. Check the item's
readiness first. A DoD that keeps needing new criteria to catch what a vague story keeps producing is
treating a Definition-of-Ready failure as a Definition-of-Done problem, and no amount of checklist
tuning at the exit gate fixes an ambiguity that should have been resolved at the entry gate.

## Pros & cons

**Pros**
- Converts "is this done" from an impression, decided anew by whoever is looking, into a checkable
  property that two different reviewers reach the same verdict on.
- Makes the cost of "done" visible and negotiable *before* work starts, rather than discovered as a
  surprise at review time.
- A DoD shaped per project (rather than inherited generically) scales down honestly — a project with
  fewer surfaces gets a shorter, still-complete list, the same move `/definition-of-ready` makes on its
  own checklist.

**Cons**
- Designing it well needs judgment the first time, and re-judgment whenever the project's surfaces
  change — a DoD that is never revisited eventually drifts into one of the four failure modes above.
- A DoD, however well designed, still depends on a well-formed item to check it against — see *Ready is
  a precondition of done*.
- The automated-gate shape trades a judgment-call risk for a coverage-gap risk: what the pipeline does
  not measure is invisible, not merely unmeasured, unless someone periodically asks what is missing.

## My take

*(Elicited directly from the owner — not scaffolded, not generalized.)*

**The most common failure, and he named all four together rather than picking one:** vague or subjective
criteria that name nothing testable ("works well," "is stable"); a DoD that exists on paper but is never
actually checked item-by-item, so review degrades back into "looks good"; a DoD copied from another team
or project without adapting it to what *this* project actually delivers; and a DoD so heavy the team
routes around it or fills it in perfunctorily rather than actually clearing it. All four are real, all
four happen, and none of them is "the" failure mode — that is the origin of *Failure modes of a badly-made
DoD*, above, named together rather than ranked because that is how he answered.

**The central mistake, in his words:** *"o grande erro cometido é seguir uma regulamentação corporativa ou
algo genérico que não é ajustado ao propósito do projeto"* — the big mistake is following a corporate
regulation or something generic that isn't adjusted to the project's own purpose. Asked where to start
when designing a DoD from scratch, this was his answer — not "write more criteria" or "add more gates,"
but a warning about the *source* the criteria come from. That is why *Designing a DoD from scratch* above
opens on where the DoD's criteria come from, before it says anything about what a well-formed criterion
looks like: getting the source right is upstream of getting any individual criterion right.

**The concrete failure story, in his words:** *"um projeto que não tinha USs bem definidas, só tinha CAs
arbitrários, ficava ambíguo e com isso ao final qualquer DOD (checklist de completude) era inócuo"* — a
project that had no well-defined User Stories, only arbitrary Acceptance Criteria, stayed ambiguous
throughout, and because of that, by the end, any DoD (a completeness checklist) was inert. He offered
this unprompted as the answer to what makes a DoD fail in practice, and it is the origin of *Ready is a
precondition of done* above, verbatim to what he described rather than a general principle this skill
invented and attributed to him. The direct implication he is naming: a Definition of Done is downstream
of intake quality, and `/definition-of-ready`'s own discipline — closing the ambiguity at the edges of a
story before it is built — is not a separate concern from this skill, it is the concern that determines
whether this skill's checklist means anything at all.
