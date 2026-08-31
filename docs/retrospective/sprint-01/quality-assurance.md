# sprint-01 — retrospective · quality-assurance

commit: 4b4df699fce75a867c81f3949400d5d0b29e4893
fed-with: `docs/retrospective/sprint-01/00-scope.md` · my own `dispatch-metrics:
tadeumendonca-skills:quality-assurance` comments on `-skills` #313 #342 #355 · my
`gatekeeper-verdict: quality-assurance` markers on `-skills` PRs #345 #346 #354 #356 and on `-io`
PRs #564 #570 #571 #573 · `hooks/scripts/dispatch-metrics-stop.sh` at head · the `sprint-01`
milestone enumeration in both repositories · `gh issue list` / `gh pr list` over the merge window

---

## Finding 1 — the one mechanism that could supply my round counter has never once fired, and it prints a plausible value on every dispatch

**[delivery]**

**What I saw.** `hooks/scripts/dispatch-metrics-stop.sh` computes a `rework_rounds_so_far` field and
gates that computation on the persona:

```
# hooks/scripts/dispatch-metrics-stop.sh:181-195
rework_rounds="n/a (not a gatekeeper dispatch)"
case "$agent_type" in
  quality-assurance|agents-lead)
```

`agent_type` is namespaced. Line 100 of the same script reads it straight from the payload, and the
value it then writes into its own comment body two dozen lines later is
`tadeumendonca-skills:quality-assurance`. **The bare-name arm cannot match the namespaced value it
is fed by the same script**, so the `case` falls through on every dispatch of every persona and the
field is a constant.

**The artifact that shows it.** Every `dispatch-metrics` comment on the two highest-volume Issues of
this iteration, grouped by that field's value:

```
gh issue view 313 --repo tedeuxx/tadeumendonca-skills --json comments \
  --jq '[.comments[]|select((.body//"")|contains("dispatch-metrics:"))
          |((.body|split("\n"))|map(select(startswith("rework_rounds_so_far:")))[0])]
        |group_by(.)|map({(.[0]):length})|add'
→ {"rework_rounds_so_far: n/a (not a gatekeeper dispatch)":29}

# same command, #342
→ {"rework_rounds_so_far: n/a (not a gatekeeper dispatch)":18}
```

47 of 47, including the 9 `quality-assurance` and 6 `agents-lead` dispatches the scope record counts
on #313 and the 6 on #342. **The falsifier is one numeric value in that field on any dispatch of
either gate persona, in either repository, in this iteration — there is none.**

The same file's own floor gets it right, which is what makes this a slip rather than a design
choice: `permission-guard.sh:1067` spells the identical test `*:quality-assurance)`.

**What it costs.** Three things, and the third is the one that matters most to this gate.

1. **My round budget is unmeasurable.** `agents/quality-assurance.md` gives me two rounds and
   obliges a decision request from the third, then tells me I cannot derive the count and must say
   so when it is not supplied. The one artifact that could have supplied it has never produced a
   number. Measured by hand from my own markers, `-skills` PR #356 and `-io` PR #571 each took two
   rounds — neither is counted anywhere.
2. **It is a green that proves nothing**, which is the failure class `/harness-engineering` names
   this discipline for. The field is present, populated, and reads as a checked value; a reader
   drawing a rework series off these comments would get a flat line of `n/a` and conclude the loop
   never reworked anything.
3. **It is the scope record's own limit 2, occurring inside the script that creates the namespace.**
   That record warns a consumer matching the bare name gets nothing. The first consumer to make that
   mistake was this hook, and nothing caught it for the whole iteration — `grep -rn "rework_rounds"
   hooks/` returns five lines, all in the script itself and none in any `*.test.sh`.

**The change I propose.** Change the arm to `*:quality-assurance|*:agents-lead)` — the spelling
`permission-guard.sh` already uses — and add a `dispatch-metrics-stop.test.sh` arm feeding a
namespaced `agent_type` and asserting the field is **not** the `not a gatekeeper dispatch` constant.
Without the test the fix is invisible again on the next rename, because the defect's whole signature
is a field that looks answered. **Then sweep the rest**: every `agent_type` comparison in
`hooks/scripts/` that is not prefixed `*:` is the same bug waiting for its first reader. I checked
the two gate-relevant ones; I did not sweep the tree exhaustively and am not claiming it is clean.

**Price of leaving it:** the round budget stays a rule enforced by nobody, on the persona whose brief
says an invented number is the defect the rule exists to prevent.

---

## Finding 2 — the iteration records the loop's own work faithfully and the product's partially, and every item it misses is reader-facing

**[delivery] and [production] — it is genuinely both, and the second half is why I am reporting it
rather than leaving it to whoever owns the metric.**

**What I saw.** In `tadeumendonca-skills` the axis is airtight: every Issue closed inside the sprint
window carries the milestone. In `tadeumendonca-io` it is not, and the miss is not random.

**The artifacts.** Window taken from the `-io` half's own first and last sprint merges (PR #530,
2026-08-27T13:50 → PR #573, 2026-08-29T12:21), so it is derived from the enumeration rather than
chosen:

```
gh pr list --repo tedeuxx/tadeumendonca-io --state merged --limit 100 --json number,mergedAt \
  --jq '[.[]|select(.mergedAt>="2026-08-27T13:50:00Z" and .mergedAt<="2026-08-29T12:22:00Z")]|length'
→ 19

gh issue list --repo tedeuxx/tadeumendonca-io --state closed --limit 200 \
  --json number,closedAt,milestone \
  --jq '[.[]|select(.closedAt>="2026-08-27T13:50:00Z" and .closedAt<="2026-08-29T12:22:00Z")]
        |group_by(.milestone!=null)
        |map({(if .[0].milestone!=null then "milestoned" else "no-milestone" end):length})|add'
→ {"milestoned":3,"no-milestone":12}

# the same predicate on tadeumendonca-skills, over its own window
→ {"milestoned":12}
```

**All twelve unmilestoned issues carry `reader-facing`**, and two of them carry an estimate:

```
gh issue list --repo tedeuxx/tadeumendonca-io --state closed --limit 200 \
  --json number,closedAt,milestone,labels \
  --jq '[.[]|select(.closedAt>="2026-08-27T13:50:00Z" and .closedAt<="2026-08-29T12:22:00Z")
          |select(.milestone==null)|{n:.number,l:(.labels|map(.name))}]'
→ #566 #559 #558 #555 #548 #544 #543 #540 #539 #538 (product/content + reader-facing)
   #473 (sp:8) #380 (sp:13)
```

**21 estimated points shipped outside the iteration in that window; the whole `-io` half of
`sprint-01` sums to 20** (5+5+8+2, #572 unestimated). The falsifier is a milestone on any of those
twelve, or a second milestone object in that repository holding them — the scope record's own
enumeration shows neither.

**What it costs — the delivery half.** `/harness-engineering` names three surviving consumers of the
iteration axis once the terminal condition moved off it: the preflight's pendency set, the closing
ceremonies' scope, and the tracker's completion bar. In `-io` all three are computed over a fifth of
what closed. A points-per-week rate drawn from this is not a rate of what the loop produced — it is a
rate of what happened to be composed in, and it will read as the former on a repository whose thesis
is rigor. This is the shape of defect I am asked to catch: a number whose base does not answer the
question it is published under.

**What it costs — the production half, which is the sharper one.** The class that fell outside is
exactly the class with the shortest reversal window: banners, captions, headlines, published copy.
An OG card pinned by a scraper on first fetch is not recovered by a later correction — this
repository has already written that down as a named residual of the boundary-merge decision, whose
booked compensation is *the owner reviews live, after deploy*. The retrospective's scope is the
iteration, and the sprint review half is unbuilt; so the work most needing a post-deploy look is the
work sitting outside the only closing ceremony that exists. **Nothing in this is a rule break** —
#365 made composition an owner act at planning, and these items were worked between plannings, which
is the system behaving as designed. That is what makes it worth a finding rather than a correction.

**The change I propose**, smallest first, because I am closing a slice rather than opening a
programme:

- **State the denominator wherever the axis is read.** The completion bar and any points series
  should be published beside the count of items closed in the same window with no milestone —
  one `jq` over a query the pool predicate already runs. A metric that names what it excludes is
  honest at a fraction of the cost of a metric that covers everything.
- **Do not propose forcing a milestone at filing.** That is the rule #365 struck for a reason the
  owner stated in his own words, and reversing it to fix a reporting gap would trade a human decision
  for a tidier chart.
- **Price of leaving it as-is:** the axis keeps meaning two different things in the two repositories
  — a full record in `-skills`, a sample in `-io` — and the first person to compare velocity across
  them will be comparing a total to a sample without any artifact telling them so.

---

## What I would leave alone

- **The gate merging the boundary class.** Across the eight PRs I sampled I posted ten verdicts:
  eight approvals, of which **seven** are `APPROVE-AND-MERGE-BOUNDARY`, plus two `REQUEST-CHANGES`.
  (A sample of eight, not the iteration's full PR set — the count is what I re-read, not a total.)
  The retired hold would have queued nearly all of that behind the owner. The four surviving holds are the part that carries the weight and
  they held: nothing in `iac/` moved, and the two-round PRs (`-skills` #356, `-io` #571) both went
  `REQUEST-CHANGES` then boundary-approve rather than being waved through.
- **The `dispatch-metrics` lower bound, and the honesty of stating it.** The scope record records
  zero `quality-assurance` dispatches in `-io`; I posted four verdict markers there. The bound is not
  a defect in that record — it is the record being right about itself, and it is the reason I could
  reconstruct my own `-io` work at all. Do not "fix" it by trusting the counts.
- **The two-finding cap.** I found more than two things worth saying and this file contains two.
  That is the cap working, and I would rather it stayed uncomfortable than became a quota.
- **The retrospective's file-per-persona shape.** It cost a branch, a PR and a gate pass, and it is
  the only reason my answer is not being summarised by the one context that saw the whole iteration.
