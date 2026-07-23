# 0004. Autonomy & permission model — classes + tool-scoping

- **Status:** accepted
- **Date:** 2026-07-22
- **Deciders:** the owner
- **Driven by:** [ADR-0002](./0002-agentic-dev-loop-architecture.md), [ADR-0003](./0003-mr-definition-of-done.md)

## Context & problem
The goal is to reduce the human's per-item approvals for delimited/roadmap work **without** giving up the
production go/no-go on the things that matter. A permission model has to say *who may merge what*, and
enforce it so it isn't just a promise an agent can break.

## Decision drivers
- Delimited, in-pattern work should complete without a human clicking merge each time.
- The irreversible/architectural boundary must stay with the human.
- Enforcement should be **mechanical**, not judgment — a capability, not a rule an agent can ignore.

## Considered options
1. **DoD classification + per-persona tool-scoping** (chosen) — the `critical-reviewer` approves **and
   merges** the **safe class** (docs, deps, test-only, in-pattern refactor, in-pattern implementation of an
   already-approved spec/ADR) once the DoD (ADR-0003) is green; the **boundary class** (architecture,
   contracts, `iac/`, positioning/public content, any ADR change, anything irreversible) always escalates
   to the human. Enforced mechanically: build specialists have **no merge tool**; the reviewer has **no
   edit tool**. The plugin defines the model; the project's committed settings consume it. *Trade-off:* the
   reviewer is not a human — a fresh context removes authorship bias, not model bias.
2. **All merges ask the human** — *Why not:* the status quo; no autonomy, the exact bottleneck this removes.
3. **Auto-merge anything the gate passes** — *Why not:* removes the human from the production go/no-go on
   architecture and infra; a same-model reviewer isn't a sufficient backstop for irreversible changes.

## Decision outcome
Chosen: **classified autonomy, mechanically enforced.** The safe class self-merges on a green DoD; the
boundary escalates. Tool-scoping makes the classification a capability boundary (a specialist *cannot*
merge; a reviewer *cannot* edit), reinforced by the existing global permission floor
(`apply`/`destroy`/`--force`/`rm -rf`/secrets/`--dangerously-skip-permissions` denied + the `PreToolUse`
guard hook, unchanged). Significance always pulls a merge from the subagent (ADR-0003).

## Consequences
**Good**
- Delimited work completes end-to-end without per-item human clicks; the human's attention goes to the boundary.
- The boundary is a *capability*, not a promise — the agent literally lacks the tool to cross it.

**Bad / accepted costs**
- The reviewer is the same model family as the author: strong gate, not a substitute for human judgment on
  the boundary class (hence it always escalates). Consider a higher reviewer model/effort or a multi-vote
  refute pass for high-stakes MRs.
- The safe/boundary line needs care; a mis-classified boundary MR that self-merges is the failure mode to
  guard against (significance-test discipline).

## Links
- Driven by ADR-0002, ADR-0003 · consumed per project via committed `.claude/settings.json` · the global
  floor + guard hook are described in the plugin's `/principles/permissions-and-environments`.
