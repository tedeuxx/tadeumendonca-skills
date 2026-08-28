#!/usr/bin/env bash
# purpose: hold the SubagentStart registration deliberately close to a no-op, so the metrics pair is visible as a pair and no capability is inferred from the event merely being wired
# dispatch-metrics-start.sh — SubagentStart hook, registered for symmetry with dispatch-metrics-stop.sh
# and deliberately close to a no-op. Read this file before assuming it does more than it does (#209).
#
# WHAT SubagentStart CARRIES, measured (#209 comment, 2026-08-14): session_id, transcript_path (the
# MAIN session's, not this agent's own), cwd, prompt_id, agent_id, agent_type, hook_event_name. No
# prompt text, no token usage, no `agent_transcript_path` — that field does not exist until the agent
# has produced at least one turn, so it is a SubagentStop-only field.
#
# EVERY ONE OF THOSE FIELDS IS ALSO ON THE FIRST LINE OF `agent_transcript_path`, which
# dispatch-metrics-stop.sh already reads in full. So there is nothing in the SubagentStart payload
# that Stop cannot reconstruct itself, and the one thing Start uniquely knows — "a dispatch of this
# TYPE began, at this wall-clock instant" — is already recoverable from the transcript's own first
# timestamp to within the time it takes the harness to write the first line, which is not a gap this
# hook is built to close.
#
# SO THIS HOOK DOES NOT POST. Posting a second comment per dispatch (Start AND Stop) doubles the
# per-round comment volume for zero additional signal — exactly the noise cost #209 asks to be weighed
# rather than defaulted into. The design call is: ONE comment per dispatch, from Stop, where the data
# actually is.
#
# WHY IT IS REGISTERED AT ALL, rather than left out of hooks.json entirely. Two reasons, both
# deliberately small:
#   1. Symmetry with the event pair #209 asks to implement, so a future extension (e.g. a genuine
#      queueing-delay measurement, if Claude Code ever exposes one) has a place to land without a new
#      hooks.json edit.
#   2. A cheap, silent dependency probe — the same shape session-plugin-version.sh already uses for a
#      different dependency chain. If `jq` is unavailable, dispatch-metrics-stop.sh will not be able to
#      read `agent_transcript_path` either, so this hook says so ONCE, early, rather than leaving the
#      Stop hook to fail silently on every dispatch with no signal anywhere that metrics are not being
#      captured this session.
#
# Never blocks a dispatch — this hook has nothing to decide and must not slow a subagent's start.
# Silent on success and on a missing dependency alike: `finish` below always exits 0; the notice, when
# it fires, is additionalContext for the ORCHESTRATOR (the only party that can act on "install jq"),
# never a denial.

set -uo pipefail

if ! command -v jq >/dev/null 2>&1; then
  jq_notice='DISPATCH METRICS WILL NOT BE CAPTURED THIS SESSION — `jq` is not on PATH.

`dispatch-metrics-stop.sh` (SubagentStop) needs `jq` to read `agent_transcript_path` and to build the
issue comment body. Without it, every subagent dispatch in this session completes with no metrics
comment posted, and nothing else in this loop will say so — this notice is that "nothing else".

Install `jq` and restart the session if per-dispatch metrics (#209) matter for this run.'
  # No jq means the ordinary jq-based escaping this repo's other hooks use is unavailable here too
  # (session-plugin-version.sh hits the identical problem and solves it the same way) — escape by
  # hand rather than depend on the very tool whose absence is the notice.
  escaped="$(printf '%s' "$jq_notice" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk 'BEGIN{ORS="\\n"}{print}')"
  printf '{"hookSpecificOutput":{"hookEventName":"SubagentStart","additionalContext":"%s"}}\n' "$escaped"
fi

exit 0
