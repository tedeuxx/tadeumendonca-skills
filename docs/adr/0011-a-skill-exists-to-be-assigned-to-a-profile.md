# 0011. A skill exists to be **ASSIGNED to a profile in the loop's roster** — *to which profile is this assigned, and why?* is the operative test, and a skill assigned to nobody has no reason to exist whatever its quality; what it standardises is a **behaviour**, transversal, persisting across sessions

- **Capability:** skills-and-preload
- **Status:** accepted · amended 2026-08-13 (a fifth disposition, scoped to the three technical
  families — `cloud-infrastructure`/`backend`/`frontend` consolidation, per-family, curated on the owner's preferred
  pattern rather than exhaustive merge; the process-family four-way framework is untouched)
- **Date:** 2026-08-11
- **Deciders:** the owner (he arrived at the definition across a conversation and ordered it recorded; his sentences are quoted verbatim and unparaphrased in *Decision outcome*); written by `tech-lead`; measurement input from `harness-lead` on [#183](https://github.com/tedeuxx/tadeumendonca-skills/issues/183), cited per finding below
- **Supersedes / superseded by:** —
- **Driven by:** [#183](https://github.com/tedeuxx/tadeumendonca-skills/issues/183)

## Context & problem

The library has **69 skills** and no written definition of what a skill *is*. Every other property of it
is recorded — how a description is written ([ADR-0009](./0009-a-skill-description-is-a-trigger-not-a-title.md)),
how one reaches a persona ([ADR-0010](./0010-a-personas-startup-context-is-a-curated-preload.md)) — and
the thing those two records are about was left to be inferred from the folder it sits in. The definition
below was arrived at in conversation and existed nowhere in the tree.

**Why that gap has cost rather than merely being untidy.** Without a definition there is no test, so
three questions have been answered by folder and by habit:

1. **What belongs in the library at all.** The existing project-agnostic lint passes on all 69 files —
   re-derived here, not relayed:

       grep -rnoE 'apps/(fed|bff)|tadeumendonca([-.][A-Za-z]+)*' --include=SKILL.md skills \
         | grep -vE ':tadeumendonca-skills$' | wc -l
       → 0

   The library carries no consumer identifiers and is still full of one retired application's shape. The
   lint sees **names**; nothing sees **shape**.

2. **Who a file is written for.** `agents/product-lead.md` preloads `new-issue`, which is a **command** —
   the human's surface, addressed to the owner, carrying `argument-hint`. Measured:

       grep -rn "^argument-hint:" skills commands
       → commands/autonomy-on.md:3 · commands/new-issue.md:3   (exactly 2, and 0 under skills/)

3. **Which agents a rule reaches.** Of the **14 process skills** under `skills/principles/` and
   `skills/workflow/`, **8 are preloaded by nobody** — including `dev-loop`, the file that defines the
   loop every persona runs. Six are loaded by anyone at all, and **four of those by exactly one persona**:

       find skills/principles skills/workflow -name SKILL.md   → 14
       grep -rn -A6 '^skills:' agents/                          → the ten entries
       loaded by nobody: dev-loop · loop-engineering · permissions-and-environments ·
                         claude-code · github-actions · license · terraform-cloud · versioning
       loaded by 2: engineering-philosophy · verification-and-gates
       loaded by 1: adr · code-review · documentation-standard · sonarcloud

~~**The consequence is a live defect, not a design worry, and it is the evidence for this record.**
Because the definition does not reach the persona that applies it, what reaches that persona is the
**copy in its brief** — and the copy and the source have drifted:

    grep -rn "own authority\|loop's own rules\|expansion of its own" agents/ skills/principles/dev-loop/SKILL.md
    → 2 hits, BOTH in skills/principles/dev-loop/SKILL.md (475, 477). ZERO in any brief.

Two clauses exist only in the skill nobody loads — ***"a change to the loop's own rules"* is boundary
class**, and ***the gate never merges an expansion of its own authority*** — while three exist only in
`agents/quality-assurance.md:714-716` (`new architecture`, `contract/schema change`, `creates or changes
an ADR's decision`). The one persona that applies the class is `quality-assurance`, and **its list does
not contain *a change to the loop's own rules*.** A slice implementing this Issue is a change to the
loop's own rules. Found by `harness-lead` on #183 §2; the grep above was re-run here.~~

**FALSIFIED — marker placed 2026-08-13, closed by [#224](https://github.com/tedeuxx/tadeumendonca-skills/issues/224)/[#237](https://github.com/tedeuxx/tadeumendonca-skills/pull/237).**
The drift this paragraph reports no longer exists: `skills/principles/dev-loop/SKILL.md` was folded into
`skills/harness-engineering/SKILL.md` by that consolidation, and both clauses now live in
`agents/quality-assurance.md:737,744` alongside the three that were already there. Re-run of the same
grep, against the current tree:

    grep -rn "own authority\|loop's own rules\|expansion of its own" agents/ skills/harness-engineering/SKILL.md
    → 3 hits, all in agents/quality-assurance.md (737, 744, and the original three merged with these two)

**What this costs the record, said here so a reader does not have to infer it:** this paragraph was the
**evidence** for the decision this ADR records, not the decision itself — the definition-as-test argument
in *Decision outcome* below does not depend on this specific drift and still stands. What is contested is
only the *present-tense* claim that the drift is live; it is closed, and citing this paragraph as current
evidence of an ongoing defect is now wrong. Struck rather than deleted, per this repo's supersede-never-
delete convention: this is the premise the decision was argued from, and it must stay legible even after
the world it described has changed under it.

**Two mechanism facts bound every option below.**

- **`skills:` frontmatter preload is the only channel into a persona.** `Skill` is not grantable through
  `tools:` ([#177](https://github.com/tedeuxx/tadeumendonca-skills/pull/177) removed
  [#171](https://github.com/tedeuxx/tadeumendonca-skills/issues/171)'s inert grant), and a persona
  receives no skill index, so **on-demand invocation from inside a persona does not exist.** Model
  invocation is a **main-agent** mechanism. *Untested and named as such:* whether a persona that omits
  `tools:` entirely would inherit `Skill`. Nobody has measured it.
- **The library was not reachable at all until 2026-08-10.** The loader's index reported **`Skills (2)`**
  before [#182](https://github.com/tedeuxx/tadeumendonca-skills/pull/182) moved the tree from
  `commands/<family>/<name>.md` to `skills/<name>/SKILL.md`, and **`Skills (71)`** after — booked in
  [ADR-0005](./0005-plugin-auto-versions-on-merge.md)`:146-149` at +9,919 always-on tokens per session.
  So ADR-0009's 69 dense trigger descriptions had **no consumer** for as long as they existed.

One correction the record owes to itself, stated here and deliberately **not** written as an amendment:
**[ADR-0010](./0010-a-personas-startup-context-is-a-curated-preload.md)'s Context item 2 — *"there is no
path to read"* — is false**, and I re-derived both halves in the shell that wrote this record:

    printenv CLAUDE_PLUGIN_ROOT              → exit=1        (ADR-0010 is right about this)
    printenv PATH | tr ':' '\n' | grep 'plugins/cache'
    → /Users/…/.claude/plugins/cache/tadeumendonca/tadeumendonca-skills/0.4.56/bin

An unset environment variable is not the absence of a path. The plugin root is derivable from the `bin`
entry Claude Code appends to `PATH`, and a persona holding `Read` and `Bash` can read the library from
disk. That makes every exclusion under ADR-0010 a **deferral** rather than the *"real deprivation"* that
record calls it. **Why no amendment here:** it is a correction to that record's premise, not part of this
decision; one decision per ADR; and `harness-lead` is mid-audit on exactly that clause, so a
correction written from this side risks two records disagreeing about the same measurement. **What stops
the false premise reading as current is a falsification marker placed IN ADR-0010, at the clause itself**
— its Context item 2, struck, linked forward here, and naming which of its own conclusions the
falsification makes contested. This paragraph is not that pointer and was published claiming to be one;
it is the measurement the marker points at. **The full amendment is still owed to ADR-0010, and a marker
is not an amendment.** Note the difference in kind before anyone treats disk access as a substitute for
preload: **the model must decide to go and read, and a dispatch that fails to decide fails silently.**

## Decision drivers

- **A definition is only worth recording if it is a test.** A description admits; a test also *rejects*.
  The one that cannot reject a plausible candidate settles no argument.
- **The context window is the constraint the roster is built around** (ADR-0002, tenth amendment). Any
  definition that implies a preload is spending that budget before the persona reads a line of the work.
- **A rule that reaches nobody is not a control.** ADR-0004's standing question applies to this record as
  much as to a hook: which layer can carry *"every persona follows this"*, and can it hold it?
- **Duplication has no comparator.** Two statements of one practice, in two files, with nothing comparing
  them, drift — measured above, not hypothesised.
- **The published artifact must be usable by someone whose stack is not the owner's.** Stated by the
  owner on #183: *"os skills não podem ser especializados por iniciativa, eles têm que ser genéricos para
  o workflow que queremos publicar."*

## Considered options

1. **A skill is the standardisation of a behaviour, applied transversally by agents** *(chosen)* — one
   definition of a behaviour, reachable by the several agents it binds, with **behaviour as the unit and
   transversality as the membership condition**. *Trade-off:* it makes part of the current library **not
   skills** by its own test — including files that are correct, generic and well written — which is a
   cost paid immediately in rewriting or cutting; and a preload is **frozen at the session's plugin
   build**, so centralising changes where a rule lives without making it current.

2. **Leave the procedure duplicated across the five briefs** — the incumbent. *Why not, and it deserves
   more than a dismissal:* **the duplication WAS the control, and it was correct.** Until #182 the
   loader index reported `Skills (2)`; no mechanism reached a subagent, so writing the rule into every
   brief was the only way any persona could receive it. That defence expired on 2026-08-10. What
   disqualifies it now is measured rather than asserted — five copies with no comparator have already
   drifted from their source, and the clause that went missing is the one governing this very change.
   Cost of keeping it: **20,777 B of duplicated operating hygiene**, re-derived here, and one more
   divergence per edit that touches four files instead of five.

       for a in developer product-lead tech-lead quality-assurance harness-lead; do
         f=agents/$a.md
         w=$(awk '/^## Working files/{p=1} p&&/^---$/{exit} p' $f | wc -c)
         c=$(awk '/^## Command hygiene/{p=1} p&&/^---$/{exit} p' $f | wc -c)
         printf "%-20s wf=%5d ch=%5d\n" "$a" "$w" "$c"; done
       → developer 1310/3121 · product-lead 1290/3613 · tech-lead 1310/2553
         quality-assurance 858/3045 · harness-lead 1079/2598      sum = 20,777

3. **A universal floor — every persona preloads all of `skills/principles/*`.** *Why not:* **rejected
   already, and the rejection stands** ([ADR-0010](./0010-a-personas-startup-context-is-a-curated-preload.md),
   option 3). It allocates by **family** where the cost is **bytes**. Re-derived at the library's current
   location — ADR-0010's `76,490 B` was measured on `commands/` before the #182 move:

       find skills/principles -name SKILL.md -exec wc -c {} +
       → dev-loop 38,541 · permissions-and-environments 11,129 · loop-engineering 10,880
         verification-and-gates 8,345 · engineering-philosophy 7,164   → 76,059 B, ×5 = 380,295 B

   Its second reason is untouched by this record and is the stronger one: the floor hands
   `quality-assurance` `engineering-philosophy`, **a ruler with no falsifier**, to the one persona whose
   ruler must be external. **What this record does correct is the object that arithmetic was priced
   against**, not the arithmetic: a skill holding only the transversal operating rules is ~5 KB — about
   **6.5%** of the floor — so **ADR-0010's figure does not reach a small transversal skill and should not
   be cited against one.** `harness-lead` measured centralising the hygiene rows as roughly
   **byte-neutral** (~20,777 B inline today against ~25,000 B billed across five). **The case for this
   definition is correctness, not saving** — a *"we saved bytes"* framing is falsifiable in one command
   and would be false.

4. **One skill per persona** — a `developer-skill`, a `gate-skill`, and so on. *Why not:* it reproduces
   the per-persona framing that produced the drift in the first place. Five files that each state the
   whole procedure is the incumbent with a different file extension, and the comparator is still missing.
   It also fails the chosen test by construction: a definition scoped to one persona is not transversal,
   and its correct home is that persona's brief.

## Decision outcome

Chosen: **option 1.** The definition is the owner's, in his words, and it is recorded **unparaphrased**.
The three sentences arrived one at a time across a conversation, each correcting a framing that had been
offered and was wrong — *norm versus knowledge*, *stack-free versus generic*, *repeated behaviour versus
transversal*. **The precision is the point and it was expensive**, so a smoother sentence is not an
improvement on it:

> *"skill é a padronização de um comportamento que quero que seja aplicado de forma transversal por
> agentes."*
>
> *"skills por tecnologia padronizam como quero que seja a entrega desse stack."*
>
> *"skills de metodologia de trabalho ancoram comportamentos no workflow."*

**Compact form, which is what a reader should be able to reconstruct from this record:**

- A skill standardises a **behaviour**, applied **transversally** by agents.
- A **technical** skill anchors **delivery** behaviour — how something is built.
- A **methodology** skill anchors **workflow** behaviour — how work moves.

**What separates the two is the axis of the behaviour, not its scope.** A technical skill's scope is
**free** — one stack (`vpc`), several, or stack-independent (`coverage`, the gate policy for both
stacks; `iam`, whose vocabulary is stack-shaped and whose behaviour is not) — and the owner has stated
twice that all three are intended, the second time to correct a narrowing to *"within that stack"*:

> *"skills técnicas também podem ser genéricas, ou seja, aplicáveis a diferentes stacks."*

**Scope is not a quality signal**, and the record says so because the naming invites the opposite
inference: `dynamodb` is named for a stack because that is where its behaviour applies, and `coverage` is
not named for one because its behaviour applies regardless. **Neither naming says anything about the
file's reach, its quality, or its standing in the library.**

### Three properties, all constitutive

The owner's closing framing supplies the third, which appears nowhere else in the conversation:

> *"pense que skills é como usuário pode definir como quer que aquele assunto seja tratado por diversos
> agentes ao longo das sessões. é uma forma de centralização de conhecimento."*

- **Behaviour is the unit.** Not knowledge, not rules — **what an agent does.** A skill's purpose is that
  the behaviour stop depending on each dispatch brief repeating it, or on the orchestrator remembering to
  inject it.
- **Transversality is what makes it a skill rather than a brief.** It is not a consequence of being a
  skill; it is the membership condition. What binds one persona belongs in that persona's brief.
- **Persistence — *ao longo das sessões* — is constitutive, not incidental.** What is written into a
  dispatch brief **dies with the session**: it binds one agent, once, and is gone. A skill defines how a
  subject is treated for **tomorrow's** agents, **with the owner not in the room.** This is the deeper
  reason the orchestrator-injects-it path fails: not that it decentralises the definition into each
  brief, which is also true, but that **a definition which has to be re-authored every session is not a
  definition.**

**The question *norm or decision knowledge* was put and answered: neither.** `coverage`'s checkable 85%
threshold and `vpc`'s NAT-versus-endpoint trade-off are two **forms** the same thing takes. What makes
either belong is that it standardises what an agent does. `vpc`'s *"first decide IF you need a VPC at all
— it's a security × cost trade-off, ASK the owner"* is **behaviour**, not background.

### A skill is the OWNER's instrument, not the agents' documentation

**A skill is where he declares how a subject is to be treated. Agents are the consumers; they are not
the authors.** This is recorded because it decides a class question: **a persona proposing an edit to a
skill is proposing a change to the owner's own instrument**, which is not the same act as writing a
brief or writing a record, and should not be routed as though it were.

### The three surfaces, and when each binds

The clearest form the definition takes is the contrast, so it is stated as one:

| surface | who | when it binds |
|---|---|---|
| **command** | the owner **acting** | now, this invocation |
| **dispatch brief** | the orchestrator **instructing** | this session, this agent |
| **skill** | the owner **defining** | every agent, every session, until he changes it |

### *Centralização de conhecimento* requires BOTH a single definition and delivery

This is the clause that ties the definition to the defect in *Context*, and neither half is sufficient:

- **The same rule living in five briefs is not centralised.** One definition is missing.
- **A definition in a skill nobody loads is centralised and unreachable.** Delivery is missing.

**The class-vocabulary drift measured above is exactly what the second failure looks like**, and it is
live today: `skills/principles/dev-loop/SKILL.md:475,477` and `agents/quality-assurance.md:714-716` are
two statements of one practice, drifted, with nothing comparing them.

### Same mechanism, one difference: which behaviour is anchored

This is deliberately **not** presented as a taxonomy of two kinds of file. A taxonomy invites a reader to
ask which bucket a file goes in; **the operative question is whether it anchors a behaviour at all.**
Technical and methodology skills share the mechanism, the unit and the transversality requirement, and
differ only in **which behaviour they anchor** — delivery, or workflow.

*(Two superseded framings, named so neither is reintroduced. **(a)** *"technical standardises WHAT is
delivered · methodology standardises HOW delivery happens"* — a what/how split lets a technical skill
read as documentation *about* a technology, which is the workload-mirror failure one level up; the unit
on both axes is **behaviour**. **(b)** *"a technology skill anchors delivery behaviour within that
stack"* — a narrowing the owner corrected: scope is free and stack-independent technical skills are
intended. Both are struck rather than deleted, because they are the forms a reader would otherwise
re-derive.)*

### Association is transversal

**No persona owns a skill.** The skill is the definition; several personas receive it. `developer` needs
the **delivery** behaviours for what it builds **and** the **workflow** behaviours for how work moves —
which is the clearest place the current tree does not match this record: `developer` preloads `code-review`,
`verification-and-gates` and `engineering-philosophy`, all three on the methodology axis, and **zero
technical standards** for the app, the infrastructure or the pipeline it delivers.

### THE OPERATIVE TEST — to which profile is this assigned, and why?

**This is the test. Everything else in this record is subordinate to it**, including the two criteria
below, which were the record's operative test in an earlier draft and are now what you apply *after* the
assignment question is answered.

> ***To which profile is this assigned, and why?***

**A skill exists to be assigned to a profile in the loop's roster. A skill with no profile assigned has
no reason to exist** — not *"not yet associated"*, which reads as a scheduling gap, but **without
function**. Nothing consumes it, so it standardises nothing, so it is not a skill.

The owner's words, which are the source of this clause and of the review it orders:

> *"está claro que elas servem à atribuição aos perfis de agentes que vamos ter no nosso loop?"*
>
> *"eu quero rever todos skills com esse propósito agora ancorado e que deve ser registrado em ADR para
> não termos esse problema novamente."*

**Note what the test is NOT.** Not *is this skill good*. Not *is this generic*. Not *is this a standard*.
Not *is this well written*. **A file that cannot answer the assignment question does not belong in the
library regardless of its quality** — and the two subordinate tests below cannot rescue it, because a
file can pass both and still be assigned to nobody.

### The failure mode this test exists to prevent, in one sentence

> **A library grew for two years against no assignment criterion, and the defect stayed invisible because
> every individual file was defensible.**

**That is why the test is about assignment and not about quality: quality was never the thing that
failed.** Every review this library has had asked whether a file was correct, dense, generic or
well-formed, and every file passed. None of those questions can see a file that nothing consumes.

### What the assignment state is today, measured

The roster is **five profiles**. The library is **69 skills**. The assignment between them:

    for f in $(find skills -name SKILL.md); do stem=$(basename $(dirname $f));
      grep -rhq -- "- $stem\$" agents/*.md || echo "$stem"; done | wc -l
    → 62 unassigned

| profile | entries | assigned |
|---|---|---|
| `developer` | 3 | `code-review` · `verification-and-gates` · `engineering-philosophy` |
| `quality-assurance` | 3 | `verification-and-gates` · `coverage` · `sonarcloud` |
| `tech-lead` | 3 | `adr` · `engineering-philosophy` · `documentation-standard` |
| `product-lead` | 1 | `new-issue` — **a command, which must go** (corollary 1), leaving the list empty |
| `harness-lead` | 0 | `skills: []` |

**Seven distinct skills are assigned. Sixty-two are not — 90% of the library.** Of the 14 process
skills, **8 are assigned to nobody**, `dev-loop` among them.

**One correction, because the figure was nearly published wrong and the exception carries the finding.**
It is natural to state this as *"of the ~55 technical files, none is assigned to anyone."* **That is false
by one, and the one matters:**

    for f in $(find skills -name SKILL.md | sort); do stem=$(basename $(dirname $f));
      if grep -rhq -- "- $stem\$" agents/*.md; then echo "$f"; fi; done
    → skills/backend/coverage/SKILL.md   ← the only technical-family file assigned to anyone
      + the six process skills

**`backend/coverage` is assigned — to `quality-assurance`, the profile that CHECKS the delivery, not to
`developer`, the profile that makes it.** So the sharper true statement is: **of 55 technical files,
exactly one is assigned, and it is assigned to the persona that verifies rather than the one that
builds.** `developer` — the only profile that writes app code, infrastructure and pipeline — carries
**three process skills and zero delivery standards.** That is the assignment defect in its purest form,
and it would have been hidden by the rounder claim.

### The consequence for what this library IS

**The library is the roster's equipment.** It is sized by what the five profiles need, not by what has
been learned and written down. That answers the question #183 left open about what the plugin should be,
and it does so without requiring a decision about any individual file.

**What does not answer the assignment question is an archive** — publishable, referenceable, potentially
excellent, and **not a skill**. Naming that category is deliberate: it gives the ~62 files a destination
that is not deletion, so the review the owner ordered is not forced into a false choice between *keep as
a skill* and *cut*.

### The two subordinate tests, and the candidate each one rejects

Applied **after** a file has a profile, to decide whether what it contains is a skill's content:

> **1 · Does this change what an agent does?** Knowledge that changes no behaviour is reading material,
> not a skill.
>
> **2 · Is it transversal?** What is not transversal is not a skill. If a rule binds one persona, its
> home is that persona's brief.

**Both are recorded through a candidate they reject, because a criterion that only admits settles no
argument.**

**Test 1 rejects: a dense passage of decision material that changes nothing an agent does.** However
good, however correct, however well written. This is the test that has never been applied in this
library, and it is the one that catches what *generic versus specialised* cannot see — a file can be
perfectly generic, perfectly accurate, and still leave every agent doing exactly what it would have done.

**Test 2 rejects `--squash`, and the worked case is recorded rather than summarised.**
*"Never squash a merge"* looks exactly like shared hygiene, and a repeated-behaviour framing flags it as
under-covered — one brief out of five:

    grep -c squash agents/*.md
    → quality-assurance 2 ; developer 0 ; product-lead 0 ; tech-lead 0 ; harness-lead 0

**That is correct scoping, not a gap.** `quality-assurance` is the only persona that merges; `developer`
never merges, both leads are advisory, `harness-lead` merges nothing. A merge-spelling rule belongs
in exactly one brief and is in exactly one. **Centralising it would push a rule binding one persona into
five contexts — the mirror image of the defect this record exists to fix.** A criterion that visibly
rejects a plausible candidate is worth more than one that only admits, and the repeated-behaviour framing
got this case wrong where the transversality test gets it right. (Correction supplied by
`harness-lead` on #183 §4; the count above was re-run here.)

The operational form of test 2: **if changing a persona's mandate would change the rule, it is not
transversal.**

### Corollary 1 — the surface rule: `commands/` is the human's, `skills/` is the agent's

A command is addressed to **one reader**, the human: the owner types it, and it declares
`argument-hint`. That is the definition of not transversal, so **a persona must never preload a command.**
`agents/product-lead.md` violates this today by preloading `new-issue`, and **removing it leaves that
list empty** — which is not a problem to route around but the honest state of that persona under this
record.

The property, not the location, is what an assertion should key on: `argument-hint` appears on exactly
the two human-triggered files and on **none** of the 69 skills (command above). The location has already
moved twice — #164 flattened, #182 re-nested — so a path-keyed check is the one thing that breaks when
the tree moves again.

### Corollary 2 — generic means **workload-free**, NOT stack-free

**This is the clause most likely to be misread later, so it is stated at length on purpose.**

**Naming a skill by stack is deliberate, and the technology in the name is the SCOPE of the behaviour,
not the subject of the file.** `dynamodb` does not exist to explain DynamoDB — **it exists to standardise
how a delivery in DynamoDB is done here.** That is a behaviour, it is transversal across every agent that
touches the datastore, and it is exactly the proof-of-depth the artifact is for. **Scope is free and no
scope is better than another:** a technical skill may anchor one stack (`vpc`), several, or be
stack-independent (`coverage`, `iam`).

**The consequence inverts an intuition and is the sharpest test in this record: the more a technical
skill reads like documentation *about* the technology, the less of a skill it is.** A file that explains
a technology without saying how delivery in it is done is **not a skill, however correct it is**. That is
a harder test than *generic versus specialised* and it should be the one a future reader applies, because
it fails good writing rather than sloppy writing — which is why nothing has ever caught it.

**The defect is mirroring a workload** — describing the modules, entities and access patterns of one
application rather than how a technology is delivered. The anchor case, measured:

    skills/backend/lambda-handler/SKILL.md:7
    → Module: $ARGUMENTS (e.g., "posts", "articles", "notifications")

**Substituting `<project>` does not rescue it.** There is no project name in that line to substitute.
Anonymising removes the **names** and leaves the **shape**, and the shape is the specialisation.

**And the existing lint cannot see this class.** The project-agnostic check is green on all 69 (Context,
above). A vocabulary grep is not the replacement — it over-matches badly, which is itself the finding:

    grep -rlniE 'articles?|posts?|feed|curriculum' --include=SKILL.md skills | wc -l   → 44
    grep -rniE 'articles?|posts?|feed|curriculum' skills/principles/dev-loop/SKILL.md
    → :81  "the gatekeeper posts a marker comment carrying the head SHA it read"

`principles/dev-loop` is among the 44 because it contains the word *posts* as a verb. **So the
workload-mirroring class is a review judgement today and has no mechanical detector**, and saying so is
better than shipping a regex that goes green on the wrong thing. The one fence that *is* mechanisable is
narrow and is recorded as a candidate rather than a decision: *no file under `skills/principles/**` may
name a cloud provider, runtime, framework or datastore outside a marked example.*

### What prevents recurrence — and today the answer is NOTHING

The owner asked for this recorded *"para não termos esse problema novamente."* **This record does not, by
itself, prevent it.** Saying so is the repo's own standard: a rule with no mechanism is a document, and
ADR-0004's routing question applies to this record as much as to a hook.

**What exists today:** `hooks/scripts/skills-resolve.test.sh` asserts the association in **one
direction** — every identifier in a `skills:` list resolves to a tracked file. **Nothing asserts the
reverse**, that a file in the library is named by at least one profile. A skill can be added, be perfect,
and be consumed by nobody, with every gate green. **That is precisely how 62 files got here.**

**The assertion that would close it** — *every `SKILL.md` is named in at least one `agents/*.md`
`skills:` list* — is checkable, is a few lines, and belongs inside `skills-resolve.test.sh`, which
already parses both trees. **It would fail on 62 of 69 files today.**

**Whether that assertion should exist is a decision this record does NOT make**, and the reason is
ADR-0004's: a check that arrives already red on 90% of its subject is a check that gets silenced, and
ADR-0009's first amendment records this repo paying exactly that price once. It is only writable **after**
the review the owner ordered, not before — so the honest sequence is *review, then assert*, and the
assertion is the thing that makes the review stick rather than a substitute for it.

**Until then the prevention is a review discipline with no mechanism, and this record says so rather than
implying a control it does not have.**

### The criterion, in one question

> ***To which profile is this assigned, and why?***

The two questions that were the operative test in an earlier draft — *"does this anchor a behaviour I
want applied, or describe something I did?"* and its workload-mirror form *"does this anchor HOW I
deliver, or describe WHAT I delivered?"* — are **kept and subordinated**. They decide whether a file's
*content* is a skill's content. **They do not decide whether the file should exist; only the assignment
question does that**, and it is the one to ask first because it disqualifies fastest and on the axis
that actually failed.

The earlier phrasing — *"does this anchor HOW I deliver, or describe WHAT I delivered?"* — is kept as the
workload-mirror form of the same question, and it is the one to reach for when the candidate is a
technical file. **The behaviour form is the general one**, because it also rejects the accurate,
generic, well-written passage that changes nothing.

## Consequences

**Good**

- **The library gets a membership test instead of a folder convention**, and the operative one —
  *to which profile is this assigned?* — **disqualifies on the axis that actually failed**. It is also
  the cheapest test in the record to apply: it is answerable from frontmatter, in one command, on all 69
  files, without reading any of them.
- **The two subordinate tests each reject as well as admit** — demonstrated on `--squash`
  (transversality) and on the well-written passage that changes no behaviour (the behaviour unit).
- **The ~62 unassigned files get a destination that is not deletion.** *Archive* is a named category, so
  the review the owner ordered is not forced into *keep as a skill or cut*.
- **The drift in the Context section becomes a defect with a named cause** rather than an untidiness. It
  is also the cheapest thing on this record to act on: the two missing clauses go into
  `agents/quality-assurance.md` as a two-line change, **independently of everything else here**, and that
  change is `developer`'s to make, not this record's.
- **"Which persona owns this skill" stops being a question.** Association is transversal, so the only
  questions left are *does it anchor a behaviour* and *whom does it bind* — both answerable.
- **The two natures are one mechanism**, so a decision about one axis does not have to be re-argued on
  the other; and **scope is settled as a non-signal**, which closes a recurring argument about whether a
  stack-named file is somehow less legitimate than a stack-independent one.

**Bad / accepted costs**

- **A preload is frozen at the session's plugin build.** The dispatch that produced #183's measurements
  was running plugin `0.4.56` against `main` at `1.0.7` — twelve versions — and nothing in-session
  reports which build it is on except the `PATH` entry above. **Centralising a rule changes where it
  lives; it does not make it current.** The duplication has the identical defect, so this is not an
  argument for the incumbent — it is a warning against reading *"we centralised the rules"* as *"we
  enforced them"*.
- **A preload is billed on every dispatch, including the ones that never touch the subject.** The
  hygiene case is roughly byte-neutral; anything beyond it is a real and growing cost, and the honest
  framing is correctness, not saving.
- **A brief that becomes a pointer stops reading as a mandate.** The mandate — what a persona is for,
  what it may not do, who it argues with — must stay in the brief, in prose, because it is read in a
  fresh context with no other source. So must every persona-specific **exception** to a shared rule, and
  the **argument for what a persona does not carry** (ADR-0010's best property is that each exclusion is
  argued in the brief that suffers it).
- **The CI assertions that currently assert the duplication would assert nothing.**
  ~~`hooks/scripts/inventory-counts.test.sh:1410` requires every brief to name `<repo-root>/.scratch/`
  literally, and `:1418` requires it to override the harness's own `/tmp` instruction. **If that rule
  moves into a skill, `:1410` goes red on the correct tree.**~~ **STRUCK 2026-08-19 (#283 slice 1) —
  every concrete fact in those two sentences has since changed, and the line locators were pointing at
  unrelated code long before anyone noticed.** What is true at this writing: the assertion requires each
  brief to name **the session scratchpad**, not `<repo-root>/.scratch/`, since #245 retired that
  directory; the `/tmp`-override assertion does not exist at all any more (`grep -n 'tmp'
  hooks/scripts/inventory-counts.test.sh` returns four comment lines and no assertion); and `:1410` and
  `:1418` now land in the gate-coverage block, which has nothing to do with either. **The locators are
  replaced with the assertion's own verdict string** — *"agent brief — … names the session scratchpad
  as where its working files go"* — per `documentation-standard`'s *cite the clause, not the line*.
  **The prediction itself was answered, and the answer is worth more than the prediction:** the rule's
  full statement DID move into a skill (`command-hygiene`, #225) and the brief assertion did **not** go
  red — because the brief kept a one-line naming of the destination and the assertion was re-keyed to
  that naming rather than to the retired path. So the swap was not free and was not fatal either: what
  survived is a check that the rule REACHES each brief, which is the property the paragraph below says
  must not be given up, bought with one sentence per brief rather than with the whole rule duplicated
  six times. Rewriting it to assert the string *in the
  skill* is worse than leaving it: it would prove the text exists and stop proving it **reaches** any
  persona, because a skill can exist and be preloaded by nobody — which is this record's whole subject.
  **What must replace it, and this is a precondition of any extraction rather than a follow-up:** an
  assertion keyed on the **association** — *for each rule in the transversal set, the persona either
  states it or preloads a skill that states it.* Until that exists, **moving a rule out of the briefs
  weakens the check, and this record says so rather than implying the swap is free.**
- **The definition makes part of the current library not-a-skill by its own test**, which converts a
  content question into a backlog. Sized but not decided: see below.
- **This record prevents nothing on its own, and the assertion that would is not written.** Stated above
  in full. The gap is one-directional: identifiers are checked to resolve, files are never checked to be
  consumed, and a check that would arrive red on 62 of 69 files is one this repo has already learned gets
  silenced.
- **The test disqualifies 90% of the library on day one**, which converts a definition into a review
  backlog of ~62 files and a decision per file. That is the cost of having had no criterion for two
  years, and it is paid now rather than avoided.
- **The behaviour test has never been run against the library, and its cost is unknown.** Every
  measurement on #183 sorted files by *genericity* or by *normative vocabulary* — neither of which can
  see whether a passage changes what an agent does. **It is a reading judgement with no proxy**, it will
  fail well-written files, and it is therefore the most expensive clause in this record to apply and the
  most likely to be quietly skipped. Naming it here is the only thing that makes the omission visible.
- **The situational half has no delivery mechanism inside a persona.** Model invocation is the main
  agent's only. A standard the persona cannot reach when the situation appears standardises nothing, so
  under this record *reachable* means **preloaded**, or **read from disk by a persona told where to
  look** — and nothing tells any persona that today.

## What this record does NOT decide

Stated so nobody reads the definition as having settled them:

- **Whether the workload-mirroring files are rewritten or cut.** `harness-lead` sized the set at
  roughly **50 guides against 19 standards or rescuable standards** on #183 §B2, by a normative-vocabulary
  proxy it verified at the extremes by reading and labelled a **hypothesis in the middle band**. Its own
  recommendation is *rewrite, not cut* for `coverage`, `iam`, `dynamodb`, `authorization`,
  `environment-config`, `sonarcloud`, `terraform-cloud`, `github-actions` and
  `permissions-and-environments`. **That is input, not a decision, and it is the owner's.** Note that
  none of that sizing applied the behaviour test, so the set it names is neither an upper nor a lower
  bound on what this record disqualifies.
- **How many methodology skills there should be**, and which rules go in each. One, three, or a split of
  one of them, is an open design question.
- **The outcome of the review the owner ordered.** This record supplies the criterion and the measurement
  (62 unassigned); it decides **no individual file**. Each one is *assign to a profile*, *rewrite so a
  profile can be assigned*, *move to archive*, or *cut* — and that is 62 decisions, his.
- **Whether the reverse assertion is added**, and when. Argued above: it is writable only after the
  review, because arriving red on 62 of 69 files is how a check gets silenced.
- **What `archive` is mechanically** — a directory, a frontmatter flag, a separate plugin, or simply
  files that stay where they are and stop being called skills. The category is named here; its shape is
  not decided.
- **The removal of `new-issue` from `agents/product-lead.md`**, and what — if anything — that list holds
  instead. This record states the rule it violates.
- **Whether `harness-lead`'s `skills: []` should change.** ADR-0010 argued it on three grounds and at
  least one of them ("your object is not in that directory") does not survive the current tree, since
  `skills/principles/permissions-and-environments/SKILL.md` documents `hooks/permission-guard.sh` by
  name. Re-arguing that list is a decision about a persona, not about what a skill is.

## Amendment (2026-08-13) — a fifth disposition, scoped to the three technical families: consolidate, don't rewrite-per-file

Ratified directly by the owner in conversation, extending the four-way disposition framework this record
handed to [#192](https://github.com/tedeuxx/tadeumendonca-skills/issues/192) (*assign / rewrite-then-assign
/ archive / cut*, applied per file). This amendment does not repeal that framework — it adds a fifth shape
that applies to one region of the library only, for a reason the framework itself did not have available
when it was written: the mechanical fact this record's own Context already states (*"`Skill` is not
grantable through `tools:`"*) was re-confirmed, not re-derived, on
[#177](https://github.com/tedeuxx/tadeumendonca-skills/pull/177) as the closing item of a separate
Issue, and this amendment is the first record to draw its consequence out fully.

**The reasoning chain, in the order the owner walked it:**

1. **The mechanical floor (already recorded, re-cited here from #177).** No subagent persona has true
   on-demand skill invocation. There are exactly two channels into a persona's context: **forced
   preload** via its brief's `skills:` list, present before the first turn and identical on every
   dispatch; or a **manual `Read`/`Bash`** of the raw file, which happens only if the model, unprompted,
   decides to go and look — a decision this record's own Context already named as one that *"fails
   silently"* when it isn't made. There is no third channel, and no situational, description-triggered
   loading exists inside a subagent the way it exists for the main agent.

2. **What that constraint implies about what's worth forcing.** Given only those two channels, the owner
   reasoned: what actually *needs* to be anchored — forced into every dispatch, governing behaviour
   whether or not the model thinks to go looking — is the **process/workflow layer**: the 14 files under
   `skills/principles/*` and `skills/workflow/*` (5 + 9, re-derived here:
   `find skills/principles skills/workflow -name SKILL.md | wc -l` → **14**), because that layer is what
   this repo's own stated mission calls the differentiator — *"the reviewable loop is the differentiator
   … the skill library is its least distinctive third"* (this file's own `CLAUDE.md` framing, cited rather
   than re-quoted). A process rule an agent never sees does not shape a dispatch; a technical file an
   agent never sees is simply not consulted this time, which is a smaller and different failure.

3. **The technical families do not need the same treatment.** The 55 files across `backend`, `frontend`
   and `infrastructure` (re-derived here, and corrected from the framing that reached this record —
   see the note below) are reference material: consulted by manual `Read` when a persona judges it
   relevant to the slice in front of it, not something whose *absence from every dispatch* would let
   behaviour drift the way an unloaded workflow rule does. Forcing 55 files into a preload was never on
   the table (ADR-0010 already rejected the universal-floor shape on cost grounds); the live question was
   whether they should stay 55 separately-assigned files or become something else.

4. **Given reference-only status, consolidation is the more usable shape.** If a persona reaches these
   files only by deciding to go and read, one entry point per family — searchable and greppable in a
   single file — serves that act better than 55 files a persona has to first guess between. The owner
   named the resolution directly and by name:

   - **`infrastructure` (21 files) → one consolidated skill, named `cloud-infrastructure`** (not
     `infrastructure` — the family directory name and the skill's own name diverge, same as every skill
     today; the name is the discipline/capability, not the taxonomy bucket). **Renamed from an earlier
     `aws` naming, owner decision 2026-08-13**: `cloud-infrastructure` reads better as a capability name
     and stays consistent with the discipline-naming convention applied to `devops`/`harness-engineering`
     — but the *content* still names AWS explicitly as the main CSP covered, since that is what all 21
     source files actually document. The skill isn't provider-neutral; only its filename is
     provider-agnostic, leaving room to note a different CSP later without another rename.
   - **`backend` (19 files, corrected below) → one consolidated skill, named `backend`**, holding *"the
     desired patterns"* — a **curated distillation**, not an exhaustive merge of all 19 files' full depth.
   - **`frontend` (15 files) → one consolidated skill, named `frontend`**, kept live and at full depth,
     since it is the current consumer's actual stack.

**Correction owed to the number that reached this record.** The reasoning chain as relayed into this
amendment's driving conversation stated `18 + 15 + 21 = 54`. Re-derived directly against the tree at
`24dbaf5` (`main`, this repo):

    find skills/backend -name SKILL.md | wc -l        → 19
    find skills/frontend -name SKILL.md | wc -l        → 15
    find skills/infrastructure -name SKILL.md | wc -l  → 21
    → 55, not 54

`backend` carries 19 files, not 18 — matching `CLAUDE.md`'s own published table (`### backend (19)`),
which the relayed figure should have been checked against and was not. The three consolidations below are
priced against **55**, not 54. This is a small, immaterial correction to the input arithmetic and changes
no part of the decision.

### What this does NOT repeal

**ADR-0011's disposition framework stands, unchanged, for the 14 process-family files** — the ones under
`skills/principles/*` and `skills/workflow/*`. Those keep per-file granularity: each is independently
`assign`ed, `rewrite`-then-assigned, `archive`d, or `cut`, exactly as [#192](https://github.com/tedeuxx/tadeumendonca-skills/issues/192)
already frames it. Nothing here changes that Issue's task 1 (the 8 named files still unassigned to any
profile — `dev-loop`, `loop-engineering`, `permissions-and-environments`, `claude-code`, `github-actions`,
`license`, `terraform-cloud`, `versioning`).

**The density standard survives the consolidation; its unit of application changes.** `CLAUDE.md` names
`skills/vpc/SKILL.md` the density exemplar — the bar every AWS-service skill should read at. `vpc` is one
of the 21 files folding into `cloud-infrastructure`. The bar is **not lowered by folding**: it now applies to the *section*
within `cloud-infrastructure` that covers VPC, not to a standalone file. A consolidated file that reads shallow because it
is one file rather than 21 has failed the same test a shallow standalone file would have failed; size of
container is not the measure, depth per subject is.

### The curation criterion — one rule, applied uniformly to all three consolidated skills

**Late refinement, arrived after this amendment's driving conversation and incorporated here rather than
scoped to `backend` alone, which is how it was first framed.** The curation is not *merge everything from
the N source files* and not *neutral best-practice coverage re-derived fresh in one place* — it is
specifically **the owner's own opinionated pattern per concern**, already stated today, only stated in a
denser, more granular way, scattered across the N separate files each consolidation absorbs. This is not
a new standard invented for the consolidation: `CLAUDE.md`'s own *"Deep-dive authoring process"* section
already names the *"owner's opinionated default + when he deviates"* — the **"My take" layer** — as
*"THIS is the differentiator; generic best-practice alone is not enough."* The consolidation's job is to
**anchor that existing preferred-pattern layer** in one file per family — not to exhaustively re-cover
every option each source file discussed.

This applies to **all three** consolidated skills alike — `cloud-infrastructure`, `backend`, and `frontend` — not to
`backend` uniquely, correcting how the reasoning first reached this record.

- **Who makes the call:** whoever executes each consolidation task (`tech-lead`, or `developer` under
  `tech-lead`'s direction, at build time on the task tracked under #192's redirected scope, one task per
  family) — not decided in advance by this amendment as a named individual dispatch, because none of the
  three tasks has been scheduled yet. What this amendment fixes is the **criterion**, so the call is
  checkable regardless of who makes it.
- **The filter is ADR-0011's own test, applied at paragraph grain rather than only at file-survival
  grain:** *"the more a technical skill reads like documentation about the technology, the less of a
  skill it is."* Content earns a place in a consolidated file only if it states **the owner's chosen
  pattern for that concern and, where recorded, the trigger to deviate from it** — signal, in ADR-0011's
  own vocabulary — not because it is accurate or complete background on the technology or the
  architecture. A passage that surveys every option a source file discussed, without saying which one is
  the default here and why, is noise under this filter regardless of how well-written or correct it is —
  the same failure ADR-0011 already named for a standalone file, now applied inside one.
- **Why `backend` carries the sharpest version of this cost, without being the only file it applies to:**
  `backend` documents a **retired** architecture (`CLAUDE.md`'s own framing: *"the `backend` family …
  document[s] a BFF-on-Lambda + DynamoDB + Cognito architecture that `tadeumendonca-io` retired"*), so
  applying the same filter there additionally means the owner's preferred pattern is being kept as a
  **reference pattern with no live consumer to exercise it** — a different and named risk from `cloud-infrastructure` and
  `frontend`, where the kept pattern is exercised by dispatches against the live stack. The filter itself
  — keep the preferred pattern, drop the survey — is the same rule in all three; only what's at stake if
  the filter is applied wrong differs.

### What this amendment does NOT decide

- **The internal structure of `cloud-infrastructure`** — how 21 services' worth of content organises inside one file (by
  architectural layer, by lifecycle stage, alphabetically by service, or some other axis). Left open
  deliberately rather than proposed here: the density exemplar (`vpc`) is itself one service among 21 and
  gives no signal about cross-service ordering, and a structural call made without having assembled the
  21 sections first is more likely to be re-litigated than followed. Named as unsettled, not decided by
  default.
- **The per-file profile assignment of the 8 remaining process files** named in [#192](https://github.com/tedeuxx/tadeumendonca-skills/issues/192)'s
  task 1 (`dev-loop`, `loop-engineering`, `permissions-and-environments`, `claude-code`, `github-actions`,
  `license`, `terraform-cloud`, `versioning`) — unchanged, ongoing, and not this amendment's job.
- **Which profile(s), if any, preload the three consolidated files.** `cloud-infrastructure`/`backend`/`frontend` are
  reference-only by this amendment's own reasoning (item 3 above) — read by `Read`, not forced by
  `skills:` — but whether any of them is nonetheless small enough or central enough to warrant a preload
  slot on `developer` is a separate call this amendment does not make.

## Links

- Driving Issue [#183](https://github.com/tedeuxx/tadeumendonca-skills/issues/183) — the owner's
  definition, his genericity constraint, **his closing assignment clause (the operative test above, and
  the order to review all 69 skills against it)**, and `harness-lead`'s reassessment and two addenda,
  which are the source of the drift finding (§2), the `--squash` correction (§4), the `argument-hint`
  property (§7), the standard/guide sizing (§B2) and the
  `developer`-carries-no-technical-standard finding (§B3) — that last one **narrowed here on
  measurement**: `developer` carries none, but the library is not wholly unassigned on the technical
  axis, since `backend/coverage` is assigned to `quality-assurance`.
- [ADR-0009](./0009-a-skill-description-is-a-trigger-not-a-title.md) — **cited, not amended.** It owns
  *how a skill is discovered*; this record owns *what a skill is*. Its standard was executed well —
  69/69 descriptions carry `Use when`, 67/69 carry `Not for` — and the only thing this record adds is
  that it had **no consumer** until #182, and that the **bodies** were not converted with the fields:
  `grep -rlF 'Context: $ARGUMENTS' --include=SKILL.md skills | wc -l` → **67**, a slash-command
  substitution in files a model may load without anyone typing a name.
- [ADR-0010](./0010-a-personas-startup-context-is-a-curated-preload.md) — **cited, not amended**, on both
  counts and deliberately. Its **rejection of the universal floor stands** — re-derived at 76,059 B ×5,
  and its second reason is untouched — but that arithmetic was priced against **all of `principles/*`**
  and does not reach a ~5 KB transversal skill, which is a re-scoping rather than a falsification. Its
  **Context item 2 is falsified** (the plugin root is derivable from `PATH`; command in Context above),
  and that clause **owes an amendment this record does not write**, for the reasons stated there.
- [ADR-0004](./0004-controls-and-enforcement.md) — **cited, not amended.** Its routing question is
  why the replacement assertion above must key on the association rather than on the text, and why a
  preload is recorded here as a cost-reducer rather than as a control.
- [ADR-0005](./0005-plugin-auto-versions-on-merge.md)`:146-149` — the `Skills (2)` → `Skills (71)`
  measurement, relayed from #182 and cited rather than re-derived: **this record could not re-derive it**,
  since the pre-#182 state no longer exists in a running loader.
- [ADR-0002](./0002-roster-and-dev-loop.md) — **cited, not amended.** The context window as one
  of the four reasons a persona exists is the driver every option above is priced against.
- **Evidence re-derived on this branch, not relayed:** the project-agnostic lint (0 hits); `argument-hint`
  (2 under `commands/`, 0 under `skills/`); the 14 process skills and the ten `skills:` entries; the
  `own authority` / `loop's own rules` grep (2 hits, both in the skill, 0 in any brief); the per-brief
  hygiene byte figures summing to 20,777 B; `find skills/principles -name SKILL.md -exec wc -c {} +` →
  76,059 B; `grep -c squash agents/*.md`; `grep -rl 'Use when' --include=SKILL.md skills | wc -l` → 69
  and the same for `Not for` → 67; `grep -rlF 'Context: $ARGUMENTS' … | wc -l` → 67; and
  `printenv CLAUDE_PLUGIN_ROOT` → exit 1 **and** the `PATH` plugin-cache entry, both in the shell that
  wrote this record; and **the assignment sweep**, which is the measurement the operative test rests on —
  the unassigned count (**62 of 69**) and the assigned seven, from the same loop run both ways.
