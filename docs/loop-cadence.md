# The cadence of record — what the clock trigger observes, and how often

**This file is the RECORD the cadence carrier reads.** It declares; it decides nothing, and nothing in
it can run a rite. Its reader is `hooks/scripts/cadence-notice.sh`, a `SessionStart` hook that reports
elapsed time and never blocks.

**It is deliberately NOT the mode record.** `docs/loop-mode.md` says which named agile method the loop
is running; this says how often the closing rites are expected to land an artifact. **The carrier reads
this file and does not read that one** — see *Why the carrier is mode-blind* below, which is a property
worth preserving rather than a convenience.

---

## The declaration

Each line at column 0, read literally — the same positional parsing contract `invocable:`, `purpose:`
and `loop-mode:` already use in this repository, chosen for the same measured reason: a token that can
also occur inside wrapped prose is not a declaration, a **position** is.

cadence-interval-days:
cadence-rite: docs/retrospective /sprint-retrospective here
cadence-rite: docs/planning /sprint-planning here
cadence-rite: docs/iteration-sweep /sprint-review sibling

**`cadence-interval-days` is UNDECLARED, and that is the state this file ships in.** The owner
authorised the carrier — *«Constrói o gatilho por relógio»*, 2026-09-09, #406 — and **was not asked for
the interval**. It is not inferred here. The carrier refuses to conclude rather than defaulting, on the
same rule the mode record already runs for an unrecognised mode value: **a default is inference by
another route**, and a carrier that silently picked a number would be reporting a verdict nobody took.

**Three values, and the middle one is the important one:**

| value | what the carrier does |
|---|---|
| a number | fires when the newest observed artifact is that many days old or older |
| `none` | **a declared opt-out** — the carrier is silent, and its silence is in a diff |
| absent (today) | reports, once per UTC day, that it is installed with no threshold and is deciding nothing |

**`none` and absent are kept apart deliberately.** Absent means nobody has decided; `none` means
somebody did. A registered hook that says nothing reads exactly like a hook that found nothing — this
repository's own named failure shape — so the undeclared state is **loud** rather than silent, and the
way to make it quiet is to declare a value, in one line, in a commit.

---

## `cadence-rite` — three tokens, and the third is the one with a limit in it

`cadence-rite: <artifact root> <typed command> here|sibling`

- **`here`** — the artifact root is in this tree, so the carrier reads
  `git log -1 --format=%ct -- <root>` and that is the rite's clock.
- **`sibling`** — the artifact lands in the **consuming** repository. `commands/sprint-retrospective.md`
  states it in its own words: the sweep report is *"`docs/iteration-sweep/<iteration>.md` in the
  consuming repo"*. A hook receives one `cwd`, so this tree cannot see it. It is reported as **NOT
  OBSERVED**, never as never-run — the two are different claims and collapsing them would make the
  carrier lie in the direction of alarm.

**Why the set is declared here rather than written into the hook.** The rite set moves — the product
sweep was added at #379 — and a carrier that needs editing when a rite is added is a carrier that goes
stale silently. Declaring it puts the observed scope in one place, in a diff, beside the interval it is
used with.

**Measured at the time this file landed**, and it is the argument for the carrier rather than a detail:

```
for p in docs/retrospective docs/planning docs/iteration-sweep; do
  printf '%s -> ' "$p"; git log -1 --format=%cI -- "$p"; echo
done
# docs/retrospective   -> 2026-08-31T11:26:12-03:00
# docs/planning        -> (empty)
# docs/iteration-sweep -> (empty)
```

**And the carrier was FIRED against this tree rather than only reasoned about**, which is the one thing
the intake pass that proposed it could not do. Clear the day's debounce marker and run it with a
`SessionStart` payload:

```
rm -f .git/cadence-notice/*
printf '{"hook_event_name":"SessionStart","cwd":"'"$PWD"'","session_id":"live"}' \
  | bash hooks/scripts/cadence-notice.sh
```

On 2026-09-09 that returned the undeclared-interval notice, reporting
`/sprint-retrospective … last written 9d ago`, `/sprint-planning … has NEVER been written in this tree`
and `/sprint-review … Not observable from this tree`, with `EXIT=0`. **Running it a second time
returned nothing** — the debounce — and `git status --porcelain` stayed empty, because the marker lands
in `.git/cadence-notice/` and never in the tracked tree. **The numbers move with the calendar; the
shape does not, and the command above is what re-derives both.**

**Two of the three rite artifact roots have never existed in this tree.** The rites' only other trigger
is a drain reaching exhaustion of its entry snapshot, which by this loop's own test is an instruction
and not a mechanism — **so the honest comparison for this carrier is CLOCK VERSUS NOTHING, never clock
versus boundary**, and it is the comparison the owner was given in the option he answered.

---

## Why the carrier is MODE-BLIND, and why that is load-bearing

**It reads no mode, no container, no label and no queue.** A clock that fires on elapsed time behaves
identically in both modes, so it never has to ask which one is running.

**That is not a convenience — it is what keeps the mode contract's central measurement true.**
`CLAUDE.md`'s `loop-mode-contract` block backs its untouchable list with a measurement that **no
registered hook reads any object a mode varies**, and states in its own words that *"the moment a hook
is taught the mode, that measurement needs re-scoping and the enforcement layer stops being mode-blind
by construction."* This carrier is registered and does not reach that boundary.

**And it honours the constraint the contract wrote down before this object existed:** *"whatever later
builds the cadence trigger must key on THE CLOCK and never on the pool being empty."* An empty
container is the terminal condition in one mode and means nothing whatever in the other; a trigger
keyed on emptiness makes the second silently inherit the first's trigger under a different name. **This
carrier makes no tracker call of any kind**, so that failure is not available to it.

---

## What nothing enforces here

| decision | what actually holds it |
|---|---|
| the interval is declared at all | **the carrier's own daily notice** — a report a human reads, never a bound |
| the interval is the RIGHT number | **nothing.** It is the owner's, and no instrument here has an opinion |
| a rite actually RUNS when the notice fires | **nothing.** A hook cannot dispatch, and this one is a notice by design |
| the observed set is the rite set | **nothing reads the rite definitions against this table.** A rite added with no line here is invisible to the carrier, and no gate says so |
| the two repositories agree about the cadence | **nothing.** A hook sees one root; the sibling has no record of its own |

**By this loop's own test — *would something stop me, or only my memory?* — the cadence carrier is not
engineered, and it is not presented as if it were.** What it changes is that the elapsed time is
**reported** rather than known by nobody, which is the whole of the claim.

**An artifact is not a rite, and that bound rides with every number this carrier prints.** It reads
commit dates on a path. A rite that ran and wrote nothing is invisible to it; a commit touching one of
those paths for an unrelated reason resets its clock. It answers *when did an artifact of this rite
last land*, never *did the rite run, and run well*.

---

## The sibling repository

**`tedeuxx/tadeumendonca-io` carries no record of its own, and the carrier is therefore silent there.**
That is deliberate rather than owed: the hook's scope signal is this file's existence, so a consuming
repository gets no notice until it ships one — which is the correct default, since a repository that
does not run the rites must not be told a rite is overdue.

**Whether the sibling should ship one is its own decision and its own merge request.** The rite whose
artifact lands there is the product sweep, and it is declared `sibling` above precisely so that this
tree reports it as unobservable instead of guessing. **Nothing pairs the two records**, and if a second
one is ever written, that is a third hand-maintained two-repository artifact with the same residual the
other two already carry: set them to different values and each repository's session reports a coherent,
healthy cadence.
