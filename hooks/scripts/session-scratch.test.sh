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

# Every call feeds a payload on stdin, because the hook reads one. Default `startup` — the source
# under which it is supposed to sweep — so the sweep tests read as before; the source-gating tests
# below pass their own.
run_hook() {
  ( export SCRATCH_ROOTS="$base/repo-a
$base/repo-b"
    printf '{"source":"%s","hook_event_name":"SessionStart"}' "${1:-startup}" \
      | "$BASH" "$HOOK" 2>/dev/null )
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

echo '--- IT MUST NOT SWEEP A RESUMED SESSION, which is the failure it exists to prevent ---'
# SessionStart fires when a session begins OR RESUMES. A resumed session is the same unit of work,
# so sweeping there deletes the handoff the pause was taken over — reintroducing exactly the loss
# this hook was built to stop. The gate caught this in review; these are the assertions that keep
# it caught.
for src in resume compact; do
  setup
  mkdir -p "$base/repo-a/.scratch"
  printf 'still needed\n' > "$base/repo-a/.scratch/pr-body.md"
  out="$(run_hook "$src")"
  eq "source=$src leaves the scratch untouched" 1 "$(count_under "$base/repo-a/.scratch")"
  if [ -f "$base/repo-a/.scratch/pr-body.md" ]; then ok "source=$src spares the file by name"; else bad "source=$src spares the file by name" 'DELETED'; fi
  if [ -z "$out" ]; then ok "source=$src is silent"; else bad "source=$src is silent" "got: $out"; fi
  teardown
done

# `clear` is a new session in every sense that matters here: the context is gone, so nothing can
# still be owed to it.
setup
mkdir -p "$base/repo-a/.scratch"
printf 'x\n' > "$base/repo-a/.scratch/x.txt"
run_hook clear >/dev/null
eq 'source=clear DOES sweep' 0 "$(count_under "$base/repo-a/.scratch")"
teardown

echo '--- an unrecognised source fails SAFE and says so, rather than sweeping ---'
# The allowlist direction is the safety argument. If the payload field is ever renamed upstream,
# this hook must go inert and ANNOUNCE it — accumulation is visible and recoverable, a delete under
# live work is neither. Silent inertness would be the worst of both.
setup
mkdir -p "$base/repo-a/.scratch"
printf 'x\n' > "$base/repo-a/.scratch/x.txt"
out="$(run_hook some-future-source)"
eq 'nothing is deleted on an unknown source' 1 "$(count_under "$base/repo-a/.scratch")"
case "$out" in
  *'NOT swept'*) ok 'and it announces that it did nothing' ;;
  *) bad 'and it announces that it did nothing' "got: ${out:-<empty>}" ;;
esac
case "$out" in
  *'some-future-source'*) ok 'naming the source it did not recognise' ;;
  *) bad 'naming the source it did not recognise' "got: ${out:-<empty>}" ;;
esac
teardown

# A payload that is absent or unparseable is the same case as an unknown source, and must not be
# the case that deletes.
setup
mkdir -p "$base/repo-a/.scratch"
printf 'x\n' > "$base/repo-a/.scratch/x.txt"
printf 'not json at all' | env SCRATCH_ROOTS="$base/repo-a" "$BASH" "$HOOK" >/dev/null 2>&1
eq 'a malformed payload deletes nothing' 1 "$(count_under "$base/repo-a/.scratch")"
teardown

setup
mkdir -p "$base/repo-a/.scratch"
printf 'x\n' > "$base/repo-a/.scratch/x.txt"
env SCRATCH_ROOTS="$base/repo-a" "$BASH" "$HOOK" </dev/null >/dev/null 2>&1
eq 'an empty payload deletes nothing' 1 "$(count_under "$base/repo-a/.scratch")"
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
