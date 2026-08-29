# The blueprint registry — the obligations this harness holds, and what each one does not do

**This file is the artifact.** It is **authored**, not generated. `/blueprint` (`commands/blueprint.md`,
built at #313 slice 2) is a *projection* of this file plus a fresh read of the tree; it renders, it
never writes — and it is row `0036` below, like every other mechanism this harness ships. The decision
and its rejected options are recorded in
[ADR-0021](./adr/0021-the-blueprint-registry-is-authored-generation-verifies-it.md).

**A row is a BEHAVIOUR, not a file.** One behaviour may span two rules of one file (`0003`), two files
(`0011`, `0020`), three (`0005`) or **none at all** (`0017`) — and one file may carry two behaviours
(`0025`/`0026`, `0027`/`0028`). A registry keyed on files could express none of that, and
the `o que não faz` column is what forces the split: two limits that could not be pasted under one
another are two rows.

**Field labels are the ones the owner ratified, in Portuguese; the content is English** like everything
else this repo publishes. The labels are a parsing contract as well as a heading —
`hooks/scripts/inventory-counts.test.sh` reads them literally.

## How to read a row

| field | what it holds |
|---|---|
| `id` | zero-padded numeric, **assigned once, never reused, never re-sorted**. A rename changes `nome`; a consolidation changes `carrier`; neither changes `id`. Only an **abandoned** obligation is tombstoned, under `## History` below. |
| `tipo` | one of five, closed and gated: `refusal` · `review` · `record` · `knowledge` · `routing`. A name outside the set reddens the suite. |
| `nome` | the behaviour's short name, in the heading beside the id. Not an identifier — the `id` is. |
| `carrier` | repo-relative path(s) in backticks, or the literal `none` (a behaviour no file carries) or `retired`. Every path is asserted to exist. |
| `descrição` | what the element *is*, in one line. Supporting, not load-bearing. |
| `propósito` | **why the behaviour is wanted** — the obligation, stated so a reader on a harness nobody here has measured can decide whether it matters to them. Never a content list. |
| `o que faz` | **what actually happens** when the carrier runs, at the grain a foreign implementer would need. |
| `o que não faz` | **the limit.** The most transferable cell in the row: a limit is a property of the strategy, so it ports even where the mechanism does not. |
| `citação` | the carrier's **own words** about its limit, verbatim, or the literal `no limit stated in the source`. Asserted to appear in the carrier file. |

## What no gate here can hold — read this before reading a green

**`propósito` is unfalsifiable, and so is the reasoning inside `o que faz`.** No instrument in this
repository can tell a true purpose from a plausible one, or a limit that is complete from one that is
merely well-written. A behaviour whose reasoning went stale two months ago passes every check in
`inventory-counts.test.sh` — the same residual `documentation-standard` already states about an
absorption fold: *whether the fold was lossless is a reviewer's judgement and there is no instrument
for it.*

**Exactly one half is gateable and it is `citação`**, because a quote is greppable and a paraphrase is
not. What the gate asserts: the quoted string appears verbatim in the carrier. What it does not
assert: that the quote is the *relevant* limit, or that `o que não faz` is a fair reading of it.

**A row whose `citação` reads `no limit stated in the source` is a finding about the element**, not a
filled cell — the carrier does not state what it declines to do, and someone should decide whether it
should.

## Coverage — which classes this registry claims completeness over

**`absent` is a value, never a missing row**, and the same rule applies one level up: an incomplete
class is *declared* incomplete rather than left to look finished. The gate reads this table in both
directions — a class declared `complete` with an unclaimed element reddens, **and a class declared
`partial` with nothing left unclaimed reddens too**, because a stale declaration that under-claims is
as misleading as one that over-claims.

| class | enumerated from | claimed |
|---|---|---|
| `persona` | `agents/*.md` | complete |
| `hook` | the commands registered in `hooks/hooks.json` | complete |
| `command` | `commands/*.md` | complete |
| `skill` | the paths declared in `.claude-plugin/plugin.json` | partial |

**What `partial` means here, exactly, and why it was not padded to look complete.** Ten `knowledge`
rows over eight carriers landed; six skills have no row yet — `backend`, `frontend`,
`cloud-infrastructure`, `definition-of-done`, `planning-poker`, `license`. The three reference skills
are where `o que não faz` is hardest and least quotable (measured: `cloud-infrastructure` is 21 service
sections whose limits are per-section, not per-file), and `license` states no limit anywhere in its 25
lines, so its cell is already known to be a finding rather than a sentence. Authoring six rows at the
ratified depth is a sitting of its own with the owner's layer in it; producing six thin ones to turn a
declaration green is the failure this file's own `citação` rule exists to prevent.

---

## `refusal` — prevented mechanically, before the act

### 0001 · the irreversible floor

- **tipo:** refusal
- **carrier:** `hooks/scripts/permission-guard.sh`
- **descrição:** A `PreToolUse` hook on the `Bash` matcher, shipped with the plugin, that inspects the command string and denies the acts whose effect escapes git.
- **propósito:** The danger is never "the wrong environment" — it is **irreversibility that escapes version control**: cloud state, secrets, remote refs on a protected branch, live traffic. A harness whose floor is a written instruction has no floor, because the same model that would skip the instruction is the one trusted to remember it.
- **o que faz:** Reads the tool call's command string before it runs and returns a `deny` decision for the acts on the floor — infrastructure mutation, secret writes, force-push and hard reset, `rm -rf`, `--dangerously-skip-permissions`. It unwraps the common indirections (`bash -c`, quoting forms) so a wrapped payload is matched rather than hidden. It is deliberately **branch-agnostic**: no `git branch` call, no environment-name matching, so one hook is correct under both loop models.
- **o que não faz:** It matches a **string**, not a program. It cannot decide anything that depends on the *class* of a change rather than its spelling — which is why the merge decision is a persona's and not a rule's — and it cannot claim completeness over the set of spellings that reach it. It fails **open** on a parse error, by design: a floor that crashes closed stops a session that has done nothing wrong.
- **citação:** > "a regex over a shell grammar is not provably complete."

### 0002 · a command the matcher cannot decompose is refused before it reaches a human

- **tipo:** refusal
- **carrier:** `hooks/scripts/permission-guard.sh`
- **descrição:** The same guard's rules on shell *shape* — chained commands, command substitution, output redirection into a file.
- **propósito:** A permission matcher reads **one command prefix**. A chain, a substitution or an env-var prefix cannot be decomposed by it, so an otherwise-allowlisted command stops for a human on its punctuation alone. Refusing the shape immediately, with a message that says how to spell it instead, converts an unbounded stream of prompts into one corrected habit.
- **o que faz:** Denies `&&` / `;` / pipe chains, and denies `>` / `>>` redirection that would create a file, returning the replacement route in the denial text (`git -C`, `npm --prefix`, the `Write` tool). The redirect rule was made mechanical only after guidance alone was measured to keep failing.
- **o que não faz:** It does not distinguish a redirect that creates a file from one that does not, beyond the stream-to-stream forms it excludes by construction: `2>/dev/null` creates nothing and is denied anyway. That false positive is **named here rather than worked around** — it cost three retried calls in the dispatch that authored this row — and it is not in the rule's own list of accepted false positives. Repairing it is a one-token exemption, and it is a decision for whatever slice next touches that file.
- **citação:** > "The matcher reads one command prefix, so a chain prompts the human even when every part is allowlisted."

### 0003 · the actor that orchestrates may not perform the irreversible act

- **tipo:** refusal
- **carrier:** `hooks/scripts/permission-guard.sh`
- **descrição:** Two rules of one file — trunk push and merge — keyed on an actor-identity field the harness stamps and the model cannot forge.
- **propósito:** An orchestrator that can merge can merge the output of its own dispatch, which turns the gate from a **control** into **advice**. The obligation is not "the orchestrator is disciplined"; it is that the actor holding the dispatch cannot also close the loop it dispatched.
- **o que faz:** Reads the caller's agent type from the hook payload. The orchestrator is the actor with **no persona of its own**, so its value is empty by construction — the two rules fire against that empty value and deny the push to the trunk and the merge, whatever the command's spelling.
- **o que não faz:** It does not verify that a review **happened**, or that it was any good; it only refuses one actor one act. And it needs a harness-stamped identity field to key on: a harness whose hook payload carries no caller identity cannot hold this floor at all, and should say so rather than claim it.
- **citação:** > "These rules enforce ROUTING, not capability."

### 0004 · review does not open work

- **tipo:** refusal
- **carrier:** `hooks/scripts/permission-guard.sh`, `agents/developer.md`
- **descrição:** A rule denying `gh issue create` to every dispatched persona, with one narrow exception carried in a brief.
- **propósito:** An agent that turns its own finding into a tracked item has **decided** that something should exist and is asking for agreement afterwards. Measured once: a queue grew by 19 issues net in a single session, roughly 13 of them born inside a review of something else. Findings are named in a verdict; the owner decides what becomes work.
- **o que faz:** Denies the create call by agent type. Reading, listing, commenting, labelling and closing stay open everywhere — the rule is about **origination**, not about the tracker. The one exception is decomposition: the builder may file a child task under a story that already carries `ready`, and the gate verifies that on the task's own merge request.
- **o que não faz:** It cannot tell a finding that *should* have been filed from one that was correctly left in a verdict, so the accepted cost is real and is stated where the rule lives: fewer things tracked, and some genuine findings lost. It also does nothing about work opened by the owner that should not have been.
- **citação:** > "intent is not in the command string"

### 0005 · the actor that drafts published prose may not publish it

- **tipo:** refusal
- **carrier:** `hooks/scripts/permission-guard.sh`, `agents/content-writer.md`, `agents/content-reviewer.md`
- **descrição:** Rule 5e — the three personas that read the private positioning layer are denied every direct posting route.
- **propósito:** The personas that draft in the owner's voice are the ones that have read private source material, so they are exactly where an unreviewed paraphrase of it would land on a public surface. Containment is worth more here than speed, and it must be **mechanical**: a brief saying "never post" is an instruction, and an instruction is only as strong as the model's attention.
- **o que faz:** Denies the posting commands to those agent types, leaving them the route the loop wants anyway — a draft on a tracked file, on a branch, reviewed before anything reaches a reader.
- **o que não faz:** It does not read what is drafted, so it cannot tell private material from public. It contains the **route**, never the content — the truth of a published claim stays a persona's blocking judgement at the merge gate, with no instrument behind it.
- **citação:** > "it never posts to a public surface, mechanically (permission-guard.sh rule 5e)"

### 0006 · the orchestrator does not edit the tree with its own hands

- **tipo:** refusal
- **carrier:** `hooks/scripts/orchestrator-write-guard.sh`
- **descrição:** A `PreToolUse` guard on the file-writing tools, denying a main-context write inside any git working tree.
- **propósito:** Between the two acts already denied — trunk push and merge — everything was open, so a session could do the whole build in the main context and never dispatch the builder that owns it. That is not a floor violation: the work is tracked and revertible. It is the **wrong layer**, and its cost is that no persona's judgement, and no gate keying on a persona, ever touches the change.
- **o que faz:** Denies by **scope** — inside a git working tree → deny — rather than by allow-listing the exempt paths, so the session scratchpad and the memory layer stay writable without anyone deriving a path shape the harness is free to change. The matcher is a full enumeration (`Edit|Write|MultiEdit|NotebookEdit`) because a matcher is anchored, not a substring search, and the shorter spelling was measured leaving a notebook write through.
- **o que não faz:** It guards the file-writing **tools** only. The `Bash`-side write routes — `sed -i`, `tee` — are deliberately not blocked, and the census below is what keeps them visible instead. It also decides nothing about whether the delegation that should have happened was the right one.
- **citação:** > "Two matchers, two scripts, one concern each."

### 0007 · one slice in flight

- **tipo:** refusal
- **carrier:** `hooks/scripts/wip-guard.sh`
- **descrição:** A `PreToolUse` guard bounding work in progress at the pull-request boundary.
- **propósito:** Stacked branches go stale and turn their own merge into a conflict resolution. The obligation is that the queue is **drained**, not grown — and it is worth a mechanism because the pressure to start a second thing is highest exactly when the first one is blocked on someone else.
- **o que faz:** Intersects the changed files of the proposed pull request against those of the open ones and denies on overlap, with a sibling-task exemption for two pull requests whose source Issues declare the same parent.
- **o que não faz:** **The mechanism and the written policy disagree, and the policy is the stricter of the two.** The hook bounds on file *overlap*; the loop's own rule has been one worktree, one branch, one open pull request since 2026-08-13, full stop. So the hook permits a second, disjoint pull request that the policy forbids. **It also never runs its own overlap check while that policy is obeyed** — it lists only *open* pull requests, so with the previous one already merged the list is empty and it exits before comparing a single path; measured across fourteen consecutive merged pull requests, not one had another of the same author open at its creation. **And it is blind to the object the policy is actually about.** A shared *checkout* is not a shared *file*: two agents in one working tree produce the same file list, and this guard cannot distinguish them — it never asks which tree it is in. **That gap cannot be closed here, and the reason is the moment rather than the matcher.** It fires on the pull-request creation, the last act of a slice, while a two-agents-in-one-tree failure — a measurement read off the wrong branch, an edit written to the wrong tree — completes during the build. The control that would hold it is a lease on the checkout taken at the first write, which is a different mechanism and is named as owed. **Follow the policy; nothing here enforces it.**
- **citação:** > "The bound is FILE OVERLAP, not a count. ONE level, and there is no second."

### 0035 · a dispatch is refused when the premise its brief states is not true

- **tipo:** refusal
- **carrier:** `hooks/scripts/dispatch-premise-guard.sh`
- **descrição:** A `PreToolUse` guard on the dispatch tool, comparing a brief's stamped commit and branch against the repository the brief's own citations resolve to.
- **propósito:** A dispatched actor inherits its brief's premise and cannot check it — it was not present when the measurement was taken. So a brief that cites one tree and stamps another spends a full review on a state that no longer exists, and nothing anywhere says so: measured once, two lead dispatches and roughly 210k tokens against copy that had already been corrected. The obligation is that **the premise of a dispatch is an object something reads back**, before the dispatch and not after, because after is a report with the bill already paid.
- **o que faz:** Reads the brief out of the dispatch payload and extracts claims of ONE declared shape — a ref and the commit it is stamped at, together, where the ref resolves in the target repository. A local branch asserts where the tree *is* (branch and HEAD both checked); a remote-tracking ref asserts only where that ref points. The stamp is attributed to a single repository using only the brief's **distinguishing** citations — a path present in several repositories attributes nothing and is dropped — falling back to the caller's working directory when none distinguishes. A claim that fails there denies the call outright, naming the tree it read and what it found.
- **o que não faz:** It checks the **tree**, never the lines: a `file:line` citation is out of scope by decision, since whether a file says what a brief claims is prose-reading and a guard that reached for it would fail open on exactly the half that matters. **A bare SHA is never checked** — a merge-base, a PR head or a quoted verdict marker is a reference, not a premise, and treating one as a premise denied 8.0% of 859 real briefs for no reason. A **cross-repository** brief is not checked at all: one stamp, two repositories, no fact available to attribute it, so a guess reported as a control would be worse than the declared gap. And it decides nothing about a **stale Issue** — the check lives at dispatch, against the brief; an Issue that described finished work was already stale before any dispatch happened, which is a different mechanism at a different moment.
- **citação:** > "So passing this guard means the TREE is what the brief says, never that the LINES are."

### 0037 · an Issue is not closed by hand while the artifact it promised is missing

- **tipo:** refusal
- **carrier:** `hooks/scripts/closure-artifact-guard.sh`
- **descrição:** A `PreToolUse` guard on `gh issue close`, resolving the `invocable:` lines of the Issue's own body against this tree.
- **propósito:** A closing keyword knows nothing about whether the thing an Issue promised exists. Measured here: three Issues closed with their operable half unbuilt, one of them twice, and every instance was caught by a human asking. The obligation is that **the tracker's word for "done" is held against an artifact a reader can reach**, at the moment the state changes rather than in a review that may not happen — because the authorable half always ships first, and the half that ships second is the one nobody re-checks.
- **o que faz:** On a close aimed at this checkout's own repository, reads the Issue body, extracts every entry declared at column 0 as `invocable:`, and resolves each one: a `/name` against `commands/name.md` or a `skills/name/SKILL.md` **that `plugin.json` also declares**; anything else as a repo-relative path. An entry carrying an `invocable-waived:` line with a reason of at least twelve characters is passed. Anything left unresolved denies the call and names it, with the three exits stated in the deny text — build it, record the narrowing, or leave the Issue open.
- **o que não faz:** **An Issue that declares nothing is invisible to it, and nothing forces the declaration** — the field is written at intake by instruction, so this refuses a stated promise and never discovers an unstated one. It deliberately does **not** derive the promise from prose: measured over twenty closed Issues, the tightest derivation worth trying produced eleven unresolved identifiers and zero true positives, so a derived form would redden on honest work until it was loosened into nothing. It resolves **existence, never behaviour** — an empty file passes. A close aimed at another repository is skipped rather than guessed at. And it **fails open** on a missing `gh`, an API error or an unreadable body, so a silence from it can mean *checked and clean* or *could not check*.
- **citação:** > "AN ISSUE THAT DECLARES NOTHING IS INVISIBLE HERE, AND NOTHING FORCES THE DECLARATION."

---

## `record` — a durable artifact makes a decision or an event findable later

### 0008 · a session knows which build of the harness it is running

- **tipo:** record
- **carrier:** `hooks/scripts/session-plugin-version.sh`
- **descrição:** A `SessionStart` hook that reports the installed plugin version and whether it is behind the source.
- **propósito:** The harness a session **runs** is an installed build, not the merged tree. A fix can be written, reviewed, merged and released and still have no effect on the machine it was written for — measured: a guard rewrite merged, and the session was three versions behind and still running the old logic. Worse, the lag is misattributed: an agent seeing a guard behave unexpectedly reasons about the rule instead of the version.
- **o que faz:** Reads the installed build at session start and injects it as context, so every claim made about a hook in that session can be read against the build that was actually running.
- **o que não faz:** It never blocks, and it reaches the **parent** context only — a subagent never sees a `SessionStart` notice, which is precisely the actor most likely to be reasoning about a hook. And it does not update anything: knowing the build is behind is not being on it.
- **citação:** > "Removing the silence does not make the guard fail closed. It makes an accepted cost observable."

### 0009 · an outstanding gate verdict surfaces at the end of the turn that ignored it

- **tipo:** record
- **carrier:** `hooks/scripts/zombie-loop-detect.sh`
- **descrição:** A `Stop` hook reading the same committed verdict artifact the session-start hook reads, but at the end of every turn.
- **propósito:** A loop can go zombie for a whole session: a dispatch is narrated and the call is never made, and nothing is watching a **turn** ending. One turn late is a different order of failure from one session late.
- **o que faz:** Reads the current branch's open pull request for the gate's own verdict marker at its current head, and surfaces an outstanding change-request or pending-human verdict as context at the end of the turn, debounced so it does not fire every turn.
- **o que não faz:** **Detection, never prevention** — a `Stop` hook fires after the work already happened, so there is nothing left to refuse. It reads committed loop state and nothing else: it cannot tell narration from a tool call that was never attempted.
- **citação:** > "It never parses prose."

### 0010 · what the orchestrator did with its own hands is visible at the end of a turn

- **tipo:** record
- **carrier:** `hooks/scripts/orchestrator-tool-census.sh`
- **descrição:** A `Stop` hook that lists the main context's own tool calls, with the write/post class separated from the reads.
- **propósito:** One class of orchestrator over-reach is unambiguous and mechanically deniable; the rest — reads, comments, the routes the floor deliberately allows — is a **habit**, and a habit nobody observes is a habit nobody can correct. Making the shape of a session visible is what makes leaving that half unmechanised affordable.
- **o que faz:** Reads the main agent's transcript, which by construction holds the orchestrator's own calls and not a subagent's, classifies each call by its **label** rather than by a substring of the whole command string, and emits a notice only once the write/post class has grown past a threshold since the last one.
- **o que não faz:** **It gates nothing and cannot** — it fires after the act, emits no decision, and every exit path is a success. It counts **attempts, not effects**: a write denied by another hook still appears in the transcript and is still counted, which is stated in the notice itself every time rather than quietly corrected.
- **citação:** > "THIS GATES NOTHING. IT CANNOT."

### 0011 · a dispatch leaves a measurable trace on the Issue it was working

- **tipo:** record
- **carrier:** `hooks/scripts/dispatch-metrics-start.sh`, `hooks/scripts/dispatch-metrics-stop.sh`
- **descrição:** A pair of subagent lifecycle hooks; the stop half posts a structured comment, the start half is registered for symmetry and is close to a no-op.
- **propósito:** A loop that cannot say what a dispatch cost cannot be tuned. Four figures were asked for — rework rounds, time per dispatch, findings per persona, token cost — and the obligation is to **record** them where a later pass can query them, not to interpret them now.
- **o que faz:** Derives the figures from the dispatch's own transcript and posts one structured comment per dispatch on the Issue being worked, sized to stay well inside the comment cap and carrying no raw dispatch input or output onto a public surface.
- **o que não faz:** **No dashboard, no aggregation, no analysis** — logging only, on the owner's own instruction. And "time per dispatch" is not "time in a loop state": the hook has no visibility into the state table, only into one dispatch's span. The start half is worth knowing about mostly for what it is *not*: every field it carries is recoverable from the transcript the stop half already reads.
- **citação:** > "WHAT THIS DOES NOT DO: no dashboard, no aggregation, no analysis."

### 0012 · a decision that explains the current codebase is findable, and one that no longer does leaves a marker

- **tipo:** record
- **carrier:** `docs/adr/README.md`, `skills/documentation-standard/SKILL.md`
- **descrição:** The methodology decision library — one numbered record per architecturally-significant decision, a closed capability set, and four dispositions for a record that is leaving.
- **propósito:** A per-task agent context cannot remember what was already decided, so isolated contexts re-decide and drift. The library is the **durable shared brain**. Its second obligation is the harder one: a record whose subject was switched off does not merely fail to help — an agent reads **bodies**, not status lines, and rebuilds what was cut on purpose.
- **o que faz:** Records the context, the options weighed, the choice and its consequences, including the rejected paths. A record leaves only as one of four dispositions, never as an absence, and every issued number is asserted — in both directions, against a **declared ceiling** rather than the highest surviving file, because a deletion at the top of the sequence leaves no gap to find.
- **o que não faz:** It does not check that a decision *was* recorded — the significance gate is a judgement made at intake, by whichever lead holds the decision, and nothing enumerates the decisions that were never written down. Where a record is absorbed, the destination's **existence** is gated and its **content** is not: a row pointing at a document that never received the decision passes exactly like one pointing at a document that did.
- **citação:** > "Whether the fold was **lossless** is a reviewer's judgement and there is no instrument for it."

### 0034 · a link to a review artifact is a summons, and one is sent only when the act is the human's

- **tipo:** record
- **carrier:** `hooks/scripts/premature-pr-link-detect.sh`, `commands/autonomy-on.md`
- **descrição:** A `Stop` hook reading the turn's own assistant prose for pull-request links, paired with the operative rule in the command that drains the backlog.
- **propósito:** An agent that hands a human a link to a review artifact is **summoning** them, whatever the surrounding prose claims — a link in a hand reads as *something is waiting for me*. Whether that reading is right is a property of **where the harness put the merge authority**, not of the link: in a loop whose gate merges everything but a named exception list, almost every review link is unactionable, and in a loop that holds a whole class for a human, most of them are. **An adopter must recompute which case they are in before adopting this at all** — porting the narrow form into a harness that holds a class for its human would suppress exactly the links that human needs.
- **o que faz:** Reads the assistant's own text for the turn that just ended, extracts links to review artifacts, and for each asks three mechanical questions of the artifact itself — is it still open, has every check on its current revision completed and succeeded, and does the gate's own verdict at that revision name the human as the remaining actor. Anything else is reported back into the next turn with the reason, once per (artifact, revision) per session.
- **o que não faz:** **Detection, never prevention** — it fires after the text has already reached the human, so there is nothing left to refuse. It reads the agent's prose and never a tool's output, because the tool that opens the artifact prints the link itself and a rule written against the character sequence would forbid nothing while looking strictest. And it is **blind to the shorthand the rule recommends**: where a tracker shares one number space between issues and review artifacts, a bare number cannot be classified without a network call, so the form the rule endorses is the one nothing checks. **If the link the human relied on was their only signal that something shipped, suppressing it is a net loss until something replaces it — name the replacement, or accept in writing that there is none.**
- **citação:** > "It polices the form the rule discourages and is blind to the form it endorses."

### 0036 · the harness can state what it is to a reader who does not run it

- **tipo:** record
- **carrier:** `commands/blueprint.md`
- **descrição:** The `export` mode of a typed command that renders this registry, plus a fresh read of the tree, as two documents from one read — a Markdown blueprint printed for a reader and a YAML interchange file written to the session scratchpad — both stamped with the commit they describe.
- **propósito:** A harness that can only be understood by running it cannot be **compared** to another one, and comparison is the whole reason to write any of this down. The obligation is that this harness's design leaves it in a form a reader on different machinery can evaluate — obligation first, mechanism as evidence — so that what ports (the obligation, the strategy, and above all the limit) is separable from what is local accident (our matcher, our event names, our directory layout). An interchange additionally needs something to **hand over**, which is why the export produces an artifact and not only a rendering.
- **o que faz:** Reads identity at invocation from the four sources that *register* a mechanism rather than from a directory listing, reads the authored obligations from this file, and renders both shapes in one invocation — two renderers over one read cannot drift because there is no interval between them. The Markdown carries a currency header (plugin, version, commit, tree state, and the commands that reproduce every count), the field contract, the residual this registry states about its own unfalsifiable cells, the rows grouped by `tipo`, the coverage declaration **with a partial class's unclaimed elements named**, and an identity appendix as evidence. The YAML translates each row into the foreign interchange shape and carries the limit column across as an **optional extra field**, which the format's own compatibility rule permits — so the one cell that actually ports is not dropped to fit a schema.
- **o que não faz:** It **never writes inside a repository** — the artifact goes to the session scratchpad, which is in no diff, no gate's input and no consumer's reach, so it cannot become the second source of truth an ageing committed projection would be. It never edits this file. It cannot tell a true obligation from a plausible one; it carries this file's cells forward exactly, residual included, and a green anywhere in this suite says nothing about them. **`always_loaded` is flattened on the way out** — a per-persona property here, a per-mechanism field there — and a `carrier: none` row is emitted as `surface: none`, which is a value outside the foreign schema's set and may be rejected by a strict reader. Its `enforcement` axis measures **refusal only**: a mechanism that acts without refusing is classed `documents`, a strain named in the format rather than resolved by a fourth value.
- **citação:** > "Never write inside a repository."

**The strain in `record`, named the same way `0018`/`0019`'s is.** The five values hold no `export`
class, and `0036`'s artifact is produced **on demand and never persisted** — the opposite of the
durability the `record` heading claims. It is filed `record` on the reading that the currency header is
what makes the document findable-and-checkable later, which is true and is not the whole truth. The set
is closed and is **not** reopened on one row. **The 2026-08-29 rewrite made the strain sharper rather
than milder**: the export now writes a file, and the file is in the one place nothing can resolve later,
so the row claims durability for a document whose whole safety property is that it is unfindable. Named
here, not smoothed over.

### 0038 · an Issue that already closed with its promised artifact missing is said out loud

- **tipo:** record
- **carrier:** `hooks/scripts/closure-artifact-guard.sh`
- **descrição:** A `Stop` hook that reads the recently-closed Issues of the current repository and reports any whose own body declares an artifact this tree does not have.
- **propósito:** The refusal at `0037` reaches one route and the loop mostly uses another: a close executed by the forge itself, on merge, from a keyword in a PR body. **No hook can observe that close and no permission layer can deny it**, so the obligation is that the failure is at least *stated* on the turn it happened, rather than surviving until somebody thinks to ask. The gap being closed is a week wide in the worst measured case, and the thing that closed it was a question from the owner.
- **o que faz:** Bounds the pool server-side with a rolling fourteen-day `closed:>=` window (one API call per turn end), applies the same declaration predicate `0037` applies, and emits the offenders as context on the next turn with the three exits named. Each finding is reported once per session per Issue, so a parked decision does not nag every turn.
- **o que não faz:** It is **detection and never prevention** — by the time it speaks, the tracker already says the work is done, and the reversal is a human act. It inherits every limit of `0037`'s predicate (nothing forces the declaration; existence rather than behaviour; fails open and silent). It reads only the repository the session is standing in. And the debounce it uses to stay quiet is indistinguishable, from the outside, from the finding having been repaired.
- **citação:** > "It resolves EXISTENCE, never behaviour."

**The same strain `0036` names, in the opposite direction.** A `Stop` hook's `additionalContext` is not
durable at all — it reaches the next turn and is gone. It is filed `record` on the precedent `0009`
already set for `zombie-loop-detect.sh`, whose artifact is the same shape, rather than on a claim that
the notice persists. **What is durable here is the Issue body it reads**, not the notice it writes.

---

## `routing` — what work exists, what state it is in, who acts next

### 0013 · the open queue is stated to a session before work begins

- **tipo:** routing
- **carrier:** `hooks/scripts/session-wip.sh`
- **descrição:** A `SessionStart` hook that surfaces the open pull-request queue.
- **propósito:** The guard above stops the queue **growing**; this stops it staying **invisible**. Inherited work sat open across sessions and surfaced only because somebody thought to look — which is exactly the kind of state a session should be *told*, not asked to remember.
- **o que faz:** Lists the open pull requests and injects them as context at session start, alongside the gate-verdict state that the end-of-turn hook also reads.
- **o que não faz:** **Injects context, never blocks** — a session must always be able to start, so it is silent on every error: no CLI, no auth, no network, not a repository. An unavailable queue reads exactly like an empty one, and nothing distinguishes them.
- **citação:** > "Injects context, never blocks. A session must always be able to start."

### 0014 · a ready backlog is drained without asking on in-pattern work

- **tipo:** routing
- **carrier:** `commands/autonomy-on.md`
- **descrição:** A typed command that runs the queue end to end, one slice at a time, through the full loop.
- **propósito:** A loop that asks a human on in-pattern work is a **design defect**, not mere friction: the human's residual should be the irreversible and the architectural, and nothing else. The command exists so that residual is *stated* rather than rediscovered per slice.
- **o que faz:** Picks, builds, reviews and merges slices one at a time against the stated order, stopping only where the owner's judgement is genuinely required, and reports product slices against hygiene slices at the end.
- **o que não faz:** It is not intake and must not become it — it works what is already tracked and `ready`, and does not capture a new request. The product/hygiene split it reports is a **measurement, not a process**: nothing durable records it, so no gate can key on it and none should.
- **citação:** > "Not for capturing a new request (see new-issue)."

### 0015 · autonomy ends with a stated close-out rather than by going quiet

- **tipo:** routing
- **carrier:** `commands/autonomy-off.md`
- **descrição:** The paired command that ends autonomy mode.
- **propósito:** **Nothing ships half-done.** Ending autonomy by simply stopping leaves the in-flight slice in a state nobody has named, and the difference between "waiting on you" and "stuck" is invisible from the outside.
- **o que faz:** Finishes the in-flight slice to merge, starts nothing new, and posts a closing summary — merged, open, blocked, split by routing type.
- **o que não faz:** It closes nothing and decides nothing about the backlog; the criterion-bearing close of an Issue is the owner's act. It also carries no trigger of its own — like the close-out pass the loop already specifies in full, it fires only when somebody invokes it.
- **citação:** > "Not for capturing a new request (see new-issue)."

### 0016 · a request becomes a tracked Issue with its description closed, or with the reason it is not

- **tipo:** routing
- **carrier:** `commands/new-issue.md`
- **descrição:** The intake command — search for the decision that already exists, run the two-lead intake, open the Issue.
- **propósito:** The owner is the only origin of work, and that rule was costing him: filing by hand is friction exactly where the loop wants none. The command makes the *cheap* path the *tracked* path.
- **o que faz:** Searches for the decision that already exists before opening anything, runs the intake that closes the description between the two leads, and opens the Issue with the routing type applied — or opens it stating plainly why the description could not be closed.
- **o que não faz:** It does not apply `ready` for a loop-typed Issue: that transition is the owner's alone. And it cannot verify that the leads actually closed the description rather than one nodding it through — the label is auditable and attributable, never proven.
- **citação:** > "Not for executing issues already filed (see autonomy-on)."

### 0017 · nothing is worked outside the tracker

- **tipo:** routing
- **carrier:** none
- **descrição:** A standing rule of the loop, carried by no file: no exceptions, no size threshold.
- **propósito:** Untracked work is invisible to every query the loop makes about itself — order, WIP, what is blocked, what shipped. The obligation is not bureaucracy; it is that **the queue is the only thing that can be reasoned about**, and a rule with no artifact behind it will be applied inconsistently *and silently*.
- **o que faz:** Nothing mechanical. It is discharged by the intake command above, by the refusal that keeps review from opening work, by the routing labels, and by the personas' own briefs — four carriers, none of which is this rule.
- **o que não faz:** **Nothing enforces it, and this row exists to say so in a form a reader cannot mistake for silence.** A session that edits a tracked file with no Issue behind it trips no hook and fails no gate. This is the clearest instance in the registry of a `carrier: none` row: the obligation is real, it is load-bearing, and it is held by discipline.
- **citação:** no limit stated in the source

### 0041 · a foreign harness's configuration becomes decisions and tracked work, never applied configuration

- **tipo:** routing
- **carrier:** `commands/blueprint.md`
- **descrição:** The `import` mode of the same command: it reads a blueprint the owner supplied, classifies every mechanism in it into one of five classes, and asks about only the two classes that are genuinely open.
- **propósito:** A configuration copied because another harness has it is a mechanism nobody here decided to want, and the failure it prevents may be a failure this harness has never had. The obligation is that **an interchange produces DECISIONS, not diffs** — a foreign document is made legible, its provenance preserved and its evidence explicitly not inherited, and only what the owner approved becomes tracked work that then goes through the harness's ordinary change flow like anything else.
- **o que faz:** Reads a document handed over explicitly, classifies each mechanism by a stated order — already here, already rejected, incompatible, prevents a measured failure, otherwise speculative — and asks the owner exactly two questions about each mechanism of the last two classes, one mechanism at a time. On approval it files one `loop` item carrying the foreign id, the failure prevented, the evidence the exporting harness declared, the owner's answers, the proposed local surface and the literal `not measured here`. The item takes the active iteration's milestone and does **not** take `ready`, so it is visible to the queue and held out of the drain by the transition that is the owner's alone.
- **o que não faz:** **It never applies anything** — no skill, brief, steering, record, permission layer or installed build is written, and nothing is written inside a repository at all. It never fetches: a URL is read on this command's initiative under no circumstance, and **nothing mechanical holds that** — a network tool never reaches the permission guard, so the rule's carrier is the command's own text. **Its silent classes are silent when they are wrong too**: a misclassification into already-here, already-rejected or incompatible asks nothing and is invisible, which is why every such verdict is enumerated in the record even though it raises no question. **There is no index of rejections here**, so an already-rejected verdict is a claim rather than a query result. **The class-1 mapping does not persist** — the record is ephemeral, so a second import of the same harness re-derives it and may map differently. And the rule that the source harness is named by **function only** is `documents`-class with no control behind it: an adoption item lands on a public tracker, and no hook can read a body posted through a file.
- **citação:** > "It never applies anything."

**A strain in the closed set, named rather than fudged.** `0041` refuses to apply a foreign
configuration, and `refusal` in this registry means **prevented mechanically, before the act** — which
this is not. It is filed `routing` on the reading that its output is *what work exists and who acts
next*: a tracked item, in a state, awaiting the owner's transition. That is true and is not the whole
truth, and the set is not reopened on one row.

### 0018 · an approved spec is built by an actor that cannot merge it

- **tipo:** routing
- **carrier:** `agents/developer.md`
- **descrição:** The single fullstack builder — app, infrastructure, pipeline, tests inline.
- **propósito:** Authorship bias corrupts judgement, so the actor that writes the change must not be the actor that lets it through. The second half is a lesson about **handoffs**: this persona replaced three specialists whose split created a routing decision, and that decision was the reason none of the three was ever dispatched.
- **o que faz:** Implements a slice end to end against a description the leads already closed, writing its tests inline rather than after, and opens the pull request the gate then reads.
- **o que não faz:** It never merges and never applies infrastructure from a laptop. It does not decide scope: adjacent debt in its path is **named, not refactored inline and not filed**, which is a real cost — some of what it names is lost.
- **citação:** > "it never merges (that gate is the quality-assurance's) and never applies infrastructure from a laptop."

### 0019 · content has a mechanical builder of its own

- **tipo:** routing
- **carrier:** `agents/content-writer.md`
- **descrição:** A second builder, content-scoped: drafts articles, site copy and social-post language in the owner's voice.
- **propósito:** A `content`-typed Issue had **no builder at all** — the lead that owns content holds no write tool, and the fullstack builder is never dispatched there — so a whole routing type had a state it could not leave. It was not folded into the builder because its failure mode is different in kind: sourcing discipline over private material, not code review.
- **o que faz:** Shapes, cuts, structures and translates an experience the owner already has, against the shared voice ruler, onto a tracked file on a branch.
- **o que não faz:** It never **originates** an experience on his behalf, and it never publishes — the containment above is mechanical. It does not judge the truth of what it drafts either; that stays a blocking veto held elsewhere, at the merge gate.
- **citação:** > "never originates one on his behalf"

**A strain in the closed set, named rather than fudged.** `0018` and `0019` are **builders**, and the
five `tipo` values hold no `build` class. They are filed `routing` on the reading that a builder is a
*who acts next* carrier for a routing type, which is true and is not the whole truth. The set is closed
and gated and is **not** reopened here; the strain is recorded in
[ADR-0021](./adr/0021-the-blueprint-registry-is-authored-generation-verifies-it.md) as a named residual,
where a sixth value can be argued on evidence rather than on the first two rows that rubbed against it.

---

## `review` — a judgement from a fresh context; nothing enforces it

### 0020 · one demand is closed by two leads that are built to disagree

- **tipo:** review
- **carrier:** `agents/product-lead.md`, `agents/tech-lead.md`
- **descrição:** Two intake personas, same tier, different optimisation, consolidating a single demand before anything is built.
- **propósito:** Product-and-market and system are genuinely different optimisations, and **where two reviewers agree the owner learns nothing**. The pair exists to produce a disagreement he would otherwise have to generate himself, and to settle it *before* the build rather than in a review round after it.
- **o que faz:** They close an Issue's description between them — what it must deliver for the reader, what it must say to the market, what the system must carry — and a disagreement they cannot settle goes **up** to the owner, never **down** as two competing briefs. The `ready` label is the artifact that records the transition.
- **o que não faz:** Neither merges, and neither edits. Nothing verifies that the description was genuinely closed rather than nodded through — the label is auditable and attributable, not proven. And one of the two is bounded by repository: on the harness repo it may block on a false published claim and recommend on how something reads, and may not rule on the machinery's functioning at all.
- **citação:** > "the two consolidate ONE demand before the build"

### 0021 · a fresh context gates what an authoring context built

- **tipo:** review
- **carrier:** `agents/quality-assurance.md`
- **descrição:** The single gate on every merge request, holding two lenses in one pass and posting a verdict artifact carrying the head it read.
- **propósito:** The gate exists to **fight the builder**, on two axes at once: was every requirement met, and can this cause a problem in production. The two are different in kind — the first has a ruler external to the gate (the description the leads agreed), the second has none and cannot, since *can this break production* is not enumerable in advance.
- **o que faz:** Verifies each criterion with evidence, labels every finding with the lens it came from, classifies the change as safe or boundary, and posts its verdict as a comment carrying the head it read — so a verdict on a moved head fails loudly instead of reading as approval. It merges both classes under distinct verdict literals, holding only four named exceptions.
- **o que não faz:** It writes no code — its write grant exists for one purpose, composing its verdict body outside the tree, and a write to a repository path is a defect in the review. The posting rule is **self-enforced**: since the second gatekeeper was absorbed, nothing verifies the verdict was posted but the persona itself.
- **citação:** > "it never edits code"

### 0022 · the machinery is stress-tested before it is built

- **tipo:** review
- **carrier:** `agents/agents-lead.md`
- **descrição:** The owner's pair in his second role — harness engineer — returning the scenarios a proposal does not cover, each with how to check it.
- **propósito:** **Second-order effects of a configuration change are invisible from inside the change.** Four were found by accident, after implementation, in a single day: a matcher that no hook observes, a deny for a tool nothing sees, a glob that does not reach the second repository, an allow entry that matches on the wrong prefix. The obligation is to move that discovery *before* the implementation.
- **o que faz:** Returns the scenarios, ordered by what they cost rather than by likelihood, each with the command or the file and line that settles it — or **labelled a hypothesis, in those words**. It posts a durable verdict marker against the commit it reviewed, **on the pull request and on no other surface**, so its review is a checkable artifact rather than a claim in someone else's context. The one-surface rule is load-bearing rather than housekeeping: the reviewer runs *before* the build, so the tempting instruction is to post wherever a durable surface happens to exist, and a gate with two places to look fails unattributably in both directions — it either blocks a properly-reviewed change or accepts an artifact its own rule never named. Where the review predates the pull request, the evidence still lands, on the tracker item and deliberately **without** the marker envelope, so nothing off the pull request can be mistaken for the artifact the gate reads.
- **o que não faz:** It **gates nothing** — no merge request, no merge, no Issue — and it takes no part in a story's intake. Nothing enforces a dispatch, so an undispatched lens is indistinguishable from a clean one; the end-of-turn hook above is detection for that, never prevention.
- **citação:** > "you never gate an MR, never merge, never open work."

### 0023 · a draft is raised against the same ruler it was written against

- **tipo:** review
- **carrier:** `agents/content-reviewer.md`
- **descrição:** The pair to the content builder — at most two rounds, blocking only where it can quote a clause.
- **propósito:** The roster's **first true pair**: the ask is to raise a draft's bar *before* it reaches the owner. It works because both sides judge against the *same sentences* — a reviewer with its own ruler produces a second opinion, which is not a conflict and costs the owner a reconciliation.
- **o que faz:** Reads the draft against the shared voice skill for at most two rounds, blocks only where it can **quote a clause** of that skill, labels everything else advisory-and-droppable, and writes its rounds to a tracked file on the same branch. It is terminal on the first round with no citable finding, or on the second, whichever comes first.
- **o que não faz:** It does not judge **truth** — that stays a blocking veto at the merge gate — and it is not a second gatekeeper: it runs pre-merge on the draft, the gate runs post-build on the diff. Its advisory half is droppable by construction, which is the price of the two-round bound.
- **citação:** > "At most two rounds. There is no round three."

---

## `knowledge` — guidance the actor reaches for, removing a re-decision

**This section is the skills list**, and it is a **view over this one registry** (selector
`tipo == knowledge`), never a second table. The `skill` class is declared `partial` above; six carriers
have no row yet, named there with the reason.

### 0024 · the loop itself, and the judgment inside it

- **tipo:** knowledge
- **carrier:** `skills/harness-engineering/SKILL.md`
- **descrição:** The universal preload — the state machine, the intake chain, the inner-loop steps, and eleven principles in two tiers.
- **propósito:** Every actor in this loop needs the same answer to *where am I, who acts next, and what records that it happened* — and that is not domain-specific the way the rest of the library is. It is preloaded by every profile so that the one thing nobody may improvise is the loop.
- **o que faz:** States the two loop models and how to tell which one a repository runs, the issue types and their states with the artifact that records each transition, what "delivered" means against hygiene, the closing criteria, and the two tiers of principle — a floor that never bends and a dial calibrated to blast radius.
- **o que não faz:** It does not define **done** or hold the gate tables, it does not carry the permission zones or the branching topology, and it does not define the SDLC-generic meaning of *ready* — three neighbours own those, and the boundary is stated in its own trigger so the model does not reach here for them.
- **citação:** > "Not what "done" means (see quality-gates), the permission zones and CI/CD workflows (see devops), or the generic, SDLC-wide meaning of ready (see definition-of-ready)."

### 0025 · where a working file goes

- **tipo:** knowledge
- **carrier:** `skills/command-hygiene/SKILL.md`
- **descrição:** The first of two bodies of knowledge this carrier declares in its own header: scratch files, and the route by which they are written.
- **propósito:** Every persona that composes a pull-request body, a commit message or a verdict writes a file first, and where that file lands is a decision nobody should be making per case. It is one preload rather than a paragraph in each brief because the same procedure had been restated near-verbatim in every brief on the roster.
- **o que faz:** Sends every scratch file to the harness's own session scratchpad — session-specific, outside every tracked tree, with a lifecycle the harness owns — and names the two valid routes for writing one.
- **o que não faz:** It does not protect the private material class: the private layer's documented home is gitignored in the **consuming** repository and not in this one, so the same path is safe in one and a tracked public path in the other. The rule is about location and route, never about content.
- **citação:** > "`Write` is the route — never a shell redirect (`>`/`>>`) into a stub file."

### 0026 · the shape of a shell command, and of a posted body

- **tipo:** knowledge
- **carrier:** `skills/command-hygiene/SKILL.md`
- **descrição:** The second body of knowledge in the same carrier: one atomic call, the flag position, and `--body-file` without exception.
- **propósito:** Permission friction is almost never a missing allowlist entry — it is the **shape** of the command. And the posting half is not friction at all but silent damage: backticks and `$` are eaten from an inline body by the shell, and this platform paid for that more than once in a single session before the rule was written down.
- **o que faz:** One atomic command per call, `git -C` and `npm --prefix` instead of a directory change, the repository flag placed *after* the subcommand so the matcher's prefix still matches, and any body longer than one line written to a file and posted with `--body-file`.
- **o que não faz:** It is a **habit**, not a control — only the redirect half is mechanically enforced, by the floor, and the rest passes every gate when ignored. It also states no exception for the posting rule on purpose: a rule with a per-case judgement is the step that failed, four times, before it became unconditional.
- **citação:** > "A few extra calls is the price of zero permission prompts."

### 0027 · how the system is documented

- **tipo:** knowledge
- **carrier:** `skills/documentation-standard/SKILL.md`
- **descrição:** Part I of a carrier that declares two bodies of content in its own header — README, architecture pages, diagram choice, and where a document lives.
- **propósito:** Documentation decays in proportion to its **distance from the code**, and the only reliable forcing function is that the same change touching the code touches the file next to it. The placement rule is the load-bearing half; the format rule exists so a diagram is diffable rather than a binary nobody updates.
- **o que faz:** Markdown and Mermaid only, no static image diagrams; a `docs/` folder owned by the smallest unit that owns what it describes; a file named for the question it answers; and a diagram spanning two units duplicated from each side rather than centralised, because a single system diagram is the one that rots first.
- **o que não faz:** It does not check that anything is **current** — keeping docs in step is a discipline, not an enforcement, and this is stated in its own cons list rather than implied. Mermaid's expressiveness limits are accepted rather than worked around.
- **citação:** > "Keeping docs current is a discipline, not enforced."

### 0028 · how a decision about the system is recorded

- **tipo:** knowledge
- **carrier:** `skills/documentation-standard/SKILL.md`
- **descrição:** Part II of the same carrier: the record format, the significance gate, the two libraries, and how a record leaves.
- **propósito:** General docs describe a **system**; a record captures **one decision made about it**, and neither collapses into the other. They share a carrier because a reader who needs one is very likely to need the other in the same sitting — which is a fact about the reader, not an argument that the two obligations merged.
- **o que faz:** Fixes the record format, the light significance gate and who applies it at which of two moments, the split between a methodology library and a per-product one, the numbering and status lifecycle, and the four dispositions by which a record leaves. It also fixes how one record cites another: quote the clause or the heading, never a line number.
- **o que não faz:** The gate is **light** by choice, so it can miss a decision that only looks routine — the trade is stated where the rule lives, against a strong gate that would tax every trivial change and train people to write empty records. And the citation rule closes a locator that moves, not a citation that quotes the wrong heading.
- **citação:** > "a light gate can miss a decision that only looks routine"

### 0029 · the pipeline, and the floor that keeps infrastructure mutation inside it

- **tipo:** knowledge
- **carrier:** `skills/devops/SKILL.md`
- **descrição:** The umbrella capability — CI wiring, identity, state backend, branching per loop model, versioning, and the permission zones.
- **propósito:** Every guarantee in this section reduces to one test — *is the effect contained in the git-tracked tree, or does it escape?* — and that test is model-independent. What changes between loop models is only **which command** crosses the line, which is why the branching topology and the permission zones belong in one place rather than two.
- **o que faz:** Carries the two branching shapes, the identity model that removes long-lived cloud keys, the secret scope-and-naming standard, the workflow set, the numeric versioning rules and their loop guard, the remote state backend, and the allow/ask/deny zones per loop model. Infrastructure mutation is pipeline-only: plan on the request, apply on the merge, never from a laptop.
- **o que não faz:** It does not carry the Terraform configuration itself, the state machine, or the gate list its quality step sits inside — three neighbours own those. And it is explicit that the merge command is **deliberately not** a permission rule: whether a merge needs the human depends on the **class** of the change, and a matcher reading a command string cannot see a class.
- **citação:** > "Not for Terraform config (see cloud-infrastructure), state machine (see harness-engineering), the gate list Sonar sits inside (see quality-gates), or the pre-merge pass (see code-review)."

### 0030 · what "done" means here, and the gates that prove it

- **tipo:** knowledge
- **carrier:** `skills/quality-gates/SKILL.md`
- **descrição:** This loop's concrete definition of done in one part, and the stack-agnostic thresholds that satisfy it in the other.
- **propósito:** A gate is only a ruler if it is **external to the reviewer**. A vague description leaves the gate nothing to anchor on, so it falls back on impression — and impression has no stopping rule. The regression invariant is the other half: every feature that ships adds its regression, so the suite is the proof that nothing broke.
- **o que faz:** States the definition of done, the full-coverage regression invariant, the gate table per loop model, and the concrete thresholds — zero lint and typecheck errors, a coverage floor, contract and end-to-end suites where they exist, dependency and secret scanning, static analysis.
- **o que não faz:** It is not the **author-side** pass that runs before the request is opened, it does not carry the quality-platform mechanics, and it does not teach what a definition of done generically *is* or how to design one — three neighbours own those. Which suites constitute the regression is per repository, deliberately: a floor stated in components a repository does not have is not a higher standard, it is an unsatisfiable one, and unsatisfiable gates get faked.
- **citação:** > "Not for the pre-merge pass (see code-review), Sonar mechanics (see devops), or what a DoD generically is and how to design one (see definition-of-done)."

### 0031 · the author's own completeness pass

- **tipo:** knowledge
- **carrier:** `skills/code-review/SKILL.md`
- **descrição:** The pass the builder runs on its own slice before opening the merge request.
- **propósito:** Both of the gate's lenses are answered **first, while fixing is still free**. The merge of the two gatekeepers raised the value of this pass rather than lowering it: there is no longer a second reader coming from a different direction, so a defect one of them would have caught is now caught once or not at all.
- **o que faz:** Walks every requirement marked met or unmet with its evidence, mutation-checks every new assertion, names what the change made **false** elsewhere, tries alternative spellings of anything the change parses, and runs the gates with real output rather than a claim.
- **o que não faz:** It is not the definition of done — it anticipates a ruler it does not own. And it is **author-side**, so it carries the bias it exists to compensate for: it can find an assertion that cannot fail, and it cannot find the question the author never thought to ask.
- **citação:** > "Not for the definition of done itself (see quality-gates)."

### 0032 · the bar an item clears before a builder picks it up

- **tipo:** knowledge
- **carrier:** `skills/definition-of-ready/SKILL.md`
- **descrição:** The SDLC-generic entry gate, independent of which loop, tracker or team runs it.
- **propósito:** A strong definition of done **cannot repair a story that was ambiguous when the builder started**. The two gates sit at opposite ends of the same lifecycle, and a loop that enforces only one fails at the end it left open.
- **o que faz:** Gives the checklist shape conditional on the project's surfaces, names the flagship failure — scope fragmented across overlapping items — and states the relationship to estimation.
- **o que não faz:** It is generic by construction, so it holds **this** loop's intake mechanism nowhere: the two-lead chain, the label, and who may apply it live with the state machine. It also does not verify what shipped, which is the other gate's job.
- **citação:** > "Not for what "done" means at delivery (see quality-gates), or this repo's own two-lead intake mechanism (see harness-engineering)."

### 0033 · the ruler for anything published in the owner's voice

- **tipo:** knowledge
- **carrier:** `skills/published-voice/SKILL.md`
- **descrição:** The shared ruler the content pair both judges against — anchors and their precedence, the subject bound, the corpus evidence, the title criteria, the teaser rules.
- **propósito:** Two personas arguing about a draft must judge against the **same sentences**, or the pair produces two opinions instead of a conflict. It is a skill rather than a section of one brief so that the drafter and the reviewer cannot drift apart — and the identity of their two preload lists is itself gated.
- **o que faz:** Holds every rule a piece of published prose can be judged against, and states the precedence between them so a conflict between two anchors resolves the same way twice.
- **o que não faz:** **It is the ruler, not the role** — it says nothing about what either persona *is* or may do, which is deliberate and is what makes it shareable. It is also an acknowledged exception to the extraction test that governs this library, taken as *extracted ahead of a decided second consumer* and recorded as such rather than as a new class of skill. It is **not** a token saving and is not sold as one.
- **citação:** > "This is the **ruler**, not the role."

### 0039 · a session refuses to run while the guards it relies on cannot run

- **tipo:** refusal
- **carrier:** `hooks/scripts/preflight.sh`
- **descrição:** A hook registered on two events — it blocks every prompt while a precondition of the registered guard set is absent, and reports the same finding at session start where a human sees it before typing.
- **propósito:** Every other guard in this harness fails open on a missing dependency, and it fails open **silently**: the hook emits nothing and the harness reads that as *no decision*. One interpreter off the path disables an entire permission floor — the merge gate, the trunk-push floor, the irreversible-act denials, every persona boundary — while the session looks exactly like one whose floor is holding. The obligation is not to make the guards fail closed; it is to make a session that cannot enforce its floor refuse to run at all, so *degraded* stops being indistinguishable from *fine*.
- **o que faz:** Derives what the floor needs rather than carrying a list — reads the hook registry for the scripts it registers, and those scripts for the interpreters they reach for, so a new hook's dependency becomes required with no edit here **wherever that hook declares it the same way** — a dependency reached for without that declaration contributes nothing, which is the derivation's blind spot rather than a gap in the registry. Refuses on three classes: an interpreter missing, a registered script absent or without its execute bit, and a **headless** session running with the static permission layer disabled, which it reads straight off its own payload. It names exactly one finding and how to fix it, counting the rest without listing them. It fails closed on its **own** bootstrap dependencies, alone in this harness, because a check that cannot read anything must not report a clean result.
- **o que não faz:** It checks that a binary is present, never that it is **authenticated** — auth expires mid-session and a door check cannot see it, which is why the one rule that denies on an unreadable verdict stays a separate mechanism and is not subsumed here. It cannot observe whether a deny list was *loaded*; the session's permission mode is the closest thing the payload carries. It does not fire for a dispatched subagent. And if the hook registry never registered at all, this never runs — and its silence is indistinguishable from a clean pass, which is unfixable from inside a hook.
- **citação:** > "A door that refuses is not a floor that holds: this stops a degraded session, it does not make any guard fail closed."

### 0040 · a persona reaches only the MCP servers it was granted

- **tipo:** refusal
- **carrier:** `hooks/scripts/mcp-guard.sh`
- **descrição:** A `PreToolUse` guard on the `mcp__.*` matcher, denying by default and allowing a named subset of one server's tools to one persona.
- **propósito:** An MCP server is a capability the agent's own tool list does not describe and no other layer can see. Until this guard, the only thing standing between a dispatched persona and every MCP server configured on the machine was the `tools:` line in its own brief — a real gate, but a **single layer that holds by absence**: no brief says *"and no MCP"*, so deleting one line inherits everything. Measured, a subagent with no restriction enumerated roughly four hundred tools, including messaging and mail surfaces that act irreversibly and in public in the owner's name.
- **o que faz:** Denies by default and allows by persona, the polarity the floor already uses for its agent-scoped rules, so a persona added later or a connector installed later starts denied and somebody decides by name. It matches the server segment rather than the full namespaced name, because the same server resolves under two spellings depending on whether the plugin or the consuming repository declared it. Within the one granted server it allows a **named read-only subset** and refuses the input-carrying tools — the narrowing the `tools:` frontmatter cannot express, since that layer grants whole servers only.
- **o que não faz:** It does not touch the orchestrator, whose agent type is empty by design — the most capable context in the loop is the one with no MCP control at all, and that is a scope line rather than an oversight. It has no opinion about what a granted call does: the origin bound on the browser is Chrome's, not this hook's. And it cannot prove the harness still routes MCP calls to a hook — that was established by live probe, and if the routing regresses every assertion stays green while the backstop is gone.
- **citação:** > "a layer that holds by ABSENCE"

---

## History

**An id leaves this registry only as a tombstone row, never as an absence** — the convention
`docs/adr/README.md` already runs, reused rather than reinvented. Every number this registry has issued
is either a live row above or a row here, asserted in both directions against a **declared ceiling**
rather than the highest surviving row, because an abandonment at the top of the sequence leaves no gap
to find.

**A rename changes `nome`. A consolidation changes `carrier`. Neither changes `id`, and neither
produces a row here.** Only an **abandoned** obligation does — one that stopped being wanted, not one
that moved. The workspace has already paid for the alternative once: a cloud trust policy pinned to a
plain name broke on a rename, and a citation that moves is worse than one that breaks, because it still
resolves.

| # | what it obliged | why it was abandoned |
|---|---|---|

*The table is empty, and that is a statement rather than a placeholder: this registry has abandoned
nothing yet. The one obligation known to have been abandoned in this harness's history — the
repo-root scratch directory, retired once measurement showed a scratch file's location does not affect
permission friction — predates the registry and was never issued a number here.*
