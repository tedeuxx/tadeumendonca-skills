# 0002. Roster and dev-loop — who exists in the loop, what each actor is for, and how work moves
through them

**This is the `roster-and-dev-loop` capability document.** It was titled *Agentic dev-loop architecture
— per-task subagents, ADRs as the durable brain* until 2026-08-20, when the owner's decision that an
anchor is named for its capability ([#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283))
reached this record. **The number is unchanged; the filename is not.** On the same day it absorbed
records **0012, 0013, 0014, 0015 and 0019** under
[ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)'s fourth disposition —
each of those decisions is still in force and has moved into the document that governs the capability it
belongs to. Their History rows are in [the index](./README.md).

- **Capability:** roster-and-dev-loop
- **Status:** accepted · **absorbed records 0012, 0013, 0014, 0015 and 0019 on 2026-08-20** (#283 slice
  S4 — all five were `accepted`; none was `proposed`, so the open question record 0007's absorption
  raised does not arise here) · **amended 2026-07-23** (twice — the product/decision-support layer joins the roster) · **amended 2026-07-24** (amendment #3 — the roster reshapes: `product-owner` re-scoped, `brand-guardian`/`editor`/`recruiter`/`scrum-master` join; owner-ratified, implementation sequenced in follow-on slices per issue #69) · **amended 2026-07-29** (amendment #4 — the `brand-guardian` trigger becomes a fail-closed rule instead of a path list; `-io`#202) · **amended 2026-07-30** (amendment #5 — `product-manager` gets a trigger, discharging #68's debt for it; the reviewer's output gets a round budget) · **amended 2026-08-01** (amendment #6 — a finding blocks only by naming a criterion and a falsifier; the DoD grows criterion 10; the lenses self-classify severity; the round budget drops to two) · **amended 2026-08-02** (amendment #7 — the roster drops 19 → 6 on a new criterion: a persona exists only where conflict is wanted; three leads, one fullstack builder, two gatekeepers) · **amended 2026-08-02** (amendment #8 — the intake chain: nothing worked outside the tracker, the three leads close the issue's description, and those requirements become the gate's external ruler; both gatekeepers approve every MR in parallel; the builder delivers the E2E suite) · **amended 2026-08-04** (amendment #9 — `marketing-lead` merges into `product-lead`; the roster drops 6 → 5; the blocking-truth clause is carried across explicitly, and the capability floor that backed it is not) · **amended 2026-08-04** (amendment #10 — `agents-lead` joins tier 1 as the owner's pair on the machinery, advisory and pre-implementation; `security` is **absorbed** into `quality-assurance`, which now holds two lenses in one pass and labels every finding with its lens. The roster is still **five** and **two of its members changed**. The persona criterion widens from *conflict wanted* to **four reasons**, with reconciliation cost paid **within** a tier. Amendment #9's *"both approvals are still required"* is **struck**. Books the rule that produced the gap: **a count is not an identity**) · **amended 2026-08-13** (amendment #13 — `writer` joins tier 2 as a content-scoped second builder; the roster grows 5 → 6; it satisfies none of the four reasons and is named plainly as an owner override; `permission-guard.sh` rule 5e inverted from a denylist to an allowlist to contain it; the `Write`/`Edit` observability gap is accepted in writing rather than closed mechanically) · **amended 2026-08-21** (amendment #14 — `product-lead`'s boundary is `tadeumendonca-io`; consolidates #295/#296/#297: inside `-skills` it may BLOCK on a false published claim and RECOMMEND, advisory-only, on communication, but may not comment on `-skills`'s functioning; `loop`-typed non-dispatch (#295) is a corollary of this rule, not a parallel clause; the labelling discipline (#296) generalises to every advisory finding, not only `loop`-typed ones; enforcement is prose-only, confirmed against Claude Code's own hooks documentation — no hook layer can observe or refuse a `Task` dispatch) · **amended 2026-08-23** (amendment #16 — the gate merges the boundary class, `content` included, under its own verdict literal `APPROVE-AND-MERGE-BOUNDARY`; the owner reviews live, after deploy. The argument is the loop model: under `trunk-single-env` there is no preview to hold for, so the hold bought a queue rather than an environment. The counter-argument is recorded rather than omitted — `tadeumendonca-io#479`, an article that reached production unreviewed after the gate had correctly refused to merge it. **Four holds survive**, none of them on the preview argument: an expansion of the gate's own authority, a harness diff with no `agents-lead` marker, anything in `iac/`, and a lens `ESCALATE`. Two of those were carried implicitly by the phrase *boundary class* and would have stopped working silently. `permission-guard.sh` rule 7c accepts two merge-authorising literals, spelled out rather than globbed; `session-wip.sh` learns the second; the verdict vocabulary is gated against the persona file for the first time. **This list omits amendments #11, #12 and #15** — a pre-existing gap found while numbering this one and deliberately not backfilled here, since a numbering slice is not a boundary-merge slice; all three are present in the record body)
- **Date:** 2026-07-22
- **Deciders:** the owner
- **Driven by:** [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md) —
  absorbed record 0001 (MADR adoption, the two libraries, the light significance gate) on 2026-08-20 —
  `docs/proposals/agentic-dev-loop.md`

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
libraries (record 0001, now [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md))
are what make the isolation safe — without them, isolation is a drift machine. The
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
2. **Extend the DoD ([ADR-0006](./0006-verification-and-its-artifacts.md), the record
   that carries it since record 0003 was absorbed on 2026-08-19) and give `critical-reviewer` the
   positioning mandate** — *strongest
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
> [ADR-0006](./0006-verification-and-its-artifacts.md)'s third 2026-08-04 amendment;
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

**Superseded 2026-08-14 — see this document's *`README.md` is the single source of truth for the dev-loop
narrative (absorbed 2026-08-20, record 0019)* section.** `README.md` is now that home;
`docs/dev-loop-design.md` is retired to a pointer stub rather than kept as a second document claiming the
same authority. This ADR library is still what governs; where this note and that section disagree, the
2026-08-14 decision — the later one — wins on this specific question.

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
[ADR-0004](./0004-controls-and-enforcement.md)'s 2026-08-04 amendment, with the mechanism that
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
is absorbed and `agents-lead` joins. The line stands struck rather than corrected because the
substitution it describes is exactly the one every mechanical check in this repo held green.

## Amendment (2026-08-04, tenth) — `agents-lead` joins tier 1; `security` is absorbed into `quality-assurance`

**Two decisions, both the owner's, both taken 2026-08-04**, recorded in one amendment because they are
one roster move under one criterion — the same shape amendment #7 used, and the same decider in the same
session. Where they differ they are kept apart below.

**Why this record was late, and it is the finding that opened it.** `quality-assurance` blocked
`-skills`#146 on this gap: the roster shipped and no decision record moved with it. The previous roster
change (`6696148`) amended **four** records — this ADR, ADR-0006, the ADR index and
`docs/dev-loop-design.md` — **in the same commit as the persona files**. So the practice is not in
dispute and this is an **omission, not a policy**. The next reader should conclude that a sweep was
missed once, not that records are written afterwards here.

### Decision 1 — `agents-lead` exists, tier 1, advisory, ~~pre-implementation~~

**Struck 2026-08-12 by the eleventh amendment, below** — the owner reversed the pre-implementation-only
constraint; `agents-lead` now also implements the harness changes it stress-tests, under this document's
*`agents-lead` implements the harness it reviews (absorbed 2026-08-20, record 0015)* section. The
persona's existence, its tier, and every other clause in this Decision stand unchanged.

The owner is the CEO of this initiative **and acts as its harness engineer**. `agents-lead` is
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

**ADR-0004's question is its standing mandate** — *which layer carries a control, and can that layer
hold it?* That record was written because nobody owned the question. Someone does now.

**The name is not decoration, and the suite is what decided it.** The first draft was `harness-lead`
(quoted verbatim — the candidate string at this 2026-08-04 amendment, unrelated to the persona's
2026-08-21 rename to `agents-lead` at #291; the two events happen to share a spelling and are not
otherwise connected).
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
decision above: `agents-lead` argues with the owner rather than with another persona, and `security`
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
because product-versus-system disagreement *is* the point, and its **third**, `agents-lead`, pays
nothing because it never runs on the same work as the other two — that is decision 1.

**This supersedes amendment #7's single-reason criterion.** That reason survives as the first of four;
what is struck is the claim that it was the only one. Amendment #9's *"conflict between two objects"*
refinement also stands, as a test applied within reason one.

### The general rule this omission leaves behind, and it is worth more than the fix

`quality-assurance` traced the cause: **`inventory-counts.test.sh` asserts the roster as a COUNT, not as
a membership.** The value is derived honestly — `find agents -name '*.md' | wc -l` — and every stated
figure in the docs is checked against it, which is a real check. It simply cannot see this change:
`security` out and `agents-lead` in **holds the count at five**, so every gate stayed green through
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
- **The merge precondition** — record 0007 until 2026-08-20, now
  [ADR-0004](./0004-controls-and-enforcement.md)'s *The merge precondition is a floor, not an
  instruction* section. Its precondition counts two markers. Amended there. It is status `proposed` and
  unimplemented (`grep gatekeeper-verdict hooks/` returns nothing), so **nothing breaks today**; what
  would have broken is the slice that implemented it against this record.
  > **The parenthetical expired 2026-08-05.** That `grep` now hits `session-wip.sh` and its suite — a
  > SessionStart *reader* that annotates a PR with no verdict on its current head, deciding nothing.
  > The deny hook is still unimplemented; only the command that proved it is gone. The check that still
  > works is in the absorbed section: look for a hook that returns a `deny` decision on `gh pr merge`.
  > The reason the proxy broke: a grep for a *string* stood in for the existence of a *control*.

Roster: **five** — `product-lead`, `tech-lead`, `agents-lead` (tier 1) · `developer` (tier 2) ·
`quality-assurance` (tier 3). The count is unchanged from amendment #9 **and two of the five members
are different**, which is the whole point of writing the names.

## Amendment (2026-08-12, eleventh) — Decision 1's *"advisory, pre-implementation"* framing is struck; `agents-lead` gains an implementer role

**Struck, not rewritten:** Decision 1's header above reads *"`agents-lead` exists, tier 1, advisory,
pre-implementation"* and its body states *"It gates nothing. It does not review merge requests, does not
merge, does not open work."* The **merge** and **MR-review** clauses stand verbatim — unchanged by this
amendment, and re-verified as still true (`hooks/scripts/permission-guard.sh:136`'s catch-all still
denies `gh pr merge` to this persona). The **pre-implementation** clause is struck: the owner reversed it
on 2026-08-12, and `agents-lead` now also builds the harness changes it stress-tests, under this
document's *`agents-lead` implements the harness it reviews (absorbed 2026-08-20, record 0015)* section.

**Why struck rather than silently widened:** amendment #10's own framing — *"a persona exists only where
conflict is wanted"* widened, that same day, to *"a persona exists for one of four reasons"* — was struck
in place rather than edited, on the stated rule that *"a record describing a control as stronger than it
is [...] is the direction that fails open."* The same rule applies here in the opposite direction: leaving
*"pre-implementation"* standing after the owner reversed it would describe the persona as **weaker** than
it now is, which fails the reader just as surely as the earlier case failed the control.

**What changed, precisely, per this document's *`agents-lead` implements the harness it reviews
(absorbed 2026-08-20, record 0015)* section:** `agents/agents-lead.md:4` gains `Write, Edit`, mirroring
`agents/tech-lead.md:4`'s unscoped grant; the mitigation is the same "cannot merge" floor already
mechanical for this persona (rules 5d and 7b's catch-alls), not a new hook or a path-scoped deny — the
latter was considered and rejected on the record already made at `agents/quality-assurance.md:100-102`
(the `security`/`Edit(.claude/**)` failure). `agents-lead` also gains a durable, posted verdict
(ADR-0006's shape) and a real Issue for its harness proposals (`loop`-typed), with `ready` on a
`loop`-typed Issue now an **owner-only** transition — closing the question the routing decision named
and left open (*"whether `loop` items should ever reach `ready` autonomously the way `product` items
can"*). Both now live in this document: see its *Issue type is the routing axis, and it is exclusive
(absorbed 2026-08-20, record 0012)* and *`agents-lead` implements the harness it reviews (absorbed
2026-08-20, record 0015)* sections, the latter's **Corollary 4**.

**What is unchanged:** the roster count (still five), tier 1's membership, the merge authority (still
`quality-assurance` alone, rule 7b), and the reason `agents-lead` was created in the first place —
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
logic that let `agents-lead` (amendment #10) join tier 1 at zero cost applies here in tier 2 —
`developer` and `writer` never run on the same work, so there is no verdict of one to reconcile with the
other's. The cost this addition actually pays is a NEW containment surface, not reconciliation:
`writer` reads the same private positioning material (`.brand/`) that justified denying `product-lead`
direct public posting, so it needed the identical mechanical boundary.

**Two preconditions shipped WITH the persona, not after (#187):**

1. **`permission-guard.sh` rule 5e inverted from a denylist to an allowlist.** The old form named only
   `product-lead` to deny; probed, `agent_type=…:writer` fell through ALLOW — the exact "absent is not a
   state" shape [ADR-0004](./0004-controls-and-enforcement.md)'s *Permission entries have three states,
   and absent is not one* section later names for the AWS floor, found here first. The new form allowlists the
   personas cleared to post directly (`developer`, `tech-lead`, `agents-lead`, `quality-assurance`, the
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
architecture page) and the routing decision's own S5 resolution — now this document's *Issue type is the
routing axis, and it is exclusive (absorbed 2026-08-20, record 0012)* section, **Corollary 3** (route
`content` Issues to `writer`, not `developer`
as a stopgap) — both outside this ADR's write scope.

## Amendment (2026-08-21, fourteenth) — `product-lead`'s boundary is `tadeumendonca-io`; inside `-skills` it may block on falsity and recommend on communication, never prescribe configuration

**Consolidates three `loop`-typed intakes from the same session (#295, #296, #297) into one decision,
because the owner closed all three with one framing rather than three.** Each Issue reasoned toward its
own recommendation from a different door; the owner's closing words collapse the doors into a single
rule, so this amendment states the rule once rather than as three patched-together findings.

### The three questions, and the owner's answers, verbatim

**#295 — which axis routes `loop`-typed intake, repository or issue type?** Asked directly, he chose
**"Eixo TIPO (recomendado)"**. `product-lead` was never routed to `loop` intake by the type axis
(`README.md`, `/architecture`); the two observed dispatches (#287, #291) were a substitution nothing in
the axis licensed. This amendment does not need to re-decide that axis — it is decided — but the
composition below makes the non-dispatch a **consequence** of the boundary rather than an independent
routing rule, which is the correction to how #295 itself was framed (see *What #295 becomes*, below).

**#296 — does `product-lead`'s career/positioning half stay inside one persona, or split back out?**
Shown the orchestrator's proposed resolution — reinforce the existing BLOCKING/ADVISORY labelling
discipline and change nothing else — the owner **rejected it**: *"eu acho que vc deveria fazer o
product-lead nao se manifestar sobre funcionamento do -skills, somente fazer recomendacoes sobre a
comunicacao da solucao. isso que acho que falta."* Asked as a direct follow-up whether the composition's
load-bearing clause — the BLOCKING veto on published falsity, carried across from `marketing-lead` by
amendment #9 — survives that narrowing, he chose **"Mantém o BLOCKING só pra falsidade
(recomendado)"**: the veto stays, unscoped; everything else about **how** a `-skills` solution is
communicated becomes advisory-only, never blocking.

**#297 — does the narrowing bind `product-lead` alone, or the whole `-io`→`-skills` door (the 7-instance
population #297 measured, including non-`product-lead` actors like `critical-reviewer` and the owner
himself)?** Unprompted, closing the Issue in one line: **"a boundary do product lead é o -io."** The
owner scoped the rule to the **persona**, not the door — #202's `critical-reviewer` repair and #328's
owner-originated rename are unaffected by this amendment; nothing here constrains any actor but
`product-lead`.

### The rule, stated once

**`product-lead`'s home, full mandate (product + market/positioning), and dispatch surface are
`tadeumendonca-io`.** When its work reaches `-skills` — through a `product`/`content`-typed `-io` Issue
whose resolution lands as a `-skills` commit (#297's Door 3), or through the copy lens reviewing a
`-skills` PR's own prose (#297's Door 2, untouched by this amendment) — its authority over `-skills`
narrows to exactly two things:

1. **It may BLOCK** — the existing truth veto (amendment #9), unchanged in force and unscoped by object —
   when a claim `-skills` publishes to a reader is **FALSE**. This is not a new veto; it is the same one,
   stated here to survive the narrowing rather than be read as repealed by it.
2. **It may RECOMMEND, advisory-only, never blocking** — on how a `-skills` solution is **communicated**:
   wording, clarity, whether a reader can follow it, tone, the structure of an explanation. It may **not**
   comment on, or have any standing to influence, `-skills`'s **functioning** — machinery, hooks,
   permission logic, agent-brief mandates, gate mechanics; anything that is *how the harness works* rather
   than *how a claim about the harness reads*.

**Worked examples, because the line is meant to be self-applied without re-deriving this reasoning:**

- The marketplace `plugin.json` `description` asserts a capability the plugin does not have → **may
  block** (falsity about a published surface).
- A hook's branching logic is wrong (e.g. it denies a case it should allow) → **may not comment** — that
  is functioning, `agents-lead`'s object, per ADR-0004's *Which layer carries a control* section.
- The wording of an error message a guard hook emits is confusing → **may recommend** — communication,
  advisory.
- A persona brief's trigger rule (the shape #202 rewrote, the sharpest instance #297 measured) → **may
  not comment** — functioning, whatever door the finding arrives through.

### What #295 becomes — a corollary, not a parallel clause

**If `product-lead` does not comment on functioning at all, it has nothing to contribute to `loop`-typed
intake, which is about machinery decisions.** So *"`product-lead` is not dispatched on `loop`-typed
Issues in `-skills`"* — #295's own recommendation — follows from this amendment's boundary rule rather
than needing independent justification. `loop`-typed intake continues to close through `agents-lead`
and `tech-lead` (`README.md`, `/architecture`, unchanged by this amendment); `product-lead`'s absence
from that chain is now explained by what it is, not asserted as a separate routing carve-out.

### What #296 becomes — a general discipline, not a `loop`-specific one

**The labelling-discipline finding (`BLOCKING:`/`ADVISORY:`, `BLOCKING: none` stated explicitly) is not
primarily about `loop`-typed work** — that door is closed by the corollary above. It is a **general
requirement for every advisory recommendation this persona returns, in any context**: ordering and craft
findings in `-io`'s `product`/`content` intake, and the narrow communication-only lane inside `-skills`
this amendment creates. `agents/product-lead.md`'s existing *"The report format"* section already states
this; it is unchanged and is not weakened by this amendment — the two `-skills` dispatches that violated
it (#287, #291) are exactly the two instances that motivated writing the boundary down at all.

### Enforcement — stated plainly, once, because every other clause in this batch gets the same treatment

**This is prose in a brief, with no mechanical enforcement, and #297's own comment thread confirms this
against the primary source rather than merely failing to find a counter-example:** the official Claude
Code hooks documentation states `SubagentStart` **cannot block** a dispatch — informational only — and
`SubagentStop` can only force a subagent's own continuation, after it already ran, never refuse the
decision to dispatch it. `hooks/hooks.json` registers `PreToolUse` on the `Bash` matcher only, so no
hook observes a `Task` dispatch at all. **There is no wider registration that would close this** — it is
not a configuration gap, it is the documented ceiling of the mechanism. This amendment converts an
unloaded rule (two Issue bodies, session memory — the exact shape that let #287 and #291 happen) into a
**loaded** one (`agents/product-lead.md`, preloaded on every dispatch); that is the whole of what it buys,
and it is stated as a ceiling rather than implied to be stronger.

### What this amendment does NOT change

- **The composition decided by amendment #9** — `product-lead` still holds both halves, product and
  market/positioning, as one persona over one object (the owner's presence). #296 asked whether to split
  the persona back apart and the owner declined; this amendment narrows what the persona may say about
  one specific object (`-skills`'s machinery), not what the persona *is*.
- **The BLOCKING veto's force or scope elsewhere.** Unchanged in `-io`, unchanged on `-skills` prose
  reviewed through the copy lens (#297 Door 2), unchanged as the mechanism amendment #9 carried across.
- **Door 2** (the copy lens reviewing `-skills` PR prose at merge review) and **the residual doors** #297
  measured that are not `product-lead` (`critical-reviewer`, the owner). Both are outside this amendment's
  scope by the owner's own #297 answer.

### A cross-repo staleness this amendment creates and does not close

`tadeumendonca-io`'s `/architecture` republishes this repo's roster table and, in prose, describes
`product-lead`'s mandate — potentially in terms this amendment narrows for the `-skills` object
specifically. This ADR cannot edit that page; the staleness is named in the PR that carries this
amendment rather than silently left for a later discovery.

## Amendment (2026-08-21, fifteenth) — `harness-lead` renamed `agents-lead`, everywhere in `-skills`

**#291, authorized to build in the owner's final closing comment on that Issue.** The rename is on
record twice already in this document without being named as such: amendment #10's *"the first draft
was `harness-lead`"* and this document's own *`agents-lead` implements the harness it reviews (absorbed
2026-08-20, record 0015)* section title are both artifacts of it, not decisions in their own right —
this amendment is where the rename itself is recorded.

**The intent, verbatim from the owner (quoted in #291, not re-derived here):** *"o proposito é que
harness nao é pluralmente conhecido. agents vai ser mais facil para usuarios novos entenderem quem é o
que ele faz"* — newcomer comprehension, reading `agents/` for the first time, deciding who does what.
**Not** market legibility (the `/architecture` gloss `product-lead` offered as a cheaper alternative was
withdrawn once this intent was named — a gloss serves the published page's reader, not the person
opening `agents/`) and **not** directory symmetry (rejected on the merits in #291: the name would cover
one-seventh of a seven-item mandate — hooks, settings and permissions, agent briefs, skills, commands,
the plugin, MCP).

**A correction #291 itself records, kept here rather than only there:** `product-lead`'s two remaining
objections on the merits (narrower than the mandate; parses as a false hierarchy claim) were **never
this Issue's to weigh** — amendment #14 above, ratified the same session, is exactly the boundary that
makes a machinery persona's own naming `product-lead`'s to recommend on communication and never to
grade on functioning. #291 is the concrete historical instance that boundary rule exists to stop, and is
worth keeping as evidence rather than smoothed over in the record.

**Naming axis: still not settled, and this amendment does not settle it.** `-lead` encodes the tier;
`harness` encoded the domain; `agents` encodes neither — it is chosen for legibility to a newcomer, a
fourth axis nothing in this roster previously named. The next persona named will re-open this unless a
future amendment states the axis once. Left open deliberately, on the same terms #291 left it.

### What the rename touched, and the two load-bearing risks it had to resolve

**Scope: `tadeumendonca-skills` only.** Fresh census at this amendment's own head (`git log -1` at the
start of the build), by the same commands #291 used at intake: `grep -rl 'harness-lead' --exclude-dir=.git
<repo> | wc -l` → **24 files**; `grep -ron 'harness-lead' --exclude-dir=.git <repo> | wc -l` →
**191 occurrences**. Both are lower than #291's 2026-08-19 intake figures (32 files / 249 occurrences) —
the gap is #283 parts 1–3, which rewrote large sections of the ADR library between intake and build,
consolidating 20 records into 6 and dropping duplicated narrative along the way; it is not evidence
anyone pre-emptively touched this rename. `tadeumendonca-io` (measured at `origin/main`, since the local
checkout there sat on an unrelated feature branch): `git grep -l 'harness-lead' origin/main | wc -l` →
**9 files**, `git grep -o 'harness-lead' origin/main | wc -l` → **58 occurrences** — unchanged from
intake, confirming `-io`'s side was untouched between #291's filing and this build. All 191 occurrences
here resolved to `agents-lead` except the ten instances of the literal string `harness-lead-verdict`
(below) and two verbatim historical quotes (also below) — every other file is swept clean
(`grep -rn 'harness-lead' --exclude-dir=.git <repo> | grep -v 'harness-lead-verdict'` → no hits).

1. **The `harness-lead-verdict` marker string is kept UNRENAMED, deliberately.** Every verdict already
   posted to a GitHub comment carries this exact string and cannot be rewritten; renaming it would make
   every prior verdict invisible to `quality-assurance`'s Corollary 2 check and to
   `dispatch-metrics-stop.sh`'s rework-round counter, with no red anywhere to say so. The cost accepted
   instead: the producer's own filename (`agents/agents-lead.md`) no longer matches the string it emits
   — a deliberate, documented inconsistency, not an oversight. `hooks/scripts/inventory-counts.test.sh`
   now carries a "marker literal" assertion pinning the string identical across its producer
   (`agents/agents-lead.md`) and both consumers (`agents/quality-assurance.md`,
   `hooks/scripts/dispatch-metrics-stop.sh`) — mutation-checked by corrupting one copy
   (`harness-lead-VERDICT`) and confirming the suite reddens before restoring it.
2. **`permission-guard.sh`'s literal-name allowlist entry (rule 5e's case statement) was updated in the
   same commit as the brief rename.** Verified both ways by live probe rather than by reading: with the
   entry present, `{"tool_input":{"command":"gh pr comment 1 --body test"},"agent_type":"orchestrator:
   agents-lead"}` piped into the guard returns no deny (exit 0, empty stdout); with the entry
   temporarily removed, the same payload returns `permissionDecision: deny`, falling to the catch-all
   exactly as #291 predicted — the renamed persona would have silently lost `gh pr comment`/`gh issue
   comment`, i.e. the ability to post the marker in finding 1, had this been missed.

**Record 0015's retired filename, `0015-harness-lead-implements-the-harness-it-reviews.md` (no longer
under `docs/adr/` — see below) — moot, not decided.**
#291 asked for a decision between renaming the file (repointing 8 path-form citations) or leaving it (a
stale title against ADR-0020's current-codebase rule). Neither applies: the file no longer exists.
#283 slice S4 (2026-08-20, one day before #291's authorization) absorbed record 0015 into this document
as this document's own *`agents-lead` implements the harness it reviews (absorbed 2026-08-20, record
0015)* section, below, and `docs/adr/README.md`'s History row for record 0015 already points here. Zero
path-form citations to the retired filename remain (`grep -rn '0015-harness-lead-implements'
--exclude-dir=.git <repo>` → no hits). The section heading itself was swept to `agents-lead` along with
the rest of this document's identity-reference prose, per the sweep precedent below.

**`inventory-counts.test.sh:526`'s `*-lead.md` exclusion re-spelled and mutation-checked, not merely
edited.** The arm excludes `agents-lead.md` from the derived "two leads" count (it is tier-equal with
`product-lead`/`tech-lead`, not one of the two who close an Issue's description). Reverting just the
filename in the exclusion (`! -name 'agents-lead.md'` → `! -name 'harness-lead.md'`) and re-running the
suite reddens exactly one assertion — `roster shape — the roster has 3 leads (three); these state
another count` — confirming the arm is real, not vacuous, before the fix was accepted.

### Two verbatim quotes deliberately NOT renamed — a sweep is not always the right instrument

A blind global rename corrupts a quote of a *past* fact into a false one. Found and corrected in this
same commit, both in this document and one in `zombie-loop-detect.sh`:

- **Amendment #10's *"the first draft was `harness-lead`"*** — the candidate name string at the
  2026-08-04 decision this amendment describes, unrelated to and six weeks earlier than this rename. A
  blind sweep first turned it into *"the first draft was `agents-lead`"*, which is false: `agents-lead`
  was never proposed at that amendment. Restored to `harness-lead`, with a parenthetical noting the two
  events share a spelling by coincidence and nothing else.
- **The #294 incident quote, *"Vou despachar o `harness-lead`..."*** (this document's *Consequences
  still being paid (record 0013)* section, and `zombie-loop-detect.sh`'s own header) — the orchestrator's
  verbatim narrated turn on 2026-08-20, before this rename existed. Restored to `harness-lead` in both
  files, each now annotated that the quote predates #291.

**Everywhere else, the sweep followed the precedent #216 set** (`harness-reviewer` → `harness-lead`,
2026-08-13): identity-reference prose describing *what the persona is/did/does*, including historical
amendment narrative naming the persona in past tense (*"`agents-lead` joins tier 1"*, *"`agents-lead`
was created"*), reads as current identity and was swept in full — `harness-reviewer` left zero traces
anywhere in this repo after #216, and this rename follows the same rule. Only a literal quoted string
value, distinguishable from an identity reference by asking *"is this naming the persona, or reporting
what was typed/said at a specific past moment?"*, is preserved as-is.

**A mechanical hazard worth naming for the next rename: grammar does not survive a blind substitution.**
`harness-lead` begins with a consonant sound (*"a `harness-lead`"*); `agents-lead` begins with a vowel
sound and needs *"an"*. Three instances of *"a `harness-lead`"* → *"a `agents-lead`"* and five of *"a
`agents-lead`"* elsewhere were found by grepping `\ba \`\{0,1\}agents-lead\b` after the sweep and fixed
by hand (`.claude-plugin/plugin.json`'s marketplace description, `README.md` twice,
`inventory-counts.test.sh`'s own comment, `agents/quality-assurance.md`, `docs/adr/README.md`,
`skills/harness-engineering/SKILL.md`, and three more sites in this document). None of the eight failures
would have reddened any gate — this repo has no grammar check — so each was a silent readability defect
a mechanical rename introduces and only a second grep-and-read pass catches.

### `tadeumendonca-io` — explicitly out of scope for this PR, named rather than silently dropped

#291's own intake named nine live surfaces in `-io`: `CLAUDE.md`,
`apps/fed/scripts/architecture-diagrams.test.mjs`, `apps/fed/src/content/architecture.{en,pt}.md`
(Mermaid node labels, the roster table row, and the `accDescr` accessibility prose read aloud to
screen readers), two live blog posts (`engineer-the-loop.{en,pt}.md`, content-class — the owner's own
edit to make, never mechanical), `generated/diagrams.json` and `generated/harness.json` (self-heal on
rebuild only if the generator runs — not confirmed automatic in this build, since it sits in the other
repo), and `-io`'s own record 0043 (`harness-inventory-derived-from-plugin-repo`, under its own
`docs/adr/`, not this repo's). None of the nine is touched by
this PR. The two repos' pipelines are independent by this repo's own convention (never couple them), and
`-io`'s own checkout sat on an unrelated feature branch during this build — a second, `-io`-scoped Issue
is the right vehicle, not a cross-repo commit inside this one.

## Amendment (2026-08-23, sixteenth) — the gate merges the boundary class; the owner reviews live, after deploy

**Decided by the owner, unprompted, on being asked what the boundary hold was buying under a
single-environment model.** In his words:

> *"a partir do momento que só temos um ambiente, acho que a cláusula de boundary não se aplica."*

**The decision.** `quality-assurance` merges the **boundary class** — `content` included — once its
Definition of Done is fully green, under its own verdict literal `APPROVE-AND-MERGE-BOUNDARY`. The
hold-for-owner rule on boundary-class merges is **retired**. The owner reviews live, after deploy.

**The argument, restated because it is a property of the loop model rather than a preference.** Under
`trunk-single-env` **merge is deploy**. Holding a boundary merge does not produce a staging copy to
inspect; it produces a delay and a queue. The hold was priced as *"the owner gets to look first"* and
what it actually bought was *"the owner gets to look later, from the same place, with the work parked
in between."* **This reasoning does not transfer to `gitflow-multi-env`** — a repo with an integration
branch does have somewhere to hold a change and look at it — and the amendment is deliberately not
extended there. `skills/quality-gates/SKILL.md` carries the change inside its `trunk-single-env` gate
table only, for exactly this reason.

### The counter-argument, which was put to the owner before he decided, and is recorded rather than omitted

**What the hold bought was the one moment the owner saw a change before the world did** — the only
pre-publication check that exists in a single-environment model at all. This is not a hypothetical.
**On 2026-08-21 an article reached production unreviewed by him**: the gate had returned
`APPROVE-PENDING-HUMAN` and refused to merge, and the pull request was merged **23 minutes later by
another actor**, with `reviews: []` (`tadeumendonca-io#479`). That is precisely the failure the retired
clause was written for, and it is the strongest available evidence *against* retiring it — the clause
fired correctly and something went around it.

**And two consequences do not come back.** Published copy stays wrong until someone notices it, and an
**OG card pinned by a scraper on first fetch is not recovered by a later correction** — both already
documented on that same article. A revert restores the repository; it does not restore what a crawler
cached or what a reader read.

**The owner was shown all of this and decided anyway.** That is his call to make and it stands. This
section exists because a record that hides what a decision cost is the defect this library was built to
catch, and because the next person to reopen this question deserves the evidence rather than the
conclusion.

### The mechanical half — because a record describing an unenforced rule is the same defect

`hooks/scripts/permission-guard.sh` **rule 7c** required the last `gatekeeper-verdict` at the PR's
current `headRefOid` to read `APPROVE-AND-MERGE`. **Boundary class never produced that literal by
design**, so the hook would have refused every merge this decision authorises. Left as prose, the
amendment would have been inert *and* the loop would have looked broken rather than unimplemented.

**What changed, and why it is a second literal rather than a widened first one:**

- **Rule 7c accepts two merge-authorising literals**, `APPROVE-AND-MERGE` and
  `APPROVE-AND-MERGE-BOUNDARY`, **spelled out and never globbed**. `APPROVE-AND-MERGE*` would have
  satisfied both in one pattern and also cleared every future prefix-sharing drift — the exact class of
  failure ADR-0004's *"The problem"* section measures (three drifted literals shipping in one day). The
  suite asserts the anti-glob case directly with a fixture reading `APPROVE-AND-MERGE-LATER`.
- **Reusing `APPROVE-AND-MERGE` for both classes was considered and rejected.** It needs no hook change
  at all, which is its whole appeal. It was rejected because it deletes the class from the machine-
  readable record: after it, nothing anywhere distinguishes *"the gate merged something the owner had
  already seen"* from *"the gate merged something nobody outside the loop has seen yet"* — and the
  owner's own decision is that he **reviews live, after deploy**, which he cannot do if nothing says
  what to go and look at. A distinction that survives only in prose is one the next slice loses.
- **`session-wip.sh` learns the second literal too**, and this is the second-order effect that would
  have been invisible from inside the change. Its `verdict_suffix()` does **not** degrade an unknown
  literal to silence — it reports *"an UNRECOGNISED verdict … a defect in the gate rather than in the
  PR"*. Adding a literal to the vocabulary without adding it there would have made **every correctly-
  verdicted boundary PR render as a defect in the gate** in the open-PR queue notice.
- **`zombie-loop-detect.sh` is examined and deliberately unchanged.** The new literal falls through its
  `*) exit 0` arm, which is correct: a clearance is not an outstanding verdict. **Named residual,
  pre-existing and unchanged by this amendment:** neither clearance fires that notice when the PR is
  still open at turn end, so *"the gate cleared it and then did not merge it"* is invisible to that
  hook — identically for both literals.
- **The verdict vocabulary gains a gate it never had.** `hooks/scripts/inventory-counts.test.sh` now
  parses `agents/quality-assurance.md`'s own *"Your verdict — exactly one of"* list and asserts, in two
  independently-reported arms, that `session-wip.sh` recognises **every** literal that list defines, and
  that rule 7c authorises a merge on **no** literal outside it. The set is read from the persona file
  rather than restated in the test, because a restated set is a second source of truth for one fact.
  **Adding a fourth literal widens the drift surface ADR-0004 was written for**, which is why the check
  lands in the same diff as the literal rather than after it.

**What the hook layer still cannot do, unchanged and not overclaimed:** rule 7c has zero reach over a
human merging in the GitHub UI or a terminal outside a session. That is how `tadeumendonca-io#479`
happened, and nothing in this amendment touches it.

### The four holds that survive, and why none of them survives on the preview argument

**Read these as separate rules that happened to live inside "boundary class" until it stopped being a
hold — not as the retired clause under another name.** On any of them the gate returns
`APPROVE-PENDING-HUMAN`, does not merge, and hands the go/no-go up.

1. **An expansion of the gate's own authority.** A diff that widens which class it may merge, removes a
   boundary trigger, or otherwise loosens its own mandate. **This has nothing to do with environments**:
   it is the one case where merging means the gate ratified its own mandate. The clause already existed
   unconditionally (see [ADR-0011](./0011-skills-and-preload.md) for the record of it drifting out of
   the persona file and back in); what changes is that it is now **load-bearing on its own** rather than
   redundant with a class that also held. **This amendment is itself such a diff**, and is therefore
   boundary class with hold 1 applying to it.
2. **A harness diff carrying no `agents-lead` verdict marker** — Corollary 2 of the *"`agents-lead`
   implements the harness it reviews"* section above. **Its old phrasing stopped working the moment
   boundary became mergeable**: it read *"absent that marker the diff is boundary class regardless"*,
   which was a hold only for as long as boundary was one. Left alone it would have bought nothing — a
   harness diff with no harness review would have merged. It is restated as its own blocker. It is a
   **missing reviewer**, the same shape as a missing gate, not a class.
3. **Anything in `iac/`.** The merge *applies*, and a destroyed resource is not recovered by a revert —
   irreversibility that escapes git, which is the permission model's own tolerance test. The single-
   environment argument does not reach it, for a concrete reason rather than caution: **there is a
   preview here**, the `terraform plan` posted on the pull request, and holding the merge is what lets a
   human read it.
4. **An explicit lens `ESCALATE`**, or a `BLOCKING` truth finding from `product-lead`. A lens has
   exactly one path to the owner and it is wired through the class. Amendment #6's own correction is the
   precedent: `ESCALATE` was first drafted routing only `BLOCKING` findings, so *"the one path the lens
   has to the owner"* was *"wired to nothing."* Retiring the boundary hold without this would have
   reproduced that defect from the other direction.

### What the safe/boundary distinction still does

**Stated explicitly, because a distinction that changes nothing should be retired rather than kept, and
this library has retired several for exactly that reason.** After this amendment the split still
decides three things:

- **Which of the four holds can apply.** Every one of them is a boundary trigger; none is a safe one. A
  slice classified safe cannot be held.
- **Which verdict literal is posted** — so the merge record itself says whether anything shipped without
  a pre-publication check. This is the fact the owner's *"I review live, after deploy"* depends on being
  able to find.
- **What the verdict must write down.** A boundary verdict states which trigger fired and what the owner
  should go and look at live; a safe verdict does not.

**What it no longer decides, outside the four holds, is who merges** — which was, until this amendment,
the only thing most readers thought it decided.

### Consequences

**Good**
- The queue stops forming behind the owner's availability on `content` and `loop` slices, which is where
  it formed. Merge is deploy either way; the hold only moved when publication happened, not whether.
- Four rules that were being carried implicitly by the phrase *"boundary class"* are now written as
  rules. Two of them (holds 2 and 4) would have silently stopped working, and both were found by asking
  what each trigger was actually buying rather than by reading the diff.
- The verdict vocabulary is gated for the first time, in both directions, against the persona file that
  defines it.

**Bad / accepted costs**
- **The pre-publication check is gone, and it was real.** `tadeumendonca-io#479` is the measured case.
  Published copy stays wrong until noticed; a pinned OG card is not recovered by a correction.
- **"The owner reviews live, after deploy" has no artifact.** This is the loop's own state-model rule
  (*what observable artifact says this rule was applied?*) failing on the rule this amendment introduces.
  Nothing records that the owner looked, and nothing surfaces to him that something boundary shipped —
  `APPROVE-AND-MERGE-BOUNDARY` makes the fact **queryable**, which is strictly weaker than **delivered**.
  **Named, not closed**: the cheapest closure would be a hook that reads merged PRs carrying that literal
  and surfaces them at `SessionStart`, and it is not built here because building the notification for a
  review nobody has yet skipped is speculative. If a boundary change is found to have shipped and gone
  unreviewed, that is the trigger to build it.
- **A fourth verdict literal is a wider drift surface**, mitigated by the new vocabulary gate rather than
  eliminated by it. The gate cannot check that the literal *means* what the brief says it means.
- **Four holds is more than the one line it replaces**, and a reader who learns "boundary means the owner
  merges" now has to learn four exceptions instead. Accepted because the alternative — folding them back
  into a class — is what made two of them stop working in the first place.

**Deciders:** the owner (the decision), written by `agents-lead` per the domain split (#223) — this is a
loop/machinery decision and the mechanical half is a hook change. **One half of it is not:** the price of
retiring the hold is paid on published content in the owner's voice, which is `product-lead`'s object,
not this persona's. That lens has not been dispatched on this amendment and should be, on the `content`
consequence specifically — not on the loop mechanics, which are outside its boundary (amendment #14).


## Amendment (2026-08-23, seventeenth) — the content pair: `writer` becomes `content-writer`, `content-reviewer` joins, and `product-lead` leaves the drafting flow

**The owner's ask, verbatim:** *"eu preciso ter um content-writer e um content-reviewer para melhorar a
barra do texto antes de cair para minha revisão."* Two further decisions from the same conversation,
also verbatim: *"o product lead acho que não pertence a esse fluxo"*, and the sequencing
*"antes de transformá-lo em content-writer"* — skills first, then the pair. Step 1 landed at #316
(`skills/published-voice/SKILL.md`); this amendment records step 2.

### The roster is seven, and the seventh is the first true PAIR

`content-reviewer` exists on **reason #1 of the four** in amendment #10 — *disagreement is wanted*.
Every other persona added since that rule was written satisfied one of the other three;
`content-reviewer` is the first added because someone should be arguing with someone, and the someone is
`content-writer`. That is also what makes it cheap for the tier the rule cares about: **reconciliation
cost is paid within a tier, not across tiers**, and both halves sit in tier 2, on the same Issue, with
one ruler between them.

**A pair is only worth its cost if both halves judge against the same sentences.** Two personas reading
two copies of a rule produce two opinions and a handoff; two reading one file produce a conflict. That
is why #316 extracted the ruler *before* this slice rather than alongside it, and why the identity of
the two `skills:` lists is now **gated** rather than asserted (`hooks/scripts/inventory-counts.test.sh`,
the *content pair* arms — a reviewer gaining a fourth skill the writer lacks reddens the build).

### The three blockers this amendment closes, and the one it does not

`agents-lead`'s pre-implementation review of the pair (#316) found three load-bearing pieces unbuilt and
said the pair was not ready. Re-tested here:

1. **No ruler.** Closed at #316. It was the stated precondition and it is the only one that was closed
   before this slice began.
2. **No round bound.** Closed here: **at most two rounds, and there is no round three.** A cap, not a
   target — a draft leaves the pair after round two whatever its state.
3. **No terminal condition.** Closed here, and mechanically rather than as "when it is good": the
   reviewer closes each round with exactly one of `CONTENT-REVIEW-FINDINGS` or `CONTENT-REVIEW-CLEAR`,
   and the pair is terminal on the first `CLEAR` **or** on the existence of a second `## Round` section,
   whichever comes first. A section count and two strings; nobody judges that it is over.
4. **No artifact recording a drafting round.** Closed here — see below — and it is the one whose closure
   is weakest, which is stated rather than glossed.

**What is NOT closed: nothing dispatches the pair.** No hook, label or gate causes a `content` Issue to
reach `content-reviewer`, so an undispatched review and a clean one are indistinguishable from outside
the diff. `quality-assurance` gains the cheapest available mitigation — *a `content` PR should carry a
review file with one or two `## Round` sections* — and that is **detection at the gate, one step late,
never prevention**. It is the same shape as `agents-lead`'s own undispatched-lens cost and is accepted
on the same terms.

### The artifact — a tracked file, and why not a comment

`content-reviewer` reads the private positioning layer to judge a draft sourced from it, so **rule 5e
denies it every posting route**, exactly as it denies `product-lead` and `content-writer`. It is named
in that rule **explicitly** rather than left to the `*)` catch-all: a deny by omission and a deny by
decision are the same behaviour and different facts, and only one of them survives a later reader
assuming the gap was an oversight — ADR-0004's *"absent is not a state"*, applied to a persona nobody
had yet decided about versus one somebody has.

**The round therefore lands in `docs/content-review/<slug>.md`, on the branch, in the diff.** This was
`agents-lead`'s own cheapest answer at #316 and it survives the ruler's arrival intact — a finding that
quotes a clause is *more* compressible than free prose, which makes the file smaller, not less
necessary. Three properties earn it over the comment it cannot post: it is in the diff the owner already
reads, it survives the session, and the round count is `grep -c '^## Round'`.

**`docs/` and not the content directory, deliberately.** A `.review.md` beside an article is a file a
site's content loader may glob and publish — the one irreversible act the whole containment exists to
prevent.

**What the artifact does not buy, stated plainly:** it is visible only to someone opening the file list.
It is not queryable from the tracker, and that is on purpose — see the state below.

### The state machine was wrong for nine days, and this fixes it

`/harness-engineering`'s state table named **`developer`** as the builder for a `content` Issue. That
was false from amendment #13 (2026-08-13) onward — `developer`'s own brief has said it does not build
`content` since #187 — and nothing reddened, because no gate reads that table. The row now names
`content-writer`, and a `drafted` sub-state is added for `content` only.

**`drafted` adds NO label.** The restraint amendment #8 earned — *keep the remedy to one bit* — is about
the label vocabulary, and it is unchanged: `ready` is still the only state this loop added to the
tracker. `drafted` is recorded by a file already in the branch's diff, which satisfies *what observable
artifact says this rule was applied* without making the tracker learn a sixth word. Its cost is the
inverse of `ready`'s and is the same one named above: not queryable from outside the PR.

### `product-lead` leaves the drafting flow — and what survives is not craft

**Only the craft opinion left.** Two things did not move an inch, and both are recorded here because the
recurring deviation in this roster is precisely a reader inferring more from this sentence than it says:

- **Its BLOCKING veto on the truth of published claims survives, unchanged in mechanism.** It cannot
  post, so it reaches the PR the way it always has: `quality-assurance` quotes the verdict verbatim
  under criterion 10 (ADR-0006). What changed is **when** it fires — at the merge gate rather than
  inside a drafting round — not whether.
- **Its `content` intake survives**: it still **decides** `ready` alone. ~~applies~~ — corrected on the
  copy lens's advisory, and the word mattered by exactly one step: `agents/product-lead.md` says *"You
  do not apply labels; hand the label to the invoking context"*, and the orchestrator holds label
  application (`CLAUDE.md`). *Decides* is the true claim; *applies* would have had this persona touching
  the tracker, and the brief would have contradicted itself two hundred lines apart.

**The intake half survives on a reason, not on a gap in the owner's words — and the reason is that the
two acts have different OBJECTS.** ~~It is a judgement call, not a reading of the owner's words, and is
recorded as one.~~ **Struck: the copy lens supplied the missing support**, which is what the flag was
asking for rather than a hedge to keep. **Intake judges the ISSUE** — is this worth doing, against what
else, bounded how. **A drafting round judges the PROSE.** The owner's decision removed this persona from
the flow that produces prose; it says nothing about the act that decides whether the Issue should exist,
because that act never enters that flow. Amendment #14 points the same way: this persona's boundary is
the consuming site, which is where `content` ships. If the reading is still wrong, the row in
`/harness-engineering`'s state table is the single place to correct it.

**What is actually lost is WHEN its craft checks run, not WHETHER they run.** Criterion 10 still fires
at the merge gate, so nothing it would have said goes unsaid — it arrives on a **finished draft**
instead of inside a round where acting on it costs a paragraph. That is the whole of the cost, and it is
smaller than "a lens was removed" and larger than "nothing changed".

**Four things `published-voice` does not cover at all, now unread until the merge gate.** They are the
concrete content of the paragraph above and the reason it is a cost rather than an inconvenience:
**cross-surface staleness** (a claim true on one surface and stale on another), **evidence proximity**
(a claim whose support sits too far from it to be found), **the machine/ATS read** (how a piece parses
to something that is not a human), and **durability** (a claim that dates badly).

### A consequence worth naming — corrected, and the correction is the useful part

~~`content-reviewer`'s ruler is the voice and **truth is not on it**. A draft can be perfectly in-voice
and make a false claim, and between the draft and `product-lead`'s veto at the gate there is now nothing
that would catch it.~~

**STRUCK as FALSE against the file this amendment names, on a BLOCKING finding from the copy lens.** It
is struck rather than deleted because the way it was wrong is operational: a `content-reviewer` loads
`published-voice` **and** would have read here that truth is not on its ruler — so it would have declined
a finding its own ruler explicitly authorises. The unsourced claim then goes unraised in round one, where
it costs a sentence, and arrives at the merge gate, where it holds the merge. **That is the cost this
pair was built to remove, reintroduced by a clause about it** — and the second copy sat in
`agents/product-lead.md`, which is preloaded on every dispatch, so the false statement was in the
operative surface and not only in the record.

**What is true.** `published-voice` carries **two** truth rules, both binding and both quotable:

- **A provenance gate on every claim in the draft** — its *sourcing constraint*, the *Practical test*:
  *"if you cannot point to where in the source material … a claim, a number or a stance comes from, it
  does not go in the draft as his."*
- **A truth test on the title** — rule 5: *"the truth test tightens here rather than relaxing … carrying
  that thesis is a **false claim** in the most quoted line of the piece."* The ruler uses those words.

**What it does not carry is EXTERNAL VERIFICATION** — no check against the code, no cross-surface
contradiction check, no durability check, no positioning-rule check.

**The inference this paragraph exists to make survives the correction and gets sharper:** a reviewed
draft has been checked for **sourcing**, never for **correctness against the world**. `product-lead`'s
veto at the merge gate is still the only thing that does the latter, and a reader who takes two clear
rounds as a fact-check has read the wrong guarantee off a real one.

### The rename rode in this slice, and the argument is arithmetic

`writer` → `content-writer` produces **zero** behavioural change and touches ~20 tracked files plus the
generated `powers/` tree, an asserted `agent_type` literal in `permission-guard.test.sh`, and a
roster-membership gate that needs the new name in four documents and the old one struck. **Standalone
that is a slice whose entire content is a sweep.** Riding here, it is free: adding `content-reviewer`
already forces every one of those surfaces open, because the membership assertion requires each of the
seven briefs to name all six peers. Paying the sweep twice buys nothing, and shipping a pair whose two
names do not say they are a pair buys less than nothing.

**The cost, since it is not zero:** `writer` becomes a retired persona in git history, so every line
that enumerates the current roster and still names it is now stale by construction. The membership gate
catches those; a line naming it *alone* is below that gate's threshold and is caught by nothing, which
is why the surviving mentions are struck or tense-marked by hand rather than swept.

### The defect class this slice was most exposed to, and what was done differently

The `-skills` build immediately before this one (#316) copied a **persona brief's** frontmatter shape
(`name:`) onto a **skill**, and the gate caught it only because a new arm was added in the same PR.
**This slice creates two personas from one, which is the same copy at a larger radius.** What was done
differently: the reviewer brief was **written**, not duplicated — no line of `content-writer.md` was
copied into it — and the one thing the two are *supposed* to share, the `skills:` list, is the thing now
gated for **identity** rather than for containment. The asymmetry is deliberate everywhere else: the
round protocol is stated in the reviewer's brief and only its four binding rules in the writer's, so
there is no second copy to drift.

### Costs, named

- **Two more personas to keep coherent.** Every roster change now edits seven briefs, not six, and the
  membership gate makes that mandatory rather than optional. Accepted: mandatory is why it is coherent.
- **Nothing dispatches the pair** (above). Detection at the gate, one turn late, never prevention.
- **The round bound and the terminal literals are prose in two files.** The literals are gated for
  spelling and for a phantom third; **whether a round file was written, whether a finding really quoted
  a clause, and whether the writer was right to drop an advisory finding are gated by nothing** and are
  a reviewer's read. A green on the content-pair arms must not stand in for any of them.
- **A `content` slice is now longer** — draft, review, revise, review — for a class of work whose
  merge-to-deploy path has no preview. The cap is what bounds this, and two rounds was chosen over three
  for exactly that reason.
- **`product-lead` keeps two roles in `content` and loses one**, which is a harder sentence to hold than
  "it left". Accepted as the price of not moving a blocking truth veto that nothing else in the roster
  can hold.

### The `-io` consequence, named and not touched

`tadeumendonca-io` carries a `harness.json` that states this roster; a persona count moving 6 → 7 and a
persona name changing falsifies it. **That repo is out of scope for this MR** and nothing here edits it
— the same treatment amendment #15 gave the `harness-lead` → `agents-lead` rename, for the same reason:
a cross-repo sweep inside a roster change is how one slice becomes two half-finished ones. It is a
follow-up the owner opens, or does not.

**Deciders:** the owner (the decision, and the three verbatim quotes above), written by `agents-lead`
per the domain split (#223) — this is a loop/machinery decision whose mechanical half is a guard rule
and three gate arms. **One half of it is not this persona's:** what `content-reviewer` may raise a
finding *about* is a judgement on published craft, which is `product-lead`'s object. That lens has not
been dispatched on this amendment and should be, on the *craft-opinion-leaves* clause specifically — not
on the round mechanics, which are outside its boundary (amendment #14).


## Amendment (2026-08-25, eighteenth) — a PR link is a summons, and the orchestrator sends one only when the remaining act is the owner's

**The rule, in the owner's own words, and it ships as his sentence rather than as a paraphrase**
([#327](https://github.com/tedeuxx/tadeumendonca-skills/issues/327)):

> *"eu apenas quero receber links de PR quando tiver pronto para merge com todos check concluidos com
> sucesso"*

The condition is **conjunctive**: ready to merge **and** every check complete and successful. A PR whose
pipeline is still running does not qualify however green it looks; a red pipeline is the loop's to fix
without involving him.

**Why the rule exists, and why it only became true recently.** A PR link in his hands reads as *something
is waiting for me*, whatever sentence sits beside it — and that reading is correct in every loop where a
human holds a merge class. This one stopped being such a loop at amendment #16: the gate merges the safe
class **and** the boundary class itself, holding only the four named exceptions. So almost every open PR
is one he has nothing to do with, and the link is an interruption with no act behind it. Four premature
links in one session were four false alarms.

**Mechanically, "ready for him" is one verdict literal, not a hold count.** `agents/quality-assurance.md`'s
*"Your verdict — exactly one of"* enumerates four; exactly one means the remaining act is the owner's:
**`APPROVE-PENDING-HUMAN`**. `REQUEST-CHANGES` is also non-merging and is **not** an owner summons — it
routes to the builder. Naming the literal is checkable; naming *"one of the four holds fired"* is not.

**The rule is phrased about DIRECTING ATTENTION, not about the character sequence, and that is a
measurement rather than a preference.** `gh pr create` prints the PR URL as its own stdout: measured on
#327 against a real transcript, `tool_result` blocks carry the **identical five PR URLs at identical
counts** as the assistant's prose blocks. A rule written against the string would forbid nothing — every
PR the loop opens surfaces its own URL regardless — and would fail open exactly where it looked
strictest. A URL the owner watched a tool emit is not a summons; one the orchestrator hands him is.

### The enforcement, and the premise it corrects

**The Issue's own central premise was false, and it is corrected here rather than carried forward.** It
proposed recording this as a third unenforced orchestrator duty, on the reasoning that *"the
orchestrator's user-facing text is not a tool call; no `PreToolUse` matcher sees it, no hook can read
it."* The first clause is true and the second does not follow. Measured by `agents-lead` at intake, on
Claude Code `2.1.245`: a `Stop` hook receives `transcript_path`; assistant `text` blocks sit in that file
alongside the `tool_use` blocks `orchestrator-tool-census.sh` already reads; a live headless probe
confirmed the turn's **final** text block is flushed by the time `Stop` fires; a real human turn is
distinguishable from a tool return by the shape of `.message.content`; and the turn-scoped extraction
costs **0.41 s** on the largest transcript on the machine (65 MB). **A control recorded as impossible is
harder to revisit than one recorded as unbuilt**, because nobody re-measures an impossibility.

`agents-lead`'s recommendation was *written now, detector deferred, trigger named*. **The owner overruled
it**, in the same answer: *"esse o comportamento que quero que vc faca enforcement no harness config"*.
So the detector ships with the rule.

**What it is: `hooks/scripts/premature-pr-link-detect.sh`, a `Stop` hook.** It reads the turn's own
assistant prose, extracts full PR URLs, and for each one asks three mechanical questions — is the PR
open, has every check on its current head completed and succeeded, and is the gate's verdict at that head
`APPROVE-PENDING-HUMAN`. Anything else is flagged with the reason. It keys on the URL's **own** PR number
and passes `--repo` explicitly, rather than on `git branch --show-current` as `zombie-loop-detect.sh`
does: a report naming one PR while checked out on another's branch would otherwise check the wrong PR.

**It is detection, never prevention, in the same terms `zombie-loop-detect.sh` uses.** It fires after the
text has already reached him. It cannot un-send a link; it makes the mistake visible one turn late
instead of one session late. Every exit path is `exit 0`, `additionalContext` is the only mechanism, no
`decision` field is ever emitted.

**The hole is in the form the rule recommends, and it is written into the script header rather than left
to be assumed away.** GitHub shares **one number space** between Issues and PRs, so a bare `#508` cannot
be classified without a network call — and the bare number is exactly the substitute this rule tells the
orchestrator to prefer. The hook matches full URLs only. **It polices the form the rule discourages and
is blind to the form it endorses.** Not closable at this layer; widening it to `tool_result` blocks would
fire on every legitimate `gh pr create` and is not a fix either.

### The coupling this rule creates, recorded because the owner took the trade knowingly

**Amendment #16 above already books, in its own *Bad / accepted costs*, that *"the owner reviews live,
after deploy" has no artifact*** — nothing records that he looked, and nothing surfaces to him that
something boundary shipped. It names the trigger for building one: *"If a boundary change is found to
have shipped and gone unreviewed, that is the trigger to build it."*

**The premature PR link was the informal substitute for that artifact.** Crude, and it interrupted him
for things he could not act on — but it was the only way he learned something had shipped. **This rule
removes it with nothing put in its place**, which makes that named residual bite, and it bites on
published copy in his voice: the exact failure `tadeumendonca-io#479` already cost once and which
amendment #16 records as its accepted price.

**He was asked and scoped the replacement out.** The question put to him was *slice 1, or slice 1 plus
the boundary-merge notification in the same slice*; he answered by restating the rule and asking for
nothing else. So the notification — a `SessionStart` arm reading merged PRs carrying
`APPROVE-AND-MERGE-BOUNDARY` — is **not built here, and is not deferred for lack of a design**. It is
declined for now, on his call, with the cost stated. **This is written in these terms so that when it
bites, nobody reconstructs it as an oversight.**

### The rejected options

- **Record it as a third unenforced orchestrator duty**, beside label application and the
  dispatch-omission judgment call (record 0013's *"Not enforced, and not claimed to be"*). Rejected on
  the measurement above: those two are genuinely unobservable and this one is not, so filing it with
  them would have published a false impossibility into the document a future context reasons from.
- **A `PreToolUse` deny on any command containing a PR URL.** Rejected mechanically: the orchestrator's
  user-facing prose is not a tool call, so no `PreToolUse` matcher sees the act at all — and the calls it
  *would* see are `gh pr create`, which must not be blocked.
- **Put the operative wording in `skills/harness-engineering/SKILL.md`**, the universal preload.
  Rejected as an **anti-placement**: `skills:` is `agents/*.md` frontmatter, and the actor this rule
  governs is the orchestrator, which is not a persona and has no frontmatter. It would be always-on for
  seven personas that never report to the owner and not always-on for the one actor that does.
- **State it in `README.md` and here only.** Right home for the argument, wrong home for the wording:
  neither file is loaded at runtime by anything.

### Consequences

**Good**
- The rule is exported, reviewable and adoptable, which was the whole of the complaint.
- Its enforcement is a gate rather than a habit, and its two holes are written down where a future
  reader meets them before assuming coverage.

**Bad / accepted costs**
- **The boundary-merge notification is still absent, and this rule is what makes its absence expensive.**
  Stated above at length; it is the highest-cost consequence of this amendment.
- **Detection is one turn late, always.** No layer can prevent text that has already been emitted.
- **The recommended form is unenforceable.** A bare `#NNN` is unclassifiable, so the discipline the rule
  most wants is the one nothing checks.
- **A third independent reader of the `gatekeeper-verdict` marker.** `session-wip.sh`,
  `zombie-loop-detect.sh` and now this one read the same artifact with the same extraction. Drift between
  three readers is caught by a reviewer diffing three test files, not by any gate — the same trade
  `zombie-loop-detect.sh`'s header already argued for, extended by one.
- **`/autonomy-on` covers autonomy runs, and the defect can occur in any session.** Accepted rather than
  duplicating the wording, which is what this document's own *`README.md` is the single source of truth
  for the dev-loop narrative (absorbed 2026-08-20, record 0019)* section forbids — *two documents
  claiming the same authority at similar depth is worse than one document at full depth*. If it recurs
  outside autonomy mode the fix is a pointer line, not a second home.
- **The orchestrator's private memory entry `feedback-show-pr-links-not-commands` instructs *showing* PR
  links.** It is outside every repo and cannot be edited from inside one, so the narrowing it needs is
  reported to the owner with the exact wording rather than performed. Until he makes it, the exported
  rule and the unexported one disagree in the one place nobody can diff.

**Deciders:** the owner (the rule, verbatim, and the instruction to enforce it), written by `agents-lead`
per the domain split (#223) — this is a loop/machinery decision whose mechanical half is a hook and a
gated suite. **One half of it is not this persona's:** the cost of removing the informal ship-notice is
paid on published content in the owner's voice, which is `product-lead`'s object. That lens has not been
dispatched on this amendment and should be, on the residual specifically — not on the hook mechanics,
which are outside its boundary (amendment #14).


## Consequences
**Good**
- Context efficiency and authorship-bias elimination fall out of per-task isolation.
- Reusable across projects; the roster models a whole engineering org.
- The copy gets a reviewer with a mandate, instead of relying on the code reviewer noticing.

**Bad / accepted costs**
- Orchestration overhead and token cost — spawn a specialist only when a slice genuinely spans its domain.
- Same-model review has a ceiling: a fresh context removes *authorship* bias, not *model* bias — ~~which is
  why the boundary class still escalates to a human (ADR-0004).~~ **Struck 2026-08-23 (amendment #16):
  the boundary class no longer escalates, so this cost is no longer mitigated by that route.** The
  ceiling is unchanged and is now paid rather than deflected: on every class except the four surviving
  holds, the only reader between a change and production is a fresh context of the same model. That is
  the price the amendment's own counter-argument section states, seen from this list.

## Issue type is the routing axis, and it is exclusive (absorbed 2026-08-20, record 0012)

**Disposition 4 of [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md):
record 0012's decision is still in force and is moving into the document that governs the capability it
belongs to.** Decided by the owner on 2026-08-12, driven by
[#184](https://github.com/tedeuxx/tadeumendonca-skills/issues/184) — his own statement that *"temos
issues de 3 tipos, cada um deles é roteado para família de agentes diferente"*. Written by `tech-lead`,
with an `agents-lead` pre-implementation stress test of eight scenarios behind it. Its History row is in
[the index](./README.md).

### The decision, as it currently binds (record 0012)

**An Issue has exactly one type, and the type is the ROUTING axis: `product` · `content` · `loop`.** The
type decides which profiles take part at intake, who builds, and whether a gate runs at all. It is *not*
the granularity axis — story/task/proposal is a different question, and the mechanism side of it is
decided in *A task is an Issue child, not a checkbox (absorbed 2026-08-20, record 0014)* below.

Three corollaries are part of the decision rather than consequences of it, because the routing axis is
not real without them.

**Corollary 1 (record 0012) — the `/autonomy-on` queue predicate is `(product OR loop) AND ready`.**
The predicate was `product` only. Measured at the time against this repo's own backlog, 12 of 13 open
Issues carried `product` and every one of them was harness/loop-class work, so making `loop` real and
exclusive without widening the predicate would have **silently emptied the drainer in the one repo whose
purpose is the loop** — reporting "0 issues" rather than erroring, which is worse than a crash because
nothing signals the miss.

**Corollary 2 (record 0012) — the three types are exclusive: one Issue, one type.** `commands/new-issue.md`'s
label step is a single choice, not "apply either or both". Dual-labelled Issues in `tadeumendonca-io`
are a migration, not a state to preserve.

**Corollary 3 (record 0012) — `content` gets a mechanical builder.** Once type is exclusive, a pure-`content`
Issue can no longer ride `product`'s build path. Measured: **2 of 13** pure-`content` Issues in `-io` had
ever closed, against **6 of 8** dual-labelled ones — 15% against 75%. The owner overrode
[#161](https://github.com/tedeuxx/tadeumendonca-skills/issues/161)'s own *"measure before adding a
persona"* precondition and created `writer` ([#187](https://github.com/tedeuxx/tadeumendonca-skills/issues/187)),
recorded as an override rather than smoothed over. The persona's own design is #187's, and its addition
to the roster is amendment #13 of this document.

**Why `loop` passes the test `type:*` failed.** This repo retired `type:*`/`phase:*`/`priority:*`/`semver:*`
on a stated rule — *something must QUERY a label* — and `loop` satisfies it **because of Corollary 1**:
`(product OR loop) AND ready` is a real query against a real label. That is what makes `loop` different
from vocabulary added by fiat, and it is the sentence to check first if anyone proposes a sixth label.

### The rejected options that are still live (record 0012)

- **Type as the GRANULARITY axis — story / task / proposal.** *Deferred, not rejected on merits.* It is
  the natural reading of "type" in most trackers, and it answers a different question than the one this
  tree already had half-built in prose. Adopting it as *the* type axis would have left the existing
  `product`/`content`/`loop` routing either undocumented or double-encoded under another name. It remains
  available as a second, orthogonal axis; nothing here forecloses it.
- **Non-exclusive co-application** — the incumbent, and the reason exclusivity had to be decided rather
  than assumed: the label table already implied the label decides merge class, while the gate in fact
  decides class from what the diff touches. Exclusivity narrows the leak; it does not close it.

### Consequences still being paid (record 0012)

- **Relabeling is ungated for every persona.** `Bash(gh issue edit:*)` and `Bash(gh label:*)` sit in the
  committed `allow`, unscoped to `agent_type`, and neither guard script keys on either command. Under this
  decision **any subagent can move an Issue into the `loop` lane with one command** — a lane that reaches
  the owner directly. Left an **open question**, not a silently accepted cost, because closing it is a
  *which layer can carry this control* question and belongs to
  [ADR-0004](./0004-controls-and-enforcement.md), not to a routing record. Reaffirmed twice since, in the
  two sections below.
- **The exclusivity migration in `tadeumendonca-io` has no owner named.** The rule is stated; no
  individual Issue is decided by it.
- **Corollary 3 is an explicit override of a precondition the loop itself set.** #161 stays open as the
  calibration Issue rather than being closed by #187 shipping.

## The orchestrator is a named role, not a persona (absorbed 2026-08-20, record 0013)

**Disposition 4 of [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md):
record 0013's decision is still in force and is moving into the document that governs the capability it
belongs to.** Decided by the owner on 2026-08-12, written by `tech-lead`, driven by an `agents-lead`
pre-implementation stress test of six scenarios; no Issue — a methodology-library decision filed and
closed at tier 1. Its History row is in [the index](./README.md).

### The decision, as it currently binds (record 0013)

**"Orchestrator" is the one term for the actor that talks to the owner and dispatches every subagent.**
It is explicitly **not** an `agents/*.md` persona: it is not dispatchable, it is the dispatcher, no `Task`
invocation ever targets it, and it satisfies none of the four reasons a persona exists (amendment #10 of
this document). The term converges five live spellings — `orchestrator`, `main session`, `main loop`,
`main agent`, `invoking context` — for **new** writing only; nothing in the tree was renamed.

**Duties, named together:**

- Dispatches every persona; no persona talks to another persona directly.
- Commits and pushes on the loop's behalf.
- Applies the `ready` label that makes an Issue executable, once the intake leads have closed its
  description.
- Applies the routing label (`product`/`content`/`loop`) decided in *Issue type is the routing axis, and
  it is exclusive (absorbed 2026-08-20, record 0012)* above.
- Decides, in the moment, whether a given review specialist needs dispatching at all — a real judgment
  call, exercised at least once against a trigger that had already fired.

**The boundary, in two honest parts rather than one:**

- **Mechanically enforced, for ~~exactly two acts~~ THREE acts — merge, direct push to the trunk, and
  (since #319, 2026-08-23) editing a file inside a git working tree.**
  `hooks/scripts/permission-guard.sh` leaves `agent_type` **empty** for the main agent by design, and
  rules 7 (trunk push) and 7b (merge) fire against that empty value. The third act is enforced by a
  different hook on a different matcher — `hooks/scripts/orchestrator-write-guard.sh`, registered on
  `Edit|Write|MultiEdit|NotebookEdit` — because `permission-guard.sh` runs on the `Bash` matcher and
  returns immediately on a payload with no `.tool_input.command`. It is a **routing** rule rather than
  a floor one: the identical edit is allowed the moment a persona makes it, and every non-empty
  `agent_type` passes through untouched. See
  [ADR-0004](./0004-controls-and-enforcement.md)'s 2026-08-23 amendment for the decision, the
  measurement that a matcher is anchored, and the `Bash`-side residual it leaves open. Asserted in
  `permission-guard.test.sh` under the case name `"main agent (no agent_type) cannot merge"` and again
  under `"THE SAME THREE FOR THE MAIN AGENT"`, the latter added 2026-08-03 specifically to cover the
  orchestrator alongside `developer`. This **corrects a suspicion the driving dispatch carried**: the
  guard is not blind to the orchestrator for irreversible acts.
- **Not enforced, and not claimed to be.** Two named instances: **label application**, which is the
  ungated-relabeling gap the record above already books; and **the dispatch-omission judgment call**,
  which is a different failure shape than *"decides the irreversible"* — an omission nobody can see
  happened or didn't, not a decision on an irreversible act. Recording the gap beside the duty is the
  discipline [ADR-0004](./0004-controls-and-enforcement.md) established for a control claimed stronger
  than it is.

**Naming safety, verified rather than assumed:** `inventory-counts.test.sh` asserts none of the five
terms as literal strings, and `permission-guard.test.sh` uses *"main agent"* only inside human-readable
test descriptions — its assertions key on the empty `agent_type` value, never on the term. Converging on
"orchestrator" breaks no assertion in either suite. **Not** checked against every `.md` file in the tree;
that residual is named, not certified closed.

### The rejected options that are still live (record 0013)

- **A full `agents/*.md` persona brief, as a roster member.** Every persona in `agents/` is a dispatch
  target with its own context window and `tools:` scoping. The orchestrator is dispatched by nobody, needs
  no fresh context from itself, and a brief nobody dispatches is read by nobody — so it would not even
  solve the naming drift it was proposed for.
- **Leaving it undefined.** Status quo is not neutral: it is *keep the decorative definition and the
  five-way drift*, in which every new file picks a spelling ad hoc.

### Consequences still being paid (record 0013)

- **Nothing in the existing tree was renamed.** The four other spellings remain live in
  `permission-guard.sh`, its test suite and several `agents/*.md` files. A sweep is its own slice.
- **The label-scoping gap is named, not closed.** Anyone reading this section as *"the orchestrator is now
  the exclusive, gated actor for `ready`/routing labels"* is reading a claim it explicitly does not make.
- ~~**The dispatch-omission blind spot has no gate.** Naming it did not make it detectable; an
  undispatched lens still looks identical to a clean run.~~ **Struck 2026-08-20 (#294) — narrower now,
  not closed.** #294's own incident was not omission: the orchestrator narrated a dispatch ("Vou
  despachar o `harness-lead`...") in its user-facing turn and ended the turn without making the `Task`
  call. Nothing recorded the difference — no hook, no comment, no error — until the owner noticed the
  loop had stalled. That is a **worse** failure than silent omission, because it defeats the one
  mitigation this loop actually relied on (the human reading the turn) by telling them the thing is
  underway.

  **What changed:** `hooks/scripts/zombie-loop-detect.sh`, a `Stop` hook, reads the same fact
  `session-wip.sh` already computed at `SessionStart` — whether the current branch's open PR carries a
  `gatekeeper-verdict` comment reading `REQUEST-CHANGES` or `APPROVE-PENDING-HUMAN` on its current head
  — but at the end of **every turn** rather than only at session start. `Stop` is the only event whose
  trigger is "a turn ended", which is the failure's own boundary; `PreToolUse` and `SubagentStart`/
  `SubagentStop` were eliminated mechanically, since each fires only in the case that is NOT the
  failure (a tool call or a dispatch that never happened leaves nothing for any of them to see —
  confirmed 2026-08-20 against the primary hooks documentation: `SubagentStart` is informational-only
  and cannot deny a dispatch; `SubagentStop` fires only after one already ran).

  **What is still true, and is the reason this is struck rather than deleted.** This is detection, one
  turn late instead of one session late — not prevention, and no layer in this architecture can prevent
  a tool call that is never made. It never parses prose: it cannot tell "narrated but not attempted"
  from "attempted and errored", only that loop state (a closed literal enumeration the gate's own
  persona defines) says something is outstanding. **The blind spot narrows, it does not close**: still
  uncaught are narration with no loop-state footprint at all ("I'll update the README" and then not
  doing it), anything during intake before a PR exists, and a narrated dispatch of a lens denied `gh pr
  comment` by `permission-guard.sh` rule 5e (`product-lead`) — its absence stays unobservable by
  construction. Full design record, mutation-checked debounce and cost-bounding: `hooks/scripts/
  zombie-loop-detect.sh`'s own header, and `README.md`'s hooks section.

## A task is an Issue child, not a checkbox (absorbed 2026-08-20, record 0014)

**Disposition 4 of [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md):
record 0014's decision is still in force and is moving into the document that governs the capability it
belongs to.** Decided by the owner on 2026-08-12, written by `tech-lead`, driven by an `agents-lead`
pre-implementation stress test of five scenarios; no Issue — a methodology-library decision filed and
closed at tier 1. Its History row is in [the index](./README.md).

### The decision, as it currently binds (record 0014)

**A task is an Issue CHILD — its own Issue, its own branch, its own PR, with `Parent: #N` in the body.**
It is not a checkbox on the story. This resolved a live contradiction rather than designing something
new: `agents/developer.md`'s task-filing rule already read as though a task were a real Issue with its
own MR, while `wip-guard.sh`'s own struck prose had measured the checkbox model as the one that actually
ran — **not one task branch across roughly ninety**.

**A task inherits the parent story's routing type and readiness, and carries no label of its own.** A
task is a decomposition of already-routed, already-ratified work, not a new intake decision; an
independent type would let one story's work scatter across routing lanes mid-execution, and an
independent `ready` would make the leads re-close an already-closed description once per task. This is a
judgement call, recorded as the owner's ruling and open to revisiting if a task-heavy workflow shows the
inherited model does not scale.

**It ships restrictive: the sibling-file exemption is NOT rebuilt.** `wip-guard.sh`'s surviving overlap
rule denies a new PR touching a file an open PR by the same author already touches, with no
story/parent carve-out in executable code. Two sibling tasks under one story that would touch the same
file are **blocked** until a later slice rebuilds the exemption. The reasoning is that the retired
two-level implementation carried four separate defects, so a temporarily-restrictive guard fails **safe**
— denying legitimate work loudly at the `gh pr create` call — rather than failing open and silently
reintroducing a bug class already caught four times. **The one non-negotiable for whoever rebuilds it:**
the test fixture must be a **mixed open set carrying a fieldless entry first**, since that is the shape
the fourth historical defect could not be caught by.

### The rejected options that are still live (record 0014)

- **Task remains a checkbox on the story Issue** — the incumbent. The zero-in-ninety measurement is
  **evidence of absence-of-instruction, not evidence the model fails once instructed**, and that reading
  is the more defensible one; the record picked it rather than staying neutral. The checkbox is rejected
  anyway on an independent driver: it has no MR, so the brief and the Definition of Done already in force
  cannot describe it, and rewriting them backward throws away the review granularity a task-level gate
  buys.
- **Reinstating hook-side `Parent: #N` verification.** The retired mechanism records four
  correct-in-sequence fixes and was deleted afterward anyway — not because the fixes were wrong but
  because **intent is not recoverable from a command string**. A fabricated `Parent: #187` is exactly as
  unverifiable by grep as a fabricated checkbox reference was, so a real parent Issue does not reopen the
  question. The cheap alternative that *does* work is a reviewer running `gh issue view <parent> --json
  labels` itself.

### Consequences still being paid (record 0014)

- **Sibling tasks touching the same file are blocked** until the exemption is rebuilt — a real capability
  loss, named rather than hidden.
- **No task-level label means a task cannot be independently paused or re-scoped** without touching the
  parent. If that matters in practice it is a reason to revisit the inheritance ruling, not a defect.
- **`quality-assurance` has no sibling-PR awareness.** Once two sibling task PRs land, the second's diff
  can read as unexplained drift with nothing in the gate's brief telling it to look for a sibling first.
- **Every task is now a full slice with its own review overhead** — a heavier mechanism than a checkbox,
  chosen because the checkbox model measurably never got used, not because it is cheaper.

## `agents-lead` implements the harness it reviews (absorbed 2026-08-20, record 0015)

**Disposition 4 of [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md):
record 0015's decision is still in force and is moving into the document that governs the capability it
belongs to.** Decided by the owner on 2026-08-12, written by `tech-lead`, with an `agents-lead`
pre-implementation stress test **of this proposal about itself** (six findings, F1–F6). It reverses
amendment #10's *"advisory, pre-implementation"* framing — struck in place there as amendment #11, not
rewritten. Its History row is in [the index](./README.md).

### The decision, as it currently binds (record 0015)

**`agents-lead` holds unscoped `Write, Edit` — the exact set `tech-lead` already carries — mitigated
purely by "cannot merge".** No new hook, no path-scoped deny. Six corollaries are part of the decision
because the capability is not safe without them.

**Corollary 1 (record 0015) — the capability shape, and nothing new in the hook layer.** Rule 7b denies
`gh pr merge` to every `agent_type` but `quality-assurance`, and rule 5d denies `gh issue create` to
every subagent but `developer`; `agents-lead` is caught by both catch-alls before and after the grant,
so **neither rule changed**. No new `PreToolUse` matcher is needed, and `tech-lead`'s own unscoped grant
is the proof: `hooks/hooks.json` registers `PreToolUse` on the `Bash` matcher only, so `Edit` and `Write`
are invisible to the hook layer for **every** persona that holds them.

**Corollary 2 (record 0015) — the harness-diff criterion.** `quality-assurance`'s boundary-class list
gains: *a diff touching `hooks/**`, `agents/**`, `skills/**`, `commands/**` or `.claude/**` requires a
`agents-lead` verdict marker present on the PR before it may classify as safe or merge; absent that
marker the diff is boundary class regardless of what else it does.* This closes a gap that existed
independently of the grant — before it, nothing stopped a harness change merging with zero `agents-lead`
involvement.

**Corollary 3 (record 0015) — the durable verdict.** `agents-lead`'s output becomes an
`<!-- harness-lead-verdict: … -->` comment following [ADR-0006](./0006-verification-and-its-artifacts.md)'s
shape, referenced against **a commit SHA of the repo state reviewed** rather than a PR head SHA, because
a harness scenario is frequently reviewed before any PR exists. `agents-lead` is deliberately **not**
denied `gh pr comment`: rule 5e's argument is the irreversibility of paraphrasing PRIVATE material
(`.brand/`) into a public comment, and this persona's object is machinery already published in this repo.
What has never been drawn is the **other** direction — what it should not be allowed to post — and none is
proposed, because no private-material class in its domain is known to exist and inventing one to close a
hypothetical gap is the shape this persona is itself instructed to distrust.

**Corollary 4 (record 0015) — `loop`-typed `ready` is an OWNER-ONLY transition**, never applied by any
dispatch including `agents-lead`'s own. This is what converts *"separate Issue for proposal versus
build"* from a convention into an actual gate: a proposal dispatch may file findings, but nothing lets
the same or a later dispatch move that Issue to `ready` and start building without the owner having read
the artifact. `product`-typed `ready` is unchanged — the two leads, per the routing record above.

**Corollary 5 (record 0015) — harness proposals enter the tracker as real Issues**, `loop`-typed and
carrying the verdict marker. This is forced by Corollary 4, not an independent decision: an owner-only
`ready` gate has nothing to attach to without an Issue to hold the label. **Who files is unchanged** —
`agents-lead` stays denied `gh issue create`, so the orchestrator files it, asked, per *Review does not
open work*. Nothing about *only the owner opens work* is loosened.

**Corollary 6 (record 0015) — the two execution-defect bugs travel with the grant.** The brief instructed
using a `Write` tool its own frontmatter did not grant, and its working-files section was silent about
the same gap. Both are fixed in the same commit as the `tools:` line, because there is no intermediate
state in which the bug exists and the grant does not.

### The rejected options that are still live (record 0015)

- **A path-scoped `Edit`/`Write` deny for what `agents-lead` may not touch.** *Already measured not to
  hold*: `security` discovered that `Edit(.claude/**)` does not hold **by editing that file while
  believing it was blocked**. Re-verified independently — `PreToolUse` fires on the `Bash` matcher only,
  so a path-scoped deny on `Edit(...)` has no enforcement layer to sit in even in principle. Proposing it
  again would be proposing a control this repo has already spent a review round proving inert.
- **Advisory only, forever.** Beyond the owner's reversal, the structural argument is amendment #10's own
  cost: *nothing enforces a dispatch, and an undispatched lens is indistinguishable from a clean one.*
  Advisory-only findings already failed silently with no artifact behind them; an implementer at least
  produces a PR the gate reviews.
- **Routing `loop` to `agents-lead` alone for both proposing and building in one dispatch** — named in
  the routing record above so it is not silently reintroduced. The owner's mitigation is that proposal and
  build ship as **separate dispatches under separate Issues**, which Corollary 4 is the mechanism for.

### Consequences still being paid (record 0015)

- **`agents-lead` reviews and builds the same object.** This is the identical *"nobody observes the gate
  that signs the merge"* shape `quality-assurance` accepted when `security` merged into it (amendment #10,
  Decision 2). Mitigated the same way — it cannot merge — not by a second internal reviewer. A real
  reduction in independence, traded against the advisory-only model's own failure.
- **`loop`-ready is owner-only BY INSTRUCTION, not by floor enforcement.** Corollary 4's gate is exactly
  as strong as the owner's habit of reading the artifact first — the same caveat this document already
  carries for relabeling generally. Left open rather than pretended closed.
- **A second persona now holds an unscoped `Write, Edit` grant mitigated purely by "cannot merge."** The
  mitigation is now load-bearing for two personas instead of one, so a future defect in rule 7b's
  catch-all would compromise both at once.

## `README.md` is the single source of truth for the dev-loop narrative (absorbed 2026-08-20, record 0019)

**Disposition 4 of [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md):
record 0019's decision is still in force and is moving into the document that governs the capability it
belongs to.** Decided by the owner on 2026-08-14, written by `agents-lead`, driven by
[#261](https://github.com/tedeuxx/tadeumendonca-skills/issues/261). Its History row is in
[the index](./README.md).

### The decision, as it currently binds (record 0019)

**`README.md` is the single canonical source for the dev-loop's narrative description, and
`docs/dev-loop-design.md` is a pointer stub at its existing path.** This record **amends this document's
own** *"where the design now lives, harness-agnostically"* note, added in amendment #7, which had named
`docs/dev-loop-design.md` as that home. The pointer target is what changed; nothing else amendment #7
decided is touched.

The README absorbed what the design doc carried at greater depth and the README did not — the Definition
of Done at issue-requirement grain, the intake-formalism argument (why the gate's ruler must be external,
the two-round budget, parallel-not-serial dispatch), and a *what travels if this design moves to another
harness* section carrying the essential/incidental/known-weak split. Content that was merely redundant —
the roster narrative, the branch diagrams — was **not** duplicated a second time, either because the
README's version was already more current or because a better-homed file already carried it.

**The rule underneath, which is the reusable half:** two documents claiming the same authority at similar
depth is worse than one document at full depth. A reader has no rule for which is current, and nothing
forces them to be edited together, so they will drift.

### The rejected options that are still live (record 0019)

- **Keep the design doc canonical and thin the README** — #261's own original framing, reversed by the
  owner mid-session. A thin README defers dense content to a second document, which is the two-sources
  problem with the authority assignment flipped rather than resolved.
- **`git rm` the design doc outright.** Its canonical URL is quoted in its own header as the citable
  target for import into another harness. A 404 where a redirect could stand costs a reader nothing to
  avoid. ~~And this repo's supersede-never-delete convention already answers the question.~~ **That
  second clause was struck 2026-08-15**: the convention was replaced by
  [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md). The rejection stands
  on the surviving reason, which was always the load-bearing one — **and ADR-0020 does not reach this
  file anyway**, being scoped to ADR records, which a redirect stub is not.

### Consequences still being paid (record 0019)

- **The README is the longest document in the repo by a wide margin**, and a reader wanting only "how do I
  install this plugin" has more to scroll past.
- **The portable framing is now one hop from the content.** A machine or reader following the raw
  canonical URL gets a redirect notice, not the design — worse than the URL resolving directly, accepted
  because `git rm` is worse still.

## What this fold dropped

Per [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md), absorption is
**lossy by instruction**: what arrives is the decision as it currently binds, the rejected options still
live, and the consequences still being paid. Dropped from the five records above, deliberately:

- **Every *"consequent work, out of scope here"* item that has since been discharged.** All five records
  were written under a `docs/adr/**`-only write scope and each named edits it could not make — the
  `/autonomy-on` predicate, `new-issue.md`'s label step, `quality-assurance`'s boundary-class criterion,
  `agents-lead`'s frontmatter and its two brief bugs, `dev-loop/SKILL.md`'s tracker rule, the README's
  checkbox sentence. Those edits landed. A list of obligations that were met is archaeology; the ones that
  are **not** met survive above as consequences.
- **The five-spelling census in record 0013** — the file-and-line inventory of `orchestrator` / `main
  session` / `main loop` / `main agent` / `invoking context`. The decision it produced is above; the
  inventory was a snapshot of a tree that has moved twice since.
- **Record 0012's 2026-08-13 amendment** — the retired-label archaeology (34 Issues, 29 unlabelled, 11 of
  15 labels never applied to anything, and the correction of an earlier figure that mixed an Issue-only
  population with a PR-inclusive one). The rule it earned — *something must QUERY a label* — is stated
  above; the census of a vocabulary that no longer exists is not.
- **Record 0014's four-defect narrative of the retired `wip-guard.sh` two-level rule**, in detail. What
  binds is kept: the exemption is not rebuilt, and the fixture shape any rebuild must use.
- **Record 0015's F1–F6 finding-by-finding attribution**, and the line locators every record used
  (`agents/quality-assurance.md:714-718`, `permission-guard.sh:135,136`, and roughly forty more).
  `documentation-standard`'s *cite the clause, not the line* rule postdates all five, and carrying dead
  locators forward would import a citation form this library has since ruled against.
- **Each record's own `Considered options` restatement of the chosen option as option 1**, and each
  record's `Links` list, whose live members are folded into this document's cross-references.

## Links
- Driven by record 0001 (ADRs are the brain this depends on), now
  [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md) · the DoD is
  [ADR-0006](./0006-verification-and-its-artifacts.md)'s *Merge Request Definition of
  Done* section, absorbed there from record 0003 on 2026-08-19 · autonomy/tool-scoping is
  ADR-0004 · full design in `docs/proposals/agentic-dev-loop.md`.
