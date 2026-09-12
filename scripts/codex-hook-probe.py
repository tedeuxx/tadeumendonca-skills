#!/usr/bin/env python3
# purpose: Measure the native Codex hook seam — carrier precedence, the trust mechanism and
# which runtime routes fire a PreToolUse hook — so an adapter is written against observed
# payloads rather than against an assumed schema.
"""Opt-in native Codex hook-seam probe.

This is an INSTRUMENT, not a control. It refuses nothing, gates nothing and changes no
enforcement. Every expectation it checks is pinned in this file and every failure exits
nonzero, so a silent pass over an empty set is not reachable.

It never reads a credential, never starts a model turn, and never writes to the invoking
user's real Codex home. Every phase builds its own disposable CODEX_HOME and fixture tree
in a new temporary directory and leaves the artifacts there for inspection.

WHAT A GREEN RUN DOES NOT MEAN. It does not mean a hook executed against a model tool
call, that a decision blocked an act, or that any caller identity was authenticated. The
`routes` phase measures the opposite — see `docs/codex-hook-bridge.md`.

Python 3.9 or newer. Usage:

    python3 scripts/codex-hook-probe.py <codex-executable> [--phase carrier|trust|routes|all]
"""

import argparse
import json
import os
import queue
import shutil
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path

# ---------------------------------------------------------------------------
# Pinned expectations. Each was measured on codex-cli 0.151.0-alpha.7.2; the
# probe exists so that a later build re-runs them instead of inheriting them.
# ---------------------------------------------------------------------------

# Carrier precedence: how many registrations the loader reports for each fixture,
# expressed relative to the Claude set so the numbers do not rot when hooks.json grows.
CARRIER_EXPECTATIONS = {
    # A plugin with no .codex-plugin manifest at all falls back to the Claude bundle.
    "claude-only": "claude",
    # A valid manifest declaring a hooks path REPLACES the Claude set entirely.
    "codex-path": "codex",
    # A manifest naming a file that is not there registers NOTHING, silently.
    "codex-missing-file": "none",
    # A manifest whose `hooks` value is the wrong TYPE falls back to the Claude
    # bundle. This is the hazard the carrier exists to avoid: malformed metadata
    # does not fail closed, it resurrects the set it was meant to replace.
    "codex-invalid-type": "claude",
    # A manifest with no `hooks` key at all falls back the same way.
    "codex-no-hooks-key": "claude",
}

# The canonical event names the runtime's own `HooksToml` struct accepts. Read out of
# `config/read`, not out of documentation. The trust-state key normalises these to
# snake_case, which is NOT the config spelling — writing the key form into a config
# registers zero hooks and prints nothing to stderr.
CODEX_HOOK_EVENTS = [
    "Interrupt", "PermissionRequest", "PostCompact", "PostToolUse", "PreCompact",
    "PreToolUse", "SessionEnd", "SessionStart", "Stop", "SubagentStart",
    "SubagentStop", "UserPromptSubmit",
]

CODEX_HOOKS_FIXTURE = {
    "hooks": {
        "PreToolUse": [
            {"matcher": "shell",
             "hooks": [{"type": "command", "command": "python3 scripts/probe-adapter.py"}]}
        ]
    }
}


class Failure(Exception):
    """An expectation did not hold. Always exits nonzero."""


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + "\n")


class AppServer:
    """A JSON-RPC session against `codex app-server --stdio`."""

    def __init__(self, binary, cwd, env, stderr_path):
        self._messages = queue.Queue()
        self._ident = 0
        self._stderr_path = stderr_path
        self._handle = stderr_path.open("w")
        self._proc = subprocess.Popen(
            [binary, "app-server", "--stdio"], cwd=str(cwd), env=env,
            stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=self._handle, text=True)
        threading.Thread(target=self._read, daemon=True).start()

    def _read(self):
        try:
            for line in self._proc.stdout:
                try:
                    self._messages.put(json.loads(line))
                except ValueError:
                    pass
        finally:
            self._messages.put(None)

    def call(self, method, params=None, timeout=45):
        self._ident += 1
        ident = self._ident
        payload = {"id": ident, "method": method, "params": params or {}}
        try:
            self._proc.stdin.write(json.dumps(payload) + "\n")
            self._proc.stdin.flush()
        except Exception as exc:
            raise Failure("could not write %s: %s" % (method, exc))
        deadline = time.time() + timeout
        while time.time() < deadline:
            try:
                message = self._messages.get(timeout=max(1, deadline - time.time()))
            except Exception:
                break
            if message is None:
                raise Failure("app-server exited during %s; see %s"
                              % (method, self._stderr_path))
            if message.get("id") == ident:
                if "error" in message:
                    return {"__error__": message["error"]}
                return message["result"]
        raise Failure("timeout waiting for %s" % method)

    def initialize(self):
        return self.call("initialize", {
            "clientInfo": {"name": "codex-hook-probe", "version": "1.0"},
            "capabilities": {"experimentalApi": True}})

    def close(self):
        self._proc.terminate()
        try:
            self._proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            self._proc.kill()
            self._proc.wait()
        self._handle.close()


def disposable_env(home):
    env = dict(os.environ)
    env["CODEX_HOME"] = str(home)
    # A credential must not travel into a disposable home by accident.
    env.pop("OPENAI_API_KEY", None)
    return env


# ---------------------------------------------------------------------------
# Phase: carrier
# ---------------------------------------------------------------------------

def build_carrier_fixture(work, case, claude_hooks):
    name = "codexhookprobe"
    root = work / case / name
    root.mkdir(parents=True)
    write_json(root / ".claude-plugin/plugin.json", {
        "name": name, "version": "0.0.1",
        "description": "Probe fixture. Not a distributable plugin.",
        "hooks": "./hooks/hooks.json"})
    write_json(root / "hooks/hooks.json", claude_hooks)
    (root / "scripts").mkdir(parents=True, exist_ok=True)
    (root / "scripts/probe-adapter.py").write_text("# probe fixture\n")
    (root / "skills/probeskill").mkdir(parents=True, exist_ok=True)
    (root / "skills/probeskill/SKILL.md").write_text(
        "---\nname: probeskill\ndescription: Use when probing the carrier seam.\n---\n"
        "Fixture body.\n")

    manifest = {"name": name, "version": "0.0.1", "description": "Probe fixture.",
                "skills": "./skills/"}
    if case == "claude-only":
        manifest = None
    elif case == "codex-path":
        write_json(root / "codex-hooks.json", CODEX_HOOKS_FIXTURE)
        manifest["hooks"] = "./codex-hooks.json"
    elif case == "codex-missing-file":
        manifest["hooks"] = "./codex-hooks-absent.json"
    elif case == "codex-invalid-type":
        write_json(root / "codex-hooks.json", CODEX_HOOKS_FIXTURE)
        manifest["hooks"] = 37
    elif case == "codex-no-hooks-key":
        write_json(root / "codex-hooks.json", CODEX_HOOKS_FIXTURE)
    else:
        raise Failure("unknown carrier case %r" % case)
    if manifest is not None:
        write_json(root / ".codex-plugin/plugin.json", manifest)

    write_json(work / case / ".claude-plugin/marketplace.json", {
        "name": "codexhookprobe-" + case, "owner": {"name": "Probe"},
        "plugins": [{"name": name, "source": "./" + name}]})
    return work / case / ".claude-plugin/marketplace.json", name


def phase_carrier(binary, work, repo, report):
    claude_hooks = json.loads((repo / "hooks/hooks.json").read_text())
    claude_count = sum(len(entry["hooks"])
                       for group in claude_hooks["hooks"].values()
                       for entry in group)
    if claude_count == 0:
        raise Failure("the repository's hooks.json declares no registrations; "
                      "the carrier comparison would be vacuous")
    codex_count = sum(len(entry["hooks"])
                      for group in CODEX_HOOKS_FIXTURE["hooks"].values()
                      for entry in group)
    if codex_count == 0 or codex_count == claude_count:
        raise Failure("the codex fixture must be nonempty and must differ in size "
                      "from the Claude set, or replacement is indistinguishable "
                      "from fallback")
    expected_counts = {"claude": claude_count, "codex": codex_count, "none": 0}

    home = work / "carrier-home"
    home.mkdir()
    neutral = work / "carrier-neutral"
    neutral.mkdir()
    server = AppServer(binary, neutral, disposable_env(home),
                       work / "carrier.stderr")
    observed = {}
    try:
        server.initialize()
        for case, expectation in CARRIER_EXPECTATIONS.items():
            market, name = build_carrier_fixture(work, case, claude_hooks)
            result = server.call("plugin/read", {"marketplacePath": str(market),
                                                 "pluginName": name})
            if "__error__" in result:
                raise Failure("plugin/read failed for %s: %s"
                              % (case, result["__error__"]))
            detail = result["plugin"]
            hooks = detail.get("hooks") or []
            skills = sorted(s["name"] for s in detail.get("skills") or [])
            if not skills:
                raise Failure("case %s resolved no skills; the fixture is broken and "
                              "its hook count cannot be trusted" % case)
            observed[case] = {"registrations": len(hooks),
                              "expected": expectation,
                              "expected_count": expected_counts[expectation],
                              "skills": skills}
    finally:
        server.close()

    report["carrier"] = {"claude_registrations": claude_count,
                         "codex_fixture_registrations": codex_count,
                         "cases": observed}
    problems = [c for c, v in observed.items()
                if v["registrations"] != v["expected_count"]]
    if problems:
        raise Failure("carrier precedence changed for: %s" % ", ".join(sorted(problems)))
    # Calibration: the three expectation classes must not have collapsed onto one number.
    distinct = {v["expected_count"] for v in observed.values()}
    if len(distinct) < 3:
        raise Failure("the three carrier outcomes are no longer distinguishable by "
                      "count; this check can no longer fail")


# ---------------------------------------------------------------------------
# Phase: trust
# ---------------------------------------------------------------------------

def trust_config(project, recorder, extra=""):
    return ("[projects.\"" + str(project) + "\"]\n"
            "trust_level = \"trusted\"\n"
            "\n"
            "[[hooks.PreToolUse]]\n"
            "\n"
            "[[hooks.PreToolUse.hooks]]\n"
            "type = \"command\"\n"
            "command = \"" + str(recorder) + "\"\n" + extra)


def make_recorder(work, capture):
    recorder = work / "recorder.sh"
    recorder.write_text(
        "#!/bin/bash\n"
        "d=" + str(capture) + "\n"
        "n=$(ls \"$d\" 2>/dev/null | wc -l | tr -d ' ')\n"
        "cat > \"$d/payload-$n.json\"\n"
        "exit 0\n")
    recorder.chmod(0o755)
    return recorder


def list_hooks(binary, home, project, stderr_path):
    server = AppServer(binary, project, disposable_env(home), stderr_path)
    try:
        server.initialize()
        result = server.call("hooks/list")
        records = []
        for entry in (result or {}).get("data", []):
            records.extend(entry.get("hooks", []))
        return records
    finally:
        server.close()


def phase_trust(binary, work, report):
    home = work / "trust-home"
    home.mkdir()
    project = work / "trust-project"
    project.mkdir()
    capture = work / "trust-capture"
    capture.mkdir()
    recorder = make_recorder(work, capture)
    config = home / "config.toml"

    config.write_text(trust_config(project, recorder))
    before = list_hooks(binary, home, project, work / "trust-a.stderr")
    if len(before) != 1:
        raise Failure("expected exactly one registration from the fixture config, "
                      "got %d; the accepted schema may have changed" % len(before))
    record = before[0]
    key, current = record["key"], record["currentHash"]
    if record["trustStatus"] != "untrusted":
        raise Failure("a freshly declared hook was not untrusted; trust may no "
                      "longer default closed")
    if not current or not current.startswith("sha256:"):
        raise Failure("no currentHash on the registration; the trust mechanism moved")

    # Write the matching trusted_hash into the DISPOSABLE home only. This measures the
    # mechanism; it is explicitly not a way to satisfy any acceptance requirement about
    # trust, and it never touches the invoking user's real Codex home.
    config.write_text(trust_config(project, recorder,
                                   "\n[hooks.state.\"" + key + "\"]\n"
                                   "trusted_hash = \"" + current + "\"\n"))
    after = list_hooks(binary, home, project, work / "trust-b.stderr")
    if len(after) != 1 or after[0]["trustStatus"] != "trusted":
        raise Failure("a matching trusted_hash did not move the registration to "
                      "trusted; the trust mechanism moved")

    # Negative control: a WRONG hash must not confer trust, or the check above is
    # measuring the presence of the key rather than the match.
    config.write_text(trust_config(project, recorder,
                                   "\n[hooks.state.\"" + key + "\"]\n"
                                   "trusted_hash = \"sha256:" + ("0" * 64) + "\"\n"))
    wrong = list_hooks(binary, home, project, work / "trust-c.stderr")
    if len(wrong) != 1 or wrong[0]["trustStatus"] == "trusted":
        raise Failure("a non-matching trusted_hash conferred trust; the hash is not "
                      "being compared")

    # Trust is FILE STATE, not an authenticated human action. Anything that can write
    # the user's config.toml can grant it — including the app-server's own
    # `config/value/write`. Measured rather than assumed, because the opposite
    # assumption (trust is a human hold) is the one a bridge design would lean on.
    config.write_text(trust_config(project, recorder))
    server = AppServer(binary, project, disposable_env(home), work / "trust-d.stderr")
    try:
        server.initialize()
        listed = server.call("hooks/list")
        record = listed["data"][0]["hooks"][0]
        if record["trustStatus"] != "untrusted":
            raise Failure("the self-trust arm needs an untrusted starting state")
        written = server.call("config/value/write", {
            "keyPath": "hooks.state",
            "value": {record["key"]: {"trusted_hash": record["currentHash"]}},
            "mergeStrategy": "replace"})
        api_granted = isinstance(written, dict) and written.get("status") == "ok"
        after = server.call("hooks/list")["data"][0]["hooks"][0]["trustStatus"]
    finally:
        server.close()

    report["trust"] = {"key": key, "current_hash": current,
                       "untrusted_by_default": True,
                       "matching_hash_trusts": True,
                       "wrong_hash_rejected": wrong[0]["trustStatus"],
                       "api_write_accepted": api_granted,
                       "trust_after_api_write": after,
                       "finding": ("trust is file state: config/value/write grants it "
                                   "with no human action"
                                   if after == "trusted" else
                                   "config/value/write did NOT grant trust — the "
                                   "recorded finding has changed")}
    if not api_granted or after != "trusted":
        raise Failure("config/value/write no longer grants hook trust (status=%r, "
                      "trustStatus=%r); docs/codex-hook-bridge.md section 2 records "
                      "that it does and must be corrected"
                      % (written, after))


# ---------------------------------------------------------------------------
# Phase: routes
# ---------------------------------------------------------------------------

def phase_routes(binary, work, report):
    home = work / "routes-home"
    home.mkdir()
    project = work / "routes-project"
    project.mkdir()
    capture = work / "routes-capture"
    capture.mkdir()
    recorder = make_recorder(work, capture)
    config = home / "config.toml"

    config.write_text(trust_config(project, recorder))
    records = list_hooks(binary, home, project, work / "routes-a.stderr")
    if len(records) != 1:
        raise Failure("expected one registration, got %d" % len(records))
    key, current = records[0]["key"], records[0]["currentHash"]
    config.write_text(trust_config(project, recorder,
                                   "\n[hooks.state.\"" + key + "\"]\n"
                                   "trusted_hash = \"" + current + "\"\n"))

    server = AppServer(binary, project, disposable_env(home), work / "routes-b.stderr")
    cases = []
    try:
        server.initialize()
        listed = server.call("hooks/list")
        trust = listed["data"][0]["hooks"][0]["trustStatus"]
        if trust != "trusted":
            raise Failure("the route phase needs a trusted hook; got %r" % trust)
        # Both commands are pure reads that succeed under the runtime sandbox. A
        # sandbox-refused command would make a zero payload count meaningless.
        for name, command in (("echo", ["/bin/echo", "codex-hook-probe"]),
                              ("read", ["/bin/sh", "-c", "ls / | head -1"])):
            before = len(list(capture.glob("payload-*")))
            result = server.call("command/exec",
                                 {"command": command, "cwd": str(work)})
            time.sleep(1)
            cases.append({
                "route": "command/exec",
                "case": name,
                "exit_code": result.get("exitCode") if isinstance(result, dict) else None,
                "stdout": (result.get("stdout") or "")[:40] if isinstance(result, dict) else "",
                "hook_invocations": len(list(capture.glob("payload-*"))) - before})
    finally:
        server.close()

    succeeded = [c for c in cases if c["exit_code"] == 0]
    if not succeeded:
        raise Failure("no command/exec case succeeded, so a zero hook-invocation "
                      "count cannot distinguish an unobserved route from an act "
                      "that never happened")
    fired = sum(c["hook_invocations"] for c in cases)
    report["routes"] = {"trusted": True, "cases": cases,
                        "succeeding_cases": len(succeeded),
                        "total_hook_invocations": fired,
                        "finding": ("command/exec does not fire a trusted PreToolUse "
                                    "hook" if fired == 0 else
                                    "command/exec DOES fire a PreToolUse hook — this "
                                    "reverses the recorded finding")}
    if fired != 0:
        raise Failure("command/exec fired %d hook invocation(s); the recorded finding "
                      "that this route is unobserved no longer holds, and "
                      "docs/codex-hook-bridge.md must be corrected" % fired)


PHASES = {"carrier": phase_carrier, "trust": phase_trust, "routes": phase_routes}


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("binary", help="installed Codex executable (path or name on PATH)")
    parser.add_argument("--phase", choices=sorted(PHASES) + ["all"], default="all")
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parent.parent,
                        help="library checkout supplying hooks/hooks.json")
    args = parser.parse_args()

    binary = shutil.which(args.binary) or str(Path(args.binary).resolve())
    if not Path(binary).exists():
        print("codex executable not found: %s" % args.binary, file=sys.stderr)
        return 2
    version = subprocess.check_output([binary, "--version"], text=True).strip()
    work = Path(tempfile.mkdtemp(prefix="codex-hook-probe-"))
    report = {"executable": binary, "version": version, "artifacts": str(work),
              "repo": str(args.repo.resolve()),
              "codex_hook_events": CODEX_HOOK_EVENTS}

    selected = sorted(PHASES) if args.phase == "all" else [args.phase]
    status = 0
    try:
        for phase in selected:
            if phase == "carrier":
                PHASES[phase](binary, work, args.repo.resolve(), report)
            else:
                PHASES[phase](binary, work, report)
        report["result"] = "PASS"
    except Failure as exc:
        report["result"] = "FAIL"
        report["failure"] = str(exc)
        status = 1
    print(json.dumps(report, indent=2))
    if status:
        print("\nFAIL: %s" % report["failure"], file=sys.stderr)
    return status


if __name__ == "__main__":
    sys.exit(main())
