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
# (`<plugin>:<subagent>`) and leaves it empty for the main agent. The merge gate (rule 7b)
# reads this; the model cannot forge it — it is set by the harness, not the prompt.
agent_type="$(printf '%s' "$input" | jq -r '.agent_type // empty' 2>/dev/null || true)"

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
if printf '%s' "$cmd" | grep -Eq '(^|[^[:alnum:]_])rm[[:space:]]+(-[[:alnum:]]*r[[:alnum:]]*f|-[[:alnum:]]*f[[:alnum:]]*r)([[:space:]]|$|/)'; then
  deny "Blocked: 'rm -rf' is irreversible and escapes git. Remove specific tracked paths instead."
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
#         ~~Full stop.~~ **One exception since #124 — see 5d below:** `developer` may file a task under
#         a story that already carries `ready`. That is decomposing work the owner approved and three
#         leads ratified, not opening work; the parent is verified against the tracker rather than read
#         from the command, and every other subagent is denied exactly as this paragraph describes.
#       - THE MAIN AGENT ASKS. Alignment is a fact about a conversation, and the main loop is the only
#         place that conversation exists — so it is the only place the question can be put to the one
#         party who can answer it. One keystroke, on a prompt showing the title.
#
#     This answers the old comment's own objection — "an exemption the model can invoke is not a
#     boundary" — rather than ignoring it. It is right about `deny`: a flag meaning "the owner asked for
#     this" would be the model vouching for itself. It does not reach `ask`, because the model is not
#     the one deciding. The owner is, per issue, before anything is created.
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
#     ~~And a subagent still has none at all.~~ **False since #124.** `developer` has one — but it is
#     not a *spelling*, which is the whole point and the thing that took two rounds to get right: the
#     exception is satisfied by a fact in the TRACKER (a parent carrying `ready`), looked up, not by
#     anything the model can write. The first implementation was satisfiable by writing the command
#     differently, and that made it a convention rather than a floor. See 5d.
#
#     THE `gh api` ROUTE IS A NAMED ACCEPTED GAP — `gh api --method POST …/issues` is NOT matched, the
#     same way rule 7b books `gh api … PUT …/merges` for the higher-stakes act of merging. It was
#     matched for two rounds and each version was wrong: reading the collapsed command let a quoted URL
#     through; reading the raw command blocked `git commit -m "gh api …"`, a message ABOUT the act. The
#     honest statement is the gap, not a matcher that keeps failing to be what the comment claims —
#     which is precisely the defect this rule exists to remove.
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
    #       DECOMPOSING     is dividing work the owner already approved and three leads ratified.
    #
    #     A task under a `ready` story adds nothing: the story passed the owner and the three-lead
    #     referendum, and the task only makes visible what was already authorised. Denying it would
    #     tax the flow the model exists to create — the same inversion the 2026-07-31 correction
    #     found in this very rule, where a blanket denial taxed ALIGNED work and the owner paid.
    #
    #     THE PARENT IS VERIFIED, NEVER READ FROM THE COMMAND. That is the whole difference between
    #     an exception and a hole: a condition satisfied by writing the command differently is a
    #     convention, and this file spent the day removing conventions from the floor. So the `#N`
    #     is looked up — the story must EXIST and carry `ready`. A model that invents a parent
    #     invents one that fails the lookup.
    #
    #     FAILS CLOSED. No `gh`, no network, no answer → denied, exactly as before. A subagent that
    #     cannot prove the parent reports instead of creating blind. That is the opposite direction
    #     from `wip-guard`, deliberately: this rule is part of the floor, and a floor that fails
    #     open is not one.
    #     AND IT IS THE BUILDER'S EXCEPTION, NOT EVERY SUBAGENT'S. The first version of this rule
    #     let any subagent through on a ready parent, and the suite caught it: `quality-assurance`
    #     and `security` citing a story would have been reviews opening work, which is the rule the
    #     exception is supposed to preserve rather than erode. Decomposing is an act of EXECUTION,
    #     so it belongs to the one persona that executes.
    case "$agent_type" in
      *:developer) ;;
      *) deny "Blocked: a subagent does not open work. Decomposing a \`ready\` story into tasks is the one exception and it belongs to \`developer\`, the persona that executes them — a review citing a story is still a review opening work. Report the finding in your verdict and let the owner decide." ;;
    esac
    #     THE PARENT COMES FROM A DECLARED MARKER, and this is the correction that makes the
    #     rule mean what its comment claims. The first version took `#([0-9]+)` with a greedy
    #     `.*`, which captures the LAST number on the line — so a body reading
    #     `Parent: #99999 (does not exist). Unrelated context: #122` was ALLOWED, authorised by
    #     a passing mention of an unrelated ready story. That reduced 5d to "a developer may
    #     open anything, as long as it ends in a ready number", which is opening scope: the
    #     exact thing the exception exists to keep denied.
    #
    #     So: `Parent: #N` or `Parent #N`, FIRST match, and a second different `#N` after the
    #     marker denies. The number the guard checks is then the number a human reading the
    #     issue will see as its parent — which is the only version of "verified" worth the word.
    #     THE MARKER IS READ FROM WHATEVER BECOMES THE ISSUE BODY, and on this repo that is
    #     usually a FILE. Bodies longer than a line go through `--body-file`/`-F` by hard
    #     convention, because a shell eats backticks and `$` out of an inline `--body` — so a
    #     rule that reads the marker from the COMMAND breaks in both directions at once:
    #
    #       · a real decomposition task, whose body is multi-line markdown in a file, is DENIED —
    #         the exception refusing the normal shape of the one act it exists to permit;
    #       · and the pressure that creates has somewhere to go: putting `Parent: #122` in the
    #         FILENAME satisfied a command-only reader while the created issue contained no
    #         parent reference at all. Arbitrary scope opened, nothing in the issue recording
    #         what authorised it.
    #
    #     The second falsifies the standard three lines above — "the number a human reading the
    #     issue will see as its parent". With a body file, the human sees nothing. So the marker
    #     comes from the file when there is one, and a marker found ONLY in the command is not
    #     accepted while a body file is present.
    #
    #     Residual, named rather than fixed: reading the file is TOCTOU — the model could rewrite
    #     it between this check and the create. The window is its own and the act is deliberate,
    #     which puts it at the same trust level as the already-booked `gh api …/issues` gap.
    body_file="$(printf '%s' "$bare" | sed -nE 's/.*[[:space:]](--body-file[[:space:]=]*|-F[[:space:]]*)([^[:space:]]+).*/\2/p')"
    if [ -n "$body_file" ]; then
      body="$(cat "$body_file" 2>/dev/null || true)"
    else
      body="$cmd"
    fi
    #     Flattened, because a file body is multi-line and the marker may be anywhere in it.
    flat="$(printf '%s' "$body" | tr '\n\t' '  ')"

    #     FIRST match, genuinely this time. The previous version used a greedy `.*`, which takes
    #     the LAST marker while the comment claimed the first — the same comment-versus-code
    #     divergence this file keeps paying for. `awk match` returns the first occurrence, and
    #     the second-`#N` void is measured from the end of THAT match.
    parent="$(printf '%s' "$flat" | grep -oiE 'parent[[:space:]]*:?[[:space:]]*#[0-9]+' | head -1 | grep -oE '[0-9]+$' || true)"
    after="$(printf '%s' "$flat" | awk 'match($0, /[Pp][Aa][Rr][Ee][Nn][Tt][ ]*:?[ ]*#[0-9]+/) { print substr($0, RSTART + RLENGTH) }' || true)"
    trailing="$(printf '%s' "$after" | grep -oE '#[0-9]+' | head -1 || true)"
    if [ -n "$trailing" ] && [ "$trailing" != "#$parent" ]; then
      parent=""
    fi

    #     THE REPO COMES FROM `$bare`, NOT `$cmd`. Same reason rule 5c matches on `$bare`: with
    #     quoted spans still present, a greedy match takes the last `-R`-looking token ANYWHERE,
    #     including inside `--body` — text `gh` itself will never see as a flag. That let the
    #     issue be created in one repo while `ready` was verified in another, so a single ready
    #     story anywhere in the account authorised opening work everywhere. Reading `$bare`
    #     means only real flags are visible.
    if [ -n "$parent" ] && command -v gh >/dev/null 2>&1; then
      parent_repo="$(printf '%s' "$bare" | sed -nE 's/.*[[:space:]](-R[[:space:]]*|--repo[[:space:]=]*)([^[:space:]]+).*/\2/p')"
      if [ -n "$parent_repo" ]; then
        parent_labels="$(gh issue view "$parent" -R "$parent_repo" --json labels -q '.labels[].name' 2>/dev/null || true)"
      else
        parent_labels="$(gh issue view "$parent" --json labels -q '.labels[].name' 2>/dev/null || true)"
      fi
      if printf '%s\n' "$parent_labels" | grep -qx 'ready'; then
        #     A FLAG, NOT `exit 0`. The first version returned from the middle of the script —
        #     the first allow-path this rule had ever had — and everything below it stopped
        #     running: the trunk-push deny (7), the merge gate (7b) and the composition check
        #     (8). `gh issue create … && git push origin main` came out with NO decision at all,
        #     where before it was denied twice over. An exception in one rule silently became a
        #     bypass of the whole floor. Falling through is the only safe shape here.
        parent_ok=1
      fi
    fi
    [ -z "${parent_ok:-}" ] && deny "Blocked: a subagent does not open work. The ONE exception is decomposing an approved story: a body declaring \`Parent: #N\` where that issue exists and carries \`ready\`, in the repo this command targets. The parent is looked up, not read from your text, and a second unrelated issue number after the marker voids it. Everything else: report the finding — in your verdict, in the PR, or upward to the main loop — and let the owner decide whether it becomes an issue."
  fi
  # A verified decomposition skips the ASK and FALLS THROUGH to rules 7, 7b and 8 — it does not
  # return. Everything else still asks the owner, exactly as before.
  [ -z "${parent_ok:-}" ] && ask "Open this issue? The guard cannot see whether it is aligned with you — that is the whole question, and only you can answer it. Approve if this is work you asked for or agreed to; decline if the agent generated it for itself."
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
#     Recorded residual (ADR-0004): a raw `gh api ... PUT .../merges` is NOT matched —
#     the natural command is gated; the API back door is an accepted, named gap, not a
#     brittle attempt to pattern every form.
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
