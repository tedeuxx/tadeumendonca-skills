Instrument the frontend with Google Analytics (GA4) in tadeumendonca-fed.

Context: $ARGUMENTS

## GA4 via gtag, SPA-aware

The SPA loads the GA4 tag and sends a **`page_view` on every route change** (react-router) — SPAs don't reload, so automatic page views miss client navigation. The measurement ID is build-time config from SSM.

## Setup
- `VITE_GA_MEASUREMENT_ID` (`G-XXXX`) — build-time env (`/frontend/environment-config`), sourced from SSM `/{env}/frontend/ga-measurement-id`.
- Load gtag once (small `src/lib/analytics.ts` that injects the script with the ID).

## Page views on navigation
```typescript
// src/lib/analytics.ts
export const pageview = (path: string) => window.gtag?.('event', 'page_view', { page_path: path });

export function usePageTracking() {           // mounted at the router root
  const location = useLocation();
  useEffect(() => pageview(location.pathname + location.search), [location]);
}
```

## Events
```typescript
export const track = (name: string, params?: Record<string, unknown>) => window.gtag?.('event', name, params);
// e.g. track('article_open', { slug }); track('subscribe');
```

## Conventions
- **Production only by default** (or a separate GA property per env) — gate on `env.environment === 'production'` so staging doesn't pollute prod analytics.
- **No PII** in events (never email/user_id); respect Do-Not-Track / a consent banner if added later.
- Measurement ID from **SSM**, never hardcoded (`/infrastructure/ssm-config-bus`, `/frontend/environment-config`).
- GA is third-party — allow it in any CSP; it doesn't touch the edge SEO path (`/frontend/seo`).
