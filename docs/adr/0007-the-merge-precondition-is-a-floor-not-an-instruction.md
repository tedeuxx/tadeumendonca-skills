# 0007. The merge precondition is a floor, not an instruction

- **Capability:** controls-and-enforcement
- **Status:** proposed · **amended 2026-08-04** (the precondition is **one** marker, not two — `security`
  is absorbed into `quality-assurance` per [ADR-0002](./0002-agentic-dev-loop-architecture.md) amendment
  #10. Status is **unchanged**: the hook is unimplemented, so nothing running is affected. The decision,
  the author filter and the whole outcome table stand; the argument for the hook gets **stronger**,
  because the one surviving marker is the merging gate's own and ADR-0006's fourth amendment has just
  recorded it as self-enforced)
- **Date:** 2026-08-03
- **Deciders:** owner (ratifies) · `quality-assurance` and `security` (both subject to it)
- **Supersedes / superseded by:** **reverses [ADR-0006](./0006-verification-and-its-artifacts.md)'s rejected option 2** (gating `gh pr merge` on the marker's existence), answering that rejection on its own terms
- **Driven by:** the drift recorded in [ADR-0006](./0006-verification-and-its-artifacts.md), #135 and #136; opened after an owner-requested assessment of which harness mechanism each rule belongs in

## Context & problem

[ADR-0006](./0006-verification-and-its-artifacts.md) fixed the right half of a problem: a verdict owed to another persona now exists as a **comment on the PR** rather than as prose in an orchestrator's context, so it can be read rather than relayed.

It did not fix the other half. **The rule that reads that artifact is itself prose**, living in `agents/quality-assurance.md` — an instruction to a model, executed by the same model it constrains, in a file that model also edits.

That is not hypothetical. In a single day, three drifts shipped in the vocabulary this rule depends on:

- `security.md` offered `ADVISORY-ONLY`, a literal the file never defined, and the merging gate checked against it
- `security.md` also read *"Lead with the verdict: clean, remediated, or blocked"* three sections below its own marker template — a third vocabulary, and the one that **actually fired**: a verdict line was once posted reading `CLEAN`, which the reading gate cannot parse
- `quality-assurance.md`'s own marker offered `APPROVED` while the set it defines is `APPROVE-AND-MERGE` / `APPROVE-PENDING-HUMAN` / `REQUEST-CHANGES`

All three were found by reading. **None could have been found by a check**, and re-introducing any of them today goes green.

The deeper point is not the vocabulary. It is that **the strongest rule in the loop is enforced by the weakest mechanism available**. The harness offers several, and they are not interchangeable:

| mechanism | runs | can deny | sees |
| --- | --- | --- | --- |
| **hook** (`hooks.json` + script) | outside the model, on a tool call | **yes** | the tool call and live system state |
| **settings permission** | outside the model, on a matcher | yes | the command string only |
| **agent** (`agents/*.md`) | as a model, fresh context | no — it decides | whatever it reads |
| **skill / command** (`commands/*.md`) | as context, on invocation | no | whatever it is given |
| **`CLAUDE.md`** | as always-on context | no | static text |

`permission-guard.sh` is a **hook** — the mechanism that runs outside the model and can deny — and it is the reason the irreversible floor holds: no amount of misreading lets an agent `terraform destroy`.

**And the merge belongs in that row under the rule ADR-0004 has already decided.** Its line as decided: *"If the act **cannot be undone**, it needs a hook — `terraform destroy`, a force-push, `rm -rf`, a secret write, **a push to the trunk** all escape git, and no later commit undoes them."* A `gh pr merge` **is** that push — `permission-guard.sh`'s rule 7b says so in its own deny message, *"merging a PR is the deploy"*. What a later merge fixes is the **site**, which is a different object from the act: the deploy has fired, the release is cut, and an OG scraper has pinned the card it first fetched.

Two further variables, kept apart from that one: **decidability** bounds how much of the precondition a hook can carry — *do two markers parse at this `headRefOid`* is decidable by a script, *is the change right* is not and never becomes so — and **blast radius** decides how the hook fails when it cannot reach an answer, which the outcome table settles.

## Decision drivers

- A rule whose violation ships to production must not depend on the constrained party reading it correctly.
- The three drifts above shared one shape: **the file said one thing and meant another, and nothing outside the file could tell.**
- There is a definite interception point. A merge is a `gh pr merge` invocation — a Bash tool call, which is where `PreToolUse` already fires twice.
- Nothing may wedge the loop **on the ordinary path** — the case where everything is working and nobody did anything wrong. `wip-guard.sh` fails **open** deliberately on that ground: a *discipline* check that stops ordinary work is worse than the drift it prevents. It is not an argument against wedging on a **negative answer**, which is the point of a gate, nor against wedging on an input an outsider tampered with, which this decision accepts by name.
- Judgement must stay with the gate. Whether a change is *right* is not mechanisable and this decision must not pretend otherwise.

## Considered options

1. **A `PreToolUse` hook on `gh pr merge` that denies a merge lacking its gatekeeper markers** (chosen) — the hook reads the PR's comments and head, **discards every comment not authored by `OWNER`**, and then denies unless both surviving markers parse, carry a verdict literal from their persona's canonical set, and record the current `headRefOid`. *Trade-off:* a second network-dependent hook, and it forces the question *what happens when the check cannot answer* to be settled explicitly rather than inherited — which turned out to have more than the two answers that framing assumes.

2. **Keep it prose, and add the assertion from #136** — pin each persona's marker literals to its own canonical verdict set. *Why not:* it is worth doing and it is **not this**. That assertion proves the **file says** the right thing. It cannot prove the **gate did** the right thing at merge time — a gate that reads a perfectly consistent file and merges anyway is exactly the failure mode, and #136 is blind to it. Not a substitute, and **load-bearing rather than merely adjacent**: this decision has the hook read the canonical set from the persona file at runtime, and nothing today keeps a marker template from diverging from the set beside it in the same file.

3. **A `settings.json` deny rule on `gh pr merge`** — block the command outright and route every merge to the human. *Why not:* it deletes the safe class, which is the mechanism that makes the loop flow. The owner's 2026-07-30 decision moved reader-facing work *out* of the boundary class precisely to stop spending their attention on in-pattern merges; this would undo that wholesale to fix a narrower problem.

4. **The same hook, but `ask` instead of `deny`** — `permission-guard.sh` already has an `ask()` and rule 5c uses it for exactly this shape. **Partially adopted**, and the split is the decision: a missing tool **denies** before either question is asked; otherwise `ask` **only** where the check could not run *and* no outsider could have caused that, `deny` in every remaining case. *Why not for everything:* the loop's value is that in-pattern work merges without waking the owner, and a hook that asks on **every** merge converts the safe class into a prompt.

5. **Gate the COMMENT rather than the merge** — ADR-0006's own option 3: deny a `gh pr comment` whose body carries a marker naming a persona the caller is not running as. *Why not, and the reason is narrow:* ADR-0006 rejected it because it *"does not touch the failure that was observed"* — #127 was **omission**, and a hook refusing a forged marker never fires when there is nothing to forge. That still holds, and this ADR targets drift, where nothing is forged either. **But it is a complement to the author filter, not an alternative to it**: a stranger's comment never passes through the harness at all, so it defends a different door.

6. **A required GitHub status check** — enforce it at the forge rather than in the harness. *Why not:* the markers are comments, and a check would have to be posted by the same token the gatekeepers write with, so it inherits the impersonation residue ADR-0006 already records **without** gaining the interception. It also only works where branch protection does; `main` here is the working branch.

## Decision outcome

**This reverses ADR-0006's option 2, and the reversal answers that record's own reason rather than ignoring it.** It rejected gating rule 7b on the ground that *"a hook buys the same guarantee as the artifact, because a context willing to fabricate the comment is a context that would equally spawn `security` and ignore its verdict."*

**That argument is about impersonation, and it is correct about impersonation.** A context prepared to forge a marker is not stopped by a hook that reads markers.

**It does not reach drift, which is a different failure and the one that has fired.** A gate that publishes `CLEAN` as a verdict line is not fabricating anything. It dispatched `security`, read the comment, and applied a vocabulary its own file contradicted. Against a party doing its honest best with a wrong rule, a hook buys exactly what the artifact does not: **it is not reading the rule.**

ADR-0006's measured cost for this option — the PR-number parsing, rule 5d's four rounds and eighty deleted lines — is **not disputed and not discounted**. It is booked below.

Chosen: **the hook on `gh pr merge`**, because the act is one ADR-0004 already places behind a hook, the precondition is mechanically decidable, and the party it binds is the one reading it. The **assertion**, the **settings deny** and the **status check** all leave the gate applying its own instructions to itself. **Gating the comment** is a complement, left for the slice that implements the author filter.

**Scoped to the markers, and the ratification half deliberately stays prose.** Safe-vs-boundary is a judgement the hook cannot derive. It would have to either demand ratification on every merge — deleting the safe class — or take the class from the constrained party, putting the protection at its weakest exactly where drift is most dangerous. *"The reviewer never merges an expansion of its own authority"* names precisely the case a drifting gate would call safe.

**The markers carry an author check, and this is a trust class neither existing hook takes.** This repository is **public**, so PR comments are **world-writable**: a precondition testing only the marker line, the verdict literal and the head SHA can be satisfied by a drive-by account. That is not the impersonation residue ADR-0006 records — a trusted party writing with the right token — it is an untrusted stranger, and `wip-guard.sh` reads only repo-controlled metadata.

The filter is `author.login` plus **`authorAssociation: OWNER`, and nothing wider**. That set is chosen here, not inherited: this repo's Merge Request Definition of Done carries no such idiom, and the consuming repo's own third record, [trunk-based, single environment](https://github.com/tedeuxx/tadeumendonca-io/blob/main/docs/adr/0003-trunk-based-single-environment.md), admits `OWNER` alone. (Both were written as a prefixed citation of number 0003 until 2026-08-19 — two different records under one token, in one sentence, which is the collision the citation gate's own header names as unresolvable from here. The local half is now [ADR-0006](./0006-verification-and-its-artifacts.md)'s *Merge Request Definition of Done* section; the cross-repo half is named by title so nothing reads it as local.) It is also right on the merits — these markers are written by the harness with the token it already holds, so the party to recognise is the account that runs it.

**Two constraints inherited rather than rediscovered**, both already paid for by the existing hooks: collapse quoted spans before matching the command, or a commit message quoting `gh pr merge` triggers a network round-trip; and match the marker on the **first line only**, never "contains" — the literal appears in both persona files, in this ADR, and in every review comment discussing it.

**And the floor it layers on is not nothing.** `permission-guard.sh` rule **7b** already denies `gh pr merge` from any `agent_type` other than `quality-assurance`, with **no network call**. So a hook that cannot answer degrades to today's posture rather than to an open door — which is the strongest argument for not making the *outsider-proof* unresolved case a hard deny, and exactly the slice `ask` covers.

### What the hook does when it cannot answer

| the check | outcome |
| --- | --- |
| **a tool it needs is absent** — `gh`, `jq` | **deny**, emitted by a path that does not use the missing tool, evaluated **after** the command is known to be a merge and **before** either question below — see the ordering conjunction. |
| **ran, and the answer is negative** — a marker is absent, its verdict literal is outside the persona's canonical set, or its head does not match | **deny.** This *is* a verdict, and it is the one the hook exists to enforce. |
| **could not run, and no outsider could have caused it** — no network, `gh` unauthenticated, credentials rejected | **ask.** An answer we could not get is not a verdict, and it is not a licence either. |
| **could not run, and an outsider could have caused it** — the deadline fired, the response came back short, `authorAssociation` came back degraded, the API returned an error | **deny.** Ask is the owner's attention, and attention a stranger can summon on demand is a resource this loop rations. |

**Two questions, asked in order, after the tool row.** First: *did the check reach an answer?* If it did, the answer decides — **affirmative allows, negative denies**, and the affirmative is the only path **through this check** to an allow. If it did not: *could someone outside the trust boundary have caused this?* Proven not, **ask**. Otherwise — including **cannot be shown either way** — **deny**.

**The default is deny, and it is stated because it is not derivable at runtime.** *Could an outsider have caused this* is an analytic label assigned to named causes; the hook sees an error signal, not its causability. The cause lists above are **examples, not an enumeration** — a 5xx, a secondary rate limit, a changed JSON shape all arrive unlabelled. Routing the unlabelled remainder to `ask` would put the implementer's `else` on the branch the general rule below forbids.

**Why the tool row comes first.** A missing tool is the most provably outsider-proof failure there is, so both questions would route it to `ask` — and `ask()` builds its JSON with `jq`, exactly as `deny()` does. The hook would then emit nothing, and nothing reads as allow: a merge with no marker verified. So **no payload may be constructed by a tool whose absence is one of the causes it reports**. Its siblings: the deadline below must be enforced without `timeout(1)`, absent on this platform, and the merge detection below must not need the tool it is about to check for. Three instances of one lesson — **a control cannot depend on the thing whose failure it exists to report** — and each was found only after the previous one was fixed.

**The ordering is a conjunction, and stating only one half reopens the hole on the other side.** *Before either question* is not enough: the questions are about the marker, which is downstream of deciding the command **is** a merge — and that decision reads `.tool_input.command` from stdin **with `jq`** (`permission-guard.sh:35`, whose next line bare-exits on an empty command; `wip-guard.sh:57`). An implementer who parses, detects the merge, then checks tools has satisfied that phrasing, and with `jq` absent the parse yields nothing, the hook exits, the tool row never evaluates, and nothing is emitted — which reads as allow. *Before any parse* alone is worse: the row would then fire before the command is known to be a merge, so an absent `gh` would deny **every Bash call in every consuming repo**, and an absent `gh` is ordinary.

Both halves, together:

> 1. **Merge detection is itself performed without the tool whose absence it reports** — so the tool row is reachable when that tool is gone.
> 2. **The tool row fires only once the command is known to be a merge** — so a missing tool never denies unrelated Bash calls.

This is the same shape as the emitter and the deadline: the input read is one more thing the control cannot depend on to report its own failure. `wip-guard.sh` and `permission-guard.sh` both parse with `jq` first and reach `command -v` afterwards, so **the local idiom is the wrong order here** and an implementer copying the file beside them lands in the hole.

**No cause routed to ASK may be selectable by anyone outside the trust boundary.** The author filter removes the instance where a stranger posts an unparseable comment; it does not by itself establish the class, because a stranger can also act on the **read**, which happens upstream of any filter.

The general rule, worth more than the instance: **any branch of a control that does not deny, reachable by an untrusted party, is a published bypass.** Any cause routed to `ask` has to be checked against it.

**An incomplete read denies.** The author filter can only discard what the read returned, and the read is over a **world-writable, unbounded list**: `gh pr view --json comments` returns a bounded page, and on a public repository the comment count is attacker-controlled. So a stranger who cannot forge a marker can still act on this control by making the markers fall outside the window. Both outcomes have to be chosen deliberately:

> **A stranger may be able to cost the loop a wedge. A stranger may never be able to cost it a merge.**

So a read that **did not find both markers** denies, whatever the reason. A **degraded `authorAssociation` fails to DISCARD**, not to allow — a filter that cannot establish authorship must exclude the comment, never admit it.

**The hook reads each persona's canonical verdict set from the persona file at runtime** rather than holding a copy, so *"the copy went stale"* is not a state that exists. Extending #136's pinning to a copy is the weaker alternative: it makes the two files fail together instead of making them one.

**The read is bounded.** The hook fetches a fixed-size page, never paginates, and holds its own deadline strictly below the `timeout` its own `hooks.json` entry declares — the values are per entry, live at 5 for `permission-guard.sh` and 10 for `wip-guard.sh`, with no global cap. The page bounds how many comments are read; the deadline bounds the wait regardless. A hook that speaks before the kill is never killed silently.

The page bounds **count, not bytes** — a stranger cannot choose how many comments are read, and nothing stops them making the ones inside that window large. The deadline covers the remainder, which is why it is a requirement rather than a refinement.

**An unresolved check prints what it could not determine**, whichever way it then routes: it is what makes an `ask` actionable and a `deny` diagnosable.

**What does not move.** The gate's judgement stays in `agents/quality-assurance.md` — whether the Issue's requirements were met, whether the class is safe or boundary, whether a finding blocks. The hook checks that the **artifacts exist and match the head**; it has no opinion about whether they are right.

## Consequences

**Good**
- The precondition holds even when the gate misreads its own file — which is the observed failure, not a theoretical one.
- The three drifts above stop producing a bad merge **through this check**. A marker whose verdict line is unparseable stops the merge instead of being interpreted.
- The rule gains a single mechanical definition. Today it exists as prose in one persona file and is *described* in another, and those two can disagree without either being wrong.

**Bad / accepted costs**
- **A second network-dependent `PreToolUse` hook on every Bash call.** `wip-guard.sh` already pays this and is budgeted at 10s. Two hooks doing `gh` calls on unrelated Bash commands is real latency for no benefit on the ~99% of calls that are not merges, so the hook must exit before any network work when the command is not a merge.
- **The kill sits above this hook.** `hooks.json` kills a hook at the `timeout` its own entry declares, and a killed hook emits no decision, which the harness treats as **allow**. The deadline requirement means the hook has already answered when the kill arrives — but the path is bounded, not removed.
- **The one path that still ends in a merge nobody checked is UNBACKED, unlike its sibling's.** `permission-guard.sh` can afford a missed deny because `settings.json`'s `deny` list is its named backstop. This hook has none: `Bash(gh pr merge:*)` sits in the consuming repo's **allow** list. So where the sibling degrades to a second mechanism, this one degrades to rule **7b** alone — real, and narrower.
- **A stranger retains one effect on this control, and it is a wedge rather than a merge.** Comment volume can push the markers out of the fetched window, which denies. An outsider can therefore cost the loop a stalled merge until a human looks. Accepted as the safe side of a choice that had to be made.
- **The impersonation residue is unchanged, and the filter does not reach it.** The hook reads comments written with the same token the agent holds, so a determined agent could still write both markers — and the token the harness runs with **is** the owner's, so the author filter separates outsiders from the harness, never the harness from itself. ADR-0006 records this and accepts it; against the insider this addresses drift, against the outsider it addresses forgery.
- **"Floor" is a term of art in this repo** for `permission-guard`'s irreversible set, and this hook is not that. The title carries the stronger word without the caveat; the index row carries the decision's shape instead.
- **The fallback floor has a hole this hook reproduces, and the two do not cover for each other.** `permission-guard.sh` books it at line 335: *"a raw `gh api ... PUT .../merges` is NOT matched"*. This hook matches the same surface — `gh pr merge` — so one command form walks past **both** at once, and the argument that a hook which cannot answer degrades to rule 7b is only true for the forms 7b actually sees.
- **The measured cost ADR-0006 recorded for this option is real and inherited.** It rejected gating rule 7b partly on the parsing: a bare `gh pr merge` names no PR, and rule 5d took four rounds and eighty deleted lines to get command parsing right. This ADR reverses that rejection on the impersonation-versus-drift argument, not by claiming the parsing got cheaper.
- **Two mechanisms now encode part of one rule** — the hook (artifacts present and current) and the persona file (what they mean). That is the split this ADR argues for, but it is still a seam, and a change to the marker shape must move both.

## Links
- [ADR-0006](./0006-verification-and-its-artifacts.md) — the verdict as artifact; this ADR enforces what that one made readable, and reverses its rejected option 2
- The Definition of Done this gate reviews against — record 0003 until 2026-08-19, now the *Merge Request Definition of Done* section of [ADR-0006](./0006-verification-and-its-artifacts.md). **Not the source of the author-and-association idiom**, and this hook checks no ratification rule.
- [ADR-0004](./0004-autonomy-and-permission-model.md) — the permission floor and `permission-guard.sh`, whose decided rule places a push to the trunk behind a hook. *That record's contract header reads "Fails OPEN (allows) on any parse error" — it has no fail-closed rule, and the claim that it did was struck from `wip-guard.sh` on 2026-08-02 with a measured falsifier.*
- #136 — pinning marker literals to each persona's canonical set. Load-bearing for the hook slice rather than merely adjacent.
- #134 — the marker's retirement mechanism, unsolved; a hook reading markers depends on that question having an answer.

## Amendment (2026-08-04) — the precondition is ONE marker, not two, and the decision survives the change

**Status is still `proposed` and this amendment does not advance it.** The hook is **unimplemented** —
`grep gatekeeper-verdict hooks/` returns nothing — so **nothing in the running system is wrong today**.

> **The falsifier above expired on 2026-08-05, and the conclusion it supported did not.** That `grep`
> now returns hits, from `session-wip.sh` and its suite — a **SessionStart reader** that annotates an
> open PR carrying no verdict on its current head. It decides nothing and blocks nothing. **This
> record's hook — the one that DENIES a merge lacking the marker — is still unimplemented**, and the
> command that used to prove it no longer can.
>
> Kept rather than rewritten, because the sentence is the reason the next sweep must not trust it: a
> grep for a *string* was standing in for the existence of a *control*, and the first artifact to
> mention the string in passing broke the proxy. To check the claim now, look for a hook that returns
> a `deny` decision on `gh pr merge` — `permission-guard.sh`'s rule 7b routes that merge to the gate
> persona but asserts nothing about a verdict. Reading the marker as a merge precondition remains
> undone.

What would have been wrong is the slice that implemented this record as written: it enumerates *both
markers*, and one of the two personas no longer exists.

**Cause:** [ADR-0002](./0002-agentic-dev-loop-architecture.md)'s amendment #10 — `security` is absorbed
into `quality-assurance`, which now holds delivery and production as **two lenses in one pass**.

### What changes: the count, and only the count

> Every *"both markers"* in this record reads **the marker**. The chosen option becomes: the hook reads
> the PR's comments and head, discards every comment not authored by `OWNER`, and **denies unless
> `quality-assurance`'s marker parses, carries a verdict literal from that persona's canonical set, and
> records the current `headRefOid`.**

Nothing else in the decision moves, and each part is checked here rather than assumed:

- **The author filter** (`author.login` + `authorAssociation: OWNER`) — unchanged. It defends against an
  outsider on a public repo, which has nothing to do with how many gates exist.
- **The outcome table** — unchanged in all four rows. A missing tool still **denies** before either
  question; an answered-negative still **denies**; unanswerable-and-outsider-proof still **asks**;
  everything else still **denies**.
- **The ordering conjunction, the bounded read, the deadline, the emitter constraint** — all unchanged.
  *"A control cannot depend on the thing whose failure it exists to report"* is not a statement about
  the roster.
- **The scope** — the ratification half still stays prose, for the reason given: safe-versus-boundary is
  a judgement the hook cannot derive.
- **Rule 7b remains the fallback floor**, and the *"degrades to today's posture"* argument is unaffected.

### What changes in KIND, and it is why this needed an amendment rather than a search-and-replace

**The hook is now checking the merging gate's own marker, and only that.** Before, one of the two
markers it read was written by a party that does **not** merge — so at least one input to the
precondition came from outside the party the precondition binds.

That property is gone, and it makes this record's central argument **stronger, not weaker**, which is
the non-obvious part and the reason it is written down:

> The decision was always justified by **drift**, not impersonation — *"against a party doing its honest
> best with a wrong rule, a hook buys exactly what the artifact does not: **it is not reading the
> rule**."* [ADR-0006](./0006-verification-and-its-artifacts.md)'s fourth amendment
> records that the gate-reads-gate check has lost its subject and the remaining verdict is now
> **self-enforced**. A self-enforced precondition is precisely the configuration this record exists to
> object to.

So the roster change **raises** the value of implementing this hook. Stated plainly because the opposite
reading is available and wrong: *"one gatekeeper, so half the precondition, so half the point."* Half
the markers, and the remaining one is the one nobody else checks.

### The cost that got worse, named

**The impersonation residue is unchanged, and the surface it covers is now the whole precondition.**
This record already books that the harness holds the owner's token, so the author filter *"separates
outsiders from the harness, never the harness from itself."* With two markers, a self-fabricating gate
had to fabricate a verdict attributed to a persona it was not. With one, the marker it must produce is
its own. Against **drift** the hook still works — a drifting gate posts an unparseable literal and is
stopped. Against a gate that decides to post an approval it does not mean, this buys nothing, and never
claimed to.

**And the seam this record books grows no wider:** *"two mechanisms now encode part of one rule"* still
holds, with one fewer persona file on the far side of it.

---

*This record was revised across fifteen review rounds before merging. The corrections, the superseded framings and the findings that produced them are in [PR #138](https://github.com/tedeuxx/tadeumendonca-skills/pull/138) — deliberately there and not here. Carrying them inline made every edit falsify a neighbouring note, which is the failure this record exists to describe, performed on itself.*
