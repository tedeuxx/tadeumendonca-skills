#!/usr/bin/env bash
# session-plugin-version.sh — SessionStart hook: tell the session which BUILD of this
# harness it is actually running, and whether that build is behind the source.
#
# The third member of the session-start family, aimed at the failure the other two
# cannot see. `wip-guard` stops the queue growing; `session-wip` stops it staying
# invisible; this one stops the SESSION being wrong about itself.
#
# The failure, measured (#93). #88/#90 rewrote wip-guard from counting open PRs to
# intersecting changed files and merged as 0.4.18. Minutes later the guard denied a PR
# for a slice sharing no file with the open one — the exact case the rewrite exists to
# allow. The installed copy was 0.4.15, three versions behind and still count-based.
# The fix was merged, released, and had no effect on the machine it was written for.
#
# Why the repo's own gates cannot catch this. They verify the plugin's SOURCE. Nothing
# verifies that the plugin a session is RUNNING is the one that was verified, so every
# hook and persona change has an unbounded, invisible lag between merge and effect. And
# the lag is misattributed: an agent that sees a guard behave unexpectedly reasons about
# the RULE, because it has no way to know it is reading a different build than the one
# executing. A session told "you are on 0.4.21, source is 0.4.24" can act on that; one
# that is not, cannot.
#
# It matters most for the change that is hardest to notice: a renamed or deleted subagent
# still resolves to its OLD definition until the cache refreshes, so a dispatch silently
# runs a persona whose file no longer exists in the repo. That is not a degraded gate, it
# is a gate that was replaced and is still running the replaced version.
#
# Injects context, never blocks. A session must always be able to start.
#
# Contract: prints SessionStart JSON carrying additionalContext, exits 0. Silent on any
# error and silent when the versions match — a step that found nothing must not read like
# a step that found something.

set -uo pipefail

MARKETPLACE="$HOME/.claude/plugins/marketplaces/tadeumendonca/.claude-plugin/plugin.json"
SOURCE="${CLAUDE_PROJECT_DIR:-.}/.claude-plugin/plugin.json"

# ── DEPENDENCY PROBE: is the permission guard able to speak at all? ──────────────────────────────
#
# THE FAILURE BEING OBSERVED IS NOT THAT THE GUARD FAILS OPEN. That is a decision, taken with the
# cost in front of the owner: failing CLOSED on a missing `jq` wedges the agent with no repair route,
# because repairing it requires running commands. What was never decided is that the failure is
# SILENT — and separating those two is what makes this fixable without reopening the rejected option.
# Removing the silence does not make the guard fail closed. It makes an accepted cost observable.
#
# THE EVIDENCE THAT SILENCE IS THE DANGEROUS HALF IS ALREADY IN THIS REPO: `wip-guard.sh` records
# losing three rules to exactly this, with `jq` off `PATH`, and nobody noticed.
#
# WHY IT LIVES HERE: this hook already runs at every session start and already never blocks. A probe
# is observation, not enforcement, so it belongs in the observing hook rather than in the guard —
# the guard cannot report its own inability to report.
#
# THE PROBE MUST NOT NEED WHAT IT PROBES. `command -v` is a shell builtin: no `jq`, no subprocess,
# no dependency. A dependency check that depends on the thing it checks is the same defect one level
# up, and this file already had the pattern right in `read_version`.
guard_notice=""
if ! command -v jq >/dev/null 2>&1; then
  guard_notice="PERMISSION GUARD IS INERT THIS SESSION — \`jq\` is not on PATH.

\`permission-guard.sh\` builds its deny payload with \`jq\`, so without it the hook emits NOTHING and
the harness reads that as 'no decision'. It does not fail closed; it fails SILENTLY OPEN.

Verified rather than inferred: with \`jq\` stubbed to exit 127, \`gh pr merge <n> --merge\` produces no
output at all — and \`Bash(gh pr merge:*)\` is in the allowlist, so the MERGE GATE is open with no
decision from any layer.

WHAT IS LOST — derived, not listed, because a list of rule numbers goes stale and this does not:
  - EVERY rule in permission-guard.sh is inert. Read that file: whatever it denies, it does not deny
    this session.
  - settings.json \`deny\` still holds, but ONLY for the DIRECT spelling it lists. Anything wrapped in
    \`bash -c\`, composed with && or \$( ), semantic (which branch HEAD is on; whether a \`gh api\` call
    writes), or shadowed by an allow entry (\`gh -R:*\`, \`git -C:*\`) has no check in any layer.
  - Controls BORN in the hook never had a direct spelling in the floor to fall back to, so for those
    the loss is total rather than degraded. The merge gate is one of them.

WHAT TO DO: install \`jq\` and restart the session. Until then treat every irreversible act as
unguarded — merging, pushing to the trunk, \`terraform apply\`, \`rm -rf\`, secret writes — and verify
by READING the rule rather than by expecting a denial that cannot arrive."
fi

# Print a SessionStart payload. Extracted so the dependency notice can be emitted from the early
# returns below — without it, a session whose versions happen to MATCH would exit before saying that
# the guard is dead, which is the case where the notice matters just as much.
emit() {
  if command -v jq >/dev/null 2>&1; then
    jq -n --arg c "$1" '{
      hookSpecificOutput: {
        hookEventName: "SessionStart",
        additionalContext: $c
      }
    }'
  else
    # No jq: emit the same shape with the payload escaped by hand. A machine without jq must still
    # get the notice — this hook exists precisely for the case where tooling is not what someone
    # assumed it was, and that is now doubly true: the dependency notice above is BY DEFINITION
    # emitted only on machines without jq, so this branch is the one that carries it.
    escaped="$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk 'BEGIN{ORS="\\n"}{print}')"
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$escaped"
  fi
}

# Every early return goes through here, so the dependency notice survives paths that have nothing to
# say about versions. `exit 0` unconditionally: this hook has never blocked a session and must not
# start now — the entire point is that this is observation, not enforcement.
finish() {
  [ -n "$guard_notice" ] && emit "$guard_notice"
  exit 0
}

# Read the version out of a plugin manifest. jq if present, sed otherwise — this hook must
# not acquire a dependency the machines it runs on might lack.
read_version() {
  [ -r "$1" ] || return 1
  if command -v jq >/dev/null 2>&1; then
    jq -r '.version // empty' "$1" 2>/dev/null
  else
    sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -1
  fi
}

installed="$(read_version "$MARKETPLACE" || true)"
[ -z "$installed" ] && finish

# What to compare against depends on where the session opened, and getting this wrong makes
# the hook silent exactly where it matters most.
#
# Inside the harness repo, the local manifest is the right reference: it is the version a
# merge here just produced, and it needs no network.
#
# In a CONSUMING repo there is no such manifest — and that is the common case, since the
# harness exists to be installed elsewhere. Comparing against a local file there would make
# this hook silent in every repo that is not this one, which is the reverse of useful. So
# fall back to the latest published release. Best-effort: no `gh`, no auth or no network
# means no notice, never a delayed session.
reference="$(read_version "$SOURCE" || true)"
reference_label="source (this repo)"
if [ -z "$reference" ]; then
  command -v gh >/dev/null 2>&1 || finish
  reference="$(gh api repos/tedeuxx/tadeumendonca-skills/releases/latest --jq '.tag_name' 2>/dev/null || true)"
  reference="${reference#v}"
  reference_label="latest release"
fi
[ -z "$reference" ] && finish

source_version="$reference"

[ "$installed" = "$source_version" ] && finish

# Which way the drift runs decides what the session should do about it, so say it rather
# than reporting two numbers and leaving the reader to work it out. A source AHEAD of the
# install is the #93 case: merged work that is not executing. A source BEHIND it means the
# checkout is stale, which is a different action entirely.
if [ "$(printf '%s\n%s\n' "$installed" "$source_version" | sort -V | tail -1)" = "$source_version" ]; then
  direction="The published harness is AHEAD of the install: work that is merged is NOT what this session is executing."
  action="Merged hook, persona and skill changes have not taken effect. Most consequential and
least visible: a renamed or deleted subagent still resolves to its OLD definition, so a
dispatch runs a persona whose file no longer exists in this repo — and reads as working.
Treat any behaviour that contradicts a file you can read in this repo as the BUILD, not
the rule, and say so rather than reasoning about the rule. Restarting the session after
the marketplace refreshes is what makes the merged version effective."
else
  direction="The INSTALL is ahead: this checkout is behind what the machine is running."
  action="Pull before changing a hook or persona — editing against a stale checkout writes a
fix on top of a version that already moved."
fi

context="Harness build vs reference — they do not match.

  installed (marketplace): $installed
  $reference_label: $source_version

$direction

$action

This is issue #93: the repo's gates verify the plugin's SOURCE, and nothing verifies that
the plugin a session RUNS is the one that was verified. This notice is that verification."

# Both findings in ONE payload when both apply — two SessionStart objects on stdout is not a shape
# the harness reads, and the dependency notice goes FIRST because it is the more consequential of
# the two: a stale build runs the wrong rules, a dead guard runs none.
[ -n "$guard_notice" ] && context="$guard_notice

────────────────────────────────────────────────────────────────────────────────

$context"

emit "$context"
exit 0
