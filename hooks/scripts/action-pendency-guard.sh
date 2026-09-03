#!/usr/bin/env bash
# purpose: refuse a multiple-choice picker whose payload is an ACTION pendency — an act the human performs on an object the loop already produced — because manufacturing options there makes them re-derive a decision that was already taken
# action-pendency-guard.sh — PreToolUse hook on `AskUserQuestion`: DENY the picker when the pendency
# being raised is an ACTION pendency rather than a DECISION pendency.
#
# ── WHAT THIS EXISTS FOR ────────────────────────────────────────────────────────────────────────
# The owner's correction, 2026-09-03, verbatim, after a pending merge was raised as a four-option
# picker:
#
#   "agora entendi. se voce quer que eu faza merge isso nao é preciso mostrar em formato assim.
#    precisa ser algo direto como uma ordem e o link."
#
# and, naming the class rather than the instance:
#
#   "lembre-se disso para esse tipo especifico de pendencia hitl" / "que nao é uma pendencia de
#    decisao" / "é uma pendencia de acao" / "enforce isso" / "na config do harness customizada"
#
# **The escalation standard says an escalation ALWAYS carries options.** That sentence was written
# about DECISION pendencies and had no partition under it, so it read as covering everything that
# rises to the human. It does not. The standard now names two classes, and this hook enforces the
# boundary between them from one side only:
#
#   DECISION pendency — the loop reduced a trade to alternatives and cannot pick between them.
#                       The options ARE the work. -> the picker. Untouched by this hook.
#   ACTION pendency   — the decision is already taken and the only thing left is the human's hand
#                       on an object the loop produced. -> an order and a link, in prose.
#
# **Why options are actively harmful on the second class rather than merely redundant.** A picker
# asserts that a choice exists. Where none does, the human reads the alternatives, looks for the
# trade between them, finds none, and has to reconstruct the decision that was already taken in
# order to discover that it was already taken. The interruption that the whole unattended/attended
# split exists to keep short is spent rebuilding context for a question nobody is asking.
#
# ── THE TEST, STATED SO A READER CAN APPLY IT WITHOUT THIS HOOK ─────────────────────────────────
# **Is there a second option I would actually defend?** If not, it is an instruction, not a question.
#
# ── WHAT IS MATCHED — a CONJUNCTION, and each half disarms the other's false positives ──────────
# The rule fires only when BOTH are true of one `AskUserQuestion` payload:
#
#   1. an OBJECT LINK is present anywhere in the payload — a full URL of the shape
#      `<forge-host>/<owner>/<repo>/(pull|issues|merge_requests)/<n>`. The link is the tell: you
#      hand someone the address of a thing because you want them to touch it. A decision about
#      direction does not need one in its options.
#   2. an EXECUTION VERB appears in an option LABEL — merge / publish / deploy / release / tag /
#      install / plugin update. Labels only, never descriptions.
#
# **Why labels only.** A description may legitimately mention a merge while the question is about
# something else entirely ("revert, or fix forward on top of the merge?"). The label is what the
# human is being asked to CHOOSE, so it is the only place the act itself is being offered.
#
# **Why this verb set and not a wider one.** Every verb here names the pure EXECUTION of a decision
# already taken — the act adds no judgement. `approve` is deliberately ABSENT although it looks like
# it belongs: approving is a judgement, and "approve, or request changes" is a real decision with
# two defensible options. Widening this set to judgement verbs would deny genuine decision
# pendencies, which is the one failure this hook must not have.
#
# ── THE FALSE NEGATIVES, NAMED RATHER THAN LEFT FOR SOMEONE TO DISCOVER ─────────────────────────
# This hook is NARROW ON PURPOSE, and a green here is not a clean bill:
#
#  1. **An action pendency with no link passes.** "Merge the open PR" carries no URL and is
#     invisible here. The bare `#NNN` form the escalation standard RECOMMENDS is exactly the form
#     this hook cannot classify — a forge shares one number space between issues and pull requests,
#     so telling them apart needs a network call this layer does not make. Same blind spot, and the
#     same reason, as `premature-pr-link-detect.sh`.
#  2. **An action pendency about a non-forge object passes** — publishing an article, updating a
#     profile, paying a bill. There is no object link to key on.
#  3. **A picker whose labels paraphrase the act passes** — "Agora", "Amanhã", "Deixa comigo" beside
#     a pull-request URL is the same defect spelled without a verb, and nothing here sees it. This
#     is the likeliest way the rule is broken next, and widening the verb list cannot close it.
#  4. **It reads the payload, never the intent.** No layer can tell a manufactured option set from a
#     real one; this reads two string properties and stops.
#
# **So the mechanism is a floor under one recognisable shape, not coverage of the class.** The
# standard is the rule; this refuses its most legible violation.
#
# ── IT IS PREVENTION, WHICH IS RARE IN THIS TREE, AND THAT IS WHY IT MUST BE NARROW ─────────────
# Unlike the `Stop` detectors here, `PreToolUse` fires BEFORE the picker reaches the human, so a
# `deny` genuinely stops it. That is the reason for the conjunction and for the absent judgement
# verbs: a detector that fires one turn late costs a correction, while a guard that fires wrongly
# costs the loop the one instrument it has for raising a real trade.
#
# Contract: receives the PreToolUse JSON on stdin; denies by printing a permissionDecision JSON and
# exiting 0. FAILS OPEN (allows) on a missing `jq`, an unreadable payload, an absent `questions`
# array, or either half of the conjunction being absent — the same trade `permission-guard.sh` and
# `dispatch-premise-guard.sh` make, and for the same reason: a guard that wedges the loop cannot be
# repaired by the agent, because repairing it requires running commands.

set -uo pipefail

input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

command -v jq >/dev/null 2>&1 || exit 0

# Every option LABEL, one per line. This is the only field the verb test reads.
labels="$(printf '%s' "$input" \
  | jq -r '[.tool_input.questions[]?.options[]?.label // empty] | .[]' 2>/dev/null || true)"
[ -z "$labels" ] && exit 0

# The whole tool input as text, for the object-link test: question text, labels and descriptions.
payload="$(printf '%s' "$input" | jq -r '.tool_input // empty | tostring' 2>/dev/null || true)"
[ -z "$payload" ] && exit 0

# ── half 1 — the object link ───────────────────────────────────────────────────────────────────
# Host-agnostic on purpose: the shape `<host>/<owner>/<repo>/pull/<n>` is what identifies a forge
# object, and pinning one host would make the rule silently absent on every other forge.
link="$(printf '%s' "$payload" \
  | grep -oE 'https?://[A-Za-z0-9.-]+/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+/(pull|pulls|issues|merge_requests)/[0-9]+' \
  | head -1 || true)"
[ -z "$link" ] && exit 0

# ── half 2 — an execution verb in a LABEL ──────────────────────────────────────────────────────
# Execution only. No judgement verbs — see the header for why `approve` is absent by design.
VERBS='merge|mergeia|mergeio|mergear|mergeando|publica|publicar|publish|publishing|deploy|deploi|release|releasa|tag|tagueia|install|instala|plugin update|atualiza o plugin|atualizar o plugin'

hit="$(printf '%s\n' "$labels" | grep -iE "(^|[^a-zA-Z])($VERBS)([^a-zA-Z]|\$)" | head -1 || true)"
[ -z "$hit" ] && exit 0

reason="ACTION PENDENCY — this is not a decision, so it does not take a picker.

The payload offers an option labelled \"$hit\" beside $link. That is the human EXECUTING a decision
the loop has already taken, not choosing between alternatives the loop composed.

The owner's rule, verbatim: \"se voce quer que eu faza merge isso nao é preciso mostrar em formato
assim. precisa ser algo direto como uma ordem e o link.\"

WHY IT IS NOT A STYLE POINT: a picker asserts that a choice exists. Where none does, the reader
looks for the trade between the options, finds none, and has to reconstruct the already-taken
decision in order to learn that it was already taken — spending the interruption the AFK/HITL split
exists to keep short.

TO CLEAR IT: drop the tool. Put the ask FIRST in your reply, as one line — the act and the link:

    Merge #NNN: <url>

If you believe this IS a genuine decision, apply the standard's own test before re-raising it: IS
THERE A SECOND OPTION YOU WOULD ACTUALLY DEFEND? If yes, the options are about that trade rather
than about when to perform one act, and they should be labelled as the alternatives they are — a
label naming the execution verb is what this guard reads, and it is what makes an action pendency
look like a decision.

The standard is \`/engineering-standards\`, *The escalation standard* — the DECISION-vs-ACTION
partition. This guard enforces one recognisable shape of the violation and is blind to the rest;
its header lists what it cannot see."

jq -n --arg r "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $r
  }
}'
exit 0
