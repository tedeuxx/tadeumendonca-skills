Implement or update SPA authentication in tadeumendonca-fed (Cognito SDK).

Context: $ARGUMENTS

## Auth lives in the frontend (Cognito SDK) + the API GW authorizer — not in the BFF

The SPA authenticates **directly with Cognito using the Cognito SDK** (AWS Amplify Auth / `amazon-cognito-identity-js`). The SDK runs the OIDC + PKCE login, **stores and refreshes the JWT**, and the SPA sends `Authorization: Bearer <access_token>` to the BFF. The **API Gateway Cognito JWT authorizer** validates it; the BFF has no auth code (`/backend/bff`). This keeps app code simple.

## Setup (Amplify Auth)
```typescript
import { Amplify } from 'aws-amplify';
Amplify.configure({ Auth: { Cognito: {
  userPoolId: env.cognitoUserPoolId,
  userPoolClientId: env.cognitoClientId,             // public client, PKCE
  loginWith: { oauth: {
    domain: env.cognitoHostedUi, scopes: ['openid','email','profile'],
    redirectSignIn: [`${location.origin}/callback`], responseType: 'code',
  } },
} } });
```
Config values come from SSM at build time (`/frontend/environment-config`).

## Usage
```typescript
import { signInWithRedirect, signOut, fetchAuthSession } from 'aws-amplify/auth';
// login: signInWithRedirect();   logout: signOut();
const { tokens } = await fetchAuthSession();           // SDK caches + refreshes
const jwt = tokens?.accessToken?.toString();
// services/api.ts injects it on every call:
fetch(`${env.apiBaseUrl}/posts`, { headers: { Authorization: `Bearer ${jwt}` } });
```

## Auth state & guards
```typescript
export function useAuth() {
  return useQuery({ queryKey: ['auth'], queryFn: () => fetchAuthSession(), retry: false });
}
export const useIsAdmin = () => {
  const groups = (useAuth().data?.tokens?.idToken?.payload?.['cognito:groups'] as string[]) ?? [];
  return groups.includes('admin');
};
// RequireAuth guards admin routes off isAdmin; a 401 from the API → re-auth (signInWithRedirect)
```

## Conventions
- The **Cognito SDK owns tokens** (storage + refresh) — don't hand-roll PKCE/token exchange.
- Send `Authorization: Bearer` to the BFF; the **API GW authorizer** validates (`/infrastructure/api-gateway`). The BFF only reads claims.
- `cognito:groups` drives **client-side UI gating**; real authz is enforced server-side via the authorizer + action types (`/backend/action-types`).
- Config from SSM/env (`/frontend/environment-config`); blueprint `/architecture/fed-spa-bff-monolith`.
