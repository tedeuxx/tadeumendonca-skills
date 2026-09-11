#!/usr/bin/env bash
# purpose: say at session start which of this repository's linked worktrees are finished and removable, because nothing removes them after a merge and the registry grows silently until someone happens to look
# worktree-notice.sh — SessionStart hook: the worktree lifecycle's MISSING HALF, reported.
#
# ── WHAT IT IS, AND THE ONE SENTENCE IT MUST NOT BE READ PAST ────────────────────────────────────
#
# It is a NOTICE. It classifies and reports; it removes nothing, refuses nothing, and every exit
# path is success. It makes no `gh` call, reads no Issue, no label, no milestone and no queue. The
# same class `cadence-notice.sh` is, and it is that class ON PURPOSE rather than by convenience.
#
# The owner's standing rule decided the class before the code was written:
#
#     A preventive control whose false positives are unobservable by the person it protects is
#     worse than no control, however good its true positives.
#
# A hook that DELETES A DIRECTORY is the sharpest member of that class. Its false positive is an
# unrecoverable deletion, and it lands before anyone sees anything — the same shape that got
# `action-pendency-guard.sh` deleted in the week this was written. A report's errors run the other
# way: it errs toward LEAVING a directory, and a directory left behind is visible twice over — as a
# folder on disk and as a line in `git worktree list`. The two options do not have symmetric
# downsides and were not priced as if they did.
#
# ── THE LAYER QUESTION WAS OPEN AND IS NOW MEASURED: DISCOVERY WORKS ─────────────────────────────
#
# `#437` left it open whether a hook receiving one `cwd` can even find the worktree set, given they
# sit under at least four naming conventions (`io-wt-*`, `tadeumendonca-io-*`, `tmio-*`, `wt-*`).
# The answer is YES, and it is NOT the sibling-tree heuristic ADR-0004 calls "a heuristic and the
# weakest part". `git worktree list` reads git's own registry under the COMMON git dir, so it
# returns every worktree of the repository at its real path, from any cwd inside it. Measured
# 2026-09-10 in `tedeuxx/tadeumendonca-io`, four cwds, one answer:
#
#   git -C <primary tree>                  worktree list | tail -n +2 | wc -l   -> 28
#   git -C <a linked worktree>             worktree list | tail -n +2 | wc -l   -> 28
#   git -C <a subdir of a linked worktree> worktree list | tail -n +2 | wc -l   -> 28
#   git -C <the OTHER repository>          worktree list | tail -n +2 | wc -l   ->  0
#
# No path guessing, no naming convention, no `cwd`-relative walk. THE BOUND IS THE LAST ROW: one
# `cwd` reaches one REPOSITORY's worktrees. A session rooted in the plugin repository cannot see the
# consuming repository's, and that is correct behaviour rather than a gap — this hook reports the
# tree the session will itself create worktrees in.
#
# ── THE LIVENESS PREDICATE, AND WHY EACH LIMB IS THERE ───────────────────────────────────────────
#
# A worktree is reported REMOVABLE only when all of the following hold. Every limb was measured
# against real `git worktree remove` behaviour on build `git 2.x` on this machine, by creating and
# destroying throwaway worktrees — never by reading the manual.
#
#   1. NOT LOCKED. `git worktree lock` is git's own in-use marker, and `git worktree remove` refuses
#      a locked worktree outright (`fatal: cannot remove a locked working tree`, exit 128, directory
#      survives). It is the cheapest mitigation available and 0 of 28 worktrees used it — measured
#      against the porcelain key census, where `locked` was ABSENT rather than misread, and
#      confirmed by locking a probe and watching the key appear.
#
#   2. HEAD IS AN ANCESTOR OF THE TRUNK REF. This is what "finished" means: every committed byte is
#      already on the trunk, so removal loses nothing even in principle.
#
#   3. THE WORKING TREE IS CLEAN AS `git status --porcelain` SEES IT — modifications AND untracked
#      files. This limb is the one that is easy to get backwards, so both directions were measured:
#        * an UNTRACKED file BLOCKS `git worktree remove` (directory survives, git names the reason);
#        * an IGNORED file does NOT (a probe carrying a gitignored `node_modules/` removed cleanly).
#      That asymmetry is why the naive "it has node_modules so it is dirty" reading is wrong here:
#      24 of the 26 present worktrees carry a real ~390 MB `node_modules` and report CLEAN, because
#      `.gitignore` carries `node_modules/`. The two that report untracked entries carry SYMLINKS
#      into the primary tree's `node_modules`, and a trailing-slash ignore pattern does not match a
#      symlink. Nothing here special-cases either — the predicate asks git.
#
#   4. NOT DETACHED-AND-UNREACHABLE. This is the ONE case where removal genuinely destroys work, and
#      it is invisible to limbs 1–3. Measured: a worktree on a BRANCH keeps its commits after
#      removal, because the branch ref survives and still resolves — so an unmerged branch-backed
#      worktree is recoverable with one `git worktree add`. A DETACHED worktree carrying commits is
#      referenced by NOTHING (`for-each-ref --contains <head>` -> 0) even before removal, so the
#      directory is the last handle and removing it makes the commits unreachable. Limb 4 refuses
#      that case loudly instead of silently.
#
# Limbs 1 and 3 are ALSO enforced by git itself, and that redundancy is deliberate rather than
# wasted: it means acting on this notice with the plain command cannot destroy work even if this
# hook's classification is wrong. Limbs 2 and 4 are the ones git does not check, and they are the
# reason this file exists rather than a line of documentation saying "run `git worktree remove`".
#
# ── WHAT IT DELIBERATELY DOES NOT DO ─────────────────────────────────────────────────────────────
#
#   * It never prints --force, and a worktree git refuses is listed with what is blocking it.
#     `--force` overrides limbs 1 and 3 at once — it removes a locked
#     worktree and destroys uncommitted tracked work. A notice that offered it would be handing the
#     reader the one command that turns this hook's safe advice into an unrecoverable act. A worktree
#     that plain `remove` refuses is reported WITH WHAT IS BLOCKING IT, so the decision is the
#     human's with the evidence in front of them.
#
#     ~~without asking~~ — **STRUCK 2026-09-10 (#443), AND THE STRIKE IS NARROW ENOUGH TO BE WORTH
#     READING.** `permission-guard.sh` rule 4c now refuses `git worktree remove` when the TARGET
#     holds uncommitted work, keyed on the target rather than on any flag spelling — so for a target
#     that rule can resolve, the forced form does now ask, in the sense that it comes back denied
#     with the reason. **It is NOT closed.** 4c abstains on an unresolvable target (a chained form, a
#     `cd`/`env`, a target registered nowhere) and sees nothing at all behind a wrapper, an alias or
#     a script file, and `rm -r <worktree>` destroys the same bytes with no decision from any layer.
#     So this hook's own refusal to print the flag is UNCHANGED and is not made redundant: the floor
#     covers one spelling of the act, this notice covers the reader's intent, and neither substitutes
#     for the other.
#
#     THE TWO AGREE ON THE PREDICATE, WHICH IS WHY THEY COMPOSE RATHER THAN OVERLAP. Limb 3 here and
#     rule 4c both reduce to `git status --porcelain` being non-empty, and both were measured against
#     the same four states independently — untracked BLOCKS a bare remove, ignored does NOT. The
#     class this hook reports as MERGED BUT NOT CLEAN is exactly the class 4c denies the forced
#     removal of.
#   * IT KEYS ON NO DIRECTORY NAME. `#437` forbids it and the forbidding is right: four naming
#     conventions are already in use and a fifth costs nothing to invent. Every classification here
#     comes from git's registry or from git's own answer about a path.
#   * IT READS NO OBJECT A LOOP MODE VARIES. No milestone, no label, no container, no queue, no
#     `gh` call at all — so the mode contract's untouchable-list measurement survives it intact.
#
# ── WHAT IT CANNOT SEE, NAMED SO A SILENCE IS NOT READ AS A CLEAN BILL ───────────────────────────
#
#   * ONE REPOSITORY, per the discovery bound above.
#   * ONE SESSION LATE, by construction — a worktree finished mid-session is reported at the next.
#   * THE PARENT ONLY. A subagent never sees a SessionStart notice.
#   * IT CANNOT TELL A FINISHED WORKTREE FROM ONE SOMEBODY IS ABOUT TO USE. Limbs 1–4 answer "is
#     removing this lossless", never "does anyone want this". `git worktree lock` is the declared
#     opt-out for the second question, and a worktree nobody locked is a worktree this hook will
#     report as removable however live it is. That residual is NARROWED by the lock and is not
#     closed by it — which is exactly why nothing here removes anything.
#
# Contract: prints SessionStart JSON carrying additionalContext, exits 0. Silent on every error —
# no jq, no git, not a repository, no linked worktrees, no resolvable trunk ref — because a session
# must always be able to start and an unavailable answer must never render as "nothing to clean".

set -uo pipefail

command -v jq  >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

input="$(cat 2>/dev/null || true)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
[ -n "$cwd" ] || cwd="$PWD"
[ -d "$cwd" ] || exit 0

ROOT="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$ROOT" ] || exit 0

# ── the trunk ref ────────────────────────────────────────────────────────────────────────────────
# Limb 2 needs one. It is RESOLVED, never assumed: a repository with no `origin/main` is a
# repository this hook has no opinion about, and inventing a fallback branch name would be the same
# defect as inventing a threshold. `origin/HEAD` is tried second because it is git's own record of
# the remote's default branch and costs nothing to consult.
TRUNK=""
for cand in origin/main origin/HEAD; do
  if git -C "$ROOT" rev-parse --verify -q "$cand^{commit}" >/dev/null 2>&1; then TRUNK="$cand"; break; fi
done
[ -n "$TRUNK" ] || exit 0

# ── debounce: at most one notice per UTC day, per REPOSITORY ─────────────────────────────────────
# `--git-common-dir`, not `--git-dir`. In a linked worktree `--git-dir` returns that worktree's own
# `.git/worktrees/<name>`, so a debounce written there would fire once per worktree per day — which
# on this machine's 26 is a notice that reads as a nag and gets routed around. The common dir is
# shared by every worktree of the repository, which is the scope the notice itself has.
common_dir="$(git -C "$ROOT" rev-parse --git-common-dir 2>/dev/null || true)"
[ -n "$common_dir" ] || exit 0
case "$common_dir" in /*) : ;; *) common_dir="$ROOT/$common_dir" ;; esac
debounce_dir="$common_dir/worktree-notice"
today="$(date -u +%Y-%m-%d 2>/dev/null || true)"
[ -n "$today" ] || exit 0
mkdir -p "$debounce_dir" 2>/dev/null || true
[ -f "$debounce_dir/$today" ] && exit 0

# ── read git's registry ──────────────────────────────────────────────────────────────────────────
# `--porcelain` rather than the human list: the human format has no stable way to say "locked" and
# quotes nothing, so a path containing a space silently splits. The porcelain form is one key per
# line, a blank line between records, and `worktree` is always the first key of a record.
listing="$(git -C "$ROOT" worktree list --porcelain 2>/dev/null || true)"
[ -n "$listing" ] || exit 0

finished=""      ; n_finished=0
blocked=""       ; n_blocked=0
live=""          ; n_live=0
locked=""        ; n_locked=0
prunable=""      ; n_prunable=0
unreachable=""   ; n_unreachable=0
first=1

flush() {
  # $w path · $h head · $b branch ('' when detached) · $lk locked · $pr prunable
  [ -z "${w:-}" ] && return 0
  if [ "$first" = 1 ]; then first=0; return 0; fi     # record 1 is the primary tree; never a subject

  if [ -n "${pr:-}" ]; then
    n_prunable=$((n_prunable + 1))
    prunable="$prunable
  $w"
    return 0
  fi
  if [ -n "${lk:-}" ]; then
    n_locked=$((n_locked + 1))
    locked="$locked
  $w"
    return 0
  fi

  # Limb 4 — the one genuine loss case, checked BEFORE limb 2 so it is never reported as merely live.
  if [ -z "${b:-}" ]; then
    refs="$(git -C "$ROOT" for-each-ref --contains "$h" --format='%(refname)' 2>/dev/null | grep -c . || true)"
    case "$refs" in ''|*[!0-9]*) refs=0 ;; esac
    if [ "$refs" -eq 0 ]; then
      n_unreachable=$((n_unreachable + 1))
      unreachable="$unreachable
  $w — detached at ${h:0:8}, and NO ref contains that commit. Removing this directory makes those
    commits unreachable. Give them a ref first:  git -C $w branch <name>"
      return 0
    fi
  fi

  # Limb 2 — finished means "already on the trunk".
  if ! git -C "$ROOT" merge-base --is-ancestor "$h" "$TRUNK" 2>/dev/null; then
    n_live=$((n_live + 1))
    live="$live
  $w — ${b:-detached at ${h:0:8}} is not an ancestor of $TRUNK"
    return 0
  fi

  # Limb 3 — git's own definition of a clean tree, which is what `worktree remove` will apply.
  [ -d "$w" ] || { n_prunable=$((n_prunable + 1)); prunable="$prunable
  $w"; return 0; }
  dirt="$(git -C "$w" status --porcelain 2>/dev/null | head -5 || true)"
  if [ -n "$dirt" ]; then
    n_blocked=$((n_blocked + 1))
    blocked="$blocked
  $w — merged, but git will refuse to remove it; it reports:
$(printf '%s\n' "$dirt" | sed 's/^/      /')"
    return 0
  fi

  n_finished=$((n_finished + 1))
  finished="$finished
  $w"
}

w=""; h=""; b=""; lk=""; pr=""
while IFS= read -r line; do
  case "$line" in
    worktree\ *) flush; w="${line#worktree }"; h=""; b=""; lk=""; pr="" ;;
    HEAD\ *)     h="${line#HEAD }" ;;
    branch\ *)   b="${line#branch }" ;;
    locked*)     lk=1 ;;
    prunable*)   pr=1 ;;
  esac
done <<< "$listing"
flush

total=$((n_finished + n_blocked + n_live + n_locked + n_prunable + n_unreachable))
[ "$total" -gt 0 ] || exit 0

# A repository whose registry holds only IN PROGRESS and LOCKED worktrees stays SILENT: both are
# correct states, and a notice that fires on them is one trained out by the time it matters.
# `n_blocked` IS in the firing set, and it is here because a test case caught it missing: a merged
# worktree carrying untracked entries is the one class where a human has to adjudicate whether those
# entries are work or build output, and suppressing it hides exactly the decision this hook exists
# to surface.
[ $((n_finished + n_prunable + n_unreachable + n_blocked)) -gt 0 ] || exit 0

: > "$debounce_dir/$today" 2>/dev/null || true
find "$debounce_dir" -maxdepth 1 -type f ! -name "$today" -delete 2>/dev/null || true

body="WORKTREE LIFECYCLE — $total linked worktree(s) registered in $ROOT, trunk ref $TRUNK.
"
# The command form is printed ONCE and the paths listed beneath it. The first draft repeated the
# whole invocation per worktree and produced 4,170 bytes of always-on context for 26 near-identical
# lines — a cost this hook pays in EVERY session of the consuming repository, which is the wrong
# place to be verbose. The list is capped for the same reason; the registry itself is one command
# away and is named rather than reproduced.
if [ "$n_finished" -gt 0 ]; then
  shown="$(printf '%s' "$finished" | grep -c . || true)"
  case "$shown" in ''|*[!0-9]*) shown=0 ;; esac
  listing_body="$finished"
  if [ "$shown" -gt 12 ]; then
    listing_body="
$(printf '%s' "$finished" | grep . | head -12)
  … and $((shown - 12)) more — the full registry is: git -C $ROOT worktree list"
  fi
  # NO BLANK LINE INSIDE A SECTION. A blank line is what a reader — and a suite — uses to find where
  # a section ends, and the first draft put one between the command form and the list. That made a
  # section-scoped assertion match an empty block and pass against anything, which is this repo's
  # own named defect class: an assertion that cannot fail. Caught by mutating the hook, not by
  # reading it.
  body="$body
FINISHED ($n_finished) — head already on $TRUNK, working tree clean, not locked. Removing these
loses nothing. One at a time, with the plain form:  git -C $ROOT worktree remove <path>$listing_body
"
fi
[ "$n_prunable" -gt 0 ] && body="$body
PRUNABLE — registered with no directory on disk. git removes these itself:$prunable
  git -C $ROOT worktree prune
"
[ "$n_unreachable" -gt 0 ] && body="$body
DO NOT REMOVE — detached with commits no ref points at:$unreachable
"
[ "$n_blocked" -gt 0 ] && body="$body
MERGED BUT NOT CLEAN — git will refuse; decide with the evidence rather than reaching for --force:$blocked
"
[ "$n_live" -gt 0 ] && body="$body
IN PROGRESS — head not yet on $TRUNK. Not removable:$live
"
[ "$n_locked" -gt 0 ] && body="$body
LOCKED — declared in use with 'git worktree lock'. Never reported as removable:$locked
"

body="$body
NOTHING HERE REMOVES ANYTHING, and no command above carries --force. --force overrides both of
git's own refusals at once — it deletes a locked worktree and destroys uncommitted work — so it is
never printed here, and a worktree git refuses is listed with what is blocking it instead. Since
#443 the permission floor also refuses the forced removal of a worktree holding uncommitted work,
keyed on the target rather than the flag; that covers one spelling and not the class, so it is a
second layer under this advice and not a replacement for it. This is a NOTICE and never a control; nothing obliges anyone to act on it, and nothing
here can tell a finished worktree from one somebody is about to use. Declare that with
'git worktree lock <path> --reason \"<why>\"' when you open one for live work. Reported once per UTC
day per repository, so silence tomorrow is the debounce and not a repair."

jq -n --arg c "$body" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $c
  }
}'
exit 0
