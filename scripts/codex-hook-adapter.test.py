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

# ── 11 · the invocation log — the only thing that can attribute a non-firing hook ─────
#
# Every arm here is run against the LIVE adapter as a subprocess, because the question
# the log answers is about a process the runtime starts, not about an importable
# function. The three states it exists to separate are "never called", "called and the
# process died" and "called and the decision was discarded"; the arms below pin that a
# record is written on each of the reachable paths.

with tempfile.TemporaryDirectory() as work:
    logdir = Path(work) / "logs"
    blocked = logdir / "blocked.jsonl"
    p = run_adapter(codex_payload("gh pr merge 999999 --merge"),
                    env={"CODEX_HOOK_ADAPTER_LOG": str(blocked)})
    check(decision_of(p) is not None and decision_of(p)["decision"] == "block",
          "log — a blocked act still produces its decision")
    check(blocked.exists(), "log — the destination's parent directory is created")
    entries = [json.loads(l) for l in blocked.read_text().splitlines() if l.strip()]
    check(len(entries) == 1, "log — exactly one record per invocation")
    e = entries[0] if entries else {}
    check(e.get("outcome") == "block", "log — the record carries the DECISION, which is "
                                       "what makes a discarded one attributable")
    check(e.get("command") == "gh pr merge 999999 --merge",
          "log — the record carries the command the decision was about")
    check(e.get("agent_type_sent") == "codex-unidentified",
          "log — the record carries the identity actually SENT to the guard, not the raw "
          "payload value, since the mapping is the part that inverts intuition")
    check("process_cwd" in e and "payload_cwd" in e,
          "log — BOTH working directories are recorded; the guard follows the process "
          "one and the relative-command defect this bridge carries is about the other")
    check(e.get("schema") == 1, "log — records are versioned")

    # The abstaining path. A floor that only logs its refusals cannot tell "it ran and
    # said nothing" from "it never ran", which is half the question.
    quiet = logdir / "quiet.jsonl"
    p = run_adapter(codex_payload("ls -la"),
                    env={"CODEX_HOOK_ADAPTER_LOG": str(quiet)})
    check(decision_of(p) is None, "log — an abstention still emits no decision")
    q = ([json.loads(l) for l in quiet.read_text().splitlines() if l.strip()]
         if quiet.exists() else [])
    # `quiet.exists()` rather than an unguarded read, and `len(q) == 1 and …` rather
    # than `q[0]…`: a mutation that made the log skip abstentions crashed this arm with
    # an IndexError, and the suite died BEFORE its summary — which reports as neither a
    # pass nor a fail. An assertion that cannot survive the defect it is aimed at does
    # not catch it; it hides it behind a traceback.
    check(len(q) == 1 and q[0].get("outcome") is None,
          "log — an ABSTENTION is recorded too, with a null outcome, since a floor that "
          "logs only its refusals cannot tell 'it ran and said nothing' from 'it never ran'")

    # A payload that does not parse is the case most likely to be mistaken for a hook
    # that never ran, so it is the case that most needs a record.
    junk = logdir / "junk.jsonl"
    p = run_adapter("this is not json", env={"CODEX_HOOK_ADAPTER_LOG": str(junk)})
    j = [json.loads(l) for l in junk.read_text().splitlines() if l.strip()]
    check(len(j) == 1 and j[0].get("unparsed_stdin_bytes") == len("this is not json"),
          "log — an UNPARSEABLE payload is recorded, which is the case most easily "
          "mistaken for a hook that was never invoked")

    # OFF by default. This adapter sits on the one route that sees every shell act, so a
    # default-on log would make the floor a transcript as a side effect of being a floor.
    #
    # THE SUBJECT IS A PRISTINE COPY, and getting there took two wrong arms.
    #
    #   first form: assert a file whose name this arm invented is absent. True of every
    #               default anyone could ship, so a mutation adding a fixed default
    #               destination passed it untouched — a green that could not be red.
    #   second form: diff the whole tree before and after. Sound in principle and
    #               VACUOUS HERE, because arms earlier in this same file already run the
    #               adapter with no log configured, so under that mutation the default
    #               file existed before the snapshot was taken.
    #
    # So the subject is a COPY at a path nothing has touched, and the diff is over that
    # path alone. Anything a default-on log writes lands beside it and is visible.
    pristine = Path(work) / "pristine" / "scripts"
    pristine.mkdir(parents=True)
    copy = pristine / ADAPTER.name
    copy.write_text(ADAPTER.read_text())
    root_of_copy = pristine.parent
    before = {p for p in root_of_copy.rglob("*") if p.is_file()}
    run_adapter(codex_payload("ls"), cwd=work, source=copy)
    run_adapter(codex_payload("gh pr merge 999999 --merge"), cwd=work, source=copy)
    appeared = sorted(str(p) for p in root_of_copy.rglob("*")
                      if p.is_file() and p not in before)
    check(not appeared,
          "log — OFF unless an operator names a destination: two invocations, one "
          "abstaining and one blocking, write no file beside the adapter")
    if appeared:
        print("      appeared: %s" % appeared[:4])

    # AND THE PROPERTY ITSELF, because the behavioural arm above watches ONE directory.
    # A mutation defaulting to an absolute path elsewhere — `/tmp/...` — slips past it
    # entirely, and widening the watch to every directory a default could name is not a
    # thing a check can do. `log_target()` returning None with the variable unset is the
    # property, and it holds for every destination at once.
    probe_src = (
        "import importlib.util, sys\n"
        "s = importlib.util.spec_from_file_location('a', %r)\n"
        "m = importlib.util.module_from_spec(s); s.loader.exec_module(m)\n"
        "print('TARGET=%%r' %% (m.log_target(),))\n" % str(ADAPTER))
    e = dict(os.environ)
    e.pop("CODEX_HOOK_ADAPTER_LOG", None)
    r = subprocess.run([sys.executable, "-c", probe_src], capture_output=True,
                       text=True, cwd=work, env=e)
    check("TARGET=None" in (r.stdout or ""),
          "log — and the PROPERTY, destination-independently: log_target() is None when "
          "the variable is unset, so no default anywhere can satisfy this suite")

    # A RELATIVE path is the defect this bridge already carries one layer down, so it is
    # refused rather than resolved against whatever tree the session happened to open.
    #
    # RUN FROM A TEMPORARY CWD, not from the repo root. The first form of this arm ran
    # the adapter from ROOT, so a mutation that made the path resolve left `rel.jsonl`
    # IN THE TRACKED TREE — and the file then reddened this same arm on the next clean
    # run, which reads as a source defect and is leftover state. A check whose failure
    # mode is to dirty the thing it checks is not a check.
    p = run_adapter(codex_payload("ls"), cwd=work,
                    env={"CODEX_HOOK_ADAPTER_LOG": "rel.jsonl"})
    check(not any(Path(work).rglob("rel.jsonl")) and not (ROOT / "rel.jsonl").exists(),
          "log — a RELATIVE destination writes nothing, anywhere")
    check("not an absolute path" in (p.stderr or ""),
          "log — and says on stderr why, rather than failing silently")

    # A logging failure must never change a verdict. The destination is made unwritable
    # by pointing it at a path whose parent is a FILE, which no mkdir can create.
    wall = Path(work) / "wall"
    wall.write_text("not a directory")
    p = run_adapter(codex_payload("gh pr merge 999999 --merge"),
                    env={"CODEX_HOOK_ADAPTER_LOG": str(wall / "nope.jsonl")})
    d = decision_of(p)
    check(d is not None and d["decision"] == "block" and p.returncode == 0,
          "log — AN UNWRITABLE DESTINATION DOES NOT CHANGE THE DECISION; the floor's job "
          "is the verdict and a floor that stops judging because it could not append a "
          "line is worse than one with no log at all")
    # THE EXIT CODE IS PART OF THAT CLAIM AND WAS NOT CHECKED. A mutation that let the
    # write's exception reach the caller left the decision on stdout — it had already
    # been written — and exited 1, which this runtime reports as a HOOK ERROR rather
    # than as a decision. "The verdict is unaffected" is false of a process that dies
    # after producing it, and the arm above said it was true.
    check(p.returncode == 0,
          "log — and exits 0, since Codex's refusal contract is a decision on stdout "
          "WITH exit 0 and a nonzero exit is reported as a hook error instead")
    check("could not write the invocation log" in (p.stderr or ""),
          "log — and the failure is announced on stderr")

# ── 12 · AC7 — the three convenience refusals are NOT forwarded, the floor is ──────────
#
# Measured on codex-cli 0.151.0-alpha.7.2 (`codex-hook-probe.py --phase friction`): a
# command substitution, an env-var prefix and a stdout redirect ALL COMPLETED under a
# permission layer that was demonstrably in force, so the subset those rules must fire
# inside is EMPTY on that runtime. These arms assert the adapter acts on that and, more
# importantly, that acting on it did not reach anything irreversible.

CONVENIENCE = [
    ("echo $(date)", "command substitution"),
    ("FOO=1 ls", "an env-var prefix"),
    ("ls > out.txt", "a stdout redirect"),
]
FLOOR = [
    ("terraform apply", "terraform apply"),
    ("git push origin main", "a trunk push"),
    ("rm -rf /tmp/anything", "a recursive force delete"),
    ("gh secret set FOO", "a secret write"),
]

for command, label in CONVENIENCE:
    # The guard on its own still denies: the rule is not deleted, it is not ASKED FOR.
    check(guard_verdict(command, None) == "deny",
          "AC7 — the guard itself still denies %s on the Claude path (unchanged)" % label)
    check(decision_of(run_adapter(codex_payload(command))) is None,
          "AC7 — the ADAPTER does not forward the refusal for %s" % label)

for command, label in FLOOR:
    d = decision_of(run_adapter(codex_payload(command)))
    check(d is not None and d["decision"] == "block",
          "AC7 — %s is still BLOCKED; narrowing the friction reached no floor rule"
          % label)

# The calibration for the whole section: the switch must be able to change an answer, or
# the seven arms above are a green that could not have been red.
import subprocess as _sp
_env_on = dict(os.environ); _env_on["PERMISSION_GUARD_CONVENIENCE_RULES"] = "on"
_p = _sp.run(["bash", str(GUARD)],
             input=json.dumps(codex_payload("echo $(date)")),
             capture_output=True, text=True, cwd=str(ROOT), env=_env_on)
check((_p.stdout or "").strip() != "",
      "AC7 — calibration: with the variable set to 'on' the guard answers, so the "
      "abstentions above are the switch acting rather than a dead selector")

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
    # Was pinned as the literal "FIRING IS UNPROVEN" until 2026-09-21, when a native turn
    # on 0.151 measured the hook firing and blocking. The note is REWRITTEN rather than
    # dropped, and the arm follows it: what a reader must not be able to take from this
    # check is a single-valued answer in EITHER direction, because the two native runs
    # disagree and differ in two variables at once.
    ("FIRING DEPENDS ON THE BUILD AND ON THE REGISTRATION ROUTE",
     "it refuses a single-valued firing claim in either direction"),
    ("0.151.0-alpha.7.2", "it names the build the affirmative reading came from"),
    ("0.154.0-alpha.6.2", "and the build the negative reading came from, since a "
                          "measurement without its build is not reproducible"),
    ("carrier's OWN route is still unproven", "it keeps the carrier's route open, which "
                                              "is the limb the affirmative run did not test"),
    ("INVOCATION LOG", "it names the invocation log and its state, which is the only "
                       "route an operator has to the firing question"),
    ("TUNABLES THAT CAN AFFECT THIS FLOOR", "it enumerates the knobs, because an unset "
                                            "one is otherwise invisible"),
    ("CONVENIENCE REFUSALS ARE NOT FORWARDED", "it states the AC7 narrowing, with the "
                                               "evidence and the date"),
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
