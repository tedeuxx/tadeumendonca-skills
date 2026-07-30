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

## Amendment (2026-07-25) — the "only the reviewer merges" claim is now mechanically true (#77)

The *Decision outcome* above claimed the classification is "mechanically enforced … a specialist *cannot*
merge." Half of that held and half was a promise. **The reviewer-has-no-edit-tool half was real** (its
agent definition grants no Write/Edit). **The no-merge-tool half was not:** merging goes through
`gh pr merge`, and the consuming repo's committed `.claude/settings.json` allowlists `Bash(gh pr merge:*)`
for the shared permission surface that **every** context inherits — the main agent and every subagent
alike. So "only the reviewer merges" rested on the main agent *choosing* to route through the reviewer —
instruction-following by the same context that (per #76's diagnosis) had skipped the review on several PRs
in a row. The `critical-reviewer` flagged this while reviewing #76; #77 tracked it.

**Fix — an agent-scoped merge gate in `permission-guard.sh` (rule 7b).** The harness stamps a subagent's
tool calls with `agent_type` (`<plugin>:<subagent>`) and leaves it empty for the main agent; this field is
set by the harness, not the prompt, so the model cannot forge it. The guard now **denies `gh pr merge`
unless `agent_type` ends in `:critical-reviewer`.** The main agent and every other subagent are denied;
the reviewer — the one context that *is* the merge gate — is allowed. "Did the reviewer run?" becomes a
precondition satisfiable only by actually routing the merge through the reviewer, matching how `wip-guard`
and the trunk-push block already work. Ships via the marketplace (`autoUpdate` on the consumer), ~~no
manual step~~ — **amended 2026-07-30**: that clause is false and this ADR's own premise now depends on
knowing it. `autoUpdate` did not carry `wip-guard`'s rewrite to a live session: the plugin was released
as `0.4.18` and the session kept running `0.4.15` for the rest of the day, so a guard behaved by a rule
that had already been fixed. **A fix ships to the marketplace; it reaches a session when the installed
copy updates, and nothing said when that was overdue.** `version-lag.sh` (SessionStart) now says it.

**Consequence — the merge flow changes, deliberately.** The main agent can no longer merge, even with the
human's go. A human-approved **boundary**-class merge is now performed by **re-invoking the
`critical-reviewer` with the human's ratification**, and it executes the merge — the human's go/no-go is
unchanged, only its *executor* moves to the gate. The safe class was already the reviewer's to merge; this
only closes the main agent's back door.

**Accepted residual (recorded, not hidden).** The gate matches the natural command `gh pr merge` (with the
`-R`/`--repo` convention). A raw `gh api … PUT …/merges` is **not** matched — pattern-listing every API
form is brittle and would drift. The API back door is an accepted, named gap: the everyday path is a
capability boundary now; a determined bypass via raw API is possible and is a smaller risk than a false
sense of total coverage. Revisit if it is ever observed in use.

This makes the *Decision outcome*'s "a specialist cannot merge" true rather than aspirational; the
"unchanged" note on the guard hook in that section is itself now superseded — the guard gained rule 7b.

## Links
- Driven by ADR-0002, ADR-0003 · consumed per project via committed `.claude/settings.json` · the global
  floor + guard hook are described in the plugin's `/principles/permissions-and-environments` · amended
  (2026-07-25) to add the agent-scoped merge gate (rule 7b in `permission-guard.sh`), closing #77.
