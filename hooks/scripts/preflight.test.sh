#!/usr/bin/env bash
# Suite for preflight.sh — the door check that refuses a degraded session (#342).
#
# WHAT THIS SUITE IS BUILT AGAINST. The defect class this repo keeps finding is an assertion that
# cannot fail: a check that passes on the unmutated tree and also passes on the mutation it claims to
# catch. So every arm here is paired — a CONTROL that must pass and a PROBE that must fail — and the
# degradation is produced by MUTATING THE WORLD the script reads (a shadowed PATH, a chmod'd file, a
# rewritten hooks.json in a scratch copy), never by asking the script to report on itself.
#
# The PATH mutations use a scratch directory holding a shim that is not executable, which is the
# cheapest way to make `command -v <x>` fail without uninstalling anything: `command -v` consults
# PATH, so a PATH that contains only directories without the binary is enough.
#
# Run: bash hooks/scripts/preflight.test.sh

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GUARD="$ROOT/hooks/scripts/preflight.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

ok()  { pass=$((pass + 1)); printf 'ok    %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }

# Run the guard over a payload file, optionally with a replacement PATH and a replacement plugin
# root. Prints "<exit>|<stdout>|<stderr>" so an arm can assert on any of the three.
# `bash` itself is resolved by ABSOLUTE PATH, not through the replaced PATH. The first draft did not
# and every degraded arm returned 127 "env: bash: No such file or directory" — the suite was
# measuring its own inability to launch the guard and reporting it as the guard failing to block.
BASH_ABS="$(command -v bash)"
run() {
  _payload="$1"; _path="${2:-$PATH}"; _guard="${3:-$GUARD}"
  _out="$TMP/out.$$"; _err="$TMP/err.$$"
  env PATH="$_path" "$BASH_ABS" "$_guard" <"$_payload" >"$_out" 2>"$_err"
  _code=$?
  printf '%s|%s|%s' "$_code" "$(cat "$_out")" "$(cat "$_err")"
}

payload() {
  printf '%s' "$2" > "$TMP/$1.json"
  printf '%s' "$TMP/$1.json"
}

P_CLEAN="$(payload clean '{"session_id":"s","cwd":"/x","permission_mode":"default","hook_event_name":"UserPromptSubmit","prompt":"go","source":"user"}')"
P_SDK_BYPASS="$(payload sdkbypass '{"session_id":"s","cwd":"/x","permission_mode":"bypassPermissions","hook_event_name":"UserPromptSubmit","prompt":"go","source":"sdk"}')"
P_USER_BYPASS="$(payload userbypass '{"session_id":"s","cwd":"/x","permission_mode":"bypassPermissions","hook_event_name":"UserPromptSubmit","prompt":"go","source":"user"}')"
P_SS_CLEAN="$(payload ssclean '{"session_id":"s","cwd":"/x","permission_mode":"default","hook_event_name":"SessionStart","source":"startup"}')"
P_SS_BYPASS="$(payload ssbypass '{"session_id":"s","cwd":"/x","permission_mode":"bypassPermissions","hook_event_name":"SessionStart","source":"startup"}')"
P_OTHER="$(payload other '{"session_id":"s","cwd":"/x","permission_mode":"default","hook_event_name":"PreToolUse","tool_name":"Bash"}')"

# Two mutated PATHs, because the two degradations they produce are DIFFERENT CLASSES and collapsing
# them was this suite's own first defect: an empty PATH takes out `grep`/`awk`/`sort` too, so it
# fires the bootstrap class and never reaches the derived one. The arm that thought it was testing
# `jq` was testing something else and passing.
#
#   EMPTY_PATH  nothing at all → the bootstrap class (the preflight cannot read anything)
#   JQLESS      a PATH carrying the bootstrap set and the ordinary tools but NOT `jq`/`gh` → the
#               derived class, which is the one the Issue is actually about
EMPTY_PATH="$TMP/nobin"
mkdir -p "$EMPTY_PATH"
JQLESS="$TMP/jqless"
mkdir -p "$JQLESS"
for b in bash sed awk grep cat tr sort head uniq env printf chmod mktemp rm cp; do
  p="$(command -v "$b" || true)"
  [ -n "$p" ] && ln -sf "$p" "$JQLESS/$b"
done

# ── 1 · CONTROL: a healthy tree on a real PATH is silent and allows ─────────────────────────────
r="$(run "$P_CLEAN")"
if [ "${r%%|*}" = "0" ]; then
  ok "control — UserPromptSubmit on a healthy tree exits 0"
else
  bad "control — UserPromptSubmit on a healthy tree exited ${r%%|*}, expected 0. Every probe below is meaningless if this is red."
fi
if [ "$r" = "0||" ]; then
  ok "control — and emits nothing on stdout or stderr (a step that found nothing must not read like one that did)"
else
  bad "control — emitted output on a healthy tree: $r"
fi

# ── 2 · PROBE: interpreters missing → BLOCKS ────────────────────────────────────────────────────
# This is the arm the whole Issue is about. permission-guard.sh loses every rule to a missing `jq`
# and says nothing; this must say something and must stop the turn.
r="$(run "$P_CLEAN" "$JQLESS")"
if [ "${r%%|*}" = "2" ]; then
  ok "class A — a PATH without \`jq\` blocks the prompt with exit 2"
else
  bad "class A — a jq-less PATH exited ${r%%|*}, expected 2 (block). A preflight that allows here is the failure it was built to remove."
fi
case "$r" in
  *"NOT ON PATH"*jq*) ok "class A — the refusal names \`jq\` specifically, not just 'degraded'" ;;
  *) bad "class A — the refusal does not name the missing interpreter: $r" ;;
esac
case "$r" in
  *"FIX:"*) ok "class A — the refusal carries a FIX line (a blocking preflight that teaches nothing costs a session for free)" ;;
  *) bad "class A — no FIX line in the refusal" ;;
esac

# The bootstrap class is separate and must be reachable on its own terms — it is the only place in
# this harness where a check fails CLOSED on its own dependency.
r="$(run "$P_CLEAN" "$EMPTY_PATH")"
case "$r" in
  2*"NOT ON PATH"*grep*)
    ok "bootstrap — a PATH with nothing on it blocks, naming the tools the preflight itself needs"
    ;;
  *)
    bad "bootstrap — a preflight that cannot read anything did not refuse: $r
      A check that cannot run must not report a clean result."
    ;;
esac

# ── 3 · THE DERIVATION IS REAL, NOT A HARDCODED LIST ────────────────────────────────────────────
# The owner's instruction was explicit: enumerate from the scripts, not from memory. So mutate the
# SCRIPTS and require the requirement set to move with them. A scratch copy of the plugin whose one
# registered hook reaches for a binary that exists nowhere must block on THAT binary's name — a name
# that appears nowhere in preflight.sh.
FAKE="$TMP/fakeplugin"
mkdir -p "$FAKE/hooks/scripts"
cp "$GUARD" "$FAKE/hooks/scripts/preflight.sh"
printf '{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"${CLAUDE_PLUGIN_ROOT}/hooks/scripts/madeup.sh"}]}]}}' > "$FAKE/hooks/hooks.json"
printf '#!/usr/bin/env bash\ncommand -v zzunobtainium >/dev/null 2>&1 || exit 0\n' > "$FAKE/hooks/scripts/madeup.sh"
chmod +x "$FAKE/hooks/scripts/madeup.sh"
r="$(run "$P_CLEAN" "$PATH" "$FAKE/hooks/scripts/preflight.sh")"
case "$r" in
  2*zzunobtainium*)
    ok "derivation — a dependency invented in a registered script is required, though its name is nowhere in preflight.sh"
    ;;
  *)
    bad "derivation — the requirement set did not follow the scripts: $r
      This is the arm that separates a derived check from a list somebody wrote down."
    ;;
esac

# CONTROL for the arm above: same scratch plugin, dependency satisfiable → silent. Without this, the
# arm above passes for any reason at all, including the guard blocking unconditionally in a scratch
# tree.
printf '#!/usr/bin/env bash\ncommand -v sed >/dev/null 2>&1 || exit 0\n' > "$FAKE/hooks/scripts/madeup.sh"
r="$(run "$P_CLEAN" "$PATH" "$FAKE/hooks/scripts/preflight.sh")"
if [ "${r%%|*}" = "0" ]; then
  ok "derivation (control) — the same scratch plugin with a satisfiable dependency allows"
else
  bad "derivation (control) — the scratch plugin blocked with a satisfiable dependency: $r"
fi

# ── 4 · PROBE: a registered script that is not executable → BLOCKS ──────────────────────────────
# hooks-executable.test.sh asserts the COMMITTED mode. That is not the same claim as the mode on the
# machine after a tarball, a volume mount or a container COPY has been between the two.
chmod -x "$FAKE/hooks/scripts/madeup.sh"
r="$(run "$P_CLEAN" "$PATH" "$FAKE/hooks/scripts/preflight.sh")"
case "$r" in
  2*not-executable*)
    ok "class B — a registered script without the execute bit blocks, and the refusal says which"
    ;;
  *)
    bad "class B — a non-executable registered hook did not block: $r"
    ;;
esac

rm -f "$FAKE/hooks/scripts/madeup.sh"
r="$(run "$P_CLEAN" "$PATH" "$FAKE/hooks/scripts/preflight.sh")"
case "$r" in
  2*absent*)
    ok "class B — a registered script that is missing entirely blocks, and the refusal says which"
    ;;
  *)
    bad "class B — an absent registered hook did not block: $r"
    ;;
esac

# ── 5 · CLASS C: headless + bypass BLOCKS · interactive + bypass does NOT ───────────────────────
# The split is the design decision and both halves have to be asserted, or the arm proves only that
# the script reacts to the word bypassPermissions.
r="$(run "$P_SDK_BYPASS")"
if [ "${r%%|*}" = "2" ]; then
  ok "class C — bypassPermissions with source=sdk (headless) blocks"
else
  bad "class C — a headless session with the deny layer off was allowed: $r"
fi
case "$r" in
  *"HEADLESS"*) ok "class C — the refusal names the headless condition rather than a generic degradation" ;;
  *) bad "class C — the refusal does not name the condition: $r" ;;
esac

r="$(run "$P_USER_BYPASS")"
if [ "${r%%|*}" = "0" ]; then
  ok "class D — bypassPermissions with a human present does NOT block (reported at SessionStart instead)"
else
  bad "class D — an interactive session was blocked for a flag its own operator typed: $r
      Blocking here confiscates a mode the owner may legitimately want and trains a bypass."
fi

# ── 6 · SessionStart REPORTS and never blocks ───────────────────────────────────────────────────
# Measured against the shipped bundle: SessionStart cannot deny. An arm that expected it to would be
# asserting something the harness cannot do.
r="$(run "$P_SS_BYPASS")"
if [ "${r%%|*}" = "0" ]; then
  ok "SessionStart — exits 0 even with a finding (it cannot block; pretending otherwise is theatre)"
else
  bad "SessionStart — exited ${r%%|*}, expected 0"
fi
case "$r" in
  0*additionalContext*) ok "SessionStart — emits a SessionStart additionalContext payload" ;;
  *) bad "SessionStart — no additionalContext emitted for a reportable finding: $r" ;;
esac
case "$r" in
  *"STATIC DENY LAYER IS OFF"*) ok "SessionStart — the interactive-bypass notice is where class D is surfaced" ;;
  *) bad "SessionStart — class D is not reported: $r" ;;
esac

r="$(run "$P_SS_CLEAN")"
if [ "$r" = "0||" ]; then
  ok "SessionStart (control) — silent on a healthy tree"
else
  bad "SessionStart (control) — emitted something on a healthy tree: $r"
fi

# ── 7 · THE NOTICE SURVIVES A MISSING jq, WHICH IS THE CASE IT EXISTS FOR ───────────────────────
# A dependency notice encoded by the dependency it reports on is the defect one level up. The
# SessionStart branch has a hand-rolled fallback for exactly this; assert it fires.
r="$(run "$P_SS_CLEAN" "$JQLESS")"
case "$r" in
  0*additionalContext*jq*)
    ok "no-jq — SessionStart still emits a valid-shaped notice naming \`jq\`, without using \`jq\` to encode it"
    ;;
  *)
    bad "no-jq — the notice that exists for a missing jq could not be emitted without jq: $r"
    ;;
esac

r="$(run "$P_CLEAN" "$JQLESS")"
if [ "${r%%|*}" = "2" ]; then
  ok "no-jq — and the prompt is refused, which is the whole ruling («bloqueante»)"
else
  bad "no-jq — a session with the permission guard inert was allowed to proceed: $r"
fi

# ── 8 · ONE THING AT A TIME ─────────────────────────────────────────────────────────────────────
# The owner's standing rule. With several classes unmet at once the refusal must name ONE and say a
# remainder exists — not print a decision list.
r="$(run "$P_SDK_BYPASS" "$EMPTY_PATH")"
case "$r" in
  *"further blocking finding"*)
    ok "one-at-a-time — with several classes unmet the refusal names one and counts the rest"
    ;;
  *)
    bad "one-at-a-time — no remainder note with multiple findings outstanding: $r"
    ;;
esac
n="$(printf '%s' "$r" | grep -c 'FIX:' || true)"
if [ "$n" = "1" ]; then
  ok "one-at-a-time — exactly one FIX line, so the refusal is one decision rather than a list"
else
  bad "one-at-a-time — $n FIX line(s) in a single refusal; the rule is one"
fi

# ── 9 · AN UNREGISTERED EVENT IS A NO-OP ────────────────────────────────────────────────────────
# The script is wired to two events. If it is ever wired to a third by accident it must do nothing
# rather than block a tool call, which would take the whole harness down.
r="$(run "$P_OTHER" "$EMPTY_PATH")"
if [ "$r" = "0||" ]; then
  ok "unknown event — a payload for an event this hook is not wired to is a silent no-op, even degraded"
else
  bad "unknown event — the guard acted on an event it is not registered for: $r"
fi

# ── 10 · REGISTRATION ───────────────────────────────────────────────────────────────────────────
# A guard that is not registered is a file. Assert both registrations, by event, so removing either
# reddens rather than going quiet.
HJ="$ROOT/hooks/hooks.json"
if grep -qE '"UserPromptSubmit"' "$HJ"; then
  ok "registration — hooks.json declares a UserPromptSubmit array"
else
  bad "registration — no UserPromptSubmit array in hooks.json; the BLOCKING half of this control does not exist"
fi
ups_block="$(awk '/"UserPromptSubmit"/{f=1} f&&/preflight\.sh/{print "y"; exit}' "$HJ")"
if [ "$ups_block" = "y" ]; then
  ok "registration — preflight.sh is registered under UserPromptSubmit"
else
  bad "registration — preflight.sh is not registered under UserPromptSubmit"
fi
ss_block="$(awk '/"SessionStart"/{f=1} f&&/preflight\.sh/{print "y"; exit}' "$HJ")"
if [ "$ss_block" = "y" ]; then
  ok "registration — preflight.sh is registered under SessionStart"
else
  bad "registration — preflight.sh is not registered under SessionStart"
fi

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
