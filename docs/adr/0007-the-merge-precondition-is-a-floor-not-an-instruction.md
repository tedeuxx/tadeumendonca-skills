# 0007. The merge precondition is a floor, not an instruction

- **Status:** proposed
- **Date:** 2026-08-03
- **Deciders:** owner (ratifies) · `quality-assurance` and `security` (both subject to it)
- **Supersedes / superseded by:** —
- **Driven by:** the sweep in #137's sibling assessment; the drift recorded in [ADR-0006](./0006-a-verdict-owed-to-another-persona-is-an-artifact.md) and in #135/#136

## Context & problem

[ADR-0006](./0006-a-verdict-owed-to-another-persona-is-an-artifact.md) fixed the right half of a problem: a verdict owed to another persona now exists as a **comment on the PR** rather than as prose in an orchestrator's context, so it can be read rather than relayed.

What it did not fix is the other half. **The rule that reads that artifact is itself prose**, living in `agents/quality-assurance.md` — *do not merge until `security` has returned an approval; verify three conditions; a relay is not the authority*. It is an instruction to a model, executed by the same model it constrains, in a file that model also edits.

That is not hypothetical. In a single day, three separate drifts shipped in the vocabulary this rule depends on:

- `security.md` offered `ADVISORY-ONLY`, a literal the file never defined, and the merging gate checked against it — one invented literal live in two files
- `security.md` also read *"Lead with the verdict: clean, remediated, or blocked"* three sections below its own marker template — a third vocabulary, and the one that **actually fired**: a verdict line was once posted reading `CLEAN`, which the reading gate cannot parse
- `quality-assurance.md`'s own marker offered `APPROVED` while the set it defines is `APPROVE-AND-MERGE` / `APPROVE-PENDING-HUMAN` / `REQUEST-CHANGES`

All three were found by reading — by two gatekeepers and by the owner, across eight rounds of one PR and two of another. **None could have been found by a check**, and re-introducing any of them today goes green.

The deeper point is not the vocabulary. It is that **the strongest rule in the loop is enforced by the weakest mechanism available**. The harness offers several, and they are not interchangeable:

| mechanism | runs | can deny | sees |
| --- | --- | --- | --- |
| **hook** (`hooks.json` + script) | outside the model, on a tool call | **yes** | the tool call and live system state |
| **settings permission** | outside the model, on a matcher | yes | the command string only |
| **agent** (`agents/*.md`) | as a model, fresh context | no — it decides | whatever it reads |
| **skill / command** (`commands/*.md`) | as context, on invocation | no | whatever it is given |
| **`CLAUDE.md`** | as always-on context | no | static text |

`permission-guard.sh` already sits in the top row and is the reason the irreversible floor holds: no amount of misreading lets an agent `terraform destroy`. **The merge precondition has the same character — a floor whose violation is not recoverable — and sits three rows down.**

## Decision drivers

- A rule whose violation ships to production must not depend on the constrained party reading it correctly.
- The three drifts above shared one shape: **the file said one thing and meant another, and nothing outside the file could tell.**
- There is a definite interception point. A merge is a `gh pr merge` invocation — a Bash tool call, which is where `PreToolUse` already fires twice.
- Whatever moves must not make the loop wedge. `wip-guard.sh` fails **open** deliberately; a discipline check that stops work is worse than the drift it prevents.
- Judgement must stay with the gate. Whether a change is *right* is not mechanisable and this decision must not pretend otherwise.

## Considered options

1. **A `PreToolUse` hook on `gh pr merge` that denies a merge lacking its preconditions** (chosen) — the hook reads the PR's comments and head, and denies unless both gatekeeper markers parse at the current `headRefOid`, plus the owner's ratification for the boundary class. *Trade-off:* a second network-dependent hook, and it forces the fail-open/fail-closed question to be answered explicitly rather than inherited.

2. **Keep it prose, and add the assertion from #136** — pin each persona's marker literals to its own canonical verdict set. *Why not:* it is worth doing and it is **not this**. That assertion proves the **file says** the right thing. It cannot prove the **gate did** the right thing at merge time — a gate that reads a perfectly consistent file and merges anyway is exactly the failure mode, and #136 is blind to it. Complementary, not a substitute.

3. **A `settings.json` deny rule on `gh pr merge`** — block the command outright and route every merge to the human. *Why not:* it deletes the safe class, which is the mechanism that makes the loop flow. The owner's 2026-07-30 decision moved reader-facing work *out* of the boundary class precisely to stop spending their attention on in-pattern merges; this would undo that wholesale to fix a narrower problem.

4. **A required GitHub status check** — enforce it at the forge rather than in the harness. *Why not:* the markers are comments, and a check would have to be posted by the same token the gatekeepers write with, so it inherits the impersonation residue ADR-0006 already records **without** gaining the interception. It also only works where branch protection does; `main` here is the working branch.

## Decision outcome

Chosen: **option 1**, because it is the only one that binds the party the rule addresses. The other three all assume the gate reads its own instructions correctly, which is the assumption that failed three times in one day.

**Fail OPEN, and this is the deliberate part.** The reflex is to say a floor fails closed, and `permission-guard.sh` is invoked as the precedent. That reasoning does not survive contact with what the two hooks actually protect:

- `permission-guard.sh` denies things that are **irreversible in the world** — `terraform destroy`, a force-push, a secret write. A missed deny is unrecoverable; a spurious deny costs a retry.
- This hook denies a merge that **has not yet been reviewed**. A missed deny produces a merge the gatekeepers would very likely have approved anyway, on a repo whose deploy is revertible. A spurious deny — no network, `gh` unauthenticated, the API slow — **wedges every merge in the loop**, which is the failure this whole architecture exists to avoid.

So it fails open on any error it cannot resolve, exactly as `wip-guard.sh` does, and for the same reason. **An answer we could not get is not a verdict.** What it must never do is fail open *silently*: an unresolved check prints what it could not determine.

**What does not move.** The gate's judgement stays in `agents/quality-assurance.md` — whether the Issue's requirements were met, whether the class is safe or boundary, whether a finding blocks. The hook checks that the **artifacts exist and match the head**; it has no opinion about whether they are right.

## Consequences

**Good**
- The precondition holds even when the gate misreads its own file — which is the observed failure, not a theoretical one.
- The three drifts above become unable to produce a bad merge. A marker whose verdict line is unparseable stops the merge instead of being interpreted.
- The rule gains a single mechanical definition. Today it exists as prose in one persona file and is *described* in another, and those two can disagree without either being wrong.

**Bad / accepted costs**
- **A second network-dependent `PreToolUse` hook on every Bash call.** `wip-guard.sh` already pays this and is budgeted at 10s. Two hooks doing `gh` calls on unrelated Bash commands is real latency for no benefit on the ~99% of calls that are not merges, so the hook must exit before any network work when the command is not a merge.
- **Fail-open means this is not airtight**, and saying "floor" could imply otherwise. It raises the cost of the failure from *zero* to *needing the network to be down at the same moment*. That is a large improvement and it is not a guarantee; anyone reading "floor" here should read the paragraph above it.
- **The impersonation residue is unchanged.** The hook reads comments written with the same token the agent holds, so a determined agent could still write both markers. ADR-0006 already records this and accepts it: the adversary this architecture addresses is **drift by a trusted party**, not hostility. This hook is squarely aimed at drift.
- **Two mechanisms now encode part of one rule** — the hook (artifacts present and current) and the persona file (what they mean). That is the split this ADR argues for, but it is still a seam, and a change to the marker shape must move both.

## Links
- [ADR-0006](./0006-a-verdict-owed-to-another-persona-is-an-artifact.md) — the verdict as artifact; this ADR enforces what that one made readable
- [ADR-0003](./0003-mr-definition-of-done.md) — the DoD the gate reviews against, and the ratification rule this hook would also check
- [ADR-0004](./0004-autonomy-and-permission-model.md) — the permission floor and `permission-guard.sh`, the sibling hook whose fail-closed rule this one deliberately does not inherit
- #136 — pinning marker literals to each persona's canonical set; complementary, and explicitly not a substitute
