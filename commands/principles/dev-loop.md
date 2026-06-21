Apply the platform's end-to-end development loop in any deployed-app <project> repo (frontend + BFF + IaC). This is the flow the principles run inside — `/principles/engineering-philosophy` is the judgment, `/principles/verification-and-gates` is what "done" means; this is how a change travels from idea to production.

Context: $ARGUMENTS

> Scope: this describes a **deployed app with environments** (staging + production on GitFlow). A consumed artifact with no environments (a library/plugin) uses a simpler trunk-based, deliberate-release flow instead — match the model to the repo's role.

## The loop at a glance
```
roadmap / PLAN.md
   │  plan-first; ask only on architecture / contract / irreversible
   ▼
thin vertical slice (WIP = 1)  ──  adjacent mess in the path? work around + file the debt
   │
   ▼
develop locally: frontend + (BFF → staging backing infra)
   │  security & resilience by-design
   ▼
validate locally: run E2E + API regression against local  ──  self-verify gates green
   │
   ▼  /code-review before opening the PR
PR → integration branch (auto-merge)  ──  staging gate: coverage + quality + security
   │  Claude App reviews the PR (advisory, non-blocking)
   ▼
STAGING  ──  post-deploy: smoke + confirm health via observability
   │
   ▼
PR integration → release branch
   │  blocking: full E2E + API regression · human review · version label · MANUAL APPROVAL
   ▼
PRODUCTION + tag / Release  ──  post-deploy smoke + observability
   │
   └─ breaks? → revert the offending merge on the release branch + re-release (forward fix)
```

## Intake — where work is born
Work is **driven by the roadmap (`PLAN.md`)**, the source of what gets built next. A tracked issue is **optional** — created only when it helps decompose the work — not a hard prerequisite for starting.

## Inner loop (per slice)
1. **Plan-first**, then implement. Ask only on architecture / contracts / irreversible calls; decide autonomously on in-pattern implementation.
2. **One thin vertical slice at a time** (WIP = 1), end-to-end and reviewable. Keep it surgical; file any adjacent debt instead of refactoring it inline.
3. **Develop locally** — frontend plus BFF, the BFF pointed at the **staging environment's backing infra** (database and dependencies) via the parameter-store bus.
4. **Validate locally** by running the **E2E + API regression against local**, and self-verify the gates (lint, typecheck, coverage). Report with the real output.
5. **Run `/code-review`** before opening the PR.

## Outer loop — promotion
- **Feature/docs branch → PR → integration branch** (auto-merge). The **staging gate** blocks on coverage + quality gate + security. On merge it deploys to **staging**; the **Claude App** reviews the PR as advisory (non-blocking).
- After staging deploys: **smoke + confirm health via observability**.
- **Promote integration → release branch**: the **full E2E + API regression is a blocking required check**, plus human review, the version-bump label, and **manual approval — promotion to production always asks**. On merge: production deploy + version tag + GitHub Release. Post-deploy: smoke + observability again.
- **Pipelines are independent per repo** (never cross-trigger). Infrastructure changes are pipeline-only: a reviewed plan on the PR, apply on merge.

## Failure path
When production breaks, **revert the offending merge on the release branch and re-release** — a forward fix with a new slice — rather than a long-lived hotfix branch. The 100% regression suite is what makes a fast forward-fix safe.

## What the human does (the residual)
Everything mechanical is the agent's job: plan, slice, build, validate locally, make the gates green, report evidence. The human is left only the residual — approving (or redirecting) architectural/contract decisions and giving the **production go/no-go**. Designing the loop so that residual stays small is the whole point (`/principles/verification-and-gates`).

See also: `/workflow/github-actions` (branching, OIDC, the deploy workflows), `/workflow/versioning` (release model), `/backend/coverage` + `/frontend/coverage` (gate definitions), `/frontend/playwright` + `/backend/postman` (the E2E + API suites).
