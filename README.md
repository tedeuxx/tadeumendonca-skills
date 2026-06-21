# tadeumendonca-skills

Personal Claude skills library — encoding 15+ years of technical expertise as reusable AI workflows.

Built on top of [Anthropic Claude](https://claude.ai) and [Claude Code](https://claude.ai/code).

## What this is

Each skill in this repo encodes a specific type of technical task I perform regularly — cloud architecture, backend engineering, IaC, code review, system design — as a structured Claude prompt or skill definition.

The goal: transfer domain knowledge into repeatable, high-quality AI-assisted workflows.

## Capabilities (`commands/`)

- `architecture/` — reference patterns (the `fed-spa-bff` blueprint) tying the pieces together
- `backend/` — Hono BFF on Lambda, DynamoDB, observability, OG/SEO, contract & test gates
- `frontend/` — React + Vite SPA, Cognito auth, state/routing, design system, RUM, SEO
- `infrastructure/` — one skill per AWS service/tool (Terraform parametrization, encryption, IAM)
- `workflow/` — GitHub Actions CI/CD, numeric versioning, Terraform Cloud, SonarCloud, docs

Generic, reusable templates — workload-specific values are `<project>` / `<apex-domain>` placeholders.
Distributed as a **Claude Code plugin + marketplace** (this repo). See [`CLAUDE.md`](./CLAUDE.md) for the full command reference, install (`/plugin marketplace add tedeuxx/tadeumendonca-skills`), and versioning.

Consumed by the `tadeumendonca.io` platform repos: `tadeumendonca-pwa` (the product monorepo — `apps/fed` SPA + `apps/bff` BFF + `iac/` app infra) and `tadeumendonca-iac` (shared regional WAF baseline).

## Related

- [tadeumendonca.io](https://tadeumendonca.io)
- [LinkedIn](https://www.linkedin.com/in/luiz-tadeu-mendonca-83a16530/)
- [GitHub](https://github.com/tedeuxx)
