#!/usr/bin/env bash
# orchestrator-write-guard.test.sh — does the guard deny exactly the main agent's edits inside a git
# working tree, and nothing else?
#
# Mutation-checked per this repo's convention: every assertion here was verified to FAIL against a
# deliberately broken guard before being trusted. Three mutations were used, because three different
# defects are possible and only one of them is the obvious one:
#   * invert the `agent_type` test          -> the ALLOW-a-subagent assertions go red (the direction
#                                              that would stop the loop dead)
#   * drop `.tool_input.notebook_path`      -> the NotebookEdit assertion goes red (the side door that
#                                              no matcher fix closes — measured open on #319)
#   * replace the git test with `true`      -> the scratchpad assertions go red (the load-bearing
#                                              route: PR bodies composed for --body-file)
#
# Uses a REAL temporary git repository, and a REAL non-repo temporary directory as the control. A
# stubbed `git` would test the stub rather than the guard's use of it, and the whole rule is a question
# about repository membership.
#
# THE MATCHER IS ASSERTED HERE TOO, against `hooks/hooks.json`, and that is not scope creep. The
# guard's script cannot see a call the matcher never routed to it, so a matcher narrowed back to
# `Edit|Write` would leave every assertion below green while `NotebookEdit` walked through the door —
# measured doing exactly that on #319. The registration is part of the control, so it is part of the
# gate.
#
# Run: bash hooks/scripts/orchestrator-write-guard.test.sh

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$HERE/orchestrator-write-guard.sh"
HOOKS_JSON="$HERE/../hooks.json"
pass=0
fail=0

ok()  { printf 'ok    %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL  %s\n     %s\n' "$1" "$2"; fail=$((fail + 1)); }

setup() {
  root="$(mktemp -d)"
  repo="$root/repo"
  plain="$root/plain"          # NOT a git repository — stands in for the session scratchpad
  mkdir -p "$repo" "$plain"
  git -C "$repo" init -q -b main
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config user.name test
  printf 'ORIGINAL\n' > "$repo/tracked.txt"
  git -C "$repo" add tracked.txt
  git -C "$repo" commit -q -m init
}
teardown() { rm -rf "$root"; }

# run_hook <tool> <path-key> <path> [agent_type] [cwd]
run_hook() {
  local tool="$1" key="$2" path="$3" at="${4:-}" cwd="${5:-}"
  local payload
  payload="$(jq -n --arg t "$tool" --arg k "$key" --arg p "$path" --arg a "$at" --arg c "$cwd" '
    {tool_name:$t, tool_input:{($k):$p}}
    + (if $a == "" then {} else {agent_type:$a} end)
    + (if $c == "" then {} else {cwd:$c} end)')"
  printf '%s' "$payload" | "$BASH" "$HOOK" 2>/dev/null
}

decision() { printf '%s' "$1" | jq -r '.hookSpecificOutput.permissionDecision // "NONE"' 2>/dev/null || echo NONE; }

# ══════════════════════════════════════════════════════════════════════════════════════════════
echo '--- the failure this exists for: the main agent editing inside a git working tree ---'
setup
out="$(run_hook Write file_path "$repo/new.txt")"
if [ "$(decision "$out")" = "deny" ]; then ok 'main-agent Write inside a git tree is denied'
else bad 'main-agent Write inside a git tree is denied' "got: ${out:-<empty>}"; fi

out="$(run_hook Edit file_path "$repo/tracked.txt")"
if [ "$(decision "$out")" = "deny" ]; then ok 'main-agent Edit inside a git tree is denied (the TOOL, not only the matcher)'
else bad 'main-agent Edit inside a git tree is denied' "got: ${out:-<empty>}"; fi

out="$(run_hook MultiEdit file_path "$repo/tracked.txt")"
if [ "$(decision "$out")" = "deny" ]; then ok 'main-agent MultiEdit inside a git tree is denied'
else bad 'main-agent MultiEdit inside a git tree is denied' "got: ${out:-<empty>}"; fi

echo '--- the side door: NotebookEdit carries notebook_path, not file_path ---'
out="$(run_hook NotebookEdit notebook_path "$repo/nb.ipynb")"
if [ "$(decision "$out")" = "deny" ]; then ok 'NotebookEdit is denied through the notebook_path key'
else bad 'NotebookEdit is denied through the notebook_path key' "got: ${out:-<empty>}"; fi

echo '--- the direction that matters most: a subagent is never blocked ---'
for persona in tadeumendonca-skills:developer tadeumendonca-skills:content-writer tadeumendonca-skills:agents-lead tadeumendonca-skills:quality-assurance somefuture:persona; do
  out="$(run_hook Edit file_path "$repo/tracked.txt" "$persona")"
  if [ -z "$out" ]; then ok "subagent '$persona' passes through untouched"
  else bad "subagent '$persona' passes through untouched" "got: $out"; fi
done

echo '--- the load-bearing route: outside any git tree, the main agent writes freely ---'
out="$(run_hook Write file_path "$plain/pr-body.md")"
if [ -z "$out" ]; then ok 'main-agent Write outside a git tree is allowed (the --body-file route)'
else bad 'main-agent Write outside a git tree is allowed' "got: $out"; fi

out="$(run_hook Edit file_path "$plain/deep/er/still-not-a-repo.md")"
if [ -z "$out" ]; then ok 'a non-existent path outside a git tree is allowed'
else bad 'a non-existent path outside a git tree is allowed' "got: $out"; fi

echo '--- the ancestor walk: neither the file nor its directory need exist yet ---'
out="$(run_hook Write file_path "$repo/does/not/exist/yet.txt")"
if [ "$(decision "$out")" = "deny" ]; then ok 'a new file in a new subdirectory of a git tree is denied'
else bad 'a new file in a new subdirectory of a git tree is denied' "got: ${out:-<empty>}"; fi

echo '--- a write into .git/ escapes the diff entirely, and is denied too ---'
out="$(run_hook Write file_path "$repo/.git/hooks/pre-commit")"
if [ "$(decision "$out")" = "deny" ]; then ok 'a write inside .git/ is denied'
else bad 'a write inside .git/ is denied' "got: ${out:-<empty>}"; fi

echo '--- relative paths resolve against cwd ---'
out="$(run_hook Write file_path "sub/rel.txt" "" "$repo")"
if [ "$(decision "$out")" = "deny" ]; then ok 'a relative path with cwd inside a git tree is denied'
else bad 'a relative path with cwd inside a git tree is denied' "got: ${out:-<empty>}"; fi

out="$(run_hook Write file_path "sub/rel.txt" "" "$plain")"
if [ -z "$out" ]; then ok 'a relative path with cwd outside a git tree is allowed'
else bad 'a relative path with cwd outside a git tree is allowed' "got: $out"; fi

out="$(run_hook Write file_path "sub/rel.txt")"
if [ -z "$out" ]; then ok 'a relative path with no cwd fails OPEN rather than guessing'
else bad 'a relative path with no cwd fails OPEN' "got: $out"; fi

echo '--- the deny reason is actionable: it names where the work goes ---'
out="$(run_hook Write file_path "$repo/new.txt")"
reason="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecisionReason // ""')"
for who in developer content-writer agents-lead; do
  case "$reason" in
    *"$who"*) ok "deny reason names '$who' as a delegation target" ;;
    *) bad "deny reason names '$who' as a delegation target" "reason: $reason" ;;
  esac
done
case "$reason" in
  *"$repo/new.txt"*) ok 'deny reason quotes the path it refused' ;;
  *) bad 'deny reason quotes the path it refused' "reason: $reason" ;;
esac

echo '--- it never emits an ALLOW decision, only deny or silence ---'
out="$(run_hook Read file_path "$repo/tracked.txt")"
case "$out" in
  *'"allow"'*) bad 'never emits an allow decision' "got: $out" ;;
  *) ok 'never emits an allow decision (silence is the allow)' ;;
esac

echo '--- payloads with nothing to decide on ---'
out="$(printf '%s' '{"tool_name":"ToolSearch","tool_input":{"query":"x"}}' | "$BASH" "$HOOK" 2>/dev/null)"
if [ -z "$out" ]; then ok 'a payload with no path is allowed'
else bad 'a payload with no path is allowed' "got: $out"; fi

out="$(printf '' | "$BASH" "$HOOK" 2>/dev/null; echo "RC:$?")"
if [ "$out" = "RC:0" ]; then ok 'an empty payload exits 0 silently'
else bad 'an empty payload exits 0 silently' "got: $out"; fi

out="$(printf '%s' 'not json at all' | "$BASH" "$HOOK" 2>/dev/null; echo "RC:$?")"
case "$out" in
  RC:0) ok 'an unparseable payload fails OPEN and exits 0' ;;
  *) bad 'an unparseable payload fails OPEN and exits 0' "got: $out" ;;
esac

# An EMPTY PATH directory, not "/usr/bin:/bin" — measured: both `jq` and `git` ship in /usr/bin on
# this platform, so the minimal-PATH form of this assertion passes while the dependency it claims to
# remove is still present. It would have been green with the branch it exists to exercise never taken.
echo '--- fails open with its dependencies genuinely absent (the wedge this guard must never cause) ---'
payload="$(jq -n --arg p "$repo/new.txt" '{tool_name:"Write", tool_input:{file_path:$p}}')"
mkdir -p "$root/emptybin"
out="$( export PATH="$root/emptybin"; printf '%s' "$payload" | "$BASH" "$HOOK" 2>/dev/null; echo "RC:$?" )"
if [ "$out" = "RC:0" ]; then ok 'no jq and no git on PATH: exits 0, emits nothing, denies nothing'
else bad 'no jq and no git on PATH: exits 0, emits nothing, denies nothing' "got: $out"; fi
teardown

echo '--- the registration: a narrowed matcher would reopen the measured side door ---'
if [ ! -f "$HOOKS_JSON" ]; then
  bad 'hooks.json is readable' 'hooks/hooks.json not found — this assertion is checking nothing'
else
  matcher="$(jq -r '.hooks.PreToolUse[] | select((.hooks[].command // "") | contains("orchestrator-write-guard.sh")) | .matcher' "$HOOKS_JSON" 2>/dev/null || true)"
  if [ -z "$matcher" ]; then
    bad 'the guard is registered in hooks.json' 'no PreToolUse entry references orchestrator-write-guard.sh'
  else
    ok "the guard is registered on matcher '$matcher'"
    for tool in Edit Write MultiEdit NotebookEdit; do
      case "$matcher" in
        *"$tool"*) ok "matcher names '$tool'" ;;
        *) bad "matcher names '$tool'" "matcher is '$matcher'; a matcher is ANCHORED — measured on #319, 'Edit|Write' does not fire for NotebookEdit, and the notebook was mutated inside a git tree" ;;
      esac
    done
  fi
fi

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
