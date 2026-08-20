# 0019. README.md is the single source of truth for the dev-loop documentation

- **Capability:** decision-library
- **Status:** accepted
- **Date:** 2026-08-14
- **Deciders:** owner (decision), harness-lead (record)
- **Supersedes / superseded by:** amends [ADR-0002](./0002-agentic-dev-loop-architecture.md)'s "Where the
  design now lives, harness-agnostically" note (added 2026-08-02, amendment #7) — that note named
  `docs/dev-loop-design.md` as the harness-agnostic description of the loop; this record moves that role
  to `README.md` and retires the standalone file.
- **Driven by:** #261 (README summarization, corrected mid-flight to a consolidation), #262 (the
  superseded proposal doc, sequenced to land after this one)

## Context & problem

Three documents described overlapping ground: `README.md` (a human entry point that had grown into a
full architecture document — roster, lifecycle, both branch models, hooks, resource taxonomy, each at
real depth), `docs/dev-loop-design.md` (630 lines, written explicitly as a **harness-agnostic** design
doc — "for import into any agent harness — Claude Code, Kiro, or another"), and
`docs/proposals/agentic-dev-loop.md` (already stale, ratified into ADR-0001 through ADR-0004,
superseded — #262's subject, not this one's).

#261 opened asking whether the README should be *thinned* — its dense content relocated into `docs/`,
leaving a short entry point. The owner corrected that mid-session: the README is now meant to be the
**single canonical source**, not a thin pointer deferring to a second document that claims the same
authority. Two documents both describing the roster, the lifecycle and the gate model at similar depth
is not redundancy that resolves itself — it is two places a reader (or a future session) can get a
different answer, with no rule for which one is current.

This crosses the significance test on its own terms: it **alters a previously-recorded decision** —
ADR-0002's own note states where the harness-agnostic design "now lives," and that pointer target is
what changes here.

## Decision drivers

- Two documents claiming the same authority is worse than one document at full depth — a reader (or a
  session) has no rule for which one is current, and the two *will* drift, because nothing forces them
  to be edited together.
- `CLAUDE.md`'s "additive density" principle (deepen; never thin out good content) — consolidating two
  documents into one at full depth is not the same act as shortening one of them, but the distinction had
  to be made explicit rather than assumed, since #261 opened with the opposite direction.
- `docs/dev-loop-design.md`'s own stated purpose — portable across harnesses, including Kiro — is real
  content, not decoration, and retiring the file must not silently drop that framing.
- The methodology ADR library (`docs/adr/`) remains authoritative over both; this decision is about where
  the **narrative** description lives, not about which ADR governs a given rule.

## Considered options

1. **README.md absorbs `docs/dev-loop-design.md`'s content; the file becomes a superseded pointer stub,
   not deleted.** Chosen. *Trade-off:* the README grows further (already dense before this change), and
   a reader who wants "just the loop, nothing about installing the plugin" now has to read past
   plugin-specific sections to reach it — there is no longer a document that is *only* the design.
2. **Keep `docs/dev-loop-design.md` as the canonical design doc; shrink the README to a thin entry
   point, per #261's original framing.** *Why not:* this was the owner's own initial framing and was
   reversed mid-session — a thin README defers dense content to a second document, which is exactly the
   two-sources problem this record exists to close, just with the authority assignment flipped.
3. **`git rm` the design doc outright rather than leave a stub.** *Why not:* the file's canonical URL
   (`raw.githubusercontent.com/…/docs/dev-loop-design.md`) is quoted in its own header as the citable
   target for import into another harness, and ADR-0002 already names it by that role. A 404 where a
   redirect could stand costs a reader nothing to avoid ~~and this repo's own convention
   (supersede-never-delete) already answers the question~~ — **that second clause is struck; see the
   2026-08-15 amendment below.** The first clause is the surviving reason and it is sufficient.

## Decision outcome

Chosen: **Option 1.** `README.md` gains the content `docs/dev-loop-design.md` carried that the README
did not already have at comparable depth — the Definition of Done (issue-requirement enumeration, the
finding-blocks-only-with-a-falsifier rule, severity set by the lens that found it), the intake-formalism
argument (why the gate's ruler must be external, the two-round budget, parallel-not-serial dispatch), and
a new "What travels if this design moves to another harness" section carrying the
essential/incidental/known-weak split that made the old document reusable outside Claude Code.
`docs/dev-loop-design.md` becomes a short pointer at its existing path, so its externally-cited canonical
URL still resolves to something, and that something says plainly what happened and where the content
went.

Content judged genuinely redundant — the roster narrative, the branch-model diagrams, the general
problem statement, the "what was absorbed" history — was **not** duplicated into README a second time,
either because README's own version was already more current (the roster; `dev-loop-design.md`'s was
written against the 2026-08-04 five-persona shape and predates `harness-lead` and `writer`) or because an
equivalent already lives in a better-homed file (`CLAUDE.md`'s own roster section carries the
absorbed/retired history; `agents/quality-assurance.md` carries the gate's own capability-boundary
argument in more detail than the design doc did).

## Consequences

**Good**
- One document to keep current instead of two that can silently disagree.
- The portable/harness-agnostic framing survives, moved rather than lost, and is now next to the concrete
  implementation it describes rather than in a separate file a reader might not find.
- The `additive density` tension #261 raised is resolved explicitly rather than left for the next reader
  to re-litigate: consolidation grew the README rather than shrinking it (line-count delta stated in the
  implementing PR).

**Bad / accepted costs**
- The README is now the longest single document in the repo by a wide margin, and a reader wanting only
  "how do I install this plugin" has more to scroll past than before.
- `docs/dev-loop-design.md`'s canonical-URL framing ("import into any agent harness") is now a pointer
  one hop from the content rather than the content itself — a machine or reader following the raw URL
  gets a redirect notice, not the design, which is a worse experience than the URL resolving directly
  (accepted because the alternative, `git rm`, is worse: no redirect at all).
- CLAUDE.md's own references to `docs/dev-loop-design.md` (in the roster section and the command
  reference) need updating to point at README sections instead — named as consequent work in the
  implementing PR, not re-litigated here.

## Amendment — 2026-08-15 (#281): the convention this record's option 3 cited no longer exists

**What changed:** *supersede-never-delete* was replaced by the rule recorded in
[ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md) — *a record earns its
place by explaining the current codebase*. This record's rejected option 3 cited that convention as one
of two reasons not to `git rm` the design doc, so **half of that rejection is now unargued.** The clause
is struck in place above rather than rewritten, per the convention ADR-0020 leaves explicitly unchanged
for live records.

**What does not change: the outcome.** Option 3 stays rejected on its **surviving reason**, which was
always the load-bearing one — `docs/dev-loop-design.md`'s canonical URL is quoted in its own header as
the citable target for import into another harness, and ADR-0002 names it by that role, so deleting it
produces a 404 where a redirect costs nothing. That reason is independent of any deletion convention.

**And ADR-0020 does not reach this file anyway**, which is worth stating so nobody applies the new rule
to it by association: ADR-0020 is scoped to **ADR records**, and `docs/dev-loop-design.md` is a redirect
stub, not a record. Its disposition is settled here and is untouched.

## Links
- [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md) — replaces the
  convention this record's option 3 cited; see the 2026-08-15 amendment above.
- #261 — the Issue this record executes, including the owner's mid-session correction reversing the
  original "thin the README" framing.
- #262 — the sibling Issue (archiving `docs/proposals/agentic-dev-loop.md`), sequenced to land after this
  one so it has a settled target (README, not the now-retired design doc) to point at.
- [ADR-0002](./0002-agentic-dev-loop-architecture.md) — amended by this record's pointer-target change;
  the roster/DoD/gate decisions ADR-0002 itself records are otherwise untouched.
- [ADR-0017](./0017-adr-authorship-is-split-by-domain-not-tech-lead-exclusive.md) — the authorship-split
  decision under which this is `harness-lead`'s record to write (a pure loop/harness documentation-
  architecture decision, no product-architecture consequence).
