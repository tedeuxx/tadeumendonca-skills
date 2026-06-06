Set up or review the frontend (<project>-fed) quality, test, and security gates.

Context: $ARGUMENTS

**Framework-agnostic** — the gates + the thresholds policy. The concrete runner config is specialized and lives in the framework skills: the unit runner + coverage config in `/frontend/framework-react`, E2E in `/frontend/playwright`, component tests in `/frontend/storybook`. CI **blocks deploy** if any gate fails (no S3 sync, no CloudFront invalidation). Backend gates: `/backend/coverage`; IaC checkov: `/infrastructure/terraform`.

## Quality
- **Lint** — zero errors.
- **Typecheck** — zero type errors.

## Test
- **Unit/component** — coverage **≥ 85%** on lines / functions / branches / statements; below threshold blocks. Runner + config: `/frontend/framework-react`.
- **E2E** — critical user journeys (home / feed / auth), login via the Cognito SDK; any failure blocks: `/frontend/playwright`.
- **Component library** — interaction/visual tests where used: `/frontend/storybook`.

## Security
- **Dependencies** — block on high/critical advisories; dependency-review/Dependabot on PRs.
- **SAST + quality gate** — **SonarCloud** Quality Gate blocks merge; imports the unit-coverage lcov (`/workflow/sonarcloud`).
- **Secrets** — secret scanning; no committed secrets. Build-time `VITE_*` come from SSM, not secrets (`/frontend/environment-config`).
- **Automated review** — Claude Code review action on every PR.

## Conventions
- Don't lower a threshold to go green; fix the gap. Thresholds are identical to the backend (`/backend/coverage`).
- Where the gates sit in the pipeline: `/workflow/github-actions`.
