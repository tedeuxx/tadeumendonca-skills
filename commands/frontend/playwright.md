---
description: Write browser end-to-end journeys with Playwright — one command targeting either a local server or the deployed apex, the standard that every user-facing feature ships its E2E, and the critical journeys run in CI. Use when a slice changes user-visible behaviour, when a journey owes a regression, or when wiring E2E into a pipeline. Not for API-level contract tests (see backend/postman).
---

Use Playwright for E2E tests in the SPA.

Context: $ARGUMENTS

End-to-end tests that drive the real **static SPA** in a browser — the functional proof that nothing already
working broke. Under `trunk-single-env` E2E runs on the **PR gate** (it blocks the merge, and the merge is the
deploy), and the same specs can run as a **post-deploy smoke** against the live apex. Part of the quality gate
(`/backend/coverage`).

## Setup (single environment, one command targets local or the apex)
- `playwright.config.ts`: `baseURL` from `PLAYWRIGHT_BASE_URL`, or from `E2E_ENV` mapped to a URL — `local`
  (a `vite preview` of the built app at `:4173`) or the **single environment served at the apex**
  (`https://<apex-domain>`). `trace: 'on-first-retry'`, `retries` in CI, chromium project. The **same
  specs run anywhere** — only the base URL changes.
- `package.json` scripts: `e2e:local` (against `vite preview`) is the **pre-merge gate**; the apex-targeted
  run is the **deploy smoke**. (There is one environment; any `staging`/`production` script names are aliases
  for the same apex — a leftover, not a second tier.)
- Tests under `e2e/*.spec.ts`; browsers via `npx playwright install --with-deps`.

## STANDARD — every user-facing feature ships its E2E
A new user-facing feature MUST add/update its Playwright spec in the same PR (the critical journey it
introduces). This is the 100%-of-user-visible-features regression invariant. Keep specs at **journey level** —
don't re-test unit logic (that's the co-located Vitest/RTL suite).

## No auth — the surface is static
The site has **no backend, no auth, no Cognito**: every journey is a public, unauthenticated page load. There
is no login to automate, no token to seed, no session to stub. If an old spec or note references Cognito/Google
login or a `storageState` token, that's the retired backend era — delete it, don't port it.

## What we cover (the static journeys)
The specs assert the real content surface — landing / CV / portfolio / blog / routing:
- **Landing** (`/`) is the content shop window (Artigos + Portfólio), **not** the CV — the personal name lives
  on `/cv` only.
- **CV** (`/cv`) renders the profile (name, sections, contact links incl. the WhatsApp click-to-message link).
- **Portfolio** (`/portfolio`) serves the full catalog with its GitHub links, reachable from the landing
  shortlist.
- **Content detail** — an article opens by slug, renders its markdown, and offers a share control.
- **Routing resilience** — retired list routes (`/blog`, `/articles`) redirect to the landing; a legacy
  `/articles/:slug` permalink still renders; an unknown path goes back to the landing, not a dead end.

## Patterns
- **Locators by role/text** (`getByRole`, `getByText`) — avoid brittle CSS selectors.
- **Web-first assertions** (`await expect(locator).toBeVisible()`) — no arbitrary `waitForTimeout`.
- Run against a local `vite preview` (the PR gate) or the apex (the smoke) — no external service to isolate.

## CI
- Runs in **`build-test.yml`** (`/workflow/github-actions`) on the PR, via the config's `webServer` booting a
  `vite preview` of the built app. **Any failure blocks the merge** — and the merge is the deploy, so a red
  E2E stops the release. Upload the HTML report/trace on failure.

## Pros & cons
**Pros**
- Real-browser coverage of critical journeys; catches integration regressions a unit test cannot.
- On a static site with no auth, the specs are simple and stable — pure public page loads.

**Cons**
- Slower and flakier than unit tests.
- Selectors/specs to maintain.
