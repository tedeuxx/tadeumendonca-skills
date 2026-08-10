---
description: Provision and instrument real-user monitoring end to end — the Terraform app monitor, a Cognito guest identity pool whose role can only put RUM events, the browser client reporting web vitals, JS errors and HTTP latency, and the sampling that bounds the bill. Use when field performance is unknown or a browser error is invisible server-side. Not for product analytics (see analytics) or server-side logs, alarms and traces (see cloudwatch, cloudwatch-xray).
---

Provision the RUM app monitor and instrument the browser that reports to it.

Context: $ARGUMENTS

**One skill for both halves**, because neither is usable alone: the app monitor is inert until a browser
sends to it, and the browser client cannot initialize without two ids that only the monitor's Terraform
produces. The seam between them — monitor id and identity-pool id travelling through the config bus —
is where this actually goes wrong, and it is in this file rather than split across two.

Real-user monitoring captures **web vitals, JS errors, HTTP latency and sessions**, and correlates them
with **X-Ray** for a browser → API → service trace. It is field telemetry, not product analytics
(`/analytics` is the latter, and they answer different questions).

## App monitor + guest identity (Terraform)

```hcl
resource "aws_rum_app_monitor" "web" {
  name   = "<project>-${var.environment}"
  domain = var.domain_name                          # the environment's hostname
  app_monitor_configuration {
    session_sample_rate = 0.1                        # cost control — see the sampling section
    telemetries         = ["performance", "errors", "http"]
    identity_pool_id    = aws_cognito_identity_pool.rum.id
    enable_xray         = true                       # end-to-end with /cloudwatch-xray
  }
  cw_log_enabled = true
}
# Cognito identity pool; its unauthenticated role grants rum:PutRumEvents on this monitor only
resource "aws_cognito_identity_pool" "rum" { allow_unauthenticated_identities = true /* … */ }
```

**Why an identity pool at all:** the reporting client is an anonymous visitor's browser, so there are no
credentials to give it. The guest identity pool is what lets an unauthenticated page obtain short-lived
credentials scoped to a single action. That is also what makes it an **open ingest surface** — anyone
can obtain those credentials — so the guest role is the only boundary and must grant exactly
`rum:PutRumEvents` on this monitor's ARN and nothing else (`/iam`).

## The two ids the browser needs

Terraform publishes them to the parameter store; the build reads them and bakes them into the bundle:

```hcl
# /{env}/frontend/rum-app-monitor-id
# /{env}/frontend/rum-identity-pool-id
```

The client is then initialized with the monitor id, the identity pool id and the region, the same three
telemetries declared above, and `enableXRay` matching the monitor's setting. Both ids are **non-secret**
— they are published to every visitor's browser by design, which is why they travel as ordinary
build-time configuration (`/environment-config`) rather than as secrets. The client snippet
itself lives with the framework (`/framework-react`).

**The failure this pairing prevents:** the two `enable_xray` / `enableXRay` settings and the two
telemetry lists have to agree. When they were documented in separate files, they disagreed silently —
the monitor accepted events it was not configured to correlate, and the trace simply had a gap.

## Sampling and cost

RUM **bills per event**, so `session_sample_rate` is the cost control and it is the one number worth
thinking about. At `0.1` the bill is small and **most sessions are never seen** — which is fine for
aggregate web vitals and actively bad for debugging a specific user's report, because the odds are the
session was not recorded. Raise it temporarily when hunting a field bug; do not leave it raised.

## Conventions

- A **separate monitor per environment**; never one monitor fed by several environments.
- **No PII** in any custom attribute. The events leave the user's browser and land in a log group.
- Production primarily — a low-traffic non-production environment produces sampled noise and a bill.
- Encrypted log group and tagged like everything else (`/kms`,
  `/terraform`).
- Pairs with `/cloudwatch-xray` for the server half of the trace, and with
  `/cloudwatch` for server-side logs and alarms.

## Pros & cons

**Pros**
- Native CloudWatch and X-Ray correlation — one bill, one console, no extra vendor.
- A guest identity pool lets anonymous visitors report real-user data with no login.
- Cheap at low session sampling, and the cost lever is a single number.
- Provisioning and instrumentation stay in step, including the settings that must match on both sides.

**Cons**
- Fewer product-analytics and session-replay features than a dedicated RUM vendor.
- Unauthenticated ingest is an open surface, bounded only by the least-privilege guest role.
- Sampling at 10% misses most sessions, so it answers aggregate questions far better than individual
  ones.
- Adds a client script and its initialization cost to every page load.
