---
description: Write or review documentation for any <project> repo — general docs (README, architecture pages, diagram choice, Markdown + Mermaid only) AND Architecture Decision Records (MADR format, the significance gate, the methodology/product library split, numbering and status, supersede-never-delete). Use when adding a README or architecture page, choosing a diagram type, reviewing drifted docs, writing or superseding an ADR, or judging architectural significance.
---

# Documentation — the general standard and the ADR practice

Write or review docs for any `<project>` repo following the platform's documentation standard.

**Two bodies of content, kept legible as two sections rather than blended (#260).** Part I is
*general documentation* — README, architecture pages, diagram choice, the Markdown + Mermaid rule,
where a doc lives. Part II is *the governed artifact* — an Architecture Decision Record: MADR format,
the significance gate that decides whether one is owed at all, the methodology/product library split,
numbering and status, supersede-never-delete. They were two separate skills until #260, on the owner's
own call, made **after** he was shown that the split was legitimate rather than accidental — general
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
`docs/proposals/agentic-dev-loop.md`).

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
- **Superseding, never deleting:** a reversed decision becomes `superseded`, keeps its file, and links forward to the ADR that replaced it. Reverted decisions are **history, not gaps** — the record of *why we changed our mind* is as valuable as the current state. (This is why the exhaustive reverse-engineering of past decisions includes the retired backend era as `superseded`.)

### Authoring checklist

- [ ] One decision per ADR. If you're recording two, write two.
- [ ] The **considered options** section is real — at least the chosen path and the strongest rejected alternative, each with its trade-off.
- [ ] Consequences list the **bad** ones too, not only the wins. An ADR with no downsides is not honest.
- [ ] Links back to the driving Issue/spec and to any ADR it supersedes or depends on.
- [ ] Committed **in the same MR** as the change it justifies (no decision drift — the docs move with the code).

### Pros & cons (of the ADR practice)

**Pros**
- Durable decision memory that a fresh per-task context can load → the anti-drift substrate.
- The rejected options are recorded → future changes see *why* a path was not taken and don't relitigate it.
- Light gate keeps the practice cheap; ADRs stay meaningful, not ceremonial.

**Cons**
- Discipline cost: an ADR per significant decision is work, and the significance test needs judgment.
- Two libraries add a lookup and an occasional "where does this belong?" call.
- MADR is verbose; a trivial-but-significant decision can feel over-documented.
