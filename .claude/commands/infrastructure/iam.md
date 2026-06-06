Use AWS IAM in tadeumendonca infrastructure.

Context: $ARGUMENTS

Modules: `terraform-aws-modules/iam/aws` submodules `iam-policy` + `iam-assumable-role-with-oidc` (`/infrastructure/module-policy`).

## Principles
- **Least privilege** — scope actions and resources; never `Action: "*"` on `Resource: "*"`. Document any broad grant.
- **No long-lived keys** — GitHub pipelines assume roles via **OIDC** (`/infrastructure/iam-oidc-roles`); humans via SSO/console.
- **Roles, not users** — Lambda exec roles via the lambda module's `attach_policy_statements`; deploy roles via `iam-policy` + `iam-assumable-role-with-oidc`.
- The GitHub OIDC provider is **pre-existing** (referenced by `provider_url`, not created here).

## Standard shapes
- Deploy policy → `iam-policy` submodule (`jsonencode`, least-priv statement).
- GitHub deploy role → `iam-assumable-role-with-oidc` (trust scoped to `repo:org/repo:*`).
- Lambda exec → `policy_statements` on the lambda module (secrets/s3/cloudwatch, scoped).

## Conventions
- Role ARNs to SSM for app repos to assume at deploy (`/infrastructure/ssm-config-bus`).
- KMS key policies follow `/infrastructure/kms`; encryption requirements `/infrastructure/encryption`.
