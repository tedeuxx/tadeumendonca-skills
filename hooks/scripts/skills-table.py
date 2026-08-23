#!/usr/bin/env python3
"""Emit the README's skill inventory table, derived from `skills/`.

THERE IS NO FAMILY ANY MORE (#286). The tree is `skills/<name>/SKILL.md`, one level, fourteen
directories — the owner's decision: *"o que eu quero é que todas skills estejam no mesmo nível
hierárquico de diretórios."* So this file no longer computes a family, no longer emits a family column,
and the allocation map below is keyed on the SKILL rather than inherited from a group.

~~THE FAMILY IS READ OFF THE PATH AGAIN (#182). The tree is `skills/<family>/<name>/SKILL.md`, so
`parent.name` is the SKILL and `parent.parent.name` is the FAMILY.~~ ~~THE FAMILY IS READ OUT OF THE
FILE, NOT OFF THE PATH (#164) … it survives as a `family:` frontmatter key.~~ **Both struck.** Kept
visible rather than deleted because between them they record what the grouping cost: it moved from a
directory to a frontmatter key and back again in two slices, and each move rewrote this generator and
three assertions in `inventory-counts.test.sh`. The reason the directories existed at all — a human
reading 69 files should not meet an alphabetical pile — is a claim about a denominator that has since
fallen to 13. That history is written up in `CLAUDE.md`, not re-argued here.

WHAT THE FLATTEN COST THIS FILE, said rather than left to look free: allocation was a per-FAMILY map
with three per-skill exceptions, which was compact and could not state the truth for those three. It is
now fourteen explicit lines. That is more to maintain and it is exact — no skill inherits an owner from
a directory it merely happens to sit in, and a NEW skill lands as `UNALLOCATED` (rendered `— none`)
instead of quietly inheriting its neighbours', which `skills-resolve.test.sh`'s reverse assertion
reddens on.

WHY THIS IS A COMMITTED TOOL RATHER THAN A ONE-OFF. The README publishes one row per skill, and each
description is the skill's own first line OF BODY — never the `description` frontmatter field, which is
written for the matcher and is far too long for this column (see `body_lines` below). That is not a
style choice: a table of this size written by hand is one chance per row to describe a skill as
something it does not say, with nothing anywhere able to catch it. Generating it removes the chance.

But a generated table whose generator lives in a scratch directory is worse than a hand-written one — the
next person to add a skill edits the table by hand, and the property that made generation worth doing is
gone silently. `inventory-counts.test.sh` asserts that every skill file has a row, so a hand-edit that
forgets one goes red. This file is what makes fixing that red cheap.

WHAT IT DOES NOT DECIDE. Allocation — whose domain a family is — is a fact about the roster, not about
the filesystem, so it is written below and maintained by hand. Everything else is read from `commands/`.

THE COLUMN IS `whose domain`, NOT `wielded by`, AND NOT `preloaded by` (renamed in #172). It answers who
is ACCOUNTABLE for a convention. It deliberately does NOT answer what a persona has loaded at startup —
that is the `skills:` frontmatter, whose ten entries resolve to 8 distinct files — 7 of them rows in this
table, since `new-issue` is top-level — and it is published as its own list in the README with the byte
cost of each. Merging the two would print "— none" against 62 of the 69 rows, i.e. nine tenths of the
library, which is false. If you are here because the two look contradictory: they answer different
questions, and the README says so above the table.

Run:  python3 hooks/scripts/skills-table.py
Then paste the output over the table in the README's skill-library section.
"""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
SKILLS = ROOT / "skills"

# ALLOCATION IS PER SKILL, KEYED ON THE SKILL'S OWN NAME (#286). It used to be a per-FAMILY map with
# three exceptions beside it, because family granularity could not state the truth for those three
# (`documentation-standard` splits by domain, `command-hygiene` is transversal, `devops` has three
# holders). With no families left there is nothing to inherit from, so every skill states its own owner
# and the exception list is gone — the same information, one indirection fewer, and fourteen lines that
# each say what they mean.
DEVELOPER = "`developer`"
JUDGES = "`product-lead` · `tech-lead` · `agents-lead` · `quality-assurance`"
WIELDER = {
    "backend": DEVELOPER,
    "cloud-infrastructure": DEVELOPER,
    "code-review": DEVELOPER,
    "command-hygiene": "`product-lead` · `tech-lead` · `agents-lead` · `developer` · `quality-assurance`",
    "definition-of-done": JUDGES,
    "definition-of-ready": JUDGES,
    "devops": "`developer` · `agents-lead` · `tech-lead` (#227)",
    "documentation-standard": "`developer` (Part I, general docs) · `tech-lead` · `agents-lead` — Part II, ADR practice split by domain (#223)",
    "frontend": DEVELOPER,
    "harness-engineering": JUDGES,
    "license": DEVELOPER,
    "planning-poker": JUDGES,
    "published-voice": "`writer` — and the content reviewer that is decided and not yet built",
    "quality-gates": JUDGES,
}

# A skill with no entry above is unallocated, and that is information rather than an error: an unused
# convention is usually a prompt to delete the file. Rendering it as a visible dash beats omitting the
# row, which would hide it. `skills-resolve.test.sh`'s reverse assertion greps for exactly this string,
# so an unallocated skill is a RED BUILD rather than a quiet dash — which is the property the flatten
# strengthened: a new skill can no longer inherit an owner from the directory it landed in.
UNALLOCATED = "— none"

MAX_DESC = 150


def body_lines(path):
    """The file's lines with any YAML frontmatter block removed.

    EVERY SKILL GAINED FRONTMATTER (#166), AND WITHOUT THIS THE GENERATOR EMITS `---` AS ALL 73
    DESCRIPTIONS. That is worse than a crash, because `inventory-counts.test.sh` tells whoever hits a
    red table to fix it by re-running THIS script and pasting the output — and its table assertion
    keys on cells 1 and 3 only, so a README with `---` in every description cell passes both
    directions. The repair instruction would have introduced the defect, silently, in the one document
    a forker reads first.

    THE FIRST BODY LINE IS STILL THE SOURCE, deliberately, rather than the new `description` field.
    Switching the column to the frontmatter is a content decision about a published README — the
    descriptions are trigger sentences of 300-500 chars written for a matcher, and MAX_DESC would cut
    each one mid-clause. Keeping the body line makes this slice's README diff exactly zero, which is
    what makes it reviewable. If the column should carry the description instead, that is its own
    change with its own truncation policy.
    """
    lines = path.read_text().splitlines()
    if lines and lines[0].strip() == "---":
        for i, line in enumerate(lines[1:], start=1):
            if line.strip() == "---":
                return lines[i + 1:]
        # Unterminated block: fall through rather than silently returning nothing. A file that opens
        # `---` and never closes it is malformed, and emitting its raw first line makes that visible
        # in the table instead of blanking the row.
    return lines


def describe(path):
    """The skill's own first non-empty line of BODY, stripped of heading syntax."""
    text = next((l.strip() for l in body_lines(path) if l.strip()), "")
    text = re.sub(r"^#+\s*", "", text).replace("|", r"\|")
    if len(text) > MAX_DESC:
        text = text[: MAX_DESC - 3].rsplit(" ", 1)[0] + "…"
    return text


def stem_of(path):
    """The skill's identifier — `skills/<name>/SKILL.md` -> `<name>`, and the ONLY shape (#286).

    A wrong depth is a hard error rather than a default, unchanged in kind from when this function
    computed a family. Defaulting would let a misplaced skill land in the table under some catch-all,
    pass both directions of the README assertion, and drop out of the count with nothing red — the
    silent-shrink shape #164 finding 1 is about, and the reason `inventory-counts.test.sh` asserts the
    tree's shape separately (now one depth, mirrored).
    """
    rel = path.relative_to(SKILLS)
    if len(rel.parts) == 2 and rel.parts[1] == "SKILL.md":
        return rel.parts[0]
    raise SystemExit(f"{path} is not at skills/<name>/SKILL.md")


def main():
    # ONE GLOB, ONE DEPTH. It was two globs while `backend`/`frontend` sat at depth 1 and the other
    # eleven at depth 2; a second glob now would silently re-admit the shape this slice removed.
    skills = sorted(SKILLS.glob("*/SKILL.md"))
    print(f"The library: {len(skills)} skills, one directory each, at one level under `skills/`.\n")
    print("| skill | what it decides | whose domain |")
    print("|---|---|---|")
    for f in skills:
        stem = stem_of(f)
        print(f"| `{stem}` | {describe(f)} | {WIELDER.get(stem, UNALLOCATED)} |")


if __name__ == "__main__":
    main()
