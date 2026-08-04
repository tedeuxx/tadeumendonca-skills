# 0006. A verdict one persona owes another is an artifact on the PR, not a relayed claim

- **Status:** accepted · **amended 2026-08-04** (the open question's premise is falsified — `marketing-lead` no longer exists and the copy lens now holds `Bash`; the decision itself is unchanged)
- **Date:** 2026-08-02
- **Deciders:** the owner
- **Driven by:** [ADR-0003](./0003-mr-definition-of-done.md), [ADR-0004](./0004-autonomy-and-permission-model.md)

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

**And the standard was inverted.** [ADR-0003](./0003-mr-definition-of-done.md)'s amendment established
that the owner's ratification is verified from the PR itself and that *a relay is a notification, never
the authority*. A gatekeeper's veto was held to a weaker standard than the owner's ratification — and
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
   the same surface with the same verification path already proven by ADR-0003.

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

## Amendment (2026-08-04) — the open question's premise is gone; the question is not

**What changed outside this record.** [ADR-0002](./0002-agentic-dev-loop-architecture.md)'s ninth
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

**A narrower observation, and it cuts the other way.** [ADR-0007](./0007-the-merge-precondition-is-a-floor-not-an-instruction.md)'s
hook reads *each persona's canonical verdict set from the persona file at runtime* — for
`quality-assurance` and `security` only. It has no dependency on the lead roster, so the roster merge
does not touch it. But it is the reason a third marker would be more than documentation: the mechanism
that would enforce one already exists and is shaped to be extended.

## Links
- Makes [ADR-0003](./0003-mr-definition-of-done.md)'s two-gatekeeper requirement checkable rather than
  instructed; reuses the verification shape its 2026-07-29 amendment established for the owner's
  ratification · applies [ADR-0004](./0004-autonomy-and-permission-model.md)'s 2026-08-02 amendment
  (routing not capability; skills where a hook buys nothing) · closes #128.
