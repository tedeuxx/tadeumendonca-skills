# 0007. The merge precondition is a floor, not an instruction

- **Status:** proposed
- **Date:** 2026-08-03
- **Deciders:** owner (ratifies) · `quality-assurance` and `security` (both subject to it)
- **Supersedes / superseded by:** **reverses [ADR-0006](./0006-a-verdict-owed-to-another-persona-is-an-artifact.md)'s rejected option 2** (gating `gh pr merge` on the marker's existence), on the revisit that record invited
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

**The variable that puts a rule in that row is MECHANICAL DECIDABILITY, not irreversibility.** The first version of this ADR argued from irreversibility — *"a floor whose violation is not recoverable"* — and that was self-defeating, because the same document argues elsewhere that this repo's deploy **is** revertible. Take either claim as true and the other conclusion loses its support; argued that way, this ADR argues against its own existence.

The correction is not new thinking. [ADR-0004](./0004-autonomy-and-permission-model.md)'s 2026-08-02 amendment already names decidability as the likely real variable, and rules out the reversible-and-fuzzy case in terms: *"if it can be fixed in the next commit, a hook costs more than it returns"*, with *"what 'finished' means"* given as the example of something skill-shaped rather than hook-shaped. And [ADR-0006](./0006-a-verdict-owed-to-another-persona-is-an-artifact.md) closes its own rejection of this exact mechanism with *"revisit this option if that question is ever settled."*

**This ADR is that revisit, and the question is settled by ADR-0006 itself.** *Do two markers parse, carrying a literal from each persona's canonical set, at this `headRefOid`* is decidable by a script with no judgement. *Is the change right* is not, and never becomes so. Before ADR-0006 the precondition was prose in an orchestrator's context and there was nothing mechanical to test; the marker is what made half of it decidable. That is the change of fact this record turns on.

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

5. **A required GitHub status check** — enforce it at the forge rather than in the harness. *Why not:* the markers are comments, and a check would have to be posted by the same token the gatekeepers write with, so it inherits the impersonation residue ADR-0006 already records **without** gaining the interception. It also only works where branch protection does; `main` here is the working branch.

## Decision outcome

**This reverses ADR-0006's option 2, and the reversal has to answer that record's own reason rather than ignore it.** It rejected gating rule 7b on the ground that *"a hook buys the same guarantee as the artifact, because a context willing to fabricate the comment is a context that would equally spawn `security` and ignore its verdict."*

**That argument is about impersonation, and it is correct about impersonation.** A context prepared to forge a marker is not stopped by a hook that reads markers — ADR-0006 says so, this record agrees, and nothing here claims otherwise.

**It does not reach drift, which is a different failure and the one that has now fired three times.** A gate that publishes `CLEAN` as a verdict line is not fabricating anything. It is not ignoring `security` — it dispatched it, read the comment, and applied a vocabulary its own file contradicted. Against a party doing its honest best with a wrong rule, a hook buys exactly what the artifact does not: **it is not reading the rule.** That is the whole difference, and it is why the same mechanism rejected fourteen days ago is right today.

The other half of ADR-0006's rejection — the parsing cost, rule 5d's four rounds and eighty deleted lines — is **not disputed and not discounted**. It is booked below as an accepted cost.

Chosen: **option 1**, because the precondition is mechanically decidable and the party it binds is the one reading it. Options 2, 3 and 5 all leave the gate applying its own instructions to itself, which is the assumption that failed three times in one day. **Option 4 is the same mechanism at a different severity** and is not rejected on principle — it is held in reserve, for the reason recorded there.

**Scoped to the markers, and the ratification half deliberately stays prose.** The first version of this decision also covered *"the owner's ratification for the boundary class"*, and that cannot be mechanised: **safe-vs-boundary is a judgement the hook cannot derive.** It would have to either demand ratification on every merge — which deletes the safe class, and is why option 3 is rejected below — or take the class from the constrained party, putting the protection at its weakest exactly where drift is most dangerous. *"The reviewer never merges an expansion of its own authority"* names precisely the case a drifting gate would call safe. A mechanism strong where the stakes are low and absent where they are high is worse than an honest boundary, because it reads as coverage.

**The markers must carry an author and association check, and this is a trust class neither existing hook takes.** This repository is **public**, so PR comments are **world-writable**: a precondition testing only the marker line, the verdict literal and the head SHA can be satisfied by a drive-by account. That is not the impersonation residue ADR-0006 records — that one is a trusted party writing with the right token — it is an untrusted stranger, and `wip-guard.sh` reads only repo-controlled metadata. The filter is the idiom ADR-0003 already uses for the owner's ratification: `author.login` plus `authorAssociation` in `OWNER`/`MEMBER`/`COLLABORATOR`. A human reviewer sees a stranger's byline; a regex does not.

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

What it must never do is fail open **silently**: an unresolved check prints what it could not determine.

**What does not move.** The gate's judgement stays in `agents/quality-assurance.md` — whether the Issue's requirements were met, whether the class is safe or boundary, whether a finding blocks. The hook checks that the **artifacts exist and match the head**; it has no opinion about whether they are right.

## Consequences

**Good**
- The precondition holds even when the gate misreads its own file — which is the observed failure, not a theoretical one.
- The three drifts above become unable to produce a bad merge. A marker whose verdict line is unparseable stops the merge instead of being interpreted.
- The rule gains a single mechanical definition. Today it exists as prose in one persona file and is *described* in another, and those two can disagree without either being wrong.

**Bad / accepted costs**
- **A second network-dependent `PreToolUse` hook on every Bash call.** `wip-guard.sh` already pays this and is budgeted at 10s. Two hooks doing `gh` calls on unrelated Bash commands is real latency for no benefit on the ~99% of calls that are not merges, so the hook must exit before any network work when the command is not a merge.
- **Fail-open means this is not airtight, and unlike its sibling it is UNBACKED.** `permission-guard.sh` can afford to fail open because `settings.json`'s `deny` list is its named backstop. This hook has none: `Bash(gh pr merge:*)` sits in the consuming repo's **allow** list. So where the sibling's fail-open degrades to a second mechanism, this one degrades to `permission-guard` rule **7b** alone — which denies `gh pr merge` from any agent other than `quality-assurance`, with no network, and is therefore real but narrower. The first version of this record priced the residual as *"needing the network to be down at the same moment"*, which understated it: `wip-guard.sh` records `permission-guard` emitting no decision at all with `jq` off PATH. Option 4 above is the answer if this bites.
- **"Floor" is a term of art in this repo** for `permission-guard`'s irreversible set, and this hook is not that. The qualification is in the Decision outcome, forty lines below a title that carries none — so a skimmer gets the stronger word without the caveat. Kept because the alternative titles were worse, and named here so the index row can carry the qualifier.
- **The measured cost ADR-0006 recorded for this option is real and inherited.** It rejected gating rule 7b partly on the parsing: a bare `gh pr merge` names no PR, and rule 5d took four rounds and eighty deleted lines to get command parsing right. This ADR reverses that rejection on the decidability argument, not by claiming the parsing got cheaper.
- **The impersonation residue is unchanged.** The hook reads comments written with the same token the agent holds, so a determined agent could still write both markers. ADR-0006 already records this and accepts it: the adversary this architecture addresses is **drift by a trusted party**, not hostility. This hook is squarely aimed at drift.
- **Two mechanisms now encode part of one rule** — the hook (artifacts present and current) and the persona file (what they mean). That is the split this ADR argues for, but it is still a seam, and a change to the marker shape must move both.

## Links
- [ADR-0006](./0006-a-verdict-owed-to-another-persona-is-an-artifact.md) — the verdict as artifact; this ADR enforces what that one made readable
- [ADR-0003](./0003-mr-definition-of-done.md) — the DoD the gate reviews against, and the ratification rule this hook would also check
- [ADR-0004](./0004-autonomy-and-permission-model.md) — the permission floor and `permission-guard.sh`, the sibling hook this one is deliberately weighed against

> **A correction, kept rather than edited away.** The first version of this line said `permission-guard.sh` has a *fail-closed rule* that this hook does not inherit. **It has no such rule** — its own contract header reads *"Fails OPEN (allows) on any parse error"*, and the claim that it fails closed was **struck from `wip-guard.sh` on 2026-08-02**, with a measured falsifier (`jq` off PATH → no decision emitted → a `git push origin main` is allowed). That header also names *what the floor should do when it cannot read its input* as an explicitly **open** question. This ADR had closed it by assertion, in a link line, in the document whose entire subject is claims that read one way and mean another. Found by `security` on this PR.
- #136 — pinning marker literals to each persona's canonical set; complementary, and explicitly not a substitute
- #134 — the marker's retirement mechanism, unsolved; a hook reading markers depends on that question having an answer
