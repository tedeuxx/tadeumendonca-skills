Write or review docs for any <project> repo following the documentation standard.

Context: $ARGUMENTS

## Rule

All documentation is **Markdown + Mermaid**. **No static image diagrams** — every diagram is Mermaid so it stays diffable and versioned.

## Diagram types

| Diagram | Mermaid | Where |
|---|---|---|
| Infra architecture | `flowchart TD` / `graph LR` | `docs/architecture.md` (each repo) |
| Data model (tables) | `erDiagram` | `apps/bff/docs/data-model.md` |
| Flows / integrations | `sequenceDiagram` | `docs/sequences.md` (`apps/bff` + `apps/fed`) |
| Frontend components | `flowchart LR` | `apps/fed/docs/architecture.md` |

## Expected content per file
- **`<project>-pwa/iac/docs/architecture.md`** — Terraform module dependency graph (+ network topology when a VPC is provisioned: subnets/NAT/endpoints).
- **`apps/bff/docs/data-model.md`** — `erDiagram` of `profiles`, `posts`, `articles`, `subscribers` (fields, types, implicit relations).
- **`apps/bff/docs/sequences.md`** — full PKCE auth, `POST /posts` (admin → API → DynamoDB → SES notification), OG edge (bot → Lambda@Edge → API → S3).
- **`apps/bff/docs/architecture.md`** — Lambdas × API GW × DynamoDB × Secrets Manager × S3.
- **`apps/fed/docs/sequences.md`** — Cognito PKCE login, `useProfile` fetch, infinite-scroll posts.
- **`apps/fed/docs/architecture.md`** — pages × hooks × store × services.

## Conventions
- Every repo has a `docs/` folder; keep diagrams next to the code they describe.
- Documentation is a deliverable per phase (labeled `type:docs`), part of the `v1.0.0` GA criteria.

## Pros & cons
**Pros**
- Diffable, versioned docs; diagrams as code (Mermaid); no binary images to drift.
**Cons**
- Mermaid has expressiveness limits.
- Keeping docs current is a discipline, not enforced.
