#!/usr/bin/env bash
# permission-guard.sh — PreToolUse(Bash) guard shipped by tadeumendonca-skills.
#
# Enforces the model-agnostic, IRREVERSIBLE "floor" centrally, so every consuming
# repo inherits the same protection without re-declaring it. This is defense in
# depth: it only blocks operations that are dangerous in ANY repo regardless of
# its branch model (the danger is irreversibility that escapes git, not "which
# branch"). Each repo's .claude/settings.json `deny` remains the hard backstop.
#
# Two classes live here that a prefix matcher provably cannot express, so leaving
# them to settings.json was the bug, not the design:
#   - Pushing to the trunk (rule 7). The same act wears many spellings —
#     `git push origin main`, `git -C <path> push`, `HEAD:main`, a bare `git push`
#     while HEAD is main. settings.json can only pattern-list them, which either
#     misses a form or over-blocks (it over-blocked: EVERY feature-branch push via
#     `git -C` was denied, so the agent hit a prompt for following its own
#     multi-repo convention). Resolving HEAD is semantic and catches all forms.
#   - Command composition (rule 8). Chains and substitutions defeat the matcher
#     itself, so the human is interrupted for tools that ARE allowlisted. Denying
#     with a reason turns that interruption into something the agent fixes alone.
#
# Still deliberately does NOT block edits or commits by branch context, so it is
# safe for both GitFlow (main=prod) and trunk-based (main=working) repos.
#
# Contract: receives the PreToolUse JSON on stdin; denies by printing a
# permissionDecision JSON and exiting 0. Fails OPEN (allows) on any parse error,
# because settings.json `deny` is the authoritative backstop and we never want to
# wedge the agent on a malformed payload.

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

# ~~For the class where the thing that makes an act right or wrong is NOT visible in the command, and
# the owner is the only one who can see it. `deny` would be a lie there — it says "never", when the
# truth is "not unless the owner agrees" — and a denial the owner has to work around by typing the
# command themselves has moved the work to them rather than protecting them from it.~~
#
# **THE `ask()` HELPER IS DELETED, 2026-08-03.** It had exactly one call site — rule 5d's prompt on a
# main-agent `gh issue create` — and that call is gone (see 5d for the reasoning). The paragraph above
# is kept struck rather than removed because its ARGUMENT is still correct and is what a future rule
# would re-derive: there is a real class of act whose rightness the command cannot show. What changed
# is that `gh issue create` from the MAIN AGENT turned out not to be in it, since the owner is already
# watching that call happen. A future rule that genuinely is in that class re-adds these ten lines
# deliberately; leaving a helper nothing calls would be a mechanism the file claims and does not run.

# Single-line, collapsed whitespace for matching.
cmd="$(printf '%s' "$command" | tr '\n\t' '  ')"

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
if printf '%s' "$cmd" | grep -Eq '(^|[^[:alnum:]_])gh([[:space:]]+(-R|--repo)[[:space:]]+[^[:space:]]+)?[[:space:]]+secret[[:space:]]+(set|delete|remove)'; then
  deny "Blocked: writing or deleting a repository secret. Secret values are set by the human, never by the agent."
fi

# 6. Clearly-destructive direct cloud mutations (cloud state escapes git).
if printf '%s' "$cmd" | grep -Eq 'aws[[:space:]]+[a-z0-9-]+[[:space:]]+(delete|terminate|deregister|destroy|remove|purge)-'; then
  deny "Blocked: destructive direct cloud mutation. Cloud state changes through the running app (staging) or the pipeline, never via direct aws CLI."
fi

# Quoted spans collapsed, so an operator inside a commit message or a grep
# pattern is never mistaken for shell composition or a refspec.
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
#     `gh_repo_flag` is DEFINED HERE, above its first use, and shared with 5e. It was 5e's local until
#     5f was placed in front of it, at which point 5e's definition sat below this line and `set -u`
#     would have expanded an unset variable into the pattern — a matcher that silently matches less,
#     which is the worst failure a deny rule has. Shared constants belong above the first rule that
#     reads them, not beside whichever rule happened to be written first.
gh_repo_flag='([[:space:]]+(-R[[:space:]]*|--repo[[:space:]=]*)[^[:space:]]+)?'
gh_api_write='(--method|-X)[[:space:]=]*(POST|PUT|PATCH|DELETE)|(-f|-F|--field|--raw-field|--input)([[:space:]=]|$)'
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
if printf '%s' "$bare" | grep -Eq "(^|[^[:alnum:]_])gh${gh_repo_flag}[[:space:]]+(pr[[:space:]]+comment|issue[[:space:]]+(comment|create))([[:space:]]|\$)"; then
  case "$agent_type" in
    *:product-lead)
      deny "Blocked: \`product-lead\` writes nothing to a public surface. It reads the private positioning layer (\`.brand/\`) and \`gh pr comment\`/\`gh issue comment\`/\`gh issue create\` publish to a public repo — a paraphrase of that material in a comment is not revertible by deleting the comment. This restores the capability boundary the merged-away \`marketing-lead\` had (no Bash at all); reading the queue (\`gh pr list\`, \`gh issue list\`, \`gh pr view\`) is untouched. Return the finding in your verdict — it still reaches the PR: \`quality-assurance\` quotes your verdict there VERBATIM under its own marker, and its criterion 10 is not satisfied until that text is on the PR (owner decision 2026-08-04, recorded in ADR-0006). Say in your return that the finding needs to reach the PR, and write it so it can be quoted as it stands. agent_type='${agent_type}'." ;;
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
if printf '%s' "$bare" | grep -Eq '(^|[^[:alnum:]_])gh([[:space:]]+(-R[[:space:]]*|--repo[[:space:]=]*)[^[:space:]]+)?[[:space:]]+issue[[:space:]]+create'; then
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
#     `gh pr merge` with an optional -R/--repo before `pr` (the rule-5b convention).
#     ~~Recorded residual (ADR-0004): a raw `gh api ... PUT .../merges` is NOT matched —
#     the natural command is gated; the API back door is an accepted, named gap~~ —
#     **closed 2026-08-04 by RULE 5f, in this file.** THIS matcher is unchanged and still
#     does not see `gh api`; 5f denies it separately, by detecting that the call WRITES
#     (`--method PUT`, `-X`, `-f`/`-F`, `--input`) rather than by parsing the endpoint.
#     The suite covers the merge spelling specifically. It briefly lived in the floor's
#     `deny` instead — see rule 5c's comment for why that was too broad and moved here.
if printf '%s' "$bare" | grep -Eq '(^|[^[:alnum:]_])gh([[:space:]]+(-R|--repo)[[:space:]]+[^[:space:]]+)*[[:space:]]+pr[[:space:]]+merge([[:space:]]|$)'; then
  case "$agent_type" in
    *:quality-assurance) : ;;  # the reviewer IS the merge gate — allow it through
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

exit 0
