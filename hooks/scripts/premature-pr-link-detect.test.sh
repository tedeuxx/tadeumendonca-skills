#!/usr/bin/env bash
# premature-pr-link-detect.test.sh — does the Stop hook fire exactly when the turn handed the owner a
# PR link he cannot act on, and stay silent (and cheap) when the link was legitimate?
#
# BOTH ARMS ARE MANDATORY AND NEITHER IS SUFFICIENT ALONE. A detector that fires on everything is as
# useless as one that fires on nothing: the "fires" arms alone are satisfied by a hook that emits
# unconditionally, and the "silent" arms alone are satisfied by a hook that emits never. Every
# assertion below was verified by MUTATING THE HOOK — the source, never the test — and watching this
# suite go red; the mutations and their before/after are recorded on the MR that introduced this file.
#
# THE TRAP THAT MAKES A MUTATION PROBE WORTHLESS, stated because this workspace has been bitten by it
# repeatedly: a probe that silently fails to mutate (a `sed` pattern that matches nothing, an edit
# applied to a copy the suite does not run) produces a green indistinguishable from a working gate.
# Confirm the mutation landed — diff the file — before believing the red or the green.
#
# Uses a REAL temporary git repository, like `zombie-loop-detect.test.sh`, because the hook calls
# `git rev-parse --git-dir` for real and holds its debounce state there. `gh` IS a stub: it serves
# fixtures and LOGS every invocation, so the "zero network calls" assertions can COUNT calls rather
# than infer them from silence — the difference between asserting a cost and hoping for one.

set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/premature-pr-link-detect.sh"
pass=0
fail=0

ok()  { printf 'ok    %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL  %s\n     %s\n' "$1" "$2"; fail=$((fail + 1)); }

setup() {
  root="$(mktemp -d)"
  repo="$root/repo"
  mkdir -p "$repo" "$root/bin" "$root/fix"
  git -C "$repo" init -q -b main
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config user.name test
  printf 'x\n' > "$repo/f"
  git -C "$repo" add f
  git -C "$repo" commit -q -m init

  : > "$root/calls.log"
  transcript="$root/transcript.jsonl"
  : > "$transcript"

  cat > "$root/bin/gh" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "__CALLLOG__"
case "$1 $2" in
  "pr view")
    if [ -f "__FIXDIR__/pr-$3.json" ]; then cat "__FIXDIR__/pr-$3.json"
    elif [ -f "__FIXDIR__/pr.json" ]; then cat "__FIXDIR__/pr.json"
    fi ;;
esac
exit 0
STUB
  sed -i.bak "s#__CALLLOG__#$root/calls.log#g; s#__FIXDIR__#$root/fix#g" "$root/bin/gh"
  rm -f "$root/bin/gh.bak"
  chmod +x "$root/bin/gh"
}

teardown() { rm -rf "$root"; }

# ── transcript fixture builders — one JSON object per line, the shape Claude Code writes ─────────
human_turn() { # text
  jq -nc --arg t "$1" '{type:"user", message:{content:$t}}' >> "$transcript"
}
assistant_text() { # text
  jq -nc --arg t "$1" '{type:"assistant", message:{content:[{type:"text", text:$t}]}}' >> "$transcript"
}
assistant_tool_use() { # command
  jq -nc --arg c "$1" '{type:"assistant", message:{content:[{type:"tool_use", name:"Bash", input:{command:$c}}]}}' >> "$transcript"
}
tool_result() { # text — a tool's OWN stdout coming back, e.g. what `gh pr create` prints
  jq -nc --arg t "$1" '{type:"user", message:{content:[{type:"tool_result", content:$t}]}}' >> "$transcript"
}

# ── PR fixtures ─────────────────────────────────────────────────────────────────────────────────
checks_green='[{"__typename":"CheckRun","status":"COMPLETED","conclusion":"SUCCESS"}]'
checks_running='[{"__typename":"CheckRun","status":"COMPLETED","conclusion":"SUCCESS"},{"__typename":"CheckRun","status":"IN_PROGRESS","conclusion":null}]'
checks_failing='[{"__typename":"CheckRun","status":"COMPLETED","conclusion":"FAILURE"}]'
checks_none='[]'

pr_fixture() { # state · head · checks_json · verdict ("" for no verdict comment) · [file suffix]
  local state="$1" head="$2" checks="$3" verdict="$4" suffix="${5:-}"
  local out="$root/fix/pr.json"
  [ -n "$suffix" ] && out="$root/fix/pr-$suffix.json"
  if [ -z "$verdict" ]; then
    jq -n --arg s "$state" --arg h "$2" --argjson c "$checks" \
      '{state:$s, headRefOid:$h, statusCheckRollup:$c, comments:[]}' > "$out"
  else
    jq -n --arg s "$state" --arg h "$2" --argjson c "$checks" \
      --arg body "<!-- gatekeeper-verdict: quality-assurance -->
$verdict
head: $2" \
      '{state:$s, headRefOid:$h, statusCheckRollup:$c, comments:[{body:$body, authorAssociation:"OWNER"}]}' > "$out"
  fi
}

run_hook() { # [session_id]
  payload="$(jq -n --arg cwd "$repo" --arg tp "$transcript" --arg sid "${1:-sess-1}" \
    '{cwd:$cwd, transcript_path:$tp, session_id:$sid}')"
  ( export PATH="$root/bin:/usr/bin:/bin"
    printf '%s' "$payload" | "$BASH" "$HOOK" 2>/dev/null )
}

gh_calls() { wc -l < "$root/calls.log" | tr -d ' '; }
view_calls() { grep -c '^pr view' "$root/calls.log" 2>/dev/null || true; }

URL='https://github.com/tedeuxx/tadeumendonca-skills/pull/150'

# ══════════════════════════════════════════════════════════════════════════════════════════════
# ARM A — IT FIRES. The turn surfaced a link the owner cannot act on.
# ══════════════════════════════════════════════════════════════════════════════════════════════
echo '--- the failure this exists for: a link handed over while a check is still running ---'
setup
human_turn "keep going"
assistant_text "Opened the PR: $URL"
pr_fixture OPEN abc123 "$checks_running" APPROVE-PENDING-HUMAN
out="$(run_hook)"
case "$out" in
  *"$URL"*) ok 'notice names the URL that was surfaced' ;;
  *) bad 'notice names the URL that was surfaced' "got: ${out:-<empty>}" ;;
esac
case "$out" in
  *'still running'*) ok 'notice states WHY it is premature' ;;
  *) bad 'notice states WHY it is premature' "got: ${out:-<empty>}" ;;
esac
case "$out" in
  *'hookSpecificOutput'*'"Stop"'*) ok 'emits Stop hookSpecificOutput' ;;
  *) bad 'emits Stop hookSpecificOutput' "got: $out" ;;
esac
teardown

echo '--- a failing check is the loop'"'"'s to fix, not his to look at ---'
setup
human_turn "go"
assistant_text "PR is up: $URL"
pr_fixture OPEN abc123 "$checks_failing" APPROVE-PENDING-HUMAN
out="$(run_hook)"
if [ -n "$out" ]; then ok 'fires when a check failed'; else bad 'fires when a check failed' 'got empty'; fi
teardown

echo '--- no check has reported at all: "todos check concluidos" cannot be true of it ---'
setup
human_turn "go"
assistant_text "PR is up: $URL"
pr_fixture OPEN abc123 "$checks_none" APPROVE-PENDING-HUMAN
out="$(run_hook)"
if [ -n "$out" ]; then ok 'fires on an empty check rollup (not treated as green)'; else bad 'fires on an empty check rollup' 'got empty'; fi
teardown

echo '--- green and merge-ready, but the GATE acts on it itself: still not his ---'
setup
human_turn "go"
assistant_text "PR is up: $URL"
pr_fixture OPEN abc123 "$checks_green" APPROVE-AND-MERGE-BOUNDARY
out="$(run_hook)"
case "$out" in
  *'APPROVE-AND-MERGE-BOUNDARY'*) ok 'fires on a clearance verdict, naming it' ;;
  *) bad 'fires on a clearance verdict, naming it' "got: ${out:-<empty>}" ;;
esac
teardown

echo '--- green, but no verdict at this head: the gate has not run ---'
setup
human_turn "go"
assistant_text "PR is up: $URL"
pr_fixture OPEN abc123 "$checks_green" ""
out="$(run_hook)"
if [ -n "$out" ]; then ok 'fires when no verdict has been posted'; else bad 'fires when no verdict has been posted' 'got empty'; fi
teardown

echo '--- REQUEST-CHANGES routes to the BUILDER, not to him ---'
setup
human_turn "go"
assistant_text "PR is up: $URL"
pr_fixture OPEN abc123 "$checks_green" REQUEST-CHANGES
out="$(run_hook)"
if [ -n "$out" ]; then ok 'fires on REQUEST-CHANGES (non-merging, but not an owner summons)'; else bad 'fires on REQUEST-CHANGES' 'got empty'; fi
teardown

echo '--- a MERGED PR has nothing for him to merge ---'
setup
human_turn "go"
assistant_text "Shipped: $URL"
pr_fixture MERGED abc123 "$checks_green" APPROVE-PENDING-HUMAN
out="$(run_hook)"
if [ -n "$out" ]; then ok 'fires when the PR is not open'; else bad 'fires when the PR is not open' 'got empty'; fi
teardown

echo '--- a verdict on a SUPERSEDED head does not clear a link at the current head ---'
setup
human_turn "go"
assistant_text "PR is up: $URL"
jq -n --argjson c "$checks_green" --arg body "<!-- gatekeeper-verdict: quality-assurance -->
APPROVE-PENDING-HUMAN
head: oldsha" '{state:"OPEN", headRefOid:"newsha", statusCheckRollup:$c, comments:[{body:$body, authorAssociation:"OWNER"}]}' > "$root/fix/pr.json"
out="$(run_hook)"
if [ -n "$out" ]; then ok 'a stale-head verdict does not legitimise the link'; else bad 'a stale-head verdict does not legitimise the link' 'got empty'; fi
teardown

echo '--- an untrusted commenter cannot forge the clearance ---'
setup
human_turn "go"
assistant_text "PR is up: $URL"
jq -n --argjson c "$checks_green" --arg body "<!-- gatekeeper-verdict: quality-assurance -->
APPROVE-PENDING-HUMAN
head: abc123" '{state:"OPEN", headRefOid:"abc123", statusCheckRollup:$c, comments:[{body:$body, authorAssociation:"NONE"}]}' > "$root/fix/pr.json"
out="$(run_hook)"
if [ -n "$out" ]; then ok 'an untrusted association cannot clear the link'; else bad 'an untrusted association cannot clear the link' 'got empty'; fi
teardown

# ══════════════════════════════════════════════════════════════════════════════════════════════
# ARM B — IT STAYS SILENT. Without these, a hook that emits unconditionally passes arm A.
# ══════════════════════════════════════════════════════════════════════════════════════════════
echo '--- THE LEGITIMATE SUMMONS: open, every check complete and successful, APPROVE-PENDING-HUMAN ---'
setup
human_turn "go"
assistant_text "Ready for you: $URL"
pr_fixture OPEN abc123 "$checks_green" APPROVE-PENDING-HUMAN
out="$(run_hook)"
if [ -z "$out" ]; then ok 'silent on a legitimate link'; else bad 'silent on a legitimate link' "got: $out"; fi
teardown

echo '--- a StatusContext-shaped rollup is read too, not just CheckRun ---'
setup
human_turn "go"
assistant_text "Ready for you: $URL"
pr_fixture OPEN abc123 '[{"__typename":"StatusContext","state":"SUCCESS"}]' APPROVE-PENDING-HUMAN
out="$(run_hook)"
if [ -z "$out" ]; then ok 'silent when a StatusContext check succeeded'; else bad 'silent when a StatusContext check succeeded' "got: $out"; fi
teardown

echo '--- THE TOOL OUTPUT IS NOT A SUMMONS: a URL only in a tool_result costs ZERO gh calls ---'
setup
human_turn "go"
assistant_tool_use "gh pr create --title x --body-file /tmp/b"
tool_result "$URL"
assistant_text "Opened it. CI is running; I will report when it is done."
pr_fixture OPEN abc123 "$checks_running" ""
out="$(run_hook)"
n="$(gh_calls)"
if [ -z "$out" ]; then ok 'silent when the URL appears only in tool output'; else bad 'silent when the URL appears only in tool output' "got: $out"; fi
if [ "$n" = "0" ]; then ok 'and makes zero gh calls'; else bad 'and makes zero gh calls' "calls: $(cat "$root/calls.log")"; fi
teardown

echo '--- TURN SCOPING: a URL from an EARLIER turn is not re-flagged in this one ---'
setup
human_turn "go"
assistant_text "PR is up: $URL"
human_turn "ok, next"
assistant_text "Working on the next slice; nothing to hand over yet."
pr_fixture OPEN abc123 "$checks_running" ""
out="$(run_hook)"
n="$(gh_calls)"
if [ -z "$out" ]; then ok 'silent when this turn surfaced no URL'; else bad 'silent when this turn surfaced no URL' "got: $out"; fi
if [ "$n" = "0" ]; then ok 'and makes zero gh calls'; else bad 'and makes zero gh calls' "calls: $(cat "$root/calls.log")"; fi
teardown

echo '--- THE NAMED HOLE: a bare #NNN is unclassifiable and is NOT checked (documented, not fixed) ---'
setup
human_turn "go"
assistant_text "Opened #150 for this; CI is still running."
pr_fixture OPEN abc123 "$checks_running" ""
out="$(run_hook)"
n="$(gh_calls)"
if [ -z "$out" ]; then ok 'a bare #NNN does not fire — the form the RULE recommends is the one this cannot check'; else bad 'bare #NNN behaviour' "got: $out"; fi
if [ "$n" = "0" ]; then ok 'and costs nothing'; else bad 'and costs nothing' "calls: $(cat "$root/calls.log")"; fi
teardown

echo '--- an unreadable PR is skipped, not flagged: an unclassifiable link is not a finding ---'
setup
human_turn "go"
assistant_text "PR is up: $URL"
rm -f "$root/fix/pr.json"
out="$(run_hook)"
if [ -z "$out" ]; then ok 'silent when gh returns nothing'; else bad 'silent when gh returns nothing' "got: $out"; fi
teardown

# ══════════════════════════════════════════════════════════════════════════════════════════════
# COST, DEBOUNCE, AND THE SHAPES THE SIBLING HOOKS ALREADY OWE
# ══════════════════════════════════════════════════════════════════════════════════════════════
echo '--- the gh call is spelled with --repo AFTER the subcommand (shell) ---'
setup
human_turn "go"
assistant_text "PR is up: $URL"
pr_fixture OPEN abc123 "$checks_running" ""
run_hook >/dev/null
if grep -q '^pr view 150 --repo tedeuxx/tadeumendonca-skills' "$root/calls.log"; then
  ok 'calls: gh pr view <n> --repo <owner/repo>'
else
  bad 'calls: gh pr view <n> --repo <owner/repo>' "log: $(cat "$root/calls.log")"
fi
teardown

echo '--- MAX_URLS caps the bill: four distinct URLs cost at most three pr-view calls ---'
setup
human_turn "go"
assistant_text "Open: https://github.com/o/r/pull/1 https://github.com/o/r/pull/2 https://github.com/o/r/pull/3 https://github.com/o/r/pull/4"
pr_fixture OPEN abc123 "$checks_running" ""
run_hook >/dev/null
v="$(view_calls)"
if [ "$v" -le 3 ] && [ "$v" -ge 1 ]; then ok "at most three pr-view calls for four URLs (was $v)"; else bad 'MAX_URLS cap' "pr view calls: $v"; fi
teardown

echo '--- DEBOUNCE: the same (PR, head) does not re-notify within a session ---'
setup
human_turn "go"
assistant_text "PR is up: $URL"
pr_fixture OPEN abc123 "$checks_running" ""
first="$(run_hook)"
second="$(run_hook)"
if [ -n "$first" ]; then ok 'first call fires'; else bad 'first call fires' 'got empty'; fi
if [ -z "$second" ]; then ok 'second call on the SAME state is silent'; else bad 'second call on the SAME state is silent' "got: $second"; fi
teardown

echo '--- DEBOUNCE re-arms when the head moves ---'
setup
human_turn "go"
assistant_text "PR is up: $URL"
pr_fixture OPEN abc123 "$checks_running" ""
run_hook >/dev/null
pr_fixture OPEN def456 "$checks_running" ""
out="$(run_hook)"
if [ -n "$out" ]; then ok 'a new head re-arms the notice'; else bad 'a new head re-arms the notice' 'got empty'; fi
teardown

echo '--- DEBOUNCE is per SESSION ---'
setup
human_turn "go"
assistant_text "PR is up: $URL"
pr_fixture OPEN abc123 "$checks_running" ""
run_hook sess-1 >/dev/null
out2="$(run_hook sess-2)"
if [ -n "$out2" ]; then ok 'a different session is notified independently'; else bad 'a different session is notified independently' 'got empty'; fi
teardown

echo '--- stop_hook_active: honoured, zero work, zero gh calls ---'
setup
human_turn "go"
assistant_text "PR is up: $URL"
pr_fixture OPEN abc123 "$checks_running" ""
payload="$(jq -n --arg cwd "$repo" --arg tp "$transcript" --arg sid s1 '{cwd:$cwd, transcript_path:$tp, session_id:$sid, stop_hook_active:true}')"
out="$( export PATH="$root/bin:/usr/bin:/bin"; printf '%s' "$payload" | "$BASH" "$HOOK" 2>/dev/null )"
n="$(gh_calls)"
if [ -z "$out" ]; then ok 'stop_hook_active suppresses the notice'; else bad 'stop_hook_active suppresses the notice' "got: $out"; fi
if [ "$n" = "0" ]; then ok 'stop_hook_active makes zero gh calls'; else bad 'stop_hook_active makes zero gh calls' "calls: $(cat "$root/calls.log")"; fi
teardown

echo '--- an unreadable transcript is silent and costs nothing ---'
setup
pr_fixture OPEN abc123 "$checks_running" ""
payload="$(jq -n --arg cwd "$repo" --arg tp "/no/such/transcript.jsonl" --arg sid s1 '{cwd:$cwd, transcript_path:$tp, session_id:$sid}')"
out="$( export PATH="$root/bin:/usr/bin:/bin"; printf '%s' "$payload" | "$BASH" "$HOOK" 2>/dev/null )"
n="$(gh_calls)"
if [ -z "$out" ]; then ok 'silent with no transcript'; else bad 'silent with no transcript' "got: $out"; fi
if [ "$n" = "0" ]; then ok 'and zero gh calls'; else bad 'and zero gh calls' "calls: $(cat "$root/calls.log")"; fi
teardown

echo '--- never blocks: no "decision" or "permissionDecision" field, ever ---'
setup
human_turn "go"
assistant_text "PR is up: $URL"
pr_fixture OPEN abc123 "$checks_running" ""
out="$(run_hook)"
case "$out" in
  *'"decision"'*|*'permissionDecision'*) bad 'never emits a blocking decision field' "got: $out" ;;
  *) ok 'never emits a blocking decision field' ;;
esac
teardown

echo '--- exit code is always 0, even on the firing path ---'
setup
human_turn "go"
assistant_text "PR is up: $URL"
pr_fixture OPEN abc123 "$checks_running" ""
run_hook >/dev/null
rc=$?
if [ "$rc" = "0" ]; then ok 'exits 0'; else bad 'exits 0' "exit was $rc"; fi
teardown

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
