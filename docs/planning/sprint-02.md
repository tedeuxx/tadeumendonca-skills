# sprint-02 — planning

commit: `eda00c41e66268841aa90d3f927f91617554e215` (`-skills`) · `c3ee1eb` (`-io`)
assembled: 2026-09-11 · repositories: `tedeuxx/tadeumendonca-skills`, `tedeuxx/tadeumendonca-io`
iteration: **2026-09-11 → 2026-09-20 — nine and a half days, deliberately irregular**

**This is the FIRST run of `/sprint-planning` that produced an iteration object.** `sprint-01`'s
retrospective ran with no planning to hand its proposals to.

## The iteration is irregular, and it is declared rather than discovered

The normal cadence, ruled by the owner today, is **`scrum` with one-week iterations starting Mondays**.
This one starts on a **Friday** because he authorised anticipating the start from 2026-09-14 while
holding the end date, to bring the 12–13 weekend inside it — **weekends are his productive window**, and
a Monday start would have spent three days including the two that count.

**The cost is stated rather than absorbed:** the first iteration is 1.4× the normal length and contains
**two** weekends. Ordinarily that contaminates a velocity series. **Here it costs almost nothing, and the
reason is measured rather than assumed** — this loop collects **no velocity**: `sp:N` is a size signal by
his 2026-09-09 ruling and not a velocity input, `/planning-poker` sits in the library as a reference
pattern, and `agents-configuration` states outright that no mapping from a story point to hours or
tokens exists. There is no series to distort. **What remains is a legibility cost**, discharged by
declaring the nine days in the first line of both milestone descriptions.

## The mode switch rides with this composition

`docs/loop-mode.md` moves **`kanban` → `scrum`** in this same slice, and not before it. His correction of
the record: *«na verdade nos habilitamos um segundo metodo de trabalho e essa semana como foi atipica
trabalhamos em kanban»* · *«o normal deveria ser rodarmos em scrums de 1 semana»*.

**`kanban` was a deliberate choice for one atypical week, not drift** — which is the distinction `#406`
was written to make visible, and this is the first time it was exercised.

**The switch had to land WITH a composition, not before it.** In `scrum` the milestone is a limb of the
pool predicate; at the moment of the switch **zero open Issues carried a milestone**, so a switch on its
own would have produced an eligible pool of **zero** while every `ready` label stayed exactly where it
was. That is the silent-wrong-guess case the contract names.

## Two composition rules the owner stated at this planning — recorded as HIS, not as a reading

1. **An iteration must carry product and content, not only loop work** — *«nao faz sentido um sprint que
   nao tenha itens de produto e conteudo»*. This rule changed the composition after the first activation:
   the pool as assembled was loop-only once both product candidates turned out to be delivered.
2. **Content is one article per iteration** — *«conteudo so precisaria ter 1 artigo por semana mesmo»*.

**Neither existed before today**, and neither is inferable from any prior artifact.

## The pool as assembled

```
eligible: 6 · awaiting the owner: 4 · content (not drained): 37, of which 11 ready
proposals read from docs/retrospective/sprint-01/: 14 findings across 7 persona files
```

**Two blind-spot predicates were run rather than assumed, and both returned real zeroes** over live
corpora of 4 and 47 open Issues:

```
# Issues carrying no routing label — invisible to every class
gh issue list --repo <owner>/<repo> --state open --limit 200 --json number,labels \
  --jq '[.[]|select((.labels|map(.name)|index("product")|not)
                and (.labels|map(.name)|index("loop")|not)
                and (.labels|map(.name)|index("content")|not))|.number]'
# -> []  and  []

# open Issues still carrying a previous milestone — invisible to this rite's assembly
gh issue list --repo <owner>/<repo> --state open --limit 200 --json number,milestone \
  --jq '[.[]|select(.milestone!=null)|.number]'
# -> []  and  []
```

**`/sprint-review`'s sweep report does not exist.** `docs/iteration-sweep/` is absent from
`tedeuxx/tadeumendonca-io`. **Reported as a finding about the handoff, naming the path that was read** —
not as an empty pool. Nothing can distinguish *the review never ran* from *it ran and produced no
artifact*.

## The ranking as returned

`scrum-master` was dispatched once, in isolation, and returned a ranked pool plus eight process findings.
**Its ranking is advisory; nothing reads `SELECTION-RECORD`.**

It applied `loop` before `product` (#339) and **declared the intra-class sequence a filing-order
tiebreak** — issue number ascending — stating in its own record that *no ratified rule orders two items
within a class*. Six of six lines were tiebreak-decided.

**Three of its findings changed what happened next:**

- **the two `-io` items carry no `sp:N`**, so ranking them was not admitting them;
- **they looked like one scope split across two Issues** — `/definition-of-ready`'s named flagship
  failure — which is what sent both to intake;
- **not one of `sprint-01`'s 14 retrospective findings appears in either class.** Taking the composition
  as assembled would have **closed that retrospective by ignoring it rather than by ruling on it**, and
  nothing anywhere would have said so.

**One finding worth keeping past this iteration:** under `kanban` its record would have been
**byte-identical**, because FIFO within the `loop`/`product` partition and the filing-order tiebreak
produce the same six lines. **That is an accident of this pool, not a property of the design** — the two
modes are indistinguishable from this output alone.

## What intake found — the composition changed because two candidates were already delivered

`product-lead` and `tech-lead` were dispatched in isolation on one question: are `-io#580` and `#611`
one scope or two? **Both converged on an answer neither was offered: two scopes, and both remainders are
already delivered at head.**

```
node apps/fed/scripts/check-harness-drift.mjs
# EXIT=0 — 30 components verified, 8 live personas dispatched, 10 cross-repo links resolving
```

That single command falsifies `#611` items 1, 2 and the links half of item 4, and `#580`'s "linked at a
404", simultaneously.

**Both descriptions were false at head**, and both carried `ready` into this rite's eligible pool on the
strength of them — `#580` claimed the drift checker throws (it exits 0), that the MAJOR tag did not exist
(cut 2026-09-02) and that `ready` was not applied (it was); `#611` listed three closed items as open.
**The defect is the description, not the label**, and both closes say so rather than quietly dropping it.

**One residual survives `#580`'s close and is deliberately NOT carried into any Issue:** the unruled
`main`-versus-tag disagreement and the cross-repo link checker that was never built. The eight plugin
links resolve today and **nothing keeps them resolving**. It is a lens finding, not the owner's demand.

## The composition as proposed — every item in the pool, in or out, with WHY

| # | item | in/out | the predicate or rule that decided it |
|---|---|---|---|
| 1 | `-skills#399` `loop` `sp:5` | **in** | eligible · `loop` precedes `product` (#339) · position = tiebreak only |
| 2 | `-skills#401` `loop` `sp:8` | **in** | eligible · same · position = tiebreak only |
| 3 | `-skills#453` `loop` `sp:3` | **in** | eligible · same · position = tiebreak only |
| 4 | `-skills#455` `loop` `sp:13` | **in** | eligible · same · position = tiebreak only |
| 5 | `-io#636` `product` `sp:3` | **in** | filed during this rite on his ruling · estimated at median 3 · admitted under his composition rule 1 |
| 6 | `-io#259` `content` no estimate | **in** | **selected by him**, not drained · composition rule 2, one article per iteration |
| — | `-io#580` `product` | **out — CLOSED** | implemented elsewhere (`#613`, `c62d8ba`/`d0ba648`/`ee80fa8`) |
| — | `-io#611` `product` | **out — CLOSED** | implemented elsewhere (`#612`, `#610`, `#632`, drift exit 0) |
| — | `-io#456` `#635` `#575` `#597` | **out** | `(product OR loop) AND NOT ready` — descriptions not closed by intake; `#597` additionally blocked on a GA4 firing |
| — | 37 `content` Issues | **out** | `content` is selected one at a time and never drained; he selected one |
| — | 14 retrospective findings | **out** | candidates, not items — no Issue, no `ready`, no estimate. **He named none for filing.** |

## The activation log — two, which is the bound

**Activation 1** — the composition as first assembled: four `loop` items, the two `product` items held
out for want of `sp:N` and for the suspected scope overlap, with the retrospective count carried as a
number.
**His answer: estimate the product items first, and let intake decide whether they are one Issue or
two.** That is a *change*, and it triggered the recomposition — which is what produced both closes.

**Activation 2** — where the `accDescr` correction lives, the one point the two leads disagreed on and
which `tech-lead` explicitly named as the owner's to rule.
**His answer: close both, and file the defect as its own Issue carrying the correction AND the missing
assertion.** `tech-lead`'s position, against `product-lead`'s, on the argument that criteria postdating a
closed description are unfalsifiable.

**The bound was reached and not exceeded.** Two further questions were settled outside the activation
form and correctly so: whether `#636` enters the iteration (scope, answered in prose) and which article
is selected (**content selection is his by standing rule and never takes a menu**).

## The composition as confirmed

Written into both milestone descriptions verbatim, `loop` before `product` before `content`, with the
irregularity in the first line and the tiebreak declared as a tiebreak.

## Estimation pendency this leaves

**`-io#259` carries no `sp:N`.** `/autonomy`'s preflight refuses to enter an iteration while any admitted
item lacks an estimate, so **this composition will refuse the first drain**, and a content estimation pass
is the named next act. **This rite admits and does not estimate** — reporting the pendency rather than
resolving it is the rule, and the alternative is a surprise at the drain's door.

## What could not be assembled, as a bound on everything above

- **The 14 retrospective findings were counted, never read.** `scrum-master` was told they exist and how
  many; nothing here judged whether any belongs in this pool. **Finding 3 above is about their absence,
  not their merit.**
- **`scrum-master` was shown a pool and cannot query one.** A truncated assembly would have been
  indistinguishable to it from the real thing; the two blind-spot zeroes were reported to it, not
  verified by it.
- **The agent registry listed `scrum-master` as holding all tools while `agents/scrum-master.md` declares
  `tools: []`**, on build `2.0.31` against source `2.0.38`. It attempted no tool call deliberately — *the
  only available test is the act the empty grant forbids* — so **the question is open, and it bears on
  whether every `tools: []` profile in this roster is currently ungated.**
- **No estimator could run the suite.** No worktree carried `node_modules`, so `#636`'s `1382/1382` green
  is taken on trust; `developer` said so rather than estimating around it.
- **Nothing reads this file.** No hook, no gate, no command. By this loop's own test — *would something
  stop me, or only my memory?* — this artifact is a record, not a control.
