#!/usr/bin/env bash
# cadence-notice.test.sh — does the clock trigger fire when the interval has elapsed, stay silent
# when it has not, refuse to conclude when no interval is declared, and never block?
#
# Mutation-checked: every assertion below was verified to fail against a deliberately broken version
# of the HOOK — not of this file — because an assertion that cannot fail is worse than none, and
# editing the checker only proves the checker responds to being edited. The mutations run and the
# reds they produced are recorded in the pull request rather than here, where they would go stale.
#
# THE FIXTURE IS A REAL GIT REPOSITORY, and that is not incidental. The hook's clock is
# `git log -1 --format=%ct -- <path>`, so a fixture that stubbed git would be asserting the stub.
# Commit dates are set through GIT_AUTHOR_DATE/GIT_COMMITTER_DATE — `%ct` is the COMMITTER date, so
# setting only the author date produces a fixture whose ages are all zero and a suite that passes
# for the wrong reason.
#
# `gh` IS STUBBED TO A RECORDER RATHER THAN REMOVED, deliberately. Removing it from PATH would make
# "the hook makes no tracker call" pass vacuously — the same shape as a check whose pattern is dead.
# The recorder appends every invocation to a file, so the assertion reads a file that CAN be
# non-empty, and one case deliberately proves it can by invoking the stub directly.
#
# Run: bash hooks/scripts/cadence-notice.test.sh

set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/cadence-notice.sh"
pass=0
fail=0

ok()  { printf 'ok    %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL  %s\n     %s\n' "$1" "$2"; fail=$((fail + 1)); }

# Build a throwaway repository.
#   $1 — the literal record file body, or '' to write no record at all
#   $2 — age in days of a commit touching docs/retrospective, or '' to write none
setup() {
  root="$(mktemp -d)"
  repo="$root/repo"
  mkdir -p "$repo"
  git -C "$repo" init -q 2>/dev/null
  git -C "$repo" config user.email t@example.invalid
  git -C "$repo" config user.name  Tester
  mkdir -p "$repo/docs"
  printf 'seed\n' > "$repo/README.md"
  git -C "$repo" add -A >/dev/null 2>&1
  git -C "$repo" commit -q -m seed >/dev/null 2>&1

  if [ -n "${2:-}" ]; then
    mkdir -p "$repo/docs/retrospective/x"
    printf 'artifact\n' > "$repo/docs/retrospective/x/00-scope.md"
    git -C "$repo" add -A >/dev/null 2>&1
    when="$(date -u -v-"$2"d +'%Y-%m-%dT%H:%M:%S+0000' 2>/dev/null \
            || date -u -d "$2 days ago" +'%Y-%m-%dT%H:%M:%S+0000' 2>/dev/null)"
    GIT_AUTHOR_DATE="$when" GIT_COMMITTER_DATE="$when" \
      git -C "$repo" commit -q -m 'rite artifact' >/dev/null 2>&1
  fi

  if [ -n "${1:-}" ]; then
    printf '%s\n' "$1" > "$repo/docs/loop-cadence.md"
    git -C "$repo" add -A >/dev/null 2>&1
    git -C "$repo" commit -q -m record >/dev/null 2>&1
  fi

  # `gh` recorder — present on PATH, so "no tracker call" is a real observation.
  mkdir -p "$root/bin"
  printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/gh-calls"\n' "$root" > "$root/bin/gh"
  chmod +x "$root/bin/gh"
  : > "$root/gh-calls"
}

run_hook() {
  ( export PATH="$root/bin:$PATH"
    printf '{"hook_event_name":"SessionStart","cwd":"%s","session_id":"s1"}' "${1:-$repo}" \
      | bash "$HOOK" 2>/dev/null )
}

# EVERY ASSERTION READS ONE CAPTURED RUN, NEVER A FRESH ONE. The hook debounces to one notice per
# UTC day, so a second invocation against the same fixture is silent BY DESIGN — an `expect` helper
# that re-ran the hook per needle would report an empty second answer as a missing string, which is
# exactly the false red the first draft of this file produced. Capture once, assert many.
OUT=""
capture() { OUT="$(run_hook "${1:-}")"; }

has()     { case "$OUT" in *"$2"*) ok "$1" ;; *) bad "$1" "expected '$2'; got: ${OUT:-<empty>}" ;; esac; }
hasnt()   { case "$OUT" in *"$2"*) bad "$1" "expected NOT '$2'; got: $OUT" ;; *) ok "$1" ;; esac; }
isempty() { [ -z "$OUT" ] && ok "$1" || bad "$1" "expected no output; got: $OUT"; }

RITES='cadence-rite: docs/retrospective /sprint-retrospective here
cadence-rite: docs/iteration-sweep /sprint-review sibling'

# ── SCOPE ────────────────────────────────────────────────────────────────────────────────────────
# hooks.json is plugin-level, so this hook starts in every consuming repository. Silence where no
# record declares a cadence is the property that stops it reporting an overdue rite in a repository
# that has never run one.
setup '' 3
capture; isempty "scope — no record file, no notice"

setup "cadence-interval-days: 1
$RITES" ''
rm -f "$repo/docs/loop-cadence.md"
capture; isempty "scope — record deleted after the fact, no notice"

setup "cadence-interval-days: 1" 3
capture; isempty "scope — a record declaring no rite says nothing"

# THE SCOPE GUARD IS CHECKED ON STDERR, AND THAT IS THE ONLY WAY IT IS FALSIFIABLE. Measured while
# writing this suite: deleting `[ -r "$RECORD" ] || exit 0` from the hook leaves all three arms above
# GREEN, because a record-less repository also has no `cadence-rite:` line and exits at that check
# instead. The two conditions are behaviour-equivalent on stdout, so no stdout assertion can tell them
# apart — an assertion that cannot fail, found by mutating the hook rather than by reading it.
#
# What the guard actually buys is SILENCE ON STDERR: without it, `sed` runs against a file that is not
# there and writes "No such file or directory" at every session start in every consuming repository
# that installs this plugin. That is observable, so it is asserted.
setup '' 3
err="$( ( export PATH="$root/bin:$PATH"
          printf '{"hook_event_name":"SessionStart","cwd":"%s"}' "$repo" \
            | bash "$HOOK" 2>&1 >/dev/null ) )"
if [ -z "$err" ]; then
  ok "scope — a record-less repository produces nothing on stderr either"
else
  bad "scope — the hook wrote to stderr where no record exists" "$err"
fi

# ── THE DECLARED OPT-OUT ─────────────────────────────────────────────────────────────────────────
setup "cadence-interval-days: none
$RITES" 400
capture; isempty "opt-out — 'none' is silent even at 400d"

# ── ARM 1 · the interval is not declared ─────────────────────────────────────────────────────────
setup "cadence-interval-days:
$RITES" 3
capture
has   "arm 1 — an absent value refuses to conclude rather than defaulting" 'INTERVAL NOT DECLARED'
has   "arm 1 — it reports elapsed time without a verdict"                  'last written 3d ago'
hasnt "arm 1 — it never claims a rite is owed"                             'RITE IS OWED'
has   "arm 1 — it names the one line that would set the interval"          'cadence-interval-days: <n>'

setup "cadence-interval-days: soon
$RITES" 3
capture; has "arm 1 — a non-numeric value is refused, not coerced" 'INTERVAL NOT DECLARED'

# ── ARM 2 · nothing has ever landed ──────────────────────────────────────────────────────────────
setup "cadence-interval-days: 7
$RITES" ''
capture
has   "arm 2 — never-landed is reported as its own state" 'NO CLOSING RITE HAS EVER LANDED AN ARTIFACT'
hasnt "arm 2 — and not as an elapsed-days figure"         'since the newest artifact'

# ── ARM 3 · the interval has elapsed ─────────────────────────────────────────────────────────────
setup "cadence-interval-days: 7
$RITES" 30
capture
has "arm 3 — 30d against a 7d interval fires" 'CLOSING RITE IS OWED ON THE CLOCK'
has "arm 3 — the notice carries both figures" '30d since the newest artifact, declared interval 7d'

setup "cadence-interval-days: 7
$RITES" 3
capture; isempty "arm 3 — 3d against a 7d interval is silent"

setup "cadence-interval-days: 7
$RITES" 7
capture; has "arm 3 — the boundary is inclusive: 7d against 7d fires" 'CLOSING RITE IS OWED'

# ── THE SIBLING RITE IS NOT OBSERVABLE, AND SAYS SO ──────────────────────────────────────────────
# Reporting it as never-run would make the carrier lie in the direction of alarm about a repository
# it cannot see.
setup "cadence-interval-days: 7
$RITES" 30
capture
has   "sibling — reported as not observable"        'Not observable from this tree'
hasnt "sibling — never reported as never-written"   'docs/iteration-sweep has NEVER'
has   "sibling — the consuming repository is named" 'CONSUMING repository'

# ── IT IS A NOTICE, AND SAYS SO IN EVERY ARM THAT SPEAKS ─────────────────────────────────────────
setup "cadence-interval-days: 7
$RITES" 30
capture; has "class — arm 3 states it is never a control" 'NOTICE and never a control'
setup "cadence-interval-days:
$RITES" 30
capture; has "class — arm 1 states it is never a control" 'NOTICE and never a control'

# ── IT READS NO TRACKER AND NO MODE ──────────────────────────────────────────────────────────────
# The contract's untouchable list rests on no registered hook reading an object a mode varies. This
# asserts it of THIS hook by observation rather than by reading it.
setup "cadence-interval-days: 7
$RITES" 30
out="$(run_hook)"
if [ -s "$root/gh-calls" ]; then
  bad "mode-blind — the hook invoked gh" "$(cat "$root/gh-calls")"
else
  # Calibration: the recorder CAN be non-empty, so the emptiness above is a real zero.
  ( export PATH="$root/bin:$PATH"; gh pr list >/dev/null 2>&1 )
  if [ -s "$root/gh-calls" ]; then
    ok "mode-blind — no tracker call was made (recorder proven live by a direct invocation)"
  else
    bad "mode-blind — the gh recorder never records" "the emptiness above proves nothing"
  fi
fi

setup "cadence-interval-days: 7
$RITES" 30
mkdir -p "$repo/docs"
printf 'loop-mode: kanban\n' > "$repo/docs/loop-mode.md"
capture; hasnt "mode-blind — the notice names no mode" 'kanban'

# ── THE DEBOUNCE ─────────────────────────────────────────────────────────────────────────────────
setup "cadence-interval-days: 7
$RITES" 30
first="$(run_hook)"
second="$(run_hook)"
if [ -n "$first" ] && [ -z "$second" ]; then
  ok "debounce — the second run on the same day is silent"
else
  bad "debounce — expected a notice then silence" "first=${first:0:40} second=${second:0:40}"
fi

# ── THE DEBOUNCE MARKER NEVER REACHES THE TRACKED TREE ───────────────────────────────────────────
setup "cadence-interval-days: 7
$RITES" 30
run_hook >/dev/null
dirty="$(git -C "$repo" status --porcelain 2>/dev/null)"
if [ -z "$dirty" ]; then
  ok "state — firing leaves the working tree clean; the marker lives under \$git_dir"
else
  bad "state — the hook dirtied the tree" "$dirty"
fi
if [ -d "$repo/.git/cadence-notice" ]; then
  ok "state — the marker directory is under \$git_dir"
else
  bad "state — no marker directory under .git/" "the debounce has no durable home"
fi

# ── SILENCE IS NOT AN ANSWER: A CASE THAT MUST NOT FIRE ──────────────────────────────────────────
setup "cadence-interval-days: 7
$RITES" 30
mkdir -p "$root/notarepo"
capture "$root/notarepo"
isempty "silence — a cwd outside any repository says nothing"

# ── THE OUTPUT IS THE SHAPE THE HARNESS READS, AND THE EXIT IS ALWAYS 0 ──────────────────────────
setup "cadence-interval-days: 7
$RITES" 30
out="$(run_hook)"
if printf '%s' "$out" | jq -e '.hookSpecificOutput.hookEventName == "SessionStart"' >/dev/null 2>&1; then
  ok "shape — the payload is SessionStart JSON carrying additionalContext"
else
  bad "shape — not the SessionStart payload shape" "${out:-<empty>}"
fi

setup "cadence-interval-days: 7
$RITES" 30
( export PATH="$root/bin:$PATH"
  printf '{"hook_event_name":"SessionStart","cwd":"%s"}' "$repo" | bash "$HOOK" >/dev/null 2>&1 )
[ "$?" -eq 0 ] && ok "never blocks — exit 0 when it fires" \
               || bad "never blocks — non-zero exit when it fires" "a SessionStart hook must not stop a session"

# THE `cd` IS NOT DECORATION, and leaving it out is a defect this suite shipped for one run. A payload
# with no `cwd` makes the hook fall back to `$PWD` — which, when the suite is run from a checkout of
# this repository, is THE REAL REPOSITORY, record and all. It ran there, and under one mutation
# (`debounce_dir` pointed at the work tree instead of `$git_dir`) it wrote a marker directory into the
# tracked tree, where `git status` found it. A suite must not touch the repository it is testing.
setup "cadence-interval-days: 7
$RITES" 30
mkdir -p "$root/notarepo"
( cd "$root/notarepo" && printf 'not json at all' | bash "$HOOK" >/dev/null 2>&1 )
[ "$?" -eq 0 ] && ok "never blocks — exit 0 on a malformed payload" \
               || bad "never blocks — non-zero exit on garbage input" "silence, not failure, is the contract"

( cd "$root/notarepo" && printf 'not json at all' | bash "$HOOK" 2>/dev/null )
out="$( cd "$root/notarepo" && printf 'not json at all' | bash "$HOOK" 2>/dev/null )"
[ -z "$out" ] && ok "fallback — a payload with no cwd falls back to \$PWD and says nothing outside a repository" \
              || bad "fallback — spoke from a \$PWD fallback outside any repository" "$out"

# THE SILENT-BUT-REACHED-THE-END PATH IS ITS OWN CASE, and it exists because a mutation found the gap.
# Every firing arm exits from inside `emit`, and every guard exits early, so the script's LAST line is
# reached only when the interval is declared and has NOT elapsed. Replacing that final `exit 0` with
# `exit 1` left all thirty assertions green until this one was added — a line no test covered, in the
# one file whose whole contract is "a session must always be able to start".
setup "cadence-interval-days: 7
$RITES" 3
( export PATH="$root/bin:$PATH"
  printf '{"hook_event_name":"SessionStart","cwd":"%s"}' "$repo" | bash "$HOOK" >/dev/null 2>&1 )
[ "$?" -eq 0 ] && ok "never blocks — exit 0 on the silent path that runs to the end of the script" \
               || bad "never blocks — non-zero exit when there is nothing to report" \
                      "a hook that found nothing must not look like a hook that failed"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
