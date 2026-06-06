Implement or review the bot-rendering API (og-meta + prerender) in tadeumendonca-api.

Context: $ARGUMENTS

Serves the HTML the Lambda@Edge returns to bots (see `/backend/og-edge-handler`). Two endpoints, same data source (DocumentDB), **no React on the server** — this is content templating, not SSR.

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
    canonical: `https://tadeumendonca.io/articles/${a.slug}`,
    ogImage: `https://tadeumendonca.io/og/articles/${a.slug}.png`,
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
