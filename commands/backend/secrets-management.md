Fetch sensitive backend values from AWS Secrets Manager in `apps/bff`.

Context: $ARGUMENTS

## Rule

**Every sensitive value comes from Secrets Manager at runtime** — never from `.env`, SSM plain text, hardcode, or tfvars. IaC stores only the **ARN** (env var / SSM); the Lambda fetches the value on cold start and caches it in memory.

In Secrets Manager: the Redis AUTH token (`REDIS_SECRET_ARN`), third-party API keys (e.g. the Giphy key for the blog editor's GIF-search proxy, `GIPHY_SECRET_ARN` — an out-of-band secret, see `/infrastructure/secrets-manager`), and any future tokens. The **data tier has no secret** — DynamoDB access is pure IAM via the Lambda exec role, so there's no DB credential to fetch here. Non-secret config stays in `.env`/IaC env vars (see `/backend/environment-config`).

## Singleton + in-memory cache: src/shared/secrets.ts

```typescript
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

const sm = new SecretsManagerClient({});             // module-level, reused across invocations
const cache = new Map<string, unknown>();

export async function getSecret<T>(secretArn: string): Promise<T> {
  if (cache.has(secretArn)) return cache.get(secretArn) as T;
  const { SecretString } = await sm.send(new GetSecretValueCommand({ SecretId: secretArn }));
  const value = JSON.parse(SecretString!) as T;
  cache.set(secretArn, value);                       // cache for the warm container lifetime
  return value;
}
```

## Usage

```typescript
const { auth_token } = await getSecret(config.redisSecretArn);                       // redis client
```

## Conventions
- Secret JSON fields are **snake_case** (`auth_token`, `dbname`).
- Fetch by **ARN** from `config`; the ARN itself is non-sensitive (fine in env var / SSM).
- IAM: Lambda role needs `secretsmanager:GetSecretValue` scoped to `<project>/{env}/*` (`policy_statements`, api.tf).
- Cache in memory for the container lifetime; never re-fetch per request. Rotation is picked up on the next cold start.
- Naming: `<project>/{env}/{component}` (e.g. `<project>/staging/redis`). The data tier needs no secret — DynamoDB is IAM-only (`/infrastructure/dynamodb`). See `/infrastructure/elasticache`.

## Decision & trade-off
- **Pattern B for secrets: IaC owns the config (the ARN in env/SSM); code reads the value at runtime.** The secret value never sits in the env, the bundle, tfvars, or state — only the non-sensitive ARN travels there. Cross-ref the Lambda Pattern-B split (`/infrastructure/lambda`). *Trade-off:* a runtime fetch (one cold-start round trip to Secrets Manager) instead of baking the value into an env var.
- **Fetched once per cold start, then cached in process memory** (module-level client + `Map`), never re-fetched per request. *Trade-off:* a rotation is only picked up on the next cold start — acceptable for tokens that rotate rarely; force a new deploy to roll one immediately.
- **Only genuinely-secret values go here; the data tier has none.** DynamoDB is pure IAM (no DB credential), so non-secret config (table names, endpoints, ARNs) stays in env vars (`/backend/environment-config`). *Trade-off:* a clear two-bucket split to maintain — putting a non-secret in Secrets Manager wastes a fetch; putting a secret in env leaks it.

## Pros & cons
**Pros**
- Secrets never in env/code; fetched at runtime and cached in memory.
- Only the ARN travels via env/SSM.
**Cons**
- Cold-fetch latency on first use.
- Cache must be invalidated on rotation.
