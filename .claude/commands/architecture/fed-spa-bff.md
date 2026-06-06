Reference architecture: SPA + BFF + modular-monolith backend — the `fed-spa-bff` pattern.

Context: $ARGUMENTS

Use this when building a **public, content-driven single-page app with a serverless backend on AWS** — the pattern the `<project>` platform is built on. This file is the **blueprint**; each piece links to the component skill that implements it.

## Shape
```
Browser ─► CloudFront ─► S3 (React + Vite SPA, CSR)
              │
              └ Viewer Request: Lambda@Edge (3-way)
                   ├ human     → SPA passthrough
                   ├ social bot → OG <head>
                   └ crawler   → prerendered HTML (SEO, no SSR)

SPA ─(Cognito SDK: login + holds JWT)─► Cognito
SPA ─Bearer JWT─► API GW (Cognito JWT authorizer) ─► its OWN BFF Lambda (Hono, 1 per SPA, routes at root)
                                                        ├ reads claims (no auth code) → RBAC/shaping
                                                        └ domain logic / microservices
                                                             ├ DocumentDB (in-VPC)
                                                             ├ Redis (cache-aside)
                                                             ├ Secrets Manager (creds)
                                                             └ S3 (OG images)
IaC (Terraform/TFC) writes all wiring to SSM  ◄─ api & fed read at deploy
```

## Frontend (SPA, CSR — no SSR)
`/frontend/framework-react` · `/frontend/environment-config` · `/frontend/authentication` · `/frontend/authorization` · `/frontend/pagination` · `/frontend/design-system` · `/frontend/seo`

## SEO without SSR (edge dynamic rendering)
`/backend/og-edge-handler` · `/backend/prerender`

## Auth — external to the BFF (Cognito SDK + API GW authorizer)
Authentication/authorization is **kept out of the BFF**: the **Cognito SDK in the SPA** runs login and holds/refreshes the JWT, and the **API Gateway Cognito JWT authorizer** validates every request. The BFF reads the validated claims and has **no auth code** — simpler. Each SPA still has its **own dedicated BFF Lambda (1:1)**, fronted by an API GW that covers only that BFF (routes at root), with its own Cognito app client and domain. SPA side: `/frontend/authentication`; BFF: `/backend/bff`.

## Backend (BFF monolith, in-VPC)
`/backend/framework-hono` (Hono) · `/backend/openapi` · `/backend/bff` · `/backend/lambda-handler` · `/backend/document-db` · `/backend/redis-cache` · `/backend/logging` · `/backend/metrics` · `/backend/error-handling` · `/backend/audit-middleware` · `/backend/action-types` · `/backend/secrets-management` · `/backend/environment-config` · `/backend/og-image-generator`

## Infrastructure (Terraform, IaC = single source of truth)
- Repo/state/modules → `/infrastructure/terraform` · `/infrastructure/terraform`
- Network/DNS → `/infrastructure/vpc` · `/infrastructure/route53`
- Compute/API → `/infrastructure/lambda` · `/infrastructure/api-gateway`
- Edge/CDN → `/infrastructure/cloudfront` · `/infrastructure/waf`
- Data → `/infrastructure/documentdb` · `/infrastructure/elasticache` · `/infrastructure/s3`
- Auth/email → `/infrastructure/cognito` · `/infrastructure/ses`
- Access/config → `/infrastructure/iam` · `/infrastructure/ssm`
- Governance → `/infrastructure/kms` · `/infrastructure/kms` · `/infrastructure/terraform`

## Cross-repo & delivery
Config bus (IaC → SSM → api/fed at deploy) · GitFlow + numeric SemVer (`/workflow/github-actions`) · deploys (`/workflow/github-actions`, `/workflow/github-actions`) · gates (`/backend/coverage`, `/frontend/coverage`) · backlog/docs (`/workflow/github-actions`, `/workflow/documentation-standard`).

## Defining properties
Public + read-heavy · SEO-friendly via **edge dynamic rendering, not SSR** · **one dedicated BFF Lambda per SPA (1:1), API GW fronts only the BFF (routes at root)** · **auth external to the BFF (Cognito SDK + GW authorizer)** · VPC-isolated data · IaC as single source of truth · independent per-repo pipelines · encrypted in transit + at rest · one shared AWS account (tagged per workload).

## When NOT this pattern
Heavy server-rendered/interactive apps (use SSR), pure API products (no SPA/edge), or event/stream-driven workloads — those are future `architecture/*` patterns.

## Pros & cons
**Pros**
- One coherent blueprint tying every component skill together; clean separation (SPA / BFF / edge); auth external to the BFF.
**Cons**
- Opinionated (CSR + edge SEO, modular monolith, 1 BFF per SPA).
- The single BFF is a shared fault domain until microservices arrive.
