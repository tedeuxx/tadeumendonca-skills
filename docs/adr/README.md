# Methodology ADRs

Architecture Decision Records for the **dev-loop machine** — the reusable engineering methodology this
plugin exports. Product decisions live in each consuming repo's own `docs/adr/` (e.g.
`tadeumendonca-io/docs/adr/`), not here.

Practice and template: [`/workflow/adr`](../../commands/workflow/adr.md) · [`template.md`](./template.md).

| ADR | Title | Status |
|---|---|---|
| [0001](./0001-adopt-madr-adrs.md) | Adopt MADR Architecture Decision Records | accepted |
| [0002](./0002-agentic-dev-loop-architecture.md) | Agentic dev-loop architecture (per-task subagents, ADRs-as-brain) | accepted · amended 2026-07-23 (`product-owner`; then `product-manager` · `analytics` · `debugger`) |
| [0003](./0003-mr-definition-of-done.md) | Merge Request Definition of Done | accepted |
| [0004](./0004-autonomy-and-permission-model.md) | Autonomy & permission model (classes, tool-scoping) | accepted |
| [0005](./0005-plugin-auto-versions-on-merge.md) | The plugin auto-versions on every merge; adoption is the consumer's opt-in | accepted |

New ADRs: copy `template.md` → `NNNN-kebab-title.md`, next number in sequence. Never delete a superseded
ADR — mark it `superseded by ADR-XXXX` and link forward.
