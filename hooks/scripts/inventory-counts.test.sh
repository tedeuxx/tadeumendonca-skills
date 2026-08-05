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
#     `harness-reviewer` in one slice, the count held at five, and every assertion in this file stayed
#     green through it. The "roster's MEMBERSHIP" block below now checks WHICH personas are named, not
#     just how many exist. It is the only inventory here with that property — the skill and hook
#     inventories are still counts plus a name list, and nothing checks membership of a family.
#   - CLAUDE.md ALSO publishes "18 subagents" enabled and "26 defined". Those are counts of the ROSTER
#     as ADR-0002 defines it in the consuming repo — not of this tree — so nothing here can derive
#     them and nothing here asserts them. The per-directory skill counts are checked in both files;
#     the persona count is checked only where it describes `agents/`. Said explicitly because "the
#     counts are pinned" would otherwise be read as covering those two.
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
# THE FAMILY LIST IS DERIVED, NOT ENUMERATED. It used to be a literal list here, and when a family was
# emptied and its directory removed, this loop kept asserting `<name> (0)` against two documents that
# had correctly stopped mentioning it — a red suite reporting the docs were wrong when the suite was.
# An enumeration inside the file written to catch stale enumerations; deriving it also means a NEW
# family is asserted from the moment it exists rather than from whenever someone remembers this line.
total=0
for path in "$ROOT"/commands/*/; do
  dir=$(basename "$path")
  n=$(find "$ROOT/commands/$dir" -name '*.md' -type f | wc -l | tr -d ' ')
  total=$((total + n))
  expect_in "$README" "$dir ($n)" "commands/$dir"
  expect_in "$CLAUDE" "$dir/ ($n)" "commands/$dir"

  # The HEADING is not the inventory — the TABLE UNDER IT is what a reader actually reads.
  #
  # This assertion exists because the gap it closes shipped. Adding a skill reddened the heading
  # above, someone bumped "(8)" to "(9)", and the suite went green with the table below it still
  # listing eight rows. The skill was published and undiscoverable in the one document a reader
  # opens to find out what exists — and the file's own header already booked this hole in its own
  # words: "It asserts the numbers, never the prose around them."
  #
  # Row-counted across the whole file rather than parsed per-section, deliberately: every skill
  # appears exactly once as a table row, so a global count needs no section-boundary logic, and
  # boundary parsing is a thing to get wrong for no gain.
  rows=$(grep -c "^| \`/$dir/" "$CLAUDE" || true)
  if [ "$rows" = "$n" ]; then
    ok "commands/$dir — CLAUDE.md table lists all $n"
  else
    bad "commands/$dir — CLAUDE.md heading says $n, the table under it lists $rows; a skill is published and unlisted"
  fi
done

expect_in "$README" "$total skills + autonomy-on" "commands/ total"

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
# Issue — both are things the owner invokes directly, neither belongs under a namespace).
#
# THE ASSERTION IS NOT WEAKER FOR HAVING BEEN BUMPED, and that is the whole reason it is a pinned
# literal rather than a `-ge`. It exists to catch the ACCIDENTAL root command — a skill dropped one
# directory too high, where nothing in the docs enumerates it and no reader ever finds it. A
# deliberate addition costs one line here and gets the docs updated in the same commit; an accidental
# one goes red. A `-ge 1` would have caught neither.
root_cmds=$(find "$ROOT/commands" -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')
if [ "$root_cmds" -eq 2 ]; then
  ok "commands/ root — exactly two un-namespaced commands (autonomy-on, new-issue), as the docs enumerate"
else
  bad "commands/ root — $root_cmds un-namespaced commands; the docs enumerate two (autonomy-on, new-issue)"
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
# per-directory skill counts grew a table-row assertion above.
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
for doc in "$README" "$CLAUDE" "$ROOT/commands/principles/loop-engineering.md"; do
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

# THE COVERAGE ABOVE IS NOT TOTAL, and the exception is asserted rather than described so that it
# cannot be quietly forgotten.
#
# The command is still at `commands/principles/loop-engineering.md`, so the PATH `/principles/loop-
# engineering` is published in CLAUDE.md's and PRINCIPLES.md's command reference — a table cell that
# names the practice `Harness Engineering` while pointing at a command named after the term that
# replaced. The check above cannot see it: it greps the title-case, spaced form, and the slug does
# not match.
#
# Left deliberately. That path is a public invocation surface and this repo's SemVer contract makes a
# renamed command a MAJOR bump; shipping one under a `docs:` subject is a worse defect than the
# mismatch. The rename belongs in its own release.
#
# Asserted POSITIVELY — the slug must still be there — so that the day the rename happens this goes
# red and drags this note out with it. A known gap that fails when it closes is bookkeeping; one that
# stays silent is exactly how the retired term survived the first propagation.
if [ -f "$ROOT/commands/principles/loop-engineering.md" ]; then
  ok "vocabulary — the slug exception is still in place, as recorded (see the note above)"
else
  bad "vocabulary — the command was renamed: retire this assertion, this note, and the four-doc list above, and confirm the MAJOR bump"
fi

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
lead_files=$(find "$ROOT/agents" -maxdepth 1 -name '*-lead.md' -type f | wc -l | tr -d ' ')
case "$lead_files" in
  1) lead_word=one ;;   2) lead_word=two ;;   3) lead_word=three ;;
  4) lead_word=four ;;  5) lead_word=five ;;  6) lead_word=six ;;
  7) lead_word=seven ;; 8) lead_word=eight ;; 9) lead_word=nine ;;
  *) lead_word="$lead_files" ;;
esac

# SCOPE IS INSTRUCTIONS, NOT RECORDS, and that cut is the whole reason this is not a cry-wolf regex.
# `agents/**` and `commands/**` are read by an agent as current fact, and `hooks/scripts/*.sh`
# comments state the rule the code beside them enforces — all three must be TRUE. `docs/**` is
# excluded on purpose: it narrates how the roster got here, and a check that reddens on "the roster
# was three leads until 2026-08-04" would force a record to be falsified to go green, which is worse
# than the gap it closes. `*.test.sh` is excluded because a suite's fixtures are deliberately wrong
# strings — including this file, whose own comments describe the phrasing it hunts.
lead_scan_files=$(
  find "$ROOT/agents" "$ROOT/commands" -name '*.md' -type f
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
    wildcard_shells="$(printf '%s\n' "$allow_entries" \
      | grep -E "^Bash\(([^)]*[/[:space:]])?(bash|sh|zsh|ksh|dash)([[:space:]][^)]*)?:\*\)$" || true)"
    if [ -z "$wildcard_shells" ]; then
      ok "permission floor — no shell-interpreter allow entry ends in a wildcard"
    else
      bad "permission floor — a shell-interpreter entry ends in ':*', which permits an unbounded suffix: $wildcard_shells
      A path prefix is a STRING prefix, not a directory scope: '<allowed-prefix>/../../../tmp/x.sh' carries it.
      permission-guard.sh does not look inside a script file, so that suffix is arbitrary code with no decision from any layer.
      Use exact-match entries (no trailing ':*'), one per script."
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
# ── THE ANCHOR IS THE (SKILL, FAMILY) PAIR, AND MATCHING ON THE NAME ALONE WOULD BE WRONG ──────
# Measured before choosing: FOUR skill names exist in two families each — `coverage`, `dynamodb`,
# `cloudwatch-rum` and `environment-config`. A check keyed on the backticked name alone passes with one
# of a duplicate pair missing from the table, which is precisely the failure it exists to catch, so the
# name is not a key. The row shape the generator emits is
#     | `<skill>` | <description> | `<family>` | <wielded by> |
# and both directions below key on cells 1 and 3 together. `.*` spans cell 2 rather than splitting on
# `|`, because a description containing an escaped `\|` still contains the delimiter.
#
# ── THE ROW SHAPE SELECTS THE TABLE WITHOUT NAMING WHERE IT IS ─────────────────────────────────
# The reverse direction needs the set of rows, and the README holds a SECOND table whose first cell is
# also backticked (the hook-event matrix: `| \`UserPromptSubmit\` | … |`). Rather than parse section
# boundaries — a thing to get wrong for no gain, as the family loop's comment already argues — the shape
# below requires cells 1 AND 3 to each be a single backticked lowercase token. Measured on the current
# head that selects exactly 73 lines, the same number the generator emits, and none of the 14 hook-event
# rows. It also means a row surviving the deletion of an entire FAMILY directory is still caught, which
# a family-name allowlist would have missed.
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
skill_rows_re='^\| `[a-z0-9][a-z0-9-]*` \|.*\| `[a-z0-9][a-z0-9-]*` \|'

# DIRECTION 1 — every skill file has a row. Catches an ADDED skill nobody listed.
table_missing=""
skill_files=0
for path in "$ROOT"/commands/*/; do
  fam=$(basename "$path")
  for f in "$path"*.md; do
    [ -e "$f" ] || continue
    stem=$(basename "$f" .md)
    skill_files=$((skill_files + 1))
    grep -qE "^\| \`$stem\` \|.*\| \`$fam\` \|" "$README" && continue
    table_missing="$table_missing
    commands/$fam/$stem.md — no row in the README table"
  done
done

if [ "$skill_files" -eq 0 ]; then
  bad "README skill table — no skill files found under commands/; this assertion did NOT run"
elif [ -n "$table_missing" ]; then
  bad "README skill table — a skill is published and has no row in the table a forker reads:$table_missing
      The counts above can be green while this is wrong: fixing the number a count failure quotes does not add the row.
      Fix by re-running \`hooks/scripts/skills-table.py\` and replacing the table — not by hand-writing the row."
else
  ok "README skill table — all $skill_files skill files have a row, keyed on (skill, family)"
fi

# DIRECTION 2 — every row has a file. Catches a DELETED skill whose row stayed, which is the direction
# that goes stale silently: nothing about deleting a file makes anyone open the README, and no count
# assertion moves if the row is still there while the total is restated correctly elsewhere.
table_orphans=""
table_rows=0
while IFS= read -r row; do
  [ -z "$row" ] && continue
  table_rows=$((table_rows + 1))
  # SPLIT ON CELLS, NEVER ON A GREEDY `.*` — and this is a corrected defect, not a precaution. The first
  # version captured cell 3 with `^\| \`…\` \|.*\| \`([a-z0-9-]+)\` \|`, and `.*` being greedy walked
  # PAST the family cell to the LAST backticked token on the row, which is the *wielder*. Every row came
  # out as family `developer`, and the assertion reported 60-odd skills missing from a table that was
  # complete — a red naming the wrong thing, which is the failure mode a check is least likely to
  # survive being trusted through. Escaped pipes inside the description (`\|`) are neutralised first, so
  # the field split is on real cell boundaries only.
  r_skill=$(printf '%s' "$row" | sed 's/\\|/§/g' | awk -F'|' '{gsub(/[ `]/,"",$2); print $2}')
  r_fam=$(printf '%s' "$row" | sed 's/\\|/§/g' | awk -F'|' '{gsub(/[ `]/,"",$4); print $4}')
  [ -z "$r_skill" ] && continue
  [ -f "$ROOT/commands/$r_fam/$r_skill.md" ] && continue
  table_orphans="$table_orphans
    the table lists \`$r_skill\` in family \`$r_fam\` — commands/$r_fam/$r_skill.md does not exist"
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
# THE DEFECT: `security` was deleted from `agents/` and `harness-reviewer` was added in the same slice.
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

if [ "$roster_n" -lt 2 ]; then
  bad "roster membership — only $roster_n persona file(s) found under agents/; the assertions below would be trivial"
elif [ -z "$roster_retired_alt" ]; then
  bad "roster membership — NO retired persona could be derived from git history. On a shallow clone \`git log --diff-filter=D\` returns nothing and every absence check below passes vacuously. Restore \`fetch-depth: 0\` on the checkout in .github/workflows/docs-test.yml"
else
  ok "roster membership — $roster_n live personas, $(printf '%s\n' "$roster_retired" | grep -c . || true) retired, both derived"

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
  # ("one fullstack developer", "a harness-reviewer") rather than in the backticked form this pattern
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
  # `commands/workflow/code-review.md` naming the two gates, `docs/adr/0008` naming the two it is about.
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

  if [ -z "$roster_stale" ]; then
    ok "roster membership — no line enumerating the roster names a persona without a file in agents/"
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
    done <<< "$FLOOR_CLAIM_FILES"

    if [ -z "$uncovered" ]; then
      ok "gate coverage — every file the floor-claim scan reads is matched by docs-test.yml's paths: filter"
    else
      bad "gate coverage — these files are SCANNED by this suite but cannot START its workflow:$uncovered
      A PR touching only such a file can introduce the defect this suite exists to catch and never run it.
      Add the path to .github/workflows/docs-test.yml's paths: filter — do not narrow the scan set to match."
    fi
  fi
fi

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
