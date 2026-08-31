---
description: Drain a repo's ready product backlog end to end without asking — pick, build, review and merge slices one at a time, stopping only where the owner's judgment is genuinely required. Use when the owner says to work the backlog or keep going, when several ready issues are queued, or when in-pattern work keeps stalling for permission. Not for capturing a new request (see new-issue).
purpose: drain an iteration's ready pool without asking on in-pattern work, so the loop stops paying one stall per slice for permission it has already been given
argument-hint: "[repo] (defaults to the current repo)"
---

Drain the product backlog of `$ARGUMENTS` (default: the current repo), one slice at a time, through
the full dev-loop, without asking permission for anything in-pattern.

**Done means: the drain's ENTRY SNAPSHOT of the active iteration's pool is exhausted** (#326, amended
#338 — the iteration's pool grows while it drains, so the snapshot is what terminates and the iteration is
not). See *Stop when* below for why the three
earlier answers — *"the backlog is empty"*, *"nothing is left that can be advanced without the owner"*,
and ~~*"no open issue outranks the cost of the session continuing"*~~ — were each wrong, and wrong in
different directions. **The third was not wrong about the whole `ready` queue**, which is what it was
written against; it stopped being the drain's condition when the drain stopped working that queue, and it
survives as the question **planning** asks.

## The queue

Open issues labelled **(`product` OR `loop`)** **and `ready`** — **and carrying the ACTIVE ITERATION'S
milestone** (#326). If the repo has no such label, say so and stop
rather than draining every open issue — a command that silently redefines its own scope is worse than
one that refuses.

**The active iteration is derived from the pool, never from a date, and the milestone name is never
typed.** The canonical wording, the predicate, and the measurement behind the tracker object are
`/agents-configuration`'s *The iteration is the unit of work* — read them there rather than trusting a
restatement here. What this command owes on top of that is one line of its own:

> **Report the count of `ready` items carrying NO milestone, at session open.**

~~from the same query~~ — **struck 2026-08-30 (#365): those three words made this line unrunnable, and
it is a falsifier that FAILS OPEN, which is the worst shape a check can have.** "The same query" is the
pool predicate, whose first filter is `select(.milestone!=null)`; items with no milestone are excluded
from it by construction, so a reader following the sentence literally gets an empty result and reads it
as *nothing to worry about*. The predicate is its own, and it is published here rather than described:

```
gh issue list --repo <owner>/<repo> --state open --limit 200 --json number,labels,milestone \
  --jq '[.[]|select(.milestone==null)
          |select(.labels|map(.name)|index("ready"))
          |.number]|length'
```

**Run it in BOTH repositories.** This command takes one repo, and the iteration does not — the drain
pool reads both trees, and a session opened in one never counts the other's unassigned items.

**Since #365 this count is a BACKLOG SIZE, not a defect signal, and reading it the old way would be
worse than not reading it.** Nothing is admitted to a running iteration automatically any more, so every
newly-filed item is in this count by construction. A non-zero result is the normal state between
plannings; what it tells the owner is how much is waiting to be composed, not that a rule was broken.

**Run the POOL predicate ONCE, at entry, and hold the issue numbers it returned — that set is the drain's
terminal set** (#338). The iteration itself keeps growing while the drain runs; the snapshot does not. See
*The pool grows while it drains* under *Stop when* for why, and for what a second invocation does.
**#365 narrows what makes the pool grow and does not remove it** — the owner still admits items at
planning, `blocked` still clears, `ready` still lands mid-drain — so the snapshot stands unchanged.

Before #326, `ready` was sufficient to be worked. After it, `ready` is necessary and not sufficient — so
**every `ready` item with no milestone silently stops being worked**, and the only thing standing between
that and a queue going quietly dark is that somebody counted it. It is one extra filter on a query the
session already runs, and it is a precondition of this scoping rather than a nicety.

**`ready` means the description is closed by whoever closes it on that lane — and on `loop` it is the
owner's transition alone** (~~"the leads closed the description"~~, struck 2026-08-25 (#329): that was
true of `product` and of no other lane, in the file the loop executes). The canonical wording is
`/agents-configuration`'s `filed → **description closed**` and `filed → **ready**` rows — `product`
closes through both leads, `content` through `product-lead` alone, `loop` through `agents-lead` alone
with the owner applying the label. The generic bar
a description must clear to earn that label is `/definition-of-ready`. An Issue
without it is in the tracker but not executable, and the right move is to say so and run the intake pass
— not to build it and discover the missing requirement at the gate.

~~**This command currently REFUSES to run on the harness repo.**~~ **It did until 2026-08-02, and the
fix landed in the same slice that found it.** The first run of the state-model assessment
(`/agents-configuration`) turned up that `tadeumendonca-skills` had no `product` label at all —
it carried a separate 24-label taxonomy that was almost entirely unused — so the repo whose whole
purpose is the loop could not be drained by the command that drains loops. Its backlog got worked by
someone reading and judging, which is the failure the `ready` state exists to remove.

The owner reconciled both repos to one vocabulary (`/agents-configuration`, *One vocabulary across every
repo*), so **this command now runs on either repo.** Kept as a correction rather than deleted, because
the gap is the evidence for why the assessment is a standing rule.

**Do not invent an order.** `product-lead` owns sequencing ~~(ADR-0002 amendment #5)~~ — **struck
2026-08-28 (#339): that citation is wrong.** Amendment #5's own header reads *"`product-manager` gets a
trigger, and the reviewer's output gets a budget"*; sequencing ownership is not what it decided. Per
`documentation-standard`'s *cite the clause, not the line*, the live wording is
`/agents-configuration`'s *Opening a session — decisions before work*: **"Starting a slice that is not
the top of the stated order requires `product-lead` to have returned a new order, or the session records
that the order is unchanged."** Invoke it at session start; do not substitute a heuristic here.

~~**The Issue's own proposed fix pointed somewhere else and was also wrong**: it proposed citing
`agents/product-lead.md`, and `grep -rn "stated order" agents/ skills/ commands/` returns that file
only at a different clause.~~ **Struck the same day it was written — the assertion was FALSE, and how
it was reached matters more than that it was wrong.** `agents/product-lead.md` **does** carry the
clause, under *What you own — the ordering half*: **"Starting work that is not the top of the stated
order requires you to have returned a new order, or the session to record that the order is
unchanged."** So **both** surfaces carry it, and the Issue's proposal was sound.

**The cause is the finding: the clause WRAPS a line.** One line ends `…the top of the stated`, the next
begins `order requires you…`. A line-oriented `grep` cannot match a phrase spanning two lines, so it
returned nothing — **and a null result was read as an absence.** Use a falsifier that survives the
wrap:

```
grep -rn -A1 "top of the stated" agents/product-lead.md
```

**The multiline shape is the reusable half, not the correction.** A passage arguing *cite the clause,
not the line* had, as its own evidence, a line-based grep that missed a clause **because of a line**.
The routing above is unaffected — amendment #5 genuinely does not decide sequencing ownership, and that
citation stays retired.

**What `product-lead` does NOT order: the `loop` block.** The owner's standing rule fixes it ahead of
every `product` item at planning time. The canonical wording is `/agents-configuration`'s
*Loop before product — a planning-time COMPOSITION rule*, which carries the eligibility escape and
states in its own words that nothing gates it. `product-lead` orders **within** what the owner composed; it does not
compose. In this repo there is no conflict to reconcile at all — `product-lead` is not dispatched on
`loop` intake here (ADR-0002 amendment #14), so the rule fills a vacuum rather than overriding anyone.

**And the `loop` block MAY travel as one branch and one MR** — `/agents-configuration`'s
*The `loop` block MAY be carried as one branch and one MR*. It is a **permission the owner exercises at
planning**, never something this drain composes on its own: read the ordered body, and if it says the
block is one batch, work it as one. **The default is unchanged and per-item.** More than one batch per
iteration is normal — a branch does not cross repositories and the iteration does — so nothing here may
infer *"the loop block is one PR"* from *"the loop block is a batch"*.

The bias it exists to correct, said plainly because it is invisible from inside: **sorting the queue
by what flows without a human is correct for safety and backwards for prioritisation.** It once
produced seventeen closed issues with not one from the owner's product queue.

## Preflight — outstanding HITL work blocks ENTRY (#326)

**Before the drain begins, the outstanding human-in-the-loop work on the active iteration must be zero.**
The owner's rule, in his words:

> *"todas pendencias HITL devem ser zeradas no momento da invocacao do comando"*

**If any exists, the drain does not enter.** It surfaces what is missing — **one thing at a time**, never
as a list — and waits. The one-at-a-time rule is not presentation: a batch of pendencies is a decision
list, and he has said repeatedly that a decision list makes him rebuild the context for each item.

**The classes, and what queries each:**

| pendency | query |
|---|---|
| a description not closed on its lane | open, in the active iteration, **no `ready`** |
| **an item with no estimate** | open, in the active iteration, **no `sp:` label** |
| a decision pending on the owner | the **`blocked`** label — already queried by the *Reporting* section below |
| an outstanding `APPROVE-PENDING-HUMAN` at the current head | `zombie-loop-detect.sh` already reads exactly this artifact at `Stop` — reuse it, do not build a second reader |

**The estimate class is the one that is new**, and `/agents-configuration`'s *Estimation* section is where
its vocabulary, its estimator sets per issue type and the median-of-isolated-dispatches rule live. Read
them there; this is the gate, not a second definition.

**Two things this preflight is not.** It is **not a mid-drain check** — a pendency discovered *during* the
drain escalates immediately and the item is parked while the others continue, which is a different rule
with a different reason (*"todo momento que estiver atuando AFK em dreno e tiver uma pendencia HITL voce
deve escalar para mim o quanto antes"*). And it is **not a mechanism**: nothing fires it, nothing records
that it ran, and a session that skipped it looks exactly like one that found the set empty.

**An ARRIVAL is not a mid-drain pendency, and the distinction has to be stated or the escalation rule
eats the accepted behaviour.** ~~(#338)~~ — **the attribution is struck 2026-08-30 (#365)**: nothing is
filed into the active iteration any more, so #338 is no longer what produces an arrival. **The rule below
is unchanged and its subject is wider than #338 ever was** — an arrival is now the owner assigning an
item at planning, or a `blocked` item clearing, both of which outlive the strike. An Issue that joins the
active iteration after the drain entered is
outside the entry snapshot, so it blocks nothing and escalates nothing; it is the *next* invocation's
preflight problem, where it will refuse on `sp:` and — on the `loop` lane — on `ready`. Escalating per
arrival would convert something the owner explicitly accepted into a stream of interruptions, which is the
opposite of what the mid-drain rule is for: that rule is about an item **being worked** turning out to
need him.

**What it will cost on its first real invocation, said now so it does not read as a regression later.**
The estimate class is empty for every item in the backlog until the first estimation pass runs — the
owner's, 128 dispatches, his figure. **So the first preflight after this ships refuses.** That is correct
under the rule he settled, and it is a bootstrap cost paid once: from the second iteration on, the
pendency set is bounded by that iteration's contents rather than by the whole backlog.

## Decisions first, then work

Per `/agents-configuration`, "Opening a session": **collect the pending owner decisions across the
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
`gh issue` call in `hooks/scripts/` is a write path. `/agents-configuration`'s *"Closing an issue is a
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

Follow `/agents-configuration`. Nothing here relaxes it:

- Plan first for anything non-trivial; the two leads consolidate **one** demand before the build.
- Thin vertical slice, end to end, finished **through merge** before opening the next. **Where the owner
  composed the `loop` block as one batch, the slice is the batch** — one branch, one MR, commits still
  separated per issue — and *"before opening the next"* is measured against that unit, not against each
  Issue in it. WIP=1 is satisfied either way, since a batch is one branch and one PR by construction.
- WIP is bounded per `/agents-configuration` — read it there rather than trusting a restatement, and
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
  asks rather than denies there, so the owner decides per issue. See `/agents-configuration`,
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

**A second case is legitimate, and it is the second limb of his own rule (#327).** A PR link also goes to
him when **the ask is explicitly a decision he holds** — a title, a positioning call on a draft —
**stated as that decision and not as a merge request.** It is not a summons because nothing is waiting on
his approval to *merge*; what waits on him is the decision, and the link is where its object lives. Two
things keep this narrow rather than a loophole. **The decision goes in the sentence, not in the PR** — an
ask that reads *"here is the PR, take a look"* is a merge request wearing a question mark, and the limb
above forbids it. And **such a PR very often has no gate verdict at its head at all**, because the gate
has not run yet: which is precisely why the verdict-literal test cannot be the whole rule, and why the
first limb alone would withhold something he asked to keep.

**The detector cannot tell this case from a violation, and does not try.** *"Is this ask a decision he
holds"* is not mechanically knowable at any layer, so `premature-pr-link-detect.sh` **will** flag a
legitimate decision-ask link. It is detection-only, so the cost is a spurious notice in the next turn's
context and never a withheld link. Read the notice, judge it, and carry on — a notice is not a verdict.

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

- **the ENTRY SNAPSHOT is exhausted** — mechanical, no judgment; or
- a slice reveals the plan behind it was wrong — a boundary event, with what changed; or
- the owner interrupts.

~~- **the active iteration's pool is exhausted** — mechanical, no judgment; or~~ — **struck 2026-08-29
(#338).** It is kept struck rather than deleted because a drain ran under it. The pool is no longer a
fixed set, so *"the pool is empty"* is not a state a drain can reach by working; the terminal set is the
pool **as it stood at entry**. See *The pool grows while it drains* below.

### On exhaustion, run `/sprint-retrospective` — the closing ceremony now has an object (#355)

**On the FIRST stop condition only** — the entry snapshot exhausted — **run
`/tadeumendonca-skills:sprint-retrospective <iteration>`.** Not on a boundary event, and not when the owner
interrupts: neither of those is the end of an iteration, and a rite fired on a stall would report on an
iteration nobody finished.

**This is the object, and until #355 there was none.** The sentence three sections below — *"the closing
ceremonies run against the exhausted iteration"* — has stood since #326 with nothing in the tree it
could name. Measured against the commit this slice forked from, **pinned so the answer does not move
when this slice merges**:

```
git grep -l "retrospect" 5cfea0b -- commands skills agents
# → agents/product-lead.md, skills/agents-configuration/SKILL.md — two files that MENTION the word
git cat-file -e 5cfea0b:commands/sprint-retrospective.md
# → exit 128, the path is not in that tree: nothing an owner or a drain could invoke
```

**Two mentions and no object is the exact failure `closure-artifact-guard.sh` was built for** — a
promise resolves in prose and not in the tree — and it survived here for a month because the promise
reads like a description of something that already runs.

**HALF the promise now has an object and half still does not.** `/sprint-retrospective` is the **method** half:
each persona that ran, consulted alone, reasoning from its own artifacts. The **sprint review** half —
a bounded sweep of the running product, which finds a different class of defect entirely — **is not
built**, and `commands/sprint-retrospective.md`'s last section is where that is recorded rather than left to be
discovered again. Do not read "the closing ceremonies" as plural-and-satisfied.

**Nothing fires it.** This is an instruction in a command file, and by this loop's own test — *would
something stop me, or only my memory?* — it is not engineered. No hook can be: nothing in
`hooks/scripts/` reads the queue at all, so no layer here can observe that a snapshot went empty.

~~**no open issue outranks the cost of continuing**~~ — **struck as the DRAIN's terminal condition at
#326, and moved rather than retired.** It is now what **planning** asks: the criterion for admitting the
next iteration's contents. See below for why both cannot be left standing.

### The pool grows while it drains, so the terminal set is a SNAPSHOT taken at entry (#338)

**The owner's decision, verbatim, and it is a decision about behaviour rather than about a rule:**

> «a gente nao consegue impedir esse comportamento, embora ao longo do tempo esse aumento de escopo dentro
> da iteracao nao é desejavel e deve se normalizar ocm o tempo»

**Three things in it.** The behaviour is **not preventable**, so narrowing the filing rule to filing time
was declined. Scope growth inside an iteration is **accepted, not endorsed**. And it should **normalise
over time**, which makes it a trend.

**What it kills.** `loop` Issues join the **active** iteration at filing (`/new-issue`, *A `loop` Issue is
filed INTO the active iteration*), and `loop` is the class generated by working. So the sentence this
file's terminal condition rested on is false by decision:

~~**An iteration's pool does not grow while it is drained**: its contents are fixed at planning, and
findings route to the *next* iteration.~~ — **struck 2026-08-29 (#338).** Kept struck because the whole
argument below was built on it.

**The replacement: the drain terminates against the pool AS IT STOOD WHEN THE DRAIN BEGAN.**

- **What it is keyed on: the set of issue NUMBERS** returned by the queue predicate at entry, after the
  preflight passes. **Not a count** — a count is satisfied by an arrival replacing a closed item, and the
  drain would then work an item it never admitted while reporting the same arithmetic.
- **Where it lives: session state, for the duration of one invocation.** It needs **no durable home**,
  which is why the constraint #339 measured — a milestone description is not readable from here, so a
  description edit leaves no trace — does not bite this design. Nothing is being written to the tracker.
- **What a second `/autonomy-on` in the same iteration does: it takes a FRESH snapshot.** Items the first
  drain did not take are still open, still `ready`, still in the iteration, so they are in the second
  snapshot by construction. **The snapshot defers, it never drops.** This is the question the proposal was
  handed to answer and it is the one that would have killed a snapshot with a durable home: a persisted
  snapshot would have to be invalidated, and nothing here can write one anyway.
- **Both of the owner's asks hold at once.** Items join the active iteration on arrival, **and** the drain
  terminates, because a finite set fixed at entry is exhausted by working it.

**The growth surfaces at the NEXT entry as a refusal, and that is the whole of the visibility — no
instrument is built for it.** An Issue that arrived mid-drain carries no `sp:` label and, on the `loop`
lane, no `ready` either. Both are preflight pendency classes. So the next invocation **refuses to enter**
and surfaces them one at a time. That is not a report anyone has to write; it is the existing preflight
meeting the existing filing rule.

**The arrivals report is NOT built, and the owner retracted it in terms:** «em resumo: as metricas da
iteracao no gitlab vao mostrar o que aconteceu.» **One fact belongs in the record, as a fact and not as a
complaint:** these repositories are on GitHub, whose milestone view shows open-versus-closed and a
completion bar and **does not show when an item joined a milestone** — the quantity the retracted clause
was about. GitLab iterations carry that history natively. On this tracker the growth reads as a **moving
denominator** rather than as an event.

**What nothing observes, said plainly.** No artifact records the snapshot. A drain that terminated against
its snapshot, one that terminated against the live pool, and one that quietly dropped an item are
**indistinguishable** from the tracker and from the diff — every `gh issue` call in `hooks/scripts/` is a
write path, so nothing in this harness reads the queue at all. **And no detector is proposed**, unlike
#337's closing rule, because the only mechanically checkable signal here — *the drain reported exhaustion
while the iteration still holds open `ready` items* — is **true of every correct snapshot termination that
saw an arrival**. A detector with zero precision by construction is worse than none: it trains the reader
to ignore it. The gate asserts the rule is **present**. That is the whole claim.

### Why exhaustion is terminal again, and why that is not a reversal of #103 (#326)

**Two stop rules would otherwise disagree, and leaving both is the failure this file has already paid for
twice.** A `ready` item in a later iteration can easily outrank the cost of continuing while the active
iteration's pool is dry.

**#103's argument does not reach a set fixed at entry, and the distinction is the whole of it.** It
retired *"drain until the unblocked queue is dry"* because **the backlog** grows faster than it drains —
measured, +19 net in one session, roughly 13 of 32 born inside a review of something else. **The entry
snapshot does not grow while it is drained**, by construction rather than by policy: it is a set of
numbers taken once. So exhaustion is reachable in a way it provably was not for the whole `ready` queue.
**#338 moved this claim off the iteration and onto the snapshot** — the iteration turned out to grow
exactly the way the backlog does, which is why the sentence above reads *"a set fixed at entry"* and no
longer *"an iteration's pool"*.

**And this removes #103's own named residual rather than relocating it.** That section closes on
*"that judgement is not mechanical"* — the honest admission that its terminal condition asks a human
question of a machine. Under #326 the machine's condition is arithmetic (is the entry snapshot empty) and
the judgement moves to **planning**, a stage where the owner is present and is already deciding exactly
that.
Strictly better than what it replaces; the reasoning below stays because it is how the next reader learns
why two arithmetic conditions failed before either of them.

**Exhaustion is no longer the end of the SESSION, only of the drain.** The closing ceremonies run against
the exhausted iteration and the session's stop is the planning handoff, which is the owner's. Two
consequences worth stating because nothing enforces either: an empty pool from a **mistyped** milestone is
indistinguishable from a drained one (`/agents-configuration`, rule 1 — enumerate, never name), and a
ceremony run over an iteration that never existed reads exactly like a completed iteration.

**And a third since #338:** the ceremonies run against the **iteration**, not against the snapshot, so an
iteration that grew mid-drain is closed with items in it the drain never admitted. That is the accepted
behaviour rather than a defect — it is what *"aumento de escopo dentro da iteracao"* looks like from the
closing end, and it is the moving denominator the tracker shows.

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

**What makes the new condition reachable is the pruning step** (`/agents-configuration`, *Closing an
issue is a step*): a loop that only ever adds has no terminal state at any threshold. With a closing
criterion, the queue can shrink, and "no open issue outranks the cost of continuing" becomes a real
question rather than a formality.

**Named residual:** that judgement is not mechanical. It is the honest shape — the alternative is
another arithmetic condition, and this section is what an arithmetic condition that looked reachable
cost.
