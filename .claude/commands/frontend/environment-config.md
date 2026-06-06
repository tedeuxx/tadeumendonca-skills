Frontend environment config in tadeumendonca-fed (concept).

Context: $ARGUMENTS

Conceptual skill — the config contract. The Vite / `import.meta.env` snippet lives in `/frontend/framework-react`.

Config is **build-time** (static SPA): CI reads values from **SSM** and injects them as `VITE_*` before the build; a single **typed accessor** is the only place that reads them.

## Contract
- Source of truth = **SSM** (written by IaC); `deploy.yml` fetches + injects (`/workflow/deploy-fed`, `/infrastructure/ssm-config-bus`).
- Keys: API base URL, Cognito ids/hosted-UI, GA measurement id, RUM app-monitor + identity-pool ids, region.
- One typed accessor; components/services never read env directly.

## Conventions
- **Build-time only** — values are baked into the bundle; **never secrets** in `VITE_*` (everything shipped to the browser is public).
- `.env.{environment}` for local/tests only; no committed secrets. Backend counterpart: `/backend/environment-config`.
