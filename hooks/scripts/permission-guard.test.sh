#!/usr/bin/env bash
# Tests for permission-guard.sh — the PreToolUse floor.
#
# The guard is the one piece of this plugin that can HALT the agent, so a regression
# here is either a hole in the floor or a wedged dev loop. Every case declares its
# expected verdict; the ALLOW cases matter as much as the DENY ones, because the bug
# that motivated rules 7 and 8 was over-blocking, not under-blocking.
#
# Run: bash hooks/scripts/permission-guard.test.sh

set -uo pipefail

GUARD="$(cd "$(dirname "$0")" && pwd)/permission-guard.sh"

pass=0
fail=0

# THREE outcomes, not two. The suite used to classify by `grep '"deny"'` and call everything else
# ALLOW — so when rule 5c started returning `ask`, a test asserting ALLOW would have passed on it and a
# test asserting ASK could not have been written at all. A harness that cannot see a decision cannot
# fail for it, which is the exact defect this repo's own review standard hunts for.
verdict() {
  case "$1" in
    *'"deny"'*) printf 'DENY' ;;
    *'"ask"'*)  printf 'ASK' ;;
    *)          printf 'ALLOW' ;;
  esac
}

check() {
  want="$1"
  desc="$2"
  cmd="$3"
  out=$(printf '%s' "$cmd" | jq -R '{tool_input:{command:.}}' | bash "$GUARD")
  got=$(verdict "$out")
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1))
    printf 'ok    %-6s %s\n' "$got" "$desc"
  else
    fail=$((fail + 1))
    printf 'FAIL  want=%s got=%s  %s\n      cmd: %s\n' "$want" "$got" "$desc" "$cmd"
  fi
}

# Like check(), but stamps an agent_type onto the payload — the field the harness sets on
# a subagent's tool calls and leaves empty for the main agent. Read by the merge gate (7b)
# and, since the 5c correction, by the issue gate. An empty agent (`''`) is the main agent.
check_agent() {
  want="$1"
  agent="$2"
  desc="$3"
  cmd="$4"
  out=$(jq -n --arg c "$cmd" --arg a "$agent" '{tool_input:{command:$c}, agent_type:$a}' | bash "$GUARD")
  got=$(verdict "$out")
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1))
    printf 'ok    %-6s %s\n' "$got" "$desc"
  else
    fail=$((fail + 1))
    printf 'FAIL  want=%s got=%s  %s\n      cmd: %s\n' "$want" "$got" "$desc" "$cmd"
  fi
}

echo "--- rule 7: pushing to the trunk, in every spelling ---"
check DENY  "explicit origin main"          "git push origin main"
check DENY  "explicit with -C"              "git -C /some/repo push origin main"
check DENY  "HEAD:main refspec"             "git push origin HEAD:main"
check DENY  "fully-qualified ref"           "git push origin refs/heads/main"
check DENY  "force-ref +main"               "git push origin +main"
check DENY  "master counts too"             "git push origin master"
check DENY  "--all sweeps the trunk"        "git push --all origin"
check DENY  "--mirror sweeps the trunk"     "git push --mirror origin"

echo "--- rule 7: feature-branch pushes MUST survive (the over-block that motivated this) ---"
check ALLOW "feature branch, plain"         "git push origin feat/x"
check ALLOW "feature branch via -C"         "git -C /some/repo push origin feat/x"
check ALLOW "set-upstream a feature"        "git push -u origin feat/x"
check ALLOW "branch merely NAMED main-*"    "git push origin feat/main-nav"

echo "--- rule 7: must not fire on non-push git ---"
check ALLOW "log mentioning main"           "git log --oneline main..HEAD"
check ALLOW "diff against main"             "git diff main...HEAD"

echo "--- rule 7: the semantic core — a bare push inherits HEAD ---"
TMP="$(mktemp -d)"
git init -q -b main "$TMP"
# CI runners have no global git identity, so the fixture must carry its own or the
# commit below fails and the repo is left with an unborn HEAD — which is exactly how
# this suite first passed locally and failed in CI.
git -C "$TMP" config user.email "fixture@example.com"
git -C "$TMP" config user.name "fixture"
git -C "$TMP" commit -q --allow-empty -m init
check DENY  "bare push, HEAD is main"       "git -C $TMP push"
check DENY  "push origin, HEAD is main"     "git -C $TMP push origin"
git -C "$TMP" checkout -q -b feat/thing
check ALLOW "bare push, HEAD is a feature"  "git -C $TMP push"
check ALLOW "push origin, HEAD a feature"   "git -C $TMP push origin"
rm -rf "$TMP"

# An unborn HEAD (init, no commits) still reports its branch via symbolic-ref. This
# case exists because CI hit it: with rev-parse the check silently skipped and a push
# on main read as ALLOW.
BARE="$(mktemp -d)"
git init -q -b main "$BARE"
check DENY  "unborn HEAD on main"           "git -C $BARE push"
rm -rf "$BARE"

echo "--- rule 7b: merging a PR is the quality-assurance's act alone ---"
check       DENY  "main agent (no agent_type) cannot merge"          "gh pr merge 149 --merge"
check_agent DENY  ""                                     "empty agent_type = main agent, denied"      "gh pr merge 149 --merge"
check_agent ALLOW "tadeumendonca-skills:quality-assurance" "the reviewer merges — it IS the gate"     "gh pr merge 149 --merge"
check_agent ALLOW "tadeumendonca-skills:quality-assurance" "the reviewer, behind --repo"              "gh --repo owner/repo pr merge 149 --merge"
check_agent ALLOW "tadeumendonca-skills:quality-assurance" "the reviewer, behind -R"                  "gh -R owner/repo pr merge 149 --squash"
check_agent DENY  "tadeumendonca-skills:planner"          "a different subagent cannot merge"         "gh pr merge 149 --merge"
check_agent DENY  "tadeumendonca-skills:frontend-react"   "a build specialist cannot merge"           "gh pr merge 149 --squash"
check_agent DENY  "Explore"                               "a built-in subagent cannot merge either"   "gh pr merge 149 --merge"

echo "--- rule 7b: only 'pr merge' is gated; the rest of the loop is untouched for everyone ---"
check       ALLOW "main agent may open a PR"          "gh pr create --fill"
check       ALLOW "main agent may view a PR"          "gh pr view 149"
check       ALLOW "main agent may check CI"           "gh pr checks 149 --repo owner/repo"
check       ALLOW "main agent may list PRs"           "gh pr list --state open"
check       ALLOW "the word merge in a commit msg"    "git commit -m 'gh pr merge notes'"

echo "--- rule 5d: developer may file issues; the JUDGEMENT moved out of the hook ---"
# WHAT THIS SUITE USED TO ASSERT, and why almost all of it is gone.
#
# For four rounds this block tested that the hook could tell a DECOMPOSITION from invented scope:
# a `Parent: #N` marker read from the body or the body FILE, word-anchored so `apparent #122` did
# not count, first-match-not-last so a trailing number could not authorise it, the repo read from
# `$bare` so a `-R` inside `--body` could not redirect the lookup, then `gh issue view` to confirm
# the story carried `ready`. Ten assertions, a repo-aware `gh` stub, and every one of them was a
# real defect correctly fixed.
#
# All of it is deleted, because the rule it tested is deleted (ADR-0004, amendment 2026-08-02):
# intent is not in the command string, so the judgement moved to `agents/developer.md` and the
# `quality-assurance` gate. Deleting the tests WITH the behaviour is the point — tests kept alive
# past their rule are the most expensive kind of green.
#
# NO `gh` STUB ANY MORE, and that is a real simplification rather than a gap: the rule no longer
# looks anything up, so there is nothing to stub and no network dependence to make hermetic. The
# last case below asserts exactly that.
check_agent ALLOW "tadeumendonca-skills:developer" "developer files a task"                    "gh issue create --title 'task: x' --body 'Parent: #122'"
check_agent ALLOW "tadeumendonca-skills:developer" "developer, behind -R"                      "gh -R owner/repo issue create --title t --body 'Parent: #122'"
# No marker needed now — asserted rather than left implied, because it is the BEHAVIOUR CHANGE.
# A reader of the old suite would expect this to deny.
check_agent ALLOW "tadeumendonca-skills:developer" "no marker: allowed now, by design"         "gh issue create --title t --body 'just work'"
# The body-file shape, which the old rule denied for three rounds while it was the only way this
# repo writes bodies. Kept as a case because that was the sharpest symptom of the deleted design.
check_agent ALLOW "tadeumendonca-skills:developer" "a body written to a file"                  "gh issue create --title t --body-file /tmp/does-not-matter.md"

# THE EXEMPTION IS STILL THE BUILDER'S ALONE. Filing is an act of EXECUTION; a review citing a
# story is still a review opening work, which is the failure the whole rule exists to prevent.
check_agent DENY  "tadeumendonca-skills:quality-assurance" "a REVIEWER still cannot file"      "gh issue create --title t --body 'Parent: #122'"
check_agent DENY  "tadeumendonca-skills:security"          "security still cannot file"        "gh issue create --title t --body 'Parent: #122'"
# The main loop is unaffected: it still ASKS. The owner answers, per issue, as before.
check       ASK   "main loop still asks"                                                       "gh issue create --title t --body 'Parent: #122'"

# THE ONE LESSON THAT SURVIVES THE DELETION: the allow is a FLAG, not `exit 0`. An earlier version
# returned from mid-script and everything below it stopped running — rules 7, 7b and 8. These three
# are the regression, and they are the reason this block is not simply "allow developer":
check_agent DENY  "tadeumendonca-skills:developer" "allow does not unreach rule 7 (trunk push)" "gh issue create --title t --body b && git push origin main"
check_agent DENY  "tadeumendonca-skills:developer" "allow does not unreach rule 7b (merge)"     "gh issue create --title t --body b && gh pr merge 1 --merge"
#   The third case here was `… && rm -rf /tmp/x`, and it was a TAUTOLOGY — `rm -rf` is rule 4,
#   which runs BEFORE 5d, so it denied whether or not the fall-through worked. Found by mutating
#   the allow back to `exit 0`: cases 7 and 7b reddened and that one did not. Replaced with rule
#   8, which is genuinely downstream of 5d, so the assertion witnesses what it names.
check_agent DENY  "tadeumendonca-skills:developer" "allow does not unreach rule 8 (composition)" "gh issue create --title t --body b ; echo done"

# A message ABOUT the act is not the act — matched on `$bare`, after quoted spans collapse.
check_agent ALLOW "tadeumendonca-skills:developer" "a commit message mentioning the act"        "git commit -m 'gh issue create notes'"

# NO `gh` ON PATH: allowed, where the old rule denied. The direction changed because the reason
# changed — the old deny was "cannot PROVE the parent, so fail closed", and there is no longer a
# proof to fail. Asserted so the change is visible rather than incidental.
NOGH="$(mktemp -d)"
REAL_PATH_5D="$PATH"
PATH="$NOGH:/usr/bin:/bin"
check_agent ALLOW "tadeumendonca-skills:developer" "no gh: nothing to look up any more"        "gh issue create --title t --body 'Parent: #122'"
PATH="$REAL_PATH_5D"
rm -rf "$NOGH"

echo "--- rule 5c: the owner decides what enters the queue — asked in the main loop, denied in a subagent ---"
# The rule used to DENY every one of these. That did not stop unaligned work; it taxed ALIGNED work,
# and the tax landed on the owner, who had to type the command themselves for something they had just
# asked for. What is guarded is the alignment, and only the owner can see it — so the main loop asks.
check ASK   "gh issue create"                    "gh issue create --title x --body y"
check ASK   "behind -R"                          "gh -R owner/repo issue create --title x"
check ASK   "behind --repo"                      "gh --repo owner/repo issue create --title x"
check ASK   "with --body-file"                   "gh issue create --title x --body-file /tmp/b.md"
# pflag accepts an attached value in both spellings, and `gh` really parses these — verified against
# the live CLI, not assumed. The first version of the rule required a space and both slipped past, so
# the suite certified coverage it did not have. Kept as ASK cases: the matcher is what is under test
# here, and a spelling that escapes it reaches the tool with NO prompt at all.
check ASK   "--repo= attached"                   "gh --repo=owner/repo issue create --title x"
check ASK   "-R attached shorthand"              "gh -Rowner/repo issue create --title x"
# The `gh api` route is a NAMED ACCEPTED GAP, as rule 7b books its equivalent for merges. These assert
# the gap rather than leaving it undocumented — a residual nobody wrote down is indistinguishable from
# one nobody noticed.
check ALLOW "gh api POST is the booked gap"      "gh api --method POST /repos/o/r/issues -f title=x"
check ALLOW "gh api listing issues"              "gh api repos/o/r/issues --paginate"
check ALLOW "a commit message about the act"     'git commit -m "gh api repos/o/r/issues -f title=x"'
# A SUBAGENT STILL CANNOT FILE, and this is where the measured failure actually happened: 13 of 19
# issues in one session were born inside a review of something else. A persona has no access to the
# owner, so it cannot answer the question the prompt asks — it reports upward instead. `agent_type` is
# stamped by the harness and cannot be forged by the model, so this is not a spelling it can escape.
check_agent DENY "tadeumendonca-skills:quality-assurance" "not even the reviewer files"  "gh issue create --title x"
check_agent DENY "tadeumendonca-skills:scrum-master"      "not even the flow persona"     "gh issue create --title x"
# The other side of the same split, and the case the correction exists for. Without it the suite would
# pass with the subagent branch applied to everyone — which is the bug being fixed, not a regression
# guard against it.
check_agent ASK  "" "an empty agent_type is the main loop, and it asks" "gh issue create --title x"

# Everything else about issues stays open, or the rule would block reading the board rather than
# opening work. These are the partner cases: without them "DENY create" would pass for a rule that
# blocked `gh issue` entirely.
check ALLOW "reading an issue"        "gh issue view 173"
check ALLOW "listing issues"          "gh issue list --state open"
check ALLOW "commenting on an issue"  "gh issue comment 173 --body-file /tmp/c.md"
check ALLOW "closing an issue"        "gh issue close 173"
check ALLOW "labelling an issue"      "gh issue edit 173 --add-label product"
check ALLOW "the words in a message"  "git commit -m 'gh issue create notes'"

echo "--- rule 8: composition the permission matcher cannot decompose ---"
check DENY  "cd compound"                   "cd /tmp && ls"
check DENY  "&& chain"                      "git status && git diff"
check DENY  "; chain"                       "ls; pwd"
check DENY  "command substitution"          'echo $(date)'
check DENY  "backticks"                     'echo `date`'
check DENY  "env-var prefix"                "E2E_ENV=local npx playwright test"

echo "--- rule 8: single commands MUST survive ---"
check ALLOW "a pipe is fine"                "grep -rn foo src | head -20"
check ALLOW "npm --prefix"                  "npm --prefix apps/fed run test"
check ALLOW "git -C plain"                  "git -C /some/repo status --short"
check ALLOW "operator inside a quoted arg"  "git commit -m 'fix: a && b handling'"

# #66: the collapse used to stop at the first inner quote, exposing the rest of a body to the
# composition check. Each of these was verified to FAIL against the pre-fix `s/"[^"]*"/""/g`.
# Deliberately NOT `gh issue create` — which is the command #66 was hit on, but which rule 5c
# answers ASK before rule 8 is ever reached. Asserting ALLOW there would test 5c and read as a
# rule-8 result. `gh pr comment` carries the same quoted-body shape with no other rule on it.
#
# THE OPERATOR MUST SIT BETWEEN THE TWO ESCAPED QUOTES, and the first draft of these cases got
# that wrong in a way worth recording. The old regex `s/"[^"]*"/""/g` pairs quote 1 with 2 and
# 3 with 4, so on `"a \"b\" c"` it collapses two spans and leaves only what sits BETWEEN the
# escaped pair bare. Put the backtick after the second escaped quote and the old regex swallows
# it inside a pair by accident — the case then passes before AND after the fix, asserts nothing,
# and reads like coverage. Three of the four cases here were originally written that shape.
# Each one below was re-checked by reverting the collapse and watching it go red.
check ALLOW "substitution between escaped quotes" 'gh pr comment 1 --body "said \"$(date)\" today"'
check ALLOW "backticks between escaped quotes"    'gh pr comment 1 --body "said \"`date`\" today"'
check ALLOW "operator between escaped quotes"     'gh pr comment 1 --body "both \"a && b\" hold"'
check ALLOW "escaped quote inside singles"        "git commit -m 'it\\'s \$(fine)'"

# The three cases the issue feared this fix would break. A false NEGATIVE here is far worse
# than the false positive above, so they are asserted rather than reasoned about.
check DENY  "operator OUTSIDE quotes still caught"    'git commit -m "msg" && npx tsc'
check DENY  "unbalanced quote fails CLOSED"           'echo "unterminated && npx tsc'
check DENY  "escaped-quote span then a REAL operator" 'gh pr comment 1 --body "said \"hi\"" && npx tsc'

echo "--- rule 5b: gh secret writes survive the -R convention ---"
check DENY  "secret set, plain"             "gh secret set MY_TOKEN"
check DENY  "secret set behind -R"          "gh -R owner/repo secret set MY_TOKEN"
check DENY  "secret set behind --repo"      "gh --repo owner/repo secret set MY_TOKEN"
check DENY  "secret delete behind -R"       "gh -R owner/repo secret delete MY_TOKEN"
check ALLOW "listing secrets is read-only"  "gh -R owner/repo secret list"

echo "--- the pre-existing floor still holds ---"
check DENY  "terraform apply"               "terraform apply -auto-approve"
check DENY  "terraform destroy"             "terraform -chdir=iac destroy"
check DENY  "force push"                    "git push --force origin feat/x"
check DENY  "reset --hard"                  "git reset --hard HEAD~1"
check DENY  "rm -rf"                        "rm -rf build"
check DENY  "skip-permissions bypass"       "claude --dangerously-skip-permissions"
check ALLOW "terraform plan"                "terraform -chdir=iac plan"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
