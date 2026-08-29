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

# Run the PreToolUse arm with a given command string.
run_pre() {
  payload="$(jq -n --arg cwd "$repo" --arg c "$1" \
    '{hook_event_name:"PreToolUse", cwd:$cwd, session_id:"sess-1", tool_input:{command:$c}}')"
  ( export PATH="$root/bin:/usr/bin:/bin"; printf '%s' "$payload" | bash "$HOOK" 2>/dev/null )
}

run_stop() { # session_id · stop_hook_active
  payload="$(jq -n --arg cwd "$repo" --arg sid "$1" --argjson active "${2:-false}" \
    '{hook_event_name:"Stop", cwd:$cwd, session_id:$sid, stop_hook_active:$active}')"
  ( export PATH="$root/bin:/usr/bin:/bin"; printf '%s' "$payload" | bash "$HOOK" 2>/dev/null )
}

denied()  { printf '%s' "$1" | grep -q '"permissionDecision": *"deny"'; }
silent()  { [ -z "$(printf '%s' "$1" | tr -d '[:space:]')" ]; }
calls()   { grep -c . "$root/calls.log"; }

# ══ ARM 1 · PreToolUse ═════════════════════════════════════════════════════════════════════════

# 1 · a command that is not a close is not the hook's business — and costs no network call
setup
out="$(run_pre 'gh pr view 12 --json body')"
if silent "$out" && [ "$(calls)" -eq 0 ]; then
  ok "PreToolUse — a non-close Bash command is silent and makes no gh call"
else
  bad "PreToolUse — a non-close Bash command" "output='$out' gh calls=$(calls)"
fi
teardown

# 2 · the founding case: a declared command that does not exist
setup
body 'invocable: /blueprint'
out="$(run_pre 'gh issue close 313')"
if denied "$out" && printf '%s' "$out" | grep -q '/blueprint'; then
  ok "PreToolUse — DENIES a close whose declared /command does not resolve, naming the entry"
else
  bad "PreToolUse — declared /command missing" "$out"
fi
teardown

# 3 · the same declaration, once the command exists — the repair must turn it green
setup
body 'invocable: /blueprint'
printf 'x\n' > "$repo/commands/blueprint.md"
out="$(run_pre 'gh issue close 313')"
if silent "$out"; then
  ok "PreToolUse — ALLOWS once commands/<name>.md exists (the arm reddens on repair, in reverse)"
else
  bad "PreToolUse — declared /command present" "$out"
fi
teardown

# 4 · a skill resolves only when the file exists AND plugin.json declares it
setup
body 'invocable: /declared'
mkdir -p "$repo/skills/declared"
printf 'x\n' > "$repo/skills/declared/SKILL.md"
out="$(run_pre 'gh issue close 1')"
if silent "$out"; then
  ok "PreToolUse — a declared skill with a SKILL.md resolves"
else
  bad "PreToolUse — declared skill present" "$out"
fi
teardown

setup
body 'invocable: /undeclared'
mkdir -p "$repo/skills/undeclared"
printf 'x\n' > "$repo/skills/undeclared/SKILL.md"
out="$(run_pre 'gh issue close 1')"
if denied "$out"; then
  ok "PreToolUse — a SKILL.md absent from plugin.json does NOT resolve (it does not exist to the model)"
else
  bad "PreToolUse — undeclared skill" "$out"
fi
teardown

# 5 · the path route — this is what covers a hook or a detector, not just a typed command
setup
body 'invocable: hooks/scripts/detector.sh'
out="$(run_pre 'gh issue close 431')"
if denied "$out" && printf '%s' "$out" | grep -q 'detector.sh'; then
  ok "PreToolUse — DENIES a declared repo-relative path that does not exist"
else
  bad "PreToolUse — declared path missing" "$out"
fi
teardown

setup
body 'invocable: hooks/scripts/detector.sh'
printf 'x\n' > "$repo/hooks/scripts/detector.sh"
out="$(run_pre 'gh issue close 431')"
if silent "$out"; then
  ok "PreToolUse — ALLOWS a declared repo-relative path that exists"
else
  bad "PreToolUse — declared path present" "$out"
fi
teardown

# 6 · `none` is a declaration, not an absence
setup
body 'invocable: none'
out="$(run_pre 'gh issue close 1')"
if silent "$out"; then
  ok "PreToolUse — 'invocable: none' is an explicit declaration and allows"
else
  bad "PreToolUse — invocable: none" "$out"
fi
teardown

# 7 · the waiver, and its reason floor
setup
body 'invocable: /blueprint
invocable-waived: /blueprint scope narrowed to the registry, ADR-0021'
out="$(run_pre 'gh issue close 313')"
if silent "$out"; then
  ok "PreToolUse — a waiver carrying a reason allows the close"
else
  bad "PreToolUse — waiver with reason" "$out"
fi
teardown

setup
body 'invocable: /blueprint
invocable-waived: /blueprint later'
out="$(run_pre 'gh issue close 313')"
if denied "$out"; then
  ok "PreToolUse — a waiver with a reason under 12 characters does NOT waive"
else
  bad "PreToolUse — waiver with a stub reason" "$out"
fi
teardown

# 8 · THE STATED LIMIT, asserted so it stays visible: no declaration, no check
setup
body 'This Issue promises `/blueprint` and mentions /architecture and commands/nothing.md in prose.'
out="$(run_pre 'gh issue close 313')"
if silent "$out"; then
  ok "PreToolUse — an Issue that DECLARES nothing is invisible here (the limit, asserted not assumed)"
else
  bad "PreToolUse — prose-only issue must not be derived from" "$out"
fi
teardown

# 9 · a close aimed at another repository is not answerable from this tree — and costs no gh call
setup
body 'invocable: /blueprint'
out="$(run_pre 'gh issue close 313 --repo other/elsewhere')"
if silent "$out" && [ "$(calls)" -eq 0 ]; then
  ok "PreToolUse — a cross-repo close is skipped before any network call"
else
  bad "PreToolUse — cross-repo close" "output='$out' gh calls=$(calls)"
fi
teardown

# 9b · the same flag naming THIS repo is checked normally
setup
body 'invocable: /blueprint'
out="$(run_pre 'gh issue close 313 --repo probe/tree')"
if denied "$out"; then
  ok "PreToolUse — --repo naming this checkout's own origin is checked, not skipped"
else
  bad "PreToolUse — --repo naming this origin" "$out"
fi
teardown

# 10 · the issue number is read from a bare number, a #-form and a URL
setup
body 'invocable: /blueprint'
out="$(run_pre 'gh issue close #313 --comment x')"
if denied "$out"; then ok "PreToolUse — reads the issue number from the #N form"
else bad "PreToolUse — #N form" "$out"; fi
out="$(run_pre 'gh issue close https://github.com/probe/tree/issues/313')"
if denied "$out"; then ok "PreToolUse — reads the issue number from an issue URL"
else bad "PreToolUse — URL form" "$out"; fi
teardown

# 11 · a namespaced identifier reduces to the innermost name, which is what the loader reads
setup
body 'invocable: /tadeumendonca-skills:blueprint'
printf 'x\n' > "$repo/commands/blueprint.md"
out="$(run_pre 'gh issue close 313')"
if silent "$out"; then
  ok "PreToolUse — /plugin:name resolves through its bare innermost name"
else
  bad "PreToolUse — namespaced identifier" "$out"
fi
teardown

# 12 · FAIL-OPEN is asserted, because it is the direction that misleads
setup
body ''
out="$(run_pre 'gh issue close 313')"
if silent "$out"; then
  ok "PreToolUse — an unfetchable body fails OPEN (a green here can mean 'could not check')"
else
  bad "PreToolUse — empty body" "$out"
fi
teardown

# 13 · the call shape, since the stub cannot test the --jq expression
setup
body 'invocable: none'
run_pre 'gh issue close 313' >/dev/null
if grep -q -- 'issue view 313 --json body,title' "$root/calls.log"; then
  ok "PreToolUse — reads the body with 'gh issue view <n> --json body,title'"
else
  bad "PreToolUse — issue view call shape" "$(cat "$root/calls.log")"
fi
teardown

# ══ ARM 2 · Stop ═══════════════════════════════════════════════════════════════════════════════

list_one() { # number · title · body
  jq -n --argjson n "$1" --arg t "$2" --arg b "$3" \
    '[{number:$n, title:$t, body:$b, url:"u"}]' > "$root/fix/list.json"
}

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
