---
description: Assemble everything that could enter the next iteration — the eligible open work plus the proposals the closing rites produced — have it ranked by a context that did not run the session, compose the iteration from that ranking against the ratified rules, and put the WHOLE composition to the owner as ONE activation he confirms or changes. Use when an iteration is about to open, or when the drain hands off at its terminal condition. It assembles, ranks and proposes; it never places.
purpose: give iteration composition an object, so the pool the owner rules on is assembled and ranked by a fresh context rather than remembered by the session that produced it, and so the retrospective's proposals reach a moment where they can be ruled on at all
argument-hint: "<iteration> (the title of the iteration being composed)"
---

Run the planning rite for the iteration named by `$ARGUMENTS`.

**This rite is the consumer the closing rites never had.** `commands/sprint-retrospective.md` produces
per-persona proposal files whose stated consumer is *"a proposal the owner rules on at planning"* — and
until this rite shipped there was no planning to rule in. **`/agents-configuration` said so in its own
words, and that sentence is STRUCK IN THAT FILE by the same slice that adds this one:**
*"PLANNING is genuinely unbuilt and no claim is made about it."* **Read it as the state this rite
closed, not as a live claim** — a command file whose opening argument rested on a sentence its own
merge falsifies would be exactly the defect this repository blocks on, and the strike is what keeps
the citation honest in both directions.

## What this is, and the one thing it is not

**It ASSEMBLES and RANKS. It does not PLACE.** Placement — an item acquiring a milestone — is the
owner's act (#365). ~~held by `permission-guard.sh` rule 10, whose prompt reaches him and nobody else.
Nothing in this rite may set a milestone without his answer to that prompt~~ — **STRUCK 2026-09-04
(#383): rules 10 and 11 are deleted, on the owner's own pricing of the act
(*«mexer em milestones nao é um risco crucial a iniciativa»*).**

**READ THIS BEFORE RUNNING THE RITE.** Setting a milestone is now **allowlisted and silent** — no
prompt, no denial, no record. **The rule that placement is his did not change; the mechanism that
enforced it did, and there is none.** So every placement this rite performs is performed on his
authority as expressed in the rite's own confirmation step, and nowhere else. If you are running this
without him present, you are violating #365 and nothing will stop you.

**Since #393 it also COMPOSES, and composing is not deciding.** It applies rules that are already
ratified to a pool it already assembled, and puts the result to him as one thing to confirm. Read the
three verbs as a sequence with the boundary at the end: **assemble · rank · compose** is AFK,
**confirm** is HITL, **place** is his prompt. A rite that walked him through the pool moved the first
three onto the human, and its first real run stopped at item 1 of 15.

### THE ITERATION IS THIS RITE'S PRODUCT, and that is a completion condition rather than a step

**Owner's ruling, 2026-09-01, verbatim:**

> *«bom, o rito deveria sim criar a iteracao como produto ao final dela»*

**Read the wording exactly: «como produto ao final dela».** The iteration object is what this rite
**produces**, not something it is permitted to create along the way. **A planning that ends without an
iteration object has produced nothing** — it assembled, it ranked, it collected rulings, and it has no
deliverable. That is a statement about whether the rite finished, and it is why step 4a is not
optional and not a nicety at the end of a list.

**One branch is exempt, and naming it is what stops a legitimate outcome reading as a violation: the
owner admitting NOTHING.** Step 3's activation permits *defer*, *drop* and *stop*, so an empty composition is
a real answer — and it creates no milestone, because a milestone with no items is an object nothing
reads. See step 4a. **Every other path through this rite ends with the object or has not finished.**

**This does NOT loosen the sentence above it, and the two are about different objects.** *Placement* is
an **item** acquiring a milestone — ~~rule 10, one prompt per item, his answer each time~~ **now a
SILENT allowlisted edit, N times, with nothing asking anyone**. *Creation* is the **iteration object
itself** — ~~rule 11, one prompt, his answer~~ **still a prompt, but only because `scripts/` sits in no
allow list; that is an absence rather than a control, and one unrelated allow entry removes it with
nothing to say so**. Both are still his **by rule**; the rite performs neither without him **by
discipline**, which is a weaker sentence than the one this paragraph used to be able to make. What the ruling settles is that producing the object is **in scope and is the
point**, after a period when no route to it existed at all.

**It also supersedes #378's own body**, which reads *"It does not create an iteration. Milestone
creation has no route from here (#375)."* That line was correct when written and its **reason** lapsed
when #386 merged the route the same day — and a lapsed reason is not a widened scope, which is why this
build stopped and asked rather than inferring the decision from what had become convenient. The ruling
above is the widening, made explicitly, and it is recorded on #378 rather than only here.

**The failure it closes, measured here rather than imported.** Eligible items sat unmilestoned with
nothing presenting them; the loop-first composition rule (#339) depended on the owner remembering it;
and the `sprint-01` retrospective's proposal files had no consumer at all.

**The count ships with the command that produces it, or not at all.** Re-derived 2026-09-01, and it is
the same predicate step 1 uses:

```
gh issue list --repo <owner>/<repo> --state open --limit 200 --json number,labels,milestone \
  --jq '[.[]|select(.milestone==null)
          |select((.labels|map(.name)|index("ready"))
                  and ((.labels|map(.name)|index("product")) or (.labels|map(.name)|index("loop"))))
          |.number]'
```

**Run it rather than reading a count here.** The class's population moves with the backlog, so this
file publishes the predicate and no number; the dated measurement that motivated the rite lives in
ADR-0002's twenty-ninth amendment, where a record belongs.

**None of those three is a missing decision** — the decision is his and stays his. What was missing is
the thing that puts the decision in front of him — **once, over a finished composition**, with the pool
already assembled, ranked and composed. ~~item by item~~ **struck #393: that form stopped at item 1 of
15 on the rite's first real run**, and the correction is step 3.

**It is executed in the ORCHESTRATOR's context, and that is STILL a requirement — but the reason
changed on 2026-09-04 (#383) and the new reason is weaker.** ~~Rule 10 (`--milestone`) and rule 11
(`scripts/milestone-create.sh`) both **deny a subagent and ask the orchestrator**, because a dispatched
context has no prompt surface for an `ask` to reach. A rite that ran inside a persona could not perform
a single one of its own writes.~~ **Both rules are deleted.** A persona could now perform the
`--milestone` writes — nothing denies it. What still stops one is the milestone-script prompt, which a
dispatched context cannot answer, and **that is an absence rather than a rule**. So: run this in the
orchestrator's context because the rite requires the owner to be present at its confirmation, not
because a layer would refuse you anywhere else. **Only one of its two writes is still mechanically
out of a persona's reach, and that one by accident.**

## The rite is unattended; only its CONFIRMATION addresses him (#393)

**The owner's ruling, verbatim:**

> *«a sprint planning nao é uma atividade hitl»* · *«ela é confirmada pelo hitl»*

**Assembling, ranking and composing are the loop's work. The confirmation is his, once. Placement is
his prompt, per item, and is a separate control that the confirmation does not replace.** That is the
whole of the split, and step 3 is where it is executed.

**The confirmation qualifies as a trade**, which is what makes it his under
`/engineering-standards`' escalation standard rather than by courtesy: composing an iteration moves
**scope** — which items are in, which wait — and scope moves cost and time with it. *Defer* and *drop*
in step 3b are the two options that name that trade outright.

~~**One tension survives and is NOT resolved here, deliberately.** `permission-guard.sh` rules 10 and 11
prompt on **placement** and **creation** — and once the composition is confirmed, neither of those acts
trades anything: the composition already made the call. **They are the #365 floor and this slice
changes neither**; see *What was never elicited* at the foot of this file.~~

**STRUCK 2026-09-04 (#383): rules 10 and 11 are deleted, so there is no floor here to be in tension
with.** The tension it named is resolved by the removal rather than by a decision about the rite — the
owner priced the act below the bar (*«mexer em milestones nao é um risco crucial a iniciativa»*), so the
prompt whose justification was in question no longer fires.

**What still prompts, and it is one of the two, from a different source.** Placement
(`gh issue edit --milestone`) draws no decision from any layer. Creation
(`bash scripts/milestone-create.sh …`) still prompts — because `scripts/` matches no `allow` entry in
either settings layer, which is **an absence, not a control**: an unrelated `allow` entry added later
removes it silently and nothing would say so. Step 4a's own text carries the same reading; this is the
same fact stated where the tension used to be, so a reader meeting it here is not told the opposite of
what they meet there.

## The trigger

**Two routes, and neither is mechanical.**

- **The drain's handoff.** `commands/autonomy.md` states that *"the session's stop is the planning
  handoff, which is the owner's"* — this rite is what that handoff hands off to. It runs **after**
  `/sprint-retrospective`, because the retrospective's proposals are one of this rite's two inputs.
- **The owner types it**, against an iteration he is about to open. That is the ordinary route while the
  loop is being reconfigured outside any iteration, and it is not a lesser path.

**Nothing fires it.** No hook in `hooks/scripts/` reads the queue — every `gh issue` call there is a
write path — and a `SessionStart` or `Stop` hook receives one `cwd` while an iteration is two milestone
objects in two repositories. By this loop's own test — *would something stop me, or only my memory?* —
**this rite is not engineered**, and it must not be described as if it were.

## Step 1 — assemble the pool, from BOTH repositories, enumerated and never named

**Never type a milestone title into a query** (`/agents-configuration`, rule 1: a milestone name that
matches nothing returns empty with exit 0, which is indistinguishable from a drained pool). At planning
the iteration does not exist yet, so the assembly is over **unmilestoned open work** rather than over a
milestone.

Per repository in the workspace:

```
gh issue list --repo <owner>/<repo> --state open --limit 200 \
  --json number,title,labels,milestone,updatedAt \
  --jq '[.[]|select(.milestone==null)
          |{n:.number,t:.title,l:(.labels|map(.name)),u:.updatedAt}]'
```

**`--limit` is part of the predicate, not tidiness.** The default page is 30, and an assembly that
silently truncates composes an iteration out of a subset while reading as complete.

**Three classes come out of that query and they are not interchangeable:**

| class | predicate | what it is |
|---|---|---|
| **eligible** | `(product OR loop) AND ready` | composable now |
| **awaiting the owner** | `(product OR loop) AND NOT ready` | his transition alone on the `loop` lane (record 0015's Corollary 4); surface it, do not rank it |
| **not drained at all** | `content` | selected by him one piece at a time and never batch-drained; present only if he asks |

**`blocked` is orthogonal and removes an item from the pool wherever it sits.**

### The second input — the closing rites' proposals

**ENUMERATE, then select — the same discipline step 1 states for milestones, and it applies here for
the identical reason.** The directory name is not derivable: no command available to this loop reads a
milestone's `state`, so *"the previous iteration"* would otherwise be typed, and a typed directory that
matches nothing makes the glob return zero files. **Zero files and an honest empty retrospective are
indistinguishable** — a plausible zero, which is the failure mode this rite exists to close arriving
through its own second door.

```
ls -d docs/retrospective/*/
```

**Select from what came back. Then read every `## Finding` section in the selected directory.** If the
selected directory holds **zero** `## Finding` sections, do not report a count — **say it as a finding
about the handoff**, naming the directory that was read, because a producer whose output arrives empty
is exactly the thing that must not pass silently. The same applies if `ls` returns nothing at all.

**Since #379 there are TWO closing rites and this step reads BOTH.** `/sprint-review` runs first and
writes one report per iteration into the **consuming** repo, at the path `agents/product-lead.md`
names. Read its **judgement** half only: its mechanical half is evidence the owner acts on directly,
often before this rite runs, and carrying it here would present a fixed-or-not question as a
composition candidate. **A missing sweep report is a finding about the handoff, not an empty pool** —
say so, naming the path that was read, exactly as the paragraph above requires of the retrospective's
directory.

Each finding is a **candidate**, not an item: it has no Issue, no `ready` and no estimate.

**A candidate cannot be composed into the iteration, and it does not get an activation of its own.** It
has no Issue, so there is nothing to admit; and a second activation for the proposals is the queue
returning through the second door — the exact shape step 3 exists to close. **So the candidates enter
step 3's ONE activation as a COUNT, and the default is that none becomes an Issue.** He names any he
wants filed under the *change* option; **an Issue exists only where he says so**, it is filed with **no
milestone** like every other Issue (#365), and it reaches a composition at the **next** planning rather
than this one — it has no `ready` and no estimate, so it is not eligible for this pool by predicate.
The per-finding detail lives in `docs/planning/<iteration>.md`, where he pulls it if he wants it.

**The handoff shape is unexercised and this rite is its first test.** `sprint-01`'s rite produced seven
files and none of them has ever been ruled on. Read a mismatch between what those files carry and what
this step expects as a finding about the handoff, not as a defect in the ruling.

## Step 2 — the ranking is DISPATCHED to `scrum-master`, and here is why

**This rite dispatches `scrum-master` exactly once, to rank the assembled pool. It is the only dispatch
the rite makes.** The decision is recorded here rather than left to a reader, because #378 made it a
condition of building this rite at all.

**Why dispatched rather than ranked in place.** The orchestrator has seen the whole session and is
therefore the context least able to see its own bias in an ordering it produces. That is the same
argument `/sprint-retrospective` already accepts as its mechanism, applied one step earlier —
`agents/scrum-master.md` states it in its own words: *"Selection is otherwise decided by the
orchestrator, which has seen the whole session and is therefore the context least able to see its own
bias in a ranking."*

**Why dispatching it cannot leak placement, which is the property that makes this safe.** It holds
`tools: []` — no `Bash`, no `Edit`, no dispatch — so it cannot assign a milestone, file an Issue or
apply a label even if it tried. ~~And rule 10 denies `--milestone` to **every** non-empty `agent_type`
regardless. Two independent layers, neither of which depends on the brief being obeyed.~~

**STRUCK 2026-09-04 (#383): rules 10 and 11 are deleted, so there is ONE layer, not two.** Re-measured
against the head guard, same payloads, one per line:

```
[scrum-master] gh issue edit 5 --repo o/r --milestone "s2"      -> NO decision from any layer
[scrum-master] bash scripts/milestone-create.sh "s2" --repo o/r -> NO decision from any layer
[scrum-master] bash scripts/milestone-update.sh 2  --repo o/r   -> NO decision from any layer
```

**The paragraph below already argued that the surviving layer is the one doing the work, and that
argument is why this removal is tolerable here rather than alarming.** It read: *"What makes the
dispatch safe today is the FIRST layer — `tools: []`, so there is no `Bash` to spell anything with. The
second is a floor over one act, not a fence around the profile."* That is now the whole of it. **A
subagent holding `Bash` reaches every spelling, because there is no rule left to name one and no
permission layer reads inside a script.** So the warning it ended on is no longer about a future
loosening — **it is the current state, and the only thing standing between this profile and a milestone
write is its empty `tools:` line.** That line is declared explicitly rather than omitted for exactly
this reason (#386: an absent `tools:` key inherits everything the parent holds).

**What it is given:** the three classes from step 1, verbatim, both repositories, with labels and
`sp:N` where present. **What it returns:** a ranked eligible pool and its process findings, in its
own `SELECTION-RECORD` shape.

### The ratified rules ORDER BETWEEN CLASSES AND NOT WITHIN ONE, and that has to be said here

**The rules it applies are ratified** — `loop` before `product` among the eligible (#339), and
eligibility as the pool predicate defines it. **They partition. They do not sequence.** Nothing
ratified anywhere in this loop orders two `loop` items against each other.

**On the pool that exists this is not a corner case, it is the whole pool.** Re-derived 2026-09-01 with
step 1's own predicate: **7 eligible items, every one `loop`, all in one repository, and `[]` in the
other.** Loop-before-product partitions nothing here, so if the rite asked for a ranked sequence with a
per-item rationale it would be asking the profile to compose an order no rule determines — and to
return it under the word *"ratified"*, from the profile built to be the bias-free one, into a milestone
description that becomes the order of record. **That launders, which is strictly worse than ranking in
the orchestrator's context where everyone can see whose order it is.**

**So the sequence within a class is a DECLARED TIEBREAK and is labelled as one: issue number ascending,
which is filing order.** It is mechanical, checkable by anyone, and it is **not** a ruling about worth.
The record says so in those terms, and *What I could not see* carries the sentence **no ratified rule
orders within a class; the intra-class sequence below is a filing-order tiebreak, not a ranking.**

**Why a declared tiebreak rather than "return the classes unordered".** The composition step 3a
produces IS an order, and it goes into the milestone description as the order of record; an unordered
set makes that order the orchestrator's again, silently. A stated mechanical rule has known provenance, which is the property the dispatch
exists to protect. **Why not ratify the tiebreak as an ordering rule:** filing order is not an argument
about what matters, and promoting it would put a rule in the loop that nobody decided.

### The one adaptation planning forces, and it is a circularity

`agents/scrum-master.md` tells it to rank against **the order of record**, and states that the order of
record is *the milestone description*. **At planning that description does not exist yet — this rite is
what produces it.** So on a composition there is nothing to rank against and the instruction is circular.

**Resolution: at planning it ranks by the ratified rules alone, plus the declared filing-order
tiebreak above, and says so in its record's *What I could not see* section.**
`agents/scrum-master.md` carries the same sentences, so the two surfaces agree rather than needing to
be reconciled by whoever reads them. Where an iteration is being **re-planned** and a description
already exists, the ordinary instruction applies unchanged.

**Two more adaptations, because a mandatory field with no legitimate value is the same improvisation
class this section exists to close, one field over:**

- **The `### Selection` block is OMITTED at planning.** Its brief mandates exactly one `profile:`, one
  `stage:` and one `item:`, and forbids hedging — correctly, for a record that names who acts next.
  **At planning nothing is being selected to act**, so there is no honest value for any of the three.
  Omitted, and the brief says so; the alternative — a `profile: none` sentinel — invents a value for a
  field whose whole point is that it never has one.
- **The record lands in ONE file and it is not `docs/selection/`.** The brief's ordinary landing spot
  is `docs/selection/<iteration>.md`; at planning the ranking is embedded verbatim in
  `docs/planning/<iteration>.md` (step 5) and **no selection file is written**. One ranking, one
  artifact. Two files would be two sources of truth for one act, and only one of them would be read.

### Its ranking is advisory and the owner overrules it in the activation

Nothing reads `SELECTION-RECORD` — its own brief says so — and this rite does not make it a gate. The
ranking is the input step 3a composes from, and nothing else. Every admission is still his, at rule
10's prompt, one per item.

## Step 3 — COMPOSE the iteration, then put the whole composition to him as ONE activation

**The rite COMPOSES. It presents ONE activation, not a queue.** This is the inversion of #393, made on
the owner's correction on the rite's first real run, which stopped at item 1 of 15:

> *«a sprint planning nao é uma atividade hitl»* · *«ela é confirmada pelo hitl»*

**Read those two sentences as one rule with a boundary in it.** Composing an iteration is **AFK work** —
it applies rules that are already ratified to a pool that is already assembled, and every input it needs
is in the tracker. What is HITL is the **confirmation**, once, over the finished composition. A rite
that walks him through the pool has moved the AFK half onto the human, which is the loop's own
*"a loop that asks the human on in-pattern work is a design defect"* arriving inside a rite.

**Nothing about assembly or ranking changes.** Steps 1 and 2 are untouched: the same predicates, the
same classes, the same single dispatch, the same ratified rules, the same declared filing-order
tiebreak. What changes is who walks the list — the rite does, and then asks once.

### 3a · compose

Take the ranked eligible pool and produce a **proposed composition**: the ordered list of items the
iteration would hold, and the list it would leave out. Apply only what is already ratified — `loop`
before `product` among the eligible (#339), the pool predicate's eligibility, and the declared
tiebreak. **Invent no ordering rule and no worth judgement**; where nothing ratified decides, the
tiebreak decides and the artifact says so in those words.

**What the rite proposes must be defensible without him, and the defence goes in the ARTIFACT.** For
every item in the pool — admitted and not — `docs/planning/<iteration>.md` carries one line: the
number, the title, in or out, and **the predicate or ratified rule that put it there**, or the literal
`tiebreak only — no ratified rule orders within this class`. **That reasoning does not go in the
activation.** It is the depth he pulls if he wants it, and the whole point of writing it down is that
he does not have to be shown it to rule.

### 3b · activate — once, and in the form `/engineering-standards` fixes

**It takes the FORM of `/engineering-standards`' escalation standard, and it is NOT an instance of
it — say both or the standard gets stretched.** That standard governs an escalation rising out of a
**running** iteration, from a dispatched subagent, about an item in flight. **Planning is none of
those**: it runs between iterations, on a pool, from the orchestrator. What the rite borrows is the
form, because the form is right for any moment that interrupts him — and borrowing a form is not
membership in a class.

Succinct, direct, objective — a tweet at most; at most four options; his technical register, naming
the objects; terse, because depth is pulled and it is already written down in 3a.

The shape, and it is a ceiling rather than a template: **what the iteration is** (count, and the
`loop`/`product` split), **what it leaves out** (count), **and four options.**

| option | what the rite does |
|---|---|
| **confirm** | step 4 runs against this composition |
| **change** | he names what moves — an item out, an item in, an order — and the rite RECOMPOSES (3c) |
| **defer / drop an item** | the ruling is recorded and the composition is recomposed without it. **DROP means withhold, never close** — an Issue he opened is not closed on a rite's advice |
| **stop** | the rite ends, the rulings and the composition are recorded, and no milestone is created |

**`needs a decision first` is not a fifth option and did not survive as one.** Where the rite already
knows an item is waiting on him, it is not eligible and never reached the composition — step 1's
`awaiting the owner` class. Where *he* says an item needs a decision, that is a **change**: the rite
records the question on the Issue, applies `blocked`, and recomposes without it.

**The standing «one question at a time, no multiple choice» rule is NOT broken by the four options, and
the two rules govern different acts.** *No multiple choice* governs an **interview** — eliciting what
he thinks, where a menu puts words in his mouth. *At most four options* governs an **activation** — a
decision he has to take, where the options are what make it fast. This rite now asks **one** question,
which is the strictest reading of the standing rule it has ever satisfied; it is the fifteen-question
form that broke it.

### 3c · recompose, and the loop terminates at TWO activations

**A change recomposes and re-activates once. That is the bound.** The second activation carries the
recomposed iteration and is **confirm or stop**: he confirms and step 4 runs, or he stops and the rite
ends with everything recorded and no milestone.

**Two, because the bound has to be a number and not a judgement.** An unbounded confirm-change loop is
the fifteen-turn walk arriving one round later and wearing a different name — which is the failure this
step exists to close, so a rite that could reproduce it has not closed it. If the second composition is
still wrong, that is a finding about the ratified rules or about the pool, not something another round
of activation fixes: **stop, record it, and the next planning starts from a corrected input.** The
count is visible in the artifact's activation log and by nothing else.

**It does not estimate.** No `sp:N` is produced, requested or required here; estimation is
`/agents-configuration`'s *Estimation* section, with its own estimator sets and its own trigger.

**Placement is still his, and this step changes none of it.** ~~The confirmation is what precedes the
placement prompts; it does not replace them. Step 4 still creates the milestone under rule 11's prompt
and still admits each item under rule 10's, one prompt per item, his answer each time. **A confirmation
is not an authorisation to place** — the two controls are independent, and this rite performs neither
without him.~~

**STRUCK 2026-09-04 (#383), and this is the strike with the most operational consequence in the rite.**
Rules 10 and 11 are deleted. **The confirmation is now the ONLY thing standing between this rite and N
milestone writes** — the per-item prompts it was explicitly described as *not replacing* do not exist,
so it replaces them by default rather than by design. Step 4a still prompts (the milestone script is in
no allow list — an absence, not a control); step 4b's per-item admissions are silent. **Read "a
confirmation is not an authorisation to place" as the rule it always was and as the only remaining
carrier of it: there is no second control to be independent of.**

## Step 4 — produce the iteration, then admit the items, in that order

**This step is where the rite's PRODUCT is made** (see *the iteration is this rite's product* above),
so the order below is not a sequencing preference — 4a is the deliverable and 4b is what fills it.

**The order is load-bearing, and the reason it is load-bearing is narrower than it first reads: there
is a CREATE route BUILT and no UPDATE route BUILT.** `scripts/milestone-create.sh` takes the
description **at creation and nowhere else**. Since the milestone description is where
`/agents-configuration` says the
**order of record** lives, the ordered body has to be known before the object is created — so
composition is collected first and the milestone is created once, carrying it.

**Read *built* literally, because the convenient reading of this is false.** It is not that the harness
*cannot* amend a milestone description — 5f denies the *convenient* spelling of a raw-API write and not
the *available* one, and this rite already depends on the available one for CREATE. Probed against the
head guard, one payload per line:

```
[ORCH]         gh api -X PATCH repos/o/r/milestones/2 -f description=x  -> deny (5f)
[ORCH]         bash scripts/milestone-update.sh 2 --repo o/r …          -> NO decision from any layer
[scrum-master] bash scripts/milestone-update.sh 2 --repo o/r …          -> NO decision from any layer
```

**PATCH is blocked in the same spelling POST is blocked in, and reachable in the same spelling POST is
reachable in.** So the correct statement is: **no update route is built. The same hole is open, and
anyone may write one.** What the CREATE-then-ADMIT order actually rests on is that no such script
exists today — a fact about this tree, re-checkable with `ls scripts/`, not a property of any control.

**And that invitation is guarded PRE-EMPTIVELY rather than left for the slice that accepts it.** Rule
11 was pinned to the literal basename `milestone-create.sh`, so a `milestone-update.sh` written in good
faith would have shipped a milestone write with **neither the `ask` nor the `deny`**, on a route that
looks exactly like the sanctioned one, and #365's human verification would have been absent with
nothing saying so. The rule now matches `milestone-[a-z0-9-]*.sh` in the same two run positions, so the
next script in that family arrives guarded on the day it is written rather than on the day someone
notices. That widening ships in this slice; it is not a follow-up.

**If NOTHING was admitted, 4a does not run and the rite has still finished.** Step 3's activation
permits *defer*, *drop* and *stop*, so the owner ruling everything out — or stopping at the first
activation — is a legitimate outcome, not a failure — and **an empty composition creates no milestone**, because a milestone with no items is an
object nothing reads. **That is the one branch where "a planning that ends without an iteration object
has produced nothing" does not apply**, and it is named here so a legitimate outcome cannot read as a
violated completion condition. Say it in the artifact — *nothing admitted, no iteration created, and
here is the pool he ruled out* — and stop; the rulings are the product of that run.

**4a · create the iteration, once per repository that has admitted items. The ordered body goes to a
FILE first — `Write` it to the session scratchpad — and the file's PATH is what the command carries:**

```
bash scripts/milestone-create.sh "<iteration>" --repo <owner>/<repo> --description-file <path>
```

**The ordered body NEVER travels as a shell argument, and this is a production rule rather than a style
one.** `/shell`'s `--body-file` rule has no per-case exception, and this flag is exactly that class.
Three things make it sharper here than the general shape:

- **A double-quoted argument is INTERPRETED, not merely mangled.** Measured, one call, the argument
  quoted exactly as this step wrote it before this round — and re-run against the file route with the
  identical payload:

  ```
  inline:      "order: 1. #383 `id -u` end · 2. #378 $HOME end"
    -> order: 1. #383 501 end · 2. #378 /Users/... end       # id -u RAN; $HOME expanded
  file route:  description="$(cat -- <path>)"
    -> 1. #383 `id -u` end · 2. #378 $HOME end                # bytes, verbatim
  ```

- **The text is not trusted.** Both repositories are public (`gh repo view --json isPrivate` → `false`,
  twice), so the Issue titles step 1 reads and step 3 composes are attacker-supplied strings, and step
  4a is where they would have been composed into that argument.
- **The corruption is unrecoverable from here.** The description IS the order of record and no update
  route is built (above), so a body that lands mangled is a browser delete-and-recreate.

**The inline `--description <text>` form is REMOVED from the script, not left beside the file route.**
Measured at head: `bash scripts/milestone-create.sh "probe" --description "x"` → `unknown option:
--description`, exit 2. Keeping both would have fixed this caller and not the script — a later caller
picks the convenient spelling, which is the whole reason `/shell`'s rule is written without exceptions.

**This still PROMPTS, and since 2026-09-04 the prompt has a different source — read the difference.**
~~Rule 11 asks the orchestrator; his answer is the human verification #365 demands.~~ **Rule 11 is
deleted (#383).** The prompt you will see comes from the permission system, because `scripts/` matches
no `allow` entry in either settings layer. **That is an absence, not a control**: an allow entry added
later for an unrelated reason removes this verification silently, and nothing anywhere would say so.
Treat the prompt as the human verification #365 demands, and treat its survival as luck rather than
design. The script refuses a duplicate title in that repository and prints what the API returned.

**It works because a hole is open, and this rite repeats that rather than relying on the script's own
header to say it.** Neither the settings matcher nor `permission-guard.sh` looks inside a script, which
is the same blindness that makes `python3 -c "…gh api -X POST…"` reach the write API. **No document here
may claim the raw-API route is closed.**

**Where the milestone already exists** — the owner created it in the browser, or a previous planning
did — **skip 4a and say in the artifact that the order of record was NOT written into the milestone
description, and why.** The reason is that no update route is built (above), not that none is possible.
The composition is still recorded in full in step 5's artifact, so the ordering is not lost — it is
lost *from the field `/agents-configuration` calls the order of record*, which is one more reason that
field is called a weak home there.

**If 4a fails after the human has approved it, STOP. Do not enter 4b.** The script exits non-zero on a
duplicate title (4), an unresolvable repository (3) and any `gh` failure under `set -euo pipefail`, and
prints `created milestone #N` on success. **If that line is not printed, there is no milestone**, and
4b would then issue N `gh issue edit --milestone` calls against a title that does not exist: N more
prompts, N failures, and a half-executed planning whose artifact says a composition landed. Record the
failure in step 5 and hand it back.

**4b · admit each item, one call per item:**

```
gh issue edit <n> --repo <owner>/<repo> --milestone "<iteration>"
```

~~**Each one prompts under rule 10, and each prompt is his verification of that admission.** N items is N
prompts, which is the cost #365 priced and accepted: planning is owner-present by construction, so there
is no path where this prompt fires at a moment he is absent.~~

**STRUCK 2026-09-04 (#383): rule 10 is deleted and `gh issue edit` is allowlisted, so NONE of these
prompt. N items is N silent writes.** The cost #365 priced has been replaced by its inverse: instead of
N interruptions at a moment he is present, there are zero interruptions whether he is present or not.
**His verification of each admission is now the confirmation in step 3 and nothing else** — one answer
covering N writes, given before any of them happen, rather than N answers given as each one does.
Whether that is acceptable is his call and he made it; what must not happen is a reader believing the
per-item verification still occurs.

**An iteration is TWO milestone objects paired by nothing but their title.** Type it identically in both
repositories or the iteration silently becomes two, each derivation succeeding and each reporting a
healthy pool. Nothing detects this.

## Step 5 — the artifact, and what it is standing in for

**The orchestrator writes `docs/planning/<iteration>.md`** on a branch, and **it is the only durable
record that this rite ran** — no `docs/selection/` file is written, per step 2.

**This rite costs a branch, a PR and a gate pass**, exactly as `/sprint-retrospective` says of itself.
That is correct rather than regrettable — it is a `loop` diff and it is reviewed like one. Two things
follow that the retrospective does not have to face, and they are stated rather than inherited:

- **The branch does not exist when the rite starts.** Planning precedes work by construction, so the
  branch is cut *for the artifact*, not found.
- **The tracker writes in step 4 are LIVE and the artifact is not.** If the PR carrying this file is
  rejected, the milestone and the N admissions stand and the only record that the rite ran does not.
  **So write and commit the pool, the ranking, the proposed composition and the activation log BEFORE
  step 4 runs**, and append the confirmed composition, the pendency and the failures after. That does not make the writes reversible — nothing
  here does; `--remove-milestone` is the corrective act and it is the owner's — it makes them
  *recorded* even in the branch that never merges.

The shape:

```
# <iteration> — planning

commit: <the SHA of the repo state the pool was assembled from>
assembled: <YYYY-MM-DD>  ·  repositories: <both, named>

## The pool as assembled
eligible: <n> · awaiting the owner: <n> · content (not drained): <n>
proposals read from docs/retrospective/<previous>/: <n findings across <n> files>

## The ranking as returned
<scrum-master's ranked list, verbatim, and its process findings>

## The composition as proposed — every item in the pool, in or out, with WHY
| # | item | in/out | the predicate or ratified rule that decided it, or `tiebreak only` |

## The activation log
<activation 1: what was put to him, in the form it was put · his answer · activation 2 if there was
one, and the bound is two — see step 3c>

## The composition as confirmed
<the ordered body, as written into the milestone description — or the reason it could not be>

## Estimation pendency this leaves
<the admitted items carrying no sp:N — see step 6>

## What could not be assembled
<what the queries could not see, said as a bound on everything above>
```

**This is NOT the iteration Issue `/agents-configuration` specifies, and it must not be read as one.**
That section specifies *"one Issue per iteration, opened by the owner at planning, whose body is the
ordered list of the items admitted"*, and it was never built; the same file already calls the milestone
description a **weak home** for the order. This file is a third home, and it is better than the milestone
description in exactly one way — it is versioned, diffable and goes through the gate — and worse in one
way: nothing else in the loop reads it either. **The specified object is still owed.**

## Step 6 — report the pendency the drain will refuse on, and do not resolve it

`/autonomy`'s **preflight** refuses to enter while any item in the active iteration lacks `sp:N`, or
lacks `ready` on the `loop` lane. This rite admits items and produces no estimates, so **the composition
it leaves will ordinarily refuse the first drain**.

**That preflight is the command's own self-check and is NOT `hooks/scripts/preflight.sh`.** The names
collide and nothing but this sentence separates them. The hook is #342's dependency door-check;
measured, `grep -cE 'sp:|milestone|iteration' hooks/scripts/preflight.sh` returns **0**, so it has no
opinion about estimates, iterations or this rite. **The estimate preflight is prose in
`commands/autonomy.md` executed by the session**, which means the word *refuses* here describes a rule
someone follows, not a hook that fires.

**That is correct rather than a defect, and naming it is the whole obligation here.** The rite closes by
listing the admitted items carrying no `sp:N` — one line each, no dispatches — so the estimation pass is
a known next act instead of a surprise at the drain's door.

## What this rite does NOT do

- **It does not place work.** He rules; the prompt is his answer.
- **It does not decide what an iteration should contain — it PROPOSES what an iteration should
  contain, and the distinction is the whole of #393.** It assembles, ranks, composes against rules that
  are already ratified, and asks once. **A composition nobody confirmed is not an iteration**: the
  milestone and every admission still go through his prompt, and *stop* at the activation ends the rite
  with nothing placed.
- **It does not estimate.** Step 6.
- **It does not open work of its own.** A proposal becomes an Issue only on his ruling, and never a
  finding of this rite's own — *Review does not open work* applies to a rite exactly as it applies to a
  review.
- **It does not close an iteration.** No command available to this loop can read whether a milestone is
  open or closed; closing is a click in a browser.
- **It does not judge the work.** Whether a slice is correct is `quality-assurance`'s, whether an order
  serves the owner's objective is `product-lead`'s.

## What nothing enforces, said before any green is read

- **Nothing fires this rite**, and no hook can. See *The trigger*.
- **Nothing observes that it ran, or that it ran correctly.** A planning skipped, a planning run over a
  mistyped iteration title, and a planning that composed three items out of thirty are
  indistinguishable from the tracker.
- **Nothing observes that `scrum-master` was dispatched.** `dispatch-metrics-stop.sh` reads an Issue
  number out of the branch name, and a planning branch need not carry one; the profile holds no tools,
  so it leaves no other trace.
- **Nothing observes the ONE-ACTIVATION rule or the two-activation bound.** Both are disciplines,
  checkable by reading the artifact's activation log and by nothing else — and the log is written by
  the same context that would have broken the bound. **A rite that walked him through fifteen items
  and then wrote `activation 1` in its own artifact would be green everywhere**, which is the honest
  statement of what #393 did and did not close: it fixed the instruction, and there is no layer that
  could hold it. A `PreToolUse` hook sees a command string and this act is a message to a human; no
  hook in this harness observes a turn at all.
- **`hooks/scripts/inventory-counts.test.sh` asserts this file's rules are WRITTEN.** It cannot assert
  that a session obeyed any of them, and no arm anywhere claims otherwise.

## What this rite cannot see

- **An item in a repository nobody enumerated.** The assembly is per repository and the list of
  repositories is supplied, not derived — a third tree would be invisible and nothing would say so.
- **A milestone that already exists under a near-miss title.** `sprint-01` against `sprint-1` is two
  iterations that each read healthy, and the create route only refuses an exact duplicate **within one
  repository**.
- **Whether the pool it was handed is the pool that exists.** `scrum-master` is shown a pool and cannot
  query one, so a truncated assembly produces a confident ranking of the wrong set.
- **AN ITEM CARRIED OVER FROM THE PREVIOUS ITERATION.** Step 1 assembles `milestone == null`, so an open
  item still carrying the last iteration's milestone is **invisible to this rite entirely** — not
  presented, not ruled on, and silently still in a closed iteration's contents. **The class is
  REACHABLE, and its population is a moving number — run the predicate, do not read a count here:**
  `gh issue list --repo <owner>/<repo> --state open --limit 200 --json number,milestone --jq '[.[]|select(.milestone!=null)|.number]'`
  over both repositories. It is populated whenever an iteration does not fully drain, which is the
  ordinary case planning exists for. **The corrective act exists and is his:**
  `gh issue edit <n> --remove-milestone`, which rule 10 deliberately did not match precisely because
  taking an item back out is what the loop wants to be easy — **and that asymmetry is what retired rule
  10 at #383: an act undone by one command is reparable, and the audit's criterion is irreparable.** **The rite does not do it and does not
  surface it**, and closing that is its own slice — it needs a second assembly pass over milestoned
  open items, and a rule for which iteration they return to.
- **AN ISSUE CARRYING NO ROUTING LABEL.** Step 1's three classes are keyed on `product`, `loop` and
  `content`, so an Issue with none of them matches nothing, appears in no class, and is dropped without
  a word. **The class is REACHABLE and has already been populated — run the predicate rather than
  reading a count here:**

  ```
  gh issue list --repo <owner>/<repo> --state open --limit 200 --json number,labels \
    --jq '[.[]|select((.labels|map(.name)|index("product")|not)
                  and (.labels|map(.name)|index("loop")|not)
                  and (.labels|map(.name)|index("content")|not))|.number]'
  ```

  **A vacuity assertion is the wrong SHAPE for this claim, and that is the finding rather than the
  number.** An earlier draft published *"vacuous today — the negation of that predicate returns `[]` in
  both repositories"*, and it was already false when it shipped: an Issue filed at 16:11:32Z on
  2026-09-01 carried only `reader-facing`, so the predicate returned one member **before** the head
  that published the emptiness was pushed — and the command printed beside the claim is what showed it.
  **One forgotten label falsifies a vacuity claim**, which makes such a claim a promise that the world
  will stay still. What is stable is the property: **an Issue with no routing label matches no class
  here and is dropped without a word**, and the predicate above is how anyone reads who is in that
  state now.

## What was never elicited — the questions, left as questions (#393)

**This rite was authored without the elicitation step this repository's own process mandates** —
*scaffold, elicit the owner's layer, iterate* — which governs `commands/` as much as `skills/`. The
owner's diagnosis, verbatim: *«voce saiu desenhando ritos sem me entrevistar como gostaria de trabalhar
no scrum movido pelo loop»*. The fifteen-turn walk was a consequence of that, not the whole of it.

**These are open questions, not deferred work, and none of them is answered by inference.** Where a
premise is missing, the honest act is to name the question rather than invent the answer — which is the
same discipline the rest of this file applies to a count.

1. ~~**Do rules 10 and 11 still prompt for the right reason?** Under the trade-off rule, **placement and
   creation trade nothing once the composition is confirmed** — the composition made the call and these
   two acts execute it. **Both rules stay exactly as they are: they are the #365 floor and this slice
   changes neither.** But the prompt at 4a is now justified by *the floor requires a human
   verification*, not by *this is a decision he is taking* — and N admissions is N prompts on a
   composition he has already confirmed once. **Whether that is the right shape is his call**, and it
   is the tension this rite most wants him to look at.~~

   **ANSWERED 2026-09-04 (#383) — and it is recorded as an answer rather than struck, because a struck
   question and an answered one read differently to the next person and only one of them closes.** The
   owner ruled on the premise: *«mexer em milestones nao é um risco crucial a iniciativa»*. Rules 10 and
   11 were deleted in that slice, so the shape he was being asked about no longer exists — **N
   admissions is now zero prompts, not N.** What survives is the *creation* prompt at 4a, and its
   source is not a rule: `scripts/` matches no `allow` entry in either settings layer, which is an
   absence rather than a control. **The question is closed. What replaces it, if anything is wanted, is
   whether an absence is an acceptable carrier for the one verification #365 asked for** — a different
   question, not this one reworded, and it is not put to him here.
2. **What is the right size of an iteration?** Nothing anywhere bounds how many items may be admitted,
   and this rite composes without a target. An over-filled iteration reproduces the unbounded drain
   inside one milestone — `/agents-configuration` names that residual and proposes no mechanism.
3. **What should the activation actually contain?** The four options and the tweet bound are his rule;
   the specific four in step 3b are this file's reading of it and were never put to him.
4. **Is two the right activation bound?** It is a number chosen because the bound had to be a number.
   He has not ruled on it, and the artifact's activation log is the only place it is visible.

**None of these blocks the rite.** They are named here so that the next person to change this file
knows which of its rules are ratified and which are a build's best reading.
