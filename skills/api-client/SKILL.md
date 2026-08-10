---
description: Call the backend from a React SPA through one typed client — base URL from build-time config, Bearer token attached, snake_case payloads with no mapping layer, cached queries and mutations that invalidate what they changed. Use when adding a data call, centralising 401 handling, or removing a raw fetch from a component. Not for the page-by-page cursor contract (see pagination).
family: frontend
---

SPA → BFF API calls (concept).

Context: $ARGUMENTS

Conceptual skill — how the SPA talks to the BFF. The fetch / React-Query snippet lives in `/framework-react`.

The SPA calls **one backend — the BFF** (`/bff`) at the base URL from SSM. Every call carries the Cognito access token; responses are **screen-shaped** (the BFF aggregates). Data access goes through a typed client + a server-state cache, never raw `fetch` in components.

## Contract
- **Base URL** from `env.apiBaseUrl` (SSM — `/environment-config`).
- **Auth:** attach `Authorization: Bearer <access_token>` (`/authentication`); on `401` → re-auth.
- **Errors:** the BFF returns `{ error, message }` (snake_case) with the right status — surface them uniformly.
- **Reads** = cached queries (keyed by resource + params); **writes** = mutations that **invalidate** the affected queries.
- **Pagination** via the cursor contract (`/pagination`).

## Conventions
- One typed API-client module; components/hooks use it — never call `fetch` directly.
- snake_case payloads (matches the BFF — no mapping layer).
- Sane timeouts; **don't retry 4xx**. Loading/error/empty states from `/design-system`.

## Pros & cons
**Pros**
- React Query gives caching, dedup, refetch, invalidation for free; Bearer auto-attached.
- 401 handling centralized in one client.
**Cons**
- React Query cache model is a learning curve.
- Another abstraction over `fetch`.
