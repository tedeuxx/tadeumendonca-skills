# 0002. Agentic dev-loop architecture — per-task subagents, ADRs as the durable brain

- **Status:** accepted · **amended 2026-07-24** (`product-owner` joins the roster — see the amendment below)
- **Date:** 2026-07-22
- **Deciders:** the owner
- **Driven by:** [ADR-0001](./0001-adopt-madr-adrs.md), `docs/proposals/agentic-dev-loop.md`

## Context & problem
The dev-loop needs to (a) optimize the context window, (b) eliminate the authorship bias that appears when
one agent both writes and reviews, and (c) scale beyond what a single context can hold. How the loop is
structured — one agent doing everything vs. a team of specialized contexts — determines whether those
three properties are achievable.

## Decision drivers
- Context efficiency — an agent should carry only what its task needs, not the whole session.
- Bias elimination — review must not be done by the context that wrote the code.
- Reuse — the machine should be usable across projects (it lives in the plugin).

## Considered options
1. **Per-task subagent contexts (personas × ephemeral instances), orchestrated via artifacts** (chosen) —
   a *persona* (frontend-react, critical-reviewer, …) is a reusable definition wielding a scoped
   skill/tool/model bundle; each *invocation* is a fresh, discarded-after context loading only its task.
   The main loop orchestrates; subagents hand off through artifacts (Issue, spec, ADR, diff), not a shared
   context. **ADRs are the durable shared brain** a fresh context reads to stay coherent. *Trade-off:*
   orchestration overhead and per-subagent cost.
2. **One generalist agent doing all layers** — *Why not:* no context optimization (it carries everything),
   and review carries authorship bias (it defends its own code).
3. **Fixed long-lived specialist agents** — *Why not:* standing agents accumulate cross-task context,
   losing the per-task isolation that gives both the optimization and the bias elimination.

## Decision outcome
Chosen: **per-task subagent contexts**. A subagent is an *autonomous context specific to a task*, not a
standing employee. Because a fresh context cannot remember prior decisions by construction, the ADR
libraries (ADR-0001) are what make the isolation safe — without them, isolation is a drift machine. The
roster (20 personas covering a common SDLC — 22 since the amendment below) is defined in the plugin; each project enables the subset its
blast-radius justifies, and personas are materialized lazily as work demands. Full detail:
`docs/proposals/agentic-dev-loop.md`.

## Amendment (2026-07-24) — `product-owner`: the copy gets a reviewer
**Problem.** The reviewer roster has **no mandate over what the words claim**. `critical-reviewer`
judges a diff against the Definition of Done, and a positioning breach is not a DoD criterion — so on a
presence where the copy *is* the product, an unearned claim, a cross-surface contradiction or a
confidentiality slip **ships green**. Reviewing them was left implicitly to the human, which meant they
reached the human unreviewed, inside a PR already marked green, at the moment of least attention.
Observed, not hypothetical: four such defects in one MR (`tadeumendonca-io#81`), all found by
`critical-reviewer` being thorough rather than by anything being responsible for them.

### Considered options
1. **A `product-owner` persona, advisory, triggered from `critical-reviewer`** (chosen) — a fresh
   context whose ruler is the owner's private positioning source. *Trade-off:* a second context per
   content MR, and its trigger is an instruction inside another persona rather than a mechanism.
2. **Extend the DoD (ADR-0003) and give `critical-reviewer` the positioning mandate** — *strongest
   rejected alternative*, and it wins on the axis option 1 is weakest: `critical-reviewer` already runs
   on **every** MR, so the trigger problem disappears. Rejected because it requires giving the merging
   persona read access to the **private** `.brand/` source. That persona has `Bash`, merges, and writes
   to public PRs — pointing it at the strategy layer puts the leak risk in the one context with the most
   publishing capability. Keeping the private source in a **read-only, write-incapable** persona is
   worth the weaker trigger.
3. **Leave it human** (the status quo) — *Why not:* it *was* human, and the failure mode is exactly that
   the human receives content defects inside a green PR with no signal that nobody checked the copy.

### Decision
**`product-owner`**: reviews reader-facing copy — claims the author has not earned, unsourced
quantification, precision drift against the canonical CV data, cross-surface coherence, confidentiality,
third-party naming, reader-first framing, durability. Runs where a repo marks content boundary **by
path**. It is **advisory** and has **no write capability at all** (`Read, Grep, Glob` — no `Bash`,
`Edit` or `Write`), so *"product ownership stays human"* holds in substance: it cannot edit copy, cannot
merge, cannot even post its own findings. The voice stays the owner's.

**The trigger lives in `critical-reviewer`**, the only persona guaranteed to run on every MR: a diff
touching content-boundary paths is **incomplete** until `product-owner` has returned a verdict, and the
reviewer must report that verdict or state that it did not run. A mandate with no trigger is a document,
not a gate.

**Privacy is structural, not a promise.** The positioning source is private and gitignored while
findings land in **public** PRs, so `product-owner` references rules by **stable identifier and
location** (`positioning.md §X, bullet N`) rather than restating them — paraphrase leaks the substance
while technically not quoting. Written that way the output is inert outside the private context. Backed
by the tool grant: the one persona whose output is dangerous in public cannot publish it (ADR-0004 — the
boundary should be a capability, not a promise).

### Consequences
**Bad / accepted costs**
- **The trigger is an instruction, not a mechanism.** It hangs off `critical-reviewer` reading its own
  definition. Weaker than the `PreToolUse` guards this repo uses elsewhere, and the honest reason it
  ships this way is that the hook form is a larger slice.
- **Two contexts per content MR** — more tokens, more latency, on the MRs that already carry the most
  review.
- **No tie-break** between `product-owner: ADJUST` and `critical-reviewer: APPROVE-AND-MERGE`. Currently
  benign because content is boundary class and escalates anyway; it becomes real if that ever changes.
- **The private source is read by an agent.** Mitigated by the identifier-only output rule and the
  absent write tools, but not eliminated — a residual accepted deliberately.

**Not shipped:** a `product-manager` persona (sequencing, scope, opportunity cost) was drafted and
withheld. It would contradict this proposal's still-standing *"backlog prioritization stays human"*, its
scope overlaps `planner` and `plan-reviewer` on "smallest slice", and the evidence behind this slice was
entirely about copy. It needs its own decision and its own evidence.

Roster: 20 → 21 defined.

## Consequences
**Good**
- Context efficiency and authorship-bias elimination fall out of per-task isolation.
- Reusable across projects; the roster models a whole engineering org.
- The copy gets a reviewer with a mandate, instead of relying on the code reviewer noticing.

**Bad / accepted costs**
- Orchestration overhead and token cost — spawn a specialist only when a slice genuinely spans its domain.
- Same-model review has a ceiling: a fresh context removes *authorship* bias, not *model* bias — which is
  why the boundary class still escalates to a human (ADR-0004).

## Links
- Driven by ADR-0001 (ADRs are the brain this depends on) · the DoD is ADR-0003 · autonomy/tool-scoping is
  ADR-0004 · full design in `docs/proposals/agentic-dev-loop.md`.
