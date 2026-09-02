#!/usr/bin/env bash
# owed-pr-link-detect.test.sh — does the Stop hook fire exactly when the turn ended OWING the owner a
# PR link and surfaced none, and stay silent every other time?
#
# BOTH ARMS ARE MANDATORY AND NEITHER IS SUFFICIENT ALONE. This hook's failure direction is worse than
# its sibling's: it fires on ABSENCE, so a hook that emits unconditionally would flag every turn of
# every session that has an open PR, and a hook that emits never is indistinguishable from a loop that
# always hands the link over. The "silent" arms are therefore the load-bearing half here.
#
# THE TRAP THAT MAKES A MUTATION PROBE WORTHLESS, restated from the sibling because it applies again: a
# probe that silently fails to mutate produces a green indistinguishable from a working gate. Confirm
# the mutation landed — diff the file — before believing the red or the green.
#
# Uses a REAL temporary git repository, because the hook calls `git branch --show-current` and
# `git rev-parse --git-dir` for real and holds its debounce state there. `gh` IS a stub serving
# fixtures and LOGGING every invocation, so the call-count assertions COUNT rather than infer.

set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/owed-pr-link-detect.sh"
pass=0
fail=0

ok()  { printf 'ok    %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL  %s\n     %s\n' "$1" "$2"; fail=$((fail + 1)); }

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
  git -C "$repo" checkout -q -b feat/x

  : > "$root/calls.log"
  transcript="$root/transcript.jsonl"
  : > "$transcript"

  cat > "$root/bin/gh" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "__CALLLOG__"
case "$1 $2" in
  "pr list")
    if [ -f "__FIXDIR__/list.json" ]; then cat "__FIXDIR__/list.json"; else printf '[]\n'; fi ;;
  "pr view")
    if [ -f "__FIXDIR__/pr.json" ]; then cat "__FIXDIR__/pr.json"; fi ;;
esac
exit 0
STUB
  sed -i.bak "s#__CALLLOG__#$root/calls.log#g; s#__FIXDIR__#$root/fix#g" "$root/bin/gh"
  rm -f "$root/bin/gh.bak"
  chmod +x "$root/bin/gh"
}

teardown() { rm -rf "$root"; }

# ── transcript fixture builders — one JSON object per line, the shape Claude Code writes ─────────
human_turn()     { jq -nc --arg t "$1" '{type:"user", message:{content:$t}}' >> "$transcript"; }
assistant_text() { jq -nc --arg t "$1" '{type:"assistant", message:{content:[{type:"text", text:$t}]}}' >> "$transcript"; }
# A tool's OWN stdout coming back — `gh pr create` prints the URL itself, so this must NOT count as
# the link having been handed over.
tool_result()    { jq -nc --arg t "$1" '{type:"user", message:{content:[{type:"tool_result", content:$t}]}}' >> "$transcript"; }

# ── PR fixtures ─────────────────────────────────────────────────────────────────────────────────
checks_green='[{"__typename":"CheckRun","status":"COMPLETED","conclusion":"SUCCESS"}]'
checks_running='[{"__typename":"CheckRun","status":"COMPLETED","conclusion":"SUCCESS"},{"__typename":"CheckRun","status":"IN_PROGRESS","conclusion":null}]'
checks_failing='[{"__typename":"CheckRun","status":"COMPLETED","conclusion":"FAILURE"}]'
checks_none='[]'

no_pr() { printf '[]\n' > "$root/fix/list.json"; }
open_pr() { # number · head
  jq -n --argjson n "$1" --arg h "$2" '[{number:$n, headRefOid:$h}]' > "$root/fix/list.json"
}
pr_fixture() { # state · head · checks_json · verdict ("" for no verdict comment)
  local state="$1" head="$2" checks="$3" verdict="$4"
  if [ -z "$verdict" ]; then
    jq -n --arg s "$state" --arg h "$head" --argjson c "$checks" \
      '{state:$s, headRefOid:$h, statusCheckRollup:$c, comments:[]}' > "$root/fix/pr.json"
  else
    jq -n --arg s "$state" --arg h "$head" --argjson c "$checks" \
      --arg body "<!-- gatekeeper-verdict: quality-assurance -->
$verdict
head: $head" \
      '{state:$s, headRefOid:$h, statusCheckRollup:$c, comments:[{body:$body, authorAssociation:"OWNER"}]}' > "$root/fix/pr.json"
  fi
}

run_hook() { # [session_id]
  payload="$(jq -n --arg cwd "$repo" --arg tp "$transcript" --arg sid "${1:-sess-1}" \
    '{cwd:$cwd, transcript_path:$tp, session_id:$sid}')"
  ( export PATH="$root/bin:/usr/bin:/bin"
    printf '%s' "$payload" | "$BASH" "$HOOK" 2>/dev/null )
}

gh_calls() { wc -l < "$root/calls.log" | tr -d ' '; }

URL='https://github.com/tedeuxx/tadeumendonca-skills/pull/150'
OTHER_URL='https://github.com/tedeuxx/tadeumendonca-skills/pull/151'

# ══════════════════════════════════════════════════════════════════════════════════════════════
# ARM A — IT FIRES. The link was owed and the turn surfaced none.
# ══════════════════════════════════════════════════════════════════════════════════════════════
echo '--- the failure this exists for: open, green, verdict says it is his, and no link ---'
setup
human_turn "keep going"
assistant_text "Merged everything I could and updated the ADR. Nothing else outstanding."
open_pr 150 abc123
pr_fixture OPEN abc123 "$checks_green" APPROVE-PENDING-HUMAN
out="$(run_hook)"
case "$out" in
  *'ended OWING the owner a pull-request link'*) ok 'fires when the link was owed and none was surfaced' ;;
  *) bad 'fires when the link was owed' "got: ${out:-<empty>}" ;;
esac
case "$out" in
  *'PR #150'*) ok 'and it names the PR, so the next turn can act without re-deriving it' ;;
  *) bad 'names the PR' "got: $out" ;;
esac
case "$out" in
  *'"Stop"'*) ok 'emits Stop hookSpecificOutput' ;;
  *) bad 'emits Stop hookSpecificOutput' "got: $out" ;;
esac
case "$out" in
  *'"decision"'*|*'permissionDecision'*) bad 'never emits a blocking decision field' "got: $out" ;;
  *) ok 'never emits a blocking decision field' ;;
esac
# THE ADMISSION IS PART OF THE ARTIFACT, not commentary on it. Without it the notice reads as coverage
# of the incident that produced this hook, which it explicitly is not.
# The needle is the CLAIM, not the character offsets it used to quote. The offsets moved to this
# hook's header (a maintainer reads them once) rather than being reprinted into every session, so an
# arm keyed on `character 20` would have asserted the register rather than the limit.
case "$out" in
  *'is not the one that actually happened'*) ok 'the notice says this is not the failure that actually happened' ;;
  *) bad 'the notice carries its own limit' "got: $out" ;;
esac
teardown

echo '--- the FIFTH literal (#374) also owes a link, and the notice says which act is his ---'
setup
human_turn "go"
assistant_text "Gate ran. All good."
open_pr 150 abc123
pr_fixture OPEN abc123 "$checks_green" APPROVE-EXECUTOR-BLOCKED
out="$(run_hook)"
case "$out" in
  *'APPROVE-EXECUTOR-BLOCKED'*) ok 'fires on the fifth literal' ;;
  *) bad 'fires on the fifth literal' "got: ${out:-<empty>}" ;;
esac
case "$out" in
  *"the owner's hand on the merge"*) ok 'and names the act as the merge, not a decision he holds' ;;
  *) bad 'names the act correctly for the fifth literal' "got: $out" ;;
esac
teardown

echo '--- a tool RESULT carrying the URL is not the orchestrator handing it over ---'
# `gh pr create` prints the URL as its own stdout. Counting that would treat every opened PR as a link
# handed over, and this hook would go silent exactly where it is most needed.
setup
human_turn "go"
assistant_text "Opened it."
tool_result "$URL"
open_pr 150 abc123
pr_fixture OPEN abc123 "$checks_green" APPROVE-PENDING-HUMAN
out="$(run_hook)"
if [ -n "$out" ]; then ok 'a URL only in a tool_result does not discharge the debt'
else bad 'a tool_result URL does not count as handed over' 'got empty'; fi
teardown

echo '--- a link to a DIFFERENT PR does not discharge this one ---'
setup
human_turn "go"
assistant_text "Here is the other one: $OTHER_URL"
open_pr 150 abc123
pr_fixture OPEN abc123 "$checks_green" APPROVE-PENDING-HUMAN
out="$(run_hook)"
if [ -n "$out" ]; then ok "another PR's URL does not discharge #150"
else bad "another PR's URL must not discharge #150" 'got empty'; fi
teardown

# ══════════════════════════════════════════════════════════════════════════════════════════════
# ARM B — IT IS SILENT. Nothing was owed, or the link was surfaced.
# ══════════════════════════════════════════════════════════════════════════════════════════════
echo '--- the link WAS surfaced: silence ---'
setup
human_turn "go"
assistant_text "Ready for you: $URL"
open_pr 150 abc123
pr_fixture OPEN abc123 "$checks_green" APPROVE-PENDING-HUMAN
out="$(run_hook)"
if [ -z "$out" ]; then ok 'silent when the turn surfaced the link'; else bad 'silent when surfaced' "got: $out"; fi
teardown

echo '--- #374 review: a PR number must not be discharged by a LONGER one (prefix collision) ---'
# The first form substring-matched `/pull/${pr_number}`, which makes every PR number a prefix of every
# longer one. Detection-only, so the cost is a MISS — the quiet direction, and the one nobody notices.
# Three cases: the two controls are what stop this arm passing for a hook that fires on everything or
# on nothing.
SHORT_URL='https://github.com/tedeuxx/tadeumendonca-skills/pull/15'
LONG_URL='https://github.com/tedeuxx/tadeumendonca-skills/pull/150'
UNRELATED_URL='https://github.com/tedeuxx/tadeumendonca-skills/pull/99'

# control: the real link WAS handed over -> silent
setup
human_turn "go"
assistant_text "Ready for you: $SHORT_URL"
open_pr 15 abc123
pr_fixture OPEN abc123 "$checks_green" APPROVE-PENDING-HUMAN
out="$(run_hook)"
if [ -z "$out" ]; then ok 'control — PR 15 with a /pull/15 link is silent'
else bad 'control — /pull/15 discharges PR 15' "got: $out"; fi
teardown

# THE PROBE: a link to PR 150 must NOT discharge PR 15.
setup
human_turn "go"
assistant_text "Here is the other one: $LONG_URL"
open_pr 15 abc123
pr_fixture OPEN abc123 "$checks_green" APPROVE-PENDING-HUMAN
out="$(run_hook)"
if [ -n "$out" ]; then ok 'a /pull/150 link does NOT discharge PR 15'
else bad 'a /pull/150 link must not discharge PR 15' 'got empty — the prefix collision is back'; fi
teardown

# control: an unrelated, non-prefix number -> fires, so the arm above is not passing on a hook that
# simply fires whenever the number differs by any means.
setup
human_turn "go"
assistant_text "Unrelated: $UNRELATED_URL"
open_pr 15 abc123
pr_fixture OPEN abc123 "$checks_green" APPROVE-PENDING-HUMAN
out="$(run_hook)"
if [ -n "$out" ]; then ok 'control — an unrelated PR link still fires'
else bad 'control — an unrelated PR link fires' 'got empty'; fi
teardown

# AND THE REVERSE DIRECTION: the longer number must not be discharged by the shorter one either.
setup
human_turn "go"
assistant_text "Ready: $SHORT_URL"
open_pr 150 abc123
pr_fixture OPEN abc123 "$checks_green" APPROVE-PENDING-HUMAN
out="$(run_hook)"
if [ -n "$out" ]; then ok 'a /pull/15 link does NOT discharge PR 150'
else bad 'a /pull/15 link must not discharge PR 150' 'got empty'; fi
teardown

echo '--- the two clearances are the gate acting on itself, and owe nothing ---'
# A PR sitting open under a clearance is a RACE at any single instant — verdict, then merge seconds
# later — indistinguishable from a strand. Treating it as owed would fire on the healthy sequence
# every time. This is why the fifth literal exists rather than this hook guessing.
for v in APPROVE-AND-MERGE APPROVE-AND-MERGE-BOUNDARY; do
  setup
  human_turn "go"
  assistant_text "Gate cleared it; merging."
  open_pr 150 abc123
  pr_fixture OPEN abc123 "$checks_green" "$v"
  out="$(run_hook)"
  if [ -z "$out" ]; then ok "silent on $v — the gate acts on that itself"
  else bad "silent on $v" "got: $out"; fi
  teardown
done

echo '--- REQUEST-CHANGES routes to the BUILDER, so no link is owed ---'
setup
human_turn "go"
assistant_text "Gate wants changes."
open_pr 150 abc123
pr_fixture OPEN abc123 "$checks_green" REQUEST-CHANGES
out="$(run_hook)"
if [ -z "$out" ]; then ok 'silent on REQUEST-CHANGES'; else bad 'silent on REQUEST-CHANGES' "got: $out"; fi
teardown

echo '--- no verdict at the head: the gate has not run, so nothing says the act is his ---'
setup
human_turn "go"
assistant_text "Still building."
open_pr 150 abc123
pr_fixture OPEN abc123 "$checks_green" ""
out="$(run_hook)"
if [ -z "$out" ]; then ok 'silent when no verdict has been posted'; else bad 'silent when no verdict' "got: $out"; fi
teardown

echo '--- the check conditions, each of which alone means nothing is owed yet ---'
setup
human_turn "go"
assistant_text "Pushed."
open_pr 150 abc123
pr_fixture OPEN abc123 "$checks_running" APPROVE-PENDING-HUMAN
out="$(run_hook)"
if [ -z "$out" ]; then ok 'silent while a check is still running'; else bad 'silent while running' "got: $out"; fi
teardown
setup
human_turn "go"
assistant_text "Pushed."
open_pr 150 abc123
pr_fixture OPEN abc123 "$checks_failing" APPROVE-PENDING-HUMAN
out="$(run_hook)"
if [ -z "$out" ]; then ok 'silent on a red pipeline — the loop fixes that, not him'; else bad 'silent on red' "got: $out"; fi
teardown
# AN EMPTY ROLLUP IS NOT GREEN. "every check concluded successfully" is unsatisfiable when there are
# none, and treating an empty rollup as success is the fail-open a lazy `all` gives you.
setup
human_turn "go"
assistant_text "Pushed."
open_pr 150 abc123
pr_fixture OPEN abc123 "$checks_none" APPROVE-PENDING-HUMAN
out="$(run_hook)"
if [ -z "$out" ]; then ok 'silent on an empty check rollup (not treated as green)'; else bad 'silent on no checks' "got: $out"; fi
teardown

echo '--- a closed PR owes nothing ---'
setup
human_turn "go"
assistant_text "Done."
open_pr 150 abc123
pr_fixture MERGED abc123 "$checks_green" APPROVE-PENDING-HUMAN
out="$(run_hook)"
if [ -z "$out" ]; then ok 'silent when the PR is not open'; else bad 'silent when not open' "got: $out"; fi
teardown

echo '--- no PR for this branch: silent, and it costs ONE gh call, not two ---'
setup
human_turn "go"
assistant_text "Working."
no_pr
out="$(run_hook)"
if [ -z "$out" ]; then ok 'silent when the branch has no open PR'; else bad 'silent with no PR' "got: $out"; fi
if [ "$(gh_calls)" = "1" ]; then ok 'and it stops after the cheap list call'
else bad 'stops after the list call' "gh was called $(gh_calls) time(s)"; fi
teardown

echo '--- the debounce: once per (PR, head) per session ---'
setup
human_turn "go"
assistant_text "Nothing to report."
open_pr 150 abc123
pr_fixture OPEN abc123 "$checks_green" APPROVE-PENDING-HUMAN
out1="$(run_hook sess-A)"
if [ -n "$out1" ]; then ok 'first turn fires'; else bad 'first turn fires' 'got empty'; fi
out2="$(run_hook sess-A)"
if [ -z "$out2" ]; then ok 'the same session at the same head is silent'; else bad 'debounced' "got: $out2"; fi
# A MOVED HEAD RE-ARMS IT. The verdict is head-scoped, so a new head is a new question.
open_pr 150 def456
pr_fixture OPEN def456 "$checks_green" APPROVE-PENDING-HUMAN
out3="$(run_hook sess-A)"
if [ -n "$out3" ]; then ok 'a moved head re-arms the notice'; else bad 'a moved head re-arms' 'got empty'; fi
out4="$(run_hook sess-B)"
if [ -n "$out4" ]; then ok 'a different session is told independently'; else bad 'per-session debounce' 'got empty'; fi
teardown

echo '--- turn scoping: a link handed over in an EARLIER turn does not discharge this one ---'
# Without this the hook would read the whole session and go silent forever after the first link.
setup
human_turn "go"
assistant_text "Ready for you: $URL"
human_turn "and now?"
assistant_text "Rebased and pushed."
open_pr 150 abc123
pr_fixture OPEN abc123 "$checks_green" APPROVE-PENDING-HUMAN
out="$(run_hook)"
if [ -n "$out" ]; then ok 'only the current turn counts as having surfaced the link'
else bad 'turn scoping' 'got empty'; fi
teardown

echo '--- degrades silently on every missing input, and never blocks ---'
setup
out="$( export PATH="$root/bin:/usr/bin:/bin"
        jq -n --arg cwd "$repo" '{cwd:$cwd}' | "$BASH" "$HOOK" 2>/dev/null; echo "RC:$?" )"
if [ "$out" = "RC:0" ]; then ok 'no transcript_path: silent, exit 0'; else bad 'no transcript_path' "got: $out"; fi

out="$( export PATH="$root/bin:/usr/bin:/bin"
        printf '' | "$BASH" "$HOOK" 2>/dev/null; echo "RC:$?" )"
if [ "$out" = "RC:0" ]; then ok 'an empty payload: silent, exit 0'; else bad 'empty payload' "got: $out"; fi

human_turn "go"
assistant_text "x"
open_pr 150 abc123
pr_fixture OPEN abc123 "$checks_green" APPROVE-PENDING-HUMAN
payload="$(jq -n --arg cwd "$repo" --arg tp "$transcript" --arg sid "s" '{cwd:$cwd, transcript_path:$tp, session_id:$sid, stop_hook_active:true}')"
out="$( export PATH="$root/bin:/usr/bin:/bin"; printf '%s' "$payload" | "$BASH" "$HOOK" 2>/dev/null )"
if [ -z "$out" ]; then ok 'stop_hook_active=true exits before doing anything'; else bad 'stop_hook_active' "got: $out"; fi

mkdir -p "$root/emptybin"
payload="$(jq -n --arg cwd "$repo" --arg tp "$transcript" --arg sid "s2" '{cwd:$cwd, transcript_path:$tp, session_id:$sid}')"
out="$( export PATH="$root/emptybin"; printf '%s' "$payload" | "$BASH" "$HOOK" 2>/dev/null; echo "RC:$?" )"
if [ "$out" = "RC:0" ]; then ok 'no jq, git or gh on PATH: silent, exit 0'; else bad 'empty PATH' "got: $out"; fi

echo '--- the debounce state never lands in the working tree ---'
untracked="$(git -C "$repo" status --porcelain)"
if [ -z "$untracked" ]; then ok 'the repo working tree is untouched by the state file'
else bad 'the working tree is untouched' "git status reported: $untracked"; fi
teardown

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
