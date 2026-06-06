Use Amazon CloudWatch in tadeumendonca infrastructure.

Context: $ARGUMENTS

## Logs
- **Log groups** per Lambda (auto-created by the lambda module) + **VPC Flow Logs** (`/infrastructure/vpc-networking`) → CloudWatch.
- Retention per env (e.g. 30d staging / 90d production) via `var.environment`; **encrypted** (`/infrastructure/encryption`).
- Structured app logs come from Powertools Logger (`/backend/logging`).

## Metrics
- App metrics arrive as **EMF** from the ADOT collector (`awsemf` exporter, namespace `tadeumendonca/{env}`) — `/backend/metrics`. **No AMP.**
- AWS service metrics (Lambda, API GW, DocumentDB, CloudFront, ElastiCache) are available out of the box.

## Alarms & dashboards (as needed)
- Alarms on error rate / p99 latency / 5xx / DLQ depth → SNS to the owner.
- One dashboard per env composing the key Lambda / API GW / DocDB / CloudFront widgets.

## Conventions
- Never log PII or the Authorization header (`/backend/logging`).
- Tag log groups / alarms per `/infrastructure/tagging`; retention driven by `var.environment` conditionals (no extra variable).
