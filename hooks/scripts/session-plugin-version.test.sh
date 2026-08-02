#!/usr/bin/env bash
# session-plugin-version.test.sh — does the version notice fire when it should, stay silent
# when it should, and say the TRUE thing about where its reference came from?
#
# Mutation-checked: every assertion below was verified to fail against a deliberately broken
# version of the hook, because an assertion that cannot fail is worse than none — which is a
# defect this repo has actually shipped, and is why this file exists at all rather than the
# hook being "obviously correct".
#
# The hook reads $HOME for the marketplace manifest and $CLAUDE_PROJECT_DIR for the source
# one, so both are pointed at a temp tree. Nothing here touches the real installation.

set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/session-plugin-version.sh"
pass=0
fail=0

ok()   { printf 'ok    %s\n' "$1"; pass=$((pass + 1)); }
bad()  { printf 'FAIL  %s\n     %s\n' "$1" "$2"; fail=$((fail + 1)); }

# Build a throwaway HOME + project tree. Passing '' for either version omits that manifest,
# which is how the "not installed" and "consuming repo" cases are expressed.
setup() {
  root="$(mktemp -d)"
  if [ -n "$1" ]; then
    mkdir -p "$root/home/.claude/plugins/marketplaces/tadeumendonca/.claude-plugin"
    printf '{"name":"tadeumendonca-skills","version":"%s"}\n' "$1" \
      > "$root/home/.claude/plugins/marketplaces/tadeumendonca/.claude-plugin/plugin.json"
  fi
  if [ -n "$2" ]; then
    mkdir -p "$root/proj/.claude-plugin"
    printf '{"name":"tadeumendonca-skills","version":"%s"}\n' "$2" \
      > "$root/proj/.claude-plugin/plugin.json"
  else
    mkdir -p "$root/proj"
  fi
}

# Run the hook against the temp tree. PATH is stripped of `gh` so the release-API fallback
# cannot reach the network from a test — a suite whose result depends on GitHub being up is
# testing GitHub.
run_hook() {
  ( export HOME="$root/home"
    export CLAUDE_PROJECT_DIR="$root/proj"
    export PATH="$root/nogh:/usr/bin:/bin"
    mkdir -p "$root/nogh"
    bash "$HOOK" 2>/dev/null )
}

check() { # label · installed · source · matcher(present|absent) · needle
  setup "$2" "$3"
  out="$(run_hook)"
  case "$4" in
    present)
      case "$out" in
        *"$5"*) ok "$1" ;;
        *)      bad "$1" "expected to find '$5' in output; got: ${out:-<empty>}" ;;
      esac ;;
    absent)
      case "$out" in
        *"$5"*) bad "$1" "expected NOT to find '$5'; got: $out" ;;
        *)      ok "$1" ;;
      esac ;;
    empty)
      if [ -z "$out" ]; then ok "$1"; else bad "$1" "expected silence; got: $out"; fi ;;
  esac
  rm -rf "$root"
}

echo '--- it fires when the install is behind, which is the failure it exists for (#93) ---'
check 'reports both versions'            0.4.21 0.4.24 present '0.4.21'
check 'names the reference version'      0.4.21 0.4.24 present '0.4.24'
check 'says the published side is ahead' 0.4.21 0.4.24 present 'is AHEAD of the install'
check 'warns about stale subagents'      0.4.21 0.4.24 present 'resolves to its OLD definition'
check 'emits a SessionStart event'       0.4.21 0.4.24 present '"hookEventName": "SessionStart"'

echo '--- version comparison is numeric, not lexical ---'
# The whole point: 0.4.9 vs 0.4.21 is where a string compare silently inverts the verdict and
# tells the session it is up to date while it runs a stale build.
check 'a two-digit patch beats a one-digit one' 0.4.9 0.4.21 present 'is AHEAD of the install'
check 'and the reverse direction too'           0.4.21 0.4.9 present 'The INSTALL is ahead'

echo '--- the two directions are distinct actions, not one message ---'
check 'install-ahead tells you to pull'     0.4.24 0.4.21 present 'Pull before changing a hook'
check 'install-ahead does NOT say restart'  0.4.24 0.4.21 absent  'Restarting the session'

echo '--- silence is the correct output, and must be real silence ---'
check 'identical versions say nothing'   0.4.24 0.4.24 empty ''
check 'no marketplace install: nothing'  ''     0.4.24 empty ''
# In a consuming repo with no `gh`, there is no reference to compare against. Silence, not a
# guess — a notice built on an unknown reference is worse than none.
check 'no source and no gh: nothing'     0.4.21 ''     empty ''

echo '--- it must never block a session ---'
setup 0.4.21 0.4.24
run_hook >/dev/null
[ $? -eq 0 ] && ok 'exits 0 when it fires' || bad 'exits 0 when it fires' "exit was $?"
rm -rf "$root"

setup 0.4.24 0.4.24
run_hook >/dev/null
[ $? -eq 0 ] && ok 'exits 0 when silent' || bad 'exits 0 when silent' "exit was $?"
rm -rf "$root"

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
