#!/usr/bin/env bash
# wip-guard.sh — PreToolUse(Bash) guard bounding work-in-progress at the PR boundary.
#
# The bound is FILE OVERLAP, not a count.
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
  open_prs="$(gh pr list -R "$repo" --state open --author @me --json number,title 2>/dev/null || true)"
else
  open_prs="$(gh pr list --state open --author @me --json number,title 2>/dev/null || true)"
fi

# No answer means no verdict. Stay out of the way.
[ -z "$open_prs" ] && exit 0

# `length` on an OBJECT counts its keys, so an unexpected shape would read as a queue.
# Only an array is an answer; anything else means we did not get one.
count="$(printf '%s' "$open_prs" | jq 'if type == "array" then length else 0 end' 2>/dev/null || true)"
case "$count" in
  ''|0) exit 0 ;;
esac

# What THIS branch would bring. Compared against the merge-base with the default branch,
# not against its tip, so commits that merely landed on the base while this branch was
# alive are not counted as ours.
base="$(gh repo view ${repo:+-R "$repo"} --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || true)"
[ -z "$base" ] && base="main"
merge_base="$(git merge-base "origin/$base" HEAD 2>/dev/null || true)"
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
