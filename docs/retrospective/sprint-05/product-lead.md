# sprint-05 — retrospective · product-lead

commit: 01045b660fc31fa6cb4f063fc0c5a2f1aa04db7c (`tadeumendonca-skills`, branch `docs/sprint-05-retrospective`) · 04dcb4ef6b61e4869e40b0f0a095ef30f27ed65a (`tadeumendonca-io`, branch `docs/sprint-05-closing-rites`, the sweep's checkout)
fed-with: my `dispatch-metrics: tadeumendonca-skills:product-lead` comments on `tedeuxx/tadeumendonca-io` #687 (3 records, 3 `dedupe_key`s); my sweep report `docs/iteration-sweep/sprint-05.md` in `tadeumendonca-io` (uncommitted); my funnel report `docs/funnel-review/sprint-05.md` and `docs/funnel-review/collected/sprint-05.tsv`; Issue #687 and PRs #689, #690, #692, #693, #694, #697, #698, #699, #700. I also followed one thread out of the sweep, into PR #686 and its gate verdict, because the sweep's top observation led there.

The working method's source has been `tedeuxx/mhw` since 2026-10-10. Both findings are proposals. The owner rules on them at planning.

## Finding 1 — My copy lens approved a page that carried a false sentence, because I read the diff and not the surface it republished

**What I saw.** The sweep's most consequential observation was that the `/architecture` agent-tier diagram, in both locales, says the `ready` label on a `loop` Issue is *"mine alone to apply"* (PT: *"só eu ponho"*). That has been false since the owner's 2026-09-25 ruling on `-skills` #512: the owner **decides** `ready` on that lane, and the main session **applies** it once aligned with him. I took that as a stale page nobody had touched since the ruling. It is not. PR #686 (`chore(harness): synchronize the one-owner-ask contract`, commit `afd1709`, 2026-09-30) edited that same file and that same diagram five days after the ruling. Its gate verdict records that I reviewed that exact head and returned **APPROVE, with no BLOCKING or ADVISORY findings**.

**The artifacts that show it.**

```
git -C <io> log -3 --format='%h %cs %s' -- apps/fed/src/content/architecture.en.md
# -> afd1709 2026-09-30 chore(harness): synchronize the one-owner-ask contract   (latest)
git -C <io> show afd1709 -U0 -- apps/fed/src/content/architecture.en.md | grep -E '^@@'
# -> hunks at lines 192, 195, 203, 239
git -C <io> show afd1709:apps/fed/src/content/architecture.en.md | grep -n "mine alone"
# -> 132 (the accDescr) and 144 (the RQ box)
gh pr view 686 --repo tedeuxx/tadeumendonca-io --json comments \
  --jq '.comments[]|select(.body|contains("gatekeeper-verdict"))|.body|split("\n")[]|select(test("^\\| 10\\."))'
# -> two rows: "| 10. Content review | **FAIL** | ... no product-lead verdict" (first verdict), then
#    "| 10. Content review and truth | PASS | The product-lead reviewed this exact head and returned APPROVE ..." (second)
```

The false sentence sat 48 to 107 lines from the changed hunks, in the same `flowchart`. In the same `accDescr` the sweep also found the boundary-class sentence (*"comes back to me, and only after my go does it ship"*), which rests on two records that disagree (sweep item 2). That paragraph also says `content-reviewer` *"blocks"* a draft, but since 2026-09-03 it repairs and does not block. I have not checked that third claim beyond reading it against my own brief. It is named so that it gets checked, and it is not offered as a finding.

**What it costs.** I hold one blocking power, and it is about exactly this: a published claim that does not survive checking. I used it on the page and the head where the claim lived, and it did not fire. The page has been wrong in public since at least 2026-09-30. What caught it was the iteration-close sweep, which is advisory, fires on nothing, and runs about two weeks late. The cause is not carelessness, and I want to name it exactly. A `loop` diff that touches reader-facing copy reaches me as a **diff**, so I judged the changed lines. The rule that made the old sentence false changed in the **other repository**, and no diff in `-io` ever touched that sentence. A diff-scoped lens cannot see a claim falsified from outside the diff.

**The change I propose.** When a reader-facing diff edits a block that describes the loop (the `/architecture` diagrams and their `accDescr`, and any page whose subject is the harness), the copy lens re-reads the **whole block** against the current canonical source, and not just the changed lines. That source is the `agents-configuration` states table at the installed plugin version. This is a change to my brief's Check 1 scope, so it is `agents-lead`'s object and the owner's call. The repair of the page itself is a `product` item for the next iteration, already named in the sweep. **The price of leaving it:** every loop ruling made in `-skills` can silently falsify `-io`'s public description of the loop, and the only thing that reads for that is a sweep at iteration close.

## Finding 2 — The only cost records filed under my name this iteration are someone else's work, and intake can never be attributed under the current key

**What I saw.** The dispatch fed me three `product-lead` records on #687, as the rite instructed. Aggregated by the stated rule (group by `dedupe_key`, keep the maximum duration, then sum), they come to **351 s, 47 tool calls and 312 output tokens** across three dispatches. None of the three served #687. The owner's closing comment on #687 says so: they are *"product-lead intakes for #702, #705/#706 and #707 … attributed by the checkout's branch name (`content/687-publish`), not by the Issue the dispatch served."* The timestamps agree. Each record stops about 20 seconds before the Issue it served was created (02:51:07 → #702 at 02:51:30; 02:59:54 → #705/#706 at 03:00:28/30; 03:07:40 → #707 at 03:08:00). Each of those four Issues carries **zero** `product-lead` records.

```
gh issue view 687 --repo tedeuxx/tadeumendonca-io --json comments \
  --jq '[.comments[]|select(.body|contains("dispatch-metrics: tadeumendonca-skills:product-lead"))]|length'   # -> 3
for n in 702 705 706 707; do gh issue view $n --repo tedeuxx/tadeumendonca-io --json createdAt,comments \
  --jq '[.createdAt, ([.comments[]|select(.body|contains("dispatch-metrics: tadeumendonca-skills:product-lead"))]|length)]'; done
# -> each Issue created ~20 s after a record stops, and each carries 0 records
gh pr view 692 --repo tedeuxx/tadeumendonca-io --json mergedAt   # the attributing branch's PR: merged 2026-10-01T00:13:39Z
```

**Why this is structural and not a one-off.** My main act on the `content` lane is intake, and intake drafts the description **before the Issue exists**. At dispatch time there is no Issue number and no branch of its own. A key built on the checkout's branch is therefore wrong for intake by construction. It charges the work to whatever branch the checkout happens to be on, here one whose PR had merged 26 hours earlier.

**What it costs.** The retrospective's whole mechanism is that each persona reasons from its own artifacts. For me, this iteration, the one quantitative artifact was not mine, and following the rite's instruction literally would have produced a confident cost reading of the wrong work. Outside the rite, the per-Issue cost of intake cannot be read, and the escalation standard says a future cost and time calibration will come from these records. That calibration would carry this error into it.

**The change I propose.** This is machinery, so I only recommend it. When the checkout branch's PR **merged before the dispatch began**, the record should say `attribution: unresolved` rather than name that branch's Issue. That is a cheap, falsifiable test, and #692 → these three records is its calibration case. In the rite, step 3 should treat a fed record whose attributing branch was already merged as suspect, and should not feed it as the persona's own. **The price of leaving it:** every intake-heavy persona is fed someone else's numbers at every retrospective, and the error is silent unless the owner happens to annotate it, as he did here.

## What I would leave alone

- **The sweep procedure.** It ran clean on its first attempt after #683 moved the origin into tracked config: 24 / 24 routes emitted and visited, 48 / 48 renders, no mechanical failure. The generator-derived coverage did its job. The count moved from 22 to 24 and the report says why. The 7 neutral share URLs being checked over HTTP only is a real gap, but the procedure itself names it, and it is not urgent.
- **My absence from the `content` copy lane, even though #687 took nine PRs and a release that went ahead before the owner had validated it (#692 → #693).** I read the owner-correction comments. They are art direction, the opening and epigraph, image placement, and a missed approval step. They are his voice and the gate's sequencing, not truth findings my Checks would have raised. The 2026-09-03 ruling stands. I am not re-entering the lane through a retrospective.
- **The funnel rite's two findings, and the routing of their fixes to `tech-lead`.** Owner-traffic exclusion and landing-page attribution are measurement design. The report already says that nothing this period is evidence about the voice, and that is the right reading with n = 1 to 2 users per edition.
