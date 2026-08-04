# 0008. Which layer carries a control — the hook is authoritative, the deny list is the direct-form floor, and the authoritative layer fails open

- **Status:** accepted
- **Date:** 2026-08-04
- **Deciders:** the owner
- **Supersedes / superseded by:** supersedes the layering claim in [ADR-0004](./0004-autonomy-and-permission-model.md)'s second 2026-08-04 amendment (*"the settings `deny` list is the hard backstop"*, inherited from `permission-guard.sh`'s own header)
- **Driven by:** the permission audit of 2026-08-04 and the ~150-probe sweep that closed it (`4842ecd`, `745d949`)

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
   is `bash`, and `Bash(bash:*)` is in `allow`. So **every** prefix-matched `deny` entry is unreachable in
   wrapped form, for every command in the floor.
2. **`gh api`'s read/write split.** `-f`/`-F` switch the request to POST with no `--method` present, so no
   prefix separates a read from a write. The blanket `Bash(gh api:*)` deny added that morning removed
   reads the loop itself performs, and the control moved to the hook (rule 5f).
3. **Allow entries shadowing deny entries.** `Bash(gh -R:*)` and `Bash(gh --repo:*)` exist because
   `gh -R <repo> <subcommand>` is this workspace's prescribed multi-repo convention. A prefix deny on
   `gh repo delete` cannot see `gh -R owner/repo repo delete`. `Bash(git -C:*)` does the same to the
   `git` half.

**Counted against the committed floor rather than asserted:** ten `gh` deny entries are shadowed by the
two `-R`/`--repo` allow entries (`workflow run`, `release create`, `release delete`, `repo delete`,
`repo archive`, `repo rename`, `pr merge --squash`, `pr merge -s squash`, `secret set`, `secret delete`),
and four `git` entries covering two acts are shadowed by `Bash(git -C:*)` (`clean -f`, `clean -fd`,
`push --tags`, `push --follow-tags`). **`permission-guard.sh`'s header gives this as *twelve*; it counts
the two `git` pairs as the two acts they are, this section counts the four literal entries. Neither is
wrong and both are the wrong thing to check against** — see *record the derivation, not the count* below.
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
4. **Shadowed by an `allow`** — `Bash(gh -R:*)`, `Bash(git -C:*)`. The general form is the one worth
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

Two obligations follow, and they are cheap only if they are done at the time:

- **A migration into the hook is an amendment to this record**, not a comment in the rule. Three
  undocumented migrations in one day is what made this decision necessary; the fourth should append here.
- **A rule that a prefix CAN express stays in the floor.** Moving it for tidiness spends the fail-open
  budget for nothing. `claude mcp` is the worked example, named rather than omitted: no flag convention
  sits between the words and no `allow` entry shadows it, so the prefix matcher sees every spelling and
  the hook would add exactly zero.

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
