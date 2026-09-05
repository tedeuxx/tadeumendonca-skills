#!/usr/bin/env bash
# purpose: refuse to run a session whose guards cannot run, because every hook in this repo fails open and a floor that is absent is indistinguishable from a floor that is holding
# preflight.sh — the door check. Registered twice, on two events, because the event that can
# BLOCK and the event that fires at the DOOR are not the same event in this harness.
#
#   UserPromptSubmit  BLOCKS. Nothing is processed while a blocking class is unmet.
#   SessionStart      REPORTS. It cannot block — see the measurement below — so it carries the
#                     text a human needs before they type, and the report-only classes.
#
# ── WHY THIS EXISTS (#342) ───────────────────────────────────────────────────────────────────────
#
# Every hook in `hooks/scripts/` fails open, deliberately and with the cost in front of the owner.
# What was never decided is that the failure is SILENT. `permission-guard.sh` is the worked example:
#
#   command="$(… jq -r '.tool_input.command' …)"
#   [ -z "$command" ] && exit 0
#
# One missing binary disables every rule in the largest guard in this directory and emits nothing —
# the size figure that stood here read "115 KB", was true when written and is not now, and is dropped
# rather than refreshed because nothing gates it. Not one arm — the
# recursive-delete rule, `terraform apply`, force-push, the trunk-push floor, the merge floor, every
# persona boundary, all of it, at once, quietly. The measured case — the guard emitting no decision at
# all with `jq` off `PATH`, and nobody noticing at the time — was recorded in `wip-guard.sh`'s header
# until that file was deleted (#383, 2026-09-04); it now lives in `permission-guard.sh`'s own header,
# beside the fail-open decision it argues about, which is where it should have been all along.
#
# The owner's ruling, asked as a single question and answered in one word — «bloqueante»: the session
# does not start when the guards' preconditions are absent. The cost was named to him first (a missing
# dependency and no work happens until it is fixed) and he took it.
#
# ── THE LAYER QUESTION, WHICH IS THE PART THAT DECIDED THE SHAPE (ADR-0004) ──────────────────────
#
# The Issue asks for a startup preflight. `SessionStart` CANNOT CARRY A BLOCK. Measured against the
# shipped bundle, Claude Code 2.1.251
# (/opt/homebrew/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe):
#
#   SessionStart      a hook's `blockingError` is pushed into the session's context messages
#                     (`if(pe.blockingError)U.push(IPe("SessionStart",pe.blockingError,…))`) — it
#                     becomes TEXT, not a stop. It sits in the bundle's own non-blocking event set
#                     alongside Notification, SessionEnd, Setup, SubagentStart, PostToolUseFailure.
#   UserPromptSubmit  blocks for real: `getUserPromptSubmitHookBlockingMessage`,
#                     "UserPromptSubmit operation blocked by hook:", "blocked by a UserPromptSubmit
#                     hook", "Prompt blocked: the UserPromptSubmit hooks did not run over the
#                     submitted text."
#
# This agrees with README.md's own event table, which already said SessionStart does not deny — the
# bundle read is the measurement behind it rather than a second opinion.
#
# So a *blocking* preflight is a UserPromptSubmit hook. That is not a compromise on the owner's
# ruling; it is the only layer in this harness that can hold it. And it is BETTER than a door check
# in one respect worth stating: it re-evaluates every turn, so a degradation that appears mid-session
# — `PATH` changed, a binary removed — is caught at the next prompt rather than never. A door check
# by definition cannot see that.
#
# ── WHAT BLOCKS, AND WHY IT IS THIS SET AND NOT THE ISSUE'S THREE BULLETS ────────────────────────
#
# BLOCKING CLASSES — the floor is absent, the determination is local and deterministic, and the
# repair is OUTSIDE the session (which is what makes blocking survivable rather than a brick):
#
#   A  an interpreter a registered hook reaches for is not on PATH
#   B  a script hooks.json registers is missing or not executable
#   C  the static deny layer is off AND nobody is there to read a warning
#      (permission_mode = bypassPermissions and prompt source = sdk)
#
# REPORT-ONLY CLASSES — real, and blocking on them would make this control fire routinely, which is
# the failure mode a blocking control has: people learn to bypass it, and a bypassed floor is worse
# than an honest warning.
#
#   D  permission_mode = bypassPermissions with a human present. The static deny is genuinely off,
#      and the human typed the flag that turned it off. Blocking here would forbid the one mode a
#      headless factory needs; reporting keeps the loss visible without confiscating the mode.
#
# DELIBERATELY NOT HERE — the Issue's third bullet, the installed plugin version. Two reasons, and
# the first is a measurement: at the time of writing the installed marketplace build is 1.1.35
# against a source of 1.1.43, and this repo publishes a release on EVERY merge to main, so the
# installed build lags the source as the normal state rather than the exceptional one. A blocking
# preflight on version drift would refuse nearly every session, which trains a bypass. The second
# reason is that `session-plugin-version.sh` already reports it, and one fact deserves one reader.
#
# ── WHAT THIS CANNOT CATCH, SAID HERE BECAUSE A FALSE REASSURANCE IS THE THING IT REPLACES ───────
#
#   * AUTH AND NETWORK. `gh` on PATH is not `gh` authenticated, and auth expires mid-session. This
#     checks that the binary exists, nothing more. #341's fix — the merge floor denying when it
#     cannot READ the gatekeeper's verdict — is NOT subsumed by this and must not be: that failure
#     arrives at the irreversible act, hours after this door check passed.
#   * WHETHER THE DENY LIST IS LOADED. A hook receives a payload, not the effective permission set.
#     `permission_mode` is the closest observable and it is what class C/D read; a session whose
#     settings.json was never loaded for some other reason looks identical to one where it was.
#   * WHETHER hooks.json REGISTERED AT ALL. If it did not, this file never runs, and its silence is
#     indistinguishable from a clean pass. That is unfixable from inside a hook, by construction.
#   * A SUBAGENT. UserPromptSubmit does not fire for a dispatched persona. The blocking half covers
#     the main thread only.
#
# A door that refuses is not a floor that holds: this stops a degraded session, it does not make any guard fail closed.
#
# ── SELF-CONSISTENCY: THIS SCRIPT MUST NOT NEED WHAT IT CHECKS ──────────────────────────────────
#
# It parses its payload with shell builtins and `sed`, never `jq` — a dependency check that depends
# on the thing it checks is the same defect one level up. It emits its refusal as plain stderr with
# exit 2, which needs no JSON encoder. And it errs toward ALLOWING on any internal failure of its
# own: a preflight that bricks a session because IT broke is a worse outcome than the one it guards.
#
# ── ONE THING AT A TIME ─────────────────────────────────────────────────────────────────────────
#
# The refusal names exactly ONE finding and how to fix it, and says how many remain without listing
# them. The owner's standing rule: a batch of findings is a decision list, and a decision list makes
# him rebuild context per item.

set -uo pipefail

# ── EVERYTHING FROM HERE TO THE DERIVATION IS BASH BUILTINS ONLY, AND THAT IS NOT FASTIDIOUSNESS ──
#
# The first draft of this file used `cat`, `dirname`, `sed`, `tr` and `head` before it reached its
# own dependency check. Its own suite caught it: on a PATH without coreutils the script died at
# `dirname` and exited 0 — FAILING OPEN, which is the exact defect it exists to remove, reproduced
# inside the fix for it. Reading stdin, resolving its own directory and parsing its payload are now
# done with `read`, `${0%/*}` and bash pattern matching, none of which fork anything.
payload=""
IFS= read -r -d '' payload || true

# Extract a top-level string field. Pure bash: strip everything up to the key, then take the quoted
# value. Anchoring on `"<key>":` after a `{` or `,` keeps a value that happens to contain the key's
# own text — a prompt quoting "permission_mode", say — from being read as the field.
field() {
  local rest="$payload" key="$1" v
  case "$rest" in
    *"\"$key\":"*)  v="${rest#*\""$key"\":}" ;;
    *"\"$key\" :"*) v="${rest#*\""$key"\" :}" ;;
    *) printf '' ; return 0 ;;
  esac
  v="${v#"${v%%[!  ]*}"}"          # drop leading spaces/tabs
  case "$v" in
    \"*) v="${v#\"}"; printf '%s' "${v%%\"*}" ;;
    *)   printf '' ;;
  esac
}

event="$(field hook_event_name)"
permission_mode="$(field permission_mode)"
prompt_source="$(field source)"

SCRIPT_DIR="${0%/*}"
[ "$SCRIPT_DIR" = "$0" ] && SCRIPT_DIR="."
HOOKS_JSON="$SCRIPT_DIR/../hooks.json"

# ── THE BOOTSTRAP SET FAILS CLOSED, WHICH IS THE OPPOSITE OF EVERY OTHER HOOK HERE ───────────────
#
# The derivation below reads files with `grep`, `awk` and `sort`. If those are gone the script cannot
# work out what is missing — and a check that cannot run must not report a clean result. This is the
# one place in this harness that fails CLOSED on its own dependency, and it is defensible precisely
# because it is the only one: it denies a prompt, never an irreversible act, and the repair is a
# `PATH` fix outside the session.
bootstrap_missing=""
for _b in grep awk sort; do
  command -v "$_b" >/dev/null 2>&1 && continue
  bootstrap_missing="$bootstrap_missing $_b"
done
bootstrap_missing="${bootstrap_missing# }"

# ── The registered set is DERIVED, never remembered ──────────────────────────────────────────────
#
# The owner's instruction, verbatim: "Enumerate from the scripts, not from memory — a preflight that
# checks a list somebody wrote down is a second source of truth that drifts away from the guards it
# protects." So the scripts come out of hooks.json and the interpreters come out of those scripts.
# Add a hook that DECLARES `python3` with `command -v` and this starts requiring `python3` with no edit
# here.
#
# THE BLIND SPOT, NAMED BECAUSE THE CONSEQUENCE IS QUOTED ELSEWHERE WITHOUT THIS SENTENCE. The scan
# reads a DECLARATION, not a call graph. A hook that reaches for `python3` with a bare call, with
# `hash`, with `type`, or through `command -v "$var"` contributes NO requirement — the preflight stays
# green and that hook still dies at runtime. Nothing here detects an undeclared dependency and nothing
# can at this grain; what compensates is that every hook in this directory already opens with its
# `command -v` probes, so a new one that does not is a review finding rather than a gate finding.
registered=""
if [ -z "$bootstrap_missing" ] && [ -r "$HOOKS_JSON" ]; then
  registered="$(grep -oE 'hooks/scripts/[A-Za-z0-9._-]+\.sh' "$HOOKS_JSON" | sort -u || true)"
fi

# Class A — interpreters. Derived from `command -v <x>` in the registered scripts only. Test suites
# are out of scope for the same reason hooks-executable.test.sh excludes them: the harness never
# invokes them, so a dependency of theirs is not a dependency of the floor.
missing_deps=""
if [ -n "$registered" ]; then
  while IFS= read -r rel; do
    [ -z "$rel" ] && continue
    f="$SCRIPT_DIR/../../$rel"
    [ -r "$f" ] || continue
    while IFS= read -r dep; do
      [ -z "$dep" ] && continue
      command -v "$dep" >/dev/null 2>&1 && continue
      case " $missing_deps " in *" $dep "*) ;; *) missing_deps="$missing_deps $dep" ;; esac
    done <<EOF
$(grep -ohE 'command -v [A-Za-z0-9_.-]+' "$f" | awk '{print $3}' | sort -u)
EOF
  done <<EOF
$registered
EOF
fi
missing_deps="${missing_deps# }"

# Class B — the registered scripts themselves. A hook committed non-executable dies at runtime with
# "Permission denied" while every logic suite stays green; hooks-executable.test.sh asserts the
# committed mode, and this asserts the mode that is actually on this machine, which is not the same
# claim once a tarball, a volume mount or a COPY has been between them.
missing_scripts=""
if [ -n "$registered" ]; then
  while IFS= read -r rel; do
    [ -z "$rel" ] && continue
    f="$SCRIPT_DIR/../../$rel"
    if [ ! -f "$f" ]; then
      missing_scripts="$missing_scripts $rel(absent)"
    elif [ ! -x "$f" ]; then
      missing_scripts="$missing_scripts $rel(not-executable)"
    fi
  done <<EOF
$registered
EOF
fi
missing_scripts="${missing_scripts# }"

# Class C/D — the static deny layer.
#
# `permission_mode` is carried on every hook payload (measured: the common base object is
# `{session_id, transcript_path, cwd, prompt_id, permission_mode, agent_id, agent_type, effort}`),
# and `bypassPermissions` is the value `--dangerously-skip-permissions` sets. This is a PAYLOAD read
# — no subprocess, no file, no network — which is the only class of check in this harness that
# degrades loudly rather than silently.
#
# WHY THE SPLIT ON `source` RATHER THAN A FLAT BLOCK. UserPromptSubmit's payload carries
# `source` ∈ {user, sdk, system, loop_wakeup, schedule_wakeup, poll_event}, and the bundle documents
# `sdk` as "non-interactive entrypoint (-p / Agent SDK)" — exactly the container worker this Issue
# was filed about. With a human present, the flag was typed by the person who will read the warning,
# and blocking would confiscate a mode the owner may legitimately want. With no human, a warning has
# no reader, which is the precise failure this whole Issue exists to remove.
bypass_active=0
[ "$permission_mode" = "bypassPermissions" ] && bypass_active=1
headless=0
[ "$prompt_source" = "sdk" ] && headless=1

# ── Findings, in the order they are surfaced. One at a time. ─────────────────────────────────────
finding_kind=""
finding_text=""
blocking_total=0

add_blocking() {
  blocking_total=$((blocking_total + 1))
  [ -n "$finding_kind" ] && return 0
  finding_kind="$1"
  finding_text="$2"
}

if [ -n "$bootstrap_missing" ]; then
  add_blocking "bootstrap" "NOT ON PATH: $bootstrap_missing

This preflight reads hooks.json and the hook scripts to work out what the floor needs. Without the
binaries above it cannot read them, so it cannot tell a healthy harness from an inert one — and a
check that cannot run must not report a clean result. It is refusing rather than guessing.

FIX: install the binaries above and start a new session."
fi

if [ -n "$missing_deps" ]; then
  add_blocking "dependency" "NOT ON PATH: $missing_deps

Every guard in this harness fails open on a missing interpreter, and it fails open SILENTLY: the hook
emits nothing and the harness reads that as 'no decision'. With \`jq\` gone, permission-guard.sh exits
before rule 1 — the merge floor, the trunk-push floor, \`terraform apply\`, force-push, \`rm -rf\`,
secret writes and every persona boundary are unguarded, and nothing anywhere says so.

FIX: install the binaries above and start a new session. This check re-runs on every prompt, so a
repair takes effect without a restart once the binary is on the PATH this process inherits."
fi

if [ -n "$missing_scripts" ]; then
  add_blocking "script" "REGISTERED BUT UNRUNNABLE: $missing_scripts

hooks.json names these and the harness invokes them by bare path. An absent file, or one without the
execute bit, dies at runtime with 'Permission denied' — which the harness reads as no decision, the
same silent open as a missing interpreter.

FIX: reinstall or update the plugin (\`/plugin marketplace update tadeumendonca\`, then update
tadeumendonca-skills), or restore the execute bit on the paths above."
fi

if [ "$bypass_active" -eq 1 ] && [ "$headless" -eq 1 ]; then
  add_blocking "bypass" "HEADLESS SESSION RUNNING WITH THE STATIC DENY LAYER OFF.

permission_mode is 'bypassPermissions' and the prompt source is 'sdk' (a non-interactive -p / Agent
SDK entrypoint). The settings.json \`deny\` block is the one layer in this harness with no runtime
dependency at all, and permission-guard.sh's own header names it as the compensating control for its
fail-open. Under the flag it compensates for nothing — and with no human on this session, a warning
about that has no reader.

FIX: run the worker WITHOUT --dangerously-skip-permissions and ship a settings.json in the image that
grants what the worker needs. The deny perimeter is a file; make it a file the container has, rather
than a flag that removes the question."
fi

# ── Emit ─────────────────────────────────────────────────────────────────────────────────────────

remainder_note() {
  n=$((blocking_total - 1))
  if [ "$n" -gt 0 ]; then
    printf '\n%s further blocking finding(s) are outstanding and are deliberately not listed here.\nFix this one; the next prompt surfaces the next.\n' "$n"
  fi
}

case "$event" in
  UserPromptSubmit)
    if [ -n "$finding_kind" ]; then
      printf 'HARNESS PREFLIGHT — REFUSING TO RUN DEGRADED (#342)\n\n%s\n' "$finding_text" >&2
      remainder_note >&2
      exit 2
    fi
    exit 0
    ;;
  SessionStart)
    # SessionStart cannot block (measured, see the header). It reports — and it is the only place the
    # report-only class D is surfaced, because a warning repeated on every prompt is a warning nobody
    # reads by the third turn.
    notice=""
    if [ -n "$finding_kind" ]; then
      notice="HARNESS PREFLIGHT — THIS SESSION IS DEGRADED AND WILL BE REFUSED AT THE FIRST PROMPT (#342)

$finding_text"
      n=$((blocking_total - 1))
      [ "$n" -gt 0 ] && notice="$notice

$n further blocking finding(s) outstanding, not listed — one at a time by design."
    fi

    if [ "$bypass_active" -eq 1 ] && [ "$headless" -eq 0 ]; then
      d="STATIC DENY LAYER IS OFF THIS SESSION — permission_mode is 'bypassPermissions'.

This is REPORTED, not refused: a human is present, and the flag that turned the layer off was typed
by the person reading this. What is lost is the layer permission-guard.sh names as its own backstop
— every deny that exists only as a settings.json literal (force-push, --tags, git reset --hard,
git clean -f, gh workflow run, gh release create/delete, gh repo delete/archive/rename, gh secret
set/delete, rm -rf and its spellings, gh pr merge --squash) has no second reader this session.

The hook layer still runs — this notice is proof of it — so rules born in permission-guard.sh are
intact. The two layers were designed independent; under this flag only one of them is present."
      if [ -n "$notice" ]; then notice="$notice

────────────────────────────────────────────────────────────────────────────────

$d"; else notice="$d"; fi
    fi

    [ -z "$notice" ] && exit 0

    if command -v jq >/dev/null 2>&1; then
      jq -n --arg c "$notice" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'
    else
      # The branch that matters most: a missing `jq` is the headline finding, so the notice carrying
      # it must not be encoded by `jq`. Same reasoning as session-plugin-version.sh's own fallback —
      # done with bash substitution rather than that file's `sed | awk`, because a machine missing
      # `jq` is exactly the machine whose `sed` should not be assumed either.
      escaped="${notice//\\/\\\\}"
      escaped="${escaped//\"/\\\"}"
      escaped="${escaped//$'\n'/\\n}"
      printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$escaped"
    fi
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
