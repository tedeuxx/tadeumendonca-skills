# Agentic dev-loop — the design, harness-agnostic

**Superseded 2026-08-14 (#261).** README.md is now the single source of truth for the dev-loop
documentation — its own state machine, roster, gate model, intake formalism, Definition of Done and
portability notes. This file's content was merged there rather than kept as a second, parallel source;
see [ADR-0019](./adr/0019-readme-is-the-single-source-of-truth-for-the-dev-loop.md) for the record of that
decision.

This file is kept as a redirect, not deleted, for one reason: anyone who bookmarked or linked the old
canonical URL below deserves to land somewhere that says what happened, rather than a 404. That is the
reason ADR-0019 gave and it is unaffected by #281, which replaced this platform's deletion convention for
**ADR records** — a class this file is not in.

**Read the current, canonical version at:**
<https://github.com/tedeuxx/tadeumendonca-skills/blob/main/README.md>

Sections that used to live here now live there, roughly in this order: *One of three pillars* → *The
problem* → *How it works* / *The engineering floor* (§1 of the old design) → *The roster, and what each
tier holds* / *What the model buys, and what it costs* (§2) → *Intake formalism is what buys the gate its
objectivity* / *The lifecycle* (§3) → *The Definition of Done, and when a finding earns the right to
block* (§4) → the branch-model section under *The branch model the loop runs on* / `/devops` (§5, §8) →
*The hooks, and what they refuse* (§6) → *The decision records are a contract, not documentation* (§7) →
*What travels if this design moves to another harness* (§9, the essential/incidental/known-weak split).

**The methodology ADR library (`docs/adr/`) remains the authoritative record of individual decisions.**
Where the README and an ADR disagree, the ADR wins — that has not changed.
