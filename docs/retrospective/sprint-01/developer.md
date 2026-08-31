# sprint-01 — retrospective · developer

commit: f117c67d1229dff66d73324c2ca9aa3f487b82e1 (`tadeumendonca-skills`, branch `docs/retrospective-sprint-one`)
fed-with:
- my own `dispatch-metrics` comments — `<!-- dispatch-metrics: tadeumendonca-skills:developer #313 -->` (2) and `#342` (7), fetched with the namespaced `agent_type`, bodies read in full;
- the four PRs carrying those branches — `#323` (`feat/blueprint-registry-313`), `#345` (`feat/purpose-field-313`), `#346` (`feat/blueprint-export-313`), `#354` (`feat/container-preflight-refuses-degraded-342`) — their commit lists, and every `gatekeeper-verdict` / `harness-lead-verdict` marker on them;
- `#313` and `#342` themselves (title, labels, body);
- `docs/retrospective/sprint-01/00-scope.md` (the scope record, per the rite);
- `agents/developer.md` and `hooks/scripts/dispatch-metrics-stop.sh` at head.

*Not read, per the rite's isolation clause: `agents-lead.md`, `product-lead.md`, `quality-assurance.md` in this directory. I did not run `git log` on this branch, and no other persona's retrospective finding reached me by any route.*

## Finding 1 — every dispatch I received this iteration was on a lane my own brief tells me to refuse

**What I saw.** All 9 of my recorded dispatches landed on `loop`-typed Issues — `#313` (2) and `#342`
(7), both labelled `ready, loop` — and on nothing else. Zero on `product`, in either repository. The
diffs I worked were a `PreToolUse`/`UserPromptSubmit` guard (`hooks/scripts/preflight.sh`) and a gated
frontmatter field spanning `hooks/`, `agents/`, `commands/` and `skills/`.

**The artifact that shows it.** Three sources agree with each other and disagree with what I did:

- `agents/developer.md:102` — of `agents-lead`: ***"It never appears anywhere in your path."*** And
  `:108-110` — *"a slice of **yours** that would change the machinery — a hook, the permission floor, an
  agent brief, a command — … is not yours to make. Say so and hand it up."* Applied literally, that
  sentence obliges me to refuse **every dispatch I received this sprint**.
- `/harness-engineering`'s states table: `ready → in progress` for `loop` is **`agents-lead`**
  (ADR-0002, record 0015's Corollary 1). There is no row admitting me to that lane.
- The PRs agree with the table and not with the metrics. Every build on those branches is signed
  `<!-- harness-lead-verdict: … -->` — on `#354`, *"built the blocking preflight #342 asked for"*; on
  `#345`, *"slice 1 built and stress-tested"*. **No artifact on any of those PRs records that
  `developer` acted at all.** My only trace is the metrics comment, which the scope record itself
  classifies as a lower bound.

**What it costs.** Three things, in ascending order of how hard they are to see later:

1. **I applied a brief written for a different lane.** Its operative rules — refuse a story without
   `ready`, decompose a `ready` story into tasks, cover the change with an E2E journey — are `product`
   rules. On a hook diff, `ready` sits on a `loop` Issue whose builder-of-record is someone else, there
   is no story to decompose, and the regression is a `.test.sh` suite, not a browser journey. **Nothing
   written anywhere says which of my obligations survive onto this lane**, so I decided that myself, per
   slice, silently — which is precisely the judgement the brief spends a paragraph telling me not to
   make.
2. **The builder-of-record is not the builder.** The gate's hold 2 checks that an `agents-lead` marker
   is present on a harness PR. It was, every time. It is a *reviewer-presence* check and it reads, to
   anyone auditing later, as authorship. The one persona whose hands were on `#354`'s diff for the
   longest single span left no marker.
3. **This retrospective found me by accident.** The consult set is derived from `dispatch-metrics`, and
   the scope record documents that the hook exits silently on about a dozen paths. Had it exited on any
   of them, the builder of two of this sprint's thirteen Issues would not have been consulted, and
   nothing would have said so.

**The change I propose, or the price of leaving it.** *This is a proposal; I do not decide it.* One of
two, not both: either **the states table gains a row** admitting `developer` as a sub-builder on `loop`
under `agents-lead`'s dispatch — with the carried-over obligations named explicitly (`ready` on the
`loop` Issue, `/code-review` before the MR, never reviewing my own work) and the dropped ones named too
(no task decomposition, `.test.sh` in place of E2E) — **or I stop being dispatched there** and
`agents-lead` builds what the table already says it builds. **The price of leaving it as-is** is that the
gap stays where nothing can see it: a persona following its brief correctly refuses work the loop
routinely gives it, and a persona ignoring its brief produces exactly the diffs that shipped. Both look
identical in the tracker, which is the property this loop's own test calls not-engineered.

## Finding 2 — my cost figures are cumulative, and the hook's own header says they are not

**What I saw.** The 7 `dispatch-metrics` comments on `#342` under my `agent_type` are **not 7
dispatches.** They are **4 distinct `agent_id`s**, three of them posting more than once with
monotonically growing figures for the same agent:

| `agent_id` | comments | `duration_seconds` | `tool_calls` | `tokens_cache_read` |
|---|---|---|---|---|
| `a27b72718ab7b0cf7` | 1 | 97 | 22 | 1,136,439 |
| `adb3e87a44f944570` | 1 | 679 | 89 | 10,510,231 |
| `a798135840132711b` | **3** | 1178 → 1941 → **2898** | 122 → 160 → **183** | 15.9M → 23.6M → **31.3M** |
| `a82801eb2c94951a2` | **2** | 520 → **1618** | 73 → **134** | 6.9M → **18.7M** |

**The artifact that shows it.** The comment bodies above, and
`hooks/scripts/dispatch-metrics-stop.sh:5` — *"one comment per dispatch"* — repeated at `:9`
(*"this is logging only — one comment per dispatch"*). **That sentence is false on my own data.** The
header is unusually careful elsewhere: it documents deduping `message.id` repeats *inside* one
transcript precisely because *"summing every line's usage blindly overcounts"*. The same overcount then
reappears one level up, across comments, undeduped.

**What it costs.** Two consumers read these numbers and both are wrong in the same direction:

- **Naive summation overstates by 69%.** Adding all seven `duration_seconds` gives **8,931 s**; the four
  agents' final values sum to **5,292 s**. A future cost or velocity pass — which is the stated reason
  #209 built this hook — would read my one `#342` slice as two-thirds longer than it was.
- **The consult set counts comments as dispatches.** `00-scope.md` records `developer: 9`; by
  `agent_id` it is **6**. On my own row the error changes nothing (I was consulted either way). On a
  persona sitting at the boundary between *consulted* and *not*, an inflated count decides that
  question, and the rite has no way to notice.

**The change I propose, or the price of leaving it.** *Proposal only.* The cheapest honest fix is a
**documentation fix, not a code one**: correct the header to say *one comment per SubagentStop, whose
figures are cumulative for that `agent_id`*, and publish the deduping form — `group_by(agent_id)` and
take the last — alongside the counting query in the rite, so the number ships with the command that
produces it correctly. Deduping at write time (edit the existing comment for that `agent_id` instead of
posting a new one) is the stronger fix and is a bigger change than this finding justifies on its own
evidence. **The price of leaving it** is a metric that is wrong by a factor nobody has measured, in the
one place this loop keeps its record of what work costs — and it is wrong *upward*, which is the
direction that makes the loop look more expensive than it is.

## What I would leave alone

- **The gate.** Nothing came back at me that I would call a wasted round. On `#345` and `#346` the
  verdict was `APPROVE-AND-MERGE-BOUNDARY` at the first head; on `#354` the one rework round was
  triggered by a real falsifiable defect in published prose, not by taste. The one `REQUEST-CHANGES` I
  can see in the four PRs I pulled (`#323`, on a `#313` branch carrying no metrics comment of mine) was
  repaired and re-approved in **15 minutes**. Rework latency is not a cost worth optimising here.
- **The `boundary` class merging without a hold.** Every PR I built merged under
  `APPROVE-AND-MERGE-BOUNDARY` and none of the four holds fired spuriously. Building against a gate that
  can finish is materially different from building against one that parks; I would not trade it back.
- **`/code-review` before the MR, and the two-lens verdict.** Both cost me time in-dispatch and both
  caught things at the point where fixing was free. No change.
- **The `--body-file` and one-atomic-call discipline.** Zero permission stalls across 9 dispatches. It is
  invisible when it works, which is why I am naming it.
