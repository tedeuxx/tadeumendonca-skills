Use Playwright for E2E tests in `apps/fed`.

Context: $ARGUMENTS

End-to-end tests that drive the real SPA in a browser; part of the deploy gate (`/frontend/coverage`).

## Setup (multi-environment, parametrized)
- `playwright.config.ts`: `baseURL` from env — `PLAYWRIGHT_BASE_URL` (or an `E2E_ENV=local|staging|production` mapped to the right URL), projects (chromium + optionally webkit), `trace: 'on-first-retry'`, `retries` in CI. **One command targets local OR any AWS env.**
- `package.json` scripts: `e2e:local` (against `vite preview`), `e2e:staging`, `e2e:production` — each sets the base URL. Run the SAME specs anywhere.
- Tests under `e2e/*.spec.ts`; browsers via `npx playwright install --with-deps`.

## STANDARD — every feature ships its E2E
A new user-facing feature MUST add/update its Playwright spec in the same PR (the critical journey it introduces). Keep specs at journey level — don't re-test unit logic.

## Auth on social-only Cognito (Google) — can't automate Google
Google's interactive login blocks bots, so you can't drive it in Playwright. For authenticated/admin journeys against AWS, mint a token from a **native test user** (`USER_PASSWORD_AUTH`, see `/infrastructure/cognito` + `/backend/postman`) and seed the Amplify session / `storageState` directly, OR run those journeys against a local build with a stubbed session. Public journeys (feed, post/blog, share) need no auth and run against any env as-is.

## What we cover (per phase)
- `home.spec.ts` — Phase 1: CV page renders all profile sections.
- `feed.spec.ts` — Phase 2: feed loads + infinite scroll.
- `auth.spec.ts` — Phase 2: Cognito SDK login (redirect → `/callback` → token via Amplify) + an authenticated call.

## Patterns
- **Locators by role/text** (`getByRole`, `getByText`) — avoid brittle CSS selectors.
- **Web-first assertions** (`await expect(locator).toBeVisible()`) — no arbitrary `waitForTimeout`.
- Test against staging or a local preview; isolate from external Cognito where possible.

## CI
- Runs in `ci.yml` (`/workflow/github-actions`); **any failure blocks the deploy**. Upload the HTML report/trace on failure.

## Conventions
- E2E lives in `apps/fed`; `apps/bff` uses Postman/newman (`/backend/postman`) + vitest.
- E2E asserts user-visible flows — don't re-test unit logic here.

## Pros & cons
**Pros**
- Real-browser coverage of critical journeys; catches integration regressions a unit test cannot.
**Cons**
- Slower and flakier than unit tests.
- Selectors/specs to maintain.
