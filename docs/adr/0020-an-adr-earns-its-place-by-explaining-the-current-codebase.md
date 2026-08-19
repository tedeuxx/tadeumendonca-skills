# 0020. An ADR earns its place by explaining the **current** codebase

- **Status:** accepted
- **Date:** 2026-08-15
- **Deciders:** the owner (decision); written by `harness-lead` per
  [ADR-0017](./0017-adr-authorship-is-split-by-domain-not-tech-lead-exclusive.md) — a pure
  loop/documentation-practice decision with no product-architecture consequence
- **Supersedes / superseded by:** — . It supersedes no record. The rule it replaces,
  *supersede-never-delete*, was **never recorded as an ADR** in this library: it had no
  `Decision outcome` anywhere in `docs/adr/`, living instead in
  `skills/documentation-standard/SKILL.md` (Part II) and in the index prose of this library's
  own `README.md`, and being **cited as settled** by live records. **That set is stated by its
  criterion, never by a count** — the two readings give different sets and both are needed:
  - **Citing `supersede-never-delete` by name: two.** ADR-0019's rejected option 3, *"this repo's own
    convention (supersede-never-delete) already answers the question"*, and ADR-0011's *"Struck rather
    than deleted, per this repo's supersede-never-delete convention"*.
  - **Citing the `supersede-*` family: five.** Those two, plus ADR-0010's *"Struck rather than deleted,
    per this practice's supersede-never-rewrite rule"*, ADR-0002's *"the rule is
    supersede-never-rewrite"* and ADR-0016's *"ADR-0011's own supersede-not-rewrite rule"*. All five
    records are `accepted`.

  Only **one** citation anywhere in that family is about the arm this record replaces — ADR-0019's,
  which is an argument against `git rm`-ing a **whole file**. **The other four — ADR-0002's,
  ADR-0010's, ADR-0011's and ADR-0016's — each justify a strike inside a live record**, which this
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
  answer *"was this ever decided?"* — otherwise the change is indistinguishable from the drift ADR-0001
  was adopted to stop.
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

3. **Move the retired record to `docs/archive/`, as [ADR-0016](./0016-archive-is-docs-archive-not-a-skills-flag.md)
   does for skills, rather than deleting it.** *Why not:* ADR-0016's mechanism works because something
   **computes over the directory boundary** — `inventory-counts.test.sh` scans `skills/` and an archived
   file is outside it, so the move changes behaviour. **Nothing keys on the `docs/adr/` boundary**, so
   moving a record out of it changes no gate's outcome. Machinery does read the directory — the same
   suite greps two literal strings out of `docs/adr/0008-which-layer-carries-a-control.md` **by path**,
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
  mv docs/adr/0002-agentic-dev-loop-architecture.md <elsewhere>
  bash hooks/scripts/inventory-counts.test.sh        →  58 passed, 5 failed
  ```

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

**Why it keys on a declared ceiling rather than the highest surviving record — the ADR-0008 question,
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
regex), and an odd count of markers mis-pairs every span after it. A file that discusses the notation
cannot be parsed for the notation, and no cheap published one-liner survives that. Verified by counting
the markers per line rather than by inference: `grep -n -o '~~' skills/documentation-standard/SKILL.md`
→ lines 76 and 255 carry two each, lines 258, 285 and 292 carry one each.

**This paragraph does the same thing to this record, and it is named rather than avoided.** Quoting the
instrument requires writing the marker, so this file now carries an odd number of markers too. It
changes nothing about how the record **renders** — every marker here sits inside a code span, so no
strikethrough opens — and it changes nothing about any gate, since none of them parses spans. It
changes only what a future naive scanner would compute over this file, which is the whole finding.

**What is claimed, and it is hand-verified rather than measured:** the struck citations found by either
instrument all name records that are **live**, so the question has never been forced. Two are certain
because they were read in place, and both records they name exist: `hooks/scripts/permission-guard.sh`
— span opening at line 961, citing ADR-0004 on that same line — and
`skills/harness-engineering/SKILL.md` — span opening at line 501, citing ADR-0011 two lines later at
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

## Links

- [#281](https://github.com/tedeuxx/tadeumendonca-skills/issues/281) — the Issue this record executes;
  [#282](https://github.com/tedeuxx/tadeumendonca-skills/pull/282) is the implementing MR, which carries
  the standard's text and this record together.
- `skills/documentation-standard/SKILL.md` — Part II; the operative wording, under the heading
  *"A record earns its place by explaining the CURRENT codebase"*.
- [ADR-0001](./0001-adopt-madr-adrs.md) — adopts the practice this record amends the disposition half of;
  ADR-0001 records MADR, the two libraries and the light significance gate, and is **not** where
  supersede-never-delete was decided.
- [ADR-0016](./0016-archive-is-docs-archive-not-a-skills-flag.md) — the archive mechanism for *skills*,
  rejected here for *records*, on the asymmetry stated in considered option 3.
- [ADR-0017](./0017-adr-authorship-is-split-by-domain-not-tech-lead-exclusive.md) — the authorship split
  under which this is `harness-lead`'s record to write.
- [ADR-0019](./0019-readme-is-the-single-source-of-truth-for-the-dev-loop.md) — cites the replaced
  convention in its rejected option 3; amended by appending on 2026-08-15 rather than rewritten, per the
  convention this record leaves explicitly unchanged for live records.
