# sprint-01 — retrospective · tech-lead

commit: `247397c2cc61ce5ce12359eefd364d3923abe209` (`tadeumendonca-skills`, branch
`docs/retrospective-sprint-one`) · `9399c70f2367c579abc1f9a1ad6af4f2879fd07f` (`tadeumendonca-io`)

fed-with:
- my own `dispatch-metrics` comments, matched on the namespaced marker
  `<!-- dispatch-metrics: tadeumendonca-skills:tech-lead #<issue> -->`, across both repositories'
  `sprint-01` halves;
- `00-scope.md` (the scope record only — no other persona's file was opened);
- the `sprint-01` Issues enumerated from the tracker, both repositories, and their comment sets:
  `-skills` #313 #335 #336 #337 #338 #339 #341 #342 #343 #344 #355 #357 #358 · `-io` #431 #506 #516
  #556 #572;
- the ADR commits that landed on `origin/main` during the iteration, in both libraries
  (`git log origin/main --since=2026-08-24 --name-only -- docs/adr/`), and the current shape of the
  records they touched;
- `skills/harness-engineering/SKILL.md`'s states table, and a tree-wide grep for the artifact it names.

**My dispatch count, derived by `agent_id` and not by comment count: 2.** Three
`dispatch-metrics` comments exist, all on `-skills` #313, carrying two distinct `agent_id`s —
`aa70c98d272f2f898` (twice, cumulative: 282 s / 48 tool calls, then 458 s / 67) and `ad921b035a5597f75`
(30 s / 6 calls). The scope record's `tech-lead: 3` counts comments. **And 2 is also wrong** — see
Finding 1: I demonstrably ran on `-io` #516 and left no comment at all, so the honest statement is
*at least 3 dispatches, of which the instrument recorded 2 and misattributes all of them to one Issue.*

---

## Finding 1 — the `product` lane's technical signature has no artifact, and on four of five product items this iteration there is nothing to distinguish an intake that did not happen from one that left no record

**What I saw.** `skills/harness-engineering/SKILL.md`'s states table names the artifact for
`filed → description closed` on all three lanes as *"the closed description in the Issue body, plus the
intake stamp"*. **There is no intake stamp.** Grepped tree-wide:

```
grep -rln "intake stamp" /path/to/tadeumendonca-skills
→ skills/harness-engineering/SKILL.md
→ powers/tadeumendonca-skills/skills/harness-engineering/SKILL.md   (the generated export of the same file)
```

Two hits, one source file, three lines — 211, 212 and 213, the three table rows themselves. Nothing
defines a format, nothing writes one, nothing reads one. The states table cites an instrument that does
not exist, in the file every persona in this roster loads always-on.

**The artifact that shows what that costs.** The iteration's `product` lane is the five `-io` items, all
carrying `ready`, all therefore claiming a closed two-lead description. Searched for any trace of this
persona in their bodies:

```
gh issue list --repo <owner>/<product> --state all --limit 300 --json number,body,milestone \
  --jq '[.[]|select(.milestone!=null)|{n:.number, names_tech_lead:((.body//"")|test("tech-lead"))}]|sort_by(.n)'
→ 431 true · 506 false · 516 true · 556 false · 572 false
```

and #431's single hit is prose *about* a published architecture diagram, not an intake. **One of five —
#516 — carries a real technical contribution** (a `tech-lead` slice-2 design verdict, 2026-08-25,
relayed as a comment). #556's own body states in as many words how it reached `ready`: *"Filed
2026-08-28 on the owner's direct confirmation… he supplied the deciding fact in the same message."*
#506 and #572 carry no intake section at all.

**I cannot tell you which of those four never had a technical intake and which had one that vanished,
and neither can anything else in this loop.** The `dispatch-metrics` instrument cannot answer it either,
and the reason is structural rather than accidental: it derives the Issue number from the branch name,
so a dispatch that runs on `main` — which is exactly where intake runs, before a branch exists — is
recorded nowhere. My `-io` #516 dispatch is the proof, on my own record: a substantive design verdict on
the tracker, zero metrics comments in that repository for this persona.

**What it costs.** The two-lead intake is not a courtesy, it is where the ruler comes from: the gate
consolidates *"was every requirement of the Issue met"*, and those requirements are the leads' output.
My half of that output is what has to exist first, what the slice must not break, what the chosen shape
costs later, and whether a decision in it crosses the ADR significance boundary. **On this iteration the
one product item I demonstrably attended is also the only one that produced a product ADR** — #516 →
`tadeumendonca-io/docs/adr/0050-journey-attribution-joins-profile-on-company-and-start-date.md`, plus the `0034` and
`0048` amendments the same work forced. That is one data point and I will not argue causation from it;
what I will argue is that **the significance flag is an intake output, and four intakes this iteration
have no recorded technical half at all.** The cost is not hypothetical: #516's own body records four
consequences the intake surfaced — a print-artifact divergence between `/me` and `/cv.pdf`, an
attribution that would have been derived from date proximity, and an asset budget at 81% — none of which
the Issue as filed had asked about.

**The change I propose.** The cheapest honest fix is not a new mechanism, it is deleting a false one and
replacing it with something a reader can check: **strike *"plus the intake stamp"* from the three states-
table rows, and replace it with the artifact that actually exists — the lane's intake section in the
Issue body, naming who ran.** Then the row is true, and its absence on an Issue is visible to anyone
reading it. If the owner wants more than visibility, the next step is a required `## Intake` section
carrying the lane and the personas that closed it, checkable by reading the Issue and by nothing else —
**and I would say so in the row rather than let a second unbacked word accumulate there.** The price of
leaving it: the states table keeps naming an object that does not exist, and every future reader —
human or fresh context — takes from it that intake is recorded when it is not.

---

## Finding 2 — ADR-0002 grew 58% in one iteration to 3,840 lines, and the record designated the thing a fresh context reads is now larger than a fresh context can read

**What I saw.** The methodology library's substrate record took 22 commits and 7 amendments in
`sprint-01` alone — the twenty-first through the twenty-seventh, of twenty-seven in its whole history.
One quarter of its lifetime amendment count landed in one iteration.

**The artifact that shows it.**

```
git log origin/main --since=2026-08-24 --format='%h %ad' --date=short -- docs/adr/0002-roster-and-dev-loop.md | wc -l
→ 22

git show 6bd2548~1:docs/adr/0002-roster-and-dev-loop.md | wc -lc     # the state before the iteration's first touch
→ 2430 lines, 186,109 bytes
wc -lc docs/adr/0002-roster-and-dev-loop.md                          # at this commit
→ 3840 lines, 296,481 bytes

grep -nE "^#{2,4} .*[Aa]mendment" docs/adr/0002-roster-and-dev-loop.md   # 27 numbered amendments, 21st-27th all dated 2026-08-28..30
```

**+58% in lines, +110 KB, in one iteration.** With `0004-controls-and-enforcement.md` (2,818 lines,
213,944 B) the two records this iteration worked in total **510,425 bytes — on the order of 128k tokens
if anything ever loaded them both.**

**And the currency question got harder in the same window.** The **twenty-seventh** amendment
(2026-08-30) *reverses decision 1 of the **twenty-third*** (2026-08-29) — one day apart, inside one
iteration, both live in the same file, and the strike is discoverable only by reading forward from the
clause to its reversal. `commands/retrospective.md` and `skills/harness-engineering/SKILL.md` both
carry struck sentences that the reversal reached, and `skills/harness-engineering/SKILL.md` records —
in its own words, about this exact instance — that *"a strike lands where a rule is STATED and survives
where it is CITED"*, which is what made a live-but-reversed premise readable as current on the next
dispatch.

**What it costs.** `/documentation-standard` Part II states the purpose this record is failing:
*"ADRs are the durable shared brain of the platform — a fresh, per-task agent context cannot remember
prior decisions, so it reads them here."* At 296 KB it does not read it — no persona in this roster
preloads it, and the practice's own checklist rule, *"One decision per ADR. If you are recording two,
write two,"* is being satisfied by a record holding twenty-seven. The failure mode is not that the file
is long; it is that **the answer to *"is this clause still in force?"* now requires reading 3,840 lines
in date order, and the cheapest available substitute is asking someone who was there** — which is
precisely the memory the library exists to replace. **This is a six-month cost, not a today cost**, and
it compounds: the twenty-third/twenty-seventh collision is the first time in this record's life that a
reversal and its target both sat inside one iteration, and the next one is cheaper to create than this
one was.

**Something worth noting rather than assuming:** the record itself already asked this question and
answered it the other way — the twentieth amendment carries a section headed *"Why this is an amendment
and NOT record 0022"*. The reasoning there was about one decision. **Seven more amendments have landed
since it was written, and nothing re-asks it at the record's own scale.**

**The change I propose.** Not a rewrite, and explicitly not a deletion — supersede-never-delete is gone
but `/documentation-standard`'s replacement is stricter, not looser, and nothing here is a reversed
decision. What I propose is a **split test applied at authorship time**: when an amendment would add a
new *decision* rather than a new *fact about an existing one*, it earns a number. The concrete probe is
already in the file — an amendment carrying its own *"Why this is an amendment and not record NNNN"*
section is one that failed the test and argued past it. **This is not mine to execute:** ADR-0002 is a
loop/machinery record and #223 put its authorship with `agents-lead`. I am pricing the shape, not
claiming the pen. The price of leaving it: the record keeps growing at the rate this iteration set, and
the first person to be misled by a live-looking reversed clause has already happened once, on 2026-08-30,
inside this iteration.

---

## What I would leave alone

- **The `loop` lane's exclusion of this persona.** I was dispatched twice this iteration and both were on
  `-skills` #313, a `loop`-typed Issue — a lane the owner ruled *"nunca"* on. I am not proposing that be
  loosened, and I want that on the record from the persona it would benefit. The argument in
  `/harness-engineering` — that almost every machinery change can be described as having an architecture
  edge, so a loose exception becomes the default case — held against my own two dispatches: I have no
  durable artifact from either of them anywhere on #313 or its PRs, which is what a dispatch into a lane
  with no verdict slot for it produces.
- **The `sp:N` label and the milestone as the iteration's carrier.** Both were chosen against measured
  alternatives (no Projects v2 iteration field reachable, no numeric field on a milestone, no token
  scope), and both were queried this iteration by the pool predicate and by the scope record without
  needing a permission change. That is the test a mechanism should pass, and they passed it.
- **The four surviving merge holds.** `iac/` in particular. Nothing in this iteration touched `iac/`, so
  the hold was not exercised — and an unexercised control is not a candidate for removal, it is a control
  with no evidence either way.
- **`/documentation-standard`'s current-codebase rule.** It replaced supersede-never-delete this month;
  it has not had an iteration's worth of exercise yet, and the honest posture on a rule that new is to
  let it run before proposing anything about it.

---

## What contradicted the dispatch brief

**Nothing did, and two things confirmed it precisely.** The brief warned the count could be wrong in both
directions at once; on my own record it is — inflated on `-skills` (3 comments, 2 `agent_id`s) and
deflated to zero on `-io` (at least one real dispatch, no comment). The brief also warned that commit
subject lines on this branch can republish another persona's finding; I did not run `git log` on this
branch at all, only on `origin/main` and only scoped to `docs/adr/`, and I saw no finding line from any
other consultation.
