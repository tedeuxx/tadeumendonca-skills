Define or review the frontend framework (React + Vite SPA) for tadeumendonca-fed.

Context: $ARGUMENTS

## Framework: React + TypeScript + Vite (CSR SPA, no SSR)

A client-rendered single-page app on S3 + CloudFront. SEO is handled at the edge (dynamic rendering) + client meta — see `/frontend/seo`. **No Next.js/Remix/SSR.**

## Stack
- **React 18 + TypeScript**, built with **Vite** (`vite build` → content-hashed assets in `dist/`).
- **Routing:** `react-router-dom` v6 (`router.tsx`).
- **Server state:** `@tanstack/react-query` — cursor pagination (`/frontend/react-query-cursor`).
- **Client state:** `zustand` (+ persist) — auth store (`/frontend/cognito-pkce`).
- **UI:** Cloudscape Design System (`/frontend/cloudscape-patterns`).
- **Markdown:** `react-markdown` + `rehype-highlight` (articles).

## Structure
```
src/
├── main.tsx          # createRoot + HelmetProvider + QueryClientProvider + RouterProvider
├── router.tsx        # routes (react-router v6)
├── env.ts            # typed import.meta.env wrapper (/frontend/environment-config)
├── pages/            # home, feed, articles, auth
├── components/       # layout, ui, seo, auth
├── hooks/            # useProfile, usePosts, useArticles
├── services/api.ts   # typed fetch wrapper (all endpoints)
├── store/authStore.ts
└── types/
```

## Bootstrap (main.tsx)
```tsx
createRoot(document.getElementById('root')!).render(
  <HelmetProvider>
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} />
    </QueryClientProvider>
  </HelmetProvider>
);
```

## Conventions
- Build-time config via `import.meta.env.VITE_*` through the typed `env.ts` — `/frontend/environment-config`.
- Data only through `services/api.ts` + React Query hooks; components never `fetch` directly.
- snake_case in API payloads (matches the backend — no mapping layer).
- Assets are content-hashed/immutable; cache split + invalidation handled by `/workflow/deploy-fed`.
