#!/usr/bin/env bash
# action-pendency-guard.test.sh — does the guard deny exactly the pickers that are ACTION pendencies,
# and leave every DECISION pendency alone?
#
# THE TWO DIRECTIONS ARE NOT EQUALLY BAD, and the suite is weighted accordingly. A missed action
# pendency costs one correction from the owner. A denied DECISION pendency costs the loop its only
# instrument for raising a real trade — so most of the assertions below are negative ones.
#
# MUTATION-CHECKED per this repo's convention: every assertion was verified to FAIL against a
# deliberately broken guard before being trusted. THE SOURCE WAS MUTATED, NEVER THE TEST — the
# recurring defect in this workspace is an assertion that cannot fail, and reading never finds one.
# Four mutations, because four different defects are possible:
#
#   * drop the link half (`[ -z "$link" ] && exit 0`)   -> the no-link negatives go red (the guard
#                                                          becomes a verb detector and denies any
#                                                          picker that says "merge")
#   * drop the verb half (`[ -z "$hit" ] && exit 0`)    -> the link-without-verb negatives go red
#                                                          (every picker citing a PR is denied)
#   * widen the label query to `.options[]?.description` -> the description-only negative goes red
#   * add `approve` to VERBS                             -> the approve negative goes red (the
#                                                          judgement-verb regression this guard's
#                                                          header argues against by name)
#
# THE MATCHER IS ASSERTED HERE TOO, against `hooks/hooks.json`, and it is not scope creep: this
# script feeds the guard a payload directly, so a matcher typo would leave every assertion green
# while every picker walked through. The registration is part of the control, so it is part of the
# gate. That lesson is `orchestrator-write-guard.test.sh`'s, paid for once already.
#
# WHAT A GREEN HERE DOES NOT MEAN, stated so nobody over-reads it:
#   * **it does not prove Claude Code routes `AskUserQuestion` to a `PreToolUse` hook, AND THAT
#     ROUTING IS UNMEASURED.** This suite feeds the script a payload directly, so it proves the
#     script's logic and says nothing about whether the harness ever hands it a call.
#
#     ~~established by live probe and recorded in the guard's header~~ — **STRUCK. That sentence was
#     false when it was written and no probe had been run.** It is struck rather than deleted because
#     it is the exact defect this repository names as its recurring one: prose asserting a state that
#     was inferred instead of read, and it shipped inside the suite for a control whose whole value
#     depends on the claim.
#
#     **What WAS attempted, and why it settled nothing:** a probe plugin registering a `PreToolUse`
#     hook on this matcher, loaded with `claude --plugin-dir <probe> -p "<call AskUserQuestion>"`.
#     **A print-mode session has no `AskUserQuestion` tool at all** — `ToolSearch` returns no match —
#     so there was no call to route and no denial to observe. The probe is INCONCLUSIVE, not negative.
#
#     **The consequence, stated at full strength: if the routing does not happen, this control is
#     INERT while reading as installed** — which is the failure shape this repository names by name.
#     Nothing in this suite, and nothing in CI, can tell the two apart.
#   * it does not prove the loop stopped raising action pendencies. Three of the four blind spots in
#     the guard's header are unreachable from any string test, and one of them — labels that
#     paraphrase the act without naming it — is the likeliest next violation.
#
# Run: bash hooks/scripts/action-pendency-guard.test.sh

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$HERE/action-pendency-guard.sh"
HOOKS_JSON="$HERE/../hooks.json"
pass=0
fail=0

ok()  { printf 'ok    %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL  %s\n     %s\n' "$1" "$2"; fail=$((fail + 1)); }

PR='https://github.com/tedeuxx/tadeumendonca-skills/pull/397'

# one_q <question> <label1> <desc1> <label2> <desc2> -> the hook's stdout
one_q() {
  jq -n --arg q "$1" --arg l1 "$2" --arg d1 "$3" --arg l2 "$4" --arg d2 "$5" \
    '{tool_name:"AskUserQuestion",
      tool_input:{questions:[{question:$q,header:"h",multiSelect:false,
        options:[{label:$l1,description:$d1},{label:$l2,description:$d2}]}]}}' \
    | bash "$HOOK" 2>/dev/null
}

assert_deny() {
  local label="$1" out
  shift
  out="$(one_q "$@")"
  if printf '%s' "$out" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
    ok "$label"
  else
    bad "$label" "expected deny, got: ${out:-<empty>}"
  fi
}

assert_allow() {
  local label="$1" out
  shift
  out="$(one_q "$@")"
  if [ -z "$out" ]; then
    ok "$label"
  else
    bad "$label" "expected silence, got: $out"
  fi
}

# ── the positives — both halves present ────────────────────────────────────────────────────────
# The instance that produced the rule, reconstructed from the real payload.
assert_deny 'the merge picker that produced this rule is denied' \
  'A #397 continua aberta.' \
  'Mergeio agora (Recomendado)' "$PR — merge commit de verdade, sem squash." \
  'Deixa para amanhã' 'Nada se perde.'

assert_deny 'the verb in the SECOND option is caught too' \
  'O que fazemos com a branch?' \
  'Deixa para amanhã' 'Nada se perde.' \
  'Merge agora' "$PR"

assert_deny 'a publish action pendency is denied' \
  'O artigo está pronto.' \
  'Publica' "$PR" \
  'Espera' 'Fica em preview.'

assert_deny 'the link may sit in the QUESTION rather than an option' \
  "Pronto para mergear: $PR" \
  'Merge' 'agora' \
  'Depois' 'amanhã'

assert_deny 'a non-github forge host is matched — the shape identifies the object, not the host' \
  'Pronto.' \
  'Merge agora' 'https://gitlab.example.com/acme/widget/merge_requests/12' \
  'Depois' 'amanhã'

# ── the negatives — the direction that must not regress ────────────────────────────────────────
assert_allow 'a genuine decision citing a PR is NOT denied — no execution verb in any label' \
  "O gate reprovou $PR." \
  'Reverter' 'volta ao estado anterior' \
  'Corrigir para frente' 'novo commit sobre o merge'

# THE ARM ABOVE PASSED FOR THE WRONG REASON AND THE GATE CAUGHT IT. Its labels are Portuguese, where
# the object noun never appears — `Reverter` contains no `merge` — so it asserted nothing about
# whether a verb in a NON-LEADING position fires. The English spelling of the identical scenario was
# DENIED by the guard, and it is the exact scenario the guard's own header cites as its reason for
# reading labels only. Kept as-is and paired below rather than replaced: the pair is the record that
# a green arm is not evidence until you know which input would redden it.
assert_allow 'the ENGLISH spelling of the same decision — `merge` as the OBJECT of `revert`' \
  "The gate rejected $PR." \
  'Revert the merge' 'back to the previous state' \
  'Fix forward' 'a new commit on top of it'

assert_allow 'a verb in any non-leading position is not the act being offered' \
  "About $PR" \
  'Undo the deploy' 'roll it back' \
  'Keep it' 'leave as is'

assert_allow 'approve/request-changes is a JUDGEMENT and survives — the header argues this by name' \
  "Revisei $PR." \
  'Aprovar' 'sem ressalvas' \
  'Pedir mudanças' 'com os achados'

assert_allow 'a verb in a DESCRIPTION does not fire — only labels offer the act' \
  'Como seguimos?' \
  'Reverter' "eu faria merge de $PR depois" \
  'Seguir' 'sem tocar nele'

assert_allow 'an execution verb with NO object link passes — the named blind spot, asserted' \
  'E a branch?' \
  'Merge agora' 'sem link nenhum aqui' \
  'Depois' 'amanhã'

# TWO OR MORE VERB-INITIAL LABELS MEANS THE ACT IS SETTLED AND THE PARAMETER IS THE QUESTION.
# Both shapes below are produced by this repository and both were DENIED by the anchored-only match.
assert_allow 'same verb on every label — the act is settled, the PARAMETER is the decision' \
  "Ready to cut: $PR" \
  'Release minor' 'new skill, additive' \
  'Release patch' 'content fix only'

assert_allow 'two verb-initial labels differing in WHEN, not whether' \
  "About $PR" \
  'Deploy on merge' 'immediately' \
  'Deploy on tag' 'held until the release'

assert_allow 'a scope trade with no link and no verb is untouched' \
  'O item cresceu.' \
  'Fatiar em dois' 'entrega metade agora' \
  'Manter inteiro' 'gasta mais tokens'

assert_allow '"merged" inside a longer word is not a verb hit' \
  "Sobre $PR" \
  'Mergedown do log' 'nada a ver' \
  'Outra coisa' 'idem'

# ── fail-open, which is the deliberate trade and must stay asserted ────────────────────────────
out="$(printf '' | bash "$HOOK" 2>/dev/null)"
[ -z "$out" ] && ok 'empty stdin fails open' || bad 'empty stdin fails open' "got: $out"

out="$(printf 'not json' | bash "$HOOK" 2>/dev/null)"
[ -z "$out" ] && ok 'unparseable stdin fails open' || bad 'unparseable stdin fails open' "got: $out"

out="$(jq -n '{tool_name:"AskUserQuestion",tool_input:{}}' | bash "$HOOK" 2>/dev/null)"
[ -z "$out" ] && ok 'a payload with no questions array fails open' || bad 'no questions array' "got: $out"

# ── the registration, without which every assertion above is theatre ───────────────────────────
if jq -e '.hooks.PreToolUse[] | select(.matcher == "AskUserQuestion")
          | .hooks[] | select(.command | contains("action-pendency-guard.sh"))' \
     "$HOOKS_JSON" >/dev/null 2>&1; then
  ok 'the guard is registered on the AskUserQuestion PreToolUse matcher'
else
  bad 'the guard is registered on the AskUserQuestion PreToolUse matcher' \
      'hooks.json routes nothing to this script — every assertion above tests an unreachable guard'
fi

# ── the standard this enforces must carry the PARTITION, or the guard refuses an unpublished rule ──
# The needle is the partition's own table header, NOT a prose mention of the words. A mention is
# cheap and any paragraph could satisfy it; the two-column row is the distinction itself, so this
# goes red if the partition is deleted, merged back into one class, or reduced to narrative. That
# choice is the fix for this arm's first form, which needled `ACTION pendency` and went red against
# a standard that already carried the partition — spelled `**ACTION**` inside the table.
STD="$HERE/../../skills/engineering-standards/SKILL.md"
if grep -qF 'a **DECISION** pendency | an **ACTION** pendency' "$STD" 2>/dev/null; then
  ok 'the escalation standard carries the DECISION/ACTION partition the guard keys on'
else
  bad 'the escalation standard carries the DECISION/ACTION partition the guard keys on' \
      "$STD does not carry the partition table — the guard would be refusing a rule nobody published"
fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
