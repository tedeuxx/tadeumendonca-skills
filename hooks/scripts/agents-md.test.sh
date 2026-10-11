#!/usr/bin/env bash
# Asserts the six MECHANICAL properties of this repository's root brief, `AGENTS.md`, whose PART I —
# everything above the column-zero line `<!-- part-i:end -->` — is the harness-neutral, budgeted prefix.
#
# WHY THIS EXISTS. `AGENTS.md` is read as always-on steering by at least one agent harness that truncates
# it — measured against Kiro 1.0.437, whose bundle resolves `AGENTS.md` at the workspace root with
# `inclusion:"always"` and cuts it at 50,000 characters. Since #562 it is also the ONLY root brief: the
# harness-specific one was consolidated into it and deleted, so the file now carries labelled
# harness-specific parts BELOW the marker, and a truncating reader keeps the head. That is why arms
# 3-5 measure Part I and not the file: Part I is what such a reader actually gets. Until #411 the file
# was UNTRACKED in both repositories of this workspace — invisible to every merge request, every
# reviewer and every gate, while being a month stale and telling its reader it described a different
# product than it does.
#
# WHY A MARKER AND NOT A SECOND FILE. A second file is what #562 removed. A marker keeps one file and
# gives the gate a boundary it can find mechanically; arm 2 asserts the boundary exists exactly once,
# because without it arms 3-5 would have no span to measure and would either measure the whole file
# (and redden on every harness-specific line below it) or measure nothing (and pass vacuously).
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
#   * THAT PART I IS NEUTRAL. Arm 4 greps a DECLARED LIST OF TOKENS. Neutrality is a property of
#     meaning, and a sentence that describes one harness's mechanism without naming it — "the guard
#     denies this", "the session hook injects that" — is exactly as harness-bound as one that does,
#     and passes. The test that catches it is a human one: WOULD THIS SENTENCE STILL BE TRUE ON A
#     HARNESS WITH NO HOOKS? If it is only true because something fires, it is not neutral.
#   * ANYTHING BELOW THE MARKER. Parts II-IV name one harness's machinery by design and quote deleted
#     paths inside struck text, so no token or path arm runs on them.
#   * THAT THE BUDGET IS RIGHT FOR EVERY HARNESS. 32,768 bytes is the smallest MEASURED cap (Codex,
#     live); 50,000 characters is Kiro's, read out of a shipped bundle. Claude Code was measured
#     loading the whole file. Any other harness is unmeasured, and this arm is not evidence about it.
#   * AN UNTRACKED OR ANCESTOR SHADOW. Arm 6 sees tracked files only.
#
# COPYABILITY IS DELIBERATE, AND WHAT IS COPIED IS THE BODY, NEVER THE FILE. This script derives its
# root from git rather than from its own position in the tree, so it runs unchanged from any depth in
# any repository that has an `AGENTS.md`. `tadeumendonca-io` is to carry the same artifact under the
# same rule, in its own merge request (`-io`#610) — stated as the rule rather than as that
# repository's current state, which is a claim this file cannot check and must not make. The invariant
# a sync maintains between this file and its copy at `scripts/agents-md.test.sh` is that everything
# below the first column-zero `set -uo` line is byte-for-byte identical — an obligation, not an
# assertion about either copy right now. The headers deliberately differ, because the duplication cost
# is a fact about that copy and has no subject here. So a sync copies the body, never the file.
# Falsifiable from a workspace holding both checkouts:
#
#   diff <(sed -n '/^set -uo/,$p' hooks/scripts/agents-md.test.sh) \
#        <(sed -n '/^set -uo/,$p' ../tadeumendonca-io/scripts/agents-md.test.sh)
#
# Nothing makes the two move together — a pipeline is independent per repository — so a change to the
# token list, the fixtures or the budget is a two-repository batch, and until the sibling's own merge
# request lands, that diff is expected to show the body changes made here.

set -uo pipefail

ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$ROOT" ]; then
  printf 'FAIL  cannot resolve a git root from %s; no arm ran\n' "$(dirname "${BASH_SOURCE[0]}")"
  exit 1
fi

BRIEF="AGENTS.md"
# Part I ends at the first line that is exactly this. Arm 2 pins WHERE it sits, not only that it exists.
MARKER='<!-- part-i:end -->'
# The first non-blank line after the marker must be exactly this heading...
PART2_HEADING='# Part II — Harness-neutral reference, beyond the budget'
# ...and every one of these must be a whole line ABOVE the marker and nowhere below it. Together they
# pin the marker from both sides: moving it UP strands a required section below it (and would exempt
# that section from arms 4 and 5); moving it DOWN puts the Part II heading, and everything after it,
# above it.
REQUIRED_H2=(
  '## The floor — obligations, not descriptions of enforcement'
  '## When you interrupt the owner — the form of an escalation'
  '## Standing rules for working this loop'
  '## What is checked'
)
# BYTES, not characters, against the SMALLEST measured consumer. Codex 0.155.0-alpha.16.3 reads the
# first 32,768 bytes of the file (default project_doc_max_bytes, measured live on 2026-10-11 by the
# agents-lead lens on tadeumendonca-io#722); Kiro 1.0.437 truncates at 50,000 characters, which is
# looser on both counts because a character is at least one byte. The LIMIT is deliberately lower so
# growth reddens BEFORE it truncates: a gate that fires at the cliff edge fires one merge too late.
BUDGET=32768
LIMIT=30000
# Files that make one harness load THEM INSTEAD of this one. Claude Code 2.1.296 reads AGENTS.md only
# as a fallback: a root CLAUDE.md, .claude/CLAUDE.md or CLAUDE.local.md each suppresses it entirely
# (measured 2026-10-11, tadeumendonca-io#722). An ancestor-directory CLAUDE.md does too, and is outside
# any repository, so no arm here can see it — a named residual.
SHADOWS=('CLAUDE.md' '.claude/CLAUDE.md' 'CLAUDE.local.md')

fails=0
ok()  { printf 'PASS  %s\n' "$1"; }
bad() { printf 'FAIL  %s\n' "$1"; fails=$((fails + 1)); }

printf '\n== %s — root brief, Part I harness-neutral ==\n\n' "$BRIEF"

# Part I is written to a temporary file so arms 3-5 read exactly the span a truncating harness keeps.
P1="$(mktemp 2>/dev/null || true)"
MUT="$(mktemp 2>/dev/null || true)"
cleanup() { [ -n "$P1" ] && rm -f "$P1"; [ -n "$MUT" ] && rm -f "$MUT"; }
trap cleanup EXIT

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

# ── ARM 2 · THE PART I MARKER OCCURS ONCE, AND SITS WHERE IT BELONGS ────────────────────────────────
# Existence is not enough. Measured on the sibling's fence (tadeumendonca-io#722): relocating an
# exemption boundary so that it exempts the whole floor left every arm green. Here the analogue is
# moving the marker UP, which would take rules out of arms 4 and 5. pin_problems prints one line per
# defect; silence means pinned. The arm then CALIBRATES itself: it moves the marker up to just after
# the title, and down to just after the Part II heading, in a temporary copy, and requires a defect
# report for each — so a pin that cannot fail reddens instead of passing.
pin_problems() {
  python3 - "$1" "$MARKER" "$PART2_HEADING" "${REQUIRED_H2[@]}" <<'PY'
import sys
path, marker, part2 = sys.argv[1], sys.argv[2], sys.argv[3]
required = sys.argv[4:]
lines = open(path, encoding="utf-8").read().split("\n")
idx = [i for i, l in enumerate(lines) if l == marker]
if len(idx) != 1:
    print("the marker line occurs %d time(s); it must occur exactly once" % len(idx)); sys.exit()
m = idx[0]
after = next((l for l in lines[m + 1:] if l.strip()), None)
if after != part2:
    print("the first non-blank line after the marker is %r, not the Part II heading" % after)
above, below = set(lines[:m]), set(lines[m + 1:])
for h in required:
    if h not in above:
        print("required section %r is not above the marker" % h)
    if h in below:
        print("required section %r also occurs below the marker" % h)
for l in lines[:m]:
    if l.startswith("# Part "):
        print("a part heading sits above the marker: %r" % l)
PY
}
p1_ready=0
if [ ! -f "$ROOT/$BRIEF" ]; then
  bad "arm 2 — $ROOT/$BRIEF does not exist; the marker assertion did NOT run"
elif [ -z "$P1" ] || [ -z "$MUT" ]; then
  bad "arm 2 — could not create a temporary file; arms 2-5 did NOT run"
elif ! command -v python3 >/dev/null 2>&1; then
  bad "arm 2 — python3 unavailable; arms 2-5 did NOT run"
else
  probs="$(pin_problems "$ROOT/$BRIEF")"
  # calibration: up (right after the title) and down (right after the Part II heading)
  cal=""
  awk -v m="$MARKER" 'NR == 1 { print; print m; next } $0 == m { next } { print }' "$ROOT/$BRIEF" > "$MUT"
  [ -n "$(pin_problems "$MUT")" ] || cal="$cal moving the marker UP to the title passes the pin;"
  awk -v m="$MARKER" -v h="$PART2_HEADING" '$0 == m { next } { print } $0 == h { print m }' "$ROOT/$BRIEF" > "$MUT"
  [ -n "$(pin_problems "$MUT")" ] || cal="$cal moving the marker DOWN past the Part II heading passes the pin;"
  if [ -n "$cal" ]; then
    bad "arm 2 — the marker pin is NOT calibrated:$cal it cannot fail, so arms 3-5 did NOT run."
  elif [ -n "$probs" ]; then
    bad "arm 2 — the Part I marker is missing, doubled or misplaced in $BRIEF. Arms 3-5 did NOT run:
$probs"
  else
    awk -v m="$MARKER" '$0 == m { exit } { print }' "$ROOT/$BRIEF" > "$P1"
    ok "arm 2 — $BRIEF carries the Part I marker once, after every required section and directly before Part II (pin calibrated: moved up and moved down both redden)"
    p1_ready=1
  fi
fi

# ── ARM 3 · PART I UNDER BUDGET, IN BYTES, WITH HEADROOM ────────────────────────────────────────────
if [ "$p1_ready" -ne 1 ]; then
  bad "arm 3 — no Part I to measure (see arm 2); the length assertion did NOT run"
else
  bytes="$(wc -c < "$P1" | tr -d ' ')"
  if ! printf '%s' "$bytes" | grep -qE '^[0-9]+$'; then
    bad "arm 3 — could not measure Part I of $BRIEF; the length assertion did NOT run"
  elif [ "$bytes" -ge "$LIMIT" ]; then
    bad "arm 3 — Part I of $BRIEF is $bytes bytes, at or past the $LIMIT headroom limit (smallest consumer
      cap $BUDGET bytes, measured live on Codex, which reads that much and drops the rest). Cut content,
      or move it below the marker if it is not a rule for every harness; do not raise the limit
      without re-measuring."
  else
    ok "arm 3 — Part I of $BRIEF is $bytes bytes, under the $LIMIT limit ($((LIMIT - bytes)) to spare; smallest consumer cap $BUDGET bytes)"
  fi
fi

# ── ARM 6 · NO FILE THAT A HARNESS WOULD LOAD INSTEAD OF THIS ONE IS TRACKED ────────────────────────
# Numbered 6 because arms 4 and 5 below predate it. Calibrated with a positive control: the same
# lookup must find the brief itself, or a broken lookup would report every shadow as absent.
if ! git -C "$ROOT" ls-files --error-unmatch "$BRIEF" >/dev/null 2>&1; then
  bad "arm 6 — the lookup cannot find $BRIEF itself, so an absent shadow would read as clean; did NOT run"
else
  shadowed=""
  for s in "${SHADOWS[@]}"; do
    git -C "$ROOT" ls-files --error-unmatch -- "$s" >/dev/null 2>&1 && shadowed="$shadowed $s"
  done
  if [ -n "$shadowed" ]; then
    bad "arm 6 — tracked:$shadowed. One harness loads such a file INSTEAD of $BRIEF, silently dropping
      this whole brief from its sessions. Fold its content into $BRIEF and delete it."
  else
    ok "arm 6 — none of ${SHADOWS[*]} is tracked (an untracked or ancestor-directory one is invisible here)"
  fi
fi

# ── ARM 4 · NO TOKENS SPECIFIC TO ONE HARNESS IN PART I ───────────────────────────────────────────────────────
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

if [ "$p1_ready" -ne 1 ]; then
  bad "arm 4 — no Part I to scan (see arm 2); the token assertion did NOT run"
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
    bad "arm 4 — the token patterns are NOT calibrated; this arm did not really run. Fix these before
      trusting any green from it:
$vac"
  else
    hits_ci="$(grep -niE "$TOKENS_CI" "$P1" || true)"
    hits_cs="$(grep -nE  "$TOKENS_CS" "$P1" || true)"
    hits="$(printf '%s\n%s' "$hits_ci" "$hits_cs" | grep -v '^$' || true)"
    if [ -n "$hits" ]; then
      bad "arm 4 — Part I of $BRIEF names a token specific to one harness. Part I is what a truncating
      harness keeps of this file, so such a token is either an identifier that does not exist for its
      reader or a mechanism that does not run for it. Restate the sentence as an obligation, drop it, or
      move it below the marker into the part labelled with that harness:
$hits"
    else
      ok "arm 4 — Part I of $BRIEF carries none of the declared harness-specific tokens"
    fi
  fi
fi

# ── ARM 5 · EVERY REPOSITORY-RELATIVE PATH PART I NAMES EXISTS ──────────────────────────────────────────
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
if [ "$p1_ready" -ne 1 ]; then
  bad "arm 5 — no Part I to scan (see arm 2); the path assertion did NOT run"
elif ! command -v python3 >/dev/null 2>&1; then
  bad "arm 5 — python3 unavailable; the path assertion did NOT run"
else
  cands="$(python3 - "$P1" <<'PY'
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
    bad "arm 5 — extracted ZERO path-shaped spans from Part I of $BRIEF. Either the brief names no paths at all,
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
      bad "arm 5 — Part I of $BRIEF names repository-relative path(s) that do not exist:$missing"
    else
      ok "arm 5 — all $n repository-relative paths named in Part I of $BRIEF exist"
    fi
  fi
fi

printf '\n'
if [ "$fails" -gt 0 ]; then
  printf '%d failure(s)\n\n' "$fails"
  exit 1
fi
printf 'all green\n\n'
