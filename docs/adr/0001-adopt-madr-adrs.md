# 0001. Adopt MADR Architecture Decision Records

- **Capability:** decision-library
- **Status:** accepted
- **Date:** 2026-07-22
- **Deciders:** the owner (ratified); this is the bootstrap ADR
- **Supersedes / superseded by:** —
- **Driven by:** `docs/proposals/agentic-dev-loop.md`

## Context & problem
The platform made significant technical decisions from the start — a fully static site, trunk-based
single-environment delivery, no shadcn, the brutalist mono identity, markdown-in-repo content with
build-time prerender, the immutable-OIDC-subject trust, the retirement of the backend — but recorded
none of them as decisions. They lived scattered across commit messages, `CLAUDE.md`, auto-memory, and
`.brand/`.

That dispersion has a concrete cost, observed directly: a full working session was spent reconciling
**drift** — dead references to the retired platform across code, config, memory and workflow names, none
caught by the loop, all caught by hand. And the dev-loop we are moving to (per-task subagent contexts)
makes this worse if unaddressed: a fresh, isolated context **cannot remember prior decisions by
construction**, so without a durable record it re-decides and contradicts what came before.

We need a durable, greppable, reviewable place for architecturally-significant decisions — one a fresh
per-task context can load.

## Decision drivers
- A fresh per-task agent context must be able to **read** prior decisions (the anti-drift substrate).
- The record must capture **why**, including the rejected options — this is a proof-of-engineering
  product; the argument is the point.
- The practice must be cheap enough to sustain (not an ADR for every trivial change).
- It must be **reusable across projects** (the practice lives in the plugin).

## Considered options
1. **MADR ADRs in `docs/adr/`, two libraries, a light significance-gated trigger** (chosen) —
   structured Markdown records; methodology decisions in the plugin, product decisions in each consuming
   repo; an ADR required only when a change crosses a significance boundary. *Trade-off:* discipline cost
   and a verbose per-record format; two libraries add a lookup.
2. **Nygard's leaner 4-section ADRs** — lighter per record. *Why not:* drops the considered-options /
   trade-off section, which is half the value for this product.
3. **Keep decisions in `CLAUDE.md` + memory (status quo)** — no new practice. *Why not:* exactly the
   dispersion that produced the drift; not loadable as discrete decisions; not reusable.

## Decision outcome
Chosen: **MADR ADRs, two libraries, light gate**, because it is the only option that gives a fresh
context a durable, discrete, why-preserving decision record without taxing every routine change — and it
packages into the plugin for reuse. The practice is defined in `/workflow/adr`; the template is
`docs/adr/template.md`.

## Consequences
**Good**
- Per-task subagent isolation becomes safe: the shared brain is on disk, greppable, versioned.
- Rejected paths are recorded → future changes don't relitigate settled trade-offs.
- Reusable: any repo enabling the plugin inherits the practice.

**Bad / accepted costs**
- An ADR per significant decision is ongoing work, and the significance test needs judgment (mitigated by
  both reviewers applying it).
- Two libraries mean a reader consults two places and an occasional "where does this belong?" call.
- MADR is verbose; a small-but-significant decision can feel over-documented.

## Links
- Proposal: `docs/proposals/agentic-dev-loop.md` (splits into ADR-0001..0004 on acceptance)
- Practice: `/workflow/adr` · Template: `docs/adr/template.md`
- Next: ADR-0002 (dev-loop architecture), record 0003 (MR Definition of Done — absorbed 2026-08-19 into
  [ADR-0006](./0006-verification-and-its-artifacts.md)), ADR-0004 (autonomy model)
