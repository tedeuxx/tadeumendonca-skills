# 0002. Agentic dev-loop architecture — per-task subagents, ADRs as the durable brain

- **Status:** accepted · **amended 2026-07-23** (twice — the product/decision-support layer joins the roster) · **amended 2026-07-24** (amendment #3 — the roster reshapes: `product-owner` re-scoped, `brand-guardian`/`editor`/`recruiter`/`scrum-master` join; owner-ratified, implementation sequenced in follow-on slices per issue #69)
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
path**. It is **advisory** and has **no write capability at all** (`Read, Grep, Glob` — no `Bash`,
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
