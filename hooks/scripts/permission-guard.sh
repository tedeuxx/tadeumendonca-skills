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
bare="$(printf '%s' "$cmd" | sed -e "s/'[^']*'/''/g" -e 's/"[^"]*"/""/g')"

# 5c. OPENING WORK. Only the owner decides that something should exist; an agent that files it has
#     made that decision and merely asked for agreement afterwards. Enforced here because it is the one
#     step of that failure that is mechanically observable — "is this creating an issue" is visible in
#     the command, where "was this asked for" never is.
#
#     THE FAILURE THIS COMES FROM, measured rather than imagined: in one session the queue grew by 19
#     issues net, and roughly 13 of them were born inside a REVIEW of something else. The reviewer's own
#     Definition of Done said "adjacent debt filed as an Issue", so every finding became tracked work
#     nobody had decided to do. The queue stopped describing the product and started describing how hard
#     the agents had looked at it — and a drain that produces more than it consumes never ends.
#
#     NO ALLOWED SPELLING, deliberately. A flag or a phrase meaning "the owner asked for this" is a
#     claim the model can make about itself, and an exemption the model can invoke is not a boundary.
#     The owner opens the issue; the agent may still read, comment, label and close.
#
#     Matched semantically for the same reason as 5b: `gh -R <repo> issue create` must not slip past a
#     prefix that only knows `gh issue create`. And matched on `$bare`, AFTER quoted spans are collapsed —
#     the suite caught the first version denying `git commit -m 'gh issue create notes'`, which is a
#     message about the act, not the act.
if printf '%s' "$bare" | grep -Eq '(^|[^[:alnum:]_])gh([[:space:]]+(-R[[:space:]]*|--repo[[:space:]=]*)[^[:space:]]+)?[[:space:]]+issue[[:space:]]+create'; then
  deny "Blocked: only the owner opens work. Report the finding — in your verdict, in the PR, or to the human — and let them decide whether it becomes an issue. An agent that files it has already decided."
fi
# The API route to the same act. Rule 7b books its equivalent as an accepted gap; this one is matched
# instead, because the comment above claims there is no allowed spelling and a claim the code does not
# keep is the formality this whole rule exists to avoid.
#
# TWO THINGS THIS MATCHER GETS RIGHT THAT THE FIRST VERSION DID NOT, both found by review:
#   - It reads $cmd, NOT $bare. Everywhere else the collapse of quoted spans is what stops a commit
#     message being mistaken for the act; here the quotable argument IS the payload, so `gh api
#     "repos/o/r/issues"` collapsed to `gh api ""` and walked straight through.
#   - It requires a WRITE indicator. `/issues` alone denied `gh api repos/o/r/issues --paginate`, which
#     is a listing — contradicting this rule's own comment, the dev-loop section and ADR-0003's
#     ratified text, all three of which say reading stays open. Over-blocking a read is the same class
#     of error as under-blocking a write: the artifact stops describing what the code does.
if printf '%s' "$cmd" | grep -Eq '(^|[^[:alnum:]_])gh[[:space:]]+api([[:space:]]|.)*/issues([[:space:]"'"'"']|$)' \
   && printf '%s' "$cmd" | grep -Eq '(--method[[:space:]=]+POST|-X[[:space:]]*POST|(^|[[:space:]])-[fF][[:space:]]|--input[[:space:]=])'; then
  deny "Blocked: only the owner opens work. Report the finding — in your verdict, in the PR, or to the human — and let them decide whether it becomes an issue. An agent that files it has already decided."
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

# 7b. Merging a PR is the deploy — ADR-0004 makes it the critical-reviewer's act alone,
#     and this is where that stops being a promise the main agent must remember. The
#     harness stamps agent_type on a subagent's tool calls (`<plugin>:critical-reviewer`)
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
    *:critical-reviewer) : ;;  # the reviewer IS the merge gate — allow it through
    *) deny "Blocked: merging a PR is the deploy and the critical-reviewer's act, not the main agent's (ADR-0004). Route it through the critical-reviewer subagent — invoke it with the human's go, and it performs the merge (approve-and-merge the safe class, or after your ratification for the boundary class). agent_type='${agent_type:-<main agent>}'." ;;
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
