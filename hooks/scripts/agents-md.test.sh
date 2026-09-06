#!/usr/bin/env bash
# Asserts the four MECHANICAL properties of this repository's harness-neutral root brief, `AGENTS.md`.
#
# WHY THIS EXISTS. `AGENTS.md` is read as always-on steering by at least one agent harness that never
# reads this repository's other root brief — measured against Kiro 1.0.437, whose bundle resolves
# `AGENTS.md` at the workspace root with `inclusion:"always"` and contains zero references to the other
# filename. For that harness this file is not a courtesy copy; it is the ENTIRE brief. So a defect in
# it is not cosmetic, and until #411 the file was UNTRACKED in both repositories of this workspace —
# invisible to every merge request, every reviewer and every gate, while being a month stale and
# telling its reader it described a different product than it does.
#
# WHY THE CHECK IS SHAPED THIS WAY, AND WHAT WAS REJECTED. The obvious arm — "assert no untracked root
# brief shadows the tracked one" — CANNOT FAIL. This suite runs in CI on a fresh checkout, and a
# checkout contains only tracked files by construction, so the arm's subject is absent from the tree in
# every run, forever. An assertion whose positive result is unconditional, added to the very file whose
# job is to make drift visible, is this repository's own named recurring defect. TRACKING the file
# removes the hazard's precondition AND makes arm 1 below a check that can genuinely go red.
#
# WHAT THIS SUITE CANNOT ASSERT, said here rather than left to be inferred from a green:
#
#   * THAT THE BRIEF IS TRUE. Nothing here reads the repository and compares it to what the file
#     claims. A brief describing the wrong product in portable vocabulary passes every arm.
#   * THAT THE BRIEF IS NEUTRAL. Arm 3 greps a DECLARED LIST OF TOKENS. Neutrality is a property of
#     meaning, and a sentence that describes one harness's mechanism without naming it — "the guard
#     denies this", "the session hook injects that" — is exactly as harness-bound as one that does,
#     and passes. The test that catches it is a human one: WOULD THIS SENTENCE STILL BE TRUE ON A
#     HARNESS WITH NO HOOKS? If it is only true because something fires, it is not neutral.
#   * THAT THE BUDGET IS RIGHT. 50,000 is ONE consumer's measured floor, read out of a shipped bundle
#     on a machine where that tool has never authenticated. Every other harness's budget is unmeasured,
#     and this arm is not evidence that any of them is larger.
#
# COPYABILITY IS DELIBERATE. `tadeumendonca-io` carries the same artifact under the same rule and needs
# the same four arms. This script derives its root from git rather than from its own position in the
# tree, so it runs unchanged from any depth in any repository that has an `AGENTS.md`.

set -uo pipefail

ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$ROOT" ]; then
  printf 'FAIL  cannot resolve a git root from %s; no arm ran\n' "$(dirname "${BASH_SOURCE[0]}")"
  exit 1
fi

BRIEF="AGENTS.md"
# The budget is the consumer's measured cap; the LIMIT is deliberately lower so growth reddens BEFORE
# it truncates. A gate that fires exactly at the cliff edge tells you at the moment content is already
# being lost, which is one merge too late.
BUDGET=50000
LIMIT=45000

fails=0
ok()  { printf 'PASS  %s\n' "$1"; }
bad() { printf 'FAIL  %s\n' "$1"; fails=$((fails + 1)); }

printf '\n== %s — harness-neutral root brief ==\n\n' "$BRIEF"

# ── ARM 1 · TRACKED ─────────────────────────────────────────────────────────────────────────────────
# The precondition for every other arm and for review itself: a file git does not know about cannot
# appear in a diff, so nothing can review it and nothing can gate it.
if git -C "$ROOT" ls-files --error-unmatch "$BRIEF" >/dev/null 2>&1; then
  ok "arm 1 — $BRIEF is tracked in git"
else
  bad "arm 1 — $BRIEF is NOT tracked. An untracked brief is invisible to every merge request and to
      every gate, including the three below, which cannot run against a file a CI checkout does not
      contain. Run: git add $BRIEF"
fi

# ── ARM 2 · UNDER BUDGET, WITH HEADROOM ─────────────────────────────────────────────────────────────
# Characters, not bytes. The consumer slices a decoded string, so a multi-byte character costs one.
if [ ! -f "$ROOT/$BRIEF" ]; then
  bad "arm 2 — $ROOT/$BRIEF does not exist; the length assertion did NOT run"
elif ! command -v python3 >/dev/null 2>&1; then
  bad "arm 2 — python3 unavailable; the length assertion did NOT run"
else
  chars="$(python3 -c "import sys;print(len(open(sys.argv[1],encoding='utf-8').read()))" "$ROOT/$BRIEF" 2>/dev/null || true)"
  if ! printf '%s' "$chars" | grep -qE '^[0-9]+$'; then
    bad "arm 2 — could not measure $BRIEF; the length assertion did NOT run"
  elif [ "$chars" -ge "$LIMIT" ]; then
    bad "arm 2 — $BRIEF is $chars characters, at or past the $LIMIT headroom limit (consumer cap
      $BUDGET, measured on Kiro 1.0.437, which truncates the file, logs the loss on a debug channel,
      and appends a '[Truncated: …]' marker to the text the model reads — so the reader is told
      something went, never what). Cut content; do not raise the limit without re-measuring."
  else
    ok "arm 2 — $BRIEF is $chars characters, under the $LIMIT limit ($((LIMIT - chars)) to spare; consumer cap $BUDGET)"
  fi
fi

# ── ARM 3 · NO TOKENS SPECIFIC TO ONE HARNESS ───────────────────────────────────────────────────────
# The rejected alternative was to gate on the substitution that produced the old file — rewrite one
# vendor's name to another's. That is what created `.Codex-plugin/plugin.json` and three sibling
# identifiers that exist nowhere: a substitution renames the TOKEN and leaves the MECHANISM, so the
# brief goes on describing one harness's configuration under another harness's name. Gating on the
# token set instead forces the sentence to be rewritten as an obligation or dropped.
#
# Two lists, because the case rules differ. The first is matched case-INSENSITIVELY: a vendor name is
# wrong in every casing, including the shouted filename form. The second is matched case-SENSITIVELY,
# because these are exact identifiers and a lowercase English word of the same spelling is innocent.
TOKENS_CI='claude|codex'
TOKENS_CS='PreToolUse|SessionStart|UserPromptSubmit|SubagentStop|PostToolUse|hooks\.json|settings\.json|agent_type|--dangerously-skip-permissions|/plugin:|/tadeumendonca-skills:|slash.command'

# ONE FIXTURE PER DECLARED ALTERNATIVE, IN DECLARATION ORDER. The calibration below asserts that every
# alternative is LOAD-BEARING for its own fixture, which is what makes a deleted token reddenable.
#
# WHY NOT A SINGLE CONTROL LINE, which is what this arm carried until it was calibrated properly. The
# line was `Claude Code reads settings.json on PreToolUse`, and it exercised 3 of the 14 declared
# alternatives — so the other 11 could be deleted from the patterns with this arm green. Measured
# end to end: drop `codex` from TOKENS_CI, plant `This is a Codex plugin.` in the brief, and all four
# arms pass. That is the exact vendor token whose presence opened #411, undetected by the gate written
# to detect it. A guard that only ever confirms the tokens it happens to name is not a vacuity guard.
#
# WHY THIS MATTERS MORE HERE THAN IT WOULD ELSEWHERE: this checker is HAND-SYNCED across two
# repositories, and the characteristic failure of a hand-synced pair is a PARTIAL edit — a token added
# or removed on one side only. That is precisely the class a whole-pattern check is blind to, with both
# suites green.
#
# THE FIXTURES ARE ALIGNED BY INDEX with the alternatives, and the counts are asserted equal, so an
# alternative ADDED without a fixture reddens too. The split is on a literal `|`, which assumes the
# patterns use no grouped alternation `(a|b)`; if you ever add a group, this count breaks and you must
# rework the split rather than raise the count.
FIXTURES_CI=(
  'the Claude Code harness'
  'the Codex harness'
)
FIXTURES_CS=(
  'a PreToolUse matcher'
  'a SessionStart notice'
  'a UserPromptSubmit hook'
  'a SubagentStop event'
  'a PostToolUse event'
  'registered in hooks.json'
  'declared in settings.json'
  'the agent_type field'
  'the --dangerously-skip-permissions flag'
  'typed as /plugin:name'
  'typed as /tadeumendonca-skills:frontend'
  'a slash command file'
)
# The negative direction, because a pattern can rot by becoming too BROAD as well as too narrow: a
# degenerate `.` or `.*` matches every fixture, passes the calibration, and then reddens the brief for
# every line in it. This line must match NEITHER pattern.
NEGATIVE='a portable brief that names no vendor and no mechanism'

# Prints one alternative per line. Safe for these patterns because no alternative contains a literal
# pipe; see the grouped-alternation caveat above.
split_alts() { printf '%s' "$1" | tr '|' '\n'; }

# Joins every alternative EXCEPT index $2 (0-based) back into a pattern.
drop_alt() {
  printf '%s' "$1" | tr '|' '\n' | awk -v skip="$2" '
    NR-1 == skip { next } { out = (out == "" ? $0 : out "|" $0) } END { printf "%s", out }'
}

# Asserts each alternative of $1 is load-bearing for its own fixture. $3.. are the fixtures.
# Emits one diagnostic line per defect on stdout; silence means calibrated.
calibrate() {
  _pat="$1"; _flags="$2"; shift 2
  _n_alt=0
  while IFS= read -r _a; do _n_alt=$((_n_alt + 1)); done <<CAL_EOF
$(split_alts "$_pat")
CAL_EOF
  if [ "$_n_alt" -ne "$#" ]; then
    printf '  %d declared alternatives but %d fixtures — the arrays are misaligned, so at least one\n' "$_n_alt" "$#"
    printf '    alternative has no fixture and cannot be shown to be load-bearing.\n'
    return
  fi
  _i=0
  for _f in "$@"; do
    if ! printf '%s\n' "$_f" | grep -q$_flags -- "$_pat"; then
      printf '  fixture %d (%s) is NOT matched by the current pattern — the alternative it pins is\n' "$_i" "$_f"
      printf '    missing or mangled.\n'
    else
      _red="$(drop_alt "$_pat" "$_i")"
      if [ -n "$_red" ] && printf '%s\n' "$_f" | grep -q$_flags -- "$_red"; then
        printf '  fixture %d (%s) still matches with its own alternative removed — a sibling covers it,\n' "$_i" "$_f"
        printf '    so deleting that alternative would go unnoticed. Make the fixture more specific.\n'
      fi
    fi
    _i=$((_i + 1))
  done
}

if [ ! -f "$ROOT/$BRIEF" ]; then
  bad "arm 3 — $ROOT/$BRIEF does not exist; the token assertion did NOT run"
else
  # Vacuity guard for the arm itself, per alternative rather than per pattern. See the fixture block
  # above for why a single control line was not enough.
  vac="$(calibrate "$TOKENS_CI" iE "${FIXTURES_CI[@]}")
$(calibrate "$TOKENS_CS" E "${FIXTURES_CS[@]}")"
  for _neg_pat_flags in "$TOKENS_CI:iE" "$TOKENS_CS:E"; do
    _neg_pat="${_neg_pat_flags%:*}"; _neg_flags="${_neg_pat_flags##*:}"
    if printf '%s\n' "$NEGATIVE" | grep -q$_neg_flags -- "$_neg_pat"; then
      vac="$vac
  the negative control matches a pattern — it has become over-broad and would flag innocent prose."
    fi
  done
  vac="$(printf '%s' "$vac" | grep -v '^$' || true)"
  if [ -n "$vac" ]; then
    bad "arm 3 — the token patterns are NOT calibrated; this arm did not really run. Fix these before
      trusting any green from it:
$vac"
  else
    hits_ci="$(grep -niE "$TOKENS_CI" "$ROOT/$BRIEF" || true)"
    hits_cs="$(grep -nE  "$TOKENS_CS" "$ROOT/$BRIEF" || true)"
    hits="$(printf '%s\n%s' "$hits_ci" "$hits_cs" | grep -v '^$' || true)"
    if [ -n "$hits" ]; then
      bad "arm 3 — $BRIEF names a token specific to one harness. This file is another harness's ENTIRE
      brief, so such a token is either an identifier that does not exist for its reader or a mechanism
      that does not run for it. Restate the sentence as an obligation, or drop it:
$hits"
    else
      ok "arm 3 — $BRIEF carries none of the declared harness-specific tokens"
    fi
  fi
fi

# ── ARM 4 · EVERY REPOSITORY-RELATIVE PATH IT NAMES EXISTS ──────────────────────────────────────────
# This is the arm that catches a dangling pointer, which is how #411 was found: a substitution pass
# rewrote a nested brief's path in the sibling repository to a filename that does not exist, at a path
# the consuming harness genuinely scans. A brief that names an empty path is worse than one that names
# nothing — it sends its reader somewhere and the somewhere is not there.
#
# Selection is by SHAPE, stated so the next person can widen it deliberately: a backticked span made
# only of path characters, that either contains a slash or ends in a known source extension. A span
# carrying a placeholder bracket, a space, or a shell flag is not a path and is skipped. The arm
# therefore UNDER-checks by construction; it never over-checks, which is the direction that costs an
# author an argument with the gate over a sentence that was never wrong.
if [ ! -f "$ROOT/$BRIEF" ]; then
  bad "arm 4 — $ROOT/$BRIEF does not exist; the path assertion did NOT run"
elif ! command -v python3 >/dev/null 2>&1; then
  bad "arm 4 — python3 unavailable; the path assertion did NOT run"
else
  cands="$(python3 - "$ROOT/$BRIEF" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
EXT = (".md", ".sh", ".py", ".json", ".toml", ".yml", ".yaml", ".mjs", ".ts", ".tsx", ".tf")
# The delimiter is built from its code point rather than written literally: this block is a heredoc
# inside a command substitution, and bash parses a literal backtick there as nested substitution
# before python ever sees the file. Measured — it is a parse error, not a subtle one.
BT = chr(96)
out = []
for span in re.findall(BT + r"([^" + BT + r"\n]+)" + BT, text):
    if not re.fullmatch(r"[A-Za-z0-9._/-]+", span):
        continue
    if span.startswith("-"):
        continue
    if "/" not in span and not span.endswith(EXT):
        continue
    out.append(span.rstrip("/"))
for p in sorted(set(out)):
    print(p)
PY
)"
  if [ -z "$cands" ]; then
    bad "arm 4 — extracted ZERO path-shaped spans from $BRIEF. Either the brief names no paths at all,
      which makes it a map with no territory, or the extraction is broken. Either way this arm did not
      really run."
  else
    missing=""
    n=0
    while IFS= read -r p; do
      [ -z "$p" ] && continue
      n=$((n + 1))
      [ -e "$ROOT/$p" ] || missing="$missing
      $p"
    done <<EOF
$cands
EOF
    if [ -n "$missing" ]; then
      bad "arm 4 — $BRIEF names repository-relative path(s) that do not exist:$missing"
    else
      ok "arm 4 — all $n repository-relative paths named in $BRIEF exist"
    fi
  fi
fi

printf '\n'
if [ "$fails" -gt 0 ]; then
  printf '%d failure(s)\n\n' "$fails"
  exit 1
fi
printf 'all green\n\n'
