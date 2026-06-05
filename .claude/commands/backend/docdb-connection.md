Set up or review the DocumentDB connection in tadeumendonca-api.

Context: $ARGUMENTS

## Singleton pattern: `src/shared/db/client.ts`

```typescript
import { MongoClient } from 'mongodb';
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

const sm = new SecretsManagerClient({});
let client: MongoClient | null = null;

export async function getDb() {
  if (!client) {
    const { SecretString } = await sm.send(new GetSecretValueCommand({ SecretId: process.env.DOCDB_SECRET_ARN }));
    const { username, password, host, port, dbname } = JSON.parse(SecretString!);
    client = new MongoClient(
      `mongodb://${username}:${encodeURIComponent(password)}@${host}:${port}/${dbname}`,
      {
        tls: true,
        tlsCAFile: '/etc/pki/tls/certs/ca-bundle.crt',
        retryWrites: false,     // DocumentDB: not supported
        directConnection: true, // DocumentDB: required
      }
    );
    await client.connect();
  }
  return client.db('tadeumendonca');
}
```

## Collections: `src/shared/db/collections.ts`

```typescript
export async function getCollections() {
  const db = await getDb();
  return {
    profiles:    db.collection('profiles'),
    posts:       db.collection('posts'),
    articles:    db.collection('articles'),
    subscribers: db.collection('subscribers'),
    audits:      db.collection('audits'),
  };
}
```

## Gotchas
- `retryWrites: false` mandatory — DocumentDB does not support retryable writes
- `directConnection: true` required to avoid topology discovery issues in Lambda
- `DOCDB_SECRET_ARN` env var is set by IaC in api.tf — never hardcode or pass via tfvars
- TLS CA file path is correct for Lambda runtime; Lambda@Edge cannot use this (no VPC)
