# The funnel-review store — one report per period, and the collection it was computed from

**This directory is the rite's artifact root, and it is what gives a finding a baseline.** Before
#401 no prior period was stored anywhere, so every observation about the content funnel was a
single reading with nothing to compare it against. Measured at the time this landed, against
`origin/main`:

```
git ls-files | grep -icE '^docs/funnel-review'        # -> 0
git ls-files | grep -cE  '^docs/retrospective/'       # -> 8   (calibration: the same selector
                                                      #         over a root that DOES exist)
```

**Two files per period, and they are different kinds of thing.**

| path | what it is | who writes it |
|---|---|---|
| `collected/<period>.tsv` | **what was read off the surfaces**, verbatim, one figure per line with its sample size | the rite's driver, from the owner's own authenticated browser |
| `<period>.md` | **the report** — the analysis, the comparison against the prior period, and at most two findings | the rite's driver, from `scripts/funnel-review.sh` |

**The split is not tidiness.** The report is derived and can be regenerated; the collection is the
only record that a surface was ever read, and it is the thing the next period compares against. A
store that kept only the prose would have a baseline nobody could recompute.

## The collection file's parsing contract

Positional, at column 0, read literally — exactly as `cadence-rite:`, `invocable:`, `purpose:` and
`loop-mode:` already are in this repository, and for the same measured reason: a token that can also
occur inside wrapped prose is not a declaration, a **position** is.

```
collected: yes <date> <provenance>       the surfaces were read
collected: no  <reason>                  they were not — and this is NOT "no findings"
figure: <surface> <metric> <value> <sample-size>
```

**`collected:` is the line the whole rite turns on.** The collection route is the owner's own
already-authenticated Chrome (owner ruling, 2026-09-10 — *«hoje o chrome do host esta autenticado. o
claude in chrome consegue acessar.»*), so the rite is **conditionally collectable**: with no
authenticated session there is nothing to read, and nothing in this harness can open one. A driver
that could not read writes `collected: no <reason>`, and the report prints
`FUNNEL-REVIEW-NOT-COLLECTED` with no findings section at all.

**A `figure:` line with no numeric sample size is printed as UNUSABLE and never as a figure.** This
repository's rule is that a number ships with what bounds it or not at all; dropping the malformed
line instead would hide that a collection run came back wrong.

### `<surface>` is a CLOSED vocabulary, and an unknown one is refused rather than described

| surface | the ceiling that rides with every one of its figures |
|---|---|
| `ga4` · `site` | consenting sessions only — this site's banner gates its analytics, so a reader who declined is invisible by design |
| `linkedin` · `x` | the banner gates nothing there; the figure is platform-reported, with the platform's own unstated sampling |
| anything else | **`UNDECLARED`** — nothing here knows whether a consent gate applies, so nothing here says |

**The default refuses rather than asserting, and that is a repair rather than a design choice.** The
first form gave the site's clause to two names and told **every** other string that the consent banner
gates nothing there — false for `ga`, `site-analytics` or `gsc`, all plausible spellings of a
site-side surface. A default that asserts a bound it cannot know is worse than one that declines,
because only the first is quotable. **Adding a surface means adding a row here and a case in
`scripts/funnel-review.sh`, in the same change**; until then its figures print as unbounded.

### A `*`, `?` or bracket class in any field is a plain character

The analysis script sets `set -f` before it splits a line, so a field is never replaced by filenames
in whatever directory the script happened to run from. **This is not a defence against an attacker** —
it is that a `*` in an analytics page path or a campaign name is **ordinary**, and without it the
published figure was a function of the working directory, with both paths exiting 0 and nothing
warning. `scripts/funnel-review.test.sh` asserts it from a directory seeded with files that **do**
match, and proves the trap is live with a control split before reading the script's output.

## What nothing here enforces

| decision | what actually holds it |
|---|---|
| a period is collected at all | **nothing.** No hook reads an external surface — see the measurement in `commands/funnel-review.md` |
| `collected: yes` is TRUE | **nothing.** A driver that invented its figures produces a byte-identical file to one that read them |
| a report lands for a period that was collected | **nothing.** `scripts/funnel-review.test.sh` reads the artifacts that landed; a period that was never reported is invisible to it |
| the cap of two findings | **the test, over LANDED artifacts only** — it counts `## Finding` headings in the reports that exist |
| the store's two halves stay paired | **nothing.** A report with no collection file beside it passes every check here |

**By this loop's own test — *would something stop me, or only my memory?* — this store is a record
and not a control.** `hooks/scripts/cadence-notice.sh`, registered on **`SessionStart`**, reports how
long since a report last landed here — which is **noticing** and never **firing**: a `SessionStart`
hook returns context, not a dispatch, and nothing in this harness can run a rite.

## The period name

Any string that sorts. `scripts/funnel-review.sh` finds the prior period by taking the greatest
collected name lexically below this one — lexical rather than chronological on purpose, because a
date parser here would be a second contract nobody declared. `sprint-02` and `2026-09` both work;
mixing the two conventions in one store does not, and nothing stops you.

**`2000-01` through `2000-05` are reserved** — they are the synthetic fixtures under
`scripts/fixtures/funnel-review/`, and they are deliberately outside this directory so that a test
period can never be mistaken for a reading of the real funnel.
