Frontend routing in `apps/fed` (concept).

Context: $ARGUMENTS

Conceptual skill — the routing structure + conventions. The react-router snippet lives in `/frontend/framework-react`.

## Route map
- `/` HomePage (CV) · `/feed` · `/articles` (list + tag filter) · `/articles/:slug` (ArticlePage) · `/callback` (auth code exchange — `/frontend/authentication`) · admin routes (compose) behind a guard · `*` 404.

## Patterns
- **Nested layouts** — a shared app shell (header/nav/content — see `/frontend/design-system`) wraps the page routes.
- **Lazy loading** — code-split heavy/rarely-hit routes (article editor, admin) to keep the initial bundle small.
- **Guards** — admin routes wrapped by `RequireAuth` (`/frontend/authorization`); `/callback` and public GETs are open.
- **404** — a catch-all route renders NotFound.
- **Scroll restoration** — reset scroll on navigation; restore on back.

## Conventions
- Routes are SEO surface — keep public routes crawlable and in the sitemap (`/frontend/seo`).
- Page-view tracking fires on route change (`/frontend/analytics`).
- Route params are the API's **opaque** ids — `:slug` (articles) or a hashid/nanoid `:public_id` (other resources); **never** an enumerable/sequential id. Mirrors the backend (`/backend/lambda-handler`).

## Pros & cons
**Pros**
- Nested layouts, lazy-loaded routes, and guards; public routes stay crawlable.
**Cons**
- Client routing needs the SPA fallback (CloudFront 403/404→index.html).
- Guards are cosmetic — the server enforces real access.
