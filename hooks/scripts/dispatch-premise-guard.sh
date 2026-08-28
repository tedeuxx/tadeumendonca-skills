#!/usr/bin/env bash
# purpose: refuse a dispatch whose brief stamps a repository state that repository does not have, so a subagent never spends a whole context reviewing a premise that was already false
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
# ONE claim form, and nothing else:
#
#   <keyword> <ref> at <sha>     e.g. "against `main` at `e92d62a`"
#
# where <keyword> is one of: against · of (covers "as of") · at · on · commit · head · stamped ·
# premise; <sha> is 7–40 hex characters CONTAINING AT LEAST ONE DIGIT (the digit requirement keeps
# English out — `defaced` is seven valid hex characters); and <ref> MUST RESOLVE as a branch or a
# remote-tracking ref in the target repository, or there is no claim.
#
# A BARE SHA IS NOT A CLAIM. The first version of this guard accepted one and it was wrong at a rate
# nobody guessed: 41.2% of 859 real briefs evaluated, 8.0% guaranteed at least one denial whatever the
# tree was. The full measurement, and the reason a bare SHA is a REFERENCE rather than a premise, is at
# the claims scanner below — read it before widening this back.
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
# ── ONE TARGET, OR NONE — AMBIGUITY FAILS OPEN ─────────────────────────────────────────────────
# The stamp is attributed to a single repository, using only citations that DISTINGUISH one (a path
# present in several repositories attributes nothing and is dropped). If the distinguishing citations
# name two or more repositories, the brief spans repositories and carries one stamp: there is no fact
# available that says which one it is about, so nothing is checked. A guess reported as a control is
# worse than a declared gap.
#
# ── ACCEPTED FALSE POSITIVES, NAMED THE WAY RULES 8b AND 9 NAME THEIRS ─────────────────────────
#  1. A DETACHED HEAD makes the current branch read as `HEAD`, so a local-branch stamp is denied.
#     Correct in spirit (the tree is not on the branch the brief claims) and annoying in practice.
#  2. A stale remote-tracking ref — never fetched since someone else pushed — makes a correct
#     `origin/main at <sha>` stamp read as false. Single-owner workspace, so low; real elsewhere.
#  3. A brief genuinely about a LINKED worktree other than `cwd`'s is checked against the repository's
#     main worktree and denied. Loud and diagnosable from the deny text, which prints the tree it read.
#
# ── ACCEPTED FALSE NEGATIVES, WHICH ARE THE PRICE OF THE ABOVE AND ARE LARGER ──────────────────
#  4. A CROSS-REPOSITORY brief is not checked at all (ambiguous attribution, above). This is the
#     largest gap and it is deliberate: the incident this guard exists for cited ONE repository's
#     paths, which is why narrowing here does not cost the case it was built for.
#  5. A bare SHA is never checked, so a brief whose only premise is "at `abc1234`" passes. That is the
#     trade the corpus measurement bought — see the claims scanner.
#  6. A claim whose SHA is genuinely HEAD but was measured on a tree with uncommitted changes passes.
#     This guard reads committed state only; it says nothing about the working tree's cleanliness.
#  7. A real abbreviated SHA containing no digit at all is not recognised (probability (6/16)^7 ≈ 0.13%).
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
# ONE claim form, emitted as `ref<TAB>sha` from the idiom `<keyword> <ref> at <sha>` — "against `main`
# at `e92d62a`". Tokenising in awk rather than grepping: the idiom spans four tokens and may wrap
# across a line, and a token scanner says that without depending on which `grep` is installed.
#
# A BARE SHA IS NOT A PREMISE, AND MEASURING THAT IS WHAT CORRECTED THIS GRAMMAR (#326 review).
# The first version also accepted a bare SHA after a keyword ("commit: abc1234"). Re-run over the
# gate's own corpus — 859 unique real dispatch briefs from this repo's transcripts:
#
#   grammar                                 briefs evaluated   >=2 distinct SHAs = guaranteed deny
#   bare SHA + ref-and-SHA  (first version)   354  (41.2%)          69  (8.0%)
#   ref-and-SHA only                           11  ( 1.3%)           0  (0.0%)
#   ref-and-SHA, ref must RESOLVE (this)        9  ( 1.0%)           0  (0.0%)
#
# Two distinct SHAs cannot both be HEAD, so every brief in that 8.0% had at least one claim denied
# whatever the tree was — and carrying two SHAs is not a mistake, it is the NORMAL shape of a review
# brief, which names a merge-base and a head. The whole failing class was bare SHAs, because a bare SHA
# is a REFERENCE (a merge-base, a PR head, a verdict marker, a historical commit) and a reference is
# not a claim about the tree you are standing in. A premise says WHERE YOU ARE: a ref and the commit it
# is at, together. That is not a tuned threshold — it is what the word means.
#
# THE REF MUST RESOLVE IN THE TARGET REPOSITORY, WHICH IS A REPOSITORY FACT RATHER THAN A GUESS.
# Ref-and-SHA alone still matched 2 of its 11 on sentence boundaries — "…of awk. At 55ecf4c…" and
# "…head 5 at 6259e53…" — where the "ref" is an English word. Requiring resolution drops both and keeps
# all 9 real stamps, INCLUDING BOTH INSTANCES OF THE BRIEF THIS GUARD EXISTS FOR (`main` at `e92d62a`).
# Resolution happens below, per candidate repository — it cannot happen in this scanner.
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
      if (isref(a) && b == "at" && issha(c)) { print a "\t" tolower(c) }
    }
  }' 2>/dev/null | sort -u | head -n "$MAX_CLAIMS")"

[ -z "$claims" ] && exit 0

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

# ONE CANDIDATE PER REPOSITORY, NOT PER DIRECTORY OR PER CLONE. Both halves of this were found by
# RUNNING the guard rather than reading it, one round apart, and they are the same defect at two scales:
#
#   * ~22 sibling directories here are linked WORKTREES of one repository. A per-directory scan listed
#     all of them, and under pass-if-any any stale worktree at the stamped SHA could vouch.
#   * `tadeumendonca-skills-mainprobe` is a second CLONE of this repository. `git worktree list`'s first
#     line is per-clone, so worktree-keying did not collapse it — and it was measured vouching for a
#     premise false of the tree being worked (#326 review, P2).
#
# So the key is the ORIGIN URL where there is one, falling back to the main worktree path. Two clones of
# one upstream are one repository; two unrelated repos that happen to share a filename are not.
repo_key() {
  local u
  u="$(git -C "$1" config --get remote.origin.url 2>/dev/null || true)"
  if [ -n "$u" ]; then printf '%s\n' "$u"; return; fi
  git -C "$1" worktree list --porcelain 2>/dev/null | awk '/^worktree /{print substr($0, 10); exit}'
}

# The representative TREE for a repository is `cwd`'s own tree when `cwd` belongs to it, and the main
# worktree otherwise — `cwd` is where the work is happening, so it is the tree a premise is about.
repo_main_tree() { git -C "$1" worktree list --porcelain 2>/dev/null | awk '/^worktree /{print substr($0, 10); exit}'; }

home_key="$(repo_key "$home_repo")"
[ -z "$home_key" ] && home_key="$home_repo"
# `key<TAB>tree` per candidate. `cwd`'s repository is seeded first with `cwd`'s own tree, so a later
# sibling belonging to the same repository never displaces it.
candidates="$home_key	$home_repo"
workspace="$(dirname "$home_repo")"
for entry in "$workspace"/*; do
  [ -d "$entry" ] || continue
  top="$(git -C "$entry" rev-parse --show-toplevel 2>/dev/null || true)"
  [ "$top" = "$entry" ] || continue
  key="$(repo_key "$entry")"
  [ -z "$key" ] && key="$entry"
  printf '%s\n' "$candidates" | cut -f1 | grep -qxF "$key" && continue
  tree="$(repo_main_tree "$entry")"
  [ -z "$tree" ] && tree="$entry"
  candidates="$candidates
$key	$tree"
done
candidates="$(printf '%s' "$candidates" | head -n "$MAX_CANDIDATES")"

# ── attribute the stamp to ONE repository ─────────────────────────────────────────────────────
# `git ls-files` covers the bare-filename case (`architecture.en.md`), which is the form the failure
# this guard exists for actually used — a citation with no directory component resolves against no
# repository root, so a `-e` test alone would have fallen straight through to the `cwd` fallback and
# reproduced the very bug the owner's correction is aimed at.
#
# A NON-DISTINGUISHING PATH IS DROPPED, AND THAT IS WHAT MAKES ATTRIBUTION MEAN ANYTHING. Measured on
# #326's review (P3): a brief citing `README.md` resolved to SEVEN repositories in this workspace,
# four of them unrelated MCP forks — so under pass-if-any a claim needed to be true of only one of
# seven. A path that exists in more than one repository attributes nothing; only a path unique to one
# repository says which tree the brief is about.
#
# AND WHERE ATTRIBUTION IS AMBIGUOUS THE GUARD FAILS OPEN, DELIBERATELY. If the distinguishing paths
# name two or more repositories, the brief spans repositories and carries one stamp — there is no fact
# available that says which one the stamp is about. Checking it against either would be a coin toss
# reported as a control. Declared false negative, named in the header: a cross-repo brief is not checked.
resolved_pairs=""
if [ -n "$paths" ]; then
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    case "$p" in /*) continue ;; esac
    hits=""
    while IFS="$(printf '\t')" read -r key tree; do
      [ -z "$tree" ] && continue
      hit=""
      if [ -e "$tree/$p" ]; then
        hit=1
      else
        case "$p" in
          */*) : ;;
          *) [ -n "$(git -C "$tree" ls-files -- "$p" "*/$p" 2>/dev/null | head -n 1)" ] && hit=1 ;;
        esac
      fi
      [ -n "$hit" ] && hits="$hits
$key	$tree"
    done <<< "$candidates"
    hits="$(printf '%s' "$hits" | grep -v '^$' || true)"
    # Exactly one repository, or the path tells us nothing.
    if [ "$(printf '%s\n' "$hits" | grep -c . )" = "1" ]; then
      resolved_pairs="$resolved_pairs
$hits"
    fi
  done <<< "$paths"
fi

resolved_pairs="$(printf '%s' "$resolved_pairs" | grep -v '^$' | sort -u || true)"
distinct_repos="$(printf '%s' "$resolved_pairs" | cut -f1 | sort -u | grep -c . || true)"

if [ "$distinct_repos" = "1" ]; then
  targets="$(printf '%s' "$resolved_pairs" | cut -f2 | sort -u | head -n 1)"
  target_source="the repository the brief's distinguishing citations resolve to"
elif [ "$distinct_repos" = "0" ]; then
  targets="$home_repo"
  target_source="cwd's own repository (no citation in this brief distinguishes one repository, so there was nothing better to anchor on)"
else
  # Ambiguous attribution: more than one repository, one stamp. Nothing to check honestly.
  exit 0
fi

# ── verify ────────────────────────────────────────────────────────────────────────────────────
# THE REF KIND DECIDES WHAT THE STAMP ASSERTS, and conflating the two is a false positive on the most
# common legitimate stamp there is.
#
#   local branch  — "against `main` at `e92d62a`" asserts WHERE THE TREE IS. Both halves are checked:
#                   the tree is on that branch, and HEAD is that commit. This is the incident's shape.
#   remote ref    — "on `origin/main` at `9a210e1`" asserts only WHERE THAT REF POINTS. HEAD is NOT
#                   checked: measuring a base while sitting on a feature branch is normal, correct
#                   briefing, and 4 of the 9 stamps in the corpus are exactly that. Requiring HEAD here
#                   would deny them all.
#   neither       — NOT A CLAIM. The token is an English word that happened to sit before `at <sha>`
#                   ("…of awk. At 55ecf4c…"). Skipped silently; this is what drops the 2 prose accidents.
#
# A claim is evaluated as a UNIT — ref and commit together — because the ref matching and the commit
# not is precisely the state this guard exists to refuse.
failures=""
while IFS="$(printf '\t')" read -r ref sha; do
  [ -z "$sha" ] && continue
  passed=""
  detail=""
  while IFS= read -r r; do
    [ -z "$r" ] && continue

    # RESOLUTION IS THE GATE ON WHETHER THERE IS A CLAIM AT ALL.
    kind=""
    git -C "$r" rev-parse --verify --quiet "refs/heads/$ref" >/dev/null 2>&1 && kind="local"
    if [ -z "$kind" ]; then
      git -C "$r" rev-parse --verify --quiet "refs/remotes/$ref" >/dev/null 2>&1 && kind="remote"
    fi
    if [ -z "$kind" ]; then passed=1; break; fi

    if ! git -C "$r" cat-file -e "${sha}^{commit}" 2>/dev/null; then
      detail="$detail
      ${r}: no commit ${sha} in this repository"
      continue
    fi

    if [ "$kind" = "remote" ]; then
      tip="$(git -C "$r" rev-parse "refs/remotes/$ref" 2>/dev/null | tr 'A-Z' 'a-z' || true)"
      case "$tip" in
        "$sha"*) passed=1; break ;;
        *) detail="$detail
      ${r}: ${ref} is at ${tip}, the brief stamps ${sha}"
           continue ;;
      esac
    fi

    head_sha="$(git -C "$r" rev-parse HEAD 2>/dev/null | tr 'A-Z' 'a-z' || true)"
    case "$head_sha" in
      "$sha"*) : ;;
      *) detail="$detail
      ${r}: HEAD is ${head_sha}, the brief stamps ${sha}"
         continue ;;
    esac
    cur="$(git -C "$r" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
    if [ "$cur" != "$ref" ]; then
      detail="$detail
      ${r}: the tree is on '${cur}', the brief stamps '${ref}'"
      continue
    fi
    passed=1
    break
  done <<< "$targets"
  [ -n "$passed" ] && continue
  failures="$failures
  claim: ${ref} at ${sha}${detail}"
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

WHAT THIS GUARD CHECKS, AND WHAT IT DELIBERATELY DOES NOT. It evaluates ONE claim form — a ref and the
commit it is stamped at, together, where the ref resolves in this repository. A local branch asserts
where the tree IS (branch and HEAD both checked); a remote-tracking ref asserts only where that ref
points. A BARE SHA IS NEVER CHECKED: a merge-base, a PR head or a quoted verdict marker is a reference,
not a premise, and checking those denied 8.0% of 859 real briefs for no reason. It does NOT verify
file:line citations, and never will — whether a file says what a brief claims it says is prose-reading,
and a control that catches half and names the half is worth more than one that reaches for everything
and cannot say what it missed.

So passing this guard means the TREE is what the brief says, never that the LINES are — and where the
brief cites paths in more than one repository, it means nothing at all, because attribution is
ambiguous there and nothing was checked.

TO CLEAR IT: re-measure against the tree you are actually dispatching about and re-stamp the brief, or
check out the state the brief describes. If this ref-and-commit pair is a deliberate reference to a
historical state rather than this dispatch's premise, drop the ref and name the commit alone — a bare
SHA is not a claim and passes untouched."

jq -n --arg r "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $r
  }
}'
exit 0
