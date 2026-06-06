Configure and validate backend environments in <project>-api.

Context: $ARGUMENTS

## Approach: `.env.{environment}` (dotenv) + one typed accessor

Non-secret, per-environment config lives in committed `.env.{environment}` files; a single `config` module is the only place that reads `process.env`. **Secrets never live here** — they come from Secrets Manager at runtime (see `/backend/secrets-management`).

```
.env.staging       # non-secret defaults for staging
.env.production    # non-secret defaults for production
.env.local         # local dev overrides (gitignored)
```

## Loading (local + tests only)

```typescript
// in deployed Lambda these keys are injected by IaC env vars; dotenv is a local/test convenience
import dotenv from 'dotenv';
dotenv.config({ path: `.env.${process.env.ENVIRONMENT ?? 'local'}` });
```

## Typed accessor: src/shared/config/index.ts

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
  redisSecretArn: process.env.REDIS_SECRET_ARN,     // Redis AUTH ARN — value fetched at runtime
  // DynamoDB table names (IaC injects from SSM); access is pure IAM, no secret
  profileTable:       required('PROFILE_TABLE'),
  postsTable:         required('POSTS_TABLE'),
  articlesTable:      required('ARTICLES_TABLE'),
  subscriptionsTable: required('SUBSCRIPTIONS_TABLE'),
  auditsTable:        required('AUDITS_TABLE'),
} as const;
```

## Conventions
- **Two sources, one shape:** `.env.{environment}` populates `process.env` locally; in the cloud the **same keys** are injected by IaC (`environment_variables`, api.tf). The `config` module doesn't care which.
- `.env.*` holds **only non-secret values** plus ARNs/endpoints — never passwords/tokens.
- The esbuild bundle (`dist/`) must not embed `.env` files — they're not a deploy artifact.
- One accessor (`config`) — handlers never read `process.env` directly.

## Pros & cons
**Pros**
- Typed, validated config accessor; per-env dotenv files.
- Non-secrets only — secrets stay in Secrets Manager.
**Cons**
- Build/deploy must inject the right env values.
- Drift risk if a var is added in one env but not another.
