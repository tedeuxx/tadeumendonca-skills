#!/usr/bin/env bash
# purpose: keep each structured owner interruption to one question, so no transport can silently discard later asks
# hitl-one-question-guard.sh — PreToolUse guard on AskUserQuestion. It enforces only the countable
# half of HITL rule 1: a structured picker carries zero or one question, never two or more.
#
# This guard deliberately does NOT classify language. It does not inspect question text, option labels,
# execution verbs, links, or whether the call is a decision, action or interview. That semantic shape is
# held by review. The deleted action-pendency guard guessed from label spelling; its false positives were
# invisible to the owner because denial happened before the picker rendered. Rebuilding that classifier
# here would recreate the defect this narrower predicate exists to avoid.
#
# The boundary is syntactic and fail-open: only a real `.tool_input.questions` array with length >= 2 is
# denied. Missing, null, non-array, malformed and `__unparsedToolInput` payloads produce no decision. The
# runtime may still reject those shapes; this hook makes no claim about them. A missing `jq` or invalid
# JSON also fails open with no decision, matching the shared hook posture rather than inventing one here.
# In one line for the blueprint registry: only a real `.tool_input.questions` array with length >= 2 is denied.

set -uo pipefail

input="$(cat)"

command -v jq >/dev/null 2>&1 || exit 0
printf '%s' "$input" | jq -e . >/dev/null 2>&1 || exit 0

tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null || true)"
[ "$tool_name" = "AskUserQuestion" ] || exit 0

questions_type="$(printf '%s' "$input" | jq -r '.tool_input.questions | type' 2>/dev/null || true)"
[ "$questions_type" = "array" ] || exit 0

question_count="$(printf '%s' "$input" | jq -r '.tool_input.questions | length' 2>/dev/null || true)"
case "$question_count" in
  ''|*[!0-9]*) exit 0 ;;
esac
[ "$question_count" -ge 2 ] || exit 0

jq -n --arg r "Blocked: AskUserQuestion carries ${question_count} questions. Ask only the first question now and wait for the owner's answer. Keep every remaining ask for its own later activation; do not convert it into prose or a numbered list." '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $r
  }
}'
