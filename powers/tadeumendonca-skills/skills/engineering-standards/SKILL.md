---
name: engineering-standards
description: The owner's engineering preferences, portable to any project — two tiers (a non-negotiable floor, a risk-calibrated judgment layer), the eleven principles behind every call, delivered versus hygiene, and the human residual. Use when deciding how much rigor a change deserves, whether something counts as delivery, or what to do while blocked. Not this loop's machinery, state machine or WIP rule (see agents-configuration), and not what done means concretely (see definition-of-done).
---

Apply the owner's engineering standards — the two tiers, the eleven principles, and the few rules
about delivery and the human residual that hold regardless of machinery — in any `<project>` repo.

Context: $ARGUMENTS

**This is the half of the former `harness-engineering` that travels (#381).** That skill held two
bodies of content in one file: the intentional design of *this* loop, and the engineering preferences
that would still be true in a project that never runs it. The owner's cut, in his words —
*«engineering-standards serve mais de forma generica as preferencias de engenharia que possuimos de
forma mais abrangente»* — and the test that decides every paragraph: **would this still be true in a
project that does not run this loop?** Yes → here. No → `agents-configuration`.

**The operational ruler that test was applied with, so a later reader can re-apply it rather than
re-derive it — and it is GATED rather than merely stated:** nothing in this file names a persona of
this roster, a hook script of this repository, or a decision record of either library. A paragraph
that needs one of those is describing local machinery and belongs in `agents-configuration`. This
repository's inventory gate asserts all three absences, so a local paragraph drifting back in here
reddens instead of being noticed by whoever happens to read it next.

**A consequence of gating it on TOKENS, said here because it shapes how this paragraph is written:**
the gate greps for the names, not for the sentences around them, so a file teaching the rule cannot
spell its own examples. That is why the three are described rather than listed — the alternative is a
red on the one paragraph that was never wrong. The same shape is recorded in
`documentation-standard`'s citation-form section, reached from a different direction.

**Issue numbers are the one exception, and it is deliberate rather than an oversight.** This paragraph
and the one above carry `#381` because they are *provenance* — where this file came from — not
content a consumer applies. The gate does not forbid them for exactly that reason, and forbidding
them would have made the file unable to say where it came from.

**Its companion is `agents-configuration`, and the two are not interchangeable.** This file is the
judgment; that one is the loop the judgment is applied inside — its state machine, its intake chain,
its gates, its WIP rule and the mechanisms that hold them. Where a principle below has a local
enforcement, the enforcement is named there and the principle is named here, once each.

## The move that makes it a discipline, not a vibe

Every guarantee a loop claims is **mechanical or it is not real.** "The reviewer holds the merge
gate" is engineered only once a hook denies the merge to every context but the reviewer; until then
it is an instruction the loop can break — and the same model that skipped a review is the one trusted
to remember. The test, applied to any claimed property of a loop:

> *If this guarantee failed right now, would something stop me — or only my memory?*

If only memory, it is not engineered yet — it is an intention.

**`agents-configuration` applies this test to itself repeatedly and by name** — several of its own
rules are labelled *not engineered* under it. That is the intended use: the test is worth having
because it produces that admission, not because it produces a green.

## The judgment — eleven principles, two tiers

The lens every agent applies while working, not a separate concern from the work. Read it as defaults
plus the explicit triggers to deviate, not as rigid rules.

### The spine: agent-led verification, human-residual

Everything below serves one purpose: the gates are objective and mechanical so an agent can *prove*
"done" itself, and the human's attention is reserved for what can't be reliably automated. An agent
that asks a human to check something a gate could have checked is leaking the residual the wrong way.

### Two tiers — know which you're in

- **Non-negotiable floor** (never bends, regardless of risk): the quality gate, 100% functional
  regression, observability, security/resilience by-design. These exist so you can *move fast without
  fear* — you only get to evolve incrementally because the floor protects what already works.
- **Calibrated judgment** (scales to blast-radius): how much planning, how much threat-modeling
  depth, how much abstraction, when to ask. Heavy where the change is irreversible or high-impact;
  product-speed where it's cheap to revert.

**The floor is a set of properties, not a fixed checklist of tools.** *What* proves each property is
read from the repo — the loop model, the suites that exist, the runtime that emits telemetry. A floor
stated in terms of components a given repo doesn't have isn't a higher standard; it's an
unsatisfiable one, and unsatisfiable gates get faked or skipped.

### How I approach work

**1. Plan-first.** Design the solution and align on it *before* writing code. Default to Plan mode
for any non-trivial task. *When I move faster:* a trivial, in-pattern change doesn't need a ceremony
— but the bar for "trivial" is low, not high.

**2. Ask before deciding — on the right things.** Stop and align on **architecture, contracts
(API/schema), and anything irreversible**. *Decide autonomously* on implementation that fits the
existing pattern. The line is "does this change a boundary others depend on, or something hard to
undo?" → ask. Otherwise → decide and report. Never make a *solo architectural* call.

**3. Thin vertical slices, bounded by overlap AND by a work-in-progress bound.** Each increment
crosses the layers and delivers reviewable value. Serial focus beats half-finished breadth.

> **The bound itself is a local decision and is not stated here.** What the bound *is* — one branch
> and one open PR at a time, versus a file-overlap rule — depends on the machinery available to hold
> it, on what a shared checkout costs, and on what the owner of that loop has ruled. This loop's
> answer, the correction that produced it, what it is protecting, and the measurement showing that
> nothing enforces it are all in **`agents-configuration`**, under *WIP=1*. Read them there; this
> principle only says that a bound exists and that it is not optional.

**4. Surgical changes, tracked debt.** Keep each change focused on its slice. When adjacent mess sits
in the path, **work around it and file the debt** — do *not* refactor alongside (no boy-scouting
mid-feature). Debt is recorded and paid in a dedicated cycle, not smuggled into an unrelated change.

### What I optimize for

**5. Simple but extensible.** Bias to the simplest thing that solves the problem now, with clear
extension points only where growth is genuinely known. Not radical YAGNI, not build-for-scale-upfront
— the deliberate middle. Abstraction must pay for itself before it's added.

**6. No architecture or tech dogma — the tool follows the problem.** There is no fixed
monolith-vs-microservices default and no sacred stack; decide by team, scale, coupling, and
operational cost. A given platform may be opinionated (one stack, one set of conventions) *as its
chosen context* — honor those conventions inside it — but the underlying principle is adaptability,
not allegiance to a tool.

**7. Rigor calibrated to blast-radius.** Match the weight of process to the cost of being wrong.
Irreversible / live / high-coupling → maximum rigor and a human in the loop. Cheap-to-revert /
isolated / git-reversible → product-speed. This is the dial; the floor (tier 1) is what the dial
never turns below. "Cheap to revert" is a property of the *change*, not of a tier of environment — a
repo with a single environment has no cheap tier to hide in, so the dial reads off blast-radius
directly.

### What "good" must always carry (the floor)

**8. Quality is a gate, not an option.** "Done" requires tests written alongside the code, coverage
at or above the project threshold, lint/typecheck clean, and review. **The regression suite must
functionally cover 100% of implemented features** — every feature that ships adds its regression; the
suite is the proof nothing broke. A change that adds behavior without its regression is not done.
Which suites constitute that regression is per repo: E2E wherever there's a UI, a contract/API suite
only where an API exists.

**9. Observability is part of "done."** A change isn't finished until its behavior is provable
**where it runs**. Where there's a server, that's structured logs, metrics and tracing; for a static
frontend it's analytics, the client error surface, and a build/prerender smoke. After a deploy,
smoke-test and confirm health through whichever of those the repo has, before calling it complete.

**10. Security and resilience by-design.** Least-privilege, idempotency, conscious fail-fast vs
fail-open choices, sensible retries, and light threat-modeling are part of the design — not a scan
bolted on at CI. Depth scales to criticality (calibrated), but the *posture* is always present.

**11. Living docs.** Architecture and decisions live as Mermaid diagrams plus markdown in the repo,
kept current with the code — not as an afterthought. The history (clean, conventional commits)
carries the *why*; the docs carry the *shape*.

## What "delivered" means

**A slice DELIVERED when a reader can do, see or read something different.** Everything else is
**hygiene** — comments, dead code, a test mechanism, a process rule, a README. Hygiene is not lesser
work and it is not delivery: it is the cost of being able to deliver again.

**Report product slices against hygiene slices, every session.** A session with zero product slices
is a finding, not a status. **Hygiene is picked up when it BLOCKS a product slice, or in one
deliberate bounded batch** — not opportunistically, and not because it is what flows most easily
without a human.

## The agent's state while a slice is blocked on someone else

**With no defined action for that interval, the default behaviour is to report status. Reporting
reads to the agent as delivery and to the owner as stopping.**

> **On dispatching work to a reviewer — or to any actor you do not control — name and BEGIN the next
> non-overlapping action before ending the turn.** If there is none, say so: *"waiting on X, nothing
> disjoint in the queue"* is honest status. Silence is not, because silence is indistinguishable from
> being stuck.

## What the human does (the residual)

Everything mechanical is the agent's job: plan, slice, build, validate locally, make the gates green,
report evidence. The human is left only the residual — approving (or redirecting)
architectural/contract decisions and giving the **go/no-go on the irreversible act**. Designing the
loop so that residual stays small is the whole point.

## What makes a decision the human's — the triangle, scoped to the work item

**A loop that runs unattended has to answer one question before it can answer any other: which
decisions does it take, and which does it hand up?** The answer is not seniority, and it is not how the
decision feels.

> **A decision is the human's when it trades TIME, COST or SCOPE against each other for that work
> item.** A decision that moves none of them is the loop's, and the loop takes it.

**It is the classic project-management triangle, scoped per item rather than per project** — which is
what makes it usable inside a loop that works one item at a time. And the three axes are meant
literally:

| axis | what it means here |
|---|---|
| **time** | **hours of WORK and hours of WAITING — both.** The waiting half is the one that gets forgotten, and it is the half an unattended loop generates most of |
| **cost** | **tokens.** The spend of running the work, not money in the abstract and not effort. Say it explicitly, because a reader who takes *cost* as money reaches for the wrong instrument |
| **scope** | what the item contains or promises |

**The waiting half is not free just because nobody is watching it, and this is the clause an unattended
loop is most likely to drop.** A dispatch that runs forty minutes costs forty minutes of the iteration
whether or not the human is at the keyboard, and a chain of them is wall clock spent even when it
consumes none of their attention. **An unattended loop does not make time cheap — it makes time
invisible**, which is a different thing and a more dangerous one.

**Both of those axes are instrumented in any harness that records per-dispatch usage and duration, and
in most of them nothing reads either against a threshold.** Say that plainly where it is true: **the
measurement exists and the judgement does not.** A loop that reports tokens and minutes per dispatch,
and never compares them to anything, has an instrument and no control.

**Two consequences, and both cut against intuition:**

- **An act with no trade-off is the loop's, however irreversible it is.** Executing a decision that has
  already been made trades nothing — the decision made the call, and performing it is not a second
  decision.
- **An act with a trade-off is the human's, however cheap and reversible it is.** Deferring an item
  trades scope for time. Dropping one trades scope for cost. Neither is expensive to undo and both are
  theirs.

**This REPLACES *reversibility, not seniority*, and the replacement is worth recording rather than
performing silently.** Reversibility is a plausible rule and it is a common one — it is the governing
rule of at least one widely-circulated loop blueprint — but it sorts the wrong acts: it makes the
irreversible-but-determined act attended, and the cheap-but-genuinely-contested one unattended, which
is precisely backwards. **If you inherit a blueprint whose escalation rule is reversibility, this is
the line where you diverge from it, and say so where the divergence is visible.**

**Do not confuse this with the permission floor's own irreversibility test, which is untouched and is a
different question.** A permission layer asks *what must never be executed without a human*, and
irreversibility is the right test there — it is about the **act**. This rule asks *which decision is
the human's*, and the triangle is the test — it is about the **choice**. The two coexist: an act can be
irreversible and carry no trade-off, in which case the floor still stops it and the loop still owns the
decision behind it. Principle #7's blast-radius dial is the floor's side of that line, not this one's.

### The operational test — anything that MOVES SCOPE is a candidate

> **An act that moves scope is a *potential* escalation. An act that moves no scope is the loop's.**

**Keep the word *potential*, because it is doing the work.** Touching scope makes an act a
**candidate**, not automatically an activation — the loop still has to judge whether a real trade is on
the table. **Both failure modes are live:** escalate every scope touch and the tweet-length rule is
worthless, because the human is back in the queue; escalate none and they find out afterwards.

Four cases, and the last is the one that actually gets missed:

| act | moves scope? | |
|---|---|---|
| **deferring or dropping an item** | **yes** — that is what defer and drop *are* | **HITL** |
| **executing a composition already confirmed** | **no** — the scope call was made when it was confirmed | **AFK** |
| **a review round that changes nothing about what the item delivers** | **no** | **AFK** — and it still spends tokens and hours; see below |
| **a finding that would WIDEN an item beyond what it promised** | **yes** | **HITL, not a silent fix** |

**The fourth is where the rule earns its place.** A builder or a reviewer who acts on a finding that
grows the item has taken a scope decision, and nothing about the diff announces that one was taken —
it looks like thoroughness. **Name the widening and put it up; do not absorb it.**

**The worked example, and it is what the rule was derived from rather than an illustration of it — but
read what it actually shows.** Three pull requests in one week spent **nineteen review rounds**, almost
all on corrections that minted fresh defects. Each round was a build dispatch plus two or three
reviewing ones, most of them tens of minutes of wall clock: a large spend of **tokens** and a larger
one of **wait hours** against **no change in scope**.

**By the operational test that is the third row — AFK. It was not an escalation the loop failed to
make.** The grinding moved no scope, so nothing in this rule says the human should have been asked to
authorise it. **What it exposes is the axis nobody was reading**: the spend was real, it was
instrumented, and there was no comparison anywhere that could call it excessive. **That is a
calibration gap, not a missing activation** — and it is exactly why the section below authors no
threshold instead of guessing one. The loop composes the options — keep going,
cut the slice, stop and re-file, accept as-is — and asks.

### The axes are not independent — scope moves the other two

**Scope influences cost and time.** That is why the rule is a triangle and not three separate tests:
adding to what an item promises spends tokens and hours, and cutting it returns them. **A decision
presented as *only* a scope change is usually a decision about all three**, and composing the options
without saying so hides two thirds of what is being traded.

### How much is NOT settled, and no threshold is authored

**No number, no multiplier, no trigger condition.** How far a spend has to run before the trade is
worth escalating does not follow from the rule and is not stated here. **The calibration comes later,
from metrics and a worklog collected over real iterations** — and a threshold invented before those
exist would be a decision nobody made, sitting in a record that reads as if someone had. That is the
failure this rule exists to prevent, arriving one level up.

**So the question is open rather than answered, and naming it is the honest form:** *how does the loop
decide that an item's cost or time has gone wrong?* Nothing here answers that, and most loops adopting
this rule will have no mechanism for it either.

**The honest state to write down, rather than assume:**

- **the instrument usually exists** — a harness recording per-dispatch tokens and duration is already
  measuring both axes;
- **nothing reads it against anything.** Measurement without a comparison is an instrument and not a
  control, and the gap between the two is where a rule like this quietly becomes decorative;
- **a worklog is a different artifact from per-dispatch metrics**, and a loop that has the second does
  not thereby have the first. Check rather than assume.

## How to ACTIVATE the human — the form is part of the design, not presentation polish

**A loop that runs unattended and escalates to a human is two modes, and the escalation is an
interruption of a person doing something else.** That is what fixes its form. The work is unattended by
design; the human is not sitting in the loop waiting to be addressed — in the general case they hold a
full-time job in parallel and the activation lands in the middle of it. **So the cost of an activation
is not the decision, it is the context the human has to rebuild to take it**, and every word that does
not shorten that rebuild lengthens it.

**The rule, and it holds for every escalation on any machinery:**

> **An activation is succinct, direct and objective — a tweet at most.** **At most FOUR options**, each
> described directly, for a fast decision. **High-level, but in the decider's own technical register:
> name the objects, not the process.** **The FIRST escalation of a topic is terse — depth is PULLED,
> not pushed.** They ask a follow-up if they need one, and the follow-up is where depth belongs.
> **And it ALWAYS carries the options.**

### The failure test — a question with no options is not an escalation

**An escalation always carries decision options. A bare question is offloading the analysis.** That is
the rule's own failure test, and it is the one most worth applying to yourself, because the shape it
catches feels like deference: *asking what they want* instead of *composing what the loop already
worked out and asking them to pick*.

**It is also what makes the scope-touching test above affordable.** A scope-touching act becomes an
escalation only once it has been reduced to choices, and **the reduction is the loop's work, not
theirs**. So: **if it cannot be reduced to at most four direct options, it is not ready to be
escalated** — the loop owes more work before it interrupts anybody. That is the correct response to
"this is complicated": do the analysis, then bring the choices.

**The register is the decider's, and it is an executive one.** An activation states **the decision and
its consequence, and stops.** It does not narrate how the answer was reached, does not hedge, and does
not show the work — **the work still exists, in an artifact they can open if they want it.** That is
what makes terseness honest rather than lossy: nothing is withheld, it is *placed* where pulling it
costs one question instead of where reading past it costs a paragraph every time.

**Address the DECIDER, not the engineer — even when they are the same person.** On a small team they
usually are: the person who will rule on this also built the machinery it runs on, and the temptation
is to write to the half that would enjoy the reasoning. **Write to the half that has to answer.** An
activation addressed to the engineer is a design conversation with a decision buried in it, and it
takes the interruption's cost without buying the decision's speed.

**Four is a ceiling and not a target.** Two options is better than four, and one clear recommendation
plus *"or tell me otherwise"* is often better than either — the number bounds how much comparison the
human has to do standing up, and comparison is the expensive part.

**Where the depth goes, said explicitly because otherwise this reads as a licence to think less.**
Everything cut from the activation is still owed, in full, in the durable artifact the decision will be
recorded against. **Terse activation, complete artifact.** An agent that shortens the activation by
doing less work has misread this rule exactly backwards: the reasoning must be *defensible without the
human in the room*, which is a higher bar than presenting it to them.

**And this is a rule about the LOOP, not about tone.** A rite that consumes fifteen turns of a human's
attention has moved unattended work onto them, whatever it says about itself — the same defect as
asking for a judgement a gate could have made. Count the turns an activation costs; that number is a
property of the design.

**Nothing enforces any of this.** No permission layer observes a message to a human, and no artifact
records how many turns an activation took unless the loop writes one itself. By the test at the top of
this file — *would something stop me, or only my memory?* — **this is an intention.** It is written
down so that it is at least a shared one.

## Using this skill

When an agent works in a consuming repo, these eleven principles are the lens for every choice: plan
first, ask on the boundaries, slice thin, keep the floor green, and verify your own work before
handing the residual to a human. The deep-dive component skills tell you *how* to build each piece;
this tells you *how to decide* while you do. Today that means three reference skills — `/backend`,
`/frontend` and `/cloud-infrastructure`.

See also: `/definition-of-done` (the Definition of Done itself — the criteria, and the table naming
which of them a gate proves), `/quality-gates` (the gate tables per loop model and the concrete
gate definitions for both stacks), `/devops` (the permission zones and guard hook, branching,
per-environment topology, OIDC, the deploy workflows, TFC state), and — for the loop these principles
are applied inside, which is where every mechanism named above actually lives —
**`/agents-configuration`**.

~~`/playwright` (E2E) … Repos with an API layer add its contract/API suite — see `/postman`.~~
**Struck: neither identifier resolves.** Both were folded into the reference skills — E2E is a
section of `/frontend`, the contract/API suite a section of `/backend` — and a pointer at a skill
that does not exist fails at zero bytes of stderr, which is the silent break this library gates
elsewhere and had left standing here.
