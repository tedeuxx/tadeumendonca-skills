#!/usr/bin/env bash
# stop-guard.sh — Stop hook: refuse to end a turn that left work standing still.
#
# WHY THIS EVENT, AND NOT ANOTHER. Every other guard in this plugin fires on PreToolUse — before an
# ACT. The failure this one exists for is not an act, it is the absence of one: a turn that ends with
# the next step named instead of started ("sending it to the reviewer now", "next I'll open the PR"),
# after which nothing happens until a human notices. From the outside, announcing and doing are
# indistinguishable; from the inside they feel the same. No tool call happens, so no PreToolUse hook is
# consulted, and the one moment the failure is observable — the end of the turn — had nothing watching
# it. `Stop` is that moment.
#
# The rule it enforces was written into a command file first, and that did not work: a document asks
# the agent to remember, and remembering is the thing that failed. This asks nothing. It reads the
# world — open PRs, current branch, working tree — and declines.
#
# WHAT IT CANNOT DO, stated so it is not trusted further than it goes:
#   - It cannot tell whether the agent ANNOUNCED an action. It has no access to the reply text, and
#     even with it, "I'll open the PR next" is not mechanically distinguishable from narration.
#   - So it catches the common shape (work is parked and nothing disjoint was begun) and misses
#     "promised X, did Y". That is a real gap, not an oversight.
#
# Contract: receives the Stop JSON on stdin. Prints a block decision and exits 0 to refuse the stop;
# exits 0 silently to allow it. Fails OPEN on every error — no gh, no auth, no network, not a repo,
# unparseable payload. A guard that wedges a session is worse than the stall it prevents.

set -uo pipefail

input="$(cat 2>/dev/null || true)"

# LOOP GUARD, and it is the one thing here that must not be wrong. When a Stop hook blocks, the agent
# continues and will Stop again; `stop_hook_active` is true on that second pass. Without this the
# session cannot end at all — the guard becomes the wedge it is written to avoid.
#
# So an UNREADABLE payload has to allow, not merely fall through. `stop_hook_active` is the only way to
# know this is a re-entry; if the payload cannot be parsed, that fact is unavailable, and blocking on an
# unknown re-entry is exactly the infinite loop. Found by this file's own test, which asserted ALLOW on
# empty stdin while the guard blocked: the first version read a missing flag as "false" and proceeded.
printf '%s' "$input" | jq -e . >/dev/null 2>&1 || exit 0
active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || echo true)"
[ "$active" = "true" ] && exit 0

command -v gh >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

# Only this repo, only this author. A teammate's PR is not this session's parked work.
open_prs="$(gh pr list --state open --author @me --json number,title,headRefName 2>/dev/null || true)"
[ -z "$open_prs" ] && exit 0

# `length` on an OBJECT counts keys, so an unexpected shape would read as a queue. Only an array is an
# answer.
count="$(printf '%s' "$open_prs" | jq 'if type == "array" then length else 0 end' 2>/dev/null || true)"
case "$count" in
  ''|0) exit 0 ;;
esac

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
[ -z "$branch" ] && exit 0

# THE DISCRIMINATOR. Parked means: still sitting on the branch of an open PR, with nothing uncommitted.
# Move to another branch and you have started something else; leave the tree dirty and you are mid-work.
# Either way this is not the stall, and the guard says nothing.
on_open_pr="$(printf '%s' "$open_prs" | jq -r --arg b "$branch" 'map(select(.headRefName == $b)) | length' 2>/dev/null || echo 0)"
[ "$on_open_pr" = "0" ] && exit 0

dirty="$(git status --porcelain 2>/dev/null || true)"
[ -n "$dirty" ] && exit 0

listing="$(printf '%s' "$open_prs" | jq -r '.[] | "#\(.number) \(.title)"' 2>/dev/null | tr '\n' ' ' || true)"

jq -n --arg r "You are still on \`${branch}\`, which has an open PR of yours, with a clean tree — so this turn is ending with the work parked rather than moving. Open: ${listing}
Do one of these before stopping: begin a slice that touches none of those files, act on the review if it has returned, or say plainly that there is nothing disjoint left to start. Naming the next action is not doing it — from the outside those are the same, which is why this is a hook and not a reminder." '{
  decision: "block",
  reason: $r
}'
exit 0
