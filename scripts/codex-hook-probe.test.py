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
check("the nine turn phases are named",
      set(probe.TURN_PHASES) == {"payload", "block", "identity", "stdin", "matcher",
                                 "firing", "friction", "carrierfire", "carrierroot"},
      str(sorted(probe.TURN_PHASES)))

# --- arm 6b: the `firing` phase's instrument, which is the one that must discriminate ---
#
# This phase exists because three readings fitted one observation — the route was never
# hooked, the hook was invoked and its decision discarded, or the command failed to
# launch — and nothing separated them. What makes it an instrument rather than a hope is
# that its three registrations differ in exactly the dimensions those readings differ in.
check("the firing phase registers the REAL adapter rather than a stand-in, since the "
      "open question is about that file",
      probe.ADAPTER_PATH.name == "codex-hook-adapter.py" and probe.ADAPTER_PATH.is_file(),
      str(probe.ADAPTER_PATH))
firing_src = (ROOT / "scripts" / "codex-hook-probe.py").read_text().split(
    "def phase_firing")[1].split("\ndef ")[0]
check("the firing phase registers a RELATIVE command, reproducing the carrier's former "
      "spelling and the historical AC1 resolution limb",
      '"bash scripts/firing-rel.sh"' in firing_src)
check("and an ABSOLUTE control beside it, so a zero from the relative one is a reading "
      "about resolution rather than about an unhooked route",
      "str(abs_recorder)" in firing_src)
check("the firing phase turns the adapter's invocation log ON, which is the only thing "
      "that can distinguish 'never called' from 'decision discarded'",
      'env["CODEX_HOOK_ADAPTER_LOG"]' in firing_src)
check("the firing phase FAILS when its control does not fire, so a silent zero over an "
      "unhooked route is not reachable",
      "THE CONTROL DID NOT FIRE" in firing_src)
check("the firing phase FAILS when the act completes despite a logged decision, which "
      "is a strictly worse state than an uninvoked hook",
      "the act COMPLETED with the adapter invoked" in firing_src)
check("the firing act is chosen where this harness's TWO Codex layers disagree — the "
      "execpolicy allows `gh pr merge` and the guard denies it — so a refusal is "
      "attributable to the hook rather than to the cheaper layer",
      "gh pr merge 999999 --merge" in probe.FIRING_COMMAND_TEMPLATE
      and "%s" in probe.FIRING_COMMAND_TEMPLATE)
policy = (ROOT / ".codex" / "rules" / "claude-command-policy.rules").read_text()
# Re-derived from the execpolicy rather than quoted from a comment, and re-derived
# against THE PROBE'S OWN COMMAND rather than against the subcommand: `gh pr merge` is
# `allow` while `gh pr merge --squash` is `forbidden`, so "the two layers disagree" is
# true of the fixture and false of a neighbouring spelling. An arm that asked only
# whether the subcommand appears beside `forbidden` anywhere would have reported the
# disagreement gone, which is how this arm first read.
import re as _re
_words = probe.FIRING_COMMAND_TEMPLATE.split("&&")[1].split()
_rules = _re.findall(r'prefix_rule\(pattern=\[([^\]]*)\],\s*decision="(\w+)"', policy)
_matching = [(p, d) for p, d in _rules
             if [w.strip().strip('"') for w in p.split(",")]
             == _words[:len([w for w in p.split(",")])]]
check("the probe's own firing command is `allow` in the execpolicy, so a refusal of it "
      "can only have come from the hook layer",
      _matching and all(d == "allow" for _, d in _matching),
      str(_matching))
check("calibration: the execpolicy CAN forbid a neighbouring spelling of the same "
      "subcommand, so the `allow` above is a real allow rather than an absent rule",
      any('"gh", "pr", "merge", "--squash"' in p and d == "forbidden"
          for p, d in _rules))

# --- arm 6c: the `friction` phase's instrument — AC7's evidence, and its calibration ---
check("every friction fixture is harmless: each is a touch or an echo, and none names "
      "an act this floor calls irreparable",
      all(t.split()[0] in ("touch", "echo", "FOO=1")
          for _, _, t, _ in probe.FRICTION_FIXTURES),
      str([t for _, _, t, _ in probe.FRICTION_FIXTURES]))
check("the friction fixtures cover the three convenience classes plus a control",
      {k for _, k, _, _ in probe.FRICTION_FIXTURES} == {"control", "convenience"}
      and len([1 for _, k, _, _ in probe.FRICTION_FIXTURES if k == "convenience"]) == 3,
      str(probe.FRICTION_FIXTURES))
friction_src = (ROOT / "scripts" / "codex-hook-probe.py").read_text().split(
    "def phase_friction")[1].split("\ndef ")[0]
check("the friction phase's hook is a pure RECORDER — it passes no stdout_json, so "
      "nothing it observes is attributable to this harness",
      "stdout_json" not in friction_src)
check("the friction phase FAILS when its `:read-only` calibration does not stop the "
      "act, because zeros from a layer that was not in force are not evidence",
      "THE CALIBRATION FAILED" in friction_src)
check("and FAILS when the calibration turn produced no payload, because an unattempted "
      "act is not a refused one",
      "An unattempted act is not a refused one." in friction_src)
check("the friction phase does NOT assert what the three convenience classes do, since "
      "pinning either answer would make it assert the conclusion it measures",
      "REPORTED rather than asserted" in friction_src)
check("the calibration turn's failure to terminate is NON-FATAL, which is what the "
      "first run of this phase got wrong: a refusal leaves the turn waiting on an "
      "approval nobody answers while the reading is already on disk",
      "except Failure as exc:" in friction_src and "second_note = str(exc)" in friction_src)

# --- arm 6d: AC7's narrowing is wired end to end, floor side and adapter side ---
guard_src = (ROOT / "hooks" / "scripts" / "permission-guard.sh").read_text()
check("the guard authors the friction/floor classification itself, via one helper",
      "deny_convenience()" in guard_src)
# TWO, and it was THREE for one round. Rule 8's substitution branch was reverted to a
# plain `deny` on the merge gate's blocking finding: a substitution MANUFACTURES the token
# every floor rule matches on, so routing it here made 13 of 20 irreversible fixtures
# reachable under `off`. The count arm could not have caught that — three was the number
# it was told to expect — which is why the arms that DO catch it live in
# `permission-guard.test.sh` and assert verdicts for manufactured tokens in both spellings.
check("exactly TWO rules use it — the count is the property, since an extra call site "
      "would silently widen what an operator can switch off",
      guard_src.count("\n  deny_convenience \"") == 2,
      str(guard_src.count("\n  deny_convenience \"")))
check("and the SUBSTITUTION branch is NOT one of them: it is a plain `deny`, because it "
      "manufactures the token every other rule matches on",
      'grep -Eq \'(\\$\\(|`)\'' in guard_src
      and guard_src.split('grep -Eq \'(\\$\\(|`)\'')[1].lstrip().startswith("; then\n  deny \""),
      "the substitution branch's call is not a plain deny")
# The companion arms are in the guard's own suite, and BOTH SPELLINGS is the property
# that makes them able to fail — `$( )` is rescued on the trunk-push case by rule 7's
# fail-closed limb and the backtick is not, so a single-spelling arm is green for a reason
# unrelated to its name. Asserted here so the pairing cannot be dropped from that file.
gt = (ROOT / "hooks" / "scripts" / "permission-guard.test.sh").read_text()
check("the guard suite asserts manufactured floor tokens in BOTH spellings",
      "off/$spelling" in gt and "'DOLLAR' 'BACKTICK'" in gt,
      "the both-spellings loop is missing from permission-guard.test.sh")
adapter_src = (ROOT / "scripts" / "codex-hook-adapter.py").read_text()
check("the adapter declines to ask for them rather than authoring a rule of its own",
      'env[CONVENIENCE_ENV] = "off"' in adapter_src)
check("the switch's default is UNCHANGED behaviour: only the exact literal `off` acts",
      'PERMISSION_GUARD_CONVENIENCE_RULES:-on}\" = \"off\"' in guard_src)

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

# --- arm 7: the credential copies a turn phase makes are removed ---------------
# Exercised against real files, without touching the operator's home: the tracking list
# is seeded by hand and the shredder is asked to clear it. A copy of a credential is not
# an artifact worth leaving in a directory nobody sweeps, and an unremovable one must
# fail the run rather than be reported and shrugged at.
probe.SEEDED_HOMES.clear()
fake_homes = []
for index in range(3):
    home = work / ("cred-home-%d" % index)
    home.mkdir()
    (home / "auth.json").write_text('{"probe": "not a credential"}')
    fake_homes.append(home)
    probe.SEEDED_HOMES.append(home)
check("the fixture homes each carry a file to remove",
      all((h / "auth.json").exists() for h in fake_homes))
removed, left = probe.shred_credentials()
check("every tracked credential copy is removed", removed == 3, str(removed))
check("nothing is reported left behind", left == [], str(left))
check("the files are gone from disk, not merely counted",
      not any((h / "auth.json").exists() for h in fake_homes))
# Calibration: the shredder must tolerate a home whose copy is already gone, or a
# re-run after a partial failure would report a phantom.
probe.SEEDED_HOMES.clear()
probe.SEEDED_HOMES.append(fake_homes[0])
removed_again, left_again = probe.shred_credentials()
check("an already-removed copy is not double-counted and is not an error",
      removed_again == 0 and left_again == [],
      "%d %s" % (removed_again, left_again))
probe.SEEDED_HOMES.clear()
check("seed_credential is what appends to the tracking list, so no phase can copy "
      "without being tracked",
      "SEEDED_HOMES.append" in
      (ROOT / "scripts" / "codex-hook-probe.py").read_text().split(
          "def seed_credential")[1].split("def ")[0])

# --- arm 8: the carrier-route phase (`carrierfire`) ---------------------------
# It starts a model turn, so the first thing to pin is that it cannot be reached by the
# unpaid default. `--phase all` runs OFFLINE_PHASES; a paid phase leaking into that set
# spends the operator's tokens on a run nobody authorised.
check("carrierfire is a TURN phase, so --phase all cannot reach it",
      "carrierfire" in probe.TURN_PHASES and "carrierfire" not in probe.OFFLINE_PHASES)
check("carrierfire is reachable by name",
      probe.PHASES.get("carrierfire") is probe.phase_carrierfire)

# The fixture package exists to separate `the carrier route did not fire` from `it fired
# and its RELATIVE command was not found`. That separation survives only while the
# fixture's own command is ABSOLUTE — if it ever becomes relative, both registrations
# share one failure mode and the phase can no longer tell them apart.
shape_root = work / "carrierfire-market"
(shape_root / ".claude-plugin").mkdir(parents=True)
shape_capture = work / "carrierfire-capture"
shape_capture.mkdir()
shape_name = probe.build_shape_package(shape_root, shape_capture)
shape_manifest = json.loads(
    (shape_root / shape_name / ".codex-plugin" / "plugin.json").read_text())
shape_hooks = json.loads((shape_root / shape_name / "codex-hooks.json").read_text())
shape_command = shape_hooks["hooks"]["PreToolUse"][0]["hooks"][0]["command"]
check("the fixture declares the shipped carrier's manifest shape",
      shape_manifest.get("hooks") == "./codex-hooks.json", str(shape_manifest))
check("the fixture registers exactly one PreToolUse handler",
      len(shape_hooks["hooks"]["PreToolUse"][0]["hooks"]) == 1)
check("the fixture's command is ABSOLUTE, so a silent carrier route and an unresolvable "
      "relative command stay distinguishable",
      Path(shape_command).is_absolute(), shape_command)
check("the fixture's recorder exists and is executable",
      Path(shape_command).exists() and Path(shape_command).stat().st_mode & 0o111)
check("the fixture ships a skill, so a zero hook count cannot be a broken package",
      (shape_root / shape_name / "skills" / "probeshape" / "SKILL.md").exists())

# The trust block is APPENDED to the config the installer wrote. `plugin/install` records
# `[plugins."<id>"] enabled = true` there, and dropping that key removes the carrier's
# hooks from `hooks/list` entirely — no error, an empty list. A block that did not begin
# on its own line would corrupt whatever it was appended to instead.
records = [{"key": "a@m:codex-hooks.json:pre_tool_use:0:0", "currentHash": "sha256:aa"},
           {"key": "b@m:codex-hooks.json:pre_tool_use:0:0", "currentHash": "sha256:bb"}]
block = probe.carrier_state_block(records)
check("the trust block opens on a fresh line, so appending cannot corrupt the "
      "enablement table above it", block.startswith("\n"), repr(block[:3]))
check("one hooks.state table is emitted per record",
      block.count("[hooks.state.") == 2, str(block.count("[hooks.state.")))
check("each record's own hash is written, not a shared one",
      'trusted_hash = "sha256:aa"' in block and 'trusted_hash = "sha256:bb"' in block)
check("the emitted key is the record's key verbatim",
      '[hooks.state."a@m:codex-hooks.json:pre_tool_use:0:0"]' in block)
check("an empty record set emits nothing rather than a malformed table",
      probe.carrier_state_block([]) == "")

# The phase must keep the installer's enablement. Asserted on the SOURCE, because the
# behaviour needs the vendor binary and this suite has none — so this arm is a drift
# check over a string and is not evidence that a run preserved anything.
# The trailing cut is on the NEXT phase's banner, not on `OFFLINE_PHASES`: `carrierroot`
# was added between the two and carries the same control marker, so cutting at the
# registry would have handed this arm both phases' source and silently made every
# assertion below true of either one.
phase_src = (ROOT / "scripts" / "codex-hook-probe.py").read_text().split(
    "def phase_carrierfire")[1].split("# Phase: carrierroot")[0]
check("the phase refuses to continue when the installer wrote no enablement block",
      "[plugins." in phase_src and "wrote no [plugins" in phase_src)
check("the trust write APPENDS to the installer-written config rather than replacing it",
      "enablement" in phase_src and "base + carrier_state_block" in phase_src)
check("the phase re-lists after the trust write and compares the REGISTRATION COUNT, "
      "which is what a dropped enablement key changes",
      "changed the REGISTRATION COUNT" in phase_src)
check("the config-route control is pinned by its source name rather than by "
      "'not plugin'", 'by_source.get("user")' in phase_src)
# The phase must not raise on the carrier route being silent: that is the measurement it
# exists to take, and an assertion in either direction would make it conclude what it was
# written to observe. Checked by naming the two raises it IS allowed to carry, so a third
# one added later reddens here rather than quietly deciding the answer.
CONTROLS_MARKER = "the controls, in the order that makes a zero readable"
check("the phase's control block is findable by the marker this arm splits on",
      phase_src.count(CONTROLS_MARKER) == 1,
      "found %d" % phase_src.count(CONTROLS_MARKER))
controls = phase_src.split(CONTROLS_MARKER)[-1]
check("the phase does NOT assert the carrier route fired, which is the measurement it "
      "exists to take",
      not any("shape_payloads" in line or "carrier_route" in line
              for line in controls.splitlines()),
      controls[:200])
check("the phase reports the carrier route's own count rather than asserting it",
      '"carrier_route_invocations": len(shape_payloads)' in phase_src)
check("the phase raises when the config-route control is silent, so a zero from the "
      "carrier cannot be read as a finding",
      "THE CONFIG-ROUTE CONTROL DID NOT FIRE" in phase_src)
check("the phase raises when the act completed while the adapter logged a block",
      "not honoured" in phase_src)
check("the phase reuses the firing act, where the two Codex layers disagree",
      "FIRING_COMMAND_TEMPLATE" in phase_src)
check("the phase installs through the vendor's installer rather than hand-placing a "
      "tree", "plugin/install" in probe.install_plugin.__code__.co_consts
      or any("plugin/install" == c for c in probe.install_plugin.__code__.co_consts))

# --- arm 9: the carrier-root phase (`carrierroot`) ----------------------------
# It answers ONE question — what the runtime hands a carrier-registered hook — and the
# whole of its value is that an absence can be told from a blind instrument. Every check
# below is about that separation, not about the answer.
check("carrierroot is a TURN phase, so --phase all cannot reach it",
      "carrierroot" in probe.TURN_PHASES and "carrierroot" not in probe.OFFLINE_PHASES)
check("carrierroot is reachable by name",
      probe.PHASES.get("carrierroot") is probe.phase_carrierroot)

# The two controls that make an absence mean something. Drop either and the phase reports
# the same JSON while having measured nothing: without the sentinel an unexpanded token
# cannot be told from a runtime that expands nothing, and without the absent name an
# empty argv slot cannot be told from a dropped one.
root_args = probe.root_token_args()
check("the argv carries a SET control name, so expansion machinery has a positive arm",
      "${PROBE_CONTROL_TOKEN}" in root_args, str(root_args))
check("the argv carries an UNSET control name, so an empty slot is readable",
      "${PROBE_ABSENT_TOKEN_ZZZ}" in root_args, str(root_args))
check("every name #491 read out of the bundle is measured",
      all(("${%s}" % n) in root_args
          for n in ("CLAUDE_PLUGIN_ROOT", "PLUGIN_ROOT", "PLUGIN_DATA",
                    "CLAUDE_PLUGIN_DATA")), str(root_args))
check("both bracing spellings are measured, since the run-on strings gave none",
      "$CLAUDE_PLUGIN_ROOT" in root_args and "${CLAUDE_PLUGIN_ROOT}" in root_args)
check("the declared args are all distinct, so an expanded slot maps to one name",
      len(set(root_args)) == len(root_args), str(root_args))

# The fixture. Two packages, because one value proves a name exists and not that it names
# THIS plugin's root — which is the only property a repair could use.
root_market = work / "carrierroot-market"
(root_market / ".claude-plugin").mkdir(parents=True)
cap_plain = work / "cr-plain"; cap_plain.mkdir()
cap_tokens = work / "cr-tokens"; cap_tokens.mkdir()
cap_b = work / "cr-b"; cap_b.mkdir()
probe.build_root_package(root_market, probe.CARRIER_ROOT_A, cap_plain, cap_tokens)
probe.build_root_package(root_market, probe.CARRIER_ROOT_B, cap_b, None)
root_hooks = json.loads(
    (root_market / probe.CARRIER_ROOT_A / "codex-hooks.json").read_text())
root_handlers = root_hooks["hooks"]["PreToolUse"][0]["hooks"]
check("package A registers a NO-ARGUMENT recorder beside the token one, so a token "
      "command that cannot launch still leaves the environment reading obtainable",
      len(root_handlers) == 2, str(len(root_handlers)))
check("package A's plain command is exactly the recorder path, no arguments",
      len(root_handlers[0]["command"].split()) == 1, root_handlers[0]["command"])
check("package A's plain command is ABSOLUTE, since a relative one measures the "
      "carrierfire finding again instead of this one",
      Path(root_handlers[0]["command"]).is_absolute())
check("package A's token command is the recorder path followed by every declared arg",
      root_handlers[1]["command"].split()[1:] == root_args,
      root_handlers[1]["command"])
check("package B registers ONE recorder, so a per-plugin value reads as two strings",
      len(json.loads((root_market / probe.CARRIER_ROOT_B
                      / "codex-hooks.json").read_text())
          ["hooks"]["PreToolUse"][0]["hooks"]) == 1)
check("the two packages' recorders are different files, so their dumps cannot be "
      "confused for one another",
      root_handlers[0]["command"]
      != json.loads((root_market / probe.CARRIER_ROOT_B / "codex-hooks.json").read_text())
      ["hooks"]["PreToolUse"][0]["hooks"][0]["command"])
check("each fixture declares the shipped carrier's manifest shape",
      json.loads((root_market / probe.CARRIER_ROOT_A / ".codex-plugin"
                  / "plugin.json").read_text()).get("hooks") == "./codex-hooks.json")

# The recorder must actually write the three readings. Run it directly — it is a plain
# executable and needs no Codex — and confirm each field is present and non-vacuous.
rec = Path(root_handlers[0]["command"])
check("the recorder is executable", rec.exists() and rec.stat().st_mode & 0o111)
import os as _os
import subprocess as _sub
_env = dict(_os.environ)
_env["PROBE_CONTROL_TOKEN"] = probe.ROOT_PROBE_SENTINEL
# Guarded, and that is not defensiveness for its own sake: mutation-calibrating this arm
# showed that a broken recorder raised here and every LATER arm stopped reporting — the
# "crashed before the summary" shape this repository has already paid for. A named red
# plus the remaining arms is strictly more information than one traceback.
try:
    _sub.run([str(rec), "ARG1"], input='{"tool_name":"Bash"}', text=True,
             env=_env, cwd=str(work), check=True)
    _launched = True
except Exception as _exc:  # noqa: BLE001 - the failure IS the reading
    _launched = False
    check("the recorder launches at all", False, repr(_exc))
_dumps = probe.read_payloads(cap_plain) if _launched else []
check("the recorder wrote exactly one dump", len(_dumps) == 1, str(len(_dumps)))
_sum = (probe.summarise_dumps(_dumps, dict(_os.environ)) if _dumps
        else [{"argv": [], "cwd": None, "stdin_tool_name": None,
               "env_names_added_by_runtime": None, "control_sentinel_in_env": None}])
check("the dump carries argv", (_sum[0]["argv"] or [None])[1:] == ["ARG1"],
      str(_sum[0]["argv"]))
check("the dump carries cwd",
      _sum[0]["cwd"] is not None
      and _os.path.realpath(_sum[0]["cwd"]) == _os.path.realpath(str(work)),
      str(_sum[0]["cwd"]))
check("the dump carries the payload it was handed on stdin",
      _sum[0]["stdin_tool_name"] == "Bash", str(_sum[0]["stdin_tool_name"]))
# The environment diff is the arm most able to be vacuous: it is computed against the
# parent environment, so a bug that diffed against itself would report an empty set
# forever and read as `the runtime adds nothing`.
check("the env diff NAMES a variable the parent did not carry, so an empty diff is a "
      "real empty rather than a dead selector",
      _sum[0]["env_names_added_by_runtime"] == ["PROBE_CONTROL_TOKEN"],
      str(_sum[0]["env_names_added_by_runtime"]))
check("the sentinel is read back out of the dumped environment, so an absent "
      "CLAUDE_PLUGIN_ROOT is a reading about that name and not about scrubbing",
      _sum[0]["control_sentinel_in_env"] == probe.ROOT_PROBE_SENTINEL)
check("the plugin-name selector is calibrated against a known-present hit",
      probe.summarise_dumps(
          [{"env": {"CLAUDE_PLUGIN_ROOT": "/x"}, "argv": [], "cwd": "/"}], {})[0]
      ["env_names_containing_plugin"] == ["CLAUDE_PLUGIN_ROOT"])
check("and it returns empty on an environment carrying no such name, so it is not "
      "matching everything",
      probe.summarise_dumps(
          [{"env": {"PATH": "/x"}, "argv": [], "cwd": "/"}], {})[0]
      ["env_names_containing_plugin"] == [])

# The phase must not conclude what it was written to observe.
root_src = (ROOT / "scripts" / "codex-hook-probe.py").read_text().split(
    "def phase_carrierroot")[1].split("\nOFFLINE_PHASES")[0]
ROOT_CONTROLS_MARKER = "the controls, in the order that makes a zero readable"
check("the phase's control block is findable by the marker this arm splits on",
      root_src.count(ROOT_CONTROLS_MARKER) == 1,
      "found %d" % root_src.count(ROOT_CONTROLS_MARKER))
root_controls = root_src.split(ROOT_CONTROLS_MARKER)[-1]
check("the phase does NOT assert that any candidate reading came back positive",
      not any(("candidate_" in line or "expansion_happened" in line
               or "sentinel_expanded" in line)
              for line in root_controls.splitlines()), root_controls[:300])
check("the phase raises when the config-route control is silent",
      "THE CONFIG-ROUTE CONTROL DID NOT FIRE" in root_src)
check("the phase raises when NO carrier hook ran, since the question is about a "
      "carrier hook specifically",
      "NO CARRIER-REGISTERED HOOK RAN" in root_src)
check("the phase appends to the installer-written enablement rather than replacing it",
      "base + carrier_state_block" in root_src and "wrote no [plugins" in root_src)
check("the phase re-lists after the trust write and compares the REGISTRATION COUNT",
      "changed the REGISTRATION COUNT" in root_src)
check("the phase installs through the vendor's installer rather than hand-placing",
      "install_plugin(installer" in root_src)
check("the phase exports the sentinel into the environment it hands the app-server",
      'env["PROBE_CONTROL_TOKEN"] = ROOT_PROBE_SENTINEL' in root_src)
check("the phase diffs against the environment it actually passed, not os.environ",
      "parent_env = dict(env)" in root_src and "parent_env)" in root_src)

# The pinned answer. It is DOCUMENTATION plus a reported flag, never a raise: the
# assertion could not be exercised inside the slice's one-turn bound, and an assertion
# nobody has watched fail is not a check. These arms pin the shape and the negative.
check("the measured answer is pinned with the build it was taken on",
      probe.ROOT_MEASURED.get("build", "").startswith("codex-cli "),
      str(probe.ROOT_MEASURED.get("build")))
check("the pinned env names are the four observed, sorted",
      probe.ROOT_MEASURED["env_names_injected_on_plugin_route"]
      == ["CLAUDE_PLUGIN_DATA", "CLAUDE_PLUGIN_ROOT", "PLUGIN_DATA", "PLUGIN_ROOT"],
      str(probe.ROOT_MEASURED["env_names_injected_on_plugin_route"]))
check("CODEX_PLUGIN_ROOT is pinned ABSENT, which is the negative a repair must not "
      "build on",
      "CODEX_PLUGIN_ROOT"
      not in probe.ROOT_MEASURED["env_names_injected_on_plugin_route"])
check("the CONFIG route is pinned as receiving none of them, so the repair is scoped "
      "to the plugin carrier",
      probe.ROOT_MEASURED["env_names_injected_on_config_route"] == [])
check("the argument-dropping property is pinned, since it shifts every later index",
      probe.ROOT_MEASURED["unset_name_drops_its_argument"] is True)
check("every pinned key is compared by the phase, so a pin cannot go unread",
      all(("ROOT_MEASURED[\"%s\"]" % k) in root_src
          for k in probe.ROOT_MEASURED if k != "build"),
      str(sorted(probe.ROOT_MEASURED)))
check("the pinned comparison is REPORTED and not raised on",
      "pinned_agreement" not in root_controls, root_controls[:200])

print("\n%d passed, %d failed" % (passed, failed))
if passed == 0:
    print("VACUITY: the suite asserted nothing")
    sys.exit(1)
sys.exit(1 if failed else 0)
