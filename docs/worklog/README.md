# Worklog and sprint velocity

The worklog is an append-only-by-convention event contract for recording which harness participated in an Issue and stage. `scripts/worklog.py` validates events, prepares a canonical file-backed GitHub comment body, and produces deterministic reports from retained tracker exports. It is offline: it reads files and writes stdout. It does not call GitHub, edit comments, inspect global configuration, or authenticate attribution.

## Surfaces

- `event.schema.json` documents one event. A canonical comment begins with `<!-- worklog-event:v1 -->` and contains exactly one JSON fence.
- `snapshot.schema.json` documents the planning snapshot. Repositories are paired by explicit repository and milestone number, not title. `counting_units` is the authoritative delivery set.
- `export.schema.json` documents retained tracker input, including pagination state, source comments, hashes, cutoff, and prior inventory.
- `scripts/worklog.py prepare-event EVENT.json` writes a comment body to stdout. Save it in the session scratchpad, inspect it, then use the existing authorized `gh issue comment --body-file` route.
- `scripts/worklog.py report --snapshot SNAPSHOT.json --export EXPORT.json --format json --reproduction-command '…'` writes a deterministic report.

No producer is automatic. Planning writes the snapshot; the acting context prepares events at implementation start, checkpoint/handoff, and outcome. A changed harness or effective configuration creates another segment. Existing `dispatch-metrics` comments remain the separate cumulative token/duration instrument and are neither input nor migrated.

## Accounting

The delivery key is the fully qualified Issue (`owner/repo#number`). A PR, dispatch, attempt, event, or comment is never a delivery key. The first implementation-start event freezes the estimate and its provenance. Mutable labels and milestone moves do not rewrite it. Corrections preserve the original input and reference the superseded event.

Only the latest effective accepted outcome, with acceptance evidence and an explicit completion sprint, earns points. Reopened work carries over with no credit until reaccepted. Cancelled, superseded, and no-longer-relevant work is excluded. The snapshot rejects an aggregate parent counted alongside one of its counted children.

The report assigns a whole item to one mutually exclusive attribution cohort:

- `sole`: one known harness and complete attribution;
- `mixed`: more than one known harness; an unknown segment adds an incomplete-coverage warning;
- `unknown`: attribution cannot be established.

Points are never duplicated per contributor or split arbitrarily. Missing estimates remain unquantified. Missing repositories, incomplete pagination, absent prior inventory, unknown sprint boundaries, edited records, or unmapped events make the report explicit about partial evidence; malformed JSON, hash mismatches, unsupported schemas, conflicting event IDs, and invalid corrections fail with exit 2.

These are team planning measurements. They do not convert points to tokens/hours, score individuals, or establish causal harness rankings across different work mixes.

## Provenance and privacy

Attribution provenance is `observed`, `declared`, or `unknown`. Declared harness identity is metadata, not authenticated permission identity. Never infer it from persona, forge account, branch, or global plugin configuration. Runtime/plugin/source fields remain independently visible and unknown stays unknown.

Events contain public evidence only: no transcripts, private material, secrets, or machine-local paths. Reports retain the input hashes, source references, cutoff, report/schema version, and exact reproduction command.

## Calibration

`python3 scripts/worklog.test.py` exercises cross-repository mixed participation, duplicates, retries, reopen, corrections, parent/child overlap, incomplete evidence, and deterministic output. Its mutation assertions explicitly fail if current labels replace frozen estimates, duplicate/reopened work gains credit, or a repository/participant disappears. The intended implementation must be restored and re-green before review.
