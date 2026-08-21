---
name: frontend
description: Build the React + Vite SPA end to end — bootstrap and providers, routing, state ownership (React Query / Zustand / the Cognito SDK), the typed BFF client, auth and cosmetic UI gating, forms, cursor pagination, the custom Tailwind design system and Storybook, async UX states, markdown rendering, SEO, GA4 analytics, and Playwright E2E. Use when building or reviewing any SPA feature. Not for the AWS resources it calls (see cloud-infrastructure) or the API it calls (see backend).
---

# Frontend (React SPA)

The full frontend implementation guide for `<project>`'s React + Vite single-page app — one `##`
section per concern, merged from the former one-skill-per-concern layout into a single reference
(#231). **Framework react, immediately below, is the only section with actual React/library
snippets** — every other section is a framework-agnostic concept that section wires up; they point
back to it rather than repeat code.

Context: $ARGUMENTS

## Framework react

**Stack:** React 18 + TypeScript + Vite (CSR SPA, no SSR) · `react-router` · `@tanstack/react-query`
· `zustand` · Tailwind + own components (see Design system below) · `aws-amplify` (auth) ·
`react-markdown`.

**Structure**
```
src/
├── main.tsx          # providers bootstrap
├── router.tsx        # routes (react-router v6) + RequireAuth
├── env.ts             # typed import.meta.env (/backend)
├── lib/              # api.ts (BFF client), analytics.ts, rum.ts, seo.tsx
├── pages/  components/  hooks/  services/  store/  types/
```

**Bootstrap: main.tsx**
```tsx
import { Amplify } from 'aws-amplify';
import { HelmetProvider } from 'react-helmet-async';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
Amplify.configure({ Auth: { Cognito: {
  userPoolId: env.cognitoUserPoolId, userPoolClientId: env.cognitoClientId,
  loginWith: { oauth: { domain: env.cognitoHostedUi, scopes: ['openid','email','profile'],
    redirectSignIn: [`${location.origin}/callback`], responseType: 'code' } } } } });
const qc = new QueryClient();
root.render(<HelmetProvider><QueryClientProvider client={qc}><RouterProvider router={router} /></QueryClientProvider></HelmetProvider>);
```

**Auth (Cognito SDK)** — concepts in Authentication, Authorization below
```typescript
import { signInWithRedirect, signOut, fetchAuthSession } from 'aws-amplify/auth';
const jwt = (await fetchAuthSession()).tokens?.accessToken?.toString();              // SDK holds + refreshes
const groups = ((await fetchAuthSession()).tokens?.idToken?.payload?.['cognito:groups'] as string[]) ?? [];
```

**BFF client** — concept in API client below
```typescript
export async function apiFetch(path: string, init?: RequestInit) {
  const jwt = (await fetchAuthSession()).tokens?.accessToken?.toString();
  const res = await fetch(`${env.apiBaseUrl}${path}`, { ...init, headers: { ...init?.headers, Authorization: `Bearer ${jwt}` } });
  if (res.status === 401) { await signInWithRedirect(); throw new Error('unauthorized'); }
  if (!res.ok) throw await res.json();        // { error, message }
  return res.json();
}
```

**React Query** — queries / mutations / cursor — concept in Pagination below
```typescript
export const usePosts = () => useInfiniteQuery({ queryKey: ['posts'],
  queryFn: ({ pageParam }) => apiFetch(`/posts?cursor=${pageParam ?? ''}`),
  getNextPageParam: (last) => last.next_cursor });
export const useCreatePost = () => { const qc = useQueryClient();
  return useMutation({ mutationFn: (b) => apiFetch('/posts', { method: 'POST', body: JSON.stringify(b) }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['posts'] }) }); };
```

**SEO / Analytics / RUM** — concepts in SEO, Analytics below, and RUM in `/cloud-infrastructure`
```tsx
<Helmet><title>…</title><meta name="description" /* … */ /><script type="application/ld+json">{JSON.stringify(jsonLd)}</script></Helmet>
window.gtag?.('event', 'page_view', { page_path });                                  // GA4
new AwsRum(env.rumAppMonitorId, '1.0.0', env.region, { sessionSampleRate: 0.1, identityPoolId: env.rumIdentityPoolId, enableXRay: true });
```

**Routing + guards**
```tsx
// router.tsx — react-router v6; <RequireAuth> gates admin routes off cognito:groups (Authorization below)
```

**Testing (vitest + RTL)** — Unit/component tests run on **vitest** + React Testing Library
(`environment: 'jsdom'`); the coverage gate (≥ 85%) is the agnostic policy in `/quality-gates` (folded
in from the former standalone `coverage` skill at #257). Thresholds
in `vitest.config.ts`:
```ts
test: { environment: 'jsdom', coverage: { provider: 'v8', thresholds: { lines: 85, functions: 85, branches: 85, statements: 85 } } }
```
E2E is Playwright, not vitest (Playwright below). lcov feeds SonarCloud (`/devops`).

**Conventions**
- Only this section carries React/library code; every other section in this file stays agnostic.
- snake_case API payloads (no mapping layer); build-time config from SSM (`/backend`).
- Content-hashed assets (immutable); cache split + invalidation in `/devops`. UI primitives
  from Design system below; components developed in Storybook below.

**Pros & cons**
Pros: the one place with React/library code; fast Vite DX; the React ecosystem.
Cons: CSR-only — SEO relies on the edge prerender path (`/backend`); the intentionally
framework-coupled section.

## Routing

Conceptual — the routing structure + conventions; the react-router snippet lives in Framework
react above.

**Route map:** `/` HomePage (CV) · `/feed` · `/articles` (list + tag filter) · `/articles/:slug`
(ArticlePage) · `/callback` (auth code exchange — Authentication below) · admin routes (compose)
behind a guard · `*` 404.

**Patterns**
- **Nested layouts** — a shared app shell (header/nav/content — Design system below) wraps the page routes.
- **Lazy loading** — code-split heavy/rarely-hit routes (article editor, admin) to keep the initial bundle small.
- **Guards** — admin routes wrapped by `RequireAuth` (Authorization below); `/callback` and public GETs are open.
- **404** — a catch-all route renders NotFound.
- **Scroll restoration** — reset scroll on navigation; restore on back.

**Conventions**
- Routes are SEO surface — keep public routes crawlable and in the sitemap (SEO below).
- Page-view tracking fires on route change (Analytics below).
- Route params are the API's **opaque** ids — `:slug` (articles) or a hashid/nanoid `:public_id`
  (other resources); **never** an enumerable/sequential id. Mirrors the backend (`/backend`).

**Pros & cons**
Pros: nested layouts, lazy-loaded routes, and guards; public routes stay crawlable.
Cons: client routing needs the SPA fallback (CloudFront 403/404→index.html); guards are cosmetic —
the server enforces real access.

## State

Conceptual — what state goes where. Library snippets live in Framework react above.

**Three kinds of state, three owners**
- **Server state → React Query** (API client, Pagination below): anything from the BFF —
  cached, keyed, refetched, invalidated on mutation. The cache *is* the source of truth for remote data.
- **Client / UI state → Zustand** (or local component state): ephemeral UI (modals, filters, form
  drafts, theme). Small, non-authoritative.
- **Auth/session → the Cognito SDK** (Authentication below), read via `fetchAuthSession` — never a store.

**Conventions**
- **Never mirror server data into Zustand** — it goes stale; derive from React Query.
- Keep stores small and per-domain; persist only non-sensitive UI prefs.
- Prefer **URL / search params** for shareable UI state (active tag, tab) over a store.

**Pros & cons**
Pros: clear ownership: server→React Query, UI→Zustand, session→SDK; no server data mirrored into stores.
Cons: a model to follow consistently; multiple state tools to learn.

## API client

Conceptual — how the SPA talks to the BFF. The fetch / React-Query snippet lives in Framework
react above.

The SPA calls **one backend — the BFF** (`/backend`) at the base URL from SSM. Every call carries
the Cognito access token; responses are **screen-shaped** (the BFF aggregates). Data access goes
through a typed client + a server-state cache, never raw `fetch` in components.

**Contract**
- **Base URL** from `env.apiBaseUrl` (SSM — `/backend`).
- **Auth:** attach `Authorization: Bearer <access_token>` (Authentication below); on `401` → re-auth.
- **Errors:** the BFF returns `{ error, message }` (snake_case) with the right status — surface them uniformly.
- **Reads** = cached queries (keyed by resource + params); **writes** = mutations that **invalidate** the affected queries.
- **Pagination** via the cursor contract (Pagination below).

**Conventions**
- One typed API-client module; components/hooks use it — never call `fetch` directly.
- snake_case payloads (matches the BFF — no mapping layer).
- Sane timeouts; **don't retry 4xx**. Loading/error/empty states from Design system below.

**Pros & cons**
Pros: React Query gives caching, dedup, refetch, invalidation for free; Bearer auto-attached; 401
handling centralized in one client.
Cons: React Query cache model is a learning curve; another abstraction over `fetch`.

## Authentication

Conceptual — the auth contract. React/Amplify snippets live in Framework react above.

Authentication is **external to the BFF**: the SPA uses the **Cognito IdP SDK** to log in and
**hold/refresh the JWT**, then sends `Authorization: Bearer <access_token>` on every API call. The
**API GW Cognito authorizer** validates it (`/cloud-infrastructure`); the BFF reads claims, no auth
code (`/backend`). The Cognito service itself is `/cloud-infrastructure`.

**Contract**
- **Login is social-only via Google** (`/cloud-infrastructure`): `signInWithRedirect({ provider:
  'Google' })` goes straight to Google (the hosted UI's only action is "Continue with Google").
  Still **Authorization Code + PKCE**; the callback completes the exchange; the SDK stores +
  refreshes tokens. **No email/password form** — no native users.
- **MFA is the IdP's** (Google 2FA) — Cognito applies no second factor to federated users. Groups
  (`admin`/`registered`) are assigned server-side by a Cognito trigger and arrive in
  `cognito:groups`; the SPA only **reads** them for cosmetic gating (Authorization below).
- Every BFF call carries the access token as a Bearer header (API client above).
- `401` → re-authenticate.
- Config (pool/client/hosted-UI ids) from **SSM** at build time (`/backend`).

**Session lifecycle (OIDC + PKCE)**
- **Tokens:** `id_token` (identity/claims for UI), `access_token` (sent as Bearer to the BFF),
  `refresh_token` (renews the other two).
- **Storage + persistence:** the SDK stores the tokens (default `localStorage`) → the session
  survives reloads and is shared across tabs. *Trade-off:* tokens in browser storage are an XSS
  surface — the accepted cost of simplicity vs. a server-side-session BFF (rejected).
- **Silent refresh:** the SDK uses the `refresh_token` to renew the `access_token` before expiry,
  transparently — the app only calls `fetchAuthSession()`.
- **Expiry:** when the `refresh_token` expires or is revoked, `fetchAuthSession` fails → re-authenticate.
- **Logout:** clearing the session removes the local tokens and redirects to the Cognito logout
  (global sign-out invalidates the refresh token).

**Conventions**
- The **SDK owns tokens + the session** — never hand-roll PKCE/token exchange, refresh, or token storage.
- Role-based UI gating is Authorization below.

**Pros & cons**
Pros: the Cognito SDK owns PKCE, refresh, and token storage — no hand-rolled auth; session survives
reloads; Bearer token sent on every call, the GW authorizer validates.
Cons: tokens in browser storage are an XSS surface (the accepted cost vs a server-session BFF); tied
to Cognito/Amplify.

## Authorization

Conceptual. React snippets live in Framework react above.

Client-side authorization is **UX only** — it decides what to *render*, not what's *allowed*. Real
enforcement is server-side: the **API GW authorizer** + action-type RBAC (`/backend`). The SPA reads
the user's **groups/claims** from the authenticated session (Authentication above) to show/hide UI
and guard routes.

**Contract**
- Read `cognito:groups` from the session → derive role (e.g. `admin`).
- Guard admin routes (redirect non-admins); conditionally render admin UI.
- For finer control, consume the **allowed actions** the BFF can expose (a `/me` route) for feature
  toggles (`/backend`).

**Conventions**
- **Client gating is cosmetic** — never the security boundary; every protected call is re-checked
  server-side.
- No secrets/PII in client logic; a hidden button is not protection.

**Pros & cons**
Pros: hides UI a user cannot use; reads JWT claims, no extra calls.
Cons: cosmetic only — real authorization is server-side and must never trust the SPA; claims can be
stale until token refresh.

## Forms

Forms for admin flows (PostCompose, article editor — Phase 2/3). Concept + conventions; the React
form-library snippet lives in Framework react above.

**Pattern**
- **Controlled inputs** with a form library (e.g. react-hook-form) + a **zod** schema for
  validation — mirror the **same shape the BFF validates** (`/backend`), so client and server agree.
- **Submit → mutation** (API client above): on success, invalidate the affected queries +
  navigate; on error, surface the BFF `{ error, message }` inline.
- Disable submit while pending; optimistic updates only where safe to roll back.

**Conventions**
- Validate client-side for UX, but the **server is authoritative** (the BFF re-validates).
- snake_case field names (match the API). Build form UI from Design system below (own Tailwind
  `Field` wrapper + styled `input`/`textarea`/`select`).
- Admin forms live behind Authorization above.

**Pros & cons**
Pros: client validation mirrors the BFF zod contract; type-safe; immediate UX feedback.
Cons: the schema is duplicated client/server and must be kept in sync; controlled-input boilerplate.

## Pagination

Conceptual — the pagination contract + infinite-scroll UX. The React Query snippet lives in ##
Framework react above; the server-side cursor query in `/cloud-infrastructure`.

**Contract**
- **Request:** `?cursor=<opaque>&limit=N` (omit `cursor` for the first page).
- **Response:** `{ items: [...], next_cursor: string | null }` (snake_case) — `next_cursor = null` means end.
- **Cursor, not offset** — an opaque token (base64 of DynamoDB's `LastEvaluatedKey`); stays
  index-efficient and survives re-ordering (`/cloud-infrastructure`).

**UX (infinite scroll)**
- Fetch the next page when a **sentinel** near the list end enters the viewport
  (IntersectionObserver); append items.
- Cache + dedupe pages client-side; show a loading sentinel; the same contract serves posts, articles, etc.

**Conventions**
- The frontend never computes offsets — it only echoes back `next_cursor`.

**Pros & cons**
Pros: stable cursor pagination (no offset drift); infinite-scroll UX; matches the BFF contract.
Cons: no random page access (cursor, not page numbers); couples the UI to the cursor contract.

## Design system

The framework-level design-system decision: **own Tailwind components, no third-party component
library** (no shadcn/ui, no Cloudscape). It pairs with the Framework react section above (the impl home)
and the Storybook section below (where components are documented). **Project-specific identity** — the
actual palette, typography, radius and theme tokens — lives in the app (its `CLAUDE.md` + `src/styles`), NOT here.

**The stack**
- **Tailwind CSS** (v3, preflight on) — utility-first; no UI component library.
- **shadcn-style HSL design tokens** in a single `:root` (e.g. `--background`, `--foreground`,
  `--primary`, `--muted`, `--border`, `--ring`, `--radius`) mirrored in `tailwind.config` so
  utilities (`bg-background`, `text-foreground`) map to the tokens. One source of truth; theming =
  changing the token values.
- **`cn()`** class-merge util (`clsx` + `tailwind-merge`) for conditional/variant classes — **no
  `cva`** (keep variants as plain conditionals; reach for `cva` only if a component's variant matrix
  truly justifies it).
- Components are **hand-built primitives** in `src/components/`, documented in Storybook below.

**Which pattern per UI need (build, don't import)**
- **Page shell / layout** — a fixed app shell (header + nav + content region) composed with
  flex/grid utilities, not an off-the-shelf `AppLayout`.
- **Card / list item** — one bordered, rounded container primitive reused for feed items, articles,
  list entries.
- **Form controls** — styled `input`/`textarea`/`select` + a small `Field` wrapper (label + error);
  validation lives in the form layer (Forms above).
- **Buttons** — a single `Button` primitive with variants expressed via `cn()` conditionals (primary
  / ghost / icon).
- **Nav** — header links + a horizontal/secondary nav; active state from the router's `NavLink`.
- **UX states** — explicit loading / empty / error primitives (UX states below), not a library
  spinner/status widget.
- **Tables** — a plain semantic `table` styled with utilities; add virtualization only when the
  dataset demands it.
- **Badges / tags** — a small rounded, token-colored `Badge` primitive.

**Theming**
- **Single fixed theme by default** (no light/dark toggle) unless the product needs one — fewer
  tokens, one `:root`, no `ThemeProvider`. A theme switch is a deliberate add (a second token set +
  a provider), not the baseline.
- **Brand identity is project-specific** — palette, fonts, radius scale and density live in the
  app's `src/styles` and are documented in the app's `CLAUDE.md`. This section stays identity-agnostic.

**Rationale — why own components over a library**
- **Full design control + a bespoke identity** — the look is part of the product's argument, not an
  off-the-shelf framework's flavor.
- **Lean bundle** — ship only the utilities/components actually used; no large component-library payload.
- **Accessibility is on you** — the cost of no library: you must build keyboard/focus/ARIA correctly.
  For the few genuinely complex widgets (menus, dialogs, comboboxes) reach for a **headless**
  primitive library rather than adopting a full design system.

**Pros & cons**
Pros: bespoke identity, minimal bundle, no library lock-in, tokens as the single theming source.
Cons: more to build and own (a11y, variants); slower initial velocity than grabbing a component
library off the shelf.

## Storybook

Component-driven development + living documentation for the SPA's component library — develop,
document, and test components in isolation. React/config snippets belong with Framework react
above; this is the practice.

**Setup**
- Storybook with the **Vite** builder; `*.stories.tsx` colocated with each component.
- Decorate stories with the app providers a component needs (the design-system tokens/theme — ##
  Design system above, React Query, router) so they render like the real app.

**What we story**
- Reusable UI (Card, Badge, Timeline, layout, feedback states) and composite sections (CV sections,
  PostCard, ArticleHeader).
- Each story = a **state**: default / loading / empty / error / admin-vs-public.

**Testing + docs**
- **Interaction tests** (`play` functions) for behavior; **visual regression** (Chromatic or
  snapshots).
- **Autodocs** from stories + prop types = the component reference.
- **a11y** addon for accessibility checks. Runs in CI (`/devops`).

**Conventions**
- Develop components in Storybook first (isolation), then compose into pages.
- Stories are committed and kept in sync with the component — a stale story is a smell.
- The design system provides our own primitives (Design system above); Storybook documents how we
  compose them.

**Pros & cons**
Pros: isolated component development + autodocs + interaction/visual tests; a living catalog.
Cons: stories to write and maintain; extra build/config overhead.

## UX states

Conceptual — consistent async UX + error boundaries. Components/snippets live in Framework react
and Design system above.

**Every async view handles four states**
- **Loading** → spinner/skeleton (own primitive).
- **Empty** → a clear empty state, never a blank screen.
- **Error** → `Alert` with the BFF `{ error, message }` + a retry (API client above).
- **Success** → the content.
React Query exposes `isLoading` / `isError` / `data` — branch on them uniformly.

**Error boundaries**
- A React **ErrorBoundary** around route subtrees catches render-time errors → fallback UI (don't
  white-screen); report to RUM (`/cloud-infrastructure`).
- Network/HTTP errors are handled at the query/mutation layer, not in boundaries.

**Conventions**
- One shared set of loading/empty/error components reused everywhere — develop in Storybook above.
- Never leave a pending action without feedback; disable buttons while mutating.
- `401` is special: re-auth, don't show a generic error (Authentication above).

**Pros & cons**
Pros: consistent async UX; error boundaries prevent white-screens; one reused set of
loading/empty/error components.
Cons: every async view must handle four states (discipline); boundary fallbacks need designing.

## Markdown

Articles are stored as markdown (`body_markdown`) and rendered to HTML in the SPA (Phase 3). Concept
+ conventions; the react-markdown snippet lives in Framework react above.

**Pattern**
- Render markdown → HTML with a markdown renderer + **syntax highlighting** for code blocks (e.g.
  react-markdown + rehype-highlight).
- **Sanitize** untrusted HTML; restrict allowed elements (no raw `<script>`).
- Map headings/typography to the design system (Design system above).

**Conventions**
- Keep the rendered HTML **consistent with the edge prerender** the bots get (`/backend`) — same
  content, good SEO, not cloaking.
- Lazy-load the highlighter + theme to keep the initial bundle small.
- Articles fetched via API client above; long-form pages are prime SEO targets (SEO below).

**Pros & cons**
Pros: safe (sanitized) article rendering with syntax highlight; consistent with the edge prerender output.
Cons: sanitization must stay strict to avoid XSS; render parity with the prerender path to maintain.

## SEO

Conceptual, no SSR. The react-helmet-async snippet + sitemap script live in Framework react above.

Two layers: **per-route meta** (title, description, canonical, OG, JSON-LD) so Google's JS rendering
+ browser tabs are correct, and build-time **`sitemap.xml` / `robots.txt`**. The crawler
heavy-lifting is at the edge (dynamic rendering — `/backend`); this is the client baseline. The app
stays CSR — **no SSR**.

**Contract**
- Each page declares its meta: `<title>`, description (≤160), canonical (absolute, prod domain),
  OG/Twitter, and **JSON-LD** (`Person` for CV, `BlogPosting` for articles).
- `robots.txt` (static) + a build step that generates `sitemap.xml` from the articles list (`/devops`).
- Keep client meta **consistent with the edge prerender** output (same title/description) — not cloaking.

**Conventions**
- No SSR framework — the architecture is CSR + edge dynamic rendering. Canonical = production
  domain; one JSON-LD per page.

**Pros & cons**
Pros: per-route meta + JSON-LD structured data without SSR; pairs with the edge prerender for bots.
Cons: CSR meta is not seen by every crawler (the reason edge prerender exists); two SEO paths to keep aligned.

## Analytics

Conceptual — the analytics contract. The gtag snippet lives in Framework react above.

Product analytics via **Google Analytics (GA4)** — page views + events. SPA-aware: send a
**page_view on every route change** (SPAs don't reload). Complements RUM (`/cloud-infrastructure`),
which is performance/errors.

**Contract**
- Load GA4 once with the measurement id (from SSM — `/backend`).
- `page_view` on each route change; custom `event`s for key actions (e.g. `article_open`, `subscribe`).
- **Production only** (or a separate property per env) so staging doesn't pollute data.

**Conventions**
- **No PII** in events. Measurement id from SSM, never hardcoded. Respect Do-Not-Track / consent if added.

**Pros & cons**
Pros: free, ubiquitous web analytics; SPA `page_view` per route + custom events; no backend work — client-side tag.
Cons: client-side, so ad-blockers/consent reduce data; privacy/consent handling required; Google dependency.

## Playwright

End-to-end tests that drive the real **static SPA** in a browser — the functional proof that
nothing already working broke. Under `trunk-single-env` E2E runs on the **PR gate** (it blocks the
merge, and the merge is the deploy), and the same specs can run as a **post-deploy smoke** against
the live apex. Part of the quality gate (`/quality-gates`).

**Setup (single environment, one command targets local or the apex)**
- `playwright.config.ts`: `baseURL` from `PLAYWRIGHT_BASE_URL`, or from `E2E_ENV` mapped to a URL —
  `local` (a `vite preview` of the built app at `:4173`) or the **single environment served at the
  apex** (`https://<apex-domain>`). `trace: 'on-first-retry'`, `retries` in CI, chromium project. The
  **same specs run anywhere** — only the base URL changes.
- `package.json` scripts: `e2e:local` (against `vite preview`) is the **pre-merge gate**; the
  apex-targeted run is the **deploy smoke**. (There is one environment; any `staging`/`production`
  script names are aliases for the same apex — a leftover, not a second tier.)
- Tests under `e2e/*.spec.ts`; browsers via `npx playwright install --with-deps`.

**STANDARD — every user-facing feature ships its E2E.** A new user-facing feature MUST add/update
its Playwright spec in the same PR (the critical journey it introduces). This is the
100%-of-user-visible-features regression invariant. Keep specs at **journey level** — don't re-test
unit logic (that's the co-located Vitest/RTL suite).

**No auth — the surface is static.** The site has **no backend, no auth, no Cognito**: every journey
is a public, unauthenticated page load. There is no login to automate, no token to seed, no session
to stub. If an old spec or note references Cognito/Google login or a `storageState` token, that's the
retired backend era — delete it, don't port it.

**What we cover (the static journeys)** — the specs assert the real content surface — landing / CV /
portfolio / blog / routing:
- **Landing** (`/`) is the content shop window (Artigos + Portfólio), **not** the CV — the personal
  name lives on `/cv` only.
- **CV** (`/cv`) renders the profile (name, sections, contact links incl. the WhatsApp click-to-message link).
- **Portfolio** (`/portfolio`) serves the full catalog with its GitHub links, reachable from the landing shortlist.
- **Content detail** — an article opens by slug, renders its markdown, and offers a share control.
- **Routing resilience** — retired list routes (`/blog`, `/articles`) redirect to the landing; a
  legacy `/articles/:slug` permalink still renders; an unknown path goes back to the landing, not a dead end.

**Patterns**
- **Locators by role/text** (`getByRole`, `getByText`) — avoid brittle CSS selectors.
- **Web-first assertions** (`await expect(locator).toBeVisible()`) — no arbitrary `waitForTimeout`.
- Run against a local `vite preview` (the PR gate) or the apex (the smoke) — no external service to isolate.

**CI**
- Runs in **`build-test.yml`** (`/devops`) on the PR, via the config's `webServer` booting a
  `vite preview` of the built app. **Any failure blocks the merge** — and the merge is the deploy, so
  a red E2E stops the release. Upload the HTML report/trace on failure.

**Pros & cons**
Pros: real-browser coverage of critical journeys, catches integration regressions a unit test
cannot; on a static site with no auth, the specs are simple and stable — pure public page loads.
Cons: slower and flakier than unit tests; selectors/specs to maintain.
