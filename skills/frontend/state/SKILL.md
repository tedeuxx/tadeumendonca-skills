---
description: Decide where a piece of state lives in a React SPA — server data in React Query, UI state in Zustand, session and auth in the SDK — and what belongs in none of them. Use when adding a store, choosing between a cache and a store, or untangling state duplicated between a server response and local UI. Not for form field state (see forms) or URL state (see routing).
---

Frontend state management (concept).

Context: $ARGUMENTS

Conceptual skill — what state goes where. Library snippets live in `/framework-react`.

## Three kinds of state, three owners
- **Server state → React Query** (`/api-client`, `/pagination`): anything from the BFF — cached, keyed, refetched, invalidated on mutation. The cache *is* the source of truth for remote data.
- **Client / UI state → Zustand** (or local component state): ephemeral UI (modals, filters, form drafts, theme). Small, non-authoritative.
- **Auth/session → the Cognito SDK** (`/authentication`), read via `fetchAuthSession` — never a store.

## Conventions
- **Never mirror server data into Zustand** — it goes stale; derive from React Query.
- Keep stores small and per-domain; persist only non-sensitive UI prefs.
- Prefer **URL / search params** for shareable UI state (active tag, tab) over a store.

## Pros & cons
**Pros**
- Clear ownership: server→React Query, UI→Zustand, session→SDK; no server data mirrored into stores.
**Cons**
- A model to follow consistently.
- Multiple state tools to learn.
