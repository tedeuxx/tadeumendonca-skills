Set up or review the Claude Code GitHub App automation in a <project> repo.

Context: $ARGUMENTS

AI-assisted development is a **standing preference**: every repo runs the Claude Code GitHub App for an on-demand assistant **and** an automatic PR review — a quality signal alongside (not replacing) SonarCloud + the coverage gates (`/workflow/sonarcloud`, `/backend/coverage`, `/frontend/coverage`). Two workflows, identical across all repos; both use `anthropics/claude-code-action@v1` with the `CLAUDE_CODE_OAUTH_TOKEN` secret.

## `claude.yml` — on-demand assistant (`@claude`)
Triggers when `@claude` appears in an issue (opened/assigned), an issue comment, a PR review, or a PR review comment:
```yaml
on:
  issue_comment: { types: [created] }
  pull_request_review_comment: { types: [created] }
  issues: { types: [opened, assigned] }
  pull_request_review: { types: [submitted] }
jobs:
  claude:
    if: contains(<event body/title>, '@claude')          # gate on the @claude mention
    permissions: { contents: read, pull-requests: read, issues: read, id-token: write, actions: read }
    steps:
      - uses: actions/checkout@v4            # fetch-depth: 1
      - uses: anthropics/claude-code-action@v1
        with:
          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
          additional_permissions: |
            actions: read                    # lets Claude read CI results on the PR
```
With no `prompt`, Claude follows the instruction in the comment that tagged it.

## `claude-code-review.yml` — automatic PR review
Runs on every PR `opened` / `synchronize` / `ready_for_review` / `reopened`:
```yaml
on: { pull_request: { types: [opened, synchronize, ready_for_review, reopened] } }
jobs:
  claude-review:
    permissions: { contents: read, pull-requests: read, issues: read, id-token: write }
    steps:
      - uses: actions/checkout@v4            # fetch-depth: 1
      - uses: anthropics/claude-code-action@v1
        with:
          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
          plugin_marketplaces: 'https://github.com/anthropics/claude-code.git'
          plugins: 'code-review@claude-code-plugins'
          prompt: '/code-review:code-review ${{ github.repository }}/pull/${{ github.event.pull_request.number }}'
```

## Setup (one-time, per repo)
- Install the **Claude GitHub App** on each repo (one-time, via `/install-github-app`) — a runbook step, not Terraform.
- Create `CLAUDE_CODE_OAUTH_TOKEN` (from `claude setup-token`) as a repo secret (`/workflow/github-actions` secrets).

## Choices & trade-offs
- **AI review is advisory, not a required check** — it informs the PR, it does **not** block merge. *Trade-off:* a non-deterministic reviewer could flake or false-positive, so gating merges on it is wrong; the blocking gates stay deterministic (Sonar + coverage). Cost: a missed issue isn't enforced — accepted, since AI review is an extra net, not the safety net.
- **OAuth token (`claude setup-token`), not an API key** — user-scoped, no separate billing key to manage/rotate per repo. *Trade-off:* tied to the owner's auth rather than a service principal — fine for a solo/small-team project; revisit if multiple maintainers need separate attribution.
- **Auto-review on every push (`synchronize`), not just on open** — every revision gets looked at. *Trade-off:* more action runs (cost/noise) vs always-current feedback — accepted at this PR volume; throttle with `paths:` filters if it gets noisy.
- **Mention-gated assistant (`@claude`)** — explicit opt-in per comment rather than auto-acting. *Trade-off:* an extra step vs avoiding unwanted automated edits.

## Conventions
- Pin `anthropics/claude-code-action@v1` and `actions/checkout@v4`; least-privilege `permissions:` per job (`id-token: write` for OIDC; `actions: read` only where Claude reads CI).
- Same two workflows in all repos; scope the review with `paths:` / author filters only if a repo needs it.
