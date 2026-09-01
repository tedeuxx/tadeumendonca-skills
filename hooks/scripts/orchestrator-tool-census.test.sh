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

# EVERY BLOCK THAT EXPECTS A NOTICE ASSERTS THAT ONE ARRIVED, BEFORE ASSERTING ANYTHING ABOUT IT.
# Found on #374's review, and it is a defect in this FILE rather than in the hook. Forcing the census
# permanently silent (CENSUS_THRESHOLD 3 -> 9999) left 18 arms passing, three of them absent-shaped and
# matching against an EMPTY STRING — including one added in this same batch specifically to harden a
# block:
#
#   ok    the wrapper never survives into a label
#   ok    gh api is not reported as a read
#   ok    a listed reader does not appear in the ? block
#
# The earlier hardening (three `Write` calls, so the notice's trigger does not depend on the
# classification under test) is real and was verified — but it is POSITIONAL: it works because each
# absent-shaped arm happens to sit beside a positive arm in the same block, so an empty notice reddens
# loudly somewhere. Delete or reorder that sibling and the protection is gone with no red to say so.
# `ctx_or_die` makes it structural: one call per block, and an absent-shaped assertion can no longer
# pass by matching nothing.
ctx_or_die() { # label · notice-text
  if [ -z "$2" ]; then
    bad "$1" 'the hook emitted NO notice — every assertion in this block would pass against an empty
     string, so this is reported as a failure rather than letting absent-shaped arms go green'
    return 1
  fi
  return 0
}

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
ctx_or_die "a notice was emitted for this block" "$ctx"
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
ctx_or_die "a notice was emitted for this block" "$ctx"
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

echo '--- #371: a wrapper prefix must not park a mutation in the read bucket ---'
# The motivating incident: `env -C <dir> claude plugin update …` rewrote the install registry — which
# decides which briefs and hooks every project runs — and was reported as a READ, because `classify()`
# labelled on the first token and the first token was `env`.
setup
# THE THREE `Write`s ARE NOT PADDING. Without them the notice's own threshold decides whether this
# block runs at all: under the mutation that removes the wrapper strip the write count drops below 3,
# the hook stays silent, and every `absent`-shaped assertion below passes against an EMPTY string. That
# is a case passing for the wrong reason, which this repo has shipped before — so the trigger is made
# independent of the thing under test.
add_call Write
add_call Write
add_call Write
add_call Bash "env -C /some/proj claude plugin update tadeumendonca-skills@tadeumendonca --scope project -y"
add_call Bash "claude plugin install tadeumendonca-skills@tadeumendonca"
add_call Bash "claude plugin uninstall tadeumendonca-skills@tadeumendonca"
out="$(run_hook)"
ctx="$(notice "$out")"
ctx_or_die "a notice was emitted for this block" "$ctx"
case "$ctx" in
  *"write/post (6)"*) ok 'a wrapper-prefixed plugin update is write-class' ;;
  *) bad 'a wrapper-prefixed plugin update is write-class' "got: ${ctx:-<empty>}" ;;
esac
# THE LABEL ARM, DELIBERATELY SEPARATE FROM THE CLASS ARM. Adding `claude plugin update` to the W list
# without the strip fixes nothing, because that string is never produced — the label came off `env`.
# Folding this into the class check above would hide exactly that failure, so it stands alone.
# Mutate: revert the label step to `awk '{print $1}'` with the W list intact -> this goes red.
case "$ctx" in
  *"Bash: claude plugin update x1"*) ok 'and it is labelled by the ACT, three words, not by the wrapper' ;;
  *) bad 'the label names the act, not the wrapper' "got: $ctx" ;;
esac
case "$ctx" in
  *"Bash: env"*) bad 'the wrapper never survives into a label' "got: $ctx" ;;
  *) ok 'the wrapper never survives into a label' ;;
esac
teardown

echo '--- #371: the NEGATIVE half — a wrapper strip must not become a blanket write ---'
# Without these, "a wrapper-prefixed update is a write" would pass for a hook that classifies the whole
# `claude` program, or every `env`-prefixed command, as a write.
setup
add_call Bash "claude plugin list"
add_call Bash "env -C /some/proj claude plugin list"
add_call Bash "claude plugin details tadeumendonca-skills@tadeumendonca"
add_call Write
add_call Write
add_call Write
out="$(run_hook)"
ctx="$(notice "$out")"
ctx_or_die "a notice was emitted for this block" "$ctx"
case "$ctx" in
  *"write/post (3)"*) ok 'three plugin READS are not writes; only the three Writes count' ;;
  *) bad 'three plugin reads are not writes' "got: ${ctx:-<empty>}" ;;
esac
case "$ctx" in
  *"Bash: claude plugin list x2"*) ok 'the wrapped and bare read carry the SAME label' ;;
  *) bad 'the wrapped and bare read carry the same label' "got: $ctx" ;;
esac
teardown

echo '--- #371: a stray option before the subcommand leaked the two labels that DO work ---'
# Measured against this hook before the fix: `git -c user.name=x commit` labelled `git -c` and landed in
# READ; `gh --repo o/r issue comment` labelled `gh --repo o/r` and landed in READ. The second is the
# orchestrator's most common write, and `command-hygiene` already documents that this flag position
# breaks the PERMISSION prefix matcher — nobody had noticed it breaks the census identically.
setup
# Same reason as above: the trigger must not depend on the classification under test.
add_call Write
add_call Write
add_call Write
add_call Bash "git -c user.name=x commit -m y"
add_call Bash "git --git-dir=/tmp/r/.git commit -m y"
add_call Bash "gh --repo o/r issue comment 1 --body-file /x"
out="$(run_hook)"
ctx="$(notice "$out")"
ctx_or_die "a notice was emitted for this block" "$ctx"
case "$ctx" in
  *"write/post (6)"*) ok 'an option before the subcommand no longer hides a write' ;;
  *) bad 'an option before the subcommand no longer hides a write' "got: ${ctx:-<empty>}" ;;
esac
case "$ctx" in
  *"Bash: git commit x2"*) ok 'both git option spellings collapse to one label, git commit' ;;
  *) bad 'both git option spellings label as git commit' "got: $ctx" ;;
esac
case "$ctx" in
  *"Bash: gh issue comment x1"*) ok 'gh --repo is stripped with its VALUE, so the subcommand is found' ;;
  *) bad 'gh --repo is stripped with its value' "got: $ctx" ;;
esac
teardown

echo '--- #371: and the option strip must not eat a read into a write, or a subcommand ---'
setup
add_call Bash "git -c core.pager=cat status --short"
add_call Bash "gh --repo o/r issue view 1"
add_call Bash "git --no-pager log --oneline -5"
add_call Write
add_call Write
add_call Write
out="$(run_hook)"
ctx="$(notice "$out")"
ctx_or_die "a notice was emitted for this block" "$ctx"
case "$ctx" in
  *"write/post (3)"*) ok 'the three option-bearing reads stay reads' ;;
  *) bad 'the three option-bearing reads stay reads' "got: ${ctx:-<empty>}" ;;
esac
case "$ctx" in
  *"Bash: git status x1"*) ok 'git -c <k=v> status is labelled git status' ;;
  *) bad 'git -c <k=v> status is labelled git status' "got: $ctx" ;;
esac
# A no-argument flag must NOT swallow the subcommand behind it — the failure a generic "skip the next
# token too" rule would produce, silently, on every `git --no-pager <read>`.
case "$ctx" in
  *"Bash: git log x1"*) ok 'a no-argument flag does not swallow the subcommand' ;;
  *) bad 'a no-argument flag does not swallow the subcommand' "got: $ctx" ;;
esac
case "$ctx" in
  *"Bash: gh issue view x1"*) ok 'gh --repo issue view is still a read, correctly labelled' ;;
  *) bad 'gh --repo issue view is still a read' "got: $ctx" ;;
esac
teardown

echo '--- #371: gh api gets a bounded label, and is NOT called a read ---'
# The three-word rule took a URL path as its third word, so `gh api` produced one label per endpoint and
# no W entry could ever match it. `gh api -X POST` writes and nothing in a label can tell, so the
# honest class is neither W nor R.
setup
add_call Bash "gh api repos/o/r/contents/VERSION"
add_call Bash "gh api repos/o/r/pulls/1 --jq .head.sha"
add_call Write
add_call Write
add_call Write
out="$(run_hook)"
ctx="$(notice "$out")"
ctx_or_die "a notice was emitted for this block" "$ctx"
case "$ctx" in
  *"Bash: gh api x2"*) ok 'two endpoints collapse to one bounded label' ;;
  *) bad 'gh api is capped at two words' "got: ${ctx:-<empty>}" ;;
esac
case "$ctx" in
  *"unclassified (2)"*) ok 'gh api lands in the unclassified class, not in read' ;;
  *) bad 'gh api lands in unclassified' "got: $ctx" ;;
esac
rd="$(printf '%s' "$ctx" | sed -n '/^read (/,/^unclassified (/p')"
case "$rd" in
  *"gh api"*) bad 'gh api is not reported as a read' "read block was: $rd" ;;
  *) ok 'gh api is not reported as a read' ;;
esac
teardown

echo '--- #371: the third class — unrecognised is NOT measured-as-a-read ---'
setup
add_call Bash "bump-my-version bump patch"
add_call Bash "npm publish"
add_call Bash "node scripts/whatever.js"
add_call Bash "grep -rn foo ."
add_call Write
add_call Write
add_call Write
out="$(run_hook)"
ctx="$(notice "$out")"
ctx_or_die "a notice was emitted for this block" "$ctx"
# Mutate: default the class back to R -> this goes red, and it is the arm the whole class exists for.
case "$ctx" in
  *"unclassified (3)"*) ok 'three unrecognised programs land in ? rather than in read' ;;
  *) bad 'unrecognised programs land in ?' "got: ${ctx:-<empty>}" ;;
esac
case "$ctx" in
  *"NOT measured as reads"*) ok 'the block says what the class means, so silence there is not comfort' ;;
  *) bad 'the ? block explains itself' "got: $ctx" ;;
esac
# THE BOUND ON THE NOISE: a listed reader must stay in R and must not appear in the ? block.
case "$ctx" in
  *"read (1)"*) ok 'a listed reader stays in the read class' ;;
  *) bad 'a listed reader stays in the read class' "got: $ctx" ;;
esac
unk="$(printf '%s' "$ctx" | sed -n '/^unclassified (/,$p')"
case "$unk" in
  *"Bash: grep"*) bad 'a listed reader does not appear in the ? block' "? block was: $unk" ;;
  *) ok 'a listed reader does not appear in the ? block' ;;
esac
teardown

echo '--- #371: an unclassified call triggers nothing, so the third class adds no noise floor ---'
setup
for _ in 1 2 3 4 5 6; do add_call Bash "bump-my-version bump patch"; done
out="$(run_hook)"
if [ -z "$out" ]; then ok 'six unclassified calls and zero writes produce no notice'
else bad 'unclassified calls never trigger a notice' "got: $out"; fi
teardown

echo '--- #371: an unknown TOOL name is unclassified too, not silently a read ---'
# The same defect one layer up: a new write-capable tool landing in R by default would be invisible.
setup
add_call SomeFutureWriteTool
add_call mcp__thing__mutate
add_call Read
add_call Write
add_call Write
add_call Write
out="$(run_hook)"
ctx="$(notice "$out")"
ctx_or_die "a notice was emitted for this block" "$ctx"
case "$ctx" in
  *"unclassified (2)"*) ok 'two unknown tool names land in ?' ;;
  *) bad 'unknown tool names land in ?' "got: ${ctx:-<empty>}" ;;
esac
case "$ctx" in
  *"read (1)"*) ok 'and a known read tool is unaffected' ;;
  *) bad 'a known read tool is unaffected' "got: $ctx" ;;
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
ctx_or_die "a notice was emitted for this block" "$ctx"
case "$ctx" in
  *"write/post (3)"*) ok 'the three decoys are reads; only the three Writes count' ;;
  *) bad 'the three decoys are reads; only the three Writes count' "got: ${ctx:-<empty>}" ;;
esac
teardown

echo '--- #374 review: `sed --in-place` was POSITIVELY CLAIMED as a read ---'
# The `sed` arm matched `*" -i"*`, which `" --in-place"` does not contain — so a mutation landed in R.
# This is worse than the `?` class it would otherwise have reached: `?` is an admission, `R` is an
# assertion, and `sed` is the one arm in classify() that asserts.
#
# PLATFORM CAVEAT, carried in the test because it is why nobody hit this: BSD `sed` rejects the long
# form (`sed: illegal option -- -`), so the defect is unreachable on the machine that found it and
# reachable on every Linux runner, including this repo's own CI.
setup
add_call Bash "sed --in-place s/a/b/ /tmp/f"
add_call Bash "sed --in-place s/c/d/ /tmp/f"
add_call Bash "sed --in-place s/e/f/ /tmp/f"
out="$(run_hook)"
case "$(notice "$out")" in
  *"write/post (3)"*) ok 'sed --in-place is write-class, like sed -i' ;;
  *) bad 'sed --in-place is write-class' "got: ${out:-<empty>}" ;;
esac
teardown
# THE NEGATIVE HALF: a long-form READ must not become a write just because the arm grew a pattern.
setup
add_call Bash "sed --expression=s/a/b/ /tmp/f"
add_call Bash "sed --quiet 1,20p /tmp/f"
add_call Write
add_call Write
add_call Write
out="$(run_hook)"
case "$(notice "$out")" in
  *"write/post (3)"*) ok 'a long-form sed READ stays a read' ;;
  *) bad 'a long-form sed read stays a read' "got: ${out:-<empty>}" ;;
esac
teardown

echo '--- #374 review: repeated spaces must not defeat the option strip ---'
# `${c%% *}` / `${c#* }` split on ONE space, so `gh  --repo o/r pr comment` (two spaces, a shape a
# human types) left `--repo` unstripped and the label came out `gh --repo o/r` -> `?`. A degradation
# rather than a false read, and fixed with the same `awk` normalisation the label already used.
setup
add_call Write
add_call Write
add_call Write
add_call Bash "gh  --repo o/r  issue comment 1 --body-file /x"
add_call Bash "git   -c user.name=x   commit -m y"
out="$(run_hook)"
ctx="$(notice "$out")"
ctx_or_die "a notice was emitted for this block" "$ctx"
case "$ctx" in
  *"write/post (5)"*) ok 'double-spaced writes are still writes' ;;
  *) bad 'double-spaced writes are still writes' "got: ${ctx:-<empty>}" ;;
esac
case "$ctx" in
  *"Bash: gh issue comment x1"*) ok 'and the label is the same as the single-spaced form' ;;
  *) bad 'the double-spaced label matches the single-spaced one' "got: $ctx" ;;
esac
case "$ctx" in
  *"Bash: git commit x1"*) ok 'the git form too' ;;
  *) bad 'the double-spaced git label' "got: $ctx" ;;
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
ctx_or_die "a notice was emitted for this block" "$ctx"
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
