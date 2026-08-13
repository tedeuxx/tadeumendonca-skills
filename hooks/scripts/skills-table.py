#!/usr/bin/env python3
"""Emit the README's skill inventory table, derived from `skills/`.

THE FAMILY IS READ OFF THE PATH AGAIN (#182). The tree is `skills/<family>/<name>/SKILL.md`, so
`parent.name` is the SKILL and `parent.parent.name` is the FAMILY. Both come from the filesystem and
nothing here enumerates either.

~~THE FAMILY IS READ OUT OF THE FILE, NOT OFF THE PATH (#164). The library is flat — one directory per
skill — so there is no family segment anywhere in the tree, and the family survives as a `family:`
frontmatter key.~~ **STRUCK: the premise was measured false on #182.** The flat tree existed because
nesting was believed not to resolve; it resolves whenever `plugin.json` declares the path, and the
identifier stays the bare innermost directory name either way. With the directory carrying the family
again, the `family:` key was a second source of one truth and a non-platform field in 69 published
files, so it is gone.

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

# Allocation is per family everywhere except `workflow`, which splits — `adr` belongs to its two
# writers, split by domain (#223), and `command-hygiene` is transversal (#225) like the `principles`
# family, not the builder alone. Family granularity cannot state that truthfully, which is why the
# table is per skill and this map has exceptions beside it.
DEVELOPER = "`developer`"
WIELDER = {
    "principles": "`product-lead` · `tech-lead` · `harness-lead` · `quality-assurance`",
    "workflow": DEVELOPER,
    "frontend": DEVELOPER,
    "backend": DEVELOPER,
    "infrastructure": DEVELOPER,
}
PER_SKILL = {
    ("workflow", "adr"): "`tech-lead` · `harness-lead` — split by domain (#223)",
    ("workflow", "command-hygiene"): "`product-lead` · `tech-lead` · `harness-lead` · `developer` · `quality-assurance`",
    ("workflow", "devops"): "`developer` · `harness-lead` · `tech-lead` (#227)",
    ("workflow", "coverage"): "`developer` · `quality-assurance` — extracted from `backend` (#230)",
}

# A family with no entry above is unallocated, and that is information rather than an error: an unused
# convention is usually a prompt to delete the file. Rendering it as a visible dash beats omitting the
# row, which would hide it.
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


def family_of(path):
    """The family DIRECTORY the skill sits in — `skills/<family>/<name>/SKILL.md`, or
    `skills/<family>/SKILL.md` when a family consolidated to one file and the family directory IS the
    skill (#230/#231 — `backend`, `frontend`).

    A wrong depth is a hard error rather than a default. Defaulting would let a misplaced skill land
    in the table under some catch-all, pass both directions of the README assertion, and drop out of
    the per-family counts with nothing red — the silent-shrink shape #164 finding 1 is about, and the
    reason `inventory-counts.test.sh` asserts the tree's shape separately (same two depths, mirrored).
    """
    rel = path.relative_to(SKILLS)
    if len(rel.parts) == 2 and rel.parts[1] == "SKILL.md":
        return rel.parts[0]
    if len(rel.parts) == 3 and rel.parts[2] == "SKILL.md":
        return rel.parts[0]
    raise SystemExit(f"{path} is not at skills/<family>/[<name>/]SKILL.md")


def main():
    skills = sorted(SKILLS.glob("*/SKILL.md")) + sorted(SKILLS.glob("*/*/SKILL.md"))
    fams = {}
    for f in skills:
        fams.setdefault(family_of(f), []).append(f)
    counts = ", ".join(f"{name} ({len(fams[name])})" for name in sorted(fams))
    print(f"The library, by family: {counts}.\n")
    print("| skill | what it decides | family | whose domain |")
    print("|---|---|---|---|")
    for name in sorted(fams):
        for f in sorted(fams[name], key=lambda p: p.parent.name):
            stem = f.parent.name
            who = PER_SKILL.get((name, stem), WIELDER.get(name, UNALLOCATED))
            print(f"| `{stem}` | {describe(f)} | `{name}` | {who} |")


if __name__ == "__main__":
    main()
