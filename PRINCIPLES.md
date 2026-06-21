# Engineering principles — the drift-reducer

The canonical, concise statement of how the owner builds software. This is the **principles layer** of the `tadeumendonca-skills` plugin: the part of the harness that keeps an agent's behavior aligned with the owner's engineering judgment so output doesn't drift. It is the summary; the four `/principles/*` skills carry the full detail.

> **For consumers (`<project>` repos):** see *Wiring* at the bottom — enable the plugin (the permission guard hook activates automatically) and surface this file's floor in your repo so it's always in context.

## The spine
**Agent-led verification, human-residual.** Agents do the majority of verification; the human is left only the residual. Every gate is objective and mechanical so an agent can *prove* "done" itself. The human's attention is reserved for what can't be reliably automated — irreversible/architectural judgment and the production go/no-go. Trust comes from the harness (hooks + CI), never from the agent's word.

## Two tiers
- **Non-negotiable floor** (never bends to risk): quality gate (tests + coverage + lint/typecheck + review), **100% functional E2E + API regression**, observability, security/resilience by-design. The floor is what lets the platform be evolved incrementally without fear.
- **Calibrated judgment** (scales to blast-radius): planning depth, threat-model depth, abstraction, when to ask. Heavy where irreversible/production; product-speed where cheap to revert.

## The principles
1. **Plan-first** — design and align before coding (Plan mode by default).
2. **Ask on the boundaries** — architecture, contracts (API/schema), irreversible; decide autonomously on in-pattern implementation. Never a solo architectural call.
3. **Thin vertical slices, WIP = 1** — each increment end-to-end and reviewable; finish one before the next.
4. **Surgical changes, tracked debt** — focused edits; work around adjacent mess and file the debt (no boy-scouting).
5. **Simple but extensible** — the deliberate middle; abstraction must pay for itself.
6. **No dogma — the tool follows the problem** — honor a platform's conventions as its context; the principle is adaptability.
7. **Rigor calibrated to blast-radius** — the dial; the floor is what it never turns below.
8. **Quality is a gate** — tests + coverage + 100% regression + lint/typecheck + review.
9. **Observability is part of done** — logs + metrics + tracing proving prod behavior; smoke after deploy.
10. **Security & resilience by-design** — least-privilege, idempotency, fail-fast/open, retries, light threat-modeling.
11. **Living docs** — Mermaid + markdown for architecture/decisions, kept current.

## The loop (deployed-app repos)
`roadmap/PLAN.md → thin slice → develop locally (BFF → staging infra) → validate locally (E2E + API) + self-verify gates → /code-review → PR → integration branch (staging: coverage + quality + security) → promote → release branch (full regression + review + manual approval) → production`. Failure → revert the merge + re-release. Environment = git branch; IaC pipeline-only, **infra-first**; local is staging-backed and **necessarily partial** (real auth flow, email, and edge are validated only at staging).

## Permissions — autonomy without losing the blast radius
Pre-authorize the entire inner loop (git-reversible / staging-scoped) so the agent works without constant prompts; **deny** the irreversible/production boundary (push/merge to the release branch, `terraform apply/destroy`, direct cloud mutation, force-push, `rm -rf`, secret writes, production); never `--dangerously-skip-permissions`. Permissions are a **versioned repo contract** (committed `settings.json`, not `settings.local.json`), layered **global floor + per-project**. Control comes from reversibility + mechanical gates + the deny boundary — not from interrupting you.

## Full detail
- `/principles/engineering-philosophy` — the principles and the two tiers.
- `/principles/verification-and-gates` — the thesis, Definition of Done, the 100% regression invariant, gates by environment.
- `/principles/dev-loop` — the end-to-end flow.
- `/principles/permissions-and-environments` — environment model, local dev, the permission zones, and the guard hook.

## Wiring (consumers)
1. **Enable the plugin** in `.claude/settings.json` (`enabledPlugins`). The **PreToolUse permission guard hook activates automatically** — every repo inherits the irreversible-floor enforcement with no extra setup.
2. **Add the repo's permission contract** to the committed `.claude/settings.json` (`permissions.allow` for the inner loop; `permissions.deny` for that repo's branch/production boundary — e.g. push/merge to the release branch). Versioned, not `settings.local.json`.
3. **Surface the principles always-on:** reference this floor in the repo's own `CLAUDE.md` (the always-loaded context) and link the `/principles/*` skills for depth. For deliberate validation of a non-trivial decision, invoke the **`principles-guide`** subagent.
