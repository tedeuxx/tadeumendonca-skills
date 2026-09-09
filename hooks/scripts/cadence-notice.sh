#!/usr/bin/env bash
# purpose: say at session start how long it has been since the loop's closing rites last landed an artifact, because their only other trigger is a boundary that has never fired and nobody is told when one is overdue
# cadence-notice.sh — SessionStart hook: the CLOCK trigger for the closing rites.
#
# ── WHAT IT IS, AND THE ONE SENTENCE IT MUST NOT BE READ PAST ────────────────────────────────────
#
# It is a NOTICE. It reports elapsed time and nothing else — it cannot run a rite, cannot refuse a
# prompt, cannot deny a tool call, and every exit path is success. Nothing obliges anyone to act on
# it. That is the class #383 deliberately KEPT when it dehydrated eight hooks that gated nothing, and
# it is the class the owner authorised: «Constrói o gatilho por relógio» (2026-09-09, #406).
#
# The honest comparison is CLOCK VERSUS NOTHING, not clock versus boundary. The rites' only other
# trigger is a drain reaching exhaustion of its entry snapshot, which by this loop's own test is an
# instruction rather than a mechanism — no layer here observes a snapshot going empty. Measured in
# this tree at the time of writing: two of the three rite artifact roots have never existed at all.
#
#   git log -1 --format=%cI -- docs/retrospective   -> 2026-08-31T11:26:12-03:00
#   git log -1 --format=%cI -- docs/planning        -> (empty)
#   git log -1 --format=%cI -- docs/iteration-sweep -> (empty)
#
# ── IT KEYS ON THE CLOCK AND NEVER ON THE POOL BEING EMPTY ───────────────────────────────────────
#
# This is a constraint the mode contract wrote down BEFORE this file existed, and it is the reason
# this hook makes no tracker call of any kind. CLAUDE.md's `loop-mode-contract` block states it:
# in one mode an empty active container is the terminal condition that hands off to the closing
# rites; in the other it means nothing whatever, and a rite fired on it would be firing on noise.
# A trigger keyed on emptiness makes the lighter mode silently inherit the other's trigger under a
# different name.
#
# ── IT DOES NOT READ THE MODE, AND THAT IS A FINDING RATHER THAN AN OMISSION ─────────────────────
#
# A clock that fires on elapsed time behaves identically in both modes, so it never has to ask which
# one is running. That matters beyond this file: the contract's untouchable list is backed by a
# measurement that NO registered hook reads any object a mode varies, and teaching a hook the mode is
# what would end it. This hook is registered and reads no mode, no label, no container and no queue.
#
# ── SCOPE: IT ACTS ONLY WHERE A RECORD DECLARES A CADENCE ────────────────────────────────────────
#
# hooks.json is plugin-level, so this file runs at session start in EVERY consuming repository. A
# hook that reported "no closing rite has ever landed here" in a repository that never runs the rites
# would be a false notice by construction. So the record file below is the scope signal: no record,
# no notice, silently. A consuming repository that wants a cadence ships its own record.
#
# ── THE OBSERVED SET IS DECLARED DATA, NOT HARD-CODED ────────────────────────────────────────────
#
# The rites are read out of the record rather than written here, for three reasons and a fourth that
# is a consequence rather than a driver:
#   1. the record has to exist anyway, to carry the interval;
#   2. the observed set is then reviewable in one place, in a diff, beside the interval it is used
#      with — rather than split between a hook and a document;
#   3. the rite set MOVES. The product sweep was added at #379; a carrier that needs editing when a
#      rite is added is a carrier that will go stale silently.
#   4. (consequence, stated because it must not be mistaken for reason 1) the contract publishes a
#      falsifier that greps the registered hooks for the strings `milestone|iteration|sprint` outside
#      comments and deny strings, and expects no output. That grep is a PROXY for the property "no
#      hook reads an object a mode varies"; it is not the property. This hook does not trip it,
#      because its rite names live in the record — but a future hook that names a rite in a code line
#      would trip it WITHOUT violating the property. That is a finding about the falsifier. The
#      sharper of the two published commands — the one selecting `--milestone`/`--label`/`--json …`
#      field names — targets the property directly and is the one to trust.
#
# ── WHAT IT CANNOT SEE, NAMED SO A SILENCE IS NOT READ AS A CLEAN BILL ───────────────────────────
#
#   * ONE ROOT. A hook receives one `cwd`, and a rite's artifacts do not all land in one repository:
#     the product sweep's report lands in the CONSUMING repository. A rite declared `sibling` in the
#     record is therefore reported as NOT OBSERVED rather than as never-run, and the notice names
#     both repositories. Sibling-tree discovery is deliberately not built — ADR-0004 already calls it
#     "a heuristic and the weakest part", and a detector that must guess where the other tree is in
#     order to read it is assuming what it checks.
#   * ONE SESSION LATE, by construction. It fires at session start, so a rite that became overdue
#     mid-session is reported at the next one. For a cadence that is correct behaviour.
#   * THE PARENT ONLY. A subagent never sees a SessionStart notice.
#   * AN ARTIFACT IS NOT A RITE. It reads the commit date of the paths a rite writes into. A rite
#     that ran and wrote nothing is invisible; a commit touching that path for an unrelated reason
#     resets the clock. It answers "when did an artifact of this rite last land", never "did the rite
#     run well" — which is the same bound `docs/retrospective/<…>/` already carries in its own words.
#
# ── THE INTERVAL IS NOT DECIDED HERE ─────────────────────────────────────────────────────────────
#
# The owner authorised the carrier and was NOT asked for the interval; it is not inferred. So the
# record ships with the value undeclared, and this hook REFUSES TO CONCLUDE rather than defaulting —
# the same rule the mode record already runs for an unrecognised mode value, and for the same reason:
# a default is inference by another route, and a carrier that silently picked a number would be
# reporting a verdict nobody decided. An undeclared interval produces a short notice naming the one
# line that would set it, once per day. `none` is an explicit, declared opt-out and is silent —
# which is the difference between a carrier the owner turned off and one that is quietly inert.
#
# Contract: prints SessionStart JSON carrying additionalContext, exits 0. Silent on every error —
# no jq, no git, not a repository, no record — because a session must always be able to start and an
# unavailable answer must never render as "nothing is overdue".

set -uo pipefail

command -v jq  >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

input="$(cat 2>/dev/null || true)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
[ -n "$cwd" ] || cwd="$PWD"
[ -d "$cwd" ] || exit 0

ROOT="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$ROOT" ] || exit 0

RECORD="$ROOT/docs/loop-cadence.md"
[ -r "$RECORD" ] || exit 0

# ── the record's parsing contract ────────────────────────────────────────────────────────────────
# Anchored at column 0, read literally, exactly as `invocable:`, `purpose:` and `loop-mode:` already
# are in this repository — and for the same measured reason: `# purpose:` once occurred at column 0
# as ordinary wrapped prose, so a declaration is a POSITION, not a token that appears somewhere.
declared="$(sed -nE 's/^cadence-interval-days:[[:space:]]*([^[:space:]]+).*$/\1/p' "$RECORD" | head -1)"

# `none` is a DECLARED opt-out and the only silent path that is not an error. Kept distinct from an
# absent line on purpose: absent means nobody has decided, `none` means somebody did.
[ "$declared" = "none" ] && exit 0

# One record line per rite: `cadence-rite: <artifact-path> <typed-command> here|sibling`.
rites="$(sed -nE 's/^cadence-rite:[[:space:]]+(.+)$/\1/p' "$RECORD")"
[ -n "$rites" ] || exit 0

# ── debounce: at most one notice per UTC day, per repository ─────────────────────────────────────
# A reminder nobody acts on is a nag, and the nag is the one that gets routed around. SessionStart
# fires on startup, resume, clear and compact, so "once per session" is not once per day.
#
# The durable home is `$git_dir/`, which `closure-artifact-guard.sh` already proves for exactly this:
# it survives across sessions, it is per-checkout, and it is not in the tracked tree, so a debounce
# marker can never arrive in a diff. Resolved through `rev-parse --git-dir` rather than assumed to be
# `$ROOT/.git`, because in a worktree it is a file pointing elsewhere.
git_dir="$(git -C "$ROOT" rev-parse --git-dir 2>/dev/null || true)"
[ -n "$git_dir" ] || exit 0
case "$git_dir" in /*) : ;; *) git_dir="$ROOT/$git_dir" ;; esac
debounce_dir="$git_dir/cadence-notice"
today="$(date -u +%Y-%m-%d 2>/dev/null || true)"
[ -n "$today" ] || exit 0
mkdir -p "$debounce_dir" 2>/dev/null || true
[ -f "$debounce_dir/$today" ] && exit 0

now="$(date -u +%s 2>/dev/null || true)"
case "$now" in ''|*[!0-9]*) exit 0 ;; esac

# ── read the clock off the artifacts ─────────────────────────────────────────────────────────────
# The commit date of the last commit touching a rite's artifact root. Chosen over a hook-written
# stamp because nothing can observe a rite RUNNING — a stamp this hook wrote would never advance and
# the notice would fire forever. A commit date advances exactly when a rite lands its artifact, it
# survives a fresh clone, and it needs no new state.
newest=""
observed=0
lines_here=""
lines_sibling=""

while IFS= read -r rite; do
  [ -z "$rite" ] && continue
  # shellcheck disable=SC2086
  set -- $rite
  [ "$#" -ge 3 ] || continue
  r_path="$1"; r_cmd="$2"; r_where="$3"

  if [ "$r_where" = "sibling" ]; then
    lines_sibling="$lines_sibling
  $r_cmd — artifact root $r_path, in the CONSUMING repository. Not observable from this tree."
    continue
  fi

  observed=$((observed + 1))
  ts="$(git -C "$ROOT" log -1 --format=%ct -- "$r_path" 2>/dev/null || true)"
  case "$ts" in
    ''|*[!0-9]*)
      lines_here="$lines_here
  $r_cmd — artifact root $r_path has NEVER been written in this tree."
      ;;
    *)
      days=$(( (now - ts) / 86400 ))
      lines_here="$lines_here
  $r_cmd — artifact root $r_path last written ${days}d ago."
      [ -z "$newest" ] && newest="$ts"
      [ "$ts" -gt "$newest" ] && newest="$ts"
      ;;
  esac
done <<< "$rites"

[ "$observed" -gt 0 ] || exit 0

emit() {
  : > "$debounce_dir/$today" 2>/dev/null || true
  # Keep the marker directory bounded: today's file is the only one that decides anything, and a
  # directory that grows one file a day forever is state nobody prunes.
  find "$debounce_dir" -maxdepth 1 -type f ! -name "$today" -delete 2>/dev/null || true
  jq -n --arg c "$1" '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: $c
    }
  }'
  exit 0
}

# ── ARM 1: the interval is not declared ──────────────────────────────────────────────────────────
# It REFUSES TO CONCLUDE rather than defaulting. This arm is the reason the carrier is not silently
# inert: a registered hook that says nothing reads exactly like a hook that found nothing.
case "$declared" in
  ''|*[!0-9]*)
    emit "CADENCE CARRIER INSTALLED, INTERVAL NOT DECLARED — it is deciding nothing.

$RECORD carries no numeric 'cadence-interval-days:' line, so this hook has no threshold and does
not default to one. The owner authorised the carrier and was not asked for the interval; inventing
a number here would report a verdict nobody decided.

Elapsed time, reported without a verdict:$lines_here${lines_sibling:+
$lines_sibling}

To set it, one line at column 0 in $RECORD:
  cadence-interval-days: <n>       fire when the newest artifact above is n or more days old
  cadence-interval-days: none      a declared opt-out — this hook then stays silent

This is a NOTICE and never a control: nothing obliges anyone to act on it, and nothing here can run
a rite. Reported once per UTC day, so silence tomorrow is the debounce and not a repair."
    ;;
esac

interval="$declared"

# ── ARM 2: nothing has ever landed ───────────────────────────────────────────────────────────────
if [ -z "$newest" ]; then
  emit "NO CLOSING RITE HAS EVER LANDED AN ARTIFACT IN THIS TREE.

Declared interval: ${interval}d. There is no start date to measure from, which is a stronger
statement than 'overdue' and is why it is reported separately.
$lines_here${lines_sibling:+
$lines_sibling}

The rites' only other trigger is a drain reaching exhaustion of its entry snapshot, and no layer
here observes that — so the honest comparison for this notice is CLOCK VERSUS NOTHING, never clock
versus boundary.

This is a NOTICE and never a control. An artifact is not a rite: this reads commit dates, so a rite
that ran and wrote nothing is invisible to it. Reported once per UTC day."
fi

# ── ARM 3: the interval has elapsed ──────────────────────────────────────────────────────────────
elapsed_days=$(( (now - newest) / 86400 ))
if [ "$elapsed_days" -ge "$interval" ]; then
  emit "A CLOSING RITE IS OWED ON THE CLOCK — ${elapsed_days}d since the newest artifact, declared interval ${interval}d.
$lines_here${lines_sibling:+
$lines_sibling}

This fires on ELAPSED TIME and on nothing else. It does not read the loop mode, a container, a label
or the queue — deliberately, because an empty container is the terminal condition in one mode and
means nothing at all in the other, and a trigger keyed on emptiness would make the second silently
inherit the first's trigger under a different name.

This is a NOTICE and never a control: nothing obliges anyone to act on it, nothing here can run a
rite, and the session is not blocked. An artifact is not a rite — a rite that ran and wrote nothing
is invisible here, and a commit touching one of those paths for an unrelated reason resets the clock.
Reported once per UTC day, so silence tomorrow is the debounce and not a repair."
fi

exit 0
