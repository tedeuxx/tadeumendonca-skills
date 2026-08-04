# Agentic dev-loop — the design, harness-agnostic

**Canonical source:** <https://github.com/tedeuxx/tadeumendonca-skills/blob/main/docs/dev-loop-design.md>
**Raw (for machine lookup):** <https://raw.githubusercontent.com/tedeuxx/tadeumendonca-skills/main/docs/dev-loop-design.md>

> This document describes a working agentic software-development loop **independently of the tool that
> runs it**. It is written to be imported into any agent harness — Claude Code, Kiro, or another — for
> review, adaptation, or reimplementation. Where a concrete implementation is named, it is named as an
> *example of the mechanism*, never as a requirement.
>
> The reference implementation is this repository, a Claude Code plugin. The loop it drives ships a
> public static site (`tadeumendonca.io`) plus this harness itself.
>
> **Status:** current as of 2026-08-04. The roster was cut from nineteen personas to six on
> 2026-08-02 and to five on 2026-08-04, when `marketing-lead` merged into `product-lead` — §2 is
> written against the current five, and the superseded shapes are recorded there rather than here.
> The decision records behind it are in `docs/adr/` of this repo (methodology) and of the consuming
> repo (product). Where this document and an ADR disagree, the ADR is authoritative — it is the record;
> this is the map.

---

## 1 · The problem this loop is built against

An agent that writes code can also *report* on the code it wrote. That self-report is the failure. It
is not dishonesty — it is that the context which produced a solution is committed to it, and cannot see
the shortcut it took as a shortcut.

Three distinct failures follow, and they need **three different kinds of mechanism**, because they fail
differently:

| failure | mechanism | kind of guarantee |
|---|---|---|
| the author judges its own work | **a persona in a fresh context** | only as strong as the model's attention |
| the agent is advised not to do something irreversible | **a pre-execution hook that denies it** | mechanical; a long context cannot argue it down |
| every session re-decides settled questions | **a written decision record** | durable across contexts, and auditable |

The spine is **agent-led verification, human-residual**: the agent proves *done* with mechanical gates
and real evidence; the human keeps the judgement that is genuinely theirs — the irreversible call, the
architectural one, the production go/no-go.

**A guarantee that is only as strong as the model's attention is not the same kind of thing as a shell
script.** Any harness implementing this must keep the three layers distinct and must not present a
prompt-level instruction as an enforcement.

---

## 2 · The roster — five personas, and the rule that produced them

The roster was nineteen. It modelled an organisation: one persona per concern, each with a mandate. In
practice most were never invoked, because **splitting a concern out of the main context creates a
handoff decision, and the handoff costs more than the work**. A persona that is never dispatched is a
document.

The governing rule now is one line:

> **A persona exists only where conflict is wanted** — where someone should be arguing against someone
> else. Anything that generates no disagreement is a competence, and belongs to whoever already holds
> the context.

**A second rule joined it on 2026-08-04, and it is not the same rule.** `marketing-lead` merged into
`product-lead` even though it *did* generate conflict — because **the conflict was internal to one
object**. The product is the site and the site is the owner's professional presence; two leads over one
object produce two verdicts to reconcile at review time, and the reconciliation was the owner's to make
in either arrangement. So: *a persona exists only where conflict is wanted **between two objects***. See
§2.4's superseding note for what the merge had to carry across explicitly.

```
                        OWNER  (CEO)
              decides · ratifies the boundary · the only one who opens work
                             │
        ┌────────────────────┼────────────────────┐
   product-lead              ⇄              tech-lead
   reader, value,                           architecture,
   order, slice size,                       measurement,
   positioning, voice,                      sequencing,
   career, market                           writes the ADRs
   (truth findings BLOCK)
        └────────────────────┼────────────────────┘
                    ONE consolidated demand
                             │
                        developer
              app · infrastructure · pipeline · tests inline
                             │
                  ─── GATEKEEPERS ───
        quality-assurance              security
        technical delivery,            the floor;
        the DoD, and the CAUSE         its own veto
        of any failing gate
```

### 2.1 · The two leads

They sit at the same altitude, below the owner, and **they are meant to disagree**:

- **`product-lead`** — what to build next and at what opportunity cost; whether a slice delivers what it
  promised the reader; whether the flow is honest (tracked work, WIP respected, board matching reality);
  whether the slice is the right *size*. **And, since 2026-08-04, the market half**: positioning, voice,
  cross-surface coherence, and the owner's career — does the presence say the right thing, and does that
  thing win with the people who hire.
- **`tech-lead`** — architecture direction and what a choice costs in six months; feasibility and
  sequencing from the system's side; the measurement plan, starting with *whether the instrumentation a
  guide claims actually exists*; leads the builder. **Writes the Architecture Decision Records** for the
  decisions it holds.

**`product-lead` is the only lead that can block.** Everything it returns is advisory — order, scope,
craft, market fit — with one exception: **a published claim that does not survive being checked is
BLOCKING**, and `quality-assurance`'s criterion 10 holds the merge on it. Because there is no longer a
second persona whose identity carried that signal, the persona must return **BLOCKING and ADVISORY as
two separately labelled classes**; a verdict without the split cannot be applied.

**They consolidate ONE demand before the build.** Two briefs is how one slice becomes two rounds.
Where they cannot reconcile, the disagreement goes to the owner *as a decision*, not downstream as
competing instructions.

### 2.2 · The builder

**`developer`** — fullstack: application, infrastructure, pipeline **and the automated E2E journeys**,
with tests written inline as it goes. It decides *how*, within decisions already recorded; it does not
decide *what* (the issue does) or *whether it ships* (the gatekeepers do).

**The E2E suite is part of the deliverable, not a follow-up.** A slice that changes user-visible
behaviour and leaves the journey for later is half-done, and does not reach a verdict — the gate
requires a green journey for exactly that class of change. Which suites this means is per repo and never
invented: **E2E always; an API suite only where an API exists.** Writing the API obligation into a
backend-less repo produces a criterion answered `n/a → pass` forever, which trains the loop to fake
evidence.

**It does not start on an unfinished issue.** If the description is not closed — no stated acceptance, a
requirement it would have to invent, an unresolved disagreement between the leads — it stops and says so
rather than filling the gap with its own judgement. A guessed requirement is invisible afterwards,
because the code looks just as deliberate either way.

The invariants stay **per-directory**, because they are properties of the code, not of a job title:
application stack decisions, least-privilege and pipeline-only apply for infrastructure, least-privilege
and pinned actions for CI.

**Stated cost, because it is not a wash:** three specialists could not accidentally edit each other's
area. One builder can. That guarantee moved from *capability* to *scope discipline*, which is weaker; it
is compensated by the gate's scope criterion — a slice reaching outside what its issue mentions is a
finding.

### 2.3 · The two gatekeepers — and the MR needs both

**Every merge request is approved by both, dispatched in parallel.** Neither is conditional on what the
diff touches.

- **`quality-assurance`** — consolidates that **every requirement of the issue was met**, using the
  Definition of Done as the *how* of proving it, in a fresh context, each criterion **with evidence**. It
  classifies the change as safe or boundary and either merges the safe class or hands the boundary class
  up. It also **diagnoses**: when a gate fails, or passes for a reason nobody can explain, it returns the
  *cause*.
- **`security`** — answers **the question the issue does not contain: can this cause a problem in
  production?** Dependencies, permissions and IAM scope, secret hygiene, supply chain, the deploy path.
  It holds its own veto.

**The asymmetry is deliberate and worth stating, because it bounds what "objective" can mean here.** The
delivery gate is objective — it has an external ruler. The security gate is **judgement**, because
*"can this break production"* is not enumerable in advance; if it were, it would be a requirement and the
delivery gate would already cover it. A loop that tries to make both objective either invents a checklist
that misses the novel case, or quietly drops the axis.

**A verdict is an artifact on the merge request, not a claim passed back through the orchestrator.**
**Each** gatekeeper writes its verdict there, carrying the commit SHA it reviewed. **Verification runs
in one direction**, and the asymmetry is deliberate rather than an omission: the gate that holds the
merge reads the other's before merging — present, approving, and **naming the current head** — while
nothing reads its own. A verdict on a superseded commit is a review of something else and fails the
check.

**And a gatekeeper that cannot write its verdict does not proceed as though it had.** For the gate whose
verdict *is* read this is automatic — the merging gate finds nothing and holds. For the gate that
merges, it is a rule, because nothing reads its own: **if it cannot record its verdict, it does not
merge.** Without that clause the asymmetry rebuilds the original failure in the half nobody verifies —
a merge with no delivery record, silently. *The trade is reversibility:* a blocked merge is a stall you
undo; an unrecorded merge, where the merge is the release, is not.

*Why both write when only one is read.* The read exists to gate a merge, and only one gate merges. The
**write** exists for a second reason the read does not cover: without it, the delivery verdict — the one
carrying the evidence and the merge decision — leaves no trace at all, which was the original complaint.
An artifact nobody currently queries is still the record of what was decided and why, and it is what a
later audit reads. Requiring the merging gate to be verified by the other would need a third party to
hold the merge, which buys less than it costs.

*Why this is a rule and not hygiene.* Without it, the rule *"do not merge until the other gate approved"*
is checkable only by the party reporting, never by the party waiting — and a relayed verdict has already
reached a gate carrying a **false statement about the diff it approved**. The loop refuses relayed
authority everywhere else; a gatekeeper's veto fires on every merge request, where the human's
ratification fires only on the boundary class, so holding the veto to the weaker standard was backwards.

*What it buys and what it does not, because the limit matters.* It closes **omission** — a merge
proceeding on a verdict that was claimed rather than given. It does not close **impersonation**: a
harness that identifies personas on tool calls, not on authorship, cannot prove which context wrote the
artifact. Naming that limit is part of the design; a mechanism promising more would buy the same
guarantee at the cost of parsing intent out of command strings, which this loop has already learned does
not work.

*And the same principle in the evidence dimension:* a gate reads the diff **from the merge request**,
never from a local comparison against a reference it chose itself. A self-chosen reference is a relay
about what was reviewed — it produced the false statement above, and the identical mistake in the other
direction silently reviews a subset while reading exactly the same.

**The cost of "every MR" lands on diffs with no security surface**, and it has one specific failure mode:
a gate answering `n/a → pass` every time is gating nothing. The mitigation is a phrasing rule, not more
process — **`n/a` is only valid when the gate NAMES the axes it looked at and found untouched.** A
reassurance is not a check.

Both gates also verify the *artifact*, not the diff's appearance. On a build that inlines and prerenders
repository content, a comment-only change is not automatically inert: the question is whether an edited
line can be **emitted**, which is a different question from whether it is a comment.

### 2.4 · What was absorbed, and why that is not the same as retired

The competence was kept; only the handoff was cut.

| absorbed | into | the argument |
|---|---|---|
| debugger | `quality-assurance` | authorship bias corrupts **judgement**, not **investigation** — the gate is already the fresh context, and a finding returned *with its cause* is most of the fix |
| ADR author | `tech-lead` | whoever holds the decision writes its record, in the same merge request as the change it justifies — which was already the rule and never happened, because of the handoff |
| brand guardian · editor · recruiter | `marketing-lead` | measured over one session, the claim-lens and the craft-lens each spent their best findings **outside their nominal lane**; what made them useful was the fresh context, not the mandate |
| product manager · product owner · scrum master | `product-lead` | scope, sequence and flow-honesty are one decision seen from three ends |
| the build specialists (frontend, infrastructure, CI, E2E, static-analysis remediation, performance) | `developer` | never dispatched: the invoking context already held the background, and explaining it three times cost more than doing the work |

**Appended 2026-08-04 — `marketing-lead` → `product-lead`.** The row above stays exactly as written: the
brand guardian, the editor and the recruiter *were* absorbed into `marketing-lead`, and that record is
true of the day it was made. What happened next is that `marketing-lead` itself was absorbed, so all
three now live in `product-lead`.

**The argument is a different one and must not be read as the row above.** Those three were merged
because they generated no disagreement worth a separate dispatch. `marketing-lead` did generate
disagreement — it just generated it *about the same object*. The owner's decision: the product is the
site and the site is his professional presence, one object, one lead; and fewer lead profiles means fewer
agent outputs to reconcile at review time.

**Two things the merge had to carry across explicitly, because a merge is where a capability gets quietly
dropped:**

1. **The blocking veto survived.** `product-lead` was purely advisory. The merged persona is advisory on
   order, scope and craft and **blocking on the truth of anything published** — ratified as a condition
   of the merge, not inferred from it. The report format (two labelled classes) exists because the split
   used to be structural and now is not.
2. **A capability boundary was lost, and it is a real cost.** `marketing-lead` declared `Read, Grep,
   Glob` — no `Bash` — deliberately: it was the one persona reading the private positioning directory
   while its output lands in comments on public repos, so the boundary was a capability rather than a
   promise. `product-lead` carries `Bash` to read the live queue, and the merged persona inherits it.
   That boundary is now an instruction. Its own file records this at the top, where a maintainer meets
   it before trusting any "it cannot write" claim.

**Retired outright:** the planner and the plan-reviewer. The owner writes the specs, in the issues, in
more detail than a planner would produce — the intake step happens upstream of the loop, done by the
person closest to it. *Named cost:* the significance test for "does this decision need a record" is now
applied once, after the code exists, rather than twice.

### 2.5 · Two standing rules above every persona's checklist

1. **The loop is a machine for grinding work down, not for generating it.** A review returning a long
   list of things somebody must now do has converted one slice into fifteen — while looking productive,
   every item real, the queue longer than before. Observed: twenty-two findings on a documentation
   change. Mechanically: blocking findings get the full treatment, advisory findings get **one line
   each**, and **no persona opens work** — only the owner does.
2. **Nothing ships half-done.** The counterpart, and not in tension with the first: grinding a slice down
   means finishing it, not merging the convenient part and leaving the rest unnamed. Close what can be
   closed, and say plainly what could not.

---

## 3 · The flow of one slice

```
owner generates demand                        ← the ONLY origin of work
        │
   [leads]  product (incl. market/voice) · tech
        │   they disagree first, then CLOSE the issue's description together
        │   (a disagreement they cannot settle goes UP as a decision,
        │    never DOWN as competing briefs)
        │
   ISSUE, description closed  ────────────────  nothing is worked that is
        │                                       not in the tracker; an issue
        │                                       in the tracker is not the same
        │                                       as an issue ready for work
        │
   [developer]  thin vertical slice, end to end
        │       app + infrastructure + pipeline + E2E journeys
        │       (+ API tests where an API exists)
        │
   [gatekeepers]  quality-assurance  ||  security     BOTH, in PARALLEL
        │         every requirement      can this break
        │         of the issue met?      production?
        │           + product-lead's COPY LENS when the diff changes anything
        │             a reader or a crawler will see (its truth findings BLOCK)
        │
   ┌────┴─────────────────────────────┐
safe class                      boundary class
merged by the gate              owner ratifies, then merged
        │                               │
        └──────────► merge = deploy ◄───┘
                          │
                post-deploy smoke (not a gate — it cannot revert)
```

### 3.1 · Intake formalism is what buys the gate its objectivity

This is the load-bearing relationship in the whole design, and it is easy to implement half of.

The delivery gate consolidates that **every requirement of the issue was met**. Those requirements are
written by the leads. So **the gate's ruler is external to the gate** — a finding either anchors in
a stated requirement (or in a Definition-of-Done criterion) or it does not block. Taste has no route to
a blocker, not because the reviewer restrains itself but because there is nothing to anchor it to.

Read it in the other direction and the failure is obvious: **a vague issue leaves the gate nothing to
anchor on**, so it falls back on impression, and impression has no stopping rule. Twenty-two findings on
a documentation change is what an unanchored gate looks like.

The work does not disappear when a loop adopts this — it moves upstream, where it is cheaper. A missed
requirement costs a text edit at intake and a full review round at the gate.

**A reimplementation that adopts the gate without the intake formalism gets the cost and not the
benefit.**

**Parallel, not serial.** Dispatching lens → fix → gate → fix serialises what has no dependency between
its parts. The observed cost of serialising was the loop's throughput, not its round count.

**Thin vertical slices, WIP = 1.** Each increment end-to-end and reviewable, finished *through merge*
before the next opens. A green merge request left sitting is the queue forming.

**Two rounds is the budget.** From the third round, the gate's verdict is accompanied by a decision
request: rounds consumed, what remains, and an explicit choice — push through, park, or narrow. The
obligation is one sentence: **state what shipping as-is would cost.** Not whether more could be found —
more can always be found — but what the reader or the next maintainer actually pays.

---

## 4 · The Definition of Done

**The primary ruler is the issue: every requirement the leads stated, enumerated and marked met or
unmet, individually.** A verdict saying "implements the issue" has consolidated nothing. Where the
description is not closed enough to enumerate, *that* is the finding — reviewing it anyway hides that
intake failed.

The Definition of Done below is the **how** of proving the two things the gate exists for: that the
issue was delivered, and that merging will not break what is already running. Each criterion is
verified with **evidence** — a command's real output, a line in the diff — never with "looks fine".

1. **Scope** — one thin vertical slice, end-to-end, no unrelated changes. Adjacent debt is *reported*,
   not fixed inline and **not filed as new work**.
2. **Traceability** — references its issue; acceptance criteria covered by end-to-end journeys.
3. **Tests proportional to the slice** — unit/integration alongside the code to the repo's coverage
   floor; a user-visible change adds a green end-to-end story; a docs change adds none but breaks none.
4. **Gates green with real evidence** — lint, typecheck, build, end-to-end regression, static analysis.
5. **Decision recorded** — if the change crosses a significance boundary (infrastructure, a public
   contract or schema, a fixed decision, a new dependency or tool class, a cross-cutting pattern) it
   references a decision record; otherwise it declares that none is needed.
6. **Observability** — new behaviour is provable *where it runs*. Satisfied by naming the artifact that
   proves it. **`n/a` is a finding, not a shrug**: say what has no observable and why, so a reader can
   disagree. A criterion answered `n/a → pass` every time is gating nothing.
7. **No documentation drift** — affected docs and records updated in the same merge request.
8. **History hygiene** — conventional commit subjects; a real merge commit.
9. **Security posture** — name what the diff touches on that axis and what was checked.
10. **Content truth** — where the diff changes anything a reader or a crawler will see, the content lens
    returned a verdict and its blocking findings are resolved. **And a claim the gate can itself falsify
    against a checkable source fails this criterion whatever the lens returned.**

### 4.1 · A finding blocks only if it names a criterion and a falsifier

**Every finding cites (a) which criterion it fails and (b) its falsifier** — the command, line or file
that would show the reviewer wrong. A finding naming no criterion is **advisory**: reported, never
blocking.

This is not licence to notice less. What changes is that *good observation* and *merge blocker* stop
being the same thing. Without the rule, the ceiling on a review is however much the reviewer happened
to notice — which is how six review passes land on a README.

**The falsifier is what separates process from taste.** *"The prose under-claims"* has none. *"The row
says the gates are blocking; the branch-protection API returns no required checks"* has one, and it is
checkable by someone who disagrees.

### 4.2 · Severity is set by the lens that found it

Each finding is marked **BLOCKING** or **ADVISORY** by the persona that produced it, with a reason. The
party reading a verdict has no basis for ranking it and will treat everything as blocking — which is
how a five-item list becomes five commits. A verdict whose findings are all advisory **does not hold a
merge**, and must say so, because the word *adjust* reads like a blocker.

*Named residual:* nothing catches a lens that marks something advisory when it should have blocked. The
gate's own criterion-10 second half bounds it for false claims; the rest is accepted deliberately,
because a reviewer who freely re-grades another lens's findings recreates the problem this contract
ended.

---

## 5 · The authority model — who may merge

- **Safe class** — documentation, dependency bumps, tests, in-pattern implementation of an
  already-approved spec. If the Definition of Done is fully green, **the gate merges it itself**.
- **Boundary class** — infrastructure and anything threatening continuity; a change to the loop's own
  rules; publishing content in the owner's voice. **The gate never merges these**: it approves pending
  the human and hands the go/no-go up.
- **Significance beats in-pattern.** When the class is unclear, it is boundary.
- **The gate never merges an expansion of its own authority.** A change to the merge rules is boundary
  by construction, whatever the diff looks like.

**Ratification is proven, not relayed.** The owner ratifies by commenting on the merge request, and the
gate **verifies that comment itself** — author, ownership association, and that it post-dates the head
of the branch. A relay through the agent is a notification, never the authority.

**Asking on the boundary, and only there.** Architecture, positioning, anything irreversible or public
goes to the human; everything in-pattern is decided and merged autonomously. *Asking on in-pattern work
is a design defect, not caution* — the boundary is what the human's attention is **for**, and spending
it elsewhere devalues it.

---

## 6 · The mechanical floor

Prompt-level rules are advisory: a long context can talk itself past one. The floor is therefore a
**pre-execution hook** that inspects each command and denies before it runs:

- force-push · history rewrite · hard reset · recursive delete
- infrastructure `apply` / `destroy` from a workstation (pipeline-only)
- secret writes
- any flag that disables the permission system itself

Two companion checks in the same layer: one refuses to open a second merge request touching files an
open one already touches (enforcing WIP = 1), and one lists the open queue at session start.

**Design constraints any reimplementation must keep:**

- **The deny must precede execution.** A post-hoc audit is not this mechanism.
- **The hook must be tested through its *installed* form.** A guard invoked directly by a test, rather
  than through the path the harness actually calls, proves nothing about what ships. A hook committed
  non-executable silently no-ops, and the test suite that never checks it passes.
- **A green that proves nothing is worse than a red.** When a gate is found not to gate, the fix is the
  **gate**, not the finding.

---

## 7 · The decision record

Every architecturally-significant decision is written down in MADR form: context, drivers, considered
options **with their trade-offs**, outcome, consequences including the bad ones.

- **Light gate** — records are written when a change crosses a significance boundary, not for every
  change. *Trade-off:* a light gate can miss a decision that only looked routine. A strong gate would
  miss none and would tax every trivial change, training everyone to write empty records.
- **One decision per record.** Two decisions is two records.
- **The rejected option is half the value.** A record listing only the chosen path cannot tell a future
  reader whether an alternative was weighed or never seen.
- **Supersede, never rewrite.** A reversed decision keeps its file, takes status `superseded`, and links
  forward. An **amendment** appends to a live record; it does not overwrite the reasoning it replaces.
  History is not a gap to be tidied — *why we changed our mind* is as valuable as the current state.
- **Two libraries** — methodology (decisions about the loop itself) and product (decisions about the
  thing being built). The test: does it constrain *this product*, or *any project using the harness*?

This is the layer that makes a fresh, memoryless context coherent with what was already decided. Without
it, isolated contexts re-decide and drift.

---

## 8 · Branching and environments

The reference loop runs **trunk-based with a single environment**: one branch, feature branches cut from
it, merge triggers deploy. The harness declares its model, because the rules differ.

Two consequences that a multi-environment model gets wrong, and that any single-environment
implementation must accept:

- **The merge request carries the gate.** There is no downstream environment to defer a check to, so a
  check skipped there is a check that never runs. The one legitimate exception is an assertion that is
  **unsatisfiable before the deploy exists** — those belong to a post-deploy smoke and must *skip*
  elsewhere rather than fail for a harness reason. The test is not "is it convenient to defer" but "can
  this be true before merge at all".
- **The trunk is the working branch, not a protected production mirror.** Tooling that blocks edits by
  branch context breaks every slice.

**The post-deploy smoke is not a gate.** It runs after publication and can revert nothing. A red one
means the thing is broken and a person must act.

---

## 9 · Portability notes

What is **essential** to the design:

- three-layer separation: fresh-context review · mechanical pre-execution deny · durable decision record
- personas justified by conflict, not by concern
- **intake formalism paired with gate objectivity** — the leads write the requirements, the gate applies
  them as an external ruler. Adopting either half alone gets the cost without the benefit
- nothing worked outside the tracker; an issue is executable only once its description is closed
- one consolidated demand reaching the builder
- **two gatekeepers on every merge request, in parallel** — one objective against the issue, one holding
  judgement over production risk
- findings that name a criterion and a falsifier, with severity set at the source
- an explicit safe/boundary classification, and ratification that is *verified* rather than relayed
- an explicit round budget that converts "this is expensive" into a decision

What is **incidental** to the reference implementation and should be re-chosen per harness:

- the persona *names*, and the fact that they are markdown files with tool grants
- the specific hook runtime, and the command-matching syntax
- the coverage floor, the round budget's number, the CI provider, the cloud
- the choice of MADR over a leaner record format
- trunk-based single-environment, as opposed to a promotion model

What is **known-weak**, stated so a reviewer does not have to discover it:

- **the gate's objectivity is transferred, not created** — it holds exactly as far as the issue is
  complete, and nothing mechanically checks that a description was actually closed by the leads rather
  than nodded through by one
- **the second gatekeeper's `n/a` is enforced by phrasing, not by a check** — nothing catches a security
  verdict that names axes it did not really examine
- one builder means directory isolation is discipline, not capability
- the significance test is applied once, after the code exists, since the design-time reviewer was cut
- a lens that under-classifies its own finding's severity is not caught by anything
- the content-truth trigger is a *rule*, not a list, and nothing mechanical can enforce it — an
  enumeration fails open, so the rule is phrased to fail closed: when it is unclear whether a string is
  reader-facing, it is

---

*Maintained in `tadeumendonca-skills`. If you are reading a copy, the current version is at the canonical
URL at the top of this file.*
