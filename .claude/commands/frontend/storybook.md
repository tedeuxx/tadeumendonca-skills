Build the component library with Storybook in <project>-fed.

Context: $ARGUMENTS

Component-driven development + living documentation for the SPA's component library — develop, document, and test components in isolation. React/config snippets belong with the framework (`/frontend/framework-react`); this is the practice.

## Setup
- Storybook with the **Vite** builder; `*.stories.tsx` colocated with each component.
- Decorate stories with the app providers a component needs (Cloudscape theme — `/frontend/design-system`, React Query, router) so they render like the real app.

## What we story
- Reusable UI (Card, Badge, Timeline, layout, feedback states) and composite sections (CV sections, PostCard, ArticleHeader).
- Each story = a **state**: default / loading / empty / error / admin-vs-public.

## Testing + docs
- **Interaction tests** (`play` functions) for behavior; **visual regression** (Chromatic or snapshots).
- **Autodocs** from stories + prop types = the component reference.
- **a11y** addon for accessibility checks. Runs in CI (`/workflow/github-actions`).

## Conventions
- Develop components in Storybook first (isolation), then compose into pages.
- Stories are committed and kept in sync with the component — a stale story is a smell.
- Cloudscape provides the primitives (`/frontend/design-system`); Storybook documents how we compose them.
