# sprint-01 — retrospective · scope record

commit: 899c67edc481e53cb8f6c4380a341cc5e00c158e (`tadeumendonca-skills`)
commit: 9399c70f2367c579abc1f9a1ad6af4f2879fd07f (`tadeumendonca-io`)
run: 2026-08-31
written-by: `agents-lead`, per `commands/retrospective.md` step 1

**This file contains query output only.** No findings, no reading of any persona's artifacts, no
summary of the iteration. Those are steps 3 and 4, and each consulted persona produces its own.

---

## 1 · The iteration, in both repositories

**Enumerated, never named from memory.** The milestone is a per-repository object: `sprint-01` is
milestone **number 2** in `tadeumendonca-skills` and milestone **number 1** in `tadeumendonca-io`.
The two halves are paired by their **title string** and by nothing else.

### `tedeuxx/tadeumendonca-skills` — 13 items, 13 closed, 0 open

```
gh issue list --repo tedeuxx/tadeumendonca-skills --state all --limit 200 \
  --json number,state,title,labels,milestone \
  --jq '[.[]|select(.milestone!=null)|{n:.number,s:.state,m:.milestone.title,mn:.milestone.number,l:(.labels|map(.name)),t:.title}]|sort_by(.n)'
```

| # | state | labels |
|---|---|---|
| 313 | CLOSED | ready, loop, sp:8 |
| 335 | CLOSED | ready, loop, sp:3 |
| 336 | CLOSED | ready, loop, sp:5 |
| 337 | CLOSED | ready, loop, sp:8 |
| 338 | CLOSED | ready, loop, sp:8 |
| 339 | CLOSED | ready, loop, sp:3 |
| 341 | CLOSED | ready, loop, sp:3 |
| 342 | CLOSED | ready, loop, sp:8 |
| 343 | CLOSED | ready, loop, sp:3 |
| 344 | CLOSED | ready, loop, sp:2 |
| 355 | CLOSED | ready, loop |
| 357 | CLOSED | ready, loop, sp:8 |
| 358 | CLOSED | ready, loop, sp:13 |

### `tedeuxx/tadeumendonca-io` — 5 items, 5 closed, 0 open

```
gh issue list --repo tedeuxx/tadeumendonca-io --state all --limit 300 \
  --json number,state,title,labels,milestone \
  --jq '[.[]|select(.milestone!=null)|{n:.number,s:.state,m:.milestone.title,mn:.milestone.number,l:(.labels|map(.name)),t:.title}]|sort_by(.n)'
```

| # | state | labels |
|---|---|---|
| 431 | CLOSED | product, reader-facing, ready, sp:5 |
| 506 | CLOSED | product, ready, sp:5 |
| 516 | CLOSED | product, reader-facing, ready, sp:8 |
| 556 | CLOSED | product, reader-facing, ready, sp:2 |
| 572 | CLOSED | product, reader-facing, ready |

### Exhaustion of a snapshot is not emptiness of an iteration

The rite is triggered by the drain's **entry snapshot** being exhausted; its scope is the
**iteration as it stands now**. Those are different sets and the record must say which it reports.

**On this run they coincide: zero open items in either half.** That is the enumeration above, not an
inference from the trigger. Had they differed, the open items would be listed here and the difference
named — a rite that does not say so is claiming a completeness it does not have.

### A sibling milestone surfaced in the enumeration and is NOT in scope

The same query returns four closed issues (#4, #5, #6, #7) under `v0.2.0 Phase 1`, which is milestone
**number 1** in `tadeumendonca-skills`. It is a leftover of the retired `phase:` taxonomy, it is not
`sprint-01`, and nothing in this rite reads it. It is named here only because it appears in the
command's own output, and a reader running that command would otherwise wonder what it is.

---

## 2 · `loop` items carrying NO milestone — the backlog awaiting composition

**This number is not a defect signal.** Since #365 nothing is admitted to a running iteration
automatically, so **every newly-filed `loop` item is in this count by construction**. It is reported
because it is the size of the backlog awaiting the owner's composition at planning, and reporting it is
how that backlog stays visible between plannings.

```
gh issue list --repo tedeuxx/<repo> --state all --limit 400 --json number,state,labels,milestone \
  --jq '[.[]|select(.milestone==null)|select(.labels|map(.name)|index("loop"))]|group_by(.state)|map({(.[0].state):length})|add // {}'
```

| repository | OPEN | CLOSED |
|---|---|---|
| `tadeumendonca-skills` | **5** | 45 |
| `tadeumendonca-io` | **0** | 0 |

The five open ones, enumerated (`--state open`, same predicate):

| # | labels |
|---|---|
| 362 | loop |
| 365 | ready, loop |
| 368 | loop |
| 370 | ready, loop |
| 371 | ready, loop |

`tadeumendonca-io` carries **zero `loop`-labelled issues of any state**, milestoned or not:

```
gh issue list --repo tedeuxx/tadeumendonca-io --state all --label loop --limit 300 --json number --jq 'length'
→ 0
```

That is a fact about contents, not a rule: the `loop` label exists in that repository's label set and
has never been applied.

---

## 3 · The derived consult set

**Derived, never a fixed seven.** One query per Issue in the iteration, in both repositories:

```
gh issue view <n> --repo tedeuxx/<repo> --json comments \
  --jq '[.comments[]|select((.body//"")|contains("dispatch-metrics:"))
          |((.body|split("\n")[0])|capture("dispatch-metrics: (?<a>[^ ]+)").a)]
        |group_by(.)|map({(.[0]):length})|add // {}'
```

### `tadeumendonca-skills` — recorded dispatches per persona per Issue

| # | agents-lead | quality-assurance | product-lead | tech-lead | developer | content-writer | content-reviewer |
|---|---|---|---|---|---|---|---|
| 313 | 6 | 9 | 6 | 3 | 2 | 3 | — |
| 335 | 3 | 2 | 1 | — | — | — | — |
| 336 | 1 | 1 | — | — | — | — | — |
| 337 | 3 | 2 | — | — | — | — | — |
| 338 | 1 | 1 | — | — | — | — | — |
| 339 | 2 | 2 | — | — | — | — | — |
| 341 | 2 | 2 | — | — | — | — | — |
| 342 | 3 | 6 | 2 | — | 7 | — | — |
| 343 | — | — | — | — | — | — | — |
| 344 | 1 | 1 | — | — | — | — | — |
| 355 | 10 | 5 | 2 | — | — | — | — |
| 357 | 1 | 1 | — | — | — | — | — |
| 358 | 1 | 2 | — | — | — | — | — |
| **total** | **34** | **34** | **11** | **3** | **9** | **3** | **0** |

**#343 returned `{}`** — no `dispatch-metrics` comment of any persona, on an Issue whose work merged.

### `tadeumendonca-io` — recorded dispatches per persona per Issue

| # | product-lead | every other persona |
|---|---|---|
| 431 | — | — |
| 506 | — | — |
| 516 | — | — |
| 556 | — | — |
| 572 | 1 | — |
| **total** | **1** | **0** |

**Four of the five `-io` Issues returned `{}`.** The whole `-io` half of the iteration carries exactly
one recorded dispatch.

### The set

**Six personas: `agents-lead`, `quality-assurance`, `product-lead`, `tech-lead`, `developer`,
`content-writer`.** `content-reviewer` recorded zero dispatches in either repository and is **not**
consulted — consulting it would spend a dispatch asking a persona that was never in the iteration to
report on it.

### The three measured limits, travelling WITH the set

**1 · The Issue number comes from the branch, by a fragile grep.** Re-verified at head:

```
grep -n "grep -oE" hooks/scripts/dispatch-metrics-stop.sh
→ 114: issue="$(printf '%s' "$branch" | grep -oE '[0-9]+' | head -1 || true)"

printf '%s' "fix/adr-0002-rewrite-355" | grep -oE '[0-9]+' | head -1   → 0002
printf '%s' "main"                     | grep -oE '[0-9]+' | head -1   → (nothing)
```

A branch carrying an earlier number **misattributes the record to another Issue**, and every dispatch
that ran on `main` is **unrecorded** — which is precisely the intake dispatches. **So the recorded set
above is builders-and-gates, not intake.** Read the `agents-lead` and lead columns accordingly: a
`loop` intake that ran on `main` left nothing here.

*This limit fired on this rite's own branch, and the branch was renamed rather than left standing as a
demonstration.* The rite opened on `docs/retrospective-sprint-01`, which resolves under the predicate
above:

```
printf '%s' "docs/retrospective-sprint-01" | grep -oE '[0-9]+' | head -1   → 01
```

Every `dispatch-metrics` comment from this rite would have posted onto **`tadeumendonca-skills` #1** —
an unrelated PR merged in 2026-07. Polluting a public artifact to demonstrate a limit already recorded
here is a bad trade, and this rite's artifact is these files, not its metrics comments. The branch was
renamed to `docs/retrospective-sprint-one`, verified digit-free with the same predicate before the push:

```
printf '%s' "docs/retrospective-sprint-one" | grep -oE '[0-9]+' | head -1   → (nothing)
```

`dispatch-metrics-stop.sh` therefore exits silently on its no-number path, and **this rite's own
dispatches are unrecorded by `dispatch-metrics` entirely.** That is not an escape from the limit but its
other face — and it is an instance of the lower bound section 4 states: a persona that ran and left no
comment is indistinguishable from one that never ran. Anyone reconstructing which personas this
retrospective consulted must read these files, because the metrics hook holds nothing about it.

**2 · `agent_type` is namespaced.** Every value returned above is spelled
`tadeumendonca-skills:<persona>`, including the one recorded in `tadeumendonca-io` — the namespace is
the **plugin**, not the repository. A consumer matching the bare persona name returns nothing.

**3 · It is per-repository.** The two halves carry their own comments and were queried separately;
neither query sees the other's.

---

## 4 · This is a LOWER BOUND

**This is a lower bound.** `hooks/scripts/dispatch-metrics-stop.sh` exits 0 silently on about a dozen
paths — no `jq`, no `gh`, no branch, no number in the branch, a `mktemp` failure, and a trailing
`|| true` on the post itself. **A persona that ran and left no comment is indistinguishable from one
that never ran.**

Read every count above as *"at least this many ran"*, and the set as *"at least these ran"*. The two
`{}` results in section 3 — `-skills` #343, and four of the five `-io` Issues — are exactly what this
bound looks like from the outside, and neither is evidence that no persona touched that Issue.

A persona the owner knows ran may be added to the consult set by hand.
