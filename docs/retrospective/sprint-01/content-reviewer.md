# sprint-01 — retrospective · content-reviewer

commit: `f3fc10a` (`tadeumendonca-skills`, branch `docs/retrospective-sprint-one`) · `9399c70`
(`tadeumendonca-io`, the tree the review files were read from)
fed-with: the six review files in `tadeumendonca-io/docs/content-review/` —
`what-my-agents-dont-do.md`, `highlights-522.md`, `prominence-launches-and-field-force-span-522.md`,
`journey.md`, `profile-hands-on-through-line-542.md`, `blast-radius-supernova.md`; the round headers,
literals and draft SHAs in them (`grep -nE '^## Round|^CONTENT-REVIEW-|^draft:'`); the citable/advisory
split per round (`grep -cE '^### (Citable findings|Advisory and droppable)'`);
`skills/published-voice/SKILL.md` as preloaded; `commands/retrospective.md`. **No `dispatch-metrics`
comment exists for this persona in either repository** — the consult was added by hand, per step 2's
lower-bound clause.

**Twelve `## Round` sections over six drafts**, not eleven: `journey` 1 · `blast-radius-supernova` 3 ·
`highlights-522` 2 · `profile-hands-on-through-line-542` 2 · `what-my-agents-dont-do` 2 ·
`prominence-…-522` 2. The twelfth is the one finding 1 is about.

## Finding 1 — the two-round bound is spent on FINDING, and nothing is left to VERIFY the fix I prescribed

**What I saw.** The round format makes me prescribe *"the smallest change that clears it"*, so my words
enter the draft. Round 2 then reads a draft I partly authored — and twice this iteration that round had
to raise a citable finding against **my own round-1 wording**, in the round where no round remains.

**The artifact.** `docs/content-review/highlights-522.md`, round 2, citable finding 2, in the file's own
words: *"Round 1's suggested wording is what produced this shape; the finding is against the ruler, not
against the drafter, and it is raised here rather than left because this is the last round."* That round
closed `CONTENT-REVIEW-FINDINGS` with three citable findings outstanding, and the pair terminated on the
section count. `blast-radius-supernova.md` is the same pressure resolved the other way: round 2 closed
`CONTENT-REVIEW-FINDINGS`, stating *"Two rounds are spent and there is no third"* — and a third section
follows it, headed `## Round 1 · revision 2 (PR #557)`. That section defeats the terminal condition and
says so itself: *"`grep -c '^## Round' …` now returns **3**, and that number is not this revision's round
count."* Two of six drafts (33%) left the pair with citable findings unverified; one of the two came back
under a re-numbered heading.

**What it costs.** Two different things, and only the second is a design defect. The first is that a
prescribed fix ships unchecked — the owner receives a draft carrying my sentence with nobody having read
it in place. The second is that **the terminal condition is a section count, and a section count is
authored by the persona the bound constrains**. The escape used on `blast-radius` may well be right on
the merits (the draft had materially changed), but it was invented in-file, by me, under the pressure of
a bound with no verification slot — which is exactly the shape `/harness-engineering` calls *an
instruction, not a mechanism*. Nothing distinguishes a legitimate re-open from a third round wearing a
new number.

**The change I propose.** Not a third round — the cap is what stops this pair becoming a queue, and it
should not move. Instead, **narrow what round 2 may cite**: round 2 raises citable findings only against
text the drafter changed in response to round 1, and everything else it notices is advisory by
construction. That turns round 2 from "read the draft again cold" into "verify the fixes", gives the
bound a stopping rule that matches what round 2 is actually for, and removes the incentive that produced
the re-numbering. **The price of leaving it as is:** the pair keeps discovering new problems in the round
that cannot act on them, and the re-numbered-round escape is now precedent in a tracked file that the
next reviewer will read.

## Finding 2 — `published-voice` has no clause about whether a sentence can be READ, so a reader-facing defect is uncitable by construction

**What I saw.** Every clause in the ruler is about sourcing, register, positioning, the journey, the
title or the teaser. **None is about comprehension.** A sentence with a dangling antecedent, a
garden-path parse, or a term the piece translates in one place and keeps in English in another violates
no clause I can quote — so I am obliged to label it `advisory-and-droppable`, which the drafter may drop
without argument, and the round may still close `CONTENT-REVIEW-CLEAR`.

**The artifact.** `docs/content-review/prominence-launches-and-field-force-span-522.md`, round 2, the
advisory block — three such items, on a round closed `CONTENT-REVIEW-CLEAR`: *"`Ran the same span` has no
antecedent"*; *"`to the analytics stakeholders read` garden-paths"*; and a pt/en term inconsistency where
the file records why it could not be blocked on — *"the corpus gloss clause could be dressed up to make
this citable, and doing so in a terminal round would be taste wearing a ruler's clothes."* That is the
citable-clause discipline working exactly as designed, and the ruler failing the reader anyway.

**What it costs.** `CONTENT-REVIEW-CLEAR` reads, to anyone downstream, as *this draft is clean*. It means
only *nothing in it violates the ruler I hold*, and no other gate closes the difference:
`product-lead`'s surviving veto is on the **truth** of published claims, and `quality-assurance` reads a
diff against the Issue. **Whether an English sentence parses is nobody's blocking lens in this loop.**
The prose that shipped is his professional surface, which is the one place the sourcing constraint says
*"é a minha imagem à prova"*.

**The change I propose.** One clause added to `published-voice`, at the owner's word and in his register
— of the shape *a sentence must resolve on one reading; a pronoun or a `the same X` must point at
something the reader has already met on the page* — so the defect above becomes quotable and blocking.
**It is the owner's to author, not mine**: the whole reason this ruler is a shared file is that neither
persona in the pair writes it. **The price of leaving it:** the pair goes on shipping clear rounds over
drafts with visible reading defects, and both of us will keep declining to block on them, correctly.

## What I would leave alone

- **The citable-clause requirement.** It held under pressure, and the artifact proves it rather than
  asserting it: on a terminal round with a real problem in view, the file refused to dress a clause up
  to make it blocking. That is the bound working. Finding 2 asks to widen the *ruler*, never the licence.
- **The cap at two rounds.** Both findings above are pressures the cap creates, and neither is an
  argument to raise it. `journey.md` cleared in round 1 and cost one dispatch; three more cleared at
  round 2. Four of six terminated cleanly inside the bound.
- **The tracked review file as the artifact.** It is what made this consultation possible at all —
  `dispatch-metrics` has zero records for this persona in either repository, and the only reason my
  rounds are countable eight days later is that they are files in a diff.
- **`product-lead`'s absence from the drafting rounds.** Nothing in the six files suggests a craft round
  was missing; the findings that needed it were routed, labelled, and named as its class rather than
  argued in mine.
- **The draft-SHA-per-round discipline**, including the one round that could not carry a commit SHA and
  recorded blob hashes instead (`what-my-agents-dont-do.md`, round 2), stating why. That is the rule
  degrading honestly rather than being skipped.
