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

# A `gh` STUB ON PATH, FOR THE WHOLE SUITE — rule 7c reads the PR's own verdict comment via a real
# `gh pr view` call, and nothing else in this file executes `gh` at all (every other rule is a pure
# string match). Without a stub, every existing "the reviewer merges" ALLOW case below would either
# hit the real network (this repo is public, so `gh pr view 149` might even resolve to a REAL PR) or
# fail silently into 7c's fail-open path — either way the suite's result would depend on what GitHub
# currently holds, which is exactly what session-wip.test.sh's own header says a suite must not do.
#
# THE DEFAULT FIXTURE IS "CLEAN": current head `stubbed-head`, one OWNER comment carrying the marker,
# APPROVE-AND-MERGE, against that same head. Every pre-existing ALLOW case for the reviewer relies on
# this default without saying so — it is what keeps them asserting what they always asserted (identity
# is sufficient) now that a second condition (the verdict) sits behind it. Dedicated cases below swap
# the stub to prove the SECOND condition independently, then restore this default.
GH_STUB_DIR="$(mktemp -d)"
cat > "$GH_STUB_DIR/gh" <<'STUB'
#!/bin/sh
# Static stub: always serves the fixture file, regardless of PR ref/repo args — the ref/repo
# PARSING itself is exercised separately (see the "rule 7c" section's arg-logging variant below).
if [ "$1 $2" = "pr view" ]; then
  cat "$(dirname "$0")/fixture.json" 2>/dev/null
fi
exit 0
STUB
chmod +x "$GH_STUB_DIR/gh"
# jq builds the fixture — same reason session-wip.test.sh's add_pr_view() does: hand-rolled JSON
# string escaping is exactly the kind of "obviously correct" code this repo's own standard distrusts.
#
# THE FIXTURE CARRIES `closingIssuesReferences` SINCE #363, AND CARRYING IT IS NOT COSMETIC. Rule 7d
# denies when the payload lacks the key at all, so a stub that omits it would turn every pre-existing
# reviewer-ALLOW case in this file red for a reason that has nothing to do with what those cases
# assert. The default is the EMPTY array — a PR that closes nothing — which is what keeps them
# asserting exactly what they always asserted. $3 and $4 exist for the 7d cases below: the set the
# forge would act on, and the set the verdict declares.
write_gh_fixture() { # head · verdict-literal-or-empty ('' = no comments) · forge-closes · declared-closes
  head="$1"; verdict="$2"; forge_closes="${3:-}"; declared="${4:-}"
  # NO `grep .` HERE, AND THE OMISSION IS LOAD-BEARING under this file's `set -o pipefail`: an empty
  # closing set makes `grep` exit 1, the pipeline inherits it, and a trailing `|| printf '[]'` then
  # appends a SECOND `[]` to jq's own — producing a two-value argjson that fails, an unwritten fixture,
  # and ten ALLOW cases denied for a reason that has nothing to do with the rule under test. Measured
  # exactly that way while building this. `select(length>0)` does the filtering inside jq, where an
  # empty stream is a normal result rather than a failure.
  closing="$(printf '%s' "$forge_closes" | tr ' ' '\n' | jq -R 'select(length > 0) | tonumber | {number: .}' | jq -s '.')"
  if [ -z "$verdict" ]; then
    jq -n --arg h "$head" --argjson c "$closing" \
      '{headRefOid:$h, comments:[], closingIssuesReferences:$c}' > "$GH_STUB_DIR/fixture.json"
  else
    body="<!-- gatekeeper-verdict: quality-assurance -->
${verdict}
head: ${head}"
    [ -n "$declared" ] && body="${body}
closes: ${declared}"
    jq -n --arg h "$head" --arg b "$body" --argjson c "$closing" \
      '{headRefOid:$h, comments:[{authorAssociation:"OWNER", body:$b}], closingIssuesReferences:$c}' > "$GH_STUB_DIR/fixture.json"
  fi
}
write_gh_fixture "stubbed-head" "APPROVE-AND-MERGE"
export PATH="$GH_STUB_DIR:$PATH"

# THREE outcomes, not two. The suite used to classify by `grep '"deny"'` and call everything else
# ALLOW — so when rule 5c started returning `ask`, a test asserting ALLOW would have passed on it and a
# test asserting ASK could not have been written at all. A harness that cannot see a decision cannot
# fail for it, which is the exact defect this repo's own review standard hunts for.
# ── WHAT `ALLOW` MEANS HERE, AND WHAT IT DOES NOT ────────────────────────────────────────────────
# `ALLOW` IS "THE HOOK EMITTED NO DECISION". It is NOT "the command runs". This harness pipes a
# command into the guard and classifies the GUARD'S OWN stdout; nothing in this file reads
# `.claude/settings.json`, so the effective outcome — run, prompt, or refuse — is decided by a layer
# the suite cannot see.
#
# THAT DISTINCTION HAS ALREADY GONE STALE ONCE, WHICH IS WHY IT IS WRITTEN HERE. A section below
# described `perl -e` as "an accepted gap that reaches ALLOW". The assertion was correct and stayed
# green; the PROSE was describing the floor as it stood that morning, and by the afternoon `perl` had
# been removed from `allow`, so the same silent hook produced an ASK instead. **A test asserting hook
# silence cannot notice a floor change** — nothing goes red, because nothing about the hook moved.
#
# SO: when a comment here explains the CONSEQUENCE of silence, it is making a claim about a file this
# suite does not test, and that claim has to be re-checked whenever the floor moves. Prefer stating
# the DERIVATION ("no allow entry remains that would shadow the act") over the enumeration ("`bash:*`
# and `sh:*` were removed") — the derivation survives the next floor edit and the list does not.
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

# ADDED #383 S3-revert. `check` classifies a verdict and nothing else, which was sufficient while two
# overlapping rules returned DIFFERENT verdicts. Reverting 3b to `deny` made rule 7 and 3b agree on the
# verdict, so a verdict-only battery went green over BOTH orderings — an assertion that cannot fail,
# which is this repo's own named defect. This helper asserts WHICH rule answered, by matching a
# distinctive fragment of its reason.
#
# IT ASSERTS THE REASON, NOT THE MESSAGE. The needle is a short fragment chosen to be unique across the
# file's messages; rewording a message around it is free, and rewording it away is meant to redden.
check_reason() {
  want="$1"
  desc="$2"
  needle="$3"
  cmd="$4"
  out=$(printf '%s' "$cmd" | jq -R '{tool_input:{command:.}}' | bash "$GUARD")
  got=$(verdict "$out")
  reason=$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecisionReason // ""')
  if [ "$got" = "$want" ] && printf '%s' "$reason" | grep -qF "$needle"; then
    pass=$((pass + 1))
    printf 'ok    %-6s %s\n' "$got" "$desc"
  else
    fail=$((fail + 1))
    printf 'FAIL  want=%s/%s got=%s  %s\n      cmd: %s\n      reason: %s\n' \
      "$want" "$needle" "$got" "$desc" "$cmd" "$reason"
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
# EVERY CASE HERE NAMES ITS REPO, and that is not decoration — it is the whole reason this
# section is trustworthy.
#
# Rule 7 resolves a push carrying no `-C` against `dir="."`, so it reads the CURRENT BRANCH OF
# WHATEVER DIRECTORY THE SUITE RUNS FROM. Written without `-C`, these four asserted ALLOW and
# were green from a feature checkout and RED from one sitting on `main` — 276 passed / 5 failed,
# measured. The guard was right both times; the suite was asking a question whose answer it did
# not control.
#
# CI never saw it: a PR checkout is always on a feature branch, so this was green in CI forever
# and red on a maintainer's machine, for a reason nothing prints. This repo's comments warn about
# that class twice already.
#
# `$FEAT` is an unborn repo on a feature branch — `git init -b` with no commit, because
# `symbolic-ref` reports an unborn HEAD, which is the property rule 7 relies on and the `BARE`
# case below already asserts.
FEAT="$(mktemp -d)"
git init -q -b feat/fixture "$FEAT"
check ALLOW "feature branch, plain"         "git -C $FEAT push origin feat/x"
check ALLOW "feature branch via -C"         "git -C /some/repo push origin feat/x"
check ALLOW "set-upstream a feature"        "git -C $FEAT push -u origin feat/x"
check ALLOW "branch merely NAMED main-*"    "git -C $FEAT push origin feat/main-nav"

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

echo "--- rule 7c: identity alone is not enough — the merge must match its OWN posted verdict, on the CURRENT head ---"
# ADR-0004's "The merge precondition is a floor, not an instruction" section: the caller-identity check
# above (7b) proves WHO is merging; it says nothing about whether that caller's own verdict, sitting on
# the PR right now, actually says APPROVE-AND-MERGE for the code that is there. Every case in THIS
# section holds agent_type at quality-assurance — 7b already passed — and varies only the fixture.
write_gh_fixture "stubbed-head" "REQUEST-CHANGES"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "own REQUEST-CHANGES on the current head blocks the merge" "gh pr merge 149 --merge"
write_gh_fixture "stubbed-head" "APPROVE-PENDING-HUMAN"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "own APPROVE-PENDING-HUMAN blocks it too — the four surviving holds never merge" "gh pr merge 149 --merge"
# THE SECOND MERGE-AUTHORISING LITERAL (ADR-0002 amendment #16). The owner retired the hold-for-owner
# rule on boundary-class merges — one environment, so holding the merge produced no preview, only a
# queue — and the gate now clears the boundary class under its OWN literal, so the merge record still
# says which class shipped without a pre-publication check. Both the ALLOW and the near-miss are
# asserted, because the whole risk of adding a literal is that the matcher gets loose while doing it.
write_gh_fixture "stubbed-head" "APPROVE-AND-MERGE-BOUNDARY"
check_agent ALLOW "tadeumendonca-skills:quality-assurance" "APPROVE-AND-MERGE-BOUNDARY clears the merge — the gate merges the boundary class" "gh pr merge 149 --merge"
# THE ANTI-GLOB CASE. `APPROVE-AND-MERGE*` would have satisfied both literals above in one pattern and
# would ALSO have cleared every future drift that happens to share the prefix. This fixture is the one
# that fails if anyone reaches for that shortcut; it cannot be caught by the two positive cases.
write_gh_fixture "stubbed-head" "APPROVE-AND-MERGE-LATER"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "a PREFIX-SHARING drift ('APPROVE-AND-MERGE-LATER') is not either literal — the arm is not globbed" "gh pr merge 149 --merge"
# THE FIFTH LITERAL (#374). `APPROVE-EXECUTOR-BLOCKED` says the gate cleared this diff and COULD NOT
# execute the merge, so the act became the owner's by exception. A verdict whose content is "I could
# not merge this" must not be a verdict that merges it — and it must not be read as a member of the
# merge-authorising family, which is why the literal is spelled disjoint from `APPROVE-AND-MERGE-…`
# rather than as another suffix on it. Mutate: add it to the clearing arm -> this goes red.
write_gh_fixture "stubbed-head" "APPROVE-EXECUTOR-BLOCKED"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "APPROVE-EXECUTOR-BLOCKED does not merge — it records that the gate could not" "gh pr merge 149 --merge"
# STALE HEAD: the verdict is APPROVE-AND-MERGE, but against a SHA that is no longer the PR's head — a
# later, unreviewed commit landed after the verdict was posted. This is the exact failure ADR-0006 was
# written for: a verdict on a superseded head must not read as approval of what is there now.
jq -n '{headRefOid:"new-head-after-verdict", comments:[{authorAssociation:"OWNER", body:"<!-- gatekeeper-verdict: quality-assurance -->\nAPPROVE-AND-MERGE\nhead: old-head-the-verdict-was-for"}]}' \
  > "$GH_STUB_DIR/fixture.json"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "a clean verdict on a SUPERSEDED head does not count" "gh pr merge 149 --merge"
write_gh_fixture "stubbed-head" ""
check_agent DENY  "tadeumendonca-skills:quality-assurance" "no comments at all — nothing was ever posted"        "gh pr merge 149 --merge"
# VOCABULARY DRIFT — the exact failure the record's Context section names: three drifted literals shipped
# in one day (ADVISORY-ONLY, CLEAN, APPROVED), none of them the word this brief defines. An unrecognised
# literal must not read as clearance any more than a wrong one does.
write_gh_fixture "stubbed-head" "APPROVED"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "a drifted literal ('APPROVED') is not APPROVE-AND-MERGE" "gh pr merge 149 --merge"
# THE MATCHING CASE, restated explicitly here rather than only inherited from the suite's default
# fixture — so this section proves the ALLOW path too, not only every DENY path.
write_gh_fixture "stubbed-head" "APPROVE-AND-MERGE"
check_agent ALLOW "tadeumendonca-skills:quality-assurance" "own APPROVE-AND-MERGE on the current head is required, and here it is" "gh pr merge 149 --merge"
# SQUASH IS STILL DENIED FIRST, even against a clean verdict — proving the two checks are independent
# rather than the squash rule silently subsumed by this one.
check_agent DENY  "tadeumendonca-skills:quality-assurance" "squash denied even with a clean verdict (independent of 7c)" "gh pr merge 149 --squash"

echo "--- rule 7c, #341: an UNREADABLE verdict denies — one case per cause, never one batch mutation ---"
# ~~FAIL OPEN: no `gh` on PATH at all. This sub-rule must add NOTHING — the merge proceeds exactly as
# it did before 7c existed, per this file's own stated policy at its header (fails open on no network /
# no `gh` / no `jq`).~~ **STRUCK 2026-08-28 (#341, owner: «deveria travar»).** The assertion below is
# the same probe with the opposite expectation, and the strike is kept because the ALLOW it asserted
# was a REAL, deliberate behaviour of this floor for weeks — a reader finding a merge that went through
# on a flaky network needs to see that it was expected, not that the test was always this way.
#
# EVERY CAUSE GETS ITS OWN CASE AND ITS OWN VERDICT LINE, NEVER CHAINED. A batch mutation ("break the
# read somehow") cannot attribute a red: four different repairs sit behind these four causes, and a
# suite that collapses them tells whoever is fixing it nothing about which one moved.
#
# EVERY CASE HOLDS THE FIXTURE AT REQUEST-CHANGES ON PURPOSE. That is the verdict that would deny
# ANYWAY if the read succeeded — so a bug that made these pass for the ordinary reason (the verdict was
# bad) rather than the reason under test (the read was impossible) is invisible here. The
# discrimination is supplied by the CLEARANCE CONTROLS at the end of this block, which run the same
# code path with a readable APPROVE-AND-MERGE and must still ALLOW. Without them, "deny everything"
# would be green.

# CAUSE 1 — `gh` absent from PATH. `jq` is real and still reachable (it lives at /usr/bin/jq, which
# stays on the trimmed PATH; the stub dir is what is dropped), so this isolates the missing CLIENT
# from the missing PARSER — they are different branches with different messages.
write_gh_fixture "stubbed-head" "REQUEST-CHANGES"
NOGH_7C="$(mktemp -d)"
REAL_PATH_7C="$PATH"
PATH="$NOGH_7C:/usr/bin:/bin"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "cause 1 — no gh on PATH: the read cannot happen, so the merge is denied (#341)" "gh pr merge 149 --merge"
PATH="$REAL_PATH_7C"
rm -rf "$NOGH_7C"

# CAUSE 2 — the API call FAILS. `gh` is present and runs; it writes its error to stderr and exits
# non-zero with empty stdout, which is what an expired token, a rate limit or no network all look like
# from inside this hook. The guard cannot distinguish them from each other and does not claim to — its
# message names the whole set.
GHFAIL_7C="$(mktemp -d)"
cat > "$GHFAIL_7C/gh" <<'STUB'
#!/bin/sh
echo "error connecting to api.github.com" >&2
exit 1
STUB
chmod +x "$GHFAIL_7C/gh"
REAL_PATH_7C="$PATH"
PATH="$GHFAIL_7C:$PATH"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "cause 2 — the API call fails (no network / expired auth / rate limit): denied (#341)" "gh pr merge 149 --merge"
PATH="$REAL_PATH_7C"
rm -rf "$GHFAIL_7C"

# CAUSE 3 — the PR REFERENCE RESOLVES TO NOTHING. Distinguished from cause 2 by the stub itself, which
# serves a real payload for PR 149 and nothing for any other ref, exactly as `gh` behaves on a number
# with no pull request behind it. The ALLOW control on 149 through the SAME stub is what proves the
# stub discriminates on the ref rather than simply failing at everything — without it, cause 3's DENY
# would be indistinguishable from a broken stub.
GHREF_7C="$(mktemp -d)"
cat > "$GHREF_7C/gh" <<'STUB'
#!/bin/sh
for a in "$@"; do
  if [ "$a" = "149" ]; then
    printf '%s\n' '{"headRefOid":"h","comments":[{"authorAssociation":"OWNER","body":"<!-- gatekeeper-verdict: quality-assurance -->\nAPPROVE-AND-MERGE\nhead: h"}],"closingIssuesReferences":[]}'
    exit 0
  fi
done
echo "GraphQL: Could not resolve to a PullRequest with the number of 999999." >&2
exit 1
STUB
chmod +x "$GHREF_7C/gh"
REAL_PATH_7C="$PATH"
PATH="$GHREF_7C:$PATH"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "cause 3 — the PR ref resolves to no pull request: denied (#341)" "gh pr merge 999999 --merge"
check_agent ALLOW "tadeumendonca-skills:quality-assurance" "cause 3's control — the SAME stub clears PR 149, so the stub discriminates on the ref" "gh pr merge 149 --merge"
PATH="$REAL_PATH_7C"
rm -rf "$GHREF_7C"

# CAUSE 4 — the response ARRIVES AND CARRIES NO HEAD. `gh` succeeds, the JSON parses, and the
# extraction still yields the empty string, because there is no `headRefOid` to anchor a verdict to.
# This is the arm that used to sit inside `APPROVE-AND-MERGE|APPROVE-AND-MERGE-BOUNDARY|''`, and it is
# the one no PATH mutation can reach — it is only reachable through the PAYLOAD, which is why it is a
# fixture case and not a stub case.
jq -n '{comments:[{authorAssociation:"OWNER", body:"<!-- gatekeeper-verdict: quality-assurance -->\nAPPROVE-AND-MERGE\nhead: h"}]}' \
  > "$GH_STUB_DIR/fixture.json"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "cause 4 — a response with no headRefOid: the empty read no longer reads as clearance (#341)" "gh pr merge 149 --merge"
# THE SAME SHAPE WITH AN EXPLICITLY EMPTY HEAD, not merely an absent key — `.headRefOid // ""` treats
# them alike and this is what says so, so a future extraction that starts distinguishing them cannot
# silently re-open the hole for one of the two.
jq -n '{headRefOid:"", comments:[{authorAssociation:"OWNER", body:"<!-- gatekeeper-verdict: quality-assurance -->\nAPPROVE-AND-MERGE\nhead: h"}]}' \
  > "$GH_STUB_DIR/fixture.json"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "cause 4b — an EMPTY headRefOid denies the same way an absent one does" "gh pr merge 149 --merge"

# THE CLEARANCE CONTROLS — WITHOUT THESE, "DENY EVERYTHING" PASSES EVERY CASE ABOVE. Both authorising
# literals are re-asserted here, through the same code path #341 changed, because the whole risk of
# closing a fail-open is shipping a floor that refuses the merge it was built to permit. They duplicate
# the two ALLOW cases earlier in this section deliberately: those ran BEFORE the empty arm was split
# out, and a control that does not sit next to the mutation is a control nobody re-runs.
write_gh_fixture "stubbed-head" "APPROVE-AND-MERGE"
check_agent ALLOW "tadeumendonca-skills:quality-assurance" "clearance control — a readable APPROVE-AND-MERGE still merges after #341" "gh pr merge 149 --merge"
write_gh_fixture "stubbed-head" "APPROVE-AND-MERGE-BOUNDARY"
check_agent ALLOW "tadeumendonca-skills:quality-assurance" "clearance control — a readable APPROVE-AND-MERGE-BOUNDARY still merges after #341" "gh pr merge 149 --merge"

# THE NAMED, UNFIXED CAUSE — `jq` ABSENT. This asserts the CURRENT, MEASURED behaviour, which is NOT
# what #341 decided, and it is written as an assertion rather than a comment so that it goes RED the
# day somebody fixes it and has to come here and read why.
#
# With `jq` off PATH the guard never reaches rule 7c at all: line ~114 parses `.tool_input.command`
# with `jq` and `exit 0`s on the empty result, so ONE missing `jq` disables the ENTIRE floor — every
# rule, not this arm. `deny()` is itself `jq -n`, so even the refusal could not be printed. That is a
# different failure with a wider blast radius, explicitly excluded from #341's decision by the owner,
# and it is NOT fixed here. It is named in the guard's header and in rule 7c's own comment.
# ── THE ISOLATION IS THE HARD PART, AND THE FIRST VERSION OF IT WAS THE DEFECT ─────────────────────
# ~~`PATH="$NOJQ_7C"`, a directory holding one `gh` symlink, then `check_agent`.~~ **That assertion
# could not fail, and it was caught by the gate on PR #350 rather than by me.** `check_agent` builds
# its payload with `jq -n` and launches the guard with `bash "$GUARD"` — BOTH resolved through the same
# `PATH` the case had just emptied. So `jq` was missing from the HARNESS, not just from the guard; the
# guard was never launched at all; the empty output classified as ALLOW; and the case reported `ok`
# for a reason that had nothing to do with the guard's behaviour. **An assertion whose entire job was
# to announce a future repair was itself the thing that could not observe one.**
#
# THE CORRECT SHAPE, and the two properties it has to have at once:
#   1. the HARNESS keeps the real `jq`/`bash` — the payload is built and the guard is launched
#      normally, outside the mutated environment;
#   2. only the GUARD'S OWN process gets the `jq`-less `PATH`, via `env PATH=… bash "$GUARD"`, with
#      every other external the guard reaches for (`bash`, `cat`, `grep`, `sed`, `awk`, `tr`, `head`,
#      `env`, `git`, `gh`) symlinked in. Removing one tool means removing ONE tool.
#
# AND IT ASSERTS THE EXIT CODE, NOT ONLY THE VERDICT. This is the part that would have caught the
# original defect on its own: a guard that never launched exits **127**, and a guard that launched and
# allowed exits **0** — while both produce empty stdout and both classify as ALLOW. Silence is the
# expected observation here, so silence cannot also be the evidence that anything ran.
NOJQ_7C="$(mktemp -d)"
for t in bash cat grep sed awk tr head env git gh; do
  p="$(command -v "$t" 2>/dev/null || true)"
  [ -n "$p" ] && ln -s "$p" "$NOJQ_7C/$t"
done
[ -e "$NOJQ_7C/jq" ] && echo "BUG: the no-jq fixture contains jq"

# One assertion, two conditions, one verdict line — the guard must have RUN (rc 0, not 127) and must
# have emitted nothing (ALLOW). Chaining them would make a red unattributable, so the failure branch
# prints which of the two moved.
nojq_out="$(jq -n --arg c 'gh pr merge 149 --merge' --arg a 'tadeumendonca-skills:quality-assurance' \
  '{tool_input:{command:$c}, agent_type:$a}' | env PATH="$NOJQ_7C" bash "$GUARD" 2>/dev/null)"
nojq_rc=$?
nojq_verdict="$(verdict "$nojq_out")"
if [ "$nojq_rc" = "0" ] && [ "$nojq_verdict" = "ALLOW" ]; then
  pass=$((pass + 1))
  printf 'ok    %-6s %s\n' "ALLOW" "NAMED GAP, not #341's fix: no jq disables the WHOLE floor at line ~114 (guard RAN, rc=0, emitted nothing)"
else
  fail=$((fail + 1))
  printf 'FAIL  want=ALLOW/rc0 got=%s/rc%s  %s\n' "$nojq_verdict" "$nojq_rc" \
    "NAMED GAP: either the floor now denies on a missing jq (good — come read this comment and retire the case) or the guard never launched (rc=127 means the isolation is broken again)"
fi
rm -rf "$NOJQ_7C"

write_gh_fixture "stubbed-head" "APPROVE-AND-MERGE"

# THE PR REF AND --repo/-R VALUE ARE ACTUALLY PARSED OUT OF THE COMMAND, not assumed — an
# arg-logging stub replaces the fixture-serving one just for this check, so the assertion is on
# what 7c ASKED FOR rather than on what a fixture happened to return regardless of the ask.
GH_LOG="$GH_STUB_DIR/args.log"
cat > "$GH_STUB_DIR/gh" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "__GH_LOG__"
if [ "$1 $2" = "pr view" ]; then
  printf '{"headRefOid":"h","comments":[]}\n'
fi
exit 0
STUB
sed -i.bak "s#__GH_LOG__#$GH_LOG#" "$GH_STUB_DIR/gh"
rm -f "$GH_STUB_DIR/gh.bak"
chmod +x "$GH_STUB_DIR/gh"

assert_gh_call() { # description · expected-args-line · command
  rm -f "$GH_LOG"
  jq -n --arg c "$3" --arg a "tadeumendonca-skills:quality-assurance" \
    '{tool_input:{command:$c}, agent_type:$a}' | bash "$GUARD" >/dev/null 2>&1
  got="$(cat "$GH_LOG" 2>/dev/null || true)"
  if [ "$got" = "$2" ]; then
    pass=$((pass + 1)); printf 'ok    ARGS   %s\n' "$1"
  else
    fail=$((fail + 1)); printf 'FAIL  ARGS   %s\n      want: %s\n      got:  %s\n' "$1" "$2" "${got:-<none>}"
  fi
}
assert_gh_call "explicit numeric ref, no --repo"        "pr view 149 --json headRefOid,comments,closingIssuesReferences"                "gh pr merge 149 --merge"
assert_gh_call "no ref: falls to current-branch PR"     "pr view --json headRefOid,comments,closingIssuesReferences"                    "gh pr merge --merge"
assert_gh_call "--repo, space form"                      "pr view 149 --repo owner/repo --json headRefOid,comments,closingIssuesReferences" "gh --repo owner/repo pr merge 149 --merge"
assert_gh_call "-R, space form"                          "pr view 149 --repo owner/repo --json headRefOid,comments,closingIssuesReferences" "gh -R owner/repo pr merge 149 --merge"
assert_gh_call "--repo=, no space"                       "pr view 149 --repo owner/repo --json headRefOid,comments,closingIssuesReferences" "gh --repo=owner/repo pr merge 149 --merge"

# ── FLAG POSITION MUST NOT MATTER (2026-08-23) ──────────────────────────────────────────────────────────
# The five cases above all put the flag BEFORE the subcommand, and the extractor they were written
# against was anchored to exactly that (`^gh <flag> <value> pr merge`). The spelling this platform's
# own `shell` skill MANDATES — "Target another repo with `gh <subcommand> --repo
# <owner/repo>`, never `gh -R <owner/repo> <subcommand>`" — is the one it could not parse, so `qa_repo`
# came out EMPTY and 7c read whatever repo the cwd resolved to. Measured before the fix, with this
# same arg-logging stub: `gh pr merge 479 --repo owner/repo` logged `pr view 479 --json …` — no
# `--repo` at all.
#
# THE ATTACHED PRE-SUBCOMMAND FORM (`-Rowner/repo`) IS HERE TOO, and it is not a bonus: the old
# extractor required at least one separator character (`[[:space:]=]+`), so a spelling `gh` accepts
# and rule 7b's own matcher already recognised fell through the extraction below it. Same defect,
# same rule, opposite side of the subcommand.
assert_gh_call "--repo AFTER the subcommand (the mandated spelling)" "pr view 149 --repo owner/repo --json headRefOid,comments,closingIssuesReferences" "gh pr merge 149 --repo owner/repo"
assert_gh_call "-R AFTER the subcommand"                 "pr view 149 --repo owner/repo --json headRefOid,comments,closingIssuesReferences" "gh pr merge 149 -R owner/repo"
assert_gh_call "--repo= AFTER the subcommand"            "pr view 149 --repo owner/repo --json headRefOid,comments,closingIssuesReferences" "gh pr merge 149 --repo=owner/repo"
assert_gh_call "-R attached, AFTER the subcommand"       "pr view 149 --repo owner/repo --json headRefOid,comments,closingIssuesReferences" "gh pr merge 149 -Rowner/repo"
assert_gh_call "-R attached, BEFORE the subcommand"      "pr view 149 --repo owner/repo --json headRefOid,comments,closingIssuesReferences" "gh -Rowner/repo pr merge 149 --merge"
assert_gh_call "-R= attached, BEFORE the subcommand"     "pr view 149 --repo owner/repo --json headRefOid,comments,closingIssuesReferences" "gh -R=owner/repo pr merge 149 --merge"
# THE REF SURVIVES A REPO FLAG PLACED BEFORE IT. Now that the flag may legally follow the subcommand,
# `--repo` would otherwise be handed to the ref extractor, which drops any token starting with `-` and
# falls back to the CURRENT BRANCH's PR — a different PR, read with a straight face. The guard strips
# the flag/value pair before reading the ref; this is what says so.
assert_gh_call "repo flag between 'merge' and the ref"   "pr view 149 --repo owner/repo --json headRefOid,comments,closingIssuesReferences" "gh pr merge --repo owner/repo 149 --merge"
# AND THE WINNING SPELLINGS STILL WIN — the five cases above this block are unchanged and still run.
# Restated here only because a fix that quietly traded one position for the other would look identical
# in a suite that only ever asserted the new one.
assert_gh_call "no repo flag at all still infers from cwd" "pr view 149 --json headRefOid,comments,closingIssuesReferences"  "gh pr merge 149 --merge"

# ── AND THE DENY ACTUALLY FIRES THROUGH THE PREVIOUSLY-LOSING SPELLING ────────────────────────────
# THIS IS THE ASSERTION THE SECTION EXISTED WITHOUT. Everything above proves what 7c *asked gh for*;
# nothing proved that a stale or missing verdict, reached through the mandated spelling, still DENIES.
# It could not have: the suite-wide stub serves its fixture regardless of which repo was asked for, so
# a DENY case written against it would have passed on the broken extractor too — the fixture would
# have been served either way. That is a test that cannot fail, this workspace's own recurring defect.
#
# SO THE STUB HERE IS REPO-AWARE, and the two fixtures are chosen so the two failure directions are
# distinguishable:
#   asked WITH --repo owner/repo -> REQUEST-CHANGES  (the real PR's real verdict)   -> must DENY
#   asked WITHOUT it             -> APPROVE-AND-MERGE (the cwd repo's unrelated PR) -> would ALLOW
# Mutate the extractor back to the `^gh …` anchor and these go RED, for the right reason: the guard
# read the wrong repo and cleared the merge on somebody else's verdict.
cat > "$GH_STUB_DIR/gh" <<'STUB'
#!/bin/sh
d="$(dirname "$0")"
prev=""; want=""
for a in "$@"; do
  [ "$prev" = "--repo" ] && want="$a"
  prev="$a"
done
if [ "$1 $2" = "pr view" ]; then
  if [ "$want" = "owner/repo" ]; then cat "$d/fixture.json"; else cat "$d/fixture-cwd.json"; fi
fi
exit 0
STUB
chmod +x "$GH_STUB_DIR/gh"
jq -n '{headRefOid:"h", comments:[{authorAssociation:"OWNER", body:"<!-- gatekeeper-verdict: quality-assurance -->\nREQUEST-CHANGES\nhead: h"}]}' \
  > "$GH_STUB_DIR/fixture.json"
jq -n '{headRefOid:"h", comments:[{authorAssociation:"OWNER", body:"<!-- gatekeeper-verdict: quality-assurance -->\nAPPROVE-AND-MERGE\nhead: h"}], closingIssuesReferences:[]}' \
  > "$GH_STUB_DIR/fixture-cwd.json"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "REQUEST-CHANGES denies through '--repo' AFTER the subcommand — the mandated spelling" "gh pr merge 149 --repo owner/repo --merge"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "REQUEST-CHANGES denies through '-R' after the subcommand"                             "gh pr merge 149 -R owner/repo --merge"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "REQUEST-CHANGES denies through '--repo=' after the subcommand"                        "gh pr merge 149 --repo=owner/repo --merge"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "REQUEST-CHANGES denies through '-R' attached, before the subcommand"                  "gh -Rowner/repo pr merge 149 --merge"
# THE CONTROL FOR THE FOUR ABOVE. Same stub, same repo-aware fixtures, the spelling that ALREADY
# worked — so a fix that merely made every path deny (by, say, dropping the repo argument entirely)
# is not what turned them green. And the negative control: no repo flag at all reads the cwd repo's
# clean verdict and ALLOWs, which is what proves the stub is actually discriminating on the argument
# rather than serving one fixture to everybody.
check_agent DENY  "tadeumendonca-skills:quality-assurance" "REQUEST-CHANGES still denies through '--repo' BEFORE the subcommand"                  "gh --repo owner/repo pr merge 149 --merge"
check_agent ALLOW "tadeumendonca-skills:quality-assurance" "no repo flag: the cwd repo's own clean verdict clears it (the stub discriminates)"    "gh pr merge 149 --merge"
# A MISSING verdict through the mandated spelling, not only a stale one — the 'none' arm of the same
# rule, which is what a PR that was never reviewed at all looks like.
jq -n '{headRefOid:"h", comments:[]}' > "$GH_STUB_DIR/fixture.json"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "NO verdict at all denies through the mandated spelling too" "gh pr merge 149 --repo owner/repo --merge"
rm -f "$GH_STUB_DIR/fixture-cwd.json"

# Restore the fixture-serving stub and the suite-wide default clean fixture for every case below
# that still expects the reviewer's identity alone to be sufficient (relies on the default fixture).
cat > "$GH_STUB_DIR/gh" <<'STUB'
#!/bin/sh
if [ "$1 $2" = "pr view" ]; then
  cat "$(dirname "$0")/fixture.json" 2>/dev/null
fi
exit 0
STUB
chmod +x "$GH_STUB_DIR/gh"
write_gh_fixture "stubbed-head" "APPROVE-AND-MERGE"

echo "--- rule 7d (#363): the merge must not close an Issue the verdict never declared ---"
# EVERY CASE HERE RUNS BEHIND A CLEAN, CURRENT-HEAD APPROVE-AND-MERGE, so 7c is satisfied in all of
# them and any DENY below is 7d's alone. That is the whole design of this block: a case that also
# tripped 7c would prove nothing about the rule it is named after.
#
# THE FIRST CASE IS THE LIVE INSTANCE, not a synthesised one. PR #356 carried `close #355` in its body
# — inside the sentence explaining why the keyword must not be used — its `closingIssuesReferences`
# returns `[355]` at head today, and the merge-authorising verdict on the merged head mentions `#355`
# in prose without declaring it.
write_gh_fixture "stubbed-head" "APPROVE-AND-MERGE" "355" ""
check_agent DENY  "tadeumendonca-skills:quality-assurance" "the live instance: the forge would close #355 and the verdict declares nothing" "gh pr merge 149 --merge"

# THE DECLARATION IS THE EXIT, and this is the case that prices the false positive. A PR that
# legitimately closes a delivered Issue is the COMMON case; if it could not merge, this rule would be
# one people route around, which this repository has measured twice is worse than none.
write_gh_fixture "stubbed-head" "APPROVE-AND-MERGE" "355" "355"
check_agent ALLOW "tadeumendonca-skills:quality-assurance" "a declared close merges — 'closes: 355' at column 0 in the verdict" "gh pr merge 149 --merge"

# THE NEGATIVE CONTROL FOR THE ABOVE. Without it, a rule that simply never denied would pass the
# ALLOW case, and a rule that always denied would pass the DENY case; only the pair distinguishes them.
write_gh_fixture "stubbed-head" "APPROVE-AND-MERGE" "355 337" "355"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "a PARTIAL declaration still denies — #337 is closed and undeclared" "gh pr merge 149 --merge"
write_gh_fixture "stubbed-head" "APPROVE-AND-MERGE" "355 337" "355 337"
check_agent ALLOW "tadeumendonca-skills:quality-assurance" "both declared, both closed: merges" "gh pr merge 149 --merge"

# A DECLARATION WIDER THAN THE CLOSE IS FINE. The comparison is one-directional by design — the forge's
# set must be inside the verdict's, never equal to it — because a gate that reviewed two Issues and a PR
# that closes one is a correct state, and denying it would teach the gate to declare narrowly.
write_gh_fixture "stubbed-head" "APPROVE-AND-MERGE" "355" "355 337"
check_agent ALLOW "tadeumendonca-skills:quality-assurance" "the verdict may declare MORE than the PR closes" "gh pr merge 149 --merge"

# A PR THAT CLOSES NOTHING NEVER REACHES THE COMPARISON — the overwhelmingly common shape in this repo,
# and it must cost the gate nothing.
#
# THIS ONE IS A CONTROL, NOT AN INDEPENDENT ASSERTION, AND IT IS LABELLED SO RATHER THAN COUNTED AS ONE.
# No mutation of 7d turns it red on its own: every source mutation tried against this block either
# leaves it green or reddens it only together with the live-instance case above. Its value is the PAIR
# — same fixture, same verdict, ONE variable different (the forge's closing set) and opposite outcomes —
# which is what says the rule discriminates on that set rather than on anything else in the payload.
write_gh_fixture "stubbed-head" "APPROVE-AND-MERGE" "" ""
check_agent ALLOW "tadeumendonca-skills:quality-assurance" "an empty closing set is not a finding" "gh pr merge 149 --merge"

# THE MEASUREMENT THAT KILLED THE OBVIOUS DESIGN, PINNED AS AN ASSERTION. Both verdicts on the real
# #356 contain the string `#355` — the merge-authorising one included, because it is the verdict that
# PRESCRIBED removing the keyword. A prose-mention check would have passed the exact case it exists to
# refuse, so the anchor is `^closes:` at column 0 and this case is what holds it there.
write_gh_fixture "stubbed-head" "APPROVE-AND-MERGE" "355" ""
jq --arg extra 'The Closes #355 in the body must become Refs #355 before this merges.' \
  '.comments[0].body = (.comments[0].body + "\n\n" + $extra)' \
  "$GH_STUB_DIR/fixture.json" > "$GH_STUB_DIR/fixture.tmp"
mv "$GH_STUB_DIR/fixture.tmp" "$GH_STUB_DIR/fixture.json"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "a verdict that MENTIONS #355 in prose has not declared it" "gh pr merge 149 --merge"

# THE DECLARATION IS POSITIONAL. `closes:` inside a wrapped sentence is prose, and this is the case
# that says the difference is column 0 and not the token — the same contract `purpose:` carries in
# this tree, for the same reason.
write_gh_fixture "stubbed-head" "APPROVE-AND-MERGE" "355" ""
jq --arg extra 'The rule is that it closes: 355 only when delivery was verified.' \
  '.comments[0].body = (.comments[0].body + "\n\n" + $extra)' \
  "$GH_STUB_DIR/fixture.json" > "$GH_STUB_DIR/fixture.tmp"
mv "$GH_STUB_DIR/fixture.tmp" "$GH_STUB_DIR/fixture.json"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "an indented/mid-sentence 'closes:' is prose, not a declaration" "gh pr merge 149 --merge"

# THE DECLARATION IS HEAD-SCOPED, because it rides in the verdict and the verdict already is. TWO
# comments, and the pair is what makes this assertion capable of failing at all: a STALE verdict at an
# old head declaring `closes: 355`, and the CURRENT verdict at the current head declaring nothing. 7c
# is satisfied — the current verdict is APPROVE-AND-MERGE against the current head — so the only thing
# that can deny here is 7d, and it denies only if it reads the comment 7c selected rather than any
# comment carrying the marker.
#
# THE ONE-COMMENT FORM OF THIS CASE WAS WRITTEN FIRST AND WAS AN ASSERTION THAT COULD NOT FAIL: a
# single stale verdict makes 7c deny on its own, so the case went green with 7d disabled entirely.
# Found by mutation, not by reading — which is this workspace's own standing finding about assertions.
jq -n '{headRefOid:"new-head", closingIssuesReferences:[{number:355}],
        comments:[{authorAssociation:"OWNER", body:"<!-- gatekeeper-verdict: quality-assurance -->\nAPPROVE-AND-MERGE\nhead: old-head\ncloses: 355"},
                  {authorAssociation:"OWNER", body:"<!-- gatekeeper-verdict: quality-assurance -->\nAPPROVE-AND-MERGE\nhead: new-head"}]}' \
  > "$GH_STUB_DIR/fixture.json"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "a declaration on a MOVED head clears nothing — the current verdict declares none" "gh pr merge 149 --merge"

# THE FAIL-CLOSED BRANCH. A payload with no `closingIssuesReferences` key at all means the read that
# would have decided did not happen — 7c's own criterion, one field wider. It is defensive rather than
# reachable through a real `gh` (which errors on an unknown --json field, landing on 7c's deny
# instead), and it is written and asserted anyway so a future edit that drops the field from the query
# wedges loudly rather than silently disarming this rule.
jq -n '{headRefOid:"h", comments:[{authorAssociation:"OWNER", body:"<!-- gatekeeper-verdict: quality-assurance -->\nAPPROVE-AND-MERGE\nhead: h"}]}' \
  > "$GH_STUB_DIR/fixture.json"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "no closingIssuesReferences key: the merge floor denies rather than passing" "gh pr merge 149 --merge"

# 7d NEVER REACHES A CALLER 7b ALREADY REFUSED, and never widens what 7c denies. Both re-asserted
# against a fixture that WOULD trip 7d, so a green here cannot come from the closing set being clean.
write_gh_fixture "stubbed-head" "APPROVE-AND-MERGE" "355" ""
check_agent DENY  "tadeumendonca-skills:developer" "7b still refuses a non-gate caller before 7d is ever consulted" "gh pr merge 149 --merge"
write_gh_fixture "stubbed-head" "REQUEST-CHANGES" "355" "355"
check_agent DENY  "tadeumendonca-skills:quality-assurance" "7c still denies a bad verdict even when the close IS declared" "gh pr merge 149 --merge"

write_gh_fixture "stubbed-head" "APPROVE-AND-MERGE"

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
# `security` stood here until 2026-08-04 and was absorbed into `quality-assurance`. A case whose
# agent_type names a persona that does not exist still PASSES — 5c denies every non-`developer`
# subagent, including a nonexistent one — which is exactly the shape this suite refuses elsewhere: an
# assertion that cannot distinguish the rule holding from the subject being gone. Re-pointed at a
# persona that exists, and deliberately at a NON-gate one, so the "not only reviewers" half is still
# covered now that there is a single reviewer.
check_agent DENY  "tadeumendonca-skills:agents-lead"  "an advisory lens cannot file"      "gh issue create --title t --body 'Parent: #122'"
# EVERY REPO-FLAG SPELLING, because this rule's own flag class was a SPELLING BEHIND the shared one
# (2026-08-23): it read `-R[[:space:]]*` where `gh_repo_flag` reads `-R[[:space:]=]*`. The `-R <space>`
# form was the only one ever covered here (see the developer ALLOW case above); these are the four
# that were not.
#
# THESE FOUR DO NOT GO RED ON THE DRIFTED CLASS, AND THE COMMENT SAYS SO RATHER THAN IMPLYING
# OTHERWISE. The diff that added them claimed the drift was a live fail-open — `gh -R=owner/x issue
# create` slipping past the gate. Mutating the class back left all four GREEN, and a direct probe over
# all six spellings showed why: this rule MATCHES with the class inside an optional group followed by
# a greedy `[^[:space:]]+`, so `-R` matches, `[[:space:]]*` matches empty, and the value class eats
# `=owner/x` whole. Nothing was open. The claim was written from the shape of the defect in rule 7c
# instead of from a measurement.
#
# THEY ARE KEPT ANYWAY, on their own merit rather than the retracted one: this rule's spelling
# coverage was genuinely untested beyond `-R <space>`, and these pin it. What guards the class itself
# is `inventory-counts.test.sh`'s intra-file arm, which DID redden on that mutation — the right layer
# for a defect that is latent in this position and a fail-open in an extracting one.
check_agent DENY  "tadeumendonca-skills:agents-lead"  "…behind -R=, the spelling that used to slip past" "gh -R=owner/repo issue create --title t --body b"
check_agent DENY  "tadeumendonca-skills:agents-lead"  "…behind -R attached"                              "gh -Rowner/repo issue create --title t --body b"
check_agent DENY  "tadeumendonca-skills:agents-lead"  "…behind --repo="                                  "gh --repo=owner/repo issue create --title t --body b"
check_agent DENY  "tadeumendonca-skills:agents-lead"  "…behind --repo, space form"                       "gh --repo owner/repo issue create --title t --body b"
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
#
#   RE-POINTED 2026-09-05 (#383 S2). It used to compose with `;`, which was rule 8's chain branch;
#   that branch is gone and the payload now falls through, so the case would have gone green for the
#   wrong reason. It is re-pointed at rule 8b (redirection), which is the LAST rule in the file and
#   therefore the strictest fall-through witness available — stricter than the chain branch was.
check_agent DENY  "tadeumendonca-skills:developer" "allow does not unreach rule 8b (redirect)" "gh issue create --title t --body b > out.txt"

# THE SAME THREE FOR THE MAIN AGENT, added 2026-08-03 with the change that made them necessary. The
# main agent now takes the same fall-through path `developer` does, so it inherits the same failure
# mode: an `exit 0` or a `return` where the ASK used to be would unreach rules 7, 7b and 8 for the
# MOST common caller in the loop, and the developer-only trio above would still pass green. Six cases,
# not three, is the whole reason this change is safe to make.
check_agent DENY  "" "main agent: allow does not unreach rule 7 (trunk push)"  "gh issue create --title t --body b && git push origin main"
check_agent DENY  "" "main agent: allow does not unreach rule 7b (merge)"      "gh issue create --title t --body b && gh pr merge 1 --merge"
check_agent DENY  "" "main agent: allow does not unreach rule 8b (redirect)" "gh issue create --title t --body b > out.txt"

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
out=$(jq -n --arg c "gh issue create --title t --body b" '{tool_input:{command:$c}, agent_type:"tadeumendonca-skills:agents-lead"}' | agent_type="tadeumendonca-skills:developer" bash "$GUARD")
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
check DENY  "read does not unreach rule 8b" "gh api repos/o/r/releases/latest > out.txt"

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

echo "--- rule 5e: the content pair is contained the same way, and for the same reason (#187, #317) ---"
# `content-writer` reads `.brand/` to draft, exactly the shape `product-lead` was denied for — inverted
# from a denylist to an allowlist at #187 specifically so a new private-material-reading persona defaults
# to DENY rather than needing to be remembered.
check_agent DENY "tadeumendonca-skills:content-writer" "pr comment"       "gh pr comment 149 --body 'draft text'"
check_agent DENY "tadeumendonca-skills:content-writer" "issue comment"    "gh issue comment 149 --body 'draft text'"
check_agent DENY "tadeumendonca-skills:content-writer" "issue create"     "gh issue create --title x --body y"
# Drafting itself is untouched — its route is Write/Edit onto tracked files, not this rule's concern.
check_agent ALLOW "tadeumendonca-skills:content-writer" "listing PRs"     "gh pr list --state open"
check_agent ALLOW "tadeumendonca-skills:content-writer" "viewing an issue" "gh issue view 173"
# THE OLD NAME MUST NOT STILL CLEAR THE RULE, and this is the case a rename is most likely to leave
# behind: `*:writer` was a live case arm until #317. It now falls to the `*)` catch-all, which denies —
# so both the old and the new spelling deny, and this assertion cannot tell them apart on the verdict
# alone. It is kept anyway, because the failure it guards is the OPPOSITE direction: someone restoring
# an `*:writer)` arm, or a matcher written loosely enough that `content-writer` and `writer` are one
# case. A same-verdict assertion is weak; a missing one is nothing.
check_agent DENY "tadeumendonca-skills:writer" "the RETIRED name still denies (catch-all)" "gh pr comment 149 --body x"
# `content-reviewer` (#317) reads the same private layer to judge a draft against it, and is named in the
# rule explicitly rather than reaching the catch-all — so this is a decision under test, not a default.
check_agent DENY "tadeumendonca-skills:content-reviewer" "pr comment"       "gh pr comment 149 --body 'round 1'"
check_agent DENY "tadeumendonca-skills:content-reviewer" "issue comment"    "gh issue comment 149 --body 'round 1'"
check_agent DENY "tadeumendonca-skills:content-reviewer" "issue create"     "gh issue create --title x --body y"
# Reading the queue is untouched for it too — the round file is written with Write/Edit, and reading the
# PR it belongs to must not be collateral of the posting deny.
check_agent ALLOW "tadeumendonca-skills:content-reviewer" "listing PRs"     "gh pr list --state open"
check_agent ALLOW "tadeumendonca-skills:content-reviewer" "viewing an issue" "gh issue view 173"
check_agent ALLOW "tadeumendonca-skills:content-reviewer" "diffing a PR"     "gh pr diff 149"

echo "--- rule 5e: scrum-master denies BY DECISION, not by omission (#375) ---"
# The three cases below would pass with the `*:scrum-master)` arm DELETED — the catch-all denies too —
# so on their own they assert nothing about the arm. They are kept for the same reason the retired
# `writer` case above is: a same-verdict assertion is weak, a missing one is nothing.
check_agent DENY "tadeumendonca-skills:scrum-master" "pr comment"    "gh pr comment 149 --body x"
check_agent DENY "tadeumendonca-skills:scrum-master" "issue comment" "gh issue comment 149 --body x"
check_agent DENY "tadeumendonca-skills:scrum-master" "issue create"  "gh issue create --title x --body y"
# THIS is the arm's falsifier, and it asserts the TEXT rather than the verdict, because the verdict is
# identical either way. Rule 5e's own comment states the property under test: "a deny by omission and a
# deny by decision are the same behaviour and different facts, and only one of them survives someone
# later reading the rule". A behavioural assertion cannot tell those two apart by construction — so the
# only thing that can redden on the arm's removal is the message. Deleting the arm falls through to the
# catch-all, whose text carries "New personas default to DENY here" and does NOT carry the literal
# below, and this case goes red naming the persona.
sm_out=$(jq -n --arg c "gh pr comment 149 --body x" --arg a "tadeumendonca-skills:scrum-master" \
  '{tool_input:{command:$c}, agent_type:$a}' | bash "$GUARD")
if printf '%s' "$sm_out" | grep -qF 'This deny is BY DECISION, not by omission'; then
  pass=$((pass + 1)); printf 'ok    %-6s %s\n' "DENY" "scrum-master's deny is its own, not the catch-all's"
else
  fail=$((fail + 1)); printf 'FAIL  want=DENY-by-decision  scrum-master reached the catch-all (or its message changed)\n      got: %s\n' "$sm_out"
fi
# The complement, so the pair cannot both be satisfied by a message that says everything: the by-name
# deny must NOT carry the catch-all's own sentence. Without this, widening the catch-all's text to
# include the literal above would keep the case above green with the arm gone.
if printf '%s' "$sm_out" | grep -qF 'New personas default to DENY here'; then
  fail=$((fail + 1)); printf 'FAIL  scrum-master got the CATCH-ALL message, so its by-name arm is not being reached\n'
else
  pass=$((pass + 1)); printf 'ok    %-6s %s\n' "DENY" "scrum-master does not receive the catch-all's 'new personas default' text"
fi
# No ALLOW cases here, deliberately, unlike `content-reviewer`'s: that persona reads the queue as part
# of its work, and this one declares `tools: []` — it holds no `Bash` at all, so a read is as impossible
# as a post. Asserting ALLOW on `gh pr list` for it would document a capability it does not have.

echo "--- rule 5e: an unlisted persona defaults to DENY, not ALLOW (#187, ADR-0004) ---"
# The falsifier the inversion exists to satisfy: a persona nobody remembered to add to the allow side
# must NOT post by default. Before #187 this fell through ALLOW for anything not literally named
# `product-lead` — the exact "absent is not a state" shape ADR-0004's own section records for the AWS
# floor (record 0018 until 2026-08-20, absorbed there), now closed here too.
check_agent DENY "tadeumendonca-skills:some-future-persona" "unlisted persona, pr comment" "gh pr comment 149 --body b"
check_agent DENY "tadeumendonca-skills:some-future-persona" "unlisted persona, issue create" "gh issue create --title x --body y"

echo "--- rule 5e: the gatekeeper protocol must keep running ---"
# The gatekeeper comments its verdict on every MR. A rule that matched by SUBCOMMAND rather than by
# agent would take out the protocol this whole loop runs on, and would do it silently — the verdicts
# would simply stop arriving. These are the cases that fail if 5e's allowlist ever drops an entry it
# needs.
#
# THE SECOND GATEKEEPER'S CASES ARE NOT DELETED, THEY ARE RE-POINTED. `security` was absorbed into
# `quality-assurance` on 2026-08-04, and the property those two lines held was never about that
# persona: it is that 5e's allowlist covers every persona that legitimately posts as part of its normal
# work. Dropping them would leave the reviewer as the only allowed persona under test, so a narrowing
# of 5e's allowlist would pass. `agents-lead` keeps that half alive.
check_agent ALLOW "tadeumendonca-skills:quality-assurance" "the reviewer comments its verdict" "gh pr comment 149 --body-file /tmp/verdict.md"
check_agent ALLOW "tadeumendonca-skills:quality-assurance" "the reviewer comments on an issue" "gh issue comment 173 --body b"
check_agent ALLOW "tadeumendonca-skills:agents-lead"  "the harness lens comments too"     "gh pr comment 149 --body-file /tmp/verdict.md"
check_agent ALLOW "tadeumendonca-skills:agents-lead"  "the harness lens comments on an issue" "gh issue comment 173 --body b"
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
check_agent DENY "" "allow does not unreach rule 8b (redirect)" "gh pr comment 1 --body b > out.txt"
check_agent DENY "tadeumendonca-skills:quality-assurance" "reviewer: still reaches rule 7"  "gh pr comment 1 --body b && git push origin main"
check_agent DENY "tadeumendonca-skills:agents-lead"  "harness lens: still reaches rule 8b" "gh issue comment 1 --body b > out.txt"

echo "--- rule 8: the two branches that were MEASURED to stop for a human ---"
# #383 S2. The chain branch is gone (see the block below); these two survive because a nested session
# carrying this guard MINUS rules 8/8b reported, verbatim, "What required approval: Contains
# command_substitution" for the first pair, and named the allowlisted command itself for the third —
# an env-var prefix defeats the allow entry, which is a different mechanism from decomposition and
# the reason the rule's premise was rewritten rather than merely re-cited.
check DENY  "command substitution"          'echo $(date)'
check DENY  "backticks"                     'echo `date`'
check DENY  "env-var prefix"                "E2E_ENV=local npx playwright test"

echo "--- rule 8's chain branch is REMOVED (#383 S2) — a chain now falls through ---"
# Measured with the rule absent, verdicts confirmed on disk rather than from a model's report:
# two allowlisted commands joined by '&&' or ';' EXECUTED with no prompt, and a chain carrying a
# denied or unlisted element was denied by the permission system, which named the offending element.
# So the deny converted work into a retry rather than a prompt into an instruction.
check ALLOW "cd compound"                   "cd /tmp && ls"
check ALLOW "&& chain"                      "git status && git diff"
check ALLOW "; chain"                       "ls; pwd"
check ALLOW "|| chain"                      "ls /nope || pwd"
# AND THE HALF THAT MUST NOT HAVE CHANGED: every rule in the guard matches a SUBSTRING of $bare, so
# hiding a denied act behind a harmless first element does not walk past it. These are the regression
# that makes the removal safe; each was measured DENY against the edited guard before being written.
check DENY  "chain does not hide the merge gate"  "echo hi && gh pr merge 1 --merge"
check DENY  "chain does not hide rm -rf"          "echo hi && rm -rf /tmp/zz"
check DENY  "chain does not hide the trunk push"  "echo hi ; git push origin main"
check DENY  "chain does not hide terraform apply" "echo hi && terraform apply"

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
check ALLOW "escaped quote inside singles"        "git commit -m 'it\\'s \$(fine)'"
# ~~check ALLOW "operator between escaped quotes" 'gh pr comment 1 --body "both \"a && b\" hold"'~~
# RETIRED 2026-09-05 (#383 S2), not re-pointed. Its subject was the chain branch, and with that branch
# gone the payload is ALLOW under every possible state of the quote collapse — an assertion that
# cannot fail, which this workspace treats as a defect rather than as coverage. The two cases above it
# carry the same #66 property with a witness that is still live.

# The three cases the issue feared this fix would break. A false NEGATIVE here is far worse
# than the false positive above, so they are asserted rather than reasoned about.
# RE-POINTED 2026-09-05 (#383 S2) from '&& npx tsc' to '$(date)': the property under test is that a
# REAL operator outside the quoted spans still reaches rule 8, and the operator that still has a
# branch is command substitution. Each was re-verified by reverting the collapse and watching it go red.
check DENY  "operator OUTSIDE quotes still caught"    'git commit -m "msg" $(date)'
check DENY  "unbalanced quote fails CLOSED"           'echo "unterminated $(date)'
check DENY  "escaped-quote span then a REAL operator" 'gh pr comment 1 --body "said \"hi\"" $(date)'

echo "--- rule 8b: shell redirection ('>'/'>>') to create or overwrite a file ---"
# #244 — measured 2026-08-13 that a redirect to a NEW file path prompts regardless of destination or
# whether the command itself is allowlisted. The remedy is Write (composed content) or running the
# command without the redirect and Write-ing its returned stdout (captured content) — never '>'.
check DENY  "plain redirect creates a file"        "git show abc123 > file.txt"
check DENY  "append redirect"                      "echo hi >> file.txt"
check DENY  "redirect into a scratch path"         "python3 hooks/scripts/skills-table.py > .scratch/out.txt"
check DENY  "heredoc feeding a redirect"            'cat > file.txt <<EOF
hello
EOF'
check DENY  "both streams to a file (&>)"          "echo hi &> file.txt"
check DENY  "both streams, append (&>>)"           "echo hi &>> file.txt"
# Excluded BY DESIGN: fd-to-fd duplication creates no file. The '&' sits AFTER the '>' here, which is
# what distinguishes it from '&>' above (where '&' precedes '>' and the target is still a path).
check ALLOW "stderr merged into stdout (2>&1)"     "echo hi 2>&1"
check ALLOW "stdout merged into stderr (1>&2)"     "echo hi 1>&2"
check ALLOW "bare fd dup (>&2)"                    "echo hi >&2"
check ALLOW "an ordinary read-only command"        "gh pr view 243 --json state"
check ALLOW "no redirect at all"                   "git status"
# ~~A known, accepted false positive … check DENY "false positive: [[ ]] string compare, documented"~~
# FIXED 2026-09-05 (#383 S2) rather than documented. Measured with this rule absent: the runtime ran
# `[[ zzz > aaa ]]` with no prompt at all, so the deny was pure over-block with no control behind it.
# A '[[ … ]]' span is now stripped before the redirect test — an ABSTENTION, not a claim: this file
# still does not parse shell, and it hands the case to the layer that does.
check ALLOW "[[ ]] string compare is not a redirect (#383)" '[[ "a" > "b" ]]'
# The other measured false positive, and the sharper one: the runtime's own check is DESTINATION-aware.
# It ran `2>/dev/null` and `>/dev/null` with no prompt and required approval for `2>somefile` — so a
# '/dev/null' target creates nothing and this rule must not fire on it. All four verdicts below were
# taken from the rule-8-less session before the exemption was written.
check ALLOW "stderr to /dev/null creates no file"  "grep -r foo /Users/x 2>/dev/null"
check ALLOW "stdout to /dev/null creates no file"  "npm test >/dev/null"
check ALLOW "both streams to /dev/null"            "npm test &>/dev/null"
check DENY  "stderr to a REAL file still creates one" "npm test 2> err.txt"
# Both strips were too loose on the round they landed. Re-measured against the runtime on build
# 2.1.261 with this hook absent: `date > /dev/nullx` and `echo x [[ a > P ]] b` BOTH required approval
# (the second is a real redirect in bash — confirmed by execution, the file appears), so neither
# looseness was a route to an act. It cost the conversion this rule exists for, and that is what these
# four arms hold. The last two are the OVER-block guard: the runtime ran both with no prompt, so a
# '[[ … ]]' in COMMAND position must stay stripped while one in ARGUMENT position must not.
check DENY  "a /dev/null PREFIX is not /dev/null (#383)"    "date > /dev/nullx"
check DENY  "[[ ]] in argument position IS a redirect (#383)" "echo hello [[ a > /tmp/evil ]] b"
check ALLOW "[[ ]] after a test keyword still strips (#383)"  "if [[ zzz > aaa ]]; then echo yes; fi"
check ALLOW "[[ ]] after a separator still strips (#383)"     "echo x; [[ a > b ]]"
# THE RIGHT-ANCHOR OVER-CORRECTED ON THE ROUND IT LANDED, AND THESE TWO ARMS ARE WHAT WITNESSES THE
# REPAIR (#383 S2, round 3). The first form required whitespace or end-of-string after the target, so a
# '/dev/null' followed by ANY OTHER SEPARATOR fell through to the deny — six shapes that were ALLOW one
# commit earlier, none of which creates a file, on the commonest redirect idiom in this repo's own
# scripts. The trailing class now carries the shell separators as well.
#   MEASURED against the runtime on build 2.1.261, this hook absent, nested `claude --plugin-dir` rig:
#     date >/dev/null;touch m1   -> EXECUTED, no prompt (marker on disk) — the hook must not fire
#     (touch m2 >/dev/null)      -> runtime REQUIRED APPROVAL, naming the subshell + redirect
#   So ';' is restored to parity, while '(' … ')' is a case where the widened rule fires on LESS than
#   the runtime stops for. That is the SAFE side of ADR-0004's subset rule and it is stated rather than
#   assumed: the runtime is the backstop, and what is lost there is the instruction, never the block.
check ALLOW "/dev/null before a separator is still /dev/null (#383)" "date >/dev/null;echo hi"
check ALLOW "/dev/null inside a subshell is still /dev/null (#383)"  "(date >/dev/null)"

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
# For part of one day, `Bash(gh -R:*)` in `allow` moved the -R spelling of EVERY gh deny entry from
# "prompts the human" to "runs silently" — the entry was removed the same day, and these rules are what
# hold if any broad `gh` allow returns. `gh -R owner/repo repo delete --yes` returned no decision from
# any layer at all.
check DENY  "repo delete"                   "gh repo delete owner/repo --yes"
check DENY  "repo delete behind -R"         "gh -R owner/repo repo delete --yes"
check DENY  "repo delete, -R attached"      "gh -Rowner/repo repo delete --yes"
check DENY  "repo delete, --repo= attached" "gh --repo=owner/repo repo delete --yes"
check ASK   "repo archive reverses"         "gh repo archive owner/repo"
check ASK   "repo rename reverses"          "gh repo rename newname"
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
check ALLOW "a plain feature push"          "git -C $FEAT push origin feat/x"

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
check_agent DENY "tadeumendonca-skills:agents-lead" "wrapped issue create (5c)" "bash -c 'gh issue create --title x'"
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

echo "--- the unwrap: ANSI-C \$'…' quoting (cause A) ---"
# Found by `security` against the real hook at ce2deea, each verified to EXECUTE rather than inferred.
# The quote-strip only knew `'…'` and `"…"`, so a `$'…'` payload kept its quotes, `$bare` collapsed the
# whole span, and every $bare rule saw nothing — INCLUDING THE MERGE GATE.
check DENY "the MERGE GATE via ANSI-C quoting" "bash -c \$'gh pr merge 145 --merge'"
check DENY "trunk push via ANSI-C quoting"     "bash -c \$'git push origin main'"
check DENY "sh, ANSI-C quoting"                "sh -c \$'git push origin main'"
check DENY "secret set via ANSI-C quoting"     "bash -c \$'gh secret set TOKEN'"
check DENY "repo delete via ANSI-C quoting"    "bash -c \$'gh repo delete o/r --yes'"
check DENY "locale \$\"…\" quoting too"          "bash -c \$\"git push origin main\""
# THE TELL THAT IT WAS THE SAME DEFECT, NOT A NEW ONE: these two denied throughout, because rules 4
# and 2 read $cmd RAW. The unwrap existed to remove exactly that asymmetry between the raw-string
# rules and the $bare rules; under $'…' it was relocated rather than removed.
check DENY "rm -rf denied even before the fix"     "bash -c \$'rm -rf /some/path'"
check DENY "terraform denied even before the fix"  "bash -c \$'terraform apply -auto-approve'"

echo "--- the unwrap: an option run before -c (cause B) ---"
# Requiring `-c` to be the FIRST token after the shell name is a guess about how the caller writes the
# wrapper. This file has rejected that same guess three times (rule 4's flag set, 5b's -R, 5f's
# attached value) and made it a fourth time here.
check DENY "--norc before -c"        "bash --norc -c 'git push origin main'"
check DENY "--login before -c"       "bash --login -c 'git push origin main'"
check DENY "-i before -c"            "bash -i -c 'git push origin main'"
check DENY "-o posix (option + arg)" "bash -o posix -c 'git push origin main'"
check DENY "-x before -c"            "sh -x -c 'git push origin main'"
check DENY "two options before -c"   "bash --login -i -c \$'git push origin main'"
# xargs was reported as a tenth spelling; measured, the plain-quoted form already denied — it is
# cause A, not a separate cause. Both are kept: the one that always worked is the control.
check DENY "xargs, plain quotes"     "xargs -I{} bash -c 'git push origin main'"
check DENY "xargs, ANSI-C quotes"    "xargs -I{} bash -c \$'git push origin main'"

echo "--- the unwrap must not become collateral: running a FILE is not a wrapper ---"
# The option run must not turn a SCRIPT invocation into a wrapper. A script's own `-c` argument is an
# argument to the script, not a shell payload — bash never evaluates it as a command.
check ALLOW "a script with its own -c"      "bash script.sh -c x"
check ALLOW "a script with options and -c"  "bash ./deploy.sh --dry-run -c prod"
check ALLOW "an absolute script, -c arg"    "bash /path/to/run.sh -c 'git push origin main'"
# And a real wrapper around a BENIGN payload must still be allowed, or the fix is just a wider deny.
check ALLOW "wrapper, benign payload"       "bash -c 'git status --short'"
check ALLOW "options, benign payload"       "bash --norc -c 'npm test'"
check ALLOW "ANSI-C, benign payload"        "bash -o posix -c \$'ls -la'"
check ALLOW "unquoted single-word payload"  "bash -c git"

echo "--- ANSI-C escape decoding is NOT covered, and these are the witnesses ---"
# The patch that added `$'…'` support taught the quote-strip the DELIMITER. Bash also DECODES ESCAPES
# inside `$'…'`, and nothing in this hook decodes anything — so a payload spelled with `\x6d` instead
# of `m` is the same command to bash and a different string to every rule here. Measured, two
# characters apart, and the second row executes exactly like the first:
#
#     bash -c $'gh pr merge 145 --merge'     -> DENY   (7b fires)
#     bash -c $'gh pr \x6derge 145 --merge'  -> silent (no decision, from any layer)
#
# ┌─ READ THIS BEFORE TRUSTING THE FIVE SILENCE CASES BELOW ───────────────────────────────────────┐
# │ A WITNESS THAT ASSERTS SILENCE IS THE WEAKEST ASSERTION IN THIS FILE. It passes if the rule     │
# │ works, and it passes just as green if you DELETE the rule it is filed under. It cannot fail for │
# │ the reason a normal case fails, so it proves nothing about coverage.                            │
# │                                                                                                 │
# │ It is a TRIPWIRE, not a proof: it exists so that a future widening of the unwrap — one that      │
# │ starts matching these — shows up as a test someone has to look at, instead of as a silent        │
# │ behaviour change. That distinction is the whole subject of ADR-0004, and it is written here      │
# │ rather than there because here is where someone reads the case.                                 │
# └─────────────────────────────────────────────────────────────────────────────────────────────────┘
#
# WHY `ALLOW` AND NOT `DENY`: nothing denies these, so DENY would assert a mechanism that does not
# exist. `ALLOW` here means the hook is SILENT (see the note above `verdict()`), and silence is what
# produces an ASK from the permission matcher.
#
# WHAT MAKES THAT SILENCE CORRECT, stated as the DERIVATION rather than as a list of entry names:
# **no allow entry remains that would shadow the act.** That sentence stays true through the next
# floor edit; an enumeration does not, and the enumeration that stood here — `Bash(bash:*)`,
# `Bash(sh:*)`, `Bash(xargs:*)` — was already incomplete within hours, because a SECOND floor edit
# narrowed the surviving `bash` entry to a single directory after both gatekeepers found that a
# `git-reps/`-wide prefix let an agent WRITE a script into the tree and run it — moving the wrapper
# class from the `-c` payload to a file path rather than removing it.
#
# TO RE-CHECK THIS CLAIM, do not read this comment: read `.claude/settings.json` and confirm no
# `allow` entry matches the interpreter you are looking at. This suite cannot check it for you — it
# never reads that file.
check ALLOW "hex escape hides the MERGE GATE"  "bash -c \$'gh pr \\x6derge 145 --merge'"
check ALLOW "hex escape hides rm -rf"          "bash -c \$'r\\x6d -rf /x'"
check ALLOW "hex escape hides the trunk push"  "bash -c \$'git -C $FEAT push origin \\x6dain'"
# `\x6d` is not the last spelling, which is the whole reason the class came out of the floor rather
# than out of the regex. Octal and plain concatenation need no escape decoding at all.
check ALLOW "octal escape, same class"         "bash -c \$'gh pr \\155erge 145 --merge'"
check ALLOW "concatenation, no escapes at all" "bash -c \$'r'\"m -rf /x\""
# THE CONTROLS, and they are what keep the five above from being vacuous: the same commands WITHOUT
# the escape still deny. If these ever go quiet, the unwrap has regressed and the cases above would
# not have told you.
#
# THE WEAKNESS ABOVE IS MEASURED, NOT ASSERTED. Reverting the ANSI-C fix — and, separately, disabling
# the unwrap entirely — reddens these controls and leaves **all five silence witnesses green**. That is
# the box's claim, demonstrated: the witnesses cannot fail for the reason a normal case fails.
#
# `rm -rf` IS NOT WITNESSING THE UNWRAP, and is kept anyway. It stays green under both mutations
# because rule 4 matches `$cmd` RAW — the very asymmetry the unwrap was built to remove. It is a
# control on rule 4, not on the unwrap, and reading it as the latter is the mistake that let the
# original `bash -c` blindness be reported as covered.
check DENY  "control: the merge gate, unescaped"  "bash -c \$'gh pr merge 145 --merge'"
check DENY  "control: rm -rf (rule 4, raw \$cmd)"  "bash -c \$'rm -rf /x'"
check DENY  "control: the trunk push, unescaped"  "bash -c \$'git push origin main'"

# THE HEADING BELOW WAS SPLIT IN TWO on 2026-08-04, and the reason is the subject of this whole batch.
# One section used to cover four interpreters as "an accepted gap that reaches ALLOW". The HOOK treats
# all four identically — it is silent for every one — but the FLOOR no longer does, so the sentence
# describing the consequence was true of two of them and false of the other two. **Two different things
# were wearing one heading**, which is exactly what ADR-0004 says a record must not do. The assertions
# never moved; only the prose was wrong, and nothing could have gone red to say so.

echo "--- the interpreter perimeter is an ACCEPTED gap, priced in ADR-0004 ---"
# `python3` and `node` are in the floor's `allow` — pre-existing on `main`, weighed, and priced by
# ADR-0004 as accepted non-containment. So for these two the hook's silence really does mean the
# command runs, and that is the decision rather than an oversight: the unwrap does not chase them
# because a regex cannot parse two more languages, and pretending to would be the "mechanism the file
# claims and does not run" defect.
#
# ASSERTED RATHER THAN LEFT UNTESTED because an accepted gap nobody wrote down is indistinguishable
# from one nobody noticed — and if a future widening of the unwrap DOES start catching them, that is a
# behaviour change someone should have to look at deliberately rather than discover.
check ALLOW "python3 -c is the priced gap"  "python3 -c 'import os; os.system(\"git push origin main\")'"
check ALLOW "node -e is the priced gap"     "node -e 'require(\"child_process\").execSync(\"git push origin main\")'"

echo "--- perl / ruby / eval: the hook is silent, but the floor now ASKS ---"
# SAME HOOK BEHAVIOUR, DIFFERENT CONSEQUENCE — which is why they are no longer filed above.
# `Bash(perl:*)` and `Bash(ruby:*)` were removed from `allow` on 2026-08-04, having been measured as
# NEW against `main` and unmentioned in any commit message: a `perl -e` carrying a trunk push was an
# ASK on trunk and a silent ALLOW here. `eval` was never in `allow` at all.
#
# So these three are NOT a priced gap. They are hook-silent and floor-asked, and the assertion below
# says only the first half — it is `ALLOW` because the HOOK emits nothing, not because the command
# runs. If someone later adds `Bash(perl:*)` back, every case here stays green while the consequence
# inverts; that is the limit of this suite, stated where the cases are.
check ALLOW "perl -e: hook silent, floor asks"  "perl -e 'system(\"git push origin main\")'"
check ALLOW "ruby -e: hook silent, floor asks"  "ruby -e 'system(\"git push origin main\")'"
check ALLOW "eval: hook silent, floor asks"     "eval 'git push origin main'"

echo "--- running a FILE is not a wrapper, and that is now load-bearing for the floor ---"
# `bash script.sh` has no `-c`, so the unwrap does not fire and the hook stays silent — by design, and
# this suite is itself run that way.
#
# WHY THAT DESIGN CHOICE NOW CONSTRAINS THE FLOOR: because the hook declines to look inside a script
# file, an `allow` entry of the form `Bash(bash <dir>/:*)` is only safe where the agent cannot WRITE
# into <dir>. A first floor edit allowed `bash /Users/…/git-reps/:*`, where `Write` is permitted — so
# an agent could author a script and run it, moving the wrapper class from the `-c` payload to a file
# path. Both gatekeepers found it independently; the entry was narrowed to the hook-scripts directory.
# The cases below assert the hook half (silence); the floor half is not visible to this suite.
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
check DENY  "force push (3b, reverted #383)"  "git push --force origin feat/x"
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

echo "--- #383 S3: the three downgraded boundaries, asserted on BOTH sides ---"
# THE CORRECTION THIS BLOCK IS WRITTEN AGAINST, from the gate's final S2 verdict and now ADR-0004's:
# a mutation proves an assertion's SENSITIVITY, never the assertion set's COMPLETENESS. A revert-to-
# loose mutation can only redden arms that already exist on the loose side, so "each mutation kills
# exactly its own arm" is the symptom, not the strength. Every boundary S3 moved therefore gets arms
# on BOTH sides: the act that was downgraded AND the neighbouring act that was not, so reverting the
# split in either direction reddens something.

echo "--- 3a/3b: BOTH halves DENY again (#383 S3-revert); the split survives in the MESSAGES ---"
# S3 made 3b an ASK; the revert made it a DENY again, because a hook `ask` is answered automatically in
# this harness's auto mode — measured in the owner's own session, where the force-push executed with no
# prompt. The 3a/3b SPLIT is not reverted: the two acts still differ (uncommitted work has no other
# copy; a force-pushed tip survives in the reflog), they still carry different messages prescribing
# different remedies, and rule 3's comment still records which is which.
#
# SO THE VERDICT ARMS NO LONGER SEPARATE THEM, AND SAYING THAT OUT LOUD IS THE POINT. A battery of
# `check DENY` over both halves passes whether they are one regex or two — the exact shape of an
# assertion that cannot fail. The `check_reason` arms below are what still discriminate: collapse 3a
# and 3b back into one rule with one message and they redden, while every verdict arm stays green.
check DENY  "3a: reset --hard, no other copy"  "git reset --hard HEAD~1"
check DENY  "3a: reset --hard behind -C"       "git -C /some/repo reset --hard origin/main"
check DENY  "3b: --force"                      "git push --force"
check DENY  "3b: --force-with-lease"           "git push --force-with-lease origin feat/x"
check DENY  "3b: short -f"                     "git push -f origin feat/x"
# The split itself, asserted where a verdict cannot see it.
check_reason DENY "3a still speaks about uncommitted work" "no other copy"  "git reset --hard HEAD~1"
check_reason DENY "3b still speaks about a rewritten ref"  "force-push"     "git push --force origin feat/x"
# The spelling NO settings entry can express, because `:*` is a TOKEN boundary (measured #383 S3): the
# `git -C` prefix, which is itself allowlisted. That is the whole reason 3b is an ASK rather than a
# removal — removed, it would execute in silence.
#
# ~~check ASK "3b: flag AFTER the refspec" "git push origin main --force"~~ — MOVED to the ordering
# block below and FLIPPED to DENY. It was asserting the defect: that spelling lands on the trunk, so
# rule 7 owns it. (It was also cited as a spelling the static layer cannot express, which is false —
# `Bash(git push origin main:*)` is in both deny lists and a token boundary matches an entry plus any
# trailing tokens, measured 2026-09-05.)
check DENY  "3b: behind an allowlisted -C"     "git -C /some/repo push --force origin feat/x"
check ALLOW "3: a plain push is neither half"  "git push origin feat/x"
check ALLOW "3: --soft is not --hard"          "git reset --soft HEAD~1"
# KNOWN DEFECT, PRE-EXISTING, ASSERTED AS IT IS RATHER THAN AS IT SHOULD BE. Rule 3 matches `$cmd`,
# not `$bare`, so a commit message ABOUT the act is treated as the act — the same false positive the
# file fixed for 5b, 5c, 5e and 5f and calls "convention rather than case-by-case care". Measured on
# origin/main's guard, both halves were DENY before this slice; S3 changed the force-push half to ASK
# and did not touch the matching surface, because moving rule 3 to `$bare` changes WHAT IT SEES
# (including how it interacts with the `bash -c` unwrap) and that is its own slice with its own probe
# battery, not a two-token drive-by inside a downgrade slice.
# These two arms are the record. When someone fixes rule 3 to read `$bare`, both flip to ALLOW.
check DENY  "3: KNOWN DEFECT, msg about 3b"    "git commit -m 'git push --force notes'"
check DENY  "3: KNOWN DEFECT, msg about 3a"    "git commit -m 'git reset --hard notes'"

echo "--- 3b x rule 7: the ORDERING survives the revert, and it is now a claim about the REASON ---"
# THE SIX-ROW TABLE THIS BLOCK WAS BUILT AROUND NOW READS DENY ON EVERY ROW, INCLUDING THE ONE ASK ROW.
# That is the S3-revert's ONLY intended change to it — 3b returns `deny`, so the non-trunk force-push
# that was the table's single ASK joins the other five. No row's rule changed hands and no spelling
# moved: rule 7 still owns every trunk row and 3b still owns every non-trunk row.
#
# WHAT WAS LOST AND WHAT REPLACES IT, because pretending nothing was lost is how an uncalibrated check
# survives. At 9aca9d4, 3b sat ABOVE rule 7 and won the intersection, so the trunk's one irreparable
# member came out a PROMPT — a defect a verdict arm could see, because the two rules disagreed on the
# verdict. They no longer disagree. A verdict-only battery is now green under BOTH orderings, so the
# ordering is asserted by REASON below. Move 3b back above rule 7 and the two `check_reason` arms
# redden while all eight verdict arms stay green; that gap is the whole reason the helper exists.
check DENY  "7 wins: -C, trunk, --force"       "git -C /some/repo push --force origin main"
check DENY  "7 wins: flag after the refspec"   "git push origin main --force"
check DENY  "7 wins: --force before the ref"   "git push --force origin main"
check DENY  "7 wins: --force-with-lease trunk" "git -C /some/repo push --force-with-lease origin main"
check DENY  "7 wins: short -f, trunk"          "git push -f origin master"
# The non-trunk side. These are 3b's, and they are DENY again since the S3-revert — if any of them
# returns ASK, the downgrade has come back; if any returns ALLOW, 3b has been removed rather than
# reverted, and `git -C <dir> push --force` executes in silence.
check DENY  "3b keeps: non-trunk ref"          "git push origin feature-x --force"
check DENY  "3b keeps: non-trunk behind -C"    "git -C /some/repo push --force origin feature-x"
check DENY  "3b keeps: 'maintenance' is not 'main'" "git push origin maintenance --force"
# THE ORDERING ITSELF. Rule 7's message prescribes branching and opening a PR; 3b's prescribes not
# rewriting a pushed ref. Both are correct advice for their own act and wrong for the other's.
check_reason DENY "7 answers the TRUNK force-push"     "pushing to the trunk" "git -C /some/repo push --force origin main"
check_reason DENY "3b answers the NON-TRUNK force-push" "force-push"        "git push origin feature-x --force"

echo "--- rule 5: AWS secret writes DENY again (#383 S3-revert); the gh sibling never moved ---"
# S3 made these ASK on the reparability argument; the revert made them DENY again, because a hook
# `ask` is answered automatically in this harness's auto mode. The AWS/gh asymmetry S3 introduced in
# the MESSAGES survives — AWS versions its secrets, GitHub Actions secrets have no history — but it is
# no longer an asymmetry of VERDICT, so no verdict arm can see it. Stated rather than left implied:
# this block is now a one-sided battery, and it is the reason arms below that keep it honest.
#
# `restore-secret` is denied again, which is the REPAIR of a scheduled deletion. That is the revert's
# named cost, asserted as it IS rather than as it should be — the same convention rule 3's known
# defect uses. When someone carves it out, this arm flips to ALLOW and the rule's comment says so.
check DENY  "5: put-secret-value"              "aws secretsmanager put-secret-value --secret-id x"
check DENY  "5: create-secret"                 "aws secretsmanager create-secret --name x"
check DENY  "5: delete-secret is SCHEDULED"    "aws secretsmanager delete-secret --secret-id x"
check DENY  "5: NAMED COST, repair is denied"  "aws secretsmanager restore-secret --secret-id x"
check DENY  "5: ssm SecureString"              "aws ssm put-parameter --name x --type SecureString"
# THE RULE-6 PRE-EMPTION, asserted where a verdict cannot see it. `delete-secret` matches rule 5 AND
# rule 6, both DENY, so only the reason says which answered. Remove rule 5's secretsmanager branch and
# the verdict stays DENY (rule 6 catches it) while this arm reddens — which is the whole point: the
# pre-emption is still live, it just no longer changes the outcome.
check_reason DENY "5 pre-empts 6 for delete-secret" "recovery window" "aws secretsmanager delete-secret --secret-id x"
check_reason DENY "6 owns the rest of the family"   "destructive direct cloud mutation" "aws ec2 delete-volume --volume-id x"
check DENY  "5b: gh secret set has no history" "gh secret set MY_TOKEN"
check DENY  "5b: gh secret delete behind -R"   "gh -R owner/repo secret delete MY_TOKEN"
check ALLOW "5: reading a secret is untouched" "aws secretsmanager get-secret-value --secret-id x"
check ALLOW "5: reading a parameter"           "aws ssm get-parameter --name x"
check ALLOW "5: ssm String is not SecureString" "aws ssm put-parameter --name x --type String"

echo "--- rule 5g: repo delete DENIES; archive/rename ASK ---"
# delete does not reverse: the immutable OIDC subject id is not reissued on a re-create, so every AWS
# trust pinned to it breaks permanently. archive/rename both reverse, and the trusts survive a rename
# precisely BECAUSE the subject pins the id rather than the name.
check DENY  "5g: repo delete"                  "gh repo delete owner/repo --yes"
check DENY  "5g: repo delete behind -R"        "gh -R owner/repo repo delete --yes"
check ASK   "5g: archive unarchives"           "gh repo archive owner/repo"
check ASK   "5g: rename renames back"          "gh repo rename newname"
check ASK   "5g: archive behind --repo="       "gh --repo=owner/repo repo archive"
check ASK   "5g: rename behind -R attached"    "gh -Rowner/repo repo rename newname"
check ALLOW "5g: repo view is neither"         "gh repo view owner/repo"

echo "--- #383 S3: what did NOT move, asserted so a later slice notices if it does ---"
# 5f was scoped into S3 as a downgrade and was NOT shipped — see the rule's own comment for the
# measurement that stopped it. These arms pin the verdict that survived, so "5f still denies the raw
# API write" is a checked fact rather than a claim in a PR body.
check DENY  "5f: raw-API repo delete"          "gh api -X DELETE repos/owner/repo"
check DENY  "5f: -f alone makes it a POST"     "gh api repos/owner/repo/issues -f title=x"
check ALLOW "5f: a read is still a read"       "gh api repos/owner/repo/issues/1/comments"

rm -rf "$FEAT"
rm -rf "$GH_STUB_DIR"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
