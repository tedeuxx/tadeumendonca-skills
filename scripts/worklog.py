#!/usr/bin/env python3
"""Offline worklog event validator and deterministic sprint reporter."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

EVENT_MARKER = "<!-- worklog-event:v1 -->"
EVENT_RE = re.compile(r"<!-- worklog-event:v1 -->\s*```json\s*(\{.*?\})\s*```", re.S)
ISSUE_RE = re.compile(r"^[^/\s]+/[^#\s]+#[1-9][0-9]*$")
SHA_RE = re.compile(r"^[0-9a-f]{7,40}$")
VERSION = "1.0.0"
EVENT_TYPES = {"implementation_start", "checkpoint", "handoff", "outcome", "correction"}
OUTCOMES = {"accepted", "reopened", "cancelled", "superseded", "no_longer_relevant"}
PROVENANCE = {"observed", "declared", "unknown"}
PRIVATE_EVIDENCE = re.compile(r"(?:^|[\s`])(?:/Users/|/private/tmp/|file://|\.brand/)")


class ContractError(ValueError):
    pass


def canonical(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def digest(value: Any) -> str:
    return hashlib.sha256(canonical(value).encode()).hexdigest()


def load(path: str) -> Any:
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ContractError(f"cannot read JSON {path}: {exc}") from exc


def require(obj: dict[str, Any], fields: list[str], where: str) -> None:
    missing = [field for field in fields if field not in obj]
    if missing:
        raise ContractError(f"{where}: missing {', '.join(missing)}")


def timestamp(value: Any, where: str) -> datetime:
    if not isinstance(value, str) or not value.endswith("Z"):
        raise ContractError(f"{where}: timestamp must be UTC and end in Z")
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ContractError(f"{where}: invalid timestamp") from exc


def validate_identity(identity: Any, where: str) -> None:
    if not isinstance(identity, dict):
        raise ContractError(f"{where}: attribution must be an object")
    require(identity, ["harness", "runtime_version", "plugin", "persona", "provenance"], where)
    if identity["provenance"] not in PROVENANCE:
        raise ContractError(f"{where}: invalid provenance")
    if not isinstance(identity["plugin"], dict):
        raise ContractError(f"{where}: plugin must be an object")
    require(identity["plugin"], ["version", "source_revision"], f"{where}.plugin")


def validate_event(event: Any, where: str = "event") -> dict[str, Any]:
    if not isinstance(event, dict):
        raise ContractError(f"{where}: must be an object")
    require(event, ["schema_version", "event_id", "issue", "timestamp", "event_type", "stage",
                    "run_id", "attempt_id", "attribution", "revision", "evidence", "handoff"], where)
    if event["schema_version"] != 1:
        raise ContractError(f"{where}: unsupported schema_version {event['schema_version']!r}")
    if not isinstance(event["event_id"], str) or not event["event_id"].strip():
        raise ContractError(f"{where}: event_id must be non-empty")
    if not isinstance(event["issue"], str) or not ISSUE_RE.fullmatch(event["issue"]):
        raise ContractError(f"{where}: issue must be owner/repo#number")
    timestamp(event["timestamp"], where)
    if event["event_type"] not in EVENT_TYPES:
        raise ContractError(f"{where}: invalid event_type")
    for field in ("stage", "run_id", "attempt_id"):
        if not isinstance(event[field], str) or not event[field].strip():
            raise ContractError(f"{where}: {field} must be non-empty")
    for field in ("predecessor_event_id", "resume_of_event_id"):
        if field in event and event[field] is not None and not isinstance(event[field], str):
            raise ContractError(f"{where}: {field} must be a string or null")
    validate_identity(event["attribution"], f"{where}.attribution")
    revision = event["revision"]
    if not isinstance(revision, dict):
        raise ContractError(f"{where}.revision: must be an object")
    require(revision, ["repository", "branch", "commit"], f"{where}.revision")
    if revision["commit"] not in (None, "unknown") and not SHA_RE.fullmatch(str(revision["commit"])):
        raise ContractError(f"{where}.revision: commit must be a git SHA, unknown, or null")
    if not isinstance(event["evidence"], list) or not all(isinstance(x, str) for x in event["evidence"]):
        raise ContractError(f"{where}: evidence must be a string array")
    if any(PRIVATE_EVIDENCE.search(item) for item in event["evidence"]):
        raise ContractError(f"{where}: evidence contains private or machine-local material")
    if not isinstance(event["handoff"], dict):
        raise ContractError(f"{where}: handoff must be an object")
    if event["event_type"] == "implementation_start":
        require(event, ["frozen_estimate"], where)
        estimate = event["frozen_estimate"]
        if not isinstance(estimate, dict):
            raise ContractError(f"{where}.frozen_estimate: must be an object")
        require(estimate, ["points", "provenance", "commitment_points"], f"{where}.frozen_estimate")
        if not isinstance(estimate["points"], int) or estimate["points"] <= 0:
            raise ContractError(f"{where}.frozen_estimate: points must be a positive integer")
    if event["event_type"] == "outcome":
        require(event, ["outcome"], where)
        if event["outcome"] not in OUTCOMES:
            raise ContractError(f"{where}: invalid outcome")
        if event["outcome"] == "accepted":
            require(event, ["completion_sprint", "acceptance_evidence"], where)
            if not event["acceptance_evidence"]:
                raise ContractError(f"{where}: accepted outcome needs acceptance_evidence")
    if event["event_type"] == "correction":
        require(event, ["supersedes_event_id", "corrected_event"], where)
        validate_event(event["corrected_event"], f"{where}.corrected_event")
        if event["corrected_event"]["event_id"] == event["event_id"]:
            raise ContractError(f"{where}: correction and corrected event IDs must differ")
    return event


def validate_snapshot(snapshot: Any) -> dict[str, Any]:
    if not isinstance(snapshot, dict):
        raise ContractError("snapshot: must be an object")
    require(snapshot, ["schema_version", "sprint", "timezone", "starts_at", "ends_at",
                       "repositories", "counting_units"], "snapshot")
    if snapshot["schema_version"] != 1:
        raise ContractError("snapshot: unsupported schema_version")
    if snapshot["starts_at"] is not None:
        timestamp(snapshot["starts_at"], "snapshot.starts_at")
    if snapshot["ends_at"] is not None:
        timestamp(snapshot["ends_at"], "snapshot.ends_at")
    if not isinstance(snapshot["repositories"], list) or not snapshot["repositories"]:
        raise ContractError("snapshot: repositories must be a non-empty array")
    for index, repo in enumerate(snapshot["repositories"]):
        require(repo, ["repository", "milestone_number"], f"snapshot.repositories[{index}]")
    if not isinstance(snapshot["counting_units"], list):
        raise ContractError("snapshot: counting_units must be an array")
    seen: set[str] = set()
    for index, unit in enumerate(snapshot["counting_units"]):
        require(unit, ["issue", "planned_points", "work_type", "parent"], f"snapshot.counting_units[{index}]")
        if unit["issue"] in seen:
            raise ContractError(f"snapshot: duplicate counting unit {unit['issue']}")
        seen.add(unit["issue"])
    for unit in snapshot["counting_units"]:
        if unit["parent"] in seen:
            raise ContractError(f"snapshot: parent/child overlap {unit['parent']} and {unit['issue']}")
    return snapshot


def extract_events(export: Any) -> tuple[list[dict[str, Any]], list[str], dict[str, Any]]:
    if not isinstance(export, dict):
        raise ContractError("export: must be an object")
    require(export, ["schema_version", "cutoff", "repositories", "prior_inventory", "comments"], "export")
    if export["schema_version"] != 1:
        raise ContractError("export: unsupported schema_version")
    timestamp(export["cutoff"], "export.cutoff")
    warnings: list[str] = []
    if not export["repositories"]:
        warnings.append("missing repositories: export declares no repository source")
    for repo in export["repositories"]:
        require(repo, ["repository", "pagination_complete"], "export.repository")
        if not repo["pagination_complete"]:
            warnings.append(f"incomplete pagination: {repo['repository']}")
    prior = export["prior_inventory"]
    if not isinstance(prior, dict) or not prior.get("complete", False):
        warnings.append("historical integrity unknown: prior inventory is absent or incomplete")
    comments = export["comments"]
    if not isinstance(comments, list):
        raise ContractError("export.comments: must be an array")
    events: list[dict[str, Any]] = []
    current_comment_ids: set[Any] = set()
    for index, comment in enumerate(comments):
        require(comment, ["repository", "issue", "comment_id", "created_at", "updated_at", "body", "body_sha256"],
                f"comment[{index}]")
        timestamp(comment["created_at"], f"comment[{index}].created_at")
        timestamp(comment["updated_at"], f"comment[{index}].updated_at")
        body_hash = hashlib.sha256(comment["body"].encode()).hexdigest()
        current_comment_ids.add(comment["comment_id"])
        if body_hash != comment["body_sha256"]:
            raise ContractError(f"comment[{index}]: body hash mismatch; record was edited or input is corrupt")
        if comment["created_at"] != comment["updated_at"]:
            warnings.append(f"edited historical record: comment {comment['comment_id']}")
        matches = EVENT_RE.findall(comment["body"])
        if EVENT_MARKER in comment["body"] and not matches:
            raise ContractError(f"comment[{index}]: malformed worklog event body")
        for match in matches:
            try:
                event = json.loads(match)
            except json.JSONDecodeError as exc:
                raise ContractError(f"comment[{index}]: invalid event JSON: {exc}") from exc
            events.append(validate_event(event, f"comment[{index}].event"))
            if event["issue"] != comment["issue"] or event["issue"].split("#")[0] != comment["repository"]:
                raise ContractError(f"comment[{index}]: event issue disagrees with comment source")
    prior_ids = set(prior.get("comment_ids", [])) if isinstance(prior, dict) else set()
    deleted = sorted(prior_ids - current_comment_ids, key=str)
    if deleted:
        warnings.append("deleted historical records: " + ", ".join(map(str, deleted)))
    return events, warnings, export


def effective_events(events: list[dict[str, Any]]) -> list[dict[str, Any]]:
    unique: dict[str, dict[str, Any]] = {}
    order: list[str] = []
    for event in events:
        event_id = event["event_id"]
        if event_id in unique:
            if canonical(unique[event_id]) != canonical(event):
                raise ContractError(f"conflicting content for event_id {event_id}")
            continue
        unique[event_id] = event
        order.append(event_id)
    superseded: set[str] = set()
    replacements: list[dict[str, Any]] = []
    for event_id in order:
        event = unique[event_id]
        if event["event_type"] == "correction":
            target = event["supersedes_event_id"]
            if target not in unique:
                raise ContractError(f"correction {event_id}: missing superseded event {target}")
            if target in superseded:
                raise ContractError(f"correction {event_id}: event {target} already superseded")
            superseded.add(target)
            replacements.append(event["corrected_event"])
    result = [unique[event_id] for event_id in order
              if event_id not in superseded and unique[event_id]["event_type"] != "correction"]
    return sorted(result + replacements, key=lambda item: (item["timestamp"], item["event_id"]))


def latest_outcome(events: list[dict[str, Any]]) -> dict[str, Any] | None:
    outcomes = [event for event in events if event["event_type"] == "outcome"]
    return outcomes[-1] if outcomes else None


def report(snapshot: dict[str, Any], export: dict[str, Any], reproduction: str) -> dict[str, Any]:
    events, warnings, raw_export = extract_events(export)
    current = effective_events(events)
    event_ids = {event["event_id"] for event in current}
    for event in current:
        for field in ("predecessor_event_id", "resume_of_event_id"):
            reference = event.get(field)
            if reference and reference not in event_ids:
                warnings.append(f"missing {field} {reference} referenced by {event['event_id']}")
    by_issue: dict[str, list[dict[str, Any]]] = {}
    for event in current:
        by_issue.setdefault(event["issue"], []).append(event)
    units = {unit["issue"]: unit for unit in snapshot["counting_units"]}
    expected_repositories = {repo["repository"] for repo in snapshot["repositories"]}
    exported_repositories = {repo["repository"] for repo in raw_export["repositories"]}
    for repository in sorted(expected_repositories - exported_repositories):
        warnings.append(f"missing repository: {repository}")
    completed = planned = carryover = scope_changes = 0
    unestimated: list[str] = []
    excluded: list[dict[str, str]] = []
    cohorts = {"sole": 0, "mixed": 0, "unknown": 0}
    cohort_items = {"sole": 0, "mixed": 0, "unknown": 0}
    items: list[dict[str, Any]] = []
    work_types: dict[str, int] = {}
    for issue, unit in units.items():
        if isinstance(unit["planned_points"], int):
            planned += unit["planned_points"]
        issue_events = by_issue.get(issue, [])
        starts = [event for event in issue_events if event["event_type"] == "implementation_start"]
        if not starts:
            frozen = None
        else:
            frozen_values = {event["frozen_estimate"]["points"] for event in starts}
            if len(frozen_values) != 1:
                raise ContractError(f"{issue}: multiple uncorrected frozen estimates")
            frozen = next(iter(frozen_values))
            if frozen != unit["planned_points"]:
                scope_changes += 1
        harnesses = {event["attribution"]["harness"] for event in issue_events
                     if event["attribution"]["provenance"] != "unknown"
                     and event["attribution"]["harness"] != "unknown"}
        unknown = any(event["attribution"]["provenance"] == "unknown" for event in issue_events)
        if not issue_events or (unknown and not harnesses):
            cohort = "unknown"
        elif len(harnesses) > 1:
            cohort = "mixed"
            if unknown:
                warnings.append(f"incomplete attribution coverage: {issue}")
        elif len(harnesses) == 1 and not unknown:
            cohort = "sole"
        else:
            cohort = "unknown"
        cohort_items[cohort] += 1
        outcome = latest_outcome(issue_events)
        credited = bool(outcome and outcome["outcome"] == "accepted"
                        and outcome.get("completion_sprint") == snapshot["sprint"] and frozen is not None)
        if credited:
            completed += frozen
            cohorts[cohort] += frozen
            work_types[unit["work_type"]] = work_types.get(unit["work_type"], 0) + frozen
        elif outcome and outcome["outcome"] == "accepted" and frozen is None:
            unestimated.append(issue)
        elif outcome and outcome["outcome"] in {"cancelled", "superseded", "no_longer_relevant"}:
            excluded.append({"issue": issue, "reason": outcome["outcome"]})
        else:
            carryover += frozen or 0
        items.append({"issue": issue, "points": frozen, "cohort": cohort,
                      "outcome": outcome["outcome"] if outcome else "unknown", "credited": credited})
    unmapped = sorted(set(by_issue) - set(units))
    if unmapped:
        warnings.append("missing sprint mapping: " + ", ".join(unmapped))
    if snapshot["starts_at"] is None or snapshot["ends_at"] is None:
        warnings.append("sprint boundary is unknown: duration and points-per-week are not measured")
        duration_days = None
        points_per_week = None
    else:
        start = timestamp(snapshot["starts_at"], "snapshot.starts_at")
        end = timestamp(snapshot["ends_at"], "snapshot.ends_at")
        duration_days = (end - start).total_seconds() / 86400
        if duration_days <= 0:
            raise ContractError("snapshot: ends_at must follow starts_at")
        points_per_week = round(completed * 7 / duration_days, 6)
    partial = bool(warnings or unestimated or unmapped)
    return {
        "report_version": VERSION, "schema_version": 1, "sprint": snapshot["sprint"],
        "cutoff": raw_export["cutoff"], "partial": partial, "warnings": sorted(set(warnings)),
        "source": {"snapshot_sha256": digest(snapshot), "export_sha256": digest(raw_export),
                   "repositories": raw_export["repositories"],
                   "comment_ids": sorted((comment["comment_id"] for comment in raw_export["comments"]), key=str)},
        "reproduction_command": reproduction,
        "totals": {"planned_points": planned, "completed_points": completed,
                   "carryover_points": carryover, "scope_changes": scope_changes,
                   "unestimated_completions": sorted(unestimated), "cohort_points": cohorts,
                   "cohort_items": cohort_items,
                   "work_type_points": dict(sorted(work_types.items())),
                   "duration_days": duration_days,
                   "points_per_week": points_per_week},
        "excluded": excluded, "items": items,
    }


def markdown(data: dict[str, Any]) -> str:
    status = "PARTIAL" if data["partial"] else "COMPLETE"
    totals = data["totals"]
    lines = [f"# {data['sprint']} worklog report", "", f"status: **{status}**",
             f"cutoff: `{data['cutoff']}`", f"snapshot sha256: `{data['source']['snapshot_sha256']}`",
             f"export sha256: `{data['source']['export_sha256']}`", "",
             f"- planned points: {totals['planned_points']}",
             f"- completed points: {totals['completed_points']}",
             f"- carryover points: {totals['carryover_points']}",
             f"- scope changes: {totals['scope_changes']}",
             f"- duration days: {totals['duration_days']}",
             f"- points per week: {totals['points_per_week']}", "", "## Warnings"]
    lines.extend([f"- {warning}" for warning in data["warnings"]] or ["- none"])
    lines.extend(["", "## Reproduce", "", "```sh", data["reproduction_command"], "```", ""])
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    validate = sub.add_parser("validate-event")
    validate.add_argument("event")
    prepare = sub.add_parser("prepare-event")
    prepare.add_argument("event")
    build = sub.add_parser("report")
    build.add_argument("--snapshot", required=True)
    build.add_argument("--export", required=True)
    build.add_argument("--format", choices=("json", "markdown"), default="json")
    build.add_argument("--reproduction-command", required=True)
    args = parser.parse_args()
    try:
        if args.command in {"validate-event", "prepare-event"}:
            event = validate_event(load(args.event))
            if args.command == "validate-event":
                print(canonical(event))
            else:
                print(EVENT_MARKER)
                print("```json")
                print(json.dumps(event, sort_keys=True, indent=2, ensure_ascii=False))
                print("```")
        else:
            data = report(validate_snapshot(load(args.snapshot)), load(args.export), args.reproduction_command)
            print(json.dumps(data, sort_keys=True, indent=2, ensure_ascii=False) if args.format == "json" else markdown(data))
        return 0
    except ContractError as exc:
        print(f"worklog: error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
