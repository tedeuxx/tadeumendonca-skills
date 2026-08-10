#!/usr/bin/env bash
# Asserts that every `skills:` identifier in `agents/*.md` resolves to a tracked file in `commands/`.
#
# WHY THIS EXISTS, and why it is CI rather than the runtime. A wrong identifier in a `skills:` list
# fails at **0 bytes of stderr**. The persona starts, the skill is simply not there, and nothing —
# not the transcript, not the exit code, not a log line without `--debug-file` — distinguishes a typo
# from a deliberate omission. Forever. That is the worst shape a defect can take in this harness: a
# capability silently absent, in a field whose whole purpose is to grant it.
#
# ADR-0008 asks which layer can carry a control and whether that layer can HOLD it. The runtime cannot:
# it has no way to report the failure. So the control sits here, where it can be evaluated, and the
# failure is a red build instead of a silence.
#
# WHAT `skills:` ACTUALLY DOES, because the assertions below only make sense against it. It is not a
# menu of skills the persona may reach for — it INJECTS each file's full body into the context before
# the persona's first turn. Three consequences the checks encode:
#   * there is NO DEDUPE, so two identifiers resolving to one file load it twice and bill it twice;
#   * SLASH FORMS DO NOT RESOLVE (`workflow/code-review` is not an identifier), and they fail silently;
#   * THERE IS NO GLOB SUPPORT, so `principles:*` is a literal that matches nothing, also silently.
# All three were measured rather than assumed (#172): `workflow:license`, bare `license` and
# `plugin:workflow:license` all resolve; the slash and glob forms do not.
#
# WHAT IT DOES NOT ASSERT, said plainly. That the list is the RIGHT one — curation is judgement, made by
# `tech-lead` and recorded in the ADR, and no test can hold it. And that the runtime actually loads what
# resolves here: this reads the same tree the loader reads, but it is not the loader. It catches a
# broken reference, not a broken loader.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AGENTS="$ROOT/agents"
COMMANDS="$ROOT/commands"

fails=0
ok()  { printf '  ok   %s\n' "$1"; }
bad() { printf '  FAIL %s\n' "$1"; fails=$((fails + 1)); }

printf '\nskills-resolve — every `skills:` identifier resolves to a tracked skill\n\n'

# `ls` rather than a glob so an empty directory is caught below rather than silently iterating once
# over a literal unexpanded pattern.
agent_files=$(find "$AGENTS" -maxdepth 1 -name '*.md' 2>/dev/null | sort)

if [ -z "$agent_files" ]; then
  bad "no persona files found under agents/ — this suite did NOT run"
  printf '\n%d failure(s)\n' "$fails"
  exit 1
fi

# Strip the optional plugin prefix. `plugin:workflow:license` and `tadeumendonca-skills:workflow:license`
# both resolve to the same file as `workflow:license` (measured, #172).
strip_prefix() {
  local id="$1"
  id="${id#plugin:}"
  id="${id#tadeumendonca-skills:}"
  printf '%s' "$id"
}

# A QUALIFIED identifier (one carrying a family segment) maps positionally:
#   `workflow:code-review` -> commands/workflow/code-review.md
#
# A BARE identifier does NOT — and assuming it did was a real defect in the first draft of this file,
# caught by writing the mutation probes rather than by reading it. Bare `license` resolves to
# `commands/workflow/license.md`, i.e. the loader searches the tree by STEM; it does not look only at
# the top level. The first version mapped bare `<id>` to `commands/<id>.md`, which happened to be right
# for `new-issue` (genuinely top-level) and would have been wrong, silently and in the permissive
# direction, for every bare identifier naming a skill inside a family. Bare resolution is therefore the
# `find` below, which is also what makes assertion 5 the resolution mechanism rather than a bolt-on.
resolve_qualified() {
  local id
  id="$(strip_prefix "$1")"
  printf 'commands/%s.md' "${id//://}"
}

total_ids=0
personas_with_key=0

for agent in $agent_files; do
  name=$(basename "$agent" .md)

  # --- SCOPE: the FRONTMATTER only, never the body ----------------------------------------------
  # A brief is tens of KB of prose and these briefs now DISCUSS their own `skills:` list in the body.
  # Scanning the whole file would let a line of documentation be parsed as configuration — a check
  # reading a different thing from the loader, which is a check that can go green about the wrong file.
  frontmatter=$(awk '
    NR == 1 && $0 == "---" { inside = 1; next }
    inside && $0 == "---"   { exit }
    inside                  { print }
  ' "$agent")

  # --- the key must be PRESENT, even when the answer is "none" -----------------------------------
  # An ABSENT `skills:` key and a DELIBERATELY EMPTY one are the same glyph to every reader and to
  # this test. `harness-reviewer` genuinely preloads nothing, and that is a decision worth publishing;
  # if absence were accepted here, a persona whose list was dropped in an edit would be indistinguish-
  # able from it. So the key is required and `skills: []` is how "none" is spelled.
  if ! printf '%s\n' "$frontmatter" | grep -qE '^skills:'; then
    bad "$name — no \`skills:\` key in the frontmatter. Absence is indistinguishable from a dropped list; write \`skills: []\` if the answer is none."
    continue
  fi
  personas_with_key=$((personas_with_key + 1))

  # Collect the list items. BOTH YAML SEQUENCE SPELLINGS ARE PARSED, and that is a corrected defect
  # rather than a precaution: the first version handled only block style, so `skills: [workflow:adr]`
  # — legal YAML the loader accepts — was read as an EMPTY list and reported "empty, deliberately".
  # A false green, in the one check that exists because this field fails silently. Quotes are stripped
  # for the same reason: `- "workflow:adr"` is legal and would otherwise resolve to a path containing
  # quote characters and fail as a phantom red.
  ids=$(printf '%s\n' "$frontmatter" | awk '
    function emit(s) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
      gsub(/^["'"'"']|["'"'"']$/, "", s)
      if (s != "") print s
    }
    /^skills:[[:space:]]*\[/ {
      # Flow style: skills: [a, b]
      line = $0
      sub(/^skills:[[:space:]]*\[/, "", line)
      sub(/\].*$/, "", line)
      n = split(line, parts, ",")
      for (i = 1; i <= n; i++) emit(parts[i])
      next
    }
    /^skills:/                   { in_block = 1; next }
    in_block && /^[^[:space:]-]/ { in_block = 0 }
    in_block && /^[[:space:]]*-[[:space:]]/ {
      line = $0
      sub(/^[[:space:]]*-[[:space:]]*/, "", line)
      sub(/[[:space:]]*#.*$/, "", line)
      emit(line)
    }
  ')

  if [ -z "$ids" ]; then
    ok "$name — \`skills:\` present and empty (preloads nothing, deliberately)"
    continue
  fi

  seen_ids=""
  seen_paths=""

  while IFS= read -r id; do
    [ -z "$id" ] && continue
    total_ids=$((total_ids + 1))

    # --- ASSERTION 2 — no `/` -------------------------------------------------------------------
    # Slash forms do not resolve and fail silently. This is the single most likely typo, because every
    # OTHER surface in this repo writes the same skill as `/workflow/code-review`.
    case "$id" in
      */*)
        bad "$name — \`$id\` contains \`/\`. Slash forms do NOT resolve; use the colon form (\`${id//\//:}\`)."
        continue
        ;;
    esac

    # --- ASSERTION 3 — no `*` -------------------------------------------------------------------
    # There is no glob support. `principles:*` is a literal that matches nothing, silently.
    case "$id" in
      *'*'*)
        bad "$name — \`$id\` contains \`*\`. There is no glob support; list each skill explicitly."
        continue
        ;;
    esac

    # --- ASSERTION 4a — no duplicate identifier within a list ------------------------------------
    case " $seen_ids " in
      *" $id "*)
        bad "$name — \`$id\` is listed twice. There is no dedupe: the file is injected, and billed, once per entry."
        continue
        ;;
    esac
    seen_ids="$seen_ids $id"

    # --- ASSERTION 5 — a BARE identifier must resolve to exactly one file ------------------------
    # Runs FIRST for a bare identifier, because for that form it IS the resolution: the loader searches
    # by stem, so two files sharing a stem make the identifier ambiguous and which one loads is not
    # something this repo gets to decide.
    #
    # NO STEM OCCURS IN TWO FAMILIES TODAY — #174 merged the four that did (`coverage`, `dynamodb`,
    # `cloudwatch-rum`, `environment-config`), and
    #   git ls-tree -r --name-only HEAD -- commands | xargs -n1 basename | sort | uniq -d
    # returns nothing. So this assertion cannot fire on the current tree, and it is here for #164's
    # flatten, which collapses every family segment into one namespace and is exactly what
    # reintroduces the collision. That is the whole argument; an earlier draft of this comment also
    # claimed the four pairs still existed, which was false at the head it shipped on.
    bare=$(strip_prefix "$id")
    case "$bare" in
      *:*)
        rel=$(resolve_qualified "$id")
        ;;
      *)
        matches=$(find "$COMMANDS" -name "$bare.md" | sort)
        n_matches=$(printf '%s\n' "$matches" | grep -c . || true)
        if [ "$n_matches" -ne 1 ]; then
          bad "$name — bare \`$id\` matches $n_matches files under commands/; it must match exactly one. Qualify it with its family."
          continue
        fi
        rel="${matches#"$ROOT"/}"
        ;;
    esac

    # --- ASSERTION 1 — resolves to a file that exists AND is tracked -----------------------------
    # Tracked matters as much as present: an untracked file resolves on the author's laptop and is
    # absent for every consumer of the plugin, which is the silent failure wearing a different hat.
    if [ ! -f "$ROOT/$rel" ]; then
      bad "$name — \`$id\` resolves to $rel, which does not exist"
      continue
    fi
    if ! git -C "$ROOT" ls-files --error-unmatch "$rel" >/dev/null 2>&1; then
      bad "$name — \`$id\` resolves to $rel, which exists but is NOT TRACKED; it would be absent for every consumer"
      continue
    fi

    # --- ASSERTION 4b — no two identifiers resolving to the same path ---------------------------
    # An alias pair (`license` and `workflow:license`) passes 4a and still loads two full copies.
    case " $seen_paths " in
      *" $rel "*)
        bad "$name — \`$id\` is an alias for a skill already listed ($rel). No dedupe: two entries, two full copies, twice the bytes."
        continue
        ;;
    esac
    seen_paths="$seen_paths $rel"

    ok "$name — \`$id\` → $rel"
  done <<< "$ids"
done

# The suite must not pass by doing nothing — the failure mode every assertion above shares.
if [ "$personas_with_key" -eq 0 ]; then
  bad "no persona declared a \`skills:\` key; every assertion above was skipped"
fi
if [ "$total_ids" -eq 0 ]; then
  bad "no identifiers were checked across $personas_with_key persona(s); the parser matched nothing and this suite proved nothing"
fi

printf '\n%d persona(s) with a `skills:` key, %d identifier(s) checked\n' "$personas_with_key" "$total_ids"

if [ "$fails" -gt 0 ]; then
  printf '%d failure(s)\n\n' "$fails"
  exit 1
fi
printf 'all green\n\n'
