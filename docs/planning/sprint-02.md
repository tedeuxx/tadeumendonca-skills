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

~~`content (not drained): 37, of which 11 ready`~~ — **STRUCK on review, and the defect is that it was
published WITHOUT ITS FALSIFIER, not that the digits were wrong.** Three of the four figures on those two
lines reproduce exactly; this one reproduces under no selector I could construct. **It sat eight lines
above two blind-spot zeroes that do ship their commands, so this block demonstrates the
number-with-its-command rule and breaks it in the same breath.** That is the finding. The digits are
downstream of it.

**The measurement, with the selector, and with what it excludes stated rather than implied:**

```
gh issue list --repo tedeuxx/tadeumendonca-io --state open --limit 300 --json number,labels,milestone --jq '
 {content_open:              [.[]|select(.labels|map(.name)|index("content"))]|length,
  content_open_ready:        [.[]|select((.labels|map(.name)|index("content"))
                                    and (.labels|map(.name)|index("ready")))]|length,
  content_unmilestoned:      [.[]|select((.labels|map(.name)|index("content")) and .milestone==null)]|length,
  content_unmilestoned_ready:[.[]|select((.labels|map(.name)|index("content")) and .milestone==null
                                    and (.labels|map(.name)|index("ready")))]|length}'
# -> {"content_open":40,"content_open_ready":13,
#     "content_unmilestoned":39,"content_unmilestoned_ready":12}
```

**Both readings are published because the admission of `#259` moved the count during this rite**, and
naming only one would hide which side of that event the number is on: **40 / 13** counts every open
`content` Issue including the one this iteration admitted; **39 / 12** counts what remains unselected
after it. *Not drained* is the second. The scope is `tedeuxx/tadeumendonca-io` alone —
`tedeuxx/tadeumendonca-skills` carries **0** `content` Issues — and no `content` Issue is `blocked`, so
that filter changes nothing either way.

**No content Issue was filed on 2026-09-11**, so this is a wrong figure rather than drift: the newest
open `content` Issue is `#633`, created 2026-09-10.

*What reproduced, checked rather than assumed:* `eligible: 6` ✓ · `awaiting the owner: 4` →
`[635, 597, 575, 456]` ✓ · `14 findings across 7 persona files` → exactly 14 `## Finding` headings across
exactly 7 persona files, `00-scope.md` correctly excluded ✓.

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

## This rite ran its steps OUT OF ORDER, and the rite itself names why that matters

**Step 5 prescribes the order: *"write and commit the pool, the ranking, the proposed composition and the
activation log BEFORE step 4 runs"*. It ran inverted.** The tracker writes landed first and the artifact
was committed after:

```
# the two closes that recomposed the pool, and the only step-4 timestamps this loop can read:
gh issue view 580 --repo tedeuxx/tadeumendonca-io --json number,state,closedAt   # 2026-09-11T21:33:20Z
gh issue view 611 --repo tedeuxx/tadeumendonca-io --json number,state,closedAt   # 2026-09-11T21:33:18Z
git log -1 --format=%cI -- docs/planning/sprint-02.md                            # 2026-09-11T18:45:08-03:00
#                                                                                # = 21:45:08Z
```

**So the exposure step 5 warns about is real and is live right now: the milestone exists in both
repositories and six items carry it, while the only record that this rite ran sits in an unmerged PR.**
If that PR is rejected, the tracker state stands and the record does not. `--remove-milestone` is the
corrective act and it is the owner's.

**This is recorded HERE, and the reason is step 5's own words.** It calls this file *"the only durable
record that this rite ran"*. The inversion was disclosed in the merge request body — which is a record of
the **review**, not of the **rite**, and a reader reconstructing what happened at this planning reads the
artifact. **A failure disclosed only where the artifact is not is disclosed to the wrong reader.**

**Not repaired, because it is not repairable after the fact** — the writes were live when they happened
and no ordering can be retrofitted. What is owed is a retrospective finding, not an edit here.

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
- ~~**Nothing reads this file.** No hook, no gate, no command.~~ **Corrected on review: the first limb is
  FALSE, and the distinction it was missing is worth more than the correction.** **Nothing reads this
  file's CONTENT** — no hook, no gate and no command parses a word of it, and the conclusion below is
  untouched. **But a registered hook reads its PATH'S COMMIT DATE**, so merging this file has an effect
  the sentence denied. `docs/loop-cadence.md` declares the root at column 0:

  ```
  cadence-rite: docs/planning /sprint-planning here
  ```

  and `hooks/scripts/cadence-notice.sh` — registered on `SessionStart` — takes each rite's clock from
  `git log -1 --format=%cI -- <that root>`, which its own header shows returning empty for this one.
  **So this commit starts the `/sprint-planning` cadence clock, for the first time that root has ever
  carried one.** It is also why `docs/iteration-sweep` is reported as never having moved: the same hook,
  the same mechanism, a root that does not exist.

  **The one gate arm naming this path asserts less than it looks like.**
  `hooks/scripts/inventory-counts.test.sh` checks that `commands/sprint-planning.md` and
  `agents/scrum-master.md` name the same `docs/planning/<iteration>.md` string. That is two prose
  documents agreeing with each other; **no arm opens a file under this root**, so *no gate* stands.

  **The conclusion is unchanged and is now load-bearing rather than decorative.** By this loop's own
  test — *would something stop me, or only my memory?* — this artifact is a record, not a control. **A
  clock that advances because a file landed is not a reader of what the file says**, and nothing
  anywhere can tell a planning that ran from a file that was committed.
