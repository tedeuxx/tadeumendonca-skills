Apply the resource tagging policy in tadeumendonca-iac (shared AWS account).

Context: $ARGUMENTS

The AWS account (`858049036700`) hosts **multiple workloads/environments**. Consistent tags keep workloads and environments distinguishable, drive cost allocation, and make ownership/filtering clear in a shared account.

## Mandatory tags (every resource)
| Tag | Value | Why |
|---|---|---|
| `Project` | `tadeumendonca` | the workload boundary — separates this from other workloads sharing the account |
| `Environment` | `staging` \| `production` | env isolation + cost split |
| `ManagedBy` | `terraform` | provenance (vs console / other tooling) |

## Applied via provider `default_tags` (not per resource)
```hcl
provider "aws" {
  region = var.aws_region
  default_tags { tags = { Project = "tadeumendonca", Environment = var.environment, ManagedBy = "terraform" } }
}
# same default_tags block on the aws.us_east_1 alias
```

## Conventions
- **Set tags once** via `default_tags` on both providers — don't repeat `tags = {}` per resource (add a resource-level tag only for a specific need, e.g. `Name`).
- The **`Project` tag is the workload boundary** — every new workload in this account uses its own `Project` value so cost and ownership stay separable.
- Activate `Project` + `Environment` as **cost-allocation tags** in Billing; use them to scope cost reports, queries, and IAM conditions.
- Keep values lowercase and stable — they feed cost reports and filters.
