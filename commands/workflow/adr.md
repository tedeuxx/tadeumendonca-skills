Author or review an Architecture Decision Record (ADR) for any `<project>` repo, following the platform's ADR practice.

Context: $ARGUMENTS

## What an ADR is
A short, immutable record of one **architecturally-significant decision**: the context that forced it, the options weighed, the choice, and its consequences. ADRs are the **durable shared brain** of the platform — a fresh, per-task agent context cannot remember prior decisions, so it reads them here. Without ADRs, isolated contexts re-decide and drift; with them, every context stays coherent with what was already pacted. This is why the ADR library is the substrate the rest of the dev-loop stands on (see `docs/proposals/agentic-dev-loop.md`).

## When to write one — the significance test (the light gate)
Write (or amend) an ADR when a change crosses a **significant boundary** — objectively, any of:
- touches infrastructure (`iac/`),
- changes a public contract / schema,
- alters a previously-recorded (fixed) decision,
- introduces a new dependency or tool-class,
- establishes a cross-cutting pattern others will follow.

Otherwise, no ADR — a routine in-pattern change declares "no ADR" and moves on. `tech-lead` flags the need at intake and **writes the record**; `quality-assurance` verifies on the MR that a significance-crossing change references one. (`adr-author` named here until 2026-08-03 was absorbed into `tech-lead` — whoever holds the decision writes it, in the same MR as the change.)

**Decision & trade-off:** a *light* gate (significance-triggered), not a *strong* one (ADR for every change). Trade-off: a light gate can miss a decision that only looks routine — and the test is applied at two moments, which the sentence here denied until 2026-08-03. **`tech-lead` applies it at intake, before the build, and writes the record** (`agents/tech-lead.md` — *"flagged at intake, written by you in the same MR as the change"*); **`quality-assurance` verifies on the MR** that a significance-crossing change references one. That is what the persona contracts say today, and it is checkable there. A strong gate would never miss one but taxes every trivial change and trains people to write empty ADRs; the light gate keeps ADRs meaningful.

## Format — MADR
Every ADR uses **MADR** (Markdown Any Decision Record). Copy `docs/adr/template.md`. Sections: title, status, context & problem, decision drivers, considered options, decision outcome, consequences (good and bad), links.

**Decision & trade-off:** MADR over Nygard's leaner 4-section form. Trade-off: MADR is heavier per ADR. Chosen because recording the **considered options and their trade-offs** is the point for a proof-of-engineering product — the rejected paths are half the argument. Nygard's form drops them.

## Two libraries — methodology vs product
| Library | Lives in | Records |
|---|---|---|
| **Methodology** | `tadeumendonca-skills/docs/adr/` | decisions about the *machine* — the dev-loop, the roster, the gates, this practice itself |
| **Product** | the consuming repo's `docs/adr/` (e.g. `tadeumendonca-io/docs/adr/`) | decisions about the *product* — its architecture, stack, infra, UX |

This skill (the template + practice) is single and lives in the plugin; both libraries consume it.

**Decision & trade-off:** two libraries, not one. Trade-off: a reader consults two places, and a decision that is half-methodology half-product needs a judgment call on where it lands (rule of thumb: does it constrain *this product* or *any project using the plugin?*). Chosen because the plugin is reused across projects — folding product decisions into it would leak one project's choices into every consumer.

## Numbering & status
- **Numbering:** zero-padded sequential **per library** (`0001`, `0002`, …). Filename `NNNN-kebab-title.md`.
- **Status lifecycle:** `proposed → accepted → superseded` (or `rejected`). A design starts `proposed`; the human's ratification makes it `accepted`.
- **Superseding, never deleting:** a reversed decision becomes `superseded`, keeps its file, and links forward to the ADR that replaced it. Reverted decisions are **history, not gaps** — the record of *why we changed our mind* is as valuable as the current state. (This is why the exhaustive reverse-engineering of past decisions includes the retired backend era as `superseded`.)

## Authoring checklist
- [ ] One decision per ADR. If you're recording two, write two.
- [ ] The **considered options** section is real — at least the chosen path and the strongest rejected alternative, each with its trade-off.
- [ ] Consequences list the **bad** ones too, not only the wins. An ADR with no downsides is not honest.
- [ ] Links back to the driving Issue/spec and to any ADR it supersedes or depends on.
- [ ] Committed **in the same MR** as the change it justifies (no decision drift — the docs move with the code).

## Pros & cons of this practice
**Pros**
- Durable decision memory that a fresh per-task context can load → the anti-drift substrate.
- The rejected options are recorded → future changes see *why* a path was not taken and don't relitigate it.
- Light gate keeps the practice cheap; ADRs stay meaningful, not ceremonial.

**Cons**
- Discipline cost: an ADR per significant decision is work, and the significance test needs judgment.
- Two libraries add a lookup and an occasional "where does this belong?" call.
- MADR is verbose; a trivial-but-significant decision can feel over-documented.
