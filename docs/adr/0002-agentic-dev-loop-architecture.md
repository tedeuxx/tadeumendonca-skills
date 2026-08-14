# 0002. Agentic dev-loop architecture — per-task subagents, ADRs as the durable brain

- **Status:** accepted · **amended 2026-07-23** (twice — the product/decision-support layer joins the roster) · **amended 2026-07-24** (amendment #3 — the roster reshapes: `product-owner` re-scoped, `brand-guardian`/`editor`/`recruiter`/`scrum-master` join; owner-ratified, implementation sequenced in follow-on slices per issue #69) · **amended 2026-07-29** (amendment #4 — the `brand-guardian` trigger becomes a fail-closed rule instead of a path list; `-io`#202) · **amended 2026-07-30** (amendment #5 — `product-manager` gets a trigger, discharging #68's debt for it; the reviewer's output gets a round budget) · **amended 2026-08-01** (amendment #6 — a finding blocks only by naming a criterion and a falsifier; the DoD grows criterion 10; the lenses self-classify severity; the round budget drops to two) · **amended 2026-08-02** (amendment #7 — the roster drops 19 → 6 on a new criterion: a persona exists only where conflict is wanted; three leads, one fullstack builder, two gatekeepers) · **amended 2026-08-02** (amendment #8 — the intake chain: nothing worked outside the tracker, the three leads close the issue's description, and those requirements become the gate's external ruler; both gatekeepers approve every MR in parallel; the builder delivers the E2E suite) · **amended 2026-08-04** (amendment #9 — `marketing-lead` merges into `product-lead`; the roster drops 6 → 5; the blocking-truth clause is carried across explicitly, and the capability floor that backed it is not) · **amended 2026-08-04** (amendment #10 — `harness-lead` joins tier 1 as the owner's pair on the machinery, advisory and pre-implementation; `security` is **absorbed** into `quality-assurance`, which now holds two lenses in one pass and labels every finding with its lens. The roster is still **five** and **two of its members changed**. The persona criterion widens from *conflict wanted* to **four reasons**, with reconciliation cost paid **within** a tier. Amendment #9's *"both approvals are still required"* is **struck**. Books the rule that produced the gap: **a count is not an identity**) · **amended 2026-08-13** (amendment #13 — `writer` joins tier 2 as a content-scoped second builder; the roster grows 5 → 6; it satisfies none of the four reasons and is named plainly as an owner override; `permission-guard.sh` rule 5e inverted from a denylist to an allowlist to contain it; the `Write`/`Edit` observability gap is accepted in writing rather than closed mechanically)
- **Date:** 2026-07-22
- **Deciders:** the owner
- **Driven by:** [ADR-0001](./0001-adopt-madr-adrs.md), `docs/proposals/agentic-dev-loop.md`

## Context & problem
The dev-loop needs to (a) optimize the context window, (b) eliminate the authorship bias that appears when
one agent both writes and reviews, and (c) scale beyond what a single context can hold. How the loop is
structured — one agent doing everything vs. a team of specialized contexts — determines whether those
three properties are achievable.

## Decision drivers
- Context efficiency — an agent should carry only what its task needs, not the whole session.
- Bias elimination — review must not be done by the context that wrote the code.
- Reuse — the machine should be usable across projects (it lives in the plugin).

## Considered options
1. **Per-task subagent contexts (personas × ephemeral instances), orchestrated via artifacts** (chosen) —
   a *persona* (frontend-react, critical-reviewer, …) is a reusable definition wielding a scoped
   skill/tool/model bundle; each *invocation* is a fresh, discarded-after context loading only its task.
   The main loop orchestrates; subagents hand off through artifacts (Issue, spec, ADR, diff), not a shared
   context. **ADRs are the durable shared brain** a fresh context reads to stay coherent. *Trade-off:*
   orchestration overhead and per-subagent cost.
2. **One generalist agent doing all layers** — *Why not:* no context optimization (it carries everything),
   and review carries authorship bias (it defends its own code).
3. **Fixed long-lived specialist agents** — *Why not:* standing agents accumulate cross-task context,
   losing the per-task isolation that gives both the optimization and the bias elimination.

## Decision outcome
Chosen: **per-task subagent contexts**. A subagent is an *autonomous context specific to a task*, not a
standing employee. Because a fresh context cannot remember prior decisions by construction, the ADR
libraries (ADR-0001) are what make the isolation safe — without them, isolation is a drift machine. The
roster (20 personas covering a common SDLC — 22 since the two 2026-07-23 amendments below, and **26 once the third amendment is ratified**) is defined in the plugin; each project enables the subset its
blast-radius justifies, and personas are materialized lazily as work demands. Full detail:
`docs/proposals/agentic-dev-loop.md`.

## Amendment (2026-07-23) — `product-owner`: the copy gets a reviewer

> **Superseded in one clause by the 2026-08-01 amendment below.** The premise *"a positioning breach is
> not a DoD criterion"* was true when written and is now false: the DoD has a criterion 10. The rest of
> this amendment — the mandate, the capability guarantee, the trigger living in `critical-reviewer` —
> stands unchanged. Kept as written rather than edited, per this library's rule: supersede, never
> rewrite.

**Problem.** The reviewer roster has **no mandate over what the words claim**. `critical-reviewer`
judges a diff against the Definition of Done, and a positioning breach is not a DoD criterion — so on a
presence where the copy *is* the product, an unearned claim, a cross-surface contradiction or a
confidentiality slip **ships green**. Reviewing them was left implicitly to the human, which meant they
reached the human unreviewed, inside a PR already marked green, at the moment of least attention.
Observed, not hypothetical: four such defects in one MR (`tadeumendonca-io#81`), all found by
`critical-reviewer` being thorough rather than by anything being responsible for them.

### Considered options
1. **A `product-owner` persona, advisory, triggered from `critical-reviewer`** (chosen) — a fresh
   context whose ruler is the owner's private positioning source. *Trade-off:* a second context per
   content MR, and its trigger is an instruction inside another persona rather than a mechanism.
2. **Extend the DoD (ADR-0003) and give `critical-reviewer` the positioning mandate** — *strongest
   rejected alternative*, and it wins on the axis option 1 is weakest: `critical-reviewer` already runs
   on **every** MR, so the trigger problem disappears. Rejected because it requires giving the merging
   persona read access to the **private** `.brand/` source. That persona has `Bash`, merges, and writes
   to public PRs — pointing it at the strategy layer puts the leak risk in the one context with the most
   publishing capability. Keeping the private source in a **read-only, write-incapable** persona is
   worth the weaker trigger.
3. **Leave it human** (the status quo) — *Why not:* it *was* human, and the failure mode is exactly that
   the human receives content defects inside a green PR with no signal that nobody checked the copy.

### Decision
**`product-owner`**: reviews reader-facing copy — claims the author has not earned, unsourced
quantification, precision drift against the canonical CV data, cross-surface coherence, confidentiality,
third-party naming, reader-first framing, durability. Runs where a repo marks content boundary **by
path** *(the persona moved to `brand-guardian` in amendment #3; the by-path trigger is **superseded by
amendment #4** below, which replaces it with a fail-closed rule)*. It is **advisory** and has **no write capability at all** (`Read, Grep, Glob` — no `Bash`,
`Edit` or `Write`), so *"product ownership stays human"* holds in substance: it cannot edit copy, cannot
merge, cannot even post its own findings. The voice stays the owner's.

**The trigger lives in `critical-reviewer`**, the only persona guaranteed to run on every MR: a diff
touching content-boundary paths is **incomplete** until `product-owner` has returned a verdict, and the
reviewer must report that verdict or state that it did not run. A mandate with no trigger is a document,
not a gate.

**Privacy is structural, not a promise.** The positioning source is private and gitignored while
findings land in **public** PRs, so `product-owner` references rules by **stable identifier and
location** (`positioning.md §X, bullet N`) rather than restating them — paraphrase leaks the substance
while technically not quoting. Written that way the output is inert outside the private context. Backed
by the tool grant: the one persona whose output is dangerous in public cannot publish it (ADR-0004 — the
boundary should be a capability, not a promise).

### Consequences
**Bad / accepted costs**
- **The trigger is an instruction, not a mechanism.** It hangs off `critical-reviewer` reading its own
  definition. Weaker than the `PreToolUse` guards this repo uses elsewhere, and the honest reason it
  ships this way is that the hook form is a larger slice.
- **Two contexts per content MR** — more tokens, more latency, on the MRs that already carry the most
  review.
- **No tie-break** between `product-owner: ADJUST` and `critical-reviewer: APPROVE-AND-MERGE`. Currently
  benign because content is boundary class and escalates anyway; it becomes real if that ever changes.
- **The private source is read by an agent.** Mitigated by the identifier-only output rule and the
  absent write tools, but not eliminated — a residual accepted deliberately.

Roster: 20 → 21 defined.

## Amendment (2026-07-23, second) — the layer that prepares the owner's decisions
The owner named themselves **CEO of the initiative**, which settles the question the first amendment
left open. *"Product ownership stays human"* is not loosened; it is made precise. The roster gains the
layer that **prepares** a decision, and the owner keeps the layer that **makes** it.

**`product-manager` — proposes the order; the owner approves it.** Withheld one revision earlier for
lack of evidence (#65). The evidence, stated as `gh issue list` actually returns it rather than from
memory: in one session the consuming repo's open queue went **2 → 7** (8 filed, one closed), and the
plugin repo **0 → 4** — eleven open items, nothing sequencing them, and several that interact.

*Weakest of the three, and worth saying so:* that is evidence of the **precondition** — an unsequenced
queue — not of a slice built in the wrong order at a cost. `analytics` and `debugger` each rest on an
observed failure. This one rests on a growing backlog, which is a leading indicator. Its every verdict
(PROCEED · RESEQUENCE · RESCOPE · DEFER) is a **proposal**; it writes nothing and merges nothing.
The proposal's *"backlog prioritization stays human"* bullet is amended in place rather than worked
around — a recommendation the owner cannot audit is worthless, and one they cannot overrule is a
decision in disguise.

Two personas already **defined** in the design were also **materialized**, each on observed failure
rather than on roster completeness:
- **`analytics`** — the consuming repo's `CLAUDE.md` asserts Google Analytics as part of "done", **and so
  does its `accepted` ADR-0023**, while the app contains **no analytics of any kind** (grep for
  gtag/googletagmanager/plausible/umami/posthog over `src`, `index.html`, `public`, `package.json`,
  `iac/`, `.github/`: zero hits). An accepted ADR describes a system property that does not exist, and
  the DoD item covering it is checked by whoever wrote the slice. *(Duration, corrected: the GA claim
  entered `CLAUDE.md` and ADR-0023 on 2026-07-22 — one day. The generic "observability is part of done"
  line dates to 2026-06-21. An earlier draft of this amendment said "for months"; that was asserted, not
  checked, which is the exact defect this persona exists to catch.)* It owns *how would we know this
  worked*, and it treats the cookie-vs-cookieless choice as an **owner decision it surfaces**, not one it
  presumes — on a site whose stated property is that nothing third-party loads until asked, adding a
  tracker is architecture, not config.
- **`debugger`** — two non-trivial failures in one session, both mis-hypothesised first: a suite silently
  targeting the deployed environment instead of the local build, and a green E2E run against a stale
  `dist`. Both were diagnosis problems, and in both the first plausible hypothesis was adopted before
  being tested. Its output is a **cause with evidence**, never a patch — a context committed to a fix
  stops looking for the cause the moment its fix works.

**`ux` was deliberately NOT materialized**, although the design marks it enabled. The reason is
*absence of evidence*, and only that: no visual decision in that session was blocked, reopened, or made
worse for want of a UX reviewer. *(An earlier draft claimed the visual decisions "held up" — one did not:
the OG card needed a corrective slice, `e87a271`. But that was a metadata defect the `performance` and
review lenses would own, not an information-architecture or a11y one, so it does not become UX evidence
either.)* Materializing on a roster row rather than on work is the theatre this design warns against —
*"a persona with no work costs context and implies coverage that isn't there"*.

### `critical-reviewer` gains a second escalation duty — recorded, because it is a decision
The same edit that gives `debugger` a trigger **expands the reviewer's mandate on every future MR in
every consuming repo**: it may now hold a MR whose gates are **green** when it cannot say *why* they are
green — red-then-green with no fix visible in the diff, a job that matched no files, a suite re-run until
it passed. That is a real widening of when review blocks, and it belongs in the ADR rather than only in
the persona file. The justification: a DoD gate is evidence only when someone can explain it, and "it
passes now" is how a wrong model of a failure survives into `main`.

### Consequences of this amendment
**Bad / accepted costs**
- **Three more contexts** to spawn, on a loop whose per-invocation cost is already an accepted downside.
- **`analytics` opens a privacy decision** that did not previously exist. Surfacing it is the point, but
  it is new surface area, and answering it wrong is publicly visible on a site that argues for restraint.
- **The reviewer can now block a green MR** (above). Correct in intent, and a new way for review to stall
  on a judgment call rather than on a failed check.
- **Trigger asymmetry.** `debugger` has one (in `critical-reviewer`); `product-manager` and `analytics`
  do not, though `planner` is the obvious host for the first. By this design's own line — *a mandate with
  no trigger is a document* — two of the three ship as documents. Tracked in #68, which also records the
  deeper problem: every trigger is an **instruction**, and chaining three of them off `critical-reviewer`
  means the moment it does not run, three mandates silently do not run either.
- **`Bash` contradicts the "advisory" framing at the capability level.** All three carry
  `Read, Grep, Glob, Bash`, and a consuming repo that allowlists `gh pr merge` grants it through the
  inherited permission surface. So *"writes nothing, merges nothing"* is **behavioural for these three**,
  where the first amendment made it **capability** for `product-owner` by withholding `Bash` entirely.
  The grant is functionally justified (`gh issue list` for the queue, reproduction for diagnosis), so it
  is accepted rather than removed — but it is the weaker guarantee, and this ADR argues the opposite two
  sections above.

Roster: 21 → 22 defined; **15 materialized** (counted from `agents/*.md`, not asserted — the two numbers
drift precisely because "defined" is a design claim and "materialized" is a file on disk).

## Amendment (2026-07-24, third) — the roster reshapes: `product-owner` becomes a product owner; the copy mandate becomes `brand-guardian`
**Status: accepted (owner-ratified 2026-07-24, issue #69).** The decision is ratified; the reshape is
**implemented in the follow-on slices sequenced below** — nothing in this amendment is materialized in
`agents/` yet, so read it as the decided target state, not the current roster.

**This amendment supersedes the scoping of `product-owner` set in the first amendment above** — it does
not rewrite it. The first amendment stands as the record of *why the copy first got a reviewer* and
*how its privacy guarantee was designed*; that reasoning is not reversed, it is **relocated**. What
changes is only the **name and home** of the mandate: everything the first amendment built for
`product-owner` (the checks, the `Read, Grep, Glob`-only capability, the escalate-never-edit design,
the identifier-only output rule) moves **unchanged** to a new persona, and the `product-owner` name is
freed to mean what it says.

**Why reshape.** The first amendment named the copy guardian `product-owner` because that was the gap in
front of it — but the name asserts a role the persona does not fill. A *product owner* owns
reader/user value and feature-level acceptance from the product side; what that persona actually does is
guard **positioning and copy coherence against a private brand source**. Two different mandates wore one
name. On a proof-of-engineering presence the distinction was cheap to ignore (the copy *is* the product,
so the guardian looked product-shaped); as the roster models a whole org it stops being cheap — a future
consuming repo with a real product and a real backlog needs both roles, and cannot get them from one
overloaded definition.

### The five moves (one decision each)
1. **Re-scope `product-owner` to a genuine software product owner.** Its mandate becomes reader/user
   value and **feature-level acceptance from the product side** — it proposes acceptance of a slice
   against what the product promised the user, distinct from `critical-reviewer` (which judges the diff
   against the engineering DoD) and from `product-manager` (which judges *whether/when*, upstream of the
   spec). It **stays advisory**: it proposes acceptance, never decides it and never merges. So *"product
   ownership stays human, narrowed to product decisions"* — the first amendment's own reconciliation —
   **remains true in substance**; what narrows is the noun, not the authority. On `tadeumendonca-io`
   specifically it likely has **no work** (a static content presence — "the product is the words", so
   product acceptance and copy conformance collapse into the same review, and that review is
   `brand-guardian`'s). It is therefore **defined-but-not-materialized in `-io`**, exactly the `ux`
   precedent from the second amendment — *materialize on observed work, not on a roster row.*
2. **New persona `brand-guardian` — the extracted copy mandate, carried over intact.** It inherits the
   positioning/coherence mandate the first amendment built, **unchanged**: the same checks (claims the
   author has not earned, unsourced quantification, precision drift against the canonical CV,
   cross-surface incoherence, confidentiality, third-party naming, durability), the same escalate-to-owner
   verdict, the same never-edits-the-copy design. **Critically, it keeps the `Read, Grep, Glob`-only
   capability with no `Bash`, `Edit` or `Write`.** That grant is the strongest thing the first amendment
   established (ADR-0004: the boundary is a *capability*, not a promise) — the one persona that reads the
   **private** `.brand/` source and whose output lands in **public** PRs is structurally unable to
   publish. **This guarantee must not be weakened in the move**; the rename is the whole change, the tool
   surface is identical. The name is `brand-guardian` deliberately: the owner **rejected
   `brand-strategist`** because "strategist" implies *deciding* strategy, which is the owner's alone —
   the persona **guards** conformance to a strategy it does not set.
3. **Re-point the `critical-reviewer` content-boundary trigger from `product-owner` → `brand-guardian`.**
   The wiring the first amendment installed — *"a diff touching content-boundary paths is **incomplete**
   until `<persona>` has returned a verdict"* — is unchanged in shape; only the persona it names moves.
   *(The by-path half of that wiring is **superseded by amendment #4** below, which replaces it with a
   fail-closed rule. The persona this item re-points to is unchanged.)*
   This is the load-bearing part of the atomic slice below: if the rename lands and this trigger still
   points at the (now re-scoped) `product-owner`, the content gate silently points at a persona that no
   longer holds the copy mandate, and a positioning breach ships green again — the exact failure the
   first amendment closed, reopened.
4. **New persona `editor` — long-form craft & rigor.** Owns article/long-form **clarity, structure,
   explicit trade-offs, technical soundness, and reader-first prose/framing**. The seam with
   `brand-guardian` is drawn deliberately: **`brand-guardian` owns claim-vs-truth and cross-surface
   coherence** (does the copy match our positioning and each other?); **`editor` owns
   clarity/structure/argument/technical-soundness** (is the piece well-made and sound on its own terms?).
   *Reader-first framing sits with `editor`* — it is a craft property of the prose, not a positioning
   conformance check. A sentence can be perfectly on-positioning and badly argued; that is `editor`'s
   catch, not `brand-guardian`'s.
5. **New persona `recruiter` — the outward market/hiring lens.** For the owner's recolocation: **LinkedIn
   best-practice/profile score, ATS/keyword fit, the hiring-manager read, and fit to target AI-Engineer
   roles.** The seam with `brand-guardian` is **internal-vs-external**: `brand-guardian` checks *internal
   conformance* (does this copy match our positioning?); `recruiter` checks *external efficacy* (does that
   positioning **win** with a hiring manager, and pass an ATS?). It is **boundary-class by construction** —
   it targets external public surfaces, which the consuming repo's guide already treats as ask-first.
6. **New persona `scrum-master` — process/flow discipline.** Enforces that **every piece of work becomes a
   tracked Issue before it is called done, WIP=1 is honoured, and the board reflects reality.** It is the
   persona against the untracked-sprawl failure mode — the sibling to `product-manager` (which sequences
   the queue) on the *hygiene* axis rather than the *priority* axis. **Advisory, never merges.**

### Considered options
1. **Extract the copy mandate to `brand-guardian` and free `product-owner` to mean product ownership**
   (chosen) — names match roles, the privacy-critical capability guarantee rides along untouched, and the
   org model gains the three real gaps (`editor`, `recruiter`, `scrum-master`). *Trade-off:* four new
   persona files, a reference sweep across the roster, and a re-scope that must be recorded as a supersede
   rather than a silent edit (this section is that cost paid).
2. **Keep `product-owner` as the copy guardian and add the new personas around it** — *strongest rejected
   alternative.* It avoids the supersede and the rename churn. Rejected because it **entrenches the
   misnomer**: the persona keeps a name asserting a role it does not fill, and the first consuming repo
   with a genuine product backlog inherits an overloaded definition it must then split under pressure.
   Paying the rename now, while `-io` is the only consumer and the copy guardian has no product work to
   collide with, is strictly cheaper than paying it later.
3. **Fold `editor` into `brand-guardian` and `recruiter` into "positioning"** — *Why not:* it recreates
   the exact overloading this amendment exists to undo. Craft-soundness, positioning-conformance and
   market-efficacy are three different rulers with three different sources of truth (the piece itself, the
   private `.brand/` source, the external hiring market); one persona holding all three reviews none of
   them well.

### Rejected as duplicates — recorded so they are not re-proposed
- **`career-advisor`** — this *is* the positioning/copy mandate now carried by `brand-guardian` (guarding
  the owner's professional narrative against the canonical source). A separate persona would duplicate it.
- **A separate "QA funcional"** — this *is* the existing `qa-e2e` persona, which already owns functional
  E2E regression as the proof nothing already working broke. A second persona for it is redundant surface.

### Sequencing — the implementation plan this amendment authorises
The reshape ships as **discrete slices**, in order, each merged before the next (WIP=1):
1. **This amendment → owner ratifies (`proposed → accepted`).** Nothing below starts until it is accepted.
2. **ATOMIC slice, must ship together:** re-scope `product-owner` (move 1) **+** author `brand-guardian`
   (move 2) **+** re-point the `critical-reviewer` trigger (move 3) **+** a full reference sweep (every
   mention of the old copy-guardian scoping across `agents/*.md`, `CLAUDE.md` roster prose, and the
   proposal). These cannot be split: any partial landing opens a content-gate gap — either a re-scoped
   `product-owner` with the trigger still pointing at it, or a `brand-guardian` no trigger reaches.
3. **`editor`** — separate slice.
4. **`recruiter`** — separate slice.
5. **`scrum-master`** — separate slice.

*(The persona `agents/*.md` files and the `CLAUDE.md` roster prose are the **implementation** of moves
1–3 and 4–6 — they are authored in the slices above, not in this ADR. This amendment is the record and
the plan; it does not itself edit any persona definition.)*

### Consequences of this amendment
**Good**
- Names match roles: `product-owner` means product ownership, `brand-guardian` means positioning
  conformance. The overloaded definition is split before a consuming repo is forced to split it in a hurry.
- The privacy-critical capability guarantee (`Read, Grep, Glob`, no `Bash`) survives the rename intact —
  the reshape is capability-preserving by explicit constraint, not by hope.
- The org model gains three genuine gaps: long-form craft (`editor`), external market efficacy
  (`recruiter`), and flow hygiene (`scrum-master`) — each a ruler nothing currently holds.

**Bad / accepted costs**
- **A re-scope is a reversal, and reversals cost trust in the record.** The first amendment argued for
  `product-owner`-as-copy-guardian; one day later this one moves it. Mitigated by superseding (not
  rewriting) that amendment and stating the reason, but the churn is real and recorded honestly.
- **The atomic slice is the failure surface.** Three coupled edits plus a repo-wide reference sweep must
  land together; a missed reference leaves the content gate pointing at the wrong persona, and unlike a
  test that gate fails **silently**. The sweep is the mitigation and it is fallible.
- **Four more persona files** — more roster to maintain, and three of them (`editor`, `recruiter`,
  `scrum-master`) ship as **documents without a mechanical trigger**, inheriting the trigger-asymmetry
  debt the second amendment already booked (#68). A mandate with no trigger is a document, not a gate.
- **`recruiter` reaches for external public surfaces**, which is new blast-radius: its lens is only useful
  aimed at LinkedIn/ATS artefacts, and those are the least-reversible, most-public surfaces the owner has.
  Boundary-class by construction is the containment, but the surface is real.

Roster: 22 → **26 defined** once ratified (four new files: `brand-guardian`, `editor`, `recruiter`,
`scrum-master`; `product-owner` is **re-scoped, not added**, so it does not increment the count).
**Materialized-in-`-io` is decided in the implementation slices, not here** — `product-owner` is expected
to stay *defined-but-not-materialized in `-io`* (the `ux` precedent), and the materialized count will be
recounted from `agents/*.md` when each slice lands, never asserted ahead of the file.

## Amendment (2026-07-29, fourth) — the content trigger becomes a fail-closed rule, not a path list

**What changes.** The `brand-guardian` trigger installed by the first amendment and re-pointed by the
third — *"a diff touching content-boundary **paths** is incomplete until the persona returns a verdict"* —
stops being expressed as a path set. The persona is unchanged, the mandate is unchanged, the wiring in
`critical-reviewer` is unchanged. Only what the trigger tests changes:

> If a diff changes **words or images any reader will see — human or machine** — on the product, in a crawler's card, or on any
> external surface the work publishes to — the review is incomplete until `brand-guardian` returns a
> verdict. The file they live in is irrelevant. A repo guide may enumerate today's content paths; that
> list is an **aid, never the definition**.

**Why.** A path enumeration **fails open**: anything unlisted reads as safe class and merges with no copy
review at all. That is not a theoretical property — it failed twice in the consuming repo, and both times
the miss was caught by accident rather than by the gate:

- `-io`#233 — the portfolio-copy module sat outside the list, so edits to **published** copy classified as
  safe class.
- `-io`#202 — a generator constant held a hashtag set **bound for** a post scaffold the owner voices and
  publishes under his own name, in a path classified as build tooling. `brand-guardian` never ran, and
  the set the generator first emitted had been **invented by the agent**, against the consuming repo's
  explicit *"do not write positioning copy from memory."* It was a **near-miss, not a breach** — the set
  was corrected before it was ever used, and only because someone read an unrelated issue's comments and
  noticed the owner had already stated his own. Remove that coincidence and agent-authored copy reaches
  the owner's byline with no copy review having happened.

The pattern is general and it grows: any generator, template or constant producing text bound for a public
surface escapes a path test. The trigger has to be about **what the diff changes**, not **where**.

**Why not a check.** `-io`#202 proposed a marker convention (a tagged export, a `copy/` module) so new
files opt in by construction. Rejected **as the sole gate**, and the reason generalizes: a check can
assert that every *listed* path still exists, catching a rename — it cannot catch **omission**, and
omission is the failure that actually happens. No check knows about a file nobody thought to list, and a
marker does not opt in by construction either: someone still has to apply it, and the author who does not
know the convention exists is exactly the author who wrote the unlisted generator.

Where the marker is genuinely better, stated rather than argued past: **locality**. It is applied at the
site of authorship, by the person writing the copy, at the moment they write it — while a path list is
edited in a distant file by someone who must remember it exists. Same failure reason, materially
different miss rate. So the marker is **viable as a complement** and is rejected only as the thing the
gate rests on. Enforcement rests on the **phrasing**, which is why the rule is phrased to fail closed:
when you cannot tell whether a string is reader-facing, it is.

This is `-io`#202's own **option 3**, which that issue judged *"probably too fuzzy to be a gate"* — worth
naming, since adopting the option the issue doubted is a claim that its doubt was misplaced. It was not
misplaced, it was mispriced: fuzziness is real and is booked as the cost below. What the issue weighed it
against was a mechanism that fails silently and in the direction that ships.

**Cost, accepted.** A rule is not mechanical, so it is applied by judgement and will sometimes over-trigger
— `brand-guardian` invoked on a diff whose only string is a log message or a test fixture. That is the
direction the error should point: a wasted advisory review is cheap, and a positioning breach on the
owner's public byline is not.

It also means this trigger **cannot be tested** — no assertion can decide whether a string is
reader-facing. It is **not unobservable**, and the distinction matters: `critical-reviewer` already owes a
mandatory disclosure on every MR (*report `brand-guardian`'s verdict, or state plainly that it did not
run*), so under-application leaves a trace in the review record and is auditable after the fact. That
disclosure is the only instrument this rule has, which makes it load-bearing rather than a courtesy —
a review that silently omits it removes the one way anyone could tell the gate had stopped firing.

## Amendment (2026-07-30, fifth) — `product-manager` gets a trigger, and the reviewer's output gets a budget

Two changes to the roster's wiring, from one session's evidence: **17 issues closed and not one from the
owner's product queue**, which stayed frozen for four days while the agent drained defects it had found
itself.

### 1. `product-manager` gets a trigger — discharging a consequence this ADR booked about itself

Amendment #2 recorded the debt in its own accepted costs: *"`product-manager` and `analytics` do not
[have a trigger] … By this design's own line — a mandate with no trigger is a document — two of the three
ship as documents. Tracked in #68."*

The session made that concrete. `critical-reviewer` was invoked **15 times**, `brand-guardian` **7**,
`product-manager` **zero** — while it was enabled the whole time and the order of work was decided
ad hoc.

The trigger is a **condition, not a frequency**, and it lives in `/principles/dev-loop`:

> Starting a slice that is **not** the top of the stated order requires `product-manager` to have
> returned a new order, or the session records that the order is unchanged.

**#68 offered a different host** — *"give the two orphans a host — `planner` for `product-manager`"* —
and that option is not taken. `planner` fires when a slice is already being designed, which is after the
order has been chosen; hosting the trigger there would fire it too late to change anything. The dev-loop
skill is read at the moment work is picked, which is the moment the trigger is about. #68 stays open for
`analytics`, whose orphaned trigger is untouched by this.

### 2. The reviewer's output gets a round budget — the same class as #2's escalation duty

From the **fourth** round on one slice, `critical-reviewer`'s verdict is accompanied by a **decision
request**: rounds consumed, what remains, and an explicit choice — push through, park, or narrow.

Recorded here rather than only in the persona file, on the precedent this ADR set for a strictly smaller
change: the `debugger` escalation duty above was recorded because it *widened when review blocks*. This
changes **what the reviewer's output is**, which is more than that.

**The counter cannot be derived by the persona it constrains**, and the first draft of this rule missed
it: `critical-reviewer` runs in a fresh context that never watched the work, so there is no count to
read, and reconstructing one from prior comments is precisely the diagnosis it is told to refuse. The
orchestrator supplies the number; when it is absent the reviewer says so rather than guessing. A rule
that would have produced a fabricated number, in the file that argues against overstating evidence, is
the defect the rule exists to prevent.

**Accepted cost:** a slice occasionally parks with a real defect unfixed. Strictly better than a queue
parking instead — which is what the session measured.

### What is NOT decided here

The **WIP bound moving from a count to file overlap** ships in the same batch but is not a roster change;
it belongs to the principles layer and to the `wip-guard` hook. It is noted because two personas —
`plan-reviewer` and `scrum-master` — act on it, and both were updated in the same batch. *(The `wip-guard`
hook shipped its overlap implementation immediately after, in `-skills`#88, closing the window in which it
was knowingly stricter than the rule.)* **A later collision this move produced, and its own correction, is
recorded in the twelfth amendment below rather than here — see that entry.**

## Amendment (2026-08-01, sixth) — a finding blocks only by naming a criterion; the DoD grows a tenth

**Problem, measured rather than felt.** Sixteen review passes across four slices in one day — six on a
README, four on a single catalog entry — while across the week the issue queue grew every day but one,
the day the owner cleared it himself. Owner: *"precisamos tornar o trabalho do revisor mais objetivo em
critérios claros… queria algo mais processual focado em DoDs."*

**The diagnosis is not that the reviewer is too strict**, and getting that backwards would break the
thing worth keeping. Those passes found eight **claim-level** defects that lint, tests and a green Sonar
gate cannot catch, because none was a fault in the code — each was a true-sounding *claim about* the
code: a hook described as the opposite of what it does; `fails open` used against the sense stamped in
the same repo's own sources; live, production-exercised skills published as retired; a CI suite called
"blocking" in a repo with no required status checks. What was missing was a **stopping rule** and a
**severity contract**.

### Decision

1. A finding may produce `REQUEST-CHANGES` only by naming the DoD criterion it fails **and its
   falsifier** — the command, line or file that would show the reviewer wrong. A finding naming no
   criterion is advisory: reported, never a gate.
2. **Criterion 10** joins §6.1 — the content lens returned a verdict and its BLOCKING findings are
   resolved, **and** a claim the reviewer can itself falsify against a checkable source fails the
   criterion *whatever the lens returned*. An `ESCALATE` verdict makes the slice boundary class.
3. `brand-guardian` and `editor` classify each finding BLOCKING or ADVISORY themselves, on
   **truth-versus-quality** rather than size. Severity is the lens's call because the lens is the only
   party with the context; the invoking context, which had been making it, has none.
4. Criteria 6 and 9 state what evidence satisfies them and what their `n/a` looks like.
5. The round budget drops from four (amendment #5) to **two**; from round three the verdict states what
   shipping as-is would cost.

**This supersedes exactly one clause** of the 2026-07-23 amendment — *"a positioning breach is not a DoD
criterion"* — and nothing else in it. That amendment's mandate, capability guarantee and trigger stand.

> **Appended 2026-08-04 — item 2's first half is superseded, and amendment #9 predicted this exact
> paragraph.** Criterion 10 no longer passes on *"the content lens returned a verdict"*. The owner
> decided that a gate **must** relay the copy verdict, so the criterion now reads **returned AND its
> text is on the PR** — a return into the orchestrator's context, where it dies, satisfies nothing.
> The decision, its scope, its accepted cost and the measurement behind it are in
> [ADR-0006](./0006-a-verdict-owed-to-another-persona-is-an-artifact.md)'s third 2026-08-04 amendment;
> the criterion's operative text is in `agents/quality-assurance.md`, which is where it lives and which
> is the only place to read it. **Item 2's second half is untouched** — a claim the reviewer can itself
> falsify still fails the criterion whatever the lens returned, and it is the residual that carries the
> most weight when a relay is thin.
>
> **Why this note exists at all is amendment #9's finding, instantiated one amendment later.** That
> amendment established that this ADR's rendering of criterion 10 is a **summary**, not the text, and
> that reading the summary as the text is a defect this library treats seriously. A summary that is not
> marked stale when the text moves is the same defect with a delay, so it is marked here rather than
> corrected in place — supersede, never rewrite.

### Two costs, named

**The severity contract handles a lens that omits severities and not one that gets a severity wrong.**
Nothing catches an under-classification, and the reviewer is told to ask rather than re-grade, which
makes it the wrong party to catch it. Accepted deliberately: a reviewer that freely re-grades lens
findings recreates the problem this contract ends. Bounded by criterion 10's second half, which is
independent of any severity — a lens that under-classifies a **false claim** does not save it.

**The first draft of criterion 10 made the reviewer's most valuable behaviour unblockable.** It was
satisfied by a lens *returning a verdict* rather than by the copy being true, so a claim-level defect the
reviewer itself found mapped to no criterion and became advisory by construction — the exact class this
amendment opens by celebrating, and the class this ADR's own 2026-07-23 amendment records as *"found by
`critical-reviewer` being thorough rather than by anything being responsible for them."* Caught in review
of the change, by the reviewer reading its own diff. Recorded because the same shape will be tempting
the next time this stopping rule is tightened.

### What this does not fix

*"Review does not open work"* already existed in criterion 1, verbatim, and was violated the same day
this was written — two issues filed from review findings, closed hours later under the pre-existing
rule. A rule not honoured is not a rule missing, and more persona text would not have changed it.

## Amendment (2026-08-02, seventh) — the roster matched an org chart, not the failures

**Problem, measured.** Nineteen personas, 1,638 lines of definition. In an intensive session the loop
dispatched **three**. Owner: *"com certeza erramos em perfis"* — and the data agrees, but not in the
way "some are unused" suggests.

**The eight defects that actually cost time were one thing: verification that verifies nothing.** A
hook described as the opposite of what it does. `fails open` used against the sense stamped in its own
source. Three live skills published as retired. A published test whose stated rule returns the wrong
answer for the skills most likely to be asked about. A CI suite called "blocking" in a repo with no
required status checks. A substring assertion that stopped discriminating when its subject grew. A
`grep` blind to a term's role-noun inflection. A focus-trap test that could not fail.

None of those is *frontend*, *product*, *scrum* or *security*. The roster enumerated **roles**; the
loop meets **one failure mode**.

### The criterion, which is the owner's and replaces "one persona per concern"

> **A persona exists only where conflict is wanted** — where someone should be arguing against someone
> else. Anything generating no disagreement is a **competence**, and belongs to whoever already holds
> the context.

This is the whole amendment. Everything below follows from applying it.

The old criterion was *one persona per concern*, and its cost is now measurable: splitting a concern out
of the main context creates a **handoff decision**, and the handoff is what did not happen. The build
specialists were never dispatched — not because no build work arrived, but because the invoking context
already held the background and explaining it three times cost more than doing the work. **A persona
that is never dispatched is a document.**

### Decision — nineteen personas to six

**Three leads that disagree, then consolidate ONE demand.** `product-lead` (reader, value, order, slice
size — absorbing `product-manager`, `product-owner`, `scrum-master`), `tech-lead` (architecture,
measurement, sequencing, leads the builder — absorbing `analytics` and `adr-author`), `marketing-lead`
(positioning, voice, the owner's career and market — absorbing `brand-guardian`, `editor`, `recruiter`).
They are separate **because reader, system and market are genuinely different optimisations**; where
they agree the owner learns little. Three briefs downstream is how one slice becomes three rounds, so
they reconcile first and send disagreements *up* as decisions rather than *down* as instructions.

**One builder.** `developer` — app, infrastructure, pipeline, tests inline — absorbing
`frontend-react`, `iac-terraform-aws`, `devops-cicd`, `qa-e2e`, `sonar-remediator` and `performance`.

**Two gatekeepers.** `quality-assurance` (renamed from `critical-reviewer`, which named an activity
rather than a role; absorbing `debugger`) and `security`. Both exist to fight the builder — one on
delivery, one on the floor.

**`planner` and `plan-reviewer` retired outright.** Not idle — **structurally unnecessary here**. The
owner writes the specs, in the Issues, in more detail than a planner would produce. Intake happens
upstream of the loop, done by the person closest to it.

#### Why `brand-guardian` + `editor` merged — corrected from this amendment's first draft

The first draft argued that **both lenses spent their best findings outside their nominal lanes**. That
claim was checked and is **false**: of the four findings cited, three were inside the lane the persona
was defined for. It is struck rather than deleted, because the correction is the point — an amendment
about verification that verifies nothing should not itself ship an unverified rationale.

**The sound evidence is the overlap, and it is in the files themselves.** `editor.md`'s own severity
contract claimed, as its worked examples, **the same two findings** `brand-guardian.md` claimed as its
own. Two personas independently documenting the same findings as characteristic of their mandate is not
an anecdote about one session — it is the seam failing in the definitions, before any dispatch. The
claim/craft split did not describe two populations of defect.

The capability guarantee survives untouched: all three predecessors carried exactly `Read, Grep, Glob` —
no `Bash`, no `Edit`, no `Write` — which is why they could be merged at all. The one persona that reads
the private positioning source still cannot publish anything (ADR-0004).

#### Why `debugger` merged into the gate, and `adr-author` into `tech-lead`

Neither generated conflict, so under the criterion both are competences. Where each landed is the
substantive part:

- **`debugger` → `quality-assurance`.** The fresh-context argument that separates the gate from the
  builder does **not** separate a debugger from the gate: authorship bias corrupts **judgement**, not
  **investigation**. Whoever wrote the bug has no incentive to miss it, only to excuse it. And it fixes
  the failure the owner named — *a review that returns findings without causes creates work; one that
  returns causes grinds it down.*
- **`adr-author` → `tech-lead`.** Whoever holds the decision writes its record. The handoff sat exactly
  where `/workflow/adr`'s own rule says it must not — *committed in the same MR as the change it
  justifies* — so the record routinely lagged. `tech-lead`'s write grant is scoped to `docs/adr/**`;
  it remains advisory on code.

### The rule this leaves behind

**A persona earns its place by generating a disagreement someone needs to hear**, not by completing an
org chart. This supersedes the version this amendment first shipped (*"by catching a class of defect
that actually occurs"*), which was true and insufficient: it justified keeping any lens that ever found
something, which is every lens.

### Two standing rules the owner set above every persona's checklist

1. **The loop is a machine for grinding work down, not for generating it.** Observed: twenty-two
   findings on a documentation PR — one slice converted into fifteen while looking productive.
   Mechanically: blocking findings get the full treatment, advisory findings one line each, and **no
   persona opens work**.
2. **Nothing ships half-done.** Close what can be closed, and say plainly what could not.

### Costs, named

- **An absorbed persona is a longer checklist.** An item competes for attention with every other item —
  which is precisely the argument the nineteen-persona roster was built on, and it is not answered by
  this amendment, only outweighed. The counter-evidence is that the specialisation was not what made the
  lenses useful; the fresh context was.
- **One builder means directory isolation is discipline, not capability.** Three specialists could not
  accidentally edit each other's glob. Compensated by the gate's scope criterion, which is weaker.
- **The significance test now runs once, after the code exists**, since `plan-reviewer` is retired.
  Recorded in `/workflow/adr` where the test itself lives.
- **The reference sweep is the failure surface**, exactly as amendment #3 recorded for its own reshape:
  a missed pointer leaves a trigger aimed at a persona that no longer exists, and unlike a test it fails
  **silently**. Swept across `agents/`, `commands/`, `hooks/`, both `CLAUDE.md`s, `README.md` and
  `plugin.json`; `docs/adr/**` deliberately **not** swept, because it is the historical record and the
  rule is supersede-never-rewrite.

### What this does NOT change

The gate's merge authority, criterion 10, the falsifier rule, the round budget, the content trigger's
fail-closed phrasing, and every hook. The hooks are the part of this design that has worked without
amendment since it shipped.

### Where the design now lives, harness-agnostically

`docs/dev-loop-design.md` describes the whole loop independently of Claude Code, for import into another
harness. It is a **derived** document: this ADR library remains authoritative, and where the two
disagree the ADR wins.

**Superseded 2026-08-14, per [ADR-0019](./0019-readme-is-the-single-source-of-truth-for-the-dev-loop.md).**
`README.md` is now that home; `docs/dev-loop-design.md` is retired to a pointer stub rather than kept as
a second document claiming the same authority. This ADR library is still what governs where the two, and
where this note and ADR-0019 disagree, ADR-0019 — the later record — wins on this specific question.

## Amendment (2026-08-02, eighth) — the gate can only be as objective as the issue is complete

**Problem.** Amendment #7 gave the roster a criterion and left the loop's *intake* untouched. Two
failures followed from that gap, and they are the same failure seen from two ends.

At the gate: the owner's standing demand is *"o reviewer não deve ser subjetivo, tem que ser objetivo —
senão nada fecha."* But the DoD alone cannot deliver that. It says a slice must be in scope, tested and
traceable; it does not say **what this particular slice was supposed to do**. With no external ruler the
gate falls back on impression, and impression has no stopping rule. Observed: **twenty-two findings on a
documentation PR** — every item real, one slice converted into fifteen.

At intake: `/principles/dev-loop` said a tracked issue was **optional**, *"created only when it helps
decompose the work"*. So the artifact the gate would have measured against was, by the loop's own rule,
allowed not to exist.

### Decision — the intake chain, and what each link buys

> **The owner generates demand. The three leads close the issue's description among themselves. Only
> then is it executable.** Nothing is worked that is not recorded in the issue tracker — no size
> threshold, no exceptions. An issue *in* the tracker is not the same as an issue *ready for work*.

This **supersedes** the optional-issue rule above. The leads do not *file* — only the owner opens work,
which *Review does not open work* already enforced through `permission-guard` rule 5c and which is
untouched. They write what goes in it.

**The load-bearing relationship, stated once so it is not implemented by halves:** the requirements the
leads state are the ruler `quality-assurance` applies. Its ruler therefore sits **outside** it, and a
finding either anchors in a stated requirement (or a DoD criterion) or it does not block. *That* is the
answer to the owner's demand — taste has no route to a blocker, not because the reviewer restrains
itself but because there is nothing to anchor it to.

**The work did not disappear; it moved upstream, where it is cheaper.** A missed requirement costs a
text edit at intake and a full review round at the gate.

### Decision — both gatekeepers approve every MR, in parallel

`security` used to fire only on diffs in its concern, which meant *whether the security gate was needed*
was judged by someone who is not the security gate. It now reviews **every** MR, dispatched in parallel
with `quality-assurance`, and the MR needs both approvals.

**The anchors differ, and the asymmetry is the reason there are two gatekeepers rather than one
checklist:**

| gate | question | kind |
|---|---|---|
| `quality-assurance` | was **every requirement of the issue** met? | **objective** — external ruler |
| `security` | can this cause a problem **in production**? | **judgement** — with a veto |

The second is not enumerable in advance. If it were, it would be a requirement and the first gate would
already cover it. A loop that insists both be objective either invents a checklist that misses the novel
case, or quietly drops the axis.

### Decision — the builder delivers the E2E suite

`qa-e2e` was absorbed into `developer` by amendment #7, and **absorbing a persona without absorbing its
output is how a capability gets quietly dropped**. Stated explicitly: a slice is app + infrastructure +
pipeline + the automated E2E journeys. Per repo and never invented — **E2E always, an API suite only
where an API exists**; API testing becomes the builder's too if a backend appears.

### Costs, named

- **The objectivity is transferred, not created.** It holds exactly as far as the description is
  complete, and **nothing mechanically verifies that a description was closed by three leads** rather
  than nodded through by one. The failure is quiet: the gate looks objective while measuring against a
  ruler nobody wrote.
- **"Every MR" lands hardest on diffs with no security surface**, where the honest answer is `n/a` — and
  a gate answering `n/a → pass` every time gates nothing. Mitigated by a phrasing rule rather than by
  process: **`n/a` is only valid naming the axes looked at and found untouched.** Nothing catches a
  verdict that names axes it did not really examine. Accepted, and written down rather than discovered.
- **Two dispatches per MR instead of one**, including on trivial ones. Bounded by running them in
  parallel; measured on the first MR under this rule, the two returned in about the time one round used
  to take, and `security` — which the old rule would not have dispatched at all on a comment-only diff —
  produced the finding neither the builder nor the delivery gate had.
- **Intake gets slower before the build starts.** That is the point, and it is still a cost.

### What this does NOT change

The roster, the merge authority, the falsifier rule, criterion 10, the severity contract, the round
budget, `Review does not open work`, and every hook.

## Amendment (2026-08-04, ninth) — `marketing-lead` merges into `product-lead`; the roster is five

**Decision, and it is the owner's.** Dated 2026-08-04. `marketing-lead` is merged into `product-lead`.
The roster goes from six personas to five.

His reasoning, in his words: *"o produto é o site e a minha presença profissional"* — the product and
the professional presence are **one object**, so one lead owns both. And a second reason, about the
loop rather than the product: fewer lead profiles means fewer outputs that have to be reconciled at
review time. Amendment #8 made the three leads close an Issue's description *among themselves*; every
lead added to that reconciliation is a round before any code exists.

This is amendment #7's operation applied one level further — that amendment merged `brand-guardian` +
`editor` into `marketing-lead`; this one merges the result into `product-lead`. It is therefore an
amendment on the same criterion, not a new record.

### The clause that is the load-bearing part of this amendment

The two personas were **not symmetric in authority**, and a naive merge would have silently demoted the
stronger one.

| persona | authority as it stood |
| --- | --- |
| `marketing-lead` | splits **truth** (BLOCKING) from **craft** (ADVISORY). A false published claim is a gate. Granted by amendment #6 item 3 — which names `brand-guardian` and `editor`, not `marketing-lead`; it reached this persona through amendment #7's merge of those two. Cite the pair, not one hop. |
| `product-lead` | purely advisory — *"it proposes, the owner decides; it writes nothing and never merges."* |

Merging into the advisory persona and saying nothing further would convert *"a published claim that is
false blocks the merge"* into *"a published claim that is false is worth mentioning."* That is not a
simplification of the roster, it is a repeal of a gate, and it would have happened as a side effect of
a decision that was not about gates at all.

**The owner chose: merge, and carry the blocking clause across explicitly.** Operative form, written
so a reviewer can apply it without knowing which persona produced the finding:

> **A finding is BLOCKING when it asserts that something published is false** — a claim the author has
> not earned, a quantification with no source, a statement contradicted by the code, the file it links
> to, or another surface. It blocks by naming the falsifier (amendment #6's rule is unchanged: a
> command, line or file that would show the finding wrong).
>
> **Every other finding this lens produces is ADVISORY** — voice, framing, structure, ordering,
> word choice, market efficacy, positioning preference. Reported, never a gate.
>
> **Which persona produced the finding does not enter this test.** The severity follows from what the
> finding asserts, not from who holds the mandate.

The last line is the one that had to be written down. Under six personas, severity correlated with
provenance closely enough that nobody had to state the rule — the copy lens blocked, the product lens
advised. Under five, provenance carries no information and the test has to stand on its own.

#### The role-not-name practice — corrected from this amendment's first draft

The first draft asserted that `quality-assurance`'s **criterion 10** *"is phrased against the content
lens rather than against a persona name, so it survives this merge without edit."* That claim is
**false, and refuted by this amendment's own diff.** Criterion 10's second half reads *"even if
`product-lead` approved"* — a persona name — and this slice edited it from `marketing-lead`. The
illustration was drawn from the criterion's **design intent** rather than from its **text**, which is
the one substitution this library treats as a defect rather than a slip.

**The mechanism, because it will recur otherwise.** Amendment #6 item 3 introduces criterion 10 with
the words *"the content lens returned a verdict"* — that is this ADR's **summary** of the criterion.
The criterion itself lives in `agents/quality-assurance.md`, and the two are not the same string. The
first draft quoted the summary and reported it as the text. **An ADR is not a source for what an agent
file says; it is a source for what was decided.** Reading the second where it lives is one `grep`;
the draft did not run it.

Struck rather than deleted: an amendment arguing that names age badly, and citing as its proof a
sentence it was at that moment renaming, is worth keeping visible.

**The practice it illustrated is sound and is not retracted:** *a criterion that names a role outlives
a roster; one that names a persona is a reference sweep waiting to happen.* What was wrong is the
example, not the rule.

**The repo does implement it — nine times, and the check is one command.** DoD criteria **1–9**
(`agents/quality-assurance.md`) name no persona; `git diff 720e0ec..HEAD -- agents/quality-assurance.md`
touches no hunk in that range, so all nine crossed a roster change untouched. Criterion 10 is the
**single counter-example** in the file, and this slice paid exactly the cost the practice predicts.

**The refinement the finding forces, because not every mention is avoidable.** Two kinds of sentence
were being treated as one:

| kind | may it name a persona | why |
| --- | --- | --- |
| an **acceptance condition** — what must be true for the criterion to pass | **no**, and criterion 10 violates this avoidably | *"even if the lens approved"* says the same thing and does not age |
| a **dispatch instruction** — who the reviewer must invoke | **yes, unavoidably** | a dispatch target that names no persona is not dispatchable |

So the trigger's *"incomplete until `product-lead` has returned a copy verdict"* is a name the file
**cannot** shed, and it will be swept on every roster change by construction. That is a known,
bounded cost, not a defect. Criterion 10's is neither, and making its text consistent is
`developer`'s to carry in this slice — this record states only what is true of it today.

### Evidence — why the clause was non-negotiable rather than cautious

On 2026-08-03 the copy lens blocked four merge requests. **None of the four findings was a product
judgement, and none was a matter of taste.** Each was a false statement about a checkable thing:

- **#344** — the page asserted that *no mechanism enforces the reviewer's dispatch*.
  `permission-guard.sh` rule 7b (`hooks/scripts/permission-guard.sh:327`) is a `PreToolUse` deny that
  refuses `gh pr merge` from every `agent_type` except `quality-assurance`. The claim was **false**, and
  it was in the **specification written by the main agent** — so the party best placed to notice was
  the party that wrote it.
- **#347** — a diff with **zero copy in it**: two code comments describing behaviour the code does not
  have (an accent treatment the nav never used; *"five links"* where `NAV` has six). The lens whose
  trigger is *"words a reader will see"* earned its keep on a diff containing none.
- **#348** — the PT string made a **different claim** than the EN: `com que` attached to the wrong
  noun, dropping the one thing the key existed to name. Two locales, one of them false.
- **#348** — `app.yml` still said *"the ONE job that reads another repository"* after the same sentence
  had been superseded **one file over in the same PR**.

Four blocks in one day, all of the same kind: *the text asserts something the repository refutes*. That
class is what the clause protects. Demote it to advice and all four ship.

### The counter-evidence, recorded because it is the strongest argument against this merge

On **#166** the two leads reached the **same conclusion** — *do not build what the issue describes* — by
**unrelated** reasoning. `product-lead` argued from inventory and the absence of any measurement path;
the copy lens argued that the selection rule itself was the defect. Same verdict, two routes, neither
derivable from the other.

That is precisely what the roster criterion says a second persona is *for*: not a second opinion, a
second **route**. Under one persona, #166 produces one of those arguments and the owner never learns
there were two — and it is not knowable in advance which one survives. Recorded here rather than
argued past, because a record that only makes the case for its own decision is the kind this library
keeps having to amend.

### Tested against the roster rule — and the answer is not one-sided

> **A persona exists only where conflict is wanted** (amendment #7).

**Was the conflict between product judgement and copy truth wanted?** Honestly: *sometimes*, and #166
is the instance. The two lenses do produce different arguments, and the owner does occasionally learn
something from the pair that neither would have supplied alone.

**Why the owner judged it is not enough.** The criterion is not *does conflict ever occur* — that
standard keeps every lens that ever disagreed, which amendment #7 already struck as *"true and
insufficient."* It is whether the conflict is **structural**: whether the two personas optimise for
genuinely different things such that their disagreement is *information*.

Here they do not. Amendment #7's own justification for merging `brand-guardian` + `editor` was that
**the seam had already failed in the definitions** — each file claimed the other's findings as
characteristic of its own mandate. **The same failure is present at this seam and it was checkable
before this slice removed one of the two files** — in the persona descriptions at `227c4a8`, the
commit this amendment was cut from (`git show 227c4a8:agents/marketing-lead.md`, and the same for
`product-lead.md`; the ref is pinned because this slice deletes the first file):

- `agents/marketing-lead.md` — *"Absorbs the former brand-guardian, editor and **recruiter** personas."*
- `agents/product-lead.md` — *"Absorbs the former product-manager, product-owner, analytics,
  scrum-master and **recruiter** personas."*

**Both claim `recruiter`.** Not a dispatch anecdote and not a judgement about one session — the
overlap was written into the definitions, on the trunk, before any invocation. Two personas
independently claiming the same absorbed mandate is definitional overlap at the seam being merged,
which is the class of evidence amendment #7 acted on — and it had recurred one level up without
anyone noticing.

**It is not the identical evidence, and the difference is worth one sentence.** Amendment #7's
overlap was **behavioural**: `editor.md` and `brand-guardian.md` claimed the same *findings* as
characteristic of their mandates, which is direct evidence the two lenses produce one output. This
one is **provenance**: two files claiming the same *inherited* mandate, which is evidence that
whoever wrote the descriptions could not hold the two apart. Weaker as a prediction about outputs,
stronger as a fact about the record — it is on the trunk and dated, where a session's dispatches are
neither.

#### The same quoted line double-claims `analytics` — and it is a DIFFERENT failure

Added 2026-08-04, after `developer` read the quote above more carefully than the draft that cited it.
The `product-lead` string quoted at `227c4a8` names **two** retired personas it did not hold. The
second is `analytics`, and every other record assigns it to `tech-lead`: this ADR's own roster
decision (§526, *"`tech-lead` … absorbing `analytics` and `adr-author`"*), `CLAUDE.md`
(*"`analytics` → `tech-lead`"*), `docs/dev-loop-design.md` (the measurement plan listed under
`tech-lead`), and the retired file itself — `git show 0563d47^:agents/analytics.md` describes
*"audits that the instrumentation exists and matches the plan"*, which is `agents/tech-lead.md`'s
duty 3 almost verbatim. `marketing-lead`'s description did **not** claim `analytics`.

**The tempting reading is that this makes the merge's case twice as strong. It does not, and taking
it that way would invert the amendment's conclusion.** The two instances differ in the one property
that makes overlap seam evidence at all — *who else claims it*:

| instance | shape | what it is evidence of |
| --- | --- | --- |
| `recruiter` | **both** merging personas claim it | the `product-lead` ↔ `marketing-lead` seam failing in the definitions. Merging the two **removes** it. |
| `analytics` | **one** persona claims what the roster assigns to a **third** | descriptions drifting from the record. Merging these two does **nothing** to it. |

`analytics` is an over-claim against `product-lead` ↔ **`tech-lead`** — the seam this amendment
explicitly declines to merge, two sections below, on the grounds that those two optimise for
genuinely different things. Read as seam evidence it would argue for merging `product-lead` into
`tech-lead`, which is the opposite of what this record decides. So it is filed as a **third failure
mode**, not as more of the second:

> **Unreconciled absorption drift.** A persona's description accumulates claims that no one checks
> against the roster table. It needs no seam and no second persona; it is a record-consistency defect,
> and its remedy is a reconciliation pass, not a merge.

**It is the more general of the three, which is why it is worth the space.** It had a second symptom
in the same string, at behaviour level rather than name level: `product-lead` also claimed *"how we
would know it worked"* — `agents/tech-lead.md`'s duty-3 heading, word for word. So the drift had
reached both the inherited name and the mandate behind it, and neither was caught by anything. That
this ADR's own evidence passage quoted the line and saw only the instance it was looking for is the
same defect one level up, and is why it is recorded here rather than fixed silently.

**Fixed in this slice, and the fix is `developer`'s ruling, not this record's:** `tech-lead` keeps
measurement, `agents/product-lead.md:3` drops both over-claims and now points at the holder
(*"MEASUREMENT is tech-lead's, which absorbed `analytics`"*), and `agents/tech-lead.md` needed no edit
because the ruling made its existing text correct. **The quote at `227c4a8` stands unchanged** — it is
pinned to a commit, it is history, and it is what the evidence rests on.

Against that, #166's two-routes argument is real but **weaker than it looks**: the routes were
different, the conclusion was not. What the owner would have lost is a second *justification* for a
decision he was going to make either way. That is worth something and it is not worth a persona.

**So: the conflict was wanted, was found not to be structural, and is booked as a real loss below
rather than argued away.**

### Costs, named

**1 · The capability floor is gone, and this is the largest cost of the merge.**

`marketing-lead` declares `tools: Read, Grep, Glob` — **no `Bash`**, deliberately, because the voice is
the owner's and the persona never edits. That grant is not decoration. It is the through-line of this
ADR from its very first amendment: *"the boundary should be a capability, not a promise"* (ADR-0004),
restated when the mandate moved to `brand-guardian` (*"this guarantee must not be weakened in the
move"*), and restated again when amendment #7 merged three lenses (*"all three predecessors carried
exactly `Read, Grep, Glob` … which is why they could be merged at all"*).

`product-lead` declares `tools: Read, Grep, Glob, Bash`. **The merged persona inherits `Bash`.**

So the one persona that reads the private positioning source, and whose findings land in **public**
PRs, is now capable of publishing. Nothing about the identifier-only output rule changes; what changes
is that the rule is now **an instruction rather than a capability**. In a consuming repo that
allowlists `gh pr comment` or `gh pr merge`, that capability is live through the inherited permission
surface.

This is **not neutral and is not presented as such.** Amendment #2 already booked exactly this
downgrade for the three personas it materialised — *"`Bash` contradicts the 'advisory' framing at the
capability level … it is the weaker guarantee, and this ADR argues the opposite two sections above."*
That entry now applies to the copy mandate too, which is the one place this record had held the line
for four consecutive amendments.

**Accepted, not solved.** The alternative — merging into the *tool-poorer* persona, i.e. stripping
`Bash` from `product-lead` — was available and is rejected on function: `product-lead` needs `Bash` for
`gh issue list` to read the queue it sequences, which is the mandate amendment #5 gave it a trigger
for. Removing it would silently retire that trigger to fix a guarantee that was already behavioural
for the product half. **The residual is real and this is the record of choosing it.** Re-tightening it
is an ADR-0004 tool-grant decision and remains the owner's.

> **Appended 2026-08-04 — the cost is closed, and by a cheaper instrument than the one named above.**
> The paragraph above pre-commits the remedy to a **tool grant**: either strip `Bash` (rejected on
> function) or leave the guarantee behavioural (chosen). **Both branches of that choice were about the
> `tools:` frontmatter, and the frontmatter was never the only surface.** The owner's decision, taken
> today: `permission-guard` gains **rule 5e**, an `agent_type`-keyed **deny on `gh pr comment`,
> `gh issue comment` and `gh issue create`** for `*:product-lead`. The persona keeps `Bash` — so
> `gh pr list` / `gh issue list` / `gh pr view` and the amendment #5 trigger they feed are untouched —
> and loses the ability to publish. **The two things this amendment treated as one dial turn out to be
> two**, and separating them costs nothing the record wanted to keep.
>
> **The remedy this amendment named is therefore superseded by rule 5e, not satisfied by it.**
> *"Splitting the tool grant"* — un-merging the persona the owner had just merged, at the cost of the
> second agent output the merge existed to remove — was the only alternative this record could see. It
> is not the one that ran, and it is now **struck as the standing remedy**. The paragraph above stands
> as written because its **rejection of stripping `Bash` is still correct** — that would still retire
> the queue trigger. What is falsified is its implied premise that the alternatives were exhausted, and
> what is superseded is the remedy it left on the table for a future reader to execute.
>
> **How it was found, because that is the transferable part.** `security` proposed it, and the route
> was not analysis of the persona — it was noticing that **`permission-guard` already keyed two denials
> on `agent_type`** (rule 5d, the subagent filing deny; rule 7b, the merge gate). A mechanism that
> already exists twice in a file is cheap to extend a third time, and expensive only to invent. The
> generalisable rule: **before pricing a remedy, read what the enforcement surface already does** — this
> amendment priced a capability change without checking whether a routing surface could carry it.
>
> **Pre-emptive rather than post-leak, on `security`'s argument and it is the load-bearing one.** The
> usual case for waiting — catch it at the gate, revert if it happens — does not apply, because the
> harm is not reverted by reverting the artifact: *a paraphrase of the positioning layer in a public
> comment is not undone by deleting the comment.* The seam this deny protects is the one place in the
> loop where the reversibility argument that governs everything else (ADR-0004: *mechanism where the act
> is irreversible*) points **toward** mechanism rather than away from it.
>
> **What is NOT claimed, in the terms ADR-0006 forced on this repo's records.** This is **routing at
> best, and here not even that** — it is a capability narrowing on one `agent_type`, and the main loop
> can still obtain the positioning content by reading `.brand/` itself and posting under no
> `agent_type` at all. It closes the **persona-shaped leak**, which is the one this amendment created.
> It does not make the private layer unpublishable, and nothing in this repo does.

**1b · A consequence outside both repos, recorded because nothing mechanical will catch it.**

The public `/architecture` page on `tadeumendonca-io` describes `product-lead` as the persona with **no
hook keyed to it**. `security` flagged the coupling before that page shipped. The obligation this
creates on the io side — what is actually falsified, what merely misleads, and why the existing
inventory check does not fire — is written up in
[ADR-0004](./0004-autonomy-and-permission-model.md)'s 2026-08-04 amendment, with the mechanism that
causes it. **It is not fixed by this slice**: the page is a different repository, and this record is
where the debt is booked, not paid.

**2 · One persona now produces both severities, so the split moved from structure to format.**

Two personas made the blocking/advisory split **structural**: a finding's provenance was most of its
severity, and a reader could tell the halves apart by which verdict they arrived in. One persona makes
it a **discipline of the report**.

The report must therefore do what the roster no longer does for it:

> The verdict **separates BLOCKING from ADVISORY into distinct, labelled sections**, and never
> interleaves them. Each BLOCKING item names its falsifier. If there are no blocking findings, the
> report **says so explicitly** rather than leaving the section absent — an omitted section and an
> empty one must not read alike.

The known gap, stated so it is not rediscovered: amendment #6 already recorded that the severity
contract *"handles a lens that omits severities and not one that gets a severity wrong"*, and that
nothing catches an under-classification. **That gap widens here.** Under two personas an
under-classified truth finding still arrived from the lens whose whole mandate was truth, which was
itself a signal. Under one, a truth finding filed in the advisory section is indistinguishable from a
craft finding. The residual backstop is criterion 10's second half — a claim the reviewer can itself
falsify fails the criterion *whatever the lens returned* — which is independent of severity and is
now carrying more weight than it was designed for.

**3 · One fewer route to a conclusion**, per #166 above. Not restated.

### What is NOT merged

**`tech-lead` stays separate, and the designed conflict is `product-lead` ↔ `tech-lead`.** That seam is
the one amendment #7 called genuinely different optimisations, and this amendment does not touch it:
`product-lead` argues from what the reader and the market need, `tech-lead` from what the system can
carry and what each choice costs later. Those are different rulers with different sources of truth, and
neither can be derived from the other — which is the test this amendment just applied to the copy seam
and found the copy seam failing.

**Stated because the evidence above touches this seam and must not be read as arguing against it:**
`product-lead`'s description had over-claimed `analytics` and the measurement duty, both `tech-lead`'s.
That is absorption drift in a **string**, not the two rulers collapsing — the mandates were never in
dispute, every other record assigned them correctly, and the fix was to correct the description. This
seam is kept, and it is kept having just been looked at rather than assumed.

~~**The two gatekeepers are untouched.** `quality-assurance` and `security` both still review every MR in
parallel, and both approvals are still required (amendment #8).~~

> **Struck 2026-08-04 by amendment #10.** `security` is absorbed into `quality-assurance`; there is
> **one** gatekeeper, holding two lenses in one pass, and **one** approval. The sentence is struck rather
> than edited because *"both approvals are still required"* was, from the moment the persona was removed,
> a record describing a control as **stronger than it is** — and that is the direction that fails open. It
> was true when written and it is the reason amendment #10 blocked a merge instead of being filed as
> tidy-up. The claim it makes about **amendment #8's parallel dispatch** is what changed; the axis that
> dispatch existed to guarantee did not.

**Unchanged in full:** the merge authority, the falsifier rule, DoD criteria **1–9**, the round budget,
*Review does not open work*, and every hook. (`agents/tech-lead.md` is edited, but only where it
**counted** the leads — *three* → *two*; the seam's description is verbatim.)

**Changed in text, unchanged in substance — stated separately, because the first draft of this
amendment listed both in the line above and was wrong twice:**

- **Criterion 10** — its *obligation* is unchanged; its *text* was edited here, in two places: the
  persona named in its second half (`marketing-lead` → `product-lead`), and the new sentence requiring
  the two severities to arrive as separately labelled classes. See the correction above.
- **The content trigger's fail-closed phrasing** — amendment #4's rule is that the trigger tests *what
  a diff changes*, never *who reviews it*, and **that half is verbatim**: *"If a diff changes words or
  images any reader will see — human or machine."* But the sentence does not end there. Its
  consequence clause — *"your review is incomplete until `product-lead` has returned a copy verdict"* —
  names a persona and was edited in this slice. So the trigger survives a roster change **in its
  condition, not in its consequence**; *"by construction"* was true of the part amendment #4 was
  arguing about and false of the sentence as a whole.

Both errors have the same cause and it is worth naming once: the record was describing **what these
rules are for** and reporting it as **what they say**. Where an amendment claims a text is untouched,
the claim is about bytes, and `git diff` settles it.

### One consequence outside this record

ADR-0006's closing **open question** — *"`marketing-lead` has the identical hole … that persona is
granted `Read, Grep, Glob` and **no `Bash`** … covering it means trading a deliberate tool grant
against verifiability"* — is **falsified by this amendment**, because the trade it describes as
unmade has now been made. Amended there, in that record, rather than settled here.

~~Roster: **6 → 5** — `product-lead`, `tech-lead`, `developer`, `quality-assurance`, `security`.~~
**Struck 2026-08-04 by amendment #10** — the count is still five and the membership is not. `security`
is absorbed and `harness-lead` joins. The line stands struck rather than corrected because the
substitution it describes is exactly the one every mechanical check in this repo held green.

## Amendment (2026-08-04, tenth) — `harness-lead` joins tier 1; `security` is absorbed into `quality-assurance`

**Two decisions, both the owner's, both taken 2026-08-04**, recorded in one amendment because they are
one roster move under one criterion — the same shape amendment #7 used, and the same decider in the same
session. Where they differ they are kept apart below.

**Why this record was late, and it is the finding that opened it.** `quality-assurance` blocked
`-skills`#146 on this gap: the roster shipped and no decision record moved with it. The previous roster
change (`6696148`) amended **four** records — this ADR, ADR-0006, the ADR index and
`docs/dev-loop-design.md` — **in the same commit as the persona files**. So the practice is not in
dispute and this is an **omission, not a policy**. The next reader should conclude that a sweep was
missed once, not that records are written afterwards here.

### Decision 1 — `harness-lead` exists, tier 1, advisory, ~~pre-implementation~~

**Struck 2026-08-12 by the eleventh amendment, below** — the owner reversed the pre-implementation-only
constraint; `harness-lead` now also implements the harness changes it stress-tests, under
[ADR-0015](./0015-harness-lead-implements-the-harness-it-reviews.md). The persona's existence, its
tier, and every other clause in this Decision stand unchanged.

The owner is the CEO of this initiative **and acts as its harness engineer**. `harness-lead` is
their pair in the second role and only there: it is dispatched on a proposal about the machinery —
hooks, settings and permissions, agent briefs, skills, commands, the plugin, MCP — and returns the
scenarios that proposal does not cover, **before anything is built**.

**It gates nothing.** It does not review merge requests, does not merge, does not open work. It sits in
**tier 1** because a harness proposal is closed the same way a story is: upstream of the build.

**Its standing rule is what makes it worth dispatching, and it is the whole of the decision:**

> **Every scenario ships with how to verify it, or is labelled a hypothesis — in those words.**

Without that rule this persona is a speculation engine: twenty plausible failure modes and no way to
sort them, which costs more attention than it saves. The failures that made the case for it were not
imaginative. Each was a mechanical fact somebody could have measured in seconds, and all four were found
**by accident, after implementation**, in one day:

- merging two personas left a third running an **installed brief that predated the merge**;
- a `deny` written for `Edit`/`Write` has **no hook layer at all** — `hooks.json` registers `PreToolUse`
  on the `Bash` matcher only;
- `Edit(.claude/**)` is a **project-relative glob**, so in a two-repo workspace it does not reach the
  other repo;
- a repo's `settings.json` is **not loaded** in a session rooted elsewhere, so twelve denies were inert
  the moment they were committed.

**ADR-0008's question is its standing mandate** — *which layer carries a control, and can that layer
hold it?* That record was written because nobody owned the question. Someone does now.

**The name is not decoration, and the suite is what decided it.** The first draft was `harness-lead`.
`inventory-counts.test.sh` derives the lead count from the filesystem (`agents/*-lead.md`) and went red,
because six sentences across `agents/` and `commands/` state that the intake is **two** leads and the
filesystem showed three. **Those six sentences were right** — this persona takes no part in closing a
user story's description. Renamed on the owner's call; the six pass untouched. Recorded because it is
the one instance in this batch where a derived count caught something a written one could not.

*Cost, named:* nothing enforces a dispatch. An undispatched lens is indistinguishable from a clean one,
and this persona — which runs before the build, where no gate exists — has no mechanical backstop at
all. It is worth exactly as much as the owner's habit of invoking it.

### Decision 2 — `security` is absorbed into `quality-assurance`

**The owner's decision, taken after the objection was raised and reaffirmed after it.** The stated
reason is the loop's, not the domain's: **fewer profiles reconciling one result on the same merge
request.** The gate now holds **two lenses in one pass** — delivery and production — and **labels every
finding with the lens it came from**. The asymmetry amendment #8 recorded did not merge away with the
persona: one gate applies two rulers, one objective (external ruler, the Issue's requirements) and one
judgement (*can this cause a problem in production*, not enumerable in advance). A finding whose ruler
is unstated is a finding the reader cannot check, which is why the labelling is a rule and not a habit.

**What it cost, recorded here because the record is where a cost survives.** These are not
reservations about the decision; they are the price of it, and each is written into
`agents/quality-assurance.md` as a **behaviour** rather than a summary, because a cost recorded only in
a README is a cost nobody performs.

1. **The two gates disagreed on severity and both were right.** On a `chmod` finding, one graded the
   **exposure** and called it advisory; the other graded the **record** and blocked. Different objects,
   both correct. One persona cannot produce that disagreement — it can only produce one severity — so
   what used to be information is now a judgement call by a single reader.
2. **They found by different instruments**, and neither would have found the other's. The single gate
   must now run **both**: measuring a mechanism by executing payloads against it, *and* re-deriving a
   stated claim against the artifact.
3. **Nobody now observes the gate that signs the merge.** This is the structural cost and it is the
   worst of the four. Until today `quality-assurance` **verified `security`'s comment before merging** —
   the only place in this loop where a verdict was mechanically checked by a party other than its
   author. That direction no longer has a subject. The remaining verdict is **self-enforced**.
4. **Which is why the merged persona did NOT inherit the `Edit` tool.** `security` could remediate
   inside its own concern — bump a dependency, tighten a permission — precisely **because it could not
   merge**. A gate that both edits and merges is a gate reviewing its own remediation. So the
   capability was dropped rather than absorbed: `quality-assurance` **prescribes** the fix and does not
   apply it, and its `Write` grant exists for one purpose, composing its verdict body in the scratchpad.

**The mechanical half was quieter than expected, and that is itself the finding.** **No rule in either
guard keyed on the retired name.** What named it was the test suite — in six cases, using `security` as
a stand-in for *"some non-`developer` subagent"*. Those cases **would have kept passing** with the
persona gone, which is an assertion that cannot distinguish the rule holding from its subject having
ceased to exist. They were **re-pointed, not deleted**.

### The criterion that changed, which is the part that generalises

Amendment #7 justified a persona by **conflict wanted**, and that single reason could not explain either
decision above: `harness-lead` argues with the owner rather than with another persona, and `security`
generated real disagreement and was merged anyway. The criterion is therefore widened, on the owner's
call:

> **A persona exists for one of four reasons:** disagreement is wanted · a fresh context is wanted ·
> **the context window is the constraint** · the capability should be smaller. A persona that satisfies
> none of the four is a handoff, and **a persona that is never invoked is a document.**

And the rule that decides where one may be **added**, which is the operative half:

> **Reconciliation cost is paid WITHIN a tier, not across tiers.** Two roles judging the same thing at
> the same moment produce two verdicts someone has to weigh; across tiers each hands the next a finished
> artifact rather than an opinion. So a **second** persona in one tier needs a reason the others do not.

Read together they settle both decisions without special pleading. Tier 3 held two and paid the
reconciliation cost every merge request — that is decision 2. Tier 1's second persona is justified
because product-versus-system disagreement *is* the point, and its **third**, `harness-lead`, pays
nothing because it never runs on the same work as the other two — that is decision 1.

**This supersedes amendment #7's single-reason criterion.** That reason survives as the first of four;
what is struck is the claim that it was the only one. Amendment #9's *"conflict between two objects"*
refinement also stands, as a test applied within reason one.

### The general rule this omission leaves behind, and it is worth more than the fix

`quality-assurance` traced the cause: **`inventory-counts.test.sh` asserts the roster as a COUNT, not as
a membership.** The value is derived honestly — `find agents -name '*.md' | wc -l` — and every stated
figure in the docs is checked against it, which is a real check. It simply cannot see this change:
`security` out and `harness-lead` in **holds the count at five**, so every gate stayed green through
exactly the change they exist to catch.

> **A count is not an identity.** An assertion that cannot tell a **substitution** from a **no-op** will
> pass through the change it exists to catch, and it will do so **silently** — which is worse than
> absent, because a green check is read as evidence.

This is the same defect class as the six re-pointed test cases above, twice in one batch: an assertion
whose subject can be replaced without the assertion noticing. `developer` is closing the membership half
in `hooks/`; this record carries the rule, because the next enumeration written here will be a count
unless somebody says otherwise.

### What is NOT decided here

- **The tier-1 and tier-2 personas are untouched** — `product-lead`, `tech-lead` and `developer` keep
  their mandates verbatim, including the `product-lead` ↔ `tech-lead` seam amendment #9 kept.
- **The merge authority is unchanged.** `quality-assurance` still holds the merge, still classifies
  safe versus boundary, still escalates the boundary class. `permission-guard` rule **7b** already
  denied `gh pr merge` to every `agent_type` other than `quality-assurance`, so the floor needed no edit.
- **The Definition of Done is unchanged**, criteria 1–10, including criterion 10's relay obligation
  decided in ADR-0006's third 2026-08-04 amendment. Criterion 9 is where the production lens now lands.
- **The intake chain is unchanged** (amendment #8), except that its *"both gatekeepers approve every MR,
  in parallel"* decision is superseded in the consequential half only — see below.

### What this amendment supersedes elsewhere, stated so no sweep has to infer it

- **Amendment #8's *"both gatekeepers approve every MR, in parallel"*** — the *decision* that the
  security axis fires on **every** MR regardless of what the diff touches **survives verbatim**; only
  its *carrier* changed from a second persona to a second lens. The `n/a` phrasing rule survives with
  it, and now applies to a lens rather than to a gate.
- **Amendment #9's *"The two gatekeepers are untouched … both approvals are still required"*** — struck
  in place, above. It is the sentence this amendment was opened on, and the reason it blocked rather
  than being tidy-up: **it describes a control as stronger than it is**, which is the direction that
  fails open.
- **ADR-0006** — its verification direction has lost its subject. Amended there.
- **ADR-0007** — its precondition counts two markers. Amended there. It is status `proposed` and
  unimplemented (`grep gatekeeper-verdict hooks/` returns nothing), so **nothing breaks today**; what
  would have broken is the slice that implemented it against this record.
  > **The parenthetical expired 2026-08-05.** That `grep` now hits `session-wip.sh` and its suite — a
  > SessionStart *reader* that annotates a PR with no verdict on its current head, deciding nothing.
  > ADR-0007's deny hook is still unimplemented; only the command that proved it is gone. Superseded
  > in place at [ADR-0007](./0007-the-merge-precondition-is-a-floor-not-an-instruction.md), with the
  > reason the proxy broke: a grep for a *string* stood in for the existence of a *control*.

Roster: **five** — `product-lead`, `tech-lead`, `harness-lead` (tier 1) · `developer` (tier 2) ·
`quality-assurance` (tier 3). The count is unchanged from amendment #9 **and two of the five members
are different**, which is the whole point of writing the names.

## Amendment (2026-08-12, eleventh) — Decision 1's *"advisory, pre-implementation"* framing is struck; `harness-lead` gains an implementer role

**Struck, not rewritten:** Decision 1's header above reads *"`harness-lead` exists, tier 1, advisory,
pre-implementation"* and its body states *"It gates nothing. It does not review merge requests, does not
merge, does not open work."* The **merge** and **MR-review** clauses stand verbatim — unchanged by this
amendment, and re-verified as still true (`hooks/scripts/permission-guard.sh:136`'s catch-all still
denies `gh pr merge` to this persona). The **pre-implementation** clause is struck: the owner reversed it
on 2026-08-12, and `harness-lead` now also builds the harness changes it stress-tests, under
[ADR-0015](./0015-harness-lead-implements-the-harness-it-reviews.md).

**Why struck rather than silently widened:** amendment #10's own framing — *"a persona exists only where
conflict is wanted"* widened, that same day, to *"a persona exists for one of four reasons"* — was struck
in place rather than edited, on the stated rule that *"a record describing a control as stronger than it
is [...] is the direction that fails open."* The same rule applies here in the opposite direction: leaving
*"pre-implementation"* standing after the owner reversed it would describe the persona as **weaker** than
it now is, which fails the reader just as surely as the earlier case failed the control.

**What changed, precisely, per ADR-0015:** `agents/harness-lead.md:4` gains `Write, Edit`, mirroring
`agents/tech-lead.md:4`'s unscoped grant; the mitigation is the same "cannot merge" floor already
mechanical for this persona (rules 5d and 7b's catch-alls), not a new hook or a path-scoped deny — the
latter was considered and rejected on the record already made at `agents/quality-assurance.md:100-102`
(the `security`/`Edit(.claude/**)` failure). `harness-lead` also gains a durable, posted verdict
(ADR-0006's shape) and a real Issue for its harness proposals (`loop`-typed), with `ready` on a
`loop`-typed Issue now an **owner-only** transition — closing the question [ADR-0012](./0012-issue-type-
is-the-routing-axis-and-is-exclusive.md) named and left open (*"whether `loop` items should ever reach
`ready` autonomously the way `product` items can"*).

**What is unchanged:** the roster count (still five), tier 1's membership, the merge authority (still
`quality-assurance` alone, rule 7b), and the reason `harness-lead` was created in the first place —
*"every scenario ships with how to verify it, or is labelled a hypothesis."* This amendment widens **what**
the persona may do once its scenarios are accepted; it does not touch **how** it produces them.

## Amendment (2026-08-13, twelfth) — the WIP bound's collision with "act while you wait", and its correction

**Named here because `harness-engineering`'s consolidation ([#224](https://github.com/tedeuxx/tadeumendonca-skills/issues/224))
found no ADR home for it and this is the nearest one** — the fifth amendment above named the WIP-bound
move as out of scope for itself; this is that debt, paid as its own dated entry rather than folded into
the fifth's block.

The principles layer separately states that a turn ending on a dispatched-and-waiting reviewer must
**name and begin the next non-overlapping action** rather than merely report status — silence reads as
being stuck. While WIP was bounded by a raw *count*, that rule collided with it directly: the guard
denied opening a second PR even for a slice sharing zero files with the one already open, so *"work in
parallel while you wait"* and *"WIP = 1"* gave opposite instructions on the same turn, and the
count-based hook was the one with a backstop. The bound moving to file **overlap** (the fifth amendment
above) is what resolved the collision, by making "start something disjoint while you wait" and "don't
let two overlapping slices rot into conflict" the same rule instead of two rules fighting over the same
guard.

**The 2026-08-13 WIP=1 correction** (see `harness-engineering`'s own section on it) **supersedes the
WRITTEN principle this collision produced** — the disjoint-files exception is struck and the policy is
now a strict count of one in-flight branch — but that correction is written policy only.
`hooks/scripts/wip-guard.sh` still enforces file overlap, not a raw count, so as of this amendment the
mechanism and the stated policy disagree: the hook permits a second, disjoint PR that the policy now
forbids. **Named as a residual rather than silently left inconsistent**; closing it is a
`wip-guard.sh` change, not a docs one, and is not this amendment's or #224's job.

## Amendment (2026-08-13, thirteenth) — `writer` joins the roster; six personas, and the sixth satisfies none of the four reasons

**The roster grows to six.** `writer` — a content-scoped second builder, drafting articles, site copy
and social-post language (LinkedIn/X) in the owner's voice — joins tier 2 alongside `developer`.

**Said plainly rather than stretched to fit: `writer` does not satisfy any of the four reasons amendment
#10 states for a persona to exist** (disagreement wanted, fresh context wanted, context-window
constraint, capability should be smaller). It exists because a `content`-typed Issue had no mechanical
builder at all — `product-lead` holds no `Write`; `developer` has `Write` and the relevant globs but is
never dispatched to `content` work, since `/autonomy-on`'s queue was `product`+`ready` only. That is a
**capability gap**, a fifth shape the four-reason criterion does not name. **Owner override, 2026-08-12,
ahead of #161's own measured-delta precondition** — #161 asked to measure the current roster's drafting
delta on one article *before* adding a persona; this amendment adds it first and retains #161's
measurement clause as `writer`'s own acceptance criteria (tracked in #187) rather than as a gate on its
creation.

**What compensates for skipping the precondition, named rather than assumed:** the same reconciliation
logic that let `harness-lead` (amendment #10) join tier 1 at zero cost applies here in tier 2 —
`developer` and `writer` never run on the same work, so there is no verdict of one to reconcile with the
other's. The cost this addition actually pays is a NEW containment surface, not reconciliation:
`writer` reads the same private positioning material (`.brand/`) that justified denying `product-lead`
direct public posting, so it needed the identical mechanical boundary.

**Two preconditions shipped WITH the persona, not after (#187):**

1. **`permission-guard.sh` rule 5e inverted from a denylist to an allowlist.** The old form named only
   `product-lead` to deny; probed, `agent_type=…:writer` fell through ALLOW — the exact "absent is not a
   state" shape ADR-0018 later names for the AWS floor, found here first. The new form allowlists the
   personas cleared to post directly (`developer`, `tech-lead`, `harness-lead`, `quality-assurance`, the
   main agent) and denies everything else by default, `writer` included, so a future private-material-
   reading persona is contained automatically rather than needing to be remembered.
2. **The `Write`/`Edit` observability gap is accepted in writing, not closed mechanically.**
   `hooks/hooks.json` registers `PreToolUse` on the `Bash` matcher only — nothing in this harness
   observes a file write anywhere, for any persona, and building that hook (registering `PreToolUse` on
   the `Write`/`Edit` matcher and confirming it receives a file path — nobody has tested whether it
   does) needs the plugin active to test live, which it was not at the time this amendment was written.
   **The accepted control for now is the owner reading the diff** — the same residual every merge
   request already carries at the human end, not a new mechanism. Revisit once the hook can genuinely be
   tested; do not read this as a closed question.

**The sourcing constraint and the fail-open behavior are in `writer`'s own brief, not merely implied** —
shape/cut/structure/translate, never originate; validate always, no autonomous-inference tier, per the
owner's own calibration (*"é a minha imagem à prova. Prefiro validar sempre."*); and an explicit refusal
to draft around a missing source for any consumer of this public plugin who has no private material of
their own.

**Named as consequent work, not done here:** the cross-repo staleness list #187 names (`-io`'s drift
check, generated manifest, harness-source test, architecture-diagram test, both locale editions of the
architecture page) and ADR-0012's own S5 resolution (route `content` Issues to `writer`, not `developer`
as a stopgap) — both outside this ADR's write scope.

## Consequences
**Good**
- Context efficiency and authorship-bias elimination fall out of per-task isolation.
- Reusable across projects; the roster models a whole engineering org.
- The copy gets a reviewer with a mandate, instead of relying on the code reviewer noticing.

**Bad / accepted costs**
- Orchestration overhead and token cost — spawn a specialist only when a slice genuinely spans its domain.
- Same-model review has a ceiling: a fresh context removes *authorship* bias, not *model* bias — which is
  why the boundary class still escalates to a human (ADR-0004).

## Links
- Driven by ADR-0001 (ADRs are the brain this depends on) · the DoD is ADR-0003 · autonomy/tool-scoping is
  ADR-0004 · full design in `docs/proposals/agentic-dev-loop.md`.
