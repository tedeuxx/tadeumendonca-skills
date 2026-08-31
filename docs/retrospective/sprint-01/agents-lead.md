# sprint-01 — retrospective · agents-lead

commit: 28436af6bbadb7bcf9f3b81db6b1c497d9dfb446 (`tadeumendonca-skills`, branch `docs/retrospective-sprint-one`)
fed-with:
- my 34 recorded `dispatch-metrics` comments across the 13 `sprint-01` Issues in
  `tadeumendonca-skills` (marker `<!-- dispatch-metrics: tadeumendonca-skills:agents-lead #N -->`,
  namespaced match);
- my `harness-lead-verdict` markers on the 18 PRs of the iteration, and the `gatekeeper-verdict`
  markers interleaved with them;
- the `harness-lead-verdict` and `## agents-lead — intake stress test` comments on the Issues
  themselves;
- the ADR commits I authored this iteration (`git log v1.1.35..HEAD -- docs/adr`);
- my own scope record, `docs/retrospective/sprint-01/00-scope.md`.

**My evidence is a LOWER BOUND, in the words step 2 requires.** `dispatch-metrics-stop.sh` exits 0
silently on about a dozen paths and reads the Issue number from a branch grep, so every dispatch that
ran on `main` — which is every `loop` intake dispatch — is unrecorded. Read 34 as *at least 34*.

---

## Finding 1 — the `harness-lead-verdict` marker attests an independence it does not have, and the loop pays ~8 hours a sprint re-posting it

**What I saw.** The gate's hold 2 requires my marker on a harness PR before it may merge, and the
loop describes that as *"a reviewer that has to have been present, not a review that is skipped"*. On
this iteration's own artifacts it recorded something else: **the author of the diff signing off on the
diff, once per round.**

**The artifacts that show it.** Enumerated over the 18 `sprint-01` PRs
(`gh pr view <n> --repo tedeuxx/tadeumendonca-skills --json comments --jq '[.comments[]|select((.body//"")|split("\n")[0]|test("harness-lead-verdict"))|(.body|split("\n")[0])]'`):

- **33 markers on 18 PRs.**
- **16 of the 18 PRs carry a marker whose own first line declares the build** — `built #335 …`,
  `the closure control is built and green at this head …`, `rule 7d built as recommended at intake …`.
  The predicate is `test("built|build|implemented")` on the first line; 17 of 33 markers match.
- **15 of the 33 are second-or-later markers on the same PR**, and 11 of the 18 PRs carry more than
  one. On PR #369 there are three, interleaved with two `gatekeeper-verdict` comments; PR #348 and
  #361 the same shape.
- Both halves of the sandwich are mine by construction on this lane: record 0015's Corollary 1 gives
  `agents-lead` the build, Corollary 2 requires `agents-lead`'s marker. Nothing in the design ever
  intended a second pair of eyes here — but the wording the gate reads implies one.

**What it costs.** Two things, and only one of them is money.

*The measurable one.* My 34 recorded dispatches totalled **17.9 h** (64,466 s), **4,408 tool calls**
and **707 M cache-read tokens** (mean 20.8 M per dispatch), for **143,806 characters** of returned
text — mean 4,230 chars per dispatch, i.e. a ~31-minute, 20-million-token dispatch returning about
four kilobytes. The command is
`bash` over `gh issue view <n> --json comments` for each of the 13 Issues, summing
`duration_seconds` / `tool_calls` / `tokens_cache_read` / `output_chars`; the script is in the session
scratchpad and is four lines of `awk`. **The 15 repeat markers are re-dispatches**; at the mean
dispatch that is on the order of **7–8 hours of the 17.9**. *I cannot make that mapping exact and will
not pretend to:* `dispatch-metrics` carries no marker id, so nothing joins a comment to the dispatch
that produced it. Read *15 of 33 markers were re-posts* as the measured fact and the hours as an
order of magnitude derived from the mean.

*The one that matters more.* The gate is told it must find a reviewer, and it finds an author. If the
marker's real content is *"the machinery lens has examined this head"* — which is true and useful —
then the loop is buying a build-completion record and reading it as a second lens. The one persona in
the roster that genuinely holds a fresh context on a `loop` diff is `quality-assurance`, and it already
reviews every one of them. **The marker adds a round, not a reviewer.**

**The change I propose.** Do not add a persona and do not build a hook. Correct the *claim*, in the two
places that state it — record 0015's Corollary 2 and `agents/quality-assurance.md`'s hold 2 — so the
marker says what it does: *the machinery lens examined this head and here is what it found*, with the
independence claim dropped. Then **stop dispatching the lens on repair rounds**: one marker at the head
the gate will actually merge, posted last, is exactly as informative as three and costs one dispatch
instead of three. What genuinely *is* pre-implementation and independent-in-time is the intake stress
test on the Issue, which runs before any diff exists — that is the artifact worth strengthening if
independence is what the owner wants back.

**The price of leaving it.** No realized damage this sprint: every PR had a marker, and the gate was
never misled about presence. The standing cost is that a control everyone believes is a second lens is
one lens twice, and the first person to rely on it — a `loop` diff nobody else reads closely because
*"the harness lens signed it"* — will not find that out from any artifact.

**One thing I did NOT do, stated because the honest form requires it.** I could not close the
head-scoping half. `permission-guard.sh` rule 7c head-scopes the *gatekeeper's* verdict and does
nothing for mine, so hold 2 remains a presence check; I recommended the one-line fix at #357's intake
(rule 7c already fetches `headRefOid` and the comment list in one call) and it was not built. If the
proposal above is accepted, head-scoping becomes *more* important rather than less, because a single
final marker must be provably at the merged head.

## Finding 2 — the one-surface rule I shipped this sprint was broken by me 76 minutes later, and its stated benefit is measurably false at head

**What I saw.** #336's whole argument was grep-decidability: with the marker literal reserved to one
surface, *"which comment is the one the gate reads"* is answered by `grep`, not by reading two briefs
and hoping they agree. Measured at head, `grep` does not answer it.

**The artifacts that show it.**

- PR **#349** (the rule) merged **2026-08-28T23:20:58Z**.
- An envelope-bearing `<!-- harness-lead-verdict: … -->` comment landed on **Issue #337** at
  **2026-08-29T00:36:48Z** — **75 minutes and 50 seconds later** — first line
  `built the closure control on branch feat/closure-gated-on-artifact…`. That is a build verdict, on
  an Issue, after the rule reserving the literal to PRs. Command:
  `gh issue view 337 --repo tedeuxx/tadeumendonca-skills --json comments --jq '[.comments[]|select((.body//"")|contains("harness-lead-verdict"))|[.createdAt,((.body|split("\n")[0])[0:90])]|@tsv]|.[]'`
- **Seven envelope-bearing markers sit on Issues in this repo** (#313 ×4, #335 ×1, #337 ×2). Six
  predate the rule and are historical; one does not.
- **And the correctly-formed artifact is greppable too.** The intake comments on #355/#357/#358 use
  the prescribed heading and deliberately carry no envelope — but each *explains* that by quoting the
  literal, so `contains("harness-lead-verdict")` returns them. The artifact designed to be invisible
  to a grep matches the grep, for the most defensible reason there is.

**What it costs.** Nothing realized: the gate reads the PR, and every `sprint-01` PR carried a valid
marker. The cost is that #336's benefit is asserted and untrue. `inventory-counts.test.sh` asserts the
literal is spelled identically across its producer, its consumer and the metrics hook, and that both
briefs carry the same one-surface sentence — **all string-identity checks over files; none can observe
where a marker was posted.** My own brief says the one-surface rule is held by review. This sprint it
was not, by me, on the sprint that shipped it.

**The change I propose, and it is small.** A **detection arm**, not a guard. `permission-guard.sh`
cannot hold this — `command-hygiene` requires `--body-file`, so the marker text is never in the command
string a `PreToolUse` hook sees, and a guard keyed on the literal would fire only on the inline
`--body` form this repo already forbids. What is available is one query with no heuristics in it:
enumerate a repo's Issue comments and redden on an envelope-bearing marker with a `createdAt` after
2026-08-28T23:20:58Z. No tree discovery, no milestone pairing, no PR→Issue resolution — the three
things that killed the loop-first detector are all absent here. **Its honest cost:**
`inventory-counts.test.sh` makes **no live `gh` call today** (all 44 occurrences of `gh ` in it are
needles and prose), so this arm brings network and auth into a suite that is currently offline and
deterministic. That is a real dependency change and it belongs in CI or a `Stop` hook, not inside that
suite.

**The price of leaving it.** The rule stays held by memory, in the persona most exposed to memory
drift, and the next instance is invisible until somebody greps — which is exactly the failure #336 was
filed about, one layer up.

---

## What I could not check

- **My own intake dispatches.** Every one ran on `main`, and `dispatch-metrics-stop.sh` derives the
  Issue number from the branch, so none is recorded. Whatever intake cost this sprint, I have no
  instrument for it.
- **The mapping from a marker to the dispatch that produced it.** No artifact joins them; the hours
  attributed to re-posting above are derived from the mean and are labelled as such.
- **Whether the intake stress test is being posted consistently.** Only 3 of 13 Issues carry one, but
  the heading convention landed on 2026-08-28 and **all three Issues filed after it carry one (3/3)**.
  A sample of three is not a finding in either direction, and I am deliberately not reporting the
  10-of-13 absence as a defect: it is a convention that did not exist yet.
- **The other half of the iteration.** `tadeumendonca-io` recorded one dispatch total, none mine. I
  saw nothing there and claim nothing about it.

## What I would leave alone

- **The gate's REQUEST-CHANGES rounds on `loop` diffs.** I expected to find that the rounds only ever
  ground my justification prose, and the evidence says otherwise: across the 17 `sprint-01` PRs in this
  repo there were **29 commits after each PR's first**, of which **14 touched `hooks/scripts/`** and 15
  were prose-only. Roughly half the rework repaired a real gate arm. That is a gate doing its job, not
  a ceremony — and it is the one place in this report where my prior was wrong and the artifact
  corrected it.
- **The `loop` lane closing through `agents-lead` alone.** Finding 1 is about what the *marker* claims,
  not about the ruling. The owner's *"nunca"* holds, and the escape-hatch argument behind it is
  correct: almost every machinery change can be described as having an architecture edge.
- **The marker literal being unrenamed through the `harness-lead` → `agents-lead` rename**, and the
  gate arm that pins it. Three consumers spell it identically and the arm would redden if one drifted.
- **The intake stress test's no-envelope design.** Finding 2 notes it is greppable in practice; the
  *design* is right, and giving it an envelope would recreate the two-surface ambiguity #336 closed.
  The fix belongs on the surface rule, not on this artifact.
- **`00-scope.md` stating its own lower bound in those words**, and the branch rename that kept this
  rite's metrics from landing on an unrelated 2026-07 PR. Both cost a paragraph and bought a checkable
  artifact.
