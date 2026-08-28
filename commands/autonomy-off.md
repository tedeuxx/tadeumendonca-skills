---
description: End autonomy mode — finish the in-flight slice to merge, start nothing new, then post a closing summary (merged/open/blocked, product vs. loop vs. content). Use when the owner wants the wheel back. Not for capturing a new request (see new-issue).
purpose: hand the wheel back deliberately - finish what is in flight, start nothing new, and report what merged, what is open and what is blocked
argument-hint: "[repo] (defaults to the current repo)"
disable-model-invocation: true
---

End `/autonomy-on` for `$ARGUMENTS` (default: the current repo).

## Ratified reading (B) — stop after the current slice

The invariant `/autonomy-on` enforces does not bend for this command either: **a slice is merged or it
is not started.** So `autonomy-off` does not cut a branch off mid-build to comply faster — it finishes
whatever slice is already in flight, through its Definition of Done and its merge, exactly as
`/autonomy-on` would have. What it changes is what happens **next**: do not pick up the next item in the
queue. Once the in-flight slice reaches a terminal state (merged, or closed per `/autonomy-on`'s own
"when a slice hits an owner decision it did not expect" rule), stop.

If nothing is in flight when this is invoked, there is nothing to finish — go straight to the closing
summary.

## What this does NOT do

- It does not revoke anything the permission floor already denies. `/autonomy-on` never granted
  `terraform apply`/`destroy`, direct cloud mutation, force-push, `rm -rf`, secret writes, or merging
  outside the gatekeeper's verdict — this command has nothing to take back on that axis.
- **It is not a mechanism.** Nothing in this repo tracks "the session is in autonomy mode" as state —
  no flag, no file, no hook reads it. `/autonomy-on` and `/autonomy-off` are both **instructions to the
  agent reading them**, not a state machine. A session transcript that never invokes either command
  never entered or left autonomy in any sense a machine can check; the pair only works because the
  agent honors it. Say this plainly rather than let the existence of an "off" command imply an "on/off"
  switch actually exists somewhere.

## The closing summary — required, posted as the final message

Once the in-flight slice is settled, post a summary before ending the turn. This is what makes the
off-switch an artifact rather than a mood — per `/autonomy-on`'s own reporting rule (state, not
narration), reused here rather than restated differently:

- **Merged this session** — count and list, by issue number.
- **Still open** — any PR that did not reach merge, and why (awaiting the gatekeeper, awaiting the
  owner, blocked).
- **Blocked on the owner** — queried via `gh issue list --label blocked`, not assembled by re-reading
  the queue.
- **Product vs. loop vs. content**, per `/autonomy-on`'s own delivery framing: a session with zero
  product slices is a finding, not a status — say so if it applies here too.

Do not bury this in a commit message or a PR body. It is the final message of the turn, addressed to
the owner.
