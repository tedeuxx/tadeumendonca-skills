Define or review action types (audit + RBAC + feature toggles) in `apps/bff`.

Context: $ARGUMENTS

Conceptual skill — *what* action types are and the rules around them. Framework wiring (the Hono middleware that uses them) lives in `/backend/framework-hono`.

## What they're for

Action types are the stable identifier behind **three things**:
1. **Audit identification** — every user interaction is written to the `audits` collection classified by its `action_type`; that constant is **how we identify/query what the user did** afterward (`/backend/audit-middleware`).
2. **RBAC composition** — they're the **unit of authorization** (below).
3. **Feature toggling per profile** — each capability is a named action, so a profile's enabled set can be flipped to turn features on/off **per role, no deploy**.

One constant, used by all three — so audit, authz, and flags never drift.

## Mandatory rule
Every action is declared **statically** as a central constant and attached to its route — **never derived from the HTTP method/path at runtime**. It must be explicit and central.

## Central definition: `src/shared/constants/action-types.ts`
```typescript
// TypeScript const = SCREAMING_SNAKE_CASE; stored DB value = snake_case (audits.action_type)
export const ActionType = {
  PROFILE_GET:        'profile_get',
  POSTS_LIST:         'posts_list',
  POSTS_CREATE:       'posts_create',
  POSTS_UPDATE:       'posts_update',
  POSTS_DELETE:       'posts_delete',
  ARTICLES_LIST:      'articles_list',
  ARTICLES_GET:       'articles_get',
  SUBSCRIBERS_CREATE: 'subscribers_create',
  OG_IMAGE_GENERATE:  'og_image_generate',
} as const;
export type ActionType = (typeof ActionType)[keyof typeof ActionType];
```

## RBAC composition (when authorization is needed)
Authorization is expressed as a **map of role → allowed action types**. The route's declared action type is checked against the caller's role (groups), so the **same constant drives both audit and authz**. Conceptually:
- `admin` → all actions · `registered` → e.g. `subscribers_create` · `public` → the open reads (`profile_get`, `posts_list`, `articles_list`, `articles_get`).
- A request is authorized iff one of its groups grants the route's action type; otherwise `UnauthorizedError`.

Use it **only when needed** — a simple group check (the three Cognito profiles, `/infrastructure/cognito`) is often enough; promote to an action-type map when permissions get finer-grained. **Feature toggles:** make the map **config-driven** to flip a profile's allowed set at runtime (no deploy); expose the user's allowed actions (a `/me` route) so the SPA renders UI accordingly.

## Pros / cons
**Pros:** single source of truth for "what actions exist" — drives audit + RBAC + flags consistently; authorization decoupled from method/path; explicit, greppable, testable.
**Cons:** manual upkeep (every new action needs a constant + RBAC entry); coarse-grained (action-level, not row/attribute-level — "edit *own* post" needs an extra ownership check); overkill for tiny surfaces.

## Conventions
- Constant **name** SCREAMING_SNAKE_CASE; stored **value** snake_case — same value everywhere, no mapping.
- One action type per handler action; add the constant **before** wiring a route — never inline a string literal.
- `og-edge` writes no audit and declares no action type.
- The Hono middleware that attaches `audit(action)` / `authorize(action)` to routes is in `/backend/framework-hono`.

## Pros & cons
**Pros**
- Central source of truth for what actions exist; one list drives audit, RBAC, and feature toggles.
- Type-safe — handlers reference constants, not strings.
**Cons**
- Every new action must be registered (small ceremony).
- A shared enum couples modules to one list.
