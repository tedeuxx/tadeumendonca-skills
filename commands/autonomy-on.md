---
description: Drain a repo's ready product backlog end to end without asking — pick, build, review and merge slices one at a time, stopping only where the owner's judgment is genuinely required. Use when the owner says to work the backlog or keep going, when several ready issues are queued, or when in-pattern work keeps stalling for permission. Not for capturing a new request (see new-issue).
argument-hint: "[repo] (defaults to the current repo)"
---

Drain the product backlog of `$ARGUMENTS` (default: the current repo), one slice at a time, through
the full dev-loop, without asking permission for anything in-pattern.

**Done means: no open issue outranks the cost of the session continuing.** See *Stop when* below for why
the two earlier answers — *"the backlog is empty"* and *"nothing is left that can be advanced without the
owner"* — were both wrong, and wrong in different directions.

## The queue

Open issues labelled **(`product` OR `loop`)** **and `ready`**. If the repo has no such label, say so and stop
rather than draining every open issue — a command that silently redefines its own scope is worse than
one that refuses.

**`ready` means the leads closed the description** (`/harness-engineering`, *Intake*; the generic bar
a description must clear to earn that label is `/definition-of-ready`). An Issue
without it is in the tracker but not executable, and the right move is to say so and run the intake pass
— not to build it and discover the missing requirement at the gate.

~~**This command currently REFUSES to run on the harness repo.**~~ **It did until 2026-08-02, and the
fix landed in the same slice that found it.** The first run of the state-model assessment
(`/harness-engineering`) turned up that `tadeumendonca-skills` had no `product` label at all —
it carried a separate 24-label taxonomy that was almost entirely unused — so the repo whose whole
purpose is the loop could not be drained by the command that drains loops. Its backlog got worked by
someone reading and judging, which is the failure the `ready` state exists to remove.

The owner reconciled both repos to one vocabulary (`/harness-engineering`, *One vocabulary across every
repo*), so **this command now runs on either repo.** Kept as a correction rather than deleted, because
the gap is the evidence for why the assessment is a standing rule.

**Do not invent an order.** `product-lead` owns sequencing (ADR-0002 amendment #5): starting a
slice that is not the top of the stated order requires that persona to have returned a new order, or
the session to record that the order is unchanged. Invoke it at session start; do not substitute a
heuristic here.

The bias it exists to correct, said plainly because it is invisible from inside: **sorting the queue
by what flows without a human is correct for safety and backwards for prioritisation.** It once
produced seventeen closed issues with not one from the owner's product queue.

## Decisions first, then work

Per `/harness-engineering`, "Opening a session": **collect the pending owner decisions across the
whole queue and ask them as a batch, before choosing what to build.** One conversation unblocks
everything at once; one question per slice produces one stall per slice.

**In the same session-open report, read the open queue and name what is stale** — anything with no
activity for weeks, and anything carrying no ADR-0002 routing label at all.

Measured on 2026-08-23 in the consuming product repo — the criterion is *open, not labelled `content`,
`updatedAt` on or before 2026-08-08* — with the command run from inside that repo:

```
gh issue list --state open --limit 100 --json number,updatedAt,labels
```

(The measurement itself was taken from this repo with `--repo <owner>/<product>` appended, which is the
same query — the flagless form is published because it names no consumer.) **Five** issues meet it —
**#380, #381, #385, #390, #127** — plus **#431**, opened 2026-08-13 with **no
routing label at all**, which makes it invisible to every type-selecting query this loop runs, the queue
above included. **`--limit 100` is part of the claim, not tidiness:** the default page is 30 against 32
open issues, so the same command without it silently drops the tail — which is where stale items live.

**Why the line belongs here and nowhere else.** Nothing in the loop reads the open queue: every
`gh issue` call in `hooks/scripts/` is a write path. `/harness-engineering`'s *"Closing an issue is a
step, with a criterion"* already specifies the pruning pass and gives it **no trigger** — a mandate with
no trigger, which is the shape this repo names as a document rather than a mechanism. Naming staleness at
session open is the trigger, and it is the cheapest one: the session is already reading the queue to pick
a slice.

**Named the honest way: this is prose, not a mechanism.** No hook fires it and no artifact records that it
ran, so a session that skips it looks exactly like one that found nothing stale. A `SessionStart` reporter
would close that, and it is deliberately not built here — the line is useful the day it lands, the
reporter is a convenience over it.

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

Follow `/harness-engineering`. Nothing here relaxes it:

- Plan first for anything non-trivial; the two leads consolidate **one** demand before the build.
- Thin vertical slice, end to end, finished **through merge** before opening the next.
- WIP is bounded per `/harness-engineering` — read it there rather than trusting a restatement, and
  note the guard enforcing it may lag the rule (`product-lead` carries the caveat).
- Every gate green with real evidence, and the `quality-assurance` on every PR. It merges the safe
  class ~~and escalates the boundary class~~ **and the boundary class, escalating only the four holds
  named in `agents/quality-assurance.md` (ADR-0002 amendment #16)**; a green CI is not a substitute
  for it. **What that changes for an autonomous run:** a content or loop slice no longer parks waiting
  for the owner — it ships, and the owner reviews it live. So the thing to surface at the next natural
  break is *what went live*, not *what is waiting*.
- `product-lead` on reader-facing copy, long-form prose included — it holds the copy lens since
  `marketing-lead` merged into it (2026-08-04), and its **truth findings block**. **Nothing enforces this
  dispatch** — no check, job or hook — so an undispatched lens fails silently. Where the repo's guide
  makes this the only review of copy, an undispatched one is the whole gate missing.
- Adjacent debt is **named in the report**, never filed *by the review* — a review has no way to
  know whether anyone wants the work, and the guard denies it. *(Since #124 the guard exempts
  `developer`, so "denies every subagent" is no longer accurate — but a **review** is still denied,
  which is the case this bullet is about.)* The **main loop may open
  issues**, and should: recording something the owner asked for is not generating demand. The guard
  asks rather than denies there, so the owner decides per issue. See `/harness-engineering`,
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
and **what is blocked on the owner — by querying the `blocked` label, not by re-reading the queue**
(`gh issue list --label blocked`). A count is checkable; "making progress" is not, and a list derived by
reading twelve Issues is neither reproducible nor auditable.

That query is what the label is FOR, and saying so here is not decoration: the vocabulary's own test is
that something must read a label or it is not classification. Before this, "what needs the owner" was
assembled by judgement each time, which is how the same four items get described differently in two
consecutive reports.

**And do not report an act you have not performed.** A status report is the least gated artifact in
the loop — no check reads it, and the human reading it cannot verify it. Every claim in one is a claim
someone will act on.

### Do not hand the owner a PR link he cannot act on

**The rule is his sentence, and it ships as his sentence rather than as a paraphrase of it (#327):**

> *"eu apenas quero receber links de PR quando tiver pronto para merge com todos check concluidos com
> sucesso"*

**The condition is CONJUNCTIVE**: *ready to merge* **and** *every check complete and successful*. A PR
whose pipeline is still running does not qualify however green it looks so far; a red pipeline is the
loop's to fix without involving him.

**Mechanically, "ready for him" is one verdict literal, not a hold count.** `agents/quality-assurance.md`'s
*"Your verdict — exactly one of"* enumerates four, and exactly one of them means the remaining act is
the owner's: **`APPROVE-PENDING-HUMAN`**, posted when one of the four surviving holds fired.
`REQUEST-CHANGES` is also non-merging and is emphatically *not* an owner summons — it routes to the
builder. `APPROVE-AND-MERGE` and `APPROVE-AND-MERGE-BOUNDARY` are clearances the gate acts on itself
(ADR-0002 amendment #16), which is why almost every open PR is one he has nothing to do with.

**The rule is about DIRECTING HIS ATTENTION, not about the character sequence** — and the distinction is
load-bearing rather than pedantic. `gh pr create` prints the PR URL as its own stdout: measured on #327,
tool-result blocks carry the identical five PR URLs at identical counts as the prose blocks. A rule
written against the string would forbid nothing and would fail open exactly where it looked strictest.
A URL the owner watched a tool emit is not a summons; one you **hand** him is. Report **state** in
prose — what shipped, what is in flight, what is blocked — and reach for a bare `#NNN` where an item
needs naming.

**What this rule removes, said plainly because he took the trade knowingly.** The premature PR link was
the informal substitute for an artifact ADR-0002 amendment #16 already books as missing: *"the owner
reviews live, after deploy" has no artifact*. Crude and noisy, but it was how he learned something had
shipped. Removing it without a replacement makes that named residual bite, on published copy in his
voice. The replacement — a boundary-merge notification — was scoped **out** of #327 on his own call.
The argument is ADR-0002's eighteenth amendment.

**Enforcement, and its exact limits.** `hooks/scripts/premature-pr-link-detect.sh` is a `Stop` hook that
reads the turn's own assistant prose and flags a PR URL whose PR is not open-green-and-pending-human. It
is **detection, never prevention** — it fires after the text has already reached him, so it makes the
mistake visible in the same turn rather than a session later. And it matches **full URLs only**: GitHub
shares one number space between Issues and PRs, so a bare `#508` cannot be classified without a network
call. **The form this rule recommends is the form the hook cannot check.** Read a silent turn as
"nothing was measured", never as "the rule was kept".

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

**What makes the new condition reachable is the pruning step** (`/harness-engineering`, *Closing an
issue is a step*): a loop that only ever adds has no terminal state at any threshold. With a closing
criterion, the queue can shrink, and "no open issue outranks the cost of continuing" becomes a real
question rather than a formality.

**Named residual:** that judgement is not mechanical. It is the honest shape — the alternative is
another arithmetic condition, and this section is what an arithmetic condition that looked reachable
cost.
