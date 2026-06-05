Define or review action types for audit logging in tadeumendonca-api.

Context: $ARGUMENTS

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

## Per-handler usage (index.ts)

```typescript
import { ActionType } from '../../shared/constants/action-types';

export const handler = middy(baseHandler)
  .use(auditMiddleware({ actionType: ActionType.POSTS_LIST }));
```

## Conventions
- The constant **name** is SCREAMING_SNAKE_CASE; the stored **value** (`audits.action_type`) is snake_case — same value everywhere, no mapping. See `/backend/audit-middleware`.
- One action type per handler action. Add a new constant before wiring a new handler — never inline a string literal.
- `fn-og-edge` (Lambda@Edge) writes **no** audit and therefore declares no action type.
