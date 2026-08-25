---
description: Capture a request as a GitHub Issue — search for the decision that already exists, run the intake the issue's type routes to, and open it with the description closed or with the reason it is not. Use when the owner describes something he wants, when work would otherwise start untracked, or when it is unclear whether a request reopens a settled decision. Not for executing issues already filed (see autonomy-on).
argument-hint: "<what you want, in your own words>"
---

Turn `$ARGUMENTS` into an Issue in the current repo.

**This command exists because the owner is the only one who opens work, and that rule was costing him
the quality of the Issue rather than protecting it.** He describes the thing in a sentence; the expensive
part — finding out whether it is already decided, and closing the description — is the agent's.

## Why the search comes before the writing

Two Issues opened on 2026-08-03 are the evidence, and both would have been *reopening a settled decision*
without this step:

- **#345** ("the `-skills` card shows RELEASES where `-io` shows its tag") — `src/data/catalog.ts` carried
  the reason **on the field itself**: a build-time GitHub API call had been refused by the owner because
  rate-limiting could red a healthy `main`. The Issue that got opened said *"here is why it was
  deliberate, and here is which half of that reasoning just stopped being true"*. That is executable. *"The
  card doesn't show a tag"* is a complaint.
- **#346** ("two navbar items have no border") — `AppShell.tsx` recorded the alternation as **deliberate**,
  from #315, with the reason. The Issue could then be about *retiring a rule* rather than *fixing a bug*,
  and it named what would be lost.

**A request is a symptom. The decision behind it is usually written down somewhere in this repo, and the
person asking is the least likely to remember where.**

## What to do

### 1 · Search before writing a single line of the body

Look for the thing already being decided, in this order — stop widening once you have the answer:

- **the code that implements it** — a doc comment on the field, the component, the constant. This repo
  puts reasons next to the thing they govern, so this is the highest-yield place and the least obvious;
- **`docs/adr/`** — read the index, then the record. An ADR *amendment* is where a decision most often
  changed without the surrounding prose moving;
- **closed Issues and merged PRs** — `gh issue list --state closed --search`, `gh pr list --state merged`;
- **`CLAUDE.md`, `apps/*/CLAUDE.md`, `.github/workflows/README.md`** — the guides, for anything about how
  work is done rather than what the product does;
- **`.brand/`** — for anything touching positioning or copy. **Read it, never quote it into the Issue**;
  it is gitignored and must not reach a public surface.

Then say, in the Issue, one of three things:

- **it was decided, and here is the reason** — quote it, cite the file and line, and frame the request
  against it;
- **it was decided, and a premise has since changed** — name which one and what changed it. This is the
  strongest shape an Issue takes, and it is the one that cannot be written without the search;
- **nothing decides it** — say so explicitly. That is a finding too, and it stops the next reader
  repeating the search.

**Do not skip this because the request sounds small.** #346 was "two buttons look wrong" and the border
turned out to encode route-vs-anchor by design.

### 2 · If the ask is `content`-typed: interview the owner FIRST

**Scope: `content` only.** A `product` ask skips this step entirely and goes straight to the **two-lead**
dispatch in step 3; a `loop` ask skips it and goes straight to the **`agents-lead`-alone** dispatch in the
same step. Nothing in it changes either of those two intakes.

**Why it sits before the dispatch and not after it.** In the consuming product repo, `#503`'s body carries a section
headed, literally, *"The one line for the owner"* — **two full lead dispatches were spent producing one
question**, and the question was for the person who had the answer before either agent started. Asking it
first collapses that: the `content` lens then judges against a stated take instead of reconstructing one.

**One required question. Ask it in these words:**

> **What does this claim, and what do you want to say back?**

Its **first clause** is the one `#503`'s own one line opens on — *"What does this video claim about how
forward-deployed engineering is done…"* — reached only after both lenses had run. **The second half is not
`#503`'s wording.** That Issue's one line is a three-way question, and the two clauses following its first
are the leads reconstructing a position the owner already held; *"what do you want to say back"* is the
generalisation of what that reconstruction was for, asked of him directly instead.

**Then follow-ups — one at a time, and only while he is still answering.** The moment he stops, stop
asking and open the Issue.

- **Where in these two repos is there something that bears on it?** → ADR-0046 gate 1's input (*"Name the
  artifact in these two repositories that proves the video's claim right or wrong"*). **The only follow-up
  with a named downstream consumer**, which is why it is first.
- **Does it still stand if you delete the video?** → ADR-0046 gate 2 (*"Delete the video. Is it still an
  article?"*). Optional here — the intake lens can run this one itself.
- **Who is it for, and what should they do differently after reading it?** → `published-voice`'s goal and
  filter: connection with the two personas is the goal, value to them is the filter.

**Two standing owner constraints, both stated by him and both broken at least once:** **one question at a
time**, and **no multiple choice**. A questionnaire is not an interview — four questions in one message is
a form, and offering options to pick from decides the answer for him.

**And it must not block the capture.** He is often mid-something else. **One line and stop still opens the
Issue**: question 1 unblocks the machine, the rest only improve the piece. An interview that costs him a
sitting is one he routes around inside a week, and then there is no interview at all.

**Record his answer verbatim, quoted, as his words** — not paraphrased, not tidied, not translated.
`published-voice`'s sourcing constraint is why: *"A draft shapes, cuts, structures and translates an
experience, an opinion, or a result the owner already has. It never originates one."* The recorded take
**is** the source `content-writer` cites for the stance, and a paraphrase is a stance with no attributable
origin — which its brief forbids it from using.

#### The marker — and recording the absence is the design, not the fallback

Put one of exactly two forms in the Issue body. There is no third spelling, and a gate asserts that
(`hooks/scripts/inventory-counts.test.sh`).

```
<!-- owner-take: supplied -->
> «his sentence, verbatim»
```

```
<!-- owner-take: not-supplied 2026-08-23 -->
```

**The second form is a first-class outcome, not a failure path.** Forcing a take means denying a capture
at the worst possible moment — which is how a mechanism gets routed around inside a week, and a mechanism
nobody uses records nothing. `not-supplied <date>` is a fact a later reader acts on: it says the question
was asked and left open, and it dates the asking. Silence says neither.

**The hole, stated here in the file where the rule lives and not only in the PR that shipped it: a model
that never asks can write `not-supplied` and pass.** No layer closes that. The gate reads the literal, not
the conversation; nothing in the harness can distinguish an interview that happened and got one line from
an interview that never started. This is a discipline with a marker, not an enforcement — treat a
`not-supplied` marker as a claim about the process, and claims about the process are exactly what this
loop does not verify.

### 3 · Run the intake the TYPE routes to — branch before dispatching

**Decide the type first (step 4's three exclusive labels), then dispatch. There is no default intake.**
Who takes part is not this file's to state: the canonical wording is the `filed → **description closed**`
rows of the states table in `/harness-engineering`, and this step **defers** to it rather than restating
it. If this step and that table ever disagree, **the table wins and the disagreement is a finding** — two
surfaces stating the same operative rule independently is precisely what produced eleven days of drift
with nothing able to contradict either (#329).

| the ask is | dispatch | in this file |
|---|---|---|
| **`product`** | `product-lead` **and** `tech-lead`, in parallel | 3a below |
| **`content`** | `product-lead`, alone — after the step-2 interview | 3a below, its `product-lead` half only |
| **`loop`** | **`agents-lead`, alone — never `tech-lead`, no exception** | 3b below |

**Why the `loop` row is unconditional, stated here because this is the file that executes it.** The
owner's ruling on #329 was one word — **"nunca"**. There is no straddling case and no test to apply at
dispatch time. His reason, and it is the reason this row must not grow a qualifier: *almost every*
machinery change can be described as having an architecture edge, so a loose exception does not stay
loose — it becomes the default case, because the reading that admits it is always available. That is how
the pairing came back once already, on 2026-08-13. **A rule with a judgement-call escape hatch is the
escape hatch.**

#### 3a · `product` and `content` — the lead intake

Dispatch **`product-lead`** and **`tech-lead`**, in parallel, each on its own half — **`product-lead`
alone when the type is `content`**. Brief them with what the search found, so neither re-derives it.

- **`product-lead`** — is it worth building, where does it sit against the open queue, what is the thin
  first slice, and how would we know it worked. **Tell it explicitly that recommending *defer* or *drop*
  is a useful answer**, or it will optimise for agreeing with the request. **It also holds the market
  half** — positioning, voice, cross-surface coherence, the owner's career — since `marketing-lead`
  merged into it on 2026-08-04.
- **`tech-lead`** — the data model, the contract, what it drags in, and whether a record is owed. It
  writes the **product/system-architecture** ADRs — not every ADR: authorship is split by domain since
  #223, and `agents-lead` writes the loop/machinery ones. If either writes one, that file rides in the
  implementing MR, not here.

**Which half of `product-lead` applies is a briefing instruction, not a dispatch decision.** This used to
say *"dispatch the copy lens only if a reader would see anything, and skip it for pure infrastructure"*.
There is nothing left to skip — the persona runs either way — so say in the brief which half you want:

- **A reader would see something** (copy, a label, a route name, a visual change) → ask for **both**
  halves, and ask explicitly for the **surfaces this leaves stale** if it ships alone. That list is the
  highest-value line in the Issue and nobody else is holding it.
- **Pure infrastructure** → ask for the ordering half only, and **say in the Issue that the market half
  was not asked for**. Saying so is the point: it is the difference between a lens that found nothing and
  a lens that was never pointed at anything, and the old *"say you skipped it"* rule existed for exactly
  that reason. It survives the merge.

Note what this changes at review time, in the other direction: on the **MR**, `quality-assurance`'s
criterion 10 still requires the copy lens to have returned a verdict on any reader-facing diff, and its
**truth findings block**. Intake is where the framing is decided; the merge gate is where it is owed.

**They are meant to disagree.** Where the two leads reach opposite conclusions, put the disagreement in
the Issue as a disagreement — do not resolve it yourself. #166's route-vs-section split is the shape: the
Issue is more useful carrying both arguments than carrying a resolution nobody ratified.

#### 3b · `loop` — `agents-lead` alone

Dispatch **`agents-lead`**, and dispatch nothing else. Brief it with what the search found. What it
returns is its own mandate, not a lead's: **the scenarios the proposal does not cover, each with how to
check it or labelled a hypothesis**, and a mitigation or the price of accepting each one.

- **Do not dispatch `tech-lead` alongside it**, on any reading of the ask. See the ruling above.
- **`product-lead` is not dispatched either.** Its boundary is the product (ADR-0002 amendment #14); on a
  `loop` ask it may block only on a false *published* claim, which is a merge-gate act, not an intake one.
- **`agents-lead` may be the record's author.** A `loop` decision significant enough to record is its ADR
  to write (#223), and that file rides in the implementing MR, not here.
- **It gates nothing and files nothing.** It holds no merge, opens no Issue, and its return is advice the
  owner acts on — which is why the `ready` transition below is his alone on this lane.

### 4 · Label it honestly, and `ready` is not automatic

**`ready` means the description is closed by whoever closes it on that lane** (the SDLC-generic bar a
description must clear to earn it is `/definition-of-ready`). It does not mean the Issue exists, and
**who closes it is per-type — the `filed → **description closed**` rows of `/harness-engineering`'s
states table are canonical**:

- **`product`** — both leads closed it and neither says stop → apply `ready`.
- **`content`** — `product-lead` closed it and does not say stop → apply `ready`. **`ready` on a
  `content` Issue is not a queue**: the owner selects content one piece at a time, and `/autonomy-on`
  excludes the lane deliberately.
- **`loop`** — **`ready` is the owner's transition and nobody else's** (ADR-0002, record 0015's
  Corollary 4). `agents-lead` closing the description does **not** earn the label; report to the owner
  and let him apply it.

And on every lane:

- **Any dispatched persona recommends defer or drop** → **do not apply `ready`.** Record the
  recommendation in the body with its reason. An Issue carrying "the intake says don't build this" is a
  real artifact; the same Issue labelled `ready` is a lie that `autonomy-on` will act on.
- **The intake needs an owner decision to close its half** → no `ready`, and put the question in the body
  in the form the owner answers in one line.

Also apply exactly one type, required: **`product`**, **`content`**, or **`loop`** — the three types are
exclusive routing labels, not independently optional (ADR-0002). Also apply **`reader-facing`** if a
reader sees anything; **`blocked`**
only if something concrete is in the way, and **name what** — a `blocked` label whose blocker is not
written down reads as *waiting on the owner* forever. (#166 carried one for over a week after its stated
blocker had shipped.)

**Stamp the intake.** Record the date and the `main` SHA whoever ran the intake read. A closed description ages: the
tree it was closed against moves, and a reader in November needs to know whether August's closure still
describes the code.

### 5 · State the class

**safe** or **boundary**, per the repo's guide, with the clause that decides it. Boundary is: anything
touching `iac/` or the site's continuity, a change to the dev-loop's own rules, and publishing an article.
*Significance beats in-pattern* — when the class is unclear, it is boundary.

**What the class decides changed on 2026-08-23 (ADR-0002 amendment #16), so state it for the right
reason.** `boundary` no longer means *the owner merges it*: the gate merges the boundary class too,
under its own verdict literal, and the owner reviews live after deploy. It still selects which of the
four surviving holds can apply, which literal ends up in the merge record, and what the verdict must
write down. **Do not drop the field** — an Issue whose class is unstated is one whose merge record
cannot say whether anything shipped unseen.

### 6 · Open it

`gh issue create --body-file <path>`. **Always a file, never `--body`** — a multi-line body through
`--body` loses every backtick to command substitution, silently, and this repo has paid for that four
times in one session.

## What this command does NOT do

- **It does not build anything.** It opens an Issue. `autonomy-on` picks it up.
- **It does not decide.** The intake advises, the owner decides, and an Issue that resolves a disagreement
  the owner has not seen is worse than one that surfaces it.
- **It does not open work nobody asked for.** The owner invoked it; that is the authorization, and it is
  the whole reason this command can exist while *only the owner opens work* still holds.

## The cost, stated once because the owner accepted it knowingly

Running the leads at capture time pays for an intake on Issues that may sit for months or never be
built. On 2026-08-03 the #166 intake cost **three** agents to conclude **defer** — that is what it cost
on the day, and the roster has since shrunk: the same intake now costs two, because `marketing-lead`
merged into `product-lead` on 2026-08-04. The trade below is unchanged; only the price moved.

That is the deliberate trade: a described-but-unclosed Issue is a decision the owner has to make again
later, at a worse moment, with less context. The alternative — intake at pick-up time — is cheaper per
Issue and puts the thinking in the path of the person trying to ship. The owner chose to front-load it.
