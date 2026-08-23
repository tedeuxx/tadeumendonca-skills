#!/usr/bin/env bash
# zombie-loop-detect.sh — Stop hook: surface an outstanding gate verdict at the END OF THE
# TURN in which it went unaddressed, instead of waiting for the next SessionStart.
#
# ── WHAT THIS EXISTS FOR (#294) ─────────────────────────────────────────────────────────────────
# `session-wip.sh` already computes exactly the fact this hook needs — whether the current
# branch's open PR carries a `gatekeeper-verdict` comment reading REQUEST-CHANGES or
# APPROVE-PENDING-HUMAN on its CURRENT head — but it is wired to SessionStart, which means the
# loop can go zombie for an entire session before anything notices. #294's own incident: the
# orchestrator narrated a dispatch ("Vou despachar o harness-lead...") and ended the turn without
# making the tool call. No hook fired, because no hook was watching a TURN ending — only a
# SESSION starting. (Quoted verbatim — the persona was still `harness-lead` when #294 happened;
# renamed to `agents-lead` at #291, after this incident.)
#
# `Stop` fires at the end of every main-agent turn, which is the failure's own boundary: if a
# gate verdict is outstanding when the turn ends, THIS is the moment to say so, one turn late
# instead of one session late (confirmed 2026-08-20 against the primary Claude Code hooks
# documentation — `additionalContext` from a `Stop` hook reaches the model on the next turn; not
# discarded because the turn already ended).
#
# ── WHAT THIS DOES NOT DO, stated so nobody assumes otherwise ──────────────────────────────────
# It never parses prose. It does not try to tell "narrated but not done" from "done" — it reads
# LOOP STATE (the gatekeeper's own posted verdict against the PR's current head), which is a
# closed four-literal enumeration the gate's own persona defines (three until 2026-08-23,
# when ADR-0002 amendment #16 added APPROVE-AND-MERGE-BOUNDARY), not a caller-controlled
# grammar (ADR-0004's "Which layer carries a control" section — a control over a closed set the
# author wrote may be recorded as closed; one over a caller-controlled grammar may not). This is
# why it is buildable at all: a `Stop` hook cannot reliably distinguish narration from a tool
# call that was never attempted (nothing is written to the transcript for an attempt that never
# started), but it CAN reliably read committed state.
#
# It does not catch: narration with no loop-state footprint ("I'll update the README" and then
# not doing it); anything during intake, before a PR exists; a narrated dispatch of a lens that
# produces no PR artifact (`product-lead` is denied `gh pr comment` by `permission-guard.sh` rule
# 5e, so its absence is unobservable by construction); prevention of any kind — no layer in this
# architecture can prevent a tool call that is never made (confirmed 2026-08-20: `SubagentStart`
# is documented informational-only and cannot deny a dispatch; `SubagentStop` fires only AFTER a
# dispatch already ran).
#
# ── REUSE VS EXTRACTION — the design's own stated preference ───────────────────────────────────
# `session-wip.sh`'s `verdict_suffix()` is not imported: extracting it into a shared file risks
# destabilising a working SessionStart gate mid-slice, which the intake explicitly asked to avoid
# unless the extraction is trivially clean. It is not — `verdict_suffix()` closes over `$MARKER`
# and is embedded in a `SessionStart`-shaped script with its own listing/formatting concerns. So
# this hook is a SECOND, INDEPENDENT READER of the same artifact (the ADR-0006
# `gatekeeper-verdict` marker comment) — same jq extraction, same author filter, same "last match
# wins" rule, same literal set — kept in sync by `zombie-loop-detect.test.sh` asserting the exact
# behaviours `session-wip.test.sh` already asserts against the shared fixture shape. A drift
# between the two readers is a defect a future reviewer can catch by diffing the two test files,
# not a silent divergence.
#
# THIS READS ONLY THE `gatekeeper-verdict` MARKER, NOT `harness-lead-verdict`, DELIBERATELY. The
# intake brief's own prose names both, but only `gatekeeper-verdict` carries the closed
# closed literal enumeration (`agents/quality-assurance.md`, "Your verdict — exactly one of"); the
# `harness-lead-verdict` marker (ADR-0002's "agents-lead implements the harness it reviews"
# section, absorbed record 0015) carries a free-text headline conclusion, not one of the three
# literals, and per that same section's Corollary 2 it is `quality-assurance` that posts the
# actual `gatekeeper-verdict` gating a `loop`-typed PR — the agents-lead marker is an input to
# that verdict, not a second gate this hook needs to read independently.
#
# ── DEBOUNCE, AND WHERE THE MARKER FILE LIVES ───────────────────────────────────────────────────
# Fire at most once per (pr_number, headRefOid) per session — a parked PR the owner is reading
# must not nag on every subsequent turn end, which is the shape that gets routed around within a
# week. The marker file is written under this checkout's OWN `.git` directory
# (`git rev-parse --git-dir`), not the harness's session scratchpad: a hook script is invoked by
# bare path with no access to the path a Claude Code SESSION is handed at start (that path is a
# capability of the `Write`/`Edit` tools inside a session's own context, not an environment
# variable a hook subprocess inherits). `.git/` is: (a) NEVER git-tracked, so a marker file there
# can never leak into a commit or a diff; (b) already scoped to this exact checkout, which is
# what the debounce key needs to be scoped to anyway (a PR's state is a property of the branch
# checked out here); (c) resolved correctly under a `git worktree` checkout too, since
# `rev-parse --git-dir` returns the worktree's own `.git/worktrees/<name>` directory rather than
# the main checkout's `.git/`, so two worktrees never share a debounce namespace. Keyed further by
# `session_id` because the debounce is explicitly PER SESSION (a second session picking up the
# same stalled PR should still be told once).
#
# ── COST BOUNDING — local-only precondition before any network call ────────────────────────────
# `git branch --show-current` is checked FIRST, with no `gh` call at all when there is no current
# branch (detached HEAD, not a repo, or an unreadable `cwd`) — the network cost is paid only when
# there is something to check. When a branch exists, the FIRST `gh` call (`pr list`) is
# unavoidable: it is the cheapest way to learn whether this branch even has an open PR, and it is
# also what supplies the (pr_number, headRefOid) debounce key — nothing local can supply that key,
# since the head SHA GitHub associates with an open PR is server-side truth, not a fact `git`
# alone knows (a local HEAD can differ from `headRefOid` after a rebase or before a push). Once
# that key is known, the debounce check happens BEFORE the second, heavier call (`pr view` with
# `comments`, which reads every comment on the PR) — so a repeated turn on an already-notified
# state costs one cheap call, not two, and a turn with no open PR at all costs exactly one call
# and never reaches the comment-parsing logic below.
#
# ── stop_hook_active ─────────────────────────────────────────────────────────────────────────────
# Documented (2026-08-20 primary-source confirmation) as the field a Stop hook must check to avoid
# looping — Claude Code overrides a Stop hook after it blocks 8 times in a row without progress.
# This hook never blocks (every exit path is `exit 0`, `additionalContext` only — see below), so
# it does not directly trip that breaker. It is honoured anyway, exactly as the intake instructed:
# when `stop_hook_active` is `true`, this hook exits before doing ANY work, local or networked,
# rather than risk compounding whatever caused another Stop hook in this chain to re-fire.
#
# ── EXIT-CODE DISCIPLINE ────────────────────────────────────────────────────────────────────────
# This is detection, not enforcement — the intake's own stated boundary. Every exit path is
# `exit 0`. `additionalContext` is the only mechanism used; this script never emits a `decision`
# field and never exits 2. It does not and must not force the loop to continue narrating instead
# of stopping — it only ensures that if the loop DOES continue, the next turn opens with the fact
# that something was left outstanding.
#
# Contract: receives the Stop event JSON on stdin (`session_id`, `cwd`, `stop_hook_active`, among
# others); prints Stop-hookSpecificOutput JSON carrying `additionalContext` when (and only when) a
# notice is due, and exits 0 either way. Silent on any error — no `gh`, no `jq`, no git repo, no
# network, an unreadable payload — because a detector that wedges the loop it is trying to protect
# is a worse failure than the one it exists to catch.

set -uo pipefail

input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

command -v jq >/dev/null 2>&1 || exit 0

stop_hook_active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || true)"
[ "$stop_hook_active" = "true" ] && exit 0

session_id="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
[ -z "$cwd" ] && exit 0
[ -d "$cwd" ] || exit 0

command -v git >/dev/null 2>&1 || exit 0

# ── local-only precondition: no network below this line unless a branch exists ─────────────────
branch="$(git -C "$cwd" branch --show-current 2>/dev/null || true)"
[ -z "$branch" ] && exit 0

git_dir="$(git -C "$cwd" rev-parse --git-dir 2>/dev/null || true)"
[ -z "$git_dir" ] && exit 0
case "$git_dir" in
  /*) : ;;
  *)  git_dir="$cwd/$git_dir" ;;
esac
debounce_dir="$git_dir/zombie-loop-detect"
mkdir -p "$debounce_dir" 2>/dev/null || true

command -v gh >/dev/null 2>&1 || exit 0

# ── first network call: is there even an open PR for this branch? ──────────────────────────────
pr_json="$(gh pr list --head "$branch" --state open --json number,headRefOid --limit 1 2>/dev/null || true)"
[ -z "$pr_json" ] && exit 0
pr_number="$(printf '%s' "$pr_json" | jq -r '.[0].number // empty' 2>/dev/null || true)"
head_sha="$(printf '%s' "$pr_json" | jq -r '.[0].headRefOid // empty' 2>/dev/null || true)"
[ -z "$pr_number" ] && exit 0
[ -z "$head_sha" ] && exit 0

# ── debounce, checked BEFORE the heavier second call ────────────────────────────────────────────
marker_file="$debounce_dir/${session_id:-nosession}-${pr_number}-${head_sha}"
[ -f "$marker_file" ] && exit 0

# ── second network call: read the gatekeeper-verdict marker at the current head ────────────────
# Same extraction as session-wip.sh's verdict_suffix(): last match wins (a re-review posts a
# second verdict at the same head), author-filtered (OWNER/MEMBER/COLLABORATOR only — these repos
# are public, and the head SHA is public with them, so an unfiltered read lets any GitHub account
# suppress or forge the mark), and the literal is read from the LINE AFTER the marker, not the
# marker line itself.
MARKER='<!-- gatekeeper-verdict: quality-assurance -->'

pr_view="$(gh pr view "$pr_number" --json headRefOid,comments 2>/dev/null || true)"
[ -z "$pr_view" ] && exit 0

verdict="$(printf '%s' "$pr_view" | jq -r --arg m "$MARKER" '
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

[ -z "$verdict" ] && exit 0

# DELIBERATELY UNCHANGED by ADR-0002 amendment #16, and the reasoning is worth stating because the
# amendment added a verdict literal. `APPROVE-AND-MERGE-BOUNDARY` falls to `*) exit 0` — it is a
# CLEARANCE, not an outstanding verdict, so it is silent here exactly as `APPROVE-AND-MERGE` already
# was. NAMED RESIDUAL, not closed here: neither clearance fires this notice when the PR is still open
# at turn end, so "the gate cleared it and then did not merge it" is invisible to this hook. That gap
# predates the amendment and is identical for both literals; closing it is a separate change.
case "$verdict" in
  REQUEST-CHANGES|APPROVE-PENDING-HUMAN) : ;;
  *) exit 0 ;;
esac

# ── emit the notice, and arm the debounce ───────────────────────────────────────────────────────
context="Turn ended with an outstanding quality-assurance verdict on PR #${pr_number} (branch
${branch}, head ${head_sha}): ${verdict}.

This is zombie-loop-detect.sh (#294), a Stop hook — it caught this because loop state (a
gatekeeper-verdict comment against the PR's CURRENT head) says a review outcome has not been
acted on, whatever the reason (omission, narration, error, or a subagent that posted nothing).
It does not know WHY; it only knows the state is outstanding.

If REQUEST-CHANGES: dispatch the persona that owns the fix and re-request review.
If APPROVE-PENDING-HUMAN: this needs the owner's go/no-go, not another dispatch.

This notice fires at most once per (PR, head SHA) per session — it will not repeat for this
exact state, and re-arms only if the head moves or a new verdict lands."

printf '%s' "$context" > "$marker_file" 2>/dev/null || true

jq -n --arg c "$context" '{
  hookSpecificOutput: {
    hookEventName: "Stop",
    additionalContext: $c
  }
}'
exit 0
