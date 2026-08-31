# sprint-01 — retrospective · content-writer

commit: 764da0c970e6d6d454996a55a16735a3694aac3a (`tadeumendonca-skills`)
fed-with:
- my own `dispatch-metrics` comments, both spellings (`writer` and `content-writer`), across all 13
  `sprint-01` Issues in `tadeumendonca-skills` and all 5 in `tadeumendonca-io`;
- `docs/content-review/*.md` in `tadeumendonca-io` — six files, and the commits that produced them;
- the `content`-labelled Issue set in `tadeumendonca-io` and its milestone field;
- the merged-PR set of both repositories over the iteration's window;
- `docs/retrospective/sprint-01/00-scope.md` (the scope record only — no other persona's file was
  opened).

**My derived dispatch count.** `content-writer: 3` in the scope record is **three comments carrying one
`agent_id`** — `a095c3e1359714c6a`, all on `-skills` #313, branch `feat/purpose-field-313`, durations
562 / 1233 / 2472 s. **One dispatch, cumulative, not three.** In `tadeumendonca-io` both spellings
return nothing on all five milestoned Issues — and **by artifact I demonstrably ran there**, which is
finding 1.

---

## Finding 1 — the content lane ran for the whole iteration window and is absent from every iteration-scoped artifact, including the brief that dispatched me

**What I saw.** My single recorded dispatch of `sprint-01` was on a machinery Issue (#313, the
`purpose:` field) — not on a draft. Meanwhile the lane I am the only builder of ran continuously, in
the other repository, entirely outside the iteration:

- **Every `content`-labelled Issue in `tadeumendonca-io` carries `milestone: none` — all 57 of them**,
  open and closed alike:
  `gh issue list --repo tedeuxx/tadeumendonca-io --state all --label content --limit 300 --json number,milestone --jq '[.[]|select(.milestone!=null)]|length'` → **0**.
  Fourteen of them closed *inside* the iteration's window (2026-08-23 → 2026-08-30).
- **Six `docs/content-review/<slug>.md` files were written in that window**, carrying **eleven `##
  Round` sections** between them
  (`grep -c '^## Round' docs/content-review/*.md` in `tadeumendonca-io` → 1, 2, 2, 2, 2, 3), across
  thirteen commits
  dated 2026-08-24 → 2026-08-28.
- **`tadeumendonca-io` merged 51 PRs in that window**
  (`gh pr list --repo tedeuxx/tadeumendonca-io --state merged --limit 100 --search "merged:2026-08-23..2026-08-31" --json number --jq 'length'`),
  **13 of them `content(`-prefixed**. The iteration's `-io` half is five Issues.

**The artifact that shows it, and it is the uncomfortable one:** this rite's own dispatch told me
*"`content-reviewer` ran ZERO times this iteration (both repos), so nothing read your drafts against
the same ruler."* **That is contradicted by artifact.** My pair read six drafts over eleven rounds
inside the window; what it did not do is leave a `dispatch-metrics` comment, because the work carried
no Issue the branch-number grep could resolve to a milestoned item. The scope record is honest about
being a lower bound; the inference drawn *from* it was not, and it was handed to me as fact.

**What it costs.** Three things at once, and none of them is bookkeeping.

1. **The iteration's completion bar describes a minority of the window's work.** Five `-io` Issues
   against 51 merged PRs. Anyone reading `sprint-01` as *what happened* is reading roughly a tenth of
   the repository's activity.
2. **This retrospective cannot see the lane.** The consult set is derived from `dispatch-metrics`
   comments on milestoned Issues, so a lane that is never milestoned is structurally invisible to the
   rite — and I was consulted only because a machinery Issue happened to dispatch me once. **The rite
   would have skipped me entirely had #313 not needed a `purpose:` line.**
3. **It reached the reasoning.** A false premise about my own pair arrived inside my dispatch brief,
   derived from an absence of records rather than from an absence of work.

**What I propose, and the price of leaving it.** I am not proposing that `content` items be
milestoned — the owner's standing rule is that `content` is *selected* one piece at a time and never
batch-drained, and `/autonomy-on` excludes it deliberately. **The defect is not that content is
outside the drain; it is that every iteration-scoped artifact reads as if content did not happen.**
The cheapest honest fix is one sentence with a command in `commands/retrospective.md`'s step 1: the
scope record reports the window's **unmilestoned closed `content` Issues and content-review files**
alongside the iteration, explicitly labelled *outside the iteration, reported so the iteration is not
mistaken for the window*. That costs one query and no rule change. Leaving it costs the same thing it
cost here — a rite that consults a lane about an iteration containing almost none of that lane's work,
and a brief that states as fact what only the absence of a hook's output supports.

## Finding 2 — the two-round bound's terminal condition is a section count in a file that outlives the draft it bounds

**What I saw.** The bound I work under is *at most two rounds*, terminal on the first
`CONTENT-REVIEW-CLEAR` or on the second `## Round` section. The mechanism is a count of headings in
one file, and the file is keyed to a **slug**, while the bound is a property of a **draft**.

**The artifact.** `docs/content-review/blast-radius-supernova.md` in `tadeumendonca-io`:

```
grep -n '^## Round' docs/content-review/blast-radius-supernova.md
→ 3:## Round 1 — 2026-08-27
→ 172:## Round 2 — 2026-08-27 · TERMINAL
→ 330:## Round 1 · revision 2 (PR #557) — 2026-08-28
```

The article was republished with its centre rewritten, so the pair reopened against a materially
different draft. The file says so in its own words and supplies a replacement falsifier
(`grep -c '^## Round .*revision 2'` → 1). **That is the right call and it is well recorded.** What it
also produces is a file where the prescribed falsifier returns **3 against a cap of 2** — a green that
reads red — and, symmetrically, a file where a genuine third round would pass unnoticed if it were
labelled `revision 2`. **The count is checkable by reading, and what it now checks depends on a
convention invented inside the artifact it checks.**

**What it costs.** The bound is the one thing in the content pair that is not a judgement call — it is
what stops a review becoming an unbounded negotiation. Its terminal condition is currently a string
pattern whose meaning is set per-file, per-revision, by the persona the bound constrains. Nobody
gamed it here; the point is that nothing would show it if someone did.

**What I propose, or the price of leaving it.** Either the skill states that the bound is **per draft**
and that a revision opens a new file (`<slug>-r2.md`), which keeps one count per bound and needs no
new mechanism — or it states plainly, where the bound is defined, that the section count is a reading
aid and not a terminal condition, and stops presenting a grep as the falsifier. **Leaving it is
survivable and should be said as such:** the pair is two dispatches deep in a diff the owner reads,
and the drift is visible to anyone opening the file. What is not survivable is the current shape,
where a published rule and a published falsifier disagree by one on a live artifact.

## What I would leave alone

- **The file-based route for review rounds.** `permission-guard.sh` rule 5e denies this persona and
  `content-reviewer` any public post, and the rounds landing in `docs/content-review/<slug>.md` turned
  that constraint into an advantage: the rounds are in the diff, versioned, and read by the gate like
  any other change. Nothing about the window suggests a comment would have been better.
- **The sourcing constraint, with no autonomous tier.** Six drafts, eleven rounds, and every place the
  source ran out was a stop rather than an invention. The rule that *nobody decides a draft is done*
  cost nothing this iteration and is the one rule I would not trade for throughput.
- **The shared-ruler split.** Drafting and reviewing against the same sentences produced citable
  findings rather than two opinions — including a round that found a defect introduced *by* a previous
  round's fix. That is the pair working, not the pair being expensive.
- **`content` staying out of `/autonomy-on`.** Finding 1 is about visibility, not about admission. The
  lane should keep being selected one piece at a time.
