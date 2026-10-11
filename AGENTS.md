# tadeumendonca-skills — the root brief

**This is the single root brief for every agent harness working in this repository**, and it holds
every rule. It is authored, not generated, and harness-neutral. Since #562 the harness-specific root
brief it used to sit beside is consolidated and deleted. **The reasoning, the measurements and one
harness's how-to are in [`docs/agents-md-record.md`](docs/agents-md-record.md)**, which is linked
rather than loaded, and holds no rule this file lacks.

sphere: personal

This is a declaration only, recorded in [decision record 0035 of the workstation configuration repository](https://github.com/tedeuxx/mhw/blob/main/docs/adr/0035-workstation-blueprint-reconciliation.md); there is no stop-on-undeclared rule.

## The budget, and how a harness finds this file

**This whole file stays under 30,000 bytes.** The smallest measured consumer reads the first 32,768 bytes
and silently drops the rest, and another truncates at 50,000 characters. A rule past the cut does not
exist for that reader, so when the file grows, move reasoning out to the record — never a rule. The
record lists each harness's figure at its evidence level.

**One harness reads this file only as a FALLBACK.** A file named for its vendor in any of three places
makes it load that file **instead of this one, entirely and silently**: at the repository root, inside
that harness's configuration directory, or as the local variant. The same holds for any of those three
in an **ancestor** directory. A **linked worktree does not** inherit its main checkout's file, but a
separate repository nested inside a checkout does inherit it. **Never create any of them here.** The
names are the `SHADOWS` list in `hooks/scripts/agents-md.test.sh`, which turns red if one is tracked. An
untracked or ancestor copy is invisible to it, and is held by whoever sets up the workstation.

## What this repository is

A **library of engineering knowledge and agent configuration** for a two-repository platform:

- `skills/` — one directory per skill, one skill file each: dense, scenario-covering architecture and
  process guides, reusable in any project.
- `commands/` — the guides a human invokes by name, with arguments.
- `agents/` — the persona briefs, one file per profile. `ls agents/*.md` is the roster.
- `hooks/` — enforcement scripts and their test suites. **Harness-specific by construction**; see
  *What is enforced* before assuming any of it runs for you.
- `docs/adr/` — the decision library for the loop and the machinery. Read the record before changing
  anything it decides.
- `powers/` — a **generated** export of `skills/` for a second harness. **Never edit it by hand**; edit
  the source under `skills/` and regenerate with `hooks/scripts/kiro-power-build.py`.
- `scripts/` — repository utilities that are not hooks.

It is consumed by `tadeumendonca-io`, the static site that is the platform's public surface. Skills are
written **project-agnostic** — generic placeholders, never real names, domains, account or resource
identifiers — because they are published for strangers. **The library is broader than its consumer:**
the `backend` skill and parts of `cloud-infrastructure` document an architecture the site **retired**
(a BFF on Lambda with DynamoDB and Cognito); it is now fully static. **Never infer the consumer's
architecture from them** — read the consumer's own root brief. Why this repository exists and the depth
bar every skill meets are in the record's *Mission*.

## The floor — obligations, not descriptions of enforcement

**Every rule below is something you must do, and each is true on a harness with no hooks.** Where one
harness also enforces a rule mechanically, that is not written into the rule.

1. **No solo architectural decisions.** Architecture, public contracts, schemas and anything
   irreversible go to the owner before you act. In-pattern implementation is yours to decide and
   report.
2. **Never merge your own work, and never push to the trunk.** Work on a short-lived branch, open a
   merge request, and let the gate decide. `main` is the only long-lived branch here.
3. **Never rewrite published history.** No force-push to a shared branch, no `git reset --hard` over
   work you did not create.
4. **Never write a secret into this repository or into a forge secret store.** No exceptions, no
   redaction, no temporary placeholders that look like real values.
5. **Infrastructure mutation is pipeline-only.** Never run `terraform apply` or `terraform destroy`
   from a workstation. Local is read-only: format, validate, inspection plan. Destroying live
   infrastructure means removing it from configuration and merging.
6. **Never use a runtime flag that disables your harness's permission checks.** If an act is refused,
   the refusal is the answer; report it rather than routing around it.
7. **Scratch files go in your harness's own session scratchpad, never in a repository path.** Bodies
   for merge-request and issue text are written to a file and passed by file, never inlined into a
   shell argument — a shell eats backticks and dollar signs out of an inline body silently.
8. **Work in progress is bounded by the `wip:` value in `docs/loop-mode.md`.** Read it there; do not
   assume a value. Each concurrent work item gets its own branch and its own `git worktree`, and each
   is finished through merge. Only one merge request is in review at a time, whatever the bound.
9. **A review finding is named, never filed.** Only the owner opens work. Report what you found; do
   not convert your own finding into a tracked item.
10. **Publish a measured number with the command that produced it, inline and runnable, or do not
    publish the number.** A figure whose falsifier is missing, dead or answers a different question is
    worse than no figure, because it reads as checked.
11. **Prefer measuring to reading, and say which you did.** A claim about machinery that was read
    rather than executed is a hypothesis, in those words.
12. **Everything published on the forge is written in English** — this file, the README, commit and
    merge-request text, issues, decision records.
13. **Content is additive.** Deepen; never thin out good content.

## When you interrupt the owner — the form of an escalation

**Rule 1 governs every owner-directed activation or message** — decisions and actions, inside or
outside work in flight. An interview, a design conversation and an ad-hoc request are not thereby
escalations; rules 2–5 govern the form only when the act they describe applies.

1. **One owner ask per interruption or message.** Two, however short, is a list, and he rebuilds his
   context twice. Ask or order the first; carry the second to its own later interruption. **This is the
   most expensive rule here, not the softest:** where a surface renders only the first of several
   questions, the rest were never shown, nothing reports the loss, and the work proceeds as though they
   had been asked. A structured picker is mechanically denied when its real `questions` array has two or
   more members; zero, one and unparsed shapes fall through. A prose list of owner actions remains
   review-held — do not recreate the deleted semantic classifier, and do not move the remaining asks
   into prose.
2. **The interruption is a tweet, and the context lives in the OPTIONS.** Each option states its own
   consequence, and that is the whole preamble; the reasoning belongs in an artifact he can open.
   **Put the consequence in the text of the option he reads** — a consequence carried in a side field
   can be dropped in transport, silently.
3. **Enumerate the choices and give each its consequence. At most four** — a ceiling, not a target.
   Where your harness offers a structured way to present them, use it; where it does not, enumerate in
   prose and keep the ceiling. An open question never stands in for a reduction you owed.
4. **An act you cannot perform yourself is an order plus a link, not a question.** The test: *is there
   a second option you would actually defend?* If not, it is one line — the act and the object, no
   options, no recommendation. The tell in a bad one is every option being the same act at a different
   time. **Do not rebuild this rule as a preventive control:** one was built and deleted, because its
   false positives were invisible to the person it protected (the record says why).
5. **An interview question takes NO options; an escalation always does.** An interview elicits what he
   thinks, and a menu puts words in his mouth; an escalation asks him to take a decision you already
   reduced. A question raised with no options can be disposed of by the machinery and the work
   advanced, unseen.

## The conventions this platform's skills enforce

1. No solo architectural decisions — ask when ambiguous.
2. Pipelines are independent per repository. Never trigger one repository's pipeline from another.
3. `snake_case` everywhere — database fields, interfaces, request and response bodies. No mapping
   layer.
4. REST: resources are nouns, HTTP verbs express the action, paths and parameters in kebab-case.
   Identifiers in paths are opaque — a slug or a hashid/nanoid `public_id` — never enumerable or
   sequential.
5. Infrastructure mutation is pipeline-only: plan on the merge request, apply on merge. Destroying live
   infrastructure is removal from configuration plus merge, or a reviewed, manually dispatched teardown
   workflow. See `skills/devops/SKILL.md`.

## How work moves

Nothing is worked that is not tracked as a forge issue. Three exclusive routing types — `product` (the
deliverable), `content` (published in the owner's voice), `loop` (this machinery) — and two state
labels, `ready` (the description is closed; the item is buildable) and `blocked`. An item without
`ready` is not executable.

**Each profile exists because a specific disagreement or fresh context is wanted.** This table is a
convenience, not the roster — `ls agents/*.md` is; a profile added with no row here reddens nothing:

| profile | brief | what it holds |
|---|---|---|
| product lead | `agents/product-lead.md` | order, value, slice size, positioning; blocking on the truth of published claims |
| tech lead | `agents/tech-lead.md` | architecture, measurement, sequencing; writes the product decision records |
| agents lead | `agents/agents-lead.md` | the machinery — briefs, enforcement, distribution; writes the machinery decision records |
| scrum master | `agents/scrum-master.md` | whether the process ran; holds no tools at all, by design |
| developer | `agents/developer.md` | builds a slice end to end |
| content writer | `agents/content-writer.md` | drafts published prose in the owner's voice |
| content reviewer | `agents/content-reviewer.md` | judges and repairs that draft against one shared ruler |
| quality assurance | `agents/quality-assurance.md` | the merge gate, on two lenses at once |

The design intent — why the loop is shaped this way, its state machine, its intake chain — is
`skills/agents-configuration/SKILL.md`; the portable engineering judgment is
`skills/engineering-standards/SKILL.md`. Read both before proposing a change to any of it.

**The merge is the go/no-go.** A change reaches the trunk through a merge request and a gate that judges
it against the item's requirements and against whether it can break production. Nothing auto-merges.

**Every dispatch is a fresh instance, and no instance is reused.** Start a new instance for each
dispatch; never carry one from one issue to the next, nor the instance that built a change into
reviewing it. Proposing and building are separate dispatches too. This is about instances, not
profiles: the agents lead may both build a `loop` item and review it (`docs/adr/0002-roster-and-dev-loop.md`,
record 0015), in two contexts. A verdict attests the diff the reviewing context holds, and an instance
carried across issues or summarised to fit may no longer hold it. Held by whoever dispatches, and by
review.

## Standing rules for working this loop

The owner's standing rules, as obligations true on a harness with no hooks. Mode-dependent values and
the work-in-progress bound are read from `docs/loop-mode.md`, never stated here.

### Git and the forge

1. **Merge with a real merge commit. Never squash, and do not rebase-merge unless the owner asks.** The
   branch's commits are the changelog. If a repository permits only squash, report it.
2. **In a commit message, reference an issue as `Refs #N`. Never put a closing verb — close, fix,
   resolve, in any tense — in the same clause as an issue number, not even to deny it.** The forge's
   parser is lexical and closes the issue on merge. A merge request's closing set is derived from its
   body alone, so check the commit range instead:

   ```
   git log <merge-base>..<head> --format='%B' \
     | grep -inE '\b(close[sd]?|fix(e[sd])?|resolve[sd]?)\b[^.]{0,20}#[0-9]+'
   ```
3. **Undo a recent change by reversing that change, never by checking out or restoring the whole
   file**, which discards every unstaged edit in it with no copy. Before deliberately breaking
   something to test it, commit the good state.
4. **Address a repository explicitly** — `git -C <path>`, and a repository flag after the subcommand —
   and never change directory inside a compound command. Several checkouts can be live at once, so the
   current directory does not identify which one an act lands in.
5. **Commit messages longer than one line go through a file**, for floor item 7's reason.
6. **Scratch never goes to a shared system temporary directory, nor inside `.git`.** With no session
   scratchpad, ask where scratch belongs. **State that must outlive your session is not scratch:** it
   goes on the issue being worked, as a worklog `handoff` or `checkpoint` event prepared with
   `scripts/worklog.py prepare-event` and posted by file — facts and one next act, one line each, never
   reasoning or anything private. Contract and resume command: `docs/worklog/README.md`. A later session
   resumes from the latest next act, then re-checks the tracker. **A measurement instrument persists
   only as a repository script with a test, and only if a gate will run it;** otherwise discard it.
7. **Never wait on a pipeline with a sleep-and-poll loop.** Push, report that checks are running, check
   once when it matters, and read the result for the exact commit by its full identifier. **Wait for a
   dispatched agent once, blocking, with the longest timeout your tool accepts** — never sleep, list or
   re-wait in between; every check re-sends your whole context.

### Reporting to the owner

8. **A merge-request link reaches the owner only when it is ready to merge**: every check passed and
   the gate's verdict at the current head leaves only his act. Before that, report state in prose and
   name the item by number. An issue link carries no such signal.
9. **When you hand him a link, it is the browser address, not a command for him to run.**
10. **A failed check is yours to fix, not his to hear about.** Send it back to the builder with the
    failing job and cause, until green — unless it needs a decision only he holds.
11. **Anything you need from him goes first in the message, labelled as a request.**
12. **His decision lands on the item it decides, when he makes it** — a comment carrying his words.
    Relaying it into a dispatch does not record it: a fresh context reads the tracker, never your
    conversation.

### The queue

13. **An item the owner opened is never closed on an agent's advice.** A lead recommending a drop
    withholds `ready`; closing is his act.
14. **When he gives several asks at once, each becomes its own tracked item before anything is built.**
15. **In every mode, every eligible `loop` item is worked before any eligible `product` item.**
    Eligible means in the pool `docs/loop-mode.md` defines for the mode in force — read the predicate
    there; under `scrum` it holds only the active iteration's milestone. Every pool requires `ready`;
    neither filters `blocked`. **The sequence inside an iteration is the machine's:** the scrum master
    proposes the set, the orchestrator dispatches, with no per-item approval.
16. **`content` is selected by the owner one piece at a time and never drained autonomously.** Its
    intake starts by interviewing him, recorded in his words, one question at a time, without options.
17. **The eligible pool spans both repositories** — read both queues. **Read the mode of record,
    `docs/loop-mode.md`, before any pool query, and never infer the mode from a query's result**: an
    empty result means opposite things in the two modes. Never type a milestone name into a query —
    enumerate, then select from what came back. A drain compares both repositories' mode records at
    entry and stops if they disagree.
18. **Review is routed by type.** `loop`: one agents-lead lens pass, plus the gate — no copy lens and no
    tech lead. `product`: the leads' lenses as the slice warrants, plus the gate. `content`: the content
    writer drafts and the content reviewer repairs in place for at most two rounds, plus the gate. **The
    gate runs on every merge request; the routing never narrows a gate, a hold, a criterion or a verdict
    literal**, and on `loop` the agents-lead marker hold still applies. The routing is a default: a lens
    the row does not name is a deviation you state in the dispatch. No review rule is keyed on a round
    count. Intake is routed the same way: `loop` by the agents lead alone, `content` by the product lead
    alone, `product` by both leads.
19. **A dispatch that only reads a checkout still gets its own worktree whenever a build may be
    running**, because a concurrent build switches branches under it.

### Building and investigating

20. **Before changing the loop, re-derive its state model**: item types, states, which role acts at each
    transition, and what artifact records it.
21. **Before relying on a check you wrote or changed, break its subject on purpose, watch it go red,
    restore, and watch it go green.** Mutate the thing checked, never the checker. See *Before you trust
    a green, break it on purpose* in `skills/engineering-standards/SKILL.md`.
22. **A true answer that closes the inquiry is the failure to guard against.** When a symptom repeats,
    *the actor should have been more careful* is a reason to keep going; find what made the rule
    unreachable at the moment of the act (principle 12 of the same skill).
23. **Do not assert in a dispatch brief a premise you have not measured.** Measure it and carry the
    command, or write it as a premise the dispatch must verify — never as a fact it may inherit. A brief
    is the specification the dispatch builds against. Mark any argument written to justify a fact as
    briefing-only. **Never ask a dispatched profile to re-read a file its instructions already carry,
    and as that profile do not re-read one;** if you think the carried copy is stale, read only the
    section you need and say why.
24. **A change to the machinery is evaluated against every harness that consumes this repository.**
25. **A mechanism that lands here ships with a portable prompt under `docs/prompts/`** — behaviour,
    reasoning and limit.
26. **A skill is atomic and consumer-free**: one whole concept across its lifecycle, no reference to one
    consumer's setup, every choice with its trade-off and explicit pros and cons. It covers the scenario
    space as a decision tree, with criteria and rough numbers where they drive the call. Its *My take*
    layer is elicited from the owner, never invented, and a persona brief's is calibrated the same way. A skill is declared in the package manifest and has a row
    in `docs/command-reference.md`; a typed command carries `argument-hint` and a skill does not; every
    mechanism carries exactly one `purpose:` line.
27. **A secret's scope and name follow the single standard in `skills/devops/SKILL.md`.**

### Who acts, and what is written in public

28. **The main session — the orchestrator — only dispatches; it never edits a repository file.** It
    dispatches every profile (no profile addresses another directly), commits and pushes on the loop's
    behalf, applies the routing label, and judges which lenses a diff needs. No layer enforces the
    no-edit rule; it is held by the orchestrator and by review.
29. **On the `loop` lane the owner decides `ready`, and the orchestrator applies the label once aligned
    with him** — his words recorded on the item (standing rule 12). On other lanes `ready` follows the
    intake that closes the description (standing rule 18).
30. **On any public surface a client or other third party is described by sector or industry, never by
    name.** The owner's own employer may be named. **Private positioning material lives only in the
    gitignored private directory of the product repository, and is never pasted into an issue, comment
    or merge-request body** — an ignore stops a commit, not a paste.
31. **The loop grinds work down rather than generating it, and nothing ships half-done.** Close what can
    be closed; say plainly what could not.

### Gating and merging

32. **Before dispatching the gate, check whether the trunk moved since the head being attested.** If it
    did, rebase onto the trunk first: a verdict on a head lacking the previous merge attests a
    composition no reviewer read. Conflicts are resolved at merge-request time by the slice's author.
33. **Every merge names the merge request's number explicitly**, never the current branch's: with one
    worktree per slice, the current branch is not unique.
34. **A lens or gate verdict is a merge-request comment naming the full 40-character commit it read.**
    A moved head needs a fresh verdict; an abbreviated identifier attests nothing.
35. **Remove a slice's worktree once it has merged.**

### The loop mode

36. **A mode selects a pool predicate and a ceremony set; it never selects a permission rule.** No mode
    touches the permission floor, the merge gate and its lenses, head-scoped verdicts, only-the-owner-
    opens-work, the readiness bar (`sp:N` in both modes), the routing labels, or the iteration's
    existence; `content` has no second mode. **A cadence trigger keys on the clock, never on the pool
    being empty.** Before any hook is taught the mode, review that change first. A mode record states
    the date the mode actually began, never the day the record lands.

## Versioning and distribution

Numeric SemVer, `MAJOR.MINOR.PATCH`, no pre-release suffix. `VERSION` is the current value and
`.bumpversion.toml` the configuration; the version file and package manifest move in lockstep. **Every
merge to `main` bumps the patch and publishes a release**: a consumer resolves published versions, so an
unpublished trunk never ships. **Publishing is not adoption.** A deliberate minor or major is cut from
the release workflow in `.github/workflows/`. For this library the contract is the invocation surface:
major renames or removes a command or changes its argument contract; minor adds a skill, a command or
substantial capability; patch changes content without changing what exists or how it is called.

## What is enforced here, and what your harness enforces

**Assume nothing in `hooks/` runs for you.** Those scripts target one harness's event model; on yours,
the rules above are obligations and nothing else. The generated package under `powers/` likewise
carries the knowledge layer and none of the enforcement layer (the record says why).

## What is checked

`hooks/scripts/agents-md.test.sh` asserts five things:

- this file is tracked;
- the whole file is under its byte budget;
- it names none of a declared set of one-harness tokens;
- every path it names exists;
- no file a harness would load instead of it is tracked.

**No check can assert that the brief is true, or that it is neutral rather than merely free of listed
tokens.** That is held by review, and so is whether a rule moved to the record without a copy here.

