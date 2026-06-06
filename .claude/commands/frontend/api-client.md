SPA → BFF API calls in tadeumendonca-fed (concept).

Context: $ARGUMENTS

Conceptual skill — how the SPA talks to the BFF. The fetch / React-Query snippet lives in `/frontend/framework-react`.

The SPA calls **one backend — the BFF** (`/backend/bff`) at the base URL from SSM. Every call carries the Cognito access token; responses are **screen-shaped** (the BFF aggregates). Data access goes through a typed client + a server-state cache, never raw `fetch` in components.

## Contract
- **Base URL** from `env.apiBaseUrl` (SSM — `/frontend/environment-config`).
- **Auth:** attach `Authorization: Bearer <access_token>` (`/frontend/authentication`); on `401` → re-auth.
- **Errors:** the BFF returns `{ error, message }` (snake_case) with the right status — surface them uniformly.
- **Reads** = cached queries (keyed by resource + params); **writes** = mutations that **invalidate** the affected queries.
- **Pagination** via the cursor contract (`/frontend/pagination`).

## Conventions
- One typed API-client module; components/hooks use it — never call `fetch` directly.
- snake_case payloads (matches the BFF — no mapping layer).
- Sane timeouts; **don't retry 4xx**. Loading/error/empty states from `/frontend/design-system`.
