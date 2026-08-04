#!/usr/bin/env bash
# Tests that every hook script `hooks.json` invokes is committed EXECUTABLE (git mode 100755).
#
# Why this exists as its own gate: the logic suites (permission-guard.test.sh, wip-guard.test.sh)
# run each guard through `bash "$GUARD"`, so they pass whether or not the file carries the exec bit.
# But the harness invokes hooks by BARE PATH — `"${CLAUDE_PLUGIN_ROOT}"/hooks/scripts/<name>.sh` —
# which needs the bit. A script committed 100644 (as wip-guard.sh and session-wip.sh once were) dies
# at runtime with "Permission denied" while every logic test stays green: a gate that verified the
# behaviour but not the installed form. This asserts the form.
#
# It checks the GIT-TRACKED mode, not the working-tree bit: the defect is what ships (the committed
# mode, which the marketplace tarball preserves), and a local `chmod +x` that was never committed
# would mask it.
#
# ── SCOPE, STATED BECAUSE THE SUMMARY LINE WAS MISREAD (2026-08-04) ──────────────────────────────
# The set under test is DERIVED from hooks.json — every script referenced as a `command` — not a
# hardcoded list, so it grows automatically when a hook is added. It is therefore SMALLER than the
# number of `.sh` files in this directory, and that is correct rather than a gap:
#
#   IN SCOPE      the scripts the HARNESS invokes by bare path. They need the exec bit or they die at
#                 runtime with "Permission denied".
#   OUT OF SCOPE  the `*.test.sh` suites. Nothing invokes them by bare path — CI and humans run them as
#                 `bash <path>`, which ignores the bit entirely. Requiring it would assert a property
#                 no caller depends on, and three of the five carry it only by accident of creation.
#
# A review read the old summary — a bare "4 executable, 0 not" — as one short of the scripts present,
# which was a reasonable reading of a number with no scope attached. The fix is at the summary line:
# it now names its own denominator and where the denominator came from. A count that cannot be
# misread beats a comment explaining that it was misread.
#
# Run: bash hooks/scripts/hooks-executable.test.sh

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOKS_JSON="$ROOT/hooks/hooks.json"

pass=0
fail=0

# Every script referenced as a `command`, across every event array in hooks.json.
scripts=$(jq -r '.hooks[][].hooks[].command' "$HOOKS_JSON" \
  | sed -E 's/^"?\$\{CLAUDE_PLUGIN_ROOT\}"?\///' \
  | awk '{print $1}' \
  | sort -u)

if [ -z "$scripts" ]; then
  echo "FAIL  no command scripts found in hooks.json — the parser or the file changed shape"
  exit 1
fi

while IFS= read -r rel; do
  mode=$(git -C "$ROOT" ls-files -s "$rel" | awk '{print $1}')
  if [ -z "$mode" ]; then
    fail=$((fail + 1))
    printf 'FAIL  %-32s referenced by hooks.json but not tracked by git\n' "$rel"
  elif [ "$mode" = "100755" ]; then
    pass=$((pass + 1))
    printf 'ok    %-32s %s\n' "$rel" "$mode"
  else
    fail=$((fail + 1))
    printf 'FAIL  %-32s committed %s, must be 100755 (executable)\n' "$rel" "$mode"
  fi
done <<< "$scripts"

total=$((pass + fail))
printf '\n%s of %s hook scripts referenced by hooks.json are committed executable, %s not\n' \
  "$pass" "$total" "$fail"
printf '(test suites are out of scope by design — nothing invokes them by bare path; see the header)\n'
[ "$fail" -eq 0 ]
