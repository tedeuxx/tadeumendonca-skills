# sprint-05 — retrospective · agents-lead

commit: 01045b660fc31fa6cb4f063fc0c5a2f1aa04db7c
fed-with: my `dispatch-metrics: tadeumendonca-skills:agents-lead` records on `-skills` #511 and #513
and `-io` #687; my `<!-- harness-lead-verdict:` markers on the 26 PRs merged 2026-09-25..2026-10-10
that carry one (`-skills` #526–#530, #532, #534, #535, #539–#546, #548, #549, #558, #559; `-io` #681,
#684–#686, #701, #713); the titles and marker headlines of those PRs. No other persona's file under
this directory was read.

Every figure below comes with the command that produced it. The source of the working method is
`tedeuxx/mhw` as of 2026-10-10, so both findings are proposals for wherever the named mechanism lives
now. They are not edits to this tree.

## Finding 1 — the permission-guard parser PRs did not converge, and "the lens is CLOSED" was declared over a set that cannot be enumerated

**What I saw.** I posted 76 markers on 26 PRs, and 17 of the 26 needed more than one. Two PRs took
13 of the 76: `-skills` #534 (rule 3b argv allowlist) took 7 rounds in 38 hours, and #543 (the quote
scanner and heredoc pass for `$bare`) took 6. Both PRs extend a shell tokenizer written by hand in
bash. Read in order, every blocking finding I raised on them belongs to one class: **the scanner and
bash disagree about a string.** Each round found a new member of it: an extglob name match that grows
exponentially and turns a force-push DENY into no decision (#534 round 4); bash 3.2's superlinear
`${var//pat/}` doing the same thing again (round 5); and three heredoc-opener desync classes in which
bash runs a trunk push that the scanner does not see (#543, third marker). **On #543 I wrote
"the lens is CLOSED" at 22:36:59Z, then reopened BLOCKING at 22:45:32Z, nine minutes later, from my own
unfinished sweep.** This is the shape `engineering-standards` records for the deleted
action-pendency guard: it searched over spellings and did not converge. The terminal instruction
requires that nothing falsifiable and false remains. Over the set of strings a hand-written parser
and bash could disagree on, I cannot honestly state that, so the literal can be typed but cannot be
earned.

**The artifact that shows it.**

```
gh pr list --repo tedeuxx/tadeumendonca-skills --state merged --search "merged:2026-09-25..2026-10-10" \
  --limit 200 --json number,additions,comments --jq '.[]|"\(.number) add=\(.additions)
  markers=\([.comments[]|select(.body|test("(^|\n)<!-- harness-lead-verdict"))]|length)"'
# -> #534 add=1427 markers=7 · #543 add=1491 markers=6 · #542 add=1226 markers=7 · #548 add=892 markers=5
gh pr view 543 --repo tedeuxx/tadeumendonca-skills --json comments \
  --jq '.comments[]|select(.body|test("(^|\n)<!-- harness-lead-verdict"))|.createdAt'
# -> the CLOSED round at 2026-09-27T22:36:59Z, the BLOCKING desync sweep at 22:45:32Z
```

Across the window the markers total 76 (68 in `-skills` over 20 PRs, 8 in `-io` over 6). Only 9 PRs
cleared in a single pass.

**What it costs.** These were real findings: every blocker was a DENY that became an ALLOW or no
decision, on the irreversible floor. So I am not reporting noise from the rounds. The cost is that
each round was paid in full, re-measured over a corpus of up to 43,180 commands at a moved head, and
that nothing about the class let me say when to stop. Another round would most likely have found
another member.

**The change I propose.** Stop growing the parser and bound the language it has to understand,
following the shape #441 already chose for rule 7c ("deny what cannot be parsed") and that rule 8's
extension already uses. The guard would recognise a small, closed grammar of simple compositions. If
a command falls **outside** that grammar **and** carries a floor token (`push`, `merge`, `rm`, a secret
write, `repo delete`), it is denied with a message telling the caller to rewrite it as a simple
command. Outside that case, the guard abstains. The errors then run in the visible direction: an
over-block on a complex but harmless command arrives as a deny message the caller reads and acts on.
The disagreement class becomes a fixed set, so a lens can enumerate it and close it honestly.
**The price of leaving it:** every future guard PR reopens the same unbounded search, and a lens
verdict of CLOSED on one means "I stopped", not "nothing remains".

## Finding 2 — my cost is measured only where it was smallest, so no one can weigh the rounds in Finding 1

**What I saw.** My `dispatch-metrics` records exist on 3 Issues: 38 distinct dispatches, 8.27 h,
about 255 M cache-read tokens. Two of those Issues (#511 and #513) map to PRs that took 4 rounds each
(#532 and #535). None of the PRs that took 5 to 7 rounds (#534, #542, #543, #548) has any record on
the Issues they implement. Per the scope record, 16 of the 19 iteration Issues carry no record of any
persona, which matches a sprint worked largely in Codex. #513 is itself the Issue titled
*"dispatch-metrics has recorded nothing since 2026-09-10"*. So the instrument meant to price a lens
round was dark exactly where the rounds piled up. The one harness-neutral trace of my work is the
marker. I post it in every harness, and it carries a full head SHA and a timestamp.

**The artifact that shows it.**

```
gh issue view 511 --repo tedeuxx/tadeumendonca-skills --json comments --jq '[.comments[]
  |select((.body//"")|contains("dispatch-metrics: tadeumendonca-skills:agents-lead"))|.body
  |{k:(capture("dedupe_key: (?<x>[^\n]+)").x),d:((capture("duration_seconds: *(?<x>[0-9.]+)").x)|tonumber)}]
  |group_by(.k)|map(max_by(.d))|{n:length,h:((map(.d)|add)/3600)}'
# -> #511 {n:23,h:4.27} · #513 {n:14,h:3.97} · -io #687 {n:1,h:0.03}   (same query, issue swapped)
```

Cache-read tokens, from the same deduplicated records: 144.6 M on #511, 109.0 M on #513 and 1.8 M on
`-io` #687.

**What it costs.** Finding 1 is a judgement about value against cost, and I can state only the value.
The engineering-standards escalation standard says the time and token axes are "already measured",
but over this iteration that holds for 2 of the 26 PRs I reviewed. Any threshold the owner later
calibrates for "this item's lens cost has gone wrong" would be trained on the cheap tail.

**The change I propose.** Use the marker as the harness-neutral round counter. It already exists on
every reviewed PR, and its count is a single `jq` expression per PR. The retrospective, and any worklog
in `mhw`, can read lens rounds from it directly rather than from a hook that only one harness fires.
For time, the gap between consecutive markers on one PR is a wall-clock bound that needs no new
carrier. It is a ceiling that includes waiting, not dispatch duration, and must be labelled that way.
**The price of leaving it:** the most expensive review work in the loop stays unpriced, and the next
retrospective reads silence again where the cost was.

## What I would leave alone

- **Head-scoped markers with the full SHA.** All 26 PRs merged with at least one marker whose
  `commit:` line names the merged `headRefOid` (the `at_head` column of the per-PR query, using hold 2's
  own capture). Nothing was cleared on a stale marker.
- **The `loop` routing row: one lens plus the gate.** No product-lens verdict marker appears in the
  window, and the chain that ran was marker, then gate, on every attested PR.
- **Hold 2 reaching beyond docs (#541), even on a dependabot bump.** On `-io` #713, a seven-action
  version-group bump, round 2 found `terraform-plan` failing at `init` with a TFC "unauthorized"
  error, after the credential-step change, and the third pass confirmed the role assumption and the
  plan before the gate ran. A credential path in a "deps bump" is exactly what this hold is for.
  Three passes were the right price.
- **The terminal literal itself.** It ended most chains on the round after the last real finding. The
  failure in Finding 1 is in what it was asked to close over, not in the instruction.
