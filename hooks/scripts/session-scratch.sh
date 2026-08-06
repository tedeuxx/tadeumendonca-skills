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
# itself" resolves to "the agent uses the one delete nothing watches", which is not a discipline
# anyone should want. A hook runs as a subprocess of the harness rather than as a tool call, so
# `PreToolUse` never sees it: no `allow` entry covers a hook invocation, and none is needed.
#
# TWO CLAIMS THAT USED TO SIT HERE WERE WRONG, and the corrections are the useful part.
#
# The first cited `session-wip.sh` running `gh pr list` with no `gh` entry in `allow` as evidence
# that hooks bypass the matcher. `Bash(gh pr list:*)` IS in `allow`, in both repos — so that
# command runs either way and the observation discriminated nothing. It was vacuous, not merely
# mistaken.
#
# The second said `find -delete` was chosen because the floor denies `rm -rf` "to every caller
# including this one". That is circular: it cannot be true both that a hook bypasses the matcher
# and that the matcher constrains this script. THE REAL REASON is smaller and checkable, and the
# suite already asserts it: `-mindepth 1 -delete` empties the directory and PRESERVES it, where
# `rm -rf` would remove it. Nothing here depends on `find` being permitted to the agent.
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

# IT SWEEPS ON A NEW SESSION, NOT ON A RESUMED ONE, and getting this wrong reintroduced the very
# failure this hook exists to fix. `SessionStart` fires when a session begins OR RESUMES. A resumed
# session is the same unit of work — the PR body written before the pause is still owed to the
# command that consumes it — so sweeping there empties the scratch underneath live work.
#
# ALLOWLIST, NOT DENYLIST, and that direction is the whole safety argument. It sweeps only on a
# `source` it recognises as a genuinely new session; anything else, INCLUDING AN ABSENT OR
# UNRECOGNISED VALUE, is left alone and reported. If the field is ever renamed upstream this hook
# goes inert and says so on the next session — accumulation is visible and recoverable, a delete
# under live work is neither.
payload="$(cat 2>/dev/null || true)"
source_kind="$(printf '%s' "$payload" | jq -r '.source // "unknown"' 2>/dev/null || printf 'unknown')"

# The roots are ENUMERATED, not derived. `$CLAUDE_PROJECT_DIR` is singular and this workspace has
# two repos, so deriving from it would cover whichever one the session was opened from and leave
# the other accumulating — the same shape as a glob that does not reach the second repo.
#
# `SCRATCH_ROOTS` is an INJECTED SEAM AND IT EXISTS FOR THE SUITE. A hook whose only targets are
# two absolute paths on one machine cannot be exercised without deleting the author's real files,
# and a delete nobody can test is the last thing this repo should ship.
#
# WHY THE SEAM IS CONTAINED, corrected. It used to say "nothing in the loop can set it", which is
# not established: the floor denies `Edit(.claude/**)` but leaves `Write` unrestricted, and `tee`,
# `cp`, `mv` and `sed` are all in `allow`. The real containment is in this script and is checkable:
# every entry has `/.scratch` APPENDED and must already exist as a directory, so even total control
# of the variable reaches only `<chosen>/.scratch` — never an arbitrary path, and never a directory
# that was not already a scratch.
ROOTS="${SCRATCH_ROOTS:-
/Users/tadeumen/git-reps/tadeumendonca-io
/Users/tadeumen/git-reps/tadeumendonca-skills
}"

case "$source_kind" in
  startup|clear) : ;;
  *)
    # Silent on `resume` and `compact`: those are the ordinary continuation of a session and a line
    # about them every time would be noise. Loud on anything else, because an unrecognised source
    # means this hook is no longer doing its job and nothing else would say so.
    case "$source_kind" in
      resume|compact) exit 0 ;;
    esac
    jq -n --arg s "$source_kind" '{
      hookSpecificOutput: {
        hookEventName: "SessionStart",
        additionalContext: ("Scratch was NOT swept: SessionStart reported source=\"" + $s + "\", which session-scratch.sh does not recognise as a new session. It sweeps only on `startup` and `clear`. Nothing was deleted — this is the safe direction — but the scratch will keep growing until the recognised set is corrected in hooks/scripts/session-scratch.sh.")
      }
    }'
    exit 0 ;;
esac

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

  # `-mindepth 1` does both jobs: it keeps the directory itself, so the next write does not have to
  # recreate it, and it stops the walk from reaching upward into tracked files. `find -delete`
  # rather than `rm -rf` for the first of those — `rm -rf` would take the directory with it. Both
  # halves are asserted; see the header for why the earlier permission-based reason was wrong.
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
