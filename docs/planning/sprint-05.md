# sprint-05 — planning

commit: 7bc43b4307683d0a2443f69b489c2980353e8bae
assembled: 2026-09-25  ·  repositories: `tedeuxx/tadeumendonca-skills`, `tedeuxx/tadeumendonca-io`
mode: `scrum` in both repository records · `wip: 2` (`docs/loop-mode.md`)

## The pool as assembled

eligible: 12 · awaiting the owner: 9 · content (not drained): 41

- **eligible**: all in skills, all `loop`, all `ready` with `sp:N` — #473, #510, #511, #512, #513, #514, #515, #521, #522, #523, #524, #525 (61 points).
- **awaiting the owner**: io `product` without `ready` — #456, #575, #597, #635, #640, #655, #662, #663, #669.
- **content**: 41 io Issues, 13 `ready`. Not drained, by rule.

Proposals from `docs/retrospective/sprint-04/`: 6 findings across 3 persona files. **All six had already become Issues before this planning ran.** The owner ruled «pode incorpora-los e estima-los» on 2026-09-24: #521–#525 were filed, and the funnel proposal went onto #473 as a comment. So they arrive here as eligible items, not as candidates. The sprint-04 sweep (-io `docs/iteration-sweep/sprint-04.md`) is FAILED, and its judgement findings were not filed.

Reproduce (live tracker). After step 4 the skills line prints **nothing** and exits 0: no open skills Issue is left without a milestone, and `gh` prints nothing when `jq` returns null. That silence is the expected result, not a broken query.

```sh
for repo in tadeumendonca-skills tadeumendonca-io; do
  gh issue list --repo "tedeuxx/$repo" --state open --limit 200 --json number,labels,milestone \
    --jq '[.[]|select(.milestone==null)|(.labels|map(.name)) as $l
           |if ($l|index("content")) then (if ($l|index("ready")) then "content-ready" else "content" end)
            elif (($l|index("product")) or ($l|index("loop"))) then (if ($l|index("ready")) then "eligible" else "awaiting" end)
            else "unrouted" end]
          |group_by(.)|map({(.[0]):length})|add'
done
```

## Estimation

Each item was estimated by its `loop` estimators (`agents-lead`, `quality-assurance`), each dispatched in isolation. Where the two estimates differed, the orchestrator recorded the next Fibonacci value at or above their median. This is the same call it made at sprint-04, and it is still not a ratified rule.

| item | agents-lead | quality-assurance | recorded |
|---|---|---|---|
| #473 | 8 | 8 | 8 |
| #510 | 2 | 2 | 2 |
| #511 | 5 | 8 | 8 (median 6.5) |
| #512 | 5 | 5 | 5 |
| #513 | 5 | 8 | 8 (median 6.5) |
| #514 | 3 | 3 | 3 |
| #515 | 8 | 8 | 8 |
| #521 | 5 | 3 | 5 (median 4) |
| #522 | 5 | 5 | 5 |
| #523 | 2 | 2 | 2 |
| #524 | 2 | 2 | 2 |
| #525 | 5 | 5 | 5 |

## The ranking as returned

Verbatim: this is `scrum-master`'s `SubagentHandback.message`, copied byte for byte from the dispatch's session transcript by a script (`subagents/agent-ac574362ea322261a.jsonl`, local and untracked). The only change is the fence around it.

```text
## Selection 1 — 2026-09-25
iteration: sprint-05   pool-as-shown: 12 items (all `tedeuxx/tadeumendonca-skills`, all `loop`; `tedeuxx/tadeumendonca-io` eligible: none)

### Eligible pool, ranked
1. #473 `loop` `sp:8`: the funnel review never ran, plus a pre-dispatch browser check. Tiebreak only; no ratified rule orders within this class.
2. #510 `loop` `sp:2`: AGENTS.md should use one instance per dispatch. Tiebreak only; no ratified rule orders within this class.
3. #511 `loop` `sp:8`: a sprint token cost breakdown for Codex. Tiebreak only; no ratified rule orders within this class.
4. #512 `loop` `sp:5`: AGENTS.md should carry the owner's cross-harness standing rules. Tiebreak only; no ratified rule orders within this class.
5. #513 `loop` `sp:8`: dispatch-metrics has recorded nothing since 2026-09-10. Tiebreak only; no ratified rule orders within this class.
6. #514 `loop` `sp:3`: continuity between sessions has no home. Tiebreak only; no ratified rule orders within this class.
7. #515 `loop` `sp:8`: defects in the worklog (#499). Tiebreak only; no ratified rule orders within this class.
8. #521 `loop` `sp:5`: the hold 2 predicate misses Codex machinery, and `.codex/config.toml` sets WIP=1. Tiebreak only; no ratified rule orders within this class.
9. #522 `loop` `sp:5`: hold 2 carry-forward. Tiebreak only; no ratified rule orders within this class.
10. #523 `loop` `sp:2`: a QA blocking-class finding should enumerate the whole class. Tiebreak only; no ratified rule orders within this class.
11. #524 `loop` `sp:2`: QA should record the post-install owner action on the Issue. Tiebreak only; no ratified rule orders within this class.
12. #525 `loop` `sp:5`: `/sprint-review` should check the sweep origin before dispatch. Tiebreak only; no ratified rule orders within this class.

Excluded from the pool, and why:
- `-io` #456, #575, #597, #635, #640, #655, #662, #663, #669 are `product` items without `ready`, so they fail the `ready` limb and are waiting on the owner.
- The `-io` `content` items (41 in total, 13 of them `ready`) are never drained. The owner selects them one at a time, and none was placed in this pool.

Rule applied: loop comes before product (#339). There are no eligible `product` items, so that rule sorts nothing here. The whole order comes from the filing-order tiebreak.
Points check: 8+2+8+5+8+3+8+5+5+2+2+5 = 61. This matches the owner's «pode por tudo», 61 points.

(`### Selection` is omitted because this is a planning dispatch.)

### Process findings
- **The tiebreak order runs against one stated dependency.** The estimators say #511 depends on #512, but by filing order #511 is at position 3 and #512 at position 4. I did not re-rank, as instructed. Whoever composes the order of record needs to decide whether #512 goes first. The tiebreak cannot say.
- **The other dependency agrees with filing order.** #522 depends on #521, and #521 comes first (positions 8 and 9). At `wip: 2` the two must not be selected into the same set. #522 cannot pass the `non-collision:` criterion while #521 is unmerged.
- **#510 and #512 both edit `AGENTS.md`, so they collide at `wip: 2`.** They cannot share a set. Because #511 depends on #512, all three form one serial chain on or next to the same file.
- **#525 and #473 share a pre-dispatch-check pattern.** Whether that is one piece of system surface is a question for `tech-lead`, not for me. Whether they ship independently is a question for `product-lead`. I cannot answer either. They are named here so they get answered before these two are paired in a set.
- **This pool is the worst case for parallel work.** It is all `loop`, and `loop` items converge by construction on a few files: `inventory-counts.test.sh`, `permission-guard.*`, `README.md`, `CLAUDE.md` and `agents-configuration`. At `wip: 2`, expect many selections to come back as one item plus a stated reason, not two. A smaller set is the right answer here, not a colliding one. Composition planning only prevents merge conflicts. The composition hazard is covered by the serial gate plus a rebase onto the moved trunk, and nothing enforces that rebase (#484/#488).
- **Closing rites for sprint-04 look incomplete in substance.** All three artifacts exist. However, the sprint review's sweep (`-io` `docs/iteration-sweep/sprint-04.md`) FAILED at its first navigation, and the funnel review (`docs/funnel-review/sprint-04.md`) is NOT-COLLECTED. So the retrospective ran without either of its two upstream inputs having produced observations. An artifact existing is not the same as a rite running. This is reported as a process fact; #473 and #525 in the pool are the owner's response to it.
- **I cannot verify the order of the rites.** The required order is `/sprint-review` → `/funnel-review` → `/sprint-retrospective` → `/sprint-planning`. I was shown that each artifact exists but not when each was written. If the retrospective came before either report, its consulted personas could not have read them.
- **The retrospective consult set has three personas.** `docs/retrospective/sprint-04/` holds agents-lead, quality-assurance and product-lead files. Whether that was the correct derived set, or a shortened one, cannot be told from the tracker. The rite's own text says so.
- **Several retrospective findings target the gate.** Findings #521–#525 were filed at iteration close as the owner's act, per #365, so their entry at planning follows the rule. Three of them (#521, #522, #523/#524) change QA and hold 2 behaviour. Any machinery finding about them belongs to `agents-lead`, not to this record.
- **No limit on sprint size applies.** The owner admitted all 61 points, and nothing in this loop bounds how many items one iteration takes. Whether the carry-over count shows over-filling is for next iteration's metrics. #513 reports that the dispatch-metrics instrument has recorded nothing since 2026-09-10. That weakens the evidence behind `wip: 2` (the 2.5% builder-share figure) for anything measured after that date.
- **Only `-skills` is contributing items.** `-io` contributes no eligible items, so sprint-05 may exist as a milestone in `-skills` only. If a `-io` milestone is created, the two titles have to match exactly (`sprint-05`), because nothing checks that they agree.
- **Main session acting instead of delegating (object 4):** nothing to report at planning, since no work is dispatched. This record detects that failure; it cannot prevent it.

### What I could not see
- No ratified rule orders items within a class. The sequence inside `loop` is a filing-order tiebreak (issue number ascending), not a ranking. Because there are no eligible `product` items, loop-first ordered nothing, so every position above comes from the tiebreak.
- There is no order of record for sprint-05 yet, because this rite creates it. Nothing was checked against a milestone description.
- I did not read `docs/loop-mode.md` in either repository. `scrum` and `wip: 2` are as stated in the dispatch.
- I saw one-line summaries, not Issue bodies or file lists. Every collision and dependency above is the estimators' statement or a prediction, not a measurement. Pairs not named above are UNASSESSED, not cleared.
- I cannot query the tracker. I cannot confirm the pool is complete or current as of `7bc43b43`, or that all twelve carry `ready` and exactly one `sp:` label.
- I did not see the contents of the rite artifacts: the three retrospective files, `00-scope.md`, the failed sweep report or the funnel report. I did not see their timestamps either, so the rite-order finding is limited to that.
- Nothing reads this record, `SELECTION-RECORD` has no consumer, and nothing checks the pool I was shown. It is an influence mechanism, not a control.

SELECTION-RECORD
```

## The composition as proposed — every item in the pool, in or out, with why

| # | item | in/out | why |
|---|---|---|---|
| 1–12 | skills #473, #510, #511, #512, #513, #514, #515, #521, #522, #523, #524, #525 | in | eligible (`loop` AND `ready` AND `sp:N`); owner ruling «pode por tudo»; order is the filing-order tiebreak only |
| — | io #456, #575, #597, #635, #640, #655, #662, #663, #669 | out | `product` without `ready` |
| — | io content (41) | out | `content` is selected one piece at a time, never drained |

Composition: 12 `loop`, 0 `product`, 61 points, all in `tedeuxx/tadeumendonca-skills`. No io milestone is created, because io admits nothing.

**The dependencies are execution constraints, not an ordering rule.** They are stated on the Issues, and the ranking names them:

- #522 depends on #521.
- #511 depends on #512. The tiebreak puts #511 first, so the drain takes #512 before #511.
- #510 and #512 both edit `AGENTS.md`, so they cannot share a `wip: 2` set.

The order of record below is still the tiebreak. The drain honours these constraints when it selects, and says so when it does.

~~**Size.** 61 points is roughly five times any earlier iteration (8, 13).~~ **Struck at the lens: false.** Summing today's `sp:` labels per milestone gives:

- `-skills`: sprint-01 = 72 (13 items), sprint-02 = 29, sprint-03 = 8, sprint-04 = 13;
- `-io`: sprint-01 = 20, sprint-02 = 11.

So 61 is the second-largest iteration, not a fivefold outlier. The labels are read today, not as they stood at each planning. Nothing in the loop bounds an iteration's size. The ranking's own finding is that an all-`loop` pool is the worst case for `wip: 2`.

## The activation log

The owner composed this iteration himself, across two turns on 2026-09-24 and 2026-09-25:

1. «aplica ready em tudo» — `ready` on all twelve.
2. Asked which items enter sprint-05, in a picker whose options were three partial sets. He answered in free text: «pode por tudo».

~~That answer is the confirmation of this composition. No separate composition activation was put to him, because the composition he confirmed is the whole eligible pool with nothing left to compose.~~ **Struck at the lens: false.** «pode por tudo» (12:37:08Z) answered an **admission** question, and it was asked **before** the ranking (dispatched 12:37:23Z, returned 12:38:11Z). He ruled on membership. The order and the execution constraints did not exist yet, so he could not have confirmed them.

**Activation 2** — the confirmation over the finished composition, put after the lens found the gap. It was a structured picker:

- **Question:** "sprint-05 composto: 12 loop, 61 pts, ordem por nº da Issue; restrições: #512 antes de #511, #521 antes de #522, #510 e #512 nunca em paralelo. Confirma?"
- **Options:** Confirmar · Parar.
- **Answer:** **Confirmar**.

Two activations: the admission, then the confirmation. That is the rite's bound of two, reached and not exceeded. The placement (step 4) ran **between** them, before the composition was confirmed. That ordering is a defect in how this rite was run, and it is recorded here rather than repaired, because a confirmation cannot be backdated.

**The milestone description on the tracker still reads "Order of record (owner-confirmed 2026-09-25 «pode por tudo» …)".** That attribution is wrong: the owner admitted the items with «pode por tudo» and confirmed the order afterwards. It is not corrected there, because no milestone-update route is built (`commands/sprint-planning.md`, step 4) and `gh api` is denied. The owner can fix it in the browser; this file is the correct record.

## The composition as confirmed

Milestone `sprint-05` was created as #7 in `tedeuxx/tadeumendonca-skills` by `scripts/milestone-create.sh`. Its description:

```
Order of record (owner-confirmed 2026-09-25 «pode por tudo»; docs/planning/sprint-05.md), filing-order tiebreak, not a ranking:
#473 sp:8 · #510 sp:2 · #511 sp:8 · #512 sp:5 · #513 sp:8 · #514 sp:3 · #515 sp:8 · #521 sp:5 · #522 sp:5 · #523 sp:2 · #524 sp:2 · #525 sp:5 — 61 pts.
Execution constraints: #512 before #511; #521 before #522; #510 and #512 never in one wip set.
```

All twelve were admitted, then read back one Issue at a time: `gh issue view <n> --json milestone` returns milestone `7` for each.

**A measurement trap met on the way.** Run immediately after the admissions, `gh issue list --milestone sprint-05` returned **8** of the 12. That query goes through the search index, which lags behind writes. Read back per Issue, the milestone was set on all twelve. Do not use the milestone-filtered list to verify an admission made seconds earlier.

## Worklog snapshot

`docs/planning/sprint-05.worklog.json` holds:

- milestone number 7;
- twelve counting units, 61 points;
- per unit, the isolated estimates, the true median and the recorded value where they differ;
- the timezone.

`starts_at` and `ends_at` are `null`, because the owner set no boundary.

## Estimation pendency this leaves

None. All twelve carry `ready` and exactly one `sp:N`.

## What could not be assembled

- The sprint-04 sweep observed nothing rendered, and the funnel collected nothing. The retrospective's inputs from those two rites were therefore empty. See #525 and #473, which are in this iteration.
- The repository list was supplied, not derived.
