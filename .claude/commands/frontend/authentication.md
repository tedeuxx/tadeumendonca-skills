SPA authentication in tadeumendonca-fed (concept).

Context: $ARGUMENTS

Conceptual skill — the auth contract. React/Amplify snippets live in `/frontend/framework-react`.

Authentication is **external to the BFF**: the SPA uses the **Cognito IdP SDK** to log in and **hold/refresh the JWT**, then sends `Authorization: Bearer <access_token>` on every API call. The **API GW Cognito authorizer** validates it (`/infrastructure/api-gateway`); the BFF reads claims, no auth code (`/backend/bff`). The Cognito service is `/infrastructure/cognito`.

## Contract
- Login → redirect to the Cognito hosted UI (Authorization Code + **PKCE**); the callback completes the exchange; the SDK stores + refreshes tokens.
- Every BFF call carries the access token as a Bearer header (`/frontend/api-client`).
- `401` → re-authenticate.
- Config (pool/client/hosted-UI ids) from **SSM** at build time (`/frontend/environment-config`).

## Conventions
- The **SDK owns tokens** — never hand-roll PKCE/token exchange or store tokens manually.
- Role-based UI gating is `/frontend/authorization`. Blueprint: `/architecture/fed-spa-bff-monolith`.
