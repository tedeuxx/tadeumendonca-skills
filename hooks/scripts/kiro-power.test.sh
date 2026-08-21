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

# --- the release wiring declares the Kiro manifest ----------------------------------------------
# Asserted against `.bumpversion.toml` and NOT merely against the version equality above, because the
# two fail at different moments. The equality goes red only AFTER a release has already shipped the
# wrong number; this goes red on the PR that forgets the wiring, which is the only place it is cheap.
if grep -qF 'powers/tadeumendonca-skills/plugin.json' "$ROOT/.bumpversion.toml"; then
  ok "release wiring — .bumpversion.toml bumps the Kiro manifest in lockstep"
else
  bad "release wiring — .bumpversion.toml does not list powers/tadeumendonca-skills/plugin.json; a release would leave the Kiro package on a stale version"
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
          */\*\*) [ "${rel#"${glob%\*\*}"}" != "$rel" ] && matched=yes ;;
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
