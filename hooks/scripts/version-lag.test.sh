#!/usr/bin/env bash
# Tests for version-lag.sh — the SessionStart signal that names the RUNNING plugin version.
#
# `gh` is stubbed and CLAUDE_PLUGIN_ROOT points at a temporary fake install, so the suite is hermetic:
# no network, and no dependence on which version happens to be installed on this machine.
#
# THE CASE THAT CARRIES THE WEIGHT is "silent when current". A signal that fires every session stops
# being read, and then it is worse than absent — it trains the reader to skip the one line that will
# eventually matter. It is asserted alongside a case with the same inputs but a lagging version, or
# "silent" would pass for a script that never speaks at all.
#
# Run: bash hooks/scripts/version-lag.test.sh

set -uo pipefail

HOOK="$(cd "$(dirname "$0")" && pwd)/version-lag.sh"
STUBDIR="$(mktemp -d)"
FAKEROOT="$(mktemp -d)"
REAL_PATH="$PATH"

pass=0
fail=0

# $1 = the version the INSTALLED manifest declares. Empty removes the manifest entirely.
fake_install() {
  rm -rf "${FAKEROOT:?}/.claude-plugin"
  if [ -n "${1-}" ]; then
    mkdir -p "$FAKEROOT/.claude-plugin"
    printf '{"name":"tadeumendonca-skills","version":"%s"}' "$1" > "$FAKEROOT/.claude-plugin/plugin.json"
  fi
}

# $1 = the tag `gh release view` prints. Empty makes gh fail, as it does with no network or no auth.
stub_gh() {
  if [ -n "${1-}" ]; then
    cat > "$STUBDIR/gh" <<STUB
#!/usr/bin/env bash
printf '%s' '$1'
STUB
  else
    cat > "$STUBDIR/gh" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
  fi
  chmod +x "$STUBDIR/gh"
  PATH="$STUBDIR:$REAL_PATH"
}

# $1 = want (SPEAKS|SILENT), $2 = description.
check() {
  want="$1"; desc="$2"
  out=$(CLAUDE_PLUGIN_ROOT="$FAKEROOT" bash "$HOOK" 2>/dev/null)
  if [ -n "$out" ]; then got=SPEAKS; else got=SILENT; fi
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); printf 'ok    %-7s %s\n' "$got" "$desc"
  else
    fail=$((fail + 1)); printf 'FAIL  want=%s got=%s  %s\n' "$want" "$got" "$desc"
  fi
}

echo "--- it speaks only when the session is BEHIND ---"
fake_install "0.4.15"; stub_gh "v0.4.19"
check SPEAKS "installed 0.4.15, published 0.4.19"

fake_install "0.4.19"; stub_gh "v0.4.19"
check SILENT "installed equals published — the common case must say nothing"

# Developing the plugin itself: the checkout is ahead of the last release. Not lag, must not report.
fake_install "0.4.20"; stub_gh "v0.4.19"
check SILENT "installed AHEAD of published — mid-slice in this repo"

# Numeric, not lexical: 0.4.9 < 0.4.19, but a string compare says otherwise.
fake_install "0.4.9"; stub_gh "v0.4.19"
check SPEAKS "0.4.9 vs 0.4.19 — sorts numerically, not as strings"

fake_install "0.4.19"; stub_gh "0.4.19"
check SILENT "a tag published without the v prefix still compares equal"

echo "--- silent on every way it can fail ---"
fake_install "0.4.15"; stub_gh ""
check SILENT "gh fails — no network, no auth"

fake_install ""; stub_gh "v0.4.19"
check SILENT "no manifest in the installed root"

fake_install "0.4.15"; stub_gh "v0.4.19"
out=$(CLAUDE_PLUGIN_ROOT="" bash "$HOOK" 2>/dev/null)
if [ -z "$out" ]; then
  pass=$((pass + 1)); printf 'ok    SILENT  CLAUDE_PLUGIN_ROOT unset\n'
else
  fail=$((fail + 1)); printf 'FAIL  want=SILENT got=SPEAKS  CLAUDE_PLUGIN_ROOT unset\n'
fi

mkdir -p "$FAKEROOT/.claude-plugin"
printf 'not json' > "$FAKEROOT/.claude-plugin/plugin.json"
stub_gh "v0.4.19"
check SILENT "the manifest is not JSON"

echo "--- what it says has to be actionable ---"
fake_install "0.4.15"; stub_gh "v0.4.19"
out=$(CLAUDE_PLUGIN_ROOT="$FAKEROOT" bash "$HOOK" 2>/dev/null)
for want in "0.4.15" "0.4.19"; do
  if printf '%s' "$out" | grep -q -- "$want"; then
    pass=$((pass + 1)); printf 'ok    NAMES   it names %s\n' "$want"
  else
    fail=$((fail + 1)); printf 'FAIL          it does not name %s\n' "$want"
  fi
done
if printf '%s' "$out" | jq -e '.hookSpecificOutput.hookEventName == "SessionStart"' >/dev/null 2>&1; then
  pass=$((pass + 1)); printf 'ok    SHAPE   valid SessionStart JSON\n'
else
  fail=$((fail + 1)); printf 'FAIL          not valid SessionStart JSON\n'
fi

PATH="$REAL_PATH"
rm -rf "$STUBDIR" "$FAKEROOT"
echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
