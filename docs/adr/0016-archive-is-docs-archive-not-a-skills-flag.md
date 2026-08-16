# 0016. A skill's `archive` disposition is a **file move to `docs/archive/`**, not a frontmatter flag left inside `skills/`

- **Status:** accepted
- **Date:** 2026-08-12
- **Deciders:** the owner decides; written by `tech-lead`, at intake on [#192](https://github.com/tedeuxx/tadeumendonca-skills/issues/192), ahead of the first file that needs the category (per ADR-0011's own instruction: *"settle it on the first file that needs the category, then apply consistently"*)
- **Supersedes / superseded by:** —
- **Driven by:** [#192](https://github.com/tedeuxx/tadeumendonca-skills/issues/192), executing [ADR-0011](./0011-a-skill-exists-to-be-assigned-to-a-profile.md)'s disposition 3

## Context & problem

ADR-0011 named `archive` as one of four dispositions for the 62 unassigned skills — *"publishable,
referenceable, correct, and answers no assignment question. Not a skill; not deleted either"* — and
deliberately left its mechanism open: *"a directory, a frontmatter flag, a separate plugin... The
category is named here; its shape is not decided."* #192 is where the first files reach that disposition,
so the mechanism has to be settled once, before it is re-litigated per file.

**Two mechanism facts from ADR-0011 bound every option:**

- Registration is `plugin.json`'s explicit `skills` array — an entry not listed there is not loaded, not
  counted in `Skills (N)`, and not reachable by the model's own discovery. This is the lever that controls
  token cost (`+9,919 tok` for 69 entries, ADR-0011 Context).
- `hooks/scripts/inventory-counts.test.sh` gates the tree **bidirectionally**: every declared path resolves
  to a real `SKILL.md` (forward), and — the direction this record activates — every `SKILL.md` found under
  `skills/` must be declared (reverse). The scan is rooted at `skills/`:

      grep -n "find \"\$ROOT/skills\" -name 'SKILL.md'" hooks/scripts/inventory-counts.test.sh
      → find "$ROOT/skills" -name 'SKILL.md' -type f

  ADR-0011's own Consequences section names this precondition: the reverse assertion "is only writable
  **after** this review — arriving red on 62 of 69 files is how a check gets silenced." An archive
  mechanism that leaves files inside `skills/` makes that assertion **permanently unwritable without a
  special case**, because it would have to carve out an ever-growing archived subset forever, rather than
  scoping to a tree that no longer contains them.

## Decision drivers

- **The reverse assertion ADR-0011 deferred must become writable, not re-deferred.** Whatever shape
  `archive` takes, it must let "every `SKILL.md` under `skills/` is declared" be true and stay true — not
  require the check to know which files are exempt.
- **Token cost is the reason 62 files can't just sit undeclared in place.** A file left in `skills/` with
  only a flag, and simply dropped from `plugin.json`, still risks re-discovery by anyone re-deriving the
  `skills` array from the directory tree (which is exactly how the array is currently authored/audited) —
  the flag is a convention a script has to know to check; a directory boundary is not.
- **Documentation-standard already has a home for exactly this class.** ADR-0011's test 1 rejection —
  *"knowledge that changes no behaviour is reading material, not a skill"* — is the definition of what
  `docs/` in this repo's own `documentation-standard` skill is for.
- **History must survive the move.** These files are not being rewritten to reach this disposition; a
  `git mv` that git detects as a rename keeps blame and log intact. A copy-then-delete would not.
- **Cross-references break silently.** Other skills point at these files by name (`` (see routing) ``-style
  pointers, ADR-0011's own catalogue does this throughout). Whatever the mechanism, moved files must be
  checked for inbound references before the move lands, or a live skill is left pointing at a 404.

## Considered options

1. **Move to `docs/archive/<family>/<name>.md`, drop from `plugin.json`'s `skills` array** *(chosen)* —
   physically outside `skills/`, so `inventory-counts.test.sh`'s reverse scan (rooted at `skills/`) never
   sees it and needs no special case; not loaded, not counted in `Skills (N)`, costs zero tokens; still
   git-tracked, linkable, and readable by a human landing on it directly. *Trade-off:* every archived
   file's inbound references (from still-live skills, from this Issue's own commits) have to be located and
   either repointed or left as a dead link deliberately noted — this is per-file audit work the flag
   options below don't create, because they don't move the target.

2. **A frontmatter flag (`status: archived`) on the file, left at `skills/<family>/<name>/SKILL.md`,
   removed from `plugin.json`.** *Why not:* solves the token-cost and load problem identically to option 1
   (both are gated by the `plugin.json` array), but leaves the reverse assertion exactly as blocked as it
   is today — the file is still a `SKILL.md` under `skills/`, so "every `SKILL.md` under `skills/` is
   declared" stays permanently false unless the check is taught to parse frontmatter and skip flagged
   files. That is a second, growing exception every future contributor to that test has to rediscover,
   for a check ADR-0011 already flagged as fragile enough to get silenced once.

3. **A separate plugin.** *Why not:* disproportionate. A second plugin is a second marketplace entry, a
   second version cadence, a second install step for consumers — real distribution surface for what is,
   by ADR-0011's own framing, overflow from the equipment list, not a second product. Nothing about the
   62 files' content requires independent versioning from the plugin they came from.

4. **Leave files exactly where they are, drop only from `plugin.json`, no marker at all.** *Why not:*
   ADR-0011's own record rejects this implicitly — a file that "stays where it is and stops being called
   a skill" with nothing marking that is indistinguishable from a file that was simply forgotten from the
   array, which is the exact failure ADR-0011 exists to prevent from recurring silently.

## Decision outcome

Chosen: **option 1.** Move the file to `docs/archive/<family>/<name>.md` (`git mv`, preserving history),
drop its entry from `plugin.json`'s `skills` array, and prepend a one-line provenance note — *"Archived
`<date>`, disposition per #192 / [ADR-0011](./0011-a-skill-exists-to-be-assigned-to-a-profile.md). Formerly
`skills/<family>/<name>/SKILL.md`; not loaded by the plugin."* No machine-read flag is needed on the file
itself: nothing computes over it once it is outside `skills/` — the directory boundary alone is what the
gate needs, and the provenance line is for a human who lands on the file directly.

The `<family>` segment is kept in the archive path so the human-readable grouping ADR-0011/#182 already
established for the live tree is not lost on the way out.

## Consequences

**Good**

- `hooks/scripts/inventory-counts.test.sh`'s reverse assertion — *"every `SKILL.md` under `skills/` is
  declared"* — becomes writable exactly as ADR-0011 anticipated, with **no per-file exception list to
  maintain**: the scope is `skills/`, and an archived file is not in it.
- Zero token cost for archived content — it is outside `plugin.json`'s `skills` array by construction, not
  by a convention a future editor has to remember to check.
- `git mv` keeps blame/log continuous; the archive is not a rewrite, so a future reader can still see the
  file's history as a skill before this disposition.
- One mechanism, applied to all 62 candidates alike — no per-file judgment call on *which* archive shape
  to use.

**Bad / accepted costs**

- **Every archived file needs an inbound-reference check before the move lands.** A live skill that still
  says `(see routing)` after `routing` is archived is pointing at a 404 in the published tree. This is
  real, per-file audit work — not automatic, and not deferred to a follow-up in this record.
- **The path changes**, so any external bookmark or prior citation to `skills/<family>/<name>/SKILL.md`
  breaks. Acceptable because nothing outside this repo consumes these files by path — the plugin's only
  consumer-facing surface is the invocation name, which archived files stop having.
- **`docs/archive/` is a new top-level convention** this repo's `documentation-standard` skill does not
  yet name. It should be added there as a one-line addendum once the first files land, so the placement
  rule (*"a `docs/` folder belongs to the smallest unit that owns the thing"*) visibly covers this case
  rather than leaving a reader to infer it.
- **No reverse path back to `skills/` is defined.** If a disposition is later reconsidered (an archived
  file turns out to anchor a behaviour after all), this record does not specify whether that is a
  `git mv` back or a fresh file — left to the record that reopens it, since ADR-0011's own supersede-not-
  rewrite rule already governs how a disposition decision is reversed.

## Links

- [ADR-0011](./0011-a-skill-exists-to-be-assigned-to-a-profile.md) — names the `archive` disposition and
  the mechanism facts (registration via `plugin.json`'s `skills` array; the deferred reverse assertion)
  this record resolves against.
- [#192](https://github.com/tedeuxx/tadeumendonca-skills/issues/192) — the intake Issue executing ADR-0011's
  62 dispositions; this record unblocks its disposition-3 files.
- `hooks/scripts/inventory-counts.test.sh` — the gate whose reverse assertion this record makes writable.
- `skills/documentation-standard/SKILL.md` — owns the placement rule this record's archive path
  follows; not yet amended to name `docs/archive/` (accepted cost, above).
