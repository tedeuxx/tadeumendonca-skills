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
check_agent ALLOW "tadeumendonca-skills:quality-assurance" "the reviewer, behind -R"                  "gh -R owner/repo pr merge 149 --merge"
# NOT `--squash`, in either of the two cases that used to spell it that way. The floor denies
# `Bash(gh pr merge --squash:*)` and the owner's standing rule is never to squash, so a case asserting
# ALLOW on that spelling certified something the loop forbids — it read as coverage of a capability
# nobody has. Only the flag changed; each case still proves what it always did (the `-R` form reaching
# 7b, and a non-reviewer being denied).
check_agent DENY  "tadeumendonca-skills:tech-lead"        "the OTHER lead cannot merge"               "gh pr merge 149 --merge"
# The nearest miss worth pinning: the persona that WROTE the PR is the one with a motive to merge it.
check_agent DENY  "tadeumendonca-skills:developer"        "the author of the PR cannot merge it"      "gh pr merge 149 --merge"
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
# ~~The main loop is unaffected: it still ASKS. The owner answers, per issue, as before.~~
# **CHANGED 2026-08-03 — the main loop falls through too.** A subagent's `gh issue create` is invisible
# (unattended, reported only if the agent chooses to); the main agent's is visible by construction —
# the owner is in the conversation watching the call and can interrupt. The prompt was charging a click
# to the one case that was already observed. Asserted here rather than only in the block below because
# this line is where the old suite said the opposite.
check       ALLOW "main loop no longer asks"                                                   "gh issue create --title t --body 'Parent: #122'"

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

# THE SAME THREE FOR THE MAIN AGENT, added 2026-08-03 with the change that made them necessary. The
# main agent now takes the same fall-through path `developer` does, so it inherits the same failure
# mode: an `exit 0` or a `return` where the ASK used to be would unreach rules 7, 7b and 8 for the
# MOST common caller in the loop, and the developer-only trio above would still pass green. Six cases,
# not three, is the whole reason this change is safe to make.
check_agent DENY  "" "main agent: allow does not unreach rule 7 (trunk push)"  "gh issue create --title t --body b && git push origin main"
check_agent DENY  "" "main agent: allow does not unreach rule 7b (merge)"      "gh issue create --title t --body b && gh pr merge 1 --merge"
check_agent DENY  "" "main agent: allow does not unreach rule 8 (composition)" "gh issue create --title t --body b ; echo done"

# A message ABOUT the act is not the act — matched on `$bare`, after quoted spans collapse.
check_agent ALLOW "tadeumendonca-skills:developer" "a commit message mentioning the act"        "git commit -m 'gh issue create notes'"

# ~~THE FLAG IS NOT INHERITED FROM THE ENVIRONMENT. Found by `security` on this PR: `developer_may`
# was read as `${developer_may:-}` and set only inside the `case`, so an exported variable of that
# name made the MAIN AGENT's `gh issue create` come out with no decision at all — the owner's ASK
# skipped by ambient state. Same shape as the `exit 0` defect this rule already memorialises.~~
#
# **THAT PROBE IS DELETED 2026-08-03, AND THIS IS WHAT IS SAID IN ITS PLACE.** `developer_may` no
# longer exists: it carried one bit from the `case` to the ASK, and there is no ASK. A test whose
# subject is a deleted variable cannot fail — `developer_may=1 bash guard` would now read ALLOW for
# the reason the test was checking AND for the reason it was not, which is a green that means nothing.
# Deleted with its rule, exactly as the ten `Parent: #N` assertions above were.
#
# WHAT SURVIVES IS THE PROPERTY, and it moves to the variable that still gates something. `agent_type`
# decides who is denied here (and who may merge, in 7b), and it is ASSIGNED unconditionally from the
# payload — not `${agent_type:-$(jq …)}`. So an exported `agent_type` cannot claim a persona. This
# assertion CAN still fail: rewrite that assignment to fall back to the environment and the case below
# flips DENY → ALLOW, which is a reviewer opening work with no decision at all.
#
# Exploitability is low, the same way it was for `developer_may` (the hook is a child of the harness,
# not of any command's shell), and that is exactly why it is asserted rather than argued: a fail-open
# at the floor that depends on "you probably cannot reach it" is not closed, it is unmeasured.
out=$(jq -n --arg c "gh issue create --title t --body b" '{tool_input:{command:$c}, agent_type:"tadeumendonca-skills:security"}' | agent_type="tadeumendonca-skills:developer" bash "$GUARD")
if [ "$(verdict "$out")" = "DENY" ]; then
  pass=$((pass + 1)); printf 'ok    %-6s %s\n' "DENY" "an inherited agent_type does not claim a persona (payload wins)"
else
  fail=$((fail + 1)); printf 'FAIL  want=DENY got=%s  an inherited agent_type does not claim a persona (payload wins)\n' "$(verdict "$out")"
fi

# NO `gh` ON PATH: allowed, where the old rule denied. The direction changed because the reason
# changed — the old deny was "cannot PROVE the parent, so fail closed", and there is no longer a
# proof to fail. Asserted so the change is visible rather than incidental.
NOGH="$(mktemp -d)"
REAL_PATH_5D="$PATH"
PATH="$NOGH:/usr/bin:/bin"
check_agent ALLOW "tadeumendonca-skills:developer" "no gh: nothing to look up any more"        "gh issue create --title t --body 'Parent: #122'"
PATH="$REAL_PATH_5D"
rm -rf "$NOGH"

echo "--- rule 5c: the owner decides what enters the queue — denied in a subagent, unblocked in the main loop ---"
# TWO CORRECTIONS, ONE INVERSION, RECORDED IN ORDER because the second only makes sense after the first.
# The rule used to DENY every one of these. That did not stop unaligned work; it taxed ALIGNED work,
# and the tax landed on the owner, who had to type the command themselves for something they had just
# asked for. ~~What is guarded is the alignment, and only the owner can see it — so the main loop asks.~~
# **The ASK went the same way 2026-08-03, for the same reason one caller further out:** the owner hit
# the prompt twice in one evening filing two issues he had just asked for in that conversation. A
# subagent's create is invisible and stays denied; the main agent's is visible by construction — the
# owner is watching the call and can interrupt it — so the prompt was a click charged to the observed
# case while the unobserved one was already covered by the deny below.
check ALLOW "gh issue create"                    "gh issue create --title x --body y"
check ALLOW "behind -R"                          "gh -R owner/repo issue create --title x"
check ALLOW "behind --repo"                      "gh --repo owner/repo issue create --title x"
check ALLOW "with --body-file"                   "gh issue create --title x --body-file /tmp/b.md"
# ~~pflag accepts an attached value in both spellings, and `gh` really parses these — verified against
# the live CLI, not assumed. The first version of the rule required a space and both slipped past, so
# the suite certified coverage it did not have. Kept as ASK cases: the matcher is what is under test
# here, and a spelling that escapes it reaches the tool with NO prompt at all.~~
#
# **THESE TWO ARE NOW WEAK CASES AND THE SUITE SHOULD SAY SO RATHER THAN LOOK COVERED.** With the main
# agent falling through, a spelling the matcher MISSES and a spelling it MATCHES both read ALLOW here,
# so these no longer test the matcher — they can only fail if some future rule denies them. Kept
# because the matcher is still load-bearing for the subagent branch, and that is where the attached-
# value spellings are now actually exercised: see the `-R`/`--repo=` DENY cases a few lines below.
check ALLOW "--repo= attached"                   "gh --repo=owner/repo issue create --title x"
check ALLOW "-R attached shorthand"              "gh -Rowner/repo issue create --title x"
# ~~The `gh api` route is a NAMED ACCEPTED GAP~~ — **closed by rule 5f since 2026-08-04, and the first
# line below flipped from ALLOW to DENY with it.** The gap was real for as long as this rule was the
# only thing looking; what changed is that a rule which CAN tell a read from a write now runs first.
# The second and third cases are unchanged and are what keeps 5f honest here: reading is still open,
# and a commit message about the act is still not the act.
check DENY  "gh api POST is closed by 5f now"    "gh api --method POST /repos/o/r/issues -f title=x"
check ALLOW "gh api listing issues"              "gh api repos/o/r/issues --paginate"
check ALLOW "a commit message about the act"     'git commit -m "gh api repos/o/r/issues -f title=x"'
# A SUBAGENT STILL CANNOT FILE, and this is where the measured failure actually happened: 13 of 19
# issues in one session were born inside a review of something else. A persona has no access to the
# owner, so it cannot answer the question the prompt asks — it reports upward instead. `agent_type` is
# stamped by the harness and cannot be forged by the model, so this is not a spelling it can escape.
check_agent DENY "tadeumendonca-skills:quality-assurance" "not even the reviewer files"  "gh issue create --title x"
# `tech-lead` and NOT `product-lead`, deliberately, though the latter absorbed the old `scrum-master`
# this case used to name. Rule 5e denies `product-lead` on `gh issue create` BEFORE 5c is reached, so
# the case would still read DENY with 5c/5d entirely broken — it would stop witnessing the rule it is
# filed under. `tech-lead` has no 5e rule and no 5d exemption, so its verdict comes from 5c alone.
check_agent DENY "tadeumendonca-skills:tech-lead"         "not even the other lead"       "gh issue create --title x"
# THE MATCHER'S ONLY REMAINING TEETH ARE HERE, so the spellings are exercised HERE. pflag accepts an
# attached value in both forms and `gh` really parses them — verified against the live CLI, not
# assumed; the first version of the rule required a space and both slipped past, certifying coverage
# it did not have. Since 2026-08-03 the main-agent cases above cannot catch that regression (they read
# ALLOW either way), so these two carry it: a matcher that misses the attached form lets a REVIEWER
# open work with no decision at all.
check_agent DENY "tadeumendonca-skills:quality-assurance" "subagent, --repo= attached"    "gh --repo=owner/repo issue create --title x"
check_agent DENY "tadeumendonca-skills:quality-assurance" "subagent, -R attached"         "gh -Rowner/repo issue create --title x"
check_agent DENY "tadeumendonca-skills:quality-assurance" "subagent, --body-file"         "gh issue create --title x --body-file /tmp/b.md"
# The other side of the same split. ~~an empty agent_type is the main loop, and it asks~~ — **it now
# falls through (2026-08-03).** The case is kept and inverted rather than deleted: it is what fails if
# someone applies the subagent branch to everyone, which was the original bug this line guarded, and
# it is equally what fails if someone reverts the main agent to ASK without touching this file.
check_agent ALLOW "" "an empty agent_type is the main loop, and it is no longer asked" "gh issue create --title x"

# Everything else about issues stays open, or the rule would block reading the board rather than
# opening work. These are the partner cases: without them "DENY create" would pass for a rule that
# blocked `gh issue` entirely.
check ALLOW "reading an issue"        "gh issue view 173"
check ALLOW "listing issues"          "gh issue list --state open"
check ALLOW "commenting on an issue"  "gh issue comment 173 --body-file /tmp/c.md"
check ALLOW "closing an issue"        "gh issue close 173"
check ALLOW "labelling an issue"      "gh issue edit 173 --add-label product"
check ALLOW "the words in a message"  "git commit -m 'gh issue create notes'"

echo "--- rule 5f: gh api that WRITES is closed; gh api that READS is not ---"
# The route rules 5c and 7b each booked as a permanently accepted gap. It lived in the floor's `deny`
# as a blanket `Bash(gh api:*)` for about an hour; that was too broad — it took the READ path with it,
# which this repo's own loop uses — so it moved here, to the layer that can tell the two apart.
check DENY  "--method POST"              "gh api --method POST repos/o/r/issues -f title=x"
check DENY  "--method PUT"               "gh api --method PUT repos/o/r/pulls/1/merge"
check DENY  "--method PATCH"             "gh api --method PATCH repos/o/r/issues/1"
check DENY  "--method DELETE"            "gh api --method DELETE repos/o/r/issues/1/labels/bug"
check DENY  "--method= attached"         "gh api --method=POST repos/o/r/issues"
check DENY  "lowercase method value"     "gh api --method post repos/o/r/issues"
# `-X` is --method's real short form. It was NOT in the brief that specified this rule; a rule closing
# the long spelling and leaving the short one open is the "which spelling did you happen to use" floor
# this file has rejected twice already (rule 4's flag set, 5b's -R).
check DENY  "-X spaced"                  "gh api -X POST repos/o/r/issues"
check DENY  "-X attached"                "gh api -XPOST repos/o/r/issues"
check DENY  "-X mixed case value"        "gh api -X Delete repos/o/r/issues/1/labels/bug"
# THE CASE THE WHOLE RULE EXISTS FOR, and the reason the settings-layer prefix could never do this:
# `-f`/`-F` switch the request to POST on their own, so this is a WRITE with no --method anywhere. It
# is the exact command the audit found — creating an issue around the owner-opens-work rule.
check DENY  "-f implies POST, no method" "gh api repos/o/r/issues -f title=x -f body=y"
check DENY  "-F implies POST, no method" "gh api repos/o/r/issues -F title=x"
check DENY  "--raw-field long form"      "gh api repos/o/r/issues --raw-field title=x"
check DENY  "--field long form"          "gh api repos/o/r/issues --field title=x"
check DENY  "--field= attached"          "gh api repos/o/r/issues --field=title=x"
check DENY  "--input reads a body file"  "gh api repos/o/r/issues --input /tmp/body.json"
check DENY  "the merge back door (7b)"   "gh api --method PUT repos/o/r/pulls/149/merge"
check DENY  "gh api behind -R"           "gh -R owner/repo api repos/o/r/issues -f title=x"
# THE ATTACHED FIELD VALUE, measured ALLOW on 2026-08-04 — the audit route respelled, at a moment when
# 5f was the ONLY layer holding it (the floor's blanket `Bash(gh api:*)` had just been removed in the
# same diff). pflag takes the value attached, and the alternation required space/=/EOL after `-f`.
check DENY  "-f value attached"          "gh api repos/o/r/issues -ftitle=x"
check DENY  "-F value attached"          "gh api repos/o/r/issues -Ftitle=x"
check DENY  "attached, merge back door"  "gh api repos/o/r/pulls/1/merge -fmerge_method=merge"
check DENY  "-X= attached value"         "gh api -X=POST repos/o/r/issues"
check DENY  "--input= attached"          "gh api repos/o/r/issues --input=/tmp/b.json"
check DENY  "graphql mutation via -f"    "gh api graphql -f query=mutation"
# The long forms keep their trailing anchor, which is what stops a longer flag name matching.
check ALLOW "--fieldwork is not --field" "gh api repos/o/r/issues --fieldwork x"

echo "--- rule 5f: READING through gh api must survive, or the rule has broken the loop ---"
# This is the half the blanket floor deny got wrong. Each of these is a real call this repo makes.
check ALLOW "plain read"                 "gh api repos/o/r/releases/latest"
check ALLOW "read with --jq"             "gh api repos/o/r/releases/latest --jq '.tag_name'"
check ALLOW "read with --paginate"       "gh api repos/o/r/issues --paginate"
check ALLOW "query params, not fields"   "gh api 'repos/o/r/issues?state=open&per_page=100'"
check ALLOW "explicit GET"               "gh api --method GET repos/o/r/issues"
check ALLOW "-X GET"                     "gh api -X GET repos/o/r/issues"
check ALLOW "a REST path containing -f"  "gh api repos/o/r/contents/src/-f-config.json"
# $bare: a message ABOUT the act is not the act. This trap has now caught a version of three different
# rules in this file, which is why it is convention rather than case-by-case care.
check ALLOW "commit message about it"    "git commit -m 'gh api repos/o/r/issues -f title=x'"
check ALLOW "a grep for the pattern"     "grep -rn 'gh api -f' docs"
# 5f has no allow BRANCH — it either denies or falls past the `if` — but the file's most expensive
# lesson is that someone eventually adds an early return to a rule that did not have one. Rules 7 and 8
# run strictly after 5f, so a read reaching them is what proves the fall-through is intact.
check DENY  "read does not unreach rule 7" "gh api repos/o/r/releases/latest && git push origin main"
check DENY  "read does not unreach rule 8" "gh api repos/o/r/releases/latest ; echo done"

echo "--- rule 5e: product-lead does not write to a public surface ---"
# The roster merge folded `marketing-lead` (tools: Read, Grep, Glob — no Bash, deliberately) into
# `product-lead`, which carries Bash. The persona that reads the PRIVATE `.brand/` layer can now run
# `gh`, and its output lands in PUBLIC comments. These are the cases that hold the capability boundary
# the merge dissolved. A DENY here is not about scope — it is that deleting a comment does not undo a
# disclosure.
check_agent DENY "tadeumendonca-skills:product-lead" "pr comment"                  "gh pr comment 149 --body 'positioning says x'"
check_agent DENY "tadeumendonca-skills:product-lead" "issue comment"               "gh issue comment 149 --body 'positioning says x'"
check_agent DENY "tadeumendonca-skills:product-lead" "issue create"                "gh issue create --title x --body y"
check_agent DENY "tadeumendonca-skills:product-lead" "pr comment, --body-file"     "gh pr comment 149 --body-file /tmp/c.md"
# The spellings. `gh` really parses all four of these; the matcher must too, or the boundary is a
# convention about punctuation. Same pflag shape rule 5b/5c use, exercised again here because a rule
# is only as wide as its own pattern.
check_agent DENY "tadeumendonca-skills:product-lead" "pr comment behind -R"        "gh -R owner/repo pr comment 149 --body b"
check_agent DENY "tadeumendonca-skills:product-lead" "pr comment behind --repo"    "gh --repo owner/repo pr comment 149 --body b"
check_agent DENY "tadeumendonca-skills:product-lead" "pr comment, --repo= attached" "gh --repo=owner/repo pr comment 149 --body b"
check_agent DENY "tadeumendonca-skills:product-lead" "pr comment, -R attached"     "gh -Rowner/repo pr comment 149 --body b"
check_agent DENY "tadeumendonca-skills:product-lead" "issue comment behind -R"     "gh -R owner/repo issue comment 149 --body b"
check_agent DENY "tadeumendonca-skills:product-lead" "issue create behind --repo"  "gh --repo owner/repo issue create --title x"
# The glob is `*:product-lead`, so it does not depend on which plugin name the harness prefixes.
check_agent DENY "otherplugin:product-lead"          "any plugin prefix"           "gh pr comment 149 --body b"

echo "--- rule 5e: it must not cost the persona what it actually needs ---"
# `product-lead` has Bash to READ the live queue — ordering work means seeing the board. A rule that
# took that away would break the persona to protect it. Without these, "DENY comment" would pass for a
# rule that blocked `gh` outright.
check_agent ALLOW "tadeumendonca-skills:product-lead" "listing PRs"                "gh pr list --state open"
check_agent ALLOW "tadeumendonca-skills:product-lead" "listing issues"             "gh issue list --label product"
check_agent ALLOW "tadeumendonca-skills:product-lead" "viewing a PR"               "gh pr view 149 --json labels"
check_agent ALLOW "tadeumendonca-skills:product-lead" "viewing an issue"           "gh issue view 173"
check_agent ALLOW "tadeumendonca-skills:product-lead" "reading a PR's comments"    "gh pr view 149 --json comments"
# Matched on $bare, after quoted spans collapse — 5c's suite caught a version of ITS rule denying a
# commit message ABOUT the act. Same trap, asserted rather than assumed.
check_agent ALLOW "tadeumendonca-skills:product-lead" "a message mentioning the act" "git commit -m 'gh pr comment notes'"

echo "--- rule 5e: the gatekeeper protocol must keep running ---"
# Both gatekeepers comment their verdict on every MR. A rule that matched by SUBCOMMAND rather than by
# agent would take out the protocol this whole loop runs on, and would do it silently — the verdicts
# would simply stop arriving. These are the cases that fail if 5e is ever widened past its one persona.
check_agent ALLOW "tadeumendonca-skills:quality-assurance" "the reviewer comments its verdict" "gh pr comment 149 --body-file /tmp/verdict.md"
check_agent ALLOW "tadeumendonca-skills:quality-assurance" "the reviewer comments on an issue" "gh issue comment 173 --body b"
check_agent ALLOW "tadeumendonca-skills:security"          "security comments its verdict"     "gh pr comment 149 --body-file /tmp/verdict.md"
check_agent ALLOW "tadeumendonca-skills:security"          "security comments on an issue"     "gh issue comment 173 --body b"
check_agent ALLOW "tadeumendonca-skills:developer"         "the builder comments on its own PR" "gh pr comment 149 --body b"
check_agent ALLOW "tadeumendonca-skills:tech-lead"         "the other lead still comments"     "gh pr comment 149 --body b"
# The main agent is an EMPTY agent_type, and the ASK removal in this same tree means it now falls
# through 5c as well. 5e must not re-block what that change deliberately opened.
check_agent ALLOW "" "main agent comments on a PR"    "gh pr comment 149 --body b"
check_agent ALLOW "" "main agent comments on issue"   "gh issue comment 173 --body b"
check_agent ALLOW "" "main agent still files issues"  "gh issue create --title x --body y"
# And 5d's exemption is unchanged — 5e runs BEFORE 5c, so a bug here would have eaten it.
check_agent ALLOW "tadeumendonca-skills:developer" "developer keeps its 5d exemption" "gh issue create --title 'task: x' --body 'Parent: #122'"

echo "--- rule 5e: allowing must remain FALLING THROUGH, not exiting ---"
# The most expensive lesson in the guard, re-paid here. An early `exit 0` on the allow path of 5e would
# unreach rules 7 (trunk push), 7b (merge) and 8 (composition) — the composed command would come out
# with NO decision at all, where it is currently denied. All three rules below run strictly AFTER 5e,
# so each verdict genuinely witnesses the fall-through rather than an earlier rule.
# Verified by mutation: `*) exit 0 ;;` added to 5e's case reddened **20 cases** — these five plus the
# whole 5c/5d block and rule 8's `gh pr comment … && npx tsc`, because 5e runs before them and the exit
# swallowed those too. The first edition of this line said "exactly these five", which was the number
# the author expected rather than the number the mutation produced; re-running it is what corrected it.
# The point survives and is stronger: the blast radius of an early return here is four times what the
# rule itself covers.
check_agent DENY "" "allow does not unreach rule 7 (trunk push)"  "gh pr comment 1 --body b && git push origin main"
check_agent DENY "" "allow does not unreach rule 7b (merge)"      "gh pr comment 1 --body b && gh pr merge 1 --merge"
check_agent DENY "" "allow does not unreach rule 8 (composition)" "gh pr comment 1 --body b ; echo done"
check_agent DENY "tadeumendonca-skills:quality-assurance" "reviewer: still reaches rule 7"  "gh pr comment 1 --body b && git push origin main"
check_agent DENY "tadeumendonca-skills:security"          "security: still reaches rule 8"  "gh issue comment 1 --body b ; echo done"

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
# THE ATTACHED SPELLINGS, measured ALLOW before 2026-08-04. 5b kept its own space-only copy of the -R
# pattern while `Bash(gh -R:*)` sat in the allowlist, so these three were a silent secret write.
check DENY  "secret set, -R attached"       "gh -Rowner/repo secret set MY_TOKEN"
check DENY  "secret set, --repo= attached"  "gh --repo=owner/repo secret set MY_TOKEN"
check DENY  "secret delete, -R= attached"   "gh -R=owner/repo secret delete MY_TOKEN"
# 5b matched $cmd until the normalisation block moved above it, so a message ABOUT the act was denied
# as the act. This is the case that was red before that move.
check ALLOW "a message about the act"       "git commit -m 'gh secret set MY_TOKEN'"

echo "--- rule 5g: the gh subcommands the floor denies and the hook could not see ---"
# `Bash(gh -R:*)` in `allow` moved the -R spelling of EVERY gh deny entry from "prompts the human" to
# "runs silently". `gh -R owner/repo repo delete --yes` returned no decision from any layer at all.
check DENY  "repo delete"                   "gh repo delete owner/repo --yes"
check DENY  "repo delete behind -R"         "gh -R owner/repo repo delete --yes"
check DENY  "repo delete, -R attached"      "gh -Rowner/repo repo delete --yes"
check DENY  "repo delete, --repo= attached" "gh --repo=owner/repo repo delete --yes"
check DENY  "repo archive"                  "gh repo archive owner/repo"
check DENY  "repo rename breaks OIDC trust" "gh repo rename newname"
check DENY  "release create publishes"      "gh release create v1.2.3"
check DENY  "release delete behind -R"      "gh -R owner/repo release delete v1.2.3"
check DENY  "workflow run dispatches CI"    "gh workflow run deploy.yml"
check DENY  "workflow run behind -R"        "gh -R owner/repo workflow run deploy.yml"
check DENY  "workflow run, --repo="         "gh --repo=owner/repo workflow run deploy.yml"

echo "--- rule 5g: must not over-block — the read half of each pair ---"
# Without these, "DENY repo delete" would pass for a rule that blocked `gh repo` entirely. Each of
# these is in the allowlist and is a call the loop actually makes.
check ALLOW "repo view"                     "gh repo view owner/repo"
check ALLOW "release view"                  "gh release view v1.2.3"
check ALLOW "release list"                  "gh release list"
check ALLOW "workflow list"                 "gh workflow list"
check ALLOW "workflow view"                 "gh workflow view deploy.yml"
check ALLOW "run list"                      "gh run list --limit 5"
check ALLOW "a message about the act"       "git commit -m 'gh repo delete notes'"

echo "--- rule 4b: git clean -f deletes what git cannot give back ---"
# Same bypass shape as the gh finding, in the other half of the allowlist: `Bash(git -C:*)` is allowed,
# and the floor's `git clean -f` deny is a prefix, so `git -C /path clean -fd` had no decision at all.
check DENY  "clean -f"                      "git clean -f"
check DENY  "clean -fd"                     "git clean -fd"
check DENY  "clean behind -C"               "git -C /some/repo clean -fd"
check DENY  "clean, flags split"            "git clean -d -f"
check DENY  "clean, fused -xdf"             "git clean -xdf"
check DENY  "clean --force long form"       "git clean --force -d"
check ALLOW "dry run is the safe form"      "git clean -n"
check ALLOW "--dry-run long form"           "git clean --dry-run"
check ALLOW "a message about the act"       "git commit -m 'git clean -fd notes'"

echo "--- rule 7: pushing tags publishes a Release ---"
# Both --tags and --follow-tags are in the floor's deny and neither was matched here.
check DENY  "push --tags"                   "git push --tags"
check DENY  "push --tags behind -C"         "git -C /some/repo push --tags origin"
check DENY  "push --follow-tags"            "git push --follow-tags origin feat/x"
check ALLOW "a plain feature push"          "git push origin feat/x"

echo "--- rule 7b: squash is denied to EVERYONE, the reviewer included ---"
# The floor denies `gh pr merge --squash`; `Bash(gh -R:*)` walked around that entry, and the reviewer is
# the one caller 7b lets through — so the check sits BEFORE the persona case, or the exemption carries
# it. The standing rule is a real merge commit, never a squash.
check_agent DENY "tadeumendonca-skills:quality-assurance" "the reviewer cannot squash"        "gh pr merge 1 --squash"
check_agent DENY "tadeumendonca-skills:quality-assurance" "the reviewer cannot squash via -R" "gh -Ro/r pr merge 1 --squash"
check_agent DENY "tadeumendonca-skills:quality-assurance" "the -s squash spelling too"        "gh pr merge 1 -s squash"
check_agent ALLOW "tadeumendonca-skills:quality-assurance" "a real merge commit is the way"   "gh pr merge 1 --merge"

echo "--- rule 7b: the merge gate no longer depends on punctuation ---"
# Measured ALLOW before 2026-08-04, from ANY caller: 7b kept its own space-only -R copy. This is the
# gate the whole loop's authority rests on, and it was open to a caller who omitted a space.
check_agent DENY "" "main agent, -R attached"      "gh -Ro/r pr merge 1 --merge"
check_agent DENY "" "main agent, --repo= attached" "gh --repo=o/r pr merge 1 --merge"
check_agent DENY "" "main agent, -R= attached"     "gh -R=o/r pr merge 1 --merge"
check_agent DENY "tadeumendonca-skills:developer" "the author, -R attached"      "gh -Ro/r pr merge 1 --merge"
check_agent DENY "tadeumendonca-skills:developer" "the author, --repo= attached" "gh --repo=o/r pr merge 1 --merge"
check_agent ALLOW "tadeumendonca-skills:quality-assurance" "reviewer, -R attached"      "gh -Ro/r pr merge 1 --merge"
check_agent ALLOW "tadeumendonca-skills:quality-assurance" "reviewer, --repo= attached" "gh --repo=o/r pr merge 1 --merge"

echo "--- the -c payload unwrap: a wrapper is not a bypass ---"
# EVERY $bare rule was blind to `bash -c '<payload>'`, because $bare collapses quoted spans and the
# payload of -c is a COMMAND that happens to be quoted. Rule 4 (rm) matches $cmd and was the only rule
# that caught it — which is why an empirical check that sampled `rm` reported the whole class covered.
# All five of these were measured ALLOW, with no decision from the hook OR the settings deny.
check       DENY "wrapped trunk push (rule 7)"   "bash -c 'git push origin main'"
check       DENY "wrapped merge (rule 7b)"       "bash -c 'gh pr merge 145'"
check_agent DENY "tadeumendonca-skills:security" "wrapped issue create (5c)" "bash -c 'gh issue create --title x'"
check_agent DENY "tadeumendonca-skills:product-lead" "wrapped pr comment (5e)" "bash -c 'gh pr comment 1 --body b'"
check       DENY "wrapped gh api write (5f)"     "bash -c 'gh api repos/o/r/issues -f title=x'"
# The rest of the floor through the same wrapper.
check DENY "wrapped terraform apply"        "bash -c 'terraform apply -auto-approve'"
check DENY "wrapped rm -rf"                 "bash -c 'rm -rf /some/path'"
check DENY "wrapped secret set"             "bash -c 'gh secret set MY_TOKEN'"
check DENY "wrapped repo delete"            "bash -c 'gh repo delete owner/repo --yes'"
# Spellings: double quotes, other shells, an absolute path, a combined flag cluster, and nesting.
check DENY "double-quoted payload"          'bash -c "git push origin main"'
check DENY "sh instead of bash"             "sh -c 'git push origin main'"
check DENY "an absolute interpreter path"   "/bin/bash -c 'git push origin main'"
check DENY "zsh"                            "zsh -c 'git push origin main'"
check DENY "-lc flag cluster"               "bash -lc 'git push origin main'"
check DENY "nested wrappers"                'bash -c "bash -c '"'"'git push origin main'"'"'"'

echo "--- the unwrap must not become collateral: running a FILE is not a wrapper ---"
# `bash script.sh` has no -c and must be untouched — this suite is itself run that way.
check ALLOW "running a script file"         "bash hooks/scripts/permission-guard.test.sh"
check ALLOW "an absolute script path"       "bash /some/path/script.sh"
check ALLOW "bash --version"                "bash --version"
check ALLOW "node running a file"           "node scripts/build.mjs"
# THE WORD BOUNDARY: without `(^|[[:space:]]|/)` before the shell name, `.*sh[[:space:]]+-c` matches the
# `sh` inside `finish` and appends whatever follows as though it were a payload. The failure is a false
# POSITIVE — an ordinary command denied for a fragment it never ran.
#
# THE FIRST TWO CASES DO NOT WITNESS THAT, and saying so is the point: the fragment they append (`x`,
# nothing) is harmless, so they pass with or without the boundary. Mutation caught them claiming a
# coverage they did not have.
#
# THE THIRD IS THE WITNESS, AND CONSTRUCTING IT TOOK TWO TRIES — the first attempt passed the payload
# UNQUOTED, which rule 7 denies straight from the raw string whether or not anything unwrapped. The
# assertion has to isolate the unwrap: the payload is QUOTED, so `$bare` collapses it and no rule sees
# it — unless the unwrap wrongly strips those quotes and appends the contents bare. That is precisely
# the false positive the boundary prevents, and it reddens when the boundary is removed.
check ALLOW "a word merely ENDING in sh"     "npm run finish -c x"
check ALLOW "another -c that is not a shell" "docker run -c 512 img"
check ALLOW "boundary: quoted arg stays inert" "npm run finish -c 'git push origin main'"

echo "--- the pre-existing floor still holds ---"
check DENY  "terraform apply"               "terraform apply -auto-approve"
check DENY  "terraform destroy"             "terraform -chdir=iac destroy"
check DENY  "force push"                    "git push --force origin feat/x"
check DENY  "reset --hard"                  "git reset --hard HEAD~1"
check DENY  "rm -rf"                        "rm -rf build"
check DENY  "skip-permissions bypass"       "claude --dangerously-skip-permissions"
check ALLOW "terraform plan"                "terraform -chdir=iac plan"

echo "--- rule 4: the flags are a SET, however they are split or cased ---"
# The first four were measured ALLOW against the previous pattern, which required both letters in one
# lowercase cluster. Same act, different punctuation, opposite verdict.
check DENY  "split, -r then -f"             "rm -r -f /some/path"
check DENY  "split, -f then -r"             "rm -f -r /some/path"
check DENY  "fused, mixed case -fR"         "rm -fR /some/path"
check DENY  "fused, mixed case -Rf"         "rm -Rf /some/path"
check DENY  "split with a flag between"     "rm -r -v -f /some/path"
check DENY  "long forms"                    "rm --recursive --force /some/path"
check DENY  "long force, short recursive"   "rm -R --force /some/path"

echo "--- rule 4: must not over-block — one flag alone is not the floor's concern ---"
# The ALLOW half is what keeps the fix honest: widening a deny until everything matches is not a fix.
check ALLOW "recursive without force"       "rm -r /some/path"
check ALLOW "force without recursive"       "rm -f /some/path"
check ALLOW "--force alone"                 "rm --force /some/path"
check ALLOW "plain rm"                      "rm /some/path"
check ALLOW "a word merely ENDING in rm"    "npm run confirm -r -f"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
