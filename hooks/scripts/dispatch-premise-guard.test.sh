#!/usr/bin/env bash
# dispatch-premise-guard.test.sh — does the guard deny exactly a dispatch whose stamped repository state
# is false, verified in the repository the brief's own citations attribute it to, and nothing else?
#
# Uses REAL temporary git repositories — two unrelated ones, a linked worktree, a SECOND CLONE, and two
# bare origins so remote-tracking refs exist — because every assertion here is a question about
# repository state, and a stubbed `git` would test the stub rather than the guard's use of it.
#
# ── WHAT THE #326 REVIEW CHANGED, AND WHY MOST OF THIS FILE IS ABOUT NOT FIRING ────────────────
# The first version accepted a BARE SHA after a keyword as a claim. Measured over 859 unique real
# dispatch briefs: 41.2% evaluated, and 8.0% carried two or more distinct SHAs — so at least one claim
# in each was denied whatever the tree was. Two SHAs is the normal shape of a review brief (a
# merge-base and a head), so that was a design fault, not a rate to tune. The grammar is now ONE form,
# `<ref> at <sha>`, with the ref required to RESOLVE in the target repository: 9 of 859 briefs
# evaluated, 0 guaranteed denials, 0 prose accidents, and both instances of the incident still caught.
# The arms below encode that as behaviour rather than as a comment.
#
# ── MUTATION-CHECKED ON THE SOURCE, PER ASSERTION ──────────────────────────────────────────────
# Every assertion here was watched to FAIL against a deliberately broken guard before being trusted;
# the mutation log is at the bottom of this file. Two shapes are checked, not one: an assertion that
# FAILS, and an assertion that DISAPPEARS — an arm that stops emitting a verdict is invisible to a
# passing total. Every branch below emits exactly one `ok` or one `FAIL`.
#
# ── THE REGISTRATION IS PART OF THE GATE ───────────────────────────────────────────────────────
# Measured on #326: a `PreToolUse` matcher of `"Task"` fires ZERO times on a real dispatch while still
# matching `TaskCreate` — installed-looking and inert. Every assertion in this file would stay green
# behind that matcher, so the registration is checked here rather than trusted.
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

setup() {
  # `pwd -P` because on macOS `/var` is a symlink to `/private/var`; the guard derives every path from
  # `rev-parse --show-toplevel` (canonical), so an uncanonicalised fixture root would compare unequal
  # and the sibling scan would silently find nothing — a suite that tested the fallback path only.
  root="$(cd "$(mktemp -d)" && pwd -P)"
  repoA="$root/alpha-repo"
  repoB="$root/beta-repo"
  awt="$root/alpha-linked-worktree"
  clone="$root/alpha-second-clone"
  plain="$root/not-a-repo"
  mkdir -p "$plain"

  # Bare origins. A bare repo has no work tree, so `rev-parse --show-toplevel` fails and the guard's
  # sibling scan skips it — they exist so `remote.origin.url` is a real shared key and so
  # `refs/remotes/origin/*` really exists.
  git init -q --bare "$root/alpha-origin.git"
  git init -q --bare "$root/beta-origin.git"

  git init -q -b main "$repoA"
  git -C "$repoA" config user.email test@example.com
  git -C "$repoA" config user.name test
  git -C "$repoA" remote add origin "$root/alpha-origin.git"
  printf 'A\n' > "$repoA/alpha.md"
  printf 'COMMON\n' > "$repoA/shared-common.md"
  git -C "$repoA" add .
  git -C "$repoA" commit -q -m "alpha init"
  git -C "$repoA" push -q origin main
  shaA_old="$(git -C "$repoA" rev-parse HEAD)"
  shortA_old="${shaA_old:0:7}"

  # A LINKED worktree and a SECOND CLONE of the same repository. Both must collapse to one candidate:
  # this workspace really carries ~22 of the former and at least one of the latter, and the clone was
  # measured (#326 review, P2) vouching for a premise false of the tree being worked.
  git -C "$repoA" worktree add -q -b side "$awt" HEAD
  git clone -q "$root/alpha-origin.git" "$clone"
  # A file that exists ONLY in the clone's tree. This is what isolates the origin-URL key: with it, the
  # clone is not a candidate at all and this path resolves nowhere; without it, the clone is a separate
  # candidate that this path attributes the stamp to. See the M-f note in the mutation log.
  printf 'ONLY\n' > "$clone/clone-only.md"

  # Now move repoA past the clone, so the clone's HEAD is a real commit that is NOT repoA's HEAD.
  printf 'A2\n' >> "$repoA/alpha.md"
  git -C "$repoA" commit -q -am "alpha second"
  shaA="$(git -C "$repoA" rev-parse HEAD)"
  shortA="${shaA:0:7}"

  git init -q -b main "$repoB"
  git -C "$repoB" config user.email test@example.com
  git -C "$repoB" config user.name test
  git -C "$repoB" remote add origin "$root/beta-origin.git"
  mkdir -p "$repoB/docs/deep"
  printf 'B\n' > "$repoB/beta.md"
  printf 'G\n' > "$repoB/docs/deep/gamma.md"
  printf 'COMMON\n' > "$repoB/shared-common.md"
  git -C "$repoB" add .
  git -C "$repoB" commit -q -m "beta init"
  git -C "$repoB" push -q origin main
  shaB_main="$(git -C "$repoB" rev-parse HEAD)"
  shortB_main="${shaB_main:0:7}"
  git -C "$repoB" fetch -q origin
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

out="$(run_hook "$repoA" "Close the description. See \`alpha.md\` for the copy. Measured against \`main\` at \`$shortA\`." product-lead)"
if [ -z "$out" ]; then ok 'the same claim, citing the repository it IS true of, is allowed'
else bad 'the same claim, citing the repository it IS true of, is allowed' "got: $out"; fi

echo '--- a bare filename with no directory resolves through git ls-files ---'
out="$(run_hook "$repoA" "Check \`gamma.md:12\` against \`main\` at \`$shortA\`." tech-lead)"
if [ "$(decision "$out")" = "deny" ]; then ok 'a bare filename resolves to the repository that tracks it (deep path, no slash cited)'
else bad 'a bare filename resolves to the repository that tracks it' "got: ${out:-<empty, i.e. allowed via the cwd fallback>}"; fi

echo '--- THE GRAMMAR CORRECTION: a bare SHA is a REFERENCE, not a premise (#326 review) ---'
# This is the 8.0%-of-859 class. A review brief naming a merge-base and a head is correct briefing.
out="$(run_hook "$repoA" "Review PR 331 against its merge-base commit $shaA_old and the head $shaA. Also commit: 0123abc4567. See \`alpha.md\`." quality-assurance)"
if [ -z "$out" ]; then ok 'three bare SHAs, two of them not HEAD, are not claims and are allowed'
else bad 'three bare SHAs are not claims and are allowed' "got: $out"; fi

out="$(run_hook "$repoA" "Reviewed \`alpha.md\`. commit: 0123abc4567" agents-lead)"
if [ -z "$out" ]; then ok 'a bare SHA no repository contains is not a claim and is allowed'
else bad 'a bare SHA no repository contains is not a claim and is allowed' "got: $out"; fi

echo '--- and the ref must RESOLVE, which is what drops the prose accidents ---'
# Both of these are real spans from the corpus: "…of awk. At 55ecf4c…" and "…head 5 at 6259e53…".
out="$(run_hook "$repoA" "Rewrote the scrub function of awk. At 0123abc4567 it was still wrong. See \`alpha.md\`." agents-lead)"
if [ -z "$out" ]; then ok 'a sentence boundary putting an English word before "at <sha>" is not a claim'
else bad 'a sentence boundary before "at <sha>" is not a claim' "got: $out"; fi

out="$(run_hook "$repoA" "Read head 5 at 0123abc4567 of the log. See \`alpha.md\`." agents-lead)"
if [ -z "$out" ]; then ok 'a number before "at <sha>" is not a ref and so is not a claim'
else bad 'a number before "at <sha>" is not a claim' "got: $out"; fi

out="$(run_hook "$repoB" "Review \`beta.md\` against \`the-spec\` at \`$shortB\`." tech-lead)"
if [ -z "$out" ]; then ok 'a plausible-looking word that is no ref in the target repository is not a claim'
else bad 'a non-ref word is not a claim' "got: $out"; fi

echo '--- a LOCAL branch stamp asserts where the tree IS: both halves checked ---'
out="$(run_hook "$repoB" "Review \`beta.md\` against \`main\` at \`$shortB\`." tech-lead)"
if [ "$(decision "$out")" = "deny" ]; then ok 'HEAD correct but the tree is on another branch: denied'
else bad 'HEAD correct but the tree is on another branch: denied' "got: ${out:-<empty>}"; fi

case "$(why "$out")" in
  *"is on 'feat/x'"*) ok 'the deny quotes the branch the tree is actually on' ;;
  *) bad 'the deny quotes the branch the tree is actually on' "reason: $(why "$out")" ;;
esac

out="$(run_hook "$repoB" "Review \`beta.md\` against \`feat/x\` at \`$shortB\`." tech-lead)"
if [ -z "$out" ]; then ok 'the right branch with the right SHA is allowed'
else bad 'the right branch with the right SHA is allowed' "got: $out"; fi

parentB="$(git -C "$repoB" rev-parse --short HEAD~1)"
out="$(run_hook "$repoB" "Review \`beta.md\` against \`feat/x\` at \`$parentB\`." tech-lead)"
if [ "$(decision "$out")" = "deny" ]; then ok 'the right branch at an ancestor that is not HEAD is denied (the tree moved)'
else bad 'the right branch at an ancestor that is not HEAD is denied' "got: ${out:-<empty>}"; fi

echo '--- a REMOTE-TRACKING stamp asserts only where that ref points: HEAD is NOT checked ---'
# 4 of the 9 real stamps in the corpus are "on origin/main at <sha>" while the tree sits on a feature
# branch. That is correct briefing; requiring HEAD here would deny every one of them.
out="$(run_hook "$repoB" "Review \`beta.md\`, measured on \`origin/main\` at \`$shortB_main\`." tech-lead)"
if [ -z "$out" ]; then ok 'a correct origin/main stamp is allowed while the tree sits on a feature branch'
else bad 'a correct origin/main stamp is allowed from a feature branch' "got: $out"; fi

out="$(run_hook "$repoB" "Review \`beta.md\`, measured on \`origin/main\` at \`$shortB\`." tech-lead)"
if [ "$(decision "$out")" = "deny" ]; then ok 'an origin/main stamp naming a commit that ref is not at is denied'
else bad 'an origin/main stamp naming the wrong commit is denied' "got: ${out:-<empty>}"; fi

case "$(why "$out")" in
  *"origin/main is at"*) ok 'the deny says where the remote ref actually points' ;;
  *) bad 'the deny says where the remote ref actually points' "reason: $(why "$out")" ;;
esac

echo '--- one candidate per REPOSITORY: a second CLONE must not vouch (#326 review, P2) ---'
# The clone is on main at repoA's PREVIOUS commit. Keyed per directory it is a separate candidate that
# satisfies the stamp; keyed per repository it collapses into repoA, whose tree is what cwd is in.
out="$(run_hook "$repoA" "Review \`alpha.md\` against \`main\` at \`$shortA_old\`." agents-lead)"
if [ "$(decision "$out")" = "deny" ]; then ok 'a second clone sitting at the stamped SHA does not vouch for it'
else bad 'a second clone does not vouch for a stamp false of the worked tree' "got: ${out:-<empty>}"; fi

listed="$(why "$out" | grep -c "$clone" || true)"
if [ "$listed" = "0" ]; then ok 'the second clone is never listed as its own candidate'
else bad 'the second clone is never listed as its own candidate' "appears $listed time(s): $(why "$out")"; fi

listed="$(why "$out" | grep -c "$awt" || true)"
if [ "$listed" = "0" ]; then ok 'a linked worktree is collapsed into its repository too'
else bad 'a linked worktree is collapsed into its repository' "appears $listed time(s): $(why "$out")"; fi

claim_lines="$(why "$out" | grep -c '^  claim: ' || true)"
if [ "$claim_lines" = "1" ]; then ok 'a single stamp produces exactly one claim'
else bad 'a single stamp produces exactly one claim' "produced $claim_lines: $(why "$out")"; fi

# THE ARM THAT ISOLATES THE ORIGIN-URL KEY, and it exists because the plain second-clone case above did
# NOT isolate it — measured. With the key, a path unique to the clone's tree resolves in no candidate
# (the clone is not one) and the check falls back to cwd, where the stamp is false. Without the key, the
# clone is a candidate, this path attributes the stamp to it, and the clone vouches. That is #326's P2
# in its purest form.
out="$(run_hook "$repoA" "Check \`clone-only.md\` against \`main\` at \`$shortA_old\`." agents-lead)"
if [ "$(decision "$out")" = "deny" ]; then ok 'a path unique to a sibling clone does not make that clone the target'
else bad 'a path unique to a sibling clone does not make that clone the target' "got: ${out:-<empty, i.e. the clone vouched>}"; fi

echo '--- a path present in several repositories DISTINGUISHES nothing and is dropped (P3) ---'
# `shared-common.md` exists in both repositories, like README.md across this workspace's seven.
out="$(run_hook "$repoA" "Review \`shared-common.md\` against \`main\` at \`$shortA\`." tech-lead)"
if [ -z "$out" ]; then ok 'a non-distinguishing citation falls back to cwd, where the claim is true'
else bad 'a non-distinguishing citation falls back to cwd' "got: $out"; fi

out="$(run_hook "$repoA" "Review \`shared-common.md\` against \`main\` at \`$shortA_old\`." tech-lead)"
if [ "$(decision "$out")" = "deny" ]; then ok 'the same non-distinguishing citation still denies a claim false of cwd'
else bad 'a non-distinguishing citation still denies a false claim against cwd' "got: ${out:-<empty>}"; fi

echo '--- attribution across TWO repositories is ambiguous, and fails OPEN by declaration ---'
out="$(run_hook "$repoA" "Update \`alpha.md\` here and \`beta.md\` there, measured against \`main\` at \`$shortA_old\`." developer)"
if [ -z "$out" ]; then ok 'a cross-repository brief is not checked at all (one stamp, two repositories)'
else bad 'a cross-repository brief fails open' "got: $out"; fi

echo '--- no citation resolves: the cwd repository is the declared fallback ---'
out="$(run_hook "$repoA" "Review the roster against \`main\` at \`$shortA\`." agents-lead)"
if [ -z "$out" ]; then ok 'with no resolvable path, a claim true of cwd is allowed'
else bad 'with no resolvable path, a claim true of cwd is allowed' "got: $out"; fi

out="$(run_hook "$repoB" "Review the roster against \`main\` at \`$shortA\`." agents-lead)"
if [ "$(decision "$out")" = "deny" ]; then ok 'with no resolvable path, a claim false of cwd is denied'
else bad 'with no resolvable path, a claim false of cwd is denied' "got: ${out:-<empty>}"; fi

echo '--- keyed on the CLAIM, never on the persona: the general-purpose blind spot stays closed ---'
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

case "$(why "$out")" in
  *"BARE SHA IS NEVER CHECKED"*) ok 'the deny text declares that a bare SHA is not checked' ;;
  *) bad 'the deny text declares that a bare SHA is not checked' "reason: $(why "$out")" ;;
esac

echo '--- English is not a SHA: the digit requirement, in the SHA SLOT ---'
# THIS ARM WAS REWRITTEN BECAUSE IT COULD NOT FAIL. Its first form put the hex-shaped word in the REF
# slot ("was defaced at defaced"), and under the narrowed grammar `isref()` excludes anything `issha()`
# accepts — so dropping the digit requirement made the token a SHA, which made it not a ref, which
# killed the claim either way. Green with the rule it named removed. The digit requirement now only
# does work in the SHA slot, so that is where the assertion has to stand. Found by mutating the source;
# reading the arm would never have shown it.
out="$(run_hook "$repoA" "Review \`alpha.md\` against \`main\` at \`defaced\`." content-reviewer)"
if [ -z "$out" ]; then ok 'a hex-shaped English word in the SHA slot is not a commit and so is not a claim'
else bad 'a hex-shaped English word in the SHA slot is not a claim' "got: $out"; fi

echo '--- no claim at all: the common case is untouched ---'
out="$(run_hook "$repoA" "Draft the LinkedIn teaser for the new article. No citations." content-writer)"
if [ -z "$out" ]; then ok 'a brief with no ref-and-commit stamp is allowed'
else bad 'a brief with no ref-and-commit stamp is allowed' "got: $out"; fi

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
# Each mutation was applied to dispatch-premise-guard.sh, confirmed present, the suite re-run, the named
# arm observed red, then reverted and the suite re-run to confirm green again.
#
#   M-a  path attribution deleted (`paths=""` forced)     -> the two owner-correction arms and the bare-
#                                                            filename arm go red. If these cannot fail,
#                                                            the guard is cwd-anchored.
#   M-b  the `git ls-files` branch removed                -> 'a bare filename resolves…' goes red ALONE
#   M-c  the local-branch comparison inverted to `=`      -> the two local-branch arms go red
#   M-d  HEAD-prefix test removed for local refs          -> 'the right branch at an ancestor…' goes red
#   M-e  digit requirement dropped from issha()           -> 'a hex-shaped English word…' goes red
#   M-f  repo_key ignores remote.origin.url               -> 'a path unique to a sibling clone…' and the
#                                                            cross-repository arm go red. NOTE, because
#                                                            it was measured and is not what was
#                                                            expected: the PLAIN second-clone arm stays
#                                                            GREEN under M-f — that case is carried by
#                                                            the non-distinguishing-path rule, not by
#                                                            the origin key. The clone-only arm exists
#                                                            precisely because the obvious one did not
#                                                            isolate the rule it appeared to test.
#   M-g  matcher changed to "Task" in hooks.json          -> the registration arm goes red and EVERY
#                                                            other arm stays green — the point of
#                                                            asserting the registration here
#   M-h  bare SHAs accepted as claims again (issha(a))    -> the three grammar-correction arms go red;
#                                                            this is the #326 review's finding as a test
#   M-i  ref-resolution gate removed (kind always local)  -> the prose-accident arms go red
#   M-j  remote refs treated as local (HEAD required)     -> 'a correct origin/main stamp is allowed…'
#                                                            goes red — the 4-of-9 corpus class
#   M-k  non-distinguishing paths kept (drop the count=1  -> 'a cross-repository brief is not checked'
#        filter)                                             and the P3 arms go red
