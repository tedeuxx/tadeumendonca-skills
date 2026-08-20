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
# WHAT IT DOES NOT COVER, said plainly so the green is not read as more than it is:
#
#   - It asserts the numbers, never the prose around them. A README describing the wrong thing in the
#     right quantity passes. NARROWED 2026-08-04 and only for the roster: `security` was swapped for
#     `harness-lead` in one slice, the count held at five, and every assertion in this file stayed
#     green through it. The "roster's MEMBERSHIP" block below now checks WHICH personas are named, not
#     just how many exist. It is the only inventory here with that property — the skill and hook
#     inventories are still counts plus a name list, and nothing checks membership of a family.
#   - CLAUDE.md ALSO publishes "18 subagents" enabled and "26 defined". Those are counts of the ROSTER
#     as ADR-0002 defines it in the consuming repo — not of this tree — so nothing here can derive
#     them and nothing here asserts them. The per-FAMILY skill counts are checked in both files;
#     the persona count is checked only where it describes `agents/`. Said explicitly because "the
#     counts are pinned" would otherwise be read as covering those two.
#
# ── THE CHAINING RULE — read this before adding an arm ANYWHERE in this file ────────────────────────
#
# Chain conditions with `elif` ONLY where the failing condition makes the next verdict genuinely
# UNCOMPUTABLE — an extraction that returned nothing cannot be judged, so it is a GUARD. Never chain
# two ASSERTIONS merely because they share a subject heading: the first one's `bad` returns, and the
# second emits neither `PASS` nor `FAIL`. The assertion does not fail — it DISAPPEARS, while the totals
# stay plausible, which is why no count will ever surface it. Give each assertion its own `if`, and
# repeat the vacuity guard in each rather than borrowing the neighbour's: a broken extraction makes
# both vacuous, so both must redden.
#
# This rule is stated HERE, once, rather than only beside the blocks that were repaired. It was written
# into two blocks first (#283 slice 2), and THREE more chains elsewhere in this file carried the same
# defect untouched — the sweep that cleared them had re-read its own justification instead of mutating
# them. NO DISTANCE IS PUBLISHED, and the withdrawal is the finding: the earlier form said "1,050 lines
# away" without saying away from WHAT. The only reading that resolves gives 1,066 — the rule text at
# 5650793:2495 to the flag-class chain at 5650793:1429 — and both line numbers move on the next edit,
# so the figure could not stay true and could not be checked without restating its own endpoints. What
# the sentence needs is that none of the three sat anywhere near the blocks the sweep opened.
# THE TEST OF A CLEARED CHAIN IS A MUTATION, NOT A REASON: plant a defect only the lower arm can catch,
# run this suite, and check that the lower arm emits a line. A reason that survives re-reading is not
# evidence.
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

# --- skills, in total ---------------------------------------------------------------------------
# The root-level commands (autonomy-on.md) are counted SEPARATELY from the library, because that is
# how both documents present them: "<N> skills + autonomy-on".
#
# ── THERE IS NO FAMILY. ONE LEVEL, THIRTEEN DIRECTORIES (#286) ────────────────────────────────────
# The owner's decision, in his words: *"o que eu quero é que todas skills estejam no mesmo nível
# hierárquico de diretórios."* Every skill is `skills/<name>/SKILL.md` and nothing groups them.
#
# ~~THE FAMILY LIST IS DERIVED, NOT ENUMERATED … a NEW family is asserted from the moment it exists.~~
# ~~THE FAMILY IS NO LONGER A DIRECTORY (#164) … it is read out of a `family:` frontmatter key.~~
# ~~SO THE FAMILY IS A DIRECTORY AGAIN (#182) — a category teaches what a skill IS in a way an
# alphabetical list of 69 does not.~~
# **All three struck.** Kept rather than deleted because the grouping's whole history is the argument
# for removing it: directory → frontmatter key → directory → gone, in four slices, each one rewriting
# this file. The #182 reason was a claim about a DENOMINATOR — 69 files are unreadable alphabetically —
# and the denominator is 13. The measurement that justified the last move is still true and no longer
# reaches the tree it was made about.
#
# WHAT SURVIVED #182 UNCHANGED, AND IS THE REASON THIS SLICE IS A PATCH RATHER THAN A BREAK: the
# identifier is the BARE INNERMOST DIRECTORY NAME, at any depth, whenever `plugin.json` declares the
# path. Re-measured on #286 rather than inherited — probe and control, ONE variable, the same skill
# body and the same manifest name, moved from `skills/fam/probealpha` to `skills/probealpha` with the
# declaration updated to match:
#     claude --plugin-dir <probe> -p "/probeplug:probealpha"   nested -> the nonce
#     claude --plugin-dir <probe> -p "/probeplug:probealpha"   flat   -> the same nonce
# One identifier, two tree shapes, both resolved. So flattening changes no invocation surface, and
# `/tadeumendonca-skills:cloud-infrastructure` is the same string before and after.
#
# WHAT REMAINS LOAD-BEARING: the declaration. A skill added to the tree and not added to `plugin.json`
# DOES NOT EXIST to the model, silently — that is gated below, in both directions, under "the declared
# skills array", and the flatten does not touch it.
#
# SKILL_DIRS holds every directory DIRECTLY under skills/ that contains a SKILL.md. ONE depth now, not
# two: the depth-2 arm went with the families, and re-adding it would silently re-admit the shape this
# slice removed. A file at any other depth is caught by the shape assertion below, which is the only
# thing that walks the whole tree.
SKILL_DIRS="$(find "$ROOT/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while IFS= read -r d; do
  [ -f "$d/SKILL.md" ] && printf '%s\n' "$d"
done | sort)"

skill_dirs_named() {  # $1 = bare skill name -> every skills/<name> carrying that name
  printf '%s\n' "$SKILL_DIRS" | awk -F/ -v n="$1" '$NF == n'
}

# THE RESOLVER RETURNS NOTHING WHEN A NAME IS AMBIGUOUS, and that arm is now unreachable by
# construction — one directory level means one directory per name, enforced by the filesystem rather
# than by this file. It is KEPT rather than simplified away because the caller below reports "does not
# exist (or the name is ambiguous)" either way, and a resolver that quietly picked a winner is how a
# downstream check goes green about a file the loader never loads. Costs one comparison; buys that the
# guarantee does not depend on remembering why it holds.
skill_file() {  # $1 = bare skill name -> its SKILL.md path; empty if absent or ambiguous
  local dirs
  dirs="$(skill_dirs_named "$1")"
  [ "$(printf '%s\n' "$dirs" | grep -c .)" = "1" ] || return 0
  [ -f "$dirs/SKILL.md" ] && printf '%s' "$dirs/SKILL.md"
  return 0
}

total=$(printf '%s\n' "$SKILL_DIRS" | grep -c . || true)

# THE SHAPE ASSERTION REPLACES THE `family:` PRESENCE CHECK, and it covers the same defect from the
# other side. Under the frontmatter model a skill could be in the tree and in no published breakdown by
# omitting a key; under the directory model it does that by sitting at the WRONG DEPTH — anything deeper
# than 2 levels, unfiled, invisible to `SKILL_DIRS` and therefore to every count, table and resolver
# below. `find` walks the whole tree here precisely so a misplaced file is seen by the one assertion
# that can report it.
#
# ~~TWO DEPTHS ARE VALID, NOT ONE, SINCE #230/#231.~~ **STRUCK #286 — ONE DEPTH IS VALID.** The two
# depths existed because eleven skills sat under a family directory and two (`backend`, `frontend`) had
# consolidated until the family directory WAS the skill. The families are gone, so the second depth
# describes nothing that exists and accepting it would let a skill be re-nested with nothing red — the
# one direction this assertion is here to refuse, since a nested skill still LOADS (measured, see the
# probe above) and would therefore fail nowhere else.
#
# `find` walks the WHOLE tree here, deeper than SKILL_DIRS deliberately: a misplaced file is invisible
# to every count, table and resolver in this suite, and this is the one assertion that can see it.
# `skills/SKILL.md` itself (depth 0) is not accepted either, unchanged.
misplaced=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  rel="${f#"$ROOT"/}"
  case "$rel" in
    skills/*/*/SKILL.md) misplaced="$misplaced
    $rel" ;;
    skills/*/SKILL.md) : ;;
    *) misplaced="$misplaced
    $rel" ;;
  esac
done <<< "$(find "$ROOT/skills" -name 'SKILL.md' -type f 2>/dev/null | sort)"

if [ -n "$misplaced" ]; then
  bad "skill tree shape — a SKILL.md is not at skills/<name>/SKILL.md:$misplaced
      Since #286 the library is ONE level: thirteen directories under skills/, no families. A file at
      any other depth is outside every count, table and resolver in this suite — and it still loads if
      plugin.json declares it, so nothing else would report it."
else
  ok "skill tree shape — all $total skills sit at skills/<name>/SKILL.md, one level, no families"
fi

# --- the declared skills array -----------------------------------------------------------------
#
# THE ONE FAILURE IN THIS REPO THAT IS SILENT AT THE LOADER, not just at the assertion. `plugin.json`'s
# `skills` array is what makes a nested skill load at all — measured on #182, probe against control,
# one variable — so a skill present in the tree and absent from the array DOES NOT EXIST to the model,
# and NOTHING says so: no error, no log line, no missing file. It is the `skills:`-identifier failure
# mode one layer down, and it applies to all 69 rather than to ten.
#
# BOTH DIRECTIONS, because they fail differently and neither implies the other:
#   FORWARD  — every declared path resolves to a real SKILL.md. Catches a rename or a delete that left
#              the declaration behind: the plugin declares a path that is not there.
#   REVERSE  — every SKILL.md in the tree is declared. Catches the ADDITION, which is the direction that
#              is silent all the way down and the reason this gate is not optional.
#
# THE ARRAY IS HAND-MAINTAINED ON PURPOSE. Generating it from the tree would make the two directions
# tautological — the declaration would BE the tree, and the gate would assert `find` against `find`.
# The array is a statement about what this plugin publishes; this is the check that it is true.
DECL_JSON="$ROOT/.claude-plugin/plugin.json"
if ! command -v jq >/dev/null 2>&1; then
  bad "declared skills — jq unavailable, so plugin.json could not be read; BOTH directions did NOT run"
elif [ ! -r "$DECL_JSON" ]; then
  bad "declared skills — $DECL_JSON unreadable; BOTH directions did NOT run"
else
  declared="$(jq -r '.skills[]?' "$DECL_JSON" 2>/dev/null)"
  declared_n="$(printf '%s\n' "$declared" | grep -c . || true)"
  if [ "$declared_n" -eq 0 ]; then
    bad "declared skills — plugin.json declares NO skills array, or it is empty. Every skill under a family
      directory is then invisible to the model: measured on #182, a nested skill with no declaration
      returns SKILL-NOT-AVAILABLE while the tree looks perfectly correct."
  else
    # FORWARD
    decl_dangling=""
    while IFS= read -r p; do
      [ -z "$p" ] && continue
      rel="${p#./}"
      [ -f "$ROOT/$rel/SKILL.md" ] && continue
      decl_dangling="$decl_dangling
    $p — declared in plugin.json, and $rel/SKILL.md does not exist"
    done <<< "$declared"

    if [ -z "$decl_dangling" ]; then
      ok "declared skills (forward) — all $declared_n declared paths resolve to a SKILL.md"
    else
      bad "declared skills (forward) — plugin.json declares a path with no skill behind it:$decl_dangling"
    fi

    # REVERSE
    undeclared=""
    tree_n=0
    while IFS= read -r d; do
      [ -z "$d" ] && continue
      tree_n=$((tree_n + 1))
      rel="./${d#"$ROOT"/}"
      printf '%s\n' "$declared" | grep -qxF -- "$rel" && continue
      undeclared="$undeclared
    $rel"
    done <<< "$SKILL_DIRS"

    if [ "$tree_n" -eq 0 ]; then
      bad "declared skills (reverse) — no skill directories found; this direction did NOT run"
    elif [ -z "$undeclared" ]; then
      ok "declared skills (reverse) — all $tree_n skills in the tree are declared in plugin.json"
    else
      bad "declared skills (reverse) — a skill is in the tree and NOT declared, so it does not exist to the
      model and nothing else anywhere will say so:$undeclared
      Add the path to plugin.json's \"skills\" array. Under a family directory the array is what LOADS
      the skill — measured on #182: identical trees, array present resolved, array absent did not."
    fi
  fi
fi

# --- bare-name uniqueness ----------------------------------------------------------------------
#
# ~~TWO SKILLS WITH THE SAME DIRECTORY NAME IN DIFFERENT FAMILIES ARE ONE AMBIGUOUS IDENTIFIER, and
# which one the loader picks is not something this repo gets to decide. #174 merged the four pairs that
# existed (`coverage`, `dynamodb`, `cloudwatch-rum`, `environment-config`) and NOTHING stopped the next
# one — least of all the tree, which makes the collision look legitimate: two different directories,
# two different families, one identifier.~~
#
# **THE ASSERTION IS DELETED, NOT MOVED (#286), AND THE DELETION IS THE HONEST ACT.** With one directory
# level the identifier IS the directory name, so a collision requires two directories with one name in
# one parent — which the filesystem refuses. The check could not fail. A check that cannot fail is this
# workspace's named recurring defect, and leaving one here, in the file whose header brags about
# vacuous greens, would be the worst place to introduce it. The property is still guaranteed; it is
# guaranteed by `mkdir` rather than by bash, and that is a stronger guarantee, not a weaker one.
#
# WHAT IS LOST, said rather than left implied: if the families ever come back, this assertion has to
# come back with them, and nothing here will say so. The shape assertion above is what refuses the
# re-nesting in the first place, which is why it, and not this, is the one that was kept.

# --- the CLAUDE.md skill table -------------------------------------------------------------------
#
# THE HEADING IS NOT THE INVENTORY — THE TABLE UNDER IT IS WHAT A READER ACTUALLY READS. This exists
# because the gap it closes shipped: adding a skill reddened a heading count, someone bumped "(8)" to
# "(9)", and the suite went green with the table below it still listing eight rows. The skill was
# published and undiscoverable in the one document a reader opens to find out what exists.
#
# IT USED TO RUN PER FAMILY, ASSERTING `<family> (<n>)` IN BOTH DOCUMENTS AND THEN THE ROWS UNDER IT.
# With no families the heading half has nothing to assert — thirteen headings each reading `(1)` is not
# a check, it is the same information spelled thirteen times — so the per-family heading pair is gone
# and the LIBRARY total takes its place, asserted in both documents. The row half is unchanged in kind
# and now covers the whole library at once: every skill in the tree must have a row in CLAUDE.md's
# table. That is the half that was catching things.
expect_in "$README" "$total skills" "library total (README)"
expect_in "$CLAUDE" "$total skills" "library total (CLAUDE)"

missing_rows=""
while IFS= read -r d; do
  [ -z "$d" ] && continue
  stem="$(basename "$d")"
  grep -qF "| \`/$stem\` |" "$CLAUDE" && continue
  missing_rows="$missing_rows $stem"
done <<< "$SKILL_DIRS"
if [ -z "$missing_rows" ]; then
  ok "CLAUDE.md skill table — a row for all $total skills"
else
  bad "CLAUDE.md skill table — these skills have no row:$missing_rows; a skill is published and unlisted"
fi

expect_in "$README" "$total skills + autonomy-on" "library total"

# EVERY occurrence, not the one literal — and this is the hole the first version of this file had.
# The README states the total twice: once as the asserted string in the diagram, and once in prose in
# the opening paragraph ("73 skills that give implementation…"). Pinning only the first meant that
# adding a skill went red, someone fixed the line the failure named, and the suite went GREEN with the
# stale number still published in the surface sentence — the exact failure this file exists to
# prevent, surviving in the most-read line of the document.
#
# So the rule is inverted: find every place any of these files states a count of skills or personas,
# and require all of them to agree with the tree.
#
# WHAT THAT BUYS, STATED EXACTLY, because the first draft of this comment claimed more. It covers new
# LOCATIONS — a count written into any of the four documents is checked without anyone adding an
# assertion for it, which is what closes the hole this replaced. It does NOT cover arbitrary new
# PHRASINGS: the noun patterns below are a small allowlist, so a count written as
# "73 curated skills" is invisible to it. The pattern is kept deliberately loose (up to two adjectives)
# rather than pretending to be exhaustive — an enumeration that claims to be a rule is the failure
# this file exists to prevent, and it would be embarrassing to commit it here.
INVENTORY_DOCS=("$README" "$CLAUDE" "$ROOT/.claude-plugin/plugin.json" "$ROOT/.claude-plugin/marketplace.json")

check_every_occurrence() {
  local pattern="$1" expected="$2" label="$3"
  local bad_files=""
  for doc in "${INVENTORY_DOCS[@]}"; do
    while IFS= read -r found; do
      [ -z "$found" ] && continue
      [ "$found" = "$expected" ] && continue
      bad_files="$bad_files $(basename "$doc"):$found"
    done < <(grep -oE "$pattern" "$doc" 2>/dev/null | grep -oE '^[0-9]+')
  done
  if [ -z "$bad_files" ]; then
    ok "$label — every stated figure across the docs is $expected"
  else
    bad "$label — expected $expected, found:$bad_files"
  fi
}

check_every_occurrence '[0-9]+ ([a-z-]+ ){0,2}skills' "$total" "skills total, EVERY occurrence"
check_every_occurrence '[0-9]+ subagent personas' "$agents" "personas, EVERY occurrence"

# The root commands are named, not counted — if they are ever joined by an unannounced third, the
# docs' enumeration stops describing the remainder and this fails on purpose.
#
# The expected value moved 1 → 2 on 2026-08-04, when `commands/new-issue.md` shipped as a deliberate
# second root-level ACTION command (autonomy-on turns the loop on; new-issue captures a request as an
# Issue — both are things the owner invokes directly, neither belongs under a namespace), then 2 → 3 on
# #165, when `commands/autonomy-off.md` shipped as the deliberate off-switch autonomy-on always lacked.
#
# THE ASSERTION IS NOT WEAKER FOR HAVING BEEN BUMPED, and that is the whole reason it is a pinned
# literal rather than a `-ge`. It exists to catch the ACCIDENTAL root command — a skill dropped one
# directory too high, where nothing in the docs enumerates it and no reader ever finds it. A
# deliberate addition costs one line here and gets the docs updated in the same commit; an accidental
# one goes red. A `-ge 1` would have caught neither.
#
# WHAT IT NOW CATCHES IS THE OTHER DIRECTION TOO, and #164 is why the wording changed. "Un-namespaced"
# was the distinction when the library sat under family directories and these two did not; the library
# is flat and NOTHING carries a family segment any more, so that word had stopped separating anything.
# The real distinction is TYPED-vs-MATCHED: these two are invoked by the owner (they carry
# `argument-hint`, which the L1 block asserts on exactly them), and the 69 are matched by the model.
# So the failure this now catches is a LIBRARY SKILL LANDING IN `commands/` — where it is typed-only,
# never matched, and absent from every count and table in this file.
root_cmds=$(find "$ROOT/commands" -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')
if [ "$root_cmds" -eq 3 ]; then
  ok "commands/ root — exactly three owner-typed commands (autonomy-on, autonomy-off, new-issue), as the docs enumerate"
else
  bad "commands/ root — $root_cmds file(s); the docs enumerate three owner-typed commands (autonomy-on, autonomy-off, new-issue).
      A library skill belongs in skills/<name>/SKILL.md — under commands/ it is absent from every count
      and table here, and from the per-family breakdown a reader actually opens."
fi

# --- hooks ------------------------------------------------------------------------------------
# THE HOOKS WERE THE ONE INVENTORY NOBODY PINNED, and it cost a false claim on a public page. The
# README's diagram drew three hooks — `permission-guard`, `wip-guard`, `session-wip` — while
# `hooks/hooks.json` had registered four since `session-plugin-version` shipped. Personas and skills
# were guarded here; hooks were guarded nowhere, and the workflow's trigger filter did not even name
# `hooks/**`, so adding a hook could not start the suite that would have caught it. The stale three
# then propagated: issue #318 in the sibling repo specified "3 hooks" because its author read this
# README, and `/architecture` was about to publish that number one click from this document.
#
# TWO ASSERTIONS, NOT ONE, because the count alone is the weaker half. A renamed hook keeps the count
# and falsifies the diagram just as completely, so the names are checked too — the same reason the
# per-family skill counts grew a table-row assertion above.
#
# The diagram is counted by its NODE DECLARATIONS (`H<n>["…"]`), which is what a reader sees as a box.
# That prefix is used nowhere else in the README, so the count needs no subgraph-boundary parsing —
# the same trade the skill-row count makes, for the same reason: boundary parsing is a thing to get
# wrong for no gain.
HOOKS_JSON="$ROOT/hooks/hooks.json"
if [ ! -f "$HOOKS_JSON" ]; then
  bad "hooks/ — hooks.json does not exist; this assertion is checking nothing"
else
  registered=$(grep -cE '^[[:space:]]*"command"[[:space:]]*:' "$HOOKS_JSON")
  drawn=$(grep -cE '^[[:space:]]*H[0-9]+\["' "$README")
  if [ "$registered" = "$drawn" ]; then
    ok "hooks/ — hooks.json registers $registered and the README diagram draws $drawn"
  else
    bad "hooks/ — hooks.json registers $registered hook(s), the README diagram draws $drawn; the diagram is publishing a number the repo refutes"
  fi

  while IFS= read -r hook_name; do
    [ -z "$hook_name" ] && continue
    if grep -qF -- "$hook_name" "$README"; then
      ok "hooks/ — README names '$hook_name'"
    else
      bad "hooks/ — '$hook_name' is registered in hooks.json and appears nowhere in README.md"
    fi
  done < <(sed -nE 's#.*/hooks/scripts/([A-Za-z0-9._-]+)\.sh.*#\1#p' "$HOOKS_JSON")
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
# It moved again on 2026-08-02: `Harness Engineering` → `Agent Harness Engineering`, and this repo was
# IN that batch, which is the check working.
#
# THE PRESENCE CHECK NEEDED A BOUNDARY AND THE ABSENCE CHECK NEEDS A NEGATIVE LOOKAHEAD, both because
# the term GREW rather than changed. `grep -qF 'Harness Engineering'` is satisfied by the new value —
# one is a substring of the other — so on the day of the rename this assertion passed against the new
# term, against the superseded one, and against a revert. A term that gains a prefix breaks a substring
# check in silence, which is the second time this file has learned that a green is not evidence.
#
# The rule is "no occurrence NOT preceded by the prefix", which needs a pattern rather than a fixed
# string. `grep -E` with a negative lookahead is not available in POSIX ERE, so the absence is checked
# by stripping the qualified form first and looking for what survives.
#
# The pattern is borrowed from the sibling repo's og-copy.test.mjs, which pins the same pair in the
# same both-directions shape: the current term present, the retired one absent. Absence is the half
# that matters — a doc can gain the new name and keep the old one three paragraphs down.
# `PRINCIPLES.md` was in this list until it was folded into the README — a floor behind a click is a
# floor nobody reads. Removed here rather than left to fail: the existence guard below would have
# reported it, which is correct behaviour and the wrong signal, since the file is gone on purpose.
for doc in "$README" "$CLAUDE" "$ROOT/skills/harness-engineering/SKILL.md"; do
  name=$(basename "$doc")
  # Existence first. Without it, a renamed or deleted file makes `grep` print to stderr and return
  # non-zero — which the "is clear of the retired term" branch reads as SUCCESS, emitting a green line
  # asserting a property of a file that is not there. A pass for an unexamined reason, inside the
  # suite written to remove exactly that.
  if [ ! -f "$doc" ]; then
    bad "vocabulary — $name does not exist; this loop is asserting against a missing file"
    continue
  fi
  if grep -qF -- 'Agent Harness Engineering' "$doc"; then
    ok "vocabulary — $name names the practice"
  else
    bad "vocabulary — $name does not name the practice; the term is fixed by the positioning record"
  fi
  # Strip the QUALIFIED form, then look for what is left. Anything still matching is a bare
  # `Harness Engineering` — the superseded value — surviving beside the current one.
  if sed 's/Agent Harness Engineering//g' "$doc" | grep -q 'Harness Engineering'; then
    bad "vocabulary — $name still carries the BARE term; supersede it, do not leave it alongside"
  else
    ok "vocabulary — $name carries no un-prefixed form of the term"
  fi
  # THE STEM, NOT THE FULL TERM, and this is the third time this file has learned the same lesson in
  # two days. The check was `grep -qF 'Loop Engineering'` and a heading in the principles skill read
  # "The three surfaces a Loop Engineer engineers" — the ROLE noun of the retired practice, surviving
  # four lines from the practice's own new name. `Loop Engineer engineers` does not contain
  # `Loop Engineering`: the space falls exactly where the `i` would be, so the assertion written to
  # catch precisely this passed green against it.
  #
  # Three inflections of one defect now: a term that GREW broke the presence check (substring), a term
  # that grew broke the absence check (substring the other way), and a term that INFLECTED broke the
  # retired check. All three were fixed-string comparisons guarding a name. Matching the stem
  # `Loop Engineer` covers the noun, the gerund and the role in one, and costs nothing — nothing
  # legitimate contains those two words any more.
  if grep -qF -- 'Loop Engineer' "$doc"; then
    bad "vocabulary — $name still carries the RETIRED term (any inflection); supersede it, do not add alongside"
  else
    ok "vocabulary — $name is clear of the retired term in every inflection"
  fi
done

# THE EXCEPTION THIS BLOCK USED TO ASSERT IS RETIRED, NOT SILENTLY DROPPED. Every prior version of this
# comment recorded a known, deliberate gap: the skill was still named `loop-engineering` even though the
# vocabulary check above required `Agent Harness Engineering`, so `/loop-engineering` was a live public
# invocation naming a superseded term, on purpose, because renaming it was its own MAJOR-bump release.
#
# `harness-engineering` (#224) is that release. `skills/principles/loop-engineering/SKILL.md` no longer
# exists — folded, together with `dev-loop` and `engineering-philosophy`, into
# `skills/harness-engineering/SKILL.md` — so `/loop-engineering` is no longer a published
# invocation and the gap this block asserted is closed by the rename it was written to wait for.
# **This is the version decision the block's last form asked for, made rather than assumed: a command
# renamed/removed is a MAJOR bump per CLAUDE.md's own rule.** Whether the release that ships this PR
# carries it as MAJOR or, per #164's precedent, as one contract change already announced by a prior
# major version, is the owner's call at release time — not asserted here.
#
# The block is retired rather than deleted so the next reader can see what closed it, per this repo's
# own struck-not-deleted convention for exactly this kind of record.

# --- the roster's SHAPE, written as an English word inside an instruction -----------------------
# THE SECOND SURFACE OF A ROSTER CHANGE, and the numbers above cannot see it. When `marketing-lead`
# merged into `product-lead` on 2026-08-04, the sweep that propagated it was driven by the token
# `marketing-lead` — which it cleaned completely. Ten present-tense "three leads" statements survived
# in files that sweep never opened, because the roster states its shape twice: once as a NAME, and
# once as a COUNT in prose. The count is the half nothing pinned.
#
# The counts above are all `<digit> <noun>` in four documents. This one is a word, in a sentence, in
# an agent file — a persona that reads "the three leads close the description" acts on three.
#
# EXPECTED VALUE IS DERIVED, never written here: `agents/*-lead.md`. A merge that removes a lead file
# reddens this in the same commit, which is the property the whole file is built on.
#
# `harness-lead.md` IS EXCLUDED, and this is a naming collision, not a re-widened scope. Issue #216
# renamed the harness persona's file to end in `-lead` for tier-equality prose ("the owner's pair on
# the MACHINERY — same tier as the leads"), and CLAUDE.md is explicit that it is NOT one of "the two
# leads": those are `product-lead` and `tech-lead`, the two who close an Issue's description and are
# addressed together as "the two leads" throughout this repo's prose. A bare `*-lead.md` glob cannot
# tell the two apart by name alone, so the exclusion is spelled out here rather than left to a suffix
# match that would otherwise silently promote every future `*-lead.md` file into this count.
lead_files=$(find "$ROOT/agents" -maxdepth 1 -name '*-lead.md' -type f ! -name 'harness-lead.md' | wc -l | tr -d ' ')
case "$lead_files" in
  1) lead_word=one ;;   2) lead_word=two ;;   3) lead_word=three ;;
  4) lead_word=four ;;  5) lead_word=five ;;  6) lead_word=six ;;
  7) lead_word=seven ;; 8) lead_word=eight ;; 9) lead_word=nine ;;
  *) lead_word="$lead_files" ;;
esac

# SCOPE IS INSTRUCTIONS, NOT RECORDS, and that cut is the whole reason this is not a cry-wolf regex.
# `agents/**`, `skills/**` and `commands/**` are read by an agent as current fact, and `hooks/scripts/*.sh`
# comments state the rule the code beside them enforces — all three must be TRUE. `docs/**` is
# excluded on purpose: it narrates how the roster got here, and a check that reddens on "the roster
# was three leads until 2026-08-04" would force a record to be falsified to go green, which is worse
# than the gap it closes. `*.test.sh` is excluded because a suite's fixtures are deliberately wrong
# strings — including this file, whose own comments describe the phrasing it hunts.
lead_scan_files=$(
  find "$ROOT/agents" "$ROOT/commands" "$ROOT/skills" -name '*.md' -type f
  find "$ROOT/hooks/scripts" -name '*.sh' -type f ! -name '*.test.sh'
)

# WHAT IT MATCHES, AND WHAT IT DELIBERATELY DOES NOT — said exactly, because the failure this file
# keeps re-learning is a pattern claiming more than it covers.
#
# It matches a count ADJACENT to the noun: `three leads`, `three-lead referendum`, `4 leads`. That
# adjacency is the phrasing that goes stale silently, and it is the one all ten survivors used.
#
# It starts at TWO. `one lead` is ordinary English for a single lead — `agents/quality-assurance.md`
# says "one half of one lead" about the copy lens — and flagging it would be the cry-wolf failure on
# the first run. The cost is real and is stated rather than hidden: if the roster ever became one
# lead, a surviving `one lead` would not be caught by this. Every wrong count ABOVE one still is,
# which is the direction that has actually happened twice.
#
# It cannot see a count stated any other way — "the leads numbered three", "both leads", a sentence
# naming each lead and omitting none. Those are out of reach of a pattern, and pretending otherwise
# is how an enumeration gets mistaken for a rule. The fix for the phrasings this misses is the
# durable one anyway: instructions say "the leads" and carry no count at all.
stale_leads=""
while IFS= read -r hit; do
  [ -z "$hit" ] && continue
  tok=$(printf '%s' "$hit" | sed -E 's/^.*:([A-Za-z0-9]+)[- ]leads?$/\1/' | tr '[:upper:]' '[:lower:]')
  [ "$tok" = "$lead_word" ] && continue
  [ "$tok" = "$lead_files" ] && continue
  stale_leads="$stale_leads
    ${hit#"$ROOT"/}"
done < <(
  # shellcheck disable=SC2086
  grep -oniE '(two|three|four|five|six|seven|eight|nine|[2-9]|[0-9]{2,})[- ]leads?' $lead_scan_files 2>/dev/null
)

if [ -z "$stale_leads" ]; then
  ok "roster shape — every stated lead count in agents/, commands/ and the hook scripts is $lead_word"
else
  bad "roster shape — the roster has $lead_files leads ($lead_word); these state another count:$stale_leads"
fi

# --- the permission floor's interpreter surface ------------------------------------------------
#
# WHY THIS IS HERE RATHER THAN IN A COMMENT. `permission-guard.test.sh` carries a carefully-written
# note explaining that its silence assertions depend on the floor — "no allow entry remains that would
# shadow the act". That note is correct, states its own limit, and points at the file. It is also an
# UNCHECKED CLAIM ABOUT A FILE NO SUITE READS: true today, false the moment someone re-adds
# `Bash(bash:*)`, and nothing would say so.
#
# THREE STALENESS EVENTS FIRED INSIDE THE PR THAT ADDED THAT NOTE — a doc count, a derived count in a
# box whose purpose was preventing a misreading, and a floor edit that inverted a section's meaning
# with no assertion going red. A fourth carefully-written comment is not the remedy for the first
# three. This block is the remedy: the claim becomes checkable, and the comment stays.
#
# THE SUITE THAT DEPENDS ON THIS CANNOT MAKE THE CHECK ITSELF. `permission-guard.test.sh` classifies
# the GUARD's stdout and never reads `settings.json` — by design, since it tests the hook. So the
# assertion belongs where repo-file content is already asserted, which is this file.
# WHAT THIS BLOCK CHECKS, AND THE FILE IT CANNOT SEE. It reads the COMMITTED floor. The EFFECTIVE
# floor of a running session is the committed file merged with `.claude/settings.local.json` — which is
# gitignored, per-machine, and re-created by a single "allow always" click. That file is not a
# hypothetical here: it is the one the audit that produced this whole block found governing every
# session, with 82 `allow` entries and no `deny` block at all. So state the scope precisely rather than
# saying "the floor":
#
#   · ASSERTIONS 1 AND 3 ARE SCOPED TO THE COMMITTED FILE AND CANNOT BE OTHERWISE. Both check for the
#     ABSENCE of an `allow` entry, and `allow` is exactly the direction a local overlay can move. Someone
#     clicks "allow always" on `perl -e …`, `Bash(perl:*)` lands in `settings.local.json`, the gap
#     re-opens, and this suite stays green — because it is reading the other file. Nothing in CI can
#     close that: CI has no such file to read, and a suite that demanded one would fail on every machine
#     that does not have it.
#   · WHAT ACTUALLY SURVIVES THE CLICK IS `deny`, NOT AN ASSERTION. In the settings merge, deny from any
#     layer wins, so a prohibition written into the committed `deny` block holds against any later local
#     `allow`. That is why this PR moved prohibitions out of "absence" and into `deny`, and it is the
#     remedy for this residual wherever the class can be denied outright. The interpreters here CANNOT
#     be: `Bash(bash:*)` in `deny` is a prefix match, so it would also refuse the five exact
#     `bash <test-script>` entries above. Hence an assertion, hence this note about its limit.
#
# The honest reading of a green result below is therefore: "the committed floor does not carry these
# entries", not "this machine's session does not". To check the latter, read
# `.claude/settings.local.json` by hand; this suite cannot check it for you.
SETTINGS="$ROOT/.claude/settings.json"

# FAIL LOUDLY IF THE INPUT CANNOT BE READ. An absence check that cannot see the file passes
# vacuously — it would report "no perl entry" on an unreadable floor, which is the exact class of
# green-for-the-wrong-reason this block exists to stop.
if ! command -v jq >/dev/null 2>&1; then
  bad "permission floor — jq unavailable, so the floor could not be read; these assertions did NOT run"
elif [ ! -r "$SETTINGS" ]; then
  bad "permission floor — $SETTINGS unreadable; these assertions did NOT run"
else
  allow_entries="$(jq -r '.permissions.allow[]?' "$SETTINGS" 2>/dev/null)"
  if [ -z "$allow_entries" ]; then
    bad "permission floor — the allow list parsed as EMPTY; every check below would pass vacuously"
  else
    ok "permission floor — allow list readable ($(printf '%s\n' "$allow_entries" | wc -l | tr -d ' ') entries)"

    # 1 — perl and ruby must NOT be in `allow`. They were added without being named in any commit
    #     message, and made a trunk push an ASK on trunk and a silent ALLOW here. Matched by
    #     interpreter NAME, not by the exact string `Bash(perl:*)`, so a respelling with a path or a
    #     different wildcard is caught too.
    #
    #     THE PREFIX GROUP IS THE SAME BOUNDARY `permission-guard.sh` USES — `(^|[[:space:]]|/)` before
    #     the interpreter name. Without it this anchored on `Bash(` and `Bash(/usr/bin/perl:*)` passed:
    #     measured green with that entry in `allow`. The two layers now agree on what "an interpreter"
    #     looks like, which is the point — a boundary that differs between them is a gap by definition.
    for interp in perl ruby; do
      hit="$(printf '%s\n' "$allow_entries" | grep -E "^Bash\(([^)]*[/[:space:]])?$interp([[:space:]]|:)" || true)"
      if [ -z "$hit" ]; then
        ok "permission floor — no '$interp' entry in allow"
      else
        bad "permission floor — '$interp' is back in allow: $hit — a payload in that interpreter reaches any act with no decision from the hook (it does not parse other languages) and none from the floor"
      fi
    done

    # 2 — python3 and node must BE in `allow`. ADR-0008 prices these as accepted non-containment, and
    #     `permission-guard.test.sh` asserts their silence as a PRICED gap rather than a hole. If they
    #     were removed, that section would be describing a floor that no longer exists — and an
    #     absence-only check would go green on it, which is a different floor than the one recorded.
    for interp in python3 node; do
      hit="$(printf '%s\n' "$allow_entries" | grep -E "^Bash\($interp([[:space:]]|:)" || true)"
      if [ -n "$hit" ]; then
        ok "permission floor — '$interp' present in allow, as ADR-0008 prices it"
      else
        bad "permission floor — '$interp' is NO LONGER in allow; ADR-0008 and permission-guard.test.sh both describe it as a priced, accepted gap. Update those records or restore the entry — do not leave them describing a floor that is gone"
      fi
    done

    # 3 — NO SHELL-INTERPRETER ENTRY MAY END IN A WILDCARD. This is the one that would have caught the
    #     round-4 defect, and the choice of shape is deliberate:
    #
    #       REJECTED: forbid `Bash(bash <path>/:*)`, the exact shape that failed. It is a SPELLING.
    #         `Bash(bash /Users/…/scripts:*)` — no trailing slash — has the identical hole and would
    #         pass. This batch's entire subject is spelling-shaped rules being respelled, four times
    #         over (rule 4's flag set, 5b's `-R`, 5f's attached value, the unwrap's `$'…'`).
    #       CHOSEN: forbid a trailing wildcard on ANY shell interpreter. That is the PROPERTY. A `:*`
    #         permits an unbounded suffix; `permission-guard.sh` deliberately declines to look inside
    #         `bash script.sh`; so the suffix is arbitrary code. Measured at round 4: a path prefix is
    #         a STRING prefix, and `…/hooks/scripts/../../../../private/tmp/x.sh` carries it while
    #         reaching any script on disk. The prefix bounded the characters, not the directory.
    #
    #     The cost, stated because it is real: this forecloses a wildcard bash entry someone may one
    #     day legitimately want. That is the intent — the five exact-match entries prove the wildcard
    #     is not needed for the actual use case, and a future need should arrive as a deliberate
    #     change to THIS assertion, reviewed, rather than as a quiet line in the floor.
    #
    #     `sh|zsh|ksh|dash` are covered though none is in allow today: re-adding one with a wildcard is
    #     precisely the respelling this shape exists to refuse. The optional `[[:space:]][^)]*` is what
    #     keeps `Bash(shellcheck:*)` and `Bash(shasum:*)` from matching on `sh` — an argument run must
    #     start with whitespace, so a longer TOOL NAME never qualifies.
    #
    #     THE FIRST VERSION OF THIS PATTERN MISSED `Bash(bash:*)` — the single entry this whole batch
    #     removed. It required `([[:space:]]|:)` after the interpreter and then `.*:\*\)`, so the bare
    #     form had only one `:` to spend and did not match, while every PATH form did. It would have
    #     passed green on the most dangerous entry expressible. Reading it did not find that; an
    #     accept/refuse table of seventeen spellings did, which is the same lesson as the rest of this
    #     batch and is why the table is kept as a comment rather than discarded after use.
    #
    #     THE SECOND VERSION MISSED THE PATH-SPELLED FORMS, and it was found the same way — by a
    #     DIFFERENT author writing a DIFFERENT table, which is the part worth keeping. A table written
    #     by whoever wrote the regex samples the spellings that author already had in mind; the first
    #     miss and this one were both invisible to reading and both fell out of an independent set.
    #     The entry anchored the interpreter name to `Bash(`, so the bare and argument forms were
    #     caught while every form naming the interpreter BY PATH walked through. Measured: the suite
    #     reported 49/0 and "no shell-interpreter allow entry ends in a wildcard" with all three of
    #     `Bash(/bin/bash:*)`, `Bash(/usr/bin/env bash:*)` and `Bash(/usr/bin/perl:*)` in `allow`.
    #     `/bin/bash /any/script.sh` is the same unbounded grant as `Bash(bash:*)`, one respelling out.
    #
    #     THE FIX IS TO BORROW THE GUARD'S OWN BOUNDARY rather than invent a third one. The unwrap in
    #     `permission-guard.sh` already answers "is this token an interpreter" with `(^|[[:space:]]|/)`
    #     before the name — which is why `/bin/bash -c` unwraps and `npm run finish -c x` does not. The
    #     optional `([^)]*[/[:space:]])?` here is that same boundary: an interpreter is at the start, or
    #     after a slash, or after whitespace. `Bash(shellcheck:*)`, `Bash(shasum:*)` and `Bash(zshdb:*)`
    #     still pass, because a longer TOOL NAME has neither in front of its `sh`.
    #
    #     Table, second author, 39 spellings, all measured before the pattern was trusted:
    #
    #       FLAG  Bash(bash:*)  Bash(sh:*)  Bash(zsh:*)  Bash(ksh:*)  Bash(dash:*)
    #             Bash(bash <path>/:*)  Bash(bash <path>:*)  Bash(bash -c:*)  Bash(bash  <path>:*)
    #             Bash(/bin/bash:*)  Bash(/bin/sh:*)  Bash(./bash:*)  Bash(../../bin/zsh:*)
    #             Bash(/usr/bin/env bash:*)  Bash(env bash:*)  Bash(command bash:*)  Bash(exec bash:*)
    #             Bash(/bin/bash -c:*)  Bash(/opt/homebrew/bin/bash -lc:*)
    #       pass  Bash(shellcheck:*)  Bash(shasum:*)  Bash(shuf:*)  Bash(sha256sum:*)  Bash(bashate:*)
    #             Bash(basher:*)  Bash(dashboard:*)  Bash(zshdb:*)  Bash(kshrc-lint:*)  Bash(node:*)
    #             Bash(python3:*)  Bash(bump-my-version:*)  Bash(npm run finish:*)  Bash(npm run lint:*)
    #             Bash(git show:*)  Bash(git stash:*)  Bash(git push:*)  Bash(gh pr view:*)
    #             Bash(bash <path>/x.test.sh)
    #
    #     The four `git`/`npm` entries are in the pass set on purpose: `show`, `stash`, `finish` and
    #     `lint` all contain a shell name as a SUBSTRING, and a prefix group that ended in anything but
    #     a slash or whitespace would flag every one of them.
    #     WIDENED 2026-08-07 FROM `:\*\)` TO `[:/]\*\)`, and this is the deliberate reviewed change the
    #     paragraph above asked for. The pattern required a COLON before the star, so
    #     `Bash(bash .scratch/*)` — a slash — walked straight through an assertion written to forbid
    #     exactly its property. One character. It shipped on #160 and was caught by the merge gate, not
    #     here. That is the third time in this file's history that this assertion was one spelling short,
    #     and the lesson is identical each time: the shape was right, the CHARACTER SET was a guess.
    #
    #     ~~AND ONE NAMED EXCEPTION~~ — `Bash(bash .scratch/*)`, kept by the owner (option A,
    #     2026-08-07) and excused here by two `grep -qF` calls against **record 0008** by FILENAME.
    #     The number is written BARE throughout this note, never prefixed and never as a path: 0008 is
    #     absorbed later in #283, and the prefixed and path forms are the two the citation gate resolves
    #     against live records. Writing either here would re-create, inside the note explaining why the
    #     coupling was wrong, a citation that the fold has to move.
    #     **THE EXCEPTION AND ITS MACHINERY ARE DELETED, 2026-08-19 (#283 slice 1) — deleted, not
    #     repointed.** Four struck paragraphs of its history went with it; what they recorded is
    #     compressed into the two paragraphs below, because the lesson is about this file and the
    #     archaeology was about an allow entry that no longer exists.
    #
    #     IT WAS NOT MERELY DEAD, WHICH IS THE PART WORTH KEEPING. The entry it excused left the floor
    #     at #245 (`grep -n 'scratch' .claude/settings.json` -> no output), but both greps still matched
    #     record 0008, so the exception branch stayed LIVE and this assertion printed *"one shell
    #     wildcard, UNBOUNDED and recorded as such"* by that record's name while `allow` held five
    #     exact-match `bash` entries and no wildcard at all. A green describing a grant that does not
    #     exist is this suite's own failure mode, one layer up, and no count would ever have surfaced it
    #     — the arm passed, it just passed a sentence about a different floor.
    #
    #     AND IT IS DELETED RATHER THAN REPOINTED because the coupling itself is the defect: #283 folds
    #     record 0008 into the `controls-and-enforcement` capability document, and a gate tied to a
    #     record BY FILENAME is exactly the coupling that fold breaks silently. (That capability was
    #     called `permissions` until 2026-08-19; the rename is why this sentence changed, and it is
    #     itself a small instance of the coupling being described.) The durable lesson, nowhere else:
    #     where a mechanism exists, tie to the mechanism by EXECUTING it, never by grepping for a
    #     sentence about it. This exception was tied first to a hook rule that could not bound it, then
    #     to a phrase in a deny message that survived commenting the rule out, then to a record — three
    #     ties, green throughout. A document check is weaker than a behaviour check every time.
    wildcard_shells="$(printf '%s\n' "$allow_entries" \
      | grep -E "^Bash\(([^)]*[/[:space:]])?(bash|sh|zsh|ksh|dash)([[:space:]][^)]*)?[:/]\*\)$" || true)"
    wildcard_shells="$(printf '%s' "$wildcard_shells" | grep -v '^[[:space:]]*$' || true)"
    if [ -z "$wildcard_shells" ]; then
      ok "permission floor — no shell-interpreter allow entry ends in a wildcard"
    else
      bad "permission floor — a shell-interpreter entry ends in a wildcard, which permits an unbounded suffix: $wildcard_shells
      A path prefix is a STRING prefix, not a directory scope: '<allowed-prefix>/../../../tmp/x.sh' carries it.
      permission-guard.sh does not look inside a script file, so that suffix is arbitrary code with no decision from any layer.
      Measured on #160 against a live floor: 'bash .scratch/.\"\"./.\"\"./<other-repo>/VERSION' runs with NO decision from any layer.
      That spelling is deliberate. The obvious one ('.scratch/../../<other-repo>/VERSION') was the original measurement and
      permission-guard rule 9 now DENIES it — so quoting it here would offer, as the evidence, the one string this repo closed.
      The empty quoted span has no '..' adjacency at all, which is why no pattern reaches it and why the property survives.
      Use exact-match entries (one per script). DO NOT reach for a hook rule: rule 9 was written to bound this directory and
      CANNOT — a lexical instrument cannot decide a filesystem property. If you add an exception here, tie it to a RECORD that
      states the accepted grant AND tie it to a mechanism you can execute. The one exception this file
      once carried was tied to a record by filename, printed a green describing a grant that had already
      left the floor, and was deleted at #283 slice 1 rather than repointed."
    fi
  fi
fi

# --- no tracked file may CLAIM an allow entry the floor does not contain ----------------------
#
# THE DEFECT THIS COMES FROM: three consecutive commits removed allow entries and left ten sites across
# a hook header, two suites and two ADRs asserting those entries are present — in the present tense,
# framed as measurement. One of them told the next maintainer that an entry the same PR had deleted
# MUST exist, which is not stale documentation but an instruction to re-introduce the defect.
#
# THE CAUSE IS STRUCTURAL, NOT CARELESSNESS: each removal commit was scoped to the file it removed from
# plus the adjacent narrative, and none re-grepped the entry name across the tree. The floor is one
# file; its justification is spread across five. Nothing connected them, so this does.
#
# ── WHAT THIS CHECK IS, STATED BEFORE IT RUNS, BECAUSE IT IS WEAKER THAN IT LOOKS ────────────────
# THE STRONG FORM — *"no tracked file asserts an allow entry the floor does not contain"* — IS NOT
# RELIABLY EXPRESSIBLE HERE, and pretending otherwise would make this the fifth instance of the defect
# it exists to catch. The blocker is not finding the entry names; `Bash(...)` tokens are exact and the
# floor is machine-readable. It is that **distinguishing an ASSERTION from a NARRATION is a reading of
# prose, not a pattern.** These two lines differ only in a verb:
#
#     `Bash(gh -R:*)` is in `allow` because the convention prescribes it   [example] ← must fire
#     for one day the floor carried `Bash(gh -R:*)` in `allow`             [example] ← must not
#
# `[example]` IS AN OPT-OUT MARKER, and it exists because the two lines above tripped this check the
# first time it ran — an illustration of the bad phrasing is not the bad phrasing. The trade is worth
# naming: an opt-out token can silence a REAL claim, so it is deliberately ugly, and a diff adding one
# to a sentence that is not an illustration should be questioned in review. That is the same bargain as
# any lint-disable comment, and the same answer — visible beats silent.
#
# SO IT IS A TRIPWIRE FOR ONE PHRASING, NOT A PROOF, and it is deliberately biased toward MISSING a
# stale claim rather than firing on a correct one. A check that cries wolf on accurate prose trains
# people to ignore it, and an ignored check is worse than an absent one — it also looks like coverage.
# It fires only on a short list of present-tense presence phrases, and only when no past-tense or
# negation marker appears on the same line.
#
# WHAT IT THEREFORE DOES NOT CATCH, so nobody reads a green here as more than it is: a stale claim
# phrased any other way ("the allowlist opens X", "X is granted", a claim spanning two lines). The
# durable fix is the one the hook header already applies — write the DERIVATION, not the entry name —
# and this check exists because that discipline failed ten times in three commits, not because it is
# the wrong discipline.
#
# THE BOUND IS PHRASING ONLY, AND THAT IS A CORRECTION. The first version of this list also hedged
# "any claim in a file this loop does not scan", which read as a caveat and was in fact a hole: the
# scan set omitted `docs/`, and `docs/adr/` is the ONLY layer the defect was left in — the commit that
# found it records that the hook header had already been re-tensed and "only the ADR layer was left
# behind". Measured, same line, same head: `Bash(perl:*) is in allow` FIRES in `agents/` and passes
# GREEN in `docs/adr/0008`. So the check covered every layer that had self-corrected and none of the
# one that had drifted. `docs/` is now in the set below, and adding it cost no prose churn — the sweep
# had already made the ADR layer honest, so the suite stayed green. A generic "files it does not scan"
# is a reassurance; an enumerated scan set is a bound.
#
# (An earlier edition of this paragraph reported the asserting-line count as "4 → 6". The suite prints
# the number it actually found, on every run, which is the only form that cannot go stale — a derived
# count in prose, inside the block built to catch stale derived counts, is this batch's signature
# defect and it landed here too.)
#
# ── THE SET IS DERIVED FROM `git ls-files`, NOT FROM A LIST OF ROOTS ─────────────────────────────
# It used to be `find` over four fixed directories plus three named files, with a COMMENT recording
# that `git ls-files` minus those paths returned nothing. Three ways that narrowed; this closes two of
# them permanently:
#
#   DIRECTORY — the only thing that would have noticed a fifth root was that comment. A comment is the
#     instrument this batch has ruled insufficient four times over: it cannot fail.
#   TRACKED-vs-PRESENT — `find` walked the FILESYSTEM while the comment verified against GIT. They
#     diverge on any tracked file `find` never reaches, and on anything untracked that it does.
#   EXTENSION — `*.md`/`*.sh` remains a bounded CHOICE, and it stays one. It is now visible in the
#     command below rather than asserted in prose. A `Bash(...)` token can appear in a `.yml`
#     (`.github/workflows/claude.yml` carries one today — shape demonstrated, no live stale claim), so
#     widening is a real option; it is not taken here because every layer that has actually drifted is
#     prose, and each added extension widens the cry-wolf surface this check is deliberately narrow on.
#
# Deriving from `git ls-files` makes the first two TAUTOLOGICAL — the set IS the tracked set, so there
# is nothing left for a comment to verify. `-z` with `read -d ''` because a tracked path may contain
# whitespace; `find` was safe on that by luck of this repo's filenames, not by construction.
FLOOR_CLAIM_FILES=""
while IFS= read -r -d '' rel; do
  FLOOR_CLAIM_FILES="$FLOOR_CLAIM_FILES
$ROOT/$rel"
done < <(git -C "$ROOT" ls-files -z -- '*.md' '*.sh' 2>/dev/null)

# ── THE CITATION SCAN SET, DEFINED HERE AND USED AT THE END OF THIS FILE ─────────────────────────
# Declared next to `FLOOR_CLAIM_FILES` rather than beside the assertions that consume it, for one
# reason: the gate-coverage check below unions every source this suite reads, and a set defined AFTER
# that check is a set the check cannot see. That is precisely the hole its own comment describes — the
# scan set derived in one place, the coverage list maintained in another, and nobody diffing them.
# Defining it above the consumer makes the union mechanical instead of remembered.
#
# THE EXTENSION LIST IS WIDER THAN `FLOOR_CLAIM_FILES`, and deliberately so. That set is `*.md`/`*.sh`
# because every layer that has drifted on a permission CLAIM is prose. A decision-record citation is a
# different population: they are measured today in `.claude-plugin/plugin.json`, in four
# `.github/ISSUE_TEMPLATE/*.yml` files and in `.github/workflows/claude-code-review.yml`. Narrowing to
# markdown and shell would have left six files carrying live citations outside the gate built for them.
CITATION_FILES=""
while IFS= read -r -d '' rel; do
  CITATION_FILES="$CITATION_FILES
$ROOT/$rel"
done < <(git -C "$ROOT" ls-files -z -- '*.md' '*.sh' '*.yml' '*.yaml' '*.json' '*.py' 2>/dev/null)

CITATION_MD_FILES=""
while IFS= read -r -d '' rel; do
  CITATION_MD_FILES="$CITATION_MD_FILES
$ROOT/$rel"
done < <(git -C "$ROOT" ls-files -z -- '*.md' 2>/dev/null)

if ! command -v jq >/dev/null 2>&1 || [ ! -r "$SETTINGS" ]; then
  bad "floor claims — floor unreadable (jq or $SETTINGS); this assertion did NOT run"
else
  floor_allow="$(jq -r '.permissions.allow[]?' "$SETTINGS" 2>/dev/null)"
  if [ -z "$floor_allow" ]; then
    bad "floor claims — allow list parsed as EMPTY; every check below would pass vacuously"
  else
    # Present-tense presence phrases. Narrow on purpose — see the note above.
    claim_re='(is|are|sits|sitting) in `allow`|(is|are) in the allowlist|with `Bash\([^)]*\)` in `allow`'
    # Past tense / negation / struck text on the same line means it is NARRATING, not asserting.
    narr_re='~~|no longer|never|was |were |had |has been|carried|sat |until |former|removed|STRUCK|struck|\[example\]'
    stale_claims=""
    checked=0
    while IFS= read -r file; do
      [ -z "$file" ] && continue
      [ -r "$file" ] || continue
      while IFS= read -r line; do
        [ -z "$line" ] && continue
        printf '%s' "$line" | grep -Eq "$narr_re" && continue
        checked=$((checked + 1))
        # Every `Bash(...)` token named on an asserting line must be in the floor's allow list.
        while IFS= read -r tok; do
          [ -z "$tok" ] && continue
          if ! printf '%s\n' "$floor_allow" | grep -qxF -- "$tok"; then
            stale_claims="$stale_claims
    ${file#"$ROOT"/}: $tok — claimed present, absent from the floor"
          fi
        done <<< "$(printf '%s' "$line" | grep -oE 'Bash\([^)]*\)' || true)"
      done <<< "$(grep -nE "$claim_re" "$file" 2>/dev/null | sed 's/^[0-9]*://' || true)"
    done <<< "$FLOOR_CLAIM_FILES"

    if [ -z "$stale_claims" ]; then
      ok "floor claims — no present-tense claim names an allow entry the floor lacks ($checked asserting lines checked)"
    else
      bad "floor claims — a tracked file says an entry is in \`allow\` and the floor does not contain it:$stale_claims
      Either the floor changed and the prose did not, or the prose names an entry that never existed.
      If the sentence is NARRATING a removal, say so on the same line (\"was\", \"no longer\", \"~~struck~~\") — that is what tells this check it is history."
    fi
  fi
fi

# --- the README's skill TABLE, not just its counts ---------------------------------------------
#
# THE SAME DEFECT AS THE `CLAUDE.md` PER-FAMILY TABLES, IN THE OTHER DOCUMENT. This file's header books
# it in its own words — "it asserts the numbers, never the prose around them" — and the family loop
# above already closed it for `CLAUDE.md` with `rows=$(grep -c ...)`, after it SHIPPED: a skill was
# added, the heading count went red, someone bumped the number the failure named, and the suite went
# green with the table below still listing one fewer. The README's table had no equivalent, so the same
# sequence there is still available. Adding a skill reddens `<N> skills + autonomy-on`, one edit fixes
# the sentence the failure quotes, and the skill ships published-and-unlisted in the one document a
# forker actually reads.
#
# ── THE ANCHOR WAS THE (SKILL, FAMILY) PAIR AND IS NOW THE SKILL ALONE (#286) ──────────────────
# ~~Measured before choosing: FOUR skill names existed in two families each — `coverage`, `dynamodb`,
# `cloudwatch-rum` and `environment-config`. A check keyed on the backticked name alone passes with one
# of a duplicate pair missing from the table, which is precisely the failure it exists to catch, so the
# name is not a key.~~ **The reason is retired with the families.** A duplicate stem needed two
# directories with one name; there is one directory level now, so the filesystem refuses it and the
# name is a key by construction — the same argument that deleted the uniqueness assertion above.
#
# The row shape the generator emits is
#     | `<skill>` | <description> | <whose domain> |
# (cell 3 was headed `wielded by` until #172; it is `whose domain` now, and the rename is why the
# heading is not what either direction keys on.) Both directions below key on cell 1. `.*` spans cell 2
# rather than splitting on `|`, because a description containing an escaped `\|` still contains the
# delimiter.
#
# ── THE ROW SHAPE SELECTS THE TABLE WITHOUT NAMING WHERE IT IS ─────────────────────────────────
# The reverse direction needs the set of rows, and the README holds a SECOND table whose first cell is
# also backticked (the hook-event matrix: `| \`UserPromptSubmit\` | … |`). Rather than parse section
# boundaries — a thing to get wrong for no gain — the shape below requires cell 1 to be a single
# backticked LOWERCASE token and the row to close after cell 3. Every hook-event row's first cell is
# CamelCase (`UserPromptSubmit`, `PostToolUse`), so none of them matches; measured on the flattened head
# this selects exactly 13 lines, the same number the generator emits.
#
# WHAT THE FLATTEN COST THIS BLOCK, and it is a real loss rather than a wash: the old key also caught a
# row filing a skill under a family the tree does not put it in. There is no such claim left to be
# wrong, so the check is narrower because the published claim is narrower — not because the assertion
# was weakened.
#
# ── HOW TO FIX A RED HERE, because a red that teaches the wrong repair is worse than none ──────
# **Re-run `hooks/scripts/skills-table.py` and paste its output over the table.** Do NOT hand-edit the
# row the failure names. The table is generated precisely so that no description is a hand-written
# claim about what a skill does, and repairing it by hand restores that risk one row at a time while
# turning this assertion green.
#
# ── WHAT THIS DOES NOT ASSERT, said plainly ────────────────────────────────────────────────────
# It checks that a row EXISTS for each skill and that no row invents one. It does NOT check the row's
# CONTENT — a description hand-edited to say something the skill does not say passes both directions.
# Closing that needs a verbatim diff against the generator's output, which was considered and rejected:
# it reddens on any reflow or formatting change to a published README, which is the cry-wolf failure
# this file books elsewhere. The generator's docstring carries the same limit from its side.
skill_rows_re='^\| `[a-z0-9][a-z0-9-]*` \|.*\|[^|]*\|$'

# DIRECTION 1 — every skill file has a row. Catches an ADDED skill nobody listed.
table_missing=""
skill_files=0
while IFS= read -r d; do
  [ -z "$d" ] && continue
  stem=$(basename "$d")
  skill_files=$((skill_files + 1))
  grep -qE "^\| \`$stem\` \|" "$README" && continue
  table_missing="$table_missing
    ${d#"$ROOT"/}/SKILL.md — no row in the README table"
done <<< "$SKILL_DIRS"

if [ "$skill_files" -eq 0 ]; then
  bad "README skill table — no skill directories found under skills/; this assertion did NOT run"
elif [ -n "$table_missing" ]; then
  bad "README skill table — a skill is published and has no row in the table a forker reads:$table_missing
      The counts above can be green while this is wrong: fixing the number a count failure quotes does not add the row.
      Fix by re-running \`hooks/scripts/skills-table.py\` and replacing the table — not by hand-writing the row."
else
  ok "README skill table — all $skill_files skill files have a row"
fi

# DIRECTION 2 — every row has a file. Catches a DELETED skill whose row stayed, which is the direction
# that goes stale silently: nothing about deleting a file makes anyone open the README, and no count
# assertion moves if the row is still there while the total is restated correctly elsewhere.
table_orphans=""
table_rows=0
while IFS= read -r row; do
  [ -z "$row" ] && continue
  table_rows=$((table_rows + 1))
  # SPLIT ON CELLS, NEVER ON A GREEDY `.*` — a corrected defect, kept in this shape after #286 for the
  # same reason it was written: a greedy span walks past the cell you meant to the last one on the row.
  # Escaped pipes inside the description (`\|`) are neutralised first, so the field split is on real
  # cell boundaries only.
  r_skill=$(printf '%s' "$row" | sed 's/\\|/§/g' | awk -F'|' '{gsub(/[ `]/,"",$2); print $2}')
  [ -z "$r_skill" ] && continue
  if [ -z "$(skill_file "$r_skill")" ]; then
    table_orphans="$table_orphans
    the table lists \`$r_skill\` — no skills/$r_skill/SKILL.md exists"
  fi
done <<< "$(grep -E "$skill_rows_re" "$README" 2>/dev/null || true)"

if [ "$table_rows" -eq 0 ]; then
  bad "README skill table — the row pattern matched NOTHING; the table moved or changed shape, and direction 2 did not run"
elif [ -n "$table_orphans" ]; then
  bad "README skill table — a row names a skill file that is not in the tree:$table_orphans
      A skill was deleted or moved and its row stayed. Re-run \`hooks/scripts/skills-table.py\` and replace the table."
else
  ok "README skill table — all $table_rows rows name a skill file that exists"
fi

# --- the roster's MEMBERSHIP, not its cardinality ----------------------------------------------
#
# THE DEFECT: `security` was deleted from `agents/` and `harness-lead` was added in the same slice.
# The roster count held at five. Every assertion above it — `"$agents subagent personas"`, the EVERY-
# occurrence sweep, the lead-count word, the gate-coverage diff — stayed green through a change that
# **swapped one persona for another**, and `docs/adr/0002` was left enumerating a roster that no longer
# exists, including the sentence *"both approvals are still required"*: a record describing a control as
# STRONGER than it is, which is the direction that fails open.
#
# A COUNT IS NOT AN IDENTITY. Every check above is cardinality — a number of files, a number of rows, a
# number spelled as an English word. Cardinality is invariant under substitution, and substitution is the
# roster change this repo actually keeps making: six merges and two outright retirements in three weeks,
# every one of them a name changing rather than a total.
#
# ── THE SETS ARE DERIVED. BOTH OF THEM. ─────────────────────────────────────────────────────────
# LIVE is `agents/*.md`, as everywhere else in this file. RETIRED is `git log --diff-filter=D` over the
# same glob, minus LIVE — every name that once had a persona file and no longer does. Neither is written
# here, for the reason the family loop above records: an enumeration inside the file written to catch
# stale enumerations is this suite's signature defect, and it has now been paid for twice.
#
# THE COST OF DERIVING RETIRED FROM HISTORY IS A CLONE DEPTH, and it is asserted rather than assumed.
# On `fetch-depth: 1` the log returns nothing, RETIRED is empty, and an absence check over an empty set
# of names is green for no reason at all. `docs-test.yml` sets `fetch-depth: 0` and the guard below
# fails loudly if it is ever removed.
roster_live=$(find "$ROOT/agents" -maxdepth 1 -name '*.md' -type f -exec basename {} .md \; | sort -u)
roster_n=$(printf '%s\n' "$roster_live" | grep -c . || true)
roster_deleted=$(git -C "$ROOT" log --diff-filter=D --name-only --pretty=format: -- 'agents/*.md' 2>/dev/null \
  | sed -nE 's#^agents/([A-Za-z0-9._-]+)\.md$#\1#p' | sort -u | grep -v '^$' || true)
roster_retired=$(comm -23 <(printf '%s\n' "$roster_deleted" | grep -v '^$' || true) <(printf '%s\n' "$roster_live"))

roster_live_alt=$(printf '%s\n' "$roster_live" | paste -sd'|' - | tr -d ' ')
roster_retired_alt=$(printf '%s\n' "$roster_retired" | grep -v '^$' | paste -sd'|' - | tr -d ' ')

# THE SHALLOW-CLONE GUARD SITS WITH THE ONE ASSERTION IT GUARDS, NOT AT THE TOP OF THE BLOCK.
#
# It was `elif [ -z "$roster_retired_alt" ]` here until #283 slice 2's re-sweep, above FOUR verdicts of
# which only ONE — assertion 2, the stale-enumeration scan — reads the retired set at all. Assertions 1
# and 1b derive from `agents/*.md` and are fully computable on a shallow clone, and they DISAPPEARED
# with it: measured, a `git clone --depth 1` of this branch with `\`writer\`` unbackticked throughout
# `agents/developer.md` reports `59 passed, 1 failed` — byte-identical to the clean shallow run — while
# the same defect on a full clone is caught (`62 passed, 1 failed`, assertion 1b red). A real defect in
# a live brief, invisible, because an unrelated guard fired above it. See THE CHAINING RULE in the
# header: a shallow clone makes the RETIRED-set scan uncomputable and nothing else here.
if [ "$roster_n" -lt 2 ]; then
  bad "roster membership — only $roster_n persona file(s) found under agents/; the assertions below would be trivial"
else
  ok "roster membership — $roster_n live personas derived from agents/"

  # SCAN SET: the tracked-file set already derived for the floor-claim scan, minus `*.test.sh`.
  #
  # REUSED RATHER THAN DERIVED AGAIN, deliberately: `gate coverage` below asserts that every file in
  # FLOOR_CLAIM_FILES is matched by `docs-test.yml`'s `paths:` filter, and a SUBSET of a covered set is
  # covered. Deriving a second set here would have re-opened exactly the hole that assertion exists to
  # close — two independently-maintained sets, one filter, and nobody diffing them.
  #
  # `*.test.sh` is excluded for the reason the lead-count scan gives: a suite's fixtures are deliberately
  # wrong strings. `permission-guard.test.sh` names retired personas as case attribution, and this file's
  # own comments name them as the defect they describe.
  #
  # `docs/**` IS IN. That is the change. The lead-count scan above excludes it on the ground that a record
  # narrates history — and that ground is real, which is why the line filter below exists rather than a
  # blanket exclusion. Excluding `docs/` here would have excluded the only layer the defect landed in.
  roster_scan_files=$(printf '%s\n' "$FLOOR_CLAIM_FILES" | grep -v '\.test\.sh$' | grep -v '^$' || true)

  # ── WHAT MAKES A LINE OR A FILE "ENUMERATE THE ROSTER" ────────────────────────────────────────
  # A backticked name is how this repo writes a persona reference, everywhere, without exception. So the
  # unit is `` `name` `` and not the bare word — which also keeps `per-route \`security\`` in the API
  # Gateway skill (an OpenAPI keyword) from being read as the retired gatekeeper, and keeps the ordinary
  # English words `developer` and `performance` out of it entirely.
  #
  # THE THRESHOLD IS N−1, DERIVED FROM THE ROSTER SIZE. A file or line naming all but one of the live
  # personas is enumerating the roster; nothing else in this tree does that by accident. Measured on the
  # current head: it selects the four documents that publish the roster and no others, and at line level
  # it selects the ADR's roster lines and no prose.
  #
  # WHY NOT "NAMES TWO OR MORE": measured, that fires on ~60 lines of ordinary prose — "`security`
  # discovered that `Edit(.claude/**)`", "`marketing-lead` merged into `product-lead`" — most of them
  # correct attributions of a past finding to the persona that made it. A check that cries wolf on
  # accurate prose trains people to ignore it, and an ignored check also looks like coverage.
  roster_threshold=$((roster_n - 1))

  # ── ASSERTION 1: a document that PUBLISHES THE COUNT must name every member ───────────────────
  # This is the weaker direction and it is stated as such. It catches an ADDED persona that a roster
  # document was never updated for. It would NOT have caught the defect above — `docs/adr/0002` gained
  # no wrong name, it kept an old one — which is why assertion 2 exists and is the point of this block.
  #
  # THE SELECTION RULE IS DEFINITIONAL, NOT A HEURISTIC, and the first draft got this wrong in a way
  # worth recording. It selected "any file naming N−1 or more live personas", on the theory that a
  # document naming most of the roster is enumerating it. Measured, that selected seven files including
  # `hooks/scripts/permission-guard.sh` — which names four personas because it maps them to permission
  # rules, not because it publishes a roster. A selection rule that pulls in a file with no roster to
  # publish makes the assertion arbitrary, and an arbitrary red is the cry-wolf failure one step earlier
  # than a false positive.
  #
  # The rule used instead is the one this whole block is named after: **a document that publishes the
  # CARDINALITY has taken on the MEMBERSHIP.** Selection is therefore the same claim the EVERY-occurrence
  # sweep above already pins — `<N> subagent personas` — read out of the file rather than listed here.
  #
  # WHAT THAT LEAVES UNCHECKED, said plainly. `plugin.json` and `marketplace.json` publish the count too
  # and are NOT selected: they are not in the md/sh scan set, and they state the roster as prose
  # ("one fullstack developer", "a harness-lead") rather than in the backticked form this pattern
  # reads. Their count is asserted above; their membership is not asserted anywhere. Matching bare words
  # there would make `developer` — an ordinary English noun — pass on any sentence at all, which is a
  # green for the wrong reason rather than coverage.
  roster_publishers=$(printf '%s\n' "$roster_scan_files" | while IFS= read -r f; do
    [ -z "$f" ] && continue
    grep -qE '[0-9]+ subagent personas' "$f" 2>/dev/null && printf '%s\n' "$f"
  done)

  if [ -z "${roster_publishers//[[:space:]]/}" ]; then
    bad "roster membership — no tracked document publishes a '<N> subagent personas' count; assertion 1 selected nothing and did NOT run"
  else
    roster_incomplete=""
    while IFS= read -r file; do
      [ -z "$file" ] && continue
      named=$(grep -ohE "\`($roster_live_alt)\`" "$file" 2>/dev/null | tr -d '`' | sort -u)
      missing=$(comm -23 <(printf '%s\n' "$roster_live") <(printf '%s\n' "$named" | grep -v '^$') | tr '\n' ' ')
      [ -z "${missing// /}" ] && continue
      roster_incomplete="$roster_incomplete
    ${file#"$ROOT"/}: publishes the count, never names: ${missing% }"
    done <<< "$roster_publishers"

    if [ -z "$roster_incomplete" ]; then
      ok "roster membership — every document publishing the persona count names all $roster_n of them"
    else
      bad "roster membership — a document states how many personas there are and does not name them all:$roster_incomplete
      The count is invariant under a swap; the membership is not. Publishing the number is taking on the list."
    fi
  fi

  # ── ASSERTION 1b: EVERY PERSONA BRIEF NAMES EVERY OTHER PERSONA ──────────────────────────────
  #
  # THE HOLE THIS CLOSES IS IN THE CHECK ABOVE, NOT IN THE DOCS. Assertion 2 below decides that a
  # document "enumerates the roster" by COUNTING names on a line — N−1 or more. **A threshold is not a
  # membership either**, which is the same defect one layer down: `agents/tech-lead.md` and
  # `agents/developer.md` named THREE and TWO personas respectively, so neither was ever examined, and
  # both contained ZERO occurrences of the persona added that day. `tech-lead`'s brief still said
  # `product-lead` was its only counterpart. The check was green about them because it never looked.
  #
  # ── WHY THIS ONE NEEDS NO THRESHOLD, WHICH IS THE WHOLE POINT ────────────────────────────────
  # Assertion 2 has to GUESS which prose is an enumeration, because it scans ~100 files that are mostly
  # narrative. Here the selection is not a guess and not a heuristic: **`agents/*.md` IS the roster** —
  # each file is one member of it, derived from the filesystem, the same set `roster_live` comes from.
  # There is nothing to threshold. That is the general lesson worth carrying: when a rule keeps needing
  # a cutoff, look for the set the cutoff is approximating and assert over that instead.
  #
  # THE CLAIM, EXACTLY: a persona brief must name every OTHER live persona, backticked. Not itself —
  # a file whose front-matter `name:` is the subject does not backtick its own name, and requiring it
  # would fire on all five for a formatting habit rather than a fact.
  #
  # WHY THAT IS THE RIGHT OBLIGATION AND NOT BUSYWORK. A brief is where one persona's relationship to
  # the others is stated, and the failure mode is exact: a roster change leaves four briefs describing a
  # loop that no longer exists, each of them individually plausible. It is also the class of staleness
  # nothing else can catch — a brief is read by an agent in a fresh context that has no other source.
  # Naming a peer is cheap; the honest form of "I do not interact with X" is a sentence saying so, which
  # is exactly what a reader of that brief needs.
  #
  # ── WHAT THIS DELIBERATELY DOES **NOT** ASSERT, so the green is not read as more ─────────────
  # It does not reach `commands/`, `docs/` or the hook scripts. Measured on the current head, requiring
  # every-peer THERE would fire on fifteen files that legitimately mention two or three personas —
  # `skills/code-review/SKILL.md` naming the two gates, `docs/adr/0008` naming the two it is about.
  # Those are correct prose, and a check that reddens correct prose is the cry-wolf failure this file
  # already books once. The bound is written into assertion 2's own comment below; between the two,
  # `agents/` is covered by MEMBERSHIP and everything else by the weaker threshold, and neither is
  # described as covering the other.
  roster_brief_gaps=""
  while IFS= read -r persona; do
    [ -z "$persona" ] && continue
    brief="$ROOT/agents/$persona.md"
    [ -r "$brief" ] || continue
    named=$(grep -ohE "\`($roster_live_alt)\`" "$brief" 2>/dev/null | tr -d '`' | sort -u)
    # `comm` needs both sides sorted; `roster_live` already is, and the peer set is it minus self.
    peers=$(printf '%s\n' "$roster_live" | grep -vxF "$persona")
    missing=$(comm -23 <(printf '%s\n' "$peers") <(printf '%s\n' "$named" | grep -v '^$') | tr '\n' ' ')
    [ -z "${missing// /}" ] && continue
    roster_brief_gaps="$roster_brief_gaps
    agents/$persona.md never names: ${missing% }"
  done <<< "$roster_live"

  if [ -z "$roster_brief_gaps" ]; then
    ok "roster membership — every persona brief names all $((roster_n - 1)) of its peers"
  else
    bad "roster membership — a persona brief does not name a persona it shares the roster with:$roster_brief_gaps
      The roster changed and this brief did not. Say what the relationship IS — a peer it argues with, a
      tier it shares, or a persona it never meets — not just the name. A brief is read in a fresh context
      that has no other source, so a relationship it omits is one that does not exist for the reader."
  fi

  # ── ASSERTION 2: a roster-enumerating LINE must not name a persona that has no file ───────────
  # THE DIRECTION THAT ACTUALLY CAUGHT NOTHING. Renaming a persona file — the exact change that shipped
  # clean — leaves the old name standing in every document that lists the roster, and no count moves.
  #
  # ── THE TRAP, AND THE BOUND, STATED BEFORE THE CHECK RUNS ────────────────────────────────────
  # A RECORD IS ALLOWED TO NAME A RETIRED PERSONA. ADRs here are supersede-never-rewrite: `~~\`security\`
  # reviews every MR~~` is CORRECT prose and must not fire. Distinguishing a live claim from a struck one
  # is a reading of prose, and the honest answer is that this cannot do it in general. Measured on the
  # current head: ~400 backticked mentions of retired personas exist in this tree, 135 of them in `docs/`
  # survive every past-tense and negation marker I could write, and nearly all 135 are correct.
  #
  # SO THIS IS THE WEAKER CHECK, AND HERE IS ITS BOUND, PRECISELY:
  #
  #   IT FIRES ONLY ON A LINE THAT NAMES N−1 OR MORE LIVE PERSONAS. That is the shape of an enumeration
  #     of the CURRENT roster, and a retired name inside one is stale by construction — history is
  #     narrated one or two personas at a time, never as "the roster is A, B, C, D and <retired>".
  #     It therefore MISSES a stale claim about one persona ("`security` still reviews every MR", alone
  #     on its line). That miss is deliberate: catching it costs the 135 false positives above.
  #
  #     AND THE THRESHOLD DECIDES WHICH FILES ARE EXAMINED AT ALL, WHICH IS THE COSTLIER HALF —
  #     booked here rather than left to be rediscovered. **A threshold is not a membership**, the same
  #     defect as the count it was written to replace, one layer down: a file naming FEWER than N−1
  #     personas is never read by this assertion, so it can name a retired one, or omit a live one,
  #     entirely unobserved. Measured when this was written: `agents/tech-lead.md` (3) and
  #     `agents/developer.md` (2) both fell under the cutoff while containing zero occurrences of the
  #     persona added that day.
  #
  #     WHAT WAS DONE ABOUT IT, AND WHAT WAS NOT. Lowering the cutoff to two was measured and rejected —
  #     ~60 lines of accurate prose fire, and an ignored check also looks like coverage. Instead the
  #     file set where the cutoff was doing real damage got an assertion that needs no cutoff at all:
  #     **1b above asserts every-peer over `agents/*.md`, selected as a derived SET rather than by a
  #     text heuristic.** So: `agents/` is covered by membership; `commands/`, `docs/` and the hook
  #     scripts are covered only by this weaker line-level check, and for those the bound above stands
  #     unmitigated. Neither assertion is described as covering the other's ground.
  #
  #   IT DEPENDS ON THIS REPO'S STRIKE CONVENTION for the lines it does select. `~~…~~` and the
  #     past-tense markers below are what tell it a roster enumeration is history. A superseded roster
  #     narrated in plain present tense with no marker WILL fire — and that is the one direction where
  #     firing on correct prose is acceptable, because the remedy is to strike the line, which the
  #     records here already do everywhere the convention was followed.
  #
  # The durable fix for what this misses is the one the file keeps arriving at: a document that states
  # the roster by pointing at `agents/` rather than by listing it cannot go stale at all.
  roster_narr_re='~~|no longer|never|was |were |had |has been|have been|until |former|retire|absorb|supersed|struck|STRUCK|used to|replaced|\[example\]'
  roster_stale=""
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    [ -r "$file" ] || continue
    while IFS= read -r numbered; do
      [ -z "$numbered" ] && continue
      lineno="${numbered%%:*}"
      text="${numbered#*:}"
      printf '%s' "$text" | grep -Eq "$roster_narr_re" && continue
      n_live_here=$(printf '%s' "$text" | grep -ohE "\`($roster_live_alt)\`" | sort -u | grep -c . || true)
      [ "$n_live_here" -lt "$roster_threshold" ] && continue
      dead=$(printf '%s' "$text" | grep -ohE "\`($roster_retired_alt)\`" | sort -u | tr -d '`' | tr '\n' ' ')
      roster_stale="$roster_stale
    ${file#"$ROOT"/}:$lineno names ${dead% } beside $n_live_here live personas"
    done <<< "$(grep -nE "\`($roster_retired_alt)\`" "$file" 2>/dev/null || true)"
  done <<< "$roster_scan_files"

  # The shallow-clone guard, moved down from the top of the block to sit with the ONE assertion whose
  # input it is. An empty RETIRED set makes this scan vacuous and nothing else here vacuous.
  if [ -z "$roster_retired_alt" ]; then
    bad "roster membership — NO retired persona could be derived from git history, so this scan is vacuous: an absence check over an empty set of names is green for no reason at all. On a shallow clone \`git log --diff-filter=D\` returns nothing. Restore \`fetch-depth: 0\` on the checkout in .github/workflows/docs-test.yml"
  elif [ -z "$roster_stale" ]; then
    ok "roster membership — $(printf '%s\n' "$roster_retired" | grep -c . || true) retired personas derived from history, and no line enumerating the roster names one of them"
  else
    bad "roster membership — these lines list the CURRENT roster and include a persona that has no file:$roster_stale
      A persona was renamed or removed and this enumeration was not. The count did not move, so nothing else here could see it.
      If the line is NARRATING a superseded roster, strike it (\`~~…~~\`) or mark the tense — that is what tells this check it is history, and this repo's records already do it everywhere the convention was followed."
  fi
fi

# --- every file this suite SCANS must be a file the workflow can START on -----------------------
#
# THE REGRESSION TEST FOR THE CAUSE, NOT FOR THE INSTANCE. Four times now, a path has been added to
# `docs-test.yml`'s `paths:` filter after someone measured a specific miss — `hooks/**`,
# `.claude-plugin/**`, `docs/**`, and `PRINCIPLES.md`. Each fix was correct and none of them prevented
# the next, because the two sets were maintained independently: **the scan set was derived, the filter
# was extended by whichever miss got measured, and nobody diffed one against the other.**
#
# A file in the scan set but not the filter is the worst shape a gate has: the PR that introduces the
# defect is exactly the PR that cannot start the gate. Green on the way in, and never red afterwards.
#
# THIS IS A ONE-DIRECTION CHECK, DELIBERATELY. Filter ⊅ scan set is a hole; filter ⊃ scan set is only
# a workflow that sometimes runs with nothing to say, which costs a minute of CI and no correctness.
# Asserting equality would make `.github/workflows/docs-test.yml` — which the filter lists so the gate
# re-runs when the filter itself changes — a failure, and that entry is correct.
WORKFLOW="$ROOT/.github/workflows/docs-test.yml"
if [ ! -r "$WORKFLOW" ]; then
  bad "gate coverage — $WORKFLOW unreadable; this assertion did NOT run"
elif [ -z "${FLOOR_CLAIM_FILES//[[:space:]]/}" ]; then
  bad "gate coverage — the scan set is EMPTY; this assertion would pass vacuously"
else
  # The globs, read from the workflow rather than restated here — restating them is the very
  # duplication that produced the drift.
  filter_globs="$(sed -n '/^  *paths:/,/^[^ #]/p' "$WORKFLOW" | sed -nE 's/^ *- "(.*)"$/\1/p')"
  if [ -z "$filter_globs" ]; then
    bad "gate coverage — no paths: globs parsed from docs-test.yml; the file changed shape and this assertion did NOT run"
  else
    # THE SCAN SET IS NOT `FLOOR_CLAIM_FILES` ALONE, and believing it was is how this assertion sat
    # green with a hole in it. `FLOOR_CLAIM_FILES` is `git ls-files -- '*.md' '*.sh'`, so EVERY source
    # this suite reads that is not markdown or shell was invisible to the check meant to cover it.
    #
    # That produced the FIFTH occurrence of the miss this check exists to prevent, and the first one
    # invisible to the instrument built for it: a PR changing only `.claude/settings.json` could not
    # start the workflow whose suite asserts against `.claude/settings.json`. Measured on
    # tedeuxx/tadeumendonca-skills#150, which changed exactly that file and started no gate.
    #
    # THE UNION IS BUILT FROM THE VARIABLES, NOT FROM MEMORY, and that is the whole correction. The
    # first attempt at this fix added `$SETTINGS` alone and its comment called the enumeration
    # complete — 2 of 6 — inside the file whose stated lesson is that incomplete self-enumeration is
    # the defect. The reviewer found the other four with `grep -n 'ROOT/'`, which is the method that
    # should have produced this list in the first place. All six are already in scope here; none was
    # omitted for being hard to reach.
    #
    # NOT CLAIMED COMPLETE. If a seventh source is added above and not added here, this check goes
    # quietly back to covering a subset, and nothing in this file will say so. A self-grep asserting
    # every `"$ROOT/…"` literal is a member was considered and deliberately not built: extracting
    # paths from shell text is heuristic — it would flag directory operands and interpolated paths
    # like `$ROOT/commands/$r_fam/…` — and a check wrong more often than right is one the loop
    # learns to silence, which is the failure this repo has already rejected once.
    scanned_files="$FLOOR_CLAIM_FILES
$CITATION_FILES
$SETTINGS
$HOOKS_JSON
$WORKFLOW
$(printf '%s\n' "${INVENTORY_DOCS[@]}")"

    uncovered=""
    while IFS= read -r file; do
      [ -z "$file" ] && continue
      rel="${file#"$ROOT"/}"
      matched=""
      while IFS= read -r glob; do
        [ -z "$glob" ] && continue
        case "$glob" in
          */\*\*) [ "${rel#"${glob%\*\*}"}" != "$rel" ] && matched=yes ;;
          *)      [ "$rel" = "$glob" ] && matched=yes ;;
        esac
        [ -n "$matched" ] && break
      done <<< "$filter_globs"
      [ -z "$matched" ] && uncovered="$uncovered
    $rel"
    done <<< "$scanned_files"

    if [ -z "$uncovered" ]; then
      ok "gate coverage — every file the floor-claim scan reads is matched by docs-test.yml's paths: filter"
    else
      bad "gate coverage — these files are SCANNED by this suite but cannot START its workflow:$uncovered
      A PR touching only such a file can introduce the defect this suite exists to catch and never run it.
      Add the path to .github/workflows/docs-test.yml's paths: filter — do not narrow the scan set to match."
    fi
  fi
fi

# ---------------------------------------------------------------------------------------------------
# EVERY PERSONA BRIEF STATES WHERE ITS WORKING FILES GO — FLIPPED AT #245.
#
# A rule that lives only in CLAUDE.md does not reach a subagent: CLAUDE.md is the MAIN agent's context,
# and a persona's context is its own brief. THIS USED TO ASSERT AN OVERRIDE — a repo-root `.scratch/`
# the brief had to state explicitly WINS over the harness's own session-scratchpad instruction, because
# on 2026-08-06 subagents followed the harness's instruction correctly and it was the wrong answer at
# the time. #245 retired the repo-root directory once #244 measured that the friction it existed to
# dodge never depended on location at all — so the harness's own instruction is now the right answer,
# and there is nothing left to override. What survives is the other half of the original reasoning:
# CLAUDE.md still cannot reach a subagent, so the brief still has to state the destination itself, in
# its own words, or a fresh dispatch has no way to know it.
#
# ONE PERSONA IS A GENUINE EXCEPTION, NOT AN OVERSIGHT. `product-lead` holds no `Write`/`Edit` grant and
# writes no scratch file at all by design (its verdict returns as text; `quality-assurance` quotes it
# onto the PR verbatim) — asserting "session scratchpad" against it would demand a sentence describing a
# capability the brief deliberately does not have.
for brief in "$ROOT"/agents/*.md; do
  name="$(basename "$brief")"
  if [ "$name" = "product-lead.md" ]; then
    if grep -qiF -- 'you write no scratch file' "$brief"; then
      ok "agent brief — $name states its exception: no Write/Edit, writes no scratch file"
    else
      bad "agent brief — $name is expected to state it writes no scratch file at all (no Write/Edit grant).
      If that has changed — the persona now holds Write/Edit — this whole exception is stale; give it the
      ordinary 'session scratchpad' assertion below instead."
    fi
    continue
  fi
  if grep -qiF -- 'session scratchpad' "$brief"; then
    ok "agent brief — $name names the session scratchpad as where its working files go"
  else
    bad "agent brief — $name does not name the session scratchpad as where its working files go.
      CLAUDE.md cannot carry this rule to a subagent; only the brief can."
  fi
done

# ---------------------------------------------------------------------------------------------------
# THE TWO HOOKS PARSE `-R`/`--repo` WITH THE SAME CHARACTER CLASS.
#
# `permission-guard.sh` defines `gh_repo_flag` and interpolates it into every `gh` rule; `wip-guard.sh`
# writes the same class inline, twice, because a hook cannot source a variable out of another hook.
# They are DUPLICATED LITERALS, and `wip-guard.sh` claimed otherwise — its comment said a sixth spelling
# would be "fixed in one place and both hooks move". Measured false: editing one file alone leaves the
# other behind and both suites stay green.
#
# THIS IS WHAT MAKES THE CLAIM TRUE, and it is deliberately weaker than the sentence it replaces. It
# does not make them move together — nothing can. It makes them unable to DRIFT APART in silence, which
# is the property that was actually missing: `wip-guard` spent a week a spelling behind `permission-guard`
# on exactly this flag, and no check anywhere could say so.
# THE ANCHOR IS DELIBERATELY LOOSER THAN THE CLASS IT COMPARES. Anchoring on the full literal made
# the third branch DEAD BY CONSTRUCTION: both sides searched for the same fixed string, so `grep -oE`
# could only ever emit that string and `grep -qvxF` had nothing to find. Measured — mutating one file
# reached branch 2, mutating both reached branch 2, mutating the guard reached branch 1, and branch 3
# never fired. Matching `(` + the flag + anything-up-to-`)` lets the two sides emit DIFFERENT text,
# which is the only way a difference can be reported at all.
guard_class="$(grep -oE '\((-R|--repo)[^)]*\)' "$ROOT/hooks/scripts/permission-guard.sh" | head -1)"
wip_classes="$(grep -oE '\((-R|--repo)[^)]*\)' "$ROOT/hooks/scripts/wip-guard.sh")"
wip_count="$(printf '%s' "$wip_classes" | grep -c . || true)"

# TWO SUBJECTS, TWO INDEPENDENT VERDICTS — see THE CHAINING RULE in this file's header.
#
# HOW MANY copies wip-guard.sh carries and WHETHER they match permission-guard.sh are different
# assertions, and they were one `if/elif` chain until #283 slice 2's re-review. A wrong count returned
# `bad` from the second arm, so the drift comparison below it was never reached and emitted NEITHER
# `PASS` NOR `FAIL`. Measured, not argued: mutating wip-guard.sh with two independent defects at once —
# the trigger's flag segment deleted (count 2 → 1) and the extraction's class drifted (`=` dropped) —
# reported ONLY `carries 1 copies of the class` at `62 passed, 1 failed`. The drift was real, present,
# and computable from a one-element list, and no verdict said so.
#
# This is the same defect as 4a/4b in the citation block and as the numbering pair, and it shipped in
# the SWEEP that fixed those two: the sweep cleared this chain by re-reading its own justification
# instead of mutating it. A reason that survives re-reading is not evidence.
#
# The vacuity guard is repeated in both arms rather than shared, for the reason the header gives: a
# permission-guard.sh with no class at all makes BOTH verdicts vacuous, so both must redden.

# ── how many copies wip-guard.sh carries ──
if [ -z "$guard_class" ]; then
  bad "flag class — permission-guard.sh no longer contains the shared -R/--repo class this asserts on,
      so the copy count below cannot be judged against anything.
      If it was deliberately reshaped, reshape this assertion with it — do not delete it: the drift it
      catches is the one that already happened once."
elif [ "$wip_count" -ne 2 ]; then
  bad "flag class — wip-guard.sh carries $wip_count copies of the class, expected 2 (trigger + extraction).
      A copy that disappeared is a parse that silently narrowed."
else
  ok "flag class — wip-guard.sh carries both copies of the -R/--repo class (trigger + extraction)"
fi

# ── and whether they are the SAME class as permission-guard.sh's ──
# Judged over whatever copies exist, deliberately, rather than only when the count is right: a copy that
# went missing AND a copy that drifted are two defects, and the second must not wait on the first being
# repaired. `wip_classes` empty is the one state where this is genuinely uncomputable — an empty list has
# nothing to compare — so it is a guard here rather than a silent pass.
if [ -z "$guard_class" ] || [ -z "$wip_classes" ]; then
  bad "flag class — the -R/--repo class could not be extracted from
      $([ -z "$guard_class" ] && printf 'permission-guard.sh ')$([ -z "$wip_classes" ] && printf 'wip-guard.sh ')— nothing was
      found to compare, so a green here would be an artifact of the break and not a finding."
elif printf '%s\n' "$wip_classes" | grep -qvxF -- "$guard_class"; then
  bad "flag class — wip-guard.sh and permission-guard.sh parse the repo flag DIFFERENTLY.
      permission-guard: $guard_class
      wip-guard:        $(printf '%s' "$wip_classes" | tr '\n' ' ')
      One of them is a spelling behind. That is how \`gh -R=owner/x pr create\` turned wip-guard off."
else
  ok "flag class — every copy in wip-guard.sh parses -R/--repo with permission-guard.sh's identical class"
fi

# ---------------------------------------------------------------------------------------------------
# EVERY SKILL CARRIES A `description` WRITTEN TO INDEX, NOT A TITLE (#166).
#
# WHY THIS IS AN INVENTORY CONCERN AT ALL. Commands were merged into skills, and model-invoked loading
# matches on the `description` field. A skill without one competes without the field that decides, so
# `description` is now part of what this repo PUBLISHES — the same class as a count on the README, and
# it rots the same way: nothing about adding a skill makes anyone write a trigger sentence for it.
#
# THE STANDARD IS harness-lead's, ON #166, AND THESE ARE ITS THREE LEVELS. What is asserted here is
# deliberately only the mechanical half. The standard names the authorial half explicitly — whether the
# situation named is the RIGHT one, whether the technology nouns are the ones a real task would contain,
# whether `Not for` points at the NEAREST rival, and whether the description is TRUE about the body —
# and refuses, by name, any quality score built out of keyword counts, noun density or embedding
# similarity, because ALL OF THEM PASS ON KEYWORD SALAD. That refusal is honoured here: nothing below
# scores a description. A green means the shape is right, never that the sentence is good.

# ── THE SCAN SET IS BOTH TREES, AND THE KEY IS THE PARENT DIRECTORY (#164, finding 2) ──────────────
# THE OBVIOUS REPAIR FOR THE MOVE IS THE ONE THAT BREAKS THIS BLOCK SILENTLY, and it was measured before
# it could ship. Repointing `find` at `skills/` alone restores the file SET and destroys the file KEY:
# every path is `skills/<stem>/SKILL.md`, so a basename stem is the string SKILL for all 69, and the two
# assertions below that are keyed on the stem stop meaning anything. `harness-lead` mutated the
# source to prove it — a stem-opener added to `routing`'s description, `argument-hint:` deleted from
# `autonomy-on` — and BOTH SURVIVED, under a PASS line asserting the property just removed. Zero reds.
#
# So the stem comes from the PARENT DIRECTORY for a library skill, and from the basename for a typed
# command. And the two typed commands are kept IN the set as a second source rather than dropped with
# the directory they no longer share: the positive `argument-hint` assertion can only run on a file the
# loop opens, so a scan that stops at `skills/` silences it by never looking.
#
# THE RE-KEY WAS RE-MUTATED AFTER THE MOVE, both cases, and both go red. An assertion is only real once
# it has been seen to fail, and this file has found four that could not fail in a single day.
SKILL_FILES="$(
  find "$ROOT/skills" -name 'SKILL.md' -type f 2>/dev/null
  find "$ROOT/commands" -maxdepth 1 -name '*.md' -type f 2>/dev/null
)"
SKILL_FILES="$(printf '%s\n' "$SKILL_FILES" | sort)"

# The invocation name, which is what every assertion below is about. `skills/<stem>/SKILL.md` -> `<stem>`
# (the loader takes the innermost directory); `commands/<stem>.md` -> `<stem>`.
skill_stem() {
  case "$1" in
    */SKILL.md) basename "$(dirname "$1")" ;;
    *)          basename "$1" .md ;;
  esac
}

ARG_HINT_ALLOWED="autonomy-on autonomy-off new-issue"   # the three the OWNER types; a model-invoked skill has no typed argument

# The frontmatter block, exclusive of its `---` fences. Empty for a file that has none, which is what
# the presence assertion below reads.
fm_block() {
  awk 'NR==1 && $0 != "---" { exit } NR==1 { infm=1; next } infm && $0 == "---" { exit } infm' "$1"
}

# ── THE VACUITY GUARD IS A FLOOR, NOT AN EMPTINESS TEST ─────────────────────────────────────────────
# IT USED TO FIRE ONLY ON ZERO, AND ZERO IS NOT HOW THIS SCAN LOSES ITS SUBJECT. Measured by
# `harness-lead` on #164 against a simulation of the flat `skills/` layout: `find $ROOT/commands`
# returns TWO files, the suite prints `38 passed, 10 failed`, and all ten reds are elsewhere — the
# counts, the README table, the loop-engineering tripwire. Meanwhile the three controls anchored on
# this file set print, in these words:
#
#     PASS  skill descriptions L1 — all 2 parse...
#     PASS  skill descriptions L2 — all 2 are triggers, not titles...
#     PASS  consumer references — all 2 skill files are project-agnostic...
#
# #166's description standard, #167's project-agnostic lint and the `(see X)` resolver stop covering 69
# of 71 files and SAY SO IN A GREEN. Whoever repairs the ten reds has no reason to open this block.
# A GUARD THAT CATCHES ONLY ZERO CANNOT CATCH A SCOPE THAT SHRANK BY 97 PERCENT.
#
# THE EXPECTATION IS DERIVED, AND DELIBERATELY NOT FROM THE SCAN ITSELF. Deriving it by counting the
# same `find` would be a tautology that can never fail; writing it as a literal makes it the next thing
# to go stale, which is the defect this whole file exists to catch. So it comes from the two places
# that already state the library's size for a reason of their own:
#
#   - THE PUBLISHED FIGURE — the count this repo prints on its front door, read out of the same four
#     inventory documents `check_every_occurrence` reads, with the same pattern. Those four are already
#     required to agree with the family walk, so this borrows a number that is independently pinned.
#   - THE TYPED-COMMAND ENUMERATION — `ARG_HINT_ALLOWED`, counted rather than assumed. The published
#     figure counts the LIBRARY only ("<N> skills + autonomy-on"), so the two owner-typed commands have
#     to be added back, and this file already maintains the list of exactly which they are. #165's
#     `autonomy-off` moves both numbers in the same commit, as it should.
#
# WHAT IT CATCHES: any shrink of the scan set that the documents have NOT been told about — a move to
# another directory, a deletion, a `find` whose path stopped resolving. WHAT IT DELIBERATELY DOES NOT:
# a shrink the docs were updated for in the same commit, which is a reviewed removal and not a silent
# one — and a GROWTH, because a floor is one-sided on purpose. An added skill is caught by the count
# assertions above, in a message that names the documents to edit.
#
# ONE THING IT NOW COVERS THAT NOTHING DID: deleting `commands/autonomy-on.md` used to remove the file
# from the scan set, which is the ONE way to silence L1's POSITIVE `argument-hint` assertion — the loop
# never opens a file it cannot see. The floor counts the typed commands independently of the scan, so
# the deletion is a shortfall rather than an absence.
published_skills="$(grep -ohE '[0-9]+ ([a-z-]+ ){0,2}skills' "${INVENTORY_DOCS[@]}" 2>/dev/null \
                      | grep -oE '^[0-9]+' | sort -n | tail -1)"
typed_cmds="$(printf '%s\n' $ARG_HINT_ALLOWED | grep -c . || true)"
scanned_skills="$(printf '%s\n' "$SKILL_FILES" | grep -c . || true)"
expected_skills=$((published_skills + typed_cmds))

if [ -z "$published_skills" ]; then
  bad "skill descriptions — no published skill count could be read out of the inventory documents, so the
      floor below has nothing to compare against and every assertion in this block would run unbounded.
      Either the figure stopped being published or its phrasing left the pattern; restore one of them."
else
  # THE SHORTFALL IS ITS OWN VERDICT, AND IT WITHHOLDS THE GREENS BELOW RATHER THAN SUPPRESSING THEM.
  #
  # It was `elif` above the whole block until #283 slice 2's re-sweep, and that lost real findings:
  # measured, holding `skills/license/` out of the tree AND deleting the `description:` line from
  # `skills/frontend/SKILL.md` reports ONLY the shortfall (`53 passed, 7 failed`) — the L1 defect, in a
  # file that IS in the truncated set and IS parseable, emits nothing. The same defect alone on a full
  # tree is caught (`62 passed, 1 failed`, L1 red).
  #
  # BUT THE ORIGINAL CHAIN WAS NOT MERELY WRONG, AND THAT IS WHY THE FIX IS NOT A PLAIN SPLIT. L1/L2/L3
  # are UNIVERSALS over the scan set — `all $desc_count parse` — so a green printed over a truncated set
  # is a false claim about coverage, which is the #164 defect this guard was built for and is recorded
  # above verbatim (`PASS skill descriptions L1 — all 2 parse...`). Splitting naively would restore it.
  #
  # So the shortfall governs the direction where it is genuinely unsound and no further: the PASS. A
  # problem found in the truncated set is a TRUE finding about a real file and still reports; a clean
  # sweep of a truncated set is not reported as clean. Both directions are red while the set is short,
  # deliberately — the same reading as the duplicated vacuity guards elsewhere in this file.
  scan_short=""
  if [ "$scanned_skills" -lt "$expected_skills" ]; then
    scan_short="the scan set is short by $((expected_skills - scanned_skills)) file(s)"
    bad "skill descriptions — the scan found $scanned_skills file(s) across skills/ and commands/, and the repo publishes
      $published_skills skill(s) plus $typed_cmds typed command(s) = $expected_skills. Every assertion in this block is
      anchored on that set, so it is now covering LESS than the library and its GREENS are withheld below.
      If the library MOVED, repoint the scan in this same commit. If files were deliberately removed,
      the published figure moves with them — and then this goes green because the shrink is on record."
  else
    ok "skill descriptions — the scan set covers all $expected_skills files the repo publishes ($published_skills skills + $typed_cmds typed commands), so the levels below quantify over the whole library"
  fi

  # --- LEVEL 1: presence and parse, zero judgement ------------------------------------------------
  # Length bounds are a FLOOR AND A CEILING, NOT A QUALITY METRIC, and the standard says so in those
  # words. 120 is below anything that can carry an act, an object and a `Use when`; 500 is above the
  # longest written. They catch an empty stub and a pasted paragraph. They cannot catch a bad sentence
  # of the right size, and are not intended to.
  DESC_MIN=120
  DESC_MAX=500

  l1_problems=""
  l2_problems=""
  desc_count=0
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    rel="${f#"$ROOT"/}"
    stem="$(skill_stem "$f")"
    fm="$(fm_block "$f")"

    if [ -z "$fm" ]; then
      l1_problems="$l1_problems
    $rel — no frontmatter block (must open AND close with ---)"
      continue
    fi

    desc_line="$(printf '%s\n' "$fm" | grep -m1 '^description:' || true)"
    if [ -z "$desc_line" ]; then
      l1_problems="$l1_problems
    $rel — frontmatter carries no 'description:' key"
      continue
    fi
    desc="${desc_line#description:}"
    desc="${desc# }"
    if [ -z "$desc" ]; then
      l1_problems="$l1_problems
    $rel — 'description:' is present and EMPTY"
      continue
    fi
    desc_count=$((desc_count + 1))

    # ONE PHYSICAL LINE — three checks, and the third is the one that was MISSING while this comment
    # claimed it. Recorded rather than quietly added, because the defect WAS the record:
    #
    #   THIS BLOCK USED TO SAY "the key appears once and the line after it is either the closing fence
    #   or another key" AND IMPLEMENT ONLY THE FIRST TWO. Measured on #168 by the merge gate: split
    #   `workflow/license.md`'s description at its last comma, so `Use when` stayed on line 1 and the
    #   remainder wrapped onto line 2. PyYAML parses that as ONE value of 305 chars — plain scalars
    #   continue across lines — while this block measured only the 248-char first line. The suite
    #   printed `61 passed, 0 failed` and, worse, `PASS … are one line` about a description that was
    #   not one line. THE LENGTH BOUND HAD SILENTLY APPLIED TO A FRAGMENT.
    #
    #   Exposure was zero — no file is written that way — and that is exactly what made it dangerous:
    #   an assertion describing a check nobody had implemented, green for a reason no one would look
    #   behind. Same class as this file's other corrections, reached from a new direction.
    #
    # WHY A WRAPPED LINE MATTERS AND IS NOT PEDANTRY: the matcher receives the FULL parsed value, so a
    # wrap defeats the length bound — and it defeats every `case` test below too. `Use when`, the
    # consumer-path lint and `(concept)` all match against `$desc`, which is the first line only. One
    # wrap and half the L2 set stops looking at half the sentence.
    if [ "$(printf '%s\n' "$fm" | grep -c '^description:')" != "1" ]; then
      l1_problems="$l1_problems
    $rel — more than one 'description:' line"
    fi
    if printf '%s\n' "$fm" | grep -qE '^description:[[:space:]]*[|>]'; then
      l1_problems="$l1_problems
    $rel — description uses a block scalar (| or >); it must be one physical line"
    fi
    # THE LINE AFTER THE KEY. `fm` excludes the `---` fences, so "the closing fence" is simply the end
    # of the block — no next line at all. Anything else must be another key. A continuation line is
    # neither, which is what fires.
    next_line="$(printf '%s\n' "$fm" | awk '/^description:/ { getline nxt; print nxt; exit }')"
    if [ -n "$next_line" ] && ! printf '%s' "$next_line" | grep -qE '^[A-Za-z][A-Za-z0-9_-]*:'; then
      l1_problems="$l1_problems
    $rel — the line after 'description:' is neither the end of the frontmatter nor another key, so the
      value CONTINUES onto it. YAML reads the whole thing; every check here reads only the first line."
    fi

    # NO UNQUOTED COLON — the failure the standard names in its own words: `description: Foo: bar` is a
    # YAML parse error. THIS IS STRICTER THAN YAML, DELIBERATELY. YAML only breaks on a colon FOLLOWED
    # BY SPACE, so `https://x` is legal in a plain scalar. The rule is written as "no colon" because an
    # author applying it should not have to know YAML's plain-scalar grammar to get it right, and
    # nothing in these 75 descriptions needs one. A description that genuinely needs a colon can quote
    # itself, which is why the quoted form is exempted rather than forbidden.
    case "$desc" in
      \"*|\'*) : ;;   # explicitly quoted — YAML owns the escaping, nothing to check
      *:*)
        l1_problems="$l1_problems
    $rel — unquoted description contains ':' (YAML parse hazard); rephrase or quote the value" ;;
    esac

    len=${#desc}
    if [ "$len" -lt "$DESC_MIN" ] || [ "$len" -gt "$DESC_MAX" ]; then
      l1_problems="$l1_problems
    $rel — description is $len chars, outside the $DESC_MIN-$DESC_MAX bound"
    fi

    case "$desc" in
      *'$ARGUMENTS'*)
        l1_problems="$l1_problems
    $rel — description contains \$ARGUMENTS; it is matched against, not interpolated" ;;
    esac

    # `argument-hint` BOTH DIRECTIONS. Positive so the two typed commands cannot silently lose theirs,
    # negative because the standard calls carrying it to a model-invoked skill cargo cult — there is no
    # typed argument to hint at. (Whether it also influences matching is unmeasured, and labelled a
    # hypothesis there; nothing here depends on the answer.)
    has_hint=""
    printf '%s\n' "$fm" | grep -q '^argument-hint:' && has_hint=yes
    allowed=""
    for a in $ARG_HINT_ALLOWED; do [ "$stem" = "$a" ] && allowed=yes; done
    if [ -n "$allowed" ] && [ -z "$has_hint" ]; then
      l1_problems="$l1_problems
    $rel — is user-typed and LOST its argument-hint"
    elif [ -z "$allowed" ] && [ -n "$has_hint" ]; then
      l1_problems="$l1_problems
    $rel — carries argument-hint; only these are typed by the owner: $ARG_HINT_ALLOWED"
    fi

    # --- LEVEL 2: the anti-title assertions, which encode the MEASURED defects of the 75 first lines --
    #
    # THE CONSUMER-PATH CHECK NO LONGER LIVES HERE. It was frontmatter-scoped on #166 for a stated
    # reason — 43 of 75 BODIES carried `apps/fed` / `apps/bff`, and a file-wide assertion would have
    # reddened this suite against work nobody had scheduled. #167 cleaned the bodies, so the scope
    # widened to the whole file and the check moved to its own block below. The rest of L2 stays
    # description-scoped, because "is this a trigger and not a title" is a question about the
    # description only.
    case "$desc" in
      *'(concept)'*)
        l2_problems="$l2_problems
    $rel — description carries '(concept)', which means nothing to a matcher" ;;
    esac

    # THE SINGLE HIGHEST-VALUE ASSERTION IN THE SET, in the standard's words: `Use when` is the clause
    # that converts a title into a trigger, it is the exact defect of all 75 original first lines, and
    # IT CANNOT BE SATISFIED BY ACCIDENT. Same shape as the `overrides that` anchor above, for the same
    # reason — an anchor that a near-miss also satisfies is not an anchor.
    case "$desc" in
      *'Use when'*) : ;;
      *)
        l2_problems="$l2_problems
    $rel — description has no 'Use when' clause, so it names an artifact and not a situation" ;;
    esac

    # DOES NOT OPEN WITH ITS OWN STEM. Catches the straight-through rewrite — `Routing …` in routing.md,
    # `Metrics …` in metrics.md — which is a title with a `Use when` bolted on. The first tokens are the
    # discriminating ones, so they must be an act, not the filename.
    #
    # THE SEGMENT LOOP IS THE WHOLE CHECK. It used to also test `$first_word = $stem`, which is dead
    # both ways: for a single-word stem the loop's one segment IS the stem, and for a hyphenated one a
    # single first word can never equal `og-image-generator`. A redundant arm in an assertion is not
    # free — it reads as extra coverage and is none — so it is gone rather than left decorating.
    first_word="$(printf '%s' "$desc" | awk '{print tolower($1)}' | tr -d '[:punct:]')"
    for seg in $(printf '%s' "$stem" | tr '-' ' '); do
      if [ "$first_word" = "$seg" ]; then
        l2_problems="$l2_problems
    $rel — description opens with its own stem ('$first_word'); open on an act + object instead"
        break
      fi
    done

    # EVERY `(see X)` POINTER RESOLVES TO A FILE — all of them, not just the clustered ones.
    #
    # L3 below checks its 31 cluster members. Measured on #168: the 75 descriptions carry 112 pointers,
    # so 38 of them had no existence assertion anywhere. A pointer is a promise that a named file is
    # where to go instead, and a dangling one sends a matcher — and a reader — at nothing.
    #
    # SAME CLASS AS THE `skills-table.py` LANDMINE THIS SLICE FIXED: cheap to state, invisible until
    # someone follows it. It catches every rename that L3's hand-maintained table cannot see, because
    # it is DERIVED — the pointers are read out of the descriptions rather than enumerated here.
    #
    # THE POINTER IS A BARE STEM NOW (#164), and the reason the plain-path form existed has gone with
    # the families. It was `(see backend/metrics)` because `(see cloudwatch-rum)` once named two files
    # in two families and could not be resolved; #174 merged all four such pairs and the flatten leaves
    # 69 unique stems, so a bare stem resolves deterministically and is the only spelling the tree can
    # still support. The rewrite was mechanical for exactly that reason.
    #
    # ── NOTHING IS SKIPPED, AND THAT IS A CORRECTION ────────────────────────────────────────────────
    # THE FIRST VERSION FILTERED WITH `grep -E '^[a-z0-9-]+/[a-z0-9-]+$'` AND DROPPED EVERYTHING ELSE.
    # Measured by the merge gate: rewrite a pointer as `(see backend/framework-hono.md)` — a `.` fails
    # the class — and the suite prints `61 passed, 0 failed`. The pointer is unresolvable, the check
    # cannot see it, and the green says nothing is wrong.
    #
    # THAT IS THE THIRD INSTANCE OF THIS SLICE'S OWN SUBJECT, and it had reached a PERMANENT record:
    # ADR-0009 lists "every `(see X)` resolving to a file" as gated. The ADR was accurate about the
    # intent and wrong about the coverage — the same shape as the one-line comment that described a
    # check nobody had implemented, and as `skills-table.py` claiming the first line. A filter that
    # silently drops what it cannot parse is indistinguishable from a filter that found nothing.
    #
    # SO THE UNPARSEABLE IS REPORTED, NOT DISCARDED. Two branches, and every token reaches one of them.
    #
    # THE CLASS IS NOW A BARE STEM ONLY, and a SLASH IS REJECTED RATHER THAN IGNORED. A surviving
    # `(see backend/metrics)` names a path that no longer exists anywhere, and the old class — which
    # made the family segment optional — would have accepted it and then failed on the file check with
    # a message about a missing file rather than about a stale spelling. Two targets are legal: a
    # library skill at `skills/<stem>/SKILL.md`, and one of the two typed commands at
    # `commands/<stem>.md`, which point at each other legitimately (ADR-0009 documents them as the only
    # such files).
    while IFS= read -r ref; do
      [ -z "$ref" ] && continue
      if ! printf '%s' "$ref" | grep -qE '^[a-z0-9-]+$'; then
        l2_problems="$l2_problems
    $rel — pointer 'see $ref' is not a resolvable reference. Since #164 the library is flat and the
      invocation name is the bare stem: write 'see <skill>' with no family segment, extension,
      backticks or punctuation."
        continue
      fi
      [ -n "$(skill_file "$ref")" ] && continue
      [ -f "$ROOT/commands/$ref.md" ] && continue
      l2_problems="$l2_problems
    $rel — points at 'see $ref', and neither skills/$ref/SKILL.md nor commands/$ref.md exists"
    done <<< "$(printf '%s' "$desc" | grep -oE '\(see [^)]*\)' \
                  | sed 's/^(see //; s/)$//' | tr ',' '\n' | sed 's/^ *see *//; s/^ *//; s/ *$//' \
                  | grep -v '^$' || true)"
  done <<< "$SKILL_FILES"

  if [ -n "$l1_problems" ]; then
    bad "skill descriptions L1 — presence/parse:$l1_problems"
  elif [ -n "$scan_short" ]; then
    bad "skill descriptions L1 — the $desc_count file(s) scanned all parse, but $scan_short, so 'all of them' is not a
      claim about the library. The green is WITHHELD rather than printed over a truncated set. Fix the
      shortfall above and this reports on its own."
  else
    ok "skill descriptions L1 — all $desc_count parse, are one line, are $DESC_MIN-$DESC_MAX chars, and argument-hint is on exactly: $ARG_HINT_ALLOWED"
  fi

  if [ -n "$l2_problems" ]; then
    bad "skill descriptions L2 — a description is written as a TITLE rather than a TRIGGER:$l2_problems
      A title names the artifact; a trigger names the situation. See the standard on #166."
  elif [ -n "$scan_short" ]; then
    bad "skill descriptions L2 — the $desc_count description(s) scanned are all triggers, but $scan_short, so the
      green is WITHHELD: it would read as coverage of the library rather than of a truncated set."
  else
    ok "skill descriptions L2 — all $desc_count are triggers, not titles (Use when present, no '(concept)', no stem opener, every '(see X)' resolves)"
  fi

  # --- NO CONSUMER-SPECIFIC REFERENCE, ANYWHERE IN A SKILL FILE (#167) ---------------------------
  #
  # THE RULE, WHICH IS OLDER THAN THIS CHECK: a skill must not name any path, identifier or artefact
  # that exists in EXACTLY ONE PROJECT. `CLAUDE.md` has said so since the first commit — "project-
  # agnostic, generic <project> / <apex-domain> placeholders, no real names or paths" — and NOTHING
  # ENFORCED IT, which is precisely how 43 of 75 files drifted past it unnoticed for months. A rule
  # that lives only in prose is a rule that is true until someone is in a hurry.
  #
  # WHY IT MATTERS BEYOND TIDINESS: this library is published for reuse. A guide naming one consumer's
  # directories teaches that consumer's setup instead of the pattern, and a skill matched into a repo
  # with a different layout hands the model a path that does not exist there.
  #
  # THE ONE ALLOWED HIT IS THE PLUGIN'S OWN NAME, and the distinction is not cosmetic:
  # `tadeumendonca-skills` is the INVOCATION SURFACE — `/tadeumendonca-skills:infrastructure/vpc` is
  # what EVERY consumer types, identically. Scrubbing it would make the install and invocation
  # instructions wrong. `tadeumendonca-io` and `tadeumendonca.io` are a specific consumer's repo and
  # domain, and go. That is why the allowance is spelled as an exact token rather than a prefix:
  # `tadeumendonca-anything-else` is a leak until someone argues otherwise, in an MR, on the record.
  #
  # THAT CLAIM WAS FALSE WHEN FIRST WRITTEN, AND THE REGEX WAS RAISED TO MEET IT RATHER THAN THE CLAIM
  # LOWERED TO MEET THE REGEX. Measured by the merge gate on #169, with this falsifier:
  #
  #   printf 'tadeumendonca-skills-evil\n' \
  #     | grep -noE 'apps/(fed|bff)|tadeumendonca(\.[A-Za-z]+|-[A-Za-z]+)?' \
  #     | grep -vE ':tadeumendonca-skills$'      # → NOTHING. Green.
  #
  # The FILTER was correctly anchored (`$`); the TOKENISER was not. `-[A-Za-z]+` consumes at most ONE
  # hyphen-segment, so `tadeumendonca-skills-evil` truncated to exactly `tadeumendonca-skills` and the
  # anchored filter then dropped it as allowed. The hole was neither the scope nor the filter, and it
  # was not general: `tadeumendonca-anything-else` and `tadeumendonca-io-backup` were both caught. It
  # was exactly `tadeumendonca-skills-*` — the one shape an anchored filter cannot distinguish from
  # the token it is anchored to, once the tokeniser has already thrown the tail away.
  #
  # `([-.][A-Za-z]+)*` consumes ALL following segments, so the token reaching the filter is whole and
  # the anchor means what it says. Same class as this file's other corrections: an assertion describing
  # a check nobody had implemented, green for a reason no one would look behind — and it landed in the
  # slice whose entire subject is a rule that nothing enforced.
  #
  # THE MATCH IS TOKENISED, NOT SUBSTRING, deliberately. Matching the bare stem and then filtering
  # lines containing the allowed name would let a genuine leak hide on the same LINE as a legitimate
  # self-reference. Extracting whole tokens and judging each one has no such blind spot — and it means
  # trailing punctuation (`tadeumendonca-skills.`) cannot turn an allowed token into a false failure,
  # which a naive `grep -v` on the raw match would.
  #
  # SCOPE IS commands/ ONLY. `agents/`, the README and the ADRs describe THIS repo and are entitled to
  # name it; the skills are the artefact that travels.
  consumer_problems=""
  consumer_scanned=0
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    rel="${f#"$ROOT"/}"
    consumer_scanned=$((consumer_scanned + 1))
    # grep -no prints LINE:MATCH, one per occurrence. The alternation captures the consumer app dirs
    # and any `tadeumendonca…` token; the filter drops the single allowed token, exactly.
    while IFS= read -r hit; do
      [ -z "$hit" ] && continue
      consumer_problems="$consumer_problems
    $rel:$hit"
    done <<< "$(grep -noE 'apps/(fed|bff)|tadeumendonca([-.][A-Za-z]+)*' "$f" \
                  | grep -vE ':tadeumendonca-skills$' || true)"
  done <<< "$SKILL_FILES"

  if [ "$consumer_scanned" -eq 0 ]; then
    bad "consumer references — no skill files were scanned; this assertion did NOT run"
  elif [ -z "$consumer_problems" ]; then
    ok "consumer references — all $consumer_scanned skill files are project-agnostic across their WHOLE body, not just the frontmatter (only 'tadeumendonca-skills', the plugin's own invocation name, is allowed)"
  else
    bad "consumer references — a skill names something that exists in exactly one project:$consumer_problems
      Replace it with a <project>-style placeholder, or with a sentence that teaches the pattern where
      the path was doing explanatory work — never delete it and leave a hole. The plugin's own name
      ('tadeumendonca-skills') is the ONLY allowed occurrence, because it is what every consumer types."
  fi

  # --- LEVEL 3: cluster symmetry -----------------------------------------------------------------
  #
  # Disambiguation is a property of THE SET, not of the file: `backend/logging`, `frontend/analytics`
  # and `infrastructure/cloudwatch` all touch observability, and a per-file pass cannot tell them
  # apart because each one, read alone, is correct. So each member must name at least one rival, and
  # the naming must be MUTUAL — if A says "not me, see B" while B has never heard of A, the pair has
  # drifted and a matcher gets one-way advice.
  #
  # ── WHAT THIS COSTS, STATED RATHER THAN IMPLIED, because this repo's standard is that a check says
  #    what it does NOT cover ────────────────────────────────────────────────────────────────────────
  # THE TABLE BELOW IS HAND-MAINTAINED, AND IT CANNOT CATCH AN ADDITION. A new skill that belongs in
  # one of these clusters — say a second tracing skill — is simply absent from the table, so nothing
  # here asks whether it disambiguates itself, and this block stays green while the cluster it joined
  # silently competes on its subject. There is no way to catch that: cluster membership is a semantic
  # judgement about what two files are ABOUT, and deriving it from the filesystem would mean deriving
  # meaning from a path. That is exactly the "quality score" the standard refuses — it would be wrong
  # often enough that the loop learns to silence it.
  #
  # WHAT IT DOES CATCH IS DELETION AND RENAME, asserted positively: every member listed must exist as a
  # file. So removing or renaming a clustered skill reddens this and drags the table out for editing in
  # the same commit, which is the property the rest of this suite is built on. The uncovered direction
  # is ADDITION only, and it is uncovered on purpose rather than by omission.
  #
  # ── THE MATCH NEEDS A TRAILING BOUNDARY, AND THAT IS LOAD-BEARING ───────────────────────────────
  # `cloudwatch` is a PREFIX of both `cloudwatch-rum` and `cloudwatch-xray`. A fixed-string search would
  # read cloudwatch-xray's description — which names `-rum` and not the bare one — as naming
  # `cloudwatch` too, then demand a reciprocal reference that should not exist, and redden a correct
  # pair. This file has learned the substring lesson three times on the practice's name; the same shape
  # appears here in a different guise, so a non-slug character (or end of line) is required after it.
  #
  # ── AND THE MATCH IS NOW SCOPED TO THE POINTER, NOT THE SENTENCE (#164, finding 10) ──────────────
  # THE MEMBERS USED TO BE `family/stem` PATHS, WHICH ARE UNAMBIGUOUS BY CONSTRUCTION. Flat members are
  # BARE STEMS, and the stems are ordinary English nouns — `metrics`, `tracing`, `analytics`, `coverage`,
  # `authentication` — so a description that happens to use the word satisfies a membership it was never
  # written to satisfy. Measured before the flatten, by stripping every `(see ...)` pointer out of the
  # current descriptions and applying the bare-stem match: FIVE of the thirty-one memberships came out
  # satisfied by a word the author wrote for a different reason (`cloudwatch` "naming" metrics,
  # `cloudwatch-xray` tracing, `cloudwatch-rum` analytics, `sonarcloud` coverage, `cognito`
  # authentication). Green, and meaningless for those five.
  #
  # So the rival must be named INSIDE a `(see ...)` construct, which is the form the #166 standard
  # requires for a disambiguating pointer anyway. That leaves this check STRICTER than it was rather
  # than weaker: before the flatten a rival mentioned in passing counted, and now only a pointer does.
  CLUSTERS="
gates|code-review quality-gates
delivery|devops harness-engineering
"

  names_rival() {  # $1 = description text, $2 = rival stem — matched only inside a `(see …)` pointer
    printf '%s' "$1" | grep -oE '\(see [^)]*\)' | grep -qE "(^|[^a-z0-9-])$2([^a-z0-9-]|$)"
  }

  cluster_problems=""
  cluster_members=0
  while IFS= read -r row; do
    [ -z "$row" ] && continue
    cname="${row%%|*}"
    members="${row#*|}"

    for m in $members; do
      cluster_members=$((cluster_members + 1))
      mf="$(skill_file "$m")"
      if [ -z "$mf" ]; then
        cluster_problems="$cluster_problems
    $cname: $m is in the cluster table and has NO FILE — it was renamed or deleted; update the table"
        continue
      fi
      mdesc="$(fm_block "$mf" | grep -m1 '^description:' || true)"

      named=0
      for other in $members; do
        [ "$other" = "$m" ] && continue
        names_rival "$mdesc" "$other" || continue
        named=$((named + 1))
        # SYMMETRY. Reported from the side that FAILS to reciprocate, so the message names the file to
        # edit rather than the file that is already right.
        of="$(skill_file "$other")"
        [ -n "$of" ] || continue
        odesc="$(fm_block "$of" | grep -m1 '^description:' || true)"
        if ! names_rival "$odesc" "$m"; then
          cluster_problems="$cluster_problems
    $cname: $m names $other, but $other does not name $m back — add the reciprocal 'Not for … (see $m)'"
        fi
      done

      if [ "$named" -eq 0 ]; then
        cluster_problems="$cluster_problems
    $cname: $m names no rival in its own cluster — it competes on a shared subject with nothing to separate it"
      fi
    done
  done <<< "$CLUSTERS"

  if [ "$cluster_members" -eq 0 ]; then
    bad "skill descriptions L3 — the cluster table parsed as EMPTY; this assertion did NOT run"
  elif [ -n "$cluster_problems" ]; then
    bad "skill descriptions L3 — cluster disambiguation:$cluster_problems"
  elif [ -n "$scan_short" ]; then
    bad "skill descriptions L3 — the $cluster_members clustered skill(s) scanned all name a rival, but $scan_short, so
      the green is WITHHELD: a cluster member missing from the scan set cannot be judged at all."
  else
    ok "skill descriptions L3 — all $cluster_members clustered skills name a rival, and every naming is mutual (addition to a cluster is NOT covered — see the note above)"
  fi
fi

# ---------------------------------------------------------------------------------------------------
# EVERY POINTER A PERSONA BRIEF MAKES INTO THE LIBRARY RESOLVES (#164, finding 8).
#
# THE SAME RULE AS THE `(see X)` RESOLVER ABOVE, POINTED AT THE OTHER SET OF FILES THAT MAKE THE SAME
# CLAIM. A skill description saying `(see dynamodb)` has been gated since #168; a persona brief saying
# `/dev-loop` was gated by nothing at all until #180, and there were ten of them across the five briefs.
# (Both spellings above were family-qualified — `(see backend/dynamodb)`, `/principles/dev-loop` — until
# #164 flattened the library; the sentence is re-tensed rather than left describing a form the tree no
# longer contains.)
#
# WHY IT IS WORTH A BLOCK, in `harness-lead`'s words on #164: it is "the only place where a break is
# both silent AND consequential". A wrong skill identifier fails at ZERO BYTES OF STDERR without
# `--debug-file` — measured — so a persona told to consult a name that no longer resolves reaches for
# nothing and reports nothing. The failure is indistinguishable from a deliberate omission, forever.
#
# WHY IT IS AT TOP LEVEL AND NOT INSIDE THE SCAN BLOCK ABOVE, WHICH IS WHERE IT WAS FIRST WRITTEN. It
# resolves into `commands/`, so nesting it under that block's guard looked like the tidy choice. IT WAS
# MEASURED WRONG BEFORE IT SHIPPED: two mutations — moving `commands/workflow/adr.md` aside, and
# emptying `commands/frontend` — both shrink the scan set, so the floor fired, the `else` was skipped
# and THIS ASSERTION NEVER RAN. The suite was red, and not one of its reds named the dangling pointer.
# That is precisely the disease the floor above was added to cure, reintroduced one block later. Both
# mutations now redden this block by name.
#
# ── WHAT THE POINTER LOOKS LIKE SINCE #164, AND WHY THE EXTRACTION HAD TO CHANGE SHAPE ────────────
# IT USED TO BE `/<family>/<skill>`, AND THE FAMILY SEGMENT WAS DOING THE WORK. The extraction keyed on
# the set of family directories, which is what kept it from swallowing `.github/workflows/**` and
# `apps/**/scripts` — every brief is full of paths that are not skills.
#
# Flat pointers are `/<skill>`, a single segment, and that anchor is GONE: `/tmp`, `/iac`, `/me` and
# every other bare path in a brief has the identical shape. So the extraction keys on the SKILL NAMES
# THEMSELVES, derived from the tree. That inverts what this block can catch, and both directions are
# stated rather than implied:
#
#   - IT STILL CATCHES THE DIRECTION THAT HAPPENS: a skill renamed, merged or moved leaves the brief's
#     pointer naming nothing, and the name disappears from the derived set, so the pointer stops being
#     extracted at all — which is why the COUNT is asserted below and not only the resolutions. A drop
#     in the number of pointers found is the signal; that is the anti-vacuity guard's whole job here.
#   - IT CANNOT CATCH AN INVENTED NAME (`/dev-lop`), for the same reason it never caught an invented
#     family: the extraction only sees what exists. Widening to any `/token` is the cry-wolf failure
#     this file refuses elsewhere, and it would fire on `/tmp` in every brief.
#
# THE FAMILY-GLOB FORM IS GONE WITH THE DIRECTORIES. `developer.md` wrote `/frontend/*` for its four
# source globs; a family is no longer a path, so that spelling names nothing and was rewritten to
# `` the `frontend` family ``. It is gated below on the frontmatter instead — a family that no skill
# claims is a broken reference exactly as an emptied directory was.
#
# THE SKILL LIST IS DERIVED FROM THE TREE, not enumerated, for the reason the family walk at the top of
# this file already gives: an enumeration inside a file written to catch stale enumerations.
#   - THE `skills:` PRELOAD IDENTIFIERS in the briefs' frontmatter are a DIFFERENT form —
#     colon-separated, `family:stem` — and are not read here. THEY ARE ALREADY GATED, by
#     `hooks/scripts/skills-resolve.test.sh`, which is scoped to the frontmatter and says so in its own
#     words: "the FRONTMATTER only, never the body". This block is the complement — the BODY, where the
#     same brief writes the same library in the slash spelling that the loader does not resolve. The
#     two together cover both forms, and neither covers the other. (An earlier draft of this comment
#     claimed the frontmatter form was ungated. It was false when written, and the correction is kept
#     rather than tidied away, because a comment overstating a gap is the same defect class as one
#     overstating coverage.)
brief_skills=""
while IFS= read -r d; do
  [ -z "$d" ] && continue
  brief_skills="$brief_skills|$(basename "$d")"
done <<< "$SKILL_DIRS"
brief_skills="${brief_skills#|}"

brief_problems=""
brief_pointers=0
if [ -z "$brief_skills" ]; then
  bad "agent brief pointers — no skills were found under skills/, so every pointer in the briefs was
      resolved against nothing and this assertion did NOT run. If the library moved, repoint this
      resolver in the same commit."
else
  for brief in "$ROOT"/agents/*.md; do
    [ -f "$brief" ] || continue
    brel="${brief#"$ROOT"/}"

    # THE SLASH-INVOCATION FORM — `/code-review`, the spelling a brief uses in prose.
    #
    # ── THE EXTRACTION NEEDS A LEFT BOUNDARY, AND IT DID NOT HAVE ONE (found on #182) ─────────────
    # `/($brief_skills)` with no preceding context matched the `/adr/` INSIDE `docs/adr/**` — an
    # ordinary directory path in two of `tech-lead.md`'s sentences, not an invocation. It passed green
    # for exactly one reason, and the reason is worth recording because it is the shape this file keeps
    # finding: the trailing `/` survived the tail strip (`/` is in the keep class), the check then tested
    # `[ -f "$ROOT/skills/adr//SKILL.md" ]`, AND THE KERNEL COLLAPSES THE DOUBLE SLASH. So a pointer the
    # extraction had mangled resolved anyway, and the PASS line counted two references that are not
    # references at all.
    #
    # It surfaced only when the resolver stopped being a path concatenation — `skill_file` searches for a
    # directory NAMED `adr/`, finds none, and reports it. A stricter resolver made a looser extraction
    # visible; neither half would have shown it alone.
    #
    # BOTH BOUNDARIES NOW. Left: start of line, or a character that cannot be part of a path
    # (`[^a-z0-9./-]` — so `docs/adr` is excluded by the `s`). Right: unchanged in intent, but a trailing
    # `/` is now REJECTED rather than trimmed, because a slash after the name means the token is a path
    # segment and never an invocation. The `sed` drops the captured left boundary character.
    while IFS= read -r hit; do
      [ -z "$hit" ] && continue
      lineno="${hit%%:*}"
      ref="${hit#*:}"
      ref="${ref#/}"
      brief_pointers=$((brief_pointers + 1))
      if [ -z "$(skill_file "$ref")" ] && [ ! -f "$ROOT/commands/$ref.md" ]; then
        brief_problems="$brief_problems
    $brel:$lineno — points at '/$ref', and neither skills/$ref/SKILL.md nor commands/$ref.md exists"
      fi
    done <<< "$(grep -noE "(^|[^a-z0-9./-])/($brief_skills)([^a-z0-9/-]|$)" "$brief" \
                  | sed -E 's#^([0-9]+):[^/]*/#\1:/#; s#[^a-z0-9-]*$##' || true)"

    # ~~THE FAMILY FORM — `` the `frontend` family ``, which replaced `/frontend/*` when the families
    # stopped being directories. It promises the family EXISTS, i.e. that some skill claims it.~~
    #
    # **THE WHOLE ARM IS DELETED (#286), AND THE BRIEFS WERE REWRITTEN IN THE SAME COMMIT.** With one
    # directory level there is no family to name, so the five references it checked
    # (`developer.md` ×4, `quality-assurance.md` ×1) were rewritten to the SKILL they actually meant —
    # `` the `/frontend` skill ``, `` the `/cloud-infrastructure` skill ``, `` the `/devops` skill ``,
    # `` the `/backend` skill `` — which the slash arm above already resolves, by name, against the
    # tree. So this is not coverage removed: it is coverage folded into the arm that was always
    # stronger, since that one resolves a FILE and this one only ever checked that a word appeared in
    # a derived list.
    #
    # THE ANTI-VACUITY GUARD GOES WITH IT. `brief_family_refs -eq 0` was a hard failure; leaving it
    # would red on every run now, and re-pointing it at a form no brief uses would be exactly the dead
    # assertion its own comment (kept below) was written about.
    #
    # THE COMMENT BELOW IS KEPT UNSTRUCK because its subject is not the families at all — it is the
    # `\`` escape, which was measured to make an ERE arm match NOTHING under GNU grep while working
    # under BSD and ugrep. That is a live trap for the next person writing any backtick pattern in this
    # file, and it outlives the arm it was written for.
    #
    # THE BACKTICK IS NOT ESCAPED, AND THAT IS THE FIX (#182 shipped it escaped and this arm has been
    # INERT ever since). A backtick is not a metacharacter in ERE, so `\`` is an UNDEFINED escape and
    # implementations disagree: ugrep and BSD grep read it as a literal backtick and the arm works.
    # GNU grep — the runner's — reads it as a ZERO-WIDTH ANCHOR, and the two things a reader assumes
    # about that are both false, which is why they are written down rather than summarised:
    #
    #   it does NOT demand a backtick, and it is NOT byte 0 of the FILE — it anchors per LINE:
    #     printf 'aaa\nbbb `frontend` family\n' | ggrep -noE '\`[a-z0-9-]+'   ->  1:aaa   2:bbb
    #                                                        ^ matched with no backtick present
    #   and the pattern carries TWO of them, the second AFTER [a-z0-9-]+ has consumed input, so it is
    #   unsatisfiable at any position, including a line that begins with a backtick:
    #     printf '`frontend` family here\n' | ggrep -c -oE '\`[a-z0-9-]+\`'   ->  0
    #
    # That distinction is the whole instruction: a start-of-buffer story makes re-escaping look
    # conditionally safe. It is not — escaped, this arm matches NOTHING ANYWHERE. Do not restore it.
    #
    # Measured on the tree, not reasoned backwards from the manual. The arm counts OCCURRENCES, so the
    # figure is the enumeration and nothing else — every attempt to also explain it has been wrong:
    #     grep -rnoE '`[a-z0-9-]+` family' agents/   ->  5   (ugrep, BSD, and GNU with this pattern)
    #       developer.md:158 `frontend` · :162 `infrastructure` · :165 `workflow` · :166 `backend`
    #       quality-assurance.md:16 `backend`
    #     the same command with '\`…\`' under GNU    ->  0   (the runner, on every branch since #182)
    # So the anti-vacuity below fired on every branch from #182 onward — and #182 was MERGED with this
    # gate red. An assertion that cannot match is not a strict assertion, it is a dead one that
    # happens to be loud.
    # THE ONE THING THE DELETED ARM STILL BUYS: a brief must not go back to naming a family, because a
    # family is not a directory, not an identifier and not anything the loader reads. This is an
    # ABSENCE check — cheap, and it fails in the direction that matters (a reintroduction), rather than
    # asserting a form no brief uses.
    while IFS= read -r hit; do
      [ -z "$hit" ] && continue
      lineno="${hit%%:*}"
      brief_problems="$brief_problems
    $brel:$lineno — names a skill FAMILY, and there are none since #286. Name the skill: \`/<skill>\`."
    done <<< "$(grep -noE '`[a-z0-9-]+` family' "$brief" || true)"
  done

  if [ "$brief_pointers" -eq 0 ]; then
    bad "agent brief pointers — not one /<skill> pointer was found across agents/*.md, and there were
      seven when this was rewritten for the flat tree. Either the briefs stopped naming the library that
      way — in which case retarget this resolver at the form they use now, in this commit — or the
      extraction broke."
  elif [ -z "$brief_problems" ]; then
    ok "agent brief pointers — all $brief_pointers /<skill> pointers across the persona briefs resolve, and no brief names a family (a wrong one fails at 0 bytes of stderr, so nothing else would say so)"
  else
    bad "agent brief pointers — a persona brief sends its reader at something that does not exist:$brief_problems
      A wrong identifier fails SILENTLY — zero bytes of stderr — so this block is the only thing that
      will ever say so. Fix the pointer, or put the file back."
  fi
fi

# ---------------------------------------------------------------------------------------------------
# EVERY PUBLISHED `/tadeumendonca-skills:<name>` INVOCATION NAMES SOMETHING THAT EXISTS (#164, finding 11).
#
# THE TWO DOCUMENTS A FORKER MEETS FIRST PUBLISH SIX OF THESE, AND NOTHING ASSERTED ANY OF THEM — the
# only occurrence of that string anywhere in this suite was a comment. They are the install-and-invoke
# instructions: `CLAUDE.md`'s usage fence and the README's, the literal lines someone types on their
# first day with this plugin.
#
# WHY IT IS WORTH ITS OWN BLOCK RATHER THAN A NOTE. The failure is silent at BOTH ends. A wrong skill
# identifier fails at 0 bytes of stderr in the runtime — the whole premise of the resolver blocks above
# — and an unresolved identifier WITH A SLASH is worse than that: it is not recognised as a command at
# all, falls through as ordinary prompt text, and the model improvises an answer to it. So a stale
# example does not error, it produces a confident wrong one, and the reader has no way to tell.
# Measured on #164: every one of the 71 identifiers this repo published before the flatten contained a
# slash, so that was the failure mode the whole rename walked toward.
#
# THE PLUGIN PREFIX IS THE ANCHOR, deliberately. Matching bare `/word` in a document this size would
# fire on every path in it. `/tadeumendonca-skills:` is unambiguous, it is exactly the form a consumer
# types, and it is the only form these two documents use for an invocation.
inv_problems=""
inv_checked=0
for doc in "$README" "$CLAUDE"; do
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    inv_checked=$((inv_checked + 1))
    [ -n "$(skill_file "$ref")" ] && continue
    [ -f "$ROOT/commands/$ref.md" ] && continue
    inv_problems="$inv_problems
    $(basename "$doc") publishes /tadeumendonca-skills:$ref — no such skill or command"
  done <<< "$(grep -ohE '/tadeumendonca-skills:[a-z0-9:/-]+' "$doc" 2>/dev/null | sed 's#^/tadeumendonca-skills:##' || true)"
done

if [ "$inv_checked" -eq 0 ]; then
  bad "published invocations — not one '/tadeumendonca-skills:<name>' string was found in README.md or
      CLAUDE.md, and there were six when this was written. Either the usage examples were removed — in
      which case delete this block in the same commit — or the extraction broke."
elif [ -z "$inv_problems" ]; then
  ok "published invocations — all $inv_checked '/tadeumendonca-skills:<name>' examples name a skill or command that exists"
else
  bad "published invocations — an install-and-invoke example names something that is not there:$inv_problems
      A wrong identifier CARRYING A SLASH is not reported as unknown: it falls through as prompt text and
      the model answers it anyway. A stale example here produces a confident wrong answer, not an error."
fi

# ---------------------------------------------------------------------------------------------------
# EVERY CITATION OF A DECISION RECORD RESOLVES (#283, slice 1).
#
# WHY THIS EXISTS, AND WHY IT LANDS BEFORE THE CHANGE IT MUST CATCH. This repo's decision library is
# cited ~800 times. Measured at `aa7a7d4` — this slice's base commit, so the figures are re-derivable
# from any checkout without one — over the same extension set the scan set below uses:
#
#   git grep -Ioh -E '0[0-9]{3}-[a-z0-9-]+\.md' aa7a7d4 \
#       -- '*.md' '*.sh' '*.yml' '*.yaml' '*.json' '*.py' | wc -l   ->  203   (path form)
#   git grep -Ioh -E 'ADR-0[0-9]{3}'            aa7a7d4 \
#       -- '*.md' '*.sh' '*.yml' '*.yaml' '*.json' '*.py' | wc -l   ->  599   (prose form)
#
# An earlier draft of this header attributed 202/593 to `1e9baf3`, which is not a valid object name in
# this repository — a provenance a reader cannot check out, in the block whose whole thesis is that an
# unresolvable reference must fail loudly. Caught by `quality-assurance` on #289 (B1). Both figures were
# re-derived above rather than re-attributed. Nothing anywhere resolved ONE of them. `grep -i link` over this file returned
# zero hits before this block; the nearest instrument, `skills-resolve.test.sh`, resolves skill
# identifiers and says nothing about `docs/`.
#
# That was tolerable only while no record had ever been removed, which was literally true: the deletion
# set in this library was EMPTY. The reconciliation this gate was built for takes it from empty to
# roughly fourteen in one slice. A relative link to a deleted record 404s on GitHub and errors nowhere;
# a prose citation of a deleted record still READS as a valid reference to an agent and points at
# nothing. Both are silent, which is the whole problem — the failure and the absence of a gate have the
# same appearance.
#
# THE GATE IS DELIBERATELY WIDER THAN `docs/adr/`. It resolves EVERY relative markdown link in every
# tracked `.md`, not only the ones naming a record. Measured before it was written: 198 such links, 0
# broken — 199 as this ships, the extra one being the destination this slice re-wrapped so that it is a
# link at all — so the widening costs nothing today and covers the whole class instead of the instance. A
# gate scoped to the one thing that is about to break is a gate that has to be re-scoped every time
# something else does.
#
# ── WHAT IT DOES NOT COVER, SAID PLAINLY SO A GREEN IS NOT READ AS MORE THAN IT IS ───────────────
#
#   CROSS-REPO CITATIONS ARE NOT CHECKED, AND CANNOT BE FROM HERE. `tadeumendonca-io` cites this
#     library's records, and this repo cites that one's. This suite has one working tree and no
#     business cloning another, so a green here says nothing about whether a record removed in this
#     repo is still cited in that one. That direction needs a gate in the consuming repo, or a
#     scheduled cross-repo check; neither is built, and neither is in this slice. Read the green as
#     "no citation INSIDE this repository dangles" and nothing wider.
#     THE SHARP EDGE, MEASURED RATHER THAN IMAGINED: a prose citation of the OTHER library whose number
#     collides with a live record here is resolved LOCALLY and passes green, without the check ever
#     establishing that the two are the same record. One such citation exists today — the record on the
#     merge precondition cites that repo's third record, and this library also has a third record. Be
#     precise about what is wrong with it, because the first draft of this note was not: that citation
#     is CORRECT — its prose says "the consuming repo's" and its destination is an absolute URL into
#     that repo — so what passes vacuously is the CHECK, not the citation. The exposure is the next one,
#     written without either disambiguator. The number-based exemption below cannot see either case,
#     because the number is not foreign. Nothing here will ever catch that class; only a qualifier in
#     the prose would.
#   ANCHORS ARE NOT RESOLVED. `](./README.md#some-heading)` is checked as far as `README.md`; whether
#     that heading exists is not checked. Heading text is prose and drifts constantly, and a check that
#     is wrong more often than it is right is one the loop learns to silence.
#   THE PROSE FORM IS CHECKED FOR EXISTENCE, NOT FOR AIM. A citation naming a live record that says
#     something other than what the citing sentence claims passes here. That is a reader's job.
#   A REDIRECT IS NOT A RESOLUTION. If a record is deleted and a file of the same name is later added
#     for a different decision, every old citation goes green while pointing at new content.

CITATION_ADR_DIR="$ROOT/docs/adr"

# ── 1 · every relative markdown link resolves from the CITING file's own directory ───────────────
link_problems=""
links_checked=0
while IFS= read -r file; do
  [ -z "$file" ] && continue
  [ -r "$file" ] || continue
  link_dir="$(dirname "$file")"
  while IFS= read -r target; do
    [ -z "$target" ] && continue
    case "$target" in
      http://*|https://*|mailto:*|'#'*|'<'*) continue ;;
    esac
    # Strip a `#fragment` (anchors are out of scope, see the header) and a ` "title"` suffix.
    target="${target%%#*}"
    target="${target%% *}"
    [ -z "$target" ] && continue
    links_checked=$((links_checked + 1))
    [ -e "$link_dir/$target" ] && continue
    link_problems="$link_problems
    ${file#"$ROOT"/} -> $target"
  done <<< "$(grep -ohE '\]\([^)]+\)' "$file" 2>/dev/null | sed -E 's/^\]\(//; s/\)$//' || true)"
done <<< "$CITATION_MD_FILES"

if [ "$links_checked" -eq 0 ]; then
  bad "citation resolution — not ONE relative markdown link was found across the tracked *.md set, and
      there were 199 when this was written. Either every relative link left the repo — in which case
      delete this block in the same commit — or the extraction broke and this assertion is vacuous."
elif [ -z "$link_problems" ]; then
  ok "citation resolution — all $links_checked relative markdown links resolve from their citing file's directory"
else
  bad "citation resolution — a relative markdown link points at a file that does not exist:$link_problems
      This fails SILENTLY for every reader: GitHub renders the link and returns 404 on the click, and
      nothing in this repo errors. If a record was removed, every citation of it moves in the SAME
      commit — that is the rule this block exists to make mechanical."
fi

# ── 2 · no markdown link destination WRAPS A LINE ────────────────────────────────────────────────
#
# WHY THIS IS A SEPARATE ASSERTION AND NOT A SMARTER EXTRACTOR. A CommonMark inline link destination
# may not contain a line break, so `[text](./some-` + newline + `rest.md)` is not a link at all: it
# renders as literal text, with the parenthesised path shown to the reader. Teaching check 1 to join
# lines would have made that case RESOLVE and go green — the extractor would repair a link the renderer
# does not, and the gate would certify a citation that is broken on the published surface.
#
# THE EXPECTED COUNT IS ZERO EVERYWHERE, AND THERE IS NO EXEMPTION LIST. One pre-existing occurrence
# existed when this block was written — `docs/adr/0002-…md:1295`, found BY this gate in the slice that
# built it — and the first draft DECLARED it in a `WRAPPED_DEST_EXPECTED` list rather than repairing it,
# on the reasoning that a record body belongs to #283's reconciliation slice.
#
# THE DECLARATION IS GONE BECAUSE IT COULD NOT SURVIVE THE OPERATION IT WAS WAITING FOR. It named a
# file, and `CITATION_MD_FILES` is built from `git ls-files`, so renaming or deleting that file removes
# it from the scan set entirely and `[ -r "$file" ]` skips the stale entry in silence: the exemption
# stops being verified and this check goes GREEN on a declaration that no longer refers to anything.
# Measured by `quality-assurance` on #289 by renaming exactly that record — check 2 stayed green while
# checks 1 and 3 reddened. Folding `0002` is precisely what the reconciliation slice does, so the
# declaration's one self-cleaning arm was blind in the only direction it was ever going to be used.
# The wrap is therefore repaired in the same slice (re-wrapping a paragraph changes no decision, no word
# and no meaning), the list is deleted rather than relocated, and the expected count is a constant zero
# with nothing to go stale.
#
# WHAT THE DECLARATION WAS ALSO DOING, AND WHAT REPLACES IT. An expected-count-of-one entry was this
# check's only proof that the DETECTOR works: a repo with zero wrapped destinations and a broken
# extractor look identical from here, so "expected 0 everywhere" is a green that can prove nothing.
# Deleting the entry without replacing that property would have traded a stale-exemption hole for a
# vacuity hole. So the detector is run first against a SYNTHETIC wrapped destination that is part of
# this file rather than part of the library — it cannot go stale when a record moves, and it fails
# loudly the moment the pattern stops matching the thing it is named for.
# The synthetic names NO real record, deliberately: a live number written here would register as a
# citation to check 4 below and couple this probe to a record slice 3 may move.
#
# AND THE PROBE MUST BE THE SAME EXPRESSION AS THE SCAN, NOT A SECOND COPY OF IT. The first form of
# this guard spelled the pattern out twice — once here, once in the loop below — so the probe proved
# only that ITS OWN copy matched. Measured by `quality-assurance` on #289 (B4): mutating the SCANNING
# literal alone to a non-matching string left the suite fully green (60 passed, 0 failed) with check 2
# asserting nothing, while mutating the probe's literal reddened. That is precisely the vacuity hole the
# deleted `WRAPPED_DEST_EXPECTED` entry used to close — reintroduced by the change that closed the
# stale-exemption one. A single variable used in both places is what makes "the detector works" a
# statement about the detector that actually runs; keep it that way, and never inline the pattern back
# into either site.
#
# THE SHARED THING IS THE FUNCTION, NOT ONLY THE PATTERN, AND THE DIFFERENCE IS MEASURABLE. Hoisting
# the regex alone closes the drift between two copies of the PATTERN and leaves the drift between two
# copies of the INVOCATION: with a bare `grep -cE "$wrap_re"` at each site, replacing the scan's
# reference with any non-matching literal was measured going fully green again (60 passed, 0 failed)
# while the probe stayed satisfied. Routing both through one function removes that too, so the probe
# exercises the exact expression the 48-file scan runs, argument for argument.
# WHAT REMAINS, NAMED RATHER THAN IMPLIED: deleting the call at the scan site — replacing
# `count_wrapped_destinations` with anything that prints `0` — is still green, and no guard inside this
# file can see it. That is assertion DELETION, visible in a diff, not the silent drift between two
# copies that this block exists to prevent; the distinction is the honest scope of the claim above.
wrap_re='\]\([^)]*$'
count_wrapped_destinations() { grep -cE "$wrap_re" || true; }

wrap_detector=$(printf '%s\n' 'a citation [some record](./a-destination-split-' \
                              'across-a-newline.md) that renders as literal text' \
                | count_wrapped_destinations)

wrap_problems=""
wrap_files_checked=0
while IFS= read -r file; do
  [ -z "$file" ] && continue
  [ -r "$file" ] || continue
  rel="${file#"$ROOT"/}"
  wrap_files_checked=$((wrap_files_checked + 1))
  wraps=$(count_wrapped_destinations < "$file")
  [ "$wraps" = "0" ] && continue
  wrap_problems="$wrap_problems
    $rel: $wraps line-wrapped link destination(s), expected 0"
done <<< "$CITATION_MD_FILES"

if [ "$wrap_detector" != "1" ]; then
  bad "citation resolution — the line-wrap DETECTOR does not detect: a synthetic wrapped destination
      matched $wrap_detector times, expected exactly 1. Every result from this check is vacuous until
      that is true, including a green one. Fix the pattern, do not delete this guard."
elif [ "$wrap_files_checked" -eq 0 ]; then
  bad "citation resolution — the wrap check opened NOT ONE tracked *.md file, so its green means only
      that it scanned nothing. Either the repository has no markdown left — in which case delete this
      block in the same commit — or CITATION_MD_FILES stopped being populated."
elif [ -z "$wrap_problems" ]; then
  ok "citation resolution — no markdown link destination wraps a line, across $wrap_files_checked tracked *.md files"
else
  bad "citation resolution — a markdown link destination is split across a newline:$wrap_problems
      A destination containing a line break is NOT parsed as a link. It renders as literal text with the
      path visible, so the citation is broken on the published surface while resolving fine to any
      line-joining tool. Re-wrap the paragraph so the destination sits on one line. There is no
      exemption list to add it to, deliberately — see the note above this check."
fi

# ── 3 · every repo-root-relative record path resolves ────────────────────────────────────────────
#
# The form a shell script, a workflow or a prose sentence uses when it names a record without linking
# it. It is not a markdown link, so check 1 never sees it, and it breaks exactly as silently.
#
# THE LEADING-BOUNDARY GROUP IS LOAD-BEARING, AND IT WAS EARNED ON THIS BLOCK'S FIRST RUN. Without it
# the pattern matches the tail of an ABSOLUTE URL into the consuming repo's library — one exists today,
# in the record on the merge precondition, pointing at that repo's third record over https. The
# substring is identical to a local path and the file is correctly absent here, so the gate reddened on
# a citation that is right. Requiring the match to start at a line boundary or after a character that
# cannot continue a path keeps the check on paths this repo can actually resolve. Cross-repo URLs are
# out of scope by construction — see the header.
path_problems=""
paths_checked=0
while IFS= read -r file; do
  [ -z "$file" ] && continue
  [ -r "$file" ] || continue
  while IFS= read -r tok; do
    [ -z "$tok" ] && continue
    paths_checked=$((paths_checked + 1))
    [ -f "$ROOT/$tok" ] && continue
    path_problems="$path_problems
    ${file#"$ROOT"/} names $tok — no such record"
  done <<< "$(grep -ohE '(^|[^/[:alnum:]._-])docs/adr/0[0-9]{3}-[a-z0-9-]+\.md' "$file" 2>/dev/null \
              | sed -E 's#^.*(docs/adr/)#\1#' || true)"
done <<< "$CITATION_FILES"

if [ "$paths_checked" -eq 0 ]; then
  bad "citation resolution — not one repo-root-relative record path was found across the tracked scan
      set, and there were 12 when this was written. Either the form fell out of use — delete this block
      in the same commit — or the extraction broke."
elif [ -z "$path_problems" ]; then
  ok "citation resolution — all $paths_checked repo-root-relative record paths resolve"
else
  bad "citation resolution — a record is named by path and the file is not there:$path_problems
      This form is invisible to a link checker and to a reader skimming for brackets. It is the form a
      GATE uses when it couples itself to a record by filename, so a stale one can silently change what
      a gate decides."
fi

# ── 4 · every prose `ADR-` + number names a live record ──────────────────────────────────────────
#
# SCOPE: REPO-WIDE, over every tracked file in the citation set, and NOT narrowed to a file class.
# The alternative considered was to assert it only in `docs/adr/` and `agents/`, on the theory that
# those are where citations are load-bearing. Measured, that theory is wrong: the prose form appears in
# `README.md`, `CLAUDE.md`, all six agent briefs, five skill files, four hook scripts, three issue
# templates, two workflows and `plugin.json`. There is no file class where a dangling citation is
# harmless, because the consumer of this form is an AGENT reading whatever file it was handed, and the
# failure is that the citation still looks valid. A narrower scope would have to justify which readers
# deserve a dangling reference, and there is no such answer.
#
# THE FOREIGN LIST IS THE ONE EXEMPTION, AND IT IS THE CROSS-REPO BLIND SPOT MADE VISIBLE. Six
# citations in this repo name records in `tadeumendonca-io`'s library, which this suite cannot open.
# They are declared by NUMBER rather than by site: a site list would be six entries drifting on every
# re-wrap, while the number is the thing that is actually foreign. Declaring them here is what turns a
# cross-repo citation into a deliberate, reviewable act instead of an accident that reads as local.
#
# THE DECLARATION IS SELF-CLEANING IN TWO DIRECTIONS, NOT ONE.
#   * A number declared foreign that later EXISTS in this library is a stale exemption hiding a real
#     check, so it fails. That is the arm that keeps this list from becoming the quiet allowlist every
#     exemption list eventually becomes.
#   * A number declared foreign that NOTHING in this repo cites any more is an exemption with no
#     subject: it exempts nothing, nobody will ever notice it, and the next reader takes it as evidence
#     that a cross-repo citation exists when it does not. It fails too. This is the direction
#     `WRAPPED_DEST_EXPECTED` did not have and could not have (a filename leaves the scan set when the
#     file moves; a NUMBER cannot), and it is the reason this exemption is by number and that one was
#     deleted outright rather than repaired. Added on #289 from `quality-assurance`'s advisory A4.
#
# WHAT NEITHER ARM CAN SEE, said plainly rather than left to be discovered: the record could be deleted
# in the OTHER repository, and a local typo that happens to land on a declared number is exempted
# exactly like a real cross-repo citation. Both need a working tree this suite does not have, or a
# qualifier in the prose that nothing writes today.
#
# AND THE COMMENTS IN THIS FILE MUST NOT SPELL THE DECLARED NUMBERS OUT in the prose form, which is why
# the sentence above says "a declared number" rather than naming one. A `ADR-nnnn` token written here
# is a citation like any other to the loop below: it would register as a sighting and keep an exemption
# alive after its last real citing site was removed — this block defeating its own second arm from
# inside its own documentation.
FOREIGN_ADR_NUMBERS="0023 0043"

foreign_problems=""
for num in $FOREIGN_ADR_NUMBERS; do
  set -- "$CITATION_ADR_DIR/$num"-*.md
  [ -f "$1" ] || continue
  foreign_problems="$foreign_problems
    $num is declared FOREIGN but ${1#"$ROOT"/} exists here now — the exemption is hiding a real check"
done

foreign_seen=""
prose_problems=""
prose_checked=0
while IFS= read -r file; do
  [ -z "$file" ] && continue
  [ -r "$file" ] || continue
  while IFS= read -r tok; do
    [ -z "$tok" ] && continue
    num="${tok##*-}"
    case " $FOREIGN_ADR_NUMBERS " in
      *" $num "*)
        case " $foreign_seen " in *" $num "*) : ;; *) foreign_seen="$foreign_seen $num" ;; esac
        continue
        ;;
    esac
    prose_checked=$((prose_checked + 1))
    set -- "$CITATION_ADR_DIR/$num"-*.md
    [ -f "$1" ] && continue
    prose_problems="$prose_problems
    ${file#"$ROOT"/} cites $tok — no record numbered $num in docs/adr/"
  done <<< "$(grep -ohE 'ADR-0[0-9]{3}' "$file" 2>/dev/null | sort -u || true)"
done <<< "$CITATION_FILES"

for num in $FOREIGN_ADR_NUMBERS; do
  case " $foreign_seen " in
    *" $num "*) continue ;;
  esac
  foreign_problems="$foreign_problems
    $num is declared FOREIGN and NOTHING in this repo cites it any more — the exemption has no subject"
done

# TWO SUBJECTS, TWO INDEPENDENT VERDICTS — AND THEY WERE ONE `if/elif` CHAIN UNTIL #283 SLICE 2.
#
# The exemption's honesty and the prose citations' resolution are different assertions about different
# things, and they were chained: a stale exemption returned `bad` from the second arm, so the prose
# verdict below it was never reached and emitted NEITHER `PASS` NOR `FAIL`. An assertion did not fail
# — it DISAPPEARED, while the totals stayed plausible, which is why no count would ever have surfaced
# it. That is this repo's signature defect (a check that silently stops checking) and it shipped inside
# the slice whose whole subject was that class. `quality-assurance` found it by toggling
# FOREIGN_ADR_NUMBERS on a mutated tree and watching the prose arm reappear.
#
# THE RULE THIS BLOCK NOW FOLLOWS is THE CHAINING RULE in this file's header, which is stated there
# rather than here so an arm added at line 1400 meets it too — this block is where it was learned, not
# where it applies. Each `if` below therefore repeats its own vacuity guard rather than borrowing its
# neighbour's — a broken extraction reddens BOTH, which is the correct reading, since both are vacuous.

# ── 4a · the foreign-number exemption is still earned, in both directions ──
if [ "$prose_checked" -eq 0 ] && [ -z "$foreign_seen" ]; then
  bad "citation resolution — the foreign-number exemption cannot be judged: not one 'ADR-nnnn' token of
      any kind was found across the tracked scan set, foreign or local. The extraction broke, so an
      exemption reading as unused below would be an artifact of the break and not a finding."
elif [ -n "$foreign_problems" ]; then
  bad "citation resolution — the foreign-number exemption is stale:$foreign_problems
      An exemption is only honest while it is still earned. If the number now names a record HERE,
      remove it from FOREIGN_ADR_NUMBERS so its citations are checked against this library; if nothing
      cites it any more, remove it because it exempts nothing and reads as evidence of a cross-repo
      citation that no longer exists."
elif [ -z "${FOREIGN_ADR_NUMBERS//[[:space:]]/}" ]; then
  # AN EMPTY EXEMPTION LIST IS NOT THE SAME GREEN, and it was reported as one: `wc -l` over an empty
  # list returns 1, because `printf '%s\n' ''` emits one blank line. The PASS read "each of the 1
  # numbers declared foreign" while nothing was declared at all — a universal quantified over an empty
  # set, wearing a count that was an artifact of the idiom. `grep -c .` is the counting idiom used
  # everywhere else in this file for exactly this reason; the empty case is now its own sentence.
  ok "citation resolution — NO number is declared foreign, so there is no exemption to keep earned. Every 'ADR-nnnn' token in the tracked scan set is checked against this library, which is the state to prefer"
else
  ok "citation resolution — each of the $(printf '%s\n' $FOREIGN_ADR_NUMBERS | grep -c . || true) numbers declared foreign is still cited here and still names no record in this library"
fi

# ── 4b · every prose `ADR-nnnn` names a live record ──
if [ "$prose_checked" -eq 0 ]; then
  bad "citation resolution — not one prose 'ADR-nnnn' citation was found across the tracked scan set,
      and there were 599 occurrences over 22 distinct numbers when this was written — 20 checked here
      and 2 declared foreign below, measured with the command in this block's header. The extraction
      broke and this check is vacuous."
elif [ -z "$prose_problems" ]; then
  ok "citation resolution — every prose ADR citation names a live record ($prose_checked distinct file/number pairs; $(printf '%s\n' $FOREIGN_ADR_NUMBERS | grep -c . || true) numbers declared foreign and NOT checked)"
else
  bad "citation resolution — a prose citation names a record that does not exist:$prose_problems
      This is the form that degrades WORST. A dangling relative link at least 404s when a human clicks
      it; a dangling 'ADR-nnnn' reads to an agent as a valid reference to a decision, forever, and
      nothing renders, errors or warns. If the record was folded elsewhere, every citation of it moves
      in the SAME commit. If it names a record in another repository, declare its number in
      FOREIGN_ADR_NUMBERS above and say which repository in the comment."
fi

# ══════════════════════════════════════════════════════════════════════════════════════════════════
# EVERY NUMBER THIS LIBRARY HAS ISSUED IS EITHER A LIVE RECORD OR AN ACCOUNTED-FOR ROW (#283, slice 2).
#
# WHAT THIS IS THE ENFORCEMENT OF. ADR-0020 made a History row mandatory when a REVERSED record is
# deleted, and said so in the record's own accepted-cost list: "Nothing enforces any of this —
# measured, not assumed." Its considered option 4 (build a gate) was deferred, not rejected, on one
# stated premise — "The deletion set in this library is EMPTY today, so the gate would have nothing to
# run against here." #283 removes that premise: it takes the deletion set from zero to roughly
# fourteen, and those fourteen are not reversals at all. They are live decisions being ABSORBED into a
# capability document. The row is the only artifact that says the absorption was authorised, and until
# this block existed nothing observed whether one was written.
#
# WHY THE ROW NEEDS A GATE WHEN THE CITATION BLOCK ABOVE ALREADY EXISTS. The citation block catches a
# deletion INDIRECTLY and only for a record something still cites: remove a record and its ~90 prose
# citations go red. That is most of the library and it is not all of it. A record cited nowhere — a
# late, narrow one, which is exactly the kind most likely to be absorbed — is deleted in perfect
# silence today, and the citation gate stays green because there is nothing left to dangle. This block
# closes that case by keying on the NUMBER rather than on who cites it.
#
# THE TWO LAYERS, AND WHICH CONTROL EACH CAN HOLD (ADR-0008's question, answered for this rule):
#   - THIS block asserts a row EXISTS for every retired number and that the row NAMES a destination.
#   - The relative-link check above resolves that destination, because the row's link is a relative
#     markdown link in a tracked `.md` like any other. It is deliberately NOT re-resolved here: one
#     resolver, not two that can disagree.
#   - The prose check above is what forbids the retired number being written as `ADR-nnnn` anywhere,
#     including in the row itself. That is why the row form declared in
#     `skills/documentation-standard/SKILL.md` is a BARE four-digit number: measured, `| 0008 | … |`
#     matches neither citation regex, and the same row written with an `ADR-` prefix matches the prose
#     one. The row can name a dead record precisely because it does not name it in the form a reader
#     would follow. The prefixed form is DESCRIBED rather than quoted here on purpose — the prose arm
#     greps the token, not the sentence, so a literal example in this comment would go red the day the
#     record it names is absorbed, and the obvious repair would be to edit an example that was correct.
#
# WHAT ONLY A HUMAN CAN CHECK, SAID PLAINLY SO THE GREEN IS NOT READ AS MORE THAN IT IS. Nothing here
# reads the destination's CONTENT. A row pointing at a capability document that does not actually carry
# the absorbed decision, its live rejected options and its consequences passes this gate exactly like
# one that does. The gate makes the absorption VISIBLE and ATTRIBUTABLE; whether it was LOSSLESS is a
# reviewer's judgement and there is no instrument for it. Do not let this green stand in for that read.
#
# WHY A DECLARED HIGH-WATER CONSTANT RATHER THAN max(live). Deriving the ceiling from the files that
# exist cannot see a deletion at the TOP of the sequence: remove the highest record and the derived max
# simply moves down by one, no gap appears, and the number is silently free to be reused later — which
# the citation block's own header already names as its worst residual ("A REDIRECT IS NOT A
# RESOLUTION"). A declared ceiling closes the ACCIDENTAL case — the top record removed with the
# constant left alone, which is the shape a real absorption takes. It does not close a DELIBERATE one,
# and no declared constant can: measured, lowering the constant in the same edit as the deletion
# re-greens the arm. The claim here read "closes that case completely" until #283 slice 2's re-review
# measured it; the word is corrected rather than the control, because the accidental case is the one
# worth closing and this is still a strict improvement on max(live).
# It costs one line per new record, and forgetting to bump it fails CLOSED: the ceiling check below
# goes red and says what to do.
ADR_HIGH_WATER=20

adr_live_count=0
adr_max=0
while IFS= read -r adr_file; do
  [ -z "$adr_file" ] && continue
  adr_base="$(basename "$adr_file")"
  adr_num="${adr_base%%-*}"
  case "$adr_num" in
    ''|*[!0-9]*) continue ;;
  esac
  adr_live_count=$((adr_live_count + 1))
  adr_n=$((10#$adr_num))
  [ "$adr_n" -gt "$adr_max" ] && adr_max="$adr_n"
done <<< "$(ls "$CITATION_ADR_DIR"/0*.md 2>/dev/null)"

# The History section, if it exists at all. It deliberately does NOT exist while the retired set is
# empty — ADR-0020 declined to invent a table with nothing to put in it, and this gate does not force
# one: with no gaps, nothing below looks for a row.
adr_history_rows=""
if [ -r "$CITATION_ADR_DIR/README.md" ]; then
  adr_history_rows="$(awk '/^## History/{h=1;next} /^## /{h=0} h' "$CITATION_ADR_DIR/README.md")"
fi

# The range the gap scan actually runs over. It is the DECLARED ceiling, except that a record numbered
# above it raises it for this scan only — so a stale constant reddens its own arm below WITHOUT taking
# the accounted-for verdict down with it. Chaining those two (the constant's arm above the row arm in
# one `if/elif`) is what hid a missing History row behind an unbumped constant until #283 slice 2.
adr_ceiling_scanned="$ADR_HIGH_WATER"
[ "$adr_max" -gt "$adr_ceiling_scanned" ] && adr_ceiling_scanned="$adr_max"

adr_gap_problems=""
adr_gaps_checked=0
adr_n=1
while [ "$adr_n" -le "$adr_ceiling_scanned" ]; do
  adr_padded="$(printf '%04d' "$adr_n")"
  set -- "$CITATION_ADR_DIR/$adr_padded"-*.md
  if [ -f "$1" ]; then
    adr_n=$((adr_n + 1))
    continue
  fi
  adr_gaps_checked=$((adr_gaps_checked + 1))
  adr_row="$(printf '%s\n' "$adr_history_rows" | grep -E "^\| *$adr_padded *\|" || true)"
  if [ -z "$adr_row" ]; then
    adr_gap_problems="$adr_gap_problems
    $adr_padded — no record file, and no '| $adr_padded |' row under '## History' in docs/adr/README.md"
  elif ! printf '%s' "$adr_row" | grep -q '](\./'; then
    adr_gap_problems="$adr_gap_problems
    $adr_padded — has a History row, but the row names NO destination (no relative '](./…)' link)"
  fi
  adr_n=$((adr_n + 1))
done

# The reverse direction: a row for a number that is still live. Either the deletion was reverted and
# the row was left behind, or the number was reissued — and a reissued number under an old row is the
# redirect hazard, wearing the artifact that is supposed to prevent it.
while IFS= read -r adr_row; do
  [ -z "$adr_row" ] && continue
  adr_rn="$(printf '%s' "$adr_row" | sed -n 's/^| *\([0-9][0-9][0-9][0-9]\) *|.*/\1/p')"
  [ -z "$adr_rn" ] && continue
  set -- "$CITATION_ADR_DIR/$adr_rn"-*.md
  [ -f "$1" ] || continue
  adr_gap_problems="$adr_gap_problems
    $adr_rn — has a History row AND a live record file; one of the two is wrong"
done <<< "$adr_history_rows"

# TWO SUBJECTS AGAIN, TWO INDEPENDENT VERDICTS. The declared ceiling being current and every issued
# number being accounted for are different assertions, and they were one `if/elif` chain in this
# block's first form: a record added without bumping the constant reddened the ceiling arm and the
# accounted-for arm below it emitted NOTHING, so a History row missing at the same time was invisible
# until someone bumped the constant. Same defect as 4a/4b above, in the block that shipped alongside it.
# The vacuity guard is repeated in both rather than shared, for the same reason it is there.

# ── every issued number is a live record or an accounted-for row ──
if [ "$adr_live_count" -eq 0 ]; then
  bad "record numbering — NOT ONE record file was found in docs/adr/, and there were 20 when this was
      written. The enumeration broke and the accounted-for scan is vacuous."
elif [ "$adr_gaps_checked" -ne $((adr_ceiling_scanned - adr_live_count)) ]; then
  bad "record numbering — the scan reports $adr_gaps_checked retired number(s) but $adr_ceiling_scanned
      issued minus $adr_live_count live is $((adr_ceiling_scanned - adr_live_count)). The range scan did
      not run over the range it claims — two files sharing a number will do this — so its per-number
      verdicts mean nothing."
elif [ -n "$adr_gap_problems" ]; then
  bad "record numbering — a number this library issued is accounted for by nothing:$adr_gap_problems
      A record leaves this library ONLY as a disposition, never as an absence. Write the row under
      '## History' in docs/adr/README.md — bare four-digit number, what was decided, and a relative
      link to where the decision now lives — in the SAME commit as the deletion. A deletion with no row
      is not a disposition; it is a gap, and a gap is indistinguishable from a mistake."
else
  ok "record numbering — $adr_live_count live records, ceiling $adr_ceiling_scanned, $adr_gaps_checked retired number(s), each carrying a History row that names a destination"
fi

# ── the declared ceiling is current ──
if [ "$adr_live_count" -eq 0 ]; then
  bad "record numbering — the declared ceiling cannot be judged: NOT ONE record file was found in
      docs/adr/. The enumeration broke, so ADR_HIGH_WATER has nothing to be compared against."
elif [ "$adr_max" -gt "$ADR_HIGH_WATER" ]; then
  bad "record numbering — the highest live record is $adr_max but ADR_HIGH_WATER is $ADR_HIGH_WATER.
      A record was added without raising the ceiling. Raise ADR_HIGH_WATER in this file to $adr_max in
      the same commit as the new record; until then a deletion at the top of the sequence is invisible
      to this gate. The accounted-for arm above scanned to $adr_ceiling_scanned regardless, so its
      verdict stands on its own and is not waiting on this repair."
else
  ok "record numbering — the declared ceiling $ADR_HIGH_WATER is at or above the highest live record $adr_max"
fi
# ══════════════════════════════════════════════════════════════════════════════════════════════════
# EVERY RECORD DECLARES A CAPABILITY, AND EVERY DECLARED NAME IS IN THE CLOSED SET (#283, slice 1).
#
# WHAT THE FIELD IS FOR. #283 reconciles this library from twenty records into a small number of
# CAPABILITY DOCUMENTS — the count is NOT written here, deliberately, because the set is published in
# docs/adr/README.md and read from there below. An earlier revision of this comment said "seven" and
# the set is now six; a comment carrying a copy of a number the same file derives two hundred lines
# later is the second-source-of-truth failure this whole arm exists to gate against, committed in the
# gate. `Capability` is the field that says which document a record belongs to — so "this slice
# closes capability X" is auditable from the tree rather than asserted in a PR body, and so a
# twenty-first record has to answer "which capability?" before it can exist. It is declared as a bullet
# in the record's own header list, immediately above `- **Status:**`, which is the one header line
# present at a predictable position in all twenty (`Status` is the FIRST bullet in every record;
# `Date`, `Deciders` and `Driven by` all wrap across lines in at least one).
#
# WHY A CLOSED SET AND NOT A FREE-TEXT FIELD. The entry rule this batch reformulates refuses a record
# that duplicates a capability already documented. A free-text field cannot refuse anything: a new
# record invents a new name and the rule reads as satisfied. The refusal lives in the SET, ratified
# once by the owner, and this gate is what makes it closed rather than advisory. Widening it stays
# allowed — as a visible edit to a published list, in the same diff as the record that needs it.
#
# WHAT THIS DOES NOT CHECK, said plainly so the green is not read as more than it is:
#   - Nothing here judges whether a record is in the RIGHT capability. A record declaring
#     `controls-and-enforcement` while deciding something about the roster passes. The mapping is a
#     reviewer's read, and there is no instrument for it. Two of this batch's own re-filings —
#     0012/0014 out of the retired `intake-and-routing`, and 0019 out of `decision-library` — were
#     found by reading, which is what "no instrument" costs stated concretely.
#   - NO COLLISION ARM SHIPS HERE — no assertion that two records declare different capabilities. That
#     is deliberate and it is a NAMED RESIDUAL, not an oversight: several records legitimately share
#     one name from this slice until that capability's fold lands, so a collision arm would be red for
#     the whole batch. It ships in the closing slice. Until then a duplicate is permitted and nothing
#     says so.
#   - The set's own membership is a decided list, derived from nothing. A name that should never have
#     been in it passes, and so does a record correctly declaring it. Demonstrated rather than
#     asserted: `intake-and-routing` sat in this set, gated and green, for the whole interval between
#     the two commits of #283 slice 1 — and it was retired for a reason no assertion here could ever
#     have raised.
#
# NO COUNT IS PUBLISHED BESIDE THE SET IN docs/adr/README.md, and that is a choice this file's whole
# subject argues for: a prose count next to the table is a second source of truth for the same fact,
# and this suite exists because that arrangement rots. The count below is DERIVED from the table and
# printed in the verdict, so there is nothing to keep in step — which is why dropping a row from the
# set needed no edit anywhere in the assertion logic, only in the two comments that had spelled the
# number out.

CAP_INDEX="$CITATION_ADR_DIR/README.md"

# The set, read from the one place it is published. The extraction is deliberately narrow — a table row
# under '## Capabilities' whose first cell is a backticked kebab name — so prose in that section cannot
# enter the set by accident, and a name written outside the table is not in it.
cap_set=""
if [ -r "$CAP_INDEX" ]; then
  cap_set="$(awk '/^## Capabilities/{c=1;next} /^## /{c=0} c' "$CAP_INDEX" \
    | sed -n 's/^| *`\([a-z][a-z0-9-]*\)` *|.*/\1/p')"
fi
cap_set_count="$(printf '%s\n' "$cap_set" | grep -c . || true)"
cap_set_dupes="$(printf '%s\n' "$cap_set" | grep -v '^[[:space:]]*$' | sort | uniq -d || true)"
# The DISTINCT count is what 5c's verdict quotes. `cap_set_count` counts ROWS, which is what the
# vacuity guards need — an unparsed table and a table of duplicates are different failures — but a row
# count would let 5c print "in the closed set of 8" over a set holding seven names and one repeat.
# Measured: that is exactly what it printed before this line existed (#283 slice 1, mutation MUT-5).
cap_set_distinct="$(printf '%s\n' "$cap_set" | grep -v '^[[:space:]]*$' | sort -u | grep -c . || true)"

cap_records_scanned=0
cap_names_checked=0
cap_missing=""
cap_multi=""
cap_unknown=""
while IFS= read -r cap_file; do
  [ -z "$cap_file" ] && continue
  [ -r "$cap_file" ] || continue
  cap_records_scanned=$((cap_records_scanned + 1))
  cap_rel="${cap_file#"$ROOT"/}"
  cap_decls="$(grep -c '^- \*\*Capability:\*\* ' "$cap_file" || true)"
  if [ "$cap_decls" -eq 0 ]; then
    cap_missing="$cap_missing
    $cap_rel — no '- **Capability:** <name>' line in the header list"
    continue
  fi
  if [ "$cap_decls" -gt 1 ]; then
    cap_multi="$cap_multi
    $cap_rel — declares $cap_decls capabilities; a record belongs to exactly one"
    continue
  fi
  cap_name="$(sed -n 's/^- \*\*Capability:\*\* *\([a-z][a-z0-9-]*\)[[:space:]]*$/\1/p' "$cap_file")"
  if [ -z "$cap_name" ]; then
    cap_unknown="$cap_unknown
    $cap_rel — the Capability line does not parse as a single kebab-case name"
    continue
  fi
  cap_names_checked=$((cap_names_checked + 1))
  if printf '%s\n' "$cap_set" | grep -qxF -- "$cap_name"; then
    :
  else
    cap_unknown="$cap_unknown
    $cap_rel — declares '$cap_name', which is not in the closed set in docs/adr/README.md"
  fi
done <<< "$(ls "$CITATION_ADR_DIR"/0*.md 2>/dev/null)"

# THREE SUBJECTS, THREE INDEPENDENT VERDICTS, each repeating its own vacuity guard rather than
# borrowing a neighbour's — THE CHAINING RULE in this file's header, applied to arms that did not exist
# when it was written. The three claims are genuinely different: the set parsing says nothing about
# whether records declare, a record with no field says nothing about the set, and membership is
# uncomputable without both. Chaining any two would make one of them DISAPPEAR rather than fail.

# ── 5a · the closed set itself parses, is non-empty, and repeats no name ──
if [ ! -r "$CAP_INDEX" ]; then
  bad "capability set — docs/adr/README.md is not readable, so the closed set could not be read at all.
      The membership verdict below is uncomputable, not green."
elif [ "$cap_set_count" -eq 0 ]; then
  bad "capability set — NO capability name parsed out of the '## Capabilities' section of
      docs/adr/README.md. Either the section is gone, or its table stopped matching the row form this
      gate reads: first cell a backticked kebab name. An empty set would let the membership arm below
      pass every record trivially, which is the direction this guard exists to close."
elif [ -n "$cap_set_dupes" ]; then
  bad "capability set — a name appears more than once in the closed set:
    $(printf '%s' "$cap_set_dupes")
      The set is the artifact the entry rule refuses against. A repeated row makes its size a claim
      nobody can trust and hides whichever of the two descriptions is the wrong one."
else
  ok "capability set — $cap_set_distinct distinct capability names declared in docs/adr/README.md"
fi

# ── 5b · every record declares exactly one capability ──
if [ "$cap_records_scanned" -eq 0 ]; then
  bad "record capability — NOT ONE record file was found in docs/adr/, and there were 20 when this was
      written. The enumeration broke and the declaration check is vacuous."
elif [ -n "$cap_missing$cap_multi" ]; then
  bad "record capability — a record does not declare exactly one capability:$cap_missing$cap_multi
      Add '- **Capability:** <name>' to the header list, immediately above '- **Status:**', naming one
      of the capabilities published in docs/adr/README.md. A record belonging to no capability document
      has nowhere to be folded and nothing for the entry rule to refuse it against."
else
  ok "record capability — all $cap_records_scanned records declare exactly one capability"
fi

# ── 5c · every declared capability is in the closed set ──
if [ "$cap_names_checked" -eq 0 ]; then
  bad "record capability — not one parseable capability name was extracted from any record, so
      membership was never tested against anything. With no name to check, a naive form of this arm
      reports success over an empty scan; it reports the break instead. 5b above says which records."
elif [ "$cap_set_count" -eq 0 ]; then
  bad "record capability — the closed set is empty or unparsed, so membership is uncomputable. Every
      declared name would 'fail' for the same reason, which is a fact about the set and not about any
      record; 5a above says what to repair."
elif [ -n "$cap_unknown" ]; then
  bad "record capability — a record declares a capability that is not in the closed set:$cap_unknown
      The set in docs/adr/README.md is closed and decided once for the whole library. A record that
      needs a name not on the list is either mis-filed, or it is the visible widening of a published
      list — which is a decision, taken in the same diff, not a spelling. (This message said 'the
      owner ratified it' until 2026-08-19. The owner ratified the SHAPE — an anchor keeps its number
      and filename; the NAMES were decided inside the loop. A refusal message that overstates who is
      behind the rule makes disagreeing with a name look like disagreeing with the owner.)"
else
  ok "record capability — all $cap_names_checked declared capabilities are in the closed set of $cap_set_distinct"
fi


printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
