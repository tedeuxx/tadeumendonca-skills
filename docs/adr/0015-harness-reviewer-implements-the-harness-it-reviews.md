# 0015. `harness-reviewer` becomes the owner's IMPLEMENTER on the machinery it reviews — the pair on the
loop gains `Write`/`Edit` under the same "cannot merge" mitigation that already holds `tech-lead`, and the
proposal/build split becomes a real, owner-gated boundary rather than a convention

- **Status:** accepted
- **Date:** 2026-08-12
- **Deciders:** the owner (the reversal itself, and each `DECISION`/`DECISION REQUIRED` point below);
  written by `tech-lead`; pre-implementation stress test by `harness-reviewer` on this proposal, about
  itself, told explicitly not to soften anything (six findings, F1–F6, all re-verified independently in
  this record rather than relayed — every citation below was re-run on this branch)
- **Supersedes / superseded by:** amends [ADR-0002](./0002-agentic-dev-loop-architecture.md)'s tenth
  amendment (Decision 1) — the *"advisory, pre-implementation"* framing is struck, not rewritten; see the
  eleventh amendment added there in this same change. Everything else in that amendment (the persona's
  existence, its four costs, `security`'s absorption) is untouched.
- **Driven by:** the owner's instruction to reverse ADR-0002's tenth amendment, this session; closes
  [ADR-0012](./0012-issue-type-is-the-routing-axis-and-is-exclusive.md)'s named forward pointer (S7,
  *"this ADR names it as ADR-0015's subject and takes no position on it"*)

## Context & problem

`harness-reviewer` exists since ADR-0002's tenth amendment as **advisory and pre-implementation only**:
it stress-tests a harness proposal — hooks, settings, agent briefs, skills, commands, the plugin, MCP —
before anything is built, and it gates nothing (no merge request, no merge, no Issue). `agents/harness-
reviewer.md:4` holds `tools: Read, Grep, Glob, Bash` — no `Write`, no `Edit`. Someone else has always had
to turn its findings into a diff.

The owner now reverses that: `harness-reviewer` becomes the owner's harness-reconfiguration arm — it
reviews **and implements** changes to the harness. Five things are true of this reversal at once, and
none of them was free to assume:

1. The convention that a proposal and its build are separate Issues, separate dispatches, is prose today,
   not a control — nothing stops the same persona, same session, from filing a proposal and then
   immediately implementing against it with no owner read in between.
2. `quality-assurance`'s own boundary-class list does not name `hooks/**`, `agents/**`, `skills/**`,
   `commands/**` or `.claude/**` by path, so a harness diff can self-classify safe and self-merge today
   with zero `harness-reviewer` involvement — the mechanical trigger this decision needs does not exist.
3. A verdict `harness-reviewer` produces has no durable form — it is a transcript in a dispatch's context,
   read once and gone, which is the same failure ADR-0006 named for every other persona's verdict before
   that record gave each one an artifact.
4. `loop`-typed `ready` was named and explicitly left open by ADR-0012 — *"whether `loop` items should
   ever reach `ready` autonomously the way `product` items can"* is unresolved and this decision cannot
   proceed without resolving it, because the session-boundary control in point 1 has nowhere to attach
   without a label transition to gate.
5. The capability itself has a precedent already tried and already failed once in this exact repo — a
   path-scoped `Edit` deny — and a second untested-again proposal of the same shape would be indefensible
   given that history is on record.

This ADR resolves all five as one decision, because they are not independent: the capability grant (5)
only becomes safe with a mechanical trigger (2) and a durable verdict (3); the trigger and verdict only
close the session-boundary gap (1) if there is a label transition to gate, which requires resolving
`loop`-ready (4) and, underneath that, requires the proposal to be a real Issue in the first place — the
corollary this record calls out explicitly below rather than assuming.

## Decision drivers

- **A recommendation nobody can audit is worthless, and one nobody can overrule is a decision in
  disguise** (this repo's own framing of the tech-lead role) — the same test applies to turning an
  advisory persona into a builder: the build must still pass through a gate someone else holds.
- **A control already shown not to hold should not be proposed again as if untested**
  (`agents/quality-assurance.md:100-102`) — the capability shape must reckon with the `security`/
  `Edit(.claude/**)` failure, not repeat it under a new name.
- **"Cannot merge" is the mitigation this repo already trusts for an unscoped write grant**
  (`agents/tech-lead.md:1-4`) — the precedent to mirror, not to reinvent.
- **A rule with no state is applied inconsistently and silently** (ADR-0012's own framing of why `ready`
  needed a label) — the same is true here: a proposal/build separation that lives only in prose is
  indistinguishable from one nobody follows.
- **Reconciliation cost is paid within a tier, not across it** (ADR-0002, tenth amendment) — this
  decision does not touch tier 3's merge authority or tier 2's build mandate; it grants tier 1's third
  member a capability tier 1's first two members already have, under the same floor.

## Considered options

1. **Grant `harness-reviewer` unscoped `Write, Edit`, mirroring `tech-lead`'s exact shape, mitigated
   purely by "cannot merge" (rule 7b) — no new hook, no path-scoped deny** *(chosen)*. *Trade-off:* the
   persona now holds two roles on the same object — it can both stress-test a harness change and build
   it — which is exactly the "nobody observes the gate that signs the merge" shape `quality-assurance`
   already named as its own accepted cost when `security` merged into it (ADR-0002, tenth amendment,
   Decision 2, cost 4). Mitigated the same way that persona was: the capability cannot merge, so the
   observation moves to `quality-assurance`'s ordinary review of the harness PR rather than to a second
   internal reviewer.

2. **A path-scoped `Edit`/`Write` grant plus a new `.claude/settings.json` deny entry for what
   `harness-reviewer` may not touch** *(rejected)*. *Why not:* this control was already tried, for a
   different persona, on the same class of surface, and **measured not to hold**:
   `agents/quality-assurance.md:100-102` — *"`security` discovered that `Edit(.claude/**)` does not
   hold by editing that file while believing it was blocked."* Re-verified independently here: no hook
   observes `Edit` or `Write` at all —

       grep -n "PreToolUse" -A3 hooks/hooks.json
       → "matcher": "Bash"   (the only PreToolUse matcher in the file)

   `PreToolUse` fires on the `Bash` matcher only, so a path-scoped `deny` on `Edit(...)` has no
   enforcement layer to sit in even in principle — it would be exactly the control ADR-0008 calls a
   claim stronger than the layer can carry. Proposing it again for `harness-reviewer` would be proposing
   a control this repo has already spent a review round proving inert.

3. **Status quo — advisory only, forever** *(rejected — the owner's reversal, argued anyway for the
   record)*. *Why not, beyond the owner's decision:* the structural argument is S7's own finding
   (ADR-0002, tenth amendment, Decision 1's cost) — *"nothing enforces a dispatch. An undispatched lens
   is indistinguishable from a clean one"* — which already means an advisory-only finding fails silently
   today with no artifact behind it. Making the persona an implementer at least converts its work into a
   PR, a diff, a thing `quality-assurance` gates — an artifact, not a transcript that dies with the
   dispatch that produced it.

## Decision outcome

Chosen: **option 1**. Four corollaries follow, each forced by making the capability real rather than
notional — the same shape ADR-0012 used for its own routing decision.

### Corollary 1 — the capability shape, and explicitly nothing new in the hook layer (F6)

`agents/harness-reviewer.md`'s frontmatter gains `Write, Edit` on `tools:`, changing line 4 from
`tools: Read, Grep, Glob, Bash` to `tools: Read, Grep, Glob, Bash, Write, Edit` — the exact set
`agents/tech-lead.md:4` already carries. The mitigation is the same two rules already mechanical for
this persona and requiring **no new rule**:

- **Rule 7b** denies `gh pr merge` to every `agent_type` other than `quality-assurance` — `harness-
  reviewer` is a subagent, does not match `*:quality-assurance`, and is denied by the catch-all
  (`hooks/scripts/permission-guard.sh:136`, re-verified). It could not merge before this grant and
  cannot merge after it.
- **Rule 5d** denies `gh issue create` to every subagent except `developer` — `harness-reviewer` is
  denied by the same catch-all (`hooks/scripts/permission-guard.sh:135`, re-verified). It cannot file
  its own proposal Issue; see Corollary 3.

**No new `PreToolUse` matcher is needed, and `tech-lead`'s own unscoped grant is the proof**: `hooks/
hooks.json:3-5` registers `PreToolUse` on the `Bash` matcher only, so `Edit` and `Write` are invisible to
the hook layer for every persona that holds them, `tech-lead` included, today. `tech-lead`'s brief already
states its own mitigation in those terms — *"advisory on code, it proposes and never merges"*
(`agents/tech-lead.md:3`) — mechanism-free, floor-only. `harness-reviewer` needs the identical sentence
for the identical reason, not a heavier apparatus the existing precedent does not require.

### Corollary 2 — the mechanical trigger `quality-assurance` needs, named precisely (F2)

Without this, "harness changes get reviewed before merge" is a sentence with no artifact behind it, the
same way `harness-reviewer`'s own dispatch has none today. Measured: neither
`agents/quality-assurance.md:397-399` (the significance criterion) nor `:714-718` (the boundary-class
list) names `hooks/`, `agents/`, `skills/`, `commands/`, or `.claude/` by path — a harness diff classifies
today by the same generic rules as any other diff, and nothing in the gate's text would catch a harness
PR merging with zero `harness-reviewer` involvement.

**Decision:** `agents/quality-assurance.md`'s boundary-class list (`:714-718`) must gain this criterion,
stated precisely enough that the edit is mechanical rather than a judgement call for whoever makes it:

> A diff touching `hooks/**`, `agents/**`, `skills/**`, `commands/**`, or `.claude/**` requires a
> `harness-reviewer` verdict marker present on the PR (Corollary 3) before it may classify as safe or
> merge. Absent that marker, the diff is boundary class regardless of what else it does.

**Consequent work, out of scope here** (this ADR's write scope is `docs/adr/**`): the actual edit to
`agents/quality-assurance.md:714-718` adding this criterion. Not designed further — the wording above is
the whole of what that edit needs to say.

### Corollary 3 — the durable verdict, and the gap it opens in `permission-guard.sh` (F3)

`harness-reviewer`'s output becomes a real artifact: an `<!-- harness-reviewer-verdict: ... -->` marker
posted as an Issue comment, following ADR-0006's shape, referenced against a **commit SHA of the repo
state reviewed** rather than a PR head SHA — a harness scenario is frequently reviewed before any PR
exists, so a PR-head reference would have nothing to point at for Corollary 4's own proposal dispatch.

**The gap this opens, named rather than assumed closed:** `harness-reviewer` "never posts" has been a
documentation-only rule in its own brief, not guard-enforced. Re-verified —
`hooks/scripts/permission-guard.sh:133-143`:

> `harness-reviewer` joined the roster on 2026-08-04 and needs no rule of its own. [...] It is NOT
> denied `gh pr comment`, and that is deliberate rather than an oversight: 5e's argument is the
> irreversibility of paraphrasing PRIVATE material (`.brand/`) into a public comment, and `harness-
> reviewer`'s mandate is the machinery [...] which is published in this repo already. [...] Its "never
> posts" is an instruction in `agents/harness-reviewer.md`, on the same footing as `tech-lead`'s.

That reasoning holds unchanged for **posting a verdict on a public, methodology-machinery Issue** — the
exact case this corollary makes routine rather than exceptional. What it does not yet examine is the
**other direction**: now that posting is a desired, routine capability, the boundary of what
`harness-reviewer` should **not** be allowed to post has never been drawn, the way `product-lead` is
denied writing entirely (rule 5e) for a reason specific to `.brand/`'s privacy. `harness-reviewer` has no
`.brand/` exposure, but it does have read access to the whole repo, including any future private material
under a different path.

**Consequent work, out of scope here:** examine and, if warranted, add a `permission-guard.sh` boundary
for what `harness-reviewer` may not post — not designed here, because no such private-material class is
known to exist in its domain today, and inventing one to close a hypothetical gap is the shape this
repo's own reviewer is instructed to be suspicious of.

### Corollary 4 — `loop`-typed `ready` is an owner-only transition, closing ADR-0012's own open question
(F1, F4)

ADR-0012 named this precisely and took no position: *"[ADR-0012] did NOT decide whether `loop` items
should ever reach `ready` autonomously the way `product` items can."* This record resolves it.

**Decision:** for `loop`-typed Issues, the `ready` label transition is an **owner-only** action — never
applied by a dispatch, including `harness-reviewer`'s own. This is what converts "separate Issue for
proposal versus build" from a convention into an actual gate: a proposal dispatch may file the Issue and
post its findings (Corollary 3), but nothing in this loop lets the same or a later dispatch move that
Issue to `ready` and start building against it without the owner having read the proposal artifact and
acted on it. For `product`-typed Issues, `ready` continues to be applied by the two leads reconciling
between themselves (ADR-0012, unchanged) — this decision narrows to the `loop` type only, the one whose
build capability this ADR is granting.

This directly closes the session-boundary gap named in the Context: a second dispatch that would
implement against a `loop` proposal cannot begin, mechanically, until the owner has touched the artifact
the first dispatch produced. It is the label-transition analogue of ADR-0012's Corollary 1 predicate
change, applied at the one type this ADR concerns.

**Consequent work, out of scope here:** whether the transition should also be enforced at the floor (a
`gh label` guard keyed on issue type, the same open question ADR-0012 and ADR-0013 already named and left
unresolved for `product`) is a which-layer-can-carry-this-control question (ADR-0008), not decided again
here. Today it is owner-only **by instruction**, the same footing `harness-reviewer`'s own "never posts"
rule stood on before this record examined it — named as a cost below, not silently upgraded to enforced.

### Corollary 5 — harness proposals enter the tracker as real Issues (F5), and this is a corollary of
Corollary 4, not an orthogonal decision

`dev-loop/SKILL.md:43-53` states today that `harness-reviewer` "does not put it in the tracker" and "It
gates nothing: no merge request, no merge, no Issue, no label transition." Corollary 4's owner-only
`ready` gate has nothing to attach to without an Issue to hold the label — a transition needs a subject.
**This record treats tracker entry as forced by, not separate from, the gate this ADR is built to add**,
rather than a fourth independent sub-decision the owner happens to also want: the moment `loop`-ready
becomes a real gate, a harness proposal that never enters the tracker has no artifact for that gate to
act on, which reopens exactly the session-boundary hole Corollary 4 closes.

**Decision:** a harness proposal that warrants stress-testing before a build is filed as a `loop`-typed
Issue, carrying `harness-reviewer`'s verdict marker (Corollary 3). Filing is unchanged by this ADR in
**who** does it: `harness-reviewer` remains denied `gh issue create` (Corollary 1, rule 5d's catch-all,
unchanged), so the Issue is opened the same way every Issue in this loop is opened today — by the
orchestrator, asked, per *"Review does not open work"* (`dev-loop/SKILL.md:254-267`). Nothing about "only
the owner opens work" is loosened; a proposal dispatch names the Issue it wants filed, the orchestrator's
existing ask-flow is the gate on whether it is filed at all, and Corollary 4's `ready` gate is what
happens after.

**Consequent work, out of scope here:** `dev-loop/SKILL.md:43-53`'s stated rule reverses — "it does not
put it in the tracker" and "no Issue" become false the moment this ADR is ratified. Named, not edited;
`dev-loop/SKILL.md` is outside this ADR's `docs/adr/**` scope, following ADR-0012's and ADR-0014's own
citation discipline for the same class of owed correction.

### Corollary 6 — the two execution-defect bugs travel with the same PR that grants the capability

Re-verified, both in `agents/harness-reviewer.md` as it stands before this ADR:

- `:170` — *"Write probe files with the `Write` tool rather than through the shell"* — instructs using a
  tool the frontmatter (`:4`) does not grant.
- `:27-42` (the "Working files" section) presupposes a file-writing capability the persona does not hold
  today, without ever naming `Bash` as the fallback — silent about the very constraint `:170` runs into.

Both become literally true the moment Corollary 1 lands, since the persona gains `Write`. **They are not
fixed here, and not fixed as a separate pre-step**: the fix is two sentences, in the same implementing PR
that edits `:4`'s `tools:` line, because there is no intermediate state in which the bug exists and the
grant does not — writing the frontmatter change without touching `:170`/`:27-42` in the same commit would
ship a persona whose own brief still describes a tool it now has as one it doesn't.

## What this record does NOT decide

- **`quality-assurance`'s boundary-class list edit itself** (Corollary 2) — the wording is specified; the
  file is not touched here (`docs/adr/**` only).
- **The `permission-guard.sh` posting boundary** (Corollary 3) — named as an open question, no rule
  proposed, because no private-material class in `harness-reviewer`'s domain is known to exist today.
- **`dev-loop/SKILL.md:43-53`'s rewrite** (Corollary 5) — named, not made.
- **`skills/principles/loop-engineering/SKILL.md:78`'s rewrite.** It states, live and unstruck as of
  this record: *"It is **advisory and pre-implementation**: it gates nothing, reviews no merge request,
  merges nothing and opens no Issue."* — the exact phrase this ADR reverses. Named here rather than left
  for a reader to find the drift themselves, the same discipline ADR-0014 owed `README.md:497-499`. Not
  edited — outside `docs/adr/**`.
- **`agents/quality-assurance.md:117`'s smaller instance of the same drift** (*"It posts no verdict, holds
  no veto"*, said of `harness-reviewer`) — becomes false once Corollary 3 ships. Named alongside the
  `:714-718` boundary-class edit already owed (Corollary 2), not a separate item.
- **Whether `loop`-ready should also be floor-enforced**, beyond instruction (Corollary 4) — a
  which-layer question left to ADR-0008's own test, not resolved by fiat here.
- **The actual `agents/harness-reviewer.md` frontmatter edit and the two sentence fixes** (Corollaries 1
  and 6) — named precisely, not executed; this record's write scope is `docs/adr/**`.
- **Whether `harness-reviewer` should also gain a merge role.** It does not, under any reading here —
  rule 7b's catch-all is unchanged and this ADR does not propose amending it. The persona builds; it does
  not sign off on its own build.
- **Any change to `product`-typed `ready`**, which stays governed by ADR-0012 (the two leads,
  unchanged). Corollary 4 is scoped to `loop` only.

## Consequences

**Good**

- **Advisory findings stop dying with the dispatch that produced them.** Corollary 3 gives every
  `harness-reviewer` finding a durable artifact, closing the cost ADR-0002's tenth amendment named and
  left open — *"an undispatched lens is indistinguishable from a clean one."* A posted verdict is at
  least checkable after the fact, even if a dispatch is still skipped.
- **The proposal/build boundary becomes a real gate instead of a convention.** Corollary 4 is the one
  piece of mechanism that makes "separate Issues, separate dispatches" true rather than aspirational —
  the second dispatch cannot begin until the owner has acted on the first artifact.
- **A harness diff can no longer self-classify safe by accident.** Corollary 2 closes a gap that existed
  independently of this decision — today, before this ADR, nothing stops a harness change from merging
  with zero `harness-reviewer` involvement at all, which this record fixes as a byproduct of making the
  new capability accountable.
- **No new hook mechanism, no new class of control to maintain.** Corollary 1 reuses a mitigation this
  repo already trusts (`tech-lead`'s precedent) instead of re-inventing a path-scoped deny already shown
  not to hold.

**Bad / accepted costs**

- **`harness-reviewer` now plays two roles on the same object — reviewer of a harness proposal and
  builder of it.** This is the identical shape `quality-assurance` named as its own accepted cost when
  `security` merged into it: "nobody observes the gate that signs the merge" (ADR-0002, tenth amendment,
  Decision 2, cost 4). Mitigated the same way — it cannot merge, so `quality-assurance`'s ordinary review
  of the resulting PR is the observation, not a second internal check. Accepted explicitly, not papered
  over: the persona reviewing its own build is a real reduction in independence relative to the
  advisory-only model, traded for the advisory-only model's own failure (findings with no artifact).
- **`loop`-ready is owner-only by instruction, not by floor enforcement.** Corollary 4's gate is exactly
  as strong as the owner's habit of reading the artifact before acting — the same caveat this repo
  already carries for `harness-reviewer`'s "never posts" rule and for `product`-typed relabeling
  (ADR-0012, ADR-0013). Left open rather than pretended closed.
- **Three pieces of consequent work are named and not done**: the `quality-assurance` criterion text
  (Corollary 2), the `permission-guard.sh` posting boundary (Corollary 3), and `dev-loop/SKILL.md:43-53`'s
  rewrite (Corollary 5) — plus the frontmatter and brief edits themselves (Corollaries 1 and 6). None of
  these is designed further here; each is precise enough that its own future edit has no judgement call
  left in it.
- **A fourth persona now holds an unscoped `Write, Edit` grant mitigated purely by "cannot merge."** The
  mitigation has held for `tech-lead` since that persona was created; this record extends the same trust
  to a second persona on the strength of the same mechanism, not a new one — but it is now load-bearing
  for two personas instead of one, and a future defect in rule 7b's catch-all would compromise both at
  once rather than one.

## Links

- [ADR-0002](./0002-agentic-dev-loop-architecture.md) (tenth amendment, Decision 1) — the record this ADR
  reverses on the advisory/pre-implementation point; amended in place, in this same change, with an
  eleventh amendment pointing here rather than rewriting the tenth's text.
- [ADR-0012](./0012-issue-type-is-the-routing-axis-and-is-exclusive.md) — cited for the exact open
  question this ADR closes (S7, `loop`-ready autonomy) and for the separate-dispatches mitigation the
  owner already named there as the shape a future capability decision should take; also the source of
  `(product OR loop) AND ready`, which Corollary 4 narrows for `loop` specifically.
- [ADR-0006](./0006-a-verdict-owed-to-another-persona-is-an-artifact.md) — the shape Corollary 3's marker
  follows (Issue-comment, not a relayed claim), and the precedent for referencing a commit SHA rather
  than a PR head where a PR may not yet exist.
- [ADR-0008](./0008-which-layer-carries-a-control.md) — cited for the routing test Corollary 1's rejected
  option (2) fails on (no hook layer exists for `Edit`/`Write` at all) and for the open which-layer
  question Corollary 4's floor-enforcement point defers rather than answers.
- `agents/quality-assurance.md:100-102` — re-verified: the `security`/`Edit(.claude/**)` failure that
  disqualifies Corollary 1's rejected option 2.
- `agents/quality-assurance.md:397-399,714-718` — re-verified: the significance criterion and
  boundary-class list Corollary 2 names the exact addition for.
- `agents/tech-lead.md:1-4` — re-verified: the unscoped `Write, Edit` precedent Corollary 1 mirrors.
- `agents/harness-reviewer.md:4,27-42,170` — re-verified: the current tool grant, the scratch-file
  section, and the two execution defects Corollary 6 names. (The permission-guard commentary quoted in
  Corollary 3 is a separate file — `hooks/scripts/permission-guard.sh:133-143`, cited on its own line
  below — not this one; an earlier draft conflated the two.)
- `hooks/hooks.json:3-5` — re-verified: `PreToolUse` registers on the `Bash` matcher only, the fact
  Corollary 1 relies on for "no new hook needed."
- `hooks/scripts/permission-guard.sh:133-143` — re-verified verbatim: the comment explaining why
  `harness-reviewer` needs no rule of its own, quoted in Corollary 3.
- `hooks/scripts/permission-guard.sh:135,136` — re-verified: rules 5d and 7b's catch-alls, already
  denying `gh issue create` and `gh pr merge` to this persona before and after this grant.
- `skills/principles/dev-loop/SKILL.md:43-53,254-267` — re-verified: the current "does not put it in the
  tracker" rule Corollary 5 reverses, and the *Review does not open work* ask-flow Corollary 5 relies on
  unchanged.
