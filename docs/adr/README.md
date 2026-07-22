# Methodology ADRs

Architecture Decision Records for the **dev-loop machine** — the reusable engineering methodology this
plugin exports. Product decisions live in each consuming repo's own `docs/adr/` (e.g.
`tadeumendonca-io/docs/adr/`), not here.

Practice and template: [`/workflow/adr`](../../commands/workflow/adr.md) · [`template.md`](./template.md).

| ADR | Title | Status |
|---|---|---|
| [0001](./0001-adopt-madr-adrs.md) | Adopt MADR Architecture Decision Records | accepted |
| 0002 | Agentic dev-loop architecture (per-task subagents, ADRs-as-brain) | *pending* |
| 0003 | Merge Request Definition of Done | *pending* |
| 0004 | Autonomy & permission model (classes, tool-scoping) | *pending* |

New ADRs: copy `template.md` → `NNNN-kebab-title.md`, next number in sequence. Never delete a superseded
ADR — mark it `superseded by ADR-XXXX` and link forward.
