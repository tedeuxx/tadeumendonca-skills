---
description: Read the content funnel end to end for one period — the site's own analytics and the post metrics for what was published — and return at most two findings about where the funnel breaks. Use when the retrospective runs at the close of an iteration, or when the owner types it against a period worked by hand. It returns observations for the owner, never a ruling, and it gates nothing.
purpose: give published content a feedback loop the loop itself can run, because every gate in this harness reads a diff and not one of them can see whether anything published was reached, read or acted on
argument-hint: "[period] (defaults to the active iteration)"
---

Run the funnel review for the period named by `$ARGUMENTS` (default: the active iteration, derived
from the pool per `/agents-configuration` rule 1 — **enumerate, never type a milestone name**).

**This rite exists because it already ran once, by hand, and found something nothing else would
have.** On 2026-09-04 one session read the site's acquisition and landing-page reports, read the post
metrics, compared both against the published corpus, and located a defect neither the owner nor the
loop had named — that a teaser asserting nothing earns no comment, and that the failure sits in the
first line. **That sitting is the rite.** What it was not, until now, is repeatable: it had no
questions written down, no store, no baseline, no cap and no way to tell a run that found nothing
from a run that could not read anything.

## What this is, and the four things it is not

**It is a READ of one period's funnel, end to end** — reach, click, read, share, contact — against
the pieces published in that period, returning where it breaks.

**It is NOT a dashboard.** The value of the prototype sitting was a *located defect*, not a set of
numbers. A rite that renders metrics and stops has replaced a finding with a chart, and a chart is
the thing that gets looked at instead of acted on.

**It is NOT a gate, and it returns no ruling.** Marketing judgement has no ruler, and this
repository's own rule is that a gate with no ruler grades taste. Every observation here is advisory
and droppable. This is the same constraint `/sprint-review` carries, for the same reason, and it is
not a posture that could be tightened later — it is what makes the rite admissible at all.

**It is NOT a generator of work.** The prototype produced three tracked items from one sitting; a
rite producing three items per period is a machine for generating work, which is the failure this
loop names first. **The cap is two findings**, declared as a number in `scripts/funnel-review.sh` and
printed into every report.

**It is NOT a publisher of unbounded numbers.** Every figure ships with its sample size and the
ceiling that bounds it, or it is printed as unusable and not as a figure.

## The cadence is the RETROSPECTIVE's — it has no clock of its own

**Owner ruling, 2026-09-11, verbatim:**

> *«a avaliacao de metricas considerando que deveriamos estar trabalhando em sprints de 1 semana
> deveria ser feita no momento da sprint retrospective acho.»*

So this rite runs **at the moment `/sprint-retrospective` runs**, and the iteration length he named is
**one week**. It declares no interval of its own, and `docs/loop-cadence.md` carries no per-rite
interval field — a second interval axis with one member would be a configuration surface with no
reader.

**It is a fourth rite, not a fourth step of the retrospective.** The retrospective consults each
persona that ran, in isolation, about the **method**; this reads the **audience**. Neither finds the
other's class, which is the same reason `/sprint-review` is a separate rite rather than a section of
one. The order is `/sprint-review` → `/funnel-review` → `/sprint-retrospective` → `/sprint-planning`:
this rite's report is evidence the retrospective can feed back, exactly as the sweep's report is, so
running it after the consultation would produce evidence the consultation could not read.

**The conditional in his own sentence is carried rather than resolved.** *«considerando que
deveríamos estar trabalhando em sprints de 1 semana»* presupposes a ceremony that fires at a
container boundary. Read the mode from `docs/loop-mode.md` **before** assuming one does — and note
that under the lighter mode no rite runs at a boundary at all, so the anchor would be an anchor to
something that does not currently happen. That is a decision about the mode, not about this rite, and
nothing here resolves it.

**The clock carrier NOTICES this rite and cannot fire it.** `docs/loop-cadence.md` carries
`cadence-rite: docs/funnel-review /funnel-review here`, so `hooks/scripts/cadence-notice.sh` — a
`SessionStart` hook — reports how long since a report last landed in the store. **Noticing is not
firing: a hook cannot dispatch.** And no interval is decided anywhere — the record ships with
`cadence-interval-days` undeclared and the carrier refuses to conclude rather than defaulting, which
stays true until the owner declares one.

## The route is the owner's own authenticated browser — and there is no credential

**Owner ruling, 2026-09-10, verbatim:**

> *«hoje o chrome do host esta autenticado. o claude in chrome consegue acessar.»*

He was offered two routes — an attended fetch he drives by hand, or a read credential held by the
harness — and took neither. **The harness holds no credential of its own and will not.** Claude in
Chrome drives a session that is already authenticated as him; nothing is stored and nothing is
granted to this plugin. The examination a harness-held credential would have owed is therefore **not
owed**, because there is no credential surface to examine.

**Two consequences, and the second is this rite's sharpest property.**

1. **The rite is CONDITIONALLY COLLECTABLE.** It reads when a session runs with an authenticated
   browser present; with none, it reads nothing. Nothing in this harness can open one.
2. **So the two states print DIFFERENT LITERALS**, at column 0, in the report:

   | literal | what it means |
   |---|---|
   | `FUNNEL-REVIEW-NOT-COLLECTED` | **nothing was read.** There is no findings section at all — not an empty one, none |
   | `FUNNEL-REVIEW-RAN` | **the surfaces were read.** The findings section exists and may say it is empty, which is a result |

   **A rite that quietly does nothing is indistinguishable from one that ran and found nothing.** That
   is this repository's own named worst shape and it is the whole reason the two literals exist.
   `scripts/funnel-review.test.sh` runs both branches in one pass and asserts each prints its own
   literal and **not** the other's.

## The containment is STATED, not implied — measured, at head

**No hook in this plugin observes the browser route.** Every registered hook sits on one of two
matchers, and a browser-extension act is neither:

```
jq -r '[.hooks|to_entries[]|.value[]|.matcher // "none"]|unique|join(" ")' hooks/hooks.json
# -> Bash mcp__.* none

jq -r '[.hooks|to_entries[]|.value[]|.hooks[]|.command]|length' hooks/hooks.json          # -> 15
jq -r '[.hooks|to_entries[]|.value[]|.hooks[]|.command]|unique|length' hooks/hooks.json   # -> 14
```

**Both figures are true and they answer different questions** — 15 registrations across 14 distinct
scripts, because `preflight.sh` is registered twice. Publish whichever you mean, with its selector.

**And no registered hook reaches an external surface of its own:**

```
jq -r '.hooks|to_entries[]|.value[]|.hooks[]|.command' hooks/hooks.json \
  | sed 's|.*/hooks/scripts/|hooks/scripts/|; s|"$||' | sort -u \
  | xargs grep -nE '(^|[^[:alnum:]_])(curl|wget|nc)[[:space:]]' | grep -vE ':[0-9]+:[[:space:]]*#'
# -> no output

# CALIBRATION — the same pipeline, a token that IS present in those files:
jq -r '.hooks|to_entries[]|.value[]|.hooks[]|.command' hooks/hooks.json \
  | sed 's|.*/hooks/scripts/|hooks/scripts/|; s|"$||' | sort -u \
  | xargs grep -lE '(^|[^[:alnum:]_])gh[[:space:]]' | wc -l
# -> 11
```

**So reads and writes travel the same ungated road**, and that is a fact this rite carries rather
than a boundary it implies. Nothing verifies that the rite ran, nothing verifies what it read, and
nothing would notice a fabricated collection file.

**What IS mechanical, and it is a different surface entirely.** The only browser a *dispatched
persona* can reach in this plugin is `product-lead`'s read-only `chrome-devtools` subset, and
`hooks/scripts/mcp-guard.sh` denies it to every other persona by default — measured, same payload
shape, only the `agent_type` varying: `product-lead` + `navigate_page` draws no decision, and
`quality-assurance` + the same tool comes back denied with *"holds no MCP grant"*. That guard is
**not** what contains this rite's route; it contains a different one, and saying so is the point.

## The steps

### 1 · Collect — where the authenticated browser is, and nowhere else

**The output of this step is a file, not a paragraph:**
`docs/funnel-review/collected/<period>.tsv`, in the contract `docs/funnel-review/README.md` declares.

Read, for the period:

- **the site's own analytics** — sessions, the acquisition split, the landing pages, and every funnel
  event the site declares. Read the event names out of the consuming repository rather than typing a
  list here: a list rots, and the declared set is in that repo's own analytics module;
- **the post metrics** for each piece published in the period — impressions, reactions, comments;
- **nothing else.** X analytics are out of scope by name; they were not read even in the prototype.

**Write `collected: no <reason>` and stop when the browser is not authenticated.** That is the
honest output of a step that could not run, and it is what makes the not-collected literal reachable.
Do not guess a number, do not carry one forward from the prior period, and do not omit the file.

**Whether a dispatched subagent can drive the Claude in Chrome extension at all is UNMEASURED — that
is a hypothesis, in those words**, and this rite is shaped so the answer does not matter: collection
happens wherever the authenticated browser is reachable, and every step after it needs no browser.
What would settle it is one dispatch attempting the act and reporting what came back.

### 2 · Analyse — no network, no credential, against the committed file

```
bash scripts/funnel-review.sh <period>
```

It reads the collection file and the prior period's, prints each figure with its sample size and its
ceiling clause, prints the comparison against the baseline or says there is none, and prints the
report skeleton. **It makes no network call** — asserted by a suite that puts a recorder on `PATH` in
place of `curl`, `wget`, `gh`, `nc`, `ssh`, `open` and `osascript` and reads a file that can be
non-empty, with one direct invocation proving it can.

### 3 · Report — at most two findings, into the store

`product-lead` writes `docs/funnel-review/<period>.md`. It is the driver for the same reason it drives
`/sprint-review`: it holds the reader's and the market's side, and the owner named that view for
exactly this work. It holds `Write` and `Bash`, so it runs step 2 and lands the file itself; nothing
is relayed through the orchestrator, because relaying is what turns a rite's own artifact into
somebody else's summary of it.

**A finding is:** what the numbers show · the figure that shows it · what it costs · the change
proposed, or the price of leaving it. **At most two, the driver choosing which** — and *"None this
period"* under the heading is a result, where a deleted heading is a step that silently did not run.

### 4 · The output is a PROPOSAL, and the owner opens whatever becomes work

Nothing here files an Issue and nothing here changes anything. **Only the owner opens work** — and
this is already mechanical rather than promised: `hooks/scripts/permission-guard.sh`, registered on
`PreToolUse` against the `Bash` matcher, denies `gh issue create` to every subagent but `developer`
(rule 5c), and denies this rite's driver three subcommands by name (rule 5e). Read that as three subcommands, not as *"every public surface"*: `gh pr create`, `gh pr edit`
and a `git push` are untouched by it.

## The questions this rite answers — the corpus, and what it costs

**Read the published corpus out of the consuming repository, never from a list here.** The pieces are
in that repo's own content tree, and a list in this file would rot the way a route list rots. Per
period, against that corpus:

1. **Reach** — did anything published in this period get in front of anyone, and from where?
2. **Click** — did reach become a visit?
3. **Read** — did a visit become a read? *(The prototype found this unmeasured; whether the site's
   declared read events actually fire is a question about the consuming repository, not this rite.)*
4. **Share and contact** — did a read become anything at all?
5. **Against the prior period** — which step moved, and is the movement bigger than the sample?

**The honest bound on all five: the per-piece numbers are small.** The prototype's per-article
figures rested on single-digit session counts, and a finding drawn from six sessions is a story about
six sessions. Say the n beside the number or do not say the number — which is why the analysis half
refuses to print a figure that arrived without one.

## What nothing enforces, said before any green is read

- **Nothing fires this.** `/sprint-retrospective` names the moment; that is an instruction in a
  command file. The clock carrier reports that the artifact is stale, one session late, and **cannot
  dispatch** — noticing is not firing, and the two words must not be collapsed.
- **Nothing observes that it ran, or that it read anything.** A collection file asserting
  `collected: yes` with invented numbers produces a byte-identical run to one read off a live
  console. Nothing in this harness can tell them apart, and no layer could: the browser act reaches
  no matcher at all.
- **Nothing pairs a report with its collection.** A report with no collection file beside it passes
  every check in this repository.
- **The cap is held over LANDED artifacts only.** `scripts/funnel-review.test.sh` counts
  `## Finding` headings in the reports that exist under the store root. A period that was never
  reported is invisible to it, and no shell anywhere can count findings inside a model's prose.
- **`hooks/scripts/inventory-counts.test.sh` asserts this file's rules are WRITTEN.** It cannot
  assert that a session obeyed any of them, and no arm anywhere claims otherwise.

**By this loop's own test — *would something stop me, or only my memory?* — this rite is an
instruction.** What it changes is that the analysis is repeatable, the baseline has a home, and the
two states that used to look identical now print different strings.

## What this rite cannot see

- **Anyone who declined consent.** The site's banner gates its analytics entirely, so every
  site-side figure is a count of consenting sessions and a reader who declined is invisible by
  design. That ceiling rides with every site-side figure the analysis prints.
- **Anything a platform does not report.** A post's own metrics are the platform's numbers, with the
  platform's own unstated sampling, unverifiable from here — which is why the ceiling clause is
  surface-aware and says something different on those lines rather than pasting the site's.
- **Whether a number caused anything.** It reads a funnel; attribution is not in the data and
  inventing it is the failure mode this rite's *not a dashboard* clause is aimed at.
- **Every defect in the method, and every defect a reader would meet on the page.** Those are
  `/sprint-retrospective`'s and `/sprint-review`'s classes respectively. Four rites, four blind
  spots, none covering another's.
