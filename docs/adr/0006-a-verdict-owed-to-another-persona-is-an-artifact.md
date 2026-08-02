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

3. **The status quo relay.** *Why not:* it is the defect. It made a gate's own rule unverifiable, and
   it delivered a false claim about a diff without anyone noticing until the consumer independently
   re-derived the file list.

2b. **Gate the COMMENT rather than the merge** — deny a `gh pr comment` whose body carries a marker
   naming a persona the caller is not running as. *Recorded because the first draft of this ADR never
   considered it, and both gatekeepers found the omission independently.* It is **not** equivalent to
   option 2: it would narrow the attributable set from *"anyone holding `Bash`"* — which is what it is
   today — to *"the main loop deliberately spawning `security`"*. So the routing-not-capability argument
   does not dispose of it. *Why not, on the better reason:* this decision **mandates `--body-file`**, so
   the marker is not in the command string at all; the hook would have to resolve a path argument and
   read the file to find it, which is the same fragility class as rule 5d — a matcher inferring intent
   from what the model happened to type, losing one spelling at a time. The conclusion survives; the
   reasoning in the first draft was one option short, and an ADR whose stated job is naming its own
   limit should name the option it did not consider.

4. **A GitHub review approval instead of a comment.** *Why not:* GitHub refuses a review approval from
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
- `security` posts before returning, on every review including clean ones.
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
- **Neither gatekeeper has a `Write` tool**, so the body goes through Bash — where rule 8 of the floor
  denies a backtick, `$(`, `;` or a chain operator outside a quoted span. A verdict needing a literal
  backtick is denied, and the gate then blocks for a reason unrelated to review quality. Workable today
  (both personas are instructed to author around it and one has already done so under this rule), and
  the clean fix is a scratchpad-scoped `Write` grant — **an ADR-0004 tool-grant decision, so recorded
  here as an open question rather than taken.**

**Open question, recorded rather than settled.** `marketing-lead` has the identical hole:
`quality-assurance` is told to confirm the copy lens returned a verdict, and cannot. It is
**deliberately out of scope** — that persona is granted `Read, Grep, Glob` and **no `Bash`**, and the
scoping is intentional because it never writes, the voice being the owner's. Covering it means trading
a deliberate tool grant against verifiability, which is an ADR-0004 decision and the owner's to make.

## Links
- Makes [ADR-0003](./0003-mr-definition-of-done.md)'s two-gatekeeper requirement checkable rather than
  instructed; reuses the verification shape its 2026-07-29 amendment established for the owner's
  ratification · applies [ADR-0004](./0004-autonomy-and-permission-model.md)'s 2026-08-02 amendment
  (routing not capability; skills where a hook buys nothing) · closes #128.
