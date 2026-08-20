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
- **Driven by:** [ADR-0002](./0002-agentic-dev-loop-architecture.md), and the Merge Request Definition of
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
[ADR-0002](./0002-agentic-dev-loop-architecture.md)'s amendment #9 gave the merged copy lens `Bash`, the
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

The same diff denies `Edit(.claude/**)` and `Write(.claude/**)` while itself modifying
`.claude/settings.json`. **That is intended and is stated here so it reads as a decision rather than an
oversight: the permission surface is owner-edited, and an agent proposes changes to it rather than
applying them.** Without this sentence the first agent that needs an allowlist entry reads the denial as
a bug and works around it, which is the failure mode this record exists to prevent.

## Amendment (2026-08-13) — two artifacts stated opposite rules about the same act, and neither was wrong on its own terms (#62)

**Recorded here, on `harness-engineering`'s consolidation ([#224](https://github.com/tedeuxx/tadeumendonca-skills/issues/224)/[#237](https://github.com/tedeuxx/tadeumendonca-skills/pull/237)), because the incident it documents is this ADR's own decision drifting out of sync with a second copy of it** — the retired `skills/principles/dev-loop/SKILL.md` (folded into `harness-engineering` by that PR) carried its own prose description of the merge step, independent of this ADR's text, and the two fell out of agreement.

**What happened.** `skills/principles/dev-loop/SKILL.md` stated, for the `trunk-single-env` model: *"Auto-merging to `main` is never in-pattern here."* That sentence predates this ADR's **Decision outcome** above (*"the safe class self-merges on a green DoD; the boundary escalates"*, 2026-07-22) and was never updated to match it. An agent reading only the dev-loop skill and an agent reading only this ADR reached **opposite conclusions** about the same act — whether `quality-assurance` (then `critical-reviewer`) may merge the safe class itself — because the two records of the same decision disagreed, and nothing cross-checked them.

**Why this is a decision-currency defect, not a merge-authority defect.** The classification this ADR decided (safe self-merges, boundary escalates, Amendment 2026-07-25 making "only the reviewer merges" mechanically true) was never wrong or ambiguous *in this ADR*. The failure was that a second prose restatement of the same rule, in a different file, was allowed to go stale independently — the platform equivalent of two callers holding different cached copies of the same config with no invalidation between them.

**Resolution.** The stale sentence was struck in `dev-loop`'s own text (*"That was written before ADR-0004's classified autonomy and contradicted `quality-assurance`'s own definition… What the merge asks for is a judgement, and who supplies it depends on the class"*) and the corrected framing — safe class merges itself once both lenses are green, boundary class never does, unclear-is-boundary — is now carried in exactly one place: `skills/harness-engineering/SKILL.md`'s *"The merge is the go/no-go"* section, which cites this ADR directly rather than re-deriving the rule in its own words. Consolidating three principle skills into one (`harness-engineering`) removes the specific duplication that let this drift happen; it does not remove the general risk of a future skill restating an ADR's decision in fresh prose that can then drift.

**Accepted cost, named rather than solved:** nothing mechanical asserts that a skill's prose description of a decision still matches the ADR it describes. This amendment records the one incident that surfaced; it is not a standing check.

## Which layer carries a control (absorbed 2026-08-20, record 0008)

**Disposition 4 of [ADR-0020](./0020-an-adr-earns-its-place-by-explaining-the-current-codebase.md):
record 0008's decision is in force and is moving into the document that governs its capability.**
Decided by the owner on 2026-08-04, driven by the permission audit of that day and the ~150-probe sweep
that closed it. **It supersedes the layering claim in this record's own second 2026-08-04 amendment**
(*"the settings `deny` list is the hard backstop"*, inherited from `permission-guard.sh`'s header) — a
supersession that is now internal to one document, which is the clearest single argument for the fold.
Its History row is in [the index](./README.md).

**This is the section a reader is sent to by name.** `agents/harness-lead.md` cites this decision as
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

Raised by `harness-lead` on `-io`#402, where `terraform apply` was reachable from a `workflow_dispatch`
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
- **The re-derivation of `harness-lead`'s four-proxy classification.** Its conclusion — *the test above
  is the thing to check against, not the number four* — is the derivation rule again, and the classified
  rules are named where they matter.
- **The record's own `Links` and evidence lists**, whose live members are folded into this document's
  cross-references.

## The merge precondition is a floor, not an instruction — **`proposed`, not `accepted`** (absorbed 2026-08-20, record 0007)

**Read the status before the decision.** Record 0007 was `proposed` when it was absorbed and this
section inherits that status: **the hook it decides is unimplemented.** Nothing in the running system
behaves the way this section describes, and nothing is wrong today because of that. Everything below is
a design that was reasoned to a conclusion and never built.

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
`APPROVE-AND-MERGE` / `APPROVE-PENDING-HUMAN` / `REQUEST-CHANGES`. **All three were found by reading.
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
- **The `Considered options` restatement of the chosen option as option 1.**
- **The record's own `Links` list**, whose live members are folded into this document's cross-references.

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
  rather than by a dispatched `harness-lead`, because the plugin was disabled for that phase. It is
  archaeology about how one record came to be written, and it binds nothing.
- **The `Considered options` framing of option 1 as an option.** Option 1 *is* the decision; restating it
  twice was MADR structure, not content.
- **The record's cross-citation of 0008 as a separate record**, which is now a cross-reference inside one
  document.

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
  on `harness-engineering`'s consolidation.
