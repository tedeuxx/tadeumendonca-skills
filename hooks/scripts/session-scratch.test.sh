#!/usr/bin/env bash
# session-scratch.test.sh — does the sweep delete what it must, spare what it must, and stay
# silent when there is nothing to say?
#
# THIS IS A SUITE FOR A DESTRUCTIVE HOOK, so the assertions run in both directions on purpose. A
# cleanup that deletes too much loses work; one that deletes too little is the accumulation it was
# built to stop. Both are failures and both are asserted.
#
# Nothing here touches a real repo: `SCRATCH_ROOTS` points at throwaway trees. The seam exists for
# exactly this reason, which is stated in the hook's own header.
#
# `if/then/else` rather than `A && ok || bad` throughout, and not for style: in that form `bad`
# also runs whenever `ok` returns non-zero, which in a file whose whole job is counting is a way
# to miscount a pass as a failure. shellcheck flags it as SC2015 and it is right to.
#
# Mutation-checked, with the count PREDICTED BEFORE EACH RUN — watching reds appear only proves
# that some assertion is live, never that a specific one is. That distinction cost this workspace
# a dead assertion earlier in the week.

set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/session-scratch.sh"
pass=0
fail=0

ok()  { printf 'ok    %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL  %s\n     %s\n' "$1" "$2"; fail=$((fail + 1)); }

# Two throwaway roots, mirroring the real pair.
setup() {
  base="$(mktemp -d)"
  mkdir -p "$base/repo-a" "$base/repo-b"
}

teardown() { rm -rf "$base"; }

run_hook() {
  ( export SCRATCH_ROOTS="$base/repo-a
$base/repo-b"
    "$BASH" "$HOOK" 2>/dev/null )
}

count_under() { find "$1" -mindepth 1 2>/dev/null | wc -l | tr -d ' '; }

# label · expected · actual
eq() {
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected $2, got $3"; fi
}

echo '--- it removes what is in scratch ---'
setup
mkdir -p "$base/repo-a/.scratch"
printf 'body\n' > "$base/repo-a/.scratch/pr-body.md"
printf 'msg\n'  > "$base/repo-a/.scratch/commit-msg.txt"
out="$(run_hook)"
eq 'scratch is empty afterwards' 0 "$(count_under "$base/repo-a/.scratch")"
case "$out" in
  *'Scratch cleared'*) ok 'and it says so' ;;
  *) bad 'and it says so' "got: ${out:-<empty>}" ;;
esac
# The directory itself survives, so the next write does not have to recreate it — and so a path
# error cannot walk upward out of it.
if [ -d "$base/repo-a/.scratch" ]; then ok 'the directory itself survives'; else bad 'the directory itself survives' 'gone'; fi
teardown

echo '--- NESTED content goes too, which is where a -maxdepth bug would hide ---'
setup
mkdir -p "$base/repo-a/.scratch/deep/deeper"
printf 'x\n' > "$base/repo-a/.scratch/deep/deeper/buried.txt"
run_hook >/dev/null
eq 'nested files and dirs are removed' 0 "$(count_under "$base/repo-a/.scratch")"
teardown

echo '--- BOTH roots are swept, not just the first ---'
# The failure this catches is a loop that returns after the first hit, or roots derived from a
# single project dir. It is the shape that has already bitten this workspace on a two-repo glob.
setup
mkdir -p "$base/repo-a/.scratch" "$base/repo-b/.scratch"
printf 'a\n' > "$base/repo-a/.scratch/a.txt"
printf 'b\n' > "$base/repo-b/.scratch/b.txt"
run_hook >/dev/null
eq 'first root swept'  0 "$(count_under "$base/repo-a/.scratch")"
eq 'second root swept' 0 "$(count_under "$base/repo-b/.scratch")"
teardown

echo '--- IT MUST NOT REACH OUTSIDE .scratch, and this is the assertion that matters most ---'
setup
mkdir -p "$base/repo-a/.scratch" "$base/repo-a/src"
printf 'tracked\n' > "$base/repo-a/src/real.ts"
printf 'tracked\n' > "$base/repo-a/README.md"
printf 'scratch\n' > "$base/repo-a/.scratch/junk.txt"
run_hook >/dev/null
if [ -f "$base/repo-a/src/real.ts" ]; then ok 'a sibling source file survives'; else bad 'a sibling source file survives' 'DELETED'; fi
if [ -f "$base/repo-a/README.md" ];   then ok 'a file at the repo root survives'; else bad 'a file at the repo root survives' 'DELETED'; fi
if [ -d "$base/repo-a/src" ];         then ok 'a sibling directory survives'; else bad 'a sibling directory survives' 'DELETED'; fi
teardown

echo '--- silence is the correct output when there is nothing to remove ---'
setup
mkdir -p "$base/repo-a/.scratch"
out="$(run_hook)"
if [ -z "$out" ]; then ok 'an empty scratch says nothing'; else bad 'an empty scratch says nothing' "got: $out"; fi
teardown

setup
out="$(run_hook)"
if [ -z "$out" ]; then ok 'no scratch directory at all says nothing'; else bad 'no scratch directory at all says nothing' "got: $out"; fi
teardown

echo '--- a root that does not exist is skipped, not fatal ---'
setup
mkdir -p "$base/repo-a/.scratch"
printf 'x\n' > "$base/repo-a/.scratch/x.txt"
rm -rf "$base/repo-b"
out="$(run_hook)"
eq 'the surviving root is still swept' 0 "$(count_under "$base/repo-a/.scratch")"
case "$out" in
  *'Scratch cleared'*) ok 'and it still reports' ;;
  *) bad 'and it still reports' "got: ${out:-<empty>}" ;;
esac
teardown

echo '--- the contract: valid SessionStart JSON, exit 0, never blocks ---'
setup
mkdir -p "$base/repo-a/.scratch"
printf 'x\n' > "$base/repo-a/.scratch/x.txt"
out="$(run_hook)"
case "$out" in
  *'"hookEventName"'*) ok 'emits a SessionStart event' ;;
  *) bad 'emits a SessionStart event' "got: $out" ;;
esac
case "$out" in
  *'additionalContext'*) ok 'carries additionalContext' ;;
  *) bad 'carries additionalContext' "got: $out" ;;
esac
case "$out" in
  *'.scratch/'*) ok 'names the location in the injected text' ;;
  *) bad 'names the location in the injected text' "got: $out" ;;
esac
teardown

setup
mkdir -p "$base/repo-a/.scratch"
printf 'x\n' > "$base/repo-a/.scratch/x.txt"
if run_hook >/dev/null; then ok 'exits 0 when it removed something'; else bad 'exits 0 when it removed something' "exit was $?"; fi
teardown

setup
if run_hook >/dev/null; then ok 'exits 0 when silent'; else bad 'exits 0 when silent' "exit was $?"; fi
teardown

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
