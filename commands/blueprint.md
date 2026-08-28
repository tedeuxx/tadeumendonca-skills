---
description: Export this harness's configuration as a portable Markdown blueprint — every obligation it holds, the mechanism that carries each one, and what each one does not do — read out of the tree at invocation and headed by the commit it describes. Use when carrying this harness's design to another project as a benchmark, or when a reader on a different harness needs to decide what is worth porting and what is local accident.
purpose: let this harness be evaluated from outside itself, by exporting the obligations it holds rather than the mechanisms it happens to run, so a reader on a harness nobody here has measured can tell a portable rule from a local accident
argument-hint: "(takes no argument — the export is the whole command; the import half is not built)"
---

Render a portable blueprint of the harness in the repository this session is rooted in.

**Read the tree. Name nothing from memory.** Every identity in the output — a hook, a persona, a
command, a skill, a count — is read at invocation from the files below, in this repository, whatever
repository that is. This command hardcodes no project's names and must never grow any: it is installed
by consumers whose trees do not look like the one it was written in, and an export that recites the
author's repository is worthless to every other reader of it.

If a file this command names does not exist here, that is **a fact about this harness to report in the
output**, not a reason to substitute what you remember. A missing registry produces an identity-only
blueprint that says so; it never produces invented obligations.

## What this produces

One Markdown document, printed in the response. **Nothing is written to the repository** — the export
is a projection, and a committed copy of a projection is a second source of truth that starts ageing
the moment it lands.

It is an **interchange format, not a report.** It has to be able to describe a harness that holds
obligations this one does not, and to leave visible the obligations this one holds and cannot carry.
That is the whole reason the rows are keyed on **what is wanted**, and the mechanism is a column.

## Step 1 · locate the harness and stamp the export

The harness root is the nearest directory containing `.claude-plugin/plugin.json`. From it:

- the plugin's own name and version — `.claude-plugin/plugin.json`, and `VERSION` if the repo has one
- the commit — `git -C <root> rev-parse HEAD`
- the branch and whether the tree is clean — `git -C <root> status --short`

**Head the document with all of it, plus the commands that reproduce every count in it.** A blueprint
without a commit is a claim with no way to check whether it is current; a reader on another harness has
none of this repository's gates and the SHA is the only instrument they get. If the working tree is
dirty, say so in the header — the export describes files, not the commit.

## Step 2 · read the identity

Four classes, each enumerated from the source that *registers* it rather than from a directory listing,
because a file present and unregistered is not a mechanism:

| class | enumerate from |
|---|---|
| hook | the commands registered in `hooks/hooks.json`, with the event each is registered on |
| persona | the briefs in `agents/` |
| command | the typed commands in `commands/` |
| skill | the paths declared in `.claude-plugin/plugin.json` |

Each mechanism declares a one-line `purpose:` — line 2 of a hook script, a frontmatter key in a
markdown mechanism. **Read it; never paraphrase it and never substitute the `description:`.** The two
answer different questions: a description says *when to reach for this*, a purpose says *why it exists
and what is lost without it*, and only the second one ports.

## Step 3 · read the obligations

The obligations live in an authored registry — `docs/blueprint-registry.md` in a harness that keeps
one. It is the artifact; this command renders it and **never writes it**. Read its rows whole: `id`,
`tipo`, `carrier`, and the three authored cells that carry the value — what the obligation is for, what
actually happens, and **what it does not do**.

**If the repository has no such registry, produce the identity-only blueprint** — the mechanisms and
their purposes, under a header stating in one sentence that this harness publishes identity and has not
authored its obligations. That is a true and useful export. Inferring obligations from file names is
not; it would put the model's guesses in a document a reader will treat as this harness's own account
of itself.

## Step 4 · render

Sections, in this order:

1. **Header** — plugin, version, commit, branch, tree state, date, and the reproduce commands.
2. **How to read a row** — the field contract, copied from the registry's own statement of it, so the
   document is self-describing to someone who has never seen this format.
3. **What no gate here can hold** — carried from the registry, above the rows. A reader must meet the
   residual before meeting the content: the purpose cells are unfalsifiable by any instrument, and a
   blueprint that hides that is selling a green it does not have.
4. **The obligations**, grouped by `tipo`, each row with its `enforcement` value and its carrier.
5. **Coverage** — which classes the harness claims completeness over, and, for a class declared
   partial, **the unclaimed elements by name**. Silence about a gap reads as compliance; a named gap
   reads as a gap.
6. **Identity appendix** — every mechanism, its class, its registration point and its `purpose:`. This
   is evidence that the rows are real rather than aspirational. **It is never the spine**: a spine made
   of one harness's mechanism names can only describe harnesses shaped like that one.
7. **Abandoned obligations** — the registry's tombstones, if it holds any. An empty table is a
   statement and is printed as one.

## The format — the part a foreign harness has to be able to fill in

**A row is an obligation, not a file.** One obligation may be carried by two rules of one file, by
three files, or by **no file at all**; one file may carry two obligations. A format keyed on files can
express none of that, and it is exactly what a reader on a different harness cannot use — their files
are not yours, and their obligations might be.

**`carrier` is nullable.** The literal `none` means *this harness states this obligation and nothing in
it carries the obligation*. That is a row, never an omission.

**`enforcement` is a closed set of four, and three of them are one axis:**

| value | means |
|---|---|
| `denies` | it can stop the actor **before** the act |
| `advises` | it produces a judgement and nothing more |
| `documents` | it removes a re-decision — the actor reaches for it and does not decide again |
| `absent` | the obligation is stated and not carried here (`carrier: none`) |

**The axis measures refusal only, and this is stated in the format rather than fixed by adding a
value.** A mechanism that *acts* — one that writes a comment, posts a measurement, appends to a record
— refuses nothing, so it lands in `documents` beside a body of guidance that does something else
entirely. That is a real strain and naming it is cheaper than a fourth value, for two reasons a
consuming reader can check: the axis is consumed by inventories that key on it with a **closed** set
and throw on an unknown value, so a fourth value breaks the readers rather than informing them; and the
distinction it would carry is already carried by `tipo`, where an acting mechanism is `record` and a
body of guidance is `knowledge`. **Read `documents` as "does not refuse", never as "does nothing".**

**A closed set is the point.** A free-text enforcement column refuses nothing and compares to nothing;
two harnesses filling it in freely produce two vocabularies and no comparison.

## What the export must never do

- **Never write a file.** Not the registry, not a cached copy of the output, not a scratch artifact.
- **Never invent a row**, and never derive one from a file name. An obligation nobody authored is a
  guess wearing the format's authority.
- **Never read a harness's private material.** Out of scope absolutely — a paraphrase of it in an
  exported document is a leak with a currency header on it, and in a repository that does not ignore
  the private path it is a leak into a tracked file. This is a rule about **what a file is**, not about
  whether it is committed: a mechanism this harness ships that is registered but not yet committed is
  still read, and the header already says the tree is dirty.
- **Never present the mechanism as the instruction.** The carrier is evidence. What ports is the
  obligation, the strategy at a grain a foreign implementer could rebuild, and above all **the limit**
  — a limit is a property of the strategy, so it survives the mechanism not surviving.

## If `$ARGUMENTS` is not empty

**Say plainly that the import half is not built, and stop.** Do not attempt to read the argument as a
foreign blueprint, and do not improvise an evaluation of it.

The reason is worth repeating to whoever typed it, because it is not an omission: a parser tested only
against documents its own authors wrote verifies nothing — parsing a format you also write always
passes. The import half waits on **one real foreign blueprint**, produced by a harness nobody here
controls. If the argument *is* such a document, that is the event that unblocks the work: report it to
the owner rather than consuming it here.
