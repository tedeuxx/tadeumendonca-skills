Use SonarCloud in <project> repos (code quality + security scan).

Context: $ARGUMENTS

SonarCloud runs on every PR and on push to develop/main as a **Quality Gate** — static analysis (bugs, code smells, **vulnerabilities/SAST**, security hotspots), coverage, and duplication. A failing gate **blocks the merge/deploy**. Analysis is **CI-based**, not Automatic: SonarCloud **Automatic Analysis must be OFF** per project or the scanner is rejected.

## Setup (per repo)
- `sonar-project.properties`: `sonar.projectKey`, `sonar.organization`, `sonar.sources` (+ `sonar.tests`/`sonar.coverage.exclusions` for code repos).
- Secret **`SONAR_TOKEN`** (per repo — `tedeuxx` is a personal account, so no org-level secret).
- Coverage import (code repos): `sonar.javascript.lcov.reportPaths=coverage/lcov.info` (from vitest; covers TS/TSX too). IaC repos have no coverage.

## CI step (after tests, in ci.yml — see `/workflow/github-actions`)
The legacy `sonarcloud-github-action` is **deprecated/archived** — use the unified scan action. One step both scans and gates via `qualitygate.wait` (no separate quality-gate action):
```yaml
- uses: SonarSource/sonarqube-scan-action@v7
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
    SONAR_HOST_URL: https://sonarcloud.io   # SonarCloud host
  with:
    args: -Dsonar.qualitygate.wait=true     # poll + FAIL the job on a red gate
```
Checkout needs `fetch-depth: 0` (full history → accurate new-code/blame attribution).

## Conventions
- **Where it lives:** code repos (api/fed) run Sonar **inside `ci.yml`** after lint/typecheck/tests — it consumes the test step's `coverage/lcov.info`. The iac repo runs Sonar in a **standalone `sonar.yml`** (no coverage to consume, and it must not trigger the AWS plan on push).
- **iac:** SonarCloud **IaC analysis** scans the Terraform (smells, security hotspots) **in addition to** `checkov` (policy/security gate in `terraform-plan.yml`) — the two are complementary (`/infrastructure/terraform`).
- **Quality gate definition:** the built-in **"Sonar way"** gate (Default) on **new code** (clean-as-you-code), incl. **Coverage on New Code ≥ 80%**. `qualitygate.wait=true` fails the *job*; to actually **block merge**, also make the workflow check (`ci` for api/fed, `sonar` for iac) a **required status check** in branch protection (`/workflow/github-actions`).
- Vitest still enforces the local **≥85%** (whole-codebase) as a fast pre-check; Sonar owns the authoritative gate on **new code** (≥80%) — two different scopes, not a contradiction.
- `SONAR_TOKEN` is a per-repo GitHub secret (`/workflow/github-actions`).
- **This skills repo is not a Sonar project** — markdown command guides have nothing to analyze.

## Pros & cons
**Pros**
- SAST + coverage + smells in one quality gate that blocks merge; free for public repos; trend tracking.
**Cons**
- False positives to triage; another account/gate to manage.
- Quality-gate thresholds need tuning.
