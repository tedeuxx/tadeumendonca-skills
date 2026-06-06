Use Amazon CloudWatch in <project> infrastructure.

Context: $ARGUMENTS

## Log group & stream naming
**Path shape:** `/aws/<service>/<project>-<workload>-<env>[/<sub>]` — the **first path levels identify the AWS service** at a glance (`/aws/<service>/`), then a **specific workload** (`<project>-<workload>-<env>`). We keep the `/aws/<service>/` prefix even on groups we create ourselves, so every log group is self-describing: service first, workload next, env last.

| Source | Log group | Created by | Streams |
|---|---|---|---|
| BFF Lambda | `/aws/lambda/<project>-bff-${env}` | Lambda (auto) | `YYYY/MM/DD/[$LATEST]{exec-id}` — app logs **+ EMF metrics** land here |
| og-edge (Lambda@Edge) | `/aws/lambda/us-east-1.<project>-og-edge-${env}` | Lambda@Edge (auto, replicated per edge region) | `{region}/YYYY/MM/DD/...` |
| API GW access logs | `/aws/apigateway/<project>-api-${env}` | us (`aws_cloudwatch_log_group`) | per-stage; `$context.requestId` per entry |
| VPC Flow Logs | `/aws/vpc/flow-logs/<project>-${env}` | us | per-ENI |
| DocumentDB audit | `/aws/docdb/<project>-${env}/audit` | DocDB log export (`/infrastructure/documentdb`) | per-instance |
| DocumentDB profiler | `/aws/docdb/<project>-${env}/profiler` | DocDB log export | per-instance |
| WAF (CLOUDFRONT + REGIONAL) | `aws-waf-logs-<project>-${env}` | us | per-webacl |

- **AWS-mandated exceptions:** Lambda auto-names `/aws/lambda/<function-name>` — so we name the *function* `<project>-bff-${env}` and the group follows the convention for free. **WAF requires the `aws-waf-logs-` prefix** (it can't use `/aws/waf/`), so the workload identifier moves right after that mandated prefix.
- **Env is always the last token** of the workload segment; sub-streams (`/audit`, `/profiler`) come after the workload.
- Retention per env (30d staging / 90d production) via `var.environment`; **encrypted** — key choice in `/infrastructure/kms`.
- Structured app logs come from Powertools Logger (`/backend/logging`).

## Metrics — EMF (Powertools), no collector
- App metrics are **EMF** emitted by **Powertools Metrics** straight into the BFF Lambda log group; CloudWatch auto-extracts them under namespace `<project>/${env}` — **no ADOT collector, no AMP, no Prometheus** (`/backend/metrics`).
- Because EMF is extracted from logs, the Lambda role needs **no `cloudwatch:PutMetricData`** (`/infrastructure/iam`).
- AWS service metrics (Lambda, API GW, DocumentDB, CloudFront, ElastiCache) are available out of the box.

## Alarms & dashboards (as needed)
- Alarms on error rate / p99 latency / 5xx / DLQ depth → SNS to the owner (`/infrastructure/sns`).
- One dashboard per env composing the key Lambda / API GW / DocDB / CloudFront widgets.

## Conventions
- Never log PII or the Authorization header (`/backend/logging`).
- Tag log groups / alarms via `default_tags` (`/infrastructure/terraform`); retention via `var.environment` conditionals (no extra variable).
