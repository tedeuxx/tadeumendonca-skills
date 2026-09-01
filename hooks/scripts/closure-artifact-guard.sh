#!/usr/bin/env bash
# purpose: hold an Issue's closure against the artifact it promised, so the half a reader can invoke has to exist before the tracker says the work is done
# closure-artifact-guard.sh — two events, one predicate: an Issue that DECLARES an invocable
# artifact does not reach `closed` while that artifact does not resolve.
#
# ── WHAT THIS EXISTS FOR (#337) ─────────────────────────────────────────────────────────────────
# Three Issues closed with their operable half unbuilt. #313 shipped `docs/blueprint-registry.md`
# and closed with `/blueprint` non-existent — twice, the second time after being reopened for
# exactly that reason. #326 shipped the iteration rules and created none of the objects they
# operate on. #431 (sibling repo) shipped a truth-fix against a ratified ask for a detector, and
# the detector was never built. Every one of them was caught by a human asking, which is not a
# mechanism.
#
# ── THE MEASUREMENT THAT SHAPED THE DESIGN, AND IT KILLED THE OBVIOUS FORM ─────────────────────
# The obvious form is to DERIVE the promise from the Issue's own prose — pull every `/identifier`
# out of the title and body and require it to resolve. Measured on 2026-08-28 against the twenty
# most recently closed Issues in this repo, with the tightest grammar worth trying (a backticked
# span that is exactly `/name` or `/plugin:name`):
#
#     25 tokens extracted · 14 resolved · 11 did not
#     of the 11: `/architecture` x7  (a live command in the SIBLING repo, not this tree)
#                `/skill-doctor` x1  (a command that was PROPOSED and rejected)
#                `/193`, `/259`  x2  (issue numbers inside backticked spans)
#                                    — and one duplicate of `/architecture`
#     TRUE POSITIVES AT HEAD: ZERO.
#
# So a derived form reddens on eleven pieces of honest work to catch none. That is the failure this
# repo names most often: a gate that reddens on correct work gets loosened until it verifies
# nothing. The promise is therefore DECLARED, never inferred — the same call #335 reached from the
# other end (do not match prose) and the same shape `docs/blueprint-registry.md` already uses (a
# field label read literally is a parsing contract; a sentence is not).
#
# ── THE DECLARATION ─────────────────────────────────────────────────────────────────────────────
# A line at column 0 of the Issue BODY. One entry per line; more than one line is allowed.
#
#     invocable: /blueprint                      a plugin identifier
#     invocable: hooks/scripts/foo.sh            a repo-relative path
#     invocable: none                            declared: this Issue promises nothing invocable
#     invocable-waived: /blueprint <reason>      the promise was narrowed, and here is why
#
# `/name` resolves iff `commands/name.md` exists, or `skills/name/SKILL.md` exists AND `name` is
# declared in `.claude-plugin/plugin.json` — an undeclared skill does not exist to the model
# (CLAUDE.md, "DECLARATION is what registers a skill"), so it must not resolve here either. A
# namespaced spelling (`/plugin:name`) is reduced to its bare innermost name, which is what the
# loader reads at every depth this library has had.
#
# `invocable-waived:` is the recorded-narrowing escape the Issue asked for, and it is deliberately
# NOT a silent one: it is a line in the Issue body, attributable and dated by GitHub's own edit
# history, and it must carry a reason of at least 12 characters. #313's own narrowing (registry
# first, command later, recorded in ADR-0021) is the case this exists for — that Issue was right to
# ship half, and wrong to close.
#
# ── WHERE THE CHECK CAN LIVE — MEASURED, NOT ASSUMED ───────────────────────────────────────────
# Measured 2026-08-28: every Issue this loop closed in the last week closed by a CLOSING KEYWORD in
# a merged PR body (`Closes #313's slice 1`, PR #345; the same in #333, #340, #347, #348,
# #349). That close is executed by GitHub's servers on merge. NO HOOK IN THIS HARNESS OBSERVES IT
# AND ~~NO PERMISSION LAYER CAN DENY IT~~ -- SEE THE 2026-08-30 CORRECTION IMMEDIATELY BELOW.
# Prevention is therefore unavailable on the route that is actually used, and this script does not
# pretend otherwise:
#
#   PreToolUse (Bash) — PREVENTS, on the manual `gh issue close` route only. Measurably the
#                       minority route today. ~~It is the only refusal surface that exists~~
#                       (struck 2026-08-30, #363), it costs one string comparison on calls that are
#                       not `gh issue close`, and the "close with a criterion" rite in
#                       `/agents-configuration` is a real user of it.
#
# ── CORRECTION 2026-08-30 (#363) — TRUE OF THE CLOSE, FALSE OF THE MERGE ───────────────────────
# The two struck clauses above were the reasoning everything downstream inherited, and the second
# one was character-for-character what `README.md` and `docs/adr/0004` strike as false. Nothing can
# deny the forge's CLOSE — that half stands. But the close only happens because a MERGE happened,
# the merge IS a tool call, and `permission-guard.sh` rule 7d denies it when the PR's
# `closingIssuesReferences` contains an Issue the gate's head-scoped verdict does not declare on a
# `closes:` line. So there are two refusal surfaces, and the second one reaches the keyword route,
# one step upstream.
#
# THAT IS A DIFFERENT OBLIGATION OVER A DIFFERENT ARTIFACT, AND THIS SCRIPT IS NOT MADE REDUNDANT
# BY IT — BUT NEITHER DOES THIS SCRIPT PATCH RULE 7D'S HOLES, WHICH IS THE MISREADING TO REFUSE.
# Rule 7d compares two artifacts (the forge's resolved set against the gate's declaration) and
# never consults `invocable:` at all. THIS script fires only on an Issue that DECLARES a promise.
# Re-derived at head on the very Issue rule 7d was built from:
#
#     gh issue view 355 --json body --jq '[.body|split("\n")[]|select(test("^invocable"))]'
#     → []
#
# #355 declares NOTHING, so this script could not have fired on it by any route — including the
# route that actually closed it. AN UNDECLARED ISSUE CLOSED BY A BROWSER MERGE, OR BY A
# COMMIT-MESSAGE KEYWORD (which `closingIssuesReferences` does not see — measured: a PR carrying
# the keyword only in a commit message returns []), IS CAUGHT BY NOTHING AT ALL. Do not publish
# either mechanism as covering the other's residue.
#   Stop             — DETECTS, on every route including the keyword one, at the end of the turn
#                       in which the close happened. Same class as `zombie-loop-detect.sh` (#294):
#                       one turn late instead of one session late, never preventive.
#
# WHAT THAT MEASUREMENT IS EVIDENCE FOR, AND WHAT IT MUST NEVER BE REUSED TO ARGUE. It is read off
# PR BODIES, so it proves the keyword was PRESENT, not that the keyword is what fired — the timeline,
# which would prove that, is unreadable from here (`gh api` is denied by the global floor). The design
# needs ONE instance of a keyword close, not a share: dominance sets PRIORITY, never feasibility. And
# the residual error points the safe way, since any close that was actually manual makes the
# PREVENTABLE share LARGER than measured, so the shipped design is correct under the error too.
# THAT ASYMMETRY IS NOT A LICENCE TO RUN THE NUMBER BACKWARDS. It supports building the detector; it
# does NOT support a later argument that the manual route is rare enough to drop the refusal arm.
# Re-measure before claiming the reverse.
#
# A PR -> Issue resolution route was NOT built, on the owner's decision (#336 measured that nothing
# forces a `loop` PR to reference its Issue). This script never reads a PR.
#
# ── WHAT IT DOES NOT COVER, said before any green is read ──────────────────────────────────────
# 1. AN ISSUE THAT DECLARES NOTHING IS INVISIBLE HERE, AND NOTHING FORCES THE DECLARATION. That is
#    the load-bearing limit and it is not hidden: the field is written at intake by the lane's own
#    intake persona (`/agents-configuration`'s states table; `commands/new-issue.md` step 4b), which
#    is an instruction, not a mechanism. Applied to the three founding cases: this would have caught
#    #313 and #431 had their intake written the line, and it would NOT have caught #326 at all —
#    what #326 failed to build was labels and milestones in the TRACKER, and this gate resolves
#    artifacts in a TREE. Two of three, conditionally. That is the honest claim.
# 2. It never reads intent. A scope narrowed mid-slice is indistinguishable from a promise dropped
#    by accident UNLESS the narrowing is written as `invocable-waived:`. The waiver's reason text is
#    unfalsifiable by any instrument here — a reviewer's read, the same residual
#    `docs/blueprint-registry.md` states about `propósito`.
# 3. It resolves EXISTENCE, never behaviour. `commands/blueprint.md` containing one empty line
#    resolves exactly like the real one.
# 4. A cross-repo close (`gh issue close N --repo other/repo` from this tree) is NOT checked — the
#    tree that would answer the question is not the tree this process can see. It exits silently
#    rather than guessing.
# 5. The PreToolUse arm anchors at the START of the command string. A `gh issue close` buried after
#    a `&&` is not seen — and does not need to be, because `permission-guard.sh` denies the chain
#    itself on the same matcher.
#
# ── EXIT-CODE DISCIPLINE, AND THE DIRECTION IT FAILS IN ────────────────────────────────────────
# FAILS OPEN, everywhere: no `jq`, no `gh`, no `git`, an unreadable payload, an API error, a body
# that cannot be fetched — every one of those exits 0 with no decision. Same trade
# `permission-guard.sh` and `orchestrator-write-guard.sh` make and for the same reason (a guard
# that wedges the loop cannot be repaired by the agent, because repairing it requires running
# commands) — and it is the direction that MISLEADS, so it is stated here rather than discovered:
# a green from this hook can mean "checked and clean" or "could not check", and nothing downstream
# can tell the two apart.
#
# Contract: reads the hook payload on stdin. On `PreToolUse`, prints a permissionDecision JSON and
# exits 0. On `Stop`, prints hookSpecificOutput carrying `additionalContext` and exits 0. Silent on
# every other event.

set -uo pipefail

input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

command -v jq >/dev/null 2>&1 || exit 0
command -v gh >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

event="$(printf '%s' "$input" | jq -r '.hook_event_name // empty' 2>/dev/null || true)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
[ -z "$cwd" ] && exit 0
[ -d "$cwd" ] || exit 0

ROOT="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$ROOT" ] && exit 0

# ── the predicate, shared by both arms ─────────────────────────────────────────────────────────
# Resolve ONE declared entry against the tree. 0 = resolves, 1 = does not.
entry_resolves() {
  local entry="$1" name
  case "$entry" in
    none|NONE) return 0 ;;
    /*)
      name="${entry#/}"
      name="${name##*:}"          # /plugin:name -> name; the loader reads the innermost name
      [ -z "$name" ] && return 1
      [ -f "$ROOT/commands/$name.md" ] && return 0
      if [ -f "$ROOT/skills/$name/SKILL.md" ]; then
        jq -e --arg n "$name" '[.skills[]? | sub("^\\./"; "") | sub("^skills/"; "")] | index($n)' \
          "$ROOT/.claude-plugin/plugin.json" >/dev/null 2>&1 && return 0
      fi
      return 1
      ;;
    *)
      [ -e "$ROOT/$entry" ] && return 0
      return 1
      ;;
  esac
}

# Read a body and print one line per UNMET declaration. Empty output = nothing to say (either the
# Issue declares nothing, or everything it declares resolves or is waived).
unmet_entries() {
  local body="$1" waived line entry
  waived="$(printf '%s\n' "$body" \
    | sed -nE 's/^invocable-waived:[[:space:]]*([^[:space:]]+)[[:space:]]+(.{12,})$/\1/p')"
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    entry="$line"
    printf '%s\n' "$waived" | grep -qxF -- "$entry" && continue
    entry_resolves "$entry" || printf '%s\n' "$entry"
  done < <(printf '%s\n' "$body" | sed -nE 's/^invocable:[[:space:]]*([^[:space:]]+).*$/\1/p')
}

issue_body() {
  gh issue view "$1" --json body,title \
    --jq '(.title // "") + "\n" + (.body // "")' 2>/dev/null || true
}

# ════════════════════════════════════════════════════════════════════════════════════════════════
# ARM 1 · PreToolUse — refuse a manual close whose declaration is unmet
# ════════════════════════════════════════════════════════════════════════════════════════════════
if [ "$event" = "PreToolUse" ]; then
  cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
  [ -z "$cmd" ] && exit 0

  # Anchored at the start — see limit 5 in the header.
  case "$cmd" in
    "gh issue close "*) : ;;
    *) exit 0 ;;
  esac

  # A close aimed at another repository cannot be answered from this tree (limit 4).
  repo_flag="$(printf '%s\n' "$cmd" | sed -nE 's/.*(--repo|-R)[[:space:]=]+([A-Za-z0-9._-]+\/[A-Za-z0-9._-]+).*/\2/p')"
  if [ -n "$repo_flag" ]; then
    origin="$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)"
    case "$origin" in
      *"$repo_flag"*) : ;;
      *) exit 0 ;;
    esac
  fi

  # The Issue number: the first operand that is a bare number, a #-prefixed number, or an issue URL.
  num="$(printf '%s\n' "${cmd#gh issue close }" | tr ' ' '\n' \
    | sed -nE 's@^#?([0-9]+)$@\1@p; s@^https?://[^[:space:]]+/issues/([0-9]+)/?$@\1@p' | head -1)"
  [ -z "$num" ] && exit 0

  body="$(issue_body "$num")"
  [ -z "$body" ] && exit 0

  unmet="$(unmet_entries "$body")"
  [ -z "$unmet" ] && exit 0

  reason="Denied: issue #${num} declares an invocable artifact that does not resolve in this tree.

unmet:
$(printf '%s\n' "$unmet" | sed 's/^/  /')

This is closure-artifact-guard.sh (#337), a PreToolUse guard. The Issue's own body carries an
'invocable:' line naming what a reader must be able to invoke when this closes, and the named
artifact is not there. Three Issues closed this way before this hook existed; each was caught by a
human asking.

Three exits, and only the third is free:
  1. build it — the artifact resolves and this call goes straight through;
  2. record the narrowing — replace the line with
       invocable-waived: <entry> <why the promise was narrowed, in a sentence>
     which is an auditable edit to the Issue body, not a flag;
  3. leave the Issue open — a promise with no artifact and no recorded narrowing is open work.

What this did NOT check: whether the artifact WORKS (existence only), and whether the Issue declared
everything it promised (nothing forces the declaration)."

  jq -n --arg r "$reason" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $r
    }
  }'
  exit 0
fi

# ════════════════════════════════════════════════════════════════════════════════════════════════
# ARM 2 · Stop — report an Issue that ALREADY closed with its declaration unmet
# ════════════════════════════════════════════════════════════════════════════════════════════════
# This is the arm that covers the closing-keyword route, and it is detection only. The window is
# rolling and server-side (`closed:>=`, one API call per turn end) rather than a fixed cutoff: a
# fixed one grows without bound and re-reports a finding nobody is going to act on six months later.
if [ "$event" = "Stop" ]; then
  stop_hook_active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || true)"
  [ "$stop_hook_active" = "true" ] && exit 0

  session_id="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)"

  since="$(date -u -v-14d +%Y-%m-%d 2>/dev/null || date -u -d '14 days ago' +%Y-%m-%d 2>/dev/null || true)"
  [ -z "$since" ] && exit 0

  listing="$(gh issue list --state closed --search "closed:>=$since" --limit 30 \
    --json number,title,body,url 2>/dev/null || true)"
  [ -z "$listing" ] && exit 0

  count="$(printf '%s' "$listing" | jq 'length' 2>/dev/null || true)"
  case "$count" in ''|*[!0-9]*) exit 0 ;; esac
  [ "$count" -eq 0 ] && exit 0

  git_dir="$(git -C "$ROOT" rev-parse --git-dir 2>/dev/null || true)"
  [ -z "$git_dir" ] && exit 0
  case "$git_dir" in /*) : ;; *) git_dir="$ROOT/$git_dir" ;; esac
  debounce_dir="$git_dir/closure-artifact-guard"
  mkdir -p "$debounce_dir" 2>/dev/null || true

  findings=""
  i=0
  while [ "$i" -lt "$count" ]; do
    n="$(printf '%s' "$listing" | jq -r --argjson i "$i" '.[$i].number' 2>/dev/null || true)"
    t="$(printf '%s' "$listing" | jq -r --argjson i "$i" '.[$i].title // ""' 2>/dev/null || true)"
    b="$(printf '%s' "$listing" | jq -r --argjson i "$i" '.[$i].body // ""' 2>/dev/null || true)"
    i=$((i + 1))
    [ -z "$n" ] && continue
    u="$(unmet_entries "$b")"
    [ -z "$u" ] && continue
    # Debounce per session per issue: the finding is reported once, not on every turn end until it
    # is fixed. The nag that never stops is the one that gets routed around.
    marker="$debounce_dir/${session_id:-nosession}-${n}"
    [ -f "$marker" ] && continue
    : > "$marker" 2>/dev/null || true
    findings="$findings
  #${n} — ${t}
      unmet: $(printf '%s' "$u" | tr '\n' ' ')"
  done

  [ -z "$findings" ] && exit 0

  context="An Issue is CLOSED while an artifact its own body declares does not resolve in this tree:
${findings}

This is closure-artifact-guard.sh (#337), a Stop hook, reporting one turn after the close rather
than one session after it. It is DETECTION — the close it is describing was executed by GitHub on
merge, from a closing keyword in a PR body, and no hook in this harness can refuse that.

Decide one of three, and say which: build the artifact and it stops; record the narrowing on the
Issue as 'invocable-waived: <entry> <reason>'; or reopen the Issue, because a promise with no
artifact and no recorded narrowing is open work. Each finding is reported once per session, so
silence on the next turn is the debounce, not a repair."

  jq -n --arg c "$context" '{
    hookSpecificOutput: {
      hookEventName: "Stop",
      additionalContext: $c
    }
  }'
  exit 0
fi

exit 0
