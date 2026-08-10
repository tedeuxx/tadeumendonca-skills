---
description: Handle the four async states in every React SPA view — loading, empty, error with a retry, and success — plus an ErrorBoundary around route subtrees so a render failure does not white-screen. Use when a view fetches data, when a pending action gives no feedback, or when errors are rendered inconsistently across screens. Not for the primitives themselves (see design-system).
---

Loading / empty / error UX states in the SPA (concept).

Context: $ARGUMENTS

Conceptual skill — consistent async UX + error boundaries. Components/snippets live in `/framework-react` and `/design-system`.

## Every async view handles four states
- **Loading** → spinner/skeleton (own primitive).
- **Empty** → a clear empty state, never a blank screen.
- **Error** → `Alert` with the BFF `{ error, message }` + a retry (`/api-client`).
- **Success** → the content.
React Query exposes `isLoading` / `isError` / `data` — branch on them uniformly.

## Error boundaries
- A React **ErrorBoundary** around route subtrees catches render-time errors → fallback UI (don't white-screen); report to RUM (`/cloudwatch-rum`).
- Network/HTTP errors are handled at the query/mutation layer, not in boundaries.

## Conventions
- One shared set of loading/empty/error components reused everywhere — develop in `/storybook`.
- Never leave a pending action without feedback; disable buttons while mutating.
- `401` is special: re-auth, don't show a generic error (`/authentication`).

## Pros & cons
**Pros**
- Consistent async UX; error boundaries prevent white-screens; one reused set of loading/empty/error components.
**Cons**
- Every async view must handle four states (discipline).
- Boundary fallbacks need designing.
