Use SonarCloud in <project> repos (code quality + security scan).

Context: $ARGUMENTS

SonarCloud runs on every PR and on develop/main as a **Quality Gate** — static analysis (bugs, code smells, **vulnerabilities/SAST**, security hotspots), coverage, and duplication. A failing gate **blocks the merge/deploy**.

## Setup (per repo)
- `sonar-project.properties`: `sonar.projectKey`, `sonar.organization`, sources/tests paths, `sonar.exclusions`.
- Secret **`SONAR_TOKEN`** (per repo) — the SonarCloud analysis token.
- Coverage import: `sonar.javascript.lcov.reportPaths=coverage/lcov.info` (from vitest).

## CI step (in ci.yml — see `/workflow/github-actions`)
```yaml
- uses: SonarSource/sonarcloud-github-action@v3
  env: { SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }} }
# run AFTER tests so coverage (lcov) exists; PR decoration shows the Quality Gate
- uses: SonarSource/sonarqube-quality-gate-action@v1   # fail the job if the gate is red
  env: { SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }} }
```

## Conventions
- Runs after lint/typecheck/tests (needs the lcov); the **Quality Gate failure blocks** — it's part of the quality gates (`/backend/coverage`, `/frontend/coverage`).
- Configure the gate on **new code** (clean-as-you-code).
- SonarCloud covers JS/TS (api/fed); **`checkov`** remains the Terraform security scan (`/infrastructure/terraform`).
- Vitest still enforces the local **≥85%** as a fast pre-check; Sonar owns the authoritative quality/coverage gate.
- `SONAR_TOKEN` is a per-repo GitHub secret (`/workflow/github-actions`).
