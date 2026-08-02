# Engineering principles — the drift-reducer

The canonical, concise statement of how the owner builds software. This is the **principles layer** of the `tadeumendonca-skills` plugin: the part of the harness that keeps an agent's behavior aligned with the owner's engineering judgment so output doesn't drift. It is the summary; the five `/principles/*` skills carry the full detail — **`/principles/loop-engineering`** names the discipline the whole is (**Agent Harness Engineering / AI-DLC**, run with Claude Code & Kiro), and the other four are its parts.

> **For consumers (`<project>` repos):** see *Wiring* at the bottom — enable the plugin (the permission guard hook activates automatically) and surface this file's floor in your repo so it's always in context.

## The spine
**Agent-led verification, human-residual.** Agents do the majority of verification; the human is left only the residual. Every gate is objective and mechanical so an agent can *prove* "done" itself. The human's attention is reserved for what can't be reliably automated — irreversible/architectural judgment and the go/no-go on the irreversible act. Trust comes from the harness (hooks + CI), never from the agent's word.

## Two tiers
- **Non-negotiable floor** (never bends to risk): quality gate (tests + coverage + lint/typecheck + review), a **regression suite functionally covering 100% of implemented features**, observability, security/resilience by-design. The floor is what lets the platform be evolved incrementally without fear. It is a set of **properties** — which suites and which telemetry satisfy them is read from the repo, never assumed.
- **Calibrated judgment** (scales to blast-radius): planning depth, threat-model depth, abstraction, when to ask. Heavy where irreversible/live; product-speed where cheap to revert.

## The principles
1. **Plan-first** — design and align before coding (Plan mode by default).
2. **Ask on the boundaries** — architecture, contracts (API/schema), irreversible; decide autonomously on in-pattern implementation. Never a solo architectural call.
3. **Thin vertical slices, bounded by file overlap** — each increment end-to-end and reviewable. A second slice may start if it touches no file an open one touches; if it does, finish the first. The bound is overlap rather than a count: the goal is avoiding stacked PRs that rot into conflicts, and counting blocks disjoint work while doing nothing about the real risk.
4. **Surgical changes, tracked debt** — focused edits; work around adjacent mess and file the debt (no boy-scouting).
5. **Simple but extensible** — the deliberate middle; abstraction must pay for itself.
6. **No dogma — the tool follows the problem** — honor a platform's conventions as its context; the principle is adaptability.
7. **Rigor calibrated to blast-radius** — the dial; the floor is what it never turns below.
8. **Quality is a gate** — tests + coverage + 100% regression + lint/typecheck + review. (E2E where there's a UI; an API suite only where there's an API.)
9. **Observability is part of done** — the change is provable **where it runs** (logs + metrics + tracing with a server; analytics + client errors + build smoke for a static frontend); smoke after deploy.
10. **Security & resilience by-design** — least-privilege, idempotency, fail-fast/open, retries, light threat-modeling.
11. **Living docs** — Mermaid + markdown for architecture/decisions, kept current.

## The loop — two models
The shared spine: `roadmap/PLAN.md → thin slice (no file overlap with an open one) → develop locally → validate locally (the repo's regression) + self-verify gates → /workflow/code-review → PR`. What differs is only how the change is promoted, and **the heavy gates always sit at the point of no return**:

- **`gitflow-multi-env`** (more than one environment) — `PR → integration branch (staging: coverage + quality + security) → promote → release branch (full regression + review + manual approval) → production`. Environment = git branch; local is staging-backed and **necessarily partial** (real auth flow, email, and edge prove out only at staging). Failure → revert on the release branch + re-release.
- **`trunk-single-env`** (one branch, one destination — a single deployed environment, or an artifact released deliberately) — `PR → main`, and **that PR carries the entire gate** (lint + typecheck + coverage + quality + security + full regression, all blocking) because there is no downstream tier to defer to. The **merge to `main` deploys, so the merge is the go/no-go**; `main` is the working branch, not a protected mirror. Failure → revert on `main` + re-deploy.

IaC is **pipeline-only** and **infra-first** under both. Pick the model from the repo, not from these examples; absent an integration branch and a second environment, it is `trunk-single-env`.

## Permissions — autonomy without losing the blast radius
Pre-authorize the entire inner loop (git-reversible) so the agent works without constant prompts; **deny** the irreversible boundary (`terraform apply/destroy`, direct cloud mutation, force-push, `rm -rf`, secret writes) and **gate exactly at this repo's point of no return** — the promotion PR under `gitflow-multi-env`, the merge to `main` (or the release) under `trunk-single-env`. Never `--dangerously-skip-permissions`. Permissions are a **versioned repo contract** (committed `settings.json`, not `settings.local.json`), layered **global floor + per-project**. Control comes from reversibility + mechanical gates + the deny boundary — not from interrupting you.

## Full detail
- `/principles/loop-engineering` — **the discipline that names the whole (Agent Harness Engineering / AI-DLC)**: the AI-native loop treated as the engineered artifact — its cadence, its gates-as-a-system, and the harness itself. The other four are its parts.
- `/principles/engineering-philosophy` — the principles and the two tiers.
- `/principles/verification-and-gates` — the thesis, Definition of Done, the 100% regression invariant, the gate tables per loop model.
- `/principles/dev-loop` — the end-to-end flow, and how to tell which model a repo uses.
- `/principles/permissions-and-environments` — environment model, local dev, the permission zones per model, and the guard hook.

## Wiring (consumers)
1. **Enable the plugin** in `.claude/settings.json` (`enabledPlugins`). The **PreToolUse permission guard hook activates automatically** — every repo inherits the irreversible-floor enforcement with no extra setup.
2. **Add the repo's permission contract** to the committed `.claude/settings.json` — `permissions.allow` for the inner loop; `permissions.deny` for that repo's boundary, written **for its loop model** (push/merge to the release branch under `gitflow-multi-env`; direct push to `main`, with the merge asking, under `trunk-single-env`). Do not copy the other model's entries: they authorize branches that don't exist and leave the real boundary open. Versioned, not `settings.local.json`.
3. **Surface the principles always-on:** reference this floor in the repo's own `CLAUDE.md` (the always-loaded context) and link the `/principles/*` skills for depth. For deliberate validation of a non-trivial plan or decision, invoke the **`plan-reviewer`** subagent (the design-time review gate — it checks against the principles and the ADR library for drift).

