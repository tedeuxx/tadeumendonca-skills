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

# ── which repo ───────────────────────────────────────────────────────────────────────────────────
origin_url="$(git -C "$cwd" remote get-url origin 2>/dev/null || true)"
# silent-exit: no-origin-remote — cwd is not a git checkout with an origin
[ -z "$origin_url" ] && exit 0
repo="$(printf '%s' "$origin_url" \
  | sed -E 's#^git@github\.com:##; s#^https?://github\.com/##; s#\.git$##' || true)"
# silent-exit: origin-not-owner-slash-repo
case "$repo" in */*) : ;; *) exit 0 ;; esac

# ── which issues — the SET, unioned from the forge and from the branch (see the header) ──────────
branch="$(git -C "$cwd" branch --show-current 2>/dev/null || true)"

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

issues="$(printf '%s\n%s\n' "$pr_issues" "$branch_issues" \
  | grep -E '^[0-9]+$' \
  | sort -n -u || true)"

# silent-exit: no-issue-resolved — no PR and no qualifying token in the branch name (chiefly intake
# work still on `main`). Named rather than left to be rediscovered; see the header.
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
