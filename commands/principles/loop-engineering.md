Name and practice the discipline this whole plugin exists to run: **Agent Harness Engineering** (the owner's term for how he works; also **AI-DLC**, the AI-native Development Life Cycle). The other four `/principles/*` skills are its parts — `/principles/engineering-philosophy` is the judgment it applies, `/principles/verification-and-gates` is the gates it composes, `/principles/dev-loop` is the flow it drives, `/principles/permissions-and-environments` is the boundary it makes mechanical. This skill is the whole, named as one thing: **the AI-native development loop, treated as the engineered artifact.**

Context: $ARGUMENTS

## What Agent Harness Engineering is
Most teams point an AI coding tool at an unchanged process and write code faster inside it. Agent Harness Engineering inverts that: **the loop itself — how a change travels from intent to live, and every gate and guard along the way — is the thing you engineer.** The code is the output of a well-built loop, not the point. Run with **Claude Code and Kiro** as the hands, its spine is the platform spine — **agent-led verification, human-residual** (`/principles/verification-and-gates`): the agent proves "done" mechanically; the human is left only the irreversible/architectural residual.

The honest claim it makes (and the one it does **not**): *a development loop that turns AI-native techniques into production-ready software* — **not** agents running in production at scale. The loop is the track record; overclaiming the agents is off-discipline.

## The three surfaces this discipline engineers
The loop is a product with three surfaces, and this discipline owns their **design**, not their execution. The fleet executes (three leads consolidate one demand → `developer` builds → `quality-assurance` and `security` gate it); `product-lead` guards that the flow is *honest* (tracked, WIP-respected). What has no other owner is the loop **as a system**:

1. **Cadence & flow** — thin vertical slices bounded by file overlap, finish-through-merge. Not "is each slice tracked" (that is `product-lead`'s bookkeeping) but "is the loop *shaped* so work flows — is the human's residual small, and does the slice boundary fall where the human's attention is actually worth spending?" A loop that asks the human on in-pattern work is a **design defect**, not mere friction: the boundary is what the human's attention is *for*, and spending it elsewhere devalues it.
2. **The gates as a composed system** — the two gatekeepers (`quality-assurance` and `security`), the mechanical hooks (`permission-guard`, `wip-guard`, `session-wip`), the CI gates. The failure mode this discipline exists to catch is **a gate that verifies nothing**: a hook committed non-executable so it silently no-ops; a `build-test` job that prints PASS having run nothing; a logic test that exercises the guard through `bash "$GUARD"` and so never checks the *installed* form. A green that proves nothing is worse than a red. When you find one, you fix the **gate**, not just the finding.
3. **The harness as the artifact** — the agent fleet, the principles, and the hooks are themselves versioned, tested, and improved. A defect in the loop — an exec-bit lost on a guard so WIP enforcement silently dies; a `gh pr merge` back-door the methodology claimed was closed — is a bug in the *product*, filed and fixed like any other.

## The move that makes it a discipline, not a vibe
Every guarantee above is **mechanical or it is not real.** "The reviewer holds the merge gate" is Agent Harness Engineering only once a hook denies the merge to every context but the reviewer; until then it is an instruction the loop can break — and the same model that skipped a review is the one trusted to remember. The test, applied to any claimed property of the loop:

> *If this guarantee failed right now, would something stop me — or only my memory?*

If only memory, it is not engineered yet — it is an intention. This is exactly the standard the spine sets for "done" (trust the harness, not the agent's word); Agent Harness Engineering turns that standard on the loop itself.

## Before a loop change goes into execution — re-derive the state model

**Owner rule, 2026-08-02: every time the loop is re-evaluated, redo this assessment before executing it.**
Not once, and not only when the tracker is being touched — *every* time.

Three axes, and the third is the one that gets skipped:

1. **Issue TYPES** — what kinds of work exist, and what each implies for merge class.
2. **STATES per type** — every state an item passes through, not just `open` and `closed`.
3. **WHICH ROLE acts at each transition — and what ARTIFACT records that it happened.**

The whole assessment collapses into one question, asked once per rule the change introduces:

> **What observable artifact says this rule was applied?**
>
> If the answer is *"someone reads the item and judges"*, the rule has no state. It will be applied
> inconsistently, and — worse — inconsistently *and silently*, because there is nothing to audit.

### Why this is a rule rather than good practice

It was earned, immediately, by this file's own discipline failing to catch it. On 2026-08-02 the roster
was rebuilt and an intake chain was merged: *the owner generates demand → the three leads close the
issue's description → only then is it executable.*

**Nothing in the tracker could say whether a description had been closed.** `product-lead` had to read
every open issue and judge each one. The rule shipped **unobservable**, one day after being written —
and the section immediately above is about exactly that failure, one level down. *A gate that verifies
nothing* has a sibling: **a rule that has no state.** The section's own test catches it if you think to
apply it upward: *if this guarantee failed right now, would something stop me — or only my memory?*
Nothing would stop anyone from building an unfinished issue.

**The bias this corrects, because it is invisible from inside.** A loop change is written as
**behaviour** — who does what, in what order — and behaviour reads as *complete* the moment the sentence
is well-formed. The states are what make it auditable later, and they are exactly what a well-written
behavioural rule does not force you to think about.

### Keep the remedy to one bit

The fix is almost never a workflow. **Do not add a state that duplicates something already observable** —
an open PR already says "in progress", and a state that restates existing information is one more thing
that can lie. Prefer the smallest label set that makes each rule's precondition **queryable**, and if a
rule needs no new state, say so explicitly rather than leaving the axis unexamined.

## When to reach for this
- **Standing up the loop** in a new repo, or picking the loop model (`/principles/dev-loop` — the two models).
- **A gate feels like theater**, or a green does not sit right — audit whether it verifies what it claims (widen the assertion to the installed form; make the "did the reviewer run?" a precondition, not a hope).
- **The human is asked too often**, or WIP is piling — the loop's *shape* needs tuning, not more discipline from the people in it.
- **Validating a loop/gate change** — pair it with `tech-lead` (design-time, against the principles and the ADR library) and `quality-assurance` (code-time, against the Definition of Done). This skill is the *why*; they are the *checks*. This line named `plan-reviewer` for the design-time half until 2026-08-03; that persona was retired outright and invoking it fails, but the review it did was **absorbed rather than dropped** — `tech-lead` owns the decision, writes its record, and flags significance at intake.

## The parts
- `/principles/engineering-philosophy` — the judgment the loop applies (the principles, the two tiers).
- `/principles/verification-and-gates` — the spine, the Definition of Done, the 100%-regression invariant, the gate tables.
- `/principles/dev-loop` — the end-to-end flow, and how to tell which of the two loop models a repo uses.
- `/principles/permissions-and-environments` — the permission zones and the guard hook that make the deny-boundary mechanical.

Agent Harness Engineering is these four run as **one designed system**, with Claude Code and Kiro as the hands. The plugin is the artifact; this discipline is how it is built and kept honest.
