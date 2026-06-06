Use Postman (+ newman) for API testing in <project>-api.

Context: $ARGUMENTS

Postman collections document and smoke/contract-test the API; run headless via **newman** in CI.

## Files (api repo, `postman/`)
- `<project>-api.postman_collection.json` — all routes + request examples + test scripts (`pm.test(...)`).
- `<project>-api.postman_environment.json` — `base_url`, auth/session vars (no secrets committed).

## What it covers
- **Smoke:** `GET /health`, `GET /profile` (public) → 200 + expected shape.
- **Contract:** response bodies match the generated OpenAPI (snake_case fields) — `/backend/openapi`.
- **Auth:** protected routes → 401 without a Bearer JWT; 200 with a valid `Authorization: Bearer` token.

## CI (newman)
```bash
npx newman run postman/<project>-api.postman_collection.json \
  -e postman/<project>-api.postman_environment.json \
  --env-var base_url=$API_URL --reporters cli,junit
```
Runs in `ci.yml` (`/workflow/github-actions`) as a post-deploy smoke (staging) or against a local server.

## Conventions
- Keep the collection in sync with the **generated OpenAPI** (the contract source of truth) — no divergent hand-maintained spec.
- No secrets in the committed environment file (tokens injected as env vars / via the BFF).
- Treat it as smoke/contract, not full coverage — vitest owns coverage (`/backend/coverage`).

## Pros & cons
**Pros**
- Black-box contract checks against a real deployed BFF; covers the Bearer-JWT auth path.
- Lives in the api repo next to the code it checks.
**Cons**
- Smoke/contract only — not a coverage substitute.
- Needs a running environment + tokens.
