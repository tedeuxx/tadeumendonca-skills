Fetch sensitive backend values from AWS Secrets Manager in tadeumendonca-api.

Context: $ARGUMENTS

## Rule

**Every sensitive value comes from Secrets Manager at runtime** — never from `.env`, SSM plain text, hardcode, or tfvars. IaC stores only the **ARN** (env var / SSM); the Lambda fetches the value on cold start and caches it in memory.

In Secrets Manager: DocumentDB credentials (`DOCDB_SECRET_ARN`), Redis AUTH token (`REDIS_SECRET_ARN`), and any future API keys/tokens. Non-secret config stays in `.env`/IaC env vars (see `/backend/environment-config`).

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
const { username, password, host, port } = await getSecret(config.docdbSecretArn);  // db client
const { auth_token } = await getSecret(config.redisSecretArn);                       // redis client
```

## Conventions
- Secret JSON fields are **snake_case** (`auth_token`, `dbname`).
- Fetch by **ARN** from `config`; the ARN itself is non-sensitive (fine in env var / SSM).
- IAM: Lambda role needs `secretsmanager:GetSecretValue` scoped to `tadeumendonca/{env}/*` (`policy_statements`, api.tf).
- Cache in memory for the container lifetime; never re-fetch per request. Rotation is picked up on the next cold start.
- Naming: `tadeumendonca/{env}/{component}` (e.g. `tadeumendonca/staging/docdb`, `tadeumendonca/staging/redis`). See `/infrastructure/documentdb-cluster`, `/infrastructure/elasticache-redis`.
