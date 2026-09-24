# sprint-04 — retrospective · quality-assurance

commit: 7c3e6c14c74f5ddff5c64a29b69f733b42fee30c
fed-with: `docs/retrospective/sprint-04/00-scope.md` (the only file in this directory I opened;
the `agents-lead` section on this branch was not read) · my `dispatch-metrics:
tadeumendonca-skills:quality-assurance` comment on `-skills` #509 · my `gatekeeper-verdict:
quality-assurance` markers on `-skills` PRs #516 #517 #518 #519 and `-io` PR #677 · the same persona's
verdicts from sprint-03, which ran on Codex: `-skills` PRs #503 #504 #505 #506 (four verdicts) #507 and
`-io` PRs #675 #676 · the `v2.0.81` GitHub Release body · the installed plugin caches under
`~/.claude/plugins/cache/` and `~/.codex/plugins/cache/` on the owner's machine

This covers two iterations, closed together (owner ruling 2026-09-24). Twelve PRs carry fifteen
verdicts. One persona brief produced all of them, on two harnesses.

---

## Finding 1 — on #506 the gate found one defect class one instance per round, and that took four rounds and two follow-up PRs

**What I saw.** PR #506 (Issue #499, `sp:8`) got four verdicts in 67 minutes: `REQUEST-CHANGES` at
23:27, 00:03 and 00:21, then `APPROVE-AND-MERGE-BOUNDARY` at 00:34. After round 1, every blocker was
the same mechanism, which is a contract value reaching set membership or hashing before its type is
checked:

- **round 1, F4:** *"The validator accepts malformed contract values"*. This names the class, but the
  falsifier was a list of examples (string booleans, boolean points, object harness/evidence, an
  unsupported v2).
- **round 2, R2-1:** four more examples of that class were still accepted or raised an uncaught
  `TypeError`. The round-2 verdict says it in its own words: *"the same contract-validation concern,
  not new scope"*.
- **round 3:** two more, `provenance = {}` and `outcome = {}`. The verdict again: *"This is the same
  failure mechanism as R2-1, not a new workstream."*

**Round 3 was the first prescription that asked for the class**: *"Systematically check the existing
contract fields reaching set membership, hashing or set construction, rather than repairing only one
example."* Round 4 approved the next head. After that, #507 repaired an acceptance gap (a sibling
repository's revision was rejected), and `-io` #676 carried the counterpart. Each of those opened a
new gate context, and each context began by restating the four rounds that came before it.

**The artifact.**

```sh
gh pr view 506 --repo tedeuxx/tadeumendonca-skills --json comments \
  --jq '[.comments[]|select(.body|contains("gatekeeper-verdict"))|{t:.createdAt,v:(.body|split("\n")[1])}]'
gh pr view 506 --repo tedeuxx/tadeumendonca-skills --json comments \
  --jq '[.comments[]|select(.body|contains("gatekeeper-verdict"))|.body][2]' | grep -n 'Systematically'
```

**What it costs.** Three extra gate passes and three extra builder rounds on one Issue. An owner
decision was also taken where no owner was present: at round 3 the verdict records *"The orchestrator
supplied the decision to continue"*. The round-3 decision request exists to turn *this is expensive*
into a choice the owner makes. Here the orchestrator made it and the gate recorded it. **The real
cost is that the budget fired and changed nothing.** Rounds 2 and 3 did not produce any new kind of
finding. Each one found the next example of a class the gate had already named at round 1, because
the builder repaired the examples the gate had listed. The gate then checked the repair against the
examples it had listed, and a check scoped that way passes exactly as far as the repair reaches.
This is my own defect, not the builder's. The persona brief is the same on both harnesses, so the
Codex run is not what caused it.

**The change I propose.** It is one rule in `agents/quality-assurance.md`, under *A finding blocks
only if it names a criterion and a falsifier*. **When a blocking finding names a defect CLASS, its
falsifier must ENUMERATE the class, not give examples of it.** In practice that means a selector
over the source that lists every site (here: every `not in <SET>` and every `set(...)` over a
contract field), and a prescribed table-driven test of every field against every wrong type. The
builder repairs against that enumeration, and the next round verifies against the same enumeration.
An example list is still allowed, but only as a demonstration. It cannot be the falsifier. On #506
this would have put round 3's sentence into round 1. **Price of leaving it:** a class-shaped finding
takes N rounds, where N is how many examples the gate happens to find each time. The round budget
reports the cost correctly and prevents none of it.

## Finding 2 — the owner action a boundary merge left behind is only in a PR comment, and the surface he reads when he installs does not carry it

**What I saw.** My #517 verdict (`APPROVE-AND-MERGE-BOUNDARY`) ranked this as *"the most serious
consequence of the diff"*: after the owner **installs** that release, both Codex hook registrations
read `modified`, Codex skips them, and **the Codex permission floor stays off, with no notice, until he
re-trusts them.** I cleared it as merge-then-act rather than as a hold. That reasoning still holds:
merging does not open the gap, because installing does. I then handed him three steps under criterion
11 (answer 3): re-trust both registrations, restart, and run the `echo $(true)` canary. My verdict also
says *"Nothing in the loop observes whether he does this."* #518's verdict leaves a second live check
of the same kind: a notice from a released install is still unmeasured. **Both Issues closed at
15:14 with no comment recording either check.** The release he would install carries neither ask.
Its notes are generated from commit subjects:

```sh
gh release view v2.0.81 --repo tedeuxx/tadeumendonca-skills --json body \
  --jq '.body|test("(?i)trust|ACTION REQUIRED")'
# -> false
ls ~/.codex/plugins/cache/tadeumendonca/tadeumendonca-skills/
# -> 2.0.79        (the Codex install predates #517's release, so the gap has not opened yet)
```

**What it costs.** Nothing yet, and that is the reason to act now. The gap opens when he runs the
update, and the next thing he reads then is the Release. The ask is on four surfaces (the PR body,
the README, the Codex manifest description, and my verdict), and the Release is not one of them. If
the update lands without the re-trust, every Codex session runs with no floor and nothing says so.
The next sprint is planned to run inside Codex, and my #517 verdict says to do the re-trust *"before
that sprint starts"*. **Criterion 11 says the third answer must reach the owner as a question.** A
paragraph in a merged PR's comment thread does not reach him when he installs. It is the *"sentence in
a report he reads twice and is never asked about"* that criterion 11 was written to replace.

**The change I propose.** It is the smaller of two options. **A boundary verdict that leaves a
post-install owner action also posts that action, one line and the link, as a comment on the Issue
it discharges, before the merge.** Those Issues are what he closes. Here, #508 and #509 were closed by
hand two seconds apart (15:14:20 and 15:14:22), and an ask sitting on them would have been in front of him at the moment he
acted. The larger option is a `version-main.yml` step that lifts an `ACTION REQUIRED:` line from the
merged PR body into the Release. That is a workflow change with its own review, and I name it without
recommending it. **Price of leaving it:** a merge that is safe on its own becomes unsafe when somebody
installs it, and on a harness where the permission floor is the only guard, the failure is silent.

## What I would leave alone

- **The head-scoped hold-2 read.** The corrected `commit:`-line selector ran on all five sprint-04
  verdicts. On #516 it returned `{"total":3,"at_head":1}`, and on #517 it separated a marker that
  attests `0b42218d` from the one at head. This is the check the struck `contains($h)` form would have
  over-counted. It works. Do not touch it.
- **`Refs #N` and no `closes:` line.** Every one of the twelve PRs has an empty
  `closingIssuesReferences`. Where acceptance was met, the verdicts said so and left the close to the
  owner. No close was earned by a keyword. The cost is one manual close per Issue, and that is cheap.
- **The round count being unavailable.** 9 of 15 verdicts say *not supplied*, all of sprint-04's
  among them. It cost nothing: every sprint-04 PR passed the gate first time, and where rounds did
  happen (#506, #507, `-io` #676) the Codex orchestrator supplied the number. My sprint-01 section
  already raised the missing counter. Raising it again would add work without new evidence.
- **The per-verdict length.** The #506 verdicts run 10 to 17 KB each, and the reproductions they carry
  are what let the builder close F1 to F3b in a single round. Finding 1 is about what the falsifier
  enumerates, not about how long the verdict is.

**One residual about myself, in line with my brief.** I gated five PRs in sprint-04, and exactly one
`dispatch-metrics` record from me exists (#509). #516, #517, #519 and `-io` #677 left none, so the
instrument undercounts this persona's work. This is the gap #513 already describes. I note it here so
that nobody reads the consult set's lower bound as an exact count.
