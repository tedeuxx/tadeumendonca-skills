Configure and access build-time environment config in tadeumendonca-fed (Vite).

Context: $ARGUMENTS

## Approach: Vite `VITE_*` env vars + a typed `env.ts` accessor

Config is injected at **build time** by Vite (it's a static SPA — no runtime env). The CI `deploy.yml` reads values from **SSM** and exports them as `VITE_*` before `vite build`. A single typed `env.ts` is the only place that touches `import.meta.env`.

## Variables (from SSM, injected at build)
```
VITE_API_BASE_URL           # /{env}/api/gateway-url
VITE_COGNITO_CLIENT_ID      # /{env}/auth/cognito-client-id
VITE_COGNITO_HOSTED_UI_URL  # /{env}/auth/cognito-hosted-ui-url
VITE_ENVIRONMENT            # staging | production
```

## Typed accessor: src/env.ts
```typescript
function required(key: keyof ImportMetaEnv): string {
  const v = import.meta.env[key];
  if (!v) throw new Error(`Missing build env: ${String(key)}`);
  return v as string;
}
export const env = {
  apiBaseUrl:      required('VITE_API_BASE_URL'),
  cognitoClientId: required('VITE_COGNITO_CLIENT_ID'),
  cognitoHostedUi: required('VITE_COGNITO_HOSTED_UI_URL'),
  environment:     import.meta.env.VITE_ENVIRONMENT ?? 'staging',
} as const;
```

## Local dev
`.env.local` (gitignored) with the `VITE_*` keys; `.env.example` documents them (no secrets).

## Conventions
- **Build-time only** — values are baked into the bundle; **never put secrets in `VITE_*`** (anything shipped to the browser is public).
- Source of truth is **SSM** (written by IaC); `deploy.yml` fetches + injects — never hardcode URLs/IDs. See `/workflow/deploy-fed`, `/infrastructure/ssm-config-bus`.
- One accessor (`env`) — components/services never read `import.meta.env` directly.
- This is the frontend counterpart of the backend `/backend/environment-config`.
