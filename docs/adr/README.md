# Methodology ADRs

Architecture Decision Records for the **dev-loop machine** — the reusable engineering methodology this
plugin exports. Product decisions live in each consuming repo's own `docs/adr/` (e.g.
`tadeumendonca-io/docs/adr/`), not here.

Practice and template: [`/workflow/adr`](../../commands/workflow/adr.md) · [`template.md`](./template.md).

| ADR | Title | Status |
|---|---|---|
| [0001](./0001-adopt-madr-adrs.md) | Adopt MADR Architecture Decision Records | accepted |
| [0002](./0002-agentic-dev-loop-architecture.md) | Agentic dev-loop architecture (per-task subagents, ADRs-as-brain) | accepted · amended 2026-07-23 (`product-owner`; then `product-manager` · `analytics` · `debugger`) · **amended 2026-07-24** (amendment #3 — roster reshape: `product-owner` re-scoped, `brand-guardian`/`editor`/`recruiter`/`scrum-master`; owner-ratified, implementation sequenced per #69) · **amended 2026-07-29** (amendment #4 — the `brand-guardian` trigger is a fail-closed rule, not a path list) · **amended 2026-07-30** (amendment #5 — `product-manager` gets a trigger; the reviewer's output gets a round budget) |
| [0003](./0003-mr-definition-of-done.md) | Merge Request Definition of Done | accepted |
| [0004](./0004-autonomy-and-permission-model.md) | Autonomy & permission model (classes, tool-scoping) | accepted |
| [0005](./0005-plugin-auto-versions-on-merge.md) | The plugin auto-versions on every merge; adoption is the consumer's opt-in | accepted |
| [0006](./0006-a-verdict-owed-to-another-persona-is-an-artifact.md) | A verdict one persona owes another is an artifact on the PR, not a relayed claim | accepted |
| [0007](./0007-the-merge-precondition-is-a-floor-not-an-instruction.md) | The merge precondition is a floor, not an instruction — a hook on the decidable half (the markers), fail-open and unbacked; the ratification half stays prose | proposed · **reverses ADR-0006's rejected option 2** |

New ADRs: copy `template.md` → `NNNN-kebab-title.md`, next number in sequence. Never delete a superseded
ADR — mark it `superseded by ADR-XXXX` and link forward.
