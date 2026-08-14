---
description: Set the quality/test/security gate policy that blocks a merge — lint and typecheck at zero, unit coverage ≥85% on both stacks, contract/E2E proof for what exists, dependency and secret scanning, and SAST imported with coverage into one verdict. Use when a merge needs a reviewable Definition of Done, deciding whether a threshold can be lowered, or wiring a new gate into CI. Not for the definition of done itself (see quality-gates) or SonarCloud mechanics (see sonarcloud).
---

# Quality gates

Context: $ARGUMENTS

Extracted from the former `backend` family's `coverage` skill (#230) — this policy is explicitly **framework-agnostic and stack-agnostic**, so it does not belong folded into the backend reference pattern (a BFF-on-Lambda architecture with no live consumer): `quality-assurance` preloads this on every merge request regardless of which stack, or whether either stack is even backend-shaped.

**Framework-agnostic, and stack-agnostic on purpose.** This is the gate list and the thresholds policy;
the concrete runner configuration is specialized per stack. CI **blocks deploy** if any gate fails — no
artifact upload, no CDN invalidation, no function update. IaC has its own gate (`checkov`, in
`cloud-infrastructure`) and is not covered here.

**Quality — identical on both sides:** lint (zero errors), typecheck (zero type errors). No variation —
these are the cheapest gates in the set and the ones most often made advisory "for now".

**Test — one threshold, two kinds of proof.** **Unit coverage ≥ 85%** on lines/functions/branches/
statements, on **both** sides; below threshold blocks. The number is deliberately the same so neither
stack can argue it is the special case. Above the unit line the stacks diverge, because what counts as
*the behaviour actually working* differs — for this backend, that is unit/integration via vitest (see
the Framework section) plus an **API/contract run** — the Postman collection executed against a deployed
API: 401 without a bearer token, 200 with it, schema checks (see the Contract tests section). **Only
what exists is required** — a service with no browser surface owes no E2E journey, but the row that
*does* apply is blocking, and "not applicable" is a claim to be checked once, not a default answer.

**Security — same four checks, different location for the secret.** Dependencies: block on
high/critical advisories, dependency review and automated update PRs. SAST + quality gate: the
SonarCloud Quality Gate blocks merge and imports the unit-coverage lcov, so SAST, coverage and smells
are judged together. Secrets: secret scanning, nothing sensitive committed — on the server a sensitive
value is fetched at runtime from a secret store (see the Secrets section); in a browser bundle there is
no such place at all, so client configuration is non-secret by construction (see the Config section).
Automated review: an automated code-review action on every pull request, advisory rather than blocking.

**Conventions:** do not lower a threshold to go green — fix the gap; an assertion that cannot fail is
worse than no assertion (coverage counts lines executed, not behaviour verified).

### Decision & trade-off
- **One threshold across both stacks, rather than tuning each.** *Why:* a per-stack number invites the
  argument every time a suite is inconvenient. A single shared number converts a recurring negotiation
  into a one-time decision. *Trade-off:* it is arbitrary for at least one of the two stacks, and it will
  occasionally be too strict for glue code and too lax for a core module.
- **Gates block the deploy rather than warn.** *Why:* an advisory gate is a gate that is red on the day
  it matters and has been red for weeks. *Trade-off:* a flaky suite can stop a correct change, so
  flakiness has to be treated as a defect in the gate rather than a cost of having one.
- **Coverage is imported into the SAST gate rather than checked separately.** *Why:* one verdict, one
  place to look, smells cannot be traded off against coverage silently. *Trade-off:* an outage or
  misconfiguration in that one service blocks every merge.

### Pros & cons
**Pros:** deterministic merge gate, one policy, one place to change it; unit + contract + SAST together,
so a change that is covered but broken still fails; framework-agnostic — the policy survives changing
the runner.
**Cons:** an 85% threshold can incentivize trivial tests that raise the number and assert nothing; gates
add latency to every merge, including the ones that could not possibly break anything.
