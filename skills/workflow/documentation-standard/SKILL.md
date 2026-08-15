---
description: Write or review documentation for any <project> repo — general docs (README, architecture pages, diagram choice, Markdown + Mermaid only) AND Architecture Decision Records (MADR format, the significance gate, the methodology/product library split, numbering and status, and the current-codebase rule for a reversed decision). Use when adding a README or architecture page, choosing a diagram type, reviewing drifted docs, writing or superseding an ADR, or judging architectural significance.
---

# Documentation — the general standard and the ADR practice

Write or review docs for any `<project>` repo following the platform's documentation standard.

**Two bodies of content, kept legible as two sections rather than blended (#260).** Part I is
*general documentation* — README, architecture pages, diagram choice, the Markdown + Mermaid rule,
where a doc lives. Part II is *the governed artifact* — an Architecture Decision Record: MADR format,
the significance gate that decides whether one is owed at all, the methodology/product library split,
numbering and status, and the current-codebase rule that replaced supersede-never-delete (#281,
[ADR-0020](../../../docs/adr/0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)). They
were two separate skills until #260, on the owner's own call, made **after** he was shown that the split
was legitimate rather than accidental — general
docs describe a *system*, an ADR records *one decision that was made about it*, and neither collapses
into the other. Merged anyway because both bodies belong to the same object (repository documentation)
and a reader who needs one is very likely, on this platform, to need the other in the same sitting. Read
Part I for *how to document the system*; read Part II for *how to record a decision about it*.

Context: $ARGUMENTS

## Part I — General documentation (README, architecture pages, diagrams)

### Rule

All documentation is **Markdown + Mermaid**. **No static image diagrams** — every diagram is Mermaid so
it stays diffable and versioned. (ADRs, Part II below, are a specific document *within* this standard —
see Part II for their own format, which layers MADR structure on top of this rule rather than replacing
it.)

### Where a document lives — the placement rule

**A `docs/` folder belongs to the smallest unit that owns the thing being described, and travels with it.**
Resolve it in that order and the paths below follow mechanically:

1. **The deployable unit owns its docs.** A standalone repo puts them at `docs/`; a monorepo puts them at
   `<unit>/docs/` — one folder per workspace (the SPA, the API, the IaC root), never one shared folder at
   the top pretending to describe all three.
2. **Name the file for the question it answers, not for the unit** — `architecture.md`, `data-model.md`,
   `sequences.md`. The unit is already the directory; repeating it in the filename buys nothing and
   breaks the cross-repo habit of knowing where to look.
3. **A diagram that spans two units is duplicated from each side, not centralised.** Each copy is drawn
   from its own unit's vantage point (what it calls out to, what calls it), because a single "system"
   diagram is the one that rots first — nobody owns it, so nobody updates it on a change.

*Why placement is a rule at all:* docs decay in proportion to their distance from the code, and the only
reliable forcing function is that the same PR touching the code also touches the file next to it. A
`docs/` folder one repo away is a folder nobody's diff ever reaches. **The ADR libraries in Part II are
the one deliberate exception to "next to the code"** — they live at each repo's own `docs/adr/` root
regardless of which unit a decision concerns, because a decision record needs one stable, browsable
index per repo more than it needs to sit beside the specific file it changed.

### Diagram types

| Diagram | Mermaid | Where |
|---|---|---|
| Infra architecture | `flowchart TD` / `graph LR` | `docs/architecture.md` (each repo) |
| Data model (tables) | `erDiagram` | `docs/data-model.md` in the API unit |
| Flows / integrations | `sequenceDiagram` | `docs/sequences.md`, one per unit that participates |
| Frontend components | `flowchart LR` | `docs/architecture.md` in the SPA unit |

### Expected content per file

- **`iac/docs/architecture.md`** — Terraform module dependency graph (+ network topology when a VPC is provisioned: subnets/NAT/endpoints).
- **The API unit's `docs/data-model.md`** — `erDiagram` of the persisted entities (fields, types, implicit relations); on a document store, the implicit relations are the ones worth drawing, since nothing in the engine declares them.
- **The API unit's `docs/sequences.md`** — the auth exchange end to end, one representative write path (admin → API → store → notification), and any request that leaves the normal path (a bot/SEO render, a webhook).
- **The API unit's `docs/architecture.md`** — compute × gateway × data store × secrets × object storage.
- **The SPA unit's `docs/sequences.md`** — login, one representative authenticated fetch, one paginated/infinite-scroll read.
- **The SPA unit's `docs/architecture.md`** — pages × hooks × store × services.

### Conventions

- Every repo has a `docs/` folder; keep diagrams next to the code they describe (Part II's ADR libraries excepted, per the placement rule above).
- ~~Documentation is a deliverable per phase (labeled `type:docs`), part of the `v1.0.0` GA criteria.~~
  **Struck 2026-08-13 — `type:*`/`phase:*` were retired 2026-08-02** (`/dev-loop`, "eleven had never
  been applied to anything"); the live vocabulary is `product`/`content`/`ready`/`blocked`/
  `reader-facing`, and there is no `v1.0.0` GA milestone in the live loop. See `github-actions`'s own
  labels table for the same retirement, carried there with the "kept, not corrected" flag this line
  lacked.

### Pros & cons (of the general standard)

**Pros**
- Diffable, versioned docs; diagrams as code (Mermaid); no binary images to drift.

**Cons**
- Mermaid has expressiveness limits.
- Keeping docs current is a discipline, not enforced.

## Part II — Architecture Decision Records (the governed artifact)

### What an ADR is

A short, immutable record of one **architecturally-significant decision**: the context that forced it,
the options weighed, the choice, and its consequences. ADRs are the **durable shared brain** of the
platform — a fresh, per-task agent context cannot remember prior decisions, so it reads them here.
Without ADRs, isolated contexts re-decide and drift; with them, every context stays coherent with what
was already pacted. This is why the ADR library is the substrate the rest of the dev-loop stands on (see
`README.md`, the current single source of truth for the dev-loop design — the former
`docs/proposals/agentic-dev-loop.md` is now a superseded historical record, per ADR-0019).

### When to write one — the significance test (the light gate)

Write (or amend) an ADR when a change crosses a **significant boundary** — objectively, any of:
- touches infrastructure (`iac/`),
- changes a public contract / schema,
- alters a previously-recorded (fixed) decision,
- introduces a new dependency or tool-class,
- establishes a cross-cutting pattern others will follow.

Otherwise, no ADR — a routine in-pattern change declares "no ADR" and moves on. Authorship is split by
domain (#223): `tech-lead` flags the need at intake and writes the record for product/system-architecture
decisions; `harness-lead` does the same for pure loop/harness/machinery decisions. `quality-assurance`
verifies on the MR that a significance-crossing change references one, regardless of which of the two
authored it. (`adr-author` named here until 2026-08-03 was absorbed into `tech-lead`; the further split
from `tech-lead`-exclusive to domain-based landed 2026-08-13 — whoever holds the decision writes it, in
the same MR as the change, and "whoever" now names two personas by domain rather than one persona by
default.)

**Decision & trade-off:** a *light* gate (significance-triggered), not a *strong* one (ADR for every
change). Trade-off: a light gate can miss a decision that only looks routine — and the test is applied at
two moments, which the sentence here denied until 2026-08-03. **The domain-holding lead applies it at
intake, before the build, and writes the record** (`agents/tech-lead.md` and `agents/harness-lead.md`
each state this for their own domain); **`quality-assurance` verifies on the MR** that a
significance-crossing change references one, whoever authored it. That is what the persona contracts say
today, and it is checkable there. A strong gate would never miss one but taxes every trivial change and
trains people to write empty ADRs; the light gate keeps ADRs meaningful.

### Format — MADR

Every ADR uses **MADR** (Markdown Any Decision Record). Copy `docs/adr/template.md`. Sections: title,
status, context & problem, decision drivers, considered options, decision outcome, consequences (good and
bad), links. This is Part I's Markdown + Mermaid rule specialized for one document type — the MADR
sections are the shape *within* a Markdown file, not an exception to the format.

**Decision & trade-off:** MADR over Nygard's leaner 4-section form. Trade-off: MADR is heavier per ADR.
Chosen because recording the **considered options and their trade-offs** is the point for a
proof-of-engineering product — the rejected paths are half the argument. Nygard's form drops them.

### Two libraries — methodology vs product

| Library | Lives in | Records |
|---|---|---|
| **Methodology** | `tadeumendonca-skills/docs/adr/` | decisions about the *machine* — the dev-loop, the roster, the gates, this practice itself |
| **Product** | `docs/adr/` in the repo that installs the plugin — one library per product, at its root | decisions about the *product* — its architecture, stack, infra, UX |

This skill (the template + practice) is single and lives in the plugin; both libraries consume it.

**Decision & trade-off:** two libraries, not one. Trade-off: a reader consults two places, and a decision
that is half-methodology half-product needs a judgment call on where it lands (rule of thumb: does it
constrain *this product* or *any project using the plugin?*). Chosen because the plugin is reused across
projects — folding product decisions into it would leak one project's choices into every consumer.

### Numbering & status

- **Numbering:** zero-padded sequential **per library** (`0001`, `0002`, …). Filename `NNNN-kebab-title.md`.
- **Status lifecycle:** `proposed → accepted → superseded` (or `rejected`). A design starts `proposed`; the human's ratification makes it `accepted`.
- **Disposition of a reversed decision:** see the next section — the record's `status` field is the criterion, and the disposition is one of three.

### A record earns its place by explaining the CURRENT codebase

**The rule.** An ADR is kept because it explains the codebase that exists now. A whole-file record whose
entire subject is a component that was switched off does not — and it does not merely fail to help, it
actively harms, because a later reader (human, and above all an agent loading a decision library) infers
architecture from it. The disposition of a reversed decision is one of three, and the record's **`status`
field is the criterion — never its filename**:

1. **Delete the record; keep a History row.** *(Default, for a record whose whole subject is a component
   that no longer exists.)* `git rm` the file and leave one row in the library's `README.md` History
   table: the id, one line naming what was decided, and what replaced it. **That row is the marker.** It
   costs one line, carries no architecture a reader could rebuild from, and answers *"was this ever
   decided?"* without answering *"how was it built?"* — which is the whole of the distinction this rule
   turns on. **A deletion with no row is not this rule; it is a gap.** A silent absence and a deliberate
   absence must not look identical.
2. **Fold the context into the record that replaced it — before the deletion, not after.** *(Mandatory
   whenever the current decision is only intelligible against what it replaced.)* The superseding record
   carries a `## What this replaced` section: what was in place, why it was reversed, and the one
   consequence that still shapes the current design. A sentence in a live record explaining what it
   replaced **explains today's codebase**; a whole file for the retired one does not. **If there is
   nowhere to fold and no row is written, do not delete** — that deletion is a net loss of information
   with no compensating artifact, and it is the version of this change that would deserve the name
   *"we deleted our history."* **Where disposition 2 has no target, disposition 1 is what covers it** —
   a reversal whose replacement is a *pivot* rather than a numbered record has nothing to fold into, and
   the History row is then the only artifact, which is why it is mandatory and not a nicety.
3. **Keep the file** where the record is not about a retired component at all: a **`proposed`** record
   (it explains an *intended* codebase, and its status already says so), and an **`accepted`** record
   whose mechanism has no instances yet (a current convention, merely unexercised). Scope the rule to
   **reversed** decisions, never to *unbuilt* or *unexercised* ones.

**This rule is about whole records, not about sentences inside a live one.** Within an `accepted` record
the convention is unchanged and **load-bearing**: **amend by appending, strike in place (`~~…~~`), never
rewrite.** Struck history inside a live record is how a reader — and at least one gate in this repo —
tells a superseded claim from a stale one: `hooks/scripts/inventory-counts.test.sh`'s roster-membership
assertion distinguishes the two by exactly those markers (its `roster_narr_re` pattern matches `~~`,
`STRUCK`, `former`, `supersed` and the other past-tense forms), and its own comment states the reason.
Stripping struck history out of a live record does not turn that check red — it makes it **quieter**,
having less to read, which is worse. Nothing here licenses that.

**Before deleting, discharge every inbound reference in the same MR.** A published page, a generated
artifact or a test may resolve the file. The deletion is not done until they do not.

**What this rule replaced.** It was **supersede-never-delete**: a reversed decision kept its file, took
`status: superseded`, and linked forward — *"reverted decisions are history, not gaps."* **Both rules
share a premise** — a retired record misleads a future reader who infers architecture from it — **and
split only on the remedy.** That shared premise is **attested, not read back into the old rule after the
fact** — the old rule's own text argued from preservation value and never stated it, so the evidence is
worth pointing at: it is written in the owner's published voice on the platform's own architecture page,
in its `status` / `superseded-by` bullet, which says in as many words that the record of a retired
architecture *reads as an instruction* and is the cheapest way to make an agent rebuild something that
was cut on purpose. [ADR-0020](../../../docs/adr/0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)
quotes that clause verbatim. The old rule says *mark it*; this one says the marker is not enough,
because the file is still there to be inferred from, and an agent loading a decision library reads
**bodies**, not status lines. *Accepted cost:* the reasoning of a reversal is no longer preserved at length. Disposition 2 is
what keeps the part of it that was load-bearing; disposition 1's row is what keeps the absence
deliberate. **The decision and its rejected options are recorded in
[ADR-0020](../../../docs/adr/0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)** — this
section is the operative wording, that record is the argument, including the correction that the
significance arm which fires is *sets a cross-cutting pattern* and not *alters a previously-recorded
decision* (supersede-never-delete was never itself recorded as an ADR).

**Nothing enforces the deletion rule** — unlike the strike convention above, which at least one
assertion reads in part. Measured on this repo, on a full scratch copy of the tree including `.git`:
`rm docs/adr/0002-agentic-dev-loop-architecture.md` — the library's largest record, cited by name from
several others — then `bash hooks/scripts/inventory-counts.test.sh` → **`69 passed, 0 failed`**,
identical to the control run on the unmutated copy. (The `.git` directory has to travel with the copy:
without it two assertions fail for an unrelated reason — a shallow-history guard — which is a different
red, not this one.) No hook, workflow or settings file asserts anything about the ADR library's shape,
so the largest record in it can vanish with every gate green. This rule is a **discipline, not an
enforcement** — including the History row and the fold, which are prose too and inherit the same zero
enforcement. They land in the same MR as the deletion, where a reviewer can still see both halves.

**Where a "this is not live" disclaimer belongs.** In the artifact's **body**, above the fold — not in a
skill's `description:` frontmatter, which is gated as a *trigger* (length, single line, `Use when`, no
stem opener) and has no budget for a disclaimer competing with it. `skills/backend/SKILL.md` already
carries its reference-only statement that way, and that is the right home.

### Cite the clause, not the line

**Reference another record's content — or your own — by quoting the clause verbatim, never by `:NN`.** A
line number depends on another file's whitespace; a quoted clause depends only on that clause continuing
to exist, and if it stops existing that is a **finding** rather than a silent misdirection. Where the
target is a *region* rather than a clause — a table, a section, an amendment — **quote its heading
verbatim** (`the "Considered options" section`, `the 2026-08-15 amendment`). A heading is a string, so it
keeps both properties the clause rule buys, and it closes the one case where the convention would
otherwise revert to line numbers exactly where they are hardest to check. **What it does not close:
quoting the wrong heading.** A heading pins a region only if it is the region the cited content sits in
— not the nearest heading that *describes* it. Check that the thing you are citing is under the heading
you quoted, or the citation is verbatim, checkable, and pointing somewhere else.

*The measurement that produced this rule, because it is the argument.* On the first authorship in either
library to use line locators, **five of nine were wrong** — four cited `:26` for a clause at `:25`, and
one named a range that ended a line early *and* pointed at a definition while the surrounding sentence
described the attachment. **A gate caught four and graded the fifth advisory**, so one imprecise locator
would still have shipped through a reviewed path. That is not a case for more care; it is the case that
**the locator form is the defect**. And nothing anywhere resolves a `:NN` — no test in either repo
asserts a line locator — so a single inserted line silently re-breaks every citation with all gates
green.

*What it costs:* quoting is longer than `:25`, in records that are already long. Accepted.

**A count, an enumeration and a "complete list" are each a claim about a SET — and verifying the members
does not verify the set.** *"Three live records cite this"* is checked by re-reading the three that were
named, which leaves the **three** itself untested: the set can hold five, and the two nobody counted are
exactly the ones a later executor mishandles, because a list published as complete is read as complete.
The same holds for a cost list, a sweep, or *"these are all the places"*. So **state the criterion that
selects the members and publish the command that returns them** — `git grep -n -E "…" -- docs/adr/`, and
the regex is part of the claim — or do not publish the count. A number verified against its examples and
not against its criterion is an anecdote about the members, shaped like a fact about the set.

### Authoring checklist

- [ ] One decision per ADR. If you're recording two, write two.
- [ ] The **considered options** section is real — at least the chosen path and the strongest rejected alternative, each with its trade-off.
- [ ] Consequences list the **bad** ones too, not only the wins. An ADR with no downsides is not honest.
- [ ] Links back to the driving Issue/spec and to any ADR it supersedes or depends on.
- [ ] Committed **in the same MR** as the change it justifies (no decision drift — the docs move with the code).
- [ ] Every citation of another record quotes the **clause or heading**, never a line number.
- [ ] If the MR **deletes** a reversed record: the History row is written and the `## What this replaced` fold has landed in the superseding record, in this same MR — both are preconditions, not follow-ups.

### Pros & cons (of the ADR practice)

**Pros**
- Durable decision memory that a fresh per-task context can load → the anti-drift substrate.
- The rejected options are recorded → future changes see *why* a path was not taken and don't relitigate it.
- Light gate keeps the practice cheap; ADRs stay meaningful, not ceremonial.

**Cons**
- Discipline cost: an ADR per significant decision is work, and the significance test needs judgment.
- Two libraries add a lookup and an occasional "where does this belong?" call.
- MADR is verbose; a trivial-but-significant decision can feel over-documented.
