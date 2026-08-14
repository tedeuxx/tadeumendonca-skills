---
description: Define what done means AND the concrete, stack-agnostic gate policy that proves it — the Definition of Done, the 100% regression invariant, the gate table per loop model, plus thresholds (lint/typecheck at zero, coverage ≥85%, contract/E2E, dependency + secret scanning, SAST). Use when deciding if a slice ships, calibrating gates, or wiring a gate into CI. Not for the pre-merge pass (see code-review) or Sonar mechanics (see devops).
---

# Quality gates — the definition of done and the concrete policy that proves it

Apply the platform's verification model and deploy gates in any `<project>` repo. This defines what "done" means and the mechanical gates that prove it — the enforcement half of the principles layer (`/harness-engineering` carries the judgment and the flow).

**Two bodies of content, kept legible as two sections rather than blended (#257).** Part I is the
*definition* of done — the thesis, the DoD, the 100% functional-regression invariant, the gate table
per loop model. Part II is the *concrete, stack-agnostic policy* that satisfies it — the actual
thresholds, and what each check is for. They were split into two skills at #230 specifically so
`quality-assurance` could preload the concrete policy independent of stack; the split was folded back
into one file at #257, on the owner's call, once the two skills sat next to each other under
near-identical names (`quality-gates` next to `coverage`, whose own doc already opened "# Quality
gates") — a naming collision, not a judgment that the two kinds of content were the same thing. Read
Part I for *what counts as done*; read Part II for *the numbers and checks that prove it*.

Context: $ARGUMENTS

## Part I — What "done" means (the definition)

### The thesis: agent-led verification, human-residual
The point of this model is that **agents perform the majority of verification and humans are left only the residual.** Every gate below is objective and mechanical *on purpose* — so an agent can prove "done" by itself, and a human's scarce attention goes only to what can't be automated with confidence: irreversible/architectural judgment and the final go/no-go.

**Trust comes from the harness, not the agent's word.** For this to hold, verification must be *enforced by the machine* — hooks and CI required checks that actually run and block — never accepted as the agent's self-report. An agent can hallucinate a green check; a required check cannot. So the agent **reports with real evidence** (actual command output) and the **hook / CI is the source of truth**. If a gate is only "the agent said it ran," the human residual silently grows back, because now someone has to check whether it really verified. Keep the gates inescapable and mechanical.

### Definition of Done (a slice is "done" only when all hold)
- Unit/integration tests written alongside the code, **coverage ≥ 85%**, green (the concrete threshold and what counts as proof beyond the unit line is Part II below).
- **Regression added for the feature** (see the invariant below).
- Lint + typecheck clean.
- **Observability instrumented for the new behavior** — in whatever form this repo's runtime actually supports (see below).
- Security/resilience posture applied (least-privilege, idempotency, fail-fast/open, retries).
- **Docs/Mermaid updated**; debt (if any) named in the review — the owner decides whether it becomes an issue.
- **Conventional-commit** subject (the commit log is the changelog).
- **Validated locally.**

Anything short of all of these is in-progress, not done.

### The regression invariant — 100% functional coverage
The regression suite must **functionally cover 100% of the repo's implemented features** — not a representative sample. Every feature that ships adds its own regression; the collective suite is the proof that *nothing already working broke*. This is the one gate that does **not** bend to blast-radius — it is the floor that lets the platform be evolved incrementally without fear. A change that adds behavior without its regression breaks the invariant and is not done.

**Which suites this means is per repo.** E2E (browser) always, where there is a UI. An **API/contract suite only where an API exists.** Demanding coverage of a surface the repo does not have is not rigor — it is an unsatisfiable gate, and an unsatisfiable gate teaches the agent to fabricate evidence or quietly skip the check. Read the repo, then name the suites.

**Observability is scoped the same way.** "Instrumented" means structured logs, metrics and tracing where there is a server to emit them; for a static frontend it means analytics, the client-side error surface, and a build/prerender smoke. Neither is a lesser standard — both must prove the change is working where it runs.

### Local validation (before anything ships)
Development is validated **locally and automatically before the deploy** — not by a manual click-through:
- Run the repo's **regression against the local environment**. The suite is multi-env by design: it runs locally now and against the deployed environment post-deploy.
- What "locally" requires depends on the loop model — a static repo runs fully offline; a repo with backing services points at them per `/devops`.
- "The regression passes locally" is the concrete pre-deploy gate.

### Gates — calibrated to blast-radius
The gate set is the same; **where it sits** follows the loop model (`/harness-engineering`). The organizing rule: **the heavy gates sit at the point of no return.**

#### `gitflow-multi-env`
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

#### `trunk-single-env`
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

### Post-deploy verification
A deploy isn't finished at "merged." After it lands — every environment it lands in — **run a smoke and confirm health through the repo's observability** before considering it complete. This closes the loop with "observability is part of done": the proof a change works is that you can *see* it working where it runs.

### Where enforcement lives
- **Hooks** (deterministic, fire on every relevant action): fast local feedback — formatting, lint-on-edit, guardrails. Shipped close to the agent.
- **CI required checks** (the blocking source of truth): coverage, quality gate, security, and the regression — on the promotion PR under `gitflow-multi-env`, on the PR to `main` under `trunk-single-env`. These are what actually gate merges; the agent's job is to make them green and report the evidence, not to *be* the gate.
- **Pipelines are independent per repo** — never trigger one repo's pipeline from another.

The agent's contract: self-verify against these locally, show the real output, and only hand the human the residual — the judgment calls and the go/no-go.

## Part II — The concrete gate policy (stack-agnostic thresholds)

**Framework-agnostic, and stack-agnostic on purpose.** Where Part I says a slice must have "coverage
≥85%" and "the regression passes," this is the actual policy that satisfies those lines — the gate
list and the thresholds, specialized per stack only in the runner configuration, never in the number.
Originally extracted from the former `backend` family's `coverage` skill (#230) precisely so this
policy did not get pulled into the backend reference pattern (a BFF-on-Lambda architecture with no live
consumer) and so `quality-assurance` could preload it on every merge request regardless of which stack,
or whether either stack is even backend-shaped — folded into this file at #257 without losing that
independence, since it is now a section of the skill every reviewing persona already preloads rather
than a second file to preload alongside it.

CI **blocks deploy** if any gate fails — no artifact upload, no CDN invalidation, no function update.
IaC has its own gate (`checkov`, in `cloud-infrastructure`) and is not covered here.

**Quality — identical on both sides:** lint (zero errors), typecheck (zero type errors). No variation —
these are the cheapest gates in the set and the ones most often made advisory "for now".

**Test — one threshold, two kinds of proof.** **Unit coverage ≥ 85%** on lines/functions/branches/
statements, on **both** sides; below threshold blocks. The number is deliberately the same so neither
stack can argue it is the special case. Above the unit line the stacks diverge, because what counts as
*the behaviour actually working* differs — for this backend, that is unit/integration via vitest (see
the Framework section) plus an **API/contract run** — the Postman collection executed against a deployed
API: 401 without a bearer token, 200 with it, schema checks (see the Contract tests section). **Only
what exists is required** — a service with no browser surface owes no E2E journey, but the row that
*does* apply is blocking, and "not applicable" is a claim to be checked once, not a default answer.

**Security — same four checks, different location for the secret.** Dependencies: block on
high/critical advisories, dependency review and automated update PRs. SAST + quality gate: the
SonarCloud Quality Gate blocks merge and imports the unit-coverage lcov, so SAST, coverage and smells
are judged together — see `devops` for the mechanics of that import. Secrets: secret scanning,
nothing sensitive committed — on the server a sensitive value is fetched at runtime from a secret store
(see the Secrets section); in a browser bundle there is no such place at all, so client configuration is
non-secret by construction (see the Config section). Automated review: an automated code-review action
on every pull request, advisory rather than blocking.

**Conventions:** do not lower a threshold to go green — fix the gap; an assertion that cannot fail is
worse than no assertion (coverage counts lines executed, not behaviour verified).

### Decision & trade-off
- **One threshold across both stacks, rather than tuning each.** *Why:* a per-stack number invites the
  argument every time a suite is inconvenient. A single shared number converts a recurring negotiation
  into a one-time decision. *Trade-off:* it is arbitrary for at least one of the two stacks, and it will
  occasionally be too strict for glue code and too lax for a core module.
- **Gates block the deploy rather than warn.** *Why:* an advisory gate is a gate that is red on the day
  it matters and has been red for weeks. *Trade-off:* a flaky suite can stop a correct change, so
  flakiness has to be treated as a defect in the gate rather than a cost of having one.
- **Coverage is imported into the SAST gate rather than checked separately.** *Why:* one verdict, one
  place to look, smells cannot be traded off against coverage silently. *Trade-off:* an outage or
  misconfiguration in that one service blocks every merge.
- **This policy folded into `quality-gates` rather than staying a standalone `coverage` skill (#257).**
  *Why:* the owner's call, made once the rename that produced `quality-gates` (#255) put it next to a
  near-identically-named skill. *Trade-off:* named and accepted at filing — the preload-independence
  rationale the extraction bought at #230 is now carried by this file being one preload rather than two,
  not by a separate file; see the note opening this Part for how that preload wiring was re-verified
  rather than assumed to still hold.

### Pros & cons (of the concrete policy)
**Pros:** deterministic merge gate, one policy, one place to change it; unit + contract + SAST together,
so a change that is covered but broken still fails; framework-agnostic — the policy survives changing
the runner.
**Cons:** an 85% threshold can incentivize trivial tests that raise the number and assert nothing; gates
add latency to every merge, including the ones that could not possibly break anything.
