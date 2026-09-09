# Portable prompt — the loop mode is a named agile method, and a mode contract needs an untouchable list

**Who this is for.** An engineer running an agent development loop on machinery nobody here has
measured, who wants to make *how work flows* configurable without making *what may never happen*
configurable by accident. **It is written to be adoptable with no hooks, no permission layer, no
per-agent identity stamp and no gate of any kind** — every sentence below is either an obligation you
can decide to hold or a measurement you can re-run in your own tracker.

**What it deliberately is not.** It carries no configuration from the loop it came from — no file
paths, no rule numbers, no persona names, no enum values you are expected to copy. **Behaviour, the
reasoning behind it, and the limit.** Where the limit is *"nothing enforces this"*, that is the
sentence, not a gap in the write-up.

---

## 1 · The move: a mode is a NAMED method, not an invented word

**Make the loop's working mode an enum of widely-known agile method names, and start with the one you
are already running.**

The first draft of this idea in its home loop proposed a mode named after how the work *feels*. It was
retired before it shipped, for a reason that ports: **an invented name has to be explained to every
reader, and a borrowed one explains itself.** A person who has never seen your loop can read *scrum* or
*kanban* and immediately know what to expect and — the part that matters — **what to ask for**. That is
legibility, not conformance: you are not adopting the method, you are borrowing its vocabulary so a
human can steer.

**The consequence is the valuable half:** a third mode later is a new member of a documented set rather
than a new design conversation. The shape is fixed once.

**And the cost of borrowing a name is that you inherit its expectations.** If your `scrum` runs no
estimation ceremony and demos to nobody, say so where the name is declared. **A borrowed name is a
promise to a reader**, and an unmarked deviation is the reader discovering, mid-loop, that a word meant
something narrower than they read.

---

## 2 · What actually differs between the two modes — and it is smaller than it sounds

**The honest finding, and the one most likely to be got wrong: the difference is mostly what happens to
the ITERATION CONTAINER, not what happens to the work.**

The work is identical in both modes. The item is still filed in the tracker. The description is still
closed before anyone builds. The build still opens a change request. The gate still runs on the diff.
**What changes is the box the work sits in and the ceremonies at that box's edges.**

**And the sharper finding, which took a separate ruling to reach: the container is DEMOTED, not
removed.** The first draft of this comparison had the lighter mode carrying no container at all. That
was wrong, and the correction is transferable because the container does **two** jobs:

- **as an IDENTIFIER** — it names a period and groups the work, and where an effort spans more than one
  repository it is often the only string the two sides pair on. **The lighter mode has no objection to
  any of that**, and deleting it costs the grouping for no gain.
- **as a BATCH BOUNDARY** — a scope commitment whose exhaustion is a terminal condition. **This is the
  half the lighter mode drops.**

**So the axis is *commitment versus label*, never *present versus absent*.** Ask that question of your
own container before you write either mode down; it makes the enum smaller and it removes the strongest
objection to the lighter mode.

| | the heavier mode | the lighter mode |
|---|---|---|
| the container | a **commitment** — it bounds a batch, and its exhaustion is terminal | a **label** — the same object names a period and bounds nothing |
| the ceremonies at its edges | planning, review, retrospective | **none run at a boundary** — see §4 |
| ordering | ranked at planning | **arrival order, within a priority partition** |
| the queue | **the tracker** | **the tracker** |
| the quality gates | **yes** | **yes** |
| the unit of work | a filed item | **a filed item** |

**The bottom three rows are the point.** A lighter mode that also dropped the tracker or the gates
would not be a mode — it would be a different loop, and it would not be reviewable. **Drop the ceremony
and the container. Keep the tracker, the gates and the floor.**

**One rule survives the container, and it is worth naming because it looks like it should not:** a
standing *priority partition* — one class of work always worked before another — costs no ceremony,
because it is a rule rather than a per-item decision. So *"arrival order"* usually means **arrival
order within a partition**, which is still simple and is still not a ranking.

---

## 3 · The untouchable list — write it as a MEASUREMENT, not as a principle

**A mode contract's most important section is the list of things a mode may never vary.** Write it
before you write the modes.

> **A mode selects a predicate and a ceremony set. It never selects a permission rule.**
> **A configuration surface that can reach the irreversible floor is a hole with a nice name.**

The list itself will be specific to your loop. The classes are not:

| a mode MAY vary | a mode may NEVER touch |
|---|---|
| the queue predicate's container term | **the irreversible floor** — whatever refuses the acts that cannot be undone |
| which ceremonies run, and what fires them | **the merge/acceptance gate**, on every change |
| the ordering act | **verdicts scoped to the exact revision they read** |
| the work-in-progress parameter (the slot — §5) | **who may open work** |
| whether an estimate is part of the readiness bar | **the routing that decides which review a change gets** |
| the container object itself | **any class of work you have decided has no second mode** |

**Now the part that makes this worth doing: DO NOT publish that table as an intention. Measure it.**

The question is mechanical and cheap: **does any enforcement component in your harness read any object
that a mode varies?** In the loop this came from, the answer is no, and it was established by
enumerating every registered enforcement component and grepping each one for the mode vocabulary and
for the tracker fields a mode changes — container, labels, ordering. Every occurrence was a comment or
a refusal message; none was a lookup.

**Two rules for doing that in your own harness:**

- **Enumerate the components from the registration, never from the directory.** A file on disk that is
  not registered enforces nothing, and a registered component you forgot to list is the one that makes
  the answer wrong.
- **Calibrate every zero.** Re-run the same search with a token you *know* is live code. If that also
  returns nothing, your search was dead and your zero meant nothing. **A check whose result is
  unconditional is not a check** — and a search that fails open reads to whoever runs it as *nothing to
  worry about*, which is worse than publishing no command at all.

**The limit, and it is the reason to re-run this rather than cite it.** A green here is a fact about
*today's* components. The moment any enforcement component is taught to read the mode, the separation
stops being structural and becomes a promise. **If a later change needs the floor to know the mode,
that is a review that happens before it is written, not after.**

---

## 4 · The ceremonies: the comparison is CLOCK versus NOTHING, not clock versus boundary

**The standard argument for the lighter mode is that its ceremonies run on a clock instead of on a
scope boundary.** That is right, and the way it is usually sold is wrong.

**Check first whether the boundary trigger you are giving up actually fires.** In the loop this came
from, it does not and never did: the rites were triggered by *"the queue reached the end of the batch
it started with"*, which is a state **no component observes**. The rites exist as commands a human
types. So the honest comparison was never *reliable clock versus reliable boundary* — it was **clock
versus nothing**, and on that comparison a clock is strictly more available.

**So say which of the two you are in before you argue the trade.** If your boundary trigger genuinely
fires, moving to a clock is a real trade with a real loss. If it does not, you are not removing a
mechanism; you are naming an absence.

**And if you build the clock: build a NOTICE, not a control.** Something that says *a rite is owed*
at the start of a session, and nothing more. It cannot run a ceremony — a notice cannot dispatch — and
converting it into something that refuses work would be a control with no ruler behind it.

**The rule that decides whether the clock is real: key it on the CLOCK and never on the queue being
empty.** This follows directly from §2's demotion and it is the single place this design leaks. Once
the lighter mode keeps the container as a *label*, an empty container looks identical in both modes and
means opposite things — **terminal in the heavier one, nothing at all in the lighter one.** A trigger
keyed on emptiness therefore makes the lighter mode **silently inherit the heavier mode's trigger under
a different name**, and fire a ceremony on noise. **Write that constraint down before the carrier is
built**, not after: it costs one sentence while nobody has implemented the wrong thing, and a rewrite
afterwards.

**Three limits to carry with it:**

- **A per-session notice sees ONE root.** If your effort spans two repositories, you have two stamps
  and each one reports its own healthy cadence. **Do not build sibling discovery to fix this**: a
  detector that must first guess where the other tree is, in order to compare a string, is assuming
  what it checks. Keep one stamp, in the place the rite's own artifacts land, and have the notice name
  both places.
- **It reports one session late, by construction.** For a cadence that is correct behaviour. For
  anything else it is not.
- **A reminder nobody acts on is a nag.** Whatever you build needs a debounce, or it trains people to
  scroll past the one surface you wanted them to read.

---

## 5 · Work-in-progress is a PARAMETER of the mode, not a constant of the loop

**If your loop runs at WIP=1, find out why before you write it into a contract.** In the loop this came
from it turned out not to be a pull-system choice at all — it was **transitional scaffolding with a
stated exit condition**: one item at a time until the model was observable enough to trust, and then
parallelism. **A mode contract that hard-coded it would have baked the scaffolding into the
configuration**, and nobody would have noticed, because the value was correct.

So: **declare `wip` as a slot with a stated type and a stated default. Do not decide its value in the
same change that declares it.** Those are two decisions, and pricing them as one is how a parameter
acquires a value nobody argued for.

**Before you raise it above one, run this check — it is the transferable half.** Ask, for every
artifact your gate requires before it will accept a change: **is that artifact scoped to the exact
revision it reviewed, or merely PRESENT?**

In the loop this came from, the gate's own verdict was head-scoped and safe. **A second required
artifact — a specialist reviewer's marker — was presence-only, and nothing read it at all.** At WIP=1
that costs at most one change's diff. **At WIP > 1, two concurrent changes each satisfy the requirement
with the other's marker.** The failure is silent and it looks exactly like compliance.

**Generalise it:** parallelism does not break the checks that name a revision. It breaks the checks
that count.

---

## 6 · The metric: the lighter mode's number is AVAILABLE, and it is not FREE

**The strongest honest argument for the lighter mode is a metric argument**, and it is easy to
overstate. State it in two halves.

**The half that holds.** A velocity-style metric needs estimation. If your loop runs no estimation
ceremony — and many agent loops do not, deliberately — then you are paying the heavier mode's ceremony
cost and **not collecting the metric that cost is supposed to buy**. A flow metric needs no estimate
from anyone, so it is available where the other is not.

**The half that is usually skipped.** *Available* is not *free*. A flow metric wants four moments:
**item filed → work admitted → work started → work merged.** Measure, in your own tracker, how many of
those you can actually retrieve:

- In the tracker this came from, **three of four are retrievable and the readiness transition is not.**
  A label application is a timeline event, and no ordinary item query returns it; the timeline route was
  refused by the harness's own floor. So the moment the item became *eligible* is unrecoverable.
- **The substitute is the change request's own creation time**, which is a real timestamp on a real
  object and needs no new permission — and it is already what the state model names as the artifact of
  *work started*.

**Then say which number you are reporting.** *Filed → merged* is **lead time**; *work started →
merged* is **cycle time**. They differ by exactly the waiting you were trying to measure, and
publishing one under the other's name is the expensive error — especially on a surface whose whole
claim is rigor.

**Publish every number with the command that produced it, and calibrate it.** A number whose base sits
inside the change that publishes it is not a measurement.

---

## 7 · Two failure modes a mode config introduces, and both are SILENT

These are the two findings least likely to occur to you while designing, and both are properties of
the design rather than of any implementation.

### 7a · The two modes' queue predicates are indistinguishable by their OUTPUT

**The heavier mode's predicate filters on the container. When no item carries one, it returns an empty
set and succeeds.** That is byte-identical to the lighter mode running correctly.

So *"lighter mode, correctly no container"* and *"heavier mode, containers dropped by mistake"* produce
the same result, and a loop that infers its mode from the query reports a healthy queue over a dark
one, with every check green.

> **The rule: the mode is READ from its record BEFORE any queue query, and the predicate is selected
> from it. Nothing may infer the mode from an empty result.**

One sentence, and it is the only place in this design where a wrong guess makes no noise.

### 7b · The readiness bar changes meaning, and everything that reads it is blind to the mode

If an estimate is part of your readiness bar and the lighter mode consumes no estimate, then **either
the bar loses an item in that mode — so *ready* means two different things on two different days — or
the estimate stays as a cost with no consumer.** Both are coherent; pick one, in the contract.

**What makes it a trap rather than a choice is that the label carries no evidence of which bar applied
to it.** Every consumer of *ready* — the builder that refuses an item without it, the queue predicate,
any entry check — sees a label and cannot see a mode. **Price of letting the bar vary: a later switch
back inherits items that were made ready under the other bar, and nothing will tell it to re-check
them.**

**Which is the argument for the answer the loop this came from actually took: keep the estimate in
BOTH modes, and let the readiness bar not vary at all.** The reasoning is worth more than the choice.
The estimate was already a **size signal** rather than a velocity input there — no velocity is
collected in either mode — so dropping it in the lighter mode would have saved two dispatches per item
and bought nothing back, while making the one label the whole intake chain depends on mean two things.
**Keeping it removes an axis**, and every axis a mode does not vary is a place the two modes cannot
drift apart with nothing watching. **The cost, stated rather than absorbed:** the lighter mode carries
a ceremony its own method does not ask for.

**The general move: prefer the mode config that has FEWER axes.** A contract gets better by shrinking.
Where an axis can be closed by making both modes agree, close it — the only thing you lose is a
freedom nobody asked for, and what you gain is one fewer silent divergence.

---

## 8 · The escalation contract: check whether its PRECONDITION survives the mode

**This is the finding worth the whole document, because it is a control removed by a change that never
mentions it.**

If your loop has a written standard for how an unattended run interrupts its human — when a decision
rises, in what form, how many options it may carry — **read its precondition.** In the loop this came
from, that precondition was written against *the iteration*: **no loop running, no escalation**, where
*a loop is running* meant *an iteration is in flight*.

**Read literally, the lighter mode has no iteration, so no escalation ever exists in it, and the entire
form contract goes dark.**

**And it goes dark in exactly the wrong mode.** The lighter mode is chosen for fluidity — *you ask and
it does it* — which makes it the **synchronous** mode, the one with the most interruptions per hour. It
is the mode where a contract for how you are interrupted matters most.

**The fix is two sentences and it belongs in the same change:** re-base the precondition on **a
dispatched agent working a filed item**, not on a container. The rest of the standard usually says this
already; only the qualifiers are container-shaped.

**The general rule:** when you make a container optional, **grep every standard you hold for the
container's name** — not for the rules you think depend on it. The dependency you did not know about is
the one written as a precondition rather than as a step.

---

## 9 · Recording the mode: put it where a human can see the PROPORTION

**A mode nobody can observe from an artifact is a preference, not a configuration.**

The instinct is to record the mode per period so the retrospective can see how often each was used.
**That instinct is right about visibility and wrong about the reader:** the retrospective is a ceremony
the lighter mode removes, so **the watcher is disabled by precisely the mode it exists to watch.**

**Make the record itself the artifact.** A tracked, dated file in the repository gives the proportion to
anyone, at any time, from version history over one path, with no ceremony in the chain. The
retrospective can still read it when it runs; it stops being the only thing that can.

**And the denominator must be TIME, not periods.** A *period* is an iteration, and the lighter mode has
none — a metric denominated in periods inherits the same disappearing container. Weeks work.

**What the record is for, stated so it is not mistaken for a lock:** the risk this whole change carries
is that the lighter mode becomes the default because it is pleasant, and the loop quietly stops
exercising the discipline it was built to demonstrate. **The mitigation is visibility, not a lock.**
*Three months at ninety percent in the lighter mode* is a fact about how your work is sized, not an
accusation about anyone's discipline — and it is only ever available if somebody wrote the mode down at
the time.

---

## 10 · What nothing enforces — say it PER DECISION, because the flattened version is false

**Do not write *"nothing enforces this"* as one sentence.** It reads as *do not try*, and it is usually
false in the permissive direction: some of these are cheaply detectable and some cannot be checked by
any layer, and a reader deserves to know which is which.

| decision | what would hold it | what actually does |
|---|---|---|
| the mode is recorded | a tracked file — versioned, visible in a change request | **nothing reads it**; version history gives a human the proportion |
| the mode is read before the queue query | nothing; no layer sees a query's intent | **an instruction** |
| two roots agree on the mode | a per-session check — but it sees one root and must guess the other | **nothing**; a split mode is undetectable at session open |
| the priority partition is honoured | nothing at any layer — ordering is not a property of a command string or a file tree | **the ordered artifact, and awkwardness** |
| the ceremonies run | a cadence notice (§4), if you build one | **nothing today** |
| the WIP parameter is honoured | a concurrency check | **nothing, if you deleted the one you had** |
| which readiness bar applied to an item | nothing — the label carries no evidence | **nothing — which is the reason to close the axis (§7b) rather than to watch it** |
| a cadence trigger keys on the clock, not on emptiness (§4) | nothing at any layer | **a rule written before its object, which is the cheapest moment to write one** |

**Then apply the test once, out loud:** *if this rule were broken right now, would something stop me —
or only my memory?* **If the answer is memory, the mode contract is an instruction, and it should be
presented as one.** A surface presented as *configuration* invites the reading that something reads it.

That is not an argument against shipping it. **Visibility over a lock is frequently the right call** —
especially for a rule whose failure mode is delay rather than escape. It is an argument against letting
anyone believe more is held than is held.

---

## What to take, in one paragraph

**Name your modes after methods people already know. Write the untouchable list before the modes, and
measure it rather than asserting it. Ask whether your container is being removed or merely demoted —
it is almost always demoted. Treat work-in-progress as a slot and decide its value separately. Close
every axis you can rather than varying it. Check whether the ceremony trigger you are replacing ever
fired, and key its replacement on the clock rather than on an empty queue. Check whether your
escalation standard's precondition names the container you are making optional. Record the mode in a
tracked file with time as the denominator. And state, per decision, what actually holds it — because
on this surface, most of it is you.**
