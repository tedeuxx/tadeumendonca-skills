# 0012. The dev-loop has THREE issue types — `product` / `content` / `loop` — and they are the
**ROUTING axis, exclusive**, not the granularity axis; four corollaries follow from making that true

- **Status:** accepted
- **Date:** 2026-08-12
- **Deciders:** the owner (four decisions below, each a direct ruling); written by `tech-lead`;
  pre-implementation stress test by `harness-lead` (8 scenarios, S1–S8, cited per finding; all
  re-derived independently in this record rather than relayed)
- **Supersedes / superseded by:** —
- **Driven by:** [#184](https://github.com/tedeuxx/tadeumendonca-skills/issues/184) (the owner's own
  statement of the three-type routing: *"temos issues de 3 tipos, cada um deles é roteado para família
  de agentes diferente"*) · corollary work tracked separately at
  [#161](https://github.com/tedeuxx/tadeumendonca-skills/issues/161) and
  [#187](https://github.com/tedeuxx/tadeumendonca-skills/issues/187)

## Context & problem

The vocabulary already exists — `README.md:166-169` draws routing on edge labels `product` / `content` /
`loop`, and `:181-182` sends `loop` straight to the owner, bypassing tiers 2 and 3. But **`loop` is not a
real label.** Re-derived here:

    gh label list --repo tedeuxx/tadeumendonca-skills
    → bug · documentation · duplicate · enhancement · good first issue · help wanted · invalid ·
      wontfix · product · content · ready · blocked · reader-facing        (exactly 5 project labels)

Five labels exist (`product`, `content`, `ready`, `blocked`, `reader-facing`) and `dev-loop/SKILL.md:126-
132` names the same five. **The README's own routing diagram draws an edge on data that does not exist**
— a diagram asserting a decision the label vocabulary never made.

This matters more than a missing label, because `type:*` was retired on a stated, checkable test:

> *"the test a label has to pass: something must QUERY it"* — `dev-loop/SKILL.md:123`

`type:*` failed that test (retired vocabulary, `SKILL.md:134-139`) and `loop` risks failing it the same
way unless something is written to query it. Separately, `dev-loop/SKILL.md:61-68`'s state table
(`filed → ready → in progress → reviewed → closed`) carries **no type column** — it presents the `product`
path as universal, when the loop already has three different tier-1 and tier-2 compositions per type
(product-lead+tech-lead / product-lead-only / harness-lead-only; developer / developer / the
orchestrator itself, per `README.md:185-188`'s own prose).

**What this ADR is not.** It does not decide issue *granularity* — story / task / proposal, a later ADR.
Type and granularity are independent axes: an issue has exactly one type (routing) and, separately, some
shape (a later decision). Confusing the two is the error this record exists to foreclose, because
`README.md:169`'s single `NI -->|loop| HR` edge reads as though `loop` were a size, not a lane.

A `harness-lead` dispatch stress-tested making `loop` a real, exclusive routing label before any of
it was built (as ADR-0002's tenth amendment requires of harness proposals) and returned 8 scenarios.
Re-derived, not relayed, below.

## Decision drivers

- **A label earns existence by being queried** (`dev-loop/SKILL.md:123`) — `type:*`'s retirement is the
  precedent this decision must not repeat with `loop`.
- **The routing that already runs in prose must not silently diverge from the vocabulary that gates it** —
  `README.md`'s diagram already asserts `loop` exists; the vocabulary should stop lying underneath it,
  not the other way around.
- **Exclusivity or co-application changes what a merge-class rule can rely on** — the label table
  (`dev-loop/SKILL.md:128-129`) already implies the label decides merge class, while the gate in practice
  decides class from what the diff touches (`dev-loop/SKILL.md:475`, `agents/quality-assurance.md:714`).
  A decision on exclusivity should close that gap rather than widen it.
- **A routing lane with no mechanical builder is a lane in name only** — measured against `content`
  below: a real lane must have someone whose job is to walk it.
- **Reconciliation cost is paid within a tier** (ADR-0002, tenth amendment) — a routing change that
  reassigns which tier does what must say, for each type, who is in tier 1, who builds, who gates.

## Considered options

1. **Type is the ROUTING axis — `product` / `content` / `loop`, exclusive** *(chosen)*. One issue, one
   type, and the type decides which profiles take part at intake, who builds, and whether a gate runs at
   all. *Trade-off:* it forces four corollaries to land alongside it (below) because the current tree
   already half-implements a different, non-exclusive version of this — the corollaries are the cost of
   closing that gap rather than optional extras.

2. **Type is the GRANULARITY axis — story / task / proposal** *(rejected, for now — a later ADR's
   subject)*. This is the natural reading of "type" in most trackers: it says how big or how composed a
   unit of work is, not which family of agents handles it. *Why not here:* it answers a different
   question than the one the tree already has half-built. `README.md`'s diagram and `dev-loop/SKILL.md`'s
   label table are already routing on `product`/`content`/`loop` in prose — adopting granularity as "the"
   type axis now would leave that existing routing either undocumented or double-encoded under a
   different name. It is not disqualified as a future axis; it is orthogonal, and conflating the two in
   one ADR would violate one-decision-per-record. **Deferred, not rejected on merits** — this record takes
   no position on story/task/proposal.

## Decision outcome

Chosen: **option 1**, because the routing behaviour already exists in `README.md`'s diagram and in
`dev-loop/SKILL.md`'s label table — this decision makes the vocabulary underneath it real, exclusive, and
queried, rather than inventing a new axis.

### Corollary 1 — the `/autonomy-on` queue predicate (forced by S1)

Measured: `commands/autonomy-on.md:15` reads *"Open issues labelled `product` and `ready`"* — `product`
only. Measured against this repo's own backlog:

    gh issue list --repo tedeuxx/tadeumendonca-skills --state open --limit 30
    → 12 of the 13 open issues carry `product`, and every one open right now is harness/loop-class work
      (measured before #187 below was filed; #187 itself carries `product`, so a re-run today reads
      13 of 14 — the ratio the drainer risk depends on is unchanged)

**If `loop` becomes real and exclusive, the drainer's predicate silently empties in the one repo whose
purpose is the loop** — it would report "0 issues" rather than error, which is worse than a crash because
nothing signals the miss.

**Decision:** the queue predicate becomes **`(product OR loop) AND ready`.**
**Consequent work, out of scope here:** `commands/autonomy-on.md:15` needs updating to state the new
predicate. Not done in this ADR.

### Corollary 2 — exclusivity (forced by the routing decision itself, stress-tested as S2)

Measured: `product` and `content` are already co-applied in the `tadeumendonca-io` repo (8 of the 21
`content` issues there also carry `product`), and the label table already implies the label decides merge
class when the gate in fact decides class from what the diff touches — so the label was already a
decorative second source of truth on this axis before this decision, not created by it.

**Decision:** the three types are **exclusive — one issue, one type.** This requires, as consequent work
not done in this ADR:

(a) `commands/new-issue.md`'s label-application step (currently *"Also apply: `product` or `content`"*,
line 101, phrased as two independently optional labels) becomes a **single choice**, not an "apply either
or both" step.

(b) The 8 dual-labelled issues in `tadeumendonca-io` are a **migration**, not a state to be preserved —
each needs its single type decided, not defended.

### Corollary 3 — `content` needs a mechanical builder (forced by exclusivity, stress-tested as S5)

Once type is exclusive, a pure-`content` issue can no longer ride `product`'s build path the way the 8
dual-labelled issues in `-io` do today. Measured: neither existing profile builds `content` mechanically
now — `product-lead` has no `Write` (`agents/product-lead.md:4` — `tools: Read, Grep, Glob, Bash`), and
`developer` has `Write` and the glob (`apps/**` covers articles) but is never dispatched there, because
`/autonomy-on`'s predicate excludes pure-`content` issues (the same predicate corollary 1 touches, on the
other type). Re-derived directly, not relayed from #161 (its own body carries a different, older
2026-08-07 measurement and neither of these figures):

    gh issue list --repo tedeuxx/tadeumendonca-io --state all --label content --limit 40
    → 21 total. 8 carry product+content: 6 CLOSED, 2 OPEN. 13 carry content alone: 2 CLOSED, 11 OPEN.

**2 of 13** pure-`content` issues have ever closed, against **6 of 8** of the dual-labelled ones. The
gap is real — 15% versus 75% — and it is the argument for this corollary; an earlier draft of this
record stated it as "2 of 21" against "7 of 8", mixing the pure population's numerator with the total
population's denominator. Corrected here rather than left to compound, since it is the exact class of
error this repo's own gate exists to catch.

**Decision (owner, overriding #161's own "wait for a measured delta before adding a persona"
precondition):** a `writer` persona is created **now** to be the mechanical builder of `content`, tracked
as [#187](https://github.com/tedeuxx/tadeumendonca-skills/issues/187) — re-derived, real, and titled
exactly *"owner decision 2026-08-12, ahead of #161's measured-delta precondition"*. **This ADR does not
design the persona** — its brief, tools and preconditions are #187's — only records that `content` routes
to `writer` once #187 ships, and that #161 remains the calibration Issue for what that brief should
contain (article-drafting delta, style calibration).

### Related, not decided here — the forward reference (S7)

Under a separate, later decision (this ADR names it as **ADR-0015**'s subject and takes no position on
it), `harness-lead` itself may become an implementer of harness/`loop` changes rather than purely
advisory — today it holds no `Write` (`agents/harness-lead.md:4`) and gates nothing. **A rejected
alternative for THAT future decision, named here so it is not silently reintroduced**, would be to let
`loop` issues route to `harness-lead` alone for both proposing and building in one dispatch. The
owner's stated mitigation for that later decision is that proposal and build ship as **separate
dispatches under separate Issues**, restoring "a different actor reads it" at the artifact level — the
same principle tier 3's independent gate protects on `product`/`content`, applied where tier 3 does not
exist. **This record does not resolve it** — one decision per ADR, and the persona-capability question is
a different decision than the routing-axis question this record makes.

## Consequences

**Good**

- **`loop` now passes the same test `type:*` failed** — `dev-loop/SKILL.md:123`'s *"something must query
  it"* is satisfied **because of corollary 1**: `(product OR loop) AND ready` is a real query against a
  real label, once the predicate is updated. Say this explicitly (S4), since it is what makes `loop`
  different from the vocabulary this repo already killed, and not merely a new label added by fiat.
- **The routing this repo's own diagram and label table already assert stops being fiction.** `README.md`
  and `dev-loop/SKILL.md` were describing a `loop` lane that the label vocabulary could not produce; this
  decision closes that gap from the vocabulary side.
- **A real builder exists for a real lane.** Corollary 3 turns `content`'s "nobody mechanically builds
  this" (2 of 13 pure-`content` issues ever closed) into a routed, staffed path.
- **The label-decides-class decoration is named rather than left implicit** — corollary 2 is honest about
  the fact that exclusivity is being imposed on a vocabulary that was already leaking into a role
  (merge-class) it doesn't actually hold.

**Bad / accepted costs**

- **Relabeling is currently ungated for every persona — an open question, not resolved here.** Measured:
  neither `hooks/scripts/permission-guard.sh` nor `hooks/scripts/wip-guard.sh` keys on `gh issue edit` or
  `gh label`, and both are in `.claude/settings.json`'s committed `allow` list:

      grep -n "gh issue edit\|gh label" .claude/settings.json
      → 51:      "Bash(gh issue edit:*)",   54:      "Bash(gh label:*)",
      grep -rn "issue edit\|gh label" hooks/scripts/*.sh
      → (no matches in either guard script)

  Under this decision, **any subagent can move an issue into the ungated `loop` lane with one command** —
  a lane that (per `README.md:181-182`) skips tier 3 entirely and reaches the owner directly. Making
  `loop` a real, exclusive, high-consequence lane raises the cost of that gap without closing it. **Left
  as an open question rather than a silently accepted cost**, because closing it is a *which-layer-can-
  carry-this-control* question (ADR-0008), not a routing decision, and belongs in its own record or a
  `harness-lead` dispatch — not invented here to make this ADR read as more finished than it is.
- **Corollary 2's migration is real work with no owner named here.** The 8 dual-labelled issues in
  `tadeumendonca-io` need a human or lead decision per issue; this record does not make those 8 decisions.
- **Corollary 3 is an explicit override of a precondition the loop itself set** (#161's "measure before
  adding a persona"). Recorded as what it is — an owner override, not a violation quietly smoothed over —
  and #161 stays open as the calibration Issue rather than being closed by #187 shipping.
- **The gate that would keep `quality-assurance`'s boundary-class list in sync with `dev-loop`'s "a change
  to the loop's own rules" clause is a pre-existing, separate defect** (ADR-0011's own citation of the
  same drift) that this decision does not fix — a `loop`-typed change is exactly the kind of change that
  drift already fails to catch, and making `loop` load-bearing does not repair the sync it depends on.

## What this record does NOT decide

- **`README.md:166-169,181-182`'s diagram correction.** Measured: `agents/tech-lead.md:3-4` is the sole
  ADR author (`Write, Edit`, skill `adr`) and `harness-lead` holds neither `Write` nor a merge role
  (`agents/harness-lead.md:3-5`) — so `loop` issues, which are the ones most likely to produce an ADR,
  need to route to **both** `harness-lead` and `tech-lead`, not the single `NI -->|loop| HR` edge the
  diagram draws today (S6). Following this repo's own citation discipline (ADR-0011 names files it does
  not edit — e.g. `commands/autonomy-on.md`, `commands/new-issue.md` — as consequent work rather than
  editing them in the deciding record), **this ADR names the correction owed to `README.md` and does not
  make it.** `README.md` is outside this ADR's scope (`docs/adr/**` only); the fix is separate consequent
  work, already partly tracked at [#184](https://github.com/tedeuxx/tadeumendonca-skills/issues/184).
- **Whether relabeling should be gated**, and if so at which layer. Named above as an open question
  (S3), not resolved.
- **ADR-0015's subject** — whether `harness-lead` becomes an implementer of `loop` changes. Named as
  a forward reference only (S7).
- **Task-as-Issue-child.** A separate, later decision. Named here only as a known collision for that
  future ADR to inherit: `hooks/scripts/wip-guard.sh`'s overlap rule deliberately removed a "two sibling
  PRs in one story may touch the same file" exemption after measuring zero task branches across ~90 —
  whichever ADR decides task-as-child must reconcile with that measurement (S8). One-line pointer only;
  not analysed further here.
- **Whether the current 8 dual-labelled `tadeumendonca-io` issues get migrated to `product` or to
  `content`**, individually. Corollary 2 states the rule; it decides no individual issue.
- **How many issue types the loop should ultimately have**, or whether granularity (story/task/proposal)
  should ever become a second, orthogonal axis. Both are explicitly out of scope (see *Considered
  options*, option 2).

## Amendment (2026-08-13) — the earlier reconciliation this decision builds on, carried here from `dev-loop/SKILL.md`

**Relocated, not new.** `skills/principles/dev-loop/SKILL.md` carried this measurement inline under a
"One vocabulary across every repo" heading; the harness-engineering consolidation
([#224](https://github.com/tedeuxx/tadeumendonca-skills/issues/224)) moved it here, to the ADR that
already owns the label-vocabulary decision, rather than restating it in the operative skill.

Before `product` / `content` / `loop` existed as the routing axis, the first pass at reconciling this
repo's label vocabulary against a sibling repo's found **incompatible taxonomies**: one used `product`
/ `content` / `reader-facing`, the other a scheme (`type:*`, `phase:*`, `priority:*`, `semver:*`,
`status:blocked`) that was almost entirely unused. Reconciled to one vocabulary (owner decision,
2026-08-02).

**The measurement, corrected in review and stated precisely because the first version was wrong in
three places** — it said "88% dead, four labels used, on four Issues, 29 of 33". Re-derived from the
repository's label events, which is the only source that survives the deletion:

- the repo had **34** Issues, **29** carrying no label at all;
- of the **15** labels retired, **11 were never applied to anything**, and four were:
  `type:feature`, `phase:1`, `semver:minor`, `semver:patch`;
- on **Issues** only three of them ever appeared — on #4–#7, all closed in the repo's first week;
- `semver:*` also landed on **eight merged PRs**, which the original count missed entirely.

*Why the correction is recorded rather than quietly fixed:* the original figure mixed two
populations, taking "four labels" from a PR-inclusive set and "four Issues" from an Issue-only one.
That is precisely the shape of error this whole record is about — a number that reads as measured and
was assembled. `type` and `priority` restated what a title and an order already say; `phase` described
a roadmap that ended; `semver:*` was vestigial from a **different loop model** (`gitflow-multi-env`,
where `/versioning` still documents label-driven bumps); `status:blocked` survives as `blocked`,
renamed for consistency rather than dropped.

## Links

- [#184](https://github.com/tedeuxx/tadeumendonca-skills/issues/184) — the owner's own statement that
  issues route to different agent families by type, and the measured mismatch between `README.md`'s
  diagram/prose and the label vocabulary that would have to back it; not yet `ready`, and this ADR does
  not close its intake.
- [#161](https://github.com/tedeuxx/tadeumendonca-skills/issues/161) — the measured-delta precondition
  corollary 3 overrides; remains the calibration Issue for the `writer` brief.
- [#187](https://github.com/tedeuxx/tadeumendonca-skills/issues/187) — tracks building the `writer`
  persona; re-derived as real and matching corollary 3's description.
- `docs/adr/0011-a-skill-exists-to-be-assigned-to-a-profile.md` — cited for its citation discipline (name
  consequent work in files this ADR does not touch, rather than editing them) and for the still-open
  `dev-loop`/`quality-assurance` boundary-class drift this decision does not repair.
- ADR-0002 (tenth amendment) — cited for *reconciliation cost is paid within a tier*, the driver behind
  naming rather than resolving S7.
- ADR-0008 — cited for *which layer can carry a control*, the reason S3 is left an open question rather
  than resolved here.
- **Evidence re-derived on this branch, not relayed:** `gh label list` (5 project labels, no `loop`);
  `gh issue list --state all --limit 30` (12 of 13 open issues carry `product`); `commands/autonomy-on.md:15`
  (`product`+`ready` predicate); `commands/new-issue.md:101` (the "apply product or content" step);
  `agents/product-lead.md:4` (no `Write`); `agents/developer.md:1-9` (`Write` + `apps/**`);
  `agents/harness-lead.md:3-5` (`skills: []`, no `Write`); `agents/tech-lead.md:2-8` (sole `adr`
  skill holder with `Write, Edit`); `.claude/settings.json` (`gh issue edit`, `gh label` in `allow`);
  `hooks/scripts/permission-guard.sh` and `hooks/scripts/wip-guard.sh` (neither keys on either command);
  `dev-loop/SKILL.md:61-68,123-139,475,477`; `agents/quality-assurance.md:710-718`; `README.md:150-194`;
  Issues #161 and #187 fetched directly (`gh issue view`); and
  `gh issue list --repo tedeuxx/tadeumendonca-io --state all --label content --limit 40` (21 total, 8
  dual-labelled with 6 closed, 13 pure-`content` with 2 closed) — this last one corrected after the
  gate on this PR caught an earlier draft mixing the pure population's numerator with the total
  population's denominator ("2 of 21" against "7 of 8"); the corrected figures are 2 of 13 and 6 of 8.
