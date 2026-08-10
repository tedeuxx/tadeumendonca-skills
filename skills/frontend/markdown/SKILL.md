---
description: Render article markdown to HTML in a React SPA — a markdown renderer with lazy-loaded syntax highlighting, strict sanitisation of untrusted HTML, and typography mapped to the design system. Use when displaying long-form content, hardening a renderer against XSS, or keeping browser output identical to what crawlers are served. Not for the crawler render path (see prerender).
---

Render article markdown in the SPA (concept).

Context: $ARGUMENTS

Articles are stored as markdown (`body_markdown`) and rendered to HTML in the SPA (Phase 3). Concept + conventions; the react-markdown snippet lives in `/framework-react`.

## Pattern
- Render markdown → HTML with a markdown renderer + **syntax highlighting** for code blocks (e.g. react-markdown + rehype-highlight).
- **Sanitize** untrusted HTML; restrict allowed elements (no raw `<script>`).
- Map headings/typography to the design system (`/design-system`).

## Conventions
- Keep the rendered HTML **consistent with the edge prerender** the bots get (`/prerender`) — same content, good SEO, not cloaking.
- Lazy-load the highlighter + theme to keep the initial bundle small.
- Articles fetched via `/api-client`; long-form pages are prime SEO targets (`/seo`).

## Pros & cons
**Pros**
- Safe (sanitized) article rendering with syntax highlight; consistent with the edge prerender output.
**Cons**
- Sanitization must stay strict to avoid XSS.
- Render parity with the prerender path to maintain.
