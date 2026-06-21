Implement or review the bot-rendering API (og-meta + prerender) in `apps/bff`.

Context: $ARGUMENTS

Serves the HTML the Lambda@Edge returns to bots (see `/backend/og-edge-handler`). Two endpoints, same data source (DynamoDB), **no React on the server** — this is content templating, not SSR.

## Endpoints
- `GET /og-meta/{type}/{slug}` → JSON meta for **social** scrapers: `{ title, description, image_url, url }`. Lightweight, no body render.
- `GET /prerender/{type}/{slug}` → **full HTML** for **search crawlers**: `<head>` (title, description, canonical, OG, Twitter, JSON-LD) + `<body>` with the real content + a bootstrap `<script>` that loads the SPA for any human who lands on it.

`{type}` ∈ `profile` (home/CV), `posts`, `articles`.

## Shared render module: src/shared/render/

```typescript
import MarkdownIt from 'markdown-it';
const md = new MarkdownIt();

export function renderArticleHtml(a: Article): string {
  const body = md.render(a.body_markdown);                 // markdown → HTML, server-side
  return htmlDoc({
    title: a.title,
    description: a.excerpt,
    canonical: `https://<apex-domain>/articles/${a.slug}`,
    ogImage: `https://<apex-domain>/og/articles/${a.slug}.png`,
    jsonLd: blogPostingJsonLd(a),
    body: `<article><h1>${a.title}</h1>${body}</article>`,
  });
}
```

## JSON-LD (structured data)
- `profile` → `Person` (name, jobTitle, sameAs links).
- `articles` → `BlogPosting`/`Article` (headline, datePublished, author, keywords from tags).
- `posts` → minimal `Article`/`SocialMediaPosting`.

## Conventions
- These are **public root routes of the BFF** (no authorizer) — `/og-meta/*` and `/prerender/*` — reusing the domain repositories (`profile`/`posts`/`articles`). Markdown deps (`markdown-it`) isolated in `shared/render`.
- Content fields are snake_case (`body_markdown`, `published_at`, `image_url`).
- HTML must mirror what the SPA renders (same content) — not cloaking. Keep `og-meta` and `prerender` titles/descriptions identical to the client `/frontend/seo` output.
- Public routes (no JWT); cached at the edge (`max-age=300`). Hit/miss can feed `/backend/metrics`.
- The OG PNG itself comes from `/backend/og-image-generator`; prerender only references its URL.

## Decision & trade-off
- **The bot API mirrors what the SPA renders from the SAME data store — it is content templating, not SSR and not cloaking.** `og-meta` (JSON for social) + `prerender` (full HTML + JSON-LD for crawlers) read the domain repositories directly; no React on the server. *Trade-off:* a **second render path** that must stay in lockstep with the client SEO output (`/frontend/seo`) — keep titles/descriptions/JSON-LD identical or it drifts toward cloaking.
- **Public root routes, no authorizer, edge-cached (`max-age=300`)** — only bots hit them; humans get the SPA. *Trade-off:* anything served here is world-readable (it's for crawlers), so never include non-public fields.

### Inbound serving vs. outbound scraping — two different things
*This skill SERVES our own content to crawlers/scrapers. Resolving a **third-party** URL's preview (link unfurl) is the opposite direction — **outbound scraping** — and follows different rules:*
- **Fetching an external URL's Open Graph data is outbound scraping, distinct from serving our own pages.** The real gotcha: a **datacenter IP + a generic User-Agent** frequently gets a consent/interstitial page or a `403`, so the OG tags aren't there. **Sending a recognized crawler User-Agent** (e.g. a `facebookexternalhit`-style token, honestly suffixed with your own `+URL`) makes most sites serve their OG page from the same IP — exactly how chat apps build rich cards. *Trade-off / caveat:* respect `robots`/ToS and keep the UA honestly attributable; some providers (e.g. login-walled social) still degrade and need their paid official API — ship a clean fallback card and leave that seam.
- **All outbound fetches go through an SSRF-guarded, bounded fetcher** (allow only http/https, re-resolve + reject private/loopback/link-local/metadata IPs on **every** redirect hop, cap time + bytes). Server-side fetching of arbitrary URLs is a classic SSRF vector even when only an admin submits the URL. *Trade-off:* manual redirect handling + a DNS check per hop, for a closed egress surface.

## Pros & cons
**Pros**
- Crawlable HTML + JSON-LD for bots without SSR; reuses the DynamoDB data.
- Only bots hit it — humans get the SPA.
**Cons**
- A second rendering path to keep consistent with the SPA.
- Bot detection is heuristic.
