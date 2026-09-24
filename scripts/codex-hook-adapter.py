#!/usr/bin/env python3
# purpose: carry the irreversible floor onto Codex through PreToolUse and refuse a prompt through UserPromptSubmit when that native route's own local dependencies are absent
"""The Codex side of the permission floor. A TRANSLATOR, never a second policy.

`hooks/scripts/permission-guard.sh` stays the only authored floor in this repository.
This file does six things and deliberately nothing else:

  1. reads a native Codex `PreToolUse` payload on stdin;
  2. decides whether the route is one the floor can speak about at all;
  3. maps the CALLER, which is the part that inverts intuition — see IDENTITY below;
  4. runs the guard and translates its verdict into Codex's own vocabulary.
  5. on `UserPromptSubmit`, refuses a degraded session when the Codex floor's own
     local dependencies are absent.
  6. on `UserPromptSubmit`, when the floor is healthy, REPORTS — never refuses — that the
     project registers native personas from a snapshot older than the installed plugin
     (#509). See THE PERSONA-SNAPSHOT NOTICE below.

There is no rule here. The sixth item is not one either: it reads two version strings and
says so, and every path through it ends in exit 0 with no `block`. A rule added here would be a second floor that drifts from the
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

── IDENTITY — ROLE PARITY since #501; the section below it is the struck predecessor ──
`agent_type` is present on a native child's payload and the key is ABSENT on the
parent's. It is a routing signal and never a credential: the parent NAMES the role in
its own spawn call, so a model that can call the spawn tool can request any role — and
an operator can hand-declare a role of any name, the build's own names included
(measured 2026-09-23, docs/codex-hook-bridge.md section 19).

**What this file sends now (#501, owner decisions 1-3, 2026-09-23):**

    what the payload carries        what the adapter sends     measured as
    <key absent>                    ""                         the ROOT session only
    a build role id, e.g. `tadeumendonca_quality_assurance`
                                    tadeumendonca-skills:quality-assurance
                                                               every child, at depth 1 and 2
    any other child role            the same value, verbatim   (a bare name fails closed)
    "", null, or a non-string       codex-unidentified         (never observed; kept closed)

The owner's rule: «temos que funcionar de forma equivalente em todos harness suportados
pela nossa distribuicao de plugin». So the Codex ROOT session is treated as the
orchestrator (the context that dispatches every persona, with no role of its own), and
a child's Codex role id is rewritten HERE (`codex_role_to_claude`) into the same
namespaced id a Claude Code plugin session stamps. Every role-keyed rule then grants and
denies a persona the same act on both harnesses, while the guard itself reads the raw
field exactly as it did before #501.

**The rewrite is here and not in the guard, on a measurement.** The guard is shared and
cannot tell which harness called it. On Claude Code a project-local agent file named
`tadeumendonca_<persona>` loads with no plugin and stamps that bare id (the gate measured
it on Claude Code 2.1.280), so a guard-side rewrite gave any committed `.claude/agents/`
file that persona's arms, merge included. This file runs only on the Codex route.

**Why ABSENT -> "" is safe now when it was the hazard below: it was MEASURED to be the
root only.** A disposable-home run on codex-cli 0.151.0-alpha.7.2 with a loopback model
found the key absent on the root's own payloads and present on EVERY child: a registered
role, a spawn with the type omitted (`default`), a full-history fork (`default`) and a
grandchild at `max_depth = 2` (its own role). A child cannot make itself keyless in any
spawn shape measured, and a parent cannot make itself a child. If a later build ever
sends a keyless CHILD payload, this mapping hands that child the orchestrator's position,
which on this floor means posting and opening work, never merge or trunk push (7 and 7b
deny an empty caller). The adapter test pins the four measured shapes by name.

**The cost, and the owner accepted it in these words:** on Codex every role-keyed act,
the irreversible merge included, rests on a DECLARED identity, not an authenticated one.

~~── IDENTITY — the naive mapping is the SAFE one ──~~ STRUCK 2026-09-23 (#501). It was
correct about the floor it described and the owner changed the floor. Kept because it is
the analysis a reader must know was overruled, not forgotten:

~~The trap is that the defensive-looking move is the dangerous one. Measured against the
live guard at `25dbd030`, with `codex-hook-adapter.test.py` re-deriving it:~~

    caller value          opening work (5c/5d)     posting (5e)
    <key absent>          abstains                 abstains      <- ~~the hazard~~ now: the root
    ""                    abstains                 abstains      <- identical to absent
    codex-unidentified    deny                     deny          <- ~~what this file sends~~

~~So normalising a missing identity to `""` hands the Codex PARENT THREAD the
orchestrator's exemptions by accident.~~ It hands them ON PURPOSE now, and to the root
alone, which is the measured half the struck sentence did not have. ~~A BARE name fails
closed instead, because the guard's allowlists match the namespaced `<plugin>:<persona>`
form~~ — still true of a bare name that is NOT the build's scheme (`agents-lead`,
`probe_child`); a `tadeumendonca_<persona>` id is rewritten by this file before the guard
sees it.

~~The consequence is stated rather than worked around: on Codex, NO caller obtains a
caller-dependent exemption. Opening work and posting to a public surface are refused to
every Codex caller, including one whose `agent_type` reads `quality-assurance`. That is
a boundary limitation of this harness, not a new merge executor, and the way to lift it
is native authenticated caller binding, which does not exist.~~ STRUCK: false since #501.
A Codex caller whose role is a build id gets exactly what the same persona gets on
Claude Code, and the Codex `quality-assurance` id IS a merge executor (it reaches rule 7c,
which still reads the verdict at head). Native authenticated caller binding still does
not exist; the owner chose to proceed without it.

── FAILURE POSTURE ───────────────────────────────────────────────────────────────────
The `PreToolUse` translation fails open, matching the guard's own general contract: a
missing interpreter, an unreadable guard, a malformed payload, a timeout or an
unparseable verdict all ABSTAIN and write one line to stderr. `UserPromptSubmit` is the
deliberate exception: once the adapter is running, a missing `bash`, `jq` or authored
guard refuses the prompt before a silently degraded floor can judge later calls.

A MALFORMED TUNABLE IS NOT IN THAT LIST, AND THE DIFFERENCE IS DELIBERATE (#455). A bad
`CODEX_HOOK_ADAPTER_TIMEOUT` does not abstain: the floor keeps running at the built-in
default, and the DEFECT is reported on stderr on every invocation and as a `--selfcheck`
note. Abstaining would turn an operator's typo into a silent floor outage; blocking would
turn it into a session outage. Reporting is the only one of the three that keeps a
mis-set knob distinguishable from an unset one, which is the whole requirement — see
`resolve_guard_timeout` for the three options and why the other two were refused.

The guard's own fail-closed exception (rule 7c, the merge verdict lookup) is preserved
by construction: this file does not interpret the guard's rules, it forwards a verdict.

── WHAT THE FLOOR DOES *NOT* CARRY ONTO CODEX (AC7, 2026-09-21) ──────────────────────
TWO of the guard's convenience rules — an env-var prefix and a stdout redirect — are not
forwarded. They exist on Claude to turn a PROMPT into a self-correcting instruction, and
`/shell`'s own rule is that such a rule must fire on a SUBSET of what the runtime stops
for. Measured on codex-cli 0.151.0-alpha.7.2 the native layer stops neither, and Codex's
hook vocabulary has no prompt rung — so there they fired on MORE.

**THE THIRD, COMMAND SUBSTITUTION, IS FORWARDED, and the same measurement says it should
not be.** It is a floor rule in disguise: a substitution MANUFACTURES the token every
other rule matches on, so omitting it made thirteen irreversible acts reachable. The
measurement is sound and it LOST. See CONVENIENCE_ENV below and section 15.3 of the
bridge document. **Every irreversible rule is forwarded unchanged.**

── AND HOW TO TELL AN ABSENT FLOOR FROM A HOLDING ONE ────────────────────────────────
`CODEX_HOOK_ADAPTER_LOG`, off by default, absolute paths only. It is the only artifact
that separates "the runtime never called this file" from "it called it and the decision
was discarded" — the pair that left the firing question open for five days. See LOG_ENV.

Usage:

    python3 scripts/codex-hook-adapter.py            # hook mode: payload on stdin
    python3 scripts/codex-hook-adapter.py --selfcheck  # activation status; nonzero if blocked
"""

import json
import math
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
GUARD = REPO_ROOT / "hooks" / "scripts" / "permission-guard.sh"

# The two events this adapter speaks about. `PreToolUse` carries the command floor;
# `UserPromptSubmit` carries only its local dependency preflight. Neither registration
# imports the Claude observer set, whose dependencies are not part of the Codex route.
EVENT = "PreToolUse"
PREFLIGHT_EVENT = "UserPromptSubmit"

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

# What the ROOT session is sent (#501): the empty value, which is the orchestrator's
# identity on Claude Code. Named rather than written inline so the one place the adapter
# grants the orchestrator's position is findable by grep.
ROOT_CALLER = ""

# The Codex agent build's role scheme, reversed here and nowhere else (#501). The build
# names a persona's native role "tadeumendonca_" + the persona name with "-" turned into
# "_", and refuses any persona name that is not [a-z0-9]+(-[a-z0-9]+)*, so no persona
# name contains "_" and the reverse is unambiguous. The permission-guard suite derives
# the role set from the build and asserts, through THIS file, that every role takes the
# same arm as its Claude Code id; a change to the build's prefix turns it red.
CODEX_ROLE_RE = re.compile(r"tadeumendonca_([a-z0-9]+(?:_[a-z0-9]+)*)")
CLAUDE_ROLE_NAMESPACE = "tadeumendonca-skills:"

# Seconds. The carrier declares its own host-side timeout; this one is deliberately
# shorter so a slow guard returns an abstention WITH a stderr line rather than being
# killed silently by the host, which is the same outcome with no trace.
#
# ── A MALFORMED TUNABLE IS A CONFIGURATION DEFECT, NOT A CRASH (#455, AC6) ────────────
#
# This read was `float(os.environ.get(...))` at module scope, so `CODEX_HOOK_ADAPTER_
# TIMEOUT=notanumber` raised a ValueError before `main` was reached: a traceback, exit 1
# and NOTHING on stdout — which this runtime reports as a hook error rather than as the
# documented abstention AC6 requires. It failed in both modes, `--selfcheck` included,
# so the one route an operator has to tell an inert floor from a holding one was the
# route that crashed.
#
# WHAT A MALFORMED VALUE MEANS HERE, DECIDED RATHER THAN DEFAULTED. Three answers were
# available and the middle one is taken:
#
#   · SILENTLY fall back to the default. REFUSED. A floor whose timeout was mis-set to
#     `notanumber` is a floor somebody believed they had configured, and a silent
#     fallback makes a mis-set knob indistinguishable from an unset one — this file's
#     own named worst shape, an absence that reads as a presence.
#   · BLOCK every call. REFUSED, and AC6 forbids it in as many words: do not convert an
#     observer failure into a blanket session denial. The tunable is not the act's
#     fault, the floor still runs at the default, and a hook that wedges the session
#     over an env var teaches an operator to unregister it.
#   · FALL BACK TO THE DEFAULT AND SAY SO, EVERY TIME. Taken. The floor keeps running at
#     4.0s, and the defect is reported on stderr on every invocation and as a `note:` in
#     `--selfcheck`. An UNSET knob is silent; a MIS-SET one is loud. That is the
#     distinction the operator needs, and it is carried by presence-of-a-line rather
#     than by anything they have to go and read.
#
# It is a `note:` and NOT a `BLOCK:` in the selfcheck: `BLOCK` means the floor cannot
# run, and it can — reporting NOT ACTIVE over a working floor is a false claim in the
# alarming direction, which trains an operator to discount the next one.
#
# NON-POSITIVE AND NON-FINITE VALUES ARE MALFORMED TOO, and that half matters more than
# the crash. `subprocess.run(timeout=0)` and a negative timeout raise TimeoutExpired
# immediately, so the adapter abstains on EVERY call — the whole floor off, silently,
# with a value that parses. An infinite timeout is the opposite failure and defeats the
# reason this constant exists: the host kills the process instead, which is the same
# outcome with no trace, which the paragraph above says is what the short value avoids.
DEFAULT_GUARD_TIMEOUT = 4.0


def resolve_guard_timeout(raw):
    """(seconds, defect-sentence-or-None). Never raises, for any value of `raw`."""
    if raw is None:
        return DEFAULT_GUARD_TIMEOUT, None
    try:
        value = float(raw)
    except (TypeError, ValueError):
        reason = "is not a number"
    else:
        if not math.isfinite(value):
            reason = "is not a finite number"
        elif value <= 0:
            reason = ("is not positive, and a non-positive timeout makes the guard "
                      "time out on EVERY call — the floor off, silently")
        else:
            return value, None
    return DEFAULT_GUARD_TIMEOUT, (
        "CODEX_HOOK_ADAPTER_TIMEOUT=%r %s. Falling back to the %.1fs default, so the "
        "floor still runs — but this knob is MIS-SET, which is a different state from "
        "unset and is why you are reading this line." % (raw, reason, DEFAULT_GUARD_TIMEOUT))


GUARD_TIMEOUT, GUARD_TIMEOUT_DEFECT = resolve_guard_timeout(
    os.environ.get("CODEX_HOOK_ADAPTER_TIMEOUT"))

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

# ── THE INVOCATION LOG — opt-in, ABSOLUTE-ONLY, and best-effort by construction ───────
#
# WHY IT EXISTS. A floor that fails open is indistinguishable from a floor that is
# holding, and the specific question this Issue could not answer is one layer worse than
# that: a registered, trusted hook did not act, and NOTHING anywhere could say whether
# the adapter ran and its decision was discarded, whether it failed to launch, or
# whether the runtime never called it. `--selfcheck` cannot close that — if you are
# reading its output the adapter was run by YOU. Only a record the adapter writes when
# the RUNTIME calls it can tell the three apart.
#
# WHY IT IS AN ENV VAR NAMING AN ABSOLUTE PATH, and this is a decision rather than a
# default. Three constraints pick the design and each one eliminates the obvious answer:
#
#   * a fixed repo-relative path is the DEFECT THIS ISSUE FOUND, one layer down. The
#     adapter's own command is resolved against the session's cwd, which is why the
#     carrier works in one checkout by structural coincidence. A log resolved the same
#     way would scatter files into whatever tree the operator happened to open, and a
#     relative path is therefore REFUSED rather than resolved — see `log_target`.
#   * a fixed absolute path under the repo root would write into a TRACKED tree on every
#     tool call, which is a new side effect of a preventive control that nobody asked
#     for. `.gitignore`-ing it would hide the side effect rather than remove it.
#   * a default-on log of every command a model runs is a TRANSCRIPT. This adapter sits
#     on the one route that sees every shell act, so writing one by default would make
#     the floor a surveillance surface as a side effect of being a floor. It is off
#     unless an operator names a destination, and nothing in this repository sets it.
#
# WHAT IT MUST NEVER DO. A logging failure must not change a verdict. Every write is
# wrapped and every failure is swallowed to stderr: the floor's job is the decision, and
# a floor that stops judging because it could not append a line is a worse floor than
# one with no log at all. This is the one place in this file where a bare `except` is
# correct, and it is written out rather than narrowed so the reason is visible.
# ── TWO OF THE THREE CONVENIENCE REFUSALS ARE NOT FORWARDED — AC7, and the third is a ──
# ── MEASUREMENT THAT LOST ────────────────────────────────────────────────────────────
#
# ~~THE THREE CONVENIENCE REFUSALS ARE NOT FORWARDED~~ · ~~The guard's rules 3, 8 and the
# redirection rule~~ — **STRUCK 2026-09-21 (#455), on the merge gate's blocking finding,
# re-derived here before accepting it.** Both halves were wrong. The count is TWO, and
# "rule 3" named a FLOOR rule: rule 3 in that file is irreversible git history and ref
# rewrites. The substitution branch never had a number; it is a branch of rule 8.
#
# WHAT IS FORWARDED AGAIN, AND WHY IT HAD TO BE. Rule 8's SUBSTITUTION branch is a plain
# `deny` once more. A substitution MANUFACTURES A TOKEN, and every floor rule in that file
# matches on tokens — so with the branch abstaining, an irreversible act whose
# floor-matching word is the substitution's output was seen by NOTHING. Measured at the
# blocked head: 13 of 20 fixtures flipped `deny -> ABSTAIN`, against six plain-spelling
# controls that denied in both columns, reaching `rm -rf`, IaC mutation, `gh secret set`,
# `gh repo delete`, `git reset --hard` and a trunk push. THE EXECPOLICY DOES NOT COVER IT
# EITHER: it forbids token sequences, which a manufactured token does not produce.
#
# WHAT STAYS OMITTED, and it is measured rather than reasoned: rule 8's ENV-VAR PREFIX
# branch and rule 8b, REDIRECTION. Neither manufactures anything — both sit BESIDE a
# command whose own tokens are intact, so the floor rules still see the act. Seventy
# wrapped floor acts (ten irreparable commands across four env-var wrappers and three
# redirect wrappers): ZERO released under `off`, with all seven wrappers confirmed
# flipping on a harmless command, so the zero is a real zero.
#
# THE NATIVE EVIDENCE STILL SAYS WHAT IT SAID, and the substitution row is kept rather
# than deleted. On codex-cli 0.151.0-alpha.7.2 (`codex-hook-probe.py --phase friction`,
# one turn, a recorder that refuses nothing) all three classes COMPLETED under
# `permissions: ":workspace"`, against a calibration — the same plain `touch` under
# `:read-only` — that was observed by the hook and did NOT complete. **That measurement is
# sound and it LOST.** Switching the substitution branch off opens the floor on the
# harness this repository actually runs, which costs more than an over-block on the
# harness it is being ported to. A measurement can be right and still not carry the
# decision; deleting the row would hide that trade.
#
# THE COST, stated as a cost rather than as a win: on Codex the substitution refusal now
# fires on more than the runtime was measured stopping — the very thing AC7 forbids. It is
# the same over-block posture this floor already accepts for rule 8's `VAR=x` case on the
# Claude side, and it is the safe direction.
#
# The classification lives in the GUARD, not here — `deny_convenience` in
# `hooks/scripts/permission-guard.sh` — because which rules are friction is a property of
# the rules and this file authors none. All this line does is decline to ask for them.
CONVENIENCE_ENV = "PERMISSION_GUARD_CONVENIENCE_RULES"

LOG_ENV = "CODEX_HOOK_ADAPTER_LOG"
# Schema version, so a reader of an old file is not guessing which fields were present.
LOG_SCHEMA = 1

# What this invocation decided, filled in by `emit_block`/`abstain` and read only by the
# logger. It is deliberately NOT a return value: the two emitters are called from six
# places and threading an outcome through all of them would put logging plumbing into
# the decision path, which is the path that must stay readable.
OUTCOME = {"decision": "__unreached__"}


def log_target():
    """The configured destination, or None. A RELATIVE path is refused, not resolved."""
    raw = os.environ.get(LOG_ENV)
    if not raw or not raw.strip():
        return None
    path = raw.strip()
    if not os.path.isabs(path):
        return ("", "%s=%r is not an absolute path; refusing to resolve it against the "
                    "session's working directory, which is the resolution defect this "
                    "bridge already carries one layer down. Nothing was logged."
                    % (LOG_ENV, path))
    return (path, None)


def log_invocation(record):
    """Append one JSON object per line. Best effort, and never a verdict."""
    target = log_target()
    if target is None:
        return
    path, refusal = target
    if refusal:
        sys.stderr.write("codex-hook-adapter: %s\n" % refusal)
        return
    record = dict(record)
    record["schema"] = LOG_SCHEMA
    record["pid"] = os.getpid()
    record["adapter"] = str(Path(__file__).resolve())
    record["process_cwd"] = os.getcwd()
    try:
        parent = os.path.dirname(path)
        if parent and not os.path.isdir(parent):
            os.makedirs(parent, exist_ok=True)
        with open(path, "a", encoding="utf-8") as handle:
            handle.write(json.dumps(record, sort_keys=True) + "\n")
    except Exception as exc:                          # noqa: BLE001 — see the block above
        sys.stderr.write("codex-hook-adapter: could not write the invocation log (%s); "
                         "the DECISION is unaffected\n" % exc)


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
    OUTCOME["decision"] = "block"
    OUTCOME["reason"] = reason
    return 0


def abstain(note=None):
    """No decision. Nothing on stdout — an empty stdout is how a hook declines to rule,
    and printing an `allow` this harness never authored would be inventing one."""
    if note:
        sys.stderr.write("codex-hook-adapter: %s\n" % note)
    OUTCOME["decision"] = None
    OUTCOME["note"] = note
    return 0


def codex_role_to_claude(value):
    """The reverse of `scripts/codex-agent-build.py`'s role scheme (#501): a well-formed
    `tadeumendonca_<persona>` becomes `tadeumendonca-skills:<persona>`, the id a Claude
    Code plugin session stamps for the same persona. Anything else is returned unchanged,
    so a malformed id or a foreign role still falls to each rule's catch-all.

    WHY HERE AND NOT IN THE GUARD. The guard is shared by both harnesses and cannot tell
    which one called it. On Claude Code a project-local agent file named
    `tadeumendonca_<persona>` loads with no plugin and stamps that bare id (measured by the
    gate on Claude Code 2.1.280), so a rewrite in the guard handed any committed
    `.claude/agents/` file that persona's arms. This file runs only on the Codex route, so
    the rewrite reaches Codex callers and nothing else. The owner accepted a declared
    identity on Codex, and only there."""
    match = CODEX_ROLE_RE.fullmatch(value)
    if not match:
        return value
    return CLAUDE_ROLE_NAMESPACE + match.group(1).replace("_", "-")


def map_caller(payload):
    """ABSENT is still not EMPTY, and the two now map to DIFFERENT values (#501).

    A missing key is the Codex ROOT session, measured as the only payload without one,
    so it becomes `""` — the orchestrator, exactly as Claude Code stamps it. A present
    but empty, null or non-string value was never observed and stays the sentinel, which
    every caller-keyed rule denies through its catch-all. A non-empty string is passed
    through `codex_role_to_claude`, so a build role id reaches the guard in its Claude
    Code form and every other value reaches it verbatim."""
    if "agent_type" not in payload:
        return ROOT_CALLER
    value = payload.get("agent_type")
    if isinstance(value, str) and value.strip():
        return codex_role_to_claude(value)
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
    env = dict(os.environ)
    env[CONVENIENCE_ENV] = "off"
    try:
        completed = subprocess.run(
            ["bash", str(GUARD)],
            input=json.dumps(payload),
            capture_output=True,
            text=True,
            cwd=workdir,
            env=env,
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


def floor_blockers():
    """Local conditions without which the Codex command floor cannot answer.

    Keep this list narrower than the Claude registry's preflight: a Codex installation
    activates this adapter and the shared guard, not that registry's observers. `git`
    and `gh` remain notes in selfcheck because their absence degrades individual guard
    branches according to the guard's own posture; it does not make every command
    unjudgeable. The adapter itself and Python are already present if this code runs.
    """
    blocking = []
    if shutil.which("bash") is None:
        blocking.append("bash is not on PATH — the guard cannot run")
    if shutil.which("jq") is None:
        blocking.append(
            "jq is not on PATH — without it the guard can exit 0 with empty stdout, "
            "silently failing open")
    if not GUARD.is_file():
        blocking.append("the guard is missing at %s" % GUARD)
    return blocking


# ── THE PERSONA-SNAPSHOT NOTICE (#509) — a REPORT on the prompt route, never a refusal ──
#
# WHAT IT CLOSES. `scripts/codex-agent-build.py` pins a consumer's native personas to a
# snapshot directory on purpose (docs/codex-native-personas.md), and nothing told a Codex
# session that the snapshot had fallen behind the installed plugin: on 2026-09-24 the
# consumer registered 2.0.44 while the plugin was at 2.0.79, and the orchestrator
# compensated by ordering each persona to re-read the source, which cannot be verified.
# Claude Code has `hooks/scripts/session-plugin-version.sh`; Codex had no equivalent.
#
# WHY IT LIVES HERE, and it is the cheapest carrier available rather than the natural one.
# A `SessionStart` registration would fire once instead of on every prompt, but ANY edit
# to `codex-hooks.json` changes a trusted command or adds an untrusted registration, and a
# changed command is SKIPPED until the owner re-trusts it (bridge section 20.5) — the
# floor off, silently, to buy a notice. The UserPromptSubmit registration already exists
# and already runs this file, and the file's CONTENTS are not in the trusted hash. So the
# notice rides the existing registration and the command string does not move
# (`codex-hook-adapter.test.py` section 8e is the pin that says so).
#
# THE CHANNEL IS MEASURED, not assumed from Claude Code. On codex-cli 0.151.0-alpha.7.2
# with a loopback model (`codex-hook-probe.py --phase snapshotnotice`), a UserPromptSubmit
# hook printing `{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit",
# "additionalContext":…}}` reached the model's FIRST request of the turn as a
# `developer`-role message after the user's prompt, the run read `completed` (not
# `blocked`) and the turn's act executed. A `systemMessage` shape reached the UI and NOT
# the model, which is why that shape is not used.
#
# IT MUST NEVER DENY, and the resolver makes that a property to be defended rather than a
# default. The shipped command maps ANY non-zero exit to 2, and 2 BLOCKS the prompt
# (bridge section 20.3). So an uncaught exception in this code would refuse every prompt
# over a notice. Every path is inside `try/except Exception` and degrades to silence —
# which is the permissive direction: a missed notice costs a stale persona, a refused
# prompt costs the session.
#
# WHAT IT READS, and what it cannot. The registrations in `<dir>/.codex/config.toml` for
# the payload's `cwd` and each ancestor up to and including the first one holding `.git`;
# the nearest file wins per role, as a project layer does. For each registered
# `tadeumendonca_*` role, the snapshot directory is the parent of its `profiles/` file, and
# its version is `source-manifest.json`'s `version`. That is compared with THIS plugin
# root's `VERSION`, which is the installed version by construction: the resolver ran this
# copy of the file. NOT READ, so silent: a registration passed as `-c` flags by the
# builder's `--exec` launcher, one in the user-level `config.toml`, and — the one that
# matters — a THREAD that started before the file was edited. Measured on the same build:
# a running thread keeps the registration it started with, so after an update this notice
# reads the new file and goes quiet in an old thread that is still on the old snapshot.
SNAPSHOT_ROLE_PREFIX = "tadeumendonca_"
SNAPSHOT_MANIFEST = "source-manifest.json"
SNAPSHOT_TAG = "PERSONA SNAPSHOT BEHIND"
_AGENT_TABLE_RE = re.compile(
    r"\s*\[\s*agents\s*\.\s*\"?(" + SNAPSHOT_ROLE_PREFIX + r"[a-z0-9_]+)\"?\s*\]\s*(?:#.*)?")
_CONFIG_FILE_RE = re.compile(
    r"\s*config_file\s*=\s*(\"(?:[^\"\\]|\\.)*\"|'[^']*')\s*(?:#.*)?")


def project_config_files(cwd):
    """`.codex/config.toml` from `cwd` upward, nearest first, stopping at a git root."""
    found = []
    if not cwd or not os.path.isdir(cwd):
        return found
    current = Path(cwd).resolve()
    for _ in range(64):
        candidate = current / ".codex" / "config.toml"
        if candidate.is_file():
            found.append(candidate)
        if (current / ".git").exists() or current.parent == current:
            break
        current = current.parent
    return found


def registered_profiles(text):
    """{role: config_file} for every `[agents.tadeumendonca_*]` table in one config.

    A line scanner rather than a TOML parser, deliberately: this file runs on the
    interpreter the host provides, and `tomllib` is 3.11+. The builder writes each table
    as a header plus a JSON-quoted `config_file` line, which is all this reads; any other
    header ends the table. A form it cannot read yields nothing, and nothing is silence."""
    profiles = {}
    role = None
    for line in text.splitlines():
        header = _AGENT_TABLE_RE.fullmatch(line)
        if header:
            role = header.group(1)
            continue
        if line.lstrip().startswith("["):
            role = None
            continue
        if role is None or role in profiles:
            continue
        value = _CONFIG_FILE_RE.fullmatch(line)
        if value:
            raw = value.group(1)
            profiles[role] = json.loads(raw) if raw.startswith('"') else raw[1:-1]
    return profiles


def version_tuple(text):
    match = re.fullmatch(r"\s*(\d+)\.(\d+)\.(\d+)\s*", text or "")
    return tuple(int(part) for part in match.groups()) if match else None


def snapshot_findings(cwd):
    """(installed_version, [(snapshot_dir, version_or_None, [roles])]) for every
    registered snapshot that is BEHIND the installed plugin or whose version cannot be
    read. An empty list means nothing to report. Raises on nothing it can foresee; the
    callers still wrap it, because a raise here would become exit 2."""
    installed = (REPO_ROOT / "VERSION").read_text(encoding="utf-8").strip()
    installed_tuple = version_tuple(installed)
    if installed_tuple is None:
        return installed, []
    profiles = {}
    for config in project_config_files(cwd):
        for role, path in registered_profiles(config.read_text(encoding="utf-8")).items():
            profiles.setdefault(role, path)
    by_dir = {}
    for role, path in sorted(profiles.items()):
        profile = Path(os.path.expanduser(path))
        directory = profile.parent.parent if profile.parent.name == "profiles" else profile.parent
        by_dir.setdefault(str(directory), []).append(role)
    findings = []
    for directory, roles in sorted(by_dir.items()):
        version = None
        try:
            manifest = json.loads((Path(directory) / SNAPSHOT_MANIFEST).read_text(encoding="utf-8"))
            version = manifest.get("version") if isinstance(manifest, dict) else None
        except (OSError, ValueError):
            version = None
        registered = version_tuple(version if isinstance(version, str) else None)
        if registered is None or registered < installed_tuple:
            findings.append((directory, version if registered else None, roles))
    return installed, findings


def snapshot_notice_text(installed, findings):
    parts = []
    for directory, version, roles in findings:
        parts.append("%s at %s (%d role%s)" % (
            ("version %s" % version) if version else "an UNREADABLE version",
            directory, len(roles), "" if len(roles) == 1 else "s"))
    oldest = min((f[1] for f in findings if f[1]), key=version_tuple, default=None)
    return (
        "%s (codex-hook-adapter, #509). This project's .codex/config.toml registers native "
        "tadeumendonca_* personas from %s, but the installed plugin is %s. A persona you "
        "dispatch receives that snapshot's briefs verbatim, not the current ones: say so "
        "before dispatching, and treat any rule newer than %s as absent from it. To "
        "update: build a NEW snapshot directory from the installed plugin root, "
        "verify it with --check, re-register it with --install-config, then continue in a "
        "NEW thread; keep the old directory until every thread started before the update "
        "has finished (docs/codex-native-personas.md). This notice reports and blocks nothing."
        % (SNAPSHOT_TAG, "; ".join(parts), installed, oldest or "the snapshot"))


def snapshot_notice(cwd):
    """The notice text, or None. Never raises: see the block above for why."""
    try:
        installed, findings = snapshot_findings(cwd)
        if not findings:
            return None
        return snapshot_notice_text(installed, findings)
    except Exception as exc:                          # noqa: BLE001 — a raise here is exit 2
        sys.stderr.write("codex-hook-adapter: the persona-snapshot notice could not be "
                         "computed (%s); nothing was reported and nothing was refused\n" % exc)
        return None


def emit_context(text):
    """Codex's measured non-blocking channel: additionalContext on UserPromptSubmit."""
    sys.stdout.write(json.dumps({"hookSpecificOutput": {
        "hookEventName": PREFLIGHT_EVENT, "additionalContext": text}}))
    sys.stdout.write("\n")
    OUTCOME["decision"] = "context"
    OUTCOME["note"] = text
    return 0


def translate(payload):
    """Codex payload in, exit code out; the decision is written to stdout."""
    if payload.get("hook_event_name") == PREFLIGHT_EVENT:
        blocking = floor_blockers()
        if not blocking:
            notice = snapshot_notice(payload.get("cwd") or "")
            return emit_context(notice) if notice else abstain()
        return emit_block(
            "Codex hook preflight failed: %s. Fix the installed plugin or PATH before "
            "continuing; %d blocking condition(s) found."
            % (blocking[0], len(blocking)))
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

    caller = map_caller(payload)
    verdict, failure = run_guard(command, caller, payload.get("cwd") or "")
    if failure is not None:
        return abstain(failure)
    decision = verdict.get("decision")
    if decision == "deny":
        reason = verdict.get("reason", "")
        raw = payload.get("agent_type")
        # The guard prints the id it was SENT. When this file rewrote a Codex role id, that
        # is the Claude Code form, so the refusal would not name what Codex actually sent.
        # Appended rather than substituted, so the guard's own text reaches the model intact.
        if isinstance(raw, str) and caller != raw and caller not in (ROOT_CALLER, UNIDENTIFIED_CALLER):
            reason = (reason + "\n\n[codex-hook-adapter] agent_type as Codex sent it: '%s', "
                      "rewritten to '%s' for the shared floor (#501)." % (raw, caller))
        return emit_block(reason)
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
    """Activation status. This is a REPORT rather than a control: it changes no trust
    state and writes nothing. UserPromptSubmit now carries the same local blocker set,
    but a green here still does not prove the host invoked either registration."""
    blocking = []
    notes = []

    # The tunable is NAMED here whether or not it is set, so an operator reading this
    # report learns that the knob exists and what value is actually in force — which is
    # the half a stderr line cannot carry, because a correctly-set knob prints nothing.
    if GUARD_TIMEOUT_DEFECT:
        # A note and NOT a block: the floor runs at the default, so reporting NOT ACTIVE
        # would be a false claim in the alarming direction.
        notes.append("GUARD TIMEOUT MIS-SET: %s" % GUARD_TIMEOUT_DEFECT)
    else:
        notes.append(
            "GUARD TIMEOUT: %.1fs, from %s. A malformed, non-positive or non-finite "
            "CODEX_HOOK_ADAPTER_TIMEOUT falls back to the %.1fs default and says so here "
            "and on stderr — it does not crash and does not block (#455)."
            % (GUARD_TIMEOUT,
               "CODEX_HOOK_ADAPTER_TIMEOUT" if os.environ.get("CODEX_HOOK_ADAPTER_TIMEOUT")
               else "the built-in default (the variable is unset)",
               DEFAULT_GUARD_TIMEOUT))

    blocking.extend(floor_blockers())
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
    # The former note ("no Codex caller receives a caller-dependent exemption ...
    # refused to every caller on this harness") was struck on 2026-09-23 (#501); it went
    # false when the owner chose role parity.
    notes.append(
        "CALLER: ROLE PARITY with Claude Code (#501). The ROOT session is sent as the "
        "orchestrator (\"\"): it may post, its `gh issue create` falls to Codex's own "
        "approval layer, and merge and trunk push are denied. A child's "
        "tadeumendonca_<persona> id takes that persona's arm in every role-keyed rule: "
        "developer, tech-lead, agents-lead and quality-assurance may post; product-lead, "
        "content-writer, content-reviewer and scrum-master are refused by their own named "
        "arms; only developer may open work (a task); only quality-assurance may merge, "
        "and only when rule 7c reads APPROVE-AND-MERGE(-BOUNDARY) at the PR's head. Any "
        "other value is refused by each rule's catch-all. THE IDENTITY IS DECLARED, NOT "
        "AUTHENTICATED: a parent names the role it spawns, and a hand-written config can "
        "declare any role name.")
    notes.append(
        "TWO CONVENIENCE REFUSALS ARE NOT FORWARDED (%s=off): an env-var prefix and a "
        "stdout redirect. Measured 2026-09-21 on codex-cli 0.151.0-alpha.7.2, both "
        "COMPLETED under permissions=':workspace' while the same plain command under "
        "':read-only' was observed and did NOT complete, so the layer was in force and "
        "stopped neither. COMMAND SUBSTITUTION IS FORWARDED DESPITE THE SAME READING: it "
        "MANUFACTURES the token every other rule matches on, so omitting it made 13 of 20 "
        "irreversible fixtures reachable (rm -rf, IaC mutation, secret write, repo delete, "
        "hard reset, trunk push) against six plain-spelling controls that denied. A sound "
        "measurement can still lose. EVERY IRREVERSIBLE RULE IS FORWARDED UNCHANGED."
        % CONVENIENCE_ENV)
    notes.append(
        "RUNTIME EVIDENCE IS DATED AND THIS CHECK IS NOT A SUBSTITUTE. Installed carrier "
        "2.0.71 invoked this adapter and blocked an unquoted command substitution on "
        "2026-09-22 in Desktop 0.151.0-alpha.7.2 (permission_mode=default) and independently "
        "in VS Code 0.154.0-alpha.6.2 (payload permission_mode=bypassPermissions; no bypass "
        "flag or config mutation was used by the verifier). This proves the installed "
        "PreToolUse/Bash route on those builds, not every route, authenticated caller "
        "identity or every shell spelling. A quoted nested substitution was observed "
        "ABSTAINING and executing on 2.0.71; the SHARED guard denies those measured spellings in "
        "source at #497 (this adapter adds no policy for it), and a native re-run on an "
        "installed release carrying the repair is OWED. "
        "UserPromptSubmit separately blocked a disposable model turn on Desktop 0.151, "
        "which proves the event CAN carry this preflight; this release's new carrier "
        "registration still needs installed-version verification. See "
        "docs/codex-hook-bridge.md section 18.")
    target = log_target()
    if target is None:
        log_state = ("OFF. Nothing is written. Set it to an ABSOLUTE path to record one "
                     "JSON line per invocation — that record is the ONLY way to tell "
                     "'the runtime never called this file' from 'it called it and the "
                     "decision was discarded', which is the question this bridge could "
                     "not answer. A relative value is REFUSED, not resolved.")
    elif target[1]:
        log_state = "MISCONFIGURED — " + target[1]
    else:
        log_state = ("ON, appending to %s. A logging failure never changes a verdict."
                     % target[0])
    notes.append("INVOCATION LOG (%s): %s" % (LOG_ENV, log_state))
    notes.append(
        "TUNABLES THAT CAN AFFECT THIS FLOOR: %s (guard timeout, currently %ss) and %s "
        "(the invocation log). NAMED HERE BECAUSE AN UNSET ONE IS INVISIBLE: an "
        "operator reading this check should be able to see every knob that changes what "
        "the floor does, and the timeout was previously reported by nothing."
        % ("CODEX_HOOK_ADAPTER_TIMEOUT", GUARD_TIMEOUT, LOG_ENV))
    notes.append(
        "INTERACTIVE SESSION STARTUP: %s"
        % ("REFUSED" if REFUSE_INTERACTIVE_SESSION_STARTUP else
           "permitted, and the write_stdin gap is therefore OPEN"))

    # A report about the CURRENT directory, so an operator can ask the question on demand
    # from the project they are about to work in. It is a note in every outcome, never a
    # BLOCK: a stale persona snapshot does not stop the floor from running (#509).
    notice = snapshot_notice(os.getcwd())
    notes.append(
        "PERSONA SNAPSHOT (#509): %s On UserPromptSubmit a registered snapshot older than "
        "this plugin's VERSION, or one whose version cannot be read, is REPORTED to the "
        "model as additionalContext and never refused. Not read, so silent: registrations "
        "passed as -c flags by the builder's --exec launcher, the user-level config.toml, and "
        "a thread that started before the project config was edited."
        % (notice if notice else
           "no registered tadeumendonca_* snapshot behind this plugin was found from %s."
           % os.getcwd()))

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
    # A MIS-SET tunable is reported on EVERY invocation, before anything else runs, and
    # that repetition is the point rather than an oversight: an unset knob is silent, so
    # the presence of this line is itself the signal. The floor is NOT stopped — it runs
    # at the default — which is why this is a stderr line and not a block.
    if GUARD_TIMEOUT_DEFECT:
        sys.stderr.write("codex-hook-adapter: %s\n" % GUARD_TIMEOUT_DEFECT)
    if "--selfcheck" in argv:
        return selfcheck()
    raw = sys.stdin.read()
    payload = None
    try:
        try:
            payload = json.loads(raw)
        except ValueError:
            return abstain("payload did not parse; this act was NOT judged")
        if not isinstance(payload, dict):
            return abstain("payload is not an object; this act was NOT judged")
        return translate(payload)
    finally:
        # In a `finally` so that a CRASH still leaves a record. The three states this
        # log exists to tell apart are "the runtime never called this file", "it called
        # it and the process died" and "it called it and the decision was discarded" —
        # and the second is exactly the one a log written on the success path would
        # lose. The fields are what a reader needs to attribute a decision to an act:
        # the command, the identity used, the two working directories (they differ, and
        # the guard follows the process one), and the outcome.
        if isinstance(payload, dict):
            tool_input = payload.get("tool_input")
            command = (tool_input.get("command")
                       if isinstance(tool_input, dict) else None)
            log_invocation({
                "event": payload.get("hook_event_name"),
                "tool_name": payload.get("tool_name"),
                "command": command,
                "agent_type_raw": payload.get("agent_type"),
                "agent_type_sent": map_caller(payload),
                "payload_cwd": payload.get("cwd"),
                "permission_mode": payload.get("permission_mode"),
                "session_id": payload.get("session_id"),
                "turn_id": payload.get("turn_id"),
                "tool_use_id": payload.get("tool_use_id"),
                "outcome": OUTCOME.get("decision"),
                "reason": OUTCOME.get("reason"),
                "note": OUTCOME.get("note"),
            })
        else:
            log_invocation({"event": None, "tool_name": None, "command": None,
                            "unparsed_stdin_bytes": len(raw or ""),
                            "outcome": OUTCOME.get("decision"),
                            "note": OUTCOME.get("note")})


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
