# The loop mode of record

**This file is the RECORD of which named agile method this loop is currently running.** It declares; it
decides nothing. **The CONTRACT — what a mode may vary and what it may never touch — is the
`<!-- loop-mode-contract -->` block in `CLAUDE.md` at the root of this repository**, and where this file
and that block disagree, the block wins and the disagreement is a finding.

**Read this before any pool query. Never infer the mode from what a pool query returns.** That is the
one place in this design where a wrong guess is silent, and the reason is measured below.

---

## The declaration

~~Four lines~~ **FIVE lines since 2026-09-11 (#385)**, each at column 0, each a parsing contract read
literally — the same positional shape
`invocable:` and `purpose:` already use in this repository, chosen for the same reason: a declaration a
reader can find with an anchored `grep` rather than by reading prose around it.

loop-mode: scrum
loop-mode-since: 2026-09-11
loop-mode-enum: scrum kanban
loop-mode-repos: tedeuxx/tadeumendonca-skills tedeuxx/tadeumendonca-io
wip: 2

**`loop-mode-enum` is closed at two, and an unrecognised value is refused BY NAME rather than defaulted.**
A mode selects a pool predicate and a ceremony set; a session that cannot resolve the value has no
predicate, and guessing one is strictly worse than stopping — it drains a queue nobody scoped. This is
the same rule `/autonomy`'s own first-token table already runs, and it is stated here rather than
inherited because the two are different enums (see *A naming collision* below).

---

## Why the date is `2026-08-30`, and what that date is NOT

**It is DERIVED from an artifact, and it is a lower bound on the switch rather than the switch itself.**
Nothing recorded a mode change, because until this file there was nothing to record one in. What is
measurable is when the container last carried anything:

```
gh issue list --repo tedeuxx/tadeumendonca-skills --state all --limit 300 \
  --json number,closedAt,milestone \
  --jq '[.[]|select(.milestone!=null)|{n:.number,m:.milestone.title,c:.closedAt}]|sort_by(.c)|last'
# -> {"c":"2026-08-30T13:53:04Z","m":"sprint-01","n":355}
```

**So the last item of the last iteration closed on 2026-08-30, and every item since was worked with no
container, no ranking and no rite.** The record is back-dated to that day rather than to the day this
file lands, because a record written as though today were the first day of the mode it names is a false
claim on a surface whose whole thesis is rigor. **What it cannot say is the hour or the intent** — the
switch was an omission, not an act, and an omission has no timestamp.

**The proportion is available from version history over one path, with no ceremony in the chain** —
which is the whole reason the record is a tracked file rather than a field on the container the lighter
mode demotes:

```
git log --follow --format='%ad %h %s' --date=short -- docs/loop-mode.md
```

**The denominator is TIME, never periods.** A period is an iteration, and `kanban` has none; a
proportion denominated in periods inherits exactly the container that is being demoted. Weeks work, and
they are already the denominator the points-per-week rate chose for the same reason.

---

## What each value selects — and the POOL PREDICATE is the operative difference

**Published in full, per mode, rather than as one predicate plus a description of how to edit it.** A
described mutation of a published command is not a published command; that defect cost three corrections
in slice A of #406, and two of the three "right" numbers came from different readings of one sentence.

### `scrum` — the container is a COMMITMENT and is a limb of the predicate

```
gh issue list --repo <owner>/<repo> --state open --limit 200 --json number,labels,milestone \
  --jq '[.[]|select(.milestone!=null)
          |select((.labels|map(.name)|index("ready"))
                  and ((.labels|map(.name)|index("product")) or (.labels|map(.name)|index("loop"))))
          |.milestone.number]|min'
```

That is the **active-iteration derivation**, unchanged, and the pool is the eligible items carrying the
milestone it returns. Ordering is the ordered body composed at planning; exhausting the drain's entry
snapshot is the terminal condition and hands off to the closing rites.

### `kanban` — the container is a LABEL and is NOT a limb of the predicate

```
gh issue list --repo <owner>/<repo> --state open --limit 300 --json number,labels \
  --jq '[.[]|{n:.number,l:[.labels[].name]}
          |select(.l|index("ready"))
          |select((.l|index("loop")) or (.l|index("product")))
          |{n,t:(if (.l|index("loop")) then "loop" else "product" end)}]
        |sort_by(.t=="product",.n)|map("\(.t) #\(.n)")|join(" | ")'
```

Ordering is **FIFO within the `loop`/`product` partition** — `loop` in arrival order, then `product` in
arrival order — which is the owner's ruling that loop-first survives in both modes, plus the
filing-order tiebreak `commands/sprint-planning.md` already defines and labels as arrival order rather
than a ranking. **Nothing ranks and nothing estimates the order.** Exhausting the snapshot ends the
drain and **fires no rite**: in `kanban` an empty container means nothing at all, and a ceremony fired on
it would be firing on noise.

**Measured at head, 2026-09-09 — the same tracker state, both predicates, both repositories:**

```
# the scrum derivation, both repos:
tedeuxx/tadeumendonca-skills -> (no output), EXIT=0
tedeuxx/tadeumendonca-io     -> (no output), EXIT=0

# the kanban predicate, both repos:
tedeuxx/tadeumendonca-skills -> loop #406
tedeuxx/tadeumendonca-io     -> product #580 | product #597 | product #611
```

**That is the mode becoming operative, and it is the sharpest thing in this file.** One tracker state,
read under two modes, gives an empty pool and a four-item pool. The `scrum` derivation prints **nothing
and exits 0** — indistinguishable from a drained iteration, which is `/agents-configuration` rule 1's
own named failure arriving by default rather than by a typo. **A session that inferred its mode from
that result would report a healthy queue over a dark one, with every check green.**

**And the `ready` limb does not vary.** Owner ruling 2026-09-09: *«Mantém o `sp:N` nos dois modos»* — the
readiness bar is identical in both modes, so `ready` asserts the same thing on both sides of this
section and `/definition-of-ready` needs no per-mode branch.

**Two facts about that measurement, both of which are about the QUEUE rather than about this file, and
neither repaired here.** Zero open items in either repository carry a milestone, which is why the
`scrum` pool is empty. And `-io` carries **16** `ready` items of which only **3** carry a routing type
label, so thirteen `ready` items are outside both predicates:

```
gh issue list --repo <owner>/<repo> --state open --limit 300 --json number,labels,milestone \
  --jq '{open:length, ready:[.[]|select(.labels|map(.name)|index("ready"))]|length,
         ready_typed:[.[]|select((.labels|map(.name)|index("ready"))
             and ((.labels|map(.name)|index("product")) or (.labels|map(.name)|index("loop"))))]|length,
         milestoned:[.[]|select(.milestone!=null)]|length,
         sp:[.[]|select(.labels|map(.name)|map(startswith("sp:"))|any)]|length}'
# -skills -> {"open":8,"ready":1,"ready_typed":1,"milestoned":0,"sp":0}
# -io     -> {"open":45,"ready":16,"ready_typed":3,"milestoned":0,"sp":0}
```

**Both zero columns are calibrated rather than trusted** — the same two selectors over `--state all` in
`-skills` return a non-zero milestoned count and a non-zero `sp:` count, so neither is a dead pattern.

---

## What READS this file — one thing, and it is not a mechanism

**`commands/autonomy.md` reads it at entry, before the pool query, and selects the predicate and the
terminal behaviour from it.** That is a rule the session executes, in the file the loop executes — the
same class of reader as the drain's own HITL preflight, which is also prose in that file and not
`hooks/scripts/preflight.sh`. It is a real reader and it is not a mechanism, and both halves of that
sentence matter.

**Nothing mechanical reads it, and this is the command that says so:**

```
jq -r '.hooks|to_entries[]|.value[]|.hooks[]|.command' hooks/hooks.json \
  | sed 's|.*/hooks/scripts/|hooks/scripts/|; s|"$||' | sort -u \
  | xargs grep -nE 'loop-mode|docs/loop-mode' \
  | grep -vE ':[0-9]+:[[:space:]]*#'
# -> no output
```

**The trailing comment filter was ADDED 2026-09-09 (#406 slice C), and the reason is a finding rather
than tidiness.** As first published this command carried no filter, while the two commands in
`CLAUDE.md` backing the same untouchable list both did. That asymmetry was invisible while no hook
mentioned this file — and the cadence carrier's header cites the constraint this record states, in two
**comment** lines, which turned a true claim red:

```
hooks/scripts/cadence-notice.sh:24:# … CLAUDE.md's `loop-mode-contract` block states it:
hooks/scripts/cadence-notice.sh:109:# … exactly as `invocable:`, `purpose:` and `loop-mode:` already
```

**Nothing about the property changed; the falsifier was weaker than its two siblings.** The filter
costs nothing real — a hook that actually resolved this path would do so in a code line, and a code
line is exactly what survives the filter. **What the filter does not close, said here rather than
discovered later:** a hook reading this record through an interpolated path (`docs/loop-$x.md`) is
invisible to this command with or without the filter. This is a grep, not a proof.

**Calibrated, because a selector that cannot go non-zero is not a check** — the same command against a
path the registered hooks genuinely do resolve returns lines:

```
jq -r '.hooks|to_entries[]|.value[]|.hooks[]|.command' hooks/hooks.json \
  | sed 's|.*/hooks/scripts/|hooks/scripts/|; s|"$||' | sort -u \
  | xargs grep -nE 'headRefOid|git rev-parse'
# -> 22 lines across 6 files (2026-09-09)
```

**That absence is DELIBERATE and is a property to preserve rather than a gap to close.** The contract's
untouchable list is backed by a measurement that no registered hook reads any object a mode varies; the
moment a hook is taught to read this file, that measurement needs re-scoping and the enforcement layer
stops being mode-blind by construction. **If a later slice needs a hook to know the mode, that review
happens before it is written, not after.**

**No gate asserts this file exists, parses, or agrees with the contract.** A drift arm would be cheap
and is deliberately not added here: `#406` slice B was scoped to the enum and its carrier, and a check
is its own decision with its own calibration.


---

## `wip: 2` — the value, its basis, and what it does NOT bound (#385)

**`#406` declared the SLOT and deliberately decided no value. `#385` decides the value, and the owner
authorised it as part of that slice.** It is `2`.

**`absent` was NOT an option, and that is the sharpest reason this line exists at all.** Before this
slice the field was missing, and a missing `wip` does not mean one — **it means UNBOUNDED**, which is
the state `#385` exists to end. `hooks/scripts/wip-guard.sh` was deleted at `e145cd0f` (#383) and
nothing replaced it; `gh pr create` is allowlisted in **both** settings layers, so a second concurrent
merge request already executed silently. **This is ADR-0004's own "absent is not a state", on the one
field where the absent reading was the most permissive one available.**

### The basis — Amdahl's law with a measured fraction

**The only instrument that can size this is `hooks/scripts/dispatch-metrics-stop.sh`**, which writes a
structured record per dispatch onto the Issue it worked. Aggregated over the 33 records on `#406`:

```
gh issue view 406 --repo tedeuxx/tadeumendonca-skills --json comments --jq '
  [.comments[]?|select((.body//"")|contains("dispatch-metrics:"))|.body]
  | map((capture("agent_type:\\s*(?<a>[^\\n]+)")?.a // "unknown") as $a
      | (capture("duration_seconds:\\s*(?<d>[0-9.]+)")?.d // "0"|tonumber) as $d
      | {a:($a|gsub("^\\s+|\\s+$|`";"")), d:$d})
  | group_by(.a) | map({agent:.[0].a, n:length, hours:((map(.d)|add)/3600*100|round/100)})'

# agents-lead        n=14   8.67 h   55.8%
# quality-assurance  n=15   5.15 h   33.1%
# developer          n=4    1.72 h   11.1%   <- the only share parallel DEVELOPMENT touches
#                    ALL   15.54 h
```

**The builder is 11% of dispatch time.** Owner ruling 1 keeps the **gate** serial, and the lens is
serial too, so `wip` parallelises that 11% while 89% stays serial. **`wip: 2` is where that stops
paying**; a larger value buys queueing at the gate, not throughput.

### Bound the figure hard — the first published basis was WRONG, and the corpus is why

~~**Re-derived 2026-09-11 across fourteen recent Issues, only two carry dispatch records at all:**

```
for n in 454 452 446 443 441 439 437 436 431 430 427 424 406 385; do
  gh issue view $n --repo tedeuxx/tadeumendonca-skills --json comments \
    --jq '[.comments[]?|select((.body//"")|contains("dispatch-metrics:"))]|length'
done
# -> 0 0 0 0 0 0 3 0 0 0 0 0 33 0
# calibration: the same selector returns 33 on #406, so the zeros are real zeros and not a dead
# pattern. TWO of fourteen Issues carry the instrument; twelve carry nothing.
```

**`#437`'s split is the second data point and it LOWERS the builder's share rather than raising it** —
`agents-lead` 0.63 h over 2 dispatches, `quality-assurance` 0.23 h over 1, and **zero `developer`
dispatches at all.** A `loop` Issue can complete with no builder time whatsoever.

**So the honest statement of the basis: one Issue with a full trace and one with a partial one, both
`loop`-typed.** A `product` Issue runs one lens pass and a `content` Issue runs no `agents-lead` at
all, so the builder's share is larger there and **`wip: 2` is conservative for those lanes rather than
tuned to them**. **Nothing can size `wip` from data until the instrument is written on most work**, and
fixing that is not this slice.~~

**STRUCK 2026-09-11 — FALSE, and the defect was the CORPUS, not the selector.** The window above was
**hand-typed**, and what I typed was dominated by Issues too recent to have been worked — so the
selector was right and it was pointed at the wrong fourteen. The gate falsified it: over the fourteen
most recent **closed** Issues, **nine** carry dispatch records, not two. That reproduces exactly here
(`#438` 8 · `#437` 3 · `#434` 3 · `#426` 1 · `#423` 1 · `#421` 5 · `#419` 3 · `#416` 6 · `#413` 12 =
**42 records**).

**The transferable half: a corpus you typed is a claim you did not measure.** Deriving the window with
the same command that reads it is what closes this class, which is why the replacement below enumerates
rather than lists.

**The corrected basis, with the command that produced it:**

```
python3 -c '
import subprocess, json, re, collections
R = "tedeuxx/tadeumendonca-skills"
g = lambda *a: subprocess.check_output(["gh"] + list(a), text=True)
nums = json.loads(g("issue","list","--repo",R,"--state","all","--limit","40",
                    "--json","number","--jq","[.[].number]"))
agg, cnt, carry = collections.Counter(), collections.Counter(), 0
for n in nums:
    bodies = json.loads(g("issue","view",str(n),"--repo",R,"--json","comments","--jq",
        "[.comments[]|select(.body|contains(\"dispatch-metrics:\"))|.body]"))
    if bodies: carry += 1
    for b in bodies:
        for a, d in zip(re.findall(r"agent_type:\s*([^\n]+)", b),
                        re.findall(r"duration_seconds:\s*([0-9.]+)", b)):
            k = a.strip().strip("`"); agg[k] += float(d); cnt[k] += 1
t = sum(agg.values())
print("issues=%d carrying=%d records=%d total=%.2fh" % (len(nums), carry, sum(cnt.values()), t/3600))
for k in sorted(agg, key=lambda x: -agg[x]):
    print("  %-40s n=%-4d %7.2fh %5.1f%%" % (k, cnt[k], agg[k]/3600, 100*agg[k]/t))
'
# issues=40 carrying=23 records=286 total=198.16h
#   agents-lead        n=154  129.78h  65.5%
#   quality-assurance  n=84    59.67h  30.1%
#   developer          n=18     4.88h   2.5%   <- the only share parallel DEVELOPMENT touches
#   product-lead       n=20     2.95h   1.5%
#   tech-lead          n=6      0.82h   0.4%
```

**The builder is 2.5% over that corpus — LOWER than the 11.07% first published, so the conclusion
survives its own correction: parallelising the builder pays less, and `wip: 2` is conservative.**

**The conclusion does not depend on the window, which is worth more than any one figure.** Every corpus
constructible here puts the builder at or below 11.07%:

| corpus | issues carrying records | records | builder share |
|---|---|---|---|
| `#406` alone | 1 | 33 | **11.07%** |
| 14 most recent **all-state** | 7 | 24 | **0.0%** |
| 14 most recent **closed** | 9 | 42 | **4.4%** |
| 40 most recent **all-state** | 23 | 286 | **2.5%** |

**One disagreement recorded rather than absorbed.** The gate is right on the half that blocks — *nine of
fourteen, not two* — and I reproduce that exactly. Its **replacement aggregate does not reproduce**: it
published *"across all nine … 89 records, 30.48 h … 9.6%"*, while the nine Issues it lists sum to **42**
records and **12.61 h** → **4.4%**. No window I could construct returns 89. **The direction is identical
and every window agrees**, so nothing downstream moves; the figures here are mine, with the command.

**`#406`'s own 11.07% is sound and is kept scoped to the one Issue where it was measured.**

### What `wip: 2` does NOT bound — read this before citing the number

- **It does not bound merge requests.** Nothing enforces it. `gh pr create` is allowlisted in both
  settings layers, `wip-guard.sh` is deleted, and no registered hook reads this file — so an
  (N+1)th concurrent PR executes with no prompt, no denial and no record.
- **It does not relax the GATE.** Review stays serial at any value of `wip` (owner ruling 1, stated in
  `CLAUDE.md`'s `loop-mode-contract` block). `wip` is a ceiling on **development**, never on review.
- **It is not a target.** `scrum-master` may return fewer than `wip` selections, and on a `loop`-heavy
  pool it usually should — the collision base rate over `v2.0.0..origin/main` puts seven distinct
  Issues on `hooks/scripts/inventory-counts.test.sh` alone.
- **It is a parameter, not a constant of the loop.** The owner's own framing before `#406` was filed:
  *«hoje o nosso scrum trabalha em wip=1 devido a necessidade de apurar o modelo antes de paralelizar a
  camada de developers»* · *«mas nao tem intuito de seguir assim»*. Raising it later is a value change
  in this line, not a redesign.
---

## The two repositories, and the residual this inherits

**A mode is a WORKSPACE property and this file is a REPOSITORY object.** `loop-mode-repos` above names
both trees because the mode is one fact about one development effort — the owner, 2026-08-29: *«nao
existe separacao no desenvolvimento do skills e do io»* — and there is no object in either tracker or
either tree that spans them.

**So this is the second hand-maintained two-repository artifact `#406` produces**, after the contract
block itself, and it carries the same residual in a sharper form: set one repository's value to `scrum`
and the other's to `kanban` and **each repository's session reports a coherent, healthy mode**. The
failure presents as everything being fine. Same class as the `sprint-01`/`sprint-1` pairing residual,
one layer up.

**No cheap mitigation from a hook**, and the reason is structural rather than budgetary: a hook receives
one `cwd`, so it would have to discover the sibling tree first — ADR-0004's own *"a heuristic and the
weakest part"* — in order to compare a string. **A detector that must guess where the other copy is in
order to check the other copy is assuming what it checks.**

**The affordable form, and it is the drain's rather than a hook's:** `commands/autonomy.md` already
reads both trees, so it compares the two records at entry and stops on a disagreement. **Price of what
remains:** every context that is *not* the drain — a rite, an ad-hoc session, a dispatched persona — sees
one repository's record and has no way to know the other disagrees.

**And the sibling copy of this file is OWED and does not exist yet.** `tedeuxx/tadeumendonca-io` carries
neither this record nor the contract block at the time this lands; both are that repository's own merge
request, and every sentence crossing the repository boundary is true on the day **its own** repository
merges, never on the day this one does.

---

## A naming collision, stated because it is the first thing a reader trips on

**`/autonomy` has `on` and `off`, and calls them MODES. Those are not loop modes and the two enums must
not be conflated.** `on|off` is *who holds the wheel for this session*; `scrum|kanban` is *how work
flows*, and it persists across sessions in this tracked file. A session can be `off` in either loop mode
and `on` in either. **Nothing anywhere records whether autonomy is on** — that command says so in its own
words — while the loop mode is recorded here, which is the whole difference between the two.

---

## What changing the value actually changes today — the honest answer

**The pool predicate, and effectively nothing else.** The three rites have never fired in either mode:
their only trigger is a drain reaching exhaustion of its entry snapshot, which is an instruction rather
than a mechanism, and no layer here observes a snapshot going empty. So *"`kanban` does not run the
rites"* costs nothing that was being collected, which is the honest comparison — **clock versus nothing,
never clock versus boundary** — and it is why the cadence carrier the owner authorised (`#406` slice C)
was worth building rather than merely worth naming. **It is built** — `hooks/scripts/cadence-notice.sh`,
against `docs/loop-cadence.md` — and it changes nothing in this file: it reads no mode, so both values
above select the same cadence behaviour. **What it does not do is fire a rite.** A hook cannot dispatch,
so *"the three rites have never fired in either mode"* is unchanged by it; what changed is that the
elapsed time is now **said out loud** instead of known by nobody.

**What it does change is measured above and is not small:** under `scrum` the pool is empty in both
repositories at head, and under `kanban` it is four items. **A mode nobody had recorded was already
selecting which of those two answers the loop got.**
