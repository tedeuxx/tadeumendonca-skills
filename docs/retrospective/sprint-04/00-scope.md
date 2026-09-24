# sprint-04 — retrospective scope (closes sprint-03 and sprint-04 together)

commit: 34e75b414e17f39ce99221592bee2eef0343f6d6
measured: 2026-09-24

**This record covers two iterations.** The owner ruled on 2026-09-24 to close sprint-03 and sprint-04
together, so this one directory is the retrospective for both. This file holds query output only: no
findings, and nobody's artifacts were read for it.

## 1 · The iterations, enumerated rather than named

The milestones were enumerated from the returned Issues. No milestone name was passed to a query as a
filter.

```sh
gh issue list --repo tedeuxx/tadeumendonca-skills --state all --limit 200 --json number,milestone,labels,state \
  --jq '[.[]|select(.milestone!=null)|{n:.number,s:.state,m:.milestone.number,mt:.milestone.title,l:[.labels[].name]}]|sort_by(.m,.n)'
```

The rows for milestones 5 and 6 (the earlier milestones 1, 2 and 4 were returned too and are left out
here):

```json
{"l":["ready","loop","sp:8"],"m":5,"mt":"sprint-03","n":499,"s":"CLOSED"}
{"l":["ready","loop","sp:8"],"m":6,"mt":"sprint-04","n":508,"s":"CLOSED"}
{"l":["ready","loop","sp:5"],"m":6,"mt":"sprint-04","n":509,"s":"CLOSED"}
```

| repository | milestone | title | items | open when this ran |
|---|---|---|---|---|
| `tadeumendonca-skills` | 5 | sprint-03 | #499 | **0** |
| `tadeumendonca-skills` | 6 | sprint-04 | #508, #509 | **0** |

```sh
gh issue list --repo tedeuxx/tadeumendonca-io --state all --limit 200 --json number,milestone,labels,state \
  --jq '[.[]|select(.milestone!=null)|{m:.milestone.number,mt:.milestone.title}]|group_by(.m)|map({m:.[0].m,mt:.[0].mt,count:length})'
```

```json
[{"count":5,"m":1,"mt":"sprint-01"},{"count":2,"m":2,"mt":"sprint-02"}]
```

**`tadeumendonca-io` has no sprint-03 or sprint-04 milestone.** No Issue there carries one. The
calibration is the same selector returning its sprint-01 and sprint-02 milestones, which shows the
selector can find milestones in that repository.

**Work that belongs to these iterations but is not an Issue in them.** The dispatch brief called
`-skills` #503–#505 and `-io` #675/#676 sprint-03 work. **They are pull requests, not Issues, and none
of them has a closing reference**, so the milestone query cannot see them. They are listed here with
the command that returned them:

```sh
gh pr list --repo tedeuxx/tadeumendonca-skills --state all --limit 40 \
  --json number,state,title,headRefName,closingIssuesReferences \
  --jq '[.[]|select(.number>=500)|{n:.number,s:.state,h:.headRefName,closes:[.closingIssuesReferences[].number],t:.title}]|sort_by(.n)'
gh pr list --repo tedeuxx/tadeumendonca-io --state all --limit 20 \
  --json number,state,title,headRefName,closingIssuesReferences \
  --jq '[.[]|select(.number>=670)|{n:.number,s:.state,h:.headRefName,closes:[.closingIssuesReferences[].number],t:.title}]|sort_by(.n)'
```

| repo | PR | state | branch | closes | title |
|---|---|---|---|---|---|
| `-skills` | 503 | MERGED | `chore/sprint-02-funnel-review` | — | docs: record sprint-02 funnel review |
| `-skills` | 504 | MERGED | `chore/sprint-02-retrospective` | — | docs: record sprint-02 retrospective scope |
| `-skills` | 505 | MERGED | `chore/sprint-03-planning` | — | docs: record owner-confirmed sprint-03 planning |
| `-skills` | 506 | MERGED | `feat/499-worklog-velocity` | — | feat: add auditable multi-harness worklog |
| `-skills` | 507 | MERGED | `fix/499-cross-repo-revisions` | — | fix: preserve cross-repository worklog revisions |
| `-skills` | 516 | MERGED | `chore/sprint-04-planning` | — | docs: record owner-confirmed sprint-04 planning |
| `-skills` | 517 | MERGED | `loop/508-codex-hook-path` | — | codex: resolve the hook adapter at call time … (#508) |
| `-skills` | 518 | MERGED | `loop/509-codex-snapshot-staleness` | — | feat(codex): report a registered persona snapshot older than the installed plugin (#509) |
| `-skills` | 519 | MERGED | `chore/sprint-04-funnel-review` | — | docs: record sprint-04 funnel review (not collected) |
| `-io` | 675 | MERGED | `chore/sprint-02-closing-rites` | — | docs: record sprint-02 review rite |
| `-io` | 676 | MERGED | `fix/499-worklog-velocity-carrier` | — | docs: align worklog velocity carrier |
| `-io` | 677 | MERGED | `docs/sprint-03-review` | — | docs: record sprint-03 and sprint-04 review sweeps |

`closes` is empty on every row in that range, so on these PRs `closingIssuesReferences` does not tie a
PR to its Issue. The link is in the branch name and the title.

## 2 · `loop` items with NO milestone (backlog size, not a defect)

```sh
gh issue list --repo tedeuxx/tadeumendonca-skills --state open --label loop --limit 200 --json number,milestone \
  --jq '{open_loop:length, unmilestoned:[.[]|select(.milestone==null)|.number]}'
# -> {"open_loop":7,"unmilestoned":[515,514,513,512,511,510,473]}
gh issue list --repo tedeuxx/tadeumendonca-io --state open --label loop --limit 200 --json number,milestone \
  --jq '{open_loop:length, unmilestoned:[.[]|select(.milestone==null)|.number]}'
# -> {"open_loop":0,"unmilestoned":[]}
```

**`tadeumendonca-skills`: 7. `tadeumendonca-io`: 0.** Since #365, a newly filed Issue carries no
milestone, so this number is the backlog waiting to be composed at planning.

Calibration, so neither result is a dead selector. `-skills` has 120 `loop` Issues in any state
(`gh issue list --repo tedeuxx/tadeumendonca-skills --state all --label loop --limit 300 --json number --jq 'length'`).
`-io` has 4, all closed and all unmilestoned (`… --repo tedeuxx/tadeumendonca-io --state all --label loop …`
→ `{"all_loop":4,"closed_unmilestoned":4}`). So the `-io` zero is a real zero.

## 3 · The derived consult set

The canonical per-Issue query from `commands/sprint-retrospective.md` step 2:

```sh
gh issue view <n> --repo tedeuxx/tadeumendonca-skills --json comments \
  --jq '[.comments[]|select((.body//"")|contains("dispatch-metrics:"))
          |((.body|split("\n")[0])|capture("dispatch-metrics: (?<a>[^ ]+)").a)]
        |group_by(.)|map({(.[0]):length})|add // {}'
```

```text
tedeuxx/tadeumendonca-skills#499  {}
tedeuxx/tadeumendonca-skills#508  {"tadeumendonca-skills:agents-lead":4}
tedeuxx/tadeumendonca-skills#509  {"tadeumendonca-skills:agents-lead":2,"tadeumendonca-skills:quality-assurance":1}
```

**Group-by-dedupe rule.** The query above counts comments. Each record is cumulative at one stop and
is not one record per dispatch. The distinct-dispatch count was therefore re-derived by grouping on
`dedupe_key`:

```sh
gh issue view <n> --repo tedeuxx/tadeumendonca-skills --json comments \
  --jq '[.comments[]|select((.body//"")|contains("dispatch-metrics:"))|.body
          |{a:(capture("agent_type: (?<x>[^\n]+)").x),k:(capture("dedupe_key: (?<x>[^\n]+)").x)}]
        |group_by(.a)|map({(.[0].a):(map(.k)|unique|length)})|add // {}'
# #499 {}
# #508 {"tadeumendonca-skills:agents-lead":4}
# #509 {"tadeumendonca-skills:agents-lead":2,"tadeumendonca-skills:quality-assurance":1}
```

The two queries agree here: each comment carries a distinct `dedupe_key`. The `agent_type` values are
**namespaced** (`tadeumendonca-skills:<persona>`), so a match on the bare name returns nothing. `-io`
has no Issue in either iteration, so nothing there was queried.

**At least these ran: `agents-lead`, `quality-assurance`.**

### Why sprint-03 reads `{}`: the instrument was silent, and a different harness did the work

- **The metrics instrument recorded nothing from #438 (2026-09-10) until #508.** That gap is the
  subject of open Issue #513, titled *"dispatch-metrics has recorded nothing since 2026-09-10, and the
  retrospective read the silence as "no persona ran""* (title returned by the §1 Issue query). This
  record cites that finding and did not re-measure it. **An empty map for #499 does not mean no
  persona ran.**
- **Sprint-03's work (#499; `-skills` PRs #503–#505; `-io` PRs #675/#676) was run by a different
  harness, Codex.** A Codex dispatch writes no `dispatch-metrics` record. Its personas left artifacts
  (PR verdict markers), but they did not come out of this instrument. **The orchestrator has NOT
  hand-added those Codex personas as separate consultees.** The Claude personas that are consulted will
  receive those artifacts as evidence.

### Hand-added, on the orchestrator's knowledge rather than on the instrument

- **`product-lead`** ran `/sprint-review` for this close (`-io` PR #677) and `/funnel-review` (`-skills`
  PR #519). Neither run left a `dispatch-metrics` record on either iteration's Issues. It is added by
  hand.

### Subtracted, by name

- **`scrum-master`** ran: it ranked the sprint-04 planning. It is **excluded** because its grant is
  `tools: []` (`agents/scrum-master.md` line 5), so it cannot `Write` its own file. Step 2 refuses a
  relay through the orchestrator.

```sh
grep -n '^tools:' agents/scrum-master.md agents/product-lead.md agents/agents-lead.md agents/quality-assurance.md
# agents/agents-lead.md:5:tools: Read, Grep, Glob, Bash, Write, Edit
# agents/quality-assurance.md:5:tools: Read, Grep, Glob, Write, Bash
# agents/scrum-master.md:5:tools: []
# agents/product-lead.md:5:tools: Read, Grep, Glob, Bash, Write, mcp__plugin_tadeumendonca-skills_chrome-devtools, mcp__chrome-devtools
```

All three consulted profiles hold `Write`.

## 4 · The recorded consult set

**`agents-lead`, `quality-assurance`, `product-lead`.**

**This is a lower bound.** A persona that ran and left no `dispatch-metrics` comment looks the same as
one that never ran. For sprint-03, that covers every dispatch Codex made, plus every Claude dispatch
made while the instrument was silent (#513).
