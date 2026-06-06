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

## Pros & cons
**Pros**
- On-demand `@claude` assistant + automatic PR review on every revision.
- Advisory — complements the deterministic gates (Sonar + coverage) without gating on a non-deterministic reviewer.
- OAuth token (`claude setup-token`) — no API key to manage/rotate per repo.
**Cons**
- Non-deterministic, so it must not block merges (a missed issue isn't enforced).
- Review on every push = more action runs (cost/noise).
- Tied to the owner's auth — single attribution, not a service principal.
