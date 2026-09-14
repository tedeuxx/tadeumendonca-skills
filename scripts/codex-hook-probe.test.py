#!/usr/bin/env python3
# purpose: Gate the parts of the Codex hook-seam probe that do not need the vendor
# binary — fixture construction, the expectation table's own discriminating power and
# the recorded event vocabulary — so a change to the probe reddens in CI, where no
# Codex executable exists.
"""Offline suite for scripts/codex-hook-probe.py.

WHAT THIS CANNOT ASSERT, stated here rather than left to be inferred: it never starts a
Codex process, so it says nothing about carrier precedence, trust or route coverage. Those
are the probe's own subject and are measurable only where the vendor binary is installed.
This suite asserts that the INSTRUMENT is well formed and that its checks are capable of
failing. A green here is not evidence about the runtime.
"""

import importlib.util
import json
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location(
    "codex_hook_probe", str(ROOT / "scripts" / "codex-hook-probe.py"))
probe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(probe)

passed = 0
failed = 0


def check(name, condition, detail=""):
    global passed, failed
    if condition:
        passed += 1
        print("PASS %s" % name)
    else:
        failed += 1
        print("FAIL %s %s" % (name, detail))


# --- arm 1: the expectation table still discriminates ------------------------
# Three outcome classes must remain distinct, or the carrier arm cannot fail.
classes = set(probe.CARRIER_EXPECTATIONS.values())
check("carrier expectations carry three distinct outcome classes",
      classes == {"claude", "codex", "none"}, str(sorted(classes)))
check("carrier expectations are non-empty",
      len(probe.CARRIER_EXPECTATIONS) >= 5,
      "only %d cases" % len(probe.CARRIER_EXPECTATIONS))

# The two fallback cases are the hazard the carrier exists to avoid. If either stops
# expecting the Claude set, that is a finding about the runtime and the docs must move
# with it — so pin them by name rather than by count.
check("an invalid hooks type is still expected to resurrect the Claude bundle",
      probe.CARRIER_EXPECTATIONS.get("codex-invalid-type") == "claude")
check("a missing hooks file is still expected to register nothing",
      probe.CARRIER_EXPECTATIONS.get("codex-missing-file") == "none")

# --- arm 2: the event vocabulary ---------------------------------------------
check("the recorded Codex event vocabulary is the twelve read from config/read",
      len(probe.CODEX_HOOK_EVENTS) == 12 and
      probe.CODEX_HOOK_EVENTS == sorted(probe.CODEX_HOOK_EVENTS),
      str(probe.CODEX_HOOK_EVENTS))
# The repository's own registered events must be a SUBSET, or the carrier cannot
# express what this harness already registers.
declared = set(json.loads((ROOT / "hooks" / "hooks.json").read_text())["hooks"].keys())
check("hooks.json declares at least one event", bool(declared))
check("every event this repo registers exists in the Codex vocabulary",
      declared <= set(probe.CODEX_HOOK_EVENTS),
      "unrepresentable: %s" % sorted(declared - set(probe.CODEX_HOOK_EVENTS)))
# Calibration: the subset check must be capable of failing.
check("the subset check can fail",
      not ({"NoSuchEvent"} | declared) <= set(probe.CODEX_HOOK_EVENTS))

# --- arm 3: fixture construction ---------------------------------------------
claude_hooks = json.loads((ROOT / "hooks" / "hooks.json").read_text())
work = Path(tempfile.mkdtemp(prefix="codex-hook-probe-test-"))
built = {}
for case in probe.CARRIER_EXPECTATIONS:
    market, name = probe.build_carrier_fixture(work, case, claude_hooks)
    root = work / case / name
    built[case] = root
    check("fixture %s writes a marketplace" % case, market.exists())
    check("fixture %s carries the Claude manifest" % case,
          (root / ".claude-plugin/plugin.json").exists())
    check("fixture %s carries a skill so an empty read is detectable" % case,
          (root / "skills/probeskill/SKILL.md").exists())

check("claude-only writes NO codex manifest",
      not (built["claude-only"] / ".codex-plugin/plugin.json").exists())
for case in ("codex-path", "codex-missing-file", "codex-invalid-type",
             "codex-no-hooks-key"):
    check("%s writes a codex manifest" % case,
          (built[case] / ".codex-plugin/plugin.json").exists())

path_manifest = json.loads(
    (built["codex-path"] / ".codex-plugin/plugin.json").read_text())
check("codex-path declares a hooks path", path_manifest.get("hooks") == "./codex-hooks.json")
check("codex-path's declared file exists", (built["codex-path"] / "codex-hooks.json").exists())

missing_manifest = json.loads(
    (built["codex-missing-file"] / ".codex-plugin/plugin.json").read_text())
check("codex-missing-file declares a path that is absent",
      not (built["codex-missing-file"] / missing_manifest["hooks"].lstrip("./")).exists())

invalid_manifest = json.loads(
    (built["codex-invalid-type"] / ".codex-plugin/plugin.json").read_text())
check("codex-invalid-type declares a non-string hooks value",
      not isinstance(invalid_manifest.get("hooks"), str))
check("codex-no-hooks-key declares no hooks key",
      "hooks" not in json.loads(
          (built["codex-no-hooks-key"] / ".codex-plugin/plugin.json").read_text()))

# An unknown case must raise rather than silently building nothing.
try:
    probe.build_carrier_fixture(work, "no-such-case-455", claude_hooks)
    check("an unknown carrier case raises", False, "it did not raise")
except probe.Failure:
    check("an unknown carrier case raises", True)
except Exception as exc:  # a different error is still a failure to be specific
    check("an unknown carrier case raises Failure", False, repr(exc))

# --- arm 4: the codex fixture differs in size from the Claude set -------------
claude_count = sum(len(e["hooks"]) for g in claude_hooks["hooks"].values() for e in g)
codex_count = sum(len(e["hooks"])
                  for g in probe.CODEX_HOOKS_FIXTURE["hooks"].values() for e in g)
check("the Claude set is non-empty", claude_count > 0, str(claude_count))
check("the codex fixture is non-empty", codex_count > 0, str(codex_count))
check("replacement is distinguishable from fallback by count",
      codex_count != claude_count,
      "both are %d, so the carrier arm could not tell them apart" % claude_count)

# --- arm 5: the recorder the routes arm counts can actually write -------------
capture = work / "cap"
capture.mkdir()
recorder = probe.make_recorder(work, capture)
check("the recorder is written executable", recorder.stat().st_mode & 0o111)
import subprocess
subprocess.run([str(recorder)], input='{"t":1}', text=True, check=True)
check("the recorder writes a payload when invoked, so a zero delta is a real zero",
      len(list(capture.glob("payload-*"))) == 1)

# --- arm 6: the turn phases are gated, and their pinned shapes are coherent ---
# The gate is the point: a probe that can start a paid model turn by default is one
# nobody can run to check the offline claims. CI has no Codex binary, so this suite can
# assert the PARTITION and never the behaviour behind it.
check("the offline and turn phase sets are disjoint",
      not (set(probe.OFFLINE_PHASES) & set(probe.TURN_PHASES)),
      str(sorted(set(probe.OFFLINE_PHASES) & set(probe.TURN_PHASES))))
check("every phase belongs to exactly one set",
      set(probe.PHASES) == set(probe.OFFLINE_PHASES) | set(probe.TURN_PHASES))
check("the three offline phases are the ones that cost nothing",
      set(probe.OFFLINE_PHASES) == {"carrier", "trust", "routes"},
      str(sorted(probe.OFFLINE_PHASES)))
check("the five turn phases are named",
      set(probe.TURN_PHASES) == {"payload", "block", "identity", "stdin", "matcher"},
      str(sorted(probe.TURN_PHASES)))

# The carrier fixture's matcher must be the measured tool_name. It read "shell" until
# 2026-09-14, when three registrations differing only in this value showed "shell"
# observing zero invocations — a carrier with that spelling reads as installed and
# fires never, which is this repository's own named failure shape.
fixture_matchers = [entry.get("matcher")
                    for group in probe.CODEX_HOOKS_FIXTURE["hooks"].values()
                    for entry in group]
check("the carrier fixture's matcher is the measured shell tool_name",
      fixture_matchers == [probe.TOOL_NAME_SHELL],
      "%s, but tool_name is %r" % (fixture_matchers, probe.TOOL_NAME_SHELL))
check("the shell and edit routes are distinguishable by tool_name",
      probe.TOOL_NAME_SHELL != probe.TOOL_NAME_EDIT)

# Absence versus presence is the whole of the identity finding. If a child-only field
# ever appeared in the parent list, an adapter reading this file would conclude the
# parent is identified.
check("no child-only field is listed as a parent field",
      not (set(probe.CHILD_ONLY_FIELDS) & set(probe.PRETOOLUSE_PARENT_FIELDS)),
      str(sorted(set(probe.CHILD_ONLY_FIELDS) & set(probe.PRETOOLUSE_PARENT_FIELDS))))
check("agent_type is recorded as child-only", "agent_type" in probe.CHILD_ONLY_FIELDS)
check("the parent field list carries the fields an adapter dispatches on",
      {"tool_name", "tool_input", "hook_event_name"} <= set(probe.PRETOOLUSE_PARENT_FIELDS))
check("the parent field list is sorted and unique, so a shape comparison is stable",
      probe.PRETOOLUSE_PARENT_FIELDS == sorted(set(probe.PRETOOLUSE_PARENT_FIELDS)))

# A refusal without a reason is rejected by the runtime in its own words ("hook returned
# decision:block without a non-empty reason"), so an empty reason here would ship a
# bridge that refuses and cannot say why.
check("the block decision uses the runtime's own verb",
      probe.BLOCK_DECISION.get("decision") == "block", str(probe.BLOCK_DECISION))
check("the block decision carries a non-empty reason",
      bool((probe.BLOCK_DECISION.get("reason") or "").strip()))
check("the blocked status the runtime reports is pinned",
      probe.BLOCKED_STATUS == "blocked")

# The hook builder must emit the decision on STDOUT when one is asked for, and nothing
# when it is not — the block phase attributes a refusal to those bytes.
recording = probe.make_hook(work / "arm6-recorder.sh", capture)
refusing = probe.make_hook(work / "arm6-blocker.sh", capture,
                           stdout_json=probe.BLOCK_DECISION)
check("a recorder emits no decision", '"decision"' not in recording.read_text())
check("a blocker emits the decision", '"decision"' in refusing.read_text())
check("both hooks are executable",
      (recording.stat().st_mode & 0o111) and (refusing.stat().st_mode & 0o111))
blocked = subprocess.run([str(refusing)], input='{"t":1}', text=True,
                         capture_output=True)
check("the blocker's stdout parses as the pinned decision",
      json.loads(blocked.stdout) == probe.BLOCK_DECISION, blocked.stdout[:200])
check("the blocker exits zero, so the refusal rides the decision and not the status",
      blocked.returncode == 0, str(blocked.returncode))

# The config writer must place a matcher only when one is given. An always-present
# matcher would make the `nomatcher` control in the matcher phase unreachable.
with_matcher = probe.turn_config(Path("/probe/project"),
                                 [("Bash", Path("/probe/hook.sh"))])
without_matcher = probe.turn_config(Path("/probe/project"),
                                    [(None, Path("/probe/hook.sh"))])
check("a declared matcher is written", 'matcher = "Bash"' in with_matcher)
check("an absent matcher writes no matcher line", "matcher =" not in without_matcher)
check("both configs declare a PreToolUse registration",
      "[[hooks.PreToolUse]]" in with_matcher and "[[hooks.PreToolUse]]" in without_matcher)
check("the PascalCase event spelling is used, not the snake_case trust-key form",
      "hooks.pre_tool_use" not in with_matcher)
roles = probe.turn_config(Path("/probe/project"), [(None, Path("/probe/hook.sh"))],
                          agents=[("probe_child", Path("/probe/role.toml"), "d")])
check("a declared role reaches the config", "[agents.probe_child]" in roles)

print("\n%d passed, %d failed" % (passed, failed))
if passed == 0:
    print("VACUITY: the suite asserted nothing")
    sys.exit(1)
sys.exit(1 if failed else 0)
