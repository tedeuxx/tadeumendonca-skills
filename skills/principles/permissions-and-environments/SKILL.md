---
description: Decide what an agent may do without asking, per loop model — the git-reversibility tolerance test, IaC as pipeline-only, the global and per-project layering, and what the guard hook actually enforces. Use when writing an allow or deny list, deciding whether an act is irreversible, or explaining why a command stops for a human. Not for the gates a finished change must pass (see verification-and-gates).
---

Apply the platform's environment and permission model in any `<project>` repo — both at the global Claude Code level and per-project. This is the mechanical encoding of the "agent-led verification, human-residual" boundary (`/verification-and-gates`): pre-authorize everything the agent owns, gate exactly at the irreversible line.

Context: $ARGUMENTS

## Pick the model first
Permissions encode where the irreversible line falls, so they follow the repo's loop model (`/dev-loop`). Determine it before writing a single allow/deny entry — an allowlist built for the wrong model pre-authorizes branches that do not exist and leaves the real boundary open.

| Model | Environments | The irreversible act |
|---|---|---|
| **`gitflow-multi-env`** | staging + production, integration branch | the **promotion** PR to the release branch |
| **`trunk-single-env`** | one deployed environment (or a consumed artifact) | the **merge to `main`** (or, for an artifact, the **release/tag**) |

**If the repo has no integration branch and one environment, it is `trunk-single-env`.** Do not assume otherwise from examples elsewhere in this library.

## The tolerance test: git-reversibility (both models)
**Anything tracked and reversible via git is tolerable.** The danger is never "low environment" — it is **irreversibility that escapes git**: cloud/infra state, remote refs on protected branches, secrets, live traffic. So:
- **Effect contained in the git-tracked tree** (Edit/Write, code, local tests) → git reverts it → **allow freely**.
- **Effect that escapes git** (cloud mutation, applied infra, protected-branch ref, secrets, a deploy) → **gate**.

This test is model-independent. What changes between models is only *which command* crosses the line.

## IaC is pipeline-only, and infra comes first (both models)
Terraform never runs on a laptop — `plan` on the PR, `apply` on merge, in CI only. Two consequences:
- Local infra-mutation is enforced trivially: `terraform apply`/`destroy` simply never run locally.
- **Infra-first ordering:** a capability needing new infrastructure ships its **IaC slice first** (PR → pipeline applies); only then can the app slice be developed and validated against it. This is a real dependency edge in the loop.

## `gitflow-multi-env`

**Environments are decided by git branch:** `develop` → staging, `main` → production. **The pipeline deploys on merge; the agent never deploys.** Locally there is only ever **staging** — so "production" is not a command argument (no AWS profile/workspace to parse), it is the **act of getting code onto `main`**. This makes the boundary visible in the command string itself (`git push origin main`, `gh pr merge --base main`), which is what makes it enforceable.

**Local development is staging-backed (and necessarily partial).** The local backend runs against **staging's backing infra** via the parameter-store bus under the staging namespace — local app process + real staging backing services, no local/air-gapped infra stack. The laptop holds **staging credentials**; **production credentials are never on the laptop** (production is unreachable by construction).

Local validation is **necessarily partial** — real auth *flow*, email delivery, and edge routing have no faithful local equivalent. Local exercises the **domain surface**; **staging owns completeness**, and the post-deploy run is where the rest is validated end-to-end.

| Zone | Contents |
|---|---|
| **Allow** (agent-owned, no prompt) | Edit/Write · git on feature branches · `gh pr` create/view/diff/checks + **merge to `develop`** · issue ops · npm/npx · the repo's test runners · node/tsx/python3 · `terraform fmt/validate/plan` · `aws` **read-only** · curl local |
| **Ask** | `gh pr merge --base main` (promotion) · the release action (tag / `workflow_dispatch`) |
| **Deny** | push/merge to `main` · `terraform apply`/`destroy` · direct `aws` mutations · `--force` / `git reset --hard` · `rm -rf` · secrets writes · anything targeting production/`prd` · `--dangerously-skip-permissions` |

Direct cloud mutation is denied entirely: writes to staging happen **through the running app**, never via `aws` CLI; writes to anything else happen through the **pipeline**.

## `trunk-single-env`

**There is one branch and one destination.** `main` is the **working** branch — the agent commits to feature branches and merges to `main`, and that merge deploys. So the boundary is not "which branch am I on", it is **the merge itself**, plus the universal irreversibles.

**Local development is whatever the repo actually is.** A static site develops fully locally with no credentials at all; a repo with backing services points at them the same way `gitflow-multi-env` points at staging. Do not assert a backing-service dependency the repo does not have — it invents setup steps and blocks work that would otherwise just run.

| Zone | Contents |
|---|---|
| **Allow** (agent-owned, no prompt) | Edit/Write · git on feature branches (including `push` of the feature branch) · `gh pr` create/view/diff/checks · issue ops · npm/npx · the repo's test runners · node/tsx/python3 · `terraform fmt/validate/plan` · `aws` **read-only** · curl local |
| **Ask** | the release action (tag / `workflow_dispatch`) |
| **Deny** | direct `git push` to `main` · `terraform apply`/`destroy` · direct `aws` mutations · `--force` / `git reset --hard` · `rm -rf` · secrets writes · `--dangerously-skip-permissions` |

**`gh pr merge` is deliberately NOT in the Ask row, and that is a correction (#62).** It used to sit there as *"this is the deploy, so it is the go/no-go"* — true about the merge, wrong about the mechanism, and it contradicted `quality-assurance`, which merges the safe class by its own definition.

The reason it cannot be a permission rule is structural, not a preference: **whether a merge needs the human depends on the CLASS of the change, and a permission matcher reads a command string.** `gh pr merge 331 --merge` looks identical whether the diff is a typo fix or a Terraform change. A rule that prompts on all of them taxes the safe class — which is most merges — while proving nothing about the boundary class, and the tax lands on the owner, who then approves something they already asked for.

So **the classification is the gate, and `quality-assurance` holds it**: it merges the safe class once both of its lenses are green — delivery, and can-this-break-production — and never merges the boundary class — infrastructure and anything threatening continuity, a change to the loop's own rules, publishing in the owner's voice, or any expansion of its own authority. When the class is unclear, it is boundary.

*The named cost:* this is a persona-level guarantee, not a mechanical one — as strong as the model reading its own definition, where the Deny row is a shell script that cannot be argued with. Accepted deliberately, and it is why the **irreversible** floor stays in Deny rather than moving to the same layer.

**Do not carry over from `gitflow-multi-env`:**
- **Do not pre-authorize merges to `develop`** — the branch does not exist, so the entry silently authorizes nothing while the *real* merge goes ungated.
- **Do not deny working on `main`.** `main` is checked out routinely; blocking edits or commits by branch context breaks the model outright (see the hook section).
- **Do not add `*prd*`/production deny patterns** for environments the repo does not have. Dead patterns read as protection and provide none.

## Two layers — global and per-project (both models)
- **Global** (`~/.claude/settings.json`): the universal **floor** — deny the always-forbidden (`apply`/`destroy`/`--force`/`rm -rf`/secrets/`--dangerously-skip-permissions`) and register the guard hook. Protects every repo, even one with no local config.
- **Per-project** (committed `.claude/settings.json`): the **inner-loop allow** for that repo's stack, plus the plugin. Permissions are a **versioned repo contract** — they live in the committed `settings.json`, not `settings.local.json` (which holds only per-machine items). In the settings merge, **deny from any layer wins**, so the global floor is inescapable and the project layer only adds autonomy.

**Never `--dangerously-skip-permissions`** — it erases the entire boundary. The allowlist is curated, not bypassed.

**Prune the allowlist when the architecture changes.** An allow entry for a service the repo no longer has is standing authority with no purpose; a *deny* entry for a service it no longer has is harmless and costs nothing to keep. When in doubt, prune allow and keep deny.

## Enforcement = static deny + the guard hook
- **Static allow/deny** covers every case where the target is visible in the command string — protected-branch operations and the universal irreversibles. This is most of the boundary.
- **The `PreToolUse` guard hook** (`hooks/permission-guard.sh`, matcher `Bash`) is the backstop for the irreversible floor that must hold in *every* repo regardless of model. It inspects the command string only and denies six families: `--dangerously-skip-permissions`; `terraform apply`/`destroy`; `git push --force`/`--force-with-lease`/`-f` and `git reset --hard`; `rm -rf`/`rm -fr`; secret writes (`aws secretsmanager put/create/update/delete/restore-secret`, `aws ssm put-parameter … SecureString`); and destructive `aws` verbs (`delete-`/`terminate-`/`deregister-`/`destroy-`/`remove-`/`purge-`). It **fails open** on a parse error, by design — the static deny list is the real floor, the hook is defence in depth.

> **The hook is deliberately branch-agnostic and must stay that way.** It contains no `git branch` / `rev-parse` call and no environment-name matching, so the same hook is correct under both models. A hook that blocked writes or commits while `main` is checked out would be safe under `gitflow-multi-env` and would **brick** `trunk-single-env`, where `main` is the working branch. Branch-dependent rules belong in the repo's own `settings.json` deny list, never in the shared hook.

## Why this doesn't cost cadence (both models)
Strong local validation is the keystone: the agent proves "done" locally — runs the repo's regression, self-verifies the gates — **without ever needing the denied boundary**. So the deny costs ~zero velocity; it only blocks what the agent should never touch. The cadence comes from the local loop; the boundary protects what is live. Cut local validation and you'd be forced to either loosen the boundary (risky) or gate everything (slow) — both break cadence. Keep local validation strong and the boundary stays tight for free.
