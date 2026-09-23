#!/usr/bin/env python3
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("worklog", ROOT / "scripts/worklog.py")
worklog = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
SPEC.loader.exec_module(worklog)
FIXTURE = json.loads((ROOT / "scripts/fixtures/worklog/scenario.json").read_text())


def tracker_export(events, complete=True):
    comments = []
    for index, event in enumerate(events):
        body = f"{worklog.EVENT_MARKER}\n```json\n{json.dumps(event, sort_keys=True)}\n```"
        comments.append({"repository": event["issue"].split("#")[0], "issue": event["issue"],
                         "comment_id": index + 1, "created_at": event["timestamp"],
                         "updated_at": event["timestamp"], "body": body,
                         "body_sha256": hashlib.sha256(body.encode()).hexdigest(),
                         "current_labels": ["sp:999"]})
    return {"schema_version": 1, "cutoff": "2026-09-08T00:00:00Z",
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
        self.assertFalse(result["partial"])
        self.assertEqual(13, result["totals"]["completed_points"])
        self.assertEqual(3, result["totals"]["carryover_points"])
        self.assertEqual({"sole": 5, "mixed": 8, "unknown": 0}, result["totals"]["cohort_points"])
        self.assertEqual(13, sum(result["totals"]["cohort_points"].values()))
        self.assertEqual({"sole": 1, "mixed": 1, "unknown": 1}, result["totals"]["cohort_items"])
        self.assertEqual(13, sum(item["points"] for item in result["items"] if item["credited"]))

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


if __name__ == "__main__":
    unittest.main(verbosity=2)
