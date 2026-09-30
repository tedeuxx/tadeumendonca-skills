#!/usr/bin/env bash
# hitl-one-question-guard.test.sh — does the guard deny only AskUserQuestion arrays with two or more
# questions, preserve the accepted fail-open boundary, and remain reachable through hooks.json?
#
# MUTATION-CHECKED: changing the threshold from `-ge 2` to `-ge 3` made the two-question assertion fail;
# replacing the non-array early exit with a denial made the null/absent/unparsed assertions fail; and
# changing the matcher in hooks.json made the registration assertion fail. Each source was restored and
# the suite re-run green. Direct payloads prove the script, not host routing; the first installed live
# fire remains runtime evidence to collect after the plugin release.
#
# Run: bash hooks/scripts/hitl-one-question-guard.test.sh

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$HERE/hitl-one-question-guard.sh"
HOOKS_JSON="$HERE/../hooks.json"
pass=0
fail=0

ok()  { printf 'ok    %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL  %s\n     %s\n' "$1" "$2"; fail=$((fail + 1)); }

run_payload() { printf '%s' "$1" | bash "$HOOK" 2>/dev/null; }

assert_abstain() {
  local label="$1" out
  out="$(run_payload "$2")"
  if [ -z "$out" ]; then ok "$label"; else bad "$label" "expected no decision, got: $out"; fi
}

assert_deny() {
  local label="$1" expected_count="$2" out
  out="$(run_payload "$3")"
  case "$out" in
    *'"permissionDecision": "deny"'*) : ;;
    *) bad "$label" "expected a deny decision, got: ${out:-<empty>}"; return ;;
  esac
  case "$out" in
    *"carries ${expected_count} questions"*"Ask only the first question now"*"do not convert it into prose or a numbered list"*) ok "$label" ;;
    *) bad "$label" "deny reason did not carry the count and recovery instruction: $out" ;;
  esac
}

assert_abstain "zero questions falls through" \
  '{"tool_name":"AskUserQuestion","tool_input":{"questions":[]}}'
assert_abstain "one question falls through" \
  '{"tool_name":"AskUserQuestion","tool_input":{"questions":[{"question":"First?"}]}}'
assert_deny "two questions are denied" 2 \
  '{"tool_name":"AskUserQuestion","tool_input":{"questions":[{"question":"First?"},{"question":"Second?"}]}}'
assert_deny "four questions are denied" 4 \
  '{"tool_name":"AskUserQuestion","tool_input":{"questions":[{},{},{},{}]}}'

assert_abstain "null questions falls through" \
  '{"tool_name":"AskUserQuestion","tool_input":{"questions":null}}'
assert_abstain "a non-array questions value falls through" \
  '{"tool_name":"AskUserQuestion","tool_input":{"questions":"first, second"}}'
assert_abstain "absent questions falls through" \
  '{"tool_name":"AskUserQuestion","tool_input":{}}'
assert_abstain "unparsed tool input falls through" \
  '{"tool_name":"AskUserQuestion","tool_input":{"__unparsedToolInput":"questions: two"}}'
assert_abstain "malformed JSON falls through" '{not-json'
assert_abstain "a misrouted non-picker tool falls through" \
  '{"tool_name":"Bash","tool_input":{"questions":[{},{}]}}'

if [ ! -f "$HOOKS_JSON" ]; then
  bad "hooks.json is readable" "not found at $HOOKS_JSON"
elif ! jq -e '.hooks.PreToolUse[] | select(.matcher == "AskUserQuestion") | .hooks[] | select(.command | test("hitl-one-question-guard\\.sh"))' "$HOOKS_JSON" >/dev/null 2>&1; then
  bad "hooks.json routes AskUserQuestion to the count guard" \
      "no exact AskUserQuestion matcher invokes hitl-one-question-guard.sh"
else
  ok "hooks.json routes AskUserQuestion to the count guard"
fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
