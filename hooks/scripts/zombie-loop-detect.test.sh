#!/usr/bin/env bash
# zombie-loop-detect.test.sh — does the Stop hook fire the notice exactly when loop state says an
# outstanding gate verdict was left unaddressed at turn end, and stay silent (and cheap) otherwise?
#
# Mutation-checked per this repo's own convention: every assertion below was verified to fail
# against a deliberately broken hook before being trusted. Two properties get that treatment
# explicitly because the intake asked for it by name — the LOCAL-ONLY PRECONDITION (no `gh` call
# at all with no current branch) and the DEBOUNCE (a repeated turn on the same (PR, head) does not
# re-notify and does not repeat the heavier `pr view` call).
#
# Uses a REAL temporary git repository (not a stub) because the hook calls `git branch
# --show-current` and `git rev-parse --git-dir` for real — a stubbed `git` would test the stub,
# not the hook's use of it. `gh` IS a stub: it serves fixtures and, critically, LOGS every
# invocation to a call-log file so the network-cost assertions can count calls rather than infer
# them from behaviour.

set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/zombie-loop-detect.sh"
pass=0
fail=0

ok()  { printf 'ok    %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL  %s\n     %s\n' "$1" "$2"; fail=$((fail + 1)); }

# ── fixture repo + gh stub ──────────────────────────────────────────────────────────────────────
setup() {
  root="$(mktemp -d)"
  repo="$root/repo"
  mkdir -p "$repo" "$root/bin" "$root/fix"
  git -C "$repo" init -q -b main
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config user.name test
  printf 'x\n' > "$repo/f"
  git -C "$repo" add f
  git -C "$repo" commit -q -m init

  : > "$root/calls.log"
  cat > "$root/bin/gh" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "__CALLLOG__"
case "$1 $2" in
  "pr list") [ -f "__FIXDIR__/list.json" ] && cat "__FIXDIR__/list.json" ;;
  "pr view") [ -f "__FIXDIR__/view.json" ] && cat "__FIXDIR__/view.json" ;;
esac
exit 0
STUB
  sed -i.bak "s#__CALLLOG__#$root/calls.log#g; s#__FIXDIR__#$root/fix#g" "$root/bin/gh"
  rm -f "$root/bin/gh.bak"
  chmod +x "$root/bin/gh"
}

teardown() { rm -rf "$root"; }

checkout_branch() { # name
  git -C "$repo" checkout -q -b "$1" 2>/dev/null || git -C "$repo" checkout -q "$1"
}

no_open_pr() {
  printf '[]\n' > "$root/fix/list.json"
}

open_pr() { # number · head_sha
  jq -n --argjson n "$1" --arg h "$2" '[{number:$n, headRefOid:$h}]' > "$root/fix/list.json"
}

# comment body carrying the marker + verdict + head, from an OWNER
view_with_verdict() { # head_sha · verdict
  jq -n --arg h "$1" --arg body "<!-- gatekeeper-verdict: quality-assurance -->
$2
head: $1" '{headRefOid:$h, comments:[{body:$body, authorAssociation:"OWNER"}]}' > "$root/fix/view.json"
}

view_no_comments() { # head_sha
  jq -n --arg h "$1" '{headRefOid:$h, comments:[]}' > "$root/fix/view.json"
}

# ── #385 fixtures: the agents-lead marker, at whatever heads the caller names ──────────────
# Each marker is a SEPARATE comment object, built by `jq` from positional arguments. The first
# version of these builders concatenated the bodies and asked `jq` to `split("\u0000")` on a
# separator that was never a NUL byte, so every marker arrived as ONE comment — and two cases
# passed anyway, for the wrong reason, because a single blob containing both a stale marker and
# the head SHA reads as fresh. That is this repo's own "a check whose positive result is
# unconditional is not a check", found by a case that failed rather than by re-reading.
#
# `marker_heads` is the variable under test: the arm asks whether ANY marker names the CURRENT head.
view_with_harness_markers() { # head_sha · marker_heads... (may be empty)
  vh="$1"; shift
  jq -n --arg h "$vh" '
    {headRefOid: $h,
     comments: ($ARGS.positional
                | map({body: ("<!-- harness-lead-verdict: reviewed -->\ncommit: " + .),
                       authorAssociation: "OWNER"}))}
  ' --args "$@" > "$root/fix/view.json"
}

# Both markers on one PR, as separate comments, so the two signals can be exercised independently.
view_gate_and_harness() { # head_sha · gate_verdict · marker_heads...
  vh="$1"; gv="$2"; shift 2
  jq -n --arg h "$vh" --arg g "$gv" '
    {headRefOid: $h,
     comments: ([{body: ("<!-- gatekeeper-verdict: quality-assurance -->\n" + $g + "\nhead: " + $h),
                  authorAssociation: "OWNER"}]
                + ($ARGS.positional
                   | map({body: ("<!-- harness-lead-verdict: reviewed -->\ncommit: " + .),
                          authorAssociation: "OWNER"})))}
  ' --args "$@" > "$root/fix/view.json"
}

run_hook() {
  payload="$(jq -n --arg cwd "$repo" --arg sid "sess-1" '{cwd:$cwd, session_id:$sid}')"
  ( export PATH="$root/bin:/usr/bin:/bin"
    printf '%s' "$payload" | "$BASH" "$HOOK" 2>/dev/null )
}

call_count() { # subcommand words, e.g. "pr list"
  grep -c "^$1" "$root/calls.log" 2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════════════════════
echo '--- the failure this exists for: REQUEST-CHANGES outstanding at turn end ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 REQUEST-CHANGES
out="$(run_hook)"
case "$out" in
  *'REQUEST-CHANGES'*'#150'*|*'#150'*'REQUEST-CHANGES'*) ok 'notice names the PR and the verdict' ;;
  *) bad 'notice names the PR and the verdict' "got: ${out:-<empty>}" ;;
esac
case "$out" in
  *'hookSpecificOutput'*'"Stop"'*) ok 'emits Stop hookSpecificOutput' ;;
  *) bad 'emits Stop hookSpecificOutput' "got: $out" ;;
esac
teardown

echo '--- APPROVE-PENDING-HUMAN also triggers the notice ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 APPROVE-PENDING-HUMAN
out="$(run_hook)"
case "$out" in
  *'APPROVE-PENDING-HUMAN'*) ok 'APPROVE-PENDING-HUMAN fires' ;;
  *) bad 'APPROVE-PENDING-HUMAN fires' "got: ${out:-<empty>}" ;;
esac
teardown

echo '--- APPROVE-EXECUTOR-BLOCKED (#374) is the sharpest outstanding state there is ---'
# The gate cleared the diff and could not execute the merge, so nothing downstream moves without the
# owner. Silence here would hide the one state in the vocabulary where the loop has finished.
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 APPROVE-EXECUTOR-BLOCKED
out="$(run_hook)"
case "$out" in
  *'APPROVE-EXECUTOR-BLOCKED'*) ok 'APPROVE-EXECUTOR-BLOCKED fires' ;;
  *) bad 'APPROVE-EXECUTOR-BLOCKED fires' "got: ${out:-<empty>}" ;;
esac
case "$out" in
  *'remaining act is the owner'*) ok 'and the notice says the act is the owner, not another dispatch' ;;
  *) bad 'the notice routes it to the owner' "got: ${out:-<empty>}" ;;
esac
teardown

echo '--- APPROVE-AND-MERGE is not outstanding, no notice ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 APPROVE-AND-MERGE
out="$(run_hook)"
if [ -z "$out" ]; then ok 'silent on APPROVE-AND-MERGE'; else bad 'silent on APPROVE-AND-MERGE' "got: $out"; fi
teardown

echo '--- no verdict at all (gate never dispatched) is not this hook''s condition ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_no_comments abc123
out="$(run_hook)"
if [ -z "$out" ]; then ok 'silent when there is no verdict yet'; else bad 'silent when there is no verdict yet' "got: $out"; fi
teardown

echo '--- staleness: a verdict citing a superseded head is not read as current ---'
# view_with_verdict's headRefOid arg is what gh pr view reports as CURRENT (newsha); the comment
# body's own "head: oldsha" line names the head the gate actually reviewed, which is stale.
setup
checkout_branch feat/x
open_pr 150 newsha
jq -n --arg h newsha --arg body "<!-- gatekeeper-verdict: quality-assurance -->
REQUEST-CHANGES
head: oldsha" '{headRefOid:$h, comments:[{body:$body, authorAssociation:"OWNER"}]}' > "$root/fix/view.json"
out="$(run_hook)"
if [ -z "$out" ]; then ok 'a verdict on an old head does not fire'; else bad 'a verdict on an old head does not fire' "got: $out"; fi
teardown

echo '--- unrecognised literal (verdict drift) is out of THIS hook''s narrow scope ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 APPROVED
out="$(run_hook)"
if [ -z "$out" ]; then ok 'an unrecognised literal does not fire (session-wip.sh owns that report)'; else bad 'unrecognised literal scope' "got: $out"; fi
teardown

# ══════════════════════════════════════════════════════════════════════════════════════════════
echo '--- LOCAL-ONLY PRECONDITION: no current branch means ZERO gh calls ---'
setup
git -C "$repo" checkout -q --detach 2>/dev/null || true
out="$(run_hook)"
n="$(call_count '')"
total_calls="$(wc -l < "$root/calls.log" | tr -d ' ')"
if [ "$total_calls" = "0" ]; then ok 'zero gh calls with no current branch'; else bad 'zero gh calls with no current branch' "calls: $(cat "$root/calls.log")"; fi
if [ -z "$out" ]; then ok 'and no notice'; else bad 'and no notice' "got: $out"; fi
teardown

echo '--- LOCAL-ONLY PRECONDITION: an unreadable cwd means zero gh calls ---'
setup
payload="$(jq -n --arg cwd "/no/such/dir/at/all" --arg sid "s1" '{cwd:$cwd, session_id:$sid}')"
out="$( export PATH="$root/bin:/usr/bin:/bin"; printf '%s' "$payload" | "$BASH" "$HOOK" 2>/dev/null )"
total_calls="$(wc -l < "$root/calls.log" | tr -d ' ')"
if [ "$total_calls" = "0" ]; then ok 'zero gh calls with an unreadable cwd'; else bad 'zero gh calls with an unreadable cwd' "calls: $(cat "$root/calls.log")"; fi
teardown

echo '--- NETWORK COST: no open PR means exactly ONE gh call, never reaches pr view ---'
setup
checkout_branch feat/x
no_open_pr
out="$(run_hook)"
list_calls="$(call_count 'pr list')"
view_calls="$(call_count 'pr view')"
if [ "$list_calls" = "1" ]; then ok 'exactly one "pr list" call'; else bad 'exactly one "pr list" call' "count: $list_calls"; fi
if [ "$view_calls" = "0" ]; then ok 'zero "pr view" calls when there is no PR'; else bad 'zero "pr view" calls when there is no PR' "count: $view_calls"; fi
if [ -z "$out" ]; then ok 'and no notice'; else bad 'and no notice' "got: $out"; fi
teardown

echo '--- NETWORK COST: an open PR costs exactly TWO gh calls on a fresh state ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 REQUEST-CHANGES
run_hook >/dev/null
list_calls="$(call_count 'pr list')"
view_calls="$(call_count 'pr view')"
if [ "$list_calls" = "1" ] && [ "$view_calls" = "1" ]; then
  ok 'exactly one pr list + one pr view on a fresh outstanding state'
else
  bad 'exactly one pr list + one pr view on a fresh outstanding state' "list=$list_calls view=$view_calls"
fi
teardown

# ══════════════════════════════════════════════════════════════════════════════════════════════
echo '--- DEBOUNCE: the same (PR, head) does not re-notify within a session ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 REQUEST-CHANGES
first="$(run_hook)"
second="$(run_hook)"
if [ -n "$first" ]; then ok 'first call fires'; else bad 'first call fires' 'got empty'; fi
if [ -z "$second" ]; then ok 'second call on the SAME state is silent'; else bad 'second call on the SAME state is silent' "got: $second"; fi
teardown

echo '--- DEBOUNCE bounds cost too: the repeat call skips the heavier pr-view read ---'
# REWRITTEN 2026-09-11 (#385 round 2), and this assertion is the one that had to CHANGE rather than
# be preserved — so it is worth saying exactly what moved and why.
#
# It used to drive a fixture with an outstanding verdict and NO harness marker, and assert ONE
# `pr view` across two turns. That held while a single key covered every signal. Per-signal keys
# make it false for that fixture BY DESIGN: only the verdict key gets armed, so the second turn has
# a signal it has never evaluated and must fetch to evaluate it.
#
# THE PROPERTY IS NOT DROPPED, IT IS SPLIT IN TWO, and the second half is new. The strong form —
# nothing more to say means nothing more to fetch — is asserted below on a fixture where BOTH
# signals have fired. The priced cost is asserted immediately after, as a cost, so that collapsing
# the keys back into one (which is what caused the #294 regression) turns it RED instead of reading
# as an optimisation.
setup
checkout_branch feat/x
open_pr 150 abc123
view_gate_and_harness abc123 REQUEST-CHANGES oldbbb   # BOTH signals fire on turn 1
run_hook >/dev/null   # arms both keys
run_hook >/dev/null   # both armed -> must short-circuit before the second gh call
view_calls="$(call_count 'pr view')"
if [ "$view_calls" = "1" ]; then
  ok 'with BOTH signals reported, the debounced repeat makes no additional "pr view" call'
else
  bad 'with BOTH signals reported, the debounced repeat makes no additional "pr view" call' "pr view calls: $view_calls"
fi
teardown

echo '--- DEBOUNCE re-arms when the head moves ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 REQUEST-CHANGES
run_hook >/dev/null
open_pr 150 def456
view_with_verdict def456 REQUEST-CHANGES
out="$(run_hook)"
if [ -n "$out" ]; then ok 'a new head re-arms the notice'; else bad 'a new head re-arms the notice' 'got empty'; fi
teardown

echo '--- DEBOUNCE is per SESSION: a different session_id is notified independently ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 REQUEST-CHANGES
run_hook >/dev/null   # session sess-1, arms it
payload2="$(jq -n --arg cwd "$repo" --arg sid "sess-2" '{cwd:$cwd, session_id:$sid}')"
out2="$( export PATH="$root/bin:/usr/bin:/bin"; printf '%s' "$payload2" | "$BASH" "$HOOK" 2>/dev/null )"
if [ -n "$out2" ]; then ok 'a different session is notified independently'; else bad 'a different session is notified independently' 'got empty'; fi
teardown

# ══════════════════════════════════════════════════════════════════════════════════════════════
echo '--- stop_hook_active: honoured, zero work done, zero gh calls ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 REQUEST-CHANGES
payload="$(jq -n --arg cwd "$repo" --arg sid "s1" '{cwd:$cwd, session_id:$sid, stop_hook_active:true}')"
out="$( export PATH="$root/bin:/usr/bin:/bin"; printf '%s' "$payload" | "$BASH" "$HOOK" 2>/dev/null )"
total_calls="$(wc -l < "$root/calls.log" | tr -d ' ')"
if [ -z "$out" ]; then ok 'stop_hook_active suppresses the notice'; else bad 'stop_hook_active suppresses the notice' "got: $out"; fi
if [ "$total_calls" = "0" ]; then ok 'stop_hook_active makes zero gh calls'; else bad 'stop_hook_active makes zero gh calls' "calls: $(cat "$root/calls.log")"; fi
teardown

echo '--- SUPPRESSION: an untrusted association cannot suppress OR forge the mark ---'
setup
checkout_branch feat/x
open_pr 150 abc123
jq -n --arg h abc123 --arg body "<!-- gatekeeper-verdict: quality-assurance -->
REQUEST-CHANGES
head: abc123" '{headRefOid:$h, comments:[{body:$body, authorAssociation:"NONE"}]}' > "$root/fix/view.json"
out="$(run_hook)"
if [ -z "$out" ]; then ok 'an untrusted commenter cannot trigger the notice'; else bad 'an untrusted commenter cannot trigger the notice' "got: $out"; fi
teardown

echo '--- exit code is always 0, even on the firing path ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 REQUEST-CHANGES
run_hook >/dev/null
rc=$?
if [ "$rc" = "0" ]; then ok 'exits 0'; else bad 'exits 0' "exit was $rc"; fi
teardown

echo '--- never blocks: no "decision" or "permissionDecision" field, ever ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 REQUEST-CHANGES
out="$(run_hook)"
case "$out" in
  *'"decision"'*|*'permissionDecision'*) bad 'never emits a blocking decision field' "got: $out" ;;
  *) ok 'never emits a blocking decision field' ;;
esac
teardown

echo '--- silence stays silence with no gh/jq on PATH ---'
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 REQUEST-CHANGES
payload="$(jq -n --arg cwd "$repo" --arg sid "s1" '{cwd:$cwd, session_id:$sid}')"
out="$( export PATH="/usr/bin:/bin"; printf '%s' "$payload" | "$BASH" "$HOOK" 2>/dev/null; echo "RC:$?" )"
case "$out" in
  RC:0) ok 'degrades silently and exits 0 without gh (if gh is genuinely absent from a minimal PATH)' ;;
  *RC:0) ok 'exits 0 regardless of gh availability on a minimal PATH' ;;
  *) bad 'exits 0 on a minimal PATH' "got: $out" ;;
esac
teardown

# ══════════════════════════════════════════════════════════════════════════════════════════════
# #385 — THE STALE agents-lead MARKER ARM
#
# Every case below was mutation-checked against the SOURCE (`zombie-loop-detect.sh`), never against
# this file, per `engineering-standards`' "break it on purpose" rule. The two mutations used, and
# what each turned red, are recorded in the PR body; the shape that matters is that the arm's
# THREE-VALUED predicate has a case for each value and each case can fail on its own.
# ══════════════════════════════════════════════════════════════════════════════════════════════

echo '--- #385: the failure this arm exists for — markers present, none at the head ---'
setup
checkout_branch loop/x
open_pr 385 headaaa
view_with_harness_markers headaaa oldbbb oldccc
out="$(run_hook)"
case "$out" in
  *'STALE agents-lead verdict marker'*) ok 'fires when every harness marker names a moved head' ;;
  *) bad 'fires when every harness marker names a moved head' "got: ${out:-<silence>}" ;;
esac
teardown

echo '--- #385: silent when ONE marker names the current head (the re-post practice) ---'
setup
checkout_branch loop/x
open_pr 385 headaaa
view_with_harness_markers headaaa oldbbb headaaa
out="$(run_hook)"
case "$out" in
  *'STALE agents-lead verdict marker'*) bad 'silent when a marker names the current head' "got: $out" ;;
  *) ok 'silent when a marker names the current head — a re-posted marker is not stale' ;;
esac
teardown

echo '--- #385: silent when there is NO harness marker at all (hold 2 is not this hook question) ---'
# THE FALSE-POSITIVE GUARD. A `product` or `content` PR carries no harness marker and must produce
# no notice — this arm never asks whether a marker is OWED, only whether a present one is fresh.
setup
checkout_branch feat/x
open_pr 385 headaaa
view_with_harness_markers headaaa
out="$(run_hook)"
case "$out" in
  *'STALE agents-lead verdict marker'*) bad 'silent with no harness marker' "got: $out" ;;
  *) ok 'silent with no harness marker — it never asks whether one is OWED' ;;
esac
teardown

echo '--- #385: a non-OWNER stale marker is ignored, same author filter as the gate marker ---'
setup
checkout_branch loop/x
open_pr 385 headaaa
jq -n --arg h headaaa --arg b '<!-- harness-lead-verdict: reviewed -->
commit: oldbbb' '{headRefOid:$h, comments:[{body:$b, authorAssociation:"NONE"}]}' > "$root/fix/view.json"
out="$(run_hook)"
case "$out" in
  *'STALE agents-lead verdict marker'*) bad 'ignores a marker from an unprivileged author' "got: $out" ;;
  *) ok 'ignores a marker from an unprivileged author — same filter as the gate marker' ;;
esac
teardown

echo '--- #385: the two signals are INDEPENDENT — a stale marker fires under a CLEARED gate ---'
# The pre-#385 control flow exited at `*) exit 0` on any non-outstanding verdict, so this case is
# the one that proves the restructure actually reaches the new arm rather than riding on the old
# one. APPROVE-AND-MERGE is a clearance: the gate signal is correctly silent here.
setup
checkout_branch loop/x
open_pr 385 headaaa
view_gate_and_harness headaaa APPROVE-AND-MERGE oldbbb
out="$(run_hook)"
case "$out" in
  *'outstanding quality-assurance verdict'*) bad 'a cleared gate verdict stays silent' "got: $out" ;;
esac
case "$out" in
  *'STALE agents-lead verdict marker'*) ok 'a stale marker fires even when the gate verdict is a clearance' ;;
  *) bad 'a stale marker fires even when the gate verdict is a clearance' "got: ${out:-<silence>}" ;;
esac
teardown

echo '--- #385: both signals in ONE notice, and the gate signal is unchanged ---'
setup
checkout_branch loop/x
open_pr 385 headaaa
view_gate_and_harness headaaa REQUEST-CHANGES oldbbb
out="$(run_hook)"
case "$out" in
  *'outstanding quality-assurance verdict'*)
    case "$out" in
      *'STALE agents-lead verdict marker'*) ok 'both signals are carried in one notice' ;;
      *) bad 'both signals are carried in one notice' "harness half missing: $out" ;;
    esac ;;
  *) bad 'both signals are carried in one notice' "gate half missing: ${out:-<silence>}" ;;
esac
teardown

# ══════════════════════════════════════════════════════════════════════════════════════════════
# #475 — WHAT COUNTS AS A MARKER. Three arms, and none of them is redundant:
#   1. a comment that merely QUOTES the literal must NOT silence the arm  (the filed defect)
#   2. a real marker that does not OPEN its comment must still be seen when STALE (it fires)
#   3. the same marker shape at the CURRENT head must silence the arm     (it is read as fresh)
# Arm 3 alone proves nothing — silence is ambiguous between "recognised and fresh" and "not
# recognised at all", which is exactly how the pre-#475 predicate looked healthy. Arm 2 is what
# disambiguates it, so the pair must be read together.
#
# SELF-REFERENTIAL TRAP, named because it is easy to trip: these fixtures contain the marker
# literal, and so does the hook under test. Nothing here greps the TREE for the literal, so the
# fixtures cannot satisfy an assertion about the source; a later arm that does grep the tree must
# exclude this file, or it will pass on its own test data.
# ══════════════════════════════════════════════════════════════════════════════════════════════
echo '--- #475: a gate verdict QUOTING the literal at head does not silence a stale marker ---'
setup
checkout_branch loop/x
open_pr 475 headaaa
jq -n --arg h headaaa '
  {headRefOid:$h,
   comments:[{authorAssociation:"OWNER",
              body:"<!-- harness-lead-verdict: reviewed -->\ncommit: oldbbb"},
             {authorAssociation:"OWNER",
              body:("<!-- gatekeeper-verdict: quality-assurance -->\nAPPROVE-AND-MERGE\nhead: "
                    + $h
                    + "\n\nHold 2: the PR carries a harness-lead-verdict marker, so it is satisfied."
                    + "\nQuoted for context: `<!-- harness-lead-verdict: reviewed -->` at an older head."
                    )}]}
' > "$root/fix/view.json"
out="$(run_hook)"
case "$out" in
  *'STALE agents-lead verdict marker'*)
    ok 'a gate verdict quoting harness-lead-verdict is not counted as a marker' ;;
  *) bad 'a gate verdict quoting harness-lead-verdict is not counted as a marker' \
         "expected the stale signal, got: ${out:-<silence>}" ;;
esac
teardown

echo '--- #475: a gate verdict quoting the envelope AT COLUMN 0 does not silence either ---'
# The -skills#303 shape, and the one arm the line-anchor limb alone does not cover: the gate put
# `<!-- harness-lead-verdict …` at the start of a line inside its own verdict. Only the
# gate-envelope exclusion catches it.
setup
checkout_branch loop/x
open_pr 475 headaaa
jq -n --arg h headaaa '
  {headRefOid:$h,
   comments:[{authorAssociation:"OWNER",
              body:"<!-- harness-lead-verdict: reviewed -->\ncommit: oldbbb"},
             {authorAssociation:"OWNER",
              body:("<!-- gatekeeper-verdict: quality-assurance -->\nAPPROVE-AND-MERGE\nhead: "
                    + $h
                    + "\n\n<!-- harness-lead-verdict quoted for context, not re-graded -->\n")}]}
' > "$root/fix/view.json"
out="$(run_hook)"
case "$out" in
  *'STALE agents-lead verdict marker'*)
    ok 'a gate verdict quoting the envelope at column 0 is not counted as a marker' ;;
  *) bad 'a gate verdict quoting the envelope at column 0 is not counted as a marker' \
         "expected the stale signal, got: ${out:-<silence>}" ;;
esac
teardown

echo '--- #475: a real marker below other prose is still SEEN — stale fires ---'
setup
checkout_branch loop/x
open_pr 475 headaaa
jq -n --arg h headaaa '
  {headRefOid:$h,
   comments:[{authorAssociation:"OWNER",
              body:("<!-- agents-lead-verdict: both spellings posted deliberately -->\n"
                    + "<!-- harness-lead-verdict: reviewed -->\ncommit: oldbbb")}]}
' > "$root/fix/view.json"
out="$(run_hook)"
case "$out" in
  *'STALE agents-lead verdict marker'*)
    ok 'a marker that does not open its comment is still recognised (stale fires)' ;;
  *) bad 'a marker that does not open its comment is still recognised (stale fires)' \
         "expected the stale signal, got: ${out:-<silence>}" ;;
esac
teardown

echo '--- #475: the same marker shape AT HEAD is read as fresh — silent ---'
setup
checkout_branch loop/x
open_pr 475 headaaa
jq -n --arg h headaaa '
  {headRefOid:$h,
   comments:[{authorAssociation:"OWNER",
              body:("<!-- agents-lead-verdict: both spellings posted deliberately -->\n"
                    + "<!-- harness-lead-verdict: reviewed -->\ncommit: " + $h)}]}
' > "$root/fix/view.json"
out="$(run_hook)"
case "$out" in
  *'STALE agents-lead verdict marker'*)
    bad 'a marker below other prose, at head, is read as fresh' "got: $out" ;;
  *) ok 'a marker below other prose, at head, is read as fresh' ;;
esac
teardown

echo '--- #385: the new arm still never blocks, and still costs no extra network call ---'
setup
checkout_branch loop/x
open_pr 385 headaaa
view_with_harness_markers headaaa oldbbb
out="$(run_hook)"
case "$out" in
  *'"decision"'*|*'permissionDecision'*) bad 'the stale-marker notice never blocks' "got: $out" ;;
  *) ok 'the stale-marker notice never blocks' ;;
esac
# ONE `pr view`, not two: the arm reads the payload the gate signal already fetched.
n="$(call_count 'pr view')"
if [ "$n" = "1" ]; then
  ok 'the stale-marker arm adds no second `pr view` call'
else
  bad 'the stale-marker arm adds no second `pr view` call' "pr view called $n time(s)"
fi
teardown

echo '--- #385: debounce covers the new signal too — one notice per (PR, head) per session ---'
setup
checkout_branch loop/x
open_pr 385 headaaa
view_with_harness_markers headaaa oldbbb
first="$(run_hook)"
second="$(run_hook)"
case "$first" in
  *'STALE agents-lead verdict marker'*)
    case "$second" in
      '') ok 'the stale-marker notice is debounced on the second turn at the same head' ;;
      *)  bad 'the stale-marker notice is debounced on the second turn at the same head' "got: $second" ;;
    esac ;;
  *) bad 'the stale-marker notice is debounced on the second turn at the same head' "first did not fire: ${first:-<silence>}" ;;
esac
teardown

echo '--- #385: a MOVED head re-arms — the notice is per (PR, head), not per PR ---'
setup
checkout_branch loop/x
open_pr 385 headaaa
view_with_harness_markers headaaa oldbbb
run_hook >/dev/null
open_pr 385 headzzz
view_with_harness_markers headzzz oldbbb
out="$(run_hook)"
case "$out" in
  *'STALE agents-lead verdict marker'*) ok 'a moved head re-arms the stale-marker notice' ;;
  *) bad 'a moved head re-arms the stale-marker notice' "got: ${out:-<silence>}" ;;
esac
teardown

# ══════════════════════════════════════════════════════════════════════════════════════════════
# #385 ROUND 2 — THE REGRESSION THE GATE FOUND, AND THE ARMS THAT WOULD HAVE CAUGHT IT
#
# The first delivery keyed the debounce on (session, PR, head) with no record of WHICH signal
# fired, so a turn that reported only a stale marker consumed the slot and the NEXT turn's
# outstanding REQUEST-CHANGES went silent — a regression in #294, which is the loop's ONLY
# observation of an outstanding verdict.
#
# THE SUITE PASSED 37/0 WITH THAT DEFECT PRESENT, and the reason generalises: every debounce case
# above drives two turns in the SAME state, so it can only ever observe "silence repeated". A
# suppression bug is invisible to a same-state repeat by construction — it needs two turns whose
# signals DIFFER. That is the shape below, in both orders.
# ══════════════════════════════════════════════════════════════════════════════════════════════

echo '--- #385 R2: a stale-marker turn must NOT silence a verdict landing later at the same head ---'
setup
checkout_branch loop/x
open_pr 385 headaaa
view_gate_and_harness headaaa APPROVE-AND-MERGE oldbbb   # turn 1: clearance + stale marker
first="$(run_hook)"
view_gate_and_harness headaaa REQUEST-CHANGES oldbbb     # turn 2: same head, now outstanding
second="$(run_hook)"
case "$first" in
  *'STALE agents-lead verdict marker'*)
    case "$second" in
      *'outstanding quality-assurance verdict'*)
        ok 'a stale-marker turn does not consume the verdict signal debounce (#294 preserved)' ;;
      *) bad 'a stale-marker turn does not consume the verdict signal debounce (#294 preserved)' \
             "turn 2 said: ${second:-<SILENCE — the outstanding verdict was suppressed>}" ;;
    esac ;;
  *) bad 'a stale-marker turn does not consume the verdict signal debounce (#294 preserved)' \
         "turn 1 did not fire the stale-marker notice: ${first:-<silence>}" ;;
esac
teardown

echo '--- #385 R2: and the mirror — a verdict turn must not silence a marker going stale ---'
# The mirror matters less (an advisory notice rather than #294) and is asserted anyway, because a
# one-directional fix is how the same defect comes back wearing the other hat.
setup
checkout_branch loop/x
open_pr 385 headaaa
view_gate_and_harness headaaa REQUEST-CHANGES headaaa    # turn 1: verdict fires, marker is FRESH
first="$(run_hook)"
view_gate_and_harness headaaa REQUEST-CHANGES oldbbb     # turn 2: same head, marker now stale
second="$(run_hook)"
case "$first" in
  *'outstanding quality-assurance verdict'*)
    case "$second" in
      *'STALE agents-lead verdict marker'*)
        ok 'a verdict turn does not consume the stale-marker signal debounce' ;;
      *) bad 'a verdict turn does not consume the stale-marker signal debounce' \
             "turn 2 said: ${second:-<silence>}" ;;
    esac ;;
  *) bad 'a verdict turn does not consume the stale-marker signal debounce' \
         "turn 1 did not fire the verdict notice: ${first:-<silence>}" ;;
esac
teardown

echo '--- #385 R2: each signal is still debounced against ITSELF (the fix must not remove that) ---'
setup
checkout_branch loop/x
open_pr 385 headaaa
view_gate_and_harness headaaa REQUEST-CHANGES oldbbb
run_hook >/dev/null                                       # both fire, both keys armed
again="$(run_hook)"
if [ -z "$again" ]; then
  ok 'both signals stay debounced on a repeat turn at the same head'
else
  bad 'both signals stay debounced on a repeat turn at the same head' "got: $again"
fi
teardown

echo '--- #385 R2: the PRICE of per-signal keys, asserted AS a price so it cannot be undone quietly ---'
# One signal fires, the other never does, so only one key is armed and the repeat turn MUST fetch
# again to evaluate the unreported one. This is a real cost and it is asserted deliberately:
# collapsing the two keys back into one would make this read 1 and turn this arm RED, which is
# exactly the alarm the first delivery did not have.
setup
checkout_branch feat/x
open_pr 150 abc123
view_with_verdict abc123 REQUEST-CHANGES                  # verdict only; no harness marker ever
run_hook >/dev/null
run_hook >/dev/null
view_calls="$(call_count 'pr view')"
if [ "$view_calls" = "2" ]; then
  ok 'with only ONE signal reported, the repeat turn pays a second `pr view` — the priced cost of per-signal keys'
else
  bad 'with only ONE signal reported, the repeat turn pays a second `pr view` — the priced cost of per-signal keys' \
      "pr view calls: $view_calls (1 means the keys were merged again, which reintroduces the #294 regression)"
fi
teardown

# ══════════════════════════════════════════════════════════════════════════════════════════════
# #522 — CARRY-FORWARD. A stale marker is NOT reported when the tree delta from its own `commit:`
# SHA to the head touches no hold-2 path (hold 2 in agents/quality-assurance.md). Every refusal
# below is asserted as the notice FIRING, because the carry fails closed to the pre-#522 notice.
#
# These cases need REAL commit SHAs, so they build history in the fixture repository; the fake
# heads above ("headaaa", "oldbbb") hold no 40-character SHA and never reach the carry block,
# which is why every earlier arm is unchanged by it.
# ══════════════════════════════════════════════════════════════════════════════════════════════
commit_path() { # path -> prints the new HEAD sha
  mkdir -p "$repo/$(dirname "$1")"
  printf '%s\n' "$RANDOM$RANDOM" >> "$repo/$1"
  git -C "$repo" add -- "$1"
  git -C "$repo" commit -q -m "touch $1"
  git -C "$repo" rev-parse HEAD
}

plugin_repo() { # the plugin repository: manifest at the root, and an origin/main ref
  commit_path .claude-plugin/plugin.json >/dev/null
  git -C "$repo" update-ref refs/remotes/origin/main HEAD
}

consuming_repo() { # no manifest, and an origin/main ref, so ls-tree classifies cleanly
  git -C "$repo" update-ref refs/remotes/origin/main HEAD
}

stale_fires() { # label · output
  case "$2" in
    *'STALE agents-lead verdict marker'*) ok "$1" ;;
    *) bad "$1" "expected the stale notice, got: ${2:-<silence>}" ;;
  esac
}

stays_silent() { # label · output
  case "$2" in
    *'STALE agents-lead verdict marker'*) bad "$1" "got: $2" ;;
    *) ok "$1" ;;
  esac
}

echo '--- #522: a docs-only delta since the marker carries it forward — silent ---'
setup; plugin_repo; checkout_branch loop/x
m="$(commit_path hooks/scripts/x.sh)"
h="$(commit_path docs/notes.md)"
open_pr 522 "$h"; view_with_harness_markers "$h" "$m"
stays_silent 'a delta touching only docs/** carries the marker forward' "$(run_hook)"
teardown

echo '--- #522: the SAME history with a hold-2 path planted in the delta — fires ---'
# The discriminating pair for the case above: one path differs, and the verdict flips.
setup; plugin_repo; checkout_branch loop/x
m="$(commit_path hooks/scripts/x.sh)"
commit_path docs/notes.md >/dev/null
h="$(commit_path hooks/scripts/x.sh)"
open_pr 522 "$h"; view_with_harness_markers "$h" "$m"
stale_fires 'a hold-2 path in the delta refuses the carry' "$(run_hook)"
teardown

echo '--- #522: the #506 shape — scripts/ is inside the plugin-repository class, so it does NOT carry ---'
setup; plugin_repo; checkout_branch loop/x
m="$(commit_path scripts/worklog.py)"
commit_path docs/worklog/README.md >/dev/null
h="$(commit_path scripts/worklog.test.py)"
open_pr 522 "$h"; view_with_harness_markers "$h" "$m"
stale_fires 'a delta touching scripts/ refuses the carry in the plugin repository' "$(run_hook)"
teardown

echo '--- #522: an empty tree delta carries — silent ---'
setup; plugin_repo; checkout_branch loop/x
m="$(commit_path hooks/scripts/x.sh)"
git -C "$repo" commit -q --allow-empty -m 'empty'
h="$(git -C "$repo" rev-parse HEAD)"
open_pr 522 "$h"; view_with_harness_markers "$h" "$m"
stays_silent 'an empty delta carries the marker forward' "$(run_hook)"
teardown

echo '--- #522: an ORPHANED marker (force-push / rebase) refuses even with a docs-only delta ---'
# The marked commit is on a history the head does not contain. The tree delta between the two is
# docs-only, so ONLY the ancestry check can refuse this — that is what makes the case discriminate.
setup; plugin_repo; checkout_branch loop/x
commit_path hooks/scripts/x.sh >/dev/null
git -C "$repo" checkout -q -b orphaned
m="$(commit_path docs/old.md)"
git -C "$repo" checkout -q loop/x
h="$(commit_path docs/new.md)"
open_pr 522 "$h"; view_with_harness_markers "$h" "$m"
stale_fires 'a marked commit that is not an ancestor of the head refuses the carry' "$(run_hook)"
teardown

echo '--- #522: a marker SHA this clone cannot read refuses — silent would be fail-open ---'
setup; plugin_repo; checkout_branch loop/x
commit_path hooks/scripts/x.sh >/dev/null
h="$(commit_path docs/notes.md)"
open_pr 522 "$h"; view_with_harness_markers "$h" 0123456789abcdef0123456789abcdef01234567
stale_fires 'an unreadable marker SHA refuses the carry' "$(run_hook)"
teardown

echo '--- #522: an ABBREVIATED commit: line refuses, even where the full SHA would carry ---'
setup; plugin_repo; checkout_branch loop/x
m="$(commit_path hooks/scripts/x.sh)"
h="$(commit_path docs/notes.md)"
open_pr 522 "$h"; view_with_harness_markers "$h" "${m:0:12}"
stale_fires 'an abbreviated commit: line carries nothing' "$(run_hook)"
teardown

echo '--- #522: markup around the full SHA is tolerated, as in hold 2 — silent ---'
setup; plugin_repo; checkout_branch loop/x
m="$(commit_path hooks/scripts/x.sh)"
h="$(commit_path README.md)"
open_pr 522 "$h"
jq -n --arg h "$h" --arg m "$m" '{headRefOid:$h, comments:[{authorAssociation:"OWNER",
  body:("<!-- harness-lead-verdict: reviewed -->\ncommit: `" + $m + "`")}]}' > "$root/fix/view.json"
stays_silent 'a backticked full SHA on the commit: line carries' "$(run_hook)"
teardown

echo '--- #522: the NEWEST marker carries — silent, older non-carrying markers are not consulted ---'
setup; plugin_repo; checkout_branch loop/x
m1="$(commit_path hooks/scripts/x.sh)"
m2="$(commit_path hooks/scripts/y.sh)"
h="$(commit_path docs/notes.md)"
git -C "$repo" checkout -q -b orphaned2 "$m1"
mo="$(commit_path docs/other.md)"
git -C "$repo" checkout -q loop/x
open_pr 522 "$h"; view_with_harness_markers "$h" "$mo" "$m1" "$m2"
stays_silent 'the newest marker carries even though an older one does not' "$(run_hook)"
teardown

echo '--- #522: a CONSUMING repository uses the harness-path list — scripts/ carries there ---'
setup; consuming_repo; checkout_branch loop/x
m="$(commit_path .github/workflows/ci.yml)"
h="$(commit_path scripts/build.sh)"
open_pr 522 "$h"; view_with_harness_markers "$h" "$m"
stays_silent 'a consuming-repository delta outside the harness-path list carries' "$(run_hook)"
teardown

echo '--- #522: and a harness path in a consuming repository refuses, at any depth ---'
setup; consuming_repo; checkout_branch loop/x
m="$(commit_path scripts/build.sh)"
h="$(commit_path apps/fed/CLAUDE.md)"
open_pr 522 "$h"; view_with_harness_markers "$h" "$m"
stale_fires 'a nested CLAUDE.md in the delta refuses the carry in a consuming repository' "$(run_hook)"
teardown

echo '--- #522: an UNCLASSIFIABLE repository (no origin/main) refuses the carry — scripts/ delta ---'
# Same history as the consuming-repository carry above, minus the origin/main ref. `ls-tree` on
# the missing ref fails, and an unclassified repository carries nothing.
setup; checkout_branch loop/x
m="$(commit_path .github/workflows/ci.yml)"
h="$(commit_path scripts/build.sh)"
open_pr 522 "$h"; view_with_harness_markers "$h" "$m"
stale_fires 'an unreadable origin/main refuses the carry (scripts/ delta)' "$(run_hook)"
teardown

echo '--- #522: an UNCLASSIFIABLE repository refuses even a DOCS-ONLY delta ---'
# The discriminating case for the refusal: under the old "wider class" rule this carried, because
# docs/** is excluded from the plugin-repository class. It must refuse, whatever the delta holds.
setup; checkout_branch loop/x
m="$(commit_path hooks/scripts/x.sh)"
h="$(commit_path docs/notes.md)"
open_pr 522 "$h"; view_with_harness_markers "$h" "$m"
stale_fires 'an unreadable origin/main refuses a docs-only delta' "$(run_hook)"
teardown

echo '--- #522: a QUOTED harness path in a CONSUMING repository refuses the carry ---'
# git quotes a non-ASCII name, so the line starts with a double quote and no ^- or /-anchored
# pattern sees ".claude/". core.quotePath is pinned so the arm does not depend on user config.
setup; consuming_repo; checkout_branch loop/x
git -C "$repo" config core.quotePath true
m="$(commit_path scripts/build.sh)"
h="$(commit_path ".claude/agents/caf$(printf '\303\251').md")"
open_pr 522 "$h"; view_with_harness_markers "$h" "$m"
stale_fires 'a quoted .claude/ path refuses the carry in a consuming repository' "$(run_hook)"
teardown

echo '--- #522: a QUOTED path in the PLUGIN repository is inside the class — refuses ---'
setup; plugin_repo; checkout_branch loop/x
git -C "$repo" config core.quotePath true
m="$(commit_path hooks/scripts/x.sh)"
h="$(commit_path "skills/caf$(printf '\303\251')/SKILL.md")"
open_pr 522 "$h"; view_with_harness_markers "$h" "$m"
stale_fires 'a quoted skills/ path refuses the carry in the plugin repository' "$(run_hook)"
teardown

echo '--- #522: the NEWEST marker governs — an older closing marker does not carry past a newer one ---'
# Older marker at A carries on its own: A -> head is docs-only, because B's hooks change is
# reverted. The newer marker at B is the lens's current word, and B -> head touches hooks/.
setup; plugin_repo; checkout_branch loop/x
a="$(commit_path hooks/scripts/x.sh)"
b="$(commit_path hooks/scripts/x.sh)"
git -C "$repo" revert --no-edit HEAD >/dev/null 2>&1
h="$(commit_path docs/notes.md)"
open_pr 522 "$h"; view_with_harness_markers "$h" "$a" "$b"
stale_fires 'an older carrying marker does not carry past a newer non-carrying one' "$(run_hook)"
teardown

echo '--- #522: a MISSING TREE OBJECT — --is-ancestor exits 0, the diff exits 128 — refuses ---'
# The commit graph is intact, so the ancestry check passes; the diff reads trees and fails. Only
# the diff's own status check can refuse this. Guarded, so the arm cannot pass vacuously.
setup; plugin_repo; checkout_branch loop/x
m="$(commit_path hooks/scripts/x.sh)"
h="$(commit_path docs/notes.md)"
t="$(git -C "$repo" rev-parse "$h:docs")"
rm -f "$repo/.git/objects/${t:0:2}/${t:2}"
ia=0; git -C "$repo" merge-base --is-ancestor "$m" "$h" 2>/dev/null || ia=$?
df=0; git -C "$repo" diff --no-renames --name-only "$m" "$h" >/dev/null 2>&1 || df=$?
if [ "$ia" -eq 0 ] && [ "$df" -ne 0 ]; then
  open_pr 522 "$h"; view_with_harness_markers "$h" "$m"
  stale_fires 'an unreadable delta refuses the carry although the ancestry check passes' "$(run_hook)"
else
  bad 'missing-tree-object fixture' "expected is-ancestor 0 and diff non-zero, got $ia and $df"
fi
teardown

echo '--- #522: a FAILING class filter refuses — its silence must not read as an empty delta ---'
# The carry filter is the hook's only grep, so a stub that prints nothing and exits 2 isolates it.
# The delta is docs-only, which carries with a working grep (the first #522 arm).
setup; plugin_repo; checkout_branch loop/x
m="$(commit_path hooks/scripts/x.sh)"
h="$(commit_path docs/notes.md)"
printf '#!/bin/sh\nexit 2\n' > "$root/bin/grep"; chmod +x "$root/bin/grep"
open_pr 522 "$h"; view_with_harness_markers "$h" "$m"
stale_fires 'a class filter that errors refuses the carry' "$(run_hook)"
teardown

echo '--- #522: a RENAME from hooks/ into docs/ refuses — --no-renames is load-bearing ---'
# Without --no-renames the delta prints only docs/x.sh, which the plugin filter excludes.
setup; plugin_repo; checkout_branch loop/x
m="$(commit_path hooks/scripts/x.sh)"
mkdir -p "$repo/docs"
git -C "$repo" mv hooks/scripts/x.sh docs/x.sh
git -C "$repo" commit -q -m 'move x.sh into docs'
h="$(git -C "$repo" rev-parse HEAD)"
open_pr 522 "$h"; view_with_harness_markers "$h" "$m"
stale_fires 'a hooks/ -> docs/ rename refuses the carry' "$(run_hook)"
teardown

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
