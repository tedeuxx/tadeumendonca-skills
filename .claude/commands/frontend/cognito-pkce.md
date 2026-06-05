Implement or update Cognito PKCE authentication in tadeumendonca-fed.

Context: $ARGUMENTS

## Flow overview
1. User clicks "Sign in" → redirect to `https://auth.{env}.tadeumendonca.io/login?response_type=code&client_id=...`
2. Cognito handles login → redirects to `/callback?code=...`
3. `CallbackPage.tsx` exchanges code for tokens → stores in `authStore`
4. `RequireAuth.tsx` guards admin routes by checking `isAdmin` from store

## `src/store/authStore.ts` (Zustand + persist)

```typescript
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface AuthState {
  accessToken: string | null;
  isAdmin: boolean;
  setTokens: (accessToken: string, groups: string[]) => void;
  clearTokens: () => void;
}

export const useAuthStore = create<AuthState>()(persist(
  (set) => ({
    accessToken: null,
    isAdmin: false,
    setTokens: (accessToken, groups) => set({ accessToken, isAdmin: groups.includes('admin') }),
    clearTokens: () => set({ accessToken: null, isAdmin: false }),
  }),
  { name: 'auth' }
));
```

## `src/pages/auth/CallbackPage.tsx`

Exchange `?code=` for tokens using Cognito token endpoint, decode JWT to extract `cognito:groups`, call `setTokens`.

## `src/components/auth/RequireAuth.tsx`

```typescript
export function RequireAuth({ children }: { children: ReactNode }) {
  const isAdmin = useAuthStore(s => s.isAdmin);
  if (!isAdmin) return <Navigate to="/" replace />;
  return <>{children}</>;
}
```

## Env vars (injected at build time by Vite)
- `VITE_COGNITO_CLIENT_ID` — Cognito app client ID (from SSM)
- `VITE_COGNITO_HOSTED_UI_URL` — `https://auth.{env}.tadeumendonca.io` (from SSM)
- `VITE_API_BASE_URL` — `https://api.{env}.tadeumendonca.io` (from SSM)
