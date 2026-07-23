#!/usr/bin/env bash
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

# Age matters more than count: a PR open for days is the signal, one opened minutes
# ago is just work in progress.
listing="$(printf '%s' "$open_prs" | jq -r '
  .[] | "- #\(.number) \(.title) — \(.author.login)\(if .isDraft then " [draft]" else "" end), opened \(.createdAt[0:10])"
' 2>/dev/null || true)"
[ -z "$listing" ] && exit 0

context="Open pull requests in this repo ($count):

$listing

The loop runs at WIP = 1: drain these before starting a new slice. For each, the
resolution is merge it, or close it with a reason — leaving it open is neither.
A bot's dependency PR still counts as something to drain, though it does not block
opening a slice of your own."

jq -n --arg c "$context" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $c
  }
}'
exit 0
