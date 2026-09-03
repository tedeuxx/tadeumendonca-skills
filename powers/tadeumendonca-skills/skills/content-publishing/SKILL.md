---
name: content-publishing
description: "Move a finished piece through the whole lane it travels — the owner's selection, the drafting pair and its two-round bound, the reviewer that REPAIRS a copy defect in place rather than blocking on it, the held preview at the real URL, release, and the social pair in the same batch. Use when a piece is being taken from a ready Issue to live, or when someone needs to know which step runs unattended and which one waits on the owner."
---

# Content publishing — the lane a piece travels from selection to live, and who waits at each step

`published-voice` judges the **text**. This skill **moves** it. Nothing here restates a rule about how
prose should read; if you are about to, you have left this file and are inventing a second copy of a
ruler two personas already share.

## Why this exists at all

**The lane was implemented and never written down anywhere a session reads.** Every step of it existed —
an interview at capture, a drafting persona, a reviewing pair, a truth veto *(which since 2026-09-03 is
a repair inside the rounds rather than a veto at the gate — step 5)*, a preview affordance, a
distribution generator — and the only place the *order* of them was recorded was a decision record in the
consuming product's own library, which is opened by someone who already knows to look for it.

The cost is measurable and it is not hypothetical: a session asked to put a finished article in front of
the owner offered a rendered artifact instead, because it did not know the platform had a preview mode
scoped and built for exactly that. The owner's correction is the reason this file exists —
*«o modo preview nao é um skill?»* · *«voce trabalhando na producao de um artigo deveria utiliza-lo ao
final para mandar para revisao»*.

**So this is the pipeline, end to end, with one column that matters more than the others: who is waiting.**

## The rule this skill exists to carry

**The owner's words, and they are the load-bearing sentence of the whole file:**

> *«ao final de fechar o texto de um artigo voce deveria fazer o primeiro deploy dele no modo preview e
> me enviar o link para revisao inplace»*

**Read it as: closing the text is not the end of drafting — the first deploy is.** The piece goes out
**held**, and what reaches him is **the link**. Not a paste, not a file, not a rendered artifact, not a
summary. The real page, the real chrome, the real URL, reviewed **in place**.

**The portable rule, stated so it survives leaving this platform:** *the first deploy is part of
drafting, and the author reviews the real artifact in place rather than a representation of it.* Every
representation — a mock, an artifact, a screenshot, a paste — answers a different question than the one
the reviewer is actually asking, which is *how does this land*. The spelling below is one worked example
of that rule, not the rule.

## The one thing that makes this lane different from every other

**Work of this type is SELECTED, one piece at a time, by the owner. It is not a queue and it is not
drained.** Every other lane in this loop reaches a builder through an autonomous drain over a pool
predicate. This one does not, deliberately: the drain's pool is *(the product type OR the loop type) AND
ready*, and that predicate excludes this lane by construction rather than by an exception written into
the drain.

**`ready` on an Issue of this type therefore does NOT mean queued.** It means the description is closed
and the piece is eligible to be chosen. Reading it as a queue is the single most likely way to get this
lane wrong, because on every other lane the two words mean the same thing.

**What that buys and what it costs, stated as a trade rather than as a feature.** It buys the owner
control over what he publishes and when, which is the whole point on a surface whose subject is his own
professional presence. It costs **visibility**: a lane that is never admitted to an iteration is absent
from every iteration-scoped artifact this loop produces — the completion bar, the closing rites, and the
briefs those rites derive. Measured in this harness over one full iteration window, the lane ran the
entire time and appears in none of them; the drafting persona was consulted at the closing rite only
because an unrelated machinery item happened to dispatch it once.

**That is the price of the design, not a defect to fix here.** Do not "fix" it by admitting pieces to an
iteration — that reverses the owner's standing rule. Know that the iteration axis under-reports this lane
and read any iteration report accordingly.

## The pipeline

Each step names its state: **AFK** (runs unattended), **HITL** (waits on the owner), or **UNBUILT**
(nothing carries it; a person does it or it does not happen).

**No step below is UNBUILT, and the label is in the legend so that answer is stated rather than
inferred from its absence.** Every step of this lane exists. What does not exist is anything that
*fires* them in sequence — see *What nothing enforces*, which is a different claim and the one that
matters.

### 1 · Capture — the Issue is filed, after an interview · **HITL**

Intake on this lane is not the two-lead intake and not the machinery intake. It is an **owner interview
at capture**, one question at a time, no multiple choice, and his answer recorded **verbatim** rather
than tidied — because the recorded take *is* the source the drafting persona cites for the stance, and a
paraphrase is a stance with no attributable origin.

**The operative wording, the required question, the follow-ups and the two spellings of the marker that
records his take (or its dated absence) live in the intake command, and are deliberately not restated
here.** One rule from it is worth carrying because it decides whether this step blocks: **one line and
stop still opens the Issue.** An interview that costs him a sitting is one he routes around within a
week, and then there is no interview at all.

### 2 · Description closed, `ready` applied · **AFK — and the label here is the LEAD's, not the owner's**

**Do not carry the machinery lane's rule across.** On a loop-typed item `ready` is the owner's
transition alone; on this lane the product lens closes the description **and** applies the label, so
step 2 needs nobody but a dispatch. The owner's next appearance is step 3, and it is a different act
from applying a label.

The product lens closes the description alone on this lane — intake only. It takes **no part** in the
drafting rounds that follow, and that split is not a matter of taste: **intake judges the ISSUE** (worth
doing, against what else, bounded how) and a drafting round **judges the PROSE**. The act that decides
whether the Issue should exist never enters the flow that produces prose.

~~Its **blocking truth veto on published claims survives untouched** and is a different act again — it
fires at the merge gate, not inside a round.~~ **Struck 2026-09-03: on this lane that veto is gone.**
What the product lens keeps here is **intake and nothing else** — it closes the description and decides
`ready`, because intake judges the **Issue** and a round judges the **prose**. The copy lens is the
reviewer's now, exercised in step 5 as a repair. See step 6.

### 3 · Selection · **HITL, and there is no substitute for it**

The owner names the piece. Nothing derives it, nothing ranks it, and no drain reaches it. **This is the
step most likely to be skipped by a session that has read the other lanes' rules and assumes this one
works the same way.**

### 4 · Draft · **AFK**

The drafting persona works from material the owner already has — it shapes, cuts, structures and
translates an experience, a decision or a result; it never originates one on his behalf. It drafts onto
tracked files and **posts to no public surface directly**; on this harness that containment is
mechanical rather than promised, in the permission guard's persona-scoped rule.

### 5 · Review rounds · **AFK, bounded at two**

The reviewing persona reads the draft against **the same ruler the drafter drafted against** — that
shared ruler is the only reason the pair is worth its cost, since two personas reading two copies of a
rule produce two opinions rather than a conflict.

- **It REPAIRS the draft in place; it does not block and it does not hand back.** Owner's ruling
  2026-09-03: *«ele pode resolver e mandar ajustado para preview em vez de bloquear»*. The corrected
  piece goes to the held preview and the owner reads **the result** rather than a verdict about it.
- **It edits on exactly two grounds and on nothing else** — it can **quote a clause** of that ruler, or
  the claim is **false against the source**, with the source the only permitted supply of the
  replacement. Everything else is advisory-and-droppable and the prose is left alone. **That bar is now
  the only thing between a review and a rewrite**, which is why it is stated as a hard edge rather than
  as a severity scale.
- **A false claim the source cannot settle is the one thing it cannot repair** — editing would mean
  inventing the replacement, which the ruler forbids. Its own clause prescribes the remedy: cut the
  claim, and record in the round that it was cut and what would settle whether it comes back. **This
  does not stop the piece.**
- **At most two rounds. There is no round three.** The bound still binds — it is the pair's only
  mechanical stopping rule — but round one is now terminal in the ordinary case whichever literal it
  carries, because re-reading an edit the reviewer made itself produces no information. **Round two
  exists only where the draft changed by another hand.**
- The rounds land in a **tracked review file on the branch**, one section per round, each closed with one
  of two literals. That file is the artifact; there is no comment and no relayed claim.

**This half of the pair is the least exercised thing in the lane, and the skill says so rather than
describing it as routine.** Read the two facts together, because separately each one misleads:

```
# in the repo the drafts live in — the artifact trail
grep -cE '^## Round' docs/content-review/*.md
```

Measured over one full iteration window in this harness: **six drafts, twelve round sections** — the pair
demonstrably ran. And in the same window the loop's **dispatch metric recorded zero dispatches for that
persona in either repository**, which is why a closing rite first excluded it from its own consult set
and had to add it back by hand after the artifacts falsified the metric. **The metric under-reports this
lane exactly as the iteration axis does**, and for the same reason: both are keyed on objects a selected
lane never acquires. Trust the review files; do not trust a dispatch count about this lane.

~~**A residual the rounds carry, from the pair's own retrospective and not from theory:** the two-round
bound is spent on *finding*, so a fix the reviewer prescribed in round 1 is read back in round 2 by the
persona that wrote it, and there is no round left to verify it. Two of six drafts terminated with citable
findings outstanding.~~ **Struck 2026-09-03: the reviewer repairs rather than prescribes, so no
prescription is left waiting for a round that does not exist.** Struck rather than deleted because the
measurement behind it is real and is what the ruling answers.

**The residual MOVED rather than closing, and this is its new shape: nobody re-reads the repair.** The
authorship bias that made a second reader worth paying for now sits on the reviewer's own edit. Two
things absorb it and neither is an instrument — the owner reading the held preview, and the merge gate
reading the diff. And unchanged from before: **nothing mechanical distinguishes a legitimate re-open
from a third round wearing a new heading number, because the terminal condition is a section count and
the section count is authored by the persona the bound constrains.**

**When the rounds terminate, the TEXT is closed and the piece is NOT finished.** By the owner's rule
above, the next act is the first deploy — steps 6 and 7 — not a message to him carrying the words. **Do
not stop here and hand him prose.**

### 6 · The merge gate · **AFK — and since 2026-09-03 no copy hold reaches this lane at all**

The gate reviews the diff under both its lenses like any other change. Publishing in the owner's voice
is a **boundary-class** change, so the verdict says so — and on this harness the gate merges the
boundary class under its own distinct verdict literal rather than holding it, with the owner reviewing
live after deploy.

~~and relays the product lens's **blocking truth veto on published claims**.~~

~~**Of the four holds that stop the gate merging, exactly one is this lane's**: a `BLOCKING` truth
finding from the product lens, or an explicit lens escalation. The other three — an expansion of the
gate's own authority, a machinery diff missing its reviewer's marker, and anything touching
infrastructure — are not reached by a piece of prose and its front matter. **So the honest statement is
that this step is AFK with one live exception, not that it is gated.**~~

~~**A truth finding is the one thing in this lane that stops it dead**, and it stops it at the gate
rather than in a round. That is later than a round and it is deliberate: the veto is about *what is
claimed*, which is not the ruler the rounds apply.~~

**All three struck 2026-09-03. There is no copy BLOCK left on this lane — and the check did not vanish,
it moved one step earlier and changed form.** What used to hold the merge is now a repair inside step 5,
where it costs a sentence instead of a round. Struck rather than deleted because a reader who sees a
hold disappear assumes the coverage disappeared with it.

**So none of the four holds is this lane's**, and the step is AFK with no live exception rather than
with one. What the gate still owes on a `content` diff is its own criterion 10, in the second shape that
criterion took on the same day: **no relayed verdict and no `copy-verdict` fence — instead the review
file on the branch, with a round section and a terminal literal — plus, unchanged, any claim the gate can
itself falsify against a checkable source.**

**The cost of losing the veto here, stated because nothing replaced it:** the reviewer's grounds reach
the ruler and the source, never the world. Cross-surface staleness, evidence proximity, the machine/ATS
read and durability go unread on this lane. The owner accepted that when he ruled — he reads the piece
at the held preview — and the honest form is that the trade bought earliness and spent a world-check.

### 7 · The held preview — the FIRST DEPLOY · **AFK to build, HITL to pass**

The piece is merged and deployed **held**: built, compiled, reachable at its final URL, in the real
components and the real chrome, and absent from every public enumeration. **You send the link. He reads
it there.**

**The worked mechanism, and get it exact — this is the step that has been described wrongly more than
once.** The hold is:

- **An explicit flag in the piece's own front matter** — spelled `draft: true` here — and the page
  renders **only to a visitor arriving with `?preview`** on the final URL.
- **The flag is a SHARED FACT, not a per-edition field.** On a multi-locale site it is authored once for
  every edition of the piece, so a held edition sitting beside a published one — half an article
  published — is impossible by construction rather than by discipline. It is read as **`=== true`, never
  for truthiness**, so a YAML string `"false"` cannot silently hold a finished piece and a missing flag
  reads as published.
- **Five readers see the flag and four act on it.** The piece is dropped from the **public enumeration**
  (index, feed, filters, navigation) · dropped from the **route enumeration**, which is *sitemap and
  prerender together, from one source* · **no share card is required**, so none is generated and a stray
  one reddens the build · **no social draft kit** is produced. The fifth reader — the one that walks the
  content tree with no hold awareness — is deliberately unchanged, and the consequence is stated where
  that decision lives rather than treated as a gap.
- **The load-bearing line is a DIVERGENCE, not an exclusion.** The **public enumeration** loses the piece;
  the **resolution** index keeps it, so the URL still answers. Drop it from both and the page resolves to
  nothing and the piece can never be read before publication; drop it from neither and it is published.
  Everything about the hold follows from getting that one line right.
- **`?preview` is presence, never a value** — see the isolation section below for why a value would be
  actively worse than nothing.
- **Release is a SECOND COMMIT** that removes the flag. See step 9.

**Three alternatives were rejected by measurement rather than by preference, and they are recorded here
so nobody proposes them again:**

1. **A future-`date` runtime filter.** Rejected twice over. The nonce **still shipped in the built
   output** under the strongest possible form of the filter — so it bought isolation while its framing
   claimed privacy, which is worse than buying nothing. And a wall-clock comparison makes **the same
   commit build differently tomorrow**: rebuild a tag the day after its release and the artifact differs
   from the one that shipped, with nothing in the diff to explain it.
2. **A `drafts/` directory outside every reader.** Strongest option on the privacy axis — the exposure
   would hold *by construction* rather than by a filter — and it renders **nowhere**, while rendering at
   the final URL in the real components is the entire requirement. It survives as the upgrade path, not
   as this step.
3. **A per-piece secret token validated at the edge.** Structurally unbuildable here, both halves: an
   edge function's source is **committed to a public repository**, so any secret in it is published; and
   a held route is never prerendered, so it never reaches the function as a distinguishable path at all.

**This is the step the whole skill was asked for, and it has its own section below because its guarantee
is half of what its name suggests.**

### 8 · His validation · **HITL**

He validates, or sends it back. A send-back re-enters at step 4 or step 5, not at step 1.

### 9 · Release · **HITL to trigger, AFK to execute**

Promotion is **a second commit** carrying **one edit** — clear the hold flag, set the real date — and it
rebuilds nothing else. The
piece enters the index, the feed, the sitemap and the prerender in the same build, because the enumeration
that drops a held piece is the same one all of those derive from.

**Scheduling is a scheduled COMMIT, not a scheduled render.** Any mechanism that publishes by comparing
against a wall clock makes the same commit build differently tomorrow, and breaks it silently — a build
that differs from a build, not an error. A commit is strictly more auditable and is the honest
replacement.

### 10 · The social pair, in the same batch · **AFK to draft, HITL to post**

**A publication is not done until it exists on both networks the platform publishes to.** Same batch as
the release — not "later", which in practice means one of the two never ships.

**The fan-out is deliberately NOT automated**, and the reason is worth carrying rather than rediscovering:
automating it means holding credentials for a class of unattended public writes. What is automated is the
**cost the manual route actually has** — a generator scaffolds both drafts from the piece's own
frontmatter and **resolves the share URL by lookup in the route enumeration, failing when no prerendered
route matches**. Construction would produce a plausible string for a page that does not exist; lookup
refuses it.

**The drafts are written to a private, ignored location**, because pre-publication copy in a public
repository lets anyone read tomorrow's post today. **Existing files are never overwritten** — the prose is
hand-voiced after generation, and regenerating over it at this cadence buys nothing.

Posting is his. **Nothing verifies that both halves of the pair shipped.**

## The guarantee that must not be softened: ISOLATION is not PRIVACY

**This is the single most important sentence in this file: a held piece's full text ships in the public
bundle.**

Two different guarantees, and the architecture below delivers one of them cheaply and the other not at
all:

| | what it means | delivered? |
|---|---|---|
| **isolation** | nobody **arrives** — no link, no search result, no sitemap entry, no unfurled card | **yes** |
| **privacy** | the text is **not fetchable** by someone who knows where to look | **no, deliberately** |

**Why, mechanically.** Where the markdown is compiled into the bundle at build time, a runtime filter can
remove a piece from every list the site renders and **cannot** remove its body from the bytes the site
ships — the build-time glob has already resolved it. So the hold is a **divergence**, not an exclusion:
the piece leaves the *public enumeration* and stays in the *resolution* index, or the URL would resolve to
nothing and the piece could never be read before publication.

**A preview parameter is concealment, not enforcement**, on three independent counts, and each stands
alone:

1. the body is in the bundle regardless of any parameter;
2. the check runs in the browser, on code the visitor already holds;
3. a per-piece secret cannot exist in a public repository, and an edge gate on the piece's own URL would
   need per-piece state the edge does not have — while the request that actually carries the text is
   served by a different cache behaviour that no viewer-side function is attached to at all.

**Treat the parameter as presence, never as a value.** A value reads as a credential, and a credential
this mechanism cannot keep is worse than none: it invites the owner to share the URL believing the token
protects it.

**The falsifier, and it is worth running rather than trusting.** Build the static output and grep a nonce
that exists only in a held piece:

```
grep -c <a-nonce-that-exists-only-in-the-held-piece> <dist>/assets/index-*.js
```

Two occurrences on a two-locale site — one per edition. **The mutation that makes it a measurement rather
than a failed search:** move the piece out of the compiled content tree and re-run; the count must go to
zero. A held-state assertion that stays green on a published piece asserts nothing about the hold.

**What a reader gives up by choosing either side.** *Isolation:* roughly three days, no infrastructure
change, no new cloud resource, no new grant, and a draft merge stays out of the boundary class that
touches infrastructure — paid for with the exposure above. *Privacy:* about a week more, and it puts
**every draft merge** into that boundary class permanently, which is a standing cost on cadence rather
than a one-time build cost. **Nothing built for isolation is discarded if privacy is wanted later** — the
privacy package is a strict extension, so the cost of choosing isolation first is a delay and not a
rewrite.

**And say which one you are claiming, out loud, whenever this comes up.** The owner asked for both in one
conversation — *«o problema é isolar trafego organico»* and, separately, *«isso deveria me ajudar com o
requisito de privacidade»* — and the record that decided it delivers the first and states plainly that it
does not deliver the second. **If the second word was load-bearing rather than loose, the decision is
wrong**, and that counter-argument is recorded as unsettled rather than answered. Do not present the hold
as privacy to close the gap.

*(In this harness the decision, its three rejected options and its upgrade path are the consuming
product's own record `ADR-0049`, in that repository's library, not this one's.)*

## What nothing enforces — read this before describing the lane as a machine

**The pipeline is a sequence of named human moments with automation between them. It is not a button, and
this repository blocks on a mechanism presented as stronger than it is.**

- **Nothing fires this skill.** There is no hook, no matcher and no rite that reaches for it at the end
  of a draft. It is reached because a model reads its trigger, which is a discovery mechanism and not a
  control.
- **Nothing checks a held piece was actually read before release.** The promotion edit is one word; no
  artifact records that anyone opened the URL.
- **Nothing verifies the social pair shipped.** The generator writes drafts; posting is manual and leaves
  no trace any gate reads.
- **Nothing observes a dispatch.** A piece drafted with no review round is indistinguishable from one
  whose rounds were clear until you open the branch's file list.
- **Nothing stops a held piece from being published by an edit to one word**, which is precisely why a
  committed fixture exists in the consuming product and every hold assertion runs against it.

**Applied to this lane, the standing test — *if this failed right now, would something stop me, or only
my memory?* — answers "only my memory" for every step above except the two that are mechanical: the
containment that keeps the drafting personas off public surfaces, and the gate's own merge floor.**
Everything else is an instruction. Say so when you describe it.

## Pros & cons

**Pros**
- The owner reads a finished piece at its **real URL in the real chrome**, before it is public — no
  artifact, no mock, no rendered stand-in.
- Isolation is cheap, needs no infrastructure change, and keeps a draft merge out of the boundary class.
- The drafting pair judges against **one ruler**, so its rounds produce a conflict rather than two
  opinions, and the bound stops the pair converting one piece into a queue.
- Reproducibility survives: nothing in the build reads a clock, so a rebuilt tag is the tag that shipped.

**Cons**
- **A held piece's text is public** to anyone who knows where to look. Isolation, not privacy.
- The lane is selected rather than drained, so it is **invisible to the iteration axis** and to any
  dispatch metric keyed on iteration objects — both under-report it, silently.
- The reviewer repairs its own findings, so **nobody re-reads the repair** — the authorship bias moved
  one step over rather than closing.
- **No world-check runs on this lane at all** since the copy veto left it: cross-surface staleness,
  evidence proximity, the machine/ATS read and durability reach the owner unread.
- The social fan-out is manual by decision; nothing catches a publication that shipped to one network.

## Using this skill

Reach for it when a draft is finished, and again at every step that follows — it is the map of who is
waiting, not a checklist to tick. Before handing anything to the owner, be able to say **which step you
are at** and **whether the next one is yours or his**.

See also: `published-voice` (the ruler the drafting pair judges the text against — this file never
restates it), `agents-configuration` (the state machine this lane's rows sit in, and who acts at each
transition), `definition-of-ready` (what a closed description asserts before selection is possible), and
`documentation-standard` (where the decision behind a step like the hold gets recorded).
