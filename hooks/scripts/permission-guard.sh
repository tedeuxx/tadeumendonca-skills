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
# floor, rules 7c AND 7d, which fail CLOSED since 2026-08-28 (#341) and 2026-08-30 (#363).**
#
# 7d IS NOT A SECOND EXCEPTION — IT IS THE SAME ONE, ONE FIELD WIDER. It runs only after 7c has already
# read the PR and cleared the verdict, on the SAME payload, and it guards the same irreversible act. Its
# one degradation branch (the payload came back without `closingIssuesReferences`) denies for exactly
# 7c's reason: the read that would have decided did not happen. Nothing else in this file moved.
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
#   hypothetical — `wip-guard.sh` records the measured case: with `jq` off `PATH` the guard emitted no
#   decision at all. A guard that denies everything when its own dependency is missing cannot be fixed
#   by the agent, because fixing it requires running commands.
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

# 3. Irreversible git history / ref rewrites.
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]].*(push([[:space:]].*)?([[:space:]](--force|--force-with-lease|-f)([[:space:]]|$))|reset[[:space:]]+--hard)'; then
  deny "Blocked: force-push / 'git reset --hard' rewrites history irreversibly. Use a safe alternative (git revert, a new commit)."
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

# 5. Secret writes (sensitive, escape git).
if printf '%s' "$cmd" | grep -Eq 'aws[[:space:]]+secretsmanager[[:space:]]+(put-secret-value|create-secret|update-secret|delete-secret|restore-secret)'; then
  deny "Blocked: writing secrets via CLI. Secrets are provisioned by the pipeline, not by the agent."
fi
if printf '%s' "$cmd" | grep -Eq 'aws[[:space:]]+ssm[[:space:]]+put-parameter([[:space:]].*)?SecureString'; then
  deny "Blocked: writing a SecureString parameter. Secrets are provisioned by the pipeline, not by the agent."
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
if printf '%s' "$bare" | grep -Eq "(^|[^[:alnum:]_])gh${gh_repo_flag}[[:space:]]+repo[[:space:]]+(delete|archive|rename)([[:space:]]|\$)"; then
  deny "Blocked: 'gh repo delete/archive/rename' changes or destroys the repository itself, and it escapes git entirely. A rename also breaks every AWS OIDC trust pinned to the immutable subject (repo:<org>@<id>/<repo>@<id>:*). This is the human's act, on the GitHub UI, never the agent's."
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
#     NUMBERED 5f, PLACED FIRST AMONG THE `gh` RULES, same convention as 5e below: the NUMBER is
#     lineage, the POSITION is deliberate. It runs before 5c and 7b because it is the route BOTH of
#     them book as their residual, so a reader arriving at either residual paragraph has already passed
#     the rule that closes it. Nothing here depends on the order — 5f matches `gh api`, which no other
#     rule matches at all — but a reader's understanding does.
#
#     WHY IT IS HERE AND NOT IN THE FLOOR'S `deny`, WHICH IS WHERE IT LIVED FOR AN HOUR. The permission
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
  deny "Blocked: this \`gh api\` call WRITES (it carries --method POST/PUT/PATCH/DELETE, -X, -f/-F/--field/--raw-field, or --input; note that -f and -F make the request a POST on their own). The raw API is the back door around the rules that own these acts — opening an issue (5c/5d) and merging a PR (7b) — so a write here is the one spelling those gates cannot see. Use the gh subcommand for the act instead, so the rule that owns it applies: \`gh issue create\`, \`gh pr merge\`, \`gh pr comment\`. READING through \`gh api\` is untouched — drop the field flags and pass query parameters in the endpoint (\`gh api 'repos/o/r/issues?state=open'\`)."
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
      *:developer) : ;;  # a no-op that CONTINUES to rules 7, 7b and 8 — see the `NOT exit 0` note above
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
if printf '%s' "$bare" | grep -Eq '(^|[^[:alnum:]_])git([[:space:]]+(-C[[:space:]]+[^[:space:]]+|-c[[:space:]]+[^[:space:]]+|--git-dir=[^[:space:]]+|--work-tree=[^[:space:]]+))*[[:space:]]+push([[:space:]]|$)'; then
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
  # A bare `git push` inherits HEAD — resolve it instead of guessing from the string.
  dir="$(printf '%s' "$bare" | sed -nE 's/.*[[:space:]]-C[[:space:]]+([^[:space:]]+).*/\1/p')"
  [ -z "$dir" ] && dir="."
  # symbolic-ref, not rev-parse: it reports the checked-out branch even when HEAD is
  # unborn (a fresh repo with no commits), where rev-parse fails and would silently
  # skip this check. On a detached HEAD it fails too, which is correct — there is no
  # branch to land on.
  branch="$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null || true)"
  case "$branch" in
    main|master)
      deny "Blocked: HEAD is '$branch', so this push lands on the trunk. Merging to main is the deploy and the human's go/no-go. Branch first, then push the branch." ;;
  esac
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
if printf '%s' "$bare" | grep -Eq "(^|[^[:alnum:]_])gh${gh_repo_flag}[[:space:]]+pr[[:space:]]+merge([[:space:]]|\$)"; then
  # SQUASH IS DENIED TO EVERYONE, THE REVIEWER INCLUDED, and it is checked BEFORE the persona case so
  # the exemption cannot carry it. The floor denies `gh pr merge --squash`; `Bash(gh -R:*)` walked
  # around that entry like every other, and the reviewer — the one caller 7b lets through — is exactly
  # who would run it. The standing rule is a real merge commit, never a squash: per-commit history is
  # the record of how a change was reached, and squashing discards it irreversibly on the trunk.
  if printf '%s' "$bare" | grep -Eq '[[:space:]](--squash|-s[[:space:]=]*squash)([[:space:]]|$)'; then
    deny "Blocked: never squash-merge. Use a real merge commit ('gh pr merge --merge') — per-commit history is the record of how the change was reached, and a squash discards it irreversibly once it is on the trunk."
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
      # `command-hygiene` skill MANDATES ("Target another repo with `gh <subcommand> --repo
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
      # NAMED RESIDUAL, not fixed here: any OTHER value-taking flag placed before the positional ref
      # (`gh pr merge -t "subject" 479`) still misdirects the ref the same way. Its blast radius is
      # much smaller than the repo case — it falls back to the current branch's PR, which under WIP=1
      # is almost always the PR being merged — and a general fix is a token-level argv parser, not a
      # regex. It is a finding for the owner, not a silent gap.
      qa_ref="$(printf '%s' "$bare" | sed -E -e 's/[[:space:]](-R[[:space:]=]*|--repo[[:space:]=]*)[^[:space:]]+/ /g' -e 's/^.*[[:space:]]pr[[:space:]]+merge[[:space:]]*//')"
      qa_ref="${qa_ref%% *}"
      case "$qa_ref" in -*|'') qa_ref="" ;; esac
      qa_repo="$(printf '%s' "$bare" | sed -nE 's/.*[[:space:]](-R[[:space:]=]*|--repo[[:space:]=]*)([^[:space:]]+).*/\2/p')"
      qa_pr_json=""
      # `qa_unavailable` IS THE SENTINEL THE OLD `''` ARM DID NOT HAVE. Non-empty means "the read did
      # not happen", and it carries the reason in the words the deny message needs — one string per
      # cause, so the message attributes rather than shrugging.
      qa_unavailable=""
      if ! command -v gh >/dev/null 2>&1; then
        qa_unavailable="the 'gh' CLI is not on PATH, so the verdict comment on the PR cannot be read at all"
      elif ! command -v jq >/dev/null 2>&1; then
        qa_unavailable="'jq' is not on PATH, so the verdict comment cannot be parsed"
      else
        if [ -n "$qa_repo" ]; then
          qa_pr_json="$(gh pr view ${qa_ref:+"$qa_ref"} --repo "$qa_repo" --json headRefOid,comments,closingIssuesReferences 2>/dev/null || true)"
        else
          qa_pr_json="$(gh pr view ${qa_ref:+"$qa_ref"} --json headRefOid,comments,closingIssuesReferences 2>/dev/null || true)"
        fi
        if [ -z "$qa_pr_json" ]; then
          qa_unavailable="'gh pr view ${qa_ref:-<the current branch>}${qa_repo:+ --repo $qa_repo}' returned nothing — no network, missing or expired auth, a rate limit, or a PR reference that resolves to no pull request"
        fi
      fi
      if [ -n "$qa_unavailable" ]; then
        deny "Blocked: the merge floor could not READ your gate verdict, and since #341 that denies instead of passing — ${qa_unavailable}. This is NOT a finding about the PR: the floor is not saying your verdict is wrong, it is saying it could not confirm one exists on the current head, and the owner's rule for that case is 'no readable verdict, no merge'. Fix the precondition named above and run this again — check 'gh auth status', check the network, and check that the PR reference in this command names a real pull request in the intended repo. If it cannot be fixed from here, the unblock is manual and the owner's: hand him the PR and say which precondition was missing."
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
          '') deny "Blocked: the merge floor read a response for this PR but could not determine its CURRENT head, so it cannot tell whether any verdict applies to the code that is there now — and since #341 an unreadable verdict denies rather than passing. Either 'gh pr view' returned a payload with no headRefOid (a partial or error response), or parsing it failed. Re-run 'gh pr view <ref> --json headRefOid,comments' by hand and see what comes back; if the PR is real and reachable, this is a finding about the tooling, not about your review. The unblock is manual and the owner's." ;;
          *) deny "Blocked: the last quality-assurance verdict on this PR's CURRENT head is '${qa_verdict}', which is neither APPROVE-AND-MERGE (safe class) nor APPROVE-AND-MERGE-BOUNDARY (boundary class, merged by the gate since ADR-0002 amendment #16) — so this merge does not match its own review record (ADR-0004). This is not a caller problem: rule 7b already confirms you are quality-assurance. It means either the head moved since that verdict was posted, the verdict was never re-posted after a later round, or the literal drifted from the one 'Your verdict — exactly one of' in your own brief defines. Post a correct verdict against the CURRENT head before merging — or, if this is one of the four holds that survive (an expansion of your own authority, a harness diff with no agents-lead marker, anything in iac/, or a lens ESCALATE), never call this tool: APPROVE-PENDING-HUMAN and hand the go/no-go to the human." ;;
        esac

        # 7d. THE MERGE MUST NOT CLOSE AN ISSUE THE VERDICT DID NOT NAME (#363, adopted from a foreign
        # harness's `mr-selection-artifact-gate`, auto-close half only — the review half is rule 7c and
        # was already here).
        #
        # THE DEFECT IS NOT "DELIVERY WAS NOT VERIFIED", AND GETTING THAT WRONG BUILDS THE WRONG CONTROL.
        # On the live instance — PR #356, Issue #355 — delivery WAS verified: the gate read the diff,
        # judged that #355 was not delivered, and prescribed `Closes #355` → `Refs #355` with its
        # reasoning. **The gate was right.** What failed is that the prescription became a PR-BODY EDIT
        # and nothing verified the edit took. Measured at head, on the merged PR:
        #
        #   gh pr view 356 --repo <owner>/<repo> --json body --jq '.body' \
        #     | grep -ioE '(clos(e|es|ed)|fix(e[sd])?|resolv(e|es|ed))[[:space:]]+#[0-9]+'   -> close #355
        #   gh pr view 356 --repo <owner>/<repo> --json closingIssuesReferences               -> [355]
        #
        # The survivor sits INSIDE the sentence explaining why the keyword must not be used. That is the
        # third time this repository has paid for it, and it is why the check runs at MERGE rather than
        # as a checklist step: the edit that re-arms the keyword is characteristically the last one, the
        # one describing the correction, and a checklist finding is stale the moment the body changes
        # after it.
        #
        # SO THE OBLIGATION HAS NO JUDGEMENT IN IT.
        # It compares two artifacts and never judges delivery.
        # The forge's own derived set is one; the gate's own verdict at the current head is
        # the other. Every number the forge will act on must be a number the verdict DECLARES. That is a
        # string comparison over material rule 7c already fetched — see the `--json` list above, which
        # gained one field and ZERO round-trips.
        #
        # WHAT MAKES A CLOSE LEGITIMATE HERE, STATED IN THE MECHANISM BECAUSE THE FALSE POSITIVE IS THE
        # REAL RISK. A PR that closes a delivered Issue is the common case, and a refusal people learn to
        # route around is worse than none (measured twice in this repository). So the legitimate close is
        # not blocked — it is DECLARED: one line at column 0 in the verdict the gate is already posting,
        # `closes: 355`, naming the Issues it verified delivered at that head. Cost: one line, in an
        # artifact that already exists, written by the persona that already made the judgement. A PR that
        # closes nothing declares nothing and never reaches the comparison at all.
        #
        # WHY A DECLARED LINE AND NOT "THE VERDICT MENTIONS #355" — THIS IS THE MEASUREMENT THAT KILLED
        # THE OBVIOUS DESIGN. Both gatekeeper verdicts on #356 contain the string `#355`, the
        # merge-authorising one included, BECAUSE it is the verdict that prescribed removing the keyword:
        #
        #   gh pr view 356 --repo <owner>/<repo> --json comments \
        #     --jq '[.comments[]|select(.body|contains("gatekeeper-verdict"))]
        #           |map({literal:(.body|split("\n")[1]), mentions:(.body|test("#355"))})'
        #   -> [{"literal":"REQUEST-CHANGES","mentions":true},
        #       {"literal":"APPROVE-AND-MERGE-BOUNDARY","mentions":true}]
        #
        # A prose-mention check passes the exact case it exists to refuse. The anchor is `^closes:` at
        # column 0, case-sensitive, for the same reason `purpose:` is positional in this tree: the token
        # occurs in ordinary wrapped prose, and a check that cannot tell a declaration from a sentence is
        # not a check.
        #
        # THE BLIND SPOT, MEASURED RATHER THAN ASSUMED, AND NAMED RATHER THAN WIDENED AWAY.
        # `closingIssuesReferences` is PR-BODY-DERIVED. Probed on 2026-08-30 with a throwaway PR whose
        # body carried no keyword and whose single commit message carried `Closes #358`:
        #
        #   gh pr view 367 --repo <owner>/<repo> --json closingIssuesReferences   ->  []
        #
        # So this rule is blind to a closing keyword living only in a COMMIT MESSAGE — the one surface
        # that cannot be edited afterwards, since amending needs a force-push the floor denies. It is
        # NOT widened to scan commit messages, deliberately: that needs the PR's head branch and its
        # merge-base resolved inside a rule that fails CLOSED, so every resolution failure would become
        # a wedged merge, and a hand-rolled keyword regex is measurably both over- and under-inclusive
        # against the forge's own parser (`Closes #313's slice 1.` matched by regex, resolved by GitHub
        # to a different number entirely). Whether that route actually closes an Issue on merge here is
        # **NOT measured** — this repository has no PR whose commits carry a keyword its body does not,
        # so the two routes have never been separable in its history.
        #
        # AND IT HAS ZERO REACH OVER A BROWSER MERGE, exactly like 7c. Keep the `Stop`-hook detection
        # arm in `closure-artifact-guard.sh`: it covers the route this refusal cannot see, and a refusal
        # presented as complete coverage would be a worse artifact than one that names its hole.
        if [ -n "$qa_pr_json" ]; then
          qa_closing_present="$(printf '%s' "$qa_pr_json" | jq -r 'has("closingIssuesReferences")' 2>/dev/null || true)"
          if [ "$qa_closing_present" != "true" ]; then
            deny "Blocked: the merge floor could not read WHICH Issues this PR would close — 'gh pr view' answered, but the payload carries no closingIssuesReferences field, so rule 7d cannot tell whether the forge is about to close an Issue your verdict never named. Like rule 7c above it, this DENIES rather than passing (#363): the read that would have decided did not happen, and on the irreversible act that is not a silence to accept. Check that this rule's own 'gh pr view --json' list still requests closingIssuesReferences. If it does and the field is still absent, this is a finding about the tooling and not about your review — the unblock is manual and the owner's."
          fi
          qa_closing="$(printf '%s' "$qa_pr_json" | jq -r '[.closingIssuesReferences[]?.number // empty] | .[]' 2>/dev/null || true)"
          if [ -n "$qa_closing" ]; then
            qa_declared="$(printf '%s' "$qa_pr_json" | jq -r --arg m '<!-- gatekeeper-verdict: quality-assurance -->' '
    (.headRefOid // "") as $h
    | if $h == "" then ""
      else [ .comments[]?
             | select((.authorAssociation // "") as $a
                      | ["OWNER","MEMBER","COLLABORATOR"] | index($a))
             | .body // ""
             | select(contains($m)) | select(contains($h)) ]
           | if length == 0 then ""
             else (.[-1] | split("\n") | map(select(test("^closes:"))) | join(" ")) end
      end' 2>/dev/null || true)"
            qa_declared_nums="$(printf '%s' "$qa_declared" | grep -oE '[0-9]+' | sort -u || true)"
            qa_undeclared=""
            for qa_n in $qa_closing; do
              printf '%s\n' "$qa_declared_nums" | grep -qx "$qa_n" && continue
              qa_undeclared="$qa_undeclared #$qa_n"
            done
            if [ -n "$qa_undeclared" ]; then
              deny "Blocked: merging this PR would let the forge close${qa_undeclared}, and your own verdict on this PR's CURRENT head declares no such close (#363). A closing keyword fires at merge and knows nothing about whether the thing the Issue promised exists — measured here: PR #356 closed Issue #355 with nothing #355 asked for built, and the keyword that did it survived inside the very sentence explaining why it must not be used. TWO EXITS, both cheap. If you verified those Issues delivered at this head: re-post your verdict with a 'closes:' line at COLUMN 0 naming every number above — 'closes: 355', or 'closes: 355 337' for several. If you did not: edit the PR body so the keyword reads 'Refs #N', then VERIFY with 'gh pr view <ref> --json closingIssuesReferences' returning [] — do not read the body and assume, because that is exactly the step that failed on #356. This rule compares two artifacts and never judges delivery: it cannot tell you whether the work was done, only whether the forge is about to act on a close your own review record does not name."
            fi
          fi
        fi
      fi
      ;;
    *) deny "Blocked: merging a PR is the deploy and the quality-assurance's act, not the main agent's (ADR-0004). Route it through the quality-assurance subagent — invoke it with the human's go, and it performs the merge (approve-and-merge the safe class, or after your ratification for the boundary class). agent_type='${agent_type:-<main agent>}'." ;;
  esac
fi

# 8. Command composition that defeats the permission matcher. The matcher reads a
#    command PREFIX; it cannot decompose `a && b`, expand `$(...)`, or see past a
#    `VAR=x` prefix, so an allowlisted tool still interrupts the human for approval.
#    Denying here converts that human interruption into an instruction the agent can
#    act on by itself — the whole point, since guidance alone did not hold. Pipes are
#    deliberately NOT blocked: the matcher handles them.
if printf '%s' "$bare" | grep -Eq '(\$\(|`)'; then
  deny "Blocked: command substitution (\$(...) or backticks) forces a permission prompt even for allowlisted tools, because the matcher cannot expand it. Run the inner command as its own call and use the literal result."
fi
if printf '%s' "$bare" | grep -Eq '(&&|\|\||;)'; then
  deny "Blocked: chained command (&& / || / ;). The matcher reads one command prefix, so a chain prompts the human even when every part is allowlisted. Issue one atomic command per call — use 'git -C <dir>' / 'npm --prefix <dir>' / absolute paths instead of 'cd X && ...'."
fi
if printf '%s' "$bare" | grep -Eq '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*='; then
  deny "Blocked: env-var prefix (VAR=x cmd) hides the real command from the matcher and prompts the human. Prefer an npm script that sets it, or export it in a dedicated call."
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
#     target is still a path, and they ARE caught, correctly. `[[ a > b ]]`, bash's string comparison
#     operator, is lexically indistinguishable from a redirect by a tool that does not parse shell (the
#     standing rule two rules up: this file expresses a property, it does not evaluate one), so a
#     command using it will be denied too — a known, accepted false positive, the same shape and the
#     same honesty as rule 9's own escape classes below. Likewise a heredoc body (`<<EOF … EOF`) that
#     happens to contain a literal `>` (e.g. a markdown blockquote line) and is NOT itself feeding a
#     redirect will still be denied — `bare` strips quoted-string CONTENTS upstream (line ~337) but a
#     heredoc is not a quoted span in that sed's sense. Both are accepted rather than chased, because the
#     remedy this rule exists to push — compose with `Write`, capture stdout by not redirecting it — makes
#     the heredoc-into-redirect pattern that would trigger it disappear from normal use in the first place.
if printf '%s' "$bare" | grep -Eq '>{1,2}([^&]|$)'; then
  deny "Blocked: shell output redirection ('>' or '>>') to create or overwrite a file. Content you are composing yourself goes through the Write tool, never a heredoc piped into '>'. Content that is a command's own stdout: run the command WITHOUT the redirect (its output returns to you) and Write it from there if it needs to persist. (If this fired on '[[ a > b ]]' string comparison or a heredoc body containing a literal '>' rather than an actual redirect: rephrase without it — this floor does not parse shell and cannot tell the two apart.)"
fi

# 9. A SPEED BUMP ON THE NAIVE TRAVERSAL. **NOT A BOUND, AND IT MUST NEVER BE CITED AS ONE.**
#
#    ~~This is the control that makes a directory-scoped wildcard mean what it says.~~ **STRUCK the
#    day it was written, 2026-08-07, by the gate that reviewed it.** It does not. `Bash(bash .scratch/*)`
#    remains `bash <any path on disk>`; the owner accepted that knowingly (option A), and the record of
#    the acceptance — not this rule — is what makes the floor honest.
#
#    THREE ESCAPE CLASSES, ALL MEASURED AGAINST THIS RULE IN FORCE:
#
#      bash .scratch/\.\./\.\./other-repo/VERSION    ALLOW — backslash escape; `\` is not in the
#                                                    preceding-character class, and `\.` is `.` to the shell
#      bash .scratch/.""./.""./other-repo/VERSION    ALLOW — empty quoted span; there is no `..` ADJACENCY
#                                                    anywhere in the string, so NO widening of the
#                                                    character class can find it. This is the one that
#                                                    settles the question.
#      bash .scratch/link.sh                         ALLOW — symlink out; the guard never resolves paths
#
#    Note the asymmetry that would fool a single probe: escaping ONE dot pair still denies on the next.
#    A prober who tried one escape and saw a deny would have concluded the rule held.
#
#    THE CAUSE, WHICH IS WHY THIS IS NOT A REGEX BUG. **Rule 9 asserts a FILESYSTEM property with a
#    LEXICAL instrument.** Between the command string and the file that opens sit quote removal, escape
#    processing and symlink resolution. This guard does none of the three — deliberately, since doing
#    them means parsing shell — and every escape above is one of them. Widening the pattern a fourth
#    time would repeat the week's defect at a higher altitude: the shape was never the problem.
#
#    WHY IT IS KEPT ANYWAY. It costs one grep, it catches the spelling a person or an agent reaches for
#    without thinking, and a speed bump that announces itself as a speed bump is honest. What it must
#    not do is appear in any sentence containing the word *bounded*. It buys no containment: the floor
#    grants UNINSPECTED EXECUTION THROUGH MORE ENTRIES THAN ANYONE HAS ENUMERATED, so every act it
#    denies is one interpreter away regardless. `python3` and `node` are the obvious ones; `perl` and
#    `ruby` were removed BY NAME and are still reachable through `Bash(command:*)`, and `Bash(awk:*)`
#    and `Bash(find:*)` each execute arbitrary code without naming an interpreter at all.
#    **DO NOT REPLACE THIS WITH A LIST.** Two attempts to state the set as a number ("six", then "four")
#    were each false one round later — a closed enumeration answering an open grammar. The claim is the
#    PROPERTY, and the count is not part of it.
#
#    ── the original reasoning, kept because the standing rule it invokes is still right ──
#    It is here because THE MATCHER CANNOT EXPRESS IT — the standing rule for the next rule, applied.
#    That rule remains correct; what this episode adds to it is a SECOND question it did not ask:
#    **can THIS LAYER hold the control, or only express it?** A hook can express a filesystem property
#    it cannot evaluate, and expressing it reads exactly like enforcing it.
#
#    THE HOLE, MEASURED TWICE, THREE MONTHS APART BY DIFFERENT AUTHORS. `inventory-counts.test.sh`'s
#    assertion 3 recorded it first (round 4, in its own comment): *"a path prefix is a STRING prefix …
#    The prefix bounded the characters, not the directory."* It was measured again on #160, against a
#    live floor, with the entry `Bash(bash .scratch/*)` in force:
#
#      $ bash .scratch/../../tadeumendonca-io/VERSION
#      .scratch/../../tadeumendonca-io/VERSION: line 1: 0.1.193: command not found
#
#    No prompt, no denial. `bash` opened and executed a file in ANOTHER REPOSITORY; exit 127 is bash
#    choking on the contents, and the permission decision was ALLOW. `.scratch/` was not a boundary,
#    it was a PASSWORD — a required prefix token, after which any path on disk is reachable.
#
#    WHY THE RULE IS NOT "FORBID THE WILDCARD". That was the previous answer and it is a real one; it
#    is written out in `inventory-counts.test.sh`, in the comment above its shell-wildcard assertion,
#    which also says a future need "should arrive as a deliberate change to THIS assertion, reviewed,
#    rather than as a quiet line in the floor." (The line locator this cited, `:461-464`, was stale and
#    pointed at unrelated code; replaced 2026-08-19, #283 slice 1, per `documentation-standard`'s
#    "cite the clause, not the line".)
#    This is that change. Forbidding the wildcard restores the friction the scratch work exists to
#    remove — one frozen absolute path per probe, and agents generate distinct paths.
#
#    ~~So the trade taken here is to keep the wildcard and make the DIRECTORY real, which only a hook
#    can do.~~ **STRUCK the same day.** A hook cannot do it either — see the three escape classes above.
#    THE TRADE ACTUALLY TAKEN (owner, 2026-08-07, option A) is to keep the wildcard and **record what it
#    is**: `bash <any path on disk>`. The honesty lives in the RECORD, not in a mechanism, because no
#    mechanism available at this layer delivers it. A floor that says what it does is worth more than a
#    floor that claims a bound and has none — which is the state this PR was opened in.
#
#    WHAT IT DOES NOT BUY, stated because the opposite reading is the dangerous one. The floor grants
#    uninspected execution through more entries than anyone has enumerated — `Bash(command:*)` alone
#    restores `perl` and `ruby` after both were removed by name — so anything this rule denies in a
#    shell spelling remains reachable one interpreter over. This rule does not narrow the agent's REACH
#    by a single act. ~~It narrows what ONE ENTRY CLAIMS.~~ **It does not do that either** — the entry's
#    claim is fixed by the record, above. That gap is ADR-0004's priced, accepted one; it is not closed
#    as closed.
#
#    Reads `$cmd`, not `$bare`: `$bare` collapses quoted spans, so `bash '.scratch/../x'` would arrive
#    as `bash ''` and walk through. Quoting must not be a spelling that exempts.
#    ── THE FALSE DENY, AND WHY THE FIRST VERSION HAD IT ──
#    Shipped as TWO INDEPENDENT greps over the whole string with NO POSITIONAL RELATION: "a shell name
#    appears somewhere" AND "a `..` appears somewhere". Measured by the gate at round 3:
#
#      grep -rn bash ../tadeumendonca-io/hooks    DENY   <- `bash` is a SEARCH TERM. No shell invoked.
#      grep -rn bashx ../tadeumendonca-io/hooks   ALLOW  <- one character apart, proving the cause
#      bash .scratch/probe.sh --repo ../other     DENY   <- the `..` is in an ARGUMENT, not the path
#
#    And the deny message described a match that had not happened. A hard deny on ordinary work is
#    worse than the hole it failed to close: the hole costs nothing today, this wedged the loop.
#
#    Twenty-two cases covered this rule and NOT ONE put the shell name in argument position. The table
#    was written by whoever wrote the pattern, which is the miss this file already records twice under
#    assertion 3 — a table samples the spellings its author had in mind.
#
#    NOW POSITIONAL: find the shell in COMMAND position (first word, or after a known wrapper), then
#    check ONLY THE FIRST NON-FLAG TOKEN AFTER IT. That token is the script path and nothing else is.
script_arg="$(printf '%s' "$cmd" | awk '
  function base(p) { sub(/^.*\//, "", p); return p }
  BEGIN { seen = 0 }
  {
    for (i = 1; i <= NF; i++) {
      w = $i
      if (seen) { if (substr(w, 1, 1) != "-") { print w; exit } ; continue }
      b = base(w)
      if (b == "bash" || b == "sh" || b == "zsh" || b == "ksh" || b == "dash") { seen = 1; continue }
      # wrappers that may legitimately precede the interpreter; anything else means the shell name is
      # an ARGUMENT to some other tool and this rule has no business firing.
      if (b == "env" || b == "exec" || b == "command" || b == "busybox" || b == "nohup" || b == "time") continue
      if (substr(w, 1, 1) == "-") continue
      if (w ~ /^[A-Za-z_][A-Za-z0-9_]*=/) continue
      exit
    }
  }')"
if [ -n "$script_arg" ] \
   && printf '%s' "$script_arg" | grep -Eq '(^|/|'"'"'|")\.\.(/|'"'"'|"|$)'; then
  deny "Blocked: a script path handed to a shell contains a '..' segment. A path in an allow entry is a STRING prefix, not a directory scope — '<allowed-prefix>/../../x.sh' carries the prefix while reaching any file on disk, and permission-guard.sh deliberately does not look inside a script. Use the path without traversal, or run the script from the directory that owns it."
fi

# 10. ADMITTING AN ITEM INTO AN ITERATION (#365). The owner's rule, 2026-08-30, verbatim:
#
#       "itens nao podem ser criados dentro do sprint automaticamente sem verificacao HITL"
#
#     THE ACT THIS GUARDS IS NOT "AN ISSUE EXISTS" — it is "an issue carries a milestone", which is
#     what changes a running iteration's contents and its completion bar. Those are different commands
#     and only the second is this rule's business. `gh issue create` with no `--milestone` is untouched
#     here and stays governed by 5c/5d alone.
#
#     WHY THIS LAYER, AND WHY THERE IS NO OTHER CANDIDATE. ADR-0004's standing question is which layer
#     can carry a control. Measured 2026-08-30: `Bash(gh issue edit:*)` sits in BOTH the project floor
#     and the global one, unscoped by caller, and this file carried no rule about it — so every persona
#     and the orchestrator could assign any milestone to any issue with no decision from any layer. It
#     cannot be expressed statically either: allow/deny entries are command PREFIXES and the issue
#     number sits between `edit` and `--milestone`, so no prefix reaches the flag. One candidate, not a
#     trade — which is rare enough in this file to be worth writing down.
#
#     TWO VERDICTS, SPLIT ON `agent_type`, AND THE SPLIT IS THE SAFETY PROPERTY RATHER THAN A NICETY:
#
#       A SUBAGENT IS DENIED. Composition is the owner's act at planning; no persona in the roster has
#       any business assigning a milestone, so there is no legitimate call to prompt about. And an
#       `ask` returned to a subagent reaches nobody — there is no prompt surface in a dispatched
#       context — so asking there would trade a deterministic refusal for an unmeasured behaviour on a
#       call that should be refused anyway. Deny is both the correct answer AND the one with no
#       unknown in it.
#
#       THE ORCHESTRATOR IS ASKED. That is the session the owner is sitting in, so the prompt reaches
#       a person and his answer is the HITL verification the rule demands. This is the whole reason
#       the rule is prevention rather than the `Stop`-hook detection its Issue expected: the wall that
#       stopped #337, #339 and #363 — a guard cannot tell "he told me" from "I did it myself" — does
#       not apply when the guard is allowed to ASK instead of having to KNOW.
#
#     PLACED LAST, AFTER EVERY DENY, AND THAT POSITION IS LOAD-BEARING. `ask` exits, exactly as `deny`
#     does. Sited next to rule 5c it would have exited BEFORE rules 7, 7b, 8 and 9, so
#     `gh issue edit 5 --milestone x && git push origin main` would have come out ASK where rule 8
#     denies it — an ask that SOFTENS a deny is a hole, not a prompt. This is the same "falling
#     through is the only safe shape" lesson rule 5d already memorialises, and the cheapest way to
#     obey it is to be the last rule in the file rather than to remember. Nothing may be appended
#     below this block that denies.
#
#     WHAT IT DOES NOT CATCH, so nobody reads it as a bound. `gh api` would reach the same endpoint
#     and is denied for writes by 5f, so that route is closed by a different rule and not by this one.
#     The GitHub web UI is outside every layer here — which is correct rather than a gap, since a
#     human clicking in a browser IS the verification. And the rule reads a flag, not an intent: an
#     owner-directed admission and a self-directed one produce the same prompt, which is precisely
#     why the prompt exists.
#
#     `--remove-milestone` IS DELIBERATELY NOT MATCHED. Removing an item from a running iteration is
#     the corrective act the owner performed by hand on #357 — it is what the rule wants to be easy,
#     not what it guards. It also does not match by accident: the pattern requires `--milestone`
#     preceded by start-or-space, and `--remove-milestone` contains no such substring.
if printf '%s' "$bare" | grep -Eq '(^|[^[:alnum:]_])gh([[:space:]]+(-R[[:space:]=]*|--repo[[:space:]=]*)[^[:space:]]+)?[[:space:]]+issue[[:space:]]+(create|edit)([[:space:]]|$)' \
   && printf '%s' "$bare" | grep -Eq '(^|[[:space:]])(--milestone|-m)([[:space:]=]|$)'; then
  if [ -n "$agent_type" ]; then
    deny "Blocked: a subagent does not admit an item into an iteration. Composing an iteration is the owner's act at planning (#365) — file or edit the issue without --milestone and say in your return which iteration you believe it belongs to, so he assigns it."
  fi
  ask "This assigns an iteration (--milestone), which changes what the running iteration contains. The owner's rule is that nothing enters it without human verification (#365), and answering this prompt IS that verification. Approve if he asked for this admission; refuse and file without a milestone if you are composing on your own."
fi

exit 0
