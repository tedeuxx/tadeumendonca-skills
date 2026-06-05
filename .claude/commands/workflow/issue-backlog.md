Manage the GitHub Issues backlog for a tadeumendonca.io repo.

Repo / context: $ARGUMENTS

The product backlog is **GitHub Issues per repository** — each repo owns the issues for its scope. There is no central backlog repo.

## Claude maintains the backlog automatically
- At the start of a work session: review open issues, propose updates (status, labels, closing stale ones).
- On delivering a plan item: open/close the corresponding issue without being asked.

## Labels (identical in all repos)

| Group | Labels |
|---|---|
| `type:` | `feature` · `bug` · `chore` · `docs` · `infra` |
| `phase:` | `1` (CV/v0.2.0) · `2` (Feed/v0.3.0) · `3` (Articles/v0.4.0) |
| `priority:` | `high` (blocks phase) · `medium` · `low` |
| `semver:` | `major` · `minor` (default) · `patch` |
| `status:` | `blocked` |

`semver:*` drives the version bump on release to `main` (see `/workflow/gitflow`).

## Milestones (per repo, aligned to roadmap)

`v0.1.0 — Bootstrap` (iac) · `v0.2.0 — Phase 1` (all) · `v0.3.0 — Phase 2` (iac/api/fed) · `v0.4.0 — Phase 3` (api/fed) · `v1.0.0 — GA` (api/fed).

## Issue templates (`.github/ISSUE_TEMPLATE/`)

**`task.md`** — `labels: 'type:feature, semver:minor'`; sections: What / Why / Acceptance criteria (checklist) / Phase · Milestone.

**`bug.md`** — `labels: 'type:bug, semver:patch, priority:high'`; sections: Expected behavior / Actual behavior / Steps to reproduce / Environment (staging | production).

## Conventions
- Issue title format: `[area] short description` (e.g. `[infra] vpc.tf — VPC + subnets + NAT`).
- Always set `type:`, `phase:`, and `semver:` on creation; `priority:` when known.
- Translate plan deliverables into backlog items at the start of implementation (one issue per deliverable).
