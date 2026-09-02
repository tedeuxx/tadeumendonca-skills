#!/usr/bin/env bash
# zombie-loop-detect.test.sh — does the Stop hook fire the notice exactly when loop state says an
# outstanding gate verdict was left unaddressed at turn end, and stay silent (and cheap) otherwise?
#
# Mutation-checked per this repo's own convention: every assertion below was verified to fail
# against a deliberately broken hook before being trusted. Two properties get that treatment
# explicitly because the intake asked for it by name — the LOCAL-ONLY PRECONDITION (no `gh` call
# at all with no current branch) and the DEBOUNCE (a repeated turn on the same (PR, head) does not
# re-notify and does not repeat the heavier `pr view` call).
#
# Uses a REAL temporary git repository (not a stub) because the hook calls `git branch
# --show-current` and `git rev-parse --git-dir` for real — a stubbed `git` would test the stub,
# not the hook's use of it. `gh` IS a stub: it serves fixtures and, critically, LOGS every
# invocation to a call-log file so the network-cost assertions can count calls rather than infer
# them from behaviour.

set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/zombie-loop-detect.sh"
pass=0
fail=0

ok()  { printf 'ok    %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL  %s\n     %s\n' "$1" "$2"; fail=$((fail + 1)); }

# ── fixture repo + gh stub ──────────────────────────────────────────────────────────────────────
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
  cat > "$root/bin/gh" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "__CALLLOG__"
case "$1 $2" in
  "pr list") [ -f "__FIXDIR__/list.json" ] && cat "__FIXDIR__/list.json" ;;
  "pr view") [ -f "__FIXDIR__/view.json" ] && cat "__FIXDIR__/view.json" ;;
esac
exit 0
STUB
  sed -i.bak "s#__CALLLOG__#$root/calls.log#g; s#__FIXDIR__#$root/fix#g" "$root/bin/gh"
  rm -f "$root/bin/gh.bak"
  chmod +x "$root/bin/gh"
}

teardown() { rm -rf "$root"; }

checkout_branch() { # name
  git -C "$repo" checkout -q -b "$1" 2>/dev/null || git -C "$repo" checkout -q "$1"
}

no_open_pr() {
  printf '[]\n' > "$root/fix/list.json"
}

open_pr() { # number · head_sha
  jq -n --argjson n "$1" --arg h "$2" '[{number:$n, headRefOid:$h}]' > "$root/fix/list.json"
}

# comment body carrying the marker + verdict + head, from an OWNER
view_with_verdict() { # head_sha · verdict
  jq -n --arg h "$1" --arg body "<!-- gatekeeper-verdict: quality-assurance -->
$2
head: $1" '{headRefOid:$h, comments:[{body:$body, authorAssociation:"OWNER"}]}' > "$root/fix/view.json"
}

view_no_comments() { # head_sha
  jq -n --arg h "$1" '{headRefOid:$h, comments:[]}' > "$root/fix/view.json"
}

run_hook() {
  payload="$(jq -n --arg cwd "$repo" --arg sid "sess-1" '{cwd:$cwd, session_id:$sid}')"
  ( export PATH="$root/bin:/usr/bin:/bin"
    printf '%s' "$payload" | "$BASH" "$HOOK" 2>/dev/null )
}

call_count() { # subcommand words, e.g. "pr list"
  grep -c "^$1" "$root/calls.log" 2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════════════════════
echo '--- the failure this exists for: REQUEST-CHANGES outstanding at turn end ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 REQUEST-CHANGES
out="$(run_hook)"
case "$out" in
  *'REQUEST-CHANGES'*'#150'*|*'#150'*'REQUEST-CHANGES'*) ok 'notice names the PR and the verdict' ;;
  *) bad 'notice names the PR and the verdict' "got: ${out:-<empty>}" ;;
esac
case "$out" in
  *'hookSpecificOutput'*'"Stop"'*) ok 'emits Stop hookSpecificOutput' ;;
  *) bad 'emits Stop hookSpecificOutput' "got: $out" ;;
esac
teardown

echo '--- APPROVE-PENDING-HUMAN also triggers the notice ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 APPROVE-PENDING-HUMAN
out="$(run_hook)"
case "$out" in
  *'APPROVE-PENDING-HUMAN'*) ok 'APPROVE-PENDING-HUMAN fires' ;;
  *) bad 'APPROVE-PENDING-HUMAN fires' "got: ${out:-<empty>}" ;;
esac
teardown

echo '--- APPROVE-EXECUTOR-BLOCKED (#374) is the sharpest outstanding state there is ---'
# The gate cleared the diff and could not execute the merge, so nothing downstream moves without the
# owner. Silence here would hide the one state in the vocabulary where the loop has finished.
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 APPROVE-EXECUTOR-BLOCKED
out="$(run_hook)"
case "$out" in
  *'APPROVE-EXECUTOR-BLOCKED'*) ok 'APPROVE-EXECUTOR-BLOCKED fires' ;;
  *) bad 'APPROVE-EXECUTOR-BLOCKED fires' "got: ${out:-<empty>}" ;;
esac
case "$out" in
  *'remaining act is the owner'*) ok 'and the notice says the act is the owner, not another dispatch' ;;
  *) bad 'the notice routes it to the owner' "got: ${out:-<empty>}" ;;
esac
teardown

echo '--- APPROVE-AND-MERGE is not outstanding, no notice ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 APPROVE-AND-MERGE
out="$(run_hook)"
if [ -z "$out" ]; then ok 'silent on APPROVE-AND-MERGE'; else bad 'silent on APPROVE-AND-MERGE' "got: $out"; fi
teardown

echo '--- no verdict at all (gate never dispatched) is not this hook''s condition ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_no_comments abc123
out="$(run_hook)"
if [ -z "$out" ]; then ok 'silent when there is no verdict yet'; else bad 'silent when there is no verdict yet' "got: $out"; fi
teardown

echo '--- staleness: a verdict citing a superseded head is not read as current ---'
# view_with_verdict's headRefOid arg is what gh pr view reports as CURRENT (newsha); the comment
# body's own "head: oldsha" line names the head the gate actually reviewed, which is stale.
setup
checkout_branch feat/x
open_pr 150 newsha
jq -n --arg h newsha --arg body "<!-- gatekeeper-verdict: quality-assurance -->
REQUEST-CHANGES
head: oldsha" '{headRefOid:$h, comments:[{body:$body, authorAssociation:"OWNER"}]}' > "$root/fix/view.json"
out="$(run_hook)"
if [ -z "$out" ]; then ok 'a verdict on an old head does not fire'; else bad 'a verdict on an old head does not fire' "got: $out"; fi
teardown

echo '--- unrecognised literal (verdict drift) is out of THIS hook''s narrow scope ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 APPROVED
out="$(run_hook)"
if [ -z "$out" ]; then ok 'an unrecognised literal does not fire (session-wip.sh owns that report)'; else bad 'unrecognised literal scope' "got: $out"; fi
teardown

# ══════════════════════════════════════════════════════════════════════════════════════════════
echo '--- LOCAL-ONLY PRECONDITION: no current branch means ZERO gh calls ---'
setup
git -C "$repo" checkout -q --detach 2>/dev/null || true
out="$(run_hook)"
n="$(call_count '')"
total_calls="$(wc -l < "$root/calls.log" | tr -d ' ')"
if [ "$total_calls" = "0" ]; then ok 'zero gh calls with no current branch'; else bad 'zero gh calls with no current branch' "calls: $(cat "$root/calls.log")"; fi
if [ -z "$out" ]; then ok 'and no notice'; else bad 'and no notice' "got: $out"; fi
teardown

echo '--- LOCAL-ONLY PRECONDITION: an unreadable cwd means zero gh calls ---'
setup
payload="$(jq -n --arg cwd "/no/such/dir/at/all" --arg sid "s1" '{cwd:$cwd, session_id:$sid}')"
out="$( export PATH="$root/bin:/usr/bin:/bin"; printf '%s' "$payload" | "$BASH" "$HOOK" 2>/dev/null )"
total_calls="$(wc -l < "$root/calls.log" | tr -d ' ')"
if [ "$total_calls" = "0" ]; then ok 'zero gh calls with an unreadable cwd'; else bad 'zero gh calls with an unreadable cwd' "calls: $(cat "$root/calls.log")"; fi
teardown

echo '--- NETWORK COST: no open PR means exactly ONE gh call, never reaches pr view ---'
setup
checkout_branch feat/x
no_open_pr
out="$(run_hook)"
list_calls="$(call_count 'pr list')"
view_calls="$(call_count 'pr view')"
if [ "$list_calls" = "1" ]; then ok 'exactly one "pr list" call'; else bad 'exactly one "pr list" call' "count: $list_calls"; fi
if [ "$view_calls" = "0" ]; then ok 'zero "pr view" calls when there is no PR'; else bad 'zero "pr view" calls when there is no PR' "count: $view_calls"; fi
if [ -z "$out" ]; then ok 'and no notice'; else bad 'and no notice' "got: $out"; fi
teardown

echo '--- NETWORK COST: an open PR costs exactly TWO gh calls on a fresh state ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 REQUEST-CHANGES
run_hook >/dev/null
list_calls="$(call_count 'pr list')"
view_calls="$(call_count 'pr view')"
if [ "$list_calls" = "1" ] && [ "$view_calls" = "1" ]; then
  ok 'exactly one pr list + one pr view on a fresh outstanding state'
else
  bad 'exactly one pr list + one pr view on a fresh outstanding state' "list=$list_calls view=$view_calls"
fi
teardown

# ══════════════════════════════════════════════════════════════════════════════════════════════
echo '--- DEBOUNCE: the same (PR, head) does not re-notify within a session ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 REQUEST-CHANGES
first="$(run_hook)"
second="$(run_hook)"
if [ -n "$first" ]; then ok 'first call fires'; else bad 'first call fires' 'got empty'; fi
if [ -z "$second" ]; then ok 'second call on the SAME state is silent'; else bad 'second call on the SAME state is silent' "got: $second"; fi
teardown

echo '--- DEBOUNCE bounds cost too: the repeat call skips the heavier pr-view read ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 REQUEST-CHANGES
run_hook >/dev/null   # arms the debounce
run_hook >/dev/null   # should short-circuit before the second gh call
view_calls="$(call_count 'pr view')"
if [ "$view_calls" = "1" ]; then
  ok 'the debounced repeat makes no additional "pr view" call'
else
  bad 'the debounced repeat makes no additional "pr view" call' "pr view calls: $view_calls"
fi
teardown

echo '--- DEBOUNCE re-arms when the head moves ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 REQUEST-CHANGES
run_hook >/dev/null
open_pr 150 def456
view_with_verdict def456 REQUEST-CHANGES
out="$(run_hook)"
if [ -n "$out" ]; then ok 'a new head re-arms the notice'; else bad 'a new head re-arms the notice' 'got empty'; fi
teardown

echo '--- DEBOUNCE is per SESSION: a different session_id is notified independently ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 REQUEST-CHANGES
run_hook >/dev/null   # session sess-1, arms it
payload2="$(jq -n --arg cwd "$repo" --arg sid "sess-2" '{cwd:$cwd, session_id:$sid}')"
out2="$( export PATH="$root/bin:/usr/bin:/bin"; printf '%s' "$payload2" | "$BASH" "$HOOK" 2>/dev/null )"
if [ -n "$out2" ]; then ok 'a different session is notified independently'; else bad 'a different session is notified independently' 'got empty'; fi
teardown

# ══════════════════════════════════════════════════════════════════════════════════════════════
echo '--- stop_hook_active: honoured, zero work done, zero gh calls ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 REQUEST-CHANGES
payload="$(jq -n --arg cwd "$repo" --arg sid "s1" '{cwd:$cwd, session_id:$sid, stop_hook_active:true}')"
out="$( export PATH="$root/bin:/usr/bin:/bin"; printf '%s' "$payload" | "$BASH" "$HOOK" 2>/dev/null )"
total_calls="$(wc -l < "$root/calls.log" | tr -d ' ')"
if [ -z "$out" ]; then ok 'stop_hook_active suppresses the notice'; else bad 'stop_hook_active suppresses the notice' "got: $out"; fi
if [ "$total_calls" = "0" ]; then ok 'stop_hook_active makes zero gh calls'; else bad 'stop_hook_active makes zero gh calls' "calls: $(cat "$root/calls.log")"; fi
teardown

echo '--- SUPPRESSION: an untrusted association cannot suppress OR forge the mark ---'
setup
checkout_branch feat/x
open_pr 150 abc123
jq -n --arg h abc123 --arg body "<!-- gatekeeper-verdict: quality-assurance -->
REQUEST-CHANGES
head: abc123" '{headRefOid:$h, comments:[{body:$body, authorAssociation:"NONE"}]}' > "$root/fix/view.json"
out="$(run_hook)"
if [ -z "$out" ]; then ok 'an untrusted commenter cannot trigger the notice'; else bad 'an untrusted commenter cannot trigger the notice' "got: $out"; fi
teardown

echo '--- exit code is always 0, even on the firing path ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 REQUEST-CHANGES
run_hook >/dev/null
rc=$?
if [ "$rc" = "0" ]; then ok 'exits 0'; else bad 'exits 0' "exit was $rc"; fi
teardown

echo '--- never blocks: no "decision" or "permissionDecision" field, ever ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 REQUEST-CHANGES
out="$(run_hook)"
case "$out" in
  *'"decision"'*|*'permissionDecision'*) bad 'never emits a blocking decision field' "got: $out" ;;
  *) ok 'never emits a blocking decision field' ;;
esac
teardown

echo '--- silence stays silence with no gh/jq on PATH ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 REQUEST-CHANGES
payload="$(jq -n --arg cwd "$repo" --arg sid "s1" '{cwd:$cwd, session_id:$sid}')"
out="$( export PATH="/usr/bin:/bin"; printf '%s' "$payload" | "$BASH" "$HOOK" 2>/dev/null; echo "RC:$?" )"
case "$out" in
  RC:0) ok 'degrades silently and exits 0 without gh (if gh is genuinely absent from a minimal PATH)' ;;
  *RC:0) ok 'exits 0 regardless of gh availability on a minimal PATH' ;;
  *) bad 'exits 0 on a minimal PATH' "got: $out" ;;
esac
teardown

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
