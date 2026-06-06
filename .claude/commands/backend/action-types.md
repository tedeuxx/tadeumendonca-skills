Define or review action types (audit + RBAC) in tadeumendonca-api.

Context: $ARGUMENTS

## What they're for

Action types are the stable identifier behind **two things**:
1. **Audit identification** — every user interaction with the app is written to the `audits` collection classified by its `action_type`. That constant is **how we identify, query, and filter what the user did** afterward (per-user activity, forensics, usage metrics) — see `/backend/audit-middleware`.
2. **RBAC composition** — they're the unit of authorization (below).
3. **Feature toggling per profile** — each capability is a named action, so a profile's enabled action-type set can be flipped via config/flags to turn features on/off **per role, with no code change** (and the frontend can read the session's allowed actions to show/hide UI).

One constant, used by all three — so audit, authz, and feature flags never drift.

## Mandatory rule

Every VPC Lambda handler declares its action type **statically** and passes it to `auditMiddleware`. **NEVER derive the action type from the HTTP method/path at runtime** — it must be an explicit, centrally-defined constant.

## Central definition: `src/shared/constants/action-types.ts`

```typescript
// TypeScript const = SCREAMING_SNAKE_CASE (enum/const convention)
// DB field value = snake_case (stored in audits.action_type)
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

## Per-route usage (index.ts)

```typescript
import { ActionType } from '../../shared/constants/action-types';

app.get('/posts', audit(ActionType.POSTS_LIST), listPosts);   // Hono middleware
```

## RBAC composition (when authorization is needed)

Action types are the **unit of authorization**, not just an audit label. Because every action is one explicit constant, you compose RBAC by mapping **roles → allowed action types** and checking the route's declared action type against the caller's role — the **same constant drives both audit and authz**, so they never drift.

```typescript
const RBAC: Record<string, Set<ActionType>> = {
  admin:      new Set(Object.values(ActionType)),                       // full CRUD
  registered: new Set([ActionType.SUBSCRIBERS_CREATE]),
  public:     new Set([ActionType.PROFILE_GET, ActionType.POSTS_LIST,
                       ActionType.ARTICLES_LIST, ActionType.ARTICLES_GET]),
};

// a Hono guard reuses the SAME action type the route already declares
export const authorize = (action: ActionType): MiddlewareHandler => async (c, next) => {
  const groups = (c.env.event.requestContext.authorizer?.jwt?.claims?.['cognito:groups'] as string[]) ?? ['public'];
  if (!groups.some((g) => RBAC[g]?.has(action))) throw new UnauthorizedError();
  await next();
};
// route: app.post('/posts', authorize(ActionType.POSTS_CREATE), audit(ActionType.POSTS_CREATE), createPosts);
```

Use it **only when needed** — the three-profile model (`/infrastructure/cognito`) via a simple group check is often enough; promote to an action-type RBAC map when permissions get finer-grained.

**Feature toggles:** make the role→actions map **config-driven** (not hardcoded) to flip a profile's allowed set at runtime — turning features on/off per role via `/backend/environment-config` or a flags store, no deploy. Expose the session's allowed actions (e.g. via `/bff/me`) so the SPA renders UI accordingly.

## Pros / cons

**Pros**
- Single source of truth for "what actions exist" — drives **audit + RBAC** consistently (no drift between them).
- Authorization **decoupled from HTTP method/path** — refactor routes without touching permissions.
- Explicit, greppable, testable (assert each role's allowed set); easy to review/audit.

**Cons**
- **Manual upkeep** — every new action needs a constant (and an RBAC entry); risk of forgetting one (mitigate with a lint/test that every route declares an action type).
- **Coarse-grained** (action-level) — not attribute/row-level; "edit *own* post" still needs an extra ownership check in the handler.
- **Overkill for tiny surfaces** — a plain group check may be simpler until permissions grow.

## Conventions
- The constant **name** is SCREAMING_SNAKE_CASE; the stored **value** (`audits.action_type`) is snake_case — same value everywhere, no mapping. See `/backend/audit-middleware`.
- One action type per handler action. Add a new constant before wiring a new handler — never inline a string literal.
- `fn-og-edge` (Lambda@Edge) writes **no** audit and therefore declares no action type.
