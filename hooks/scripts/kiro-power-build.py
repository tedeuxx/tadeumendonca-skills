#!/usr/bin/env python3
"""Generate the Kiro Power export under `powers/tadeumendonca-skills/` from `skills/`.

WHY THIS EXISTS AT ALL, and why it is a GENERATOR rather than a hand-maintained parallel tree.

The owner's ask (#287): *"quero manter compatibilidade tanto com kiro como claudecode com seus
mecanismos nativos"* — one repository, installable by BOTH harnesses through each one's own native
path, at the same time:

  * Claude Code  — `claude plugin marketplace add tedeuxx/tadeumendonca-skills` reads
    `.claude-plugin/marketplace.json` + `.claude-plugin/plugin.json`, whose `skills` array points at
    `./skills/<name>`. Untouched by this file. Nothing here writes inside `skills/` or
    `.claude-plugin/`.
  * Kiro        — Powers panel -> *Add Custom Power* -> *Import power from GitHub* -> a GitHub URL.
    Kiro clones the repo and reads a PACKAGE ROOT, which is the directory this file writes.

THE TWO FORMATS ARE NOT THE SAME FILE IN TWO PLACES. They differ mechanically, and the differences are
the whole reason a copy would rot:

  1. **Kiro's `SKILL.md` frontmatter requires `name` AND `description`. Not one of this repo's 13
     source files carries `name`** — measured, `grep -c '^name:' skills/*/SKILL.md` returns 0 for all
     thirteen. #287's intake called the two contracts "near-verbatim"; on this key it is simply wrong,
     and a hand-copied tree would have shipped thirteen skills Kiro rejects or mis-keys. The generator
     synthesises `name` from the directory, which is the same string Claude Code derives the
     identifier from, so the two harnesses agree on the name by construction rather than by care.
  2. **Relative links do not survive the move.** Five distinct `](../../docs/adr/...)` targets appear
     across the library. From `skills/<name>/SKILL.md` they resolve; from
     `powers/tadeumendonca-skills/skills/<name>/SKILL.md` they resolve two directories too high, and
     once Kiro has COPIED the skill into `~/.kiro/powers/<power>/` they do not resolve at all — the
     ADR library is not there. They are rewritten to absolute `blob/main` URLs, which is the only
     form that is correct in both the repo and the install location.
  3. **The two manifests share no schema.** Claude Code's carries a `skills` array; the Agent Plugins
     1.0.0 manifest schema (`https://agent-plugins.org/schemas/1.0.0/plugin.schema.json`) declares
     `"additionalProperties": false` and has no `skills` property at all — Kiro discovers skills by
     walking `skills/*/SKILL.md` under the package root instead. Emitting one from the other is a
     projection, not a copy.

So the export is DERIVED, and `kiro-power.test.sh` re-runs this generator into a temporary directory
and diffs it against what is committed. Drift between the two trees is therefore not a thing a
reviewer has to notice.

WHAT IS COMMITTED AND WHY. The generated tree is committed rather than built on demand, and that is
forced by the consumer: Kiro installs by cloning the repo at a ref and reading files. There is no build
step it can run, so an uncommitted artifact is an artifact nobody can install. Committing generated
output creates exactly one risk — that the copy and the source disagree — and that risk is what the
gate above exists to remove.

WHAT THIS FILE DOES NOT DO, said plainly so the export is not read as more than it is:

  * `agents/`, `hooks/`, `commands/` and `.claude/settings.json` are NOT exported. GROUNDED ON ONE
    DIRECTLY OBSERVED FACT AND NOTHING ELSE: the installed Kiro build's own Power copy allow-list is
    `POWER.md`, `mcp.json` and `steering/`, and none of those four is in it. That is the layer that
    decides what a Power can carry on a machine, and it was read out of the shipped bundle.
    THIS CLAIM HAS NOW BEEN WRONG TWICE, BOTH TIMES IN THE SAME WAY — reaching past that observation
    for a second source that reads as corroboration and is not. Form 1 attributed it to
    kiro.dev/docs/powers/ "listing them as unsupported"; that page returns HTTP 200 and contains none
    of those terms. Form 2 attributed it to the Agent Plugins 1.0.0 manifest schema requiring exactly
    `$schema` and `name` under `"additionalProperties": false`, "so there is no key a persona, a hook
    or a permission rule could be carried in" — but that schema's `properties` includes `extensions`,
    an open object keyed by reverse-domain namespace whose contents the spec assigns no semantics to,
    which is precisely such a key. Both times the conclusion held and the ground did not. DO NOT ADD
    A THIRD SOURCE HERE. If the allow-list stops being the evidence, re-measure the allow-list.
    The Power ships the KNOWLEDGE layer of this harness and none of its ENFORCEMENT layer. The
    package README this file writes says so above the fold, because a reader who installs it and
    assumes otherwise has been misled by us, not by Kiro.
  * It does not touch `skills/`. The source tree is the single source of truth and is read-only here.

Run:  python3 hooks/scripts/kiro-power-build.py [<output-dir>]
      (no argument -> writes the committed tree at powers/tadeumendonca-skills/)
"""
import json
import pathlib
import re
import shutil
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SKILLS = ROOT / "skills"
CLAUDE_MANIFEST = ROOT / ".claude-plugin" / "plugin.json"
DEFAULT_OUT = ROOT / "powers" / "tadeumendonca-skills"

SCHEMA_URL = "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json"
BLOB_BASE = "https://github.com/tedeuxx/tadeumendonca-skills/blob/main/"

# The Kiro manifest's `description` is AUTHORED HERE rather than copied from `.claude-plugin/
# plugin.json`, and the difference is not cosmetic. That one describes a Claude Code harness — six
# personas, PreToolUse hooks that deny the irreversible floor — none of which this Power ships,
# because Kiro's format carries no channel for any of it. Reusing it would put a false inventory in
# the first field a Kiro user reads. This one describes what actually installs.
KIRO_DESCRIPTION = (
    "The knowledge layer of a public agent-harness reference: 13 dense, opinionated engineering "
    "skills covering AWS infrastructure, React/Vite frontends, BFF-on-Lambda backends, CI/CD, the "
    "development loop and its quality gates. Written project-agnostically with <project> / "
    "<apex-domain> placeholders. This Power ships skills only — the harness's personas, permission "
    "hooks and merge gates have no Kiro distribution channel and are not included."
)

# Activation keywords. Derived from the skill directory names plus a small fixed set naming the
# domains a developer would actually type, since Kiro matches these against conversation text and
# nobody says "definition-of-ready" out loud. Kept deterministic (sorted, deduplicated) so two runs
# of this generator can never differ.
EXTRA_KEYWORDS = [
    "agent harness",
    "aws",
    "ci-cd",
    "definition of done",
    "github actions",
    "quality gate",
    "react",
    "terraform",
    "vite",
]


def skill_names():
    """Every skill directory, one level under `skills/`, sorted. The ONLY shape (#286)."""
    return sorted(p.parent.name for p in SKILLS.glob("*/SKILL.md"))


def split_frontmatter(text):
    """-> (frontmatter_body, rest). Raises if the file has no `---` fenced frontmatter."""
    if not text.startswith("---\n"):
        raise SystemExit("SKILL.md does not open with a '---' frontmatter fence")
    end = text.find("\n---\n", 3)
    if end == -1:
        raise SystemExit("SKILL.md frontmatter is not closed by a '---' line")
    return text[4:end + 1], text[end + 5:]


def description_of(front):
    """The `description:` value, rejoined to ONE line.

    Source descriptions are single-line by convention and gated as such elsewhere, but this reads
    them defensively: a description that wrapped would emit invalid frontmatter on the Kiro side,
    which is a failure nobody would see until an install.
    """
    match = re.search(r"^description:[ \t]*(.*)$", front, re.MULTILINE)
    if not match:
        raise SystemExit("SKILL.md frontmatter carries no `description:` key")
    return " ".join(match.group(1).split())


def absolutise_links(body):
    """Rewrite `](../../X)` to an absolute blob URL.

    `../../` from `skills/<name>/SKILL.md` is the repo root, which is what BLOB_BASE names. Only
    that exact depth is rewritten: any other relative prefix is left alone and reddens the gate
    instead of being silently guessed at, because guessing a link target wrong is worse than a
    visible failure.
    """
    return re.sub(r"\]\(\.\./\.\./([^)]+)\)", lambda m: "](" + BLOB_BASE + m.group(1) + ")", body)


def unresolved_relative_links(body):
    """Any `](../...)` left after the rewrite — the gate's falsifier for a link shape we did not expect."""
    return re.findall(r"\]\(\.\.[^)]*\)", body)


def build_skill(name):
    src = (SKILLS / name / "SKILL.md").read_text(encoding="utf-8")
    front, body = split_frontmatter(src)
    description = description_of(front)
    body = absolutise_links(body)
    leftover = unresolved_relative_links(body)
    if leftover:
        raise SystemExit(
            f"skills/{name}/SKILL.md carries a relative link this generator cannot resolve: "
            f"{leftover[0]} — extend absolutise_links() rather than leaving it to break silently"
        )
    return f"---\nname: {name}\ndescription: {description}\n---\n{body}"


def build_manifest(names):
    claude = json.loads(CLAUDE_MANIFEST.read_text(encoding="utf-8"))
    keywords = sorted(set(names) | set(EXTRA_KEYWORDS))
    # Key order is fixed and the file is written with a trailing newline, so the generator's output is
    # byte-stable across runs and the gate can diff it rather than parse-and-compare.
    return {
        "$schema": SCHEMA_URL,
        "name": claude["name"],
        "version": claude["version"],
        "description": KIRO_DESCRIPTION,
        "author": {"name": claude["author"]["name"]},
        "homepage": claude["homepage"],
        "repository": claude["repository"],
        "license": claude["license"],
        "keywords": keywords,
    }


PACKAGE_README = """<!-- GENERATED by hooks/scripts/kiro-power-build.py — do not edit by hand. -->
# tadeumendonca-skills — Kiro Power

This directory is the **Kiro Power** package root for
[`tedeuxx/tadeumendonca-skills`](https://github.com/tedeuxx/tadeumendonca-skills). It is **generated**
from the repository's own `skills/` tree and gated by `hooks/scripts/kiro-power.test.sh`; editing it by
hand will turn that gate red. Edit `skills/<name>/SKILL.md` at the repository root instead.

## Install

In Kiro: **Powers** panel -> **Add Custom Power** -> **Import power from GitHub**, then enter

```
https://github.com/tedeuxx/tadeumendonca-skills/tree/main/powers/tadeumendonca-skills
```

The `/tree/main/<path>` form is required, not optional. Kiro parses the branch and the sub-path out of
the URL and sparse-checks-out that directory; a bare repository URL resolves the package root to the
repository root, where there is no Kiro manifest.

**Read "One caveat" below before you rely on this.** Old enough builds report a successful install and
copy nothing, so the steps above can appear to work and leave you with an empty Power.

## What this ships, and what it does not

**Ships:** the skills — {count} dense, project-agnostic engineering guides.

**Does not ship:** the harness's persona briefs (`agents/`), its `PreToolUse` permission hooks
(`hooks/`) or its merge gates. **The evidence for that is one directly observed fact, and this
paragraph deliberately stops there:** the Power installer's copy allow-list in the Kiro build measured
below is `POWER.md`, `mcp.json` and `steering/`, and none of those four is in it. What a Power can
carry is decided by what the installer copies.

Two earlier forms of this paragraph reached past that for a corroborating source — a docs page, then
the manifest schema — and both were wrong about the source while right about the conclusion. They are
not restated here, and no replacement source is offered in their place.

That is a limit of what the installer accepts, not an omission here, and it is stated so that nobody
installs this expecting the enforcement layer. The full harness is the Claude Code plugin at the
repository root.

## One caveat, and it is larger than the rest

**Measured, not inferred, and it decides whether this Power installs at all.** On the Kiro build this
export was measured against — **`0.12.333`, `quality: stable`, built 2026-06-10** — the Power
installer's copy allow-list is `POWER.md`, `mcp.json` and `steering/`, the string `plugin.json` does
not occur once in the extension's 821,906-line bundle, and the copy routine **swallows the
missing-file error** rather than raising it. That build does not implement the Agent Plugins format at
all: it would report a **successful install of this Power and copy nothing** — a silent total failure,
not a partial one.

**The version to compare yourself against is not that one — it is the release that added the format.**
Kiro's public changelog dates Agent Plugin support to **IDE `1.0.288`, 7 Aug 2026**: *"Install powers
aligned with the open Agent Plugin format from a local folder or GitHub URL."* The measured build
above predates that release by two months, and it is quoted here as the concrete evidence of what a
pre-support build does, not as a threshold you can compare a version string to — the two numbers are
not from the same series, so only the named release and the dates are comparable.

This export is built to that format. A build older than the release above installs this empty rather
than failing loudly.
**Verify against your own Kiro version before relying on it:** after installing, confirm that
`~/.kiro/powers/tadeumendonca-skills/skills/` actually contains {count} directories. If it is empty,
your build predates the format and nothing here is loaded.
"""


def main():
    out = pathlib.Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else DEFAULT_OUT
    names = skill_names()
    if not names:
        raise SystemExit("no skills found under skills/*/SKILL.md — refusing to write an empty Power")

    # Rebuilt from scratch every run. A skill RENAMED at the source would otherwise leave its old
    # directory behind, and a stale skill in the export is the drift this whole file exists to
    # prevent — invisible to a forward-only check, and shipped to a consumer as if current.
    skills_out = out / "skills"
    if skills_out.exists():
        shutil.rmtree(skills_out)
    out.mkdir(parents=True, exist_ok=True)

    for name in names:
        target = skills_out / name
        target.mkdir(parents=True)
        (target / "SKILL.md").write_text(build_skill(name), encoding="utf-8")

    (out / "plugin.json").write_text(
        json.dumps(build_manifest(names), indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    (out / "README.md").write_text(
        PACKAGE_README.replace("{count}", str(len(names))), encoding="utf-8"
    )
    print(f"wrote {len(names)} skills + plugin.json + README.md to {out}")


if __name__ == "__main__":
    main()
