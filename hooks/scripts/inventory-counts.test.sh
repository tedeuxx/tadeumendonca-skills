#!/usr/bin/env bash
# Tests that every INVENTORY COUNT published in README.md and CLAUDE.md matches what the repo
# actually contains.
#
# Why this exists: the README is the surface a forker meets first, and its pitch is concrete —
# "19 subagent personas", "73 skills", and a per-directory breakdown. Concreteness is the point;
# it is also the thing that rots. Adding one skill falsifies four numbers across two files, and
# nothing about adding a skill makes anyone open the README. A wrong count on the front door of a
# repo whose whole claim is "the code is the pitch" is worse than no count, because it is checkable
# and it fails the check.
#
# The alternative was to publish no numbers. That was rejected: vagueness is not accuracy, it is
# just unfalsifiable. This makes the claim cheap to keep true instead.
#
# WHAT IT DOES NOT COVER, said plainly so the green is not read as more than it is: it asserts the
# numbers, never the prose around them. A README describing the wrong thing in the right quantity
# passes this suite.
#
# Run: bash hooks/scripts/inventory-counts.test.sh

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
README="$ROOT/README.md"
CLAUDE="$ROOT/CLAUDE.md"

pass=0
fail=0

ok()   { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad()  { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }

# `grep -F` throughout: these are literal strings, and a count like "(1)" is a regex group.
# Asserting the literal as it is WRITTEN is the point — a number that is right in a form the file
# does not use would pass a looser check while the reader still sees the wrong one.
expect_in() {
  local file="$1" needle="$2" label="$3"
  if grep -qF -- "$needle" "$file"; then
    ok "$label — '$needle' present in $(basename "$file")"
  else
    bad "$label — '$needle' NOT found in $(basename "$file"); the repo changed and the doc did not"
  fi
}

# --- personas -------------------------------------------------------------------------------
agents=$(find "$ROOT/agents" -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')
expect_in "$README" "$agents subagent personas" "agents/"

# --- skills, per directory and in total ------------------------------------------------------
# The root-level commands (autonomy-on.md) are counted SEPARATELY from the namespaced skills,
# because that is how both documents present them: "<N> skills + autonomy-on".
total=0
for dir in principles architecture backend frontend infrastructure workflow; do
  n=$(find "$ROOT/commands/$dir" -name '*.md' -type f | wc -l | tr -d ' ')
  total=$((total + n))
  expect_in "$README" "$dir ($n)" "commands/$dir"
  expect_in "$CLAUDE" "$dir/ ($n)" "commands/$dir"
done

expect_in "$README" "$total skills + autonomy-on" "commands/ total"

# The root command is named, not counted — if it is ever joined by a second one, "+ autonomy-on"
# stops being an accurate way to describe the remainder and this fails on purpose.
root_cmds=$(find "$ROOT/commands" -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')
if [ "$root_cmds" -eq 1 ]; then
  ok "commands/ root — exactly one un-namespaced command, so '+ autonomy-on' still describes it"
else
  bad "commands/ root — $root_cmds un-namespaced commands; the docs say '+ autonomy-on' as if there were one"
fi

# --- the career figure, which is why this file exists at all ----------------------------------
# README.md:3 carried "15+ years" while the CV published "18+", computed evergreen from the career
# start so it can never drift. A hardcoded second copy is exactly what went stale. The rule is that
# this repo does not restate the figure — the surface that COMPUTES it owns it.
# Deliberately wider than the literal string that went stale. Matching only `NN+ years` would pass
# "18 years", "two decades" and "since 2008" — three ways to restate the same figure and rot the same
# way. The rule is that this repo does not carry the number in any form, so the assertion is written
# against the rule rather than against the one phrasing that happened to be wrong.
if grep -qEi '[0-9]+\+? years|[a-z]+ decades?|since (19|20)[0-9]{2}' "$README"; then
  bad "career figure — README states a career duration; that figure is owned by the CV, which computes it"
else
  ok "career figure — README restates no career duration, in any of its forms, so it cannot go stale"
fi

# --- the practice's name ----------------------------------------------------------------------
# THIS is the claim that actually drifted, and the reason the numbers above are not enough. The site
# propagated `Loop Engineering` → `Harness Engineering` across five surfaces on 2026-07-31 and this
# repo was not one of them — so for a day it was the only public surface still publishing the retired
# term, while asserting it was the central identity term. Numbers were pinned; the vocabulary was not.
#
# The pattern is borrowed from the sibling repo's og-copy.test.mjs, which pins the same pair in the
# same both-directions shape: the current term present, the retired one absent. Absence is the half
# that matters — a doc can gain the new name and keep the old one three paragraphs down.
for doc in "$README" "$CLAUDE" "$ROOT/PRINCIPLES.md" "$ROOT/commands/principles/loop-engineering.md"; do
  name=$(basename "$doc")
  if grep -qF -- 'Harness Engineering' "$doc"; then
    ok "vocabulary — $name names the practice"
  else
    bad "vocabulary — $name does not name the practice; the term is fixed by the positioning record"
  fi
  if grep -qF -- 'Loop Engineering' "$doc"; then
    bad "vocabulary — $name still carries the RETIRED term; supersede it, do not add alongside"
  else
    ok "vocabulary — $name is clear of the retired term"
  fi
done

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
