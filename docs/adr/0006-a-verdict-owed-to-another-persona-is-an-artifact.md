# 0006. A verdict one persona owes another is an artifact on the PR, not a relayed claim

- **Status:** accepted
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
- ~~`quality-assurance` verifies three conditions before merging … and names which of the three
  failed.~~ **Superseded by the 2026-08-03 amendment**, which replaced this three times over — see
  *Three conditions could not express `malformed`* below. The current rule is **gather · parse ·
  select · judge**, each outcome named rather than numbered, and it is stated in
  `agents/quality-assurance.md`. **No count and no enumeration is kept here**: this bullet carried a
  three, then a five, then a five contradicting the amendment printed below it — *a count is an
  enumeration with the items deleted, and it drifts identically.*
- The check runs **immediately before the merge, not at review start**, so the two gates stay parallel.
- **Both** gatekeepers derive the diff from `gh pr diff` / `gh pr view --json files`, never from a local
  `git diff` against a ref they picked. This is the same principle in the evidence dimension: a
  self-chosen ref is a relay about what was reviewed.

## Consequences

**Good**
- `quality-assurance`'s merge precondition becomes a query rather than a matter of trust, satisfiable
  only by the other gate having actually run and written something.
- ~~A stale verdict fails **loudly**. The head-SHA comparison is an exact string match, not a
  clock-ordering argument.~~ **Overstated twice; corrected in the 2026-08-03 amendment below.** The
  comparison discriminates on **form**, and staleness is only inferable from it when the artifact is
  well-formed; the SHA is **self-reported by the writer**; and *"loudly"* names no audience.
- The transition finally has the artifact its own state table always claimed.
- It leaves a record a future sweep can audit. Today's loop produces none at all.

**Bad / accepted costs**
- **The residual, named rather than papered over:** the harness stamps `agent_type` on tool calls, not
  on comment authorship. A verified comment proves the verdict exists, is attributable to this token,
  and matches the current head — **not** that `security`'s context authored it. This closes
  **omission**, which is the observed failure. It does not close **impersonation**, ~~which has not been
  observed and~~ which no reachable mechanism in this harness closes either — option 2 above buys nothing
  against it. Overstating the guarantee would be worse than naming its limit. *(**Observed once**, the
  day after this ADR merged — see the 2026-08-03 amendment. The observation changes no decision; it
  removes the word that made the residual sound theoretical.)*
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

## Amendment (2026-08-03) — the mechanism rejected its own valid verdicts (#130)

This ADR ran live on two PRs the day it merged. **Every defect below was observed, not predicted**, and
the first one is a merge blocker rather than a naming problem.

### The contract was specified in three places and reconciled with none of them

`agents/security.md` required its marker to read `APPROVED` / `BLOCKED` / `ADVISORY-ONLY`, while **the
same file's own *How to respond* section**, which predated the marker, said *"lead with the verdict:
clean, remediated, or blocked"*. `agents/quality-assurance.md` required `APPROVED`, **a literal absent
from that persona's own verdict set** — its only other appearance in that file is the condition where it
*reads* `security`'s literal — whose canonical set is `APPROVE-AND-MERGE` / `APPROVE-PENDING-HUMAN` /
`REQUEST-CHANGES`.

Both personas wrote the vocabulary their own file already used — **which is correct behaviour** — and
both produced markers a strict reader rejects. Observed on `tadeumendonca-io#336`: verdict lines reading
`CLEAN` and `APPROVE-AND-MERGE`, neither in the set its own marker required. On
`tadeumendonca-skills#129`: `ADVISORY-ONLY`, a marker whose line 2 was prose rather than a literal, and
a `head:` field carrying a 7-character short form.

*(An earlier version of this sentence attributed `CLEAN` to both PRs. It appears on `#336` only —
mis-cited in the same sentence, and in the same way, as the `APPROVE-AND-MERGE` attribution corrected
one round earlier. Recorded rather than quietly fixed: a decision record that mis-states its own
evidence is the defect it exists to prevent.)*

**The collision fired only on the approving branch, which is why it survived so long.**
`REQUEST-CHANGES` and `APPROVE-PENDING-HUMAN` are in both sets, so every blocking round produced a
conforming marker and looked clean. The one slot that could not be written correctly was **the one that
merges**.

**And it was not latent.** On `tadeumendonca-skills#129` at head `5d678b39…`, `security` posted
`ADVISORY-ONLY` and this gate answered `APPROVE-PENDING-HUMAN` — **it did not hold.** So the observed
failure is worse than the one first recorded here: not merely a rule that would have blocked wrongly,
but a gate that read a non-approval and proceeded anyway.

**The defect is this ADR's, not the personas'.** A rule was grafted onto two files that already answered
the same question, and the graft was never reconciled with what was there. The rule that prevents the
next one, now in both files: *the marker's verdict line is a **projection of the persona's own canonical
set** and introduces no literal that set does not contain.*

### `ADVISORY-ONLY` was a gate that blocked on the most common outcome

It was a **verdict**, and `quality-assurance` holds on any line that is not an approval — while
`agents/security.md` defines ADVISORY as exactly the class that must **not** gate, being exposure the MR
did not introduce. So a review finding only pre-existing advisory items blocked the merge *by obeying
its own instruction*. **A severity axis and a disposition axis were collapsed into one line, and the
collapse defaulted to blocking.**

`security` now has two dispositions, `APPROVED` and `BLOCKED`; advisory findings ride inside an
approval, marked per finding — the model `marketing-lead` and `quality-assurance` were already using.
*Rejected: a third verdict for "reviewed but could not check axis X". A gate cannot approve what it
could not verify; that outcome is `BLOCKED` with the unreachable axis named.*

### Three conditions could not express *malformed*, and a combination cannot recover it

The original check had three predicates and reported *"which of the three failed"*. Two conditions were
missing, and the second is the one that matters:

- **Two markers from the same gatekeeper naming the same head with conflicting verdicts.** Not
  hypothetical: the cadence is per round, so markers accumulate, and a re-review at an **unchanged**
  head — a documentation fix, a re-run — produces exactly that pair. The gate reads the most recent and
  treats a contradiction at one head as a failure rather than a tie broken by reading order.
- **Whether the comment PARSES AT ALL.**

**The first attempt at this amendment tried to infer *malformed* from a combination** — *"the verdict is
not `APPROVED`"* together with *"the head does not match"* — and prescribed *re-post, not re-review*.
That is wrong, and wrong in the costly direction: **a well-formed `BLOCKED` on a superseded head
satisfies both**, which is the normal state of every block-then-fix round. The prescribed remedy was the
exact inverse of the one owed.

The lesson is more general than this rule: **a predicate that is not checked cannot be recovered from a
combination of the ones that are.** Parseability is now its own check, evaluated before the verdict is
read. *Never dispatched* and *dispatched but could not post* are given their own outcome, because they
have different owners and the gate cannot distinguish them alone — it must require the invoking context
to say which.

**And the second version was wrong too, in a way worth recording because it is the same shape one level
up.** It made the contradiction a *fifth condition* after the others, under a stop-at-first-failure
rule — which made it **unreachable in the only case it exists for**: a `BLOCKED` selected alongside an
`APPROVED` at the same head stops at the verdict check, and the contradiction is never reported,
resolved by reading order. **A condition placed after checks that can short-circuit past it is not a
condition.**

**The rule was rewritten four times, and the two gatekeepers disagreed on the fourth — which is how it
was settled.** Three shapes are recorded as superseded, because the pattern is the finding:

1. ***Combination inference.*** *Malformed* was read off *"not `APPROVED`"* **and** *"head does not
   match"* together — which is also the signature of a well-formed `BLOCKED` on a superseded head, the
   normal state of every block-then-fix round. **A predicate that is not checked cannot be recovered
   from a combination of the ones that are.**
2. ***Selection, then ordered checks.*** Put the contradiction check *after* checks that stop at the
   first failure, making it **unreachable in the only case it exists for**.
3. ***Scope everything to the current head.*** Proposed by `quality-assurance` on the sound observation
   that four defects in a row had all lived in gather/select machinery and none in `parse` or `head`.
   **`security` blocked it, and was right:** excluding a marker as *not current* means reading the head
   line you just declared unreadable, so a `BLOCKED` too broken to parse plus a later well-formed
   `APPROVED` at the same commit yields one readable verdict and a merge over a live block. The
   narrowing restored the defect it was meant to retire.

**What actually shipped keeps the strict parse and gains a retirement path**, which is what shape 3 was
really reaching for. The gate gathers **owner-authored, non-minimised** markers, parses **all** of them,
and only then selects on the current head. *Malformed* was terminal until this amendment — a re-post
appends rather than replaces, an edit sets the edit flag and is malformed again, and only deletion
clears it, destroying the artifact. **Minimising is the exit**: non-destructive, inside the trust
boundary, and selection skips it. Measured cost of not having it: #129 carries markers that
fail this parse and would have been un-mergeable in perpetuity, having already merged.

**And the strict parse is only affordable because the author filter runs first** — post-filter, only
parties already trusted to merge can create a blocking artifact, so it is a chore rather than a denial
of service. That dependency is stated **in the filter's own paragraph**, because whoever widens the
filter will be reading that and not the parse rule below it.

That the gate must **select at all** was itself unstated: the persona file said *"that comment"*,
singular, while this same amendment establishes that markers accumulate per round.

*One limit named rather than closed:* nothing asks whether the recorded SHA **names a real commit**. A
fabricated 40-hex parses and fails the head check as *stale*, prescribing a re-dispatch where the remedy
owed is a re-post with a resolved SHA. `git cat-file -t` closes it. Recorded as known — this record
contains an instance of exactly that fabrication.

### Two things the gate must not trust, booked because the read widened to find them

**Authorship.** These repos are public and anyone may comment. The gate reads markers by pattern, so
until this amendment it would have collected one left by an arbitrary account. It now filters on
**`authorAssociation == OWNER`** — that field is the test and `author.login` is corroboration only,
because GitHub computes the association and it is repo-relative, while a login is mutable, which is the
rename failure the immutable OIDC subject already ate.

*This differs from ADR-0003's ratification filter deliberately.* There the question is *did that
specific human ratify*; here it is *was this written from inside the trust boundary*, since the writer
is a subagent on the owner's token. **Portability, named because this file ships to other repos:**
`OWNER` is not returned for org members, so in an org-owned repo the gather returns nothing and stops
permanently — widening it there is a deliberate act, and it is coupled to the parse rule above.

**Edits.** A comment body can be rewritten after posting while keeping its `createdAt` and its position
in the list: `BLOCKED` at the current head, edited in place to `APPROVED`, no new artifact anywhere the
gate looks. Distinct from the *self-reported SHA* residual below — there a writer mis-states its own
commit; here a verdict already given is silently replaced. Closed by requiring `includesCreatedEdit` to
be false.

*That predicate was written once against `lastEditedAt` and it did not exist in the prescribed command.*
`gh pr view --json comments` does not return that field; `jq` yields `null` for an absent key, so
*"carries no `lastEditedAt`"* was **true of every comment, edited or not** — the hole written as closed
and left open. The field is real only through the GraphQL API. **A predicate is not a check until the
command that runs it returns the field it names.**

The working field, `includesCreatedEdit`, was **verified to flip rather than assumed to**: it reads
`true` on a comment edited earlier the same day and `false` on every unedited one in the same payload.
`security` had declined to recommend it precisely because it could not confirm that without editing a
live comment — the right caution, and the check was available from an edit already made.

### The producer side is still instruction-only, and that residual is now named

The projection rule and the parse check between them remove the *cause* of the malformations seen so far
and give the consumer a way to detect one. **Neither prevents a producer from emitting an unreadable
marker.** The shape is instruction on the writing side and always will be — nothing runs between a
persona deciding what to type and the comment landing.

The original residual booked only the **consumer** possibly not checking. The producer half was
unbooked, and it is the half that actually failed: three malformations in the mechanism's first two
days, on the third and later uses, **by the two personas whose own files define the shape.** What
changed is that a malformed marker now **holds the merge and says so** rather than being misdiagnosed;
what did not change is that it can be written.

### What *"a stale verdict fails loudly"* actually delivers

Two overstatements in one bullet, both struck above:

- **The head SHA is self-reported by the writer.** The check compares a claim against the live head, so
  it detects a verdict that is *honestly stale* and not one that is *dishonestly current* — any context
  that can read `headRefOid` can write it.
- **"Loudly" names no audience.** The failure was loud in the gate's **return** — the orchestrator's
  context, the exact medium this ADR declared untrustworthy — and **silent on the PR**, the durable
  surface it was written to reach. A later reader could not distinguish a verdict that was rejected from
  one that was never posted. **Fixed:** the gate now posts its own marker naming the failed condition
  before returning. The self-reporting half is a residual, not a fix.

### Impersonation: observed once, and the observation is why the word changed

On `tadeumendonca-io#336` the invoking context relayed a verdict for `marketing-lead` — a lens with no
`Bash` by design, structurally unable to post — first under a `gatekeeper-verdict:` marker and then
corrected in place to a non-gating `advisory-lens:` one when `security` found that a machine consumer
would read the prose disclaimer never and the namespace always — **and wrote a
`head:` SHA it had invented**, holding the 7-character short form and generating the remaining 33.
`quality-assurance` caught it by running `git cat-file -t` on the field rather than reading it, and
merged on the comment's *substance*, which re-derives from the diff, while reporting the stamp as a
channel defect.

Benign, self-disclosed, and corrected in place — which is exactly what makes it **evidence** rather than
an incident. It also demonstrates the first bullet above: the field a checker trusts is the field a
writer supplies.

**And no relay rule was written, deliberately.** A rule governing *how* a relay is performed legitimises
the path this record exists to close, and would apply first to the persona the ADR explicitly deferred
to an owner tool-grant decision — deciding an open question sideways. Instead, one sentence in both
persona files: **no context posts a marker on behalf of a persona; a verdict a persona could not post
did not happen.** `security`'s ruling stands as the axis: *a lens that cannot post is advice, not a
gate, because a gate is defined by the artifact it leaves.*

### Swept and dispositioned rather than skipped

This ADR's own *Considered options* restates the contract as *"a verdict line"* — vocabulary-agnostic,
so it survives unchanged. Recorded because a sweep that finds nothing and says nothing is
indistinguishable from one that never ran.

**`commands/principles/dev-loop.md` did NOT survive unchanged, and an earlier version of this paragraph
said it did** — while the same diff was editing it. It carried the contract in **two** places that had
already drifted into two *different* four-of-five subsets, and the one that dropped **parseability**
dropped the predicate that rejects a malformed verdict: the fail-open direction. **Both now point here
rather than re-enumerating**, because the enumeration is the thing that drifts.

*Line-number citations are deliberately absent from this paragraph.* The earlier version carried them
and they were stale within one round.

## Links
- Makes [ADR-0003](./0003-mr-definition-of-done.md)'s two-gatekeeper requirement checkable rather than
  instructed; reuses the verification shape its 2026-07-29 amendment established for the owner's
  ratification · applies [ADR-0004](./0004-autonomy-and-permission-model.md)'s 2026-08-02 amendment
  (routing not capability; skills where a hook buys nothing) · closes #128.
