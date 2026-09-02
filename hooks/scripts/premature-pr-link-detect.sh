#!/usr/bin/env bash
# purpose: say so when a turn handed the owner a pull-request link for a PR that is not ready to merge with every check concluded successfully
# premature-pr-link-detect.sh — Stop hook: at the end of a turn, say so when the turn HANDED THE OWNER
# a pull-request link for a PR that is not ready for him.
#
# ── WHAT THIS EXISTS FOR (#327) ─────────────────────────────────────────────────────────────────
# The owner's own words, and they are the rule rather than a summary of it:
#
#   "eu apenas quero receber links de PR quando tiver pronto para merge com todos check concluidos
#    com sucesso"
#
# The condition is CONJUNCTIVE: ready to merge AND every check complete and successful. A PR whose
# pipeline is still running does not qualify however green it looks so far, and a red pipeline is the
# loop's to fix without involving him. Four premature links in one session were four false alarms —
# a link in his hands reads as "something is waiting for me", whatever sentence sits beside it, and
# that reading is correct: under ADR-0002 amendment #16 the gate merges the safe class AND the
# boundary class itself, so almost every open PR is one he has nothing to do with.
#
# The operative wording is `commands/autonomy.md`'s *Reporting* section; the argument, the rejected
# options and the residual this rule makes bite are ADR-0002's eighteenth amendment. This file is the
# enforcement half, and it exists because the owner asked for one in those terms: "esse o comportamento
# que quero que vc faca enforcement no harness config".
#
# ── WHAT MAKES A LINK LEGITIMATE HERE — three conditions, all mechanical ────────────────────────
# 1. the PR is OPEN;
# 2. every check on its current head has COMPLETED and SUCCEEDED, and there is at least one;
# 3. the gate posted `APPROVE-PENDING-HUMAN` **or `APPROVE-EXECUTOR-BLOCKED`** against that same head.
#
# (3) is what turns "ready to merge" into "ready for HIM". `agents/quality-assurance.md`'s "Your verdict
# — exactly one of" enumerates **five** literals since #374, and exactly TWO of them mean the remaining
# act is the owner's: `APPROVE-PENDING-HUMAN`, posted when one of the four surviving holds fired, and
# `APPROVE-EXECUTOR-BLOCKED`, posted when the gate cleared the diff and could not execute the merge.
# THE HOLD COUNT IS NOT WHAT THIS READS, deliberately — `REQUEST-CHANGES` is also non-merging and is
# emphatically not an owner summons, it routes to the builder. Reading the literal is checkable;
# reading "which of four holds applied" is not.
#
# `APPROVE-AND-MERGE` and `APPROVE-AND-MERGE-BOUNDARY` are clearances the gate acts on itself, and
# since #374 they are **silent here rather than flagged** — see the narrowing at the `case` below.
#
# ── DETECTION, NEVER PREVENTION — the same terms `zombie-loop-detect.sh` uses ───────────────────
# This is a `Stop` hook. It fires AFTER the text has already reached the owner. It cannot un-send a
# link; it can only make the mistake visible in the same turn instead of a session later. Every exit
# path is `exit 0`, the only mechanism used is `additionalContext`, no `decision` field is ever emitted
# and this script never exits 2. There is nothing left to prevent by the time it runs, and a reader who
# takes a silent turn as compliance is reading something this hook does not say.
#
# ── IT READS THE ORCHESTRATOR'S PROSE AND NOTHING ELSE, AND THAT IS THE RULE'S OWN SHAPE ────────
# Measured on #327 against a real transcript: `tool_result` blocks carry the IDENTICAL five PR URLs at
# identical counts as the assistant's prose blocks, because `gh pr create` prints the URL as its own
# stdout. So a rule written against the CHARACTER SEQUENCE would forbid nothing and would fail open
# exactly where it looked strictest — every PR the loop opens surfaces its own URL whatever any rule
# says. The rule is about DIRECTING THE OWNER'S ATTENTION, so this hook reads assistant `text` blocks
# only. A URL echoed by a tool he watched run is not a summons; one the orchestrator HANDS him is.
# Widening this to `tool_result` would fire on every legitimate `gh pr create` and is not a fix.
#
# ── THE FORM THE RULE RECOMMENDS IS THE FORM THIS HOOK CANNOT CHECK. Say it, do not imply coverage ──
# GitHub shares ONE NUMBER SPACE between Issues and PRs, so a bare `#508` in prose cannot be classified
# as issue-or-PR without a network call — and the bare number is exactly the substitute the rule
# recommends over a link. This hook therefore matches FULL URLs only:
# It polices the form the rule discourages and is blind to the form it endorses.
# That is a real hole, it is not closable at this layer, and it is written here rather than left for a
# future reader to assume away.
#
# ── OTHER PLACES IT FAILS OPEN, all named ───────────────────────────────────────────────────────
# * A link surfaced in a turn whose PR cannot be read (`gh` failure, no network, private repo) is
#   skipped, not flagged — an unclassifiable link is not a finding.
# * `MAX_URLS` distinct URLs are examined per turn; a report listing more is examined only that far.
#   One `gh pr view` per distinct URL is the cost, and an uncapped report is an uncapped bill.
#   AND THE WORD "TURN" DEPENDS ON A HUMAN RECORD EXISTING. The awk pass below resets its buffer on
#   each real human turn, so in an autonomous continuation that emits NO `user` record between turns
#   the buffer spans the whole run and `MAX_URLS` becomes a PER-RUN cap, not a per-turn one: the
#   fourth distinct URL of the run is never examined. This degrades toward SILENCE, never toward a
#   wrong clearance — it is a usefulness limit, not a correctness one, and it is why an unexamined
#   link and a compliant turn look identical from outside. Raising the cap trades bill for coverage
#   and settles nothing about which of the two a silent turn was.
#
# ── AND THE ONE PLACE IT FAILS THE OTHER WAY: it fires on a link that is LEGITIMATE ─────────────
# The rule has a second limb this hook does not implement and cannot: a PR link is also legitimate
# when the ask is explicitly A DECISION THE OWNER HOLDS (a title, a positioning call), stated as that
# and not as a merge request. Such a PR frequently has NO gate verdict at its head at all — the gate
# has not run yet — so condition (3) above classifies it as premature and this hook emits a notice.
# "Is this ask a decision he holds" is not knowable at any layer, and making it guessable would be
# theatre. The cost is bounded by this being DETECTION ONLY: a spurious notice in the next turn's
# context, never a withheld link. That bound is load-bearing — if this hook were ever made preventive
# it would suppress exactly the links the owner asked to keep. See `commands/autonomy.md` and
# ADR-0002's eighteenth amendment, both of which state the second limb in the operative wording.
# * Silent on: no `jq`, no `gh`, no git dir, an unreadable transcript, `stop_hook_active`. Inherited
#   from the sibling Stop hooks and correct — absence of a notice never means compliance.
#
# ── WHY IT KEYS ON THE URL'S OWN PR NUMBER AND NOT ON THE CURRENT BRANCH ────────────────────────
# `zombie-loop-detect.sh` keys on `git branch --show-current`, which is right for its question (is THIS
# branch's PR outstanding?) and wrong for this one: a report naming PR #509 while checked out on #511's
# branch would check the wrong PR and clear the wrong link. The owner/repo/number all come out of the
# URL that was actually surfaced, and `--repo` is passed explicitly so a report about another repo is
# read against that repo.
#
# ── REUSE VS EXTRACTION, and the drift this accepts ────────────────────────────────────────────
# This is a THIRD independent reader of the ADR-0006 `gatekeeper-verdict` marker, after `session-wip.sh`
# and `zombie-loop-detect.sh` — same marker, same author filter, same head match, same "last match wins"
# rule, same "literal is on the line AFTER the marker". `zombie-loop-detect.sh`'s own header argues
# against extracting the shared reader mid-slice and that argument has not changed; the cost is that a
# drift between three readers is caught by a reviewer diffing three test files, not by any gate.
#
# ── WHERE THE DEBOUNCE STATE LIVES ─────────────────────────────────────────────────────────────
# Under the checkout's own `.git/` directory, keyed by `session_id` and by (pr_number, head SHA) — the
# same choice and the same three reasons as the sibling Stop hooks: never git-tracked so it cannot leak
# into a diff, already scoped to this checkout, resolved correctly under a `git worktree`. A hook
# subprocess is not handed the session scratchpad path, so that is not an option. NO GIT DIR, NO
# NOTICE: without somewhere to hold the debounce this would nag every turn, which is the shape that
# gets routed around within a week.
#
# Contract: receives the Stop event JSON on stdin (`transcript_path`, `session_id`, `cwd`,
# `stop_hook_active`); prints Stop hookSpecificOutput carrying `additionalContext` when a notice is due,
# and exits 0 either way.

set -uo pipefail

MAX_URLS=3
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

# ── TURN SCOPING, and it is the whole reason this is affordable ─────────────────────────────────
# One line per transcript record: `H` for a REAL human turn, `A<TAB><the assistant's text>` for an
# assistant turn's prose with newlines squashed to spaces. A human turn is distinguishable from a tool
# return by the SHAPE of `.message.content` — a string (or an array whose first block is `text`) for a
# person, a `tool_result` block for a tool. Measured on #327 against a real transcript: 54 string + 1
# text human turns against 196 `tool_result` entries.
#
# The awk pass keeps only the assistant lines since the LAST `H`, which is this turn. Without it the
# hook would re-read every PR URL the whole session ever mentioned and re-flag settled ones forever.
# `awk` rather than `tail -r`/`tac`: `tail -r` is BSD-only and `tac` is GNU-only, and this runs on both.
turn_prose="$(jq -r '
  if (.type=="user")
     and (((.message.content|type)=="string")
          or (((.message.content|type)=="array") and (((.message.content[0]?.type) // "")=="text")))
  then "H"
  elif (.type=="assistant")
  then ("A\t" + ([.message.content[]? | select(.type=="text") | .text] | join(" ") | gsub("[\r\n]"; " ")))
  else empty end' "$transcript" 2>/dev/null \
  | awk '/^H/{buf=""} /^A/{buf = buf $0 "\n"} END{printf "%s", buf}' || true)"
[ -z "$turn_prose" ] && exit 0

urls="$(printf '%s\n' "$turn_prose" \
  | grep -oE 'https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/pull/[0-9]+' \
  | sort -u | head -n "$MAX_URLS" || true)"
[ -z "$urls" ] && exit 0

command -v git >/dev/null 2>&1 || exit 0
git_dir="$(git -C "$cwd" rev-parse --git-dir 2>/dev/null || true)"
[ -z "$git_dir" ] && exit 0
case "$git_dir" in
  /*) : ;;
  *)  git_dir="$cwd/$git_dir" ;;
esac
state_dir="$git_dir/premature-pr-link-detect"
mkdir -p "$state_dir" 2>/dev/null || true

command -v gh >/dev/null 2>&1 || exit 0

findings=""
while IFS= read -r url; do
  [ -z "$url" ] && continue
  repo="$(printf '%s' "$url" | sed -n 's#^https://github\.com/\([^/]*/[^/]*\)/pull/[0-9]*$#\1#p')"
  num="$(printf '%s' "$url" | sed -n 's#^.*/pull/\([0-9]*\)$#\1#p')"
  [ -z "$repo" ] && continue
  [ -z "$num" ] && continue

  pr_json="$(gh pr view "$num" --repo "$repo" --json state,headRefOid,statusCheckRollup,comments 2>/dev/null || true)"
  [ -z "$pr_json" ] && continue

  # One jq pass returns three tab-separated facts: the PR state, the check rollup reduced to one word,
  # and the gate's verdict literal at the CURRENT head.
  #
  # The rollup carries two shapes and both must be read or the answer is wrong for half the checks: a
  # `CheckRun` has `status` + `conclusion`, a `StatusContext` has only `state`. A rollup that is EMPTY
  # is `nochecks`, which is NOT green — "todos check concluidos com sucesso" is unsatisfiable when
  # there are none, and treating an empty rollup as success is the fail-open a lazy `all` gives you.
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
    | [$st, $checks, $verdict, $h] | @tsv' 2>/dev/null || true)"
  [ -z "$facts" ] && continue

  state="$(printf '%s' "$facts" | cut -f1)"
  checks="$(printf '%s' "$facts" | cut -f2)"
  verdict="$(printf '%s' "$facts" | cut -f3)"
  head_sha="$(printf '%s' "$facts" | cut -f4)"
  [ -z "$head_sha" ] && continue

  marker_file="$state_dir/${session_id:-nosession}-$(printf '%s' "$repo" | tr '/' '-')-${num}-${head_sha}"
  [ -f "$marker_file" ] && continue

  reason=""
  case "$state" in
    OPEN) : ;;
    *) reason="the PR is $state, so there is nothing for him to merge" ;;
  esac
  if [ -z "$reason" ]; then
    case "$checks" in
      green)    : ;;
      running)  reason="a check is still running — 'todos check concluidos' is not satisfied by a check that has not concluded" ;;
      failing)  reason="a check has not succeeded — a red pipeline is the loop's to fix, not his to look at" ;;
      nochecks) reason="no check has reported at all, so 'todos check concluidos com sucesso' cannot be true of it" ;;
      *)        reason="the check rollup could not be read" ;;
    esac
  fi
  if [ -z "$reason" ]; then
    # ── NARROWED, NOT WIDENED (#374) ─────────────────────────────────────────────────────────────
    # The catch-all treated *not APPROVE-PENDING-HUMAN* as *premature*, which fused two states that are
    # not alike: `REQUEST-CHANGES` (genuinely premature — the diff is not finished) and
    # `APPROVE-AND-MERGE(-BOUNDARY)` (NOT premature — the PR is finished, and only WHO EXECUTES is
    # open). The false positive is on disk rather than reasoned about: a debounce marker from PR #373
    # reads "the verdict at this head is APPROVE-AND-MERGE, not APPROVE-PENDING-HUMAN — the gate acts
    # on that itself", written about a link the owner had asked for.
    #
    # SILENT, NOT APPROVED, and the distinction is the whole of the arm. A link to a cleared-but-
    # unmerged PR is AMBIGUOUS, not legitimate: it could be a race (verdict, merge seconds later) or a
    # strand. Clearing it would let this hook certify what it cannot judge. **Detection hooks should be
    # silent where they are ignorant.**
    #
    # PRICED CAVEAT: after this, a genuinely premature link on a cleared-but-unmerged PR is flagged by
    # nothing. Correct trade — the hook was flagging it for the wrong reason AND giving the wrong
    # instruction ("Report STATE in prose instead"), which on the motivating incident is what pushed the
    # link the owner was asking for down to character 439 of a turn that opened with two paragraphs
    # about rule 7b.
    #
    # AND THE INVERSE TRIGGER IS NOT FOLDED IN HERE. "A URL is absent" shares no code path, no debounce
    # semantics and no notice text with "a URL is present". One hook with two rulers is unattributable
    # in both directions; the absence case is `owed-pr-link-detect.sh`.
    case "$verdict" in
      # the two literals that mean the remaining act is the owner's — a link is exactly right
      APPROVE-PENDING-HUMAN|APPROVE-EXECUTOR-BLOCKED) : ;;
      # cleared: the PR is finished and who executes is a different question from whether this link
      # was premature. Say nothing.
      APPROVE-AND-MERGE|APPROVE-AND-MERGE-BOUNDARY) : ;;
      none) reason="no quality-assurance verdict at this head — the gate has not run, so nothing says the remaining act is his" ;;
      *)    reason="the verdict at this head is $verdict, which is neither a hold that hands him the decision (APPROVE-PENDING-HUMAN, APPROVE-EXECUTOR-BLOCKED) nor a clearance — so nothing says the remaining act is his" ;;
    esac
  fi

  [ -z "$reason" ] && continue

  printf '%s' "$reason" > "$marker_file" 2>/dev/null || true
  findings="$findings
  - ${url} — ${reason}"
done <<EOF
$urls
EOF

[ -z "$findings" ] && exit 0

context="This turn handed the owner a pull-request link for a PR that is not ready for him:
$findings

The rule, in his words (#327): \"eu apenas quero receber links de PR quando tiver pronto para merge com
todos check concluidos com sucesso\". The condition is conjunctive — ready to merge AND every check
complete and successful — and the mechanical reading of \"ready for him\" is a quality-assurance verdict
of APPROVE-PENDING-HUMAN or APPROVE-EXECUTOR-BLOCKED at the PR's current head, the two literals of five
that mean the remaining act is the owner's.

Report STATE in prose instead: what shipped, what is in flight, what is blocked. Hand over the link when
the remaining act is his — and when you do, put the ask FIRST. This hook has nothing to say about
placement and cannot: on the incident that produced #374 the link was in his hands twice before he asked
for it, at character 20 and at character 439, and an index threshold would have passed the first (an
announcement) and flagged the second (the actual ask).

This is premature-pr-link-detect.sh (#327), a Stop hook. It is DETECTION, NEVER PREVENTION — it fires
after the text already reached him, so there is nothing left to refuse; it gates nothing and decides
nothing. It reads the assistant's own prose only, never a tool's output, because \`gh pr create\` prints
the URL itself and forbidding the character sequence would forbid nothing. It matches full URLs only: a
bare #NNN cannot be told from an Issue number without a network call, so the shorthand the rule
RECOMMENDS is the form this hook cannot check.

Fires at most once per (PR, head SHA) per session."

jq -n --arg c "$context" '{
  hookSpecificOutput: {
    hookEventName: "Stop",
    additionalContext: $c
  }
}'
exit 0
