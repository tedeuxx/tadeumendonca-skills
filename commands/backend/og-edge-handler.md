Implement or update the og-edge Lambda@Edge handler. **It lives in `<project>-pwa/iac`** (`iac/lambda-src/og-edge/index.js`), not `apps/bff` — see "Where the code lives" below.

Context: $ARGUMENTS

The edge does a **3-way classification** at CloudFront Viewer Request — humans get the SPA, bots get server-built HTML. It covers **two bot functionalities**: OG previews for social scrapers, and dynamic rendering for SEO crawlers.

## Lambda@Edge constraints (mandatory)
- NO VPC / NO Hono / NO audit / NO DynamoDB — runs at the CloudFront PoP.
- NO `process.env` at runtime → **derive the API base from the request `Host` header**: `https://api.${host}`. This is the project's domain convention (api.<frontend-host>), so the SAME artifact works in staging and production with zero build-time injection. *Trade-off:* couples the function to that subdomain convention — if the API ever moves off `api.<frontend-host>`, switch to a CloudFront custom-header origin config. (Alternatives — hardcoding per build, or a custom header — both need per-env builds/config, so prefer the Host header.)
- Handler signature: `CloudFrontRequestEvent` (not APIGatewayProxyEventV2). Generated viewer-request responses are capped at **40 KB** (headers+body) — guard on `Buffer.byteLength` and fall back to passthrough if exceeded. *Trade-off:* the origin-request-rewrite alternative (point the request at the API GW origin, 1 MB cap, CloudFront-cacheable) is heavier infra — defer it until a rendered page approaches 40 KB.
- **Zero dependencies** — only Node built-ins (global `fetch`). Nothing to bundle: Terraform zips the single `index.js` directly. *Trade-off:* no TypeScript at the edge; keep the file small and plain CJS (`exports.handler`).
- Always **fall back to passthrough** (return the request unchanged) on any fetch error/timeout/oversize/unmapped path — the SPA shell is always a valid response. Use an `AbortController` with a short timeout (~1.5s) well under the 5s viewer-request ceiling.

## Classification: `iac/lambda-src/og-edge/index.js` (plain CJS, zero deps)

```javascript
'use strict';
const MAX_BODY = 40000;          // viewer-request generated-response ceiling (bytes)
const TIMEOUT_MS = 1500;         // well under the 5s viewer-request ceiling
const SOCIAL  = /facebookexternalhit|twitterbot|linkedinbot|whatsapp|telegrambot|slackbot|discordbot|pinterest|redditbot|skypeuripreview|embedly/i;
const CRAWLER = /googlebot|bingbot|duckduckbot|yandex|baiduspider|applebot|petalbot|google-inspectiontool/i;

const route = (uri) => (uri === '/' || uri === '/index.html' ? { type: 'profile', slug: 'me' } : null); // Phase 1: only the homepage
const hdr = (req, n) => req.headers[n]?.[0]?.value;

async function fetchText(url) {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), TIMEOUT_MS);
  try { const r = await fetch(url, { signal: ctrl.signal }); return r.ok ? await r.text() : null; }
  catch { return null; } finally { clearTimeout(t); }
}
const html = (body) => Buffer.byteLength(body, 'utf8') > MAX_BODY ? null : ({
  status: '200', statusDescription: 'OK',
  headers: {
    'content-type':  [{ key: 'Content-Type', value: 'text/html; charset=utf-8' }],
    'cache-control': [{ key: 'Cache-Control', value: 'public, max-age=300' }],
    'x-prerendered-by': [{ key: 'X-Prerendered-By', value: 'og-edge' }],
  }, body,
});

exports.handler = async (event) => {
  const req = event.Records[0].cf.request;
  const ua  = hdr(req, 'user-agent') ?? '';
  const kind = SOCIAL.test(ua) ? 'social' : CRAWLER.test(ua) ? 'crawler' : 'human';
  if (kind === 'human') return req;                        // 3) → S3 SPA (CSR), passthrough

  const t = route(req.uri); const host = hdr(req, 'host');
  if (!t || !host) return req;
  const api = `https://api.${host}`;                       // Host-derived base, no env vars

  if (kind === 'social') {                                 // 1) social scrapers → OG-only <head>
    const j = await fetchText(`${api}/og-meta/${t.type}/${t.slug}`);
    let meta; try { meta = JSON.parse(j); } catch { return req; }
    return html(buildOgHead(meta)) || req;
  }
  const page = await fetchText(`${api}/prerender/${t.type}/${t.slug}`); // 2) crawlers → full HTML
  return page ? (html(page) || req) : req;
};
```

## The two functionalities

| | Social (web scraping) | SEO (search crawlers) |
|---|---|---|
| UA | facebook/linkedin/whatsapp/x… | googlebot/bingbot/… |
| Calls | `GET /og-meta/{type}/{slug}` | `GET /prerender/{type}/{slug}` |
| Returns | `<head>` only: OG/Twitter tags | full HTML: head + **content body** + JSON-LD |
| Goal | rich share card | indexable page (no SSR) |

Both come from the API (DynamoDB) — see `/backend/prerender`. The React app and the human path are unchanged (CSR). Not cloaking: crawler and user resolve to the same content.

## Where the code lives + deploy (IaC owns it — Pattern-B exception)

Unlike the BFF (`apps/bff` ships code, IaC owns config), the **edge code lives in `<project>-pwa/iac`** and Terraform owns its full lifecycle. *Why:* CloudFront must reference a **specific published version** (a qualified ARN — `$LATEST` is rejected), so every code change must publish a new version **and** repoint the distribution. Terraform does both in one apply:

```hcl
module "fn_og_edge" {
  source    = "terraform-aws-modules/lambda/aws"
  version   = "~> 7.0"
  providers = { aws = aws.us_east_1 }            # Lambda@Edge MUST be us-east-1
  function_name  = "${var.project}-og-edge-${var.environment}"
  handler        = "index.handler"
  runtime        = "nodejs22.x"
  architectures  = ["x86_64"]                    # Lambda@Edge does NOT support arm64
  timeout = 5; memory_size = 128                 # viewer-request ceilings
  lambda_at_edge = true                          # dual-trust + publish a version (qualified ARN)
  create_package = true                          # IaC owns the code: source hash → new version
  source_path    = "${path.module}/lambda-src/og-edge"   # single zero-dep index.js, no build step
  # no VPC, no environment_variables
}
# qualified_arn flows straight into the CloudFront viewer-request association (/infrastructure/cloudfront);
# code change → new hash → new version → new qualified_arn → distribution updated, all in one apply.
resource "aws_ssm_parameter" "lambda_edge_og_qualified_arn" { value = module.fn_og_edge.lambda_function_qualified_arn /* … */ }
```

*Trade-off:* an edge code change is a `terraform apply` (not the `apps/bff` deploy pipeline). Acceptable — the edge is bot/SEO-only and changes rarely. The rejected alternative (`apps/bff` `update-function-code` + `publish-version`, then a separate CloudFront `update-distribution`) would fight the CloudFront module's state permanently, since Terraform reconciles the association back to the version it knows. With `create_package=true` + `source_path` there's **no esbuild** — the zero-dep file is zipped as-is (Terraform's lambda module needs Python 3 on the runner to package).

After apply, CloudFront propagation + Lambda@Edge replication take several minutes; verify with `curl -A Googlebot` once the distribution is `Deployed` (look for `x-prerendered-by: og-edge`).

## Decision & trade-off
*(The sections above carry the per-mechanism trade-offs — Host-derived base, 40 KB cap, zero-deps, IaC-owned code. This summarizes the architectural call.)*
- **Classify the viewer at the edge and do the MINIMUM for humans.** A viewer-request Lambda@Edge does a 3-way User-Agent split: **humans pass straight through** to the SPA (CSR, untouched), **social scrapers** get a lightweight OG `<head>`, **search crawlers** get full prerendered HTML + JSON-LD. *Why at the edge:* serve bots server-rendered content **without paying for SSR on human traffic**. *Cost trade-off:* L@E runs on **every** viewer request and is pricier than regular Lambda, so the human path is a bare pass-through and real work happens only for bot UAs — the routing heuristic is the cost lever.
- **Not cloaking — bot and human resolve to the same content** (the edge fetches the same data the SPA renders, via the BFF bot API — `/backend/prerender`). *Trade-off:* a second render path that must stay in sync with the SPA.
- **The edge code is IaC-owned (the Pattern-B exception)** — CloudFront must reference a specific published version, so Terraform publishes the version AND repoints the distribution in one apply, rather than the `apps/bff` deploy pipeline. *Trade-off:* an edge change is a `terraform apply` with slow CloudFront/replication propagation — acceptable because it's bot/SEO-only and changes rarely.

## Pros & cons
**Pros**
- SEO/social crawling without SSR; runs at the edge (fast); 3-way UA routing.
- Human traffic passes straight through to the SPA.
**Cons**
- Lambda@Edge constraints: no VPC, us-east-1, slow deploys, size limits.
- UA classification is heuristic.
