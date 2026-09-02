---
description: Sweep the running product at iteration close — the live surface, derived rather than listed, at more than one viewport and in every locale, and report what a reader would meet. Use when the drain reports its entry snapshot exhausted, or when the owner types it against an iteration worked by hand. It returns observations for the owner, never a verdict, and it gates nothing.
purpose: give the closing of an iteration a look at the running product, because every gate in this loop reads a diff and none of them can see a page that renders wrong
argument-hint: "[iteration] (defaults to the active iteration)"
---

Run the sprint review for the iteration named by `$ARGUMENTS` (default: the active iteration, derived
from the pool per `/agents-configuration` rule 1 — **enumerate, never type a milestone name**).

**This file is the second half of a promise that was plural for months.** `/autonomy on` has said *"the
closing ceremonies run against the exhausted iteration"* since #326; `/sprint-retrospective` (#355) was
the first half and said in its own last section that this half was **not built**. It is built now, and
that section is struck rather than deleted, because it is what told every reader the half was refused.

## What this is, and the two things it is not

**It is an OBSERVATION SWEEP of the running product.** Merge is deploy under `trunk-single-env`, so
there is no staging copy and no preview: the thing being looked at is what a reader is looking at.

**It is NOT a gate, and it returns NO verdict.** This is not a preference and it is not a posture that
could be tightened later — it is what makes the rite admissible at all. The finding a looker produces
is *taste plus observation*, and this repository's own rule is that
**a gate with no ruler grades taste**. Every finding here is advisory and droppable, including the mechanical ones. The gates that
can block already ran, per PR, on the diff.

**And it is NOT a defect hunt over the diff.** `quality-assurance` reads diffs, twice per merge, under
two lenses. This rite exists for the class no diff carries: a banner off-centre, a preview bar
rendering without its link, a layout that reads wrong at 390px. **Those were found by the owner on his
phone, after every gate went green.** That is the gap, stated as the reason rather than as a slogan.

## The trigger, and where it sits among the three rites

**The drain reaching exhaustion of its ENTRY SNAPSHOT** — the same signal `/sprint-retrospective` uses,
read against `/autonomy on`'s own terminal condition rather than against a second definition invented
here. **The typed fallback is this file's `argument-hint` and it is not a lesser path:** an iteration
worked without `/autonomy on` never reaches the mechanical trigger, so the owner types it.

**It runs FIRST of the three, and the order is Scrum's own:**

> **`/sprint-review` → `/sprint-retrospective` → `/sprint-planning`.**

Two independent reasons, and either alone would settle it:

1. **Legibility, which is why the rites carry Scrum names at all.** In Scrum the Sprint Review precedes
   the Sprint Retrospective. A reader who knows the events and finds them in a different order has been
   handed a name that no longer helps him predict anything, which is the whole of what the naming was
   for.
2. **The retrospective feeds each consulted persona its OWN artifacts.** This rite's report is one of
   them. Run second, it would be an artifact produced after the consultation that would have read it.

**Nothing sequences these.** No hook fires any of the three; the order is an instruction in a command
file, and by this loop's own test — *would something stop me, or only my memory?* — it is not
engineered.

## The driver is `product-lead`, and that is a MEASUREMENT rather than a preference

**Dispatch `product-lead`, once.** It is the only persona in the roster holding a browser, and the
brief it already carries — *"You hold a browser — the ITERATION-CLOSE REGRESSION SWEEP of the live
site"* — is the mechanical half of this rite in full: the derivation, the two halves, the fail-loud
rule, the report path. **This file is the rite; that brief is the procedure.** Read them as one thing
and do not restate either inside the other.

**The owner named that persona for it, and his reason is the constraint on everything below** —
*«ele tem a visao de proposito conectada a engenharia»*: the purpose-view held together with enough
engineering to know what a failed request was serving. A console error read by someone who does not
know what the page was for is a line nobody can act on.

**Any other driver is denied by a hook, and this was measured rather than assumed.**
`hooks/scripts/mcp-guard.sh` grants the browser to that persona by name and denies every other
`agent_type` by default:

```
printf '%s' '{"tool_name":"mcp__plugin_tadeumendonca-skills_chrome-devtools__navigate_page","agent_type":"<plugin>:quality-assurance"}' \
  | bash hooks/scripts/mcp-guard.sh
# → permissionDecision: "deny" — "holds no MCP grant … New personas default to DENY here"
```

**So a rite driven by the gatekeeper would fail at its first navigation**, and the repair would be a
second MCP grant — widening a surface that was deliberately narrowed to one persona and one read-only
tool subset. **That is a decision, not an implementation detail**, and it is recorded in ADR-0002's
thirtieth amendment rather than taken here.

**The second reason is about the rite rather than about the hook, and it survives the hook changing.**
The gatekeeper's whole discipline is a ruler external to itself — the Issue's requirements, the
Definition of Done. **This rite deliberately has no ruler.** Handing a rite with no ruler to the one
persona built around one produces either a verdict nobody asked for or a gate with no ground, and both
are the failure this rite's own shape refuses.

## The hard part: how the sweep knows what to look at, without a list that rots

**A route list rots**, and a sweep whose list is stale reports green over the routes nobody enumerated.
That objection was the reason this half stayed unbuilt, and it is answered here in three axes rather
than argued away. **Two are derived. The third is not enumerable at all, and the rite says so.**

### Axis 1 — the routes are DERIVED from the artifact that already defines them

**Run the consuming repo's own route generator.** Do not type a route list, and do not read one out of
this file — this rite ships no list, deliberately. The concrete command belongs to the consumer and is
named in `agents/product-lead.md`, which is entitled to name it; the property is what matters here:

> **The generator that emits the sweep's targets is the same function the sitemap and the prerender
> consume.** A route that exists in the product is in that list *by construction*, and a route that is
> added without appearing in it is broken for search engines before it is missed by this sweep.

That is the whole of the answer to *"a list by another name?"* — **yes, it is a list, and no, it does
not rot**, because nothing maintains it: it is generated, and its staleness is not a state the product
can be in while working. **If the generator cannot be run, that is a FAILED sweep, not a sweep with a
smaller list.**

### Axis 2 — the viewport is a closed set, and it is where the motivating defects lived

**Every route is looked at on a phone viewport and a desktop viewport, in every locale.** This is a
list, it is small, and it is enumerated in the rite rather than derived — so it is stated as the one
place staleness can enter: **a viewport class the product starts caring about (a tablet, a foldable, a
print stylesheet) is invisible here until someone adds it.**

That is a real residual and it is cheap only because the set is short and its members change rarely.
**It is named here so it is a known bound rather than a discovery.** The three defects that motivated
this rite were all found at a viewport, so this axis is not overhead — it is the axis.

### Axis 3 — the assets are read OFF THE PAGE, and this is the axis no list could have held

**Do not enumerate assets.** The page states its own, and two read-only browser tools answer for them
without anyone writing anything down:

- **the network log** — a missing image, a 404 on a font, a failed API call. A broken asset announces
  itself as a failed request; nothing had to know its name in advance.
- **the accessibility/DOM snapshot** — an element that rendered without the thing it was for. *A preview
  bar rendering without its link* is exactly this shape, and it is why the snapshot is taken per route
  rather than only when something looks wrong.

**This axis is the direct answer to the objection.** The motivating defects were found *on an asset no
route list would have enumerated by name* — and no list here does, because the page is the enumerator.

### And the sweep is INCOMPLETE. It says so, in the report, every time

**Route × viewport × the page's own assets is a product of three derived-or-small sets, and it is still
a lower bound.** State this in the rite rather than after it, because a sweep that reads as complete is
worse than one that admits it is not:

- **Anything behind an interaction the sweep does not perform.** The browser grant is read-only —
  `evaluate_script`, `fill`, `type_text`, `upload_file` and `handle_dialog` are denied by
  `mcp-guard.sh` — so anything reachable only by entering data is out of reach by construction.
- **Anything time-, data- or state-dependent.** The sweep sees one moment, logged out, on a throwaway
  profile.
- **Anything an emulated phone renders differently from a real one.** The defects that motivated this
  rite were found on **an actual phone**; the sweep emulates one. **This is the residual most likely to
  matter, and nothing here closes it.**

**So the honest claim is a lower bound, in those words, in the report.** The counts are what make the
bound checkable rather than rhetorical: `routes emitted: N / routes visited: N`.

## The report — two halves, reported SEPARATELY, and its failure is LOUD

**`product-lead` writes the report itself**, to the consuming repo, one file per iteration, at the path
its own brief names. It is not relayed through the orchestrator: relaying is the aggregation the
closing rites' isolation exists to prevent, already ruled on for the retrospective, and the same
argument applies unchanged.

**The two halves never merge into one list**, because merging makes the first invisible inside the
second and the first is the one that means someone has to act tonight:

| half | what a finding is | who acts |
|---|---|---|
| **mechanical** | evidence — it rendered or it did not, the request failed or it did not | the owner, possibly tonight |
| **judgement** | observation plus taste, labelled as taste | the owner, at the next planning |

**An empty section that says it is empty is a result. A missing section is a step that silently did not
run.** Both headings appear every time.

**A sweep that could not reach the site reports FAILED, never "no findings".** The rite runs at
iteration close, which is exactly the moment nobody is watching, and a clean-looking report is precisely
what a broken sweep produces if it is allowed to. The conditions are in `agents/product-lead.md`; the
rule here is that **the two counts lead the report**, because a reader who sees no counts at all knows
nothing and will assume the best.

## The output is a PROPOSAL, and the owner opens whatever becomes work

**Nothing here files an Issue and nothing here changes anything.** The judgement findings are candidates
for the next iteration and `/sprint-planning` reads them alongside the retrospective's proposals; the
owner rules on each. This is already mechanical rather than promised — `permission-guard.sh` rule 5c
denies `gh issue create` to every subagent but `developer`, and rule 5e denies this rite's driver every
public surface — and the rite adds no second control over it.

**A sweep finding must never be relayed as a BLOCKING truth finding.** That veto is about *the truth of
a published claim*. A broken image, a console error and a bad line-break at 390px are none of them
claims, and dressing one as a truth finding would convert an advisory rite into a merge blocker through
the one door its driver holds. **This is an instruction and nothing enforces it.**

## What nothing enforces, said before any green is read

- **Nothing fires this.** `/autonomy on` names it at its terminal condition; that is an instruction in a
  command file. No hook can be built for it: nothing in `hooks/scripts/` reads the queue — every
  `gh issue` call there is a write path — so no layer here can observe a snapshot going empty, and a
  hook receives one `cwd` while an iteration is two milestone objects in two repositories.
- **Nothing observes that it ran, or that it ran over the right iteration.** A skipped sweep, a sweep
  run over the wrong iteration and a sweep that visited four routes of eighteen are indistinguishable
  from the tracker.
- **Nothing bounds what it reports.** There is no cap, deliberately: the mechanical half's size is a
  property of the site rather than of the reporter, and capping it would hide failures. The judgement
  half is bounded by the same instruction the retrospective uses and by nothing else.
- **Nothing scopes the driver's `Write`.** It is instructed to write one report file; nothing stops it
  writing elsewhere. `content-reviewer` carries the identical unenforced shape.
- **`hooks/scripts/inventory-counts.test.sh` asserts this file's rules are WRITTEN.** It cannot assert
  that a session obeyed any of them, and no arm anywhere claims otherwise.

## What this rite cannot see

- **Anything outside the three axes above.** See *And the sweep is INCOMPLETE*.
- **Anything only a logged-in reader meets.** No agent authenticates, and that rule is not suspended
  because a tool made it easy.
- **Whether a finding is worth acting on.** It has no ruler for layout and only one for wording
  (`published-voice`, quoted by clause or it is a preference, not a finding). That asymmetry is
  deliberate and is not repaired by inventing a design standard at the moment one is needed.
- **Every defect in the method.** Those are `/sprint-retrospective`'s class. **This rite finds none of
  them, and that rite finds none of these** — which is why there are two, and why the plural in
  *"the closing ceremonies"* is finally true.
