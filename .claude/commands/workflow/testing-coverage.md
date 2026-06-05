Set up or review the test coverage / E2E gates for a tadeumendonca.io repo.

Repo / context: $ARGUMENTS

CI **blocks deploy** if the gate fails. Gates run in `deploy.yml` before the AWS steps.

## api (tadeumendonca-api)
- **Unit/integration:** `vitest`. Coverage threshold **≥ 85%** enforced via `vitest.config.ts` (`coverage.thresholds`).
- CI fails the deploy if coverage < 85%.

```ts
// vitest.config.ts
test: { coverage: { provider: 'v8', thresholds: { lines: 85, functions: 85, branches: 85, statements: 85 } } }
```

## fed (tadeumendonca-fed)
- **Unit:** `vitest` — same **≥ 85%** coverage gate.
- **E2E:** `Playwright` — CI fails the deploy if any E2E spec fails.
  - `home.spec.ts` (Phase 1: CV renders), `feed.spec.ts` (Phase 2: infinite scroll), `auth.spec.ts` (Phase 2: Cognito PKCE callback).

## Conventions
- Coverage + E2E run on the deploy path; a red gate means no S3/CloudFront/Lambda changes ship.
- Keep tests close to the source (`*.spec.ts`); E2E lives under `tests/e2e/`.
- The gate is intentionally identical across repos — don't lower the threshold per repo.
- See `/workflow/deploy-api` and `/workflow/deploy-fed` for where the gate sits in the pipeline.
