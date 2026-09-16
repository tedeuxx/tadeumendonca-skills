#!/usr/bin/env python3
# purpose: carry the irreversible floor onto Codex by translating its native PreToolUse payload into the authoritative guard's and its verdict back into Codex's own refusal verb, so the floor is authored once rather than re-declared per harness
"""The Codex side of the permission floor. A TRANSLATOR, never a second policy.

`hooks/scripts/permission-guard.sh` stays the only authored floor in this repository.
This file does four things and deliberately nothing else:

  1. reads a native Codex `PreToolUse` payload on stdin;
  2. decides whether the route is one the floor can speak about at all;
  3. maps the CALLER, which is the part that inverts intuition — see IDENTITY below;
  4. runs the guard and translates its verdict into Codex's own vocabulary.

There is no rule here. A rule added here would be a second floor that drifts from the
first with nothing watching, which is the failure this repository names most often.

── WHAT THIS DOES NOT COVER, AND IT IS STRUCTURAL ────────────────────────────────────
A `PreToolUse` hook observes tool calls the MODEL makes inside a turn and nothing else.
`command/exec`, `process/spawn` and `thread/shellCommand` each fired ZERO hooks against
a trusted registration, all three succeeding — measured, `docs/codex-hook-bridge.md`
section 3. So a host feature, an IDE terminal or any caller of the app-server passes no
hook at all. **"The shell is guarded" is false on this runtime**, and every sentence
about coverage anywhere must say *the model's tool calls* instead.

The second gap is `write_stdin`: a model that opens a bare interpreter and feeds it
lines afterwards is observed ONCE, carrying the four-character string `bash`, and the
later input is invisible to the hook layer AND to the runtime's own item stream
(section 7). See `REFUSE_INTERACTIVE_SESSION_STARTUP` below — that gap is an OWNER
DECISION this file leaves explicit rather than answering on its own authority.

── IDENTITY — the naive mapping is the SAFE one ──────────────────────────────────────
`agent_type` is present on a native child's payload and the key is ABSENT on the
parent's. It is a routing signal and never a credential: the parent NAMES the role in
its own spawn call, so a model that can call the spawn tool can request any role.

The trap is that the defensive-looking move is the dangerous one. Measured against the
live guard at `25dbd030`, with `codex-hook-adapter.test.py` re-deriving it:

    caller value          opening work (5c/5d)     posting (5e)
    <key absent>          abstains                 abstains      <- the hazard
    ""                    abstains                 abstains      <- identical to absent
    codex-unidentified    deny                     deny          <- what this file sends

So normalising a missing identity to `""` hands the Codex PARENT THREAD the
orchestrator's exemptions by accident. A BARE name fails closed instead, because the
guard's allowlists match the namespaced `<plugin>:<persona>` form — `agents-lead` is
denied by 5e while `tadeumendonca-skills:agents-lead` abstains. Codex's own value is
bare. **So passing the value through verbatim, and substituting a non-empty sentinel
when there is none, is both the simplest mapping and the closed one.**

The consequence is stated rather than worked around: on Codex, NO caller obtains a
caller-dependent exemption. Opening work and posting to a public surface are refused to
every Codex caller, including one whose `agent_type` reads `quality-assurance`. That is
a boundary limitation of this harness, not a new merge executor, and the way to lift it
is native authenticated caller binding, which does not exist.

── FAILURE POSTURE ───────────────────────────────────────────────────────────────────
Fail open, matching the guard's own general contract: a missing interpreter, an
unreadable guard, a malformed payload, a timeout or an unparseable verdict all ABSTAIN
and write one line to stderr. A floor that is absent is indistinguishable from a floor
that is holding, which is why `--selfcheck` exists and why activation instructions must
send an operator through it.

The guard's own fail-closed exception (rule 7c, the merge verdict lookup) is preserved
by construction: this file does not interpret the guard's rules, it forwards a verdict.

Usage:

    python3 scripts/codex-hook-adapter.py            # hook mode: payload on stdin
    python3 scripts/codex-hook-adapter.py --selfcheck  # activation status; nonzero if blocked
"""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
GUARD = REPO_ROOT / "hooks" / "scripts" / "permission-guard.sh"

# The event this adapter speaks about. Codex's vocabulary is twelve PascalCase names and
# this is the only one translated here; the observer half of this harness is a later
# slice and is not smuggled in by accepting other events silently.
EVENT = "PreToolUse"

# `matcher` is compared against `tool_name`, and the shell route's `tool_name` is `Bash`
# — NOT `shell`, which matches nothing and registers a hook that reads as installed and
# never fires. The carrier ships NO matcher at all for that reason: dispatch happens
# here, where a wrong value is a visible branch rather than a silent non-registration.
SHELL_TOOL = "Bash"

# Every other route the runtime was observed carrying. Listed so that an unhandled route
# is a named abstention rather than an accident, and so `--selfcheck` can print it.
#   apply_patch               a file edit; the floor is a COMMAND guard and says nothing
#                             about a patch envelope, so translating it would be inventing
#                             a rule rather than carrying one.
#   collaborationspawn_agent  delegation. Its tool_input carries the requested agent_type,
#   collaborationwait_agent   which is the measurement showing identity is a selection.
UNTRANSLATED_ROUTES = ("apply_patch", "collaborationspawn_agent", "collaborationwait_agent")

# A non-empty caller value that no allowlist in the guard matches, used when the payload
# carries no usable identity. It must not end in `:<persona>`: the guard's 5e allowlist
# matches the namespaced form, so `codex:quality-assurance` would be a synthesised
# identity that works. There is deliberately no colon in it at all.
UNIDENTIFIED_CALLER = "codex-unidentified"

# Seconds. The carrier declares its own host-side timeout; this one is deliberately
# shorter so a slow guard returns an abstention WITH a stderr line rather than being
# killed silently by the host, which is the same outcome with no trace.
GUARD_TIMEOUT = float(os.environ.get("CODEX_HOOK_ADAPTER_TIMEOUT", "4.0"))

# ── THE BRANCH POINT — the owner's ruling is this one constant ────────────────────────
#
# `write_stdin` defeats a command-string floor: the model opens a bare interpreter, the
# hook sees `bash`, and every line fed in afterwards is observed by nothing. Two answers
# are defensible and the third — shipping the command floor and calling it shell
# coverage — is refused by this repository's own rule and is not implemented here.
#
#   False  SHIP THE BRIDGE AND STATE THE GAP. The floor covers commands issued as tool
#          calls. It does not cover input delivered into a running session, and every
#          coverage sentence says so.
#   True   REFUSE INTERACTIVE SESSION STARTUP. `is_interactive_startup` below denies a
#          shell or REPL invoked with no script and no non-interactive flag, which is
#          the only enforceable point on this route.
#
# Flipping this constant is the whole of the change. Both paths are exercised by
# `codex-hook-adapter.test.py`, so the unselected one cannot rot.
REFUSE_INTERACTIVE_SESSION_STARTUP = False

# The programs whose bare invocation opens a session that later input can be fed into.
# THIS LIST IS THE COST OF THE `True` BRANCH AND IT IS AN ENUMERATION OVER SPELLINGS —
# the exact shape `action-pendency-guard.sh` was deleted for. It is written out rather
# than hidden so that whoever rules on the constant can see what they are buying.
INTERACTIVE_PROGRAMS = (
    "bash", "sh", "zsh", "ksh", "dash", "fish",
    "python", "python3", "node", "irb", "ruby", "psql", "sqlite3", "R",
)

# Argument forms that make one of the above non-interactive: a command string, a module,
# a script file. Anything else, and the invocation opens a session.
NON_INTERACTIVE_FLAGS = ("-c", "-m", "-e", "--command", "--eval", "-s", "--stdin")


def emit_block(reason):
    """Codex's refusal vocabulary, measured in section 5 of the bridge document: a JSON
    object on stdout and exit 0. The verb is `block`, not `deny`; there is no
    `hookSpecificOutput` envelope and no exit-code-2 channel. The runtime's own error
    for the degenerate case is `hook returned decision:block without a non-empty
    reason`, so an empty reason is substituted rather than forwarded."""
    if not reason or not reason.strip():
        reason = ("Blocked by the irreversible floor. The guard returned a refusal with "
                  "no reason text; see hooks/scripts/permission-guard.sh.")
    sys.stdout.write(json.dumps({"decision": "block", "reason": reason}))
    sys.stdout.write("\n")
    return 0


def abstain(note=None):
    """No decision. Nothing on stdout — an empty stdout is how a hook declines to rule,
    and printing an `allow` this harness never authored would be inventing one."""
    if note:
        sys.stderr.write("codex-hook-adapter: %s\n" % note)
    return 0


def map_caller(payload):
    """ABSENT is not EMPTY. Any value that is not a non-empty string becomes the
    sentinel, which the guard's caller-keyed rules deny through their catch-all."""
    value = payload.get("agent_type")
    if isinstance(value, str) and value.strip():
        return value
    return UNIDENTIFIED_CALLER


def is_interactive_startup(command):
    """True when the command opens an interpreter session with no work attached, which
    is the only point on the `write_stdin` route a layer can observe at all.

    Only reached when REFUSE_INTERACTIVE_SESSION_STARTUP is True."""
    try:
        import shlex
        words = shlex.split(command)
    except ValueError:
        return False
    if not words:
        return False
    program = os.path.basename(words[0])
    if program not in INTERACTIVE_PROGRAMS:
        return False
    rest = words[1:]
    if not rest:
        return True
    for word in rest:
        if word in NON_INTERACTIVE_FLAGS:
            return False
        if word.startswith("-"):
            continue
        # A bare word after the program is a script or a database name: work is attached.
        return False
    return True


def run_guard(command, caller, cwd):
    """Forward to the authoritative floor.

    THE PROCESS WORKING DIRECTORY IS LOAD-BEARING AND THE PAYLOAD FIELD IS NOT. The guard
    resolves a bare `git push`'s branch with `git -C "." symbolic-ref`, so the verdict
    follows the process cwd and IGNORES the payload's `cwd` entirely. Measured on two
    fixture repositories, one on `main` and one on a feature branch:

        process cwd=main     payload cwd=feature  -> deny
        process cwd=feature  payload cwd=main     -> abstain

    Both controls behaved (main/main deny, feature/feature abstain), so the two mismatched
    rows are the finding rather than noise. Not chdir-ing here would make the trunk rule
    read whichever tree the host happened to launch the hook from, and the error runs in
    BOTH directions — a real trunk push abstaining is the expensive one.
    """
    if shutil.which("bash") is None:
        return None, "bash is not on PATH; the floor cannot run and this act was NOT judged"
    if not GUARD.is_file():
        return None, "the guard is not at %s; the floor cannot run and this act was NOT judged" % GUARD
    payload = {
        "hook_event_name": EVENT,
        "tool_name": SHELL_TOOL,
        "tool_input": {"command": command},
        "agent_type": caller,
        "cwd": cwd,
    }
    workdir = cwd if cwd and os.path.isdir(cwd) else str(REPO_ROOT)
    try:
        completed = subprocess.run(
            ["bash", str(GUARD)],
            input=json.dumps(payload),
            capture_output=True,
            text=True,
            cwd=workdir,
            timeout=GUARD_TIMEOUT,
        )
    except subprocess.TimeoutExpired:
        return None, ("the floor did not answer within %ss; this act was NOT judged"
                      % GUARD_TIMEOUT)
    except OSError as exc:
        return None, "the floor could not be started (%s); this act was NOT judged" % exc
    out = (completed.stdout or "").strip()
    if not out:
        return {"decision": None}, None
    try:
        verdict = json.loads(out)["hookSpecificOutput"]
    except (ValueError, KeyError, TypeError):
        return None, ("the floor returned output this adapter cannot read; this act was "
                      "NOT judged")
    return {"decision": verdict.get("permissionDecision"),
            "reason": verdict.get("permissionDecisionReason", "")}, None


def translate(payload):
    """Codex payload in, exit code out; the decision is written to stdout."""
    if payload.get("hook_event_name") != EVENT:
        return abstain()
    tool = payload.get("tool_name")
    if tool != SHELL_TOOL:
        # Named rather than silent: an unhandled route is a coverage claim this adapter
        # must not make, and `apply_patch` is a real edit route it genuinely does not
        # cover. Section 3 of the bridge document carries the same sentence.
        return abstain("route %r carries no floor here" % tool if tool else None)
    tool_input = payload.get("tool_input")
    command = tool_input.get("command") if isinstance(tool_input, dict) else None
    if not isinstance(command, str) or not command.strip():
        return abstain()

    if REFUSE_INTERACTIVE_SESSION_STARTUP and is_interactive_startup(command):
        return emit_block(
            "Blocked: an interactive interpreter session is refused on this harness. "
            "Input fed into a running session with write_stdin is observed by no layer "
            "— not this hook and not the runtime's own item stream — so the command "
            "floor cannot speak about anything you would type into it. Run the work as "
            "one command instead (for example `bash -c '<payload>'`), which IS judged.")

    verdict, failure = run_guard(command, map_caller(payload), payload.get("cwd") or "")
    if failure is not None:
        return abstain(failure)
    decision = verdict.get("decision")
    if decision == "deny":
        return emit_block(verdict.get("reason", ""))
    if decision == "ask":
        # Codex's measured vocabulary has ONE refusal verb and no prompt rung, so there
        # is nothing to translate an `ask` into. It becomes a block: an act the floor
        # would not have let through unattended must not pass because the destination
        # harness is missing a rung. Unreachable at 25dbd030 — the guard defines `ask()`
        # and has ZERO call sites against `deny`'s 37 — and implemented anyway, because
        # the reachable day is the day someone adds a caller, not the day someone reads
        # this branch.
        return emit_block(
            (verdict.get("reason") or "") +
            "\n\n[codex-hook-adapter] The floor asked for a human decision. Codex's hook "
            "vocabulary has no prompt, so this is refused rather than passed through. "
            "Take the decision yourself and run the act directly if it is right.")
    return abstain()


# ── selfcheck ─────────────────────────────────────────────────────────────────────────

def selfcheck():
    """Activation status. Every hook here fails open, so an inert floor looks exactly
    like a holding one — this is the only route an operator has to tell them apart, and
    it is a REPORT rather than a control: it changes no trust state and writes nothing."""
    blocking = []
    notes = []

    if shutil.which("bash") is None:
        blocking.append("bash is not on PATH — the guard cannot run")
    if shutil.which("jq") is None:
        blocking.append(
            "jq is not on PATH — MEASURED: without it the guard exits 0 with empty "
            "stdout on `terraform apply`, which is a silent fail-open of the whole floor")
    if not GUARD.is_file():
        blocking.append("the guard is missing at %s" % GUARD)
    if shutil.which("git") is None:
        notes.append("git is not on PATH — the trunk-push rule cannot resolve a branch")
    if shutil.which("gh") is None:
        notes.append("gh is not on PATH — the merge floor (rule 7c) denies rather than "
                     "passing, which is its designed fail-closed posture")

    carrier = REPO_ROOT / ".codex-plugin" / "plugin.json"
    hooks_file = REPO_ROOT / "codex-hooks.json"
    if not carrier.is_file():
        blocking.append("the Codex carrier %s is missing" % carrier)
    else:
        try:
            manifest = json.loads(carrier.read_text())
        except ValueError as exc:
            blocking.append("the Codex carrier does not parse (%s)" % exc)
            manifest = {}
        hooks_value = manifest.get("hooks")
        if not isinstance(hooks_value, str):
            # Row four of the carrier table: a wrong TYPE does not fail closed, it
            # silently restores the Claude registry the carrier existed to replace.
            blocking.append(
                "the carrier's `hooks` value is %r, not a path string — a wrong type "
                "falls back to the Claude bundle SILENTLY, so the carrier would read as "
                "installed and behave as absent" % (hooks_value,))
        elif not (REPO_ROOT / hooks_value.lstrip("./")).is_file():
            blocking.append("the carrier names %r and no such file exists — a missing "
                            "path registers ZERO hooks, silently" % hooks_value)
    if not hooks_file.is_file():
        blocking.append("%s is missing" % hooks_file)

    notes.append(
        "TRUST IS NOT CHECKED HERE AND CANNOT BE: it is a `trusted_hash` in the invoking "
        "user's own config.toml, this process does not read that file, and it would not "
        "be a control if it did — anything that can write that file confers trust.")
    notes.append(
        "COVERAGE: the model's tool calls only. command/exec, process/spawn and "
        "thread/shellCommand fire no hook; input fed into a running session with "
        "write_stdin is observed by nothing.")
    notes.append(
        "CALLER: no Codex caller receives a caller-dependent exemption. Opening work and "
        "posting to a public surface are refused to every caller on this harness.")
    notes.append(
        "FIRING IS UNPROVEN, AND THIS CHECK IS NOT EVIDENCE OF IT. A native run on 2026-09-16 "
        "(codex-cli 0.154.0-alpha.6.2) found a REGISTERED and TRUSTED PreToolUse hook not "
        "acting on a shell tool call, in this repository's own checkout, with the adapter "
        "present and returning `block` for that same payload when fed it directly. What is "
        "measured is that the carrier is DISCOVERED and can be TRUSTED — by an API call with "
        "NO human prompt, so Codex hook trust is not a human checkpoint. What is NOT measured "
        "is that Codex ever calls this file. THIS CHECK CANNOT CLOSE THAT GAP: if you are "
        "reading this line the adapter was found and run by YOU, which says nothing about "
        "whether the runtime does. Standing hypothesis, labelled as one: command/exec, "
        "process/spawn and thread/shellCommand fire ZERO hooks (section 3), so the leading "
        "explanation is an unhooked route. See docs/codex-hook-bridge.md sections 13 and 14.")
    notes.append(
        "INTERACTIVE SESSION STARTUP: %s"
        % ("REFUSED" if REFUSE_INTERACTIVE_SESSION_STARTUP else
           "permitted, and the write_stdin gap is therefore OPEN"))

    for note in notes:
        sys.stdout.write("note:  %s\n" % note)
    for item in blocking:
        sys.stdout.write("BLOCK: %s\n" % item)
    if blocking:
        sys.stdout.write("\ncodex-hook-adapter: NOT ACTIVE — %d blocking condition(s).\n"
                         % len(blocking))
        return 1
    sys.stdout.write("\ncodex-hook-adapter: dependencies and carrier are in place. This "
                     "says the floor CAN run; it does not say a hook FIRED.\n")
    return 0


def main(argv):
    if "--selfcheck" in argv:
        return selfcheck()
    raw = sys.stdin.read()
    try:
        payload = json.loads(raw)
    except ValueError:
        return abstain("payload did not parse; this act was NOT judged")
    if not isinstance(payload, dict):
        return abstain("payload is not an object; this act was NOT judged")
    return translate(payload)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
