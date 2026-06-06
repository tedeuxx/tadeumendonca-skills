Frontend SEO in <project>-fed (concept, no SSR).

Context: $ARGUMENTS

Conceptual skill. The react-helmet-async snippet + sitemap script live in `/frontend/framework-react`.

Two layers: **per-route meta** (title, description, canonical, OG, JSON-LD) so Google's JS rendering + browser tabs are correct, and build-time **`sitemap.xml` / `robots.txt`**. The crawler heavy-lifting is at the edge (dynamic rendering — `/backend/og-edge-handler`, `/backend/prerender`); this is the client baseline. The app stays CSR — **no SSR**.

## Contract
- Each page declares its meta: `<title>`, description (≤160), canonical (absolute, prod domain), OG/Twitter, and **JSON-LD** (`Person` for CV, `BlogPosting` for articles).
- `robots.txt` (static) + a build step that generates `sitemap.xml` from the articles list (`/workflow/github-actions`).
- Keep client meta **consistent with the edge prerender** output (same title/description) — not cloaking.

## Conventions
- No SSR framework — the architecture is CSR + edge dynamic rendering. Canonical = production domain; one JSON-LD per page.
