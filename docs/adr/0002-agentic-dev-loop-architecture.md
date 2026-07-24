# 0002. Agentic dev-loop architecture — per-task subagents, ADRs as the durable brain

- **Status:** accepted
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

## Amendment (2026-07-24) — product personas, advisory only
The roster gains **`product-owner`** and **`product-manager`**, which the design had excluded:
`docs/proposals/agentic-dev-loop.md` read *"product ownership stays human"*. That line stays true in
substance and is narrowed in scope, because it was answering a question nobody had asked — whether an
agent may **decide** product direction. It may not, and neither of these does.

What changed is the observation that the reviewer roster had **no mandate over the copy**. The
`critical-reviewer` judges a diff against the Definition of Done; on a presence where the words are the
product, a positioning breach, an unearned claim or a cross-surface contradiction ships **green**,
because none of them is a DoD criterion. Reviewing them was left implicitly to the human — which meant
they reached the human unreviewed, in a PR already marked green, at the moment of least attention.

The split:
- **`product-owner`** — reviews reader-facing **copy** against the owner's private positioning source
  of truth: claims the author has not earned, unsourced quantification, precision drift against the
  canonical CV data, cross-surface incoherence, confidentiality, third-party naming. Runs where a repo
  marks content boundary **by path**.
- **`product-manager`** — upstream of `planner`: sequencing, scope and opportunity cost. Whether a
  slice is the right *next* thing, and what half-done state it creates or closes.

**Both are advisory and neither can merge**, which is what keeps *"product ownership stays human"*
intact: they raise the decision with the evidence attached, and the human decides. They author nothing —
`product-owner` in particular **never edits copy**, since the voice is the owner's and a persona
rewriting it in its own register is the failure being guarded against.

One constraint is load-bearing enough to state in the ADR: the positioning source is **private and
gitignored**, while findings frequently land in a **public** PR. `product-owner` must cite it, never
quote it. A review that leaks the strategy layer to protect the copy has done more damage than the copy
could.

Roster: 20 → 22 defined.

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
