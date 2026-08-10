# 0010. A persona's startup context is a **curated preload** — each brief declares the skills it loads in full, nothing else in the library reaches it, and the identifiers are asserted in CI because a wrong one is silent

- **Status:** accepted
- **Date:** 2026-08-10
- **Deciders:** the owner (he ordered the curation ahead of the directory split on [#172](https://github.com/tedeuxx/tadeumendonca-skills/issues/172), and ratified the five lists by labelling the Issue `ready`); curated and recorded by `tech-lead`; ordering and cross-surface half closed by `product-lead`
- **Supersedes / superseded by:** —
- **Driven by:** [#172](https://github.com/tedeuxx/tadeumendonca-skills/issues/172), implemented in [PR #178](https://github.com/tedeuxx/tadeumendonca-skills/pull/178)

## Context & problem

A persona in `agents/*.md` starts with its brief and nothing else. The library it is meant to work from —
**71 files, 449,205 bytes** under `commands/` — was, until this decision, not reachable by any of the
five at all. That is a measured claim rather than an inference, and it is the whole problem:

    git ls-tree -r -l origin/main -- commands | awk '{s+=$4; n+=1} END {print n, s}'
    → 71 449205

    git grep -n '^tools:' origin/main -- agents
    → five lines; none contains `Skill`

    printenv CLAUDE_PLUGIN_ROOT
    → exit 1   (re-derived inside the subagent shell that wrote this record, not relayed)

Three facts compose into one hole:

1. **`Skill` is not grantable through `tools:`.** [#171](https://github.com/tedeuxx/tadeumendonca-skills/issues/171)
   added it to all five briefs believing it opened an on-demand channel; the grant was inert, and
   [#177](https://github.com/tedeuxx/tadeumendonca-skills/pull/177) removed it.
2. **Nothing tells a persona where the library is on disk.** The plugin cache is readable by absolute
   path, but `CLAUDE_PLUGIN_ROOT` is unset inside a subagent shell, so there is no path to read.
3. **Therefore `skills:` is not an optimisation over reading on demand — it is the entire channel.**

That third point is what makes this a decision rather than a preference. **Every exclusion from a
`skills:` list is a real deprivation, not a deferral.** A persona that does not carry a skill cannot go
and get it, this session or any session, and no error is raised when it tries.

The failure mode of the mechanism itself compounds it. `skills:` **injects each named file's body in
full** before the persona's first turn; there is no declare-without-loading form. Measured on #172:
identifiers are **colon-separated** (`workflow:code-review`; `plugin:` and `tadeumendonca-skills:`
prefixes are accepted and stripped; a bare stem resolves tree-wide), **slash forms do not resolve**,
**there is no glob support**, and **there is no dedupe** — two identifiers naming one file inject it
twice and bill it twice. Every one of those wrong spellings fails at **0 bytes of stderr**. The persona
starts, the skill is simply absent, and nothing distinguishes a typo from a deliberate omission.

## Decision drivers

- **The context window is the constraint the roster is already built around.** It is one of the four
  reasons a persona may exist at all ([ADR-0002](./0002-agentic-dev-loop-architecture.md), tenth
  amendment). A preload spends that budget before the persona reads a single line of the work, so the
  list is bounded by **bytes, not by count**.
- **An exclusion is a deprivation, so it must be argued rather than defaulted to.** This is the driver
  that ruled out every uncurated option below.
- **A gate must not acquire a second ruler.** `quality-assurance`'s brief states its ruler is external —
  the requirements the leads agreed and the DoD — and that taste has no route to a blocker. What is
  preloaded into it is therefore a decision about what it is allowed to grade against.
- **A silent failure needs a layer that can report it.** [ADR-0008](./0008-which-layer-carries-a-control.md)'s
  standing question — *which layer can carry this control, and can that layer hold it?* — answers itself
  here: the runtime **cannot**, because it has no way to surface a 0-byte failure.
- **The tree moves under the identifiers.** [#164](https://github.com/tedeuxx/tadeumendonca-skills/issues/164)
  may flatten the family segments that nine of the ten entries carry, and a rewrite that breaks one
  identifier breaks it silently.

## Considered options

1. **A curated per-persona preload — each brief declares the skills it loads, and argues its exclusions**
   *(chosen)*. **Ten entries across five personas, resolving to eight distinct files** — seven of which
   are rows in the README's 69-row skill table, `new-issue` being top-level and not one — **79,261 B, 17.6% of the library**,
   no persona over 35 KB. *Trade-off:* the curation is **judgement with no falsifier** — no test can say
   a list is the right one — and it is a **static** grant, so there is no per-dispatch top-up when a
   slice needs something the list omits. The known bite is `developer` on a CI slice: it owns
   `.github/workflows/**` and does not carry `workflow:github-actions` (19,582 B), so the invoking
   context or the Issue has to supply that content. Also: **nine of the ten entries carry a family
   segment** — seven distinct identifiers, since two are carried by two personas each — and every one of
   them is rewritten if #164 flattens the tree.

2. **Preload nothing, and rely on on-demand access** — the state of the repo before this change.
   *Why not:* **the on-demand access does not exist.** Measured above: `Skill` is not grantable (#177),
   and `CLAUDE_PLUGIN_ROOT` exits 1 in a subagent shell. This option is not "load later"; it is "four of
   five personas can never reach any skill". It buys back 79,261 B of per-dispatch context and pays for
   it with the whole library. It is named here rather than dropped because it was the *incumbent*, it
   looked like a deferral for as long as #171's grant was believed to work, and the belief was the defect.

3. **The universal floor — *"`/principles/*` … every persona loads it"*** — the model proposed at
   [`docs/proposals/agentic-dev-loop.md:253`](../proposals/agentic-dev-loop.md) (the table header is at
   `:251`; the same claim recurs as a follow-up item at `:260`). *Why not, and it is refused on the
   record rather than passed over:* it allocates by **family**, and a preload paid in bytes cannot be
   allocated by family. **The floor is 76,490 B of `principles/*` on every dispatch — 382,450 B across
   the five, against 79,261 B for the curated set** (`git ls-tree -r -l origin/main -- commands/principles`,
   summed). One of its five members, `principles:dev-loop` at 38,702 B, is on its own **larger than the
   entire curated list of the persona that would most plausibly want it** (`developer`, 35,294 B), and
   duplicates content that brief already inlines: the intake chain, the `ready` query, the task-filing
   rule. It also fails the driver above in the one place it matters most: it would hand
   `quality-assurance` `principles:engineering-philosophy`, a second ruler with no falsifier attached,
   which is exactly how a gate starts grading impression. **The pointer is the cheap half of this
   rejection.** That proposal is superseded in substance — its *Loaded by* column still routes families
   to `frontend-react`, `iac-terraform-aws` and `devops-cicd`, three personas retired in the 19→5 merge —
   and **a superseded proposal reads as instruction until something says it was rejected.** The proposal
   is deliberately **not rewritten**; this record is the thing that says it.

4. **Preload the whole library into every persona** — the symmetric extreme, stated so the range is
   visible. *Why not:* 449,205 B per persona per dispatch, against a driver that already treats the
   context window as a first-class constraint. It also inverts the point of having five personas rather
   than one.

## Decision outcome

Chosen: **option 1.** A persona's startup context is a curated preload; the `skills:` list in its
frontmatter is the complete set of library files it can reach, and each brief carries the argument for
what was left out — because an exclusion is a deprivation and an unargued deprivation is
indistinguishable from an oversight.

The five lists as accepted, re-derived at `origin/main` rather than copied from the intake:

| persona | bytes | list |
|---|---|---|
| `developer` | 35,294 | `workflow:code-review` · `principles:verification-and-gates` · `principles:engineering-philosophy` |
| `quality-assurance` | 18,215 | `principles:verification-and-gates` · `backend:coverage` · `workflow:sonarcloud` |
| `tech-lead` | 16,857 | `workflow:adr` · `principles:engineering-philosophy` · `workflow:documentation-standard` |
| `product-lead` | 8,895 | `new-issue` |
| `harness-reviewer` | 0 | `skills: []` |

    git ls-tree -r -l origin/main -- commands/workflow/code-review.md \
      commands/principles/verification-and-gates.md commands/principles/engineering-philosophy.md \
      commands/backend/coverage.md commands/workflow/sonarcloud.md commands/workflow/adr.md \
      commands/workflow/documentation-standard.md commands/new-issue.md
    → the eight blob sizes, which sum to 63,647 B of DISTINCT bytes:
      code-review 19680 · verification-and-gates 8406 · engineering-philosophy 7208 ·
      coverage 6173 · sonarcloud 3636 · adr 5924 · documentation-standard 3725 · new-issue 8895

**63,647 distinct, 79,261 as billed** — `verification-and-gates` and `engineering-philosophy` are each
carried by two personas, and there is no dedupe **across** personas any more than within one: each
dispatch pays for its own copy.

**Two entries in that table are decisions in their own right and would otherwise read as gaps.**

- **`quality-assurance` does not carry `principles:engineering-philosophy` (7,208 B), deliberately.**
  Its ruler is external by design. A principles document is a ruler with no falsifier attached, and the
  gate is the one persona whose findings must each name a criterion and a falsifier
  (ADR-0002, amendment #6).
- **`harness-reviewer` carries an explicit empty list, not an absent key.** Its object is `hooks/`,
  `settings.json`, `agents/`, the plugin and MCP — none of which lives in `commands/`; and a preload is
  a frozen snapshot handed to the persona whose standing rule is *read the files, do not trust your
  training*, which would arm the drift it exists to catch. The spelling is load-bearing: **an absent key
  is the same glyph as a dropped one**, so the resolver requires the key on every persona and a missing
  one goes red.

**The identifier mechanics and the CI assertion are part of this decision, not a second one.** They are
the mechanism the preload depends on and the layer that holds its failure. Per ADR-0008's routing test
the control cannot sit in the runtime — a 0-byte failure has no reporter — so
`hooks/scripts/skills-resolve.test.sh` asserts, for every `agents/*.md`: the `skills:` key is present;
every identifier resolves to a **tracked** file; no `/`; no `*`; no duplicate identifier and no two
identifiers resolving to one path; a bare identifier matches exactly one file; and two anti-vacuous
guards, because a suite that silently checks nothing is the failure this class of gate is most prone to.
`agents/**` was added to `hooks-test.yml`'s path filter in the same MR — without it, a PR editing only a
`skills:` list would not have triggered the one check that can see a broken identifier.

**What the assertion does not cover, said plainly:** whether a list is the **right** one. That is
judgement, it is recorded here, and no test can hold it. And it reads the same tree the loader reads
without being the loader — it catches a broken reference, not a broken loader.

## Consequences

**Good**

- **Four of five personas can reach a skill at all**, for the first time since the roster was written.
  That is the honest headline of this change; *"the unblock for the roster column"* undersells it.
- **The association between a persona and its skills is data**, in frontmatter, rather than prose in a
  README — which is what lets a generator publish it and a test check it.
- **Each exclusion is argued in the brief that suffers it**, so the persona knows what it does not have
  and can say so in its report instead of hallucinating the content.
- **The silent-identifier failure is a red build**, proven by mutation against the source rather than by
  reading: twelve mutations on #178, three of which found real defects in the resolver — flow-style
  lists reported as *"deliberately empty"*, a whole-file rather than frontmatter-scoped scan, and quoted
  items as a phantom red.

**Bad / accepted costs**

- **The curation has no falsifier and never will.** The gate proves an identifier resolves; nothing
  proves the list is right. The only instrument is the persona reporting when an omission bit it.
- **A `skills:` list is static.** There is no per-dispatch top-up, so `developer` on a CI slice works
  without `workflow:github-actions` and cannot fetch it. Named as the first entry to add if pipeline work
  becomes frequent.
- **Nine of the ten entries carry a family segment** — seven distinct identifiers — so a flatten under
  #164 rewrites every one of them. The
  resolver is what turns that from silence into a red build, which is the argument for building it now
  rather than with the split.
- **`backend:coverage` is now published in a third place under a stem that misdescribes it.** Post-#174
  that file is the gate policy for *both* stacks while still sitting under `backend/`. Accepted knowingly
  rather than renamed here: a rename is a breaking change to the invocation surface, it would force a
  deliberate MAJOR for a naming defect, and #164 would force a second one shortly after.
- **The repo now publishes two allocations of skills to personas** — *whose domain* (hand-maintained in
  `skills-table.py`'s `WIELDER` map, 69 rows, nothing checks it) and *what is preloaded* (ten entries,
  checked). They answer different questions and they visibly disagree — `developer` preloads two
  `principles/*` skills that the domain column puts under the judging personas. The README says so in
  its own voice and says which of the two has a gate behind it. **Reconciling them into one column was
  the alternative and was rejected**: it would print *"— none"* against 62 of 69 skills, deleting true
  information to resolve what is a heading problem.
- **The roster column on the consumer's architecture page is not delivered by this decision**
  ([`tadeumendonca-io#413`](https://github.com/tedeuxx/tadeumendonca-io/issues/413)). Until it is
  generated **and** covered by the drift check, that page's own claim that *nothing compares this table
  to anything* stays true of it, and no *verified* claim should be published about it.

## Links

- Driving Issue [#172](https://github.com/tedeuxx/tadeumendonca-skills/issues/172) — the consolidated
  demand, the five lists with the byte figures behind them, and the ordering call (curate before the
  directory split) — implemented in
  [PR #178](https://github.com/tedeuxx/tadeumendonca-skills/pull/178), whose *Not done* section is the
  obligation this record discharges.
- [#177](https://github.com/tedeuxx/tadeumendonca-skills/pull/177) — *`Skill` is not grantable through
  `tools:`*, which removed [#171](https://github.com/tedeuxx/tadeumendonca-skills/issues/171)'s inert
  grant and is the measurement that makes option 2 untenable.
- [ADR-0002](./0002-agentic-dev-loop-architecture.md) — **cited, not amended.** Its four-reason rule
  explains why the roster is five; curating what those five preload does not change why any of them
  exists, and the context-window reason is one of the four this record leans on.
- [ADR-0009](./0009-a-skill-description-is-a-trigger-not-a-title.md) — **cited, not amended.** It owns
  *how a skill is discovered* — the `description` as the matcher's trigger. A `skills:` preload
  **bypasses discovery entirely**: the file is injected whether or not any description would have
  matched. Adjacent, not a correction, and the two mechanisms load the same files by different routes.
- [ADR-0008](./0008-which-layer-carries-a-control.md) — **cited, not amended.** Its routing test is why
  the resolver assertion is in CI and not in the runtime.
- [`docs/proposals/agentic-dev-loop.md:253`](../proposals/agentic-dev-loop.md) — the **universal floor**,
  rejected as option 3. The proposal is left as written; this pointer is what stops it reading as
  instruction.
- Open and deliberately **not** pre-empted:
  [#164](https://github.com/tedeuxx/tadeumendonca-skills/issues/164) (tree shape — the identifier rewrite
  above) and [`tadeumendonca-io#413`](https://github.com/tedeuxx/tadeumendonca-io/issues/413) (the
  published roster column).
- **Evidence re-derived at `origin/main` on 2026-08-10, not relayed:** the two `git ls-tree` commands
  above for 71 / 449,205 B and the seven file sizes; `git grep -n '^tools:' origin/main -- agents` for
  the absent `Skill` grant; `printenv CLAUDE_PLUGIN_ROOT` → exit 1, run in the subagent shell that wrote
  this record; and `grep -n 'universal floor\|Skill group' docs/proposals/agentic-dev-loop.md` → `251`
  (header), `253` (the claim), `260` (the follow-up item).
