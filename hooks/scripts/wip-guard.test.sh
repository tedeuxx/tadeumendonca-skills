#!/usr/bin/env bash
# Tests for wip-guard.sh — the WIP = 1 gate at the PR boundary.
#
# `gh` is stubbed on PATH so the suite is hermetic: no network, no auth, no dependence
# on what happens to be open in a real repo. The stub's canned answer is what varies
# between cases, which is exactly the variable the guard reads.
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

# Writes a fake `gh` whose `pr list` prints $1.
stub_gh() {
  cat > "$STUBDIR/gh" <<STUB
#!/usr/bin/env bash
printf '%s' '$1'
STUB
  chmod +x "$STUBDIR/gh"
  PATH="$STUBDIR:$REAL_PATH"
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

echo "--- a queue already exists: opening another PR is blocked ---"
stub_gh "$ONE"
check DENY  "one open PR, plain create"      "gh pr create --title x --body y"
check DENY  "one open PR, behind -R"         "gh -R owner/repo pr create --title x"
check DENY  "one open PR, behind --repo"     "gh --repo owner/repo pr create --title x"
stub_gh "$TWO"
check DENY  "two open PRs"                   "gh pr create --fill"

echo "--- an empty queue lets the slice open ---"
stub_gh "$NONE"
check ALLOW "no open PRs"                    "gh pr create --title x --body y"
check ALLOW "no open PRs, behind -R"         "gh -R owner/repo pr create --title x"

echo '--- only "gh pr create" is gated; the rest of the loop is untouched ---'
stub_gh "$ONE"
check ALLOW "viewing a PR"                   "gh pr view 65"
check ALLOW "listing PRs"                    "gh pr list --state open"
check ALLOW "merging a PR"                   "gh pr merge 65 --merge"
check ALLOW "creating an ISSUE, not a PR"    "gh issue create --title x"
check ALLOW "an unrelated command"           "git status --short"
check ALLOW "npm, nowhere near gh"           "npm --prefix apps/fed run test"
check ALLOW "the word create in a message"   "git commit -m 'gh pr create notes'"

echo "--- every failure mode ends in ALLOW: this must never wedge the loop ---"
stub_gh ""
check ALLOW "gh returns nothing"             "gh pr create --title x"
stub_gh 'not json at all'
check ALLOW "gh returns garbage"             "gh pr create --title x"
stub_gh '{"unexpected":"shape"}'
check ALLOW "gh returns the wrong shape"     "gh pr create --title x"
# The "gh is not installed" branch is deliberately NOT tested here. Exercising it means
# removing gh from PATH, and any PATH narrow enough to hide gh also hides bash, jq and
# grep — the harness dies and the case "passes" for the wrong reason, which is how it
# first appeared to pass. It is one `command -v gh || exit 0` line, read rather than
# asserted; a fake assertion is worse than an honest gap.
PATH="$REAL_PATH"

rm -rf "$STUBDIR"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
