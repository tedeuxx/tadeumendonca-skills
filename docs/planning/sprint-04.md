# sprint-04 — planning

commit: 1afb64578a505fe1e62d911b399fe387c33b0b98
assembled: 2026-09-24  ·  repositories: `tedeuxx/tadeumendonca-skills`, `tedeuxx/tadeumendonca-io`
mode: `scrum` in both repository records (`grep -m1 '^loop-mode: ' docs/loop-mode.md` in each tree)

## The pool as assembled

eligible: 2 · awaiting the owner: 16 · content (not drained): 41

- **eligible** — skills #508, #509. Both were filed on 2026-09-24 from the analysis of the first sprint run inside Codex. The owner selected them for this iteration the same day, and `ready` was applied after that alignment.
- **awaiting the owner** (`ready` absent):
  - skills: #473, #510, #511, #512, #513, #514, #515
  - io: #456, #575, #597, #635, #640, #655, #662, #663, #669
- **content** — 41 io Issues, 13 of them carrying `ready`. Not drained, by rule.

**Correction, found at the lens:** the first push of this file said 40 content Issues, 14 of them `ready`, and the same wrong 40 went into the brief sent to `scrum-master`. It was a hand-count error; no content Issue moved between assembly and the lens. The ranking below is kept verbatim with the wrong figure in it, because the rule is to keep it verbatim. The figure has no effect on the ranking, since content is never in the pool.

Proposals from `docs/retrospective/`: **none for sprint-03 — no sprint-03 retrospective exists.** This is a finding about the handoff, not an empty result. `ls -d docs/retrospective/*/` returns `sprint-01/` and `sprint-02/` only. The sprint-03 sweep report exists only staged and unpushed in the io working tree (`docs/iteration-sweep/sprint-03.md`), and the sprint-03 funnel review has not run. So **the sprint-03 closing rites are owed**. The owner confirmed this composition knowing that; the activation stated it.

Reproduce:

```sh
for repo in tadeumendonca-skills tadeumendonca-io; do
  gh issue list --repo "tedeuxx/$repo" --state open --limit 200 --json number,labels,milestone \
    --jq '[.[]|select(.milestone==null)|(.labels|map(.name)) as $l
           |if ($l|index("content")) then (if ($l|index("ready")) then "content-ready" else "content" end)
            elif (($l|index("product")) or ($l|index("loop"))) then (if ($l|index("ready")) then "eligible" else "awaiting" end)
            else "unrouted" end]
          |group_by(.)|map({(.[0]):length})|add'
done
ls -d docs/retrospective/*/
```

**The tracker is mutable, so this reproduces the live state, not the snapshot.** Run after step 4, it returns 0 eligible in skills, because #508 and #509 now carry milestone 6 and fall outside `milestone==null`. The content classes add up to 41 (28 `content` + 13 `content-ready`).

## Estimation

Each item was estimated by its `loop` estimators (`agents-lead` and `quality-assurance`), dispatched in isolation:

| item | agents-lead | quality-assurance | recorded |
|---|---|---|---|
| #508 | 5 | 8 | **8** |
| #509 | 5 | 5 | **5** |

The median of 5 and 8 is 6.5, which is not a Fibonacci value, and no ratified rule rounds a median of two. **8 was recorded — the next value up — as the orchestrator's call**, stated here so it is not read as a rule. The estimators' own reasons agreed that most of #508's size is measurement across a real release rather than code.

## The ranking as returned

This is `scrum-master`'s hand-back as the orchestrator transcribed it after the lens. **It is not a byte-verified copy.** The first push condensed it, nothing kept the original output as a file, and this transcription is the closest record that exists. It carries the brief's wrong content figure (40 content, 14 `ready`); see the correction above.

```text
## Selection 1 — 2026-09-24
iteration: sprint-04   pool-as-shown: 2 items (eligible), plus 16 non-eligible and 40 `content` named in the brief

### Eligible pool, ranked
1. #508 `loop` `sp:pending` — codex: a patch release blocks every tool call in a running Codex session — the hook path names the removed version — tiebreak only; no ratified rule orders within this class
2. #509 `loop` `sp:pending` — codex: native persona snapshot pinned at 2.0.44 while source is 2.0.79, and nothing says so — tiebreak only; no ratified rule orders within this class

   Excluded from the pool, with the predicate:
   - -skills #473, #510, #511, #512, #513, #514, #515 — `loop`, not `ready` (the owner's transition alone on the `loop` lane, record 0015's Corollary 4)
   - -io #456, #575, #597, #635, #640, #655, #662, #663, #669 — `product`, not `ready`
   - -io `content` (40 items, 14 carrying `ready`) — not drained; `content` is selected by the owner one piece at a time and never batch-drained. None was put in this pool.
   - The #339 loop-before-product rule partitioned nothing here: the eligible set is entirely `loop`, so its whole ordering is the tiebreak.

### Process findings
- **The sprint-03 closing rites are owed and not in evidence in canonical order.** Sprint-03's only admitted item (#499) closed 2026-09-24T01:29Z, so its entry snapshot is exhausted — the terminal condition under `scrum`. The order is `/sprint-review` → `/funnel-review` → `/sprint-retrospective` → `/sprint-planning`, and this planning is running while: the sprint-03 sweep report (`docs/iteration-sweep/sprint-03.md`) exists only staged and unpushed in the -io working tree, so whether that rite completed is not something I can see — only that no landed artifact exists; the funnel review has not run; and `docs/retrospective/` holds only sprint-01 and sprint-02, so there is no sprint-03 retrospective and its proposals are absent from this planning's candidate set. Owed: review and funnel review before the retrospective, and the retrospective before this planning. Nothing sequences these rites and nothing fires them; this record is the only place the gap surfaces.
- **#473 ("the funnel review has never run") sits in awaiting-the-owner while the sprint-03 funnel review is itself unrun.** Those are the same process gap seen from two sides. Named for pairing only — making #473 `ready` is the owner's transition.
- **Both eligible items carry `ready` and neither carries `sp:N`.** The readiness bar includes `sp:N` in both modes; until it lands these two do not meet the bar, and `/autonomy on`'s preflight will refuse on them. The brief says estimates are being produced separately and I am excluded from estimating — the gap is named so the label lands before any drain, not filled here.
- **The owner selected #508 and #509 before this ranking was produced.** That is legitimate — composition is his act — but it means this ranking did not inform the selection and must not be presented as if it had; it contributes only a presentation order with known provenance.
- **sprint-04 carries zero `product` items.** -io has no eligible item; nine `product` Issues await `ready`. "A session with zero product slices is a finding" — at iteration grain, this iteration ships nothing a reader sees. For the owner to know, not a correction to the ranking.
- **Named for later, if this iteration runs at `wip` > 1:** both items are `loop` and both concern the Codex distribution surface (the hook-path pinning and the persona snapshot version), so a file collision between them is likely and the `loop` lane is this repository's worst parallelism candidate. I cannot assess it without their bodies. If both are to run together, whether they touch the same system surface is `tech-lead`'s to answer, and whether they ship independently is `product-lead`'s — for the orchestrator to dispatch, not me.
- Detection, not prevention: this record names who should act and prevents nothing. Nothing reads `SELECTION-RECORD`, and nothing stops the main session acting outside it.

### What I could not see
- No ratified rule orders within a class; the intra-class sequence below is a filing-order tiebreak, not a ranking — here that means #508 before #509 is issue-number order and nothing else, and must not be read as a judgement that #508 is more important or more urgent, whatever its title suggests.
- No order of record exists to rank against at planning — the sprint-04 milestone description is what this rite produces — so I ranked by the ratified rules alone (eligibility, then #339's loop-before-product) plus the declared filing-order tiebreak.
- The mode and `wip` were stated to me, not seen: I was told `scrum` in both repositories from `docs/loop-mode.md`, and I was not shown the `wip:` value.
- I did not see the pool first-hand: it is exactly what the brief listed, as assembled at `1afb6457` (-skills). I cannot tell whether that assembly was truncated or stale.
- I saw no Issue bodies, so no scope, dependency, `invocable:` declaration or file-overlap between #508 and #509 was checkable.
- I did not see the contents of the sprint-03 sweep report or whether it is complete.
- I cannot see whether a sprint-04 milestone already exists in either repository.
- Nothing here is enforced: this record is an influence mechanism, not a control.

SELECTION-RECORD
```

## The composition as proposed — every item in the pool, in or out, with why

| # | item | in/out | why |
|---|---|---|---|
| 1 | skills #508 — hook path names the removed version | in | eligible (`loop` AND `ready`); owner selection; first by tiebreak only |
| 2 | skills #509 — persona snapshot pinned at 2.0.44 | in | eligible (`loop` AND `ready`); owner selection; second by tiebreak only |
| — | skills #473, #510–#515 | out | `loop` without `ready` — the owner's transition |
| — | io #456, #575, #597, #635, #640, #655, #662, #663, #669 | out | `product` without `ready` |
| — | io content (41) | out | `content` is selected one piece at a time, never drained |

Composition: 2 `loop`, 0 `product`, 13 points, all in `tedeuxx/tadeumendonca-skills`. No io milestone is created, because io admits nothing.

## The activation log

**Activation 1**, a structured picker:

- **Question:** "sprint-04: #508 (sp:8) → #509 (sp:5), 13 pts, só loop, no -skills. Fica de fora: 7 loop sem ready + 9 product do -io. Obs.: o fechamento do sprint-03 (review, funnel, retro) segue pendente."
- **Options:** Confirmar · Fechar sprint-03 antes · Alterar · Parar.
- **Answer:** **Confirmar**.

One activation; the bound of two was not reached.

## The composition as confirmed

Milestone `sprint-04` was created as #6 in `tedeuxx/tadeumendonca-skills` by `scripts/milestone-create.sh`, with this description:

```
Order of record (owner-confirmed 2026-09-24; docs/planning/sprint-04.md):
1. #508 codex: a patch release blocks every tool call in a running Codex session — sp:8
2. #509 codex: native persona snapshot pinned at 2.0.44, and nothing says so — sp:5
Sequence within loop is a filing-order tiebreak, not a ranking.
```

Both items were admitted and then read back: `gh issue view <n> --json milestone,labels` returns `6 sprint-04 ready,loop,sp:8` for #508 and `6 sprint-04 ready,loop,sp:5` for #509. No io milestone was created.

## Worklog snapshot

`docs/planning/sprint-04.worklog.json` records the explicit milestone number (6), both counting units, their estimates and provenance, and the timezone. The recorded 8 for #508 sits beside its true median of 6.5. `starts_at` and `ends_at` are `null`, because the owner set no boundary.

## Estimation pendency this leaves

None. Both admitted items carry `ready` and `sp:N`.

## What could not be assembled

- The sprint-03 closing-rite outputs, which do not exist yet (see *The pool as assembled*). **Nothing carries a late sprint-03 retrospective into a later planning.** Step 1 reads only the directory it selects, and at sprint-05 planning that is sprint-04's. A sprint-03 retrospective that lands late is read only if that planning is told to read it.
- The repository list was supplied, not derived. A third tree would have been invisible.
