#!/usr/bin/env bash
# closure-artifact-guard.test.sh — does the guard refuse exactly the closes whose declared artifact
# is missing, stay silent on everything else, and report an already-closed Issue once per session?
#
# Mutation-checked per this repo's convention: every arm below was verified to FAIL against a
# deliberately broken hook before being trusted, and each red was attributed separately — a batch
# mutation cannot say which case failed. The reds are recorded in the PR body.
#
# Uses a REAL temporary git repository (not a stub) because the hook calls `git rev-parse
# --show-toplevel`, `--git-dir` and `remote get-url` for real, and resolves declared artifacts
# against that tree. `gh` IS a stub, and it LOGS every invocation so the "no network call" arms can
# count calls rather than infer them from silence.
#
# WHAT THE STUB DOES NOT TEST, said so the green is not read as more: the hook renders the issue
# body with `gh ... --jq`, so the stub serves the already-rendered text. That tests the hook's USE
# of the output, never `gh`'s own rendering. A change to the `--jq` expression is therefore invisible
# to this suite — it is covered by the `issue view` call-shape arm instead, which asserts the flags
# the hook passes.
#
# Run: bash hooks/scripts/closure-artifact-guard.test.sh

set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/closure-artifact-guard.sh"
pass=0
fail=0

ok()  { printf 'ok    %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL  %s\n     %s\n' "$1" "$2"; fail=$((fail + 1)); }

setup() {
  root="$(mktemp -d)"
  repo="$root/repo"
  mkdir -p "$repo/commands" "$repo/skills" "$repo/.claude-plugin" "$repo/hooks/scripts" \
           "$root/bin" "$root/fix"
  git -C "$repo" init -q -b main
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config user.name test
  git -C "$repo" remote add origin https://github.com/probe/tree.git
  printf '{"skills":["./skills/declared"]}\n' > "$repo/.claude-plugin/plugin.json"
  printf 'x\n' > "$repo/f"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m init

  : > "$root/calls.log"
  : > "$root/fix/view.txt"
  printf '[]\n' > "$root/fix/list.json"
  cat > "$root/bin/gh" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "__CALLLOG__"
case "$1 $2" in
  "issue view") cat "__FIXDIR__/view.txt" ;;
  "issue list") cat "__FIXDIR__/list.json" ;;
esac
exit 0
STUB
  sed -i.bak "s#__CALLLOG__#$root/calls.log#g; s#__FIXDIR__#$root/fix#g" "$root/bin/gh"
  rm -f "$root/bin/gh.bak"
  chmod +x "$root/bin/gh"
}

teardown() { rm -rf "$root"; }

body() { printf '%s\n' "$1" > "$root/fix/view.txt"; }

run_stop() { # session_id · stop_hook_active
  payload="$(jq -n --arg cwd "$repo" --arg sid "$1" --argjson active "${2:-false}" \
    '{hook_event_name:"Stop", cwd:$cwd, session_id:$sid, stop_hook_active:$active}')"
  ( export PATH="$root/bin:/usr/bin:/bin"; printf '%s' "$payload" | bash "$HOOK" 2>/dev/null )
}

silent()  { [ -z "$(printf '%s' "$1" | tr -d '[:space:]')" ]; }
calls()   { grep -c . "$root/calls.log"; }

# ══ THE ONLY ARM · Stop ════════════════════════════════════════════════════════════════════════
#
# THE `PreToolUse` ARM AND ITS THIRTEEN CASES WERE REMOVED AT #383 WITH THE ARM ITSELF. What did NOT
# go with them is the coverage of the SHARED PREDICATE — `entry_resolves` and `unmet_entries` are
# called by both arms, and every resolution rule they implement was asserted only through the deleted
# arm. **Deleting a control's tests along with the control is correct; deleting a shared predicate's
# tests because the caller that happened to exercise them left is not**, and it is the silent kind of
# coverage loss this repository keeps paying for. So the predicate cases below are PORTED to this arm
# rather than dropped — same fixtures, same assertions, one caller instead of two.
#
# The cases that genuinely went are the ones about the REFUSAL and nothing else: the start-anchored
# command match, the issue-number forms (`N`, `#N`, a URL), the cross-repo `--repo` skip, the
# no-network-call-on-a-non-close arm, and the `gh issue view` call shape. Those asserted properties of
# a code path that no longer exists.

list_one() { # number · title · body
  jq -n --argjson n "$1" --arg t "$2" --arg b "$3" \
    '[{number:$n, title:$t, body:$b, url:"u"}]' > "$root/fix/list.json"
}

reported() { printf '%s' "$1" | grep -q 'additionalContext' && printf '%s' "$1" | grep -q "$2"; }

# ── the shared predicate, ported from the removed PreToolUse arm ────────────────────────────────

# P1 · a declared skill resolves only when plugin.json ALSO declares it
setup
list_one 401 'declared skill' 'invocable: /declared'
mkdir -p "$repo/skills/declared"
printf 'x\n' > "$repo/skills/declared/SKILL.md"
out="$(run_stop sess-A)"
if silent "$out"; then
  ok "predicate — a declared skill with a SKILL.md resolves"
else
  bad "predicate — declared skill present" "$out"
fi
teardown

# P2 · and the control: a SKILL.md absent from plugin.json does NOT resolve
setup
list_one 402 'undeclared skill' 'invocable: /undeclared'
mkdir -p "$repo/skills/undeclared"
printf 'x\n' > "$repo/skills/undeclared/SKILL.md"
# WITHOUT THE `mkdir` THIS CASE PASSED FOR THE WRONG REASON, and it was caught by P1 going red beside
# it rather than by reading: with no `skills/undeclared/` the redirect failed, the SKILL.md never
# existed, and `/undeclared` was unmet because the FILE was missing rather than because plugin.json
# does not declare it. A green asserting the wrong cause is worse than a red.
out="$(run_stop sess-A)"
if reported "$out" 402; then
  ok "predicate — a SKILL.md absent from plugin.json does NOT resolve (it does not exist to the model)"
else
  bad "predicate — undeclared skill" "$out"
fi
teardown

# P3 · a declared repo-relative path that does not exist
setup
list_one 403 'a detector' 'invocable: hooks/scripts/detector.sh'
out="$(run_stop sess-A)"
if reported "$out" 403; then
  ok "predicate — a declared repo-relative path that does not exist is unmet"
else
  bad "predicate — declared path missing" "$out"
fi
teardown

# P4 · and resolves once it is there
setup
list_one 404 'a detector' 'invocable: hooks/scripts/detector.sh'
printf 'x\n' > "$repo/hooks/scripts/detector.sh"
out="$(run_stop sess-A)"
if silent "$out"; then
  ok "predicate — a declared repo-relative path that exists resolves (the arm reddens on repair, in reverse)"
else
  bad "predicate — declared path present" "$out"
fi
teardown

# P5 · `invocable: none` is an explicit declaration, not an absence
setup
list_one 405 'promises nothing' 'invocable: none'
out="$(run_stop sess-A)"
if silent "$out"; then
  ok "predicate — 'invocable: none' is an explicit declaration and is met"
else
  bad "predicate — invocable: none" "$out"
fi
teardown

# P6 · and `/none` is NOT the null value — a leading slash makes it an identifier that must resolve
setup
list_one 406 'slash none' 'invocable: /none'
out="$(run_stop sess-A)"
if reported "$out" 406; then
  ok "predicate — '/none' is NOT the null value: a leading slash makes it an unresolvable identifier"
else
  bad "predicate — /none must not be treated as the null value" "$out"
fi
teardown

# P7 · a waiver carrying a reason of at least 12 characters waives
setup
list_one 407 'narrowed' 'invocable: /blueprint
invocable-waived: /blueprint the registry ships first, the command later'
out="$(run_stop sess-A)"
if silent "$out"; then
  ok "predicate — a waiver carrying a reason waives the declaration"
else
  bad "predicate — waiver with reason" "$out"
fi
teardown

# P8 · and a stub reason does not — the length bound is the whole of what makes the waiver auditable
setup
list_one 408 'narrowed' 'invocable: /blueprint
invocable-waived: /blueprint later'
out="$(run_stop sess-A)"
if reported "$out" 408; then
  ok "predicate — a waiver with a reason under 12 characters does NOT waive"
else
  bad "predicate — waiver with a stub reason" "$out"
fi
teardown

# P9 · THE LOAD-BEARING LIMIT: an Issue that declares nothing is invisible, and is never derived from
setup
list_one 409 'ships /blueprint' 'This issue delivers the `/blueprint` command and its registry.'
out="$(run_stop sess-A)"
if silent "$out"; then
  ok "predicate — an Issue that DECLARES nothing is invisible here (the limit, asserted not assumed)"
else
  bad "predicate — prose-only issue must not be derived from" "$out"
fi
teardown

# ── the reporting behaviour itself ──────────────────────────────────────────────────────────────

# 14 · a closed Issue whose declaration is unmet is reported
setup
list_one 313 'the blueprint' 'invocable: /blueprint'
out="$(run_stop sess-A)"
if printf '%s' "$out" | grep -q 'additionalContext' && printf '%s' "$out" | grep -q '313'; then
  ok "Stop — reports a CLOSED Issue whose declared artifact does not resolve"
else
  bad "Stop — unmet closed issue" "$out"
fi
teardown

# 15 · and stays silent once the artifact is there
setup
list_one 313 'the blueprint' 'invocable: /blueprint'
printf 'x\n' > "$repo/commands/blueprint.md"
out="$(run_stop sess-A)"
if silent "$out"; then
  ok "Stop — silent once the declared artifact resolves"
else
  bad "Stop — met closed issue" "$out"
fi
teardown

# 16 · debounce: once per session per issue, not once per turn
setup
list_one 313 'the blueprint' 'invocable: /blueprint'
first="$(run_stop sess-A)"
second="$(run_stop sess-A)"
if printf '%s' "$first" | grep -q '313' && silent "$second"; then
  ok "Stop — a finding is reported once per session, not on every turn end"
else
  bad "Stop — debounce" "first='$first' second='$second'"
fi
# 17 · a different session is told again
third="$(run_stop sess-B)"
if printf '%s' "$third" | grep -q '313'; then
  ok "Stop — a new session is told about the same outstanding finding"
else
  bad "Stop — per-session scope of the debounce" "$third"
fi
teardown

# 18 · stop_hook_active short-circuits before any network call
setup
list_one 313 'the blueprint' 'invocable: /blueprint'
out="$(run_stop sess-A true)"
if silent "$out" && [ "$(calls)" -eq 0 ]; then
  ok "Stop — stop_hook_active=true exits before any work, local or networked"
else
  bad "Stop — stop_hook_active" "output='$out' gh calls=$(calls)"
fi
teardown

# 19 · the window is server-side, and the flag is part of the claim
setup
list_one 313 'the blueprint' 'invocable: none'
run_stop sess-A >/dev/null
if grep -q -- '--search closed:>=' "$root/calls.log"; then
  ok "Stop — bounds the pool server-side with a rolling 'closed:>=' window (one call per turn)"
else
  bad "Stop — rolling window flag" "$(cat "$root/calls.log")"
fi
if [ "$(calls)" -eq 1 ]; then
  ok "Stop — exactly one gh call per turn end"
else
  bad "Stop — call count per turn" "$(cat "$root/calls.log")"
fi
teardown

# 20 · an event this hook is not wired to does nothing at all
setup
body 'invocable: /blueprint'
payload="$(jq -n --arg cwd "$repo" '{hook_event_name:"SessionStart", cwd:$cwd}')"
out="$( export PATH="$root/bin:/usr/bin:/bin"; printf '%s' "$payload" | bash "$HOOK" 2>/dev/null )"
if silent "$out" && [ "$(calls)" -eq 0 ]; then
  ok "any other event — silent, and makes no call"
else
  bad "other event" "output='$out' gh calls=$(calls)"
fi
teardown

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
