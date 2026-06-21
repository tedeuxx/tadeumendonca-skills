Design system (custom Tailwind, no component library) — which pattern for each UI need.

Pattern/section: $ARGUMENTS

This skill is the framework-level design-system decision: **own Tailwind components, no third-party
component library** (no shadcn/ui, no Cloudscape). It pairs with `/frontend/framework-react` (the impl home)
and `/frontend/storybook` (where components are documented). **Project-specific identity** — the actual
palette, typography, radius and theme tokens — lives in the app (its `CLAUDE.md` + `src/styles`), NOT here.

## The stack
- **Tailwind CSS** (v3, preflight on) — utility-first; no UI component library.
- **shadcn-style HSL design tokens** in a single `:root` (e.g. `--background`, `--foreground`, `--primary`,
  `--muted`, `--border`, `--ring`, `--radius`) mirrored in `tailwind.config` so utilities (`bg-background`,
  `text-foreground`) map to the tokens. One source of truth; theming = changing the token values.
- **`cn()`** class-merge util (`clsx` + `tailwind-merge`) for conditional/variant classes — **no `cva`**
  (keep variants as plain conditionals; reach for `cva` only if a component's variant matrix truly justifies it).
- Components are **hand-built primitives** in `src/components/`, documented in `/frontend/storybook`.

## Which pattern per UI need (build, don't import)
- **Page shell / layout** — a fixed app shell (header + nav + content region) composed with flex/grid
  utilities, not an off-the-shelf `AppLayout`.
- **Card / list item** — one bordered, rounded container primitive reused for feed items, articles, list entries.
- **Form controls** — styled `input`/`textarea`/`select` + a small `Field` wrapper (label + error); validation
  lives in the form layer (`/frontend/forms`).
- **Buttons** — a single `Button` primitive with variants expressed via `cn()` conditionals (primary / ghost / icon).
- **Nav** — header links + a horizontal/secondary nav; active state from the router's `NavLink`.
- **UX states** — explicit loading / empty / error primitives (`/frontend/ux-states`), not a library spinner/status widget.
- **Tables** — a plain semantic `table` styled with utilities; add virtualization only when the dataset demands it.
- **Badges / tags** — a small rounded, token-colored `Badge` primitive.

## Theming
- **Single fixed theme by default** (no light/dark toggle) unless the product needs one — fewer tokens, one
  `:root`, no `ThemeProvider`. A theme switch is a deliberate add (a second token set + a provider), not the baseline.
- **Brand identity is project-specific** — palette, fonts, radius scale and density live in the app's
  `src/styles` and are documented in the app's `CLAUDE.md`. This skill stays identity-agnostic.

## Rationale — why own components over a library
- **Full design control + a bespoke identity** — the look is part of the product's argument, not an
  off-the-shelf framework's flavor.
- **Lean bundle** — ship only the utilities/components actually used; no large component-library payload.
- **Accessibility is on you** — the cost of no library: you must build keyboard/focus/ARIA correctly. For the
  few genuinely complex widgets (menus, dialogs, comboboxes) reach for a **headless** primitive library rather
  than adopting a full design system.

## Pros & cons
**Pros**
- Bespoke identity, minimal bundle, no library lock-in, tokens as the single theming source.
**Cons**
- More to build and own (a11y, variants); slower initial velocity than grabbing a component library off the shelf.
