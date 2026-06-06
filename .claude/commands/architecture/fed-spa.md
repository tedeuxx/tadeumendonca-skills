Reference architecture: frontend SPA + serverless backend (the "fed SPA" pattern).

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

SPA ─► its OWN BFF Lambda (Hono, 1 per SPA): OIDC PKCE + httpOnly session ─► API GW v2 (JWT) ─► Hono Lambdas (VPC, Pattern B)
                                                                          ├ DocumentDB (in-VPC)
                                                                          ├ Redis (cache-aside + sessions)
                                                                          ├ Secrets Manager (creds)
                                                                          └ S3 (OG images)
IaC (Terraform/TFC) writes all wiring to SSM  ◄─ api & fed read at deploy
```

## Frontend (SPA, CSR — no SSR)
`/frontend/framework` · `/frontend/environment-config` · `/frontend/cognito-pkce` · `/frontend/react-query-cursor` · `/frontend/cloudscape-patterns` · `/frontend/seo`

## SEO without SSR (edge dynamic rendering)
`/backend/og-edge-handler` · `/backend/prerender`

## Auth — always BFF + OIDC PKCE (one BFF per SPA)
**Every fed/SPA has its own dedicated BFF Lambda — a 1:1 mapping, never a BFF shared across frontends.** The BFF (`/backend/bff`) runs OIDC Authorization Code + PKCE server-side with Cognito and gives *its* SPA an httpOnly session cookie — **no tokens in the browser**. A new frontend → a new BFF (its own Cognito app client, its own session store + cookie, its own domain). The SPA side is `/frontend/cognito-pkce`.

## Backend (serverless, in-VPC)
`/backend/framework` (Hono) · `/backend/bff` · `/backend/lambda-handler` · `/backend/docdb-connection` · `/backend/redis-cache` · `/backend/logging` · `/backend/metrics` · `/backend/error-handling` · `/backend/audit-middleware` · `/backend/action-types` · `/backend/secrets-management` · `/backend/environment-config` · `/backend/og-image-generator`

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
Public + read-heavy · SEO-friendly via **edge dynamic rendering, not SSR** · **one dedicated BFF Lambda per SPA (1:1)** · VPC-isolated data · IaC as single source of truth · independent per-repo pipelines · encrypted in transit + at rest · one shared AWS account (tagged per workload).

## When NOT this pattern
Heavy server-rendered/interactive apps (use SSR), pure API products (no SPA/edge), or event/stream-driven workloads — those are future `architecture/*` patterns.
