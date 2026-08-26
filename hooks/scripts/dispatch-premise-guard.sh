#!/usr/bin/env bash
# dispatch-premise-guard.sh — PreToolUse guard on the DISPATCH tool: a brief that stamps the state of a
# repository is checked against that repository before the subagent runs.
#
# ── WHAT THIS EXISTS FOR (#326) ────────────────────────────────────────────────────────────────
# Two leads were dispatched on a brief citing `architecture.en.md:132` and stamped "against `main` at
# `e92d62a`", while the working tree sat on `feat/persona-membership-drift-detector-431`. The citations
# had been measured on one tree and the stamp named another. ~210k tokens were spent reviewing copy that
# had already been corrected, and nothing in the loop could have said so — the premise of a dispatch was
# never an object anything read back. This is the same defect shape #329 recorded one layer up: a rule
# (here, a claim) that lives only in prose that nothing verifies.
#
# The guard is PREVENTIVE, not detective, and that is the whole reason it is worth building at this
# layer rather than as another end-of-turn report: it denies the dispatch, so the brief never runs and
# the tokens are never spent. An after-the-fact notice would arrive with the bill already paid.
#
# ── THE MATCHER IS `Agent`, AND `Task` WOULD HAVE BEEN INERT-BUT-WIRED-LOOKING — MEASURED ──────
# Probe/control, headless, one variable, against this machine's installed build:
#
#   matcher "Agent" + a real subagent dispatch  -> fired; payload captured, verbatim:
#       {"hook_event_name":"PreToolUse","tool_name":"Agent",
#        "tool_input":{"description":"Probe dispatch","prompt":"PROBE-NONCE-8Z4",
#                      "subagent_type":"probeagent"},
#        "cwd":"/Users/tadeumen/git-reps/tadeumendonca-skills","tool_use_id":"toolu_01Vexg…"}
#   matcher "Task"  + the identical dispatch    -> fired NOT ONCE; the log file stayed empty
#
# The trap the control exposes: a `matcher` is a REGEX, so `"Task"` still matches `TaskCreate` and would
# give you a hook that fires on todo-list writes and never on a dispatch — installed-looking and inert,
# this repo's named failure shape. The registration is asserted by this guard's own suite for exactly
# that reason.
#
# Two more properties of that payload decide the design below. The FULL BRIEF is in
# `.tool_input.prompt`, so the claim is readable at this layer at all. And `subagent_type` is present
# only when the model names a persona — it is ABSENT when it dispatches the default general-purpose
# agent — so a guard keyed on the persona would silently skip that whole class. This guard is keyed on
# the presence of a CLAIM, never on who is being dispatched, and the blind spot closes for free.
#
# ── WHAT IT CHECKS, AND THE BOUNDARY IS DECLARED RATHER THAN IMPLIED ───────────────────────────
# TWO claim forms, and nothing else:
#
#   form 1  <keyword> <branch> at <sha>     e.g. "against `main` at `e92d62a`"  — branch AND commit
#   form 2  <keyword> <sha>                 e.g. "commit: ccf0abd"              — commit only
#
# where <keyword> is one of: against · of (covers "as of") · at · on · commit · head · stamped ·
# premise. A <sha> is 7–40 hex characters CONTAINING AT LEAST ONE DIGIT — the digit requirement is what
# keeps English out (`defaced` is seven valid hex characters; a real abbreviated SHA without a digit has
# probability (6/16)^7 ≈ 0.13%, which is the false-NEGATIVE this deliberately accepts to buy a much
# larger reduction in false positives).
#
# **`file:line` citations are OUT OF SCOPE, by decision and not by omission.** Whether a file says what
# a brief claims it says is prose-reading; a guard that reached for it would fail open on the hard half
# and produce confident nonsense on the rest. A SHA is unambiguous and a branch name is a string
# comparison — this guard catches those and SAYS SO in its own deny text, because a control that catches
# half and names the half beats one that reaches for everything and cannot say what it missed.
#
# So passing this guard means the TREE is what the brief says, never that the LINES are.
#
# ── THE REPO IS RESOLVED FROM THE CITED PATH, NOT FROM `cwd` — THE OWNER'S CORRECTION ──────────
# The pre-implementation review proposed verifying against `git -C "$cwd"`. That would have checked the
# WRONG REPOSITORY on the night this exists for: `cwd` was `tadeumendonca-skills` and the brief cited
# `tadeumendonca-io` paths. A `cwd`-anchored guard catches the easy case and misses the real one.
#
# So: every path-shaped token in the brief is resolved to the repository that actually contains it, and
# the claim is verified THERE. `cwd`'s own repository is the fallback when the brief cites no path that
# resolves anywhere.
#
# NAMED LIMIT — the candidate set is a heuristic, and it is the weakest part of this guard. The payload
# carries `cwd` and nothing else about the workspace: the harness's additional working directories are
# NOT in it (measured, above). So the candidates are `cwd`'s own repository plus every sibling directory
# of it that is a git work tree — which is exactly right for this workspace's layout and would be wrong
# for a checkout somewhere else entirely. When that fails, it fails toward the fallback and the guard
# gets quieter, never louder.
#
# ── PASS-IF-ANY, WHICH IS THE PERMISSIVE DIRECTION ON PURPOSE ──────────────────────────────────
# A brief can cite paths that exist in more than one candidate (`README.md`, `CLAUDE.md`). A claim
# therefore passes if it holds in ANY resolved candidate, and is denied only if it holds in NONE. A
# false positive here BLOCKS A DISPATCH, which is the expensive direction; every ambiguity is resolved
# toward allowing.
#
# ── ACCEPTED FALSE POSITIVES, NAMED THE WAY RULES 8b AND 9 NAME THEIRS ─────────────────────────
#  1. A brief that deliberately cites a HISTORICAL commit after a keyword — "the defect landed at
#     `e441260`" — is denied, because the guard cannot tell a premise from a reference. This is the
#     largest one. It is loud, it names the token it refused, and rephrasing clears it.
#  2. A DETACHED HEAD makes the current branch read as `HEAD`, so a stamp naming a branch is denied.
#     Correct in spirit (the tree is not on the branch the brief claims) and annoying in practice.
#  3. A brief citing a bare filename that exists in several repositories widens the candidate set
#     rather than narrowing it — a false NEGATIVE, listed here because it is the same mechanism.
#  4. A claim whose SHA is genuinely HEAD but was measured on a tree with uncommitted changes passes.
#     This guard reads committed state only; it makes no claim about the working tree's cleanliness.
#
# Contract: receives the PreToolUse JSON on stdin; denies by printing a permissionDecision JSON and
# exiting 0. FAILS OPEN (allows) on a missing `jq`, a missing `git`, a missing `awk`, an unreadable
# payload, an empty prompt, a prompt carrying no claim, or a `cwd` outside any git tree — the same trade
# `permission-guard.sh` and `orchestrator-write-guard.sh` make, and for the same reason: a guard that
# wedges the loop cannot be repaired by the agent, because repairing it requires running commands.

set -uo pipefail

# Bounds. A brief can be tens of thousands of words; neither of these is a tuning knob, they are the
# degradation this guard prefers over an unbounded scan inside a 5-second PreToolUse budget.
MAX_CLAIMS=20
MAX_PATHS=12
MAX_CANDIDATES=24

input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

command -v jq >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0
command -v awk >/dev/null 2>&1 || exit 0

prompt="$(printf '%s' "$input" | jq -r '.tool_input.prompt // empty' 2>/dev/null || true)"
[ -z "$prompt" ] && exit 0

# ── the claims ────────────────────────────────────────────────────────────────────────────────
# Emitted as `branch<TAB>sha`, with `-` for form 2 (no branch named). Tokenising in awk rather than
# grepping: the idiom spans three or four tokens and may wrap across a line, and a token scanner is the
# portable way to say that without depending on which `grep` is installed.
claims="$(printf '%s' "$prompt" | awk '
  function clean(x) { sub(/[.,;:!?]+$/, "", x); return x }
  function issha(x) { return (x ~ /^[0-9a-fA-F]{7,40}$/ && x ~ /[0-9]/) }
  function isref(x) { return (x ~ /^[A-Za-z0-9][A-Za-z0-9._\/-]*$/ && length(x) <= 100 && !issha(x)) }
  # The apostrophe is scrubbed through a variable rather than named in the bracket expression: an
  # escape like \x27 is a gawk extension, and on the one-true-awk that ships with macOS it would be
  # read as the three literal characters x, 2 and 7 — silently mangling every token containing them.
  function scrub(s,   q) { gsub(/[`"(){}\[\],;*<>|]/, " ", s); q = sprintf("%c", 39); gsub(q, " ", s); return s }
  { buf = buf " " $0 }
  END {
    buf = scrub(buf)
    n = split(buf, t, /[[:space:]]+/)
    for (i = 1; i <= n; i++) {
      w = tolower(clean(t[i]))
      if (w != "against" && w != "of" && w != "at" && w != "on" && w != "commit" && w != "head" && w != "stamped" && w != "premise") continue
      a = clean(t[i+1]); b = tolower(clean(t[i+2])); c = clean(t[i+3])
      if (issha(a)) { print "-\t" tolower(a); continue }
      if (isref(a) && b == "at" && issha(c)) { print a "\t" tolower(c) }
    }
  }' 2>/dev/null | sort -u | head -n "$MAX_CLAIMS")"

[ -z "$claims" ] && exit 0

# A form-1 stamp ("against `main` at `abc1234`") also satisfies form 2 through its own `at` keyword, so
# the same SHA arrives twice — once bare, once with its branch. Drop the bare copy: the branched claim
# is strictly stronger (it checks everything the bare one does, plus the branch), and keeping both
# doubles every line of the deny text for no information. Found by running the suite, not by reading.
branched="$(printf '%s\n' "$claims" | awk -F'\t' '$1 != "-" { print $2 }' | sort -u)"
if [ -n "$branched" ]; then
  claims="$(printf '%s\n' "$claims" | awk -F'\t' -v b="$branched" '
    BEGIN { n = split(b, a, "\n"); for (i = 1; i <= n; i++) if (a[i] != "") s[a[i]] = 1 }
    !($1 == "-" && ($2 in s))')"
fi

# ── the cited paths ───────────────────────────────────────────────────────────────────────────
# A path-shaped token is one carrying a dot-extension. The `:NN` suffix is STRIPPED and then ignored —
# the line number is out of scope (see the header), but the file it hangs off is exactly what resolves
# the repository, which is why a `file:line` citation is useful here even though the line is not checked.
paths="$(printf '%s' "$prompt" | awk '
  function scrub(s,   q) { gsub(/[`"(){}\[\],;*<>|]/, " ", s); q = sprintf("%c", 39); gsub(q, " ", s); return s }
  { buf = buf " " $0 }
  END {
    buf = scrub(buf)
    n = split(buf, t, /[[:space:]]+/)
    for (i = 1; i <= n; i++) {
      x = t[i]
      sub(/:[0-9]+$/, "", x)
      sub(/[.,;:!?]+$/, "", x)
      if (x ~ /^[A-Za-z0-9_][A-Za-z0-9_.@\/-]*\.[A-Za-z0-9]+$/) print x
    }
  }' 2>/dev/null | sort -u | head -n "$MAX_PATHS")"

# ── the candidate repositories ────────────────────────────────────────────────────────────────
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
[ -z "$cwd" ] && exit 0
[ -d "$cwd" ] || exit 0

home_repo="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$home_repo" ] && exit 0

# ONE CANDIDATE PER REPOSITORY, NOT PER DIRECTORY — and this was found by running the guard, not by
# reading it. This workspace holds ~22 sibling directories that are all linked worktrees of the SAME
# repository, so a naive per-directory scan produced a 22-entry candidate set and, far worse, a
# pass-if-any rule that any stale worktree sitting at the stamped SHA would satisfy. The key is
# `git worktree list --porcelain`'s first line, which is the repository's MAIN worktree by definition.
#
# The representative for a repository is `cwd`'s own tree when `cwd` belongs to it, and the main
# worktree otherwise. NAMED LIMIT, and it is a false positive by construction: a brief that is genuinely
# about a LINKED worktree other than `cwd`'s is checked against the main one and denied. That is the
# loud direction, it is diagnosable from the deny text (which prints the tree it checked), and it is
# preferred over the silent direction, where a forgotten worktree vouches for a premise nobody measured.
repo_key() { git -C "$1" worktree list --porcelain 2>/dev/null | awk '/^worktree /{print substr($0, 10); exit}'; }

home_key="$(repo_key "$home_repo")"
[ -z "$home_key" ] && home_key="$home_repo"
candidates="$home_repo"
seen_keys="$home_key"
workspace="$(dirname "$home_repo")"
for entry in "$workspace"/*; do
  [ -d "$entry" ] || continue
  top="$(git -C "$entry" rev-parse --show-toplevel 2>/dev/null || true)"
  [ "$top" = "$entry" ] || continue
  key="$(repo_key "$entry")"
  [ -z "$key" ] && key="$entry"
  printf '%s\n' "$seen_keys" | grep -qxF "$key" && continue
  seen_keys="$seen_keys
$key"
  candidates="$candidates
$key"
done
candidates="$(printf '%s' "$candidates" | head -n "$MAX_CANDIDATES")"

# ── resolve the cited paths to the repositories that contain them ─────────────────────────────
# `git ls-files` covers the bare-filename case (`architecture.en.md`), which is the form the failure
# this guard exists for actually used — a citation with no directory component resolves against no
# repository root, so a `-e` test alone would have fallen straight through to the `cwd` fallback and
# reproduced the very bug the owner's correction is aimed at.
resolved=""
if [ -n "$paths" ]; then
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    case "$p" in /*) continue ;; esac
    while IFS= read -r r; do
      [ -z "$r" ] && continue
      hit=""
      if [ -e "$r/$p" ]; then
        hit=1
      else
        case "$p" in
          */*) : ;;
          *) [ -n "$(git -C "$r" ls-files -- "$p" "*/$p" 2>/dev/null | head -n 1)" ] && hit=1 ;;
        esac
      fi
      [ -n "$hit" ] && resolved="$resolved
$r"
    done <<< "$candidates"
  done <<< "$paths"
fi

resolved="$(printf '%s' "$resolved" | grep -v '^$' | sort -u || true)"
targets="$resolved"
target_source="the repositories containing the paths this brief cites"
if [ -z "$targets" ]; then
  targets="$home_repo"
  target_source="cwd's own repository (the brief cites no path that resolves anywhere, so there was nothing better to anchor on)"
fi

# ── verify ────────────────────────────────────────────────────────────────────────────────────
# A claim is evaluated as a UNIT per repository — branch and commit together — and passes overall if it
# holds in any target. Evaluating the two halves independently would let a mixed result read as a pass:
# the branch matching one repository and the commit another is precisely the state this guard exists to
# refuse.
failures=""
while IFS="$(printf '\t')" read -r branch sha; do
  [ -z "$sha" ] && continue
  passed=""
  detail=""
  while IFS= read -r r; do
    [ -z "$r" ] && continue
    if ! git -C "$r" cat-file -e "${sha}^{commit}" 2>/dev/null; then
      detail="$detail
      ${r}: no commit ${sha} in this repository"
      continue
    fi
    head_sha="$(git -C "$r" rev-parse HEAD 2>/dev/null || true)"
    head_sha="$(printf '%s' "$head_sha" | tr 'A-Z' 'a-z')"
    case "$head_sha" in
      "$sha"*) : ;;
      *) detail="$detail
      ${r}: HEAD is ${head_sha}, the brief stamps ${sha}"
         continue ;;
    esac
    if [ "$branch" != "-" ] && git -C "$r" rev-parse --verify --quiet "refs/heads/$branch" >/dev/null 2>&1; then
      cur="$(git -C "$r" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
      if [ "$cur" != "$branch" ]; then
        detail="$detail
      ${r}: the tree is on '${cur}', the brief stamps '${branch}'"
        continue
      fi
    fi
    passed=1
    break
  done <<< "$targets"
  [ -n "$passed" ] && continue
  if [ "$branch" = "-" ]; then
    failures="$failures
  claim: commit ${sha}${detail}"
  else
    failures="$failures
  claim: ${branch} at ${sha}${detail}"
  fi
done <<< "$claims"

[ -z "$failures" ] && exit 0

reason="Denied: this brief stamps a repository state that is not true right now, so the dispatch would
review the wrong tree.
${failures}

checked against ${target_source}:
$(printf '%s' "$targets" | sed 's/^/  /')

This is dispatch-premise-guard.sh (#326), a PreToolUse guard on the Agent (dispatch) tool. It exists
because two leads were once dispatched on a brief that cited one tree and stamped another; the review
ran to completion against copy that had already been corrected. Denying here is what makes that
preventable rather than merely reportable — the brief has not run and nothing has been spent.

WHAT THIS GUARD CHECKS, AND WHAT IT DELIBERATELY DOES NOT. It verifies exactly two things: that a
commit named as the brief's premise is HEAD of the repository the brief's own citations resolve to, and
that a branch named alongside it is the branch that repository is actually on. It does NOT verify
file:line citations, and never will — whether a file says what a brief claims it says is prose-reading,
and a control that catches half and names the half is worth more than one that reaches for everything
and cannot say what it missed. So passing this guard means the TREE is what the brief says. It means
nothing about whether the lines are.

TO CLEAR IT: re-measure the citations against the tree you are actually dispatching about and re-stamp
the brief, or check out the state the brief describes. If the SHA is a deliberate reference to a
historical commit rather than the brief's premise, this is a known false positive of the keyword scan —
rephrase so the SHA does not follow against/at/on/of/commit/head/stamped/premise, and say in the brief
that you did."

jq -n --arg r "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $r
  }
}'
exit 0
