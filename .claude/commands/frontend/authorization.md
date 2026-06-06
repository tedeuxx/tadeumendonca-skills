Implement or review SPA authorization (UI gating) in tadeumendonca-fed.

Context: $ARGUMENTS

Client-side authorization is **UX only** — it decides what to *render*, not what's *allowed*. The real enforcement is server-side: the **API GW Cognito authorizer** + action-type RBAC in the backend (`/backend/action-types`). The SPA reads the user's groups/claims from the authenticated session (`/frontend/authentication`) to show/hide UI.

## Read role from the session
```typescript
import { fetchAuthSession } from 'aws-amplify/auth';
export function useAuth() {
  return useQuery({ queryKey: ['auth'], queryFn: () => fetchAuthSession(), retry: false });
}
export const useIsAdmin = () => {
  const groups = (useAuth().data?.tokens?.idToken?.payload?.['cognito:groups'] as string[]) ?? [];
  return groups.includes('admin');
};
```

## Guard admin routes
```typescript
export function RequireAuth({ children }: { children: ReactNode }) {
  const { data, isLoading } = useAuth();
  if (isLoading) return <Spinner />;
  const groups = (data?.tokens?.idToken?.payload?.['cognito:groups'] as string[]) ?? [];
  if (!groups.includes('admin')) return <Navigate to="/" replace />;
  return <>{children}</>;
}
```

## Conventions
- **Client gating is cosmetic** — never the security boundary. Every protected call is enforced again server-side (`/infrastructure/api-gateway`, `/backend/action-types`).
- Drive UI from `cognito:groups` (the 3 profiles — `/infrastructure/cognito`) or, for finer control, the **allowed-actions** the BFF can expose (a `/me` route) for feature toggles (`/backend/action-types`).
- No secrets/PII in client logic; a hidden admin button is not protection.
