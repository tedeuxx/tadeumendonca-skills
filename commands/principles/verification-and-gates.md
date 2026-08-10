---
description: Define what done means and the mechanical gates that prove it — the Definition of Done, the 100% functional-regression invariant, local validation, and the gate table per loop model. Use when deciding whether a slice is shippable, calibrating gates to blast radius, or arguing that a green check is not evidence. Not for the concrete gate list and thresholds (see backend/coverage) or the author's own pre-merge pass (see workflow/code-review).
---

Apply the platform's verification model and deploy gates in any `<project>` repo. This defines what "done" means and the mechanical gates that prove it — the enforcement half of the principles layer (`/principles/engineering-philosophy` is the judgment half; `/principles/dev-loop` is the flow).

Context: $ARGUMENTS

## The thesis: agent-led verification, human-residual
The point of this model is that **agents perform the majority of verification and humans are left only the residual.** Every gate below is objective and mechanical *on purpose* — so an agent can prove "done" by itself, and a human's scarce attention goes only to what can't be automated with confidence: irreversible/architectural judgment and the final go/no-go.

**Trust comes from the harness, not the agent's word.** For this to hold, verification must be *enforced by the machine* — hooks and CI required checks that actually run and block — never accepted as the agent's self-report. An agent can hallucinate a green check; a required check cannot. So the agent **reports with real evidence** (actual command output) and the **hook / CI is the source of truth**. If a gate is only "the agent said it ran," the human residual silently grows back, because now someone has to check whether it really verified. Keep the gates inescapable and mechanical.

## Definition of Done (a slice is "done" only when all hold)
- Unit/integration tests written alongside the code, **coverage ≥ 85%**, green.
- **Regression added for the feature** (see the invariant below).
- Lint + typecheck clean.
- **Observability instrumented for the new behavior** — in whatever form this repo's runtime actually supports (see below).
- Security/resilience posture applied (least-privilege, idempotency, fail-fast/open, retries).
- **Docs/Mermaid updated**; debt (if any) named in the review — the owner decides whether it becomes an issue.
- **Conventional-commit** subject (the commit log is the changelog).
- **Validated locally.**

Anything short of all of these is in-progress, not done.

## The regression invariant — 100% functional coverage
The regression suite must **functionally cover 100% of the repo's implemented features** — not a representative sample. Every feature that ships adds its own regression; the collective suite is the proof that *nothing already working broke*. This is the one gate that does **not** bend to blast-radius — it is the floor that lets the platform be evolved incrementally without fear. A change that adds behavior without its regression breaks the invariant and is not done.

**Which suites this means is per repo.** E2E (browser) always, where there is a UI. An **API/contract suite only where an API exists.** Demanding coverage of a surface the repo does not have is not rigor — it is an unsatisfiable gate, and an unsatisfiable gate teaches the agent to fabricate evidence or quietly skip the check. Read the repo, then name the suites.

**Observability is scoped the same way.** "Instrumented" means structured logs, metrics and tracing where there is a server to emit them; for a static frontend it means analytics, the client-side error surface, and a build/prerender smoke. Neither is a lesser standard — both must prove the change is working where it runs.

## Local validation (before anything ships)
Development is validated **locally and automatically before the deploy** — not by a manual click-through:
- Run the repo's **regression against the local environment**. The suite is multi-env by design: it runs locally now and against the deployed environment post-deploy.
- What "locally" requires depends on the loop model — a static repo runs fully offline; a repo with backing services points at them per `/principles/permissions-and-environments`.
- "The regression passes locally" is the concrete pre-deploy gate.

## Gates — calibrated to blast-radius
The gate set is the same; **where it sits** follows the loop model (`/principles/dev-loop`). The organizing rule: **the heavy gates sit at the point of no return.**

### `gitflow-multi-env`
| Gate | Staging (merge → integration branch) | Production (promote → release branch) |
|---|---|---|
| Coverage (≥85%) | **required** | required |
| Static analysis / quality gate | **required** | required |
| Security (dependency audit / SAST) | **required** | required |
| Lint + typecheck | — | required |
| **Full regression** | runs (local pre-push + staging post-deploy); not a merge-blocker *into* staging | **required, blocking check on the promotion PR** |
| Human review + branch protection | — | required |
| Version bump label | — | required (drives tag + Release) |
| **Manual approval** | — | **required — promotion always asks** |

Staging stays light so integration is fast and cheap to revert. Production layers on the heavy gates because it's expensive and irreversible — the green staging regression is the prerequisite that makes the promotion safe.

### `trunk-single-env`
| Gate | PR → `main` (the only gate) |
|---|---|
| Coverage (≥85%) | **required** |
| Static analysis / quality gate | **required** |
| Security (dependency audit / SAST) | **required** |
| Lint + typecheck | **required** |
| **Full regression** | **required, blocking** |
| Human review + branch protection | required |
| Version bump | on merge (auto-bump + tag + Release) |
| **The gatekeeper approves** | **required, every MR — `quality-assurance`, holding both lenses in one pass: was every requirement of the issue met, and can this cause a problem in production. It absorbed the `security` persona on 2026-08-04; the second question did not go away, it stopped being a second dispatch** |
| **Merge asks a HUMAN** | **only for the boundary class** — see below |

There is no downstream tier to defer to, so **nothing is deferred**: a gate skipped on this PR is a gate that never runs. This is not a heavier model than `gitflow-multi-env` — it is the same total rigor, collapsed onto one hop.

**The merge is the go/no-go; that is not the same as the merge always asking a human.** This table used to read *"Merge asks — required"*, which contradicted `quality-assurance`'s own definition and made an agent's conclusion depend on which file it happened to read (#62). The merge needs a **judgement**; who supplies it is set by the class. `quality-assurance` merges the **safe** class itself once both of its lenses are green; it never merges the **boundary** class — infrastructure and anything threatening continuity, a change to the loop's own rules, publishing in the owner's voice — and never merges an expansion of its own authority. When the class is unclear, it is boundary.

(Infrastructure repos, both models: format + validate + policy scan + a reviewed plan; apply only on merge, pipeline-only.)

## Post-deploy verification
A deploy isn't finished at "merged." After it lands — every environment it lands in — **run a smoke and confirm health through the repo's observability** before considering it complete. This closes the loop with "observability is part of done": the proof a change works is that you can *see* it working where it runs.

## Where enforcement lives
- **Hooks** (deterministic, fire on every relevant action): fast local feedback — formatting, lint-on-edit, guardrails. Shipped close to the agent.
- **CI required checks** (the blocking source of truth): coverage, quality gate, security, and the regression — on the promotion PR under `gitflow-multi-env`, on the PR to `main` under `trunk-single-env`. These are what actually gate merges; the agent's job is to make them green and report the evidence, not to *be* the gate.
- **Pipelines are independent per repo** — never trigger one repo's pipeline from another.

The agent's contract: self-verify against these locally, show the real output, and only hand the human the residual — the judgment calls and the go/no-go.
