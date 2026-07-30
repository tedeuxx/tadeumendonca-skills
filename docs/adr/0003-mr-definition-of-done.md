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

## Amendment, 2026-07-30 — adjacent debt is named, never filed

**Owner directive.** Gate 1 of the adopted DoD said *"adjacent debt → an Issue, never fixed inline"*.
It now reads: adjacent debt is **named in the review, never filed and never fixed inline**. Only the
owner opens work.

**Why the ratified text had to change rather than the practice around it.** The instruction was not
being violated — it was being followed. In one session the queue grew by 19 issues net and roughly 13
were born inside a *review of something else*, each one a finding that gate 1 told the reviewer to
file. Nobody decided that work should exist; the loop decided, and asked afterwards. The queue stopped
describing the product and started describing how hard the agents had looked at it.

**Enforced rather than instructed.** `permission-guard` rule 5c denies `gh issue create` — every
spelling of that command, with no `agent_type` exemption. Read, list, comment, label and close remain
open. An exemption a model can invoke by asserting something about itself is not a boundary, so there
is none.

**With one named accepted gap:** the `gh api … POST …/issues` route is **not** matched, the same way
ADR-0004's rule 7b books `gh api … PUT …/merges` for merging. It was matched twice and both matchers
were wrong — one let a quoted URL through, the other blocked a commit message *about* the act. A stated
gap describes the code; a matcher that keeps failing to be what its comment claims is the defect this
amendment exists to remove.

**The accepted cost, named here so it is not rediscovered:** a finding in a verdict is ephemeral where
an Issue is not. On a merged PR the report has no reader afterwards, so some real findings will be
lost. That is the trade — and it is preferred to a backlog that grows by working.

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
