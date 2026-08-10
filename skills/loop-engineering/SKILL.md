---
description: Name and practise Agent Harness Engineering (also AI-DLC) — the AI-native development loop treated as the engineered artifact, its three surfaces, and the rule that a loop change re-derives its state model before execution. Use when proposing a change to the harness itself, deciding whether a remedy belongs in a hook or in a brief, or naming this discipline in public writing. Not for the day-to-day flow a slice travels (see dev-loop).
family: principles
---

Name and practice the discipline this whole plugin exists to run: **Agent Harness Engineering** (the owner's term for how he works; also **AI-DLC**, the AI-native Development Life Cycle). The other four `/principles/*` skills are its parts — `/engineering-philosophy` is the judgment it applies, `/verification-and-gates` is the gates it composes, `/dev-loop` is the flow it drives, `/permissions-and-environments` is the boundary it makes mechanical. This skill is the whole, named as one thing: **the AI-native development loop, treated as the engineered artifact.**

Context: $ARGUMENTS

## What Agent Harness Engineering is
Most teams point an AI coding tool at an unchanged process and write code faster inside it. Agent Harness Engineering inverts that: **the loop itself — how a change travels from intent to live, and every gate and guard along the way — is the thing you engineer.** The code is the output of a well-built loop, not the point. Run with **Claude Code and Kiro** as the hands, its spine is the platform spine — **agent-led verification, human-residual** (`/verification-and-gates`): the agent proves "done" mechanically; the human is left only the irreversible/architectural residual.

The honest claim it makes (and the one it does **not**): *a development loop that turns AI-native techniques into production-ready software* — **not** agents running in production at scale. The loop is the track record; overclaiming the agents is off-discipline.

## The three surfaces this discipline engineers
The loop is a product with three surfaces, and this discipline owns their **design**, not their execution. The fleet executes (the leads consolidate one demand → `developer` builds → `quality-assurance` gates it); `product-lead` guards that the flow is *honest* (tracked, WIP-respected). What has no other owner is the loop **as a system**:

1. **Cadence & flow** — thin vertical slices bounded by file overlap, finish-through-merge. Not "is each slice tracked" (that is `product-lead`'s bookkeeping) but "is the loop *shaped* so work flows — is the human's residual small, and does the slice boundary fall where the human's attention is actually worth spending?" A loop that asks the human on in-pattern work is a **design defect**, not mere friction: the boundary is what the human's attention is *for*, and spending it elsewhere devalues it.
2. **The gates as a composed system** — the gatekeeper (`quality-assurance`, holding delivery and production-risk in one pass since `security` was absorbed into it on 2026-08-04), the mechanical hooks (`permission-guard`, `wip-guard`, `session-wip`, `session-plugin-version`), the CI gates. The failure mode this discipline exists to catch is **a gate that verifies nothing**: a hook committed non-executable so it silently no-ops; a `build-test` job that prints PASS having run nothing; a logic test that exercises the guard through `bash "$GUARD"` and so never checks the *installed* form. A green that proves nothing is worse than a red. When you find one, you fix the **gate**, not just the finding.
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
was rebuilt and an intake chain was merged: *the owner generates demand → the leads close the
issue's description → only then is it executable.* (As merged that day the leads numbered three;
`marketing-lead` folded into `product-lead` on 2026-08-04 and they number two. The chain is unchanged —
what changed is who is in it, which is exactly the kind of drift the section below is about.)

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
- **Standing up the loop** in a new repo, or picking the loop model (`/dev-loop` — the two models).
- **A gate feels like theater**, or a green does not sit right — audit whether it verifies what it claims (widen the assertion to the installed form; make the "did the reviewer run?" a precondition, not a hope).
- **The human is asked too often**, or WIP is piling — the loop's *shape* needs tuning, not more discipline from the people in it.
- **Validating a loop/gate change** — pair it with `tech-lead` (design-time, against the principles and the ADR library) and `quality-assurance` (code-time, against the Definition of Done). This skill is the *why*; they are the *checks*. This line named `plan-reviewer` for the design-time half until 2026-08-03; that persona was **retired outright** and invoking it fails. `tech-lead` is not its successor — it owns architecture decisions on its own account, writes their records, and flags significance at intake.
- **Proposing a change to the MACHINERY — dispatch `harness-reviewer` before implementing it.** This is the persona of this discipline: added 2026-08-04 as the owner's pair in their *harness-engineer* role, on hooks, settings and permissions, agent briefs, skills, commands, the plugin and MCP. It returns the scenarios a proposal does not cover, each with **how to check it or labelled a hypothesis**, and its standing question is ADR-0008's — *which layer can actually carry this control, and can that layer hold it?* It is **advisory and pre-implementation**: it gates nothing, reviews no merge request, merges nothing and opens no Issue, so it never sits in the intake chain the leads run (`/dev-loop`).

  **Why the two lines above are not the same dispatch, since both sound like "validate a change".** `tech-lead` and `quality-assurance` judge a change *to the product*, against records and against a Definition of Done. `harness-reviewer` judges a change *to the loop that judges the product*, and the failure it exists to catch is not a wrong decision but an **inert** one — a deny on a tool no hook observes, a glob that does not reach the second repo of a two-repo workspace, a persona merged while a third still runs the brief that predates the merge. Four of those were found in a single day, all by accident, all after implementation.

  *Its stated cost, because this skill's own rule is that a gate which verifies nothing is worse than a red:* **nothing enforces this dispatch and no gate stands behind it.** An undispatched lens is indistinguishable from a clean one. It is worth exactly as much as the habit of invoking it — which is why it is written here, in the skill you open when you are about to change the loop.

## The parts
- `/engineering-philosophy` — the judgment the loop applies (the principles, the two tiers).
- `/verification-and-gates` — the spine, the Definition of Done, the 100%-regression invariant, the gate tables.
- `/dev-loop` — the end-to-end flow, and how to tell which of the two loop models a repo uses.
- `/permissions-and-environments` — the permission zones and the guard hook that make the deny-boundary mechanical.

Agent Harness Engineering is these four run as **one designed system**, with Claude Code and Kiro as the hands. The plugin is the artifact; this discipline is how it is built and kept honest.
