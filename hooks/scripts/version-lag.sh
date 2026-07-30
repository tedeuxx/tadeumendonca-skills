#!/usr/bin/env bash
# version-lag.sh — SessionStart hook: say which version of this plugin the session is actually running.
#
# THE FAILURE THIS EXISTS FOR, observed rather than imagined. `wip-guard` was rewritten from counting
# open PRs to intersecting changed files and released as 0.4.18. Minutes later, in a session on this
# machine, the guard denied a PR for a slice that shared no file with the open one — the exact case the
# rewrite exists to allow. The installed copy was 0.4.15, three versions behind, and every gate in the
# skills repo had passed: they verify the plugin's SOURCE. Nothing verified that the plugin a session is
# RUNNING is the one that was verified.
#
# So the fix a person can act on is not "remember to update". It is being told. An agent that reads
# "you are running 0.4.15, latest is 0.4.19" can attribute a guard's behaviour to the build; one that is
# not told will attribute it to the rule, and argue with a rule that was already fixed.
#
# Contract: prints SessionStart JSON carrying additionalContext, exits 0. SILENT when the versions match
# — a session that is current should hear nothing, or the signal becomes noise and stops being read.
# Silent on every error too (no gh, no network, no manifest, unreadable JSON): an unavailable answer is
# not worth interrupting for, and this is the least urgent thing a session start can say.

set -uo pipefail

# What is actually loaded. CLAUDE_PLUGIN_ROOT points at the installed copy, so its manifest is the
# running version — NOT the checkout's, which is what makes this different from reading VERSION here.
root="${CLAUDE_PLUGIN_ROOT:-}"
[ -z "$root" ] && exit 0
manifest="$root/.claude-plugin/plugin.json"
[ -f "$manifest" ] || exit 0

installed="$(jq -r '.version // empty' "$manifest" 2>/dev/null || true)"
[ -z "$installed" ] && exit 0

command -v gh >/dev/null 2>&1 || exit 0

# The published version, from the release the version-main workflow cuts on every merge to main.
latest="$(gh release view -R tedeuxx/tadeumendonca-skills --json tagName -q '.tagName' 2>/dev/null || true)"
latest="${latest#v}"
[ -z "$latest" ] && exit 0

# Equal is the common case and says nothing. Also covers a local checkout AHEAD of the release (mid-slice
# in this repo), which is not lag and must not be reported as it.
[ "$installed" = "$latest" ] && exit 0

# Only report BEHIND. `sort -V` puts the lower version first; if that is the published one, the session
# is ahead — which happens while developing the plugin itself and is not a defect.
lower="$(printf '%s\n%s\n' "$installed" "$latest" | sort -V | head -n1)"
[ "$lower" = "$latest" ] && exit 0

context="Plugin version: this session is running **${installed}**; the published version is **${latest}**.

Hooks, agent personas and command files come from the INSTALLED copy, so anything merged into the plugin
after ${installed} is not in effect here — including fixes to the guards themselves. If a hook behaves
in a way the documented rule does not explain, check the version before arguing with the rule: that has
already happened once, where a guard denied a slice the current rule allows.

Updating is \`/plugin\` in this session. This message does not appear when the versions match."

jq -n --arg c "$context" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $c
  }
}'
exit 0
