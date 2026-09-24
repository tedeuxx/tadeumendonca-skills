# sprint-04 — retrospective · product-lead

commit: eda7ed7a90b60742620488927e5181778a2f06b1 (`tadeumendonca-skills`) · 42ac5334a76824e43e08e9708efe15442e2b1504 (`tadeumendonca-io`, `main`)
fed-with: `tadeumendonca-io` `docs/iteration-sweep/sprint-02.md`, `sprint-03.md`, `sprint-04.md` (PRs #675, #677) · `tadeumendonca-skills` `docs/funnel-review/sprint-02.md`, `sprint-04.md` and `collected/sprint-02.tsv`, `collected/sprint-04.tsv` (PRs #503, #519) · `docs/retrospective/sprint-04/00-scope.md`. Read for context: `.mcp.json`, `commands/funnel-review.md` §§ *The route* and *1 · Collect*, ADR-0004's bounded-browser section, and the Codex paragraph in `README.md`.

This covers the joint sprint-03 + sprint-04 close. Both findings are about my two closing rites, and
they have the same shape: **each rite depends on a precondition only the owner can satisfy, and the
rite finds out it is missing by failing, after it has been dispatched.**

## Finding 1 — The bounded sweep browser has never completed a sweep, and each close failed for a different reason

**What I saw.** In three closes, the browser this harness ships for `/sprint-review` rendered nothing:

| close | host | what happened | report |
|---|---|---|---|
| sprint-02 | Codex (the report cites `AGENTS.md` as its consumer brief) | the first page open failed: *"Failed to construct 'URLPattern': A base URL must be provided for a relative constructor string"* · 0 / 22 routes | `-io` `docs/iteration-sweep/sprint-02.md` — **FAILED** |
| sprint-03 | Codex | 22 / 22 routes and 44 / 44 observations, but through **Codex's Chrome extension browser**, not the shipped server. Not isolated, no origin bound, no network log, and the PDF download was refused | `sprint-03.md` — completed with named gaps |
| sprint-04 | Claude Code | `HARNESS_SWEEP_ORIGIN` was unset, so the fail-closed default (`http://127.0.0.1:9/*`) refused the first navigation · 0 / 22 | `sprint-04.md` — **FAILED**, with an HTTP-only supplement |

The sprint-04 cause is measured (`echo "HARNESS_SWEEP_ORIGIN=${HARNESS_SWEEP_ORIGIN:-unset}"` →
`unset`). **The sprint-02 cause is a hypothesis, and I label it as one.** `README.md` records that
Codex's MCP listing shows the `--allowedUrlPattern` argument **unexpanded**, as the literal
`${HARNESS_SWEEP_ORIGIN:-…}`. A pattern starting with `$` has no scheme, which fits a "relative
constructor string" error exactly. Nobody has checked the argv of the running process. The way to
settle it is one Codex session that runs `list_pages` with the variable set, and one that runs it
unset. If the error only appears when the variable is unset, the hypothesis holds.

**The artifact.** The three sweep reports above. The bound is declared in `.mcp.json`:
`"${HARNESS_SWEEP_ORIGIN:-http://127.0.0.1:9/*}"`. The rite's own procedure does not check the
variable before it runs. I grepped `commands/sprint-review.md` for `HARNESS_SWEEP` and `origin`: no
matches.

**What it costs.** This rite exists for the class of defect only a render shows: layout, at phone
width. Two layout defects reached production and were found by the owner on his phone. In two of
three closes that class was not observed at all. The one close that did render did it outside the
isolation and origin bound that ADR-0004 records as the reason this persona may hold a browser. That
sprint-03 report says so plainly, which is correct, but a rite whose only successful render happens
off its own safety bound has not been shown to work. The HTTP probe in sprint-04 was useful: it
checked 35 / 35 served assets and the CV PDF, and it caught the soft 404. But by construction it
cannot see what the rite is for. There is also a quieter cost. Each failed report takes a full
dispatch to write down an absence, and a report that says FAILED at every close starts to read as
the rite's normal output.

**The change I propose — two parts, and the second is the owner's call:**

1. **Check the precondition first, as step 0 of `/sprint-review`, before routes are derived or a
   persona is dispatched.** Confirm the browser's origin bound resolves to the production origin on
   this host. If it does not, stop with one line: *"Set `HARNESS_SWEEP_ORIGIN` to the production
   origin and restart the session, then run the rite."* That is an ACTION pendency under the
   escalation standard (the loop cannot do it), not a FAILED report written after a dispatch. The
   FAILED literal stays for failures that occur after the precondition holds.
2. **Decide where the production origin lives, so it stops depending on session environment.**
   ADR-0004 already names the cheap option it kept open: the consuming repository declares its own
   `chrome-devtools` server with its own bound. The brief and the guard match the bare spelling on
   purpose. `tadeumendonca-io` is the only consumer with a site, and a real domain is allowed in that
   tracked file. **Price:** that repository then carries a second declaration of the same server
   beside the plugin's. How Codex handles that is unmeasured, since it puts plugin servers in a flat
   name space, so a name collision there is possible. It also does not fix the sprint-02 hypothesis if
   Codex does not expand variables at all.

**The price of leaving it:** the next close fails at the first navigation, as it did in sprint-04.
This is the fail-closed design working as intended, and it means the rite cannot run on this host.

## Finding 2 — The funnel has never been collected, and the rite as shaped can only collect when the owner happens to be at the browser

**What I saw.** Two funnel records, and both are `FUNNEL-REVIEW-NOT-COLLECTED`:

- `docs/funnel-review/collected/sprint-02.tsv`: *"collected: no this dispatched persona has no
  authenticated browser route, and the available Chrome DevTools route failed before navigation with
  a URLPattern construction error"*.
- `docs/funnel-review/collected/sprint-04.tsv`: *"collected: no … the orchestrator's Claude in Chrome
  route reported "Browser extension is not connected" in this session, and the dispatched persona's
  chrome-devtools route was not attempted because it holds no authenticated session …"*.

**The artifact.** Those two TSVs and their reports. The rite's own design is in
`commands/funnel-review.md`: the route is *the owner's own authenticated browser* (his ruling,
2026-09-10), the rite is *"CONDITIONALLY COLLECTABLE"*, and *"nothing in this harness can open one"*.

**What it costs.** Across two periods, nothing measured whether any published piece reached anyone,
in either language. The records are honest. The two literals do their job, and neither record claims
a healthy funnel. **But the rite now runs at every close and records absence at every close.** Its
cost is a branch, a PR and a gate pass, and the product it returns is the sentence *"nothing was
read"*. The failure is structural, not bad luck. The route needs him present with a connected
extension. The rite fires at iteration close, driven by the loop. Nothing in the rite checks that
condition before it is dispatched. In sprint-02 the reason recorded was even the wrong tool: the
chrome-devtools server was never a collection route for this rite, because it holds no authenticated
session.

**The change I propose.** Treat collection as an **owner-present act and check it before the rite
starts**, in the same way as Finding 1:

- Before dispatching `/funnel-review`, the orchestrator confirms that Claude in Chrome is connected
  in this session. If it is not, it sends one ACTION line to the owner: *"Connect the Chrome extension
  to run the funnel review, or say skip."* A skipped period is recorded once, in one line, not as a
  full rite run.
- **Or, and this is his call rather than mine:** he fills the few figures into
  `collected/<period>.tsv` himself, then the analysis step runs with no browser. That step already
  needs none: *"every step after it needs no browser"*.

**The price of leaving it:** `NOT-COLLECTED` records keep accumulating. The series starts to look
like a funnel practice that exists, while the audience half of the closing rites has not produced one
reading. There is also an open question about another route: whether a **dispatched** subagent can
drive the extension at all. The rite calls that *UNMEASURED* in its own words, and sprint-04 did not
try it. One attempt with the extension connected would settle it.

## What I would leave alone

- **The fail-closed default in `.mcp.json`.** Do not widen the plugin's bound to a real domain to
  make the sweep pass. That would break the project-agnostic principle, and ADR-0004 had a reason for
  it. The fix is where the origin is supplied, not how wide the default is.
- **The loud literals.** Both `FAILED` and `FUNNEL-REVIEW-NOT-COLLECTED` did exactly what they exist
  for. No record in these closes claims a clean sweep or a healthy funnel it did not observe. The
  sprint-03 label correction, from FAILED to completed with named gaps, was also right: it kept FAILED
  for the conditions the procedure names.
- **The HTTP probe as a supplement that never changes the label.** It is calibrated against the
  catch-all. A nonexistent path answers 200, so the evidence is the route-specific title, `lang` and
  canonical. Keep it labelled as not-a-render.
- **The derived route count and the `emitted / visited` header.** 22 = 22 derived at each close, from
  the generator, with no carried number.
- **Advisory-only.** Nothing from these sweeps was promoted to a merge blocker. That includes the
  section-density observation that sprint-04 re-counted rather than counted twice, and the soft 404.
  That should stay as it is.
