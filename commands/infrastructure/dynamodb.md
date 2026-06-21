Provision or review the DynamoDB tables (data.tf) in <project>-iac.

Context: $ARGUMENTS

Infra side (tables + GSIs + PITR + SSM). The api-side client is `/backend/dynamodb`. Module: **`terraform-aws-modules/dynamodb-table/aws ~> 4.0`** (one call per table). DynamoDB replaces DocumentDB — chosen for cost: **on-demand (`PAY_PER_REQUEST`) is ~$0 at idle**, where a DocumentDB cluster is a fixed ~$54/mo always-on instance that this workload's spiky, low-volume traffic can't justify.

## Per-entity tables (not single-table)
One table per entity — maps 1:1 to the domain aggregates, each evolves independently, and on-demand makes the extra tables free at rest. Single-table design is the at-scale DynamoDB pattern; this workload doesn't need its modeling complexity.

**Entity names are always English** — the table, its hash/range keys, GSI partition values, and the matching TS type/repository all use the English domain noun (`polls`/`poll_id`/`gsi_pk="POLL"`, never `pesquisas`/`pesquisa_id`), **even when the product surface is pt-BR** (the UI label can be "Enquete"; the data entity stays `polls`). This keeps the schema, code, IAM ARNs, and SSM keys in one language and consistent with the snake_case-everywhere rule. Why English (not the UI language): the AWS/TS ecosystem, our existing entities (`profile`/`posts`/`articles`/`subscriptions`/`audits`/`comments`/`shortlinks`), and most contributors default to it — mixing languages in identifiers is the kind of drift that's expensive to undo once tables exist (rename = new table + backfill). Mirror this in `/backend/dynamodb` (the repository/type names).

| Table | Hash / Range | GSIs | Purpose |
|---|---|---|---|
| `profile` | `profile_id` | — | the CV document (effectively one item) |
| `posts` | `post_id` | `by-created` (`gsi_pk`="POST" / `created_at`) | feed, newest-first via cursor |
| `articles` | `article_id` | `by-slug` (`slug`), `by-tag` (`tag` / `created_at`) | slug routing + tag queries |
| `subscriptions` | `email` | `by-status` (`status` / `email`), `by-cognito` (`cognito_sub`) | newsletter opt-ins |
| `audits` | `audit_id` | `by-entity` (`entity` / `created_at`), `by-actor` (`actor` / `created_at`) | audit trail (`/backend/audit-middleware`) |

Feed ordering uses a GSI with a **constant partition** (`gsi_pk="POST"`) + `created_at` range so a single `Query` returns newest-first; fine at this scale (revisit if a single partition gets hot). All attribute names are **snake_case** — same on the wire and in the TS interfaces, no mapping (`/backend/dynamodb`).

## Configuration (the arguments we set on every table)
```hcl
module "posts_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 4.0"

  name         = "<project>-posts-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"            # on-demand — ~$0 idle, no capacity planning

  hash_key  = "post_id"
  attributes = [
    { name = "post_id",    type = "S" },
    { name = "gsi_pk",     type = "S" },
    { name = "created_at", type = "S" },
  ]
  global_secondary_indexes = [{
    name            = "by-created"
    hash_key        = "gsi_pk"
    range_key       = "created_at"
    projection_type = "ALL"
  }]

  # encryption at rest — AWS-managed aws/dynamodb KMS key ("" CMK = managed; /infrastructure/kms)
  server_side_encryption_enabled     = true
  server_side_encryption_kms_key_arn = null

  # continuous backups / restore
  point_in_time_recovery_enabled = true

  deletion_protection_enabled = var.environment == "production"
}
```
**Choices that matter:** `PAY_PER_REQUEST` (the whole reason for the pivot — no idle cost, no RCU/WCU planning); **per-entity tables**; GSIs `projection_type = "ALL"` (read-through without a second fetch — storage is cheap at this volume); **PITR on** (continuous backup, 35-day window, restore = new table); `deletion_protection` gated on env; **TTL** on `audits` (`ttl` epoch attribute) to auto-expire old trail entries. Only declare attributes that are a table/GSI key — DynamoDB is schemaless for everything else.

## TTL (where it applies)
```hcl
# audits table only — expire trail entries after the retention window
ttl_enabled        = true
ttl_attribute_name = "ttl"      # epoch seconds; the app sets it on write (/backend/audit-middleware)
```

## Access — IAM, not credentials
DynamoDB has **no master user / no connection secret** — access is pure IAM. The BFF exec role gets `dynamodb:GetItem|PutItem|UpdateItem|DeleteItem|Query|BatchGetItem` scoped to **exactly these table ARNs + their `/index/*`** (`/infrastructure/iam`) — never `dynamodb:*` on `*`, never `Scan` in hot paths. So there is **no Secrets Manager entry for the data tier** (unlike DocumentDB) and nothing to rotate.

## SSM — table names (the config bus)
```hcl
# /${env}/data/profile-table-name       = module.profile_table.dynamodb_table_id
# /${env}/data/posts-table-name         = module.posts_table.dynamodb_table_id
# /${env}/data/articles-table-name      = module.articles_table.dynamodb_table_id
# /${env}/data/subscriptions-table-name = module.subscriptions_table.dynamodb_table_id
# /${env}/data/audits-table-name        = module.audits_table.dynamodb_table_id
```
IaC writes the table names; `apps/bff` reads them at deploy → Lambda env (`/infrastructure/ssm`). Non-sensitive (names only).

## Network
DynamoDB is a **regional service**. With the BFF non-VPC (the default), the Lambda reaches DynamoDB over the **public DynamoDB endpoint with IAM** (no NAT, no VPC endpoint — there is no VPC). **When in-VPC** (e.g. once Redis/RDS forces a VPC), it is reached over a **Gateway VPC endpoint** (like S3) — Lambda→DynamoDB traffic stays on the AWS backbone, **off the NAT path** (`/infrastructure/vpc` declares the `dynamodb` Gateway endpoint alongside `s3`). HTTPS/TLS in transit by default either way (`/infrastructure/kms`).

## Notes
- Tags via provider `default_tags` (`/infrastructure/terraform`); encryption stance `/infrastructure/kms` (AWS-managed `aws/dynamodb` key, no CMK in Phase 1-3).
- Cursor pagination is `Query` + `Limit` + `ExclusiveStartKey`; the opaque cursor is the base64 `LastEvaluatedKey` (`/backend/dynamodb`, `/frontend/pagination`).
- Restore = launch a **new** table from PITR / a backup (no in-place restore) — update the SSM table name after.

## Rationale — DynamoDB over DocumentDB (cost-driven reversal)
DocumentDB is a fixed-cost always-on cluster (~$54/mo `db.t4g.medium`, before replicas/backup) — unviable for a personal site with low, spiky traffic. DynamoDB on-demand bills per request and **costs effectively nothing at idle**, scales to zero operationally, is IAM-auth (no creds/secret/SG), and needs no VPC instance. Trade-off: access patterns must be designed up front (no ad-hoc queries / joins); rich document querying gives way to key+GSI access. For this app's known patterns (profile read, feed list, article by-slug/by-tag) that fits cleanly.

## Decision & trade-off
- **Per-entity tables + GSIs over single-table design.** One table per domain aggregate, with a GSI per access pattern. *Why:* simpler mental model, each entity evolves and is capacity-isolated independently, and on-demand makes the extra tables free at rest. *Trade-off:* gives up single-table's cross-entity transactional reads and its at-scale efficiency — modeling complexity this workload doesn't need.
- **On-demand (`PAY_PER_REQUEST`) over provisioned = scale-to-zero.** Bills per request, ~$0 idle, no RCU/WCU planning. *Trade-off:* per-request pricing is **costlier than provisioned at sustained high steady load** — not this traffic regime, so the trade is worth it.
- **Access patterns are fixed at design time** (key + GSI only; no ad-hoc queries/joins, no `Scan` in hot paths). A new query shape means a new GSI (+ possible backfill). Pagination is cursor-based via the opaque base64 `LastEvaluatedKey`.

## Pros & cons
**Pros**
- On-demand = ~$0 idle, no capacity planning; scales automatically.
- IAM-auth (no credentials, no Secrets Manager, no SG) ; Gateway endpoint keeps traffic off NAT.
- Managed PITR; encryption at rest + TLS by default.
**Cons**
- Access patterns fixed at design time — new query shapes may need a new GSI/backfill.
- No joins / ad-hoc queries; large scans are an anti-pattern.
- Per-request cost can exceed provisioned at sustained high volume (not this workload).
