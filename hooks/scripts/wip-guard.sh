#!/usr/bin/env bash
# wip-guard.sh — PreToolUse(Bash) guard bounding work-in-progress at the PR boundary.
#
# The bound is FILE OVERLAP, not a count. ONE level, and there is no second.
#
# ~~The bound has TWO LEVELS: file overlap between slices, and a COUNT between stories.~~
# ~~True of slices, and false of stories since `gitflow-single-env` (#122/#123).~~
# **Struck 2026-08-04, owner's decision: the story level is REMOVED and the sentence above it
# is true again without qualification.** The record of that design, and of the four defects
# found in it, is kept struck under STORY AWARENESS — RETIRED at the bottom of this header.
# Read it before proposing branch-level decomposition again: it was tried, it was correct, and
# it came out for a reason that is a measurement rather than an opinion.
#
# It used to count: one open PR per repo, full stop. That was a proxy for the thing
# actually worth preventing — stacked PRs that go stale and turn their merge into a
# conflict resolution — and it was a bad one. It blocked disjoint slices, which is the
# common case, while doing nothing about the real risk. Measured over one long session:
# of roughly a dozen slices, only three would have collided; every other one waited
# anyway, and the queue the owner had asked to be drained stood still.
#
# So the question is not "how many are open" but "does this one touch what an open one
# touches". Two PRs editing different files merge cleanly in either order and there is
# nothing to protect against.
#
# Scope: per REPO, per author. Not global — a genuine cross-repo pair (a plugin change
# plus the consuming repo adopting it) is one slice wearing two PRs. Author-scoped
# because a bot's dependency PR should be drained, but must not stop a human slice.
#
# Contract: receives the PreToolUse JSON on stdin; denies by printing a
# permissionDecision JSON and exiting 0. Fails OPEN on any error — no network, no gh,
# no git, no auth, unparseable payload, an unreadable file list — because a
# loop-discipline check must never be the thing that wedges the loop. Every early exit
# below is that rule applied: an answer we could not get is not a verdict.
#
# ⚠ Do not carry this file's fail-open rule across to `permission-guard.sh`, the other
# PreToolUse hook here. This hook enforces loop DISCIPLINE, where a spurious deny costs more
# than a missed one; that hook is the irreversible FLOOR, where a missed deny is the whole
# failure. **Do not "fix" one to match the other.**
#
# ~~That hook fails CLOSED.~~ **Struck 2026-08-02 — it does not, and asserting it here was
# worse than saying nothing.** `permission-guard.sh` fails OPEN on an unreadable payload, by
# design (its header says so, and `settings.json`'s deny list is the stated backstop). Measured:
# with `jq` off PATH it emits no decision at all, so a main-agent `git push origin main` is
# allowed. The backstop covers terraform / force-push / `rm -rf` / secrets, but NOT rules 7, 7b
# and 8 — which exist precisely because a prefix matcher cannot express them.
#
# So the accurate warning is the one above: the DIRECTIONS DIFFER BY INTENT, and this file's
# reasoning is not transferable. What that floor should do when it cannot read its input is an
# open question, NAMED rather than answered here — and named, not filed: the reviewer does not open
# work, so there is no issue to point at. ("filed" stood here for one round and was false, in the
# file whose entire diff is about a comment asserting something untrue.) A comment claiming that
# question was already answered is exactly the failure it was written to prevent — which is how the
# struck line above got here, found by `security` reviewing #124.
#
# ── STORY AWARENESS — RETIRED 2026-08-04 (kept struck, not deleted) ──────────────────
#
# ~~Under `gitflow-single-env` a story owns a short-lived branch and its tasks open PRs INTO
# that branch; the story branch itself then opens one PR into the trunk, and THAT merge is the
# deploy. So this guard has to move in two opposite directions at once:~~
#
#   ~~LOOSER inside a story: two task PRs touching the same file, in the same story, are
#   normal work rather than a collision. They land in sequence on a branch that has not
#   published yet. Blocking them would deny the exact flow the model creates.~~
#
#   ~~TIGHTER between stories: only one story may be live. Not because two stories would
#   necessarily collide — file overlap already answered that question, and answered it
#   correctly in #88/#90 — but because a story branch DIVERGES FOR AS LONG AS THE STORY
#   LASTS. Overlap measured at an instant cannot see time, and every cost of the model (the
#   lead dispatches, a diverging branch, a ratification, an acceptance) is per story.~~
#
# ~~Which story a PR belongs to is read off the branch pair: a task PR has `feat/*` as its
# BASE, and the story's own publish PR has `feat/*` as its HEAD.~~
#
# **WHY IT CAME OUT, and the part that transfers: a user story's tasks are CHECKBOXES on its
# issue, not branches. One story, one branch, one PR. Measured across roughly NINETY branches
# in this repo, NOT ONE task branch has ever existed — no `story/*`, no `task/*`, and no PR
# whose base is another feature branch. The two-level rule shipped, carried 14 suite cases,
# stayed green, and never once decided anything.** It was inert for a second reason as well:
# it read `story/` while every branch here is `feat/`. It is not removed for being wrong — it
# is removed for describing a flow that does not exist, which is the defect class this repo
# spent the week deleting. Leaving it would have been the second time knowingly.
#
# THE FOUR DEFECTS FOUND IN IT, kept because three of them are about shell, not about stories,
# and the shapes recur:
#   1. ATTACHED OPTION VALUES. `gh` accepts `--base=x` and `-Bx`; a space-only regex missed
#      both. It broke the rule in OPPOSITE directions at once — the count failed OPEN (a
#      second story read as no story) and the exemption failed CLOSED (a legitimate task PR
#      denied), intermittently, depending only on how the command happened to be spelled.
#      **This parsing SURVIVES the retirement — see `base` below — and must keep both spellings.**
#   2. A BRANCH NAME INTERPOLATED INTO A REGEX. `.` is legal in a git ref, so `feat/1..thing`
#      matched a live `feat/12-thing`, deleted it from the set, and let a second story through:
#      a bypass a crafted name can drive and a mis-match real names hit by accident. Fixed with
#      `grep -vxF`. **The surviving overlap path uses `grep -Fxf` for the same reason — fixed
#      strings, never a regex, for anything that came out of a ref or a path.**
#   3. A MISSING jq FIELD MAKING A RULE VANISH SILENTLY. Without `// ""`, a `gh` that omitted
#      `headRefName`/`baseRefName` made `startswith` error, jq print nothing, and the whole
#      story rule disappear while every test still passed.
#   4. A VACUOUS TEST FOR (3). Its first version used a non-story branch, so the block
#      short-circuited before the defaults were ever consulted — it passed with the line under
#      test deleted outright. Only a MIXED open set, fieldless entry FIRST, could falsify it.
#      That one is not about stories at all; it is this workspace's recurring defect.

set -uo pipefail

input="$(cat 2>/dev/null || true)"
command="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[ -z "$command" ] && exit 0

cmd="$(printf '%s' "$command" | tr '\n\t' '  ')"
# Quoted spans collapsed first, so a commit message that merely MENTIONS `gh pr create`
# is not mistaken for the act of creating a PR.
cmd="$(printf '%s' "$cmd" | sed -e "s/'[^']*'/''/g" -e 's/"[^"]*"/""/g')"

# Only `gh pr create` is interesting. Everything else leaves immediately, so this adds
# no measurable cost to the Bash calls that make up the actual dev loop.
# THE REPO FLAG USED TO BE ACCEPTED IN ONE SPELLING. `-R x` matched; `--repo=x`, `-Rx` and `-R=x` did
# not, and neither did `--repo x` reach the `pr` that has to follow. When the pattern missed, the hook
# exited HERE — no decision, no denial, no trace. Spellings `gh` itself accepts turned the whole
# control off, for any repo, not only the cross-repo case.
#
# ~~FOUR SPELLINGS~~ — the first fix said four, covered four, and `-R=x` was the fifth. Struck rather
# than corrected in place, because how it was found is the lesson: not by reading the pattern, but by a
# gate running the REAL `gh`. It accepts `-R=x`; the space-only extraction leaked the `=` into the slug;
# `gh pr list -R =owner/x` failed to resolve; `open_prs` came back empty; and the guard exited ALLOWING
# the create. An enumerating comment is a comment that can be wrong by omission, so the pattern is now
# shared rather than restated.
#
# THE CHARACTER CLASS IS `permission-guard.sh`'s `gh_repo_flag`, VERBATIM (that file, line 380).
# Converging on it is the point: two hooks parsing the same flag two different ways is how one of them
# ends up a spelling behind, which is precisely what happened here.
#
# ~~If a sixth spelling ever appears, it is fixed in one place and both hooks move.~~ **False when
# written, and struck rather than deleted because the shape is the lesson.** These are two DUPLICATED
# LITERALS, not one shared variable — a hook cannot source a variable out of another hook. Editing
# `permission-guard.sh:380` alone leaves this file behind and BOTH suites stay green; that was
# measured, not reasoned. So the sentence described a mechanism that did not exist, in the comment
# block of the fix whose whole subject is a comment asserting a control it did not hold.
#
# What makes the claim true is elsewhere: `inventory-counts.test.sh` asserts the two literals are
# byte-identical, in all three places. A sixth spelling still takes two edits — the guarantee is not
# that they move together, it is that they cannot silently drift apart.
#
# This is defect 1 of the retired record above, which claims to have SURVIVED the rewrite. It survived
# for `--base` (see the extraction below, which handles `--base=` and `-B`) and was never carried to
# `-R`/`--repo` in either place. A comment asserting a control is held, in a file whose header is
# largely about a comment that asserted something untrue.
printf '%s' "$cmd" | grep -Eq '(^|[^[:alnum:]_])gh([[:space:]]+(-R[[:space:]=]*|--repo[[:space:]=]*)[^[:space:]]+)*[[:space:]]+pr[[:space:]]+create([[:space:]]|$)' || exit 0

command -v gh >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

# Honour an explicit -R/--repo; otherwise let gh infer from the working directory.
#
# ALL FOUR SPELLINGS, and this one matters even when the trigger above already fired. `gh pr create
# --repo=X` passes the trigger on the bare `gh pr create` and then failed HERE: `$repo` came back empty,
# `gh pr list` inferred the repo from the working directory, and the guard judged a create aimed at one
# repo using another repo's queue and another repo's branch — internally coherent and entirely wrong,
# with a denial naming a real PR and a real file list. That is worse than the trigger miss, because the
# message looks right and the author believes it.
repo="$(printf '%s' "$cmd" | sed -nE 's/.*[[:space:]](-R[[:space:]=]*|--repo[[:space:]=]*)([^[:space:]]+).*/\2/p')"
if [ -n "$repo" ]; then
  open_prs="$(gh pr list -R "$repo" --state open --author @me --json number,title,headRefName,baseRefName 2>/dev/null || true)"
else
  open_prs="$(gh pr list --state open --author @me --json number,title,headRefName,baseRefName 2>/dev/null || true)"
fi

# No answer means no verdict. Stay out of the way.
[ -z "$open_prs" ] && exit 0

# `length` on an OBJECT counts its keys, so an unexpected shape would read as a queue.
# Only an array is an answer; anything else means we did not get one.
count="$(printf '%s' "$open_prs" | jq 'if type == "array" then length else 0 end' 2>/dev/null || true)"
case "$count" in
  ''|0) exit 0 ;;
esac

# The base this PR would target: an explicit -B/--base if the command carries one, else the
# repo default.
#
# ATTACHED VALUES, both spellings. `gh` accepts `--base=x` and `-Bx` exactly as it accepts
# the spaced forms, and a space-only regex misses them — the same class `permission-guard`
# 5b/5c were hardened for, so this is the in-repo idiom rather than a new idea. Defect 1 in
# the retired record above: it broke that rule in both directions at once.
#
# `-B[[:space:]]*` cannot mis-fire on `--base`: the character before `B` would have to be a
# space, and in `--base` it is `-` with a lowercase `b`.
explicit_base="$(printf '%s' "$cmd" | sed -nE 's/.*[[:space:]](-B[[:space:]]*|--base[[:space:]=]*)([^[:space:]]+).*/\2/p')"

# What THIS branch would bring. Compared against the merge-base with the branch it would
# target, not against that branch's tip, so commits that merely landed on the base while this
# branch was alive are not counted as ours.
merge_base=""
[ -n "$explicit_base" ] && merge_base="$(git merge-base "origin/$explicit_base" HEAD 2>/dev/null || true)"

# FALL BACK TO THE DEFAULT BRANCH rather than giving up, when the command named a base this
# clone cannot resolve (never fetched, a ref that does not exist, a remote not named origin).
# Without the fallback, `--base=anything-unresolvable` is a one-word BYPASS of the whole guard:
# no merge-base, no file list, fail open, done. The default branch is the right second guess —
# it is what the old two-level version always used here, so this preserves that behaviour
# exactly in the case where the explicit base tells us nothing.
#
# ONE `gh repo view` at most, and it is the only one in this file now: the retired story block
# made the identical query first and the overlap block reused its answer, so with that block
# gone the resolution MOVED here rather than being asked twice or lost.
if [ -z "$merge_base" ]; then
  default_base="$(gh repo view ${repo:+-R "$repo"} --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || true)"
  [ -z "$default_base" ] && default_base="main"
  merge_base="$(git merge-base "origin/$default_base" HEAD 2>/dev/null || true)"
fi
[ -z "$merge_base" ] && exit 0
mine="$(git diff --name-only "$merge_base" HEAD 2>/dev/null || true)"
# A branch with no diff yet is not a conflict risk, and it is also not a PR worth
# blocking. Either way there is nothing to intersect.
[ -z "$mine" ] && exit 0

# Intersect against each open PR in turn, so the denial can name WHICH PR and WHICH
# files — a denial that does not say what to look at is a denial the author works
# around rather than acts on.
collisions=""
for pr in $(printf '%s' "$open_prs" | jq -r '.[].number' 2>/dev/null || true); do
  theirs="$(gh pr view "$pr" ${repo:+-R "$repo"} --json files -q '.files[].path' 2>/dev/null || true)"
  # Could not read that PR's files — fail open for this PR rather than guessing at an
  # overlap we cannot see.
  [ -z "$theirs" ] && continue
  # `-Fxf`: fixed strings, whole line. A path is not a regex and must never be read as one —
  # defect 2 in the retired record above is the same shape, and it produced both a bypass and
  # an accidental mis-match.
  shared="$(printf '%s\n' "$mine" | grep -Fxf <(printf '%s\n' "$theirs") 2>/dev/null | tr '\n' ' ' || true)"
  [ -n "$shared" ] && collisions="${collisions}#${pr}: ${shared}; "
done

# Disjoint from everything open. This is the case the old counter got wrong, and it is
# the common one.
[ -z "$collisions" ] && exit 0

jq -n --arg r "Blocked: this slice touches files an open PR of yours already touches, so one of them will go stale and its merge becomes a conflict resolution. Finish that one first — merge it, or close it with a reason. Overlaps: ${collisions}(Disjoint slices are allowed: the bound is file overlap, not a count.)" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $r
  }
}'
exit 0
