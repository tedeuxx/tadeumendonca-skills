# 0008. Which layer carries a control — the hook is authoritative, the deny list is the direct-form floor, and the authoritative layer fails open

- **Status:** accepted
- **Date:** 2026-08-04
- **Deciders:** the owner
- **Supersedes / superseded by:** supersedes the layering claim in [ADR-0004](./0004-autonomy-and-permission-model.md)'s second 2026-08-04 amendment (*"the settings `deny` list is the hard backstop"*, inherited from `permission-guard.sh`'s own header)
- **Driven by:** the permission audit of 2026-08-04 and the ~150-probe sweep that closed it (`4842ecd`, `745d949`)
- **Floor grant recorded by this ADR — a status field, not reasoning:** `Bash(bash .scratch/*)` is honestly
  `bash <any path on disk>` with a required prefix token, and **no mechanism bounds it** (owner,
  2026-08-07, *option A*; reasoning in the third amendment). **If this decision reverses, this line is
  EDITED here — not struck — exactly as `Status:` is.** It is the one class of line this library mutates
  in place, which is why the marker lives here; see *the marker that survives strike-through* in the third
  amendment for what that does and does not buy.

## Context & problem

The permission floor has always been described as **defence in depth with the static layer underneath**.
`permission-guard.sh` says it twice in its header — *"Each repo's `.claude/settings.json` `deny` remains
the hard backstop"*, and, justifying its fail-open contract, *"because settings.json `deny` is the
authoritative backstop and we never want to wedge the agent on a malformed payload."* ADR-0004 repeated
it. Every rule added to the hook was added on that understanding: the hook is the *smart* layer, the deny
list is the *dumb but unfailing* one, and the hook may fail open because something is behind it.

**On 2026-08-04 that stopped being true for a substantial and growing set of controls, and it stopped
being true three separate times in one day — none of the three being a decision about the floor's
architecture.**

1. **`bash -c '…'`.** The settings matcher reads a command *prefix*. The prefix of `bash -c 'rm -rf /x'`
   is `bash`, and ~~`Bash(bash:*)` is in `allow`~~ ~~**`Bash(bash:*)` is in `allow` — an entry this same
   batch added; see the 2026-08-04 amendment, which corrects the tense throughout this section**~~
   **`Bash(bash:*)` was in `allow` from `4842ecd` to `994c8a1` and came back out at `14d7b43`; at
   `cb9a2f3` ~~no interpreter wrapper is allow-listed at all~~ — see the *second* 2026-08-04 amendment
   for the removals, and the **third** for that clause, which was false at the head it names.** So
   **every** prefix-matched `deny` entry is unreachable in wrapped form **for as long as any wrapper is
   allow-listed** — which is a property of the matcher rather than of the entry, and is why this routing
   reason outlives the entry that first demonstrated it.

   > **Corrected 2026-08-04, third — and the correction makes this reason stronger, not weaker.**
   > *"No interpreter wrapper is allow-listed at all"* is contradicted by this same record 170 lines
   > down (*"of the six interpreters listed, only `node` and `python3` are in `allow` at that head"*)
   > and by `permission-guard.sh`'s own header, which books `node -e` and `python3 -c` as **NOT
   > COVERED, DELIBERATELY**. Measured at `f797cc6`, piping each into the guard: `node -e …` and
   > `python3 -c …` both draw **no decision from any layer**, and both are allow-listed, so they run.
   > What came out at `14d7b43`/`786437c` is the **shell** wrapper class; the interpreter wrapper class
   > is **not empty**, by design. The clause therefore read as though the wrapped-form hole had closed
   > at this head. It has not, and the condition in the sentence it introduces — *"for as long as any
   > wrapper is allow-listed"* — **is still satisfied at `f797cc6`**. Like routing reason 3, reason 1
   > has a **live** instance in the floor as it stands and not only a historical one. The accepted
   > non-containment is unchanged; only a sentence that erred toward reassurance is.
2. **`gh api`'s read/write split.** `-f`/`-F` switch the request to POST with no `--method` present, so no
   prefix separates a read from a write. The blanket `Bash(gh api:*)` deny added that morning removed
   reads the loop itself performs, and the control moved to the hook (rule 5f).
3. **Allow entries shadowing deny entries.** ~~`Bash(gh -R:*)` and `Bash(gh --repo:*)` exist because~~
   ~~**`Bash(gh -R:*)` and `Bash(gh --repo:*)` were added to `allow` by this batch, because**~~
   **`Bash(gh -R:*)` and `Bash(gh --repo:*)` were added to `allow` by this batch at `4842ecd` and
   removed again at `cb9a2f3`, because** `gh -R <repo> <subcommand>` **was** this workspace's prescribed
   multi-repo convention. A prefix deny on
   `gh repo delete` cannot see `gh -R owner/repo repo delete`. `Bash(git -C:*)` does the same to the
   `git` half — **and `Bash(git -C:*)` is still in `allow` at `cb9a2f3`, so this reason has a live
   instance in the floor as it stands, not only a historical one.** The convention moved rather than the
   reason: the repo flag now goes **after** the subcommand (`gh pr view --repo <o/r>`), which matches the
   per-subcommand entries instead of fronting them. See the second 2026-08-04 amendment.

**Counted against the committed floor rather than asserted:** ten `gh` deny entries **were** shadowed by
the two `-R`/`--repo` allow entries (`workflow run`, `release create`, `release delete`, `repo delete`,
`repo archive`, `repo rename`, `pr merge --squash`, `pr merge -s squash`, `secret set`, `secret delete`),
and four `git` entries covering two acts are shadowed by `Bash(git -C:*)` (`clean -f`, `clean -fd`,
`push --tags`, `push --follow-tags`). **`permission-guard.sh`'s header gives this as *twelve*; it counts
the two `git` pairs as the two acts they are, this section counts the four literal entries. Neither is
wrong and both are the wrong thing to check against** — see *record the derivation, not the count* below.

> **Re-derived at `cb9a2f3`, and this paragraph is now its own worked example.** The two `gh` allow
> entries came out at `cb9a2f3`, so **the ten `gh` denies are no longer shadowed** and the shadowed set
> is the `git` half alone. The count above is stale; **the derivation beside it is what let a reader see
> that in one command** (`jq -r '.permissions.allow[]' .claude/settings.json`, checked against the deny
> list), which is the entire claim of *record the derivation, not the count*. The number moved **down**
> here, against that section's *"the count only moves in one direction"* — a prediction about migrations,
> not about an allow entry being withdrawn.

The trunk-push denies are shadowed the same way, and the one
`-C`-form deny that exists (`Bash(git -C /Users/tadeumen/git-reps/tadeumendonca-skills push:*)`) is
hardcoded to one of the two repos in the workspace — the consuming repo's own floor has no equivalent
entry at all. For all of these the hook is already the only layer, and item 1 above puts **every**
remaining entry in the same position the moment a caller types eight extra characters.

**The pattern is what demands a decision, not the instances.** Each of the three migrations was locally
correct, each was made by someone solving a different problem, and **nobody was deciding the
architecture**. The architecture changed anyway, three times in a day, and the header sentence describing
it was in none of the three diffs. A property that can be inverted as a side effect is not a property; it
is an accident that has not been contradicted yet.

## Decision drivers

- **A control's layer should be chosen, not inherited from whichever layer someone reached for.**
- **Expressibility is a hard constraint.** A prefix matcher provably cannot express *"the `-R` form of
  this subcommand"*, *"this `gh api` call writes"*, or *"the payload inside these quotes"*. No amount of
  care makes it able to.
- **Failing closed on a broken hook must not wedge the agent** into a state whose only repair route runs
  through the owner — the floor exists to spend less of his attention, not more.
- **The reader of the hook and of this library must be able to tell which layer is load-bearing**, because
  the fail-open contract is justified by the answer.

## Considered options

1. **The hook is authoritative; the deny list is the floor for the direct form** *(chosen)* — the static
   `deny` list catches the obvious spelling, which is the one an agent reaches for by default and the one
   a human types by accident. Everything else — wrapped, composed, semantic, or shadowed by an `allow`
   entry — is the hook's, by construction rather than by preference. *Trade-off:* the authoritative layer
   is the one that **fails open**, and every future migration into it removes one more thing the static
   layer still covers. Booked in full below.

2. **Make the hook fail closed** — on a parse error, a missing `jq`, a malformed payload, deny instead of
   allow, so the authoritative layer's failure mode matches its new status. *Why not:* the owner rejected
   it, and the reason is the failure that has already happened. `wip-guard.sh` records it in its own
   header: with `jq` off `PATH` the guard emitted no decision at all. Reproduced here for this record —
   with `jq` stubbed to exit 127, `permission-guard.sh` returns nothing for a `git push origin main`
   payload, because extraction fails before any rule runs and `deny()` itself needs `jq` to emit. **Under
   fail-closed, that same broken `jq` denies every `Bash` call in the session** — including the ones that
   would diagnose and repair it. The agent is wedged, and the only route out goes through the owner, at
   the moment he is least able to see why. A control that converts a missing dependency into an outage of
   the whole loop costs more than the window it closes.

3. **Pattern-list every spelling back into the floor** — keep the static layer authoritative by enumerating
   the wrapped, attached and `-R` forms as additional `deny` entries. *Why not:* **measured, not
   predicted.** The ~150-probe sweep of 2026-08-04 found **nine** spellings nobody had listed, across
   rules that had already been swept once for exactly this: `gh --repo=o/r pr merge`, `gh -Ro/r pr merge`,
   the same two against `secret set`, `gh api -ftitle=x` (the audit's own route, respelled, at a moment
   when that rule was the only layer left), `git -C <path> clean -fd`, `git -C <path> push --tags`,
   `gh -R o/r repo delete`, `gh -R o/r workflow run`. The rule this repo already learned twice — from
   `rm -fR` and from rule 5b's `-R` — is that **a floor which depends on how the caller punctuated is not
   a floor**. Enumeration does not converge; each fix leaves the next spelling open, and the list's
   *appearance* of coverage is worse than a shorter list that claims less.

## Decision outcome

Chosen: **option 1.** In operative language a reviewer can apply on a diff:

> **Direct form → the settings `deny` list. Wrapped, composed, semantic, or shadowed by an `allow` entry
> → `permission-guard.sh`.** The hook is the **authoritative** layer. The deny list is a floor for the
> spelling a caller produces by default, not a backstop behind the hook.

**The four routing reasons, stated identically here and in `permission-guard.sh`'s header** so the two
cannot drift into two different rules:

1. **Wrapped** — `bash -c '<payload>'`. The prefix is `bash`; the payload is invisible to the matcher.
2. **Composed** — `&&`, `||`, `;`, `$( )`, backticks, a `VAR=x` prefix. The matcher reads one prefix and
   cannot decompose the rest.
3. **Semantic** — the act is not in the string. `git push` lands on the trunk or not depending on the
   checked-out branch; `gh api` reads or writes depending on whether `-f` is present.
4. **Shadowed by an `allow`** — `Bash(gh -R:*)`, `Bash(git -C:*)`. **[At `cb9a2f3` only `Bash(git -C:*)`
   is still in `allow`; `Bash(gh -R:*)` is kept here as the worked example that produced the rule, not as
   a claim about the current floor. The routing reason is about a **shape** — a broad allow on a tool
   whose deny entries are per-subcommand — and the shape has a live instance either way.
   `permission-guard.sh`'s header carries the same two examples and is corrected the same way in the same
   branch; this sentence is required to be identical in both places, so correcting one alone is itself
   the drift this clause exists to prevent.]** The general form is the one worth
   quoting, because it is the reason this class is systematically underestimated:

   > **An `allow` entry does not weaken one `deny`; it weakens every `deny` for the same tool, at once,
   > and silently.**

And the property that goes with it, stated because it is the half a reader will otherwise assume away:

> **The authoritative layer fails open.** On a parse error, a missing `jq`, or a malformed payload,
> `permission-guard.sh` emits no decision, and for every control it is the only layer of, that is an open
> door rather than a degraded one. **This is accepted, in the owner's name, with option 2 rejected on the
> reason recorded above.**

`permission-guard.sh`'s header must stop asserting the inverse. That is a `hooks/` change and not this
record's to make; it is booked here so the slice is written down rather than remembered.

## Why this is not a weakening of the principle it looks like it weakens

Stated explicitly, because the batch that produced this decision ratified *"a control expressed as
absence is not a control"* and this record could be misread as retreating from it.

That principle was about **`gh api` being unlisted** — never denied, merely absent — and therefore erased
by a single `Bash(gh *)` wildcard in an unreviewed 82-entry local overlay. **It is untouched. An explicit
`deny` still beats every `allow` for the direct form**, which is precisely the property the overlay
defeated and the committed floor restores. Nothing here removes a `deny` entry or narrows one.

What changed is **which layer carries the semantic cases** — and it changed because those cases are
**inexpressible in the other layer**, not because anyone traded them away for convenience. The three
migrations of 2026-08-04 each moved a control that the static matcher could not have expressed correctly
in any spelling. There was no version of the floor that held them.

## Consequences

**Good**
- The layering is now **decided**, so the next migration is a choice made against a written rule rather
  than a side effect nobody records. The three that happened today were each locally correct and
  collectively an architectural change; that is the failure mode this record closes.
- The fail-open cost is **visible where the controls live**. It was previously justified by a backstop
  that, for a growing set of rules, was not behind them.
- Reviewers get a test they can apply to a diff without judgement: *can a prefix express this?* If no, the
  floor is the wrong layer and adding it there is theatre.

**Bad / accepted costs**
- **The authoritative layer fails open, and the set of controls it alone carries only grows.** A broken
  `jq`, a harness payload change, or a `set -u` expansion of an undefined variable (which has already
  happened once in this file, and would have made a deny matcher silently match *less*) is a hole in
  everything on the hook's side of the line. There is no second layer for those.
- **The floor now reads as broader than it is.** A reader of `.claude/settings.json` sees `rm -rf` in four
  spellings and infers containment. It contains the direct form only, and this record is the only place
  that says so.
- **`permission-guard.sh`'s header is wrong until a `hooks/` diff fixes it**, and nothing mechanical
  detects the disagreement between a record and a comment.
- **Neither layer is a sandbox, and the perimeter model does not claim one.** Arbitrary code execution is
  granted deliberately inside the perimeter (`node`, `python3`, `perl`, `ruby`, `bash`, `sh`). These
  controls exist for the irreversible/public boundary and for process integrity, never for containment.
  ~~**This bullet's judgement stands; its tense does not. Four of
  those six entries, plus `xargs`, enter the committed floor in the same diff that records this ADR — see
  the 2026-08-04 amendment for what was measured and in which direction the perimeter moved.**~~
  **Corrected again at `cb9a2f3`, and this is the second correction to the same four words. Of the six
  interpreters listed, only `node` and `python3` are in `allow` at that head; `perl`, `ruby`, `bash` and
  `sh` reach the human as an ASK. The judgement is unchanged and the reason is the sharper half — the
  perimeter is still non-containment, because `node -e` and `python3 -c` reach every act `bash -c` did
  and `permission-guard.sh` deliberately does not chase them (its own header books `python3 -c`,
  `perl -e`, `ruby -e`, `node -e` and `eval` as NOT COVERED, DELIBERATELY). What changed is which
  spellings cost an ASK, not what the perimeter contains. See the second 2026-08-04 amendment.**

### The accepted cost that makes this architecture degrade quietly — *the retained floor entry*

Named separately because it is the one a reader will remove **correctly by every other measure**, and
because it is what bounds the fail-open cost above.

When a control migrates to the hook, **its floor entry stays.** `bash -c 'rm -rf /x'` needs the hook, but
a plain `rm -rf /x` is still stopped by a layer that cannot fail open. That retention is the whole reason
the fail-open cost is bounded rather than total: a wedged `jq` leaves the cheap, default spelling of every
migrated control still denied.

> **The floor entry is not a duplicate of the hook rule. It is the fail-closed half of a two-layer
> control.** Deleting it converts a control that survives a broken `jq` into one that does not.

**The bound covers less than the architecture, and this is the sharper half.** Retention bounds the
fail-open cost for controls that **migrated** — they had a floor entry and kept it. It does nothing for
controls **born in the hook**, which have no direct form to fall back to and never had one: rule 7b (the
merge gate), rule 8 (composition), rule 5f (`gh api` writes), rules 5c/5d/5e (who may open work, who may
publish), and rule 7's bare-`git push`-on-`main` branch. For those, a broken `jq` is a **total** hole, not
a degraded one. The concrete instance, since it is the one that matters most: `Bash(gh pr merge:*)` is in
`allow` and the merge gate exists **only** in the hook, so with `jq` missing the main agent can merge a PR
with no decision from any layer — verified by probe against the live tree with `jq` stubbed. **So the
retained floor entry bounds the migrated set only, and the set it does not bound contains the gate.**

**And it is true only by convention.** Nothing verifies that a migrated control kept its floor entry, and
nothing would notice its removal. The removal reads *correct*: a deny list with a semantic layer behind it
is exactly where an entry looks redundant, and *"redundant with the hook"* is a sentence a careful reviewer
would write. This failure mode is silent in both directions — no test reddens, and the loop behaves
identically until the day `jq` is missing.

**Can anything check it? Considered and rejected, stated so this reads as a decision rather than an
oversight.** A test asserting *"every hook rule has a corresponding floor entry"* is writable. It requires
a **mapping between two files that nobody maintains** — hook rules are numbered by lineage and matched by
regex, floor entries are literal prefixes, and the correspondence is one-to-many in both directions
(rule 5g covers six subcommands; rule 7 covers spellings the floor never enumerates). Worse, it would go
**red on the correct act**: adding a hook rule for something the floor never denied — which is most of
them, since rules 7 and 8 exist precisely because no floor entry could express them — would fail a guard
that is supposed to be protecting a retention rule. **A check that is wrong more often than right trains
the loop to silence it**, which is the failure this library has already recorded for a hook that guessed
intent from a command string.

So the cost stands **unclosed, with the reason stated**. What holds it is this paragraph, the header
sentence that matches it, and a reviewer who reads either before deleting a deny entry.

## The standing consequence — the sentence a future reader needs

> **Any control a prefix cannot express belongs in the hook by construction.** And **every such migration
> removes one more thing the fail-open cost is bounded by** — so the price of the hook's fail-open contract
> is not fixed, it is paid again, slightly higher, each time a rule moves.

~~Two~~ **Three** obligations follow (the third added 2026-08-07 by the third amendment; struck rather
than rewritten, per *record the derivation, not the count*), and they are cheap only if they are done at
the time:

- **A migration into the hook is an amendment to this record**, not a comment in the rule. Three
  undocumented migrations in one day is what made this decision necessary; the fourth should append here.
- **A rule that a prefix CAN express stays in the floor.** Moving it for tidiness spends the fail-open
  budget for nothing. `claude mcp` is the worked example, named rather than omitted: no flag convention
  sits between the words and no `allow` entry shadows it, so the prefix matcher sees every spelling and
  the hook would add exactly zero.
- **Added 2026-08-07 — ask the routing test's second question, and know which of the two failures you are
  in.** *Can this layer **express** the control* is not sufficient; **`can this layer EVALUATE the
  property the control is about?`** is the other half, and a layer can express a property it has no
  instrument to decide. The two failures are different in kind and take **different remedies**:

  | | **sampling shortfall** | **kind mismatch** |
  |---|---|---|
  | example | the unwrap regex vs the shell grammar (amendment #2) | rule 9 — a **lexical** instrument asserting a **filesystem** property (third amendment) |
  | what more probes buy | more coverage, never all of it | **nothing**; the property is not decidable at that layer |
  | remedy | publish the derivation — *"these spellings, measured this way, on this date"* — so the next reader extends it | **stop claiming the control and record the grant**; there is no direction to extend in |

  The practical test, since neither has an instrument: **a rule that asserts a filesystem, network or
  process property from a caller-supplied string should be assumed unable to evaluate it until probed.**
  Rule 9 was routed to the hook **correctly** by the four reasons above, was tested with eighteen cases,
  went green, and bounded nothing — so passing the routing test is not evidence of holding the control.
  Worked example and measurements in the third amendment.

## A practice this decision promotes: *record the derivation, not the count*

Judged to have earned a named place, on the evidence that it was reached independently **three times
today** by three different parties solving three different problems — the roster sweep removed counts from
prose rather than correcting them; ADR-0004 was corrected because a stale count of `agent_type`-keyed
denials made `security`'s search stale (*"a stale count is a stale search"*); and
`permission-guard.sh`'s header now gives the routing test — *read the deny list, and for each entry ask
whether one of the four reasons applies* — with **twelve as of 2026-08-04, followed by "do not trust that
number; re-derive it."**

> **A derived count in prose is a claim with no owner. The derivation is the thing that stays true.**

The count in this record's *Context* (ten `gh` entries, four `git` entries) is written the same way: it
names the two `allow` entries that cause the shadowing and the deny entries they shadow, so a reader who
finds a different number has the method to see why rather than a contradiction to report. **A number is
given only to convey magnitude, never as the thing to check against.** This is not a rule about counting;
it is the general form of the defect this whole record is about — a fact recorded in a place that no
mechanism keeps true, in a shape that gives the next reader no way to re-derive it.

## The open question this inherits, recorded rather than settled

ADR-0004's 2026-08-02 amendment decides *mechanism where the act is irreversible, skills where the rule
is a judgement*, and records an unresolved objection: the rule is stated on **reversibility** while its
evidence is about **expressibility**, and the two come apart (`inventory-counts` gates an entirely
reversible property and is one of the harness's highest-yield mechanisms). **This record is stated on
expressibility throughout** — it is the axis on which floor-vs-hook actually divides. That is not an
answer to 0004's question; it is a second data point for it, on a different pair of layers. Noted so the
sweep that eventually settles it starts from both.

## Amendment (2026-08-04) — the perimeter this record prices is one this batch widened, and no control of this shape may be recorded as *closed*

Two corrections, both raised by `security` reviewing this batch at `ce2deea` (PR #145). **Neither touches
the routing decision, the fail-open acceptance, or the retained-floor-entry cost** — those are re-affirmed
as written, and `security`'s review confirmed the third of them member by member (the born-in-hook set
7b, 8, 5f, 5c/5d/5e and rule 7's bare-push branch have no floor entry; 5g and 4b correctly sit in the
migrated-and-bounded set, so *"the set the floor does not bound contains the merge gate"* is true as
written). What is corrected is a **tense** and a **word**.

### 1 · ~~The perimeter is not inherited — this diff moved it, and outward~~ The perimeter is not inherited — this diff moved it, out and then back

> **The direction claim is superseded by the second 2026-08-04 amendment.** *"Outward"* was true of the
> head it was written at (`994c8a1`) and of every head before it; three later commits in the same batch
> (`14d7b43`, `786437c`, `cb9a2f3`) withdrew all seven entries, and at `cb9a2f3` the committed floor is
> **identical to `main` on every one of them**. The half that is corrected is the **direction**. The half
> that stands, and is the reason this amendment was worth writing, is that **the perimeter was moved by
> this batch rather than inherited from it** — which is exactly as true of a batch that moved it out and
> back as of one that only moved it out, and is the fact a reader weighing the trade needs.

The body above prices the interpreter class as deliberate non-containment and presents that as the
condition the decision was taken inside. **It is partly the condition this batch created.** Measured
against `git diff f316015..ce2deea -- .claude/settings.json` rather than asserted:

| entry | committed floor before | the gitignored local overlay | after this batch — ~~as written at `994c8a1`~~ re-measured at `cb9a2f3` |
|---|---|---|---|
| `Bash(bash:*)` | absent | **absent** — only six *literal* `bash <file>` invocations | ~~**in `allow`**~~ **absent** — in at `4842ecd`, out at `14d7b43`; five *literal* `bash <test-script>` entries remain |
| `Bash(sh:*)` | absent | absent (only `Bash(shellcheck *)`) | ~~**in `allow`**~~ **absent** — in at `4842ecd`, out at `14d7b43` |
| `Bash(xargs:*)` | absent | absent (only `Bash(xargs -n1 basename)`) | ~~**in `allow`**~~ **absent** — in at `4842ecd`, out at `14d7b43` |
| `Bash(perl:*)` | absent | `Bash(perl *)` | ~~in `allow`~~ **absent** — in at `4842ecd`, out at `786437c` |
| `Bash(ruby:*)` | absent | `Bash(ruby *)` | ~~in `allow`~~ **absent** — in at `4842ecd`, out at `786437c` |
| `Bash(node:*)`, `Bash(python3:*)` | present | absent | present |
| `Bash(gh -R:*)`, `Bash(gh --repo:*)` | **absent** | `Bash(gh *)` | ~~**in `allow`**~~ **absent** — in at `4842ecd`, out at `cb9a2f3` |

**Why the fourth column is corrected in place while the heading above it is struck.** The first three
columns are dated measurements of states that existed, so they are history and are untouched. The fourth
is not a measurement of any past state — its subject is *"after this batch"*, and the batch has not
landed, so there is no earlier world it is an honest record of. Striking it and appending a replacement
would enter a state into the record that nothing ever occupied. The heading is different: it is a
**thesis** that was true at a committed head and that a reader auditing this amendment must be able to
see, so it is struck and followed rather than rewritten.

Two different movements, and collapsing them is what produced the wrong framing:

- **`perl` and `ruby` were already inside the effective perimeter** — the overlay granted them by
  wildcard. For those, this batch widened the **recorded** floor and left the **effective** one where it
  was, which is the batch's stated purpose (*"a control expressed as absence is not a control"*).
- **`bash`, `sh` and `xargs` are new to both.** The overlay listed specific `bash <script>` invocations,
  never the `-c` form as a class. **So the mechanism *Context* item 1 describes — a `bash` wrapper making
  every prefix-matched `deny` unreachable — is a hole this diff opened in the committed floor**, not one
  it inherited. Before it, `bash -c 'rm -rf /x'` matched no `allow` entry and would have reached the human
  as an ASK. (Under the overlay it reached ALLOW anyway, via `Bash(rm *)` and no `deny` block at all —
  which is why the *net* session-to-session change is not a simple widening. It is a widening of the
  reviewed floor and a large narrowing of the unreviewed one.)

**Method, so the next reader can re-derive rather than trust:** the overlay was truncated by `4842ecd` and
is gitignored, so it is not in git; the copy measured above is the pre-truncation backup taken during that
same session (`scratchpad/settings.local.backup.json`, 82 `allow` entries, **no `deny` block**, matching
`4842ecd`'s commit message). If that file is gone, the commit message is the surviving record and the
table's middle column is the part that can no longer be re-derived.

**Why this is worth an amendment rather than a footnote.** The *Decision drivers* and the accepted
fail-open cost read differently when the perimeter under discussion is one the same author had just made
larger. A reader deciding whether to accept the same trade — and this record exists to make that decision
re-derivable — needs to know the perimeter **moved, and in which direction**, because "we already lived
here" and "we moved here in this diff" carry different burdens of proof. ~~The judgement is unchanged: the
interpreter class stays in `allow`, non-containment stays accepted, and `security` called that the right
call recorded in the right place. Only the claim about *when it became true* is corrected.~~

> **Superseded 2026-08-04 (second amendment) — the owner reversed the judgement this paragraph reports
> as unchanged.** At `14d7b43` he took `Bash(bash:*)`, `Bash(sh:*)` and `Bash(xargs:*)` out of the floor,
> and at `786437c` `Bash(perl:*)` and `Bash(ruby:*)` followed; **the interpreter class does not stay in
> `allow`.** The evidence that decided it is worth carrying, because it is the argument this record's own
> *Considered options* item 3 makes and the one a future reader will re-open: the matcher had been
> patched three times for wrapped spellings, and `$'r'"m -rf /x"` — **plain concatenation, no escape
> decoding at all** — still reached ALLOW. No fourth patch reaches that. So the class came out of the
> allow list instead of the spelling coming into the matcher.
>
> **Non-containment stays accepted, and that half is untouched** — `node -e` and `python3 -c` remain
> allow-listed and reach the same acts. What changed is that the *cheap default* wrapper now costs an
> ASK, which is a different property from containment and should not be read as one.

### 2 · *Closed* is not a word a pattern-over-a-grammar control may use about itself

The generalisation the third occurrence earns.

**The three, in order, all inside this one batch.** Each is the same move: measure some spellings, report
the class.

1. `4842ecd` — the floor's `rm` deny was understood to cover recursive-force deletion. Measured:
   `rm -rf /x` denied while `rm -r -f /x`, `rm -f -r /x` and `rm -fR /x` reached ALLOW. *(Recorded in
   that commit's message; not re-measured here.)*
2. `745d949` — the wrapped form was reported as covered on a probe that **sampled `rm` and generalised**.
   Rule 4 matches the raw string and was the only rule that caught it; every `$bare` rule was blind.
   *(Recorded in `permission-guard.sh`'s own header; not re-measured here.)*
3. `ce2deea` — the unwrap step's header says the wrapped class is *"Closed by the unwrap step below"*.
   **Re-measured here, against the committed script at `ce2deea`, by piping payloads at it directly:**

   | spelling | decision at `ce2deea` |
   |---|---|
   | `gh pr merge 145 --merge` | `deny` |
   | `bash -c 'gh pr merge 145 --merge'` | `deny` |
   | `bash -c $'gh pr merge 145 --merge'` | **no decision → ALLOW** |
   | `bash --norc -c '…'` / `--login` / `-i` / `-o posix` | **no decision → ALLOW** |
   | `echo x \| xargs -I{} bash --norc -c '…'` | **no decision → ALLOW** |
   | `bash --norc -c 'git push origin main'` | **no decision → ALLOW** |
   | `bash -c $'git push origin main'` | **no decision → ALLOW** |

   Two causes, both visible in the committed text: the quote-strip
   (`s/^'(.*)'$/\1/; s/^"(.*)"$/\1/`) does not know ANSI-C `$'…'`, and the unwrap regex requires `-c` to
   be the **first token after the shell name** (`(bash|sh|zsh|ksh|dash)[[:space:]]+-[A-Za-z]*c[A-Za-z]*`),
   with no alternation for an option run. The two-line fix is `developer`'s and lands in this same branch;
   **it is not what this amendment records.**

**The decision.** Stated as a rule about the *record*, because that is this library's jurisdiction and
because the hook's header can only say it about itself:

> **A control implemented as a pattern over a grammar may be recorded as *"these spellings, measured this
> way, on this date"* — never as *"closed"*.** The class it must cover is every string the grammar admits;
> the evidence available is always a finite sample. *Closed* asserts the first and is only ever backed by
> the second, so it is **not a claim the author is in a position to make**, however careful the sweep.

This is the same defect as *record the derivation, not the count*, one level up: a count in prose is a
claim no mechanism keeps true, and **a coverage verdict in prose is a claim no mechanism could have
established in the first place**. The remedy is identical in shape — publish the derivation (which
spellings, by what probe, on what date) so the next reader can extend it, rather than a verdict they can
only trust or discard.

It binds this record too. *Considered options* item 3 rejects enumeration on the ground that
*"enumeration does not converge"* — which is the same fact stated about the floor. **It applies equally to
the hook**, and the hook is now the authoritative layer, so the non-convergence is not a property of the
layer that lost the argument. It is a property of the technique both layers use.

**What it costs, stated rather than absorbed.** This is the half that makes it a trade rather than a
tidying:

- **Every such record gets longer and less quotable.** *"The wrapped class is closed"* is one clause a
  reviewer can carry in their head; the table above is not. A record nobody quotes is a record nobody
  applies, and this library has already lost a header sentence to exactly that (the *"hard backstop"*
  claim, wrong for months, in a file everyone had read).
- **The reader must check a measurement instead of reading a verdict**, which moves work from the author
  to every future reader and makes the record's usefulness depend on the sample still being current. A
  probe list dated 2026-08-04 says nothing about the rule as amended in October.
- **It removes the stopping rule.** *Closed* is what tells a sweep when to stop probing; *"these
  spellings"* never does. The stopping point moves back to judgement — which is the thing the formalism
  was bought to replace. **No remedy is proposed for this**, and it is the strongest argument against the
  rule. What holds it is that the alternative has now been measured wrong three times in one day, and a
  stopping rule that stops early is worse than none, because it stops **and** reports coverage.

**The narrow scope, so this does not become a ban on plain sentences.** It applies to controls that match
a **pattern against a caller-controlled string** — the settings prefix matcher and the hook's regexes.
A control over a **closed, enumerable** domain may still be recorded as closed: `agent_type` keys take
finitely many values a rule can list, so *"every non-`developer` persona is denied"* is a provable claim
about a set, not a sample of one. The test is whether the adversary picks from a set the author wrote or
from a grammar.

## Amendment (2026-08-04, second) — a floor entry's name is not the entry; the record that justifies it is spread across files no removal commit opens

Raised by `quality-assurance` blocking PR #145 at `cb9a2f3`. **The routing decision, the fail-open
acceptance and the retained-floor-entry cost are again untouched** — what is corrected is that this
record and ADR-0004 asserted, in the present tense and framed as measurement, a floor that three later
commits in the same batch had already taken apart.

### The measurement, so it is checkable rather than reported

At `cb9a2f3`, `jq -r '.permissions.allow[]' .claude/settings.json` contains **none** of `Bash(bash:*)`,
`Bash(sh:*)`, `Bash(xargs:*)`, `Bash(perl:*)`, `Bash(ruby:*)`, `Bash(gh -R:*)`, `Bash(gh --repo:*)`.
**On all seven the committed floor is identical to `main`.** Removed by `14d7b43` (`bash`, `sh`,
`xargs`), `786437c` (`perl`, `ruby`) and `cb9a2f3` (the two `gh` flag prefixes). `Bash(chmod:*)` took the
same route in and out (`4842ecd` → `fe0143c`), with its `Bash(chmod -x:*)` deny added and withdrawn
alongside it; it is named here because it is an eighth instance of the pattern and it appears in no
narrative at all, which is the quieter half of the same defect.

The corrections are applied at the sites above, and each says which convention it took and why. The
short form: **a dated measurement of a state that existed is history and is left alone; a thesis or a
decision that was true at a committed head is struck and followed; a forward claim about a batch that
has not landed is corrected in place**, because there is no past world it is an honest record of and a
strike would enter into the library a state nothing ever occupied.

### The rule this earns — *the entry is one file, the record of it is five*

The cause was established by toggling rather than inferred. `git show --stat cb9a2f3` is three files;
`git log 8f48a4f..cb9a2f3 -- docs/adr/0008-which-layer-carries-a-control.md docs/adr/0004-autonomy-and-permission-model.md hooks/scripts/permission-guard.sh`
stops at `786437c`. **Each removal commit was scoped to the file it removed from plus the narrative
adjacent to it, and no commit re-grepped the entry's name across the tree.** The drift sits exactly, and
only, at the sites those commits did not open.

> **Removing or adding a floor entry is a change to at least five artifacts, and the name of the entry is
> the only thing that finds them all.** The entry lives in `.claude/settings.json`; its justification
> lives in this record, in ADR-0004, in `permission-guard.sh`'s header, in the ADR index, and in the
> assertions in `inventory-counts.test.sh` and `permission-guard.test.sh`. **Grep the literal entry
> string across the tree before the commit, not the directory you are editing.**

This belongs to ADR-0008 rather than to a new record because it is **this decision's own architecture
restated as an obligation**: the reason the justification is spread across five artifacts is that the
floor holds only the direct form while the hook and the ADRs carry everything else. A layering that
divides a control across layers divides its record across files by the same cut.

**`developer` is adding the mechanical half** in this branch — an assertion in `inventory-counts.test.sh`
that no tracked file asserts an allow entry the floor does not contain. The rule above is what makes that
assertion legible when it goes red: it fails on the *narrative*, and the fix is almost never to change the
floor back.

**What the mechanical half cannot reach, stated so it is a known bound rather than an oversight.** It
matches a literal entry string, so it finds `Bash(bash:*)` in prose and does not find *"the interpreter
class stays in `allow`"*, which asserts the same thing with no entry name in it — and that sentence is one
of the sites corrected above. The class of claim is a paraphrase; the check is a string match. It closes
the spelling, not the class, which is this record's own amendment #2 applied to the remedy for its own
amendment #1.

### Two residuals corrected, both measured, and both strengthening the decision not to fix them here

**1 · The `Edit(.claude/**)` remedy named in `cb9a2f3`'s message does not exist.** That message records
the fix as *"the absolute form mirrored in both repos"*. Measured since: **a repo's `settings.json` is not
loaded at all in a session rooted elsewhere.** The evidence is this repo's unique deny — a
`git -C <skills> push` to a nonexistent remote **reached git and failed there**, which a floor deny would
have pre-empted. So the deny was never *consulted*, not merely unmatched, and mirroring the glob into both
files would not change that: the deny can only fire from the session root's own file. The recorded
migration target — *"belongs in the hook"* — names a layer with **no `PreToolUse` on `Edit`/`Write`** at
all; the guard is registered on `Bash`.

Both corrections point the same way, and it is the opposite of the direction a remedy points: the control
is void **by scope**, on a tool **no hook can see**, so there is no cheap fix being deferred. Not
attempting one in this PR is the right call for a stronger reason than the one recorded when it was made.

**2 · `gh <subcommand> --repo <o/r>` matches the existing per-subcommand entries** — verified live three
times, with a `gh api` denial in the same session proving the deny layer was live at the time. That is
why withdrawing `Bash(gh -R:*)` and `Bash(gh --repo:*)` at `cb9a2f3` cost nothing: the convention moves
the flag after the subcommand and the twenty-five careful per-subcommand entries do the work they were
written for, instead of sitting behind a flag prefix that fronts the whole `gh` grammar. **Routing
reason 4 is not weakened by this — it is satisfied.** The shadowing was removed by deleting the shadow,
which is the remedy this record prefers wherever it is available, and `Bash(git -C:*)` shows where it is
not: no convention change removes it, because `-C` *is* how the multi-repo loop addresses the other repo.

## Amendment (2026-08-07, third) — a layer can EXPRESS a control it cannot EVALUATE, and expressing it reads exactly like enforcing it

Raised by the merge gate on PR #160 and decided by the owner the same day (*option A*). **The routing
decision, the fail-open acceptance and the retained-floor-entry cost are untouched again.** What this
amendment adds is a **second question** the record did not ask, and one floor entry recorded as what it
actually is.

### The decision

> **`Bash(bash .scratch/*)` stays in the floor, and this record states what it is: `bash <any path on
> disk>` with a required prefix token.** There is no mechanism bounding it. The honesty lives in the
> record, not in a mechanism, because **no mechanism available at that layer delivers it.**

`.scratch/` in that entry is not a boundary. It is a **password** — a string the caller must type, after
which every file on the filesystem is reachable.

### The measurement, so it is checkable rather than reported

Against the live floor, with the entry in force:

```
$ bash .scratch/../../tadeumendonca-io/VERSION
.scratch/../../tadeumendonca-io/VERSION: line 1: 0.1.193: command not found
```

`bash` opened and executed a file in **another repository**. Exit 127 is `bash` choking on the contents;
the permission decision was **ALLOW**, from no layer.

`permission-guard.sh` rule 9 was written to close exactly this and does not. Three escape classes, each
measured **with rule 9 in force**:

| spelling | decision | why |
|---|---|---|
| `bash .scratch/\.\./\.\./other-repo/x` | **ALLOW** | backslash escape; `\` is not in the preceding-character class, and `\.` is `.` to the shell |
| `bash .scratch/.""./.""./other-repo/x` | **ALLOW** | empty quoted span — there is **no `..` adjacency anywhere in the string**, so no widening of a character class can ever catch it |
| `bash .scratch/link.sh` | **ALLOW** | symlink out; the guard never resolves paths |

**The asymmetry that would have fooled a single probe:** escaping *one* dot pair still denies on the
next. A prober who tried one escape, saw a deny, and generalised would have reported the rule holding.

### The second question this earns

This record's standing test is *which layer can express this control?* Rule 9 passes that test — the
prefix matcher provably cannot express *"inside this directory"*, so by routing reason 4 the control
belongs in the hook, and that routing was **correct**. The rule was then written, tested with eighteen
cases, went green, and **bounded nothing.**

> **Expressibility is two questions, not one. Can this layer *express* the control — and can it
> *evaluate* the property the control is about?** A layer can express a property it has no instrument to
> decide, and the expression is indistinguishable, from the outside, from enforcement.

**The cause, stated as a category rather than a bug:** rule 9 asserts a **filesystem** property with a
**lexical** instrument. Between the command string and the file that opens sit quote removal, escape
processing and symlink resolution. `permission-guard.sh` performs none of the three — deliberately,
because performing them means parsing shell — and every escape in the table above is one of them.

**This is not amendment #2 restated, and the difference is the operative part.** Amendment #2 says a
pattern-over-a-grammar control may be recorded only as *"these spellings, measured this way, on this
date"*, because the class is a grammar and the evidence is a sample. That is a **sampling shortfall**:
more probes buy more coverage, just never all of it. Rule 9 is a **kind mismatch**: more probes buy
nothing, because the property is not decidable at that layer at all. Amendment #2's remedy — publish the
derivation and let the next reader extend it — does not apply, since there is no direction to extend in.
The remedy here is different in kind too: **stop claiming the control and record the grant.**

**This distinction is promoted out of this amendment** into *The standing consequence* above, as a third
obligation with the two remedies side by side. It is only reusable if a reviewer meets it where they
apply the routing test, and nobody reads to a third amendment before routing a rule.

### What was actually traded, and what was not

**Reach is unchanged either way.** `python3`, `node`, `npx`, `npm`, `perl` and `ruby` are in `allow`
**uninspected**, so every act the entry permits was already one interpreter away. The entry adds no
reachable act. **What was wrong was the entry claiming a bound** — which is this record's *"the floor
now reads as broader than it is"* cost, arriving in the one place a reader would least suspect it,
inside a path that looks like a scope.

### Considered and rejected

1. **Widen rule 9 a fourth time.** *Why not:* the empty-quoted-span escape has no `..` adjacency
   anywhere in the string, so no character class reaches it. This is *Considered options* item 3
   (*enumeration does not converge*) at a higher altitude, and this batch had already respelled four
   spelling-shaped rules for the same reason. The shape was never the problem.
2. **Forbid the wildcard; one exact-match entry per script.** The previous answer, and a real one —
   `inventory-counts.test.sh`'s assertion 3 was written to require exactly this, and said a future need
   *"should arrive as a deliberate change to THIS assertion, reviewed, rather than as a quiet line in
   the floor."* *Why not:* it restores the friction the scratch convention exists to remove. Probe
   scripts are generated with distinct names, so every probe costs a frozen absolute entry or a human
   prompt — and the floor gains nothing measurable, since reach is unchanged (above). *This is the
   option a future reader should re-open first if the trade stops looking right;* it is rejected on
   cost, not on principle.
3. **Record rule 9 as the bound and move on.** *Why not:* measured false the day it was written. A
   record asserting a control stronger than it is fails in the direction nobody notices — which is the
   failure this whole record exists to close, and the reason the strike marks in rule 9's header were
   made rather than the text quietly replaced.

### The residual the relative spelling leaves — recorded, not settled

`grep -nE 'cwd|PWD|pwd' hooks/scripts/permission-guard.sh` returns **nothing**: the guard never learns
where the command runs. Neither does the settings matcher. So the **relative** spelling `.scratch/*`
means *any directory named `.scratch` relative to wherever the shell is* — and this workspace has a
second registered working directory with its own `.scratch/` (`/Users/tadeumen/git-reps/tadeumendonca-io/.scratch`,
confirmed present).

Issue #155 specified the **absolute** form — `Bash(bash /Users/tadeumen/git-reps/<repo>/.scratch/*)` —
and that spelling closes the cross-repo ambiguity for free, at the matcher, with no hook involvement. It
was traded away for portability without the cost being seen. **Book this as a security consequence of
the relative spelling, not as a portability trade.** It does not change the decision above — the
absolute form is still `bash <any path on disk>` by the same traversal — but it is the one improvement
available at zero cost to the fail-open budget, and it is the owner's call rather than this record's.

### The coupling this creates, and my judgement of it

`hooks/scripts/inventory-counts.test.sh` assertion 3 forbids a trailing wildcard on any shell-interpreter
allow entry. It now grants **one exception**, and the exception applies only while this file contains
both the literal entry string and the phrase `any path on disk`. Delete the record and the entry is
flagged again.

**I judge the coupling sound, for the reason it is unusual: under option A the record IS the control**,
so tying the assertion to the record ties it to the only thing that carries the property. The tie it
replaced was worse in a way worth keeping visible — it grepped a **phrase from rule 9's deny message**,
so commenting out rule 9's code left the phrase alive in the comment and the exception applying with no
rule behind it. Commenting out is what a bisect and a revert-in-place both do. That tie failed in the
**unsafe** direction; this one fails safe.

**Its bound, stated so it is known rather than discovered.** The check is a `grep -F` for two strings. It
verifies the record *mentions* the entry; it cannot verify the record is *true*, and — in a library whose
convention is **supersede and strike, never delete** — it cannot verify the record still *asserts* what
it asserted. A struck `~~Bash(bash .scratch/*)~~` inside a superseded span greps identically to a live
one. The check would go green on a record that had reversed itself.

#### The marker that survives strike-through — narrowed, not closed

There **is** a spelling that survives, and it is the one line class this library **mutates in place
instead of striking**: the front-matter status block. `Status: accepted → superseded` is already the
documented reversal move for a whole record, so a field there is governed by *edit*, not by *append and
strike*. The marker is therefore stated as a **status field in this record's header**, added by this
amendment, carrying both literal strings and an explicit instruction that a reversal edits it.

**What that buys:** it moves the marker from a place the convention **preserves** (struck prose, which
greps identically to live prose) to a place the convention **requires editing**. Reversing the decision
without touching the field is now a visible inconsistency in the header rather than an invisible pass.

**What it does not buy, and this is the honest half.** Nothing *forces* the field to be updated. It is
held by the same convention as the retained floor entry two sections up — *"true only by convention;
nothing verifies it, and nothing would notice its removal"* — and it fails the same way: silently, with
no test reddening. **The bound is narrowed, not closed, and it stays recorded as a bound.**

**Rejected: teach the check to ignore matches inside `~~…~~`.** *Why not:* it is a **spelling**, and this
batch's entire subject is spelling-shaped rules being respelled. `<s>`, `<del>`, a strike opened on one
line and closed on another, or a superseding block quote that strikes nothing and simply says *"this no
longer holds"* all defeat it, and each would leave the check reporting coverage it does not have —
amendment #2's prohibition applied to the check itself. A shorter check with a written failure mode beats
a cleverer one whose failure mode nobody can predict.

> **The check should point at the status field, not at the whole file.** That is a `hooks/` change,
> outside this record's grant, so **today the check still greps the whole file and the field is inert.**
> Booked here so the slice is written down rather than remembered — the same disposition this record used
> for `permission-guard.sh`'s header.

**If a mechanism existed, I would prefer it, and where one exists the rule is to execute it rather than
grep for a sentence about it.** For this control none exists at this layer, and that is the decision
above rather than an omission. What I would add instead, and it is a behaviour check rather than a
document check: assert the **spelling** of the entry in `.claude/settings.json` — that any `.scratch`
wildcard is written in the absolute form. That is a property of a file the suite already reads, it goes
red on the exact regression the residual above describes, and it is not a sentence anyone can satisfy by
writing prose. Proposed, not decided; it belongs to the owner and to a `hooks/` diff, not to this record.

### The finding worth the most, and it is about the record rather than the rule

**This exact hole was measured in this repo three months earlier, by a different author, and written
down** — `inventory-counts.test.sh:455-459`:

> *"Measured at round 4: a path prefix is a STRING prefix, and `…/hooks/scripts/../../../../private/tmp/x.sh`
> carries it while reaching any script on disk. **The prefix bounded the characters, not the directory.**"*

The wildcard entry went into the floor anyway, and a hook rule was then written to close a hole the tree
already documented as unclosable by that means.

> **A comment is a place to put a finding, not a layer that can hold a control.** The finding was
> correct, current, in the right file, and in the file the new entry's own assertion lives in — and it
> stopped nothing.

That is **this record's own subject turned on the record itself**: *which layer carries this control, and
can that layer hold it?* asked about the **documentation** layer. It answers the way the rest of this
record answers — the layer can express the finding and cannot enforce it — and it is the reason the
mechanical half matters here. What eventually caught the entry was not the comment stating the property;
it was assertion 3 **executing** it.

The consequence, and it is the obligation this amendment adds to the two in *The standing consequence*:

- **When a finding is measured and cannot be mechanised, it goes in an ADR — not only in the comment of
  the file where it was found.** A comment is scoped to its reader; this library is what a floor change
  is required to be grepped against (*"the entry is one file, the record of it is five"*). The finding
  above lived in exactly one of the five, and the four commits that could have caught it never opened it.

### What it costs

- **The floor now contains one entry whose honest description is `bash <any path on disk>`**, and the
  only thing distinguishing it from a bare `Bash(bash:*)` — which this library removed at `14d7b43` — is
  the friction of typing a prefix token. That is a real weakening relative to the post-`14d7b43` floor,
  accepted in the owner's name, on the ground that reach is unchanged by the uninspected interpreters.
- **A record is now load-bearing for a test's verdict.** Editing prose can turn a suite green or red,
  which is a coupling this library has otherwise avoided; the bound above is the price.
- **The second question does not come with an instrument either.** *Can this layer evaluate the
  property?* is answered by judgement and by probing, exactly like the stopping-rule problem amendment #2
  left unremedied. No remedy is proposed. What holds it is that a rule asserting a filesystem, network or
  process property from a command string should now be **assumed** unable to evaluate it until probed.

## Links
- Supersedes the layering claim in [ADR-0004](./0004-autonomy-and-permission-model.md)'s second
  2026-08-04 amendment (both the *"the hook, not the floor, stops them"* sentence, superseded in place
  there for the separate reason that it was **false when written**, and the *"recorded as a known
  property, not scheduled as a fix"* disposition) · related to ADR-0004's 2026-08-02 amendment (mechanism
  versus skill — a different pair of layers, the same unresolved axis) · the `agent_type`-keyed denials
  (rules 5d, 5e, 7b) are per-persona scoping and stay with ADR-0004 · evidence: `4842ecd` (the audit and
  five decisions), `745d949` (the `-c` unwrap and the attach-tolerance sweep; 245 assertions) ·
  `hooks/scripts/permission-guard.sh`, `hooks/scripts/wip-guard.sh` (the recorded real fail-open with
  `jq` off `PATH`).
- **Amendment evidence (2026-08-04):** `git diff f316015..ce2deea -- .claude/settings.json` for the
  perimeter table's first and last columns; the pre-truncation overlay backup for its middle column
  (82 `allow` entries, no `deny` block — corroborated by `4842ecd`'s commit message); and the ALLOW table
  from piping payloads at `git show ce2deea:hooks/scripts/permission-guard.sh`, run against the committed
  script rather than the working tree, since `developer`'s fix was already unstaged there.
- **Second amendment evidence (2026-08-04):** `jq -r '.permissions.allow[]' .claude/settings.json` at
  `cb9a2f3` for the seven absences; `git log -p 4842ecd~1..cb9a2f3 -- .claude/settings.json` for which
  commit removed which entry; `git show --stat cb9a2f3` and
  `git log 8f48a4f..cb9a2f3 -- docs/adr/0008-… docs/adr/0004-… hooks/scripts/permission-guard.sh` for the
  scope of the removal commits; `14d7b43`'s message for the `$'r'"m -rf /x"` probe that decided the
  reversal; `git show cb9a2f3:hooks/scripts/permission-guard.sh` for the header's own *NOT COVERED,
  DELIBERATELY* list of the interpreters that remain allow-listed.
- **Third amendment evidence (2026-08-07):** PR #160 and its merge-gate verdict, which raised the
  measurement; the live-floor run of `bash .scratch/../../tadeumendonca-io/VERSION` (ALLOW, exit 127 from
  `bash` on the file's contents, no decision from any layer); the three escape classes probed against
  `hooks/scripts/permission-guard.sh` **rule 9 in force**, whose struck header records the same three;
  `grep -nE 'cwd|PWD|pwd' hooks/scripts/permission-guard.sh` → **no match**, for the relative-spelling
  residual, with `/Users/tadeumen/git-reps/tadeumendonca-io/.scratch` confirmed present as the second
  candidate directory; issue **#155** for the absolute form that was specified and traded away
  (`Bash(bash /Users/tadeumen/git-reps/<repo>/.scratch/*)`); `hooks/scripts/inventory-counts.test.sh`
  assertion 3 for the coupling, and its round-4 comment at lines **455-459** for the same hole measured
  three months earlier.
