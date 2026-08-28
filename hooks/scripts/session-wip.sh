#!/usr/bin/env bash
# purpose: tell a starting session what is already open, so an inherited PR queue surfaces on its own instead of waiting for someone to remember to look
# session-wip.sh — SessionStart hook: surface the open PR queue before work begins.
#
# The companion to wip-guard.sh, aimed at the other half of the same failure. The
# guard stops the queue GROWING; this stops it staying INVISIBLE. Inherited PRs sat
# open across sessions and only surfaced because someone thought to look — which is
# precisely the kind of state a session should be told, not asked to remember.
#
# Injects context, never blocks. A session must always be able to start.
#
# Contract: prints SessionStart JSON carrying additionalContext, exits 0. Silent on
# any error (no gh, no auth, not a repo, no network) — an unavailable queue is not
# a reason to interrupt.

set -uo pipefail

command -v gh >/dev/null 2>&1 || exit 0

open_prs="$(gh pr list --state open --json number,title,author,createdAt,isDraft 2>/dev/null || true)"
[ -z "$open_prs" ] && exit 0

count="$(printf '%s' "$open_prs" | jq 'length' 2>/dev/null || true)"
case "$count" in
  ''|0) exit 0 ;;
esac

# Has this PR been through the merge gate, on THE CODE THAT IS THERE NOW?
#
# Listing a PR without that fact says precisely the same thing about one the gate approved
# and one nobody ever dispatched — which is the half of INVISIBLE this hook did not cover.
# Measured, and it is why this exists: two PRs were opened in one session, sat green and
# MERGEABLE, and nothing anywhere distinguished them from reviewed ones. The owner noticed,
# not the machine.
#
# The gate's verdict is already an artifact — a PR comment carrying the marker below plus the
# head it read (ADR-0006). Nothing new is being invented here; this is a READER for a record
# that was decided and then read by nobody. The SHA must match, because a verdict on a
# superseded head is not a verdict on this code.
#
# WHAT THIS CANNOT DO, stated so it is a known bound and not an assumed one: a dispatch that
# never happens is not a tool call, so no hook can intercept it. This fires at SessionStart,
# which means it surfaces the omission ONE SESSION LATE, and the context reaches the parent
# only — a subagent never sees it. Detection, not prevention. Prevention is not available in
# this architecture.
MARKER='<!-- gatekeeper-verdict: quality-assurance -->'

# Silence on failure is deliberate and matches the contract above: if the per-PR read fails
# (no auth, rate limit, no network), the line stays exactly as it read before this existed.
# An unavailable answer is not a finding, and MUST NOT render as "not reviewed" — that would
# make the hook lie in precisely the direction that erodes trust in it.
#
# THE AUTHOR FILTER IS NOT DECORATION. These repos are PUBLIC, and the head SHA is public with
# them. Without it, one comment from any GitHub account carrying the marker and that SHA makes
# a genuinely unreviewed PR render clean — the one failure direction that matters here, since
# a missing annotation reads as "fine" while a spurious one is only noise. `authorAssociation`
# already rides in the same payload, so this costs no extra call. It bounds who can SUPPRESS
# the mark; it cannot prove who wrote a conforming comment, because every context holding the
# owner's token reports OWNER (ADR-0006's impersonation residual, unchanged by this).
#
# IT REPORTS THE VERDICT, NOT WHETHER ONE EXISTS, and that is the whole of this revision.
# The boolean version rendered a BLOCKED PR identically to an approved one — measured on
# `-io`#357, which sat at REQUEST-CHANGES while this listing said nothing about it. The queue
# listing exists to answer "which of these still needs something", and on the one PR where
# the answer was "yes, one dispatch" it was silent. A control that removes itself exactly
# when it is needed is worse than no control, because the reader has learnt to trust it.
#
# Reading the literal is expressible where reading prose would not be: the verdict set is a
# CLOSED ENUMERATION of FOUR since 2026-08-23 (three before it), defined in
# `agents/quality-assurance.md` under *Your verdict —
# exactly one of*, and the marker template is a projection of that same set. ADR-0004's
# "Which layer carries a control" section draws exactly this line, under *Two rules this decision
# earned* — a control over a closed set the author wrote may be recorded as closed; one over a
# caller-controlled grammar may not. (That was record 0008's first 2026-08-04 amendment until
# 2026-08-20, when the record was absorbed.)
#
# An UNRECOGNISED literal is reported rather than passed over. That is verdict drift — a gate
# posting a word its own persona does not define — and it is the failure the merge-precondition
# decision was opened for (record 0007 until 2026-08-20; now ADR-0004's "The merge precondition is a
# floor, not an instruction" section). Rendering it as "fine" would hide the one thing that check
# exists to see.
#
# THE LAST MATCH, NOT THE FIRST (`.[-1]`), and it is an ordinary path rather than an edge case:
# a re-review posts a second verdict at the same head. With `.[0]`, an APPROVE-AND-MERGE followed
# by a REQUEST-CHANGES rendered SILENT — this hook's own headline defect, on a path it did not
# cover. GitHub returns comments in creation order, so the last match is the current verdict.
# Until the two-verdict cases in the suite, the ordering was asserted by NOTHING: the suite stayed
# 32/32 under either index. Note the comment lives here and not inside the jq program — an
# apostrophe in a jq comment terminates the single-quoted shell string, which is how the first
# version of this note silently emptied the whole hook.
verdict_suffix() {
  pr_json="$(gh pr view "$1" --json headRefOid,comments 2>/dev/null || true)"
  [ -z "$pr_json" ] && return 0
  # Empty output means the read failed or the head is unknown — NOT "no verdict". The two are
  # different and only one is a finding; `none` is the explicit no-verdict value.
  verdict="$(printf '%s' "$pr_json" | jq -r --arg m "$MARKER" '
    def literal($lines; $m):
      ($lines | index($m)) as $i
      | if $i == null then "" else ($lines[$i + 1] // "" | gsub("^\\s+|\\s+$"; "")) end;
    (.headRefOid // "") as $h
    | if $h == "" then ""
      else [ .comments[]?
             | select((.authorAssociation // "") as $a
                      | ["OWNER","MEMBER","COLLABORATOR"] | index($a))
             | .body // ""
             | select(contains($m)) | select(contains($h))
             | literal(split("\n"); $m) ]
           | if length == 0 then "none" else .[-1] end
      end' 2>/dev/null || true)"
  case "$verdict" in
    '') : ;;                                   # unavailable — say nothing, per the contract above
    none) printf '%s' ' — NO quality-assurance verdict on the current head' ;;
    # BOTH merge-authorising literals render silently, and the second one is here for a reason the
    # `*)` arm below makes sharp: an unlisted-but-legitimate literal does not degrade to silence, it
    # is reported as a DEFECT IN THE GATE. So adding `APPROVE-AND-MERGE-BOUNDARY` to the verdict
    # vocabulary (ADR-0002 amendment #16) without adding it here would have made every correctly-
    # verdicted boundary PR read as a gate that posted a literal its own persona does not define.
    # `inventory-counts.test.sh` now asserts this list against `agents/quality-assurance.md`'s own
    # "Your verdict — exactly one of" section, so the next literal added there cannot land here late.
    APPROVE-AND-MERGE|APPROVE-AND-MERGE-BOUNDARY) : ;;  # reviewed and clear; the listing has nothing to add
    APPROVE-PENDING-HUMAN|REQUEST-CHANGES)
      printf '%s' " — quality-assurance returned ${verdict} on the current head" ;;
    *) printf '%s' " — quality-assurance posted an UNRECOGNISED verdict on the current head: ${verdict}" ;;
  esac
}

# Age matters more than count: a PR open for days is the signal, one opened minutes
# ago is just work in progress.
listing=""
while IFS= read -r number; do
  [ -z "$number" ] && continue
  line="$(printf '%s' "$open_prs" | jq -r --argjson n "$number" '
    .[] | select(.number == $n)
    | "- #\(.number) \(.title) — \(.author.login)\(if .isDraft then " [draft]" else "" end), opened \(.createdAt[0:10])"
  ' 2>/dev/null || true)"
  [ -z "$line" ] && continue
  listing="${listing}${line}$(verdict_suffix "$number")
"
done <<EOF
$(printf '%s' "$open_prs" | jq -r '.[].number' 2>/dev/null || true)
EOF
[ -z "$listing" ] && exit 0
listing="${listing%$'\n'}"

context="Open pull requests in this repo ($count):

$listing

A line marked NO quality-assurance verdict has not been through the merge gate on its
current head — either it was never dispatched, or the verdict it has is stale because the
branch moved since. Dispatch the gate before merging; that is the rule, and this line
exists because nothing else in the loop can tell you it was skipped.

A line naming a verdict — REQUEST-CHANGES or APPROVE-PENDING-HUMAN — HAS been through the
gate and is not done: the first needs changes and a re-review, the second needs the owner.
A line reporting an UNRECOGNISED verdict means the gate posted a literal its own persona
does not define, which is a defect in the gate rather than in the PR.

An UNMARKED line is still not proof of review: the annotation is omitted whenever the read
failed, so absence means reviewed-and-clear OR unknown.

Drain these: for each, the resolution is merge it, or close it with a reason —
leaving it open is neither. They do NOT block a new slice by count: a slice that
touches none of their files may start now, and \`wip-guard\` denies only on file
overlap, naming the PR and the files. What rots is a PR sitting behind one that
edits the same lines, so the one to finish first is whichever this next slice
would collide with. A bot's dependency PR counts as something to drain."

jq -n --arg c "$context" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $c
  }
}'
exit 0
