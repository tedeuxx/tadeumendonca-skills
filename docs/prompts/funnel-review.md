# Portable prompt — a rite whose data lives behind a login, and the two words it must never collapse

**Who this is for.** An engineer running an agent development loop that *publishes* something —
articles, posts, a product surface — and wants a periodic, repeatable read of whether any of it
reached anyone. **It is written to be adoptable with no hooks, no permission layer, no per-agent
identity stamp and no gate of any kind**: every sentence below is an obligation you can decide to
hold, or a measurement you can re-run in your own tree.

**What it deliberately is not.** It carries no configuration from the loop it came from — no file
paths you are expected to copy, no persona names, no rule numbers, no metric list. **Behaviour, the
reasoning behind it, and the limit.** Where the limit is *"nothing enforces this"*, that is the
sentence rather than a gap in the write-up.

---

## 1 · The gap: every gate you have reads a diff, and a diff cannot say whether anything was read

A loop of this shape verifies **what was built**. Lint, tests, coverage, a reviewer, a gate — every
one of them takes a change as its subject. Not one of them can answer the only question that matters
about published work: *did it reach anyone, and did reaching them do anything?*

That question has an answer, and the answer lives outside the repository — in an analytics console, in
a platform's post metrics, in a surface your loop does not own. **So it is invisible to every
instrument you already have**, and the default outcome is that nobody asks it, or asks it once.

**The motivating instance, because it is what makes this worth building rather than admiring.** One
session read those surfaces by hand, for one period, and located a defect nobody had named — a
specific failure in how a piece was being introduced to readers, visible only once reach was compared
against engagement. **It was real, and it was unrepeatable:** no questions written down, no store, no
baseline, no bound on how much work it could generate.

**That is the whole of the move. You are not building a metrics pipeline; you are making one sitting
repeatable.**

---

## 2 · The hard part is not the data. It is that the data is behind a login

**Whatever you build, someone will have to authenticate.** The three routes, and their real costs:

| route | what it costs |
|---|---|
| the loop holds a read credential | a stored secret, a new surface to audit, and an argument about what else that credential reaches. Cheap to use, expensive to justify |
| a human fetches and pastes | no credential and no surface — and the rite is **unfireable by construction**, because it cannot start without a human doing work first |
| the loop drives a session the human is **already** authenticated in | nothing stored, nothing granted. The rite runs when that session is present and **reads nothing when it is not** |

The loop this came from took the third. **Whichever you take, write down which and why**, because the
consequence differs per route and the artifact has to carry it.

**The third route's consequence is the one nobody expects and it is the reason for this prompt:** the
rite becomes **conditionally collectable**. It runs, it reads nothing, and it produces a report.

---

## 3 · The move that ports: did-not-run and ran-and-found-nothing MUST print different words

> **A rite that quietly does nothing is indistinguishable from one that ran and found nothing.**

This is the sentence to keep. Both states produce a calm artifact with no findings in it, and a reader
— including the next run of your own loop — reads both as *the funnel is fine*. **One of those two
readings is a lie, and nothing about the output says which.**

**So make the two states print distinct literals, at a fixed position, and make one of them structural
rather than textual:**

- **could not collect** → a literal saying so, **with no findings section at all**;
- **collected** → a different literal, **with a findings section that may say it is empty**.

**An absent section and an empty section are different claims**, and only the second means the
surfaces were read. A reader who has to compare two adjectives will not; a reader who finds a heading
missing notices.

**Three properties worth copying exactly:**

1. **Neither literal is a substring of the other.** Otherwise a search for one is satisfied by the
   other, and your check is green for the wrong reason.
2. **The declaration is made by the actor that can observe the condition.** Only the collector knows
   whether it had an authenticated session. So the collector writes that fact into the collection
   artifact, and the analysis reads it rather than inferring it. **An analysis that infers
   *not collected* from *no data* cannot tell it apart from a genuinely empty period.**
3. **The declaration WINS over anything else in the artifact.** If it says nothing was collected, no
   number below it is printed — even if numbers are there. Otherwise the declaration is decoration,
   and the failure mode is publishing a figure from a surface nobody reached.

**Test it by running both branches in one pass**, and calibrate by breaking the *source* — delete the
could-not-collect branch and confirm your check goes red, then restore it. A check that has only ever
passed has been observed passing, which is a much smaller claim than it looks.

---

## 4 · Split the rite at the credential line, and the analysis half becomes buildable today

**Collection** needs the authenticated surface. **Analysis** needs none of it. Separate them with a
**file**, and you get three things at once:

- the analysis half is buildable and testable **now**, before any credential question is settled;
- the collection artifact is the only record that a surface was ever read, so it is also your
  **baseline** for next period;
- the rite survives whatever you later decide about the route, because only the first step changes.

**Store the collection verbatim, not just the conclusion.** A report is derived and can be
regenerated; a reading cannot. A store that kept only the prose has a baseline nobody can recompute.

---

## 5 · Four rules for the numbers, and each one is a defect somebody shipped

1. **No figure without its sample size.** Small audiences produce single-digit denominators, and a
   finding drawn from six sessions is a story about six sessions. **Print the n beside the number or
   do not print the number.**
2. **A figure that arrived without a sample size is reported as UNUSABLE, not dropped.** Dropping it
   satisfies rule 1 silently and hides that a collection run came back malformed.
3. **Every figure carries the ceiling that bounds it, and the ceiling is SURFACE-SPECIFIC.** If a
   consent banner gates your own analytics, every figure from it counts consenting sessions only and a
   reader who declined is invisible by design. **Do not paste that clause onto a figure from a
   platform you do not control** — its bound is different (the platform's own unstated sampling), and
   a true clause on the wrong surface is a false bound wearing the right word. That is worse than a
   missing one, because it reads as having been thought about.
4. **Say when there is no baseline.** A number with no prior period, printed bare, is read as a trend.

---

## 6 · Bound what it can produce, or you have built a machine for generating work

The motivating sitting produced three tracked items in one evening. **Run that monthly and the rite's
output is the loop's next month.**

**Cap the findings at a number**, declare it in the source rather than in prose, and print it into
every report. Two is a defensible ceiling for one reporter. **The cap is a ceiling and never a quota**
— *"none this period"* under the heading is a result.

**And what you can actually check is narrower than the rule**, so say so: no shell can count findings
inside a model's prose. What a check *can* count is headings in the artifacts that **landed**. A
period nobody reported is invisible to it.

---

## 7 · It must not become a dashboard, and it must not become a gate

**Not a dashboard.** The value of the motivating sitting was a *located defect*, not a set of numbers.
A rite that renders metrics and stops has replaced a finding with a chart — and a chart is the thing
that gets looked at instead of acted on.

**Not a gate.** Audience judgement has no ruler. A gate with no ruler grades taste, and taste has no
stopping rule. Return observations, return no verdict, and let the human open whatever becomes work.

**Not an opener of work either.** If your loop has a rule that only the human files work, this rite is
exactly where it gets broken — one sitting, three plausible items, all of them real. Findings are
named in the report; somebody else decides which become tracked.

---

## 8 · The limit — say all of this out loud, in the artifact

- **Nothing fires it.** A clock can *notice* that the report is stale, and a notice is not a trigger:
  it cannot dispatch. **Keep NOTICING and FIRING as two words.** Collapsing them is how a loop comes
  to believe a rite runs.
- **Nothing verifies that it read anything.** A collection artifact asserting it read a live console
  is byte-identical to one somebody invented, and no enforcement layer can tell them apart, because
  the browser act it describes reaches no layer at all. **Check that before you write that a route is
  contained** — in the loop this came from, the read and the write travel the same ungated road.
- **Nothing pairs a report with its collection.** A report with no reading beside it passes every
  check.
- **Nothing tells you why a number moved.** Attribution is not in this data, and inventing it is
  exactly what the *not a dashboard* rule is aimed at.

**By the test that matters — *would something stop me, or only my memory?* — this rite is an
instruction.** What it changes is that the analysis is repeatable, the baseline has a home, and two
states that used to look identical now print different words. Claim that, and nothing more.
