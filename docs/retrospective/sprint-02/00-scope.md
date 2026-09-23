# sprint-02 — retrospective scope

commit: 03fa21227073ea3ad944733c0d9cea3b8a169174

## Iteration composition and open state

The repository queries enumerate all Issues first and select the returned milestone title; no milestone name is passed to `gh issue list`.

```sh
gh issue list --repo tedeuxx/tadeumendonca-skills --state all --limit 200 --json number,state,title,labels,milestone \
  --jq '[.[] | select(.milestone != null and .milestone.title == "sprint-02") | {number,state,title,labels:(.labels|map(.name)),milestone:.milestone.title}] | sort_by(.number)'
```

```json
[{"labels":["ready","loop","sp:5"],"milestone":"sprint-02","number":399,"state":"CLOSED","title":"The lane must end at the audience: the harness posts, and the containment it credits does not exist"},{"labels":["ready","loop","sp:8"],"milestone":"sprint-02","number":401,"state":"CLOSED","title":"The content funnel needs a periodic rite — and the data lives behind a login the harness does not hold"},{"labels":["ready","loop","sp:3"],"milestone":"sprint-02","number":453,"state":"CLOSED","title":"loop: the permission-guard suite is not hermetic — a main checkout silences 8 of the 11 assertions guarding rule 3b"},{"labels":["ready","reader-facing","loop","sp:13"],"milestone":"sprint-02","number":455,"state":"CLOSED","title":"Add a native Codex preventive hook bridge with explicit trust and caller boundaries"}]
```

```sh
gh issue list --repo tedeuxx/tadeumendonca-io --state all --limit 200 --json number,state,title,labels,milestone \
  --jq '[.[] | select(.milestone != null and .milestone.title == "sprint-02") | {number,state,title,labels:(.labels|map(.name)),milestone:.milestone.title}] | sort_by(.number)'
```

```json
[{"labels":["content","ready","sp:8"],"milestone":"sprint-02","number":259,"state":"CLOSED","title":"content: 'Every company should have a Brain' (Garry Tan, YC) — the thesis this loop already runs on"},{"labels":["product","reader-facing","ready","sp:3"],"milestone":"sprint-02","number":636,"state":"CLOSED","title":"/architecture tells a sighted reader 15 and a screen-reader reader 14 — on the grid whose argument is that the inventory is derived"}]
```

Open items in the enumerated sprint-02 composition: **0** in `tadeumendonca-skills`; **0** in `tadeumendonca-io`.

## Open loop backlog with no milestone

```sh
gh issue list --repo tedeuxx/tadeumendonca-skills --state open --limit 200 --json number,title,labels,milestone \
  --jq '[.[] | select(.milestone == null) | select(.labels | map(.name) | index("loop")) | {number,title}] as $items | {count:($items|length),items:$items}'
```

```json
{"count":2,"items":[{"number":499,"title":"loop: multi-harness worklog attribution and team sprint velocity from story points"},{"number":473,"title":"The funnel review has never run, and what it learns has no path into the ruler"}]}
```

```sh
gh issue list --repo tedeuxx/tadeumendonca-io --state open --limit 200 --json number,title,labels,milestone \
  --jq '[.[] | select(.milestone == null) | select(.labels | map(.name) | index("loop")) | {number,title}] as $items | {count:($items|length),items:$items}'
```

```json
{"count":0,"items":[]}
```

## Derived consult set

For each Issue below, the canonical comment query returned the following grouped profile map:

```text
tedeuxx/tadeumendonca-skills#399  {}
tedeuxx/tadeumendonca-skills#401  {}
tedeuxx/tadeumendonca-skills#453  {}
tedeuxx/tadeumendonca-skills#455  {}
tedeuxx/tadeumendonca-io#259      {}
tedeuxx/tadeumendonca-io#636      {}
```

Query applied to each row:

```sh
gh issue view <number> --repo <owner/repo> --json comments \
  --jq '[.comments[]|select((.body//"")|contains("dispatch-metrics:")) | ((.body|split("\n")[0])|capture("dispatch-metrics: (?<a>[^ ]+)").a)] | group_by(.) | map({(.[0]):length}) | add // {}'
```

Deduplication rule applied before deriving the set: group records by `dedupe_key` (`agent_id`), retain the record with the greatest `duration_seconds` for each `agent_id`, and never sum cumulative `SubagentStop` comments. Input records: **0**. Retained records: **0**.

Derived lower-bound set before tool-grant subtraction: **none**.

Profiles without `Write` are subtracted by property. At this commit `agents/scrum-master.md` declares `tools: []`; it was not present in the derived set. Subtracted profiles: **none**.

Final consult set: **none**.

This is a **lower bound**, never the set of personas that ran. A persona that ran and left no comment is indistinguishable from one that never ran. The source names silent exits for missing `jq`, missing `gh`, empty payload, absent `agent_type`, absent/invalid cwd or origin, no resolved Issue, `mktemp` failure, and normal completion; intake work without a resolvable Issue posts nothing. Metrics are per repository and the namespaced profile spelling is required.

## Closing-rite scope evidence

```sh
git -C ../tadeumendonca-io show HEAD:docs/iteration-sweep/sprint-02.md | sed -n '1,8p'
```

```text
# Sprint Review — sprint-02

**FAILED**

routes emitted: **22** / routes visited: **0**

The route generator completed and returned a non-zero set, but the read-only browser failed before the first navigation. This is a failed sweep, not a clean sweep.
```

Artifact: `tedeuxx/tadeumendonca-io:docs/iteration-sweep/sprint-02.md`. Recorded scope: no route visited; no rendered-product, locale, viewport, DOM/accessibility, console, network, image, request, PDF, layout or wording evidence.

```sh
sed -n '1,17p' docs/funnel-review/sprint-02.md
```

```text
# sprint-02 — funnel review

commit: 819efedace16cb2c1b23c8ee9230587a4d280734
collection: docs/funnel-review/collected/sprint-02.tsv
cap: 2 findings, the ceiling and not a quota

FUNNEL-REVIEW-NOT-COLLECTED

Nothing was read this period. Reason: the collection file declares 'collected: no this dispatched persona has no authenticated browser route, and the available Chrome DevTools route failed before navigation with a URLPattern construction error'

This is NOT "the funnel is healthy" and it is NOT "no findings". No surface was reached,
so this report makes no claim about the funnel at all. The collection route is the owner's
own authenticated browser (owner ruling, 2026-09-10); with no authenticated session there is
nothing to read, and nothing in this harness can open one.

There is deliberately no findings section below — a findings section that is absent and one
that is empty are different claims, and only the second means the surfaces were read.
```

Artifact: `docs/funnel-review/sprint-02.md`; collection: `docs/funnel-review/collected/sprint-02.tsv`. Recorded scope: `FUNNEL-REVIEW-NOT-COLLECTED`; no audience surface or metric was read.
