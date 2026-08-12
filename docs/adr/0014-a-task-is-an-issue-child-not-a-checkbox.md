# 0014. A task is an Issue **child** — its own Issue, its own branch, its own PR, with `Parent: #N` in
its body — not a checkbox on the story

- **Status:** proposed
- **Date:** 2026-08-12
- **Deciders:** owner (ratifies) · tech-lead (writes the record)
- **Supersedes / superseded by:** —
- **Driven by:** a `harness-reviewer` pre-implementation stress test of this proposal (5 scenarios,
  independently re-verified by tech-lead before this record was written); no Issue — methodology-library
  decision, filed and closed at tier 1

## Context & problem

The tree currently asserts two different models of what a task is, and neither is fully live.

`agents/developer.md:111-141` already reads as though a task is a **real Issue**: it is filed with
`gh issue create`, it must "reference the parent in the issue body, so what authorised the task is
visible to a human reading the task later," and `quality-assurance` is named as the check on "the task's
own MR" — language that presupposes a task has its own MR, hence its own branch and PR.

`hooks/scripts/wip-guard.sh:74-77` (struck-through prose, retired 2026-08-04) measured the opposite
model as the one that actually ran: *"a user story's tasks are CHECKBOXES on its issue, not branches...
Measured across roughly NINETY branches in this repo, NOT ONE task branch has ever existed — no
`story/*`, no `task/*`, and no PR whose base is another feature branch."* Re-verified here, verbatim at
those line numbers.

So the tree has been carrying a live contradiction: a persona brief written as though tasks are Issues,
and a measured ninety-branch history in which they never were. This record resolves it by choosing the
Issue-child reading and naming what building that mechanism requires — the checkbox model was tried (by
absence, not by an explicit competing design) and produced zero task branches, ever.

**What this ADR is not.** It does not decide issue *granularity* generally (story/task/proposal is
ADR-0012's named-but-deferred axis); it decides one thing inside that space — the **mechanism** a task
takes once it exists: child Issue, own branch, own PR, `Parent: #N` in the body.

## Decision drivers

- The brief already in force (`agents/developer.md`) presupposes a task's own MR; a checkbox has no MR to
  gate, so the brief and the DoD (`quality-assurance` reviewing "the task's own MR against the parent")
  cannot both be literally true of the same object under the checkbox model.
- A checkbox is not independently reviewable, not independently mergeable, and carries no gate of its
  own — it inherits the story branch's single review, which is the opposite of "thin vertical slice,
  bounded by overlap" (`engineering-philosophy`, principle 3) applied at the task grain.
- Two mechanisms in this repo were built and then retired specifically for the checkbox/story-branch
  model — `wip-guard.sh`'s two-level overlap rule and `permission-guard.sh`'s parent-verification block —
  and their retirement histories are load-bearing precedent for what NOT to rebuild the same way twice.
- Reconciliation cost is paid within a tier (ADR-0002, tenth amendment): a task's routing and readiness
  must not invent a new intake decision at a tier that has already ratified the parent story.

## Considered options

1. **Task is an Issue child — own Issue, own branch, own PR, `Parent: #N` in the body** *(chosen)*.
   Matches what `agents/developer.md` already assumes. *Trade-off:* it requires rebuilding, from
   scratch, a sibling-overlap exemption in `wip-guard.sh` that was deliberately removed after being
   measured to never fire (S1 below) — this ADR ships without that exemption rather than pretend
   rebuilding it is free.

2. **Task remains a checkbox on the story Issue** *(rejected — status quo)*. *Why not:* the measured
   history is that this model, run for as long as it takes to accumulate roughly ninety branches, never
   produced a single task branch. Two readings compete for why, and this record picks the more
   defensible one rather than staying neutral: either the checkbox genuinely does not fit how work
   decomposes here (a task big enough to want its own branch stops being a checkbox in practice and
   either gets folded into the story or never gets separated at all), or nothing in the loop's own
   instructions ever told a builder to open one (`agents/developer.md`'s task-filing rule is dated to
   this session, not to the ninety-branch history that preceded it). The second reading is the more
   defensible one: a mechanism that was never instructed cannot be said to have been tried and failed.
   That does not rescue the checkbox model — it means the checkbox model was simply never exercised, so
   zero-in-ninety is evidence of absence-of-instruction, not evidence the model fails once instructed.
   Rejected anyway, on the independent driver above: a checkbox has no MR, so the brief and DoD already
   in force cannot describe it, and rewriting them backward to fit checkboxes throws away the review
   granularity a task-level gate buys.

3. **Reinstate hook-side `Parent: #N` verification, now that a real parent reference exists to verify**
   *(rejected)*. *Why not:* `permission-guard.sh:843-858` (struck 2026-08-02) records four
   correct-in-sequence fixes to exactly this mechanism — word-anchoring the marker, taking the
   first match rather than the last, scoping the repo lookup off `$bare` rather than an embedded `-R`,
   then a `gh issue view` readiness check — and the whole mechanism was still deleted afterward, not
   because the fixes were wrong but because **intent is not recoverable from a command string**
   (ADR-0004, amendment 2026-08-02, quoted in the retired block: *"Mechanism where the act is
   irreversible. Skills where the rule is a judgement"*). Whether the parent marker points at a checkbox
   or a real Issue is orthogonal to that failure mode — the string is exactly as unverifiable either way.
   Reinstating hook-side verification now would repeat a four-round history at the exact place it was
   abandoned, for a reason the new object (a real parent Issue) does not remove.

## Decision outcome

Chosen: **option 1**. It is not a new design so much as making explicit and mechanically real what
`agents/developer.md:111-141` already assumed in prose, and retiring the model the tree's own measurement
(`wip-guard.sh:74-77`) shows was never exercised in ~90 branches.

### On S1 — the sibling-overlap exemption is NOT rebuilt in this ADR; task-as-child ships restrictive

`wip-guard.sh:216-236`'s surviving overlap rule denies a new PR that touches a file an open PR by the
same author already touches, with **no story/parent carve-out in executable code**. The carve-out that
would permit two sibling task PRs (under one story) to legitimately touch the same file exists only as
struck-through prose at `wip-guard.sh:55-101` (retired 2026-08-04) — re-verified: that block also
documents four defects found in the original two-level implementation (attached-option-value parsing
missed by a space-only regex; a branch name interpolated unescaped into a regex, since `.` is legal in a
git ref; a missing `jq` field default silently making the whole rule vanish; and a vacuous test for that
third defect, which passed with the line under test deleted because it exercised only a non-story
branch).

**Decision: ship task-as-child without the sibling-file exemption.** Two sibling tasks under one story
that would touch the same file are **blocked** by the existing overlap rule until a later slice
explicitly rebuilds the exemption. Reasoning: the four-defect history shows this specific mechanism is
genuinely hard to get right in shell, and a temporarily-restrictive guard fails **safe** — it denies
legitimate work, loudly, at the point of the `gh pr create` call — rather than failing **open**, which
would silently reintroduce a bug class this file has already caught four times. A denied PR is a visible,
one-line-reason event a builder acts on immediately; a silently-passed overlap is invisible until it
surfaces as a conflicted merge.

**Consequent work, out of scope here:** rebuilding the sibling-file exemption in `wip-guard.sh`, as new
code informed by the four-defect history — not a revert of the struck block, since a revert would also
resurrect defects that block already contains. Whoever rebuilds it must, at minimum, name a test fixture
with a **mixed open set carrying a fieldless entry first**, since that is the shape the fourth historical
defect could not be caught by (a test using only a non-story branch short-circuited before the fieldless
default was ever consulted).

### On S2 — hook-side parent verification is NOT reinstated

Recorded as option 3 above (rejected). Stated explicitly here because a reader could otherwise assume a
real `Parent: #N` marker reopens a question ADR-0004 already closed: it does not, because the failure
mode struck at `permission-guard.sh:843-858` was never about whether a real Issue existed on the other
end of the marker — it was that a command string cannot prove intent, and a fabricated `Parent: #187`
string is exactly as unverifiable by grep as a fabricated checkbox reference was.

**Consequent work, out of scope here:** `quality-assurance` gains a checkable, Read-only option during
its review of a task's MR — running `gh issue view <parent> --json labels` itself to confirm the story
the task claims as parent is real and carries `ready`. Naming it, not designing it: whether and how
`agents/quality-assurance.md` adopts this is that brief's own edit, not this ADR's.

### On S3 — a task inherits the parent story's type and readiness; it gets no independent label

ADR-0012 names this exact collision as an open forward pointer to this record ("What this record does
NOT decide" → *"Task-as-Issue-child... whichever ADR decides task-as-child must reconcile with that
measurement"*) — re-verified at `docs/adr/0012-issue-type-is-the-routing-axis-and-is-exclusive.md:224-228`.

Two questions, decided together because they have the same answer:

1. **Does a task inherit the parent story's routing type (`product`/`content`/`loop`), or is it
   independently routed?** Inherits. A task is a decomposition of already-approved, already-routed work —
   it is not a new intake decision, and giving it an independent type would let a single story's work
   scatter across routing lanes mid-execution, which nothing in the loop's intake chain anticipates or
   reconciles.
2. **Does a task need its own `ready` label to be picked up, or does the parent's `ready` cover the whole
   tree?** The parent's `ready` covers it. `agents/developer.md:111-135`'s task-filing rule already checks
   the **parent's** `ready` label before a task may be filed at all (*"Only a task under a story that
   carries `ready`"*) and states nothing about applying `ready` to the task itself — a measured absence in
   the exact section that would naturally state it, re-verified by reading `agents/developer.md:111-141`
   directly rather than trusting this claim relayed. A task requiring its own separate readiness
   ratification would mean the leads re-close an already-closed description, once per task, which
   contradicts the reason tasks exist (dividing already-approved work, never re-litigating it).

**Decision:** tasks carry no independent `product`/`content`/`loop` label and no independent `ready`
label. Routing and readiness are read off the parent Issue named in the task's `Parent: #N` reference.
This is a judgement call, not a measurement — recorded as the owner's ruling on this record, open to
revisiting if a task-heavy workflow later shows the inherited model does not scale.

### On S4 — this record does not close the label-scoping gap; it explicitly inherits it, and only if S3
had gone the other way would it be load-bearing

Because S3 concludes tasks carry **no** independent label of any kind, the `gh issue edit`/`gh label`
scoping gap ADR-0013 already names as an accepted-but-unclosed cost (`gh issue edit`/`gh label` sit
unscoped in `.claude/settings.json`'s committed `allow` — re-verified: `:51,54` — with zero matching rule
in either guard script, self-documented by `permission-guard.test.sh:336`'s use of `check` rather than
`check_agent`) is **not newly load-bearing on the mechanism this ADR decides.** Stated plainly rather than
manufactured into a connection that does not exist: no task label means no new labelling surface for this
gap to widen. If a future revision of S3's decision introduces a per-task label of any kind, that revision
inherits the same open gap ADR-0013 already named — this record does not close it either way.

### On S5 — `quality-assurance` has no sibling-PR awareness; named as consequent work, not designed here

Re-verified: `grep -in "sibling\|concurrent\|parent issue\|Parent:" agents/quality-assurance.md` returns
nothing. Once sibling task PRs exist as a real mechanism (even restricted, per S1, to non-overlapping
files for now), a scenario the gate's brief does not anticipate becomes live: PR A merges first; PR B's
diff can then contain hunks that read as unexplained drift relative to B's own task description, with
nothing in the gate's brief telling it to check for a sibling before flagging that as a finding.

**Consequent work, out of scope here** (this is `tech-lead`'s design call on `agents/quality-assurance.md`,
not `harness-reviewer`'s to make and not this ADR's `docs/adr/**` scope to execute): a future edit to that
brief should name the mitigation option of checking `gh issue view <parent> --json body` for sibling task
references before flagging cross-task drift as a finding against the task under review. Not designed
further here.

### `README.md` states the retired model as live prose, and this record owes it a correction

`README.md:497-499` reads, unstruck, as of this record: *"**One user story, one branch, one pull
request.** The story's tasks are checkboxes on its issue, not branches — so the branch layer has exactly
one level, and the pull request the gate reviews is the unit that has product meaning."* This decision
makes that sentence false the moment it is ratified. ADR-0012 named the identical class of owed
`README.md` correction explicitly rather than leaving a reader to find the drift themselves
(`docs/adr/0012-issue-type-is-the-routing-axis-and-is-exclusive.md`, "What this record does NOT decide");
this record follows that precedent rather than breaking it silently.

**Consequent work, out of scope here** (`README.md` is outside this ADR's `docs/adr/**` scope): update
`README.md:497-499` to state the branch layer now has two levels — one branch per story, one branch per
task, each with its own PR — and that the sibling-file exemption is not yet rebuilt (S1), so two sibling
tasks touching the same file are blocked until it is. Not edited here.

## Consequences

**Good**

- Resolves a live contradiction rather than leaving it to be discovered by whichever persona hits it
  first: `agents/developer.md` already reads as though tasks are real Issues, and this record makes that
  literal rather than aspirational.
- Task-level review becomes possible at all — a checkbox on a story issue has no MR, no diff of its own,
  and no gate of its own; a task-as-child gets a real `quality-assurance` pass scoped to just that slice.
- Ships the restrictive version of the overlap rule rather than a rebuilt exemption nobody has re-derived
  yet — failing safe (denying legitimate sibling-file work) over failing open (silently reintroducing a
  bug class already caught four times).
- Explicitly forecloses re-litigating ADR-0004's closed question (hook-side intent verification) under
  the guise of "now there's a real Issue to verify" — the object changed, the failure mode did not.

**Bad / accepted costs**

- **Sibling tasks touching the same file are blocked until a later slice rebuilds the exemption.** This is
  a real capability loss relative to what a fully-built task-child model would allow — named, not hidden,
  and the four-defect history is the reason it is not rebuilt inline here.
- **No task-level readiness label means a task cannot be independently paused or re-scoped via labels**
  without touching the parent — if that turns out to matter in practice, it is a reason to revisit S3's
  ruling, not a defect in this record.
- **The `quality-assurance` sibling-awareness gap (S5) ships live** the moment the first two sibling task
  PRs land, however rare that is under the S1 restriction — named as consequent work, not mitigated here.
- **This record creates real branch/PR volume where a checkbox model created none** — every task is now a
  full slice with its own review overhead, which is a heavier mechanism than a checkbox, chosen because
  the checkbox model measurably never got used rather than because it is cheaper.
- **`README.md:497-499` states the retired checkbox model as live prose the moment this ADR is ratified**
  — named as consequent work, not fixed here, following ADR-0012's own precedent for the same class of gap.

## Links

- [ADR-0004](./0004-autonomy-and-permission-model.md) — cited: the *"mechanism where the act is
  irreversible, skills where the rule is a judgement"* principle this record's S2 decision rests on, and
  the amendment recording why hook-side parent verification was deleted rather than perfected.
- [ADR-0012](./0012-issue-type-is-the-routing-axis-and-is-exclusive.md) — cited: names this exact
  collision as its own unresolved forward pointer (`docs/adr/0012-...md:224-228`); this record closes
  that pointer.
- [ADR-0013](./0013-the-orchestrator-is-a-named-role-not-a-persona.md) — cited: the `gh issue
  edit`/`gh label` scoping gap this record explicitly does not close and, per S3's ruling, does not widen
  either.
- [ADR-0002](./0002-agentic-dev-loop-architecture.md) (tenth amendment) — cited for *reconciliation cost
  is paid within a tier*, the driver behind S3's inheritance ruling.
- `agents/developer.md:111-141` — the task-filing rule this record makes literal.
- `README.md:497-499` — states the retired checkbox model as live prose; the correction it owes is named,
  not made, per this repo's own citation discipline.
- `hooks/scripts/wip-guard.sh:55-101` (struck, retired 2026-08-04) — the retired two-level/checkbox
  design and its four documented defects, cited as lessons for the exemption's eventual rebuild, not as
  something to revert.
- `hooks/scripts/wip-guard.sh:216-236` — the surviving overlap rule this record ships without an
  exemption against.
- `hooks/scripts/permission-guard.sh:843-858` (struck, retired 2026-08-02) — the four-round parent-
  verification history this record declines to reopen.
- `agents/quality-assurance.md` — grepped and confirmed to carry no sibling/parent-PR awareness (S5).
- Driven by a `harness-reviewer` pre-implementation stress test (5 scenarios; no Issue — filed and closed
  within tier 1 as a methodology-library decision).
