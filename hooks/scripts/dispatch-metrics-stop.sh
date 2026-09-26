#!/usr/bin/env bash
# purpose: log one structured record per dispatch onto every Issue it worked, so the loop can be measured later without raw dispatch text ever reaching a public surface
# dispatch-metrics-stop.sh — SubagentStop hook: log the four benchmarking metrics the owner asked for
# (#209) — rework rounds, time per state, findings per persona, token cost — as a structured comment
# on the Issue the dispatch was working, without ever pasting raw dispatch input/output onto a public
# Issue and without risking GitHub's ~65KB comment cap.
#
# WHAT THIS DOES NOT DO: no dashboard, no aggregation, no analysis. Per the owner's own words on #209
# ("meu take era registrar dados necessários para análise futura... não tinha expectativa de ter
# visualização e acompanhamento nesse momento"), this is logging only — one comment per stop per
# Issue, structured enough that a future pass can query it, and nothing more.
#
# ── WHERE THE FOUR METRICS ACTUALLY COME FROM, measured on #209 rather than assumed ────────────────
#
#   TIME PER STATE   — `agent_transcript_path`'s own first and last `timestamp` fields. Measured
#                       (#209 comment, 2026-08-14 and again in this PR): every line in that file, user
#                       and assistant alike, carries an ISO-8601 `timestamp`. Wall-clock duration of
#                       ONE dispatch is the difference; it is not "time in a loop STATE" (filed →
#                       ready → in progress → …) — this hook has no visibility into the state table,
#                       only into one dispatch's own span. A later pass could sum per-agent_type
#                       durations across an Issue's comments to approximate time-in-state; this hook
#                       supplies the raw span, not that rollup. READ THE AGGREGATION RULE BELOW BEFORE
#                       SUMMING ANYTHING — the naive sum is wrong by construction.
#
#   TOKEN COST        — summed from `agent_transcript_path`'s assistant `message.usage` objects.
#                       MEASURED, not assumed: the same `message.id` repeats across several JSONL
#                       lines as a response streams (a thinking-chunk line, then a text-chunk line,
#                       then occasionally a duplicate final line), each carrying a `usage` object
#                       whose `input_tokens`/`cache_*` figures are IDENTICAL across the repeats and
#                       whose `output_tokens` grows to its final value on the last repeat. Summing
#                       every line's `usage` blindly overcounts input/cache tokens by the number of
#                       repeats. This hook dedupes by `message.id`, keeping the repeat with the
#                       largest `output_tokens` (the final snapshot) before summing.
#
#   FINDINGS PER PERSONA — NOT parsed out of the transcript. A generic "count the bullet points in
#                       `last_assistant_message`" parser would be noise dressed as a metric — some
#                       personas (`quality-assurance`) return a structured, labelled verdict; most
#                       don't. What this hook logs instead is a size proxy (line/char count of the
#                       final message) plus a POINTER — the transcript path — never the text itself,
#                       honouring #209's "never paste raw dispatch input/output onto a public Issue"
#                       constraint. A stricter per-persona findings count is future work with a real
#                       output contract behind it, not a regex here.
#
#   REWORK ROUNDS      — NOT transcript-derivable, confirmed on #209: one subagent dispatch is one
#                       continuous transcript, not a sequence of review/revise cycles. A rework round
#                       is a GitHub-side fact — how many times `quality-assurance` (or `agents-lead`,
#                       per ADR-0002, record 0015) posted REQUEST-CHANGES on the PR before it merged —
#                       so this hook reads it from the PR's own gatekeeper-verdict /
#                       harness-lead-verdict comments (the ADR-0006 / ADR-0002 record 0015 markers,
#                       already the durable record of that fact)
#                       rather than reinventing a counter. Only computed when this dispatch's own
#                       agent_type is one of those two gatekeeper personas, and only when an open PR
#                       already exists for the branch — both are cheap, targeted `gh` reads, not a
#                       blanket query on every dispatch.
#
# ── MARKER CONVENTION ────────────────────────────────────────────────────────────────────────────
# `<!-- dispatch-metrics: <agent_type> #<issue> -->`, the same greppable-HTML-comment shape as
# `gatekeeper-verdict` (ADR-0006) and `harness-lead-verdict` (ADR-0002, record 0015) — chosen for consistency
# with those two rather than invented fresh, and deliberately a DIFFERENT literal so a grep for one
# marker family never accidentally matches the other two, which carry go/no-go authority this one
# does not.
#
# ── THE RECORD IS CUMULATIVE-AT-STOP, NOT ONE-PER-DISPATCH — corrected #382 ───────────────────────
#
# ~~ONE COMMENT PER DISPATCH, NOT ONE ACCUMULATED COMMENT PER ISSUE — the design call #209 asks for,
#   made and justified rather than defaulted.~~ **STRUCK 2026-09-02 (#382). The sentence was this
#   file's own header, in two places, and it was FALSE about the artifact the file produces** — which
#   is why it is struck in place rather than edited away: every consumer that summed these records
#   took the claim from here.
#
# WHAT IS ACTUALLY TRUE, measured by `developer` on its own record during the `sprint-01`
# retrospective: `SubagentStop` fires MORE THAN ONCE for a single dispatch, and every firing re-reads
# the SAME cumulative `agent_transcript_path`. The seven comments on #342 under one persona are FOUR
# agents, and summing their `duration_seconds` gives 8,931 s against a true 5,292 s — **+69%**.
#
# THE DECISION #382 ASKS FOR, MADE RATHER THAN DEFAULTED: **keep the accumulation, correct the header,
# and declare the aggregation rule in the artifact itself.** The alternative — make the comment truly
# one-per-dispatch — requires knowing which stop is the LAST one, and this hook cannot know that: the
# payload carries no "final" flag, `--edit-last` is rejected below for a reason unchanged by this
# correction, and selective edit-by-id needs `gh api`, which the permission floor denies. A mechanism
# that cannot be built is not a design option; declaring the rule is what is actually available.
#
# SO EVERY COMMENT NOW CARRIES `record: cumulative-at-stop` AND `dedupe_key: <agent_id>`, and states
# its own aggregation rule in the trailer. THE RULE, stated once here and once in every comment:
# **group by `agent_id`, keep the record with the greatest `duration_seconds`, and sum across
# `agent_id`s — never across comments.** A consumer that sums every comment double-counts, and now
# has no excuse for it that this file supports.
#
# `gh issue comment --edit-last` exists (measured: `gh issue comment --help`, this PR) and was the
# obvious route to "one updated comment per Issue". It is REJECTED, for a reason that is mechanical
# rather than aesthetic: `--edit-last` edits the CALLER'S literal last comment on the issue, with no
# way to select by content — there is no `--id` and no edit-by-marker in the `gh issue comment`
# surface (same `--help` output). Every persona in this loop posts under the SAME GitHub identity
# (the token this harness runs as; ADR-0006 already names this as the impersonation residual), so
# "the last comment" is not reliably a metrics comment — it could be the OWNER's own ratification
# comment, posted between two dispatches, which `--edit-last` would silently overwrite. Selective
# edit-by-ID exists only through `gh api`, which is denied outright in both the global and the
# per-repo permission floor (`Bash(gh api:*)` in `deny`; verified in this session — `gh api --help`
# itself was refused). So the only mechanism actually available without widening that floor is a
# fresh comment per stop. The cost is real and is named rather than hidden: on a long-running
# Issue this is noisy. Accepted because a broken update mechanism that occasionally eats an unrelated
# comment is a worse failure than noise, and noise is the one #209 explicitly asked to weigh rather
# than default past.
#
# ── WHICH ISSUES, since neither hook payload carries one — REWRITTEN #382 ─────────────────────────
#
# ~~Derived from the checked-out branch in `cwd` … so the first run of digits in the branch name is
#   the issue number.~~ **STRUCK 2026-09-02 (#382).** The rule was `grep -oE '[0-9]+' | head -1`, and
# it was wrong in three separate ways at once. Probed directly, at head, before the fix:
#
#     fix/adr-0002-rewrite-355              -> 0002   (misattributes to a non-existent Issue)
#     feat/v2-api-355                       -> 2      (misattributes)
#     loop/batch-brief-381-384-372-368-r2   -> 381    (records ONE of four; the other three vanish)
#     main                                  -> (none) (every intake dispatch, unrecorded)
#
# The third line is not hypothetical: PR #391 ran a four-Issue batch on such a branch and put 36
# comments on #381 and NONE on the other three, after which `/sprint-retrospective` step 2 read *no
# persona ran* for three quarters of the batch.
#
# THE REPLACEMENT IS A SET, NOT A NUMBER, AND IT HAS TWO SOURCES UNIONED:
#
#   1. THE FORGE'S OWN RESOLVED SET — `closingIssuesReferences` on the PR whose head is this branch.
#      This is the same field `permission-guard.sh` rule 7d reads, chosen for the same reason: GitHub
#      resolved it, so no heuristic of ours can be wrong about it. Its measured limit travels with it
#      (#363): the field is PR-BODY-derived, so a closing keyword living only in a commit message is
#      invisible to it. That limit is exactly why source 2 is not dropped.
#
#   2. THE BRANCH NAME, TOKENISED — split on every non-alphanumeric character, then keep a token only
#      if it is ENTIRELY digits, has NO leading zero, and is at most 5 digits long. Each of those
#      three clauses kills one measured false positive and nothing else:
#        * "entirely digits"    kills `v2` in `feat/v2-api-355` and `r2` in a `-r2` round suffix —
#                               a digit run glued to a letter is a version or a round, never an Issue.
#        * "no leading zero"    kills `0002` in `fix/adr-0002-rewrite-355`. An Issue number never has
#                               one; a zero-padded record id always does.
#        * "at most 5 digits"   kills a date stamp such as `20260902`. This repo's Issue numbers are
#                               three digits and the bound is generous by two orders of magnitude.
#
# THE UNION IS DELIBERATE AND IS THE RIGHT DIRECTION FOR *THIS* MECHANISM. Over-attribution and
# under-attribution are not symmetric here: this hook is an OBSERVER with no authority, so a comment
# on an Issue the dispatch merely touched costs noise, while a missing comment costs a persona being
# read as never having run — which is the defect #382 was filed for, and which nearly cost a profile
# its place in the roster. A GATE would need the opposite bias; this is not a gate.
#
# ── WHAT THE FAN-OUT COSTS, PRICED RATHER THAN LEFT AS "NOISE" ────────────────────────────────────
# The noise paragraph further up prices the ONE-COMMENT-PER-STOP shape, which predates the set and is
# therefore not the whole bill. The set MULTIPLIES that volume by however many Issues resolve, up to
# the cap below. Measured on the live instance this fix was built from:
#
#   gh issue view 381 --repo <owner>/<repo> --json comments \
#     --jq '[.comments[]|select(.body|contains("dispatch-metrics:"))]|length'      # -> 36
#
# 36 metrics comments on ONE Issue, from a batch branch that named four. The identical run under this
# hook posts to all four — so roughly **144 comments for the same work**, four times the volume for
# the same information, and the cap bounds the fan-out at 8 ISSUES rather than at any number of
# comments.
#
# ACCEPTED, and the trade is stated rather than implied: the alternative is what #382 measured — three
# quarters of a batch reading as *no persona ran*. A reader can ignore a comment; a reader cannot
# recover a record that was never posted. **If this becomes intolerable the lever is the cap, not the
# union** — lowering `issue_cap` narrows the fan-out while keeping the attribution correct for the
# common case, and the truncation is visible when it bites.
#
# WHAT IS STILL UNRECORDED, and it is narrower than before but not gone: a dispatch on a branch whose
# name carries no qualifying token AND which has no PR — chiefly intake work still on `main`. That
# case has no Issue to attach a comment to and nothing here can invent one. It is named in the
# silent-exit list below rather than left to be rediscovered.
#
# ── WHICH WORKING TREE — the payload's `cwd` is the SESSION's, not the dispatch's (#513) ─────────
#
# ~~Derived from the checked-out branch in `cwd`~~ was true of one checkout and stopped being true the
# day per-slice worktrees arrived (#385). MEASURED FROM A CAPTURED LIVE PAYLOAD, build 2.1.283: a
# throwaway plugin loaded with `--plugin-dir` recorded `SubagentStop` for a dispatch whose only
# command was `git -C <worktree> branch --show-current` (it returned the worktree's branch), and the
# payload's `cwd` — and the hook process's own `$PWD` — was the session's PRIMARY checkout, on `main`.
# A second dispatch told to `cd` into the worktree was REFUSED by the host (a worktree outside the
# session's directories is not a place a subagent may `cd`), so the cwd cannot follow the work even
# when asked to. `agent_type` was present and `SubagentStop` fired: hypothesis 2 of #513 is
# eliminated on that build.
#
# WHAT IT COST, read off the records rather than inferred. Every subagent transcript line carries a
# `cwd` and a `gitBranch`; across the sessions behind sprints 02–05 not one line names a worktree as
# `cwd`. So the hook posted against whatever branch the PRIMARY checkout happened to hold at stop:
#   * primary on `main` -> `no-issue-resolved`, silently — the gap #513 was filed for;
#   * primary on ANOTHER slice's branch -> the record lands on the WRONG Issue. Live: `-wt-510` and
#     `-wt-512` work posted onto #473, and `-wt-531` work onto #511, because those were the branches
#     the primary checkout held while the worktree slices were dispatched;
#   * a gate that merged and left the primary on `main` before its last stop -> the gate's own record
#     vanished (#508: four `agents-lead` records, no `quality-assurance` one, although it gated #517).
#
# THE REPAIR, and it is a READ of the dispatch's own actions, never of its prompt. The transcript's
# `tool_use` inputs (command text, file paths) are scanned for every known working-tree root — the
# payload cwd's own `git worktree list`, plus the worktree lists of every `git -C <dir>` target the
# dispatch used, which is what reaches a sibling repository's worktree. The root referenced MOST, on
# a path boundary (so `<repo>` is never counted as a prefix of `<repo>-wt-512`), becomes the working
# tree: its origin names the repository and its branch feeds the two sources above. No reference at
# all -> the payload `cwd`, exactly as before. A referenced root is ACCEPTED only if its origin is a
# GitHub URL naming exactly `owner/repo` (`parse_repo`); otherwise the next-ranked root is tried, then
# the payload cwd. That clause was added on review: a scratch clone reached through `git -C` — no
# origin, or a local-path origin — was the most-referenced root in 9 of 101 replayed dispatches and
# lost every one of those records, one of them silently inside `gh`. The prompt is deliberately NOT read: a brief names every
# Issue it cites, and this very hook's brief cited nine.
#
# AND A THIRD SOURCE, for the gate: THE PULL REQUESTS THIS DISPATCH WROTE TO. `gh pr comment <n>`,
# `gh pr merge <n>` and `gh pr review <n>` in its own Bash calls — acts, never reads, because a
# reviewer VIEWS many PRs and WRITES to the one it reviews — resolve through that PR's head branch
# (tokenised by the same rule) and its `closingIssuesReferences`. Only a PR on the resolved repository
# is read, and at most four. This is what survives a merge that left every checkout on `main`.
# When the branch came from the PAYLOAD CWD and this source found something, the two branch-derived
# sources are DROPPED (`attribution: prs-written-only`): the PR is the dispatch's own act, the
# primary's branch is not.
#
# WHAT THIS STILL DOES NOT COVER, stated so it is not rediscovered: A DISPATCH THAT NAMES NO WORKTREE
# AND WRITES TO NO PR STILL GETS THE PRIMARY CHECKOUT'S BRANCH — so while the primary sits on another
# slice's branch, such a dispatch (an intake read, a lens that returned without posting) is recorded
# on THAT slice's Issue, wrongly, exactly as before #513. The narrowing above cannot reach it, because
# nothing the dispatch did names a better Issue. A dispatch that worked in a SIBLING repository's
# worktree only through `cd` or file paths, with no `git -C` into that repository, cannot reach that
# worktree as a candidate and falls back the same way. Work done through RELATIVE paths in the
# payload cwd counts no reference, so one absolute `git -C` into a sibling repository can outrank it;
# a PR written on the payload cwd's repository is then filtered as foreign and the record is lost —
# found on replay (a gate that merged a `-skills` PR after two `git -C` reads of `-io` on `main`).
# A dispatch that only READ — an
# intake review on `main` that touched no worktree and wrote to no PR — is still `no-issue-resolved`;
# a PR number placed after a flag (`gh pr merge --merge 517`) is not recognised, since the loop's own
# rule names it positionally first; and a branch token names an Issue in the checkout's OWN repository,
# so a branch in one repository carrying another repository's Issue number posts onto the wrong
# Issue there — measured live, 17 records on an unrelated `-io` Issue from a `-io` branch named for a
# `-skills` one. That last one is a naming convention the hook cannot see through.
#
# CODEX EMITS NO RECORDS AT ALL. `codex-hooks.json` registers `PreToolUse` and `UserPromptSubmit`
# only, with no `SubagentStop` equivalent and no reference to this file, so a dispatch run there
# leaves nothing here. `/sprint-retrospective` step 2 says so where it reads these records, and reads
# the PR verdict markers as a second source for exactly that reason.
#
# ── EVERY SILENT EXIT IS NAMED, AND THE NAMES ARE GATED — #382 ────────────────────────────────────
# The hook must not fail a dispatch because it could not post a metric, so every exit path is
# `exit 0`. That is a design choice and it is kept. What was wrong is that the paths were
# UNENUMERATED — the consumer's own words were "about a dozen", which is a lower bound on a lower
# bound. Every `exit 0` in this file now carries a `# silent-exit: <name>` annotation on the line
# above it, and `dispatch-metrics-stop.test.sh` asserts that NO `exit 0` lacks one. The enumeration
# therefore cannot go stale silently: adding an unannotated early return reddens the suite.
#
# THE ANNOTATION IS THE MEMBER LIST, NOT A COUNT. There is deliberately no number published here:
# a count beside a list is a second source of truth for one fact, and this repository's gate exists
# because that arrangement rots. Read the annotations with
# `grep -n 'silent-exit:' hooks/scripts/dispatch-metrics-stop.sh`.
#
# Best-effort logging, same contract as the other SessionStart hooks in this repo.

set -uo pipefail

# The ONLY accepted repository form (#513 review): an origin that is a GitHub URL — `git@github.com:`,
# `ssh://git@github.com/` or `http(s)://github.com/` — whose remainder is exactly `owner/repo`. Prints
# the slug, or nothing. A local-path origin (a clone of a worktree) used to pass a `*/*` test, reach
# `gh … --repo /Users/…`, fail with a format error and be swallowed by `|| true` — a loss that was not
# even a NAMED silent exit. Under this parse that value can no longer reach `gh` at all.
parse_repo() { # origin url
  local u="$1" s
  s="$(printf '%s' "$u" | sed -E 's#^git@github\.com:##; s#^ssh://git@github\.com/##; s#^https?://github\.com/##')"
  [ "$s" = "$u" ] && return 0
  s="${s%/}"; s="${s%.git}"
  printf '%s' "$s" | grep -E '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' || true
}

# silent-exit: no-jq — cannot parse the payload or the transcript at all
command -v jq >/dev/null 2>&1 || exit 0
# silent-exit: no-gh — cannot reach the tracker to post
command -v gh >/dev/null 2>&1 || exit 0

input="$(cat 2>/dev/null || true)"
# silent-exit: empty-payload
[ -z "$input" ] && exit 0

agent_type="$(printf '%s' "$input" | jq -r '.agent_type // empty' 2>/dev/null || true)"
agent_id="$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null || true)"
session_id="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
transcript="$(printf '%s' "$input" | jq -r '.agent_transcript_path // empty' 2>/dev/null || true)"
last_message="$(printf '%s' "$input" | jq -r '.last_assistant_message // empty' 2>/dev/null || true)"

# silent-exit: no-agent-type — nothing to attribute the record to
[ -z "$agent_type" ] && exit 0
# silent-exit: no-cwd
[ -z "$cwd" ] && exit 0
# silent-exit: cwd-not-a-directory
[ -d "$cwd" ] || exit 0

# ── which working tree — the one the dispatch's own tool calls referenced most (#513) ────────────
# See the header: the payload `cwd` is the session's primary checkout, never the slice's worktree.
workdir="$cwd"
resolution="payload-cwd"
rejected=0
if [ -n "$transcript" ] && [ -r "$transcript" ]; then
  # Candidate roots: the payload cwd's own worktree list, plus the worktree list of every distinct
  # `git -C <dir>` target (bounded), which is what reaches a sibling repository's worktree.
  gitc_targets="$(jq -r 'select(.type=="assistant") | .message.content[]?
      | select(.type=="tool_use" and .name=="Bash") | .input.command // empty' "$transcript" 2>/dev/null \
    | grep -oE "git -C (\"[^\"]+\"|'[^']+'|[^ 	;&|)]+)" \
    | sed -E "s/^git -C //; s/^[\"']//; s/[\"']\$//" \
    | sort -u | head -n 12 || true)"
  roots="$(
    { printf '%s\n' "$cwd"; printf '%s\n' "$gitc_targets"; } | while IFS= read -r d; do
      [ -n "$d" ] && [ -d "$d" ] || continue
      git -C "$d" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p'
    done | awk 'NF && !seen[$0]++'
  )"
  if [ -n "$roots" ]; then
    roots_json="$(printf '%s\n' "$roots" | jq -R -s -c 'split("\n") | map(select(length > 0))' 2>/dev/null || true)"
    # Count references on a PATH BOUNDARY: the character after the root must be `/`, a quote, blank,
    # a shell separator, or the end of the string — so `<repo>` is never a prefix hit of `<repo>-wt-N`.
    # `split` rather than `indices`, because `indices` on a string is byte-offset in some jq builds
    # and the commands here carry non-ASCII text.
    # RANKED, not just the winner (#513 review): every referenced root, most-referenced first.
    ranked="$(jq -r -s --argjson roots "${roots_json:-[]}" '
      [ .[] | select(.type=="assistant") | .message.content[]?
        | select(.type=="tool_use") | .input | .. | strings ] as $s
      | [ $roots[] as $r
          | { root: $r,
              n: ([ $s[] | split($r) | .[1:][] | .[0:1]
                    | select(. == "" or test("^[/\\s\"'"'"';&|)]")) ] | length) } ]
      | map(select(.n > 0)) | sort_by(-.n) | .[].root
    ' "$transcript" 2>/dev/null || true)"
    # A candidate is accepted only if its origin parses to `owner/repo` (parse_repo above). A scratch
    # clone — the gate's mutation copy, a fixture repo — is a candidate too, because it is reached
    # through `git -C`, and it is usually the MOST-referenced path in that dispatch. With no origin it
    # used to end the hook at `no-origin-remote`; with a local-path origin it reached `gh` as a
    # malformed `--repo`. Measured by replay over one session's 101 subagent transcripts: 9 records
    # lost that way, one of them the gate that merged a PR. Now it is skipped and the NEXT-ranked root
    # is tried, then the payload cwd.
    while IFS= read -r cand; do
      [ -n "$cand" ] && [ -d "$cand" ] || continue
      if [ -n "$(parse_repo "$(git -C "$cand" remote get-url origin 2>/dev/null || true)")" ]; then
        workdir="$cand"
        [ "$cand" != "$cwd" ] && resolution="transcript-worktree"
        break
      fi
      rejected=$((${rejected:-0} + 1))
    done <<EOF
$ranked
EOF
  fi
fi

# ── which repo ───────────────────────────────────────────────────────────────────────────────────
origin_url="$(git -C "$workdir" remote get-url origin 2>/dev/null || true)"
# silent-exit: no-origin-remote — cwd is not a git checkout with an origin
[ -z "$origin_url" ] && exit 0
repo="$(parse_repo "$origin_url")"
# silent-exit: origin-not-owner-slash-repo — STRICT since the #513 review: a GitHub URL whose remainder
# is exactly `owner/repo`. A local-path origin exits HERE, named, instead of failing inside `gh`.
[ -z "$repo" ] && exit 0

# ── which issues — the SET, unioned from the forge and from the branch (see the header) ──────────
branch="$(git -C "$workdir" branch --show-current 2>/dev/null || true)"

# Source 1: the forge's own resolved set. One call, and it is allowed to return nothing — a branch
# with no PR yet is the normal case for the first dispatches of a slice.
pr_issues=""
if [ -n "$branch" ]; then
  pr_issues="$(gh pr list --repo "$repo" --head "$branch" --state all --limit 1 \
    --json closingIssuesReferences \
    --jq '.[0].closingIssuesReferences[]?.number // empty' 2>/dev/null || true)"
fi

# Source 2: the branch name, tokenised. The three clauses are justified in the header; each one is
# asserted by its own arm in dispatch-metrics-stop.test.sh, so loosening one goes red.
branch_issues=""
if [ -n "$branch" ]; then
  branch_issues="$(printf '%s' "$branch" \
    | tr -c 'A-Za-z0-9' '\n' \
    | grep -E '^[1-9][0-9]{0,4}$' || true)"
fi

# Source 3 (#513): the pull requests this dispatch WROTE to — `gh pr comment|merge|review <n>` in its
# own Bash calls, the number positionally first. Resolved through the PR's head branch (same tokeniser)
# and its closingIssuesReferences. Only a PR on THIS repository is read, and at most four.
touched_issues=""
if [ -n "$transcript" ] && [ -r "$transcript" ]; then
  touched_prs="$(jq -r 'select(.type=="assistant") | .message.content[]?
      | select(.type=="tool_use" and .name=="Bash") | .input.command // empty' "$transcript" 2>/dev/null \
    | grep -oE 'gh pr (comment|merge|review) [1-9][0-9]{0,5}[^;&|]*' \
    | while IFS= read -r m; do
        n="$(printf '%s\n' "$m" | awk '{print $4}')"
        # ANCHORED on a preceding blank (#513 review): unanchored, `-R` inside a body-file path such
        # as `/x/-Rnotes.md` read as a foreign repository and dropped the PR.
        r="$(printf '%s\n' "$m" | grep -oE '[[:space:]](--repo[= ]|-R[= ]?)[^ ]+' | head -n 1 \
          | sed -E 's/^[[:space:]]+//; s/^(--repo[= ]|-R[= ]?)//; s/^["'"'"']//; s/["'"'"']$//' || true)"
        if [ -z "$r" ] || [ "$(printf '%s' "$r" | tr 'A-Z' 'a-z')" = "$(printf '%s' "$repo" | tr 'A-Z' 'a-z')" ]; then
          printf '%s\n' "$n"
        fi
      done | awk 'NF && !seen[$0]++' | head -n 4 || true)"
  for pr in $touched_prs; do
    touched_issues="$touched_issues
$(gh pr view "$pr" --repo "$repo" --json headRefName,closingIssuesReferences \
      --jq '(.closingIssuesReferences[]?.number | tostring), (.headRefName // "")' 2>/dev/null \
      | tr -c 'A-Za-z0-9\n' '\n' \
      | grep -E '^[1-9][0-9]{0,4}$' || true)"
  done
fi

# THE NARROWING (#513 review). When the branch was read from the PAYLOAD CWD — no referenced worktree
# was accepted — that branch is whatever the session's primary checkout holds, which is the source of
# the misattribution this slice exists for. If the dispatch WROTE to a PR, that PR is its own act and
# names its Issue; the primary's branch then adds only a possibly-wrong Issue on top (measured: two
# gates on #532 resolved to the primary's #513 plus the correct #511). So the two branch-derived
# sources are DROPPED in exactly that case. Kept whenever the branch came from a worktree the dispatch
# itself used, and whenever no PR was written — see the residual in the header.
attribution="union"
if [ "$resolution" = "payload-cwd" ] && [ -n "$(printf '%s' "$touched_issues" | tr -d '[:space:]')" ]; then
  pr_issues=""
  branch_issues=""
  attribution="prs-written-only (payload-cwd branch dropped)"
fi

issues="$(printf '%s\n%s\n%s\n' "$pr_issues" "$branch_issues" "$touched_issues" \
  | grep -E '^[0-9]+$' \
  | sort -n -u || true)"

# silent-exit: no-issue-resolved — no PR, no qualifying token in the branch name of the working tree
# the dispatch used, and no PR it wrote to (chiefly intake work still on `main`). Named rather than
# left to be rediscovered; see the header.
[ -z "$issues" ] && exit 0

# The post fans out over the set, so a runaway branch name must not fan out without bound. The cap is
# VISIBLE when it bites — the comment says it truncated and names the total — rather than silent,
# which is the property that separates this from the defect being fixed.
issue_total="$(printf '%s\n' "$issues" | grep -c . || true)"
issue_cap=8
issues_all="$(printf '%s\n' "$issues" | tr '\n' ' ' | sed 's/ $//')"
issues="$(printf '%s\n' "$issues" | head -n "$issue_cap")"

# ── transcript-derived metrics ───────────────────────────────────────────────────────────────────
duration_seconds=""
tool_calls=""
tok_input="" tok_output="" tok_cache_creation="" tok_cache_read=""

if [ -n "$transcript" ] && [ -r "$transcript" ]; then
  span="$(jq -s -c '
    ([.[].timestamp // empty] | map(select(. != ""))) as $ts
    | if ($ts | length) == 0 then null
      else {first: ($ts | sort | first), last: ($ts | sort | last)}
      end
  ' "$transcript" 2>/dev/null || true)"
  if [ -n "$span" ] && [ "$span" != "null" ]; then
    first_ts="$(printf '%s' "$span" | jq -r '.first' 2>/dev/null || true)"
    last_ts="$(printf '%s' "$span" | jq -r '.last' 2>/dev/null || true)"
    if [ -n "$first_ts" ] && [ -n "$last_ts" ]; then
      first_epoch="$(date -u -d "$first_ts" +%s 2>/dev/null || date -u -jf '%Y-%m-%dT%H:%M:%S' "${first_ts%%.*}" +%s 2>/dev/null || true)"
      last_epoch="$(date -u -d "$last_ts" +%s 2>/dev/null || date -u -jf '%Y-%m-%dT%H:%M:%S' "${last_ts%%.*}" +%s 2>/dev/null || true)"
      if [ -n "$first_epoch" ] && [ -n "$last_epoch" ]; then
        duration_seconds="$((last_epoch - first_epoch))"
      fi
    fi
  fi

  tool_calls="$(jq -s '
    [ .[] | select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") ] | length
  ' "$transcript" 2>/dev/null || true)"

  tokens_json="$(jq -s -c '
    [ .[] | select(.type=="assistant") | .message
      | select(.usage != null) | {id, usage} ]
    | group_by(.id)
    | map(max_by(.usage.output_tokens // 0))
    | {
        input: (map(.usage.input_tokens // 0) | add // 0),
        output: (map(.usage.output_tokens // 0) | add // 0),
        cache_creation: (map(.usage.cache_creation_input_tokens // 0) | add // 0),
        cache_read: (map(.usage.cache_read_input_tokens // 0) | add // 0)
      }
  ' "$transcript" 2>/dev/null || true)"
  if [ -n "$tokens_json" ]; then
    tok_input="$(printf '%s' "$tokens_json" | jq -r '.input' 2>/dev/null || true)"
    tok_output="$(printf '%s' "$tokens_json" | jq -r '.output' 2>/dev/null || true)"
    tok_cache_creation="$(printf '%s' "$tokens_json" | jq -r '.cache_creation' 2>/dev/null || true)"
    tok_cache_read="$(printf '%s' "$tokens_json" | jq -r '.cache_read' 2>/dev/null || true)"
  fi
fi

# ── output size proxy — never the text itself ───────────────────────────────────────────────────
output_lines="0"
output_chars="0"
if [ -n "$last_message" ]; then
  output_lines="$(printf '%s' "$last_message" | wc -l | tr -d ' ')"
  output_chars="$(printf '%s' "$last_message" | wc -c | tr -d ' ')"
fi

# ── rework rounds — GitHub-side, gatekeeper dispatches only ─────────────────────────────────────
#
# THE NAMESPACE STRIP IS THE WHOLE FIX (#382). This `case` matched the BARE persona names while the
# harness stamps `agent_type` as `<plugin>:<persona>` — `tadeumendonca-skills:quality-assurance`.
# So the arm below never once ran: measured across the two highest-volume Issues of `sprint-01`,
# 47 of 47 comments read `n/a (not a gatekeeper dispatch)`, including every gatekeeper dispatch.
# It printed a plausible value on every dispatch and had no test arm anywhere, which is this repo's
# named worst shape — a control that reads as working and is inert.
#
# `${agent_type##*:}` is the same strip `permission-guard.sh` expresses as its `*:persona` patterns,
# and the bare form is kept matching too so a payload from a harness that does not namespace still
# works. Both spellings are asserted in dispatch-metrics-stop.test.sh.
agent_bare="${agent_type##*:}"
rework_rounds="n/a (not a gatekeeper dispatch)"
case "$agent_bare" in
  quality-assurance|agents-lead)
    pr_number="$(gh pr list --repo "$repo" --head "$branch" --state all --json number --limit 1 \
      --jq '.[0].number // empty' 2>/dev/null || true)"
    if [ -n "$pr_number" ]; then
      rework_rounds="$(gh pr view "$pr_number" --repo "$repo" --json comments \
        --jq '[.comments[]? | select((.body // "") | contains("gatekeeper-verdict") or contains("harness-lead-verdict")) | select((.body // "") | contains("REQUEST-CHANGES"))] | length' \
        2>/dev/null || true)"
      [ -z "$rework_rounds" ] && rework_rounds="unavailable (gh read failed)"
    else
      rework_rounds="n/a (no PR yet for this branch)"
    fi
    ;;
esac

# ── compose and post, once per resolved Issue ───────────────────────────────────────────────────
scratch="$(mktemp 2>/dev/null || true)"
# silent-exit: mktemp-failed
[ -z "$scratch" ] && exit 0
trap 'rm -f "$scratch"' EXIT

for issue in $issues; do
  {
    printf '<!-- dispatch-metrics: %s #%s -->\n' "$agent_type" "$issue"
    printf 'agent_type: %s\n' "$agent_type"
    printf 'issue: #%s\n' "$issue"
    # THE FULL SET, NEVER THE CAPPED ONE. `issues_resolved` naming only the Issues actually posted to
    # would silently truncate the very set-visibility property this field exists to publish — a
    # reader could not tell a four-Issue batch from the first eight of a forty-Issue one, and the
    # total sat on a different line that only appears when the cap bites.
    printf 'issues_resolved: %s\n' "$issues_all"
    if [ "${issue_total:-0}" -gt "$issue_cap" ]; then
      printf 'issues_posted: %s\n' "$(printf '%s' "$issues" | tr '\n' ' ')"
      printf 'issues_truncated: yes — %s resolved, capped at %s\n' "$issue_total" "$issue_cap"
    fi
    printf 'branch: %s\n' "${branch:-unavailable}"
    # #513: which tree the branch was read from, and why — so a reader can audit an attribution
    # instead of trusting it. `payload-cwd` is the pre-#513 behaviour; `transcript-worktree` means
    # the dispatch's own tool calls pointed somewhere other than the session's checkout.
    printf 'worktree: %s\n' "$workdir"
    printf 'worktree_resolution: %s\n' "$resolution"
    printf 'payload_cwd: %s\n' "$cwd"
    # #513 review: how many referenced trees were skipped for a non-`owner/repo` origin, and whether
    # the primary checkout's branch was dropped in favour of the PRs this dispatch wrote to.
    printf 'worktrees_rejected: %s\n' "$rejected"
    printf 'attribution: %s\n' "$attribution"
    printf 'prs_written: %s\n' "$(printf '%s' "${touched_prs:-}" | tr '\n' ' ' | sed 's/ $//')"
    printf 'session_id: %s\n' "$session_id"
    printf 'agent_id: %s\n' "$agent_id"
    printf 'record: cumulative-at-stop\n'
    printf 'dedupe_key: %s\n' "$agent_id"
    printf 'duration_seconds: %s\n' "${duration_seconds:-unavailable}"
    printf 'tool_calls: %s\n' "${tool_calls:-unavailable}"
    printf 'tokens_input: %s\n' "${tok_input:-unavailable}"
    printf 'tokens_output: %s\n' "${tok_output:-unavailable}"
    printf 'tokens_cache_creation: %s\n' "${tok_cache_creation:-unavailable}"
    printf 'tokens_cache_read: %s\n' "${tok_cache_read:-unavailable}"
    printf 'output_lines: %s\n' "$output_lines"
    printf 'output_chars: %s\n' "$output_chars"
    printf 'rework_rounds_so_far: %s\n' "$rework_rounds"
    printf 'transcript_path: %s\n' "${transcript:-unavailable}"
    printf '\n_Logged by dispatch-metrics-stop.sh (#209, corrected #382) — structured logging only, no raw dispatch text. The transcript_path above is a LOCAL pointer, valid only on the machine that ran this dispatch._\n'
    printf '\n_AGGREGATION RULE — this record is CUMULATIVE AT ONE STOP, not one per dispatch. `SubagentStop` fires more than once per dispatch and every firing re-reads the same cumulative transcript. To aggregate: group by `dedupe_key` (the `agent_id`), keep the record with the greatest `duration_seconds`, then sum ACROSS `agent_id`s. Summing across comments double-counts — measured at +69% on #342._\n'
  } > "$scratch" 2>/dev/null || true

  [ -s "$scratch" ] || continue

  gh issue comment "$issue" --repo "$repo" --body-file "$scratch" >/dev/null 2>&1 || true
done

# silent-exit: normal-completion
exit 0
