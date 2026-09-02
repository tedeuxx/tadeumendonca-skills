# 0004. Controls and enforcement

**This record is the capability document for `controls-and-enforcement`.** It was titled *Autonomy &
permission model — classes + tool-scoping*, and filed as `0004-autonomy-and-permission-model.md`, until
2026-08-20 — when the owner decided that an anchor is named for its **capability** rather than for the
decision that originated it ([#283](https://github.com/tedeuxx/tadeumendonca-skills/issues/283), part 3
slice S3). The originating decision — classified autonomy, mechanically enforced — is unchanged and is
the body below. What changed is that this file stopped being named after one of the decisions it holds,
because the same slice absorbed **records 0007, 0008 and 0018** into it, under
[ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md)'s fourth disposition.
The number did not move, so every `ADR-0004` citation in either repository is unaffected; the
**filename** did, and every path-form citation of it was rewritten in the same commit as the rename.

**Read this document in four layers, because they answer four different questions and were four records
until 2026-08-20.** *Who may do what without asking* is the body and its amendments below — the autonomy
classes, the per-persona scoping, and where a mechanism is worth building at all. *Which layer can carry
a given control* is the absorbed 0008 section, and it is the one a reader is most often sent to by name.
*What state a permission entry may be in* is the absorbed 0018 section. *Whether the merge precondition
is enforced or merely instructed* is the absorbed 0007 section — **the one part of this document that is
`proposed`, not `accepted`**, which its own heading says.

- **Capability:** controls-and-enforcement
- **Status:** accepted
- **Date:** 2026-07-22
- **Deciders:** the owner
- **Driven by:** [ADR-0002](./0002-roster-and-dev-loop.md), and the Merge Request Definition of
  Done — record 0003 until 2026-08-19, now a section of
  [ADR-0006](./0006-verification-and-its-artifacts.md)

## Context & problem
The goal is to reduce the human's per-item approvals for delimited/roadmap work **without** giving up the
production go/no-go on the things that matter. A permission model has to say *who may merge what*, and
enforce it so it isn't just a promise an agent can break.

## Decision drivers
- Delimited, in-pattern work should complete without a human clicking merge each time.
- The irreversible/architectural boundary must stay with the human.
- Enforcement should be **mechanical**, not judgment — a capability, not a rule an agent can ignore.

## Considered options
1. **DoD classification + per-persona tool-scoping** (chosen) — the `critical-reviewer` approves **and
   merges** the **safe class** (docs, deps, test-only, in-pattern refactor, in-pattern implementation of an
   already-approved spec/ADR) once the DoD
   ([ADR-0006](./0006-verification-and-its-artifacts.md)'s *Merge Request Definition of
   Done* section) is green; the **boundary class** (architecture,
   contracts, `iac/`, positioning/public content, any ADR change, anything irreversible) always escalates
   to the human. Enforced mechanically: build specialists have **no merge tool**; the reviewer has **no
   edit tool**. The plugin defines the model; the project's committed settings consume it. *Trade-off:* the
   reviewer is not a human — a fresh context removes authorship bias, not model bias.
2. **All merges ask the human** — *Why not:* the status quo; no autonomy, the exact bottleneck this removes.
3. **Auto-merge anything the gate passes** — *Why not:* removes the human from the production go/no-go on
   architecture and infra; a same-model reviewer isn't a sufficient backstop for irreversible changes.

## Decision outcome
Chosen: **classified autonomy, mechanically enforced.** The safe class self-merges on a green DoD; the
boundary escalates. Tool-scoping makes the classification a capability boundary (a specialist *cannot*
merge; a reviewer *cannot* edit), reinforced by the existing global permission floor
(`apply`/`destroy`/`--force`/`rm -rf`/secrets/`--dangerously-skip-permissions` denied + the `PreToolUse`
guard hook, unchanged). Significance always pulls a merge from the subagent — the *significance beats
in-pattern* resolution of the DoD, in
[ADR-0006](./0006-verification-and-its-artifacts.md).

## Consequences
**Good**
- Delimited work completes end-to-end without per-item human clicks; the human's attention goes to the boundary.
- The boundary is a *capability*, not a promise — the agent literally lacks the tool to cross it.

**Bad / accepted costs**
- The reviewer is the same model family as the author: strong gate, not a substitute for human judgment on
  the boundary class (hence it always escalates). Consider a higher reviewer model/effort or a multi-vote
  refute pass for high-stakes MRs.
- The safe/boundary line needs care; a mis-classified boundary MR that self-merges is the failure mode to
  guard against (significance-test discipline).

## Amendment (2026-07-25) — the "only the reviewer merges" claim is now mechanically true (#77)

The *Decision outcome* above claimed the classification is "mechanically enforced … a specialist *cannot*
merge." Half of that held and half was a promise. **The reviewer-has-no-edit-tool half was real** (its
agent definition grants no Write/Edit — since [ADR-0006](./0006-verification-and-its-artifacts.md)'s
2026-08-03 amendment it holds a scratchpad-scoped `Write` for composing its verdict body, and still no
`Edit`, so the *cannot edit code* half this sentence rests on is unchanged). **The no-merge-tool half was not:** merging goes through
`gh pr merge`, and the consuming repo's committed `.claude/settings.json` allowlists `Bash(gh pr merge:*)`
for the shared permission surface that **every** context inherits — the main agent and every subagent
alike. So "only the reviewer merges" rested on the main agent *choosing* to route through the reviewer —
instruction-following by the same context that (per #76's diagnosis) had skipped the review on several PRs
in a row. The `critical-reviewer` flagged this while reviewing #76; #77 tracked it.

**Fix — an agent-scoped merge gate in `permission-guard.sh` (rule 7b).** The harness stamps a subagent's
tool calls with `agent_type` (`<plugin>:<subagent>`) and leaves it empty for the main agent; this field is
set by the harness, not the prompt, so the model cannot forge it. *(Precisely: cannot **claim** it —
it can still **choose** which persona to spawn. See the 2026-08-02 amendment below, which corrects this
phrasing for 7b as well as 5d; the guarantee is routing, not capability.)* The guard now **denies `gh pr merge`
unless `agent_type` ends in `:critical-reviewer`.** The main agent and every other subagent are denied;
the reviewer — the one context that *is* the merge gate — is allowed. "Did the reviewer run?" becomes a
precondition satisfiable only by actually routing the merge through the reviewer, matching how `wip-guard`
and the trunk-push block already work. Ships via the marketplace (`autoUpdate` on the consumer), no manual
step.

**Consequence — the merge flow changes, deliberately.** The main agent can no longer merge, even with the
human's go. A human-approved **boundary**-class merge is now performed by **re-invoking the
`critical-reviewer` with the human's ratification**, and it executes the merge — the human's go/no-go is
unchanged, only its *executor* moves to the gate. The safe class was already the reviewer's to merge; this
only closes the main agent's back door.

**Accepted residual (recorded, not hidden).** The gate matches the natural command `gh pr merge` (with the
`-R`/`--repo` convention). A raw `gh api … PUT …/merges` is **not** matched — pattern-listing every API
form is brittle and would drift. The API back door is an accepted, named gap: the everyday path is a
capability boundary now; a determined bypass via raw API is possible and is a smaller risk than a false
sense of total coverage. Revisit if it is ever observed in use.

This makes the *Decision outcome*'s "a specialist cannot merge" true rather than aspirational; the
"unchanged" note on the guard hook in that section is itself now superseded — the guard gained rule 7b.

## Amendment (2026-08-02) — where mechanism belongs, and where it costs more than it returns (#125)

This ADR has always said *what* the floor denies. It never said **which rules earn a mechanism at all**,
and that silence had a price: the loop's default became "if a rule matters, write a hook."

**The owner's rule, in their words:**

> **A shell script supporting the workflow of executing tasks is an antipattern.**

**The line as decided.** If the act **cannot be undone**, it needs a hook — `terraform destroy`, a
force-push, `rm -rf`, a secret write, a push to the trunk all escape git, and no later commit undoes
them. If it **can be fixed in the next commit**, a hook costs more than it returns. WIP discipline, who
may open an Issue, how a story is decomposed, what "finished" means are all reversible, and all are
rules about judgement.

**The measurement behind it, not an aesthetic preference.** The slice adding one narrow exception to the
floor took five commits, four of them corrective, and closed three separate bypasses — attached flag
values, a number that was not the declared one, a body written to a file. Every fix was correct and
every one left the next spelling open, because **intent is not in the command string**. That is the cost
of putting a judgement rule in a matcher, paid in review rounds and in a guard the loop learns to work
around rather than follow.

**Consequence.** Rules about the *shape of the work* move to skills the personas read
(`/workflow/code-review` is the first). Skills are weaker — nothing enforces them — and that is the
accepted trade: what they check is judgement rather than an act.

**First application, same day (#124).** The rule was applied to the slice that motivated it, and the
owner chose the skill over the mechanism. `permission-guard` rule 5d had spent four rounds trying to
verify from the command string that a `gh issue create` was a *decomposition* rather than invented
scope — a `Parent: #N` marker, read from the body file since that is how this repo writes bodies,
word-anchored so `apparent #122` did not count, first-match-not-last so a trailing number could not
authorise it, the repo read from the collapsed command so a `-R` inside `--body` could not redirect the
lookup, then a tracker lookup for `ready`. **Eighty lines and ten assertions, all deleted.**

What replaced it: the hook decides only what it can decide mechanically — `developer` may file, every
other subagent is denied, the main loop asks the owner — keyed on `agent_type`, which the harness
stamps and the model cannot write. The judgement rule (*only a task under a `ready` story, referencing
its parent, never extending it*) lives in `agents/developer.md`, and `quality-assurance` verifies it on
the task's MR.

**And the cost is real, so it is recorded here rather than only in the persona.** Three parts, because
the first draft of this paragraph booked only the first and `security` found the other two:

- **The parent is unverified.** Nothing mechanical stops a `developer` filing work nobody asked for. It
  surfaces as a finding at the gate instead of a denial at the keystroke — later, and more expensively.
- **The REPO is unverified too.** The deleted lookup bound the act to one repository — the parent had to
  carry `ready` in the repo the command targeted, so `-R someone-else/repo` failed. Nothing binds it
  now, and the token carries full `repo` scope. A `developer` can file into any repository it reaches.
- **And an issue can start execution.** In the consuming repo, `claude.yml` triggers on `issues:` when
  the body or title contains `@claude` — so a filed issue whose prose merely *mentions* the agent
  workflow starts a token-bearing run. Bounded (`contents: read`, and rules 7/7b apply inside it), and
  accident-shaped rather than attack-shaped, but it means "issues are inert" is not one of the reasons
  this trade is cheap.

**A correction to how this ADR states the `agent_type` property, applying to rule 7b as much as 5d.**
The claim has been *"the model cannot forge it — set by the harness, not the prompt"*. True, and it
reads as more than it says. `agent_type` is read from the payload root while the model contributes only
`.tool_input.command`, a sibling string, so **no spelling exempts anyone** — that half holds. But the
main loop **chooses which persona to spawn**, so it can obtain any `agent_type` by delegating. The
accurate property is:

> **The model cannot CLAIM a persona it is not running as; it can CHOOSE which persona to run.**

So these rules enforce **routing**, not capability. For 7b that was always the design — its deny message
says to route through the reviewer, and the value is that the reviewer's instructions actually run in a
fresh context. 5d now works the same way. What changed is only that the owner's ASK on issue creation is
**advisory rather than enforced**: one delegation away. Recorded because the stronger phrasing would
have been read as a guarantee it never made.

**An open question raised in review of this amendment, recorded rather than settled.** The rule is
stated on **reversibility**; the evidence cited is about **expressibility**. They correlate in the
examples chosen and come apart elsewhere in this repo: `inventory-counts` is a shell gate over an
entirely reversible property (a stale number is fixed by the next commit) and is one of the harness's
highest-yield mechanisms — by the rule as written it should not exist. The converse is the guard above:
a trunk push is irreversible, yet what the guard must decide is intent, which no matcher reads. The
variable that separates them may be **mechanical decidability** — counting files and comparing to a
literal is decidable; "is this story finished" is not. **Not adopted**: the owner has not ruled on it,
and the rule as written is defensible and causing no harm. Recorded so the next sweep finds the
question rather than re-deriving it.

## Amendment (2026-08-03) — the main agent stops being asked to file an issue

The amendment above records that the hook "decides only what it can decide mechanically — `developer`
may file, every other subagent is denied, **the main loop asks the owner**". The last clause is struck.
**`permission-guard` rule 5d no longer prompts on a main-agent `gh issue create`; it falls through,
exactly as `developer` does.** Nothing reaches the `ask` any more, so the call — and the `ask()` helper
whose only call site it was — is deleted rather than left as a branch that can never fire.

**The owner's decision, and the measurement behind it:** he hit that prompt twice in one evening,
filing two issues he had just asked for in that same conversation.

**The asymmetry that justifies it is a property of the CALLER, not of the command** — which is why no
matcher was needed to find it, and why this does not repeat the four-round mistake the 2026-08-02
amendment records:

- **A subagent's `gh issue create` is invisible.** It runs unattended, in a context the owner is not
  reading, and reaches them only if the agent chooses to report it. Nothing outside the hook observes
  it.
- **The main agent's is visible by construction.** The owner is *in* the conversation, watching the
  tool call happen, and can interrupt it. The act is already observed before the hook speaks.

So the prompt was charging a click to the one case that was already observable, while the genuinely
unobservable case was — and remains — denied outright. **This is the same inversion this rule already
corrected once**, one caller further out: the 2026-07-31 correction found a blanket denial that "taxed
ALIGNED work and the owner paid", and the ASK was a smaller version of the same tax on the same payer.

**The subagent deny is untouched.** Every non-`developer` subagent is still denied, in the same branch,
with the same message. That branch is where the measured failure actually happened, so it is the half
that had to survive.

**The cost, booked:** nothing mechanical now stops the **main agent** from opening work nobody asked
for. The failure this guarded against was **32 issues created against 13 closed in one session** across
both repos, roughly **13 of the 32 generated by reviewing something else**. What remains against it is
(a) the subagent deny, which covers exactly that review-generated case, and (b) a behavioural rule in
the main agent's instructions. That is the shape this ADR's 2026-08-02 amendment already chose —
*mechanism where the act is irreversible, skills where the rule is a judgement* — and opening an issue
is reversible by closing it.

**A second, smaller deletion that follows from the first.** The guard carried a hardening line
(`developer_may=` at the top, with a comment that it is never inherited from the environment) and the
suite asserted it. The flag existed only to carry one bit from 5d's `case` to 5d's `ask`; with no ask
it gated nothing, and a probe for a deleted variable cannot fail. **Both are deleted.** The property
they protected — ambient state must not decide the outcome — moves to the variable that still gates
something: `agent_type` is assigned unconditionally from the payload, and the suite now asserts that an
exported `agent_type` cannot turn a reviewer's DENY into an ALLOW. Mutation-confirmed in both
directions: rewriting that assignment to fall back to the environment reddens it.

**What is NOT weakened, stated because the fall-through is the risky part of this change.** Falling
through must remain falling through — no `exit 0`, no early ALLOW. An earlier version of 5d returned
from mid-script and rules 7, 7b and 8 stopped running, so `gh issue create … && git push origin main`
came out with no decision at all. The suite asserted that for `developer`; it now asserts the same
three compositions for the main agent, which is the caller that just joined that path. Mutation-
confirmed: making the main agent return early reddens exactly those three and nothing else.

## Amendment (2026-08-04) — the frontmatter is not the only place a capability is expressed

**The question this settles was the owner's, and it was asked the other way round.** After
[ADR-0002](./0002-roster-and-dev-loop.md)'s amendment #9 gave the merged copy lens `Bash`, the
open item was whether that **inherited grant should be visible from this record**, which decides
per-persona tool-scoping in principle and deliberately enumerates no concrete grant. The earlier ruling
was that it belonged in 0002, with the roster change that caused it. **That ruling stands for the
enumeration and is reversed for the mechanism**, and the reason is that something landed in between.

**The enumeration stays out of this record, and the reason is not tidiness.** `agents/*.md` frontmatter
is the *executable* declaration — the harness reads it, and a list here would be a second copy with no
reader, drifting silently. This ADR has already been burned once by a claim about tool-scoping it did
not own: its own *Decision outcome* asserted *"a specialist cannot merge"*, which the 2026-07-25
amendment had to correct because the fact lived elsewhere. **A record that restates a grant it does not
control acquires an obligation it cannot discharge.** Grants are read from the persona files.

**What does belong here is the surface, and it is new.** Until 2026-08-04, per-persona tool-scoping had
exactly one expression: the `tools:` frontmatter. **It now has two.** `permission-guard` gains an
`agent_type`-keyed deny on the writing `gh` subcommands for `*:product-lead` — a persona that keeps
`Bash` in its frontmatter and cannot publish with it. That is this ADR's subject matter, not ADR-0002's:

> **A persona's effective capability is the frontmatter grant MINUS the `agent_type`-keyed denials in the
> floor.** Reading either surface alone overstates it in one direction or understates it in the other.

> **Appended 2026-08-04 — the formula computes CAPABILITY, and `security` is the persona where that stops
> being the same question as *what is it allowed to do*.**
>
> The ruling asked for was whether this section owes `agents/security.md` a line, given that the same
> batch gave it `Write`, a mandate to post its verdict publicly, and a `.brand/` prohibition it had never
> had. **It does — but not the line it looks like it owes.** An enumeration of `security`'s grant belongs
> in the persona file for exactly the reason stated two paragraphs above, and repeating it here would
> re-acquire the obligation this record was burned by twice. What is owed is a **bound on the formula
> itself**, which is this record's and nobody else's:
>
> > The formula reads *frontmatter grant MINUS the `agent_type`-keyed denials*. Both terms are
> > **capabilities**. A persona's real boundary may be in **neither** — and `security`'s is: it reads
> > `.brand/` and posts to a public repo on every MR, and the only thing between those two facts is a
> > paragraph in its own instructions.
>
> So the formula's output is **what a persona CAN do, never what it MAY do**, and reading it as the latter
> understates the exposure by exactly the set of prose-only boundaries. `security` is the first persona
> where that gap is load-bearing and deliberately left open: unlike `product-lead`, which rule 5e closes
> off from publishing entirely, `security`'s verdict **must** reach the PR, so no capability boundary is
> available without destroying the artifact ADR-0006 requires. **Where `product-lead` has a capability
> boundary, `security` has a paragraph** — and a paragraph is only as strong as the attention it gets.
> That asymmetry is the accepted cost, and it is recorded here rather than only in the persona because
> this is the record whose stated property would otherwise be read as covering it.
>
> The count in this section is unaffected: the `agent_type`-keyed denials remain **three** (5d, 5e, 7b).
> `security` adds no fourth surface — it demonstrates that two surfaces do not span the space.

This is what makes the 2026-08-04 mechanism worth recording where 0002's grant was not. ADR-0002 booked
the loosening as *"the rule is now an instruction rather than a capability"* — the exact downgrade this
record's own driver forbids (*"a capability, not a rule an agent can ignore"*). **The second surface
restores the property by a route this ADR never contemplated**, which is precisely why the ADR that
owns the property has to say it exists.

### The correction to *routing, not capability* — smaller than it first looks

The amendment above states, in a block quote, that these rules **enforce routing, not capability**. It
is tempting to call that falsified by a deny that routes the act toward nobody. **It is not, and the
overstatement is worth refusing explicitly** — ADR-0006 records four consecutive rounds of a right
conclusion defended by a reason its facts did not support, and this is the same opportunity.

The formal property is untouched: the main loop can still obtain the act by spawning a different
persona, or by reading `.brand/` itself and posting with **no `agent_type` at all**. Nothing here is a
wall. What differs is the **shape**, and it needs one sentence rather than a new principle:

- Rules 5d and 7b route an act **toward** a designated persona — the value is that *that* persona's
  instructions run in a fresh context.
- **Rule 5e** — the `*:product-lead` deny, as shipped — routes an act **away from** one, with no
  destination. Its value is an **information-flow separation**: the context instructed to read the
  private, gitignored positioning layer is not a context that can publish. It works because subagent
  contexts are isolated, and it buys nothing against a main loop that reads the private layer itself.

  > **Appended 2026-08-04 — the act still has no destination; the CONTENT now does, and the difference
  > is the whole of it.** As written above, 5e left the denied persona's *finding* with no assured route
  > to the PR: the deny message said `quality-assurance` would carry it, and at the time nothing had
  > decided that it would. The owner has now decided it —
  > [ADR-0006](./0006-verification-and-its-artifacts.md)'s **third 2026-08-04
  > amendment**: the merging gate **must** quote the copy verdict verbatim under its own marker, and
  > criterion 10 is unsatisfied until the text is on the PR. **So the consequence this rule created is
  > no longer an open gap.**
  >
  > What is *not* corrected is the sentence above. A comment authored by `product-lead` still has no
  > destination — nobody may post as the lens, and no carve-out was made. The relay carries the
  > **findings**, attributed to the carrier, which is a strictly weaker artifact than a first-party one
  > and is booked as such in ADR-0006. The information-flow separation this rule buys is therefore
  > **exactly as wide as it was**: the persona that reads `.brand/` still cannot publish, and what
  > reaches the public PR now passes through a persona that does not read it.
  >
  > **The transferable rule, because this cost half a day.** A persona-keyed publication deny does not
  > only remove a capability — it **orphans whatever that persona's output was feeding**. Ship the deny
  > and name the receiver in the same MR, or state that nothing waits on the output. ADR-0006 books
  > that obligation on the deny rather than on the relay for this reason.

**The count in this record was two and is now three.** This ADR's earlier amendments describe the
`agent_type`-keyed denials as rules **5d** and **7b**; **5e** joins them, and it is the first of the
three whose purpose is neither routing an act to its owner (7b) nor withholding one from every
subagent but its owner (5d). Corrected here rather than left for a sweep to trip over, because
`security` found 5e *by counting the existing ones* — a stale count is a stale search.

So the guarantee is narrower than *"the positioning layer cannot leak"* and is exactly *"the persona
told to read it cannot post it."* **That is the capability floor ADR-0002's first amendment wanted and
its ninth amendment spent — re-obtained on a different surface, at a smaller price.** Stated at that
width so no later record can quote it as the larger claim.

### A consequence in the consuming repo, recorded because nothing will catch it

The public `/architecture` page on `tadeumendonca-io` describes this harness, and this rule reaches it.
**That page is not this repo's to edit; the obligation is booked here so the slice is written down
rather than remembered.** Three things about it are easy to get wrong, so they are stated separately.

**1 · What is actually falsified is less than it was flagged as.** The warning raised when the coupling
was first noticed was that the page's sentence *"nothing refuses the merge command on its behalf"*
**becomes false in both locales**. Checked against the page: **that clause stays true.** No new
mechanism blocks a merge for `product-lead`; the new rule constrains what `product-lead` may *run*, not
what happens when it objects. What breaks is the **contrast the passage is built on** — it presents
`quality-assurance` as the one persona named in the hook and `product-lead` as *"the mirror case"*,
convention-only. After this rule, `permission-guard` names `product-lead` too, in the restricting
direction. **The reader's takeaway is falsified; the sentence's literal claim is not.** A rewrite that
only edits that clause will fix the wrong half.

**2 · It is in four places, not two.** The passage appears in each locale **twice** — once in the prose,
and once inside the Mermaid `accDescr` block, which restates the same contrast at length:

- `apps/fed/src/content/architecture.en.md` — the `accDescr` and the paragraph below the diagram
- `apps/fed/src/content/architecture.pt.md` — the same two

**The `accDescr` is the copy a sighted reviewer does not read**, and it is the more detailed of the two.
It is where a partial fix will survive review.

**3 · The existing check does not fire, and this is the structural part.** ADR-0043's inventory guard
compares `apps/fed/src/content/generated/harness.json` against this repo's live tree **by identity** —
a component missing, a row with nothing behind it, a row that changed shape. Read the manifest: every
persona row is `{"kind":"persona","id":…,"file":"agents/<name>.md","enforcement":"advises"}`. **Adding a
rule to `permission-guard.sh` adds no component, retires none, renames none, and changes no counted
field.** The io build stays green while the page misdescribes the harness — which is the exact failure
mode that page names in its own text (*"a hook that keeps its name and changes what it does publishes a
stale description under a green build"*), now instantiated rather than hypothetical.

**The open question that slice inherits, not settled here:** whether `product-lead`'s manifest row
should still read `enforcement: "advises"`. It is the io repo's schema and the io repo's call. Noted so
the slice starts from it.

## Amendment (2026-08-04, second) — what the deny list actually stops, and what it does not

~~**Decision: the owner, 2026-08-04.** `Bash(bash:*)` and `Bash(sh:*)` **stay** in the committed floor.
The cost recorded below is **accepted in his name**, having been put to him with the counter-argument
intact. *This record does not re-propose narrowing the grant, and a later reader should not read it as
building that case.*~~

> ### Superseded 2026-08-04, later the same day — the owner reversed this decision, and the reversal is the reason it is worth reading
>
> **Decision: the owner, 2026-08-04 (`14d7b43`, `786437c`).** `Bash(bash:*)`, `Bash(sh:*)` and
> `Bash(xargs:*)` came **out** of the committed floor, and `Bash(perl:*)` / `Bash(ruby:*)` followed. At
> `cb9a2f3` none of the five is in `allow`; a payload wrapped **in one of those five** reaches the human
> as an **ASK**. Checkable: `jq -r '.permissions.allow[]' .claude/settings.json`.
>
> **The five words in bold are a correction, made 2026-08-04 by `security` while reviewing this batch,
> and the scope they add is the whole point of the paragraph below.** The sentence read *"a wrapped
> payload reaches the human as an ASK"*, without qualification — which the very next paragraph
> contradicts by reaffirming that `node` and `python3` are still granted and *"reach the same acts"*.
> Measured at `f797cc6`: `node -e …` and `python3 -c …` draw no decision from any layer and are
> allow-listed, so a payload wrapped in **those** reaches ALLOW, not ASK. Unqualified, the sentence
> claimed the class was closed; what actually closed is its **default spelling**, which is exactly the
> distinction the rest of this amendment is at pains to draw. Same correction as ADR-0004's third
> 2026-08-04 amendment, in the other record, found the same way.
>
> **What changed between the two decisions was evidence, not preference — and this is the transferable
> half.** The reasoning struck above is *"narrowing does not close the hole, because `node`, `python3`,
> `perl` and `ruby` are already granted and reach the same acts"*. That premise was correct and is still
> correct. What it did not weigh is that the two grants are **not equally reachable by the matcher this
> loop actually runs**: the `bash -c` form is what a wrapped payload is *spelled* as by default, and by
> the time this was reversed the guard's unwrap regex had been patched three times for it —
> `$'…'` delimiters, escape decoding, option runs before `-c` — with `$'r'"m -rf /x"` (**plain string
> concatenation, no escapes at all**) still reaching ALLOW. The choice was never *narrow the grant* versus
> *accept non-containment*; it was **patch a matcher a fourth time** versus **remove the class from the
> floor**, and the first buys one spelling while the second buys the class.
>
> **`xargs` went with them for a reason that is a property of the floor rather than of `xargs`:** allow
> entries are prefixes, so `xargs -I{} bash -c '…'` matches on `xargs` and the `bash` question is never
> reached. An allow entry is only as narrow as the *first word* of every command that can carry a payload.
>
> **The accepted cost, stated so this is a trade rather than a tightening:** an agent-written scratchpad
> script is now an ASK. That is deliberate — a script under `git-reps` is committed and reviewable, while
> a scratchpad script was written minutes earlier by the thing about to run it, which is precisely the
> shape a wrapped payload takes. `bash` is re-opened by explicit path for the five committed test scripts.
>
> **The instruction in the struck paragraph is withdrawn with it.** *"This record does not re-propose
> narrowing the grant, and a later reader should not read it as building that case"* was correct guidance
> for the decision it accompanied and would now steer a reader away from the decision the owner actually
> holds. **Non-containment is still accepted** (`node -e`, `python3 -c` remain granted and
> `permission-guard.sh` deliberately does not chase them) — so what was narrowed is which spellings are
> free, not what the perimeter contains. The architecture is this document's *Which layer carries a
> control (absorbed 2026-08-20, record 0008)* section; the measurement is the `jq -r
> '.permissions.allow[]' .claude/settings.json` check in the *Superseded 2026-08-04, later the same day*
> block at the head of this amendment.

**What raised it.** The batch that committed this floor ratified the principle *a control expressed as
absence is not a control* — and in the same diff allowlisted `Bash(bash:*)` / `Bash(sh:*)` alongside the
already-granted `node`, `python3`, `perl`, `ruby`. Since the settings matcher is a **prefix** match, the
prefix of `bash -c 'rm -rf /x'` is `bash`, so `Bash(rm -rf:*)` never sees it. The objection was that a
diff arguing *one wildcard erased a control* was adding a larger wildcard.

**Why it was not narrowed, and this is the reasoning rather than a summary of it.** Narrowing does not
close the hole. `node`, `python3`, `perl` and `ruby` were already granted and each executes arbitrary
code, so denying `bash -c` shuts the wide door and leaves the narrow one — the same conclusion that
retired an earlier `node -e` deny as theatre. **A control that is trivially reachable by a synonym is
not a smaller control; it is a claim.** What remains to fix is therefore not the grant but **the
property this record was implying and does not have.**

### The three layers, and what each actually stops

1. **The settings `deny` list — the obvious, direct form.** `rm -rf …`, `gh api …`, `git push origin
   main`. This is the form an agent reaches for by default and the form a human types by accident, and
   catching it there is worth having. It is a prefix match and nothing more.
2. **The `permission-guard` hook — wrapped and composed forms.** It reads the raw command string
   semantically, so it sees the `rm -rf` inside `bash -c '…'`, and rules 7 and 8 exist precisely
   because trunk-push spellings and command composition *provably cannot* be expressed by a prefix
   matcher.
3. **Neither is a sandbox, and the perimeter model does not claim one.** Inside the perimeter,
   arbitrary code execution is granted **deliberately** — ~~`node`, `python3`, `perl`, `ruby`, `bash`,
   `sh`~~ **`node` and `python3` as of `cb9a2f3`; `perl`, `ruby`, `bash` and `sh` came out of `allow`
   the same day and are now an ASK — see the superseded decision above. The bullet's claim is
   unaffected: `node -e` and `python3 -c` reach every act the others did, which is exactly why removing
   the others is not containment.** The controls exist for the **irreversible/public boundary** and for
   **process integrity**, not
   for containment. That is the design; what follows is the price.

### The specific consequence, named rather than implied

**`bash -c '…'` renders every prefix-matched `deny` in the committed floor unreachable.** Concretely
that includes the four `rm` spellings this same batch adds, `gh api`, and the trunk-push denies. ~~In
wrapped form it is **the hook, not the floor**, that stops them.~~

~~**Verified empirically, not reasoned:** piping `bash -c 'rm -rf /tmp/x'` at the guard returns
`Blocked: 'rm -rf' is irreversible`. The hook matches; the settings `deny` does not, because the prefix
is `bash`.~~

> ### Superseded 2026-08-04 — the struck sentence was FALSE WHEN WRITTEN, and the owner ratified against it
>
> **What it asserted:** that for wrapped commands the hook is the layer that stops them — stated of the
> `rm` spellings, `gh api` and *the trunk-push denies* alike, and offered as *verified empirically*.
>
> **What was true.** Only the `rm` case. `permission-guard.sh` matches most rules on `$bare`, which
> collapses quoted spans — correct for its own purpose and exactly wrong for a `-c` payload, since that
> payload is a command that happens to be quoted rather than a string that happens to look like one.
> Rule 4 (`rm`) matches `$cmd`, the raw string, and was **the only rule in the file that saw a wrapped
> form**. `security` measured the rest against the tree as this amendment was ratified:
> `bash -c 'git push origin main'`, `bash -c 'gh pr merge …'`, `bash -c 'gh issue create …'`,
> `bash -c 'gh pr comment …'` and a wrapped `gh api` write **all reached ALLOW with no decision from any
> layer** — the merge gate among them. So the sentence was not merely imprecise: for the trunk-push
> denies it names, *neither* layer stopped them.
>
> **What made it true.** Commit `745d949` unwraps `-c` payloads **once, above every rule**, appending the
> payload to `cmd` so the outer command still trips the composition check. Re-measured after the fix:
> `bash -c 'gh pr merge 145 --merge'` from the main agent returns rule 7b's deny; against the pre-fix
> tree (`4842ecd`) the identical payload returns nothing at all. Both probes were run to write this
> paragraph rather than reasoned from the diff.
>
> **The method error, which is the transferable half and the reason this is superseded in place rather
> than quietly amended.** The empirical check behind *"verified empirically, not reasoned"* sampled
> **one** rule and generalised to the file. It sampled the single rule that does not use the shared
> matching surface — so the sample was not merely small, it was the one member of the population that
> could not represent it. **An empirical claim about a rule SET is checked per rule, or it is stated as
> covering the rules it tested.** The claim's confident phrasing is what carried it past two
> gatekeepers and into a record the owner ratified.
>
> The layering conclusion this passage was reaching for is now decided rather than observed — see this
> document's *Which layer carries a control (absorbed 2026-08-20, record 0008)* section, which makes the
> hook the authoritative layer by decision and books the fail-open cost the section below describes.

### The load-bearing sentence: the layering is inverted from what the hook claims

`permission-guard.sh`'s own header says it twice — *"Each repo's .claude/settings.json `deny` remains
the hard backstop"*, and, on its fail-open contract, *"because settings.json `deny` is the authoritative
backstop and we never want to wedge the agent on a malformed payload."*

> **For wrapped forms that is false, and it is false in the direction that matters.** The deny list is
> the **weaker** layer there and the hook is the **only** one — while the hook **fails open** on a parse
> error, justified by a backstop that, for exactly those forms, is not behind it.

So the two layers are not defence in depth for the wrapped case: they are one layer that fails open,
and a second that never sees the command. ~~**Recorded as a known property, not scheduled as a fix** —
correcting the hook's header comment is a `hooks/` change and not this record's to make.~~

> **Superseded 2026-08-04 — it is no longer a property, it is a decision.** This passage observed the
> inversion for one class of command and declined to act on it. Within the same day it recurred twice
> more, for reasons unconnected to each other and to this one (`gh api`'s read/write split; the
> `Bash(gh -R:*)` and `Bash(git -C:*)` allow entries shadowing fourteen deny entries **— the floor as it
> stood when the decision was taken; `Bash(gh -R:*)` was withdrawn at `cb9a2f3` and only the `git -C`
> half of that shadowing survives, which changes the instance count and none of the reasoning**), at
> which point
> the owner decided the architecture rather than letting a third instance be recorded as a fourth
> property. **The hook is the authoritative layer; the settings `deny` list is the floor for the direct
> form; the authoritative layer fails open and that cost is accepted in the owner's name.** The record
> is this document's *Which layer carries a control (absorbed 2026-08-20, record 0008)* section, which
> also carries the two rejected options and the standing rule for the next control. This section stands
> as the observation that led to it.

### Why decision 1's principle survives this

Stated because the amendment above could be misread as softening it. *A control expressed as absence is
not a control* was about **`gh api` being unlisted** — never denied, only absent — and therefore erased
by a single `Bash(gh *)` wildcard in an unreviewed 82-entry local overlay. That remains exactly true,
and it is untouched here: **an explicit `deny` still beats every `allow` across all layers for the
direct form**, which is the property the overlay defeated and the property the committed floor restores.

What this amendment adds is only that **a `deny` is not a sandbox** — which the principle never claimed,
and which a reader could easily infer from a floor that lists `rm -rf` four ways.

### One sentence the floor was missing

~~The same diff denies `Edit(.claude/**)` and `Write(.claude/**)` while itself modifying
`.claude/settings.json`.~~ **Struck 2026-08-23 (#319) — the sentence overstated the control in two
different ways at once, and the WEAKER half is the one worth naming.** Measured at head:
`.claude/settings.json` carries `"ask": ["Edit(.claude/**)"]` and **no `Write` entry at all**. So the
control is (a) an **ask**, not a deny — one notch weaker, a prompt rather than a refusal — and (b)
**half-present**: `Write(.claude/**)` was never there, so a file created rather than edited under
`.claude/` reaches no check on this layer. A record asserting a `deny` where an `ask` lives is exactly
the shape this document's own *Which layer carries a control* section warns about: it stops the next
reader from looking.

**The decision the sentence was carrying is unchanged and is restated in its own terms:** the permission
surface is owner-edited, and an agent proposes changes to it rather than applying them. Without that,
the first agent that needs an allowlist entry reads the prompt as a bug and works around it, which is
the failure mode this record exists to prevent. **What is corrected is only the claim about the
mechanism**, and widening `ask` to `deny`, or adding the missing `Write` entry, is a floor change the
owner makes — not something this amendment performs on its own authority.

## Amendment (2026-08-13) — two artifacts stated opposite rules about the same act, and neither was wrong on its own terms (#62)

**Recorded here, on `harness-engineering`'s consolidation ([#224](https://github.com/tedeuxx/tadeumendonca-skills/issues/224)/[#237](https://github.com/tedeuxx/tadeumendonca-skills/pull/237)), because the incident it documents is this ADR's own decision drifting out of sync with a second copy of it** — the retired `skills/principles/dev-loop/SKILL.md` (folded into `harness-engineering` by that PR) carried its own prose description of the merge step, independent of this ADR's text, and the two fell out of agreement.

**What happened.** `skills/principles/dev-loop/SKILL.md` stated, for the `trunk-single-env` model: *"Auto-merging to `main` is never in-pattern here."* That sentence predates this ADR's **Decision outcome** above (*"the safe class self-merges on a green DoD; the boundary escalates"*, 2026-07-22) and was never updated to match it. An agent reading only the dev-loop skill and an agent reading only this ADR reached **opposite conclusions** about the same act — whether `quality-assurance` (then `critical-reviewer`) may merge the safe class itself — because the two records of the same decision disagreed, and nothing cross-checked them.

**Why this is a decision-currency defect, not a merge-authority defect.** The classification this ADR decided (safe self-merges, boundary escalates, Amendment 2026-07-25 making "only the reviewer merges" mechanically true) was never wrong or ambiguous *in this ADR*. The failure was that a second prose restatement of the same rule, in a different file, was allowed to go stale independently — the platform equivalent of two callers holding different cached copies of the same config with no invalidation between them.

**Resolution.** The stale sentence was struck in `dev-loop`'s own text (*"That was written before ADR-0004's classified autonomy and contradicted `quality-assurance`'s own definition… What the merge asks for is a judgement, and who supplies it depends on the class"*) and the corrected framing — safe class merges itself once both lenses are green, boundary class never does, unclear-is-boundary — is now carried in exactly one place: `skills/agents-configuration/SKILL.md`'s *"The merge is the go/no-go"* section, which cites this ADR directly rather than re-deriving the rule in its own words. Consolidating three principle skills into one (`harness-engineering`) removes the specific duplication that let this drift happen; it does not remove the general risk of a future skill restating an ADR's decision in fresh prose that can then drift.

**Accepted cost, named rather than solved:** nothing mechanical asserts that a skill's prose description of a decision still matches the ADR it describes. This amendment records the one incident that surfaced; it is not a standing check.

## Which layer carries a control (absorbed 2026-08-20, record 0008)

**Disposition 4 of [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md):
record 0008's decision is in force and is moving into the document that governs its capability.**
Decided by the owner on 2026-08-04, driven by the permission audit of that day and the ~150-probe sweep
that closed it. **It supersedes the layering claim in this record's own second 2026-08-04 amendment**
(*"the settings `deny` list is the hard backstop"*, inherited from `permission-guard.sh`'s header) — a
supersession that is now internal to one document, which is the clearest single argument for the fold.
Its History row is in [the index](./README.md).

**This is the section a reader is sent to by name.** `agents/agents-lead.md` cites this decision as
that persona's standing question — *which layer carries a control, and can that layer hold it?* — and it
is a general design question asked about gates, labels and hooks that hold no permission at all, not
only about permissions. The capability's name is `controls-and-enforcement` rather than `permissions`
for exactly that reason.

### The problem: an architecture that changed three times in one day, and nobody was deciding it

The permission floor had always been described as **defence in depth with the static layer underneath**.
`permission-guard.sh` said it twice in its own header, and this record's body repeated it. Every rule
added to the hook was added on that understanding: the hook is the *smart* layer, the deny list is the
*dumb but unfailing* one, and the hook may fail open because something is behind it.

On 2026-08-04 that stopped being true for a substantial and growing set of controls, three separate
times, **none of the three being a decision about the floor's architecture**:

1. **Wrapped.** The settings matcher reads a command *prefix*. The prefix of `bash -c 'rm -rf /x'` is
   `bash`. So **every** prefix-matched `deny` entry is unreachable in wrapped form for as long as any
   wrapper is allow-listed — a property of the matcher rather than of the entry, which is why the
   routing reason outlives the entry that first demonstrated it. **It has a live instance today, not
   only a historical one:** the shell wrappers came back out of `allow`, but `node -e` and `python3 -c`
   remain allow-listed by design and draw no decision from any layer.
2. **`gh api`'s read/write split.** `-f`/`-F` switch the request to POST with no `--method` present, so
   **no prefix separates a read from a write.** A blanket `Bash(gh api:*)` deny removed reads the loop
   itself performs, and the control moved to the hook (rule 5f).
3. **Allow entries shadowing deny entries.** `Bash(git -C:*)` is in `allow`, and a prefix deny on
   `git clean -f` cannot see `git -C <path> clean -f`. **This one is live in the floor as it stands** —
   `-C` *is* how the multi-repo loop addresses the other repository, so no convention change removes it,
   unlike the `gh -R` half, which was removed by moving the flag after the subcommand.

> **The pattern is what demanded a decision, not the instances.** Each migration was locally correct,
> each was made by someone solving a different problem, and the header sentence describing the
> architecture was in none of the three diffs. **A property that can be inverted as a side effect is not
> a property; it is an accident that has not been contradicted yet.**

### The decision, as it currently binds

> **Direct form → the settings `deny` list. Wrapped, composed, semantic, or shadowed by an `allow` entry
> → `permission-guard.sh`.** The hook is the **authoritative** layer. The deny list is a floor for the
> spelling a caller produces by default, **not a backstop behind the hook**.

**The four routing reasons, stated identically here and in `permission-guard.sh`'s header** so the two
cannot drift into two different rules:

1. **Wrapped** — `bash -c '<payload>'`. The prefix is the shell; the payload is invisible to the matcher.
2. **Composed** — `&&`, `||`, `;`, `$( )`, backticks, a `VAR=x` prefix. The matcher reads one prefix and
   cannot decompose the rest.
3. **Semantic** — the act is not in the string. `git push` lands on the trunk or not depending on the
   checked-out branch; `gh api` reads or writes depending on whether `-f` is present.
4. **Shadowed by an `allow`.** The general form is the one worth quoting, because it is why this class is
   systematically underestimated:

   > **An `allow` entry does not weaken one `deny`; it weakens every `deny` for the same tool, at once,
   > and silently.**

And the property that goes with it, stated because it is the half a reader will otherwise assume away:

> **The authoritative layer fails open.** On a parse error, a missing `jq`, or a malformed payload,
> `permission-guard.sh` emits no decision — and for every control it is the only layer of, that is an
> open door rather than a degraded one. **Accepted, in the owner's name.**

### The rejected options that are still live

1. **Make the hook fail closed**, so the authoritative layer's failure mode matches its status. *Why
   not, and the reason is a failure that has already happened rather than a prediction:* with `jq` off
   `PATH`, `permission-guard.sh` returns nothing for a `git push origin main` payload, because
   extraction fails before any rule runs and `deny()` itself needs `jq` to emit. **Under fail-closed
   that same broken `jq` denies every `Bash` call in the session — including the ones that would
   diagnose and repair it.** The agent is wedged and the only route out goes through the owner, at the
   moment he is least able to see why. A control that converts a missing dependency into an outage of
   the whole loop costs more than the window it closes.
2. **Pattern-list every spelling back into the floor.** *Why not — measured, not predicted:* the
   ~150-probe sweep of 2026-08-04 found **nine** spellings nobody had listed, across rules that had
   already been swept once for exactly this (`gh --repo=o/r pr merge`, `gh -Ro/r pr merge`, the same two
   against `secret set`, `gh api -ftitle=x`, `git -C <path> clean -fd`, `git -C <path> push --tags`,
   `gh -R o/r repo delete`, `gh -R o/r workflow run`). **A floor that depends on how the caller
   punctuated is not a floor.** Enumeration does not converge; each fix leaves the next spelling open,
   and the list's *appearance* of coverage is worse than a shorter list that claims less.

### Why this is not a weakening of the principle it looks like it weakens

Stated explicitly, because the batch that produced it also ratified *a control expressed as absence is
not a control* — which this record's absorbed 0018 section generalises. **That principle is untouched.**
It was about `gh api` being **unlisted** — never denied, merely absent — and therefore erased by a single
`Bash(gh *)` wildcard in an unreviewed 82-entry local overlay. **An explicit `deny` still beats every
`allow` for the direct form.** Nothing here removes or narrows a `deny`. What changed is **which layer
carries the semantic cases**, and it changed because those cases are **inexpressible in the other
layer** — there was no version of the floor that held them.

### Consequences still being paid

**Good** — the layering is **decided**, so the next migration is a choice against a written rule rather
than a side effect nobody records; the fail-open cost is visible where the controls live; and reviewers
get a test they can apply to a diff without judgement: *can a prefix express this?* If no, the floor is
the wrong layer and adding it there is theatre.

**Bad / accepted:**

- **The authoritative layer fails open, and the set of controls it alone carries only grows** — see the
  third-layer amendment below, which supplies the one mechanism that shrinks it.
- **The floor now reads as broader than it is.** A reader of `.claude/settings.json` sees `rm -rf` in
  four spellings and infers containment. It contains the direct form only, and this section is the only
  place that says so.
- **Neither layer is a sandbox, and the perimeter model does not claim one.** Arbitrary code execution is
  granted **deliberately** inside the perimeter — `node -e` and `python3 -c` are allow-listed and
  `permission-guard.sh`'s header books them, with `perl -e`, `ruby -e` and `eval`, as **NOT COVERED,
  DELIBERATELY**. These controls exist for the irreversible/public boundary and for process integrity,
  never for containment.

#### The accepted cost that makes this architecture degrade quietly — *the retained floor entry*

Named separately because it is the one a reader will remove **correctly by every other measure**, and
because it is what bounds the fail-open cost above.

**When a control migrates to the hook, its floor entry stays.** `bash -c 'rm -rf /x'` needs the hook, but
a plain `rm -rf /x` is still stopped by a layer that cannot fail open.

> **The floor entry is not a duplicate of the hook rule. It is the fail-closed half of a two-layer
> control.** Deleting it converts a control that survives a broken `jq` into one that does not.

**The bound covers less than the architecture, and this is the sharper half.** Retention bounds the cost
for controls that **migrated**. It does nothing for controls **born in the hook**, which never had a
direct form to fall back to: rule 7b (the merge gate), rule 8 (composition), rule 5f (`gh api` writes),
rules 5c/5d/5e (who may open work, who may publish), and rule 7's bare-`git push`-on-`main` branch. For
those a broken `jq` is a **total** hole. The concrete instance, since it is the one that matters most:
`Bash(gh pr merge:*)` is in `allow` and the merge gate exists **only** in the hook, so with `jq` missing
the main agent can merge a PR with no decision from any layer — verified by probe with `jq` stubbed.
**So the retained floor entry bounds the migrated set only, and the set it does not bound contains the
gate.**

**And it is true only by convention.** Nothing verifies that a migrated control kept its floor entry, and
nothing would notice its removal. The removal reads *correct*: a deny list with a semantic layer behind
it is exactly where an entry looks redundant. **Considered and rejected:** a test asserting *"every hook
rule has a corresponding floor entry"* is writable, but it requires a mapping between two files nobody
maintains — hook rules are numbered by lineage and matched by regex, floor entries are literal prefixes,
and the correspondence is one-to-many in both directions — and it would go **red on the correct act**,
since adding a hook rule for something the floor never denied is most of them. **A check that is wrong
more often than right trains the loop to silence it.** So the cost stands unclosed, with the reason
stated; what holds it is this paragraph, the matching header sentence, and a reviewer who reads either
before deleting a deny entry.

### The standing consequence — the sentence a future reader needs

> **Any control a prefix cannot express belongs in the hook by construction.** And **every such
> migration removes one more thing the fail-open cost is bounded by** — so the price of the hook's
> fail-open contract is not fixed; it is paid again, slightly higher, each time a rule moves.

Two obligations follow, cheap only if done at the time:

- **A migration into the hook is an amendment to this section**, not a comment in the rule. Three
  undocumented migrations in one day is what made the decision necessary.
- **A rule that a prefix CAN express stays in the floor.** Moving it for tidiness spends the fail-open
  budget for nothing. `claude mcp` is the worked example: no flag convention sits between the words and
  no `allow` entry shadows it, so the prefix matcher sees every spelling and the hook would add exactly
  zero.

### Two rules this decision earned, both about what a record may claim

**1 · *Record the derivation, not the count.*** Reached independently three times in one day by three
parties solving three different problems.

> **A derived count in prose is a claim with no owner. The derivation is the thing that stays true.**

So a number is given only to convey magnitude, never as the thing to check against, and it ships with
the command that produced it. This section's own counts are written that way: it names the `allow`
entries that cause the shadowing and the `deny` entries they shadow, so a reader who finds a different
number has the **method** to see why rather than a contradiction to report.
`jq -r '.permissions.allow[]' .claude/settings.json`, read against the `deny` list, is that method.

**2 · *Closed* is not a word a pattern-over-a-grammar control may use about itself.** Earned on three
occurrences inside one batch, each the same move — measure some spellings, report the class. The third
was the sharpest: the unwrap step's header said the wrapped class was *"closed by the unwrap step
below"*, and re-measuring by piping payloads at the committed script found `bash -c $'…'` (ANSI-C
quoting the quote-strip does not know) and `bash --norc -c '…'` (an option run before `-c`, which the
unwrap regex did not admit) both reaching **ALLOW** — including for `git push origin main` and
`gh pr merge`.

> **A control implemented as a pattern over a grammar may be recorded as *"these spellings, measured
> this way, on this date"* — never as *"closed"*.** The class it must cover is every string the grammar
> admits; the evidence available is always a finite sample. *Closed* asserts the first and is only ever
> backed by the second, so it is **not a claim the author is in a position to make**, however careful
> the sweep.

**It binds this section too.** The rejected option above refuses enumeration because *"enumeration does
not converge"* — which is a fact about the technique, not about the layer that lost the argument, and it
applies equally to the hook.

**What it costs, stated rather than absorbed, because this is a trade:** every such record gets longer
and less quotable, and a record nobody quotes is a record nobody applies — this library has already lost
a header sentence to exactly that. The reader must check a measurement instead of reading a verdict. And
**it removes the stopping rule**: *closed* is what tells a sweep when to stop probing, and *"these
spellings"* never does, so the stopping point moves back to judgement, which is the thing the formalism
was bought to replace. **No remedy is proposed for that, and it is the strongest argument against the
rule.** What holds it is that the alternative was measured wrong three times in one day, and a stopping
rule that stops early is worse than none, because it stops **and** reports coverage.

**The narrow scope, so this is not a ban on plain sentences.** It applies to controls that match a
**pattern against a caller-controlled string** — the settings prefix matcher and the hook's regexes. A
control over a **closed, enumerable** domain may still be recorded as closed: `agent_type` keys take
finitely many values a rule can list, so *"every non-`developer` persona is denied"* is a provable claim
about a set. **The test is whether the adversary picks from a set the author wrote or from a grammar** —
which is also why the absorbed 0018 section above may state its three states as closed.

### The rule that a floor entry's record is spread across files no removal commit opens

Earned when three commits removed seven `allow` entries and left the narrative asserting them, in the
present tense, framed as measurement. The cause was established by toggling rather than inferred: each
removal commit was scoped to the file it removed from plus the narrative adjacent to it, and **no commit
re-grepped the entry's name across the tree**. The drift sat exactly, and only, at the sites those
commits did not open.

> **Removing or adding a floor entry is a change to at least five artifacts, and the name of the entry is
> the only thing that finds them all.** The entry lives in `.claude/settings.json`; its justification
> lives in this document, in `permission-guard.sh`'s header, in the ADR index, and in the assertions in
> `inventory-counts.test.sh` and `permission-guard.test.sh`. **Grep the literal entry string across the
> tree before the commit, not the directory you are editing.**

This belongs to this decision rather than to a record of its own because it is **this architecture
restated as an obligation**: the reason the justification is spread across five artifacts is that the
floor holds only the direct form while the hook and the records carry everything else. A layering that
divides a control across layers divides its record across files by the same cut.

**The mechanical half exists** — an assertion in `inventory-counts.test.sh` that no tracked file asserts
an allow entry the floor does not contain. **What it cannot reach, stated as a known bound:** it matches
a literal entry string, so it finds `Bash(bash:*)` in prose and does not find *"the interpreter class
stays in `allow`"*, which asserts the same thing with no entry name in it. **It closes the spelling, not
the class** — which is rule 2 above applied to the remedy for the problem rule 2 was written about.

### A path in an `allow` entry is a string prefix, not a directory scope

Recorded because the spelling suggests otherwise and a reader will infer a scope that is not there.
Measured against the floor and the hook: a path prefix carries through traversal, quoting, escaping and
symlink resolution while reaching any file on disk, and there is no `..` adjacency in the spellings that
work — so **no widening of a character class finds them**. Nothing bounds such an entry: not the matcher,
which cannot express a directory, and not `permission-guard.sh`, which deliberately does not resolve
quoting, escaping or symlinks. Any guard rule against the naive spelling is a **speed bump**, and is
recorded as one.

**And the reach argument is stated in the only form a single probe can settle**, because that is the only
form available over a grammar:

> **At least one `allow` entry reaches an arbitrary interpreter, so reach is already unbounded.**

Measured 2026-08-07: **`command perl -e 'print 1'` runs with no decision from any layer**, via
`Bash(command:*)`, although neither `perl` nor `ruby` is itself in `allow`. **One witness settles it.**
`Bash(awk:*)`, `Bash(find:*)`, `Bash(sed:*)`, `node` and `python3` are four more routes, and **this list
is not the set** — closing any member of it restores no bound, because the question is *which allow
entries can reach an interpreter*, a property of an open grammar rather than a list of names.
*"More entries than anyone has enumerated"* is a claim about **enumeration effort** with no falsifier;
the existential form above has exactly one, and it is cheap.

### The third layer: ask which SYSTEM authorises the act (2026-08-08)

Raised by `agents-lead` on `-io`#402, where `terraform apply` was reachable from a `workflow_dispatch`
against a caller-chosen tree. **The routing decision, the fail-open acceptance and the retained-floor-
entry cost are untouched; this extends the routing test.**

**The worked example is this decision's sharpest, because the rule already existed.** Rule 5g's
`gh workflow run` deny landed 2026-08-04 and its message names the exact risk verbatim — *"it can reach
`terraform apply` without the merge that is supposed to authorise it"*. **The rule named the risk
correctly and the risk stayed live for five days**, until it was closed **in the workflow file**
(`github.event_name == 'push'` on the apply job) — in neither of this decision's two layers. That is not
a failure of rule 5g. It is a fact about what rule 5g **can** bind: **one caller's terminal in one
session.** The GitHub UI, a PAT, a session with a different settings root, or any of the interpreter
routes above reach the same dispatch with rule 5g never consulted.

**This decision divided controls between two layers. There is a third**, and it went unnamed not because
no control needed it but because the question *which system authorises the act* had never been asked — so
controls of exactly that shape were routed here **implicitly**, and the routing was invisible. Three
already in this repository:

| control | workspace rule | the system that actually authorises it |
|---|---|---|
| direct push to the trunk | hook rule 7, floor `Bash(git push origin main)` | **branch protection** on `main` — **asserted, not measured**: the protection API is denied to the agent |
| merging with squash | hook rule 7b, floor `Bash(gh pr merge --squash:*)` | a **repository setting** — measured `squashMergeAllowed: false`, so the act is already foreclosed where it is decided |
| `terraform apply` from a laptop | hook rule 2 | **Terraform Cloud** pipeline-only apply, plus an AWS OIDC trust only CI can assume |

> **Ask which SYSTEM authorises the act, before asking which layer of this workspace can see it.** Where
> the act is authorised by a system outside the agent's shell — a CI trigger, a cloud IAM policy, a
> branch protection, a repository setting — **that system's own configuration is the AUTHORISING SYSTEM,
> and that is where the control belongs.** Route the control there, **keep the workspace rule**, and
> record it as what it then is: a **convenience refusal for the agent**, not the control.
>
> **Keeping it is part of the rule, not an afterthought.** Reclassifying a speed bump is not removing it
> — the agent's shell is still one of the routes, and a refusal that costs nothing is worth having on it.
> This sentence exists because the general form without it is the sentence someone would quote while
> deleting a hook rule that had just been correctly re-described.

**A word this decision spends, which the third layer must not overload.** Everywhere above,
*authoritative* answers a question **internal to this workspace** — hook versus floor. The layer named
here answers a different question, **which system authorises the act at all**, so it is called the
**authorising system** and never *the authoritative layer*. A control has both at once: `terraform
apply`'s authoritative *workspace* layer is the hook, and its *authorising system* is Terraform Cloud.

**Two statements above are narrowed by that distinction, and the second is the one that matters:**

- **Fail-open does not travel to the third layer.** *"The authoritative layer fails open"* is a fact
  about `permission-guard.sh` and stays exactly true of it. A branch protection, a repository setting and
  a pipeline-only apply do not emit no decision on a malformed payload. **So routing a control to its
  authorising system is the only move here that takes it out of the fail-open blast radius.**
- **The set the hook alone carries no longer only grows.** *"…and the set of controls it alone carries
  only grows"* was true while there were two layers, because migration only ever ran floor → hook. **The
  third layer is the first mechanism that shrinks it:** route the control to its authorising system,
  keep the workspace rule, and the control leaves the hook-alone set while the speed bump stays. A
  reader who takes *only grows* as still unqualified learns that migration is monotonically expensive
  and misses the one move that stops the meter.

#### The obligation this puts on a crude deny

> **A deny that stands in for a capability must name the capability in its own comment.** Crudeness is
> not a defect to apologise for — it is the honest shape when the act is not in the string — but a rule
> whose *name* is narrower than its *purpose* reads as precision and is filed as coverage.

**And the two words that must not be fused.** The proposal that produced this said *"the floor's correct
move is the crude, fail-closed deny"*. Both nouns are wrong, and the confusion is the exact one this
decision exists to prevent: these rules are **hook** rules, not floor rules; and the hook is the layer
that **fails open**. What is fail-closed about them is their **predicate** — they deny the whole class
rather than attempting to distinguish inside it — which is a property of the rule's logic, not of the
layer's failure mode. **Calling a hook rule fail-closed is the "hard backstop" sentence being re-derived
from scratch**, four days after this decision was taken to strike it. So: **crude in predicate,
fail-open in layer, and the record must say both.**

#### The sibling reviewer test — *can the hook SEE this?*

> **`permission-guard.sh` receives `.tool_input.command` and the root `agent_type`. Nothing else exists
> to it.** A value that can travel on **stdin**, in a file the command reads, in an environment variable,
> or in a later interactive prompt is invisible to a `PreToolUse` hook however clever the matcher is.

**Its scope, measured rather than asserted, because the obvious reading of it is wrong.** Piped at the
guard, `gh workflow run deploy.yml --json` **denies** (rule 5g) — the test does not defeat that rule,
because the *act* is in the command string and only the *inputs* are outside it. **What it forecloses is
a rule someone would otherwise propose:** a value-level refusal such as *"deny `gh workflow run` only
when it carries `apply_infra=true`"*. That rule is unwritable at this layer, and the reason is not
matcher cleverness — the value need never appear in `.tool_input.command` at all. **A design constraint
on future rules, not a defect in existing ones.**

#### The one finding that errs OPEN — recorded, not decided

**Rule 5e is the one command-level proxy that fails in the direction nobody notices, and this is by
probe rather than by reading.** Its predicate matches `gh pr comment`, `gh issue comment` and `gh issue
create`. `Bash(gh pr edit:*)` and `Bash(gh issue edit:*)` are both in the committed `allow` list, so a
persona 5e exists to keep off public surfaces reaches the same public surface through a sibling
subcommand the rule does not name. **5e's own comment claims "all three subcommands it names are
genuinely its own", which is true and is not the same claim as coverage.**

**Deliberately not decided here.** Before adding `pr edit` to 5e's predicate, ask whether **enumerating
sibling subcommands converges** — the rejected option above says it does not — and note that 5e's
argument is about a **capability**, which points at the tool grant rather than at a longer regex.
Naming that as the open question is what a record can honestly do; choosing between them is the owner's.

### The open question this section inherits

This record's own 2026-08-02 amendment decides *mechanism where the act is irreversible, skills where
the rule is a judgement*, and records an unresolved objection: **the rule is stated on reversibility
while its evidence is about expressibility**, and the two come apart (`inventory-counts` gates an
entirely reversible property and is one of the harness's highest-yield mechanisms). **This section is
stated on expressibility throughout** — it is the axis on which floor-versus-hook actually divides. That
is not an answer to the amendment's question; it is a second data point for it, on a different pair of
layers. **Both are now in one document, which is the fold's most concrete gain here**: the question and
its second data point were two files and a cross-citation, and a reader had to hold both open to see
that they were the same question.

### What this fold dropped

**All of it is defect archaeology about states the floor passed through in one day, and none of it
binds.** Named individually so a reader can go and find it in git rather than wonder whether it was
lost:

- **The whole perimeter table and its two amendments** — a seven-row before/overlay/after comparison of
  `allow` entries, struck and re-struck twice as three commits in the same batch put five interpreter
  wrappers in and took them all back out again. The **judgement** it argued survives above (the
  perimeter is non-containment, deliberately); the **tense war** does not. Its own method note says the
  overlay it measured is gitignored and truncated, so its middle column can no longer be re-derived.
- **The shadowed-entry counts** (ten `gh` entries, four `git` entries) and their re-derivation, which
  the section that publishes *record the derivation, not the count* had itself already marked stale.
  **The derivation is kept; the numbers are not** — which is that rule applied to its own record.
- **The `Bash(bash .scratch/*)` amendment in full.** The entry it prices was removed at #245, so it
  prices a grant that no longer exists. **What survived it is the general half**, kept above: a path in
  an allow entry is a string prefix, and the one-witness form of the reach argument.
- **The 2026-08-04 `-C`-form illustration** and its 2026-08-12 correction — a removed illustration, not
  a falsified claim, and its point ("for these the hook is already the only layer") is stated directly
  above instead.
- **The four-days-versus-five-days correction** on how long rule 5g's named risk stayed live, and the
  `-S`-versus-`-G` instrument lesson under it. **Five days is carried; the archaeology of how four got
  published is not** — the general form of that lesson is the *record the derivation* rule above.
- **The re-derivation of `agents-lead`'s four-proxy classification.** Its conclusion — *the test above
  is the thing to check against, not the number four* — is the derivation rule again, and the classified
  rules are named where they matter.
- **The record's own `Links` and evidence lists**, whose live members are folded into this document's
  cross-references.

## The merge precondition is a floor, not an instruction — **`accepted`** (absorbed 2026-08-20, record 0007; a narrower version implemented 2026-08-20)

~~**Read the status before the decision.** Record 0007 was `proposed` when it was absorbed and this
section inherits that status: **the hook it decides is unimplemented.** Nothing in the running system
behaves the way this section describes, and nothing is wrong today because of that. Everything below is
a design that was reasoned to a conclusion and never built.~~ **No longer true — see "What actually
shipped" immediately below, before the design that follows it.** The design below was reasoned to a
conclusion first and only PARTLY built; read the implementation note before crediting the running
system with everything this section describes.

### What actually shipped, and how it differs from the design below — read this first

**`hooks/scripts/permission-guard.sh` rule 7c** (right after rule 7b's caller-identity check) denies
`gh pr merge` when the last `quality-assurance` verdict comment on the PR does not read one of its
**two merge-authorising literals** — `APPROVE-AND-MERGE` or `APPROVE-AND-MERGE-BOUNDARY` — **for the
PR's current `headRefOid`**. It is real, it runs on every `gh pr merge`
tool call in every session, and it is mutation-tested (`hooks/scripts/permission-guard.test.sh`, section
"rule 7c") against every row of the table below that it actually implements.

> **The second literal arrived 2026-08-23** with [ADR-0002](./0002-roster-and-dev-loop.md)'s sixteenth
> amendment, which retired the hold-for-owner rule on boundary-class merges. That amendment holds the
> decision and its counter-argument; what belongs **here** is the enforcement consequence, and it is
> not cosmetic: **before the amendment, rule 7c would have refused every merge the new mandate
> authorises**, because the boundary class never produced the one literal this rule accepted. A
> mandate change that stops at the persona file is a mandate the floor denies.
>
> **Two things about the shape of the fix, both of which are this document's subject rather than
> 0002's:**
>
> - **The accepted set is an enumeration, never a glob.** `APPROVE-AND-MERGE*` would have covered both
>   literals in one pattern and also cleared `APPROVE-AND-MERGED`, `APPROVE-AND-MERGE-LATER` and every
>   future prefix-sharing drift — re-opening precisely the failure this rule exists to close, inside
>   the rule that closes it. The suite asserts the anti-glob case with its own fixture. This is the
>   *"Which layer carries a control"* section's rule applied again: a control over **a closed set the
>   author wrote** may be recorded as closed, and the way you keep it closed is by writing the members
>   down.
> - **The vocabulary itself is now gated, which it was not.** This document's *"The problem"*
>   subsection below measures three verdict-literal drifts shipping in one day, every one found by
>   reading and none findable by a check. Adding a fourth literal widens that surface, so
>   `hooks/scripts/inventory-counts.test.sh` gained two independently-reported arms: `session-wip.sh`
>   must recognise **every** literal `agents/quality-assurance.md` defines, and rule 7c must authorise
>   a merge on **no** literal outside that list. The set is parsed from the persona file, not restated
>   in the test.
>
> **What the new arm does NOT assert, stated so the green is not over-read:** it checks for *phantoms*
> in rule 7c (a literal the guard merges on that the brief does not define), not for *omissions* (a
> merge-authorising literal the brief defines that the guard rejects). The asymmetry is deliberate —
> the guard legitimately rejects `APPROVE-PENDING-HUMAN` and `REQUEST-CHANGES`, so the completeness
> direction cannot be expressed without encoding *which* literals authorise a merge, which would make
> the test a second source of truth for the very thing it is checking. That direction is covered
> instead by `permission-guard.test.sh`'s own ALLOW case for the boundary literal, which is where a
> behavioural assertion belongs.

**It implements exactly one row of the four-row outcome table below — "ran, and the answer is
negative" — and none of the other three.** Naming the gap precisely, so nothing here is credited with
more than it does:

- **NARROWER SURFACE, on purpose.** The design below is a standalone control reachable by *any* caller.
  What shipped sits **behind rule 7b**, which already restricts `gh pr merge` to the `quality-assurance`
  agent_type alone — an unforgeable, harness-stamped property, not something an untrusted party can
  claim. So 7c adds nothing against a *different* caller (7b already denies every one); it closes a
  narrower, still-real gap: **the one caller allowed to merge at all, drifting from its own posted
  verdict** — the exact vocabulary-drift failure this section's "The problem" subsection below measures.
  It does not implement "a `PreToolUse` hook on `gh pr merge` that denies a merge lacking the
  gatekeeper's marker" as its own freestanding control; it implements that check conditioned on 7b
  already having passed.
- ~~**FAILS OPEN on a missing tool, not closed.**~~ **REVERSED 2026-08-28 (#341) — rule 7c fails
  CLOSED. This bullet is struck in place rather than rewritten; see the amendment
  *"the merge floor fails closed, and only the merge floor"* at the end of this record for the owner's
  decision, what shipped, and the two claims in this bullet that measurement contradicted.** Read the
  text below as the argument that was recorded for the fail-open, not as the current behaviour:
  ~~The table below requires **deny** when `gh`/`jq` are
  absent. What shipped **allows** — matching `permission-guard.sh`'s own stated, file-wide policy
  ("Fails OPEN … on any parse error, a missing `jq`, or no network," this file's own header) rather than
  carving an exception into it. The reasoning for the deviation, not merely the fact of it: the design's
  fail-closed table row is argued from a threat an untrusted party can trigger at will against a control
  reachable by anyone; behind 7b, the only party who can even reach this branch is the harness-stamped
  reviewer, so a transient `gh`/network outage does not hand an outsider anything — it would, if anything,
  block a genuinely clean safe-class merge until the tooling recovers. **Named, not resolved:** this is a
  judgement call the owner may want to override; flipping the two `: ;;`/`*)` arms in rule 7c's final
  `case` statement is the entire diff required to make it fail closed instead.~~ **The owner did
  override it (#341), and "the entire diff" was measurably wrong — see the 2026-08-28 amendment.**
- **NO `ask` outcome, and none is possible without reintroducing a mechanism this file removed.** The
  table's third row routes an unattributable failure to `ask`; `permission-guard.sh`'s `ask()` helper was
  **deleted 2026-08-03** (this file's own comment above rule 5d), before this fold happened. Building the
  `ask` row back in means re-adding a helper this file's history explicitly argues against restoring
  without a fresh reason. Not attempted here.
- **NO explicit deadline, no bounded read.** The design requires the hook to "hold its own deadline
  strictly below the `timeout` its `hooks.json` entry declares," separately from `hooks.json`'s own kill.
  Rule 7c has no such deadline: an unresponsive `gh pr view` is bounded only by `hooks.json`'s outer
  timeout, whose kill this section's own "Consequences still being paid" list already names as degrading
  to **allow** — so on that one failure shape, 7c inherits the exact residual the design already priced
  for its own full version, not a new one.
- **THE AUTHOR FILTER IS WIDER than this design specifies, inherited rather than chosen.** "The trust
  class this takes" subsection below is explicit: `authorAssociation: OWNER`, **and nothing wider**. Rule
  7c reuses `session-wip.sh`'s `verdict_suffix()` jq program **verbatim** (deliberately — see the code
  comment at its call site, and `inventory-counts.test.sh`'s new byte-identity assertion), and that
  program — already shipped, already the reader every open-PR queue notice relies on — filters on
  `["OWNER","MEMBER","COLLABORATOR"]`. This is a **pre-existing discrepancy between this design and the
  code ADR-0006 already shipped**, not one introduced by this slice; reusing rather than forking it means
  7c inherits it rather than fixing it silently. Narrowing `session-wip.sh`'s own filter is a decision
  about already-shipped, already-tested code and is out of this slice's scope — named here so it is not
  lost.
- **The literal is hardcoded, not read from the persona file at runtime.** The design below says the hook
  "reads each persona's canonical verdict set from the persona file at runtime." Rule 7c checks the
  literals directly (`APPROVE-AND-MERGE`, and `APPROVE-AND-MERGE-BOUNDARY` since 2026-08-23), matching what `session-wip.sh` already does and what this file's
  own later "Which layer carries a control" section (absorbed above) already reasons is correct for a
  **closed set the author wrote**, rather than a caller-controlled grammar — so this is not a shortcut
  taken against the design's advice; it is the design's advice, updated by later reasoning in the same
  document, applied consistently with the one control that already existed.

**The gap this leaves completely unclosed, named because the record that motivated this slice measured
it directly rather than assumed it:** this hook has **zero reach over a human merging via the GitHub UI
or a personal terminal outside a Claude Code session** — no `PreToolUse` hook fires there, by
construction; the mechanism only intercepts tool calls a session issues. Measured on
[#293](https://github.com/tedeuxx/tadeumendonca-skills/pull/293): `mergedBy` was the owner's own GitHub
account, `is_bot: false`, while `REQUEST-CHANGES` sat on the PR's current head — the exact shape a
mechanically-clean rule 7c would have denied *had it been invoked through a session tool call*, and did
not touch at all, because the merge did not go through one. **That is not a defect in what shipped; it is
the honest boundary of what a `PreToolUse` hook is.** Nothing proposed anywhere in this document, built or
not, closes it — a browser click is not a tool call, in this or any future revision of this control.

> **The disposition this fold used is not the one ADR-0020 wrote for it, and that is a finding rather
> than a liberty.** Disposition 4 is scoped to *"a record whose decision is **still in force** and is
> merely moving"*; disposition 3 keeps a **`proposed`** record on the grounds that *"it explains an
> intended codebase, and its status already says so"*, and scopes deletion *"to **reversed** decisions,
> never to *unbuilt* or *unexercised* ones."* A `proposed` record being **absorbed** matches neither
> clause: it is not reversed, and it is not in force. **The set of four dispositions has a gap exactly
> here**, and the gap is not academic — one of the twenty records in this library sits in it.
>
> **What was done, and why:** absorbed, with the status carried into the heading and this paragraph,
> because disposition 3's *reason* is preservation of the reasoning and absorption preserves it
> verbatim in a live document, while leaving 0007 as a file would mean `controls-and-enforcement` is
> two files and the reconciliation does not close. **What was not done:** ADR-0020 and
> `documentation-standard` Part II were **not** amended to widen disposition 4. That edit belongs to
> the `decision-library` slice, which owns that document, and making it here would put a
> decision-library decision inside a controls slice. **The owner's call, named rather than assumed:**
> whether disposition 4 reads *"still in force"* or *"still current — in force, or proposed and not
> withdrawn."*

**Decided (as a proposal) 2026-08-03, amended 2026-08-04.** Deciders: the owner ratifies; the gate is
subject to it. Its History row is in [the index](./README.md).

### The problem, and it is the reason this section is in this document rather than in verification

[ADR-0006](./0006-verification-and-its-artifacts.md) fixed the right half: a verdict owed to another
persona exists as a **comment on the PR** rather than as prose in an orchestrator's context, so it can
be read rather than relayed. It did not fix the other half. **The rule that reads that artifact is
itself prose**, living in `agents/quality-assurance.md` — an instruction to a model, executed by the
same model it constrains, in a file that model also edits.

That is measured, not hypothetical. In a single day three drifts shipped in the vocabulary this rule
depends on: a persona file offered a verdict literal it never defined and the merging gate checked
against it; the same file carried a *third* vocabulary three sections below its own marker template, and
that was the one that actually fired (a verdict line posted reading `CLEAN`, which the reading gate
cannot parse); and `quality-assurance`'s own marker offered `APPROVED` while the set it defines is
`APPROVE-AND-MERGE` / `APPROVE-PENDING-HUMAN` / `REQUEST-CHANGES` (the set as it stood then;
`APPROVE-AND-MERGE-BOUNDARY` joined it on 2026-08-23). **All three were found by reading.
None could have been found by a check, and re-introducing any of them today goes green.**

> **The deeper point, and it is the sentence that makes this a `controls-and-enforcement` decision:**
> the strongest rule in the loop is enforced by the weakest mechanism available. **Whether a rule is
> mechanically enforced or merely instructed is the enforcement question, not the *done* question** —
> which is why this section lives here and not in `verification-and-its-artifacts`. It is also the
> boundary in this library's capability set that a reader is most likely to cross in the wrong
> direction.

### The mechanisms, and why they are not interchangeable

| mechanism | runs | can deny | sees |
| --- | --- | --- | --- |
| **hook** (`hooks.json` + script) | outside the model, on a tool call | **yes** | the tool call and live system state |
| **settings permission** | outside the model, on a matcher | yes | the command string only |
| **agent** (`agents/*.md`) | as a model, fresh context | no — it decides | whatever it reads |
| **skill / command** | as context, on invocation | no | whatever it is given |
| **`CLAUDE.md`** | as always-on context | no | static text |

**And the merge belongs in the hook row under the rule this record's own body already decided** — *if
the act cannot be undone it needs a hook, and a push to the trunk escapes git*. A `gh pr merge` **is**
that push; rule 7b's deny message says so in its own words. What a later merge fixes is the *site*,
which is a different object from the act: the deploy has fired, the release is cut, and an OG scraper
has pinned the card it first fetched.

### The decision, as proposed

**A `PreToolUse` hook on `gh pr merge` that denies a merge lacking the gatekeeper's marker.** The hook
reads the PR's comments and head, **discards every comment not authored by `OWNER`**, and denies unless
`quality-assurance`'s marker parses, carries a verdict literal from that persona's canonical set, and
records the current `headRefOid`.

**This reverses [ADR-0006](./0006-verification-and-its-artifacts.md)'s rejected option 2 on that
record's own terms, and the reversal is the argument worth keeping.** 0006 rejected gating rule 7b
because *"a hook buys the same guarantee as the artifact — a context willing to fabricate the comment is
a context that would equally spawn the gate and ignore its verdict."* **That argument is about
impersonation and it is correct about impersonation.** It does not reach **drift**, which is a different
failure and the one that has fired. A gate publishing an unparseable verdict literal is fabricating
nothing; it dispatched, read the comment, and applied a vocabulary its own file contradicted. Against a
party doing its honest best with a wrong rule, a hook buys exactly what the artifact does not: **it is
not reading the rule.**

**Scoped to the markers; the ratification half stays prose deliberately.** Safe-versus-boundary is a
judgement the hook cannot derive. It would have to demand ratification on every merge — deleting the
safe class — or take the class from the constrained party, putting the protection at its weakest exactly
where drift is most dangerous.

### What the hook does when it cannot answer — the table, which is the operative half

| the check | outcome |
| --- | --- |
| **a tool it needs is absent** (`gh`, `jq`) | **deny**, emitted by a path that does not use the missing tool, evaluated **after** the command is known to be a merge and **before** either question below |
| **ran, and the answer is negative** — the marker is absent, its verdict literal is outside the canonical set, or its head does not match | **deny.** This *is* a verdict, and it is the one the hook exists to enforce |
| **could not run, and no outsider could have caused it** — no network, `gh` unauthenticated, credentials rejected | **ask.** An answer we could not get is not a verdict, and it is not a licence either |
| **could not run, and an outsider could have caused it** — deadline fired, short response, degraded `authorAssociation`, an API error | **deny.** Ask is the owner's attention, and attention a stranger can summon on demand is a resource this loop rations |

**Two questions, asked in order, after the tool row.** *Did the check reach an answer?* If it did, the
answer decides. If it did not: *could someone outside the trust boundary have caused this?* Proven not,
**ask**; otherwise — including **cannot be shown either way** — **deny**. The cause lists are examples,
not an enumeration; the hook sees an error signal, not its causability, so the unlabelled remainder
denies.

**The ordering is a conjunction, and stating only one half reopens the hole on the other side:**

> 1. **Merge detection is itself performed without the tool whose absence it reports** — so the tool row
>    is reachable when that tool is gone.
> 2. **The tool row fires only once the command is known to be a merge** — so a missing tool never denies
>    unrelated Bash calls.

Both halves are needed. *Before either question* alone is not enough: merge detection reads
`.tool_input.command` **with `jq`**, so an implementer who parses first, detects, then checks tools has
satisfied that phrasing — and with `jq` absent the parse yields nothing, the hook exits, the tool row
never evaluates, and nothing emitted reads as **allow**. *Before any parse* alone is worse: an absent
`gh` would then deny every Bash call in every consuming repo, and an absent `gh` is ordinary.
**`wip-guard.sh` and `permission-guard.sh` both parse with `jq` first and reach `command -v` afterwards,
so the local idiom is the wrong order here** and an implementer copying the file beside them lands in
the hole.

> **The general rule, worth more than the instance: a control cannot depend on the thing whose failure
> it exists to report.** Three instances of it here — the emitter (`ask()` and `deny()` both build their
> JSON with `jq`), the deadline (which must be enforced without `timeout(1)`, absent on this platform),
> and merge detection — and each was found only after the previous one was fixed.

### The trust class this takes and neither existing hook does

This repository is **public**, so PR comments are **world-writable**. A precondition testing only the
marker line, the verdict literal and the head SHA can be satisfied by a drive-by account. That is not
the impersonation residue 0006 records — a trusted party writing with the right token — it is an
untrusted stranger, and `wip-guard.sh` reads only repo-controlled metadata.

The filter is `author.login` plus **`authorAssociation: OWNER`, and nothing wider.** That set is chosen
here rather than inherited: this repository's Merge Request Definition of Done carries no such idiom, and
the consuming repository's own third record,
[trunk-based delivery, single environment](https://github.com/tedeuxx/tadeumendonca-io/blob/main/docs/adr/0003-trunk-based-single-environment.md),
admits `OWNER` alone.

**An incomplete read denies.** `gh pr view --json comments` returns a bounded page, and on a public
repository the comment count is attacker-controlled, so a stranger who cannot forge a marker can still
push the markers outside the window. Both outcomes had to be chosen deliberately:

> **A stranger may be able to cost the loop a wedge. A stranger may never be able to cost it a merge.**

So a read that **did not find the marker** denies, whatever the reason, and a **degraded
`authorAssociation` fails to DISCARD, not to allow** — a filter that cannot establish authorship must
exclude the comment, never admit it.

> **And the general form, which binds any future control of this shape: any branch of a control that
> does not deny, reachable by an untrusted party, is a published bypass.** Every cause routed to `ask`
> has to be checked against it.

**The read is bounded and the deadline is separate from the page.** The hook fetches a fixed-size page,
never paginates, and holds its own deadline strictly below the `timeout` its `hooks.json` entry declares.
The page bounds **count, not bytes** — a stranger cannot choose how many comments are read, and nothing
stops them making the ones inside the window large — which is why the deadline is a requirement rather
than a refinement. **The hook reads each persona's canonical verdict set from the persona file at
runtime** rather than holding a copy, so *"the copy went stale"* is not a state that exists.

### The rejected options that are still live

1. **Keep it prose, and pin each persona's marker literals to its own canonical verdict set (#136).**
   *Why not:* it is worth doing and it is not this. The assertion proves the **file says** the right
   thing; it cannot prove the **gate did** the right thing at merge time, and a gate that reads a
   perfectly consistent file and merges anyway is exactly the failure mode. **Load-bearing rather than
   adjacent**, because the decision has the hook read the canonical set from the persona file at runtime.
2. **A `settings.json` deny on `gh pr merge`.** *Why not:* it deletes the safe class, which is the
   mechanism that makes the loop flow. The owner's 2026-07-30 decision moved reader-facing work *out* of
   the boundary class precisely to stop spending his attention on in-pattern merges.
3. **The same hook, but `ask` instead of `deny`.** **Partially adopted, and the split is the decision** —
   a missing tool denies before either question; `ask` **only** where the check could not run *and* no
   outsider could have caused that. *Why not for everything:* a hook that asks on every merge converts
   the safe class into a prompt.
4. **Gate the COMMENT rather than the merge** — 0006's own option 3, denying a `gh pr comment` whose body
   carries a marker naming a persona the caller is not running as. *Why not, narrowly:* it never fires
   when there is nothing to forge, and both the observed failure (omission) and this record's target
   (drift) forge nothing. **It is a complement to the author filter, not an alternative** — a stranger's
   comment never passes through the harness at all, so it defends a different door.
5. **A required GitHub status check.** *Why not:* the markers are comments, so the check would be posted
   by the same token the gate writes with, inheriting the impersonation residue without gaining the
   interception. It also only works where branch protection does, and `main` here is the working branch.

### Consequences still being paid

**Good** — the precondition would hold even when the gate misreads its own file, which is the observed
failure; a marker with an unparseable verdict would stop the merge instead of being interpreted; and the
rule would gain a single mechanical definition instead of existing as prose in one persona file and
being *described* in another, where the two can disagree without either being wrong.

**Bad / accepted, and these are what an implementer inherits:**

- **A second network-dependent `PreToolUse` hook on every Bash call.** The hook must exit before any
  network work when the command is not a merge; ~99% of calls are not merges.
- **The kill sits above this hook.** `hooks.json` kills a hook at its declared `timeout`, and a killed
  hook emits no decision, which the harness treats as **allow**. The deadline requirement means the hook
  has already answered when the kill arrives — the path is bounded, not removed.
- **The one path that still ends in a merge nobody checked is UNBACKED, unlike its sibling's.**
  `permission-guard.sh` can afford a missed deny because the settings `deny` list is its named backstop.
  This hook has none: `Bash(gh pr merge:*)` sits in the consuming repository's **allow** list, so it
  degrades to rule **7b** alone.
- **The fallback floor has a hole this hook reproduces.** A raw `gh api … PUT …/merges` is not matched by
  rule 7b, and this hook matches the same surface — `gh pr merge` — so one command form walks past
  **both** at once.
- **A stranger retains one effect, and it is a wedge rather than a merge.** Comment volume can push the
  markers out of the fetched window, which denies.
- **The impersonation residue is unchanged and the filter does not reach it.** The token the harness runs
  with **is** the owner's, so the author filter separates outsiders from the harness, never the harness
  from itself.
- **The measured cost 0006 recorded for this option is real and inherited** — the PR-number parsing a
  bare `gh pr merge` needs, which is rule 5d's four rounds and eighty deleted lines. This reverses that
  rejection on the impersonation-versus-drift argument, **not** by claiming the parsing got cheaper.
- **Two mechanisms now encode part of one rule** — the hook (artifacts present and current) and the
  persona file (what they mean). That is the split this argues for, and it is still a seam: a change to
  the marker shape must move both.
- **"Floor" is a term of art in this repository** for `permission-guard`'s irreversible set, and this
  hook is not that. The absorbed title carries the stronger word without the caveat.

### The 2026-08-04 amendment, and why it makes the case stronger rather than weaker

`security` was absorbed into `quality-assurance`, so **the precondition is ONE marker, not two.** Every
*"both markers"* in the original reads *the marker*, and **only the count changes** — the author filter,
the four-row outcome table, the ordering conjunction, the bounded read, the deadline, the emitter
constraint and the prose-ratification scope are all untouched.

What changes in **kind** is the part worth carrying: the hook is now checking the merging gate's own
marker, and only that. Before, one of the two markers came from a party that does **not** merge, so at
least one input to the precondition came from outside the party the precondition binds. **That property
is gone**, and 0006's fourth amendment records that the remaining verdict is now **self-enforced** — a
self-enforced precondition is precisely the configuration this section exists to object to. Stated
plainly because the opposite reading is available and wrong: *"one gatekeeper, so half the precondition,
so half the point."* Half the markers, and the remaining one is the one nobody else checks.

**The cost that got worse:** with two markers, a self-fabricating gate had to fabricate a verdict
attributed to a persona it was not. With one, the marker it must produce is its own. Against **drift**
the hook still works; against a gate that decides to post an approval it does not mean, this buys
nothing and never claimed to.

### What this fold dropped

- **The expired falsifier and its correction narrative.** The record carried `grep gatekeeper-verdict
  hooks/` as proof the hook was unimplemented, then a block explaining that the command started
  returning hits from `session-wip.sh` — a **reader**, not a denier — and that the proxy had broken. The
  lesson (*a grep for a string was standing in for the existence of a control*) is real, but it is
  archaeology about one falsifier. **What replaces it is the check that still works, stated once:** to
  verify the hook is still unimplemented, look for a hook that returns a `deny` decision on `gh pr
  merge`; rule 7b routes that merge to the gate persona and asserts nothing about a verdict.
- **The fifteen-review-round footnote** pointing at PR #138 for the superseded framings. The PR is still
  there; nothing binds on the pointer.
- **The seven-entry perimeter table and its struck-and-re-struck history** — the interpreter-class floor
  entries (`bash`, `sh`, `perl`, `ruby` and the rest) that the record's 2026-08-04 amendment measured
  moving out of `allow` and back, commit by commit. **Added to this list on 2026-08-20 (#283 slice S4);
  it was dropped in S3's fold and this list did not say so**, which made the list one entry short of its
  own standard — a `What this fold dropped` section that omits a drop is exactly the failure the section
  exists to prevent. What binds survives above: the perimeter is **non-containment**, and removing the
  interpreter spellings changed what is *free*, not what is *contained*. The commit-by-commit
  archaeology does not, and is re-readable at `448c506` if anyone needs it.
- **The `Considered options` restatement of the chosen option as option 1.**
- **The record's own `Links` list**, whose live members are folded into this document's cross-references.

### Amendment (2026-08-23) — the fail-open had a third door, and it was the one the house tells you to use

~~**The decision is unchanged: rule 7c still fails open.**~~ **Struck 2026-08-28 (#341): it does not
any more.** Everything else in this amendment stands — the extractor fix it records is unaffected, and
its closing generalisation (*a fail-open's safety argument is an argument about the causes that can
reach it*) is what the 2026-08-28 amendment builds on rather than replaces. What changes is the
argument recorded for it, because a premise it rested on was measured false.

**What the record claimed.** The *"FAILS OPEN on a missing tool, not closed"* bullet above justifies the
deviation from the four-row table on the grounds that *"behind 7b, the only party who can even reach this
branch is the harness-stamped reviewer, so a transient `gh`/network outage does not hand an outsider
anything — it would, if anything, block a genuinely clean safe-class merge until the tooling recovers."*
Every cause it names is **environmental**: a missing tool, a transient outage, no network. The bullet is
the whole of the recorded argument, and it enumerates the ways the check can fail to run.

**The enumeration was incomplete, and the missing member is the hook's own parser.** Rule 7c's repo
extraction was anchored `^gh <flag> <value> pr merge` — the `-R`/`--repo` flag **before** the subcommand
and nowhere else. Measured by piping both spellings into the hook with an arg-logging `gh` stub:

```
gh --repo owner/repo pr merge 479 --merge   ->  qa_repo=owner/repo  ->  gh pr view 479 --repo owner/repo …
gh pr merge 479 --repo owner/repo           ->  qa_repo=<empty>     ->  gh pr view 479 …        (cwd repo)
```

and with `REQUEST-CHANGES` sitting on the named PR's current head, the second spelling came out
**ALLOW**. No outage, no missing tool, no unauthenticated `gh` — a well-formed command that `gh` accepts,
issued by the harness-stamped reviewer, reaching the fail-open through the extractor rather than through
the environment.

**And the losing spelling is the one this platform MANDATES.** `skills/shell/SKILL.md`: *"Target
another repo with `gh <subcommand> --repo <owner/repo>`, never `gh -R <owner/repo> <subcommand>`."* That
rule is right about its own subject — a flag before the subcommand changes the allowlist prefix — and it
is preloaded by all six personas, `quality-assurance` included. **So the strongest control in this loop
was off for the exact spelling every persona is instructed to write.** A fail-open reached by a malformed
command and a fail-open reached by the mandated command are not the same trade, and only the first is
what the bullet above priced.

**Worse than "no answer", in the ordinary case.** The record reasons about the fail-open as *degrading to
7b alone*, which is what happens when the read returns nothing. That is the benign shape. The likelier
shape is that `gh pr view 479` **succeeds** against whatever repo the working directory resolves to and
returns a **different PR #479**, with its own head and its own verdict — which the hook then reads with a
straight face. An answer about the wrong subject is not an absent answer, and nothing in the outcome table
above has a row for it.

**The fix, and what it covers.** The extraction now uses `wip-guard.sh`'s position-agnostic shape with
`gh_repo_flag`'s character class, verbatim: `-R`/`--repo`, value attached, `=`-joined or space-separated,
on **either** side of the subcommand. The repo flag is also stripped before the positional ref is read, so
a flag placed between `merge` and the ref no longer redirects 7c to the current branch's PR.

**Why the fail-open stays open, stated as what makes it safe *now* rather than as what made it safe
before.** The bullet's argument is sound for the causes it names, and those are now the only causes left:
the parse path that bypassed it is closed, so reaching the fail-open again requires an actual `gh`/`jq`
absence, an actual outage, or a genuinely unparseable command — none of which an outsider can trigger
behind 7b, and each of which would otherwise block a clean safe-class merge with no override available to
the one persona allowed to perform it. **What closing it would cost, named so the choice is real:** a
network blip during a merge would deny `quality-assurance`'s only irreversible act, with no second caller
authorised to retry it, and the honest recovery would be the owner merging in the browser — the one path
this hook has **zero reach over** (measured on PR #293, above). A fail-closed rule whose failure mode is
*"do it by hand, unchecked"* is not a stronger control.

**The generalisation, which is the part worth more than the instance.** *A fail-open's safety argument is
an argument about the causes that can reach it, and the parser that decides whether the check runs at all
is one of those causes.* The four-row table above enumerates outcomes **after** the check has been aimed;
it has no row for *the check was aimed at the wrong thing*, and it cannot acquire one, because a hook
cannot know it mis-parsed. So the obligation falls on the extractor, and the way it is discharged is
convergence rather than care: three different spellings of the same flag lived in `permission-guard.sh`
at once — the shared `gh_repo_flag`, a copy at rule 5c one character behind, and 7c's own. Both suites
were green on all three, because `inventory-counts.test.sh` compared `wip-guard.sh`'s copies to
`permission-guard.sh`'s **first** class and never compared that file's copies to **each other**. It does
now, as its own independently-reported arm.

> **A retraction, recorded because the way it was caught is the point.** The first version of this
> amendment — and the code comment and commit message shipped with it — claimed the rule 5c copy was a
> **second live fail-open**: that `gh -R=owner/x issue create` matched nothing and the subagent issue
> gate was off for that spelling. **That is false.** Rule 5c uses the class in a **matcher**, inside an
> optional group followed by a greedy `[^[:space:]]+`, so the drifted class matches `-R`, the space
> class matches empty, and the value class swallows `=owner/x` whole. Measured over all six spellings:
> identical behaviour. The divergence there was **latent, not live**.
>
> It was written from the shape of the defect next door rather than from a measurement, it read
> plausibly, and it survived the review of its own diff. What caught it was **mutating the class back
> and watching the four new behavioural assertions stay green** — a claimed fail-open that no test
> could see. This document's own standing rule (*"an assertion that cannot fail"*) applied to a claim
> in the record rather than to a line of code.
>
> **What survives the retraction, and it is the more useful finding:** the same characters are harmless
> in a matcher and a fail-open in an extractor — the capture boundary lands inside the value and the
> `=` leaks into the slug, which is exactly what took `wip-guard.sh` off for a week and one of the two
> things 7c got wrong. So the copies are converged **because position decides whether a spelling is
> latent or live**, and no reviewer should have to re-derive which position a given copy is in. That is
> the argument for the intra-file arm; "there were two holes" never was.
This is the *"Which layer carries a control"* question asked one level down: not *can this layer hold the
control*, but *can this layer still see the act it is holding a control over*.

**Deciders:** the owner ratifies; written by `agents-lead` (authorship split by domain — this is loop
machinery). Pre-implementation reproduction and mutation-check by the same, in the slice that fixed it.

### Amendment (2026-08-28) — the merge floor fails CLOSED, and only the merge floor (#341)

**The decision, and it is the owner's, in one word.** Asked whether the merge blocks or passes when
reading the gate's verdict fails — no network, expired auth, a bad PR ref:

> «deveria travar»

**No readable verdict, no merge.** The unblock is manual and his. This reverses the *"FAILS OPEN on a
missing tool, not closed"* bullet above, which named itself *"a judgement call the owner may want to
override"*; he has.

**What the fail-open actually was, and why it was worth reversing here and nowhere else.** It was not
that the check was skipped — it is that the check was skipped **emitting nothing**, so a merge with no
gate was indistinguishable, in the transcript and on the PR, from a merge with a clean one. Every other
control in `hooks/scripts/` degrades into something a later step can still catch. This one degraded into
the irreversible act itself. That is the criterion for the exception — **what the degradation lands on**,
not how important the rule feels.

**The recorded diff estimate was wrong, and it was wrong in the larger half.** The struck bullet says
*"flipping the two `: ;;`/`*)` arms in rule 7c's final `case` statement is the entire diff required"*.
Measured against the code it describes: it is not. The `case` is reached only inside
`if [ -n "$qa_pr_json" ]`, so an absent `gh`, a failed API call, an expired token or a PR ref resolving
to nothing never enter the `case` at all — they skip it, and flipping its arms changes nothing for any
of them. The `case`'s `''` arm covers only a **third** flavour of unreadability: a response that arrived
carrying no `headRefOid`. So the fix is two edits, not one: a `qa_unavailable` sentinel set before the
read is consumed, and the `''` arm split out of the clearance list. **The bullet was written from the
shape of the rule rather than from its control flow** — the same defect this record already logs one
section up, where a claimed fail-open was written from the defect next door instead of from a
measurement. It is recorded here rather than quietly corrected because *an ADR that states the size of
a change nobody has run* is the failure mode this library is most exposed to.

**What shipped, by cause, each with its own message.** Absent `gh` · absent `jq` · the API call
returning nothing (no network, missing or expired auth, a rate limit, a PR reference resolving to no
pull request) · a response with no readable head. Each denies naming **which precondition was missing
and what unblocks it** — because a deny that is silent about why trades one invisible failure for
another, which is the defect being fixed, not a lesser version of it.

**Verified by mutation, one cause at a time, because a batch mutation cannot attribute a red.** Three
independent mutations of the SOURCE, each run against the whole suite:

```
bash hooks/scripts/permission-guard.test.sh                       # control: 380 passed, 0 failed
# 1. the unavailable-read deny disabled  (`if [ -n "$qa_unavailable" ]` -> `if false`)
#    -> 377 passed, 3 failed: causes 1 (no gh), 2 (API failure), 3 (bad PR ref) — and nothing else
# 2. the empty arm restored to the clearance list (`…|'') : ;;`)
#    -> 378 passed, 2 failed: causes 4 and 4b (no headRefOid / empty headRefOid) — and nothing else
# 3. both clearance literals removed (a floor that denies everything)
#    -> 368 passed, 12 failed, including both new clearance controls
```

Mutation 3 is the one that matters most and is the one a suite of this shape usually lacks: **closing a
fail-open ships a floor that denies everything unless something proves otherwise**, and the two
clearance controls sitting next to the mutation are what prove otherwise.

**THE SCOPE, STATED AS A REFUSAL RATHER THAN AS A NOTE.** The owner was asked about the merge floor and
answered about the merge floor. **Every other control in this file, and every other hook in
`hooks/scripts/`, still fails open and is untouched by this.** The generalisation across the guard set
is [#342](https://github.com/tedeuxx/tadeumendonca-skills/issues/342), a separate Issue with a separate
decision that has not been taken. A one-word ruling is the easiest thing in this repository to
over-apply, and the fail-open contract it would be applied to is the one whose alternative — wedging the
agent with no repair route — this record has already priced twice.

**One branch is UNREACHABLE and shipped anyway, named here so nobody credits it.** A missing `jq` never
reaches rule 7c: `permission-guard.sh` parses `.tool_input.command` with `jq` near its top and `exit 0`s
on an empty result, so one absent `jq` disables the **entire** file — every rule, not this arm — and
`deny()` is itself `jq -n`, so even the refusal could not be printed. Measured, and asserted in the
suite as the current behaviour under the label `NAMED GAP, not #341's fix`, so it goes red the day
somebody closes it. It is a different failure with a wider blast radius, it was excluded from #341's
decision explicitly, and it is not fixed here.

**And that last claim was FALSE when this record first made it — caught by the gate, not by its author,
and recorded here because the shape is worth more than the fix.** The assertion set `PATH` to a
directory holding a single `gh` symlink and then called the suite's ordinary helper — a helper that
builds its payload with `jq -n` and launches the guard with `bash "$GUARD"`, **both resolved through
that same emptied `PATH`.** So `jq` went missing from the *harness*, the guard was never launched, the
empty output classified as ALLOW, and the case reported `ok` for a reason with no relation to the
guard's behaviour. The gate proved it by simulating the repair — the parse branch denying instead of
exiting 0 — and watching the assertion stay green.

**The rule this yields, which generalises past this instance.** *Pinning a known-wrong behaviour is
disciplined on three conditions: the gap is named in the assertion's own name, the reason is in the
comment beside it, and **it actually reddens on repair**. The third is what does the work — without it
the pattern is strictly worse than the comment it replaces, because a comment does not claim to be a
check.* The correction has two parts, and the second is the transferable one:

- **Remove one tool, not an environment.** The guard now runs under `env PATH=… bash "$GUARD"` against
  a fixture holding symlinks to every external it reaches for (`bash`, `cat`, `grep`, `sed`, `awk`,
  `tr`, `head`, `env`, `git`, `gh`) and **only** `jq` absent, while the harness keeps its own real
  tools.
- **Assert the EXIT CODE, because the expected observation is silence.** A guard that never launched
  exits **127**; a guard that launched and allowed exits **0**; both emit nothing and both classify as
  ALLOW. Where a test's expected result is *no output*, the absence of output cannot also be its
  evidence that anything ran. Re-measured against both directions: the simulated repair reports
  `DENY/rc0`, and deliberately dropping `bash` from the fixture — the original defect, reproduced —
  reports `ALLOW/rc127`. The failure line names which of the two moved.

**What the exception costs, since it is a cost this record twice declined to pay.** Rule 7c can now
wedge the gatekeeper: with no network the one persona authorised to merge cannot merge, and no command
it can run repairs that. The recovery is the owner merging in the browser — **the path this hook has
zero reach over**, which is the argument the 2026-08-23 amendment used to keep the fail-open open. That
argument is not refuted here; it is **outweighed**, on the owner's call, by the fact that the silent
version of the same outcome produced a merge that nobody could tell from a reviewed one. A deferred
merge costs a retry and is visible. An admitted one costs the whole control and is not.

**Deciders:** the owner decides («deveria travar»); written and built by `agents-lead` (authorship split
by domain — this is loop machinery). Gate review by `quality-assurance` on the diff, like any other.

## Permission entries have three states, and absent is not one (absorbed 2026-08-20, record 0018)

**Disposition 4 of [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md):
record 0018's decision is still in force and is moving into the document that governs the capability it
belongs to.** Decided by the owner on 2026-08-13, driven by
[#163](https://github.com/tedeuxx/tadeumendonca-skills/issues/163). Its History row is in
[the index](./README.md).

### The decision, as it currently binds

**A permission entry is in one of three states, and there is no fourth:**

| state | means |
|---|---|
| `deny` | never, at any price |
| `ask` | not without me — **currently non-functional in this harness**, see the cost below |
| `allow` | pre-authorised |

**Absent is not a state.** An entry that is in none of the three lists is not a decision; it is the
*omission* of one, and it resolves to whatever the nearest broader `allow` pattern says, silently.

The practical form, which is what a future request shaped like #163's runs into: **"let this specific
case through without opening the whole class" cannot be spelled by deleting a `deny` and stopping.** It
has to become an actual `allow` — if the class is judged safe to pre-authorise unconditionally — or stay
`deny`. There is no third resting place that also counts as a decision.

This **generalises** the narrower finding the body of this record already carried — *a control expressed
as absence is not a control*, earned on `gh api` being unlisted rather than denied — from one measured
case into a stated principle. It is **orthogonal to** the *which layer carries a control* section below:
that one decides which layer holds a control, this one decides which state an entry in the static layer
may be in.

### The rejected options, each on a measured failure — kept because a future request will re-open them

1. **A fourth state, "absent", used deliberately for the unitary case.** Rejected on three properties it
   lacks that `deny` has, and all three are the same property from different angles — **absence is not
   observable as a decision, so it cannot be audited as one**:
   - it is erasable by a broader `allow` added anywhere, silently (this workspace already carried
     **15** such unreviewed entries in local overlays when #163 measured it);
   - a removed `deny` and an entry that never existed are **indistinguishable in the file**, so the
     decision leaves no record that it was made;
   - it does not survive `settings.local.json`, which accumulates by clicking and is never reviewed.

2. **Migrate the unitary case into `permissions.ask`.** Rejected on a **measurement, not a principle**,
   and this is the one a later reader is most likely to want to re-run. #163's test, executed
   2026-08-13: move `Bash(aws cloudfront create-invalidation:*)` from `deny` to an `ask` entry in **both**
   the committed project file and the global user-scope file, then run the command as a live tool call.
   **Result: no permission prompt — the command executed directly**, reaching real AWS auth and failing
   only on an expired session token, meaning no permission layer intercepted the call at all.

   > **This is a falsification, not a rejection on the merits, and it is dated.** `ask` is a real state
   > in the model and does not work through this configuration surface in the Claude Code version tested.
   > It is falsified **until re-measured against a newer version**, and re-measuring it is the cheap move
   > for anyone who wants the state back.

### Consequences still being paid

- **`ask` is vocabulary with no working implementation.** Any decision that would have used it is stuck
  choosing between `deny` and `allow` until the measurement above is re-run and comes back different.
- **The `deny`/`ask`/`allow` triple is a closed, enumerable domain**, which is why it may be stated as
  closed at all — see the *pattern over a grammar* rule in the absorbed 0008 section below, which forbids
  exactly that word for controls matching a caller-controlled string. The distinction is deliberate and
  the two sections do not contradict each other.
- **This record does not resolve #163's own remaining concrete action** — removing the duplicated AWS
  `deny` entries from the unversioned, self-protected global `~/.claude/settings.json`. That is an
  owner-executed step with no PR, gate or record, orthogonal to the vocabulary decided here.

### Where this decision is live in the tree, so the section is checkable rather than descriptive

`permission-guard.sh`'s rule 5e applies it by name: an unlisted persona defaults to **DENY**, on the
grounds that *absent is not a state*, and `permission-guard.test.sh` asserts that default. That is the
one place in this repository where the principle is mechanically enforced rather than merely stated.

### What this fold dropped

- **The bootstrapping note.** Record 0018 carried a paragraph explaining that it was written directly
  rather than by a dispatched `agents-lead`, because the plugin was disabled for that phase. It is
  archaeology about how one record came to be written, and it binds nothing.
- **The `Considered options` framing of option 1 as an option.** Option 1 *is* the decision; restating it
  twice was MADR structure, not content.
- **The record's cross-citation of 0008 as a separate record**, which is now a cross-reference inside one
  document.

## Amendment (2026-08-23) — a third control class: ROUTING, and the matcher that is an enumeration (#319)

**The decision.** The main agent may not edit a repository directly. A `PreToolUse` guard
(`hooks/scripts/orchestrator-write-guard.sh`) denies a file-writing call whose `agent_type` is empty
and whose path resolves inside a **git working tree**; a `Stop` hook
(`hooks/scripts/orchestrator-tool-census.sh`) reports the rest without deciding anything.

**Why this is a new class rather than another floor entry, in this document's own vocabulary.** The
floor denies what is IRREVERSIBLE. This denies what is REVERSIBLE, tracked and reviewable — and denies
it anyway, because the harm is not the edit, it is that no persona's judgement and no gate keyed on a
persona ever touched it. The four reasons a control cannot live in `.claude/settings.json` (this
document's *Which layer carries a control* section) are joined by a fifth, and it is decisive here:
**the permissions syntax has no caller dimension.** A path-scoped `deny` there hits `developer` exactly
as hard as it hits the orchestrator. Any caller-keyed control is a hook by construction — the same
reason rules 5c/5d/5e/7b were born in `permission-guard.sh` with no floor entry behind them.

**Why a separate hook, not a rule in `permission-guard.sh`.** That script is registered on the `Bash`
matcher and returns immediately when `.tool_input.command` is empty, which every file-writing payload
is. Two matchers, two scripts, one concern each.

**The measurement that changed the design, and it is the part worth carrying past this issue.** The
control was specified with matcher `Edit|Write`. **A matcher is ANCHORED, not a substring search** —
probe plugin, one variable at a time, 2026-08-23:

| probe | result |
|---|---|
| matcher `rit` + a main-agent `Write` | did NOT fire; file created |
| matcher `Write` + the identical call (control) | fired, denied, no file |
| matcher `Edit\|Write` + a main-agent `NotebookEdit` | **did NOT fire; the notebook was mutated inside a git working tree** |
| matcher `Edit\|Write\|MultiEdit\|NotebookEdit` + the identical call | fired, denied, notebook unchanged |

`NotebookEdit` is a **deferred** tool in this build — listed by name, schema loaded on demand — which is
why reading a session's initial tool list does not find it. And the payload key is `notebook_path`, not
`file_path` (measured: `keys=["cell_id","new_source","notebook_path"]`), so a guard reading only
`file_path` allows every NotebookEdit **even with the matcher naming it** — a second side door behind
the first, which no matcher fix would have closed. **Therefore: a matcher is an enumeration and inherits
every risk an enumeration has**, exactly like the pattern-lists this document already rejects on the
`Bash` side. ~~The mitigation is not a claim of completeness — it is that~~
~~`hooks/scripts/orchestrator-write-guard.test.sh` asserts the registration itself, so narrowing the~~
~~matcher goes red instead of quiet.~~

**Struck 2026-08-31 (#386): that file is DELETED in the same slice that removed the hook, and its CI
step with it, so THERE IS NO MITIGATION — this paragraph named a control that does not exist, in the
one paragraph a future guard author is sent to read.** The struck sentence is corrected here rather
than deferred with its neighbour at *"denies a file-writing call whose `agent_type` is empty"* above,
and the two are genuinely different: that one is a **dated amendment** reversed in this same document
1,100 lines later under *"`orchestrator-write-guard.sh` is REMOVED"*, so a reader who keeps reading is
corrected; this one is a **standing engineering lesson about matchers**, deliberately kept live and
deliberately rehomed by this slice precisely so the next matcher author reads it — and it was left
pointing at a test suite that is gone.

**What survives the strike, and it is everything the lesson is for:** a matcher is anchored rather than
a substring search, `NotebookEdit` is deferred and carries `notebook_path` rather than `file_path`, and
therefore a matcher is an enumeration. Those are properties of the runtime measured on build 2.1.241,
not of the deleted hook. **What does NOT survive is the reassurance.** Any future hook on a
multi-tool matcher ships with no assertion behind its registration unless its author writes one —
`hooks/scripts/hooks-executable.test.sh` checks that a registered script exists and is executable, and
nothing anywhere asserts that a given matcher still names the tools its argument depends on. That is the
residual, and it is now the reader's to carry rather than a suite's.

**What is deliberately NOT mechanised, recorded so it reads as a decision.** Reads, `gh issue create`,
and the `gh pr comment` / `gh issue comment` routes rule 5e allows the orchestrator. A hook sees `grep`
and a path, never whether the answer was already in a subagent's return, so it cannot tell a justified
read from a lazy one; and denying the comment routes would leave an intake finding with no durable
artifact, since at intake there is frequently no PR and `product-lead` holds no `Write` at all. That
half is a **habit**, observed by the census and enforced by nobody.

**Named residual — the `Bash` side door, open and known.** `Bash(sed:*)` and `Bash(tee:*)` are in the
committed allow list, so `sed -i` and `tee` reach a tracked file without passing this matcher. Closing
it means resolving a path out of a shell command string, which is the SEMANTIC class this document says
a pattern cannot hold — and a wrong guess there denies `developer`'s builds too, since the guard decides
from the same string. It is left open and made **visible** instead: ~~the census classifies those commands
into its write/post class.~~ **Struck 2026-09-01 (#371) — true of the two commands this paragraph names,
false as the general property the sentence reads as.** It reads as *the census sees the `Bash` write side
door*; measured, it saw a hand-listed slice of it, and a wrapper prefix or a stray option put a mutation
in the READ list. See the 2026-09-01 amendment below for what the census sees now and what it declares it
does not. `command > file` was already denied outright for every caller (#244), so the
loudest spelling of this door was closed before this rule existed.

**Accepted costs.** The guard fails open on a missing `jq`/`git`, like every other guard here. It is a
routing rule the main loop can always satisfy by delegating, so it enforces routing and not capability —
the same property rules 5d/7b have. And the census counts **attempts**: a denied call still appears in
the transcript, which the notice states every time rather than pretending otherwise.

## Amendment (2026-08-25) — a control on the DISPATCH, and the rule is *classify the claim, not the actor* (#326)

**Why this is an amendment here and not a new record, stated first because it is a judgement someone
may disagree with.** It crosses the significance test on *establishes a cross-cutting pattern others
will follow* — it is the first control this harness has placed on the dispatch tool, and it answers
this document's own standing question (*which layer carries a control, and can that layer hold it?*)
for a layer nothing had used. It is **not** a new capability: it is one more answer to the question
this document exists to hold, and the controls capability was deliberately consolidated into one record
on 2026-08-20. Splitting it back out would fragment the thing that consolidation fixed. The rejected
options below are the part that had to be written down somewhere, and this is where the others live.

**The decision.** A `PreToolUse` guard on matcher `Agent`
(`hooks/scripts/dispatch-premise-guard.sh`) denies a dispatch whose brief stamps a repository state
that is not true: a commit named as the brief's premise must be HEAD of the repository the brief's own
citations resolve to, and a branch named alongside it must be the branch that repository is on.

**The problem, measured rather than argued.** Two leads were dispatched on a brief citing
`architecture.en.md:132` and stamped *"against `main` at `e92d62a`"*, while the tree sat on
`feat/persona-membership-drift-detector-431`. Roughly 210k tokens were spent reviewing copy that had
already been corrected. **The structural point is not that a human erred.** A dispatched actor
*inherits* its brief's premise and cannot check it — it was not present when the measurement was taken
— so the premise of a dispatch was a load-bearing claim that nothing in the loop ever read back. That
is the same defect shape #329 recorded one layer up, and it is the shape the state-model rule in
`agents-configuration` exists to catch: *what observable artifact says this was true?*

**Why `PreToolUse` and not `Stop`.** Because this layer can **prevent**. A `Stop` hook would report the
waste after it was paid for, which is the difference between a control and a receipt. This is the first
place in this document where the preventive/detective split falls on the side of prevention for a
non-floor concern.

**The measurement that decided the matcher, and it is the trap worth carrying past this issue.**
The dispatch tool is named **`Agent`**, not `Task`. Probe/control, headless, one variable:

| probe | result |
|---|---|
| `PreToolUse` matcher `Agent` + a real subagent dispatch | fired; payload captured |
| `PreToolUse` matcher `Task` + the identical dispatch | **fired zero times; the log stayed empty** |

A `matcher` is a **regex**, so `"Task"` still matches `TaskCreate` — it would give a hook that fires on
todo-list writes and never on a dispatch: **inert and installed-looking**, this repo's named failure
shape and the exact one the previous amendment's `Edit|Write` measurement is about. The mitigation is
the same one and it is not a claim of care: `dispatch-premise-guard.test.sh` asserts the registration,
so the matcher going wrong goes red rather than quiet.

**Two more properties of that payload shaped the design.** The full brief is in `.tool_input.prompt`,
which is why the claim is legible at this layer at all. And `subagent_type` is **absent** when the model
dispatches the default general-purpose agent, present only when it names a persona — so a guard keyed on
the persona would silently skip a whole class of dispatch. Hence the rule this amendment is named for:
**classify the claim, never the actor.** A brief carrying no premise is not checked and not blocked,
whoever is being dispatched; a brief carrying one is checked, whoever is being dispatched. The
general-purpose blind spot closes as a side effect rather than as a special case.

### The rejected options that are still live

**1 · Verify against `git -C "$cwd"`.** This was the pre-implementation review's own proposal and **the
owner overruled it, correctly**. On the night this exists for, `cwd` was `tadeumendonca-skills` and the
citations were `tadeumendonca-io`'s: a `cwd`-anchored guard catches the easy case and misses the real
one. The repository is resolved from the **cited path** instead. Recorded because it is the cheaper
implementation and will be proposed again — the reason it is wrong is not visible from inside it.

**2 · Detect an *intake* dispatch and check only those.** Rejected: `product-lead` is dispatched for
intake, for queue ordering and for a truth pass with the same `subagent_type` every time, so the only
separator is prose. A hook that fired on every `product-lead` dispatch would be disabled within a week.

**3 · Verify `file:line` citations too.** Rejected, and the exclusion is **declared** — in the deny text
and in the script's header — rather than left silent. Whether a file says what a brief claims it says is
prose-reading; a guard reaching for it fails open on the hard half and produces confident nonsense on
the rest. **A control that catches half and names the half is worth more than one that reaches for
everything and cannot say what it missed.** Passing this guard means the *tree* is what the brief says
and nothing about whether the lines are.

**4 · Warn instead of deny.** Rejected on the owner's decision: a warning at dispatch time is another
end-of-turn report nobody acts on, and the whole value here is that the brief never runs.

### Consequences still being paid

- **A false positive blocks a dispatch**, which is the expensive direction, so every ambiguity resolves
  toward allowing: a claim passes if it holds in **any** resolved candidate repository. The named false
  positives are in the script's header rather than only here — chiefly a brief citing a **historical**
  commit after one of the trigger keywords, which the guard cannot distinguish from a premise.
- **The candidate set is a heuristic and is the weakest part.** The payload carries `cwd` and nothing
  else about the workspace — measured: its top-level keys are `cwd`, `hook_event_name`,
  `permission_mode`, `prompt_id`, `session_id`, `tool_input`, `tool_name`, `tool_use_id`,
  `transcript_path`, with no additional-working-directory field. So candidates are `cwd`'s repository
  plus sibling git trees, deduped **per repository** rather than per directory (this workspace carries
  ~22 linked worktrees of one repo; without the dedupe any stale one could vouch for a premise nobody
  measured). When the heuristic fails it falls back to `cwd` and the guard gets **quieter**, never
  louder — a named false-negative, deliberately chosen over its opposite.
- **It says nothing about a stale Issue**, and that limit is the sharper one. `product-lead`
  independently found that three Issues in one session described work already done. That is not a
  dispatch failure — those Issues were stale before any dispatch existed — so it is a different
  mechanism at a different moment (pick-up, against the Issue) and is deliberately **not** absorbed
  into this one.
- **It reads committed state only.** A premise measured against a tree with uncommitted changes passes.

### Correction (2026-08-26, at the merge gate) — the claim grammar was wrong, and the corpus was there all along

**The first consequence above said the false-positive rate was unmeasurable against briefs not yet
written. That was wrong, and the way it was wrong is the part worth keeping.** It was measurable
against **859 briefs already written** — this repo's own transcripts — and nobody, including the
review that specified this guard and the owner who ratified the deny, reached for them. The gate did,
by transplanting the guard's own scanner verbatim over the corpus:

| grammar | briefs evaluated | ≥2 distinct SHAs = at least one denial guaranteed |
|---|---|---|
| bare SHA **and** ref-and-SHA (as shipped at `312a14d`) | 354 / 859 = **41.2%** | 69 = **8.0%** |
| ref-and-SHA only | 11 = 1.3% | 0 = 0.0% |
| ref-and-SHA, **ref must resolve** in the target repository | 9 = **1.0%** | **0** |

**This was a design fault, not a rate to tune,** and the owner said so of his own decision: two
distinct SHAs cannot both be HEAD, so every brief in that 8.0% was guaranteed a denial whatever the
tree was — and carrying two SHAs is *correct briefing*, because a review names a merge-base and a
head. Confirmed live: *"Review PR 331 against its merge-base commit `f1de137`"* was denied.

**The decision, and it is not a mitigation of the deny — it is a correction of what a premise IS.**
A bare SHA is a **reference** (a merge-base, a PR head, a quoted verdict marker, a historical commit).
A **premise** says where you are standing: a ref and the commit it is at, together. The deny stays;
the grammar loses bare SHAs entirely. Two further findings from the same measurement:

- **The ref must RESOLVE, which is a repository fact rather than a lexical guess.** Ref-and-SHA alone
  still matched 2 of its 11 on sentence boundaries — *"…of awk. At `55ecf4c`…"*, *"…head 5 at
  `6259e53`…"*. Requiring the token to be a ref in the target repository drops both and keeps all 9
  real stamps, including both instances of the incident.
- **The ref KIND decides what the stamp asserts.** A local branch asserts where the tree *is* (branch
  and HEAD both checked — the incident's shape). A remote-tracking ref asserts only where that ref
  points, and HEAD is deliberately **not** checked: 4 of the 9 real stamps are *"on `origin/main` at
  `<sha>`"* issued from a feature branch, which is correct briefing that a HEAD requirement would have
  denied every time.

**Two measured holes in the attribution, both closed here, both the same defect at a wider scale than
the one already recorded above.** The consequence about `~22` linked worktrees was right and
incomplete: (1) a **second clone** of the same repository was measured vouching for a premise false of
the tree being worked, because `git worktree list` is per-clone — the key is now `remote.origin.url`
where there is one; (2) a bare `README.md` citation resolved to **seven** repositories, four of them
unrelated forks, so under pass-if-any a claim needed to be true of one in seven. **A citation present
in more than one repository distinguishes nothing and is now dropped**, and where the distinguishing
citations name two or more repositories the guard **fails open** rather than guessing — a
cross-repository brief is now a declared blind spot instead of a coin toss reported as a control.

**Rejected here, and recorded because the owner put both on the table.** *Observe-only mode*
(record what would have been denied, promote the second slice to first): rejected because the whole
reason this ranked first was that it is **preventive**, and the corpus answered the question
observe-only would have been collecting data to answer — the data already existed. *This layer cannot
carry it*: rejected because the narrowed grammar catches the incident with zero guaranteed denials
across 859 real briefs, which is the evidence that the layer can.

**What this correction costs, stated so it is not read as a free win.** Coverage drops from 41.2% of
briefs to 1.0%. Most dispatches are now unchecked, and every false-negative class above is larger than
it was. That is the intended direction — a control that blocks correct briefing is not a control — but
it means this guard catches one specific, cheaply-falsifiable mistake and nothing else, which is what
the section heading in this document has said about every control here from the start.

## Amendment (2026-08-28) — a control whose act belongs to the forge: what closes an Issue is not a tool call (#337)

**Deciders:** the owner ratifies; written by `agents-lead` (authorship split by domain — this is loop
machinery). Measurement, design and mutation-check by the same, in the slice that shipped it.

**The question is this document's standing one — *which layer carries a control, and can that layer hold
it?* — and this time the honest answer for the dominant route is "none of them".** Three Issues closed
with the invocable half they promised unbuilt (#313, twice; #326; #431 in the sibling repo), and every
instance surfaced because the owner asked. The control wanted is *an Issue does not reach `closed` while
the artifact it promised is missing*.

### The measurement that decides the layer

**Every Issue this loop closed in the week to 2026-08-28 closed by a closing keyword in a merged PR
body** — `Closes #313's slice 1` (PR #345), and the same shape in #333, #340, #347, #348, #349.
The state transition is executed **by GitHub, on merge**. There is no tool call, so there is no
`PreToolUse` payload, so **no hook in this harness observes it and no entry in any permissions layer can
deny it.** This is a **sixth** reason a control cannot live in the floor — the four this document's
*Which layer carries a control* section lists, plus the fifth #319 added (*the permissions syntax has no
caller dimension*) — and it is different in kind from all five: not *the syntax has no dimension for
it*, but **the act is not performed by anything the harness mediates**. Every earlier reason assumes
there is a tool call to match and argues about what the match can see; this one removes the tool call.

**Still literally true about the CLOSE, and operationally superseded about what follows from it
(2026-08-30, #363).** The close is not mediated and no layer can deny it — that is unchanged. What was
wrong was the inference everyone drew from it, here and in three other files: that the *failure* was
therefore unpreventable. The **merge** that causes the close is mediated, and the 2026-08-30 amendment
below builds the refusal there. **The generalisation to carry forward is that this sixth reason bounds
the ACT it names and not the outcome that act produces** — before citing it, ask whether something one
step upstream is mediated.

**What that measurement is evidence for, and what it must never be reused to argue.** It is read off
**PR bodies**, so it proves the keyword was **present**, not that the keyword is what fired — the
timeline, which would prove that, is unreadable from inside this harness (`gh api` is denied by the
global floor). The claim is worded to what the artifact supports, and the design needs **one instance**
of a keyword close rather than a share: dominance sets **priority**, never feasibility. The residual
error also points the safe way — any close that was in fact manual makes the **preventable** share
**larger** than measured, so the shipped design is correct under the error too. **That asymmetry is not
a licence to run the number backwards.** It supports building the detector; it does **not** support a
later argument that the manual route is rare enough to drop the refusal arm. Re-measure before claiming
the reverse.

**What that leaves is a two-surface split, and the split is forced rather than designed:**

| route | share, measured | surface | what it can do |
|---|---|---|---|
| closing keyword on merge | all of the last week's closes | `Stop` hook | **detect**, one turn late — ~~and nothing else~~ · **see the row below, added 2026-08-30** |
| the same route, at the MERGE that causes it | same | `PreToolUse` on `Bash`, rule 7d (#363) | **refuse**, one step upstream — a different predicate, see the 2026-08-30 amendment |
| `gh issue close` by hand | none in that window | `PreToolUse` on `Bash` | **refuse** |

Both `Stop` and the hand-close refusal are `hooks/scripts/closure-artifact-guard.sh`, registered twice;
the middle row is `permission-guard.sh` and is a **different obligation over a different artifact**, not
a second implementation of this one. The hand-close refusal is kept although its route is currently
unused: ~~it is the only refusal surface that exists at all~~ — **struck 2026-08-30 (#363), and it is
the clause `README.md` strikes as false in the same diff; leaving it live here, in the canonical
layer-analysis record, is the drift this document exists to prevent.** It is the only refusal surface
for **this** predicate (a declared `invocable:` promise); it stopped being the only refusal surface
reaching the keyword route. The *close with a criterion* rite in `/agents-configuration` is still a real
user of it.

### The rejected option that is still live, and why it was refused

**A PR → Issue resolution route** — read the closing keyword out of the PR body at merge time and check
the Issue's promise then. It is the only surface that could **prevent** the dominant failure, and
`--body-file` does not hide it the way it hides comment text: the *path* is in the command string and
the file is readable. It was **not built, on the owner's decision**, and the reason is #336's
measurement: nothing forces a `loop` PR to reference its Issue, so the route's blind spot is exactly the
PR that skipped the reference — a control whose coverage is decided by the author of the thing being
controlled.

**~~It was not built~~ — a route of this shape WAS built on 2026-08-30 (#363), and the difference is
worth stating precisely, because "it was not built" one page above the amendment that ships it is the
drift class this document names most.** What #363 built is **not** this option: it does not read the
keyword out of the PR body (it reads the forge's own resolved `closingIssuesReferences`, so the regex
blind spot disappears), and it does not check *the Issue's promise* (it checks that the gate's
head-scoped verdict **declares** the close, so the `invocable:` predicate is never consulted). **The
objection above therefore does not transfer and was never answered — it was side-stepped by changing
the predicate.** The blind spot #336 measured is real and survives in a different shape: a PR that
references no Issue produces an empty resolved set, which rule 7d passes silently, exactly as this
paragraph predicts. Read this section as *the promise-checking form of the route is still refused* and
the 2026-08-30 amendment as *a consistency-checking form of it is in force*.

**Deriving the promise from the Issue's prose** was rejected on a measurement rather than a preference.
Over the twenty most recently closed Issues here, the tightest grammar worth trying (a backticked span
that is exactly `/name` or `/plugin:name`) extracted **25 tokens, of which 11 did not resolve and every
one of the 11 was a false positive** — `/architecture` seven times (a live command in the sibling repo),
`/skill-doctor` (a rejected proposal), and two issue numbers inside backticks. **Zero true positives at
head.** Eleven reds on honest work to catch nothing is the shape this document names repeatedly: a gate
that reddens on correct work is loosened until it verifies nothing.

### The decision, as it binds

**The promise is DECLARED, not inferred.** An `invocable:` line at column 0 of the Issue body, read
literally by the guard, written at intake by instruction, with `none` as a first-class value and
`invocable-waived: <entry> <reason>` as the recorded-narrowing escape. The field label is a **parsing
contract** in the same sense `docs/blueprint-registry.md`'s field labels are, and
`hooks/scripts/inventory-counts.test.sh` asserts that the guard that reads it, the preload that states
the rule and the intake command that writes it all spell it.

### Consequences, including the one that makes this weaker than it reads

**Nothing forces the declaration.** An Issue that declares nothing is invisible to both arms, and the
only thing that puts the line there is an instruction in two documents. Applied to the three founding
cases: it would have caught **#313 and #431** had their intake written the line, and **not #326 at
all** — what #326 failed to create was labels and milestones in the *tracker*, and this control resolves
artifacts in a *tree*. **Two of three, conditionally**, is the honest claim.

It resolves **existence and never behaviour**; an empty file passes. It **fails open** on a missing
`gh`, an API error or an unreadable body, so a silence from it can mean *checked and clean* or *could
not check* — the same trade every guard here makes, in the direction that misleads. The `Stop` arm costs
one API call per turn end and debounces per session per Issue, which means **its silence and its repair
look identical from outside**. And the scope is deliberately narrow: Issues promising an **invocable**
artifact, not every Issue type — a `content` Issue closes on a published article and a record Issue on a
merged record, and neither is this control's business.

## Amendment (2026-08-29) — the layer that can refuse a SESSION, and why the generalisation of #341 is not what it looked like (#342)

**Decision: a `UserPromptSubmit` hook refuses to process anything while a precondition of the
registered guard set is absent.** Carried by `hooks/scripts/preflight.sh`, registered twice — the
refusal on `UserPromptSubmit`, the notice on `SessionStart`. The owner ruled it **blocking**, in one
word — *«bloqueante»* — with the cost named to him first: a missing dependency and no work happens
until it is fixed.

### The problem #341 left open, and the shape it turned out to have

The 2026-08-28 amendment made the merge floor fail **closed** and said in as many words that *"the
generalisation across the rest of the guard set is #342 and is deliberately NOT taken here."* Taking
it now, the generalisation is **not** *"make the other rules fail closed too"*, and that reframing is
the substance of this amendment.

The measured cause is upstream of every rule. `permission-guard.sh` reads its payload with `jq` and
exits on an empty read, so **one missing binary disables every rule in the file before rule 1 is
reached** — the merge floor's own new fail-closed branch included. Flipping arms inside a guard that
never runs buys nothing. The failure is not per-rule; it is per-**session**, and the only control that
can address a per-session failure is one that refuses the session.

### Which layer can hold it — the standing question, and the answer was a measurement

The Issue asks for a *startup* preflight. **`SessionStart` cannot deny.** Measured against the shipped
bundle (Claude Code 2.1.251,
`/opt/homebrew/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe`):

| event | what the bundle does with a hook that wants to stop things |
|---|---|
| `SessionStart` | a hook's `blockingError` is **pushed into the session's context messages** — it becomes text. The event sits in the bundle's own non-blocking set, alongside `Notification`, `SessionEnd`, `Setup`, `SubagentStart`, `PostToolUseFailure`. |
| `UserPromptSubmit` | blocks for real: `getUserPromptSubmitHookBlockingMessage`, `"UserPromptSubmit operation blocked by hook:"`, `"blocked by a UserPromptSubmit hook"`, `"Prompt blocked: the UserPromptSubmit hooks did not run over the submitted text."` |

This agrees with `README.md`'s own event table, which already published *denies? no* for
`SessionStart`; the bundle read is the evidence behind that row rather than a second opinion. So the
control splits by capability, not by preference: **the block lives where blocking works, the notice
lives where a human reads it before typing.** Wiring it the other way round would have produced the
exact defect that section of the README exists to name — a control on an observe-only event, which
looks like enforcement and is not, and stays invisible until somebody tests it.

**A property that was not asked for and is worth more than the door check.** `UserPromptSubmit`
re-evaluates every turn, so a degradation appearing **mid-session** — `PATH` changed, a binary
removed, a plugin update that lands a hook without its execute bit — is caught at the next prompt. A
literal door check could not see any of that.

### What blocks, and the two things that deliberately do not

Blocking: an interpreter a registered hook reaches for is missing from `PATH`; a script `hooks.json`
registers is absent or without its execute bit; a **headless** session running with the static deny
layer off (`permission_mode` = `bypassPermissions` **and** prompt `source` = `sdk`, both read straight
off the payload — the bundle documents `sdk` as *"non-interactive entrypoint (`-p` / Agent SDK)"*).

**Reported, not blocked — the same bypass with a human present.** Blocking there would confiscate the
one mode a headless worker fleet needs, and the person who would read the warning is the person who
typed the flag that produced it.

**Reported by another mechanism, and deliberately not made blocking here — the installed-versus-merged
version drift**, which the Issue proposed as the third precondition. Measured at authoring time: the
installed marketplace build was `1.1.35` against a source of `1.1.43`, and this repo publishes a
release on **every** merge to `main`, so the install lagging the source is the **normal** state rather
than the exceptional one. **A blocking control that fires routinely is not a stricter control; it is a
control people learn to route around**, and a routed-around floor is worse than an honest warning.
`session-plugin-version.sh` already reports this, and one fact deserves one reader.

**That distinction is the general rule this amendment adds to the layer question**: before placing a
control, ask not only *can this layer hold it* but *how often will it fire, and does the answer make
holding it survivable*. A control whose trigger refills from ordinary work fails that test even when
the layer passes.

### The requirement set is derived, never listed

The preflight reads `hooks.json` for the scripts it registers, and those scripts for the
`command -v <x>` they reach for. Adding a hook that **declares** a new binary with `command -v` makes
that binary required with no edit to the preflight. **A hook that reaches for one without declaring it
that way — a bare call, `hash`, `type`, or `command -v "$var"` — contributes no requirement**, and that
is the derivation's named blind spot: it reads a declaration, not a call graph. The owner's instruction was explicit — a written-down list is a second
source of truth drifting away from the guards it protects — and the suite asserts the derivation by
inventing a dependency in a scratch plugin and requiring the refusal to name a binary whose name
appears nowhere in `preflight.sh`.

### It fails CLOSED on its own bootstrap dependencies — alone in this harness

`grep`, `awk` and `sort` are what the derivation itself needs. Without them the script cannot tell a
healthy harness from an inert one, so it refuses rather than reporting clean. This is the only place
here that fails closed on its own dependency, and it is defensible **because** it is the only one: it
denies a prompt, never an irreversible act, and the repair is a `PATH` fix outside the session.

**Its own first draft got this wrong and its own suite caught it.** The draft resolved its directory
with `dirname` and read stdin with `cat`; on a `PATH` without coreutils it died at `dirname` and
exited 0 — **failing open, reproducing the exact defect it exists to remove, inside the fix for it.**
Payload parsing, stdin and directory resolution are now bash builtins. Recorded rather than quietly
fixed, because it is the sharpest available evidence for why a dependency check must not depend on
what it checks.

### Consequences still being paid

- **A false positive stops all work.** The owner accepted this. It is survivable only because every
  blocking class has a repair **outside** the session; no in-session escape hatch exists, and none is
  offered — an env-var bypass reachable only by relaunching costs the same as the fix and teaches the
  wrong habit.
- **A binary on `PATH` is not an authenticated one.** Auth expires mid-session and a preflight cannot
  see it. #341's fix is **not** subsumed and must not be: that failure arrives at the irreversible act,
  hours after this check passed.
- **It cannot observe whether a deny list was LOADED.** A hook receives a payload, not the effective
  permission set. `permission_mode` is the closest observable, which is why classes C and D read it
  rather than reading `settings.json` — the file's presence answers a different question from the one
  that matters.
- **It does not fire for a dispatched subagent.** `UserPromptSubmit` is a main-thread event.
- **If `hooks.json` never registered at all — the container case nobody has measured — this never runs,
  and its silence is indistinguishable from a clean pass.** Unfixable from inside a hook, by
  construction, and named rather than left to be discovered.

### Rejected here

**1 · A `SessionStart` block.** Not a preference — measured impossible, above.

**2 · Blocking on version drift.** Rejected on the measurement above: it is the normal state, so the
control would refuse nearly every session.

**3 · Asserting `settings.json`'s `deny` array from disk.** Rejected as the wrong instrument. The file
existing does not mean it was loaded, and a repo that legitimately has no such file — every consuming
repo — would be refused. The payload's `permission_mode` answers the question the file only gestures at.

**4 · An acknowledgement escape (`HARNESS_PREFLIGHT_BYPASS=…`).** Rejected: it is set outside the
session, so it costs the same as the repair while converting a floor into a habit.

### What is NOT decided here, and belongs to whoever builds the container

Whether the plugin's `hooks.json` registers at all in a headless container run, and whether a
tool-trust flag bypasses a project `settings.json` that IS loaded. Both were named in the Issue as
load-bearing and unverified, and both remain so — the first is unmeasurable from inside a hook, and
the second could not be read out of the bundle before the auto-mode classifier refused two of the
greps that would have settled it. **If hooks do not load in a container, every floor in this repo is
gone at once and this control with it**, which is the worst possible resolution and the one worth
measuring before an image is built.

## Amendment (2026-08-29) — MCP is a control surface, and it was held by a single layer that holds by ABSENCE (#355)

**Decided by:** the owner. Four statements, and the later ones narrow the earlier ones — recorded in
order because the design changed under each: *«precisamos fazer o setup do nosso ambiente com chrome
devtools»* · *«ele é a melhor ferramenta para fazermos review exploratorio do site automatizado»* ·
***«varrer como uma regressao geral alto nivel da aplicacao integrada rodando»*** ·
***«onde issues de layout, wording, coisas de revisao, podem ser pegas em uma ultima instancia»***.
**Written by:** `agents-lead`, per the domain split (#223) — this is machinery.

**The word *exploratory* did not survive, and the correction is load-bearing.** An exploration decides
where to look and therefore needs a bound on its own scope; a **regression sweep** must instead COVER
what exists, which turns the hard question from *"how does it stop"* into *"how is coverage proved"*.
The first framing produced a design with a stated page budget. The second replaced it with a derived
route list and two counts. Recorded rather than quietly rewritten, because a reader of the shipped
brief will find no budget and should know it was removed on purpose.

### What was asked, and the larger thing it uncovered

The ask was a browser for a high-level regression sweep of the running application. The intake for #355 had
already measured that no persona holds one: every brief's `tools:` list is `Read`/`Grep`/`Glob`/`Bash`
and friends, with zero `mcp__*`, and neither repository carries a `.mcp.json`.

**The second half of that measurement was wrong in a way that matters, and this amendment exists as
much for the correction as for the capability.** "No `.mcp.json` in either repo" is true and is not the
same claim as "no MCP servers are configured". Measured 2026-08-29, `~/.claude.json` carries
**project-scoped** MCP servers for the consumer repository — `linkedin` (with a credential in `env`)
and `instagram-collections` — declared in the user's own configuration rather than in any tracked file.
A subagent dispatched there **with no `tools:` restriction** enumerated its own MCP surface and named
roughly **400 tools**, including:

```
mcp__linkedin__send_message            mcp__linkedin__connect_with_person
mcp__claude_ai_Gmail__send_message     mcp__claude_ai_Gmail__trash_thread
mcp__claude_ai_Google_Drive__share_file
mcp__claude_ai_Google_Calendar__delete_event
```

Every one of those is irreversible, credentialed, and lands in public in the owner's name. **This
exposure predates the browser and predates this amendment; what changed is that somebody measured it.**

### The measurements, because every claim here is one

Probe against control, one variable at a time. `claude -p`, a dependency-free stdio MCP server
returning a nonce, and a dispatched subagent asked to call it.

| # | server declared in | subagent `tools:` | result |
|---|---|---|---|
| A | project `.mcp.json` | `Read, Grep, Glob` | `TOOL-NOT-AVAILABLE` |
| B | project `.mcp.json` | `+ mcp__nonceprobe__nonce` | nonce returned |
| C | **plugin** `.mcp.json` | *(no `tools:` line — inherits)* | nonce returned |
| D | plugin `.mcp.json` | `+ mcp__plugin_<plugin>_<server>` *(server-scoped)* | nonce returned |
| E | plugin `.mcp.json` | `Read` only | `TOOL-NOT-AVAILABLE` |
| F | project `.mcp.json`, agent shipped by the **plugin** | `+ mcp__nonceprobe__nonce` | nonce returned |

**A dispatched subagent does reach a project-declared MCP server**, which was the load-bearing premise
of the whole change — if it did not, this buys nothing and must not ship. **The `tools:` list is the
gate**, and it is tight: an agent granted exactly one MCP entry, dispatched in the repository where the
~400 tools live, enumerated **one**.

**Plugin-scoped servers namespace differently** — `mcp__plugin_<plugin>_<server>__<tool>` — and both
spellings resolve from a plugin-shipped brief (D and F), which is why every artifact here matches both.

### The fork: plugin-level, and what it gave up

**Chosen: the server is declared by the PLUGIN** (`.mcp.json` at the plugin root), not per consuming
repository.

*Why.* The consumer of this capability is a **persona**, and personas ship in the plugin. The grant
(`tools:` in `agents/product-lead.md`), the guard (`hooks/scripts/mcp-guard.sh`) and the declaration
must all agree on one string. Put them in one repository and a gate can assert they agree — which it
now does. Split them across two and nothing can: the failure when a brief names a server the repository
does not declare is **silent**, the persona simply has no browser, and this harness's named failure
shape is a control that reads as installed and is inert.

*What it gave up, stated rather than minimised:*

- **`tadeumendonca-skills` carries a browser it has no site for.** Measured: declaring the server costs
  one lazily-spawned stdio process and **no Chrome** — a session in this repository enumerated all 29
  tools with zero browser processes running. Chrome launches on first tool call, never at session start.
- **Every marketplace consumer inherits the declaration.** Mitigated by making the origin bound an
  environment variable with a **fail-closed default** (`${HARNESS_SWEEP_ORIGIN:-http://127.0.0.1:9/*}`
  — port 9 is discard). Measured: `${VAR:-default}` expands in a plugin `.mcp.json`, the default applies
  when unset and is overridden when set. A consumer who installs this and configures nothing gets a
  browser that can reach nothing. **This also keeps the plugin project-agnostic**, which is a hard
  principle here — no real domain appears in a tracked file.
- **The rejected option is still live and cheap to take:** a consuming repository may declare its own
  `chrome-devtools` server with its own bound, and the guard and brief both match the bare spelling
  deliberately so that path works without touching the plugin.

### Which layer can carry the control — the standing question, and the answer moved

The `tools:` frontmatter is a real gate (probes A and E) but it is **one layer, and it holds by
absence**: no brief says *"and no MCP"*; each names a tool list and MCP falls outside it. Delete that
one line from any brief and the persona inherits everything above. A control with one layer and no
backstop is the class this record exists to refuse.

| layer | can it hold *"a subagent reaches only the servers its brief was granted"*? |
|---|---|
| `settings.json` `deny` | **no** — a tool-name matcher with no notion of *who* is asking, and the orchestrator must keep its servers |
| `permission-guard.sh` | **no** — registered on the `Bash` matcher, reads `.tool_input.command`, which an MCP call does not have |
| the brief's `tools:` list | **yes, and it is the only layer that held until now** — single, and holds by absence |
| a `PreToolUse` hook on `mcp__.*` | **yes — measured, and this was the open question** |

The open question was whether *any* hook can observe an MCP call. It can. A probe hook registered on
matcher `mcp__.*` fired on a subagent's MCP tool call, received the fully-namespaced name in
`.tool_name`, and its `deny` was honoured — the subagent reported back verbatim:

```
RAW: HOOK-DENIED-MCP tool_name=mcp__plugin_probe-plug_chrome-devtools__nonce
```

**So `hooks/scripts/mcp-guard.sh` is built**, deny-by-default and allow-by-persona, the same polarity as
rule 5e and for the reason this record already states as *absent is not a state*: a persona added later,
or a connector installed later, defaults to DENY and somebody decides by name. The inverse — listing the
forbidden servers — would have to grow every time the owner installs a connector and would fail open in
between.

**The orchestrator is deliberately untouched.** `agent_type` is empty there and the guard exits without
a decision.

**State the reason precisely, because the obvious phrasing is wrong and was caught at the gate.** It is
**not** that the act is smaller: `mcp__linkedin__send_message` is as irreversible and as public as the
merge that rule 7c was made to fail *closed* over, and this guard is the only rule in this file that
**fails open** on an act of that class. The distinguishing argument is different and it is the only one
that holds — **the orchestrator IS the owner's own session.** A subagent is a delegate acting on a brief
nobody reads in real time; the main context is the human at the keyboard, and denying it a connector he
installed and invokes deliberately is not a floor, it is a malfunction. Rule 5e's whole shape rests on
the same distinction, and the routing-class amendment (2026-08-23) is the precedent for calling it what
it is rather than dressing it as a safety argument.

**The residual stands as a residual:** the most capable context in the loop has no MCP control at all,
and the reason is that it is not an agent boundary to enforce.

### Who gets the browser, and why nobody else does

**`product-lead`, alone.** Its object is what a reader meets on the consumer site, its scope boundary is
already that repository, and it **cannot post** — rule 5e denies it `gh pr comment` / `gh issue comment`
/ `gh issue create` — so a sweep finding reaches a PR only by being quoted in the gate's verdict. A
sweep therefore cannot become the gate's artifact by accident. That is a property of containment that
already existed, not something this change added.

**The owner named the same persona independently** — *«potencialmente a melhor pessoa para isso fosse o
product lead»* — and gave the reason that constrains the rest of the design: ***«ele tem a visao de
proposito conectada a engenharia»***. It holds the purpose-view *with* enough engineering to know what a
failed request was serving.

Refused, each for a stated reason rather than by omission: **`quality-assurance`** (it is the gate; a
browser there makes a taste-bearing observation into a merge blocker, which #355's intake
settled against) · **`developer`** (authorship bias, and a builder's browser becomes a scripted check,
which is a regression suite wearing the wrong name) · **`tech-lead`** (performance tracing is arguably
its object; not this slice) · **`content-writer` / `content-reviewer`** (they judge prose, pre-publication)
· **`agents-lead`** (its object is the machinery, not the site).

### One persona holds BOTH halves, and the split was refused on the owner's reason

The rite has a **mechanical** half (renders · no console errors · no failed requests · no missing images
· the PDF downloads · both locales · phone and desktop) whose findings are **evidence**, and a
**judgement** half (does the layout read right, does the copy read right) whose findings are **taste plus
observation** and become Issues for the next iteration. **They are reported as two separate sections,
always** — merging them makes the first invisible inside the second, and the first is the one that means
someone has to act tonight.

**The mechanical half is not a product judgement, so factoring it to another persona looked tidy. It was
refused**: it would separate *seeing what broke* from *knowing what it was for*, which is precisely the
pairing the owner named. *The cost of not splitting, stated:* the sweeper reads console and network
output outside its native competence and may under-read noise a builder would recognise. **The
compensation is that the mechanical half is a checklist with a count, not an opinion** — per route the
evidence is present or it is not.

### Coverage is DERIVED, and that is what makes the sweep checkable

The route list is not typed into the brief. It is read from the consumer's own generator —
`apps/fed/scripts/routes.mjs`, whose `localizedRoutes()` the sitemap and the prerender already consume,
so a route that exists is in it by construction. Measured 2026-08-29: **18** targets across both
locales, `{ locale, route, url }` each. **The brief carries the command, not the number.**

A hardcoded list rots **silently** — it covers eight of nine and reports green. The report therefore
leads with `routes emitted: N` / `routes visited: N`, and those being equal *is* the coverage claim.

**Weighting toward the iteration is derivable and must not become scoping.** The owner: *«sendo ou nao
parte de itens desenvolvidos no sprint atual, porem obviamente dando maior enfase as funcionalidades
impactadas no sprint»*. Every emitted route gets the mechanical pass; weighting decides only where the
judgement half spends attention. **A sweep that quietly skips untouched routes reports green over the
half nobody looked at, and the untouched half is where a regression from an unrelated change lands.**

### The judgement half has one ruler and openly lacks the other

**Wording has a ruler**: `published-voice`, the same skill `content-writer` drafts against and
`content-reviewer` judges against, with the distinction those personas already use — a finding that can
**quote a clause** is a finding, one that cannot is a preference. Reused rather than reinvented.

**Layout has none, and the brief says so** rather than inventing one. There is no document defining what
"reads right" means at 390px, so a layout finding is observation labelled as taste, carrying its weight
through being specific and reproducible. **A layout ruler invented at the moment it was needed would be
the failure this record exists to refuse**, so the absence is recorded as an absence.

### The sweep's own failure must be LOUD — the fail-open shape, arriving unwatched

The rite runs at iteration close, which is exactly when nobody is watching, and a broken sweep's natural
output is a clean-looking report. So the brief makes **FAILED** the required verdict whenever the route
generator did not run or returned zero, the browser never started, `routes visited < routes emitted` for
any reason, or the report could not be written. **This is an instruction in a brief and nothing enforces
it** — no hook observes whether a dispatch produced a report at all, and that is named here rather than
implied by the two counts.

### Why this rite is the LAST sieve, mechanically

Merge is deploy under `trunk-single-env`, and the held-draft state holds an **article** — a `draft` fact
in front matter takes a post out of the index, sitemap, prerender and cards. **A layout change to a page
has no held state and nothing to preview.** The owner's recorded rule for a page revision is that it is
validated in production, *«pois preciso verificar layout junto não apenas texto»*.

**The evidence is this session, twice.** A generated banner shipped off-centre with every containment
assertion holding and the suite green; he found it on his phone. He found the vertical defect the same
way after the fix. **Two layout defects, zero gates able to see either.**

### What a persona with this can reach that it could not before — bounded, and the bounds measured

`chrome-devtools-mcp@1.8.0`, version-pinned. It is **not** the `claude-in-chrome` integration the
session already has: that is extension-based, session-scoped and not dispatchable, which is precisely
why it could not serve this. They do not conflict — one is a `--chrome` session flag, the other an MCP
server — but only one of them a subagent can reach.

**The profile is the finding that decides the class.** By default this server drives a **persistent**
profile at `$HOME/.cache/chrome-devtools-mcp/chrome-profile`, and `--autoConnect` / `--browserUrl` /
`--wsEndpoint` would attach it to the owner's **running** Chrome — his cookies, his sessions, his
logged-in accounts. **None of those is used.** The server runs `--isolated`, a temporary user-data-dir
discarded when the browser closes, so it holds no session of his at any point. That is also the correct
lens rather than merely the safe one: **the reader this site is for is not logged in as the owner.**

**The origin bound is enforced by Chrome, not by instruction** — `--allowedUrlPattern`, which needs
Chrome 149+; the machine runs 151. Measured, probe and control on the real browser:

```
new_page https://www.iana.org/   -> Error: Navigation to https://www.iana.org/ is blocked by blocklist/allowlist rules
new_page https://example.com/    -> Page loaded successfully. Title: "Example Domain"
```

Telemetry is off in the same line (`--no-usage-statistics`, `--no-performance-crux`), because the
defaults send usage data to Google and traced URLs to the CrUX API.

### The second-order effect this dispatch existed to catch: a browser is an EGRESS route

**Rule 5e denies `product-lead` public surfaces because it reads the private positioning layer**, and a
paraphrase of that material into a public surface is not revertible. **A browser is a route to the
outside that a read-only grant did not previously include** — a URL is a channel, and a navigation
carries whatever is in it. Granting a browser to precisely the persona 5e contains is therefore not a
neutral addition, and it would have been one had nobody asked.

Two narrowings, and **neither closes it**:

1. **The origin bound** means anything sendable goes to the owner's **own** domain rather than a third
   party — materially different from posting to LinkedIn, and still not nothing: a query string lands in
   his CloudFront logs.
2. **The grant is a NAMED SUBSET of the server's tools, not the server.** `mcp-guard.sh` denies
   `evaluate_script`, `fill`, `fill_form`, `type_text`, `upload_file`, `handle_dialog` and `drag` — the
   input-carrying tools, none of which is needed to look at a page, and `evaluate_script` above all,
   since arbitrary JS can compose and issue its own requests. What remains is a viewer.

**This is a narrowing the `tools:` frontmatter cannot express** — it grants whole servers only — which
is a second, independent reason the hook layer had to hold this control rather than the brief.

**`click` is allowed with its cost stated:** a nav link and the PDF download are unreachable without it,
and a click can submit a form somebody else's markup put on the page. Narrowing, not closure.

### The supply chain of the server itself, and one measured correction

Raised at the merge gate as an advisory: `npx -y chrome-devtools-mcp@1.8.0` is exact-version pinned,
**but has no integrity pin and "cannot run `--ignore-scripts`."** The concern is right and **the second
half of the premise is false, measured** — `npx --ignore-scripts -y chrome-devtools-mcp@1.8.0 --version`
prints `1.8.0`, and the same flag was measured completing a real navigation end to end. It is adopted,
so the install-script surface of the package and its transitive dependencies no longer executes.

**It is asserted at position 0, not by membership, and that distinction is the assertion's whole value.**
`npx` splits its own flags from the package specifier at the first non-flag argument, so a
`--ignore-scripts` that drifts *after* `chrome-devtools-mcp@1.8.0` is handed to the **server** — where it
is an unknown option rather than a protection. Measured: moving it one position past the specifier
reddens the suite; a membership check would have stayed green through exactly that move.

**What is still not closed: the integrity hash.** Exact-version pinning plus npm's prohibition on
republishing a version is what stands in for it. A true integrity pin needs a lockfile, and **this
repository has no `package.json` and no `package-lock.json`** — introducing an npm manifest into a
repo that has none, to hold one dev-time dependency, is a larger change than the risk justifies here
and is recorded as declined rather than overlooked.

### Recording: a tracked file, because the sweeper cannot post

Rule 5e is **unchanged** — no new posting route was opened. The sweep is written to
`docs/iteration-sweep/<iteration>.md` in the consumer repository, reusing the route 5e's own deny
message already prescribes and that `content-reviewer` already uses for its rounds.

**Relaying findings through the orchestrator was refused**, on the ruling already made for the
retrospective: relaying reintroduces the aggregation the isolation exists to prevent.

**This required adding `Write` to `product-lead`, and that is a real widening.** It gained `Write` and
**not** `Edit`, and `Write` refuses a file the persona has not read — so it cannot quietly modify
existing copy — but **nothing scopes that grant to `docs/iteration-sweep/**`.** It is discipline.
`content-reviewer` carries the identical unenforced shape for its own rounds file, so this matches a
ratified precedent rather than inventing a hole; a path-scoping hook on the `Edit|Write` matcher is
buildable (the matcher already exists for `orchestrator-write-guard.sh`) and is deliberately **not** in
this slice.

**Judgement findings become Issues for the next iteration and the OWNER opens them** — *Review does not
open work* is unchanged, and the sweeper names them in the file and in its return.

### Absent or broken: loud, and therefore NOT a preflight requirement

Measured with a deliberately unreachable browser:

```
RAW: Browser was not found at the configured executablePath (/nonexistent/path/to/chrome)
```

The failure is a clear error at the point of use, not a silent degradation, so **Chrome is deliberately
not added to `preflight.sh`'s refusal set.** Adding it would make the preflight refuse on every machine
without Chrome — for a capability one persona uses occasionally — to catch a condition that already
announces itself. The trade is stated the other way round in the rejected column: if a future sweep
becomes load-bearing for a merge decision, that judgement changes, and it should be revisited then.

### Consequences still being paid

- **The one-persona-one-server grant is asserted in three files and gated across two.** The suite checks
  the guard against `hooks.json`'s matcher and against `.mcp.json`'s server name and flags. It does
  **not** check `agents/product-lead.md`'s `tools:` line against either — a brief that drops its MCP
  entry loses the browser silently, and the guard would not notice because the guard only ever denies.
- **Nothing proves the harness still routes `mcp__*` to a `PreToolUse` hook.** That was established by
  live probe, and the suite feeds the guard a payload directly. If the routing regresses, every
  assertion stays green and the backstop is gone. There is no assertion available in-repo that catches
  it; the guard's header says so and this is the second place it is written down.
- **The suite shipped wired into NO CI job, and the build report published it as a gate.** Found at the
  merge gate by `grep -rn "mcp-guard.test.sh" .github/workflows/` returning nothing. It is this
  amendment's own headline finding one layer up — a control that reads as installed and is inert — in
  the layer that was supposed to hold the control. `hooks-test.yml`'s own comments already record two
  prior instances and state the rule this broke: **add the hook and its CI step in the same slice.**
  Fixed here. The `.mcp.json` entry added to `docs-test.yml`'s `paths:` one round earlier is explicitly
  **not** that fix — it satisfies a gate-coverage arm while starting a job containing **zero**
  occurrences of `mcp`, so the glob went green without gating the origin bound.
- **"A sweep finding is advisory" is an instruction, not a mechanism.** `product-lead` holds one
  blocking veto — the truth of a published claim — and nothing prevents a sweep observation being
  dressed as one. The brief states the rule and states that nothing enforces it.
- **`product-lead`'s `Write` is unscoped.** See the recording section above; it matches
  `content-reviewer`'s existing shape, and the fix is a hook nobody has built.
- **Nothing observes that a sweep ran, or that it reported FAILED honestly.** The two counts make a
  short sweep visible *to a reader of the file*; no gate reads the file, and no hook knows the rite was
  due. The iteration-close trigger is a habit, exactly as the loop-first composition rule is.
- **Coverage is derived from the consumer's generator, which couples this rite to a file in the OTHER
  repository.** If `localizedRoutes()` is renamed or moved, the sweep fails loudly (good) but the brief's
  command goes stale (bad), and no gate in either repo asserts the two agree.
- **The ~400-tool exposure is now contained for subagents and untouched for the orchestrator.** That is
  a deliberate scope line, not an oversight, and it means the most capable context in the loop is the
  one with no MCP control at all.

## Amendment (2026-08-30) — the layer that can hold *nothing is admitted automatically*, and the first control here that reaches PREVENTION by ASKING (#365)

**Status:** accepted · **Deciders:** owner (decision), written by `agents-lead` (loop/machinery domain,
#223) · **Issue:** #365, `loop`, boundary

### The rule, and the act it actually guards

The owner's rule, verbatim, 2026-08-30:

> *«review e retrospective geram issues somente ao final do sprint e submetidos a priorizacao do backlog
> do proximo. itens nao podem ser criados dentro do sprint automaticamente sem verificacao HITL.»*

**The guarded act is not *an Issue exists*. It is *an Issue carries a milestone*** — the only observable
that changes a running iteration's contents and its completion bar. Those are different commands and only
the second is a control question. This distinction is the whole amendment: the previous rule (#338) had
guarded the wrong one and made the objectionable act mandatory.

### Which layer can carry it — one candidate, which is rare here

The standing question of this record, answered by measurement rather than by preference:

| layer | can it hold *nothing is admitted automatically*? |
|---|---|
| `.claude/settings.json` / the global floor | **no.** `Bash(gh issue edit:*)` sits in **both** layers, unscoped by caller. Allow/deny entries are command **prefixes** and the issue number sits between `edit` and `--milestone`, so no prefix pattern reaches the flag. |
| `permission-guard.sh` (`PreToolUse`/`Bash`) | **yes** — the flag is in the command string, no lookup, no network, branch-agnostic. |
| a `Stop` hook | detection only, one turn late. |
| `inventory-counts.test.sh` | presence of the written rule, nothing more. |

**And the starting state was worse than the Issue described:** the guard carried **no rule at all** about
`gh issue edit`, so every persona and the orchestrator could assign any milestone to any Issue with a
decision from no layer. Measured 2026-08-30 —
`grep -rn "issue edit" .claude/settings.json ~/.claude/settings.json` returns both allow entries, and
`grep -rn "issue edit" hooks/scripts/permission-guard.sh` returned nothing.

### The observation that made PREVENTION available, and it generalises past this Issue

**#337, #339 and #363 each shipped as detection on the same wall: a guard cannot tell *the human asked
for this* from *I decided it myself*.** That wall is real, and it is **not a property of guards — it is a
property of guards that must KNOW.** A guard permitted to return `permissionDecision: "ask"` does not
have to distinguish the two cases: **the human's answer to the prompt IS the verification the rule
demands.**

Measured against the installed build before relying on it: `ask` is an accepted `PreToolUse` decision
(`permissionDecision:ie(["allow","deny","ask"])`), and `PreToolUse` hooks are consulted even under
`bypassPermissions`, which the bundle states in its own words while describing what bypass skips.

**When this does NOT generalise:** an `ask` needs a prompt surface. That is the whole reason the rule
splits below, and it is the condition to check before reusing this shape.

### The decision, as it binds

1. **`commands/new-issue.md` files with no milestone, for every type.** Composition is the owner's act
   at planning.
2. **`permission-guard.sh` rule 10** matches `gh issue create`/`gh issue edit` carrying `--milestone` or
   `-m`, in every spelling the tool accepts (attached value, the repository flag before the subcommand,
   a `bash -c` payload). **A dispatched persona is DENIED; the orchestrator is ASKED.**
3. **`--remove-milestone` is unmatched.** Taking an item back out is the corrective act the owner
   performed by hand on #357 — what the rule wants to be easy, not what it guards.
4. **#338 is struck, not narrowed**, at every surface that carried it.

### Why #338 loses, and it is a measurement rather than a preference

#338's argument was that a `loop` Issue born outside the pool is invisible to `/autonomy on`. The pool is
`(product OR loop) AND ready AND active-iteration`, and **a `loop` Issue is filed WITHOUT `ready`** — the
owner's transition alone. **The item leaves the pool on the `ready` predicate before the milestone
predicate is consulted.** So the milestone at filing was inert until he acted, and when he acted he was
present. It changed exactly one thing: the running iteration's contents. **It bought nothing and cost the
objection.**

### The split is REACHABILITY, not severity, and that is the load-bearing design call

`ask` returned to a dispatched subagent reaches nobody — there is no prompt surface in that context — so
asking there would trade a deterministic refusal for an **unmeasured** behaviour, on a call that has no
legitimate form anyway. Denying the subagent case removes the only unknown in the mechanism from every
path except the orchestrator's own, which is by construction the session the human is in.

### The measurement that was owed and why it was NOT taken

The intake flagged one unknown: *does an `ask` hang rather than deny where no prompt can be shown?* It is
**not measured**, and the reason is that no path reaches the guarded act unattended. Walked at head, in
both repositories: no script in `hooks/scripts/` assigns a milestone (every `gh issue` call there is a
write path of another kind, and the one `"gh issue edit"` string in `orchestrator-tool-census.sh` is a
classification label, not a call); `commands/autonomy.md` and `commands/sprint-retrospective.md` never assign
one; and the only two files that did — `new-issue.md` and `blueprint.md` — are narrowed by this slice.

~~and the two CI workflows running `anthropics/claude-code-action` install no plugin, so this hook is not
even registered there.~~ **Struck at the merge gate, 2026-08-30, and struck rather than corrected in
place because of WHERE it sat: this is the paragraph that dispenses with a measurement whose failure mode
is a frozen session, so a false sentence inside it is load-bearing in a way the same sentence elsewhere
would not be.** `.github/workflows/claude-code-review.yml` **does** install a plugin — it passes
`plugin_marketplaces: 'https://github.com/anthropics/claude-code.git'` and
`plugins: 'code-review@claude-code-plugins'`. (`claude.yml` installs none; the claim was true of one
workflow and asserted of two.)

**The corrected claim, and the correction is a change of KIND rather than of fact.** No plugin **of this
harness** is installed in either workflow, so `hooks/hooks.json` is never registered and rule 10 does not
run there. That is a fact about **configuration**, which can change with one line in a workflow file —
not the **structural** closure the struck sentence asserted. The conclusion survives; its strength does
not, and the difference is exactly what a future reader would have relied on.

**So this is a conditional, and there are now two conditions to re-check, not one:** the day any
automated path assigns a milestone, **and** the day any workflow installs this repository's own plugin,
the probe is owed before that path ships.

### Rejected here, with the reason

- **A `Stop`-hook detector.** It was the Issue's own expectation and it is the wrong answer *here*: the
  act is visible to a matcher this harness already registers, so installing the weaker control where the
  stronger one fits would be a choice, not a limit.
- **Denying `create --milestone` outright** (the intake's own recommendation, narrowed here). It would
  force one legitimate human act into two commands and buy nothing the prompt does not already buy —
  `ask` makes the admission visible at birth exactly as it does at edit.
- **Removing `Bash(gh issue edit:*)` from the floor.** It would tax every label edit, which is the bulk
  of honest `gh issue edit` traffic, to reach one flag.

### Consequences still being paid

- **Planning fires N prompts**, one per admission. Accepted: planning is owner-present by construction,
  so there is no path where this prompt fires when he is absent and should not have been — the property
  that stops an `ask` training a bypass.
- **It reads a flag, never an intent.** An owner-directed admission and a self-directed one produce the
  identical prompt. That is the design, not a shortfall, but it means the control cannot say afterwards
  which one happened — nothing records *why* a milestone was assigned.
- **The web interface is outside every layer**, correctly: a human clicking in a browser is the
  verification. But it also means the guard's coverage is *this harness*, never *this tracker*.
- **Nothing bounds how many items the owner admits to one iteration.** An over-filled iteration
  reproduces the old unbounded drain inside one milestone, and no mechanism is proposed.
- **The `-m` alternation is a two-character matcher.** It is correct for `gh issue create|edit`, where
  `-m` is `--milestone`, and it would be wrong the day `gh` reassigns that short flag. Nothing detects
  that; the suite asserts today's meaning.

## Amendment (2026-08-30) — the auto-close was called unrefusable, and the act that causes it was already being refused (#363)

**Status:** accepted · **Deciders:** the owner (ratified the intake, «de acordo») · written by `agents-lead`
(loop/machinery domain, ADR-0002's authorship split) · pre-implementation stress test by `agents-lead`,
posted on the Issue as an intake comment.

**Imported obligation, adopted narrowed.** #363 adopts the auto-close half of a foreign harness's
`mr-selection-artifact-gate`. Its evidence class there was `measured`; **its standing here was
`not measured here`, and everything below is local measurement rather than an inherited claim.** The
review half of that mechanism was not re-adopted: rule 7c already binds the gate's verdict to the PR's
current head.

### The premise that was false, and it is the whole amendment

The Issue's own framing — repeated in this repository's README, in the universal preload and in the
blueprint registry — was that *a closing-keyword transition is executed by the forge at merge time, with
no tool call for any `PreToolUse` hook to intercept.* **That is true of the close and false of the
merge.** The merge is a tool call; rule 7c already intercepts it, already resolves the PR, already
fetches the gate's verdict head-scoped, and already fails closed. Measured: `closingIssuesReferences`
returns on the **same** `gh pr view` call rule 7c was already making, so the control costs **zero
additional round-trips**.

**The generalisation worth keeping is not about closing keywords.** An obligation written off as
unreachable because *the event* is not a tool call may still be reachable at *the act that causes the
event*, one step upstream. That is the second time in a week this harness found prevention where it had
recorded only detection — #365 found it by letting a guard **ask** instead of know; this one found it by
moving up one causal step. Neither is a property of guards in general; both are properties of a layer
analysis somebody redid.

### The local defect is NOT the imported obligation's, and building the imported one would have missed it

The import says *delivery was not verified*. **Locally, delivery was verified.** On PR #356 the gate read
the diff, judged Issue #355 undelivered, and prescribed `Closes #355` → `Refs #355` with its reasoning
recorded. The gate was right. **What failed is that the prescription became a PR-body edit and nothing
verified the edit took** — measured live at head, on the merged PR, the body still carries `close #355`
inside the sentence explaining why the keyword must not be used, and the derived field still returns
`[355]`.

So the obligation implemented here has **no judgement in it**: the set of Issues the forge will close
must be a set the gate's verdict at the current head declares. It compares two artifacts. It catches
*the correction that did not hold* — the entire local defect class, three occurrences — and it does not
catch *the gate judging wrongly*, which is stated in the hook's own header rather than left to be
discovered.

### Which layer carries it — and the measurement that ruled out the proposed one

The Issue proposed a **CI job, per repository**. Measured at head:

```
gh pr checks 366 --repo <owner>/<repo> --required   → no required checks on the branch
gh pr checks 366 --repo <owner>/<repo>              → claude-review · guard · inventory-counts (all reporting)
```

**Three checks run and report; zero are required.** A red job here is a notification, so the proposed
surface would have shipped a control that reads as enforcement and behaves as advice — and the Issue
would have closed as delivered. Making it real needs a second, owner-side change to branch protection,
which this loop cannot even read: `gh api` is denied by the global floor, hit live during intake.

`closure-artifact-guard.sh` was the other candidate and is the wrong file: its own header states *"This
script never reads a PR"*, a decision taken on the owner's call at #336, and both its arms key on the
Issue's `invocable:` declaration rather than on a PR's closing set.

### The measurement that killed the obvious implementation

The natural design — *the verdict must mention the Issue number* — **passes the exact case it exists to
refuse.** Both gatekeeper verdicts on #356 contain `#355`, the merge-authorising one included, *because
it is the verdict that prescribed removing the keyword*:

```
gh pr view 356 --repo <owner>/<repo> --json comments \
  --jq '[.comments[]|select(.body|contains("gatekeeper-verdict"))]
        |map({literal:(.body|split("\n")[1]), mentions:(.body|test("#355"))})'
→ [{"literal":"REQUEST-CHANGES","mentions":true},{"literal":"APPROVE-AND-MERGE-BOUNDARY","mentions":true}]
```

So the declaration is **positional**: `^closes:` at column 0 of the verdict, the same contract
`invocable:` and `purpose:` already carry in this tree, for the same reason — the token occurs in
ordinary wrapped prose.

### The false positive is priced in the mechanism, not in prose

A PR that legitimately closes a delivered Issue is the common case, and this repository has measured
twice that a control people route around is worse than none. **The legitimate close is not blocked; it is
declared** — one line, at column 0, in the verdict the gate is already posting, on the head it already
names. The comparison is **one-directional**: the forge's set must be inside the verdict's, never equal
to it, so a gate that reviewed two Issues on a PR that closes one is a correct state rather than a deny.
A PR that closes nothing never reaches the comparison.

### The decision, as it binds

- **Rule 7d, inside `permission-guard.sh`'s existing `*:quality-assurance` arm**, after rule 7c has
  cleared the verdict. It denies `gh pr merge` when the PR's `closingIssuesReferences` contains a number
  the head-scoped verdict does not declare on a `^closes:` line.
- **It fails CLOSED, and that is the same exception #341 took rather than a second one.** A payload
  without the field means the read that would have decided did not happen, on the irreversible act.
- **`agents/quality-assurance.md` gains the `closes:` line in both verdict templates**, plus what to do
  when the rule fires: declare it, or drop the keyword and **verify** the derived field returns `[]`
  rather than reading the body and assuming.

### What it does not reach, measured rather than assumed

- **`closingIssuesReferences` is PR-body-derived.** Probed 2026-08-30 with a throwaway PR whose body
  carried no keyword and whose single commit message carried `Closes #358`: the field returned `[]`. So
  a keyword living only in a commit message is invisible to this rule — **the one surface that cannot be
  edited afterwards**, since amending needs a force-push the floor denies.
- **It is deliberately NOT widened to scan commit messages.** That needs the PR's head branch and
  merge-base resolved inside a rule that fails closed, so every resolution failure becomes a wedged
  merge; and a hand-rolled keyword regex is measurably both over- and under-inclusive against the forge's
  own parser (`Closes #313's slice 1.` matches a regex and resolves, at GitHub, to a different number).
- **Whether the commit-message route actually closes an Issue on merge here is NOT measured.** This
  repository has no PR whose commits carry a keyword its body does not, so the two routes have never been
  separable in its history. Documented forge behaviour is not a local measurement and is not claimed as
  one.
- **Zero reach over a browser merge**, exactly as rule 7c. ~~`closure-artifact-guard.sh`'s `Stop` arm is
  what covers that residue and the commit-message route~~ — **struck 2026-08-30, the sixth instance of
  this diff's own defect and the one inside the section headed *What it does not reach*, which is
  exactly where a reader goes to learn the holes.** That arm's predicate is an Issue that **declares** an
  `invocable:` line, and #355 declares none, so it could not have fired on the instance rule 7d was built
  from by any route. It covers the **route**, for a **different obligation**; it is **not** made redundant
  and is not retired, and it does **not** patch this rule's holes. **An undeclared Issue closed by a
  browser merge or by a commit-message keyword is caught by nothing at all.**

### Consequences still being paid

- **The gate can now be denied for a second reason that is not about the diff.** The repair is one line
  in its own artifact, but it is a new way for a correct review to be stopped at the last step.
- **Nothing verifies a declaration is TRUE.** A gate that declares `closes: N` without verifying delivery
  passes. This control holds consistency between two artifacts the same persona produced.
- **Every verdict written before this shipped declares nothing**, so any such PR that closes an Issue
  needs a re-post. The blast radius is bounded by the plugin being installed deliberately — the rule is
  inert until the owner updates.
- **The blueprint registry's `0038` row asserted the opposite** (*"no permission layer can deny it"*) and
  is re-authored in the same diff, as is the README sentence it came from. A registry row is prose no
  instrument can falsify; this one went false the moment the layer analysis changed.
- **THIS DOCUMENT asserted it too, in three places, and shipped the amendment without touching them for
  one round.** The #337 amendment's *"it is the only refusal surface that exists at all"* was
  character-for-character the clause the README strikes here; its routing table's `Stop`-hook row was
  wrong in its own cell; and its *"rejected option that is still live"* described this route as unbuilt
  one page above the amendment building a variant of it. All three are corrected above. **The lesson is
  the one the strike itself is for: a strike travels to every surface carrying the sentence, and the
  canonical record is the surface most likely to be missed, because it is the one being appended to
  rather than read.**
- **`closure-artifact-guard.sh` carried the same claim in its own header** and was not in the first
  round's diff at all — so the carrier said the opposite of the registry row describing it.
- **The `Stop` arm does NOT cover this rule's residue, and TWO rounds of this amendment said it did —
  the second while the correction sat twenty-nine lines below the assertion, in the same document.** Re-derived: Issue #355, the instance rule 7d was built from, declares **no** `invocable:` line
  (`gh issue view 355 --json body --jq '[.body|split("\n")[]|select(test("^invocable"))]'` → `[]`), and
  that arm's predicate is a **declared** promise. So it could not have fired on #355 by any route. It
  covers the **route**, for a **different obligation**. **The uncovered case — an undeclared Issue
  closed by a browser merge or by a commit-message keyword — is stated in the limits section above, in
  the README, in the gate's brief and in registry `0044`**, because a residue published as covered is
  worse than one published as open.
- **The arm built for this class could not catch this instance, and that is the finding worth carrying.**
  Arm 5 asserts the correction is **PRESENT** — it counts one needle from the corrected sentence, found
  it at the corrected bullet, and passed while the false claim stood twenty-nine lines above. **A presence check cannot
  express an absence**, and the two are different assertions about the same fact. The absence half is
  arm 6's shape — *every occurrence of this clause is struck or quoted* — and it was keyed to a different
  clause, so it looked past this one. **Both halves are now written for both clauses**, and the general
  rule is stated rather than left to be rediscovered: **a correction needs the false claim's ABSENCE
  asserted, not only its replacement's presence.**

## Amendment (2026-08-31) — a lock is removed on the owner's thesis, the persona restrictions are reassessed against it, and a rite gets a route that works because a hole is open (#375)

**Deciders:** the owner. **Written by** `agents-lead` (#223). This amendment carries three things that
belong together because they are one reassessment: what the removal of a control costs, what the three
persona-keyed rules look like measured against the ruler the owner stated, and the one act in the Scrum
rites that had no route at all.

### The ruler, stated first, because every judgement below is made against it

> *«o objetivo dessa configuracao de harness é conceder autonomia segura com defesa em perimetro e
> processo de trabalho coordenado.»*
> *«nao devemos ter restricao quanto a isso no nivel de subagents. subagents precisam ter acesso a todas
> ferramentas necessarias para cumprir suas responsabilidades e atividades previstas.»*

**Perimeter defence, not local locks. Coordinated process, not restriction.** The operative test this
gives, and it is sharper than it first reads: **a rule that denies a persona an act its mandate never
included is not a restriction the thesis objects to — it is the perimeter.** A rule that denies a
persona an act its mandate *requires* is a local lock, and that is what has to go. Applied rule by rule
below, the answer is not a sweep in either direction.

### 1 · `orchestrator-write-guard.sh` is REMOVED, and it is a lock rather than a perimeter

**The owner's diagnosis:** *«entendi que foi uma contingencia entao, nao era intencional. entao esse
hook nao deveria existir. o que queriamos era deixar a sessao principal intencionalmente ociosa somente
delegando. isso o SM ajuda.»*

**Its own header agreed, which is the evidence rather than the assertion.** It recorded that the
orchestrator was denied merge (rule 7b) and trunk push (rule 7) *"and nothing else"*, and that the act
it stopped is *"not a floor violation (the work is tracked, reviewable, revertible); it is the WRONG
LAYER."* **A control whose own text says the act it refuses is not a floor violation is a routing
preference expressed as a deny**, and under the thesis that is exactly the class to remove.

**What replaces it is positive rather than negative.** *The orchestrator may not write* states the rule
by exclusion, where delegation is whatever is left over. *The main session is deliberately idle,
delegating only* makes delegation the normal path and acting directly the deviation, and
`scrum-master`'s selection record — naming who acts, **before** acting — is that rule's artifact
(ADR-0002's twenty-eighth amendment).

**Consequences, stated because they are the whole cost.** Nothing prevents the main session from
editing a repository file. Detection replaces prevention, and **the detection is weaker than the phrase
suggests**: the record is landed by the orchestrator itself, so it is self-attested, and nothing greps
`SELECTION-RECORD`. `orchestrator-tool-census.sh` still reports the main agent's write/post class at
`Stop`, one turn late, and it is now the whole of the mechanical half rather than one side of a pair.
**And #371's finding rides along**: that census classifies on the first token, so a wrapper prefix
lands a mutation in the read bucket — the one remaining observer of this class is measurably blind in
ways nobody has fixed.

### The runtime facts a deleted guard measured, rehomed here

**These are properties of Claude Code, not of the hook that found them.** They were established by
probe, they cost a probe to establish, and deleting the file that recorded them would have lost them.
The next author of any guard over file-writing tools meets both:

- **A `matcher` is ANCHORED, not a substring search.** One probe plugin, one variable:
  `matcher "rit"` did **not** fire on a main-agent `Write` (control: `matcher "Write"` fired on the
  identical call, and no file was created). `matcher "Edit|Write"` did **not** fire on a main-agent
  `NotebookEdit`, and **the notebook was mutated inside a git working tree** — a real mutation of a real
  file, not a hypothetical. `matcher "Edit|Write|NotebookEdit|MultiEdit"` fired and denied.
- **`NotebookEdit` does not carry `file_path`.** Its payload keys, read from the same probe, are
  `["cell_id","new_source","notebook_path"]`. **So a guard reading only `.tool_input.file_path` allows
  every `NotebookEdit` even with the matcher naming it** — a second side door behind the first, and one
  **no matcher fix would close.** Read a path out of a fallback chain, and assert the chain.
- **`NotebookEdit` is a DEFERRED tool in this build** — its name is listed, its schema loads on demand
  via `ToolSearch` — which is precisely why it is easy to miss by reading a session's initial tool list.

**Bound on all three: measured on build 2.1.241, once.** Nothing re-measures them now that the hook is
gone, so treat them as dated facts about a build rather than as invariants.

### 2 · The three persona-keyed rules, reassessed against the thesis — and the answer is KEEP, three times, for three different reasons

**Rule 10 — `--milestone` denied to every persona, asked of the orchestrator (#365).** **Keep, unchanged.**
It denies subagents an act **no persona's mandate includes**: composing an iteration is the owner's at
planning, and the profile most likely to want it — `scrum-master` — is explicitly barred from placing
work in its own brief. So this is perimeter, not a local lock, and the thesis does not reach it.
**Where it genuinely cannot be reconciled, said plainly rather than resolved:** if a future profile is
ever given composition, rule 10 offers only two verdicts and neither works. Exempting it to `allow`
**removes** the HITL verification #365 exists to create — the owner's answer to the prompt *is* the
verification — and that would be reversing his newer rule for one caller. Exempting it to `ask` returns
a prompt to a dispatched context with no prompt surface, which the guard's own comment says is
**unmeasured**. There is no third verdict. **That is a conflict between two of the owner's own rules and
it is left standing rather than decided here**; the mitigation that needs no exemption is the one that
shipped — *propose* and *execute* are split, the profile proposes, the orchestrator executes and hits
the prompt.

**Rule 5c/5d — `gh issue create` denied to every subagent but `developer`.** **Keep.** Under the thesis
this looks like a subagent-level restriction and is not one: opening work is not among any reviewing
persona's *atividades previstas* — it is excluded by mandate, in `/agents-configuration`'s *Review does
not open work*, and the measured failure is on record (19 net Issues in one session, ~13 born inside a
review of something else). **The friction it does create is real and is named:** `agents-lead` is now
the `loop` lane's intake and authors `loop` items, and it cannot file one — #375's own intake had to be
filed by the orchestrator on its naming. That is a routing cost, paid deliberately, and the alternative
(a fourth persona exempted) re-opens the case the exemption was cut down to one caller to close.

**A DEADLOCK is one owner decision away, and this MR records it rather than solving it (#386).** The
routing cost above is survivable only because the orchestrator is the escape valve — it files what
`agents-lead` names. The owner's decision of 2026-08-31 20:53 on #375 closes that valve: *«o proposito
da sessao principal é interface com o HITL»* and *«toda interacao com issue tracker precisa ocorrer na
camada de subagents»*. Compose the three rules as they stand:

- the orchestrator no longer touches the tracker,
- rule 5c denies `gh issue create` to every subagent but `developer`,
- `developer`'s 5d exemption is scoped to **decomposing a `ready` story**, which a `loop` item is not.

**Nothing in the loop can file a `loop` Issue at all.** Not a friction — an act with no remaining
principal. **This is NOT this PR's to solve and nothing here is changed on account of it:** no rule in
this slice moves tracker interaction, so the KEEP verdicts on 10, 5c and 5e are correct at this head. It
becomes a defect the day that decision is implemented, and it is written here so that slice starts from
a stated problem rather than discovering it.

**The proxy's premise is what breaks, which is why the repair is not just "exempt one more persona."**
5c keys on *process identity* (`agent_type`) as a proxy for *origination* (whose idea was it). Moving all
tracker work into the subagent layer severs the two, and no command string can distinguish *he asked for
this* from *the model says he did* — the same limit #339 and #363 hit from other directions. Whatever is
built there is a routing decision, not a floor one.

**Rule 5e — direct posting denied to `product-lead`, `content-writer`, `content-reviewer`.** **Keep.**
This is the one rule of the three that *is* a local lock in the thesis's sense, and it survives on the
half of the thesis that is not about tools: **perimeter defence is about irreversibility**, and a
paraphrase of `.brand/` in a public comment is not revertible by deleting the comment. The mandate is
not obstructed — each of the three has a durable artifact route (a quoted verdict, a tracked draft, a
tracked review file), so none of them is denied an *activity*, only a *spelling*.

~~**One thing 5e gains and it is deliberately NOT a case branch.** `scrum-master` is now covered by 5e's
`*)` catch-all, which denies a persona nobody has decided about. **The decision was made and it is
recorded here rather than in the rule**, because the profile holds no `Bash` at all: a case branch
naming it would be a rule with no subject, which is the *"mechanism the file claims and does not run"*
defect `permission-guard.sh` already books twice. **If it is ever granted `Bash`, that branch has to be
written**, and this paragraph is the note that says so.~~

**Struck within the same slice (#375), and the strike is kept because the reasoning it replaces is the
better half of the argument.** The clause is right that the branch is **unreachable in practice** — the
profile declares `tools: []`, so it can never issue the command, and nothing that reaches 5e under that
`agent_type` is a real dispatch. What it gets wrong is the conclusion it draws from that. *"Recorded
here rather than in the rule"* puts the decision in a document the rule's own reader is not holding,
and 5e's own comment states the property being traded away in its own words: **a deny by omission and a
deny by decision are the same behaviour and different facts, and only one of them survives someone
later reading the rule and assuming the gap was an oversight.** Five surfaces in this same slice assert
`scrum-master`'s deny as a deliberate fact; the rule was the one place it read as an accident.

**So the branch is written.** `*:scrum-master)` carries its own deny text naming its own reason — no
`.brand/` exposure, an empty tool grant — and the catch-all still stands behind it for the persona
nobody has decided about yet. **Behaviour is unchanged and was measured both ways**: the same payload
denies before and after, and only the message differs. **The branch is therefore DORMANT, not inert** —
the same distinction this slice draws for the retrospective rite's SUBTRACT clause, and for the same
reason: nothing exercises it today, and it is correct the moment anything does. The *"mechanism the
file claims and does not run"* defect is a rule that claims a case it never **decides**; this one
decides its case, and the case simply does not arrive. What is genuinely gated is the **text**, not the
verdict — `permission-guard.test.sh` asserts the by-name message is what a `scrum-master` payload
receives and that the catch-all's *"New personas default to DENY here"* is not, because a verdict
assertion cannot tell the two routes apart by construction.

### 3 · The milestone route — and it works BECAUSE a hole is open, which is the finding, not the design

**The act has no route at all, measured three ways.** `gh milestone` does not exist
(`gh milestone --help` → `unknown command "milestone" for "gh"`). `gh api` that writes is denied by rule
5f, whose prescribed remedy is *"use the gh subcommand for the act instead"* — **unexecutable here,
because there is no subcommand**. And `Bash(gh api:*)` sits unqualified in the user-level floor's
`deny`, which kills reads as well as writes, so 5f's own message (*"READING through `gh api` is
untouched"*) is **false on this machine**.

**Two candidate layers, and the one that could be clean is unreachable.** Carving the milestones
endpoint into 5f would be the precise fix — the layer that already tells a read from a write can equally
tell which endpoint — and it **would not work**, because a settings `deny` is evaluated whatever a hook
returns and the floor entry is in an **untracked user file** nothing this plugin ships can change. So
the precise fix ships inert.

**What was built instead, and it is an exploitation rather than a design.** One tracked script,
`scripts/milestone-create.sh`, is the only sanctioned milestone write. **It reaches the API because
neither the settings matcher nor `permission-guard.sh` looks inside a script** — the guard says so in
its own words at the `..`-traversal rule (*"permission-guard.sh deliberately does not look inside a
script"*). **That is the same blindness that makes `python3 -c "…gh api -X POST…"` a back door, and
both were measured against the live guard rather than a stub:**

```
{"tool_input":{"command":"python3 -c \"…subprocess.run(['gh','api','-X','POST',…])\""},"agent_type":""}
  -> permission-guard.sh emits NOTHING (allow)
{"tool_input":{"command":"gh api -X POST repos/o/r/milestones -f title=s2"},"agent_type":""}
  -> deny (rule 5f)
{"tool_input":{"command":"bash <repo>/hooks/scripts/<any>.sh …"},"agent_type":""}
  -> permission-guard.sh emits NOTHING (allow)
```

**So 5f stops the convenient spelling, not the available one, and no ADR here may claim the raw-API
route is closed.** Nobody is attacking; the point is that *"a carve-out could be widened later"* is
decisive only if what is being carved is load-bearing, and it is not. **No cheap mitigation exists** —
closing it means removing `python3:*` / `node:*` / `npx:*` from the allow lists, which breaks the loop's
own tooling. **The price of accepting it is this paragraph**: a reviewed, named, single-purpose instance
of an open hole beats an unreviewed general one, and it is not *"we found a clean layer"*.

**What makes the route defensible rather than merely available.** The widenable surface moves from a
regex in a hook to a **repo file that goes through review, the inventory gate and `quality-assurance`**.
And the script deliberately does **not** sit under `hooks/scripts/` — it is not a hook, and the
`purpose:` gate (#313) would read an unregistered script there as an orphan mechanism. It also
therefore does **not** match the user floor's `Bash(bash <repo>/hooks/scripts/*)` allow entry, **so it
prompts** — which is the feature, not the friction: composition is HITL by #365, and a prompt in the
orchestrator's session is the verification.

**Rule 11 makes that prompt a decision rather than a gap.** It keys on the script's basename plus
`agent_type`: a subagent is **denied** (no persona composes an iteration), the orchestrator is **asked**
— rule 10's exact verdict split, for the same reason. Relying on the *absence* of an allow entry would
have been the *"absent is not a state"* shape this record already books for the AWS floor.

**Placement: rule 11 sits LAST, after rule 10, and that is load-bearing.** `ask` exits like `deny`, so a
rule sited earlier would let `bash scripts/milestone-create.sh x && git push origin main` come out ASK
where rule 8 denies it — an ask that softens a deny is a hole. Rule 10's own comment already states this
and rule 11 obeys it rather than restating it.

### The alternative that was put FIRST and is not a compromise: do not grant it

`agents-configuration` stated the design — *"Creating one and closing one are both owner acts in
the browser"*, *"one click per iteration is cheaper than reopening that door."* **Both clauses are
STRUCK at head by this record's own decision (#375), the strike scoped to CREATION — closing is still
a click.** *This sentence read as if that had always been true of both sites; it was not.* The first
clause occurs **twice** in the skill — struck where it is restated alongside the second, and **left
standing at its original site** until #387 struck it there too, so a reader following this citation
between #375 and #387 landed on it asserted. Read both as the state this option was argued FROM, not
as current text; the skill was
named `harness-engineering` until #381. Planning is owner-present
by construction and nothing blocks *him*. **The price of that option, and it is the thing that gets
forgotten and rediscovered as a defect:** `/sprint-planning` carries a manual step and the rites are not
mechanically complete end to end. **The owner's requirement is the opposite** — *«voce deveria ao final
dessa reconfiguracao do loop conseguir realizar intencionalmente todas atividades previstas em ritos de
scrum»* — so the route is built and the honest description of it is above.

### What was NOT measured, and would settle it

- **Whether `gh issue edit --milestone "<new title>"` CREATES a missing milestone.** `--help` says *"by
  name"*, which is a **read**, not a measurement. **It could not be measured from here**: rule 10 denies
  every `gh issue edit --milestone` to a subagent, so the persona that would settle this question is
  the one the guard refuses. **If it does create, this whole route is moot.** Cheap to settle on a
  throwaway repo, from the orchestrator's session.
- **Whether a `PreToolUse` hook returning `allow` overrides a settings-layer `deny`.** This decides
  whether any `gh api` fix can ever ship inside the plugin. Not measured.
- **Whether `ask` reaches anything in a dispatched subagent.** Unmeasured before this slice and
  unmeasured after it; rule 11 avoids depending on it exactly as rule 10 does.

### Consequences still being paid

- **The `gh api` floor entry lives in an untracked user file, so no gate can see it**, it cannot ship in
  the plugin, and a consumer gets 5f with no floor entry — a *different* control than this one. **5f's
  own header additionally asserts the floor entry was removed** (*"WHY IT IS HERE AND NOT IN THE
  FLOOR'S `deny`, WHICH IS WHERE IT LIVED FOR AN HOUR"*) and it lives there now. **Corrected in the
  hook's comment in this slice; the entry itself is not this slice's to remove**, and whether to remove
  it is its own decision with its own record.
- **The loop depends on a capability it denies its own agents.** `session-plugin-version.sh` runs
  `gh api repos/…/releases/latest` — the exact read the floor forbids — and works only because hook
  scripts execute outside the permission layer. **That asymmetry is the mechanism behind the script
  route above**: one finding wearing two hats.
- **Nothing verifies the script does what its name says.** It is a repo file in the diff; a reviewer is
  the control. That is the same residual every prose rule here carries and it is louder for a file that
  reaches a write API.
- **The orchestrator's boundary is two mechanically-enforced acts again, down from three.** The count is
  in `CLAUDE.md` with the third clause struck rather than deleted, because it is the sentence that told
  every reader the routing rule was mechanical.

## Links
- Driven by ADR-0002 and the Merge Request Definition of Done (record 0003, absorbed 2026-08-19 into
  [ADR-0006](./0006-verification-and-its-artifacts.md)) · consumed per project via
  committed `.claude/settings.json` · the global
  floor + guard hook are described in the plugin's `/principles/permissions-and-environments` · amended
  (2026-07-25) to add the agent-scoped merge gate (rule 7b in `permission-guard.sh`), closing #77 ·
  amended (2026-08-02) to record where mechanism belongs and where a skill carries the rule instead
  (`/workflow/code-review`), closing #125 · amended (2026-08-03) to remove the main agent's ASK on
  `gh issue create` — visible-by-construction versus invisible — leaving the subagent deny unchanged ·
  amended (2026-08-04) to record the **second** surface on which per-persona scoping is expressed (rule
  5e, an `agent_type`-keyed deny in the floor alongside the `tools:` frontmatter) and the obligation it
  creates on `tadeumendonca-io`'s `/architecture` page · amended (2026-08-04, second) to record what
  each layer of the floor actually stops — the deny list catches the direct form, the hook catches the
  wrapped form, **neither is a sandbox** — and that the hook's *"settings.json is the authoritative
  backstop"* claim is inverted for wrapped commands (owner-accepted cost) · appended (2026-08-04) to
  record that rule 5e's orphaned consequence is closed by
  [ADR-0006](./0006-verification-and-its-artifacts.md)'s decided relay, and the
  obligation a persona-keyed publication deny carries from now on · **the layering half of the second
  2026-08-04 amendment is superseded by this document's *Which layer carries a control (absorbed
  2026-08-20, record 0008)* section** — its
  *"the hook, not the floor, stops them"* sentence because it was **false when written** (an empirical
  check that sampled one rule and generalised), and its *"recorded as a known property, not scheduled as
  a fix"* disposition because the owner has since decided the architecture · appended (2026-08-04) to
  bound the two-surface formula: it computes **capability**, and `security`'s `.brand/` boundary is in
  neither surface · **the second 2026-08-04 amendment's opening decision — *"`Bash(bash:*)` and
  `Bash(sh:*)` stay in the committed floor"* — is superseded in place later the same day (`14d7b43`,
  `786437c`): the owner took the interpreter class out of `allow` once plain string concatenation
  (`$'r'"m -rf /x"`, no escapes) showed that a fourth patch to the unwrap regex buys a spelling and not
  the class. Non-containment stays accepted and `node`/`python3` stay granted; the measurement is the
  `jq -r '.permissions.allow[]' .claude/settings.json` check in the *Superseded 2026-08-04, later the
  same day* block at the head of that same amendment.** · amended
  (2026-08-13) to record #62 — a retired principles skill's own prose restatement of this ADR's
  safe/boundary merge decision went stale independently and stated the opposite rule, closing the gap
  on `harness-engineering`'s consolidation · amended (2026-08-23) to add the **routing** control class
  (`orchestrator-write-guard.sh` + `orchestrator-tool-census.sh`), the fifth reason a control cannot
  live in the floor (**the permissions syntax has no caller dimension**), and the measurement that a
  `matcher` is anchored — so `Edit|Write` left `NotebookEdit` open and a matcher is an enumeration;
  the same amendment strikes this record's *"denies `Edit(.claude/**)` and `Write(.claude/**)`"*
  sentence, which head refutes (`"ask": ["Edit(.claude/**)"]`, no `Write` entry), closing #319 ·
  amended (2026-08-28) to record the owner's reversal of rule 7c's fail-open — **the merge floor, and
  only the merge floor, now fails CLOSED** (#341): the *"FAILS OPEN on a missing tool, not closed"*
  bullet is struck in place, the 2026-08-23 amendment's *"The decision is unchanged: rule 7c still fails
  open"* opening is struck with it, and that bullet's *"flipping the two `: ;;`/`*)` arms … is the
  entire diff required"* estimate is recorded as measurably wrong — the `case` it names is never reached
  for three of the four causes. The generalisation across the rest of the guard set is #342 and is
  deliberately NOT taken here. · amended (2026-08-28, second) to record a **sixth** reason a control
  cannot live in the floor — the act is performed by the forge rather than by anything the harness
  mediates, measured on a week of closes that were all closing-keyword closes — and the two-surface
  split that follows from it (`closure-artifact-guard.sh`, refusing the manual route and detecting the
  automatic one), including the PR → Issue route the owner refused and the prose-derivation the
  measurement killed, closing #337. · amended (2026-08-29) to record the layer that can refuse a
  **session** rather than an act — a `UserPromptSubmit` hook (`preflight.sh`), chosen because
  `SessionStart` cannot deny, measured against the shipped bundle — and to take the generalisation the
  2026-08-28 amendment deferred, in the shape it turned out to have: **not** *make the other rules fail
  closed*, since a missing `jq` exits the guard before any rule including the new fail-closed one, but
  *refuse the session while the guard set's preconditions are absent*. The same amendment adds a rule to
  the layer question — **how often a control fires decides whether the layer can survive holding it** —
  and records the version-drift precondition as rejected on that rule, closing #342.

## Amendment (2026-09-01) — a REPORTER's coverage is unbounded where a FLOOR's is enumerated, so it declares what it did not recognise (#371)

**What moves:** the *"Named residual — the `Bash` side door, open and known"* paragraph above, whose
clause *"the census classifies those commands into its write/post class"* is struck in place. **What does
not move:** the residual itself. The `Bash` side door is still open, still deliberately, and this
amendment makes it *more* visible rather than closing it.

### What was measured

Probed against `hooks/scripts/orchestrator-tool-census.sh` with a real `Stop` payload, threshold lowered
so the notice would print. Every row is a mutation, and every row landed in the **read** list:

| command | label produced | class |
|---|---|---|
| `git -c user.name=x commit -m y` | `git -c` | R |
| `git --git-dir=<path> commit -m y` | `git --git-dir=<path>` | R |
| `gh --repo <o/r> issue comment 1 --body-file <p>` | `gh --repo <o/r>` | R |
| `env -C <dir> claude plugin update <plugin> --scope project -y` | `env` | R |
| `gh api <endpoint>` | `gh api <endpoint>` | R, one label per endpoint |

The fourth is the motivating incident: a call that rewrote which build every project resolves, reported
as a read. The third is the more expensive one — `gh … comment` is the orchestrator's most common write,
and `command-hygiene` already documents that this flag position breaks the **permission** prefix matcher.
Nobody had noticed it breaks the census identically.

### The finding, which is about SHAPE rather than about five bugs

The three string defects are cheap and are fixed. What is not fixable in this layer is the coverage. The
first token of every `Bash(...)` allow pattern across the six settings files in this workspace resolves
to **61 distinct programs**, plus 2 absolute script paths counted separately because they are not
programs, of which exactly **two** carried a multi-word label before this change and three do after it.
**Re-derived at head on 2026-09-01, with the six files named rather than elided** — a placeholder is not
a runnable command, and this repository's rule is inline-and-runnable or not at all:

```
jq -r '.permissions.allow[]? // empty' \
  ~/.claude/settings.json ~/.claude/settings.local.json \
  <workspace>/tadeumendonca-io/.claude/settings.json \
  <workspace>/tadeumendonca-io/.claude/settings.local.json \
  <workspace>/tadeumendonca-skills/.claude/settings.json \
  <workspace>/tadeumendonca-skills/.claude/settings.local.json \
  | grep '^Bash(' | sed 's/^Bash(//; s/[:)].*$//' | awk '{print $1}' | sort -u | grep -v '^/'
```

**Four of those six files are outside every repository, not two.** Both `~/.claude/*` live in the home
directory and in no repo at all; both `settings.local.json` are untracked, measured with
`git ls-files --error-unmatch` answering *"did not match any file(s) known to git"* for each.

**From the two TRACKED files alone the same pipeline yields 57** — the exact number #371's intake
published and this amendment corrects. That line is not a footnote: without it, a reader re-deriving
from what a clone can reach lands on 57, reads this record calling 57 an erratum, and concludes the
correction was the error. **The four programs that exist only outside every repository are `brew`,
`claude`, `file` and `open`** — and `claude`, the program at the centre of #371's motivating incident,
comes from an untracked overlay.

**Three conditions govern publishing a number derived partly from untracked files**, and they are stated
here as a rule rather than as this instance's apology: name the files inline; state how much of the
derivation is unreproducible and publish what a clone yields beside it; and the argument must survive
the imprecision. **The third is what licenses the figure at all** — *the list is unbounded and it moves*
holds at 57 and at 61 — and the first two are what this amendment failed on its first authorship and
discharges here.

**The drift between 57 and 61 is the argument rather than an erratum:** four programs entered the
allowlists in one day and nothing in this repository could see it. A list that moves by four overnight,
sourced mostly from files no repository holds, is not a list anyone maintains by hand in a second place.

So *"which other programs
hide a mutating subcommand"* is not a list of seven; it is everything except two — `bump-my-version bump`
(writes two files, commits and tags), `npm publish`, `node`, `python3`, `bash`, `terraform init`,
`aws <verb>`, `awk 'print > "f"'`, `find -delete`, `curl -o`, each reported as a read.

**A hand-maintained per-tool list of mutating subcommands has the maintenance profile of a matcher list,
not of a classifier**: it must be extended every time a program is added to any of the SIX settings files named above, by
someone who remembers this hook exists. (The derivation set and the maintenance set are the same six;
an earlier draft of this paragraph said "four" beside the "six" above and contradicted itself twice.)

### The rule this adds to the layer question

> **A FLOOR may enumerate what it denies, because a denial fires on a specific act. A REPORTER cannot
> enumerate what it observes, because its subject is everything that happened — so a reporter with a
> two-class output silently reports its own coverage gap as a clean result.**

The remedy is a **third class**. `?` means *not recognised*, printed as its own block, and the notice
says in its own words that unclassified is not measured-as-a-read. Before it, `R` was the default and
nothing distinguished *measured as a read* from *not recognised*; every future gap was something the
next person found by accident.

**Price, paid rather than waved at:** the notice is longer, and `?` holds genuine readers until they are
listed. It is bounded by an explicit reader list, and `?` deliberately **does not trigger** the notice,
so a turn holding only unclassified calls stays as silent as it was before. Of the variants weighed, it
is the only one whose cost does not grow with the allowlist.

### Considered and rejected

- **Extend the W list per tool.** Rejected on the enumeration above: the list to maintain is 55 programs
  wide and grows in four files this hook does not read.
- **Go back to substring matching over the whole command.** Rejected on its own recorded evidence: run
  against a real 916-call transcript it classified a `cat` heredoc as a write because the heredoc *body*
  carried a mutating word, and `gh release view` as a post. **The argument here is that the coverage is
  unbounded, not that the matching is wrong**, and only the second was ever the defect.
- **Merge `classify()` into `permission-guard.sh`.** It is a second, weaker classifier over the same
  command strings, and this Issue is that duplication drifting into view — but the guard is a
  **fail-closed floor** and the census a **fail-open reporter**. Coupling them would give the floor a
  reason to change every time the report gains a label, which is a bad trade in the direction that
  matters. The mitigation is review discipline: **when a program is added to any allowlist, both files
  are the checklist.**

### What this does NOT claim

The census still gates nothing, still fires after the act, and still counts **attempts** rather than
effects. And the semantic half stays uncloseable: no first-N-words rule can tell `node scripts/read.js`
from `node scripts/write.js`. The `?` class is what documents that **at runtime, per session**, instead
of in a paragraph nobody re-reads.

**Significance:** *alters a previously-recorded decision*, marginally — it strikes a clause of this
record's own residual and adds one rule to the layer question. No new record. Authored by `agents-lead`
per the domain split (#223).

## Amendment (2026-09-01) — the auto-mode classifier is a THIRD-LAYER system that cannot be routed to, and the state it produces gets a name (#374)

**What moves:** *"The third layer: ask which SYSTEM authorises the act"* gains its first entry where
the section's own instruction — *"Route the control there, keep the workspace rule"* — **is not
available**, and `agents/quality-assurance.md`'s verdict vocabulary gains a fifth literal. **What does
not move:** rule 7b's single-executor design, and the four surviving holds.

### Correcting a premise before anything else: it is NOT undocumented here

The intake was briefed that this repository had never recorded the classifier. It had — **once**, in
this record, where it appears as an *obstacle to a measurement* (two greps it refused, in the
container amendment's *"What is NOT decided here"*). **That is worse than absence**: a reader meets it
as an annoyance rather than as a thing that decides acts.

### What it is, and what can honestly be said about it

Claude Code's auto-mode classifier refused a dispatch instructing `quality-assurance` to merge a PR.
Four properties, each measured or read rather than assumed:

1. **It is NOT unobservable.** The transcript carries `"toolDenialKind":"automode-blocked"` alongside
   `"sourceToolAssistantUUID"`, a value **distinct** from the `permission-rule` this harness's own guard
   produces. Over one session: 8 denial records, 2 distinct kinds, 7 × `permission-rule`, 1 ×
   `automode-blocked`. Resolving the UUID gives the denied call — a `SendMessage`, not a `Bash`.
2. **It is unconfigurable and unversioned from here.** Its predicate can change between CLI builds with
   no signal in this repository, and `session-plugin-version.sh` measures the *plugin*, not the CLI.
3. **It is advisory in wording and terminal in effect.** It says the act may be attempted with other
   tools. For a merge, the other tools are rule 7b's back door and the `gh api` route rule 5f denies.
   **The instruction it gives is one this harness must not follow**, and recording that is the point —
   a future context reading it as licence is the failure mode.
4. **It is not a control in either direction.** It is not this loop's guarantee against a bad merge
   (rule 7c is), and it is not predictable enough to design around.

**So the third layer's routing move is unavailable for the first time.** There is nothing to route to:
no configuration surface, no published policy, no per-repo setting. The rule the section adds is
therefore not *route it* but:

> **Where the authorising system cannot be reached, the control cannot be moved — so name the STATE it
> produces instead, and give that state an artifact.** An unroutable refusal is not a reason to weaken
> the workspace rule it collides with; it is a reason to make the collision visible.

### Which verdicts can strand the loop — read at head, and the asymmetry is the finding

| literal | authorised executor | permitted by this harness? | can strand? |
|---|---|---|---|
| `REQUEST-CHANGES` | `developer` / `agents-lead` | yes — no merge | no |
| `APPROVE-PENDING-HUMAN` | **the owner**, in the browser | yes — outside every layer here | **no**, and it is the only literal whose executor no layer can block |
| `APPROVE-AND-MERGE` | `quality-assurance` **alone** | rule 7b denies every other `agent_type` | **yes** |
| `APPROVE-AND-MERGE-BOUNDARY` | `quality-assurance` **alone** | identical path | **yes** |

> **The two verdicts that authorise the gate to act are the two that can strand the loop; the verdict
> that hands the act to the owner cannot.**

### The decision: a fifth literal, `APPROVE-EXECUTOR-BLOCKED`

**Decided by the owner, over the intake's flag-don't-recommend and over deferring until frequency data
existed.** It names the state that had no name — *DoD green, safe-or-boundary class, none of the four
holds applies, executor unavailable, the act is the owner's by exception* — so the readers read a state
that exists instead of inferring one from a clearance that stayed open.

**Why inference was not enough, and this is the measurement that decides the design.** *"A clearance
posted and the PR still open"* is derivable, and it is a **race detector**: the healthy sequence is
verdict-then-merge seconds later, and a strand is the same two facts minutes later. Nothing in any
artifact distinguishes *the executor is blocked* from *the gate has not merged yet* — so the weaker
honest trigger was persistence across two `Stop` events at the same `(PR, head)`, and even that could
not say **why**. The fifth literal replaces an inference with a statement by the only actor that knows.

**Spelled disjoint from the merge-authorising pair, deliberately.** `APPROVE-AND-MERGE-…` would have
read as a member of the family that authorises a merge, and this literal is its opposite. Every reader
in this repository matches exact literals and never globs (rule 7c states that in its own words), so
the naming is not what makes it safe — it is the first line of defence in the readers that have not
been written yet.

**What it costs, accepted and stated so it is not rediscovered as a defect.** Five readers now parse
the vocabulary independently — `permission-guard.sh` (7c), `session-wip.sh`, `zombie-loop-detect.sh`,
`premature-pr-link-detect.sh` and the new `owed-pr-link-detect.sh` — plus the producing brief. They
must move in lockstep.

~~and the only thing enforcing that is `inventory-counts.test.sh`'s assertion of `session-wip.sh`'s
list against the brief's own section. **That gate covers one reader of five.**~~

**STRUCK the day it was written, and it is the same defect this amendment's neighbour struck one
section above for the *Bash side door* clause — committed again, in the amendment that ships beside
it.** *"Held by review"* was false about the four `case`-block readers: removing the literal from any of
their own arms reddens that reader's own suite. **All FIVE readers were mutated, not three** — the first
authorship of this block published a three-row table under a claim about four, which is *measured and
omitted* being indistinguishable from *not measured*, this record's own rule failing on the soft side.
One mutation per run, tree restored between:

| reader, literal removed from its own arm | its own suite |
|---|---|
| `owed-pr-link-detect.sh` | 28 passed, **2 failed** |
| `zombie-loop-detect.sh` | 25 passed, **2 failed** |
| `premature-pr-link-detect.sh` | 34 passed, **1 failed** |
| `session-wip.sh` | 38 passed, **1 failed** |
| `permission-guard.sh` (rule 7c) | **430 passed, 0 failed — no red** |

**The fifth row is the one worth reading, and it is NOT a contradiction of the rule-7c sentence three
paragraphs below.** Removing 7c's dedicated arm changes the *message* and not the *decision*: the
literal falls to `*)`, which **also denies**. So the merge floor is covered by fail-closed default
rather than by an assertion, in both directions — an unconsidered literal denies, and a deleted arm
denies too. It is stated here because a table of
four reds and one green invites the reader to hunt for a defect that is not there. The two facts sit
three paragraphs apart because they concern **opposite mutations** — one adds a literal to the brief,
the other removes an arm from a reader — and only the first is what the new gate arms watch.

~~That is the safe direction and no arm is owed for it.~~ **Narrowed on the gate's own reading: that is
true of the DECISION and over-broad as first written.** An arm asserting the *decision* would be
vacuous — it would pass with the dedicated arm and without it, since `*)` denies either way, which is
precisely the assertion-that-cannot-fail this record names as a defect elsewhere. **What is unheld is
the MESSAGE**, and the message is not incidental: it is #374's whole deliverable. A gate that lands in
the executor-blocked state and is denied by the catch-all reads *"the head moved, or the literal
drifted"* — which is wrong about both, and sends it to re-post a verdict rather than to hand the owner
the link. So the honest form is *no **decision** arm is owed; the message is held by nothing*, and it
joins the residual list rather than the settled one.

**The real residual was a different one, and the misstatement hid it.** Adding a SIXTH literal to the
brief reddened exactly one arm — `inventory-counts` 179/1 on `session-wip.sh` — and left all four other
readers green. So the gap was never *a literal deleted from a reader*; it was *a literal added to the
brief that no reader ever considered*, which every reader's `*)` then swallows: silently in the two
`exit 0` readers, as a false defect report in `session-wip.sh`, as a false notice in
`premature-pr-link-detect.sh`, and as a deny with the wrong repair message in rule 7c.

**That gap is closed in this same MR**, by generalising the `awk` case-block extraction
`inventory-counts.test.sh` already had. The same sixth-literal probe now reddens **four** arms instead
of one.

**A substring match against PROSE read as a mechanism, committed by the reviewer of the batch about
exactly that (recorded 2026-09-01).** The gate's first pass ruled that *"16 of 16 suites have a step in
`hooks-test.yml`"*; its probe matched each suite's **basename in comments** rather than a `run:` line,
and the true split is **15 plus `inventory-counts.test.sh` in `docs-test.yml`**. The ruling it
supported is unchanged — every suite does run in CI — but the defect is the same one this amendment
records one section above: *a check that cannot tell a citation from a discussion of it*. It is written
down because the batch's thesis is that an instrument reporting something other than what it measures
is the failure, and the instrument was a reviewer this time.

**Four, not five, and the fifth reader is worth naming rather than rounding up.** Rule 7c does *not*
redden on an unconsidered literal — it **fails closed**, denying the merge, which is correct by default
and is why no arm is owed there. So the five readers are covered as **four that redden plus one that
fails closed**, and a reader expecting a fifth red will not get one. Stated because the sentence above
reads as *five arms* if the distinction is left to inference.

**A third class was added at the gate's first pass, and it covers the surface the other two do not.**
Both classes above compare the definition list to a **reader**; nothing compared it to the block a gate
actually **copies**. That is exactly where this amendment's own fifth literal failed to arrive — the
*"Required shape"* template kept offering four while the definition list defined five, and the
sixth-literal probe reddened four arms, none of them about it. It is the mirror of the `APPROVED`
incident this record's Context section already measured: then the template offered a literal the set
never defined; now the set defined one the template never offered. **The arm therefore asserts both
directions**, and it anchors on the fenced block rather than a line, because adding the fifth literal
wrapped the template onto two lines — a line-anchored check would have broken on its own fix.

Two arm classes below, and they are deliberately not the same strength:

- **Named-anywhere, across the three `Stop` readers.** *"Every literal must appear in every reader's
  case block"* was **rejected rather than merely not chosen**: `zombie-loop-detect.sh` deliberately
  omits both clearances and `owed-pr-link-detect.sh` omits three, so that assertion would redden on
  correct code. What is asserted is that each reader **names** every brief literal — in an arm, or in
  the comment documenting the fall-through — because the property that matters is *the author
  considered it*. **Its limit is stated in the arm itself:** a name in a comment is not a name in an
  arm, and this check cannot tell them apart. It therefore does not replace the arm-scoped
  `session-wip.sh` check, which exists because a fall-through there is a defect rather than a design.
- **Phantom, generalised to all four `case`-block readers.** Rule 7c already had this for its *accept*
  arms only; a misspelling in a deny arm, or in any `Stop` reader, was covered by nothing. This is the
  drift this record's own Context section measured three times in one day.

**What is still not gated, and this time it is stated as the narrow thing it is:** nothing asserts that
a reader's *treatment* of a literal is correct — only that it was considered and that it exists.
`owed-pr-link-detect.sh` was found by this arm never naming `REQUEST-CHANGES` at all, which is exactly
the class it was built for; whether the sentence added there is the right decision is a reviewer's call
and there is no instrument for it.

### And the gate must DISCOVER that it is blocked: attempt the merge once per head

A refusal that was never attempted leaves no `automode-blocked` record, so no downstream detector has a
premise. Measured across two PRs in one session: on the first the call was issued and the record
exists; on the second the loop reasoned *"already hit this today"* and issued nothing.

> **The signal exists precisely when the loop already knows, and is absent precisely when it forgets.
> Self-censorship produces no record of anything.**

So the behaviour rule is **attempt once per head, even when the classifier is known to block**, priced
at roughly 65 seconds per blocked head. Once, never in a retry loop.

### What was NOT built, and why each is a decision rather than a gap

- **A `Stop` detector for "a clearance posted and the PR still open".** It is a race detector, above.
  What ships instead is `owed-pr-link-detect.sh`, keyed on the two literals that *say* the act is the
  owner's, which needs no inference at all.
- **The placement half.** The motivating incident was a link the owner had received twice and could not
  find, at character 20 and character 439 of two turns. **A position threshold would have passed the
  non-ask and flagged the ask**, so position is not a ruler; it lives on #362 as a behaviour question.
- **A route around rule 7b.** The escape already exists and it is the owner's browser merge, which rule
  7c's own comment says it has zero reach over. **The strand is the correct failure of a correct rule.**

### A fourth denial kind exists, and a detector keyed on one of them misses the other

The measurement above (`8 records, 2 kinds` in one session) is honestly scoped and stays. But the
**corpus** is wider than two kinds, and a future detector needs the wider figure:

```
grep -rhoE '"toolDenialKind":"[a-z-]+"' ~/.claude/projects/<this-project>/
→ 2546 permission-rule · 51 user-rejected · 25 automode-blocked · 14 automode-unavailable
```

**`automode-unavailable` is a second auto-mode refusal shape**, and nothing above mentions it. A
detector keyed only on `automode-blocked` is blind to 14 records in this corpus. That is advisory — no
detector is keyed on either string today — and it is recorded so the first one built does not inherit
the narrower premise. *(Machine-local, like every transcript figure: the corpus is this machine's
project directory and is not reproducible from a clone.)*

### The prefix exposure this batch shipped as an open hypothesis is REFUTED, with one exception

#371 left it open whether `permission-guard.sh` carries the same wrapper/option blindness the census
had. **It does not, and the reason is the finding rather than the result.** Measured by feeding the
guard `PreToolUse` payloads with `agent_type` empty — it is a pure function of its stdin, so nothing was
mutated:

```
rule 7b (merge)      — DENY on every form:
  gh pr merge · gh --repo o/r pr merge · env gh pr merge · command gh pr merge
  xargs -I{} gh pr merge · time gh pr merge
rule 7  (trunk push) — DENY on every form:
  git push origin main · git -c user.name=x push · git -C <repo> push · env git push · time git push
```

**The census labels the FIRST TOKEN; the guard matches `(^|[^[:alnum:]_])gh…` ANYWHERE in the string**,
and rule 7b carries a shared `gh_repo_flag` pattern covering `-R`/`--repo` in every punctuation. The two
layers anchor differently on purpose, and that difference is what kept #371's defect out of the floor.
**This is evidence FOR keeping `classify()` and the guard separate, not against it** — merging them
would have propagated the bug into the fail-closed layer.

**The one exception, and it is a real hole in the floor:**

```
git --git-dir=<a-repo-on-main>/.git push        → «no decision»
```

Rule 7's extraction reads `-C` only, so a push aimed at another checkout's trunk through `--git-dir`
reaches no rule. **Contained rather than open:** that spelling matches no `Bash(git push:*)` allow
prefix either, so it degrades to *ask a human* rather than to *execute*. **Not fixed here, deliberately
— it is the floor, and the floor is its own change with its own record.** Named so the next reader
finds a measured gap rather than an open worry.

### Significance

Arm: *alters a previously-recorded decision* — it narrows the third layer's routing instruction and
extends the verdict vocabulary rule 7c enforces. `Deciders`: the owner (the fifth literal, and the
split of the deliverable); written by `agents-lead` per the domain split (#223), whose object is the
machinery.

## Amendment (2026-09-02) — every hook walked against the owner's criterion, which grades the ALTERNATIVES and not the hook (#383)

**Deciders:** the owner — the criterion, ruled on #383 on 2026-09-01. **Written by** `agents-lead`
(#223). **Nothing is removed in this slice, and that is the Issue's own condition rather than
caution** — see *The order* below.

### The criterion, and it is none of the three the intake proposed

> «qualquer trava mecanica (hook) so deveria sobreviver se nao puder ter algum mecanismo de controle
> equivalente com outros elementos de configuracao do harness explorados»

One question per hook, in this order:

> **Can some other harness element carry this control? If yes, the hook does not survive — regardless
> of how important the control is.**

**The importance of the control is not the question.** A control can be essential and the hook still
lose: the criterion is about *which layer carries it*, not *whether it is worth carrying*. That is the
inversion separating it from the three the intake offered (reversibility of the act · legible
authorship without the lock · measured firing frequency), each of which would have spared a hook on
the strength of what it protects.

**«explorados» is load-bearing** — an alternative never attempted does not count as unavailable. Each
verdict below names which of the six elements was tried: a persona brief · a skill · a command · the
permission layer · the forge/CI perimeter · a selection or verdict artifact.

### The inventory, derived — and the unit changes the number, so the unit is stated

**14 scripts · 16 registrations · 6 events.** Both figures come out of `hooks/hooks.json`, which this
MR does not touch:

```
jq '[.hooks|to_entries[]|.value[]|.hooks[]]|length' hooks/hooks.json            → 16
jq -r '[.hooks|to_entries[]|.value[]|.hooks[]|(.command|split("/")|last)]|unique|length' hooks/hooks.json  → 14
jq -r '.hooks|keys|length' hooks/hooks.json                                     → 6
```

The gap is two scripts carrying two registrations each, and the members are emitted rather than
asserted:

```
jq -r '[.hooks|to_entries[]|.key as $e|.value[]|.hooks[]|{e:$e,s:(.command|split("/")|last)}]
       |group_by(.s)|map(select(length>1))|map(.[0].s + " -> " + (map(.e)|join(", ")))|.[]' hooks/hooks.json
→ closure-artifact-guard.sh -> PreToolUse, Stop
→ preflight.sh             -> UserPromptSubmit, SessionStart
```

**A live false claim fell out of that derivation and is corrected in this same MR.** `README.md` read
*"`closure-artifact-guard` (#337) is the only hook registered on **two** events"* — false since
`preflight` shipped on two events at #342.

~~three days later~~ — **struck 2026-09-02: the interval was minted by this correction and never
falsified, which is the fifth instance of the lesson the round before it wrote down — *a correction
is a publication, and it needs the same falsifier discipline as what it replaces.* It was THREE
HOURS ELEVEN MINUTES, the same night**, and the true figure is the sharper evidence for everything
this paragraph exists to say: the claim went stale before its author slept. Published with its two
commits rather than as a rounded interval, because a duration is exactly the shape that cannot be
re-derived from the sentence carrying it:

```
git show -s --format='%H %ad %s' --date=iso 8b6d302 e1fe5c7
→ 8b6d302  2026-08-28 21:35:16 -0300  feat(loop): closure is held against the artifact … (#337)
→ e1fe5c7  2026-08-29 00:46:19 -0300  feat(loop): the session refuses to run while its guards cannot … (#342)
```

**The form to prefer is the one that cannot go stale at all**, and it already existed inside this
same diff: `inventory-counts.test.sh`'s own comment says *"true when written and false from #342
onward"* and names no duration. `README.md` now carries that form; the interval is kept only here,
where it is the argument rather than decoration. The sentence is struck in place and the derived
statement replaces it, and `inventory-counts.test.sh` now holds the claim in both directions off the
command above, so the next registration on a second event reddens rather than quietly refuting a
sentence nobody re-reads. **The event table in the same file was already correct** (it lists
`preflight` in two rows); only the prose was wrong, which is the harder half to notice.

### Which hooks can REFUSE — measured on the scripts, not read off the event names

The Issue's split was a starting point. Re-derived at head by the emission each script is capable of
— a `permissionDecision` of `deny`/`ask`, or `exit 2`, the only two refusal mechanisms in this
harness:

```
grep -lE 'permissionDecision: "(deny|ask)"|exit 2$' hooks/scripts/<the 14 registered scripts>
→ permission-guard.sh · wip-guard.sh · closure-artifact-guard.sh
  dispatch-premise-guard.sh · mcp-guard.sh · preflight.sh
```

**Six can refuse, eight cannot**, and the eight are already what the owner's direction asks for. Four
confirming probes, payload piped to the script, verdict read off stdout and the exit code:

| payload | script | result |
|---|---|---|
| `terraform apply -auto-approve` | `permission-guard.sh` | `deny` — *"pipeline-only"* |
| `git push origin main` | `permission-guard.sh` | `deny` — the trunk-push floor |
| `mcp__claude_ai_Gmail__send_message`, `agent_type` = `…:developer` | `mcp-guard.sh` | `deny` — no MCP grant |
| `{"hook_event_name":"Stop", …}` | `orchestrator-tool-census.sh` | no output, `exit 0` |

And one mutation, because `preflight` is the only hook here that fails **closed** and the claim is
worth measuring rather than reading: a `PATH` holding every binary it needs **except `jq`**, built by
symlinking into a shim directory, with the full `PATH` as the control.

```
control (full PATH)    → no output, exit 0
mutation (no jq)       → "HARNESS PREFLIGHT — REFUSING TO RUN DEGRADED (#342) / NOT ON PATH: jq", exit 2
```

That measurement decides one of the three cuts below.

### The finding that decides most of the audit: the alternatives are blind in ways the criterion's list does not say

Walking six elements against fourteen hooks produces one table, and the table is the amendment's
load-bearing part:

| element | sees WHO is asking | sees WHAT is asked | reads live state at decision time | can refuse |
|---|---|---|---|---|
| a persona brief · a skill · a command | it *is* the caller's text | yes, as prose | no | **no** |
| `settings.json` `allow`/`ask`/`deny` | **no** | a `Bash` command **prefix**, **or a tool name × path glob** (`Edit(<glob>)`) — corrected 2026-09-02, see below | no | yes |
| a profile's `tools:` grant | yes | tool **name** only | no | yes |
| the forge/CI perimeter | the forge actor | only acts that reach the forge | yes | yes |
| a selection or verdict artifact | yes | yes | yes | **no — after the fact** |

Three consequences, and each disposes of a whole class:

1. **Only two layers refuse anything locally, and each is blind where the other sees.** The permission
   layer sees the command and not the caller; `tools:` sees the caller and not the command. **A
   control needing both is inexpressible anywhere else** — this record's own *Which layer carries a
   control* section reached the same wall from the other direction. Live instances: rules 5c/5d
   (`gh issue create`, denied to every subagent but `developer`), 5e (public posting, denied to the
   three personas that read `.brand/`), 7b (`gh pr merge`, allowed to `quality-assurance` alone), and
   `mcp-guard` in its entirety. `Bash(gh pr merge:*)` sits in the **allow** list of both settings
   layers, and it must: a `deny` there denies the gatekeeper too, which is the whole act.
2. **A control whose predicate is live remote state is expressible in NONE of them**, because none of
   the five performs I/O at decision time. The criterion's list has no member for this class, so it
   has no alternative to offer: `closure-artifact-guard`'s `PreToolUse` arm (the Issue's body),
   `dispatch-premise-guard` (the repository the brief stamps), rules 7c and 7d (the gate's verdict and
   the PR's closing set).
3. **Eight of fourteen refuse nothing at all, so the criterion cannot reach them either** — every
   alternative it lists is static text or a refusal, and none of them can *observe*. No brief computes
   the open PR queue; no skill reads `agent_transcript_path`; no command knows which build is
   installed. **They are judged on cost, which is the Issue's framing and not the owner's criterion**,
   and this amendment prices them rather than pretending the criterion ruled on them.

> **So the criterion bites in exactly one place: where a hook duplicates a control another layer
> already holds.** That is a narrower cut than the Issue anticipated, and saying so is the finding. It
> found three.

#### CORRECTION 2026-09-02 — the `settings.json` row said *"a command prefix only"* and that is FALSE

**Struck as a claim, corrected in the row above, and recorded here because this is the table a later
reader applies rather than a detail.** The permission layer refuses on **two** shapes, not one: a
`Bash` command prefix **and** a tool name × path glob. Measured, both settings files,
non-`Bash` entries emitted rather than counted:

```
jq -r '.permissions.ask[]?, .permissions.deny[]?' \
  .claude/settings.json ~/.claude/settings.json | grep -v '^Bash('
→ Edit(.claude/**)                                        (project, ask)
→ Edit(//Users/…/.claude/settings.json)                   (global, ask)
→ Edit(//Users/…/.claude/plugins/**)                      (global, ask)
→ Edit(//…/tadeumendonca-io/.claude/**)                   (global, deny)
→ Edit(//…/tadeumendonca-skills/.claude/**)               (global, deny)
```

**No verdict in this amendment changes** — settings still cannot see the caller, which is the property
every caller × command verdict rests on. **But the false row was doing real damage in one specific
place, and it is the amendment arguing against its own strongest surviving verdict:** as written it
forecloses `Edit(<glob>)` as a candidate alternative for exactly the `orchestrator-write-guard` class
that the census's ground 3 rests on. A reader applying the table would have concluded no layer can
refuse a file edit at all. One can.

**So ground 3 is re-checked rather than asserted, and it narrows.** ~~The census is the only observer
of main-context `Edit`/`Write` that exists at all.~~ **Too strong.** `Edit(<glob>)` in settings *can*
refuse a file edit, path-scoped, before it happens. What it **cannot** do is refuse it **selectively by
caller** — an `Edit(**)` deny denies `developer` too, and `developer` editing the tree is the entire
build. That is the same caller-blindness that makes rule 7b inexpressible in settings, arriving at a
different rule. **Ground 3 as it now binds:** *no layer can refuse a main-context file edit without
also refusing every persona's, and no layer but the census can OBSERVE one after the fact.* The
conclusion holds; the sentence that carried it did not, and the difference is the kind a later reader
would have executed on.

### The verdicts

| # | hook | refuses? | verdict | the element that carries it instead, or the pair that makes it inexpressible |
|---|---|---|---|---|
| 1 | `permission-guard` | yes | **survives** | caller × command, four times; and enumeration in the floor was measured not to converge |
| 2 | `wip-guard` | yes | **CUT** | **its own precondition is dead** — 0 concurrency across 22 PRs, all states. ~~a skill — WIP=1 in the universal preload~~ (a preload is not a control; see the re-argument) |
| 3 | `closure-artifact-guard` | yes (`PreToolUse`) | survives | live remote state; no element reads an Issue body |
| 4 | `dispatch-premise-guard` | yes | survives | live remote state × the dispatch's own text |
| 5 | `mcp-guard` | yes | survives | caller × tool name — the canonical pair |
| 6 | `preflight` | yes | survives | nothing else can refuse a **session**; and it is the only fail-closed layer |
| 7 | `session-wip` | no | survives | observer — and it inherits #2's detection |
| 8 | `session-plugin-version` | no | survives | observer; no element reads the installed build |
| 9 | `zombie-loop-detect` | no | survives | observer; reads the gate's verdict at head |
| 10 | `orchestrator-tool-census` | no | ~~contested~~ **survives** (resolved below, 2026-09-02) | it reads an artifact the observed party did not author; the selection record is self-attested |
| 11 | `premature-pr-link-detect` | no | survives | observer; the condition is conjunctive over live CI state |
| 12 | `owed-pr-link-detect` | no | survives | observer; same |
| 13 | `dispatch-metrics-start` | no | **CUT** | `preflight` — measured above, and it blocks where this only warns |
| 14 | `dispatch-metrics-stop` | no | survives | observer, **and it has a consumer**: `/sprint-retrospective` step 2 |

**Plus one rule-level cut and one rule-level verdict that was contested and now SURVIVES (rule 7,
resolved 2026-09-02) inside `permission-guard`**, because that file is
fourteen controls in one script and a per-file verdict would hide both.

### The three that lose, each with what detects the act afterwards

**1 · `wip-guard.sh` — CUT, and the ground is the DEAD PRECONDITION, not the preload.**

~~A skill already carries a strictly stronger rule.~~ **Re-argued 2026-09-02, and the strike is the
most important edit in this amendment** — not because the verdict moves (it does not) but because the
argument as written was **a precedent for cutting `permission-guard`'s persona-keyed rules**, which
this same amendment lists as load-bearing.

**Why that argument was invalid on this amendment's own table.** *"A skill states it, so the hook is
redundant"* requires the skill to be an **equivalent control**, and the layer table two sections up
says in its own column that a persona brief, a skill and a command **cannot refuse**. A rule stated in
a preload is read by a cooperating actor; a hook denies a tool call. **They are not the same kind of
object, and the criterion asks for an equivalent MECHANISM rather than an equivalent SENTENCE.**

**Say the consequence out loud, because a later reader will otherwise reach for it:** `Review does not
open work` appears three times in the universal preload, and rule **5c survives** — this amendment says
so itself. **If "a preload says it too" were a ground for cutting, 5c, 5d, 5e and 7b would all fall**,
and every one of them is listed here as inexpressible in any other layer. **It is NOT a ground. It is
never a ground.** A preload is context; a hook is a refusal; the criterion grades layers, not
restatements.

**The ground that actually holds is the one measured, and it is about this hook specifically.** The
guard reads `gh pr list --state open --author @me` and exits at `[ -z "$open_prs" ] && exit 0` before
computing a single path. **Its precondition — another PR of the same author open at the instant this
one is created — has not been true once.** Re-derived at head, and **widened past the form published in
the first round**, which was merged-only and therefore blind to a PR that was closed without merging:

```
gh pr list --repo <owner>/<repo> --state all --limit 200 \
  --json number,createdAt,closedAt,state \
  --jq '[.[]|select(.number>=349)] as $p
        | {n:($p|length),
           never_concurrent:([$p[]|.number as $x|.createdAt as $c
             |{pr:$x, others:[$p[]|select(.number!=$x and .createdAt<$c
                 and ((.closedAt==null) or (.closedAt>$c)))]|length}]
             |map(select(.others>0))|length)}'
→ {"n":22,"never_concurrent":0}
```

**Twenty-two PRs, every state, zero concurrency.** ~~twenty most recent merged PRs … zero, twenty times
out of twenty~~ — **superseded by the wider form above, and the widening was not cosmetic.** The
merged-only query cannot see `#367`, which is `CLOSED` with `mergedAt: null`
(`gh pr view 367 --json state,mergedAt` → `CLOSED`, `null`) and was open for 26 seconds inside the
window. A concurrency claim that cannot see an unmerged PR is measuring the wrong set; this one can,
and the answer did not move.

*(Bounds, stated so the next reader knows what is NOT covered: this repository only, PRs numbered ≥349,
and the query does **not** filter by author where the guard does — filtering can only shrink the set,
so zero stays zero.)*

**So the cut rests on: the hook's own entry condition is dead in practice, and its removal therefore
removes no refusal that has ever fired.** That argument does not generalise to 5c/5d/5e/7b — each of
those fires, and this amendment keeps every one of them.

**What detects the act afterwards:** `session-wip.sh` lists the open PR queue at every session start,
so a second open PR is visible one session late — the same class of trade the removal of
`orchestrator-write-guard` made. Nothing observes it at `gh pr create` time, and nothing has needed
to.

**What the cut costs, stated as a cost and not waved away.** WIP=1 is explicitly reversible by owner
decision — `/agents-configuration` keeps the struck disjoint-files exception visible for exactly that
reason. This hook is the surviving artifact of the *previous* policy, and deleting it makes that
reversal more expensive than re-registering a file: it also holds the sibling-task exemption (#195),
which is real logic nobody would rewrite from memory. **The rehoming obligation therefore has content
here** — the overlap algorithm and the exemption belong in the removal's own record before the file
goes.

**And what it does NOT cost, because the hook was never protecting it:** the failure WIP=1 exists to
prevent — two slices in one checkout — is invisible to this guard by construction. It fires at
`gh pr create`, hours after the damage, and it derives its own side from whatever directory it runs
in, so two agents in one checkout produce the same answer. That is already recorded in
`/agents-configuration` and is unchanged by this verdict.

**2 · `dispatch-metrics-start.sh` — CUT. Its own header states two reasons and neither survives.**

Reason 1 is *symmetry with the event pair, so a future extension has a place to land without a new
`hooks.json` edit*. **That is not a control**, and a registration held open for a hypothetical is the
shape the owner's direction is aimed at.

Reason 2 is *a cheap, silent dependency probe … says so ONCE, early, rather than leaving the Stop hook
to fail silently*. **`preflight.sh` carries that, and carries it harder.** It derives its requirement
set from `command -v` declarations across every registered script, so `jq` is required transitively:

```
grep -lE 'command -v jq' hooks/scripts/<the 14 registered scripts>
→ permission-guard · closure-artifact-guard · dispatch-premise-guard · preflight
  zombie-loop-detect · session-plugin-version · orchestrator-tool-census
  premature-pr-link-detect · dispatch-metrics-start · dispatch-metrics-stop · owed-pr-link-detect
```

~~→ 10 of the 14, permission-guard among them~~ — **struck 2026-09-02: the command returns ELEVEN, at
head and at this branch's base `a547acf`.** The miscount was `preflight.sh` itself, whose own match is
real code (`if command -v jq >/dev/null 2>&1; then`) and not a comment. **The defect is the one this
same MR corrects four screens away in `README.md`** — a figure published beside a command that refutes
it — which is why the count is not corrected to `11` but **replaced by its members**: this repository's
own rule is that a set claim ships the criterion and the list, and a bare number beside a `grep -l`
buys nothing the list does not.

and the probe above shows what happens when it is missing: `exit 2`, the prompt refused, with the
missing binary named. **A warning is strictly weaker than a refusal of the same condition.** The
subsumption is chronological rather than designed — `dispatch-metrics-start` shipped at #209
(2026-08-14), `preflight` at #342 (2026-08-29) — which is exactly the drift this audit exists to find.

**What detects the act afterwards:** nothing is being refused, so nothing is owed. Removing this
registration does not weaken `preflight`'s derivation, because `dispatch-metrics-stop.sh` declares
`command -v jq` on its own and stays registered.

**Rehoming, and it is not empty.** The header records the `SubagentStart` payload's field set, measured
on #209 — `session_id`, `transcript_path` (the *main* session's), `cwd`, `prompt_id`, `agent_id`,
`agent_type`, `hook_event_name`, and the absence of `agent_transcript_path` until the agent has
produced a turn. **That is a property of Claude Code, not of the hook**, and it is the same class of
fact the `orchestrator-write-guard` removal had to rehome into this record. It moves with the deletion,
not after it.

**3 · `permission-guard.sh` rule 9 — CUT at rule grain. It is the one rule that carries no control.**

Its own text says so: *"A SPEED BUMP ON THE NAIVE TRAVERSAL. **NOT A BOUND, AND IT MUST NEVER BE CITED
AS ONE.**"* Three escape classes are recorded against it as measured, one of which — an empty quoted
span, `.""./.""./` — has no `..` adjacency anywhere in the string, so no widening of the pattern can
reach it. **The criterion does not apply to rule 9, and that is the verdict:** there is no control to
relocate, so the question *can another element carry it* has no subject. It survives today on
*"it costs one grep and a speed bump that announces itself is honest"*, which is a reasonable argument
under a thesis of defence in depth and not under a thesis of fewer mechanical locks.

**What detects the act afterwards: nothing, and nothing did before.** The floor grants uninspected
execution through more allow entries than anyone has enumerated, which is the rule's own stated
reason for not being a bound.

### ~~Contested, and the owner's to rule — two, for two different reasons~~ — BOTH RESOLVED 2026-09-02, and both to SURVIVES

**Struck as a heading rather than deleted, because it stood in a published body and the two verdicts
under it were open for a round.** Each is resolved below by a different route — one by a measurement
this harness cannot take itself, one by re-deriving against a tree that moved while the audit was
being written. **Neither reopens anything else**: the three cuts, the nine survivors and the inventory
are untouched by both.

#### `permission-guard.sh` rule 7 (the trunk push) — SURVIVES, and it is the only verdict here settled by a read this loop cannot perform

Rule 7 is the case the owner predicted: *the two acts the permission layer already reaches — trunk
push and merge — are exactly where the hook may turn out to be the redundant layer.* Half of it
already **is** redundant. Both settings layers deny the direct spellings, and the global layer goes
further and denies the `git -C <path>` spelling for both repositories by name:

```
Bash(git push origin main) · Bash(git push origin main:*) · Bash(git push origin HEAD:main:*)
Bash(git -C <repo-a> push origin main) · Bash(git -C <repo-a> push origin main:*) · …and the same three for <repo-b>
```

**So somebody already explored this alternative and implemented it by hand, per repository.** What the
settings layer still cannot express is the *semantic* case — a bare `git push` while `HEAD` is `main`,
where the target is in the checkout and not in the string — and the wrapped case. That is this record's
routing rule working exactly as written.

**The element that could have carried it whole is the forge, and the forge does not refuse this actor.**
Branch protection refusing a non-PR push to `main` would hold the control at the only layer where the
act actually lands, for every spelling at once, semantic case included. **Measured 2026-09-02:**

```
gh api repos/<owner>/<repo>/branches/main/protection --jq '.enforce_admins.enabled'
→ false
```

**That read is the OWNER'S, and the provenance is part of the finding rather than a footnote.**
`Bash(gh api:*)` is a **global deny**, so no context inside this loop can run it — not a dispatched
persona, not the orchestrator. The audit's own attempt returned
`Permission to use Bash with command gh api … has been denied.` **A harness that cannot read its own
forge perimeter cannot audit the layer it most wants to delegate to**, and that is why this verdict
took a human round-trip where every other verdict in this amendment did not.

**What `false` decides.** `enforce_admins` disabled means protection is not applied to administrators,
and **every agent in this loop acts through the owner's own credential**, which is an admin credential.
So the forge would accept a direct push to `main` from exactly the actor rule 7 exists to stop.
**Remove rule 7 and nothing refuses a direct trunk push** — not the forge, and not the settings layer
for the semantic and wrapped spellings. It survives, and it survives on evidence rather than on the
documented posture `/devops` records (*PR required, 0 approvals, no force-push,
`enforce_admins=false`*), which pointed the same way but was read rather than measured.

**The fragility is the interesting half, and it is stated beside the verdict rather than below it.**
**This survival is contingent on one repository setting that nothing in this tree can observe.** If
`enforce_admins` is ever flipped to `true`, the forge starts refusing this actor, rule 7 becomes the
redundant layer the owner predicted — **and nobody here can find out.** The setting lives at the forge,
changes without a commit, produces no diff, and the one command that reads it is denied to every
context in this loop.

**What would detect that flip: nothing does.** Stated plainly rather than softened. The candidates,
each with why it fails today:

- **A gate arm.** It would have to call `gh api` from CI. Buildable, and it is a different slice with a
  token-scope decision inside it; nothing like it exists.
- **A `SessionStart` hook.** ***Hypothesis, in those words, and it is the one worth testing:*** a hook
  runs as a subprocess rather than as a model tool call, so the permission matcher may never see its
  `gh api` invocation — in which case a hook **could** read branch protection where the model cannot.
  **Not measured.** No registered hook in this tree calls `gh api` at all, so there is no instance to
  read the answer off. What would settle it: register a throwaway `SessionStart` hook that runs
  `gh api repos/<owner>/<repo>/branches/main/protection` and observe whether it returns JSON or is
  refused. Until that is run, treat *"a hook can bypass the floor's `gh api` deny"* as unverified — and
  note that if it is **true**, it is itself a finding about the floor rather than a convenience.
- **Re-asking the owner.** The only route that works today, and it is a habit, not a mechanism.

**So rule 7's verdict carries an expiry nobody observes.** ~~nobody can observe~~ — **corrected
2026-09-02 in the same breath as the skill that quoted it**: the three candidates listed directly
above are *buildable*, *could* and *works today*, so *cannot* contradicts this record's own evidence
two lines up. The gap is **unwatched**, not **unwatchable**. That is recorded here so the next reader
finds a dated, sourced measurement and a named blind spot rather than a bare *"survives"*.

#### `orchestrator-tool-census.sh` — SURVIVES, re-derived at head after the tree moved under the audit

**The framing this amendment carried for one round is stale, and the correction is worth more than the
verdict.** It read: *"#371 measured the census wrong about its own classes: it classifies on the first
token … a reporter that is measurably blind."* **#371 shipped while this audit was being written** —
`3ec315f`, then `a6827e0`, merged in **PR #389** (`df891a5`), both already in this branch's base:

```
git log --oneline -- hooks/scripts/orchestrator-tool-census.sh
# a6827e0 fix(loop): the batch's own correction did not travel … (#370, #371, #374)
# 21d77fb fix(loop): the 57-programs figure was inherited, not re-derived — it is 61 at head (#371)
# 3ec315f fix(hooks): the census reported four mutations as reads; it now declares what it did not recognise (#371)
# a987f2a refactor(skills): command-hygiene becomes shell, license folds into documentation-standard (#384)
# ac3cbb2 fix(hooks): orchestrator-write-guard was a contingency … (#375)
# 0d218e1 feat(harness): every mechanism declares its purpose, and every declaration names a mechanism
# 53a9125 feat(hooks): the orchestrator does not edit a repository directly — one deny, one census
```

**The block above is the command's WHOLE output, and it was not on 2026-09-02.** It showed two of
seven lines — and the omitted `21d77fb` is itself a **#371** commit to this file, dropped from the
paragraph whose entire argument is *what #371 did to this file*. **An elision that removes evidence
FOR the claim it sits under is the same defect class as a count beside a refuting command:** the
command is published so a reader can re-run it, and a reader who re-ran this one found three #371
commits where the text showed two. Published whole rather than trimmed, because trimming is what
produced the defect.

Re-derived at head rather than relayed — `bash hooks/scripts/orchestrator-tool-census.test.sh` →
**`56 passed, 0 failed`**. *(The pre-fix total was relayed to this audit and is deliberately not
republished: running the old suite against the new hook measures nothing, and no figure here is
carried from someone else's context.)*

**And the repair is NOT "the misclassification is fixed" — the file says so in its own words, which is
why this is a correction and not a ratification.** Two things changed: the wrapper strip now lands
**first** (so `env -C … claude plugin update` no longer takes its label from `env`), and a **third
class `?` — meaning not recognised** — replaced `R` as the default for anything the explicit lists do
not name. The header states what was *not* fixed: *"the argument is that the COVERAGE is unbounded, not
that the MATCHING is wrong, and only the second was ever the defect,"* and **`?` deliberately does not
trigger the notice**. So the instrument's gaps are now **declared instead of silent**. That is exactly
the change that makes the verdict decidable — a declared gap can be weighed; a silent one cannot — and
it is not the same claim as *correct*.

**The verdict against the criterion, and the candidate is the one the criterion itself names.**
*A selection or verdict artifact* is the alternative, and `scrum-master`'s selection record is it.
**It cannot carry this control, for three reasons that are about the object rather than about quality:**

1. **Its input is authored by the observed party.** The orchestrator lands the selection record itself.
   The census reads the **transcript**, which the orchestrator does not author — the only input in this
   harness that the observed context did not write. That is the same distinction ADR-0006 draws between
   the gatekeeper's own posted verdict and a relayed claim, and it is the load-bearing one.
2. **They observe different things at different times.** The record states **intent, before the act**;
   the census reports **acts, after them**. A record naming who *should* act says nothing about what was
   then done, so it cannot be the equivalent control for *what did this context do with its own hands*.
3. **Since #375 deleted `orchestrator-write-guard.sh`, no layer refuses a main-context file edit
   SELECTIVELY, and nothing but the census OBSERVES one.** ~~the census is the only observer of
   main-context `Edit`/`Write` that exists at all~~ — **narrowed 2026-09-02**, because the layer table
   it rested on was wrong: `settings.json` **can** refuse an edit by tool name × path glob
   (`Edit(<glob>)`, five live entries across the two files), so *"no layer can refuse a file edit"* was
   never true. What no layer can do is refuse it **by caller** — an `Edit(**)` deny stops `developer`
   too, and that is the build. The selection record still cannot see an edit, and nothing else fires on
   one. Cutting the census removes the last observation of a class the same audit already recorded as
   unrefused. **The ground holds on the narrowed statement; it did not hold on the one it was written
   with**, and the correction section above carries the measurement.

**So no other harness element carries it, and it survives.** **Its residuals are unchanged by #371 and
are restated rather than retired:** it counts attempts and not effects (a denied call still appears in
the transcript); its coverage is unbounded by its own header's admission; `?` holds genuine readers
until someone lists them; and it fires after the act, so it detects and never prevents.

**#371 is therefore closed as the repair rather than dissolved by a cut** — the disposition this
amendment left open in the previous round, now settled in the direction that keeps the hook.

### Cost priced where the criterion is silent — the eight reporters

The criterion offers them no alternative, so this is the axis they are actually judged on. Two carry a
measured cost worth recording.

**`dispatch-metrics-stop.sh` dominates this repository's Issue comment surface**, and the figure is
published as a **dated reading of a sliding window** rather than as a fixed pair, because the window
moves every time an Issue is filed or commented:

```
gh issue list --repo <owner>/<repo> --state all --limit 40 --json number,comments \
  --jq '{metrics:([.[]|[.comments[]|select(.body|test("dispatch-metrics"))]|length]|add),
         total:([.[]|(.comments|length)]|add)}'
→ {"metrics":325,"total":390}    2026-09-01   (~83%)
→ {"metrics":333,"total":398}    2026-09-02   (~84%)
```

**Two readings one day apart, and neither is wrong** — `--limit 40` selects *the forty most recent*,
so the denominator is a moving object and a single pair republished later reads as refuted by its own
command. **The stable claim is the proportion, not the numerator**: on both readings the hook's own
comments are more than four fifths of everything on that surface. Re-run it; do not cite the pair.

**It survives anyway, and the reason is a consumer rather than a preference:** `/sprint-retrospective`
step 2 derives the rite's consult set from these comments by name. Cutting the hook removes the rite's
only evidence of which personas ran. That is the difference between this and
`dispatch-metrics-start` — one is read by something, the other by nothing.

**A defect in that instrument was found while pricing it, and it is stated here because it bears on
what the survival buys.** The Issue number is derived as the **first** integer in the branch name:

```
issue="$(printf '%s' "$branch" | grep -oE '[0-9]+' | head -1 || true)"
```

Measured against the batch branch `loop/batch-structural-381-384-372-368-r2`: **all 36 of that slice's
dispatch comments landed on #381, and #384, #372 and #368 carry none.** Under the loop-batch
permission this record's companion skill already grants — one branch may carry several `loop` Issues —
the instrument attributes the whole batch to whichever Issue is named first, and the retrospective
then reads *no persona ran* for every other Issue in the batch. **Not repaired here** (this slice
removes nothing and repairs nothing).

**And it is TRACKED rather than merely noticed — it is #382, `ready`, next in this batch.** That Issue
already names the branch grep as its first item and carries its own probes
(`fix/adr-0002-rewrite-355 → 0002`, `feat/v2-api-355 → 2`), so what this audit adds is a **live
instance on a real batch branch** rather than a new item. Verified at head:
`gh issue view 382 --repo <owner>/<repo> --json state,labels` → `OPEN`, labels `ready`, `loop`.
**Nothing is filed by this slice** — per *Review does not open work*, a finding of the audit's own goes
to the owner in the MR body, and this one had a home before the audit found it.

**`owed-pr-link-detect.sh` states in its own header that it does not address the incident that
produced it** — the defect was placement, not absence, and an absence detector is silent on both of
the turns that failed. It survives the criterion (nothing else observes a turn ending), and the honest
note is that its green means less than its name suggests. That was already declared at build time,
which is why it is a note and not a finding.

### The order, and why nothing is cut in this slice

**Nothing is removed here, and it is #383's own condition rather than caution.** The Issue states the
`orchestrator-write-guard` removal as the template *"including its two conditions: the replacement
lands first, and the runtime knowledge the hook measured is rehomed rather than deleted."* Both cuts
above carry rehoming content — `wip-guard`'s overlap algorithm and sibling-task exemption,
`dispatch-metrics-start`'s measured `SubagentStart` payload — and neither has been rehomed. A removal
slice that also had to invent its own record is the shape that produces the defects this repository
keeps paying for.

Proposed order, smallest blast radius first:

1. **`dispatch-metrics-start`** — one registration, one file, one rehomed payload fact, no control
   lost. The replacement is already in the tree and measured.
2. **`wip-guard`** — one registration, one file, and a real algorithm to rehome. Its detection
   successor (`session-wip`) is already in the tree.
3. **rule 9** — a rule-grain deletion inside `permission-guard`, with its three measured escape
   classes rehomed into this record. Mutation-check the suite: the arms asserting rule 9's denials go
   with it, and no other arm may go green over their absence.
~~4. **`orchestrator-tool-census`** — decided **with** #371, never before it.~~
~~5. **rule 7** — decided **after** the owner reads the branch-protection settings. If
   `enforce_admins` is true for the actor this loop uses, the semantic half is the only part worth
   keeping and the rest is duplication.~~

**Both struck 2026-09-02 — they were items on a removal order and both resolved to SURVIVES**, so
there is nothing left to sequence for either. Struck rather than deleted because an order is the
surface a later reader executes from, and a silently shortened list and a deliberately shortened one
must not look alike. The rulings are in the section above.

~~**Each of the five**~~ **Each of the three remaining is a `loop` change to the loop's own floor**, so
each is `ready` on the owner's transition alone.

### What could NOT be checked, so nobody re-walks it

- ~~**The forge perimeter.** `Bash(gh api:*)` is denied at the global layer, and there is no `gh`
  subcommand for branch protection. The command that would settle rule 7 is named above.~~
  **Struck 2026-09-02 — it WAS checked, by the owner, because it cannot be checked from here.**
  `enforce_admins.enabled` → `false`; the ruling is in the rule 7 section above. **The half that
  survives the strike is the reason it was listed at all:** this loop still cannot read its own forge
  perimeter, so the *answer* is now known and the *capability* is not. A second question came out of
  it and is open — whether a **hook**, as a subprocess rather than a tool call, escapes the `gh api`
  deny. **Labelled a hypothesis**; the settling probe is named above.
- **Whether any of the eight reporters is ever read by a human.** `/sprint-retrospective` reads one of
  them mechanically; for the other seven there is no artifact that would record a read, so *"does this
  notice change behaviour"* is unmeasurable from inside the harness and is the owner's judgement.
- **Whether `permission-guard`'s coverage claims still hold.** They are asserted by its own suite over
  the spellings someone thought to try, and this audit re-ran none of them. A per-rule sweep is its
  own slice.
- **Why `#375` carries zero `dispatch-metrics` comments** while its own branch
  (`loop/scrum-master-and-milestone-route-375`) resolves to `375` under the derivation above. Observed,
  not explained; the hook exits `0` silently on about a dozen paths, so the observation is compatible
  with several causes and settles none.

### What is left alone, and it is most of the file

`permission-guard`'s persona-keyed rules (5c/5d, 5e), the merge floor (7b/7c/7d), the milestone
rules (10/11), the composition rules (8/8b) and `mcp-guard` are all the caller × command pair, and
this record already measured that enumerating spellings into the floor does not converge — nine
unlisted spellings in a 150-probe sweep. `dispatch-premise-guard` and `closure-artifact-guard`'s
`PreToolUse` arm are the remote-state class, which no element in the criterion's list can hold at all.
`preflight` is the only layer that can refuse a session and the only one that fails closed. **Five of
the six refusal-capable hooks are load-bearing, and the audit says so as plainly as it says which one
is not.**

### Significance

Arm: *sets a cross-cutting pattern others will follow* — it records the test by which a mechanical
lock is kept or removed in this harness, and the layer table that answers it. `Deciders`: the owner
(the criterion); written by `agents-lead` per the domain split (#223), whose object is the machinery.
