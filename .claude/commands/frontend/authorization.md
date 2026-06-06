SPA authorization / UI gating in tadeumendonca-fed (concept).

Context: $ARGUMENTS

Conceptual skill. React snippets live in `/frontend/framework-react`.

Client-side authorization is **UX only** — it decides what to *render*, not what's *allowed*. Real enforcement is server-side: the **API GW authorizer** + action-type RBAC (`/backend/action-types`). The SPA reads the user's **groups/claims** from the authenticated session (`/frontend/authentication`) to show/hide UI and guard routes.

## Contract
- Read `cognito:groups` from the session → derive role (e.g. `admin`).
- Guard admin routes (redirect non-admins); conditionally render admin UI.
- For finer control, consume the **allowed actions** the BFF can expose (a `/me` route) for feature toggles (`/backend/action-types`).

## Conventions
- **Client gating is cosmetic** — never the security boundary; every protected call is re-checked server-side.
- No secrets/PII in client logic; a hidden button is not protection.
