#!/usr/bin/env bash
# worktree-notice.test.sh — does the notice classify a worktree the way `git worktree remove` will
# actually behave, stay silent when there is nothing to say, and never offer `--force`?
#
# Mutation-checked: every assertion below was verified to fail against a deliberately broken version
# of the HOOK — not of this file — because an assertion that cannot fail is worse than none, and
# editing the checker only proves the checker responds to being edited. The mutations run and the
# reds they produced are recorded in the pull request rather than here, where they would go stale.
#
# THE FIXTURE IS A REAL GIT REPOSITORY WITH REAL WORKTREES, and that is not incidental. Every limb of
# the hook's predicate is a question put to git — `merge-base --is-ancestor`, `status --porcelain`,
# `for-each-ref --contains`, and the `locked`/`prunable` keys of `worktree list --porcelain`. A
# fixture that stubbed git would be asserting the stub, and the two facts this suite exists to pin
# are facts about GIT rather than about the script:
#
#   * an UNTRACKED file blocks `git worktree remove`; an IGNORED file does not;
#   * a branch-backed worktree's commits survive removal, a detached one's do not.
#
# Case 11 therefore does not assert what the hook printed — it runs the real `git worktree remove`
# the hook recommended and asserts it SUCCEEDED. That is the only assertion here that can catch the
# hook and git disagreeing, which is the failure mode a report of this shape actually has.
#
# `gh` IS STUBBED TO A RECORDER RATHER THAN REMOVED, deliberately. Removing it from PATH would make
# "the hook makes no tracker call" pass vacuously — the same shape as a check whose pattern is dead.
# The recorder appends every invocation to a file, so the assertion reads a file that CAN be
# non-empty, and case 9 proves it can by invoking the stub directly.
#
# Run: bash hooks/scripts/worktree-notice.test.sh

set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/worktree-notice.sh"
pass=0
fail=0

ok()  { printf 'ok    %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL  %s\n     %s\n' "$1" "$2"; fail=$((fail + 1)); }

command -v git >/dev/null 2>&1 || { echo "SKIP: git unavailable"; exit 0; }
command -v jq  >/dev/null 2>&1 || { echo "SKIP: jq unavailable";  exit 0; }

# ── the recorder ─────────────────────────────────────────────────────────────────────────────────
STUBDIR="$(mktemp -d)"
GH_LOG="$STUBDIR/gh-calls"
: > "$GH_LOG"
cat > "$STUBDIR/gh" <<STUB
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$GH_LOG"
exit 0
STUB
chmod +x "$STUBDIR/gh"
PATH="$STUBDIR:$PATH"
export PATH

# ── fixture ──────────────────────────────────────────────────────────────────────────────────────
# One repository, one commit, `refs/remotes/origin/main` pointed at it — the hook resolves its trunk
# ref by name and has no opinion about a repository that carries none.
setup() {
  root="$(mktemp -d)"
  repo="$root/repo"
  mkdir -p "$repo"
  git -C "$repo" init -q 2>/dev/null
  git -C "$repo" config user.email t@example.invalid
  git -C "$repo" config user.name  "t"
  git -C "$repo" config commit.gpgsign false
  printf 'seed\n'          > "$repo/README.md"
  printf 'ignored-dir/\n' > "$repo/.gitignore"
  git -C "$repo" add -A
  git -C "$repo" commit -qm "seed"
  git -C "$repo" update-ref refs/remotes/origin/main HEAD
}

run() {
  # $1 — cwd handed to the hook. Clears the debounce first: the debounce is case 10's subject and
  # must not silently suppress every other case in the same UTC day.
  cd="$1"
  common="$(git -C "$cd" rev-parse --git-common-dir 2>/dev/null || true)"
  case "$common" in /*) : ;; *) common="$cd/$common" ;; esac
  rm -rf "$common/worktree-notice" 2>/dev/null || true
  printf '{"cwd":"%s","hook_event_name":"SessionStart"}' "$cd" | bash "$HOOK" 2>/dev/null
}

ctx() { printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext // ""' 2>/dev/null || true; }

# Extract one section of the notice: from its heading to the next blank line. Cases 3, 4 and 5 all
# assert a path is ABSENT from the FINISHED block, and an absence check over an EMPTY extraction
# passes against anything — which is exactly what happened on this suite's first run, when the hook
# still emitted a blank line inside the section. So every caller pairs the absence with a positive
# control worktree it requires to be PRESENT in the same block, and the arm fails if the control is
# missing rather than reporting a green over an empty string.
section() { printf '%s\n' "$1" | sed -n "/^$2/,/^\$/p"; }

# ── case 1 · a merged, clean, unlocked worktree is reported FINISHED ─────────────────────────────
setup
git -C "$repo" worktree add -q "$root/wt-done" -b done origin/main 2>/dev/null
out="$(run "$repo")"; c="$(ctx "$out")"
case "$c" in
  *"FINISHED"*"$root/wt-done"*) ok "1 · merged+clean+unlocked -> FINISHED, path named" ;;
  *) bad "1 · merged+clean+unlocked -> FINISHED" "context was: ${c:0:300}" ;;
esac

# ── case 2 · nothing removable -> SILENT ─────────────────────────────────────────────────────────
# The whole point of a report is that it is read. A notice that fires on a registry with nothing to
# act on is a notice that has been trained out by the time it matters.
setup
out="$(run "$repo")"
if [ -z "$out" ]; then ok "2 · no linked worktrees -> silent, no JSON at all"
else bad "2 · no linked worktrees -> silent" "emitted: ${out:0:200}"; fi

# ── case 3 · a LOCKED worktree is never FINISHED ─────────────────────────────────────────────────
setup
git -C "$repo" worktree add -q "$root/wt-lock" -b lk origin/main 2>/dev/null
git -C "$repo" worktree lock "$root/wt-lock" --reason "in use" 2>/dev/null
git -C "$repo" worktree add -q "$root/wt-ok" -b okb origin/main 2>/dev/null   # so the hook is not silent
out="$(run "$repo")"; c="$(ctx "$out")"
fin="$(section "$c" FINISHED)"
case "$fin" in
  *"wt-ok"*) : ;;   # positive control: the extractor really does see paths in this block
  *) bad "3 · locked worktree reported under LOCKED" \
         "CALIBRATION FAILED: control wt-ok absent from the FINISHED block — the absence check below would pass on anything"
     fin="__calibration-failed__" ;;
esac
case "$fin" in
  *"wt-lock"*) bad "3 · locked worktree is never FINISHED" "wt-lock appeared under FINISHED" ;;
  *) case "$c" in
       *"LOCKED"*"wt-lock"*) ok "3 · locked worktree reported under LOCKED, never FINISHED" ;;
       *) bad "3 · locked worktree reported under LOCKED" "context was: ${c:0:400}" ;;
     esac ;;
esac
git -C "$repo" worktree unlock "$root/wt-lock" 2>/dev/null

# ── case 4 · an UNMERGED branch-backed worktree is IN PROGRESS, not FINISHED ─────────────────────
setup
git -C "$repo" worktree add -q "$root/wt-live" -b live origin/main 2>/dev/null
printf 'ahead\n' >> "$root/wt-live/README.md"
git -C "$root/wt-live" commit -qam "ahead of trunk"
git -C "$repo" worktree add -q "$root/wt-ok" -b okb origin/main 2>/dev/null
out="$(run "$repo")"; c="$(ctx "$out")"
fin="$(section "$c" FINISHED)"
case "$fin" in
  *"wt-ok"*) : ;;   # positive control, same reason as case 3
  *) bad "4 · unmerged worktree reported IN PROGRESS" \
         "CALIBRATION FAILED: control wt-ok absent from the FINISHED block"
     fin="__calibration-failed__" ;;
esac
case "$fin" in
  *"wt-live"*) bad "4 · unmerged worktree is never FINISHED" "wt-live appeared under FINISHED" ;;
  *) case "$c" in
       *"IN PROGRESS"*"wt-live"*) ok "4 · unmerged worktree reported IN PROGRESS, never FINISHED" ;;
       *) bad "4 · unmerged worktree reported IN PROGRESS" "context was: ${c:0:400}" ;;
     esac ;;
esac

# ── case 5 · an UNTRACKED file makes it MERGED BUT NOT CLEAN, and the entry is quoted ────────────
# The predicate that matters: git will refuse this removal, so the hook must not recommend it.
setup
git -C "$repo" worktree add -q "$root/wt-dirty" -b dty origin/main 2>/dev/null
printf 'hand-written\n' > "$root/wt-dirty/NOTES-never-added.md"
git -C "$repo" worktree add -q "$root/wt-ok" -b okb origin/main 2>/dev/null   # positive control
out="$(run "$repo")"; c="$(ctx "$out")"
fin="$(section "$c" FINISHED)"
case "$fin" in
  *"wt-ok"*) : ;;
  *) bad "5 · untracked file -> MERGED BUT NOT CLEAN" \
         "CALIBRATION FAILED: control wt-ok absent from the FINISHED block"
     fin="__calibration-failed__" ;;
esac
case "$fin" in
  *"wt-dirty"*) bad "5 · untracked file -> not FINISHED" "wt-dirty appeared under FINISHED" ;;
  *) case "$c" in
       *"MERGED BUT NOT CLEAN"*"NOTES-never-added.md"*)
         ok "5 · untracked file -> MERGED BUT NOT CLEAN, blocking entry quoted" ;;
       *) bad "5 · untracked file -> MERGED BUT NOT CLEAN" "context was: ${c:0:400}" ;;
     esac ;;
esac

# ── case 6 · an IGNORED file does NOT block — this is the node_modules case ──────────────────────
# Measured against real git: `git worktree remove` tolerates ignored files and refuses untracked
# ones. If this arm ever goes red the hook has started treating build output as work, and 24 of the
# 26 worktrees this was written for would stop being reported at all.
setup
git -C "$repo" worktree add -q "$root/wt-ign" -b ign origin/main 2>/dev/null
mkdir -p "$root/wt-ign/ignored-dir"; printf 'x\n' > "$root/wt-ign/ignored-dir/build.js"
out="$(run "$repo")"; c="$(ctx "$out")"
fin="$(section "$c" FINISHED)"
case "$fin" in
  *"wt-ign"*) ok "6 · ignored file does not block -> still FINISHED" ;;
  *) bad "6 · ignored file does not block" "context was: ${c:0:400}" ;;
esac

# ── case 7 · a DETACHED worktree whose commits no ref contains is DO NOT REMOVE ──────────────────
# The one case where removal genuinely destroys work. It is checked before the ancestry limb so it
# can never be reported as merely in-progress.
setup
git -C "$repo" worktree add -q --detach "$root/wt-orphan" origin/main 2>/dev/null
printf 'orphan\n' >> "$root/wt-orphan/README.md"
git -C "$root/wt-orphan" commit -qam "unreferenced"
out="$(run "$repo")"; c="$(ctx "$out")"
case "$c" in
  *"DO NOT REMOVE"*"wt-orphan"*) ok "7 · detached + no containing ref -> DO NOT REMOVE" ;;
  *) bad "7 · detached + no containing ref -> DO NOT REMOVE" "context was: ${c:0:400}" ;;
esac

# ── case 8 · `--force` never appears anywhere in the emitted context ─────────────────────────────
# Calibrated below rather than asserted bare: the same selector is run against a string that DOES
# contain the flag, so a zero here is a real zero and not a dead pattern.
setup
git -C "$repo" worktree add -q "$root/wt-a" -b a1 origin/main 2>/dev/null
git -C "$repo" worktree add -q "$root/wt-b" -b b1 origin/main 2>/dev/null
printf 'hand\n' > "$root/wt-b/UNTRACKED.md"
git -C "$repo" worktree add -q --detach "$root/wt-c" origin/main 2>/dev/null
printf 'o\n' >> "$root/wt-c/README.md"; git -C "$root/wt-c" commit -qam "orphan"
out="$(run "$repo")"; c="$(ctx "$out")"
# THE SELECTOR IS THE INTERESTING PART, and it has now been wrong TWICE in opposite directions.
#
#   Too WIDE first: a bare `grep -c -- '--force'` over the whole context returns non-zero, because
#   the notice's own prose names the flag while explaining why it never offers it.
#
#   Then too NARROW: anchoring at `^[[:space:]]*git ` looked right and was measured wrong — planting
#   `--force` into the hook's own recommendation left this arm GREEN, because that recommendation is
#   written INLINE after a sentence and does not begin its line. An anchored selector was checking a
#   position the defect does not occupy.
#
# The property is neither "the word never appears" nor "no line starts with git". It is: NO
# `worktree remove` RECOMMENDATION ANYWHERE IN THE CONTEXT CARRIES THE FLAG. That is what the
# selector asks, and both calibrations below exercise it — one line that must match, and the live
# prose count that must be non-zero so the arm is not proving a word nobody writes.
force_lines() { printf '%s\n' "$1" | grep -E 'worktree remove' | grep -c -- '--force' || true; }
n_force="$(force_lines "$c")"
n_prose="$(printf '%s' "$c" | grep -c -- '--force' || true)"
n_ctl="$(force_lines 'loses nothing. One at a time:  git -C /r worktree remove --force <path>')"
if [ "$n_ctl" -ne 1 ]; then
  bad "8 · --force never offered in a copyable command" \
      "CALIBRATION FAILED: the selector returned $n_ctl on a line that plainly carries it"
elif [ "$n_prose" -eq 0 ]; then
  bad "8 · --force never offered in a copyable command" \
      "CALIBRATION FAILED: the notice does not mention --force at all, so this arm proves nothing"
elif [ "$n_force" -eq 0 ]; then
  ok "8 · 0 copyable command lines carry --force, though the prose names it $n_prose times (control: selector finds 1)"
else
  bad "8 · --force never offered in a copyable command" "found $n_force command line(s)"
fi

# ── case 9 · no `gh` call, and the recorder proves it could have recorded one ────────────────────
n_gh="$(grep -c . "$GH_LOG" || true)"
if [ "$n_gh" -ne 0 ]; then
  bad "9 · makes no tracker call" "the gh recorder logged $n_gh invocation(s)"
else
  gh probe --calibration >/dev/null 2>&1
  n_after="$(grep -c . "$GH_LOG" || true)"
  if [ "$n_after" -gt 0 ]; then
    ok "9 · zero gh calls across every case above (recorder proven live: it logged the probe)"
  else
    bad "9 · makes no tracker call" "CALIBRATION FAILED: the recorder logs nothing even when invoked"
  fi
fi
: > "$GH_LOG"

# ── case 10 · debounce — a second run the same day is silent ─────────────────────────────────────
setup
git -C "$repo" worktree add -q "$root/wt-dbg" -b dbg origin/main 2>/dev/null
first="$(run "$repo")"
second="$(printf '{"cwd":"%s","hook_event_name":"SessionStart"}' "$repo" | bash "$HOOK" 2>/dev/null)"
if [ -n "$first" ] && [ -z "$second" ]; then
  ok "10 · debounce — fires once, silent on the second run the same UTC day"
else
  bad "10 · debounce" "first=${#first} bytes, second=${#second} bytes (expected non-empty then empty)"
fi

# ── case 11 · the recommendation is EXECUTABLE — git actually removes what the hook named ────────
# The only assertion here that can catch the hook and git disagreeing. It runs the real command on
# the real fixture and asserts success and the directory's disappearance.
setup
git -C "$repo" worktree add -q "$root/wt-exec" -b ex origin/main 2>/dev/null
mkdir -p "$root/wt-exec/ignored-dir"; printf 'x\n' > "$root/wt-exec/ignored-dir/b.js"
out="$(run "$repo")"; c="$(ctx "$out")"
case "$c" in
  *"$root/wt-exec"*)
    if git -C "$repo" worktree remove "$root/wt-exec" >/dev/null 2>&1 && [ ! -d "$root/wt-exec" ]; then
      ok "11 · the plain command the hook recommends really removes it (no --force needed)"
    else
      bad "11 · the recommendation is executable" "git refused a worktree the hook called FINISHED"
    fi ;;
  *) bad "11 · the recommendation is executable" "hook did not name wt-exec at all" ;;
esac

# ── case 12 · a non-repository cwd is silent, and so is a repo with no trunk ref ─────────────────
tmp="$(mktemp -d)"
out="$(printf '{"cwd":"%s","hook_event_name":"SessionStart"}' "$tmp" | bash "$HOOK" 2>/dev/null)"
if [ -n "$out" ]; then
  bad "12 · non-repository cwd is silent" "emitted: ${out:0:200}"
else
  setup
  git -C "$repo" update-ref -d refs/remotes/origin/main
  git -C "$repo" worktree add -q "$root/wt-notrunk" -b nt HEAD 2>/dev/null
  out2="$(run "$repo")"
  if [ -z "$out2" ]; then
    ok "12 · silent on a non-repository cwd AND on a repository with no resolvable trunk ref"
  else
    bad "12 · no trunk ref is silent" "emitted: ${out2:0:200}"
  fi
fi

# ── case 13 · a NON-EMPTY registry with nothing actionable is also silent ───────────────────────
# Case 2 does not cover this and a mutation proved it: case 2's registry is EMPTY, so the hook exits
# on the "any linked worktrees at all" gate and never reaches the "anything actionable" gate.
# Loosening the second gate left the whole suite green. This case holds one IN PROGRESS worktree and
# one LOCKED one — both correct states, neither actionable — and requires silence.
setup
git -C "$repo" worktree add -q "$root/wt-busy" -b busy origin/main 2>/dev/null
printf 'ahead\n' >> "$root/wt-busy/README.md"
git -C "$root/wt-busy" commit -qam "ahead"
git -C "$repo" worktree add -q "$root/wt-held" -b held origin/main 2>/dev/null
git -C "$repo" worktree lock "$root/wt-held" --reason "in use" 2>/dev/null
out="$(run "$repo")"
if [ -z "$out" ]; then
  ok "13 · registry non-empty but nothing actionable (1 in-progress + 1 locked) -> silent"
else
  bad "13 · nothing actionable -> silent" "emitted: $(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | head -3)"
fi
git -C "$repo" worktree unlock "$root/wt-held" 2>/dev/null

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
