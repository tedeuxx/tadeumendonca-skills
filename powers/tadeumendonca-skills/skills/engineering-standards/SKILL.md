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

## The escalation standard — when a running loop reaches the human, and in what form

**This is a standard for ONE act: an escalation rising out of a running loop to the human who owns it.**
It is not a rule about every question anyone has for that human, and reading it as one is the failure it
was written after — a design conversation, an interview, an ad-hoc request typed at a terminal are none
of them escalations, whatever their subject.

### The precondition comes FIRST, or the rest is misapplied

> **No loop running, no escalation.** The protocol exists *inside* a running iteration. Outside one
> there is no pendency to escalate, whatever the topic.

**Say this before the form, always.** A reader who meets the form without the precondition stamps every
question to the human as an escalation and applies a four-option contract to conversations it was never
about. That is not hypothetical: it is what happened to this standard while it was being written.

### The full definition — five clauses, all of them, or it is not one

1. **A loop is running** — an iteration is in flight.
2. **A dispatched subagent** hits something on a work item *in that iteration*.
3. **It rises through the protocol** — subagent → main session → the human. Not laterally, and not from
   a context that was never dispatched.
4. **The trigger is a TRADE** of time, cost or scope against each other, for that item.
5. **The form is the contract below**, and it always carries options.

**All five. Four of five is not an escalation, and the missing clause tells you what it is instead** —
clause 1 missing makes it a conversation, clause 2 a design question, clause 4 a status report.

### Clause 4 — what a trade IS, with the axes defined literally

> **A decision rises when it trades TIME, COST or SCOPE against each other for that work item.** A
> decision that moves none of them is the loop's, and the loop takes it.

It is the classic project-management triangle, **scoped per item** rather than per project, and the
three axes are meant literally:

| axis | what it means here |
|---|---|
| **time** | **hours of WORK and hours of WAITING — both.** The waiting half is the one that gets forgotten, and it is the half an unattended loop generates most of |
| **cost** | **tokens.** The spend of running the work, not money in the abstract and not effort — a reader who takes *cost* as money reaches for the wrong instrument |
| **scope** | what the item contains or promises |

**Scope influences cost and time.** The axes are not independent: adding to what an item promises spends
tokens and hours, and cutting it returns them. **A decision presented as *only* a scope change is
usually a decision about all three.**

**The operational test: anything that MOVES SCOPE is a *potential* escalation.** Keep the word
*potential* — it is doing the work. Touching scope makes an act a **candidate**, not automatically an
escalation, and both failure modes are live: escalate every scope touch and the form's brevity buys
nothing because the human is back in a queue; escalate none and they find out afterwards.

**Two consequences, and both cut against intuition:**

- **An act with no trade is the loop's, however irreversible it is.** Executing a decision already made
  trades nothing — performing it is not a second decision.
- **An act with a trade is the human's, however cheap and reversible it is.** Deferring an item trades
  scope for time; dropping one trades scope for cost.

**This is NOT *reversibility, not seniority*, and the divergence is worth recording rather than
performing silently.** Reversibility is a plausible rule and a common one — it governs at least one
widely-circulated loop blueprint — and it sorts the wrong acts: the irreversible-but-already-decided act
becomes attended, the cheap-but-genuinely-contested one unattended. **If you inherit a blueprint whose
escalation rule is reversibility, this is the line where you diverge from it, and say so where the
divergence is visible.**

**Do not confuse either with the permission floor's own irreversibility test**, which is untouched and
answers a different question. A permission layer asks *what must never execute without a human* — about
the **act**. This asks *whose decision a choice is* — about the **choice**. They coexist.

### Clause 5 — the form, and it is part of the design rather than presentation polish

**An escalation interrupts a person doing something else.** The work is unattended by design; the human
is not sitting in the loop waiting to be addressed. **So the cost is not the decision, it is the context
they have to rebuild to take it**, and every word that does not shorten that rebuild lengthens it.

> **Succinct, direct, objective — a tweet at most.** **At most FOUR options**, each described directly,
> for a fast decision. **High-level, but in the decider's own technical register: name the objects, not
> the process.** **The FIRST escalation of a topic is terse — depth is PULLED, not pushed.** **And it
> ALWAYS carries the options.**

**The register is the decider's, and it is an executive one.** State **the decision and its consequence,
and stop.** Do not narrate how the answer was reached, do not hedge, do not show the work — **the work
still exists, in an artifact they can open.** That is what makes terseness honest rather than lossy:
nothing is withheld, it is *placed* where pulling it costs one question instead of where reading past it
costs a paragraph every time.

**Address the DECIDER, not the engineer — even when they are the same person.** On a small team they
usually are, and the temptation is to write to the half that would enjoy the reasoning. **Write to the
half that has to answer.**

**Four is a ceiling, not a target.** Two is better than four; one clear recommendation plus *"or tell me
otherwise"* is often better than either.

### The failure test — a question with no options is not an escalation

**A bare question is offloading the analysis.** That is this standard's own failure test, and it catches
the shape that feels like deference: *asking what they want* instead of *composing what the loop already
worked out and asking them to pick*.

**It is also what makes the scope test affordable.** A scope-touching act becomes an escalation only
once it is reduced to choices, and **the reduction is the loop's work**. So: **if it cannot be reduced
to at most four direct options, it is not ready to rise** — the loop owes more work before it interrupts
anybody. That is the correct response to *"this is complicated"*: do the analysis, then bring the
choices.

**Where the options need composing, compose them below the human rather than at them.** A trade with a
value half and a build half needs both read before the options are honest — and **where two consulted
opinions disagree, the disagreement IS the trade**: it rises as the options rather than being resolved
underneath. Which roles those are is a property of the roster, not of this standard.

### How much is NOT settled, and no threshold is authored

**No number, no multiplier, no trigger condition.** How far a spend runs before the trade is worth
escalating does not follow from this standard and is not stated here. **The calibration comes later,
from metrics and a worklog collected over real iterations** — and a threshold invented before those
exist would be a decision nobody made in a record that reads as if someone had.

**So the question is open rather than answered:** *how does the loop decide that an item's cost or time
has gone wrong?* Nothing here answers it.

**The honest state to write down rather than assume:** the instrument usually exists — a harness
recording per-dispatch tokens and duration is already measuring two of the three axes — and **nothing
reads it against anything**, which is an instrument and not a control. And **a worklog is a different
artifact from per-dispatch metrics**; a loop that has the second does not thereby have the first.

### What enforces this — say it before anyone reads a green as coverage

**Clauses 1 and 5 are partly mechanizable. Clauses 2, 3 and 4 are not, at all.**

- **Whether a loop is running** is a query, so a hook can read it.
- **The FORM is string-checkable** — option count and length — **but only once something says an
  escalation is happening.** Nothing infers that from prose without failing open.
- **Whether a question was a genuine trade, whether it rose through the protocol, and whether four
  options were the right four are none of them checkable by any layer.** Do not build something that
  pretends otherwise: a detector that fails open is worse than none.
- **And every layer available is DETECTION, one turn late.** A permission layer reads a command string
  and an escalation is a message to a human; no layer intercepts one.

By the test at the top of this file — *would something stop me, or only my memory?* — **most of this
standard is an intention.** It is written down so that it is at least a shared one, and so that the
part which can be detected has something to be detected against.

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
