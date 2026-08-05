#!/usr/bin/env bash
# session-wip.test.sh — does the queue notice say the TRUE thing about whether each open PR
# has been through the merge gate, and stay silent when it cannot know?
#
# Mutation-checked: every assertion below was verified to fail against a deliberately broken
# hook, because an assertion that cannot fail is worse than none — a defect this repo has
# shipped more than once, and the reason this file exists rather than the hook being read and
# pronounced obviously correct.
#
# `gh` is a stub on PATH serving fixtures from a temp tree. Nothing here reaches the network:
# a suite whose result depends on GitHub being up is testing GitHub.

set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/session-wip.sh"
MARKER='<!-- gatekeeper-verdict: quality-assurance -->'
pass=0
fail=0

ok()  { printf 'ok    %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL  %s\n     %s\n' "$1" "$2"; fail=$((fail + 1)); }

# A throwaway tree holding the fixtures and a `gh` that serves them. The stub dispatches on
# the same two calls the hook actually makes; anything else exits 0 silently, so a hook that
# grew a third call would read as an unavailable answer rather than passing on a stale stub.
setup() {
  root="$(mktemp -d)"
  mkdir -p "$root/bin" "$root/fix"
  cat > "$root/bin/gh" <<STUB
#!/bin/sh
case "\$1 \$2" in
  "pr list") [ -f "$root/fix/list.json" ] && cat "$root/fix/list.json" ;;
  "pr view") [ -f "$root/fix/pr-\$3.json" ] && cat "$root/fix/pr-\$3.json" ;;
esac
exit 0
STUB
  chmod +x "$root/bin/gh"
}

# One entry in the `pr list` payload.
add_pr() { # number · title · author
  printf '{"number":%s,"title":"%s","author":{"login":"%s"},"createdAt":"2026-08-01T00:00:00Z","isDraft":false}\n' \
    "$1" "$2" "$3" >> "$root/fix/entries"
}

build_list() {
  if [ -s "$root/fix/entries" ]; then
    jq -s '.' < "$root/fix/entries" > "$root/fix/list.json"
  else
    printf '[]\n' > "$root/fix/list.json"
  fi
}

# The per-PR payload the hook reads. Passing '' for the comment body means "no comments at
# all"; passing the literal SKIP means the read FAILS (no fixture file), which is the
# degradation path. The 4th argument is the commenter's authorAssociation and defaults to
# OWNER — the only value that made the pre-filter version of this hook pass.
add_pr_view() { # number · headRefOid · comment body · [authorAssociation]
  assoc="${4:-OWNER}"
  case "$3" in
    SKIP) return 0 ;;
    '')   jq -n --arg h "$2" '{headRefOid:$h, comments:[]}' > "$root/fix/pr-$1.json" ;;
    *)    jq -n --arg h "$2" --arg b "$3" --arg a "$assoc" \
            '{headRefOid:$h, comments:[{body:$b, authorAssociation:$a}]}' > "$root/fix/pr-$1.json" ;;
  esac
}

run_hook() {
  ( export PATH="$root/bin:/usr/bin:/bin"
    "$BASH" "$HOOK" 2>/dev/null )
}

expect() { # label · matcher(present|absent|empty) · needle
  out="$(run_hook)"
  case "$2" in
    present)
      case "$out" in
        *"$3"*) ok "$1" ;;
        *)      bad "$1" "expected to find '$3'; got: ${out:-<empty>}" ;;
      esac ;;
    absent)
      case "$out" in
        *"$3"*) bad "$1" "expected NOT to find '$3'; got: $out" ;;
        *)      ok "$1" ;;
      esac ;;
    empty)
      if [ -z "$out" ]; then ok "$1"; else bad "$1" "expected silence; got: $out"; fi ;;
  esac
}

NEEDLE='NO quality-assurance verdict on the current head'

echo '--- the failure this exists for: a PR nobody dispatched the gate on ---'
setup
add_pr 150 'chore: prune an inert deny rule' tedeuxx
build_list
add_pr_view 150 'abc123' ''
expect 'no comments at all is NOT reviewed' present "$NEEDLE"
expect 'and the PR is still listed'         present '#150'
rm -rf "$root"

setup
add_pr 150 'chore: prune an inert deny rule' tedeuxx
build_list
add_pr_view 150 'abc123' 'LGTM, looks fine to me'
expect 'a comment without the marker is not a verdict' present "$NEEDLE"
rm -rf "$root"

echo '--- a real verdict on the current head is NOT annotated ---'
setup
add_pr 150 'chore: prune an inert deny rule' tedeuxx
build_list
add_pr_view 150 'abc123' "$MARKER
APPROVE-AND-MERGE
head: abc123"
expect 'marker + matching head is reviewed' absent  "$NEEDLE"
expect 'and it is still listed'             present '#150'
rm -rf "$root"

echo '--- THE VERDICT IS REPORTED, not merely its existence ---'
# The defect this section exists for, measured on -io#357: a PR sitting at REQUEST-CHANGES
# rendered identically to an approved one, because the check asked "is there a marker at this
# head" and stopped. The listing's whole job is to say which PRs still need something.
for v in REQUEST-CHANGES APPROVE-PENDING-HUMAN; do
  setup
  add_pr 150 'chore: prune an inert deny rule' tedeuxx
  build_list
  add_pr_view 150 'abc123' "$MARKER
$v
head: abc123"
  expect "$v is named on the line"        present "quality-assurance returned $v on the current head"
  expect "$v is NOT read as unreviewed"   absent  "$NEEDLE"
  rm -rf "$root"
done

# The partner half: the one verdict that means "done" must stay silent, or every reviewed PR
# carries a line and the signal dies of noise.
setup
add_pr 150 'chore: prune an inert deny rule' tedeuxx
build_list
add_pr_view 150 'abc123' "$MARKER
APPROVE-AND-MERGE
head: abc123"
expect 'APPROVE-AND-MERGE renders silently' absent 'quality-assurance returned'
rm -rf "$root"

# VERDICT DRIFT — a literal the gate's own persona does not define. Reporting it is the point:
# this is the failure ADR-0007 was opened for, and rendering it as "fine" hides the one thing
# that check exists to see. `APPROVED` is the real historical example — the marker template
# carried it while the verdict set said APPROVE-AND-MERGE.
setup
add_pr 150 'chore: prune an inert deny rule' tedeuxx
build_list
add_pr_view 150 'abc123' "$MARKER
APPROVED
head: abc123"
expect 'an unrecognised literal is reported' present 'UNRECOGNISED verdict on the current head: APPROVED'
expect 'and is not silently treated as approval' absent 'quality-assurance returned'
rm -rf "$root"

echo '--- TWO VERDICTS AT ONE HEAD: the LAST one is the current one ---'
# A re-review posts a second verdict at the same head, so this is the ordinary path rather than an
# edge case. With `.[0]` an APPROVE-AND-MERGE followed by a REQUEST-CHANGES rendered SILENT — this
# hook's own headline defect, on a path it did not cover. GitHub returns comments in creation order.
#
# Both directions are asserted. Without the approve-then-block case the fix would be untested in the
# direction that matters; without the block-then-approve case the check could pass by always taking
# the noisiest verdict rather than the latest.
two_verdicts() { # number · head · first verdict · second verdict
  jq -n --arg h "$2" --arg a "$MARKER
$3
head: $2" --arg b "$MARKER
$4
head: $2" '{headRefOid:$h, comments:[
      {body:$a, authorAssociation:"OWNER"},
      {body:$b, authorAssociation:"OWNER"}]}' > "$root/fix/pr-$1.json"
}

setup
add_pr 150 're-reviewed after changes' tedeuxx
build_list
two_verdicts 150 'abc123' 'APPROVE-AND-MERGE' 'REQUEST-CHANGES'
expect 'approve-then-block reports the BLOCK' present 'quality-assurance returned REQUEST-CHANGES on the current head'
rm -rf "$root"

setup
add_pr 150 're-reviewed after changes' tedeuxx
build_list
two_verdicts 150 'abc123' 'REQUEST-CHANGES' 'APPROVE-AND-MERGE'
expect 'block-then-approve renders silent' absent 'quality-assurance returned'
expect 'and is not read as unreviewed'     absent "$NEEDLE"
rm -rf "$root"

echo '--- STALENESS: a verdict on a superseded head is not a verdict on this code ---'
# The case a naive "does a verdict comment exist" check gets wrong. The gate reviewed
# `old999`; the branch has moved to `abc123` since, so nothing has reviewed what is there now.
setup
add_pr 150 'chore: prune an inert deny rule' tedeuxx
build_list
add_pr_view 150 'abc123' "$MARKER
APPROVE-AND-MERGE
head: old999"
expect 'marker on a stale head is NOT a pass' present "$NEEDLE"
rm -rf "$root"

echo '--- SUPPRESSION: these repos are public, so who wrote the verdict has to matter ---'
# The failure direction that counts. A missing annotation reads as "fine"; a spurious one is
# only noise. So the question is who can make the mark DISAPPEAR — and without an author
# filter the answer is anyone with a GitHub account, since the head SHA is public too.
for assoc in NONE CONTRIBUTOR FIRST_TIME_CONTRIBUTOR; do
  setup
  add_pr 150 'chore: prune an inert deny rule' tedeuxx
  build_list
  add_pr_view 150 'abc123' "$MARKER
APPROVE-AND-MERGE
head: abc123" "$assoc"
  expect "a $assoc comment cannot suppress the mark" present "$NEEDLE"
  rm -rf "$root"
done

# The partner half: the filter must not reject the people who legitimately review here, or it
# annotates every PR forever and the signal dies of noise.
for assoc in OWNER MEMBER COLLABORATOR; do
  setup
  add_pr 150 'chore: prune an inert deny rule' tedeuxx
  build_list
  add_pr_view 150 'abc123' "$MARKER
APPROVE-AND-MERGE
head: abc123" "$assoc"
  expect "a $assoc verdict still counts" absent "$NEEDLE"
  rm -rf "$root"
done

# A payload with no authorAssociation field at all must not be treated as trusted.
setup
add_pr 150 'chore: prune an inert deny rule' tedeuxx
build_list
jq -n --arg h abc123 --arg b "$MARKER
head: abc123" '{headRefOid:$h, comments:[{body:$b}]}' > "$root/fix/pr-150.json"
expect 'a comment with no association is not trusted' present "$NEEDLE"
rm -rf "$root"

echo '--- silent degradation: an unavailable answer must not render as "not reviewed" ---'
# The direction that matters. A hook that cries "unreviewed" on a rate limit is one the loop
# learns to ignore within a week, and then it protects nothing.
setup
add_pr 150 'chore: prune an inert deny rule' tedeuxx
build_list
add_pr_view 150 '' SKIP
expect 'a failed per-PR read annotates nothing' absent  "$NEEDLE"
expect 'but the PR is still listed'              present '#150'
rm -rf "$root"

setup
add_pr 150 'chore: prune an inert deny rule' tedeuxx
build_list
add_pr_view 150 '' ''
expect 'an empty headRefOid annotates nothing' absent "$NEEDLE"
rm -rf "$root"

echo '--- mixed queue: the annotation is per PR, not per session ---'
setup
add_pr 150 'reviewed one' tedeuxx
add_pr 151 'unreviewed one' tedeuxx
build_list
add_pr_view 150 'aaa111' "$MARKER
APPROVE-AND-MERGE
head: aaa111"
add_pr_view 151 'bbb222' ''
out="$(run_hook)"
# ANCHORED TO THE WHOLE LINE, and that is the point rather than a style choice. The previous
# version of the negative case matched "reviewed one — $NEEDLE", which the hook CANNOT emit:
# the annotation is appended after the login and date, so " — tedeuxx, opened …" always sits
# between them. It matched no possible output, so it passed unconditionally — a dead assertion
# inside the section asserting the per-PR property, in a file whose header claims every
# assertion was mutation-verified. It surfaced only because a mutation produced four failures
# where five were predicted. Reading never finds these; counting does.
META=' — tedeuxx, opened 2026-08-01'
case "$out" in
  *"#151 unreviewed one${META} — ${NEEDLE}"*) ok 'the unreviewed PR carries the mark' ;;
  *) bad 'the unreviewed PR carries the mark' "got: $out" ;;
esac
case "$out" in
  *"#150 reviewed one${META} — ${NEEDLE}"*) bad 'the reviewed PR does not' "got: $out" ;;
  *"#150 reviewed one${META}"*)             ok  'the reviewed PR does not' ;;
  *) bad 'the reviewed PR does not' "the reviewed PR was not listed at all; got: $out" ;;
esac
rm -rf "$root"

echo '--- the contract the hook already had must survive ---'
setup
add_pr 150 'chore: something' tedeuxx
build_list
add_pr_view 150 'abc123' ''
expect 'still a SessionStart event' present '"hookEventName"'
expect 'still carries additionalContext' present 'additionalContext'
expect 'still says to drain the queue'  present 'Drain these'
expect 'explains what an UNMARKED line means' present 'absence means'
if run_hook >/dev/null; then ok 'exits 0'; else bad 'exits 0' "exit was $?"; fi
rm -rf "$root"

echo '--- silence stays silence ---'
setup
build_list
expect 'an empty queue says nothing' empty ''
rm -rf "$root"

# Without this, every "absent" assertion above would also pass against a hook that emits
# nothing at all, and the suite would be vacuous in the exact direction it is asserting.
setup
add_pr 150 'chore: something' tedeuxx
build_list
add_pr_view 150 'abc123' ''
expect 'a non-empty queue really does emit' present 'Open pull requests'
rm -rf "$root"

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
