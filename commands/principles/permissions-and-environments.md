Apply the platform's environment and permission model in any <project> repo — both at the global Claude Code level and per-project. This is the mechanical encoding of the "agent-led verification, human-residual" boundary (`/principles/verification-and-gates`): pre-authorize everything the agent owns, gate exactly at the irreversible/production line.

Context: $ARGUMENTS

## Environments are decided by git branch
`develop` → staging, `main` → production. **The pipeline deploys on merge; the agent never deploys.** Locally there is only ever **staging** — so "production" is not a command argument (no AWS profile/workspace to parse), it is the **act of getting code onto `main`**. This makes the boundary visible in the command string itself (`git push origin main`, `gh pr merge --base main`), which is what makes it enforceable.

## IaC is pipeline-only, and infra comes first
Terraform never runs on a laptop — `plan` on the PR, `apply` on merge, in CI only. Two consequences:
- Local infra-mutation is enforced trivially: `terraform apply`/`destroy` simply never run locally.
- **Infra-first ordering:** because the local app depends on staging infra *existing*, the build order is **infra (staging) → app**. A capability needing new infra ships its **IaC slice first** (PR → pipeline applies to staging); only then can the app slice be developed and validated locally against it. This is a real dependency edge in the loop — app work that needs new infra is blocked until the infra is live in staging.

## Local development is staging-backed (and necessarily partial)
The local backend runs against **staging's backing infra** (database and dependencies) via the parameter-store bus under the staging namespace — local app process + real staging backing services, **no local/air-gapped infra stack**. This is a deliberate choice: one real environment that contemplates all layers, no parallel local-infra to maintain, no fidelity gaps in the backing services. It implies the laptop holds **staging credentials**; **production credentials are never on the laptop** (production is unreachable by construction).

Local validation is **necessarily partial** — the complete stack is never testable locally: real auth *flow* (hosted UI / social login), email delivery, and edge (Lambda@Edge / CDN routing & cache) have no faithful local equivalent. Local exercises the **domain surface** (and validates **real staging auth tokens**, since it points at the real staging user pool); **staging owns completeness** — the post-deploy E2E + API run is where real login, email, and edge are validated end-to-end. So an agent proves the local-testable part locally and reports that complete validation happens at the staging run.

## The tolerance test: git-reversibility
In a low environment, **anything tracked and reversible via git is tolerable**. The danger is never "low env" — it is **irreversibility that escapes git**: cloud/infra state, remote refs on protected branches, secrets, production. So:
- **Effect contained in the git-tracked tree** (Edit/Write, code, local tests) → git reverts it → **allow freely**.
- **Effect that escapes git** (cloud mutation, applied infra, protected-branch ref, secrets, production) → **gate**.

## Permission zones
| Zone | Contents |
|---|---|
| **Allow** (agent-owned, no prompt) | Edit/Write · git on feature branches (status/log/diff/add/commit/checkout/switch/branch/fetch/pull/restore/stash/push) · `gh pr` create/view/diff/checks + **merge to `develop`** · issue ops · npm/npx (install, lint, typecheck, test, build, dev) · Playwright + newman · node/tsx/python3 · `terraform fmt/validate/plan` · `aws` **read-only** (describe/list/get) · curl local |
| **Ask** (case-by-case) | `gh pr merge --base main` (promotion) · the release action (tag / `workflow_dispatch`) |
| **Deny** (never by the agent) | push/merge to `main` · `terraform apply`/`destroy` · direct `aws` mutations · `--force` / `git reset --hard` · `rm -rf` · secrets writes · anything targeting production/`prd` · `--dangerously-skip-permissions` |

Direct cloud mutation is denied entirely: writes to staging happen **through the running app** (the local BFF), never via `aws` CLI; writes to anything else happen through the **pipeline**.

## Two layers — global and per-project
- **Global** (`~/.claude/settings.json`): the universal **floor** — deny the always-forbidden (`apply`/`destroy`/`--force`/`rm -rf`/secrets/`*prod*`/`--dangerously-skip-permissions`) and register the guard hook. Protects every repo, even one with no local config.
- **Per-project** (committed `.claude/settings.json`): the **inner-loop allow** for that repo's stack, plus the plugin. Permissions are a **versioned repo contract** — they live in the committed `settings.json`, not `settings.local.json` (which holds only per-machine items such as credential paths). In the settings merge, **deny from any layer wins**, so the global floor is inescapable and the project layer only adds autonomy.

**Never `--dangerously-skip-permissions`** — it erases the entire boundary. The allowlist is curated, not bypassed.

## Enforcement = static deny + a guard hook
- **Static allow/deny** covers the cases where the target is visible in the command string — protected-branch operations and the universal irreversibles. This is most of it, because the environment boundary is branch-based.
- **A `PreToolUse` guard hook** is the backstop for what patterns can't see — chiefly **current-branch context**: block write/commit/push while `main` is checked out, and block any local `terraform apply`/`destroy`. It reads the git branch + the command; it does **not** need to parse cloud profiles (the branch-based model removed that complexity). The plugin ships this hook so every consuming repo inherits identical enforcement.

## Why this doesn't cost cadence
Strong local validation is the keystone: the agent proves "done" locally (run fed + bff against staging infra, run E2E + API, self-verify the gates) **without ever needing the denied boundary**. So the production/cloud deny costs ~zero velocity — it only blocks what the agent should never touch. The cadence comes from the local loop; the boundary protects production. Cut local validation and you'd be forced to either loosen the boundary (risky) or gate everything (slow) — both break cadence. Keep local validation strong and the boundary stays tight for free.
