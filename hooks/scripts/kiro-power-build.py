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

  1. **Kiro's `SKILL.md` frontmatter requires `name` AND `description`. Not one of this repo's 14
     source files carries `name`** — measured, `grep -c '^name:' skills/*/SKILL.md` returns 0 for all
     fourteen. #287's intake called the two contracts "near-verbatim"; on this key it is simply wrong,
     and a hand-copied tree would have shipped fourteen skills Kiro rejects or mis-keys. The generator
     synthesises `name` from the directory, which is the same string Claude Code derives the
     identifier from, so the two harnesses agree on the name by construction rather than by care.
  2. **Relative links do not survive the move.** Five distinct `](../../docs/adr/...)` targets appear
     across the library. From `skills/<name>/SKILL.md` they resolve; from
     `powers/tadeumendonca-skills/skills/<name>/SKILL.md` they resolve two directories too high, and
     once Kiro has COPIED the skill into `~/.kiro/powers/installed/<power>/` they do not resolve at
     all — the ADR library is not there. They are rewritten to absolute `blob/main` URLs, which is
     the only form that is correct in both the repo and the install location. (The install path is
     `getPowerDir()` in the `1.0.337` bundle: `getKiroPowersHome()` -> `getInstalledDir()`, which
     appends `installed`, -> the power name. It read `~/.kiro/powers/<power>/` here until #287's
     review caught the missing segment.)
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

  * `agents/`, `hooks/`, `commands/` and `.claude/settings.json` are NOT exported. THE GROUND FOR
    THAT IS A CHOICE, NOT A MEASUREMENT OF KIRO, and the difference is the whole of the correction
    below: the enforcement layer is Claude-Code-shaped (`hooks.json`, `PreToolUse` matchers, an
    `agent_type` the harness stamps), and porting it is work nobody has done.
    ~~WHETHER A BUILD IMPLEMENTING THE AGENT PLUGINS FORMAT WOULD CARRY THEM IS NOT MEASURED AND IS
    NOT CLAIMED HERE IN EITHER DIRECTION. The one installer this repository has read — copy
    allow-list `POWER.md`, `mcp.json`, `steering/` — belongs to a build that does not implement this
    format at all.~~
    STRUCK 2026-08-23 (#287): IT IS MEASURED NOW, and the answer splits in two. Read out of the
    INSTALLED Kiro `1.0.337` bundle (`quality: stable`, built 2026-08-18) — a BUNDLE READING, not a
    live install; nothing below was observed loading, activating or denying anything:
      - TRANSPORT — yes. `isAgentPluginDir` -> `copyAgentPluginFiles` ->
        `copyDirectoryFiltered(..., AGENT_PLUGIN_EXCLUDED_DIRS)` with
        `AGENT_PLUGIN_EXCLUDED_DIRS = new Set([".git"])`. One exclusion. `agents/` and `hooks/`
        would arrive on disk.
      - ACTIVATION — no. The loader's filename constants are exactly `plugin.json`, `mcp.json`,
        `skills`/`SKILL.md` and `dev.kiro`. Nothing walks `agents/`, `hooks/` or `commands/`, and
        `~/.kiro/powers/` is never scanned for a persona or a hook.
    THAT SPLIT IS WHY THE OMISSION IS NOW A REASON AND NOT ONLY A PREFERENCE: a copied-but-never-read
    directory sitting next to skills that DO load reads as installed, which is this repo's own named
    failure shape — presenting a prompt-level instruction as an enforcement. A missing directory
    announces itself; an inert one does not.
    The `0.12.333` allow-list is KEPT, struck, under the README's "One caveat" — it stays true about
    that pre-support build and is cited only there.
    THIS CLAIM HAS NOW BEEN WRONG THREE TIMES. Twice in the same way — reaching past that observation
    for a second source that reads as corroboration and is not. Form 1 attributed it to
    kiro.dev/docs/powers/ "listing them as unsupported"; that page returns HTTP 200 and contains none
    of those terms. Form 2 attributed it to the Agent Plugins 1.0.0 manifest schema requiring exactly
    `$schema` and `name` under `"additionalProperties": false`, "so there is no key a persona, a hook
    or a permission rule could be carried in" — but that schema's `properties` includes `extensions`,
    an open object keyed by reverse-domain namespace whose contents the spec assigns no semantics to,
    which is precisely such a key. Both times the conclusion held and the ground did not.
    Form 3 was a DIFFERENT failure and worth telling apart, because it survived the fix for the first
    two: it dropped the bad second source and kept the good first one — the measured allow-list —
    without noticing that the measurement is scoped to a build the same document says cannot install
    this package. A correct measurement, offered as the ground for a claim about a DIFFERENT
    installer. The self-check that catches it is not "is this source real?" but "is this source about
    the same object as the claim it is carrying?"
    DO NOT ADD A FOURTH SOURCE HERE. The export ships skills by CHOICE; that needs no external
    ground, and it is the whole of what the README now asserts. If someone acquires a build at or
    above the release named in the README, measure THAT installer's allow-list and say which build it
    came from — do not re-cite this one. THAT INSTRUCTION WAS FOLLOWED on 2026-08-23: the `1.0.337`
    reading above names its build, and the `0.12.333` reading is kept struck rather than re-cited.
    The standing instruction now points one step further out — the bundle reading is still not a live
    one, and what would settle it is ten minutes of an authenticated Kiro login: Powers -> Add Custom
    Power -> Import power from local folder, with sentinel files planted in `agents/` and `hooks/`,
    then read `~/.kiro/powers/` for what ARRIVED and the agent's behaviour for what ACTIVATED.
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
# plugin.json`, and the difference is not cosmetic. That one describes a Claude Code harness —
# personas, PreToolUse hooks that deny the irreversible floor — none of which this Power ships.
# Reusing it would put a false inventory in the first field a Kiro user reads. This one describes
# what actually installs.
#
# THE SKILL COUNT IS DERIVED, NEVER TYPED, and the reason is a defect this file shipped. It read
# "13 dense skills" while `skills/` held 14, and `kiro-power.test.sh` was green throughout: that
# gate regenerates into a temp directory and diffs it against `powers/`, so it compares the
# generator's output to itself and a wrong constant is reproduced identically on both sides. A
# regenerate-and-diff gate can see drift between two trees; it is structurally blind to a claim
# the generator invents. So the number comes from the same `names` list that produces the exported
# directories and the keyword set — one source, and moving a skill moves the sentence.
def kiro_description(skill_count):
    return (
        f"The knowledge layer of a public agent-harness reference: {skill_count} dense, opinionated "
        "engineering skills covering AWS infrastructure, React/Vite frontends, BFF-on-Lambda "
        "backends, CI/CD, the development loop and its quality gates. Written project-agnostically "
        "with <project> / <apex-domain> placeholders. This Power ships skills only — the harness's "
        "personas, permission hooks and merge gates are deliberately not exported."
    )

# WHY THE SENTENCE STOPS THERE. It used to close with "…and Kiro's Power loader reads none of them
# from a package in any case" — true as measured against `1.0.337`, and still stated in the README,
# where the version it was measured on and the bundle-reading bound travel with it. This field does
# not have that room: it renders as a marketplace card with no date, no version and no bound, so the
# one half of the sentence that ages the moment Kiro ships its next build would age there unattended.
# What survives is a fact about THIS package — what it exports — which needs no measurement of
# anybody else's software to stand behind.

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


def safe_skills_out(out):
    """Return `out/skills`, or refuse — the only recursive delete in this file happens on that path.

    WHY THIS EXISTS, and it was found by EXECUTION rather than by reading. `main()` takes the output
    root from `sys.argv[1]` and rebuilds `out/skills` from scratch, which means a `shutil.rmtree`.
    Invoked as `python3 hooks/scripts/kiro-power-build.py .` from the repository root — a plausible
    mis-invocation, since every other script here is run from the root — `out/skills` IS `skills/`.
    Measured in a disposable copy: the 13 source skills were destroyed, one empty directory was left,
    and the run THEN died with `FileNotFoundError` reading a file it had just deleted. The failure
    arrives after the destruction, so there is no point at which the crash could have saved anything.

    THE PERMISSION FLOOR CANNOT SEE THIS. `permission-guard.sh` denies `rm -rf` by inspecting a
    command string; this is `python3 <a repo script> <a path>`, which it allows, and the deletion
    happens inside the process. That is this repository's own thesis pointed at itself — *every
    guarantee is mechanical or it is not real* — so the guard belongs here, adjacent to the hazard,
    and not in a layer that structurally cannot hold it.

    TWO CHECKS, and the second is the general one:

      1. **Never delete the source library.** Stated as an identity so it holds regardless of what
         anything else in this file does, and so it survives a later change to check 2's marker.
         `out == ROOT` is the demonstrated case; `out` at or inside `skills/` is refused with it,
         because writing the export there would also break this file's own read-only invariant.
      2. **Never recursively delete a `skills/` tree this generator did not write.** Check 1 is
         keyed to THIS repository and the hazard is not: `... build.py ~` deletes `~/skills`, and
         `... build.py ../<some other repo>` deletes that repo's. So the rmtree is allowed only into
         an output root that is absent, empty, or already a package this generator produced —
         identified by its own manifest's `name`. The rule is the general one: this file deletes only
         its own prior output.

    ACCEPTED COST of check 2, stated rather than discovered later: an export whose `plugin.json` was
    deleted by hand, or a run interrupted between the rmtree and the manifest write, refuses instead
    of self-healing and needs the directory removed manually. That is the correct direction to fail
    for a recursive delete, and the message says which state was found.
    """
    out = out.resolve()
    src = SKILLS.resolve()
    skills_out = out / "skills"

    if skills_out == src or out == src or src in out.parents:
        raise SystemExit(
            f"refusing to write the export to {out}: that would recursively delete the source "
            f"library at {src}. The output root is the PACKAGE root (default: {DEFAULT_OUT}), not "
            f"the repository root — run the generator with no argument."
        )

    if skills_out.exists():
        manifest = out / "plugin.json"
        produced_by_us = False
        if manifest.is_file():
            try:
                produced_by_us = (
                    json.loads(manifest.read_text(encoding="utf-8")).get("name")
                    == json.loads(CLAUDE_MANIFEST.read_text(encoding="utf-8"))["name"]
                )
            except (OSError, ValueError):
                produced_by_us = False
        if not produced_by_us:
            raise SystemExit(
                f"refusing to delete {skills_out}: it exists, and {out} carries no plugin.json "
                f"naming this Power, so this generator did not write it. This file deletes only its "
                f"own prior output. Remove the directory by hand if that is really what you want."
            )

    return skills_out


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
        "description": kiro_description(len(names)),
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

> **What changed since an earlier release of this file.** Earlier releases said the question of
> whether a Kiro build implementing the Agent Plugins format would carry `agents/` and `hooks/` was
> unmeasured and claimed in neither direction. It is measured now — against Kiro `1.0.337`, on
> 2026-08-23 — and the answer splits in two: **transport yes, activation no** (see *What this ships*
> below). The struck text and the full round-by-round history are kept at the source, in the
> repository's own [`README.md`](https://github.com/tedeuxx/tadeumendonca-skills/blob/main/README.md).
> This file is regenerated and republished on every merge, so it carries current claims only.

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
(`hooks/`) or its merge gates. **This export carries the knowledge layer and not the enforcement layer
BY CHOICE**, which is a fact about this package and needs no reading of anybody else's installer: the
enforcement layer is Claude-Code-shaped — `hooks.json`, `PreToolUse` matchers, `agent_type` — and
porting it to another harness is work nobody has done, not a file anybody forgot to copy.

**Whether a Kiro build implementing the Agent Plugins format WOULD carry those directories has two
halves, with opposite answers.** Read out of the installed Kiro **`1.0.337`** (`quality: stable`,
bundle built 2026-08-18):

- **Transport — yes.** The installer branches on whether the package holds a `plugin.json`. If it
  does, it copies the whole tree with a single exclusion (`.git`). `agents/` and `hooks/` would
  arrive on disk.
- **Activation — no.** The loader's filename constants are exactly `plugin.json`, `mcp.json`,
  `skills`/`SKILL.md` and `dev.kiro`. Nothing walks `agents/`, `hooks/` or `commands/`, and
  `~/.kiro/powers/` is never scanned for a persona or a hook.

**Keep those two words apart, because the gap between them is why omitting the enforcement layer is a
reason and not only a preference.** A directory that is copied but never read sits next to skills that
*do* load, and reads as installed. A missing directory announces itself; an inert one does not.

**This is a bundle reading, not a live install.** Nothing above was observed loading, activating or
denying anything: no Power has ever been installed from this repository. What would settle it is ten
minutes of an authenticated Kiro session — *Powers → Add Custom Power → Import power from local
folder*, with sentinel files planted in `agents/` and `hooks/` — then reading
`~/.kiro/powers/installed/` for what **arrived** and the agent's behaviour for what **activated**.

So, whichever half you care about: **install this expecting the skills, not the denies.** The full
harness is the Claude Code plugin at the repository root.

## One caveat, and it is larger than the rest

**Measured, not inferred — and measured by reading the shipped Kiro bundle, not by running a live
install.** Every claim here comes from the installed Kiro **`1.0.337`** (`quality: stable`, bundle
built 2026-08-18) as a file on disk; **nothing in this README was observed installing, loading or
denying anything.** That build **does** implement the Agent Plugins format: `plugin.json` occurs in
the bundle, the installer recognises a package that carries one, and the legacy copy allow-list
(`POWER.md`, `mcp.json`, `steering/`) is the `else` branch it no longer takes for this package. This
caveat decides whether the Power installs at all, so read it as a bundle reading you should confirm
against your own build — the check is at the end of this section.

**A build predating the format installs this empty and says it succeeded.** On the older
`0.12.333` build (`quality: stable`, built 2026-06-10) the copy allow-list is the legacy one above,
the string `plugin.json` does not occur in the extension bundle at all, and the copy routine
**swallows the missing-file error** rather than raising it — so it reports a **successful install of
this Power and copies nothing**: a silent total failure, not a partial one. That swallow is
**unchanged at `1.0.337`**; it was never fixed, it merely stopped applying to *this* package on a
build new enough to recognise it.

**The version to compare yourself against is not that one — it is the release that added the format.**
Kiro's public changelog dates Agent Plugin support to **IDE `1.0.288`, 7 Aug 2026**: *"Install powers
aligned with the open Agent Plugin format from a local folder or GitHub URL."* The `0.12.333` build
predates that release by two months, and it is quoted here as the concrete evidence of what a
pre-support build does, not as a threshold you can compare a version string to — the two numbers are
not from the same series, so only the named release and the dates are comparable.

**Verify against your own Kiro version before relying on it:** after installing, confirm that
`~/.kiro/powers/installed/tadeumendonca-skills/skills/` contains {count} directories. The `installed/`
segment is not optional and the last segment is the power name, which Kiro derives from the final
path component of the URL above. If that directory does not exist or is empty, your build predates the
format and nothing here is loaded.
"""


def main():
    out = pathlib.Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else DEFAULT_OUT
    names = skill_names()
    if not names:
        raise SystemExit("no skills found under skills/*/SKILL.md — refusing to write an empty Power")

    # Rebuilt from scratch every run. A skill RENAMED at the source would otherwise leave its old
    # directory behind, and a stale skill in the export is the drift this whole file exists to
    # prevent — invisible to a forward-only check, and shipped to a consumer as if current.
    skills_out = safe_skills_out(out)
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
