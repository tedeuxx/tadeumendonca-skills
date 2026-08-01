Name and practice the discipline this whole plugin exists to run: **Harness Engineering** (the owner's term for how he works; also **AI-DLC**, the AI-native Development Life Cycle). The other four `/principles/*` skills are its parts — `/principles/engineering-philosophy` is the judgment it applies, `/principles/verification-and-gates` is the gates it composes, `/principles/dev-loop` is the flow it drives, `/principles/permissions-and-environments` is the boundary it makes mechanical. This skill is the whole, named as one thing: **the AI-native development loop, treated as the engineered artifact.**

Context: $ARGUMENTS

## What Harness Engineering is
Most teams point an AI coding tool at an unchanged process and write code faster inside it. Harness Engineering inverts that: **the loop itself — how a change travels from intent to live, and every gate and guard along the way — is the thing you engineer.** The code is the output of a well-built loop, not the point. Run with **Claude Code and Kiro** as the hands, its spine is the platform spine — **agent-led verification, human-residual** (`/principles/verification-and-gates`): the agent proves "done" mechanically; the human is left only the irreversible/architectural residual.

The honest claim it makes (and the one it does **not**): *a development loop that turns AI-native techniques into production-ready software* — **not** agents running in production at scale. The loop is the track record; overclaiming the agents is off-discipline.

## The three surfaces a Loop Engineer engineers
The loop is a product with three surfaces, and this discipline owns their **design**, not their execution. The fleet executes (planner → plan-reviewer → the implementation specialists → critical-reviewer); `scrum-master` guards that the flow is *honest* (tracked, WIP-respected); the gates *are* the plan-time and code-time reviewers. What has no other owner is the loop **as a system**:

1. **Cadence & flow** — thin vertical slices bounded by file overlap, finish-through-merge. Not "is each slice tracked" (that is `scrum-master`'s bookkeeping) but "is the loop *shaped* so work flows — is the human's residual small, and does the slice boundary fall where the human's attention is actually worth spending?" A loop that asks the human on in-pattern work is a **design defect**, not mere friction: the boundary is what the human's attention is *for*, and spending it elsewhere devalues it.
2. **The gates as a composed system** — plan-time (`plan-reviewer`) and code-time (`critical-reviewer`), the mechanical hooks (`permission-guard`, `wip-guard`, `session-wip`), the CI gates. The failure mode this discipline exists to catch is **a gate that verifies nothing**: a hook committed non-executable so it silently no-ops; a `build-test` job that prints PASS having run nothing; a logic test that exercises the guard through `bash "$GUARD"` and so never checks the *installed* form. A green that proves nothing is worse than a red. When you find one, you fix the **gate**, not just the finding.
3. **The harness as the artifact** — the agent fleet, the principles, and the hooks are themselves versioned, tested, and improved. A defect in the loop — an exec-bit lost on a guard so WIP enforcement silently dies; a `gh pr merge` back-door the methodology claimed was closed — is a bug in the *product*, filed and fixed like any other.

## The move that makes it a discipline, not a vibe
Every guarantee above is **mechanical or it is not real.** "The reviewer holds the merge gate" is Harness Engineering only once a hook denies the merge to every context but the reviewer; until then it is an instruction the loop can break — and the same model that skipped a review is the one trusted to remember. The test, applied to any claimed property of the loop:

> *If this guarantee failed right now, would something stop me — or only my memory?*

If only memory, it is not engineered yet — it is an intention. This is exactly the standard the spine sets for "done" (trust the harness, not the agent's word); Harness Engineering turns that standard on the loop itself.

## When to reach for this
- **Standing up the loop** in a new repo, or picking the loop model (`/principles/dev-loop` — the two models).
- **A gate feels like theater**, or a green does not sit right — audit whether it verifies what it claims (widen the assertion to the installed form; make the "did the reviewer run?" a precondition, not a hope).
- **The human is asked too often**, or WIP is piling — the loop's *shape* needs tuning, not more discipline from the people in it.
- **Validating a loop/gate change** — pair it with `plan-reviewer` (design-time) and `critical-reviewer` (code-time). This skill is the *why*; they are the *checks*.

## The parts
- `/principles/engineering-philosophy` — the judgment the loop applies (the principles, the two tiers).
- `/principles/verification-and-gates` — the spine, the Definition of Done, the 100%-regression invariant, the gate tables.
- `/principles/dev-loop` — the end-to-end flow, and how to tell which of the two loop models a repo uses.
- `/principles/permissions-and-environments` — the permission zones and the guard hook that make the deny-boundary mechanical.

Harness Engineering is these four run as **one designed system**, with Claude Code and Kiro as the hands. The plugin is the artifact; this discipline is how it is built and kept honest.
