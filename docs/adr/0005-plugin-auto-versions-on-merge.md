# 0005. The plugin auto-versions on every merge; adoption is the consumer's opt-in

- **Status:** accepted
- **Date:** 2026-07-23
- **Deciders:** the owner
- **Supersedes:** the informal "trunk-based release-only" model (introduced by commit `90a2fec`, never recorded as an ADR)

## Context & problem
This repo is a Claude Code **plugin distributed through a marketplace**. Consumers install it and pull new
versions with `/plugin update`; the marketplace serves the plugin at the version in `.claude-plugin/plugin.json`.

A prior change (`90a2fec`, "trunk-based release model for the skills plugin") removed the auto-bump workflow and
made releases **deliberate-only** (`release.yml`, `workflow_dispatch`), on the reasoning that "a consumed
artifact's tags are a consumer lockfile, so it never auto-bumps on push." That reasoning fits a **semver-pinned
library** (npm dependency), but it is wrong for a **marketplace-distributed plugin**, and it produced a concrete
failure: 36 commits of real improvement — the entire agentic dev-loop roster (11 subagents) plus reconciled
skills — sat on `main` at an unchanged version `0.4.0`, never released, and therefore **never reachable by the
installed plugin**. A restart didn't help, because a restart reloads the *installed* (cached, pinned) plugin, not
`main`. The machine existed in git but not in the harness.

The confusion was conflating **publishing a version** with **forcing adoption**. They are separate: publishing is
cheap; whether to adopt a new version is *always* the consumer's decision (`/plugin update` is opt-in). So there
is no cost to publishing on every merge, and a real cost to not doing so.

## Decision drivers
- A marketplace plugin is only consumable at a *published version* — an unreleased `main` is invisible to it.
- Publishing ≠ forcing: adoption is the consumer's opt-in, so frequent publishing has no downside for consumers.
- The failure mode of deliberate-only is silent: work merges, looks done, and never ships to the harness.
- Consistency with the deploy-model repos (`-io` auto-bumps patch on merge via `version-main.yml`).

## Considered options
1. **Auto-bump PATCH + publish a Release on every merge to `main`; deliberate minor/major on demand** (chosen)
   — a `version-main.yml` mirrors the deploy-model repos: every non-`bump:` push to `main` bumps the patch,
   tags `vX.Y.Z`, and publishes a Release. `release.yml` is kept for a deliberate minor/major milestone. *Trade-off:*
   the version number churns fast (every docs typo is a new patch), and tag history is noisy. Accepted because
   adoption is opt-in — a consumer simply skips versions it doesn't want.
2. **Deliberate release-only** (the prior model, `release.yml` only) — *Why not:* it caused this exact incident.
   It optimizes for a semver-pinned-library consumer this plugin does not have, at the cost of work silently never
   reaching the marketplace.
3. **Auto-bump but suppress the Release for trivial commits** (e.g. only `feat:`/`fix:` publish) — *Why not:* adds
   a classification gate and a judgment call for marginal benefit; the churn it avoids is free to the consumer
   anyway (opt-in adoption). Keep the rule dumb and predictable: every merge publishes.

## Decision outcome
Chosen: **every merge to `main` auto-bumps the patch and publishes a Release** (`version-main.yml`), with
`release.yml` retained for deliberate minor/major. This makes the plugin **continuously releasable** so
improvements reach consumers as fast as they choose to pull them, and it removes the silent "merged but never
shipped" failure mode. The distinction the prior model missed is now explicit in `/workflow/versioning`: a
**marketplace plugin** auto-publishes (adoption is opt-in); a **semver-pinned library** releases deliberately (its
tag is a consumer lockfile).

## Consequences
**Good**
- No work is ever stranded on `main` — a merge is a published version a consumer can pull.
- Publishing and adoption are cleanly separated; the owner never has to remember to cut a release for changes to ship.
- Consistent versioning trigger with the deploy-model repos.

**Bad / accepted costs**
- Version numbers and tags churn quickly; a patch is not a curated milestone (minor/major via `release.yml` are).
- Release notes are per-merge and small; the categorized changelog still groups by conventional-commit type.
- A consumer that wants stability must pin a version deliberately rather than tracking latest.

## Links
- Supersedes the informal release-only model (`90a2fec`); reconciles `/workflow/versioning` and
  `/workflow/github-actions` (which stated "a consumed artifact never auto-bumps"). Same numeric-SemVer scheme as
  [ADR-0001]-era decisions; the trigger, not the scheme, is what this changes.
