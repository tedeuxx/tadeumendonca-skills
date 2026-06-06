Use Playwright for E2E tests in tadeumendonca-fed.

Context: $ARGUMENTS

End-to-end tests that drive the real SPA in a browser; part of the deploy gate (`/workflow/testing-coverage`).

## Setup
- `playwright.config.ts`: `baseURL` from env (staging URL or local `vite preview`), projects (chromium + optionally webkit/firefox), `trace: 'on-first-retry'`, `retries` in CI.
- Tests under `e2e/*.spec.ts`; browsers via `npx playwright install --with-deps`.

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
- E2E lives only in fed; api uses Postman/newman (`/workflow/postman`) + vitest.
- E2E asserts user-visible flows — don't re-test unit logic here.
