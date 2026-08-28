#!/usr/bin/env bash
# purpose: keep the orchestrator out of a repository's working tree, so every edit passes through the persona that owns it and through the gates that key on a persona
# orchestrator-write-guard.sh — PreToolUse guard on the FILE-WRITING tools: the orchestrator does not
# edit a repository directly. It dispatches a persona that does.
#
# ── WHAT THIS EXISTS FOR (#319) ─────────────────────────────────────────────────────────────────
# The orchestrator is denied merge (rule 7b) and trunk push (rule 7) by `permission-guard.sh`, and
# nothing else. Everything between those two acts — editing a tracked file, editing a brief, editing a
# hook — was open, so a session could do the whole build in the main context and never dispatch the
# builder that owns it. That is not a floor violation (the work is tracked, reviewable, revertible); it
# is the WRONG LAYER, and the cost is that no persona's judgement, and no gate that keys on a persona,
# ever touched it.
#
# ── WHY THIS IS A SEPARATE HOOK AND NOT A RULE IN `permission-guard.sh` ─────────────────────────
# `permission-guard.sh` is registered on the `Bash` matcher and exits at line 3 of its body when
# `.tool_input.command` is empty — which every file-writing call is. Wiring it to a second matcher
# would run its ~90 Bash rules against a payload that has no command, for every Edit in the session.
# Two matchers, two scripts, one concern each.
#
# ── THE POLARITY: DENY BY SCOPE, NEVER ALLOW-LIST THE EXEMPT PATHS ─────────────────────────────
# The rule is *inside a git working tree → deny*, not *outside the scratchpad → deny*. The harness's
# session scratchpad path embeds the session id, so allow-listing it means deriving a path shape that
# is the harness's to change; the memory layer would need a second entry; and both would have to be
# re-derived the next time the harness moves its temp root. Scope-denial exempts all of them without
# naming any of them, and stays correct when those paths move. The load-bearing case is the scratchpad
# itself: PR bodies and verdicts are composed there for `--body-file`, and a guard that broke that
# route would break the posting discipline `command-hygiene` mandates.
#
# ── THE MATCHER IS AN ENUMERATION, AND IT HAD TO BE — MEASURED 2026-08-23 ──────────────────────
# A `matcher` is ANCHORED, not a substring search. Probe plugin, one variable:
#
#   matcher "rit"                  + a main-agent `Write`        → hook did NOT fire; the file was created
#   matcher "Write"                + the same call               → fired, denied, no file (control)
#   matcher "Edit|Write"           + a main-agent `NotebookEdit` → hook did NOT fire; the notebook was
#                                                                  MUTATED inside a git working tree
#   matcher "Edit|Write|NotebookEdit|MultiEdit" + the same call  → fired, denied, notebook unchanged
#
# So `Edit|Write` — the matcher this rule was specified with — leaves an open side door, and it is not
# hypothetical: the third row is a real mutation of a real file inside a real git tree by an
# orchestrator-shaped call. `NotebookEdit` is a DEFERRED tool in this build (its name is listed, its
# schema loads on demand via `ToolSearch`), which is exactly why it is easy to miss by reading a tool
# list: it is not in the session's initial one. `MultiEdit` is named although this build (2.1.241)
# offers no such tool — a matcher naming a tool that does not exist costs nothing and is the cheap half
# of covering a build where it returns. `Bash`-side routes (`sed -i`, `tee`, a redirect) are NOT
# covered here and are a named residual, not an oversight — see the bottom of this header.
#
# ── AND THE PATH KEY IS AN ENUMERATION TOO, WHICH IS THE SUBTLER HALF ──────────────────────────
# `NotebookEdit` does not carry `file_path`. Measured from the same probe's payload:
#   `keys=["cell_id","new_source","notebook_path"]`
# A guard reading only `.tool_input.file_path` therefore ALLOWS every NotebookEdit even with the
# matcher naming it — a second side door behind the first, and one that no matcher fix would close.
# Both keys are read below. A future write tool adds a third; the test suite asserts the fallback chain
# so that adding one is a visible edit rather than a silent hole.
#
# ── WHO IS EXEMPT, AND WHY THAT IS THE DIRECTION THAT MATTERS MOST ─────────────────────────────
# `agent_type` is stamped by the harness at the payload ROOT and is empty for the main agent — the same
# field `permission-guard.sh` rules 5c/5d/5e/7b key on, and the same property holds: the model's only
# contribution is `.tool_input.*`, a sibling, so no spelling of a file path claims a persona. ANY
# non-empty `agent_type` is allowed through. That is deliberately broader than an allowlist of the
# personas that build: a deny that caught `developer` would stop the loop dead, and the roster changes
# more often than this rule should. This enforces ROUTING, not capability — the main loop can still
# reach any of these paths, by dispatching the persona that owns them, which is the whole point.
#
# ── WHO OWNS THE WORK THIS DENY REFUSES ────────────────────────────────────────────────────────
# `developer` for app/infra/pipeline/test code; `content-writer` for published prose AND for `.brand/`
# edits (the owner's decision on #319 — it already reads that private layer to draft, it is the content
# builder, it is contained by `permission-guard.sh` rule 5e, and no other persona has a mandate there;
# `product-lead` holds no `Write` grant at all). `agents-lead` for the harness itself, per ADR-0002.
# Every path this rule denies has an assignee; that was the precondition the owner closed before it
# shipped.
#
# ── THE HALF THAT IS A HABIT AND IS NOT MECHANISED, STATED SO IT READS AS A DECISION ───────────
# Nothing here touches READS, `gh issue create`, or the `gh pr comment` / `gh issue comment` routes
# rule 5e allows the orchestrator. Not an omission — a decision, taken on #319 with the argument
# recorded: a hook sees `grep` and a path, never whether the answer was already in a subagent's return,
# so it cannot tell a justified read from a lazy one, and a control that cannot see its target is worse
# than none. Denying the comment routes would be worse still: at intake there is frequently no PR and
# no gate dispatch, `product-lead` holds no `Write`, and a copy-lens finding would have no path to any
# durable artifact. Keeping the orchestrator's own reading and posting proportionate is a HABIT,
# observed by `orchestrator-tool-census.sh` (Stop) and enforced by nobody.
#
# ── NAMED RESIDUAL: THE `Bash` SIDE DOOR ───────────────────────────────────────────────────────
# `Bash(sed:*)` and `Bash(tee:*)` are in this repo's committed allow list, so an orchestrator that
# writes `sed -i` or `tee` reaches a tracked file without passing this matcher. That door is left open
# knowingly: closing it means resolving a path out of a shell command string, which is the semantic
# class ADR-0004 says a pattern cannot hold (a rule that guessed wrong would deny `developer`'s builds
# too, since `permission-guard.sh` must decide from the same string). What covers it instead is
# DETECTION — the census classifies those commands into its write/post class by name, so the route
# stays visible even though it is not blocked. `command > file` is already denied outright for
# everyone by `permission-guard.sh` (#244), so the loudest spelling of this door was closed before this
# rule existed.
#
# Contract: receives the PreToolUse JSON on stdin; denies by printing a permissionDecision JSON and
# exiting 0. FAILS OPEN (allows) on a missing `jq`, a missing `git`, an unreadable payload, a payload
# with no path, or any path that resolves outside a git tree — the same trade `permission-guard.sh`
# makes and for the same reason: a guard that wedges the loop cannot be repaired by the agent, because
# repairing it requires running commands.

set -uo pipefail

input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

command -v jq >/dev/null 2>&1 || exit 0

# WHO. Empty == the main agent (the orchestrator). Any persona is allowed straight through.
agent_type="$(printf '%s' "$input" | jq -r '.agent_type // empty' 2>/dev/null || true)"
[ -n "$agent_type" ] && exit 0

# WHAT PATH. The fallback chain IS the enumeration — see the header; `notebook_path` is NotebookEdit's
# key and the reason a `file_path`-only read is a hole rather than a simplification.
path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null || true)"
[ -z "$path" ] && exit 0

cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
case "$path" in
  /*) : ;;
  *)  [ -z "$cwd" ] && exit 0; path="$cwd/$path" ;;
esac

command -v git >/dev/null 2>&1 || exit 0

# The file being created need not exist, and neither need its directory. Walk up to the first ancestor
# that does — that is the directory whose repository membership decides this call.
dir="$path"
while [ ! -d "$dir" ]; do
  parent="$(dirname "$dir")"
  [ "$parent" = "$dir" ] && break
  dir="$parent"
done
[ -d "$dir" ] || exit 0

# `rev-parse --git-dir` succeeds inside a work tree AND inside a `.git` directory. Both are denied
# deliberately — a write into `.git/` escapes the diff entirely, which is a stronger version of the
# same failure this rule exists for, not an exception to it.
#
# (The word was "on purpose" until #313, wrapped so that "purpose:" began a line. `purpose:` is now a
# DECLARED FIELD in this plugin, read at line 2 of every registered hook, and a naive consumer greps
# `^# purpose:` rather than reading a position. One accidental column-0 occurrence in prose is enough
# to hand that consumer two answers for a file that has one — so the sentence was rewrapped rather
# than the gate loosened.)
git -C "$dir" rev-parse --git-dir >/dev/null 2>&1 || exit 0

reason="Denied: the orchestrator does not edit a repository directly — it dispatches the persona that owns the work.

path: ${path}

This is orchestrator-write-guard.sh (#319), a PreToolUse guard on the file-writing tools. It denies
this call because agent_type is empty (the main agent) and the path resolves inside a git working
tree. It is a ROUTING rule, not a capability limit: dispatch the persona that owns this file and the
identical edit goes through.

  app / infrastructure / pipeline / tests  ->  developer
  published prose, site copy, .brand/      ->  content-writer
  hooks, settings, briefs, skills, plugin  ->  agents-lead

Still open to the orchestrator, deliberately: any path that is not inside a git working tree. The
session scratchpad is the load-bearing case — PR bodies and verdict text are composed there for
--body-file — and it qualifies because it holds no repository, not because it is the scratchpad."

jq -n --arg r "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $r
  }
}'
exit 0
