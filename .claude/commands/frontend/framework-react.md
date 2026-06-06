Implement or review the React frontend framework for tadeumendonca-fed.

Context: $ARGUMENTS

## Stack: React 18 + TypeScript + Vite (CSR SPA, no SSR)
`react-router` · `@tanstack/react-query` · `zustand` · Cloudscape (`/frontend/design-system`) · `aws-amplify` (auth) · `react-markdown`. **This skill is the only place with React/library snippets** — the other frontend skills are framework-agnostic concepts that this wires up.

## Structure
```
src/
├── main.tsx          # providers bootstrap
├── router.tsx        # routes (react-router v6) + RequireAuth
├── env.ts            # typed import.meta.env (/frontend/environment-config)
├── lib/              # api.ts (BFF client), analytics.ts, rum.ts, seo.tsx
├── pages/  components/  hooks/  services/  store/  types/
```

## Bootstrap: main.tsx
```tsx
import { Amplify } from 'aws-amplify';
import { HelmetProvider } from 'react-helmet-async';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
Amplify.configure({ Auth: { Cognito: {
  userPoolId: env.cognitoUserPoolId, userPoolClientId: env.cognitoClientId,
  loginWith: { oauth: { domain: env.cognitoHostedUi, scopes: ['openid','email','profile'],
    redirectSignIn: [`${location.origin}/callback`], responseType: 'code' } } } } });
const qc = new QueryClient();
root.render(<HelmetProvider><QueryClientProvider client={qc}><RouterProvider router={router} /></QueryClientProvider></HelmetProvider>);
```

## Auth (Cognito SDK) — concepts in /frontend/authentication, /frontend/authorization
```typescript
import { signInWithRedirect, signOut, fetchAuthSession } from 'aws-amplify/auth';
const jwt = (await fetchAuthSession()).tokens?.accessToken?.toString();              // SDK holds + refreshes
const groups = ((await fetchAuthSession()).tokens?.idToken?.payload?.['cognito:groups'] as string[]) ?? [];
```

## BFF client — concept in /frontend/api-client
```typescript
export async function apiFetch(path: string, init?: RequestInit) {
  const jwt = (await fetchAuthSession()).tokens?.accessToken?.toString();
  const res = await fetch(`${env.apiBaseUrl}${path}`, { ...init, headers: { ...init?.headers, Authorization: `Bearer ${jwt}` } });
  if (res.status === 401) { await signInWithRedirect(); throw new Error('unauthorized'); }
  if (!res.ok) throw await res.json();        // { error, message }
  return res.json();
}
```

## React Query — queries / mutations / cursor — concept in /frontend/pagination
```typescript
export const usePosts = () => useInfiniteQuery({ queryKey: ['posts'],
  queryFn: ({ pageParam }) => apiFetch(`/posts?cursor=${pageParam ?? ''}`),
  getNextPageParam: (last) => last.next_cursor });
export const useCreatePost = () => { const qc = useQueryClient();
  return useMutation({ mutationFn: (b) => apiFetch('/posts', { method: 'POST', body: JSON.stringify(b) }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['posts'] }) }); };
```

## SEO / Analytics / RUM — concepts in /frontend/seo, /frontend/analytics, /frontend/cloudwatch-rum
```tsx
<Helmet><title>…</title><meta name="description" /* … */ /><script type="application/ld+json">{JSON.stringify(jsonLd)}</script></Helmet>
window.gtag?.('event', 'page_view', { page_path });                                  // GA4
new AwsRum(env.rumAppMonitorId, '1.0.0', env.region, { sessionSampleRate: 0.1, identityPoolId: env.rumIdentityPoolId, enableXRay: true });
```

## Routing + guards
```tsx
// router.tsx — react-router v6; <RequireAuth> gates admin routes off cognito:groups (/frontend/authorization)
```

## Testing (vitest + RTL)
Unit/component tests run on **vitest** + React Testing Library (`environment: 'jsdom'`); the coverage gate (≥ 85%) is the agnostic policy in `/frontend/coverage`. Thresholds in `vitest.config.ts`:
```ts
test: { environment: 'jsdom', coverage: { provider: 'v8', thresholds: { lines: 85, functions: 85, branches: 85, statements: 85 } } }
```
E2E is Playwright, not vitest (`/frontend/playwright`). lcov feeds SonarCloud (`/workflow/sonarcloud`).

## Conventions
- **Only this skill carries React/library code**; the concept skills (authentication, authorization, api-client, pagination, seo, analytics, cloudwatch-rum, environment-config, forms, markdown) stay agnostic.
- snake_case API payloads (no mapping layer); build-time config from SSM (`/frontend/environment-config`).
- Content-hashed assets (immutable); cache split + invalidation in `/workflow/github-actions`. UI primitives from `/frontend/design-system`; components developed in `/frontend/storybook`.
