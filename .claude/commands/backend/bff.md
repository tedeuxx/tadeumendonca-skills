Implement or review the Backend-for-Frontend (BFF) for the fed SPA.

Context: $ARGUMENTS

## Pattern: the BFF owns the session; the SPA holds no tokens

The SPA never handles OAuth tokens. A **dedicated BFF Lambda** (Hono — **one per SPA, 1:1**, never shared across frontends) runs the **OIDC Authorization Code + PKCE** flow server-side with Cognito, keeps the tokens server-side, and exposes the SPA only an **httpOnly, Secure, SameSite session cookie**. The BFF also proxies/aggregates the domain API for the frontend. This is the standard auth combo for the fed-SPA pattern — it removes tokens from the browser (XSS-safe) and lets responses be tailored to the UI.

## Endpoints (Hono, behind CloudFront / API GW at `/bff/*`)
- `GET  /bff/login`    → redirect to the Cognito hosted UI (auth request, PKCE `code_challenge`, `state`).
- `GET  /bff/callback` → verify `state`, exchange `code` + `code_verifier` for tokens (PKCE), create a server session, set the cookie, redirect to the SPA.
- `POST /bff/logout`   → clear session + cookie, redirect to Cognito logout.
- `GET  /bff/me`       → current user (from session) so the SPA can render auth state.
- `ALL  /bff/api/*`    → proxy to the domain API, injecting the session's access token (silent refresh near expiry).

## Session
- Tokens stored **server-side** — an opaque session id in the cookie, the tokens persisted in **Redis** (`/backend/redis-cache`) or DynamoDB. Never put tokens in the cookie.
- Cookie: `HttpOnly; Secure; SameSite=Lax`; short TTL with refresh-token rotation.
- The PKCE `code_verifier` + `state` live in a short pre-auth session during the redirect.

## Conventions
- Built on Hono (`/backend/framework`), in-VPC, Pattern B; audit/log/metrics via the standard middleware.
- Cognito issuer/client-id/hosted-UI from SSM/env (`/backend/environment-config`); client secret (confidential client) from Secrets Manager (`/backend/secrets-management`).
- The SPA calls `/bff/*` with `credentials: 'include'` and holds **no tokens** — SPA side is `/frontend/cognito-pkce`. Blueprint: `/architecture/fed-spa`.
