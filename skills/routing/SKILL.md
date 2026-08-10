---
description: Lay out routes in a React SPA — nested layouts around a shared app shell, lazy-loaded heavy routes, auth guards, a catch-all 404 and scroll restoration, with opaque slug or public_id params rather than sequential ids. Use when adding a page, code-splitting to shrink the initial bundle, or keeping public routes crawlable. Not for what a route renders (see design-system).
family: frontend
---

Frontend routing (concept).

Context: $ARGUMENTS

Conceptual skill — the routing structure + conventions. The react-router snippet lives in `/framework-react`.

## Route map
- `/` HomePage (CV) · `/feed` · `/articles` (list + tag filter) · `/articles/:slug` (ArticlePage) · `/callback` (auth code exchange — `/authentication`) · admin routes (compose) behind a guard · `*` 404.

## Patterns
- **Nested layouts** — a shared app shell (header/nav/content — see `/design-system`) wraps the page routes.
- **Lazy loading** — code-split heavy/rarely-hit routes (article editor, admin) to keep the initial bundle small.
- **Guards** — admin routes wrapped by `RequireAuth` (`/authorization`); `/callback` and public GETs are open.
- **404** — a catch-all route renders NotFound.
- **Scroll restoration** — reset scroll on navigation; restore on back.

## Conventions
- Routes are SEO surface — keep public routes crawlable and in the sitemap (`/seo`).
- Page-view tracking fires on route change (`/analytics`).
- Route params are the API's **opaque** ids — `:slug` (articles) or a hashid/nanoid `:public_id` (other resources); **never** an enumerable/sequential id. Mirrors the backend (`/lambda-handler`).

## Pros & cons
**Pros**
- Nested layouts, lazy-loaded routes, and guards; public routes stay crawlable.
**Cons**
- Client routing needs the SPA fallback (CloudFront 403/404→index.html).
- Guards are cosmetic — the server enforces real access.
