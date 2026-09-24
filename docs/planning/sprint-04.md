# sprint-04 — planning

commit: 1afb64578a505fe1e62d911b399fe387c33b0b98
assembled: 2026-09-24  ·  repositories: `tedeuxx/tadeumendonca-skills`, `tedeuxx/tadeumendonca-io`
mode: `scrum` in both repository records (`grep -m1 '^loop-mode: ' docs/loop-mode.md` in each tree)

## The pool as assembled

eligible: 2 · awaiting the owner: 16 · content (not drained): 40

- **eligible** — skills #508, #509. Both were filed on 2026-09-24 from the analysis of the first sprint run inside Codex. The owner selected them for this iteration the same day, and `ready` was applied after that alignment.
- **awaiting the owner** (`ready` absent):
  - skills: #473, #510, #511, #512, #513, #514, #515
  - io: #456, #575, #597, #635, #640, #655, #662, #663, #669
- **content** — 40 io Issues, 14 of them carrying `ready`. Not drained, by rule.

Proposals from `docs/retrospective/`: **none for sprint-03 — no sprint-03 retrospective exists.** This is a finding about the handoff, not an empty result. `ls -d docs/retrospective/*/` returns `sprint-01/` and `sprint-02/` only. The sprint-03 sweep report exists only staged and unpushed in the io working tree (`docs/iteration-sweep/sprint-03.md`), and the sprint-03 funnel review has not run. So **the sprint-03 closing rites are owed**. The owner confirmed this composition knowing that; the activation stated it.

Reproduce:

```sh
for repo in tadeumendonca-skills tadeumendonca-io; do
  gh issue list --repo "tedeuxx/$repo" --state open --limit 200 --json number,title,labels,milestone
done
ls -d docs/retrospective/*/
```

## Estimation

Each item was estimated by its `loop` estimators (`agents-lead` and `quality-assurance`), dispatched in isolation:

| item | agents-lead | quality-assurance | recorded |
|---|---|---|---|
| #508 | 5 | 8 | **8** |
| #509 | 5 | 5 | **5** |

The median of 5 and 8 is 6.5, which is not a Fibonacci value, and no ratified rule rounds a median of two. **8 was recorded — the next value up — as the orchestrator's call**, stated here so it is not read as a rule. The estimators' own reasons agreed that most of #508's size is measurement across a real release rather than code.

## The ranking as returned

## Selection 1 — 2026-09-24
iteration: sprint-04   pool-as-shown: 2 items (eligible), plus 16 non-eligible and 40 `content` named in the brief

### Eligible pool, ranked
1. #508 `loop` `sp:pending` — codex: a patch release blocks every tool call in a running Codex session — the hook path names the removed version — tiebreak only, no ratified rule orders within this class
2. #509 `loop` `sp:pending` — codex: native persona snapshot pinned at 2.0.44 while source is 2.0.79, and nothing says so — tiebreak only, no ratified rule orders within this class

### Process findings (condensed; the full record was returned to the orchestrator)
- The sprint-03 closing rites are owed and did not run in order before this planning: the review is unlanded, the funnel review has not run, and the retrospective is absent.
- The owner's selection preceded this ranking. The ranking adds only a presentation order with known provenance.
- sprint-04 holds no `product` item; nothing a reader can see ships in this iteration.
- At `wip` > 1, both items touch the Codex distribution surface and may collide on files.

### What I could not see
- No ratified rule orders within a class; the intra-class sequence above is a filing-order tiebreak, not a ranking.
- There is no order of record at planning, so the ranking uses the ratified rules alone.
- The mode and `wip` were stated to it, not seen. The pool was shown to it, not queried by it.

## The composition as proposed — every item in the pool, in or out, with why

| # | item | in/out | why |
|---|---|---|---|
| 1 | skills #508 — hook path names the removed version | in | eligible (`loop` AND `ready`); owner selection; first by tiebreak only |
| 2 | skills #509 — persona snapshot pinned at 2.0.44 | in | eligible (`loop` AND `ready`); owner selection; second by tiebreak only |
| — | skills #473, #510–#515 | out | `loop` without `ready` — the owner's transition |
| — | io #456, #575, #597, #635, #640, #655, #662, #663, #669 | out | `product` without `ready` |
| — | io content (40) | out | `content` is selected one piece at a time, never drained |

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

- The sprint-03 closing-rite outputs, which do not exist yet (see *The pool as assembled*). Any proposal a sprint-03 retrospective would produce reaches the next planning instead.
- The repository list was supplied, not derived. A third tree would have been invisible.
