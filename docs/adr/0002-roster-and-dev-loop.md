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
  raised does not arise here) · **amended 2026-07-23** (twice — the product/decision-support layer joins the roster) · **amended 2026-07-24** (amendment #3 — the roster reshapes: `product-owner` re-scoped, `brand-guardian`/`editor`/`recruiter`/`scrum-master` join; owner-ratified, implementation sequenced in follow-on slices per issue #69) · **amended 2026-07-29** (amendment #4 — the `brand-guardian` trigger becomes a fail-closed rule instead of a path list; `-io`#202) · **amended 2026-07-30** (amendment #5 — `product-manager` gets a trigger, discharging #68's debt for it; the reviewer's output gets a round budget) · **amended 2026-08-01** (amendment #6 — a finding blocks only by naming a criterion and a falsifier; the DoD grows criterion 10; the lenses self-classify severity; the round budget drops to two) · **amended 2026-08-02** (amendment #7 — the roster drops 19 → 6 on a new criterion: a persona exists only where conflict is wanted; three leads, one fullstack builder, two gatekeepers) · **amended 2026-08-02** (amendment #8 — the intake chain: nothing worked outside the tracker, the three leads close the issue's description, and those requirements become the gate's external ruler; both gatekeepers approve every MR in parallel; the builder delivers the E2E suite) · **amended 2026-08-04** (amendment #9 — `marketing-lead` merges into `product-lead`; the roster drops 6 → 5; the blocking-truth clause is carried across explicitly, and the capability floor that backed it is not) · **amended 2026-08-04** (amendment #10 — `agents-lead` joins tier 1 as the owner's pair on the machinery, advisory and pre-implementation; `security` is **absorbed** into `quality-assurance`, which now holds two lenses in one pass and labels every finding with its lens. The roster is still **five** and **two of its members changed**. The persona criterion widens from *conflict wanted* to **four reasons**, with reconciliation cost paid **within** a tier. Amendment #9's *"both approvals are still required"* is **struck**. Books the rule that produced the gap: **a count is not an identity**) · **amended 2026-08-13** (amendment #13 — `writer` joins tier 2 as a content-scoped second builder; the roster grows 5 → 6; it satisfies none of the four reasons and is named plainly as an owner override; `permission-guard.sh` rule 5e inverted from a denylist to an allowlist to contain it; the `Write`/`Edit` observability gap is accepted in writing rather than closed mechanically) · **amended 2026-08-21** (amendment #14 — `product-lead`'s boundary is `tadeumendonca-io`; consolidates #295/#296/#297: inside `-skills` it may BLOCK on a false published claim and RECOMMEND, advisory-only, on communication, but may not comment on `-skills`'s functioning; `loop`-typed non-dispatch (#295) is a corollary of this rule, not a parallel clause; the labelling discipline (#296) generalises to every advisory finding, not only `loop`-typed ones; enforcement is prose-only, ~~confirmed against Claude Code's own hooks documentation — no hook layer can observe or refuse a `Task` dispatch~~ **— that clause is STRUCK 2026-08-28 (#344): a `PreToolUse` hook on matcher `Agent` both observes and denies a dispatch, and `hooks/scripts/dispatch-premise-guard.sh` has done so since #326. What survives is narrower and still true: nothing mechanical enforces a dispatch's SCOPE. See this record's *"Correction (2026-08-28, #344) — the dispatch layer is observable and refusable, and the retraction never reached this record's own status line"* heading, inside the fourteenth amendment**) · **amended 2026-08-23** (amendment #16 — the gate merges the boundary class, `content` included, under its own verdict literal `APPROVE-AND-MERGE-BOUNDARY`; the owner reviews live, after deploy. The argument is the loop model: under `trunk-single-env` there is no preview to hold for, so the hold bought a queue rather than an environment. The counter-argument is recorded rather than omitted — `tadeumendonca-io#479`, an article that reached production unreviewed after the gate had correctly refused to merge it. **Four holds survive**, none of them on the preview argument: an expansion of the gate's own authority, a harness diff with no `agents-lead` marker, anything in `iac/`, and a lens `ESCALATE`. Two of those were carried implicitly by the phrase *boundary class* and would have stopped working silently. `permission-guard.sh` rule 7c accepts two merge-authorising literals, spelled out rather than globbed; `session-wip.sh` learns the second; the verdict vocabulary is gated against the persona file for the first time. **This list omits amendments #11, #12 and #15** — a pre-existing gap found while numbering this one and deliberately not backfilled here, since a numbering slice is not a boundary-merge slice; all three are present in the record body)
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

**The 2026-08-13 WIP=1 correction** (see `agents-configuration`'s own section on it) **supersedes the
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
never dispatched to `content` work, since `/autonomy on`'s queue was `product`+`ready` only. That is a
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
decision to dispatch it. ~~`hooks/hooks.json` registers `PreToolUse` on the `Bash` matcher only, so no
hook observes a `Task` dispatch at all. **There is no wider registration that would close this** — it is
not a configuration gap, it is the documented ceiling of the mechanism.~~

**STRUCK 2026-08-26 (#326) — the second sentence was false, and it is struck rather than deleted
because a reader took a design conclusion from it: it is the sentence that argued the ceiling belonged
to the mechanism rather than to this repo's configuration.** It was true of the `SubagentStart` /
`SubagentStop` pair it was reasoning about, and the reasoning above it about those two events still
holds. What it got wrong was generalising from them to *"no hook observes a dispatch"*: the dispatch
tool is reached by `PreToolUse` like any other tool, and the tool is named **`Agent`**. Measured — a
`PreToolUse` hook on matcher `Agent` captured the full brief on a real dispatch, while the identical
run on matcher `Task` captured nothing at all, which is how the wrong name survived unexamined.

**Falsifier, runnable:** `jq -r '.hooks.PreToolUse[].matcher' hooks/hooks.json` → `Bash`, `Agent`,
`Edit|Write|MultiEdit|NotebookEdit`. If that returns `Bash` alone, the struck text is correct again.

**What is now true, stated narrowly so it is not read as more than it is:** a `PreToolUse` hook on
`Agent` can **deny** a dispatch, and one does — `hooks/scripts/dispatch-premise-guard.sh`, recorded in
ADR-0004's 2026-08-25 amendment. It refuses a dispatch whose brief stamps a repository state that is
not true. **It does not enforce a dispatch's SCOPE**, which is what this section is about: nothing
mechanical decides whether a persona is being dispatched inside its lane. That half of the paragraph
survives untouched. This amendment converts an
unloaded rule (two Issue bodies, session memory — the exact shape that let #287 and #291 happen) into a
**loaded** one (`agents/product-lead.md`, preloaded on every dispatch); that is the whole of what it buys,
and it is stated as a ceiling rather than implied to be stronger.

### Correction (2026-08-28, #344) — the dispatch layer is observable and refusable, and the retraction never reached this record's own status line

**#326 struck the false sentence where it was argued and left it standing where it is summarised.** The
`- **Status:**` line above still carried *"enforcement is prose-only, confirmed against Claude Code's own
hooks documentation — no hook layer can observe or refuse a `Task` dispatch"* for two days after the
mechanism that falsifies it shipped. It is struck there now, in place. **The general shape is worth more
than the instance: a record's index or status line is where a superseded rule survives longest, because
nothing executes it** — the body gets re-read when the decision is revisited, the summary gets re-read
by nobody and copied by everybody.

**What the claim said, and how it was reached.** It was reached from **documentation**, not from a probe
— that is stated in the paragraph above this one, in its own words (*"confirmed this against the primary
source rather than merely failing to find a counter-example"*), and it is the reason the error was
durable: the documentation it consulted describes `SubagentStart` and `SubagentStop`, and about those two
events it was correct. The generalisation from *those two events cannot block* to *no layer can observe a
dispatch* is what was never measured.

**What falsifies it, by name and by matcher.** `hooks/scripts/dispatch-premise-guard.sh`, registered on
matcher **`Agent`** under `PreToolUse` in `hooks/hooks.json`, and it **denies** — a live denial, not a
capability claim: it refused a real dispatch on 2026-08-28 whose brief stamped `origin/main` at a commit
belonging to the other repository in this workspace, which is the exact failure it was built for.
**Runnable falsifier:** `jq -r '.hooks.PreToolUse[].matcher' hooks/hooks.json` → `Bash`, `Agent`,
`Edit|Write|MultiEdit|NotebookEdit`.

**The matcher asymmetry, which is the likely origin and the part that stops this recurring.**
Probe against control, one variable, recorded in that guard's own header: matcher `"Agent"` **fired** on
a real dispatch and captured the full payload; matcher `"Task"` on the identical dispatch **fired not
once**. A true observation about one matcher name — `Task` sees nothing — generalised into a false claim
about the layer. Worse than inert: a `matcher` is a regex, so `"Task"` matches `TaskCreate` and yields a
hook that fires on todo-list writes and never on a dispatch — installed-looking and useless, this repo's
named failure shape.

**The measurement that makes dispatch gating IMPLEMENTABLE, which is what this correction is actually
for.** From the same guard's header: the dispatch payload carries the full brief at
`.tool_input.prompt`, and **`subagent_type` is present only when the model names a persona — it is
ABSENT when it dispatches the default general-purpose agent.** So *deny on an absent or unsanctioned
`subagent_type`* is a small, keyed-on-a-present-field hook, and the struck clause said it was impossible.
**A reader deciding what to enforce needs the capability, not the retraction** — and the sprint that
contains this correction also contains an owner instruction to add enforcement *"se necessário"* (#339),
which is precisely the decision the struck clause would have made wrong in one of two expensive
directions: rebuilding a control that already exists, or abandoning one that is available.

**Two boundaries a reader must carry before assuming the dispatch layer is now covered.**

- **The guard checks REPOSITORY state, never TRACKER state.** In one session it denied a dispatch over a
  ref-and-commit pair and, in that same session, passed a brief whose claim about an Issue's contents was
  false. A tree is resolvable from a `PreToolUse` payload; an Issue's comment history is not. This is the
  same limit already recorded under this document's *"A limit of what the premise guard can hold, named
  here because it is the honest companion to it"* heading, restated here because that heading is 900
  lines away and a reader arriving at this correction will not have passed it.
- **A bare SHA is deliberately not checked.** By the guard's own header, a merge-base, a PR head or a
  quoted verdict marker is a **reference** rather than a premise; treating one as a premise denied 8.0%
  of 859 real briefs for no reason. So the absence of a denial on a SHA-bearing brief is not evidence the
  brief was verified.

**What is NOT retracted, and the distinction is the whole of what this amendment's enforcement section
was about.** Nothing mechanical decides whether a persona is being dispatched **inside its lane**.
`Agent` can carry a scope control; none is built, and the fourteenth amendment's boundary rule remains
prose in a loaded brief. *"Enforcement is prose-only"* is still true of **scope**; it was never true of
the layer.

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
`skills/agents-configuration/SKILL.md`, and three more sites in this document). None of the eight failures
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

  **PARTIALLY DISCHARGED 2026-09-02 by amendment #30 (#379), and the split is exact rather than
  generous — this bullet books THREE things and `/sprint-review` delivers ONE.** Struck in place below
  only for the third; the first two stand, live, and this bullet remains the place a reader looking up
  the residual arrives at.

  | this bullet's clause | `/sprint-review` |
  |---|---|
  | *"Nothing records that **the owner** looked"* | **open.** The report records that `product-lead` looked. |
  | *"nothing surfaces **to him** that something boundary shipped"* | **open.** The rite reads merged PRs to *weight* its sweep; it surfaces nothing per-merge. |
  | ~~a post-deploy look leaves no artifact at all~~ | **closed** — one report file per iteration, in the consuming repo. |

  **And the trigger clause names a case the rite cannot cover, which is why the discharge is partial
  rather than pending.** The one instance booked against this residual is `tadeumendonca-io#479`, an
  article that reached production unreviewed — a **truth-of-a-published-claim** case, and the sweep bars
  itself from that class twice: it runs *after* the merge gate where the blocking veto fires, and
  `commands/sprint-review.md` states *"A sweep finding must never be relayed as a BLOCKING truth
  finding."* **The `SessionStart` arm over `APPROVE-AND-MERGE-BOUNDARY` remains the open half of this
  residual**, unbuilt, and is not an optional extra to the sweep.
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

`/agents-configuration`'s state table named **`developer`** as the builder for a `content` Issue. That
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
`/agents-configuration`'s state table is the single place to correct it.

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

**Mechanically, "ready for him" is a verdict literal, not a hold count.** `agents/quality-assurance.md`'s
*"Your verdict — exactly one of"* enumerates ~~four~~ **five**; ~~exactly one means~~ **two mean** the
remaining act is the owner's: **`APPROVE-PENDING-HUMAN`** **and `APPROVE-EXECUTOR-BLOCKED`**.
`REQUEST-CHANGES` is also non-merging and is **not** an owner summons — it
routes to the builder. Naming the literal is checkable; naming *"one of the four holds fired"* is not.

**Amended 2026-09-01 (#374): the vocabulary is FIVE and the owner-summoning set is TWO.**
`APPROVE-EXECUTOR-BLOCKED` joins it — the gate cleared the diff and could not execute the merge, so the
decision is made and only the act is his. **The arithmetic above is STRUCK IN PLACE rather than left to
this amendment to correct**, which is the fix the copy lens required on this paragraph's first
authorship: an adjacent correction is not a correction, because *"a correction needs the false claim's
ABSENCE asserted, not its replacement's presence"* — this repository's own rule, landed one commit
before this branch. ADR-0005's amendment in this same PR applies it to itself, striking
`~~Thirty-five versions~~` **even though the corrected figure is in the very next sentence**; leaning on
adjacency here would have been the one inconsistency in the batch. What is genuinely unchanged is the
*argument* — naming a literal is checkable, naming which hold fired is not — and only the arithmetic
moved, which is precisely why the arithmetic is what needed striking. See ADR-0004's 2026-09-01
amendment for the decision, the readers that must move in lockstep, and why inferring the state from a
clearance that stayed open is a race detector rather than a strand detector.

**The rule has a SECOND limb, and it is not mechanical — which is why it was nearly lost.** #327 states
it in the same blockquote it labels *"the sharp form of the rule"*: a PR link also goes to him **when the
ask is explicitly a decision he holds** (a title, a positioning call), *stated as that and not as a merge
request*. Such a PR frequently carries **no gate verdict at its head at all**, so the verdict-literal test
above classifies it as premature — the first limb alone is **stricter than the rule the owner wrote**, in
the direction that withholds something he asked to keep. It shipped on no surface in the first round of
this slice and was caught by the merge gate, not by any check; the operative wording now carries both
limbs (`commands/autonomy.md`, *"Do not hand the owner a PR link he cannot act on"*). **The mechanical
half deliberately implements only limb one** — *"is this ask a decision he holds"* is not knowable at any
layer, and an attempt to make it so would be the theatre this record spends its length avoiding.

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
- **Put the operative wording in `skills/agents-configuration/SKILL.md`**, the universal preload.
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
- **The detector will flag legitimate decision-ask links, and this is the rule's second limb being
  unimplementable rather than a bug.** A PR whose ask is a decision the owner holds usually has no gate
  verdict at its head, so the hook classifies it as premature and emits a notice. The failure is in the
  **harmless direction only because the hook is detection-only**: the cost is a spurious notice in the
  next turn's context, never a withheld link. Were this ever made preventive, this cost inverts into
  suppressing exactly the links the owner asked to keep — which is a second, independent reason not to
  make it preventive, beyond the one already stated above.
- **A third independent reader of the `gatekeeper-verdict` marker.** `session-wip.sh`,
  `zombie-loop-detect.sh` and now this one read the same artifact with the same extraction. Drift between
  three readers is caught by a reviewer diffing three test files, not by any gate — the same trade
  `zombie-loop-detect.sh`'s header already argued for, extended by one.
- **`/autonomy on` covers autonomy runs, and the defect can occur in any session.** Accepted rather than
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


## Amendment (2026-08-25, nineteenth) — the lane relation has ONE home, and it is the states table

**What this amendment records is WHERE the rule lives, not what the rule says.** That restraint is the
decision, not a stylistic choice: a record that restates an operative rule becomes one more surface to
keep true, and [#329](https://github.com/tedeuxx/tadeumendonca-skills/issues/329) is what nine surfaces
stating one rule costs. The wording itself is in
[`skills/agents-configuration/SKILL.md`](../../skills/agents-configuration/SKILL.md), in the states table's
`filed → **description closed**` rows. Read it there.

**Two owner rulings, both on 2026-08-25:**

1. **Canonical home.** *"The states table in `skills/agents-configuration/SKILL.md` is canonical.
   `README.md` becomes a pointer."*
2. **The exception.** Asked whether `tech-lead` co-signs a `loop` intake by exception or never, the
   answer was one word: ***"nunca"***.

### What the defect was, and it is an OMISSION rather than a wrong sentence

`loop`-typed intake has been `agents-lead` alone by standing rule since 2026-08-13. **This document never
said so.** The *Issue type is the routing axis, and it is exclusive (absorbed 2026-08-20, record 0012)*
section states *"The type decides which profiles take part at intake"* and then never enumerates the
per-lane intake sets. That hole is why `README.md` became the only surface stating the relation, and why
nothing contradicted it when it stated the retired pairing for eleven days. **There was nothing here to
correct; there was something missing to add** — and what is added is the pointer, plus the enumeration's
new home.

### Why the mechanism layer wins over the narrative layer, reversing record 0019 for THIS class of rule

The *`README.md` is the single source of truth for the dev-loop narrative (absorbed 2026-08-20, record
0019)* section stands **for the narrative**, and is not disturbed. This rule is not narrative — it is an
**instruction to whoever dispatches**. In the owner's terms:

- the **README is prose that no agent carries**; nothing preloads it;
- the **states table is mechanism**, and every persona preloads `agents-configuration` and `engineering-standards`.

**A rule exists to be obeyed by whoever dispatches, and whoever dispatches reads the skill.** Putting the
operative wording where nobody looks is how #329 happened.

### It does NOT disturb record 0015's rejected option, and this paragraph exists because it reads as if it does

The *`agents-lead` implements the harness it reviews (absorbed 2026-08-20, record 0015)* section's
rejected-options list contains:

> *"**Routing `loop` to `agents-lead` alone** for both proposing and building in one dispatch — named in
> the routing record above so it is not silently reintroduced."*

**Read to the comma it rejects this amendment. Read whole it rejects something else entirely** — a single
dispatch that *proposes and builds in one act*. That separation is untouched here: `agents-lead` closes
the description at intake, the owner applies `ready`, and the build is a **second, separate** dispatch.
It is the only place in either library where the string *"`agents-lead` alone"* appears, so anyone
implementing this rule will meet it and must not argue the rule back out on it.

### The rejected options

- **State the wording in this record.** Rejected: it makes the record a fourth surface to keep true, which
  is the failure being closed. The record points; it does not restate.
- **Keep `README.md` canonical, per record 0019.** Rejected on the mechanism/narrative split above. The
  cost taken: this is the first place record 0019's designation is narrowed by class rather than
  followed, and a future reader must check *which class of rule* before citing it.
- **Tighten the `tech-lead` exception instead of removing it.** Rejected by the owner, with the argument
  that decides it: almost every machinery change can be described as having an architecture edge, so a
  loose exception becomes the default case. It is not hypothetical — that is how the pairing returned on
  2026-08-13. **A rule with a judgement-call escape hatch is the escape hatch.** An unconditional branch
  is cheaper to implement *and* cheaper to obey.
- **Add a lane anchor (a machine-readable fence) and gate the drawing against it.** ~~Deferred, not
  rejected.~~ **The ANCHOR half is built, 2026-08-26, as #329's third requirement; the "gate the drawing
against it" half is NOT** — that is the consumer slice in `tadeumendonca-io`, a separate Issue, and
nothing there reads this fence yet. Read the bullet's title as naming the whole option, of which one
half has landed. The fence is in
  [`README.md`](../../README.md), between the `roster:lanes` markers beside the tier diagram, and three
  arms in `hooks/scripts/inventory-counts.test.sh` hold it (exactly one fence · six (type, tier) arms,
  none empty · every id resolves to a live `agents/*.md`). **This does not move the canonical home and
  is not a fourth surface stating the rule:** the fence is *derived* from the states table, carries
  persona ids and no wording, and its own section says the table wins where they disagree. It is a real
  mechanism with its own design questions — fence count, vacuity guard,
  both-direction assertion — and `agents-lead`'s intake measured the naive alternative dead: a prose
  extractor over the states table returns the empty set for two of three lanes and would ship a vacuous
  green. **Re-measured at build time from the other side, and the second reading is the sharper one:**
  run over the two rows a tolerant extractor *can* read, it returns `tech-lead` for the `loop` intake
  lane and `developer` for the `content` build lane — both pulled out of the clause that EXCLUDES them,
  and both exactly the errors this anchor exists to catch. A wrong set is worse than an empty one, so
  the fence carries no prose at all. ~~It gets its own Issue, opened by the owner.~~ **It did — #329,
  reopened for it.**

### Consequences

- ~~**Nothing observes a dispatch, and this amendment does not change that.**~~ **Narrowed 2026-08-28
  (#344): a dispatch IS observed — `hooks/scripts/dispatch-premise-guard.sh` on matcher `Agent` reads
  every brief and denies on a false tree-shaped premise. What nothing observes is WHO was dispatched
  against WHICH LANE, which is the only thing this bullet was ever about; the over-broad wording is
  struck so it cannot be quoted as the general claim #344 retracts.** The gate added in this slice
  asserts that the canonical rows and the `new-issue.md` branch **exist and say this**. Whether an intake
  obeyed them is invisible to the tracker and to the diff — a `loop` Issue whose description was closed
  by both personas looks exactly like one closed correctly. Stated as a residual, deliberately.
- **Three GitHub label descriptions are corrected in the same slice, and nothing can ever sweep them.**
  They are repo metadata, in no file and in no diff, reachable by no `git grep` in either tree. `-skills`'s
  `loop` label carried both the retired pairing **and** a retired persona name (`harness-reviewer`); the
  `ready` label in **both** repos described a rule true of one lane in three. This class of surface is why
  eleven days was possible.
- **The `-io` half is routed separately** — the tier-fence diagram, its `accDescr` (including a persona-box
  **count** that an edit to the fence falsifies) and the regenerated `diagrams.json`. Not in this slice and
  not this persona's object.
- **One coupling accepted:** the new gate arms key on phrases. Rewording the canonical rows or the
  `new-issue.md` branch reddens `inventory-counts.test.sh`, and whoever rewords must edit the arm in the
  same commit. That friction is the feature — it is the same trade the second-limb arm in that suite
  already takes.

### Addendum (2026-08-26) — a TENTH surface, and it was the one written as an INSTRUCTION

**This amendment's own sweep missed `skills/agents-configuration/SKILL.md`'s *When to reach for this
discipline specifically* bullet**, which read *"pair it with `tech-lead` (design-time …) and
`quality-assurance` (code-time …)"* — seventy-five lines above the canonical row this amendment
installed saying `tech-lead` never co-signs that lane. **The same file stated both, in the universal
preload, for thirteen days**, and arm 1 of the gate was green throughout because the row it reads was
correct. Corrected here by strike, and gated by a fifth arm (positive: the strike is present; negative:
the retired literal is not live anywhere in the file, struck spans stripped first).

**Why the sweep missed it, and this is the transferable half.** Arms 1–4 and the round-1 sweep both key
on surfaces that **state** the lane relation. This bullet does not state it — it **prescribes a
dispatch**, in the register a persona is most likely to act on. *"Validating a loop/gate change"* and
*"`loop` intake"* are the same act — the 2026-08-13 correction that established the rule was made on
exactly such a dispatch — but nothing in the sentence says *intake*, *lane*, *`ready`* or *description*,
so no vocabulary built from the defect reached it. **The lesson is the arm's own comment: sweep a
rule's surfaces by what they INSTRUCT, not only by what they state.**

**And it is the concrete instance of the rejected option this amendment already named.** *Tighten the
`tech-lead` exception instead of removing it* was rejected on the argument that a loose exception
becomes the default case. This bullet is that exception, surviving in the one file every persona
carries: a reader wanting `tech-lead` on a machinery change did not have to argue for it, only to read
the advice section instead of the table.

**Deciders:** the owner (both rulings, quoted above), written by `agents-lead` per the #223 domain split —
this is a pure loop/machinery decision with no product-architecture stake, so no `tech-lead` co-citation is
owed on its own terms, which is also what the decision itself says.

## Amendment (2026-08-25, twentieth) — the ITERATION is the unit of work, and its tracker object is a milestone

**Owner decision, 2026-08-24 ([#326](https://github.com/tedeuxx/tadeumendonca-skills/issues/326)):
the loop adopts iterations as the unit of work.** He applied `loop`-typed `ready` himself, which on that
lane is his transition alone (the *`agents-lead` implements the harness it reviews* section, Corollary 4).
The falsifier that opened the Issue re-ran clean at head before this slice — `iteration`, `iteração` and
`sprint` matched **nothing** in `commands/`, `skills/` or `docs/adr/` — so the rites existed as knowledge
and the axis did not exist at all.

**This amendment records WHERE the rule lives and WHAT was decided in this slice that the source document
refused to decide. It does not restate the operative wording** — the same restraint the nineteenth
amendment took, for the same reason. The wording is
[`skills/agents-configuration/SKILL.md`](../../skills/agents-configuration/SKILL.md), section *The iteration
is the unit of work*, and the drain's terminal condition is `commands/autonomy.md`'s *Stop when*.

### Why this is an amendment and NOT record 0022

The `roster-and-dev-loop` capability's own entry claims *"how work moves through them … the shape a unit
of work takes"*. An iteration is exactly that, so a new record would be a **second file inside a
capability whose whole design (#283) is one document per name** — the shape the consolidation exists to
prevent. **"No new record owed" is the answer, with that reason**, and the ceiling constant is untouched.

### The three decisions this slice closed, and who closed each

1. **The tracker object is a MILESTONE** — decided inside the loop on a measurement, not a preference. A
   Projects v2 iteration field cannot be *created* from this harness (`gh project field-create
   --data-type` offers `{TEXT|SINGLE_SELECT|DATE|NUMBER}`), cannot be *read* without a `read:project`
   token scope the account lacks, and its GraphQL route is denied by the global floor. Milestones need
   none of that.
2. **`loop`-typed items are iteration-assignable** — the question the source document explicitly declines
   to answer for an importer. Decided inside the loop, on a premise measured locally: `/autonomy on`'s
   queue is `(product OR loop) AND ready`, so the alternative does not orphan a ceremony's output, it
   takes half the queue dark.
3. **Exhaustion is the drain's terminal condition again, and #103's judgment condition moves to
   planning** — decided inside the loop. ~~It is not a reversal: #103's argument is about a pool that
   grows while it drains, and an iteration's pool does not.~~ **Struck 2026-08-29 — see the twenty-third
   amendment.** `loop` Issues now join the ACTIVE iteration at filing on the owner's decision, so an
   iteration's pool does grow while it drains and this justification no longer holds. The terminal set
   moved to the drain's ENTRY SNAPSHOT; the half of decision 3 that survives is that #103's judgment
   condition still lives at planning.

**The one measurement that could have sent decision 1 back to the table, closed here rather than left
open.** `gh issue list --json milestone` returns a sub-object with **four keys and no `state`**
(`description`, `dueOn`, `number`, `title`); `state` is not among that command's available fields, and
there is no `gh milestone` subcommand. **So no command available to this loop can read whether a milestone
is open or closed.** It does not overturn the choice, because rule 1 derives the active iteration from
*items* and never consults `state` — but it does kill the source document's *"the iteration closes
automatically"* clause, which is **not adopted**. Creating and closing a milestone are owner clicks. The
alternative — unlisting `Bash(gh api:*)` from the global floor — is refused: that entry is what stands
between every persona and the raw write API.

### The rejection sent back to the source project

**The blueprint format-version field, with its *"an unknown field is ignored, never rejected"* rule.**
`agents-lead` recommended against it when that format was designed, on the ground that a version field
promises a compatibility guarantee this repository cannot hold — a Markdown table ignores unknown columns
by construction, and this repo's own `CLAUDE.md` carries three struck figures whose published commands
stopped resolving. **The source document's §6.4 licenses the rejection in its own words** — measured local
evidence beats an imported rule, in both directions — and this is measured, local, and predates the
import. **It is a rejection of the *schema* version only, not of source identity**; the *"which project,
which configuration version, when generated"* header is a different object and is not refused here.

### The rejected options

- **A Projects v2 iteration field.** Rejected on the measurements above. Choosing it would mean the loop
  reads an axis it cannot write.
- **An `iteration:N` label.** Rejected: it duplicates an observable GitHub already stores and already
  constrains to one per item, which is the anti-pattern the eighth amendment's *"what observable artifact
  says this rule was applied"* rule names. The milestone **is** the artifact.
- **A sixth state in the vocabulary.** Rejected for the same reason. The axis changes one row's
  precondition (`ready → in progress`) and adds no word to the label set.
- **Leaving both terminal conditions standing.** Rejected — it is the shape this file has already paid
  for twice (#97 → #103, and the exhaustion event itself).
- ~~**Building estimation in this slice.** Deferred, not refused …~~ **STRUCK the same day, and the
  strike is the load-bearing part of this amendment rather than a correction to it.** Estimation is
  **in**, per the owner's ratified interview of 2026-08-24 (*"inteiro. estimar antes é positivo"*,
  *"todos agentes que trabalham no tipo de issue estimam"*), reconfirmed by him on 2026-08-25. The
  carrier is **built**: an `sp:N` label class over a closed Fibonacci set, estimator sets per issue
  type, median of isolated dispatches, no revote, and a **preflight** that refuses to enter the drain
  while any item in the active iteration lacks one. What is deferred is only **the first pass** —
  **128 dispatches** over the existing backlog, **his figure, not a re-derivation** — which is a
  bootstrap cost the owner triggers, not the steady state.
- **Building the 128-dispatch first pass inside this slice.** Rejected. It is one act over the whole
  backlog, it is the owner's to trigger, and folding it in would make a rule change wait on a batch job.
  **The consequence is stated rather than hidden: the first preflight after this ships REFUSES**, because
  no item carries an `sp:N` yet. That is correct under the rule he settled and will read as a regression
  to anyone who meets it without this paragraph.
- **Building the ceremony chain's REVIEW rite.** ~~Not deferred on preference: it is **unbuildable AFK
  here** on three independently measured grounds — no MCP server is reachable from a dispatched subagent,
  merge-is-deploy leaves no non-production target to sweep, and resumable state has had no durable home
  since #245 retired the repo-side scratch directory.~~ **Struck 2026-08-30 (#355): the first of the
  three grounds is false at head, and it was the load-bearing one.** `product-lead` declares a read-only
  `chrome-devtools` subset with a bounded origin, merged 2026-08-29 in PR #356. The other two survive,
  and the rite is **still** deferred — but on grounds this amendment never measured and that the browser
  does not touch: a route list rots, so a sweep whose list is stale is a green that proves nothing; and a
  looker's finding is taste, so it must never be a gate. **Struck in place rather than edited** because
  the estimation bullet fourteen lines above sets that convention in this very list, and an unstruck
  bullet in a list that strikes its retirements reads as live. The refusal that stands today, and its
  cheapest first slice, are in the twenty-sixth amendment and in `commands/sprint-retrospective.md`'s own last
  section.

### Consequences

- **A `ready` item with no milestone silently stops being worked.** `ready` was sufficient and is now
  necessary-not-sufficient. The mitigation is a **count reported at session open**, from the same query —
  prose, not a mechanism, and it is the single largest silent-failure surface this amendment creates.
- **The unboundedness moves; it is not removed.** ~~The active iteration's pool is fixed at planning~~ —
  **struck 2026-08-29, twenty-third amendment: it is not, and the bound is now the drain's entry
  snapshot.** The rest of this bullet survives intact: nothing bounds the *next* one, or how many items the owner admits to one iteration. That is the intended
  shape — the bound on worth is a human deciding — but an over-filled iteration reproduces the old
  unbounded drain inside one milestone, and no gate can see it.
- **An empty pool from a mistyped milestone is indistinguishable from a drained one**, and exhaustion is
  no longer terminal, so the loop would run the closing ceremonies over an iteration that never existed.
  The rule that answers it — enumerate the milestones from the items, never type a name — is prose, and
  nothing enforces it.
- **Nothing observes an iteration.** Every `gh issue` call in `hooks/scripts/` is a write path. The gate
  added in this slice asserts that the rules are **written** in the canonical surface and in the executed
  command; it cannot assert that a session obeyed them. Same residual, same wording, as the nineteenth
  amendment's.
- **One coupling accepted**, identical in kind to the nineteenth's: the new gate arms key on phrases, so
  rewording the canonical section or the command's *Stop when* reddens `inventory-counts.test.sh`, and
  whoever rewords edits the needles in the same commit.

### Which artifact supersedes which, so the next reader does not re-litigate it

**Two artifacts on #326 disagree about whether implementation may proceed, and the chronology settles
it.** At **22:31 on 2026-08-24** a comment placed implementation **on hold** pending the source project's
finished implementation — the axis, the tracker object, the ceremony chain and the `/autonomy on` stop
condition, all explicitly not proceeding. At **00:00:25** the **ratified sprint model** was posted: later
in time, and a **complete design** rather than a deferral. The owner then applied `loop`-typed `ready`,
which on that lane is his transition alone and is the loop's own signal that an Issue is executable.

**The ratified model supersedes the hold, and the hold's reason survives in narrowed form.** Its argument
was interoperability — building a shape here that the source project's finished implementation would
contradict, paying a migration *and* losing the interchange. That argument does not reach the **axis**,
which is derived from this repository's own measurements and its own #103. **It does still reach the
ceremony chain**, which is why REVIEW, RETROSPECTIVE and PLANNING are designed and not built here, and
why that is recorded as a rejected option above rather than as an omission.

### A limit of what the premise guard can hold, named here because it is the honest companion to it

**This slice was dispatched with a false premise: that the owner had decided *"iterations yes, estimation
no"*.** He had not — the contradicting artifact was a comment on the very Issue being built, in his own
quoted words. The build refused to write *"void — owner's decision"* into this record on an agent
message's authority, routed the question to him, and he confirmed the ratified design stands.

**No mechanism could have caught it, and the reason is worth stating precisely rather than as a
lament.** `hooks/scripts/dispatch-premise-guard.sh` checks **tree-shaped** premises — a SHA, a branch,
a path — because those are the claims a hook can resolve against a repository. ***"The owner decided X"*
is not tree-shaped.** Its truth-maker is a comment on an Issue, and no `PreToolUse` payload carries the
Issue, let alone its comment history.

**So the control that held here was a persona rule, not a hook**: *read the files, do not trust your
training; if your instructions contradict a file you can read, the file wins and you say so out loud.*
**That is an instruction, and by this document's own test an instruction is not engineered** — if it had
failed, nothing would have stopped it. It is recorded as a **named residual**, not as a control, and
deliberately **not** used as an argument against the guard: the guard closes the class it can close, and
pretending it closes this one would be the exact failure it exists to prevent.

**Deciders:** the owner (the adoption itself, the estimation ratification of 2026-08-24 reconfirmed
2026-08-25, and the `loop`-typed `ready`), written by `agents-lead` per the #223 domain split — a pure
loop/machinery decision, no product-architecture stake, no `tech-lead` co-citation owed. The three
sub-decisions above were closed inside the loop and are labelled as such rather than attributed to him.

## Amendment (2026-08-28, twenty-first) — the `agents-lead` verdict marker lives on the PR, and the intake review's evidence is a different artifact

**The defect (#336).** `agents/agents-lead.md` instructed *"Post via `gh issue comment` where the
proposal is still an Issue with no PR yet — **which is the common case, since you run before the
build**"*, while `agents/quality-assurance.md`'s hold 2 requires *"an `<!-- harness-lead-verdict: … -->`
comment **on the PR** before you may merge it."* **In the case the producing brief called common, a
correctly-reviewed `loop` change carried its marker where the gate is correctly told not to look.**

**Why that is worse than a nuisance, and it is the reason this got its own Issue rather than riding on
#335: both outcomes are unattributable afterwards.** Either the gate blocks a properly-reviewed diff
because it looked on the PR and found nothing, or it accepts an Issue comment and hold 2 quietly means
something looser than it says. A verdict records the literal, never the surface it was read from, so
nothing in the artifact distinguishes the two.

**Measured, not read.** Issue #335 carries exactly one `harness-lead-verdict` comment (the intake one,
relayed by the orchestrator after the Issue was filed); PR #348 carries three. The sets are disjoint:

```
gh issue view 335 --repo <owner>/<repo> --json comments \
  --jq '[.comments[]|select((.body//"")|contains("harness-lead-verdict"))]|length'   # -> 1
gh pr view 348 --repo <owner>/<repo> --json comments \
  --jq '[.comments[]|select((.body//"")|contains("harness-lead-verdict"))]|length'   # -> 3
```

**Nothing bridges them, and nothing was ever going to.** `hooks/scripts/dispatch-metrics-stop.sh` reads
the marker off `gh pr view "$pr_number" --json comments`, so the one mechanism that touches the string
already assumes the PR; and nothing forces a `loop` PR to reference its Issue, so a PR → Issue
resolution route would have no reliable edge to follow.

### The decision

**Decided by the owner on 2026-08-28, in one sentence — *«se é relacionado a revisao, deveria ser no
PR»*.** The criterion, not just the answer: **a review artifact lives with the review.** What the marker
attests is that the machinery lens was pointed at **the change**; the change is the diff; the diff is on
the PR. `agents/quality-assurance.md`'s hold 2 is correct as written and did not move — **the producing
brief is the half that gave way.**

1. **The marker literal `harness-lead-verdict` is a PR-only string.** `agents-lead` posts it with
   `gh pr comment`, never `gh issue comment`. The gate reads one surface, and reserving the envelope to
   that surface is what makes *"which comment does the gate read"* answerable by `grep` rather than by
   reading two briefs and hoping they agree.
2. **The marker is head-scoped, and a moved head takes a fresh one** — the earlier marker is explicitly
   named in the new one as referring to a moved head, never edited away. **This records behaviour that
   already ran rather than proposing it:** PR #348's second and third markers open *"re-reviewed at
   fe66f85"* and *"re-reviewed at 9489a3f"*, posted after the gate moved the head twice.
3. **The intake review keeps producing evidence, on the Issue, WITHOUT the envelope** — heading
   `## agents-lead — intake stress test (not the gate's artifact)`, same content and same `commit:`
   line. The envelope exists to be machine-read; this artifact has no machine reader, so giving it one
   would recreate the two-surface ambiguity being closed.
4. **A PR marker is never a copy of an intake comment.** A copied marker carries a pre-build SHA, so it
   would satisfy a head-scoped check with a review that never saw the diff — strictly worse than an
   absent marker, because it *looks* like the lens was pointed at the change when it was pointed at the
   proposal.
5. **The case where neither surface exists yet is named rather than left uncovered.** `agents-lead`
   reports it in its return as a finding about its own dispatch and names the Issue the intake comment
   belongs on; the orchestrator relays a plain comment there. The relay therefore cannot manufacture a
   gate artifact — which it did on #335, and which is what #336 recorded.

**This is the second of the two shapes the Issue offered, with one deviation stated as such.** The
Issue's second shape was *"the marker is carried forward — written wherever it can be at intake, and
re-posted onto the PR"*. Carrying the **evidence** forward is adopted; carrying the **marker** forward
is not, for the reason in item 4. The first shape — the intake review stops producing a marker at all —
was rejected because it silently drops the intake review's evidence, which is the only artifact the
stress-test half of a `loop` intake produces.

### The rejected options that are still live

- **A second marker literal for the intake artifact** (e.g. `harness-lead-intake`). It would be
  mechanically unambiguous, and it was rejected because the same unambiguity is bought by *removing* an
  envelope rather than by *adding* a string — and the added string would need its own gate arm, its own
  spelling-drift risk, and a place in `dispatch-metrics-stop.sh`'s reader. Removing machinery beats
  adding it when both reach the same state.
- **A PR → Issue resolution route**, so an Issue-side marker could satisfy hold 2. This was the price of
  the answer the owner did not choose. It is recorded here so it is not silently reintroduced: it has no
  reliable edge to follow, since nothing forces a `loop` PR to reference its Issue.
- **A hook that denies posting the marker to an Issue.** Measured inert before proposing: `shell`
  requires every comment body to go through `--body-file`, so the marker text is never in the command
  string a `PreToolUse` hook receives. Such a guard would fire only on the inline `--body` form this repo
  already forbids — a control that works everywhere except where it is needed.

### Consequences still being paid

- **The one-surface rule is held by review, not by a mechanism, and this amendment does not pretend
  otherwise.** `hooks/scripts/inventory-counts.test.sh` gains one arm asserting that
  `agents/agents-lead.md` and `agents/quality-assurance.md` both carry the sentence *"marker lives on
  the PR"*, mutation-verified in both directions. **It is a drift check over a string** — the same class
  #335 found for the mirror gate — and it cannot tell whether either file means it, nor observe where a
  marker was actually posted. By this document's own test (*would something stop me, or only my
  memory?*), the rule is an **instruction**, and it is recorded as a named residual rather than as a
  control.
- **Historical Issue-side markers exist and are not rewritable.** #335's carries the envelope on an
  Issue. The PR-only invariant binds forward, not backward, and a reader sweeping old comments will find
  counter-examples that were correct under the rule of their day.
- **The PR marker on a PR `agents-lead` itself built is a self-attestation.** That is unchanged by this
  amendment — it is record 0015's own *"`agents-lead` reviews and builds the same object"* consequence —
  but stating the marker's surface makes it more visible, and it should be read as *the lens was pointed
  at this diff*, never as *an independent reviewer approved it*.

**Deciders:** the owner (the surface, and the criterion behind it), written by `agents-lead` per the
#223 domain split — a pure loop/machinery decision, no product-architecture stake, no `tech-lead`
co-citation owed. The design choice between the Issue's two shapes, and the four sub-decisions above,
were closed inside the loop and are labelled as such rather than attributed to him.

**Explicitly out of scope, and still open:** Corollary 2's own text in this document still reads the
retired *"absent that marker the diff is boundary class regardless"* form, ~980 lines from the amendment
that corrected it. It is the citation every other surface points at, and it is its own slice.

## Amendment (2026-08-28, twenty-second) — loop before product is a planning-time COMPOSITION rule, and no layer in this harness can gate it

**The owner's standing rule (#339), 2026-08-28:** *«o pedido é que sempre todos itens de loop sejam
atacados no inicio de sprints. lembre-se disso. faca enforcement se necessario.»* He ruled while the
iteration was being ordered, which **dissolved a circularity worth recording**: the rule that would
order the sprint was an item **inside** that sprint (position 7 of 13). He answered directly rather than
waiting for the mechanism, so this amendment records a rule in force rather than proposing one, and the
slice is not a precondition for the iteration it sits in.

### The decision

**Loop-first is discharged at PLANNING, on the iteration's ordered body — not at drain time, and not by
a gate.** The ordered body lists every eligible `loop` item before any eligible `product` item; the
drain keeps obeying `commands/autonomy.md`'s *"Do not invent an order."* The operative wording is
`skills/agents-configuration/SKILL.md`'s *"Loop before product — a planning-time COMPOSITION rule, and it
is NOT a gate"*, in the preload every persona carries; this record is the argument, not a second copy.

**It ranks only what is ELIGIBLE**, and that clause is the deadlock escape the Issue asked for by name:
`(loop AND ready AND active-iteration)` ahead of `(product AND ready AND active-iteration)`. An item
without `ready`, or carrying `blocked`, is not in the pool and cannot stall it. **`ready` on a `loop`
item is the owner's transition alone** (record 0015's Corollary 4), so ranking `loop`-ness rather than
*eligible* `loop`-ness would have stalled a whole repo behind Issues only he could release — measured
2026-08-28: `-skills` carried two unlabelled `loop` Issues while `-io` carried five `ready` `product`
items and zero `loop` items of any kind.

**The escape's real shape is narrower than it first reads, and this is where the honest limit sits.**
This sprint produced a live instance the same day: position **5** (#341) needed the owner's go under
the gate's hold 1, WIP=1 held, position **6**'s build (#337) could not open its PR, and the drain
stopped until he answered. (Written as `6` and `7` on the first pass; the order of record reads
`5 #341`, `6 #337`, `7 #339`. **The gate could show the claim disagreed with the milestone description
and could not show it false** — the field is mutable and unversioned, which is this amendment's own
weak-home consequence reproducing itself inside the slice that records it.) **The eligibility clause did not apply** — #341 was `ready` and already in progress. It covers
an item that never *entered* the pool; it does not cover one that entered and stalled. For that, the
escape is the one `/autonomy on` already carries (cut the slice, write the question on the Issue, move
on), and **WIP=1 is what converts the second case into a full stop** — a cost of WIP=1, not a defect in
this rule.

### The rejected options that are still live

**1 · A `PreToolUse` refusal.** Rejected on the layer question this document exists to ask. Ordering is
not a property of a tree and not a property of a command string: `gh pr create` on a product slice is
character-identical whether a `loop` item is outstanding or not, and `wip-guard.sh` keys on file overlap
on the same matcher. There is no observable moment at which a `product` slice "starts".

**2 · A `Stop`-hook detector — designed, measured, NOT built.** This is the rejection most likely to be
proposed again, and it was killed by a measurement rather than by cost. The obvious form is *"a product
PR is open while `loop` items remain in the active iteration."* Measured against sprint-01's actual
composition on 2026-08-28: **every `loop` item is in `-skills` and every `product` item is in `-io`**,
and the iteration exists as two milestones (numbers 2 and 1) paired only by title. A `Stop` hook
receives one `cwd`, so the same-repo form has **zero true positives against this iteration, by
construction** — no `product` item in `-skills` for it to fire on, no `loop` item in `-io` to make it
fire. **Scope that claim honestly: it is a fact about this sprint's composition, not about the class** —
a future iteration mixing both types in one repo would give the same-repo form real positives. The
cross-repo form is buildable and stacks three heuristics for one advisory notice: sibling-tree discovery
from a payload carrying only `cwd` (ADR-0004's own *"a heuristic and the weakest part"*), milestone
pairing by title (convention, as the milestone description itself says), and PR → Issue resolution
(measured over the twelve most recent PRs: the closing-keyword route resolves 9 of 12, plus a
branch-suffix heuristic 11 of 12, and #330 resolves under neither). Three heuristics deep, fail-silent
by necessity, arriving one turn after a pick the ordered body already directed.

**3 · Declaring the rule enforced because a gate arm exists.** Rejected explicitly.
`inventory-counts.test.sh` gains two arms; both assert the rule is **written**, one of them keying on
the *"not a gate"* disclaimer precisely so that trimming the disclaimer reddens. Nothing observes a
pick.

### What would change the answer, so the next reader does not re-walk it

**A declared, machine-readable order carrier.** `skills/agents-configuration/SKILL.md` already specifies
one — *"The planning artifact is an ITERATION ISSUE"* — and **it does not exist**. The order lives in
the **milestone description** instead, in both repos, chosen for lack of an alternative. That home is
weak in three measurable ways: nothing in `hooks/scripts/` resolves a milestone at all (one `grep` hit,
in a comment); a description edit produces no commit, no diff and no timeline event this loop can read,
since `gh api` is denied by the global floor; and it stands in for an object this same skill specifies.
With a declared order the check becomes declarative — read the sequence, look up each number's labels,
assert every `loop` number precedes every `product` number — needing no PR classification, no tree
discovery and no prose parsing. **That is one object away, and it is the same object the weak-home
finding is already asking for.**

### Consequences still being paid

- **The rule holds because deviation becomes visible and awkward, not because anything stops it.** By
  this document's own test — *would something stop me, or only my memory?* — it is an instruction. It is
  recorded as a named residual, not as a control, and the gate arms must never be read as the second.
- **The order of record is unversioned where this loop can see it.** A milestone description can change
  with no artifact any persona or hook can diff, so *"the plan said loop first"* is a claim about a
  mutable field. Building the iteration Issue closes this and is not in this slice.
- **A citation defect was fixed in passing, and the attempt to discredit the Issue's replacement was
  itself the defect.** `commands/autonomy.md` cited ADR-0002 amendment #5 for sequencing ownership;
  #5's own header reads *"`product-manager` gets a trigger, and the reviewer's output gets a budget"*,
  so that retirement stands and the routing to `skills/agents-configuration/SKILL.md`'s *Opening a
  session — decisions before work* is correct. ~~The Issue's proposed replacement,
  `agents/product-lead.md`, is also wrong — it carries only a `PROCEED` verdict line.~~ **Struck the
  same day: that was FALSE.** That file carries the clause under *What you own — the ordering half*
  (*"Starting work that is not the top of the stated order requires you to have returned a new order,
  or the session to record that the order is unchanged."*), so **both** surfaces carry it and the
  Issue was right. **The cause is the finding, and it is the reusable half: the clause WRAPS a line**,
  so the published `grep -rn "stated order"` matched nothing and **a null result was read as an
  absence.** The falsifier that survives the wrap is `grep -rn -A1 "top of the stated"
  agents/product-lead.md`. A passage arguing *cite the clause, not the line* had, as its own evidence,
  a line-based grep that missed a clause **because of a line** — which is an argument for
  `documentation-standard`'s rule, not against it, and a standing warning that **a grep's silence is
  evidence only once the pattern is known to survive the target's line breaks.**
- **The synergy premise behind the rule is unmeasured, and stays that way.** *"Ganho de sinergia de
  processo"* is the owner's, and this harness has no instrument for it — so if the ordering ever costs
  more than it buys, there is no number to weigh it against. The metrics that would settle it already
  exist in the design (cycle time, and carried-over count per iteration) and are not built here.

**Deciders:** the owner (the rule, and that it is standing rather than batch-specific), written by
`agents-lead` per the #223 domain split — a pure loop/machinery decision, no product-architecture stake,
no `tech-lead` co-citation owed. The layer analysis, the detector's rejection and the two citation
findings were closed inside the loop and are labelled as such rather than attributed to him.

## Amendment (2026-08-29, twenty-third) — `loop` joins the ACTIVE iteration at filing, so the drain's terminal set is an entry SNAPSHOT and the iteration's pool is not

**This amendment reverses decision 3 of the twentieth amendment**, and the clause it reverses is quoted
there in as many words: *"It is not a reversal: #103's argument is about a pool that grows while it
drains, and an iteration's pool does not."* **An iteration's pool now does.** The consequence bullet in
that same amendment reading *"The active iteration's pool is fixed at planning"* is false for the same
reason. Both are left standing there and reversed here rather than rewritten, per this library's own
convention: each was correct on the day and someone built on it.

**Two owner decisions, in order, both #338.** First the rule: *«tudo de loop deveria estar na iteracao
corrente.»* Then, asked whether to narrow it to filing time — which is what `agents-lead` proposed at
intake, and what would have preserved decision 3 intact — he declined: *«a gente nao consegue impedir esse
comportamento, embora ao longo do tempo esse aumento de escopo dentro da iteracao nao é desejavel e deve
se normalizar ocm o tempo.»* Then he amended: *«em resumo: as metricas da iteracao no gitlab vao mostrar
o que aconteceu.»*

**Read the three as one decision with a shape**, because taken singly the second reads as a shrug: the
behaviour is **not preventable**, growth inside an iteration is **accepted and not endorsed**, and the
signal that it is normalising is read **off the tracker** rather than off any instrument this repo
authors.

### The decision

1. **A `loop` Issue is filed into the ACTIVE iteration, at filing, in the repo it is filed in.** Carrier:
   `commands/new-issue.md`'s *Open it* step. Before this the command set no milestone at all —
   `grep -c "milestone" commands/new-issue.md` returned `0` — so every `loop` Issue was born outside the
   pool `/autonomy on` can see, which is the defect the rule closes. Scope is `loop` and only `loop`:
   widening it to every type moves planning into the capture command, a decision nobody has made.
2. **The drain's terminal set is the pool AS IT STOOD AT ENTRY** — a snapshot of issue **numbers**, taken
   once, held as session state for one invocation. Carrier: `commands/autonomy.md`. Two properties are
   load-bearing rather than incidental. **Numbers, not a count**: a count is satisfied by an arrival
   replacing a closed item, so the drain would work an item it never admitted while the arithmetic still
   matched. **Re-taken fresh per invocation**: a second `/autonomy on` in the same iteration picks up
   everything the first did not take, so the snapshot **defers and never drops** — which is also why it
   needs no durable home, and why the constraint the twenty-second amendment's slice measured (a milestone
   description is not readable from here, so a description edit leaves no trace) does not reach this
   design.
3. **No arrivals instrument is built**, on his amendment. The drain does not report how many items joined
   after it started.

### The measurement his third clause needed, and why nothing was built for it

**One fact, recorded as a fact.** These repositories are on **GitHub**, whose milestone view shows
open-versus-closed and a completion bar and **does not show when an item joined a milestone** — the exact
quantity *«deve se normalizar com o tempo»* is about. GitLab iterations carry that history natively. So on
this tracker the growth is visible as a **moving denominator** rather than as an event. That is a
constraint on what the tracker can show, not an argument for building around it; he was told and settled
it.

**The growth does surface, and it surfaces for free.** An Issue that arrives mid-drain carries no `sp:`
label and, on the `loop` lane, no `ready` — both are existing **preflight** pendency classes. So the
*next* invocation refuses to enter and surfaces them one at a time. Nobody writes that report; it is the
existing preflight meeting the new filing rule.

### Considered options

1. **Narrow the rule to filing time** (`agents-lead`'s proposal at intake) — a `loop` Issue the owner
   files during iteration N joins N, a `loop` finding surfaced by a slice inside N joins N+1. **Rejected
   by the owner**, and the rejection is the interesting part: the line is unobservable. Nothing in the
   tracker distinguishes an Issue born of the owner's ask from one born of a slice's finding, so the rule
   would have been a discipline whose violation no gate and no reader could ever see — a stricter rule
   with strictly less evidence behind it than the loose one.
2. **Accept the growth and leave exhaustion as the terminal condition.** Rejected as incoherent: `loop` is
   the class generated by working, so the drain's stopping condition would recede as the drain runs. That
   is #103's argument arriving one layer down, and #103 is the reason `/autonomy on` has a
   terminal-condition section at all.
3. **Persist the snapshot in the tracker** — a milestone description, or a comment on the iteration Issue.
   Rejected twice over: the milestone description is not readable from here, and the iteration Issue does
   not exist yet. **And it would be worse if it worked** — a persisted snapshot needs an invalidation rule
   for the second invocation, which is exactly the question that kills a snapshot, and session state
   answers it by having nothing to invalidate.
4. **A detector, as the closing-artifact slice built for its own rule.** Rejected on precision rather than
   on cost: the only mechanically checkable signal — *the drain reported exhaustion while the iteration
   still holds open `ready` items* — is **true of every correct snapshot termination that saw an arrival**.
   A detector with zero precision by construction trains its reader to ignore it, which is worse than none.

### Consequences

**Good**
- **Both of the owner's asks hold at once**, which neither option managed alone: items join the active
  iteration on arrival, and the drain still terminates.
- **The terminal condition is true by construction rather than by policy.** A set of numbers fixed at
  entry is exhausted by working it; it does not depend on anyone refraining from filing.
- **Two unknowns the Issue flagged are closed by measurement.** `gh issue edit --milestone
  "<nonexistent>"` **fails loudly** — exit 1, `'<name>' not found`, the issue unchanged — so a bulk
  assignment cannot appear to succeed and not have. And the pool predicate returns `sprint-01` in **both**
  repositories, so the bootstrap the Issue called blocking is discharged, and *"the current iteration is
  two objects"* is now a concrete pair of milestones sharing a title rather than a hypothetical.

**Bad**
- **The closing ceremonies run against the ITERATION, not the snapshot**, so an iteration that grew
  mid-drain is closed holding items the drain never admitted. That is what the accepted behaviour looks
  like from the closing end. No mitigation is proposed.
- **Nothing observes the snapshot.** No artifact records it, so a drain that terminated against its
  snapshot, one that terminated against the live pool, and one that quietly dropped an item are
  indistinguishable from the tracker and from the diff. Same residual, same wording, as the twentieth
  amendment's — every `gh issue` call in `hooks/scripts/` is a write path.
- **A `loop` Issue filed with the wrong milestone, or with none while one existed, is equally invisible.**
  The `--milestone` failure is loud; *selecting* the wrong iteration is silent, which is why the carrier
  enumerates from the items instead of naming.
- **The trend is unmeasured, by decision.** *«Deve se normalizar com o tempo»* has no instrument, and a
  moving denominator on a milestone bar is a weak reading of it. Recorded so that if watching the bar
  turns out not to be enough, the gap is known to be one paragraph of a report rather than a mechanism.
- **The same phrase-keyed coupling as the twentieth and nineteenth**: three new arms in
  `inventory-counts.test.sh` key on sentences, so rewording reddens the gate and whoever rewords edits the
  needles in the same commit. One arm is **line-anchored** rather than fixed-string, because the retired
  #326 bullet is kept struck in the file and `grep -F` would have matched the preserved copy — a negative
  arm that passes with the rule live again is the failure mode it exists to catch.

**Deciders:** the owner (both rulings); written by `agents-lead` per the #223 domain split — a pure
loop/machinery decision, no product-architecture stake, no `tech-lead` co-citation owed. The snapshot's
shape, its rejection of a durable home, and the detector's rejection were closed inside the loop and are
labelled as such rather than attributed to him.

## Amendment (2026-08-29, twenty-fourth) — the iteration's `loop` block MAY be carried as one branch and one MR; "one batch per iteration" is not adopted

**Why this is an amendment and not record 0022.** This capability's own index entry claims *"the shape a
unit of work takes (Issue, child task, branch, PR)"*, and the delivery unit for `loop` work is exactly
that. #283's design is **one document per capability name**, so a new number here would create a second
`roster-and-dev-loop` document — the arrangement that reconciliation exists to remove. The twentieth
amendment declined a new record on the same reasoning and is the precedent, not a coincidence. **The
#223 domain split governs WHO writes, not whether a number is issued**, and this is written by
`agents-lead`.

**The ask, and what was adopted from it.** The owner's specification (#357) proposed a *Loop Batch*: the
iteration's `loop` items planned individually and delivered as one integrated reconfiguration — one
branch, one MR, one bump, one tag, one integral QA verdict, one consumer reinstall, plus an authored
traceability matrix, plus *"faça enforcement se necessário"*. **The composition half is adopted as a
permission. The prohibition half, the matrix, the reinstall step and the enforcement are not.**

### The decision

1. **An iteration's eligible `loop` items MAY be carried as one branch and one merge request.** They are
   still planned individually — each keeps its Issue, its `sp:N` and its position in the ordered body —
   and commits stay separated per issue so the delivery is navigable. Carrier:
   `skills/agents-configuration/SKILL.md`, section *The `loop` block MAY be carried as one branch and one
   MR*; pointers in `commands/autonomy.md` and `commands/new-issue.md`.
2. **It is a PERMISSION exercised by the owner at planning.** The default is unchanged and per-item.
   Nothing composes a batch automatically and no drain may infer one.
3. **"One Loop Batch per iteration" is NOT adopted**, and more than one batch per iteration is normal.
4. **Nothing is enforced.** No gate, no hook, no deny. The only new gate arm asserts the rule is
   **written**.

### Why the headline clause was refused — false by construction, not merely unwanted

**A branch does not cross repositories, and the iteration already does.** Measured 2026-08-29:
`sprint-01` is milestone **1** in `tadeumendonca-io` (#556, #516) and milestone **2** in
`tadeumendonca-skills` (#313, #357, #358), the two paired by nothing but a hand-written title. The moment
an iteration's `loop` block spans both trees, *one branch / one MR / one bump / one tag / one integral
review* is two of each, and the model must tolerate that rather than imply it away.

**This is one development effort.** The owner, 2026-08-29: *«nao existe separacao no desenvolvimento do
skills e do io»*. What is two is the tracker's representation and git's unit of integration — both
limitations, neither a design. **The `loop` block being single-repo today is a fact about CONTENTS**: the
product repo has never carried a `loop` item (`--state all --label loop` → **0**) while its label set
already provisions `loop` and the full `sp:` class. Every rule here is written to survive the day that
changes.

**Second, independent reason: one batch per iteration removes the installable intermediate.** Every merge
publishes a version ([ADR-0005](./0005-plugin-auto-versions-on-merge.md)), so per-item the window between
*a rule merges* and *it can take effect* is bounded by the owner's next update. Under a whole-iteration
batch there is **no installable intermediate by construction**, and the iteration's entire `loop` work is
authored and reviewed under the pre-batch configuration. This iteration shipped `hooks/scripts/preflight.sh`,
a hook that can refuse a prompt; batched, it would have sat inert while the rest of the batch was built
against sessions it was written to stop.

### What the batch actually buys, and what it costs — the arguments were re-derived, not accepted

**It buys a conflict-and-rebase saving and nothing else.** Distinct issues per file over
`v1.1.35..origin/main`, generated and version-carrier files excluded: **7** touched
`hooks/scripts/inventory-counts.test.sh`, **5** touched `skills/harness-engineering/SKILL.md`,
`docs/blueprint-registry.md` and `README.md`, **4** touched two records. N serial slices each rebase on a
base the previous one just moved; a batch pays that once.

**The Issue's two other arguments do not hold.** *Nine releases in one night* is not a cost the batch
removes — publishing is not adoption, and the nine intermediate versions were nine chances to adopt, all
of which the batch deletes. *Repeated reinstalls* is the same claim; one update instead of nine was
always available as the owner's choice, and was in fact exercised mid-review (1.1.44 → 1.1.45).

**It costs the ability to ship in part.** `git merge-tree --write-tree --merge-base=<commit> HEAD <commit>^`
— the computation `git revert` performs — was run against two of this iteration's `loop` commits and
conflicted in **7** files and **5** files respectively. One `REQUEST-CHANGES` therefore leaves the
iteration's whole `loop` block unshipped, and the implied escape is a hand-resolved conflict in the files
carrying the loop's own rules. Only the **last** issue's commits are cheap to drop. **The two bounds are
compositional and both are discipline:** order by risk, keep batches small.

**And it trades review rather than preserving it.** A small diff buys a **reviewable premise**; nothing
reproduces that inside a batch-sized diff, and a matrix is navigation, not a ruler. Favourable for
documentation-shaped `loop` items, unfavourable for hook-shaped ones.

### Considered options

1. **Adopt the composition half as a permission.** *(Chosen.)*
2. **Adopt the specification as written, including "one batch per iteration".** Rejected: false by
   construction across repositories, and it deletes the installable intermediate for the whole iteration.
3. **Reject the model outright and keep per-item delivery mandatory.** Rejected: the overlap measurement
   is real and the saving is real; forbidding the shape would price a measured benefit at zero.
4. **Build the enforcement the specification asks for.** Rejected on a layer walk, not on cost —
   see below.
5. **Adopt the derived commit ↔ issue coverage check in this slice.** Rejected as scope: it is a separate
   decision with a red gate and a convention behind it, and it is worth building whether or not any batch
   is ever formed.

### Why no layer can carry it — [ADR-0004](./0004-controls-and-enforcement.md)'s standing question, answered

`permission-guard.sh` and `wip-guard.sh` read a **command string**, and `gh pr create` for a second `loop`
PR is character-identical to the first. `wip-guard.sh` additionally lists only **open** PRs, so under
WIP=1 the previous `loop` PR is already merged and there is nothing to overlap with — it bounds
concurrency, never count-per-iteration, and it never fired once across this iteration's nine `loop`
slices. A `PreToolUse` deny would have to resolve a branch to an Issue (a suffix heuristic measured at
**11 of 12** on this repo's recent PRs), read its labels and milestone, and query merged PRs — two to
three network calls inside a hook whose file-level posture is **fail open**. **A control that fails open
on every lookup failure, keyed on a heuristic that misses one in twelve, denying an act with a legitimate
exception, reads as enforcement and behaves as advice.** That is the shape the twenty-second amendment
rejected, and it is rejected here on the same evidence.

**The deeper reason, which does not expire with any measurement:** a `PreToolUse` or `Stop` hook receives
**one `cwd`** and therefore sees **one repository**, while the iteration is not a repo-scoped object.
**No single-repo hook can observe the iteration at all, whatever any repo contains.** The twenty-second
amendment's *zero true positives* figure is a symptom of that; this is the cause, and this amendment
restates it in the durable form in the carrier as well.

### Consequences

**Good**
- **The measured benefit is available and the false clause is not shipped.** The saving that survives
  scrutiny is permitted; the claim that could not hold is refused with its refutation recorded.
- **Admission needs no new mechanism.** The specification's *"only by explicit owner decision"* is
  already spelled `ready` — the owner's transition alone on this lane, and required by the pool
  predicate. Building a second control would have duplicated an existing one.
- **A permission has the least to lose from being unenforced.** An unenforced prohibition can be
  violated; an unenforced permission can only be declined.
- **It reconciles with the twenty-third amendment without reopening it.** That amendment governs the
  **iteration**; this governs the **branch**. Different objects, no collision.

**Bad / accepted costs**
- **The `agents-lead` verdict marker is a PRESENCE check, not a head check, and a batch makes that
  matter.** Rule 7c head-scopes only the **gatekeeper's** verdict (`headRefOid`, fail-closed since
  #341); nothing does the equivalent for `harness-lead-verdict`, and `agents/quality-assurance.md`'s
  hold 2 reads *"a comment on the PR before you may merge it"*. **On a branch that lives a whole
  iteration, a marker from the first commit satisfies hold 2 for the entire batch.** Recorded as a named
  residual and deliberately **not** repaired here: the repair is an added condition inside the merge
  floor, which is its own change and touches the irreversible boundary.
- **The active iteration is derived per repository and nothing checks the two derivations agree.** The
  predicate returns a milestone *number* (1 and 2 today); only the hand-written **title** pairs them, so
  `sprint-01` against `sprint-1` gives two successful derivations, two healthy-looking pools, and one
  iteration silently become two. **Judged and deferred rather than folded in:** the cheap-looking
  detector — derive in both trees at session open and compare titles — must first discover the sibling
  tree (ADR-0004 calls that *"a heuristic and the weakest part"*) and then pair by the very string whose
  agreement it is verifying. A detector that assumes what it checks is not a detector.
- **The one genuinely enforceable clause is deferred, by name.** A derived commit ↔ issue coverage check
  — every closed issue has a commit naming it, every commit names an admitted issue — is computable from
  objects that already exist and needs no PR-body parsing. Measured cost at head: **17 of 21** non-`bump`
  subjects carry a `(#N)`, so it reddens on honest work until the convention closes.
- **Step 6 has no mechanism and none is proposed.** There is no install path; `powers/` is a generated
  export, not an install route, and `session-plugin-version.sh` compares a **version string** rather than
  tree contents. The specification's *"cópias instaladas idênticas ao manifest"* does not translate.
- **The same phrase-keyed coupling as the last four amendments.** The new arm keys on sentences, so
  rewording reddens the gate and whoever rewords edits the needles in the same commit.
- **Nothing observes composition.** A batch, a per-item run, and a batch that quietly dropped an issue
  are indistinguishable from the tracker and from the diff. The arm asserts the rule is written; it
  cannot assert a session obeyed it.

**Deciders:** the owner (the ask, and the *«nao existe separacao»* framing); written by `agents-lead` per
the #223 domain split — a pure loop/machinery decision, no product-architecture stake, no `tech-lead`
co-citation owed. The narrowing, the four refusals and the two deferrals were closed inside the loop
against the owner's stated intent, and are labelled as such rather than attributed to him. Driven by
[#357](https://github.com/tedeuxx/tadeumendonca-skills/issues/357).

## Amendment (2026-08-29, twenty-fifth) — WIP=1 stands, and what it protects is recorded: the working tree, which no hook in this harness observes

**Why this is an amendment and not record 0022.** WIP=1 is the delivery discipline of *the shape a unit
of work takes (Issue, child task, branch, PR)* — this capability's own index entry — and the twelfth
amendment already records the WIP bound here. #283's design is **one document per capability name**, so
a new number would create a second `roster-and-dev-loop` document, which is the arrangement
reconciliation exists to remove. The twentieth and twenty-fourth amendments declined a new number on
the same reasoning and are the precedent. **The #223 domain split governs WHO writes, not whether a
number is issued**, and this is written by `agents-lead`.

**What the Issue asked for and what it became.** [#343](https://github.com/tedeuxx/tadeumendonca-skills/issues/343)
was filed to **reverse** WIP=1 — the twelfth amendment names the route (*"an explicit owner decision,
recorded the same way"*) — with the reversal's own precondition attached: the reason for the rule was
never written down. **The owner declined the reversal on 2026-08-28** (*«por enquanto siga com a regra
de wip»*) and re-scoped the Issue himself to the recording half. So this amendment reverses nothing.
It closes the twelfth amendment's residual on the only half that can be closed by a document, and
corrects the twelfth amendment's claim about the other half.

### The decision

1. **WIP=1 stands, unchanged: one worktree, one in-flight branch, one open PR.** No reversal, and the
   `ready` label was withheld on the reversal at the time the owner answered.
2. **What the rule protects is recorded** in `skills/agents-configuration/SKILL.md`, section *What
   WIP=1 is PROTECTING*, in **three separated layers** — the owner's quoted words, the measured
   failure, and what is still unrecorded — because they are not equally strong and blending them turns
   a reconstruction into a citation.
3. **`wip-guard.sh` is stated, in the universal preload, NOT to enforce WIP=1.** Two independent
   measurements carry it, and the section says plainly that the rule is held by instruction alone.
4. **The twelfth amendment's remedy clause is struck** — *"closing the gap is a `wip-guard.sh` change,
   not a docs one"* is true of the count half and false of the checkout half.
5. **Nothing is enforced, and no new mechanism is proposed.** The one new gate arm asserts the
   recording is **written**.

### What was measured, and what is a report rather than a measurement

**Measured at head, 2026-08-29.** `wip-guard.sh` reads `gh pr list --state open --author @me`, so
under WIP=1 the predecessor is already merged, the list is empty, and the script exits before
computing a single path. Across the fourteen most recent merged PRs in this repository — the whole
`sprint-01` `loop` block and its neighbours — **not one had another PR of the same author open at its
creation instant**, so the overlap loop never ran across nine consecutive `loop` slices. The command
is published in the carrier beside the claim. *Bounds:* one repository, fourteen PRs, and `--author
@me` excludes bot PRs by construction.

**Measured, second and independent.** `grep -c worktree hooks/scripts/wip-guard.sh` → **0**. It derives
its own side from `git diff --name-only` in whatever directory it runs in, so two agents in one
checkout produce the same answer and it cannot distinguish them. Three sibling hooks —
`dispatch-premise-guard.sh`, `zombie-loop-detect.sh`, `orchestrator-tool-census.sh` — do reason about
worktrees explicitly, so this is a property of this guard rather than of the harness.

**REPORTS, not measurements, and the carrier's own heading now says so.** The owner's comment on #343
enumerates what this record must capture *"from evidence rather than reconstruction"*, and **both of its
concrete instances are carried**: the **2026-08-28** collision — two slices in one checkout, a reviewer's
measurements landing against `main`, a builder's fixes landing on the wrong branch's tree, both found by
accident — and, **earlier, a mutation probe left applied to `apps/fed/src/data/profile.ts` while three
agents shared one branch**. Nothing was re-derived from git, and layer 2's heading reads *"from EVIDENCE
rather than reconstruction"* rather than *"measured"*, so it cannot borrow the authority of the two
figures above. **It read *"measured rather than reconstructed"* for one round**, four lines above the
sentence conceding it was a report — this document's own row-0007 defect, reproduced in a heading.

**The second instance is why layer 2 is not n=1, and it carries the structural reason both are
unmeasurable.** An uncommitted edit left applied to a shared working tree produces no commit, no diff
and no ref naming it: `git log --oneline --all -S "MUTATION" -- apps/fed/src/data/profile.ts` at head
returns **nothing**, because the probe was never committed and no commit can carry what was never
committed. **The failure class is invisible to git by construction**, so the
absence of an instrument reading is a property of the failure rather than a shortfall of this slice —
and *"discovered by accident"* is the only discovery route that exists for it. On that instance the
guard is worse than merely permissive: three agents on one branch share one path list, so there is no
second PR to intersect against at all.

### Why no layer can carry it — [ADR-0004](./0004-controls-and-enforcement.md)'s standing question, answered

**It is a MOMENT problem, not a matcher problem, and that is what makes it different from the twenty-second
and twenty-fourth amendments' answers.** Those refused an enforcement because the *predicate* was
unavailable to any layer. Here the predicate is trivially available — *is another agent already working
in this checkout* — and the layer that would carry it is a `PreToolUse` on `gh pr create`, which is the
**last** act of a slice. The 2026-08-28 failure completed during the build, hours earlier: a
measurement read off the wrong branch, an edit written to the wrong tree. **A control at the merge
boundary cannot observe a failure that finishes before the boundary is reached.**

**A control at the right moment would have to be a lock on the checkout at the first write**, which is
neither `wip-guard.sh` nor a change to it, and is not proposed here: it would need a durable lease with
an owner, a holder identity a subagent cannot forge, and a release path for a crashed session — none of
which exist, and all of which are a mechanism rather than a rule. **Named as owed and left owed**, which
is the honest form and the one the struck clause failed to take.

### Considered options

1. **Record the reason in three separated layers and correct the twelfth amendment's remedy clause.**
   *(Chosen.)*
2. **Reverse WIP=1 as the Issue's title asks.** Not available — the owner declined it, and his stated
   precondition (personas and skills not yet equalised across his other harness projects) is not
   something this loop can argue past.
3. **Reconstruct a single coherent purpose from the three owner statements.** Rejected, and this is the
   substantive call in the slice. #88 argues against a count, the 2026-08-13 correction imposes one,
   and the 2026-08-28 answer keeps it while naming an unrelated precondition. A synthesis would read
   as his rationale while being the loop's — the substitution this document's own *Deciders* convention
   exists to prevent, which is why the line below labels each closed-inside-the-loop call as one.
4. **Build the checkout lock.** Rejected as scope and as shape — see the layer walk above.
5. **Change `wip-guard.sh` to deny on a count.** Rejected: it would satisfy the written policy at the
   PR boundary while leaving the measured failure untouched, and #88 records the owner rejecting a
   count with a reason. It buys the appearance of enforcement for the thing that never broke.

### Consequences

**Good**
- **The proposal the owner asked for is now evaluable.** Its precondition was a written purpose; there
  is one, with its three layers marked by strength.
- **A reader can no longer infer enforcement from the hook.** The preload states in its own words that
  `wip-guard.sh` does not enforce WIP=1, with two falsifiable measurements attached.
- **A false remedy is off the books.** The twelfth amendment promised the gap away as a pending hook
  change; that promise is struck where it was wrong, and struck rather than deleted.

**Bad / accepted costs**
- **The rule's actual purpose is still unrecorded, and layer 3 says so.** What is recorded is what the
  rule *catches*, not what the owner *wanted caught*. If the answer is *"I want to see every change as
  it happens"*, no isolation tooling satisfies it — and this record cannot close that.
- **WIP=1 remains held by instruction alone.** By this loop's own test it is not engineered, and the
  2026-08-28 collision is what that costs against a fresh context that never had the instruction. No
  mechanism is proposed and the gap is left named.
- **The fourteen-PR figure ages.** It is a fact about this repository's recent history, not a property
  of the hook; the property is the `--state open` read, and the carrier states both so the conclusion
  does not expire with the sample.
- **Both instances are reports and can only ever be one.** They were discovered by accident, and the
  second shows why: an uncommitted edit on a shared tree leaves no commit, no diff and no ref, so the
  class is invisible to git by construction. The carrier's honesty about that is the whole of the
  mitigation, and layer 2's heading is where it has to be visible.
- **The record post-dated its own source for one round**, dating the owner's answer and the collision
  from the authoring session's clock rather than from the comment reporting them (`createdAt`
  2026-08-28). The rule that prevents it — **an event is dated from the artifact reporting it, a
  measurement from the day it was run** — is now written in the carrier, where the next author meets
  it. Nothing enforces it and no instrument can: a plausible date is indistinguishable from a true one
  to every check in this repository.
- **Every enumeration of that defect has been short, including this record's own, and that is the
  finding rather than an aside.** The review named a set; the correction named a larger one and **got
  its own arithmetic wrong** — two slots claimed, three items listed, and a fourth occurrence in this
  amendment's own *Considered options* paragraph corrected in the same commit without appearing in
  either list. **So no count is published beside the rule at all.** Selected by the criterion above —
  *every date naming the owner's answer or the collision* — the members are mechanically re-derivable
  by anyone, in either tree, at any head; the chewed total is the only part that was wrong, and it was
  wrong every time it was stated. **This bullet is the one place in the round that did not follow the
  rule the bullet above it states**, which is why it is written as a correction rather than as a
  reflection.
- **The same phrase-keyed coupling as the last five amendments.** The new arm keys on sentences, so
  rewording reddens the gate and whoever rewords edits the needles in the same commit.
- **Nothing observes WIP.** A session that ran two slices in one checkout and one that ran one are
  indistinguishable from the tracker and from the diff. The arm asserts the recording is written; it
  cannot assert a session obeyed the rule it records.

**Deciders:** the owner (WIP=1 stands, and the re-scoping of #343 from reversal to recording); written
by `agents-lead` per the #223 domain split — a pure loop/machinery decision, no product-architecture
stake, no `tech-lead` co-citation owed. The three-layer separation, the strike of the twelfth
amendment's remedy clause and the refusal to synthesise a purpose were closed inside the loop and are
labelled as such rather than attributed to him. Driven by
[#343](https://github.com/tedeuxx/tadeumendonca-skills/issues/343).

## Amendment (2026-08-30, twenty-sixth) — an iteration closes with a retrospective rite; ~~the sprint review half is refused for now~~ **REVERSED 2026-09-02 by the thirtieth (#379)**

**Why this is an amendment and not record 0022.** It decides *what happens at the end of an iteration*,
which is the same capability the iteration axis itself was recorded under (#326, the twentieth
amendment) and the same document that already holds the composition rules the rite's output feeds
(#338, #339, #357). #283's design is **one document per capability name**; a new number would create a
second `roster-and-dev-loop`. Written by `agents-lead` per the #223 domain split — pure loop machinery,
no product-architecture stake, no `tech-lead` co-citation owed.

**The owner's sequencing governs the shape of this amendment.** Asked to run the rite ad hoc on
2026-08-29, he stopped it: **«primeiro quero garantir os mecanismos e automatizacoes corretamente
implementados»**, and on running it, **«depois a gente foca em executar ele no final do sprint atual»**.
So this records a mechanism that **has not been run**. Doing it once by hand does not create the rite,
and a rite whose first execution predates its definition has no definition to be executed against.

### The decision

1. **`commands/sprint-retrospective.md` is the rite**, typed by the owner and named by `/autonomy on` at its
   terminal condition. Trigger, scope, output and close are four things, decoupled: **the trigger is
   the drain's entry snapshot going empty; the scope is the iteration as it stands at that moment; the
   output is a proposal; the iteration's close stays the owner's, at planning.**
2. **The consult set is DERIVED from the dispatch records the loop already leaves**, never a fixed
   roster, and it is **a lower bound**. Measured across `sprint-01` in this repository: **six of seven
   personas ran; `content-reviewer` ran zero times.**
3. **Each consulted persona is fed its OWN artifacts** and reasons from them. This is the decision that
   makes the rite worth having: isolation without evidence relocates the orchestrator's bias into N
   contexts rather than removing it.
4. **The artifact is one tracked file PER persona**, `docs/retrospective/<iteration>/<persona>.md`, and
   the split is mechanical rather than cosmetic — a shared file would put every earlier answer in the
   next persona's context, so the isolation would survive the dispatch and die at the write.
5. **A cap of two findings per persona lives in the artifact template.** It is checkable by reading and
   by nothing else, and the rite says so in those terms.
6. ~~**The sprint review half is NOT built**, and the deferral is recorded inside the rite rather than in
   a tracker comment, so the second half of *"the closing ceremonies"* cannot read as satisfied.~~
   **REVERSED 2026-09-02 by the thirtieth amendment (#379): it is built, `commands/sprint-review.md`,
   driven by `product-lead`, and it runs FIRST of the three.** Struck in place rather than deleted
   because this item is what told every reader for three days that the half was refused. **The two
   grounds behind the deferral were SATISFIED rather than lifted** — the rite ships no route list and
   is not a gate — which is why the thirtieth amendment is a reversal of this decision and not of the
   reasoning under it.
7. **`agents/quality-assurance.md`'s Write rule gains its first exception, and a bound.** The two
   states, quoted as they are rather than as the change felt. **Before:** three occurrences already
   read *"a Write to any repo path is a defect **in the review**"* — in the description, in the
   working-files section and in the tool-discipline section — and the rule was nonetheless **absolute**,
   because nothing anywhere named a case where a repo write was legitimate, so the qualifier read as a
   context noun rather than as a scope. **After:** the retrospective is named as the one exception and
   the **dispatch** rather than the path is what bounds it; the description's copy drops *"in the
   review"* in favour of stating the exception outright, and the other two occurrences are untouched.

   *An earlier form of this item said the narrowing ran "from `a Write to any repo path is a defect` to
   `…is a defect in the review`". That was inverted in both halves — the quoted AFTER is verbatim what
   `main` already said, and it occurs nowhere at this branch's head. Corrected before merge rather than
   left standing, because this document is where the next reader reconstructs what the rule used to say,
   and a record that misquotes the state it replaced is worse than one that says nothing.*

### What was measured, and what it corrects in this repository's own records

**The consult set is derivable, which falsifies the Issue's fourth open question** (*"nothing currently
records which were dispatched"*). `hooks/scripts/dispatch-metrics-stop.sh` posts one marker comment per
dispatch. **Three limits travel with it and are written into the rite rather than left in this record:**
the Issue number comes from the branch by a fragile grep (`fix/adr-0002-rewrite-355` yields `0002`;
`main` yields nothing, so every intake dispatch is unrecorded), `agent_type` is namespaced, and it is
per-repository. And the recorder exits 0 silently on about a dozen paths, so **a persona that ran and
left no comment is indistinguishable from one that never ran.**

**One claim in the universal preload was true when written and is false at head, and is struck rather
than quietly edited.** *"REVIEW cannot run unattended in this harness — no MCP server is reachable from
a dispatched subagent"* stopped being true on 2026-08-29, when `product-lead` gained a read-only
`chrome-devtools` subset with a bounded origin (PR #356). ~~**The review half is still refused, on grounds
that survive the new capability**: a route list rots, and a looker's finding has no ruler, so it must
never be a gate.~~ **Struck 2026-09-02 (#379): the half is BUILT, and both grounds were satisfied inside
the rite's shape rather than lifted — it ships no route list and it is not a gate.** The clause that
survives untouched is the one worth keeping: **the obstacle was never the browser.** The capability
arrived on 2026-08-29 and the rite was built three days later, by the persona it was granted to, on
those same two grounds.

**The amplification is a consequence of two rules merged three days earlier, and it is stated where the
rite is defined rather than here.** A retrospective finding is `loop`-typed, so it joins the **active**
iteration at filing (#338) and is composed **ahead of every product item** (#339). Fifteen findings do
not queue behind product work; they displace it, by rule. Plus roughly two estimation dispatches each
before the next drain may enter.

### Considered options

- **A skill rather than a typed command** — rejected on this repository's own rule that
  `argument-hint` is the contract and the distinction is semantic. The Issue's first open question asks
  what an iteration *drained by hand* gets; the answer is a human typing an iteration name, and an
  iteration name is an argument.
- **One skill holding both rites** — rejected. They share a trigger and nothing else, and one file with
  two halves would ship with one half real and one half a paragraph, which is the shape #337 exists for.
- **A comment on the Issue as the artifact** — rejected. `permission-guard.sh` rule 5e denies
  `product-lead`, `content-writer` and `content-reviewer` any public surface, so three of the seven
  could not post at all and relaying them through the orchestrator reintroduces the aggregation the
  isolation exists to prevent.
- **One shared file with a section per persona** — rejected on the write-time contamination above. It
  is the shape `docs/content-review/<slug>.md` uses, which is safe there only because one persona writes
  it.
- **Consulting all seven** — rejected on the measurement: one of them never ran.
- **A `Stop` hook firing the rite** — rejected, not deferred. Nothing in `hooks/scripts/` reads the
  queue, and a hook receives one `cwd` while the iteration is two milestone objects in two repositories
  paired by title alone.

### Why no layer can carry it — [ADR-0004](./0004-controls-and-enforcement.md)'s standing question, answered

| layer | can it hold *the rite ran, over the right iteration, within its cap*? |
|---|---|
| `permission-guard.sh` (`PreToolUse`/`Bash`) | **no** — it reads a command string; there is no command whose spelling differs between a rite that ran and one that did not. |
| a `PreToolUse` on `Write` | **no** — it sees a path, not a finding count, and not whether the dispatch was isolated. |
| a `Stop` hook | **no** — it cannot observe a snapshot going empty, because nothing here reads the queue; and it sees one repository. |
| `inventory-counts.test.sh` | **presence only** — it asserts the rite's rules are WRITTEN, which is what the five arms added here do, and all they do. |

**So the rite is held by instruction, and by this loop's own test — *would something stop me, or only my
memory?* — it is not engineered.** That is stated in the rite, in the drain, in the preload and in the
registry row, in four places, because the one failure this repository names most often is a control that
reads as installed and is inert.

### Consequences

**Good**
- The `/autonomy on` promise that has stood objectless since #326 now has half its object, and the other
  half is named as owed in the file that makes the promise.
- The improvement list stops being the orchestrator's, and stops being speculation, in the same move.
- `sprint-01` closed with no rite at all; the next iteration has one to close with.

**Bad / accepted costs**
- **Nothing fires it and nothing observes it.** A skipped rite, a rite over the wrong iteration and a
  rite with three of six personas are indistinguishable from the tracker.
- **The cap is a template, not a bound.** Twelve proposals per iteration displacing product work by rule
  is the designed-for case; nothing prevents thirty.
- **The gatekeeper's absolute Write rule became conditional**, and a conditional rule is the shape that
  erodes. The bound is the dispatch, and the bound is prose.
- **The retrospective costs a branch, a PR and a gate pass.** Correct rather than regrettable — it is a
  `loop` diff — but it is not free, and it lands at the moment an iteration is trying to close.
- **The rite may fire twice per iteration**, once per repository drain, and nothing can prevent it. The
  per-persona files are what make the second firing idempotent rather than duplicative.
- ~~**The sprint review half stays unbuilt**, so the three defects that motivated the Issue — all found by
  the owner opening the running site himself, all through every green gate — remain uncaught by anything
  in this loop.~~ **Struck 2026-09-02 (#379): the half is built and `/sprint-review` is aimed at exactly
  that class.** The residual is NARROWER rather than gone, and the narrowing is what the rite claims:
  the three defects were found on a **real phone** and the sweep emulates one, so the class is covered
  by a mechanism that declares itself a **lower bound** rather than by nothing at all.
- **The same phrase-keyed coupling as the last six amendments.** The arms key on sentences; whoever
  rewords edits the needles in the same commit.

**Deciders:** the owner (the rite as a ritual, the drain's exhaustion as its trigger, isolation as its
mechanism, and mechanism-before-execution); written by `agents-lead`, whose own intake stress test on
[#355](https://github.com/tedeuxx/tadeumendonca-skills/issues/355) is the source of the narrowing, the
derived consult set, the artifact choice and the refusal of the review half. The command-versus-skill
call, the per-persona file split and the `quality-assurance` narrowing were closed inside the loop and
are labelled as such rather than attributed to him.

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

**Corollary 1 (record 0012) — the `/autonomy on` queue predicate is `(product OR loop) AND ready`.**
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

- **Mechanically enforced, for ~~exactly two acts~~ ~~THREE acts~~ TWO acts again — merge and direct
  push to the trunk.** ~~and
  (since #319, 2026-08-23) editing a file inside a git working tree.~~ **Struck 2026-08-31 (#386):
  `orchestrator-write-guard.sh` is deleted and its registration removed, so the third act has no
  carrier and the count is two.** The strike is sited here, under *The decision, as it currently
  binds*, because that heading is what a fresh context reads as present tense — `CLAUDE.md`'s copy of
  this same sentence was struck in the slice that deleted the hook and **this original was not**, which
  is the CITED-vs-STATED class this repo has now paid for twice in one PR.
  `hooks/scripts/permission-guard.sh` leaves `agent_type` **empty** for the main agent by design, and
  rules 7 (trunk push) and 7b (merge) fire against that empty value. ~~The third act is enforced by a
  different hook on a different matcher — `hooks/scripts/orchestrator-write-guard.sh`, registered on
  `Edit|Write|MultiEdit|NotebookEdit` — because `permission-guard.sh` runs on the `Bash` matcher and
  returns immediately on a payload with no `.tool_input.command`. It is a **routing** rule rather than
  a floor one: the identical edit is allowed the moment a persona makes it, and every non-empty
  `agent_type` passes through untouched.~~ **The `Bash`-matcher fact in that struck passage is still
  true and still load-bearing** — `permission-guard.sh` cannot see an `Edit`/`Write` call at all — so
  what the deletion leaves is not a rule moved to another layer but **no layer**, which is the honest
  reading and the one *The coupled removal* section below argues for. See
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
a harness scenario is frequently reviewed before any PR exists. **NARROWED 2026-08-28 by the
twenty-first amendment (#336) on the owner's ruling: the marker comment lives on the PR and nowhere
else** — the SHA clause above is untouched and still binds, but *"`agents-lead`'s output becomes an
`<!-- harness-lead-verdict: … -->` comment"* no longer holds for the **intake** case this corollary's
own *"before any PR exists"* was written about. There the output is a plain Issue comment with no
envelope. `agents-lead` is deliberately **not**
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
  `/autonomy on` predicate, `new-issue.md`'s label step, `quality-assurance`'s boundary-class criterion,
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

## Amendment (2026-08-30, twenty-seventh) — nothing is admitted into a running iteration automatically; the twenty-third amendment's decision 1 is REVERSED

**Status:** accepted · **Deciders:** owner (decision), written by `agents-lead` (loop/machinery domain,
#223) · **Issue:** #365, `loop`, boundary · **the control layer is recorded in
[ADR-0004](./0004-controls-and-enforcement.md)'s 2026-08-30 amendment**, which is where *which layer can
hold this* belongs and is not restated here.

**This amendment reverses decision 1 of the twenty-third amendment.** That decision — *"a `loop` Issue is
filed into the ACTIVE iteration, at filing, in the repo it is filed in"* — is struck. It stood for one
day. It is reversed rather than rewritten, per this library's convention, because someone built on it:
`commands/blueprint.md`'s adoption step was written against it six hours after it merged, and
`commands/sprint-retrospective.md` justified its own trigger on it the next day.

### The owner's rule

> *«review e retrospective geram issues somente ao final do sprint e submetidos a priorizacao do backlog
> do proximo. itens nao podem ser criados dentro do sprint automaticamente sem verificacao HITL. isso
> precisa de enforcement acho. pois desconfio que vc nao esta seguindo isso.»*

**His suspicion was right about the mechanism and wrong about the cause, which is the more useful
finding.** Nothing had been auto-admitted — measured — but not because anything refused it: the pool
predicate returned empty at those filings, so **there was no active iteration to admit into.** Had one
`ready` item remained, both Issues filed that day would have been admitted by rule, with nobody asked.
The rule held by luck.

### Why #338 loses on a measurement rather than on a preference

The Issue frames this as *which of two rules wins*. It is not a contest: **#338's own failure mode cannot
occur.** Its argument was that a `loop` Issue born outside the pool is invisible to `/autonomy on` and
silently never worked. The pool is `(product OR loop) AND ready AND active-iteration`, and a `loop` Issue
is filed **without `ready`** — the owner's transition alone (Corollary 4). **The item falls out of the
pool on the `ready` predicate before the milestone predicate is consulted.**

So the milestone set at filing was inert until he acted, and when he acted he was present. **It changed
exactly one observable thing — the running iteration's contents and its completion bar** — which is
precisely the scope change he objects to. It bought nothing and cost the objection. He had already
applied the new rule by hand, removing #357 from `sprint-01` (*«a principio isso nao deveria influenciar
a iteracao corrente»*); that was read as a one-off and was the rule appearing for the first time.

### The decision

1. **No Issue is filed with a milestone, for any type.** Composition into an iteration is the owner's act
   at planning. Carrier: `commands/new-issue.md`'s *Open it* step.
2. **The rule is enforced, not merely written** — `permission-guard.sh` rule 10, denied to every
   dispatched persona and asked of the orchestrator. **This is the first rule in this family to reach
   prevention**, and the reason is in ADR-0004's amendment: the wall that forced #337, #339 and #363 into
   detection is a property of guards that must *know*, not of guards, and one that may **ask** does not
   have to.
3. **The scope is the ADMISSION, never the creation.** `gh issue create` without a milestone is untouched
   and rules 5c/5d are unchanged.

### What SURVIVES the twenty-third amendment, and it is the half most likely to be swept away with it

**Decision 2 — the drain's terminal set is the ENTRY SNAPSHOT — stands.** The two decisions arrived in
one commit and read as one; they are not. The pool still grows while it drains, for reasons #338 never
owned: the owner admits items at planning, `blocked` clears, `ready` lands mid-drain. **#338 was one
contributor, never the premise**, so reverting it does not restore *"the iteration's pool is exhausted"*
as a terminal condition and the twentieth amendment's decision 3 stays reversed.

### The ripple, discharged in this slice rather than named

`commands/new-issue.md` (the act) · `skills/agents-configuration/SKILL.md` (the preload) ·
`commands/blueprint.md` (the adoption step, whose *"where the two rules conflict, the local rule wins"*
paragraph is struck — its **reasoning** was the defect, and precisely: *"an adopted item with no
milestone is invisible to the queue"* is **true**, the pool predicate opening with
`select(.milestone!=null)`; what does not follow is that the milestone was worth setting, since the same
predicate also requires `ready`, which the item never gets, so it was invisible **either way**. **A true
premise carrying a false conclusion**, which the merge gate caught this authorship calling *"simply
wrong"*) ·
`commands/sprint-retrospective.md` (**the trigger justification, re-opened deliberately** — its rejected option
*"the iteration is empty"* rested on #338 and genuinely re-opens; it is re-decided on two grounds that
never depended on #338 rather than left inheriting a dead argument) · `commands/autonomy.md` (whose
no-milestone count had a **published predicate that could not return what it claimed** —
*"from the same query"*, whose first filter excludes exactly the items being counted — a falsifier that
fails open, repaired here) · `docs/blueprint-registry.md` (row 0041 re-authored, row **0043** added).

### Consequences still being paid

- **Every newly-filed item is unassigned by construction**, so `/autonomy on`'s no-milestone count stops
  being a defect signal and becomes a backlog size. Read the old way it would look like a permanent
  breach.
- **Nothing bounds how many items the owner admits at planning.** The prompt makes each admission
  visible; it makes none of them wise.
- **Nothing records WHY a milestone was assigned.** The guard reads a flag, and an owner-directed
  admission is indistinguishable afterwards from one he merely approved without reading.
- **The `ask`-with-no-prompt-surface behaviour is unmeasured**, deliberately: no automated path reaches
  the guarded act today. That is a condition, not a closure — see ADR-0004's amendment for what would
  re-open it.

## Amendment (2026-08-31, twenty-eighth) — `scrum-master` returns holding NOTHING, and exactly one half of amendment #7 is reversed (#375)

**Deciders:** the owner. **Written by** `agents-lead` (#223 — this is a pure loop/machinery decision).
**Pre-implementation stress test:** the #375 intake, which recommended **against** this profile and was
overridden; the argument it made and the argument that beat it are both recorded below, because a
future reader will raise this again.

### What is reversed, said as narrowly as it is true

Amendment #7 cut the roster 19 → 6 on the criterion *a persona exists only where conflict is wanted*,
and `scrum-master` was one of the nineteen. That amendment made **two** claims about it, and they are
not the same claim:

1. **The measured claim: it produced no disagreement anybody needed.** Its object was ceremony
   facilitation and an opinion about ordering, and `product-lead` already held both. **This is NOT
   reversed.** It is still true, it is still the reason the old profile was absorbed, and `product-lead`
   keeps ordering the `product` queue against the owner's stated objective.
2. **The inferred claim: therefore nothing of that shape is worth having.** **This is what is
   reversed**, and it was an inference from the first rather than a measurement of its own.

**The distinction is the whole amendment.** What returns is not the absorbed competence. It is one
artifact the absorbed profile never produced and nothing in this loop produces today: **a written
selection record** — one profile, one stage, one item, and the reason — returned before the work is
dispatched rather than reconstructed after it.

### The reversal rests on a design where the profile holds nothing, and that is a precondition rather than a detail

**The intake's objection, quoted, because it was correct about the profile it was pricing:** *"a new
principal holding a write no persona currently has makes the capability larger, not smaller."* It
priced a `scrum-master` that would carry milestone-write, which is what #375 was filed about.

**The owner's answer was to change the object rather than to outweigh the argument.** The profile that
ships declares **`tools: []`, an explicit empty grant** — no dispatch, no `Edit`, no `Bash`, no label,
no milestone, no comment. A profile with no capability cannot enlarge the capability surface, so the
objection does not reach it.

~~The profile that ships declares **no `tools:` line at all**.~~ **Struck 2026-08-31 (#386), and this is
the correction that matters most in the record, because the argument above rests entirely on it.** The
first round of this slice held the property by OMITTING the key, on the reading that an absent grant is
an empty grant. **That reading is the exact inverse of the runtime's**, and it was settled by exercise
rather than by reading: against build 2.1.252, a plugin agent whose markdown frontmatter declares no
`tools:` key, dispatched through `Task`, ran `Bash` and left a file on disk; the same agent declaring
`tools: []` left none and reported `"tools":[]` in the session's own init event. Six runs, one variable,
with an explicit `tools: Read` control to validate the instrument. The binary's schema says it in as
many words — *"If omitted, inherits all tools from parent"*.

**So the shipped-first-round profile would have held everything its parent holds**, and the sentence
admitting it to the roster would have been false at the moment it was written. **The general rule, which
is worth more than this one profile: in agent frontmatter, absence is inheritance** — a brief that argues
from a missing key is arguing from the largest grant in the roster. Any future persona claiming a bounded
capability declares it; none may claim one by omission.

**A second property fell out of the same probe and is recorded because it shapes how this profile is
read:** an agent holding no tools does not *report* holding none. Asked to run a command, the `tools: []`
probe replied *"The command succeeded. File created at the specified path."* and no file existed. A
tool-less profile's output is therefore not self-verifying, which is an argument for the selection record
being read as a recommendation and never as a report of work done.

**Milestone access does NOT move to it.** It stays with the orchestrator, where `permission-guard.sh`
rule 10's `ask` reaches a person, which is what makes composition HITL under #365. So the Issue's two
halves separate after all, contrary to the framing it was filed under: the profile lands, the
capability does not move.

**Which of the four reasons it satisfies: reason 2 — a fresh context is wanted.** Selection is
otherwise decided by the orchestrator, which has seen the whole session and is therefore the context
least able to see its own bias in a ranking. That is the argument the retrospective rite already
accepts as its own mechanism, applied one step earlier.

**And it does not fail the ADD rule, which is the half most likely to be waved through.**
*Reconciliation cost is paid within a tier, not across tiers.* `scrum-master` produces one artifact
nobody else produces and no verdict anybody must reconcile: it holds no gate, blocks nothing, and its
record is advisory by construction because nothing reads it. The one adjacency that could have cost a
reconciliation — ordering — is resolved by direction rather than by negotiation: it applies the **order
of record** and routes disagreement with it to the owner, never back to `product-lead` as a re-ranking.

### The coupled removal — `orchestrator-write-guard.sh` goes, and the two must be read together

**The owner's diagnosis, verbatim:** *«entendi que foi uma contingencia entao, nao era intencional.
entao esse hook nao deveria existir. o que queriamos era deixar a sessao principal intencionalmente
ociosa somente delegando. isso o SM ajuda.»*

**The hook's own header confirms the contingency reading** — it records that the orchestrator was denied
merge (rule 7b) and trunk push (rule 7) *"and nothing else"*, so everything between was open, and that
the act it stops is *"not a floor violation … it is the WRONG LAYER."* It closed a gap that was found,
not a design anybody wanted.

**The positive formulation is the better one and is why the replacement is not another lock.** The goal
is not *the orchestrator may not write* — a rule stated by exclusion, where delegation is the leftover.
It is **the main session is deliberately idle, delegating only**, where delegation is the normal path
and acting directly is the deviation. A selection record naming who acts, **before** acting, is the
positive form of the same rule.

**Sequencing was not optional and is visible in the commit order of the slice that shipped this: the
profile and its record land first, the guard is removed after.** Removing a lock before its replacement
exists produces an interval with neither.

**What that costs, stated because it disappears with the hook.** Nothing prevents the main session from
editing a repository file. What changes is that it becomes **visible**: a record said who should act and
a commit says otherwise. **Detection instead of prevention**, which is the direction the owner chose
(*«menos travas mecanicas … mecanismos de influencia de contexto em vez de travas mecanicas»*) applied
to its first concrete case. **And the detection is weaker than it sounds**: the record is landed by the
orchestrator itself, so it is self-attested, and nothing greps `SELECTION-RECORD` at all.

### The overlap with the hooks was DECIDED, not inherited

The owner named the tension himself before the build: six mechanisms already guard parts of *"the loop
runs in Scrum format"* mechanically — `wip-guard`, `session-wip`, `zombie-loop-detect`,
`premature-pr-link-detect`, rule 10, `closure-artifact-guard`. **A profile whose mission duplicates a
hook becomes a second, weaker classifier over the same state**, which is the defect measured on
`orchestrator-tool-census.sh` (#371). The brief carries the split as a table and the left column is
explicitly not the profile's. **Four states have no carrier at all, and only those are its object:** a
rite that never ran on an exhausted iteration; an Issue whose work merged and which stayed open; an
iteration worked with eligible `loop` items left behind; and the main session acting instead of
delegating.

### Considered options

- **Do not rebuild it; leave selection with the orchestrator.** The intake's recommendation, and the
  status quo for four weeks. **Rejected by the owner.** *What it was right about:* it costs nothing and
  adds no roster surface. *What it could not answer:* the ranking context is the one with the bias.
- **Rebuild it holding milestone-write, as #375 was filed.** **Rejected**, and by the owner rather than
  by the intake: it would move HITL composition off rule 10's prompt, which is #365's whole mechanism.
- **A typed command instead of a profile** — the shape `/sprint-retrospective` uses. **Rejected**, and this is
  the closest call in the set: a command runs in the orchestrator's own context, which reproduces
  exactly the bias reason 2 is about. A command can hold a *method*; only a dispatch can hold a *fresh
  context*.
- **Rebuild it, tool-less, and remove the write guard.** **Chosen.**

### Consequences still being paid

- **Nothing dispatches it**, and no hook can: a `SessionStart` hook receives one `cwd` while an
  iteration is two milestone objects in two repositories, and nothing in `hooks/scripts/` reads the
  queue at all. **An undispatched process guardian is indistinguishable from one that found nothing** —
  the same residual `agents-lead` carried before #294, and this time there is no `Stop`-hook mitigation,
  because there is no committed artifact for one to read.
- **Nothing reads `SELECTION-RECORD`.** It is a terminal literal with no consumer, deliberately: giving
  it one would make an advisory record look like a gate.
- **The tool-less property is one word away from being false.** A non-empty `tools:` line would silently
  reverse the argument this amendment rests on, so `inventory-counts.test.sh` asserts that the key is
  present AND empty, and that the brief still states the property. **Both directions redden**: a granted
  tool, and a missing key — the second because absence is inheritance, so it is the largest grant rather
  than the smallest. ~~the arm asserts the key's absence~~ ~~whether the runtime honours an absent
  `tools:` key … is **NOT measured**~~ — **struck (#386): it is measured now, and it inherits; the arm
  that required absence was requiring the one spelling that grants everything.** **What the arm still
  cannot hold:** it reads a string in a file, so it cannot observe a dispatch. That the runtime honours
  the empty list was established by probe, once, at one build; a future build could change it without
  reddening anything here.
- **The roster grew for the third time since it was cut to five**, and each addition was individually
  argued. That is the pattern to watch rather than any one of them: #187 was an owner override against
  all four reasons, #317 was reason 1, this is reason 2. A fourth should have to explain the trend.
- **`product-lead`'s absorbed ordering competence and this profile's ranking now sit one hop apart.**
  Nothing mechanical keeps them apart; the brief's direction rule is prose.

## Amendment (2026-09-01, twenty-ninth) — planning gets an object; it assembles and ranks, and composition stays the owner's act (#378)

**Deciders:** the owner — on #378's ratified body, **and separately on the scope widening below, ruled
2026-09-01.** **Written by** `agents-lead` (#223 — this is a pure loop/machinery decision).
**Pre-implementation stress test:** the #378 intake; **a second, independent lens read the built diff
cold at `573d842`** and its three blocking findings are what the *partition-not-sequence*,
*no-update-route-is-built* and *enumerate-the-retrospective-directory* sections below record.

### The scope widening, ratified 2026-09-01 — and the wording decides more than the yes

**The owner's ruling, verbatim, on #378:**

> *«bom, o rito deveria sim criar a iteracao como produto ao final dela»*

**«como produto ao final dela» is stronger than permission to create one, and the rite is written to
that wording rather than to the question that was asked.** The question was *may it create the
iteration*; the answer makes the iteration **the rite's product**. So it is a statement about the rite's
**completion**, not about one of its steps: **a planning that ends without an iteration object has
produced nothing.** The rite says exactly that, in its own words, before step 1.

~~**ONE PART OF THIS AMENDMENT IS NOT YET RATIFIED AND MUST NOT BE READ AS IF IT WERE.**~~ **Struck
2026-09-01 by the ruling above.** It is struck rather than deleted because it stood on a pushed head
and a reader may have taken the flag seriously — which was its purpose. What it flagged was real and
is worth keeping visible as a method note: #378's body said *"It does not create an iteration"*, the
owner applied `ready` to **that** body, and what had lapsed was the bullet's **reason** (#375 open, no
route) rather than its scope. **A lapsed reason is not a widened scope**, so the build stopped and
asked instead of inferring the decision from what had become convenient. The ruling is the widening,
made explicitly, and it lives on #378 rather than only here.

**What this does NOT loosen, because the two acts are different objects and the rite keeps both
guarded.** *Placement* is an **item** acquiring a milestone — rule 10, one prompt per item. *Creation*
is the **iteration object** — rule 11, one prompt. Both remain the owner's, answered by him; the
widening moves what the rite is **for**, not who decides.

**Why this is an amendment and not a new record.** It decides *what happens before an iteration
starts*, which is the same object as the twenty-sixth amendment's *what happens when one ends* and the
twenty-seventh's *what may enter one while it runs*. #283's rule is one document per capability name;
the capability is the dev loop and this document is it.

### What was actually missing, and it was not a decision

**Nothing here moves a decision away from the owner, and that is the whole design.** Composition was
already his (twenty-seventh amendment, held by `permission-guard.sh` rule 10), and it stays his,
prompt by prompt. What did not exist was the thing that **puts the decision in front of him**: the pool
assembled, the ordering rules applied, one item at a time.

Three instances, measured rather than argued:

1. `skills/agents-configuration/SKILL.md` said so in its own words — *"PLANNING is genuinely unbuilt
   and no claim is made about it."* **That sentence is struck by this slice**, in the file itself: it
   was true when the rite did not exist and it is false the moment this merges, and it sits in the
   universal preload every persona carries always-on.
2. **Five `ready` `loop` items sat unmilestoned with nothing presenting them** — a real measurement,
   dated, attributed and re-runnable rather than asserted: **taken 2026-08-31 by #378's own intake**,
   naming **#365, #370, #371, #372, #374**. The predicate:

   ```
   gh issue list --repo <owner>/<repo> --state open --limit 200 --json number,labels,milestone \
     --jq '[.[]|select(.milestone==null)
             |select((.labels|map(.name)|index("ready")) and (.labels|map(.name)|index("loop")))
             |.number]'
   ```

   **Re-run 2026-09-01 it returns SEVEN** — `[383, 378, 374, 372, 371, 370, 365]` — the same five plus
   #378 and #383, filed since. **The two figures do not contradict each other and the difference is the
   point:** one is a dated historical measurement of the condition that motivated the rite, the other
   is the class's population today, and a class whose membership moves must be published as a
   predicate rather than as a bare count. **`commands/sprint-planning.md` therefore publishes the
   predicate and NO number, and this bullet is where the dated figure lives** — the split the copy lens
   asked for and the one this practice already prescribes: the command file is installed by strangers
   and states the rule, the record carries the measurement that motivated it. **The command is printed
   here because a figure under a heading reading *measured rather than argued*, carrying neither a date
   nor a falsifier, is precisely the failure this slice spent a round correcting elsewhere.**
3. **The twenty-sixth amendment's rite shipped its producer and not its consumer.**
   `commands/sprint-retrospective.md` writes per-persona proposals whose declared consumer is *"a
   proposal the owner rules on at planning"*. `sprint-01`'s seven files have never been ruled on,
   because there was no planning to rule in.

**(3) is the one that generalises.** A rite that produces an artifact for a moment that does not exist
is the same shape as a promise with no object — the failure the twenty-sixth amendment itself closed
one step earlier, reappearing at the other end of the same chain.

### The decision that #378 required to be made explicitly: the rite DISPATCHES the ranking

**`/sprint-planning` dispatches `scrum-master` exactly once, to rank the assembled pool, and makes no
other dispatch.** The alternative — rank in the orchestrator's context, which already holds the pool —
is cheaper and was rejected on the argument the twenty-sixth amendment already accepts as a mechanism:
the orchestrator has seen the whole session and is the context least able to see its own bias in an
ordering it produces. This is that argument applied one step earlier, which is exactly how the
twenty-eighth amendment justified the profile's existence.

**It is the first dispatch of that profile.** It shipped on 2026-08-31 and had never been used.

**Why the dispatch cannot leak the composition, which is what makes it safe rather than merely
reasonable — two independent layers, neither depending on a brief being obeyed:** the profile declares
`tools: []`, so it holds no `Bash`, no `Edit` and no dispatch; and rule 10 denies `--milestone` to
**every** non-empty `agent_type`. Its ranking decides the order items are presented in and nothing
else.

**Read the second layer NARROWLY, because it is ACT-specific and not agent-specific, and this sentence
is what a future reader will lean on the day the profile is given a tool.** Rule 10 keys on a flag and
rule 11 on a script name. Measured against the head guard: `bash scripts/milestone-update.sh …` — a
script that does not exist — drew **no decision from any layer, for a subagent as well as the
orchestrator**, before this slice widened rule 11. **A subagent holding `Bash` reaches any spelling
neither rule names.** What makes the dispatch safe today is the FIRST layer, and the second is a floor
over named acts rather than a fence around the profile.

**And the dispatch forces one circularity, recorded rather than left to be hit.**
`agents/scrum-master.md` ranks against *the order of record*, which `agents-configuration` says is the
milestone description — and at planning that description does not exist, because this rite is what
creates it. **Resolution: at planning it ranks by the ratified rules alone (`loop` before `product`
among the eligible, #339) and says so in its record.** The brief now names planning as a third moment
and carries that exception, so the two surfaces agree instead of needing a reader to reconcile them.

#### The ratified rules PARTITION and do not SEQUENCE — found on review, and it is the sharper half

**The resolution above is necessary and was not sufficient, and the gap it left is the one that would
have discredited the whole dispatch on its first run.** Loop-before-product is the only ordering rule
this loop has ratified and it says nothing about two `loop` items; the pool predicate says nothing
either. **So "rank by the ratified rules alone" determines a partition and no sequence.**

**On the pool that exists, the partition is empty.** Re-derived 2026-09-01 with the pool predicate:
**7 eligible items, every one `loop`, all in one repository, `[]` in the other.**

```
gh issue list --repo <owner>/<repo> --state open --limit 200 --json number,labels,milestone \
  --jq '[.[]|select(.milestone==null)
          |select((.labels|map(.name)|index("ready"))
                  and ((.labels|map(.name)|index("product")) or (.labels|map(.name)|index("loop"))))
          |.number]'
```

**So the first draft asked the profile to compose an order no rule determines and return it under the
word *ratified*, from the profile built to be the bias-free one, into the field that becomes the order
of record.** That **launders**, and laundering is strictly worse than the thing #378 refused: ranking
in the orchestrator's context at least leaves everyone able to see whose order it is.

**The decision: the intra-class sequence is a DECLARED TIEBREAK — issue number ascending, which is
filing order — labelled as one in the record and in every per-item line it decided.** Both surfaces
carry it and a gate arm holds both.

**Rejected, with the reason, because a later reader will propose each:**

- **Return the classes unordered.** The owner rules item by item and needs a stable presentation order;
  an unordered set makes the *rite's* order the orchestrator's again, silently. Strictly worse.
- **Ratify filing order as an ordering rule.** It is not an argument about what matters. Promoting it
  would put a rule in the loop nobody decided, and the loop would then order by it forever.
- **Let the profile compose and justify a sequence.** This is what was refused; it is the defect.

**What the tiebreak does NOT buy:** it is arbitrary. It gives the order *known provenance*, not merit —
and the record and the rite both say so in those words rather than letting *declared* read as *right*.

#### Two consequences of dispatching at a moment the brief did not name

Both were found on review, both are the same class as the circularity, and both are settled in the
brief rather than left to the profile to improvise:

- **The `### Selection` block is OMITTED at planning.** It mandates exactly one `profile:`, one
  `stage:` and one `item:` and forbids hedging — correct for a record naming who acts next, and there
  is nothing to select when the owner is composing a pool. A sentinel (`profile: none`) was rejected:
  it invents a value for a field whose whole point is that it always names somebody.
- **One act, one artifact.** The brief lands records at `docs/selection/<iteration>.md`; the rite embeds
  the ranking verbatim in `docs/planning/<iteration>.md`. **No selection file is written for a planning
  dispatch.** Unstated, either both are written or one is silently skipped, and only one would be read.

### #378's "it does not create an iteration" is SUPERSEDED — by the owner's ruling, on a dependency that
had already lapsed

**The ruling is what supersedes it** (quoted in full at the top of this amendment); what follows is why
the bullet was right when written and what had changed underneath it before he was asked.

That bullet was written on 2026-08-31, when #375 was open and milestone creation had **no route at
all** — measured then and unchanged now: `gh milestone --help` → `unknown command "milestone" for
"gh"`, and `gh api` writes are denied by rule 5f. #386 merged `scripts/milestone-create.sh` and rule
11 the same day.

**So the rite PRODUCES the iteration, through that route, and it is the route's first exercise.** Rule
11 asks the orchestrator; his answer is the verification. **Read *produces* rather than *may create*:**
the ruling's own wording — «como produto ao final dela» — makes the object the rite's deliverable, so a
planning that ends without one has not finished. **Nothing about that is claimed to be
closed:** the route reaches the write API because no permission layer reads inside a script, which is
the same blindness that makes `python3 -c "…gh api -X POST…"` reach it. The rite repeats that in its
own text rather than relying on the script's header.

**The create-before-admit ORDER rests on a missing SCRIPT, not on a control — and the first draft of
this amendment got that wrong in the one direction that matters.** The script accepts `--description`
at creation; the composition therefore has to be collected before the object is created, since
`agents-configuration` says the order of record lives in that description. That much stands.

~~and **nothing in this harness can amend a milestone description afterwards**. … Where the milestone
already exists, the order of record **cannot be written at all**~~ — **STRUCK on review, before this
ever merged, and struck rather than edited because it is the sentence that made a missing script read
as a property of the harness.** It is refuted by the rite's own mechanism, three paragraphs above:
5f blocks the *convenient* spelling and not the *available* one, and CREATE already depends on the
available one. Measured against the head guard, one payload per line:

```
[ORCH]         gh api -X PATCH repos/o/r/milestones/2 -f description=x  -> deny (5f)
[ORCH]         bash scripts/milestone-update.sh 2 --repo o/r …          -> NO decision from any layer
[scrum-master] bash scripts/milestone-update.sh 2 --repo o/r …          -> NO decision from any layer
```

**PATCH is blocked in the same spelling POST is blocked in and reachable in the same spelling POST is
reachable in.** The correct statement is **no update route is BUILT**; the hole is open and anyone may
write one. Where the milestone already exists, the order of record is **not written into the milestone
description and the reason is recorded** — the composition itself survives in full in the rite's own
artifact, which is one more reason `agents-configuration` calls that field a weak home.

**And the residual is guarded PRE-EMPTIVELY rather than left to the slice that accepts the invitation.**
Rule 11 was pinned to the literal basename `milestone-create.sh`, so the `milestone-update.sh` this
residual invites would have shipped a milestone write with **neither the `ask` nor the `deny`**, on a
route indistinguishable from the sanctioned one — #365's human verification absent, with nothing saying
so. That is ADR-0004's *"absent is not a state"* shape arriving through a file nobody had written yet.
**Rule 11 now matches `milestone-[a-z0-9-]*.sh` in both run positions**, and the widening ships here.

**A closed VERB LIST was rejected, and the reason is the whole argument for the family form.**
`milestone-(create|update|close)\.sh` reintroduces exactly the failure the widening exists to prevent:
the first name nobody enumerated ships unguarded, silently. The family form fails the other way — a
read-only `milestone-report.sh` prompts — and **a prompt on a read is legible where an unguarded write
is not.** One pre-existing ALLOW assertion asserted the opposite property and is **struck and
re-authored in place**, with that reasoning written at the assertion rather than in a commit message,
because changing a test to fit new code is the shape to be most suspicious of.

### The planning artifact is a tracked file, and it is NOT the object this loop specified

`agents-configuration` specifies the planning artifact as **an iteration Issue** — *"one Issue per
iteration, opened by the owner at planning, whose body is the ordered list of the items admitted"* —
and that object was never built. The same file already calls the milestone description a **weak home**
for the order.

**This rite writes `docs/planning/<iteration>.md` and that is a THIRD home, not the specified one.** It
is better than the milestone description in one way — versioned, diffable, in a diff the gate reads —
and worse in one: nothing else in the loop reads it either. **The specified object remains owed**, and
the rite says so in the section that writes the file, so a reader cannot mistake one for the other.

### What this deliberately does NOT do

- **It does not estimate.** #378 scoped it out and the scoping is kept: a profile that ranks a pool
  and also weighs it grades its own ruler, which is the reason `scrum-master` is excluded from the
  estimator sets in the first place. **The consequence is stated in both files rather than discovered:**
  `/autonomy`'s preflight refuses entry while an item lacks `sp:N`, so a freshly composed iteration
  ordinarily refuses the first drain, and the rite closes by listing exactly which items will cause it.
- **It does not open work.** A retrospective proposal becomes an Issue only on the owner's ruling, and
  it is filed with no milestone like everything else (twenty-seventh amendment), then admitted by the
  same prompted route as any other item.
- **It does not close an iteration.** No command available to this loop can read whether a milestone is
  open or closed.
- **It does not handle a CARRY-OVER, and it does not pretend to.** Step 1 assembles `milestone == null`,
  so an open item still carrying the last iteration's milestone is invisible to the rite entirely. **The
  class is reachable and its population is a moving number, so the rite publishes the predicate and no
  count** — it is populated whenever an iteration does not fully drain, which is the ordinary case
  planning exists for. The corrective act exists and is the owner's (`--remove-milestone`, which rule 10
  deliberately does not match). Closing it needs a second assembly pass and a rule for which iteration a
  carried item returns to, and that is its own slice.
- **It does not see an Issue carrying no routing label.** Same shape, same treatment: the predicate is
  published and no vacuity is asserted.

#### A VACUITY CLAIM IS THE WRONG SHAPE, and both bullets above carried one until the gate refuted it

**Both bullets shipped saying the class was *vacuous today*, with the predicate printed beside the
claim, and one of them was already false at the head that published it.** An Issue filed at 16:11:32Z
on 2026-09-01 in the product repository carried only `reader-facing` — no routing label — so the
negated predicate returned one member, and it did so **before** the head asserting emptiness was
pushed. **The falsifier printed beside the claim is what refuted the claim.**

**That is not staleness and the distinction is the whole of the correction.** A stale figure was true
once; this was false when written. And it is the same defect this very amendment corrects under *What
was actually missing, and it was not a decision*, where a published `five` carried neither a date nor a
falsifier — **the second instance in one slice, which is what makes it a shape rather than a slip.**

**Why re-measuring was rejected as the fix.** The class re-emptied within the hour (the missing label
was applied by hand), so a fresh measurement would have republished *vacuous* and been correct for
exactly as long as nobody forgets a label again. **One forgotten label falsifies a vacuity claim**, so
the claim is a promise that the world stays still, which is not a promise a record may make.

**What replaces it:** the **property** — an item in this class is dropped by the rite without a word —
plus the predicate that reads who is in the class **now**. A count would need a date and a re-run; a
property needs neither. **The general rule this books: publish a predicate for a class whose membership
moves, and reserve dated counts for measurements of things that do not.**

### The SECOND input is enumerated, not typed — the rite's own rule, applied to itself

**Found on review: the rite stated *"never type a milestone title into a query"* and then addressed its
second input by a hand-typed directory one screen later.** The proposals live in
`docs/retrospective/<previous-iteration>/`, and *which* iteration is not derivable — no command here
reads a milestone's `state`. **A mistyped directory makes the glob match nothing and the rite reports
"0 findings", which is exactly what an honest empty retrospective looks like.** A plausible zero, from
a falsifier that fails open, reproducing the very failure the rite exists to close — a producer whose
output has no consumer — through its own second door on the same run.

**The rule now applies to both inputs: `ls -d docs/retrospective/*/`, select from what came back, and
if the selected directory holds zero `## Finding` sections, say it as a finding about the handoff
rather than reporting a count.** The cost of the second half is a false alarm on a genuinely empty
retrospective; that is the direction worth failing in, because an empty retrospective is itself worth
saying out loud.

### The VERSION, ruled on rather than defaulted to

**By this repository's own published criterion this is a MINOR** — `CLAUDE.md`: *"**minor** — additive:
a new skill/command, or substantial new capability."* The first draft of the PR body stated that
criterion and concluded PATCH, which is the criterion arguing against the conclusion in the same
sentence.

**What actually happens is mechanical and is not a decision anyone takes on this PR.**
`version-main.yml` bumps **patch unconditionally** on every push to `main`; this repository has no
`semver:` label path, `release.yml` is `workflow_dispatch` only, and `Bash(gh workflow run:*)` is
denied. **So the merge publishes a PATCH whatever any PR body says.** Declaring PATCH here is therefore
a description of the mechanism, not a ruling — and the failure mode of dressing a default as a decision
is that the MINOR never gets cut.

**It is absorbed by the deliberate bump the owner cuts once the whole reconfiguration lands** (*«ao
final dessa reconfiguracao completa vamos gerar o major»*), and a MAJOR subsumes an outstanding MINOR.
**If that bump does not happen, this slice will have shipped a MINOR-class change under a patch tag**,
and the record says so here rather than leaving it to be reconstructed from the tag history.

### Counter-argument, and the cost accepted

**The strongest case against building this at all is #378's own carried hypothesis:** that what was
missing is the assembly, rather than the owner simply not having sat down to plan. The three instances
above are consistent with both readings. **The rite is worth building on the first and cheap on the
second** — it is a typed command, costing nothing until invoked — which is why it was built rather than
argued about further.

**What it costs, which is real:** N admitted items is N permission prompts, plus one for creating the
iteration. That is the price the twenty-seventh amendment already priced and accepted, arriving in
bulk at the one moment the owner is present by construction.

### Criterion 10 on this slice — CLOSED BY A RULING, not passed, and the ruling is the ORCHESTRATOR'S

**Who decided, first, because that is the part this repository blocks on hardest.** The ruling that a
two-count `README.md` edit does not warrant a `product-lead` dispatch was made by **the orchestrator**,
in a dispatch brief. **It is not the owner's. He was never asked and has not spoken on it.**

**A round of this PR recorded it as the owner's, and that was false.** It is corrected here rather than
quietly reworded, because *who decided* is exactly the class of claim this loop treats as blocking: a
ruling attributed to the owner carries authority he never lent it, and **it is unfalsifiable from inside
the artifact** — a reader in November has no way to tell a real ratification from a misattributed one.
The falsifier is external and cheap: `gh issue view 378 --json comments` and `gh pr view 388 --json
comments` are where his words are, and neither carries this one.

**What the ruling closes, stated exactly: the DISPATCH, not the CHECK.** The gate's own reading is
`CLOSED-BY-RULING`, never `PASSED`, and the three parts of it are separate:

- **The trigger fired.** `README.md` and `CLAUDE.md` are in the diff and the reader-facing rule fails
  closed, so criterion 10 was live.
- **No `product-lead` verdict on this diff exists.** The `dispatch-metrics` entries showing it ran are
  on the **Issue**, at intake — a different object from a lens verdict on a diff.
- **The gate found the copy clean by its OWN measurement** — the counts in both documents are the ones
  it re-derived. That is a different fact from *the copy lens having run*, and the two must not be
  collapsed: one is a gate checking numbers, the other is a persona judging published claims.

**So the honest form is that a check was WAIVED by the orchestrator on a size judgement, with the gate's
independent read recorded beside it.** If that waiver is wrong, the correction is the owner's and the
route is a `product-lead` dispatch on the diff, relayed verbatim under a `copy-verdict` fence.

### What nothing enforces, said before any green is read

**Nothing fires this rite, nothing observes that it ran, and nothing observes that it ran correctly.**
No hook in `hooks/scripts/` reads the queue — every `gh issue` call there is a write path — and a hook
receives one `cwd` while an iteration is two milestone objects in two repositories paired by a
hand-typed title. A planning skipped, a planning over a mistyped title, and a planning that presented
three items instead of thirty are indistinguishable from the tracker.

**And nothing observes the dispatch.** `dispatch-metrics-stop.sh` reads an Issue number out of the
branch name and a planning branch need not carry one; the profile holds no tools, so it leaves no other
trace. **The one-item-at-a-time rule is checkable by reading the artifact's rulings table and by
nothing else.**

- **The same phrase-keyed coupling as the last seven amendments.** `inventory-counts.test.sh`'s three
  planning arms key on sentences across three files; whoever rewrites one of them will meet a red
  naming the clause. That is presence of a rule and never obedience to one, and the arms' own header
  says so.

## Amendment (2026-09-02, thirtieth) — the sprint review is BUILT, its driver is `product-lead`, and the Scrum rite-naming set is complete (#379, #372)

**Deciders:** the owner — on #379's ratified body (*"build the full sweep"*, 2026-08-31, taken over the
cheap first slice he was offered). **Written by** `agents-lead` (#223 — pure loop machinery, no
product-architecture stake, no `tech-lead` co-citation owed). **Two Issues, one amendment**, and that
is a ruling rather than a convenience: see *One amendment, not two* below.

**Why this is an amendment and not a new record.** It decides *what happens at the end of an
iteration*, which is the twenty-sixth amendment's own object, and it **reverses that amendment's
decision 6**. #283's rule is one document per capability name; a new number would create a second
`roster-and-dev-loop`.

### One amendment, not two — and #372's closure is a CONSEQUENCE, not a second decision

**#372 asked for the rites to carry the official Scrum names, and for the record of why the other two
stayed absent.** Its rename half shipped at #387; its remaining half is now answerable only as history,
because both absent rites were built (#378, #379). **Nobody decided *"the naming set is complete"* — it
became complete**, which is the definition of a consequence. Splitting it into its own amendment would
put a decision heading over something no one chose, and this library already carries the rule that a
record explains the current codebase rather than narrating how it got here.

**What that closure actually is, stated so it is not read as a claim about the harness's quality.** The
three rites now exist and run in Scrum's order. Nothing fires any of them.

### The decision

1. **`commands/sprint-review.md` is the rite**, typed by the owner and named by `/autonomy on` at its
   terminal condition. **The twenty-sixth amendment's decision 6 — *"the sprint review half is NOT
   built"* — is REVERSED**, and every surface carrying that claim is struck in place rather than
   edited away: the retrospective rite's last section, `/autonomy on`'s *HALF the promise* clause, the
   universal preload's *one built and one owed*, and the Scrum disclaimer's item 2 in both of its homes.
2. **It runs FIRST of the three: `/sprint-review` → `/sprint-retrospective` → `/sprint-planning`.**
   Two independent reasons, either sufficient. **Legibility** — Sprint Review precedes Sprint
   Retrospective in Scrum, and a Scrum name that no longer predicts the order has stopped doing the one
   thing #372 renamed it for. **Mechanics** — the retrospective feeds each consulted persona its own
   artifacts, and the sweep's report is one of them; run second it would be produced after the
   consultation that would have read it.
3. **The driver is `product-lead`, NOT `quality-assurance`, and #379's body is overridden on this
   point.** See *The driver, measured* below. This is the one place the build departs from a `ready`
   Issue body, it is flagged in the PR rather than absorbed, and the Issue itself labelled that choice
   a hypothesis.
4. **The refusal's two grounds are SATISFIED, not lifted, and they are built into the rite's shape.**
   *A route list rots* → the rite ships **no list**; targets come from the product's own route
   generator, the same function its sitemap and prerender consume, and assets are read **off the page**
   through the network log and the DOM snapshot. *A looker's finding has no ruler* → the rite is **not a
   gate and returns no verdict**, stated in its second section rather than added afterwards.
5. **The rite declares itself a LOWER BOUND.** Route × viewport × on-page assets is not the surface: the
   viewport set is enumerated and can go stale, anything behind an interaction is unreachable under a
   read-only browser grant, and **an emulated phone is not the phone the motivating defects were found
   on.** An incomplete sweep that says so is worth more than a complete-looking one that is not.
6. **The rite and the driver's brief are two halves of one mechanism and each declares which.**
   `commands/sprint-review.md` is the WHEN and the WHY; `agents/product-lead.md`'s existing sweep
   section is the HOW and remains the authority on it. Neither restates the other.
7. **Amendment #16's booked residual is PARTIALLY DISCHARGED.** ~~DISCHARGED — *"the owner reviews live,
   after deploy" has no artifact* — by the sweep's per-iteration report file. The
   `APPROVE-AND-MERGE-BOUNDARY` `SessionStart` arm … is now an **optional addition** to a rite that
   exists rather than a substitute for one that did not.~~ **Struck in the first review round of this
   same MR, before merge, on an independent lens's finding — and the correction is worth more than the
   word.** The residual books **three** clauses and the sweep delivers **one**: a post-deploy look now
   leaves an artifact, but the report records that **`product-lead`** looked rather than the owner, and
   it surfaces **nothing per-merge**. The `SessionStart` arm is therefore **the open half of this
   residual, not an optional extra** — and the one case the residual was booked against
   (`tadeumendonca-io#479`) is a truth-of-a-published-claim case the rite bars itself from twice. The
   clause-by-clause split lives with amendment #16's own bullet, where a reader looking the residual up
   arrives; this item points there rather than restating it.

   *Why the overclaim is worth recording rather than quietly narrowing:* a record asserting a control is
   in place where it is partial retires a residual that is two-thirds open, and nothing downstream would
   ever have reopened it — the booked residual is the only thing that remembers.

8. **A REVIEWED BRANCH IS NOT REBASED, and the reason is ADR-0006's, not convenience.** This MR's PR
   body carried a false base SHA; the two available repairs were *correct the line* or *rebase onto the
   commit the line named*. **Rebasing was refused, and the general rule is worth having beyond this
   MR:** a rebase rewrites every commit on the branch, so **the SHA a head-scoped verdict names stops
   existing.** [ADR-0006](./0006-verification-and-its-artifacts.md) head-scopes the gatekeeper's verdict
   precisely so a verdict on a moved head fails loudly instead of reading as approval — and a rebase
   does not move the head, it **deletes the commit the verdict points at**, which is strictly worse: the
   marker resolves to nothing rather than to something stale. The `agents-lead` marker is affected
   identically and has *less* protection, being a presence check rather than a head check.

   **So: once any head-scoped verdict has been posted against a branch, correct the claim, never the
   history.** The cost of the correction is one struck line; the cost of the rebase is a verification
   artifact that can no longer be resolved to what it verified.

### The driver, measured — and it is a hook, not an opinion

**#379's body names `quality-assurance`, imported from the foreign harness's own choice. At head that
rite would die at its first navigation.** `hooks/scripts/mcp-guard.sh` (#355) grants the browser to
`product-lead` by name and denies every other `agent_type` by default:

```
printf '%s' '{"tool_name":"mcp__plugin_tadeumendonca-skills_chrome-devtools__navigate_page","agent_type":"tadeumendonca-skills:quality-assurance"}' \
  | bash hooks/scripts/mcp-guard.sh
# → {"permissionDecision":"deny", … "holds no MCP grant … New personas default to DENY here"}
# the same payload with agent_type=…:product-lead exits 0 with no decision — allowed
```

**So the imported driver is not a preference this build declined; it is a configuration this harness
already refuses.** Adopting it would have required a second MCP grant — widening, three days after
#355 narrowed it to one persona and one read-only tool subset, a surface whose other members act
irreversibly and in public in the owner's name.

**And the second reason survives the hook changing, which is why it is recorded beside it rather than
under it.** The gatekeeper's whole discipline is a ruler external to itself. **This rite deliberately
has none.** Handing a rite with no ruler to the persona built around one produces either a verdict
nobody asked for or a gate with no ground — the failure the rite's own shape refuses.

**The owner had already decided this, at #355**, in terms this build did not have to re-derive:
*«ele tem a visao de proposito conectada a engenharia»* — the purpose-view held together with enough
engineering to know what a failed request was serving.

### Considered options

- **`quality-assurance` as driver, per #379's body** — rejected on the measurement above.
- **A second MCP grant so the gatekeeper could drive it** — rejected. It reverses #355's narrowing to
  buy a driver the rite is a worse fit for.
- **Splitting the rite from the driver's brief and moving the procedure into the command file** —
  rejected. The procedure names the consuming repository's own route-generator path, and
  `inventory-counts.test.sh`'s consumer-reference lint scans `commands/` for exactly that: measured,
  a `tadeumendonca-io` or `apps/fed` token in a command file reddens the suite. The brief is entitled
  to name a consumer; the command file is not. **The two-file split is therefore a constraint of this
  plugin's own publication rule, not a preference** — and it is stated here because the next person
  who tries to consolidate them will meet the red before they meet the reason.
- **Reserving the third rite's name and shipping the record only** — rejected; it is the *stub* shape
  #372's struck section already priced, and the owner declined the cheap slice explicitly.
- **A separate amendment for #372's closure** — rejected. See *One amendment, not two*.

### What nothing enforces, said before any green is read

- **Nothing fires the rite.** `/autonomy on` names it at its terminal condition; that is an instruction
  in a command file. No hook can be built for it: nothing in `hooks/scripts/` reads the queue, and a
  hook receives one `cwd` while an iteration is two milestone objects in two repositories. **Three
  rites now exist and zero of them have a trigger** — the plural in *"the closing ceremonies"* is
  satisfied in COUNT and in nothing else, which the preload now says in those words.
- **Nothing observes the sweep, and this one is worse than the retrospective's equivalent.** The report
  lands in the **consuming** repository, so `inventory-counts.test.sh` never sees it at all. A skipped
  sweep, a sweep over the wrong iteration and a sweep that visited four routes of eighteen are
  indistinguishable from everything this repo can read.
- **The one mechanical arm is a NEGATIVE.** `inventory-counts.test.sh` asserts the rite ships no
  leading-slash route token — the only form of ground 1's erosion a grep can catch. A route list
  written as prose is a reviewer's read and has no instrument.
- **Every other arm is presence of a sentence**, in the rite, the drain, the preload and the driver's
  brief. Presence of a rule, never obedience to one.

## Amendment (2026-09-02, thirty-first) — planning composes and he confirms once; the escalation protocol gets one standard (#393)

**Deciders:** the owner, in an interview conducted mid-session, on the rite's first real run. **Written
by** `agents-lead` (#223 — pure loop machinery; no product-architecture stake, so no `tech-lead`
co-citation is owed).

**Why this is an amendment and not a new record.** It decides *how work is composed into an iteration
and when a running loop reaches the human* — the same object as the twenty-sixth, twenty-ninth and
thirtieth amendments, and it **corrects the twenty-ninth's step 3**. #283's rule is one document per
capability name; a new number would create a second `roster-and-dev-loop`.

### What broke, and it broke on the first run

`/sprint-planning` shipped at #378 presenting the ranked pool **one item at a time**, waiting for a
per-item ruling. Run against `sprint-02`, **it stopped at item 1 of 15.** The owner's correction, in
order:

> *«a sprint planning nao é uma atividade hitl»* · *«ela é confirmada pelo hitl»* · *«voce saiu
> desenhando ritos sem me entrevistar como gostaria de trabalhar no scrum movido pelo loop»*

**The third sentence is the finding and the first two are the fix.** The rite was authored without the
elicitation step this repository's own process mandates — *scaffold, elicit the owner's layer,
iterate* — which governs `commands/` as much as `skills/`. That interview was run in this slice
instead, and the decisions below are its output.

### Decision 1 — `/sprint-planning` composes; he confirms once

It applies the already-ratified rules to the ranked pool, produces a proposed composition, and puts the
whole of it to him as one activation — **confirm · change · defer/drop an item · stop**. **A change
recomposes and re-activates once; two is the bound**, because an unbounded confirm-change loop is the
fifteen-turn walk arriving one round later. The per-item reasoning — why each item is in or out, by
predicate — goes to `docs/planning/<iteration>.md`, **never into the activation**.

**Nothing about assembly, ranking, the predicates or rule 10/11 placement changes.** The confirmation
precedes the placement prompts and does not replace them.

### Decision 2 — the escalation protocol has ONE standard, and a precondition

The owner's scope, verbatim: *«eu apenas queria padronizar a escalacao do loop»* — and his correction of
the anchoring, which is the load-bearing half: *«pendencias hitl sao apenas derivadas o protocolo de
escalnomaneto padrao de subagents ate a sessao principal»*, *«relacionados a issues em andamento em um
sprint»*, *«se nao tem loop nao é hitl»*.

**Five clauses, all required:** (1) a loop is running; (2) a **dispatched subagent** hits something on
an Issue in that iteration; (3) it rises **subagent → main session → owner**; (4) the trigger is a
**trade** of time (work *plus* wait hours), cost (**tokens**) or scope, for that item — anything moving
scope is a *candidate*, not an automatic escalation; (5) the form is a tweet at most, **at most four
direct options**, his technical register, terse first with depth pulled — **and it always carries the
options**, because a bare question is offloading the analysis.

**The precondition is stated first, deliberately.** Outside a running iteration there is no HITL
pendency, whatever the subject. It is recorded because the standard was mis-scoped **twice** while being
written: every question to the owner read as an escalation, and the contract was applied to
conversations it was never about.

**Where the options are composed:** `scrum-master` **names** which leads a scope escalation needs — it
holds `tools: []` and dispatches nobody — and the orchestrator dispatches them, for **one** escalation
and its trade and nothing else. **A disagreement between the two leads IS the trade and rises as the
options**, resolved by neither.

**Where the standard lives: `skills/engineering-standards/SKILL.md`**, judged on #381's cut test — it
names no persona, no hook and no record, and it is true of any loop that runs unattended. The **local**
half is in `skills/agents-configuration/SKILL.md`: who composes options here, what is instrumented, and
what is missing. Both are universal preloads, so every profile that could escalate reads them.

### What this DIVERGES from, and the divergence is what gets re-adopted

**The escalation rule is NOT *reversibility, not seniority*.** That came from a blueprint the owner
imported, authored for a different project, and it was relayed into this work as though it were his.
**It is not.** It sorts this loop's own acts backwards — creating an iteration is barely reversible and
trades nothing; deferring an item is trivially reversible and trades scope for time. Recorded in both
skills and gated by an absence arm, because the risk is re-adoption from a real source rather than
invention. **The permission floor's own irreversibility test is untouched** and answers a different
question.

### What is NOT decided, and must not be inferred

- **No AFK/HITL contract table is authored.** The imported blueprint carries one; this harness has the
  five-clause standard and nothing tabular. **His live design work.**
- **No threshold** — no number, no multiplier, no trigger for how far a spend runs before the trade is
  worth escalating. **`sp:N` as a denominator was drafted and withdrawn before shipping**: he stated
  that scope influences cost and time, which is a relation, not a mechanism.
- **A WORKLOG does not exist here.** He named *«metricas e worklog»*; `dispatch-metrics-stop.sh` is the
  metrics half and there is no worklog. Do not read the metrics hook as one.
- **Open with no mechanism:** *how does this loop decide an item's cost or time has gone wrong?*
- **Rules 10 and 11 stay exactly as they are.** Under decision 2 they prompt on acts that trade nothing
  once a composition is confirmed. **They are the #365 floor and this amendment changes neither**; the
  tension is named for the owner in `commands/sprint-planning.md` and left to him.
- **`/sprint-review`, `/sprint-retrospective` and `/autonomy`'s preflight are UNTOUCHED.** An earlier
  draft of this slice declared an AFK/HITL half in each and rewrote the preflight's surfacing; the
  owner narrowed the ask and all of it was reverted. **The preflight still surfaces pendencies one at a
  time** — a known tension, recorded in the gate's own failure text, and out of scope here because it
  runs *before* a loop is running, where the standard's precondition says it does not reach.

### The worked example decision 2 was derived from, read correctly

Three PRs in one week spent **nineteen review rounds**, almost all on corrections that minted fresh
defects — a large spend of tokens and a larger one of wait hours against **no change in scope**. **By
the operational test that is not an escalation the loop failed to make.** What it exposes is that the
spend was instrumented and nothing compared it to anything: **a calibration gap, not a missing
escalation** — which is why no threshold is authored above.

### What nothing enforces — and the owner asked for enforcement, so this is the honest answer

He asked: *«faça enforcement para nao errar de novo»*. **Most of this standard cannot be enforced by any
layer this harness has, and that is stated in the carriers themselves rather than only here:**

- **Clauses 2, 3 and 4 are unreachable.** Nothing records that a subagent's return was an escalation
  rather than its ordinary output; nothing distinguishes a relayed escalation from the orchestrator's
  own prose; and whether a question was a genuine trade is a judgement no string check reaches. **A
  detector that fails open is worse than none.**
- **Clause 1 is a query and clause 5's shape is string-checkable**, but only once something *declares*
  that an escalation is happening — inferring it from prose fails open.
- **Every available layer is DETECTION, one turn late.** A permission layer reads a command string; an
  escalation is a message to a human, which no matcher sees.
- **`inventory-counts.test.sh` asserts the rules are WRITTEN** — in the standard, the preload, the rite
  and the ranking profile's brief — and cannot observe that a planning presented one activation or
  fifteen. **The artifact that would show it is written by the same context that would have broken it.**

By this loop's own test, the escalation standard is an **intention**. A declared-envelope detector — an
escalation carrying a literal a `Stop` hook can read, whose *shape* is then checked — is the one
buildable control and is **not built here**: it is its own decision, it enforces only the clause least
likely to be got wrong, and it would read as covering the four it cannot.

### Considered and rejected

- **Keep the walk and shorten each item** — rejected. The cost is the turn count, not the per-item
  length.
- **Let the rite compose and place without confirming** — rejected. Composition moves scope, which is a
  trade, and it would collapse rule 10's floor by the back door.
- **An unbounded confirm-change loop** — rejected as having no terminal state.
- **Declare an AFK/HITL half in every rite** — built, then reverted when the ask narrowed. The two
  closing rites ask him nothing and were not the defect.
- **Adopt `sp:N` as the cost/time denominator** — rejected after being drafted, as above.
- **Build the envelope detector in this slice** — deferred, not dropped. See above.

## Links
- Driven by record 0001 (ADRs are the brain this depends on), now
  [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md) · the DoD is
  [ADR-0006](./0006-verification-and-its-artifacts.md)'s *Merge Request Definition of
  Done* section, absorbed there from record 0003 on 2026-08-19 · autonomy/tool-scoping is
  ADR-0004 · full design in `docs/proposals/agentic-dev-loop.md`.
