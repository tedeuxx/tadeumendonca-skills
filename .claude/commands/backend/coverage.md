Set up or review the backend (<project>-api) quality, test, and security gates.

Context: $ARGUMENTS

**Framework-agnostic** — the gates + the thresholds policy. The concrete runner config is specialized and lives in the framework skills: the unit runner + coverage config in `/backend/framework-hono`, contract tests in `/backend/postman`. CI **blocks deploy** if any gate fails (no Lambda update, no reimport). Frontend gates: `/frontend/coverage`; IaC checkov: `/infrastructure/terraform`.

## Quality
- **Lint** — zero errors.
- **Typecheck** — zero type errors.

## Test
- **Unit/integration** — coverage **≥ 85%** on lines / functions / branches / statements; below threshold blocks. Runner + config: `/backend/framework-hono`.
- **API/contract** — collection run against a staged BFF (401 without a Bearer JWT, 200 with it, schema checks): `/backend/postman`.

## Security
- **Dependencies** — block on high/critical advisories; dependency-review/Dependabot on PRs.
- **SAST + quality gate** — **SonarCloud** Quality Gate blocks merge; imports the unit-coverage lcov (`/workflow/sonarcloud`).
- **Secrets** — secret scanning; no committed secrets (they live in Secrets Manager — `/backend/secrets-management`).
- **Automated review** — Claude Code review action on every PR.

## Conventions
- Don't lower a threshold to go green; fix the gap. Thresholds are identical to the frontend (`/frontend/coverage`).
- Where the gates sit in the pipeline: `/workflow/github-actions`.
