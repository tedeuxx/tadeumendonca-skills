---
description: Capture a request as a GitHub Issue — search for the decision that already exists, run the two-lead intake, and open it with the description closed or with the reason it is not. Use when the owner describes something he wants, when work would otherwise start untracked, or when it is unclear whether a request reopens a settled decision. Not for executing issues already filed (see autonomy-on).
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

### 2 · Run the two-lead intake

Dispatch **`product-lead`** and **`tech-lead`**, in parallel, each on its own half. Brief them with what
the search found, so neither re-derives it.

- **`product-lead`** — is it worth building, where does it sit against the open queue, what is the thin
  first slice, and how would we know it worked. **Tell it explicitly that recommending *defer* or *drop*
  is a useful answer**, or it will optimise for agreeing with the request. **It also holds the market
  half** — positioning, voice, cross-surface coherence, the owner's career — since `marketing-lead`
  merged into it on 2026-08-04.
- **`tech-lead`** — the data model, the contract, what it drags in, and whether a record is owed. It is
  the only writer of ADRs; if it writes one, that file rides in the implementing MR, not here.

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

### 3 · Label it honestly, and `ready` is not automatic

**`ready` means the leads closed the description** (the SDLC-generic bar a description must clear to
earn it is `/definition-of-ready`). It does not mean the Issue exists.

- **Both closed it and neither says stop** → apply `ready`.
- **Any lead recommends defer or drop** → **do not apply `ready`.** Record the recommendation in the body
  with its reason. An Issue carrying "the leads say don't build this" is a real artifact; the same Issue
  labelled `ready` is a lie that `autonomy-on` will act on.
- **A lead needs an owner decision to close its half** → no `ready`, and put the question in the body in
  the form the owner answers in one line.

Also apply exactly one type, required: **`product`**, **`content`**, or **`loop`** — the three types are
exclusive routing labels, not independently optional (ADR-0012). Also apply **`reader-facing`** if a
reader sees anything; **`blocked`**
only if something concrete is in the way, and **name what** — a `blocked` label whose blocker is not
written down reads as *waiting on the owner* forever. (#166 carried one for over a week after its stated
blocker had shipped.)

**Stamp the intake.** Record the date and the `main` SHA the leads read. A closed description ages: the
tree it was closed against moves, and a reader in November needs to know whether August's closure still
describes the code.

### 4 · State the class

**safe** or **boundary**, per the repo's guide, with the clause that decides it. Boundary is: anything
touching `iac/` or the site's continuity, a change to the dev-loop's own rules, and publishing an article.
*Significance beats in-pattern* — when the class is unclear, it is boundary.

### 5 · Open it

`gh issue create --body-file <path>`. **Always a file, never `--body`** — a multi-line body through
`--body` loses every backtick to command substitution, silently, and this repo has paid for that four
times in one session.

## What this command does NOT do

- **It does not build anything.** It opens an Issue. `autonomy-on` picks it up.
- **It does not decide.** The leads advise, the owner decides, and an Issue that resolves a disagreement
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
