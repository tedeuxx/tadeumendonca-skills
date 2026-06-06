Implement or review SPA authentication in tadeumendonca-fed.

Context: $ARGUMENTS

Authentication lives in the **frontend (Cognito SDK) + the API GW authorizer** — not in the BFF. The SPA authenticates directly with Cognito via the SDK (AWS Amplify Auth), which **holds and refreshes the JWT**; every API call carries `Authorization: Bearer <access_token>`; the API GW Cognito authorizer validates it (`/infrastructure/api-gateway`); the BFF reads claims, no auth code (`/backend/bff`). The Cognito **service** (pool, app client, hosted UI, groups) is `/infrastructure/cognito`.

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
Config values come from SSM at build time (`/frontend/environment-config`) — never hardcoded.

## Login / logout / token
```typescript
import { signInWithRedirect, signOut, fetchAuthSession } from 'aws-amplify/auth';
// login: signInWithRedirect();   logout: signOut();
const { tokens } = await fetchAuthSession();           // SDK caches + refreshes
const jwt = tokens?.accessToken?.toString();
// services/api.ts injects it on every call:
fetch(`${env.apiBaseUrl}/posts`, { headers: { Authorization: `Bearer ${jwt}` } });
```
A `401` from the API → re-auth (`signInWithRedirect`). The `/callback` route lets the SDK finish the code exchange.

## Conventions
- The **Cognito SDK owns tokens** (storage + refresh) — don't hand-roll PKCE/token exchange.
- Send `Authorization: Bearer` to the BFF; the **API GW authorizer** validates.
- Role-based UI gating is `/frontend/authorization`; blueprint `/architecture/fed-spa-bff-monolith`.
