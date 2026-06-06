Reference architecture: SPA + BFF + modular-monolith backend — the `fed-spa-bff-monolith` pattern.

Context: $ARGUMENTS

Use this when building a **public, content-driven single-page app with a serverless backend on AWS** — the pattern `tadeumendonca.io` is built on. This file is the **blueprint**; each piece links to the component skill that implements it.

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
`/frontend/framework` · `/frontend/environment-config` · `/frontend/cognito-pkce` · `/frontend/react-query-cursor` · `/frontend/cloudscape-patterns` · `/frontend/seo`

## SEO without SSR (edge dynamic rendering)
`/backend/og-edge-handler` · `/backend/prerender`

## Auth — external to the BFF (Cognito SDK + API GW authorizer)
Authentication/authorization is **kept out of the BFF**: the **Cognito SDK in the SPA** runs login and holds/refreshes the JWT, and the **API Gateway Cognito JWT authorizer** validates every request. The BFF reads the validated claims and has **no auth code** — simpler. Each SPA still has its **own dedicated BFF Lambda (1:1)**, fronted by an API GW that covers only that BFF (routes at root), with its own Cognito app client and domain. SPA side: `/frontend/cognito-pkce`; BFF: `/backend/bff`.

## Backend (BFF monolith, in-VPC)
`/backend/framework` (Hono) · `/backend/openapi` · `/backend/bff` · `/backend/lambda-handler` · `/backend/docdb-connection` · `/backend/redis-cache` · `/backend/logging` · `/backend/metrics` · `/backend/error-handling` · `/backend/audit-middleware` · `/backend/action-types` · `/backend/secrets-management` · `/backend/environment-config` · `/backend/og-image-generator`

## Infrastructure (Terraform, IaC = single source of truth)
- Repo/state/modules → `/infrastructure/terraform` · `/infrastructure/module-policy`
- Network/DNS → `/infrastructure/vpc-networking` · `/infrastructure/dns`
- Compute/API → `/infrastructure/lambda-pattern-b` · `/infrastructure/api-gw-contract`
- Edge/CDN → `/infrastructure/cloudfront-spa` · `/infrastructure/waf`
- Data → `/infrastructure/documentdb-cluster` · `/infrastructure/elasticache-redis` · `/infrastructure/s3-buckets`
- Auth/email → `/infrastructure/cognito-custom-domain` · `/infrastructure/ses-email`
- Access/config → `/infrastructure/iam-oidc-roles` · `/infrastructure/ssm-config-bus`
- Governance → `/infrastructure/encryption` · `/infrastructure/kms` · `/infrastructure/tagging`

## Cross-repo & delivery
Config bus (IaC → SSM → api/fed at deploy) · GitFlow + numeric SemVer (`/workflow/gitflow`) · deploys (`/workflow/deploy-api`, `/workflow/deploy-fed`) · gates (`/workflow/testing-coverage`) · backlog/docs (`/workflow/issue-backlog`, `/workflow/documentation-standard`).

## Defining properties
Public + read-heavy · SEO-friendly via **edge dynamic rendering, not SSR** · **one dedicated BFF Lambda per SPA (1:1), API GW fronts only the BFF (routes at root)** · **auth external to the BFF (Cognito SDK + GW authorizer)** · VPC-isolated data · IaC as single source of truth · independent per-repo pipelines · encrypted in transit + at rest · one shared AWS account (tagged per workload).

## When NOT this pattern
Heavy server-rendered/interactive apps (use SSR), pure API products (no SPA/edge), or event/stream-driven workloads — those are future `architecture/*` patterns.
