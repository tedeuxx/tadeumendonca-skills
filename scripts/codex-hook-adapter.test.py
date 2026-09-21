#!/usr/bin/env python3
"""Gate for the Codex floor adapter and its carrier.

WHAT A GREEN HERE MEANS, AND IT IS NARROWER THAN IT LOOKS. This suite never starts a
Codex process — no CI runner has one — so nothing here is evidence about the runtime.
It asserts three things:

  1. the TRANSLATION is correct against the LIVE guard, not against a transcript of it.
     Every identity row below is re-derived by piping a payload into
     `hooks/scripts/permission-guard.sh` on this machine, so a change to the guard's
     caller rules reddens here rather than silently changing what Codex is exempted from;
  2. the CARRIER is the shape measured to replace the Claude registry, and is not one of
     the two shapes measured to fail SILENTLY (a wrong `hooks` type falls back to the
     Claude bundle; a missing path registers zero);
  3. the BRANCH POINT is real — both settings of
     `REFUSE_INTERACTIVE_SESSION_STARTUP` are exercised, so the unselected one cannot rot
     into something that no longer works when the owner rules.

WHAT IT CANNOT SEE: whether Codex ever invokes the registered command, whether a
relative path resolves from a plugin carrier, and whether the registration is trusted.
All three are runtime facts and all three are named in `docs/codex-hook-bridge.md`.

Run: python3 scripts/codex-hook-adapter.test.py
"""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ADAPTER = ROOT / "scripts" / "codex-hook-adapter.py"
GUARD = ROOT / "hooks" / "scripts" / "permission-guard.sh"
CARRIER = ROOT / ".codex-plugin" / "plugin.json"
HOOKS = ROOT / "codex-hooks.json"

PASS = 0
FAIL = 0


def ok(msg):
    global PASS
    PASS += 1
    print("PASS  " + msg)


def bad(msg):
    global FAIL
    FAIL += 1
    print("FAIL  " + msg)


def check(cond, msg):
    ok(msg) if cond else bad(msg)


# ── helpers ───────────────────────────────────────────────────────────────────────────

def run_adapter(payload, cwd=None, env=None, source=None):
    """Run the adapter as a subprocess, optionally from a MUTATED copy of its source.

    A mutated copy rather than an import: the branch point is a module constant, and
    re-importing a module to flip a constant tests the import system. Rewriting the
    source and running it is what a reader would do."""
    script = str(source) if source else str(ADAPTER)
    e = dict(os.environ)
    if env:
        e.update(env)
    p = subprocess.run([sys.executable, script],
                       input=json.dumps(payload) if not isinstance(payload, str) else payload,
                       capture_output=True, text=True,
                       cwd=cwd or str(ROOT), env=e)
    return p


def decision_of(p):
    out = (p.stdout or "").strip()
    if not out:
        return None
    try:
        return json.loads(out)
    except ValueError:
        return {"decision": "UNPARSEABLE", "reason": out[:120]}


def guard_verdict(command, caller, cwd=None):
    """The live guard's own verdict, so the identity table below is measured rather than
    copied out of a document."""
    payload = {"hook_event_name": "PreToolUse", "tool_name": "Bash",
               "tool_input": {"command": command}, "cwd": cwd or str(ROOT)}
    if caller is not None:
        payload["agent_type"] = caller
    p = subprocess.run(["bash", str(GUARD)], input=json.dumps(payload),
                       capture_output=True, text=True, cwd=cwd or str(ROOT))
    out = (p.stdout or "").strip()
    if not out:
        return None
    try:
        return json.loads(out)["hookSpecificOutput"]["permissionDecision"]
    except (ValueError, KeyError, TypeError):
        return "UNPARSEABLE"


def codex_payload(command, **extra):
    payload = {"hook_event_name": "PreToolUse", "tool_name": "Bash",
               "tool_input": {"command": command}, "cwd": str(ROOT)}
    payload.update(extra)
    return payload


class MutationTargetMissing(Exception):
    """Raised rather than exiting: a suite that dies before its summary reports no totals,
    which reads differently from a red and hid two failures during this file's own
    mutation calibration."""


def mutated_adapter(work, replacements):
    src = ADAPTER.read_text()
    for old, new in replacements:
        if old not in src:
            raise MutationTargetMissing(old)
        src = src.replace(old, new, 1)
    target = Path(work) / "mutated-adapter.py"
    target.write_text(src)
    return target


# ── 1 · the refusal vocabulary is Codex's, not Claude's ───────────────────────────────
# Measured in bridge section 5: `{"decision":"block","reason":...}` on stdout, exit 0.
# There is no hookSpecificOutput envelope, no permissionDecision key and no exit-code-2
# channel. A Claude-shaped output here would be a hook the runtime ignores.

p = run_adapter(codex_payload("terraform apply"))
d = decision_of(p)
check(p.returncode == 0, "vocabulary — a refusal exits 0 (Codex reads stdout, not the code)")
check(d is not None and d.get("decision") == "block",
      "vocabulary — the verb is `block`" + ("" if d else " (nothing was printed)"))
check(d is not None and isinstance(d.get("reason"), str) and d["reason"].strip(),
      "vocabulary — `reason` is present and non-empty (the runtime errors without it)")
check(d is not None and "hookSpecificOutput" not in d and "permissionDecision" not in d,
      "vocabulary — no Claude envelope leaks through")
check(d is not None and set(d) == {"decision", "reason"},
      "vocabulary — exactly the two measured keys, nothing invented")

# CALIBRATION: the same adapter must be able to say nothing at all, or the four checks
# above are measuring a script that always blocks.
p = run_adapter(codex_payload("ls -la"))
check((p.stdout or "").strip() == "" and p.returncode == 0,
      "vocabulary (calibration) — a permitted act produces NO decision, so `block` is a "
      "real verdict rather than this adapter's only output")

# ── 2 · identity — measured against the live guard, and the hazard is re-derived ──────
# The naive mapping is the safe one. This is asserted by MEASURING both, not by trusting
# the adapter's comment.

OPEN_WORK = ("gh issue create --repo tedeuxx/tadeumendonca-skills "
             "--title x --body-file /dev/null")
POST = "gh pr comment 999999 --repo tedeuxx/tadeumendonca-skills --body-file /dev/null"

absent = guard_verdict(OPEN_WORK, None)
empty = guard_verdict(OPEN_WORK, "")
check(absent is None and empty is None,
      "identity (hazard) — an ABSENT agent_type and an EMPTY one are indistinguishable "
      "to the guard: both ABSTAIN on opening work, so normalising absence to \"\" is the "
      "fail-open move this adapter must not make")

import importlib.util
spec = importlib.util.spec_from_file_location("cha", ADAPTER)
cha = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cha)

sentinel = cha.UNIDENTIFIED_CALLER
check(":" not in sentinel and sentinel.strip(),
      "identity — the sentinel is non-empty and carries NO colon, so it cannot match the "
      "guard's namespaced `<plugin>:<persona>` allowlists")
check(guard_verdict(OPEN_WORK, sentinel) == "deny",
      "identity — the sentinel is DENIED opening work where absence abstains")
check(guard_verdict(POST, sentinel) == "deny",
      "identity — the sentinel is DENIED posting to a public surface")
check(guard_verdict("ls -la", sentinel) is None,
      "identity (calibration) — the sentinel still ABSTAINS on a read, so it is a caller "
      "the guard judges rather than a value that denies everything")

# The bare-name finding: a bare persona name fails CLOSED where the namespaced one is
# exempt. Codex's own value is bare, which is why pass-through is the closed mapping.
check(guard_verdict(POST, "agents-lead") == "deny"
      and guard_verdict(POST, "tadeumendonca-skills:agents-lead") is None,
      "identity — a BARE persona name is denied by 5e while the namespaced form abstains, "
      "so passing Codex's bare value through verbatim fails closed")

# And the mapping itself: what does the adapter actually send?
check(cha.map_caller({}) == sentinel, "identity — a missing key maps to the sentinel")
check(cha.map_caller({"agent_type": ""}) == sentinel,
      "identity — an EMPTY value maps to the sentinel, not to itself")
check(cha.map_caller({"agent_type": None}) == sentinel,
      "identity — a null value maps to the sentinel")
check(cha.map_caller({"agent_type": 7}) == sentinel,
      "identity — a non-string value maps to the sentinel")
check(cha.map_caller({"agent_type": "probe_child"}) == "probe_child",
      "identity — a real child role is passed through VERBATIM, un-namespaced")

# End to end: a Codex parent payload (no agent_type key at all) must be BLOCKED on an act
# that an empty caller would have been allowed.
p = run_adapter(codex_payload(OPEN_WORK))
d = decision_of(p)
check(d is not None and d.get("decision") == "block",
      "identity (end to end) — a payload with NO agent_type key is refused opening work, "
      "which is the exemption an \"\" mapping would have handed the Codex parent thread")

# ── 3 · routes — an untranslated route abstains and says so ───────────────────────────

for tool in cha.UNTRANSLATED_ROUTES:
    p = run_adapter({"hook_event_name": "PreToolUse", "tool_name": tool,
                     "tool_input": {"command": "terraform apply"}, "cwd": str(ROOT)})
    check((p.stdout or "").strip() == "" and "carries no floor" in (p.stderr or ""),
          "routes — %s abstains and NAMES itself on stderr rather than being silently "
          "treated as covered" % tool)

p = run_adapter({"hook_event_name": "SessionStart", "cwd": str(ROOT)})
check((p.stdout or "").strip() == "",
      "routes — a non-PreToolUse event is not answered; the observer half is a later "
      "slice and is not smuggled in by accepting the event silently")

check(cha.SHELL_TOOL == "Bash",
      "routes — the shell route is `Bash`; `shell` matches nothing and would register a "
      "hook that reads as installed and never fires")

# ── 4 · the process cwd is load-bearing and the payload field is not ──────────────────
# The guard resolves a bare `git push`'s branch with `git -C "."`, so the verdict follows
# the PROCESS cwd. The adapter chdirs to the payload's cwd; without that, the trunk rule
# reads whichever tree the host launched the hook from.

with tempfile.TemporaryDirectory() as work:
    trees = {}
    for branch in ("main", "feature"):
        d = Path(work) / branch
        d.mkdir()
        subprocess.run(["git", "init", "-q", str(d)], check=True,
                       capture_output=True)
        subprocess.run(["git", "-C", str(d), "-c", "user.email=a@b", "-c", "user.name=a",
                        "commit", "-q", "--allow-empty", "-m", "init"], check=True,
                       capture_output=True)
        subprocess.run(["git", "-C", str(d), "branch", "-M", branch], check=True,
                       capture_output=True)
        trees[branch] = str(d)

    # Run the adapter FROM the main tree with a payload naming the feature tree.
    p = run_adapter(codex_payload("git push", cwd=trees["feature"]), cwd=trees["main"])
    check((p.stdout or "").strip() == "",
          "cwd — a payload naming a FEATURE tree is not refused even when the adapter "
          "process starts in a trunk checkout: the payload's cwd is what decides")
    # And the converse: a payload naming the trunk IS refused from a feature checkout.
    p = run_adapter(codex_payload("git push", cwd=trees["main"]), cwd=trees["feature"])
    d = decision_of(p)
    check(d is not None and d.get("decision") == "block",
          "cwd — a payload naming the TRUNK is refused even when the adapter process "
          "starts in a feature checkout, which is the direction that would fail OPEN")

    # CALIBRATION: the guard itself follows the process cwd, so the two rows above are a
    # property of the adapter's chdir and not of the guard being cwd-blind.
    check(guard_verdict("git push", None, cwd=trees["main"]) == "deny"
          and guard_verdict("git push", None, cwd=trees["feature"]) is None,
          "cwd (calibration) — the guard's own verdict DOES depend on its process cwd, "
          "so the adapter's chdir is doing the work rather than being decoration")

# ── 5 · failure posture — every degradation abstains, and says so on stderr ───────────

p = run_adapter("{not json")
check((p.stdout or "").strip() == "" and p.returncode == 0 and "NOT judged" in p.stderr,
      "failure — an unparseable payload abstains and says the act was NOT judged")

p = run_adapter("[1,2,3]")
check((p.stdout or "").strip() == "" and "NOT judged" in p.stderr,
      "failure — a payload that is not an object abstains with the same sentence")

with tempfile.TemporaryDirectory() as work:
    src = mutated_adapter(work, [('GUARD = REPO_ROOT / "hooks" / "scripts" / "permission-guard.sh"',
                                  'GUARD = REPO_ROOT / "hooks" / "scripts" / "no-such-guard.sh"')])
    p = run_adapter(codex_payload("terraform apply"), source=src)
    check((p.stdout or "").strip() == "" and "NOT judged" in p.stderr,
          "failure — a MISSING guard fails OPEN with a stderr line, matching the guard's "
          "own general contract rather than wedging the session")

p = run_adapter(codex_payload("terraform apply"), env={"CODEX_HOOK_ADAPTER_TIMEOUT": "0.001"})
check((p.stdout or "").strip() == "" and "did not answer" in p.stderr,
      "failure — a guard that does not answer in time abstains WITH a trace, rather than "
      "being killed by the host and leaving none")

# ── 5b · A MALFORMED TUNABLE IS A CONFIGURATION DEFECT, NOT A CRASH (#455, AC6) ───────
# The read was `float(os.environ.get(...))` at module scope, so a non-numeric value raised
# before `main` was reached: a traceback, exit 1, and NOTHING on stdout — which this
# runtime reports as a hook ERROR rather than as the abstention AC6 names. It failed in
# BOTH modes, `--selfcheck` included, so the one route an operator has to tell an inert
# floor from a holding one was itself the route that crashed.
#
# The three malformed classes are asserted separately because they fail differently, and
# the two that PARSE are the dangerous ones: a non-positive value makes `subprocess.run`
# time out on EVERY call, which is the whole floor off SILENTLY with a value that looks
# deliberate; an infinite one defeats the reason the constant is short in the first place.
for badval, why in (("notanumber", "non-numeric"), ("", "empty"), ("0", "zero"),
                 ("-1", "negative"), ("nan", "NaN"), ("inf", "infinite")):
    p = run_adapter(codex_payload("wc -l README.md"),
                    env={"CODEX_HOOK_ADAPTER_TIMEOUT": badval})
    check(p.returncode == 0 and "Traceback" not in p.stderr
          and (p.stdout or "").strip() == "" and "MIS-SET" in p.stderr,
          "timeout tunable — a %s CODEX_HOOK_ADAPTER_TIMEOUT abstains and reports the "
          "knob as MIS-SET, rather than crashing with a traceback and no decision" % why)

    # Selfcheck mode is asserted separately because the crash was identical in both and a
    # fix landing in only one of them would still read as a fix.
    p = subprocess.run([sys.executable, str(ADAPTER), "--selfcheck"],
                       capture_output=True, text=True, cwd=str(ROOT),
                       env=dict(os.environ, CODEX_HOOK_ADAPTER_TIMEOUT=badval))
    check("Traceback" not in p.stderr and "MIS-SET" in p.stdout,
          "timeout tunable — `--selfcheck` reports a %s value as a MIS-SET note rather "
          "than crashing" % why)
    # It is a NOTE and never a BLOCK: the floor runs at the default, so reporting NOT
    # ACTIVE over a working floor would be a false claim in the alarming direction.
    check("BLOCK: GUARD TIMEOUT" not in p.stdout,
          "timeout tunable — a %s value is a selfcheck NOTE, never a BLOCK, because the "
          "floor still runs at the default" % why)

    # AND THE FLOOR IS STILL CARRIED. The fallback must RUN the guard, not merely avoid
    # crashing — a fix that abstained on everything would pass every arm above.
    p = run_adapter(codex_payload("terraform apply"),
                    env={"CODEX_HOOK_ADAPTER_TIMEOUT": badval})
    d = decision_of(p)
    check(d is not None and d.get("decision") == "block",
          "timeout tunable — under a %s value the floor STILL blocks, so the fallback "
          "runs the guard rather than degrading into a blanket abstention" % why)

# The UNSET control, so "reports MIS-SET" is not a constant: a correctly-set knob and an
# unset one must both be SILENT on stderr, which is what makes the line above a signal.
for good in (None, "2.5"):
    env = {"CODEX_HOOK_ADAPTER_TIMEOUT": good} if good else {}
    p = run_adapter(codex_payload("wc -l README.md"), env=env)
    check("MIS-SET" not in p.stderr,
          "timeout tunable — a %s knob is SILENT on stderr, which is what makes the "
          "mis-set line distinguishable from an unset one"
          % ("valid" if good else "an unset"))

# ── 6 · `ask` becomes a block, because Codex has no prompt rung ───────────────────────
# Unreachable at head — the guard defines ask() and has zero call sites — so it is
# exercised against a STUB guard rather than left untested until the day it fires.

with tempfile.TemporaryDirectory() as work:
    stub = Path(work) / "ask-guard.sh"
    stub.write_text(
        "#!/usr/bin/env bash\n"
        "cat >/dev/null\n"
        "printf '%s' '{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\","
        "\"permissionDecision\":\"ask\",\"permissionDecisionReason\":\"stub asked\"}}'\n")
    src = mutated_adapter(work, [('GUARD = REPO_ROOT / "hooks" / "scripts" / "permission-guard.sh"',
                                  'GUARD = Path(%r)' % str(stub))])
    p = run_adapter(codex_payload("anything"), source=src)
    d = decision_of(p)
    check(d is not None and d.get("decision") == "block" and "no prompt" in d.get("reason", ""),
          "ask — an `ask` verdict becomes a BLOCK, because Codex's measured vocabulary has "
          "one refusal verb and no prompt: an act the floor would not pass unattended must "
          "not pass because the destination harness is missing a rung")

    # And the guard at head really does emit no `ask`, so the branch above is currently
    # unreachable rather than merely untriggered — stated as a fact with its command.
    src_text = GUARD.read_text()
    import re
    ask_calls = len(re.findall(r'(?m)^[^#\n]*(?:^|[^#\w])ask\s+"', src_text))
    deny_calls = len(re.findall(r'(?m)^[^#\n]*(?:^|[^#\w])deny\s+"', src_text))
    check(ask_calls == 0 and deny_calls > 20,
          "ask (reachability) — the guard has %d `ask` call site(s) against %d `deny`, so "
          "the branch above is unreachable at head rather than untested" % (ask_calls, deny_calls))

# ── 7 · the branch point is REAL — both settings are exercised ────────────────────────

check(cha.REFUSE_INTERACTIVE_SESSION_STARTUP is False,
      "branch point — the shipped setting is SHIP-AND-STATE-THE-GAP (False). This "
      "assertion is the tripwire: flipping the constant must be a deliberate edit that "
      "also edits this line and every coverage sentence in the bridge document")

p = run_adapter(codex_payload("bash"))
check((p.stdout or "").strip() == "",
      "branch point (False) — a bare interpreter is PERMITTED, and the write_stdin gap is "
      "therefore open: the hook sees the four characters `bash` and nothing after")

with tempfile.TemporaryDirectory() as work:
    try:
        src = mutated_adapter(work, [("REFUSE_INTERACTIVE_SESSION_STARTUP = False",
                                      "REFUSE_INTERACTIVE_SESSION_STARTUP = True")])
    except MutationTargetMissing:
        src = ADAPTER  # already True; exercise it as shipped rather than skipping
    for cmd, expect_block, why in [
        ("bash", True, "a bare shell opens a session"),
        ("python3", True, "so does a bare REPL"),
        ("/bin/zsh", True, "an absolute path is the same act"),
        ("bash -c 'echo hi'", False, "a command string attaches work"),
        ("python3 script.py", False, "a script argument attaches work"),
        ("python3 -m mod", False, "a module argument attaches work"),
        ("ls -la", False, "an ordinary command is untouched"),
        ("git status", False, "so is an ordinary read"),
    ]:
        p = run_adapter(codex_payload(cmd), source=src)
        got = decision_of(p)
        blocked = got is not None and got.get("decision") == "block"
        check(blocked == expect_block,
              "branch point (True) — %-24r %s (%s)"
              % (cmd, "blocked" if expect_block else "permitted", why))

# ── 8 · the carrier is the shape measured to REPLACE, not either silent-failure shape ──

check(CARRIER.is_file(), "carrier — .codex-plugin/plugin.json exists")
manifest = json.loads(CARRIER.read_text()) if CARRIER.is_file() else {}
check(isinstance(manifest.get("hooks"), str),
      "carrier — `hooks` is a PATH STRING. A wrong TYPE was measured falling back to the "
      "Claude bundle SILENTLY, so the carrier would read as installed and behave as absent")
declared = manifest.get("hooks")
check(HOOKS.is_file() and isinstance(declared, str)
      and declared.lstrip("./") == HOOKS.name,
      "carrier — the declared path RESOLVES. A missing path was measured registering ZERO "
      "hooks, also silently")
check(manifest.get("skills") == "./skills/",
      "carrier — the skill library is declared, or adopting the carrier would silently "
      "drop skill discovery that the Claude manifest was providing")
check(manifest.get("mcpServers") == "./.mcp.json" and (ROOT / ".mcp.json").is_file(),
      "carrier — the canonical MCP source is declared and resolves")

hooks_doc = json.loads(HOOKS.read_text()) if HOOKS.is_file() else {}
regs = hooks_doc.get("hooks", {}).get("PreToolUse", [])
check(len(regs) == 1 and len(regs[0].get("hooks", [])) == 1,
      "carrier — exactly one registration; this slice ships the floor and no observer")
check("matcher" not in regs[0] if regs else False,
      "carrier — NO matcher. `shell` matches nothing and an absent matcher observes every "
      "route, so dispatch happens in the adapter where a wrong value is a visible branch")
cmd = regs[0]["hooks"][0]["command"] if regs else ""
check(ADAPTER.name in cmd and cmd.startswith("python3 "),
      "carrier — the command names the adapter through an explicit interpreter, so the "
      "exec bit is not load-bearing")
check(set(regs[0]["hooks"][0]) == {"type", "command"} if regs else False,
      "carrier — only the two keys the probe fixture registered with. An unrecognised key "
      "risks a parse this repository has already measured failing SILENTLY")

events = set(hooks_doc.get("hooks", {}))
CODEX_EVENTS = {"Interrupt", "PermissionRequest", "PostCompact", "PostToolUse",
                "PreCompact", "PreToolUse", "SessionEnd", "SessionStart", "Stop",
                "SubagentStart", "SubagentStop", "UserPromptSubmit"}
check(events and events <= CODEX_EVENTS,
      "carrier — every event registered is in Codex's own PascalCase vocabulary; the "
      "snake_case trust-key spelling registers ZERO hooks and prints nothing to stderr")

# Version lockstep with the release wiring.
bump = (ROOT / ".bumpversion.toml").read_text()
check('filename = ".codex-plugin/plugin.json"' in bump,
      "carrier — the manifest is on bumpversion's file list, or a release leaves the "
      "Codex package advertising a version that no longer exists")
check(manifest.get("version") == (ROOT / "VERSION").read_text().strip(),
      "carrier — the manifest version matches VERSION")

# ── 9 · selfcheck reports rather than controls ────────────────────────────────────────

p = subprocess.run([sys.executable, str(ADAPTER), "--selfcheck"],
                   capture_output=True, text=True, cwd=str(ROOT))
check(p.returncode == 0, "selfcheck — passes on a complete checkout")
for needle, why in [
    ("TRUST IS NOT CHECKED HERE", "it says it cannot see trust"),
    ("COVERAGE:", "it states the route limit"),
    ("CALLER:", "it states that no caller is exempt"),
    ("INTERACTIVE SESSION STARTUP:", "it states which branch is in force"),
    # Added 2026-09-16. This was the only note of the set left unpinned, which made it
    # the one a later edit could delete in silence — and it is the note carrying the
    # single most misreadable fact about this bridge: that a green here is not evidence
    # the hook ever fires. What this arm asserts is that the sentence is PRESENT. It
    # cannot assert the sentence is true, and no arm here could: firing is a property of
    # a runtime this suite never starts.
    ("FIRING IS UNPROVEN", "it states that firing is unproven, which is this bridge's"
                           " most misreadable fact"),
]:
    check(needle in p.stdout, "selfcheck — %s" % why)
check("does not say a hook FIRED" in p.stdout,
      "selfcheck — a green explicitly refuses to be read as evidence that a hook ran")

# ── 10 · the documentation carries the two sentences a reader must not miss ───────────

bridge = (ROOT / "docs" / "codex-hook-bridge.md").read_text()
check("the model's tool calls" in bridge.lower(),
      "docs — the bridge states coverage as the MODEL's tool calls rather than 'the shell'")
check("REFUSE_INTERACTIVE_SESSION_STARTUP" in bridge,
      "docs — the branch point is named in the document, not only in the source")
check("codex-unidentified" in bridge,
      "docs — the sentinel is published, so the operational restriction it creates is "
      "findable by someone reading the document rather than the code")

print()
print("%d passed, %d failed" % (PASS, FAIL))
sys.exit(1 if FAIL else 0)
