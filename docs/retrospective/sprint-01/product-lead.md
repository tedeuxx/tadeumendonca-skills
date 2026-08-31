# sprint-01 — retrospective · product-lead

commit: 1bdf1c10d91256a3569c8d5c369222b3b0f93e3e

fed-with:

- my own `dispatch-metrics` comments, matched strictly on the namespaced marker
  `dispatch-metrics: [^ ]*:product-lead` in the comment's **first line** — **11 in
  `tadeumendonca-skills`** (#313 ×6, #355 ×2, #342 ×2, #335 ×1) and **1 in `tadeumendonca-io`** (#572);
- my `copy-verdict: product-lead` relays, enumerated across the merged PRs of both repositories in the
  iteration window: `-io` PRs 526, 530, 531, 532, 564, 571 read in full; `-skills` PRs 323, 334, 345,
  346, 348, 352, 354, 364, 369 enumerated, 354 read in full;
- the `sprint-01` milestone in both repositories, enumerated rather than named from memory — **13
  Issues in `-skills`** (all `loop`, all closed) and **5 in `-io`** (all `product`, all closed);
- the merged-PR → closing-Issue map for the `-io` window (40 PRs), and the merge dates of the
  `-skills` PRs on branches naming #329.

I did not read any other persona's file in this directory, and I did not run `git log`. No other
persona's finding reached me by any route.

---

## Finding 1 — the harness's own self-description is hand-maintained on two published surfaces, and both went false inside this iteration

**Half: MARKET (cross-surface coherence), with the `-skills` half held inside my narrow lane there.**

**What I saw.** One class of defect produced work on both surfaces in one iteration, and I met it from
both sides — once as the lens that blocked it, once as the reader of what it cost.

*On `-io`, the surface is `/architecture`.* Six merged PRs in this window exist to reconcile that page
with what `-skills` actually says: PR 515 (`fix/architecture-content-pair-word-514`), PR 518
(`fix/architecture-loop-lane-agents-lead-alone-329`), PR 520 (`fix/roster-adr-authorship-519`), PR 532
(`fix/architecture-tier3-loop-lens-431`), PR 570 (`feat/tier-lane-topology-detector-431`), and PR 512
(`feat/persona-membership-drift-detector-431`). Two of the six build detectors, which is the right
instinct; four are hand corrections. **`sprint-01`'s own #431 is titled *"architecture page's tier-1
diagram is stale against `-skills`' corrected README"* — the iteration carried an Issue whose entire
subject is this class.**

*The propagation is serial and its order is not the one you would choose.* Owner ruling #329
(2026-08-25, one word) landed on the site first — `-io` PR 518, merged **2026-08-25** — then in
`-skills` PR 334 on **2026-08-26**, and only on **2026-08-27** did `-skills` PR 340
(`fix/loop-lane-survivor-in-preload-329`) reach the universal preload every persona loads on every
dispatch. **The public page was right for two days while the file the agents read was wrong.**

*On `-skills`, I blocked one instance myself.* PR 354, `copy-verdict: product-lead`, BLOCKING 1:
`README.md` partitioned 31 events as **5 + 26** while `hooks/hooks.json` registered **six**, and the
README refuted itself 280 lines further down. It was already off by one on `main` (*"four"* against
five), **and the diff editing that exact sentence carried the error forward**, so it shipped as a claim
of that PR rather than as inherited debt.

**What it costs.** Three things, in order of weight.

1. **Hand-correcting a truth claim re-introduces one.** PR 532 *was* a truth fix, and it introduced a
   fresh falsehood — that `quality-assurance` checks the `agents-lead` marker *instead of* the
   Definition of Done. I blocked it; the gate returned `REQUEST-CHANGES` citing my finding under
   criterion 10; a round was spent. **The repair mechanism has the same failure rate as the thing it
   repairs.**
2. **The falsity is found by a lens at the merge gate, after the claim has been live.** Every one of the
   six PRs above is a correction, which means a reader could have read the wrong version first. On the
   surface whose entire thesis is rigor, that is the most expensive place for it to be wrong.
3. **The paying surface is the one that argues the repositioning.** `/architecture` is where a hiring
   reader goes to check whether the harness is real. A page that has been wrong about the harness six
   times in one iteration is a weaker argument than a simpler page that is right.

**The change I propose — and it is deliberately only the half I hold.**

*For `-io`, where my mandate is full:* **at intake of any `loop` Issue that changes a rule `/architecture`
states, the closed description names the `-io` surfaces the change invalidates.** That is the
cross-surface staleness line my own brief calls my highest-value intake output, and nobody else in the
roster is holding that list. It converts *"someone will notice"* into a line in a description that a
builder and a gate can both read. It costs one sentence at intake and it would have made #431, PR 518
and PR 520 into scheduled work instead of discoveries.

*For `-skills`, where my standing is narrow:* **I name the class and hand the remedy over.** I may block
on a false published claim there — which is what PR 354 was — and recommend on communication. Whether
the fix is a derived count, a gate arm, or nothing at all is machinery, and machinery is `agents-lead`'s
object, not mine. **The observation I am handing over is the specific one:** the gate standing next to
that README sentence pins node counts and hook names and reads no prose, so the number that was wrong
was the one number nothing derived. **The price of leaving it is that the next hand-maintained count in
that file goes stale the same way, and the earliest thing that can catch it is a lens at a merge gate.**

---

## Finding 2 — eighteen items closed, one of them changed something a reader can see

**Half: PRODUCT (order, value, what the iteration bought).**

**What I saw.** The iteration, enumerated across both milestones rather than remembered:

| repo | items | what they are |
|---|---|---|
| `-skills` | **13** | all `loop` — machinery: #313 #335 #336 #337 #338 #339 #341 #342 #343 #344 #355 #357 #358 |
| `-io` | **5** | all `product`: #431, #506, #516, #556, #572 |

Read the `-io` five by what a reader gets:

- **#516** — the journey photographs move beside the work-experience entries. **New reader value.** One.
- **#431** — *"stale against `-skills`' corrected README"*. **A repair of a published claim.**
- **#572** — the X banner's lockup is centred on the safe area, not on what a reader sees. **A repair of
  a shipped asset**, found by the owner on his phone.
- **#556** — *"restore the digital-bank qualifier"*. **A restoration** of a qualifier an earlier pass had
  cut; I approved it as sourced and correctly bounded (`copy-verdict` on PR 564).
- **#506** — draft review affordances behind the preview parameter. **Internal tooling**; it is the one
  `-io` item in the milestone carrying no `reader-facing` label.

**So: eighteen items, thirteen machinery, three repair-or-restoration, one internal tool, one new thing
a reader can see.**

**What it costs.** This is not a complaint about the machinery work — I have no standing on whether any
of those thirteen was the right build, and I am not claiming one. **The claim is about the ratio, and
the ratio is mine to hold**: `/harness-engineering` already says *a session with zero product slices is
a finding, not a status*, and this is the iteration-scale version of that sentence. The site is the
argument for the repositioning; an iteration in which it gained one visible thing and was repaired three
times is an iteration in which the argument did not advance. **And the loop-first composition rule
(#339, merged inside this very iteration) means the next iteration starts by ordering every `loop` item
ahead of every `product` item** — so the ratio is not self-correcting; it is now the rule.

**The change I propose.** Not a cap and not a quota — I do not think a numeric floor on product items
would survive contact with a week where the machinery genuinely blocks. What I propose is that **the
planning artifact state the split before the iteration is committed**: how many items are machinery, how
many repair a live surface, and how many give a reader something new. Three numbers, written where the
owner composes the iteration, so the shape is a decision he makes rather than one he discovers at the
retrospective. **The price of leaving it** is that the loop keeps doing what it is best shaped to do —
`loop` work flows without a human, `product` work needs his voice and his decisions — and the autonomy
gradient quietly sorts the backlog by what can move without him. That is the failure mode
`/harness-engineering` names in *"discovered vs requested"*, arriving one level up: not a wrong item, a
wrong iteration.

---

## What I would leave alone

- **The `BLOCKING` / `ADVISORY` split, and the relay route.** It held. Every verdict I read back carries
  the two classes labelled and separate, states `BLOCKING: none` explicitly where there were none (PRs
  530, 531, 564), and on PR 532 the gate acted on the distinction exactly as designed —
  `REQUEST-CHANGES` because criterion 10 was unmet, and it said so in those words rather than treating
  my `ADJUST` as a blocker on its face. On PR 531 the gate reached `APPROVE-AND-MERGE` over a verdict of
  mine that was `ADJUST` with `BLOCKING: none`. **The split is doing what it was written to do, and it
  is doing it through an orchestrator relay rather than a tool grant.** Do not tidy this.
- **Reading the positioning source before ruling on copy, and referencing it by pointer.** Every relay of
  mine that touched `/me` or the profile says which private files were read and cites rules by pointer;
  none quotes them. The verdicts are inert outside the private context, which is the property that lets
  them be published verbatim on a public PR at all.
- **`content` staying out of the iteration.** The window merged a large amount of `content` work that
  appears in no milestone, and that is correct — content is selected one piece at a time, not drained.
  Nothing in Finding 2 is an argument for pulling it into the pool.

---

## One thing my evidence says that the dispatch brief did not

**My recorded `-io` count of 1 is not what happened, and the markers say so.** I was told 11 recorded
dispatches in `-skills` and 1 in `-io`, and both numbers reproduce exactly. But `copy-verdict:
product-lead` markers appear on `-io` PRs **526, 530, 531, 532, 564 and 571** — six relays of my own
verdicts, at least four of them long, evidence-bearing reviews — against **one** `dispatch-metrics`
comment in that repository, on #572, recording a 27-second dispatch with 2 tool calls.

**So in the repository where I hold my full mandate, the metrics record roughly one dispatch in six.**
I am reporting this as a contradiction in the evidence and **not** as a finding: what causes it is the
behaviour of a hook, and hook behaviour is functioning, which on `-skills` is outside my standing. It
matters here for one reason only, and it is a reason about *this rite* rather than about the machinery:
**a future retrospective that ranks personas or repositories by recorded dispatch cost would conclude
that this persona barely ran on the product, and it would be wrong by a factor of about six.** Read the
per-repository counts as a lower bound in the direction the scope record already warns about.
