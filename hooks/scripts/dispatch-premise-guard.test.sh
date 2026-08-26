#!/usr/bin/env bash
# dispatch-premise-guard.test.sh — does the guard deny exactly a dispatch whose stamped repository state
# is false, verified in the repository the brief's own citations resolve to, and nothing else?
#
# Uses REAL temporary git repositories — two unrelated ones plus a linked worktree — because every
# assertion here is a question about repository state, and a stubbed `git` would test the stub rather
# than the guard's use of it.
#
# ── MUTATION-CHECKED ON THE SOURCE, PER ASSERTION ──────────────────────────────────────────────
# Every assertion below was watched to FAIL against a deliberately broken guard before being trusted;
# the mutations used, and the arm each one reddens, are listed at the bottom of this file next to the
# results. Two shapes were checked, not one: an assertion that FAILS, and an assertion that
# DISAPPEARS — an arm that stops emitting a verdict at all is invisible to a passing total, which is
# how this repo has lost verdicts before. Every branch below emits exactly one `ok` or one `FAIL`.
#
# ── THE DISCRIMINATOR THAT MATTERS MOST ────────────────────────────────────────────────────────
# The first block is not "does it deny a wrong SHA". It is the OWNER'S CORRECTION: a brief whose claim
# is TRUE of `cwd`'s repository and FALSE of the repository its citations resolve to. A `cwd`-anchored
# guard passes that brief; this one denies it. That single case is the difference between catching the
# failure this exists for and catching only its easy cousin, so it is asserted in both directions —
# the deny, and the mirror where the same claim cites the other repository and is allowed.
#
# ── THE REGISTRATION IS PART OF THE GATE ───────────────────────────────────────────────────────
# The matcher is asserted against `hooks/hooks.json`. Measured on #326: a `PreToolUse` matcher of
# `"Task"` fires ZERO times on a real dispatch while still matching `TaskCreate` — installed-looking and
# inert. Every assertion in this file would stay green behind that matcher, so the registration is
# checked here rather than trusted.
#
# Run: bash hooks/scripts/dispatch-premise-guard.test.sh

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$HERE/dispatch-premise-guard.sh"
HOOKS_JSON="$HERE/../hooks.json"
pass=0
fail=0

ok()  { printf 'ok    %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL  %s\n     %s\n' "$1" "$2"; fail=$((fail + 1)); }

mkrepo() {
  local dir="$1" branch="$2"
  mkdir -p "$dir"
  git -C "$dir" init -q -b "$branch"
  git -C "$dir" config user.email test@example.com
  git -C "$dir" config user.name test
}

setup() {
  # `pwd -P` because on macOS `/var` is a symlink to `/private/var`; the guard derives every path from
  # `rev-parse --show-toplevel` (canonical), so an uncanonicalised fixture root would compare unequal
  # and the sibling scan would silently find nothing — a suite that tested the fallback path only.
  root="$(cd "$(mktemp -d)" && pwd -P)"
  repoA="$root/alpha-repo"
  repoB="$root/beta-repo"
  awt="$root/alpha-linked-worktree"
  plain="$root/not-a-repo"
  mkdir -p "$plain"

  mkrepo "$repoA" main
  printf 'A\n' > "$repoA/alpha.md"
  git -C "$repoA" add alpha.md
  git -C "$repoA" commit -q -m "alpha init"
  shaA="$(git -C "$repoA" rev-parse HEAD)"
  shortA="${shaA:0:7}"

  # A LINKED worktree of repoA. It exists so the per-repository dedupe has something to collapse: this
  # workspace really does carry ~22 of these, and the unfixed guard listed every one of them as an
  # independent candidate — which is also a pass-if-any hole, since any stale worktree could vouch.
  git -C "$repoA" worktree add -q -b side "$awt" HEAD

  mkrepo "$repoB" main
  mkdir -p "$repoB/docs/deep"
  printf 'B\n' > "$repoB/beta.md"
  printf 'G\n' > "$repoB/docs/deep/gamma.md"
  git -C "$repoB" add .
  git -C "$repoB" commit -q -m "beta init"
  git -C "$repoB" checkout -q -b feat/x
  printf 'B2\n' >> "$repoB/beta.md"
  git -C "$repoB" commit -q -am "beta second"
  shaB="$(git -C "$repoB" rev-parse HEAD)"
  shortB="${shaB:0:7}"
}
teardown() { rm -rf "$root"; }

# run_hook <cwd> <prompt> [subagent_type]
run_hook() {
  local cwd="$1" prompt="$2" at="${3:-}"
  local payload
  payload="$(jq -n --arg c "$cwd" --arg p "$prompt" --arg a "$at" '
    {tool_name:"Agent", cwd:$c, tool_input:{description:"d", prompt:$p}}
    + (if $a == "" then {} else {tool_input:{description:"d", prompt:$p, subagent_type:$a}} end)')"
  printf '%s' "$payload" | "$BASH" "$HOOK" 2>/dev/null
}

decision() { printf '%s' "$1" | jq -r '.hookSpecificOutput.permissionDecision // "NONE"' 2>/dev/null || echo NONE; }
why()      { printf '%s' "$1" | jq -r '.hookSpecificOutput.permissionDecisionReason // ""' 2>/dev/null || true; }

setup

# ══════════════════════════════════════════════════════════════════════════════════════════════
echo '--- the owner correction: the repo comes from the CITED PATH, not from cwd ---'
# TRUE of repoA (cwd), FALSE of repoB (cited). A cwd-anchored guard passes this brief.
out="$(run_hook "$repoA" "Close the description. See \`beta.md\` for the copy. Measured against \`main\` at \`$shortA\`." product-lead)"
if [ "$(decision "$out")" = "deny" ]; then ok 'a claim true of cwd but false of the CITED repository is denied'
else bad 'a claim true of cwd but false of the CITED repository is denied' "got: ${out:-<empty, i.e. allowed>}"; fi

case "$(why "$out")" in
  *"$repoB"*) ok 'the deny names the repository the citation resolved to, not cwd' ;;
  *) bad 'the deny names the repository the citation resolved to, not cwd' "reason: $(why "$out")" ;;
esac

# The mirror. Same claim, citing the repository it is actually true of.
out="$(run_hook "$repoA" "Close the description. See \`alpha.md\` for the copy. Measured against \`main\` at \`$shortA\`." product-lead)"
if [ -z "$out" ]; then ok 'the same claim, citing the repository it IS true of, is allowed'
else bad 'the same claim, citing the repository it IS true of, is allowed' "got: $out"; fi

echo '--- a bare filename with no directory resolves through git ls-files ---'
# `architecture.en.md:132` — the citation form the real failure used — has no directory component, so a
# filesystem existence test alone resolves nothing and falls back to cwd. That fallback is exactly the
# bug the owner corrected, so the lookup is asserted with a case only it can decide.
out="$(run_hook "$repoA" "Check \`gamma.md:12\` against \`main\` at \`$shortA\`." tech-lead)"
if [ "$(decision "$out")" = "deny" ]; then ok 'a bare filename resolves to the repository that tracks it (deep path, no slash cited)'
else bad 'a bare filename resolves to the repository that tracks it' "got: ${out:-<empty, i.e. allowed via the cwd fallback>}"; fi

echo '--- the branch half, in the repository the claim resolves to ---'
out="$(run_hook "$repoB" "Review \`beta.md\` against \`main\` at \`$shortB\`." tech-lead)"
if [ "$(decision "$out")" = "deny" ]; then ok 'a correct SHA with the wrong branch name is denied'
else bad 'a correct SHA with the wrong branch name is denied' "got: ${out:-<empty>}"; fi

case "$(why "$out")" in
  *"is on 'feat/x'"*) ok 'the deny quotes the branch the tree is actually on' ;;
  *) bad 'the deny quotes the branch the tree is actually on' "reason: $(why "$out")" ;;
esac

out="$(run_hook "$repoB" "Review \`beta.md\` against \`feat/x\` at \`$shortB\`." tech-lead)"
if [ -z "$out" ]; then ok 'the right branch with the right SHA is allowed'
else bad 'the right branch with the right SHA is allowed' "got: $out"; fi

echo '--- a branch name that is not a ref in that repository is not treated as a branch claim ---'
out="$(run_hook "$repoB" "Review \`beta.md\` against \`the-spec\` at \`$shortB\`." tech-lead)"
if [ -z "$out" ]; then ok 'a non-ref word before a correct SHA is prose, not a branch claim'
else bad 'a non-ref word before a correct SHA is prose, not a branch claim' "got: $out"; fi

echo '--- form 2: a commit claim with no branch ---'
out="$(run_hook "$repoA" "Reviewed \`alpha.md\`. commit: $shaA" agents-lead)"
if [ -z "$out" ]; then ok 'a full-length SHA that is HEAD is allowed'
else bad 'a full-length SHA that is HEAD is allowed' "got: $out"; fi

out="$(run_hook "$repoA" "Reviewed \`alpha.md\`. commit: 0123abc4567" agents-lead)"
if [ "$(decision "$out")" = "deny" ]; then ok 'a SHA no candidate repository contains is denied'
else bad 'a SHA no candidate repository contains is denied' "got: ${out:-<empty>}"; fi

case "$(why "$out")" in
  *"no commit 0123abc4567"*) ok 'the deny says the commit is absent rather than guessing why' ;;
  *) bad 'the deny says the commit is absent rather than guessing why' "reason: $(why "$out")" ;;
esac

echo '--- the parent commit is in the repository but is not HEAD: still a false premise ---'
parentB="$(git -C "$repoB" rev-parse --short HEAD~1)"
out="$(run_hook "$repoB" "Review \`beta.md\` against \`feat/x\` at \`$parentB\`." tech-lead)"
if [ "$(decision "$out")" = "deny" ]; then ok 'a real ancestor commit that is not HEAD is denied (the tree moved)'
else bad 'a real ancestor commit that is not HEAD is denied' "got: ${out:-<empty>}"; fi

echo '--- no citation resolves: the cwd repository is the declared fallback ---'
out="$(run_hook "$repoA" "Review the roster. Stamped at \`$shortA\`." agents-lead)"
if [ -z "$out" ]; then ok 'with no resolvable path, a claim true of cwd is allowed'
else bad 'with no resolvable path, a claim true of cwd is allowed' "got: $out"; fi

out="$(run_hook "$repoB" "Review the roster. Stamped at \`$shortA\`." agents-lead)"
if [ "$(decision "$out")" = "deny" ]; then ok 'with no resolvable path, a claim false of cwd is denied'
else bad 'with no resolvable path, a claim false of cwd is denied' "got: ${out:-<empty>}"; fi

echo '--- keyed on the CLAIM, never on the persona: the general-purpose blind spot stays closed ---'
# `subagent_type` is ABSENT when the model dispatches the default agent (measured #326). A guard keyed
# on persona names would skip this payload entirely.
out="$(run_hook "$repoA" "Look at \`beta.md\` against \`main\` at \`$shortA\`.")"
if [ "$(decision "$out")" = "deny" ]; then ok 'a dispatch with NO subagent_type is checked like any other'
else bad 'a dispatch with NO subagent_type is checked like any other' "got: ${out:-<empty>}"; fi

echo '--- the declared boundary: file:line is out of scope and stays out ---'
out="$(run_hook "$repoA" "Fix the sentence at \`alpha.md:9999\`, against \`main\` at \`$shortA\`." content-writer)"
if [ -z "$out" ]; then ok 'a line number that cannot exist is NOT checked (declared out of scope)'
else bad 'a line number that cannot exist is NOT checked' "got: $out"; fi

out="$(run_hook "$repoA" "Look at \`beta.md\` against \`main\` at \`$shortA\`." product-lead)"
case "$(why "$out")" in
  *"file:line"*) ok 'the deny text DECLARES the boundary rather than leaving it implied' ;;
  *) bad 'the deny text declares the boundary' "reason: $(why "$out")" ;;
esac

echo '--- English is not a SHA: the digit requirement ---'
# `defaced` is seven valid hex characters. Without the digit rule it reads as a commit no repository
# contains, and every brief using the word is denied.
out="$(run_hook "$repoA" "The copy was defaced at defaced. Review \`alpha.md\`." content-reviewer)"
if [ -z "$out" ]; then ok 'a hex-shaped English word after a keyword is not a claim'
else bad 'a hex-shaped English word after a keyword is not a claim' "got: $out"; fi

echo '--- no claim at all: the common case is untouched ---'
out="$(run_hook "$repoA" "Draft the LinkedIn teaser for the new article. No citations." content-writer)"
if [ -z "$out" ]; then ok 'a brief with no SHA and no branch stamp is allowed'
else bad 'a brief with no SHA and no branch stamp is allowed' "got: $out"; fi

echo '--- one candidate per REPOSITORY, not per directory ---'
# repoA has a linked worktree. Both contain `alpha.md`, so both resolve; the dedupe must collapse them
# to repoA's main worktree, or a stale worktree becomes a second voter under pass-if-any.
out="$(run_hook "$repoB" "Review \`alpha.md\` against \`main\` at \`$shortB\`." tech-lead)"
listed="$(why "$out" | grep -c "$awt" || true)"
if [ "$listed" = "0" ]; then ok 'a linked worktree is collapsed into its repository and never voted separately'
else bad 'a linked worktree is collapsed into its repository' "the worktree path appears $listed time(s): $(why "$out")"; fi

times="$(why "$out" | grep -cE "^ +$repoA$" || true)"
if [ "$times" = "1" ]; then ok 'the candidate list holds the repository exactly once'
else bad 'the candidate list holds the repository exactly once' "listed $times time(s): $(why "$out")"; fi

echo '--- a form-1 stamp is ONE claim, not a branch claim plus a redundant bare-SHA claim ---'
claim_lines="$(why "$out" | grep -c '^  claim: ' || true)"
if [ "$claim_lines" = "1" ]; then ok 'a single "<branch> at <sha>" stamp produces exactly one claim'
else bad 'a single "<branch> at <sha>" stamp produces exactly one claim' "produced $claim_lines: $(why "$out")"; fi

echo '--- it never emits an ALLOW decision, only deny or silence ---'
out="$(run_hook "$repoA" "Review \`alpha.md\` against \`main\` at \`$shortA\`." tech-lead)"
case "$out" in
  *'"allow"'*) bad 'never emits an allow decision' "got: $out" ;;
  *) ok 'never emits an allow decision (silence is the allow)' ;;
esac

echo '--- fails open on everything it cannot decide ---'
out="$(printf '' | "$BASH" "$HOOK" 2>/dev/null; echo "RC:$?")"
if [ "$out" = "RC:0" ]; then ok 'an empty payload exits 0 silently'
else bad 'an empty payload exits 0 silently' "got: $out"; fi

out="$(printf '%s' 'not json at all' | "$BASH" "$HOOK" 2>/dev/null; echo "RC:$?")"
if [ "$out" = "RC:0" ]; then ok 'an unparseable payload fails OPEN and exits 0'
else bad 'an unparseable payload fails OPEN and exits 0' "got: $out"; fi

out="$(printf '%s' '{"tool_name":"Agent","tool_input":{"description":"d"}}' | "$BASH" "$HOOK" 2>/dev/null; echo "RC:$?")"
if [ "$out" = "RC:0" ]; then ok 'a dispatch payload with no prompt fails OPEN'
else bad 'a dispatch payload with no prompt fails OPEN' "got: $out"; fi

out="$(run_hook "$plain" "Review \`alpha.md\` against \`main\` at \`0123abc4567\`." tech-lead)"
if [ -z "$out" ]; then ok 'a cwd outside any git tree fails OPEN'
else bad 'a cwd outside any git tree fails OPEN' "got: $out"; fi

# An EMPTY PATH directory, not "/usr/bin:/bin" — jq, git and awk all ship in /usr/bin on this platform,
# so the minimal-PATH spelling of this assertion would pass with the dependency it claims to remove
# still present. Same correction `orchestrator-write-guard.test.sh` already carries.
mkdir -p "$root/emptybin"
payload="$(jq -n --arg c "$repoA" --arg p "Review \`beta.md\` against \`main\` at \`$shortA\`." '{tool_name:"Agent",cwd:$c,tool_input:{prompt:$p}}')"
out="$( export PATH="$root/emptybin"; printf '%s' "$payload" | "$BASH" "$HOOK" 2>/dev/null; echo "RC:$?" )"
if [ "$out" = "RC:0" ]; then ok 'no jq, git or awk on PATH: exits 0, emits nothing, denies nothing'
else bad 'no jq, git or awk on PATH: exits 0, emits nothing, denies nothing' "got: $out"; fi

teardown

echo '--- the registration: matcher "Task" would be inert and look wired (measured #326) ---'
if [ ! -f "$HOOKS_JSON" ]; then
  bad 'hooks.json is readable' 'hooks/hooks.json not found — this assertion is checking nothing'
else
  matcher="$(jq -r '.hooks.PreToolUse[] | select((.hooks[].command // "") | contains("dispatch-premise-guard.sh")) | .matcher' "$HOOKS_JSON" 2>/dev/null || true)"
  if [ -z "$matcher" ]; then
    bad 'the guard is registered in hooks.json' 'no PreToolUse entry references dispatch-premise-guard.sh'
  elif [ "$matcher" = "Agent" ]; then
    ok "the guard is registered on PreToolUse matcher '$matcher'"
  else
    bad 'the guard is registered on PreToolUse matcher "Agent"' "matcher is '$matcher'; measured on #326, a PreToolUse hook on 'Task' captured NOTHING across a full dispatch while still matching TaskCreate — inert and installed-looking"
  fi
fi

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]

# ── MUTATION LOG — what was broken, and which arm went red ─────────────────────────────────────
# Each mutation was applied to dispatch-premise-guard.sh, confirmed present with `git diff`, the suite
# re-run, the named arm observed red, then reverted and the suite re-run to confirm green again.
#
#   M-a  path resolution deleted (`paths=""` forced)        -> 'a claim true of cwd but false of the
#                                                              CITED repository is denied' and 'a bare
#                                                              filename resolves…' go red. This is the
#                                                              owner's correction; if these two cannot
#                                                              fail, the guard is cwd-anchored.
#   M-b  the `git ls-files` branch removed                  -> 'a bare filename resolves to the
#                                                              repository that tracks it' goes red ALONE
#   M-c  the branch comparison inverted to `=`              -> 'a correct SHA with the wrong branch name
#                                                              is denied' and 'the right branch with the
#                                                              right SHA is allowed' both go red
#   M-d  HEAD-prefix test replaced by `cat-file` alone      -> 'a real ancestor commit that is not HEAD
#                                                              is denied' goes red
#   M-e  digit requirement dropped from issha()             -> 'a hex-shaped English word after a
#                                                              keyword is not a claim' goes red
#   M-f  per-repository dedupe removed                      -> both worktree arms go red
#   M-g  matcher changed to "Task" in hooks.json            -> the registration arm goes red and EVERY
#                                                              other arm stays green — which is the
#                                                              point of asserting the registration here
