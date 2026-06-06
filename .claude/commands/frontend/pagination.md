Cursor pagination in tadeumendonca-fed (concept).

Context: $ARGUMENTS

Conceptual skill — the pagination contract + infinite-scroll UX. The React Query snippet lives in `/frontend/framework-react`; the server-side cursor query in `/backend/document-db`.

## Contract
- **Request:** `?cursor=<opaque>&limit=N` (omit `cursor` for the first page).
- **Response:** `{ items: [...], next_cursor: string | null }` (snake_case) — `next_cursor = null` means end.
- **Cursor, not offset** — an opaque token over the indexed sort key; stays index-efficient and survives re-ordering (`/backend/document-db`).

## UX (infinite scroll)
- Fetch the next page when a **sentinel** near the list end enters the viewport (IntersectionObserver); append items.
- Cache + dedupe pages client-side; show a loading sentinel; the same contract serves posts, articles, etc.

## Conventions
- The frontend never computes offsets — it only echoes back `next_cursor`.
