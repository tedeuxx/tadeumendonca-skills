Review your own slice for COMPLETENESS before opening the merge request. Author-side, run by `developer`, and distinct from the gatekeepers' review that comes after.

Context: $ARGUMENTS

## What this is, and what it is not

**An anticipation of both gates, run by the author.** `quality-assurance` will consolidate that every requirement of the Issue was met and every DoD item holds; `security` will ask whether this can break production. **You answer both first, while fixing is still free.**

**You verify the DoD items here — you do not defer them.** The gate re-verifies independently, in a fresh context, and that independence is the point of having it. But arriving at the gate with the DoD unchecked outsources your own work to it, and every item it has to raise costs a round, a re-ratification and the owner's attention.

**Why it exists, measured rather than assumed.** Two hook slices in one session took **eight review rounds** between them. Reading back what each round found, almost every finding was reachable by the author before opening:

- a flag spelling (`--base=x`) whose class had **already been hardened in the same file**;
- **seven** assertions that could not fail, every one found by mutation and none by reading;
- doc drift in the second PR that was **the exact pattern the first PR had just taught**;
- a rule that could not read a body written the way this repo writes bodies — a convention the author had followed all day.

None needed a fresh context. They needed a list.

**A round costs a dispatch, a re-ratification and the owner's attention. This list costs minutes.**

### And it exists to reduce how much of this has to be a shell script

The harness has two ways to hold a rule: a **hook**, which is mechanical and cannot be argued down, and a **skill**, which is only as strong as the reading. The floor belongs to hooks — irreversible acts need a guarantee that survives a long context and a tired session.

**But a hook is expensive, and it can only see a command string.** Measured on the slice that added one narrow exception to the floor: **five review rounds and three separate bypasses**, all in a regex trying to infer intent from what the model happened to type — attached flag values, a number that was not the declared one, a body written to a file. Each fix was correct and each left the next spelling open, because *intent is not in the string*.

A rule about **what "finished" means** is exactly that class. No matcher can express it, and a guard that tried would be the same regex arms race one level up.

So the trade this skill takes deliberately: **a checklist the author follows, instead of a mechanism the author fights.** It is weaker — nothing enforces it — and it is the right weakness here, because what it checks is judgement rather than an act. **Reserve the mechanical floor for what is irreversible; let the loop's shape be carried by skills the personas read.**

**The rule, stated by the owner and worth keeping as a rule rather than a preference:**

> **A shell script supporting the workflow of executing tasks is an antipattern.**

The floor is not workflow. `terraform destroy`, a force-push, `rm -rf`, a secret write, a push to the trunk — those escape git and no later commit undoes them, so they earn a mechanism. **WIP discipline, who may open an Issue, how a story is decomposed, what "finished" means — every one of those is reversible by the next commit**, and every one of them is a rule about judgement, which a matcher cannot read.

*The line, so it does not blur:* **if the act cannot be undone, it needs a hook. If it can be fixed in the next commit, a hook costs more than it returns** — and the cost is not hypothetical: it is review rounds spent on spellings, plus a guard the loop learns to work around rather than follow.

---

## 1 · Completeness, at both levels

### The task, and every artifact it owes

**Enumerate the Issue's requirements and mark each met or unmet, individually.** Not "implements the issue" — that consolidates nothing, and it is the sentence the gate rejects.

A thin slice owes **all of its artifacts, not just its code**: the application change, the infrastructure that serves it, the pipeline that ships it, the **automated E2E journey**, the tests written inline, the decision record if a boundary was crossed, and the documentation the change makes stale. An artifact missing is an artifact the gate will ask for.

- Any requirement you cannot mark met is **unfinished work**, not a note for the PR body. Finish it or cut the slice and say what you cut.
- If the description is not closed enough to enumerate — no stated acceptance, a requirement you would have to invent — **stop**. That is an intake failure, and building past it produces a slice that passes its gate and still fails the person who asked.
- **Nothing ships half-done.** Scope you cut, a gate you could not run, an assumption you made: say it in the PR body. The reviewer will find it; finding it in your own report is cheaper for everyone.

### The story, when this task closes it

If this is the **last** task under its story, the story's completeness is now the question — and the three leads are about to ask it. Before opening:

- **every task under the story is implemented and merged**, not merely opened;
- the story delivers what its description promised, read against the intake ratification rather than against your memory of it;
- anything it does not deliver is **named**, and named as a task rather than as a caveat.

A story whose last task is green while an earlier one is still open is not finished — and that is a state only the author can see, since each task's own gate passed.

### The DoD, item by item

Verify these yourself. Each with **evidence** — a command's real output, a line in the diff — never "looks fine":

1. **Scope** — one thin vertical slice, no unrelated changes; adjacent debt reported, not fixed inline and not filed.
2. **Traceability** — references its Issue; acceptance covered by E2E journeys.
3. **Tests proportional** — inline, to the coverage floor; a user-visible change adds a green E2E story. §2 is how you check they can fail.
4. **Gates green with real evidence** — §8.
5. **Decision recorded** — an ADR if a significance boundary was crossed; otherwise say "no ADR" explicitly rather than silently.
6. **Observability** — name the artifact that proves the new behaviour where it runs. **`n/a` is a finding, not a shrug**: say what has no observable and why.
7. **No doc drift** — §3.
8. **History hygiene** — conventional subjects; a real merge commit, never squash.
9. **Security posture** — §7.
10. **Content truth** — where the diff changes anything a reader or a crawler sees, the copy lens has returned a verdict and its blocking findings are resolved.

## 2 · Every assertion must be able to fail

**Coverage cannot see this and neither can reading.** A tautological test executes the line, satisfies the threshold, and proves nothing.

> **Mutate the SOURCE, run the suite, count the reds. A new assertion that adds no red asserts nothing.**

Mutate the **source**, never the test — mutating the test proves only the composition you wrote. And after each: **restore, and re-run green.**

Two shapes that recur, both seen more than once:

- **Short-circuit.** The inputs satisfy an earlier guard, so the branch under test never runs. Choose inputs that clear every prior guard, and add a **control** asserting the opposite outcome without the condition.
- **Same literal on both sides.** Asserting `X` against a component built from `X`. Pin the *coupling* instead — read the rendered value and build the expectation from it — and put "is the value right" where a stale literal cannot pass.

**A stub that cannot distinguish the inputs cannot witness the rule.** If the test doubles answer identically whatever they are asked, no assertion in the suite can observe which input the code used.

## 3 · What did this slice make false?

A rule change leaves stale claims in places the diff does not touch. Check each, every time:

- the **README** or equivalent published description;
- the **header of the file you changed** — a contract sentence at the top that the body now contradicts;
- the **principles skills and the ADRs** that describe the behaviour;
- **persona files**, if the change alters what a persona must produce or may do.

**Supersede, never rewrite.** Strike the old sentence with the reason it stopped being true. A silently edited claim invites the next sweep to revert the decision.

*The trap worth naming:* deferring this to a later slice fails, because the sentence becomes false **the moment this one merges** — leaving the documented behaviour contradicting the real one for however long the later slice takes.

## 4 · Alternative spellings, if the diff parses anything

If the change matches command strings, paths, branch names or labels, try the forms that are legal and not obvious:

- **attached values** — `--flag=value` and `-Fvalue`, not only `--flag value`;
- **inside quotes** — text that looks like a flag but never reaches the tool as one;
- **the second occurrence** — greedy `.*` takes the *last* match, not the first;
- **word boundaries** — a marker matching inside another word is not a marker;
- **case and prefix** variants of any name you anchor on.

Every one of these has escaped a matcher in this repo at least once.

## 5 · Does the repo already do this differently?

The convention you are about to break is usually **your own**, from earlier the same day:

- bodies and multi-line text go through `--body-file`, never inline;
- merge with a real merge commit, never squash;
- `git -C <dir>` / `npm --prefix <dir>` instead of `cd`;
- one atomic command per call, no `&&` chains.

**If your change makes a repo convention impossible to follow, the change is wrong** — not the convention.

## 6 · The tree is clean and it is yours

- **`git status` before committing.** Foreign changes mean a concurrent agent left work in the tree; committing them ships something nobody reviewed.
- **Reviewers run in the same working tree.** While a gate is reviewing, use a `git worktree` rather than the main checkout — a mutation for verification and an edit for authoring look identical to git, and both parties lose.
- **Verify the branch base.** A branch cut while another slice was mid-merge starts from the wrong commit and carries its diff into your PR.

## 7 · The question the Issue does not contain — anticipate `security`

The sections above anticipate the delivery gate. This one anticipates the other, and it is the half most often skipped **because the Issue cannot prompt it**: *can this cause a problem in production?* is not enumerable in advance — if it were, it would be a requirement.

Name the axes you looked at and what you found, **the way `security` will**:

- **Dependencies** — a new package, a version change, a lockfile move.
- **Permissions and IAM** — anything widening what CI or the agent may do.
- **Secrets** — a value, a path, a private source quoted into something public.
- **Action pins** — a moving tag where a SHA belongs.
- **New external inputs** — anything the code now reads that someone else writes.
- **The deploy path** — does this merge publish, and does the artifact change?

> **`n/a` is only valid when you NAME the axes you checked and found untouched.** "No security impact" is a reassurance. *"`package.json` and both lockfiles are absent from the diff; no file under `iac/` or `.github/`; a secret-pattern scan over the diff returns nothing"* is a check.

**Verify the ARTIFACT, not the diff's appearance.** A comment-only change is not automatically inert: on a build that inlines and prerenders repository content, the question is whether an edited line can be **emitted**, which is a different question from whether it is a comment.

**And ask which direction a failure takes.** A guard that fails **open** stops protecting silently; one that fails **closed** wedges the loop loudly. Both are defects — but only one announces itself, so the silent direction is the one to check first. Trace every new error path and say where it lands.

## 8 · Gates, with real output

Run them and paste what they printed. **Never a claim.**

- The suite you touched, plus the suites you did not — a change to one hook can redden another.
- Lint, typecheck, build.
- The functional regression: **E2E always; an API suite only where an API exists.**
- **A gate that skipped is not a gate that passed.** If a job matched no files, say so in those words.

---

## The one-line version

> **Would a stranger reading only the Issue agree this is finished — and is every sentence this slice adds or leaves behind true?**

If either answer needs a caveat, the caveat belongs in the PR body before the reviewer finds it.

## Decision & trade-off

**An author-side anticipation of both gates, over relying on them to catch everything.** *Trade-off:* it deliberately overlaps what the gatekeepers check, and duplicated checks can drift apart. Accepted because the alternative was measured and is worse — eight rounds on two slices, with most findings reachable before opening.

**The overlap is the design, not a cost to minimise.** The author checks the DoD to *arrive finished*; the gate re-checks it in a fresh context with no authorship bias, which is the only reason its verdict means anything. Running it twice is not waste — running it *only at the gate* is, because every item raised there costs a round.

**When the two disagree, the gate wins.** It is the ruler, and it never inherits this pass as evidence: "the author checked" is not a verification, it is a claim.

**Not a gate itself.** Nothing enforces this and it must not become a required check. It is the author's own pass, and a checklist that blocks is a third gate nobody decided to add.
