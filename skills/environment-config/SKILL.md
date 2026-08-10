---
description: Configure an application from one contract — a dotenv file per environment behind a typed accessor at server runtime, and parameter-store values baked into a browser bundle at build time as VITE_ prefixed variables, nothing sensitive on either path. Use when adding a config key, wiring a deploy job to fetch configuration, or explaining why a client value change needs a rebuild. Not for sensitive values (see secrets-management) or writing the parameters (see ssm).
family: backend
---

Configure an application's non-secret values — server runtime and browser build alike.

Context: $ARGUMENTS

**One contract, two delivery mechanisms.** Both sides obey the same three rules — a single typed
accessor, non-secret values only, and the same key present in every environment — and they differ only
in *when* the value arrives. Which mechanism applies is decided by one question, and it is worth asking
explicitly rather than by habit:

> **Can the consumer read a value at the moment it runs?** A server process can, so its config is
> **runtime**. A static bundle already sitting in a browser cannot, so its config is **build-time** —
> baked in, public, and changed only by rebuilding.

Everything below follows from that one answer. Sensitive values follow neither path (see
`/secrets-management`); the parameters themselves are written by infrastructure
(`/ssm`).

## Server side — `.env.{environment}` (dotenv) + one typed accessor

Non-secret, per-environment config lives in committed `.env.{environment}` files; a single `config`
module is the only place that reads `process.env`.

```
.env.staging       # non-secret defaults for staging
.env.production    # non-secret defaults for production
.env.local         # local dev overrides (gitignored)
```

**Loading (local + tests only):**

```typescript
// in a deployed function these keys are injected by IaC env vars; dotenv is a local/test convenience
import dotenv from 'dotenv';
dotenv.config({ path: `.env.${process.env.ENVIRONMENT ?? 'local'}` });
```

**Typed accessor** — the only module that touches `process.env`, and the only place a missing key is
allowed to be discovered:

```typescript
function required(name: string): string {
  const v = process.env[name];
  if (!v) throw new Error(`Missing required env var: ${name}`);
  return v;
}

export const config = {
  environment:    required('ENVIRONMENT'),          // staging | production
  logLevel:       process.env.LOG_LEVEL ?? 'INFO',
  ogImagesBucket: required('OG_IMAGES_BUCKET'),
  redisEndpoint:  required('REDIS_ENDPOINT'),
  redisSecretArn: process.env.REDIS_SECRET_ARN,     // secret ARN — the value is fetched at runtime
  // table names (IaC injects them from the parameter store); access is pure IAM, no secret
  profileTable:       required('PROFILE_TABLE'),
  postsTable:         required('POSTS_TABLE'),
  articlesTable:      required('ARTICLES_TABLE'),
  subscriptionsTable: required('SUBSCRIPTIONS_TABLE'),
  auditsTable:        required('AUDITS_TABLE'),
} as const;
```

`required()` throwing at module load is the point: the process fails on the first invocation with a
clear message, rather than at 3am inside a handler with an `undefined` in a table name.

**Two sources, one shape:** `.env.{environment}` populates `process.env` locally; in the cloud the
**same keys** are injected by IaC. The `config` module does not care which, which is what makes local
and deployed behaviour comparable at all.

## Client side — parameter store → CI → `VITE_*` at build

A static bundle has no runtime config source, so CI reads the values and injects them as `VITE_*`
**before** the build; a single typed accessor is again the only place that reads them.

- **Source of truth = the parameter store** (written by infrastructure); the deploy workflow fetches and
  injects (`/github-actions`, `/ssm`).
- **Typical keys:** API base URL, identity-provider ids and hosted-UI domain, analytics measurement id,
  RUM app-monitor and identity-pool ids (`/cloudwatch-rum`), region.
- **One typed accessor**; components and services never read the injected variables directly.
- **A value change requires a rebuild and redeploy.** There is no way to change a baked value in place,
  and treating one as if it were runtime-configurable is the recurring mistake here.

## Conventions

- **Nothing sensitive on either path, for two different reasons.** On the server, secrets are fetched at
  runtime from a secret store, so `.env.*` holds only non-secret values plus ARNs and endpoints — never
  passwords or tokens. In a bundle it is stronger than a convention: **everything shipped to a browser
  is public**, so a secret in a `VITE_*` variable is already disclosed, and no amount of care at build
  time recovers it. An ARN or an endpoint is fine on both; a credential is fine on neither.
- **One accessor per side.** Handlers and components never read the environment directly, so the set of
  keys an application depends on is enumerable by reading one file.
- **The same key exists in every environment**, even when the value differs. The failure mode this
  prevents is a key added to one environment and missing in another, which passes every test and fails
  once deployed.
- `.env.*` files are **not a deploy artifact** — the bundle must not embed them.
- Local overrides (`.env.local`) are gitignored, and no secret is committed on any path.

## Pros & cons

**Pros**
- One typed, validated accessor per side; a missing key fails fast and by name.
- Configuration has a single source of truth that both delivery mechanisms draw from.
- Non-secrets only, stated as a rule on the server and guaranteed by physics in the browser.
- Local and deployed runs share a key shape, so a local reproduction is meaningful.

**Cons**
- Client values are build-time only — changing one needs a rebuild and a redeploy.
- Client values are public, so the "is this really non-secret" judgement is load-bearing and easy to get
  wrong under time pressure.
- Drift risk if a variable is added in one environment but not another.
- The deploy job must inject the right values, so a configuration error surfaces as an application bug
  rather than a pipeline failure.
