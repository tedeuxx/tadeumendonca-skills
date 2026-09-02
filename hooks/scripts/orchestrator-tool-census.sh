#!/usr/bin/env bash
# purpose: report at the end of a turn what the orchestrator did with its own hands, so the delegation habits nothing mechanises stay observable and therefore correctable
# orchestrator-tool-census.sh — Stop hook: at the end of a turn, tell the owner WHAT the orchestrator
# did with its own hands this session, as a named list, with the write/post class separated from the
# reads.
#
# ── WHAT THIS EXISTS FOR (#319), AND WHAT IT INHERITED (#375) ──────────────────────────────────
# ~~`orchestrator-write-guard.sh` (PreToolUse) closes the one class where the act is unambiguous and the
# delegation target exists: editing a file inside a git tree.~~ **STRUCK 2026-08-31 (#375): that hook is
# DELETED, on the owner's ruling that it was a contingency rather than a design. So this file is no
# longer half of a pair — it is the WHOLE of the mechanical half, and it fires at `Stop`, after the act.
# Nothing refuses a main-context edit any more. The replacement is `scrum-master`'s selection record,
# which names who should act before acting: detection, not prevention, and self-attested, since the
# orchestrator lands the record itself. Read every "this is the observation half" claim below with that
# in mind — there is no refusal half behind it now.** Everything else the #319 review looked at
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
# `Bash`-side write routes that were never blocked (`sed -i`, `tee`) — and since #375 deleted
# `orchestrator-write-guard.sh`, the `Edit`/`Write` tool routes are not blocked either. Not blocked, but
# not invisible: this census is now the only observer of both classes, and #371 measured how imperfect
# an observer it was — see the block below. Read the `?` class as the standing admission that it still
# is one, just not silently.
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
# `git -C <dir>` used to be stripped as a one-off special case, for the same reason on the other side:
# unstripped, 53 distinct git reads collapsed to one useless label `Bash: git -C`, and every git WRITE
# spelled with `-C` — which is this repo's own mandated spelling (`shell`) — would have been classified
# by that same non-label and missed. **That strip was right and far too narrow (#371).**
#
# ── WHAT #371 MEASURED, AND WHY THE OBVIOUS FIX WAS DEAD ON ARRIVAL ────────────────────────────
# Probed against this hook with a real Stop payload, threshold lowered so the notice would print. Every
# one of these is a MUTATION, and every one landed in the READ list:
#
#   git -c user.name=x commit -m y             ->  Bash: git -c                          R
#   git --git-dir=/tmp/r/.git commit -m y      ->  Bash: git --git-dir=/tmp/r/.git       R
#   gh --repo o/r issue comment 1 --body-file  ->  Bash: gh --repo o/r                   R
#   env -C <dir> claude plugin update …        ->  Bash: env                             R
#   gh api repos/<owner>/<repo>/contents/…     ->  Bash: gh api repos/<owner>/…          R, unbounded label
#
# The motivating incident was the fourth: a `claude plugin update` that rewrote which build every
# project resolves, reported as a read. **And adding `claude plugin update` to the W list below fixes
# nothing on its own** — that string is never produced, because the label came off `env`. The wrapper
# strip must land FIRST or the W list is decoration. The `gh --repo` spelling is the sharper one: it is
# the orchestrator's most common write, and `command-hygiene` already documents that this flag position
# breaks the PERMISSION prefix matcher. Nobody had noticed it breaks the census identically.
#
# ── WHY A PER-TOOL LIST OF MUTATING SUBCOMMANDS IS NOT THE SHAPE, AND `?` IS ───────────────────
# The first token of every `Bash(...)` allow pattern across all six settings files in this workspace
# resolves to **61 distinct programs** (plus 2 absolute script paths, counted separately because they
# are not programs), of which exactly two — `gh` and `git` — got a multi-word label before this change
# and three do after it. Re-derived at head on 2026-09-01, with the six files NAMED rather than elided,
# because a placeholder is not a runnable command and this repo's rule is inline-and-runnable or not at
# all:
#
#   jq -r '.permissions.allow[]? // empty' \
#     ~/.claude/settings.json ~/.claude/settings.local.json \
#     <workspace>/tadeumendonca-io/.claude/settings.json \
#     <workspace>/tadeumendonca-io/.claude/settings.local.json \
#     <workspace>/tadeumendonca-skills/.claude/settings.json \
#     <workspace>/tadeumendonca-skills/.claude/settings.local.json \
#     | grep '^Bash(' | sed 's/^Bash(//; s/[:)].*$//' | awk '{print $1}' | sort -u | grep -v '^/'
#
# FOUR OF THOSE SIX FILES ARE OUTSIDE EVERY REPOSITORY, not two. Both `~/.claude/*` live in the home
# directory and in no repo at all, and both `settings.local.json` are untracked — measured with
# `git ls-files --error-unmatch`, which answers "did not match any file(s) known to git" for each.
#
# **FROM THE TWO TRACKED FILES ALONE, THE SAME PIPELINE YIELDS 57** — the exact number #371's intake
# published and this file corrects. Publishing 61 without that line manufactures a contradiction: a
# reader re-deriving from what a clone can reach lands on 57, reads 57 called an erratum, and concludes
# the correction was the error. The four programs that exist ONLY outside every repository are `brew`,
# `claude`, `file` and `open` — and `claude`, the program at the centre of this hook's own motivating
# incident, comes from an untracked overlay.
#
# THE DRIFT IS THE ARGUMENT, NOT AN ERRATUM. Four programs entered the allowlists in one day and this
# hook read none of it. A number that moves by four overnight, sourced mostly from files no repository
# holds, is not a list anyone maintains by hand in a second file. **And the argument survives the
# imprecision** — *the list is unbounded and it moves* holds at 57 and at 61 — which is why the figure
# is published with its disclosure rather than withdrawn.
# So "which other programs hide a mutating subcommand" is not a list of seven; it is everything except
# two. `bump-my-version bump patch` writes two files, commits AND tags. `npm publish`, `npx`, `node`,
# `python3`, `bash`, `terraform init`, `aws <any verb>`, `awk 'print > "f"'`, `find -delete`, `curl -o`
# are all reachable and all reported as reads. A hand-maintained list would have to be extended every
# time a program is added to any of the SIX settings files named above — the derivation set and the
# maintenance set are the same six — by someone who remembers this hook exists. That is the maintenance
# profile of a matcher list, not of a classifier.
#
# So a THIRD class exists: `?`, meaning **not recognised**, not measured-as-a-read. Before it, `R` was
# the default and a reader could not tell the two apart; every future gap was something the next person
# found by accident. Now every gap is something the owner can SEE. **The cost, stated rather than
# discovered:** the notice is longer, and `?` holds genuine readers until they are listed. It is bounded
# by an explicit R list of obvious readers below — and `?` deliberately does NOT trigger the notice, so
# a turn holding only unclassified calls stays silent exactly as it did before.
#
# ── WHAT IS DELIBERATELY UNCHANGED ────────────────────────────────────────────────────────────
# The explicit-list-over-heuristic decision stands, on its own 916-call evidence above. Nothing here
# argues for going back to substring matching: the argument is that the COVERAGE is unbounded, not that
# the MATCHING is wrong, and only the second was ever the defect.
#
# And `classify()` remains a second, weaker classifier over the same command strings
# `permission-guard.sh` already classifies. **They must not be merged** — the guard is a fail-closed
# floor, this is a fail-open reporter, and coupling them would give the floor a reason to change every
# time the report gains a label. The mitigation is review discipline, not machinery: **when a program is
# added to any allowlist, both files are the checklist.**

# Drop leading shell wrappers, `VAR=value` assignments and options from a command string, so what is
# left begins with the thing that actually acts. Options that take a SEPARATE argument are enumerated
# rather than guessed: a generic "skip the next token too" rule eats the subcommand out of
# `git --no-pager log`, and a rule that only ever skips one token leaves `o/r` sitting where `issue`
# should be. Both failures are silent, which is why the set is written down.
strip_lead() { # command -> command with wrappers/assignments/leading options removed
  # NORMALISE WHITESPACE FIRST. `${c%% *}` and `${c#* }` split on ONE space, so `gh  --repo o/r pr
  # comment` (two spaces, a shape a human types) left `--repo` unstripped and the label came out as
  # `gh --repo o/r`. That degraded into `?` rather than into a false read — an admission, not an
  # assertion — so it was a usefulness defect and not a correctness one, and it is fixed with the same
  # `awk` call the label already makes at the end of `classify()`. Tabs and backslash-continuations
  # were probed and were already handled correctly; only runs of spaces were not.
  local c rest first guard=0
  c="$(printf '%s' "$1" | awk '{$1=$1; print}')"
  while [ "$guard" -lt 12 ]; do
    guard=$((guard + 1))
    [ -z "$c" ] && break
    first="${c%% *}"
    case "$c" in *' '*) rest="${c#* }" ;; *) rest="" ;; esac
    case "$first" in
      env|sudo|time|nohup|command|xargs) c="$rest"; continue ;;
      -C|-c|--repo|-R|--git-dir|--work-tree|--namespace|--exec-path)
        # takes a separate argument: drop the option AND its value
        case "$rest" in *' '*) c="${rest#* }" ;; *) c="" ;; esac
        continue ;;
      -*)   c="$rest"; continue ;;
      *=*)  c="$rest"; continue ;;   # `env VAR=x cmd` leaves the assignment as the first token
    esac
    break
  done
  printf '%s' "$c"
}

classify() { # name · command  ->  "W<TAB>label" | "R<TAB>label" | "?<TAB>label"
  local name="$1" cmd="$2" label class prog rest
  case "$name" in
    Write|Edit|MultiEdit|NotebookEdit) printf 'W\t%s\n' "$name"; return ;;
    Bash) : ;;
    # The tool names are a bounded set the harness stamps, so the readers are enumerable — but an
    # UNKNOWN tool name is exactly the case `?` exists for. A new write-capable tool silently landing
    # in R would be this file's own defect one layer up.
    Read|Grep|Glob|Task|Agent|TodoWrite|WebFetch|WebSearch|BashOutput|KillShell|\
    SlashCommand|ExitPlanMode|NotebookRead|ListMcpResources|ReadMcpResource)
      printf 'R\t%s\n' "$name"; return ;;
    *) printf '?\t%s\n' "$name"; return ;;
  esac

  cmd="$(strip_lead "$cmd")"
  prog="${cmd%% *}"
  case "$cmd" in *' '*) rest="${cmd#* }" ;; *) rest="" ;; esac

  # Only these three carry a subcommand vocabulary worth labelling, so only these three get their
  # options stripped a second time — between the program name and the subcommand.
  case "$prog" in
    git|gh|claude) rest="$(strip_lead "$rest")" ;;
  esac

  case "$prog" in
    gh)
      case "$rest" in
        # `gh api <endpoint>` takes a URL path as its third word, so the three-word rule produced one
        # label per endpoint and no W entry could ever match it. Capped at two words. It stays
        # UNCLASSIFIED rather than R: `gh api -X POST` writes, and nothing in a label can tell.
        api*) label="gh api" ;;
        *)    label="gh $(printf '%s' "$rest" | awk '{print $1, $2}')" ;;
      esac ;;
    git)    label="git $(printf '%s' "$rest" | awk '{print $1}')" ;;
    claude) label="claude $(printf '%s' "$rest" | awk '{print $1, $2}')" ;;
    *)      label="$prog" ;;
  esac
  # awk prints a trailing separator when a field is missing; a label must not end in whitespace or the
  # `case` patterns below stop matching.
  label="$(printf '%s' "$label" | awk '{$1=$1; print}')"

  class='?'
  case "$label" in
    # ── W: the write/post class ──────────────────────────────────────────────────────────────
    "gh pr comment"|"gh issue comment"|"gh pr create"|"gh issue create"|\
    "gh pr edit"|"gh issue edit"|"gh issue close"|"gh pr close"|\
    "gh pr merge"|"gh pr ready"|"gh label create"|"gh label edit"|"gh label delete"|\
    "gh release create"|"gh release delete"|"gh secret set"|"gh secret delete"|\
    "gh workflow run"|"gh repo delete")
      class=W ;;
    "git commit"|"git push"|"git add"|"git merge"|"git rebase"|"git reset"|\
    "git rm"|"git mv"|"git tag"|"git cherry-pick"|"git restore"|"git stash")
      class=W ;;
    # The motivating case (#371): it rewrites the install registry, which decides which briefs and
    # hooks every project runs. Reachable for the first time now that the wrapper strip lands first.
    "claude plugin install"|"claude plugin update"|"claude plugin uninstall"|\
    "claude plugin enable"|"claude plugin disable"|"claude plugin marketplace")
      class=W ;;
    tee|mv|cp|rm|chmod|touch|mkdir|rsync|patch)
      class=W ;;
    sed)
      # IN-PLACE ONLY; a `sed -n` read is not a write. BOTH SPELLINGS, and the second one was a
      # measured defect rather than a precaution: `*" -i"*` does not contain `" --in-place"`, so
      # `sed --in-place s/a/b/ <file>` was classified `R` — a mutation POSITIVELY CLAIMED as a read,
      # which is worse than the `?` class it would otherwise have fallen into. `?` is an admission;
      # `R` is an assertion, and this is the one arm in this function that asserts.
      #
      # PLATFORM CAVEAT, because the defect is unreachable on the machine that found it: BSD `sed`
      # rejects the long form outright (`sed: illegal option -- -`), so this fires only where `sed` is
      # GNU-shaped — every Linux runner, and this repo's own CI. A classifier that is correct on one
      # platform and wrong on another should say which, rather than being green where it is tested.
      case " $cmd " in *" -i"*|*" --in-place"*) class=W ;; *) class=R ;; esac ;;
    # ── R: the explicit readers, which is what keeps `?` from filling with noise ──────────────
    # Bounded on purpose. A subcommand that is not listed here lands in `?`, which is the honest
    # answer for `git config` (writes with `--global`), `git checkout`, `git fetch` and `git clone`.
    "git status"|"git log"|"git diff"|"git show"|"git rev-parse"|"git branch"|"git remote"|\
    "git ls-files"|"git ls-remote"|"git ls-tree"|"git merge-base"|"git describe"|"git blame"|\
    "git shortlog"|"git cat-file"|"git for-each-ref"|"git grep"|"git rev-list"|"git symbolic-ref"|\
    "git check-ignore"|"git name-rev"|"git version")
      class=R ;;
    "gh pr view"|"gh pr list"|"gh pr diff"|"gh pr checks"|"gh pr status"|\
    "gh issue view"|"gh issue list"|"gh issue status"|\
    "gh run view"|"gh run list"|"gh run watch"|"gh release view"|"gh release list"|\
    "gh label list"|"gh repo view"|"gh repo list"|"gh workflow view"|"gh workflow list"|\
    "gh secret list"|"gh auth status"|"gh search")
      class=R ;;
    "claude plugin list"|"claude plugin details"|"claude plugin validate"|"claude --version")
      class=R ;;
    grep|cat|ls|head|tail|wc|sort|uniq|jq|diff|find|rg|which|realpath|basename|dirname|\
    test|date|echo|printf|pwd|stat|file|column|tr|cut|nl|comm|md5|shasum|true|false)
      class=R ;;
  esac
  printf '%s\tBash: %s\n' "$class" "$label"
}

classified="$(printf '%s\n' "$calls" | while IFS="$(printf '\t')" read -r name cmd; do
  [ -z "$name" ] && continue
  classify "$name" "$cmd"
done)"

write_labels="$(printf '%s\n' "$classified" | awk -F'\t' '$1=="W" && $2!="" {print $2}')"
read_labels="$(printf '%s\n' "$classified" | awk -F'\t' '$1=="R" && $2!="" {print $2}')"
unknown_labels="$(printf '%s\n' "$classified" | awk -F'\t' '$1=="?" && $2!="" {print $2}')"

write_count="$(printf '%s\n' "$write_labels" | grep -c . || true)"
read_count="$(printf '%s\n' "$read_labels" | grep -c . || true)"
unknown_count="$(printf '%s\n' "$unknown_labels" | grep -c . || true)"
[ -z "$write_count" ] && write_count=0
[ -z "$read_count" ] && read_count=0
[ -z "$unknown_count" ] && unknown_count=0

# ── threshold + debounce, both checked before anything is emitted ───────────────────────────────
last=0
if [ -f "$state_file" ]; then
  last="$(cat "$state_file" 2>/dev/null || echo 0)"
  case "$last" in ''|*[!0-9]*) last=0 ;; esac
fi
[ "$write_count" -lt $((last + CENSUS_THRESHOLD)) ] && exit 0

tally() { printf '%s\n' "$1" | grep . | sort | uniq -c | sort -rn | awk '{c=$1; $1=""; sub(/^ /,""); printf "  %s x%s\n", $0, c}'; }

unknown_block=""
if [ "$unknown_count" -gt 0 ]; then
  unknown_block="
unclassified (${unknown_count}) — NOT measured as reads:
$(tally "$unknown_labels")"
fi

context="Orchestrator tool census — ${write_count} write/post, ${read_count} read, ${unknown_count} unclassified, this session.

write/post (${write_count}):
$(tally "$write_labels")
read (${read_count}):
$(tally "$read_labels")${unknown_block}

This is orchestrator-tool-census.sh (#319), a Stop hook. It GATES NOTHING and decides nothing — it
reports what the main agent did with its own hands. A subagent's calls are not in this list; a
dispatch appears only as 'Agent'.

Three things to know before reading the numbers. It counts ATTEMPTS: a call a guard denied still
appears here. The write/post class is the only one that can trigger this notice — it fires again
only after ${CENSUS_THRESHOLD} more write/post calls in this session, and an unclassified call
triggers nothing at all. And the third class means what it says (#371): 'unclassified' is NOT
'measured as a read'. No first-N-words rule can tell 'node scripts/read.js' from
'node scripts/write.js', and the programs reachable from this workspace's allowlists outnumber the
handful that carry a subcommand label by more than twenty to one — so the honest report of the
remainder is that it was not recognised. If something in that block mutates anything, it belongs in
this hook's W list.

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
