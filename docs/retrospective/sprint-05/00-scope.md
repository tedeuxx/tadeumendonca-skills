# sprint-05 — retrospective scope

commit: 01045b660fc31fa6cb4f063fc0c5a2f1aa04db7c
measured: 2026-10-10

This file holds query output only: no findings, and nobody's artifacts were read for it. Every figure
was re-run for this record; none is carried from the dispatch brief. Where a re-run disagreed with the
brief, the re-run is published and the disagreement is named.

## 1 · The iteration in both repositories, and what was open when the rite ran

The two milestones were read by number with the reviewed reader:

```sh
python3 scripts/milestone-read.py 7 --repo tedeuxx/tadeumendonca-skills
python3 scripts/milestone-read.py 3 --repo tedeuxx/tadeumendonca-io
```

| repository | milestone | title | state | open | closed |
|---|---|---|---|---|---|
| `tadeumendonca-skills` | 7 | sprint-05 | open | **0** | 15 |
| `tadeumendonca-io` | 3 | sprint-05 | open | **0** | 4 |

Both milestones are still `open` as objects; both hold **0 open Issues**.

The members, enumerated from the returned Issues. No milestone name was passed to a query as a filter:

```sh
gh issue list --repo tedeuxx/tadeumendonca-skills --state all --limit 300 --json number,milestone,state,stateReason,labels \
  --jq '[.[]|select(.milestone!=null and .milestone.number==7)|{n:.number,s:.state,r:.stateReason,l:[.labels[].name]}]|sort_by(.n)'
gh issue list --repo tedeuxx/tadeumendonca-io --state all --limit 300 --json number,milestone,state,stateReason,labels \
  --jq '[.[]|select(.milestone!=null and .milestone.number==3)|{n:.number,s:.state,r:.stateReason,l:[.labels[].name]}]|sort_by(.n)'
```

| repository | Issues | all `CLOSED` / `COMPLETED` |
|---|---|---|
| `-skills` (15) | #510 #511 #512 #513 #514 #515 #521 #522 #523 #524 #525 #531 #536 #537 #538 | yes |
| `-io` (4) | #680 #682 #683 #687 | yes |

**19 Issues in the iteration.** All 15 `-skills` Issues and three of the four `-io` Issues carry `loop`;
`-io` #687 carries `content`.

### How the milestone emptied: by owner ruling, not by draining

On 2026-10-10, before this rite, the owner ruled that the method now lives in `tedeuxx/mhw` and that
`-skills` becomes the plugin's distribution. On that ruling the owner cancelled `-skills` #552, and the
orchestrator removed #547 and #473 from the milestone. The order of record in milestone 7's
description still lists #473 and #552, which the member list above no longer contains.

The closures that are visible to a query:

```sh
gh issue list --repo tedeuxx/tadeumendonca-skills --state closed --limit 100 --search "closed:>=2026-10-10" \
  --json number,stateReason,closedAt,milestone --jq '.[]|{n:.number,r:.stateReason,c:.closedAt,m:(.milestone.title//null)}'
```

| Issue | reason | closed (UTC) | milestone now |
|---|---|---|---|
| #552 | NOT_PLANNED | 16:27:49 | none |
| #547 | NOT_PLANNED | 16:32:51 | none |
| #551 | NOT_PLANNED | 16:32:55 | none |
| #554 | NOT_PLANNED | 16:32:59 | none |
| #555 | NOT_PLANNED | 16:33:02 | none |
| #550 | NOT_PLANNED | 16:33:06 | none |
| #556 | NOT_PLANNED | 16:33:11 | none |
| #557 | NOT_PLANNED | 16:33:15 | none |
| #533 | NOT_PLANNED | 16:33:19 | none |

**The query returns nine, the brief said eight.** The nine include #552, the owner's own cancellation,
closed about five minutes before the other eight. Without #552 the batch is eight: #533, #547, #550,
#551, #554, #555, #556, #557.

**#473 and #553 no longer resolve in `-skills`.** `gh issue view 473` and `gh issue view 553` against
`tedeuxx/tadeumendonca-skills` return *"Could not resolve to an issue or pull request"*. In
`tedeuxx/mhw` both #128 and #129 exist and are open:

```sh
gh issue view 128 --repo tedeuxx/mhw --json number,state,createdAt   # -> OPEN, created 2026-09-19T16:47:55Z
gh issue view 129 --repo tedeuxx/mhw --json number,state,createdAt   # -> OPEN, created 2026-09-30T20:57:39Z
```

The mapping #473 → mhw#128 and #553 → mhw#129 is the orchestrator's account. These commands do not
check it: they show that the two numbers stopped resolving in `-skills` and that two open Issues exist
in `tedeuxx/mhw`. **That #547 and #473 were once in milestone 7 also comes from the account, not from a
query:** the Issue reads available here return only the current milestone, which is none for #547.

## 2 · `loop` items with NO milestone

```sh
gh issue list --repo tedeuxx/tadeumendonca-skills --state open --label loop --limit 200 --json number,milestone \
  --jq '{open_loop:length, unmilestoned:[.[]|select(.milestone==null)|.number]}'
# -> {"open_loop":0,"unmilestoned":[]}
gh issue list --repo tedeuxx/tadeumendonca-io --state open --label loop --limit 200 --json number,milestone \
  --jq '{open_loop:length, unmilestoned:[.[]|select(.milestone==null)|.number]}'
# -> {"open_loop":0,"unmilestoned":[]}
```

**`tadeumendonca-skills`: 0. `tadeumendonca-io`: 0.**

Calibration, so neither zero comes from a dead selector:

```sh
gh issue list --repo tedeuxx/tadeumendonca-skills --state all --label loop --limit 300 --json number --jq 'length'   # -> 137
gh issue list --repo tedeuxx/tadeumendonca-io --state all --label loop --limit 300 --json number --jq 'length'       # -> 7
gh issue list --repo tedeuxx/tadeumendonca-skills --state open --limit 300 --json number --jq 'length'               # -> 0
gh issue list --repo tedeuxx/tadeumendonca-io --state open --limit 300 --json number --jq 'length'                   # -> 63
```

The label matches Issues in both repositories. `-skills` has **no open Issue of any type**. `-io` has
63 open Issues, none carrying `loop`.

## 3 · The derived consult set — a LOWER BOUND

### First source: the dispatch-metrics records

The canonical per-Issue query from `commands/sprint-retrospective.md` step 2, run on all 19 Issues. A
second query groups on `dedupe_key`, because each record is cumulative at one stop rather than one
record per dispatch:

```sh
gh issue view <n> --repo <owner>/<repo> --json comments \
  --jq '[.comments[]|select((.body//"")|contains("dispatch-metrics:"))
          |((.body|split("\n")[0])|capture("dispatch-metrics: (?<a>[^ ]+)").a)]
        |group_by(.)|map({(.[0]):length})|add // {}'
gh issue view <n> --repo <owner>/<repo> --json comments \
  --jq '[.comments[]|select((.body//"")|contains("dispatch-metrics:"))|.body
          |{a:(capture("agent_type: (?<x>[^\n]+)").x),k:(capture("dedupe_key: (?<x>[^\n]+)").x)}]
        |group_by(.a)|map({(.[0].a):(map(.k)|unique|length)})|add // {}'
```

| Issue | comments per `agent_type` | distinct `dedupe_key` per `agent_type` |
|---|---|---|
| `-skills` #511 | agents-lead 23 · quality-assurance 8 | agents-lead 23 · quality-assurance 6 |
| `-skills` #513 | agents-lead 14 · quality-assurance 4 | agents-lead 14 · quality-assurance 4 |
| `-io` #687 | agents-lead 1 · product-lead 3 · quality-assurance 2 | agents-lead 1 · product-lead 3 · quality-assurance 2 |
| the other 16 | `{}` | `{}` |

The `agent_type` values are namespaced (`tadeumendonca-skills:<persona>`). On #511 the two queries
disagree for `quality-assurance` (8 comments, 6 distinct keys).

**Records exist on 3 of the 19 Issues, so 16 carry none. The brief said 15 of 19.** The 16 are `-skills`
#510, #512, #514, #515, #521, #522, #523, #524, #525, #531, #536, #537, #538 and `-io` #680, #682, #683.
That matches an iteration worked largely in Codex, which emits no records (step 2, limit 6). The query
does not show which harness ran any given Issue.

**At least these ran, per the records: `agents-lead`, `quality-assurance`, `product-lead`.**

### Second source: verdict markers on PRs merged 2026-09-25..2026-10-10

```sh
gh pr list --repo tedeuxx/<repo> --state merged --search "merged:2026-09-25..2026-10-10" --limit 200 \
  --json number,comments \
  --jq '{prs:length,
         gatekeeper:([.[]|select(any(.comments[];.body|contains("<!-- gatekeeper-verdict:")))|.number]|length),
         harness:([.[]|select(any(.comments[];.body|contains("<!-- harness-lead-verdict:")))|.number]|length),
         product_lead_calibration:([.[]|select(any(.comments[];.body|contains("<!-- product-lead-verdict:")))|.number]|length)}'
```

| repository | merged PRs | `gatekeeper-verdict` | `harness-lead-verdict` | `product-lead-verdict` (calibration) |
|---|---|---|---|---|
| `-skills` | 20 | 20 | 20 | 0 |
| `-io` | 16 | 16 | 6 | 0 |

The PRs: `-skills` #526–#530, #532, #534, #535, #539–#546, #548, #549, #558, #559; `-io` #681, #684–#686,
#689, #690, #692–#694, #697–#701, #711, #713. The calibration column returns 0 because no such marker
exists, which shows the selector can return zero. The window selects by merge date, so a PR reviewed in
the iteration and merged after 2026-10-10 is outside it.

This source attests `quality-assurance` (gatekeeper) and `agents-lead` (harness) only. It adds no
persona the records did not already name.

### Hand-added, on artifact evidence rather than on either instrument

- **`content-reviewer`.** Four files matching `docs/content-review/ai-answers-in-seconds-you-dont-have-to*.md`
  were touched on `-io` `origin/main` (`45de58a58cea901bfa8fbd3fba6e9e352664969d`) since 2026-09-25:

  ```sh
  git -C <-io checkout> log origin/main --since=2026-09-25 --name-only --format= \
    -- 'docs/content-review/ai-answers-in-seconds-you-dont-have-to*.md' | sort -u
  # docs/content-review/ai-answers-in-seconds-you-dont-have-to-epigraph-rlhf.md
  # docs/content-review/ai-answers-in-seconds-you-dont-have-to-owner-correction.md
  # docs/content-review/ai-answers-in-seconds-you-dont-have-to-tos-paraphrase.md
  # docs/content-review/ai-answers-in-seconds-you-dont-have-to.md
  ```

  The same selector over all of `docs/content-review/*` in the window also returns 4. Over the period
  before it (`--until=2026-09-24`) it returns 10, so the path selector does match files.
- **`content-writer`: not added.** No artifact evidence of a run was found, so it is not consulted.

### Subtracted, by property

- **`scrum-master`**, because its grant contains no `Write` and step 2 refuses a relay through the
  orchestrator:

  ```sh
  grep -n '^tools:' agents/*.md
  # agents/scrum-master.md:5:tools: []
  # agents/agents-lead.md:5:tools: Read, Grep, Glob, Bash, Write, Edit
  # agents/quality-assurance.md:5:tools: Read, Grep, Glob, Write, Bash
  # agents/product-lead.md:5:tools: Read, Grep, Glob, Bash, Write, mcp__plugin_tadeumendonca-skills_chrome-devtools, mcp__chrome-devtools
  # agents/content-reviewer.md:5:tools: Read, Grep, Glob, Write, Edit, Bash
  ```

  All four consulted profiles hold `Write`.

## 4 · The recorded consult set

**`agents-lead`, `quality-assurance`, `product-lead`, `content-reviewer`.**

**This is a lower bound.** A persona that ran and left no `dispatch-metrics` record looks the same as
one that never ran. In this iteration that covers every Codex dispatch, and 16 of the 19 Issues carry no
record.

## 5 · The rites before this one

- **The sprint review report exists**: `tadeumendonca-io` `docs/iteration-sweep/sprint-05.md`, 172
  lines, **uncommitted**. `git -C <-io checkout> status --short --branch -- docs/iteration-sweep/sprint-05.md`
  returns `## docs/sprint-05-closing-rites` and `?? docs/iteration-sweep/sprint-05.md`.
- ~~**`/funnel-review` did NOT run before this rite.** It needs the owner's authenticated browser session,
  and its Issue (#473) was moved to `tedeuxx/mhw` on 2026-10-10. `docs/funnel-review/` at the `commit:`
  above holds `README.md`, `collected/`, `sprint-02.md` and `sprint-04.md`, with no `sprint-05` entry
  (`ls docs/funnel-review`).~~ **Struck 2026-10-10: no longer true.** During this rite, on the owner's
  instruction, the orchestrator collected the data through the owner's authenticated Chrome session.
  **`/funnel-review` ran on 2026-10-10**, after the sweep and before the consultations had finished.
  `docs/funnel-review/collected/sprint-05.tsv` (23 lines) and `docs/funnel-review/sprint-05.md`, which
  carries `FUNNEL-REVIEW-RAN`, now exist. Both are **untracked** in this worktree:
  `git status --short -- docs/funnel-review` returns `?? docs/funnel-review/collected/sprint-05.tsv`
  and `?? docs/funnel-review/sprint-05.md`.
- **The `agents-lead` and `quality-assurance` consultations had already started when the funnel review
  ran, so neither was given its report.**
