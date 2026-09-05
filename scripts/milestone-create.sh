#!/usr/bin/env bash
# milestone-create.sh — the ONE sanctioned route for creating an iteration's milestone (#375).
#
# THIS IS NOT A HOOK, AND IT IS NOT IN `hooks/scripts/` FOR A REASON. Nothing registers it in
# `hooks/hooks.json`; it is a repo utility a human's session runs during `/sprint-planning`. Putting it
# under `hooks/scripts/` would additionally trip the `purpose:` gate (#313), which reads any `*.sh`
# there declaring a `# purpose:` line as a mechanism that must be registered — so an unregistered script
# in that directory is either an orphan (red) or a mechanism pretending not to be one.
#
# ── READ THIS BEFORE YOU TRUST IT: THIS ROUTE WORKS BECAUSE A HOLE IS OPEN ──────────────────────
# It is an EXPLOITATION of a known gap, not a clean layer, and #375 requires that to be said in the
# artifact rather than only in a record. Measured against the live guard, not a stub:
#
#   gh api -X POST repos/o/r/milestones -f title=x        -> DENIED by permission-guard.sh rule 5f
#   python3 -c "…subprocess.run(['gh','api','-X','POST',…])"  -> ALLOWED, no decision from any layer
#   bash <a script that runs the same call>                -> ALLOWED, no decision from any layer
#
# **Neither the settings matcher nor `permission-guard.sh` looks inside a script.** The guard says so in
# its own words at the `..`-traversal rule: *"permission-guard.sh deliberately does not look inside a
# script."* That is the same blindness that makes the `python3 -c` spelling a back door. So rule 5f
# stops the CONVENIENT spelling of a raw-API write and not the AVAILABLE one, and **no document here may
# claim the raw-API route is closed.**
#
# WHAT MAKES THIS DEFENSIBLE ANYWAY, since it is a trade and not a fix: the widenable surface moves from
# a regex inside a hook to a REPO FILE that goes through review, the inventory gate and
# `quality-assurance`. A reviewed, named, single-purpose instance of an open hole beats an unreviewed
# general one. It is not "we found a clean layer".
#
# NO CHEAP MITIGATION EXISTS FOR THE HOLE ITSELF. Closing it means removing `python3:*` / `node:*` /
# `npx:*` from the allow lists, which breaks the loop's own tooling. The price of accepting it is this
# header.
#
# ── WHY THE ACT HAD NO ROUTE AT ALL ────────────────────────────────────────────────────────────
#   `gh milestone --help`  ->  unknown command "milestone" for "gh"
# So rule 5f's prescribed remedy — *"use the gh subcommand for the act instead, so the rule that owns it
# applies"* — is UNEXECUTABLE here. 5f was designed on the assumption that every act has an owning
# subcommand; milestone creation is the counterexample. And `Bash(gh api:*)` sits unqualified in the
# user-level floor's `deny`, in an UNTRACKED file nothing this plugin ships can change, so the precise
# fix — carving the milestones endpoint into 5f — would ship inert.
#
# ── WHY THIS PROMPTS — AND SINCE 2026-09-04 IT IS A GAP RATHER THAN A DECISION ─────────────────
# ~~`permission-guard.sh` rule 11 keys on this script's basename plus `agent_type`: a subagent is DENIED
# (no persona in the roster composes an iteration), the orchestrator is ASKED. That is rule 10's exact
# verdict split, for rule 10's exact reason — the owner's answer to the prompt IS the human verification
# #365 demands, and a dispatched context has no prompt surface for an `ask` to reach.
#
# Relying on the mere ABSENCE of an allow entry would have been the "absent is not a state" shape
# ADR-0004 already books for the AWS floor. The prompt is a decision by a rule, not a gap.~~
#
# **STRUCK 2026-09-04 (#383). RULES 10 AND 11 ARE DELETED**, on the owner's pricing of the act —
# «mexer em milestones nao é um risco crucial a iniciativa» — against the audit's criterion of
# IRREPARABLE. A milestone is deleted and an assignment is removed; nothing latches.
#
# **THIS SCRIPT STILL PROMPTS, AND THE STRUCK PARAGRAPH ABOVE IS NOW THE EXACT DESCRIPTION OF WHY THAT
# IS WRONG.** `scripts/` matches no `allow` entry in either settings layer, so the permission system
# asks — which is precisely the "absent is not a state" shape the old text was written to avoid relying
# on. **The prompt is now a gap, not a decision by a rule.** An allow entry added later for an
# unrelated reason removes the verification silently and nothing anywhere will say so.
#
# Read that as the standing state rather than as a risk: it is what the removal chose, knowingly.
#
# ── WHAT THIS DOES NOT DO ──────────────────────────────────────────────────────────────────────
# It does not close a milestone, does not assign one to an Issue (that is `gh issue edit --milestone`,
# ~~governed by rule 10~~ — governed by nothing since #383, and allowlisted, so it runs silently),
# does not read a milestone's state (no command available to this loop can — the
# `milestone` sub-object returned by `gh issue list --json milestone` carries four keys and no `state`),
# and does not compose an iteration. It creates one object and prints what the API returned.
#
# It also does not take a description INLINE any more. `--description <text>` is gone; the only route
# is `--description-file <path>`. The reason is at the option itself rather than here, because that is
# where someone re-adding the flag would be standing.
#
# ── AN UNSETTLED QUESTION THAT COULD MAKE THIS FILE UNNECESSARY ────────────────────────────────
# Whether `gh issue edit --milestone "<new title>"` CREATES a missing milestone is NOT measured. `--help`
# says "by name", which is a READ of documentation and not a measurement. ~~It could not be measured from
# the persona that wrote this file, because rule 10 denies every `gh issue edit --milestone` to a
# subagent.~~ **Struck 2026-09-04 (#383): rule 10 is gone, so the obstacle to measuring this is gone
# with it — any persona can now settle it in one command.** If it turns out to create, this whole route
# is moot and should be deleted rather than kept.

set -euo pipefail

usage() {
  printf '%s\n' \
    'usage: bash scripts/milestone-create.sh <title> [--repo <owner>/<repo>] [--description-file <path>]' \
    '' \
    'Creates ONE milestone. The repo defaults to the one the current directory belongs to.' \
    'This is the only sanctioned milestone-creation route in this harness; see the header of' \
    'this file for why it exists and what hole it depends on.' \
    '' \
    'THE DESCRIPTION ARRIVES BY FILE AND HAS NO INLINE FORM. There is no --description <text>: it' \
    'was REMOVED rather than left beside the file route, so no caller can pick the hazard.' >&2
}

[ "$#" -ge 1 ] || { usage; exit 2; }

title=""
repo=""
description=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)        [ "$#" -ge 2 ] || { usage; exit 2; }; repo="$2"; shift 2 ;;
    # THE DESCRIPTION ARRIVES BY FILE, AND THE INLINE FORM IS GONE RATHER THAN DEPRECATED (#378).
    # This script shipped with `--description <text>` (#375) and `/sprint-planning` was written to
    # call it that way. Measured, one Bash call, the argument double-quoted exactly as that step
    # wrote it: a backtick inside it is EXECUTED, not eaten, and `$` expands the same way. The text
    # being composed is not trusted — both repositories are public (`gh repo view --json isPrivate`
    # -> false, twice), so the Issue titles the rite reads into that body are attacker-supplied. And
    # the corruption is unrecoverable from here: the description IS the order of record and no update
    # route is built, so a mangled one is a browser delete-and-recreate.
    #
    # KEEPING BOTH FLAGS WOULD HAVE FIXED THE CALLER AND NOT THE SCRIPT. A caller may always pick the
    # convenient spelling, and the next one will; the repo's own `/shell` rule is that --body-file has
    # NO per-case exception. So the inline form is deleted. `inventory-counts.test.sh` asserts its
    # ABSENCE, not merely the presence of the file route, because "unused" and "gone" are different
    # claims and only the second one is a control.
    --description-file)
                   [ "$#" -ge 2 ] || { usage; exit 2; }
                   [ -r "$2" ] || { printf 'description file not readable: %s\n' "$2" >&2; exit 2; }
                   description="$(cat -- "$2")"; shift 2 ;;
    -h|--help)     usage; exit 0 ;;
    -*)            printf 'unknown option: %s\n' "$1" >&2; usage; exit 2 ;;
    *)             [ -z "$title" ] || { printf 'more than one title given\n' >&2; exit 2; }
                   title="$1"; shift ;;
  esac
done

[ -n "$title" ] || { usage; exit 2; }

command -v gh >/dev/null 2>&1 || {
  printf 'gh is not on PATH; this script has no other route to the API.\n' >&2
  exit 3
}

if [ -z "$repo" ]; then
  # `gh repo view` resolves the repo from the current directory's remote. It FAILS LOUDLY rather than
  # guessing: a script that reached the wrong repository would create an iteration nobody is working in,
  # and the milestone namespace is per-repo.
  repo="$(gh repo view --json nameWithOwner --jq '.nameWithOwner')" || {
    printf 'could not resolve a repository from this directory; pass --repo <owner>/<repo>.\n' >&2
    exit 3
  }
fi

# REFUSE A DUPLICATE TITLE, and this is the one check that is worth more than it looks. An iteration is
# ONE thing whose tracker representation is two milestones in two repositories paired by nothing but
# their title — `agents-configuration` names that as a live, undetected failure ("title one `sprint-01`
# and the other `sprint-1` and each derivation succeeds, each reports a healthy pool, and the iteration
# silently becomes two"). This does not fix that. It closes only the narrower case of creating a second
# milestone with a title this repository already has.
existing="$(gh api "repos/${repo}/milestones?state=all&per_page=100" --jq '.[].title' 2>/dev/null || true)"
if printf '%s\n' "$existing" | grep -qxF -- "$title"; then
  printf 'a milestone titled "%s" already exists in %s; refusing to create a second.\n' "$title" "$repo" >&2
  exit 4
fi

# THE WRITE. `-f` makes this a POST on its own, which is exactly what rule 5f matches and denies when the
# same string is typed at the shell. It reaches the API here only because no layer reads inside a script.
if [ -n "$description" ]; then
  gh api "repos/${repo}/milestones" -X POST -f "title=${title}" -f "description=${description}" \
    --jq '"created milestone #\(.number) \"\(.title)\" in '"${repo}"'"'
else
  gh api "repos/${repo}/milestones" -X POST -f "title=${title}" \
    --jq '"created milestone #\(.number) \"\(.title)\" in '"${repo}"'"'
fi
