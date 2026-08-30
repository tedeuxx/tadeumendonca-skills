---
description: Exchange harness configurations across projects — render this harness's obligations as a portable blueprint, or triage a foreign one into the few adoption decisions the owner actually has to make. Use when carrying this harness's design to another project as a benchmark, when a reader on different machinery must tell a portable rule from a local accident, or when a blueprint produced elsewhere needs comparing against what is already here.
purpose: let this harness be evaluated from outside itself and let a foreign harness's design be evaluated from inside it, by exchanging obligations rather than mechanisms, so what ports is separable from what is local accident and no configuration is ever copied blindly
argument-hint: "export | import <path-to-a-foreign-blueprint> | (no argument prints help and does nothing)"
---

Exchange harness configuration with a project on machinery nobody here has measured.

## The three modes

Resolve `$ARGUMENTS` to exactly one row. **The first token is the mode. Nothing else is.**

| mode | what it does | writes |
|---|---|---|
| `export` | renders this harness's obligations as a portable blueprint, in two shapes | the session scratchpad |
| `import` | triages a foreign blueprint and conducts the adoption decisions with the owner | the session scratchpad |
| *(no argument)* | prints the help below and stops | nothing |

**Bare `/blueprint` prints help and does nothing else.** No file, no interview, no export, no implicit
effect of any kind. The help states what each mode does, what each writes, and where. This is a change:
the command exported on a bare invocation until 2026-08-29, and a typist who learned that behaviour will
be surprised. That is the point — a mode that has to be named cannot be entered by accident, and an
unresolved first token fails loudly instead of doing something nobody asked for.

**An unrecognised first token is refused by name.** Print the table above and stop. Do not guess that
`/blueprint exprot` meant `export`, and do not fall through to a mode: a mode chosen for the typist is
the failure this dispatch table exists to remove.

**Read the tree. Name nothing from memory.** Every identity in either mode's output — a hook, a persona,
a command, a skill, a count — is read at invocation from the files below, in this repository, whatever
repository that is. This command hardcodes no project's names and must never grow any: it is installed
by consumers whose trees do not look like the one it was written in, and an export that recites the
author's repository is worthless to every other reader of it.

If a file this command names does not exist here, that is **a fact about this harness to report in the
output**, not a reason to substitute what you remember. A missing registry produces an identity-only
blueprint that says so; it never produces invented obligations.

---

# Mode: `export`

## What this produces

Two artifacts from one read, in one invocation:

1. **A Markdown document, printed in the response** — the human-readable blueprint, for a reader.
2. **A YAML document, written to the session scratchpad** — the machine-readable interchange form, for
   another harness's import.

**Both are rendered from one read of the registry and the tree.** Two renderers over one read cannot
drift, because there is no interval between them; two commands can, which is why this is one invocation
and not two.

**Print the scratchpad path in the response.** The file is the thing being handed over, and a handover
artifact whose location is not stated is not a handover.

## Where the output goes, and the rule that decides it

**Never write inside a repository.** Not the registry, not a cached copy of the output, not a scratch
artifact, not a `tmp/` directory in a tracked tree. **The export writes to the harness's own session
scratchpad and nowhere else** — the path the harness hands the session at start, session-specific and
outside every tracked tree by construction.

**The test this rule encodes is *can anything resolve this file later?*** A committed projection is a
second source of truth that starts ageing the moment it lands; so is an uncommitted one sitting at a
predictable path inside a tree, because the next reader finds it and reads it as configuration. A
scratchpad path is in no diff, in no gate's input, and reachable by no consumer — so it cannot become a
source of truth, which is what makes writing it safe.

~~**Never write a file.** Not the registry, not a cached copy of the output, not a scratch artifact.~~
**Struck 2026-08-29.** It was the right rule stated one notch too wide: it forbade the *handover
artifact* in order to forbid the *ageing copy*, and an interchange with nothing to hand over is not an
interchange. Struck rather than deleted because it stood from 2026-08-28 and is quoted in the registry
row that describes this command — the narrowed sentence above is what that row now quotes.

**A repository-relative output path is refused even where it would work.** Measured on 2026-08-29
against `hooks/scripts/orchestrator-write-guard.sh`, one variable, payload `{"agent_type":"",
"tool_name":"Write"}`: a `file_path` inside a git working tree returns `permissionDecision: deny`; the
same path outside every tree returns nothing, which is allow. **A typed command runs in the main session,
whose `agent_type` is empty by construction, so the deny is the ordinary case rather than the exotic
one** — and in the single-repository shape most consumers install, a workspace-relative `tmp/` *is*
inside the tree. The same instruction would then produce two behaviours decided by a property of the
reader's machine, which is why the destination is the scratchpad and not a path relative to anything.

## Step 1 · locate the harness and stamp the export

The harness root is the nearest directory containing `.claude-plugin/plugin.json`. From it:

- the plugin's own name and version — `.claude-plugin/plugin.json`, and `VERSION` if the repo has one
- the commit — `git -C <root> rev-parse HEAD`
- the branch and whether the tree is clean — `git -C <root> status --short`

**Head both documents with all of it, plus the commands that reproduce every count in them.** A blueprint
without a commit is a claim with no way to check whether it is current; a reader on another harness has
none of this repository's gates and the SHA is the only instrument they get. If the working tree is
dirty, say so in the header — the export describes files, not the commit.

**Read the canonical source, never an installed copy.** The tree this session is rooted in is the
source; a plugin cache under a version directory is an installed build and may be behind it. If you
cannot establish that you are reading the canonical source, **stop and report that limitation** rather
than emitting a blueprint that may describe a build nobody is running.

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

## Step 4 · render the Markdown document

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

## Step 5 · render the YAML document

The interchange shape, one entry per registry row:

```
format_version: "1.0"
source:
  harness: <the plugin's own name, read from plugin.json>
  config_version: <VERSION, or the plugin manifest's version>
  generated_at: <ISO-8601 timestamp>
  commit: <the SHA from step 1>
  tree_clean: <true|false>
mechanisms:
  - id: <the registry's four-digit id, unprefixed>
    prevents: <the failure the obligation exists to prevent>
    surface: <one of the surface values below>
    always_loaded: <true|false>
    evidence_class: <measured|documented|unknown>
    note: <optional>
    does_not: <the limit, carried across from the registry>
    enforcement: <denies|advises|documents|absent>
```

**Translate on export. Do not reshape the registry.** The registry is the authored artifact and this is
a projection of it (ADR-0021); reshaping the artifact to suit one consumer inverts that, and the
registry's Portuguese field labels are a parsing contract this repository's own gate reads literally, so
renaming them moves gate arms for no interchange benefit.

| registry field | interchange field | how |
|---|---|---|
| `id` | `id` | verbatim, four digits, unprefixed — `source.harness` is the namespace |
| `propósito` | `prevents` | the failure it prevents, stated as a failure rather than as a virtue |
| `carrier` | `surface` | by the class of the carrier — see the table below |
| — | `always_loaded` | derived — see below |
| — | `evidence_class` | authored — see below |
| `o que faz` | `note` | the reproduction grain, redacted per the rule below |
| `o que não faz` | **`does_not`** | verbatim in substance — an **optional extra field** |
| `tipo` + the enforcement axis | **`enforcement`** | an **optional extra field** |

**`does_not` and `enforcement` ride along as optional fields, and the authority for that is the
interchange format's own compatibility rule** — *a reader must ignore unknown fields, and adding an
optional field is a compatible change.* So **the limit column is not dropped**, which matters more than
it looks: the limit is the one cell that *ports*, because a limit is a property of the strategy and
survives the mechanism not surviving. An interchange that carried only the mechanism would transmit
exactly the half that does not travel.

**A conforming foreign reader ignores both fields and loses nothing it was promised. A
non-conforming one may reject the document, and that is a fact about that reader.** Say so in the
header rather than trimming the export to suit a reader nobody has measured.

### The surface values, and the two this harness has no instance of

| carrier class | `surface` |
|---|---|
| a hook registered in `hooks.json` | `hook` |
| a persona brief in `agents/` | `agent-profile` |
| a skill or a typed command | `skill` |
| an entry in a `settings.json` permission layer | `permission-rule` |

**`manual-steering` and `always-loaded-steering` are surfaces of the format that this harness has no
instance of, so no row is emitted under them.** Do not invent an entry to fill a surface out — an
invented row is a guess wearing the format's authority, and the format's own rule forbids it.

**Where one obligation's carriers span two classes, emit the surface of the carrier that performs the
obligation and name the others in `note`.** The obligation is one thing; the field takes one value.

**A `carrier: none` row is emitted with `surface: none` and `enforcement: absent`, and the header
declares that as this harness's one deviation from the schema.** The alternative is to pick a surface
for an obligation that nothing carries, which is exactly the invention forbidden above. **The limit is
real and is stated rather than hidden: a strict reader keyed on a closed surface set may reject the
value**, since the compatibility rule covers unknown *fields* and not unknown *values*. Emitting it is
still the better failure — a rejection is visible, and a fabricated surface is not.

### `always_loaded` — derived, and lossy in a way worth stating

Emit `true` where the mechanism consumes context on every interaction of some actor: a skill named in
any persona's `skills:` preload, or a persona brief within its own dispatch. Emit `false` for a hook, a
permission rule and a typed command — none of them costs context until something invokes them.

**Here it is a per-persona property and there it is a per-mechanism field.** The emission is therefore
the disjunction — `true` if *any* profile preloads it — and the resolution is lost. Name the preloading
profiles in `note` so a reader can recover what the field flattened.

### `evidence_class` — a closed set of three, and the default is `unknown`

| value | means |
|---|---|
| `measured` | the behaviour was exercised in this harness |
| `documented` | documentation or a record asserts the behaviour; nothing exercised it |
| `unknown` | the behaviour has not been established |

**Default to `unknown`, never to `documented`.** Defaulting up publishes a stronger claim than the
harness has, and the two failure directions are not symmetric: an under-claim is corrected in one edit
by whoever notices, and a quiet over-claim ships and is believed.

**The evidence is relative to this harness and does not travel.** A mechanism `measured` here is not
measured in the harness that imports it — which is what the import half's `not measured here` standing
exists to hold.

**Nothing can falsify this field.** It is self-declared, and a model can write `measured` without
measuring, exactly as `owner-take: not-supplied` can be written without asking. It earns its place as a
**discipline with a marker** rather than as a verified fact, and this sentence is the marker. What a
gate can hold is closed-set membership and nothing else.

### Stable ids — the registry is the authority, and the interchange rule has a defect

The registry already satisfies every stability requirement the format states: an id is assigned once,
never reused, never re-sorted; a rename changes the name, a consolidation changes the carrier, and
neither changes the id; an abandoned id is tombstoned rather than freed. **There is nothing to build
here and no cross-harness id authority is needed** — the format asks for a *mapping* between a foreign
id and a local one, and `source.harness` namespaces both sides.

**The format's own id rule is circular for a harness with no registry, and the export says so.** It
requires consulting prior exports before assigning an id, while also requiring that those exports be
ephemeral and deletable. Here that is harmless — the registry is the durable id source and prior exports
are never consulted. For a harness whose only id source *is* its exports, the stability rule depends on
an artifact the ephemerality rule destroys. **Report that back to whoever supplied the format.**

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

- **Never write inside a repository**, per the rule stated above. The scratchpad, or nothing.
- **Never invent a row**, and never derive one from a file name. An obligation nobody authored is a
  guess wearing the format's authority. The same holds one level up for a surface: an empty surface is
  a fact about the harness, not a cell to fill.
- **Never read a harness's private material.** Out of scope absolutely — a paraphrase of it in an
  exported document is a leak with a currency header on it, and in a repository that does not ignore
  the private path it is a leak into a tracked file. This is a rule about **what a file is**, not about
  whether it is committed: a mechanism this harness ships that is registered but not yet committed is
  still read, and the header already says the tree is dirty.
- **Never present the mechanism as the instruction.** The carrier is evidence. What ports is the
  obligation, the strategy at a grain a foreign implementer could rebuild, and above all **the limit**
  — a limit is a property of the strategy, so it survives the mechanism not surviving.

---

# Mode: `import`

`$ARGUMENTS` after the mode is a **path to a document the owner supplied**. Read that path and nothing
else.

## What import never does

- **Never fetch.** No URL is read on this command's own initiative, ever — not one named in the
  document, not one the owner mentioned in passing, not a redirect. If the document is somewhere this
  command cannot read from disk, say so and stop.
- **Never run on a schedule**, and never look for a document nobody handed over.
- **Never modify local configuration.** Not a skill, not a persona brief, not steering, not a decision
  record, not a permission layer, not an installed build. Import produces a triage and, on the owner's
  approval, a tracked backlog item. **It never applies anything.**
- **Never write inside a repository**, exactly as the export half does not. The triage record goes to
  the session scratchpad.

**Nothing mechanical holds the no-fetch rule.** The permission guard reads shell commands and a network
tool never reaches it, so this rule's carrier is this command's own text and its enforcement is
`documents`. **That is a row in the registry, not an omission** — do not let the absence of a control be
read as the presence of one.

## Triage before asking

Classify **every** mechanism in the document into exactly one of five classes. **Apply the order
below**, not the order the classes are described in — the order is what makes the classification
deterministic when a mechanism qualifies for two.

1. Does it already exist locally? → **class 1**
2. Was it explicitly rejected by a recorded decision? → **class 4**
3. Is it incompatible with a local limit, a live decision or a measured constraint? → **class 5**
4. Has the failure it prevents been measured locally? → **class 2**
5. Otherwise → **class 3**

| class | the mechanism is | questions | what the record must carry |
|---|---|---|---|
| 1 | already here, possibly under another name or on another surface | 0 | the mapping from the foreign id to the local id, and any difference in surface or evidence |
| 2 | absent, and it prevents a failure measured here | 2 | the local evidence |
| 3 | absent, and speculative — no local evidence of the failure | 2 | the speculative marking, in those words |
| 4 | already rejected by a recorded decision | 0 | the record, cited by quoting its clause or heading |
| 5 | incompatible with a local limit or a live decision | 0 | the authority or the measurement that makes it incompatible |

**Silence is for questions, never for the record.** Classes 1, 4 and 5 ask the owner nothing — that is
the discipline worth having, and it is what makes an import produce a handful of real decisions instead
of a list. **But a wrong classification into those three produces exactly the same silence as a right
one**, so every class-1, class-4 and class-5 verdict is **enumerated in the triage record with its
citation, and the enumeration is presented to the owner** even though it asks nothing. An unasked
question he can see is recoverable; one he cannot is not.

**Class 4 has no consultable substrate here, and that is a limit rather than a step.** This repository
keeps a decision library, not an index of rejections: *was this rejected?* is answered by a model
reading prose across the records, and there is no query that returns the set. **A class-4 verdict is
therefore a claim, and it is presented as one** — cite the record by quoting its clause or heading,
never by line number, and where no record can be cited the mechanism is not class 4.

## The interview

**Only classes 2 and 3 generate questions. One mechanism at a time. Never a batch.**

For each, exactly two questions, in this order:

1. **What does it prevent, and have we observed that failure here?** For class 2, present the local
   evidence. For class 3, mark it speculative in those words and do not present it as a proven need.
2. **What does it cost?** Which local surface would carry it, and would that surface be loaded on every
   interaction?

**Wait for the owner to approve, reject or defer before presenting the next mechanism.** A batch of
decisions is not a faster interview; it is a worse one, and this repository has already paid for that.

## Adoption — what happens when the owner approves

**File one tracked `loop` item, and do not ask again whether to file it.** The approval in the interview
is the authorization.

**That reading is political, not measured, and it is the owner's to overturn.** The standing rule here is
that **only the owner opens work**, and the guard enforces it by denying `gh issue create` to every
dispatched persona. The reading taken is that the rule is about **origination**, and origination here is
his: he approved this mechanism, one at a time, in an interview. **It narrows a standing rule by
interpretation, it is stated out loud for exactly that reason, and if he disagrees the correct behaviour
is to present the item and let him file it.** Nothing can gate this — no command string distinguishes
*the owner approved* from *the model says the owner approved* — and no attempt should be made to.

**Filing works today only from the main session.** Measured 2026-08-29 against
`hooks/scripts/permission-guard.sh`, one field varying: `gh issue create` with an `agent_type` naming a
dispatched persona is denied; the same command with the orchestrator's empty `agent_type` is allowed.
`/blueprint` is a typed command and runs in the main session, so the filing route is open. **If any part
of the import is ever delegated to a subagent, the filing is denied** — that is a build constraint, not
a policy question.

The filed item carries:

- the source harness, **by function only** — see the redaction rule below
- the export's `format_version` and `config_version`
- the foreign `id` of the mechanism
- the failure it prevents
- the evidence class the exporting harness declared
- the owner's answers to both questions
- the local surface proposed, and whether that surface loads on every interaction
- the literal **`not measured here`**

**`not measured here` is the adoption's local standing, not a fourth evidence class of the format.** It
is what stops a `measured` from another harness laundering itself into a local claim.

**The item gets NO milestone and does NOT get `ready`.** The format says not to schedule an adopted item,
and since #365 the local rule agrees with it: nothing is admitted to a running iteration automatically,
so an adopted item is composed at planning like everything else.

~~**The item gets the active iteration's milestone and does NOT get `ready`.** … **Where the two rules
conflict on the same act, the local rule wins**, and the reason is stated rather than assumed: it is the
newer decision, it is the owner's own, and an adopted item with no milestone is invisible to the queue
by construction.~~

**Struck 2026-08-30 (#365). The conflict it adjudicated no longer exists** — the local rule it invoked
(#338) is itself struck — **and it is struck rather than edited because its REASONING was the defect, not
its conclusion.** *"An adopted item with no milestone is invisible to the queue by construction"* is
false in the way that matters: the queue predicate requires `ready`, which this same paragraph correctly
says the item does not get. The item was already out of the drain on the `ready` predicate, and the
milestone bought nothing but a changed completion bar on an iteration nobody had decided to change.
**This instruction was written six hours after #338 merged and was already acting on it, which is why
the strike is here and not only in the rule's home file.**

**Also note what did NOT need to change: the guard now refuses the old form anyway.** `permission-guard.sh`
rule 10 denies `gh issue create --milestone` to every dispatched persona, so if any part of an import is
ever delegated, the struck instruction is unexecutable rather than merely stale.

**Do not route the item into a batch, and do not name one.** Whether adopted items are later grouped is
a separate decision with its own tracked item; referencing a batch that has not been composed would make
this command depend on a mechanism that does not exist.

## The provenance redaction rule — function only, never internals

**The source harness is named by FUNCTION and by nothing else.** *"a harness on another agent platform"*
is a source; an internal path, a system name, a board or ticket reference, a host, a person, or a
verbatim span of the foreign document is not, and none of them is reproduced in a filed item, in a
comment, or in the triage record.

**This is the highest-cost rule in this mode and it is the one with no control behind it.** An adoption
item is filed on a **public** tracker in a **public** repository, and the format's `note:` field is
defined to carry *"reproduction notes, limitations or origin"* — which is exactly where an internal path
or a system name lives. A leak there is not reverted by deleting the comment; the surface is public and
the copy is already made. **The one containment rule this harness holds for the analogous case is
mechanical** — the personas that read private material are denied every posting route — **and it does
not reach this case at all**, because the actor filing is the orchestrator and the material is foreign
rather than local.

**`enforcement: documents`. There is no gate here and none is claimed.** No hook can hold it: a posted
body travels through `--body-file`, so the text is never in the command string a `PreToolUse` hook sees,
and a guard keyed on the content would fire only on the inline form this repository already forbids —
a control that is inert exactly where it would need to work. **Read this rule as a rule, and read the
absence of a control as an absence.**

## The triage record

Write it to the session scratchpad, and print the path. It carries the full triage — every class-1
mapping, every class-4 rejection with its citation, every class-5 incompatibility with its authority,
the owner's answers for classes 2 and 3, and the references of any items filed.

**The mapping does not persist, and that is accepted rather than repaired.** The record is ephemeral by
design, so a second import of the same foreign harness re-derives every class-1 correspondence from
scratch and may map differently. **The mapping is advisory, re-derivation is cheap, and the only fix — a
committed mapping file — is precisely the second source of truth this whole design refuses.** Say so in
the record so a later reader does not treat a mapping as durable.

---

# What no gate here can hold

**Neither mode's content is verified by anything.** The suite asserts that this command exists, is
typed, declares one purpose, declares its modes consistently, and is claimed by registry rows whose
quotes resolve. It cannot assert that a rendered blueprint is faithful to the registry, that a
classification is correct, that a redaction was performed, or that a filing carried what it should —
**the render and the triage are a model reading a file**, which is the same residual the registry
already states about its own unfalsifiable cells, one surface further out and one degree weaker.

**Read a green in this repository as saying nothing about any of it.**
