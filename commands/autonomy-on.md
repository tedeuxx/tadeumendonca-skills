---
description: Drain the product backlog end to end — pick, build, review and merge slices without asking, stopping only where the owner's judgment is genuinely required
argument-hint: "[repo] (defaults to the current repo)"
---

Drain the product backlog of `$ARGUMENTS` (default: the current repo), one slice at a time, through
the full dev-loop, without asking permission for anything in-pattern.

**Done means: nothing is left that can be advanced without the owner.** Not "the backlog is empty" —
that is unachievable while any item needs a human, and a terminal condition you cannot reach is not
one. This one is checkable.

## The queue

Open issues labelled **`product`**. If the repo has no such label, say so and stop rather than
draining every open issue — a command that silently redefines its own scope is worse than one that
refuses.

**Do not invent an order.** `product-manager` owns sequencing (ADR-0002 amendment #5): starting a
slice that is not the top of the stated order requires that persona to have returned a new order, or
the session to record that the order is unchanged. Invoke it at session start; do not substitute a
heuristic here.

The bias it exists to correct, said plainly because it is invisible from inside: **sorting the queue
by what flows without a human is correct for safety and backwards for prioritisation.** It once
produced seventeen closed issues with not one from the owner's product queue.

## Decisions first, then work

Per `/principles/dev-loop`, "Opening a session": **collect the pending owner decisions across the
whole queue and ask them as a batch, before choosing what to build.** One conversation unblocks
everything at once; one question per slice produces one stall per slice.

That is the timing. What follows is the exception path for what you *discover* mid-slice.

## When a slice hits an owner decision it did not expect

1. **Do not stop.** Write the question **on the issue**, in the form the owner answers in one line,
   with the trade-off named.
2. **Decide whether the slice can still finish end to end.** The invariant is not negotiable: a slice
   is merged or it is not started. If the remainder is genuinely independent, cut the slice down to
   that and merge it, and let the blocked part become its own issue. If it is not, **close the branch
   and move on**, noting on the issue what was already built so it is not rebuilt — do not leave an
   unmergeable branch open. An open PR that cannot merge is the queue forming, which is the thing this
   loop exists to prevent.
3. Move to the next item, and surface the question at the next natural break rather than banking it
   to the end. A decision the owner could have answered an hour ago is latency you chose.

## Per slice — the loop, unchanged

Follow `/principles/dev-loop`. Nothing here relaxes it:

- Plan first for anything non-trivial; `plan-reviewer` before implementing a new mechanism.
- Thin vertical slice, end to end, finished **through merge** before opening the next.
- WIP is bounded per `/principles/dev-loop` — read it there rather than trusting a restatement, and
  note the guard enforcing it may lag the rule (`scrum-master` carries the caveat).
- Every gate green with real evidence, and the `critical-reviewer` on every PR. It merges the safe
  class and escalates the boundary class; a green CI is not a substitute for it.
- `brand-guardian` on reader-facing copy, `editor` on long-form prose. **Nothing enforces this
  dispatch** — no check, job or hook — so an undispatched lens fails silently. Where the repo's guide
  makes these the only review of copy, an undispatched one is the whole gate missing.
- File adjacent debt as its own issue rather than folding it in.

## What autonomy does NOT extend to

Unchanged, and this command grants nothing: pushing or merging to `main` outside the reviewer's
verdict, `terraform apply`/`destroy`, direct cloud mutation, force-push, `rm -rf`, secret writes,
`--dangerously-skip-permissions`. Autonomy is about **not asking on in-pattern work**, never about
widening the floor.

## Between dispatch and verdict

While a reviewer runs, **begin the next non-overlapping slice**. Do not end a turn with the next
action merely named — naming it and doing it are indistinguishable from outside, and a turn that ends
on a description reads as a stall.

If there is genuinely nothing disjoint to start, say so. *"Waiting on X, nothing disjoint in the
queue"* is honest status; silence is indistinguishable from being stuck.

## Reporting

Report **state**, not narration: how many `product` issues are open, how many merged this session,
what is blocked on the owner. A count is checkable; "making progress" is not.

**And do not report an act you have not performed.** A status report is the least gated artifact in
the loop — no check reads it, and the human reading it cannot verify it. Every claim in one is a claim
someone will act on.

## Stop when

- the unblocked queue is dry; or
- a slice reveals the plan behind it was wrong — a boundary event, with what changed; or
- the owner interrupts.
