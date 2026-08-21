#!/usr/bin/env bash
# Asserts that the committed Kiro Power export under `powers/tadeumendonca-skills/` is exactly what
# `hooks/scripts/kiro-power-build.py` produces from `skills/` — and that it is a valid Kiro package.
#
# WHY THIS IS A GATE AND NOT A CONVENTION. The export is GENERATED output that is also COMMITTED, and
# it has to be: Kiro installs a Power by cloning the repo and reading files, so there is no build step
# it could run and an uncommitted artifact is one nobody can install. Committing generated output buys
# exactly one liability — the copy and the source drifting apart — and it is invisible from both sides.
# A skill edited at the source still reads correctly in `skills/`; the stale copy in `powers/` still
# reads correctly on its own. Nothing about either file says the other exists. That is precisely the
# failure this repository names as its signature one, and the only instrument that finds it is a
# regeneration diff.
#
# THE DIFF IS THE CHECK, and it is bidirectional by construction — `diff -r` reddens on a file added to
# either tree, removed from either tree, renamed on either side, or edited on either side. The
# assertions after it are not a second opinion on the same thing: they check properties the diff cannot
# see, because a generator faithfully producing an INVALID package passes its own diff every time.
#
# ── THE CHAINING RULE, inherited from `inventory-counts.test.sh` and restated because it is easy to
# lose when copying a suite ──────────────────────────────────────────────────────────────────────────
# Chain with `elif` ONLY where the failing condition makes the next verdict genuinely uncomputable (a
# GUARD). Never chain two ASSERTIONS because they share a subject: the first one's `bad` returns, the
# second emits neither PASS nor FAIL, and the totals stay plausible while an assertion has silently
# DISAPPEARED. Every assertion below gets its own `if` and repeats its own vacuity guard.
#
# Run: bash hooks/scripts/kiro-power.test.sh

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
POWER="$ROOT/powers/tadeumendonca-skills"
GENERATOR="$ROOT/hooks/scripts/kiro-power-build.py"
MANIFEST="$POWER/plugin.json"
CLAUDE_MANIFEST="$ROOT/.claude-plugin/plugin.json"

# The canonical Agent Plugins 1.0.0 manifest schema id, and the `name` pattern that schema declares.
# Both are written out literally rather than fetched: a gate that reaches the network is a gate that
# goes red when the network does, and this suite runs on every PR touching the library.
SCHEMA_URL="https://agent-plugins.org/schemas/1.0.0/plugin.schema.json"
NAME_RE='^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$'

pass=0
fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }

# --- the package exists at all ----------------------------------------------------------------
# A GUARD, not an assertion: nothing below can be judged against a package that is not there, and a
# suite that reports twelve vacuous passes over a missing directory is worse than one that stops.
if [ ! -f "$MANIFEST" ]; then
  bad "package root — $MANIFEST does not exist; run: python3 hooks/scripts/kiro-power-build.py"
  printf '\n%s passed, %s failed\n' "$pass" "$fail"
  exit 1
fi
ok "package root — powers/tadeumendonca-skills/plugin.json exists"

# --- the regeneration diff — the load-bearing assertion ----------------------------------------
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
gen_out="$(python3 "$GENERATOR" "$tmp" 2>&1)"
gen_rc=$?
if [ "$gen_rc" -ne 0 ]; then
  bad "regeneration — the generator exited $gen_rc: $gen_out"
elif ! diff_out="$(diff -r "$tmp" "$POWER" 2>&1)"; then
  bad "regeneration diff — the committed export is NOT what the generator produces from skills/.
Regenerate with: python3 hooks/scripts/kiro-power-build.py
$diff_out"
else
  ok "regeneration diff — the committed export matches the generator's output byte for byte"
fi

# --- manifest: the schema id -------------------------------------------------------------------
# Its own `if`. A wrong `$schema` is not a formatting slip: it is the one field that tells Kiro which
# spec version to read the rest of the file as.
if grep -qF "\"\$schema\": \"$SCHEMA_URL\"" "$MANIFEST"; then
  ok "manifest \$schema — names the Agent Plugins 1.0.0 manifest schema"
else
  bad "manifest \$schema — does not name $SCHEMA_URL"
fi

# --- manifest: the name, against the schema's own pattern --------------------------------------
power_name="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("name",""))' "$MANIFEST" 2>/dev/null)"
if [ -z "$power_name" ]; then
  bad "manifest name — absent or unparseable; \`name\` is one of only two REQUIRED keys in the schema"
elif ! printf '%s' "$power_name" | grep -qE "$NAME_RE"; then
  bad "manifest name — '$power_name' does not match the schema's pattern $NAME_RE"
else
  ok "manifest name — '$power_name' matches the schema's pattern"
fi

# --- manifest: the version tracks VERSION ------------------------------------------------------
# This is the assertion that catches the release wiring, not the generator. `.bumpversion.toml` must
# list this manifest, or a release bumps VERSION and `.claude-plugin/plugin.json` and leaves the Kiro
# package advertising a version that no longer exists — a stale number in the field an installer shows
# the user, with every other gate green.
version_file="$(tr -d ' \n' < "$ROOT/VERSION" 2>/dev/null)"
power_version="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("version",""))' "$MANIFEST" 2>/dev/null)"
if [ -z "$version_file" ] || [ -z "$power_version" ]; then
  bad "manifest version — could not read VERSION ('$version_file') or the manifest's version ('$power_version')"
elif [ "$version_file" != "$power_version" ]; then
  bad "manifest version — VERSION says $version_file, the Kiro manifest says $power_version"
else
  ok "manifest version — $power_version, in lockstep with VERSION"
fi

# --- manifest: no key the schema forbids -------------------------------------------------------
# The Agent Plugins schema declares `"additionalProperties": false`, so an extra key is not ignored —
# it makes the manifest invalid. The one this repo is most likely to leak is `skills`, since Claude
# Code's manifest carries an explicit `skills` array and the obvious wrong move is to copy the file.
allowed='$schema name version description author homepage repository license keywords extensions'
stray=""
while read -r key; do
  [ -z "$key" ] && continue
  case " $allowed " in
    *" $key "*) : ;;
    *) stray="$stray $key" ;;
  esac
done <<< "$(python3 -c 'import json,sys;[print(k) for k in json.load(open(sys.argv[1]))]' "$MANIFEST" 2>/dev/null)"
if [ -n "$stray" ]; then
  bad "manifest keys — the Agent Plugins schema sets additionalProperties:false and these are not in it:$stray"
else
  ok "manifest keys — every key is one the Agent Plugins 1.0.0 schema declares"
fi

# --- forward: every skill Claude Code declares is in the Power ---------------------------------
declared="$(python3 -c 'import json,sys;[print(p.rsplit("/",1)[-1]) for p in json.load(open(sys.argv[1]))["skills"]]' "$CLAUDE_MANIFEST" 2>/dev/null)"
if [ -z "$declared" ]; then
  bad "forward export — could not read the skills array out of .claude-plugin/plugin.json"
else
  missing=""
  while read -r n; do
    [ -z "$n" ] && continue
    [ -f "$POWER/skills/$n/SKILL.md" ] || missing="$missing $n"
  done <<< "$declared"
  if [ -n "$missing" ]; then
    bad "forward export — declared for Claude Code but absent from the Kiro Power:$missing"
  else
    ok "forward export — all $(printf '%s\n' "$declared" | wc -l | tr -d ' ') Claude-Code-declared skills are in the Power"
  fi
fi

# --- reverse: every skill in the Power traces back to a source skill ---------------------------
# The direction that catches an ADDITION — a skill hand-written straight into the export, which the
# forward check is blind to by construction and which would be a second source of truth on day one.
exported="$(find "$POWER/skills" -mindepth 2 -maxdepth 2 -name 'SKILL.md' -type f 2>/dev/null | sort)"
if [ -z "$exported" ]; then
  bad "reverse export — no SKILL.md found under powers/tadeumendonca-skills/skills/"
else
  orphan=""
  while read -r f; do
    [ -z "$f" ] && continue
    n="$(basename "$(dirname "$f")")"
    [ -f "$ROOT/skills/$n/SKILL.md" ] || orphan="$orphan $n"
  done <<< "$exported"
  if [ -n "$orphan" ]; then
    bad "reverse export — in the Kiro Power with no skills/<name>/SKILL.md behind it:$orphan"
  else
    ok "reverse export — all $(printf '%s\n' "$exported" | wc -l | tr -d ' ') exported skills trace to a source skill"
  fi
fi

# --- every exported skill satisfies Kiro's OWN frontmatter contract ----------------------------
# `name` AND `description`. Not one of the 13 SOURCE files carries `name` — Claude Code derives the
# identifier from the directory instead — so this is the property the generator ADDS, and the one a
# hand-copied tree would have got wrong on all thirteen at once.
if [ -z "$exported" ]; then
  bad "kiro frontmatter — no exported skills to check (see the reverse-export failure above)"
else
  badfront=""
  while read -r f; do
    [ -z "$f" ] && continue
    head -n 4 "$f" | grep -q '^name: ' || badfront="$badfront $(basename "$(dirname "$f")"):name"
    head -n 4 "$f" | grep -q '^description: ' || badfront="$badfront $(basename "$(dirname "$f")"):description"
  done <<< "$exported"
  if [ -n "$badfront" ]; then
    bad "kiro frontmatter — Kiro validates name+description; these are missing one:$badfront"
  else
    ok "kiro frontmatter — every exported SKILL.md declares both name and description"
  fi
fi

# --- no relative link survives into the export --------------------------------------------------
# A `](../../docs/adr/...)` link is correct in `skills/` and wrong everywhere the export goes: two
# levels too high in this repo, and pointing at nothing once Kiro has copied the file into
# `~/.kiro/powers/`. It fails SILENTLY — a dead link renders as a link — which is what makes it a gate
# rather than a review note.
if [ -z "$exported" ]; then
  bad "link rewriting — no exported skills to check (see the reverse-export failure above)"
else
  rel="$(grep -rlE '\]\(\.\.' "$POWER/skills" 2>/dev/null)"
  if [ -n "$rel" ]; then
    bad "link rewriting — a relative link survived into the export:
$rel"
  else
    ok "link rewriting — no relative link remains in any exported skill"
  fi
fi

# --- the export README cites no origin but this repository's own --------------------------------
# CONVERTS A COMMENT INTO A GATE. The generator carries a standing instruction to its next author not
# to reach for another external source to ground the "what this Power does not ship" paragraph — the
# claim has now been published wrong three times, each time by reaching. That instruction was PROSE,
# in the repository whose own test is *"if this guarantee failed right now, would something stop me,
# or only my memory?"* The answer was memory. This is the something.
#
# MEASURED AGAINST THE ACTUAL HISTORY RATHER THAN ASSUMED, which is what decided it was worth adding:
#   * at `ab6c5c7` (form 1) the README carried `https://kiro.dev/docs/powers/`   -> this goes RED
#   * at `2ccb402` (form 2) it carried `https://agent-plugins.org/schemas/...`   -> this goes RED
#   * at head it carries two URLs, both under this repository                    -> GREEN
# Two of the three published defects would have been stopped by one assertion nobody had to remember.
#
# WHAT IT DOES NOT CATCH, said plainly so nobody reads the green as more than it is: form 3 cited a
# CORRECT measurement of the wrong build and carried no URL at all. A URL is a proxy for reaching
# outward, not the act itself, so this narrows the class rather than closing it. The judgement — *is
# this source about the same object as the claim it is carrying?* — has no instrument and stays with
# the reviewer.
#
# IT IS DELIBERATELY STRICT. A future author with a legitimate external link must edit the generator's
# template AND this assertion, and argue for it in the MR. That friction is the feature: the three
# defects above were each one author deciding alone that one more source would help.
PKG_README="$POWER/README.md"
OWN_ORIGIN="https://github.com/tedeuxx/tadeumendonca-skills"
if [ ! -r "$PKG_README" ]; then
  bad "README origin — $PKG_README is unreadable; this assertion did NOT run"
else
  readme_urls="$(grep -oE 'https?://[^ )"<>]+' "$PKG_README" | sort -u)"
  if [ -z "$readme_urls" ]; then
    bad "README origin — the export README carries NO URL at all, not even the install URL a Kiro user has to paste; this assertion would pass vacuously"
  else
    foreign=""
    while IFS= read -r url; do
      [ -z "$url" ] && continue
      case "$url" in
        "$OWN_ORIGIN"*) ;;
        *) foreign="$foreign
    $url" ;;
      esac
    done <<< "$readme_urls"
    if [ -z "$foreign" ]; then
      ok "README origin — every URL in the export README is under this repository's own origin ($(printf '%s\n' "$readme_urls" | wc -l | tr -d ' ') URLs)"
    else
      bad "README origin — the export README cites an origin that is not this repository:$foreign
    This file's claims about what a Power can carry have been published wrong three times, each time by
    reaching for an external source that did not support them. Ground it on what this package CHOOSES to
    ship, or measure the installer of a named build and say which build. See the standing instruction in
    hooks/scripts/kiro-power-build.py."
    fi
  fi
fi

# --- the release wiring declares the Kiro manifest ----------------------------------------------
# Asserted against `.bumpversion.toml` and NOT merely against the version equality above, because the
# two fail at different moments. The equality goes red only AFTER a release has already shipped the
# wrong number; this goes red on the PR that forgets the wiring, which is the only place it is cheap.
if grep -qF 'powers/tadeumendonca-skills/plugin.json' "$ROOT/.bumpversion.toml"; then
  ok "release wiring — .bumpversion.toml bumps the Kiro manifest in lockstep"
else
  bad "release wiring — .bumpversion.toml does not list powers/tadeumendonca-skills/plugin.json; a release would leave the Kiro package on a stale version"
fi

# --- the generator refuses an output root whose `skills/` it did not write -----------------------
# THE ONLY RECURSIVE DELETE IN THIS SLICE, and it is driven by a caller-supplied path. `main()` takes
# the output root from `sys.argv[1]` and rebuilds `<root>/skills` from scratch, so invoking it as
# `python3 hooks/scripts/kiro-power-build.py .` from the repository root — the way every other script
# here is run — makes that path the SOURCE LIBRARY. Measured before the guard existed, in a disposable
# copy: 13 skills destroyed, one empty directory left, and the run THEN died reading a file it had
# just deleted. The destruction precedes the error, so nothing downstream can save it.
#
# WHY IT IS ASSERTED HERE RATHER THAN LEFT TO THE PERMISSION FLOOR. `permission-guard.sh` denies
# `rm -rf` by reading a command string. This is `python3 <a repo script> <a path>`, which it allows,
# and the deletion happens inside the process — a repo script routing around the mechanical control
# this repository's whole thesis rests on. A destructive script whose guard has no test is that thesis
# stated and not applied.
#
# THE ASSERTION RUNS AGAINST A DISPOSABLE MIRROR, NOT AGAINST `$ROOT`, and that is not fastidiousness.
# The generator resolves its own source tree from `__file__`, so the only way to make it point at a
# library is to give it one. Pointing it at the real repository would mean a test that DESTROYS the
# library on the exact run where it fails — the failure mode inverted, and by far the worst possible
# shape for a regression test to have.
mirror="$(mktemp -d)"
trap 'rm -rf "$tmp" "$mirror"' EXIT
mkdir -p "$mirror/hooks/scripts"
cp -R "$ROOT/skills" "$mirror/skills"
cp -R "$ROOT/.claude-plugin" "$mirror/.claude-plugin"
cp "$GENERATOR" "$mirror/hooks/scripts/kiro-power-build.py"
mirror_before="$(find "$mirror/skills" -name SKILL.md | wc -l | tr -d ' ')"
if [ "$mirror_before" -lt 1 ]; then
  bad "destructive-argument refusal — the disposable mirror holds no SKILL.md, so the generator would have nothing to destroy; this assertion did NOT run"
else
  refusal="$(python3 "$mirror/hooks/scripts/kiro-power-build.py" "$mirror" 2>&1)"
  refusal_rc=$?
  mirror_after="$(find "$mirror/skills" -name SKILL.md | wc -l | tr -d ' ')"
  if [ "$mirror_after" -ne "$mirror_before" ]; then
    bad "destructive-argument refusal — pointing the generator at a repository root DELETED source skills ($mirror_before -> $mirror_after). Restore the guard in kiro-power-build.py's safe_skills_out()."
  elif [ "$refusal_rc" -eq 0 ]; then
    bad "destructive-argument refusal — pointing the generator at a repository root exited 0 instead of refusing; it must fail loudly, not silently do something else: $refusal"
  else
    ok "destructive-argument refusal — an output root whose skills/ is the source library is refused, non-zero, with nothing deleted"
  fi
fi

# --- ...and the refusal does not block the workflow it protects ----------------------------------
# ITS OWN `if`, and it is not a restatement of the one above. A guard that refuses EVERYTHING passes
# the assertion above perfectly, and the only thing that would notice is a maintainer regenerating the
# committed export by hand — which no gate here does, since the regeneration diff at the top of this
# file always writes into a FRESH temporary directory and so never exercises the delete-then-rebuild
# path at all. The real maintenance invocation overwrites a directory that already has content in it.
# This asserts that case, against a COPY of the committed export so the repository is never written to.
regen="$(mktemp -d)"
trap 'rm -rf "$tmp" "$mirror" "$regen"' EXIT
cp -R "$POWER/." "$regen/"
if [ ! -f "$regen/plugin.json" ]; then
  bad "regeneration over prior output — the copy of the committed export is missing plugin.json; this assertion did NOT run"
else
  regen_out="$(python3 "$GENERATOR" "$regen" 2>&1)"
  regen_rc=$?
  if [ "$regen_rc" -ne 0 ]; then
    bad "regeneration over prior output — the generator REFUSED to rebuild its own committed export: $regen_out
    The safety guard is over-broad: it now blocks the one invocation a maintainer actually makes."
  elif ! regen_diff="$(diff -r "$regen" "$POWER" 2>&1)"; then
    bad "regeneration over prior output — rebuilding on top of the committed export did not reproduce it:
$regen_diff"
  else
    ok "regeneration over prior output — the generator rebuilds its own export in place and reproduces it exactly"
  fi
fi

# --- CI can actually start this gate -------------------------------------------------------------
# THE UNION-OF-WHAT-THE-SUITE-READS RULE, which this repo has now got wrong ten times (see
# `docs-test.yml`'s header for the enumeration). A PR that edits ONLY a file this suite reads must be
# able to start the workflow that runs it — otherwise the gate is green on exactly the change it
# exists to catch and never red afterwards.
#
# ── WHY THIS ASSERTION WAS WIDENED, AND WHAT WIDENING DID AND DID NOT BUY ─────────────────────────
# It shipped as a single hardcoded `grep -qF '"powers/**"'` against this workflow, and it PASSED on
# the PR that introduced the tenth occurrence — because the tree it added was read by a DIFFERENT
# suite (`inventory-counts`) in a DIFFERENT workflow (`docs-test.yml`), which the hardcoded form could
# not see. That is one real defect and it is fixed in `docs-test.yml`, not here.
#
# What is fixed HERE is the OTHER half, which nothing had looked at: the hardcoded form checked ONE of
# the seven paths this suite reads and said nothing about the other six. Three of them were genuinely
# uncovered — `VERSION`, `.bumpversion.toml` and `.claude-plugin/plugin.json` — so a PR deleting the
# Kiro entry from `.bumpversion.toml` could not start the suite whose release-wiring assertion exists
# to catch exactly that. The narrow form was green while the hole it was written for was open three
# times over.
#
# THE SET IS DERIVED FROM THIS FILE, NOT RESTATED IN IT. Restating it is the duplication that produced
# every previous occurrence: the scan set maintained in one place, the filter in another, nobody
# diffing them. `inventory-counts.test.sh` considered and REJECTED a self-grep for its own scan set,
# and the rejection was correct THERE and does not transfer here — its paths are interpolated
# (`$ROOT/commands/$r_fam/…`) and its real scan set is dynamic (`git ls-files`), so a self-grep would
# have been a heuristic wrong more often than right. This suite's paths are literal, and truncating at
# the first interpolation yields a PREFIX that is exactly what a `**` glob has to match anyway.
#
# WHAT THIS STILL DOES NOT CLOSE, stated so the eleventh occurrence is not a surprise: this checks
# THIS suite against ITS OWN workflow. The cross-suite direction — "some other suite also reads the
# tree I just added" — is not derivable by grep, because the suite most likely to read it derives its
# scan set from `git ls-files` and contains the literal string `powers` nowhere. That direction is
# covered structurally rather than by an assertion: `inventory-counts`'s scan set is every tracked
# `.md`/`.sh`/`.yml`/`.json`/`.py`, so any new tree holding one of those extensions reddens ITS
# gate-coverage arm without anyone telling it the tree exists. The residual is a new tree holding NONE
# of those extensions and read by a suite other than its own — which is not hypothetical: a `.toml`
# file is invisible to that scan set today, which is how `.bumpversion.toml` stayed uncovered.
#
# ONE-DIRECTION, deliberately, for the same reason `inventory-counts` gives: filter ⊅ read set is a
# hole; filter ⊃ read set is a workflow that occasionally runs with nothing to say.
HOOKS_WORKFLOW="$ROOT/.github/workflows/hooks-test.yml"
SELF="$ROOT/hooks/scripts/kiro-power.test.sh"
if [ ! -r "$HOOKS_WORKFLOW" ] || [ ! -r "$SELF" ]; then
  bad "gate coverage — $HOOKS_WORKFLOW or $SELF unreadable; this assertion did NOT run"
else
  wf_globs="$(sed -n '/^  *paths:/,/^[^ #]/p' "$HOOKS_WORKFLOW" | sed -nE 's/^ *- "(.*)"$/\1/p')"
  # Truncated at the first character a path literal cannot contain, so an interpolated path
  # contributes its literal prefix rather than dropping out of the set entirely.
  suite_reads="$(grep -oE '\$ROOT/[A-Za-z0-9_./-]*' "$SELF" | sed 's|^\$ROOT/||' | sort -u)"
  if [ -z "$wf_globs" ]; then
    bad "gate coverage — no paths: globs parsed from hooks-test.yml; the file changed shape and this assertion did NOT run"
  elif [ -z "$suite_reads" ]; then
    bad "gate coverage — the read set derived from this suite is EMPTY; this assertion would pass vacuously"
  else
    uncovered=""
    while IFS= read -r rel; do
      [ -z "$rel" ] && continue
      matched=""
      while IFS= read -r glob; do
        [ -z "$glob" ] && continue
        case "$glob" in
          */\*\*)
            # `skills/**` covers BOTH a read of a file under `skills/` AND a read of the directory
            # `skills` itself — reading a directory is reading its contents, and a PR that changes
            # anything in it starts the workflow either way. The second test was missing, and it
            # reported `skills` and `.claude-plugin` as uncovered when both are in the filter and
            # always were. That is the shape this assertion is least able to afford: a FALSE RED on
            # the arm written to catch false greens teaches the next reader to widen the filter (or
            # to narrow what the suite reads) to silence it, which is the defect, applied as a fix.
            prefix="${glob%\*\*}"
            [ "${rel#"$prefix"}" != "$rel" ] && matched=yes
            [ "$rel" = "${prefix%/}" ] && matched=yes
            ;;
          *)      case "$rel" in "$glob"|"$glob"/*) matched=yes ;; esac ;;
        esac
        [ -n "$matched" ] && break
      done <<< "$wf_globs"
      [ -z "$matched" ] && uncovered="$uncovered
    $rel"
    done <<< "$suite_reads"

    if [ -z "$uncovered" ]; then
      ok "gate coverage — every path this suite reads is matched by hooks-test.yml's paths: filter ($(printf '%s\n' "$suite_reads" | wc -l | tr -d ' ') paths)"
    else
      bad "gate coverage — these paths are READ by this suite but cannot START its workflow:$uncovered
      A PR touching only such a file can introduce the defect this suite exists to catch and never run it.
      Add the path to .github/workflows/hooks-test.yml's paths: filter — do not narrow what the suite reads."
    fi
  fi
fi

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
