#!/usr/bin/env bash
# purpose: keep a subagent's MCP reach to the servers its brief was granted, so a brief that loses its tools line does not silently inherit every MCP server configured on the machine
# mcp-guard.sh — PreToolUse guard on the `mcp__.*` matcher. A subagent may call an MCP tool only from a
# server this file names for its persona. Everything else is denied.
#
# ── WHAT THIS EXISTS FOR (#355) ─────────────────────────────────────────────────────────────────
# Before this hook, the ONLY thing standing between a dispatched persona and every MCP server on the
# machine was the `tools:` line in its own brief. That containment is real — measured, probe against
# control, one variable — but it is a SINGLE LAYER, and it is a layer that holds by ABSENCE: no brief
# says "and no MCP"; each says `tools: Read, Grep, Glob, …` and MCP falls outside the list. Delete that
# one line from any brief and the persona inherits everything.
#
# WHAT "EVERYTHING" IS, MEASURED 2026-08-29 rather than imagined. A subagent dispatched with no `tools:`
# restriction, cwd = the consumer repo, enumerated its own MCP tools. The reply named ~400, among them:
#
#   mcp__linkedin__send_message          mcp__linkedin__connect_with_person
#   mcp__claude_ai_Gmail__send_message   mcp__claude_ai_Gmail__trash_thread
#   mcp__claude_ai_Google_Drive__share_file
#   mcp__claude_ai_Google_Calendar__delete_event
#
# Those servers are configured at PROJECT scope in the user's own `~/.claude.json`, not by this plugin,
# and they carry live credentials. Every one of those acts is irreversible and lands in public in the
# owner's name — the exact class the floor exists to refuse. The exposure PREDATES this hook and
# predates the chrome server; what changed is that somebody measured it.
#
# ── THE LAYER QUESTION (ADR-0004) — AND THE ANSWER MOVED ────────────────────────────────────────
# `settings.json` cannot hold this: its `deny` is a per-tool-name matcher with no notion of WHO is
# asking, and the whole point here is that the orchestrator keeps its MCP servers while subagents do
# not. `permission-guard.sh` cannot hold it either — it is registered on the `Bash` matcher and reads
# `.tool_input.command`, which an MCP call does not have.
#
# The open question was whether ANY hook can see an MCP call at all. Measured, probe plugin, one
# variable: a `PreToolUse` hook registered on matcher `mcp__.*` FIRED on a subagent's MCP tool call,
# received the fully-namespaced name in `.tool_name`, and its `deny` was honoured — the subagent
# reported back, verbatim:
#
#   RAW: HOOK-DENIED-MCP tool_name=mcp__plugin_probe-plug_chrome-devtools__nonce
#
# So the hook layer CAN carry this control. It is the only layer that can.
#
# ── THE POLARITY: DENY BY DEFAULT, ALLOW BY PERSONA ─────────────────────────────────────────────
# Same shape `permission-guard.sh` rule 5e already uses, and for the reason ADR-0004 states as
# "absent is not a state": a persona added later, or a server configured later, defaults to DENY and
# somebody has to decide it belongs. An allowlist of the forbidden servers would have to grow every
# time the owner installs an MCP connector, and would fail open in between.
#
# ── WHAT THIS DOES *NOT* TOUCH, DELIBERATELY ────────────────────────────────────────────────────
# The ORCHESTRATOR. `agent_type` is empty for the main session, and this hook exits without a decision
# there. The owner drives LinkedIn, Gmail, Figma and the rest from the main session; a guard that broke
# that would be a floor rule invented to fix a subagent problem. The orchestrator's MCP use is
# unmeasured by any hook and is left as a habit, exactly as `orchestrator-tool-census.sh` leaves reads.
#
# ── WHAT IT CANNOT DO ───────────────────────────────────────────────────────────────────────────
# It cannot tell whether a granted call is a good idea. `chrome-devtools` bounded to one origin is
# still a scriptable browser, and this hook has no opinion about what the persona does inside it. The
# URL bound is the server's own `--allowedUrlPattern`, enforced by Chrome, not by anything here.
#
# It also cannot see a call the harness does not stamp. `agent_type` is harness-written and the model
# cannot forge it — that is the property this rule rests on, the same one 5d and 7b rest on — but a
# future dispatch shape that leaves it empty would read to this hook as the orchestrator.

set -uo pipefail

input="$(cat)"

tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null || true)"
agent_type="$(printf '%s' "$input" | jq -r '.agent_type // empty' 2>/dev/null || true)"

# Not an MCP call. The matcher should have prevented this, but a matcher is configuration and this is
# the file that has to be right if the configuration drifts.
case "$tool_name" in
  mcp__*) : ;;
  *) exit 0 ;;
esac

# The orchestrator. See "WHAT THIS DOES *NOT* TOUCH" above.
[ -z "$agent_type" ] && exit 0

deny() {
  jq -n --arg r "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $r
    }
  }'
  exit 0
}

# ── THE GRANT TABLE ─────────────────────────────────────────────────────────────────────────────
# One case per persona that holds an MCP grant. `agent_type` arrives as `<plugin>:<persona>`, so the
# patterns are suffix-matched exactly as rule 5e's are.
#
# The server segment is matched as `*_chrome-devtools__*` rather than against the full plugin-qualified
# name, because the SAME server resolves under two different tool-name spellings depending on where it
# was declared, and both are legitimate:
#
#   mcp__plugin_tadeumendonca-skills_chrome-devtools__navigate_page   (declared by this plugin)
#   mcp__chrome-devtools__navigate_page                              (declared by a consuming repo)
#
# Both were measured resolving from a plugin-shipped brief. Matching the server segment covers the
# consuming repo that declares its own instance with its own origin bound — which is the override path
# the project-agnostic default in `.mcp.json` exists to leave open.
#
# ── THE GRANT IS A NAMED SUBSET, NOT THE SERVER — AND THAT IS THE EGRESS ANSWER ─────────────────
# The `tools:` frontmatter can only express a whole server (`mcp__…_chrome-devtools`); it has no way to
# say "these 12 tools of the 29". This hook is where that narrowing is expressed, and it is the reason
# the grant is safe to give a persona that rule 5e denies public surfaces to.
#
# WHY IT MATTERS. Rule 5e denies `product-lead` `gh …comment`/`gh issue create` because it reads the
# private positioning layer and a paraphrase into a public surface is not revertible. **A browser is a
# route to the outside that a read-only grant did not previously include** — a URL is a channel, and a
# navigation carries whatever is in it. `--allowedUrlPattern` narrows the destination to the owner's own
# origin; it does NOT make the channel disappear (a query string lands in his CloudFront logs).
#
# So the INPUT-CARRYING tools are denied, and none of them is needed to look at a page:
#   evaluate_script   arbitrary JS in the page — the sharpest; it can compose and issue its own requests
#   fill / fill_form / type_text / upload_file / handle_dialog / drag   put data INTO the page
#
# What remains is a viewer: navigate, screenshot, snapshot, resize, emulate, read the console, read the
# network log, open and close pages, wait. That is the whole mechanical half of the sweep.
#
# `click` IS allowed, deliberately and with the cost stated: the sweep has to follow a nav link and has
# to trigger the PDF download, and neither is reachable without it. A click can submit a form somebody
# else's markup put on the page — so this is a narrowing, not a closure, and the brief carries the
# standing rule (never log in, never submit) that covers the residue.
case "$agent_type" in
  *:product-lead)
    case "$tool_name" in
      # the denied subset, listed FIRST so a widening of the allow pattern below cannot silently
      # re-admit one of them
      *__evaluate_script|*__fill|*__fill_form|*__type_text|*__upload_file|*__handle_dialog|*__drag)
        deny "Blocked: '${tool_name}' puts data INTO a page, and \`product-lead\`'s browser grant is READ-ONLY. The sweep looks at the live site; it does not drive it. This is not an oversight to widen: rule 5e denies you public surfaces because you read the private positioning layer, and an input-carrying browser tool is a route to the outside that the read-only grant deliberately does not include. If the sweep genuinely cannot be done without this, that is a finding for your return and a decision for the owner — not a workaround. agent_type='${agent_type}'."
        ;;
      mcp__*_chrome-devtools__*|mcp__chrome-devtools__*) exit 0 ;;
    esac
    deny "Blocked: \`product-lead\` holds ONE MCP grant — the \`chrome-devtools\` browser, read-only, for the iteration-close regression sweep of the live site — and '${tool_name}' is not it. This is not a missing allowlist entry to add: MCP servers configured on this machine include publishing and messaging surfaces that act irreversibly in the owner's name (LinkedIn, Gmail, Drive), and no persona reaches them. If the sweep needs something the browser cannot give you, that is a finding for your return, not another server. agent_type='${agent_type}'."
    ;;
  *)
    deny "Blocked: '${agent_type}' holds no MCP grant, and '${tool_name}' is therefore denied. New personas default to DENY here, per ADR-0004's 'absent is not a state' — a grant is a decision somebody makes by name in mcp-guard.sh, never a gap to route around. Only \`product-lead\` holds one today (the \`chrome-devtools\` browser, advisory sweep of the live site). If your brief's \`tools:\` line named this server, the two disagree and THAT is the finding: say so in your return rather than working around it."
    ;;
esac
