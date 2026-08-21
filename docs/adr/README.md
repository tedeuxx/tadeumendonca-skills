# Methodology ADRs

Architecture Decision Records for the **dev-loop machine** — the reusable engineering methodology this
plugin exports. Product decisions live in each consuming repo's own `docs/adr/` (e.g.
`tadeumendonca-io/docs/adr/`), not here.

Practice and template: [`/documentation-standard`](../../skills/documentation-standard/SKILL.md)
(Part II — merged from the former standalone `adr` skill at #260) · [`template.md`](./template.md).

## Capabilities

**Every record declares a `Capability` in its header, and the value must be one of the names below.**
The set is **closed** — decided once for the whole library, not derived per record — and
`hooks/scripts/inventory-counts.test.sh` reddens on a record declaring a name that is not here.
Widening it is allowed and is meant to be *visible*: a row added to this table, in the same diff as the
record that needs it, rather than a name invented in a header where nobody would see it.

**Who decided the set, stated exactly, because this line claimed more than it held.** It read *"ratified
once by the owner"*. The owner ratified the **shape** — that a capability document keeps its anchor's
number and filename — on [#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283). **The names
themselves, and this revision of them, were decided inside the loop and are not owner-ratified.** The
set is closed by the gate either way; what is *not* true is that disagreeing with a name means
disagreeing with the owner. It is reversible at the cost of one table and one field per record.

**What the field is for.** [#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283) reconciles
this library into one **capability document** per name below. The anchor keeps its number and its
filename; the other records folding into it are deleted with a `## History` row naming it as their
destination. So a record that cannot name a capability has no document to live in — which is the entry
rule, made mechanical instead of asserted.

| capability | anchor | what belongs in it | what does not |
|---|---|---|---|
| `roster-and-dev-loop` | [0002](./0002-roster-and-dev-loop.md) | Who exists in the loop and what each actor is for — the personas, the tiers, the reasons a persona exists at all, the orchestrator, and which actor may implement or gate which class of work — **and how work moves through them**: the issue types and their exclusivity, the `ready` transition, the shape a unit of work takes (Issue, child task, branch, PR), and where the loop's own canonical narrative description lives. | What must be true before a change may merge, and what artifact proves a check actually ran (`verification-and-its-artifacts`). Whether the act is permitted at all, and by what (`controls-and-enforcement`). |
| `verification-and-its-artifacts` | [0006](./0006-verification-and-its-artifacts.md) | What "done" means and what observable artifact proves a check actually ran — the Definition of Done and its criteria, the gate's two lenses, and the rule that a verdict owed to another actor is a posted artifact rather than a relayed claim. | **Who** holds the gate, and which actor may implement or gate a class of work (`roster-and-dev-loop`). **Whether** a rule is mechanically enforced rather than instructed, and what an actor is permitted to do once it has decided (`controls-and-enforcement`). |
| `controls-and-enforcement` | [0004](./0004-controls-and-enforcement.md) | Whether an act may be performed at all, and by what — the autonomy classes and the allow/ask/deny states, the committed floor and the guard hook, **which layer can carry a given control**, and the systems outside the agent's shell (a branch protection, a repository setting, pipeline-only apply) that authorise an act regardless of any agent-facing rule. | Whether a specific change is *good* — that is a check, not a control (`verification-and-its-artifacts`) — and who is making it (`roster-and-dev-loop`). |
| `skills-and-preload` | [0011](./0011-skills-and-preload.md) | What a skill is and when one earns its place, how it is described so a model reaches for it, what a persona preloads into a fresh context, and where a file goes when it stops being a skill. | Which personas exist to be preloaded into (`roster-and-dev-loop`). |
| `decision-library` | [0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md) | How this library itself works — the record format, who authors one, when a record earns its place, and how it leaves. | Any decision the records are *about* — **including where a document that is not a record lives**. This capability is the shelf, not what is on it. |
| `plugin-distribution` | [0005](./0005-plugin-auto-versions-on-merge.md) | How the harness reaches a consumer — versioning, publishing, the marketplace, and what a consumer opts into and when. | How the plugin's contents are decided (`skills-and-preload`). |

**No count is published beside this table, deliberately.** A prose count next to the table is a second
source of truth for one fact, and this repository's own gate exists because that arrangement rots. The
count is derived from the table and printed in the gate's verdict instead. This paragraph used to spell
the number out while making that argument — it read *"a prose 'seven' next to a seven-row table"* — and
the table has since lost a row, which is the demonstration rather than a counter-example.

**The set held a seventh name, `intake-and-routing`, and the argument that kept it separate was
measured false rather than merely doubted.** That row was published anchored on
record **0012** — absorbed into [0002](./0002-roster-and-dev-loop.md) on 2026-08-20, so the row it
anchored no longer names a file — and named, in this section, as the
weakest boundary in the set — separate *"because 0002 is already the largest record in the library by a
wide margin"*. Both halves of that failed:

- **The taxonomy leak below is what carries this bullet. The SIZE comparison that used to carry it was
  false, and it is corrected here rather than swapped.** ~~*"Summing each capability's records as they
  stand, `controls-and-enforcement` was already the larger of the two"* — 152,559 against 149,589.~~
  **Struck 2026-08-19 (#283, slice S2).** The roster command summed `0002 + 0013 + 0015` **only** — it
  omitted `0012`, `0014` and `0019`, the three records *the same commit* moved into that capability. So
  it compared a **pre**-fold roster against a **post**-fold controls set, which is the defect class this
  Issue has been chasing throughout: **the base moved under the figure**, and the figure kept reading as
  though it had not. Re-derived over the set that actually shipped — and **pinned to a named commit**,
  for a reason the next two lines pay for:

      wc -c docs/adr/0004*.md docs/adr/0007*.md docs/adr/0008*.md docs/adr/0018*.md   # 153725 total
      wc -c docs/adr/0002*.md docs/adr/0012*.md docs/adr/0013*.md docs/adr/0014*.md docs/adr/0015*.md docs/adr/0019*.md   # 199925 total
      # both at 448c506, and ONLY at 448c506. Run either command in a working tree at or after
      # 2026-08-20 and it does not reproduce: slice S3 DELETED 0007, 0008 and 0018 (absorbed into
      # 0004) and edited 0002 and 0004, so the first glob now matches one file and the second matches
      # six files of different sizes. Read them at the pinned commit instead:
      #   git cat-file -s 448c506:<path>            # one file, immune to any working tree
      #   git ls-tree -l 448c506 -- docs/adr/       # the whole set as it stood
      #
      # THE PARENTHETICAL THAT USED TO SIT HERE WAS FALSIFIED BY THE VERY NEXT SLICE, and it is
      # replaced rather than deleted because it is the sharpest instance in this file of the defect
      # the bullet above names. It read: "Neither set contains a file this slice edits (git diff
      # --name-only 448c506 -> 0006 and this README only), so a bare wc -c in the working tree
      # returns the same totals." True when written; false four commits later. A claim that a pinned
      # figure ALSO happens to reproduce live is a second, unpinned claim smuggled in beside a pinned
      # one — and it is the half that rots. Pin the figure and stop; do not also promise the working
      # tree agrees.

  **`roster-and-dev-loop` is 1.30× `controls-and-enforcement` and is the largest document this
  reconciliation produces** — the opposite of what the struck sentence said, and the conclusion is
  unchanged by the correction below.

  **These two figures were published wrong once, and the failure is the same one this bullet exists to
  name — its third instance, committed by the correction itself.** They read 152,611 and 199,626 until
  2026-08-20: measured at `main`, **before** this reconciliation's own edits to 0002, 0004 and 0007, and
  then published inside the commit that made those edits. **The base moved under the figure again.**
  Only the digits were wrong; the ratio moved 1.31× → 1.30× and the conclusion survived.

  **The standing rule this earns, because S3 and S4 will meet it:** a `wc -c` figure taken over files a
  slice is itself editing is stale the moment it is committed, whatever the author intends. Either pin
  it to a named commit and say which — the form above — or take the measurement **last**, after the
  slice's final edit. A live command with no ref beside it is not reproducible; it is only *currently*
  true, which is indistinguishable from wrong the next time anyone runs it.

  Note the original controls figure also did not reproduce its own then-published number (152,611, not
  152,559, a 52-byte drift); only the roster half was wrong by composition.

  **What this changes and what it does not.** It does **not** reverse the six-name call — the taxonomy
  leak in the next bullet carries that on its own, and the size argument was always the weaker of the
  two. What it changes is what this table may claim: a size objection admitting a seventh name would
  now have to admit an eighth splitting **roster**, not controls, and nobody has proposed one.
  **"By a wide margin" was also wrong at record grain** — 0002 was about 1.5× 0008, the next largest,
  not a different order — and that half of the correction stands unchanged. **Its command is dead at
  head and the tense is corrected rather than the claim:** 0008 stopped being a file on 2026-08-20, so
  the comparison is re-readable only at a pinned commit
  (`git ls-tree -l 448c506 -- docs/adr/` → 105,222 against 69,702). Left as a dated record-grain
  observation, not restated as a live one.
- **The taxonomy leaked in both directions, with named artifacts.**
  [0002](./0002-roster-and-dev-loop.md) carries a section headed *"Decision — the intake
  chain, and what each link buys"* — intake's defining mechanism, living in the roster anchor. And
  record 0012's *Corollary 3* was the decision
  that **created the `writer` persona** — the roster's newest member, decided inside the routing
  record. A boundary that neither document respects is not a boundary a reader can use. (Both are
  cited by heading rather than by line, per `documentation-standard`'s *cite the clause, not the
  line* — the same rule whose breach 94ea0fe repaired in seven places.) **Both artifacts now sit in the
  same file**, which is what the fold below settles: the leak was the argument for merging the two
  capabilities, and the merge is what removes the boundary the leak crossed.

**Folded 2026-08-20 (slice S3): 0007, 0008 and 0018 into
[0004](./0004-controls-and-enforcement.md), which is now the whole of
`controls-and-enforcement` — and it is the first capability in this batch whose real, post-fold size can
be read rather than predicted.** The inputs to it summed to **153,725 B** at `448c506`. What arrived is:

    wc -c docs/adr/0004-controls-and-enforcement.md    # measured at this slice's final commit

**That is the number to compare against 153,725, and the comparison is the only evidence this
reconciliation has produced about whether the fold shrinks anything.** It is stated as a ratio in the
PR body rather than here, because a ratio published beside its own inputs in a file the slice is still
editing is the defect the bullets above spend eight paragraphs on. **The `roster-and-dev-loop` figure
two paragraphs up remained an upper bound on INPUTS until 2026-08-20**, when S4 made it measurable the
same way — see the paragraph below.

*Two caveats on reading the controls figure as good news.* The three absorbed records carried an
unusual amount of same-day defect archaeology — a seven-row perimeter table struck and re-struck twice,
an amendment pricing a floor entry that #245 removed — so its drop rate is not a prediction for
`roster-and-dev-loop`, whose absorbed records are mostly live decisions. And **record 0007 was
`proposed`, not `accepted`**: a design nobody built compresses differently from a decision the tree is
running.

**Folded 2026-08-20 (slice S4): 0012, 0013, 0014, 0015 and 0019 into
[0002](./0002-roster-and-dev-loop.md), which is now the whole of `roster-and-dev-loop`.** All five were
`accepted` — no `proposed` record is involved, so the disposition question record 0007's absorption
raised does not arise here. The anchor was renamed to its capability in the same slice, per the owner's
#283 ruling; the number is unchanged, which is why every cross-repo citation of it survives.

**What that costs, published rather than argued away.** The inputs to the loop document summed to about
**200 KB**, and the command is written against a pinned commit because the working tree it was taken in
no longer contains five of the six files:

    git ls-tree -l 448c506 -- docs/adr/    # 0002 + 0012 + 0013 + 0014 + 0015 + 0019 = 199925 B total
    # ONLY at 448c506. Published as 199621 until 2026-08-19 (off by 5), then as 199626 until
    # 2026-08-20 — that second figure was measured before this reconciliation's own edits to 0002,
    # and is the same base-moved-under-the-figure defect the bullet above records. The bare `wc -c`
    # form published here until S4 was a live command over a glob that S4 reduced from six files to
    # one; it is replaced by the pinned form rather than re-derived.

That was an **upper bound on the inputs, not a prediction of the document** — [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)'s
disposition 4 makes the fold *lossy by instruction*, so what arrives is the decision as it currently
binds and not the archaeology. **What actually arrived is readable at head, and the ratio is stated in
S4's PR body rather than here**, for the same reason S3's was: a ratio published beside its own inputs,
in a file the slice is still editing, is the defect the bullets above spend eight paragraphs on.

    wc -c docs/adr/0002-roster-and-dev-loop.md    # measured at S4's final commit

The honest statement of the cost is unchanged: this is the longest document in the set, and its remedy
is **sections inside it**, not a second capability drawn on a line the content does not have. **Whether
a fresh context can still read it usefully is a real question and S4 measured it** — the probe, its
question and its result are in that PR body, and the answer is a finding about the capability rule
itself rather than about any one slice.

**Folded 2026-08-20 (slice S5): 0009, 0010 and 0016 into
[0011](./0011-skills-and-preload.md), which is now the whole of `skills-and-preload`.** All three were
`accepted`, so the `proposed` question record 0007 raised does not arise here either. The anchor was
renamed to its capability in the same slice, per the same #283 ruling; the number is unchanged.

**Two things specific to this fold, both worth reading before S6 runs.**

**First: an absorbed record can carry an obligation, and this one does.** Record 0010's Context item 2
was **struck with a falsification marker rather than an amendment**, and the amendment was deferred by
*two* records to each other — 0011 declined to write it from the citing side, 0010 recorded it as still
owed to itself. **The fold removes both reasons and neither closes the obligation:** there is one
document now and no citing side, but re-arguing the decision that rested on the falsified premise is
the owner's call, not a fold's. It is stated once, in the absorbed section's *The open amendment*
subsection, and named in the index rows above. **A fold is not a discharge**, and the next slice should
expect the same shape rather than treat a green suite as one.

**Second: the arithmetic inverted, and the inversion is the finding rather than a cost.** The record's
own figures — **79,261 B billed across five personas, 14.2% of the library** — were measured against a
71-file `commands/` tree. Re-derived over six personas and thirteen skills, **pinned to `1018be1`, this
slice's base**, because the slice edits two of the seven preloaded files and a live figure over them is
stale the moment it is committed:

    # per agents/*.md at 1018be1, sum `git cat-file -s <ref>:skills/<id>/SKILL.md`
    # for each entry in that brief's `skills:` list
    → 23 entries · 7 distinct files · 144,650 B distinct · 484,660 B billed across six dispatches
    git ls-tree -r -l 1018be1 -- skills | awk '{s+=$4; n+=1} END {print n, s}'   # 13 428260

**Taking it live first is how the drift was caught rather than published:** the same measurement in the
working tree mid-slice returned 144,602 / 484,372, forty-eight bytes per file lighter, because a commit
earlier in this very slice had already rewritten a path citation inside two preloaded skills. That is
the *base moved under the figure* defect, in its smallest form, inside the paragraph warning about it.

**The preloaded set is now about a third of everything the library publishes, and the bill across one
round of dispatches exceeds the entire library as it stood when the decision was taken.** That is not
six personas being greedier than five: #229/#230/#231 and #224–#227 replaced 71 small files with 13
large ones, so the same curation buys much bigger units. **Whether the trade still holds is a live
question this fold deliberately does not answer** — it is published here because a reader who finds the
old percentage in the absorbed section should meet the current one in the same sitting.

**The field assigns a record to a document; it does not promise the document is self-contained.** This
is named because the strongest objection to `verification-and-its-artifacts` is a *completeness* one,
and completeness does not resolve into a move. Reading only
[0006](./0006-verification-and-its-artifacts.md) — which since 2026-08-19 is that
whole capability, record 0003 having been absorbed into it — a reader does not learn who holds
the gate, that the merge precondition is mechanically a floor, or that a harness diff is boundary-class
absent a `harness-lead` verdict marker. All three were examined for relocation and **none of them
moves**:

- **Who holds the gate** is roster content by the table above — *which actor may implement or gate which
  class of work*. Not misfiled; a pointer, which the *what does not* column now carries in both
  directions.
- **The merge precondition stays under `controls-and-enforcement`** — record 0007 until 2026-08-20, now
  a section of [0004](./0004-controls-and-enforcement.md). What it decides is whether a rule is
  mechanically enforced or merely instructed, and that is the enforcement question, not the *done*
  question. This is the boundary a reader is most likely to cross in the wrong direction, which is why
  it is item 1 of the list below rather than quietly resolved by filing the decision where it reads more
  naturally.
- **Record 0015's Corollary 2 is verification
  *behaviour* derived from a roster *decision*, and `Capability` is single-valued** — the gate parses
  exactly one name per record and reddens on two (`hooks/scripts/inventory-counts.test.sh`, the *record
  capability* arm: *"a record belongs to exactly one"*). A record therefore cannot be split across two
  documents by declaration, and the corollary travelled with its record into
  [0002](./0002-roster-and-dev-loop.md) on 2026-08-20, where it is **Corollary 2** of the
  *`harness-lead` implements the harness it reviews (absorbed 2026-08-20, record 0015)* section.

**One thing is genuinely misplaced, and it is content rather than a record.**
[0002](./0002-roster-and-dev-loop.md) renders DoD criterion 10 across eleven lines — the
verification document's subject, inside the roster anchor. It is tolerable only because that passage
already marks itself: *"this ADR's rendering of criterion 10 is a **summary**, not the text"*, naming
`agents/quality-assurance.md` as the only place to read the operative wording. **That is the convention
the folds should follow:** a capability document may restate a neighbour's content only where it marks
the restatement as a summary and names where the operative text lives. **It is a convention and not a
gate** — nothing detects an unmarked copy, and none is proposed, because *"is this paragraph a summary
of something that lives elsewhere"* has no mechanical form. Said plainly so the next reader does not
mistake the marked case for an enforced one.

**Three boundaries in this set were a judgement call rather than a reading, and they are named here so
disagreeing with one is cheap:**

1. **`controls-and-enforcement` versus `verification-and-its-artifacts`.** *The merge precondition is a
   floor, not an instruction* reads as a statement about verification and is filed under enforcement,
   because what it decides is whether a rule is mechanically enforced rather than instructed. **The
   rename below narrowed this discomfort without removing it** — "enforcement" names the question that
   record answers, where "permissions" did not — but a reader looking for the merge precondition under
   verification still will not find it.
2. **`skills-and-preload` versus `decision-library`.** *A skill's `archive` disposition is a file move*
   is about where a retired artifact goes, which is the shape of a documentation-architecture decision;
   it is filed under skills because the artifact it governs is a skill. That is
   [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)'s own filing rule —
   a decision belongs to *"the document that governs the thing it decides"* — and it is the same rule
   that moves 0019 out of `decision-library` in the next paragraph. One rule, two answers, which is
   what makes it a rule rather than a preference.
3. **`roster-and-dev-loop` holds a record about a file.**
   Record 0019 — since 2026-08-20 the *`README.md` is the single source of truth for the dev-loop
   narrative (absorbed 2026-08-20, record 0019)* section of
   [0002](./0002-roster-and-dev-loop.md) — decides that `README.md` is
   the single source of truth for the dev-loop documentation. It was published under `decision-library`,
   against that capability's own exclusion — *the shelf, not what is on it* — since `README.md` is not
   part of this library. Applying ADR-0020's rule instead: the thing 0019 governs is the loop's
   narrative description, so it belongs to the document that governs the loop. `decision-library`'s
   *"what belongs in it"* lost the clause *"and where the canonical documentation of the loop lives"*,
   which existed only to admit this record. **The residual discomfort, stated:** the `roster` half of
   the name does not cover a decision about a file's role; the `dev-loop` half does, and that is the
   whole of why the name still holds.

**One name was doing more work than a name should, and it has been changed rather than compensated
for.** `permissions` absorbed *which layer carries a control* — record 0008 until 2026-08-20, now a
section of [0004](./0004-controls-and-enforcement.md) — and that decision's
third layer is not about agent permissions at all — it routes controls to *"a CI trigger, a cloud IAM
policy, a branch protection, a repository setting"*, none of which any allow/ask/deny entry can express.
The set now publishes **`controls-and-enforcement`**, with the autonomy classes as one instance of a
control rather than the category. Rejected: `enforcement-layers`, because *layer* is a word 0008 spends
under a deliberate discipline — the **authoritative layer** is internal to this workspace, the
**authorising system** is not — and a capability named for it would collide with that distinction on
the record that draws it. **The previous compensation is withdrawn:** the earlier text obliged the
capability document to carry the layer question as a citable named section *"or the name is wrong"*.
The name was wrong, and a citation convention is not a treatment for that. A named section is still
good practice; it is no longer the thing standing in for a correct name.

**What the new name must not absorb.** *Control* is a wide enough word to swallow a gate and a label,
so the discriminator is in the table's *what does not* column and is repeated here: a control decides
whether an act may be performed **at all, independent of whether the change is any good**. Whether the
change is good is a check, and checks are `verification-and-its-artifacts`.

## The records


| ADR | Title | Status |
|---|---|---|
| [0002](./0002-roster-and-dev-loop.md) | **Roster and dev-loop** — the capability document, **absorbing records 0012, 0013, 0014, 0015 and 0019 on 2026-08-20**. Titled *Agentic dev-loop architecture (per-task subagents, ADRs-as-brain)* until then, when the owner decided an anchor is named for its capability (#283); the number is unchanged, the filename is not | accepted · **absorbed 0012, 0013, 0014, 0015 and 0019 on 2026-08-20** (#283 slice S4 — all five `accepted`, so the `proposed`-record question record 0007 raised does not arise) · amended 2026-07-23 (`product-owner`; then `product-manager` · `analytics` · `debugger`) · **amended 2026-07-24** (amendment #3 — roster reshape: `product-owner` re-scoped, `brand-guardian`/`editor`/`recruiter`/`scrum-master`; owner-ratified, implementation sequenced per #69) · **amended 2026-07-29** (amendment #4 — the `brand-guardian` trigger is a fail-closed rule, not a path list) · **amended 2026-07-30** (amendment #5 — `product-manager` gets a trigger; the reviewer's output gets a round budget) · **amended 2026-08-01** (amendment #6 — a finding blocks only by naming a criterion and a falsifier; DoD criterion 10; the lenses self-classify severity) · **amended 2026-08-02** (amendment #7 — roster 19 → 6 on a new criterion: a persona exists only where conflict is wanted) · **amended 2026-08-02** (amendment #8 — the intake chain; both gatekeepers approve every MR in parallel; the builder delivers the E2E suite) · **amended 2026-08-04** (amendment #9 — `marketing-lead` merges into `product-lead`, roster 6 → 5; the blocking-truth clause carries across explicitly, the capability floor behind it does not) · **appended 2026-08-04** (amendment #9's accepted cost is **closed** — the remedy it pre-committed to, a tool grant, is struck in favour of an `agent_type`-keyed deny that keeps `Bash` and removes publishing; the `/architecture` obligation is booked in ADR-0004) · **appended 2026-08-04** (amendment #6 item 2's summary of criterion 10 is **superseded** — the criterion no longer passes on *"the lens returned a verdict"*; see ADR-0006's third 2026-08-04 amendment. Its second half, the reviewer's own falsifiability clause, stands) · **amended 2026-08-04** (amendment #10 — **`harness-lead` joins tier 1**, the owner's pair on the machinery: advisory, pre-implementation, gates nothing, standing rule *every scenario ships with how to verify it or is labelled a hypothesis*. **`security` is absorbed into `quality-assurance`**, which holds two lenses in one pass and labels every finding with its lens — owner's decision, reaffirmed after objection, for fewer profiles reconciling one result on the same MR. **The roster is still five and two members changed.** Four costs booked, the structural one being that **nobody now observes the gate that signs the merge**, which is why the merged persona did not inherit `Edit`. The persona criterion widens from *conflict wanted* to **four reasons**, with **reconciliation cost paid within a tier**. Amendment #9's *"both approvals are still required"* is **struck** — a record describing a control as stronger than it is. And the rule the gap leaves behind: **a count is not an identity**, since swapping one persona for another held `inventory-counts` at five and every gate stayed green. **An omission, not a policy** — the previous roster change amended four records in the same commit) · **amended 2026-08-12** (amendment #11 — Decision 1's *"advisory, pre-implementation"* clause is **struck** rather than rewritten, on the owner's reversal: `harness-lead` gains an implementer role over record 0015. The **merge** and **MR-review** clauses of Decision 1 stand verbatim and unchanged — `harness-lead` still never merges and never gates an MR; only its pre-build-only limit is reversed) |
| [0004](./0004-controls-and-enforcement.md) | **Controls and enforcement** — the capability document, **absorbing records 0007, 0008 and 0018 on 2026-08-20**. Titled *Autonomy & permission model (classes, tool-scoping)* until then, when the owner decided an anchor is named for its capability (#283); the number is unchanged, the filename is not | accepted · **amended 2026-07-25** (the agent-scoped merge gate — rule 7b — makes "only the reviewer merges" mechanically true, #77) · **amended 2026-08-02** (where mechanism belongs and where a skill carries the rule instead; the accurate `agent_type` property is *cannot claim*, not *cannot obtain* — these rules enforce **routing**, #125) · **amended 2026-08-03** (the main agent's ASK on `gh issue create` is removed — visible-by-construction versus invisible; the subagent deny is untouched) · **amended 2026-08-04** (per-persona scoping now has a **second** surface — an `agent_type`-keyed deny in the floor alongside the `tools:` frontmatter; effective capability is the grant *minus* the denials; books the obligation on `tadeumendonca-io`'s `/architecture`) · **appended 2026-08-04** (5e's orphaned consequence is closed by ADR-0006's decided relay — the *act* still has no destination, the *content* now does, and the separation the rule buys is exactly as wide as before; a persona-keyed publication deny must name the receiver of that persona's output in the same MR) · **amended 2026-08-04, second** (what each layer of the floor actually stops — the deny list holds the direct form, the hook holds the wrapped form, **neither is a sandbox**; its layering half is superseded by **record 0008**, whose decision now lives in this record's *Which layer carries a control (absorbed 2026-08-20, record 0008)* section, and **its opening decision — *"`Bash(bash:*)` and `Bash(sh:*)` stay in the committed floor"* — is superseded in place later the same day**: the owner took the interpreter class out of `allow` (`14d7b43`, `786437c`) once plain string concatenation showed a fourth patch to the unwrap regex buys a spelling and not the class. Non-containment stays accepted; `node`/`python3` stay granted, which is why removing the rest is a change to what is *free*, not to what is *contained*) |
| [0005](./0005-plugin-auto-versions-on-merge.md) | The plugin auto-versions on every merge; adoption is the consumer's opt-in | accepted · **amended 2026-08-10** (adds the *which part* axis for one case the record left to `CLAUDE.md`: **a follow-on PATCH may carry the remainder of a break whose first half already shipped under a MAJOR** — [#164](https://github.com/tedeuxx/tadeumendonca-skills/issues/164)'s split travelling on top of `1.0.0`, decided by the owner and **recorded as an interpretation**, with both readings kept and neither provable from the tree: *one contract change cut halfway* (chosen — the rename rule was **satisfied at `1.0.0`, not waived**; `7590a14` carried no content, it was an announcement) against *two separate breaks* (`#174` removed four commands, the split renames sixty-nine). **The additive escape is explicitly unavailable** — `commands/` holds 2 files, `skills/` 69, and the names change — so on the second reading this is a knowing deviation. Affordability is a **circumstance, not a rule**: the one consumer is pinned per-version in `installed_plugins.json` and a pin is a lockfile; any future appeal must re-derive the consumer set. Books the capability change the number does not carry (**`Skills (2)` → `Skills (71)`, +9,919 always-on tok/session**, relayed from #182) and weighs the **second renamed surface** — `skills:` preload identifiers go family-qualified → bare — as **fact-strengthening but part-neutral**, since its only author today is `agents/**` here and `skills-resolve.test.sh` assertion 5 reddens on the old form. **Rules on the release-note obligation:** `quality-assurance`'s proposed assertion belongs **nowhere in its proposed form** — `version-main.yml:57-91` **generates** the whole body from commit subjects with `--no-merges`, so no one authors notes, the PR title never appears, the first line is a section heading (`### 🐛 Fixes` for this branch) and the check would fire after the tag is pushed, which ADR-0004 routes to the wrong layer; a follow-up may re-specify it at **PR time on commit subjects**, not pre-approved. What keeps the obligation alive is named as weak on purpose: a post-publish `gh release edit --notes-file`, with the pull-in-the-interval cost booked. Rejected: `2.0.0` (with the cost of being wrong stated) · a MINOR (asserts a compatibility that is false — it buys signal by making the number lie) · hand-authored notes (the generator overwrites unconditionally). **The trigger decision, the auto-patch model and every original consequence stand unchanged**) |
| [0006](./0006-verification-and-its-artifacts.md) | **Verification and its artifacts** — the capability document. Titled *A verdict one persona owes another is an artifact on the PR, not a relayed claim* until 2026-08-20, when the owner decided an anchor is named for its capability (#283); the number is unchanged, the filename is not | accepted · **amended 2026-08-03** (both gatekeepers granted a scratchpad-scoped `Write`; the load-bearing `--body-file` question inside *Consequences* is closed — measured: a ~60-line verdict posted with every backtick hand-stripped) · **amended 2026-08-04** (the *closing* open question's premise is falsified by ADR-0002 amendment #9 — `marketing-lead` no longer exists and the copy lens now holds `Bash`; the hole it named survives) · **amended 2026-08-04, second** (rule 5e now stands behind the copy lens's identifier-only rule, which **prices** the third-marker question rather than settling it; flags that 5e's deny message cites this record for a relay mechanism it does not name) · **amended 2026-08-04, third** (**the closing open question is CLOSED** — a gate **may** relay another persona's verdict and, where a criterion waits on it and the floor denies that persona every route to publish, **must**; `quality-assurance` quotes the copy verdict **verbatim under its own marker** and criterion 10 upgrades from *returned* to *returned and quoted*. Accepted cost: the carrier merges, so attribution is weaker than a first-party artifact and selective quoting has no detector. The **multiplier objection survives** and is now the standing reason not to revive the third marker. Evidence: the alternative was measured at **five omissions in one session**. Relaying `security`'s approval or the owner's ratification remains forbidden) · **amended 2026-08-04, fourth** (**the gate-reads-gate verification has lost its subject** — `security` is absorbed per ADR-0002 amendment #10, so the remaining verdict is posted by the party that merges and **read by nobody**. The artifact survives and still closes *omission*; **confirmation** is gone, and *"verified"* should not be written of the remaining gate. The exclusion list loses `security`'s approval as an entry and keeps its principle — **authority versus record** — with the owner's ratification now its only member. The relay decision and the multiplier objection are untouched). **The decision itself is unchanged by all five.** |
was one of the three entries it needs**, corrected on #164: the suite resolves identifiers against the
library too, so `commands/**` (#180) and `skills/**` (#164, when the library moved there) are equally
load-bearing and a rename on the target side is what the single entry could not start the gate on. Costs: **the curation has no falsifier**, the list is **static** (no per-dispatch top-up — `developer` works a CI slice without `workflow:github-actions`), nine of the ten entries carry a family segment and get rewritten if [#164](https://github.com/tedeuxx/tadeumendonca-skills/issues/164) flattens the tree, `backend:coverage` gains a third publication under a stem that misdescribes it, and the repo now publishes **two** allocations — *whose domain* (unchecked) and *what is preloaded* (checked) — which visibly disagree, deliberately. [ADR-0002](./0002-roster-and-dev-loop.md) and record 0009 (now a section of [ADR-0011](./0011-skills-and-preload.md)) **cited, not amended** — a preload **bypasses** description-based discovery rather than correcting it |

| [0011](./0011-skills-and-preload.md) | **Skills and preload** — the capability document, **absorbing records 0009, 0010 and 0016 on 2026-08-20**, and it inherits record 0010's **open amendment** (the *"an exclusion is a real deprivation"* premise, falsified and not yet re-argued) rather than closing it. Titled *A skill exists to be assigned to a profile in the loop's roster — "to which profile is this assigned, and why?" is the operative test, and a skill assigned to nobody has no reason to exist whatever its quality; what it standardises is a behaviour, transversal, persisting across sessions* until 2026-08-20, when the owner's ruling that an anchor is named for its capability (#283) reached this one; the number is unchanged, the filename is not | accepted · **absorbed 0009, 0010 and 0016 on 2026-08-20** (#283 slice S5 — all three `accepted`, so the `proposed`-record question record 0007 raised does not arise) · **THE OPERATIVE TEST is assignment**, and it is deliberately not *is this good* / *is this generic* / *is this a standard* — **a file that cannot name a profile does not belong regardless of quality**, because *a library grew for two years against no assignment criterion and the defect stayed invisible since every individual file was defensible*. **Measured: 5 profiles, 69 skills, 7 assigned, 62 unassigned — 90%.** `developer` 3 · `quality-assurance` 3 · `tech-lead` 3 · `product-lead` 1 (`new-issue`, **a command, which must go**, leaving it empty) · `harness-lead` 0; **8 of 14 process skills assigned to nobody**, `dev-loop` among them. **One figure corrected on measurement rather than published round:** *"none of the ~55 technical files is assigned"* is **false by one** — `backend/coverage` is assigned, **to `quality-assurance`, the profile that CHECKS, not to `developer`, which builds** and carries three process skills and **zero** delivery standards; the exception is the finding, and the rounder claim would have hidden it. **Consequence for what the plugin IS: the library is the roster's equipment**, sized by what five profiles need, not by accumulated knowledge — and what cannot answer the assignment question is an **archive** (publishable, referenceable, not a skill), a named destination so the ordered review is not forced into *keep or cut*. **Prevention is stated as ABSENT:** `skills-resolve.test.sh` asserts identifiers resolve to files and **nothing asserts the reverse** — that a file is consumed by some profile — which is exactly how 62 files arrived; the closing assertion is a few lines, **would fail on 62 of 69 today**, and is deliberately **NOT decided here**, since a check arriving red on 90% of its subject is one this repo has already paid to learn gets silenced (record 0009's frontmatter-scoped consumer-path ban, now a clause of this record's own trigger-description section). *Review, then assert.* · the owner's definition quoted **unparaphrased** because each of his sentences corrected a framing that had been offered and was wrong (*norm versus knowledge* · *stack-free versus generic* · *repeated behaviour versus transversal* · *within that stack* · *centralisation is one definition, not also delivery*). **Two SUBORDINATE tests decide whether a file's CONTENT is a skill's content once a profile exists — not whether the file should exist, which only assignment decides — and each is recorded through a candidate it REJECTS**, since a criterion that only admits settles nothing: *does this change what an agent does?* rejects the accurate, generic, well-written passage that changes no behaviour — a class no measurement on #183 could see; *is it transversal?* rejects `--squash` (`grep -c squash agents/*.md` → **1 file, `quality-assurance`, the only persona that merges**), which a *repeated-behaviour* framing wrongly flagged as under-covered. **Scope is free and is NOT a quality signal** — a technical skill may anchor one stack (`vpc`), several, or none (`coverage`, `iam`); the technology in the name is the **scope of the behaviour, not the subject of the file**, so *the more a technical skill reads like documentation about the technology, the less of a skill it is*. **Generic means workload-free, not stack-free:** the project-agnostic lint is green on all 69 (re-derived → **0**) and cannot see shape — `skills/backend/lambda-handler/SKILL.md:7` reads `Module: $ARGUMENTS (e.g., "posts", "articles", "notifications")` and has **no project name to substitute**; a vocabulary grep is not the replacement (44 files hit, including `principles/dev-loop` for the verb *posts*), so **the class is a review judgement with no mechanical detector, said plainly rather than papered over with a regex**. Three surfaces separated: **command** = the owner acting, now · **brief** = the orchestrator instructing, this session · **skill** = the owner defining, every agent every session — so **a persona must never preload a command**, which `agents/product-lead.md` does today (`new-issue`), and removing it leaves that list **empty**. Association is **transversal** — no persona owns a skill — and `developer` today preloads three methodology files and **zero** delivery standards. Rejected: **duplication across the five briefs** — the incumbent, and it **was the control**, correctly, while the loader reported `Skills (2)` before [#182](https://github.com/tedeuxx/tadeumendonca-skills/pull/182) ([ADR-0005](./0005-plugin-auto-versions-on-merge.md)`:146-149`); it expired 2026-08-10 and its cost is now measured drift (**2 clauses live only in `dev-loop:475,477` and 0 in any brief — including *a change to the loop's own rules is boundary class*, absent from the one persona that classes**) at **20,777 B** re-derived · **a universal floor of all `principles/*`** (**76,059 B ×5**, re-derived at the new location; record 0010's rejection **stands**, and its stronger second reason — the gate must not acquire a ruler with no falsifier — is untouched) · **one skill per persona** (the incumbent with a different extension). Costs booked: a preload is **frozen at the session's plugin build** and centralising **does not make a rule current**; a brief that becomes a pointer stops reading as a mandate; ~~**`inventory-counts.test.sh:1410` goes red on the correct tree** if the scratch rule moves~~ (**struck 2026-08-19, #283 slice 1** — the locator was stale and the prediction was answered: the rule moved to `command-hygiene` at #225, the brief assertion was re-keyed to *"names the session scratchpad as where its working files go"*, and it did not go red), and re-keying it to the skill's text would prove existence and stop proving **reach** — the replacement must key on the **association**, and until it exists **moving a rule out weakens the check**; and **the behaviour test has never been run and has no proxy**. records 0009 and 0010 (both absorbed into this record 2026-08-20), [ADR-0004](./0004-controls-and-enforcement.md), [ADR-0005](./0005-plugin-auto-versions-on-merge.md) and [ADR-0002](./0002-roster-and-dev-loop.md) **cited, not amended** — including one **falsification carried but deliberately not written as an amendment**: record 0010's *"there is no path to read"* is false (`printenv CLAUDE_PLUGIN_ROOT` → exit 1, **and** the plugin root is derivable from `PATH`, both re-derived in the shell that wrote the record), which makes its exclusions deferrals rather than deprivations — left for that record's own amendment because `harness-lead` is mid-audit on the same clause. **Explicitly undecided:** **the outcome of the ordered review — this record supplies the criterion and the measurement and decides NO individual file** (62 decisions: assign · rewrite so a profile can be assigned · archive · cut), whether and when the reverse assertion is added, what `archive` is mechanically, whether the workload-mirroring files are rewritten or cut, how many methodology skills there should be, the `new-issue` removal, and `harness-lead`'s `skills: []` · **amended 2026-08-13** (a **fifth disposition**, scoped to the three technical families and leaving the four-way framework untouched for the 14 process files: `infrastructure` (21 files), `backend` (19, correcting a relayed `18`) and `frontend` (15) — **55 files total, not the four-way disposition per file** — each consolidate into **one skill per family**, named `cloud-infrastructure`, `backend` and `frontend`. Driver: [#177](https://github.com/tedeuxx/tadeumendonca-skills/pull/177)'s mechanical floor — no subagent has on-demand skill invocation, only forced `skills:` preload or a manual `Read` the model may or may not decide to make — so what needs **forcing into every dispatch** is the process/workflow layer (14 files, this repo's own stated differentiator), while the 55 technical files are reference-only, reached by `Read` when judged relevant, and served better as one greppable entry point per family than as 55 to first guess between. **The density bar (`vpc`, cited in `CLAUDE.md`) is not lowered by folding** — it moves from file-grain to section-grain within `cloud-infrastructure`. **Uniform curation criterion across all three** (a late refinement, incorporated rather than scoped to `backend` alone as first framed): each consolidated file keeps **the owner's own preferred pattern per concern**, already stated today at finer grain across the source files — not an exhaustive merge of every option each one discussed — using ADR-0011's own documentation-versus-standard test as the noise/signal filter, applied at paragraph grain. `backend` carries the sharpest version of the cost since it documents a **retired** architecture with no live consumer to exercise the kept pattern; `cloud-infrastructure` and `frontend` are exercised live. **Explicitly undecided:** the internal structure of `cloud-infrastructure` (organizing axis for 21 services); the per-file assignment of #192's remaining 8 process files; and whether any of the three consolidated files earns a preload slot on any profile) |

| [0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md) | **An ADR earns its place by explaining the current codebase** — the capability document, **absorbing records 0001 and 0017 on 2026-08-20**. A record leaves this library only as a disposition, ~~one of three, keyed on `status`~~ **one of four since the 2026-08-19 amendment**: the first three keyed on `status` for a *reversed* decision, the fourth for a decision still **in force** and merely relocating | accepted · **absorbed 0001 and 0017 on 2026-08-20** (#283 slice S6 — both `accepted`, so the `proposed`-record question record 0007 raised does not arise here either; this record's own 2026-08-20 amendment instead names, without resolving, the gap record 0007's absorption exposed) · replaces **supersede-never-delete**, which was never itself recorded as an ADR (no `Decision outcome` in this library; it lived in `skills/documentation-standard/SKILL.md` and this index's own closing note, and live records cited it — a set stated by its criterion and never by a count: **two** cite `supersede-never-delete` by name (ADR-0011, record 0019), **five** cite the `supersede-*` family (those two plus ADR-0002, record 0010, record 0016), all `accepted`, all line-wrapped across the hyphen). Driven by [#281](https://github.com/tedeuxx/tadeumendonca-skills/issues/281). **Which arm of the significance gate fires, corrected in the record itself:** not *alters a previously-recorded decision* (nothing was recorded) but **sets a cross-cutting pattern** — it governs both ADR libraries, prescribes `git rm` against artifacts a published `-io` page renders, and live records cite the convention it replaces. **Only record 0019's citation is about the arm this record replaces; the other four (ADR-0002's own *"the rule is supersede-never-rewrite"*, record 0010, ADR-0011, record 0016) each justify a strike inside a live record and are explicitly not to be swept.** **Chosen:** three dispositions — delete with a mandatory `README.md` History row · fold the context into the superseding record (`## What this replaced`) **before** the deletion · keep the file where the record is `proposed` or merely unexercised. Both preconditions are preconditions, not follow-ups. **Rejected:** keeping supersede-never-delete (not wrong about the risk; answers it with a marker the misreading consumer — an agent, which reads bodies not status lines — does not read) · moving retired records to `docs/archive/` as the skills-archive mechanism (record 0016, now a section of [ADR-0011](./0011-skills-and-preload.md)) does for skills (that mechanism works because a gate computes over the directory boundary; **nothing keys on the `docs/adr/` boundary**, so moving a record out of it changes no gate's outcome — machinery does read the directory (`inventory-counts.test.sh` greps `docs/adr/0008` by path, `docs-test.yml` filters on `docs/**`), which makes the why-not stronger: an archived record is still scanned by the floor-claim assertion, so the move buys the appearance of the remedy and not the remedy) · building a gate now (deferred on evidence — the deletion set in this library is **empty**: **19 records before this one** / 18 accepted / 1 proposed / **0 superseded**, and 20 / 19 / 1 / 0 once it lands, measured at `2de6844` with `ls docs/adr/0*.md | wc -l` and `grep -ih "^- \*\*Status:\*\*" docs/adr/0*.md` — the figure the deferral rests on is the last one, zero superseded). **Scope boundaries that are part of the decision:** whole records only — inside a live record, append-and-strike is **unchanged and load-bearing** (`inventory-counts.test.sh`'s roster-membership assertion reads those markers, and stripping them was measured to make it *quieter*, not red) — and *reversed* decisions only, never unbuilt or unexercised ones. **Accepted costs:** the reasoning of a reversal is no longer preserved at length · ~~**nothing enforces any of it** (a record deleted from a scratch copy of this tree left the suite at `69 passed, 0 failed`)~~ — **struck by the 2026-08-19 amendment below; true when written, and true only while the deletion set was empty** · the first real execution is `-io`'s library, where `AdrTable.test.tsx`'s `inLibrary > 5` assertion reddens against 8 superseded-by-status records, and `architecture.{en,pt}.md` states the old rationale as published copy — `product-lead`'s blocking call, not settled here · **three further `-io` costs the record now names so its list is the whole executor brief**: `-io`'s own `docs/adr/README.md` still publishes *"never deleted"* (it shares no vocabulary with `supersede-never-delete`, so every sweep missed it), disposition 1's designated home there is a History table whose heading asserts the rule it replaces and whose every row links a live file, and `architecture.{en,pt}.md` hard-links five superseded records by URL — in the table under *"O que foi cortado — e tinha sido construído antes, que é a parte que importa"*, serving the argument in the *"Se você precisar do backend de volta"* subsection below it, which cites the five by bare number and depends on them being readable · disposition 1's History table does not exist in this library yet, left open deliberately since the deletion set here is empty · **amended 2026-08-19** ([#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283), slice 2) — **a fourth disposition, ABSORPTION**, for a record whose decision is still **in force** and is moving into the document that governs what it decided. Dispositions 1–3 are keyed on a reversal at every joint, so applied literally to a live record they produce **false** artifacts (`## What this replaced` heads a section nothing replaced; the row asserts a supersession that did not happen). **Its preconditions are stricter, not looser** — the History row is mandatory **and so is a destination link**, and the fold is **unconditional** because absorption has a target by construction: **no destination, no deletion**. **The fold is lossy by instruction** (the decision as it binds, the still-live rejected options, the consequences still paid; superseded narrative and defect archaeology dropped) — unsaid, "absorb" reads as "append" against records averaging **28 KB** (572,390 B over 20 at `c52aa4f`, command in the record). **Considered option 4's deferral is discharged**, its stated premise (*"the deletion set is empty"*) being exactly what #283 removes: `inventory-counts.test.sh` now asserts every issued number is a live record or a History row naming a destination, in both directions, against a **declared ceiling** rather than the highest surviving file — because a derived maximum cannot see a deletion at the **top** of the sequence. Row form is the **bare** number (`0008`), never with an `ADR-` prefix, since the prose citation arm asserts every `ADR-nnnn` names a live record and does not except this table — which also means that arm cannot tell a citation from a *discussion of the citation form*, so documents teaching the rule use the `nnnn` placeholder. **What it still does not hold:** the destination's *content* — visible and attributable, not proven lossless. **Left open, not decided:** whether a citation inside a struck (`~~…~~`) span must still resolve. Records 0001 and 0017 — both absorbed into this document on 2026-08-20 — are now this record's own *MADR ADRs are adopted, in two libraries, behind a light significance gate* and *ADR authorship is split by domain* sections; the authorship split those sections describe is why this is `harness-lead`'s record to write |

New ADRs: copy `template.md` → `NNNN-kebab-title.md`, next number in sequence. ~~Never delete a superseded
ADR — mark it `superseded by ADR-XXXX` and link forward.~~ **Struck 2026-08-15 (#281).** The disposition
of a reversed decision is now one of three, keyed on the record's `status` field and never on its
filename — delete with a mandatory History row, fold the context into the superseding record first, or
keep the file — per [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md) and
the operative wording in `skills/documentation-standard/SKILL.md`. **A fourth disposition was added
2026-08-19 (#283) for a record that is not reversed at all: absorption**, where a decision still in
force moves into the document that governs it. It is the only disposition whose History row must carry
a **destination** — no destination, no deletion — and it is the one this library's own reconciliation
runs on. **This applies to whole
records only**: inside a live record, amend by appending and strike in place, never rewrite — unchanged.

## History

**A record leaves this library only as a disposition, never as an absence.** Every number this library
has issued is either a live record in the table above or a row here, and
`hooks/scripts/inventory-counts.test.sh` asserts that **in both directions** — a missing number with no
row reddens, and a row for a number that is still live reddens too — against a declared ceiling rather
than the highest surviving file, because a deletion at the *top* of the sequence leaves no gap to find.

**The number is written bare, never with an `ADR-` prefix**, and that is mechanical rather than
stylistic: the same gate's prose arm asserts every `ADR-nnnn` token in a tracked file names a **live**
record, and it does not except this table. A prefixed row would name a dead record in exactly the form a
reader — or an agent — would follow.

**What the gate cannot check, so that this table's green is not over-read — and it is a SMALLER
residual than this paragraph claimed until 2026-08-20:** the destination's **existence** *is* gated.
Point a row's destination at a file that does not exist and the citation-resolution arm reddens —
**`69 passed, 1 failed`, re-performed at S5's head rather than inherited.** The mutation is one
edit and restores itself:

    # in docs/adr/README.md, ONE History row: change its destination link's target
    # filename to one that does not exist, leaving the link syntax intact.
    bash hooks/scripts/inventory-counts.test.sh    # FAIL citation resolution … ; 69 passed, 1 failed
    # Written as a description rather than a literal before/after pair, and that is the
    # SECOND thing this mutation teaches: the citation arm scans markdown links in every
    # tracked .md file and does not know an indented code block from prose, so spelling
    # the mutated link out here reddens the very arm the paragraph is describing.

**The figure published here until 2026-08-20 was `67 passed, 1 failed`, and it was stale on arrival** —
taken at S3 *before* arm 4c landed in the same commit, so the suite it described was one arm smaller
than the suite that shipped. It is corrected rather than struck because the residual it illustrates is
unchanged; only the tally moved, and a tally is exactly the kind of figure this file's own rule says to
take **last**. **It moved once more at S5** — 68 → 69 — for the same reason and in the same shape: that
slice added arm 4d, so the tally beside an unchanged residual drifted by one again. **Two slices in a
row is not a coincidence, it is the property of the figure**: any slice that adds an arm stales it, and
nothing reads it, so the only thing that keeps it true is a slice choosing to re-perform the mutation. What is genuinely unchecked is the destination's **content**: a row
pointing at a document that never received the decision passes exactly like one pointing at a document
that did. Whether the fold was **lossless** is a reviewer's judgement and there is no instrument for it.
~~it never opens the destination~~ — struck because it **understated** the gate, which is the direction
that matters: a residual published wider than it is teaches a reader to distrust a check that works.

| # | what it decided | where the decision lives now |
|---|---|---|
| 0003 | The Merge Request Definition of Done — the pacted, objective ruler the gate reviews against; its safe/boundary classification of who may merge; the three pacted resolutions (significance beats in-pattern, coverage ≥ 85%, the approval hook); and the rule that adjacent debt is named in a review and never filed | [0006](./0006-verification-and-its-artifacts.md) — section *The Merge Request Definition of Done (absorbed 2026-08-19, record 0003)*. Absorbed under [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)'s fourth disposition on [#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283), slice S2 |
| 0007 | The merge precondition is a floor, not an instruction — at the time of absorption a **`proposed`, unimplemented** `PreToolUse` hook on `gh pr merge` that denies unless the gatekeeper's marker parses at the current `headRefOid`, with an `OWNER`-only author filter, a four-row cannot-answer table (missing tool → deny; negative → deny; unanswerable and outsider-proof → ask; everything else → deny), and the ordering conjunction that keeps the tool row reachable. **A narrower version of this design was implemented 2026-08-20** — see the destination section's own "What actually shipped" subsection for exactly which rows it covers and which it does not | [0004](./0004-controls-and-enforcement.md) — section *The merge precondition is a floor, not an instruction — **`accepted`** (absorbed 2026-08-20, record 0007; a narrower version implemented 2026-08-20)*. Absorbed under [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)'s fourth disposition on [#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283), slice S3. **The disposition does not literally cover a `proposed` record** — see the note at the head of that section |
| 0008 | Which layer carries a control — the hook is **authoritative**, the settings `deny` list is the floor for the **direct form**, and the authoritative layer **fails open**; the four routing reasons (wrapped · composed · semantic · shadowed by an `allow`); the retained-floor-entry bound and the born-in-hook set it does not cover; *record the derivation, not the count*; **closed** is not a word a pattern-over-a-grammar control may use about itself; and the third layer — ask which **system** authorises the act | [0004](./0004-controls-and-enforcement.md) — section *Which layer carries a control (absorbed 2026-08-20, record 0008)*. Absorbed under [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)'s fourth disposition on [#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283), slice S3. It **superseded** the layering claim in 0004's own second 2026-08-04 amendment, so the supersession is now internal to one document |
| 0009 | A skill's `description` is a **trigger, not a title** — the canonical `<act> <object> <where>` / `Use when` / `Not for … (see X)` form, its seven constraints, the cluster rule that makes disambiguation a property of the set, and an enforcement boundary that gates shape and **refuses any quality score**, because every available score passes on the keyword salad the standard exists to prevent | [0011](./0011-skills-and-preload.md) — section *A skill's `description` is a trigger, not a title (absorbed 2026-08-20, record 0009)*. Absorbed under [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)'s fourth disposition on [#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283), slice S5 |
| 0010 | A persona's startup context is a **curated preload** — the `skills:` list is the complete set of library files that persona can reach, each brief argues its exclusions, an explicit empty list is a decision where an absent key is a dropped one, and the identifier check lives in CI because every wrong spelling fails at **0 bytes of stderr** and the runtime has no way to report it. Carries an **open amendment**: its *"an exclusion is a real deprivation"* premise was falsified in 2026-08 and the decision has not been re-argued | [0011](./0011-skills-and-preload.md) — section *A persona's startup context is a curated preload (absorbed 2026-08-20, record 0010)*, whose *The open amendment* subsection is where that obligation now lives. Absorbed under [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)'s fourth disposition on [#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283), slice S5 |
| 0012 | Issue type is the **routing** axis and is exclusive — `product` / `content` / `loop`, one Issue one type; the `(product OR loop) AND ready` queue predicate that is what makes `loop` pass the *something must query it* test; and the measured 15%-against-75% close rate that forced a mechanical builder for `content`, which is the decision that created the `writer` persona | [0002](./0002-roster-and-dev-loop.md) — section *Issue type is the routing axis, and it is exclusive (absorbed 2026-08-20, record 0012)*. Absorbed under [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)'s fourth disposition on [#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283), slice S4 |
| 0013 | The orchestrator is a named **role**, not a persona — one term converging five live spellings, the duty list (dispatch, commit/push, the `ready` label, the routing label, the dispatch-omission judgment), and a boundary stated in two honest parts: mechanically enforced for merge and trunk push, not enforced for label application or for an omission nobody can see happened | [0002](./0002-roster-and-dev-loop.md) — section *The orchestrator is a named role, not a persona (absorbed 2026-08-20, record 0013)*. Absorbed under [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)'s fourth disposition on [#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283), slice S4 |
| 0014 | A task is an Issue **child** — own Issue, own branch, own PR, `Parent: #N` in the body; it inherits the parent's routing type and `ready` and carries no label of its own; and it ships **restrictive**, without the sibling-file overlap exemption, with the one non-negotiable fixture shape any rebuild must use | [0002](./0002-roster-and-dev-loop.md) — section *A task is an Issue child, not a checkbox (absorbed 2026-08-20, record 0014)*. Absorbed under [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)'s fourth disposition on [#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283), slice S4 |
| 0015 | `harness-lead` implements the harness it reviews — unscoped `Write, Edit` mitigated purely by *cannot merge*, and six corollaries: no new hook layer, the harness-diff criterion that makes such a diff boundary class absent a verdict marker, the durable verdict marker against a commit SHA, **owner-only `loop`-typed `ready`**, harness proposals as real `loop` Issues, and the two brief bugs that travel with the grant | [0002](./0002-roster-and-dev-loop.md) — section *`harness-lead` implements the harness it reviews (absorbed 2026-08-20, record 0015)*. Absorbed under [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)'s fourth disposition on [#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283), slice S4 |
| 0016 | A skill's `archive` disposition is a **file move to `docs/archive/<family>/<name>.md`** plus removal from `plugin.json`'s `skills` array — not a frontmatter flag left inside `skills/`, because a directory boundary is what makes the reverse assertion (*every `SKILL.md` under `skills/` is declared*) writable with no growing per-file carve-out | [0011](./0011-skills-and-preload.md) — section *The `archive` disposition is a file move to `docs/archive/`, not a frontmatter flag (absorbed 2026-08-20, record 0016)*. Absorbed under [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)'s fourth disposition on [#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283), slice S5 |
| 0018 | A permission entry is `deny` / `ask` / `allow` — **absent is not a fourth state**, it is the omission of a decision, so "let this one case through" has to resolve to an actual `allow` or stay `deny`; plus the dated falsification of `permissions.ask`, which did not intercept a live tool call in the version tested | [0004](./0004-controls-and-enforcement.md) — section *Permission entries have three states, and absent is not one (absorbed 2026-08-20, record 0018)*. Absorbed under [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)'s fourth disposition on [#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283), slice S3 |
| 0019 | `README.md` is the single source of truth for the dev-loop narrative — `docs/dev-loop-design.md` is retired to a pointer stub rather than deleted, because its canonical URL is quoted as the citable import target; and the rule underneath it, that two documents claiming the same authority at similar depth is worse than one document at full depth | [0002](./0002-roster-and-dev-loop.md) — section *`README.md` is the single source of truth for the dev-loop narrative (absorbed 2026-08-20, record 0019)*. Absorbed under [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)'s fourth disposition on [#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283), slice S4 |
| 0001 | Adopt MADR Architecture Decision Records — this library's own bootstrap ADR: MADR-format ADRs, in two libraries (methodology here, product per consuming repo), behind a light significance gate | [0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md) — section *MADR ADRs are adopted, in two libraries, behind a light significance gate (absorbed 2026-08-20, record 0001)*. Absorbed under [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)'s fourth disposition on [#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283), slice S6 — the one case in this table where the anchor and the destination are the same document, since record 0001 is the practice's own bootstrap decision |
| 0017 | ADR authorship is split by domain — `tech-lead` writes product/system records, `harness-lead` writes loop/machinery records | [0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md) — section *ADR authorship is split by domain — `tech-lead` writes product/system records, `harness-lead` writes loop/machinery records (absorbed 2026-08-20, record 0017)*. Absorbed under [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)'s fourth disposition on [#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283), slice S6 |
