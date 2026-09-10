#!/usr/bin/env bash
# Asserts the MECHANICAL properties of this repository's Codex exec-policy port,
# `.codex/rules/claude-command-policy.rules`.
#
# No count of arms is stated here on purpose. The header read "the four" while the file carried six
# verdicts, and a prose figure beside a derived one is the arrangement this repository's own gates
# exist because it rots. Count the `ok`/`bad` calls if a number is wanted.
#
# WHY THIS EXISTS. That file is a THIRD harness's permission layer. It was agent-authored on
# 2026-09-07, listed in `.git/info/exclude` — so `git status` never showed it — and no PR, no gate and
# no reviewer had ever seen it until skills#419. An untracked control is worse than an untracked brief
# because its failure direction is permissive: whoever finds it reads it as the floor, and it is a
# partial floor. Tracking it is what makes a check possible at all; this suite is the check.
#
# WHAT IT CANNOT SEE — read this before spending the green on anything.
#
#   * THE ALLOW SIDE. 183 of the port's 335 original allow rules had no verbatim source line in either
#     `settings.json`; they are expansions the porting run invented. Nothing here can derive them, so
#     nothing here asserts them. That is deliberate and it is the right asymmetry: a missing allow is
#     a permission prompt, a missing deny is a hole, and this suite points at the hole.
#   * FIVE DENIES THAT NO CI ARM CAN EVER READ. Of the 34 unique `Bash` deny token-lists governing this
#     workspace, five live only in `~/.claude/settings.json`, which is in no git repository
#     (`git -C ~ rev-parse --show-toplevel` -> not a repository). This suite reads the repo's own
#     tracked layer and nothing else, by construction.
#   * SEMANTICS. A deny present verbatim is still matched as a literal argv prefix from argv[0], so it
#     remains reachable through an exec wrapper -- `xargs` is allowed bare in this very file. The arm
#     proves coverage of a LIST. It proves nothing about the ACT.
#   * WHETHER THE TRACKED FILE IS THE ONE THAT HARNESS LOADS. Nothing in this loop runs inside Codex,
#     no Codex session has ever been observed here, and that harness resolves `.rules` at a user layer
#     too (`~/.codex/rules/`) which is outside every repository. A green here says the tracked artifact
#     holds its properties; it does not say the running floor is this artifact.
#
# So: this is a DRIFT check over a list, not a proof that either floor works. The two floors are not
# equivalent and the file's own header says so; do not let a green here be read as saying they are.
#
# ── HOW EVERY ARM WAS CALIBRATED — REPRODUCE IT, DO NOT TRUST THIS PARAGRAPH ────────────────────────
# A check that has only ever passed has been OBSERVED PASSING, which is a far smaller claim than
# CALIBRATED. Each arm below was taken green -> red by mutating the SUBJECT (never this file) and back
# again. Run these from the repository root; each restores itself with `git checkout`:
#
#   arm 1  printf 'prefix_rule(pattern=["z"] decision="allow")\n' >> the port      -> 1 failed
#   arm 2  add "Bash(zzznonce mutate:*)" to .claude/settings.json permissions.deny -> 1 failed
#   arm 2  delete the ["gh","secret","set"] forbidden rule from the port           -> 1 failed
#   arm 3  add a rule whose pattern carries /Users/zzznonce/x                      -> 2 failed
#   arm 4  add an allow naming hooks/scripts/zzznonce.test.sh                      -> 1 failed
#   arm 4  delete every `bash hooks/scripts/...` allow from the port               -> 2 failed
#          (arm 4's own vacuity guard, plus arm 4b -- NOT "0 of 0 resolve, PASS")
#   arm 4b `touch hooks/scripts/zzznonce.sh && git add` it, list it in no rule     -> 1 failed
#   arm 4b delete the `bash hooks/scripts/permission-guard.sh` allow               -> 1 failed
#   arm 5  observed red before this suite was wired into a workflow at all
#
# ARM 4b's SECOND MUTATION IS THE ONE THAT MATTERS, and the first alone would have been a weaker
# claim than it looks. Adding an unlisted file proves the arm reads the disk; deleting a listed rule
# proves it reads the rules. An arm that only ever saw new files could have been comparing the disk
# against itself.
#
# AND ARM 4's VACUITY GUARD WAS ADDED BECAUSE IT WAS ALREADY PRINTING A ZERO AS A GREEN. The sibling
# copy's run reported `arm 4 · all 0 script path(s) named in a rule resolve` -- a pass over an empty
# set, in a green run, in the suite whose own header teaches that a check which has only ever passed
# has been observed passing and not calibrated. A `0` is evidence only once something in the same run
# has returned non-zero.
#
# THE FIRST MUTATION TRIED ON ARM 2 WAS DEAD, and it is published because the nonce result is
# meaningless without it: adding `Bash(terraform apply:*)` to the deny list leaves the arm GREEN,
# because the port already carries `["terraform","apply"]` as forbidden. A mutation that lands on
# ground the check already covers proves nothing at all, and it looks exactly like a passing test.
#
# ── THE CHAINING RULE, inherited from `inventory-counts.test.sh` ────────────────────────────────────
# Chain with `elif` ONLY where the failing condition makes the next verdict genuinely uncomputable (a
# GUARD). Never chain two ASSERTIONS because they share a subject: the first one's `bad` returns, the
# second emits neither PASS nor FAIL, and the totals stay plausible while an assertion has silently
# DISAPPEARED.
#
# ── THE BODY IS SHARED WITH THE SIBLING REPOSITORY ──────────────────────────────────────────────────
# Everything below the first column-zero `set -uo` line is byte-for-byte identical to
# `tadeumendonca-io/scripts/codex-rules.test.sh`. That is an OBLIGATION, not a claim about either
# copy's current state -- nothing checks it and nothing makes the two move together, because pipelines
# are independent per repository. The header deliberately differs. From a workspace holding both:
#
#   diff <(sed -n '/^set -uo/,$p' hooks/scripts/codex-rules.test.sh) \
#        <(sed -n '/^set -uo/,$p' ../tadeumendonca-io/scripts/codex-rules.test.sh)
#
# A sync copies the BODY, never the file: copying the whole file destroys the sibling's header, which
# is where that copy's own cost is recorded.
#
# Run: bash hooks/scripts/codex-rules.test.sh

set -uo pipefail

# ROOT and SCRIPT_DIR are both resolved by asking git, never by walking for a `.git` DIRECTORY. In a
# linked worktree `.git` is a FILE, so the old walk ran off the top of the tree and landed on `/`,
# making RULES_DIR `//.codex/rules` and reporting a missing subject -- a red that pointed at the file
# instead of at the walk. Fails closed: outside a repository no arm runs at all.
ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$ROOT" ]; then
  printf 'FAIL  cannot resolve a git root from %s; no arm ran\n' "$(dirname "${BASH_SOURCE[0]}")"
  exit 1
fi
# `--show-prefix` is what absorbs the depth difference between the two copies (`hooks/scripts/` here,
# `scripts/` in the sibling) without either one hard-coding the other's layout. Trailing slash included.
SCRIPT_DIR="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-prefix 2>/dev/null || true)"
if [ -z "$SCRIPT_DIR" ]; then
  printf 'FAIL  this suite resolves to the repository root; arm 4b would scan the whole tree\n'
  exit 1
fi
SETTINGS="$ROOT/.claude/settings.json"
RULES_DIR="$ROOT/.codex/rules"
SELF="$(basename "$0")"

pass=0
fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }
done_() { printf '\n%s passed, %s failed\n' "$pass" "$fail"; [ "$fail" -eq 0 ]; }

# --- the subject exists at all ------------------------------------------------------------------
# A GUARD, not an assertion: every verdict below is vacuous over a missing file, and a suite that
# reports a column of passes about nothing is worse than one that stops.
rules_files=""
if [ -d "$RULES_DIR" ]; then
  rules_files="$(find "$RULES_DIR" -maxdepth 1 -name '*.rules' -type f | sort)"
fi
if [ -z "$rules_files" ]; then
  bad "subject — no .rules file under $RULES_DIR"
  done_
  exit 1
fi
ok "subject — $(printf '%s\n' "$rules_files" | wc -l | tr -d ' ') .rules file(s) under .codex/rules/"

if [ ! -f "$SETTINGS" ]; then
  bad "subject — $SETTINGS does not exist, so deny coverage is uncomputable"
  done_
  exit 1
fi
ok "subject — .claude/settings.json exists"

corpus="$(printf '%s\n' "$rules_files" | while IFS= read -r f; do
  [ -n "$f" ] && cat "$f"
done)"

# --- ARM 1 · every non-comment line is a parseable prefix_rule ----------------------------------
# Not tidiness: a line the harness cannot parse is a rule that does not exist, and a typo in a
# `forbidden` rule removes a floor entry while the file still reads as carrying it.
malformed="$(printf '%s\n' "$corpus" \
  | grep -vE '^[[:space:]]*(#.*)?$' \
  | grep -vcE '^prefix_rule\(pattern=\["[^]]*"\], decision="(allow|forbidden)"\)$' || true)"
if [ "$malformed" != "0" ]; then
  bad "arm 1 · $malformed non-comment line(s) are not a parseable prefix_rule"
else
  ok "arm 1 · every non-comment line parses as prefix_rule(pattern=[...], decision=allow|forbidden)"
fi

# --- ARM 2 · every Bash() deny in settings.json is a forbidden prefix_rule -----------------------
# THE LOAD-BEARING ARM. It is the only thing that makes the port a tracked artifact rather than a
# tracked artifact that silently stopped being true: the Claude deny list moves, and nothing else
# anywhere would notice the port failing to move with it.
#
# The transform is mechanical and total: strip the `Bash(` wrapper, strip a trailing `:*` (a token
# boundary in the permission matcher, not part of the command), split on whitespace, and require that
# exact token list to appear as a `forbidden` rule. No normalising, no fuzzy match -- a rule that
# almost matches is a rule that does not fire.
deny_total=0
deny_missing=0
missing_list=""
while IFS= read -r entry; do
  [ -n "$entry" ] || continue
  deny_total=$((deny_total + 1))
  tokens="${entry%:\*}"
  rule="prefix_rule(pattern=[$(printf '%s\n' "$tokens" | tr ' ' '\n' \
        | awk 'NF{printf "%s\"%s\"", (NR>1?", ":""), $0}')], decision=\"forbidden\")"
  if ! printf '%s\n' "$corpus" | grep -Fxq "$rule"; then
    deny_missing=$((deny_missing + 1))
    missing_list="$missing_list
    $entry"
  fi
done <<EOF
$(jq -r '.permissions.deny[]? | select(startswith("Bash(")) | select(endswith(")")) | .[5:-1]' "$SETTINGS")
EOF

if [ "$deny_total" -eq 0 ]; then
  bad "arm 2 · settings.json declares no Bash() deny at all — the arm would pass vacuously"
elif [ "$deny_missing" -ne 0 ]; then
  bad "arm 2 · $deny_missing of $deny_total Bash() deny entries have no forbidden prefix_rule:$missing_list"
else
  ok "arm 2 · all $deny_total Bash() deny entries appear verbatim as forbidden prefix_rules"
fi

# --- ARM 3 · no machine-specific absolute path -------------------------------------------------
# The reason the file could not be tracked as authored: 113/116 lines carried the owner's home
# directory. This arm is what stops one coming back on the next porting run, in a public repository.
abs="$(printf '%s\n' "$corpus" \
  | grep -cE '"(/|[^"]*=/)[^"]*"' || true)"
if [ "$abs" != "0" ]; then
  bad "arm 3 · $abs rule(s) carry an absolute path token — not portable, and not publishable"
else
  ok "arm 3 · no rule carries an absolute path token"
fi

home="$(printf '%s\n' "$corpus" | grep -cE '/(Users|home)/' || true)"
if [ "$home" != "0" ]; then
  bad "arm 3b · $home line(s) name a home directory"
else
  ok "arm 3b · no line names a home directory"
fi

# --- ARM 4 · every repo-relative script path in a rule resolves ---------------------------------
# The drift that had ALREADY happened when this suite was written: the port allowed
# `hooks/scripts/wip-guard.test.sh`, deleted at e145cd0f (#383), twelve hours after being authored.
# A rule naming a file that does not exist is dead weight that reads as coverage.
unresolved=0
unresolved_list=""
paths="$(printf '%s\n' "$corpus" \
  | grep -oE '"[^"]*\.(sh|py)"' | tr -d '"' | sort -u)"
path_total=0
for p in $paths; do
  path_total=$((path_total + 1))
  if [ ! -f "$ROOT/$p" ]; then
    unresolved=$((unresolved + 1))
    unresolved_list="$unresolved_list
    $p"
  fi
done
if [ "$path_total" -eq 0 ]; then
  bad "arm 4 · no rule names a script path at all — the arm would pass vacuously"
elif [ "$unresolved" -ne 0 ]; then
  bad "arm 4 · $unresolved of $path_total script path(s) named in a rule do not exist:$unresolved_list"
else
  ok "arm 4 · all $path_total script path(s) named in a rule resolve under the repository root"
fi

# --- ARM 4b · every tracked shell script in THIS suite's own directory is named by a rule --------
# THE REVERSE DIRECTION, and the reason it exists is that arm 4 alone cannot see the drift that
# actually happens. Arm 4 is rule -> disk: it catches a rule outliving its file, which is how this
# suite was calibrated (`wip-guard.test.sh`, deleted at e145cd0f). Nothing was disk -> rule, so a
# script ARRIVING and never being listed was invisible: at the head this arm landed on, three tracked
# scripts were named by no rule and the suite reported 8 passed, 0 failed.
#
# SCOPE IS THIS DIRECTORY, NOT THE TREE, and that is a decision rather than convenience. In this
# repository `scripts/milestone-create.sh` is tracked, is run with `bash`, and is deliberately named
# by no allow anywhere: the permission prompt its absence produces is what stands in for the deleted
# rule 11 milestone verification. An arm scoped to the tree would have demanded a rule for it and
# closed that prompt as a side effect of a drift check. WHAT THAT COSTS: a `*.sh` added outside this
# directory is invisible here, and only review will see it.
#
# `*.sh` ONLY, because `bash` is not allowed bare while `python3` is, so a `.py` file needs no
# per-file rule and requiring one would be decoration. Falsify with:
#   grep -nE 'pattern=\["(bash|python3)"\]' .codex/rules/*.rules
# If that ever prints a bare `bash` rule, every per-script allow below is redundant; if it stops
# printing `python3`, this arm is under-scoped. Neither is checked.
#
# TRACKED files only (`git ls-files`): an untracked local script is not something a published port
# must name, and CI never checks one out.
unnamed=0
unnamed_list=""
script_total=0
while IFS= read -r s; do
  [ -n "$s" ] || continue
  script_total=$((script_total + 1))
  if ! printf '%s\n' "$paths" | grep -Fxq "$s"; then
    unnamed=$((unnamed + 1))
    unnamed_list="$unnamed_list
    $s"
  fi
done <<EOF
$(git -C "$ROOT" ls-files -- "${SCRIPT_DIR}*.sh")
EOF

if [ "$script_total" -eq 0 ]; then
  bad "arm 4b · no tracked *.sh under ${SCRIPT_DIR} — the arm would pass vacuously"
elif [ "$unnamed" -ne 0 ]; then
  bad "arm 4b · $unnamed of $script_total tracked script(s) under ${SCRIPT_DIR} are named by no rule:$unnamed_list"
else
  ok "arm 4b · all $script_total tracked script(s) under ${SCRIPT_DIR} are named by a rule"
fi

# --- ARM 5 · this suite is wired into CI --------------------------------------------------------
# A suite run only when somebody remembers is a gate one forgotten habit away from absent -- the
# failure `.github/workflows/hooks-test.yml` enumerates five times in its own header. This arm is the
# cheapest possible instrument against it: the suite asserts that a workflow names it.
wired="$(grep -rl -- "$SELF" "$ROOT/.github/workflows" 2>/dev/null | wc -l | tr -d ' ')"
if [ "$wired" = "0" ]; then
  bad "arm 5 · no workflow under .github/workflows names $SELF — this suite runs nowhere"
else
  ok "arm 5 · $SELF is named by $wired workflow file(s)"
fi

done_
