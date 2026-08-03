# 0007. The merge precondition is a floor, not an instruction

- **Status:** proposed
- **Date:** 2026-08-03
- **Deciders:** owner (ratifies) · `quality-assurance` and `security` (both subject to it)
- **Supersedes / superseded by:** **reverses [ADR-0006](./0006-a-verdict-owed-to-another-persona-is-an-artifact.md)'s rejected option 2** (gating `gh pr merge` on the marker's existence), answering that rejection on its own terms. *It does **not** rest on 0006's "revisit this option" clause — that clause belongs to its **option 3**, a different mechanism, and the first version of this header claimed it three times.*
- **Driven by:** the drift recorded in [ADR-0006](./0006-a-verdict-owed-to-another-persona-is-an-artifact.md), #135 and #136; opened after an owner-requested assessment of which harness mechanism each rule belongs in

## Context & problem

[ADR-0006](./0006-a-verdict-owed-to-another-persona-is-an-artifact.md) fixed the right half of a problem: a verdict owed to another persona now exists as a **comment on the PR** rather than as prose in an orchestrator's context, so it can be read rather than relayed.

What it did not fix is the other half. **The rule that reads that artifact is itself prose**, living in `agents/quality-assurance.md` — *do not merge until `security` has returned an approval; verify three conditions; a relay is not the authority*. It is an instruction to a model, executed by the same model it constrains, in a file that model also edits.

That is not hypothetical. In a single day, three separate drifts shipped in the vocabulary this rule depends on:

- `security.md` offered `ADVISORY-ONLY`, a literal the file never defined, and the merging gate checked against it — one invented literal live in two files
- `security.md` also read *"Lead with the verdict: clean, remediated, or blocked"* three sections below its own marker template — a third vocabulary, and the one that **actually fired**: a verdict line was once posted reading `CLEAN`, which the reading gate cannot parse
- `quality-assurance.md`'s own marker offered `APPROVED` while the set it defines is `APPROVE-AND-MERGE` / `APPROVE-PENDING-HUMAN` / `REQUEST-CHANGES`

All three were found by reading — by two gatekeepers and by the owner, across eight rounds of one PR and two of another. **None could have been found by a check**, and re-introducing any of them today goes green.

The deeper point is not the vocabulary. It is that **the strongest rule in the loop is enforced by the weakest mechanism available**. The harness offers several, and they are not interchangeable:

| mechanism | runs | can deny | sees |
| --- | --- | --- | --- |
| **hook** (`hooks.json` + script) | outside the model, on a tool call | **yes** | the tool call and live system state |
| **settings permission** | outside the model, on a matcher | yes | the command string only |
| **agent** (`agents/*.md`) | as a model, fresh context | no — it decides | whatever it reads |
| **skill / command** (`commands/*.md`) | as context, on invocation | no | whatever it is given |
| **`CLAUDE.md`** | as always-on context | no | static text |

`permission-guard.sh` already sits in the top row and is the reason the irreversible floor holds: no amount of misreading lets an agent `terraform destroy`.

**And the merge belongs in that row under the rule ADR-0004 has already decided.** Its line as decided: *"If the act **cannot be undone**, it needs a hook — `terraform destroy`, a force-push, `rm -rf`, a secret write, **a push to the trunk** all escape git, and no later commit undoes them."* A `gh pr merge` **is** that push — `permission-guard.sh`'s rule 7b says so in its own deny message, *"merging a PR is the deploy"*. What a later merge fixes is the **site**, which is a different object from the act: the deploy has fired, the release is cut, and an OG scraper has pinned the card it first fetched.

Two further variables, kept apart from that one because conflating them cost this record three rewrites: **decidability** bounds how much of the precondition a hook can carry — *do two markers parse at this `headRefOid`* is decidable by a script, *is the change right* is not and never becomes so — and **blast radius** decides how the hook fails when it cannot reach an answer, which is the fail-open section below.

> *Three earlier versions of this section argued the placement from the wrong variable, in both directions, and none of them had read the clause above. The history is left in the PR rather than here: a decision record is for the decision, and this one had grown longer in reasons about its own reasons than in reasons. `security` recorded the same lesson on ADR-0006 — the correction that finally held was deleting reasons, not adding them.*

## Decision drivers

- A rule whose violation ships to production must not depend on the constrained party reading it correctly.
- The three drifts above shared one shape: **the file said one thing and meant another, and nothing outside the file could tell.**
- There is a definite interception point. A merge is a `gh pr merge` invocation — a Bash tool call, which is where `PreToolUse` already fires twice.
- Whatever moves must not make the loop wedge. `wip-guard.sh` fails **open** deliberately; a discipline check that stops work is worse than the drift it prevents.
- Judgement must stay with the gate. Whether a change is *right* is not mechanisable and this decision must not pretend otherwise.

## Considered options

1. **A `PreToolUse` hook on `gh pr merge` that denies a merge lacking its gatekeeper markers** (chosen) — the hook reads the PR's comments and head, and denies unless both markers parse, carry a verdict literal from their persona's canonical set, and record the current `headRefOid`. *Trade-off:* a second network-dependent hook, and it forces the fail-open/fail-closed question to be answered explicitly rather than inherited.

2. **Keep it prose, and add the assertion from #136** — pin each persona's marker literals to its own canonical verdict set. *Why not:* it is worth doing and it is **not this**. That assertion proves the **file says** the right thing. It cannot prove the **gate did** the right thing at merge time — a gate that reads a perfectly consistent file and merges anyway is exactly the failure mode, and #136 is blind to it. Complementary, not a substitute.

3. **A `settings.json` deny rule on `gh pr merge`** — block the command outright and route every merge to the human. *Why not:* it deletes the safe class, which is the mechanism that makes the loop flow. The owner's 2026-07-30 decision moved reader-facing work *out* of the boundary class precisely to stop spending their attention on in-pattern merges; this would undo that wholesale to fix a narrower problem.

4. **The same hook, but `ask` instead of `deny`** — `permission-guard.sh` already has an `ask()` and rule 5c uses it for exactly this shape. *Why not, and it is close:* `ask` dissolves the fail-open dilemma entirely — a spurious `ask` costs one keystroke where a spurious deny wedges the loop, so the hook could then treat *cannot reach an answer* the same as *the answer is no*. It is rejected only because the loop's value is that in-pattern work merges without waking the owner, and a hook that asks on every merge converts the safe class into a prompt. **If the fail-open residual below turns out to bite in practice, this is the first thing to try** — it is a strictly smaller change than removing the hook. Recorded here rather than discovered later; `security` raised it, and it was absent from the first version of this record.

5. **Gate the COMMENT rather than the merge** — ADR-0006's own option 3: deny a `gh pr comment` whose body carries a marker naming a persona the caller is not running as. *Why not, and the reason is narrow:* ADR-0006 rejected it because it *"does not touch the failure that was observed"* — #127 was **omission**, and a hook refusing a forged marker never fires when there is nothing to forge. That still holds, and this ADR targets drift, where nothing is forged either. **But it is a complement to the author filter above, not an alternative to it**: a stranger's comment never passes through the harness at all, so it defends a different door. Recorded here because the first version of this record omitted it while claiming its revisit clause — citing an option it had not considered.

6. **A required GitHub status check** — enforce it at the forge rather than in the harness. *Why not:* the markers are comments, and a check would have to be posted by the same token the gatekeepers write with, so it inherits the impersonation residue ADR-0006 already records **without** gaining the interception. It also only works where branch protection does; `main` here is the working branch.

## Decision outcome

**This reverses ADR-0006's option 2, and the reversal has to answer that record's own reason rather than ignore it.** It rejected gating rule 7b on the ground that *"a hook buys the same guarantee as the artifact, because a context willing to fabricate the comment is a context that would equally spawn `security` and ignore its verdict."*

**That argument is about impersonation, and it is correct about impersonation.** A context prepared to forge a marker is not stopped by a hook that reads markers — ADR-0006 says so, this record agrees, and nothing here claims otherwise.

**It does not reach drift, which is a different failure and the one that has now fired three times.** A gate that publishes `CLEAN` as a verdict line is not fabricating anything. It is not ignoring `security` — it dispatched it, read the comment, and applied a vocabulary its own file contradicted. Against a party doing its honest best with a wrong rule, a hook buys exactly what the artifact does not: **it is not reading the rule.** That is the whole difference, and it is why the same mechanism rejected **yesterday** is right today. *(The first version said "fourteen days ago" — ADR-0006 is dated 2026-08-02 and this one 2026-08-03. The error ran in the reversal's own favour, making the change of mind look considered rather than same-week, and the argument does not need it.)*

The other half of ADR-0006's rejection — the parsing cost, rule 5d's four rounds and eighty deleted lines — is **not disputed and not discounted**. It is booked below as an accepted cost.

Chosen: **the hook on `gh pr merge`**, because the act is one ADR-0004 already places behind a hook, the precondition is mechanically decidable, and the party it binds is the one reading it.

*Named rather than numbered, deliberately — an earlier draft said "options 2, 3 and 5" and a single inserted option falsified it. A cross-reference by position is a derived value with nothing keeping it true, which is this record's own subject.*

The **assertion**, the **settings deny** and the **status check** all leave the gate applying its own instructions to itself, which is the assumption that failed three times in one day. **`ask` instead of `deny`** is the same mechanism at a different severity and is not rejected on principle — it is held in reserve, for the reason recorded there. **Gating the comment** is not an alternative at all but a complement, and is left for the slice that implements the author filter.

**Scoped to the markers, and the ratification half deliberately stays prose.** The first version of this decision also covered *"the owner's ratification for the boundary class"*, and that cannot be mechanised: **safe-vs-boundary is a judgement the hook cannot derive.** It would have to either demand ratification on every merge — which deletes the safe class, and is why the **settings-deny** option is rejected above — or take the class from the constrained party, putting the protection at its weakest exactly where drift is most dangerous. *"The reviewer never merges an expansion of its own authority"* names precisely the case a drifting gate would call safe. A mechanism strong where the stakes are low and absent where they are high is worse than an honest boundary, because it reads as coverage.

**The markers must carry an author and association check, and this is a trust class neither existing hook takes.** This repository is **public**, so PR comments are **world-writable**: a precondition testing only the marker line, the verdict literal and the head SHA can be satisfied by a drive-by account. That is not the impersonation residue ADR-0006 records — that one is a trusted party writing with the right token — it is an untrusted stranger, and `wip-guard.sh` reads only repo-controlled metadata. The filter is `author.login` plus **`authorAssociation: OWNER`, and nothing wider**. A human reviewer sees a stranger's byline; a regex does not.

> **That set is chosen here, not inherited, and an earlier version of this paragraph got both halves wrong.** It said the filter was *"the idiom ADR-0003 already uses"* and specified `OWNER`/`MEMBER`/`COLLABORATOR`. **This repo's ADR-0003 carries no such idiom** — it is the Definition of Done. The idiom is in the *consuming* repo's [ADR-0003](https://github.com/tedeuxx/tadeumendonca-io/blob/main/docs/adr/0003-trunk-based-single-environment.md), and it admits **`OWNER` alone**. So the set was widened in the borrowing, the widening was argued nowhere, and the consequence was then booked as inherited. Found by `security`, and it is the same shape as its round-1 finding on this record: a link line crediting a sibling document with a property it does not have.
>
> **`OWNER` alone is also the right set on the merits, not merely the conservative one.** These markers are written by the harness with the token it already holds, so the party the hook must recognise is the account that runs it. Nothing about a gatekeeper's verdict needs a wider association, and a control whose whole purpose is to exclude a stranger should not start by admitting a class it has no use for.

**Two constraints inherited rather than rediscovered**, both already paid for by the existing hooks: collapse quoted spans before matching the command, or a commit message quoting `gh pr merge` triggers a network round-trip; and match the marker on the **first line only**, never "contains" — the literal appears in both persona files, in this ADR, and in every review comment discussing it.

**And the floor it replaces is not nothing.** `permission-guard.sh` rule **7b** already denies `gh pr merge` from any `agent_type` other than `quality-assurance`, with **no network call**. So failing open degrades to today's posture rather than to an open door — which is the strongest argument for the fail-open choice below, and it came from `security` rather than from this ADR's author.

**Fail OPEN, and this is the deliberate part.** The reflex is to say a floor fails closed, and `permission-guard.sh` is invoked as the precedent. That reasoning does not survive contact with what the two hooks actually protect:

- `permission-guard.sh` denies things that are **irreversible in the world** — `terraform destroy`, a force-push, a secret write. A missed deny is unrecoverable; a spurious deny costs a retry.
- This hook denies a merge that **has not yet been reviewed**. A missed deny produces a merge the gatekeepers would very likely have approved anyway, on a repo whose deploy is revertible. A spurious deny — no network, `gh` unauthenticated, the API slow — **wedges every merge in the loop**, which is the failure this whole architecture exists to avoid.

**And the fail-open set has to be pinned, because the obvious phrasing defeats the incident that motivated this.** "Fails open on any error it cannot resolve" would fail open on an unparseable verdict line — and an unparseable verdict line is exactly what fired (`CLEAN`). The slogan is right and the set was wrong:

| the check | outcome |
| --- | --- |
| **could not run** — no network, `gh` unauthenticated, timeout, API error, malformed payload | **allow.** An answer we could not get is not a verdict. |
| **ran, and the answer is negative** — a marker is absent, its verdict literal is outside the persona's canonical set, or its head does not match | **deny.** This *is* a verdict, and it is the one the hook exists to enforce. |

Unreadable is the second row, not the first. The distinction is *did the check reach an answer*, never *was the answer convenient*.

**And the second row needs a qualifier, because otherwise this ADR relocates drift instead of removing it.** A negative is a verdict **only when its inputs were complete and current**. The instance that matters: the hook has to know each persona's canonical verdict set, and **that copy can go stale**. Then the check runs, the literal is legitimately new, the table above calls the negative a verdict — and the hook denies **every merge** until someone edits the script. That is the hook drifting, in a record whose whole subject is drift, and it flips the failure from a silent allow into a wedged loop, which is precisely the trade fail-open was chosen to avoid. Same for a truncated comment read or a degraded `authorAssociation`: inputs that are not complete do not produce verdicts.

The mitigation is not new machinery. Read the canonical set **from the persona file at runtime** rather than keeping a copy, or extend #136's pinning to the hook's copy so the two cannot separate. Nothing pins that vocabulary today, which is why this is stated as a constraint on the implementation rather than assumed away. Found by `security`.

What it must never do is fail open **silently**: an unresolved check prints what it could not determine.

**What does not move.** The gate's judgement stays in `agents/quality-assurance.md` — whether the Issue's requirements were met, whether the class is safe or boundary, whether a finding blocks. The hook checks that the **artifacts exist and match the head**; it has no opinion about whether they are right.

## Consequences

**Good**
- The precondition holds even when the gate misreads its own file — which is the observed failure, not a theoretical one.
- The three drifts above become unable to produce a bad merge. A marker whose verdict line is unparseable stops the merge instead of being interpreted.
- The rule gains a single mechanical definition. Today it exists as prose in one persona file and is *described* in another, and those two can disagree without either being wrong.

**Bad / accepted costs**
- **A second network-dependent `PreToolUse` hook on every Bash call.** `wip-guard.sh` already pays this and is budgeted at 10s. Two hooks doing `gh` calls on unrelated Bash commands is real latency for no benefit on the ~99% of calls that are not merges, so the hook must exit before any network work when the command is not a merge.
- **Fail-open means this is not airtight, and unlike its sibling it is UNBACKED.** `permission-guard.sh` can afford to fail open because `settings.json`'s `deny` list is its named backstop. This hook has none: `Bash(gh pr merge:*)` sits in the consuming repo's **allow** list. So where the sibling's fail-open degrades to a second mechanism, this one degrades to `permission-guard` rule **7b** alone — which denies `gh pr merge` from any agent other than `quality-assurance`, with no network, and is therefore real but narrower. The first version of this record priced the residual as *"needing the network to be down at the same moment"*, which understated it: `wip-guard.sh` records `permission-guard` emitting no decision at all with `jq` off PATH. The **`ask` instead of `deny`** option above is the answer if this bites.
- **"Floor" is a term of art in this repo** for `permission-guard`'s irreversible set, and this hook is not that. The qualification is in the Decision outcome, well below a title that carries none — so a skimmer gets the stronger word without the caveat. *(This bullet used to state the distance as a line count, which drifted the moment the document grew. A derived number nothing keeps true, in the record about files drifting from what they say.)* Kept because the alternative titles were worse, and named here so the index row can carry the qualifier.
- **The measured cost ADR-0006 recorded for this option is real and inherited.** It rejected gating rule 7b partly on the parsing: a bare `gh pr merge` names no PR, and rule 5d took four rounds and eighty deleted lines to get command parsing right. This ADR reverses that rejection on the impersonation-versus-drift argument above, not by claiming the parsing got cheaper.
- **The impersonation residue is unchanged.** The hook reads comments written with the same token the agent holds, so a determined agent could still write both markers. ADR-0006 already records this and accepts it. **Scoped deliberately: that sentence is about the party *inside* the harness**, and this record no longer generalises it to "the adversary is not hostility" — it mandates a control against a hostile stranger in the Decision above. Against the insider the mechanism addresses drift; against the outsider it addresses forgery. Two adversaries, one hook, and the first version of this bullet named only one of them.
- **The stranger class this ADR introduces has its own residual, and it needs a line in the ledger rather than only a paragraph in the Decision.** Because the repository is public, the author filter is what stands between a drive-by comment and a merge, and **that filter is now the whole control** — there is no second mechanism behind it. Pinned to `OWNER` alone it is as narrow as this harness can make it, and the residual is what that narrowness cannot cover: **the token the harness runs with IS the owner's**, so the filter separates outsiders from the harness, never the harness from itself. That is ADR-0006's impersonation residue arriving by a second route, and it is unchanged by this hook.
  - *The first version of this bullet booked a different residual — that the filter admitted `COLLABORATOR` — and presented it as inherited from a sibling record. Both halves were wrong: the widening was introduced here, and it has since been removed. Kept as a note because a ledger entry that misstates which risk is accepted is worse than a missing one, and this is the entry the next person auditing the control will read.*
- **Two mechanisms now encode part of one rule** — the hook (artifacts present and current) and the persona file (what they mean). That is the split this ADR argues for, but it is still a seam, and a change to the marker shape must move both.

## Links
- [ADR-0006](./0006-a-verdict-owed-to-another-persona-is-an-artifact.md) — the verdict as artifact; this ADR enforces what that one made readable
- [ADR-0003](./0003-mr-definition-of-done.md) — the Definition of Done this gate reviews against. **It is not the source of the author-and-association idiom**, and this hook does not check any ratification rule. *(Two corrections live in this one line, both found by a gatekeeper and both the same shape — crediting a sibling record with a property it does not have. It first said the hook "would also check" the ratification, which was true only of the wider scope and survived the narrowing. It then said this record was the source of the author filter; that idiom is in the **consuming repo's** ADR-0003, linked in the Decision outcome, and it admits `OWNER` alone.)*
- [ADR-0004](./0004-autonomy-and-permission-model.md) — the permission floor and `permission-guard.sh`, the sibling hook this one is deliberately weighed against

> **A correction, kept rather than edited away.** The first version of this line said `permission-guard.sh` has a *fail-closed rule* that this hook does not inherit. **It has no such rule** — its own contract header reads *"Fails OPEN (allows) on any parse error"*, and the claim that it fails closed was **struck from `wip-guard.sh` on 2026-08-02**, with a measured falsifier (`jq` off PATH → no decision emitted → a `git push origin main` is allowed). That header also names *what the floor should do when it cannot read its input* as an explicitly **open** question. This ADR had closed it by assertion, in a link line, in the document whose entire subject is claims that read one way and mean another. Found by `security` on this PR.
- #136 — pinning marker literals to each persona's canonical set; complementary, and explicitly not a substitute
- #134 — the marker's retirement mechanism, unsolved; a hook reading markers depends on that question having an answer
