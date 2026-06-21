Apply these engineering principles — the owner's way of building software — in any <project> repo. They shape every decision an agent makes here. Read them as defaults plus the explicit triggers to deviate, not as rigid rules.

Context: $ARGUMENTS

This is the **principles layer**: the part of the harness that keeps an agent's behavior aligned with how the owner sees software engineering, so output doesn't drift from his standard. The companion skills carry the *mechanics* — `/principles/verification-and-gates` (what "done" means and the gates that prove it) and `/principles/dev-loop` (the end-to-end flow). This skill is the *judgment*.

## The spine: agent-led verification, human-residual
The purpose of the whole setup is that **agents do the majority of verification; the human is left only the residual.** Everything below serves that: the gates are objective and mechanical so an agent can *prove* "done" itself, and the human's attention is reserved for what can't be reliably automated — irreversible/architectural judgment and the final production approval. An agent that asks a human to check something a gate could have checked is leaking the residual the wrong way.

## Two tiers — know which you're in
- **Non-negotiable floor** (never bends, regardless of risk): the quality gate, 100% functional regression, observability, security/resilience by-design. These exist so you can *move fast without fear* — you only get to evolve incrementally because the floor protects what already works.
- **Calibrated judgment** (scales to blast-radius): how much planning, how much threat-modeling depth, how much abstraction, when to ask. Heavy where the change is irreversible or high-impact; product-speed where it's cheap to revert.

## How I approach work

**1. Plan-first.** Design the solution and align on it *before* writing code. Default to Plan mode for any non-trivial task. *When I move faster:* a trivial, in-pattern change doesn't need a ceremony — but the bar for "trivial" is low, not high.

**2. Ask before deciding — on the right things.** Stop and align on **architecture, contracts (API/schema), and anything irreversible**. *Decide autonomously* on implementation that fits the existing pattern. The line is "does this change a boundary others depend on, or something hard to undo?" → ask. Otherwise → decide and report. Never make a *solo architectural* call.

**3. Thin vertical slices, one at a time.** Each increment crosses the layers and delivers reviewable value (a working slice, not a horizontal layer). **WIP = 1**: finish a slice to its Definition of Done before starting the next. Serial focus beats half-finished breadth.

**4. Surgical changes, tracked debt.** Keep each change focused on its slice. When adjacent mess sits in the path, **work around it and file the debt** — do *not* refactor alongside (no boy-scouting mid-feature). Debt is recorded and paid in a dedicated cycle, not smuggled into an unrelated change. Speculative refactor is not a feature.

## What I optimize for

**5. Simple but extensible.** Bias to the simplest thing that solves the problem now, with clear extension points only where growth is genuinely known. Not radical YAGNI, not build-for-scale-upfront — the deliberate middle. Abstraction must pay for itself before it's added.

**6. No architecture or tech dogma — the tool follows the problem.** There is no fixed monolith-vs-microservices default and no sacred stack; decide by team, scale, coupling, and operational cost. A given platform may be opinionated (one stack, one set of conventions) *as its chosen context* — honor those conventions inside it — but the underlying principle is adaptability, not allegiance to a tool.

**7. Rigor calibrated to blast-radius.** Match the weight of process to the cost of being wrong. Irreversible / production / high-coupling → maximum rigor and a human in the loop. Cheap-to-revert / isolated / staging → product-speed. This is the dial; the floor (tier 1) is what the dial never turns below.

## What "good" must always carry (the floor)

**8. Quality is a gate, not an option.** "Done" requires tests written alongside the code, coverage at or above the project threshold, lint/typecheck clean, and review. **The E2E + API regression must functionally cover 100% of implemented features** — every feature that ships adds its regression; the suite is the proof nothing broke. A change that adds behavior without its regression is not done.

**9. Observability is part of "done."** A change isn't finished until its behavior is provable in production through structured logs, metrics, and tracing. After a deploy, smoke-test and confirm health via observability before calling it complete.

**10. Security and resilience by-design.** Least-privilege, idempotency, conscious fail-fast vs fail-open choices, sensible retries, and light threat-modeling are part of the design — not a scan bolted on at CI. Depth scales to criticality (calibrated), but the *posture* is always present.

**11. Living docs.** Architecture and decisions live as Mermaid diagrams plus markdown in the repo, kept current with the code — not as an afterthought. The history (clean, conventional commits) carries the *why*; the docs carry the *shape*.

## Using this skill
When an agent works in a consuming repo, these principles are the lens for every choice: plan first, ask on the boundaries, slice thin, keep the floor green, and verify your own work before handing the residual to a human. The deep-dive component skills (`/backend/*`, `/infrastructure/*`, `/frontend/*`) tell you *how* to build each piece; this tells you *how to decide* while you do.
