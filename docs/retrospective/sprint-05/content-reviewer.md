# sprint-05 — retrospective · content-reviewer

commit: `tedeuxx/tadeumendonca-io` @ `04dcb4ef6b61e4869e40b0f0a095ef30f27ed65a` (the review files and their history were read there); this file written against `tedeuxx/tadeumendonca-skills` @ `01045b660fc31fa6cb4f063fc0c5a2f1aa04db7c`
fed-with: `docs/content-review/ai-answers-in-seconds-you-dont-have-to.md`, `…-owner-correction.md`, `…-epigraph-rlhf.md`, `…-tos-paraphrase.md`; Issue `-io#687` (state and labels only); `git log --since=2026-09-25 -- docs/content-review` in `-io` (six commits, 2026-09-30 → 2026-10-01). No dispatch-metrics records exist for this persona, so these files are the whole evidence of my presence.

## Finding 1 — the two-round cap was reset three times on one piece, by opening new files

**What I saw.** One article, one Issue (`-io#687`), **four** review files and **six** `## Round` sections. Each owner-authorised correction opened a new file with a suffix (`-owner-correction`, `-epigraph-rlhf`, `-tos-paraphrase`) and started again at `## Round 1`. Every file is inside the cap; the piece is not.

```
grep -c '^## Round' docs/content-review/ai-answers*   # in -io
# -> 2, 1, 1, 2 — six rounds, no file over two
```

**The artifact that shows it.** The four files themselves. Each one's own `provenance:` line says the earlier artifacts "remain terminal and unchanged", so I treated each correction as a fresh pair rather than a third round.

**What it costs.** The cap is the pair's one mechanical stopping rule, and it is a per-file section count. Opening a new file resets it, and nothing notices. `content-publishing` already names this as open with the owner ("a bound that can be reset by the party it constrains is not a bound"). This iteration is the first measured instance. It also breaks the naming contract. My brief says `<slug>` is the draft's own file stem, so the review and the piece can be found from each other. Three of the four files are not that stem, so `ls` on the stem finds one round file out of four.

**What I propose.** The owner rules on the open question, using this piece as the evidence. My proposal: **one file per piece**. An owner-authorised correction appends a `## Correction <N>` heading to the stem's file. Under it sit at most two `## Round` sections, plus the owner's comment link as provenance. The cap would then mean "two rounds per correction the owner ordered", and that is countable in one file. The price of leaving it as is: the cap means "two rounds per file", and a file is free to create.

## Finding 2 — the ruler and the workstation IP floor collided, and I had no clause to cite

**What I saw.** On 2026-10-01 the owner asked for a verbatim third-party passage (the *Star Trek: The Original Series* opening narration). `published-voice` has no clause for this. Rule 18 governs how a verbatim quotation is presented, with the author's name on the block, and assumes the quotation may exist. The global workstation brief, rule 1 (third-party IP), forbids reproducing it. The paraphrase that shipped came from another hand. My round recorded it under a heading the round template does not have (`### LLM-firewall intervention`). It cited neither ground, because neither applies: the intervention came from the floor, not from my ruler.

**The artifact that shows it.** `docs/content-review/ai-answers-in-seconds-you-dont-have-to-tos-paraphrase.md`, Round 1.

**What it costs.** I can edit on exactly two grounds, and the floor is neither. When the floor wins, a reviewer either edits with no ground it can state, or leaves a violation in a draft headed for the held preview. This time another hand had already made the edit, so the gap stayed hidden. Next time it will not be, and the brief, the template and the ruler give no answer.

**What I propose.** The owner rules on where the IP floor meets rule 18. The ruler then carries a quotable clause pointing at that ruling, for example a scope sentence on rule 18's VERBATIM clause. A repair forced by the floor would then become ground 1, citable like any other. I am not proposing the clause's wording. That would be me writing a second ruler. The price of leaving it: the floor is enforced in the review file by a heading nobody defined.

## What I would leave alone

- **Repair instead of block.** In five rounds out of six, the round said exactly what it changed or that it changed nothing. The owner read results at the held preview, not verdicts.
- **Rule 10 as a target, not a limit.** The piece grew from 2,041 to about 3,100 words, all of it owner-selected material. Each round recorded the count as advisory with its reason and forced nothing. That is the ruling working.
- **Round 2 only when another hand changed the draft.** Both second rounds this iteration had a changed SHA under them. Neither re-read my own edit.
