# 0003. The Merge Request Definition of Done

- **Status:** accepted
- **Date:** 2026-07-22
- **Deciders:** the owner
- **Driven by:** [ADR-0002](./0002-agentic-dev-loop-architecture.md), `docs/proposals/agentic-dev-loop.md`

## Context & problem
The `critical-reviewer` subagent (ADR-0002) reviews MRs so the human doesn't have to on the safe class.
But a reviewer without an explicit, agreed ruler reviews by taste — which reintroduces exactly the
subjectivity/bias the isolated reviewer exists to remove. The Definition of Done must be **pacted** and
**objective**, or the reviewer is worthless.

## Decision drivers
- Every criterion must be mechanically checkable or evidence-cited — no "looks fine".
- It must classify who may merge (the autonomy hinge, ADR-0004).
- It must scale to the slice type (a docs slice ≠ a feature slice).

## Considered options
1. **A pacted, objective DoD with a merge-authority classification** (chosen) — hard gates (thin slice,
   traceability to an Issue, tests proportional to slice type with coverage ≥85%, all gates green with real
   evidence, an ADR when a significance boundary is crossed, observability, no doc drift, conventional
   commits, security posture) + a **safe/boundary classification** that decides who merges. *Trade-off:*
   discipline cost, and the significance test needs judgment.
2. **Subjective reviewer judgment** — *Why not:* reintroduces bias; two reviewers would disagree; not
   auditable.
3. **No DoD** — *Why not:* the reviewer subagent has nothing to review against; autonomy can't be granted safely.

## Decision outcome
Chosen: **the DoD of `docs/proposals/agentic-dev-loop.md` §6**, with three pacted resolutions:
- **Significance > in-pattern** — a change crossing a significance boundary always leaves the safe class,
  even if it looks routine. Safety over convenience.
- **Coverage ≥85%** — the plugin's default; a project may raise it, never lower.
- **Approval hook** — the human approves once, on the spec/Issue; the slices implementing it are born
  safe-class. This is the join between one approval and downstream autonomy.

## Consequences
**Good**
- The reviewer has an objective, auditable ruler → its verdicts are trustworthy, not taste.
- Tests scale to slice type → a docs PR isn't blocked demanding an E2E it doesn't need.

**Bad / accepted costs**
- Ongoing discipline: every significant MR carries its ADR; every feature carries its regression.
- The significance test is objective but still a judgment call at the margins (both reviewers apply it).

## Links
- Driven by ADR-0002 · the classification feeds the autonomy model ADR-0004 · full checklist in the
  proposal §6.
