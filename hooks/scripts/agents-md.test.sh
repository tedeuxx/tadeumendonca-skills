#!/usr/bin/env bash
# Asserts the five MECHANICAL properties of this repository's root brief, `AGENTS.md`: tracked; the
# WHOLE file under a byte budget set by the smallest measured consumer; no declared one-harness token;
# every repository-relative path it names exists; and no file that a harness would load INSTEAD of it
# is tracked.
#
# WHY THIS EXISTS. `AGENTS.md` is the only root brief since #562, read by every harness this repository
# serves. Codex reads its first 32,768 bytes and silently drops the rest; Kiro truncates at 50,000
# characters; Claude Code reads it whole, but only when no file of its own vendor's name loads. So a
# defect here is not cosmetic: a rule past the byte cap, or a shadowing file, removes rules from a
# harness with every other check green. Until #411 the file was UNTRACKED — invisible to every merge
# request, reviewer and gate.
#
# WHAT WAS TRIED AND REPLACED (#562). A first cut kept a long file with a budgeted, marker-delimited
# prefix and pinned the marker from both sides. The orchestrator replaced it with a whole-file budget
# and moved the reasoning to `docs/agents-md-record.md`: a prefix budget leaves the tail free to carry a
# rule that the smallest consumer never reads, and the marker pin was machinery to defend a boundary
# that a whole-file budget does not need.
#
# WHAT THIS SUITE CANNOT ASSERT, said here rather than left to be inferred from a green:
#
#   * THAT THE BRIEF IS TRUE. Nothing here compares the file with the repository it describes.
#   * THAT THE BRIEF IS NEUTRAL. Arm 3 greps a DECLARED LIST OF TOKENS. A sentence that describes one
#     harness's mechanism without naming it passes. The human test: WOULD THIS SENTENCE STILL BE TRUE
#     ON A HARNESS WITH NO HOOKS?
#   * THAT NO RULE LIVES ONLY IN THE RECORD. Moving reasoning out is the remedy arm 2 prescribes, and
#     whether a rule went with it is held by review.
#   * THAT THE BUDGET IS RIGHT FOR EVERY HARNESS. 32,768 bytes is the smallest MEASURED cap; any other
#     harness is unmeasured.
#   * AN UNTRACKED OR ANCESTOR SHADOW. Arm 5 sees tracked files only.
#
# ~~COPYABILITY IS DELIBERATE, AND WHAT IS COPIED IS THE BODY, NEVER THE FILE … the invariant a sync
# maintains between this file and its copy at `scripts/agents-md.test.sh` is that everything below the
# first column-zero `set -uo` line is byte-for-byte identical~~ — STRUCK 2026-10-11 (#562): since
# tadeumendonca-io#722 that sibling's checker declares its sync "broken on purpose, because that
# sibling is to be generated from the workstation repository", and the two bodies differ. There is no
# sync obligation left; a change here is a change to this repository's checker only.
set -uo pipefail

ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$ROOT" ]; then
  printf 'FAIL  cannot resolve a git root from %s; no arm ran\n' "$(dirname "${BASH_SOURCE[0]}")"
  exit 1
fi

BRIEF="AGENTS.md"
# BYTES, not characters, against the SMALLEST measured consumer, over the WHOLE file. Codex
# 0.155.0-alpha.16.3 reads the first 32,768 bytes of AGENTS.md (default project_doc_max_bytes, measured
# live on 2026-10-11 by the agents-lead lens on tadeumendonca-io#722, and again on this repository's
# brief under #562) and silently drops the rest; Kiro 1.0.437 truncates at 50,000 characters, looser on
# both counts. A rule past the cut does not exist for that reader, which is why the WHOLE file is
# budgeted rather than a prefix: a prefix budget leaves the tail free to carry a rule nobody reads. The
# LIMIT is lower than the cap so growth reddens BEFORE it truncates.
BUDGET=32768
LIMIT=30000
# Files that make one harness load THEM INSTEAD of AGENTS.md. Claude Code 2.1.296 reads AGENTS.md only
# as a fallback: each of these at the root, or in an ancestor directory, suppresses it entirely
# (measured 2026-10-11 on tadeumendonca-io#722 and the workstation repository's #154). Ancestors are
# outside any repository, so no arm here can see them — a named residual.
SHADOWS=('CLAUDE.md' '.claude/CLAUDE.md' 'CLAUDE.local.md')

fails=0
ok()  { printf 'PASS  %s\n' "$1"; }
bad() { printf 'FAIL  %s\n' "$1"; fails=$((fails + 1)); }

printf '\n== %s — the harness-neutral root brief ==\n\n' "$BRIEF"

# ── ARM 1 · TRACKED ─────────────────────────────────────────────────────────────────────────────────
# The precondition for every other arm and for review itself: a file git does not know about cannot
# appear in a diff, so nothing can review it and nothing can gate it.
if git -C "$ROOT" ls-files --error-unmatch "$BRIEF" >/dev/null 2>&1; then
  ok "arm 1 — $BRIEF is tracked in git"
else
  bad "arm 1 — $BRIEF is NOT tracked. An untracked brief is invisible to every merge request and to
      every gate, including the ones below, which cannot run against a file a CI checkout does not
      contain. Run: git add $BRIEF"
fi

# ── ARM 2 · THE WHOLE FILE UNDER BUDGET, IN BYTES, WITH HEADROOM ────────────────────────────────────
if [ ! -f "$ROOT/$BRIEF" ]; then
  bad "arm 2 — $ROOT/$BRIEF does not exist; the length assertion did NOT run"
else
  bytes="$(wc -c < "$ROOT/$BRIEF" | tr -d ' ')"
  if ! printf '%s' "$bytes" | grep -qE '^[0-9]+$'; then
    bad "arm 2 — could not measure $BRIEF; the length assertion did NOT run"
  elif [ "$bytes" -ge "$LIMIT" ]; then
    bad "arm 2 — $BRIEF is $bytes bytes, at or past the $LIMIT headroom limit (smallest consumer cap
      $BUDGET bytes, measured live on Codex, which reads that much and silently drops the rest). Move
      reasoning to docs/agents-md-record.md — never a rule — and do not raise the limit without
      re-measuring."
  else
    ok "arm 2 — $BRIEF is $bytes bytes, under the $LIMIT limit ($((LIMIT - bytes)) to spare; smallest consumer cap $BUDGET bytes)"
  fi
fi

# ── ARM 5 · NO FILE THAT A HARNESS WOULD LOAD INSTEAD OF THIS ONE IS TRACKED ────────────────────────
# Calibrated with a positive control: the same lookup must find the brief itself, or a broken lookup
# would report every shadow as absent.
if ! git -C "$ROOT" ls-files --error-unmatch "$BRIEF" >/dev/null 2>&1; then
  bad "arm 5 — the lookup cannot find $BRIEF itself, so an absent shadow would read as clean; did NOT run"
else
  shadowed=""
  for s in "${SHADOWS[@]}"; do
    git -C "$ROOT" ls-files --error-unmatch -- "$s" >/dev/null 2>&1 && shadowed="$shadowed $s"
  done
  if [ -n "$shadowed" ]; then
    bad "arm 5 — tracked:$shadowed. One harness loads such a file INSTEAD of $BRIEF, silently dropping
      this whole brief from its sessions. Fold its content into $BRIEF and delete it."
  else
    ok "arm 5 — none of ${SHADOWS[*]} is tracked (an untracked or ancestor-directory one is invisible here)"
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
# EACH FIXTURE IS THE BARE TOKEN, AND THAT IS LOAD-BEARING RATHER THAN TERSE. These were sentences
# EMBEDDING the token until this revision, and a sentence fixture leaves a second way to defeat the
# arm that is not a deletion: NARROW the alternative to the fixture's own text. Measured — with the
# fixture `the Codex harness`, narrowing the alternative `codex` to `the Codex harness` keeps the
# fixture matched, keeps it load-bearing, passes every arm, and stops catching the bare vendor token
# in the brief. Same for `agent_type` narrowed to `the agent_type field`. A bare fixture closes it:
# any narrowing of the alternative makes it stop matching its own fixture, so the calibration reddens.
FIXTURES_CI=(
  'claude'
  'codex'
)
FIXTURES_CS=(
  'PreToolUse'
  'SessionStart'
  'UserPromptSubmit'
  'SubagentStop'
  'PostToolUse'
  'hooks.json'
  'settings.json'
  'agent_type'
  '--dangerously-skip-permissions'
  '/plugin:'
  '/tadeumendonca-skills:'
  'slash command'
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
        printf '    so deleting that alternative would go unnoticed. Fix the PATTERN — one alternative\n'
        printf '    subsumes another — and do NOT lengthen the fixture past the bare token to escape\n'
        printf '    this, which trades a deletion hole for a narrowing one. See the fixture block.\n'
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
      bad "arm 3 — $BRIEF names a token specific to one harness. Every harness reads this file, so such a
      token is either an identifier that does not exist for its reader or a mechanism that does not run
      for it. Restate the sentence as an obligation, drop it, or move it to docs/agents-md-record.md:
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
