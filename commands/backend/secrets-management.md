Fetch sensitive backend values from AWS Secrets Manager in <project>-api.

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

## Pros & cons
**Pros**
- Secrets never in env/code; fetched at runtime and cached in memory.
- Only the ARN travels via env/SSM.
**Cons**
- Cold-fetch latency on first use.
- Cache must be invalidated on rotation.
