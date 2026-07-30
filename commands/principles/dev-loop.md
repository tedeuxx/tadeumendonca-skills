Apply the platform's end-to-end development loop in a `<project>` repo. This is the flow the principles run inside — `/principles/engineering-philosophy` is the judgment, `/principles/verification-and-gates` is what "done" means; this is how a change travels from idea to live.

Context: $ARGUMENTS

## Pick the model first
The loop has **two shapes**. They share every invariant below and differ only in how a change is promoted. Read the repo before applying either — asserting the wrong model is worse than asking.

| Model | Use when | Promotion |
|---|---|---|
| **`gitflow-multi-env`** | The repo deploys to **more than one environment** (staging + production) and carries an integration branch. | Two hops: PR → integration branch → staging, then a promotion PR → release branch → production behind a manual approval. |
| **`trunk-single-env`** | The repo has **one long-lived branch (`main`) and one destination** — a single deployed environment, or a consumed artifact (library/plugin) released deliberately. | One hop: PR → `main` → deploy/release. |

**How to tell**, in order of authority: the repo's `CLAUDE.md` states the model outright; otherwise look for an integration branch (`develop`) on the remote and more than one environment in CI. **If both signals are absent, it is `trunk-single-env`** — a single branch cannot express a promotion. Never infer the model from the skills library's own examples.

> The number of environments — not the repo's size or seriousness — picks the model. `trunk-single-env` is not "the lightweight one": the gate does not get weaker, it moves (see below).

## Invariants (both models)

### Intake — where work is born
Work is **driven by the roadmap (`PLAN.md`)**, the source of what gets built next. A tracked issue is **optional** — created only when it helps decompose the work — not a hard prerequisite for starting.

### Opening a session — decisions before work

**Collect the pending owner decisions across the whole queue and ask them as a batch, before choosing what to build.** One question at a time, in one sitting.

Batching is the point. Asking a decision when a slice hits it produces one stall per slice; asking them up front produces one conversation and unblocks everything at once. Same questions, completely different cost to the person answering — and the owner's attention is the scarce input this whole loop is calibrated around.

Then **`product-manager` states the order**, and the session works it. Not "invoke it more often" — the condition is precise:

> Starting a slice that is **not** the top of the stated order requires `product-manager` to have returned a new order, or the session records that the order is unchanged.

That fires exactly when the risk is real — picking work — and it produces the artifact that makes drift visible: a stated order that a later choice can be checked against.

**A session with no pending decisions says so.** A step that silently did nothing must not read like a step that ran.

*Why this is an invariant and not advice:* every other persona has a trigger. `critical-reviewer` runs on every MR; `brand-guardian` and `editor` hang off it; `plan-reviewer` fires on a plan. `product-manager` had none, and a mandate with no trigger is a document, not a gate — which is this loop's own sentence, about a different persona, that this rule finally applies to the one it was written next to.

### What gets worked next — discovered vs requested

**Work you discover only preempts work the owner asked for when it BLOCKS it.**

File everything, always — a defect found in context, with the evidence in hand, is worth recording whether or not it is worked. That part is unconditional. This rule is only about **what gets built next**.

The test is checkable, not a judgment call:

> Does the requested work ship **wrong**, or **not at all**, without this?

Yes → it goes first, and the blocking relationship is stated on the issue. No → it queues like everything else and `product-manager` orders it.

*Why the rule is needed:* discovered work is cheap to justify — found in context, evidence attached, usually safe class, merges without the owner. Requested work needs decisions, designs, sometimes the owner's own words. So the loop's **autonomy gradient sorts the queue by what can flow without the human**, which is exactly backwards from what a backlog is for. That is not a lapse in judgment; it is the incentive the other rules create, and it needs a counterweight written down.

### Inner loop (per slice)
1. **Plan-first**, then implement. Ask only on architecture / contracts / irreversible calls; decide autonomously on in-pattern implementation.
2. **One thin vertical slice at a time**, end-to-end and reviewable. Keep it surgical; adjacent debt is **named, not refactored inline and not filed** — see *Review does not open work*.
   **WIP is bounded by file OVERLAP, not by a count.** A second PR may open freely if its changed files do not intersect an open PR's; it may not if they do. The goal was never *one at a time* — it was avoiding stacked PRs that rot into conflicts, and counting is a bad proxy for that: it blocks disjoint work, which is the common case, while doing nothing about the actual risk. Pair it with the half that prevents rot: **integrate `main` before requesting review** if `main` has moved.
3. **Develop locally**, against whatever backing services the repo actually has — see `/principles/permissions-and-environments` for what "locally" means per model.
4. **Validate locally**: run the repo's **functional regression** and self-verify the gates (lint, typecheck, coverage). Report with the real output, never a claim.
5. **Run `/code-review`** before opening the PR.

### Always true
- **Pipelines are independent per repo** (never cross-trigger). Infrastructure changes are **pipeline-only**: a reviewed plan on the PR, apply on merge.
- **Merge with a real merge commit, never squash** (`gh pr merge --merge`) — each thin slice's conventional commits are the changelog and the slice-by-slice trail; squashing collapses them. See `/workflow/github-actions`.
- **The regression suite must functionally cover 100% of implemented features.** Which suites that means is per repo — E2E always; an API suite only where an API exists. Coverage of a surface the repo does not have is not a requirement, and pretending otherwise trains the agent to fake evidence.
- **Something irreversible always asks.** The models differ on *which* act is the point of no return, never on whether one exists.

## `gitflow-multi-env`

```
roadmap / PLAN.md
   │  plan-first; ask only on architecture / contract / irreversible
   ▼
thin slice, no file overlap  ──  adjacent mess in the path? work around + file the debt
   │
   ▼
develop locally  ──  security & resilience by-design
   │
   ▼
validate locally: run the regression  ──  self-verify gates green
   │
   ▼  /code-review before opening the PR
PR → integration branch (auto-merge)  ──  staging gate: coverage + quality + security
   │  Claude App reviews the PR (advisory, non-blocking)
   ▼
STAGING  ──  post-deploy: smoke + confirm health via observability
   │
   ▼
PR integration → release branch
   │  blocking: full regression · human review · version label · MANUAL APPROVAL
   ▼
PRODUCTION + tag / Release  ──  post-deploy smoke + observability
   │
   └─ breaks? → revert the offending merge on the release branch + re-release (forward fix)
```

- **Feature/docs branch → PR → integration branch** (auto-merge). The **staging gate** blocks on coverage + quality gate + security. On merge it deploys to **staging**; the **Claude App** reviews the PR as advisory (non-blocking).
- After staging deploys: **smoke + confirm health via observability**.
- **Promote integration → release branch**: the **full regression is a blocking required check**, plus human review, the version-bump label, and **manual approval — promotion to production always asks**. On merge: production deploy + version tag + GitHub Release. Post-deploy: smoke + observability again.
- **The point of no return is the promotion**, which is why the heavy gates sit there and the staging gate stays light: staging is cheap to break and re-fix.
- **Failure path:** revert the offending merge on the release branch and re-release — a forward fix with a new slice, not a long-lived hotfix branch.

## `trunk-single-env`

```
roadmap / PLAN.md
   │  plan-first; ask only on architecture / contract / irreversible
   ▼
thin slice, no file overlap  ──  adjacent mess in the path? work around + file the debt
   │
   ▼
develop locally  ──  security & resilience by-design
   │
   ▼
validate locally: run the regression  ──  self-verify gates green
   │
   ▼  /code-review before opening the PR
PR → main   ── THE gate, all of it: lint + typecheck + coverage + quality + security + full regression
   │  Claude App reviews the PR (advisory, non-blocking)
   │  MERGE ASKS — this merge is the go/no-go
   ▼
LIVE (deploy on merge) + tag / Release  ──  post-deploy smoke + confirm health
   │
   └─ breaks? → revert the offending merge on main + re-deploy (forward fix)
```

- **Feature/docs branch → PR → `main`.** There is no integration branch and nothing to defer to, so **the PR carries the entire gate**: lint, typecheck, coverage, quality gate, security, and the **full regression as a blocking required check**. The Claude App reviews as advisory (non-blocking).
- **The merge to `main` is the point of no return** — it deploys. So the merge is what **asks**: the human's go/no-go moved from a promotion step onto this merge. Auto-merging to `main` is never in-pattern here.
- On merge: deploy + version tag + GitHub Release. Post-deploy: **smoke + confirm health**, through whatever observability the repo actually has (for a static site that is analytics + the client error surface + a build/prerender smoke, not backend telemetry).
- **Failure path:** revert the offending merge on `main` and let the revert deploy — same forward-fix discipline, one hop instead of two.
- **Consumed-artifact variant** (a library or plugin with no deployed environment): identical, except the merge to `main` publishes nothing by itself — the irreversible act is the **release/tag**, so that is what asks. `main` stays always-releasable.

### Do not carry these over from `gitflow-multi-env`
- No `develop`/integration branch — do not create one, and do not pre-authorize merges to a branch that does not exist.
- No "light staging gate". There is no second chance downstream; a gate skipped on the PR is a gate that never runs.
- `main` is the **working** branch, not a protected production mirror. Tooling that blocks edits or commits while `main` is checked out breaks this model outright.

## What the human does (the residual)
Everything mechanical is the agent's job: plan, slice, build, validate locally, make the gates green, report evidence. The human is left only the residual — approving (or redirecting) architectural/contract decisions and giving the **go/no-go on the irreversible act** (the promotion under `gitflow-multi-env`, the merge to `main` or the release under `trunk-single-env`). Designing the loop so that residual stays small is the whole point (`/principles/verification-and-gates`).

See also: `/workflow/github-actions` (branching, OIDC, the deploy workflows), `/workflow/versioning` (release model), `/frontend/coverage` + `/backend/coverage` (gate definitions), `/frontend/playwright` (E2E). Repos with an API layer add its contract/API suite — see `/backend/postman`.
