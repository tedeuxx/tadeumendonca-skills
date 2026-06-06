Render article markdown in tadeumendonca-fed (concept).

Context: $ARGUMENTS

Articles are stored as markdown (`body_markdown`) and rendered to HTML in the SPA (Phase 3). Concept + conventions; the react-markdown snippet lives in `/frontend/framework-react`.

## Pattern
- Render markdown → HTML with a markdown renderer + **syntax highlighting** for code blocks (e.g. react-markdown + rehype-highlight).
- **Sanitize** untrusted HTML; restrict allowed elements (no raw `<script>`).
- Map headings/typography to the design system (`/frontend/design-system`).

## Conventions
- Keep the rendered HTML **consistent with the edge prerender** the bots get (`/backend/prerender`) — same content, good SEO, not cloaking.
- Lazy-load the highlighter + theme to keep the initial bundle small.
- Articles fetched via `/frontend/api-client`; long-form pages are prime SEO targets (`/frontend/seo`).
