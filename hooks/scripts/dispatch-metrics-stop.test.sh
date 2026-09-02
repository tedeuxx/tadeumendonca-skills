#!/usr/bin/env bash
# dispatch-metrics-stop.test.sh — the suite this hook shipped WITHOUT for three weeks (#382).
#
# WHY IT EXISTS AT ALL, and the reason is sharper than "every hook should have one". This hook is the
# loop's ONLY cost instrument, its output is read by `/sprint-retrospective` step 2 to decide WHICH
# PERSONAS TO CONSULT, and a persona was nearly cut from the roster on a zero it reported wrongly.
# An observer with a consumer that acts on it is not decoration; it was simply never gated. Every one
# of the four defects #382 records — the branch grep, the accumulation the header denied, the
# `rework_rounds_so_far` arm that never once ran, the unenumerated silent exits — was reachable by
# reading the file, and none of them was reachable by any check.
#
# MUTATION-CHECKED ON THE SOURCE, per this repo's own standing discipline: an assertion that cannot
# fail is this workspace's recurring defect, and reading never finds one. Every arm below was
# confirmed to go RED by breaking the SOURCE — loosening a tokenisation clause, restoring the bare
# `case` pattern, deleting the aggregation trailer, stripping a `silent-exit:` annotation — not by
# breaking the fixture.
#
# `gh` IS A STUB that serves fixtures and LOGS every invocation, so the per-Issue assertions COUNT
# comments rather than infer them. The git repository is REAL, because the hook calls
# `git branch --show-current` and `git remote get-url origin` for real.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$HERE/dispatch-metrics-stop.sh"
pass=0
fail=0

ok()  { printf 'ok    %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL  %s\n     %s\n' "$1" "$2"; fail=$((fail + 1)); }

# ── fixture plumbing ─────────────────────────────────────────────────────────────────────────────

setup() {
  root="$(mktemp -d)"
  repo="$root/repo"
  mkdir -p "$repo" "$root/bin" "$root/fix" "$root/bodies"
  git -C "$repo" init -q -b main
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config user.name test
  git -C "$repo" remote add origin git@github.com:acme/widget.git
  printf 'x\n' > "$repo/f"
  git -C "$repo" add f
  git -C "$repo" commit -q -m init

  : > "$root/calls.log"
  printf '[]\n' > "$root/fix/closing.json"
  printf '[]\n' > "$root/fix/number.json"
  printf '{"comments":[]}\n' > "$root/fix/prview.json"

  # THE STUB HONOURS `--jq`, and that is not a detail. The first draft of this suite just `cat`-ed the
  # fixture, so the hook received raw JSON where real `gh` would have handed it a scalar — and the
  # forge-source and rework-rounds arms failed for a reason that had nothing to do with the hook.
  # A stub that is more permissive than the tool it replaces produces a red that is about the stub;
  # one that is LESS faithful in the other direction produces a green that is about nothing.
  cat > "$root/bin/gh" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "__ROOT__/calls.log"

# Extract the --jq expression, if any, exactly where the caller put it.
jq_expr=""
prev=""
for a in "$@"; do
  if [ "$prev" = "--jq" ]; then jq_expr="$a"; fi
  prev="$a"
done

emit() { # fixture path
  if [ -n "$jq_expr" ]; then
    jq -r "$jq_expr" < "$1"
  else
    cat "$1"
  fi
}

case "$1 $2" in
  "pr list")
    case "$*" in
      *closingIssuesReferences*) emit "__ROOT__/fix/closing.json" ;;
      *) emit "__ROOT__/fix/number.json" ;;
    esac ;;
  "pr view") emit "__ROOT__/fix/prview.json" ;;
  "issue comment")
    # Persist the body so its CONTENT can be asserted, not just the call shape.
    n=""
    prev=""
    for a in "$@"; do
      if [ "$prev" = "--body-file" ]; then cp "$a" "__ROOT__/bodies/last"; fi
      prev="$a"
    done
    n="$3"
    cp "__ROOT__/bodies/last" "__ROOT__/bodies/$n" 2>/dev/null || true
    ;;
esac
exit 0
STUB
  sed -i.bak "s#__ROOT__#$root#g" "$root/bin/gh"
  rm -f "$root/bin/gh.bak"
  chmod +x "$root/bin/gh"
}

teardown() { rm -rf "$root"; }

# Run the hook on a branch, with a given agent_type. Echoes nothing; state lands in $root.
run_hook() { # branch · agent_type
  local branch="$1" agent="$2"
  git -C "$repo" checkout -q -B "$branch"
  : > "$root/calls.log"
  rm -f "$root/bodies/"*
  jq -nc --arg a "$agent" --arg c "$repo" \
    '{agent_type:$a, agent_id:"agent-abc", session_id:"sess-1", cwd:$c, last_assistant_message:"done"}' \
    | PATH="$root/bin:$PATH" bash "$HOOK" >/dev/null 2>&1
}

# The set of Issue numbers this run posted to, space-separated and sorted.
posted_issues() {
  grep '^issue comment ' "$root/calls.log" | awk '{print $3}' | sort -n -u | tr '\n' ' ' | sed 's/ $//'
}

# ── ARM 1 — the branch tokeniser, one sample per measured false positive ────────────────────────
#
# Each row is a branch that the PRE-FIX rule (`grep -oE '[0-9]+' | head -1`) got wrong, and the value
# it got wrong is named beside it. Every row is a falsifier of one clause of the replacement, so
# loosening any single clause reddens exactly one row rather than all of them.

setup

run_hook "fix/adr-0002-rewrite-355" "acme:developer"
got="$(posted_issues)"
if [ "$got" = "355" ]; then
  ok "tokeniser — a zero-padded record id is not an Issue number (old rule: 0002)"
else
  bad "tokeniser — leading-zero clause" "expected '355', got '$got'"
fi

run_hook "feat/v2-api-355" "acme:developer"
got="$(posted_issues)"
if [ "$got" = "355" ]; then
  ok "tokeniser — a digit run glued to a letter is a version, not an Issue (old rule: 2)"
else
  bad "tokeniser — letter-glued clause (v2)" "expected '355', got '$got'"
fi

run_hook "loop/batch-brief-381-384-372-368-r2" "acme:developer"
got="$(posted_issues)"
if [ "$got" = "368 372 381 384" ]; then
  ok "tokeniser — a BATCH branch resolves to all four Issues (old rule: 381 only, PR #391's defect)"
else
  bad "tokeniser — the batch case #382 was filed for" "expected '368 372 381 384', got '$got'"
fi

run_hook "chore/rebuild-20260902" "acme:developer"
got="$(posted_issues)"
if [ -z "$got" ]; then
  ok "tokeniser — a date stamp is not an Issue number (5-digit bound)"
else
  bad "tokeniser — length bound" "expected no post, got '$got'"
fi

run_hook "loop/issue-266-x" "acme:developer"
got="$(posted_issues)"
if [ "$got" = "266" ]; then
  ok "tokeniser — the ordinary <type>/issue-<N>-<slug> convention still resolves"
else
  bad "tokeniser — ordinary convention" "expected '266', got '$got'"
fi

# ── ARM 2 — `main` is still unrecorded, and that is ASSERTED rather than left to be rediscovered ──
#
# This is the coverage gap the header names. It is asserted because a future change that silently
# starts attributing intake dispatches to an arbitrary Issue would be WORSE than the gap, and nothing
# else in this repo would say so.

run_hook "main" "acme:agents-lead"
got="$(posted_issues)"
if [ -z "$got" ]; then
  ok "no-issue-resolved — a dispatch on 'main' with no PR posts nothing, and invents no Issue"
else
  bad "no-issue-resolved" "expected no post on a bare 'main', got '$got'"
fi

# ── ARM 3 — the forge's own resolved set is a source, and it is UNIONED with the branch ──────────

jq -n '[{closingIssuesReferences:[{number:501},{number:502}]}]' > "$root/fix/closing.json"
run_hook "loop/some-slug-with-no-number" "acme:developer"
got="$(posted_issues)"
if [ "$got" = "501 502" ]; then
  ok "forge source — closingIssuesReferences resolves a branch whose NAME carries no number"
else
  bad "forge source" "expected '501 502', got '$got'"
fi

run_hook "loop/batch-355" "acme:developer"
got="$(posted_issues)"
if [ "$got" = "355 501 502" ]; then
  ok "union — the forge set and the branch set are unioned, not preferred one over the other"
else
  bad "union of both sources" "expected '355 501 502', got '$got'"
fi
printf '[]\n' > "$root/fix/closing.json"

# ── ARM 4 — rework_rounds_so_far, the arm that had NEVER computed a number ───────────────────────
#
# The defect was that `case "$agent_type"` matched the bare persona name while the harness stamps
# `<plugin>:<persona>`. Measured before the fix: 47 of 47 comments read the n/a string, including
# every gatekeeper dispatch. Both spellings are asserted, so re-introducing the bare-only `case`
# reddens the first row and leaving the strip out entirely reddens both.

jq -n '[{number:77}]' > "$root/fix/number.json"
jq -n '{comments:[{body:"<!-- gatekeeper-verdict: x -->\nREQUEST-CHANGES"},{body:"<!-- harness-lead-verdict: y -->\nREQUEST-CHANGES"},{body:"<!-- gatekeeper-verdict: z -->\nAPPROVE-AND-MERGE"}]}' \
  > "$root/fix/prview.json"

run_hook "loop/gate-355" "acme:quality-assurance"
if grep -q '^rework_rounds_so_far: 2$' "$root/bodies/355" 2>/dev/null; then
  ok "rework rounds — a NAMESPACED agent_type computes a number (the #382 defect, both markers counted)"
else
  bad "rework rounds — namespaced agent_type" \
      "expected 'rework_rounds_so_far: 2', got '$(grep '^rework_rounds_so_far' "$root/bodies/355" 2>/dev/null)'"
fi

run_hook "loop/gate-355" "quality-assurance"
if grep -q '^rework_rounds_so_far: 2$' "$root/bodies/355" 2>/dev/null; then
  ok "rework rounds — the BARE spelling still works, for a harness that does not namespace"
else
  bad "rework rounds — bare agent_type" \
      "expected 'rework_rounds_so_far: 2', got '$(grep '^rework_rounds_so_far' "$root/bodies/355" 2>/dev/null)'"
fi

run_hook "loop/gate-355" "acme:developer"
if grep -q '^rework_rounds_so_far: n/a (not a gatekeeper dispatch)$' "$root/bodies/355" 2>/dev/null; then
  ok "rework rounds — a NON-gatekeeper dispatch still reports n/a, so the strip did not widen the arm"
else
  bad "rework rounds — non-gatekeeper" \
      "expected the n/a string, got '$(grep '^rework_rounds_so_far' "$root/bodies/355" 2>/dev/null)'"
fi
printf '[]\n' > "$root/fix/number.json"

# ── ARM 5 — the record declares its own aggregation rule ────────────────────────────────────────
#
# The header claimed "one comment per dispatch" and the artifact was cumulative-at-stop; summing it
# naively overshot by 69%. The correction is only worth anything if it reaches the READER, and the
# reader reads the comment, not this file. So the comment must carry both machine fields and the
# prose rule.

run_hook "loop/agg-355" "acme:developer"
body="$root/bodies/355"
if grep -q '^record: cumulative-at-stop$' "$body" 2>/dev/null; then
  ok "aggregation — the record declares itself cumulative-at-stop"
else
  bad "aggregation — record field" "the 'record: cumulative-at-stop' line is missing from the comment"
fi
if grep -q '^dedupe_key: agent-abc$' "$body" 2>/dev/null; then
  ok "aggregation — the record carries the dedupe key a consumer must group by"
else
  bad "aggregation — dedupe_key field" "the 'dedupe_key:' line is missing or does not carry the agent_id"
fi
if grep -q 'Summing across comments double-counts' "$body" 2>/dev/null; then
  ok "aggregation — the prose rule travels WITH the record, not only in this repo's source"
else
  bad "aggregation — prose rule" "the comment does not state the aggregation rule"
fi

# ── ARM 6 — the record names the whole set it resolved, not only the Issue it is posted on ──────
#
# Without this, a reader on #372 cannot tell that the same dispatch also worked #381 — which is
# exactly the join `/sprint-retrospective` needs and the reason a batch read as four unrelated slices.

run_hook "loop/batch-371-372" "acme:developer"
if grep -q '^issues_resolved: 371 372$' "$root/bodies/371" 2>/dev/null; then
  ok "set visibility — each comment names every Issue the dispatch resolved"
else
  bad "set visibility" "expected 'issues_resolved: 371 372' in the #371 comment, got '$(grep '^issues_resolved' "$root/bodies/371" 2>/dev/null)'"
fi

# ── ARM 6b — THE CAP, which was the one new behaviour in this slice with no assertion at all ────
#
# Added on review. The slice's own thesis is "this shipped without a suite for three weeks", so a new
# bound arriving with no arm is that defect in miniature — and the cap is the ONLY thing standing
# between a runaway branch name and an unbounded fan-out.
#
# Three properties, because the cap is only safe if all three hold: it BOUNDS the posts, it is VISIBLE
# when it bites, and — the one that was wrong before this arm existed — `issues_resolved` still names
# the WHOLE set rather than the truncated one.

run_hook "loop/b-101-102-103-104-105-106-107-108-109-110" "acme:developer"
posted_count="$(grep -c '^issue comment ' "$root/calls.log" || true)"
if [ "$posted_count" -eq 8 ]; then
  ok "cap — ten resolved Issues post to exactly 8, so the fan-out is bounded"
else
  bad "cap — bound" "expected 8 posts, got $posted_count"
fi

capbody="$root/bodies/101"
if grep -q '^issues_truncated: yes — 10 resolved, capped at 8$' "$capbody" 2>/dev/null; then
  ok "cap — truncation is VISIBLE in the artifact and names the total, never silent"
else
  bad "cap — visibility" "expected the issues_truncated line, got '$(grep '^issues_truncated' "$capbody" 2>/dev/null)'"
fi

if grep -q '^issues_resolved: 101 102 103 104 105 106 107 108 109 110$' "$capbody" 2>/dev/null; then
  ok "cap — issues_resolved names the WHOLE set, not the 8 that were posted to"
else
  bad "cap — set visibility survives truncation" \
      "issues_resolved must carry all ten; got '$(grep '^issues_resolved' "$capbody" 2>/dev/null)'"
fi

teardown

# ── ARM 7 — every silent exit is NAMED, derived from the SOURCE ──────────────────────────────────
#
# ANCHORED ON STRUCTURE, NEVER ON A LINE NUMBER, per this repo's own rule: an arm anchored on a line
# breaks on its own fix. This arm reads every `exit 0` in the executable region and requires a
# `# silent-exit:` annotation on the line above it. So an early return added later without an
# annotation reddens here, and the header's enumeration cannot go stale silently — which is the whole
# of what "make the silence visible" can mean in a layer that must never block a dispatch.
#
# IT EMITS ITS MEMBERS ON A HIT, never a count: a falsifier that reports only a number is one a reader
# cannot act on, and this repo has paid for that shape more than once.

# The scan walks UPWARD through the contiguous comment block above the exit, rather than reading the
# single line above it. An annotation that wraps onto a second line is the normal case in this file,
# and a one-line lookback called that unannotated — a red about the arm, not about the hook.
unannotated=""
while IFS= read -r n; do
  found=""
  p=$((n - 1))
  while [ "$p" -gt 0 ]; do
    line="$(sed -n "${p}p" "$HOOK")"
    case "$line" in
      \#*)
        case "$line" in *silent-exit:*) found=1 ;; esac
        [ -n "$found" ] && break
        p=$((p - 1)) ;;
      *) break ;;
    esac
  done
  [ -z "$found" ] && unannotated="$unannotated $n"
done < <(grep -n '^[[:space:]]*\(\[.*\]\|case\|command\).*exit 0\|^exit 0' "$HOOK" | cut -d: -f1)

if [ -z "$unannotated" ]; then
  ok "silent exits — every exit path in the source carries a '# silent-exit:' name"
else
  bad "silent exits — unannotated exit path(s)" "lines:$unannotated"
fi

names="$(grep -c 'silent-exit:' "$HOOK" || true)"
if [ "${names:-0}" -ge 2 ]; then
  ok "silent exits — the annotation set is non-empty, so the arm above cannot pass vacuously"
else
  bad "silent exits — vacuous" "found ${names:-0} 'silent-exit:' annotations; this arm would pass over an empty set"
fi

# ── ARM 8 — the DEFECTIVE parser is absent, not merely superseded ────────────────────────────────
#
# Asserting the replacement's presence is not the same claim as asserting the defect's absence, and
# this repo has shipped a correction landing beside the claim it corrects without touching it. So this
# arm asserts the ABSENCE of the old rule in the executable region.
#
# THE HEADER SPELLS THE OLD RULE VERBATIM, INSIDE ITS STRIKE, AND MUST NOT REDDEN THIS. That is why
# the comment lines are stripped before the search rather than the pattern being narrowed: a struck
# quotation of a defect is the record this repo keeps on purpose, and an absence check that cannot
# tell a live pipeline from a quoted one would force the record to be deleted to go green. The first
# draft of this arm did exactly that and failed on its own file's header.

if grep -v '^[[:space:]]*#' "$HOOK" | grep -qF "grep -oE '[0-9]+' | head -1"; then
  bad "old parser absent" "the pre-#382 first-number-in-the-branch pipeline is still live in the source"
else
  ok "old parser absent — the first-number-in-the-branch rule is gone, not merely described as gone"
fi

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
exit 0
