---
description: Run any slice through the loop — intake, the state machine, the inner-loop steps — and apply the judgment (eleven principles, two tiers) behind every decision in it. Use when picking up a slice, proposing a change to the loop itself, or naming Agent Harness Engineering / AI-DLC in public writing. Not what "done" means (see quality-gates), the permission zones and CI/CD workflows (see devops), or the generic, SDLC-wide meaning of ready (see definition-of-ready).
purpose: name and carry the loop itself - the state machine, the intake chain and the judgment inside it - as the one body of knowledge every profile shares
---

Apply Agent Harness Engineering — the owner's name for how this loop is built and run, the state
machine a change travels through, the judgment that shapes every decision inside it — in any
`<project>` repo.

Context: $ARGUMENTS

This is the **universal preload**: the one skill every profile in this roster carries, because
understanding the loop itself is not domain-specific the way the rest of the process library is.
Two companion skills carry adjacent ground and are **not** folded in here: `/quality-gates`
(what "done" means, the Definition of Done, the gate tables) and `/devops` (the permission zones and
guard hook that make the deny-boundary mechanical, plus CI/CD and the branching topology). The single-
vs. two-environment branching topology lives in `/devops` (#227) — this skill keeps only how the state
machine, labels and inner loop work once a mode is chosen, not the mode itself.

## What Agent Harness Engineering is

Most teams point an AI coding tool at an unchanged process and write code faster inside it. Agent Harness
Engineering inverts that: **the loop itself — how a change travels from intent to live, and
every gate and guard along the way — is the thing you engineer.** The code is the output of a
well-built loop, not the point. Its spine is **agent-led verification, human-residual**: the agent
proves "done" mechanically; the human is left only the irreversible/architectural residual.

**The discipline is portable; this package is not the discipline.** Nothing about the design is
specific to one tool — the owner runs the same kind of work with Claude Code in public and with Kiro
internally, which is what lets him tell the model apart from the setup around it. But **this plugin is
the Claude Code implementation of it**, and what it ships to another harness is one layer of three.

~~and ships no Kiro carrier — no configuration, no directory, no gate.~~ **Struck 2026-08-23 (#287).
Two of those three were false, and the sentence is copied verbatim into the Kiro export — so a Kiro
user read *"there is no carrier"* from inside the carrier.** It also erred in the permissive
direction: it understated what ships, which is the half of a stale claim that misleads. There **is** a
configuration and there **is** a directory — `powers/tadeumendonca-skills/`, a generated Agent Plugins
package with its own `plugin.json`, installable from Kiro's own Powers panel.

**"No gate" survives intact, and it is the load-bearing third.** What a Kiro user installs is the
knowledge layer of this harness and none of its enforcement layer: no permission guard, no merge gate,
no persona brief. That is a choice, not only a limit — but the limit is real and was measured on the
installed build: the Power **installer** transports a package's whole tree (everything but `.git`),
while the Power **loader** reads only `plugin.json`, `skills/`, `mcp.json` and `dev.kiro/`. So
`agents/` and `hooks/` would arrive on disk and never activate, which is the reason not to ship them —
an inert brief is worse than an absent one. **That reading is from the shipped bundle, not from a live
install; the version, the commands and what was *not* exercised are in
[`README.md`](../../README.md)'s Kiro section**, which is where this claim is maintained rather than
restated here.

Read a reimplementation against another harness as work someone would have to do, not as
something installed here.

The honest claim it makes (and the one it does **not**): *a development loop that turns AI-native
techniques into production-ready software* — **not** agents running in production at scale. The
loop is the track record; overclaiming the agents is off-discipline.

### The three surfaces this discipline engineers

The loop is a product with three surfaces, and this discipline owns their **design**, not their
execution. The fleet executes (the leads consolidate one demand → `developer` builds →
`quality-assurance` gates it); `product-lead` guards that the flow is *honest* (tracked,
WIP-respected). What has no other owner is the loop **as a system**:

1. **Cadence & flow** — thin vertical slices bounded by file overlap, finish-through-merge. Not "is
   each slice tracked" (`product-lead`'s bookkeeping) but "is the loop *shaped* so work flows — is
   the human's residual small, and does the slice boundary fall where the human's attention is
   actually worth spending?" A loop that asks the human on in-pattern work is a **design defect**,
   not mere friction.
2. **The gates as a composed system** — the gatekeeper (`quality-assurance`), the mechanical hooks
   (`permission-guard`, `wip-guard`, `session-wip`, `session-plugin-version`), the CI gates. The
   failure mode this discipline exists to catch is **a gate that verifies nothing**: a hook committed
   non-executable so it silently no-ops; a job that prints PASS having run nothing; a test that
   exercises the guard through a shell call and so never checks the *installed* form. A green that
   proves nothing is worse than a red. When you find one, fix the **gate**, not just the finding.
3. **The harness as the artifact** — the agent fleet, the principles, and the hooks are themselves
   versioned, tested, and improved. A defect in the loop is a bug in the *product*, filed and fixed
   like any other.

### The move that makes it a discipline, not a vibe

Every guarantee above is **mechanical or it is not real.** "The reviewer holds the merge gate" is
Agent Harness Engineering only once a hook denies the merge to every context but the reviewer; until
then it is an instruction the loop can break — and the same model that skipped a review is the one
trusted to remember. The test, applied to any claimed property of the loop:

> *If this guarantee failed right now, would something stop me — or only my memory?*

If only memory, it is not engineered yet — it is an intention.

### Before a loop change goes into execution — re-derive the state model

**Owner rule, 2026-08-02: every time the loop is re-evaluated, redo this assessment before executing
it.** Not once, and not only when the tracker is being touched — *every* time.

Three axes, and the third is the one that gets skipped:

1. **Issue TYPES** — what kinds of work exist, and what each implies for merge class.
2. **STATES per type** — every state an item passes through, not just `open` and `closed`.
3. **WHICH ROLE acts at each transition — and what ARTIFACT records that it happened.**

The whole assessment collapses into one question, asked once per rule the change introduces:

> **What observable artifact says this rule was applied?** If the answer is *"someone reads the item
> and judges"*, the rule has no state. It will be applied inconsistently, and — worse — inconsistently
> *and silently*, because there is nothing to audit.

This rule was itself earned by a failure of exactly this shape ([ADR-0002](../../docs/adr/0002-roster-and-dev-loop.md)
amendment #8): an intake chain shipped with nothing in the tracker able to say whether a description
had been closed, one day after being written. **Keep the remedy to one bit.** Do not add a state that
duplicates something already observable — an open PR already says "in progress." Prefer the smallest
label set that makes each rule's precondition **queryable**, and if a rule needs no new state, say so
explicitly rather than leaving the axis unexamined.

### When to reach for this discipline specifically

- **Standing up the loop** in a new repo, or picking the loop model — see `/devops`.
- **A gate feels like theater**, or a green does not sit right — audit whether it verifies what it
  claims (widen the assertion to the installed form; make "did the reviewer run?" a precondition,
  not a hope).
- **The human is asked too often**, or WIP is piling — the loop's *shape* needs tuning, not more
  discipline from the people in it.
- **Validating a loop/gate change** — ~~pair it with `tech-lead` (design-time, against the principles and the ADR library) and~~ `quality-assurance` (code-time, against the Definition of Done).
  **Struck 2026-08-26 (#329), and this bullet is where the retired paired default survived its own
  correction — in the universal preload, seventy-five lines above the row that says the opposite.**
  `tech-lead` acts at **no** `loop` transition: read the `filed → **description closed**` rows in the
  states table below, which are canonical — that lane closes through `agents-lead` **alone**, with no
  exception (owner ruling 2026-08-25, one word: *"nunca"*). *Design-time validation of a loop change*
  and *`loop` intake* are the same act — the 2026-08-13 correction that established the rule was made
  on exactly such a dispatch — so this bullet was the judgement-call escape hatch ADR-0002's
  nineteenth amendment rejected by name: **a rule with a judgement-call escape hatch is the escape
  hatch**, and almost every machinery change can be described as having an architecture edge.
  **What survives untouched:** `quality-assurance` at code-time, which is the `in progress →
  **reviewed**` row — and on the `loop` lane it answers for **more** there rather than less: the same
  two-lens DoD every other lane gets, **plus** an `agents-lead` verdict marker that must be present on
  the PR before it may classify the diff safe or merge it (ADR-0002, record 0015's Corollary 2). **A
  reviewer that has to have been present, not a review that is skipped.** Struck rather than deleted
  because the pairing is what anyone reading this preload took away from it for thirteen days, and a
  rule that walked back in once walks back in again unless the door stays visible.
- **Proposing a change to the MACHINERY** — dispatch `agents-lead` before implementing it. Its
  standing question is [ADR-0004](../../docs/adr/0004-controls-and-enforcement.md)'s — *which
  layer can actually carry this control, and can that layer hold it?* Since
  [ADR-0002](../../docs/adr/0002-roster-and-dev-loop.md) it may also
  implement the harness changes it stress-tests (never merging, never gating an MR of its own — rule
  7b's catch-all and rule 5d's catch-all are unchanged by that ADR).

## Pick the loop model first

The loop has **two shapes**. They share every invariant below and differ only in how a change is
promoted. Full branching diagrams, per-environment topology, and the CI wiring live in `/devops`
(#227) — this is the pointer, not the depth.

| Model | Use when | Promotion |
|---|---|---|
| **`gitflow-multi-env`** | The repo deploys to **more than one environment** and carries an integration branch. | Two hops: PR → integration branch → staging, then a promotion PR → release branch → production behind manual approval. |
| **`trunk-single-env`** | The repo has **one long-lived branch (`main`) and one destination** — a single deployed environment, or a consumed artifact released deliberately. | One hop: PR → `main` → deploy/release. |

**How to tell**, in order of authority: the repo's `CLAUDE.md` states the model outright; otherwise
look for an integration branch (`develop`) on the remote and more than one environment in CI. **If
both signals are absent, it is `trunk-single-env`.**

## Intake — where work is born, and the chain it must walk

**Nothing is worked that is not recorded in the issue tracker.** No exceptions, no size threshold.

**What "closed" means for a description, generically, is `/definition-of-ready`'s subject, not
restated here.** This section is this loop's own **mechanism** for reaching that state — which two
personas close it, what label records the transition, what the state machine does once it is set — not
a second definition of what "ready" means as a concept. Read `/definition-of-ready` for the SDLC-generic
bar (the checklist shape, the flagship failure of scope fragmented across issues, the relationship to
estimation); read this section for how *this loop specifically* gets an Issue there.

**The chain below is the `product` lane.** All three lanes are in the states table's
`filed → **description closed**` rows, which are the canonical statement of who takes part on each —
`content` closes through `product-lead` alone, `loop` through `agents-lead` alone.

**The chain — see `agents/product-lead.md` and `agents/tech-lead.md` for the persona-level detail;
this is the canonical statement, and both briefs point here rather than restate it:**

> **The owner generates demand.** They are the only origin of work — see *Review does not open work*
> below.
>
> **The leads close the description among themselves.** `product-lead` and `tech-lead` collaborate:
> what it must deliver for the reader, what it must say to the market, what the system must carry.
> They disagree first and reconcile second; a disagreement they cannot settle goes **up** to the
> owner, never **down** as competing briefs.
>
> **Only then is the issue executable.** `developer` does not pick up an issue whose description is
> not closed.

**`agents-lead` is not a link in that chain, deliberately — and it closes the `loop` lane's description
alone.** The two are the same rule seen from either end: its object is the machinery this loop runs on,
not the product the loop builds, so it takes no part in closing a **story's** description and is the only
persona that closes a **`loop`** Issue's. It is dispatched on a **proposal about the loop itself**, before anything is
built, and per ADR-0002 that proposal now enters the tracker as a `loop`-typed Issue — filed by the
orchestrator on its naming (`agents-lead` itself remains denied `gh issue create`). `loop`-typed
`ready` is an **owner-only** label transition (ADR-0002, record 0015's Corollary 4), never applied by any
dispatch — see that record's section in full for the six corollaries (durable verdict marker, the
harness-diff criterion, the
proposal/build dispatch separation).

*Where the two chains meet.* A change to *how work is decided* — this skill, the states table, an
ADR that governs the loop — is still a **boundary** decision for the owner. `agents-lead` is who the
owner works that decision out with; it does not make it.

## The states

| transition | type | who acts | artifact that records it |
|---|---|---|---|
| → **filed** | all | the owner, alone | the Issue exists |
| filed → **description closed** | `product` | `product-lead` **and** `tech-lead`, dispatched in parallel and reconciling between themselves | the closed description in the Issue body, plus the intake stamp |
| filed → **description closed** | `content` | `product-lead`, **alone** — intake only, after the owner interview | the closed description in the Issue body, plus the intake stamp |
| filed → **description closed** | `loop` | `agents-lead`, **alone — `tech-lead` never co-signs this lane, with no exception** (owner ruling 2026-08-25, #329: *"nunca"*) | the closed description in the Issue body, plus the intake stamp |
| filed → **ready** | `product` | both leads, closing the description together | **`ready` label** |
| filed → **ready** | `content` | `product-lead`, alone — **intake only**; it takes no part in the drafting rounds (ADR-0002, seventeenth amendment) | **`ready` label** |
| filed → **ready** | `loop` | the owner, alone — not the leads (ADR-0002, record 0015's Corollary 4) | **`ready` label** |
| ready → **in progress** | `product` | `developer` | an open PR |
| ready → **in progress** | `content` | `content-writer` — **not `developer`**, which has never been dispatched at a draft (ADR-0002, thirteenth amendment; this row said `developer` until #317 and was wrong for nine days) | an open PR |
| ready → **in progress** | `loop` | `agents-lead` (ADR-0002, record 0015's Corollary 1) | an open PR |
| in progress → **drafted** | `content` only | `content-reviewer`, at most **two** rounds against `published-voice` (ADR-0002, seventeenth amendment) | **`docs/content-review/<slug>.md` on the branch** — one `## Round` section per round, each closed with `CONTENT-REVIEW-FINDINGS` or `CONTENT-REVIEW-CLEAR`; terminal on the first `CLEAR` or the second section, whichever comes first |
| in progress → **reviewed** | `product` · `content` | `quality-assurance`, against the full two-lens DoD | **a `<!-- gatekeeper-verdict: … -->` comment on the PR, carrying the head SHA it read** |
| in progress → **reviewed** | `loop` | `quality-assurance`, against the full two-lens DoD **exactly as on any other lane**, **plus** an `agents-lead` verdict marker that must be on the PR before it may classify the diff safe or merge it (ADR-0002, record 0015's Corollary 2). The marker is an **added** control, never a substitute for the DoD | **a `<!-- gatekeeper-verdict: … -->` comment on the PR, carrying the head SHA it read** |
| reviewed → **closed** | all | `quality-assurance` — safe **and** boundary since 2026-08-23 (ADR-0002 amendment #16) · the owner only on the four surviving holds | the merge, plus the verdict literal that authorised it (`APPROVE-AND-MERGE` or `APPROVE-AND-MERGE-BOUNDARY`); on a hold, the owner's ratifying comment |
| **any → blocked → back** | all | anyone, on discovering it waits on the owner or on something outside the loop | **`blocked` label** |

**`blocked` is orthogonal, not a sixth step.** It can attach at any point and returns the item to
wherever it was.

### The `filed → description closed` rows are the CANONICAL wording of the lane relation (#329)

**This table is where *who takes part at intake* is stated, and every other surface points here.** Owner
ruling, 2026-08-25: `README.md` keeps the narrative and points; `commands/new-issue.md` branches by type
and **defers** to these rows for who; the ADR-0002 amendment records *where the wording lives and why*,
not the wording. The reason is mechanical rather than editorial — **the README is prose no agent carries,
and this skill is the universal preload every persona reads at the moment it acts.** A rule exists to be
obeyed by whoever dispatches, and whoever dispatches reads the skill. **Putting the operative wording
where nobody looks is how #329 happened.**

**The three rows were ADDED, not edited.** The `filed → **ready**` rows below them were already right and
are untouched — they record *who applies the label*, which is a different question from *who closes the
description*, and conflating the two is why nothing in this file could answer the lane question before.
On `loop` the two answers differ on purpose: `agents-lead` closes the description, **the owner alone
applies `ready`** (ADR-0002, record 0015's Corollary 4).

**Why the `loop` row carries no exception clause, and must not grow one.** The owner's ruling was one
word — *"nunca"*. His argument, which is the load-bearing part: almost every machinery change can be
described as having an architecture edge, so **a loose exception does not stay loose — it becomes the
default case**, because the reading that admits it is always available. That is not hypothetical; it is
how the retired pairing walked back in on 2026-08-13. **A rule with a judgement-call escape hatch is the
escape hatch.**

**What this does NOT enforce, said plainly so the rows are not read as a mechanism.** Nothing observes a
dispatch. A `loop` Issue whose intake was run by both personas is indistinguishable, from the tracker and
from the diff, from one run correctly — the artifact column names the closed description, and a
description says nothing about who was asked. `hooks/scripts/inventory-counts.test.sh` asserts that these
rows and the `new-issue.md` branch **exist and say this**; it cannot assert that anyone obeyed them.

**`drafted` adds NO label, and that is why it is allowed to exist (#317).** It is a `content`-only
sub-state between *in progress* and *reviewed*, and the only thing that records it is a file already in
the branch's diff — so the *"what observable artifact says this rule was applied"* test is satisfied
without the tracker learning a sixth word. **The restraint stated below about `ready` being the only
state added is about the LABEL VOCABULARY and is unchanged**: nothing here is queryable with
`gh issue list --label`, deliberately, because nothing outside the PR needs to query it. Its cost is the
opposite of `ready`'s: the round is visible only to someone reading the diff, so a `content` PR that
skipped the pair looks exactly like one whose rounds were clear until you open the file list.

**`product-lead` keeps `content` intake and loses `content` craft — and the split holds because the two
acts have different OBJECTS.** **Intake judges the ISSUE** (worth doing, against what else, bounded how);
**a drafting round judges the PROSE**. The owner's decision — quoted verbatim in ADR-0002's seventeenth
amendment, not restated here — removed this persona from the flow that produces prose, and the act that
decides whether the Issue should exist never enters that flow. ~~The split is a call, not a reading.~~
**Struck at #317: the copy lens supplied that reason on review, so this no longer rests on a judgement
flagged as unsupported.** Reinforcing it: nobody else in the roster orders a `content` queue or judges
what it is worth to the reader.

**Its BLOCKING truth veto on published claims survives untouched** — it fires at the merge gate, relayed
by `quality-assurance` under criterion 10, rather than inside a round. **Only the craft opinion left, and
what that costs is WHEN those checks land, not WHETHER they run:** they arrive on a finished draft
instead of inside a round where acting on them costs a paragraph. If the reading is still wrong, the row
above is where to correct it.

**Since [ADR-0006](../../docs/adr/0006-verification-and-its-artifacts.md)** the
`reviewed` row's artifact is real — the gatekeeper posts a marker comment carrying the head SHA it
read, so a verdict on a moved head fails loudly instead of reading as approval. Until 2026-08-04 that
verdict was checked by a second gatekeeper (`security`) before merge; `security` was absorbed into
`quality-assurance` ([ADR-0002](../../docs/adr/0002-roster-and-dev-loop.md) amendment
#10 — the rationale for that merge lives there, not here), so the posting rule is now
**self-enforced**: nothing verifies it but the persona itself.

**`ready` is the only state added, and the restraint is the point.** An issue with no `ready` label
is not executable — a mechanism, not something a persona must remember. *What it does not buy:*
nothing verifies the leads actually closed the description rather than one nodding it through. The
label is auditable and attributable, not proven.

## One vocabulary across every repo

| label | means | set by | queried by |
|---|---|---|---|
| `product` | the repo's own deliverable | the owner, at filing | `/autonomy-on`'s queue · merge class **safe** |
| `content` | published in the owner's voice | the owner, at filing | merge class **boundary** |
| `ready` | the description is closed on that lane, per the `filed → **description closed**` rows above | the leads (`product`) · `product-lead` (`content`) · **the owner** (`loop`) | `/autonomy-on` · `developer` refuses an Issue without it |
| `blocked` | waiting on the owner, or on something outside the loop | anyone | the "what needs the owner" report |
| `reader-facing` | the diff will change words or images a reader sees | the owner or the leads | which lens the gate dispatches — **a signal, never a gate** |
| `sp:N` | the item's estimated weight, one Fibonacci value from a closed set (#326) | the estimating personas for that type, median of an isolated dispatch each | `/autonomy-on`'s **preflight** (an item without one blocks entry) · the points-per-week aggregation |

`product` / `content` / `loop` are exclusive per
[ADR-0002](../../docs/adr/0002-roster-and-dev-loop.md), which is the
citation for *why* — routing, not a re-argument here. **The test a label has to pass: something must
QUERY it.** A label nobody reads is decoration that ages, which is why the retired vocabulary
(`type:*`, `phase:*`, `priority:*`, `semver:*`, `status:blocked`) stays retired — each failed that
test or was superseded by a row in the table above. ~~one of the five above~~ — **struck at #326**: the
table gained `sp:N` and a prose count beside a table is a second source of truth for one fact, which is
the arrangement this repository's own gate exists because it rots. The criterion is what selects the
members; the number is derived by reading them.

**`sp:N` is the first label admitted to this table since the vocabulary was cut**, and it was admitted on
the test rather than around it: two things query it, and — unlike every candidate rejected here — no
GitHub field carries the thing it records. That is the entry rule, and it is worth stating that a label
class can pass it, or the table reads as closed when it is only strict.

**Why the formalism is not ceremony.** `quality-assurance` consolidates that every requirement of the
Issue was met, and those requirements are the leads' output — so the ruler the gate applies is
**external to the gate**. A vague issue leaves the gate nothing to anchor on, so it falls back on
impression, which has no stopping rule. That objectivity is what the labels buy: they are how the
chain above becomes checkable instead of merely believed.

## The iteration is the unit of work

**The pool a drain works is an ITERATION, not the whole `ready` queue.** Owner decision, 2026-08-24
(#326). What the axis buys is stated narrowly on purpose: **a bounded pool and a reachable terminal
condition.** `/autonomy-on` scoped by `ready` alone is unbounded for exactly the reason #103 retired
*"drain until the queue is dry"* — the queue grows by working — and an iteration is the smallest thing
that fixes a pool's contents at a moment the owner is present.

**A points-per-*iteration* series is only a rate when the iterations are the same length**; a series over
variable buckets is a burndown drawn as a trend, which on a repository whose thesis is rigor is a false
claim with a chart attached. **The rate metric is therefore points per WEEK** — a constant denominator,
immune to how long an iteration ran, and readable mid-iteration rather than only at close.

~~The weight the rate needs is not built here; see *What is not built* below.~~ **Struck within the hour
it stood, and struck rather than deleted because it was published and someone may have read it.** It was
written under a premise handed to the build — *"iterations yes, estimation no"* — that the owner's own
ratified interview of 2026-08-24 contradicts in his words: ***"inteiro. estimar antes é positivo."*** He
confirmed on 2026-08-25 that the ratified design stands. **The weight IS built: see *Estimation* below.**

### Rule 1 — the active iteration is derived from the POOL, never from a date

**The active iteration is the oldest not-yet-closed iteration holding at least one eligible item.** Dates
are metadata; they do not select. The rule is imported with its evidence: the source project first
selected *"the iteration whose date range contains today"*, which picked an iteration with zero open
items while real work sat one iteration away, and **the loop reported nothing-to-do as though it were
done.**

**That defect is reachable on this repository's own data today**, which is why the rule is adopted rather
than admired. `tadeumendonca-skills` carries one milestone left over from the retired `phase:` taxonomy,
`v0.2.0 Phase 1`, milestone number 1, holding four issues that are **all closed**:

```
gh issue list --repo <owner>/<repo> --state all --limit 200 --json number,state,milestone \
  --jq '[.[]|select(.milestone!=null)|{number,state,m:.milestone.title}]'
```

A naive *"oldest"* rule selects it and drains nothing. The pool predicate skips it, because it selects
from the items rather than from the milestones:

```
gh issue list --repo <owner>/<repo> --state open --limit 200 --json number,labels,milestone \
  --jq '[.[]|select(.milestone!=null)
          |select((.labels|map(.name)|index("ready"))
                  and ((.labels|map(.name)|index("product")) or (.labels|map(.name)|index("loop"))))
          |.milestone.number]|min'
```

**`--limit` is part of the predicate, not tidiness** — the default page is 30, and a pool query that
silently truncates selects the wrong iteration and then reports a dry pool. Same failure class as the
one above, one layer down.

**Never type a milestone name into a query — enumerate, then select from what came back.** Measured:

```
gh issue list --repo <owner>/<repo> --milestone "nonexistent-probe" --limit 1
→ (no output, exit 0)
```

**No error. An empty result is indistinguishable from a drained iteration.** Rule 1 protects against
selecting the *wrong* iteration and does nothing about naming one that does not exist — and since
exhaustion is no longer terminal (below), a typo does not stop the loop, it runs the closing ceremonies
over an iteration that never held anything. **If a milestone name is ever typed into a query, that is
the defect.**

### Rule 2 — the tracker object is a MILESTONE, and this section is it being written down

Both rules are imported as not-optional. Rule 2 is *"choose the object deliberately and write it down"*;
what follows discharges it.

**Milestones, and the choice is closer to a measurement than to a preference.** A GitHub Projects v2
iteration field cannot be driven from inside this harness at all: `gh project field-create --data-type`
accepts `{TEXT|SINGLE_SELECT|DATE|NUMBER}` and `ITERATION` is not in the set, `gh project list` fails on
a missing `read:project` token scope, and the GraphQL escape hatch is denied by the global permission
floor (`Bash(gh api:*)`). A milestone needs none of that: `gh issue edit --milestone`,
`gh issue list --milestone` and `gh issue list --json milestone` are all allowlisted already.

| requirement (#326) | milestone |
|---|---|
| one iteration per item | **yes**, and GitHub enforces it — an Issue has at most one milestone |
| mark an iteration closed | **not readable from here** — see the degradation below |
| aggregate a numeric weight per iteration | **no native field**; see *What is not built* |

**The degradation, measured rather than inferred, and it is the one thing to know before trusting this
object.** The `milestone` sub-object returned by `gh issue list --json milestone` carries **four keys and
no `state`**:

```
gh issue list --repo <owner>/<repo> --state all --limit 200 --json number,milestone \
  --jq '[.[]|select(.milestone!=null)]|.[0].milestone'
→ {"description":"…","dueOn":null,"number":1,"title":"…"}
```

There is no `gh milestone` subcommand, and `state` is not among `gh issue list --json`'s available
fields, so **no command available to this loop can read whether a milestone is open or closed.**
Creating one and closing one are both owner acts in the browser.

**Why that does not send the object back to the table, which is the honest form of this answer:** rule 1
never reads `state`. The predicate above derives the active iteration from *items*, so the one attribute
milestones cannot expose is the one attribute the design does not consult. What it does cost is the
source document's *"the iteration closes automatically"* clause, which is therefore **not adopted** —
closing is a click. The alternative is unlisting `Bash(gh api:*)` from the global floor, which is the
line standing between every persona and the raw write API; one click per iteration is cheaper than
reopening that door.

### `loop`-typed items ARE iteration-assignable

**Decided in this slice, not inherited — the source document explicitly refuses to answer it.** There,
loop-typed items carry no iteration and sit outside the drained pool, so the question is only about where
a retrospective's output lands. **Here the premise does not hold**: `/autonomy-on`'s queue is
`(product OR loop) AND ready`, so an iteration-scoped pool with loop items unassignable does not orphan a
ceremony's output — **it takes half the queue dark**. One list, one axis, one predicate.

Cost, carried knowingly: planning must slot loop items, and `loop`-typed `ready` is the owner's
transition alone — so he is already the critical path for exactly these items, and this adds one
milestone assignment to a transition he already performs. It adds no new gate and no new actor.

### The state-model pass — the AXIS adds no label and no state, and ESTIMATION adds exactly one class

~~### The state-model pass — the axis adds NO label and NO state~~ — **the heading was struck within the
hour it stood.** It was written under the premise that estimation was out, and it was true of the axis
and false of the slice. **Corrected rather than deleted**, because a reader who took "no new vocabulary"
from it would look for `sp:N` in the wrong place.

Per the standing rule, both were walked against issue types × states × role-per-transition rather than
bolted on:

- **`ready → in progress`, all three types** — unchanged in who acts and what records it, with **two**
  added preconditions: the item is in the **active** iteration, and it carries an `sp:N`. The first is
  recorded by the **milestone assignment**, which GitHub already stores, already returns on the ordinary
  query, and already permits only one of. The second is recorded by **the label itself**.
- **Every other row is untouched.** Intake, the gate, the merge and `blocked` are indifferent to which
  iteration an item sits in and to what it weighs.
- **The AXIS adds no label**, and that restraint stands. The label vocabulary's own test is *something
  must query it*; a milestone is not a label and the pool predicate reads it directly. Adding
  `iteration:N` beside a field GitHub already enforces would duplicate an observable, which is the named
  anti-pattern.
- **ESTIMATION adds one class, `sp:N`, and it passes the same test rather than being exempted from it.**
  Two things query it — the preflight (*open, in the active iteration, no `sp:` label*) and the
  aggregation — and **no GitHub field carries a number**, so this duplicates nothing. It is the opposite
  case to `iteration:N`, and the vocabulary table below records it as a class rather than as six labels,
  because the six are one concept and a table listing them separately would be six rows nobody reads.

- **The loop-first COMPOSITION rule (below) adds neither**, and it was walked against the same three
  axes rather than assumed to be free. It changes no transition's actor and no transition's artifact —
  it constrains only the **order** in which already-eligible items are picked out of a pool that already
  exists. The state-model question *what observable artifact says this rule was applied?* has an honest
  and uncomfortable answer here: **the ordered body, and nothing else**, which is why that section
  states plainly that nothing gates it.

**Two transitions are genuinely new, and they are the ones with no artifact — so they get one.**
*An iteration was planned* and *an iteration closed* are both events a milestone's own flag cannot record
here (no readable `state`), and an event nothing records is applied inconsistently and silently.

> **The planning artifact is an ITERATION ISSUE** — one Issue per iteration, opened by the owner at
> planning, whose body is the **ordered** list of the items admitted. It records what was planned, in
> what order (milestones carry no ordering field either), and it is **closed with a criterion** like any
> other Issue, which is what records that the iteration closed.

That reuses a primitive the loop already has rather than inventing a state: it is queryable, attributable,
dated by GitHub, and it is the only place the owner's ordering can live at all.

### Loop before product — a planning-time COMPOSITION rule, and it is NOT a gate

**The owner's standing rule, 2026-08-28, in his words:**

> *«o pedido é que sempre todos itens de loop sejam atacados no inicio de sprints. lembre-se disso. faca
> enforcement se necessario.»*

**It is in force, so this section RECORDS a rule rather than proposing one** — and it dissolved a
circularity worth keeping, because the shape recurs. The rule that would order the iteration was itself
an item **inside** that iteration (this one, position 7 of 13). He answered directly instead of waiting
for the mechanism. **So this section is not a precondition for the iteration it sits in**, and a future
reader finding the rule already applied to the sprint that produced it is not looking at a defect.

**The rule.** At planning, the iteration's **ordered body** lists every eligible `loop` item before any
eligible `product` item. One ordering authority, discharged by an artifact that already exists, and the
drain keeps obeying `commands/autonomy-on.md`'s own *"Do not invent an order."*

**It orders only what is ELIGIBLE, and that clause is the deadlock escape rather than a softening.**
The rule ranks `(loop AND ready AND active-iteration)` ahead of
`(product AND ready AND active-iteration)`. An item **without `ready`**, or carrying **`blocked`**, is
not in the pool and therefore cannot stall it. State this explicitly or the first person to hit the
stall improvises an escape, and the standing rule is that the loop grinds work down rather than halting
on it.

**Why that clause is not theoretical — a live instance from this sprint, and it is the escape's real
shape rather than an invented one.** On 2026-08-28, position 6 (#341) needed the owner's go under the
gate's hold 1; WIP=1 held; position 7's build was finished and could not open its PR; **the drain
stopped until he answered.** Note what the eligibility clause does and does not buy there: #341 was
`ready` and *in progress*, so it was in the pool and the escape did **not** apply. **The eligibility
clause covers an item that never entered; it does not cover one that entered and then stalled** — for
that, the escape is the one `/autonomy-on` already names (*"When a slice hits an owner decision it did
not expect"*): write the question on the Issue, cut the slice to what can still finish, and move on.
**WIP=1 is what turns the second case into a full stop**, and that is a deliberate cost of WIP=1, not a
defect in this rule.

**`ready` on a `loop` item is the owner's transition alone** (record 0015's Corollary 4), so a `loop` item
awaiting `ready` is by construction awaiting him — which is exactly why the pool is scoped to `ready`
and not to `loop`-ness. Measured 2026-08-28: `-skills` carried two `loop` Issues with no `ready`
(#335, #336) while `-io` carried five `ready` `product` items and **zero** `loop` items of any kind. A
rule ranking `loop` rather than *eligible* `loop` would have stalled a whole repo behind two Issues only
he could release.

#### Where the order actually lives — and it is a weak home

**The order lives in the MILESTONE DESCRIPTION, in both repos** — carrying the ruling verbatim, the
numbered positions across both trees, and the open recommendations not yet ruled on. It was chosen for
lack of an alternative and it is stated as such rather than as a design:

- **Nothing reads it.** Measured 2026-08-28: no script under `hooks/scripts/` resolves a milestone at
  all (`grep -rn "milestone" hooks/scripts/*.sh` matches exactly one line, and that line is a **comment**
  in `closure-artifact-guard.sh`). The order is prose, read by a human, in a field no gate opens.
- **It is not versioned where this loop can see it.** A description edit produces no commit, no diff and
  no Issue-timeline event this harness can read — `gh api` is denied by the global permission floor, so
  the route that would expose the edit history is unavailable by construction.
- **It contradicts the paragraph directly above.** *"The planning artifact is an ITERATION ISSUE"* is
  what this skill specifies, and **there is no iteration Issue.** The specified object was not built;
  the milestone description is standing in for it. That gap is named here rather than papered over,
  because it is the same defect class #337 exists for — a rule shipped without the object it operates
  on — and the surface most likely to be read as if the object exists is this one.

**Building the iteration Issue is what would fix the home**, and it is not this slice. Until then, read
the milestone description as the order of record and treat its weakness as known.

#### Nothing gates this, and the layer analysis is why

**Ordering is not a property of a tree and not a property of a command string.** Measured against every
layer this harness has:

| layer | can it hold *loop first*? |
|---|---|
| `permission-guard.sh` (`PreToolUse`/`Bash`) | **no** — it reads a command string. `gh pr create` on a product slice is character-identical whether a loop item is outstanding or not. |
| `wip-guard.sh` | **no** — same matcher, keyed on file overlap. |
| `session-wip.sh` (`SessionStart`) | **no** — it can *report* outstanding loop items, but it fires before any pick and cannot observe the pick that follows. |
| a `Stop` hook | **detection only, one turn late** — and see the measurement below for why one is not built here. |
| `inventory-counts.test.sh` | **presence only** — it can assert this rule is WRITTEN, which is what the arm added with this section does, and all it does. |

**The only artifact that could record *"this was picked next"* is a PR's creation timestamp against the
queue state at that moment, and nothing captures the queue state at that moment.**

**A `Stop`-hook detector was designed and NOT built, on a measurement rather than on cost.** The
obvious form — *"a product PR is open while `loop` items remain in the active iteration"* — was measured
against this sprint's actual composition on 2026-08-28:

```
gh issue list --repo <owner>/<skills> --state open --limit 200 --json number,labels,milestone \
  --jq '[.[]|select(.milestone!=null)|{n:.number,m:.milestone.number,l:(.labels|map(.name))}]'
gh issue list --repo <owner>/<product> --state open --limit 200 --json number,labels,milestone \
  --jq '[.[]|select(.milestone!=null)|{n:.number,m:.milestone.number,l:(.labels|map(.name))}]'
```

**Every `loop` item is in one repo and every `product` item is in the other, and the two halves of the
iteration are two milestones carrying different numbers (2 and 1) paired only by title.** A `Stop` hook
receives one `cwd` and therefore sees one repo, so the same-repo form has **zero true positives against
this iteration's composition, by construction** — in `-skills` there is no `product` item it could fire
on, and in `-io` there is no `loop` item that could make it fire. The cross-repo form is buildable and
stacks three heuristics for one advisory notice: sibling-tree discovery from a payload that carries only
`cwd` (ADR-0004 calls that candidate set *"a heuristic and the weakest part"*), milestone pairing by
**title** (convention — the milestone description says so in its own words), and PR → Issue resolution
(measured over the twelve most recent PRs: the closing-keyword route resolves **9 of 12**, adding a
branch-name-suffix heuristic reaches **11 of 12**, and #330 resolves under neither).

**What would change the answer, stated so the next person does not re-walk this.** A **declared,
machine-readable order carrier** — the iteration Issue above, with the order as a parsed field rather
than prose — turns the check declarative: read the declared sequence, look up each number's labels,
assert every `loop` number precedes every `product` number. No PR classification, no tree discovery, no
prose. That is one object away, and it is the same object the *weak home* section is already asking for.

**So: the rule holds because deviation becomes visible and awkward, not because anything stops it. It is
an instruction, and by this loop's own test — *would something stop me, or only my memory?* — it is not
engineered.** Read the gate arm as asserting the rule is written down, never that a session obeyed it.

### Estimation — the weight is an `sp:N` label, and the estimators are the personas that work the type

**Owner decision, ratified in interview 2026-08-24 and reconfirmed 2026-08-25**, in his words:

> *"inteiro. estimar antes é positivo."*
> *"todos agentes que trabalham no tipo de issue estimam"*

**The carrier is a label, because a milestone has no numeric field of any kind** — title, description, due
date, state, and nothing else. One label per Fibonacci value, closed set:

```
sp:1  sp:2  sp:3  sp:5  sp:8  sp:13
```

`gh label` and `gh issue edit` are both already allowlisted and `gh issue list --json labels` reads them
back, so this needs **no permission change and no token scope** — the same test that chose the milestone
over a Projects v2 field. Aggregation is one `jq` expression over the query the pool predicate already
runs:

```
gh issue list --repo <owner>/<repo> --state all --limit 200 --json number,labels,milestone \
  --jq '[.[]|select(.milestone!=null)|.labels[].name|select(startswith("sp:"))|ltrimstr("sp:")|tonumber]|add'
```

**Who estimates — the personas that work that type, each dispatched in ISOLATION, median recorded, no
revote:**

| type | estimators |
|---|---|
| `product` | `product-lead` · `tech-lead` · `developer` · `quality-assurance` |
| `content` | `product-lead` · `content-writer` · `content-reviewer` · `quality-assurance` |
| `loop` | `agents-lead` · `quality-assurance` |

**Isolation costs nothing extra here and is not a new ceremony** — a subagent cannot see another's
output, so independence is a property of dispatch rather than a discipline anyone must keep. It is the
same property the two leads' parallel intake already relies on.

**The author-estimates-his-own-work conflict is resolved without an exception, and that is why the `loop`
row has two names rather than one.** `agents-lead` authors `loop` items *and* estimates them — but never
alone: `quality-assurance` is the second voice, and it is the only persona in the roster whose whole
discipline is a fresh context. **That does not remove the bias; it exposes it in a median of two**, which
is the honest claim rather than the comfortable one.

**Where the estimate is required.** An item with no `sp:N` is **outstanding HITL work**, and outstanding
HITL work blocks the drain from entering — the owner's rule, *"todas pendencias HITL devem ser zeradas no
momento da invocacao do comando"*. It is a **preflight**, not a mid-drain check: see `/autonomy-on`'s
*Preflight* for the operative wording and the one-at-a-time surfacing rule, stated once, there.

**What nothing enforces, said plainly.** Nothing constrains an item to exactly one `sp:` label, and
nothing constrains the value to the six above — a single-select field would give both for free and is
unreachable here. A gate can assert the **vocabulary is written down**; it cannot assert an item carries
one and only one. Read a sum as a sum of what was applied, never as a sum of what was estimated.

**The first pass is NOT this slice, and the figure is his rather than a re-derivation.** The whole backlog
is estimated before the first iteration — **11 `product` + 20 `content` + 2 `loop` at head → 128
dispatches**, once, accepted knowingly. That is its own slice and **the owner triggers it**: it is a
bootstrap cost, not the steady state, and once an iteration exists the pendency set is bounded by that
iteration's contents rather than by the backlog. Until it runs, every points-based series is empty — not
wrong, empty, and a chart drawn over it would be inventing its own subject.

### What exhaustion means now

**Exhausting the active iteration's pool is an internal transition, not the end of the session** — the
closing ceremonies run, and the stop moves to the planning handoff, which is the owner's. See
`/autonomy-on`'s *Stop when* for the operative wording and for how this settles against #103's judgment
condition; it is stated once, there, rather than twice.

### What this does NOT bound, said plainly

**The iteration bounds the pool being drained. It does not bound the backlog, and it does not bound the
NEXT iteration.** Findings from a slice land as Issues on the next iteration by design, and nothing stops
that one growing without limit — the unboundedness is *moved*, not removed. **That is the intended
shape rather than a leak:** #103's argument was never that a backlog must be small, it was that a *pool*
whose contents grow while it drains has no terminal state. Planning is HITL and the owner composes, so
the growth is bounded by a human deciding, which is the only place this loop has ever bounded anything
that is a matter of worth rather than of arithmetic.

**The residual, named because nothing catches it:** nothing bounds how many items the owner admits to one
iteration, so an over-filled iteration reproduces the old unbounded drain inside one milestone. There is
no mechanism for this and none is proposed — the signal is the metric (cycle time, and the count of items
carried over), not a gate.

### What is not built in this slice

- ~~**The numeric weight.** … **Not built here**, and until it is, every points-based metric starts at
  zero.~~ **STRUCK within the hour it stood.** #326's third tracker requirement was never void, and the
  weight is **built** — see *Estimation* above for the `sp:N` vocabulary, the estimator sets and the
  preflight. What is genuinely not in this slice is **the first pass**, 128 dispatches over the existing
  backlog, which is the owner's to trigger. Until it runs the points series is **empty rather than
  wrong**, and that distinction is the whole reason this bullet is corrected rather than left standing.
- **The ceremonies.** REVIEW cannot run unattended in this harness — no MCP server is reachable from a
  dispatched subagent, there is no non-production environment to sweep, and resumable state has no
  durable home since #245. RETROSPECTIVE and PLANNING are dispatch-and-interview shapes, not mechanisms
  in this file.
- **Anything that observes an iteration.** No hook reads the queue: every `gh issue` call in
  `hooks/scripts/` is a write path. This section is a rule the loop follows, and a gate asserts only that
  the rule is **written**, never that a session obeyed it.

## Opening a session — decisions before work

**Collect the pending owner decisions across the whole queue and ask them as a batch, before choosing
what to build.** One question at a time, in one sitting. Asking a decision when a slice hits it
produces one stall per slice; asking them up front produces one conversation and unblocks everything
at once.

Then **`product-lead` states the order**, and the session works it:

> Starting a slice that is **not** the top of the stated order requires `product-lead` to have
> returned a new order, or the session records that the order is unchanged.

**A session with no pending decisions says so.** A step that silently did nothing must not read like
a step that ran.

**Each decision lands as an artifact on the issue it unblocks (#85)** — a comment, not only
conversation — so the ratification survives the session that made it and a later reader can find why a
slice went the way it did without reconstructing the chat.

## What gets worked next — discovered vs requested

**Work you discover only preempts work the owner asked for when it BLOCKS it.** File everything,
always — evidence in hand is worth recording whether or not it is worked. The test:

> Does the requested work ship **wrong**, or **not at all**, without this?

Yes → it goes first, stated as a blocking relationship. No → it queues like everything else and
`product-lead` orders it. Discovered work is cheap to justify (found in context, usually safe class,
merges without the owner); requested work needs decisions, sometimes the owner's own words. Left
unchecked, the autonomy gradient sorts the queue by what can flow without a human, which is exactly
backwards from what a backlog is for.

## What "delivered" means

**A slice DELIVERED when a reader can do, see or read something different.** Everything else is
**hygiene** — comments, dead code, a test mechanism, a process rule, a README. Hygiene is not lesser
work and it is not delivery: it is the cost of being able to deliver again.

**Report product slices against hygiene slices, every session.** A session with zero product slices
is a finding, not a status. **Hygiene is picked up when it BLOCKS a product slice, or in one
deliberate bounded batch** — not opportunistically, and not because it is what flows most easily
without a human.

## Closing an issue is a step, with a criterion

**The loop must be able to REMOVE work, or it has no terminal state.** Close an issue when any of
these holds, and state which one in the closing comment:

- **Superseded** — a later decision answered it. Say what superseded it.
- **Implemented elsewhere** — the mechanism exists now, under another slice's name. Point at it.
- **Its premise no longer holds** — the condition that produced it is gone.
- **The cost of tracking exceeds the cost of rediscovering it** — real, small, cheaper to find again
  than to carry. Say so plainly rather than pretending it was fixed.

**A closing comment that states no criterion is not a close, it is a deletion.** This is the owner's
act, like opening one — the permission floor leaves closing open everywhere, deliberately: opening
work commits the owner's future attention, closing it releases attention already committed. But
**propose the batch and the criteria**; do not close silently.

### An Issue that promises an invocable artifact declares it, and does not close while it is missing

**A closing keyword is not evidence.** `Closes #NNN` fires on merge and knows nothing about whether
the thing the Issue promised exists. Measured (#337): **three Issues closed with their operable half
unbuilt** — #313 shipped `docs/blueprint-registry.md` and closed with `/blueprint` non-existent, twice;
#326 shipped the iteration rules and created none of the objects they operate on; #431 shipped a
truth-fix against a ratified ask for a detector nobody built. Each was found because the owner asked.

**So the promise is written into the Issue body as a field, at column 0**, and the field name is a
parsing contract read literally by `hooks/scripts/closure-artifact-guard.sh`:

```
invocable: /blueprint                    a plugin identifier a reader can type
invocable: hooks/scripts/detector.sh     a repo-relative path
invocable: none                          this Issue promises nothing invocable
invocable-waived: /blueprint <reason>    the promise was narrowed, and here is why
```

**Who writes it: the lane's own intake, when it closes the description** — the same act, no new state
and no new label. `none` is a real answer and the common one; the field exists so that *promised* and
*promised nothing* stop looking alike.

**What it buys, and the two facts that bound it — both measured, neither assumed.** A manual
`gh issue close` on an Issue with an unmet declaration is **refused**. A close by closing keyword is
**executed by the forge on merge**, so nothing in this harness can refuse it — that case is *reported*
at the end of the turn instead, one turn late, exactly the class `zombie-loop-detect` is. And the
promise is **declared, never derived**: deriving it from prose was measured over twenty closed Issues
and produced eleven unresolved identifiers with **zero** true positives, which is a gate that reddens
on honest work until someone loosens it into nothing.

**The limit, stated wherever the rule is:** an Issue that declares nothing is invisible to the guard,
and nothing mechanical forces the declaration. **The scope is Issues promising an invocable artifact
and nothing wider** — a `content` Issue closes on a published article and a record Issue on a merged
record; neither is this rule's business, and both answer `invocable: none` if they are closed by hand
at all.

## Review does not open work

**Only the owner decides what enters the queue.** A REVIEW never files: an agent that turns its own
finding into an Issue has decided something should exist and is merely asking for agreement
afterwards. Findings are **named** — in a verdict, in the PR, to the human — and the owner decides
whether any of them becomes tracked work.

**Enforced by WHO is asking.** `permission-guard` rule 5c reads `agent_type`, which the harness
stamps and the model cannot forge; every subagent except `developer` (rule 5d) is denied
`gh issue create` outright, and the main loop is asked. Reading, listing, commenting, labelling and
closing stay open everywhere.

**The one exception.** A story is broken into tasks, and `developer` executes them. **Opening scope**
is creating work nobody asked for; **decomposing** is dividing work the owner opened and the leads
ratified. `developer` may file a task, and the rule it must follow — *only under a story carrying
`ready`, referencing its parent, never extending the story* — lives in `agents/developer.md`, and
`quality-assurance` verifies it on the task's own MR.

**Why, measured rather than assumed.** In one session the queue grew by 19 issues net, with roughly
13 born inside a *review of something else*. Every finding became work nobody had decided to do. The
accepted cost: a finding in a verdict is ephemeral where an Issue is not — fewer things tracked, some
real findings lost, preferred to a queue that grows by working.

## The agent's state while a slice is blocked on someone else

**With no defined action for that interval, the default behaviour is to report status. Reporting
reads to the agent as delivery and to the owner as stopping.**

> **On dispatching work to a reviewer — or to any actor you do not control — name and BEGIN the next
> non-overlapping action before ending the turn.** If there is none, say so: *"waiting on X, nothing
> disjoint in the queue"* is honest status. Silence is not, because silence is indistinguishable from
> being stuck.

## Inner loop (per slice)

1. **Plan-first**, then implement. Ask only on architecture / contracts / irreversible calls; decide
   autonomously on in-pattern implementation.
2. **One thin vertical slice at a time**, end-to-end and reviewable. Keep it surgical; adjacent debt
   is **named, not refactored inline and not filed** — see *Review does not open work*.
   **WIP=1 — one worktree, one in-flight branch, one open PR at a time, full stop, until formally
   reversed** (owner correction, 2026-08-13; see *WIP=1* below for the struck predecessor rule and
   why). **Integrate `main` before requesting review** if `main` has moved.
3. **Develop locally**, against whatever backing services the repo actually has — see `/devops`.
4. **Validate locally**: run the repo's **functional regression** and self-verify the gates (lint,
   typecheck, coverage). Report with the real output, never a claim.
5. **Run `/code-review`** before opening the PR — the author's own completeness pass. *Namespaced
   deliberately:* a bare `/code-review` resolves to a different, external marketplace plugin this
   repo also installs.
6. **`quality-assurance` reviews every MR, holding TWO lenses in one pass** — delivery (*was every
   requirement of the Issue met?*) and production (*can this cause a problem in production?*). Both
   are labelled per finding. The gatekeeper posts its verdict to the PR before returning — a
   `<!-- gatekeeper-verdict: … -->` comment carrying the head SHA it read
   ([ADR-0006](../../docs/adr/0006-verification-and-its-artifacts.md)). A relay
   from the invoking context is a notification, never the authority.

### Always true

- **Pipelines are independent per repo** (never cross-trigger). Infrastructure changes are
  **pipeline-only**: a reviewed plan on the PR, apply on merge.
- **Merge with a real merge commit, never squash** — each thin slice's conventional commits are the
  changelog and the slice-by-slice trail.
- **The regression suite must functionally cover 100% of implemented features.** Which suites that
  means is per repo — E2E always; an API suite only where an API exists.
- **Something irreversible always asks.** The models differ on *which* act is the point of no return,
  never on whether one exists.

## The merge is the go/no-go — who decides which class

**"The merge is the go/no-go" does NOT mean "the merge always asks a human."** What the merge asks
for is a **judgement**, and who supplies it depends on the class:

- **Safe class** — docs, dependency bumps, tests, in-pattern implementation of an already-approved
  spec. **`quality-assurance` merges it**, once both of its lenses are green.
- **Boundary class** — infrastructure and anything threatening continuity, a change to the loop's own
  rules, publishing in the owner's voice. ~~**The gate never merges these.** It approves pending the
  human and hands the go/no-go up.~~ **Struck 2026-08-23** ([ADR-0002](../../docs/adr/0002-roster-and-dev-loop.md)
  amendment #16, the owner's decision): **the gate merges these too**, under its own verdict literal
  `APPROVE-AND-MERGE-BOUNDARY`, and **the owner reviews live, after deploy**. The argument is the loop
  model itself — under `trunk-single-env` there is no preview to hold for, so holding the merge produced
  no staging copy to inspect, only a queue. **Under `gitflow-multi-env` this reasoning does not
  transfer** and this skill does not extend it there: a repo with an integration branch *does* have a
  place to hold a change and look at it, which is the whole premise the retirement rests on.

**Four holds survive, and none of them survives on the preview argument** — read them as separate rules
that happen to have lived inside "boundary class" until it stopped being a hold, not as the retired
clause under another name. On any of these the gate returns `APPROVE-PENDING-HUMAN` and does not merge:

1. **An expansion of the gate's own authority** — a diff widening which class it may merge, removing a
   boundary trigger, or otherwise loosening its own mandate. Unconditional, whatever the diff looks like;
   see [ADR-0011](../../docs/adr/0011-skills-and-preload.md) for the record of this clause drifting out
   of `agents/quality-assurance.md` and back in, which is why it is restated in two places on purpose.
2. **A harness diff carrying no `agents-lead` verdict marker ON THE PR** ([ADR-0002](../../docs/adr/0002-roster-and-dev-loop.md),
   record 0015's Corollary 2). It is a *missing reviewer*, not a class. **The surface is part of the
   hold, not context** (#336, owner's ruling): the marker literal is a PR-only string, and a comment on
   the Issue — where `agents-lead`'s **intake** stress test lands, deliberately without the marker
   envelope — satisfies nothing here. Until 2026-08-28 the producing brief said the opposite about the
   case it called common, and a gate with two places to look and no rule saying which fails
   unattributably in either direction.
3. **Anything in `iac/`** — the merge applies, a destroyed resource is not recovered by a revert, and
   there *is* a preview here: the plan posted on the PR.
4. **An explicit lens `ESCALATE`**, or a `BLOCKING` truth finding from `product-lead` — a lens has one
   path to the owner and this is it.

*Significance beats in-pattern:* when the class is unclear, it is boundary — which now means the gate
merges it under the boundary literal rather than holding it, so **when what is unclear is whether one of
the four holds applies, the conservative reading is that it does.**

**What the safe/boundary split still decides, since a distinction that changes nothing should be retired
rather than kept:** which of the four holds can apply (every one is a boundary trigger), which verdict
literal is posted — so the merge record itself says whether anything shipped without a pre-publication
check — and what the verdict must state. What it no longer decides, outside the four holds, is **who
merges**.

This framing above is the corrected one — an earlier prose restatement of it, in the retired
`dev-loop` skill this file replaces, said the opposite (*"auto-merging to `main` is never in-pattern
here"*) and went stale against
[ADR-0004](../../docs/adr/0004-controls-and-enforcement.md)'s classified-autonomy decision
without anyone noticing until the two disagreed in front of an agent (#62). That incident, and the
decision-currency lesson it carries, is recorded as ADR-0004's 2026-08-13 amendment rather than
re-told here — this section states only the current, corrected rule.

**Failure path:** revert the offending merge and let the revert deploy/re-release — a forward fix
with a new slice, not a long-lived hotfix branch.

## What the human does (the residual)

Everything mechanical is the agent's job: plan, slice, build, validate locally, make the gates green,
report evidence. The human is left only the residual — approving (or redirecting)
architectural/contract decisions and giving the **go/no-go on the irreversible act**. Designing the
loop so that residual stays small is the whole point.

---

## The judgment — eleven principles, two tiers

This is the section that folds in what was `/engineering-philosophy`: the lens every agent applies
while doing the above, not a separate concern from it. Read it as defaults plus the explicit triggers
to deviate, not as rigid rules.

### The spine: agent-led verification, human-residual

Everything below serves the same purpose stated above: the gates are objective and mechanical so an
agent can *prove* "done" itself, and the human's attention is reserved for what can't be reliably
automated. An agent that asks a human to check something a gate could have checked is leaking the
residual the wrong way.

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

**3. Thin vertical slices, bounded by overlap AND by WIP=1.** Each increment crosses the layers and
delivers reviewable value. **WIP=1 — see below.** Serial focus beats half-finished breadth.

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

### WIP=1 — the struck exception, and why

Principle #3 above used to read, and this project's own struck-not-deleted convention keeps the old
text visible rather than erasing it:

~~**A slice may start while another is open only if they touch no file in common**; if they overlap,
finish the first to its Definition of Done. Serial focus beats half-finished breadth — but serialising
*disjoint* work buys nothing and stalls the queue, which is why the bound is overlap and not a
count.~~

**Struck 2026-08-13 (owner correction).** This session tested the disjoint-files exception directly —
two disjoint-file issues were built in separate `git worktree` checkouts at the same time — and the
owner corrected it on sight: *"nao temos intencionalidade de trabalhar assim por enquanto"* ("we have
no intention of working that way for now"). The written rule and current intent disagreed, and intent
wins.

**State plainly, in its place: one worktree, one in-flight branch, one open PR at a time — full stop,
until this is formally reversed.** The worktree mechanism itself — a separate checkout sharing the
same repo's history, removed after merge — is **not** struck; it remains the correct isolation tool
for a single build. Only the license to run two of them at once is struck. A future session may
reverse this by the same route: an explicit owner decision, recorded the same way.

**Named residual: the policy above and the mechanism disagree.** `hooks/scripts/wip-guard.sh` still
denies a second PR only on file **overlap**, not on a raw count — the mechanism
[ADR-0002](../../docs/adr/0002-roster-and-dev-loop.md)'s twelfth amendment (2026-08-13)
describes, unchanged by this correction. So today the hook permits a second, disjoint PR that this
written policy now forbids. Follow the written policy regardless of what the hook allows; closing the
gap is a `wip-guard.sh` change, not a docs one, and is not this skill's job to make.

### Using this section

When an agent works in a consuming repo, these eleven principles are the lens for every choice: plan
first, ask on the boundaries, slice thin, keep the floor green, and verify your own work before
handing the residual to a human. The deep-dive component skills tell you *how* to build each piece;
this tells you *how to decide* while you do. Today that means three reference skills — `/backend`,
`/frontend` and `/cloud-infrastructure`. ~~Today that means the per-service families under
`skills/backend/*`, `skills/frontend/*` and `skills/infrastructure/*`; per
[ADR-0011](../../docs/adr/0011-skills-and-preload.md)'s 2026-08-13
amendment these are consolidating into single reference skills … **not yet built as of this writing**,
so read the family directories as they stand until that consolidation lands.~~ **Struck: it is built.**
#229/#230/#231 consolidated 21, 19 and 15 files into one skill each, and #286 removed the family
directories the struck sentence told a reader to go and read. Every skill is `skills/<name>/SKILL.md`.

See also: `/quality-gates` (the Definition of Done, the gate tables per loop model, and — since #257
folded the former standalone `coverage` skill in — the concrete gate definitions for both stacks),
`/devops` (the permission zones and guard hook, branching, per-environment topology, OIDC, the deploy
workflows, TFC state), `/playwright` (E2E). Repos with an API layer add its contract/API suite — see
`/postman`.
