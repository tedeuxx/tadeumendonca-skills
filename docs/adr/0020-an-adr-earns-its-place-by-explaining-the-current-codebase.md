# 0020. An ADR earns its place by explaining the **current** codebase

- **Capability:** decision-library
- **Status:** accepted
- **Date:** 2026-08-15
- **Deciders:** the owner (decision); written by `agents-lead` under the ADR-authorship domain split
  — record 0017, absorbed 2026-08-20 into this document's own *ADR authorship is split by domain
  (absorbed 2026-08-20, record 0017)* section below — a pure loop/documentation-practice decision with
  no product-architecture consequence
- **Supersedes / superseded by:** — . It supersedes no record. The rule it replaces,
  *supersede-never-delete*, was **never recorded as an ADR** in this library: it had no
  `Decision outcome` anywhere in `docs/adr/`, living instead in
  `skills/documentation-standard/SKILL.md` (Part II) and in the index prose of this library's
  own `README.md`, and being **cited as settled** by live records. **That set is stated by its
  criterion, never by a count** — the two readings give different sets and both are needed:
  - **Citing `supersede-never-delete` by name: two.** Record 0019's rejected option 3, *"this repo's own
    convention (supersede-never-delete) already answers the question"* — since 2026-08-20 the
    *`README.md` is the single source of truth for the dev-loop narrative (absorbed 2026-08-20, record
    0019)* section of [ADR-0002](./0002-roster-and-dev-loop.md) — and ADR-0011's *"Struck rather
    than deleted, per this repo's supersede-never-delete convention"*.
  - **Citing the `supersede-*` family: five.** Those two, plus record 0010's *"Struck rather than deleted,
    per this practice's supersede-never-rewrite rule"*, ADR-0002's *"the rule is
    supersede-never-rewrite"* and record 0016's *"ADR-0011's own supersede-not-rewrite rule"* — the
    last of which is now a clause of the *The `archive` disposition is a file move to `docs/archive/`,
    not a frontmatter flag (absorbed 2026-08-20, record 0016)* section of
    [ADR-0011](./0011-skills-and-preload.md), kept verbatim through that fold **because this
    enumeration quotes it**. All five records were `accepted`.

  Only **one** citation anywhere in that family is about the arm this record replaces — record 0019's,
  which is an argument against `git rm`-ing a **whole file**. **The other four — ADR-0002's own
  *"the rule is supersede-never-rewrite"*, record 0010's, ADR-0011's and record 0016's — each justify a strike
  inside a live record**, which this
  record leaves explicitly unchanged. All four are correct as they stand and are **not** to be swept.
  Enumerate them without the hyphenated name, since every one of them is line-wrapped across a hyphen:
  `git grep -n -E "supersede[- ]?never|supersede-not" -- docs/adr/`.
- **Driven by:** [#281](https://github.com/tedeuxx/tadeumendonca-skills/issues/281)

## Context & problem

An ADR library is read by two consumers with different failure modes. A human skims titles and statuses.
**An agent loading a decision library reads bodies, not status lines** — and a whole-file record whose
entire subject is a component that was switched off is, to that reader, a description of an architecture
that does not exist. It does not merely fail to help; it is actively misleading, because architecture is
exactly what a reader infers from a record's body.

The library's practice until now answered this with a **marker**: a reversed decision took
`status: superseded`, kept its file, and linked forward — *"reverted decisions are history, not gaps."*
The premise underneath that rule is the same premise as this one: a retired record misleads a future
reader. **That is attested, not inferred** — the text of the old rule argued from *preservation value*
(*"history, not gaps"*) and never stated the misleading-risk premise, so it is worth showing where the
premise actually is written down. It is in the owner's own published voice, in `tadeumendonca-io`'s
`apps/fed/src/content/architecture.pt.md`, in the `status` / `superseded-by` bullet: *"**Sem isso,** o
registro de uma arquitetura aposentada lê como instrução — que é a forma mais barata de fazer um agente
reconstruir algo que foi cortado de propósito."* The same reader, the same failure, on the surface the
old rule was defended on.

**The leading clause is quoted because the passage turns on it.** *Sem isso* means *without the status
marker*, and the same bullet closes asserting that the table is where reverted decisions *"aparecem
marcadas em vez de sumirem"*. In full, then, the passage that attests the shared premise is **the
owner's published defence of the remedy this record rejects** — it is cited for the premise and not for
the remedy, and the elision is not worth the four words it saves. The strongest statement of the risk
sits on the page that answers it the other way, which is itself the argument: the two rules split only
on the **remedy**, and the case for changing it is that the marker is not enough — the file is still
there to be inferred from, and the reader most at risk never reads the status field that carries the
marker.

**Why a record is owed for this, and on which arm of the significance test — corrected.** The
implementing MR ([#282](https://github.com/tedeuxx/tadeumendonca-skills/pull/282)) named the arm *alters
a previously-recorded decision*. **That arm does not fire**, for the reason recorded in the
*Supersedes* line above: nothing was previously *recorded*. The arm that fires cleanly is **sets a
cross-cutting pattern others will follow** — this rule governs **both** ADR libraries (methodology here,
product in each consuming repo), it prescribes an irreversible act (`git rm`) against artifacts that a
published page in `tadeumendonca-io` renders, and live records already cite the convention it replaces
(two by name, five across the `supersede-*` family — enumerated in the *Supersedes* line above). A
record that misstated its own trigger would be the exact defect this Issue exists to remove, so the
correction is carried here rather than quietly fixed.

## Decision drivers

- **The reader at risk is an agent, and it reads bodies.** Any remedy that lives only in a status field
  or a filename is invisible to the consumer whose misreading is the cost.
- **A deliberate absence and a silent one must not look identical.** Whatever replaces the file has to
  answer *"was this ever decided?"* — otherwise the change is indistinguishable from the drift record
  0001 was adopted to stop.
- **Some reversals are only intelligible against what they replaced.** Deleting the retired record
  without capturing that context is a net loss of information, not a cleanup.
- **The `status` field is the only trustworthy criterion.** `-io`'s library already contains a record
  that is `superseded` by status and *not* named `superseded-*`, so any filename-driven rule is
  off-by-one on the first execution.
- **Struck history *inside* a live record is a different object** and is load-bearing here:
  `hooks/scripts/inventory-counts.test.sh`'s roster-membership assertion distinguishes a superseded
  claim from a stale one by exactly those markers. A rule phrased as "delete what is not current" would
  invite stripping them, and — measured — stripping them makes that gate **quieter, not red**.

## Considered options

1. **Three dispositions keyed on the record's `status` field: delete with a mandatory History row, fold
   the context into the superseding record first, or keep the file** *(chosen)*. Delete is the default
   for a record whose whole subject is a component that no longer exists; the fold is mandatory wherever
   the current decision is only intelligible against what it replaced; the file is kept for a `proposed`
   record (it explains an *intended* codebase, and its status says so) and for an `accepted` record whose
   mechanism merely has no instances yet. *Trade-off:* **the reasoning of a reversal is no longer
   preserved at length.** A one-line History row plus a `## What this replaced` section keeps what was
   load-bearing and drops the rest, deliberately. Both halves are prose with **zero enforcement** —
   measured, below — so a careless executor can take the deletion and skip the compensation.

2. **Keep *supersede-never-delete* unchanged** — the status quo, and the strongest rejected option
   because it is not wrong about the risk. *Why not:* it addresses the risk with a marker the misreading
   consumer does not read. It also accumulates: a library that never removes anything grows a permanent
   fraction of content describing systems that do not exist, and that fraction is loaded, cited and
   rendered like the rest.

3. **Move the retired record to `docs/archive/`, as the skills-archive mechanism does for skills, rather
   than deleting it** — record 0016, now the *The `archive` disposition is a file move to
   `docs/archive/`, not a frontmatter flag (absorbed 2026-08-20, record 0016)* section of
   [ADR-0011](./0011-skills-and-preload.md). *Why not:* that mechanism works because something
   **computes over the directory boundary** — `inventory-counts.test.sh` scans `skills/` and an archived
   file is outside it, so the move changes behaviour. **Nothing keys on the `docs/adr/` boundary**, so
   moving a record out of it changes no gate's outcome. Machinery does read the directory — the same
   suite greps two literal strings out of `docs/adr/0004-controls-and-enforcement.md` **by path**,
   and `docs-test.yml` carries `docs/**` in its `paths:` filter precisely so the floor-claim assertion,
   which scans every tracked `.md`, starts on an ADR edit — and that makes the why-not **stronger**: an
   archived record is still scanned by that assertion, still a full-length body describing a dead
   architecture, still greppable, still loadable, just one directory further away. The move buys the
   appearance of the remedy and not the remedy. An accepted asymmetry rather than an inconsistency: the
   two records disagree about the mechanism because in `skills/` the directory boundary is what a gate
   reads, and in `docs/adr/` nothing reads it.

4. **Build a gate — a check that fails when a record's `status` is `superseded`, or when a deletion lands
   with no History row.** *Why not:* not rejected on merit, deferred on evidence. The deletion set in
   this library is **empty** today, so the gate would have nothing to run against here, and its first
   real subject is `-io`'s library under a separate slice. Enforcement built ahead of its first
   execution is how this repo has previously acquired checks that pass without reading anything. Named as
   an open question below rather than closed.

## Decision outcome

Chosen: **option 1**, in the wording that now lives in
`skills/documentation-standard/SKILL.md` under the heading *"A record earns its place by
explaining the CURRENT codebase"* — the skill is the operative text; this record is the decision and its
argument.

Two preconditions are what make it a disposition rather than a deletion, and both are stated in the
skill as preconditions rather than follow-ups: **the History row** (*"A deletion with no row is not this rule; it
is a gap"*) and **the fold** (*"If there is nowhere to fold and no row is written, do not delete"*).

Two boundaries are part of the decision, not caveats on it:

- **It is scoped to whole records, never to sentences inside a live one.** Within an `accepted` record
  the convention is unchanged and load-bearing: amend by appending, strike in place (`~~…~~`), never
  rewrite.
- **It is scoped to *reversed* decisions, never to *unbuilt* or *unexercised* ones** — disposition 3.

**This library's own deletion set is empty, and that was measured rather than assumed:** **19 records
before this one** — 18 `accepted`, 1 `proposed`, zero `superseded` — and 20 / 19 / 1 / 0 once this record
lands, since it is itself the twentieth. Both figures come from the same pair of commands, run at
`2de6844`:

```
ls docs/adr/0*.md | wc -l                     → 20 (19 before this record)
grep -ih "^- \*\*Status:\*\*" docs/adr/0*.md  → 19 accepted, 1 proposed (0007), 0 superseded
```

The count that carries the decision is the last one: **zero `superseded`**, which is what *the deletion
set is empty* means and the only figure here the rule depends on. The retired machinery in this repo
lives *inside* live records as struck amendments, where the remedy is the strike convention and not
deletion. So this record changes what happens next; it deletes nothing today.

## Consequences

**Good**

- The consumer whose misreading is the actual cost — an agent loading the library — stops being handed
  full-length descriptions of architectures that do not exist.
- The absence stays deliberate and cheap to audit: one History row per removed record, carrying the id,
  what was decided and what replaced it.
- The context that was genuinely load-bearing survives **in a live record**, where it explains today's
  codebase, instead of in a dead one where it describes yesterday's.

**Bad / accepted costs**

- **The reasoning of a reversal is no longer preserved at length.** This is the real price, and the
  fold only recovers the part that still shapes the current design. `git log` retains the deleted file,
  but a record that requires archaeology is, for the reading consumer, gone.
- ~~**Nothing enforces any of this — measured, not assumed.** A record was deleted outright from a
  scratch copy of this tree and the full suite still reported `69 passed, 0 failed`. No hook, workflow
  or settings file asserts anything about the ADR library's shape. The History row and the fold are
  prose too and inherit the same zero enforcement; the only compensating control is that both halves
  land in the same MR, where a reviewer can see them.~~

  **Struck 2026-08-19 by this record's own amendment below** — the one clause in this list the
  amendment reaches, and it is struck rather than left standing because the sentence *"No hook,
  workflow or settings file asserts anything about the ADR library's shape"* is **false at head**: the
  amendment's own gate is that assertion. It was true when written and stayed true exactly as long as
  the deletion set was empty. The same mutation at head, on the tree in place:

  ```
  mv docs/adr/0002-roster-and-dev-loop.md <elsewhere>
  bash hooks/scripts/inventory-counts.test.sh        →  65 passed, 5 failed
  ```

  The **five reds** are what the claim turns on and they are unchanged: four citation arms (relative
  link, repo-root path, stale foreign exemption, prose token) and the numbering arm. The **passing**
  total moved from 58 to 60 in this same MR's second review round, which added two verdicts by
  splitting two more suppressed arms apart, **and from 60 to 65 across #283's folding slices** — S3
  added arm 4c, S5 added arm 4d, and the rest is the suite growing around them. Re-performed at S5's
  head rather than inherited. It is restated here rather than left at the figure the
  round-1 fix measured, because a published number that silently drifts is the defect this record's
  own amendment is about.

  **What survives the strike, and it is the half that still binds:** the row's **honesty** and the
  **fold** are still prose and still inherit zero enforcement. The gate reads that a row exists and
  that it names a destination; nothing reads whether the destination received the decision. Both halves
  still land in the same MR, where a reviewer can still see them, and that is still the only control
  over the part that is not gated.
- **The first real execution is in `tadeumendonca-io`, and it reddens a gate there.**
  `apps/fed/src/components/AdrTable.test.tsx` asserts `inLibrary > 5` over records with
  `status === 'superseded'`, and that library has **8** such records
  (`grep -c '"status": "superseded"' apps/fed/src/content/generated/adrs.json` → 8). A deletion sweep
  makes that assertion false. Sequencing and the fix are that slice's, not this record's; named here so
  it is not discovered as a surprise.
- **`architecture.{en,pt}.md` in `-io` states the superseded rationale in the owner's own voice**, as
  published copy rather than a link. Whether that paragraph stays true after a deletion is
  `product-lead`'s call, whose findings on published copy are blocking. Not settled here.
- **Three further `-io` costs, so this list is the whole brief the `-io` executor meets.** The
  enumeration above stopped at what this repo could see, and a cost list that presents itself as a brief
  and is short by three is worse than one that names its scope. Still not this slice's work — recorded
  so the executor is not surprised:
  - **`tadeumendonca-io/docs/adr/README.md` still publishes the retired instruction** verbatim — *"A
    reversed decision becomes `superseded by ADR-XXXX` and links forward — never deleted."* It is the
    sibling of the sentence this MR struck here and it survived every sweep for the same reason: **it
    shares no vocabulary with `supersede-never-delete`**. Two public repos will carry contradictory
    imperative instructions about one practice until that slice lands.
  - **Disposition 1's designated home in `-io` contradicts the rule in its own heading**, and its row
    form does not exist yet. That library's History table is headed *"History (superseded —
    reverse-engineered, kept not deleted)"*, and every existing row links a live file — so the first
    disposition-1 row would sit under a heading asserting the rule it replaces, and **would 404 its own
    link** unless the table's form changes with it.
  - **`architecture.{en,pt}.md` hard-links five superseded records by URL** (`0025`–`0029`) and
    characterises their contents in the owner's voice. The five URLs are in the **table** under the
    heading
    *"O que foi cortado — e tinha sido construído antes, que é a parte que importa"*
    (*"What was cut — and it was built first, which is the part that matters"* in `en`). The subsection
    below it,
    *"Se você precisar do backend de volta, o registro diz qual decisão reverter"*,
    carries the argument those links serve — reversibility is concrete because each reversal names the
    decision to reopen — and refers to the five by bare number, pointing **upward** at the table rather
    than linking them again. So a deletion sweep **404s five published links inside a live argument that depends on them
    being readable**. A larger cost than the `AdrTable.test.tsx` assertion above, and the reason
    disposition 2's fold is a precondition rather than a follow-up.
    **This bullet's first form named the subsection as the link site, and that is worth recording where
    it happened:** it is the first instance *inside* the convention written to stop it. The heading was
    quoted verbatim, as the rule asks — and it was the wrong heading. **Quoting a heading pins a region
    only if it is the region the cited content sits in**, not the nearest one that describes it; the
    rule's operative wording in `skills/documentation-standard/SKILL.md` now says so.
- **The disposition-1 row has no defined home in *this* library yet.** The skill mandates a row in the
  library's `README.md` History table; `-io`'s library has such a table and this one has only an index
  table. Left open deliberately — the deletion set here is empty, so the first executor is in `-io`, and
  inventing a table with nothing to put in it is the shape this repo tries hardest to avoid.

## Amended 2026-08-19 — a fourth disposition (**absorption**), and option 4's deferral is discharged

Appended rather than rewritten, per the convention this record leaves explicitly unchanged for live
records. Driven by [#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283), slice 2. **Every
word of the reversal rule stands** — the decision, its preconditions and its two scope boundaries are
untouched, and this amendment adds the case they do not reach. **Exactly one clause above is struck by
it, and it is a cost rather than a rule:** the *"nothing enforces any of this"* bullet, whose second
sentence (*"No hook, workflow or settings file asserts anything about the ADR library's shape"*) this
amendment's own gate makes false in the same MR. The strike is in place, in that list, with the
re-measurement beside it.

**The gap, in this record's own words.** *Decision outcome* states a boundary as part of the decision:
*"It is scoped to reversed decisions, never to unbuilt or unexercised ones."* #283 relocates roughly
fourteen records whose decisions are **still in force** — they are neither reversed, nor unbuilt, nor
unexercised, and dispositions 1–3 are keyed on a reversal at every joint. Disposition 2's
`## What this replaced` is the wrong heading for a decision nothing replaced, and disposition 1's row
would assert a supersession that did not happen. The rule did not merely fail to cover them; **applied
literally it would have produced false rows.**

**Disposition 4 — absorption.** A record whose decision is still binding may be deleted when that
decision **moves into the document that governs the thing it decides** — a capability document, or, for
the "is not an ADR at all" bucket, the code the reasoning constrains. The operative wording is in
`skills/documentation-standard/SKILL.md` under the heading
*"Absorption is a different act from reversal"*; this is the decision and its argument.

**Its preconditions are stricter than disposition 1's, and the reason is the reader's question.** A
reversed record leaves a reader asking *"was this ever decided?"*, which a one-line row answers
completely — the trail may end there. An absorbed record leaves a reader asking *"where is this decision
now?"*, and that reader is **still bound by it**. So: the row is mandatory **and so is a destination
link**; and the fold is **unconditional**, because absorption has a target by construction — there is no
"nowhere to fold" case for disposition 1's row to catch. **No destination, no deletion.**

**The fold is lossy by instruction.** What arrives at the destination is the decision as it currently
binds, the rejected options still live, and the consequences still being paid; superseded narrative,
defect archaeology and no-longer-binding struck amendments are dropped. Stated because the alternative
is not neutral: unsaid, "absorb" reads as "append", and this library's records average about **28 KB**.
Pinned to this amendment's base commit rather than to head, because a figure measured over a set that
includes the file stating it moves every time the sentence is edited:

```
git ls-tree -l c52aa4f -- docs/adr/ \
  | awk '$5 ~ /\/0[0-9][0-9][0-9]-/ {n++; s+=$4} END {print n, s, int(s/n)}'
  →  20 records, 572390 bytes, 28619 avg
```

So a capability assembled by concatenation lands at a size
the fresh agent context this practice exists to serve cannot afford to read. That is a real cost of the
consolidation and it is booked here rather than discovered at record nine.

**Considered option 4 is no longer deferred, because its stated premise is gone.** It was deferred on
*"the deletion set in this library is empty today, so the gate would have nothing to run against here"*.
#283 takes that set from zero to roughly fourteen. The gate is now built, in
`hooks/scripts/inventory-counts.test.sh`: **every number this library has issued is either a live record
or a History row naming a destination**, asserted in both directions.

**Why it keys on a declared ceiling rather than the highest surviving record — the ADR-0004 question,
answered.** A ceiling derived from the files that exist cannot see a deletion at the **top** of the
sequence: the derived maximum simply moves down and no gap appears. A declared constant closes the
**accidental** form of that case — the top record removed with the constant left alone — costs one line
per new record, and **fails closed**: adding a record without raising it turns the gate red and the
message says what to do. Measured, both directions: moving the top record out with the constant in
place reddens; adding a record without raising it reddens.

**It does not close the deliberate form, and no declared constant can.** Measured: lowering the
constant in the same edit as the deletion returns the arm to green
(`PASS — 19 live records, ceiling 19, 0 retired`). Recorded because the accidental case is the one
worth closing and a reader will otherwise price this control by the stronger claim — which the gate's
own comment made (*"closes that case completely"*) until this MR's review measured it and corrected the
word rather than the control.

**What the gate does not hold, said plainly.** It never reads the destination's **content**. A row
pointing at a document that never received the decision passes exactly like one pointing at a document
that did. The gate makes an absorption **visible and attributable**; whether it was **lossless** has no
instrument and stays a reviewer's judgement. Two layers, each holding what it can: this gate catches a
deletion **nothing cites** (which the citation gate is blind to by construction, having nothing left to
dangle), and slice 1's citation gate catches the inbound references. The same layering decides the row's
form — the retired number is written **bare** (`0008`), never with an `ADR-` prefix, because the prose
citation arm asserts every `ADR-nnnn` token names a live record and does not except this table.
Measured, running the gate's own two regexes over both row forms: the bare form matches **neither**, the
prefixed form matches the **prose** arm.

**A residual that arrived with the fix, and it is the gate's, not this rule's.** The prose arm greps the
token and not the sentence around it, so it cannot distinguish a **citation** from a **discussion of the
citation form**. A document teaching this row rule therefore cannot carry a concrete prefixed example —
when the record in the example is itself absorbed, the teaching text goes red and the obvious repair is
to edit an example that was never wrong. Cheap mitigation, taken: write the rule with the `nnnn`
placeholder and keep concrete numbers bare. No mitigation is proposed on the gate side; an exemption for
"this looks like an example" would be a hole shaped exactly like the failure the gate exists to catch.

**This record's own "no defined home yet" cost is now half-closed.** Its cost list says the
disposition-1 row *"has no defined home in this library yet"* and declines to invent a table with
nothing in it. That restraint is kept: the gate **requires no table while the retired set is empty**, and
looks for a row only once a number is missing. What is now defined is the row's **form and heading**, so
the first executor creates the table rather than designing it.

**Left open, and deliberately not decided here: whether a citation inside a struck (`~~…~~`) span must
still resolve.** This repo strikes rather than deletes, so #283's reconciliation will strike prose
containing citations of the records it removes, and slice 1's gate has no strike-awareness.

**No count of the affected sites is published, and the withdrawal is itself the finding.** An earlier
form of this paragraph said *"four struck citations exist today"* without the command that produced it,
against this repo's own rule that a measured number ships with its command or not at all. Both the
figure and the instrument were then falsified in review, and the instrument fails worse than the review
found — re-derived here rather than inherited. The Issue's line-level
`git grep -E '~~[^~]*ADR-0[0-9]{3}'` counts any line carrying a `~~` and, anywhere later on it, a
token, whether or not the token is inside the span. Run at this head it returns **five** hits, and
**exactly one** is a token inside a strike: `hooks/scripts/permission-guard.sh:961`. In the other four
the token sits **outside** the struck span — `docs/adr/README.md` lines 19, 41 and 43, and
`docs/proposals/agentic-dev-loop.md:227`, where `~~Product ownership stays human.~~` closes before
`(ADR-0002)` begins. So the command's hit count is not the population under any reading, and the four
it over-counted are not the same four the withdrawn figure named.

**A span-aware replacement was written and falsified too, which is why nothing replaces the figure.**
A multi-line `~~(.*?)~~` scan over every tracked `.md` and `.sh` was run against this tree: in
`skills/documentation-standard/SKILL.md` it reported two citations inside a span that is not a span and
**missed the file's one genuine struck block entirely**. The cause is the residual this amendment
already names one paragraph up, one level higher: that file *teaches* the strike convention, so it
writes the marker as literal prose (`` (`~~…~~`) ``, and a bare `` `~~` `` inside a sentence about a
regex), and an odd count of markers mis-pairs every span after it. Verified by counting the markers per
line rather than by inference: `grep -n -o '~~' skills/documentation-standard/SKILL.md` → lines 76 and
255 carry two each, lines 258, 285 and 292 carry one each.

**A stronger instrument was then built rather than argued about, and it HALF works — which is a narrower
claim than this paragraph carried into review.** It said *no cheap published one-liner survives that*,
and that was over-claimed. The three mis-pairing markers just enumerated — the two on line 255 and the
one on 258 — are precisely the ones the sentence above quotes as sitting **inside backtick code spans**,
so a scan that strips inline code spans and fenced blocks *before* pairing does fix that file: its
remaining four markers (76 twice, 285, 292) pair correctly, and the scan reports no citation there at
all, phantom or otherwise. It also finds **both** of the hand-verified sites named below.

**Where it still fails is a shell script, and the reason is that markdown's rules do not apply there.**
`hooks/scripts/inventory-counts.test.sh` writes the marker thirty times in prose comments quoting this
repo's own struck records — `grep -o '~~' hooks/scripts/inventory-counts.test.sh | wc -l` → **30** — and
a markdown parser has no licence to treat backticks in shell comments as code spans. The pairing there is
unsound, and the scan emits phantom citations out of it. The same instrument also flags **this record**
as suspect, for the reason the next paragraph measures.

**So the impossibility claim is withdrawn, and what replaces it is narrower and worse-shaped.** The
instrument that works on markdown is a ~50-line script, not a one-liner: it cannot be published inline
beside a figure, which is what this repo's rule requires of a measured number, and no gate would run it,
which is what this repo's rule requires before a measurement instrument is kept rather than discarded. It
was therefore discarded, and every number in this section is one a published command reproduces.
**The figure stays withdrawn not because no instrument exists, but because the instrument that exists
cannot ship beside it** — a different reason than the one published in review, and the difference is
worth more than the figure was.

**This paragraph does the same thing to this record, and both halves of what it used to say about that
were false.** It claimed this file carried an **odd** number of markers and that **every** marker here
sits inside a code span. Measured at the head that published it: **sixteen** markers — even — and two of
them were the accepted-cost bullet **this same MR struck four paragraphs up**, which is a real rendering
strikethrough and not a code span. A false, checkable claim about markers, in the paragraph whose whole
subject is a false, checkable claim about markers.

**Re-derived here, with the command, and the command's own marker counted in the total it reports:**

    grep -n -o '~~' docs/adr/0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md

**Eighteen markers**, at lines 140 (two), 175, 179, 344 (two), 353 (two), 357 (two), 362 (two), 366
(three), 368, 381 and 404. Two of the eighteen — 381 and 404 — are the commands this correction
publishes, so the total is **partly a product of correcting it.** That is the self-reference this
paragraph is about, measured now instead of asserted.

**What each of the eighteen actually does, since the earlier claim got that wrong too.** Fifteen sit
inside inline code spans and one (line 404) inside the indented code block above, so all sixteen render
as literal text. **Exactly two are bare — lines 175 and 179** — the accepted-cost bullet struck earlier
in this record, which is the file's one and only rendering strikethrough. *"Every marker here sits
inside a code span"* was false the moment that bullet was struck, in the commit that wrote both.

**What survives is the finding, and it survives intact.** A naive pairer still mis-parses this record.
Taken in document order the first seven pairs land where they should — the accepted-cost strike at
175/179 among them — and then the eighth pairs the **third marker on line 366 with the one on 368**, and
the ninth pairs **381 with 404**, producing two spans that are not spans. Neither contains an `ADR-nnnn`
token, so neither yields a phantom citation *here* — luck about this file's wording, not a property of
the instrument. Nothing about how the record **renders** changes, and no gate parses spans; what changes
is only what a future scanner would compute over this file, which was always the whole finding.

**The line numbers above are the fragile part and are named as such.** They are correct at this commit
and any edit above line 140 invalidates every one of them — which is precisely why this record's own
citation convention is *quote the clause, not the line number*, and why the numbers here are published
only because the subject genuinely is positional. Re-run the command; do not trust the list.

**What is claimed, and it is hand-verified rather than measured:** the struck citations found by either
instrument all name records that are **live**, so the question has never been forced. Two are certain
because they were read in place, and both records they name exist: `hooks/scripts/permission-guard.sh`
— span opening at line 961, citing ADR-0004 on that same line — and
`skills/agents-configuration/SKILL.md` — span opening at line 501, citing ADR-0011 two lines later at
503, which is exactly why a line-level grep cannot see it. The population is not claimed to be
complete, and whoever executes the owner's answer must enumerate it by reading rather than by running a
grep.

**One thing the review of that figure did settle, and it widens the question rather than the count:**
the struck block in `skills/documentation-standard/SKILL.md` (lines 285–292 at this head) cites a
record by **path** on line 287, not in the `ADR-nnnn` prose form — which is why neither instrument
above lists it and why the path arm is one of the five that reddens when that record is moved out of
the tree. So the open question reaches all three citation
forms slice 1 gates — relative link, repo-root path, prose token — and an answer scoped to the prose
form alone would leave two arms unaddressed.

It is the owner's question, it is being asked separately, and **nothing in this amendment presupposes
either answer**: the row form above is a positive requirement about the row and is correct whichever way
the strike question goes. If struck citations are exempted, one sentence is added there — that the row is
not the only place a retired number may appear — and nothing else in this amendment changes.

## Amended 2026-08-20 — the `proposed`-record gap is named here, not resolved

Appended rather than rewritten, per this record's own convention. Driven by
[#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283), slice S6. The 2026-08-19 amendment
above states, as part of the decision, that disposition 4 is scoped to *"a record whose decision is
still in force"* — and every fold through slice S5 used that reading. **Slice S3 already put weight on
the other reading, and this document never said so.** It absorbed record 0007 — `proposed`, not
`accepted`, at the time — into [ADR-0004](./0004-controls-and-enforcement.md), and that document's own
*"The merge precondition is a floor, not an instruction — **`proposed`, not `accepted`**
(absorbed 2026-08-20, record 0007)"* section states, in its own words, that the case matches **neither**
disposition 3 (which keeps a `proposed` record precisely because it is `proposed`) nor disposition 4 (as
worded here). It records the choice made without amending either this document or
`documentation-standard` to cover it:

> *"The disposition this fold used is not the one ADR-0020 wrote for it, and that is a finding rather
> than a liberty. […] The set of four dispositions has a gap exactly here, and the gap is not academic
> — one of the twenty records in this library sits in it. […] The owner's call, named rather than
> assumed: whether disposition 4 reads 'still in force' or 'still current — in force, or proposed and
> not withdrawn.'"*

**This amendment does not answer that question.** Slice S6 was asked to make the gap visible in the
document that owns the four dispositions, without deciding it on the owner's behalf — deciding it here
would be the same shape this repo's own reviewer discipline is instructed to be suspicious of: a fold
quietly resolving a question it was only asked to carry forward.

> **TODO (owner decision, not this slice's to make):** does disposition 4 (absorption) read *"a decision
> still in force"* — admitting only `accepted` records with no unbuilt mechanism, the reading every fold
> through S5 used and the reading this record's own wording still states — or does it read *"still
> current — in force, or `proposed` and not withdrawn"*, which would retroactively describe what S3
> already did to record 0007? Until the owner answers, record 0007's absorption stands as an exception
> applied under the existing wording, not as evidence the wording already covers it.

**Both readings leave the four dispositions themselves untouched by this amendment.** Nothing above
changes what disposition 1, 2, 3 or 4 says; it only makes the open question findable from the document a
reader consults first, rather than only discoverable inside ADR-0004's own record-0007 section.

## MADR ADRs are adopted, in two libraries, behind a light significance gate (absorbed 2026-08-20, record 0001)

**Disposition 4: record 0001's decision is still in force and is moving into the document that governs
the capability it belongs to** — in this one case, its own capability document, because record 0001 is
this library's bootstrap ADR: the decision that this practice, and this document's own disposition rules,
exist at all. Deciders: the owner (ratified); this is the bootstrap ADR. Its History row is in
[the index](./README.md).

### The decision, as it currently binds (record 0001)

**MADR-format ADRs, in two libraries (methodology here, product per consuming repo), behind a light
significance gate.** An ADR is owed only when a change crosses a significance boundary — touches
`iac/`, changes a public contract, alters a previously-recorded decision, introduces a new
dependency/tool-class, or sets a cross-cutting pattern — not for every routine change. The practice is
defined operationally in `skills/documentation-standard/SKILL.md` Part II (the successor to the
`/workflow/adr` skill this record originally named); the template is `docs/adr/template.md`. MADR is
chosen over Nygard's leaner 4-section form specifically because the *considered options and their
trade-offs* are half the value for a proof-of-engineering product — Nygard's form drops them.

### The rejected options that are still live (record 0001)

- **Nygard's leaner 4-section ADRs.** *Why not:* drops the considered-options / trade-off section, which
  is half the argument this practice exists to preserve.
- **Keep decisions in `CLAUDE.md` + memory (status quo).** *Why not:* exactly the dispersion that
  produced the drift this record was written to stop — decisions scattered across commits, config,
  memory and `.brand/`, none loadable as a discrete record by a fresh per-task context.

### Consequences still being paid (record 0001)

- **An ADR per significant decision is ongoing work**, and the significance test needs judgment —
  mitigated by both domain-holding leads applying it at intake (per record 0017's authorship split,
  the *ADR authorship is split by domain* section below) and `quality-assurance` verifying on the MR.
- **Two libraries mean a reader consults two places**, and an occasional "where does this belong?" call.
- **MADR is verbose**; a small-but-significant decision can feel over-documented.

## ADR authorship is split by domain — `tech-lead` writes product/system records, `agents-lead` writes loop/machinery records (absorbed 2026-08-20, record 0017)

**Disposition 4: record 0017's decision is still in force and is moving into the document that governs
the capability it belongs to.** Decided by the owner, directly in conversation, 2026-08-13; recorded per
this section's own bootstrapping note below. Driven by
[#223](https://github.com/tedeuxx/tadeumendonca-skills/issues/223). Its History row is in
[the index](./README.md).

### The decision, as it currently binds (record 0017)

**`tech-lead` authors ADRs for product/system-architecture decisions**, including methodology decisions
with product-architecture consequence; **`agents-lead` authors ADRs for pure loop/harness/machinery
decisions** — which is why this very document, a pure loop/documentation-practice decision, is
`agents-lead`'s to write (see the bootstrapping note below for the one time that rule was not
followed). Authorship follows whoever holds the decision, not a single default persona regardless of
domain — the coupling this record corrects. A decision that straddles both domains has no mechanical
resolution: it is named in the `Deciders` line of the record itself, co-citing both personas, mirroring
the shape record 0015's own header already used (now
[ADR-0002](./0002-roster-and-dev-loop.md)'s *`agents-lead` implements the harness it reviews (absorbed
2026-08-20, record 0015)* section).

### The rejected options that are still live (record 0017)

- **Keep `tech-lead` as sole author, fix only the routing table that cited it as the reason.** *Why
  not:* treats the symptom (a stale diagram/routing edge) without touching the cause (authorship not
  following stake) — the next `loop`-typed decision would reproduce the same pull toward `tech-lead` for
  the same reason.
- **Give every persona ADR-authoring capability for its own domain** (`product-lead`, `developer`,
  `quality-assurance` too). *Why not:* no evidence any of those three actually originate
  architecturally-significant decisions of their own that aren't already covered by `product-lead`'s
  advisory-only role or `quality-assurance`'s gate role — inventing authorship capability for a class of
  decision that doesn't exist yet.

### Consequences still being paid (record 0017)

- **A straddling decision has no mechanical resolution**, only a convention (co-citation in the
  `Deciders` line) — named explicitly rather than solved, since inventing a rule for a case that hadn't
  happened yet risked getting it wrong in the abstract.
- **Role-stacking compounds further for `agents-lead`.** It already stacks proposer/reviewer
  ([ADR-0004](./0004-controls-and-enforcement.md)) and implementer
  ([ADR-0002](./0002-roster-and-dev-loop.md)'s absorbed record 0015) on harness changes it reviews;
  authoring the justifying ADR for its own harness change adds a third role on the same object.
- **Not verified:** whether any `tadeumendonca-io` product-library ADR was ever authored by anyone but
  `tech-lead` — outside this record's read scope (a different repo); its absence doesn't weaken this
  decision, since the product library's own author convention is unaffected by it.

### Bootstrapping note (record 0017)

Under the rule this record itself establishes, it was `agents-lead`'s to write — a pure loop/machinery
decision about the harness's own authorship convention. It was instead authored directly by the owner
and the orchestrating session while the plugin was temporarily disabled for a batch of self-referential
harness changes (2026-08-13), with no `agents-lead` persona dispatched. Recorded here rather than let
pass silently: whichever persona (or, in this case, no persona) drafts a record that exercises the
authority it is granting should say so explicitly.

## Links

- [#281](https://github.com/tedeuxx/tadeumendonca-skills/issues/281) — the Issue this record executes;
  [#282](https://github.com/tedeuxx/tadeumendonca-skills/pull/282) is the implementing MR, which carries
  the standard's text and this record together.
- `skills/documentation-standard/SKILL.md` — Part II; the operative wording, under the heading
  *"A record earns its place by explaining the CURRENT codebase"*.
- Record 0001 and record 0017 — both absorbed into **this document** on 2026-08-20
  ([#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283) slice S6), so what used to be two
  outbound links are now the *MADR ADRs are adopted…* and *ADR authorship is split by domain…* sections
  above, not cross-file references.
- [ADR-0011](./0011-skills-and-preload.md), its *The `archive` disposition is a file move to
  `docs/archive/`, not a frontmatter flag (absorbed 2026-08-20, record 0016)* section — the archive
  mechanism for *skills*, rejected here for *records*, on the asymmetry stated in considered option 3.
- [ADR-0002](./0002-roster-and-dev-loop.md) — its *`README.md` is the single source of truth for the
  dev-loop narrative (absorbed 2026-08-20, record 0019)* section cites the replaced convention in its
  rejected option 3; amended by appending on 2026-08-15 rather than rewritten, per the
  convention this record leaves explicitly unchanged for live records.
