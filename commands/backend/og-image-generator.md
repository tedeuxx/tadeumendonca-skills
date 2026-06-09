Implement or update the OG image generator — a module of the BFF (`<project>-api/src/modules/og-image/`).

Context: $ARGUMENTS

## Pattern: generate PNG on-demand, cache in S3, serve via the CDN

**route** (`routes.ts`) — public BFF route `GET /og/{type}/{slug}.png` (no authorizer), cache-aside:
1. S3 key = **`og/{type}/{slug}.png`** — the FULL public path. CloudFront's `/og/*` behavior forwards the URI **verbatim** to the S3 origin (it does NOT strip the matched prefix), so the object must live under `og/…` or the CDN 404s. *(This bit everyone once: storing `{type}/{slug}.png` makes the API 302 fine but the CDN serve a 403→SPA fallback.)*
2. `objectExists(key)` via `HeadObject`. **Hit** → 302 to `${spaOrigin}/${key}`.
3. **Miss** → `getProfile()` → generate → `PutObject(key)` → 302 to `${spaOrigin}/${key}`.

The PNG bytes are **never** served through API Gateway — we 302 to the CloudFront `/og/*` behavior (→ S3), so the binary rides the CDN and the API stays JSON-only. `og:image` URLs point at **`config.apiOrigin`** (`https://api.<host>/og/…`) so the first scrape triggers generation; the 302 then hands the scraper the CDN URL.

```typescript
const key = `og/${type}/${slug}.png`;
if (!(await objectExists(key))) {
  const profile = await getProfile();
  if (!profile) throw new NotFoundError('profile not found');
  const { generateOgImage } = await import('./generator'); // lazy — see "bundling" below
  await putImage(key, await generateOgImage(profile));
}
return c.redirect(`${config.spaOrigin}/${key}`, 302);
```

**`generator.ts`** — satori (element tree → SVG) + **`@resvg/resvg-wasm`** (SVG → PNG):
```typescript
import satori from 'satori';
import { initWasm, Resvg } from '@resvg/resvg-wasm';
import resvgWasm from '@resvg/resvg-wasm/index_bg.wasm';        // → Uint8Array (esbuild binary loader)
import interRegular from '@fontsource/inter/files/inter-latin-400-normal.woff';
import interBold from '@fontsource/inter/files/inter-latin-700-normal.woff';

let wasmReady: Promise<void> | undefined;                       // initWasm throws if called twice — memoise
const ensureWasm = () => (wasmReady ??= initWasm(resvgWasm as unknown as ArrayBuffer));

export async function generateOgImage(profile: Profile): Promise<Uint8Array> {
  const svg = await satori(card(profile), {                     // card() = plain {type,props} tree, no JSX
    width: 1200, height: 630,                                   // OG standard size
    fonts: [{ name: 'Inter', data: interRegular as any, weight: 400, style: 'normal' },
            { name: 'Inter', data: interBold    as any, weight: 700, style: 'normal' }],
  });
  await ensureWasm();
  return new Resvg(svg, { fitTo: { mode: 'width', value: 1200 } }).render().asPng();
}
```
Build a plain element tree (no React/JSX): `{ type, props: { style, children } }`. Every node with >1 child MUST set `display:'flex'` — satori only lays out flexbox.

## WASM, not the native build (deliberate)
Use **`@resvg/resvg-wasm`**, not `@resvg/resvg-js`. The native package ships a per-platform `.node` binary that esbuild can't bundle and that needs per-arch optional-dep juggling on CI. The WASM build + the Inter `.woff` fonts embed into one self-contained bundle via esbuild's **binary loader** — no runtime file reads, no native binary. *Trade-off:* WASM renders a touch slower — irrelevant, images are cached in S3 and regenerated rarely. Bundle ≈ 5 MB (≈1.7 MB zipped), well within Lambda limits.

```js
// esbuild.config.mjs
loader: { '.wasm': 'binary', '.woff': 'binary' },
```

## Bundling + testing gotchas (both real, both fixed the same way)
- **Lazy-import the generator** from the route (`await import('./generator')`). Its top-level `.wasm`/`.woff` imports are fine under esbuild (embedded, inlined into the single bundle), but **break any tool that loads the app without that loader** — `tsx scripts/build-openapi-aws.ts` (the deploy's contract step) and vitest both throw `ERR_UNKNOWN_FILE_EXTENSION`. Keeping the generator behind a dynamic import means only a live `/og` request resolves the binaries.
- **Exclude `generator.ts` from coverage** (vitest + sonar) — its binary imports can't load under vitest. Validate it with a build smoke test (bundle a temp entry with the real loaders, render a PNG, assert the signature) + the live deploy. A small vitest `resolveId/load` plugin can stub `.wasm`/`.woff` so the rest of the suite still imports the app; mock the generator in the route test.

## IAM (set by IaC — /infrastructure/iam, /infrastructure/lambda)
The BFF exec role needs, on the og-images bucket:
- `s3:GetObject` + `s3:PutObject` on `…/*` (read/write the cached PNG).
- **`s3:ListBucket` on the bucket ARN** — without it, `HeadObject` on a MISSING key returns **403** (S3 hides existence), not 404, so the cache-aside 500s on the very first request instead of generating. This is the #1 og-image footgun.

## Env vars (set by IaC)
- `OG_IMAGES_BUCKET` — S3 bucket name. `ENVIRONMENT` — staging | production (drives `spaOrigin`/`apiOrigin`).

## Image URL convention
`https://api.<host>/og/{type}/{slug}.png` (the BFF route) → 302 → `https://<host>/og/{type}/{slug}.png` (CloudFront `/og/*` → S3). Deterministic: same type+slug → same URL (cache-friendly). Regenerate = overwrite the key + CloudFront invalidation.

## Pros & cons
**Pros**
- Dynamic OG images from code, cached in S3, served from the same CloudFront distribution; no headless browser; binaries never touch API GW.
**Cons**
- satori/resvg-wasm bundle size + memory (watch the Lambda memory; 256 MB is the floor for 1200×630 — bump if it OOMs).
- Font/layout fidelity is limited vs a real browser; satori is flexbox-only with a fixed font set.
