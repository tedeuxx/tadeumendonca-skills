# 0021. The blueprint registry is authored, and generation verifies it

- **Capability:** harness-blueprint
- **Status:** accepted
- **Date:** 2026-08-24
- **Deciders:** the owner (decision) · written by `agents-lead` per the domain split — this is a pure loop/machinery decision · the consumer interest in `tadeumendonca-io` is co-cited below and did not decide it
- **Driven by:** [#313](https://github.com/tedeuxx/tadeumendonca-skills/issues/313)

## Context & problem

`/blueprint` is to export a portable description of this harness — every element and the purpose of
each mechanism — in a format symmetric enough that a *foreign* harness could produce one and have it
read here. That makes the format an **interchange protocol**, not a report, and it forces two questions
that the Issue as filed did not separate.

**First: what is a row?** The Issue's slice 1 proposed a `purpose:` frontmatter field on every hook,
persona, skill and command, gated in both directions. That answers *what is this FILE for*. It cannot
answer what the blueprint needs, because the thing a foreign reader must be able to evaluate is a
**desired behaviour**, and a behaviour is not a property of one file:

- *the actor that orchestrates may not perform the irreversible act* is **two rules of one file**, and
  neither rule is a file;
- *nothing is worked outside the tracker* is carried by **no file at all** — it is two guard rules, a
  label vocabulary, an intake command and several briefs;
- *one demand is closed by two leads that disagree* is **two files at once**.

A per-file field produces a file inventory with glosses. That is a real want with a real record behind
it — `tadeumendonca-io`'s manifest publishes 17-plus rows of **identity and zero purposes**, and that
repo's own **ADR-0043** deferred the purpose schema to here rather than rejecting it, in its own words
(*"tadeumendonca-io"* is the consumer speaking, and *"that repo"* in the quote is this one):

> Adding a description schema to the plugin so the gloss could be derived was considered and **deferred**,
> not rejected: a hook's one-line purpose is a methodology fact and would sit legitimately in that repo.
> It is deferred because introducing a schema there to serve one consumer's page is option 2's inversion in
> a milder form, and because the drift it would close is small next to the drift this closes.

But it is a **different consumer with a different need**, and making the blueprint wait on it would be
waiting on a sweep the blueprint does not use.

**Second: who produces the table?** The owner's constraint is that the artifact be *immutable enough to
be effective* — a row must stay citable across versions and across harnesses. Generation from the tree
pulls the other way: a generator that can **assign** an id can **reassign** one, and that is the whole
failure. Meanwhile the drift measured while #313 was being designed shows why identity cannot simply be
trusted either: the consuming repo's component count read **17**, then **18**, then **red**, inside one
day — three values for one figure, in the repo that at least *has* a drift check.

## Decision drivers

- A row must be evaluable by a reader on a harness nobody here has measured. That rules out keying the
  spine on this harness's own mechanism names.
- An id must survive a rename and a consolidation, or a citation silently re-points instead of breaking.
  This workspace has already paid for that once, in a cloud trust policy pinned to a plain name.
- The content that carries the value — purpose, and what a mechanism does **not** do — is unfalsifiable
  by any instrument in this repository. That has to be stated, or a green will be read as verification.
- Nothing may become a second source of truth for a fact the tree already holds.

## Considered options

1. **Registry authored; generation verifies it in both directions.** *(Chosen.)*
2. **Registry generated from the tree**, with ids derived from `<tipo>/<nome>` or from a manifest id.
3. **Per-file `purpose:` frontmatter**, as filed — the blueprint rendered from the file inventory.
4. **No registry: keep the existing prose section** in `README.md` (the *Essential / Incidental /
   Known-weak* list) and render the blueprint from it.

## Decision outcome

**Option 1.** The registry is one authored, tracked file — `docs/blueprint-registry.md` — and it **is**
the artifact. Generation never writes it; a gate arm in `hooks/scripts/inventory-counts.test.sh` checks,
in both directions, that the registry and the tree still agree. That is not a new mechanism: it is the
shape this repository already asserts for the plugin's declared skills array, and the numbering half is
the shape the decision library already runs — numbers checked against a **declared ceiling** rather than
the highest surviving row, precisely so an abandonment at the top of the sequence leaves no gap to find.

**Ids are zero-padded numeric, assigned once, never reused, never re-sorted.** A rename changes `nome`;
a consolidation changes `carrier`; neither changes `id`. Only an **abandoned** obligation is tombstoned,
with a History row. The alternative — a name-keyed id — was the author's own first instinct and is
exactly wrong under this thesis: a name-keyed id keys on *our carrier*, where the id must name *a
behaviour*, so that a consuming project can say **"we implement 0003 differently"** across versions and
across harnesses.

**`tipo` is a closed set of five and throws:** `refusal · review · record · knowledge · routing`. It is
the behaviour-level generalisation of the enforcement axis the consuming repo's manifest already uses,
and it is closed for the same reason that one is: a free-text field refuses nothing.

**The skills list is a VIEW over this registry** (`tipo == knowledge`), rendered under its own heading,
never a second table. It is ~16 rows over 14 carriers, not 14: two skills declare **two bodies of
knowledge** in their own headers, and the limits column is what forces the split — two limits that could
not be pasted under one another are two rows. **The row count is deliberately not gated against the
library's file count**: it would be green today by coincidence and would push the next author to merge
two limits into one cell.

**The skill↔persona association is derived at export time from persona frontmatter and is never
stored** — not here, not in the consuming repo's manifest, not in prose. It carries a **mode**
(`injected` | `discoverable`), not just a pairing, because the pairing alone names a mechanism of one
harness while the mode is the harness-agnostic question: *is this knowledge placed in the actor by
construction, or must the actor find it?* Measured at the time of the decision: **8 of 14 injected, 6
reachable only through their trigger description.** The association references a row's **id**, never its
`nome`. **It is not implemented in this slice** — see *Consequences*.

### Why not the others

**Option 2** fails on the immutability constraint and on nothing else: everything else about it is
attractive, which is what makes it dangerous. A generator that assigns ids reassigns them on a
consolidation — and this library has consolidated 69 files into 14 in three slices, which under a
file-keyed registry is ~55 tombstones for obligations that **never went away**. Under a behaviour-keyed
registry the same event is zero rows: when 21 files became one skill, the twenty-one bodies of knowledge
did not merge, they became sections.

**Option 3** is not wrong; it is a different artifact. It is decoupled rather than rejected — it still
serves the consuming repo's deferred gloss, on its own merits, in its own Issue.

**Option 4** was rejected on measurement, not taste. The prose section it would render from is ungated,
and one of its bullets was **false at head** when this was designed — it stated that the gate's own
verdict is read by nobody, which stopped being true when the end-of-turn hook landed. Keying an
interchange format on ungated prose exports a wrong claim with a currency header on it. That section is
**replaced** by this registry rather than kept beside it; duplication is this repository's measured
failure mode. *(The replacement edit is not in this slice — see* Consequences *.)*

## Consequences

### Good

- The blueprint's spine is keyed on something a foreign harness can answer about itself, and the limits
  column — the most transferable cell in a row — ports even where the mechanism does not.
- A consolidation, a rename and an abandonment are three visibly different events. A file-keyed registry
  cannot tell the first two apart from the third.
- `absent` is expressible as a **value** rather than as silence, one level up as well as one level down:
  the registry declares, per element class, whether it claims completeness — and a class declared
  `partial` with nothing left unclaimed **reddens**, so an under-claiming declaration cannot go stale
  quietly either.

### Bad, and accepted

- **`propósito` is unfalsifiable, and so is the reasoning inside `o que faz`.** No instrument here can
  tell a true purpose from a plausible one, or a complete limit from a well-written one. A row whose
  reasoning went stale months ago passes every check. This is the same residual the documentation
  standard already states about an absorption fold, and it is written into the registry's own body,
  above the rows, so that a reader meets it before meeting a green.
- **Exactly one half is gateable: the `citação` field**, which quotes the carrier's own words about its
  own limit and is asserted to appear verbatim in that carrier. A quote is greppable; a paraphrase is
  not. The gate does **not** assert that the quote is the *relevant* limit.
- **The three content columns are 100% authored, zero generated.** This is an elicitation pass of the
  same class as one deep-dive per skill. It does not complete in one sitting, and it did not: the
  `skill` class ships **declared partial**, with six carriers unclaimed and named.
- **The strain in the closed set is real and is not resolved here.** Two rows describe **builders**, and
  the five values hold no `build` class; they are filed `routing` on the reading that a builder is a
  *who acts next* carrier for a routing type. That is true and it is not the whole truth. The set is not
  reopened on two rows — a sixth value should be argued on more evidence than the first two cases that
  rubbed against it, and `absent`-style silence about the strain would be worse than filing it visibly.
- **Two things this decision settles are deliberately not built in the same slice**: the derived
  skill↔persona association, and the replacement of the prose section in `README.md`. Both are stated
  here as decided, which means a reader of this record can find them owed. The cost is that a decided
  thing sits unbuilt, and that is preferred to a slice large enough that its own review cannot hold it.
- **`/blueprint` the command is not built here.** The registry is the artifact; the command is a
  projection over it, and it reddens two arms of the inventory suite (the root-command count, and the
  argument-hint allow list, asserted in both directions) plus one manifest row in the consuming repo.
  Those edits belong with the command, not with the thing it projects.

## Amendment, 2026-08-24 — the README claim contract, and the class that is EXECUTED

**Driven by [#324](https://github.com/tedeuxx/tadeumendonca-skills/issues/324). Decided by the owner,
who ratified the direction and left the mechanism to `agents-lead`; written by `agents-lead` under the
same domain split as the record above.** It belongs to this capability rather than to
`verification-and-its-artifacts` because its subject is **how this harness describes itself to a reader
who does not run it** — the same object the registry has, one surface out: the README is the
description a forker actually meets.

**What was offered first, and why it was refuted before it was built.** The proposal was that the
README has two halves — *inventory*, projected from `docs/blueprint-registry.md`, and *argument*, left
authored. Measured, that split would have caught **none** of the three drift examples that justified
the work: all three sat in the authored half, none was a numeric count, and
`grep -c 'subagent personas\|14 skills' docs/blueprint-registry.md` → `0` says the registry does not
hold the figures the README publishes anyway. Routing the README's counts through an authored
intermediary would have been **worse than the status quo**, since the existing arms compare README
against the **tree**.

**The decision.** The defect class is **a claim published with no falsifier beside it**, not a number
that disagrees with a directory listing. A README section may carry
`<!-- claim id=NNNN class=CLASS -->`, and `docs/readme-claims.md` carries what would falsify it, in one
of **four** classes:

| class | falsifier | what the gate does |
|---|---|---|
| `DERIVED` | an existing arm of `inventory-counts.test.sh` | asserts the named arm exists as a **two-sided** assertion |
| `VERIFIED` | a local, deterministic command plus its expected output | **runs it and compares** |
| `MEASURED` | a command CI cannot run — network, or a foreign machine | shape only: a date and a fenced command |
| `JUDGEMENT` | none, declared | refuses an entry that ships a falsifier anyway |

**`VERIFIED` is the part that needed deciding, because running a command that came out of a markdown
file is executing shell in CI.** Three containments, all gated rather than described: the command lives
in `docs/readme-claims.md` and **never** in `README.md`, so an edit to the front door cannot introduce
one; a **closed allow-list of pipeline-stage heads**, ~~which deliberately excludes `awk` and `sed`
because a head-only allow-list containing a general-purpose language contains nothing~~ **— struck
2026-08-24, see the amendment below: that criterion is too weak, and it is the one that admitted two
heads that write files** — and a
**character allow-list**, so substitution, redirection and chaining are unreachable rather than
forbidden one at a time.

**`VERIFIED` and `MEASURED` split on where the command can run, never on how important the claim is.**
A network command would redden on an API outage, and a red that fires for reasons unrelated to the
claim teaches everyone to ignore red — which costs more than the claim was worth.

### Consequences — bad, and accepted

- **It binds a command to a NUMBER, never a number to a SENTENCE.** Nothing reads the prose around a
  marker, so a section whose text contradicts its own entry is green. **Measured**: swapping a claim's
  command for an unrelated one that returns the same value by accident
  (`ls docs/adr/0*.md | wc -l` → `7`, the same as the persona count it replaced) left the suite at
  `102 passed, 0 failed`. This is the registry's `propósito` residual one surface out, and it is why
  the class markers are a **reviewer's instrument**, not a substitute for one.
- **No resource bound.** No timeout and no output limit; a slow but well-formed command hangs CI.
- **The class itself is authored.** Nothing stops a `VERIFIED`-able claim being filed `JUDGEMENT` to
  avoid the work. Coverage makes an *unlabelled* section visible; it cannot make a *mislabelled* one
  visible.
- **It ships `partial` — 5 of 18 sections — and the declaration is gated in both directions**, so
  `complete` with an unlabelled section reddens and `partial` with nothing unlabelled reddens too.
  Padding to `complete` with thin `JUDGEMENT` markers is the failure the class set exists to prevent.

### What the mechanism found, which is the argument for it

Two claims live on `main` at `4ad4dfc`, with the suite `92 passed, 0 failed` through both:
*"the gate's own verdict is read by nobody"* (two hooks read it) and *"the six personas above"* (there
are seven). Both are corrected in the same slice. **Neither was found by a reviewer** — both fell out
of authoring the class, because a `VERIFIED` marker cannot be written without running the command.

**And two defects in the gate itself, found the same way — by mutating it, not by re-reading it.** The
executing arm re-derived the containment instead of calling the refusing arm's predicate, so a command
whose *head* had just been refused was run anyway; and the marker extraction emitted an empty leading
field, which `read` strips because TAB is an IFS whitespace character, so the arm reddened on shifted
columns and printed the class where the id belonged. Both are the shape this repository keeps paying
for: **a reason that survives re-reading is not evidence**, and *failing closed with an unreadable
message* is not the same as failing closed.

### Amendment 2026-08-24 — the containment criterion was wrong, and the gate found it by executing it

**The slice whose thesis is *a claim published with no falsifier beside it* shipped three sentences of
exactly that.** The containment criterion above, the same claim in `docs/readme-claims.md`, and the
comment above `RC_HEADS` in `hooks/scripts/inventory-counts.test.sh` all asserted a property of the
allow-list that **nobody had tested**. It was found in review, by *running* the containment rather than
reading it — which is precisely the instrument this record exists to install, turned on the record's own
mechanism. **This is not an edge case that was found.** It is this ADR's defect class, committed inside
the gate built to catch that defect class, and it is written down that way deliberately.

**The escape.** `RC_HEADS` contained two heads that write files:

```
uniq README.md hooks/scripts/kiro-power.test.sh | wc -l
```

`uniq` writes its **second positional operand** — no flag, so nothing a denylist could hold, and every
character inside the character allow-list. The gate reported *all three containments passed* and then
overwrote another gate's test script (31614 bytes before, 109064 after), reddening only afterwards on
the `expects` comparison. A command chosen to return the right number would have written the file and
left the suite green. `sort` was the same defect wearing a flag (`-o`) — **and patching only the flag
denylist would have caught `sort` and not `uniq`**, which is why the correction is to the criterion and
not to the list.

**The corrected criterion: flags AND positional operands enumerable, and every one of them read-only.**
Not *"not a general-purpose language"* — that is a strictly weaker test and it is the one that failed.

**Applying it to the remaining nine heads dropped two more, for two different reasons.** `find` was
dropped because `-fprint0` writes and was *also* missing from the denylist, and because find's action
set is implementation-dependent (BSD find has no `-fprint*`; GNU findutils and `bfs` do) with nothing
pinning which binary CI runs — it was the only head whose safety rested on a denylist rather than on the
allow-list, and it is the one that leaked. `jq` was dropped on the **operand** half rather than the write
half: it cannot write a file, but its first positional is an expression in its own language, and
`jq -n -r 'env.HOME'` reads the CI environment using not one character outside the allow-list, into a
failure message that prints stdout. `grep`, `ls`, `wc`, `head`, `cat`, `tr` and `basename` pass, each
checked against both halves; the per-head table is in
[`docs/readme-claims.md`](../readme-claims.md), under *"The criterion a head must satisfy"*.

**What now holds the criterion, since prose demonstrably did not.** Two arms, both two-sided:
`RC_HEADS` is **pinned** (`RC_HEADS_PIN`), so adding or removing a head reddens the suite until a human
re-applies the criterion in the same commit; and a **containment regression** feeds `rc_contain_of` the
escapes it leaked plus the commands it must still accept, because a refusal-only table is satisfied by a
containment that refuses everything. Neither arm can read a program's manual — **no gate can** — so what
they buy is that the judgement is *forced and dated*, never that it is *made correctly*. That residual is
the same shape as `propósito` and as the class marker itself, and it is stated here rather than left to
be rediscovered.

**One cost, paid rather than worked around.** Claim `0001` used `find`; its command is now
`ls agents/*.md | wc -l`, which does not filter to regular files. A directory named `something.md` under
`agents/` would be counted. Accepted, and recorded in the entry's own `limit`.

## Amendment, 2026-08-28 — `purpose:` is a plugin-side field, and it is NOT the registry's second source

**Driven by [#313](https://github.com/tedeuxx/tadeumendonca-skills/issues/313), slice 1, reopened by the
owner on 2026-08-28: «preciso tbm que priorize o comando blueprint para acelerarmos a reconciliacao com
outros projetos de configuracao de harness que estou trabalhando».**

**Deciders:** the owner (decision, and the reopening that put it at the front of the queue) · written by
`agents-lead` per the domain split — this is a pure loop/machinery decision · **the consumer interest in
`tadeumendonca-io` is co-cited and did not decide it**: that repo's manifest is what has carried
identity-with-no-purpose since it was built, and its own record deferred the fix to here.

**Why this is an amendment and not record 0022, stated because the Issue asked for a record.** Since
[#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283) this library is **one document per
capability name**, and the most recent decision of comparable size refused a new number on exactly that
ground — ADR-0002's amendment #20: *"No new record, and the reason is the capability shape."* This
capability's entry in [`docs/adr/README.md`](./README.md) claims *how this harness describes itself to a
reader who does not run it*, which is what a `purpose:` field is for. A standalone record would have
cost a new row in the closed capability table and a ceiling bump, to say something this document is
already the home of. **If the owner wants the standalone record anyway, that is what it costs** — the
decision below is unaffected either way.

### The deferral this discharges, and why its reason lapsed

`tadeumendonca-io`'s **ADR-0043** deferred the purpose schema to this repository rather than rejecting
it. The clause, quoted in full in *Context & problem* above and reduced here to the half that lapsed:

> …a hook's one-line purpose is a methodology fact and would sit legitimately in that repo. It is
> deferred because introducing a schema there to serve **one consumer's page** is option 2's inversion
> in a milder form…

**The reason was the denominator, and the denominator moved.** The objection was never that the field
was wrong; it was that a schema in the *producer* built to serve a single *consumer's* rendering
inverts which repo is authoritative. `/blueprint` is a **second consumer, living in this repository**,
and it is the one the owner has now put upstream of everything else — on
[#343](https://github.com/tedeuxx/tadeumendonca-skills/issues/343) he declined to relax WIP=1 and named
the precondition himself: *«ainda nao estamos com todos perfis e skills configurados que ainda vamos
equalizar com meus outros projetos de harness»*. A field with two consumers, one of them local, is not
an inversion. It is a plugin-side fact that two readers happen to want.

**What the drift costs today, measured rather than asserted.** `tadeumendonca-io`'s
`apps/fed/src/content/generated/harness.json` enumerates every element of this harness and carries
`kind`, `id`, `file`, `event`, `matcher`, `enforcement` — identity, and no obligation:

    python3 -c "import json;d=json.load(open('apps/fed/src/content/generated/harness.json'));\
    print(len(d), sorted({k for r in d for k in r}))"
    # 20 ['enforcement', 'event', 'file', 'id', 'kind', 'matcher', 'skills']

Its generator says so in its own header. So the surface that publishes this harness to a reader can name
every mechanism and cannot say what any of them is **for** — which is the one thing a reader on another
harness needs, and the only thing no consumer can derive from the tree.

### Decision

**Every mechanism this plugin ships declares exactly one `purpose:` line, and every declaration names a
mechanism that exists.** A mechanism is: a hook **registered in `hooks/hooks.json`**, a persona in
`agents/`, a typed command in `commands/`, or a skill **declared in `.claude-plugin/plugin.json`** — 35
at this record's date. The declaration is **positional**: line 2 of a hook script, immediately after the
shebang; a frontmatter key in a markdown mechanism. Both directions are gated by three arms in
`hooks/scripts/inventory-counts.test.sh` (`purpose (forward)`, `purpose (shape)`, `purpose (reverse)`).

**`purpose:` is not `description:`, and the gate asserts they differ.** `description:` is a **trigger**
addressed to the model — *when do I reach for this*. `purpose:` is an **obligation** addressed to an
engineer on a harness nobody here has measured — *why does this exist, and what is lost without it*.
The cheapest way to fill a new field is to paste the neighbouring one, so a byte-identical pair reddens.

**The position is a measurement, not a preference.** `# purpose:` already occurred at column 0 in this
tree as ordinary prose — `orchestrator-write-guard.sh` carried *"Both are denied on / purpose: a write
into `.git/` escapes the diff entirely"*, a sentence wrapped so the token began a line. It was found by
the new arm's first run, not by reading. **The prose was rewrapped rather than the gate exempted**,
because position is what *this* suite reads and `^# purpose:` is what a naive consumer greps, and the
whole point of the field is to be read by consumers nobody here controls.

### This does NOT reverse considered option 3

Option 3 above — *per-file `purpose:` frontmatter, as filed, the blueprint rendered from the file
inventory* — stays rejected, for the reason given: a behaviour is not a property of one file, so a
per-file field cannot produce the registry's rows. **What is adopted here is the field, not the row
model.** The two coexist and are keyed differently on purpose:

| | `docs/blueprint-registry.md` | `purpose:` |
|---|---|---|
| keyed on | a **behaviour** | a **file** |
| a behaviour no file carries | has a row (`carrier: none`) | has no declaration, and must not |
| a file carrying two behaviours | has two rows | has one declaration |
| consumer | `/blueprint`, and a foreign harness | an identity inventory — `harness.json` today |

**Nothing cross-checks the two, deliberately.** A gate tying them together would force one to be a
projection of the other, which is the collapse they were separated to avoid — and it would recreate,
between two files in one repo, exactly the inversion ADR-0043 refused between two repos.

### Rejected option — leave the purposes as README prose

**What it is:** the README already glosses most of these mechanisms in its hooks and roster sections.
The purposes could have been curated there and left as prose, with no field, no frontmatter change and
no gate.

**Trade-off, and why not:** it is free to write and unusable to a consumer. A generator cannot extract a
gloss from a narrative paragraph without inventing a parse of prose that nobody wrote to be parsed —
which is a second, worse source of truth appearing the moment anyone tries. And it fails in the
direction this repository has been wrong in before: nothing about adding a hook makes anyone open the
README, so the omission is silent and the prose that *is* there ages against a tree that moved. The
field costs one line per mechanism and one gate; the prose costs a sweep nobody schedules.

### Consequences

**Good**
- The one fact an inventory consumer cannot derive from the tree now exists in the tree, gated.
- `-io`'s ADR-0043 deferral is discharged, and the closure is on the producer's side where it belongs.
- Slice 1 stands alone: it closes a drift that repository explicitly could not close, whether or not
  `/blueprint` is ever built.

**Bad / accepted costs**
- **A purpose is unfalsifiable by grep, and the greens must not be read as more.** The arms assert
  existence, position, length and non-duplication. A purpose describing what a mechanism was *meant* to
  do rather than what it does passes all three. That is a reviewer's read, and it is the same residual
  the registry already states about `propósito`.
- **35 lines that must be maintained by hand**, and the field's value decays exactly as fast as they
  go stale. The gate makes the *absence* loud and the *staleness* silent.
- **Two purpose-shaped artifacts now exist in one repository**, and a reader meeting the second one
  first has to be told they are keyed differently. The table above is that telling; nothing enforces
  that anyone reads it.
- **One purpose line is an honest disappointment and is written as one.**
  `dispatch-metrics-start.sh` declares that it is *"deliberately close to a no-op"*, because that is
  what the file does — its own header says every field it receives is recoverable at `SubagentStop`.
  A field that let that row read as a capability would have been worse than no field.

## Amendment, 2026-08-28 — `/blueprint` exists, and its enforcement axis measures REFUSAL only

**Driven by [#313](https://github.com/tedeuxx/tadeumendonca-skills/issues/313), slice 2, on the owner's
priority ruling the same day: «preciso tbm que priorize o comando blueprint para acelerarmos a
reconciliacao com outros projetos de configuracao de harness que estou trabalhando».**

**Deciders:** the owner (priority, and the direction) · written by `agents-lead` per the domain split —
a pure loop/machinery decision.

### What landed, and the one check nobody performed twice

`commands/blueprint.md` — the projection this record's *Consequences* deliberately left unbuilt. **This
Issue had closed twice with `/blueprint` not existing**, both times because a slice merged and carried
the Issue with it; nothing in the loop reads whether an Issue's promised artifact resolves, and a
closing keyword cannot check a command. ~~Until the closure gate lands, the check is manual and it is one
line:~~ **The gate landed on 2026-08-28 (#337, `hooks/scripts/closure-artifact-guard.sh`,
[ADR-0004](./0004-controls-and-enforcement.md)'s 2026-08-28 amendment), and the sentence is struck
rather than deleted because the manual check it names is still the one to run and the reason has
changed.** What the gate holds is a promise the Issue **declares** (`invocable: /blueprint`); nothing
forces that declaration, and this Issue carries none, so **for #313 specifically the check is still
manual**: `ls commands/` names the file, and an unknown sibling identifier is refused *by name*.

Measured, probe against control, one variable:

    claude --plugin-dir <root> -p "/tadeumendonca-skills:blueprintzz" --max-turns 1
    → Unknown command: /tadeumendonca-skills:blueprintzz. Did you mean /tadeumendonca-skills:blueprint?

**The control's suggestion is the evidence, not the probe's output.** A loader that had not registered
the file could not have named it, and the run of the real identifier produced the document end to end.

### The decision this slice makes: no fourth `enforcement` value

The Issue left it open — *either add `acts` deliberately, or state in the format that the axis measures
refusal only.* **Stated, not added**, and the reasoning is checkable in both directions.

**The strain is real and has live instances at head, so this is not settled by the discomfort having
gone away.** `hooks/scripts/dispatch-metrics-stop.sh:224` calls `gh issue comment` — it writes to a
surface outside the repository and refuses nothing; `zombie-loop-detect.sh` and
`orchestrator-tool-census.sh` are the same shape one step milder. The registry's whole `record` group
acts and denies nothing. ADR-0043's *"one row sits uncomfortably here"* was about a hook deleted at
#245, but the class it named did not leave with it.

**Two reasons the value is not added anyway, both consumer-facing rather than aesthetic.** The axis is
consumed by an inventory in the other repository that keys on it with a **closed set** and throws on an
unknown key by design — a fourth value produced here does not inform that reader, it breaks it, and the
red lands on an unrelated pull request over there. And the distinction `acts` would carry **is already
carried by `tipo`**: an acting mechanism is `record`, a body of guidance is `knowledge`, and a column
that re-expresses a distinction another column already makes is this repository's measured failure mode.

**So the format says it in words instead**, and the export prints it above the rows: *the axis answers
can this stop the actor before the act — read `documents` as "does not refuse", never as "does
nothing".* **A named strain in an interchange format is information; a silently overloaded value is
not.**

### Consequences

**Good**
- The registry stops being a description of an artifact that did not exist. It is row `0036` now, and
  the coverage arm holds the command class complete in both directions.
- The export reads the tree at invocation and hardcodes no repository's names, so the half of this
  Issue that is reusable by anyone who installs the plugin actually is.

**Bad, and accepted**
- **`0036` strains the closed `tipo` set the way `0018`/`0019` do, in the opposite direction.** Its
  artifact is produced on demand and never persisted, which is not what `record`'s heading claims. It
  is filed there on the reading that the currency header is what makes the document checkable later.
  The set is not reopened on one row, and the strain is written into the registry beside it rather than
  smoothed over.
- **Nothing gates the export's content.** The suite asserts the command exists, is typed, declares a
  purpose, and is claimed by a row whose quote resolves. It cannot assert that a rendered blueprint is
  faithful to the registry, because the render is a model reading a file — the same residual this
  record already states about `propósito`, one surface further out and one degree weaker.
- **Three gates moved for one file, and one of them is in the other repository.** `root_cmds`,
  `ARG_HINT_ALLOWED` and `BP_HIGH_WATER` are edited here; the consuming repo's manifest gains a command
  row and its gate reddens on its next unrelated pull request until regenerated. That asymmetry is
  ADR-0043's, booked there, and it is **not** repaired from this side.
- **The import half remains unbuilt and is now refused with a reason rather than absent.** A non-empty
  argument gets the format's own explanation of why parsing a document nobody foreign wrote proves
  nothing. **Whether a foreign harness's configuration fits this schema is a hypothesis, in those
  words** — there is one harness in evidence and it is ours.

## Links

- [#324](https://github.com/tedeuxx/tadeumendonca-skills/issues/324) — the claim-class contract, its
  pre-implementation refutation of the inventory-projection design, and the owner's addition of the
  `VERIFIED` class.
- [`docs/readme-claims.md`](../readme-claims.md) — the claim registry, and the containment section.
- [#313](https://github.com/tedeuxx/tadeumendonca-skills/issues/313) — the driving Issue, and the three
  pre-implementation verdicts that are this record's design work.
- [ADR-0004](./0004-controls-and-enforcement.md) — *which layer carries a control*, the standing
  question every `refusal` row is written against.
- [ADR-0011](./0011-skills-and-preload.md) — what a skill is, and the transversality test the shared
  content ruler is an acknowledged exception to.
- [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md) — the disposition
  rules and the declared-ceiling convention this registry reuses rather than reinvents.
- [`tadeumendonca-io`'s ADR-0043](https://github.com/tedeuxx/tadeumendonca-io/blob/main/docs/adr/0043-harness-inventory-derived-from-plugin-repo.md)
  — the foreign record whose deferral of the purpose schema is quoted in *Context & problem*, and the
  consumer interest option 3 stays decoupled from. Its number belongs to the other library.
- [The registry itself](../blueprint-registry.md).
