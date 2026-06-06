SPA authentication in tadeumendonca-fed (concept).

Context: $ARGUMENTS

Conceptual skill — the auth contract. React/Amplify snippets live in `/frontend/framework-react`.

Authentication is **external to the BFF**: the SPA uses the **Cognito IdP SDK** to log in and **hold/refresh the JWT**, then sends `Authorization: Bearer <access_token>` on every API call. The **API GW Cognito authorizer** validates it (`/infrastructure/api-gateway`); the BFF reads claims, no auth code (`/backend/bff`). The Cognito service is `/infrastructure/cognito`.

## Contract
- Login → redirect to the Cognito hosted UI (Authorization Code + **PKCE**); the callback completes the exchange; the SDK stores + refreshes tokens.
- Every BFF call carries the access token as a Bearer header (`/frontend/api-client`).
- `401` → re-authenticate.
- Config (pool/client/hosted-UI ids) from **SSM** at build time (`/frontend/environment-config`).

## Session lifecycle (OIDC + PKCE)
- **Tokens:** `id_token` (identity/claims for UI), `access_token` (sent as Bearer to the BFF), `refresh_token` (renews the other two).
- **Storage + persistence:** the SDK stores the tokens (default `localStorage`) → the session survives reloads and is shared across tabs. *Trade-off:* tokens in browser storage are an XSS surface — the accepted cost of simplicity vs. a server-side-session BFF (rejected).
- **Silent refresh:** the SDK uses the `refresh_token` to renew the `access_token` before expiry, transparently — the app only calls `fetchAuthSession()`.
- **Expiry:** when the `refresh_token` expires or is revoked, `fetchAuthSession` fails → re-authenticate.
- **Logout:** clearing the session removes the local tokens and redirects to the Cognito logout (global sign-out invalidates the refresh token).

## Conventions
- The **SDK owns tokens + the session** — never hand-roll PKCE/token exchange, refresh, or token storage.
- Role-based UI gating is `/frontend/authorization`. Blueprint: `/architecture/fed-spa-bff-monolith`.
