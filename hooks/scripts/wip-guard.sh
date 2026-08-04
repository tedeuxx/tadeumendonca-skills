#!/usr/bin/env bash
# wip-guard.sh — PreToolUse(Bash) guard bounding work-in-progress at the PR boundary.
#
# The bound has TWO LEVELS: file overlap between slices, and a COUNT between stories.
#
# ~~The bound is FILE OVERLAP, not a count.~~ True of slices, and false of stories since
# `gitflow-single-env` (#122/#123). Struck rather than deleted because the paragraph below it
# is the measured argument for the first half and still stands — see STORY AWARENESS further
# down for why the second half is a count. Not a change of mind about counting: a story
# branch diverges for as long as the story lasts, and overlap measured at an instant cannot
# see time.
#
# It used to count: one open PR per repo, full stop. That was a proxy for the thing
# actually worth preventing — stacked PRs that go stale and turn their merge into a
# conflict resolution — and it was a bad one. It blocked disjoint slices, which is the
# common case, while doing nothing about the real risk. Measured over one long session:
# of roughly a dozen slices, only three would have collided; every other one waited
# anyway, and the queue the owner had asked to be drained stood still.
#
# So the question is not "how many are open" but "does this one touch what an open one
# touches". Two PRs editing different files merge cleanly in either order and there is
# nothing to protect against.
#
# Scope: per REPO, per author. Not global — a genuine cross-repo pair (a plugin change
# plus the consuming repo adopting it) is one slice wearing two PRs. Author-scoped
# because a bot's dependency PR should be drained, but must not stop a human slice.
#
# Contract: receives the PreToolUse JSON on stdin; denies by printing a
# permissionDecision JSON and exiting 0. Fails OPEN on any error — no network, no gh,
# no git, no auth, unparseable payload, an unreadable file list — because a
# loop-discipline check must never be the thing that wedges the loop. Every early exit
# below is that rule applied: an answer we could not get is not a verdict.
#
# ⚠ Do not carry this file's fail-open rule across to `permission-guard.sh`, the other
# PreToolUse hook here. This hook enforces loop DISCIPLINE, where a spurious deny costs more
# than a missed one; that hook is the irreversible FLOOR, where a missed deny is the whole
# failure. **Do not "fix" one to match the other.**
#
# ~~That hook fails CLOSED.~~ **Struck 2026-08-02 — it does not, and asserting it here was
# worse than saying nothing.** `permission-guard.sh` fails OPEN on an unreadable payload, by
# design (its header says so, and `settings.json`'s deny list is the stated backstop). Measured:
# with `jq` off PATH it emits no decision at all, so a main-agent `git push origin main` is
# allowed. The backstop covers terraform / force-push / `rm -rf` / secrets, but NOT rules 7, 7b
# and 8 — which exist precisely because a prefix matcher cannot express them.
#
# So the accurate warning is the one above: the DIRECTIONS DIFFER BY INTENT, and this file's
# reasoning is not transferable. What that floor should do when it cannot read its input is an
# open question, NAMED rather than answered here — and named, not filed: the reviewer does not open
# work, so there is no issue to point at. ("filed" stood here for one round and was false, in the
# file whose entire diff is about a comment asserting something untrue.) A comment claiming that
# question was already answered is exactly the failure it was written to prevent — which is how the
# struck line above got here, found by `security` reviewing #124.

set -uo pipefail

input="$(cat 2>/dev/null || true)"
command="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[ -z "$command" ] && exit 0

cmd="$(printf '%s' "$command" | tr '\n\t' '  ')"
# Quoted spans collapsed first, so a commit message that merely MENTIONS `gh pr create`
# is not mistaken for the act of creating a PR.
cmd="$(printf '%s' "$cmd" | sed -e "s/'[^']*'/''/g" -e 's/"[^"]*"/""/g')"

# Only `gh pr create` is interesting. Everything else leaves immediately, so this adds
# no measurable cost to the Bash calls that make up the actual dev loop.
printf '%s' "$cmd" | grep -Eq '(^|[^[:alnum:]_])gh([[:space:]]+(-R|--repo)[[:space:]]+[^[:space:]]+)*[[:space:]]+pr[[:space:]]+create([[:space:]]|$)' || exit 0

command -v gh >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

# Honour an explicit -R/--repo; otherwise let gh infer from the working directory.
repo="$(printf '%s' "$cmd" | sed -nE 's/.*[[:space:]](-R|--repo)[[:space:]]+([^[:space:]]+).*/\2/p')"
if [ -n "$repo" ]; then
  open_prs="$(gh pr list -R "$repo" --state open --author @me --json number,title,headRefName,baseRefName 2>/dev/null || true)"
else
  open_prs="$(gh pr list --state open --author @me --json number,title,headRefName,baseRefName 2>/dev/null || true)"
fi

# No answer means no verdict. Stay out of the way.
[ -z "$open_prs" ] && exit 0

# `length` on an OBJECT counts its keys, so an unexpected shape would read as a queue.
# Only an array is an answer; anything else means we did not get one.
count="$(printf '%s' "$open_prs" | jq 'if type == "array" then length else 0 end' 2>/dev/null || true)"
case "$count" in
  ''|0) exit 0 ;;
esac

# ── STORY AWARENESS (gitflow-single-env) ────────────────────────────────────────────
#
# Under `gitflow-single-env` a story owns a short-lived branch and its tasks open PRs
# INTO that branch; the story branch itself then opens one PR into the trunk, and THAT
# merge is the deploy. So this guard has to move in two opposite directions at once, and
# that is the reason it is the riskiest change in the batch — a pair like this passes a
# suite while gating nothing.
#
#   LOOSER inside a story: two task PRs touching the same file, in the same story, are
#   normal work rather than a collision. They land in sequence on a branch that has not
#   published yet. Blocking them would deny the exact flow the model creates.
#
#   TIGHTER between stories: only one story may be live. Not because two stories would
#   necessarily collide — file overlap already answered that question, and answered it
#   correctly in #88/#90 — but because a story branch DIVERGES FOR AS LONG AS THE STORY
#   LASTS. Overlap measured at an instant cannot see time, and every cost of the model
#   (the lead dispatches, a diverging branch, a ratification, an acceptance) is per story.
#   Written without a figure on purpose: it said six of them, a number derived from a roster
#   that has since been cut twice, with nothing anywhere able to notice.
#
# Which story a PR belongs to is read off the branch pair: a task PR has `story/*` as its
# BASE, and the story's own publish PR has `story/*` as its HEAD. Anything with neither is
# an ordinary trunk slice and keeps the pre-existing behaviour untouched.
story_of() { # $1 head, $2 base
  case "$2" in story/*) printf '%s' "$2"; return ;; esac
  case "$1" in story/*) printf '%s' "$1"; return ;; esac
  printf ''
}

# The base this PR would target: an explicit -B/--base, else the repo default.
default_base="$(gh repo view ${repo:+-R "$repo"} --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || true)"
[ -z "$default_base" ] && default_base="main"
# ATTACHED VALUES, both spellings. `gh` accepts `--base=x` and `-Bx` exactly as it accepts
# the spaced forms, and a space-only regex misses them — the same class `permission-guard`
# 5b/5c were hardened for, so this is the in-repo idiom rather than a new idea.
#
# Missing them broke this rule in BOTH directions at once, which is why it is worth a
# comment rather than a quiet fix:
#   · the story COUNT failed OPEN and silently — `--base=story/other` read as no base at
#     all, fell back to the default branch, and a second story opened unchallenged;
#   · the same-story EXEMPTION failed CLOSED — a legitimate second task PR written with
#     `--base=` was DENIED, wedging the primary flow this hook exists to permit, and doing
#     it intermittently, since it depends on how the command happened to be spelled.
#
# `-B[[:space:]]*` cannot mis-fire on `--base`: the character before `B` would have to be a
# space, and in `--base` it is `-` with a lowercase `b`.
new_base="$(printf '%s' "$cmd" | sed -nE 's/.*[[:space:]](-B[[:space:]]*|--base[[:space:]=]*)([^[:space:]]+).*/\2/p')"
[ -z "$new_base" ] && new_base="$default_base"
new_head="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
new_story="$(story_of "$new_head" "$new_base")"

# Every story already live in the open set.
# `// ""` on both fields, deliberately: a `gh` that omits them (an older version, a shape
# change) would otherwise make `startswith` error, jq print nothing, and this whole rule
# vanish silently while every test still passed. Defaulting to empty makes a missing field
# mean "not a story" — which is the safe reading, and a visible one.
live_stories="$(printf '%s' "$open_prs" | jq -r '.[] | (if ((.baseRefName // "") | startswith("story/")) then .baseRefName elif ((.headRefName // "") | startswith("story/")) then .headRefName else empty end)' 2>/dev/null | sort -u || true)"

# WIP = 1 STORY, by count. Fires only when this PR belongs to a story AND a DIFFERENT one
# is already live — an ordinary trunk slice alongside a story is not what this bounds.
if [ -n "$new_story" ] && [ -n "$live_stories" ]; then
  # `-vxF`, not `-v "^…$"`: the branch name was being interpolated into a REGEX, and `.` is
  # legal in a git ref. So a base like `story/1..thing` failed to match a live `story/12-thing`,
  # that story vanished from the set, and a second story opened unchallenged. A bypass a
  # crafted name can drive, and a mis-match that real names hit by accident.
  others="$(printf '%s\n' "$live_stories" | grep -vxF "$new_story" || true)"
  if [ -n "$others" ]; then
    jq -n --arg r "Blocked: WIP is ONE story at a time, and $(printf '%s' "$others" | tr '\n' ' ')is already live. This is a count rather than file overlap on purpose — a story branch diverges for as long as the story lasts, and every cost of the model is per story. Finish that one through its ratification and merge, then open this. (Inside a single story, task PRs are NOT bounded by overlap — that is a different rule and it is looser, not stricter.)" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $r
      }
    }'
    exit 0
  fi
fi

# What THIS branch would bring. Compared against the merge-base with the default branch,
# not against its tip, so commits that merely landed on the base while this branch was
# alive are not counted as ours.
#
# Reuses `default_base` resolved above rather than asking again — the story block already
# made this exact query, and a second identical round-trip on every `gh pr create` is cost
# for nothing. Both reviewers flagged it.
merge_base="$(git merge-base "origin/$default_base" HEAD 2>/dev/null || true)"
[ -z "$merge_base" ] && exit 0
mine="$(git diff --name-only "$merge_base" HEAD 2>/dev/null || true)"
# A branch with no diff yet is not a conflict risk, and it is also not a PR worth
# blocking. Either way there is nothing to intersect.
[ -z "$mine" ] && exit 0

# Intersect against each open PR in turn, so the denial can name WHICH PR and WHICH
# files — a denial that does not say what to look at is a denial the author works
# around rather than acts on.
collisions=""
for pr in $(printf '%s' "$open_prs" | jq -r '.[].number' 2>/dev/null || true); do
  # SAME-STORY PRs ARE EXEMPT — this is the "looser" half, and skipping it here rather
  # than filtering the list earlier is deliberate: the exemption is a property of the
  # PAIR, not of either PR alone.
  #
  # Two task PRs into one story branch land in sequence on a branch that has not published
  # yet, so an overlap between them is ordinary sequential work, not a slice going stale
  # behind another. The conflict this guard exists to prevent is between things racing to
  # the SAME destination, and two tasks in one story are not racing.
  their_head="$(printf '%s' "$open_prs" | jq -r --arg n "$pr" '.[] | select(.number == ($n|tonumber)) | .headRefName' 2>/dev/null || true)"
  their_base="$(printf '%s' "$open_prs" | jq -r --arg n "$pr" '.[] | select(.number == ($n|tonumber)) | .baseRefName' 2>/dev/null || true)"
  their_story="$(story_of "$their_head" "$their_base")"
  if [ -n "$new_story" ] && [ "$their_story" = "$new_story" ]; then
    continue
  fi

  theirs="$(gh pr view "$pr" ${repo:+-R "$repo"} --json files -q '.files[].path' 2>/dev/null || true)"
  # Could not read that PR's files — fail open for this PR rather than guessing at an
  # overlap we cannot see.
  [ -z "$theirs" ] && continue
  shared="$(printf '%s\n' "$mine" | grep -Fxf <(printf '%s\n' "$theirs") 2>/dev/null | tr '\n' ' ' || true)"
  [ -n "$shared" ] && collisions="${collisions}#${pr}: ${shared}; "
done

# Disjoint from everything open. This is the case the old counter got wrong, and it is
# the common one.
[ -z "$collisions" ] && exit 0

jq -n --arg r "Blocked: this slice touches files an open PR of yours already touches, so one of them will go stale and its merge becomes a conflict resolution. Finish that one first — merge it, or close it with a reason. Overlaps: ${collisions}(Disjoint slices are allowed: the bound is file overlap, not a count.)" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $r
  }
}'
exit 0
