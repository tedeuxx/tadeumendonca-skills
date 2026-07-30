---
description: Drain the product backlog end to end — pick, build, review and merge slices without asking, stopping only where the owner's judgment is genuinely required
argument-hint: "[repo] (defaults to the current repo)"
---

Drain the product backlog of `$ARGUMENTS` (default: the current repo), one slice at a time, through
the full dev-loop, without asking permission for anything in-pattern.

## What this command can and cannot do — read this before relying on it

**It is a prompt, not a mechanism.** It cannot force the loop to continue; only a hook can force
anything. What it buys is that the *ordering* and the *blocked-item rule* are written down instead of
improvised, which is where the loop was actually failing.

**"Until the backlog is empty" is not achievable and must not be promised.** Some items require the
owner — an irreversible act, a positioning call, a decision about what the product should be. A
command that promises to zero the queue will collide with the boundary rule within minutes, and the
honest terminal state is different:

> **Done means: nothing is left that can be advanced without the owner.**

That state is real and checkable. "Backlog empty" is not.

## The queue

Open issues labelled **`product`**. That label already separates the site-as-software from `content`
(articles, which need the owner's voice and are out of scope here).

Order by: **unblocks-other-work** first, then **reader-visible value**, then **cost to revert**
(cheap-to-revert earlier). When two are close, take the smaller — a merged slice beats a better plan.

Do not reorder to avoid the owner. **That bias is the specific failure this command exists to
correct**: sorting the queue by what flows without a human is correct for safety and backwards for
prioritisation, and it once produced seventeen closed issues with not one from the product queue.

## The rule for a blocked item — the load-bearing part

When a slice needs the owner (irreversible, positioning, product-shape, or a fact only they hold):

1. **Do not stop.** Do not ask yet.
2. Write the question **on the issue**, in the form the owner can answer in one line, with the
   trade-off named. Label it so it is findable.
3. Do everything on that issue that does *not* depend on the answer. A blocked decision rarely blocks
   the whole slice.
4. Move to the next unblocked item.
5. **Accumulate** the questions. Deliver them **one at a time**, when the unblocked queue runs dry —
   not as a list, and not interleaved with the work.

This respects *ask on the boundaries and only there* without turning every boundary into a stop.

## Per slice — the loop, unchanged

Follow `/principles/dev-loop`. Nothing here relaxes it:

- Plan first for anything non-trivial; `plan-reviewer` before implementing a new mechanism.
- Thin vertical slice, end to end, finished **through merge** before opening the next.
- WIP is bounded by **file overlap**, not by count — a slice touching no open PR's files may start now.
- Every gate green with real evidence, and the `critical-reviewer` on every PR. It merges the safe
  class and escalates the boundary class; a green CI is not a substitute for it.
- `brand-guardian` on reader-facing copy, `editor` on long-form prose.
- File adjacent debt as its own issue rather than folding it in.

## What autonomy does NOT extend to

Unchanged, and this command grants nothing here: pushing or merging to `main` outside the reviewer's
verdict, `terraform apply`/`destroy`, direct cloud mutation, force-push, `rm -rf`, secret writes,
`--dangerously-skip-permissions`. Reader-facing content still reaches the owner for ratification —
autonomy is about **not asking on in-pattern work**, never about widening the floor.

## Between dispatch and verdict

While a reviewer runs, **begin the next non-overlapping slice**. Do not end a turn with the next
action merely named — naming it and doing it are not the same thing from the outside, and a turn that
ends on a description reads as a stall.

If there is genuinely nothing disjoint to start, say so explicitly. *"Waiting on X, nothing disjoint
in the queue"* is honest status; silence is indistinguishable from being stuck.

## Reporting

Report **state**, not narration: how many `product` issues are open, how many merged this session, and
what is blocked on the owner. A count is checkable; "making progress" is not.

## Stop when

- the unblocked queue is dry — then deliver the accumulated questions, one at a time; or
- a slice reveals that the plan behind it was wrong, which is a boundary event and goes to the owner
  with what changed; or
- the owner interrupts.
