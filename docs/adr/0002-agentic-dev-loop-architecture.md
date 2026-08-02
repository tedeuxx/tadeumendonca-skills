# 0002. Agentic dev-loop architecture — per-task subagents, ADRs as the durable brain

- **Status:** accepted · **amended 2026-07-23** (twice — the product/decision-support layer joins the roster) · **amended 2026-07-24** (amendment #3 — the roster reshapes: `product-owner` re-scoped, `brand-guardian`/`editor`/`recruiter`/`scrum-master` join; owner-ratified, implementation sequenced in follow-on slices per issue #69) · **amended 2026-07-29** (amendment #4 — the `brand-guardian` trigger becomes a fail-closed rule instead of a path list; `-io`#202) · **amended 2026-07-30** (amendment #5 — `product-manager` gets a trigger, discharging #68's debt for it; the reviewer's output gets a round budget) · **amended 2026-08-01** (amendment #6 — a finding blocks only by naming a criterion and a falsifier; the DoD grows criterion 10; the lenses self-classify severity; the round budget drops to two) · **amended 2026-08-02** (amendment #7 — the roster drops 19 → 6 on a new criterion: a persona exists only where conflict is wanted; three leads, one fullstack builder, two gatekeepers)
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
was knowingly stricter than the rule.)*

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
