---
description: Assemble everything that could enter the next iteration — the eligible open work plus the proposals the closing rites produced — have it ranked by a context that did not run the session, and present it to the owner ONE item at a time so he composes the iteration himself. Use when an iteration is about to open, or when the drain hands off at its terminal condition. It assembles and ranks; it never places.
purpose: give iteration composition an object, so the pool the owner rules on is assembled and ranked by a fresh context rather than remembered by the session that produced it, and so the retrospective's proposals reach a moment where they can be ruled on at all
argument-hint: "<iteration> (the title of the iteration being composed)"
---

Run the planning rite for the iteration named by `$ARGUMENTS`.

**This rite is the consumer the closing rites never had.** `commands/sprint-retrospective.md` produces
per-persona proposal files whose stated consumer is *"a proposal the owner rules on at planning"*, and
`/agents-configuration` states in its own words that **"PLANNING is genuinely unbuilt and no claim is
made about it."** This is that object.

## What this is, and the one thing it is not

**It ASSEMBLES and RANKS. It does not PLACE.** Placement — an item acquiring a milestone — is the
owner's act (#365), held by `permission-guard.sh` rule 10, whose prompt reaches him and nobody else.
Nothing in this rite may set a milestone without his answer to that prompt, and nothing in it decides
what the iteration contains.

**The failure it closes, measured here rather than imported.** On 2026-09-01 five `ready` `loop` items
sat with no milestone and nothing presenting them; the loop-first composition rule (#339) depended on
the owner remembering it; and the `sprint-01` retrospective's seven proposal files had no consumer at
all. None of those is a missing decision — the decision is his and stays his. What was missing is the
thing that puts the decision in front of him, item by item, with the pool already assembled.

**It is executed in the ORCHESTRATOR's context, and that is a requirement rather than a convenience.**
Rule 10 (`--milestone`) and rule 11 (`scripts/milestone-create.sh`) both **deny a subagent and ask the
orchestrator**, because a dispatched context has no prompt surface for an `ask` to reach. A rite that
ran inside a persona could not perform a single one of its own writes.

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

Read every `## Finding` section in `docs/retrospective/<previous-iteration>/*.md` on the default branch.
Each is a **candidate**, not an item: it has no Issue, no `ready` and no estimate. Present it as itself
and record his ruling; **an Issue exists only where he says so**, and it is filed with **no milestone**
like every other Issue (#365), then admitted in step 4 by the same route as everything else.

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
apply a label even if it tried. And rule 10 denies `--milestone` to **every** non-empty `agent_type`
regardless. Two independent layers, neither of which depends on the brief being obeyed.

**What it is given:** the three classes from step 1, verbatim, both repositories, with labels and
`sp:N` where present. **What it returns:** a ranked eligible pool and its process findings, in its
own `SELECTION-RECORD` shape.

**The ordering rules it applies are ratified, not invented** — `loop` before `product` among the
eligible (#339), and eligibility as defined above. It does not invent an order and this rite does not
ask it to.

### The one adaptation planning forces, and it is a circularity

`agents/scrum-master.md` tells it to rank against **the order of record**, and states that the order of
record is *the milestone description*. **At planning that description does not exist yet — this rite is
what produces it.** So on a composition there is nothing to rank against and the instruction is circular.

**Resolution: at planning it ranks by the ratified rules alone, and says so in its record's *What I
could not see* section.** `agents/scrum-master.md` carries the same sentence, so the two surfaces agree
rather than needing to be reconciled by whoever reads them. Where an iteration is being **re-planned**
and a description already exists, the ordinary instruction applies unchanged.

### Its ranking is advisory and the owner overrules it item by item

Nothing reads `SELECTION-RECORD` — its own brief says so — and this rite does not make it a gate. The
ranking decides the **order the items are presented in**, and nothing else. Every admission is his.

## Step 3 — present ONE item at a time, and take his ruling on each

**One question at a time. No multiple choice. No decision list.** Two standing owner constraints, both
broken before, and a batch of admissions is a decision list wearing a table.

Per item, in ranked order, present: the number, the title, its type, its labels, its `sp:N` if it has
one, and one line of why it ranks where it does. Take one of four rulings:

| ruling | what the rite does |
|---|---|
| **admit** | it joins the composition being assembled in step 4 |
| **defer** | nothing; it stays unmilestoned and returns at the next planning |
| **drop** | nothing in the tracker. **DROP means withhold, never close** — an Issue he opened is not closed on a rite's advice |
| **needs a decision first** | apply `blocked` and record the question on the Issue |

**Do not proceed to the next item before his ruling on the current one is recorded.** A rite that
presents five and collects five answers has produced the decision list the constraint forbids.

**It does not estimate.** No `sp:N` is produced, requested or required here; estimation is
`/agents-configuration`'s *Estimation* section, with its own estimator sets and its own trigger.

## Step 4 — create the iteration, then admit the items, in that order

**The order is load-bearing and is the consequence of a measured gap: there is a CREATE route and no
UPDATE route.** `scripts/milestone-create.sh` accepts `--description` at creation; nothing in this
harness can amend a milestone description afterwards (`gh api -X PATCH` is denied by
`permission-guard.sh` rule 5f, and there is no `gh milestone` subcommand at all). Since the milestone
description is where `/agents-configuration` says the **order of record** lives, the ordered body has to
be known before the object is created — so composition is collected first and the milestone is created
once, carrying it.

**4a · create the iteration, once per repository that has admitted items:**

```
bash scripts/milestone-create.sh "<iteration>" --repo <owner>/<repo> --description "<the ordered body>"
```

**This PROMPTS, and the prompt is the point.** Rule 11 asks the orchestrator; his answer is the human
verification #365 demands. The script refuses a duplicate title in that repository and prints what the
API returned.

**It works because a hole is open, and this rite repeats that rather than relying on the script's own
header to say it.** Neither the settings matcher nor `permission-guard.sh` looks inside a script, which
is the same blindness that makes `python3 -c "…gh api -X POST…"` reach the write API. **No document here
may claim the raw-API route is closed.**

**Where the milestone already exists** — the owner created it in the browser, or a previous planning did
— **skip 4a and say in the artifact that the order of record could not be written**, because there is no
update route. That is a real residual of this rite and not a step anyone forgot.

**4b · admit each item, one call per item:**

```
gh issue edit <n> --repo <owner>/<repo> --milestone "<iteration>"
```

**Each one prompts under rule 10, and each prompt is his verification of that admission.** N items is N
prompts, which is the cost #365 priced and accepted: planning is owner-present by construction, so there
is no path where this prompt fires at a moment he is absent.

**An iteration is TWO milestone objects paired by nothing but their title.** Type it identically in both
repositories or the iteration silently becomes two, each derivation succeeding and each reporting a
healthy pool. Nothing detects this.

## Step 5 — the artifact, and what it is standing in for

**The orchestrator writes `docs/planning/<iteration>.md`** on the branch the planning lands on, and it
is the only durable record that this rite ran:

```
# <iteration> — planning

commit: <the SHA of the repo state the pool was assembled from>
assembled: <YYYY-MM-DD>  ·  repositories: <both, named>

## The pool as assembled
eligible: <n> · awaiting the owner: <n> · content (not drained): <n>
proposals read from docs/retrospective/<previous>/: <n findings across <n> files>

## The ranking as returned
<scrum-master's ranked list, verbatim, and its process findings>

## The rulings
| # | item | ruling | note |

## The composition
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

**That is correct rather than a defect, and naming it is the whole obligation here.** The rite closes by
listing the admitted items carrying no `sp:N` — one line each, no dispatches — so the estimation pass is
a known next act instead of a surprise at the drain's door.

## What this rite does NOT do

- **It does not place work.** He rules; the prompt is his answer.
- **It does not decide what an iteration should contain.** It assembles, ranks and asks.
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
  mistyped iteration title, and a planning that presented three items instead of thirty are
  indistinguishable from the tracker.
- **Nothing observes that `scrum-master` was dispatched.** `dispatch-metrics-stop.sh` reads an Issue
  number out of the branch name, and a planning branch need not carry one; the profile holds no tools,
  so it leaves no other trace.
- **Nothing observes the one-at-a-time rule.** It is a discipline, checkable by reading the artifact's
  rulings table and by nothing else.
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
