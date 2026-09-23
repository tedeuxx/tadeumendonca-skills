#!/usr/bin/env python3
from __future__ import annotations

import copy
import contextlib
import hashlib
import importlib.util
import io
import json
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("worklog", ROOT / "scripts/worklog.py")
worklog = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
SPEC.loader.exec_module(worklog)
FIXTURE = json.loads((ROOT / "scripts/fixtures/worklog/scenario.json").read_text())


def tracker_export(events, complete=True, cutoff="2026-10-01T00:00:00Z"):
    comments = []
    for index, event in enumerate(events):
        body = f"{worklog.EVENT_MARKER}\n```json\n{json.dumps(event, sort_keys=True)}\n```"
        comments.append({"repository": event["issue"].split("#")[0], "issue": event["issue"],
                         "comment_id": index + 1, "created_at": event["timestamp"],
                         "updated_at": event["timestamp"], "body": body,
                         "body_sha256": hashlib.sha256(body.encode()).hexdigest()})
    return {"schema_version": 1, "cutoff": cutoff,
            "repositories": [{"repository": "acme/skills", "pagination_complete": complete},
                             {"repository": "acme/site", "pagination_complete": complete}],
            "prior_inventory": {"complete": complete, "comment_ids": list(range(1, len(comments) + 1))},
            "comments": comments}


class WorklogTest(unittest.TestCase):
    def baseline(self):
        snapshot = worklog.validate_snapshot(copy.deepcopy(FIXTURE["snapshot"]))
        events = copy.deepcopy(FIXTURE["events"])
        events.append(copy.deepcopy(events[0]))  # repeated delivery of one identical event
        return worklog.report(snapshot, tracker_export(events), "python3 scripts/worklog.py report ...")

    def test_cross_repository_mixed_harness_counts_each_issue_once(self):
        result = self.baseline()
        self.assertTrue(result["partial"])
        self.assertEqual(13, result["totals"]["completed_points"])
        self.assertEqual(3, result["totals"]["carryover_points"])
        self.assertEqual({"sole": 5, "mixed": 8, "unknown": 0}, result["totals"]["cohort_points"])
        self.assertEqual(13, sum(result["totals"]["cohort_points"].values()))
        self.assertEqual({"sole": 1, "mixed": 1, "unknown": 1}, result["totals"]["cohort_items"])
        self.assertEqual(13, sum(item["points"] for item in result["items"] if item["credited"]))
        self.assertTrue(any("incomplete attribution coverage: acme/site#8" == warning
                            for warning in result["warnings"]))

    def test_conflicting_duplicate_fails(self):
        events = copy.deepcopy(FIXTURE["events"])
        conflict = copy.deepcopy(events[0])
        conflict["stage"] = "different"
        events.append(conflict)
        with self.assertRaisesRegex(worklog.ContractError, "conflicting content"):
            worklog.report(FIXTURE["snapshot"], tracker_export(events), "reproduce")

    def test_mutation_current_label_cannot_replace_frozen_estimate(self):
        result = self.baseline()
        self.assertEqual(8, next(item["points"] for item in result["items"] if item["issue"] == "acme/skills#7"))
        mutated_total = sum(999 for item in result["items"] if item["credited"])
        self.assertNotEqual(result["totals"]["completed_points"], mutated_total,
                            "MUTATION SURVIVED: current labels replaced frozen estimates")

    def test_mutation_duplicate_and_reopen_cannot_inflate_credit(self):
        result = self.baseline()
        naive_duplicate_total = 8 + 8 + 5 + 3
        self.assertNotEqual(result["totals"]["completed_points"], naive_duplicate_total,
                            "MUTATION SURVIVED: duplicates or reopened work received credit")
        site8 = next(item for item in result["items"] if item["issue"] == "acme/site#8")
        self.assertFalse(site8["credited"])

    def test_mutation_lost_participant_or_repository_breaks_reconciliation(self):
        result = self.baseline()
        mutated = copy.deepcopy(result)
        mutated["items"] = [item for item in mutated["items"] if item["issue"] != "acme/skills#7"]
        self.assertNotEqual(result["totals"]["completed_points"],
                            sum(item["points"] for item in mutated["items"] if item["credited"]),
                            "MUTATION SURVIVED: repository loss still reconciled")
        self.assertEqual("mixed", next(item["cohort"] for item in result["items"] if item["issue"] == "acme/skills#7"))

    def test_incomplete_and_edited_inputs_are_partial_or_invalid(self):
        incomplete = worklog.report(FIXTURE["snapshot"], tracker_export(FIXTURE["events"], False), "reproduce")
        self.assertTrue(incomplete["partial"])
        corrupt = tracker_export(FIXTURE["events"])
        corrupt["comments"][0]["body"] += "edited"
        with self.assertRaisesRegex(worklog.ContractError, "hash mismatch"):
            worklog.report(FIXTURE["snapshot"], corrupt, "reproduce")
        deleted = tracker_export(FIXTURE["events"])
        deleted["comments"].pop()
        result = worklog.report(FIXTURE["snapshot"], deleted, "reproduce")
        self.assertTrue(result["partial"])
        self.assertTrue(any("deleted historical" in warning for warning in result["warnings"]))
        missing_repo = tracker_export(FIXTURE["events"])
        missing_repo["repositories"] = missing_repo["repositories"][:1]
        result = worklog.report(FIXTURE["snapshot"], missing_repo, "reproduce")
        self.assertTrue(any("missing repository: acme/site" == warning for warning in result["warnings"]))

    def test_cutoff_is_an_as_of_boundary_for_acceptance_reopen_and_correction(self):
        events = copy.deepcopy(FIXTURE["events"])
        cases = [
            ("2026-09-01T00:00:00Z", 0),
            ("2026-09-03T23:00:00Z", 8),
            ("2026-09-05T23:00:00Z", 16),
            ("2026-09-07T00:00:00Z", 13),
        ]
        for cutoff, expected in cases:
            with self.subTest(cutoff=cutoff):
                result = worklog.report(FIXTURE["snapshot"], tracker_export(events, cutoff=cutoff), "reproduce")
                self.assertEqual(expected, result["totals"]["completed_points"])
        corrected = copy.deepcopy(events[0])
        corrected["event_id"] = "skills-7-start-backdated-corrected"
        corrected["frozen_estimate"]["points"] = 13
        correction = copy.deepcopy(events[1])
        correction.update({"event_id": "late-correction", "timestamp": "2026-09-07T12:00:00Z",
                           "event_type": "correction", "supersedes_event_id": events[0]["event_id"],
                           "corrected_event": corrected})
        events.append(correction)
        before = worklog.report(FIXTURE["snapshot"], tracker_export(events, cutoff="2026-09-07T11:00:00Z"), "reproduce")
        after = worklog.report(FIXTURE["snapshot"], tracker_export(events, cutoff="2026-09-07T13:00:00Z"), "reproduce")
        self.assertEqual(13, before["totals"]["completed_points"])
        self.assertEqual(18, after["totals"]["completed_points"])

    def test_correction_graph_rejects_collisions_and_supports_chains(self):
        events = copy.deepcopy(FIXTURE["events"])
        cross = copy.deepcopy(events[4])
        bad = copy.deepcopy(events[1])
        bad.update({"event_id": "cross-correction", "event_type": "correction",
                    "supersedes_event_id": events[0]["event_id"], "corrected_event": cross})
        with self.assertRaisesRegex(worklog.ContractError, "replacement event_id collision"):
            worklog.report(FIXTURE["snapshot"], tracker_export(events + [bad]), "reproduce")
        bad["corrected_event"]["event_id"] = "cross-issue-unique"
        with self.assertRaisesRegex(worklog.ContractError, "target and replacement must belong"):
            worklog.report(FIXTURE["snapshot"], tracker_export(events + [bad]), "reproduce")

        first_replacement = copy.deepcopy(events[0])
        first_replacement["event_id"] = "skills-7-start-r1"
        first_replacement["frozen_estimate"]["points"] = 13
        first = copy.deepcopy(events[1])
        first.update({"event_id": "correction-r1", "timestamp": "2026-09-07T10:00:00Z",
                      "event_type": "correction", "supersedes_event_id": events[0]["event_id"],
                      "corrected_event": first_replacement})
        second_replacement = copy.deepcopy(first_replacement)
        second_replacement["event_id"] = "skills-7-start-r2"
        second_replacement["frozen_estimate"]["points"] = 21
        second = copy.deepcopy(first)
        second.update({"event_id": "correction-r2", "timestamp": "2026-09-08T10:00:00Z",
                       "supersedes_event_id": first_replacement["event_id"],
                       "corrected_event": second_replacement})
        result = worklog.report(FIXTURE["snapshot"], tracker_export(events + [first, second]), "reproduce")
        self.assertEqual(21, next(item["points"] for item in result["items"] if item["issue"] == "acme/skills#7"))

    def test_missing_history_and_unknown_participation_are_partial(self):
        empty = worklog.report(FIXTURE["snapshot"], tracker_export([]), "reproduce")
        self.assertTrue(empty["partial"])
        self.assertEqual(3, len([warning for warning in empty["warnings"] if warning.startswith("missing worklog history:")]))
        no_work_snapshot = copy.deepcopy(FIXTURE["snapshot"])
        no_work_snapshot["counting_units"] = []
        self.assertFalse(worklog.report(no_work_snapshot, tracker_export([]), "reproduce")["partial"])

        known_unknown = copy.deepcopy(FIXTURE["events"])
        unknown = copy.deepcopy(known_unknown[3])
        unknown.update({"event_id": "site-7-unknown-checkpoint", "timestamp": "2026-09-02T12:00:00Z",
                        "event_type": "checkpoint", "stage": "build"})
        unknown.pop("frozen_estimate")
        unknown["attribution"].update({"harness": "unknown", "provenance": "declared"})
        known_unknown.append(unknown)
        result = worklog.report(FIXTURE["snapshot"], tracker_export(known_unknown), "reproduce")
        self.assertEqual("unknown", next(item["cohort"] for item in result["items"] if item["issue"] == "acme/site#7"))
        self.assertTrue(result["partial"])

        mixed_unknown = copy.deepcopy(FIXTURE["events"])
        unknown["issue"] = "acme/skills#7"
        unknown["event_id"] = "skills-7-unknown-checkpoint"
        unknown["revision"]["repository"] = "acme/skills"
        mixed_unknown.append(unknown)
        result = worklog.report(FIXTURE["snapshot"], tracker_export(mixed_unknown), "reproduce")
        self.assertEqual("mixed", next(item["cohort"] for item in result["items"] if item["issue"] == "acme/skills#7"))
        self.assertTrue(result["partial"])

    def test_malformed_contract_values_and_marker_versions_fail(self):
        snapshot = copy.deepcopy(FIXTURE["snapshot"])
        snapshot["counting_units"][0]["planned_points"] = True
        with self.assertRaisesRegex(worklog.ContractError, "positive integer"):
            worklog.report(snapshot, tracker_export(FIXTURE["events"]), "reproduce")
        export = tracker_export(FIXTURE["events"])
        export["repositories"][0]["pagination_complete"] = "false"
        with self.assertRaisesRegex(worklog.ContractError, "must be a boolean"):
            worklog.report(FIXTURE["snapshot"], export, "reproduce")
        export = tracker_export(FIXTURE["events"])
        export["prior_inventory"]["complete"] = "false"
        with self.assertRaisesRegex(worklog.ContractError, "must be a boolean"):
            worklog.report(FIXTURE["snapshot"], export, "reproduce")
        event = copy.deepcopy(FIXTURE["events"][0])
        event["frozen_estimate"]["points"] = True
        with self.assertRaisesRegex(worklog.ContractError, "positive integer"):
            worklog.validate_event(event)
        event = copy.deepcopy(FIXTURE["events"][0])
        event["attribution"]["harness"] = {"invented": "identity"}
        with self.assertRaisesRegex(worklog.ContractError, "non-empty string"):
            worklog.validate_event(event)
        accepted = copy.deepcopy(FIXTURE["events"][2])
        accepted["acceptance_evidence"] = [{"invented": "proof"}]
        with self.assertRaisesRegex(worklog.ContractError, "string array"):
            worklog.validate_event(accepted)
        accepted = copy.deepcopy(FIXTURE["events"][2])
        accepted["acceptance_evidence"] = ["/Users/example/private.txt"]
        with self.assertRaisesRegex(worklog.ContractError, "private or machine-local"):
            worklog.validate_event(accepted)
        export = tracker_export(FIXTURE["events"])
        export["comments"][0]["body"] = export["comments"][0]["body"].replace("worklog-event:v1", "worklog-event:v2")
        export["comments"][0]["body_sha256"] = hashlib.sha256(export["comments"][0]["body"].encode()).hexdigest()
        with self.assertRaisesRegex(worklog.ContractError, "unsupported worklog marker version"):
            worklog.report(FIXTURE["snapshot"], export, "reproduce")

    def test_live_correction_segments_and_markdown_are_auditable(self):
        event_paths = sorted((ROOT / "docs/worklog/events").glob("sprint-03-499-*.json"))
        events = [json.loads(path.read_text()) for path in event_paths]
        snapshot = json.loads((ROOT / "docs/planning/sprint-03.worklog.json").read_text())
        result = worklog.report(snapshot, tracker_export(events), "python3 scripts/worklog.py report ...")
        self.assertFalse(any("missing predecessor_event_id" in warning for warning in result["warnings"]))
        item = result["items"][0]
        serialized = json.dumps(item, sort_keys=True)
        self.assertIn("2.0.74", serialized)
        self.assertIn("2.0.77", serialized)
        self.assertIn('"runtime_version": "unknown"', serialized)
        self.assertIn("skills-499-implementation-start-20260923t224133z-corrected", serialized)
        rendered = worklog.markdown(result)
        for needle in ("report version", "schema version", "cohort points", "work-type points",
                       "comment IDs", "Items and retained segments", "2.0.74", "2.0.77", "unknown"):
            self.assertIn(needle, rendered)

    def test_parent_child_overlap_and_unsupported_schema_fail(self):
        snapshot = copy.deepcopy(FIXTURE["snapshot"])
        snapshot["counting_units"][1]["parent"] = "acme/skills#7"
        with self.assertRaisesRegex(worklog.ContractError, "parent/child overlap"):
            worklog.validate_snapshot(snapshot)
        event = copy.deepcopy(FIXTURE["events"][0])
        event["schema_version"] = 2
        with self.assertRaisesRegex(worklog.ContractError, "unsupported"):
            worklog.validate_event(event)
        private = copy.deepcopy(FIXTURE["events"][0])
        private["evidence"] = ["/Users/example/private.txt"]
        with self.assertRaisesRegex(worklog.ContractError, "private or machine-local"):
            worklog.validate_event(private)

    def test_correction_replaces_original_without_erasing_it(self):
        events = copy.deepcopy(FIXTURE["events"])
        corrected = copy.deepcopy(events[0])
        corrected["event_id"] = "skills-7-start-corrected"
        corrected["frozen_estimate"]["points"] = 13
        correction = copy.deepcopy(events[1])
        correction.update({"event_id": "correction-1", "event_type": "correction",
                           "supersedes_event_id": "skills-7-start", "corrected_event": corrected})
        events.append(correction)
        result = worklog.report(FIXTURE["snapshot"], tracker_export(events), "reproduce")
        self.assertEqual(13, next(item["points"] for item in result["items"] if item["issue"] == "acme/skills#7"))
        self.assertEqual(1, result["totals"]["scope_changes"])

    def test_cli_is_deterministic_and_prepare_is_file_backed(self):
        with tempfile.TemporaryDirectory() as directory:
            temp = Path(directory)
            snapshot = temp / "snapshot.json"
            export = temp / "export.json"
            event = temp / "event.json"
            snapshot.write_text(json.dumps(FIXTURE["snapshot"]))
            export.write_text(json.dumps(tracker_export(FIXTURE["events"])))
            event.write_text(json.dumps(FIXTURE["events"][0]))
            command = ["python3", str(ROOT / "scripts/worklog.py"), "report", "--snapshot", str(snapshot),
                       "--export", str(export), "--format", "json", "--reproduction-command", "same command"]
            first = subprocess.run(command, check=True, capture_output=True, text=True).stdout
            second = subprocess.run(command, check=True, capture_output=True, text=True).stdout
            self.assertEqual(first, second)
            prepared = subprocess.run(["python3", str(ROOT / "scripts/worklog.py"), "prepare-event", str(event)],
                                      check=True, capture_output=True, text=True).stdout
            self.assertTrue(prepared.startswith(worklog.EVENT_MARKER))
            invalid = tracker_export(FIXTURE["events"])
            invalid["repositories"][0]["pagination_complete"] = "false"
            export.write_text(json.dumps(invalid))
            failed = subprocess.run(command, check=False, capture_output=True, text=True)
            self.assertEqual(2, failed.returncode)
            self.assertIn("must be a boolean", failed.stderr)
            self.assertNotIn("Traceback", failed.stderr)

    def test_cli_entrypoint_covers_both_formats_validation_and_clean_errors(self):
        with tempfile.TemporaryDirectory() as directory:
            temp = Path(directory)
            snapshot = temp / "snapshot.json"
            export = temp / "export.json"
            event = temp / "event.json"
            snapshot.write_text(json.dumps(FIXTURE["snapshot"]))
            export.write_text(json.dumps(tracker_export(FIXTURE["events"])))
            event.write_text(json.dumps(FIXTURE["events"][0]))
            commands = [
                (["worklog.py", "validate-event", str(event)], '"event_id":"skills-7-start"'),
                (["worklog.py", "prepare-event", str(event)], worklog.EVENT_MARKER),
                (["worklog.py", "report", "--snapshot", str(snapshot), "--export", str(export),
                  "--format", "json", "--reproduction-command", "reproduce"], '"report_version"'),
                (["worklog.py", "report", "--snapshot", str(snapshot), "--export", str(export),
                  "--format", "markdown", "--reproduction-command", "reproduce"], "report version:"),
            ]
            for argv, needle in commands:
                with self.subTest(argv=argv[1]), mock.patch.object(sys, "argv", argv):
                    stdout = io.StringIO()
                    with contextlib.redirect_stdout(stdout):
                        self.assertEqual(0, worklog.main())
                    self.assertIn(needle, stdout.getvalue())
            with mock.patch.object(sys, "argv", ["worklog.py", "validate-event", str(temp / "missing.json")]):
                stderr = io.StringIO()
                with contextlib.redirect_stderr(stderr):
                    self.assertEqual(2, worklog.main())
                self.assertIn("cannot read JSON", stderr.getvalue())
                self.assertNotIn("Traceback", stderr.getvalue())


if __name__ == "__main__":
    unittest.main(verbosity=2)
