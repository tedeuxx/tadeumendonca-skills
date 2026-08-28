#!/usr/bin/env bash
# purpose: log one structured record per dispatch onto the Issue it worked, so the loop can be measured later without raw dispatch text ever reaching a public surface
# dispatch-metrics-stop.sh — SubagentStop hook: log the four benchmarking metrics the owner asked for
# (#209) — rework rounds, time per state, findings per persona, token cost — as a structured comment
# on the Issue the dispatch was working, without ever pasting raw dispatch input/output onto a public
# Issue and without risking GitHub's ~65KB comment cap.
#
# WHAT THIS DOES NOT DO: no dashboard, no aggregation, no analysis. Per the owner's own words on #209
# ("meu take era registrar dados necessários para análise futura... não tinha expectativa de ter
# visualização e acompanhamento nesse momento"), this is logging only — one comment per dispatch,
# structured enough that a future pass can query it, and nothing more.
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
#                       supplies the raw span, not that rollup.
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
# ── ONE COMMENT PER DISPATCH, NOT ONE ACCUMULATED COMMENT PER ISSUE — the design call #209 asks for,
#    made and justified rather than defaulted ─────────────────────────────────────────────────────
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
# fresh comment per dispatch. The cost is real and is named rather than hidden: on a long-running
# Issue this is noisy. Accepted because a broken update mechanism that occasionally eats an unrelated
# comment is a worse failure than noise, and noise is the one #209 explicitly asked to weigh rather
# than default past.
#
# ── WHICH ISSUE, since neither hook payload carries one ────────────────────────────────────────────
# Derived from the checked-out branch in `cwd` — this repo's own convention names branches
# `<type>/issue-<N>-<slug>` or `<type>/<N>-<slug>` (`loop/issue-266-...`, `docs/187-...`,
# `content/issue-247-...`), so the first run of digits in the branch name is the issue number. A
# dispatch on a branch that carries no digits (chiefly: intake work still on `main`, before a branch
# exists) has nothing to attach a comment to and is skipped — a named, accepted coverage gap, not a
# silent one.
#
# Never blocks a subagent from stopping: every exit path is `exit 0`, and every step degrades to
# silence rather than failure. Best-effort logging, same contract as the other SessionStart hooks in
# this repo.

set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0
command -v gh >/dev/null 2>&1 || exit 0

input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

agent_type="$(printf '%s' "$input" | jq -r '.agent_type // empty' 2>/dev/null || true)"
agent_id="$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null || true)"
session_id="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
transcript="$(printf '%s' "$input" | jq -r '.agent_transcript_path // empty' 2>/dev/null || true)"
last_message="$(printf '%s' "$input" | jq -r '.last_assistant_message // empty' 2>/dev/null || true)"

[ -z "$agent_type" ] && exit 0
[ -z "$cwd" ] && exit 0
[ -d "$cwd" ] || exit 0

# ── which issue ──────────────────────────────────────────────────────────────────────────────────
branch="$(git -C "$cwd" branch --show-current 2>/dev/null || true)"
[ -z "$branch" ] && exit 0
issue="$(printf '%s' "$branch" | grep -oE '[0-9]+' | head -1 || true)"
[ -z "$issue" ] && exit 0

# ── which repo ───────────────────────────────────────────────────────────────────────────────────
origin_url="$(git -C "$cwd" remote get-url origin 2>/dev/null || true)"
[ -z "$origin_url" ] && exit 0
repo="$(printf '%s' "$origin_url" \
  | sed -E 's#^git@github\.com:##; s#^https?://github\.com/##; s#\.git$##' || true)"
case "$repo" in */*) : ;; *) exit 0 ;; esac

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
rework_rounds="n/a (not a gatekeeper dispatch)"
case "$agent_type" in
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

# ── compose and post ─────────────────────────────────────────────────────────────────────────────
scratch="$(mktemp 2>/dev/null || true)"
[ -z "$scratch" ] && exit 0
trap 'rm -f "$scratch"' EXIT

{
  printf '<!-- dispatch-metrics: %s #%s -->\n' "$agent_type" "$issue"
  printf 'agent_type: %s\n' "$agent_type"
  printf 'issue: #%s\n' "$issue"
  printf 'branch: %s\n' "$branch"
  printf 'session_id: %s\n' "$session_id"
  printf 'agent_id: %s\n' "$agent_id"
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
  printf '\n_Logged by dispatch-metrics-stop.sh (#209) — structured logging only, no raw dispatch text. The transcript_path above is a LOCAL pointer, valid only on the machine that ran this dispatch._\n'
} > "$scratch" 2>/dev/null || true

[ -s "$scratch" ] || exit 0

gh issue comment "$issue" --repo "$repo" --body-file "$scratch" >/dev/null 2>&1 || true

exit 0
