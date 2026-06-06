Frontend state management in <project>-fed (concept).

Context: $ARGUMENTS

Conceptual skill — what state goes where. Library snippets live in `/frontend/framework-react`.

## Three kinds of state, three owners
- **Server state → React Query** (`/frontend/api-client`, `/frontend/pagination`): anything from the BFF — cached, keyed, refetched, invalidated on mutation. The cache *is* the source of truth for remote data.
- **Client / UI state → Zustand** (or local component state): ephemeral UI (modals, filters, form drafts, theme). Small, non-authoritative.
- **Auth/session → the Cognito SDK** (`/frontend/authentication`), read via `fetchAuthSession` — never a store.

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
