# tadeumendonca-skills — the harness-neutral brief

**This file is the whole brief for any agent harness that reads `AGENTS.md`.** It is not a
compatibility copy and it is not generated. Where your harness reads a root brief under a different
name, that other file exists in this repository too and is longer; **this one is not derived from it**,
and the two are authored side by side under the same rule rather than one being transformed into the
other. A rename-only transform was measured and rejected: the other brief is already well past this
file's budget, so a generator could not produce a loadable artifact at all.

## The budget, and whose it is

**Keep this file under 50,000 characters.** That number is **one consumer's measured floor, not a
standard**: Kiro `1.0.337` loads `AGENTS.md` as always-on steering and truncates it at 50,000
characters, announcing the loss only on a debug channel. **Every other harness's budget is unmeasured.**
Read it as a ceiling that is known to bite somewhere, not as a limit anyone published.

The measurement is a read of the shipped bundle's control flow on a machine where that tool has never
authenticated. It has not been confirmed against a live session.

**A gate asserts the length.** See *What is checked* below.

## What this repository is

A **library of engineering knowledge and agent configuration** for a two-repository platform. It holds:

- `skills/` — one directory per skill, each holding one skill file. This is the knowledge layer: dense,
  scenario-covering architecture and process guides, written to be reusable in any project.
- `commands/` — the guides a human invokes by name, with arguments.
- `agents/` — the persona briefs. Eight profiles, one file each.
- `hooks/` — the enforcement scripts and their test suites. **Harness-specific by construction**; see
  *What is enforced* below before assuming any of it runs for you.
- `docs/adr/` — the decision library for the loop and the machinery. Read the record before changing
  anything it decides.
- `powers/` — a **generated** export of `skills/` for a second harness. **Never edit it by hand**;
  edit the source under `skills/` and regenerate with `hooks/scripts/kiro-power-build.py`.
- `scripts/` — repository utilities that are not hooks.

It is consumed by `tadeumendonca-io`, the static site that is this platform's public surface. The
skills are written **project-agnostic** — generic placeholders, never real names, domains, account
identifiers or resource identifiers — because they are published and meant to be read by strangers.

**The library is broader than its current consumer.** The `backend` skill and parts of
`cloud-infrastructure` document an architecture the consuming site **retired**; it is now fully static.
They are kept deliberately as reference patterns. **Never infer the consumer's architecture from
them** — read the consumer's own root brief.

## The floor — obligations, not descriptions of enforcement

**Every rule below is stated as something you must do, and each is true on a harness with no hooks at
all.** Where this platform also enforces one mechanically, that is a property of one harness and is
deliberately not written into the rule. Obey them because they are the rules, not because something
watches.

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
8. **One work item at a time.** One branch, one open merge request. Finish it through merge before
   starting the next.
9. **A review finding is named, never filed.** Only the owner opens work. Report what you found; do
   not convert your own finding into a tracked item.
10. **Publish a measured number with the command that produced it, inline and runnable, or do not
    publish the number.** A figure whose falsifier is missing, dead or answers a different question is
    worse than no figure, because it reads as checked.
11. **Prefer measuring to reading, and say which you did.** A claim about machinery that was read
    rather than executed is a hypothesis, in those words.
12. **Everything published on the forge is written in English** — this file, the README, commit and
    merge-request text, issues, decision records.
13. **Content is additive.** Deepen; never thin out good content to make room.

## The conventions this platform's skills enforce

1. No solo architectural decisions — ask when ambiguous.
2. Pipelines are independent per repository. Never trigger one repository's pipeline from another.
3. `snake_case` everywhere — database fields, interfaces, request and response bodies. No mapping
   layer.
4. REST: resources are nouns, HTTP verbs express the action, paths and parameters in kebab-case.
   Identifiers in paths are opaque, never enumerable.
5. Infrastructure mutation is pipeline-only.

## How work moves

Work is tracked as issues in the forge, and nothing is worked that is not tracked. Three exclusive
routing types — `product` (the deliverable), `content` (published in the owner's voice), `loop` (this
machinery) — and two state labels, `ready` (the description is closed and the item is buildable) and
`blocked`. An item without `ready` is not executable.

**Eight profiles, and each exists because a specific disagreement or a specific fresh context is
wanted** — not to complete an organisation chart:

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

The design intent behind all of it — why the loop is shaped this way, its state machine, its intake
chain — is `skills/agents-configuration/SKILL.md`. The portable engineering judgment is
`skills/engineering-standards/SKILL.md`. Read those two before proposing a change to any of it.

**The merge is the go/no-go.** A change reaches the trunk through a merge request and a gate that
judges it against the item's own requirements and against whether it can break production. Nothing
auto-merges.

## Versioning and distribution

Numeric SemVer, `MAJOR.MINOR.PATCH`, no pre-release suffix. `VERSION` at the repository root is the
current value and `.bumpversion.toml` is the bump configuration; both the version file and the package
manifest move in lockstep.

**Every merge to `main` bumps the patch and publishes a release.** That is deliberate: this repository
is a consumed dependency, and a consumer's installed copy resolves published versions — an unpublished
trunk is invisible to it, so a merge that never publishes is work that silently never ships.
**Publishing is not adoption**: every consumer updates on its own decision.

A deliberate minor or major is cut on demand from the release workflow in `.github/workflows/`.

## What is enforced here, and what your harness enforces

**Assume nothing in `hooks/` runs for you.** Those scripts are written against one specific harness's
event model and its permission layer. On that harness, several of the obligations above are also
refused mechanically. **On yours, they are obligations and nothing else** — which is exactly why they
are written above as rules rather than as descriptions of a guard.

The same split is deliberate in what this repository exports. The generated package under `powers/`
carries the **knowledge** layer and none of the **enforcement** layer, because the enforcement is
shaped for one harness and porting it is work nobody has done. Measured against Kiro `1.0.337`: its
installer copies a package's whole tree, but its loader resolves only the manifest, `skills/`, the MCP
declaration and its own directory — so shipping briefs or enforcement scripts there would put them on
disk **inert**, which reads as installed and is worse than an absent file.

## What is checked, and what no check can say

`hooks/scripts/agents-md.test.sh` asserts, on every change to this file:

- it is **tracked in git** — an untracked brief is invisible to every review and every gate, and that
  is the state this file was in until the check existed;
- it is **under the character budget**, with headroom, so growth reddens before it truncates;
- it contains **none of a declared set of tokens specific to one harness** — tool names, event names,
  configuration file names, invocation syntax;
- **every repository-relative path it names exists.**

**What no check here can assert: that this brief is TRUE, or that it is neutral rather than merely
free of the tokens on a list.** A sentence that is portable in vocabulary and false in substance passes
every arm above. Neutrality is held by whoever writes and reviews this file, and the green means only
that four mechanical properties hold.

## What this file deliberately does not carry

- **The harness-specific installation and configuration steps.** They are in `README.md` and in this
  repository's other root brief, where they belong; restating them here would put one harness's
  mechanics into the file written for the others.
- **The invocation syntax for a typed command.** Skills resolve on more than one harness; the typed
  form does not. Reach a guide by its path — `skills/<name>/SKILL.md` or `commands/<name>.md` — and
  read it.
- **Counts.** Every enumerated number in this repository ages, and a prose figure sitting beside a
  derived one is the arrangement its own drift gate exists because it rots. Where you need a count,
  derive it.
