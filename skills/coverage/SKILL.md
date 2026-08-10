---
description: Set the quality, test and security gates for both stacks against one shared threshold — lint, typecheck, unit coverage at or above 85%, browser journeys and server contract runs, dependency advisories and secret scanning, every one of them blocking the deploy. Use when a gate is red, adding gates to a repo, or resisting pressure to lower a threshold to go green. Not for the Sonar step itself (see sonarcloud) or what done means (see verification-and-gates).
family: backend
---

Set up or review the quality, test and security gates — the same policy on both sides of the stack.

Context: $ARGUMENTS

**Framework-agnostic, and stack-agnostic on purpose.** This is the gate list and the thresholds policy;
the concrete runner configuration is specialized and lives in the framework skills. **One document
rather than two** because the policy genuinely is one: the threshold, the blocking behaviour, the
dependency and secret rules and the "don't lower it" convention are identical, and the only real
difference is *which kind of test proves the behaviour*. Keeping them apart meant two files stating the
same number, which is two places for it to drift.

CI **blocks deploy** if any gate fails — no artifact upload, no CDN invalidation, no function update.
IaC has its own gate (`checkov`, in `/terraform`) and is not covered here.

## Quality — identical on both sides

- **Lint** — zero errors.
- **Typecheck** — zero type errors.

No variation, and that is worth stating rather than omitting: these two are the cheapest gates in the
set and the ones most often made advisory "for now".

## Test — one threshold, two kinds of proof

**Unit coverage ≥ 85%** on lines / functions / branches / statements, on **both** sides; below
threshold blocks. The number is deliberately the same so that neither stack can argue it is the
special case.

Above the unit line the stacks diverge, because what counts as *the behaviour actually working*
differs:

| side | what proves it | where the config lives |
|---|---|---|
| browser | **E2E journeys** — the critical paths (home, feed, authenticated entry), driven through a real browser | `/playwright` |
| browser | **component library** — interaction and visual tests, where a component library is used | `/storybook` |
| browser | unit/component runner + coverage thresholds | `/framework-react` |
| server | **API/contract run** — the collection executed against a deployed API: 401 without a bearer token, 200 with it, schema checks | `/postman` |
| server | unit/integration runner + coverage thresholds | `/framework-hono` |

**Only what exists is required.** A static site with no API owes no contract run, and a service with no
browser surface owes no E2E journey — but the row that *does* apply is blocking, and "not applicable"
is a claim to be checked once, not a default answer. A criterion answered `n/a` every time trains the
loop to fake evidence.

## Security — same four checks, different location for the secret

- **Dependencies** — block on high/critical advisories; dependency review and automated update PRs.
- **SAST + quality gate** — the **SonarCloud** Quality Gate blocks merge and imports the unit-coverage
  lcov, so SAST, coverage and smells are judged together (`/sonarcloud`).
- **Secrets** — secret scanning, and nothing sensitive committed. The stacks differ only in where a
  sensitive value legitimately lives: on the server it is fetched at runtime from a secret store
  (`/secrets-management`), and in a browser bundle **there is no such place at all** — anything
  baked in at build time is public, so client configuration is non-secret by construction
  (`/environment-config`).
- **Automated review** — an automated code-review action on every pull request, advisory rather than
  blocking (`/claude-code`).

## Conventions

- **Do not lower a threshold to go green; fix the gap.** The threshold is a gate, not a target, and it
  is the same number on both sides precisely so that lowering it is visible as a policy change rather
  than a local tweak.
- An assertion that cannot fail is worse than no assertion. Coverage counts lines executed, not
  behaviour verified — a suite at 85% with no failing mutation is 85% of nothing.
- Where the gates sit in the pipeline: `/github-actions`. What "done" means, above any
  particular gate: `/verification-and-gates`.

## Decision & trade-off

- **One threshold across both stacks, rather than tuning each.** *Why:* a per-stack number invites the
  argument every time a suite is inconvenient, and the argument is always available because no
  threshold is derivable from first principles. A single shared number converts a recurring negotiation
  into a one-time decision. *Trade-off:* it is arbitrary for at least one of the two stacks, and it will
  occasionally be too strict for glue code and too lax for a core module — the uniformity is bought at
  the cost of fit.
- **Gates block the deploy rather than warn.** *Why:* an advisory gate is a gate that is red on the day
  it matters and has been red for weeks. *Trade-off:* a flaky E2E suite can stop a correct change, so
  flakiness has to be treated as a defect in the gate rather than a cost of having one.
- **Coverage is imported into the SAST gate rather than checked separately.** *Why:* one verdict, one
  place to look, and smells cannot be traded off against coverage silently. *Trade-off:* an outage or
  misconfiguration in that one service blocks every merge.

## Pros & cons

**Pros**
- Deterministic merge gate; one policy, one threshold, one place to change it.
- Unit + journey/contract + SAST together, so a change that is covered but broken still fails.
- Framework-agnostic — the policy survives changing the runner on either side.

**Cons**
- An 85% threshold can incentivize trivial tests that raise the number and assert nothing.
- E2E adds real flakiness risk and the largest share of CI time.
- Gates add latency to every merge, including the ones that could not possibly break anything.
