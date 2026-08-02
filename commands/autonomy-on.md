---
description: Drain the product backlog end to end — pick, build, review and merge slices without asking, stopping only where the owner's judgment is genuinely required
argument-hint: "[repo] (defaults to the current repo)"
---

Drain the product backlog of `$ARGUMENTS` (default: the current repo), one slice at a time, through
the full dev-loop, without asking permission for anything in-pattern.

**Done means: no open issue outranks the cost of the session continuing.** See *Stop when* below for why
the two earlier answers — *"the backlog is empty"* and *"nothing is left that can be advanced without the
owner"* — were both wrong, and wrong in different directions.

## The queue

Open issues labelled **`product`** **and `ready`**. If the repo has no such label, say so and stop
rather than draining every open issue — a command that silently redefines its own scope is worse than
one that refuses.

**`ready` means the three leads closed the description** (`/principles/dev-loop`, *Intake*). An Issue
without it is in the tracker but not executable, and the right move is to say so and run the intake pass
— not to build it and discover the missing requirement at the gate.

**This command currently REFUSES to run on the harness repo, and that is a real gap rather than a
quirk.** `tadeumendonca-skills` has no `product` label: it carries a 24-label taxonomy (`type:*`,
`phase:*`, `priority:*`, `semver:*`, `status:blocked`) of which four labels are used, on four Issues,
while **29 of its 33 Issues carry no label at all**. So the repo whose whole purpose is the loop cannot
be drained by the command that drains loops — its backlog gets worked by someone reading and judging,
which is precisely the failure the `ready` state exists to remove.

Found by the first run of the state-model assessment (`/principles/loop-engineering`). Recorded here
rather than fixed silently, because reconciling the two taxonomies is a decision about how work is
classified and belongs to the owner.

**Do not invent an order.** `product-lead` owns sequencing (ADR-0002 amendment #5): starting a
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

- Plan first for anything non-trivial; the three leads consolidate **one** demand before the build.
- Thin vertical slice, end to end, finished **through merge** before opening the next.
- WIP is bounded per `/principles/dev-loop` — read it there rather than trusting a restatement, and
  note the guard enforcing it may lag the rule (`product-lead` carries the caveat).
- Every gate green with real evidence, and the `quality-assurance` on every PR. It merges the safe
  class and escalates the boundary class; a green CI is not a substitute for it.
- `marketing-lead` on reader-facing copy, long-form prose included. **Nothing enforces this
  dispatch** — no check, job or hook — so an undispatched lens fails silently. Where the repo's guide
  makes these the only review of copy, an undispatched one is the whole gate missing.
- Adjacent debt is **named in the report**, never filed *by the review* — a subagent has no way to
  know whether anyone wants the work, and the guard denies it outright. The **main loop may open
  issues**, and should: recording something the owner asked for is not generating demand. The guard
  asks rather than denies there, so the owner decides per issue. See `/principles/dev-loop`,
  *Review does not open work* — which is about reviews, not about the queue being unwritable.

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

## Report in delivery, not in issues closed

**Every session report states product slices against hygiene slices.** *"Ten issues closed"* sounded
like progress on the day it was measured; the honest ruler said **3 of 12** (#104).

- **A product slice** is one where a reader can **do, see or read something different**.
- **A hygiene slice** is everything else — comments, dead code, a test mechanism, a process rule, a
  README. Internal correctness is not delivery, however good; it is the cost of being able to deliver
  again.

**A session with zero product slices is a finding, not a status.** Say it in those words.

This is a **measurement, not a process** — it adds no step, blocks nothing and needs nobody's approval.
That is what makes it agile rather than ceremony, and it is why it earns its place: rules can be argued
with, an outcome that is visible cannot be closed without someone noticing.

*Why the bias needs a counterweight at all:* hygiene work is cheap to justify — found in context,
evidence attached, safe class, merges without the owner — while product work needs decisions and
sometimes the owner's own words. The autonomy gradient therefore sorts the queue by what flows without
a human, which is exactly backwards from what a backlog is for.

**Pick up hygiene when it BLOCKS a product slice, or in one deliberate bounded batch.** Not
opportunistically.

## Stop when

- **no open issue outranks the cost of continuing** — see below; or
- a slice reveals the plan behind it was wrong — a boundary event, with what changed; or
- the owner interrupts.

### Why the terminal condition changed (#103)

~~*the unblocked queue is dry*~~ **cannot be a terminal condition, and the arithmetic is one line.**
If each slice yields on average more than one new unblocked issue, the unblocked queue never dries up
and this command runs forever. Measured on the day it was raised: **32 issues created against 13 closed
across both repos in one session — net +19**, with roughly 13 of the 32 produced by *reviewing something
else* rather than by requested value.

**Worse, that condition is anti-correlated with execution quality.** A sharper reviewer finds more per
MR; more findings become more issues; the queue grows faster. The better the loop works, the less it
terminates.

It replaced *"until the backlog is empty"* (#97) on the argument that the first fails because of the
**human** and is therefore unreachable. True, and it shipped a version that fails because of the
**loop** — which is worse, because it looks reachable.

**What makes the new condition reachable is the pruning step** (`/principles/dev-loop`, *Closing an
issue is a step*): a loop that only ever adds has no terminal state at any threshold. With a closing
criterion, the queue can shrink, and "no open issue outranks the cost of continuing" becomes a real
question rather than a formality.

**Named residual:** that judgement is not mechanical. It is the honest shape — the alternative is
another arithmetic condition, and this section is what an arithmetic condition that looked reachable
cost.
