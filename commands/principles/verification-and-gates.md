Apply the platform's verification model and deploy gates in any <project> repo. This defines what "done" means and the mechanical gates that prove it — the enforcement half of the principles layer (`/principles/engineering-philosophy` is the judgment half; `/principles/dev-loop` is the flow).

Context: $ARGUMENTS

## The thesis: agent-led verification, human-residual
The point of this model is that **agents perform the majority of verification and humans are left only the residual.** Every gate below is objective and mechanical *on purpose* — so an agent can prove "done" by itself, and a human's scarce attention goes only to what can't be automated with confidence: irreversible/architectural judgment and the final production approval.

**Trust comes from the harness, not the agent's word.** For this to hold, verification must be *enforced by the machine* — hooks and CI required checks that actually run and block — never accepted as the agent's self-report. An agent can hallucinate a green check; a required check cannot. So the agent **reports with real evidence** (actual command output) and the **hook / CI is the source of truth**. If a gate is only "the agent said it ran," the human residual silently grows back, because now someone has to check whether it really verified. Keep the gates inescapable and mechanical.

## Definition of Done (a slice is "done" only when all hold)
- Unit/integration tests written alongside the code, **coverage ≥ 85%**, green.
- **E2E + API regression added for the feature** (see the invariant below).
- Lint + typecheck clean.
- **Observability instrumented** — structured logs, metrics, tracing for the new behavior.
- Security/resilience posture applied (least-privilege, idempotency, fail-fast/open, retries).
- **Docs/Mermaid updated**; debt (if any) filed as an issue.
- **Conventional-commit** subject (the commit log is the changelog).
- **Validated locally** (next section).

Anything short of all of these is in-progress, not done.

## The regression invariant — 100% functional coverage
The **E2E + API suite must functionally cover 100% of the platform's implemented features** — not a representative sample. Every feature that ships adds its own E2E + API regression; the collective suite is the proof that *nothing already working broke*. This is the one gate that does **not** bend to blast-radius — it is the floor that lets the platform be evolved incrementally without fear. A change that adds behavior without its regression breaks the invariant and is not done.

## Local validation (before anything reaches staging)
Development is validated **locally and automatically before the staging deploy** — not by a manual click-through:
- Run the **E2E (browser) + API (contract) regression against the local environment**. The suite is multi-env by design: it runs locally now and against staging post-deploy.
- The **local backend runs against the staging environment's backing infra** (database and other dependent resources), reading config from the parameter-store bus under the staging namespace — i.e. local app process + remote staging backing services (no fully-local infra stack). This needs staging credentials on the machine.
- "Passes E2E + API locally" is the concrete pre-staging gate.

## Gates by environment — calibrated to blast-radius
| Gate | Staging (merge → integration branch) | Production (promote → release branch) |
|---|---|---|
| Coverage (≥85%) | **required** | required |
| Static analysis / quality gate | **required** | required |
| Security (dependency audit / SAST) | **required** | required |
| Lint + typecheck | — | required |
| **E2E + API regression** | runs (local pre-push + staging post-deploy); not a merge-blocker *into* staging | **required, blocking check on the promotion PR** |
| Human review + branch protection | — | required |
| Version bump label | — | required (drives tag + Release) |
| **Manual approval** | — | **required — promotion always asks** |

Staging stays light (coverage + quality + security) so integration is fast and cheap to revert. Production layers on the heavy gates because it's expensive and irreversible — the green staging regression is the prerequisite that makes the promotion safe, and a human approves the final step. (Infrastructure repos: format + validate + policy scan + a reviewed plan; apply only on merge, pipeline-only.)

## Post-deploy verification
A deploy isn't finished at "merged." After it lands (staging and production), **run a smoke and confirm health through observability** — logs, metrics, real-user monitoring, tracing — before considering it complete. This closes the loop with "observability is part of done": the proof a change works is that you can *see* it working in the environment.

## Where enforcement lives
- **Hooks** (deterministic, fire on every relevant action): fast local feedback — formatting, lint-on-edit, guardrails. Shipped close to the agent.
- **CI required checks** (the blocking source of truth): coverage, quality gate, security, and the regression on the promotion PR. These are what actually gate merges; the agent's job is to make them green and report the evidence, not to *be* the gate.
- **Pipelines are independent per repo** — never trigger one repo's pipeline from another.

The agent's contract: self-verify against these locally, show the real output, and only hand the human the residual — the judgment calls and the production go/no-go.
