#!/usr/bin/env bash
# session-plugin-version.test.sh — does the version notice fire when it should, stay silent
# when it should, and say the TRUE thing about where its reference came from?
#
# Mutation-checked: every assertion below was verified to fail against a deliberately broken
# version of the hook, because an assertion that cannot fail is worse than none — which is a
# defect this repo has actually shipped, and is why this file exists at all rather than the
# hook being "obviously correct".
#
# THE FIXTURE CHANGED WITH #370, and the change is the point rather than plumbing. The hook used
# to read the marketplace clone, so the old fixture wrote a manifest under
# `$HOME/.claude/plugins/marketplaces/…` and ran the hook straight out of the repo. That fixture
# could not have caught the defect #370 records: it asserted the behaviour of the wrong file.
#
# Now the hook derives the running build from `$0`, so the test COPIES it to a versioned,
# build-shaped temp path and invokes it from there:
#
#     $root/build/<version>/hooks/scripts/session-plugin-version.sh
#     $root/build/<version>/.claude-plugin/plugin.json      ← the version under test
#
# That is a faithful model of how the harness actually invokes it — `hooks/hooks.json` registers
# every hook as `"${CLAUDE_PLUGIN_ROOT}"/hooks/scripts/<name>.sh`, an interpolated absolute path
# into one cached build — and it is why the "running build" version is now a fixture parameter
# rather than a file in a fake $HOME.
#
# $HOME still points at the temp tree, because the CROSS-PROJECT arm reads
# `$HOME/.claude/plugins/installed_plugins.json`. Nothing here touches the real installation.

set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/session-plugin-version.sh"
pass=0
fail=0

ok()   { printf 'ok    %s\n' "$1"; pass=$((pass + 1)); }
bad()  { printf 'FAIL  %s\n     %s\n' "$1" "$2"; fail=$((fail + 1)); }

# Build a throwaway build tree + project tree + $HOME.
#   $1 — the version of the BUILD the hook is copied into. '' means "no manifest beside the
#        build", i.e. the hook was invoked from somewhere that is not a plugin tree.
#   $2 — the version in the project's own source manifest. '' omits it (the consuming-repo case).
#   $3 — optional: literal JSON for installed_plugins.json. '' omits the registry entirely.
setup() {
  root="$(mktemp -d)"
  build="$root/build/x"
  mkdir -p "$build/hooks/scripts"
  cp "$HOOK" "$build/hooks/scripts/session-plugin-version.sh"
  if [ -n "$1" ]; then
    mkdir -p "$build/.claude-plugin"
    printf '{"name":"tadeumendonca-skills","version":"%s"}\n' "$1" \
      > "$build/.claude-plugin/plugin.json"
  fi
  if [ -n "$2" ]; then
    mkdir -p "$root/proj/.claude-plugin"
    printf '{"name":"tadeumendonca-skills","version":"%s"}\n' "$2" \
      > "$root/proj/.claude-plugin/plugin.json"
  else
    mkdir -p "$root/proj"
  fi
  mkdir -p "$root/home/.claude/plugins"
  if [ -n "${3:-}" ]; then
    printf '%s\n' "$3" > "$root/home/.claude/plugins/installed_plugins.json"
  fi
}

# Run the hook FROM THE BUILD PATH, which is what makes `$0` meaningful. PATH is stripped of `gh`
# so the release-API fallback cannot reach the network from a test — a suite whose result depends
# on GitHub being up is testing GitHub.
run_hook() {
  ( export HOME="$root/home"
    export CLAUDE_PROJECT_DIR="$root/proj"
    mkdir -p "$root/nogh"
    export PATH="$root/nogh:/usr/bin:/bin"
    bash "$build/hooks/scripts/session-plugin-version.sh" 2>/dev/null )
}

check() { # label · build version · source version · matcher(present|absent|empty) · needle · [registry json]
  setup "$2" "$3" "${6:-}"
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

echo '--- it fires when the running build is behind, which is the failure it exists for (#93) ---'
check 'reports both versions'            0.4.21 0.4.24 present '0.4.21'
check 'names the reference version'      0.4.21 0.4.24 present '0.4.24'
check 'says the published side is ahead' 0.4.21 0.4.24 present 'is AHEAD of the build this session is running'
check 'warns about stale subagents'      0.4.21 0.4.24 present 'resolves to its OLD definition'
check 'emits a SessionStart event'       0.4.21 0.4.24 present '"hookEventName": "SessionStart"'

echo '--- the version reported is the BUILD it runs from, not any other manifest (#370) ---'
# THE ARM THE OLD FIXTURE COULD NOT HAVE HAD. It asserts the label AND that the number came out of
# the build directory the hook was invoked from. Mutate: point SELF_MANIFEST back at the marketplace
# clone and this goes red while every other arm above still passes — which is precisely how the
# defect survived.
check 'labels it as the running build'   0.4.21 0.4.24 present 'running build (this session): 0.4.21'
check 'no longer calls it "marketplace"' 0.4.21 0.4.24 absent  'installed (marketplace)'
# The build's own manifest is the ONLY source of that number: with the manifest absent from the
# build tree there is nothing to report, and the hook must not substitute another file.
check 'no build manifest: silent, never "up to date"' '' 0.4.24 empty ''

echo '--- the remedy it prints must be one that works (#370) ---'
# The old text said restarting after a marketplace refresh made the merged version effective. It
# does not: the refresh moves the shared clone and leaves the per-scope install record pinned.
check 'prescribes the marketplace refresh' 0.4.21 0.4.24 present '/plugin marketplace update'
check 'and the install-record move'        0.4.21 0.4.24 present '/plugin update tadeumendonca-skills@tadeumendonca'
check 'says the refresh alone is not it'   0.4.21 0.4.24 present 'refreshing the clone alone leaves the record pinned'

echo '--- version comparison is numeric, not lexical ---'
# The whole point: 0.4.9 vs 0.4.21 is where a string compare silently inverts the verdict and
# tells the session it is up to date while it runs a stale build.
check 'a two-digit patch beats a one-digit one' 0.4.9 0.4.21 present 'is AHEAD of the build'
check 'and the reverse direction too'           0.4.21 0.4.9 present 'The BUILD is ahead'

echo '--- the two directions are distinct actions, not one message ---'
check 'build-ahead tells you to pull'      0.4.24 0.4.21 present 'Pull before changing a hook'
check 'build-ahead does NOT say restart'   0.4.24 0.4.21 absent  '/plugin marketplace update'

echo '--- silence is the correct output, and must be real silence ---'
check 'identical versions say nothing'   0.4.24 0.4.24 empty ''
# In a consuming repo with no `gh`, there is no reference to compare against. Silence, not a
# guess — a notice built on an unknown reference is worse than none.
check 'no source and no gh: nothing'     0.4.21 ''     empty ''

echo '--- the cross-project arm: the projects nobody opens (#370) ---'
# This is the half that matters. The primary arm above reports from inside a stale session; a
# project that is never opened never starts one, so only this arm can see it.
REG_STALE='{"version":2,"plugins":{"tadeumendonca-skills@tadeumendonca":[
  {"scope":"project","projectPath":"/tmp/other-project","version":"1.0.16"},
  {"scope":"user","version":"0.4.24"}]}}'
REG_CLEAN='{"version":2,"plugins":{"tadeumendonca-skills@tadeumendonca":[
  {"scope":"project","projectPath":"/tmp/other-project","version":"0.4.24"},
  {"scope":"user","version":"0.4.24"}]}}'
# Every PROJECT record matches; only the USER record is stale. This arm is what separates "reports
# stale project records" from "reports stale records" — the user record is the running session's own
# concern and arm 1 already owns it, so reporting it here would double-report and, worse, name no
# path the reader could act on.
REG_USER_STALE='{"version":2,"plugins":{"tadeumendonca-skills@tadeumendonca":[
  {"scope":"project","projectPath":"/tmp/other-project","version":"0.4.24"},
  {"scope":"user","version":"1.0.16"}]}}'
REG_SCHEMA='{"version":3,"plugins":{"tadeumendonca-skills@tadeumendonca":[
  {"scope":"project","projectPath":"/tmp/other-project","version":"1.0.16"}]}}'
REG_SCOPE='{"version":2,"plugins":{"tadeumendonca-skills@tadeumendonca":[
  {"scope":"managed","projectPath":"/tmp/other-project","version":"1.0.16"},
  {"scope":"project","projectPath":"/tmp/third","version":"1.0.16"}]}}'

check 'names the stale project path'   0.4.24 0.4.24 present '/tmp/other-project' "$REG_STALE"
check 'names its pinned version'       0.4.24 0.4.24 present '1.0.16'             "$REG_STALE"
check 'prints the move command'        0.4.24 0.4.24 present 'claude plugin update tadeumendonca-skills@tadeumendonca --scope project -y' "$REG_STALE"
# The NEGATIVE half — without it, "reports a stale project" would pass for an arm that reports
# every project unconditionally.
check 'silent when every record matches' 0.4.24 0.4.24 empty '' "$REG_CLEAN"
check 'a stale user-scope record is not reported here'  0.4.24 0.4.24 empty '' "$REG_USER_STALE"
# And it must be silent when the running build itself is fine and there is no registry at all.
check 'no registry: nothing'           0.4.24 0.4.24 empty ''

echo '--- three cases that must end in "could not determine", never in a clean bill of health ---'
check 'unknown schema is reported as skipped' 0.4.24 0.4.24 present 'schema version this hook has not read' "$REG_SCHEMA"
check 'unknown schema reports nothing else'   0.4.24 0.4.24 absent  '/tmp/other-project'                    "$REG_SCHEMA"
check 'an unrecognised scope refuses to conclude' 0.4.24 0.4.24 present 'An unrecognised scope may be in play' "$REG_SCOPE"
# THE SHARPEST ARM IN THIS BLOCK: with a `managed` record present, the hook must NOT go on to report
# the `project` record it does understand. A partial answer presented as a complete one is the exact
# failure this hook exists to prevent. Mutate: drop the SCOPE branch and let the filter run → red.
check 'and does not report the records it recognises' 0.4.24 0.4.24 absent '/tmp/third'                     "$REG_SCOPE"

echo '--- the dependency probe: is the permission guard able to speak at all? ---'
# ARRANGING "jq IS ABSENT" HONESTLY, because the alternative is a case that passes for the wrong
# reason — a failure this batch produced twice already.
#
# The rejected shortcuts, and why each is dishonest:
#   · PATH="" — strips `sed`, `awk`, `head`, `sort` too, so the hook fails for reasons that have
#     nothing to do with jq and the assertion would pass on the wrong cause.
#   · asserting on a variable or a stubbed function — tests the test, not the hook.
#
# What is done instead: a bin directory holding symlinks to every external the hook actually uses,
# and NOT jq. That is genuinely "a machine without jq" and nothing else, which is the condition the
# probe claims to detect. `command -v`, `printf` and `[` are shell builtins and need no link.
setup_nojq_bin() {
  mkdir -p "$root/nojq"
  for b in sed awk head sort tail; do
    src="$(command -v "$b" 2>/dev/null)"
    [ -n "$src" ] && ln -sf "$src" "$root/nojq/$b"
  done
  # jq deliberately NOT linked. `gh` deliberately NOT linked either — the release fallback must not
  # reach the network from a test.
}

run_hook_nojq() {
  # `"$BASH"`, not `bash` — the interpreter is resolved through PATH too, and a PATH holding only the
  # stub bin has no bash in it. The first version of this ran nothing at all and every assertion
  # below reported `<empty>`; it failed LOUDLY, which is the only reason it was not mistaken for the
  # hook staying silent. A matcher looking for absence would have passed on it.
  ( export HOME="$root/home"
    export CLAUDE_PROJECT_DIR="$root/proj"
    export PATH="$root/nojq"
    "$BASH" "$build/hooks/scripts/session-plugin-version.sh" 2>/dev/null )
}

check_nojq() { # label · build version · source version · matcher(present|absent) · needle · [registry]
  setup "$2" "$3" "${6:-}"
  setup_nojq_bin
  out="$(run_hook_nojq)"
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
  esac
  rm -rf "$root"
}

# THE GUARD IS ONLY REACHABLE THROUGH THE PROBE'S OWN PRECONDITION, so the sanity check comes first:
# if this ever fails, the bin directory grew a jq and every case below it is vacuous.
check_nojq 'the arrangement really has no jq' 0.4.24 0.4.24 present 'is not on PATH'

# THE CASE THAT MATTERS MOST, and the one the naive implementation gets wrong: versions MATCHING is
# the hook's silent path — it used to `exit 0` four lines in. A dead guard must be reported on the
# path where there is nothing else to say, or the notice is missing exactly when the session looks
# healthiest.
check_nojq 'fires when versions MATCH'        0.4.24 0.4.24 present 'PERMISSION GUARD IS INERT'
check_nojq 'fires with no build manifest'     ''     0.4.24 present 'PERMISSION GUARD IS INERT'
check_nojq 'fires with no source and no gh'   0.4.21 ''     present 'PERMISSION GUARD IS INERT'
check_nojq 'fires when versions DIFFER too'   0.4.21 0.4.24 present 'PERMISSION GUARD IS INERT'

# The jq-less machine must be TOLD the cross-project arm did not run, inside the notice it already
# gets — otherwise the arm's silence there is indistinguishable from a clean result (#370).
check_nojq 'says the cross-project arm skipped' 0.4.24 0.4.24 present 'cross-project check skipped: no jq' "$REG_STALE"
check_nojq 'and really does not run it'         0.4.24 0.4.24 absent  '/tmp/other-project'                 "$REG_STALE"

# Both findings arrive in ONE payload rather than two objects, and the version half is not lost.
check_nojq 'version finding survives beside it' 0.4.21 0.4.24 present 'is AHEAD of the build'
check_nojq 'still a valid SessionStart event'   0.4.24 0.4.24 present '"hookEventName":"SessionStart"'

# It must say what is LOST in re-derivable terms, and name the concrete verified consequence.
check_nojq 'names the merge gate concretely'  0.4.24 0.4.24 present 'MERGE GATE is open'
check_nojq 'points at the file, not a list'   0.4.24 0.4.24 present 'EVERY rule in permission-guard.sh is inert'
check_nojq 'says the floor still holds direct' 0.4.24 0.4.24 present 'ONLY for the DIRECT spelling'
check_nojq 'says born-in-hook loss is total'  0.4.24 0.4.24 present 'loss is total rather than degraded'

echo '--- and it must stay silent when jq IS present, or it is noise on every session ---'
# The partner half. Without these, "fires when jq is absent" would pass for a probe that fires always.
check 'no notice when jq is present'     0.4.24 0.4.24 empty  ''
check 'not appended to a version notice' 0.4.21 0.4.24 absent 'PERMISSION GUARD IS INERT'

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
