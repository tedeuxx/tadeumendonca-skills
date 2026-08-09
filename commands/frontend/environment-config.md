---
description: Inject build-time configuration into a React SPA — values read from the parameter store in CI and baked in as VITE_ prefixed variables, behind one typed accessor, with nothing secret because the bundle is public. Use when adding a config key, wiring a deploy job to fetch configuration, or explaining why a value change needs a rebuild. Not for server-side runtime config (see backend/environment-config) or writing the parameters (see infrastructure/ssm).
---

Frontend environment config in the SPA (concept).

Context: $ARGUMENTS

Conceptual skill — the config contract. The Vite / `import.meta.env` snippet lives in `/frontend/framework-react`.

Config is **build-time** (static SPA): CI reads values from **SSM** and injects them as `VITE_*` before the build; a single **typed accessor** is the only place that reads them.

## Contract
- Source of truth = **SSM** (written by IaC); `deploy.yml` fetches + injects (`/workflow/github-actions`, `/infrastructure/ssm`).
- Keys: API base URL, Cognito ids/hosted-UI, GA measurement id, RUM app-monitor + identity-pool ids, region.
- One typed accessor; components/services never read env directly.

## Conventions
- **Build-time only** — values are baked into the bundle; **never secrets** in `VITE_*` (everything shipped to the browser is public).
- `.env.{environment}` for local/tests only; no committed secrets. Backend counterpart: `/backend/environment-config`.

## Pros & cons
**Pros**
- Typed accessor; config sourced from SSM at build (single source of truth); no secrets in the bundle.
**Cons**
- Build-time only — a value change needs a rebuild.
- `VITE_*` values are public (shipped in the bundle).
