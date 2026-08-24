#!/usr/bin/env bash
# orchestrator-tool-census.test.sh — does the Stop hook stay silent until the WRITE/POST class crosses
# the threshold, classify a `Bash` call by the act it performed, and never gate anything?
#
# Mutation-checked per this repo's convention: every assertion was verified to FAIL against a
# deliberately broken hook before being trusted. The mutations used:
#   * drop the threshold comparison        -> the "silent below threshold" assertions go red
#   * drop the state-file write            -> the debounce assertions go red
#   * classify every Bash call as W        -> the read-classification assertions go red
#   * label a `git -C` command unstripped  -> the label assertion goes red
#
# The transcript is a REAL JSONL fixture in the shape the harness writes, and the repository is a REAL
# temporary git repo — the hook resolves `rev-parse --git-dir` for its debounce state, so a stub would
# test the stub. `jq` is real for the same reason: the extraction IS the hook's contract with the
# transcript format, and asserting it against a stub would assert nothing.
#
# Run: bash hooks/scripts/orchestrator-tool-census.test.sh

set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/orchestrator-tool-census.sh"
pass=0
fail=0

ok()  { printf 'ok    %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL  %s\n     %s\n' "$1" "$2"; fail=$((fail + 1)); }

setup() {
  root="$(mktemp -d)"
  repo="$root/repo"
  mkdir -p "$repo"
  git -C "$repo" init -q -b main
  transcript="$root/transcript.jsonl"
  : > "$transcript"
}
teardown() { rm -rf "$root"; }

# add_call <tool> [command]
add_call() {
  jq -nc --arg n "$1" --arg c "${2:-}" '
    {type:"assistant", message:{content:[
      ({type:"tool_use", name:$n} + (if $c == "" then {} else {input:{command:$c}} end))
    ]}}' >> "$transcript"
}

# a line the extraction must ignore: a user turn, and an assistant turn with plain text
add_noise() {
  jq -nc '{type:"user", message:{content:[{type:"text", text:"hello"}]}}' >> "$transcript"
  jq -nc '{type:"assistant", message:{content:[{type:"text", text:"thinking"}]}}' >> "$transcript"
}

run_hook() { # [session_id] [stop_hook_active]
  jq -n --arg t "$transcript" --arg c "$repo" --arg s "${1:-sess-1}" --argjson a "${2:-false}" \
    '{transcript_path:$t, cwd:$c, session_id:$s, stop_hook_active:$a}' \
    | "$BASH" "$HOOK" 2>/dev/null
}

notice() { printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext // ""' 2>/dev/null || true; }

# ══════════════════════════════════════════════════════════════════════════════════════════════
echo '--- below the threshold, a turn is silent (the noise bound that keeps this readable) ---'
setup
add_noise
add_call Write
add_call Edit
out="$(run_hook)"
if [ -z "$out" ]; then ok '2 write/post calls produce no notice'
else bad '2 write/post calls produce no notice' "got: $out"; fi

echo '--- reads alone never trigger a notice, however many there are ---'
for _ in 1 2 3 4 5 6 7 8 9 10; do add_call Read; done
add_call Bash "gh issue view 319 --repo o/r"
add_call Bash "grep -rn foo ."
out="$(run_hook)"
if [ -z "$out" ]; then ok '12 reads on top of 2 writes still produce no notice'
else bad 'reads never trigger a notice' "got: $out"; fi

echo '--- crossing the threshold: the notice names each tool with its count ---'
add_call Bash "gh issue comment 319 --repo o/r --body-file /x"
out="$(run_hook)"
ctx="$(notice "$out")"
case "$ctx" in
  *"write/post (3)"*) ok 'the write/post class counts 3' ;;
  *) bad 'the write/post class counts 3' "got: ${ctx:-<empty>}" ;;
esac
case "$ctx" in
  *"Bash: gh issue comment x1"*) ok 'a gh post is classified write/post and labelled by its subcommand' ;;
  *) bad 'a gh post is classified write/post' "got: $ctx" ;;
esac
case "$ctx" in
  *"Read x10"*) ok 'the read class is listed, with counts, as context' ;;
  *) bad 'the read class is listed with counts' "got: $ctx" ;;
esac
# the read/write split is the whole point: `gh issue view` must NOT be in the write class
wp="$(printf '%s' "$ctx" | sed -n '/^write\/post/,/^read (/p')"
case "$wp" in
  *"gh issue view"*) bad 'gh issue view stays in the read class' "write/post block was: $wp" ;;
  *) ok 'gh issue view stays in the read class' ;;
esac
teardown

echo '--- a subagent dispatch is one Agent entry, and never the subagent own calls ---'
setup
for _ in 1 2 3; do add_call Agent; done
out="$(run_hook)"
if [ -z "$out" ]; then ok 'three dispatches are not three writes (Agent is a read-class entry)'
else bad 'Agent is not write-class' "got: $out"; fi
teardown

echo '--- git -C is stripped so the label names the ACT, not the flag ---'
setup
add_call Bash "git -C /some/repo add -A"
add_call Bash "git -C /some/repo commit -m x"
add_call Bash "git -C /some/repo push origin feat/x"
add_call Bash "git -C /some/repo status --short"
out="$(run_hook)"
ctx="$(notice "$out")"
case "$ctx" in
  *"Bash: git commit x1"*) ok 'a git -C commit is labelled git commit' ;;
  *) bad 'a git -C commit is labelled git commit' "got: ${ctx:-<empty>}" ;;
esac
case "$ctx" in
  *"Bash: git status x1"*) ok 'a git -C status is labelled git status and stays a read' ;;
  *) bad 'a git -C status is labelled git status' "got: $ctx" ;;
esac
case "$ctx" in
  *"write/post (3)"*) ok 'add, commit and push are the three writes; status is not' ;;
  *) bad 'add, commit and push are the three writes; status is not' "got: $ctx" ;;
esac
teardown

echo '--- classification is on the label, not on a substring of the whole command ---'
setup
# The measured false positive: a heredoc whose BODY carries a mutating word, and a `gh release view`.
add_call Bash "cat /tmp/f  # this body mentions rm and mv and tee and sed -i"
add_call Bash "gh release view v1.2.3 --repo o/r"
add_call Bash "sed -n '1,20p' /tmp/f"
add_call Write
add_call Write
add_call Write
out="$(run_hook)"
ctx="$(notice "$out")"
case "$ctx" in
  *"write/post (3)"*) ok 'the three decoys are reads; only the three Writes count' ;;
  *) bad 'the three decoys are reads; only the three Writes count' "got: ${ctx:-<empty>}" ;;
esac
teardown

echo '--- sed is a write only in place ---'
setup
add_call Bash "sed -i.bak s/a/b/ /tmp/f"
add_call Bash "sed -i.bak s/c/d/ /tmp/f"
add_call Bash "sed -i.bak s/e/f/ /tmp/f"
out="$(run_hook)"
case "$(notice "$out")" in
  *"write/post (3)"*) ok 'sed -i is write-class (the Bash-side route the PreToolUse guard does not block)' ;;
  *) bad 'sed -i is write-class' "got: ${out:-<empty>}" ;;
esac
teardown

echo '--- the debounce: the same state does not re-notify, and re-arms only after N more ---'
setup
add_call Write
add_call Write
add_call Write
out1="$(run_hook sess-A)"
if [ -n "$out1" ]; then ok 'first crossing notifies'
else bad 'first crossing notifies' 'got nothing'; fi
out2="$(run_hook sess-A)"
if [ -z "$out2" ]; then ok 'the same session on the same state is silent'
else bad 'the same session on the same state is silent' "got: $out2"; fi
add_call Write
add_call Write
out3="$(run_hook sess-A)"
if [ -z "$out3" ]; then ok 'two more writes are below the re-arm and stay silent'
else bad 'two more writes stay silent' "got: $out3"; fi
add_call Write
out4="$(run_hook sess-A)"
if [ -n "$out4" ]; then ok 'the third further write re-arms the notice'
else bad 'the third further write re-arms the notice' 'got nothing'; fi
echo '--- the debounce is per session ---'
out5="$(run_hook sess-B)"
if [ -n "$out5" ]; then ok 'a different session is told once, independently'
else bad 'a different session is told once' 'got nothing'; fi
teardown

echo '--- it gates nothing, and says what it cannot see ---'
setup
add_call Write
add_call Write
add_call Write
out="$(run_hook)"
case "$out" in
  *'"decision"'*|*'permissionDecision'*) bad 'never emits a blocking decision field' "got: $out" ;;
  *) ok 'never emits a blocking decision field' ;;
esac
case "$out" in
  *'"Stop"'*) ok 'emits Stop hookSpecificOutput' ;;
  *) bad 'emits Stop hookSpecificOutput' "got: $out" ;;
esac
ctx="$(notice "$out")"
case "$ctx" in
  *ATTEMPTS*) ok 'the notice states that it counts attempts, including denied calls' ;;
  *) bad 'the notice states that it counts attempts' "got: $ctx" ;;
esac
case "$ctx" in
  *"GATES NOTHING"*) ok 'the notice states that it gates nothing' ;;
  *) bad 'the notice states that it gates nothing' "got: $ctx" ;;
esac
case "$ctx" in
  *HABIT*) ok 'the notice names the unmechanised half as a habit, so silence there reads as a decision' ;;
  *) bad 'the notice names the unmechanised half as a habit' "got: $ctx" ;;
esac

echo '--- stop_hook_active short-circuits before any work ---'
out="$(run_hook sess-C true)"
if [ -z "$out" ]; then ok 'stop_hook_active=true exits before doing anything'
else bad 'stop_hook_active=true exits before doing anything' "got: $out"; fi

echo '--- degrades silently on every missing input ---'
out="$(jq -n --arg c "$repo" '{cwd:$c, session_id:"s"}' | "$BASH" "$HOOK" 2>/dev/null; echo "RC:$?")"
if [ "$out" = "RC:0" ]; then ok 'no transcript_path: silent, exit 0'
else bad 'no transcript_path: silent, exit 0' "got: $out"; fi

out="$(jq -n --arg t "$root/nope.jsonl" --arg c "$repo" '{transcript_path:$t, cwd:$c}' | "$BASH" "$HOOK" 2>/dev/null; echo "RC:$?")"
if [ "$out" = "RC:0" ]; then ok 'a transcript_path that does not exist: silent, exit 0'
else bad 'a transcript_path that does not exist: silent, exit 0' "got: $out"; fi

out="$(jq -n --arg t "$transcript" --arg c "$root" '{transcript_path:$t, cwd:$c}' | "$BASH" "$HOOK" 2>/dev/null; echo "RC:$?")"
if [ "$out" = "RC:0" ]; then ok 'cwd outside any git repo: no debounce state is possible, so no census'
else bad 'cwd outside any git repo: silent, exit 0' "got: $out"; fi

out="$(printf '' | "$BASH" "$HOOK" 2>/dev/null; echo "RC:$?")"
if [ "$out" = "RC:0" ]; then ok 'an empty payload: silent, exit 0'
else bad 'an empty payload: silent, exit 0' "got: $out"; fi

# The payload is BUILT before PATH is emptied — `run_hook` itself shells out to jq, so calling it
# under the stripped PATH would test the harness rather than the hook (it did, and reported RC:127).
mkdir -p "$root/emptybin"
payload="$(jq -n --arg t "$transcript" --arg c "$repo" '{transcript_path:$t, cwd:$c, session_id:"sess-D"}')"
out="$( export PATH="$root/emptybin"; printf '%s' "$payload" | "$BASH" "$HOOK" 2>/dev/null; echo "RC:$?" )"
if [ "$out" = "RC:0" ]; then ok 'no jq and no git on PATH: silent, exit 0'
else bad 'no jq and no git on PATH: silent, exit 0' "got: $out"; fi

echo '--- the debounce state never lands in the working tree ---'
untracked="$(git -C "$repo" status --porcelain)"
if [ -z "$untracked" ]; then ok 'the repo working tree is untouched by the census state file'
else bad 'the repo working tree is untouched' "git status reported: $untracked"; fi
teardown

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
