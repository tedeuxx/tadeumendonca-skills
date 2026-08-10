---
description: Run a change from idea to live in one of two loop models — gitflow-multi-env with staging and promotion, or trunk-single-env where merge is deploy — including intake, what gets worked next, closing criteria, and revert-then-forward-fix on failure. Use when deciding which model a repo is on, sequencing a slice through review and merge, or handling a failed deploy. Not for the workflow files that implement it (see workflow/github-actions).
---

Apply the platform's end-to-end development loop in a `<project>` repo. This is the flow the principles run inside — `/principles/engineering-philosophy` is the judgment, `/principles/verification-and-gates` is what "done" means; this is how a change travels from idea to live.

Context: $ARGUMENTS

## Pick the model first
The loop has **two shapes**. They share every invariant below and differ only in how a change is promoted. Read the repo before applying either — asserting the wrong model is worse than asking.

| Model | Use when | Promotion |
|---|---|---|
| **`gitflow-multi-env`** | The repo deploys to **more than one environment** (staging + production) and carries an integration branch. | Two hops: PR → integration branch → staging, then a promotion PR → release branch → production behind a manual approval. |
| **`trunk-single-env`** | The repo has **one long-lived branch (`main`) and one destination** — a single deployed environment, or a consumed artifact (library/plugin) released deliberately. | One hop: PR → `main` → deploy/release. |

**How to tell**, in order of authority: the repo's `CLAUDE.md` states the model outright; otherwise look for an integration branch (`develop`) on the remote and more than one environment in CI. **If both signals are absent, it is `trunk-single-env`** — a single branch cannot express a promotion. Never infer the model from the skills library's own examples.

> The number of environments — not the repo's size or seriousness — picks the model. `trunk-single-env` is not "the lightweight one": the gate does not get weaker, it moves (see below).

## Invariants (both models)

### Intake — where work is born, and the chain it must walk

**Nothing is worked that is not recorded in the issue tracker.** No exceptions, no size threshold, no
"this is a one-liner". This **supersedes** the previous rule, which made a tracked issue *optional*,
created only when it helped decompose the work.

The chain, and each link is load-bearing:

> **The owner generates demand.** They are the only origin of work — see *Review does not open work*
> below, which is the other half of this and is untouched.
>
> **The leads close the description among themselves.** `product-lead` and `tech-lead` collaborate on
> writing the issue: what it must deliver for the reader, **what it must say to the market** (that half
> is `product-lead`'s since `marketing-lead` merged into it on 2026-08-04), and what the system must
> carry. They disagree first and reconcile second; a disagreement they cannot settle goes **up** to the
> owner as a decision, never **down** as competing briefs.
>
> **Only then is the issue executable.** `developer` does not pick up an issue whose description is not
> closed. An issue in the tracker is not the same as an issue ready for work.

**`harness-reviewer` is not a link in that chain, and the omission is deliberate rather than an oversight
in the list.** It shares the leads' tier and takes **no part in closing a story's description** — its
object is the machinery this loop runs on (hooks, settings and permissions, agent briefs, skills,
commands, the plugin, MCP), not the product the loop builds. It is dispatched on a **proposal about the
loop itself**, returns the scenarios that proposal does not cover with how to check each one, and does
that **before anything is built**. It gates nothing: no merge request, no merge, no Issue, no label
transition — which is why it appears in no row of the table below.

*Where the two chains meet.* A change to *how work is decided* — this skill, the states table, an ADR
that governs the loop — is still a **boundary** decision for the owner. `harness-reviewer` is who the
owner works that decision out with; it does not make it, and it does not put it in the tracker.

#### The states, and the one artifact that was missing

The chain above is **behaviour**; this is the state it implies. Derived by the assessment
`/principles/loop-engineering` now requires before any loop change is executed — and the first run of
that assessment found this gap **one day after the chain was merged**.

| transition | who acts | artifact that records it |
|---|---|---|
| → **filed** | the owner, alone | the Issue exists |
| filed → **ready** | the leads, closing the description | **`ready` label** ← *this was missing* |
| ready → **in progress** | `developer` | an open PR (already observable — no new state) |
| in progress → **reviewed** | `quality-assurance` | **a `<!-- gatekeeper-verdict: … -->` comment on the PR, carrying the head SHA it read** |
| reviewed → **closed** | `quality-assurance` (safe) · the owner (boundary) | the merge, and for boundary the owner's ratifying comment |
| **any → blocked → back** | anyone, on discovering it waits on the owner or on something outside the loop | **`blocked` label** |

**`blocked` is orthogonal, not a sixth step, and saying that is part of the model rather than an excuse
for leaving it out.** It can attach at any point and it returns the item to wherever it was — an Issue
can be blocked before its description is closed *and* after, and a slice can discover mid-build that it
needs the owner's words. Modelling it as a stage in the line would be false; leaving it out of the table
entirely was also false, and that omission was caught in review of the very slice that introduced it.

**The `reviewed` row was false when this table was written, and saying so is the correction.** It named
*"their verdicts on the PR"* as the artifact while gatekeeper verdicts existed only as prose returned to
the orchestrator — nothing reached the PR, the Issue, or anywhere durable. So the table asserted an
artifact that did not exist, in the very column whose job is to answer *what records that this
happened*. Since 2026-08-02 ([ADR-0006](../../docs/adr/0006-a-verdict-owed-to-another-persona-is-an-artifact.md))
the artifact is real: the gatekeeper posts a marker comment carrying the head SHA it read, so a verdict
on a moved head fails loudly instead of reading as approval.

**One half of that mechanism was load-bearing and is now gone, which is worth stating rather than
quietly dropping.** Until 2026-08-04 there were two gatekeepers, and `quality-assurance` **verified
`security`'s comment before merging** — a gate reading another gate's artifact, which is the only place
in this loop where a verdict was mechanically checked by someone other than its author. `security` was
absorbed into `quality-assurance`, so the remaining verdict is checked by nobody: the rule that it must
be posted before the merge is now **self-enforced**, and its file says so in those words. The artifact
still closes *omission* — a merge claimed to have been reviewed when nothing was written. It no longer
has a second party confirming it.

**`ready` is the only state added, and the restraint is the point.** Four of the five transitions were
already observable; inventing states for them would restate information that exists and give it a second
place to be wrong. **An issue with no `ready` label is not executable** — that is the whole mechanism,
and it turns the rule above from something a persona must remember into something anyone can query.

*What it does not buy:* nothing verifies that the leads actually closed the description rather than
one nodding it through. The label makes the claim **auditable and attributable**, not proven. Stated
because the previous section's own argument — objectivity is transferred, not created — applies here too.

#### One vocabulary across every repo

The first run of the assessment found the two repos carrying **incompatible taxonomies**: one used
`product` / `content` / `reader-facing`, the other a scheme (`type:*`, `phase:*`, `priority:*`,
`semver:*`, `status:blocked`) that was almost entirely unused. Reconciled to one vocabulary (owner
decision, 2026-08-02).

**The measurement, corrected in review and stated precisely because the first version was wrong in
three places** — it said "88% dead, four labels used, on four Issues, 29 of 33". Re-derived from the
repository's label events, which is the only source that survives the deletion:

- the repo had **34** Issues, **29** carrying no label at all;
- of the **15** labels retired, **11 were never applied to anything**, and four were: `type:feature`,
  `phase:1`, `semver:minor`, `semver:patch`;
- on **Issues** only three of them ever appeared — on #4–#7, all closed in the repo's first week;
- `semver:*` also landed on **eight merged PRs**, which the original count missed entirely.

*Why the correction is recorded rather than quietly fixed:* the original figure mixed two populations,
taking "four labels" from a PR-inclusive set and "four Issues" from an Issue-only one. That is precisely
the shape of error this section is about — a number that reads as measured and was assembled.

**The test a label has to pass: something must QUERY it.** A label nobody reads is not classification,
it is decoration that ages.

| label | means | set by | queried by |
|---|---|---|---|
| `product` | the repo's own deliverable — for a site, the site; for a harness, the harness | the owner, at filing | `/autonomy-on`'s queue · merge class **safe** |
| `content` | published in the owner's voice | the owner, at filing | merge class **boundary** |
| `ready` | the leads closed the description | the leads | `/autonomy-on` · `developer` refuses an Issue without it |
| `blocked` | waiting on the owner, or on something outside the loop | anyone | the "what needs the owner" report |
| `reader-facing` | the diff will change words or images a reader sees | the owner or the leads | which lens the gate dispatches — **a signal, never a gate** |

**Retired:** `type:*`, `phase:*`, `priority:*`, `semver:*`, `status:blocked`. `type` and `priority`
restate what a title and an order already say; `phase` described a roadmap that ended; `semver:*` was
vestigial from a **different loop model** — `/workflow/versioning` documents label-driven bumps for
`gitflow-multi-env`, and that skill stays correct for a repo using it, but a `trunk-single-env` artifact
repo picks its part at dispatch and reads no label. `status:blocked` survives as `blocked`, renamed for
consistency rather than dropped: *waiting on the owner* is real and is otherwise invisible.

**`content` is defined in every repo even where it cannot occur.** A harness repo publishes no articles,
so it will carry none — and defining it anyway keeps one meaning per word across the workspace, which is
the whole point of reconciling. A vocabulary that changes per repo is two vocabularies with a shared
prefix.

**Why the formalism is not ceremony — it is what buys the gate its objectivity.** `quality-assurance`
consolidates that *every requirement of the issue was met*, and those requirements are the leads' output.
So the ruler the gate applies is **external to the gate**: a finding either anchors in a stated
requirement or it does not block. That is the whole answer to *"the reviewer must be objective, otherwise
nothing closes"* — and it only works if the requirements are actually there.

Read the failure in that direction and it becomes obvious: a vague issue leaves the gate nothing to
anchor on, so it falls back on impression, and impression has no stopping rule. **Twenty-two findings on
a documentation PR is what an unanchored gate looks like.** The work did not disappear when this rule
moved it upstream; it got cheaper, because a missed requirement costs a text edit at intake and a review
round at the gate.

**The asymmetry, stated so the rule does not promise more than it delivers.** The gate's *second* axis
is *not* in the issue and cannot be: *"can this cause a problem in production"* is not enumerable in
advance — if it were, it would be a requirement and the delivery axis would already cover it. So the
loop is objective on delivery and **judgement-based on the floor**, and the two rulers are different in
kind.

**Until 2026-08-04 that asymmetry was carried by a separate persona** — `security`, holding its own veto
precisely because its axis could not be a criterion on someone else's checklist. The owner merged it
into `quality-assurance` for fewer profiles reconciling a result on the same MR. **The asymmetry did not
merge away with the persona**: one gate now applies two rulers, which is why its file requires every
finding to be labelled with the lens it came from. A finding whose ruler is unstated is a finding the
reader cannot check.

### Opening a session — decisions before work

**Collect the pending owner decisions across the whole queue and ask them as a batch, before choosing what to build.** One question at a time, in one sitting.

Batching is the point. Asking a decision when a slice hits it produces one stall per slice; asking them up front produces one conversation and unblocks everything at once. Same questions, completely different cost to the person answering — and the owner's attention is the scarce input this whole loop is calibrated around.

Then **`product-lead` states the order**, and the session works it. Not "invoke it more often" — the condition is precise:

> Starting a slice that is **not** the top of the stated order requires `product-lead` to have returned a new order, or the session records that the order is unchanged.

That fires exactly when the risk is real — picking work — and it produces the artifact that makes drift visible: a stated order that a later choice can be checked against.

**A session with no pending decisions says so.** A step that silently did nothing must not read like a step that ran.

*Why this is an invariant and not advice:* every surviving persona has a trigger. `quality-assurance` runs on every MR and the copy lens — `product-lead`'s market half since 2026-08-04, `marketing-lead`'s before that — hangs off it. Its predecessor `product-manager` had none, and a mandate with no trigger is a document, not a gate — which is this loop's own sentence, about a different persona, that this rule finally applies to the one it was written next to.

### What gets worked next — discovered vs requested

**Work you discover only preempts work the owner asked for when it BLOCKS it.**

File everything, always — a defect found in context, with the evidence in hand, is worth recording whether or not it is worked. That part is unconditional. This rule is only about **what gets built next**.

The test is checkable, not a judgment call:

> Does the requested work ship **wrong**, or **not at all**, without this?

Yes → it goes first, and the blocking relationship is stated on the issue. No → it queues like everything else and `product-lead` orders it.

*Why the rule is needed:* discovered work is cheap to justify — found in context, evidence attached, usually safe class, merges without the owner. Requested work needs decisions, designs, sometimes the owner's own words. So the loop's **autonomy gradient sorts the queue by what can flow without the human**, which is exactly backwards from what a backlog is for. That is not a lapse in judgment; it is the incentive the other rules create, and it needs a counterweight written down.

### What "delivered" means, and the measure that keeps it honest

**A slice DELIVERED when a reader can do, see or read something different.** Everything else is
**hygiene** — comments, dead code, a test mechanism, a process rule, a README. Hygiene is not lesser
work and it is not delivery: it is the cost of being able to deliver again.

**Report product slices against hygiene slices, every session.** Measured on the day the owner raised
it: twelve merges, **three** of which a reader could perceive; the session reported *"ten issues
closed"*, which sounded like progress. Every one of the six hygiene slices was defensible on its own —
which is exactly what makes this invisible from inside. Nothing was wrong and the product barely moved.

**A session with zero product slices is a finding, not a status.**

*Why this is a measurement and not a process:* it adds no step, blocks nothing, needs nobody's approval.
Rules 1–3 above shape behaviour and can be argued with; a visible outcome cannot be closed without
someone noticing. That is what makes it agile rather than ceremony.

**Hygiene is picked up when it BLOCKS a product slice, or in one deliberate bounded batch** — not
opportunistically, and not because it is what flows most easily without a human. That bias is the same
one recorded above, and it once produced seventeen closed issues with none from the product queue.

### Closing an issue is a step, with a criterion

**The loop must be able to REMOVE work, or it has no terminal state.** Every review round could only
add: findings became issues, the do-not-fold-in rule made thin slices by filing, and nothing anywhere
said *"this is not worth tracking"*. Measured across one session: **32 issues created against 13 closed,
net +19**, with roughly 13 of the 32 produced by reviewing something else rather than by requested
value.

Three things that multiply it are each individually **correct**, which is why the fix is not to undo
any of them: adversarial review that actually works, the do-not-fold-in rule, and wider autonomy. **The
fix is not "file fewer issues"** — the findings are real, and losing them is worse than tracking them.
And not a cap: a queue that refuses entries silently drops the next one that matters.

**Close an issue when any of these holds, and state which one in the closing comment:**

- **Superseded** — a later decision answered it, or answered the question it was asking. Say what
  superseded it, so the reader can check rather than trust.
- **Implemented elsewhere** — the mechanism exists now, under another slice's name. Point at it.
- **Its premise no longer holds** — the condition that produced it is gone. This is the one most often
  left open, because nothing prompts anyone to re-read an old issue against the current tree.
- **The cost of tracking exceeds the cost of rediscovering it** — a real finding, small, and cheaper to
  find again in context than to carry. Say so plainly rather than pretending it was fixed.

**A closing comment that states no criterion is not a close, it is a deletion.** The record of *why* an
issue stopped mattering is worth as much as the record of why it was opened — same argument as
supersede-never-rewrite in the ADR library.

**This is the owner's act**, like opening one — `permission-guard` leaves closing open everywhere, and
that asymmetry is deliberate: opening work commits the owner's future attention, closing it releases
attention already committed. But **propose the batch and the criteria**; do not close silently and do
not let the graveyard grow because nobody was assigned the question.

## Review does not open work

**Only the owner decides what enters the queue.** A REVIEW never files: an agent that turns its own
finding into an Issue has decided something should exist and is merely asking for agreement afterwards.
Findings are **named** — in a verdict, in the PR, to the human — and the owner decides whether any of
them becomes tracked work.

**Enforced by WHO is asking, since a correction on 2026-07-31.** `permission-guard` rule 5c reads
`agent_type`, which the harness stamps and the model cannot forge — *cannot **claim**, precisely; it
can still **choose** which persona to run, so this enforces routing rather than capability, see
ADR-0004's 2026-08-02 amendment* — a ~~**subagent is denied**
outright~~ **subagent is denied unless it is `developer`** (rule 5d, since #124), and the
**main loop is asked** — one prompt showing the title, which the owner approves
or declines. Reading, listing, commenting, labelling and closing stay open everywhere.

**The one exception, and why it does not erode the rule.** Under `gitflow-single-env` a story is
broken into tasks, and `developer` is the persona that executes them. **Opening scope** is creating
work nobody asked for; **decomposing** is dividing work the owner opened and the leads
ratified, and the task adds nothing that was not already authorised.

~~Opening scope is still denied for every subagent, `developer` included.~~ **Struck: that is the
RULE, and since 2026-08-02 it is no longer the MECHANISM.** `developer` is exempt from the hook
outright — a task with no parent at all is allowed by the guard. What forbids it is
`agents/developer.md` and the gate, not a denial. The distinction below is what the persona must
apply; it is not what the floor checks.

~~What makes it an exception rather than a hole: the parent is verified against the tracker, never
read from the command. It must be declared (`Parent: #N`), it must exist, and it must carry `ready`.~~
**Struck 2026-08-02 (owner decision), and the strike is the substance.** For four rounds the hook tried
to verify exactly that — the marker read from the body file, word-anchored, first-match-not-last, the
repo read from the collapsed command so a `-R` inside `--body` could not redirect the lookup, then a
tracker lookup for `ready`. Each fix was correct; each left the next spelling open. **Intent is not in
the command string** (ADR-0004, amendment 2026-08-02).

**So the check moved to where a judgement can be stated.** `developer` may file issues; the rule it must
follow — *only a task under a story carrying `ready`, referencing its parent, never extending the
story* — lives in `agents/developer.md`, and `quality-assurance` verifies it on the task's own MR.

**What the floor still decides, because these are acts and not judgements:** every OTHER subagent is
denied — `quality-assurance` citing a story is still a review opening work, and the
exemption is keyed on `agent_type`, which the harness stamps and the model cannot write. The main loop
still asks the owner.

**The cost is three things, not one, and it is booked in ADR-0004 (amendment 2026-08-02) rather than
restated here:** the parent is unverified, the *repo* is unverified too, and in the consuming repo a
filed issue mentioning `@claude` starts a token-bearing run. Read it there — a second copy is a second
thing to keep true, and this rule has already paid for that twice.

~~*This is enforced, not asked: rule 5c denies `gh issue create` with no exempt spelling.*~~ **That
version was wrong, and the way it was wrong is worth keeping.** It reasoned that "was this asked for"
is not mechanically observable while "is this creating an Issue" is, and guarded the observable proxy
instead. But a blanket denial does not prevent unaligned work — it taxes **aligned** work, and the tax
falls on the owner, who then types the command themselves for something they had just asked for. The
owner named it: *"não é aceitável eu ter que abrir por conta própria a feature toda vez que
alinharmos algo."* Substituting an observable proxy for the real property is not a conservative
approximation when it inverts who pays.

The old objection — *an exemption the model can invoke is not a boundary* — is answered rather than
dropped. It is correct about `deny`: a flag meaning "the owner asked for this" would be the model
vouching for itself. It does not reach `ask`, because the model is not the one deciding.

**With one named gap, accepted until 2026-08-04 and now closed:** the `gh api … POST …/issues` route —
and ADR-0004's equivalent for merging — is closed by the hook's **rule 5f**, which denies a `gh api`
call carrying a write indicator (`--method POST/PUT/PATCH/DELETE`, `-X`, `-f`/`-F`/`--field`/
`--raw-field`, `--input`) and leaves a bare read untouched. The issue-creating matcher itself is
unchanged and still does not parse endpoints; 5f asks only whether the call **writes**, which is visible
in the flags where intent is not.

It briefly lived in the floor's `deny` as a blanket `Bash(gh api:*)` and that was too broad — it took
the read path with it. Two things to carry: **say which layer closes a route whenever you say it is
closed**, because "closed" on its own is how the next reader trusts the hook on a path it does not
cover; and state residuals rather than leaving them quietly true — a residual nobody wrote down is
indistinguishable from one nobody noticed, and so is a discharged one nobody struck.

**Why, measured rather than assumed.** In one session the queue grew by 19 issues net, and roughly 13
were born inside a *review of something else* — because the reviewer's own Definition of Done said
"adjacent debt filed as an Issue". Every finding became work nobody had decided to do. The queue stopped
describing the product and started describing how hard the agents had looked at it, and a drain that
produces faster than it consumes has no end state.

**The accepted cost, named rather than discovered:** a finding in a verdict is ephemeral where an Issue
is not. On a merged PR the report has no reader afterwards. That is the trade — fewer things tracked,
and some real findings lost — and it is preferred to a queue that grows by working.

### The agent's state while a slice is blocked on someone else

Everything below defines the states of a **slice** — plan, build, review, merge. It did not define the
state of the **agent** while a slice waits on an actor it does not control, and that interval is where
most of a session's wall-clock actually goes: two to seven minutes per reviewer round-trip, several
times per slice.

**With no defined action for that interval, the default behaviour is to report status. Reporting reads
to the agent as delivery and to the owner as stopping** — both parties acting correctly on the same
evidence. The owner said it three times in one session (*"você está parando"*, *"não to vendo você
fazer nada"*), which is what makes it a loop defect rather than an attention failure: **an instruction
that has to be repeated is a rule that should have been written.**

> **On dispatching work to a reviewer — or to any actor you do not control — name and BEGIN the next
> non-overlapping action before ending the turn.** If there is none, say so: *"waiting on X, nothing
> disjoint in the queue"* is honest status. Silence is not, because silence is indistinguishable from
> being stuck.

Naming the next action and doing it are indistinguishable from outside, so a turn that ends on a
description reads as a stall regardless of intent.

**This rule used to collide with WIP, and the collision won.** While WIP was bounded by a *count*, the
guard denied a second PR for a slice sharing zero files with the open one — so *"work in parallel while
you wait"* and *"WIP = 1"* gave opposite instructions, and the blocking one had a hook behind it. The
bound is file **overlap** now (see step 2), which is what makes this rule executable rather than
aspirational. It stayed aspirational for a while anyway, because the fix was merged into a plugin build
the sessions were not running — the reason `session-plugin-version` exists.

### Inner loop (per slice)
1. **Plan-first**, then implement. Ask only on architecture / contracts / irreversible calls; decide autonomously on in-pattern implementation.
2. **One thin vertical slice at a time**, end-to-end and reviewable. Keep it surgical; adjacent debt is **named, not refactored inline and not filed** — see *Review does not open work*.
   **WIP is bounded by file OVERLAP, not by a count.** A second PR may open freely if its changed files do not intersect an open PR's; it may not if they do. The goal was never *one at a time* — it was avoiding stacked PRs that rot into conflicts, and counting is a bad proxy for that: it blocks disjoint work, which is the common case, while doing nothing about the actual risk. Pair it with the half that prevents rot: **integrate `main` before requesting review** if `main` has moved.
3. **Develop locally**, against whatever backing services the repo actually has — see `/principles/permissions-and-environments` for what "locally" means per model.
4. **Validate locally**: run the repo's **functional regression** and self-verify the gates (lint, typecheck, coverage). Report with the real output, never a claim.
5. **Run `/workflow/code-review`** before opening the PR — the author's own completeness pass, anticipating both of the gate's lenses while fixing is still free. *Namespaced deliberately:* a bare `/code-review` resolves to the external `code-review@claude-code-plugins` marketplace plugin this repo also installs, which is a different thing entirely.
6. **`quality-assurance` reviews every MR, holding TWO lenses in one pass.** It consolidates that every
   requirement of the issue was met, **and** it answers the question the issue does not contain — *can
   this cause a problem in production?* **Neither lens is conditional on what the diff touches.**

   **This was two personas until 2026-08-04.** `security` was the second gatekeeper, dispatched in
   parallel; the owner merged it in for fewer profiles reconciling a result on the same MR. The mandate
   is unchanged and the dispatch is halved. What the single gate must now do deliberately — hold both
   lenses, label every finding with the one it came from, and run both *instruments* (measuring a
   mechanism by executing payloads against it, and re-deriving a stated claim against the artifact) — is
   written into `agents/quality-assurance.md` with the four costs it is compensating for.

   *The cost, named, because it is the failure this loop keeps meeting:* on a diff with no security
   surface the production lens has nothing to check, and a lens answering `n/a → pass` every time is
   gating nothing. So its `n/a` is only valid **naming the axes it looked at and found untouched** —
   dependencies, permissions and IAM, secrets, action pins, new external inputs, the deploy path.
   A reassurance is not a check.

   **The gatekeeper posts its verdict to the PR before returning** — a `<!-- gatekeeper-verdict: … -->`
   comment carrying the head SHA it read, so a verdict on a moved head fails loudly instead of reading
   as approval. A relay from the invoking context is a notification, never the authority
   ([ADR-0006](../../docs/adr/0006-a-verdict-owed-to-another-persona-is-an-artifact.md)).
   ~~`quality-assurance` verifies `security`'s before merging.~~ **Struck 2026-08-04**: there is no
   second verdict to verify, so the posting rule is self-enforced — see the `reviewed` row above for
   what that costs.

   *This paragraph exists because the sweep that should have caught its absence could not.* The rule was
   added to both persona files and to the state table, and this narration — the place an agent actually
   reads the procedure — kept none of the old wording, so no grep of the old claim could reach it. The
   lesson lives where the reader who needs it is, in `/workflow/code-review` §3: **a phrase sweep finds
   restatements, never omissions.**

### Always true
- **Pipelines are independent per repo** (never cross-trigger). Infrastructure changes are **pipeline-only**: a reviewed plan on the PR, apply on merge.
- **Merge with a real merge commit, never squash** (`gh pr merge --merge`) — each thin slice's conventional commits are the changelog and the slice-by-slice trail; squashing collapses them. See `/workflow/github-actions`.
- **The regression suite must functionally cover 100% of implemented features.** Which suites that means is per repo — E2E always; an API suite only where an API exists. Coverage of a surface the repo does not have is not a requirement, and pretending otherwise trains the agent to fake evidence.
- **Something irreversible always asks.** The models differ on *which* act is the point of no return, never on whether one exists.

## `gitflow-multi-env`

```
roadmap / PLAN.md
   │  plan-first; ask only on architecture / contract / irreversible
   ▼
thin slice, no file overlap  ──  adjacent mess in the path? work around + file the debt
   │
   ▼
develop locally  ──  security & resilience by-design
   │
   ▼
validate locally: run the regression  ──  self-verify gates green
   │
   ▼  /workflow/code-review before opening the PR
PR → integration branch (auto-merge)  ──  staging gate: coverage + quality + security
   │  Claude App reviews the PR (advisory, non-blocking)
   ▼
STAGING  ──  post-deploy: smoke + confirm health via observability
   │
   ▼
PR integration → release branch
   │  blocking: full regression · human review · version label · MANUAL APPROVAL
   ▼
PRODUCTION + tag / Release  ──  post-deploy smoke + observability
   │
   └─ breaks? → revert the offending merge on the release branch + re-release (forward fix)
```

- **Feature/docs branch → PR → integration branch** (auto-merge). The **staging gate** blocks on coverage + quality gate + security. On merge it deploys to **staging**; the **Claude App** reviews the PR as advisory (non-blocking).
- After staging deploys: **smoke + confirm health via observability**.
- **Promote integration → release branch**: the **full regression is a blocking required check**, plus human review, the version-bump label, and **manual approval — promotion to production always asks**. On merge: production deploy + version tag + GitHub Release. Post-deploy: smoke + observability again.
- **The point of no return is the promotion**, which is why the heavy gates sit there and the staging gate stays light: staging is cheap to break and re-fix.
- **Failure path:** revert the offending merge on the release branch and re-release — a forward fix with a new slice, not a long-lived hotfix branch.

## `trunk-single-env`

```
roadmap / PLAN.md
   │  plan-first; ask only on architecture / contract / irreversible
   ▼
thin slice, no file overlap  ──  adjacent mess in the path? work around + file the debt
   │
   ▼
develop locally  ──  security & resilience by-design
   │
   ▼
validate locally: run the regression  ──  self-verify gates green
   │
   ▼  /workflow/code-review before opening the PR
PR → main   ── THE gate, all of it: lint + typecheck + coverage + quality + security + full regression
   │  Claude App reviews the PR (advisory, non-blocking)
   │  MERGE ASKS — this merge is the go/no-go
   ▼
LIVE (deploy on merge) + tag / Release  ──  post-deploy smoke + confirm health
   │
   └─ breaks? → revert the offending merge on main + re-deploy (forward fix)
```

- **Feature/docs branch → PR → `main`.** There is no integration branch and nothing to defer to, so **the PR carries the entire gate**: lint, typecheck, coverage, quality gate, security, and the **full regression as a blocking required check**. The Claude App reviews as advisory (non-blocking).
- **The merge to `main` is the point of no return** — it deploys. So the merge is where the go/no-go lives: it moved from a promotion step onto this merge.

  **But "the merge is the go/no-go" does NOT mean "the merge always asks a human", and this line used to say it did.** ~~*Auto-merging to `main` is never in-pattern here.*~~ That was written before ADR-0004's classified autonomy and contradicted `quality-assurance`'s own definition, which merges the safe class — so an agent reading the principles layer and an agent reading the gate reached opposite conclusions about the same act (#62). What the merge asks for is a **judgement**, and who supplies it depends on the class:

  - **Safe class** — docs, dependency bumps, tests, in-pattern implementation of an already-approved spec. **`quality-assurance` merges it**, once both of its lenses are green. Escalating these is not caution; it is the loop failing to flow, and it spends the owner's attention where it buys nothing.
  - **Boundary class** — infrastructure and anything threatening continuity, a change to the loop's own rules, publishing in the owner's voice. **The gate never merges these.** It approves pending the human and hands the go/no-go up.

  *Significance beats in-pattern:* when the class is unclear, it is boundary. And **the gate never merges an expansion of its own authority**, whatever the diff looks like.
- On merge: deploy + version tag + GitHub Release. Post-deploy: **smoke + confirm health**, through whatever observability the repo actually has (for a static site that is analytics + the client error surface + a build/prerender smoke, not backend telemetry).
- **Failure path:** revert the offending merge on `main` and let the revert deploy — same forward-fix discipline, one hop instead of two.
- **Consumed-artifact variant** (a library or plugin with no deployed environment): identical, except the merge to `main` publishes nothing by itself — the irreversible act is the **release/tag**, so that is what asks. `main` stays always-releasable.

### Do not carry these over from `gitflow-multi-env`
- No `develop`/integration branch — do not create one, and do not pre-authorize merges to a branch that does not exist.
- No "light staging gate". There is no second chance downstream; a gate skipped on the PR is a gate that never runs.
- `main` is the **working** branch, not a protected production mirror. Tooling that blocks edits or commits while `main` is checked out breaks this model outright.

## What the human does (the residual)
Everything mechanical is the agent's job: plan, slice, build, validate locally, make the gates green, report evidence. The human is left only the residual — approving (or redirecting) architectural/contract decisions and giving the **go/no-go on the irreversible act** (the promotion under `gitflow-multi-env`, the merge to `main` or the release under `trunk-single-env`). Designing the loop so that residual stays small is the whole point (`/principles/verification-and-gates`).

See also: `/workflow/github-actions` (branching, OIDC, the deploy workflows), `/workflow/versioning` (release model), `/backend/coverage` (gate definitions, both stacks), `/frontend/playwright` (E2E). Repos with an API layer add its contract/API suite — see `/backend/postman`.
