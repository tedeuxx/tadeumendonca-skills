Use Postman (+ newman) for API testing in `apps/bff`.

Context: $ARGUMENTS

Postman collections document and smoke/contract-test the API; run headless via **newman** in CI.

## Files (`apps/bff/postman/`)
- `<project>-api.postman_collection.json` — all routes + request examples + test scripts (`pm.test(...)`).
- **One environment file PER environment** — `local.postman_environment.json`, `staging.postman_environment.json`, `production.postman_environment.json`, each with `base_url` + a `token` var (NO secrets committed). This is the **multi-environment** parametrization: one command targets local OR any AWS env.
- `package.json` scripts: `api-test:local` / `api-test:staging` / `api-test:production` (`newman run <collection> -e postman/<env>.postman_environment.json`). Inject the auth token at runtime: `npm run api-test:staging -- --env-var token=$TOKEN`.

## STANDARD — every feature ships its regression
Adding/changing an endpoint MUST add/update its Postman request + `pm.test` assertions in the same PR (smoke + contract + the auth path). A new entity = new requests for its public GETs, admin writes (401 without token, 200/201 with), and the response shape.

## Auth on social-only Cognito (Google) — needs a NATIVE test user
Google sign-in can't be automated (Google blocks bots), so an interactive token won't do. Use an **admin-created native Cognito user** + a client with `USER_PASSWORD_AUTH` to mint a token via `InitiateAuth` (no Google) — that's an `/infrastructure/cognito` change. Store the token as a CI secret (`TEST_USER_TOKEN`) injected via `--env-var token=...`. Until it exists, the authed-write checks stay skipped (the `401-without-token` check runs everywhere).

## What it covers
- **Smoke:** `GET /health`, `GET /profile` (public) → 200 + expected shape.
- **Contract:** response bodies match the generated OpenAPI (snake_case fields) — `/backend/openapi`.
- **Auth:** protected routes → 401 without a Bearer JWT; 200 with a valid `Authorization: Bearer` token.

## CI (newman) — post-deploy smoke against the just-deployed env
Run as the **last step of `deploy.yml`** (after `create-deployment`), targeting the env that was just deployed (staging on develop, production on main):
```yaml
- name: API smoke (newman) against the deployed environment
  run: |
    sleep 5 # let the new stage settle
    npm run "api-test:$ENV_NAME" -- --env-var "token=${{ secrets.TEST_USER_TOKEN }}"
```
A red smoke surfaces a regression the just-shipped deploy introduced. Can also run **locally against any env** (`npm run api-test:staging`) — that's the point of the per-env environment files.

## Conventions
- Keep the collection in sync with the **generated OpenAPI** (the contract source of truth) — no divergent hand-maintained spec.
- No secrets in the committed environment file (tokens injected as env vars / via the BFF).
- Treat it as smoke/contract, not full coverage — vitest owns coverage (`/backend/coverage`).

## Pros & cons
**Pros**
- Black-box contract checks against a real deployed BFF; covers the Bearer-JWT auth path.
- Lives in `apps/bff` next to the code it checks.
**Cons**
- Smoke/contract only — not a coverage substitute.
- Needs a running environment + tokens.
