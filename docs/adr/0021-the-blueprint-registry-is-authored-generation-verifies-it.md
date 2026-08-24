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

## Links

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
