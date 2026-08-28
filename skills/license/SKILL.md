---
description: Apply the MIT licensing standard to a repo — the LICENSE file that gives it legal effect, the matching license field in every manifest, and keeping the copyright year current. Use when creating a repo, auditing license consistency across manifests, or weighing MIT against Apache-2.0 for its patent grant.
purpose: make licensing a standard applied once per repo rather than a decision taken again in each one
---

Apply the repository licensing standard in any <project> repo.

Context: $ARGUMENTS

Every repo on the platform is **MIT-licensed** — permissive, ubiquitous, friction-free, which is the point for code and skills meant to be reused.

## Standard
- A **`LICENSE`** file at the repo root: MIT, `Copyright (c) <year> <owner>`. GitHub **auto-detects** it (shows the license + the "MIT" badge); the file — not just a manifest field — is what gives it legal effect.
- **Manifests declare it too:** `plugin.json` / `package.json` `"license": "MIT"`; OpenAPI `info.license` where applicable (`/openapi`). Keep them in sync with the `LICENSE` file.
- Keep the **copyright year** current (use a range, e.g. `2026–2027`, once it spans years).

## Why MIT (and the trade-off)
- **Permissive, universally understood**, no copyleft obligations → maximizes adoption and reuse (the skills library exists to be reused).
- **Trade-off:** no explicit **patent grant** (Apache-2.0 has one) and no copyleft (derivatives may be closed) — accepted for simplicity; if a patent grant ever matters, Apache-2.0 is the drop-in swap.

## Pros & cons
**Pros**
- One permissive license across all repos — zero legal friction for reuse/contribution.
- GitHub auto-detects the `LICENSE` file (badge + clarity for consumers).
**Cons**
- No patent grant or copyleft (Apache-2.0 / GPL territory) — a deliberate trade for simplicity.
