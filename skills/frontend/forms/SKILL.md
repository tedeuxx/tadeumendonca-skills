---
description: Build admin forms in a React SPA — controlled inputs with a zod schema mirroring exactly what the server validates, submit as a mutation that invalidates and navigates, and server errors surfaced inline. Use when adding a create or edit screen, keeping client and server validation in step, or handling a pending submit. Not for where the surrounding state lives (see state).
---

Implement or review forms in the SPA (admin compose).

Context: $ARGUMENTS

Forms for admin flows (PostCompose, article editor — Phase 2/3). Concept + conventions; the React form-library snippet lives in `/framework-react`.

## Pattern
- **Controlled inputs** with a form library (e.g. react-hook-form) + a **zod** schema for validation — mirror the **same shape the BFF validates** (`/openapi`), so client and server agree.
- **Submit → mutation** (`/api-client`): on success, invalidate the affected queries + navigate; on error, surface the BFF `{ error, message }` inline.
- Disable submit while pending; optimistic updates only where safe to roll back.

## Conventions
- Validate client-side for UX, but the **server is authoritative** (the BFF re-validates).
- snake_case field names (match the API). Build form UI from `/design-system` (own Tailwind `Field` wrapper + styled `input`/`textarea`/`select`).
- Admin forms live behind `/authorization`.

## Pros & cons
**Pros**
- Client validation mirrors the BFF zod contract; type-safe; immediate UX feedback.
**Cons**
- The schema is duplicated client/server and must be kept in sync.
- Controlled-input boilerplate.
