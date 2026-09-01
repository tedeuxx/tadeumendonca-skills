---
name: engineering-standards
description: The owner's engineering preferences, portable to any project — two tiers (a non-negotiable floor, a risk-calibrated judgment layer), the eleven principles behind every call, delivered versus hygiene, and the human residual. Use when deciding how much rigor a change deserves, whether something counts as delivery, or what to do while blocked on someone else. Not this loop's own machinery, state machine or WIP rule (see agents-configuration), and not what done means concretely (see quality-gates).
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

## Using this skill

When an agent works in a consuming repo, these eleven principles are the lens for every choice: plan
first, ask on the boundaries, slice thin, keep the floor green, and verify your own work before
handing the residual to a human. The deep-dive component skills tell you *how* to build each piece;
this tells you *how to decide* while you do. Today that means three reference skills — `/backend`,
`/frontend` and `/cloud-infrastructure`.

See also: `/quality-gates` (the Definition of Done, the gate tables per loop model, and the concrete
gate definitions for both stacks), `/devops` (the permission zones and guard hook, branching,
per-environment topology, OIDC, the deploy workflows, TFC state), and — for the loop these principles
are applied inside, which is where every mechanism named above actually lives —
**`/agents-configuration`**.

~~`/playwright` (E2E) … Repos with an API layer add its contract/API suite — see `/postman`.~~
**Struck: neither identifier resolves.** Both were folded into the reference skills — E2E is a
section of `/frontend`, the contract/API suite a section of `/backend` — and a pointer at a skill
that does not exist fails at zero bytes of stderr, which is the silent break this library gates
elsewhere and had left standing here.
