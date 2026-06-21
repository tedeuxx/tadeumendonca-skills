Frontend analytics (GA4) in `apps/fed` (concept).

Context: $ARGUMENTS

Conceptual skill — the analytics contract. The gtag snippet lives in `/frontend/framework-react`.

Product analytics via **Google Analytics (GA4)** — page views + events. SPA-aware: send a **page_view on every route change** (SPAs don't reload). Complements RUM (`/frontend/cloudwatch-rum`), which is performance/errors.

## Contract
- Load GA4 once with the measurement id (from SSM — `/frontend/environment-config`).
- `page_view` on each route change; custom `event`s for key actions (e.g. `article_open`, `subscribe`).
- **Production only** (or a separate property per env) so staging doesn't pollute data.

## Conventions
- **No PII** in events. Measurement id from SSM, never hardcoded. Respect Do-Not-Track / consent if added.

## Pros & cons
**Pros**
- Free, ubiquitous web analytics; SPA `page_view` per route + custom events.
- No backend work — client-side tag.
**Cons**
- Client-side, so ad-blockers/consent reduce data.
- Privacy/consent handling required; Google dependency.
