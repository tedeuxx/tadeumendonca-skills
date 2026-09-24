# sprint-04 (joint close with sprint-03) — retrospective · agents-lead

commit: 4f617d177b0cb3912420909b170f72cfbec9da1d
fed-with: my `dispatch-metrics` records on #508 (4 dispatches) and #509 (2); my `harness-lead-verdict`
markers on `-skills` PRs #516, #517, #518, #519 and `-io` #677; the PRs I built, #517 (#508) and #518
(#509), with their Issues; sprint-03's agents-lead markers from the Codex-run persona on `-skills`
#503–#507 and `-io` #675, #676; the gate's verdicts on those same PRs, read only where a marker of mine
is cited in them or they explain one; `docs/retrospective/sprint-04/00-scope.md`. I opened no other file
in this directory.

## Finding 1 — hold 2's path predicate misses the Codex machinery, and the next sprint runs on that machinery

**What I saw.** Hold 2 applies to a diff that touches `hooks/**`, `agents/**`, `skills/**`,
`commands/**` or `.claude/**` (`agents/quality-assurance.md`, the hold's own text: *"a diff touching
`hooks/**`, `agents/**`, `skills/**`, `commands/**` or `.claude/**` requires an
`<!-- harness-lead-verdict: … -->` comment"*). Neither of the two PRs I built this sprint touches any of
those paths:

```
gh pr view 517 --repo tedeuxx/tadeumendonca-skills --json files --jq '.files[].path'
# .codex-plugin/plugin.json  README.md  codex-hooks.json  docs/adr/0004-…  docs/codex-hook-bridge.md
# scripts/codex-hook-adapter.test.py  scripts/codex-hook-probe.py  scripts/codex-hook-probe.test.py
gh pr view 518 --repo tedeuxx/tadeumendonca-skills --json files --jq '.files[].path'
# docs/… (3)  scripts/codex-hook-adapter.py  scripts/codex-hook-adapter.test.py  scripts/codex-hook-probe*.py
```

Those two diffs are the permission floor's **registration and adapter on Codex**. #517 re-routes the
hook that runs the floor, and #518 adds output to the floor's `UserPromptSubmit` arm. The gate saw the
miss and handled it two different ways on consecutive PRs. On #517 it reasoned from substance (*"this
changes the harness's own Codex hook registration (`codex-hooks.json`), which carries the permission
floor on Codex"*). On #518 it wrote that *"the diff also touches no `hooks/`, `agents/`, `skills/`,
`commands/` or `.claude/` path"*. Both PRs carried a marker at head only because the `loop` routing row
dispatched me. The written predicate did not require one on either.

**The unguarded tree already has a live defect in it.** `.codex/config.toml` is also outside the
predicate, and it is the Codex orchestrator's operating brief. Line 20 reads *"Preserve WIP=1: one
implementation branch and one open merge request through completion"*. `docs/loop-mode.md:24` reads
`wip: 2`. The Codex line landed on 2026-09-10 (`git log -- .codex/config.toml` → `1c2a4469`) and the
reversal to `wip: 2` came a day later (#385, 2026-09-11). Nothing has touched the file since. It also
instructs Codex to override the canonical command: *"even where the canonical autonomy command still
carries an older disjoint-slice exception … Do not change the shared command"*. #509 built a detector
for one Codex staleness class, a persona snapshot older than the installed plugin. This is a second class
that detector cannot see, because an inline instruction carries no version.

**What it costs.** The owner has decided that the next sprint runs entirely inside Codex. That puts the
loop on the files hold 2 does not name: `scripts/codex-*`, `codex-hooks.json`, `.codex/**` and
`.codex-plugin/**`. A change to the Codex floor now needs a lens marker only if the orchestrator happens
to dispatch one, and nothing reads that choice. The failure is silent, and it runs in the permissive
direction: a missing reviewer on the machinery the next sprint executes on. The WIP line errs
conservatively. It costs parallelism, not a control. It does show that the Codex carrier already outranks
the record in one place.

**The change I propose.** Extend hold 2's predicate in `agents/quality-assurance.md` to
`scripts/codex-*`, `codex-hooks.json`, `.codex/**` and `.codex-plugin/**`, and apply the same change to
any string-identity arm that pins the path list. Separately, `.codex/config.toml:20` should defer to
`docs/loop-mode.md` rather than state a WIP value. **Price of leaving it:** the Codex floor stays
guarded only by routing habit, which is exactly what #393 said it had to stop depending on. **Held by:**
the gate persona reading its own brief. That is an instruction, the same layer hold 2 already sits on.
Extending the list moves no layer.

## Finding 2 — head-scoped hold 2 makes the lens re-attest repair rounds that never touch its object

**What I saw.** On `-skills` #506 (sprint-03, Codex-run) the lens posted four markers. The gate returned
`REQUEST-CHANGES` three times, for delivery defects in `scripts/worklog.py`: a cutoff that never
constrained accounting, and enum type checks. Each repair moved the head, so each round needed a fresh
marker, and markers 2–4 are pure re-attestations (*"re-reviewed … no falsifiable-and-false harness
finding remains"*). Measured: no repair delta touches a hold-2 path.

```
git diff --name-only 6568e17d… 1762f091…   # docs/worklog/* scripts/worklog*.py        -> 0 predicate paths
git diff --name-only 1762f091… 26e7eebf…   # + scripts/fixtures/worklog/*               -> 0
git diff --name-only 26e7eebf… d97e82b2…   # event.schema.json scripts/worklog*.py      -> 0
# calibration — the PR's own base..first head DOES match: commands/autonomy.md,
# commands/sprint-planning.md, skills/agents-configuration/SKILL.md
git diff --name-only 6cfe93c1f26564f703c39a14c8aa8c366635f448 6568e17daf18f817b71af833431f3c48b3b70073
```

My Claude-run re-reviews this sprint were different: on #516, #517 and `-io` #677 each later marker
carried a finding of the lens's own. So the waste is specific. It happens when the head moves because of
the **gate**, and the delta is outside the lens's object.

**What it costs.** Three lens dispatches on one PR, each of which attested to nothing new. Their duration
is unknown: Codex writes no `dispatch-metrics` record (00-scope §3). For scale, the two shortest
agents-lead records on #508 run 507 s and 552 s. I cannot map records to markers, so that is an order of
magnitude and not a price. The serial gate queues behind every one of those passes.

**The change I propose, and it depends on Finding 1 landing first.** Let the gate carry a marker forward
from an earlier head of the same PR when `git diff --name-only <marker commit> <head>` touches no
hold-2 path. The gate already reads that delta: its round-4 verdict on #506 says it *"compared with the
previously reviewed GitHub diff"*. The rule costs no new call, and it still catches a rebase. A trunk
merge that brings in harness paths shows up in the tree delta and forces a fresh marker. **Do not adopt
it before Finding 1.** With today's predicate, the carry-forward would wave through exactly the
`scripts/codex-*` repairs Finding 1 shows are machinery. **Price of leaving it:** one lens dispatch per
gate round on every harness PR whose repairs are delivery-only.

## What I would leave alone

- **The terminal literal works on both harnesses.** I expected the Codex-run lens not to type it. It
  did, in all ten of its markers: `-skills` #503–#507 and `-io` #675/#676, each counted with
  `test("the lens is CLOSED";"i")`. That hypothesis is eliminated. Do not build an arm on it.
- **The 40-character `commit:` contract.** Every marker I read, on both harnesses, carries a full SHA,
  and hold 2's `commit:`-line limb resolved cleanly on #517 and #518. The reader and the writer agree.
- **The lens finding real defects on its own re-reviews.** Three rounds on #516, two on #517 and three on
  `-io` #677 each closed on a fixed, falsifiable finding. That is the lens working, not ceremony.
- **The report-only shape of #518's snapshot notice.** It can't block, and that was measured. That is the
  right direction of error for a notice on the floor's own arm.
- **One thing I could not check:** which persona snapshot the Codex dispatches actually ran in sprint-03.
  `docs/codex-native-personas.md` records a `2.0.44` registration found on 2026-09-24. `v2.0.44` already
  carries the terminal literal (3 occurrences) and predates the 40-character contract, so the premise
  "same brief, different machinery" is a hypothesis for sprint-03, not a measurement. The Codex session
  transcripts would settle it.
