Implement or update the OG image generator — a module of the BFF (`tadeumendonca-api/src/modules/og-image/`).

Context: $ARGUMENTS

## Pattern: generate PNG on-demand, cache in S3

**route** (`routes.ts`) — public BFF route `GET /og/{type}/{slug}.png` (no authorizer)
1. Check S3 cache: `og-images/{type}/{slug}.png`
2. If cache hit → return presigned URL redirect (302)
3. If miss → call `generator.ts` → upload to S3 → return PNG

**`generator.ts`** — satori + resvg:
```typescript
import satori from 'satori';
import { Resvg } from '@resvg/resvg-js';

export async function generateOgImage(title: string, type: string): Promise<Buffer> {
  const svg = await satori(
    // JSX-like element tree (React syntax via h() calls)
    { type: 'div', props: { style: { /* ... */ }, children: title } },
    { width: 1200, height: 630, fonts: [/* ... */] }
  );
  const resvg = new Resvg(svg);
  return resvg.render().asPng();
}
```

## Image URL convention
`https://{domain}/og/{type}/{slug}.png` — served via CloudFront `/og/*` behavior → og-images S3 bucket.
URL is deterministic: same type+slug always produces same URL (cache-friendly).

## S3 cache key
`{type}/{slug}.png` in the `og-images-{env}` bucket. Bucket is public-readable via CloudFront OAC.

## Env vars (set by IaC)
- `OG_IMAGES_BUCKET` — S3 bucket name
- `ENVIRONMENT` — staging | production
