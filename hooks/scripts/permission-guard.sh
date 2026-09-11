#!/usr/bin/env bash
# purpose: hold the irreversible floor centrally, so every consuming repo inherits the same refusal without re-declaring it, and an act whose effect escapes git is refused whoever asks for it
# permission-guard.sh — PreToolUse(Bash) guard shipped by tadeumendonca-skills.
#
# Enforces the model-agnostic, IRREVERSIBLE floor centrally, so every consuming repo inherits the same
# protection without re-declaring it. It blocks only what is dangerous in ANY repo regardless of branch
# model — the danger is irreversibility that escapes git, not "which branch" — and it deliberately does
# NOT block edits or commits by branch context, so it is safe for both GitFlow (main=prod) and
# trunk-based (main=working) repos.
#
# ┌─ WHICH LAYER OWNS A CONTROL ───────────────────────────────────────────────────────────────────┐
# │  settings.json `deny`  — THE DIRECT FORM. A literal command prefix, as a human would type it.   │
# │  THIS HOOK            — EVERYTHING ELSE, and it is the AUTHORITATIVE layer.                     │
# └────────────────────────────────────────────────────────────────────────────────────────────────┘
#
# ~~This is defense in depth … each repo's .claude/settings.json `deny` remains the hard backstop.~~
# **STRUCK 2026-08-04 (owner). It is backwards, and had been for some time before anyone measured it.**
# The hook was described as a supplement to an authoritative floor. It is the reverse: the floor holds
# the direct spelling, and for a growing set of controls EVERY OTHER SPELLING is held only here.
#
# FOUR REASONS A CONTROL CANNOT LIVE IN THE FLOOR. A reader deciding where to put the next rule should
# be able to decide from this list alone — if any of these is true, the rule belongs here:
#
#   1. WRAPPED. `bash -c '<payload>'` hides the whole command from a prefix matcher. The unwrap step
#      below re-points matching at the payload for every rule at once — **BEST-EFFORT, and the word is
#      load-bearing.** It covers the spellings listed in the suite and measured there; it does not
#      close the class, and it cannot.
#
#      ~~Closed by the unwrap step below~~ — **struck 2026-08-04, one commit after it was written, and
#      the strike is worth more than the sentence was.** Nine spellings still reached ALLOW when that
#      claim was made, the merge gate among them (`bash -c $'gh pr merge 145 --merge'` — ANSI-C quoting
#      the strip did not know, and an option run before `-c`). Both are fixed below. That is not the
#      point.
#
#      THE POINT IS THAT "CLOSED" WAS THE WRONG SHAPE OF CLAIM, and no amount of patching makes it the
#      right one: **a regex over a shell grammar is not provably complete.** The honest form is *which
#      spellings are covered, and how that was measured* — which is why the assertions live in the
#      suite, where they can be re-run, rather than in an adjective here. Whatever this file says about
#      its own coverage is true only of the spellings someone thought to try.
#
#      THAT MATTERS BEYOND THIS ONE RULE, and it is why the correction is here rather than only in the
#      commit: this batch shipped a record over-claiming its own coverage three times — an ADR quoting
#      its own summary as the criterion's text, an amendment denying a distinction the same PR created,
#      and this. A gap is a gap; a record asserting the gap is closed is what stops anyone looking.
#      **When you fix something here, state the measurement, not the conclusion.**
#   2. COMPOSED. `a && b`, `$(…)`, a `VAR=x` prefix — the matcher cannot decompose them, so it prompts
#      the human for tools that ARE allowlisted (rule 8). Denying with a reason turns an interruption
#      into something the agent fixes alone.
#   3. SEMANTIC. The act is not in the string. `git push` lands on the trunk depending on the CHECKED-OUT
#      BRANCH (rule 7); `gh api` is a read or a write depending on whether `-f` is present (rule 5f).
#      Pattern-listing these either misses a form or over-blocks — it over-blocked, denying EVERY
#      feature-branch push via `git -C`, so the agent hit a prompt for following its own convention.
#   4. SHADOWED BY AN ALLOW. This is the one that is invisible until measured, and the one that produced
#      most of the current set. A prefix `deny` on `gh repo delete` cannot see
#      `gh -R owner/repo repo delete`, so a broad allow on the tool re-opens every deny for that tool
#      at once, silently. **An allow entry does not weaken one deny; it weakens all of them together.**
#
#      THE WORKED EXAMPLE IS `Bash(gh -R:*)`, WHICH IS NO LONGER IN `allow` — it was removed once the
#      shadowing was measured, and it turned out to cost nothing, because `gh <subcommand> --repo <o/r>`
#      puts the flag AFTER the subcommand and so still matches the per-subcommand entries. Read that as
#      the lesson rather than as a fact about today's floor: **the reason a control belongs here is the
#      SHAPE — a broad allow on a tool whose deny entries are per-subcommand — not any particular
#      entry.** `Bash(git -C:*)` is still in `allow` and is the live instance of that shape.
#
# THE SIZE OF THE SET, DESCRIBED RATHER THAN LISTED — deliberately, and the trade is real either way.
# An enumeration here would be exact today and wrong at the next migration, and this file has now paid
# three times for a comment that drifted from the code beside it. What does not go stale is the
# DERIVATION, so that is what is recorded: **read `.claude/settings.json`'s `deny` list, and for each
# entry ask whether one of the four reasons above applies to it. Every entry where the answer is yes is
# an entry whose real enforcement is here.** Do not expect a count here: one was written, and by the
# end of the same day the floor had moved three times under it. Re-derive it against the floor you
# actually have — `inventory-counts.test.sh` asserts that no tracked file claims an allow entry the
# floor does not contain, which is the mechanical half of the same discipline.
#
# THE DERIVATION FINDS ONLY THE CONTROLS THAT MIGRATED, AND THAT IS NOT ALL OF THEM. Reading the
# `deny` list can only find rules that HAVE a floor entry. Several controls were BORN here and never
# had a direct spelling at all — the merge gate (7b), composition (8), `gh api` writes (5f), the
# persona-keyed rules (5c/5d/5e), and rule 7's bare-`git push`-while-HEAD-is-main branch. For those
# there is no floor entry to retain and nothing behind this file. **The set the floor does not bound
# contains the merge gate**, which is the sharpest way to hold the point. See ADR-0004.
#
# ── THE FAIL-OPEN CONTRACT, AND WHY IT SURVIVED THE INVERSION ────────────────────────────────────
# Contract: receives the PreToolUse JSON on stdin; denies by printing a permissionDecision JSON and
# exiting 0. **Fails OPEN (allows) on any parse error, a missing `jq`, or no network — EXCEPT the merge
# floor, rule 7c, which fails CLOSED since 2026-08-28 (#341).**
#
# ~~7d IS NOT A SECOND EXCEPTION — IT IS THE SAME ONE, ONE FIELD WIDER … its one degradation branch (the
# payload came back without `closingIssuesReferences`) denies for exactly 7c's reason.~~ **STRUCK
# 2026-09-08 (#383, slice S4): RULE 7d IS REMOVED, so there is exactly one fail-closed rule again.**
# The paragraph is struck rather than deleted because it is the sentence that told a reader this file
# had two of them, and the count is the thing a later reader will want to trust. What 7d refused —
# the forge auto-closing an Issue the gate's verdict never declared — is REPARABLE: `gh issue reopen`
# restores the prior state exactly, at no cost, and nothing latches off an Issue close. Under the
# owner's criterion (*«situacoes irreparaveis»*) a lock does not survive on a reparable act however
# correctly it fires. The full verdict, what is lost with it and what does NOT replace it are at 7d's
# former site, below rule 7c.
#
# ONE EXCEPTION, AND THE CRITERION FOR IT IS NOT "IMPORTANCE" — IT IS WHAT THE FAIL-OPEN LANDS ON.
# Rule 7c is the only rule here whose degradation admits the IRREVERSIBLE act itself: it guards the
# merge, and an unreadable verdict used to clear it silently. Every other control in this file degrades
# into something still catchable downstream, so the wedging argument below still governs them. The
# owner's decision (#341) was «deveria travar», asked about the merge floor and answered about the
# merge floor — **do not read it as a licence to flip any other rule, here or in another hook.** That
# generalisation is #342, a separate Issue with a separate decision that has not been taken.
#
# WHAT THE EXCEPTION COSTS, NAMED: rule 7c can now wedge the gatekeeper. With no network, the one
# persona allowed to merge cannot merge, and no command it can run repairs that. That is the accepted
# trade — a merge deferred costs a retry, a merge admitted costs the whole control — and the deny says
# which precondition was missing so the human can see what to fix.
#
# AND ONE THING IT DOES NOT BUY: a missing `jq` still disables this ENTIRE file at line ~114 below,
# before any rule runs, so 7c's own `jq` branch cannot fire. That is a different failure with a wider
# blast radius, explicitly out of #341's scope, and it is unfixed. See rule 7c's own comment.
#
# ~~because settings.json `deny` is the authoritative backstop~~ — **that justification is GONE.** It was
# the reason failing open was nearly free, and it stopped being true when the semantic cases migrated
# here. The reason it still fails open is now a different and weaker one, accepted with the cost named:
#
#   FAIL-CLOSED WEDGES THE AGENT, WITH NO REPAIR ROUTE THAT DOES NOT GO THROUGH THE HUMAN. This is not
#   hypothetical. THE MEASURED CASE, REHOMED HERE 2026-09-04 (#383) BECAUSE ITS ONLY RECORD WAS
#   `wip-guard.sh`'S HEADER AND THAT FILE IS DELETED — three surviving hooks cited it there
#   (`preflight.sh`, `session-plugin-version.sh` and this line), so the deletion would have left three
#   live citations resolving to nothing:
#
#     WITH `jq` OFF `PATH`, THIS GUARD EMITTED NO DECISION AT ALL — silently. Every semantic rule it
#     carries was off, and a main-agent `git push origin main` was allowed. Nothing anywhere said so.
#     The failure is not that the guard broke; it is that a missing DEPENDENCY and a clean verdict are
#     indistinguishable downstream. (That specific hole is what `preflight.sh` was later built to
#     close, at `UserPromptSubmit`, by refusing the prompt rather than the command.)
#
#   A guard that denies everything when its own dependency is missing cannot be fixed by the agent,
#   because fixing it requires running commands.
#
# **THE COST IS NOW LARGER THAN IT WAS, AND IT GROWS.** The layer that fails open is the layer carrying
# the semantic cases — so a hook failure is not a degraded floor, it is an OPEN DOOR for every control
# in the derived set above. That is the accepted trade, not an oversight. The two alternatives were put
# to the owner and declined: fail-closed (above), and pattern-listing the spellings back into the floor
# — killed by measurement, since ~150 probes found nine spellings nobody had listed, across rules that
# had already been swept. That is precisely the pattern-list this hook exists to replace.
#
# ── THE STANDING RULE FOR THE NEXT RULE ──────────────────────────────────────────────────────────
# **A control a prefix matcher cannot express belongs here by construction — and every such migration
# removes one more thing the fail-open cost is bounded by.** Both halves are the rule. Migrate when one
# of the four reasons applies; when it does, keep the direct form in the floor as well, so the cheap
# spelling still has a check that cannot fail open. Do not migrate a control that a prefix CAN express.
#
# ADR-0004 holds the full decision and its supersessions; this is the short operative form.

set -euo pipefail

input="$(cat 2>/dev/null || true)"

# Extract the bash command; allow normal flow if we can't read it.
command="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[ -z "$command" ] && exit 0

# WHO is running this call. The harness stamps a subagent's tool calls with agent_type
# (`<plugin>:<subagent>`) and leaves it empty for the main agent. The merge gate (rule 7b) and the
# filing exemption (5d) both read it.
#
# THE PROPERTY IS "CANNOT CLAIM", NOT "CANNOT OBTAIN", and the difference matters enough to state:
# `agent_type` is read from the ROOT of the payload, while the model's only contribution is
# `.tool_input.command`, a sibling string. There is no path from a command string to a root field —
# so no SPELLING exempts anyone. But the main loop CHOOSES which persona to spawn, so it can obtain
# any agent_type by delegating. That is 7b's designed path (its deny message says to route through
# the reviewer) and it is now 5d's too. These rules enforce ROUTING, not capability.
#
# WHICH PERSONAS THIS FILE NAMES, AND WHY THE FIFTH IS NOT ONE OF THEM (2026-08-04). Three rules key on
# `agent_type`: 5e names `product-lead` to deny it, 5d names `developer` to exempt it, 7b names
# `quality-assurance` to allow it. Every other persona is decided by those rules' catch-all `*)`
# branches — that is the shape, and it is why `tech-lead` has no rule either.
#
# `agents-lead` joined the roster on 2026-08-04 and **needs no rule of its own.** Worked through
# act by act rather than asserted: it is a subagent, so `agent_type` is non-empty and does not match
# `*:developer`, so 5d's `*)` DENIES `gh issue create` — which is what its brief says it must never do;
# it does not match `*:quality-assurance`, so 7b's `*)` DENIES `gh pr merge`. Both obligations are
# already mechanical. It is NOT denied `gh pr comment`, and that is deliberate rather than an
# oversight: 5e's argument is the irreversibility of paraphrasing PRIVATE material (`.brand/`) into a
# public comment, and `agents-lead`'s mandate is the machinery — hooks, settings, briefs — which
# is published in this repo already. Adding a deny to make the list of named personas look complete
# would be a rule with no argument behind it, and this file has spent four rounds learning what those
# cost. Its "never posts" is an instruction in `agents/agents-lead.md`, on the same footing as
# `tech-lead`'s.
agent_type="$(printf '%s' "$input" | jq -r '.agent_type // empty' 2>/dev/null || true)"

# ~~NEVER INHERITED FROM THE ENVIRONMENT. `developer_may` is set only by rule 5d below and read as
# `${developer_may:-}`, so an exported variable of that name in the hook's environment would skip
# the owner's ASK — a main-agent `gh issue create` coming out with no decision at all. That is the
# same shape as the `exit 0` defect this file already memorialises: an outcome depending on state
# the rule never established. Cheap to close, at the floor, so it is closed rather than reasoned about.~~
#
# **THE VARIABLE IS DELETED, 2026-08-03, and the defence with it — because what it defended is gone.**
# `developer_may` existed to carry ONE bit from rule 5d's `case` down to 5d's `ask`: "this caller is
# exempt from the prompt". There is no prompt any more (see 5d), so the flag gated nothing and the
# environment defence guarded nothing. Keeping a hardening line whose subject no longer exists is the
# same defect as a comment that outlived its code — it reads as protection and protects nothing.
#
# What SURVIVES the deletion is the property, and it now rests on `agent_type` alone: that variable is
# ASSIGNED unconditionally from the payload (`agent_type="$(… jq …)"`, not `${agent_type:-$(…)}`), so
# ambient state cannot claim a persona either. That is the assertion the suite still carries, in place
# of the `developer_may` probe — it can still fail, where a probe for a deleted variable could not.

deny() {
  jq -n --arg r "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $r
    }
  }'
  exit 0
}

ask() {
  jq -n --arg r "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: $r
    }
  }'
  exit 0
}

# For the class where the thing that makes an act right or wrong is NOT visible in the command, and
# the owner is the only one who can see it. `deny` would be a lie there — it says "never", when the
# truth is "not unless the owner agrees" — and a denial the owner has to work around by typing the
# command themselves has moved the work to them rather than protecting them from it.
#
# ~~**THE `ask()` HELPER IS DELETED, 2026-08-03.** It had exactly one call site — rule 5d's prompt on a
# main-agent `gh issue create` — and that call is gone (see 5d for the reasoning). The paragraph above
# is kept struck rather than removed because its ARGUMENT is still correct and is what a future rule
# would re-derive: there is a real class of act whose rightness the command cannot show. What changed
# is that `gh issue create` from the MAIN AGENT turned out not to be in it, since the owner is already
# watching that call happen. A future rule that genuinely is in that class re-adds these ten lines
# deliberately; leaving a helper nothing calls would be a mechanism the file claims and does not run.~~
#
# **RESTORED 2026-08-30 (#365), on exactly the terms that deletion set: a rule arrived that IS in the
# class, so the helper is re-added deliberately rather than kept idle.** The paragraph above is
# UN-struck and the deletion note struck in its place, because the argument it preserved is now load-
# bearing again — rule 10 below guards *admitting an item into the running iteration*, and whether a
# given admission is the owner's decision or the loop's own is not a fact any matcher can read off the
# command. **What makes `ask` the right verdict there rather than a hedge: the owner's answer to the
# prompt IS the human verification his rule demands.** The guard does not have to distinguish *he told
# me to do this* from *I did it myself*; it puts the question to the only party who knows.
#
# WHAT AN `ask` COSTS THAT A `deny` DOES NOT, and it is the reason rule 10 does not hand it to
# everyone: an `ask` needs a prompt surface. In the orchestrator's session there is one, by
# construction — that is where the owner sits. A dispatched subagent has none, so `ask` there resolves
# to whatever the harness does with an unanswerable prompt, which is a behaviour this file has NOT
# measured. Rule 10 therefore denies the subagent case outright and asks only the orchestrator; see
# its own comment.
#
# ── THE HELPER IS DELETED AGAIN 2026-09-04 (#383), ON THE EXACT TERMS THIS COMMENT ALREADY SET ───
# Rules 10 and 11 were its only callers, and both went when the owner priced the milestone act below
# the audit's bar. The rule this helper's own history establishes, applied for the second time:
# **leaving a helper nothing calls would be a mechanism the file claims and does not run.**
#
# THIS GUARD NOW EMITS NO `ask` VERDICT AT ALL — it denies, or it abstains. Nothing else. Know that
# before writing the next rule: reaching for `ask` means re-adding those ten lines deliberately,
# which is the point of removing them rather than leaving them idle.
#
# EVERYTHING ABOVE IS KEPT UNSTRUCK, because the ARGUMENT is still correct and is what a future rule
# would re-derive: there is a real class of act whose rightness the command string cannot show, and
# for that class the owner's answer to a prompt IS the verification — the guard never has to
# distinguish *he told me to* from *I decided it myself*. What is gone is not the argument. It is the
# only rule that was ever in the class.
#
# ── RESTORED A SECOND TIME, 2026-09-05 (#383, slice S3), ON THOSE SAME TERMS ──────────────────────
# ~~struck: it emits four~~ **AND WITHDRAWN THE SAME DAY (#383, S3-revert). THIS GUARD EMITS NO `ask`
# VERDICT AGAIN, AND THE HELPER HAS NO CALLER.** The three S3 downgrades — force-push (3b), AWS secret
# writes (5), `gh repo archive`/`rename` (5g) — are back to `deny` on the owner's ruling.
#
# **THE CLASS ARGUMENT WAS NOT WRONG. THE MECHANISM IS NOT AVAILABLE.** Each of those acts is genuinely
# REPARABLE, and for each, whether it is right is genuinely invisible in the command — a force-push
# onto a shared branch and onto the agent's own throwaway branch are the same string. That is the class
# this helper exists for and the acts are still in it. What the revert established is narrower and
# fatal to the remedy: **a hook `ask` is answered automatically in this harness's default working
# mode**, measured in the owner's own interactive session, so the prompt that was supposed to carry
# the verification never reached him. See rule 3's site for the measurement.
#
# **SO THE LADDER HAS A MISSING RUNG, AND THAT IS THE THING TO CARRY FORWARD RATHER THAN THIS
# TOMBSTONE.** `deny -> ask -> context -> nothing`: the second rung does not hold here. Any future rule
# in this class faces the same wall, and the condition that would lift it is an auto mode that
# EXCLUDES hook `ask` — the owner named it himself. Until then, a reparable-but-serious act has only
# `deny` or nothing.
#
# **THE HELPER IS KEPT WITH NO CALLER, DELIBERATELY, AND THAT IS A DEVIATION FROM THIS FILE'S OWN
# CONVENTION.** The 2026-08-03 tombstone above says a helper nothing calls is "a mechanism the file
# claims and does not run", and by that rule it should be deleted for the second time. It is not,
# because the reason it has no caller is now an external, dated property of the host — not a finding
# that no act belongs in the class — and deleting it would erase the only place that distinction is
# written next to the code. **Read `ask()` as parked, not as available**: adding a caller today ships a
# rule that does not fire.
#
# ── WHAT AN UNANSWERABLE `ask` ACTUALLY DOES — MEASURED 2026-09-05, AND IT WAS THE OPEN QUESTION ──
# The paragraph above says a dispatched subagent has no prompt surface, so `ask` there "resolves to
# whatever the harness does with an unanswerable prompt, which is a behaviour this file has NOT
# measured." **It is measured now, because S3 could not ship a downgrade whose failure direction was
# unknown.** Probe plugin loaded with `claude --plugin-dir`, build 2.1.261, one hook returning `ask`
# on one marker and `deny` on another, every verdict confirmed on disk rather than taken from the
# nested model's narration:
#
#   MAIN session, headless `-p`:
#     hook `ask`                     -> REFUSED, hook's reason surfaced, directory NOT created
#     hook `ask` + settings `deny`   -> REFUSED by the PERMISSION LAYER; the hook's ask text never
#                                       appeared, so a static `deny` BEATS a hook `ask`
#     hook `deny`                    -> REFUSED, hook's reason surfaced (control)
#     hook abstains, cmd allowlisted -> EXECUTED (control)
#
#   DISPATCHED SUBAGENT (Task, general-purpose), the case this file called unmeasured:
#     hook `ask`                     -> REFUSED, hook's reason surfaced, directory NOT created
#     hook `deny`                    -> REFUSED (control)
#     hook abstains, cmd allowlisted -> EXECUTED (control — proves the subagent really ran)
#
# **AN `ask` FAILS CLOSED WHERE THERE IS NOBODY TO ANSWER IT.** ~~That is the fact the downgrades in
# this slice rest on~~ — **the FACT is untouched and the DOWNGRADES ARE REVERTED (#383, S3-revert).**
# The reading above is correct and stays: in a headless main session and in a dispatched subagent, an
# unanswerable `ask` refuses and surfaces its reason. **What it does not describe is the context the
# owner works in**, which is the paragraph flagged NOT MEASURED at the bottom of this block — and that
# is the one that decided the revert. Read this measurement as scoped to the two contexts it names.
#
# **AND A STATIC `deny` IS NOT WEAKENED BY A HOOK `ask` OVER THE SAME COMMAND.** Every act downgraded in
# S3 keeps whatever static deny already covered it; the downgrade only reaches the spellings the static
# layer cannot express (`git -C <dir> push --force`, `gh -R o/r repo archive`), and those become a
# prompt rather than a silent execution.
#
# ~~NOT MEASURED, AND NAMED RATHER THAN ASSUMED: the INTERACTIVE main session.~~ **MEASURED THE SAME
# DAY, IN THE OWNER'S OWN SESSION, AND IT IS WHY THE THREE DOWNGRADES WERE REVERTED. THIS PARAGRAPH IS
# THE MOST IMPORTANT ONE IN THE BLOCK: it named the gap correctly, priced it in the safe direction, and
# was wrong about the direction.**
#
# The old text guessed that the worst case was "an interactive `ask` also merely refuses", i.e.
# deny-with-a-softer-message — *"it fails safe either way."* **It does not fail safe. Under AUTO MODE
# the `ask` is answered automatically and the act EXECUTES.** Measured in the owner's interactive
# session immediately after the S3 merge, new build confirmed live:
#
#   this guard's source, fed the exact force-push command, two payloads  -> ask
#   the same force-push EXECUTED for real                                -> executed, NO PROMPT
#   a `>` redirect (rule 8b, a deny) as a control                        -> denied, message shown
#   the session's mode                                                    -> AUTO, harness-declared
#
# So the hooks fire and the build is live; the `ask` verdict is simply consumed. **The three downgraded
# acts were not gated at all in the one session that matters.**
#
# **THE LESSON IS ABOUT THE PROBE, NOT ABOUT THE RULES.** Both readings above are headless (`-p`) or
# subagent, and both are correct — they measured the *floor* of an `ask`'s behaviour. The context that
# decides the verdict is the one a hook-bound probe cannot drive, and it was left as an assumption in
# the SAFE direction, which is the assumption a floor may never make. **A downgrade whose remedy is a
# prompt must be measured in the mode the human actually runs.** Nothing here can measure that; the
# owner can, in one command, and did.

# Single-line, collapsed whitespace for matching.
cmd="$(printf '%s' "$command" | tr '\n\t' '  ')"

# ── `-c` PAYLOAD UNWRAPPING ──────────────────────────────────────────────────────────────────────
# A `bash -c '<payload>'` wrapper made EVERY `$bare` rule blind, and the blindness was invisible in
# exactly the way that matters: measured 2026-08-04, all of these came out ALLOW, with no decision from
# any layer — not this hook, not the settings `deny`:
#
#     bash -c 'git push origin main'    → rule 7   (the trunk push)
#     bash -c 'gh pr merge 145'         → rule 7b  (the MERGE GATE)
#     bash -c 'gh issue create …'       → rule 5c/5d
#     bash -c 'gh pr comment …'         → rule 5e
#     bash -c 'gh api … -f title=x'     → rule 5f
#
# WHY IT HIT EVERY RULE EXCEPT ONE, because the pattern is the lesson: `$bare` COLLAPSES quoted spans,
# which is right for its own purpose (an operator inside a commit message is not composition) and is
# precisely wrong here — the payload of `-c` is a COMMAND that happens to be quoted, not a string that
# happens to look like one. Rule 4 (`rm`) matches `$cmd`, the raw string, and is the only rule that
# caught the wrapped form. An empirical check that sampled `rm` and generalised is how this was
# reported as covered; one rule was, and it was the one rule that does not use the shared surface.
#
# THE FIX IS AT THE SOURCE, NOT PER-RULE. Unwrap here, once, and every rule downstream sees the payload
# as a command rather than as a quoted string. Fixing it rule-by-rule would mean each future rule has to
# remember — which is the property this file keeps proving it does not have.
#
# ── WHAT THIS COVERS, AND WHAT IT CANNOT ─────────────────────────────────────────────────────────
# BEST-EFFORT, NOT COMPLETE, and stated here because the first edition of this block said "closed" and
# was wrong within a day — nine spellings still reached ALLOW, the MERGE GATE among them.
#
#   COVERED, and each spelling is asserted in the suite rather than claimed here: `bash`/`sh`/`zsh`/
#     `ksh`/`dash`, an absolute interpreter path, `-c`/`-lc` clusters, an option run before `-c`
#     (`--norc`, `--login`, `-i`, `-o posix`), `'…'` and `"…"` payload quoting, and three levels of
#     nesting.
#
#     ~~`$'…'` / `$"…"` payload quoting~~ — **REMOVED FROM THIS LIST 2026-08-04, THE DAY IT WAS ADDED.**
#     What the patch taught the strip is the ANSI-C **delimiter**. What makes ANSI-C quoting different
#     from single quoting is that **bash DECODES ESCAPES inside it**, and nothing here decodes anything.
#     Two characters separate a denial from an allow, and both rows execute identically:
#
#         bash -c $'gh pr merge 145 --merge'      → DENY   (7b fires)
#         bash -c $'gh pr \x6derge 145 --merge'   → ALLOW  (no decision, from any layer)
#
#     Listing the class when the fix covered one member is **the fourth time in this batch a record
#     over-claimed its own coverage** — and it shipped inside the commit that added ADR-0004, which
#     exists to stop precisely this. The lesson is not "add `\xNN` to the regex": `\155`, `\e`, `\cX`
#     and plain concatenation (`$'r'"m -rf /x"`, no escapes at all) are all still there, and each patch
#     to a thrice-patched matcher buys one spelling. Where it now sits is the honest bucket:
#   NOT COVERED, DELIBERATELY: the other interpreters. `python3 -c`, `perl -e`, `ruby -e`, `node -e`
#     and `eval` reach the same acts and are NOT chased — a regex cannot parse four more languages,
#     and pretending to would be the "mechanism the file claims and does not run" defect. ADR-0004
#     prices this as accepted non-containment; the suite asserts they ALLOW, so the gap is visible
#     rather than merely absent.
#   NOT PROVABLE EITHER WAY: everything nobody has tried — and, named explicitly because it was once
#     in the COVERED list above, **ANSI-C `$'…'` payloads. The DELIMITER is handled; ESCAPE DECODING is
#     not, and no regex over ANSI-C quoting can claim otherwise** — the notation is a small language
#     with hex, octal, control and escape forms, and matching it would mean implementing bash's decoder
#     in a `sed` expression. The suite carries `\x6d` witnesses against the merge gate and the
#     recursive-force delete, asserting SILENCE rather than denial; read the comment there for why a
#     silence assertion is the weakest thing in that file.
#
#     **A regex over a shell grammar is not provably complete**, so the honest claim is always *these
#     spellings, measured* — never *the class*. If you extend this, add the spelling to the suite and
#     re-measure; do not upgrade the adjective. And prefer removing the class from the FLOOR over
#     extending this regex — ADR-0004's argument applied to this rule: a matcher patched a fourth time
#     closes a spelling; removing the allow entry closes the class. That is what actually happened
#     here: the interpreter entries that made a wrapped payload reachable came out of `allow`.
#
#     THE CURRENT LIST IS NOT REPEATED HERE, DELIBERATELY — an earlier edition of this line named three
#     entries and was incomplete within hours, when a second floor edit narrowed a fourth. **Read
#     `.claude/settings.json` for what is allowed today.** Two things about that edit are worth
#     carrying, because they are properties of the design rather than of the list: an `allow` on
#     `bash <dir>/` is only safe where the agent cannot WRITE into <dir> — rule 5's `bash script.sh`
#     exemption means the wrapper class otherwise just moves from the `-c` payload to a file path; and
#     an interpreter entry added without being named in a commit message is how `perl`/`ruby` became
#     silent ALLOWs here while remaining ASKs on trunk.
#
# APPENDED, NOT SUBSTITUTED. The payload is added to `cmd`, so the OUTER command survives matching too:
# `FOO=x bash -c '…'` must still trip rule 8's env-var prefix, and substituting would have thrown that
# half away. Both surfaces are matched, which is strictly more than before and never less.
#
# THE WORD BOUNDARY IS LOAD-BEARING: `(^|[[:space:]]|/)` before the shell name, so `npm run finish -c x`
# does not unwrap on the `sh` inside `finish`, while `/bin/bash -c` and `/usr/bin/env sh -c` do. Without
# it the rule would rewrite ordinary commands into fragments and match rules against noise.
#
# `bash script.sh` IS UNTOUCHED — no `-c`, no unwrap, no collateral. Only the `-c` form is a wrapper
# around a command string; running a FILE is not, and the test suite pins that (it is itself run as
# `bash hooks/scripts/permission-guard.test.sh`).
#
# THREE PASSES, for `bash -c "bash -c '…'"`. Bounded rather than `while`, because a hook that can loop
# on adversarial input is a wedged agent; three is past any real nesting and terminates unconditionally.
unwrap_scan="$cmd"
for _ in 1 2 3; do
  case "$unwrap_scan" in
    *-*c*) ;;
    *) break ;;
  esac
  # Delimiter is `#`, NOT `|` — the pattern is full of alternation and a `|` delimiter silently cuts it
  # into fragments that still compile. It matched nothing and looked fine.
  #
  # THE OPTION RUN between the shell name and `-c` — `bash --norc -c`, `--login`, `-i`, `-o posix`.
  # Requiring `-c` to be the FIRST token after the shell name is a guess about how the caller writes
  # the wrapper, and this file has rejected that guess three times already (rule 4's flag set, 5b's
  # `-R`, 5f's attached value). The optional trailing `[A-Za-z][A-Za-z0-9_-]*` is the OPTION'S OWN
  # ARGUMENT, which is what `-o posix` needs.
  unwrap_payload="$(printf '%s' "$unwrap_scan" | sed -E 's#^.*(^|[[:space:]]|/)(bash|sh|zsh|ksh|dash)([[:space:]]+--?[A-Za-z][A-Za-z-]*([[:space:]]+[A-Za-z][A-Za-z0-9_-]*)?)*[[:space:]]+-[A-Za-z]*c[A-Za-z]*[[:space:]]+##')"
  [ "$unwrap_payload" = "$unwrap_scan" ] && break
  # Strip ONE layer of surrounding quotes — that layer is the wrapper's, so removing it is what turns
  # the payload back into a command. Inner quoting is left alone for `$bare` to collapse as usual.
  #
  # THE LEADING `$` IS STRIPPED FIRST, for ANSI-C `$'…'` and locale `$"…"` quoting. Without it the
  # quote-strip did not match at all, so the payload kept its quotes, `$bare` collapsed the whole span,
  # and every `$bare` rule saw nothing — INCLUDING THE MERGE GATE. `bash -c $'gh pr merge 145 --merge'`
  # reached ALLOW with no decision from any layer.
  #
  # The tell that it was the same defect rather than a new one: under `$'…'`, `rm -rf` and
  # `terraform apply` still denied — because rules 4 and 2 read `$cmd` RAW. That is exactly the
  # asymmetry the unwrap was written to remove, relocated one spelling further out rather than removed.
  unwrap_payload="$(printf '%s' "$unwrap_payload" | sed -E -e 's/^\$//' -e "s/^'(.*)'\$/\\1/; s/^\"(.*)\"\$/\\1/")"
  [ -z "$unwrap_payload" ] && break
  cmd="$cmd $unwrap_payload"
  unwrap_scan="$unwrap_payload"
done

# ~~Quoted spans collapsed~~ **MOVED UP, to just after `cmd`, on 2026-08-04.** The computation and this
# whole explanation now live beside `cmd` — see there. It sat here, in the middle of the rule list, for
# one reason that was never a decision: it was written when only rules 7 and 8 needed it. Rule 5b was
# above it and therefore matched `$cmd`, which is why `git commit -m "gh secret set X"` — a message
# ABOUT the act — was denied as the act. A normalisation every rule should share does not belong
# halfway down the rules that share it.
#
# ESCAPE-AWARE since #66, and the earlier form is worth stating because it looked correct.
# It was `s/"[^"]*"/""/g` — "run to the next double quote" — so a body containing an ESCAPED
# quote terminated the span early and exposed the remainder to the composition check:
#
#     gh issue create --body "text with \"quotes\" and `backticks`"
#                            ^-------------------^ collapse stopped here
#                                                    ^^^^^^^^^^^^ read as substitution → denied
#
# `([^"\\]|\\.)*` consumes any escaped character as one unit, so the span ends at the real
# closing quote. Same for single quotes, kept symmetric even though POSIX shells do not honour
# escapes inside them — the input here is a command STRING, not a parsed shell word, and a
# rule that treats the two quote styles differently is one nobody will remember correctly.
#
# The issue's stated fear was that fixing a false positive here would buy a false NEGATIVE in
# the rule protecting the matcher. Three cases pin that it does not, and all three are asserted
# in the test suite rather than argued here:
#   · an operator OUTSIDE quotes still survives the collapse and is still caught;
#   · an UNBALANCED quote matches nothing, so the operator stays exposed — it fails CLOSED,
#     which is the only safe direction for a deny-only rule;
#   · an escaped quote INSIDE a span no longer truncates it.
bare="$(printf '%s' "$cmd" | sed -E -e "s/'([^'\\\\]|\\\\.)*'/''/g" -e 's/"([^"\\]|\\.)*"/""/g')"

# ── ONE SPELLING OF "AN OPTIONAL -R/--repo BEFORE THE SUBCOMMAND" ────────────────────────────────
# ~~`gh -R <repo> <subcommand>` is this workspace's PRESCRIBED multi-repo convention~~ — **STRUCK,
# 2026-08-05. It is the opposite: the prescribed form is `gh <subcommand> --repo <owner/repo>`, and
# `gh -R` before the subcommand is the spelling that does NOT work.** The flag can still appear there
# in a command this hook sees, so every `gh` rule must still expect it — the variable below is
# unchanged and nothing about the matching changes. What was wrong was the sentence, not the code.
#
# HOW IT WAS WRONG, because the shape recurs: the paragraph below it already recorded the removal of
# `Bash(gh -R:*)` from `allow` and stated the working replacement in its own last clause. The
# correction landed in the record and the header above it was never re-read. So the file simultaneously
# prescribed a form and explained why that form cannot be allowlisted, and the header is the half a
# reader hits first.
#
# THE COST WAS MEASURED BEFORE THE FIX: a `product-lead` dispatch ran `gh -R <repo> issue view …` and
# stopped for a human on a read-only command. This comment was the only place in the workspace that
# said anything about the convention at all — `skills/permissions-and-environments/SKILL.md`
# contained neither spelling — so the rule that makes commands work lived in the file nobody opens
# before typing a command, and the rule that breaks them was what every persona had been taught.
# The teaching now lives in the five agent briefs, which is where an invocation convention is read.
#
# THE HISTORY IS KEPT BECAUSE IT IS THE REASON THE VARIABLE EXISTS, and it is history: for part of one
# day the floor carried `Bash(gh -R:*)` / `Bash(gh --repo:*)` in `allow`. The settings matcher reads a
# command PREFIX, so `Bash(gh repo delete:*)` could not see `gh -R owner/repo repo delete`, and for
# EVERY `gh` deny entry the `-R` spelling moved from *prompts the human* to *runs silently* — one allow
# entry weakening the whole `gh` half of the floor at once. **Both entries were removed the same day**,
# and removing them cost nothing: `gh <subcommand> --repo <o/r>` puts the flag after the subcommand and
# still matches the per-subcommand entries.
#
# THE RULE-LEVEL NEED SURVIVES THE FLOOR CHANGE, WHICH IS WHY NOTHING HERE IS DELETED. The hook must
# still match the `-R` form, because the convention still produces it and because the floor is not the
# only reader — a command the floor never sees still reaches these rules.
#
# THE FIX IS THIS VARIABLE, USED EVERYWHERE, and the reason it is one variable is the second half of
# the same finding: three rules had each grown their OWN copy, two of them space-only, so
# `gh -Ro/r pr merge` and `gh --repo=o/r secret set X` walked past the MERGE GATE and the SECRET-WRITE
# rule while the spaced form was denied. A floor that depends on how the caller punctuated is not a
# floor — rule 4 learned that with `rm -fR`, and it had to be learned twice more here.
#
# Tolerates all four spellings pflag accepts: `-R o/r`, `-Ro/r`, `--repo o/r`, `--repo=o/r` (and
# `-R=o/r`, which pflag also takes). Any rule matching a `gh` subcommand MUST interpolate this rather
# than write its own.
gh_repo_flag='([[:space:]]+(-R[[:space:]=]*|--repo[[:space:]=]*)[^[:space:]]+)?'

# 1. Never bypass the permission system.
case "$cmd" in
  *--dangerously-skip-permissions*)
    deny "Blocked: --dangerously-skip-permissions erases the permission boundary. The allowlist is curated, not bypassed." ;;
esac

# 2. IaC is pipeline-only — terraform never mutates from a laptop.
if printf '%s' "$cmd" | grep -Eq '(^|[^[:alnum:]_])terraform([[:space:]].*)?[[:space:]](apply|destroy)([[:space:]]|$)'; then
  deny "Blocked: 'terraform apply/destroy' is pipeline-only — IaC mutations run in CI, never locally. Use 'terraform plan' to inspect."
fi

# 3. Irreversible git history / ref rewrites. SPLIT IN TWO 2026-09-05 (#383, slice S3), and the split
#    is the whole content of the change: the two acts this rule matched with one regex and refused with
#    one sentence are NOT the same act under the owner's narrowed criterion — «situacoes irreparaveis».
#
#    3a. `git reset --hard` — KEEPS ITS DENY. Uncommitted work has no other copy anywhere. Nothing in
#        the reflog, nothing on the remote, nothing in the index once it is gone. It passes the strict
#        test on the merits.
#
#    3b. force-push — ~~DOWNGRADED TO `ask`~~ **REVERTED TO `deny` 2026-09-05 (#383, S3-revert, owner:
#        «reverte os três»). The reparability argument below is UNCHANGED and still true; what failed
#        is the REMEDY it relied on.** A force-pushed branch is recoverable from two independent
#        places: the pusher's own reflog, which still names the pre-push tip, and the remote's
#        unreachable objects, which survive until that repository is garbage-collected. It is costly
#        and loud; it is not irreparable. That reasoning is why the downgrade was defensible, and it
#        is not what this revert disputes.
#
#    ── WHY IT CAME BACK: `ask` IS NOT AN AVAILABLE REMEDY IN THE MODE THIS HARNESS RUNS IN ──────────
#    The downgrade's load-bearing premise was that `deny -> ask` converts a refusal into a question the
#    owner answers. Measured in the owner's own interactive session immediately after the S3 merge,
#    with the new build confirmed live:
#      · this guard's source, fed the exact force-push command, two payloads   -> ask
#      · the same force-push EXECUTED for real, in that session                -> executed, NO PROMPT
#      · a `>` redirect (rule 8b, still a deny) in the same session            -> denied, new message
#      · the session's mode                                                     -> AUTO, declared by
#                                                                                 the harness
#    So the hooks fire, the build is live, and a hook `ask` is answered automatically without reaching
#    him. **The three downgraded acts were not gated at all in his working session** — they went from
#    denied to silently executed, which is the opposite of what the downgrade promised.
#
#    **THE EARLIER SAFETY MEASUREMENT WAS NOT WRONG — IT WAS TAKEN IN THE WRONG CONTEXT.** It
#    established that an unanswerable `ask` FAILS CLOSED **in a dispatched subagent**, where there is
#    no prompt surface at all. That still holds. Nobody measured the MAIN SESSION under auto mode, and
#    that is the context the owner works in. Two correct measurements, two different contexts; the one
#    that decides this rule is the one that was never taken.
#
#    **THE GENERAL RULE, which binds every future downgrade in this file:** the ladder
#    `deny -> ask -> context -> nothing` has a rung that does not hold in this harness's default
#    working mode. The criterion is unchanged — irreparability still decides what belongs on the floor
#    — but *reparable* now licenses a downgrade only to a rung that actually fires. Any proposal whose
#    mitigation is *"it becomes a prompt"* is proposing a mitigation that does not fire. What would
#    make `ask` viable again is an auto mode that EXCLUDES hook `ask` — the owner named it himself as
#    one of his three options. It is not built here; it is the condition under which these three rules
#    could be revisited.
#
#    ~~WHY `ask` AND NOT REMOVAL, WHICH IS THE PART A LATER READER WILL WANT TO SECOND-GUESS.~~
#    **KEPT UNSTRUCK BELOW THIS LINE, because it is the argument for the DENY too, and it is the part
#    that decides this rule must live in the hook at all rather than in `settings.json`.** Removing
#    the branch would not degrade this to a prompt — it would degrade it UNEVENLY, and the uneven half
#    executes in silence. The static layers deny only the spellings where the flag follows `push`
#    IMMEDIATELY (`Bash(git push --force:*)`, `--force-with-lease`, `-f`), because a settings entry is
#    a token-bounded PREFIX. Measured 2026-09-05 with a probe settings file loaded via `--settings`,
#    the verdict read off disk:
#
#      deny  Bash(mkdir <P>/BOUND:*)   vs  mkdir <P>/BOUND    -> DENIED   (control)
#                                          mkdir <P>/BOUNDX   -> CREATED  <- the finding
#                                          mkdir <P>/OTHER    -> CREATED  (control)
#
#    So `:*` is a TOKEN boundary, not a raw prefix — which is why `--force-with-lease` had to be listed
#    separately from `--force` in the first place, and it generalises: a settings entry cannot express
#    "this flag ANYWHERE in the command". ~~These all walk past every static entry~~ — ONE of the two
#    does, and the example that did not is corrected here rather than deleted, because it is the one a
#    reader would have checked first:
#
#      git push origin main --force        ~~(flag after the refspec — no entry is a prefix of this)~~
#                                          WRONG. `Bash(git push origin main:*)` is in the deny list of
#                                          BOTH settings layers, and a token boundary matches an entry
#                                          plus ANY trailing tokens — so this spelling IS denied
#                                          statically. Measured 2026-09-05, same technique as the
#                                          BOUND/BOUNDX probe above, third arm added for exactly this:
#                                            deny Bash(mkdir -p <P>/out/main:*)
#                                              mkdir -p <P>/out/main            -> DENIED  (control)
#                                              mkdir -p <P>/out/main <P>/EXTRA  -> DENIED  <- the point
#                                              mkdir -p <P>/out/mainX           -> CREATED (control)
#      git -C <dir> push --force           (prefix is `git -C`, which is ALLOWLISTED) — this one is
#                                          real, and it is what the branch is actually for. Measured by
#                                          EXECUTION: with the plugin disabled, `git -C <repo> push
#                                          --force origin main` against a local bare remote moved that
#                                          remote's `main` (d7e5677 -> 42b3173, forced).
#
#    ~~Keeping the branch as `ask` is therefore strictly better than removing it~~ — the conclusion
#    changed with the verdict; the PREMISE it rests on is what survives and is why this branch still
#    exists at all: **`git -C <dir> push --force` is a spelling no settings entry can express**, so
#    without this rule it executes in silence. That is now an argument for the DENY living here rather
#    than for an `ask`. A hook `deny` is also final — it is decided BEFORE the permission system and
#    is never softened by an `allow` beneath it — so unlike an `ask`, this verdict does not depend on
#    the session's mode.
#
#    ── WHERE 3b's EXECUTABLE BLOCK LIVES, AND WHY IT IS NOT HERE ────────────────────────────────────
#    **3b's `if` is BELOW rule 7, not here, and that position is KEPT — but what it buys CHANGED with
#    the revert, and saying so is the honest form.** `ask()` and `deny()` both call `exit 0`, so the
#    first matching rule is the whole verdict. 3b's pattern matches `git -C <repo> push --force origin
#    main` — which is ALSO rule 7's trunk push — so with 3b above rule 7 the trunk classification was
#    never reached and a force-push to the trunk came out `ask`. Measured at 9aca9d4, before the move:
#      git -C <repo> push --force origin main   -> ASK    (3b)
#      same, with 3b neutralised                -> DENY   (rule 7 DOES match; it was never reached)
#    **WITH 3b BACK TO `deny` THE ORDERING NO LONGER CHANGES THE VERDICT — BOTH RULES DENY — SO IT NOW
#    DECIDES ONLY WHICH REASON THE CALLER READS.** That is a smaller thing than it was and it is still
#    worth keeping: the two messages prescribe different remedies (rule 7 says *branch first and open a
#    PR*; 3b says *do not rewrite a pushed ref*), and a trunk force-push is rule 7's problem first.
#    **The lesson generalises past this rule and is the reason the block is not moved back for
#    tidiness:** where two rules match one act, the stricter one runs first ONLY where it is right
#    about the act — the same test rule 5's pre-emption note states from the other side.
#    **The arms had to change with it.** A verdict-only assertion can no longer tell the two orders
#    apart, so the ordering arms now assert the REASON (`check_reason`), and a verdict-only battery
#    that reads green over a reordering would be exactly the uncalibrated check this repo hunts for.
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]].*reset[[:space:]]+--hard'; then
  deny "Blocked: 'git reset --hard' discards uncommitted work, and uncommitted work has no other copy — not in the reflog, not on the remote, not in the index. That is the irreparable half of what this rule used to refuse in one sentence; the force-push half is rule 3b, which denies too (#383 S3-revert) — briefly an 'ask', reverted because a hook 'ask' is answered automatically in this harness's auto mode. Use a safe alternative: commit first, 'git stash', or 'git revert' for something already committed."
fi

# 4. Recursive force delete (escapes git).
#
#    THE FLAGS ARE A SET, NOT A TOKEN, and the earlier pattern got that wrong. It required the
#    recursive and force letters to be COMBINED in one lowercase cluster
#    (`-[[:alnum:]]*r[[:alnum:]]*f` or its mirror), so, measured: `rm -rf /x` was denied while
#    `rm -r -f /x`, `rm -f -r /x` and `rm -fR /x` all came through ALLOW. Three spellings of the
#    same irreversible act, one of which (`-fR`) is what a shell-completion or a copied macOS
#    incantation actually produces. A floor that depends on how the caller happened to punctuate is
#    not a floor.
#
#    So the rule is written as what it means: `rm`, followed by a run of flag tokens whose UNION
#    contains a recursive flag and a force flag — split across tokens or fused into one, upper or
#    lower case, short or long. Three branches, because "both letters in one cluster" cannot be
#    expressed by the two-distinct-tokens form and vice versa.
#
#    Each token alternative is anchored on the whitespace before its leading dash, deliberately.
#    Without that anchor `--force` matches the recursive pattern from its SECOND dash (`-force`
#    contains an `r`), and `rm --force x` would deny as though it were recursive — a false positive
#    inside the fix for a false negative.
#
#    Defence in depth, not the only control: the static `deny` lists in all three settings layers
#    now spell these four forms out. The hook and the floor should agree, and this is the half that
#    reads the command semantically rather than by prefix.
#
#    A THIRD FALSE POSITIVE, MEASURED 2026-09-04 (#383) AND RECORDED RATHER THAN FIXED — IT IS S2's,
#    NOT S1's. This rule matches `$cmd`, not `$bare`. So a READ-ONLY command whose quoted SEARCH
#    PATTERN names the act is denied AS the act. Measured against this guard at head, two payloads
#    differing only in the character after the flag cluster:
#
#      grep -rn 'rm -rf'   <dir>   -> NO decision   (the closing quote breaks the trailing class)
#      grep -rn 'rm -rf /' <dir>   -> DENY          ("recursive force delete ... escapes git")
#
#    Nothing is being deleted in either. The second is denied because the pattern's own trailing `/`
#    satisfies `([[:space:]]|$|/)`. So whether a read-only grep runs depends on how the caller
#    punctuated their search string — which is the exact property the comment above says a floor must
#    not have, arriving from the other side of the same regex.
#
#    THIS IS A KNOWN, ALREADY-SOLVED DEFECT CLASS IN THIS FILE, WHICH IS WHY IT IS WORTH PINNING.
#    Rule 5b's own comment records the identical finding against itself — `git commit -m "gh secret
#    set X"`, a message ABOUT the act, denied as the act — and its fix was one token: `$cmd` -> `$bare`.
#    `$bare` is computed above this rule, and it collapses single- and double-quoted spans, so the same
#    substitution here abstains on both payloads above. On the DIRECT form it costs nothing: a genuine
#    `rm -rf '/some path'` leaves the FLAGS unquoted, so `$bare` still carries `rm -rf ` and the
#    trailing space still matches.
#
#    BUT IT COSTS A FALSE NEGATIVE ON THE WRAPPED FORM, AND THAT IS THE FORM ADR-0004 ASSIGNS TO THIS
#    HOOK — its layering amendment splits them in as many words: "the deny list holds the direct form,
#    the hook holds the wrapped form". In an interpreter-wrapped payload the quoted span IS the
#    command, so collapsing it deletes the act. Measured at this head, the same payload twice:
#
#      $cmd  = bash -c 'rm -rf /tmp/probe-x'   -> DENY   (this rule, today)
#      $bare = bash -c ''                      -> no match, rule 4 abstains
#
#    `python3 -c "..."` and `node -e "..."` are both granted in the project allow and degrade the same
#    way. So the one-token fix is NOT safe as measured, and its error runs in the dangerous direction:
#    the CURRENT defect over-blocks a read, the PROPOSED fix under-blocks an irreversible act. Whatever
#    S2 does here needs to keep the wrapped form covered — a bare substitution does not.
#
#    NOT CHANGED HERE, DELIBERATELY. S1's scope is removals; changing a floor rule's input is a
#    behaviour change to a surviving irreversible-floor rule and needs its own mutation proof — the
#    same reasoning that left the `inventory-counts` purpose-declarer gap reported rather than fixed
#    in this slice. It is pinned beside the rule so the UX pass over rules 8/8b meets it in the file
#    it will already be editing, instead of rediscovering it by being bitten.
#
#    ── S2 MET IT, RE-VERIFIED IT, AND STILL DID NOT FIX IT. THAT IS THE POINT OF THIS PARAGRAPH. ──
#
#    The pin worked: the UX pass ran into this comment in the file it was already editing. All three
#    payloads above were re-run against this guard at head on 2026-09-05 and reproduced exactly what is
#    written — `grep -rn 'rm -rf' <dir>` NO DECISION, `grep -rn 'rm -rf /' <dir>` DENY, and the wrapped
#    `bash -c 'rm -rf /tmp/probe-x'` DENY. The record survived S1's merge intact.
#
#    IT IS NOT FIXED BECAUSE THE FIX IS A DIFFERENT KIND OF CHANGE, and S2's own subject is what
#    separates them. Rules 8 and 8b govern FRICTION: their errors run toward over-blocking, and the
#    test S2 established for that class is "fire on a subset of what the runtime stops for, never on
#    more". THIS rule governs an IRREPARABLE act, so its errors run the other way, and the one-token
#    substitution measured above trades a false positive on a read for a FALSE NEGATIVE on a wrapped
#    delete. A repair has to keep the wrapped form covered — plausibly by matching `$cmd` and `$bare`
#    under different anchors rather than by swapping the input — and it needs a mutation proof of its
#    own, against the wrapped cases in the suite. **Do not fold it into a UX slice on the strength of
#    it being one token.** That is the whole reason it is still here.
rm_flag='([[:space:]]+(--[[:alpha:]][[:alpha:]-]*|-[[:alnum:]]+))*'
rm_rec='[[:space:]]+(--recursive|-[[:alnum:]]*[rR][[:alnum:]]*)'
rm_force='[[:space:]]+(--force|-[[:alnum:]]*[fF][[:alnum:]]*)'
rm_both='[[:space:]]+-[[:alnum:]]*([rR][[:alnum:]]*[fF]|[fF][[:alnum:]]*[rR])[[:alnum:]]*'
if printf '%s' "$cmd" | grep -Eq "(^|[^[:alnum:]_])rm${rm_flag}(${rm_both}|${rm_rec}${rm_flag}${rm_force}|${rm_force}${rm_flag}${rm_rec})([[:space:]]|\$|/)"; then
  deny "Blocked: recursive force delete ('rm -rf', in any spelling) is irreversible and escapes git. Remove specific tracked paths instead."
fi

# 4b. `git clean` WITH FORCE — the same act as rule 4, spelled through git, and it deletes UNTRACKED
#     files, which are by definition the ones git cannot give back. `git clean -f` and `-fd` are both
#     in the floor's `deny`, and neither was matched here — so `git -C /path clean -fd`, with
#     `Bash(git -C:*)` sitting in `allow`, ran with no decision from any layer. Same bypass shape as
#     the `gh -R` finding, in the half of the allowlist nobody was looking at.
#
#     Matched on `$bare` and tolerant of the leading `-C`/`-c`/`--git-dir`/`--work-tree` options, the
#     way rule 7 is, because that is precisely how the bypass was spelled. `-x`/`-X`/`-d` combine with
#     `-f` in any order or cluster, so the force flag is matched as a SET member the way rule 4 does,
#     rather than as a fixed token.
if printf '%s' "$bare" | grep -Eq '(^|[^[:alnum:]_])git([[:space:]]+(-C[[:space:]]+[^[:space:]]+|-c[[:space:]]+[^[:space:]]+|--git-dir=[^[:space:]]+|--work-tree=[^[:space:]]+))*[[:space:]]+clean([[:space:]]+(--[[:alpha:]][[:alpha:]-]*|-[[:alnum:]]+))*[[:space:]]*(--force|-[[:alnum:]]*f[[:alnum:]]*)([[:space:]]|$)'; then
  deny "Blocked: 'git clean -f' deletes UNTRACKED files — the one class git cannot restore, so it is as irreversible as 'rm -rf'. Remove the specific paths you mean, or use 'git clean -n' to see what it would take."
fi

# 4c. `git worktree remove` ONTO A DIRTY WORKTREE (#443). Third member of rules 4/4b's family and the
#     one that had no rule at all: it deletes a working DIRECTORY whose uncommitted content exists
#     nowhere else — not in the reflog, not on the remote, not in the index. That is the same sentence
#     rule 3 uses to justify refusing `git reset --hard`, and until this rule the two acts got opposite
#     answers. Measured against the live guard at 636fd983, with two working controls in the same run:
#
#       git worktree remove --force ../wt-probe  -> no output, exit 0   (NO DECISION)
#       git worktree prune                       -> no output, exit 0   (NO DECISION)
#       git push origin main                     -> deny                (control)
#       git reset --hard HEAD~1                  -> deny                (control)
#
#     And `Bash(git worktree:*)` sits in `allow` in ALL THREE settings layers — the global floor
#     included — with `deny` and `ask` empty in each. That is reason 4 of this file's own four
#     (SHADOWED BY AN ALLOW): a token-bounded prefix on the subcommand tree covers every subcommand at
#     once, so there is no per-subcommand entry left to reach. The act executed with no prompt and no
#     record from any layer.
#
#     -- IT KEYS ON THE TARGET, NEVER ON THE FLAG, AND THAT IS THE WHOLE DESIGN --------------------
#     Matching the force flag would be an enumeration claiming to be a language bound — #441's defect,
#     and #446's, and #438's before them. Cited, not restated. What makes it avoidable here is that
#     the flag set is measurably open-ended: all seven of `-f`, `--force`, `-ff`, `--force --force`,
#     `--f`, `--fo` and `--forc` destroyed a tracked modification (rc 0, directory gone), because git
#     accepts unambiguous long-option abbreviations. There is no finite list to write.
#
#     So the rule reads the TARGET, and no flag spelling appears anywhere in its executable part. A
#     reader auditing this block can confirm that by grepping the code below for the flag and finding
#     nothing.
#
#     -- THE PREDICATE IS GIT'S OWN REFUSAL, WHICH IS WIDER THAN #443'S BODY PROPOSED --------------
#     #443 proposed *"deny when the target has tracked modifications"*. THAT PREDICATE IS TOO NARROW,
#     and the Issue's own inventory is what falsifies it. Measured in a throwaway repo, bare
#     `git worktree remove` against each state:
#
#       tracked-modified   rc=128 refused        `git status --porcelain` non-empty
#       untracked          rc=128 refused        `git status --porcelain` non-empty
#       ignored-only       rc=0   removed        `git status --porcelain` EMPTY (ignored excluded)
#       clean              rc=0   removed        `git status --porcelain` empty
#
#     The correspondence is exact across all four rows: **`git status --porcelain` is non-empty in
#     precisely the two states git itself refuses to remove.** So this rule denies exactly what git
#     already denies and permits exactly what git already permits — behaviour-neutral against the
#     non-forced form by construction rather than by testing. The only thing it changes is that force
#     no longer overrides the refusal.
#
#     WHY THE NARROWER PREDICATE WOULD HAVE BEEN A GREEN THAT NEVER GOES RED. Against the live
#     inventory in the sibling repository on 2026-09-10:
#
#       total worktrees 29 · dirty per `git status --porcelain` 1 · TRACKED-dirty 0 · ignored-carrying 26
#
#     The 26 is the calibration — the same walk that returns 0 for tracked-dirty returns 26 for
#     ignored-carrying, so neither selector is dead. **A tracked-only predicate has 0 true positives
#     today, and the ONE genuinely at-risk worktree is untracked-dirty — exactly the class it would
#     have abstained on.** An untracked file is the more orphaned of the two: a tracked modification
#     at least has a committed ancestor to diff against, and an untracked file has nothing anywhere.
#     Rule 4b already denies `git clean -f` for that precise reason, and a floor that protects
#     untracked files from one spelling and not the other is not a floor.
#
#     -- THE RESOLVER, AND ITS TWO HONEST HOLES ----------------------------------------------------
#     `git worktree remove` takes exactly one positional and no value-taking option, so the positional
#     is the one token in the argument span that does not begin with `-`. Everything else is
#     recognized POSITIVELY and anything unrecognized is *unresolvable*, per #446's pattern: exactly
#     one `git … worktree remove` invocation, exactly one positional, no construct that can move the
#     working directory. A shape nobody has thought of lands in *unresolvable* by construction.
#
#     UNRESOLVABLE ABSTAINS HERE, AND #446 DENIES — the two rules decide the same state differently,
#     on purpose, and that ruling is written into #446's own comment at rule 7 rather than invented
#     here. The argument: #446 asks WHICH REPOSITORY a push lands in, where refusing to answer leaves
#     a latching publish unclassified; this rule asks WHETHER A DIRECTORY HOLDS UNCOMMITTED WORK, and
#     an unreadable answer to that is genuinely unknown. Denying on unknown would refuse every
#     `git worktree remove` the resolver cannot parse, the clean ones included, which is a wedge on
#     the loop's own cleanup path.
#
#     **SO THIS RULE FAILS OPEN AND SAYS SO.** Two holes, named rather than left to be discovered:
#
#       · AN UNRESOLVABLE TARGET PASSES. A chained form, a second invocation, a `cd`/`env` that moves
#         the directory, or a target that resolves to nothing registered — all abstain. The act runs.
#       · A RELATIVE TARGET IS RESOLVED AGAINST THE HOOK'S OWN CWD, not the caller's. This file never
#         reads the payload's `cwd` field and deliberately still does not: whether a `PreToolUse`
#         payload carries `cwd` AT ALL is UNMEASURED here — what is measured is that a `SubagentStart`
#         payload does (`dispatch-metrics-start.sh`'s header, #209), a different event. Adopting a
#         field whose presence is a hypothesis would make this limb resolve against an empty string on
#         any build that omits it. This is the one sub-problem NEITHER #443 NOR #446 owns; it is a
#         named residual in both. What would settle it: one registered probe hook echoing its stdin.
#
#     -- AND IT CLOSES NOTHING AGAINST A DELIBERATE ROUTE. SAY THIS BEFORE THE GREEN IMPLIES IT -----
#     A wrapper, an alias, a shell function or a script file invoked by path reaches the same directory
#     with this hook seeing only a name. And the obvious hand-spelled escape is not merely worse than
#     the guarded route — it is OPEN. Measured in the same run as the probes above:
#
#       rm -rf ../wt-probe   -> deny  (rule 4)
#       rm -r  ../wt-probe   -> NO DECISION,      and `Bash(rm:*)` sits in `allow` in both layers
#
#     `rm -r <worktree>` destroys the same bytes and is refused by nothing. **This rule raises the
#     cost of the ACCIDENTAL destruction and closes nothing against a deliberate one.** Whether
#     `rm -r` is itself a floor item is a separate irreversibility ruling and is NOT proposed here.
#
#     -- THE FALSE-POSITIVE DIRECTION, WHICH IS THE TEST THIS HAD TO PASS --------------------------
#     The standing rule is that a preventive control whose false positives are invisible to the person
#     it protects is worse than no control. A `PreToolUse` deny is the visible kind: the caller reads
#     the reason string in the same turn and the message names three remedies. That is the opposite of
#     the deleted `action-pendency-guard.sh`, whose errors landed before the owner saw anything. The
#     false-positive rate is additionally 0 of 29 against the live inventory, since the rule permits
#     everything git permits.
#
#     -- ONE SPELLING HAZARD MEASURED AND FOUND NOT TO TRANSFER ------------------------------------
#     #441 found `gh` accepting five spellings of its repo flag. `git` does not: `git -C<path> worktree
#     remove -f z1` returns rc 129 — git's own usage error — so it never executes, and the spaced form
#     is the only one this rule needs to read. This is a NEGATIVE result and it is recorded because
#     #443's body drew a WIDER conclusion from it than it supports: it said rule 7's old extractor was
#     therefore "complete for git". True of the SPELLING, false of the EXTRACTION, which #446 found
#     greedy and unscoped. Do not reuse that line as a resolver; it never was one.
if printf '%s' "$bare" | grep -Eq '(^|[^[:alnum:]_])git([[:space:]]+(-C[[:space:]]+[^[:space:]]+|-c[[:space:]]+[^[:space:]]+|--git-dir=[^[:space:]]+|--work-tree=[^[:space:]]+))*[[:space:]]+worktree[[:space:]]+remove([[:space:]]|$)'; then
  # EVERY `grep` IN THIS BLOCK CARRIES `|| true`, AND THREE OF THE FIVE ARE LOAD-BEARING. This file
  # runs under `set -euo pipefail`, so a grep that legitimately matches nothing exits 1, the pipeline
  # inherits it, and the whole guard dies with no output. A hook that dies silently reads to the
  # runtime as NO DECISION — that exact shape turned eight of rule 3b's force-push denials into silent
  # allows once already, measured 471/8 against a 479/0 baseline. Removing `|| true` from the two
  # greps that CAN match nothing reproduces it here: the target-flag grep (no `-C` on the invocation is
  # the commonest shape there is) took the suite to 545/32, and the positional grep to 574/3.
  #
  # **AND TWO OF THE FIVE ARE UNREACHABLE, WHICH IS WORTH SAYING RATHER THAN LETTING THE SENTENCE
  # ABOVE IMPLY OTHERWISE.** The `-oE` re-match on the next line and the `grep -c .` after it both run
  # only inside an `if` whose condition just matched the SAME pattern, so neither can come back empty.
  # Mutating each one's `|| true` away leaves the suite at 577/0 — no arm reddens, and none can. They
  # are kept as insurance against the trigger pattern and the `-oE` pattern drifting apart in a later
  # edit, which is a real hazard (they are duplicated literals) but is not a hazard any assertion here
  # observes. This paragraph exists because the first draft of it claimed all five were load-bearing,
  # and mutating the source is what falsified that.
  wt_hits="$(printf '%s' "$bare" | grep -oE '(^|[^[:alnum:]_])git([[:space:]]+(-C[[:space:]]+[^[:space:]]+|-c[[:space:]]+[^[:space:]]+|--git-dir=[^[:space:]]+|--work-tree=[^[:space:]]+))*[[:space:]]+worktree[[:space:]]+remove([[:space:]]|$)' || true)"
  # `grep -o | grep -c .`, never `grep -co`: with -o, BSD grep counts MATCHES and GNU grep counts
  # LINES, so `-co` would return different answers on a maintainer's macOS and in Ubuntu CI.
  wt_n="$(printf '%s\n' "$wt_hits" | grep -c . || true)"
  wt_dir=""
  if [ "$wt_n" = "1" ] \
     && ! printf '%s' "$bare" | grep -Eq '(^|[^[:alnum:]_.-])(cd|pushd|popd|chdir|env)([[:space:]]|$)|\(|GIT_DIR=|GIT_WORK_TREE=|GIT_CEILING_DIRECTORIES='; then
    wt_inv="$(printf '%s\n' "$wt_hits" | sed -n '1p')"
    # The argument span: everything after the matched `remove`, cut at the first shell separator so a
    # trailing `&& npm ci` contributes no tokens. Greedy `.*` is safe because wt_n is exactly 1.
    wt_args="$(printf '%s' "$bare" | sed -E 's/^.*[[:space:]]+worktree[[:space:]]+remove//' | sed -E 's/[;&|].*$//')"
    wt_pos_hits="$(printf '%s' "$wt_args" | tr ' ' '\n' | grep -vE '^-|^$' || true)"
    wt_pos_n="$(printf '%s\n' "$wt_pos_hits" | grep -c . || true)"
    # More than one target-naming flag on the invocation means guessing their precedence. Refuse to.
    wt_tflags="$(printf '%s' "$wt_inv" | grep -oE '(-C[[:space:]]+[^[:space:]]+|--git-dir=[^[:space:]]+|--work-tree=[^[:space:]]+)' || true)"
    wt_tn="$(printf '%s\n' "$wt_tflags" | grep -c . || true)"
    if [ "$wt_pos_n" = "1" ] && [ "$wt_tn" -le 1 ] 2>/dev/null; then
      wt_pos="$(printf '%s\n' "$wt_pos_hits" | sed -n '1p')"
      wt_base="$(printf '%s' "$wt_inv" | sed -nE 's/.*[[:space:]]-C[[:space:]]+([^[:space:]]+).*/\1/p')"
      [ -z "$wt_base" ] && wt_base="$(printf '%s' "$wt_inv" | sed -nE 's/.*--work-tree=([^[:space:]]+).*/\1/p')"
      [ -z "$wt_base" ] && wt_base="."
      case "$wt_pos" in
        /*) wt_cand="$wt_pos" ;;
        *)  wt_cand="$wt_base/$wt_pos" ;;
      esac
      wt_abs=""
      [ -d "$wt_cand" ] && wt_abs="$(cd "$wt_cand" 2>/dev/null && pwd -P || true)"
      # THE LOOKUP VERIFIES REGISTRATION, WHICH IS NOT DECORATION. Without it, a target that is a
      # directory but NOT a worktree would have its CONTAINING repository's status read instead, and a
      # dirty parent would produce a deny on a command git would have rejected anyway — a confidently
      # wrong verdict, which this file already holds is worse than a missed one. The MAIN worktree is
      # skipped for the same reason: git refuses to remove it, so a deny there would be noise. It is
      # always the first entry of `worktree list --porcelain`.
      wt_first=1
      while IFS= read -r wt_p; do
        [ -z "$wt_p" ] && continue
        if [ "$wt_first" = "1" ]; then wt_first=0; continue; fi
        wt_pabs="$(cd "$wt_p" 2>/dev/null && pwd -P || true)"
        if { [ -n "$wt_abs" ] && [ "$wt_pabs" = "$wt_abs" ]; } || [ "${wt_p##*/}" = "$wt_pos" ]; then
          wt_dir="$wt_p"; break
        fi
      done < <(git -C "$wt_base" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p' || true)
    fi
  fi
  if [ -n "$wt_dir" ]; then
    # THE SENTINEL SEPARATES "CLEAN" FROM "UNREADABLE", WHICH A BARE `|| true` WOULD COLLAPSE. Both
    # produce an empty string, and treating an unreadable worktree as clean is precisely the silent
    # fail-open this rule exists to remove. A porcelain line can never BE the sentinel — every one of
    # them begins with two status characters.
    wt_status="$(git -C "$wt_dir" status --porcelain 2>/dev/null || printf '__WT_UNREADABLE__')"
    case "$wt_status" in
      "" | __WT_UNREADABLE__) : ;;
      *) deny "Blocked: '$wt_dir' holds uncommitted work, and removing that worktree with force deletes it where it exists nowhere else — not in the reflog, not on the remote, not in the index. That is the same irreparability 'git reset --hard' is refused for. Note what this rule is NOT keyed on: it reads the TARGET, not the flag, so every abbreviation reaches it alike. Git itself refuses this removal unforced, and this rule denies exactly what git denies — a clean worktree, or one carrying only ignored build output, still removes with a bare 'git worktree remove'. Remedies, cheapest first: commit or 'git stash' inside '$wt_dir'; or run 'git -C $wt_dir status' to see what would be lost and delete those paths deliberately; then remove it unforced." ;;
    esac
  fi
fi

# 5. AWS secret writes — ~~DOWNGRADED TO `ask` 2026-09-05 (#383, slice S3)~~ **REVERTED TO `deny` the
#    same day (#383, S3-revert, owner: «reverte os três»).**
#
#    **THE REPARABILITY ARGUMENT BELOW IS UNCHANGED AND STILL TRUE. What failed is the REMEDY.** A hook
#    `ask` is answered automatically in this harness's default working mode — measured in the owner's
#    own interactive session right after the S3 merge, where the guard returned `ask` for the exact
#    command and the act then EXECUTED with no prompt. So these writes were not gated at all in the one
#    session that matters. The full measurement, and the general rule it produces — *the ladder
#    `deny -> ask -> context -> nothing` has a rung that does not hold here* — are recorded once, at
#    rule 3's site above, rather than three times.
#
#    THE ACT IS REPARABLE, AND THAT IS WHY THE DOWNGRADE WAS DEFENSIBLE. AWS keeps a prior version of both
#    things this rule matches, so a wrong write here is recoverable without a restore from anywhere
#    else:
#      · Secrets Manager versions every value and labels the previous one `AWSPREVIOUS`, so a bad
#        `put-secret-value` is undone by moving the `AWSCURRENT` stage back.
#      · `delete-secret` is a SCHEDULED deletion with a recovery window (7–30 days, 30 by default), and
#        `restore-secret` — which this rule also matched, i.e. it was denying the REPAIR — cancels it.
#      · SSM keeps parameter history, so a `put-parameter --overwrite` has the prior value behind it.
#
#    ~~This is the class the `ask` helper's comment describes exactly — the command cannot show whether
#    the write is the owner's intent, and his answer to the prompt IS the verification.~~ **STRUCK: the
#    class description is right and the mechanism is not available.** His answer is the verification
#    only where he is asked, and in auto mode he is not. **The pipeline still provisions secrets and the
#    agent still does not** — and now the guard is what says so again, rather than a prompt nobody sees.
#
#    **WHAT THE REVERT COSTS, NAMED RATHER THAN GLOSSED: `restore-secret` — the REPAIR — is denied
#    again.** S3 correctly observed that the old one-regex rule was refusing the act that undoes a
#    scheduled deletion. That defect returns with the revert, and it is accepted here rather than
#    quietly fixed, because carving `restore-secret` out is a FOURTH decision and this slice is
#    scoped to three. It is defensible on its own terms — the delete it repairs is itself denied to
#    the agent, so the repair is the owner's act by the same route — but it is a real narrowing and
#    the next person to touch rule 5 should decide it deliberately rather than inherit it.
#
#    ~~WHAT THIS COSTS, AND IT IS SMALLER THAN IT LOOKS: `aws` is in NEITHER the allow nor the deny list
#    of EITHER settings layer, so removing this rule outright would already have landed on a permission
#    prompt.~~ **The observation stands and it now argues the other way.** `aws` is unlisted in both
#    settings layers (re-read at head, 2026-09-05), so the layer beneath this rule offers a prompt —
#    and a prompt is exactly what auto mode answers. The hook `deny` is decided BEFORE the permission
#    system and is not softened by anything under it, which is why the verdict has to be here.
#
#    THE SIBLING THAT DID NOT MOVE, said here so the asymmetry is not read as an oversight: `gh secret
#    set/delete` (5b) KEEPS ITS DENY. GitHub Actions secrets have no version history and no recovery
#    window — the old value is gone the moment it is overwritten. Same word, different act.
#
#    ── THE RULE-6 PRE-EMPTION: STILL THERE, NO LONGER A NARROWING ──────────────────────────────────
#    **RE-CHECKED AT THE REVERT, because the question is exactly the kind that a revert answers
#    silently if nobody asks it. The answer: the pre-emption SURVIVES and its ARGUMENT DISSOLVES.**
#
#    The mechanism is unchanged — `deny()` and `ask()` both exit, so where this rule matches, rule 6
#    below never runs, and `aws secretsmanager delete-secret` matches both (rule 6's
#    `aws <service> (delete|terminate|...)-` family). What changed is that the two rules no longer
#    DISAGREE. Measured 2026-09-05, the same command across all three states:
#      aws secretsmanager delete-secret --secret-id x
#        pre-S3 (origin/main at 8c49382)  -> DENY   (rule 5, pre-empting rule 6's identical verdict)
#        S3 head (01069ca8)               -> ASK    (rule 5) <- the narrowing
#        this revert                      -> DENY   (rule 5, pre-empting rule 6 again)
#
#    So there is **nothing left to disclose as a narrowing**: the pre-emption now only decides which
#    MESSAGE the caller reads, and rule 5's is the more useful of the two (it names the recovery
#    window and points at `restore-secret`). It is kept as an attribution note rather than deleted,
#    because the mechanism is still live and the next downgrade proposed anywhere above rule 6 inherits
#    it. **The reader-facing consequence is now zero and the shape is not** — a rule that exits above
#    another rule is still pre-empting it, and that stays true whether or not the verdicts differ.
#
#    ~~The contrast with 3b's ordering defect, because the two look identical and are not.~~ **Both
#    collapsed into the same state at the revert, and the CONTRAST is what survives, because it is the
#    test rather than the instance.** There, rule 7 was stricter and RIGHT about its member, so
#    pre-empting it was a hole. Here rule 6 was stricter and the criterion did not reach this member,
#    so pre-empting it was the intended verdict. **The test is never "which rule is stricter" — it is
#    "which rule is right about the act."** Both pairs now agree on the verdict and differ only in the
#    message, so in both places the ordering is asserted by reason rather than by verdict.
#    **What is NOT covered: the rest of rule 6.** Every other `aws ... delete-*`/`terminate-*` denies,
#    and nothing here has ever loosened it.
#
#    ~~undisclosed~~ — the narrowing shipped at 9aca9d4 with no note anywhere, and was found by the
#    merge gate rather than by the slice. Recorded as the finding it was. It is also the reason this
#    paragraph was re-checked at the revert instead of assumed to unwind on its own.
if printf '%s' "$cmd" | grep -Eq 'aws[[:space:]]+secretsmanager[[:space:]]+(put-secret-value|create-secret|update-secret|delete-secret|restore-secret)'; then
  deny "Blocked: writing secrets via CLI. Secrets are provisioned by the pipeline, not by the agent. This was briefly an 'ask' (#383 S3) on the argument that Secrets Manager is REPARABLE — the previous value stays behind the AWSPREVIOUS stage, and 'delete-secret' only SCHEDULES a deletion with a recovery window that 'restore-secret' cancels — and that argument is still true. What failed is the remedy: a hook 'ask' is answered automatically in this harness's auto mode, measured in the owner's own session, so the downgrade produced a silent write rather than a prompt. Note this also denies 'restore-secret', which is the REPAIR — an accepted cost of the revert, since the deletion it repairs is denied to the agent too. If a secret genuinely must be written by hand, it is the human's own act."
fi
if printf '%s' "$cmd" | grep -Eq 'aws[[:space:]]+ssm[[:space:]]+put-parameter([[:space:]].*)?SecureString'; then
  deny "Blocked: writing a SecureString parameter. Secrets are provisioned by the pipeline, not by the agent. This was briefly an 'ask' (#383 S3) because SSM keeps parameter history, so the prior value survives an --overwrite — still true, and still not enough: a hook 'ask' is answered automatically in this harness's auto mode, so the downgrade produced a silent write. If this parameter genuinely must be written by hand, it is the human's own act."
fi

# 5b. Secret writes via gh, in any spelling. Same prefix-matcher blind spot as rule 7:
#     a deny on `gh secret set` does not see `gh -R <repo> secret set`, and `-R` is
#     exactly what the multi-repo convention prescribes. Matched semantically so the
#     allowlist can open `gh -R` without opening secret writes with it.
#
#     TWO CORRECTIONS, 2026-08-04, both measured rather than reasoned:
#       · IT KEPT ITS OWN SPACE-ONLY COPY of the `-R` pattern, so `gh --repo=o/r secret set X` and
#         `gh -Ro/r secret set X` came out ALLOW while the spaced form was denied. It now uses the
#         shared `gh_repo_flag`. A rule whose comment says "in any spelling" and means "in two of the
#         four" is worse than one that claims nothing.
#       · IT MATCHED `$cmd`, NOT `$bare`, because it was written above where `$bare` used to be
#         computed. So `git commit -m "gh secret set X"` — a message ABOUT the act — was denied as the
#         act, the same false positive `$bare` exists to prevent and that 5c/5e/5f each avoid.
if printf '%s' "$bare" | grep -Eq "(^|[^[:alnum:]_])gh${gh_repo_flag}[[:space:]]+secret[[:space:]]+(set|delete|remove)"; then
  deny "Blocked: writing or deleting a repository secret. Secret values are set by the human, never by the agent."
fi

# 5g. THE `gh` SUBCOMMANDS THE FLOOR DENIES AND THE HOOK COULD NOT SEE (2026-08-04).
#
#     Each of these is in the settings `deny` list, and for each one the `-R` spelling was ALLOW —
#     `gh -R owner/repo repo delete --yes` returned no decision from any layer. `repo delete`,
#     `release delete` and `workflow run` had no hook rule at all, so the floor's prefix entry was the
#     only thing between the agent and the act, and the then-live `Bash(gh -R:*)` walked around it.
#
#     ~~WHY A HOOK RULE RATHER THAN NARROWING THE ALLOW: removing `Bash(gh -R:*)` would break the
#     workspace's own prescribed multi-repo convention and push every legitimate cross-repo read to a
#     human prompt.~~ **STRUCK — THE PREMISE WAS FALSE, and it was the load-bearing half of the
#     argument.** The entry WAS removed, later the same day, and nothing was pushed to a prompt:
#     `gh <subcommand> --repo <o/r>` puts the flag AFTER the subcommand, so it still matches the
#     per-subcommand allow entries. The "convention would break" claim was never measured; it was
#     inferred from the flag's existence.
#
#     Struck rather than deleted because of what it would have cost the next reader: a comment
#     asserting that an entry this repo has already removed MUST exist is not stale documentation, it
#     is an instruction to re-introduce the defect.
#
#     WHAT SURVIVES, AND IT IS WHY THESE RULES STAY: the floor cannot express "the `-R` form of this
#     subcommand" at all. Removing the broad allow closed the shadowing, but the moment any broad
#     allow on `gh` returns — or a command reaches this hook that the floor never sees — the
#     per-subcommand deny is again blind to the flag. The hook rule is what does not depend on that.
#     Same argument that moved `gh api` (5f) and the `bash -c` payload (the unwrap at the top).
#
#     GROUPED BY WHAT THEY DO, because the deny messages differ:
#       repo delete/archive/rename — destroys or renames the repository itself. A rename also breaks
#         every OIDC trust pinned to the immutable subject, which is a documented outage in this
#         workspace, not a hypothetical.
#       release create/delete — publishes or unpublishes a public artifact. The `deploy` workflow's
#         `release` job owns this; a hand-made release desynchronises the tag, the VERSION file and
#         the published notes.
#       workflow run — dispatches CI, which is the one thing in this repo that holds AWS credentials.
#
#     NOT COVERED HERE, and named rather than omitted silently:
#       `claude mcp` — denied in the floor, no hook rule, and it needs none: there is no `-R`-style
#         flag convention between `claude` and `mcp`, and no allow entry shadows it, so the prefix
#         matcher sees every spelling it can be written in. The hook adds nothing.
#       `claude --dangerously-skip-permissions` — already rule 1, which matches the flag anywhere in
#         the string.
#       `gh pr merge --squash` — belongs with the merge gate, so it is enforced in 7b rather than here.
# SPLIT IN THREE 2026-09-05 (#383, slice S3). One regex matched `delete`, `archive` and `rename` and
# refused all three with one sentence; under the narrowed criterion only the first is irreparable.
#   delete  — KEEPS ITS DENY. The repository, its history, its Issues and its immutable OIDC subject id
#             are gone, and the id is not reissued on a re-create, so every AWS trust pinned to it
#             breaks in a way that re-creating the repo does NOT repair.
#   archive — `gh repo unarchive` exists. Reparable.
#   rename  — rename it back. The OIDC breakage the old deny text cited is real and IS repaired by the
#             same act, because the subject pins the immutable ID rather than the name — which is the
#             very property that makes a rename survivable and a delete not.
#
# **THE SPLIT IS KEPT; ARCHIVE/RENAME's VERDICT IS REVERTED TO `deny` the same day (#383, S3-revert,
# owner: «reverte os três»).** The three-way reading above is correct and stays — the acts genuinely
# differ, and they now carry different MESSAGES saying so. What is withdrawn is only the conclusion
# that *reparable* licenses an `ask` here, because a hook `ask` is answered automatically in this
# harness's default working mode: measured in the owner's own session, the guard returned `ask` and the
# act executed with no prompt. The full measurement and the general rule are at rule 3's site, once.
#
# ~~THE ORDER OF THESE TWO BRANCHES IS LOAD-BEARING~~ — **the ORDER is kept and what it buys shrank,
# exactly as at 3b and at rule 5's pre-emption; this is the third instance of one shape.** `deny`
# exits, so whatever runs first wins — but both branches now deny, so the order decides which reason
# the caller reads (delete's names the un-reissued OIDC subject id; archive/rename's names the undo).
# The measurement that produced this note is kept because it is still the reason not to reorder
# casually: widening the SECOND branch to include `delete` while it sits below is UNREACHABLE dead
# code — the suite stayed 412/0 under exactly that mutation, which reads like an uncaught defect and
# is not one. Under the revert the same mutation is invisible to every verdict arm as well, so the
# branch that answers is asserted by reason instead.
if printf '%s' "$bare" | grep -Eq "(^|[^[:alnum:]_])gh${gh_repo_flag}[[:space:]]+repo[[:space:]]+delete([[:space:]]|\$)"; then
  deny "Blocked: 'gh repo delete' destroys the repository itself — history, Issues, PRs and its immutable OIDC subject id, which is not reissued if you re-create a repository with the same name, so every AWS trust pinned to 'repo:<org>@<id>/<repo>@<id>:*' breaks permanently. This is the irreparable member of the family: 'archive' and 'rename' both reverse, and they are denied too (#383 S3-revert) for a different reason — not because they cannot be undone, but because a hook 'ask' does not reach the human in this harness's auto mode. This one would stand even if it did. This is the human's act, on the GitHub UI, never the agent's."
fi
if printf '%s' "$bare" | grep -Eq "(^|[^[:alnum:]_])gh${gh_repo_flag}[[:space:]]+repo[[:space:]]+(archive|rename)([[:space:]]|\$)"; then
  deny "Blocked: 'gh repo archive/rename' changes what the repository IS to everyone looking at it. This was briefly an 'ask' (#383 S3) on the argument that both REVERSE — 'gh repo unarchive' undoes an archive, a rename is undone by renaming back, and the AWS OIDC trusts survive because they pin the repository's IMMUTABLE id rather than its name — and that argument is still true. What failed is the remedy: a hook 'ask' is answered automatically in this harness's auto mode, measured in the owner's own session, so the downgrade produced a silent archive/rename rather than a prompt. Note 'gh repo delete' is a different act with a different message: the id is NOT reissued, so that one does not reverse at all. This is the human's act, on the GitHub UI, never the agent's."
fi
if printf '%s' "$bare" | grep -Eq "(^|[^[:alnum:]_])gh${gh_repo_flag}[[:space:]]+release[[:space:]]+(create|delete)([[:space:]]|\$)"; then
  deny "Blocked: creating or deleting a Release publishes or unpublishes a public artifact. The deploy workflow's 'release' job owns this — it bumps VERSION, tags and publishes in one pass, and a hand-made release desynchronises the three. Use 'gh release view/list' to inspect."
fi
if printf '%s' "$bare" | grep -Eq "(^|[^[:alnum:]_])gh${gh_repo_flag}[[:space:]]+workflow[[:space:]]+run([[:space:]]|\$)"; then
  deny "Blocked: 'gh workflow run' dispatches CI, which is the only place in this workspace holding AWS credentials — it can reach 'terraform apply' without the merge that is supposed to authorise it. Push the branch and let the PR gates run, or ask the human to dispatch. 'gh workflow list/view' and 'gh run view/list/watch' stay open."
fi

# 6. Clearly-destructive direct cloud mutations (cloud state escapes git).
if printf '%s' "$cmd" | grep -Eq 'aws[[:space:]]+[a-z0-9-]+[[:space:]]+(delete|terminate|deregister|destroy|remove|purge)-'; then
  deny "Blocked: destructive direct cloud mutation. Cloud state changes through the running app (staging) or the pipeline, never via direct aws CLI."
fi


# 5f. `gh api` THAT WRITES (owner, 2026-08-04). The back door that rules 5c and 7b each booked as a
#     permanently accepted gap, closed here — in the layer that can tell a read from a write.
#
#     ── SCOPED INTO #383 SLICE S3 AS A DOWNGRADE AND **NOT SHIPPED**. UNCHANGED AT HEAD. ───────────
#     The audit scored 5f a downgrade on the ground that it "cannot tell `-X DELETE repos/o/r` from a
#     comment POST", so it does not distinguish the case it exists for. S3's brief made shipping it
#     conditional on a `Bash(gh api:*)` line landing in the PROJECT `.claude/settings.json` first,
#     since only the GLOBAL layer carries one and that layer is out of scope for this Issue.
#
#     **THE PRECONDITION TURNED OUT NOT TO BE THE REASON TO STOP, AND SAYING SO PRECISELY MATTERS
#     MORE THAN STOPPING.** Measured 2026-09-05, rule 5f neutralised in a probe copy loaded with
#     `claude --plugin-dir`, the real plugin disabled, build 2.1.261:
#
#       session rooted IN the skills repo        `gh api probe-nonexistent -f a=b` -> DENIED
#       session rooted OUTSIDE any repo          same command                      -> DENIED
#         (both refusals were the PERMISSION LAYER's text, not a hook's)
#
#     So the audit's stated gap — "a session rooted elsewhere loses the project deny" — is **false on
#     this machine**: user-level settings are not repo-scoped, they apply at every root. The project
#     line is REDUNDANT here, not required. **Which removes the precondition and, in the same stroke,
#     removes the benefit**: where the static deny already shadows this rule completely, deleting the
#     rule changes nothing anyone can observe.
#
#     **AND WHERE IT IS NOT SHADOWED, DELETING IT IS A FLOOR REGRESSION.** `.claude/settings.json` does
#     NOT travel with a plugin install, so every consumer of this plugin has these hooks and none of
#     those deny entries. Asked directly, source-level, against a copy with 5f neutralised:
#
#       gh api -X DELETE repos/o/r          5f present -> deny        5f absent -> ABSTAIN
#       gh api repos/o/r/issues -f title=x  5f present -> deny        5f absent -> ABSTAIN
#       gh api repos/o/r/issues/1/comments  5f present -> ABSTAIN     5f absent -> ABSTAIN  (control)
#
#     The first row is the raw-API spelling of `gh repo delete` — the one member of 5g that THIS SAME
#     SLICE keeps as irreparable, because the immutable OIDC subject id is not reissued. 5f is the only
#     rule in this file that sees it in that spelling.
#
#     **THE HONEST VERDICT, WHICH IS NOT THE AUDIT'S: over-broad is a UX complaint, not an
#     irreparability finding.** The criterion asks whether the class CONTAINS an irreparable act, and
#     this one does. A rule that over-blocks reads is worth NARROWING; it is not worth deleting while
#     it is the only layer standing in front of repository destruction for everyone who is not the
#     owner. Narrowing it — and the KNOWN, ACCEPTED OVER-BLOCK noted further down is where that would
#     start — is a different slice with a different argument, and it is not this one.
#
#     WHAT WOULD CHANGE THIS: an endpoint-aware narrowing that keeps the destructive routes denied and
#     lets a comment POST through, or a decision that the plugin's floor is only ever the owner's floor
#     and consumers are on their own. The second is the owner's to make, not the audit's.
#
#     NUMBERED 5f, PLACED FIRST AMONG THE `gh` RULES, same convention as 5e below: the NUMBER is
#     lineage, the POSITION is deliberate. It runs before 5c and 7b because it is the route BOTH of
#     them book as their residual, so a reader arriving at either residual paragraph has already passed
#     the rule that closes it. Nothing here depends on the order — 5f matches `gh api`, which no other
#     rule matches at all — but a reader's understanding does.
#
#     ~~WHY IT IS HERE AND NOT IN THE FLOOR'S `deny`, WHICH IS WHERE IT LIVED FOR AN HOUR.~~ **THAT
#     HEADING IS FALSE AT HEAD, CORRECTED 2026-08-31 (#375): `Bash(gh api:*)` LIVES IN THE FLOOR'S
#     `deny` NOW, unqualified.** So this rule is not the only layer, and the paragraph below describes
#     a state that was undone by a later permission audit without anyone editing this comment. **Three
#     consequences, and the third is the one that bites:** (a) the deny message's closing sentence
#     ("READING through `gh api` is untouched") is **false on the owner's machine** — that read is
#     refused before this hook is consulted; (b) the floor entry is in an UNTRACKED user-level file, so
#     no gate here can see it and a consumer of this plugin gets 5f with no floor entry, which is a
#     DIFFERENT control than the one running here; (c) the loop depends on the capability it denies its
#     own agents — `session-plugin-version.sh` runs `gh api repos/…/releases/latest`, and it works only
#     because hook scripts execute outside the permission layer. **Whether to remove the floor entry is
#     its own decision with its own record and is NOT taken here**; what is corrected here is the claim.
#
#     ORIGINAL PARAGRAPH, KEPT BECAUSE ITS ARGUMENT IS STILL THE REASON THIS RULE EXISTS. The permission
#     audit added a blanket `Bash(gh api:*)` deny after finding the route was never denied at all,
#     merely unlisted, with one `Bash(gh *)` wildcard erasing even that. That deny was too broad: it
#     removed READ access to everything the `gh` subcommands do not expose, and this repo's own loop
#     uses that (`session-plugin-version.sh` reads the latest release through it; a reviewer verifying
#     a ratification reads comment metadata). The first symptom was already in the batch — a falsifier
#     example in `quality-assurance.md` had to be rewritten because it "named a command the loop cannot
#     execute". That was treated as a citation fix; it was the deny being too wide.
#
#     THE NARROWING THAT DOES NOT WORK, recorded so nobody proposes it again: denying only
#     `--method POST|PUT|PATCH|DELETE`. **`-f`/`-F` implicitly switch the request to POST**, so
#     `gh api repos/:owner/:repo/issues -f title=x` is a write with no `--method` anywhere — and that
#     is EXACTLY the command the audit found, creating an issue around the owner-opens-work rule. A
#     prefix matcher in settings.json cannot separate read from write here, which is the same reason
#     rules 7 and 8 exist at all. So the rule goes where the distinction is expressible.
#
#     `-X` IS MATCHED THOUGH THE BRIEF LISTED ONLY `--method`. It is `--method`'s real short form
#     (`gh api -X PATCH …`), and a rule that closes the long spelling while leaving the short one open
#     is the "which spelling did you happen to use" floor this file has already rejected twice (rule 4's
#     flag set, 5b's `-R`). Attached forms too: `--method=POST`, `-XPOST`.
#
#     THE COST THE OWNER ACCEPTED, AND IT IS THE WHOLE TRADE — stated here because it is the kind of
#     thing that becomes invisible the moment it works: this moves the control from the layer that
#     CANNOT fail open to the layer that CAN. This hook fails open by design — a parse error, a missing
#     `jq`, a malformed payload and it allows — and its own header says the static `deny` list is the
#     authoritative backstop. **For `gh api` that sentence is now false**: there is no static backstop
#     behind this rule, so a hook failure is an open door, not a degraded one.
#
#     SECOND INSTANCE OF THE SAME INVERSION, WHICH MAKES IT A PATTERN RATHER THAN AN EXCEPTION.
#     `tech-lead` recorded the same shape for `bash -c`. Both moved from a matcher that could not
#     express the rule to a hook that can, and both paid the same price. Two is enough to say what the
#     pattern costs: every rule that migrates here for expressiveness removes one more thing the
#     fail-open header's promise still covers. The header should eventually stop claiming it in
#     general, and that is a record change, not a hook change.
#
#     Case-insensitive (`-i`) so `--method post` and `-X Post` are caught. The only side effect is that
#     `GH API` would match, which is not a real command and is harmless to deny.
#
#     KNOWN, ACCEPTED OVER-BLOCK: `gh api -X GET -F per_page=100` is a read carrying a field flag, and
#     it is denied. It is denied in the safe direction, the query-string form (`?per_page=100`) is right
#     there, and the deny message names it — a rule that tried to model gh's own read/write inference
#     would be back to guessing intent from a string.
#
#     Matched on `$bare`, so `git commit -m "gh api -f title=x"` — a message ABOUT the act — is not the
#     act. That trap has now caught a version of THREE different rules in this file (5c's, 5e's, and it
#     would have caught this one), which is why it is convention rather than case-by-case care.
#     `gh_repo_flag` and `$bare` are both defined at the top of the file now — see the normalisation
#     block beside `cmd`. They were local to whichever rule first needed them, which is how the file
#     ended up with THREE spellings of "an optional -R before the subcommand", two of them space-only.
#
#     `gh_api_write` — THE ATTACHED VALUE, fixed 2026-08-04 after `security` measured `-ftitle=x` as
#     ALLOW. The alternation required space/`=`/EOL after `-f`, and pflag also accepts the value
#     ATTACHED, so `-ftitle=x`, `-Ftitle=x` and `-fmerge_method=merge` all walked past — **the audit
#     route respelled**, at a moment when this rule was the only layer left holding it. The short forms
#     now carry NO trailing anchor: inside a `gh api` command every token beginning `-f`/`-F` is a field
#     flag (pflag has no other `-f*` short flag there), so the anchor bought nothing and cost the fix.
#     The long forms keep `([[:space:]=]|$)`, which is what stops `--fieldwork` matching `--field`.
gh_api_write='(--method|-X)[[:space:]=]*(POST|PUT|PATCH|DELETE)|(-f|-F)|(--field|--raw-field|--input)([[:space:]=]|$)'
if printf '%s' "$bare" | grep -Eqi "(^|[^[:alnum:]_])gh${gh_repo_flag}[[:space:]]+api([[:space:]]+[^[:space:]]+)*[[:space:]]+(${gh_api_write})"; then
  deny "Blocked: this \`gh api\` call WRITES (it carries --method POST/PUT/PATCH/DELETE, -X, -f/-F/--field/--raw-field, or --input; note that -f and -F make the request a POST on their own). The raw API is the back door around the rules that own these acts — opening an issue (5c/5d) and merging a PR (7b) — so a write here is the one spelling those gates cannot see. Use the gh subcommand for the act instead, so the rule that owns it applies: \`gh issue create\`, \`gh pr merge\`, \`gh pr comment\`. THIS RULE leaves READS untouched — drop the field flags and pass query parameters in the endpoint (\`gh api 'repos/o/r/issues?state=open'\`) — but a static \`Bash(gh api:*)\` deny may sit in the settings floor ABOVE this hook and refuse the read anyway; that is a different layer and this message cannot see it. And where an act has NO gh subcommand at all — creating a milestone, measured: \`gh milestone --help\` -> unknown command — this rule's remedy is unexecutable and the act needs its own reviewed route: \`bash scripts/milestone-create.sh\`. NOTHING IN THIS FILE GUARDS THAT ROUTE — the rule that did (11) was removed 2026-09-04 (#383). It prompts only because \`scripts/\` matches no allow entry in either settings layer, which is an absence and not a control."
fi

# 5e. THE COPY LENS DOES NOT WRITE TO A PUBLIC SURFACE (owner, 2026-08-04).
#
#     NUMBERED 5e, PLACED BEFORE 5c, and the order is deliberate rather than sloppy. `gh issue create`
#     is matched by BOTH this rule and 5c/5d; whichever runs first is the one whose reason the caller
#     reads. 5d would deny `product-lead` already — "a subagent does not open work" — which is true and
#     is not the reason that matters here. If this rule sat after 5c it would name a subcommand it can
#     never reach, and a rule that claims a case it does not decide is the "mechanism the file claims
#     and does not run" defect recorded further down. So it runs first, and all three subcommands it
#     names are genuinely its own.
#
#     WHAT THIS REPLACES, because the remedy it replaces was the one already written down. The roster
#     merge folded `marketing-lead` into `product-lead`. `marketing-lead` declared `tools: Read, Grep,
#     Glob` — no `Bash`, deliberately: it was the one persona reading `.brand/` (private, gitignored
#     positioning material) while its output routinely lands in a comment on a PUBLIC repo, so the
#     boundary was a CAPABILITY, not a promise. The merged persona inherits `Bash`, so that capability
#     became an instruction — and an instruction is only as strong as the model's attention.
#
#     ADR-0002 names the remedy as "split the tool grant", i.e. un-merge the persona the owner had just
#     merged, at the cost of the second agent output the merge existed to remove. `security` escalated
#     that this OVER-PRICES the fix and the owner accepted the cheaper one: this file ALREADY keys two
#     denials on `agent_type` (5d, 7b) — a harness-stamped signal the model cannot write — so the
#     boundary can be restored here, at the floor, without touching the roster. It costs the persona
#     nothing it declares it needs: its own body says it "writes nothing — no issue, no commit, no
#     comment, no edit to any file", and `gh pr list` / `gh issue list` / `gh pr view` are untouched,
#     which is what its `Bash` grant is actually for.
#
#     PRE-EMPTIVE, NOT POST-LEAK, and that is the whole reason it is mechanical rather than reviewed:
#     a paraphrase of the positioning layer in a public comment is NOT revertible by deleting the
#     comment. Deletion removes the artifact, not the disclosure — the same irreversibility class as
#     an OG card an unfurl has already pinned. `quality-assurance` reviewing the persona's output
#     afterwards cannot unpublish it.
#
#     WHERE THE FINDING GOES: `quality-assurance` quotes the verdict onto the PR, VERBATIM, under its
#     own marker, and its criterion 10 is not satisfied until that text is there. That is a decided
#     mechanism (owner, 2026-08-04, ADR-0006), so the message says it plainly — a denial that only
#     refuses teaches the model to route around it.
#
#     THE SEQUENCE IS RECORDED BECAUSE IT IS INSTRUCTIVE, NOT BECAUSE THE FILE NEEDS THE HISTORY. It
#     ran in three moves inside one day, and the final state alone teaches none of it:
#
#       1. THE CITATION WAS FALSE WHEN WRITTEN. This message originally said the finding reaches the PR
#          "— the mechanism ADR-0006 already names, not one invented here." ADR-0006 named no such
#          mechanism: it named two gatekeepers posting their OWN verdicts under their OWN markers, one
#          verifying the other. A gate quoting a THIRD party's verdict is the RELAY shape, which that
#          record exists to refuse and which its amendment introduced as an explicitly UNDECIDED,
#          weaker option. So the rule booked an existing guarantee against an open question — and it
#          landed on the one reader who cannot check it, the persona being denied.
#       2. `tech-lead` CAUGHT IT AND THE MESSAGE WAS CORRECTED TO CLAIM LESS — that publishing was a
#          consequence of this deny rather than a guarantee, and that nothing assured it. That was the
#          right fix for the state of the record at the time, and it was right for about an hour.
#       3. THE OWNER THEN DECIDED TO MAKE THE ORIGINAL CLAIM TRUE. Forced by two things, both measured:
#          under 5e the copy lens that found the ADR-0043 falsehood on `-io`#349 would have had no way
#          to post it; and the alternative — the invoking context remembering to ask the lens to post —
#          failed five times out of five in a single session, criterion 10 unverified each time.
#
#     WHAT THE SEQUENCE TEACHES, and it is why all three moves are kept rather than the last one:
#     **a record is a source for what was DECIDED, not for what something else DOES — and decisions
#     move.** Both halves matter. Move 1 is the first error: citing a record for a mechanism it did not
#     contain. Move 3 is the half a reader would otherwise mislearn — the fix for a false citation is
#     never "wait for the claim to come true", it is to claim less until someone with the authority
#     decides. The wording was wrong; the deference was right.
#
#     Matched on `$bare`, AFTER quoted spans are collapsed — 5c's suite caught a version denying
#     `git commit -m 'gh issue create notes'`, a message ABOUT the act rather than the act. And the
#     optional `-R`/`--repo` (spaced, attached, or `=`) before the subcommand is the rule-5b convention:
#     a prefix that only knows `gh pr comment` does not see `gh -R owner/repo pr comment`.
#
#     FALLS THROUGH FOR EVERYONE ELSE — no `exit 0`, no `return`. The most expensive lesson in this file
#     is 5d's: an early return from mid-script unreached rules 7 (trunk push), 7b (merge) and 8
#     (composition), so a composed command came out with NO decision at all. `deny` is terminal by
#     design and that is correct; an ALLOW here must never be.
# `gh_repo_flag` is defined above rule 5f, which is the first rule that reads it — see the note there.
#
# INVERTED FROM A DENYLIST TO AN ALLOWLIST (#187, 2026-08-13). The `writer` persona — renamed
# `content-writer` at #317, so this paragraph narrates a name that no longer resolves — reads `.brand/`
# (private positioning material) to draft public-facing prose — the same shape `product-lead` was
# denied for — and probing `agent_type=…:writer` against the OLD form (`case ... *:product-lead) deny
# ;; esac`, everything else falls through ALLOW) found it posts straight through with no decision at
# all. Naming every persona that must NOT post, one at a time, is the same "absent is not a state"
# failure ADR-0004's "Permission entries have three states, and absent is not one" section records for
# the AWS floor (record 0018 until 2026-08-20, absorbed there): a new persona that reads private material and is simply
# never added to this list posts by default, silently. The fix is deny-unless-cleared: name the
# personas ALLOWED to post directly, and anything else — including a future persona nobody remembered
# to list here — denies by default.
if printf '%s' "$bare" | grep -Eq "(^|[^[:alnum:]_])gh${gh_repo_flag}[[:space:]]+(pr[[:space:]]+comment|issue[[:space:]]+(comment|create))([[:space:]]|\$)"; then
  case "$agent_type" in
    ""|*:developer|*:tech-lead|*:agents-lead|*:quality-assurance)
      : ;;  # allowlisted — none of these reads .brand/ as a matter of course, and each posts as part
            # of its normal work (verdicts, findings, task filing). Falls through to the rest of the
            # file, same as before.
    *:product-lead)
      deny "Blocked: \`product-lead\` writes nothing to a public surface. It reads the private positioning layer (\`.brand/\`) and \`gh pr comment\`/\`gh issue comment\`/\`gh issue create\` publish to a public repo — a paraphrase of that material in a comment is not revertible by deleting the comment. This restores the capability boundary the merged-away \`marketing-lead\` had (no Bash at all); reading the queue (\`gh pr list\`, \`gh issue list\`, \`gh pr view\`) is untouched. Return the finding in your verdict — it still reaches the PR: \`quality-assurance\` quotes your verdict there VERBATIM under its own marker, and its criterion 10 is not satisfied until that text is on the PR (owner decision 2026-08-04, recorded in ADR-0006). Say in your return that the finding needs to reach the PR, and write it so it can be quoted as it stands. agent_type='${agent_type}'." ;;
    *:content-writer)
      deny "Blocked: \`content-writer\` writes nothing to a public surface directly. It reads the private positioning layer (\`.brand/\`) to draft — the same shape \`product-lead\` is denied for, and for the same reason: a paraphrase of private material in a public comment is not revertible by deleting the comment. Drafts go through \`Write\`/\`Edit\` onto tracked files (\`content/blog/**\`, site copy, a social-post draft) for the owner's review, never straight to \`gh pr comment\`/\`gh issue comment\`/\`gh issue create\`. agent_type='${agent_type}'." ;;
    # `content-reviewer` (#317) is named EXPLICITLY rather than left to the `*)` catch-all below, and the
    # difference is not cosmetic. The catch-all denies a persona nobody has decided about; naming this one
    # records that the decision WAS made and which way it went, and it is the difference ADR-0004's
    # "absent is not a state" section turns on — a deny by omission and a deny by decision are the same
    # behaviour and different facts, and only one of them survives someone later reading the rule and
    # assuming the gap was an oversight. It reads the same private layer for the same reason: it judges a
    # draft sourced from `.brand/` against `published-voice`, so its findings quote that material back.
    *:content-reviewer)
      deny "Blocked: \`content-reviewer\` writes nothing to a public surface directly. It reads the private positioning layer (\`.brand/\`) to judge a draft against \`published-voice\`, so a finding of its own can quote that material — the same shape \`product-lead\` and \`content-writer\` are denied for, and not revertible by deleting the comment. Its round goes to a TRACKED file on the same branch (\`docs/content-review/<slug>.md\`, one \`## Round\` section per round, closed with \`CONTENT-REVIEW-FINDINGS\` or \`CONTENT-REVIEW-CLEAR\`) through \`Write\`/\`Edit\`, where it lands in the diff the owner already reads. That file is the artifact, not a workaround for this deny. agent_type='${agent_type}'." ;;
    # `scrum-master` (#375) is named EXPLICITLY for the same reason `content-reviewer` is, and its REASON
    # is a different one — which is precisely why leaving it to the catch-all loses something. The other
    # three deny because they read `.brand/` and a paraphrase of private material in a public comment is
    # not revertible. This one reads nothing private. It denies because it declares `tools: []` — an
    # explicit empty grant, measured as the only spelling that means nothing — so it holds no `Bash` and
    # cannot issue this command at all. A posting call arriving under this `agent_type` is therefore an
    # impossible payload, and the honest verdict is DENY rather than the catch-all's "nobody has decided
    # about you yet": someone has, and the decision is that this profile's whole output is the SELECTION
    # RECORD it returns to the main session, which executes it.
    *:scrum-master)
      deny "Blocked: \`scrum-master\` posts nothing, and the reason is narrower than the other denies in this rule: it declares \`tools: []\` — an explicit empty grant — so it holds no \`Bash\` and cannot issue \`gh pr comment\`/\`gh issue comment\`/\`gh issue create\` at all. A posting call arriving under this agent_type is an impossible payload, not a capability question. Its whole output is the SELECTION RECORD it RETURNS; the main session is what acts on it, including any comment that record says is owed. Writing the act in the past tense is a false claim about the loop's own state. This deny is BY DECISION, not by omission — it is not the catch-all's 'nobody has decided about you yet'. agent_type='${agent_type}'." ;;
    *)
      deny "Blocked: agent_type='${agent_type}' is not on this rule's allowlist for posting directly (\`gh pr comment\`/\`gh issue comment\`/\`gh issue create\`). New personas default to DENY here — deliberately, per ADR-0004's 'absent is not a state' — until someone decides they belong on the allow side above and adds them by name. If this SHOULD be allowed, that is a decision to make explicitly, not a gap to route around." ;;
  esac
fi

# 5c. OPENING WORK. Only the owner decides that something should exist. What is guarded is UNALIGNED
#     work entering the queue — NOT the act of recording work the owner already asked for.
#
#     THIS RULE WAS WRONG AND IS CORRECTED HERE, kept as a correction rather than a rewrite because the
#     way it was wrong is the lesson. It denied `gh issue create` outright, on the reasoning that "was
#     this asked for" is not mechanically observable while "is this creating an issue" is — so it
#     guarded the observable step instead. That substitution is the defect. The owner named it twice:
#
#         "o problema é voce gerar demanda por si mesmo para voce trabalhar"
#         "nao é aceitavel eu ter que abrir por conta propria a feature toda vez que alinharmos algo"
#
#     A blanket denial does not prevent unaligned work; it taxes ALIGNED work, and the tax falls on the
#     owner, who then has to type the command for something they had just asked for. Guarding the
#     observable proxy rather than the real thing is not a conservative approximation — it inverted who
#     pays.
#
#     THE FIX USES A SIGNAL THAT IS BOTH OBSERVABLE AND HONEST: `agent_type`, stamped by the harness and
#     unforgeable by the model (see rule 7b). It splits the two cases the old rule conflated.
#
#       - A SUBAGENT still cannot file. This is where the measured failure actually happened (below):
#         issues born inside a review of something else, by a persona with no access to the owner and
#         no way to know whether anyone wants the work. It reports the finding upward; that is its job.
#         ~~Full stop.~~ **One exception since #124 — see 5d below:** `developer` may file issues,
#         because filing tasks under an approved story is decomposing work the owner already approved,
#         not opening work. Every other subagent is denied exactly as this paragraph describes.
#         ~~The parent is verified against the tracker rather than read from the command.~~ **Struck
#         2026-08-02:** it is not verified here at all any more. The hook cannot decide whether an
#         issue is a decomposition — four rounds of trying is the evidence — so that rule moved to
#         `agents/developer.md` and the `quality-assurance` gate. See 5d for what was deleted and why.
#       - ~~THE MAIN AGENT ASKS. Alignment is a fact about a conversation, and the main loop is the only
#         place that conversation exists — so it is the only place the question can be put to the one
#         party who can answer it. One keystroke, on a prompt showing the title.~~ **STRUCK 2026-08-03 —
#         THE MAIN AGENT NOW FALLS THROUGH, exactly as `developer` does.** The paragraph is right that
#         the conversation is where alignment lives and wrong about what follows from it: BECAUSE the
#         conversation is right there, the owner is already watching the call and does not need to be
#         asked about it. See the asymmetry below, which is the whole reason for the change.
#
#     ~~This answers the old comment's own objection — "an exemption the model can invoke is not a
#     boundary" — rather than ignoring it. It is right about `deny`: a flag meaning "the owner asked for
#     this" would be the model vouching for itself. It does not reach `ask`, because the model is not
#     the one deciding. The owner is, per issue, before anything is created.~~ **Struck with the
#     paragraph it defends.** Nothing is put to the owner here any more; what remains against a main
#     agent opening unaligned work is a behavioural rule in its instructions, and that cost is booked
#     below and in ADR-0004 rather than left to be discovered.
#
#     THE ASYMMETRY THAT DECIDES IT (owner, 2026-08-03), and it is a property of the CALLER, not of the
#     command — which is why no matcher was needed to find it:
#
#       A SUBAGENT'S `gh issue create` IS INVISIBLE.  It runs unattended, in a context the owner is not
#         reading, and reaches them only if the agent chooses to report it. Nothing outside the hook
#         observes it. That is why the deny below is untouched.
#       THE MAIN AGENT'S IS VISIBLE BY CONSTRUCTION.  The owner is IN the conversation, watching the
#         tool call happen, and can interrupt it. The act is already observed before the hook speaks.
#
#     So the prompt was charging a click to the one case that was already observable, while the case
#     that genuinely is not observable — every non-`developer` subagent — was and remains denied
#     outright. THIS FILE HAS NOW MADE THAT INVERSION TWICE. The 2026-07-31 correction below found a
#     blanket denial that "taxed ALIGNED work and the owner paid"; this is the same inversion one caller
#     further out, measured the same way — the owner hit the prompt twice in one evening filing two
#     issues he had just asked for in that same conversation.
#
#     THE COST, BOOKED NOT BURIED: nothing mechanical now stops the MAIN AGENT from opening work nobody
#     asked for. The measured failure this guarded against was 32 issues created against 13 closed in
#     one session across both repos, roughly 13 of the 32 generated by REVIEWING something else. What
#     remains against it is (a) the subagent deny below, which is exactly the review-generated case, and
#     (b) a behavioural rule in the main agent's instructions. That is the shape ADR-0004's 2026-08-02
#     amendment already chose for `developer` — *mechanism where the act is irreversible, skills where
#     the rule is a judgement* — and opening an issue is reversible by closing it.
#
#     THE FAILURE THIS COMES FROM, measured rather than imagined: in one session the queue grew by 19
#     issues net, and roughly 13 of them were born inside a REVIEW of something else. The reviewer's own
#     Definition of Done said "adjacent debt filed as an Issue", so every finding became tracked work
#     nobody had decided to do. The queue stopped describing the product and started describing how hard
#     the agents had looked at it — and a drain that produces more than it consumes never ends.
#
#     ~~NO ALLOWED SPELLING OF `gh issue create`, deliberately.~~ Superseded above — the objection is
#     answered by moving the decision to the owner rather than by inventing a self-vouching flag. What
#     survives from it: there is still no spelling the MODEL can use to exempt itself.
#
#     ~~And a subagent still has none at all.~~ **False since #124.** `developer` is exempt — and the
#     exemption is keyed on `agent_type`, which the HARNESS stamps and the model cannot write. So the
#     sentence above still holds in the form that matters: there is no *spelling* that exempts anyone.
#     What the exemption no longer carries is a check that the issue is really a decomposition; that
#     was attempted for four rounds and is now the persona's rule and the gate's, not the floor's.
#
#     ~~THE `gh api` ROUTE IS A NAMED ACCEPTED GAP~~ — **CLOSED 2026-08-04 BY RULE 5f, IN THIS FILE.**
#     `gh api` carrying a write indicator is denied; a bare `gh api <endpoint>` read is not. The suite
#     asserts both halves.
#
#     THE ROUTE TO THAT ANSWER IS RECORDED BECAUSE IT MOVED TWICE IN ONE DAY, and the intermediate
#     state is the instructive one:
#
#       1. The permission audit found `gh api` was never denied at all — merely unlisted, and one
#          `Bash(gh *)` wildcard erased even that. It added a blanket `Bash(gh api:*)` to the floor's
#          `deny`, for reasons unrelated to this rule, and thereby DISCHARGED A RESIDUAL ADR-0004 HAD
#          BOOKED AS PERMANENTLY ACCEPTED, as a side effect.
#       2. That deny was TOO BROAD. It took the READ path with it — everything the `gh` subcommands do
#          not expose, which this repo's own loop uses — and the first symptom was already inside the
#          same batch: a falsifier example in `quality-assurance.md` had to be rewritten because it
#          "named a command the loop cannot execute". That read as a citation fix and was a symptom.
#       3. So it was re-expressed HERE, in the layer that can tell a read from a write, and removed
#          from the floor. See rule 5f for why a prefix matcher provably cannot make that distinction
#          (`-f`/`-F` imply POST with no `--method` present) and for the cost the owner accepted.
#
#     BOTH GENERALISATIONS SURVIVE THE MOVE — only the layer changed. A residual booked "permanent" is
#     a statement about the layer that booked it, not about the system. And a gap can stop being real
#     without anyone editing the file that describes it, which is why these comments are corrected
#     rather than left to age — this passage has now been corrected TWICE in one day, once when the
#     floor closed the route and once when the hook took it over.
#
#     WHAT REMAINS TRUE, AND IS WHY 5f IS A SEPARATE RULE RATHER THAN A WIDENING OF THIS ONE: matching
#     `gh api` *as an issue-creating command* was attempted here for two rounds and each version was
#     wrong — reading the collapsed command let a quoted URL through; reading the raw command blocked
#     `git commit -m "gh api …"`, a message ABOUT the act. 5f does not repeat that attempt. It does not
#     ask WHICH endpoint is being called or what the call means; it asks only whether the command
#     WRITES, which is visible in the flags. That is the difference between a rule that can be right
#     and one that keeps failing to be what its comment claims.
#
#     Matched semantically for the same reason as 5b: `gh -R <repo> issue create` must not slip past a
#     prefix that only knows `gh issue create`. And matched on `$bare`, AFTER quoted spans are collapsed —
#     the suite caught the first version denying `git commit -m 'gh issue create notes'`, which is a
#     message about the act, not the act.
#     THE FLAG CLASS HERE WAS A SPELLING BEHIND THE SHARED ONE — `-R[[:space:]]*` where
#     `gh_repo_flag` reads `-R[[:space:]=]*` — and converging it is HYGIENE, NOT A FIX (2026-08-23).
#
#     ~~`gh -R=owner/x issue create` matched NOTHING and the whole subagent issue gate was off for
#     that spelling.~~ **FALSE, struck the same day it was written, and struck rather than deleted
#     because of HOW it was caught.** It was written from the shape of the defect next door (rule 7c,
#     below) instead of from a measurement, it read plausibly, and it survived review of its own diff.
#     What caught it was mutating this line back and watching the four new `-R=`/`-Rx`/`--repo=`
#     assertions in `permission-guard.test.sh` stay GREEN — a claimed fail-open with no test able to
#     see it, which is the one shape this repo treats as disqualifying.
#
#     WHY IT IS EQUIVALENT HERE, WHICH IS THE PART WORTH KEEPING. This rule uses the class in a
#     MATCHER, inside an OPTIONAL group, followed by a greedy `[^[:space:]]+`. Against `-R=owner/x`
#     the drifted class matches `-R`, `[[:space:]]*` matches empty, and the value class then swallows
#     `=owner/x` whole. Both spellings match; nothing was open. Measured over all six spellings.
#
#     SO THE DIVERGENCE WAS LATENT, NOT LIVE — and latent is still worth closing, because it goes live
#     the moment the class is used to EXTRACT rather than to match: the capture boundary then lands
#     inside the value and the `=` leaks into the slug. That is exactly what it did in `wip-guard.sh`
#     (`gh pr list -R =owner/x` failed to resolve, and the guard exited ALLOWING the create), and it
#     is one of the two things rule 7c got wrong below. The same characters, harmless in one position
#     and a fail-open in the other, is why the copies are converged rather than each judged on its own
#     merits.
#
#     Found because the flag-class grep `inventory-counts.test.sh` already ran ACROSS the two hooks,
#     pointed at this ONE file, returned three different classes at three rules. (That grep is not
#     quoted here on purpose — a comment carrying the pattern would itself read as a fourth copy.)
#     It now asserts they are identical within this file, not only across the two hooks.
if printf '%s' "$bare" | grep -Eq '(^|[^[:alnum:]_])gh([[:space:]]+(-R[[:space:]=]*|--repo[[:space:]=]*)[^[:space:]]+)?[[:space:]]+issue[[:space:]]+create'; then
  if [ -n "$agent_type" ]; then
    # 5d. DECOMPOSING IS NOT OPENING (#122, gitflow-single-env). One narrow exception, and the
    #     distinction it rests on is real rather than a convenience:
    #
    #       OPENING SCOPE   is creating work nobody asked for — still denied, for every subagent.
    #       DECOMPOSING     is dividing work the owner already approved and the leads ratified.
    #
    #     A task under a `ready` story adds nothing: the story passed the owner and the leads'
    #     referendum, and the task only makes visible what was already authorised. Denying it would
    #     tax the flow the model exists to create — the same inversion the 2026-07-31 correction
    #     found in this very rule, where a blanket denial taxed ALIGNED work and the owner paid.
    #
    #     ~~THE PARENT IS VERIFIED, NEVER READ FROM THE COMMAND. That is the whole difference
    #     between an exception and a hole: a condition satisfied by writing the command differently
    #     is a convention, and this file spent the day removing conventions from the floor. So the
    #     `#N` is looked up — the story must EXIST and carry `ready`. A model that invents a parent
    #     invents one that fails the lookup.~~
    #
    #     ~~FAILS CLOSED. No `gh`, no network, no answer → denied, exactly as before. A subagent
    #     that cannot prove the parent reports instead of creating blind.~~
    #
    #     **BOTH STRUCK 2026-08-02 — nothing is looked up any more and there is no lookup to fail.**
    #     The verification they describe is deleted; see the block below for what replaced it and
    #     why. Struck HERE, in place, rather than only corrected further down: a claim and its
    #     retraction twenty-five lines apart is a claim, because the reader who stops at this
    #     paragraph never reaches the retraction. The suite is the falsifier — `no gh: nothing to
    #     look up any more` asserts ALLOW where this text says denied.
    #     AND IT IS THE BUILDER'S EXCEPTION, NOT EVERY SUBAGENT'S. The first version of this rule
    #     let any subagent through on a ready parent, and the suite caught it: `quality-assurance`
    #     and `security` citing a story would have been reviews opening work, which is the rule the
    #     exception is supposed to preserve rather than erode. Decomposing is an act of EXECUTION,
    #     so it belongs to the one persona that executes.
    #     ~~A FLAG~~, NOT `exit 0` — the one lesson from those four rounds that survives the deletion,
    #     and it outlived the flag itself: `developer_may` is gone (2026-08-03, with the ASK it fed),
    #     so the exempt branch is now a literal no-op that continues. The lesson is the CONTINUING,
    #     never the flag —
    #     because it was never about intent either. An earlier version returned from the middle of
    #     the script and everything below it stopped running: the trunk-push deny (7), the merge
    #     gate (7b) and the composition check (8). `gh issue create … && git push origin main` came
    #     out with NO decision at all, where before it was denied twice over. An exception in one
    #     rule silently became a bypass of the whole floor. Falling through is the only safe shape.
    case "$agent_type" in
      *:developer) : ;;  # a no-op that CONTINUES to EVERY rule below this block — see the `NOT exit 0` note above
      *) deny "Blocked: a subagent does not open work. Filing tasks under an approved story belongs to \`developer\`, the persona that executes them — a review citing a story is still a review opening work. Report the finding in your verdict and let the owner decide whether it becomes an issue." ;;
    esac
    #     ~~AND THE PARENT IS VERIFIED, NEVER READ FROM THE COMMAND.~~ **Struck 2026-08-02, and the
    #     strike is the point of the rule now.** For four rounds this branch tried to verify, in the
    #     hook, that a `gh issue create` was a decomposition: a `Parent: #N` marker read from the
    #     body — or from the body FILE, since that is how this repo writes bodies — word-anchored so
    #     `apparent #122` did not count, first-match-not-last so a trailing unrelated number did not
    #     authorise it, with the repo read from `$bare` so a `-R` inside `--body` could not point the
    #     lookup at a different repo, then `gh issue view` to confirm the story carried `ready`.
    #
    #     Every one of those was a real defect, correctly fixed, and each fix left the next spelling
    #     open — because **intent is not in the command string**. That is now a recorded decision
    #     (ADR-0004, amendment 2026-08-02) rather than a lesson this file kept re-learning:
    #
    #         Mechanism where the act is irreversible. Skills where the rule is a judgement.
    #
    #     "Is this issue a decomposition of approved work, or is it scope somebody invented?" is a
    #     judgement. A matcher cannot read it, and the eighty lines that tried are deleted here.
    #
    #     WHAT REPLACES IT — and it is deliberately weaker. `developer` may create issues; the rule
    #     it must follow ("only a task under a story carrying `ready`, referencing its parent") lives
    #     in `agents/developer.md`, where a judgement rule can actually be stated, and the
    #     `quality-assurance` gate verifies it on the task's own MR. **Nothing mechanical stops a
    #     `developer` from opening work nobody asked for.**
    #
    #     THE FULL COST IS BOOKED IN ADR-0004 (amendment 2026-08-02) AND NOT RESTATED HERE — it is
    #     three things, not one, and a fourth copy of a paragraph is a fourth thing to keep true.
    #     This file has now paid three times for a comment that drifted from the code beside it.
    #
    #     What is NOT weakened, because it was never about intent: `terraform apply`, force-push,
    #     `rm -rf`, secret writes, the trunk push, the merge gate. Those are acts, not judgements,
    #     and they stay mechanical.
  fi
  # ~~`developer` skips the ASK and FALLS THROUGH to rules 7, 7b and 8 — it does not return.
  # Everything else still asks the owner, exactly as before.~~
  #
  # **THERE IS NO ASK HERE ANY MORE (2026-08-03).** `developer` and the main agent both reach this
  # point and both continue; only a non-`developer` subagent leaves this block, and it leaves via
  # `deny` above. The `[ -z "${developer_may:-}" ] && ask …` line that stood here is deleted rather
  # than left guarded-off: after the change nothing could satisfy it, and a branch that can never fire
  # is a claim about behaviour the file does not have.
  #
  # THE INVARIANT THAT MATTERS IS UNCHANGED AND IS THE POINT OF THE WHOLE BLOCK: falling through must
  # remain FALLING THROUGH. No `exit 0`, no `return`, no early ALLOW. An earlier version returned from
  # mid-script and rules 7 (trunk push), 7b (merge) and 8 (composition) simply stopped running, so
  # `gh issue create … && git push origin main` came out with NO decision at all. The suite asserts
  # that for `developer` AND, since this change, for the main agent — six cases, not three.
fi

# 7. Direct push to the trunk. This IS model-agnostic, contrary to the note above:
#    under gitflow-multi-env main is production, and under trunk-single-env the push
#    to main IS the deploy. Both want it blocked; only the reason differs. Deciding
#    it HERE rather than in each repo's `deny` is the point — settings.json matches
#    prefixes, so it cannot see that `git -C <path> push origin main` and
#    `git push` while HEAD is main are the same act, and pattern-listing every form
#    either misses one or (as happened) over-blocks every feature-branch push too.
#
#    ── RE-JUSTIFIED 2026-09-08 (#383, slice S4), AND THE OLD REASON DOES NOT SURVIVE ─────────────
#    The audit's own summary put rule 7 and rule 7b in one row and kept both on the AUTHORSHIP
#    exception (*only `quality-assurance` may do this, and no other layer sees the caller*). **That is
#    false of rule 7, and measurably so: this rule reads no `agent_type` at all.** Piping the same
#    payload in under four different callers returns the same deny four times:
#
#      agent_type=<empty/orchestrator>          git push origin main  -> deny
#      agent_type=…:quality-assurance           git push origin main  -> deny
#      agent_type=…:developer                   git push origin main  -> deny
#      agent_type=some-foreign-thing            git push origin main  -> deny
#
#    **It denies the gatekeeper too.** So push and merge are NOT the same case, and whatever survives
#    here has to survive on the act rather than on who is performing it. `permission-guard.test.sh`
#    pins that property directly now, so a later edit that adds a persona exemption here reddens.
#
#    WHAT IT SURVIVES ON: THE CONSEQUENCE LATCHES, AND THE PREDICATE IS COEXTENSIVE WITH IT.
#    The owner's criterion is «situacoes irreparaveis» — irreparable, not costly. A push to `main` in
#    THIS repository is not merely a deploy: `.github/workflows/version-main.yml` triggers on
#    `push: branches: [main]`, bumps the patch, tags `vX.Y.Z`, pushes the tag and runs
#    `gh release create`. **The push publishes a marketplace Release with no human between the two
#    acts.** A Release is deletable; a Release a consumer has already pulled with `/plugin update` is
#    on their disk and does not un-happen. That is the same standard this audit already applied to
#    rule 5g's `gh release create` and `gh workflow run`, and exempting the push would be applying it
#    unevenly. In the consuming repository the same push is the site deploy, which can latch an OG card
#    a scraper pins on first fetch and a GA4 event name that has begun collecting — both recorded in
#    that repository's own decision library, cited by name there rather than numbered here, because a
#    foreign record number in this tree reads to an agent as a live local citation.
#
#    AND THIS IS THE HALF THAT SEPARATES IT FROM THE MERGE FLOOR. §5 of the audit refused to keep 7b
#    on irreparability because a merge-time classifier cannot identify WHICH merges latch — the OG
#    surface alone is spread across most of a frontend, and "a claim a reader has already read" has no
#    path at all. **Rule 7 has no such gap: the workflow's own trigger is `push to main`, so every act
#    this rule refuses publishes, and every act it permits does not.** The one exclusion is the
#    workflow's `bump:` loop guard, which is its own commit. A lock whose predicate is coextensive
#    with the latching act is the opposite of the shape this audit is dehydrating.
#
#    WHY NOT THE OTHER LAYERS, EACH TRIED RATHER THAN ASSUMED UNAVAILABLE («explorados»):
#      · `settings.json` — both layers deny `git push origin main`, `git push origin main:*` and
#        `git push origin HEAD:main:*`, and both ALLOW `Bash(git push:*)`. Token-bounded prefixes
#        cannot express *bare `git push` while HEAD is main*, `--all`, `--mirror`, `+main`,
#        `HEAD:refs/heads/main`, or `git -C <dir> push origin main` (whose prefix `git -C` is itself
#        allowlisted). So removal here is a REAL removal with silent execution for exactly the forms
#        this rule was written for.
#      · the forge — `enforce_admins` on `main` is `false` (read 2026-09-02, carried in `/devops`), so
#        protection does not apply to the administrator credential every context in this loop acts
#        through. **The forge would accept the push this rule refuses.** Not re-read here: the command
#        is `gh api`, which the global floor denies in-loop. Treat it as dated rather than settled —
#        and note the gap is unwatched rather than unwatchable, since CI is not an in-loop context.
#      · a brief or a skill — an instruction, and the act is one keystroke from a context that has the
#        credential. By this loop's own test that is memory, not a mechanism.
#    KEEP.
#
#    THE TRIGGER'S TRAILING CLASS WIDENED AT #446, and it is a widening rather than a rewrite. It read
#    `push([[:space:]]|$)`, so `push` followed by any shell punctuation did not fire the rule AT ALL —
#    measured on the pinned blob, `(cd <repo-on-main>; git push)` came out ABSTAIN not because the
#    branch limb misread the target but because rule 7 never ran. `push($|[^[:alnum:]_./-])` fires on
#    `push)`, `push;`, `push|` and `push&` while still declining `git push-something`. It can only ever
#    make this rule fire on MORE, never on less, so it adds no path from DENY to ALLOW.
if printf '%s' "$bare" | grep -Eq '(^|[^[:alnum:]_])git([[:space:]]+(-C[[:space:]]+[^[:space:]]+|-c[[:space:]]+[^[:space:]]+|--git-dir=[^[:space:]]+|--work-tree=[^[:space:]]+))*[[:space:]]+push($|[^[:alnum:]_./-])'; then
  # Any refspec landing on the trunk: `main`, `refs/heads/main`, `HEAD:main`, `+main`.
  if printf '%s' "$bare" | grep -Eq '[[:space:]]\+?([^[:space:]:]+:)?(refs/heads/)?(main|master)([[:space:]]|$)'; then
    deny "Blocked: pushing to the trunk. Merging to main is the deploy and the human's go/no-go — it is never an agent action. Push your feature branch and open a PR."
  fi
  # --all / --mirror sweep every ref, trunk included.
  if printf '%s' "$bare" | grep -Eq '[[:space:]](--all|--mirror)([[:space:]]|$)'; then
    deny "Blocked: 'git push --all/--mirror' pushes every ref, the trunk included. Push one named branch instead."
  fi
  # --tags / --follow-tags PUBLISH. Both are in the floor's `deny` and neither was matched here, so
  # `git -C <path> push --tags` — with `Bash(git -C:*)` in `allow` — ran with no decision from any
  # layer, the same bypass shape as the `gh -R` finding. A tag in this workspace is not a label: the
  # deploy's `release` job creates it, and pushing one by hand publishes a Release and desynchronises
  # it from VERSION.
  if printf '%s' "$bare" | grep -Eq '[[:space:]](--tags|--follow-tags)([[:space:]]|$)'; then
    deny "Blocked: pushing tags publishes a Release. The deploy workflow's 'release' job owns tagging — it bumps VERSION, tags and publishes in one pass, and a hand-pushed tag desynchronises the three. Push the branch alone."
  fi
  # ── TARGET RESOLUTION (#446). A bare `git push` inherits HEAD, so this limb has to name the
  #    repository the push will land in. Until #446 it did that by taking the LAST `-C` anywhere in
  #    the string and falling back to `.`, and all three properties of those four lines were wrong:
  #
  #      1. `dir` defaulted to `.` — the HOOK's cwd, not the cwd the command will run in — with no
  #         concept of *unresolvable* at all. On an unnameable target the rule reported whatever the
  #         ambient directory happened to say: **guess-by-default**, neither deny- nor abstain-by-
  #         default, and both directions of error below are that guess.
  #      2. The TRIGGER above enumerates `-C`, `-c`, `--git-dir=` and `--work-tree=`; the extractor
  #         knew `-C` alone. The rule fired on a command whose target it then refused to read.
  #      3. The extractor was greedy and unscoped, so it took the last `-C` in the string whether or
  #         not that `-C` belonged to the push — or to `git` at all. Measured on the pinned blob:
  #         `git -C <main-repo> push ; git -C <feat-repo> status` came out ABSTAIN. **A correct deny
  #         reversed into an abstention by appending a read-only `git status`**, with both elements in
  #         `allow` in both settings layers, so that trunk push reached the floor with no decision
  #         from any layer.
  #
  #    WHY THIS IS NOT A FIFTH FLAG ADDED TO THE LIST. `-C`, then `--git-dir=`, then `--work-tree=`,
  #    then `cd`, then a subshell is a search over spellings, and #438 already paid for that shape
  #    twice (escape, arithmetic, comment, heredoc — four constructs answered one at a time, and a
  #    fifth existed each time until a RECOGNIZER replaced the list). So this limb recognizes the
  #    SIMPLE case positively and calls everything else unresolvable: exactly one `git … push`
  #    invocation, carrying at most one target-naming flag OF ITS OWN, in a command that contains no
  #    construct able to move the working directory out from under it. A sixth shape nobody has
  #    thought of falls into *unresolvable* by construction rather than by omission, which is the
  #    fail-safe direction.
  #
  #    UNRESOLVABLE DENIES, AND THAT CHOICE IS THE WHOLE OF THIS SLICE'S RISK. The alternative — an
  #    explicit abstention — returns the same verdict today's guess returns on those rows, stated
  #    rather than accidental, and leaves the floor silent on a command that may well be a trunk
  #    push. This rule's own re-justification above keeps it on the ground that its predicate is
  #    COEXTENSIVE WITH A LATCHING ACT (`version-main.yml` triggers on push-to-main, bumps, tags and
  #    publishes a Release a consumer can already have pulled). A silent false negative on that
  #    predicate is the mirror of the standing rule about invisible false POSITIVES, and it is worse
  #    in one specific way: a suppressed decision costs a round, a permitted publish costs a
  #    consumer's disk.
  #
  #    AND THE DENY INVERTS THE PATHOLOGY RATHER THAN RESTATING IT. Under the old rule the noisy
  #    half (a wrong deny) had a documented workaround — `git -C <dir> push` — which is precisely the
  #    shape that HID the silent half, so the workaround recruited callers into the blind spot. Under
  #    this rule the same workaround is the shape that resolves CORRECTLY, so the remedy the message
  #    prescribes is the fix rather than the mask. The denied shape (`cd X && git push`) is already
  #    forbidden in prose by the `shell` skill every persona preloads — *`git -C <dir>`, never
  #    `cd X && …`* — so what lands here is a mechanism under an instruction that already existed.
  #
  #    WHAT IT STILL DOES NOT SEE, said here rather than left to be discovered. A `git push` inside a
  #    script invoked by path, or behind a shell alias or function, reaches the act with this hook
  #    seeing only the script's name; no wording of a string-reading rule closes that class. And the
  #    no-flag case still resolves against the HOOK's own cwd, which is the caller's cwd in the
  #    ordinary case and is NOT in a worktree or an additional working directory.
  #
  #    THE PAYLOAD'S OWN `cwd` IS DELIBERATELY NOT ADOPTED, AND THAT IS A DEFERRAL RATHER THAN A
  #    JUDGEMENT. Whether a `PreToolUse` payload carries `cwd` at all is UNMEASURED here: what is
  #    measured is that a `SubagentStart` payload does (`dispatch-metrics-start.sh`'s header, #209),
  #    which is suggestive and is not the same event. Adopting a field whose presence is a hypothesis
  #    would make this limb resolve against an empty string on any build that omits it — silently
  #    widening the very hole this slice closes. What would settle it is one registered probe hook on
  #    `PreToolUse` echoing its stdin, which is its own slice.
  #
  #    THE SEAM WITH #443, RULED HERE AND WRITTEN INTO BOTH BODIES. #443 keys on `git worktree remove`
  #    and needs to resolve a POSITIONAL PATH; this rule resolves WHICH REPOSITORY a `git` invocation
  #    acts on. Those are two different objects, so nothing is extracted into a shared helper — a
  #    helper generalised over one consumer is a guess. What #443 consumes from here is a CORRECTION
  #    and a PATTERN, not code: its body asserts that this rule's old line 1524 was *"complete for
  #    `git`"* and that it *"inherits no defect from that line"*, which is true of the flag SPELLING
  #    (git rejects the attached `-C<path>` form, rc 129) and FALSE of the extraction, which was
  #    greedy, unscoped and blind to two flags its own trigger enumerated. The pattern is: recognize
  #    the simple case positively, give *unresolvable* an explicit state, and decide that state's
  #    verdict deliberately. **The two rules decide it differently and that is intended** — #443's
  #    predicate asks whether a directory holds uncommitted work, so an unreadable answer there is
  #    genuinely unknown; this rule's asks which repository a push lands in, and refusing to answer
  #    would leave a publish unclassified. The one sub-problem NEITHER Issue owns is the payload-`cwd`
  #    question above; it is named as a residual in both rather than half-claimed by either.
  # `grep -o | wc -l`, never `grep -co`: with -o, BSD grep counts MATCHES and GNU grep counts LINES,
  # so on this one-line payload `-co` returns 2 on a maintainer's macOS and 1 in Ubuntu CI. That
  # divergence would have made the two-invocation arm below green locally and dead in the pipeline —
  # the same platform-split class this file's own rule-7 fixture comment already warns about.
  # EVERY `grep` HERE CARRIES `|| true`, AND THAT IS LOAD-BEARING RATHER THAN DEFENSIVE. This file
  # runs under `set -euo pipefail`, so a grep that legitimately matches nothing (a push carrying no
  # target flag — the commonest shape there is) exits 1, fails the pipeline, and kills the whole
  # guard with no output. A hook that dies silently reads to the runtime as NO DECISION, so the
  # first form of this block turned eight of rule 3b's force-push denials into silent allows —
  # measured, 471/8 against a 479/0 baseline. A guard that abstains by crashing is the worst member
  # of the fail-open family, because nothing anywhere says it happened.
  push_matches="$(printf '%s' "$bare" | grep -oE '(^|[^[:alnum:]_])git([[:space:]]+(-C[[:space:]]+[^[:space:]]+|-c[[:space:]]+[^[:space:]]+|--git-dir=[^[:space:]]+|--work-tree=[^[:space:]]+))*[[:space:]]+push($|[^[:alnum:]_./-])' || true)"
  push_hits="$(printf '%s\n' "$push_matches" | grep -c . || true)"
  push_inv="$(printf '%s\n' "$push_matches" | sed -n '1p')"
  # Only these three name a TARGET. `-c` sets a config key and is tolerated inside the invocation
  # without contributing one, which is why the trigger enumerates it and this count does not.
  push_tflag_hits="$(printf '%s' "$push_inv" | grep -oE '(-C[[:space:]]+[^[:space:]]+|--git-dir=[^[:space:]]+|--work-tree=[^[:space:]]+)' || true)"
  push_tflags="$(printf '%s\n' "$push_tflag_hits" | grep -c . || true)"
  target_unresolvable=""
  git_dir_flag=""
  dir=""
  if [ "$push_hits" != "1" ]; then
    target_unresolvable="the command carries more than one 'git … push' invocation, so it has more than one target"
  elif [ "$push_tflags" -gt 1 ] 2>/dev/null; then
    target_unresolvable="the 'git push' invocation carries more than one target-naming flag (-C / --git-dir= / --work-tree=), and this rule will not guess their precedence"
  elif [ "$push_tflags" = "1" ]; then
    dir="$(printf '%s' "$push_inv" | sed -nE 's/.*[[:space:]]-C[[:space:]]+([^[:space:]]+).*/\1/p')"
    [ -z "$dir" ] && dir="$(printf '%s' "$push_inv" | sed -nE 's/.*--work-tree=([^[:space:]]+).*/\1/p')"
    if [ -z "$dir" ]; then
      git_dir_flag="$(printf '%s' "$push_inv" | sed -nE 's/.*--git-dir=([^[:space:]]+).*/\1/p')"
    fi
  else
    # No target flag on the invocation, so the target is the working directory at the moment the
    # push runs. That is knowable only if nothing in the command can move it.
    #
    # ── THIS BRANCH IS AN ENUMERATION AND IT IS NOT BOUNDED. SAYING SO IS THE POINT. ──────────────
    # The first version of this comment claimed the list was "the SHELL's own directory-changing
    # surface, bounded by the language rather than by anyone's imagination", and that ANY miss
    # "lands back on today's behaviour rather than on something worse". **Both halves were false and
    # the gate falsified them at review**, with `env -C <trunk-checkout> git push`:
    #
    #   · FALSE that it is bounded — `env -C` is an EXTERNAL PROGRAM that chdirs before it execs, and
    #     so are `chroot`, `systemd-run --working-directory=`, a shell function and a script file.
    #     Any program may do this. The language does not bound the set; nothing does.
    #   · FALSE that a miss is never worse — and this is the deeper error. The PINNED extractor caught
    #     `env -C` BY ACCIDENT, because it took the last `-C` anywhere in the string whatever command
    #     owned it. Scoping target flags to the push invocation is CORRECT and it is exactly what
    #     removed the accident. So a miss here is not neutral: it can be a REGRESSION against the very
    #     defect this slice fixes. Measured, cwd on a feature checkout, `env -C <main-repo> git push`:
    #     bd8dfa9e -> deny, 75b0c726 -> ABSTAIN. `env` is added below because of that regression.
    #
    # WHAT ADDING `env` CLOSES AND WHAT IT DOES NOT. It closes the regression, `env`'s long spelling
    # (`env --chdir=<dir>`, which the pinned guard never caught either), and the wrapper forms that
    # still contain the token (`nice env -C …`, `setarch … env -C …`) — all four measured. It does
    # NOT close `chroot`, `systemd-run --working-directory=`, a shell alias or function, a script file
    # invoked by path, or the next program nobody has thought of. **Adding one token to an open
    # enumeration and calling it complete would repeat this defect inside its own fix**, so the class
    # is recorded here as open rather than as handled.
    #
    # WHY NOT A POSITIVE RECOGNIZER HERE, since that is what the flag branch above uses. The only one
    # available is "a single simple invocation, no chaining at all", and it would deny
    # `git add -A && git commit -m x && git push` — the commonest multi-step shape in this loop, on a
    # command that moves no directory. That trade is worse than the residual. And note what a shared
    # target/subject resolver would NOT have bought: this is not an incomplete git-flag alternation,
    # it is that *which directory will this command run in* is unanswerable from a command string.
    if printf '%s' "$bare" | grep -Eq '(^|[^[:alnum:]_.-])(cd|pushd|popd|chdir|env)([[:space:]]|$)|\(|GIT_DIR=|GIT_WORK_TREE=|GIT_CEILING_DIRECTORIES='; then
      target_unresolvable="the command can move the working directory before the push runs (a 'cd'/'pushd'/'popd', an 'env' that chdirs, a subshell, or a GIT_DIR/GIT_WORK_TREE environment assignment), so which repository it lands in is not readable from the command string"
    else
      dir="."
    fi
  fi
  if [ -n "$target_unresolvable" ]; then
    deny "Blocked: this rule could not resolve which repository your 'git push' targets, and a push it cannot classify is refused rather than waved through — ${target_unresolvable}. A push to the trunk fires version-main.yml, which bumps, tags and publishes a Release a consumer can already have pulled, so an unreadable target is denied on the same ground the trunk itself is. The remedy is one edit and it is the shape this harness already asks for: name the repository on the push invocation itself, as 'git -C <dir> push …', in its own Bash call rather than chained behind a 'cd' or another command. That form is read exactly and a feature branch passes."
  fi
  # symbolic-ref, not rev-parse: it reports the checked-out branch even when HEAD is
  # unborn (a fresh repo with no commits), where rev-parse fails and would silently
  # skip this check. On a detached HEAD it fails too, which is correct — there is no
  # branch to land on.
  if [ -n "$git_dir_flag" ]; then
    branch="$(git --git-dir="$git_dir_flag" symbolic-ref --short HEAD 2>/dev/null || true)"
  else
    branch="$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null || true)"
  fi
  case "$branch" in
    main|master)
      deny "Blocked: HEAD is '$branch', so this push lands on the trunk. Merging to main is the deploy and the human's go/no-go. Branch first, then push the branch." ;;
  esac
fi

# 3b. Force-push — ~~DOWNGRADED TO `ask` (#383 S3)~~ **BACK TO `deny` (#383 S3-revert)**. The
#     reparability argument, the measurement that reverted it, the token-boundary finding and the
#     reason this rule cannot live in `settings.json` are all at rule 3's site above, where a reader
#     meets the 3a/3b split; only the executable block lives here.
#
#     **IT STILL SITS AFTER RULE 7 DELIBERATELY, AND WHAT THAT BUYS IS NOW SMALLER AND STATED AS
#     SUCH.** Both rules exit, so whichever matches first is the whole verdict — but both now DENY, so
#     the order decides the REASON rather than the outcome. A force-push to the trunk is rule 7's act
#     first: its message prescribes the right remedy (branch and open a PR), 3b's does not. The
#     ordering is kept, the verdict-only arms can no longer see it, and `check_reason` arms are what
#     pin it now. Moving this block back above rule 7 no longer opens a hole; it silently swaps the
#     advice the caller gets, which is why it is still asserted rather than left to habit.
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]].*push([[:space:]].*)?([[:space:]](--force|--force-with-lease|-f)([[:space:]]|$))'; then
  deny "Blocked: force-push rewrites a ref that others may already have pulled. It was briefly an 'ask' (#383 S3) on the argument that it is REPARABLE — the pre-push tip survives in your reflog and in the remote's unreachable objects — and that argument is still true. What failed is the remedy: a hook 'ask' is answered automatically in this harness's auto mode, measured in the owner's own session, so the downgrade produced silent execution rather than a prompt. Until an auto mode exists that excludes hook 'ask', a reparable-but-serious act has no rung between deny and nothing. Use a safe alternative: push a new branch, or rebase-then-push without --force. If the force-push is genuinely right, it is the human's own act."
fi

# 7b. Merging a PR is the deploy — ADR-0004 makes it the quality-assurance's act alone,
#     and this is where that stops being a promise the main agent must remember. The
#     harness stamps agent_type on a subagent's tool calls (`<plugin>:quality-assurance`)
#     and leaves it empty for the main agent, so `gh pr merge` is allowed ONLY from the
#     reviewer; the main agent and every other subagent are denied. It turns "did the
#     reviewer run?" into a precondition the model cannot satisfy by recall — only by
#     actually routing the merge through the reviewer, which is the design. Matches
#     `gh pr merge` with an optional -R/--repo before `pr` — the SHARED `gh_repo_flag`
#     since 2026-08-04. It carried its own space-only copy until then, so
#     `gh -Ro/r pr merge 1` and `gh --repo=o/r pr merge 1` came out ALLOW from ANY caller
#     while the spaced form was denied. **The merge gate depended on punctuation**, which
#     also falsified the claim — added in the same diff — that this rule makes "only the
#     reviewer merges" mechanically true. It does now; it did not then. The comment above
#     citing "the rule-5b convention" as a precedent for closing spelling gaps was itself
#     false at the time: 5b had the same defect, in the same shape, and was fixed with it.
#     ~~Recorded residual (ADR-0004): a raw `gh api ... PUT .../merges` is NOT matched —
#     the natural command is gated; the API back door is an accepted, named gap~~ —
#     **closed 2026-08-04 by RULE 5f, in this file.** THIS matcher is unchanged and still
#     does not see `gh api`; 5f denies it separately, by detecting that the call WRITES
#     (`--method PUT`, `-X`, `-f`/`-F`, `--input`) rather than by parsing the endpoint.
#     The suite covers the merge spelling specifically. It briefly lived in the floor's
#     `deny` instead — see rule 5c's comment for why that was too broad and moved here.
#
#     ── RE-JUSTIFIED 2026-09-08 (#383, slice S4), AND THE SENTENCE ABOVE IS THE WRONG REASON ───────
#     This block opens with *"Merging a PR is the deploy"*, and under the owner's narrowed criterion —
#     «situacoes irreparaveis» — **that does not carry it.** Under `trunk-single-env` a bad deploy is
#     repairable: revert, redeploy. What a deploy can LATCH (an OG card pinned on first fetch, a GA4
#     event name that has begun collecting, a claim a reader has already read, a Release a consumer
#     already pulled) is real, and **a `PreToolUse` classifier cannot tell those merges from the rest**
#     — the audit measured that the OG surface alone spans most of a frontend and that a read claim has
#     no path at all. A lock that cannot distinguish the case it exists for is precisely the shape this
#     audit dehydrated elsewhere, and the merge floor gets no exemption from a test applied to
#     `gh api`, to the milestone pair and to 7d.
#
#     IT SURVIVES AS A **DERIVED** CONTROL — the same reading the audit already applied to rule 1 and
#     to `preflight`, and flagged as an interpretation rather than smuggled in. Two grounds, both
#     measured, and the first alone is sufficient:
#
#     1. RULE 7c IS LEXICALLY INSIDE THIS RULE'S `*:quality-assurance)` ARM. Removing 7b's caller check
#        removes the file's ONE fail-closed rule — the one the owner ruled on directly (#341,
#        «deveria travar») and the one whose degradation lands on the irreversible act itself. 7b is
#        not a second opinion about the merge; it is the scope 7c lives in. Whatever one thinks of
#        authorship, deleting this deletes that.
#
#     2. THE VERDICT 7c READS CANNOT BE ATTRIBUTED, SO `agent_type` IS THE ONLY THING SEPARATING THE
#        AUTHOR OF A VERDICT FROM THE EXECUTOR OF THE MERGE. Measured: rule 5e ALLOWLISTS the empty
#        `agent_type` for `gh pr comment`, so the orchestrator may post one; and every comment on a PR
#        in this workspace comes back `authorAssociation: OWNER`, whatever persona typed it — on PR
#        #422 the `harness-lead-verdict` and the `gatekeeper-verdict` are both `author: tedeuxx`,
#        `assoc: OWNER`, which is exactly the filter 7c's `jq` selects on. **So a context that can
#        post can satisfy 7c with a verdict it wrote itself.** 7b is what stops the same context doing
#        both. That is the ruling's own named exception in evidence rather than in assertion: the
#        control needs the CALLER and the COMMAND together, `settings.json` sees only the command
#        (`Bash(gh pr merge:*)` is ALLOWLISTED in both layers, so removal here is real and silent) and
#        the `tools:` grant sees only the caller.
#
#     WHAT WAS TRIED AND DOES NOT CARRY IT: a brief (this rule exists because the prose version was
#     read and executed by the same model it constrains — three verdict literals drifted in one day);
#     the forge's review rules (a required approving review is a forge identity, and every context here
#     shares one credential); a verdict artifact alone (ground 2 — it is forgeable from inside).
#     KEEP, on the derived ground, NOT on «merging is the deploy». The opening sentence stays because
#     it is the historical reason and this file strikes rather than rewrites; read it as superseded.
if printf '%s' "$bare" | grep -Eq "(^|[^[:alnum:]_])gh${gh_repo_flag}[[:space:]]+pr[[:space:]]+merge([[:space:]]|\$)"; then
  # SQUASH IS DENIED TO EVERYONE, THE REVIEWER INCLUDED, and it is checked BEFORE the persona case so
  # the exemption cannot carry it. The floor denies `gh pr merge --squash`; `Bash(gh -R:*)` walked
  # around that entry like every other, and the reviewer — the one caller 7b lets through — is exactly
  # who would run it. The standing rule is a real merge commit, never a squash: per-commit history is
  # the record of how a change was reached, and squashing discards it irreversibly on the trunk.
  if printf '%s' "$bare" | grep -Eq '[[:space:]](--squash|-s[[:space:]=]*squash)([[:space:]]|$)'; then
    # THE REFERENCE IS IN THE REMEDY, AND ITS POSITION IS LOAD-BEARING (#441). This string used to read
    # `gh pr merge --merge`. A caller who followed it and appended the PR they were merging produced
    # `gh pr merge --merge 479` — flag first — which rule 7c below could not read, so the merge floor
    # abstained and the act executed silently. The remedy a floor prints must be a spelling the floor
    # can read; 7c denies the flag-first order now, so an unqualified `--merge` here would hand the
    # caller a second deny in a row.
    deny "Blocked: never squash-merge. Use a real merge commit ('gh pr merge <number> --merge', reference first) — per-commit history is the record of how the change was reached, and a squash discards it irreversibly once it is on the trunk."
  fi
  case "$agent_type" in
    *:quality-assurance)
      # 7c. THE CALLER IS ALREADY PROVEN — this check is about WHETHER ITS OWN VERDICT SAYS SO,
      # on the PR's CURRENT head. ADR-0004's "The merge precondition is a floor, not an instruction"
      # section proposed exactly this: the strongest rule in this loop (a merge requires a clean gate
      # verdict posted as an artifact) was, before this rule, enforced only by prose in
      # `agents/quality-assurance.md` — read and executed by the same model it constrains. Three
      # vocabulary drifts shipped in that rule in one day (`ADVISORY-ONLY`, `CLEAN`, `APPROVED`, none
      # a literal the reviewing gate defines) and none could have been caught by a check. This turns
      # "did I actually post APPROVE-AND-MERGE for the code that is here now?" into a precondition the
      # model cannot satisfy by recall — only by the artifact on the PR actually saying so.
      #
      # NAMED LIMIT, STATED HERE SO THE CONTROL IS NOT OVERCLAIMED (ADR-0004's "Which layer carries a
      # control" section — 0008 in this table until it was absorbed there on 2026-08-20): this narrows what rule
      # 7b already restricted (only `*:quality-assurance` may call `gh pr merge` at all) — it adds
      # nothing against a DIFFERENT caller, because 7b already denies every other one. And it has
      # ZERO reach over a human merging via the GitHub UI or a personal terminal outside this session
      # — the dominant real-world merge path on this platform (measured: PR #293's `mergedBy` was the
      # owner's own account, not a session tool call, while REQUEST-CHANGES sat on its current head).
      # That gap is not this layer's to close; no hook can see a browser click.
      #
      # THE JQ LITERAL-EXTRACTION BELOW IS DUPLICATED FROM session-wip.sh's verdict_suffix(), ON
      # PURPOSE — a hook cannot source code out of another hook (wip-guard.sh's own `gh_repo_flag`
      # precedent, that file's line ~142). `inventory-counts.test.sh` asserts the two copies stay
      # byte-identical, the same way it already does for `gh_repo_flag`, so a marker-format change in
      # one cannot silently leave the other reading a shape that no longer exists.
      #
      # ── FAILS CLOSED SINCE 2026-08-28 (#341), AND IT IS THE ONLY RULE IN THIS FILE THAT DOES ──────
      # ~~FAILS OPEN, matching this file's own stated policy at its header ("Fails OPEN … on any parse
      # error, a missing jq, or no network"): no `gh`/`jq` on PATH, or an empty/unreadable response,
      # degrades to 7b's identity check alone — this sub-rule adds nothing, denies nothing, and the
      # merge proceeds exactly as it did before this rule existed. An unavailable answer is not a
      # finding, the same distinction session-wip.sh's own comment makes for the same read.~~
      #
      # **STRUCK on the owner's decision (#341): «deveria travar» — no readable verdict, no merge.**
      # The argument is not that the fail-open reasoning above was wrong in general; it is that this
      # arm is the one place where the fail-open lands on the IRREVERSIBLE act. Every other control in
      # this file degrades into something a later step can still catch; this one degraded into a merge,
      # and it did so EMITTING NOTHING — so a merge with no gate was indistinguishable, in the
      # transcript and in the PR, from a merge with a clean one. The unblock is manual and the owner's.
      #
      # THE READ COLLAPSED TWO DIFFERENT FACTS INTO ONE EMPTY STRING, which is what made the fix a
      # one-case split rather than an architecture change: *the read succeeded and found no verdict*
      # (already denied, the `none` arm) and *the read never happened*. The second now has its own
      # sentinel, `qa_unavailable`, set before the `case` is ever reached, and every branch of it —
      # absent `gh`, absent `jq`, a failed API call, expired auth, a rate limit, a PR reference that
      # resolves to nothing — denies with a message naming WHICH precondition was missing. A deny that
      # is silent about why trades one invisible failure for another.
      #
      # WHAT THIS DOES **NOT** CHANGE, STATED SO THE SCOPE IS NOT READ WIDER THAN THE DECISION.
      #   · The owner was asked about the MERGE FLOOR and answered about the merge floor. The rest of
      #     this file, and every other hook in `hooks/scripts/` that asks the world a question, is
      #     unchanged and still fails open. That generalisation is its own Issue (#342) with its own
      #     decision, and it is deliberately not taken here.
      #   · The file header's fail-open contract still governs everything else; it now names this arm
      #     as its one exception rather than being quietly contradicted by it.
      #
      # THE `jq` BRANCH BELOW IS UNREACHABLE TODAY, AND IT IS WRITTEN ANYWAY — NAMED, NOT HIDDEN.
      # A missing `jq` never gets this far: line ~114 parses `.tool_input.command` with `jq` and
      # `exit 0`s on an empty result, so one absent `jq` disables the ENTIRE floor, not one arm of it.
      # That is a different failure with a different blast radius, it was explicitly excluded from
      # #341's decision, and it is not fixed here. Measured at this file's head: with `jq` off `PATH`
      # this hook emits nothing at all and the merge proceeds. `deny()` itself is built on `jq -n`, so
      # even the deny below could not be printed without it — closing this branch means changing how
      # every rule in this file refuses, which is exactly the blast radius the owner did not decide.
      # The branch stays because it is two lines and it is correct the moment line ~114 is fixed.
      # THE REPO FLAG IS READ POSITION-AGNOSTICALLY, and that is a FIX, not a widening (2026-08-23).
      #
      # The extraction here used to be anchored `^gh <flag> <value> pr merge` — the flag BEFORE the
      # subcommand and nowhere else. Measured, by piping both spellings into this hook with an
      # arg-logging `gh` stub:
      #
      #   gh --repo owner/repo pr merge 479   ->  qa_repo=owner/repo     -> reads the right PR
      #   gh pr merge 479 --repo owner/repo   ->  qa_repo=<empty>        -> falls back to the cwd repo
      #
      # and with a REQUEST-CHANGES verdict sitting on the named PR, the second spelling came out
      # **ALLOW** — the fail-open below, reached by a command `gh` accepts and this platform's own
      # `shell` skill MANDATES ("Target another repo with `gh <subcommand> --repo
      # <owner/repo>`, never `gh -R <owner/repo> <subcommand>`", that file's own wording). A control
      # defeated by following the instructions is not a parsing bug with a security consequence; it is
      # a control that was off for the everyday spelling, which is why the fail-open argument below
      # does not cover it and never did.
      #
      # THE CLASS IS `gh_repo_flag`'s, VERBATIM, and the extraction shape is `wip-guard.sh`'s — the
      # `.*[[:space:]]` prefix rather than a `^gh` anchor. That convergence is the whole point: this
      # file carried THREE spellings of the same flag (the shared class at the `gh_repo_flag`
      # definition, a drifted one at rule 5c, and this one), each parsed differently, and the two
      # drifted copies were both a fail-open. `inventory-counts.test.sh` now asserts every copy in
      # this file is identical, in the same shape it already asserted across the two hooks — so a
      # fourth spelling cannot be introduced in silence.
      #
      # NOT COVERED, DELIBERATELY: an unquoted `--repo` appearing inside a flag VALUE (`--body` and
      # friends are collapsed by `$bare` before this line, so it takes a contrived command to reach),
      # and `--repository`, which no `gh` subcommand accepts. Both degrade to an unresolvable slug,
      # which lands on the fail-open — i.e. on the behaviour that was already there.
      #
      # THE REPO FLAG IS STRIPPED BEFORE THE REF IS READ. Now that the flag may legally follow the
      # subcommand, `gh pr merge --repo owner/repo 479` would otherwise hand `--repo` to the ref
      # extractor, which drops it and silently reads the CURRENT BRANCH's PR instead of 479. Removing
      # the flag/value pair first cannot make any other spelling worse.
      # ~~NAMED RESIDUAL, not fixed here: any OTHER value-taking flag placed before the positional ref
      # (`gh pr merge -t "subject" 479`) still misdirects the ref the same way. Its blast radius is
      # much smaller than the repo case — it falls back to the current branch's PR, which under WIP=1
      # is almost always the PR being merged — and a general fix is a token-level argv parser, not a
      # regex. It is a finding for the owner, not a silent gap.~~
      #
      # STRUCK AND FIXED 2026-09-10 (#441), struck rather than rewritten because a reader took the
      # blast-radius pricing from it and BOTH HALVES OF THAT PRICING WERE WRONG:
      #
      #   1. THE CLASS IS NOT "value-taking flag". It is ANY first token beginning with `-`. The
      #      mechanism was the `case ... in -*|'') qa_ref="" ;;` line alone: `--repo` was stripped BY
      #      NAME one line above, every other flag survived, became the first token, matched `-*`, and
      #      set the reference to the empty string. `--merge`, `--auto`, `--admin` and
      #      `--delete-branch` take no value at all and each reproduced it on its own.
      #   2. "ALMOST ALWAYS THE PR BEING MERGED" priced the fallback against WIP=1, which is a property
      #      of how the loop happens to be run, not of this rule. #385 is open to end WIP=1.
      #
      # THE SHARPEST INSTANCE WAS THE FLOOR'S OWN REMEDY STRING. The squash deny above printed "Use a
      # real merge commit ('gh pr merge --merge')". A caller who followed that instruction and appended
      # the PR they were merging typed `gh pr merge --merge 479` — flag first — and the reference was
      # erased in silence. `Bash(gh pr merge:*)` is allowlisted in BOTH settings layers, so this hook
      # abstaining is SILENT EXECUTION and not a prompt. That message now carries the reference in the
      # position this rule can read.
      #
      # THE DIRECTION IS B — DENY WHAT CANNOT BE PARSED — and A was rejected on a measurement rather
      # than on taste. A is "parse the argv", which requires knowing which flags take a value.
      # `gh help pr merge` IS readable from here (`gh pr merge --help` is not: rule 7b's prefix catches
      # it, and that spelling difference is the whole reason the enumeration was thought unavailable),
      # so the list exists: value-taking are -A/--author-email, -b/--body, -F/--body-file,
      # --match-head-commit and -t/--subject; the rest are boolean. A WOULD HAVE WORKED TODAY. It was
      # rejected because the list is read off one installed `gh`, a release adding a value-taking flag
      # re-opens the hole in silence with a green suite, and — the deciding measurement — the
      # enumeration buys correct handling only for spellings this loop never types. The one prescribed
      # form is `gh pr merge --merge` (`agents/quality-assurance.md`, its "merge the safe class"
      # clause); no brief, skill or record in this tree puts -t, -b, -F, -A or --match-head-commit on a
      # merge. An enumeration claiming to be a rule, bought for zero real invocations, is the shape
      # this repository has already paid for twice.
      #
      # SO THE DISCRIMINATOR IS NOT "IS `qa_ref` EMPTY" — that would wedge everyday work. `gh pr merge`
      # and `gh pr merge --merge` carry NO reference on purpose: they merge the current branch's PR,
      # the fallback is the correct read, and both stay ALLOW. The question asked here is the narrower
      # one: WAS THERE A REFERENCE WE FAILED TO READ? A flag leads and a bare token follows it, so `gh`
      # will bind the reference to some token and this hook cannot prove which. It denies.
      #
      # WHAT IT COSTS, PRICED RATHER THAN ABSORBED: a legal no-reference invocation carrying a
      # value-taking flag (`gh pr merge -t "subject"`, `gh pr merge --body-file /tmp/x`) now denies,
      # because the flag's VALUE is a bare token and nothing here can tell a value from a reference
      # without the enumeration just rejected. The error runs toward DENIAL, which the caller reads,
      # and the remedy is in the message and always works: put the reference first.
      #
      # WHAT STAYS OPEN, so the repair is not read as closing the class. A SCRIPT FILE — `sh
      # ./merge-it.sh` — reaches the merge untouched, because neither settings matcher nor any rule in
      # this file looks inside one; the same blindness `agents-configuration` records for
      # `scripts/milestone-create.sh`, reached from the other side. A BROWSER MERGE is unreachable from
      # any hook, as 7c's own comment already states. Measured for #441 and already closed, so nobody
      # re-walks them: an absolute path, `command gh`, `xargs -I{}` and `gh api -X PUT .../merge`
      # (rule 5f) all deny at head.
      qa_rest="$(printf '%s' "$bare" | sed -E -e 's/[[:space:]](-R[[:space:]=]*|--repo[[:space:]=]*)[^[:space:]]+/ /g' -e 's/^.*[[:space:]]pr[[:space:]]+merge[[:space:]]*//')"
      qa_ref="${qa_rest%% *}"
      case "$qa_ref" in
        -*)
          qa_ref=""
          # A flag leads. If ANY bare token follows it, a reference is present and unattributable.
          # `|| true` is load-bearing: `grep -v` matching nothing exits 1, and under this file's
          # `set -euo pipefail` that would kill the whole guard — the crash class that turned eight
          # force-push denials into silent allows once already.
          qa_stray="$(printf '%s' "$qa_rest" | tr -s '[:space:]' '\n' | grep -vE '^-|^$' | head -n 1 || true)"
          if [ -n "$qa_stray" ]; then
            deny "Blocked: this merge command puts a flag before the pull-request reference, so this hook cannot prove WHICH pull request 'gh' will merge — and the merge floor may not clear a merge whose subject it could not read (#341: no readable verdict, no merge). 'gh pr merge' takes the reference as a positional argument and some of its flags take a value, so '${qa_stray}' here could be either one. Put the reference FIRST and every flag after it: 'gh pr merge <number> --merge'. A merge with NO reference at all ('gh pr merge --merge') is untouched — that one deliberately merges the current branch's PR, and this hook reads that PR's verdict."
          fi
          ;;
        '') qa_ref="" ;;
      esac
      qa_repo="$(printf '%s' "$bare" | sed -nE 's/.*[[:space:]](-R[[:space:]=]*|--repo[[:space:]=]*)([^[:space:]]+).*/\2/p')"
      qa_pr_json=""
      qa_err=""
      # WHERE THE READ RESOLVED, NAMED (#413). The deny used to interpolate `${qa_repo:+ --repo …}`,
      # so on the IMPLICIT spelling — no `--repo`, which is the everyday one — the repository was
      # omitted from the message ENTIRELY. The operator read `'gh pr view 610' returned nothing` and
      # could not learn the single most diagnostic fact: which repository was looked in. Measured on
      # `-io#610`: the same reference merged cleanly with an explicit `--repo`, and nothing in the
      # deny pointed at the difference.
      #
      # THIS RESOLVES THE REPOSITORY FOR THE MESSAGE ONLY. It does NOT feed `gh`, and it must not:
      # the whole reason #413 is a message fix is that having this hook GUESS a repository would read
      # a verdict from a PR the merge command is not going to merge — a confidently wrong ALLOW, the
      # shape this file's own comments already record shipping once. The decision logic below is
      # byte-for-byte what it was; only the words change.
      #
      # `git remote get-url` is LOCAL — no network call, and rule 7 already reads local git through
      # `git -C … symbolic-ref`, so this is in-pattern rather than a new dependency. It runs in the
      # hook's own cwd, which is the same cwd `gh` would resolve against, so it answers the question
      # actually asked. If it fails (not a repo, no `origin`, no `git`), the message degrades to the
      # FLOOR the Issue named: it still says an absent `--repo` resolves against the cwd repository.
      qa_repo_shown=""
      if [ -z "$qa_repo" ]; then
        qa_origin="$(git remote get-url origin 2>/dev/null || true)"
        qa_origin="${qa_origin%.git}"
        qa_origin="${qa_origin%/}"
        case "$qa_origin" in
          */*) qa_repo_shown="$(printf '%s' "$qa_origin" | sed -E 's#^.*[:/]([^/:]+/[^/:]+)$#\1#')" ;;
        esac
        case "$qa_repo_shown" in */*) : ;; *) qa_repo_shown="" ;; esac
      fi
      if [ -n "$qa_repo" ]; then
        qa_where="'$qa_repo', named by this command's own --repo flag"
      elif [ -n "$qa_repo_shown" ]; then
        qa_where="'$qa_repo_shown' — this command carries NO --repo, so 'gh' resolved the reference against the cwd repository, and that is its 'origin'"
      else
        qa_where="the cwd repository — this command carries NO --repo, so 'gh' resolved the reference against the cwd repository, whose 'origin' could not be read from here"
      fi
      # `qa_unavailable` IS THE SENTINEL THE OLD `''` ARM DID NOT HAVE. Non-empty means "the read did
      # not happen", and it carries the reason in the words the deny message needs — one string per
      # cause, so the message attributes rather than shrugging.
      qa_unavailable=""
      if ! command -v gh >/dev/null 2>&1; then
        qa_unavailable="the 'gh' CLI is not on PATH, so the verdict comment on the PR cannot be read at all"
      elif ! command -v jq >/dev/null 2>&1; then
        qa_unavailable="'jq' is not on PATH, so the verdict comment cannot be parsed"
      else
        # THE DISCRIMINATOR WAS BEING THROWN AWAY (#413). The read below used to end `2>/dev/null`,
        # which discards the ONE string that separates "this reference names no pull request" from
        # "the network is down" — 'gh' emits `Could not resolve to a PullRequest` on stderr and this
        # hook deleted it, then wrote a deny listing four causes in the order that puts the actual
        # one LAST. Capturing it costs no extra call.
        #
        # CAPTURED TO A FILE RATHER THAN MERGED WITH `2>&1`, and that is not fastidiousness: 'gh'
        # writes update notices and other chatter to stderr on a SUCCESSFUL read too, so merging the
        # streams would hand `jq` an unparseable payload and turn a READABLE verdict into a deny. On
        # this rule that trades a cosmetic defect for a wedge on the irreversible act.
        # THE `--json` LIST LOST `closingIssuesReferences` ON 2026-09-08 (#383, S4), WITH RULE 7d.
        # It was requested for 7d alone and 7d is gone, so leaving it in would be a fetch nothing reads
        # -- which the next reader would reasonably take as evidence that a check lives here. It is one
        # token to add back: the field, and `files` alongside it, ride on THIS call at zero additional
        # round-trips, which is the property 7d was built on and is recorded at 7d's tombstone below.
        qa_errfile="$(mktemp 2>/dev/null || printf '%s' "${TMPDIR:-/tmp}/permission-guard-7c-$$.err")"
        if [ -n "$qa_repo" ]; then
          qa_pr_json="$(gh pr view ${qa_ref:+"$qa_ref"} --repo "$qa_repo" --json headRefOid,comments 2>"$qa_errfile" || true)"
        else
          qa_pr_json="$(gh pr view ${qa_ref:+"$qa_ref"} --json headRefOid,comments 2>"$qa_errfile" || true)"
        fi
        qa_err="$(head -n 1 "$qa_errfile" 2>/dev/null || true)"
        rm -f "$qa_errfile"
        if [ -z "$qa_pr_json" ]; then
          # THE CAUSES ARE ORDERED BY WHAT ACTUALLY HAPPENS, not by what is easiest to list. The
          # reference cause leads in every arm, and where 'gh' named it the message ATTRIBUTES
          # instead of enumerating.
          case "$qa_err" in
            *'Could not resolve to a PullRequest'*|*'no pull requests found'*|*'Could not resolve to a Repository'*)
              qa_unavailable="the PR reference in this command names NO pull request in the repository the read resolved against, which is ${qa_where} — 'gh' said so itself: \"${qa_err}\". This is a wrong-reference or wrong-repository error, NOT a network or auth one"
              ;;
            '')
              qa_unavailable="'gh pr view ${qa_ref:-<the current branch>}${qa_repo:+ --repo $qa_repo}' returned nothing, against ${qa_where}. 'gh' printed nothing on stderr to say why, so the causes cannot be told apart from here — in the order they actually occur: the PR reference names no pull request in that repository, or auth is missing or expired, or a rate limit was hit, or there is no network"
              ;;
            *)
              qa_unavailable="'gh pr view ${qa_ref:-<the current branch>}${qa_repo:+ --repo $qa_repo}' returned nothing, against ${qa_where} — 'gh' said: \"${qa_err}\". Read that line first: it, and not this hook, knows whether the reference, the auth or the network is at fault"
              ;;
          esac
        fi
      fi
      if [ -n "$qa_unavailable" ]; then
        deny "Blocked: the merge floor could not READ your gate verdict, and since #341 that denies instead of passing — ${qa_unavailable}. This is NOT a finding about the PR: the floor is not saying your verdict is wrong, it is saying it could not confirm one exists on the current head, and the owner's rule for that case is 'no readable verdict, no merge'. Fix the precondition named above and run this again — check FIRST that the PR reference in this command names a real pull request in the repository named above, and that you passed '--repo <owner/repo>' if the PR does not live in the cwd repository; only then 'gh auth status' and the network. If it cannot be fixed from here, the unblock is manual and the owner's: hand him the PR and say which precondition was missing."
      fi
      if [ -n "$qa_pr_json" ]; then
        # ── BEGIN duplicated from session-wip.sh's verdict_suffix() — keep byte-identical ──
        qa_verdict="$(printf '%s' "$qa_pr_json" | jq -r --arg m '<!-- gatekeeper-verdict: quality-assurance -->' '
    def literal($lines; $m):
      ($lines | index($m)) as $i
      | if $i == null then "" else ($lines[$i + 1] // "" | gsub("^\\s+|\\s+$"; "")) end;
    (.headRefOid // "") as $h
    | if $h == "" then ""
      else [ .comments[]?
             | select((.authorAssociation // "") as $a
                      | ["OWNER","MEMBER","COLLABORATOR"] | index($a))
             | .body // ""
             | select(contains($m)) | select(contains($h))
             | literal(split("\n"); $m) ]
           | if length == 0 then "none" else .[-1] end
      end' 2>/dev/null || true)"
        # ── END duplicated from session-wip.sh's verdict_suffix() ──
        # TWO merge-authorising literals since 2026-08-22, not one (ADR-0002 amendment #16, ADR-0004's
        # "Rule 7c accepts two merge-authorising literals" section). The owner retired the
        # hold-for-owner rule on boundary-class merges — with a single environment there is no preview
        # to hold for, so holding the merge delayed publication without producing anything to inspect.
        # `APPROVE-AND-MERGE-BOUNDARY` is the boundary class's own clearance: the gate merges it and
        # the owner reviews live, after deploy.
        #
        # THE LITERALS ARE SPELLED OUT, NEVER GLOBBED. `APPROVE-AND-MERGE*` would match both — and
        # would also match `APPROVE-AND-MERGED`, `APPROVE-AND-MERGE-LATER` and every future drift,
        # which is the exact class of failure this rule was built to catch (ADR-0004 measured three
        # drifted literals shipping in one day). A closed set the author wrote stays closed.
        #
        # `APPROVE-PENDING-HUMAN` STILL BLOCKS, and it still means something: it is now the verdict
        # for the four holds that survive the retirement — an expansion of the gate's own authority,
        # a harness diff with no agents-lead marker, anything in `iac/` (where the merge APPLIES and
        # the PR's own plan is the preview the single-environment argument says does not exist), and
        # an explicit lens ESCALATE. See `agents/quality-assurance.md`'s "Classify — who may merge"
        # section for the list this hook is the floor under.
        # THE EMPTY CASE LEFT THIS ARM AT #341 AND NOW DENIES ON ITS OWN.
        # ~~`APPROVE-AND-MERGE|APPROVE-AND-MERGE-BOUNDARY|'') : ;;  # … OR the read produced nothing — fail open~~
        # `''` is NOT "no verdict" — that is `none`, and it has denied since 7c existed. `''` is what
        # the extraction above returns when the response carried no `headRefOid`, or when `jq` itself
        # failed on it: a THIRD flavour of "could not read", reached after `gh` answered, so
        # `qa_unavailable` above never sees it. It gets its own arm and its own message, because a
        # response with no head is a different repair from an absent `gh`.
        case "$qa_verdict" in
          APPROVE-AND-MERGE|APPROVE-AND-MERGE-BOUNDARY) : ;;  # clear to merge — the two authorising literals, spelled out, never globbed
          # THE FIFTH LITERAL (#374) GETS ITS OWN ARM, AND IT DENIES. `APPROVE-EXECUTOR-BLOCKED` means
          # the gate cleared the diff and could NOT execute the merge, so the act became the owner's by
          # exception. A verdict whose content is "I could not merge this" must not be a verdict that
          # merges it. Without this arm it falls to `*)` and denies anyway — correctly, with a message
          # about a moved head or a drifted literal, which is the wrong repair for the only case where
          # the literal is exactly right and the caller is exactly wrong.
          #
          # It is spelled disjoint from the merge-authorising pair ON PURPOSE. `APPROVE-AND-MERGE-…`
          # would have read as a member of the family that authorises a merge, and this one is its
          # opposite; the naming is the first line of defence in every reader that has not been written
          # yet. The pair above is still spelled out and still never globbed.
          APPROVE-EXECUTOR-BLOCKED)
            deny "Blocked: the verdict at this PR's current head is APPROVE-EXECUTOR-BLOCKED, which is the one literal that says the gate cleared this diff and COULD NOT execute the merge — so the remaining act was handed to the owner by exception (#374). This denial is not a finding about your review and not a hold: rule 7b already confirms you are quality-assurance, and the four holds are unaffected. It means a merge is being attempted under a verdict that records the opposite. If you are NOW able to merge, post a fresh APPROVE-AND-MERGE or APPROVE-AND-MERGE-BOUNDARY against this same head and run this again — the head-scoped verdict is the record, and re-posting is how it moves. If you are still blocked, do not retry: hand the owner the PR and say which layer refused you." ;;
          '') deny "Blocked: the merge floor read a response for this PR but could not determine its CURRENT head, so it cannot tell whether any verdict applies to the code that is there now — and since #341 an unreadable verdict denies rather than passing. Either 'gh pr view' returned a payload with no headRefOid (a partial or error response), or parsing it failed. Re-run 'gh pr view <ref> --json headRefOid,comments' by hand and see what comes back; if the PR is real and reachable, this is a finding about the tooling, not about your review. The unblock is manual and the owner's." ;;
          *) deny "Blocked: the last quality-assurance verdict on this PR's CURRENT head is '${qa_verdict}', which is neither APPROVE-AND-MERGE (safe class) nor APPROVE-AND-MERGE-BOUNDARY (boundary class, merged by the gate since ADR-0002 amendment #16) — so this merge does not match its own review record (ADR-0004). This is not a caller problem: rule 7b already confirms you are quality-assurance. It means either the head moved since that verdict was posted, the verdict was never re-posted after a later round, or the literal drifted from the one 'Your verdict — exactly one of' in your own brief defines. Post a correct verdict against the CURRENT head before merging — or, if this is one of the four holds that survive (an expansion of your own authority, a harness diff with no agents-lead marker, anything in iac/, or a lens ESCALATE), never call this tool: APPROVE-PENDING-HUMAN and hand the go/no-go to the human." ;;
        esac

        # -- 7d. REMOVED 2026-09-08 (#383, slice S4). THE NUMBER IS LEFT VACANT, like 9, 10 and 11. --
        #
        # WHAT IT DID, so the removal is legible without archaeology: after 7c had cleared the verdict,
        # it compared the forge's own resolved `closingIssuesReferences` against the `^closes:` lines of
        # that same head-scoped verdict, and denied the merge when the forge was about to close an Issue
        # the gate never declared. It never judged delivery; it compared two artifacts. It was correct,
        # it was cheap (zero additional round-trips -- the field rode on 7c's existing `gh pr view`), and
        # it never fired in production: a transcript sweep for its own deny string returned 0 at removal
        # (`grep -roh --include='*.jsonl' '"content":"Blocked: merging this PR would let the forge close'
        # ~/.claude/projects/ | wc -l`).
        #
        # WHY IT GOES -- THE CRITERION, NOT THE FIRING COUNT (owner, #383): «o risco de permitir essa
        # operacao passar é one way door decision», narrowed by him to «situacoes irreparaveis».
        # **The act 7d refused is an Issue auto-close, and `gh issue reopen` restores the prior state
        # exactly, at no cost.** Nothing in this loop latches off a close: no publication, no deploy, no
        # tag, no distribution. Measured rather than assumed -- the only consumers of a closed Issue in
        # this tree are `closure-artifact-guard.sh`'s `Stop` arm, `dispatch-metrics-stop.sh`'s forge
        # source and `commands/sprint-retrospective.md`'s consult set, and all three read the tracker
        # live, so all three see the reopen. A lock does not survive on a reparable act however
        # correctly it fires, and 7d fired correctly -- that is the whole discomfort of this removal and
        # it is not a reason to exempt it from a test that was applied to `gh api` and to the milestone
        # pair.
        #
        # WHAT DOES **NOT** REPLACE IT, STATED PLAINLY BECAUSE THE OPPOSITE WAS ONCE WRITTEN DOWN AND
        # WAS WRONG. `closure-artifact-guard.sh`'s surviving `Stop` arm is NOT the replacement. Its
        # predicate is *an Issue that DECLARES an `invocable:` line*, and #355 -- the instance 7d was
        # built from -- declares none. So that arm could not have fired on 7d's own instance by any
        # route, and it does not fire on an undeclared Issue now. **NOTHING detects a merge auto-closing
        # an undeclared Issue.** That is the honest cost, and it is a DETECTION gap rather than an
        # exposure: the state it leaves is restored by one command.
        #
        # WHAT SURVIVES THE REMOVAL, because these are properties of the FORGE rather than of the hook,
        # and deleting the code would otherwise delete facts this repository paid probes to establish
        # (#375's template, the rehoming half):
        #   1. `closingIssuesReferences` is PR-BODY-DERIVED. Probed 2026-08-30 with a throwaway PR whose
        #      body carried no keyword and whose single commit message carried a closing keyword: the
        #      field returned an empty list. A keyword living only in a commit message is invisible to
        #      it -- and a commit message cannot be edited afterwards, since amending needs a force-push
        #      rule 3b denies.
        #   2. A NEGATED closing keyword still creates the link (#393 slice A). The forge parses the
        #      token, not the sentence around it, which is why a PR body is grepped for the keyword
        #      class before posting rather than read.
        #   3. A PROSE MENTION IS NOT A DECLARATION. Both gatekeeper verdicts on PR #356 contained the
        #      string for Issue 355, the merge-authorising one included, precisely BECAUSE it was the
        #      verdict prescribing the keyword's removal. Any future check over this material has to
        #      anchor at column 0 -- the same positional contract `purpose:` uses, for the same reason.
        #   4. The field rides on the SAME `gh pr view` call rule 7c already makes, at zero additional
        #      round-trips, and so does `--json files`. A merge-time classifier is REACHABLE. It is not
        #      built, and ADR-0004 records why: a path classifier cannot identify the latching case.
        # All four are rehomed to ADR-0004's record of this removal; they are restated here because this
        # is the file a reader arrives at when they wonder where 7d went.
        #
        # WHAT REMAINS AN INSTRUCTION: `agents/quality-assurance.md` still asks the gate to write a
        # `closes:` line naming what it verified delivered at that head. **Nothing reads it now.** It is
        # kept as the artifact that makes the divergence findable by a human comparing the verdict with
        # the forge's own resolved set, and that brief says so in those words rather than implying a
        # check that no longer exists.
      fi
      ;;
    *) deny "Blocked: merging a PR is the deploy and the quality-assurance's act, not the main agent's (ADR-0004). Route it through the quality-assurance subagent — invoke it with the human's go, and it performs the merge (approve-and-merge the safe class, or after your ratification for the boundary class). agent_type='${agent_type:-<main agent>}'." ;;
  esac
fi

# 8. Composition forms that make the permission system stop for a human. TWO BRANCHES SURVIVE AND ONE
#    IS GONE, and the difference between them is a measurement rather than a judgement.
#
#    ~~The matcher reads a command PREFIX; it cannot decompose `a && b`, expand `$(...)`, or see past
#    a `VAR=x` prefix, so an allowlisted tool still interrupts the human for approval.~~
#
#    STRUCK 2026-09-05 (#383, slice S2). THE FIRST CLAUSE IS FALSE. The matcher DOES decompose a
#    composition and evaluates each element on its own; it stops for a human only when some element
#    is not approved. Measured in a nested session carrying this guard MINUS rules 8 and 8b, loaded
#    with `claude --plugin-dir` (the #182/#286 probe-plugin method), against build 2.1.261. Each
#    verdict was confirmed on disk rather than taken from the nested model's report:
#
#      mkdir <A> && mkdir <B>     both allowlisted   -> EXECUTED, no prompt (both dirs created)
#      mkdir <A> ;  mkdir <B>     both allowlisted   -> EXECUTED, no prompt (both dirs created)
#      mkdir <A> && mkdir -p <B>  second DENIED      -> whole call DENIED  (neither dir created)
#      mkdir <A> && touch <B>     second not listed  -> "What required approval: touch in '<B>'"
#      mkdir <A>                  control            -> EXECUTED
#      touch <A>                  control            -> required approval
#
#    So the chain deny was not converting a prompt into an instruction. It was converting WORK INTO A
#    RETRY: a chain of allowlisted commands had nothing to prompt about, and a chain carrying a denied
#    or unlisted element is caught by the permission system anyway, element by element, naming the
#    offending element. That branch is deleted — see the tombstone below. It fired 2,140 times.
#
#    THE OTHER TWO BRANCHES MEASURED THE OTHER WAY, WHICH IS WHY THEY ARE STILL HERE. In the same
#    rule-8-less session:
#
#      mkdir <A>-$(basename /x/y)   -> "What required approval: Contains command_substitution"
#      FOO=1 mkdir <A>              -> "What required approval: mkdir in '<A>'" (the allow entry
#                                       no longer matched, although the bare form above executed)
#
#    Both genuinely stop for a human, so denying them here still buys what this rule was written for:
#    an instruction the agent can act on by itself instead of an interruption. **The premise is now
#    the measurement above, not the prefix story** — a substitution is flagged BY NAME by the runtime,
#    and an env-var prefix defeats the allow entry rather than the decomposition.
#
#    Pipes are deliberately NOT blocked: the matcher handles them.
if printf '%s' "$bare" | grep -Eq '(\$\(|`)'; then
  deny "Blocked: command substitution (\$(...) or backticks) forces a permission prompt even for allowlisted tools, because the matcher cannot expand it. Run the inner command as its own call and use the literal result."
fi
# 8-chain. REMOVED 2026-09-05 (#383, slice S2). It denied `&&`, `||` and `;` on the premise struck
#    above, and that premise was false for every form reachable with the rule absent. It is not
#    renumbered away: this file's convention since S1 is that a removed rule leaves a tombstone rather
#    than a gap someone later fills, and "rule 8" is cited across briefs, skills and records.
#
#    WHAT ITS ABSENCE COSTS, AND IT IS NOT NOTHING. A chained command now reaches the permission
#    system, which approves it only if EVERY element is approved. Where one element is not, the human
#    sees a prompt naming that element instead of the agent seeing an instruction it can act on. That
#    is a real UX regression on the minority of chains and the removal of a 2,140-fire tax on the
#    majority. It is not a floor change: every rule in this file matches a SUBSTRING of `$bare`
#    (`(^|[^[:alnum:]_])rm…`, `(^|[^[:alnum:]_])gh…`), so prefixing a denied act with a harmless
#    command does not walk past it — `echo x && gh pr merge 1` still meets rule 7b.
#
#    ── THE ENV-VAR BRANCH WAS ANCHORED AT STRING START AND IS WIDENED TO COMMAND POSITION (#438). ──
#
#    The predicate below read `^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*=` against `$bare`, and `^` was the
#    whole of it. Any statement in front of the assignment moved it off column zero and the branch
#    stopped matching, so the rule caught the honest spelling and only the honest spelling:
#
#      C=/usr/bin/git; "$C" status                    -> DENIED by this branch
#      export PATH="$PATH"; C=/usr/bin/git; "$C" …    -> ABSTAINED (the guard declined to decide)
#      export PATH="$PATH"; git push origin main      -> DENIED by rule 7 (the calibration: the
#                                                        identical prefix does not defeat the guard
#                                                        generally, so the gap was rule-8-specific)
#
#    #438 LEFT THE DIRECTION OPEN — widen, narrow, or delete — ON ONE UNMEASURED PREMISE: whether the
#    runtime stops the POST-STATEMENT form at all. If it does not, widening would put this hook above
#    the layer beneath it, which this file's own governing test forbids (see 8b: fire on a SUBSET of
#    what the runtime stops for, never on more). IT WAS MEASURED, and the answer is that it does.
#
#    Nested session, this guard MINUS this branch, loaded with `claude --plugin-dir` (the #182/#286
#    probe-plugin method), the installed plugin disabled via `--settings`, build 2.1.267 — NOT the
#    2.1.261 the rows above were taken on. Every verdict confirmed on disk or in the tool result:
#
#      wc -l <f>                          allowlisted   -> EXECUTED
#      FOO=1 wc -l <f>                    same command  -> "This command requires approval"
#      true; FOO=1 wc -l <f>              POST-STATEMENT-> "This Bash command contains multiple
#                                                          operations. The following part requires
#                                                          approval: FOO=1 wc -l <f>"
#      true; export FOO=1; BAR=2 touch <f>              -> TWO parts require approval; file absent
#      true; touch <f>                    calibration   -> EXECUTED (the leading statement alone is
#                                                          harmless; the prefix is what stops it)
#
#    THE RUNTIME DECOMPOSES, AND IT NAMES THE ENV-PREFIXED ELEMENT IN NON-LEADING POSITION. So this
#    branch's premise was observed for the leading and post-statement probes. These finite results
#    support widening to those forms; they do not prove a runtime subset for every shell spelling.
#
#    ONE CLAIM IN #438's BODY WAS NOT REPRODUCED BY THE SAME RIG, recorded here because it argued for
#    deletion: it read "it fires on MORE where spelled honestly and LESS where it is not", which would
#    require a case where this branch denies and the runtime would have allowed. Four were sought and
#    none was found — an env-var prefix defeated the allow entry (`FOO=1 wc -l`), the working-directory
#    sandbox (`FOO=1 touch <in-cwd>`, `FOO=1 mkdir <in-cwd>`) and the sandbox's auto-approval of an
#    UNLISTED command (`cp <in-cwd> <in-cwd>` EXECUTED; `FOO=1 cp` the same paths, BLOCKED). The branch
#    did not over-block those probes. That does not falsify the existence of an untested counterexample.
#
#    WHY COMMAND POSITION AND NOT "ANYWHERE". An assignment token is only an env prefix where a command
#    could start: string start, or after `;`, `&`, `|` or `(`. Matching anywhere would fire on ordinary
#    arguments that carry an `=` — `terraform plan -var foo=bar`, `docker run -e FOO=1`, `make FOO=1
#    target`, `awk -F= …` — none of which is a prefix. That
#    would be the over-block this rule's class must never be. The original leading check uses `$bare`
#    with quoted spans collapsed; the added check below recognizes the original string instead.
#
#    WHAT IS STILL NOT COVERED, NAMED RATHER THAN IMPLIED AWAY. An assignment reachable only through a
#    separator this pattern does not carry — a `case` arm's `)`, a `then`/`do`/`else` keyword — is an
#    ABSTENTION, not a claim. This file does not parse shell; where it cannot tell, the runtime decides,
#    which is the outcome that is correct either way.
#    #438 review: punctuation is also present in comments, heredocs, expansions and patterns. The
#    added check therefore recognizes ONLY a complete, simple composition in the ORIGINAL command:
#    ASCII words, blanks, simple subshells and the listed separators. No quotes, escapes, expansions,
#    redirects, glob syntax or newlines enter this language. Bash =~ anchors the entire string;
#    grep's line-wise ^...$ would wrongly accept a simple line INSIDE a heredoc. This is deliberately
#    narrower than shell: even a real prefix after a quoted/escaped word abstains in the extension.
#    The original leading predicate remains independent, and no other rule uses this recognition.
env_prefix_word='[-A-Za-z0-9_./,:=+%]+'
env_prefix_simple="$env_prefix_word([[:blank:]]+$env_prefix_word)*"
env_prefix_element="($env_prefix_simple|\([[:blank:]]*$env_prefix_simple[[:blank:]]*\))"
env_prefix_sequence="^[[:blank:]]*$env_prefix_element([[:blank:]]*(;|&&|\|\||\||&)[[:blank:]]*$env_prefix_element)*[[:blank:]]*;?[[:blank:]]*$"
if printf '%s' "$bare" | grep -Eq '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*=' ||
   { [[ "$command" =~ $env_prefix_sequence ]] &&
     printf '%s' "$command" | grep -Eq '[;&|(][[:space:]]*[A-Za-z_][A-Za-z0-9_]*='; }; then
  deny "Blocked: env-var prefix (VAR=x cmd) at a leading position or in a recognized simple composition hides the real command from the matcher and prompts the human. Prefer an npm script that sets it, or export it in a dedicated call."
fi

# 8b. Shell output redirection (`>` / `>>`) to create or overwrite a file. THIS IS A DIFFERENT ROOT
#     CAUSE FROM RULE 8 ABOVE, not a sub-case of it — rule 8 is about the matcher failing to decompose
#     a command it CAN otherwise allowlist; this is a permission prompt that fires on `command > path`
#     REGARDLESS of whether the command itself is allowlisted, measured repeatedly on 2026-08-13
#     (`git show … > file`, `gh pr diff … > file`, `python3 script.py > file`, several more), and
#     independent of the destination directory — `.scratch/`, the session scratchpad, anywhere; the
#     owner asked directly and the answer is the same everywhere. It is grouped with rule 8 anyway
#     because the REMEDY is identical: convert a human interruption into an instruction the agent can
#     act on itself, since guidance alone (a skill, a brief) did not hold — the model used `>` in this
#     very session after already having diagnosed the problem, which is the argument for a mechanical
#     floor over a preloaded rule.
#
#     THE ALTERNATIVE, STATED SO THE DENY MESSAGE IS ACTIONABLE RATHER THAN A DEAD END. Content the
#     agent is composing itself (a commit message, a PR/issue body, any generated text) goes through
#     `Write`, never a heredoc piped into `>`. Content that is a COMMAND'S OWN STDOUT (a `git show`, a
#     generator script) is captured by running the command WITHOUT the redirect — its output already
#     returns to the caller — and, if it needs to persist as a file, handed to `Write` from there. There
#     is no case this floor is aware of where `>`/`>>` is the only route to either outcome.
#
#     WHAT THIS DOES NOT CATCH, NAMED RATHER THAN HIDDEN. `2>&1`, `1>&2` and `>&2` redirect one STREAM
#     to another FILE DESCRIPTOR — they create no file, and are excluded by construction: the `&`
#     following the `>` marks a descriptor target, not a path. `&>`/`&>>` (bash's "redirect both
#     stdout+stderr to a file" shorthand) are the opposite case — the `&` PRECEDES the `>` there, the
#     target is still a path, and they ARE caught, correctly.
#
#     ── THIS RULE'S PREMISE WAS TESTED AT #383 S2 AND HELD; TWO OF ITS FALSE POSITIVES DID NOT. ──
#
#     Measured in the same rule-8-less nested session described above (build 2.1.261), so these are
#     the RUNTIME's own verdicts with this rule absent, not this rule's:
#
#       basename /x/y > <file, inside the primary working dir>  -> "What required approval: Output
#                                                                   redirection to '<file>'"
#       mkdir <A> 2>/private/.../err.txt                        -> same, naming err.txt
#       mkdir <A> 2>/dev/null                                   -> EXECUTED, no prompt (dir created)
#       mkdir <A> >/dev/null                                    -> EXECUTED, no prompt (dir created)
#       [[ zzz > aaa ]]                                         -> EXECUTED, no prompt, exit 0
#
#     So the premise stands — a redirect that CREATES a file stops for a human whatever the command
#     is — and the runtime's own check is DESTINATION-AWARE where this rule was not. It allowed
#     `2>/dev/null` and denied `2>somefile`, which is exactly the distinction this rule failed to make.
#     Every payload in the third, fourth and fifth rows was a case where this hook denied an act the
#     permission system would have let through silently: a false positive with no control behind it.
#
#     THE NARROWING THAT FOLLOWS, AND THE PRINCIPLE BEHIND IT. This rule exists only to convert a
#     prompt the runtime would raise into an instruction the agent can act on. It must therefore fire
#     on a SUBSET of what the runtime stops for, never on more — where it cannot tell, it abstains and
#     the runtime decides, which is the outcome that was correct all along. Two spans are removed from
#     a working copy of `$bare` before the test: a `/dev/null` target (with or without a leading file
#     descriptor, and `&>` included), which creates no file; and a `[[ … ]]` span, which is bash's
#     string comparison and not a redirect at all. The second is an ABSTENTION rather than a claim —
#     this file does not parse shell, so it hands `[[ … ]]` to the layer that does.
#
#     ── BOTH STRIPS WERE TOO LOOSE ON THE ROUND THEY LANDED, AND BOTH ARE TIGHTENED HERE (#383 S2). ──
#
#     The first form of the `/dev/null` strip was not right-anchored, so any target merely BEGINNING
#     `/dev/null` was swallowed and reached ALLOW; the `[[ … ]]` strip was lexical rather than
#     positional, so a bracket span in ARGUMENT position was swallowed too — and `echo x [[ a > P ]] b`
#     is a real redirect in bash, confirmed by execution (the file appears, carrying `hello [[ a ]] b`).
#     Measured against the runtime on build 2.1.261, same rig and same build as the probe above, this
#     hook absent:
#
#       date > /dev/nullx                        -> "What required approval: Output redirection to
#                                                    '/dev/nullx' was blocked"
#       echo hello [[ a > <wd>/evil1 ]] b        -> "What required approval: Redirect has multiple
#                                                    targets — post-redirect args swallowed"
#       date > /dev/null/../wd/evil3             -> "What required approval: Path contains '..'
#                                                    traversal after a directory segment"
#       date > /dev/null · date >/dev/null · date 2>/dev/null   -> EXECUTED, no prompt
#       [[ zzz > aaa ]] · if [[ zzz > aaa ]]; then echo yes; fi -> EXECUTED, no prompt
#
#     SO THE RUNTIME IS THE BACKSTOP AND NEITHER LOOSENESS WAS A ROUTE TO AN ACT: both degraded to a
#     prompt, never to a silent write. What they cost is this rule's whole purpose — a prompt that
#     should have been an instruction. The strips are therefore tightened to the narrowest form that
#     does not OVER-block, which is the constraint that shapes them: the last two payloads above run
#     with no prompt, so a `[[ … ]]` in command position — start of string, after `; & | ( ) { } !`,
#     or after `if`/`while`/`until`/`elif`/`then`/`else`/`do` — must still be stripped, while one in
#     argument position must not. The `/dev/null` strip now requires whitespace, a shell separator or
#     end-of-string after the target, which additionally makes `> /dev/null/../…` deny — matching the
#     runtime, which refuses it on traversal.
#
#     ── THE RIGHT-ANCHOR OVER-CORRECTED, AND THE SEPARATOR CLASS IS THE REPAIR (#383 S2, round 3). ──
#
#     The anchor first shipped as `([[:space:]]|$)`, which fired the strip ONLY on whitespace or end of
#     string — so `date >/dev/null;echo hi`, `… &&echo hi`, `(date >/dev/null)`, `{ date >/dev/null; }`
#     and `… 2>/dev/null|head -1` all fell through to the deny. All five were ALLOW one commit earlier,
#     none creates a file, and they are the exact shapes S1 had just un-taxed by removing rule 8's chain
#     branch. The trailing class therefore carries `; & | ) }` as well.
#
#     MEASURED against the runtime on build 2.1.261 — same nested `claude --plugin-dir` rig as above,
#     this hook absent, `--permission-prompts none` making a would-prompt observable, verdicts confirmed
#     on disk rather than from the session's own report:
#
#       date >/dev/null;touch m1      -> EXECUTED, no prompt (the marker file appears)
#       (touch m2 >/dev/null)         -> "uses shell operators (subshell and redirection)" — APPROVAL
#       date >/dev/null · date > c2   -> executed, no prompt / approval required (controls, unchanged)
#
#     SO THE TWO HALVES OF THE WIDENING ARE NOT THE SAME CLAIM, AND THE WEAKER ONE IS SAID OUT LOUD.
#     For `;` the widening restores PARITY with the runtime. For `( … )` the runtime prompts anyway, so
#     the widened rule fires on LESS than the runtime stops for — the safe side of ADR-0004's subset
#     rule, and deliberately not narrowed back: what is lost there is this rule's instruction, never a
#     block, because the runtime is the backstop. The pipe form was probed and is INCONCLUSIVE — the
#     nested session refused it naming the `grep` element rather than the redirect, so nothing is
#     claimed about `|` in either direction.
#
#     THE KEYWORD ALTERNATIVE OF THE `[[ … ]]` STRIP IS KNOWN-LOOSE AND IS DELIBERATELY LEFT (#383 S2).
#     It is not itself position-checked, so any of `if|while|until|elif|then|else|do` immediately before
#     a bracket span makes it read as command position wherever it sits — `echo hello do [[ a > F ]] b`
#     is stripped and reaches ALLOW, and it IS a real redirect in bash. The narrowing was attempted and
#     REVERTED, on measurement rather than on effort: requiring the keyword to follow `^` or a separator
#     denies a multi-line `if … / then / [[ … ]] / fi`, because `bare` flattens newlines to spaces
#     upstream and the keyword then sits mid-string. Repairing that needs a fixpoint LOOP over the
#     strip, not a character class, which is a different shape from this edit. It stays because the
#     direction is safe and it was probed: the runtime stopped `echo hello do [[ a > m4 ]] b` with
#     "Redirect has multiple targets — post-redirect args swallowed", so the hook fires on LESS than
#     the runtime here too.
#
#     STILL NOT CAUGHT, AND STILL ACCEPTED: a heredoc body (`<<EOF … EOF`) that happens to contain a
#     literal `>` (e.g. a markdown blockquote line) and is NOT itself feeding a redirect will still be
#     denied — `bare` strips quoted-string CONTENTS upstream (line ~337) but a heredoc is not a quoted
#     span in that sed's sense. Accepted rather than chased, because the remedy this rule exists to
#     push — compose with `Write`, capture stdout by not redirecting it — makes the heredoc-into-redirect
#     pattern that would trigger it disappear from normal use in the first place. It is also the one
#     false positive that bites this repository's own harness reviewer hardest, which is why it is
#     named in `agents/agents-lead.md` as well as here.
redirect_probe="$(printf '%s' "$bare" | sed -E 's%(^|[;&|(){}!]|(^|[[:space:]])(if|while|until|elif|then|else|do))[[:space:]]*\[\[[^]]*\]\]%\1%g')"
redirect_probe="$(printf '%s' "$redirect_probe" | sed -E 's%[0-9]?>{1,2}[[:space:]]*/dev/null([[:space:];&|)}]|$)%\1%g')"
if printf '%s' "$redirect_probe" | grep -Eq '>{1,2}([^&]|$)'; then
  deny "Blocked: shell output redirection ('>' or '>>') to create or overwrite a file. Content you are composing yourself goes through the Write tool, never a heredoc piped into '>'. Content that is a command's own stdout: run the command WITHOUT the redirect (its output returns to you) and Write it from there if it needs to persist. (If this fired on a heredoc body containing a literal '>' rather than an actual redirect: rephrase without it — this floor does not parse shell and cannot tell the two apart. '[[ a > b ]]' string comparison and a '/dev/null' target are exempt since #383 and should not reach you.)"
fi

# 9. REMOVED 2026-09-04 (#383, slice S1). THE NUMBER IS LEFT VACANT DELIBERATELY — a rule list that
#    silently renumbers makes every citation of "rule 9" in this repo's records point at whatever
#    moved up into the slot.
#
#    WHAT IT WAS: a deny on a `..` segment in the first non-flag token after a shell in command
#    position. WHAT IT CLAIMED: nothing. Its own header called it "A SPEED BUMP ON THE NAIVE
#    TRAVERSAL — NOT A BOUND, AND IT MUST NEVER BE CITED AS ONE", and three measured escape classes
#    walked through it, one of which (`.""./`) has no `..` adjacency at all, so no widening of any
#    pattern could ever have reached it.
#
#    WHY IT WENT: the owner's criterion (#383) — a mechanical lock survives only where no other
#    harness element can carry the control. This one carried no control to relocate. ADR-0004's
#    section "A path in an `allow` entry is a string prefix, not a directory scope" already held the
#    whole of what it knew, and now also holds the three escape spellings and the positional-parsing
#    lesson that were only ever recorded here.
#
#    WHAT ITS ABSENCE COSTS, MEASURED AND NOT SOFTENED. The global floor allows
#    `Bash(bash <repo>/hooks/scripts/*)`, so a traversal carrying that prefix now EXECUTES SILENTLY —
#    no prompt, no record. A path carrying no allowed prefix falls to a permission prompt. Neither
#    outcome is new reach: every act rule 9 denied was already reachable one interpreter over
#    (`command perl -e …` runs with no decision from any layer), which is exactly why the deny bought
#    nothing. Do not re-add it without reading ADR-0004's section first.

# 10 and 11. REMOVED 2026-09-04 (#383, slice S1) — THE MILESTONE PAIR. Numbers left vacant, for the
#    reason rule 9's tombstone gives.
#
#    WHAT THEY WERE. Rule 10 matched `gh issue create`/`gh issue edit` carrying `--milestone`/`-m` and
#    split on `agent_type`: a subagent was DENIED, the orchestrator was ASKED. Rule 11 did the same for
#    the `scripts/milestone-*.sh` family, the sanctioned milestone-write route. Together they were this
#    file's only `ask` verdicts and its only PREVENTIVE answer to #365's *«itens nao podem ser criados
#    dentro do sprint automaticamente sem verificacao HITL»* — the owner's answer to the prompt WAS
#    that verification.
#
#    WHY THEY WENT, AND IT IS THE OWNER'S OWN PRICING RATHER THAN THE AUDIT'S PREFERENCE. The audit
#    surfaced them as DROPs that collided with a standing instruction and refused to resolve it. He
#    ruled:
#
#        «mexer em milestones nao é um risco crucial a iniciativa»
#
#    The criterion for this whole audit is IRREPARABLE, not costly and not merely traceable. A
#    milestone assignment is undone by `--remove-milestone` — which rule 10 deliberately never matched,
#    precisely because removal is the corrective act — and a milestone is deleted. Nothing latches.
#
#    ── WHAT THIS COSTS, AND IT IS NOT A DOWNGRADE. READ THIS BEFORE ASSUMING THE FLOOR COVERS IT. ──
#
#    RULE 10 IS A REAL REMOVAL WITH SILENT EXECUTION. `Bash(gh issue edit:*)` is allowlisted in BOTH
#    settings layers, and this hook decides BEFORE the permission system does. So an item is admitted
#    to a running iteration with NO prompt, NO deny and NO record. **#365's objection was never that
#    the act is dangerous — it was that it silently changes a running iteration's contents and its
#    completion bar. That failure mode is unchanged; what is gone is the prompt that made it visible
#    at the moment it happened.** Nothing detects it either: no hook in this directory reads the queue.
#
#    RULE 11 IS DIFFERENT AND MUST NOT BE DESCRIBED WITH RULE 10'S SENTENCE. `scripts/` matches no
#    allow entry in either layer (the global floor allows `bash <repo>/hooks/scripts/*`, a different
#    directory), so a milestone-script run still reaches a PERMISSION PROMPT for the orchestrator, and
#    an unanswerable one for a subagent. **Its removal is close to behaviour-neutral; what is lost is
#    the rule's own text, which explained WHY the prompt was there.**
#
#    AND THAT SURVIVING PROMPT IS AN ABSENCE, NOT A CONTROL — which is the shape ADR-0004 books under
#    "Permission entries have three states, and absent is not one". Rule 11's own comment said so while
#    it existed: leaning on the absence means an allow entry added later for an unrelated reason
#    silently removes the verification, and nothing would say so. That is now the standing state.
#
#    NOTHING IS APPENDED BELOW THIS POINT. Both rules were placed last because `ask` exits exactly as
#    `deny` does, so an `ask` sited earlier would have SOFTENED a deny. With the asks gone that hazard
#    is gone with them, but the rule stays: a verdict added here runs after every deny above and must
#    be one that is safe in that position.

exit 0
