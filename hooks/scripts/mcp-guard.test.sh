#!/usr/bin/env bash
# mcp-guard.test.sh — does the guard deny exactly the MCP calls no persona was granted, and nothing
# else?
#
# MUTATION-CHECKED per this repo's convention: every assertion below was verified to FAIL against a
# deliberately broken guard before being trusted. Four mutations were used, because four different
# defects are possible and only the first is obvious:
#
#   * delete the `*:product-lead` case          -> the GRANT assertions go red (the direction that
#                                                  silently removes the capability)
#   * change the catch-all `deny` to `exit 0`   -> every DENY assertion goes red (the direction that
#                                                  silently removes the CONTROL, which is worse)
#   * delete the empty-`agent_type` early exit  -> the orchestrator assertion goes red (the direction
#                                                  that breaks the owner's own session)
#   * narrow the server pattern to the
#     plugin-qualified spelling only            -> the bare-spelling assertion goes red (the consuming
#                                                  repo's own declaration, measured resolving)
#
# THE MATCHER IS ASSERTED HERE TOO, against `hooks/hooks.json`, and it is not scope creep — it is the
# lesson `orchestrator-write-guard.test.sh` already paid for. This script cannot see a call the matcher
# never routed to it, so a matcher typo leaves every assertion below green while every MCP call walks
# through. The registration is part of the control, so it is part of the gate.
#
# WHAT THIS SUITE CANNOT DO, stated so a green is not over-read: it feeds the guard a payload directly.
# It does NOT prove Claude Code routes `mcp__*` calls to a `PreToolUse` hook — that is a property of
# the harness, not of this file, and it was established by live probe (recorded in the guard's header
# and in ADR-0004's 2026-08-29 amendment). If that routing regresses, this suite stays green and the
# control is gone. There is
# no assertion available here that would catch it.
#
# Run: bash hooks/scripts/mcp-guard.test.sh

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$HERE/mcp-guard.sh"
HOOKS_JSON="$HERE/../hooks.json"
pass=0
fail=0

ok()  { printf 'ok    %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL  %s\n     %s\n' "$1" "$2"; fail=$((fail + 1)); }

# run <tool_name> <agent_type> -> prints the hook's stdout
run() {
  jq -n --arg t "$1" --arg a "$2" '{tool_name: $t, agent_type: $a, tool_input: {}}' | bash "$HOOK" 2>/dev/null
}

assert_deny() {
  local label="$1" out
  out="$(run "$2" "$3")"
  case "$out" in
    *'"permissionDecision": "deny"'*|*'"permissionDecision":"deny"'*) ok "$label" ;;
    *) bad "$label" "expected a deny decision, got: ${out:-<empty>}" ;;
  esac
}

assert_allow() {
  local label="$1" out
  out="$(run "$2" "$3")"
  if [ -z "$out" ]; then
    ok "$label"
  else
    bad "$label" "expected no decision (fall through to the permission system), got: $out"
  fi
}

# ── the grant ───────────────────────────────────────────────────────────────────────────────────
assert_allow "product-lead reaches the plugin-declared chrome server" \
  "mcp__plugin_tadeumendonca-skills_chrome-devtools__navigate_page" "tadeumendonca-skills:product-lead"

# The consuming repo's own declaration. Measured resolving from a plugin-shipped brief, and it is the
# override path the project-agnostic origin default in `.mcp.json` exists to leave open.
assert_allow "product-lead reaches a consuming repo's own chrome server declaration" \
  "mcp__chrome-devtools__take_screenshot" "tadeumendonca-skills:product-lead"

assert_allow "product-lead may read the console — the mechanical half of the sweep" \
  "mcp__chrome-devtools__list_console_messages" "tadeumendonca-skills:product-lead"
assert_allow "product-lead may read the network log" \
  "mcp__chrome-devtools__list_network_requests" "tadeumendonca-skills:product-lead"
assert_allow "product-lead may resize — the phone-width half of the sweep" \
  "mcp__chrome-devtools__resize_page" "tadeumendonca-skills:product-lead"
# Allowed deliberately and with the cost stated in the guard: a nav link and the PDF download are not
# reachable without it.
assert_allow "product-lead may click" \
  "mcp__chrome-devtools__click" "tadeumendonca-skills:product-lead"

# ── the grant is READ-ONLY: the input-carrying browser tools are denied ─────────────────────────
# This is the egress narrowing. Rule 5e denies this persona public surfaces because it reads the
# private positioning layer; a browser is a route to the outside that the read-only grant does not
# include, and these are the tools that carry data along it.
assert_deny "product-lead cannot run arbitrary script in the page" \
  "mcp__chrome-devtools__evaluate_script" "tadeumendonca-skills:product-lead"
assert_deny "product-lead cannot type into the page" \
  "mcp__chrome-devtools__type_text" "tadeumendonca-skills:product-lead"
assert_deny "product-lead cannot fill a field" \
  "mcp__chrome-devtools__fill" "tadeumendonca-skills:product-lead"
assert_deny "product-lead cannot fill a form" \
  "mcp__chrome-devtools__fill_form" "tadeumendonca-skills:product-lead"
assert_deny "product-lead cannot upload a file" \
  "mcp__chrome-devtools__upload_file" "tadeumendonca-skills:product-lead"
assert_deny "product-lead cannot handle a dialog" \
  "mcp__chrome-devtools__handle_dialog" "tadeumendonca-skills:product-lead"
# The plugin-qualified spelling of the same tool must be denied too, or the narrowing holds in one
# installation shape and not the other.
assert_deny "the read-only narrowing holds under the plugin-qualified spelling too" \
  "mcp__plugin_tadeumendonca-skills_chrome-devtools__evaluate_script" "tadeumendonca-skills:product-lead"

# ── the grant is to ONE server, not to MCP ──────────────────────────────────────────────────────
# The load-bearing case. These are live, credentialed, irreversible and public in the owner's name.
assert_deny "product-lead cannot reach linkedin" \
  "mcp__linkedin__send_message" "tadeumendonca-skills:product-lead"
assert_deny "product-lead cannot reach gmail" \
  "mcp__claude_ai_Gmail__send_message" "tadeumendonca-skills:product-lead"

# ── every other persona holds no grant ──────────────────────────────────────────────────────────
assert_deny "quality-assurance holds no MCP grant — the gate does not get a browser" \
  "mcp__plugin_tadeumendonca-skills_chrome-devtools__navigate_page" "tadeumendonca-skills:quality-assurance"
assert_deny "developer holds no MCP grant" \
  "mcp__plugin_tadeumendonca-skills_chrome-devtools__navigate_page" "tadeumendonca-skills:developer"
assert_deny "agents-lead holds no MCP grant — its object is the machinery, not the site" \
  "mcp__plugin_tadeumendonca-skills_chrome-devtools__navigate_page" "tadeumendonca-skills:agents-lead"
assert_deny "content-writer holds no MCP grant" \
  "mcp__linkedin__send_message" "tadeumendonca-skills:content-writer"
assert_deny "content-reviewer holds no MCP grant" \
  "mcp__linkedin__send_message" "tadeumendonca-skills:content-reviewer"
assert_deny "tech-lead holds no MCP grant" \
  "mcp__claude_ai_Figma__create_new_file" "tadeumendonca-skills:tech-lead"

# A persona nobody has written yet. This is ADR-0004's "absent is not a state": the default must be
# deny, or the roster growing silently grows the MCP surface with it.
assert_deny "an unknown persona defaults to DENY" \
  "mcp__plugin_tadeumendonca-skills_chrome-devtools__navigate_page" "tadeumendonca-skills:some-future-persona"

# ── the orchestrator is untouched ───────────────────────────────────────────────────────────────
# Empty agent_type. The owner drives LinkedIn/Gmail/Figma from the main session and this hook has no
# opinion about that; breaking it would be a floor rule invented to fix a subagent problem.
assert_allow "the orchestrator (empty agent_type) is not touched" \
  "mcp__linkedin__send_message" ""

# ── a non-MCP tool falls through even if the matcher misroutes it ───────────────────────────────
assert_allow "a non-MCP tool name falls through" "Bash" "tadeumendonca-skills:developer"

# ── the registration ────────────────────────────────────────────────────────────────────────────
if [ ! -f "$HOOKS_JSON" ]; then
  bad "hooks.json is readable" "not found at $HOOKS_JSON"
elif ! jq -e '.hooks.PreToolUse[] | select(.matcher == "mcp__.*")' "$HOOKS_JSON" >/dev/null 2>&1; then
  bad "hooks.json registers the mcp__.* matcher" \
      "no PreToolUse entry with matcher \"mcp__.*\" — the script below is unreachable and every
      assertion above is green over a control that never runs"
elif ! jq -e '.hooks.PreToolUse[] | select(.matcher == "mcp__.*") | .hooks[] | select(.command | test("mcp-guard\\.sh"))' "$HOOKS_JSON" >/dev/null 2>&1; then
  bad "the mcp__.* matcher runs mcp-guard.sh" \
      "the matcher is registered but does not invoke mcp-guard.sh"
else
  ok "hooks.json registers mcp-guard.sh on the mcp__.* matcher"
fi

# ── the declared server and the granted server are the same string ──────────────────────────────
# Two files have to agree on one name, and the failure when they disagree is SILENT: the brief names a
# server that does not exist, the persona gets no browser, and nothing says so. This is the arm that
# makes the disagreement loud.
MCP_JSON="$HERE/../../.mcp.json"
if [ ! -f "$MCP_JSON" ]; then
  bad ".mcp.json is readable" "not found at $MCP_JSON"
elif ! jq -e '.mcpServers | has("chrome-devtools")' "$MCP_JSON" >/dev/null 2>&1; then
  bad ".mcp.json declares the chrome-devtools server" \
      "the guard and product-lead's brief both name \"chrome-devtools\"; the plugin declares something else"
else
  ok ".mcp.json declares the chrome-devtools server the guard and the brief name"
fi

# The origin bound is what stops an exploratory sweep wandering the whole internet, and it is enforced
# by Chrome rather than by anything in this repo. If the flag is dropped, the sweep is unbounded and no
# other assertion here would notice.
if [ -f "$MCP_JSON" ] && jq -e '.mcpServers["chrome-devtools"].args | index("--allowedUrlPattern")' "$MCP_JSON" >/dev/null 2>&1; then
  ok ".mcp.json bounds the browser with --allowedUrlPattern"
else
  bad ".mcp.json bounds the browser with --allowedUrlPattern" \
      "the origin bound is missing — the sweep can reach any site"
fi

# `--isolated` is what keeps the server off the owner's real Chrome profile. Without it the default
# user-data-dir is a persistent profile, and `--autoConnect`/`--browserUrl` would reach the running
# browser with his logged-in sessions.
if [ -f "$MCP_JSON" ] && jq -e '.mcpServers["chrome-devtools"].args | index("--isolated")' "$MCP_JSON" >/dev/null 2>&1; then
  ok ".mcp.json keeps the browser on a throwaway profile (--isolated)"
else
  bad ".mcp.json keeps the browser on a throwaway profile (--isolated)" \
      "--isolated is missing — the server gets a persistent profile"
fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
