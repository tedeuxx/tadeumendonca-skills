Loading / empty / error UX states in <project>-fed (concept).

Context: $ARGUMENTS

Conceptual skill — consistent async UX + error boundaries. Components/snippets live in `/frontend/framework-react` and `/frontend/design-system`.

## Every async view handles four states
- **Loading** → spinner/skeleton (Cloudscape `Spinner`).
- **Empty** → a clear empty state, never a blank screen.
- **Error** → `Alert` with the BFF `{ error, message }` + a retry (`/frontend/api-client`).
- **Success** → the content.
React Query exposes `isLoading` / `isError` / `data` — branch on them uniformly.

## Error boundaries
- A React **ErrorBoundary** around route subtrees catches render-time errors → fallback UI (don't white-screen); report to RUM (`/frontend/cloudwatch-rum`).
- Network/HTTP errors are handled at the query/mutation layer, not in boundaries.

## Conventions
- One shared set of loading/empty/error components reused everywhere — develop in `/frontend/storybook`.
- Never leave a pending action without feedback; disable buttons while mutating.
- `401` is special: re-auth, don't show a generic error (`/frontend/authentication`).

## Pros & cons
**Pros**
- Consistent async UX; error boundaries prevent white-screens; one reused set of loading/empty/error components.
**Cons**
- Every async view must handle four states (discipline).
- Boundary fallbacks need designing.
