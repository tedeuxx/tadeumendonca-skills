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

echo "--- rule 5d: a subagent MAY decompose an approved story, and only that ---"
# `gh` is stubbed on PATH so the parent lookup is hermetic — no network, no auth, no dependence
# on what happens to exist in a real tracker. What varies per case is the canned label list,
# which is exactly the input the rule reads.
#
# THIS SUITE HAD NO STUB BEFORE, and that is why the 79 pre-existing tests passed against this
# change without exercising it at all: with no `gh` reachable the lookup fails, the labels come
# back empty, and every case falls through to the same deny it had before. A green suite that
# never reaches the new code is the exact defect this repo keeps finding, so the stub is what
# makes the rule observable rather than merely present.
GHSTUB="$(mktemp -d)"
REAL_PATH_5D="$PATH"
stub_gh_labels() { # $1 — what `gh issue view --json labels` prints, one label per line
  cat > "$GHSTUB/gh" <<STUB
#!/usr/bin/env bash
case "\$*" in
  *"issue view"*) printf '%s' '$1' ;;
  *)              exit 0 ;;
esac
STUB
  chmod +x "$GHSTUB/gh"
  PATH="$GHSTUB:$REAL_PATH_5D"
}

stub_gh_labels 'product
ready'
check_agent ALLOW "tadeumendonca-skills:developer" "a task under a READY story"                "gh issue create --title 'task: x' --body 'Parent: #122'"
check_agent ALLOW "tadeumendonca-skills:developer" "the parent behind -R"                      "gh -R owner/repo issue create --title t --body 'Parent: #122'"

# The label is what authorises, not the reference. A parent that exists but is not ready is a
# story whose description the three leads have not closed — building under it is the thing the
# intake chain exists to prevent.
stub_gh_labels 'product'
check_agent DENY  "tadeumendonca-skills:developer" "a parent WITHOUT ready"                    "gh issue create --title t --body 'Parent: #122'"

# A parent that does not resolve. `gh` printing nothing is indistinguishable from a fabricated
# number, and both must deny — this is what makes the reference unforgeable.
stub_gh_labels ''
check_agent DENY  "tadeumendonca-skills:developer" "a parent that does not resolve"            "gh issue create --title t --body 'Parent: #999'"

# No parent at all: unchanged from 5c. Opening scope is still denied outright.
stub_gh_labels 'product
ready'
check_agent DENY  "tadeumendonca-skills:developer" "no parent referenced"                      "gh issue create --title t --body 'just work'"

# The exception is about DECOMPOSING, which is an act of execution. A reviewer citing a ready
# story is still a review opening work, and reviews do not open work.
check_agent DENY  "tadeumendonca-skills:quality-assurance" "a REVIEWER citing a ready parent"  "gh issue create --title t --body 'Parent: #122'"
check_agent DENY  "tadeumendonca-skills:security"          "security citing a ready parent"    "gh issue create --title t --body 'Parent: #122'"

# The main loop is unaffected: it still ASKS, parent or no parent. The owner answers, as before.
check       ASK   "main loop, with a ready parent"                                             "gh issue create --title t --body 'Parent: #122'"

# THE THREE BYPASSES `security` REPRODUCED END TO END. Each was ALLOW against the first
# implementation, with the suite fully green — which is why they are here as regressions
# rather than as a note.
#
# 1 · A SECOND, UNRELATED NUMBER. The first version's `#([0-9]+)` was greedy, so it captured the
#     LAST number on the line. A declared parent that does not exist, plus a passing mention of
#     a real ready story, was ALLOWED — reducing the rule to "open anything, as long as it ends
#     in a ready number", which is opening scope.
check_agent DENY  "tadeumendonca-skills:developer" "a second number after the marker voids it"  "gh issue create --title t --body 'Parent: #99999 (gone). Context: #122'"
# Its control: the SAME shape with only the declared parent present must still ALLOW, or the fix
# would have closed the hole by breaking the feature.
check_agent ALLOW "tadeumendonca-skills:developer" "the declared parent alone still allows"     "gh issue create --title t --body 'Parent: #122 — decomposing'"

# 2 · A `-R` INSIDE THE BODY. `parent_repo` came from the raw command, so a greedy match took an
#     `-R`-looking token out of `--body` — text `gh` never sees as a flag. The issue was created
#     in one repo while `ready` was verified in another, so one ready story anywhere authorised
#     work everywhere. Now read from `$bare`, where quoted spans are already collapsed.
check_agent DENY  "tadeumendonca-skills:developer" "a -R hidden in the body cannot pick the repo" "gh issue create -R owner/other --title t --body 'see -R owner/skills #122'"

# 3 · THE FLOOR BELOW MUST STILL RUN. The first version returned `exit 0` from the middle of the
#     script, so rules 7, 7b and 8 never evaluated: a verified decomposition chained to a trunk
#     push came out with NO decision, where before it was denied twice. An exception in one rule
#     had silently become a bypass of the whole floor.
check_agent DENY  "tadeumendonca-skills:developer" "a verified task chained to a trunk push"    "gh issue create --title t --body 'Parent: #122' && git push origin main"
PATH="$REAL_PATH_5D"

# FAILS CLOSED with no `gh` — the opposite direction from wip-guard, deliberately. That hook is
# loop discipline and must never wedge the loop; this one is the floor, and a floor that fails
# open is not one. Exercised by pointing PATH at a directory holding only the harness's needs,
# with no `gh` — and asserted, unlike wip-guard's equivalent case, because here the harness does
# not need `gh` to run.
NOGH="$(mktemp -d)"
PATH="$NOGH:/usr/bin:/bin"
check_agent DENY  "tadeumendonca-skills:developer" "no gh: cannot prove the parent"            "gh issue create --title t --body 'Parent: #122'"
PATH="$REAL_PATH_5D"
rm -rf "$GHSTUB" "$NOGH"

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
