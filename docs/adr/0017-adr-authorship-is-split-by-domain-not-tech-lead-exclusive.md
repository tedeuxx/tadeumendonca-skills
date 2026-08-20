# 0017. ADR authorship is split by domain — `tech-lead` writes product/system records, `harness-lead` writes loop/machinery records

- **Capability:** decision-library
- **Status:** accepted
- **Date:** 2026-08-13
- **Deciders:** the owner, decided directly in conversation, 2026-08-13; recorded here per this record's
  own bootstrapping note below
- **Supersedes / superseded by:** —
- **Driven by:** [#223](https://github.com/tedeuxx/tadeumendonca-skills/issues/223)

## Context & problem

`agents/tech-lead.md` stated `tech-lead` as the sole ADR author for both libraries — product/system
architecture and the plugin's own methodology — regardless of which persona actually held the decision
being recorded. `docs/adr/README.md`'s own row for record 0012 already named the cost this caused, unprompted:
*"the `README.md` diagram correction owed (`loop` needs to route to both `harness-lead` and `tech-lead`,
not the single edge drawn today, since `tech-lead` is the sole ADR author and `loop` issues are the ones
most likely to produce one)"*. Routing followed authorship, not stake — a `loop`-typed decision pulled
`tech-lead` into intake it had no real stake in, purely because it was the only persona wired to write
the record at all.

This directly contradicts a principle already stated elsewhere in this repo (`CLAUDE.md`'s "Absorbed
rather than retired" section): *"whoever holds the decision writes its record."* The coupling was a
drift from that principle, not an application of it.

## Decision drivers

- **Authorship should follow who holds the decision, not default to one persona regardless of domain.**
- **Mechanically, nothing blocks this.** `agents/harness-lead.md`'s tool grant (`Read, Grep, Glob, Bash,
  Write, Edit`) is already unscoped and identical in shape to `tech-lead`'s, from record 0015 — now
  [ADR-0002](./0002-roster-and-dev-loop.md)'s *`harness-lead` implements the harness it reviews
  (absorbed 2026-08-20, record 0015)* section. `docs/adr/**`
  is already reachable. What was missing was brief language, not permission.
- **A decision that straddles both domains needs a resolution that doesn't require a fight each time.**
  Record 0015's own header already modelled the shape: `Deciders: the owner; written by tech-lead;
  pre-implementation stress test by harness-lead` — joint involvement, one named author, decided per
  case.

## Considered options

1. **Split by domain** *(chosen)* — `tech-lead` authors ADRs for product/system-architecture decisions,
   including methodology decisions with product-architecture consequence; `harness-lead` authors ADRs
   for pure loop/harness/machinery decisions. *Trade-off:* a straddling decision has no mechanical rule
   deciding the author — resolved case by case via co-citation in the `Deciders` line, which is a real,
   accepted ambiguity, not a solved one.
2. **Keep `tech-lead` as sole author, fix only the routing table that cited it as the reason.** *Why
   not:* this treats the symptom (a stale diagram/routing edge) without touching the cause (authorship
   not following stake) — the next `loop`-typed decision would reproduce the same pull toward `tech-lead`
   for the same reason.
3. **Give every persona ADR-authoring capability for its own domain (`product-lead`, `developer`,
   `quality-assurance` too).** *Why not:* no evidence any of those three actually originate
   architecturally-significant decisions of their own that aren't already covered by `product-lead`'s
   advisory-only role or `quality-assurance`'s gate role — inventing authorship capability for a class of
   decision that doesn't exist yet is exactly the shape this repo's own reviewer is instructed to be
   suspicious of.

## Decision outcome

Chosen: **option 1.** `tech-lead` and `harness-lead` each author ADRs for the decisions they hold,
verbatim per the domain split stated above. Both briefs (`agents/tech-lead.md`, `agents/harness-lead.md`)
and the `adr` skill (`skills/workflow/adr/SKILL.md`) are updated in the same slice as this record, per
this repo's own rule that a decision and the record of it land together.

## Consequences

**Good**
- `loop`-typed intake no longer pulls `tech-lead` in by default — a real fix to the routing cost
  record 0012's own row already named, not just a corrected diagram.
- `harness-lead` gains the `adr` skill in its preload (a narrow, deliberate second exception to its
  otherwise-empty `skills:` list, alongside `harness-engineering`) — it is a format/process standard, not
  a description of `harness-lead`'s own machinery, so it does not reopen the staleness concern that keeps
  the rest of that list empty.

**Bad / accepted costs**
- **A straddling decision has no mechanical resolution**, only a convention (co-citation in `Deciders`).
  This is named explicitly rather than solved, per #223's own scope — inventing a rule for a case that
  hasn't happened yet risks getting it wrong in the abstract.
- **Role-stacking compounds further for `harness-lead`.** It already stacks proposer/reviewer (ADR-0004)
  and implementer (record 0015) on harness changes it reviews; authoring the justifying ADR for its own
  harness change adds a third role on the same object. Accepted, same shape as that record's own accepted
  cost, not newly introduced by this record — named here so it isn't silently inherited.
- **Not verified**: whether any `tadeumendonca-io` product-library ADR was ever authored by anyone but
  `tech-lead` — outside this record's read scope (a different repo); a clean precedent there would
  strengthen this decision's case but its absence doesn't weaken it, since the product library's author
  convention is unaffected by this record (it only touches the methodology-library authorship split).

## Bootstrapping note

Under the rule this record itself establishes, this ADR — a pure loop/machinery decision about the
harness's own authorship convention — is `harness-lead`'s to write. It was instead authored directly by
the owner and the orchestrating session while the plugin was temporarily disabled for a batch of
self-referential harness changes (2026-08-13), with no `harness-lead` persona dispatched. Recorded here
per this Issue's own instruction: whichever persona (or, in this case, no persona) drafts a record that
exercises the authority it is granting, say so explicitly rather than let it pass silently.

## Links

- [#223](https://github.com/tedeuxx/tadeumendonca-skills/issues/223) — the Issue this record closes.
- [ADR-0002](./0002-roster-and-dev-loop.md) — the capability document that absorbed records 0012 and
  0015 on 2026-08-20. Its *`harness-lead` implements the harness it reviews (absorbed 2026-08-20,
  record 0015)* section is the `Deciders`-line co-citation shape this record reuses for straddling
  decisions; its *Issue type is the routing axis, and it is exclusive (absorbed 2026-08-20, record
  0012)* section is the routing decision whose own index row named the authorship-coupling cost this
  decision corrects.
- `agents/tech-lead.md`, `agents/harness-lead.md`, `skills/workflow/adr/SKILL.md` — updated in the same
  slice as this record.
