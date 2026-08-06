#!/usr/bin/env bash
# session-scratch.sh — SessionStart hook: a new session starts with an empty scratch.
#
# THE PROBLEM THIS EXISTS FOR, measured rather than assumed. `/private/tmp/claude-501/` held 16
# session directories, the oldest ten days old, 38 MB, on a machine with no periodic sweeper. And
# a gitignored `apps/fed/.scratch/` in the other repo held seven files untouched for ten days. So
# "temporary" was an intention in two places at once and true in neither, and things that mattered
# — an interview transcript, a measurement instrument — ended up living somewhere designed to be
# thrown away.
#
# THE OWNER'S TWO REQUIREMENTS, in his words: the scratch must be "efêmero de verdade", and it
# must sit "dentro do root de cada repositório". This hook is the first half; `<root>/.scratch/`
# being the documented location is the second.
#
# THE CEILING, STATED SO IT IS NOT OVERSOLD. Nothing can delete a file *because its use ended* —
# there is no event for that. The session boundary is the only observable proxy, so the honest
# guarantee is exactly this: NOTHING SURVIVES INTO A NEW SESSION. Within a session files live, and
# they must: a PR body is written and consumed minutes apart. He accepted that ceiling explicitly,
# on the reasoning that anything escaping one sweep is caught by the next.
#
# WHY A HOOK RATHER THAN A RULE THE AGENT FOLLOWS. Every recursive delete the agent could issue is
# either denied by the floor (`rm -rf`, `git clean -fdX`) or asks the human (`rm -r`) — except
# `find -delete`, which passes with no decision from any layer. So "the agent tidies up after
# itself" resolves to "the agent uses the one delete nothing watches". A hook does not pass through
# the permission matcher at all (measured: `session-wip.sh` runs `gh` with no `gh` entry in
# `allow`), so cleanup belongs here and nowhere else.
#
# WHY SessionStart AND NOT SessionEnd. SessionEnd is best-effort — it does not fire on a crash,
# and the 16 orphaned directories are what best-effort looks like after two weeks. It would also
# delete during the window in which a handoff is still needed. SessionStart fails SAFE: if it does
# not run you accumulate, visibly, and never lose work.
#
# Contract: prints SessionStart JSON carrying additionalContext when it removed something, exits 0
# always. Silent when there was nothing to remove — a report of "removed 0 files" every session is
# noise that teaches the reader to skip the line that matters.

set -uo pipefail

# The roots are ENUMERATED, not derived. `$CLAUDE_PROJECT_DIR` is singular and this workspace has
# two repos, so deriving from it would cover whichever one the session was opened from and leave
# the other accumulating — the same shape as a glob that does not reach the second repo.
#
# `SCRATCH_ROOTS` is an INJECTED SEAM AND IT EXISTS FOR THE SUITE. A hook whose only targets are
# two absolute paths on one machine cannot be exercised without deleting the author's real files,
# and a delete nobody can test is the last thing this repo should ship. The seam is not a
# widening: a hook is invoked by the harness, never by the agent, so nothing in the loop can set
# it. Default is the real pair.
ROOTS="${SCRATCH_ROOTS:-
/Users/tadeumen/git-reps/tadeumendonca-io
/Users/tadeumen/git-reps/tadeumendonca-skills
}"

removed_total=0
report=""

while IFS= read -r root; do
  [ -z "$root" ] && continue
  scratch="$root/.scratch"
  [ -d "$scratch" ] || continue

  # Count before removing, so the report describes what happened rather than what was attempted.
  n="$(find "$scratch" -mindepth 1 2>/dev/null | wc -l | tr -d ' ')"
  case "$n" in
    ''|0) continue ;;
  esac

  # `-mindepth 1` keeps the directory itself, so the next write does not have to recreate it — and
  # so a path error cannot walk upward into tracked files. `find -delete` rather than `rm -rf`
  # because the floor denies the latter to every caller including this one; see the header.
  find "$scratch" -mindepth 1 -delete 2>/dev/null

  left="$(find "$scratch" -mindepth 1 2>/dev/null | wc -l | tr -d ' ')"
  removed=$((n - ${left:-0}))
  removed_total=$((removed_total + removed))
  report="$report
  - ${scratch#/Users/tadeumen/git-reps/}: removed $removed of $n"
done <<EOF
$ROOTS
EOF

[ "$removed_total" -eq 0 ] && exit 0

context="Scratch cleared for this session ($removed_total entries):
$report

\`<repo-root>/.scratch/\` is the ONLY place for scratch files, and it does not survive a session.
Write PR bodies and commit messages there; nothing else. A review verdict belongs in the PR
comment, which is already the durable record and is already machine-read. Raw source material
belongs in \`.brand/\`. A measurement instrument becomes a repo script with a test if a gate will
run it, and is discarded otherwise.

If a count above is lower than the number found, something in that directory could not be removed
— a permission or a busy file — and the next session will try again."

jq -n --arg c "$context" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $c
  }
}'
exit 0
