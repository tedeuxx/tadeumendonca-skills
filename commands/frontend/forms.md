Implement or review forms in `apps/fed` (admin compose).

Context: $ARGUMENTS

Forms for admin flows (PostCompose, article editor — Phase 2/3). Concept + conventions; the React form-library snippet lives in `/frontend/framework-react`.

## Pattern
- **Controlled inputs** with a form library (e.g. react-hook-form) + a **zod** schema for validation — mirror the **same shape the BFF validates** (`/backend/openapi`), so client and server agree.
- **Submit → mutation** (`/frontend/api-client`): on success, invalidate the affected queries + navigate; on error, surface the BFF `{ error, message }` inline.
- Disable submit while pending; optimistic updates only where safe to roll back.

## Conventions
- Validate client-side for UX, but the **server is authoritative** (the BFF re-validates).
- snake_case field names (match the API). Build form UI from `/frontend/design-system` (own Tailwind `Field` wrapper + styled `input`/`textarea`/`select`).
- Admin forms live behind `/frontend/authorization`.

## Pros & cons
**Pros**
- Client validation mirrors the BFF zod contract; type-safe; immediate UX feedback.
**Cons**
- The schema is duplicated client/server and must be kept in sync.
- Controlled-input boilerplate.
