Implement or update SPA authentication in tadeumendonca-fed (BFF + OIDC PKCE).

Context: $ARGUMENTS

## The SPA holds no tokens — auth runs through the BFF

The OIDC Authorization Code + PKCE flow is executed **server-side by the BFF** (`/backend/bff`). The SPA only carries an **httpOnly session cookie** it never reads, and learns who the user is from `GET /bff/me`. No tokens in JS/localStorage, no Zustand token store.

## Flow
1. "Sign in" → `window.location.href = '/bff/login'` (BFF starts PKCE with Cognito).
2. Cognito login → `/bff/callback` (BFF exchanges `code` + `code_verifier`, creates the session, sets the httpOnly cookie) → redirects back to the SPA.
3. SPA reads the session user via `GET /bff/me` (cookie sent automatically).
4. "Sign out" → `POST /bff/logout`.

## Session state: `src/hooks/useAuth.ts` (React Query, not tokens)
```typescript
export function useAuth() {
  return useQuery({
    queryKey: ['me'],
    queryFn: () => api.get('/bff/me'),       // { user_id, email, groups } or 401
    retry: false, staleTime: 5 * 60_000,
  });
}
export const useIsAdmin = () => (useAuth().data?.groups ?? []).includes('admin');
```

## `src/components/auth/RequireAuth.tsx`
```typescript
export function RequireAuth({ children }: { children: ReactNode }) {
  const { data, isLoading } = useAuth();
  if (isLoading) return <Spinner />;
  if (!data?.groups?.includes('admin')) return <Navigate to="/" replace />;
  return <>{children}</>;
}
```

## API access
All API calls go to `/bff/api/*` via `services/api.ts` with `credentials: 'include'` — the BFF injects the access token. The SPA never sends an `Authorization` header. A `401` from the BFF means "not logged in" → send the user to `/bff/login`.

## Conventions
- **No tokens** in any store; the only durable auth state is the httpOnly cookie (set/cleared by the BFF).
- A tiny Zustand store may hold **non-sensitive UI state** (e.g. cached display name) — never tokens.
- Build-time config (`VITE_*`) via `/frontend/environment-config`; auth/session design in `/backend/bff`; blueprint `/architecture/fed-spa`.
