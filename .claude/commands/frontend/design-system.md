Design system (Cloudscape) — which component for each UI pattern in tadeumendonca-fed.

Pattern/section: $ARGUMENTS

Like `/frontend/framework-react`, this skill is allowed library-specific snippets (Cloudscape is the chosen design system). Components are developed/documented in `/frontend/storybook`.

## Page shell
```typescript
import AppLayout from '@cloudscape-design/components/app-layout';
import SideNavigation from '@cloudscape-design/components/side-navigation';
// AppLayout wraps every page; SideNavigation provides nav links
```

## CV sections (Phase 1)
- `ContentLayout` + `SpaceBetween` — outer layout
- `Container` + `Header` — each CV section (Experience, Education, Certifications, Skills)
- `Cards` — experience items (company, role, period, description)
- `Table` — certifications list (name, issuer, date, badge link)
- `Badge` — skill tags (one Badge per skill in each category)
- `Timeline` (custom via SpaceBetween) — education timeline

## Feed (Phase 2)
- `Cards` — PostCard grid
- `Button` variant="primary" — compose button (admin only)
- `Form` + `Textarea` — PostCompose admin UI
- `StatusIndicator` — post status (published/draft)
- `Spinner` — loading state during fetch

## Articles (Phase 3)
- `Table` — articles list with tag filter
- `Select` — tag filter dropdown
- `Container` — single article view wrapper
- Article body rendered as markdown inside `Container` — see `/frontend/markdown`

## Feedback states
- `Alert` type="error" — API errors, form validation
- `Spinner` — loading states
- `StatusIndicator` — success/error inline

## Design tokens
```typescript
import '@cloudscape-design/global-styles/index.css';  // in main.tsx
```

## Rationale — why Cloudscape
AWS's open-source design system, used across AWS Console products. On a personal portfolio it signals product-engineering maturity and AWS fluency, and ships accessible, responsive components out of the box (`AppLayout`, `Cards`, `Table`, `Badge`, `ContentLayout`) — no bespoke design system to build.
