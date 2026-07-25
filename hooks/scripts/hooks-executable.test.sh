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

printf '\n%s executable, %s not\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
