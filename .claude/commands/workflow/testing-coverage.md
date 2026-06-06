Set up or review the quality, test, and security gates for a tadeumendonca.io repo.

Repo / context: $ARGUMENTS

CI **blocks deploy** if any gate fails. Gates run on PR and on the deploy path, before the AWS steps.

## Quality gates (all repos)
- **Lint** — ESLint (`eslint.config.mjs`); zero errors.
- **Typecheck** — `tsc --noEmit` (api/fed) / `terraform validate` + `fmt -check` (iac).

## Test gates
- **api:** `vitest` unit/integration, coverage **≥ 85%** (`vitest.config.ts` thresholds).
  ```ts
  test: { coverage: { provider: 'v8', thresholds: { lines: 85, functions: 85, branches: 85, statements: 85 } } }
  ```
- **fed:** `vitest` unit (**≥ 85%**) + **Playwright** E2E (`home` / `feed` / `auth` specs) — any failure blocks.

## Security / artifact verification
- **IaC:** **`checkov`** static analysis on `terraform/` — blocks on HIGH `FAILED` (`/infrastructure/terraform`).
- **Dependencies:** `npm audit --audit-level=high` (api/fed) blocks on high/critical; `dependency-review` / Dependabot on PRs.
- **Code quality + SAST:** **SonarCloud** Quality Gate (bugs, smells, vulnerabilities, security hotspots, coverage, duplication) on every PR — **blocks merge**; imports vitest coverage (lcov). See `/workflow/sonarcloud`.
- **Secrets:** secret scanning — no committed secrets (they live in Secrets Manager, `/backend/secrets-management`).
- **Automated review:** Claude Code review action (`claude-code-review.yml`) on every PR.

## Conventions
- A red gate means **nothing ships** — no S3/CloudFront/Lambda change, no `terraform apply`.
- Gates are identical across repos — don't lower a threshold per repo.
- See `/workflow/deploy-api`, `/workflow/deploy-fed` for where gates sit in the pipeline.
