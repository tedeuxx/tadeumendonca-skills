#!/usr/bin/env bash
# wip-guard.sh — PreToolUse(Bash) guard enforcing WIP = 1 at the PR boundary.
#
# The dev loop's rule is that a slice is finished — reviewed and MERGED — before the
# next one starts. Stated as guidance it decays: the agent opens a PR, moves on, and
# the queue grows until someone notices. That is what happened, and it is mechanically
# preventable, so it is prevented here instead of advised.
#
# Scope: one open PR per REPO, counted per author. Deliberately not global, because a
# genuine cross-repo pair (a plugin change plus the consuming repo's adoption of it)
# is one slice wearing two PRs, and a global counter would block correct work. Also
# deliberately author-scoped: a bot's dependency PR should be drained, but it must not
# stop a human slice from opening.
#
# Contract: receives the PreToolUse JSON on stdin; denies by printing a
# permissionDecision JSON and exiting 0. Fails OPEN on any error — no network, no gh,
# no auth, unparseable payload — because a loop-discipline check must never be the
# thing that wedges the loop.

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

# Honour an explicit -R/--repo; otherwise let gh infer from the working directory.
repo="$(printf '%s' "$cmd" | sed -nE 's/.*[[:space:]](-R|--repo)[[:space:]]+([^[:space:]]+).*/\2/p')"
if [ -n "$repo" ]; then
  open_prs="$(gh pr list -R "$repo" --state open --author @me --json number,title 2>/dev/null || true)"
else
  open_prs="$(gh pr list --state open --author @me --json number,title 2>/dev/null || true)"
fi

# No answer means no verdict. Stay out of the way.
[ -z "$open_prs" ] && exit 0

# `length` on an OBJECT counts its keys, so an unexpected shape would read as a queue
# and deny. Only an array is an answer; anything else means we did not get one.
count="$(printf '%s' "$open_prs" | jq 'if type == "array" then length else 0 end' 2>/dev/null || true)"
case "$count" in
  ''|0) exit 0 ;;
esac

listing="$(printf '%s' "$open_prs" | jq -r '.[] | "#\(.number) \(.title)"' 2>/dev/null | tr '\n' ';' || true)"

jq -n --arg r "Blocked: WIP = 1. This repo already has an open PR of yours, and opening another builds the queue the loop exists to avoid. Finish it first — merge it, or close it with a reason. Open now: ${listing}" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $r
  }
}'
exit 0
