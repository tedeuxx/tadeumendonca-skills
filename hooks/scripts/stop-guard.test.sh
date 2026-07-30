#!/usr/bin/env bash
# Tests for stop-guard.sh — the Stop hook that refuses to end a turn on parked work.
#
# `gh` and `git` are both stubbed on PATH so the suite is hermetic: no network, no auth, and no
# dependence on what happens to be open or checked out. The stubs' canned answers are the variables the
# guard reads, which is exactly what has to vary between cases.
#
# THE LOOP-GUARD CASE CARRIES MORE WEIGHT THAN THE REST COMBINED. A blocked Stop makes the agent
# continue and then Stop again; if `stop_hook_active` were ignored the session could never end, and this
# guard would become the wedge it exists to prevent. That case is asserted first and deliberately.
#
# Every other failure mode must end in ALLOW. This enforces loop discipline, not the irreversible floor.
#
# Run: bash hooks/scripts/stop-guard.test.sh

set -uo pipefail

GUARD="$(cd "$(dirname "$0")" && pwd)/stop-guard.sh"
STUBDIR="$(mktemp -d)"
REAL_PATH="$PATH"

pass=0
fail=0

# $1 = JSON that `gh pr list` prints.
stub_gh() {
  cat > "$STUBDIR/gh" <<STUB
#!/usr/bin/env bash
printf '%s' '$1'
STUB
  chmod +x "$STUBDIR/gh"
  PATH="$STUBDIR:$REAL_PATH"
}

# $1 = current branch name, $2 = `git status --porcelain` output (empty means clean),
# $3 = non-empty makes `status` FAIL (exit 128, no output) while `rev-parse` still succeeds. That
# asymmetry is the realistic one: rev-parse reads .git/HEAD, status walks the worktree.
stub_git() {
  cat > "$STUBDIR/git" <<STUB
#!/usr/bin/env bash
args="\$*"
case "\$args" in
  *"rev-parse --abbrev-ref"*) printf '%s' '$1' ;;
  *"status --porcelain"*)     [ -n '${3-}' ] && exit 128; printf '%s' '${2-}' ;;
  *) exit 1 ;;
esac
STUB
  chmod +x "$STUBDIR/git"
  PATH="$STUBDIR:$REAL_PATH"
}

# $1 = want (BLOCK|ALLOW), $2 = description, $3 = the Stop payload on stdin.
check() {
  want="$1"; desc="$2"; payload="$3"
  out=$(printf '%s' "$payload" | bash "$GUARD")
  if printf '%s' "$out" | grep -q '"block"'; then got=BLOCK; else got=ALLOW; fi
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); printf 'ok    %-6s %s\n' "$got" "$desc"
  else
    fail=$((fail + 1)); printf 'FAIL  want=%s got=%s  %s\n' "$want" "$got" "$desc"
  fi
}

# The shape the guard is written for: one open PR, sitting on its branch, nothing uncommitted.
PARKED='[{"number":42,"title":"feat: something","headRefName":"feat/x"}]'

echo "--- the loop guard: a re-entered Stop must ALWAYS pass ---"
stub_gh "$PARKED"; stub_git "feat/x" ""
check ALLOW "stop_hook_active — the second pass after a block" '{"stop_hook_active":true}'
# The same inputs WITHOUT the flag must block, or the case above proves nothing: it would pass for the
# wrong reason, and a guard that never blocks needs no loop guard at all.
check BLOCK "same state, first pass — proves the case above is not vacuous" '{"stop_hook_active":false}'

echo "--- it blocks only when the work is genuinely parked ---"
stub_gh "$PARKED"; stub_git "feat/x" ""
check BLOCK "on the open PR's branch, clean tree" '{}'

stub_gh "$PARKED"; stub_git "feat/other" ""
check ALLOW "on a DIFFERENT branch — something else was started" '{}'

stub_gh "$PARKED"; stub_git "feat/x" " M src/app.ts"
check ALLOW "on the branch but the tree is dirty — mid-work" '{}'

stub_gh '[]'; stub_git "feat/x" ""
check ALLOW "no open PR of mine" '{}'

# The fail-CLOSED path the first version had: a failing `status` produced no output, empty read as
# "clean", and the guard blocked on a state it could not observe. rev-parse still works, so this is
# not covered by the "no git" case.
stub_gh "$PARKED"; stub_git "feat/x" "" "fail"
check ALLOW "git status FAILS while rev-parse works — cannot observe is not clean" '{}'

echo "--- fail open, every way it can fail ---"
stub_gh "$PARKED"; stub_git "" ""
check ALLOW "git cannot name the branch" '{}'

stub_gh 'not json at all'; stub_git "feat/x" ""
check ALLOW "gh returns something unparseable" '{}'

stub_gh '{"message":"Not Found"}'; stub_git "feat/x" ""
check ALLOW "gh returns an OBJECT — length would count keys, not PRs" '{}'

stub_gh "$PARKED"; stub_git "feat/x" ""
check ALLOW "empty payload on stdin" ''

PATH="$STUBDIR:$REAL_PATH"; rm -f "$STUBDIR/gh"
check ALLOW "no gh on PATH" '{}'

stub_gh "$PARKED"; rm -f "$STUBDIR/git"
check ALLOW "no git on PATH" '{}'

echo "--- the denial has to be actionable ---"
stub_gh "$PARKED"; stub_git "feat/x" ""
out=$(printf '%s' '{}' | bash "$GUARD")
for want in "feat/x" "#42"; do
  if printf '%s' "$out" | grep -q -- "$want"; then
    pass=$((pass + 1)); printf 'ok    NAMES  the denial names %s\n' "$want"
  else
    fail=$((fail + 1)); printf 'FAIL         the denial does not name %s\n' "$want"
  fi
done

PATH="$REAL_PATH"
rm -rf "$STUBDIR"
echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
