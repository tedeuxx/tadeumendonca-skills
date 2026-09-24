# Worklog and sprint velocity

The worklog is an append-only-by-convention event contract for recording which harness participated in an Issue and stage. `scripts/worklog.py` validates events, prepares a canonical file-backed GitHub comment body, and produces deterministic reports from retained tracker exports. It is offline: it reads files and writes stdout. It does not call GitHub, edit comments, inspect global configuration, or authenticate attribution.

## Surfaces

- `event.schema.json` documents one event. `prepare-event` emits one canonical `<!-- worklog-event:v1 -->` plus JSON-fence envelope. A retained tracker comment may contain more than one complete envelope; each marker must pair with one valid event fence, as the published correction-plus-resume comment does.
- `snapshot.schema.json` documents the planning snapshot. Repositories are paired by explicit repository and milestone number, not title. `counting_units` is the authoritative delivery set.
- `export.schema.json` documents retained tracker input, including pagination state, source comments, hashes, cutoff, and prior inventory.
- `scripts/worklog.py prepare-event EVENT.json` writes a comment body to stdout. Save it in the session scratchpad, inspect it, then use the existing authorized `gh issue comment --body-file` route.
- `scripts/worklog.py report --snapshot SNAPSHOT.json --export EXPORT.json --format json --reproduction-command '…'` writes a deterministic report.

No producer is automatic. Planning writes the snapshot; the acting context prepares events at implementation start, checkpoint/handoff, and outcome. A changed harness or effective configuration creates another segment. Existing `dispatch-metrics` comments remain the separate cumulative token/duration instrument and are neither input nor migrated.

## Accounting

The delivery key is the fully qualified Issue (`owner/repo#number`). A PR, dispatch, attempt, event, or comment is never a delivery key. The first implementation-start event freezes the estimate and its provenance. Mutable labels and milestone moves do not rewrite it. Corrections preserve the original input and reference the superseded event.

The cutoff is an as-of boundary, not display metadata. A fact enters a report only once its source comment and event timestamp are at or before the cutoff. A correction has two times: the correction comment/event says when the replacement became available; the embedded event timestamp says when the corrected fact was effective. A later backdated correction therefore changes later reports and never earlier ones.

Only the latest effective accepted outcome, with acceptance evidence and an explicit completion sprint, earns points. Reopened work carries over with no credit until reaccepted. Cancelled, superseded, and no-longer-relevant work is excluded. Corrections form one retained graph: replacement IDs cannot collide, target and replacement stay on the same Issue, chains are valid, and cycles fail. Predecessor and resume links are checked against retained nodes, including correction nodes, before the effective projection is derived. The snapshot rejects an aggregate parent counted alongside one of its counted children.

The report assigns a whole item to one mutually exclusive attribution cohort:

- `sole`: one known harness and complete attribution;
- `mixed`: more than one known harness; an unknown segment adds an incomplete-coverage warning;
- `unknown`: attribution cannot be established.

Points are never duplicated per contributor or split arbitrarily. Missing estimates remain unquantified. A snapshot counting unit with no retained event history is missing evidence, not observed no-work, and makes the report partial; a snapshot with no counting units can honestly report a complete zero. Unknown harness participation makes coverage partial even when the surrounding identity was declared. Missing repositories, incomplete pagination, absent prior inventory, unknown sprint boundaries, edited records, or unmapped events likewise make the report explicit about partial evidence; malformed JSON, hash mismatches, unsupported marker/schema versions, conflicting event IDs, invalid corrections, and wrong scalar/container types fail with exit 2.

`prior_inventory` can expose a retained comment ID that later disappears. It cannot prove that an older comment absent from every retained inventory never existed. A null source `updated_at` likewise leaves edit-time evidence unknown; it is retained as null and makes the report partial rather than being silently treated as the creation time. Complete pagination and inventory are declarations about the supplied capture, not authentication of an unobserved past; reports keep these detection limits visible in the source metadata and never promote them to a stronger claim.

These are team planning measurements. They do not convert points to tokens/hours, score individuals, or establish causal harness rankings across different work mixes.

## Provenance and privacy

Attribution provenance is `observed`, `declared`, or `unknown`. Declared harness identity is metadata, not authenticated permission identity. Never infer it from persona, forge account, branch, or global plugin configuration. Runtime/plugin/source fields remain independently visible and unknown stays unknown.

Events contain public evidence only: no transcripts, private material, secrets, or machine-local paths. The same rule applies to acceptance evidence. JSON and Markdown reports retain the input hashes, source comments, cutoff, report/schema version, exact reproduction command, accounting cohorts and work types, unknown/unestimated states, exclusions, and per-Issue event segments. Segment projections keep stage/run/attempt/resume identity, harness/runtime/plugin/source/persona, frozen-estimate and correction provenance, acceptance evidence, and unknown values without authenticating declared identity.

## Calibration

`python3 scripts/worklog.test.py` exercises cross-repository mixed participation, as-of cutoffs, duplicates, retries, reopen, correction chains/collisions, parent/child overlap, incomplete evidence, strict types, marker versions, both report formats, and deterministic output. Its mutation assertions explicitly fail if current labels replace frozen estimates, duplicate/reopened work gains credit, or a repository/participant disappears. The intended implementation must be restored and re-green before review.
