# Worklog and sprint velocity

The worklog is an append-only-by-convention event contract for recording which harness participated in an Issue and stage. `scripts/worklog.py` validates events, prepares a canonical file-backed GitHub comment body, and produces deterministic reports from retained tracker exports. It is offline: it reads files and writes stdout. It does not call GitHub, edit comments, inspect global configuration, or authenticate attribution.

## Surfaces

- `event.schema.json` documents one event. `prepare-event` emits one canonical `<!-- worklog-event:v1 -->` plus JSON-fence envelope. A retained tracker comment may contain more than one complete envelope; each marker must pair with one valid event fence, as the published correction-plus-resume comment does.
- `snapshot.schema.json` documents the planning snapshot. Repositories are paired by explicit repository and milestone number, not title. `counting_units` is the authoritative delivery set.
- `export.schema.json` documents retained tracker input, including pagination state, source comments, hashes, cutoff, and prior inventory.
- `scripts/worklog.py prepare-event EVENT.json` writes a comment body to stdout. Save it in the session scratchpad, inspect it, then use the existing authorized `gh issue comment --body-file` route.
- `scripts/worklog.py report --snapshot SNAPSHOT.json --export EXPORT.json --format json --reproduction-command '…'` writes a deterministic report.

No producer is automatic. Planning writes the snapshot; the acting context prepares events at implementation start, checkpoint/handoff, and outcome. A changed harness or effective configuration creates another segment. Existing `dispatch-metrics` comments remain the separate cumulative token/duration instrument and are neither input nor migrated.

## Continuity between sessions — the home is the Issue, and the format is this event (#514)

**State that must survive a session lives on the Issue being worked, as a `handoff` (or `checkpoint`) worklog event.** Never in a scratch file. The session scratchpad is discarded when the session ends, by design. A file in a shared system temporary directory is untracked, is invisible to every other harness and every gate, and survives only by accident. Sprint state was once carried across sessions in exactly such files. The fifth one was written with its words glued together (`reportlowerboundnotnoagentsran`), and the next session resumed from it anyway. The Issue is the one surface that every harness, every fresh context, and the owner can already read. `gh issue view` works the same way whichever tool runs it.

**The format is bounded, because the Issue is public.** A `.gitignore` stops a commit. It does not stop a paste, and a comment's edit history cannot be repaired. So a continuity record carries **facts and the next act, and nothing else**:

| field | what goes in it | bound |
|---|---|---|
| `revision` | repository, branch, and the commit the work stands at | a SHA, `unknown` or `null` |
| `handoff.state` · `handoff.to` | where the item is, and who acts next (`null` if anyone may) | non-empty string |
| `evidence` | public references: a PR, a check run, a verdict comment, a file path in the repository | **one line, at most 280 characters each, no machine-local path, nothing from `.brand/`** |
| `next_act` | **the one act a resuming session performs first**, stated as an act | **one line, at most 280 characters, same privacy filter; checkpoint and handoff only** |

Reasoning, drafts, conversation, private positioning and "notes for next time" have **no field**, and that is the bound. If something needs more than one line to hand over, it belongs in the pull request, in a commit, or in the tracker as the owner's own comment — never in a continuity record.

**Who checks what — the producer and the reader differ on purpose.** `prepare-event` refuses a `handoff` without `next_act`, and it refuses any evidence entry that runs over the line or the length bound. `validate-event` and `report` accept retained history exactly as it was written. Handoff events posted before this contract have no `next_act`, and a reader that rejected them would turn a published record into a report failure. `next_act` itself is validated everywhere it appears.

**Resuming.** Read the Issue's worklog comments, newest last, and start with the latest `next_act`:

```
gh issue view <n> --repo <owner/repo> --json comments \
  --jq '[.comments[].body|select(contains("<!-- worklog-event:v1 -->"))]|last'
```

Then re-derive everything else from the tracker rather than trusting the record: whether the PR is still open, which head it points at, and whether a verdict names that head. **A continuity record says where the work was. The tracker says where it is.** Sprint-level state has no record of its own and needs none. The order of record is `docs/planning/sprint-<nn>.md`, and each item's position is its own Issue's latest event plus its PR. A sprint summary written somewhere else would be a second source of truth for facts the tracker already holds.

**What nothing enforces.** Nothing makes a session write a handoff before it ends, and nothing makes a resuming session read one. Both are instructions. `prepare-event` bounds a record's *shape*. It cannot tell a true `next_act` from a plausible one, and it cannot detect glued words. That was an authoring defect, not a storage defect, and moving the record does not fix it. What helps is that the output is printed to stdout to be inspected before posting, and one line is short enough to read back. Whether a shared temporary directory is purged on reboot on the machine where this happened was **not measured**, and it no longer matters, because nothing here depends on it.

## Accounting

The delivery key is the fully qualified Issue (`owner/repo#number`). A PR, dispatch, attempt, event, or comment is never a delivery key. The event's `revision.repository` identifies the repository containing the applicable code revision and may name a sibling repository; it does not create another delivery. The source comment remains bound to the repository of the Issue that carries it. The first implementation-start event freezes the estimate and its provenance. Mutable labels and milestone moves do not rewrite it. Corrections preserve the original input and reference the superseded event.

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
