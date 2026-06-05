Implement or review SEO in tadeumendonca-fed (client-side, no SSR).

Context: $ARGUMENTS

Two layers: per-route meta via **react-helmet-async** (so Google's JS rendering + browser tabs are correct) and build-time **`sitemap.xml`/`robots.txt`**. The heavy lifting for crawlers is done at the edge (**dynamic rendering** — see `/backend/og-edge-handler` and `/backend/prerender`); this is the client-side baseline + fallback. The app stays CSR — **no SSR**.

## Per-route meta: react-helmet-async

```tsx
// main.tsx
import { HelmetProvider } from 'react-helmet-async';
root.render(<HelmetProvider><App /></HelmetProvider>);

// components/seo/Seo.tsx — reused per page
export function Seo({ title, description, canonical, ogImage, jsonLd }: SeoProps) {
  return (
    <Helmet>
      <title>{title}</title>
      <meta name="description" content={description} />
      <link rel="canonical" href={canonical} />
      <meta property="og:title" content={title} />
      <meta property="og:description" content={description} />
      {ogImage && <meta property="og:image" content={ogImage} />}
      <meta name="twitter:card" content="summary_large_image" />
      {jsonLd && <script type="application/ld+json">{JSON.stringify(jsonLd)}</script>}
    </Helmet>
  );
}
```

Each page renders its own `<Seo>` (HomePage → `Person`, ArticlePage → `BlogPosting`).

## sitemap.xml + robots.txt
- `public/robots.txt` (static): allow all + sitemap pointer.
- `scripts/generate-sitemap.ts` (build step in `deploy.yml`, before `vite build`): fetch the articles list from the API + static routes (`/`, `/articles`, `/feed`) → write `public/sitemap.xml`.

```
User-agent: *
Allow: /
Sitemap: https://tadeumendonca.io/sitemap.xml
```

## Conventions
- Titles: `{Page} — Luiz Tadeu Mendonça`; descriptions ≤ 160 chars.
- JSON-LD: `Person` (home/CV), `BlogPosting`/`Article` (articles), `BreadcrumbList` where useful.
- Canonical always absolute, production domain.
- Keep client meta **consistent with the edge prerender** output (same title/description) — single source of truth where possible.
- Dep: `react-helmet-async`. No SSR framework (Next/Remix) — the architecture is CSR SPA + edge dynamic rendering (PLAN decision: dynamic rendering, not SSR).
