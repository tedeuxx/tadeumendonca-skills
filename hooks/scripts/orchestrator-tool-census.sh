#!/usr/bin/env bash
# orchestrator-tool-census.sh — Stop hook: at the end of a turn, tell the owner WHAT the orchestrator
# did with its own hands this session, as a named list, with the write/post class separated from the
# reads.
#
# ── WHAT THIS EXISTS FOR (#319) ─────────────────────────────────────────────────────────────────
# `orchestrator-write-guard.sh` (PreToolUse) closes the one class where the act is unambiguous and the
# delegation target exists: editing a file inside a git tree. Everything else the #319 review looked at
# — reads, `gh issue create`, the `gh pr comment` / `gh issue comment` routes rule 5e ALLOWS the
# orchestrator — is deliberately NOT mechanised, and this hook is the reason that decision is
# affordable. A hook sees `grep` and a path, never whether the answer was already in a subagent's
# return; it cannot tell a justified read from a lazy one. So that half stays a HABIT, and a habit with
# no observation is a habit nobody can correct. This makes the shape of a session visible without
# deciding anything about it.
#
# ── THIS GATES NOTHING. IT CANNOT. ─────────────────────────────────────────────────────────────
# Every exit path is `exit 0`; the only mechanism used is `additionalContext`; no `decision` field is
# ever emitted and this script never exits 2. A `Stop` hook fires after the work already happened —
# there is nothing left to prevent. Read the notice as an instrument reading, never as a verdict, and
# never as a reason to redo the turn.
#
# ── THE TWO COSTS THE MECHANISM ARRIVES WITH, AND WHAT IS DONE ABOUT EACH ──────────────────────
# 1. IT COUNTS ATTEMPTS, NOT EFFECTS. Measured on #319: a `Write` denied by a PreToolUse hook still
#    appears in the transcript as a `tool_use`, so it is still counted here. There is no fix — the
#    transcript records the call, not its outcome, and the outcome lands in a separate `tool_result`
#    the model may or may not have acted on. What is done instead is to SAY SO, in the notice itself,
#    every time. A number the reader can calibrate beats a number that is quietly wrong.
# 2. IT FIRES EVERY TURN. Unhandled, that is noise the owner learns to skip within a week — the exact
#    failure `zombie-loop-detect.sh` debounces against. Two things bound it here: only the WRITE/POST
#    class can trigger a notice (a read-heavy turn is silent no matter how many reads it holds), and
#    the notice fires only when that class has grown by CENSUS_THRESHOLD since the last notice in this
#    session. So the first notice needs 3 write/post calls, the second needs 3 MORE, and a turn that
#    adds none is silent. The read list is still PRINTED when a notice fires — it is context for the
#    write count, not a trigger of its own.
#
# ── WHY THE TRANSCRIPT IS THE RIGHT SOURCE, AND WHAT IT CORRECTLY EXCLUDES ─────────────────────
# Measured on #319, control against probe: `transcript_path` holds the MAIN agent's own turns. A
# subagent's tool calls do not appear in it; the dispatch appears as a single `Agent` entry. So this
# census is the orchestrator's own hands by construction — no filtering needed, and no risk of
# reporting the builder's edits as the orchestrator's. The extraction is the one the #319 review
# measured, widened by one field so a `Bash` call can be classified by what it actually ran:
#   jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | .name'
#
# ── WHY `Bash` IS CLASSIFIED BY ITS COMMAND AND NOT LEFT AS ONE BUCKET ─────────────────────────
# The complaint on #319 was about posting — `gh issue comment`, `gh pr comment` — and every one of
# those is a `Bash` call. A census that reported "Bash x31" would have an EMPTY post class by
# construction, and would have been unable to see the thing it was built to see. It also picks up the
# `Bash`-side write routes `orchestrator-write-guard.sh` deliberately does not block (`sed -i`, `tee`):
# not blocked, but not invisible either.
#
# ── WHERE THE DEBOUNCE STATE LIVES ─────────────────────────────────────────────────────────────
# Under the checkout's own `.git/` directory, keyed by `session_id` — the same choice, for the same
# three reasons, as `zombie-loop-detect.sh`: never git-tracked so it cannot leak into a diff, already
# scoped to this checkout, and resolved correctly under a `git worktree`. A hook subprocess is not
# handed the session scratchpad path, so that is not an option here. NO GIT DIR, NO CENSUS: without a
# place to hold the debounce this hook would notify every turn, which is the failure mode it is built
# to avoid — so it stays silent instead.
#
# Contract: receives the Stop event JSON on stdin (`transcript_path`, `session_id`, `cwd`,
# `stop_hook_active`); prints Stop hookSpecificOutput carrying `additionalContext` when a notice is
# due, and exits 0 either way. Silent on any error — no `jq`, no transcript, no git dir, an unreadable
# payload. `stop_hook_active` is honoured (exit before any work) even though this hook never blocks and
# so cannot itself trip the 8-blocks breaker.

set -uo pipefail

CENSUS_THRESHOLD=3

input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

command -v jq >/dev/null 2>&1 || exit 0

stop_hook_active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || true)"
[ "$stop_hook_active" = "true" ] && exit 0

transcript="$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null || true)"
[ -z "$transcript" ] && exit 0
[ -f "$transcript" ] || exit 0

session_id="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
[ -z "$cwd" ] && exit 0
[ -d "$cwd" ] || exit 0

command -v git >/dev/null 2>&1 || exit 0
git_dir="$(git -C "$cwd" rev-parse --git-dir 2>/dev/null || true)"
[ -z "$git_dir" ] && exit 0
case "$git_dir" in
  /*) : ;;
  *)  git_dir="$cwd/$git_dir" ;;
esac
state_dir="$git_dir/orchestrator-tool-census"
mkdir -p "$state_dir" 2>/dev/null || true
state_file="$state_dir/${session_id:-nosession}"

# ── the census: one line per tool_use, tab-separated name and (for Bash) its command ────────────
calls="$(jq -r '
  select(.type=="assistant")
  | .message.content[]?
  | select(.type=="tool_use")
  | [ (.name // "?"), ((.input.command // "") | gsub("[\n\t]"; " ")) ]
  | @tsv' "$transcript" 2>/dev/null || true)"
[ -z "$calls" ] && exit 0

# ── classification ──────────────────────────────────────────────────────────────────────────────
# W = the write/post class (this is what can trigger a notice). R = everything else.
# The label is what the reader sees: a bare tool name, or `Bash: <the first words that identify the
# act>` — enough to tell `gh issue comment` from `gh issue view` without echoing an argument list.
#
# CLASSIFY THE LABEL, NEVER THE WHOLE COMMAND STRING — measured, and it is the difference between an
# instrument and a rumour. The first form of this function matched substrings anywhere in the command;
# run against a real 916-call transcript it classified a `cat` heredoc as a write because the heredoc
# BODY happened to contain one of the mutating words, and `gh release view` as a post because
# `gh release` matched. Both are reads. A census that miscounts the class it exists to report teaches
# the owner to distrust it, which costs more than the census buys.
#
# `git -C <dir>` is stripped first, for the same reason on the other side: unstripped, 53 distinct git
# reads collapsed to one useless label `Bash: git -C`, and every git WRITE spelled with `-C` — which is
# this repo's own mandated spelling (`command-hygiene`) — would have been classified by that same
# non-label and missed.
classify() { # name · command  ->  "W<TAB>label" | "R<TAB>label"
  local name="$1" cmd="$2" label class
  case "$name" in
    Write|Edit|MultiEdit|NotebookEdit) printf 'W\t%s\n' "$name"; return ;;
    Bash) : ;;
    *) printf 'R\t%s\n' "$name"; return ;;
  esac

  # `git -C <dir> <subcommand>` -> `git <subcommand>`, so the label names the ACT.
  case "$cmd" in
    "git -C "*) cmd="git $(printf '%s' "$cmd" | awk '{$1=""; $2=""; $3=""; sub(/^ +/,""); print}')" ;;
  esac

  case "$cmd" in
    gh\ *)  label="$(printf '%s' "$cmd" | awk '{print $1, $2, $3}')" ;;
    git\ *) label="$(printf '%s' "$cmd" | awk '{print $1, $2}')" ;;
    *)      label="$(printf '%s' "$cmd" | awk '{print $1}')" ;;
  esac

  class=R
  case "$label" in
    "gh pr comment"|"gh issue comment"|"gh pr create"|"gh issue create"|\
    "gh pr edit"|"gh issue edit"|"gh issue close"|"gh pr close"|\
    "gh pr merge"|"gh pr ready"|"gh label create"|"gh label edit"|"gh label delete"|\
    "gh release create"|"gh release delete"|"gh secret set"|"gh secret delete"|\
    "gh workflow run"|"gh repo delete")
      class=W ;;
    "git commit"|"git push"|"git add"|"git merge"|"git rebase"|"git reset"|\
    "git rm"|"git mv"|"git tag"|"git cherry-pick"|"git restore"|"git stash")
      class=W ;;
    tee|mv|cp|rm|chmod|touch|mkdir|rsync|patch)
      class=W ;;
    sed)
      # in-place only; a `sed -n` read is not a write
      case " $cmd " in *" -i"*) class=W ;; esac ;;
  esac
  printf '%s\tBash: %s\n' "$class" "$label"
}

classified="$(printf '%s\n' "$calls" | while IFS="$(printf '\t')" read -r name cmd; do
  [ -z "$name" ] && continue
  classify "$name" "$cmd"
done)"

write_labels="$(printf '%s\n' "$classified" | awk -F'\t' '$1=="W" && $2!="" {print $2}')"
read_labels="$(printf '%s\n' "$classified" | awk -F'\t' '$1=="R" && $2!="" {print $2}')"

write_count="$(printf '%s\n' "$write_labels" | grep -c . || true)"
read_count="$(printf '%s\n' "$read_labels" | grep -c . || true)"
[ -z "$write_count" ] && write_count=0
[ -z "$read_count" ] && read_count=0

# ── threshold + debounce, both checked before anything is emitted ───────────────────────────────
last=0
if [ -f "$state_file" ]; then
  last="$(cat "$state_file" 2>/dev/null || echo 0)"
  case "$last" in ''|*[!0-9]*) last=0 ;; esac
fi
[ "$write_count" -lt $((last + CENSUS_THRESHOLD)) ] && exit 0

tally() { printf '%s\n' "$1" | grep . | sort | uniq -c | sort -rn | awk '{c=$1; $1=""; sub(/^ /,""); printf "  %s x%s\n", $0, c}'; }

context="Orchestrator tool census — ${write_count} write/post, ${read_count} read, this session.

write/post (${write_count}):
$(tally "$write_labels")
read (${read_count}):
$(tally "$read_labels")

This is orchestrator-tool-census.sh (#319), a Stop hook. It GATES NOTHING and decides nothing — it
reports what the main agent did with its own hands. A subagent's calls are not in this list; a
dispatch appears only as 'Agent'.

Two things to know before reading the numbers. It counts ATTEMPTS: a call a guard denied still
appears here. And the write/post class is the only one that can trigger this notice — it fires again
only after ${CENSUS_THRESHOLD} more write/post calls in this session.

If the write/post list holds work a persona owns, that work was done in the wrong layer: dispatch
next time. Reads and the comment routes rule 5e allows are a HABIT, not a rule — nothing here forbids
them, and nothing will."

printf '%s' "$write_count" > "$state_file" 2>/dev/null || true

jq -n --arg c "$context" '{
  hookSpecificOutput: {
    hookEventName: "Stop",
    additionalContext: $c
  }
}'
exit 0
