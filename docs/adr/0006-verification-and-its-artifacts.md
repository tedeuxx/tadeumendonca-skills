# 0006. Verification and its artifacts

**This record is the capability document for `verification-and-its-artifacts`.** It was titled *A
verdict one persona owes another is an artifact on the PR, not a relayed claim*, and filed as
`0006-a-verdict-owed-to-another-persona-is-an-artifact.md`, until 2026-08-20 — when the owner decided
that an anchor is named for its **capability** rather than for the decision that originated it
([#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283), part 3 slice S3). The originating
decision is unchanged and is the body below; what changed is that this file stopped being named after
one of the decisions it holds once it began holding more than one. The number did not move, so every
`ADR-0006` citation in either repository is unaffected; the **filename** did, and every path-form
citation of it was rewritten in the same commit as the rename — which the citation gate asserts, so
the claim is checkable rather than reported (`bash hooks/scripts/inventory-counts.test.sh`).

- **Capability:** verification-and-its-artifacts
- **Status:** accepted · **amended 2026-08-03** (both gatekeepers granted `Write`; the load-bearing
  `--body-file` question inside *Consequences* is closed) · **amended 2026-08-04** (the closing open
  question's premise is falsified — `marketing-lead` no longer exists and the copy lens now holds
  `Bash`) · **amended 2026-08-04, second** (a mechanism now stands behind the copy lens's
  identifier-only rule) · **amended 2026-08-04, third** (**the closing open question is CLOSED** — a
  gate may relay another persona's verdict, and for the copy lens it must; criterion 10 upgrades from
  *returned* to *returned and quoted*) · **amended 2026-08-04, fourth** (`security` is absorbed into
  `quality-assurance` per [ADR-0002](./0002-roster-and-dev-loop.md) amendment #10, so **the
  gate-reads-gate verification has no subject** — the artifact survives and still closes *omission*, the
  **confirmation** does not, and the remaining verdict is self-enforced). **The decision itself is
  unchanged by all five** — ~~the relay is an addition alongside the two first-party markers, never a
  substitute for either.~~ **Corrected by the fourth amendment:** there is now **one** first-party
  marker, and the relay is an addition alongside it. That it is never a substitute is what did not
  change. **Absorbed record 0003 on 2026-08-19** (#283) — this file is the capability document for
  `verification-and-its-artifacts`, and the Merge Request Definition of Done is now a section of it.
- **Date:** 2026-08-02
- **Deciders:** the owner
- **Driven by:** the Merge Request Definition of Done — record 0003 until 2026-08-19, absorbed into this
  document below — and [ADR-0004](./0004-controls-and-enforcement.md)

## Context & problem

Two gatekeepers review every MR: `quality-assurance` on delivery, `security` on the floor. They are
dispatched in parallel and both must approve before the safe class merges. `quality-assurance` holds
the merge and carries the rule *"do not merge until `security` has returned an approval."*

**It could not check that rule.** Subagent verdicts are returned to the orchestrator's context and
written nowhere. `gh pr view --json comments,reviews` returned empty on every PR in this repo. So the
merge precondition was satisfiable only by trusting a relay — the invoking context saying the other
gate approved — and a relay is the one thing this loop already refuses to trust everywhere else.

**Three observations, all on #127, all within one turn:**

1. **The harness's own security monitor flagged the merge** as *"merged with no visible review approval
   or owner ratification comment, contrary to the repo's documented merge-gate policy."* Both
   gatekeepers had in fact approved. The monitor was right about what it could see, and what it could
   see was nothing — an independent confirmation of the gap, arriving in the same turn it was
   diagnosed.
2. **A relayed verdict contained a false statement about the diff it approved.** `security` reported
   four files where the PR had one, having diffed against the previous PR's merge commit rather than
   the merge-base. Coverage was a strict superset, so nothing was missed. **The identical mistake
   against a newer ref reviews a subset and the relay reads identically.**
3. **`/principles/dev-loop`'s state table already claimed the artifact existed.** Its `in progress →
   reviewed` row named *"their verdicts on the PR"* — in the column whose entire job is to answer *what
   records that this happened*.

**And the standard was inverted.** The loop already held that the owner's ratification is verified from
the PR itself and that *a relay is a notification, never the authority* — the rule this record then made
mechanical, and which `/harness-engineering` states in its inner-loop section. (This sentence attributed
that rule to a *"2026-07-29 amendment"* of record 0003 until 2026-08-20. The amendment is real; the
number was a **cross-repo collision** — it belongs to the consuming repo's third record,
[trunk-based delivery, single environment](https://github.com/tedeuxx/tadeumendonca-io/blob/main/docs/adr/0003-trunk-based-single-environment.md),
not to this library's 0003 — see *A citation that resolved to another library* below.) A gatekeeper's
veto was held to a weaker standard
than the owner's ratification — and
the veto fires on **every** MR while the ratification fires only on the boundary class.

## Decision drivers

- The rule that waits on a verdict must be **checkable by the party that waits**, not by the party that
  reports.
- The check must catch a verdict that is **stale**, not merely absent — a review of a commit that has
  since been superseded is not an approval of what is about to merge.
- It must not serialise the two gatekeepers, which are deliberately parallel.
- It must not require a new permission, tool grant or hook (ADR-0004: mechanism only where the act is
  irreversible).

## Considered options

1. **A marker comment on the PR, verified by the consumer** (chosen). The producing gatekeeper posts
   `<!-- gatekeeper-verdict: … -->` with a verdict line and the `headRefOid` it read; the consumer
   verifies with `gh pr view --json comments,headRefOid` immediately before merging. *Trade-off:* the
   comment is self-attested — see the residual below. **Needs no permission change**: `Bash(gh pr
   comment:*)` is already allowlisted in both repos and `security` already holds `Bash`.

2. **Extend `permission-guard` rule 7b to gate `gh pr merge` on the comment's existence.** *Why not:*
   ADR-0004's 2026-08-02 amendment establishes that these rules enforce **routing, not capability** —
   the model cannot *claim* a persona it is not running as, but the main loop *chooses* which to spawn.
   So a hook buys the **same** guarantee as the artifact, because a context willing to fabricate the
   comment is a context that would equally spawn `security` and ignore its verdict. And it costs
   parsing the PR number out of the merge command — `-R`, `--repo`, a bare `gh pr merge` inheriting
   HEAD's PR — which is rule 5d's four rounds and eighty deleted lines, re-run for no additional
   assurance.

3. **Gate the COMMENT rather than the merge** — deny a `gh pr comment` whose body carries a marker
   naming a persona the caller is not running as. *Recorded because the first draft of this ADR never
   considered it, and both gatekeepers found the omission independently.* It is **not** equivalent to
   option 2: it would narrow the attributable set from *"anyone holding `Bash`"* — which is what it is
   today — to *"the main loop deliberately spawning `security`"*. So the routing-not-capability argument
   does not dispose of it.

   ***Why not — one reason, and it is enough.*** **It does not touch the failure that was observed.**
   #127 was **omission**: no verdict existed at all. A hook that refuses a forged marker never fires
   when there is nothing to forge. So this option defends a threat this record has not seen, while
   leaving the one it has seen exactly where it was.

   **What this rejection deliberately does NOT claim.** It does not claim the option is infeasible —
   a hook could read the marker, and rule 5d proves it, because that rule *did* resolve and read a
   `--body-file`. It does not claim the reversibility line in ADR-0004 excludes it: **that line is an
   open question in ADR-0004's own final amendment**, which names `inventory-counts` as a fully
   reversible, high-yield mechanism the rule as written would forbid, and proposes **mechanical
   decidability** as the likely real variable — under which a literal marker compared to `agent_type`
   is decidable and would *not* be excluded. **Revisit this option if that question is ever settled.**

   *Three earlier versions of this rejection were wrong, and they are recorded rather than swapped in
   silently, because the pattern is the finding rather than any one of them.* The first claimed the
   decision mandates `--body-file` — grep falsified it. The second argued the marker's presence in the
   command string is a property of the spelling — refuted by 5d above, and *"nothing prevents a fourth
   spelling"* proves too much, being equally true of rules 5b, 7, 7b and 8, all kept with **named**
   gaps. The third invoked *"a partial mechanism is worse than a named gap"* — which **does not
   discriminate**, since the option chosen here is partial in the identical way, closing omission and
   not impersonation. That argument silently upgraded this ADR's actual rule, *do not overstate a
   guarantee*, into *do not build a partial mechanism*, then applied the upgraded form to the option it
   rejected and the original form to the option it chose.

   **Four times, this option was rejected on a reason stronger than the facts supported — and each
   version was longer than the last.** The conclusion survived every time, which is what makes it worth
   recording: a right answer defended by a wrong argument reads as settled and audits as false. The
   correction that finally held was **deleting reasons, not adding them.**

4. **The status quo relay.** *Why not:* it is the defect. It made a gate's own rule unverifiable, and
   it delivered a false claim about a diff without anyone noticing until the consumer independently
   re-derived the file list.

5. **A GitHub review approval instead of a comment.** *Why not:* GitHub refuses a review approval from
   the PR's own author, and every PR here is authored by the same token the gatekeepers run under, so
   the mechanism is unavailable rather than merely awkward. A comment carries the same information on
   the same surface with the same verification path the Definition of Done had already proven (record
   0003, absorbed into this document below).

## Decision outcome

Chosen: **the comment, verified by the consumer against the current head.**

- **Both** gatekeepers post before returning, on every review including clean ones, each under its own
  marker. **Verification runs in one direction** — only the gate that holds the merge reads the other's,
  and nothing reads its own. *Why both write when only one is read:* the read gates a merge and only one
  gate merges, but the **write** serves a second purpose the read does not — without it the *delivery*
  verdict, the one carrying the DoD evidence and the merge decision, leaves no trace, which is exactly
  what observation 1 above complained about. A security-only comment closes half the observed failure.
- **A gatekeeper that cannot post does not proceed as though it had.** For `security` that is automatic
  — the merging gate will not find its marker. For `quality-assurance` it is a rule, because nothing
  reads its comment: **if it cannot post its own verdict, it does not merge**, and it says why. Without
  that, the asymmetry reintroduces the original failure in the half nobody verifies — a merge with no
  delivery record, silently, which is precisely what the harness monitor objected to.
- `quality-assurance` verifies three conditions before merging — the marker is present, the verdict
  reads `APPROVED`, and **the recorded head SHA equals the PR's current `headRefOid`** — and names
  which of the three failed, with the command output, when one does.
- The check runs **immediately before the merge, not at review start**, so the two gates stay parallel.
- **Both** gatekeepers derive the diff from `gh pr diff` / `gh pr view --json files`, never from a local
  `git diff` against a ref they picked. This is the same principle in the evidence dimension: a
  self-chosen ref is a relay about what was reviewed.

## Consequences

**Good**
- `quality-assurance`'s merge precondition becomes a query rather than a matter of trust, satisfiable
  only by the other gate having actually run and written something.
- A stale verdict fails **loudly**. The head-SHA comparison is an exact string match, not a
  clock-ordering argument.
- The transition finally has the artifact its own state table always claimed.
- It leaves a record a future sweep can audit. Today's loop produces none at all.

**Bad / accepted costs**
- **The residual, named rather than papered over:** the harness stamps `agent_type` on tool calls, not
  on comment authorship. A verified comment proves the verdict exists, is attributable to this token,
  and matches the current head — **not** that `security`'s context authored it. This closes
  **omission**, which is the observed failure. It does not close **impersonation**, which has not been
  observed and which no reachable mechanism in this harness closes either — option 2 above buys nothing
  against it. Overstating the guarantee would be worse than naming its limit.
- One extra `gh pr comment` per gatekeeper per round — and the cadence is **per round**, not per PR,
  because head-SHA equality is strict: every subsequent commit invalidates the standing verdict and the
  gatekeeper must be re-dispatched. That multiplier is the thing most likely to get worked around, and
  the workaround is a stale verdict waved through. Named here so it is a known price rather than a
  discovery.
- **Fails closed by INSTRUCTION, not mechanically**, and the distinction matters enough to state:
  `permission-guard` cannot be reasoned past because it is a `PreToolUse` hook; this gate holds only
  while `quality-assurance` obeys the instruction to check. It is a materially weaker fail-closed, it is
  the same class of gap this ADR exists to narrow rather than close, and option 2 would not have fixed
  it either. "Fails closed like the permission floor" is not a sentence to write without this qualifier.
- **Neither gatekeeper has a `Write` tool**, so the body goes through Bash and must survive the floor's
  composition rule. *The mechanics live in the persona files and are not restated here* — a third copy
  is a third thing to keep true. What belongs in the record is the **cost**, and it is larger than an
  inconvenience:

  **The failure correlates with the reviews that matter most.** What makes posting fail is the
  characters in the body; what determines those is how much the review found. A dense verdict citing
  paths, flags and shell fragments is exactly the one that jams. So the tax is heaviest on the
  substantive reviews, and the pressure it creates — trim the verdict until it posts — produces a
  thinned verdict that is **indistinguishable from a careful one** to every checker in this loop.

  That does not argue against the decision: under the rejected alternative the same bias yields a
  *missing* record on the most substantive reviews, which is strictly worse. It argues that the
  scratchpad-scoped `Write` grant is **not cleanup — it is what decides whether this rule is livable.**
  Still an ADR-0004 tool-grant decision and therefore the owner's — and a *capability* grant, so a
  boundary decision in its own right rather than a consequence of merging this — so recorded here as an
  open question, but recorded as load-bearing rather than cosmetic.

  **Observed on this ADR's own MR, which is why it is stated this strongly.** A gatekeeper's verdict was
  refused twice by the floor: once for quoting the very hook line that proved one of its refutations,
  once because its prose used semicolons. It posted only after deleting the quoted evidence and
  rewriting the argument's punctuation. The prediction and its confirmation are in the same review.

  **And nothing detects the thinning.** No party in this loop holds both the verdict a gate *returned*
  and the verdict it *posted* — the orchestrator sees the return, a later reader sees the comment, and
  no check compares them. The detector would be trivial and there is nowhere to put it. Recorded as a
  known blind spot rather than left to be rediscovered.

**Open question, recorded rather than settled.** `marketing-lead` has the identical hole:
`quality-assurance` is told to confirm the copy lens returned a verdict, and cannot. It is
**deliberately out of scope** — that persona is granted `Read, Grep, Glob` and **no `Bash`**, and the
scoping is intentional because it never writes, the voice being the owner's. Covering it means trading
a deliberate tool grant against verifiability, which is an ADR-0004 decision and the owner's to make.

---

**Two open questions, one shape — read the amendments below in order.** This record leaves *two* holes,
and a 3-way replay of the batch that closes them presented them as competing edits to the same file.
They are not competing; they are consecutive, and the shape they share is the reason to say so before
either amendment speaks:

> **Both holes were priced in the same currency — a tool grant — and this ADR routed both to the same
> decider, the owner, under [ADR-0004](./0004-controls-and-enforcement.md).** The *Consequences*
> hole is the gatekeepers' missing `Write`; the *Open question* hole is the copy lens's withheld `Bash`.

What happened to them, in the order it happened, is the point:

1. **2026-08-03 — the `Write` was granted.** The hole this ADR called *"what decides whether this rule
   is livable"* is closed, on measured evidence rather than on the argument that predicted it.
2. **2026-08-04 — the `Bash` was spent without buying anything.** A roster merge decided on unrelated
   grounds handed the copy lens the exact capability this ADR had named as the price of closing its
   second hole — and the hole stayed open, because nobody was closing it.
3. **2026-08-04, later the same day — the second hole is closed, and not with a tool grant at all.**
   Rule 5e took the spent capability back on the publishing subcommands, and the owner then decided
   the **relay** (third amendment below). So the hole this record priced in a currency it did not
   control was paid in one it did: **an instruction in a persona file.** Which is the sharper form of
   the contrast above — the tool grant was never the only price, and pre-committing the remedy to one
   is what kept the question open for two days.

**That contrast is the finding, and neither amendment carries it alone.** One tool-grant question was
put and answered; the other was answered by accident, in the wrong direction, by a record that was not
asking it. A capability spent as a side effect buys nothing, because nothing was bought *with* it.

---

## Amendment — 2026-08-03: the open `Write` question is closed, and both gatekeepers hold the grant

The consequence above says *"Neither gatekeeper has a `Write` tool"* and books a scratchpad-scoped grant
as an open question that is **"what decides whether this rule is livable."** That question was put and
answered: **`quality-assurance` and `security` are both granted `Write`, scoped to composing the verdict
body in the scratchpad.** The consequence's text stands as written — it records what was true when it
was written, and its prediction is the reason this amendment exists.

**What decided it was the confirmation, not the argument.** The consequence predicted that the tax falls
hardest on the densest verdicts and that the thinning is undetectable. Measured since: a ~60-line verdict
posted with **every backtick hand-stripped**, so paths, command names and job names rendered as bare
prose in the artifact the merge gate reads. Under `--body` an unstripped backtick does not error — the
shell **deletes the span** — so the failure mode is not a refusal the agent notices but a silent
subtraction from the record.

**The rule that replaces the three-way choice:** `--body-file` from the scratchpad, always, no per-case
judgement about quoting. The mechanics stay in the persona files, as before; what is recorded here is
that the choice itself is gone, because a per-case judgement was the mechanism of the failure.

**What is NOT closed.** The blind spot recorded above — nobody holds both the verdict a gate *returned*
and the verdict it *posted* — is untouched by this grant. What the personas add against it is an
instruction, not a detector: **a verdict that had to be shortened or stripped to post is a posting
failure and is reported as one.** That is the same weaker fail-closed this ADR already books, and it is
named again rather than allowed to read as fixed.

**And the grant is a capability, so it widens the surface.** `quality-assurance`'s contract sentence
said *"it never edits code"*, which a `Write` tool makes mechanically untrue; the description now states
the grant and its single purpose, and a `Write` to any repo path is a defect in the review. That is a
scope rule, not a wall — nothing mechanical confines either gatekeeper's `Write` to the scratchpad.
Booked here as a real cost of closing the question, in the same terms this ADR uses for its others.

## Amendment (2026-08-04) — the closing open question's premise is gone; the question is not

**What changed outside this record.** [ADR-0002](./0002-roster-and-dev-loop.md)'s ninth
amendment merged `marketing-lead` into `product-lead`. The persona named in the open question above no
longer exists, and the copy mandate now lives in a persona declaring
`tools: Read, Grep, Glob, Bash`.

**The decision this ADR records is untouched.** The marker comment, the three conditions
`quality-assurance` verifies before merging, the head-SHA equality, the one-directional read, the
`gh pr diff` rule — none of them names a lead persona, and none of them changes. This amendment
touches the **open question only**.

**What is falsified, precisely.** The open question rested on two premises and both are now false:

1. *"that persona is granted `Read, Grep, Glob` and **no `Bash`**"* — it is granted `Bash`.
2. *"covering it means **trading** a deliberate tool grant against verifiability, which is an ADR-0004
   decision and the owner's to make"* — **the trade has been made.** Not as a verifiability decision;
   as a **side effect** of a roster merge decided on entirely different grounds. The record should say
   that plainly: the capability the open question treated as the price of closing the hole was spent
   without the hole being closed.

**What survives, and it is the whole substance.** The hole itself is unchanged: `quality-assurance` is
told to confirm the copy lens returned a verdict and **still cannot check that it did**. What was a
capability constraint is now merely the absence of an instruction — the copy lens does not post a
marker because nothing tells it to, not because it cannot.

**And the question is now cheaper, not settled.** ADR-0002's amendment #9 books the `Bash` inheritance
as a **cost it accepted**, not as an enablement it wanted. Reading it as a licence would let this
record convert someone else's accepted downside into a justification — which is exactly the shape
this ADR's own rejected option 3 was found to keep doing across four rewrites. So:

> **Recorded as reachable, not as decided.** A third marker — `product-lead` posting its copy verdict
> the way both gatekeepers do — is now mechanically possible where it previously was not. Whether it
> *should* exist is a separate decision, and it is not made here.

Two things the deciding record would have to weigh, stated so the next reader starts from them rather
than rediscovering them:

- **The multiplier.** This ADR already books the marker cadence as **per round, not per PR**, and names
  it *"the thing most likely to get worked around."* A third marker on every reader-facing MR
  compounds that on the MRs that already carry the most review.
- **Privacy is the reason the grant was withheld in the first place.** ADR-0002's first amendment made
  the copy lens write-incapable because it reads a **private, gitignored** source while its findings
  land in **public** PRs. Instructing it to post to a public PR points it at exactly that seam. The
  identifier-only output rule (`positioning.md §X, bullet N`) is the containment, and it is now an
  instruction with no capability behind it.

**A narrower observation, and it cuts the other way.** The proposed merge-precondition hook — record 0007
until 2026-08-20, now [ADR-0004](./0004-controls-and-enforcement.md)'s *The merge precondition is a
floor, not an instruction* section —
reads *each persona's canonical verdict set from the persona file at runtime* — for
`quality-assurance` and `security` only. It has no dependency on the lead roster, so the roster merge
does not touch it. But it is the reason a third marker would be more than documentation: the mechanism
that would enforce one already exists and is shaped to be extended.

## Amendment (2026-08-04, second) — the containment gets a mechanism, and it narrows this question

The amendment above ends on the sharper of its two warnings: the copy lens's **identifier-only output
rule** — cite `positioning.md §X, bullet N`, never the line — *"is now an instruction with no capability
behind it."* **It has one.** `permission-guard` gains **rule 5e**, an `agent_type`-keyed deny on
`gh pr comment` / `gh issue comment` / `gh issue create` for `*:product-lead`, so the persona that reads
the private, gitignored positioning source cannot itself publish to a public PR. The decision and its cost are recorded in
[ADR-0002](./0002-roster-and-dev-loop.md)'s amendment #9, where the loosening was booked; the
mechanism class is recorded in [ADR-0004](./0004-controls-and-enforcement.md). It is noted here
because it **moves this record's open question**, in both directions.

- **Against the third marker.** It requires the copy lens to *post*, and posting is now exactly what the
  floor refuses it. The option is no longer *"mechanically possible where it previously was not"* — it
  became possible on 2026-08-04 and was closed again the same day. Reviving it costs a **carve-out in
  the deny**, not merely an instruction, which is a materially larger ask than the amendment above
  assumed when it wrote *"recorded as reachable."*
- **For it.** The privacy objection — the second of the two things the deciding record must weigh — is
  the one that just got cheaper, because the leak path it feared is now closed by construction rather
  than by the lens's own discipline. **The multiplier objection is untouched**, and it was always the
  stronger of the two.

**And it points at a shape this record kept not considering.** If the copy verdict must become
checkable, the form that survives the deny is **the merging gate posting the copy verdict it received**,
not the lens posting its own. That is *weaker* — it is a relay, which is the thing this entire ADR
exists to refuse — and it is named here so the next reader weighs it against the carve-out rather than
discovering it as the only remaining option under time pressure.

**A citation to this record that this record does not support, flagged rather than quietly honoured.**
Rule 5e's deny message and its comment both tell the caller that the finding still reaches the PR
because *"`quality-assurance` quotes it onto the PR (ADR-0006)"* — described in the comment as *"the
mechanism ADR-0006 already names, not one invented here."* **This ADR names no such mechanism.** What it
names is two gatekeepers posting their **own** verdicts under their **own** markers, and one gate
verifying the other's. A gate quoting a *third* party's verdict is the relay shape — which this record
exists to refuse, and which the paragraph above introduces as an *undecided option*, explicitly weaker.

The rule's **behaviour** is right and nothing here argues against it: the finding should reach the PR,
and with 5e in force `quality-assurance` is the only party that can carry it. What is wrong is the
**citation** — it books an existing guarantee where there is an unmade decision, which is precisely the
defect this ADR catalogues four times over in its own option 3. Two ways to settle it, neither taken
here because the choice is the owner's:

1. **Decide the relay**, and record it in this ADR as the third marker's cheaper substitute — at which
   point the citation becomes true.
2. **Correct the citation** in `hooks/scripts/permission-guard.sh` to say the finding is returned to the
   invoking context and that publishing it is *not* mechanically guaranteed.

Until one of those happens, **the deny message overstates what happens to a `product-lead` finding**,
and it overstates it to the one reader — the persona being denied — who cannot check it.

**One caution, because this record has a documented habit of exactly this error.** Option 3 above was
rejected four times on reasons stronger than the facts supported. The symmetric error is available here:
it would be convenient to read the new deny as *settling* the third-marker question in the negative. **It
does not settle it. It prices it.** A capability the owner can grant is not a decision the owner made.

## Amendment (2026-08-04, third) — the open question is closed: a gate MAY relay, and for the copy lens it MUST

**Decision: the owner, 2026-08-04.** The amendment above lists two ways to settle the citation that
rule 5e books against this record. **The first was taken.** The relay is decided:

> **A gate may quote another persona's verdict onto the PR under its own marker. For the copy lens it
> is not optional: `quality-assurance` quotes the copy verdict verbatim into its own verdict comment,
> and criterion 10 is no longer satisfied by *"the lens returned a verdict"* but by *"the lens returned
> a verdict and its text is on the PR."***

### 1 · Scope — where "may" ends and "must" begins, stated because it is a real fork

The permission is **general**: nothing in this record forbids a gate from carrying a third party's
findings, and quoting one has always been better than dropping it.

The **obligation** is not general in the sense of *"applies to every persona"*, and it is not specific
in the sense of *"applies to `product-lead` by name"* either. Both readings are wrong and each fails in
its own direction — the first conscripts gates into relaying verdicts nothing waits on, the second
leaves the next 5e-shaped rule to rediscover this whole question. The obligation attaches to the
**condition**, and the condition is two facts, both checkable:

> **A gate MUST relay a persona's verdict when (a) one of that gate's own criteria is unsatisfied
> without it, and (b) the floor denies that persona every route to publish it itself.** Today exactly
> one pair meets both: `quality-assurance` / `product-lead`, criterion 10, rule 5e.

**And the obligation is created by the deny, so it is booked on the deny.** Whoever adds a
persona-keyed publication denial to `permission-guard` acquires, in the same MR, the duty to name which
gate relays that persona's output and under which criterion — or to state that nothing waits on it.
Without that, "general" is a promise with no trigger, and this library's recurring defect is precisely
a rule whose state nothing records. The general form buys nothing today, because it currently describes
one pair; what it buys is that **the next 5e is told what it owes before it ships**, which is exactly
what the last one was not.

**What the permission does NOT reach, and this exclusion is load-bearing.** *May relay* must never be
read as loosening this ADR's core decision. The relayed copy verdict **authorises nothing**. It is
transport for findings the gate must then apply. Two things stay first-party only and are unchanged:

- **`security`'s approval.** The merge precondition is satisfied by `security`'s own marker at the
  current head, verified with `gh pr view`. A relay of it remains exactly what this record was written
  to refuse.
- **The owner's ratification.** *A relay is a notification, never the authority* stands verbatim. (This
  bullet cited a *"2026-07-29 amendment"* of record 0003 until 2026-08-20. Both the rule and the
  amendment are real; the **number** was the defect — it names the consuming repo's
  [trunk-based delivery, single environment](https://github.com/tedeuxx/tadeumendonca-io/blob/main/docs/adr/0003-trunk-based-single-environment.md),
  not this library's 0003 — see *A citation that resolved to another library* below.)

The discriminator is **authority versus record**. A verdict that *permits an act* must be first-party,
because the party that benefits from the permission must not be the party that reports it. A verdict
that *supplies findings a gate then judges* is a record, and a record can be carried — provided the
carrying is visible, which is the whole of §2.

### 2 · The cost, which is this record's own objection turned on itself

**A relayed verdict passes through a party with an interest in the outcome. `quality-assurance` merges.**
It is being asked to carry findings that could hold its own merge, which is the structure this ADR
spent four rejections refusing to hand-wave. It is not neutral and is booked as an accepted cost, with
one named mitigation:

> **Verbatim, and under the relayer's own marker.** The words are the lens's; the marker is
> `quality-assurance`'s. It is visibly the carrier and not the author, so **a false or shaded relay is
> attributable to it and is itself a review defect.** Never paraphrase, never re-classify a severity in
> transit, never decide which findings were worth quoting; disagreement goes in the gate's own text
> *below* the quote, where a reader sees both.

Attribution is genuinely weaker than a first-party artifact and this record does not pretend otherwise.
What it buys is that the failure has an owner. What it does not buy:

- **The blind spot widens rather than appears.** This ADR already books that *"no party holds both the
  verdict a gate returned and the verdict it posted"* — for the gatekeepers' own verdicts. It now
  covers a **third party's** verdict too, where the gap is one step larger: with a self-posted verdict
  the shortening is at least done by its author. Selective quoting is invisible afterwards, because a
  quote of three findings looks precisely like a verdict that had three. **The detector would still be
  trivial and there is still nowhere to put it.**
- **The mitigation against selective quoting is a rule about length, not a check.** Quote in full,
  always; fold in `<details>` if long; split into part 1/2 under the same marker if GitHub's limit is
  reached. Folding is presentation, truncation is loss. The `Write` grant from the 2026-08-03 amendment
  is what makes "in full, always" livable — a 200-line quote composed in the scratchpad and posted with
  `--body-file` costs exactly what a 5-line one does. **That grant was booked as *"what decides whether
  this rule is livable"*; it now decides whether a second rule is, and it was already paid for.**

### 3 · The multiplier objection — it SURVIVES, and it is now the decisive one

The amendment above named two objections to reviving the third marker and said the multiplier *"was
always the stronger of the two."* Ruling, because it was asked for explicitly:

> **The decided relay does not dispose of the multiplier. It routes around it — and in doing so makes
> it the standing reason not to give the copy lens its own marker.**

The relay adds **zero comments**. The quote rides inside the verdict comment `quality-assurance`
already posts unconditionally on every review including clean ones. So the per-round cadence this
record calls *"the thing most likely to get worked around"* is not compounded on the reader-facing MRs
that already carry the most review — which is the entire cost the third marker would have imposed.

That inverts the standing balance, and the balance is now worth stating in one place so the next reader
does not re-derive it:

| | third marker (carve-out in 5e) | decided relay (chosen) |
|---|---|---|
| **Privacy** | closed by construction *only if* the carve-out is narrower than 5e | closed by 5e, untouched |
| **Multiplier** | one more comment per round on the most-reviewed MRs | **none** |
| **Attribution** | first-party — the strong form | carrier-attributed, verbatim |
| **Cost to build** | a carve-out in the floor + persona instruction | an instruction in one persona file |

**So the third-marker question is not settled — it is now dominated on three of four axes and loses only
on the one this record cares most about.** It stays open on exactly that ground: **if a shaded or
selective relay is ever observed, attribution is the axis that failed and the third marker is the
remedy, and its price is the multiplier.** That is the trigger to revisit, written down so the revisit
is not an invention.

### 4 · The mechanism — criterion 10, from *returned* to *returned and quoted*

The upgrade belongs in this record because it is where the relay becomes checkable rather than
encouraged:

> **Criterion 10 is satisfied when the lens returned a verdict AND its text is on the PR.** A dispatch
> does not satisfy it. A return into the orchestrator's context does not satisfy it. If
> `quality-assurance` cannot post at all, criterion 10 is **UNVERIFIED** — not passed, not skipped — and
> it says so, reporting what the lens returned in its own return text so the finding is not lost with
> the artifact.

This is the same shape the decision outcome already sets for the gatekeepers' own verdicts: *a
gatekeeper that cannot post does not proceed as though it had.* Implementation lives in
`agents/quality-assurance.md`, written by `developer` in the same MR as this amendment; the mechanics
are **not** restated there and here in full, per this record's existing rule that a third copy is a
third thing to keep true.

**The floor does not enforce it, and that is unchanged rather than newly conceded.**
The proposed merge-precondition hook — [ADR-0004](./0004-controls-and-enforcement.md)'s *The merge
precondition is a floor, not an instruction* section, record 0007 until 2026-08-20 — reads the two
gatekeepers' markers and their head SHAs; it cannot tell a `quality-assurance` comment that quotes a
copy verdict from one that does not. The relay therefore fails closed **by instruction**, exactly like
the rest of criterion 10 and like the *"cannot post, does not merge"* rule above it. Stated so nobody
reads a decided relay as a mechanised one.

### 5 · The evidence — the measured failure rate of the alternative

The alternative to a decided relay is *the invoking context asks the lens to post*. That is not a
hypothetical baseline; it ran, and its rate is on the PRs.

**In one session the main agent dispatched a copy lens and omitted to have its verdict posted five
times, and `quality-assurance` recorded criterion 10 unverified every time.** Checkable — the trail is
`gh pr view <n> -R tedeuxx/tadeumendonca-io --json comments` on `-io` **#337, #338, #343, #344, #348,
#349**, grepping `criterion 10`. Two notes on the counting, because a measurement quoted loosely is the
defect this library keeps finding:

- **The recordings outnumber the occasions.** #348 alone records it four times across rounds, ending
  *"recorded unverified a fourth time, and it is the truth."* The *five* counts distinct occasions, not
  distinct sentences; the sentence count is higher and the honest reading is that the sentence count
  being higher makes the case stronger, not weaker.
- **#338 is the harder one, and it is included deliberately:** there the lens was not dispatched at all
  (*"the trigger fires and it has NOT been dispatched"*). Omission at the dispatch step and omission at
  the posting step are different failures with the same outcome — no verdict in the record — and the
  relay only fixes the second. **The trigger rule is what covers the first, and this amendment does not
  touch it.**

**And the finding that forced the decision is the one that would have been lost.** `security` traced
rule 5e's consequence: the copy lens that found the ADR-0043 falsehood on `-io`#349 — an amendment
claiming `/architecture` did not draw a distinction the same PR made it draw — would, under 5e, have
had **no way to post it**. The lens's highest-value finding, on the class the lens exists for, reaching
the PR only if a step measured at four-omissions-in-five happened to run.

> **A step forgotten four times in five is not a step. The choice was never *the relay* versus *the main
> agent carries it*; it was the relay versus the finding not arriving.**

### 6 · The correction loop, recorded because both states were right in turn

This record's habit is to keep the wrong version rather than swap it out, and the sequence here is
unusually clean:

1. Rule 5e's **first** deny message told the denied persona that the finding still reaches the PR
   because *"`quality-assurance` quotes it onto the PR (ADR-0006)"*, calling it *"the mechanism ADR-0006
   already names, not one invented here."*
2. The amendment above found the citation false: this record named no such mechanism, and the citation
   **booked an existing guarantee where there was an unmade decision** — its own option 3's documented
   defect, committed by a rule citing it.
3. `developer` corrected the message to state that publishing was **not** mechanically assured.
4. **The owner has now made the original claim true.**

**The correction was right when it was made and is not retroactively wrong.** Between (1) and (4) the
message would have promised a guarantee nobody had decided, to the one reader — the persona being
denied — who could not check it. The record shows both states because *"the citation was false, then a
decision made it true"* is a different and more useful fact than *"the first version was right all
along."* The deny message returns to substantially its first claim, and it may now do so **citing this
amendment**, which is a decision, rather than this record's silence, which was not one.

### 7 · The field had already ruled, on the same reasoning, before the record did

Worth surfacing rather than leaving in a PR thread: on `-io`#337, `quality-assurance` ruled on its own
authority that a relayed copy verdict satisfied criterion 10 — *"the lens has Read/Grep/Glob and
structurally cannot post, so a relay is the only transport that exists; requiring self-posting would
make the criterion unsatisfiable"* — and correctly scoped the *"a relay is not the authority"* rule to
the `security` veto and the owner's ratification, both of which **can** post.

That is the same discriminator §1 arrives at, reached independently under time pressure. It is
recorded for two reasons and the second is the uncomfortable one: it is evidence the distinction is
natural rather than invented here, **and** it is an instance of a gate resolving an open question in
this library by itself, in a PR comment, where no sweep would find it. The decision above makes that
ruling correct by decision instead of by improvisation, and upgrades it — #337's relay was a
disclosed paraphrase; a relay is now **verbatim, under the relayer's marker**, which is the half that
makes it attributable.

## Amendment (2026-08-04, fourth) — the verification direction has lost its subject; the artifact survives, the check does not

**Cause:** [ADR-0002](./0002-roster-and-dev-loop.md)'s amendment #10 — `security` is absorbed
into `quality-assurance`. **The decision this record makes is unchanged**: a verdict owed to another
persona is still an artifact on the PR, still carries the head SHA it read, still is never a relayed
claim. What changed is that **one half of its mechanism no longer has a second party**, and that half
was the load-bearing one.

**What is falsified, precisely.** This record's *Decision outcome* has both gatekeepers write and **one
read the other's** — *"the read gates a merge and only one gate merges."* There is now one gatekeeper.
So:

> ~~`quality-assurance` verifies `security`'s marker before merging — present, approving, and naming
> the current `headRefOid`.~~ **Struck: there is no second marker.** The remaining verdict is posted by
> the party that merges and is **read by nobody**. The posting rule is **self-enforced**.

**This is the single largest loss in this record's history and it is not softened.** The gate-reads-gate
step was **the only place in this loop where a verdict was mechanically checked by a party other than
its author.** Its removal was not a defect in this decision; it is a consequence of an owner decision
taken for a different reason — fewer profiles reconciling one result — and the price is booked here
because here is where it will be looked for.

**What the artifact still buys, stated so it is not written off either.** It closes **omission**: a
merge proceeding on a review that was claimed rather than given leaves no comment, and the harness's own
monitor flagged exactly that (observation 1). The record of *what was decided and why*, at *which head*,
still exists for a later audit. What it no longer buys is **confirmation**, and that word should replace
any lingering *"verified"* in prose describing the remaining gate.

**The rule for the merging gate is unchanged and is now carrying all the weight.** *"A gatekeeper that
cannot write its verdict does not proceed as though it had"* was written for the half nobody verified,
and that half is now the whole. Its own justification is worth re-reading in the new light: *"without
that clause the asymmetry rebuilds the original failure in the half nobody verifies — a merge with no
delivery record, silently."*

**The blind spot this record already books widens again.** It already said that *"no party holds both
the verdict a gate returned and the verdict it posted"*, and the third amendment widened that to a third
party's relayed verdict. It now covers **the only verdict there is**. The detector would still be
trivial and there is still nowhere to put it.

### What this does NOT touch

- **The relay decision (third amendment) survives entire**, and its `quality-assurance` / `product-lead`
  pair is unaffected — `product-lead` still cannot publish (rule 5e), criterion 10 still upgrades from
  *returned* to *returned and quoted*, the quote is still verbatim under the relayer's own marker.
- **The multiplier objection survives**, and it is now stronger: reviving a third marker would add a
  reconciliation cost inside tier 3, which ADR-0002 amendment #10 has just paid down deliberately.
- **The exclusion list in §1 loses one entry and keeps its principle.** *"`security`'s approval … a
  relay of it remains exactly what this record was written to refuse"* has **no referent**; the persona
  is gone. **The discriminator is untouched** — *authority versus record*, a verdict that **permits an
  act** must be first-party, a verdict that **supplies findings a gate then judges** may be carried. The
  owner's ratification remains in the list and is now its only member,
  which makes the general form load-bearing rather than illustrative: the next authority-bearing verdict
  is covered by the rule and not by an enumeration that would have had to be edited again.
- **The impersonation limit** is unchanged and unreachable from here.

## The Merge Request Definition of Done (absorbed 2026-08-19, record 0003)

**What this section is.** Record 0003 held the Definition of Done this gate reviews against. Its
decision is still in force — it is not reversed, not superseded, not unbuilt — so it is **absorbed**
into this document under [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)'s
fourth disposition, and the `## History` row in [the index](./README.md) names this document as its
destination. Driven by [#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283), slice S2.

**The fold is lossy by instruction, and the drops are listed rather than left to be noticed** — see
*What this fold dropped* at the end of this section. What arrives is the decision as it currently binds,
the rejected options still live, and the consequences still being paid.

### Context — why a Definition of Done exists at all

A reviewer with no explicit, agreed ruler reviews by **taste**, which reintroduces exactly the
subjectivity an isolated reviewing context exists to remove. The DoD must be **pacted** and
**objective**, or the gate is worthless. That argument is why this capability is named *verification and
its artifacts* rather than either half alone: a check with no ruler and a check with no artifact fail
the same way — nothing outside the checker's own head says it happened.

### Decision drivers

- Every criterion is mechanically checkable or evidence-cited — no "looks fine".
- It classifies **who may merge**, which is the autonomy hinge
  ([ADR-0004](./0004-controls-and-enforcement.md)).
- It scales to the slice type: a docs slice is not a feature slice.

### The decision, as it currently binds

**The DoD of `docs/proposals/agentic-dev-loop.md` §6**, with three pacted resolutions:

- **Significance beats in-pattern** — a change crossing a significance boundary always leaves the safe
  class, even when it looks routine. Safety over convenience.
- **Coverage ≥ 85%** — the plugin's default. A project may raise it, never lower it.
- **The approval hook** — the owner approves once, on the spec or the Issue; the slices implementing it
  are born safe-class. This is the join between one approval and downstream autonomy.

Its hard gates: a thin slice, traceability to an Issue, tests proportional to the slice type with
coverage at or above the threshold, all gates green with real evidence, an ADR wherever a significance
boundary is crossed, observability, no doc drift, conventional commits, and the security posture — plus
the **safe/boundary classification** that decides who merges.

**Adjacent debt is named, never filed and never fixed inline** (owner directive, 2026-07-30). Gate 1
originally read *"adjacent debt → an Issue, never fixed inline"*, and the instruction was not being
violated — it was being followed: in one session the queue grew by 19 issues net, roughly 13 of them
born inside a review of something else. Nobody decided that work should exist; the loop decided and
asked afterwards, and the queue stopped describing the product and started describing how hard the
agents had looked at it. **Only the owner opens work.** What *enforces* that today is
[ADR-0004](./0004-controls-and-enforcement.md)'s rule, not this one's: every subagent except
`developer` is denied `gh issue create`, and for the main agent the rule is instructed rather than
enforced.

### The rejected options, still live

1. **Subjective reviewer judgement** — reintroduces bias, two reviewers disagree, nothing is auditable.
2. **No DoD at all** — the gate has nothing to review against, so autonomy cannot be granted safely.

Both are kept because they are the paths a future reader must not relitigate: an argument for softening
a criterion is usually one of these two wearing a narrower coat.

### The consequences still being paid

**Good**
- The gate has an objective, auditable ruler, so its verdicts are trustworthy rather than taste.
- Tests scale to slice type, so a docs PR is not blocked demanding an E2E it does not need.

**Bad / accepted**
- Ongoing discipline: every significant MR carries its ADR, every feature carries its regression.
- The significance test is objective in form and still a judgement call at the margins.
- **A finding in a verdict is ephemeral where an Issue is not.** On a merged PR the report has no reader
  afterwards, so some real findings are lost. That is the trade, and it is preferred to a backlog that
  grows by working.

### The generic concept is a separate artifact

What a Definition of Done *is* — what makes a criterion well-formed, the common shapes, the four failure
modes — is `/definition-of-done` (#265). This section records **this loop's own** pacted DoD and its
safe/boundary classification: one concrete instance of that concept, never a restatement of it. The full
checklist is `docs/proposals/agentic-dev-loop.md` §6.

### A citation that resolved to another library, stated rather than repaired quietly

**This record cited a "2026-07-29 amendment" of record 0003 four times. The amendment exists — in the
consuming repo, not in this one.** It is the second amendment of `tadeumendonca-io`'s third record,
[trunk-based delivery, single environment](https://github.com/tedeuxx/tadeumendonca-io/blob/main/docs/adr/0003-trunk-based-single-environment.md),
whose §1 carries verbatim the rule the four sites hung on it: *"The relay is a notification that a
comment exists; it is never the authority."* **The defect was the number, not the referent** — two
different records under one token, which is the same collision `0007` records for the `authorAssociation`
citation in this same fold, and it is named there in the form this section now matches. This library's
0003, *The Merge Request Definition of Done*, carried exactly one amendment, dated 2026-07-30, about
adjacent debt — so the token pointed at a real record that had never held the rule.

**The record published a falsifier for this, and the falsifier was scoped to the wrong universe.** It
was the first command below, whose pathspec confines it to *this* repository: it answers *"is this
amendment here?"* and was read as answering *"does this amendment exist?"* — a real command attached to
a question it does not answer. Both halves are published now, because the pair is the finding:

    # this library — the amendment is genuinely not here, and the scan is not vacuous
    git log --all --oneline -S'2026-07-29' -- 'docs/adr/0003-*'   # no commit, ever
    git log --all --oneline               -- 'docs/adr/0003-*'   # 10 commits

    # the consuming repo — where it actually is
    grep -n "Amendment (2026-07-29)" ../tadeumendonca-io/docs/adr/0003-trunk-based-single-environment.md
    # 48:## Amendment (2026-07-29) — how a ratification is proven, and what no longer needs one

The local pathspec is a **glob** rather than the record's full filename, deliberately: the file is gone
at head, and spelling it out would be a repo-root-relative citation of a deleted record — which the
citation gate catches, correctly, and which is the same example trap in the path form that the row rule
already names in the prose form.

**The non-vacuity count published above read `3` until 2026-08-20, and it is corrected in place rather
than quietly.** `3` is what `--diff-filter=A` returns; the command printed beside it carries no such
filter and returns `10`. A number measured with a narrower filter than the command published next to it
is this section's own subject one layer down — the falsifier was right, the digit beside it answered a
different command — and it shipped one line below the paragraph correcting the same shape.

**The rule's ownership, corrected with the number.** The claim the four sites carried is live, and this
record made it mechanical **for a verdict owed between personas** — the consuming repo's amendment had
already mechanised it for the owner's own ratification, so this record extended the rule to a second
case rather than originating it. The consuming repo's amendment is dated
2026-07-29 and this record 2026-08-02, which is what this record's own *Context* means by *"The loop
already held that…"*. A statement that the rule *"is this record's own decision"* stood here until
2026-08-20 and was wrong in the same direction as the number it was defending.

The four sites now name the rule and, where they name its source, name the consuming repo's record **by
title**, never by prefixed number — the number is the thing that collided. This is the failure the
citation gate names in its own header and cannot catch — *the prose form is checked for existence, not
for aim* — with a sharper edge than the header describes: an unresolvable token can be **wrong in two
opposite directions**, dangling (nothing behind it) or colliding (the wrong thing behind it), and a
repair that assumes the first produces a confident falsehood where the second was true. It surfaced only
because the record had to be read end to end in order to fold it, and then only because a reviewer ran
the falsifier against the other repo. It is the reason the aim of a re-pointed citation is a reviewer's
read in this batch and not a green.

**The PR body and the commit message of the fold that introduced this section state that no such
amendment ever existed.** The PR body has been corrected; **the commit message cannot be** — it is
immutable under this repo's no-squash, no-rewrite convention, and rewriting a pushed history to hide a
falsified claim would cost more than the claim does. Read `refactor(adr): fold 0003 into 0006` against
this section, which supersedes it.

### What this fold dropped

- **The two struck blocks inside the 2026-07-30 amendment** — the blanket `gh issue create` deny, and the
  "no `agent_type` exemption" justification — together with the round-by-round correction narrative
  around them. Both are struck history of a rule whose current form is
  [ADR-0004](./0004-controls-and-enforcement.md)'s; neither binds anything now.
- **The named accepted gap for the raw-API issue-creating route.** Not merely superseded — **false at
  head**: `hooks/scripts/permission-guard.sh` rule 5f (2026-08-04) denies a `gh api` call carrying a
  write indicator, and that file's own comment marks the gap CLOSED. Carrying it forward would have
  moved a stale claim into a live document.
- **The record's own `Links` block**, whose pointers are folded into the sentences that use them.

## Links
- [ADR-0002](./0002-roster-and-dev-loop.md) amendment #10 — the roster change that removed the
  reading party; the four costs of the absorption are recorded there, cost 3 being this one
- Makes the Definition of Done's two-gatekeeper requirement checkable rather than instructed, and reuses
  the verification shape already established for the owner's ratification — that DoD was record 0003
  and is now the section *The Merge Request Definition of Done (absorbed 2026-08-19, record 0003)* of
  this document · applies [ADR-0004](./0004-controls-and-enforcement.md)'s 2026-08-02 amendment
  (routing not capability; skills where a hook buys nothing) · closes #128.
