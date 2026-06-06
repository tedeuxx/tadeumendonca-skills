Implement or review backend caching with Redis (ElastiCache) in <project>-api.

Context: $ARGUMENTS

## Pattern: cache-aside (lazy), fail-open

Read public, read-heavy data through Redis; on miss, read DocumentDB and populate with a TTL. **If Redis is unavailable, fall back to the database — a cache error must never fail the request.**

## Client singleton: src/shared/cache/client.ts

```typescript
import Redis from 'ioredis';
import { getSecret } from '../secrets';
import { config } from '../config';
import { logger } from '../middleware/powertools';

let client: Redis | null = null;

export async function getCache(): Promise<Redis | null> {
  if (client) return client;
  try {
    const { auth_token } = config.redisSecretArn
      ? await getSecret<{ auth_token: string }>(config.redisSecretArn) : { auth_token: undefined };
    client = new Redis({
      host: config.redisEndpoint, port: 6379,
      password: auth_token, tls: auth_token ? {} : undefined,   // in-transit encryption
      lazyConnect: true, enableOfflineQueue: false,
      maxRetriesPerRequest: 1, commandTimeout: 200,             // fail fast → fall back to DB
    });
    client.on('error', (e) => logger.warn('redis error', { error: e.message }));
    await client.connect();
  } catch { client = null; }
  return client;
}
```

## Cache-aside helper

```typescript
export async function cached<T>(key: string, ttl: number, load: () => Promise<T>): Promise<T> {
  const redis = await getCache();
  if (redis) { try { const hit = await redis.get(key); if (hit) { cacheHits.add(1); return JSON.parse(hit); } } catch {} }
  cacheMisses.add(1);
  const value = await load();                                            // DocumentDB
  if (redis) redis.set(key, JSON.stringify(value), 'EX', ttl).catch(() => {});  // best-effort
  return value;
}
```

## Key convention + TTLs — `{env}:{resource}:{id}` (snake_case)

| Key | TTL | Notes |
|---|---|---|
| `{env}:profile:default` | 3600s | CV rarely changes |
| `{env}:posts:list:{cursor}` | 60s | feed, short TTL |
| `{env}:article:{slug}` | 300s | long-form |

Never cache `subscribers`, `audits`, or any per-user authenticated mutation.

## Invalidation on writes

Admin mutations delete affected keys (don't wait for TTL). Prefer a **version/namespace bump** (`{env}:posts:v{n}:list:...`) over `KEYS *` scans in production:

```typescript
// posts_create / posts_update / posts_delete → bump the list namespace version
await redis?.incr(`${env}:posts:list:version`);
```

## Conventions
- Connection reused across warm invocations (singleton, `lazyConnect`) — never connect per request.
- Reached in-VPC over the cluster SG (port 6379, off the NAT path), like DocumentDB.
- AUTH token from Secrets Manager (`/backend/secrets-management`); endpoint from `REDIS_ENDPOINT` (IaC). Provisioned in `/infrastructure/elasticache`.
- Emits `cache_hits_total` / `cache_misses_total` — see `/backend/metrics`.

## Pros & cons
**Pros**
- Cuts latency and DB load; fail-open (cache down is not an outage); TTL + invalidation.
- In-VPC, low latency.
**Cons**
- A staleness window between writes and invalidation.
- Invalidation is per-write/manual; one more dependency.
