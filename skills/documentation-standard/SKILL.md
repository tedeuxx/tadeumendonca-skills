---
description: Write repository documentation to the platform standard — Markdown and Mermaid only, the diagram types expected per repo, and the content each document owes. Use when adding a README or an architecture page, choosing a diagram type, or reviewing docs that drifted from the format. Not for decision records, which have their own format (see adr).
family: workflow
---

Write or review docs for any <project> repo following the documentation standard.

Context: $ARGUMENTS

## Rule

All documentation is **Markdown + Mermaid**. **No static image diagrams** — every diagram is Mermaid so it stays diffable and versioned.

## Where a document lives — the placement rule

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
`docs/` folder one repo away is a folder nobody's diff ever reaches.

## Diagram types

| Diagram | Mermaid | Where |
|---|---|---|
| Infra architecture | `flowchart TD` / `graph LR` | `docs/architecture.md` (each repo) |
| Data model (tables) | `erDiagram` | `docs/data-model.md` in the API unit |
| Flows / integrations | `sequenceDiagram` | `docs/sequences.md`, one per unit that participates |
| Frontend components | `flowchart LR` | `docs/architecture.md` in the SPA unit |

## Expected content per file
- **`iac/docs/architecture.md`** — Terraform module dependency graph (+ network topology when a VPC is provisioned: subnets/NAT/endpoints).
- **The API unit's `docs/data-model.md`** — `erDiagram` of the persisted entities (fields, types, implicit relations); on a document store, the implicit relations are the ones worth drawing, since nothing in the engine declares them.
- **The API unit's `docs/sequences.md`** — the auth exchange end to end, one representative write path (admin → API → store → notification), and any request that leaves the normal path (a bot/SEO render, a webhook).
- **The API unit's `docs/architecture.md`** — compute × gateway × data store × secrets × object storage.
- **The SPA unit's `docs/sequences.md`** — login, one representative authenticated fetch, one paginated/infinite-scroll read.
- **The SPA unit's `docs/architecture.md`** — pages × hooks × store × services.

## Conventions
- Every repo has a `docs/` folder; keep diagrams next to the code they describe.
- Documentation is a deliverable per phase (labeled `type:docs`), part of the `v1.0.0` GA criteria.

## Pros & cons
**Pros**
- Diffable, versioned docs; diagrams as code (Mermaid); no binary images to drift.
**Cons**
- Mermaid has expressiveness limits.
- Keeping docs current is a discipline, not enforced.
