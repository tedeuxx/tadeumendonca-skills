#!/usr/bin/env bash
# Tests for wip-guard.sh — the file-overlap gate at the PR boundary.
#
# `gh` and `git` are stubbed on PATH so the suite is hermetic: no network, no auth, no
# dependence on what happens to be open in a real repo or checked out in this one. What
# varies between cases is the canned answer, which is exactly the variable the guard reads.
#
# The case that matters most is DISJOINT → ALLOW. That is the one the previous
# count-based guard got wrong, and getting it wrong is invisible: a denial reads as the
# rule working. So it is asserted first and it is asserted with two open PRs, because
# "allowed because the queue was empty" would pass a weaker test for the wrong reason.
#
# The fail-open cases carry real weight. This guard enforces loop discipline, not the
# irreversible floor, so every way it can fail must end in ALLOW — a check that wedges
# the loop is worse than the queue it was written to prevent.
#
# Run: bash hooks/scripts/wip-guard.test.sh

set -uo pipefail

GUARD="$(cd "$(dirname "$0")" && pwd)/wip-guard.sh"
STUBDIR="$(mktemp -d)"
REAL_PATH="$PATH"

pass=0
fail=0

# Writes a fake `gh` that dispatches on its arguments:
#   $1 — what `pr list` prints (the open PRs)
#   $2 — what `pr view <n> --json files` prints (one path per line), for EVERY pr
stub_gh() {
  cat > "$STUBDIR/gh" <<STUB
#!/usr/bin/env bash
args="\$*"
case "\$args" in
  *"repo view"*)  printf 'main' ;;
  *"pr view"*)    printf '%s' '$2' ;;
  *"pr list"*)    printf '%s' '$1' ;;
  *)              exit 0 ;;
esac
STUB
  chmod +x "$STUBDIR/gh"
  PATH="$STUBDIR:$REAL_PATH"
}

# Writes a fake `git` whose `diff --name-only` prints $1 — the files THIS branch brings.
stub_git() {
  cat > "$STUBDIR/git" <<STUB
#!/usr/bin/env bash
args="\$*"
case "\$args" in
  *"merge-base"*) printf 'abc1234' ;;
  *"diff"*)       printf '%s' '$1' ;;
  *)              exit 0 ;;
esac
STUB
  chmod +x "$STUBDIR/git"
}

check() {
  want="$1"
  desc="$2"
  cmd="$3"
  out=$(printf '%s' "$cmd" | jq -R '{tool_input:{command:.}}' | bash "$GUARD")
  if printf '%s' "$out" | grep -q '"deny"'; then got=DENY; else got=ALLOW; fi
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1))
    printf 'ok    %-6s %s\n' "$got" "$desc"
  else
    fail=$((fail + 1))
    printf 'FAIL  want=%s got=%s  %s\n      cmd: %s\n' "$want" "$got" "$desc" "$cmd"
  fi
}

ONE='[{"number":65,"title":"chore(deps): bump the group"}]'
TWO='[{"number":65,"title":"bump"},{"number":45,"title":"harden"}]'
NONE='[]'

THEIRS='docs/adr/README.md
CLAUDE.md'
MINE_DISJOINT='hooks/scripts/wip-guard.sh
hooks/scripts/wip-guard.test.sh'
MINE_OVERLAPS='CLAUDE.md
apps/fed/src/App.tsx'

echo "--- DISJOINT slices are allowed: the case the old count-based guard got wrong ---"
stub_gh "$TWO" "$THEIRS"
stub_git "$MINE_DISJOINT"
check ALLOW "two open PRs, no shared file"   "gh pr create --title x --body y"
check ALLOW "disjoint, behind -R"            "gh -R owner/repo pr create --title x"

echo "--- OVERLAP is denied: that is the PR that would go stale ---"
stub_gh "$ONE" "$THEIRS"
stub_git "$MINE_OVERLAPS"
check DENY  "one open PR sharing a file"     "gh pr create --title x --body y"
check DENY  "overlap, behind --repo"         "gh --repo owner/repo pr create --title x"
stub_gh "$TWO" "$THEIRS"
check DENY  "two open PRs, one overlaps"     "gh pr create --fill"

echo "--- the denial names what to look at, or the author works around it ---"
stub_gh "$ONE" "$THEIRS"
stub_git "$MINE_OVERLAPS"
out=$(printf '%s' "gh pr create --title x" | jq -R '{tool_input:{command:.}}' | bash "$GUARD")
if printf '%s' "$out" | grep -q 'CLAUDE.md'; then
  pass=$((pass + 1)); printf 'ok    %-6s %s\n' "NAMES" "the overlapping FILE is named"
else
  fail=$((fail + 1)); printf 'FAIL  the denial does not name the overlapping file\n'
fi
if printf '%s' "$out" | grep -q '#65'; then
  pass=$((pass + 1)); printf 'ok    %-6s %s\n' "NAMES" "the colliding PR is named"
else
  fail=$((fail + 1)); printf 'FAIL  the denial does not name the colliding PR\n'
fi

echo "--- an empty queue lets the slice open ---"
stub_gh "$NONE" "$THEIRS"
stub_git "$MINE_OVERLAPS"
check ALLOW "no open PRs"                    "gh pr create --title x --body y"

echo '--- only "gh pr create" is gated; the rest of the loop is untouched ---'
stub_gh "$ONE" "$THEIRS"
stub_git "$MINE_OVERLAPS"
check ALLOW "viewing a PR"                   "gh pr view 65"
check ALLOW "listing PRs"                    "gh pr list --state open"
check ALLOW "merging a PR"                   "gh pr merge 65 --merge"
check ALLOW "creating an ISSUE, not a PR"    "gh issue create --title x"
check ALLOW "an unrelated command"           "git status --short"
check ALLOW "npm, nowhere near gh"           "npm --prefix apps/fed run test"
check ALLOW "the word create in a message"   "git commit -m 'gh pr create notes'"

echo "--- every failure mode ends in ALLOW: this must never wedge the loop ---"
stub_gh "" "$THEIRS"
stub_git "$MINE_OVERLAPS"
check ALLOW "gh returns nothing"             "gh pr create --title x"
stub_gh 'not json at all' "$THEIRS"
check ALLOW "gh returns garbage"             "gh pr create --title x"
stub_gh '{"unexpected":"shape"}' "$THEIRS"
check ALLOW "gh returns the wrong shape"     "gh pr create --title x"
stub_gh "$ONE" ""
stub_git "$MINE_OVERLAPS"
check ALLOW "the open PR's files unreadable" "gh pr create --title x"
stub_gh "$ONE" "$THEIRS"
stub_git ""
check ALLOW "this branch's diff unreadable"  "gh pr create --title x"
# The "gh is not installed" branch is deliberately NOT tested here. Exercising it means
# removing gh from PATH, and any PATH narrow enough to hide gh also hides bash, jq and
# grep — the harness dies and the case "passes" for the wrong reason, which is how it
# first appeared to pass. It is one `command -v gh || exit 0` line, read rather than
# asserted; a fake assertion is worse than an honest gap. The same holds for git.
PATH="$REAL_PATH"

rm -rf "$STUBDIR"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
