#!/usr/bin/env bash
# purpose: tell a starting session which build of this harness it is actually running and whether that build is behind the source, because every other gate verifies the source and none verifies the install
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
# ── THE DEFECT THIS FILE CARRIED FOR ITS FIRST ELEVEN MONTHS (#370) ──────────────────────────────
#
# It read the MARKETPLACE CLONE and called the result `installed`. The marketplace clone is
# the shared checkout `/plugin marketplace update` refreshes; it is not the build any session
# necessarily runs. Measured on 2026-08-31: `~/.claude/plugins/installed_plugins.json` held a
# PROJECT-scope record pinning `tadeumendonca-io` to 1.0.16 — **69 published releases** and 17 days
# behind (`git tag --list 'v*' --sort=v:refname` between v1.0.16 and v1.1.51 → 69; the "35" #370's
# intake published is `51 − 16`, patch-component subtraction across a minor boundary, and it is struck
# in ADR-0005's 2026-09-01 amendment) —
# while the marketplace clone read 1.1.51. The hook compared 1.1.51 against its reference,
# matched, and FINISHED SILENTLY. The one mechanism built to see exactly this drift could not,
# because it was reading the wrong file. That 1.0.16 build had no `agents-lead`, no
# `content-writer`, no `content-reviewer`, no merge floor (rule 7c) and no milestone rule
# (rule 10) — a session there ran a harness whose rules had been superseded five times over.
#
# THE RUNTIME ALREADY HANDS THIS HOOK THE ANSWER, and it is `$0`. `hooks/hooks.json` registers
# every hook by interpolated absolute path — `"${CLAUDE_PLUGIN_ROOT}"/hooks/scripts/<name>.sh` —
# so `$0` IS the running build's path, and each cached build carries its own manifest. Measured:
# a script placed at `<root>/9.9.9/hooks/scripts/probe.sh` and invoked by that absolute path
# reports `$0` as that path and reads `9.9.9` back out of `<root>/9.9.9/.claude-plugin/plugin.json`.
#
# THE REJECTED ALTERNATIVE, and it is rejected for the reason this hook exists. The obvious fix
# was "read `installed_plugins.json` and match `projectPath` against the session's directory".
# Every open unknown in that design — record precedence, the `local`/`managed` scopes, a schema
# that can move, subdirectory and worktree sessions, symlinked macOS paths (`/Users/…` versus
# `/System/Volumes/Data/Users/…`) — exists only because it RE-DERIVES a fact the runtime gives
# away. Each is a heuristic and each fails silently, in a hook that never blocks. Worse, its
# stated fallback resolved a failed match to the `user` record, which on 2026-08-14 would have
# reported "up to date" while running a build 69 releases old. A hook whose whole job is "you may
# be wrong about yourself" must never resolve an ambiguity in the direction of comfort.
#
# A `$0`-derived read also fixes `claude --plugin-dir .`, the documented local-authoring route,
# where the marketplace read could emit a stale-build notice about a build that is not in play.
#
# ── THE SECOND ARM IS THE POINT, NOT AN EXTRA (#370) ─────────────────────────────────────────────
#
# The primary arm reports staleness FROM INSIDE the stale session. The `-io` install sat at
# 1.0.16 for 17 days precisely BECAUSE that project was never opened — a perfectly-fixed primary
# arm stays silent for all 17 of them. The cross-project arm fires from wherever the owner
# actually works, about the projects nobody opens. So the arms invert: cross-project is the
# point, self-report is the cheap sanity line.
#
# They also read two different files for two different questions — `$0` for *what am I running*,
# `installed_plugins.json` for *what is registered elsewhere* — each the correct file for its
# question, which is exactly the property the old single-file read had lost.
#
# Injects context, never blocks. A session must always be able to start.
#
# Contract: prints SessionStart JSON carrying additionalContext, exits 0. Silent on any
# error and silent when the versions match — a step that found nothing must not read like
# a step that found something.

set -uo pipefail

# `$0` is the path this build was invoked as; the manifest two levels up from `hooks/scripts/`
# is that build's own. See the #370 block above for why this and not the marketplace clone.
#
# `${0%/*}` and NOT `$(dirname "$0")`, for the reason this file already applies to `read_version`:
# this hook must not acquire an external it might not have. Parameter expansion is a shell builtin;
# `dirname` is a program on PATH. That is not theoretical — the no-jq arm of this hook's own test
# arranges a PATH holding only the externals the hook uses, and the first `dirname` draft silently
# lost the entire version finding there, reporting only the guard notice. It failed in the direction
# of saying nothing, which is this hook's worst direction and the one it exists to remove.
# `preflight.sh` already uses this form at SessionStart for the same reason.
#
# When `$0` carries no `/` at all (invoked as a bare name resolved through PATH) the expansion
# yields `$0` unchanged, the derived path does not resolve, and the hook stays SILENT about the
# running build. That is the correct degradation: a build it cannot identify is not a build it may
# call up to date.
SELF_MANIFEST="${0%/*}/../../.claude-plugin/plugin.json"
REGISTRY="$HOME/.claude/plugins/installed_plugins.json"
SOURCE="${CLAUDE_PROJECT_DIR:-.}/.claude-plugin/plugin.json"
PLUGIN_KEY="tadeumendonca-skills@tadeumendonca"

# ── DEPENDENCY PROBE: is the permission guard able to speak at all? ──────────────────────────────
#
# THE FAILURE BEING OBSERVED IS NOT THAT THE GUARD FAILS OPEN. That is a decision, taken with the
# cost in front of the owner: failing CLOSED on a missing `jq` wedges the agent with no repair route,
# because repairing it requires running commands. What was never decided is that the failure is
# SILENT — and separating those two is what makes this fixable without reopening the rejected option.
# Removing the silence does not make the guard fail closed. It makes an accepted cost observable.
#
# THE EVIDENCE THAT SILENCE IS THE DANGEROUS HALF IS ALREADY IN THIS REPO: with `jq` off `PATH` the
# permission guard emitted no decision at all, and nobody noticed. That measurement was recorded in
# `wip-guard.sh`'s header until #383 deleted it; it is now in `permission-guard.sh`'s own header,
# under the fail-open decision.
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
    writes), or shadowed by a broad allow entry on the same tool (\`git -C:*\`) has no check in any layer.
  - Controls BORN in the hook never had a direct spelling in the floor to fall back to, so for those
    the loss is total rather than degraded. The merge gate is one of them.
  - cross-project check skipped: no jq. Selecting a nested object by key out of the install registry
    has no honest \`sed\` equivalent, so the arm that reports OTHER projects' stale installs does not
    run on this machine. The primary self-report above needs no jq and is unaffected.

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

# Accumulated findings, in the order a reader should meet them. Kept as one variable rather than
# emitted per arm: two SessionStart objects on stdout is not a shape the harness reads.
findings=""
add_finding() {
  if [ -z "$findings" ]; then
    findings="$1"
  else
    findings="$findings

────────────────────────────────────────────────────────────────────────────────

$1"
  fi
}

# Every early return goes through here, so the dependency notice survives paths that have nothing to
# say about versions. `exit 0` unconditionally: this hook has never blocked a session and must not
# start now — the entire point is that this is observation, not enforcement.
finish() {
  # The dependency notice goes FIRST when it applies: a stale build runs the wrong rules, a dead
  # guard runs none.
  if [ -n "$guard_notice" ]; then
    if [ -n "$findings" ]; then
      emit "$guard_notice

────────────────────────────────────────────────────────────────────────────────

$findings"
    else
      emit "$guard_notice"
    fi
  elif [ -n "$findings" ]; then
    emit "$findings"
  fi
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

# THE BUILD THIS SESSION IS RUNNING. Empty means the manifest two levels up from this script is
# unreadable — the hook was invoked from somewhere that is not a plugin tree. That is a genuine
# "could not determine", and the correct output for it is silence about the running build, never
# a guess and never "up to date".
running="$(read_version "$SELF_MANIFEST" || true)"

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

# ── ARM 1: what THIS session is running ──────────────────────────────────────────────────────────
if [ -n "$running" ] && [ "$running" != "$reference" ]; then
  # Which way the drift runs decides what the session should do about it, so say it rather
  # than reporting two numbers and leaving the reader to work it out. A source AHEAD of the
  # install is the #93 case: merged work that is not executing. A source BEHIND it means the
  # checkout is stale, which is a different action entirely.
  if [ "$(printf '%s\n%s\n' "$running" "$reference" | sort -V | tail -1)" = "$reference" ]; then
    direction="The published harness is AHEAD of the build this session is running: work that is merged is NOT executing here."
    # THE REMEDY THIS HOOK USED TO PRESCRIBE DID NOT WORK, and that is how #370 stayed invisible
    # for 17 days. It said "restarting the session after the marketplace refreshes is what makes
    # the merged version effective". Refreshing the marketplace moves the shared CLONE and leaves
    # the per-scope INSTALL RECORD exactly where it was; a restart then re-resolves the same
    # pinned build. Both steps are needed, and the update is per scope.
    action="Merged hook, persona and skill changes have not taken effect. Most consequential and
least visible: a renamed or deleted subagent still resolves to its OLD definition, so a
dispatch runs a persona whose file no longer exists in this repo — and reads as working.
Treat any behaviour that contradicts a file you can read in this repo as the BUILD, not
the rule, and say so rather than reasoning about the rule.

To make the merged version effective, refresh the marketplace AND move this scope's install
record, then restart — refreshing the clone alone leaves the record pinned where it was:
  /plugin marketplace update tadeumendonca
  /plugin update tadeumendonca-skills@tadeumendonca"
  else
    direction="The BUILD is ahead: this checkout is behind what the session is running."
    action="Pull before changing a hook or persona — editing against a stale checkout writes a
fix on top of a version that already moved."
  fi

  add_finding "Harness build vs reference — they do not match.

  running build (this session): $running
  $reference_label: $reference

$direction

$action

This is issue #93: the repo's gates verify the plugin's SOURCE, and nothing verifies that
the plugin a session RUNS is the one that was verified. This notice is that verification.
Which file answers that question is issue #370: it is this build's own manifest, derived
from \$0, not the shared marketplace clone this hook used to read."
fi

# ── ARM 2: the projects nobody opens ─────────────────────────────────────────────────────────────
#
# jq-gated by construction: there is no honest `sed` equivalent of selecting a nested object by key
# out of this registry, and the jq-less machine already gets a louder notice above.
if command -v jq >/dev/null 2>&1 && [ -r "$REGISTRY" ]; then
  # THREE CASES THAT MUST NEVER END IN "up to date":
  #   SCHEMA — the registry declares a version this hook has not read. Do not parse a schema you
  #            do not know; say so and stop.
  #   SCOPE  — a record carries a scope other than `project`/`user`. `claude plugin update --help`
  #            names `local` and `managed`; neither has ever been observed here, so treat an
  #            unrecognised one as possibly-in-play and REFUSE to conclude rather than skipping it
  #            quietly and reporting on the rest as if the set were complete.
  #   (file absent) — nothing registered to report on. Genuine silence, handled by the `-r` test.
  cross="$(jq -r --arg key "$PLUGIN_KEY" --arg ref "$reference" '
    if (.version != 2) then "SCHEMA"
    else
      ((.plugins[$key]) // []) as $recs
      | if ([$recs[] | select(.scope != "project" and .scope != "user")] | length) > 0
        then "SCOPE"
        else
          [$recs[]
            | select(.scope == "project")
            | select((.version // "") != $ref)
            | "  " + (.projectPath // "<record carries no projectPath>") + "  →  " + (.version // "?")]
          | join("\n")
        end
    end' "$REGISTRY" 2>/dev/null || true)"

  case "$cross" in
    SCHEMA)
      add_finding "Cross-project install check SKIPPED — could not determine.

$REGISTRY declares a schema version this hook has not read. Nothing is claimed about any other
project's install: an unparsed registry is an unknown, not a clean bill of health." ;;
    SCOPE)
      add_finding "Cross-project install check SKIPPED — could not determine.

$REGISTRY holds a record whose \`scope\` is neither \`project\` nor \`user\` (\`claude plugin update
--help\` names \`local\` and \`managed\`). An unrecognised scope may be in play, so this arm refuses to
report on the records it DOES recognise — a partial answer presented as a complete one is the
failure this hook exists to prevent." ;;
    "") : ;;
    *)
      add_finding "OTHER PROJECTS ARE PINNED TO A DIFFERENT BUILD — and none of them will say so
until someone opens a session there.

Reference ($reference_label): $reference
Project-scope install records that differ:

$cross

This is the half of #370 that matters: a project's install record is written once by \`install\`
and never surfaced again, so a project nobody opens can sit any number of versions behind for any
length of time with every gate in this repo green. Measured on 2026-08-31: \`tadeumendonca-io\` sat
69 published releases and 17 days behind, on a build with no merge floor and no \`agents-lead\`.

Each stale record moves WITHOUT opening a session there:
  env -C <projectPath> claude plugin update $PLUGIN_KEY --scope project -y

(\`env -C\` is GNU-shaped and not universally portable; it fails loudly where it is absent, which is
acceptable for a printed suggestion. Whether the owner wants each of these moved is his call — this
arm reports, it does not act.)" ;;
  esac
fi

finish
