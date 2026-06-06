Maintain the backend API contract (OpenAPI) — generated, versioned, committed.

Context: $ARGUMENTS

**Principle: the contract is maintained automatically by the backend.** It is generated from the code itself on every change, so the OpenAPI can **never drift** from the implementation — there is no manual update step to forget, hence **no contract-update gaps**. This is the whole point of the skill. It is framework-agnostic; the framework-specific *generation* (here: Hono + `@hono/zod-openapi`) lives in `/backend/framework-hono`.

## Principles
1. **Generated from code, never hand-written** — the backend's route/schema definitions are the single source of truth; the OpenAPI is emitted from them. No drift between code and contract.
2. **Versioned with the backend** — the generated spec's `info.version` is stamped with the backend's current **VERSION** (the SemVer tag — `/workflow/github-actions`). Each release's contract carries the **same version as the code** that produced it.
3. **A committed copy lives at the repo root** — the generated `openapi.json` (and/or `.yaml`) is written to the **root of the backend repo** and committed, so it's diffable in PRs, reviewable, and consumable by clients/tools without running the app.

## Generation (CI + local)
```bash
VERSION=$(cat VERSION)
<gen-command> --version "$VERSION" --out openapi.json     # framework adapter → version-stamped root copy
```
- Runs on build/deploy **and** as a CI / pre-commit check: regenerate and **fail if the root `openapi.json` is out of date** (contract-drift guard).
- The adapter that produces the document is the framework's job — `/backend/framework-hono` (`app.getOpenAPI31Document`).

## Two artifacts: vendor-neutral root copy vs AWS-published spec
- The **root `openapi.json` is vendor-neutral** — pure paths + schemas + security scheme references. This is the reviewable/consumable contract.
- **When publishing to AWS API Gateway**, the spec must carry the **AWS-specific OpenAPI extensions** — produced as an overlay on top of the neutral contract, not committed at root:
  - `x-amazon-apigateway-integration` per route → the Lambda invoke ARN (`AWS_PROXY`) — single BFF integration (`/infrastructure/api-gateway`).
  - `x-amazon-apigateway-authorizer` + `securitySchemes` → the Cognito JWT authorizer (issuer = pool URL, audience = client id, from SSM).
  - Applied at deploy (envsubst) → `aws apigatewayv2 reimport-api …` (`/workflow/github-actions`).

## Downstream
- **API Gateway:** root contract + AWS overlay → reimport — `/infrastructure/api-gateway`.
- **Clients/tests:** Postman/newman + consumers read the committed root copy — `/backend/postman`.

## Conventions
- `info.version` **==** backend `VERSION`; `info.title` == the service name.
- The root copy is regenerated + committed every release; a stale root copy is a **failing gate**.
- snake_case schemas (matches the API). **Never hand-edit** the generated file; keep AWS extensions in the overlay template, out of the neutral root copy.

## Pros & cons
**Pros**
- Contract generated from code — no drift; version-stamped, committed root copy.
- AWS overlay applied only at deploy (clean source contract).
**Cons**
- A generation step in CI.
- zod-openapi annotations to maintain.
