#!/usr/bin/env bash
# purpose: say so when a turn ended owing the owner a pull-request link — the PR is open, green, and the gate's verdict at its head says the remaining act is his — because the sibling hook only ever checks a link that WAS handed over
# owed-pr-link-detect.sh — Stop hook: at the end of a turn, say so when the turn ENDED OWING the owner
# a pull-request link and did not surface one.
#
# ── WHAT THIS EXISTS FOR (#374), AND THE PART TO READ FIRST ─────────────────────────────────────
#
# THIS HOOK DOES NOT ADDRESS THE INCIDENT THAT PRODUCED THE ISSUE IT WAS BUILT UNDER. Stating that up
# front is a condition of shipping it, and it is not modesty — it is the difference between a detector
# and a green that proves nothing.
#
# The owner's words, 2026-08-31: *"cade o link para merge entao? a comunicacao nao esta sendo direta e
# clara nas acoes HITL necessarias. precisamos de enforcement."* Measured against the session
# transcript, the character index of the PR URL inside each assistant turn's joined text blocks:
#
#   14:09:29   index 20    (message length 2070)   — a PR-OPENED announcement
#   14:33:06   index 439   (message length 1862)   — the actual ask, under two paragraphs about rule 7b
#   14:38:37   — the owner: "cade o link para merge entao?"
#   14:38:52   index 0     (message length 1576)
#
# **He had the link twice before he asked for it. The defect was PLACEMENT, not absence** — and an
# absence detector is silent on both of those turns. Ship it as the answer to that complaint and its
# silence reads as *communication was clear*, which is worse than no hook at all.
#
# So this covers the OTHER case, which is real and has also happened: a turn that ends with the PR
# genuinely owed and no link surfaced at all. The placement half is not here and is not buildable as a
# threshold — index 20 was the non-ask and index 439 was the ask, so a position rule would have passed
# the first and flagged the second.
# Position does not separate an announcement from a summons; only intent does, and intent is not in the string.
# That half lives on #362, whose open question 4 already
# carries it in the same terms (*"the limitation reached the owner twice as prose and neither time as a
# question. That is a behaviour, not a mechanism."*).
#
# ── WHY IT IS A SEPARATE FILE FROM `premature-pr-link-detect.sh` ────────────────────────────────
# It is the exact inverse of that hook's conditions 1–3 and it must not be folded into it. Their
# predicates are opposites — *a URL is present* against *a URL is absent* — so they share no code path,
# no debounce semantics and no notice text. One hook with two rulers is unattributable in both
# directions: a silent turn would mean either "no link was handed over and none was owed" or "a link was
# handed over and it was fine", and no reader could tell which.
#
# They also resolve the PR from opposite ends. The sibling reads the PR number OUT OF the URL that was
# surfaced, because that is the link being judged. This one has no URL by construction, so it resolves
# the current branch's open PR the way `zombie-loop-detect.sh` does. That is the right resolution for
# this question and the wrong one for the sibling's, which is a second reason the two cannot share a
# body.
#
# ── WHAT MAKES A LINK OWED — three conditions, all mechanical ───────────────────────────────────
# 1. the current branch has an OPEN pull request;
# 2. every check on its current head has COMPLETED and SUCCEEDED, and there is at least one;
# 3. the gate's verdict at that same head is one of the two literals that mean the remaining act is the
#    owner's: `APPROVE-PENDING-HUMAN` (one of the four holds fired) or `APPROVE-EXECUTOR-BLOCKED` (the
#    gate cleared it and could not execute the merge — #374's fifth literal).
#
# ...and the turn's own prose carried no URL for that PR.
#
# `APPROVE-AND-MERGE` and `APPROVE-AND-MERGE-BOUNDARY` are NOT in (3), deliberately. Those are
# clearances the gate acts on itself, and a PR sitting open under one of them is a RACE at any single
# instant — verdict, then merge seconds later — indistinguishable from a strand. Treating it as owed
# would fire on the healthy sequence every time. The fifth literal exists precisely so that the strand
# stops having to be inferred from a clearance that stayed open.
#
# `REQUEST-CHANGES` is not in (3) either, and it is worth stating rather than leaving to the reader:
# it routes to the BUILDER, not to the owner, so a PR carrying it owes him nothing. It reaches this
# hook only via the `*)` arm below, which exits silently — correct here, and the reason every literal
# in the brief is named in this header rather than only the ones that fire. A literal nobody wrote
# down is a literal nobody decided about, and `*)` swallows it either way.
#
# ── IT READS THE ORCHESTRATOR'S PROSE ONLY, for the sibling's measured reason ───────────────────
# `tool_result` blocks carry the identical PR URLs at identical counts, because `gh pr create` prints
# the URL as its own stdout. A rule that counted those would consider the link "surfaced" every time the
# loop opened a PR, whatever the orchestrator actually wrote. So the prose read is assistant `text`
# blocks only — same extraction, same turn scoping, same reason.
#
# ── DETECTION, NEVER PREVENTION ────────────────────────────────────────────────────────────────
# A `Stop` hook fires after the turn already reached the owner. It cannot add the link; it can only make
# the omission visible in the next turn instead of when he asks. Every exit path is `exit 0`, the only
# mechanism used is `additionalContext`, no `decision` field is ever emitted and this script never exits
# 2. A silent turn is not compliance: it is also every turn where `gh` failed, the branch had no PR, the
# debounce had already fired, or the read did not happen.
#
# ── WHERE THE DEBOUNCE STATE LIVES ─────────────────────────────────────────────────────────────
# Under the checkout's own `.git/` directory, keyed by `session_id` and by (PR number, head SHA) — the
# same choice and the same three reasons as the sibling Stop hooks: never git-tracked so it cannot leak
# into a diff, already scoped to this checkout, resolved correctly under a `git worktree`. NO GIT DIR,
# NO NOTICE. And the debounce is what keeps this from becoming a nag: a turn that legitimately ends
# without the link — the owner is asleep, the loop is drafting the message — is told once per head, not
# once per turn.
#
# Contract: receives the Stop event JSON on stdin (`transcript_path`, `session_id`, `cwd`,
# `stop_hook_active`); prints Stop hookSpecificOutput carrying `additionalContext` when a notice is due,
# and exits 0 either way.

set -uo pipefail

MARKER='<!-- gatekeeper-verdict: quality-assurance -->'

input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

command -v jq >/dev/null 2>&1 || exit 0

stop_hook_active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || true)"
[ "$stop_hook_active" = "true" ] && exit 0

transcript="$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null || true)"
[ -z "$transcript" ] && exit 0
[ -f "$transcript" ] || exit 0

session_id="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
[ -z "$cwd" ] && exit 0
[ -d "$cwd" ] || exit 0

command -v git >/dev/null 2>&1 || exit 0

# ── local-only preconditions: no network below this line unless a branch and a git dir exist ────
branch="$(git -C "$cwd" branch --show-current 2>/dev/null || true)"
[ -z "$branch" ] && exit 0

git_dir="$(git -C "$cwd" rev-parse --git-dir 2>/dev/null || true)"
[ -z "$git_dir" ] && exit 0
case "$git_dir" in
  /*) : ;;
  *)  git_dir="$cwd/$git_dir" ;;
esac
state_dir="$git_dir/owed-pr-link-detect"
mkdir -p "$state_dir" 2>/dev/null || true

command -v gh >/dev/null 2>&1 || exit 0

# ── first network call: is there an open PR for this branch at all? ─────────────────────────────
pr_list="$(gh pr list --head "$branch" --state open --json number,headRefOid --limit 1 2>/dev/null || true)"
[ -z "$pr_list" ] && exit 0
pr_number="$(printf '%s' "$pr_list" | jq -r '.[0].number // empty' 2>/dev/null || true)"
head_sha="$(printf '%s' "$pr_list" | jq -r '.[0].headRefOid // empty' 2>/dev/null || true)"
[ -z "$pr_number" ] && exit 0
[ -z "$head_sha" ] && exit 0

# ── debounce, checked BEFORE the heavier second call ────────────────────────────────────────────
marker_file="$state_dir/${session_id:-nosession}-${pr_number}-${head_sha}"
[ -f "$marker_file" ] && exit 0

# ── second network call: checks and the verdict at the current head, in one read ────────────────
# Same rollup handling as `premature-pr-link-detect.sh`: a `CheckRun` carries `status` + `conclusion`,
# a `StatusContext` carries only `state`, and an EMPTY rollup is `nochecks` rather than green — a PR
# with no check has not satisfied "every check concluded successfully", it has dodged the question.
pr_json="$(gh pr view "$pr_number" --json state,headRefOid,statusCheckRollup,comments 2>/dev/null || true)"
[ -z "$pr_json" ] && exit 0

facts="$(printf '%s' "$pr_json" | jq -r --arg m "$MARKER" '
  def literal($lines; $m):
    ($lines | index($m)) as $i
    | if $i == null then "" else ($lines[$i + 1] // "" | gsub("^\\s+|\\s+$"; "")) end;
  (.state // "") as $st
  | (.headRefOid // "") as $h
  | ([.statusCheckRollup[]?]) as $c
  | (if ($c | length) == 0 then "nochecks"
     elif ([$c[]
            | if ((.status // "") != "") then ((.status == "COMPLETED") and (.conclusion == "SUCCESS"))
              else ((.state // "") == "SUCCESS") end] | all) then "green"
     elif ([$c[] | ((.status // "") != "") and (.status != "COMPLETED")] | any) then "running"
     else "failing" end) as $checks
  | (if $h == "" then "nohead"
     else ([ .comments[]?
             | select((.authorAssociation // "") as $a
                      | ["OWNER","MEMBER","COLLABORATOR"] | index($a))
             | .body // ""
             | select(contains($m)) | select(contains($h))
             | literal(split("\n"); $m) ]
           | if length == 0 then "none" else .[-1] end)
     end) as $verdict
  | [$st, $checks, $verdict] | @tsv' 2>/dev/null || true)"
[ -z "$facts" ] && exit 0

state="$(printf '%s' "$facts" | cut -f1)"
checks="$(printf '%s' "$facts" | cut -f2)"
verdict="$(printf '%s' "$facts" | cut -f3)"

[ "$state" = "OPEN" ] || exit 0
[ "$checks" = "green" ] || exit 0

# The two literals that mean the remaining act is the owner's, spelled out and never globbed — the
# same closed-set discipline `permission-guard.sh` rule 7c states in its own words.
case "$verdict" in
  APPROVE-PENDING-HUMAN|APPROVE-EXECUTOR-BLOCKED) : ;;
  *) exit 0 ;;
esac

# ── did this turn actually surface the link? ────────────────────────────────────────────────────
# Turn scoping and the prose extraction are the sibling hook's, unchanged: `H` marks a real human turn
# (a string content, or an array whose first block is `text` — a `tool_result` is neither), `A` carries
# an assistant turn's joined text. The awk pass keeps only the assistant lines since the last `H`.
turn_prose="$(jq -r '
  if (.type=="user")
     and (((.message.content|type)=="string")
          or (((.message.content|type)=="array") and (((.message.content[0]?.type) // "")=="text")))
  then "H"
  elif (.type=="assistant")
  then ("A\t" + ([.message.content[]? | select(.type=="text") | .text] | join(" ") | gsub("[\r\n]"; " ")))
  else empty end' "$transcript" 2>/dev/null \
  | awk '/^H/{buf=""} /^A/{buf = buf $0 "\n"} END{printf "%s", buf}' || true)"

# A URL for THIS PR specifically. A link to some other pull request does not discharge this one, and a
# bare `#NNN` cannot be told from an Issue number without a network call — the same hole the sibling
# names, in the same direction: this hook is blind to the shorthand and therefore fires on a turn that
# used it. That is a false positive in a DETECTION-only notice, which is the cheap direction.
#
# THE NUMBER IS EXTRACTED AND COMPARED, NEVER SUBSTRING-MATCHED (#374 review). The first form was
# `case "$turn_prose" in *"/pull/${pr_number}"*)`, and a plain substring makes every PR number a
# PREFIX of every longer one. Measured through the hook end to end, with a control on each side:
#
#   PR 15, turn links /pull/15    -> silent   (correct — the link was handed over)
#   PR 15, turn links /pull/150   -> SILENT   ← FALSE NEGATIVE: a different PR discharged this one
#   PR 15, turn links /pull/99    -> fires    (correct)
#
# Detection-only, so the cost is a MISS rather than a false alarm — the quiet direction, and the one
# nobody notices. The sibling `premature-pr-link-detect.sh` never had this: it extracts full URLs with
# a bounded regex and parses the number exactly. This now does the same rather than adding a boundary
# character class, so the two hooks agree on what "a link to PR N" means.
if printf '%s\n' "$turn_prose" \
   | grep -oE 'https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/pull/[0-9]+' \
   | sed -n 's#^.*/pull/\([0-9]*\)$#\1#p' \
   | grep -qx "$pr_number"; then
  exit 0
fi

owner_act="the owner's decision on one of the four holds"
case "$verdict" in
  APPROVE-EXECUTOR-BLOCKED)
    owner_act="the owner's hand on the merge — the gate CLEARED this and could not execute (#374)" ;;
esac

context="This turn ended OWING the owner a pull-request link, and did not surface one.

  PR #${pr_number} (branch ${branch}, head ${head_sha})
  state OPEN · every check concluded successfully · quality-assurance verdict at this head: ${verdict}

All three conditions for 'ready for him' hold, and the remaining act is ${owner_act}. Nothing in this
turn's prose carried the URL, so as far as he can see the slice simply stopped.

Hand him the link, and put the ask FIRST. The standing rule is that anything needed FROM him goes first
and labelled as an ask, never buried at the end of a report — and this hook cannot check that half. On
the incident that produced it the link was in his hands twice before he asked for it, in both cases
mid-message, so the failure this hook detects is not the only one in
this family and is not the one that actually happened. (The measured offsets are in this file's own
header, where they are read once by a maintainer rather than reprinted into every session.)

This is owed-pr-link-detect.sh (#374), a Stop hook. It is DETECTION, NEVER PREVENTION — it fires after
the turn already reached him, so there is nothing left to refuse; it gates nothing and decides nothing.
It reads the assistant's own prose only, never a tool's output, because \`gh pr create\` prints the URL
itself and counting that would treat every opened PR as a link handed over. It matches full URLs only:
a bare #NNN cannot be told from an Issue number without a network call, so a turn that used the
shorthand is flagged here even though the shorthand is what the rule recommends.

Fires at most once per (PR, head SHA) per session."

printf '%s' "$context" > "$marker_file" 2>/dev/null || true

jq -n --arg c "$context" '{
  hookSpecificOutput: {
    hookEventName: "Stop",
    additionalContext: $c
  }
}'
exit 0
