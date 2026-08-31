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
#     `agents-lead` in one slice, the count held at five, and every assertion in this file stayed
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
# ── AND THEN VERIFY THE MUTATION LANDED, BEFORE YOU BELIEVE THE RESULT ──────────────────────────────
#
# A MUTATION PROBE THAT SILENTLY FAILS TO MUTATE PRODUCES A FALSE GREEN INDISTINGUISHABLE FROM A
# WORKING GATE. This is the failure mode ABOVE the one the previous paragraph fixes: you did run a
# mutation, so the "a reason is not evidence" rule is satisfied — and the clean result you got back is
# still worthless, because the file was never changed. The two are indistinguishable from the exit
# code alone, and the reassuring direction is the one you get for free.
#
# Measured here (#322 review): a probe planting a literal with
#   perl -i -ne 'print; END{print "<literal>"}' <file>
# reported a clean run of this suite. The gate had not passed — the probe had not fired. Under `-i`
# perl's END block runs AFTER the in-place output handle is closed, so the appended literal went to
# STDOUT and never entered the file. The suite was, correctly, reporting on an unmutated tree.
#
# SO THE STEP IS: after mutating and before running anything, READ THE FILE BACK and confirm the
# defect is present — `grep -c` the planted literal, or `git diff --stat` the target. One command,
# and it is the only thing separating "this arm holds" from "my editor no-opped". Confirm the same
# way that the mutation is REVERTED afterwards; a probe left in place turns the next run's red into a
# mystery.
#
# This generalises past this arm and past this file: it is a property of mutation testing, not of
# anything specific here. It is written at the header rather than beside the one arm that caught it
# for the same reason the chaining rule above is — the next person to mutate this suite will be
# working somewhere else in it.
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
# ── THERE IS NO FAMILY. ONE LEVEL, FOURTEEN DIRECTORIES (#286) ────────────────────────────────────
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
      Since #286 the library is ONE level: fourteen directories under skills/, no families. A file at
      any other depth is outside every count, table and resolver in this suite — and it still loads if
      plugin.json declares it, so nothing else would report it."
else
  ok "skill tree shape — all $total skills sit at skills/<name>/SKILL.md, one level, no families"
fi

# --- NO SKILL CARRIES A `name:` FRONTMATTER KEY ------------------------------------------------
#
# THE INVARIANT IS PUBLISHED IN THREE PLACES AND WAS ASSERTED IN NONE, until #316. `README.md` states
# it with its own command beside it, and `hooks/scripts/kiro-power-build.py`'s docstring states it as
# the DESIGN PREMISE for synthesising `name` from the directory — the whole reason the Kiro export is
# a projection rather than a copy. Claude Code derives the identifier from the directory too, so a
# `name:` key here is at best inert and at worst a second source of truth for the same string.
#
# HOW IT SHIPPED, because the cause is live rather than a one-off slip. A persona brief
# (`agents/<name>.md`) DOES carry `name:`, and #316 extracted brief prose into a new skill — copying
# the frontmatter shape along with the content. That is the exact move the remaining steps of the
# content-flow reconfiguration will keep making, so the next occurrence is likelier than the first.
#
# WHY THIS ONE IS SAFE TO GATE AND THE SPELLED-OUT-COUNT SWEEP IS NOT (the sibling arm proposed on
# #316 and deliberately NOT built): there is exactly ONE correct value here — zero, for every skill —
# so the check cannot redden on correct content. A sweep for the WORD "thirteen" cannot make that
# claim: the same token is legitimate in an ordinal, a SHA-pinned measurement, a past-tense
# counterfactual and an accepted ADR that may not be rewritten, and telling those from live drift is
# a judgement about TENSE that no grep performs. Gating it would need an exemption list — an
# enumeration inside the file written to catch stale enumerations, this suite's signature defect.
#
# WHAT IT DOES NOT CATCH: a `name:` that is CORRECT (equal to the directory). It is still refused,
# deliberately — the property is "the identifier has one source", not "the key happens to agree".
named=""
named_scanned=0
while IFS= read -r d; do
  [ -z "$d" ] && continue
  f="$d/SKILL.md"
  [ -f "$f" ] || continue
  named_scanned=$((named_scanned + 1))
  # Frontmatter only: a `name:` at column 0 in the BODY is prose, not a key. The block is the span
  # between the first two `---` lines, which is how every other reader in this file scopes it.
  if awk '/^---$/{n++; next} n==1' "$f" | grep -q '^name:'; then
    named="$named
    ${f#"$ROOT"/} — carries a 'name:' key in its frontmatter"
  fi
done <<< "$SKILL_DIRS"

if [ "$named_scanned" -eq 0 ]; then
  bad "skill frontmatter — no skill files were scanned; this assertion did NOT run"
elif [ -n "$named" ]; then
  bad "skill frontmatter — a skill declares 'name:', which no skill in this library may:$named
      Claude Code derives the identifier from the DIRECTORY, and kiro-power-build.py synthesises
      'name' from it for the Kiro export — so the key is a second source of truth for a string that
      already has one. Delete the line. README.md and kiro-power-build.py's docstring both publish
      this absence as an invariant; leaving the key makes both false."
else
  ok "skill frontmatter — none of the $named_scanned skills carries a 'name:' key (the identifier's one source is the directory)"
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
# #165, when `commands/autonomy-off.md` shipped as the deliberate off-switch autonomy-on always lacked,
# then 3 → 4 on #313 slice 2, when `commands/blueprint.md` shipped the harness export. The fourth is a
# typed command for the same reason as the other three and for one more: its argument selects DIRECTION
# (empty exports, text would import), which is a thing a human types and a model cannot be matched into.
# Then 4 → 5 on #355, when `commands/retrospective.md` shipped the iteration retrospective rite. It is
# typed for the reason the Issue itself raised as an open question: an iteration drained by HAND never
# reaches the drain's terminal condition, so the fallback route has to be a human typing an iteration
# name — and an iteration name is an argument, which is what `argument-hint` exists for.
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
if [ "$root_cmds" -eq 5 ]; then
  ok "commands/ root — exactly five owner-typed commands (autonomy-on, autonomy-off, new-issue, blueprint, retrospective), as the docs enumerate"
else
  bad "commands/ root — $root_cmds file(s); the docs enumerate five owner-typed commands (autonomy-on, autonomy-off, new-issue, blueprint, retrospective).
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

  # --- the EVENT count, which is a different number from both of the ones already pinned above ----
  #
  # THIS FILE'S OWN HEADER, TWENTY LINES UP, SAYS: "THE HOOKS WERE THE ONE INVENTORY NOBODY PINNED,
  # and it cost a false claim on a public page." It then pinned two numbers — REGISTRATIONS (the
  # `"command"` count) against DIAGRAM NODES (`H<n>[`) — and left a third unpinned in the same
  # section of the same README: how many EVENTS are wired.
  #
  # All three are different, and the README asserted the wrong one as a partition of 31:
  #
  #   registrations   15   one per `"command"` entry — closure-artifact-guard and preflight twice each
  #   diagram nodes   15   one box per registration, by construction of the arm above
  #   FILLED nodes     5   the drawing collapses SubagentStart · SubagentStop · TeammateIdle into one
  #   EVENTS wired     6   `jq '.hooks | keys | length'`
  #
  # The prose said "wires five … the other twenty-six", which is the FILLED-NODE count written as an
  # event count, over a denominator of 31 events. It was "four" before #342 — wrong by one in the
  # same way, for six days, while the event table 280 lines below bolded six events by name. Caught
  # by the copy lens on the PR, not by this file, because nothing here read the prose.
  #
  # WHAT IS PINNED AND WHAT CANNOT BE. The wired figure and its complement are derived from
  # hooks.json. The 31 is NOT derivable here — it is a property of Claude Code, not of this repo — so
  # the arm reads it from the prose and checks only that the partition CLOSES. A reader who wants the
  # 31 falsified has to go and count the platform's events; this asserts that whatever total the
  # README claims, the two parts it splits into add up to it and the wired part is the true one.
  #
  # NUMBER WORDS, NOT DIGITS, because that is how this README writes counts and a gate should not
  # force a house style. The map is a closed set; a figure outside it fails loudly rather than
  # silently reading as zero.
  ev_word_to_int() {
    case "$1" in
      zero) printf '0' ;;      one) printf '1' ;;        two) printf '2' ;;
      three) printf '3' ;;     four) printf '4' ;;       five) printf '5' ;;
      six) printf '6' ;;       seven) printf '7' ;;      eight) printf '8' ;;
      nine) printf '9' ;;      ten) printf '10' ;;       eleven) printf '11' ;;
      twelve) printf '12' ;;
      twenty-one) printf '21' ;;   twenty-two) printf '22' ;;   twenty-three) printf '23' ;;
      twenty-four) printf '24' ;;  twenty-five) printf '25' ;;  twenty-six) printf '26' ;;
      twenty-seven) printf '27' ;; twenty-eight) printf '28' ;; twenty-nine) printf '29' ;;
      *) printf '' ;;
    esac
  }

  ev_actual="$(jq -r '.hooks | keys | length' "$HOOKS_JSON" 2>/dev/null || printf '')"
  ev_total_claimed="$(sed -nE 's/.*\*\*([0-9]+) hook events\*\*.*/\1/p' "$README" | head -1)"
  ev_wired_word="$(sed -nE 's/.*This repo wires \*\*([a-z-]+)\*\*.*/\1/p' "$README" | head -1)"
  ev_unwired_word="$(sed -nE 's/.*the other \*\*([a-z-]+)\*\* are not.*/\1/p' "$README" | head -1)"
  ev_wired="$(ev_word_to_int "$ev_wired_word")"
  ev_unwired="$(ev_word_to_int "$ev_unwired_word")"

  if [ -z "$ev_actual" ]; then
    bad "hooks/ — the wired-EVENT count could not be read from hooks.json, so the three arms below
      are checking nothing. Either jq is absent or the file stopped being an object keyed by event."
  elif [ -z "$ev_wired" ]; then
    bad "hooks/ — README's 'This repo wires **<word>**' did not parse, or the word is outside the
      closed set this arm knows ('$ev_wired_word'). hooks.json wires $ev_actual event(s). A figure
      this arm cannot read is a figure it cannot falsify, which is the state this whole block exists
      to end."
  elif [ "$ev_wired" != "$ev_actual" ]; then
    bad "hooks/ — README says this repo wires '$ev_wired_word' ($ev_wired) event(s); hooks.json wires
      $ev_actual: $(jq -r '.hooks | keys | join(", ")' "$HOOKS_JSON").
      This is the count that was wrong twice — do not fix it by counting boxes in the diagram, which
      collapses several events into one node and is a different number on purpose."
  else
    ok "hooks/ — README's wired-EVENT figure ('$ev_wired_word') matches hooks.json's $ev_actual event key(s)"
  fi

  # THE EMPTY-OPERAND GUARD IS NOT DEFENSIVE TIDINESS — IT IS THE ARM'S OWN MUTATION FINDING.
  # The first draft read `elif [ -n "$ev_wired" ] && [ "$((…))" != … ]`, so an UNPARSEABLE wired
  # figure fell through to the success branch and printed
  #     ok  the event partition closes:  wired + 25 unwired = 31 claimed
  # — a PASS line, with a blank where a number belongs, reporting a computation that never ran.
  # Found by mutating the README's figure out of the parseable form and reading the output rather
  # than the total (the total was red anyway, from the arm above, which is exactly how a verdict
  # like this survives: the suite fails for a different reason and nobody reads the line). An arm
  # that cannot compute must say so; it must never report the answer it did not reach.
  if [ -z "$ev_total_claimed" ] || [ -z "$ev_unwired" ] || [ -z "$ev_wired" ]; then
    bad "hooks/ — the event partition is UNCOMPUTABLE, so it is unchecked rather than passing:
      total='$ev_total_claimed', wired word='$ev_wired_word', unwired word='$ev_unwired_word'.
      The README states 'N hook events', 'This repo wires **<word>**' and 'the other **<word>** are
      not'; at least one stopped matching. Restore the form or widen the word map — do not leave a
      figure here that no arm can read."
  elif [ "$((ev_wired + ev_unwired))" != "$ev_total_claimed" ]; then
    bad "hooks/ — the event partition does not close: $ev_wired wired + $ev_unwired unwired
      = $((ev_wired + ev_unwired)), against the $ev_total_claimed hook events the same sentence
      claims. Both halves are stated in prose over a denominator this repo cannot derive, so a
      partition that does not add up is the only signal available that one of them moved."
  else
    ok "hooks/ — the event partition closes: $ev_wired wired + $ev_unwired unwired = $ev_total_claimed claimed
      (the $ev_total_claimed itself is a property of Claude Code and is deliberately NOT falsified here)"
  fi
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
# `agents-lead.md` IS EXCLUDED, and this is a naming collision, not a re-widened scope. Issue #216
# renamed the harness persona's file to end in `-lead` for tier-equality prose ("the owner's pair on
# the MACHINERY — same tier as the leads"), and CLAUDE.md is explicit that it is NOT one of "the two
# leads": those are `product-lead` and `tech-lead`, the two who close an Issue's description and are
# addressed together as "the two leads" throughout this repo's prose. A bare `*-lead.md` glob cannot
# tell the two apart by name alone, so the exclusion is spelled out here rather than left to a suffix
# match that would otherwise silently promote every future `*-lead.md` file into this count.
lead_files=$(find "$ROOT/agents" -maxdepth 1 -name '*-lead.md' -type f ! -name 'agents-lead.md' | wc -l | tr -d ' ')
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

    # 2 — python3 and node must BE in `allow`. ADR-0004 prices these as accepted non-containment, and
    #     `permission-guard.test.sh` asserts their silence as a PRICED gap rather than a hole. If they
    #     were removed, that section would be describing a floor that no longer exists — and an
    #     absence-only check would go green on it, which is a different floor than the one recorded.
    for interp in python3 node; do
      hit="$(printf '%s\n' "$allow_entries" | grep -E "^Bash\($interp([[:space:]]|:)" || true)"
      if [ -n "$hit" ]; then
        ok "permission floor — '$interp' present in allow, as ADR-0004 prices it"
      else
        bad "permission floor — '$interp' is NO LONGER in allow; ADR-0004 and permission-guard.test.sh both describe it as a priced, accepted gap. Update those records or restore the entry — do not leave them describing a floor that is gone"
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
    #     The number is written BARE throughout this note, never prefixed and never as a path: 0008 was
    #     absorbed on 2026-08-20 (#283 slice S3), and the prefixed and path forms are the two the citation gate resolves
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
    #     AND IT IS DELETED RATHER THAN REPOINTED because the coupling itself is the defect: #283 folded
    #     record 0008 into the `controls-and-enforcement` capability document on 2026-08-20 — and the
    #     anchor's own FILENAME changed in the same slice, from `0004-autonomy-and-permission-model.md`
    #     to `0004-controls-and-enforcement.md`. A gate tied to a
    #     record BY FILENAME is exactly the coupling that fold breaks silently, and this slice moved
    #     both ends of it at once, which is the strongest available evidence that deleting was right. (That capability was
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
# GREEN in `docs/adr/0008` (that record was absorbed into `0004-controls-and-enforcement.md` on
# 2026-08-20; the measurement is dated and is left as it was taken). So the check covered every layer that had self-corrected and none of the
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
# THE DEFECT: `security` was deleted from `agents/` and `agents-lead` was added in the same slice.
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
  # ("one fullstack developer", "an agents-lead") rather than in the backticked form this pattern
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
  # `skills/code-review/SKILL.md` naming the two gates, `docs/adr/0004` naming the two it is about.
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

# ── AND WITHIN permission-guard.sh ITSELF, which is where the drift actually was (2026-08-23) ────────────
# The two arms above compare wip-guard.sh against permission-guard.sh's FIRST class and stop there.
# Measured at origin/main, that was a blind spot big enough to hold two live fail-opens: the same grep
# pointed at permission-guard.sh alone returned THREE DIFFERENT classes —
#
#   `gh_repo_flag` (the shared definition)   (-R[[:space:]=]*|--repo[[:space:]=]*)   correct
#   rule 5c, `gh issue create`               (-R[[:space:]]*|--repo[[:space:]=]*)    `-R=x` slipped past
#   rule 7c, the merge-verdict extraction    (-R|--repo)                             plus a `^gh` anchor
#
# — and BOTH suites were green, because nothing compared a file's copies to each other. The 5c copy
# turned the subagent issue gate off for `gh -R=owner/x issue create`; the 7c copy turned the merge
# gate's verdict check off for `gh pr merge N --repo owner/x`, which is the spelling `command-hygiene`
# MANDATES. A rule defeated by following the instructions.
#
# THIS IS DELIBERATELY THE SAME SHAPE AS THE ARMS ABOVE and not a cleverer one: emit every copy, and
# report any that is not the first. The first is `gh_repo_flag`'s own definition, which is the class
# every rule interpolates when it does not hand-roll one — so "identical to the first" is exactly
# "identical to the shared class".
guard_classes="$(grep -oE '\((-R|--repo)[^)]*\)' "$ROOT/hooks/scripts/permission-guard.sh")"
if [ -z "$guard_class" ] || [ -z "$guard_classes" ]; then
  bad "flag class — no -R/--repo class could be extracted from permission-guard.sh, so its copies
      cannot be compared to each other. A green here would be an artifact of the break."
elif printf '%s\n' "$guard_classes" | grep -qvxF -- "$guard_class"; then
  bad "flag class — permission-guard.sh parses the repo flag DIFFERENTLY in different rules.
      shared class: $guard_class
      all copies:   $(printf '%s' "$guard_classes" | tr '\n' ' ')
      A hand-rolled copy that is a spelling behind is a rule that is OFF for that spelling, silently.
      That is how rule 5c missed 'gh -R=owner/x issue create' and rule 7c missed
      'gh pr merge N --repo owner/x' — the spelling command-hygiene tells every persona to use."
else
  ok "flag class — every copy inside permission-guard.sh parses -R/--repo with the identical class"
fi

# ---------------------------------------------------------------------------------------------------
# THE SAME PRECEDENT, FOR A SECOND DUPLICATED LITERAL: rule 7c (permission-guard.sh) re-checks the
# gatekeeper-verdict marker at merge time, and session-wip.sh's verdict_suffix() reads it to annotate
# the open-PR queue. Both need the SAME jq literal-extraction + SHA/author-matching program, and a
# hook cannot source code out of another hook — same reason wip-guard.sh carries its own copy of
# `gh_repo_flag` rather than importing permission-guard.sh's. Anchored on `def literal` through the
# `if length == 0 …` line, which is the whole selection pipeline; a drift here is exactly the shape
# that let `gh -R=owner/x pr create` slip past wip-guard for a week on the OTHER duplicated literal.
guard_literal="$(grep -A11 'def literal(\$lines; \$m):' "$ROOT/hooks/scripts/permission-guard.sh" 2>/dev/null || true)"
wip_literal="$(grep -A11 'def literal(\$lines; \$m):' "$ROOT/hooks/scripts/session-wip.sh" 2>/dev/null || true)"
if [ -z "$guard_literal" ] || [ -z "$wip_literal" ]; then
  bad "verdict literal — the jq extraction block could not be found in
      $([ -z "$guard_literal" ] && printf 'permission-guard.sh ')$([ -z "$wip_literal" ] && printf 'session-wip.sh ')— nothing was
      found to compare, so a green here would be an artifact of the break and not a finding."
elif [ "$guard_literal" != "$wip_literal" ]; then
  bad "verdict literal — permission-guard.sh's rule 7c and session-wip.sh's verdict_suffix() read the
      gatekeeper-verdict marker DIFFERENTLY. One of them is a spelling behind — this is how the merge
      gate and the queue notice would disagree about which verdict a PR actually carries."
else
  ok "verdict literal — rule 7c's copy is byte-identical to session-wip.sh's verdict_suffix()"
fi

# ---------------------------------------------------------------------------------------------------
# THE VERDICT VOCABULARY ITSELF — the drift the byte-identity check above cannot see. That check proves
# the two hooks READ the marker the same way; it says nothing about whether the SET OF LITERALS they
# recognise matches the set `agents/quality-assurance.md` actually defines. ADR-0004's own Context
# section measures that exact failure: three drifted literals shipped in one day (`ADVISORY-ONLY`,
# `CLEAN`, `APPROVED`), each found by reading, none findable by a check. Adding a fourth literal
# (`APPROVE-AND-MERGE-BOUNDARY`, ADR-0002 amendment #16) widens that surface rather than narrowing it,
# which is why the check lands in the same diff as the literal.
#
# THE SOURCE OF TRUTH IS THE PERSONA FILE'S OWN "Your verdict — exactly one of" LIST, parsed from it —
# not a set restated here, which would be a second source of truth for one fact and would rot exactly
# the way the thing it is guarding rots.
#
# TWO ARMS, EACH EMITTING ITS OWN VERDICT (this file's own rule, earned at #283 slice 2: an arm that
# shares a verdict with the one above it can DISAPPEAR rather than fail, and no total moves to say so).
qa_verdicts="$(awk '/^## Your verdict — exactly one of/{f=1;next} f&&/^## /{exit} f&&/^- \*\*[A-Z][A-Z-]*\*\*/{gsub(/^- \*\*/,"");gsub(/\*\*.*$/,"");print}' \
  "$ROOT/agents/quality-assurance.md" 2>/dev/null || true)"
# CASE-PATTERN LINES ONLY, never a plain grep of the file. Both hooks now carry comments that NAME the
# new literal, so a `grep -F` for it passes on a file where the literal was deleted from the case arm
# and survives only in the prose explaining why it is there. Mutation-checked against exactly that.
wip_patterns="$(awk '/^  case "\$verdict" in/{f=1} f{print} f&&/^  esac/{exit}' \
  "$ROOT/hooks/scripts/session-wip.sh" 2>/dev/null \
  | grep -oE "^[[:space:]]*[A-Z][A-Z'|-]*\)" | tr -d ' )' | tr '|' '\n' || true)"
guard_accept="$(grep -oE "^[[:space:]]*[A-Z][A-Z'|-]*\) : ;;" "$ROOT/hooks/scripts/permission-guard.sh" 2>/dev/null \
  | sed -E 's/\) : ;;$//' | tr -d ' ' | tr '|' '\n' | grep -v "^''$" || true)"

if [ -z "$qa_verdicts" ] || [ -z "$wip_patterns" ]; then
  bad "verdict vocabulary — nothing was extracted from
      $([ -z "$qa_verdicts" ] && printf 'agents/quality-assurance.md ')$([ -z "$wip_patterns" ] && printf 'session-wip.sh ')— a green here would
      be an artifact of the parse breaking, not a finding."
else
  missing_in_wip=""
  while IFS= read -r v; do
    [ -z "$v" ] && continue
    printf '%s\n' "$wip_patterns" | grep -qx "$v" || missing_in_wip="${missing_in_wip} ${v}"
  done <<EOF
$qa_verdicts
EOF
  if [ -n "$missing_in_wip" ]; then
    bad "verdict vocabulary — session-wip.sh's verdict_suffix() does not recognise:${missing_in_wip}.
      Its \`*)\` arm does not degrade to silence — it reports 'an UNRECOGNISED verdict … a defect in the
      gate rather than in the PR'. So a literal the gate correctly posts, missing from that case, turns
      every correctly-verdicted PR into a false defect report in the open-PR queue notice."
  else
    ok "verdict vocabulary — session-wip.sh recognises every literal quality-assurance.md defines"
  fi
fi

if [ -z "$qa_verdicts" ] || [ -z "$guard_accept" ]; then
  bad "verdict vocabulary — rule 7c's accept arm could not be extracted from permission-guard.sh;
      nothing was compared, so a green would be an artifact of the break."
else
  phantom=""
  while IFS= read -r v; do
    [ -z "$v" ] && continue
    printf '%s\n' "$qa_verdicts" | grep -qx "$v" || phantom="${phantom} ${v}"
  done <<EOF
$guard_accept
EOF
  if [ -n "$phantom" ]; then
    bad "verdict vocabulary — permission-guard.sh rule 7c AUTHORISES A MERGE on literal(s) that
      agents/quality-assurance.md does not define:${phantom}. This is the drift that made rule 7c
      necessary, now sitting inside rule 7c: the merge floor would clear a verdict the gate has no
      way to post, so the only thing that could produce it is something other than the gate."
  else
    ok "verdict vocabulary — every literal rule 7c merges on is one quality-assurance.md defines"
  fi
fi

# ---------------------------------------------------------------------------------------------------
# THE THIRD DUPLICATED LITERAL, AND WHY IT MUST NOT BE RENAMED: `agents-lead`#291 kept the exact
# marker string `harness-lead-verdict` unchanged when the persona that produces it was renamed from
# `harness-lead` to `agents-lead`, on the argument that every marker already posted to a GitHub
# comment is unrewritable — renaming the string would make every prior verdict invisible to both
# consumers below, with no red anywhere to say so. That decision makes this a DELIBERATE, DOCUMENTED
# inconsistency (the producer's own filename no longer matches the string it emits) rather than an
# oversight, and #291 requires a test pinning it — this is that test. It does not assert the marker
# is well-formed, only that all three sites that must agree on its spelling still do.
marker_producer="$(grep -c 'harness-lead-verdict' "$ROOT/agents/agents-lead.md" 2>/dev/null || true)"
marker_qa="$(grep -c 'harness-lead-verdict' "$ROOT/agents/quality-assurance.md" 2>/dev/null || true)"
marker_metrics="$(grep -c 'harness-lead-verdict' "$ROOT/hooks/scripts/dispatch-metrics-stop.sh" 2>/dev/null || true)"
if [ -z "$marker_producer" ] || [ "$marker_producer" = "0" ] || \
   [ -z "$marker_qa" ] || [ "$marker_qa" = "0" ] || \
   [ -z "$marker_metrics" ] || [ "$marker_metrics" = "0" ]; then
  bad "marker literal — the exact string \`harness-lead-verdict\` was not found in one or more of the
      three sites that must agree on it: agents/agents-lead.md (producer, $marker_producer hits),
      agents/quality-assurance.md (consumer, $marker_qa hits), hooks/scripts/dispatch-metrics-stop.sh
      (consumer, $marker_metrics hits). A spelling drift here is a boundary-class review that never
      reaches the PR, and a metrics hook that silently stops counting rework rounds."
else
  ok "marker literal — \`harness-lead-verdict\` is spelled identically across its producer
      (agents/agents-lead.md) and both consumers (agents/quality-assurance.md,
      hooks/scripts/dispatch-metrics-stop.sh) — kept unrenamed on purpose across the agents-lead
      rename (#291), since prior GitHub comments carrying it cannot be rewritten"
fi

# ---------------------------------------------------------------------------------------------------
# THE MARKER'S SURFACE (#336). Spelling the literal identically is not enough: until 2026-08-28 the
# producer instructed `gh issue comment` "where the proposal is still an Issue with no PR yet — which
# is the common case", while the consumer's hold 2 requires the marker ON THE PR. Both files spelled
# the string the same way and named DIFFERENT surfaces, so the arm above stayed green through a
# contradiction that either blocks a properly-reviewed diff or quietly loosens hold 2 — and nothing
# afterwards can tell which happened, because a verdict records the literal and not where it was read.
# The owner's ruling (#336): a review artifact lives with the review, so the marker lives on the PR.
#
# THIS IS A DRIFT CHECK OVER A STRING, NOT A CONTENT CHECK, and the distinction is the whole of what
# it is worth. It asserts both files still carry the one-surface sentence; it cannot assert either
# means it, and it can never observe where a marker was actually posted. NO HOOK CAN: `command-hygiene`
# requires every comment body to go through `--body-file`, so the marker text is never in the command
# string a PreToolUse hook sees — a guard keyed on the literal would fire only on the inline `--body`
# form this repo already forbids, i.e. it would be inert exactly where it would have to work.
# Its own verdict, never chained onto the arm above (#283's lesson: an elif hides an assertion by
# never reaching it, and the totals stay plausible while a check disappears).
marker_surface_producer="$(grep -c 'marker lives on the PR' "$ROOT/agents/agents-lead.md" 2>/dev/null || true)"
marker_surface_qa="$(grep -c 'marker lives on the PR' "$ROOT/agents/quality-assurance.md" 2>/dev/null || true)"
if [ -z "$marker_surface_producer" ] || [ "$marker_surface_producer" = "0" ] || \
   [ -z "$marker_surface_qa" ] || [ "$marker_surface_qa" = "0" ]; then
  bad "marker surface — the one-surface sentence \`marker lives on the PR\` is missing from one or both
      of the files that must agree on it: agents/agents-lead.md (producer, $marker_surface_producer
      hits), agents/quality-assurance.md (consumer, $marker_surface_qa hits). Producer and consumer
      naming different surfaces is #336's defect verbatim, and it is unattributable after the fact."
else
  ok "marker surface — producer (agents/agents-lead.md) and consumer (agents/quality-assurance.md)
      both carry the one-surface sentence \`marker lives on the PR\` (#336). Drift check over a
      string: it cannot tell whether either file means it, and no hook can observe where a marker
      was actually posted, since --body-file keeps the text out of the command string"
fi

# ---------------------------------------------------------------------------------------------------
# THE CONTENT PAIR'S SHARED CONSTANTS (#317). Three arms, each its own verdict — the lesson #283's
# re-sweep paid for twice is that a chained `elif` hides an assertion by never reaching it, and the
# totals stay plausible while a check DISAPPEARS. Nothing here is chained.
#
# WHAT THIS GATES AND WHAT IT CANNOT. The pair's whole value is that both halves judge against ONE
# ruler and stop on ONE mechanical condition. Both of those live in prose, in two files, and prose in
# two files is this repo's most-paid-for defect class. So: the preload identity is asserted (arm A),
# and the terminal literals are asserted present in both briefs with no third spelling anywhere (arm
# B/C). What is NOT gated, and is a reviewer's read: whether a round file was actually written, whether
# a finding really quoted a clause, and whether the writer dropped an advisory finding it should have
# taken. No instrument reaches any of those, and a green here must not stand in for them.
CP_W="$ROOT/agents/content-writer.md"
CP_R="$ROOT/agents/content-reviewer.md"

# ── ARM A: the pair preloads the SAME ruler ────────────────────────────────────────────────────────
# Derived from the frontmatter of both files rather than written here, so the assertion is "identical"
# and not "both contain published-voice" — a reviewer gaining a fourth skill the writer lacks is the
# drift this exists to catch, and a containment check would pass straight through it.
cp_w_skills="$(sed -n '/^skills:/,/^---$/p' "$CP_W" 2>/dev/null | sed -n 's/^  - //p' | sort)"
cp_r_skills="$(sed -n '/^skills:/,/^---$/p' "$CP_R" 2>/dev/null | sed -n 's/^  - //p' | sort)"
if [ -z "$cp_w_skills" ] || [ -z "$cp_r_skills" ]; then
  bad "content pair — one or both briefs declared NO preloaded skills (content-writer: $(printf '%s' "$cp_w_skills" | grep -c . || true), content-reviewer: $(printf '%s' "$cp_r_skills" | grep -c . || true)). Either a brief was deleted or its frontmatter shape changed; an empty-vs-empty comparison would pass for no reason, which is why this arm exists ahead of the equality below."
elif [ "$cp_w_skills" != "$cp_r_skills" ]; then
  bad "content pair — the drafter and the reviewer no longer preload the same skills, so they no longer
      judge against the same sentences. That identity IS the reason published-voice was extracted to a
      skill (#316) and the reason the pair is worth its cost at all (#317).
        content-writer:   $(printf '%s' "$cp_w_skills" | tr '\n' ' ')
        content-reviewer: $(printf '%s' "$cp_r_skills" | tr '\n' ' ')
      If one of them genuinely needs a skill the other must not have, that is a decision to record in
      ADR-0002 and to state in both briefs — not a difference to leave standing here."
else
  ok "content pair — content-writer and content-reviewer preload an identical skill list ($(printf '%s' "$cp_w_skills" | tr '\n' ' '))"
fi

# ── ARM B: both terminal literals are named in BOTH briefs ─────────────────────────────────────────
# The bound is only mechanical if the drafter recognises the same two strings the reviewer writes. A
# literal known to one side is a terminal condition only that side can evaluate.
cp_missing=""
for lit in CONTENT-REVIEW-FINDINGS CONTENT-REVIEW-CLEAR; do
  grep -qF -- "$lit" "$CP_W" 2>/dev/null || cp_missing="$cp_missing content-writer.md:$lit"
  grep -qF -- "$lit" "$CP_R" 2>/dev/null || cp_missing="$cp_missing content-reviewer.md:$lit"
done
if [ -n "$cp_missing" ]; then
  bad "content pair — a terminal literal is missing from a brief that must recognise it:$cp_missing
      The round bound stops being mechanical the moment one side does not know the string the other
      writes; it degrades to 'someone reads the file and judges', which is the state /harness-engineering
      calls no state at all."
else
  ok "content pair — both terminal literals (CONTENT-REVIEW-FINDINGS, CONTENT-REVIEW-CLEAR) appear in both briefs"
fi

# ── ARM C: no THIRD literal has been invented ──────────────────────────────────────────────────────
# The direction arm B is blind to, and it is the one quality-assurance's own verdict-set gate learned to
# check: adding a spelling reddens nothing when the assertion only asks whether the known ones survive.
# Scope is the two briefs plus the guard rule and the state table that quote them.
cp_phantom="$(grep -rhoE 'CONTENT-REVIEW-[A-Z-]+' "$CP_W" "$CP_R" \
  "$ROOT/hooks/scripts/permission-guard.sh" "$ROOT/skills/harness-engineering/SKILL.md" 2>/dev/null \
  | sort -u | grep -vxE 'CONTENT-REVIEW-(FINDINGS|CLEAR)' || true)"
if [ -n "${cp_phantom//[[:space:]]/}" ]; then
  bad "content pair — a CONTENT-REVIEW-* literal exists that the pair does not define:$(printf '%s' "$cp_phantom" | tr '\n' ' ')
      A third terminal spelling means the bound has two answers. Either the set changed — in which case
      change it in both briefs, the guard message and the state table together — or this is drift."
else
  ok "content pair — no CONTENT-REVIEW-* literal outside the defined set of two, across both briefs, the guard rule and the state table"
fi

# ---------------------------------------------------------------------------------------------------
# THE `content` INTERVIEW'S OWNER-TAKE MARKER IS A CLOSED SET OF TWO.
#
# `commands/new-issue.md` step 2 interviews the owner before the two-lead dispatch and records the answer
# — or its absence — as one of exactly two HTML-comment markers in the Issue body. The absence form is a
# first-class outcome by design, because forcing a take means denying a capture at the worst moment, and a
# mechanism that costs the owner a sitting is one he routes around.
#
# WHY A GATE AT ALL, given the marker is written into an Issue this suite never sees. It is written into
# an Issue by a MODEL READING THIS FILE'S RULE, so what the gate can hold is the rule's own vocabulary: a
# third spelling in the tree means the rule has two answers, and whichever the model reads last wins. That
# is the same failure the CONTENT-REVIEW-* arm above exists for, and this arm is deliberately built on its
# shape rather than a new one.
#
# WHAT IT DOES NOT HOLD, and no layer does: a model that never asks can write the not-supplied form and
# pass. The gate reads the literal, never the conversation. `commands/new-issue.md` states that hole in
# its own text; a green here is not evidence that an interview happened.
#
# SCAN SET is $CITATION_FILES — every tracked `.md`/`.sh`/`.yml`/`.yaml`/`.json`/`.py`. Wider than the two
# files that legitimately carry the literal, on purpose: the drift this catches is a THIRD spelling
# invented somewhere else (an agent brief, a hook message, a skill), which a scan narrowed to the file
# that defines the set could never see.
OT_RULE_FILE="$ROOT/commands/new-issue.md"

# ── ARM A: both defined forms are PRESENT where the rule lives ─────────────────────────────────────
# Without this, ARM B passes vacuously on a file that lost the marker block entirely — the phantom set is
# empty when the whole rule is gone, which reads identical to a clean tree.
if [ ! -r "$OT_RULE_FILE" ]; then
  bad "owner-take marker — $OT_RULE_FILE is unreadable; both arms of this check did NOT run"
else
  ot_missing=""
  for ot_lit in supplied not-supplied; do
    grep -qF -- "owner-take: $ot_lit" "$OT_RULE_FILE" 2>/dev/null \
      || ot_missing="$ot_missing $ot_lit"
  done
  if [ -n "$ot_missing" ]; then
    bad "owner-take marker — a defined form is missing from commands/new-issue.md:$ot_missing
      The set is two, and the absence form is not the fallback — it is the outcome that keeps the
      interview from blocking a capture. A rule that names only the supplied form pushes a model to
      record nothing when the owner is mid-something else, which is the state this marker replaced."
  else
    ok "owner-take marker — both defined forms (supplied, not-supplied) are present in commands/new-issue.md"
  fi

  # ── ARM B: no THIRD spelling anywhere in the tracked tree ────────────────────────────────────────
  # The empty-set guard is not defensive noise: with no file arguments `grep` reads STDIN, so an empty
  # scan set would not fail — it would HANG, or pass on nothing. Say so instead.
  ot_phantom=""
  if [ -z "${CITATION_FILES//[[:space:]]/}" ]; then
    bad "owner-take marker — the citation scan set is EMPTY, so the closed-set arm did NOT run"
    ot_scan_ran=0
  else
    ot_scan_ran=1
    ot_phantom="$(grep -hoE 'owner-take:[[:space:]]*[a-z][a-z-]*' $CITATION_FILES 2>/dev/null \
      | sort -u | grep -vxE 'owner-take:[[:space:]]*(supplied|not-supplied)' || true)"
  fi
  if [ "$ot_scan_ran" = "0" ]; then
    :
  elif [ -n "${ot_phantom//[[:space:]]/}" ]; then
    bad "owner-take marker — a marker value exists that the rule does not define: $(printf '%s' "$ot_phantom" | tr '\n' ' ')
      A third value means the closed set is not closed, and a later reader cannot tell a recorded
      absence from an invented state. Either the set genuinely changed — change it in
      commands/new-issue.md and here together — or this is drift."
  else
    ok "owner-take marker — no marker value outside the defined set of two, across every tracked .md/.sh/.yml/.yaml/.json/.py"
  fi
fi

# ---------------------------------------------------------------------------------------------------
# EVERY SKILL CARRIES A `description` WRITTEN TO INDEX, NOT A TITLE (#166).
#
# WHY THIS IS AN INVENTORY CONCERN AT ALL. Commands were merged into skills, and model-invoked loading
# matches on the `description` field. A skill without one competes without the field that decides, so
# `description` is now part of what this repo PUBLISHES — the same class as a count on the README, and
# it rots the same way: nothing about adding a skill makes anyone write a trigger sentence for it.
#
# THE STANDARD IS agents-lead's, ON #166, AND THESE ARE ITS THREE LEVELS. What is asserted here is
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
# assertions below that are keyed on the stem stop meaning anything. `agents-lead` mutated the
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

ARG_HINT_ALLOWED="autonomy-on autonomy-off new-issue blueprint retrospective"   # the five the OWNER types; a model-invoked skill has no typed argument

# The frontmatter block, exclusive of its `---` fences. Empty for a file that has none, which is what
# the presence assertion below reads.
fm_block() {
  awk 'NR==1 && $0 != "---" { exit } NR==1 { infm=1; next } infm && $0 == "---" { exit } infm' "$1"
}

# ── THE VACUITY GUARD IS A FLOOR, NOT AN EMPTINESS TEST ─────────────────────────────────────────────
# IT USED TO FIRE ONLY ON ZERO, AND ZERO IS NOT HOW THIS SCAN LOSES ITS SUBJECT. Measured by
# `agents-lead` on #164 against a simulation of the flat `skills/` layout: `find $ROOT/commands`
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
    # record 0009 listed "every `(see X)` resolving to a file" as gated — now the trigger-description
    # section of ADR-0011. The record was accurate about the
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
    # `commands/<stem>.md`, which point at each other legitimately (the trigger-description section of
    # ADR-0011, absorbed from record 0009, documents them as the only
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
# WHY IT IS WORTH A BLOCK, in `agents-lead`'s words on #164: it is "the only place where a break is
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
#     establishing that the two are the same record. ~~One such citation exists today — the record on the
#     merge precondition cites that repo's third record, and this library also has a third record.~~
#     STRUCK #283 SLICE S2: NEITHER HALF IS TRUE ANY MORE, and the way it stopped being true is the
#     point. This library's third record was ABSORBED into the verification anchor and deleted, so (a)
#     there is no local record for a cross-repo citation of that number to collide with, and (b) the
#     citation in the merge-precondition record was rewritten to name the consuming repo's record by
#     TITLE rather than by number — because once the local record is gone, the prefixed form no longer
#     resolves locally and reddens the arm below, on a citation that is correct. The exemption list
#     could not take it: declaring the number foreign would have exempted a number this library has
#     ITSELF retired, so a leftover local citation of the dead record would then pass green. That is a
#     real hole in the number-based exemption and it has no cheap repair — the list keys on a number,
#     and a number can be foreign and retired-here at the same time.
#     The rest of the note stands and is why this paragraph is kept: what passed vacuously was the
#     CHECK, not the citation; the exposure is the NEXT such citation, written with no disambiguator in
#     the prose. Nothing here will ever catch that class. There are ZERO instances in the tree today
#     (the only one was rewritten by this slice), which means this hazard is now documented and
#     unexercised — read that as "no example to learn from", not as "closed".
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
# THE FOREIGN LIST IS THE ONE EXEMPTION, AND IT IS THE CROSS-REPO BLIND SPOT MADE VISIBLE. Several
# citations in this repo name records in the consumer product's library, which this suite cannot open.
# (The count that stood here was dropped rather than re-stamped when the list grew: it was a claim about
# a SET, verified against its members and never against its criterion, and nothing re-runs it.)
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
FOREIGN_ADR_NUMBERS="0023 0043 0046"

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

# ── 4c · NO RECORD LINKS TO ITSELF (#283 slice S3, blocking finding B1) ──
#
# THE CLASS THIS EXISTS FOR, WHICH IS NOT THE FIVE LINES THAT PRODUCED IT. A fold turns every
# cross-record citation of the absorbed record into an INTRA-record one, and the mechanical
# `ADR-<old>` → `ADR-<new>` substitution that performs the fold cannot know it. Everywhere outside the
# absorbing document the substitution is right; inside it, "cite the other record" had to become "cite
# the section below", and a substitution has no way to tell those apart. #283 has three more folds to
# run (S4, S5, S6) and S4 alone absorbs five records into 0002, which already cites every one of them.
#
# WHY 4a/4b ARE STRUCTURALLY BLIND TO IT. Both ask *does this identifier name a LIVE record*. After a
# fold it does — the target is the absorbing document, which is exactly the file the citation sits in.
# The sweep is not weak here, it is answering a different question. That is the boundary of what a
# resolution check can be, and it is why this arm asks a relational question instead: not "does the
# target exist" but "is the target the document making the citation".
#
# WHY THE LINK FORM AND NOT THE BARE PROSE TOKEN — MEASURED, and the measurement is the whole design.
# Two candidate spellings were run over the library at head:
#
#   narrow  awk '… index($0, "[ADR-" n "](./")'   →  0 hits at head, 5 hits at 6259e53 (exactly B1)
#   wide    awk '… index($0, "ADR-" n)'           →  13 hits at head, across 5 records, ALL legitimate
#
# The wide form matches a record naming its own number in prose — "every `ADR-0004` citation is
# unaffected" (0004:11), "same correction as ADR-0004's third amendment" (0004:414) — which is normal,
# correct writing. It would arrive RED on a clean tree, and this file's own floor is that a check that
# arrives red is a check that gets silenced. The narrow form is a LINK: a markdown reference whose
# destination is the file it is written in, which is never something a writer means. Zero false
# positives over the whole library, and it caught every one of B1's five.
#
# WHAT IT DOES NOT CATCH, PRICED RATHER THAN CLAIMED. B1's sharp half was that two of the five named a
# section title that is AMBIGUOUS inside the merged document — both records carried an "Amendment
# (2026-08-04, second)". That half is NOT gateable and this arm does not pretend to it. Duplicate
# headings inside one record are the normal state of a folded document, not a defect: measured at head,
# 10 duplicated headings across 0002 and 0004, and every one is structurally entailed (each absorbed
# section carries its own "What this fold dropped", "Consequences still being paid", "The rejected
# options that are still live"). An arm forbidding them would be red and WRONG. And the pointer itself
# is a heading quoted in prose — there is no machine-readable relation between the sentence and the
# section for a check to verify. What this arm buys against that residual is indirect and real: it
# forces every one of those pointers to be AUTHORED rather than substituted, and the ambiguity is
# visible to whoever writes the sentence.
selfcite_problems=""
selfcite_checked=0
for selfcite_file in "$CITATION_ADR_DIR"/[0-9][0-9][0-9][0-9]-*.md; do
  [ -r "$selfcite_file" ] || continue
  selfcite_base="${selfcite_file##*/}"
  selfcite_n="${selfcite_base%%-*}"
  selfcite_checked=$((selfcite_checked + 1))
  selfcite_hits="$(grep -n -F "[ADR-$selfcite_n](./" "$selfcite_file" | cut -d: -f1 | tr '\n' ' ' || true)"
  [ -z "${selfcite_hits//[[:space:]]/}" ] && continue
  selfcite_problems="$selfcite_problems
    docs/adr/$selfcite_base — links to ITSELF as '[ADR-$selfcite_n](./…)' at line(s): $selfcite_hits"
done

if [ "$selfcite_checked" -eq 0 ]; then
  bad "citation resolution — the self-citation scan found NO record files in docs/adr/, and there were
      16 when this was written. The enumeration broke and this check is vacuous."
elif [ -n "$selfcite_problems" ]; then
  bad "citation resolution — a record cites itself by number:$selfcite_problems
      This is what a fold's mechanical 'ADR-<old>' → 'ADR-<new>' substitution produces inside the
      ABSORBING document, and no resolution check above can see it: the target is live, it is simply
      the file doing the citing. Two of these are worse than circular — where both records carried a
      section with the same title, the sentence now names a real and DIFFERENT section of its own file
      and sends a reader several hundred lines from the text it promises. Replace each with an
      intra-document pointer that quotes the absorbed section's heading verbatim ('this document's
      *<heading>* section'), never a link back to this file and never a bare amendment date."
else
  ok "citation resolution — no record links to itself ($selfcite_checked records scanned for '[ADR-nnnn](./…)' naming their own number)"
fi

# ── 4d · NO INDEX ROW LINKS TO ITS OWN RECORD (#283 slice S5) ────────────────────────────────────
#
# WHAT THIS CHECKS, AND WHY ITS NAME IS NARROWER THAN THE CLASS IT COMES FROM. Arm 4c above asks the
# same relational question inside a RECORD's own file. This asks it inside the index: a row of
# `docs/adr/README.md`'s `## The records` table whose first cell is `[00N]` must not cite `ADR-00N`
# in the link form anywhere else in that row. Nothing more. The class it comes from — a fold's
# mechanical `ADR-<old>` → `ADR-<new>` substitution collapsing two distinct referents into one — is
# WIDER than this arm, and the arm is deliberately not named for it. Three of the four collapses S4
# produced were caught by reading, not by any instrument, and calling this "the collapse gate" would
# convert a green over one form into a green that reads as coverage of all of them.
#
# WHY THE INDEX NEEDS ITS OWN ARM AT ALL. 4c enumerates `docs/adr/[0-9][0-9][0-9][0-9]-*.md`, so the
# index is not in its scan set — the README is not a record. Yet the index is where a fold's
# substitution does the most damage per site: each row is one long line carrying that record's whole
# amendment history, so a link that used to name an absorbed sibling ("its layering half is superseded
# by [ADR-nnnn](./nnnn-…)", where nnnn was the sibling) becomes a link to the row's own record and the
# referent is simply gone — the exact site this arm found at 1018be1, in the 0004 row, left there by
# S3. The sentence still parses, the link still resolves, and 4a/4b stay green because the target is
# live. Written with the `nnnn` placeholder deliberately: the concrete number was the absorbed record's,
# so spelling it here would have reddened 4b the moment that record stopped existing — which is
# precisely what happened when this comment was first written, one run before this sentence replaced it.
#
# MEASURED BEFORE BUILDING IT, on this library at 1018be1, both candidate spellings:
#
#   narrow  the link form `[ADR-00N](./`      →  1 hit: row 0004  (a REAL defect, inherited from S3)
#   wide    the bare token `ADR-00N`          →  2 hits: rows 0004 and 0011
#
# The wide form's extra hit is row 0011's *"using ADR-0011's own documentation-versus-standard test"* —
# prose, a record's row naming its own number as the subject of a sentence, no referent lost and
# nothing to repair. Same result as 4c's own measurement one arm above, for the same reason: the bare
# token is a legitimate way to write about a record, the LINK form is a pointer whose destination is
# the thing doing the pointing, which is never what a writer means. Building the wide form would have
# meant shipping an arm that is red on correct prose, and this file's floor is that an arm arriving red
# is an arm that gets silenced. The narrow form arrives green **only because the S5 commit that adds it
# also repairs row 0004** — it did not arrive green on its own, which is the strongest thing that can
# be said for it and is why it is recorded here rather than in a commit message.
#
# WHAT IT DOES NOT CATCH, PRICED. (a) The bare-token collapse in a row, per the measurement above.
# (b) A collapse into a row that is NOT the target's own — the third form named in PR #299 §10b, which
# no standing arm can see, since the sentence reads fluently and the link resolves to a live record.
# (c) Section-grain aim: a row pointing at the right record and the wrong section leaves this arm and
# the whole suite green. All three travel to S6 unchanged.
rowcite_problems=""
rowcite_checked=0
rowcite_index="$CITATION_ADR_DIR/README.md"
if [ -r "$rowcite_index" ]; then
  while IFS= read -r rowcite_line; do
    [ -z "$rowcite_line" ] && continue
    rowcite_n="${rowcite_line#*| \[}"
    rowcite_n="${rowcite_n%%\]*}"
    case "$rowcite_n" in
      [0-9][0-9][0-9][0-9]) ;;
      *) continue ;;
    esac
    rowcite_checked=$((rowcite_checked + 1))
    case "$rowcite_line" in
      *"[ADR-$rowcite_n](./"*)
        rowcite_problems="$rowcite_problems
    docs/adr/README.md — the '$rowcite_n' row links to ITS OWN record as '[ADR-$rowcite_n](./…)'" ;;
    esac
  done <<< "$(grep -n '^| \[[0-9][0-9][0-9][0-9]\](\./' "$rowcite_index" || true)"
fi

if [ "$rowcite_checked" -eq 0 ]; then
  bad "citation resolution — the index self-citation scan found NO record rows in docs/adr/README.md,
      and there were 11 when this was written. Either the '## The records' table changed shape or the
      file moved; this check is vacuous until the enumeration is repaired."
elif [ -n "$rowcite_problems" ]; then
  bad "citation resolution — an index row cites its own record:$rowcite_problems
      A row summarises ONE record, so a link inside it naming that same record points a reader at the
      row they are already reading and the referent the sentence needed is lost. This is what a fold's
      'ADR-<old>' → 'ADR-<new>' substitution produces in the index, and every resolution arm above
      stays green on it because the target is a live record. Replace it with a bare 'record 00nn'
      naming the ABSORBED record — unqualified is resolvable here, and only here, because the row's
      first column already establishes which document is being described."
else
  ok "citation resolution — no index row links to its own record ($rowcite_checked rows scanned in docs/adr/README.md for '[ADR-nnnn](./…)' naming the row's own number)"
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
# THE TWO LAYERS, AND WHICH CONTROL EACH CAN HOLD (ADR-0004's question, answered for this rule):
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
ADR_HIGH_WATER=21

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
  # THE ROW IS READ BY COLUMN, NOT AS A STRING, AND THIS ARM WAS WEAK UNTIL 2026-08-20 (#283 slice S3).
  #
  # It used to ask whether the WHOLE ROW contained a `](./` anywhere. That passes on a row whose
  # destination column is EMPTY, because the row's own authority citation — the disposition record it
  # is written under — is itself a relative link two columns to the left. Measured at the time it was
  # written: with the destination stripped and the authority citation left alone, the suite stayed
  # green. It was left alone then on the honest ground that ONE History row is not a sample; #283
  # slice S3 supplies rows two, three and four, so it is closed here rather than carried.
  #
  # The row's shape is fixed by `skills/documentation-standard/SKILL.md` and by the table's own header:
  # `| <bare number> | what it decided | where the decision lives now |`. A markdown table row splits
  # on `|` into a leading empty field, the three columns, and a trailing empty field — five fields.
  # Selecting field 4 by NUMBER is position-based, which this repo distrusts; it is defensible here
  # and only here because the position is not a coordinate in a file that can be edited above it, it
  # is the table's declared arity, and the arity is asserted first. A row that is not five fields is
  # reported as malformed rather than silently read at the wrong offset.
  #
  # AND SELECTING THE COLUMN IS NOT ENOUGH — MEASURED, NOT REASONED, AND THE FIRST TRY WAS WRONG.
  # Column-selection alone was written first and then MUTATED: strip the destination link from the
  # third column and leave the row's own authority citation (the disposition record it was deleted
  # under) where it sits, IN THAT SAME COLUMN, and the suite stayed 68/0. The weakness the old
  # whole-row grep had was not caused by the link being in another column; it is caused by the column
  # containing TWO links with different jobs. Reading the column was a better-shaped check that
  # asserted the same nothing, which is the exact failure this file exists to catch, committed inside
  # the fix for it.
  #
  # WHAT CLOSES IT: the destination must be the column's FIRST content. The row form is
  # `<destination link> — <where inside it> . Absorbed under <authority> …`, so requiring the column
  # to BEGIN with a relative markdown link separates the two links by position without naming either
  # of them. It hardcodes no record number — a check spelled "the link that is not 0020" would rot
  # the day the disposition record moves, which is precisely the class of coupling #283 slice 1
  # deleted from this file.
  #
  # WHAT IT STILL CANNOT DO, STATED SMALLER THAN IT WAS (#283 slice S3, advisory A5). The residual was
  # published here, in the index and in the PR body as "nothing opens the destination", and that
  # UNDERSTATES the gate: point a row's destination at a file that does not exist and the separate
  # citation-resolution arm above reddens: `68 passed, 1 failed`, re-measured at #283 slice S4's final
  # commit. The figure published here until then was `67 passed, 1 failed`, taken at S3 BEFORE arm 4c
  # landed in the same commit — stale on arrival, which is why a tally beside a residual is taken LAST
  # or not at all. The destination's
  # EXISTENCE is gated. What is genuinely unchecked is its CONTENT — a row pointing at a document that
  # never received the decision passes exactly like one pointing at a document that did.
  #
  # AND ONE MORE, PRICED RATHER THAN CLOSED (advisory A1). The destination is separated from the row's
  # own authority citation BY POSITION, and position is authored: strip the destination and place the
  # `[ADR-0020](./0020-…)` authority link FIRST in the same column, and this check passes on a row with
  # no destination. Closing it needs the check to know WHICH link is the destination, and every cheap
  # discriminator available is a hardcoded record number — the coupling #283 slice 1 deleted from this
  # file, reintroduced to close a case reachable only by writing the column backwards against the house
  # form. Priced, not closed: the exposure is one row form nobody writes, and the `ok()` line below now
  # states what the arm checks rather than what it wishes it checked.
  # THE MULTIPLICITY GUARD IS FIRST, AND IT IS FIRST BECAUSE THIS ARM FAILED OPEN WITHOUT IT (#283
  # slice S3, blocking finding B2). `grep` returns EVERY matching row, so two rows for one number made
  # `adr_row_fields` the two-line string "5\n5"; `[ "5\n5" -ne 5 ]` is not a comparison, it is a shell
  # ERROR — `[` exits 2 with 'integer expression expected' on stderr, the `elif` chain evaluates as
  # not-taken, no problem is recorded, and the arm printed PASS. `68 passed, 0 failed`, exit 0, with the
  # only evidence on a stream nothing reads. An arm that falls through to PASS on a shell error fails
  # OPEN, and this file's whole subject is that a green proving nothing is worse than a red.
  #
  # WHY A COUNT GUARD AND NOT `set -e` / `set -o pipefail`. `set -e` would abort the run at the first
  # non-zero anywhere, and this suite is built to keep going and TALLY — it would convert one malformed
  # row into "the suite died", losing every verdict after it. The defect is not that errors are
  # tolerated; it is that a value with unbounded arity was fed to a scalar test. Bound the arity at the
  # source, next to the `grep` that produces it, where the reason is visible.
  #
  # WHY IT IS ALSO THE RIGHT ASSERTION ON ITS OWN TERMS, not merely a crash guard: a retired number has
  # exactly ONE disposition. Two rows can name two different destinations, and nothing downstream would
  # choose between them. Note the capability arm below already does exactly this (`cap_decls -gt 1`) —
  # the pattern was in this same file and this arm did not apply it.
  adr_row_count="$(printf '%s\n' "$adr_history_rows" | grep -cE "^\| *$adr_padded *\|" || true)"
  adr_row_fields="$(printf '%s' "$adr_row" | awk -F'|' '{print NF}')"
  adr_row_dest="$(printf '%s' "$adr_row" | awk -F'|' 'NF>=4 {print $4}')"
  if [ -z "$adr_row" ]; then
    adr_gap_problems="$adr_gap_problems
    $adr_padded — no record file, and no '| $adr_padded |' row under '## History' in docs/adr/README.md"
  elif [ "${adr_row_count:-0}" -ne 1 ]; then
    adr_gap_problems="$adr_gap_problems
    $adr_padded — has $adr_row_count History rows under '## History' in docs/adr/README.md, not 1. A
    retired number has exactly ONE disposition, so it gets exactly one row; two rows can name two
    different destinations and nothing here could choose between them. Delete the duplicate — do not
    reconcile them into a row that says both"
  elif [ "${adr_row_fields:-0}" -ne 5 ]; then
    adr_gap_problems="$adr_gap_problems
    $adr_padded — has a History row with $adr_row_fields '|'-separated fields, not the 5 a three-column
    row produces. The row is malformed, so its columns cannot be read at all"
  elif ! printf '%s' "$adr_row_dest" | grep -Eq '^[[:space:]]*\[[^]]+\]\(\./'; then
    adr_gap_problems="$adr_gap_problems
    $adr_padded — has a History row whose DESTINATION column (the third) does not BEGIN with a
    relative '[…](./…)' link. The destination is the column's first content, before the '— section …'
    and before the 'Absorbed under …' authority citation. A relative link later in the same column is
    not enough: measured, the authority citation alone satisfies a check that only asks whether the
    column contains one somewhere, which is how a stripped destination shipped green"
  elif [ -z "$(printf '%s' "$adr_row" | awk -F'|' '{print $3}' | tr -d '[:space:]')" ]; then
    adr_gap_problems="$adr_gap_problems
    $adr_padded — has a History row whose middle column is EMPTY. The row must say what was decided;
    a number and a destination with nothing between them answers 'where did it go' and not 'was this
    ever decided', which is the question the row exists for"
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
  ok "record numbering — $adr_live_count live records, ceiling $adr_ceiling_scanned, $adr_gaps_checked retired number(s), each carrying exactly one History row whose destination column begins with a relative link"
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
# docs/adr/README.md and read from there below. ~~An earlier revision of this comment said "seven" and
# the set is now six~~ — and the correction earned its own correction at #313, which is the better
# demonstration: the set grew again (`harness-blueprint`, ADR-0021), so the replacement number was
# stale within days of being written to argue against stale numbers. NO COUNT IS WRITTEN HERE NOW. A
# comment carrying a copy of a number the same file derives two hundred lines later is the
# second-source-of-truth failure this whole arm exists to gate against, committed in the gate. `Capability` is the field that says which document a record belongs to — so "this slice
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


# ══════════════════════════════════════════════════════════════════════════════════════════════════
# THE BLUEPRINT REGISTRY (#313) — BOTH DIRECTIONS, AND ONE HALF OF ONE COLUMN.
#
# WHAT THE REGISTRY IS. `docs/blueprint-registry.md` is an AUTHORED file describing this harness's
# obligations as BEHAVIOURS — a row may span two rules of one file, several files, or none at all, and
# one file may carry two rows. It is the artifact; `/blueprint` (unbuilt) is a projection over it.
# Generation never writes it. The reason is ADR-0021's, in one line: a generator that can ASSIGN an id
# can REASSIGN one, and the id is what a consuming project cites when it says "we implement 0003
# differently". So the tree does not produce the table — these arms check that the table and the tree
# still agree.
#
# WHAT THESE ARMS PROVABLY CANNOT HOLD, SAID BEFORE THE FIRST ASSERTION SO NO GREEN IS OVER-READ.
# `propósito`, `descrição` and the reasoning inside `o que faz` are UNFALSIFIABLE by any instrument in
# this repository. A row whose purpose went stale months ago passes every check below. The registry's
# own body says so above its first row, and ADR-0021 records it as an accepted cost — this comment is
# the third statement of it deliberately, because it is the one a person editing the gate reads.
#
# THE ONE GATEABLE HALF IS `citação` (arm 7): the carrier's OWN words about its OWN limit, asserted to
# appear verbatim in the carrier. A quote is greppable; a paraphrase is not. It does NOT assert that
# the quote is the RELEVANT limit, or that `o que não faz` is a fair reading of it.
#
# WHY THE COVERAGE DECLARATION IS GATED IN BOTH DIRECTIONS (arm 6). The registry declares, per element
# class, whether it claims completeness. A class declared `complete` with an unclaimed element reddens
# — that is the obvious direction. A class declared `partial` with NOTHING left unclaimed reddens too,
# and that is the direction worth having: an under-claiming declaration is exactly as misleading as an
# over-claiming one, and it is the one that would otherwise go stale in silence, since finishing the
# last row of a class is precisely when nobody thinks to edit a table three hundred lines above it.
#
# THE CHAINING RULE APPLIES HERE AS EVERYWHERE (see this file's header): each assertion gets its own
# `if`, and each repeats its own vacuity guard rather than borrowing the neighbour's.

BP_REG="$ROOT/docs/blueprint-registry.md"

# THE DECLARED CEILING, AND WHY IT IS A CONSTANT HERE RATHER THAN max(live) — the same argument the
# record-numbering block above makes, for the same failure: derive the ceiling from the rows that exist
# and an abandonment at the TOP of the sequence moves the derived max down by one, leaves no gap, and
# frees the number for reuse. Raising it is one line, in the same commit as the row that needs it, and
# forgetting to fails CLOSED at arm 3b.
BP_HIGH_WATER=44

# The closed set. It is the behaviour-level generalisation of the enforcement axis, and it THROWS —
# a free-text field would refuse nothing, which is the whole reason for a closed set (ADR-0021).
BP_TIPOS="refusal review record knowledge routing"

# The seven fields every row carries. `nome` is not among them: it lives in the row's heading beside
# the id, and the heading is what the parse keys on.
BP_KEYS='tipo
carrier
descrição
propósito
o que faz
o que não faz
citação'

# id<TAB>key<TAB>value, one line per field, ids taken from the `### NNNN · <nome>` headings. A field
# bullet outside any row block is dropped rather than attributed to the previous row.
bp_rows="$(awk '
  /^### [0-9][0-9][0-9][0-9] · / { id = substr($0, 5, 4); next }
  /^## /                         { id = ""; next }
  /^- \*\*[^*]+:\*\* /           {
      if (id == "") next
      line = $0
      sub(/^- \*\*/, "", line)
      k = line; sub(/:\*\*.*$/, "", k)
      v = line; sub(/^[^*]*:\*\* */, "", v)
      print id "\t" k "\t" v
  }
' "$BP_REG" 2>/dev/null || true)"

bp_ids="$(printf '%s\n' "$bp_rows" | awk -F'\t' 'NF==3 {print $1}' | sort -u | grep . || true)"
bp_row_count="$(printf '%s\n' "$bp_ids" | grep -c . || true)"

bp_field() { printf '%s\n' "$bp_rows" | awk -F'\t' -v i="$1" -v k="$2" '$1 == i && $2 == k {print $3}'; }

# ── 1 · every row carries exactly one of each of the seven fields ──
bp_field_problems=""
for bp_id in $bp_ids; do
  while IFS= read -r bp_key; do
    [ -z "$bp_key" ] && continue
    bp_n="$(bp_field "$bp_id" "$bp_key" | grep -c . || true)"
    [ "$bp_n" -eq 1 ] && continue
    bp_field_problems="$bp_field_problems
    $bp_id — field '$bp_key' appears $bp_n time(s), not 1"
  done <<< "$BP_KEYS"
done

if [ "$bp_row_count" -eq 0 ]; then
  bad "blueprint registry — NOT ONE row was parsed out of docs/blueprint-registry.md, and there were 33
      when this was written. Either the file left the repo — in which case delete this whole block in
      the same commit — or the '### NNNN · <nome>' heading form changed and every arm below is vacuous."
elif [ -n "$bp_field_problems" ]; then
  bad "blueprint registry — a row does not carry the seven fields exactly once:$bp_field_problems
      The labels are a parsing contract, not a heading style: tipo, carrier, descrição, propósito,
      'o que faz', 'o que não faz', citação — each written as '- **<label>:** <value>'."
else
  ok "blueprint registry — all $bp_row_count rows carry the seven fields exactly once"
fi

# ── 2 · every declared tipo is in the closed set ──
bp_tipo_problems=""
for bp_id in $bp_ids; do
  bp_tipo="$(bp_field "$bp_id" tipo | head -1)"
  case " $BP_TIPOS " in
    *" $bp_tipo "*) continue ;;
  esac
  bp_tipo_problems="$bp_tipo_problems
    $bp_id — tipo '$bp_tipo' is not one of: $BP_TIPOS"
done

if [ "$bp_row_count" -eq 0 ]; then
  bad "blueprint registry — the tipo set could not be tested: no row was parsed at all. Arm 1 says what
      broke; with nothing to classify, a naive form of this arm reports success over an empty scan."
elif [ -n "$bp_tipo_problems" ]; then
  bad "blueprint registry — a row declares a tipo outside the closed set:$bp_tipo_problems
      The set is closed and it THROWS. A behaviour that needs a sixth value is a visible widening of a
      published list — decided, in the same diff, and argued on more than one row that rubbed against
      it (ADR-0021 records the one strain known at authoring: two builder rows filed as routing)."
else
  ok "blueprint registry — all $bp_row_count rows declare a tipo in the closed set of 5"
fi

# ── 3a · every issued id is a live row or exactly one tombstone row ──
#
# Same shape, and deliberately the same shape, as the record-numbering block above: a number leaves the
# registry only as a disposition, never as an absence. The tombstone table may legitimately be EMPTY —
# nothing has been abandoned yet — which is why the scan looks for a row only when a number has no
# live row to account for it.
bp_tomb_rows=""
if [ -r "$BP_REG" ]; then
  bp_tomb_rows="$(awk '/^## History/{h=1;next} /^## /{h=0} h' "$BP_REG")"
fi

bp_max=0
for bp_id in $bp_ids; do
  bp_n=$((10#$bp_id))
  [ "$bp_n" -gt "$bp_max" ] && bp_max=$bp_n
done

bp_ceiling_scanned="$BP_HIGH_WATER"
[ "$bp_max" -gt "$bp_ceiling_scanned" ] && bp_ceiling_scanned="$bp_max"

bp_gap_problems=""
bp_n=1
while [ "$bp_n" -le "$bp_ceiling_scanned" ]; do
  bp_padded="$(printf '%04d' "$bp_n")"
  if printf '%s\n' "$bp_ids" | grep -qx "$bp_padded"; then
    bp_n=$((bp_n + 1))
    continue
  fi
  bp_rowcount="$(printf '%s\n' "$bp_tomb_rows" | grep -cE "^\| *$bp_padded *\|" || true)"
  bp_row="$(printf '%s\n' "$bp_tomb_rows" | grep -E "^\| *$bp_padded *\|" || true)"
  bp_fields="$(printf '%s' "$bp_row" | awk -F'|' '{print NF}')"
  if [ -z "$bp_row" ]; then
    bp_gap_problems="$bp_gap_problems
    $bp_padded — no live row, and no '| $bp_padded |' row under '## History' in the registry"
  elif [ "${bp_rowcount:-0}" -ne 1 ]; then
    bp_gap_problems="$bp_gap_problems
    $bp_padded — has $bp_rowcount tombstone rows, not 1. An abandoned id has exactly one disposition"
  elif [ "${bp_fields:-0}" -ne 5 ]; then
    bp_gap_problems="$bp_gap_problems
    $bp_padded — tombstone row has $bp_fields '|'-separated fields, not the 5 a three-column row
    produces; its columns cannot be read at all"
  elif [ -z "$(printf '%s' "$bp_row" | awk -F'|' '{print $3}' | tr -d '[:space:]')" ] \
    || [ -z "$(printf '%s' "$bp_row" | awk -F'|' '{print $4}' | tr -d '[:space:]')" ]; then
    bp_gap_problems="$bp_gap_problems
    $bp_padded — tombstone row has an empty column. A row must say what the id obliged AND why the
    obligation was abandoned; without the second, an abandonment is indistinguishable from a mistake"
  fi
  bp_n=$((bp_n + 1))
done

# The reverse direction: a tombstone for an id that is still live.
while IFS= read -r bp_trow; do
  [ -z "$bp_trow" ] && continue
  bp_tn="$(printf '%s' "$bp_trow" | sed -n 's/^| *\([0-9][0-9][0-9][0-9]\) *|.*/\1/p')"
  [ -z "$bp_tn" ] && continue
  printf '%s\n' "$bp_ids" | grep -qx "$bp_tn" || continue
  bp_gap_problems="$bp_gap_problems
    $bp_tn — has a tombstone row AND a live row; one of the two is wrong"
done <<< "$bp_tomb_rows"

if [ "$bp_row_count" -eq 0 ]; then
  bad "blueprint registry — id accounting is uncomputable: no row was parsed at all (arm 1)."
elif [ -n "$bp_gap_problems" ]; then
  bad "blueprint registry — an id the registry issued is accounted for by nothing:$bp_gap_problems
      An id leaves the registry ONLY as a tombstone, never as an absence. A rename changes nome; a
      consolidation changes carrier; NEITHER changes the id and neither produces a tombstone. Only an
      abandoned obligation does."
else
  ok "blueprint registry — $bp_row_count live rows, ceiling $bp_ceiling_scanned, every issued id accounted for"
fi

# ── 3b · the declared ceiling is current ──
if [ "$bp_row_count" -eq 0 ]; then
  bad "blueprint registry — the declared ceiling cannot be judged: no row was parsed at all (arm 1),
      so BP_HIGH_WATER has nothing to be compared against."
elif [ "$bp_max" -gt "$BP_HIGH_WATER" ]; then
  bad "blueprint registry — the highest live id is $bp_max but BP_HIGH_WATER is $BP_HIGH_WATER. A row
      was added without raising the ceiling. Raise it in this file, in the same commit as the row;
      until then an abandonment at the top of the sequence is invisible here."
else
  ok "blueprint registry — the declared ceiling $BP_HIGH_WATER is at or above the highest live id $bp_max"
fi

# ── 4 · every carrier resolves ──
#
# A carrier is one or more backticked repo-relative paths, or the literal `none` (a behaviour no file
# carries — the format's own answer to "absent is a value, never a missing row") or `retired`.
bp_carrier_problems=""
bp_carriers_checked=0
bp_claimed=""
for bp_id in $bp_ids; do
  bp_cval="$(bp_field "$bp_id" carrier | head -1)"
  case "$bp_cval" in
    none|retired) bp_carriers_checked=$((bp_carriers_checked + 1)); continue ;;
  esac
  bp_paths="$(printf '%s' "$bp_cval" | grep -oE '`[^`]+`' | tr -d '`' || true)"
  if [ -z "$bp_paths" ]; then
    bp_carrier_problems="$bp_carrier_problems
    $bp_id — carrier names no backticked path and is neither 'none' nor 'retired'"
    continue
  fi
  while IFS= read -r bp_path; do
    [ -z "$bp_path" ] && continue
    bp_carriers_checked=$((bp_carriers_checked + 1))
    bp_claimed="$bp_claimed
$bp_path"
    [ -e "$ROOT/$bp_path" ] && continue
    bp_carrier_problems="$bp_carrier_problems
    $bp_id — carrier '$bp_path' does not exist"
  done <<< "$bp_paths"
done

if [ "$bp_row_count" -eq 0 ]; then
  bad "blueprint registry — carrier resolution is vacuous: no row was parsed at all (arm 1)."
elif [ "$bp_carriers_checked" -eq 0 ]; then
  bad "blueprint registry — not ONE carrier value was extracted across $bp_row_count rows. The backtick
      form changed, or the field label did, and this assertion checked nothing."
elif [ -n "$bp_carrier_problems" ]; then
  bad "blueprint registry — a carrier does not resolve:$bp_carrier_problems
      A row describes something that exists, or it says 'none' (no file carries this behaviour) or
      'retired'. A carrier pointing at a deleted file is a row describing a harness nobody runs."
else
  ok "blueprint registry — all $bp_carriers_checked carrier value(s) resolve to a file, 'none' or 'retired'"
fi

# ── 5 · the reverse direction, per declared class ──
bp_cov="$(awk '/^## Coverage/{c=1;next} /^## /{c=0} c' "$BP_REG" 2>/dev/null \
  | sed -n 's/^| *`\([a-z][a-z-]*\)` *|[^|]*| *\([a-z]*\) *|.*/\1 \2/p' || true)"
bp_cov_count="$(printf '%s\n' "$bp_cov" | grep -c . || true)"

bp_elements_for() {
  case "$1" in
    persona) find "$ROOT/agents" -maxdepth 1 -name '*.md' -type f | sed "s|^$ROOT/||" ;;
    command) find "$ROOT/commands" -maxdepth 1 -name '*.md' -type f | sed "s|^$ROOT/||" ;;
    hook)    jq -r '.hooks | to_entries[] | .value[] | .hooks[] | .command' "$ROOT/hooks/hooks.json" 2>/dev/null \
               | sed 's|.*/hooks/scripts/|hooks/scripts/|; s|"$||' | sort -u ;;
    skill)   jq -r '.skills[]?' "$ROOT/.claude-plugin/plugin.json" 2>/dev/null \
               | sed 's|^\./||; s|$|/SKILL.md|' ;;
  esac
}

bp_cov_problems=""
bp_cov_elements=0
while IFS=' ' read -r bp_class bp_claim; do
  [ -z "$bp_class" ] && continue
  bp_unclaimed=""
  while IFS= read -r bp_el; do
    [ -z "$bp_el" ] && continue
    bp_cov_elements=$((bp_cov_elements + 1))
    printf '%s\n' "$bp_claimed" | grep -qxF "$bp_el" && continue
    bp_unclaimed="$bp_unclaimed $bp_el"
  done <<< "$(bp_elements_for "$bp_class")"
  case "$bp_claim" in
    complete)
      [ -z "$bp_unclaimed" ] && continue
      bp_cov_problems="$bp_cov_problems
    $bp_class — declared complete, but no row claims:$bp_unclaimed" ;;
    partial)
      [ -n "$bp_unclaimed" ] && continue
      bp_cov_problems="$bp_cov_problems
    $bp_class — declared partial, but every element is claimed. Declare it complete: an under-claiming
    declaration is exactly as misleading as an over-claiming one, and it is the one that goes stale in
    silence, because finishing a class's last row is when nobody thinks to edit the coverage table" ;;
    *)
      bp_cov_problems="$bp_cov_problems
    $bp_class — claim '$bp_claim' is neither 'complete' nor 'partial'" ;;
  esac
done <<< "$bp_cov"

if [ "$bp_cov_count" -eq 0 ]; then
  bad "blueprint registry — the coverage table under '## Coverage' is empty or unparsed, so the reverse
      direction never ran. Without it, a mechanism added to the tree and described nowhere is invisible."
elif [ "$bp_cov_elements" -eq 0 ]; then
  bad "blueprint registry — the coverage table parsed $bp_cov_count class(es) and NOT ONE element was
      enumerated from the tree. Every class would 'pass' for the same reason, which is a fact about the
      enumeration and not about the registry."
elif [ -n "$bp_cov_problems" ]; then
  bad "blueprint registry — the coverage declaration and the tree disagree:$bp_cov_problems"
else
  ok "blueprint registry — coverage holds in both directions across $bp_cov_count class(es), $bp_cov_elements element(s) enumerated"
fi

# ── 6 · every citação appears verbatim in one of the row's carriers ──
#
# THE ONLY ARM HERE THAT TOUCHES THE CONTENT COLUMNS AT ALL, and it touches one half of one of them.
# The value is either the literal 'no limit stated in the source' — a FINDING about the element, not a
# filled cell — or a quote, from which the span between the first and last double quote is taken and
# grepped, literally, in the carriers.
bp_quote_problems=""
bp_quotes_checked=0
bp_unquoted=0
for bp_id in $bp_ids; do
  bp_cit="$(bp_field "$bp_id" citação | head -1)"
  case "$bp_cit" in
    *"no limit stated in the source"*) bp_unquoted=$((bp_unquoted + 1)); continue ;;
  esac
  bp_q="$(printf '%s' "$bp_cit" | sed -n 's/^[^"]*"\(.*\)"[^"]*$/\1/p')"
  if [ -z "$bp_q" ]; then
    bp_quote_problems="$bp_quote_problems
    $bp_id — citação is neither a double-quoted span nor 'no limit stated in the source'"
    continue
  fi
  bp_quotes_checked=$((bp_quotes_checked + 1))
  bp_hit=0
  bp_cval="$(bp_field "$bp_id" carrier | head -1)"
  while IFS= read -r bp_path; do
    [ -z "$bp_path" ] && continue
    [ -r "$ROOT/$bp_path" ] || continue
    grep -qF -- "$bp_q" "$ROOT/$bp_path" && bp_hit=1
  done <<< "$(printf '%s' "$bp_cval" | grep -oE '`[^`]+`' | tr -d '`' || true)"
  [ "$bp_hit" -eq 1 ] && continue
  bp_quote_problems="$bp_quote_problems
    $bp_id — citação does not appear verbatim in any of its carriers: $bp_q"
done

if [ "$bp_row_count" -eq 0 ]; then
  bad "blueprint registry — citação verification is vacuous: no row was parsed at all (arm 1)."
elif [ "$bp_quotes_checked" -eq 0 ]; then
  bad "blueprint registry — NOT ONE citação was extracted as a quote across $bp_row_count rows. Either
      every row now reads 'no limit stated in the source' — which is a finding of its own — or the
      quoting form changed and the one gateable half of the content columns checks nothing."
elif [ -n "$bp_quote_problems" ]; then
  bad "blueprint registry — a citação does not appear in its carrier:$bp_quote_problems
      The cell quotes the carrier's OWN words about its own limit. A quote is greppable and a
      paraphrase is not, which is the entire reason this is the one content column with a gate."
else
  ok "blueprint registry — all $bp_quotes_checked citação(s) appear verbatim in a carrier; $bp_unquoted row(s) state no limit in their source"
fi

# ── 7 · a citação is not satisfied ONLY by a line the carrier has STRUCK ──────────────────────────
#
# FOUND BY BUILDING, NOT BY READING (#358). Arm 6 greps the quote with `grep -qF`, which is blind to
# `~~strike~~` markup — so rewriting a carrier's rule while KEEPING the old sentence inside a struck
# span leaves arm 6 green with the row quoting a rule the carrier no longer holds. Measured on the
# slice that rewrote `commands/blueprint.md`: the old `citação` (*"Not the registry, not a cached copy
# of the output, not a scratch artifact."*) survived verbatim inside a `~~…~~` span, and the suite
# printed 140/0 while row `0036` cited a struck rule.
#
# THAT IS THE WORST DIRECTION FOR THIS PARTICULAR GATE. `citação` is the ONE gateable half of the one
# content column that has a gate at all — the whole argument for it is that a quote is greppable — and
# a quote resolving into dead text turns the repo's single content assertion into a check that a
# sentence was once written. The strike convention is deliberate and stays; what changes is that a row
# must cite something the carrier still says.
#
# WHAT IT CANNOT HOLD: a sentence that is stale WITHOUT being struck. Strike markup is the only signal
# of retirement this repo has that a grep can see, so this closes the announced retirement and nothing
# else. A rule quietly reversed in the prose around a surviving sentence passes exactly as before.
bp_struck_problems=""
bp_struck_checked=0
for bp_id in $bp_ids; do
  bp_cit="$(bp_field "$bp_id" citação | head -1)"
  case "$bp_cit" in
    *"no limit stated in the source"*) continue ;;
  esac
  bp_q="$(printf '%s' "$bp_cit" | sed -n 's/^[^"]*"\(.*\)"[^"]*$/\1/p')"
  [ -z "$bp_q" ] && continue          # arm 6 owns the malformed-cell case; do not double-report it
  bp_live=0
  bp_seen=0
  bp_cval="$(bp_field "$bp_id" carrier | head -1)"
  while IFS= read -r bp_path; do
    [ -z "$bp_path" ] && continue
    [ -r "$ROOT/$bp_path" ] || continue
    while IFS= read -r bp_hitline; do
      [ -z "$bp_hitline" ] && continue
      bp_seen=1
      case "$bp_hitline" in
        *'~~'*) : ;;                  # this occurrence is inside a struck span
        *)      bp_live=1 ;;
      esac
    done <<< "$(grep -F -- "$bp_q" "$ROOT/$bp_path" || true)"
  done <<< "$(printf '%s' "$bp_cval" | grep -oE '`[^`]+`' | tr -d '`' || true)"
  [ "$bp_seen" -eq 0 ] && continue     # arm 6 owns the does-not-appear-at-all case
  bp_struck_checked=$((bp_struck_checked + 1))
  [ "$bp_live" -eq 1 ] && continue
  bp_struck_problems="$bp_struck_problems
    $bp_id — every occurrence of the citação in its carrier(s) sits on a STRUCK line: $bp_q"
done

if [ "$bp_row_count" -eq 0 ]; then
  bad "blueprint registry — the struck-citação check is vacuous: no row was parsed at all (arm 1)."
elif [ "$bp_struck_checked" -eq 0 ]; then
  bad "blueprint registry — NOT ONE citação was found in a carrier at all, so the struck-line check
      quantifies over nothing. Arm 6 says whether that is a resolution failure or a parse failure."
elif [ -n "$bp_struck_problems" ]; then
  bad "blueprint registry — a citação resolves only into STRUCK text:$bp_struck_problems
      A struck sentence is a rule the carrier announced it no longer holds. Re-author the row's
      citação against what the carrier says NOW — the id does not change, only the cell does."
else
  ok "blueprint registry — all $bp_struck_checked resolved citação(s) appear on at least one line the carrier has not struck"
fi

# ══════════════════════════════════════════════════════════════════════════════════════════════════
# `/blueprint`'S THREE MODES (#358) — THE DISPATCH SURFACE, BOTH DIRECTIONS.
#
# WHY THESE ARMS EXIST. `commands/blueprint.md` became a three-mode command on 2026-08-29: `export`,
# `import <document>`, and a bare invocation that prints help and does nothing. The mode set is
# published in TWO places that a human maintains independently — the `argument-hint` frontmatter, which
# is what a typist sees, and the dispatch table plus the `# Mode:` headings in the body, which is what
# the model reads. Nothing made them agree, and the failure is silent in the expensive direction: a
# mode named in the hint with no section behind it is a mode the typist is invited to use and the model
# has no instructions for.
#
# WHAT THEY PROVABLY CANNOT HOLD: whether any mode DOES what its row says. These are drift checks over
# strings — the same class as every other cross-surface arm in this file — and the command's own
# closing section states the residual in its own words. No green here says a blueprint was rendered
# faithfully, a mechanism was classified correctly, or a provenance line was redacted.

BP_CMD="$ROOT/commands/blueprint.md"

# The declared modes, from the DISPATCH TABLE ONLY — bounded to the section, because backticked first
# cells occur in five other tables in this file (the field mapping, the surfaces, the evidence classes,
# the enforcement axis) and an unbounded regex would sweep them all in.
bp_modes_table="$(awk '/^## The three modes/{t=1;next} /^## /{t=0} t' "$BP_CMD" 2>/dev/null \
  | sed -n 's/^| `\([a-z][a-z-]*\)` |.*/\1/p' | sort -u | grep . || true)"
# The declared modes, from the `argument-hint` — the first bare word of each `|`-separated segment.
bp_modes_hint="$(grep -m1 '^argument-hint:' "$BP_CMD" 2>/dev/null \
  | sed 's/^argument-hint: *//; s/"//g' | tr '|' '\n' \
  | sed -n 's/^ *\([a-z][a-z-]*\).*/\1/p' | sort -u | grep . || true)"
# The mode sections in the body.
bp_modes_head="$(grep -oE '^# Mode: `[a-z][a-z-]*`' "$BP_CMD" 2>/dev/null \
  | sed 's/^# Mode: `//; s/`$//' | sort -u | grep . || true)"

bp_mode_problems=""
if [ ! -r "$BP_CMD" ]; then
  bp_mode_problems="$bp_mode_problems
    commands/blueprint.md is not readable"
fi
for bp_m in $bp_modes_table; do
  printf '%s\n' "$bp_modes_hint" | grep -qx "$bp_m" \
    || bp_mode_problems="$bp_mode_problems
    '$bp_m' has a dispatch-table row and is NOT in the argument-hint the typist reads"
  printf '%s\n' "$bp_modes_head" | grep -qx "$bp_m" \
    || bp_mode_problems="$bp_mode_problems
    '$bp_m' has a dispatch-table row and NO '# Mode: \`$bp_m\`' section to dispatch to"
done
for bp_m in $bp_modes_hint; do
  printf '%s\n' "$bp_modes_table" | grep -qx "$bp_m" \
    || bp_mode_problems="$bp_mode_problems
    '$bp_m' is offered in the argument-hint and has no dispatch-table row"
done
# The third mode is the bare invocation. It has no word, so it is asserted by its two statements: the
# hint must tell the typist that no argument is legal, and the body must say what that does.
grep -m1 '^argument-hint:' "$BP_CMD" 2>/dev/null | grep -qF 'no argument' \
  || bp_mode_problems="$bp_mode_problems
    the argument-hint does not mention 'no argument'; the bare-invocation mode is invisible to a typist"
grep -qF 'prints help and does nothing else' "$BP_CMD" 2>/dev/null \
  || bp_mode_problems="$bp_mode_problems
    the body does not state that a bare invocation prints help and does nothing else"
# The hint must not still advertise an unbuilt half. It said '(takes no argument — the export is the
# whole command; the import half is not built)' until #358, and a stale hint of that shape is worse
# than a missing one: it tells the typist the mode they are about to use does not exist.
grep -m1 '^argument-hint:' "$BP_CMD" 2>/dev/null | grep -qF 'not built' \
  && bp_mode_problems="$bp_mode_problems
    the argument-hint still says a half is 'not built'"

bp_modes_n="$(printf '%s\n' "$bp_modes_table" | grep -c . || true)"
if [ "$bp_modes_n" -lt 2 ]; then
  bad "blueprint modes — the dispatch table parsed $bp_modes_n mode(s) and there are two named ones
      (export, import) plus the bare invocation. Either the table moved out from under
      '## The three modes' or its row shape changed, and every assertion here is now vacuous."
elif [ -n "$bp_mode_problems" ]; then
  bad "blueprint modes — the dispatch surface disagrees with itself:$bp_mode_problems
      The argument-hint is what a human reads while typing and the body is what the model dispatches
      on. A mode present in one and absent from the other is an invitation with nothing behind it."
else
  ok "blueprint modes — the $bp_modes_n named mode(s) agree across the argument-hint, the dispatch table and the '# Mode:' sections, and the bare invocation is declared in both"
fi

# ── the import triage — five classes, and the question distribution that makes silence deliberate ──
#
# THE DISTRIBUTION IS THE ASSERTION, not the row count. Three of the five classes ask the owner
# NOTHING, and that silence is the feature — it is what turns a foreign document into a handful of real
# decisions. It is also what makes a MISCLASSIFICATION into those three invisible. So the shape is
# gated: five classes, question counts drawn from a closed set of two values, and exactly three of them
# silent. Change a 0 to a 2 and the interview stops being bounded; change a 2 to a 0 and a real
# decision is taken without asking.
bp_triage="$(awk '/^## Triage before asking/{t=1;next} /^## /{t=0} t' "$BP_CMD" 2>/dev/null \
  | sed -n 's/^| *\([1-5]\) *| *[^|]* *| *\([0-9]\) *|.*/\1 \2/p' || true)"
bp_triage_n="$(printf '%s\n' "$bp_triage" | grep -c . || true)"
bp_triage_ids="$(printf '%s\n' "$bp_triage" | awk 'NF==2{print $1}' | sort -u | tr -d '\n')"
bp_triage_silent="$(printf '%s\n' "$bp_triage" | awk 'NF==2 && $2 == 0' | grep -c . || true)"
bp_triage_bad=""
while IFS= read -r bp_tline; do
  [ -z "$bp_tline" ] && continue
  bp_tq="$(printf '%s' "$bp_tline" | awk '{print $2}')"
  case "$bp_tq" in
    0|2) : ;;
    *) bp_triage_bad="$bp_triage_bad
    class $(printf '%s' "$bp_tline" | awk '{print $1}') declares $bp_tq questions; the closed set is {0, 2}" ;;
  esac
done <<< "$bp_triage"

if [ "$bp_triage_n" -eq 0 ]; then
  bad "blueprint triage — NOT ONE class row was parsed under '## Triage before asking'. Either the
      table moved or its shape changed; every assertion about the interview's bound is now vacuous."
elif [ "$bp_triage_n" -ne 5 ] || [ "$bp_triage_ids" != "12345" ]; then
  bad "blueprint triage — parsed $bp_triage_n row(s) with class ids '$bp_triage_ids'; the format
      declares exactly five classes numbered 1..5, and the classification order in the body walks all
      five. A missing class is a mechanism that falls through to whatever the model improvises."
elif [ -n "$bp_triage_bad" ]; then
  bad "blueprint triage — a class declares a question count outside the closed set:$bp_triage_bad
      Two questions or none. A third value is an interview with no stated bound."
elif [ "$bp_triage_silent" -ne 3 ]; then
  bad "blueprint triage — $bp_triage_silent of 5 classes are silent; the format declares THREE
      (already here, already rejected, incompatible). Fewer silent classes means the owner is asked
      about decisions already taken; more means a real decision is taken without asking him."
else
  ok "blueprint triage — five classes numbered 1..5, question counts in {0,2}, exactly three silent"
fi

# ── the two rules of this command that have no control behind them, asserted as WRITTEN ────────────
#
# BOTH ARE `documents`-CLASS AND BOTH SAY SO. These arms hold that the sentences exist; nothing can
# hold that anyone obeyed them, and the command states that in its own closing section. They are here
# because the failure they guard is IRREVERSIBLE and public — an adoption item naming a foreign
# harness's internals lands on a public tracker, and deleting the comment does not un-publish it.
#
# THE NEGATIVE ARM IS THE SHARPER OF THE TWO. The specification this command implements asks for the
# export to be written to `<workspace-root>/tmp/blueprint-<config_version>.yaml`, and that path was
# MEASURED denied by `orchestrator-write-guard.sh` in the ordinary single-repository install shape
# (`{agent_type:"", Write, <repo-root>/tmp/…}` -> deny). So the arm asserts the command names no such
# destination. It is scoped to `commands/blueprint.md` DELIBERATELY: ADR-0021 records the rejected path
# and must be free to name it, and a repo-wide grep would redden the record that explains the rule.
bp_rule_problems=""
grep -qF 'Never write inside a repository.' "$BP_CMD" 2>/dev/null \
  || bp_rule_problems="$bp_rule_problems
    the narrowed write rule ('Never write inside a repository.') is not stated"
grep -qF 'the session scratchpad' "$BP_CMD" 2>/dev/null \
  || bp_rule_problems="$bp_rule_problems
    the command names no session-scratchpad destination, so the output has nowhere legal to go"
grep -qF 'by FUNCTION and by nothing else' "$BP_CMD" 2>/dev/null \
  || bp_rule_problems="$bp_rule_problems
    the provenance redaction rule (source named 'by FUNCTION and by nothing else') is not stated"
grep -qF 'There is no gate here and none is claimed.' "$BP_CMD" 2>/dev/null \
  || bp_rule_problems="$bp_rule_problems
    the redaction rule does not state that nothing enforces it; a rule that implies a control it does
    not have is worse than no rule"
bp_bad_dest="$(grep -c -E 'workspace-root|tmp/blueprint' "$BP_CMD" 2>/dev/null || true)"
if [ "${bp_bad_dest:-0}" -ne 0 ]; then
  bp_rule_problems="$bp_rule_problems
    the command names a repository-relative output destination ($bp_bad_dest occurrence(s) of
    'workspace-root' or 'tmp/blueprint'). That path is DENIED to a typed command by
    orchestrator-write-guard.sh wherever the workspace root is the repository root, which is the
    ordinary installed shape"
fi

if [ ! -r "$BP_CMD" ]; then
  bad "blueprint rules — commands/blueprint.md is not readable, so none of its uncontrolled rules
      can be asserted present."
elif [ -n "$bp_rule_problems" ]; then
  bad "blueprint rules — a rule with no control behind it is missing from the only place it lives:$bp_rule_problems"
else
  ok "blueprint rules — the narrowed write rule, the scratchpad destination, the function-only provenance rule and its stated absence of a control are all present, and no repository-relative destination is named"
fi


# ══════════════════════════════════════════════════════════════════════════════════════════════════
# THE README CLAIM CONTRACT (#324) — FOUR CLASSES, AND ONE OF THEM IS EXECUTED.
#
# WHAT THIS IS FOR. Every arm ABOVE this one asserts a COUNT: a number published in README.md or
# CLAUDE.md against what the tree contains. Measured on #324, that is not where the drift was. All
# three drift examples that justified this block sat in the AUTHORED half of the README and none was a
# count — a relational claim ("read by nobody"), a number SPELLED OUT in prose ("the six personas
# above"), and a dated measurement of a foreign machine. The suite was 92/0 green through every one.
# The defect class is A CLAIM PUBLISHED WITH NO FALSIFIER BESIDE IT, and these arms gate the falsifier.
#
# THE SPLIT THAT MAKES IT EXECUTABLE SAFELY. `docs/readme-claims.md` holds the commands; README.md
# holds only `<!-- claim id=NNNN class=CLASS -->`. So an edit to the front door — the file most likely
# to be touched by someone not thinking about CI at all — CANNOT introduce a command this suite runs.
# That is the first containment and the one that matters most; the head allow-list and the character
# allow-list below are the second and third, and they are gated here rather than described in prose.
#
# WHAT THESE ARMS PROVABLY CANNOT HOLD, SAID BEFORE THE FIRST ASSERTION. They bind a COMMAND to a
# NUMBER. They never bind a number to a SENTENCE — nothing here reads the prose around a marker, so a
# section whose text contradicts its own entry passes green. That is the same residual the blueprint
# registry states about `propósito`, one surface further out, and `docs/readme-claims.md` states it in
# its own containment section. This comment is the third statement of it deliberately, because it is
# the one a person editing the gate reads.
#
# WHY `MEASURED` EXISTS AT ALL RATHER THAN EVERYTHING BEING `VERIFIED`. A command that reaches the
# network or a machine CI does not have would redden on an API outage or on a laptop nobody has, and a
# red that fires for reasons unrelated to the claim teaches everyone to ignore red. `MEASURED` is a
# SHAPE check — a date, and a fenced command adjacent — and its green means "dated and re-runnable by
# someone with the machine", never "true".
#
# THE CHAINING RULE APPLIES HERE AS EVERYWHERE (see this file's header): each assertion gets its own
# `if`, and each repeats its own vacuity guard rather than borrowing the neighbour's.

RC_REG="$ROOT/docs/readme-claims.md"

# The declared ceiling, same argument as ADR_HIGH_WATER and BP_HIGH_WATER above: derive it from the
# entries that exist and an abandonment at the TOP of the sequence leaves no gap and frees the number
# for reuse. Raising it is one line, in the same commit as the claim that needs it.
RC_HIGH_WATER=5

RC_CLASSES="VERIFIED MEASURED DERIVED JUDGEMENT"

# CONTAINMENT 2 — the closed allow-list of command heads.
#
# THE CRITERION, CORRECTED (#325 gate round). This comment used to read "a head is a meaningful unit
# of containment only for programs whose FLAGS are enumerable", and named `awk`/`sed` as the general-
# purpose languages that fails against. That criterion was too weak in a way nothing here could see,
# and the gate found it by EXECUTING this list rather than reading it:
#
#     uniq README.md hooks/scripts/kiro-power.test.sh | wc -l
#
# `uniq` writes its SECOND POSITIONAL OPERAND. There is no flag involved, so no denylist could hold
# it, and every character is inside containment 3's allow-list. Arm 7 reported all three containments
# passed and arm 8 overwrote another gate's test script — 31614 bytes before, 109064 after — reddening
# afterwards only on the `expects` comparison. A command chosen to return the right number would have
# written the file and left the suite green. `sort` was the same defect with a flag (`-o`).
#
# THE RULE IS THEREFORE: **flags AND POSITIONAL OPERANDS enumerable, and every one of them read-only.**
# Not "not a general-purpose language" — that is a strictly weaker test, and it is the one that passed
# `sort` and `uniq`. A head qualifies only if BOTH its option surface and its operand positions are a
# finite, documented, read-only set.
#
# APPLIED TO EVERY HEAD, and four were dropped rather than patched:
#   grep     PASS  — no option writes a file (`-f`, `--exclude-from` READ); operands are PATTERNS then
#                    FILEs, all read. Measured against GNU grep 3.12, which is what ubuntu-latest runs.
#   ls       PASS  — no write option; operands are paths, read.
#   wc       PASS  — no write option; operands are files, read.
#   head     PASS  — no write option; operands are files, read.
#   cat      PASS  — no write option; operands are files, read.
#   tr       PASS  — takes no file operand at all; operands are character SETs; stdin to stdout.
#   basename PASS  — string manipulation; touches no file.
#   sort     DROP  — `-o FILE` writes. A flag, and it was not in the denylist below.
#   uniq     DROP  — writes its second positional operand. NO FLAG EXISTS to denylist.
#   find     DROP  — `-fprint0 FILE` writes and was NOT in the denylist below (measured: a canary file
#                    was replaced by a NUL-terminated path list). Its operands are read-only, so it
#                    fails on flags alone — but the deeper reason it goes rather than gets patched is
#                    that find's action set is IMPLEMENTATION-DEPENDENT (BSD find has no `-fprint*` at
#                    all; GNU findutils and bfs do), and nothing pins which `find` is on PATH in CI. A
#                    head whose enumeration is only correct against an unpinned binary is not
#                    enumerable in the sense this criterion needs. It was the ONLY head whose safety
#                    rested on a denylist rather than on the allow-list, and it is the one that leaked.
#   jq       DROP  — cannot write a file (every output goes to stdout; `--rawfile`/`--slurpfile`/`-f`
#                    all READ), so it is not the same escape class. It fails on the OPERAND half: its
#                    first positional is an expression in jq's own language, which is exactly the
#                    property `awk` and `sed` were excluded for. Measured: `jq -n -r 'env.HOME'` reads
#                    the process environment and prints it, using NOT ONE character outside containment
#                    3's allow-list — and arm 8's failure message prints the command's stdout, so a
#                    claim authored this way puts a CI secret in the log on a deliberate mismatch.
#
# `awk` and `sed` remain absent for the reason they always were, now stated as a special case of the
# corrected rule rather than as the rule itself.
RC_HEADS="grep ls wc head cat tr basename"

# CONTAINMENT 3 — a character ALLOW-list, not a metacharacter denylist, so `$`, backtick, `;`, `&`,
# `<`, `>`, `(`, `)`, `{`, `}`, backslash and `!` are unreachable rather than forbidden one at a time.
#
# THE TOKEN DENYLIST HAS NO LIVE CONSUMER AND IS KEPT ANYWAY, which needs saying rather than leaving
# for someone to discover. Every token in it is a `find` action, and `find` just left RC_HEADS — so
# nothing in the allow-list above can reach any of them today. It is retained as defence-in-depth for
# exactly one scenario: a later slice re-adds `find`. The pin arm below forces that re-addition to be
# deliberate; this list is what stops it being SILENTLY uncontained in the same breath. `-fprint0` is
# added here because its absence is the second escape this round found, and leaving a known-incomplete
# list behind as "dead anyway" is how it gets resurrected incomplete.
#
# `-o` IS DELIBERATELY NOT IN THIS LIST, and that is a decision rather than an oversight. It would have
# caught `sort -o`, but `sort` is dropped, so it now guards nothing — while `grep -o` (only-matching) is
# a legitimate, read-only flag on a head that PASSES the criterion. Adding `-o` buys no containment and
# produces only false refusals. A denylist entry whose sole reachable effect is a false positive is
# worse than an absent one.
RC_BADTOKENS="-exec -execdir -ok -okdir -delete -fls -fprint -fprint0 -fprintf"

# section ordinal <TAB> id <TAB> class, one line per marker found in README.md.
rc_marks="$(awk '
  /^## / { sec++ }
  /^<!-- claim id=[0-9][0-9][0-9][0-9] class=[A-Z]+ -->[[:space:]]*$/ {
      line = $0
      sub(/^<!-- claim id=/, "", line)
      id = substr(line, 1, 4)
      sub(/^[0-9][0-9][0-9][0-9] class=/, "", line)
      sub(/ *-->.*$/, "", line)
      # sec+0, NEVER a bare sec: before the first heading it is UNSET, and awk prints that as an
      # empty field. TAB is an IFS whitespace character, so the bash read below strips the leading
      # empty field entirely and every column shifts by one. The arms still redden, but on the wrong
      # value: measured, a marker moved above the first heading reported "JUDGEMENT — section 0005
      # carries 0 markers", with the class where the id belongs. Failing closed with an unreadable
      # message is not the same as failing closed.
      # And assigned to a variable first. Written inline with a parenthesis, awk reads it as the start
      # of a print argument LIST and the parse fails, which under the trailing "|| true" here produces
      # an empty extraction. The vacuity guard in arm 1 is what caught that.
      # NOTE FOR ANY FUTURE COMMENT IN THIS BLOCK: it sits inside a single-quoted shell string, so an
      # apostrophe or a backtick here TERMINATES the awk program. That is how both of the above were
      # introduced while being written down.
      n = sec + 0
      print n "\t" id "\t" line
  }
' "$README" 2>/dev/null || true)"

rc_mark_ids="$(printf '%s\n' "$rc_marks" | awk -F'\t' 'NF==3 {print $2}' | sort -u | grep . || true)"
rc_mark_count="$(printf '%s\n' "$rc_mark_ids" | grep -c . || true)"
rc_sections="$(grep -c '^## ' "$README" || true)"

# id <TAB> key <TAB> value, one line per field, ids taken from the `## NNNN · <name>` headings.
rc_rows="$(awk '
  /^## [0-9][0-9][0-9][0-9] · / { id = substr($0, 4, 4); next }
  /^## /                        { id = ""; next }
  /^- \*\*[^*]+:\*\* /          {
      if (id == "") next
      line = $0
      sub(/^- \*\*/, "", line)
      k = line; sub(/:\*\*.*$/, "", k)
      v = line; sub(/^[^*]*:\*\* */, "", v)
      print id "\t" k "\t" v
  }
' "$RC_REG" 2>/dev/null || true)"

rc_entry_ids="$(printf '%s\n' "$rc_rows" | awk -F'\t' 'NF==3 {print $1}' | sort -u | grep . || true)"
rc_entry_count="$(printf '%s\n' "$rc_entry_ids" | grep -c . || true)"

rc_field()   { printf '%s\n' "$rc_rows" | awk -F'\t' -v i="$1" -v k="$2" '$1 == i && $2 == k {print $3}'; }
rc_unback()  { printf '%s' "$1" | grep -oE '`[^`]+`' | head -1 | tr -d '`'; }
rc_body()    { awk -v want="$1" '/^## /{sec++} sec==want' "$README" 2>/dev/null; }

# ── 1 · marker and entry account for each other, in both directions ──
rc_pair_problems=""
for rc_id in $rc_mark_ids; do
  printf '%s\n' "$rc_entry_ids" | grep -qx "$rc_id" && continue
  rc_pair_problems="$rc_pair_problems
    $rc_id — a README marker names it, and docs/readme-claims.md has no '## $rc_id · ' entry"
done
for rc_id in $rc_entry_ids; do
  printf '%s\n' "$rc_mark_ids" | grep -qx "$rc_id" && continue
  rc_pair_problems="$rc_pair_problems
    $rc_id — an entry exists, and no README section carries '<!-- claim id=$rc_id … -->'"
done

if [ ! -r "$RC_REG" ]; then
  bad "README claim contract — docs/readme-claims.md is not readable. Either the registry left the repo
      — in which case delete this whole block in the same commit, and every marker in README.md with it
      — or its path changed and all ten arms below are vacuous."
elif [ "$rc_mark_count" -eq 0 ] && [ "$rc_entry_count" -eq 0 ]; then
  bad "README claim contract — NOT ONE marker was parsed out of README.md and NOT ONE entry out of
      docs/readme-claims.md, and there were 5 of each when this was written. An empty-against-empty
      comparison passes for no reason, which is the direction this guard exists to close."
elif [ "$rc_mark_count" -eq 0 ]; then
  bad "README claim contract — $rc_entry_count entries exist and NOT ONE '<!-- claim id=NNNN class=… -->'
      marker was found in README.md. Either every marker was stripped, or the marker form changed and
      every arm keyed on it below is vacuous."
elif [ -n "$rc_pair_problems" ]; then
  bad "README claim contract — a marker and its entry do not account for each other:$rc_pair_problems
      The id is the whole binding: README.md carries the claim, docs/readme-claims.md carries what
      would falsify it, and neither is meaningful alone."
else
  ok "README claim contract — all $rc_mark_count markers and $rc_entry_count entries account for each other"
fi

# ── 2 · every marker sits inside a section, and no section carries two ──
rc_place_problems=""
while IFS=$'\t' read -r rc_sec rc_id rc_cls; do
  [ -z "${rc_id:-}" ] && continue
  if [ "${rc_sec:-0}" -eq 0 ]; then
    rc_place_problems="$rc_place_problems
    $rc_id — the marker sits above the first '## ' heading, so it labels no section"
    continue
  fi
  rc_n="$(printf '%s\n' "$rc_marks" | awk -F'\t' -v s="$rc_sec" '$1 == s' | grep -c . || true)"
  [ "$rc_n" -eq 1 ] && continue
  rc_place_problems="$rc_place_problems
    $rc_id — section $rc_sec carries $rc_n markers, not 1. A class is a property of one section"
done <<< "$rc_marks"

if [ "$rc_mark_count" -eq 0 ]; then
  bad "README claim contract — marker placement is uncomputable: no marker was parsed at all (arm 1)."
elif [ -n "$rc_place_problems" ]; then
  bad "README claim contract — a marker is misplaced:$rc_place_problems
      A marker goes on the line after the '## ' heading of the section it labels."
else
  ok "README claim contract — all $rc_mark_count markers sit in a distinct '## ' section"
fi

# ── 3 · the class is in the closed set, and the marker agrees with the entry ──
rc_class_problems=""
while IFS=$'\t' read -r rc_sec rc_id rc_cls; do
  [ -z "${rc_id:-}" ] && continue
  case " $RC_CLASSES " in
    *" $rc_cls "*) : ;;
    *) rc_class_problems="$rc_class_problems
    $rc_id — class '$rc_cls' is not one of: $RC_CLASSES"
       continue ;;
  esac
  rc_ecls="$(rc_field "$rc_id" class | head -1)"
  [ "$rc_ecls" = "$rc_cls" ] && continue
  rc_class_problems="$rc_class_problems
    $rc_id — README says '$rc_cls', docs/readme-claims.md says '$rc_ecls'"
done <<< "$rc_marks"

if [ "$rc_mark_count" -eq 0 ]; then
  bad "README claim contract — the class set could not be tested: no marker was parsed at all (arm 1)."
elif [ -n "$rc_class_problems" ]; then
  bad "README claim contract — a class is outside the set or disagrees with its entry:$rc_class_problems
      The set is closed and it THROWS. A claim that needs a fifth class is a visible widening of a
      published list, decided in the same diff, not a value invented in a marker nobody re-reads."
else
  ok "README claim contract — all $rc_mark_count markers declare a class in the closed set of 4, agreeing with their entry"
fi

# ── 4 · the fields an entry carries are the ones its class licenses ──
#
# The direction worth having is the NEGATIVE one: a JUDGEMENT entry shipping a command means somebody
# had a falsifier and filed the claim as unfalsifiable anyway, which is the one abuse of the class set
# that would otherwise be free.
rc_field_problems=""
for rc_id in $rc_entry_ids; do
  rc_ecls="$(rc_field "$rc_id" class | head -1)"
  rc_has_cmd="$(rc_field "$rc_id" command | grep -c . || true)"
  rc_has_exp="$(rc_field "$rc_id" expects | grep -c . || true)"
  rc_has_on="$(rc_field "$rc_id" on | grep -c . || true)"
  rc_has_arm="$(rc_field "$rc_id" arm | grep -c . || true)"
  rc_has_lim="$(rc_field "$rc_id" limit | grep -c . || true)"
  [ "$rc_has_lim" -eq 1 ] || rc_field_problems="$rc_field_problems
    $rc_id — carries $rc_has_lim 'limit' fields, not 1. Every class carries one: the limit is a
    property of the claim, and it is the cell that ports to a harness nobody here has measured"
  case "$rc_ecls" in
    VERIFIED)
      [ "$rc_has_cmd" -eq 1 ] && [ "$rc_has_exp" -eq 1 ] && [ "$rc_has_on" -eq 0 ] && [ "$rc_has_arm" -eq 0 ] && continue
      rc_field_problems="$rc_field_problems
    $rc_id — VERIFIED needs exactly one 'command' and one 'expects', and no 'on'/'arm'
    (command:$rc_has_cmd expects:$rc_has_exp on:$rc_has_on arm:$rc_has_arm)" ;;
    MEASURED)
      [ "$rc_has_cmd" -eq 1 ] && [ "$rc_has_on" -eq 1 ] && [ "$rc_has_exp" -eq 0 ] && [ "$rc_has_arm" -eq 0 ] && continue
      rc_field_problems="$rc_field_problems
    $rc_id — MEASURED needs exactly one 'command' and one 'on', and no 'expects'/'arm'. An 'expects'
    on a command nothing runs is a comparison that never happens, dressed as one that does
    (command:$rc_has_cmd expects:$rc_has_exp on:$rc_has_on arm:$rc_has_arm)" ;;
    DERIVED)
      [ "$rc_has_arm" -eq 1 ] && [ "$rc_has_cmd" -eq 0 ] && [ "$rc_has_exp" -eq 0 ] && [ "$rc_has_on" -eq 0 ] && continue
      rc_field_problems="$rc_field_problems
    $rc_id — DERIVED needs exactly one 'arm' and nothing else. An arm already owns the fact; a second
    command beside it is a second source of truth
    (command:$rc_has_cmd expects:$rc_has_exp on:$rc_has_on arm:$rc_has_arm)" ;;
    JUDGEMENT)
      [ "$rc_has_cmd" -eq 0 ] && [ "$rc_has_exp" -eq 0 ] && [ "$rc_has_on" -eq 0 ] && [ "$rc_has_arm" -eq 0 ] && continue
      rc_field_problems="$rc_field_problems
    $rc_id — JUDGEMENT declares that NO falsifier exists, and this entry ships one
    (command:$rc_has_cmd expects:$rc_has_exp on:$rc_has_on arm:$rc_has_arm). If there is a command,
    the class is VERIFIED or MEASURED" ;;
    *)
      rc_field_problems="$rc_field_problems
    $rc_id — entry declares class '$rc_ecls', which arm 3 should have caught; fields not judged" ;;
  esac
done

if [ "$rc_entry_count" -eq 0 ]; then
  bad "README claim contract — field licensing is uncomputable: no entry was parsed at all (arm 1)."
elif [ -n "$rc_field_problems" ]; then
  bad "README claim contract — an entry's fields do not match its class:$rc_field_problems"
else
  ok "README claim contract — all $rc_entry_count entries carry exactly the fields their class licenses"
fi

# ── 5 · every issued id is a live entry or exactly one tombstone ──
rc_tomb_rows=""
if [ -r "$RC_REG" ]; then
  rc_tomb_rows="$(awk '/^## History/{h=1;next} /^## /{h=0} h' "$RC_REG")"
fi

rc_max=0
for rc_id in $rc_entry_ids; do
  rc_n=$((10#$rc_id))
  [ "$rc_n" -gt "$rc_max" ] && rc_max=$rc_n
done

rc_ceiling="$RC_HIGH_WATER"
[ "$rc_max" -gt "$rc_ceiling" ] && rc_ceiling="$rc_max"

rc_gap_problems=""
rc_n=1
while [ "$rc_n" -le "$rc_ceiling" ]; do
  rc_padded="$(printf '%04d' "$rc_n")"
  if printf '%s\n' "$rc_entry_ids" | grep -qx "$rc_padded"; then
    rc_n=$((rc_n + 1))
    continue
  fi
  rc_rowcount="$(printf '%s\n' "$rc_tomb_rows" | grep -cE "^\| *$rc_padded *\|" || true)"
  if [ "${rc_rowcount:-0}" -ne 1 ]; then
    rc_gap_problems="$rc_gap_problems
    $rc_padded — no live entry, and $rc_rowcount '| $rc_padded |' row(s) under '## History', not 1"
  fi
  rc_n=$((rc_n + 1))
done

if [ "$rc_entry_count" -eq 0 ]; then
  bad "README claim contract — id accounting is uncomputable: no entry was parsed at all (arm 1)."
elif [ "$rc_max" -gt "$RC_HIGH_WATER" ]; then
  bad "README claim contract — the highest live id is $rc_max but RC_HIGH_WATER is $RC_HIGH_WATER. A
      claim was added without raising the ceiling. Raise it in this file, in the same commit as the
      entry; until then an abandonment at the top of the sequence is invisible here."
elif [ -n "$rc_gap_problems" ]; then
  bad "README claim contract — an id this registry issued is accounted for by nothing:$rc_gap_problems
      An id leaves the registry ONLY as a tombstone, never as an absence. Retitling a section changes
      nothing; deleting the section it labelled is what produces a tombstone."
else
  ok "README claim contract — $rc_entry_count live entries, ceiling $rc_ceiling, every issued id accounted for"
fi

# ── 6 · the coverage declaration, in BOTH directions ──
#
# `complete` with an unlabelled section reddens — the obvious direction. `partial` with NOTHING
# unlabelled reddens too, and that is the direction worth having: labelling the last section is
# precisely when nobody thinks to edit a table two hundred lines above it.
rc_cov="$(awk '/^## Coverage/{c=1;next} /^## /{c=0} c' "$RC_REG" 2>/dev/null \
  | sed -n 's/^| *`\([a-z][a-z-]*\)` *|[^|]*| *\([a-z]*\) *|.*/\1 \2/p' || true)"
rc_cov_count="$(printf '%s\n' "$rc_cov" | grep -c . || true)"

rc_unlabelled=0
rc_s=1
while [ "$rc_s" -le "${rc_sections:-0}" ]; do
  printf '%s\n' "$rc_marks" | awk -F'\t' -v s="$rc_s" '$1 == s' | grep -q . \
    || rc_unlabelled=$((rc_unlabelled + 1))
  rc_s=$((rc_s + 1))
done

rc_cov_problems=""
while IFS=' ' read -r rc_class rc_claim; do
  [ -z "$rc_class" ] && continue
  case "$rc_claim" in
    complete)
      [ "$rc_unlabelled" -eq 0 ] && continue
      rc_cov_problems="$rc_cov_problems
    $rc_class — declared complete, and $rc_unlabelled of $rc_sections '## ' sections carry no marker" ;;
    partial)
      [ "$rc_unlabelled" -gt 0 ] && continue
      rc_cov_problems="$rc_cov_problems
    $rc_class — declared partial, and every one of the $rc_sections sections carries a marker. Declare
    it complete: an under-claiming declaration is exactly as misleading as an over-claiming one" ;;
    *)
      rc_cov_problems="$rc_cov_problems
    $rc_class — claim '$rc_claim' is neither 'complete' nor 'partial'" ;;
  esac
done <<< "$rc_cov"

if [ "$rc_cov_count" -eq 0 ]; then
  bad "README claim contract — the table under '## Coverage' in docs/readme-claims.md is empty or
      unparsed, so the reverse direction never ran. Without it, a section added to README.md and
      classed nowhere is invisible."
elif [ "${rc_sections:-0}" -eq 0 ]; then
  bad "README claim contract — NOT ONE '## ' heading was counted in README.md, so every coverage class
      would 'pass' for the same reason. That is a fact about the enumeration, not about the registry."
elif [ -n "$rc_cov_problems" ]; then
  bad "README claim contract — the coverage declaration and README.md disagree:$rc_cov_problems"
else
  ok "README claim contract — coverage holds in both directions: $rc_mark_count of $rc_sections sections labelled, $rc_unlabelled unlabelled, declared partial"
fi

# ── 7 · CONTAINMENT — every VERIFIED command is refusable before it is runnable ──
#
# ONE FUNCTION, CALLED BY BOTH ARM 7 AND ARM 8, and that is not a tidiness choice. The first form of
# this block open-coded the three containments here and had arm 8 re-check only the CHARACTER class
# before executing — so a command with a REFUSED HEAD was reddened by arm 7 and then RUN by arm 8.
# Measured, before the fix, by swapping a claim's command for `sed -n 1p README.md | wc -l`: arm 7
# said "head 'sed' is not in the allow-list" and arm 8 reported the value that command returned, which
# it could only have got by running it. A containment that the executing arm re-derives independently
# is two containments, and the weaker one is the one that decides.
rc_contain_of() {   # prints the problems for one command; empty output means contained
  local c="$1" residue stages stage h tok
  residue="$(printf '%s' "$c" | LC_ALL=C tr -d "A-Za-z0-9 ._/*'\"|=:+,^#-")"
  if [ -n "$residue" ]; then
    printf '    character(s) outside the allow-list: [%s]\n' "$residue"
    return 0                       # a command this dirty is not worth tokenising further
  fi
  for tok in $RC_BADTOKENS; do
    case " $c " in
      *" $tok "*|*" $tok")
        printf "    the denied flag '%s'; the character allow-list cannot see a flag\n" "$tok" ;;
    esac
  done
  stages="$(printf '%s' "$c" | tr '|' '\n')"
  while IFS= read -r stage; do
    h="$(printf '%s' "$stage" | awk '{print $1}')"
    [ -z "$h" ] && continue
    case " $RC_HEADS " in
      *" $h "*) continue ;;
    esac
    printf "    pipeline stage head '%s' is not in the allow-list: %s\n" "$h" "$RC_HEADS"
  done <<< "$stages"
}

rc_contain_problems=""
rc_contained=0
for rc_id in $rc_entry_ids; do
  [ "$(rc_field "$rc_id" class | head -1)" = "VERIFIED" ] || continue
  rc_cmd="$(rc_unback "$(rc_field "$rc_id" command | head -1)")"
  if [ -z "$rc_cmd" ]; then
    rc_contain_problems="$rc_contain_problems
    $rc_id — the 'command' field carries no backticked command to contain"
    continue
  fi
  rc_contained=$((rc_contained + 1))
  rc_one="$(rc_contain_of "$rc_cmd")"
  [ -z "$rc_one" ] && continue
  rc_contain_problems="$rc_contain_problems
    $rc_id — refused:
$rc_one"
done

if [ "$rc_entry_count" -eq 0 ]; then
  bad "README claim contract — containment is uncomputable: no entry was parsed at all (arm 1)."
elif [ "$rc_contained" -eq 0 ]; then
  bad "README claim contract — NOT ONE VERIFIED command was extracted, and there were 2 when this was
      written. Either every claim stopped being VERIFIED — which arm 4 would not catch, since it only
      checks a class against its own fields — or the backtick form changed and arm 8 runs nothing."
elif [ -n "$rc_contain_problems" ]; then
  bad "README claim contract — a VERIFIED command is not containable:$rc_contain_problems
      Three containments, and this arm is the last two: a closed allow-list of pipeline-stage heads,
      and a character allow-list that puts substitution, redirection and chaining out of reach rather
      than forbidding them one at a time. The first containment is structural — the command lives in
      docs/readme-claims.md and never in README.md — and nothing in this arm can restore it."
else
  ok "README claim contract — all $rc_contained VERIFIED command(s) pass all three containments"
fi

# ── 7a · THE PIN ON RC_HEADS ITSELF — two-sided ──
#
# Arm 7 asserts that the live claims fit the allow-list. NOTHING asserted anything about the allow-list
# ITSELF, which is how `sort` and `uniq` sat in it from the first commit: adding a head was a one-word
# edit with no verdict attached, and the criterion it had to satisfy lived only in a comment. This pin
# makes the edit LOUD. It does not — and cannot — check that a head satisfies the criterion; no gate
# can read a program's manual. What it buys is that the criterion gets RE-APPLIED BY A HUMAN, because
# the suite goes red until the pin is updated in the same commit.
#
# Two-sided, and the second side is the one that would otherwise rot: a head ADDED to RC_HEADS and not
# to the pin reddens, AND a head REMOVED from RC_HEADS while the pin still names it reddens. A one-
# sided pin (only "everything in RC_HEADS is pinned") stays green forever after a deletion, which is
# the failure shape this file names about high-water marks.
RC_HEADS_PIN="basename cat grep head ls tr wc"

rc_pin_problems=""
for rc_h in $RC_HEADS; do
  case " $RC_HEADS_PIN " in
    *" $rc_h "*) continue ;;
  esac
  rc_pin_problems="$rc_pin_problems
    '$rc_h' is in RC_HEADS and NOT in RC_HEADS_PIN — a head was added without the criterion being
    re-applied. Read the criterion in the comment above RC_HEADS, apply it to '$rc_h' in writing, and
    add it to the pin in the SAME commit."
done
for rc_h in $RC_HEADS_PIN; do
  case " $RC_HEADS " in
    *" $rc_h "*) continue ;;
  esac
  rc_pin_problems="$rc_pin_problems
    '$rc_h' is in RC_HEADS_PIN and NOT in RC_HEADS — the pin has gone stale behind a removal."
done

if [ -z "$RC_HEADS" ] || [ -z "$RC_HEADS_PIN" ]; then
  bad "README claim contract — the RC_HEADS pin is uncomputable: RC_HEADS or RC_HEADS_PIN is empty, so
      both directions would pass over nothing."
elif [ -n "$rc_pin_problems" ]; then
  bad "README claim contract — the command-head allow-list and its pin disagree:$rc_pin_problems"
else
  ok "README claim contract — the command-head allow-list matches its pin in both directions ($RC_HEADS)"
fi

# ── 7b · THE CONTAINMENT REGRESSION — the refusals, and the acceptances that keep it honest ──
#
# THIS ARM EXISTS BECAUSE ARM 7 WAS GREEN ON AN ESCAPE. `rc_contain_of` was reasoned about and never
# fed a hostile input, so the containment asserted a property nobody had tested — which is precisely
# the defect class this whole block was built to gate, committed inside the gate itself.
#
# BOTH DIRECTIONS ARE MANDATORY. A refusal-only table is satisfied by a `rc_contain_of` that refuses
# EVERYTHING, which would be green here and would silently stop arm 8 executing any claim at all
# (arm 8 `continue`s past a refused command, and its own vacuity guard is the only thing that would
# notice). The ACCEPT rows are what make the refusals mean something.
rc_reg_problems=""
rc_reg_checked=0
while IFS=$'\t' read -r rc_want rc_probe; do
  [ -z "${rc_want:-}" ] && continue
  rc_reg_checked=$((rc_reg_checked + 1))
  rc_verdict="$(rc_contain_of "$rc_probe")"
  if [ "$rc_want" = "REFUSE" ] && [ -z "$rc_verdict" ]; then
    rc_reg_problems="$rc_reg_problems
    NOT REFUSED, and it must be: $rc_probe"
  elif [ "$rc_want" = "ACCEPT" ] && [ -n "$rc_verdict" ]; then
    rc_reg_problems="$rc_reg_problems
    REFUSED, and it must not be: $rc_probe
$rc_verdict"
  fi
done <<'RC_REGRESSION'
REFUSE	uniq README.md hooks/scripts/kiro-power.test.sh | wc -l
REFUSE	sort -o README.md docs/readme-claims.md
REFUSE	find agents -maxdepth 1 -name *.md -fprint0 README.md
REFUSE	jq -n -r env.HOME
REFUSE	sed -n 1p README.md | wc -l
REFUSE	awk END{print NR} README.md
REFUSE	grep -delete pattern README.md
REFUSE	cat README.md > /tmp/x
REFUSE	ls agents | wc -l && rm -rf agents
ACCEPT	ls agents/*.md | wc -l
ACCEPT	grep -lF gatekeeper-verdict hooks/scripts/session-wip.sh hooks/scripts/zombie-loop-detect.sh | wc -l
ACCEPT	grep -o pattern README.md | wc -l
ACCEPT	cat README.md | tr -s a-z | wc -c
RC_REGRESSION

if [ "$rc_reg_checked" -lt 13 ]; then
  bad "README claim contract — the containment regression is uncomputable: only $rc_reg_checked probe(s)
      were read and there are 13 rows. The heredoc is TAB-separated; an editor that converted those tabs
      to spaces empties every row's want/probe split and this arm passes over nothing."
elif [ -n "$rc_reg_problems" ]; then
  bad "README claim contract — the containment does not behave as published:$rc_reg_problems
      The REFUSE rows are the escapes this containment has actually leaked or was measured to be able
      to leak: \`uniq\` writing its second positional operand, \`sort -o\`, and \`find -fprint0\`. The
      ACCEPT rows are the honesty half — without them a containment that refuses everything is green.
      The \`grep -o\` row pins a DECISION: \`-o\` is deliberately absent from RC_BADTOKENS, because with
      \`sort\` dropped it guards nothing and would only refuse a legitimate read-only grep flag."
else
  ok "README claim contract — containment regression: all $rc_reg_checked probes behave as published ($((rc_reg_checked - 4)) refused, 4 accepted)"
fi

# ── 8 · EXECUTION — the VERIFIED commands run, and their output is what was declared ──
#
# This is the arm the whole block exists for. It runs a command that came out of a markdown file, which
# is why arm 7 sits above it and why arm 7 has its own vacuity guard rather than borrowing this one.
rc_exec_problems=""
rc_executed=0
for rc_id in $rc_entry_ids; do
  [ "$(rc_field "$rc_id" class | head -1)" = "VERIFIED" ] || continue
  rc_cmd="$(rc_unback "$(rc_field "$rc_id" command | head -1)")"
  rc_exp="$(rc_unback "$(rc_field "$rc_id" expects | head -1)")"
  [ -z "$rc_cmd" ] && continue
  if [ -z "$rc_exp" ]; then
    rc_exec_problems="$rc_exec_problems
    $rc_id — 'expects' carries no backticked value, so the output has nothing to be compared against"
    continue
  fi
  # THE SAME predicate arm 7 refused on, not a re-derivation of it — see the comment on
  # `rc_contain_of`. Arm 7 has already reddened; this is the gate that keeps it from being run anyway.
  [ -n "$(rc_contain_of "$rc_cmd")" ] && continue
  rc_executed=$((rc_executed + 1))
  rc_out="$( (cd "$ROOT" && bash -c "$rc_cmd") 2>/dev/null \
    | tr '\n' ' ' | tr -s '[:space:]' ' ' | sed 's/^ *//; s/ *$//' )"
  [ "$rc_out" = "$rc_exp" ] && continue
  rc_exec_problems="$rc_exec_problems
    $rc_id — expected '$rc_exp', the command returned '$rc_out'
    ($rc_cmd)"
done

if [ "$rc_entry_count" -eq 0 ]; then
  bad "README claim contract — execution is uncomputable: no entry was parsed at all (arm 1)."
elif [ "$rc_executed" -eq 0 ]; then
  bad "README claim contract — NOT ONE VERIFIED command was executed, and there were 2 when this was
      written. A green here would be a fact about the extraction, not about any claim in README.md."
elif [ -n "$rc_exec_problems" ]; then
  bad "README claim contract — a VERIFIED claim's command no longer returns what was declared:$rc_exec_problems
      Re-run the command, decide whether the WORLD changed or the CLAIM was wrong, and fix the one that
      is wrong — the prose in README.md as well as the 'expects' value, because nothing here reads the
      prose and a corrected number beside an uncorrected sentence passes this arm."
else
  ok "README claim contract — all $rc_executed VERIFIED command(s) returned exactly what was declared"
fi

# ── 9 · MEASURED — the shape, and only the shape ──
rc_meas_problems=""
rc_measured=0
while IFS=$'\t' read -r rc_sec rc_id rc_cls; do
  [ "${rc_cls:-}" = "MEASURED" ] || continue
  rc_measured=$((rc_measured + 1))
  rc_on="$(rc_field "$rc_id" on | head -1)"
  printf '%s' "$rc_on" | grep -qE '^20[0-9][0-9]-[01][0-9]-[0-3][0-9]$' \
    || rc_meas_problems="$rc_meas_problems
    $rc_id — 'on' is '$rc_on', not an ISO date. A measurement with no date is not re-runnable, it is
    just a number somebody once saw"
  rc_sbody="$(rc_body "$rc_sec")"
  printf '%s\n' "$rc_sbody" | grep -q '^```' \
    || rc_meas_problems="$rc_meas_problems
    $rc_id — the section carries no fenced block. MEASURED means the command is published beside the
    claim for someone with the machine to re-run; without the fence there is nothing to re-run"
  printf '%s\n' "$rc_sbody" | grep -qE '20[0-9][0-9]-[01][0-9]-[0-3][0-9]' \
    || rc_meas_problems="$rc_meas_problems
    $rc_id — the section carries no ISO date, so a reader cannot tell how old the figures are"
done <<< "$rc_marks"

if [ "$rc_mark_count" -eq 0 ]; then
  bad "README claim contract — the MEASURED shape check is uncomputable: no marker was parsed (arm 1)."
elif [ "$rc_measured" -eq 0 ]; then
  bad "README claim contract — NOT ONE MEASURED claim was found, and there was 1 when this was written.
      Either the class fell out of use — which is a finding, since the claims it covers did not — or
      the marker parse broke and this arm checked nothing."
elif [ -n "$rc_meas_problems" ]; then
  bad "README claim contract — a MEASURED section does not carry the shape its class requires:$rc_meas_problems
      This arm asserts a date and a fence, and NOTHING about whether the figures are true. Read a green
      as 'dated and re-runnable by someone with the machine', never as 'this claim holds'."
else
  ok "README claim contract — all $rc_measured MEASURED section(s) carry a date and a fenced command"
fi

# ── 10 · DERIVED — the named arm exists, as a TWO-SIDED assertion ──
#
# Requiring the label in both an `ok` and a `bad` branch is what makes `DERIVED` mean "an arm OWNS
# this". An arm that can only pass owns nothing, and a label that survives only in a comment owns less.
rc_der_problems=""
rc_derived=0
for rc_id in $rc_entry_ids; do
  [ "$(rc_field "$rc_id" class | head -1)" = "DERIVED" ] || continue
  rc_derived=$((rc_derived + 1))
  rc_arm="$(rc_unback "$(rc_field "$rc_id" arm | head -1)")"
  if [ -z "$rc_arm" ]; then
    rc_der_problems="$rc_der_problems
    $rc_id — the 'arm' field carries no backticked arm label"
    continue
  fi
  rc_oks="$(grep -cF "ok \"$rc_arm" "$0" || true)"
  rc_bads="$(grep -cF "bad \"$rc_arm" "$0" || true)"
  [ "${rc_oks:-0}" -ge 1 ] && [ "${rc_bads:-0}" -ge 1 ] && continue
  rc_der_problems="$rc_der_problems
    $rc_id — arm '$rc_arm' appears in $rc_oks ok() and $rc_bads bad() call(s) in this file; DERIVED
    requires at least one of each"
done

if [ "$rc_entry_count" -eq 0 ]; then
  bad "README claim contract — the DERIVED check is uncomputable: no entry was parsed at all (arm 1)."
elif [ "$rc_derived" -eq 0 ]; then
  bad "README claim contract — NOT ONE DERIVED claim was found, and there was 1 when this was written.
      With none, this arm reports success over an empty scan."
elif [ -n "$rc_der_problems" ]; then
  bad "README claim contract — a DERIVED claim names an arm that does not own it:$rc_der_problems
      What this arm CANNOT check: that the named arm is the one that actually owns the section's claim.
      A marker naming a real but unrelated arm passes here, and only a reviewer catches it."
else
  ok "README claim contract — all $rc_derived DERIVED claim(s) name a two-sided arm in this file"
fi


# ── The PR-link rule ships BOTH its limbs, or neither is the rule the owner wrote (#327/#328) ──
#
# WHY THIS IS AN ASSERTION AND NOT A PARAGRAPH. #327 stated the rule in two limbs. The first shipped
# with a hook and a 32-assertion suite; the SECOND — "or when the ask is explicitly a decision he
# holds … stated as that and not as a merge request" — reached no shipped surface at all, and every
# gate in this repo was green over the omission. It was caught by the merge gate reading the Issue
# against the diff, which is a human act nothing repeats. What shipped in its absence was a rule
# STRICTER than the owner's, in the direction that withholds a link he asked to keep.
#
# WHAT THIS ARM OWNS: that the operative wording still contains the second limb. Deleting the
# paragraph reddens here. That is the whole of it.
#
# WHAT IT EXPLICITLY DOES NOT OWN, and no arm can: that the hook DETECTS the case. It cannot — "is
# this ask a decision he holds" is not mechanically knowable, the hook implements limb one only, and
# an assertion pretending otherwise would be the theatre this suite exists to catch. This arm gates
# the PRESENCE OF A SENTENCE, and a sentence is what limb two is.
#
# COST, taken deliberately: the check is coupled to a phrase, so rewording it goes red and whoever
# rewords must edit this arm. That friction is the feature — the same argument the bare-`#NNN` arm in
# `premature-pr-link-detect.test.sh` already makes. Change it deliberately, do not drift out of it.
AUTON="$ROOT/commands/autonomy-on.md"
limb2_missing=""
for limb2_needle in \
  'the ask is explicitly a decision he holds' \
  'stated as that decision and not as a merge request' \
  'The detector cannot tell this case from a violation'
do
  grep -qF -- "$limb2_needle" "$AUTON" || limb2_missing="$limb2_missing
    missing: \"$limb2_needle\""
done
if [ -z "$limb2_missing" ]; then
  ok "PR-link rule — commands/autonomy-on.md carries the second limb AND names the detector's blindness to it"
else
  bad "PR-link rule — commands/autonomy-on.md no longer states the rule the owner wrote:$limb2_missing
      #327's rule has TWO limbs. Shipping only the first publishes a stricter rule than his, which
      withholds a PR link carrying a decision he holds. If this is a deliberate rewording, update the
      needles here in the same commit; if it is a deletion, it is the #328 defect recurring."
fi

# ---------------------------------------------------------------------------------------------------
# THE LANE RELATION HAS ONE CANONICAL HOME, AND THE FILE THAT EXECUTES IT BRANCHES BY TYPE (#329).
#
# WHY THIS EXISTS. `loop`-typed intake has been `agents-lead` ALONE by standing rule since 2026-08-13.
# For eleven days NINE live surfaces said otherwise or said nothing, and every gate in this repo was
# green over it — because the rule was stated only in prose no assertion had ever read. The gravest
# surface was `commands/new-issue.md`, the file the orchestrator EXECUTES: it dispatched the two-lead
# intake unconditionally, and the string `agents-lead` appeared in it ZERO times. The practice survived
# only because the orchestrator was overriding its own command file from memory, which is the failure
# this suite exists to catch one layer down: not a wrong number, a wrong INSTRUCTION.
#
# WHAT THESE ARMS OWN: that the canonical rows still exist and still say `agents-lead` alone, and that
# the executed command still branches by type instead of defaulting to one intake. Delete either and
# this reddens.
#
# WHAT NO ARM CAN OWN, and the amendment says so too: that a DISPATCH obeyed them. Nothing observes a
# dispatch. A `loop` Issue whose intake was run by both personas is indistinguishable, from the tracker
# and from the diff, from one run correctly. These arms gate the PRESENCE OF A SENTENCE — and a sentence
# is what the owner's ruling is.
#
# COST, taken deliberately: coupled to phrasing. Reword the rows or the branch and this goes red, and
# whoever rewords edits the needles in the same commit — the same trade the second-limb arm above takes.
LANE_SKILL="$ROOT/skills/harness-engineering/SKILL.md"
LANE_CMD="$ROOT/commands/new-issue.md"

# ── 1 · the canonical rows are in the states table, all three lanes, loop unconditional ──────────
lane_rows=$(grep -cF -- '| filed → **description closed** |' "$LANE_SKILL" 2>/dev/null || true)
lane_loop_needle='| `agents-lead`, **alone — `tech-lead` never co-signs this lane, with no exception**'
if [ "${lane_rows:-0}" -ne 3 ]; then
  bad "lane relation — skills/harness-engineering/SKILL.md carries $lane_rows 'filed → **description closed**'
      rows, expected 3 (product · content · loop). These rows are the CANONICAL wording of who takes part
      at intake (ADR-0002, nineteenth amendment); README.md and commands/new-issue.md both point HERE. A
      lane with no row is a lane whose dispatch has no stated rule, which is #329 recurring."
elif ! grep -qF -- "$lane_loop_needle" "$LANE_SKILL"; then
  bad "lane relation — the \`loop\` row no longer states \`agents-lead\` alone with the unconditional
      no-exception clause. Owner ruling 2026-08-25 (#329) was one word — \"nunca\". The clause is not
      decoration: a loose exception becomes the default case, because the reading that admits it is
      always available, and that is how the retired pairing walked back in on 2026-08-13."
else
  ok "lane relation — the states table carries all 3 'filed → **description closed**' rows, loop unconditional"
fi

# ── 2 · the file the orchestrator EXECUTES branches by type and names agents-lead ────────────────
# Own `if`, own vacuity guard: a broken read of either file must redden both arms, not borrow arm 1's.
lane_cmd_missing=""
for lane_cmd_needle in \
  '### 3 · Run the intake the TYPE routes to — branch before dispatching' \
  '| **`loop`** | **`agents-lead`, alone — never `tech-lead`, no exception** |' \
  '#### 3b · `loop` — `agents-lead` alone'
do
  grep -qF -- "$lane_cmd_needle" "$LANE_CMD" || lane_cmd_missing="$lane_cmd_missing
    missing: \"$lane_cmd_needle\""
done
if [ ! -r "$LANE_CMD" ]; then
  bad "lane relation — commands/new-issue.md is not readable; the branch cannot be checked at all"
elif [ -n "$lane_cmd_missing" ]; then
  bad "lane relation — commands/new-issue.md no longer branches the intake by issue type:$lane_cmd_missing
      This is the file the orchestrator EXECUTES. Before #329 it dispatched the two-lead intake with no
      branch anywhere in the step, and \`agents-lead\` appeared in it zero times. An unbranched step 3 is
      not a documentation defect — it is a wrong dispatch instruction the loop will follow."
else
  ok "lane relation — commands/new-issue.md branches step 3 by type and routes loop to agents-lead alone"
fi

# ── 3 · README.md POINTS at the table rather than restating the rule ─────────────────────────────
lane_ptr_needle='the `filed → **description closed**` rows of the states table in'
if ! grep -qF -- "$lane_ptr_needle" "$README"; then
  bad "lane relation — README.md no longer points at the canonical states-table rows. Owner ruling
      2026-08-25 (#329): the table is canonical and the README is a POINTER. Two surfaces stating the
      same operative rule independently is what produced eleven days of drift with nothing able to
      contradict either — if the pointer went away because the rule was restated here, that is the
      defect, not the fix."
else
  ok "lane relation — README.md points at the canonical states-table rows instead of restating them"
fi

# ── 4 · the lane relation is not re-GENERALISED — "the leads", unscoped, in an operative surface ──
#
# WHY A FOURTH ARM. Arms 1-3 key on the DEFECT's vocabulary: the pairing phrase, and the persona names.
# Round 1 of #329 shipped with three surfaces still publishing the retired rule, and NEITHER key reached
# any of them — because their defect is a GENERALISATION. "the leads" is not a pairing phrase and names
# no persona, so it is invisible to both. The three were `agents/product-lead.md` (a preload, citing as
# its authority the two surfaces the same MR had just reversed), `commands/autonomy-on.md` (the OTHER
# file the orchestrator executes, four lines under a queue predicate that includes `loop`), and the
# label table INSIDE the file the ruling designates canonical. Three instances in three files is a
# class, not a coincidence: the cheapest way to restate a lane rule is to drop the lane.
#
# WHAT THIS ARM OWNS: both directions, per surface. The lane-scoped wording is PRESENT, and the retired
# unscoped literal is ABSENT. The negative half is the one that survives a rewording — a future author
# who rewrites the sentence loses the positive needle (and edits it here, same commit), but one who
# re-generalises by pasting the old sentence back trips the negative needle whatever else changed.
#
# WHAT IT CANNOT OWN: an unscoped lane claim written in words nobody has used yet. This arm reads the
# literals this repo has actually shipped; a NEW generalisation is a new needle, found the way these
# three were — by a sweep whose key is not built from the defect's own vocabulary.
LANE_PLEAD="$ROOT/agents/product-lead.md"
lane_gen_missing=""
for lane_gen_file in "$LANE_SKILL" "$AUTON" "$LANE_PLEAD"; do
  [ -r "$lane_gen_file" ] || lane_gen_missing="$lane_gen_missing
    unreadable: \"${lane_gen_file#$ROOT/}\""
done
if [ -n "$lane_gen_missing" ]; then
  bad "lane relation — a surface carrying the lane-scoped \`ready\` wording cannot be read at all:$lane_gen_missing"
else
  # One needle per file, checked against THAT file only — a needle satisfied by the wrong surface is
  # exactly the drift this arm exists to catch.
  grep -qF -- '| `ready` | the description is closed on that lane, per the `filed → **description closed**` rows above | the leads (`product`) · `product-lead` (`content`) · **the owner** (`loop`) |' "$LANE_SKILL" \
    || lane_gen_missing="$lane_gen_missing
    missing: the label table's \`ready\` row in skills/harness-engineering/SKILL.md is no longer lane-scoped"
  grep -qF -- '**`ready` means the description is closed by whoever closes it on that lane — and on `loop` it is the' "$AUTON" \
    || lane_gen_missing="$lane_gen_missing
    missing: commands/autonomy-on.md's \`ready\` sentence is no longer lane-scoped"
  grep -qF -- 'through `agents-lead` **alone**' "$LANE_PLEAD" || lane_gen_missing="$lane_gen_missing
    missing: agents/product-lead.md no longer closes its \`loop\` sentence on \`agents-lead\` alone"
  # STRUCK OCCURRENCES ARE NOT HITS, and this is not a convenience — it is what makes the negative half
  # compatible with this repo's strike convention. Both surfaces below keep the retired sentence visible
  # inside `~~…~~` precisely because someone acted on it; a check that cannot tell `~~X~~` from X would
  # force the correction to DELETE its own history to go green, which is the opposite of the convention.
  # `grep -c` (never `-q`) after the strip: `-q` exits early, and under `pipefail` that SIGPIPEs `sed`
  # and reports the pipeline as failed — i.e. it would report "clean" on exactly the files that are not.
  for lane_gen_retired in \
    'the leads closed the description' \
    'through `agents-lead` and `tech-lead` without you'
  do
    for lane_gen_file in "$LANE_SKILL" "$AUTON" "$LANE_PLEAD"; do
      lane_gen_hits=$(sed 's/~~[^~]*~~//g' "$lane_gen_file" | grep -cF -- "$lane_gen_retired" || true)
      [ "${lane_gen_hits:-0}" -eq 0 ] || lane_gen_missing="$lane_gen_missing
    RETIRED literal is live (not struck) in ${lane_gen_file#$ROOT/}: \"$lane_gen_retired\""
    done
  done
  if [ -n "$lane_gen_missing" ]; then
    bad "lane relation — an operative surface states who closes the description WITHOUT naming the lane:$lane_gen_missing
      \"the leads\" is true of \`product\` and of no other lane. Unscoped, it is read by whoever dispatches
      as the rule for all three — which is #329's defect surviving its own fix. If this is a deliberate
      rewording, update the needles here in the same commit; if the retired literal is back, it is not."
  else
    ok "lane relation — the \`ready\` wording is lane-scoped in the canonical table, the executed command and the preload"
  fi
fi

# ── 5 · the preload's own DISPATCH ADVICE does not re-prescribe `tech-lead` on a loop change ─────
#
# WHY A FIFTH ARM, when arms 1-4 already read this same file. Because each of them keys on a SURFACE
# that states the lane relation, and this one does not state it — it PRESCRIBES A DISPATCH. Round 1 of
# #329 corrected nine surfaces and left `skills/harness-engineering/SKILL.md`'s *When to reach for this
# discipline specifically* bullet reading "pair it with `tech-lead` … and `quality-assurance`", seventy-
# five lines above the canonical row saying `tech-lead` never co-signs that lane. The same file stated
# both, in the preload every persona carries on every dispatch, for thirteen days. Arm 1 was green the
# whole time: the row it reads was correct.
#
# WHAT THIS ARM OWNS, both directions. POSITIVE: the strike is present and says why. NEGATIVE: the
# retired literal is not LIVE anywhere in the file — struck spans are stripped first, so the convention
# that keeps the sentence visible does not have to fight the assertion that killed it. The negative half
# is the one that survives a rewording, and it is the half that matters: a future author who pastes the
# pairing back trips it whatever else changed.
#
# THE STRUCK SPAN IS ON ONE LINE ON PURPOSE, and it is a real constraint on whoever rewords it. The
# stripper is `sed 's/~~[^~]*~~//g'`, which is LINE-oriented: a `~~` opened on one line and closed on
# the next is not stripped, so a re-wrapped strike would read to this arm as a live occurrence and
# redden on correct work. Keep the strike on its own single line.
#
# WHAT IT CANNOT OWN: a re-prescription written in words nobody has used yet — "loop the architect in",
# "get a second lead on it". This arm reads the literal this repo actually shipped. A new phrasing is a
# new needle, found the way this one was: by reading the file for what it INSTRUCTS, not for what it
# states.
lane_advice_problems=""
if [ ! -r "$LANE_SKILL" ]; then
  bad "lane relation — skills/harness-engineering/SKILL.md is not readable; the dispatch-advice arm
      cannot be checked at all."
else
  for lane_advice_needle in \
    '- **Validating a loop/gate change** — ~~pair it with `tech-lead`' \
    '`tech-lead` acts at **no** `loop` transition'
  do
    grep -qF -- "$lane_advice_needle" "$LANE_SKILL" || lane_advice_problems="$lane_advice_problems
    missing: \"$lane_advice_needle\""
  done
  # `grep -c`, never `-q`, after the strip — `-q` exits early, SIGPIPEs the `sed` under `pipefail`, and
  # reports the pipeline as failed, i.e. reports "clean" on exactly the files that are not.
  lane_advice_live=$(sed 's/~~[^~]*~~//g' "$LANE_SKILL" | grep -cF -- 'pair it with `tech-lead`' || true)
  [ "${lane_advice_live:-0}" -eq 0 ] || lane_advice_problems="$lane_advice_problems
    RETIRED literal is LIVE (not struck) in skills/harness-engineering/SKILL.md: \"pair it with \`tech-lead\`\""
  if [ -n "$lane_advice_problems" ]; then
    bad "lane relation — the preload prescribes a dispatch the canonical rows forbid:$lane_advice_problems
      This file is the universal preload. A bullet telling whoever dispatches to pair a loop/gate change
      with \`tech-lead\` is not a stale sentence — it is a wrong INSTRUCTION, and it outranks the table in
      practice because it is the part written as advice. Owner ruling 2026-08-25 (#329) was \"nunca\";
      \`tech-lead\` acts at no \`loop\` transition in the states table at all. If this is a deliberate
      rewording, update the needles here in the same commit."
  else
    ok "lane relation — the preload's dispatch advice no longer pairs a loop/gate change with tech-lead"
  fi
fi

# ---------------------------------------------------------------------------------------------------
# THE ITERATION IS THE UNIT OF WORK, AND ITS TWO NOT-OPTIONAL RULES ARE WRITTEN DOWN (#326).
#
# WHY THIS EXISTS. The owner decided on 2026-08-24 that the loop adopts iterations as the unit of work,
# and the falsifier that opened the Issue matched NOTHING in commands/, skills/ or docs/adr/ — the rites
# existed as knowledge and the axis did not exist at all. Two rules were imported as not-optional, and
# each is not-optional because the source project shipped the alternative and measured it failing:
#
#   RULE 1 — the active iteration is derived from the POOL, never from a date. Their first cut selected
#   "the iteration whose date range contains today", picked one with zero open items while real work sat
#   one iteration away, and REPORTED NOTHING-TO-DO AS THOUGH IT WERE DONE.
#   RULE 2 — the tracker object is chosen deliberately and WRITTEN DOWN. Rule 2 is discharged by a
#   surface existing; these arms are what makes "written down" mean something a diff can lose.
#
# WHAT THESE ARMS OWN: that the canonical section still exists and still carries both rules, the
# measurement behind the tracker object, and the state-model pass; and that the file the loop EXECUTES
# scopes its queue to the active iteration and stops on exhaustion rather than on the retired judgment
# condition. Delete or reword any of it and this reddens.
#
# WHAT NO ARM CAN OWN, and the amendment says so in the same words: that a SESSION obeyed any of it.
# Every `gh issue` call in hooks/scripts/ is a write path — nothing in this harness reads the queue, so
# a drain that ignored the milestone entirely is invisible to the tracker and to the diff. These arms
# gate the PRESENCE OF A RULE. That is the whole claim.
#
# TWO INDEPENDENT `if` BLOCKS, EACH WITH ITS OWN VACUITY GUARD, DELIBERATELY. An arm that lives in an
# `elif` under another arm emits NO verdict when the one above it goes red — an assertion that does not
# fail but DISAPPEARS, which no passing total can surface. That defect was found five times in this file
# by planting a mutation and watching for the line that never came; it is not repeated here.
ITER_SKILL="$ROOT/skills/harness-engineering/SKILL.md"
ITER_CMD="$ROOT/commands/autonomy-on.md"

# ── 1 · the canonical section carries both rules, the measurement, and the state-model pass ──────
iter_skill_missing=""
if [ ! -r "$ITER_SKILL" ]; then
  bad "iteration axis — skills/harness-engineering/SKILL.md is not readable; the canonical section
      cannot be checked at all. This is the file every persona preloads, which is why the rule lives
      here rather than in README.md prose no agent carries."
else
  for iter_needle in \
    '## The iteration is the unit of work' \
    '### Rule 1 — the active iteration is derived from the POOL, never from a date' \
    '### Rule 2 — the tracker object is a MILESTONE, and this section is it being written down' \
    'carries **four keys and' \
    '### `loop`-typed items ARE iteration-assignable' \
    '### The state-model pass — the AXIS adds no label and no state, and ESTIMATION adds exactly one class'
  do
    grep -qF -- "$iter_needle" "$ITER_SKILL" || iter_skill_missing="$iter_skill_missing
    missing: \"$iter_needle\""
  done
  if [ -n "$iter_skill_missing" ]; then
    bad "iteration axis — the canonical section no longer carries a load-bearing part of the rule:$iter_skill_missing
      Rule 1 and Rule 2 were imported as NOT OPTIONAL, each because the source project measured the
      alternative failing. The 'four keys' needle is the tracker object's own degradation — no command
      available to this loop can read a milestone's open/closed state — and it is what stops someone
      building a closing rule on an attribute that is not there. If this is a deliberate rewording,
      update the needles in this file in the same commit."
  else
    ok "iteration axis — the canonical section carries both not-optional rules, the tracker measurement and the state-model pass"
  fi
fi

# ── 2 · the file the loop EXECUTES scopes its pool and stops on exhaustion ───────────────────────
#
# BOTH DIRECTIONS, and the negative half is the one that survives a rewording. The retired terminal
# condition must be ABSENT IN ITS BULLET FORM — not absent from the file, which would be wrong twice
# over: the sentence is deliberately kept struck (`~~…~~`) under *Stop when* because someone acted on
# it, and it is quoted again inside the #103 rationale, which is history and must not be swept. Keying
# on the bullet is what tells a live rule from a preserved one, and it is why this arm does not reuse
# the strip-then-grep shape the lane arms use.
iter_cmd_missing=""
if [ ! -r "$ITER_CMD" ]; then
  bad "iteration axis — commands/autonomy-on.md is not readable; the executed pool and terminal
      condition cannot be checked at all."
else
  for iter_cmd_needle in \
    '**and carrying the ACTIVE ITERATION' \
    '> **Report the count of `ready` items carrying NO milestone, at session open.**' \
    'select(.milestone==null)' \
    '- **the ENTRY SNAPSHOT is exhausted** — mechanical, no judgment; or'
  do
    grep -qF -- "$iter_cmd_needle" "$ITER_CMD" || iter_cmd_missing="$iter_cmd_missing
    missing: \"$iter_cmd_needle\""
  done
  iter_retired='- **no open issue outranks the cost of continuing** — see below; or'
  iter_retired_hits=$(grep -cF -- "$iter_retired" "$ITER_CMD" || true)
  [ "${iter_retired_hits:-0}" -eq 0 ] || iter_cmd_missing="$iter_cmd_missing
    RETIRED terminal condition is live again as a *Stop when* bullet: \"$iter_retired\""
  if [ -n "$iter_cmd_missing" ]; then
    bad "iteration axis — commands/autonomy-on.md no longer executes the iteration-scoped drain:$iter_cmd_missing
      The queue predicate and the terminal condition are what the axis IS, operationally — the rest is
      description. And the no-milestone count is a precondition of this scoping rather than a nicety:
      \`ready\` was sufficient before #326 and is necessary-not-sufficient after it, so every \`ready\`
      item with no milestone silently stops being worked and nothing else anywhere would say so.
      The \`select(.milestone==null)\` needle is #365's repair of that count and is a needle in its own
      right rather than part of the sentence above: the published form read 'from the same query', and
      the same query's FIRST filter is \`select(.milestone!=null)\`, so a reader following it literally
      got an empty result and read it as nothing-to-worry-about. A falsifier that FAILS OPEN is worse
      than no falsifier, which is why the predicate is now inline and asserted rather than described.
      Leaving BOTH terminal conditions standing is the shape this file has already paid for twice
      (#97 → #103, and the exhaustion event itself)."
  else
    ok "iteration axis — commands/autonomy-on.md scopes the pool to the active iteration, counts the unassigned, and stops on exhaustion"
  fi
fi

# ---------------------------------------------------------------------------------------------------
# LOOP JOINS THE ACTIVE ITERATION AT FILING, AND THE TERMINAL SET IS THE DRAIN'S ENTRY SNAPSHOT (#338).
#
# WHY THIS EXISTS. The owner asked that `loop` work never be scheduled out — "tudo de loop deveria estar
# na iteracao corrente" — and then, asked whether to narrow the rule to filing time or accept that the
# pool grows, declined the narrowing: "a gente nao consegue impedir esse comportamento". Both halves are
# load-bearing and they PULL AGAINST EACH OTHER, which is the only reason this needs a gate at all:
#
#   THE FILING RULE puts new `loop` Issues into the pool a drain is currently working. commands/
#   new-issue.md set no milestone at all before this (`grep -c milestone commands/new-issue.md` -> 0), so
#   every `loop` Issue was born outside the pool /autonomy-on can see.
#   THE CONSEQUENCE is that "the active iteration's pool is exhausted" stops being reachable by working —
#   the exact shape #103 retired one layer up, arriving one layer down. The terminal set therefore moved
#   onto a SNAPSHOT taken at entry, and the two must ship together: the filing rule without the snapshot
#   is a drain with no terminal state, and the snapshot without the filing rule is machinery for a
#   problem nobody has.
#
# WHAT THESE ARMS OWN: that the filing rule is written in the file that FILES (commands/new-issue.md) and
# in the preload every persona carries (skills/harness-engineering/SKILL.md), and that the file that
# DRAINS carries the snapshot with the two properties that make it work — keyed on issue NUMBERS rather
# than a count, and re-taken fresh on a second invocation so it defers rather than drops.
#
# THE NEGATIVE ARM IS LINE-ANCHORED, DELIBERATELY, AND grep -F WOULD HAVE FAILED HERE. The #326 bullet is
# kept in the file struck (`~~- **the active iteration's pool is exhausted** …~~`) because a drain ran
# under it, so a fixed-string search for the bullet text matches the PRESERVED copy and would pass with
# the rule live again. Anchoring on `^- ` is what tells a live *Stop when* bullet from a struck one.
#
# WHAT NO ARM CAN OWN. That any session took a snapshot, or that any Issue was filed with the right
# milestone. Nothing in hooks/scripts/ reads the queue — every `gh issue` call there is a write path — so
# a drain that terminated against the live pool and one that terminated against its snapshot are
# indistinguishable from the tracker and from the diff. No detector is proposed either, and the reason is
# in the file: the only checkable signal (exhaustion reported while the iteration still holds open `ready`
# items) is TRUE of every correct snapshot termination that saw an arrival. These arms gate the PRESENCE
# OF A RULE. That is the whole claim.
#
# THREE INDEPENDENT `if` BLOCKS, EACH WITH ITS OWN VACUITY GUARD, for the reason stated 100 lines above:
# an arm in an `elif` under a red arm emits NO verdict, and no passing total can surface that.
SNAP_NEW="$ROOT/commands/new-issue.md"

# ── 1 · the file that FILES carries the filing rule ──────────────────────────────────────────────
snap_new_missing=""
if [ ! -r "$SNAP_NEW" ]; then
  bad "loop-at-filing — commands/new-issue.md is not readable; the filing rule cannot be checked at all.
      This is the file that performs the act, so the rule living anywhere else is a description."
else
  # RE-AUTHORED 2026-08-30 (#365). The three needles that stood here asserted the OPPOSITE rule — that
  # `loop` Issues are filed INTO the active iteration (#338) — and #365 struck it. They are replaced
  # rather than deleted: the act this arm guards did not go away, it INVERTED, and an arm deleted
  # because its subject reversed leaves the new rule ungated while every total stays plausible.
  #
  # Each needle was verified with `grep -c -F` against commands/new-issue.md before being written here,
  # and the count checked to be exactly 1 — a `grep -qF` arm's property is COUNT >= 1, so a needle
  # occurring twice survives a single-line deletion probe and the arm tests nothing while looking green.
  for snap_new_needle in \
    'No Issue is filed with a milestone — nothing enters a running iteration automatically (#365)' \
    'itens nao podem ser criados dentro do sprint automaticamente sem verificacao HITL' \
    '**So this command sets no milestone, for any type.**' \
    '`permission-guard.sh` rule 10 holds it.'
  do
    grep -qF -- "$snap_new_needle" "$SNAP_NEW" || snap_new_missing="$snap_new_missing
    missing: \"$snap_new_needle\""
  done
  # THE NEGATIVE HALF, AND IT IS THE ARM THAT ACTUALLY BITES. The struck #338 text is KEPT in the file
  # under \`~~\`, so a fixed-string search for it matches the preserved copy and would pass with the old
  # rule live again. Anchoring on a LIVE (unstruck) line start is what tells the two apart — the same
  # shape, and the same reason, as the \`^- \` anchor on the retired #326 bullet fifty lines below.
  snap_new_live=$(grep -cE '^\*\*Derive the milestone from the pool' "$SNAP_NEW" || true)
  [ "${snap_new_live:-0}" -eq 0 ] || snap_new_missing="$snap_new_missing
    The #338 derive-and-assign instruction is LIVE again as an unstruck line. Deriving the active
    iteration in order to READ a pool is untouched by #365; deriving one in order to ASSIGN a milestone
    at filing is the act the owner's HITL rule forbids."
  if [ -n "$snap_new_missing" ]; then
    bad "no-auto-admission — commands/new-issue.md no longer files without a milestone:$snap_new_missing
      This is the file that PERFORMS the filing, so the rule living anywhere else is a description.
      The QUOTE needle is the owner's own words and is what stops the rule being re-derived into
      something adjacent; the FOR-ANY-TYPE needle is not decoration, since #338 was scoped to \`loop\`
      and the whole correction is that the scope was never the problem; the GUARD needle is the pointer
      to permission-guard.sh rule 10, without which this reads as an instruction when it is enforced."
  else
    ok "no-auto-admission — commands/new-issue.md files with no milestone, quotes the owner's rule, and names the guard that holds it"
  fi
fi

# ── 2 · the file that DRAINS carries the snapshot, and the retired bullet is not live ────────────
snap_cmd_missing=""
if [ ! -r "$ITER_CMD" ]; then
  bad "entry snapshot — commands/autonomy-on.md is not readable; the terminal set cannot be checked."
else
  for snap_cmd_needle in \
    '### The pool grows while it drains, so the terminal set is a SNAPSHOT taken at entry (#338)' \
    '**What it is keyed on: the set of issue NUMBERS**' \
    'it takes a FRESH snapshot'
  do
    grep -qF -- "$snap_cmd_needle" "$ITER_CMD" || snap_cmd_missing="$snap_cmd_missing
    missing: \"$snap_cmd_needle\""
  done
  snap_live_hits=$(grep -cE "^- \*\*the active iteration's pool is exhausted\*\*" "$ITER_CMD" || true)
  [ "${snap_live_hits:-0}" -eq 0 ] || snap_cmd_missing="$snap_cmd_missing
    RETIRED #326 terminal condition is live again as a *Stop when* bullet, and it is not reachable by
    working now that loop Issues join the pool at filing."
  if [ -n "$snap_cmd_missing" ]; then
    bad "entry snapshot — commands/autonomy-on.md no longer terminates against a set fixed at entry:$snap_cmd_missing
      The NUMBERS needle is what stops the snapshot being a count: a count is satisfied by an arrival
      replacing a closed item, so the drain would work an item it never admitted while the arithmetic
      still matched. The FRESH needle is what makes the snapshot defer rather than drop — a second
      invocation re-takes it, which is also why it needs no durable home and is not blocked by the
      unreadable milestone description (#339)."
  else
    ok "entry snapshot — commands/autonomy-on.md terminates against the entry snapshot, keyed on numbers, re-taken per invocation"
  fi
fi

# ── 3 · the universal preload carries both halves ────────────────────────────────────────────────
snap_skill_missing=""
if [ ! -r "$ITER_SKILL" ]; then
  bad "entry snapshot — skills/harness-engineering/SKILL.md is not readable; the preload every persona
      carries cannot be checked for the filing rule or the retired bound."
else
  # THE FIRST NEEDLE IS REPLACED, THE SECOND IS UNTOUCHED, and the asymmetry is the finding #365 turned
  # up rather than an editorial choice. The two clauses were shipped together by #338 and read as one
  # decision; they are not. The FILING rule is struck. The ENTRY SNAPSHOT survives it — the pool still
  # grows while it drains, for reasons #338 never owned (the owner admits at planning, `blocked` clears,
  # `ready` lands mid-drain), so #338 was one contributor and never the premise. Striking both because
  # they arrived in one commit is exactly the mistake this pair of needles now exists to make loud.
  for snap_skill_needle in \
    '#### NOTHING is admitted into a running iteration automatically — an Issue is filed with NO milestone (#365)' \
    '**Why prevention was available here when it was not for #337, #339 or #363.**' \
    "**The iteration bounds nothing. The drain's ENTRY SNAPSHOT does.**"
  do
    grep -qF -- "$snap_skill_needle" "$ITER_SKILL" || snap_skill_missing="$snap_skill_missing
    missing: \"$snap_skill_needle\""
  done
  if [ -n "$snap_skill_missing" ]; then
    bad "no-auto-admission — the universal preload no longer carries the #365 decision:$snap_skill_missing
      The WALL needle is the reasoning, not colour: this is the first rule in the family to ship as
      PREVENTION rather than detection, and it is available only because a guard that may ASK does not
      have to distinguish 'he told me' from 'I did it myself'. Lose that sentence and the next machinery
      proposal re-derives detection from #337/#339/#363 without noticing the case is different.
      The THIRD needle is the correction #338 shipped and #365 does NOT reverse: the drain terminates
      against its entry snapshot, not against the iteration. Deleting it alongside the filing rule —
      because the two arrived in the same commit — would leave the drain with no stated terminal set at
      all, which is #103's defect restored one layer down."
  else
    ok "no-auto-admission — the universal preload carries the #365 rule, why prevention was available here, and the entry-snapshot bound that survives it"
  fi
fi

# ---------------------------------------------------------------------------------------------------
# LOOP BEFORE PRODUCT IS A PLANNING-TIME COMPOSITION RULE, AND ITS OWN "NOT A GATE" CLAUSE IS GATED (#339).
#
# WHY THIS EXISTS. The owner ruled on 2026-08-28 that every `loop` item is worked before any `product`
# item, in every iteration, and asked for enforcement. There is none available: ordering is not a
# property of a tree and not a property of a command string, and the only artifact that could record
# "this was picked next" — the queue state at the instant of the pick — is captured by nothing. So the
# rule ships as an INSTRUCTION, and these arms hold the two things that are actually holdable:
#
#   1. THE RULE IS WRITTEN, in the file every persona preloads rather than in README prose no agent
#      carries — including the ELIGIBILITY ESCAPE, without which the first person to hit a stalled
#      `loop` item improvises one, and including the "nothing gates this" clause itself.
#   2. THE COMMAND THE LOOP EXECUTES points at it and no longer carries the wrong citation live.
#
# WHY ARM 1 GATES THE "NOT A GATE" CLAUSE, which reads like a joke and is the load-bearing part. A rule
# recorded with no enforcement, whose disclaimer is later trimmed as verbose, becomes a rule that READS
# as enforced — this repo's own named failure shape (an inert control that looks installed). The
# disclaimer is the only thing standing between a future reader and that inference, so it is the needle.
#
# WHAT NO ARM CAN OWN, in the same words the #326 arms use: that a SESSION obeyed any of it. Nothing in
# hooks/scripts/ resolves a milestone — measured 2026-08-28, `grep -rn "milestone" hooks/scripts/*.sh`
# matches one line and that line is a COMMENT — so the ordered body is prose in a field no gate opens.
# These arms gate the PRESENCE OF A RULE. That is the whole claim.
#
# TWO INDEPENDENT `if` BLOCKS, EACH WITH ITS OWN VACUITY GUARD, for the reason stated 100 lines above:
# an arm nested under another emits NO verdict when the one above it goes red, and a disappearing
# assertion is invisible to any passing total.
LOOPFIRST_SKILL="$ROOT/skills/harness-engineering/SKILL.md"
LOOPFIRST_CMD="$ROOT/commands/autonomy-on.md"

# ── 1 · the canonical section carries the rule, the escape, the weak home and the not-a-gate clause ──
loopfirst_skill_missing=""
if [ ! -r "$LOOPFIRST_SKILL" ]; then
  bad "loop-first — skills/harness-engineering/SKILL.md is not readable; the canonical composition
      rule cannot be checked at all. This is the preload every persona carries, which is why the
      owner's standing rule lives here and not in narrative prose."
else
  for loopfirst_needle in \
    '### Loop before product — a planning-time COMPOSITION rule, and it is NOT a gate' \
    'The rule ranks `(loop AND ready AND active-iteration)` ahead of' \
    '#### Where the order actually lives — and it is a weak home' \
    '#### Nothing gates this, and the layer analysis is why' \
    'zero true positives against'
  do
    grep -qF -- "$loopfirst_needle" "$LOOPFIRST_SKILL" || loopfirst_skill_missing="$loopfirst_skill_missing
    missing: \"$loopfirst_needle\""
  done
  if [ -n "$loopfirst_skill_missing" ]; then
    bad "loop-first — the canonical composition rule lost a load-bearing part:$loopfirst_skill_missing
      The ELIGIBILITY needle is the deadlock escape: the rule ranks what is ALREADY ready, so an item
      awaiting the owner's \`ready\` (his transition alone on the \`loop\` lane) is not in the pool and
      cannot stall it. The WEAK HOME needle is the admission that the order lives in a milestone
      description no gate reads, standing in for an iteration Issue that was specified and never built.
      The NOT-A-GATE needle and the ZERO-TRUE-POSITIVES measurement are what stop this rule being read
      as enforced by a reader who finds it in a file full of mechanisms. If this is a deliberate
      rewording, update the needles in this file in the same commit."
  else
    ok "loop-first — the canonical section carries the rule, the eligibility escape, the weak-home admission and the not-a-gate clause"
  fi
fi

# ── 2 · the executed command points at the rule, and the wrong citation is struck rather than live ──
#
# BOTH DIRECTIONS. The negative half keys on the LIVE form of the bad citation, not on its absence from
# the file: the wrong locator is deliberately kept struck (`~~…~~`) because someone acted on it, and a
# check that merely greps for the string would force deleting the correction that explains it. Same
# distinction the #326 arm above draws between a live bullet and a preserved one.
loopfirst_cmd_missing=""
if [ ! -r "$LOOPFIRST_CMD" ]; then
  bad "loop-first — commands/autonomy-on.md is not readable; the pointer from the file the loop
      EXECUTES to the composition rule cannot be checked."
else
  for loopfirst_cmd_needle in \
    '*Loop before product — a planning-time COMPOSITION rule*' \
    '`product-lead` orders **within** what the owner composed; it does not'
  do
    grep -qF -- "$loopfirst_cmd_needle" "$LOOPFIRST_CMD" || loopfirst_cmd_missing="$loopfirst_cmd_missing
    missing: \"$loopfirst_cmd_needle\""
  done
  loopfirst_retired='owns sequencing (ADR-0002 amendment #5): starting'
  loopfirst_retired_hits=$(grep -cF -- "$loopfirst_retired" "$LOOPFIRST_CMD" || true)
  [ "${loopfirst_retired_hits:-0}" -eq 0 ] || loopfirst_cmd_missing="$loopfirst_cmd_missing
    RETIRED citation is live again, unstruck: \"$loopfirst_retired\""
  if [ -n "$loopfirst_cmd_missing" ]; then
    bad "loop-first — commands/autonomy-on.md no longer routes ordering correctly:$loopfirst_cmd_missing
      The pointer is what stops the drain treating the \`loop\` block as \`product-lead\`'s to reorder;
      the ownership sentence is what says the two authorities do not overlap. And ADR-0002 amendment #5
      decided \"\`product-manager\` gets a trigger, and the reviewer's output gets a budget\" — not
      sequencing ownership — so that citation must not come back live."
  else
    ok "loop-first — commands/autonomy-on.md points at the composition rule and the wrong citation stays struck"
  fi
fi

# ---------------------------------------------------------------------------------------------------
# THE `loop` BLOCK MAY BE CARRIED AS ONE BRANCH AND ONE MR — A PERMISSION, AND THE REFUSALS BESIDE IT (#357).
#
# WHY THIS EXISTS. The owner proposed a "Loop Batch": the iteration's `loop` items delivered as one
# integrated reconfiguration, with "faça enforcement se necessário". The composition half was adopted as
# a PERMISSION; the headline clause ("one Loop Batch per iteration"), the authored traceability matrix,
# the consumer-reinstall step and the enforcement were all refused, each on a measurement. ADR-0002's
# twenty-fourth amendment is the record.
#
# WHAT THESE ARMS HOLD, AND IT IS ONLY EVER PRESENCE:
#
#   1. THE PERMISSION IS WRITTEN AS A PERMISSION, in the file every persona preloads — including the
#      "more than one batch per iteration is normal" clause, the deferral of the coverage check, the
#      marker residual, and the "nothing gates this either" disclaimer.
#   2. THE TWO COMMANDS A HUMAN TYPES point at it, so neither `/autonomy-on` nor `/new-issue` reads as
#      promising a per-Issue MR.
#
# WHY THE "IT IS A MAY" NEEDLE IS THE LOAD-BEARING ONE. A permission trimmed into a rule is the exact
# failure this section refuses: "one Loop Batch per iteration" is FALSE BY CONSTRUCTION the moment the
# iteration's `loop` block spans both repositories, because a branch does not cross repositories. If a
# later edit turns the MAY into a MUST, this repo ships a rule it has already measured cannot hold.
#
# WHY THE DURABLE-FORM NEEDLE IS SEPARATE (arm 3). #339's layer analysis was argued from a dated fact —
# every `loop` item in one repo, every `product` item in the other — which reads as a SEPARATION between
# the two repositories. The owner's 2026-08-29 correction is that there is ONE development effort and two
# places where files live. The durable statement is that a hook receives one `cwd`, so no single-repo hook
# can observe the iteration REGARDLESS of contents. The dated measurement is kept as evidence; this arm
# holds the reason, which is what stops the conclusion expiring when the contents move.
#
# WHAT NO ARM CAN OWN. That any iteration was actually composed as a batch, or was not. Nothing captures
# the composition — the same limit, in the same words, as the loop-first arms 200 lines above. A green
# here means the permission and its refusals are written down. That is the whole claim.
#
# THREE INDEPENDENT `if` BLOCKS, EACH WITH ITS OWN VACUITY GUARD, for the reason stated repeatedly above:
# an arm nested under another emits NO verdict when the one above it goes red.
LOOPBATCH_SKILL="$ROOT/skills/harness-engineering/SKILL.md"
LOOPBATCH_AUTONOMY="$ROOT/commands/autonomy-on.md"
LOOPBATCH_NEWISSUE="$ROOT/commands/new-issue.md"

# ── 1 · the permission, its refusals, its deferral and its residual are in the universal preload ──
loopbatch_skill_missing=""
if [ ! -r "$LOOPBATCH_SKILL" ]; then
  bad "loop-batch — skills/harness-engineering/SKILL.md is not readable; the composition permission
      cannot be checked at all. This is the preload every persona carries, which is why the rule lives
      here rather than in narrative prose."
else
  for loopbatch_needle in \
    '### The `loop` block MAY be carried as one branch and one MR — a PERMISSION, not a rule (#357)' \
    '**It is a MAY. Nothing composes a batch automatically, nothing forbids the per-item shape, and no gate' \
    '#### More than one batch per iteration is NORMAL, and the model must say so' \
    '#### Deliberately DEFERRED, not dropped: the derived commit ↔ issue coverage check' \
    'is a PRESENCE check, not a HEAD check' \
    '#### Nothing gates this either, and the arm says only that it is written'
  do
    grep -qF -- "$loopbatch_needle" "$LOOPBATCH_SKILL" || loopbatch_skill_missing="$loopbatch_skill_missing
    missing: \"$loopbatch_needle\""
  done
  if [ -n "$loopbatch_skill_missing" ]; then
    bad "loop-batch — the composition permission lost a load-bearing part:$loopbatch_skill_missing
      The IT-IS-A-MAY needle is the one that matters most: turned into a MUST, this becomes
      \"one Loop Batch per iteration\", which is false the moment the block spans both repositories
      because a branch does not cross repositories. The MORE-THAN-ONE needle is that refusal stated
      positively. The DEFERRED needle keeps the derived commit-to-issue coverage check visible as a
      deliberate omission rather than an oversight — it is the only enforceable clause in the whole
      specification. The PRESENCE-not-HEAD needle is the residual a batch makes expensive: rule 7c
      head-scopes the GATEKEEPER's verdict and nothing head-scopes this persona's, so on a long-lived
      branch a first-commit marker satisfies hold 2 for everything after it. The NOTHING-GATES needle is
      what stops a reader inferring enforcement from a rule found in a file full of mechanisms.
      If this is a deliberate rewording, update the needles in this file in the same commit."
  else
    ok "loop-batch — the preload carries the permission as a permission, the more-than-one clause, the deferred coverage check, the marker residual and the not-a-gate clause"
  fi
fi

# ── 2 · both typed commands point at it, so neither promises a per-Issue MR ──
loopbatch_cmd_missing=""
if [ ! -r "$LOOPBATCH_AUTONOMY" ] || [ ! -r "$LOOPBATCH_NEWISSUE" ]; then
  bad "loop-batch — commands/autonomy-on.md or commands/new-issue.md is not readable; the pointers from
      the files a human TYPES to the composition permission cannot be checked."
else
  for loopbatch_autonomy_needle in \
    'the `loop` block MAY travel as one branch and one MR' \
    'the slice is the batch'
  do
    grep -qF -- "$loopbatch_autonomy_needle" "$LOOPBATCH_AUTONOMY" || loopbatch_cmd_missing="$loopbatch_cmd_missing
    missing from commands/autonomy-on.md: \"$loopbatch_autonomy_needle\""
  done
  loopbatch_newissue_needle='Filing a `loop` Issue does NOT reserve it a branch'
  grep -qF -- "$loopbatch_newissue_needle" "$LOOPBATCH_NEWISSUE" || loopbatch_cmd_missing="$loopbatch_cmd_missing
    missing from commands/new-issue.md: \"$loopbatch_newissue_needle\""
  if [ -n "$loopbatch_cmd_missing" ]; then
    bad "loop-batch — a typed command no longer routes the delivery unit correctly:$loopbatch_cmd_missing
      \`/autonomy-on\` is the file that WORKS the pool, so without the pointer its own
      \"finished through merge before opening the next\" reads as a per-Issue promise. \`/new-issue\`
      files the Issue, and without its needle a reader takes filing as reserving a branch. Both
      pointers are one-directional on purpose: the canonical wording is the skill's, and these say so
      rather than restating it."
  else
    ok "loop-batch — /autonomy-on and /new-issue both point at the composition permission and neither promises a per-Issue MR"
  fi
fi

# ── 3 · the layer reason is stated in its DURABLE form, not only as a dated measurement ──
loopbatch_durable_missing=""
if [ ! -r "$LOOPBATCH_SKILL" ]; then
  bad "loop-batch — skills/harness-engineering/SKILL.md is not readable; the durable statement of why no
      hook can observe the iteration cannot be checked."
else
  for loopbatch_durable_needle in \
    'no single-repo hook can observe the iteration at all,' \
    'about contents on a date, never as a separation between the two repositories'
  do
    grep -qF -- "$loopbatch_durable_needle" "$LOOPBATCH_SKILL" || loopbatch_durable_missing="$loopbatch_durable_missing
    missing: \"$loopbatch_durable_needle\""
  done
  if [ -n "$loopbatch_durable_missing" ]; then
    bad "loop-batch — the layer analysis fell back to its dated measurement alone:$loopbatch_durable_missing
      #339 argued from a fact about CONTENTS (every \`loop\` item in one repo, every \`product\` item in
      the other). That fact expires the first time a \`loop\` Issue is filed in the product repo — where
      the label already exists and has simply never been applied — and the conclusion it supports would
      look like it expired with it. The durable reason is that a hook receives one \`cwd\` while the
      iteration is not a repo-scoped object, so the conclusion holds whatever any repo contains. The
      second needle is the owner's 2026-08-29 framing: one development effort, two places where files
      live. Without it the measurement reads as a separation between the repositories.
      NOTE ON THE NEEDLE ITSELF: it is a SINGLE-LINE span deliberately, and the full sentence begins
      'Read that as a fact' on the previous line. \`grep -F\` is line-oriented, so a needle spanning a
      wrap matches nothing and a null result reads as an absence — the defect commands/autonomy-on.md
      records against itself. This needle was written across the wrap first and caught here."
  else
    ok "loop-batch — the layer reason is stated durably (one cwd, iteration not repo-scoped) and the dated measurement is flagged as a fact about contents"
  fi
fi

# ---------------------------------------------------------------------------------------------------
# WHAT WIP=1 PROTECTS IS RECORDED, AND THE HOOK IS STATED NOT TO ENFORCE IT (#343).
#
# WHY THIS EXISTS. WIP=1 stood for sixteen days with no recorded reason. #343 was filed to REVERSE it;
# the owner declined and re-scoped the Issue to the recording, on the ground that a proposal to relax a
# rule whose purpose is unwritten cannot be evaluated. ADR-0002's twenty-fifth amendment is the record.
#
# WHAT THESE ARMS HOLD, AND IT IS ONLY EVER PRESENCE:
#
#   1. THE RECORDING IS IN THE UNIVERSAL PRELOAD, with its THREE-LAYER separation intact, the two
#      measurements that say `wip-guard.sh` does not enforce WIP=1, the moment-not-matcher reason, and
#      the plain statement that the rule is held by instruction alone.
#   2. THE PORTABLE REGISTRY ROW no longer promises the gap away as a pending hook change — asserted in
#      BOTH directions, since the false clause leaving is the half a presence check cannot see.
#
# WHY LAYER 3 IS THE LOAD-BEARING NEEDLE. Layers 1 and 2 are the owner's quoted words and the measured
# failure. Layer 3 is the sentence saying they are NOT the same claim: what a rule CATCHES is not what
# its author WANTED caught. Delete it and the record reads as a rationale the owner gave, which he did
# not — the exact substitution the amendment rejected by name as its third considered option.
#
# WHY MOMENT-NOT-MATCHER IS ITS OWN NEEDLE. The twelfth amendment promised the gap away as a
# `wip-guard.sh` change. That is false: the hook is a PreToolUse on `gh pr create`, the last act of a
# slice, and the 2026-08-29 failure completed during the build. Without this sentence a later reader
# re-derives the promise, because "the hook is too weak" is the available reading and it is wrong about
# WHERE the weakness is.
#
# WHAT NO ARM CAN OWN. That any session obeyed WIP=1. Nothing captures how many agents shared a
# checkout — that is the whole finding, not a gap in this file. A green here means the recording is
# written down. That is the entire claim.
#
# TWO INDEPENDENT `if` BLOCKS, EACH WITH ITS OWN VACUITY GUARD: an arm nested under another emits NO
# verdict when the one above it goes red.
WIP343_SKILL="$ROOT/skills/harness-engineering/SKILL.md"
WIP343_REG="$ROOT/docs/blueprint-registry.md"

# ── 1 · the three-layer recording, the two measurements and the not-engineered admission ──
wip343_skill_missing=""
if [ ! -r "$WIP343_SKILL" ]; then
  bad "wip-recording — skills/harness-engineering/SKILL.md is not readable; what WIP=1 protects cannot
      be checked at all. This is the preload every persona carries, which is why the recording lives
      here rather than in narrative prose."
else
  for wip343_needle in \
    '#### What WIP=1 is PROTECTING — recorded 2026-08-29 (#343), because it was never written down' \
    'from EVIDENCE rather than reconstruction' \
    'a mutation probe left APPLIED to' \
    '**The failure class is invisible to git by construction**' \
    'an EVENT is dated from the artifact that reports it' \
    'and a MEASUREMENT from the day it was run' \
    '**Layer 3 — what remains unrecorded, stated so nobody mistakes layer 2 for it.**' \
    '#### `wip-guard.sh` does NOT enforce WIP=1, and a reader who thinks it does is wrong about what protects them' \
    '**It bounds concurrency; it has never bounded a count per iteration, and across nine consecutive' \
    'grep -c worktree hooks/scripts/wip-guard.sh' \
    'That is a moment problem, not a matcher problem' \
    '**So: WIP=1 is held by instruction and by nothing else.**' \
    'it is true of the count half and FALSE of the half that actually cost something.'
  do
    grep -qF -- "$wip343_needle" "$WIP343_SKILL" || wip343_skill_missing="$wip343_skill_missing
    missing: \"$wip343_needle\""
  done
  if [ -n "$wip343_skill_missing" ]; then
    bad "wip-recording — the record of what WIP=1 protects lost a load-bearing part:$wip343_skill_missing
      FROM-EVIDENCE is layer 2's heading, and it read 'measured rather than reconstructed' for one
      round — four lines above the sentence conceding the item was a REPORT, and while the record
      claimed the carrier labelled it as one. A heading that overclaims is worse than a body that
      does, because the body is what nobody re-reads. MUTATION-PROBE is the second of the two evidence
      items the owner's own comment enumerates; without it layer 2 stands at n=1 exactly where it
      concedes it has no instrument, and nothing would say an item was dropped. INVISIBLE-TO-GIT is
      why neither item can ever be more than a report: an uncommitted edit on a shared tree leaves no
      commit, no diff and no ref, so the absence of an instrument reading is a property of the failure
      rather than a shortfall of the record. THE DATING RULE IS TWO NEEDLES AND BOTH ARE REQUIRED,
      because it is two clauses and only one of them ever failed. AN-EVENT-IS-DATED is the half that
      prevents the defect actually paid for: dates taken from the authoring session's clock, post-dating
      the very comment they cite. AND-A-MEASUREMENT is the half nobody would get wrong. For one round
      only the second was needled, so the clause that carries the rule could be deleted with the whole
      suite green — a presence check pointed at the half that never fails, which is precisely the row
      0007 shape this slice exists to close, reproduced inside it. It was found by EXECUTION, not by
      reading: delete the event clause alone and the arm passed.
      A COROLLARY WORTH MORE THAN THE FIX. The mutation offered as proof of this arm (M9) deletes the
      MEASUREMENT clause, so it reddened on the half that was never at risk and demonstrated nothing
      about the half that was. A mutation that passes for the wrong reason is worse than an absent one,
      because it is presented as evidence. When a needle covers a rule with more than one clause, mutate
      EACH clause separately or say plainly which one the mutation proves.
      LAYER 3 is the one that matters most: without it the owner's quoted intent and the reported
      failures blur into a single claim, and the record reads as a rationale he gave. He gave none —
      #88 rejects a count, the 2026-08-13 correction imposes one, the 2026-08-29 answer keeps it while
      naming an unrelated precondition. The TWO MEASUREMENT needles are what stop a reader inferring
      that \`wip-guard.sh\` enforces WIP=1: it lists only OPEN PRs, so under WIP=1 it never reaches its
      overlap loop, and it contains the word 'worktree' zero times, so two agents in one checkout are
      indistinguishable to it. MOMENT-NOT-MATCHER is why no version of that hook could hold the gap —
      it fires at \`gh pr create\` and the failure completes during the build. HELD-BY-INSTRUCTION is
      the admission this loop's own test demands. And the LAST needle is the strike of the twelfth
      amendment's remedy clause, which promised the gap away as a pending hook change.
      NOTE ON THE NEEDLES THEMSELVES: every one is a SINGLE-LINE span, checked with \`grep -c -F\`
      before being written here. \`grep -F\` is line-oriented, so a needle spanning a wrap matches
      nothing and the null result reads as an absence rather than as a broken needle.
      If this is a deliberate rewording, update the needles in this file in the same commit."
  else
    ok "wip-recording — the preload carries the three-layer record with both evidence items labelled reports, BOTH clauses of the dating rule, both measurements, the moment-not-matcher reason and the held-by-instruction admission"
  fi
fi

# ── 2 · the portable registry row states the real limit, in BOTH directions ──
#
# THE NEGATIVE HALF IS NOT DECORATION. The row used to end "closing the gap is a change to this hook
# and is named as owed, not as done" — a promise that the gap had a known remedy and merely needed
# doing. A presence check cannot see a false sentence that stayed; only asserting its ABSENCE can.
wip343_reg_problems=""
if [ ! -r "$WIP343_REG" ]; then
  bad "wip-recording — docs/blueprint-registry.md is not readable; the portable row for the WIP guard
      cannot be checked. That row is what another harness reads, so a stale limit there travels."
else
  for wip343_reg_needle in \
    '**It also never runs its own overlap check while that policy is obeyed**' \
    'A shared *checkout* is not a shared *file*'
  do
    grep -qF -- "$wip343_reg_needle" "$WIP343_REG" || wip343_reg_problems="$wip343_reg_problems
    missing: \"$wip343_reg_needle\""
  done
  wip343_dead='closing the gap is a change to this hook and is named as owed, not as done'
  grep -qF -- "$wip343_dead" "$WIP343_REG" && wip343_reg_problems="$wip343_reg_problems
    present again, and it is FALSE: \"$wip343_dead\""
  if [ -n "$wip343_reg_problems" ]; then
    bad "wip-recording — the portable registry row misstates what the WIP guard cannot do:$wip343_reg_problems
      The two positive needles are the limits measured on 2026-08-29: the hook never reaches its
      overlap loop while WIP=1 is obeyed (it lists only OPEN PRs), and it cannot see a shared checkout
      at all. The negative needle is the clause that was struck — it promised the gap away as a hook
      change, and no change to that hook can hold it, because it fires at pull-request creation while
      the failure completes during the build. This row is the surface another harness adopts, so a
      restored promise there is a false limit exported rather than a local staleness."
  else
    ok "wip-recording — the portable row states both measured limits and no longer promises the gap away as a hook change"
  fi
fi

# ---------------------------------------------------------------------------------------------------
# ESTIMATION: THE WEIGHT IS AN `sp:N` LABEL, AND IT BLOCKS ENTRY RATHER THAN BEING DECORATION (#326).
#
# WHY THIS EXISTS, and it is a different failure from the axis arms above. This slice was dispatched
# with a FALSE PREMISE — that the owner had decided "iterations yes, estimation no". He had not; the
# artifact contradicting it was a comment on the very Issue being built, in his own quoted words
# ("inteiro. estimar antes é positivo"). The build refused to write "void — owner's decision" into a
# durable record on an agent message's authority, and he confirmed the ratified design stands.
#
# NOTHING MECHANICAL CAUGHT THAT, and this block does not pretend to. dispatch-premise-guard.sh checks
# TREE-SHAPED premises — a SHA, a branch, a path — because those resolve against a repository. "The
# owner decided X" is not tree-shaped: its truth-maker is an Issue comment, and no PreToolUse payload
# carries one. What these arms hold is the far narrower thing a file CAN hold: that the decision, once
# taken, is still written where the loop reads it.
#
# WHAT THESE ARMS OWN: the carrier vocabulary and the estimator sets in the canonical surface; the
# preflight and the owner's rule in the file the loop EXECUTES; and — both directions — that the
# retired "not built here" claim has not come back to life outside a strike.
#
# WHY THE NEGATIVE HALF IS SCOPED TO UNSTRUCK TEXT. Both surfaces deliberately KEEP the wrong sentences
# visible inside `~~…~~`, because they were published and someone may have read them in the hour they
# stood. A check that swept the literal would force the correction to delete its own history to go
# green — the opposite of this repo's convention — so the strip-then-count shape is used, and `grep -c`
# rather than `-q`: `-q` exits early, SIGPIPEs `sed` under `pipefail`, and would report "clean" on
# exactly the files that are not.
#
# OWN `if`, OWN VACUITY GUARD, same reason as the block above: an arm in an `elif` under another emits
# NO verdict when the one above goes red, and a total that stays plausible cannot surface that.
EST_SKILL="$ROOT/skills/harness-engineering/SKILL.md"
EST_CMD="$ROOT/commands/autonomy-on.md"

# ── 1 · the canonical surface carries the vocabulary, the estimators and the enforcement limit ───
est_skill_missing=""
if [ ! -r "$EST_SKILL" ]; then
  bad "estimation carrier — skills/harness-engineering/SKILL.md is not readable; the sp:N vocabulary
      and the estimator sets cannot be checked at all."
else
  for est_needle in \
    '### Estimation — the weight is an `sp:N` label, and the estimators are the personas that work the type' \
    'sp:1  sp:2  sp:3  sp:5  sp:8  sp:13' \
    '| `loop` | `agents-lead` · `quality-assurance` |' \
    '| `sp:N` | the item'
  do
    grep -qF -- "$est_needle" "$EST_SKILL" || est_skill_missing="$est_skill_missing
    missing: \"$est_needle\""
  done
  # The retired claim must not be live. Struck occurrences are not hits — see the header.
  est_retired='The designed carrier is a'
  est_retired_hits=$(sed 's/~~[^~]*~~//g' "$EST_SKILL" | grep -cF -- "$est_retired" || true)
  [ "${est_retired_hits:-0}" -eq 0 ] || est_skill_missing="$est_skill_missing
    RETIRED claim is live (not struck): the weight is described as merely DESIGNED, not built"
  if [ -n "$est_skill_missing" ]; then
    bad "estimation carrier — the canonical surface no longer states the built carrier:$est_skill_missing
      A milestone has no numeric field of any kind, so the label IS the weight — there is no fallback
      surface for it. The \`loop\` estimator row is two names on purpose: \`agents-lead\` authors loop
      items AND estimates them, and \`quality-assurance\` is the second voice that exposes the bias in a
      median rather than removing it. Cutting that row to one name silently reinstates
      author-estimates-own-work with nothing anywhere to say so."
  else
    ok "estimation carrier — the canonical surface carries the sp:N vocabulary, the per-type estimator sets and the vocabulary-table row"
  fi
fi

# ── 2 · the executed command refuses to ENTER while a pendency stands ────────────────────────────
est_cmd_missing=""
if [ ! -r "$EST_CMD" ]; then
  bad "estimation carrier — commands/autonomy-on.md is not readable; the preflight cannot be checked."
else
  for est_cmd_needle in \
    '## Preflight — outstanding HITL work blocks ENTRY (#326)' \
    'todas pendencias HITL devem ser zeradas no momento da invocacao do comando' \
    '| **an item with no estimate** |' \
    '**one thing at a time**, never'
  do
    grep -qF -- "$est_cmd_needle" "$EST_CMD" || est_cmd_missing="$est_cmd_missing
    missing: \"$est_cmd_needle\""
  done
  if [ -n "$est_cmd_missing" ]; then
    bad "estimation carrier — commands/autonomy-on.md no longer gates ENTRY on the pendency set:$est_cmd_missing
      The owner's rule is quoted rather than paraphrased because it is the rule: zero outstanding HITL
      work AT INVOCATION. A preflight that surfaces a LIST instead of one thing at a time is a decision
      list, which he has rejected repeatedly — the one-at-a-time clause is part of the rule, not of its
      presentation. And an estimate pendency at ENTRY is a different rule from one discovered MID-DRAIN,
      which escalates immediately and parks the item; collapsing the two either wakes him for every
      doubt or holds a real blocker until the iteration closes."
  else
    ok "estimation carrier — commands/autonomy-on.md blocks entry on the pendency set, one thing at a time"
  fi
fi

# ---------------------------------------------------------------------------------------------------
# THE LANE ANCHOR: README.md's `roster:lanes` fence — one line per (issue type, tier) pair (#329).
#
# WHY IT IS GATED AT ALL. The fence is not a rule; the states table in
# `skills/harness-engineering/SKILL.md` is. The fence is a machine-readable MIRROR of that table's
# lane rows, published so a consumer (`tadeumendonca-io`'s `/architecture` page) can compare its own
# prose against something a regex can read. A mirror nobody checks is a second source of truth, which
# is the arrangement #329 was: one surface stating the lane relation, wrong, for eleven days.
#
# WHAT THESE ARMS OWN, EXACTLY — and each is its own `if` with its own vacuity guard, per THE CHAINING
# RULE in the header:
#
#   A · exactly ONE fence, asserted as a COUNT and not as presence — on a FORECAST, and the tense is the
#       point. NOTHING READS THIS FENCE TODAY: `roster:lanes` appears nowhere in `tadeumendonca-io`, and
#       the reader that exists there (`rosterDispatchNames`, `apps/fed/scripts/harness-source.mjs`,
#       called from `check-harness-drift.mjs`) matches a DIFFERENT marker, `roster:dispatch`, in that
#       repo's own `CLAUDE.md`. It is the PRECEDENT this anchor is shaped to mirror, not a reader of
#       these lines. The forecast: the consumer built for this anchor will mirror that reader, whose
#       fence regex is lazy and non-global, so a second pair of markers would be silently read by
#       nothing. Asserting the count closes that shape BEFORE a consumer inherits it — which is the only
#       moment it is cheap. Presence would be green on the duplicate either way.
#   B · the six (type, tier) keys are each present EXACTLY ONCE, and no arm is EMPTY. An empty arm is
#       the vacuous-green shape this file books repeatedly — an extractor returning `[]` for a lane
#       compares equal to "nothing missing" on the consumer's side.
#   C · every id inside the fence resolves to a live `agents/<id>.md`.
#
# WHAT IS DELIBERATELY **NOT** ASSERTED, in three parts, so the green is not read as more than it is:
#
#   1. THE REVERSE OF C IS NOT MADE, AND WOULD BE FALSE. `quality-assurance` is tier 3 and gates all
#      three lanes, so it is correctly absent from a six-line (type, tier) mirror. "Every live persona
#      appears in the fence" would redden on correct content.
#   2. FENCE-AGAINST-TABLE IS NOT ASSERTED, AND THE REASON IS MEASURED RATHER THAN ECONOMIC. The
#      obvious third arm — fence ids ⊆ the backticked ids of the matching table row — was written and
#      REJECTED: the `loop` intake row contains `` `tech-lead` `` inside the clause excluding it, and
#      the `content` build row contains `` `developer` `` inside the clause excluding it. So a subset
#      arm is green on exactly the two errors this anchor exists to catch, and red on nothing. That is
#      the same negation trap that forced prose out of the fence, seen from the gate's side.
#   3. THE PERSONA ASSIGNMENT IS NOT PINNED AS LITERALS. The six KEYS below are enumerated because they
#      are structural — issue types × tiers, a shape that changes only when the state machine does. The
#      NAMES on each line are not, because an enumeration of the roster inside the file written to
#      catch stale enumerations is this suite's signature defect, booked twice already in the roster
#      block above. What holds the names is arm C plus a human reading the diff.
LANE_README="$ROOT/README.md"
LANE_OPEN='<!-- roster:lanes -->'
LANE_CLOSE='<!-- /roster:lanes -->'

lane_n_open=$(grep -cxF -- "$LANE_OPEN" "$LANE_README" 2>/dev/null || true)
lane_n_close=$(grep -cxF -- "$LANE_CLOSE" "$LANE_README" 2>/dev/null || true)
lane_body=$(awk -v o="$LANE_OPEN" -v c="$LANE_CLOSE" '$0==o{f=1;next} $0==c{f=0} f' "$LANE_README" 2>/dev/null \
  | grep -v '^```' | grep -v '^[[:space:]]*$' || true)
lane_rows=$(printf '%s\n' "$lane_body" | grep -c . || true)

# ── A · exactly one fence, both markers ─────────────────────────────────────────────────────────
if [ "${lane_n_open:-0}" -eq 1 ] && [ "${lane_n_close:-0}" -eq 1 ]; then
  ok "lane anchor — README.md carries exactly one roster:lanes fence (1 opening marker, 1 closing)"
else
  bad "lane anchor — README.md must carry EXACTLY ONE roster:lanes fence; found $lane_n_open opening and $lane_n_close closing marker(s).
      Zero means the anchor is gone and every consumer comparing against it has nothing to compare.
      Two means the consumer's regex reads the FIRST pair and ignores the rest, silently — which is
      why this is a count and not a presence check."
fi

# ── B · six keys, each exactly once, none of them empty ─────────────────────────────────────────
lane_expected='product tier1
content tier1
loop tier1
product tier2
content tier2
loop tier2'
if [ "${lane_rows:-0}" -eq 0 ]; then
  bad "lane anchor — the roster:lanes fence extracted NO lines, so the arm checks below are vacuous.
      An empty extraction compares equal to 'nothing wrong' on every set check that follows it."
else
  lane_arm_problems=""
  while IFS= read -r lane_key; do
    [ -z "$lane_key" ] && continue
    lane_matched=$(printf '%s\n' "$lane_body" | awk -v k="$lane_key" '$1" "$2 == k')
    lane_n=$(printf '%s\n' "$lane_matched" | grep -c . || true)
    if [ "$lane_n" -ne 1 ]; then
      lane_arm_problems="$lane_arm_problems
    '$lane_key': $lane_n line(s), expected exactly 1"
      continue
    fi
    lane_ids=$(printf '%s\n' "$lane_matched" | grep -ohE '`[a-z][a-z0-9-]*`' | tr -d '`' | sort -u | grep -c . || true)
    [ "${lane_ids:-0}" -ge 1 ] || lane_arm_problems="$lane_arm_problems
    '$lane_key': names NO persona — an EMPTY arm"
  done <<< "$lane_expected"
  if [ "$lane_rows" -ne 6 ]; then
    lane_arm_problems="$lane_arm_problems
    the fence holds $lane_rows line(s); the (issue type × tier) grid is 3 × 2 = 6"
  fi
  if [ -z "$lane_arm_problems" ]; then
    ok "lane anchor — all 6 (issue type, tier) arms present exactly once, none of them empty"
  else
    bad "lane anchor — the roster:lanes fence does not cover the (issue type × tier) grid:$lane_arm_problems
      An arm that is missing and an arm that is empty fail the SAME way on the consumer's side: the
      extractor returns nothing for that lane, and nothing compares equal to 'nothing missing'. The
      keys are two bare words — 'product tier1' — because the fence carries persona ids and nothing
      else; a negation written into it would be pulled out as an id by any consumer that reads it."
  fi
fi

# ── C · every id in the fence resolves to a live brief ──────────────────────────────────────────
lane_all_ids=$(printf '%s\n' "$lane_body" | grep -ohE '`[a-z][a-z0-9-]*`' | tr -d '`' | sort -u | grep -v '^$' || true)
if [ -z "${lane_all_ids//[[:space:]]/}" ]; then
  bad "lane anchor — no persona id could be extracted from the roster:lanes fence, so the resolution
      check is vacuous. Either the fence is gone, or its ids stopped being written in backticks — the
      only form this repo uses for a persona reference, and the only one a consumer's extractor reads."
else
  lane_dead=""
  while IFS= read -r lane_id; do
    [ -z "$lane_id" ] && continue
    [ -r "$ROOT/agents/$lane_id.md" ] && continue
    lane_dead="$lane_dead
    \`$lane_id\` is named in the fence and has NO file at agents/$lane_id.md"
  done <<< "$lane_all_ids"
  if [ -z "$lane_dead" ]; then
    ok "lane anchor — every persona id in the fence resolves to a live agents/*.md ($(printf '%s\n' "$lane_all_ids" | grep -c .) distinct ids)"
  else
    bad "lane anchor — the fence dispatches a persona that does not exist:$lane_dead
      This is the #329 defect in its mechanical form: a retired name left standing in the one surface
      that states the lane relation. The count does not move when a persona is renamed, so nothing
      else in this file can see it."
  fi
fi

# ---------------------------------------------------------------------------------------------------
# EVERY MECHANISM DECLARES A `purpose:`, AND EVERY DECLARATION NAMES A MECHANISM (#313 slice 1).
#
# WHAT THE FIELD IS FOR, AND WHY IT IS NOT `description:`. `description:` is a TRIGGER, addressed to the
# model: *when do I reach for this*. `purpose:` is an OBLIGATION, addressed to an engineer on a harness
# nobody here has measured: *why does this mechanism exist, and what is lost if it is not reproduced*.
# The two answer different questions and are asserted to differ, because the cheapest way to fill a new
# field is to paste the neighbouring one — and a pasted trigger reads as a purpose to everything except
# a reader who already knew.
#
# WHY IT IS GATED AT ALL. `tadeumendonca-io`'s `harness.json` is a drift-checked inventory of exactly
# these elements and it carries IDENTITY ONLY — file, event, matcher, enforcement — because its
# generator has no purpose to read. ADR-0043 there deferred adding one on the grounds that a schema
# serving one consumer's page was an inversion; ADR-0021's 2026-08-28 amendment here records why that
# reason lapsed — `/blueprint` is a second consumer, in the plugin's own repo. A field
# nothing asserts would be back to prose in a month, and the failure would be silent in the direction
# that matters: a mechanism added with no purpose looks exactly like one whose purpose is elsewhere.
#
# THE DECLARATION IS POSITIONAL, AND THAT IS A MEASUREMENT RATHER THAN A PREFERENCE. `# purpose:` at
# column 0 already occurred in this tree as ORDINARY PROSE before the field existed:
# `orchestrator-write-guard.sh` read "Both are denied on / purpose: a write into `.git/` escapes the
# diff entirely" — a wrapped sentence putting the token at the start of a line, found by this arm's
# first run rather than by reading. So a declaration is: line 2 of a hook script (immediately after
# the shebang), or a `purpose:` key inside a markdown file's frontmatter fence.
#
# AND THE ACCIDENTAL OCCURRENCE WAS REWRAPPED RATHER THAN EXEMPTED, which is the half worth arguing.
# Position is what THIS suite reads; `^# purpose:` is what a naive consumer greps, and the whole point
# of the field is to be read by a consumer nobody here controls — `-io`'s generator today, a foreign
# harness tomorrow. One stray column-0 occurrence hands that consumer two answers for a file that has
# one. So the forward arm asserts BOTH: the declaration is at the declared position, and it is the
# only line in the file that begins that way. A gate that tolerated the stray would be correct about
# this repository and wrong about every reader of it.
#
# WHAT NO ARM BELOW CAN HOLD, said before the greens are read. A purpose is unfalsifiable by grep. The
# suite asserts that one exists, that it is in the declared position, that it is long enough to be a
# sentence and that it is not the description reworded. It cannot assert that it is TRUE of the file,
# and a purpose describing what a hook was MEANT to do rather than what it does passes every arm here.
# That is a reviewer's read, and it is the same residual `docs/blueprint-registry.md` already states
# about `propósito`.
#
# AND THE REGISTRY IS NOT THIS FIELD'S SECOND SOURCE. `docs/blueprint-registry.md` is keyed on a
# BEHAVIOUR — one row may span two rules of one file, three files, or none — and this field is keyed on
# a FILE. A behaviour no file carries has a row and no `purpose:`; a file carrying two behaviours has
# one `purpose:` and two rows. They are not two spellings of one claim and nothing here cross-checks
# them, deliberately: a gate tying them together would force one to be a projection of the other, which
# is precisely the collapse both were separated to avoid.

purpose_fm() { awk 'NR==1 && $0 != "---" { exit } NR==1 { infm=1; next } infm && $0 == "---" { exit } infm' "$1"; }

# The mechanism set, derived from FOUR independent sources and never from the purpose scan itself —
# deriving it from what carries a purpose would assert `grep` against `grep`.
purpose_hooks="$(grep -oE 'hooks/scripts/[a-z0-9-]+\.sh' "$ROOT/hooks/hooks.json" 2>/dev/null | sort -u || true)"
purpose_md="$(
  find "$ROOT/agents"   -maxdepth 1 -name '*.md' -type f 2>/dev/null | sed "s|^$ROOT/||"
  find "$ROOT/commands" -maxdepth 1 -name '*.md' -type f 2>/dev/null | sed "s|^$ROOT/||"
  jq -r '.skills[]?' "$ROOT/.claude-plugin/plugin.json" 2>/dev/null | sed 's|^\./||; s|$|/SKILL.md|'
)"
purpose_md="$(printf '%s\n' "$purpose_md" | grep . | sort -u || true)"
purpose_hooks_n="$(printf '%s\n' "$purpose_hooks" | grep -c . || true)"
purpose_md_n="$(printf '%s\n' "$purpose_md" | grep -c . || true)"

# ── 1 · FORWARD — every mechanism carries exactly one purpose, in the declared position ────────────
if [ "$purpose_hooks_n" -lt 5 ] || [ "$purpose_md_n" -lt 20 ]; then
  bad "purpose (forward) — the mechanism set did not enumerate ($purpose_hooks_n hook(s), $purpose_md_n markdown
      mechanism(s)). Either hooks.json, agents/, commands/ or plugin.json's skills array stopped being
      readable, or jq is unavailable. NOTHING WAS ASSERTED; a green here would have been an artifact of
      the enumeration breaking, which is the direction this suite has been wrong in before."
else
  purpose_missing=""
  while IFS= read -r h; do
    [ -z "$h" ] && continue
    if [ ! -r "$ROOT/$h" ]; then
      purpose_missing="$purpose_missing
    $h — registered in hooks.json and not readable"
      continue
    fi
    if ! sed -n '2p' "$ROOT/$h" | grep -qE '^# purpose: .+'; then
      purpose_missing="$purpose_missing
    $h — line 2 is not '# purpose: <one line>'"
    fi
    n="$(grep -cE '^# purpose: ' "$ROOT/$h" || true)"
    if [ "$n" -gt 1 ]; then
      purpose_missing="$purpose_missing
    $h — $n lines begin '# purpose: '; exactly one may, and it is line 2"
    fi
  done <<< "$purpose_hooks"
  while IFS= read -r m; do
    [ -z "$m" ] && continue
    if [ ! -r "$ROOT/$m" ]; then
      purpose_missing="$purpose_missing
    $m — enumerated as a mechanism and not readable"
      continue
    fi
    n="$(purpose_fm "$ROOT/$m" | grep -cE '^purpose: .+' || true)"
    if [ "$n" -ne 1 ]; then
      purpose_missing="$purpose_missing
    $m — carries $n 'purpose:' key(s) in its frontmatter; exactly one is required"
    fi
  done <<< "$purpose_md"

  if [ -z "$purpose_missing" ]; then
    ok "purpose (forward) — all $((purpose_hooks_n + purpose_md_n)) mechanisms declare exactly one purpose in the declared position ($purpose_hooks_n hooks at line 2, $purpose_md_n frontmatter keys)"
  else
    bad "purpose (forward) — a mechanism this plugin ships declares no purpose, or declares two:$purpose_missing
      Every hook registered in hooks.json, every persona in agents/, every command in commands/ and
      every skill declared in plugin.json carries ONE 'purpose:' line. A hook declares it on line 2,
      immediately after the shebang; a markdown mechanism declares it as a frontmatter key. This is the
      one field an inventory consumer cannot derive from the tree — identity it can read, obligation it
      cannot — so a mechanism without one is invisible to every consumer of the inventory."
  fi
fi

# ── 2 · SHAPE — a purpose is a sentence, and it is not the description reworded ────────────────────
purpose_shape_scanned=0
purpose_shape=""
while IFS= read -r h; do
  [ -z "$h" ] && continue
  [ -r "$ROOT/$h" ] || continue
  v="$(sed -n '2p' "$ROOT/$h" | grep -E '^# purpose: ' | sed 's/^# purpose: //' || true)"
  [ -n "$v" ] || continue
  purpose_shape_scanned=$((purpose_shape_scanned + 1))
  [ "${#v}" -ge 60 ] || purpose_shape="$purpose_shape
    $h — the purpose is ${#v} characters; under 60 it is a label, not an obligation"
done <<< "$purpose_hooks"
while IFS= read -r m; do
  [ -z "$m" ] && continue
  [ -r "$ROOT/$m" ] || continue
  front="$(purpose_fm "$ROOT/$m")"
  v="$(printf '%s\n' "$front" | grep -E '^purpose: ' | head -1 | sed 's/^purpose: //')"
  [ -n "$v" ] || continue
  purpose_shape_scanned=$((purpose_shape_scanned + 1))
  [ "${#v}" -ge 60 ] || purpose_shape="$purpose_shape
    $m — the purpose is ${#v} characters; under 60 it is a label, not an obligation"
  d="$(printf '%s\n' "$front" | grep -E '^description: ' | head -1 | sed 's/^description: //' | sed 's/^"//; s/"$//')"
  if [ -n "$d" ] && [ "$v" = "$d" ]; then
    purpose_shape="$purpose_shape
    $m — the purpose is byte-identical to the description; they answer different questions"
  fi
done <<< "$purpose_md"

if [ "$purpose_shape_scanned" -lt 20 ]; then
  bad "purpose (shape) — only $purpose_shape_scanned purposes were read, which is fewer than this plugin
      ships. The extraction broke; nothing was judged."
elif [ -z "$purpose_shape" ]; then
  ok "purpose (shape) — all $purpose_shape_scanned purposes are a sentence rather than a label, and none is the file's description pasted twice"
else
  bad "purpose (shape) — a purpose is not one:$purpose_shape
      'description:' says WHEN to reach for the file; 'purpose:' says WHY the mechanism exists and what
      is lost without it. A gate cannot tell a true purpose from a plausible one — that is a reviewer's
      read — but it can refuse the two failures that need no judgement: a label, and a paste."
fi

# ── 3 · REVERSE — every declaration names a mechanism that exists ──────────────────────────────────
# The direction that is silent all the way down. A hook DEREGISTERED from hooks.json, a skill dropped
# from plugin.json's array, a brief moved out of agents/ — each leaves a file still declaring a purpose
# for a mechanism this plugin no longer ships, and nothing else in this suite reads that file at all.
purpose_declarers="$(
  for f in "$ROOT"/hooks/scripts/*.sh; do
    [ -r "$f" ] || continue
    sed -n '2p' "$f" | grep -qE '^# purpose: ' && printf '%s\n' "${f#"$ROOT"/}"
  done
  for f in "$ROOT"/agents/*.md "$ROOT"/commands/*.md "$ROOT"/skills/*/SKILL.md; do
    [ -r "$f" ] || continue
    purpose_fm "$f" | grep -qE '^purpose: ' && printf '%s\n' "${f#"$ROOT"/}"
  done
)"
purpose_declarers_n="$(printf '%s\n' "$purpose_declarers" | grep -c . || true)"
purpose_set="$(printf '%s\n%s\n' "$purpose_hooks" "$purpose_md" | sort -u)"

if [ "$purpose_declarers_n" -lt 20 ]; then
  bad "purpose (reverse) — only $purpose_declarers_n files were found declaring a purpose, which is fewer
      than this plugin ships. The scan lost its subject; the reverse direction did NOT run."
else
  purpose_orphans=""
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    printf '%s\n' "$purpose_set" | grep -qxF "$f" && continue
    purpose_orphans="$purpose_orphans
    $f — declares a purpose and is not a mechanism this plugin ships"
  done <<< "$purpose_declarers"
  if [ -z "$purpose_orphans" ]; then
    ok "purpose (reverse) — all $purpose_declarers_n declarations name a mechanism this plugin ships (a hook registered in hooks.json, a brief in agents/, a typed command, or a skill declared in plugin.json)"
  else
    bad "purpose (reverse) — a purpose is declared for something that is not a mechanism:$purpose_orphans
      A file declaring a purpose is claiming to be an element of this harness. A test suite is not one;
      a deregistered hook is not one any more; a skill dropped from plugin.json's array does not exist
      to the model at all. Either the file is a mechanism and its registration is missing, or it is not
      and the declaration is. Nothing else in this suite would say so."
  fi
fi

# ---------------------------------------------------------------------------------------------------
# THE `invocable:` FIELD IS A PARSING CONTRACT WITH THREE HOLDERS, AND ALL THREE MUST SPELL IT (#337).
#
# A CONSUMER AND A PRODUCER OF THE SAME LITERAL, WHICH IS WHY THIS IS NOT #335's DEFEATED FENCE. #335
# proposed matching a SENTENCE and an inserted word beat it. This matches a FIELD LABEL that a script
# greps at column 0 — the same class as `docs/blueprint-registry.md`'s Portuguese field labels, which
# this suite already reads literally for the same reason. Rename the field in the guard and the two
# documents that tell an intake to write it are instantly wrong, silently, in the direction that reads
# as "nothing to declare".
#
# NAMED GAP — THIS ASSERTS THAT THE RULE IS WRITTEN, NEVER THAT IT IS OBEYED. Nothing here reads an
# Issue, and nothing anywhere makes an intake write the line. An Issue filed with no `invocable:` field
# passes this arm, passes the guard, and closes with its promise unstated — that is the mechanism's
# load-bearing limit, stated in three places on purpose and gated in none.
invocable_holders="hooks/scripts/closure-artifact-guard.sh
skills/harness-engineering/SKILL.md
commands/new-issue.md"
invocable_missing=""
invocable_checked=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if [ ! -r "$ROOT/$f" ]; then
    invocable_missing="$invocable_missing
    $f — does not exist or is unreadable"
    continue
  fi
  invocable_checked=$((invocable_checked + 1))
  grep -qF 'invocable:' "$ROOT/$f" || invocable_missing="$invocable_missing
    $f — does not carry the literal 'invocable:'"
done <<< "$invocable_holders"

if [ "$invocable_checked" -lt 3 ]; then
  bad "invocable field — only $invocable_checked of 3 holders were readable, so nothing was asserted:$invocable_missing"
elif [ -n "$invocable_missing" ]; then
  bad "invocable field — the closure declaration's label is not spelled by every holder:$invocable_missing
      The guard greps this literal at column 0 of an Issue body; the preload and the intake command are
      the only things that tell anyone to write it. A rename in one place is silent in the other two."
else
  ok "invocable field — the guard that reads it, the preload that states the rule and the intake command that writes it all spell 'invocable:'"
fi

# And the waiver is the recorded-narrowing escape: the guard must accept it and the rule must document
# it, or the only exit from a false promise is to leave the Issue open forever.
if grep -qF 'invocable-waived:' "$ROOT/hooks/scripts/closure-artifact-guard.sh" \
   && grep -qF 'invocable-waived:' "$ROOT/skills/harness-engineering/SKILL.md"; then
  ok "invocable field — the 'invocable-waived:' escape is both implemented and documented"
else
  bad "invocable field — 'invocable-waived:' is implemented or documented but not both.
      A guard with an undocumented escape is a guard people route around; a documented escape no guard
      honours is a promise the deny text cannot keep."
fi

# ---------------------------------------------------------------------------------------------------
# THE `closes:` DECLARATION IS A SECOND PARSING CONTRACT WITH A CONSUMER AND A PRODUCER (#363).
#
# Rule 7d in `permission-guard.sh` greps `^closes:` out of the gate's own verdict comment; nothing but
# `agents/quality-assurance.md` tells the gate to write it. Rename or re-anchor it in one place and the
# other is instantly wrong, silently, in the direction that reads as "this PR declares no close" — i.e.
# every merge that closes anything gets denied, or every declaration stops counting. Same class as the
# `invocable:` block above and the `gh_repo_flag` identity arms: a field label read literally at
# column 0.
#
# EVERY NEEDLE IS ASSERTED AT COUNT EXACTLY 1 (or an explicit N, stated), not at "at least one". A
# `grep -qF` arm's real property is *count >= 1*, so a line-deletion probe removes the needle only when
# it is unique — an arm that passes on two occurrences cannot be falsified by deleting one.
#
# NAMED GAP, THE SAME ONE THE `invocable:` BLOCK CARRIES: this asserts the contract is WRITTEN in both
# halves. It cannot observe a verdict, cannot observe a merge, and cannot tell whether a declaration
# that was written was true. Whether the gate verified delivery before declaring is a reviewer's read
# and there is no instrument for it — the rule's own text says so, in the guard and in the brief.
closes_guard="$ROOT/hooks/scripts/permission-guard.sh"
closes_brief="$ROOT/agents/quality-assurance.md"

if [ ! -r "$closes_guard" ] || [ ! -r "$closes_brief" ]; then
  bad "closes declaration — a holder is unreadable
      ($([ ! -r "$closes_guard" ] && printf 'hooks/scripts/permission-guard.sh ')$([ ! -r "$closes_brief" ] && printf 'agents/quality-assurance.md ')),
      so nothing below was compared and a green would be an artifact of the break."
else
  closes_anchor="$(grep -c -F 'test("^closes:")' "$closes_guard" || true)"
  closes_query="$(grep -c -F -- '--json headRefOid,comments,closingIssuesReferences' "$closes_guard" || true)"
  closes_taught="$(grep -c -F 'closes: <every Issue number this PR will close' "$closes_brief" || true)"

  # ── arm 1 · the consumer reads the declaration, anchored at column 0 ──
  if [ "${closes_anchor:-0}" -ne 1 ]; then
    bad "closes declaration — permission-guard.sh carries the anchored extraction 'test(\"^closes:\")'
      ${closes_anchor} time(s), not exactly 1. Drop the '^' and the rule passes on a verdict that merely
      MENTIONS the Issue number in prose — which is the exact case it exists to refuse, because on the
      live instance BOTH verdicts on PR #356 contain '#355', the merge-authorising one included."
  else
    ok "closes declaration — rule 7d extracts the declaration anchored at column 0, exactly once"
  fi

  # ── arm 2 · the consumer actually ASKS the forge for the set it compares ──
  # Asserted at 2 (both branches of the repo-flag split), spelled out rather than '>= 1': one branch
  # silently losing the field is a rule that is OFF for the spelling that lost it, which is precisely
  # how rule 7c was off for `gh pr merge N --repo owner/x` for a week.
  if [ "${closes_query:-0}" -ne 2 ]; then
    bad "closes declaration — the merge floor's own 'gh pr view --json' list requests
      closingIssuesReferences in ${closes_query} of its 2 branches. A branch without it hands rule 7d a
      payload with no field, which fails CLOSED and wedges the gate; a rule that asks for nothing
      compares nothing."
  else
    ok "closes declaration — both branches of the merge floor's PR read request closingIssuesReferences"
  fi

  # ── arm 3 · the producer is told to write it, in the shape the consumer parses ──
  if [ "${closes_taught:-0}" -ne 1 ]; then
    bad "closes declaration — agents/quality-assurance.md carries the verdict-template 'closes:' line
      ${closes_taught} time(s), not exactly 1. Nothing else in this harness tells the gate to write it,
      so without it rule 7d denies every merge that closes an Issue and the deny is the only place the
      contract is stated."
  else
    ok "closes declaration — the gate's own brief teaches the line the merge floor parses"
  fi

  # ── arm 4 · both limits are stated wherever the rule is ──
  # The rule is a REFUSAL with two holes, and a refusal whose holes are documented in only one of the
  # places that describe it is one somebody will read as complete coverage. Three surfaces: the
  # mechanism, the brief that acts on it, and the universal preload every persona carries.
  closes_limit_missing=""
  closes_limit_checked=0
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    [ -r "$ROOT/$f" ] || { closes_limit_missing="$closes_limit_missing
    $f — unreadable"; continue; }
    closes_limit_checked=$((closes_limit_checked + 1))
    n="$(grep -c -i -F 'PR-body-derived' "$ROOT/$f" || true)"
    [ "${n:-0}" -eq 1 ] || closes_limit_missing="$closes_limit_missing
    $f — names the body-derived blind spot ${n} time(s), not exactly 1"
  done <<'CLOSES_LIMIT_HOLDERS'
hooks/scripts/permission-guard.sh
agents/quality-assurance.md
skills/harness-engineering/SKILL.md
CLOSES_LIMIT_HOLDERS

  if [ "$closes_limit_checked" -lt 3 ]; then
    bad "closes declaration — only $closes_limit_checked of 3 limit-holders were readable, so the limit
      was not asserted anywhere:$closes_limit_missing"
  elif [ -n "$closes_limit_missing" ]; then
    bad "closes declaration — the rule's measured blind spot is not stated wherever the rule
      is:$closes_limit_missing
      Measured 2026-08-30: a PR whose keyword lived only in a commit message returned an EMPTY
      closingIssuesReferences, so the refusal cannot see that surface — the one that cannot be edited
      afterwards, since amending needs a force-push the floor denies. A refusal presented as complete
      coverage is worse than one that names its hole."
  else
    ok "closes declaration — the body-derived blind spot is named in the guard, the gate's brief and the preload"
  fi

  # ── arm 5 · the RESIDUE is stated wherever either mechanism is described ──
  # THIS ARM EXISTS BECAUSE THE FIRST ROUND OF #363 PUBLISHED THE OPPOSITE, IN FOUR PLACES AT ONCE:
  # that `closure-artifact-guard.sh`'s `Stop` arm covers rule 7d's two blind spots. It does not. That
  # arm's predicate is an Issue that DECLARES an `invocable:` line, and the Issue rule 7d was built
  # from declares none — re-derived at head:
  #
  #     gh issue view 355 --json body --jq '[.body|split("\n")[]|select(test("^invocable"))]'  ->  []
  #
  # So it could not have fired on that Issue by ANY route. It covers the ROUTE, for a DIFFERENT
  # obligation. An UNDECLARED Issue closed by a browser merge or by a commit-message keyword is caught
  # by nothing at all — and a residue published as covered is strictly worse than one published as
  # open, because it is the sentence a gatekeeper would rely on when deciding the hole is somebody
  # else's problem. Six holders, because six files describe one or both mechanisms and the correction
  # is worthless in five of them.
  closes_residue_missing=""
  closes_residue_checked=0
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if [ ! -r "$ROOT/$f" ]; then
      closes_residue_missing="$closes_residue_missing
    $f — unreadable"
      continue
    fi
    closes_residue_checked=$((closes_residue_checked + 1))
    n="$(grep -c -i -F 'caught by nothing' "$ROOT/$f" || true)"
    [ "${n:-0}" -eq 1 ] || closes_residue_missing="$closes_residue_missing
    $f — states the uncovered residue ${n} time(s), not exactly 1"
  done <<'CLOSES_RESIDUE_HOLDERS'
README.md
agents/quality-assurance.md
skills/harness-engineering/SKILL.md
docs/blueprint-registry.md
docs/adr/0004-controls-and-enforcement.md
hooks/scripts/closure-artifact-guard.sh
CLOSES_RESIDUE_HOLDERS

  if [ "$closes_residue_checked" -lt 6 ]; then
    bad "closes declaration — only $closes_residue_checked of 6 residue-holders were readable, so the
      claim was not asserted anywhere:$closes_residue_missing"
  elif [ -n "$closes_residue_missing" ]; then
    bad "closes declaration — a surface describing the merge refusal or the closure detector does not
      state that their residues do NOT cover each other:$closes_residue_missing
      An undeclared Issue closed by a browser merge or a commit-message keyword is caught by NOTHING.
      Publishing either mechanism as covering the other's hole is worse than publishing the hole."
  else
    ok "closes declaration — all 6 surfaces state the residue neither mechanism covers"
  fi

fi

# ---------------------------------------------------------------------------------------------------
# THE RETIRED-CLAUSE REGISTRY — a correction needs the false claim's ABSENCE asserted, not only its
# replacement's PRESENCE (#363, #365).
#
# THIS BLOCK REPLACES TWO NEAR-IDENTICAL ARMS AND EXISTS BECAUSE OF A MEASURED FAILURE OF THE OTHER
# SHAPE. The `closes declaration` arm above asserts the correction is PRESENT — it counts a needle in a
# holder list and passes the moment the corrected sentence exists somewhere in each file. On this very
# diff it passed while the FALSE claim stood twenty-nine lines above its own correction, in the section
# headed "What it does not reach", which is exactly where a reader goes to learn the holes. **Presence
# and absence are different assertions about the same fact, and a presence check cannot express an
# absence.**
#
# WHY THE ABSENCE HALF IS NOT FOLDED INTO THAT ARM, WHICH IS A JUDGEMENT RATHER THAN A CONVENIENCE.
# That arm's domain is a DECLARED HOLDER LIST — six files that must each carry a sentence. This one's
# domain is the WHOLE TREE — no file may carry a retired clause unstruck, including files nobody
# thought to list. Two predicates over two domains sharing one verdict is the shape this file's own
# header forbids: an arm that shares a verdict can DISAPPEAR rather than fail, and no total moves to
# say so. So the halves stay apart, and this half is a REGISTRY rather than one arm per clause —
# adding the next retired clause is one line here instead of forty lines of near-duplicate.
#
# THE GENERALISABLE FINDING, WHICH IS WHY THE REGISTRY IS KEYED ON THE CLAIM AND NOT ON A HEADING:
# **a strike lands where a rule is STATED and survives where it is CITED, paraphrased, or used as a
# premise for something else.** Sweeping for the struck sentence finds the places already fixed. Every
# entry below was found that way — three of the six instances across these two clauses were in files
# the same diff was already editing.
#
# THE PREDICATE ADMITS TWO FORMS AND NOTHING ELSE: the line carries a `~~` strike, or it quotes the
# clause inside `*"` as a DISCUSSION — which the documentation standard's own citation rule warns a
# grep cannot distinguish from an assertion. Anything else is the clause asserted.
#
# WHAT IT CANNOT DO, SAID BEFORE THE FIRST GREEN. It reads strings. It cannot tell whether a
# replacement sentence is TRUE, cannot see a paraphrase that shares no vocabulary with the retired
# clause, and cannot judge whether a `*"` quotation is really a discussion rather than an assertion
# dressed as one. It catches the clause surviving VERBATIM, which is how all six instances survived.
#
# THIS FILE IS EXCLUDED FROM ITS OWN SCAN, and the exclusion is not a convenience: the registry has to
# NAME each clause to search for it, so a scan including this file matches its own needle list and
# reddens on a clean tree. Found by running it. The exclusion is by FILENAME rather than by directory,
# so the carrier and every other hook stay in scope — dropping `$ROOT/hooks` instead would have
# silently un-scanned `closure-artifact-guard.sh`, one of the files this exists because of.
#
# `powers/` IS EXCLUDED because it is GENERATED from `skills/` and gated by regeneration-and-diff:
# asserting it here would report one authored defect twice, and would redden on a stale export for a
# reason this block does not own.
#
# EACH CLAUSE EMITS ITS OWN VERDICT, per this file's chaining rule, and each repeats its own vacuity
# guard rather than borrowing the neighbour's.
while IFS='|' read -r retired_clause retired_why; do
  [ -z "$retired_clause" ] && continue
  retired_lines="$(grep -rn "$retired_clause" \
    "$ROOT/README.md" "$ROOT/docs" "$ROOT/hooks" "$ROOT/agents" "$ROOT/skills" "$ROOT/commands" 2>/dev/null \
    | grep -v 'inventory-counts\.test\.sh:' || true)"
  retired_live="$(printf '%s\n' "$retired_lines" | grep . | grep -v '~~' | grep -v '\*"' || true)"
  retired_total="$(printf '%s\n' "$retired_lines" | grep -c . || true)"

  if [ "${retired_total:-0}" -eq 0 ]; then
    bad "retired clause — '$retired_clause' was found NOWHERE, so this assertion compared nothing.
      Either every occurrence was deleted rather than struck — which the strike-not-delete convention
      forbids for a sentence someone acted on — or the wording moved and this entry is now vacuous,
      which is the failure mode this registry exists to catch, one level up."
  elif [ -n "$retired_live" ]; then
    bad "retired clause — '$retired_clause' still stands as a LIVE assertion:
$retired_live
      $retired_why
      Every occurrence must be inside a '~~' strike or quoted inside '*\"' as a discussion. A strike
      lands where a rule is STATED and survives where it is CITED or used as a premise."
  else
    ok "retired clause — all $retired_total occurrences of '$retired_clause' are struck or quoted"
  fi
done <<'RETIRED_CLAUSES'
only refusal surface that exists|Rule 7d (#363) is a second refusal surface, reaching the closing-keyword route one step upstream at the merge.
joins the active iteration at|No Issue is filed with a milestone, for any type (#365; ADR-0002's twenty-seventh amendment, held by permission-guard.sh rule 10).
covers that residue|The Stop arm's predicate is a DECLARED invocable promise, and the Issue rule 7d was built from declares none — so it covers the ROUTE, for a DIFFERENT obligation, and patches none of rule 7d's holes.
RETIRED_CLAUSES

# ══════════════════════════════════════════════════════════════════════════════════════════════════
# THE ITERATION RETROSPECTIVE RITE, AND EVERY LIMIT IT SHIPS WITH (#355).
#
# WHY THIS EXISTS. `/autonomy-on` promised "the closing ceremonies run against the exhausted iteration"
# from #326 and named nothing — measured on the commit this slice forked from, `git grep -l retrospect
# 5cfea0b -- commands skills agents` matched two files that MENTION the word and
# `git cat-file -e 5cfea0b:commands/retrospective.md` exited 128. A promise with no object survived a
# month because it reads like a description of something that already runs. #355 built the object.
#
# WHAT THESE ARMS ASSERT AND WHAT THEY CANNOT. They assert the rite's rules are WRITTEN, in the files
# that execute them. THEY CANNOT OBSERVE THAT A RITE RAN, that it ran over the right iteration, or that
# it ran with the personas it should have. Nothing in hooks/scripts/ reads the queue at all — every
# `gh issue` call there is a write path — so no layer in this harness can see a snapshot go empty.
# Same claim, same words, as the #326 and #339 arms above: PRESENCE OF A RULE. That is the whole of it.
#
# WHY THE LIMIT NEEDLES ARE HERE AT ALL, WHICH LOOKS LIKE GATING A DISCLAIMER AND IS THE LOAD-BEARING
# HALF. This rite has no enforcement anywhere: no hook fires it, no layer counts its findings, and its
# consult set is a LOWER BOUND rather than a set. A reader who finds it in a directory full of
# mechanisms will read it as one unless the file says otherwise — and a disclaimer later trimmed as
# verbose leaves a rule that READS as enforced, this repo's own named failure shape. So the
# lower-bound clause, the not-a-gate clause and the nothing-fires-this clause are needles.
#
# EACH NEEDLE IS ONE CLAUSE, AND THE FAILURE MESSAGE NAMES WHICH. The trap this suite has now paid for
# twice is a needle that covers one clause of a two-clause rule: it reddens for the half nobody would
# get wrong and stays green through the half that matters. Every needle below was verified with
# `grep -c -F` against its target BEFORE being written here (all returned 1 — a needle written across a
# line wrap matches nothing and reads exactly like absence), and each was then deleted on its own and
# the suite re-run.
RITE_CMD="$ROOT/commands/retrospective.md"
RITE_DRAIN="$ROOT/commands/autonomy-on.md"
RITE_GATE="$ROOT/agents/quality-assurance.md"
RITE_PRELOAD="$ROOT/skills/harness-engineering/SKILL.md"

# ── 1 · the rite carries its trigger, its mechanism, its artifact shape and all four of its limits ──
rite_missing=""
if [ ! -r "$RITE_CMD" ]; then
  bad "retrospective rite — commands/retrospective.md is not readable, so NOTHING about the rite was
      asserted. The drain's terminal condition points at this file; without it the closing ceremony is
      a promise again, which is the state #355 was filed to end."
else
  for rite_needle in \
    "The TRIGGER is the entry snapshot's exhaustion." \
    'Isolated speculation is still speculation.' \
    'the isolation would survive the dispatch and die at the write.' \
    'denies `product-lead`, `content-writer` and' \
    '**At most TWO findings per persona, the persona choosing which two.**' \
    'A rule that is checkable by reading and not by running is the honest maximum here' \
    'They still displace the product work there, by rule (#339)' \
    '**And the whole set is a LOWER BOUND, never the set.**' \
    '- **Nothing fires this.** There is no hook.' \
    '**A defect that lived between two contexts is invisible to this rite by construction.**' \
    '## The sprint review half is NOT built, and this is where that is recorded'
  do
    grep -qF -- "$rite_needle" "$RITE_CMD" || rite_missing="$rite_missing
    missing: \"$rite_needle\""
  done
  if [ -n "$rite_missing" ]; then
    bad "retrospective rite — a load-bearing clause left commands/retrospective.md:$rite_missing
      Each needle is ONE clause and answers for itself:
        TRIGGER          — the snapshot fires it, the iteration scopes it, the owner still closes it.
                           Collapsing the three is what makes the rite either never fire or fire on a
                           half-worked iteration.
        SPECULATION      — the reason the rite is worth running: a consulted persona is a fresh context,
                           so isolation without its own evidence relocates the bias instead of removing it.
        DIE AT THE WRITE — why the artifact is one file PER persona. A shared file puts every earlier
                           answer in the next persona's context; isolation would survive the dispatch
                           and die at the write.
        DENIES           — why it is a file and not a comment: rule 5e denies three of the seven any
                           public surface, so a comment artifact would have to be aggregated.
        AT MOST TWO      — the volume cap.
        HONEST MAXIMUM   — and the admission that the cap is checkable by reading and by nothing else.
                           These two are separate clauses on purpose; the cap alone reads as enforced.
        DISPLACE         — the amplification: a retrospective finding is \`loop\` and is ordered ahead
                           of every product item (#339), so it displaces product work rather than
                           queueing behind it. RE-AUTHORED 2026-08-30 (#365): the old needle read
                           'they displace it, by rule, in the very next', which was written when the
                           findings landed in the iteration the rite was CLOSING (#338). They now land
                           unassigned and displace at the NEXT planning. The displacement did not go
                           away — only its timing moved — so the needle moved with the sentence rather
                           than being dropped with the struck half.
        LOWER BOUND      — the consult set is derived from a recorder that exits silently on about a
                           dozen paths, so it is 'at least these ran' and never 'these ran'.
        NOTHING FIRES    — no hook, by instruction only.
        BETWEEN CONTEXTS — what the rite cannot catch, by construction.
        SWEEP NOT BUILT  — the review half is deferred and says so where the rite is defined, so the
                           promise is not discovered unbuilt a second time.
      If a clause was deliberately reworded, move its needle here in the same commit."
  else
    ok "retrospective rite — the rite states its trigger, why the evidence travels with the question, why the artifact is one file per persona, its cap, its amplification cost and all four of its limits"
  fi
fi

# ── 2 · the drain names the object, on the right condition, without over-claiming the plural ──
rite_drain_missing=""
if [ ! -r "$RITE_DRAIN" ]; then
  bad "retrospective rite — commands/autonomy-on.md is not readable; the pointer from the file that
      EXECUTES the drain to the rite it fires cannot be checked."
else
  for rite_drain_needle in \
    '### On exhaustion, run `/retrospective` — the closing ceremony now has an object (#355)' \
    '**On the FIRST stop condition only**' \
    '**HALF the promise now has an object and half still does not.**'
  do
    grep -qF -- "$rite_drain_needle" "$RITE_DRAIN" || rite_drain_missing="$rite_drain_missing
    missing: \"$rite_drain_needle\""
  done
  if [ -n "$rite_drain_missing" ]; then
    bad "retrospective rite — the drain no longer routes to the rite correctly:$rite_drain_missing
      Three separate clauses. The HEADING is the pointer itself. FIRST STOP CONDITION scopes it to
      snapshot exhaustion and away from the other two stops — a rite fired on a boundary event or an
      owner interrupt reports on an iteration nobody finished. HALF THE PROMISE is what stops
      'the closing ceremonies' being read as plural-and-satisfied while the sweep half is unbuilt."
  else
    ok "retrospective rite — autonomy-on names /retrospective, scopes it to snapshot exhaustion alone, and says which half of its own plural is still owed"
  fi
fi

# ── 3 · the gatekeeper's Write narrowing — TWO clauses, TWO verdicts, because they fail differently ──
#
# The narrowing itself and the test that keeps it narrow are not one rule. Losing the first makes the
# gate's brief contradict the rite (a persona instructed to write a file by one document and told it is
# a defect by another). Losing the second turns a scoped exception into an open one, which is the
# direction that erodes. One needle covering both would redden for whichever went first and could never
# say which mattered, so they are two `if` blocks with two verdicts.
if [ ! -r "$RITE_GATE" ]; then
  bad "retrospective rite — agents/quality-assurance.md is not readable; the Write narrowing cannot be
      checked in either direction."
elif grep -qF -- '**One narrowing, and it is not a review dispatch (#355).**' "$RITE_GATE"; then
  ok "retrospective rite — the gatekeeper's brief carries the Write narrowing, so it does not contradict the rite it is asked to write into"
else
  bad "retrospective rite — the gatekeeper's brief lost the Write narrowing. Its standing rule is that a
      Write to any repo path is a defect in the review; the rite asks it for exactly one file. Without
      this clause the two documents disagree and the persona is right either way, which is worse than
      either rule alone."
fi

if [ ! -r "$RITE_GATE" ]; then
  bad "retrospective rite — agents/quality-assurance.md is not readable; the narrowing's own bound
      cannot be checked. Reported separately from the clause above on purpose: an unreadable file makes
      BOTH verdicts uncomputable, and borrowing the neighbour's guard is how an assertion disappears."
elif grep -qF -- 'The test that keeps it narrow is the dispatch, not the path' "$RITE_GATE"; then
  ok "retrospective rite — the narrowing is bounded by the DISPATCH rather than by a path, so it cannot be read as a general licence to write into the tree"
else
  bad "retrospective rite — the narrowing lost its bound. Scoped to a PATH it would license any write
      whose destination happened to look right; scoped to the DISPATCH it licenses nothing on a review.
      A conditional rule with no stated condition is an unconditional one."
fi

# ── 4 · the universal preload no longer says the ceremony is unbuilt, and does not say it is finished ──
rite_preload_missing=""
if [ ! -r "$RITE_PRELOAD" ]; then
  bad "retrospective rite — skills/harness-engineering/SKILL.md is not readable; the preload every
      persona carries cannot be checked against the rite that now exists."
else
  for rite_preload_needle in \
    '**Struck 2026-08-30 (#355), and it was wrong in two different ways.**' \
    'Read *"the closing ceremonies"* anywhere in this loop as' \
    '**And nothing FIRES the one that exists.**' \
    '**the rite is not engineered.**'
  do
    grep -qF -- "$rite_preload_needle" "$RITE_PRELOAD" || rite_preload_missing="$rite_preload_missing
    missing: \"$rite_preload_needle\""
  done
  if [ -n "$rite_preload_missing" ]; then
    bad "retrospective rite — the universal preload is out of step with the rite:$rite_preload_missing
      The STRIKE needle is the correction of a bullet that said the ceremonies were not mechanisms in
      that file and that no MCP server is reachable from a subagent — the first half is now false
      because the rite exists, the second because product-lead holds a browser (#356). The
      CEREMONIES-AS-ONE-BUILT-ONE-OWED needle is the other direction: this is the file every persona
      preloads, so a plural read as satisfied here is read as satisfied everywhere.
      The NOTHING-FIRES and NOT-ENGINEERED needles are a separate clause from both, added after the
      copy lens measured that ADR-0002's twenty-sixth amendment claimed the enforcement admission was
      in four surfaces and it was in three — present in the rite, the drain and registry row 0042, and
      ABSENT from this one. That is the surface where its absence costs most: a persona meets
      '/retrospective is the method half' here, always-on, and would learn the rite exists without
      learning that nothing fires it. A promise a persona believes is worse than one it never read."
  else
    ok "retrospective rite — the preload strikes the claim that the ceremonies are unbuilt, says which half is still owed, and admits that nothing fires the half that exists"
  fi
fi

# ── 5 · the copy lens's brief counts its OWN write exceptions correctly, and keeps the half that stands ──
#
# `product-lead` already held `Write` for the iteration sweep report (#356) and its brief called that
# "the one exception". The rite asks EVERY consulted persona to write, and rule 5e names this persona as
# one of the three that cannot comment instead — so after #355 there are TWO, and a brief that says
# "one" while carrying two teaches its reader to stop counting. Found by the copy lens, which noted that
# `agents/quality-assurance.md` was amended for exactly this and the identical clause one file over was
# not.
#
# TWO NEEDLES, TWO CLAUSES, AND THEY FAIL DIFFERENTLY — the reason this arm reports per needle rather
# than as one verdict. Losing the COUNT needle restores a false "one exception". Losing the WHAT-HAS-NOT-
# CHANGED needle drops the half that stands (this persona still never edits copy, and neither report file
# is copy) — which is the direction a strike is most likely to over-reach in, since the struck sentence
# was protecting something real.
RITE_COPY="$ROOT/agents/product-lead.md"
rite_copy_missing=""
if [ ! -r "$RITE_COPY" ]; then
  bad "retrospective rite — agents/product-lead.md is not readable; the copy lens's own write-exception
      count cannot be checked against the rite that adds the second one."
else
  for rite_copy_needle in \
    'there are TWO exceptions now, and a rule that says "one" while carrying two is the shape that teaches a' \
    '**What has NOT changed is the thing'
  do
    grep -qF -- "$rite_copy_needle" "$RITE_COPY" || rite_copy_missing="$rite_copy_missing
    missing: \"$rite_copy_needle\""
  done
  if [ -n "$rite_copy_missing" ]; then
    bad "retrospective rite — the copy lens's brief is out of step with its own grant:$rite_copy_missing
      TWO EXCEPTIONS is the count: the iteration sweep report (#356) and the retrospective section
      (#355). It cannot be a comment for this persona — permission-guard.sh rule 5e denies it
      \`gh issue comment\` and \`gh pr comment\` by name — so the file is not a preference.
      WHAT HAS NOT CHANGED is the half the struck sentence was protecting: it still never edits copy,
      and neither report file is copy. A strike that drops it widens the grant by accident."
  else
    ok "retrospective rite — product-lead's brief counts both of its write exceptions and keeps the never-edit-copy half the struck sentence protected"
  fi
fi

# ── 6 · the three briefs and the rite agree on WHERE the artifact goes ────────────────────────────
#
# The rite instructs a write to `docs/retrospective/<iteration>/`; two personas' briefs name that path
# in their own words. Three files, one path, hand-maintained — which is the arrangement this suite
# exists because it rots. A brief pointing one directory away produces a rite whose artifact is
# scattered and whose "did it run" test (`ls` the directory) answers wrong.
#
# WHAT THIS CANNOT HOLD: that any file is ever actually written there. It is a string agreement across
# three documents, nothing more, and it says so rather than being read as a check on the artifact.
rite_path='docs/retrospective/<iteration>/'
rite_path_missing=""
rite_path_checked=0
for rite_path_file in commands/retrospective.md agents/quality-assurance.md agents/product-lead.md; do
  if [ ! -r "$ROOT/$rite_path_file" ]; then
    rite_path_missing="$rite_path_missing
    $rite_path_file — not readable"
    continue
  fi
  rite_path_checked=$((rite_path_checked + 1))
  grep -qF -- "$rite_path" "$ROOT/$rite_path_file" || rite_path_missing="$rite_path_missing
    $rite_path_file — does not name $rite_path"
done
if [ "$rite_path_checked" -lt 3 ]; then
  bad "retrospective rite — only $rite_path_checked of 3 artifact-path holders were readable, so the
      agreement was not asserted:$rite_path_missing"
elif [ -n "$rite_path_missing" ]; then
  bad "retrospective rite — the rite and the briefs disagree about where the artifact goes:$rite_path_missing
      One path, three hand-maintained documents. A brief pointing one directory away scatters the
      artifact and breaks the only 'did the rite run' test there is, which is listing that directory."
else
  ok "retrospective rite — the rite and both writing briefs name the same artifact directory (string agreement only; nothing here observes a file being written)"
fi

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
