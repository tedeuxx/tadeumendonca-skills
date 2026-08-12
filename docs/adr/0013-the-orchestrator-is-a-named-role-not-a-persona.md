# 0013. The orchestrator is a named role — one term, listed duties, a stated boundary — not a persona

- **Status:** accepted
- **Date:** 2026-08-12
- **Deciders:** owner (ratifies) · tech-lead (writes the record)
- **Supersedes / superseded by:** —
- **Driven by:** a `harness-reviewer` pre-implementation stress test of this proposal (six scenarios,
  independently re-verified by tech-lead before this record was written); no Issue — this is a
  methodology-library decision, filed and closed at tier 1

## Context & problem

The agent that talks to the owner and dispatches every subagent has existed since ADR-0002 and is drawn
as a node in `README.md`'s diagram (`ORCH["ORCHESTRATOR — the main session<br/>dispatches every
persona · commits · pushes<br/>never merges · never decides the irreversible"]`, `README.md:150`), but it
is not defined anywhere as a role: no duty list, no boundary statement outside that one diagram label, and
no single term. The tree currently uses **five** spellings for the same actor, each still live:
`orchestrator` (`README.md:33,150,182,193,197,224,248,254,256` — the diagram itself and prose around it;
also used by `ADR-0012:39`), `main session` (`README.md:150,670`, inside the same diagram node and again
naming the actor `SessionStart`'s injected context reaches), `main loop`
(`docs/adr/0002-agentic-dev-loop-architecture.md:23,991`, `hooks/scripts/permission-guard.sh:124`,
`permission-guard.test.sh` throughout, `skills/principles/dev-loop/SKILL.md:266,294`), `main agent`
(`hooks/scripts/permission-guard.sh:118,931`, `permission-guard.test.sh` throughout, `ADR-0002:812`), and
`invoking context` (`docs/dev-loop-design.md`, `ADR-0006`, `ADR-0002`, `agents/quality-assurance.md`,
`agents/developer.md`, `agents/product-lead.md`). Five names for one actor is the kind of drift ADR-0009
found in skill descriptions and ADR-0012 found in issue-type vocabulary: a decision that is already
half-real in prose and never made a decision.

Two further problems compound the naming gap:

1. **The actor already performs duties nowhere listed together.** It applies the `ready` label that makes
   an Issue executable (`agents/tech-lead.md`, `agents/product-lead.md`), it applies the ADR-0012 routing
   label (`product`/`content`/`loop`) that decides which review path an Issue takes, it commits and
   pushes on behalf of every dispatch, and — per ADR-0006's own measured evidence
   (`docs/adr/0006-a-verdict-owed-to-another-persona-is-an-artifact.md:523`, citing `-io`#338) — it has, at
   least once, decided **not** to dispatch a review lens although the trigger for it had already fired:
   *"the trigger fires and it has NOT been dispatched."* None of that is written down as a duty list; it
   is inferred from scattered mentions.
2. **The one place a boundary is stated (`README.md:150`) is not the orchestrator's own loaded context.**
   `hooks/scripts/inventory-counts.test.sh:1397` states the general rule this record must obey: *"A rule
   that lives only in CLAUDE.md does not reach a subagent: CLAUDE.md is the MAIN agent's context, and a
   persona's context is its own brief."* Read the other way: CLAUDE.md **is** the orchestrator's own
   context, loaded every session, and README.md is not loaded as anyone's context automatically. A
   boundary that lives only in the README's diagram is decorative with respect to the orchestrator's own
   behavior in a fresh session — the exact failure mode ADR-0010/0011 already priced for personas that
   preload nothing.

The problem this record must decide is narrower than "design the orchestrator" — it is: **does this
actor get one name, a listed set of duties, and a boundary statement, without becoming a sixth
dispatchable persona it structurally is not?**

## Decision drivers

- One actor should have one name; five spellings is unforced drift with no reader benefit.
- The duties already being performed (label application, commit/push, the dispatch decision itself)
  should be visible in one place rather than reconstructed by grep.
- The boundary that already exists and is mechanically enforced for two acts (merge, trunk push) should
  be stated precisely — neither overclaimed as broader coverage nor left uncredited.
- The definition must live somewhere the orchestrator itself loads, or it is decorative (ADR-0010's own
  standard, applied here to the orchestrator instead of a persona).
- The orchestrator is **not dispatchable** — it is the dispatcher — so whatever names it must not imply
  it is a sixth entry in the five-persona roster (ADR-0002 amendment #7's whole point: a persona exists
  only where conflict is wanted, or one of the four reasons amendment #10 added; none of those reasons
  fires for the actor that does the dispatching).

## Considered options

1. **Name it "orchestrator," list its duties, state its boundary in prose — not a persona file (chosen).**
   One term across new writing; the duty list and boundary live in this record and are added to CLAUDE.md
   as follow-up (Consequences, below) so the orchestrator's own context carries them. *Trade-off:* this
   ADR fixes the vocabulary and states the boundary but does not itself close the two gaps the boundary
   exposes (Consequences below) — the record documents a role, it does not implement new enforcement.

2. **Leave it undefined, as today (status quo).** *Why not:* the five-way spelling has already
   produced a distinguishable-but-unlabelled term in `ADR-0012:39` (`orchestrator`) beside the guard's own
   `main agent` and the README's `main session` — the drift is active, not hypothetical, and every new
   file picks a spelling ad hoc. And the one existing boundary statement lives in a file
   (`README.md:150`) the actor it describes never loads, which `inventory-counts.test.sh:1397`'s own
   stated rule says makes it non-reaching. Status quo is not neutral; it is "keep the decorative
   definition and the naming drift."

3. **Give it a full `agents/*.md` persona brief, as a sixth roster member.** *Why not:* every persona in
   `agents/` is a **dispatch target** — `Task`-invoked, with its own context window, its own `tools:`
   scoping, and (per ADR-0002 amendment #10) its own reason among the four that justify a persona's
   existence. The orchestrator satisfies none of those reasons: it is not dispatched, it does not need a
   fresh context from itself, and giving it a brief would misrepresent it as one more subagent among
   five — exactly what `harness-reviewer`'s stress test flagged as the wrong shape. It also does not
   solve the actual problem (naming drift + an unreached boundary), since a brief nobody dispatches
   is not read by anyone either.

## Decision outcome

Chosen: **Option 1**. "Orchestrator" becomes the one term for this actor across new writing (existing
occurrences of the other four spellings are not renamed by this ADR — see Consequences). It is explicitly
**not** an `agents/*.md` persona: it is not dispatchable, it is the dispatcher, and no `Task` invocation
ever targets it.

**Duties, as already performed and now named together:**
- Dispatches every persona; no persona talks to another persona directly (`README.md:193`).
- Commits and pushes on the loop's behalf.
- Applies the `ready` label that makes an Issue executable, once both intake leads have closed its
  description (`agents/tech-lead.md`, `agents/product-lead.md`).
- Applies the ADR-0012 routing label (`product`/`content`/`loop`) that determines an Issue's review path.
- Decides, in the moment, whether a given review specialist needs dispatching at all — a real judgment
  call already exercised at least once, measured on `-io`#338: the copy-lens trigger fired and the lens
  was not dispatched at all (`docs/adr/0006-a-verdict-owed-to-another-persona-is-an-artifact.md:523`),
  with no owner sign-off and no gate on it today.

**Boundary — stated precisely, in two parts, because it is not one uniform thing:**

- **Mechanically enforced today, for exactly two acts:** merge and direct push to the trunk.
  `hooks/scripts/permission-guard.sh:118` documents that `agent_type` is left **empty** for the main
  agent (the orchestrator), and rules 7 (trunk push) and 7b (merge) fire against that empty value
  explicitly — asserted at `permission-guard.test.sh:143` (`"main agent (no agent_type) cannot merge"`)
  and again, added 2026-08-03 specifically to cover the orchestrator alongside `developer`, at
  `permission-guard.test.sh:221-228` (`"THE SAME THREE FOR THE MAIN AGENT"` — trunk push, merge,
  composition fall-through). This corrects a suspicion this ADR's own driving dispatch initially carried:
  the guard is **not** blind to the orchestrator for irreversible acts. `README.md:150`'s stated
  boundary — *"never merges · never decides the irreversible"* — is mechanically true for the merge half,
  by design, since 2026-08-03.
- **Not enforced, and not claimed to be:** everything below that floor. Two examples this record names
  rather than papers over:
  - **Label application.** `.claude/settings.json:51` (`Bash(gh issue edit:*)`) and `:54`
    (`Bash(gh label:*)`) are in the global `allow`, unscoped to `agent_type`, and
    `hooks/scripts/permission-guard.sh` has no rule matching either command — confirmed by grep, and
    `permission-guard.test.sh:336` records the gap itself with a caller-agnostic
    `check ALLOW "labelling an issue" "gh issue edit 173 --add-label product"` (using `check`, not
    `check_agent` — the test suite's own admission that this allow is not scoped to who calls it). Under
    ADR-0012, moving an Issue between `product`/`content`/`loop` changes which review path it takes and
    whether it reaches the gate at all; ADR-0012 itself already named ungated relabeling as an **open
    question**, not a settled one. This ADR does not close that question. It states plainly that the two
    duties it just listed as the orchestrator's — the `ready` label and the routing label — are, today,
    equally reachable by any actor, and choosing to list them as duties here without saying so would let
    this record read as more settled than the mechanism it describes. Recording the gap alongside the
    duty is the same discipline ADR-0008 established for a control claimed stronger than it is: the
    failure that matters is the one nobody notices, and a record is the place that notices get written
    down.
  - **The dispatch-omission judgment call.** Deciding not to dispatch a review specialist is a different
    failure shape than "decides the irreversible" — it is an **invisible omission**, and it is not a
    hypothetical one: ADR-0006's own measurement of `-io`#338 records exactly this — the copy-lens
    trigger fired and *"the trigger fires and it has NOT been dispatched"*
    (`docs/adr/0006-a-verdict-owed-to-another-persona-is-an-artifact.md:523`). `README.md:259` already
    names the consequence generally ("an undispatched lens fails silently and looks identical to a clean
    one"), but the existing one-line boundary (`README.md:150`) is scoped to deploy-class acts and does
    not cover it. This record names the dispatch-omission judgment as the boundary's blind spot
    explicitly, rather than folding it silently into "never decides the irreversible" as if that sentence
    already covered it — it does not, because an omission is not a decision on an irreversible act; it is
    the absence of an act nobody can see happened or didn't.

**Naming safety, verified rather than assumed:** `grep -n "invoking context\|main loop\|main session\|
main agent\|orchestrator" hooks/scripts/inventory-counts.test.sh` returns nothing — that suite asserts
none of the five terms as literal strings. `permission-guard.test.sh` uses "main agent" only inside
human-readable test *descriptions* (string literals passed to `check`/`check_agent` for output, not
matched against); its assertions key on the **empty `agent_type` value**, never on the term itself.
Converging new writing on "orchestrator" — already used in `ADR-0012:39` and in `README.md`'s diagram
prose — breaks no assertion in either suite checked. This was **not** checked exhaustively against every
`.md` file in the tree for a prose-scraping test; that residual is named, not certified closed.

## What this record does NOT decide (consequent work, named here, not done in this ADR)

Per this repo's own citation discipline (ADR-0011, ADR-0012): named precisely, left for a follow-up MR,
because this record's write access is `docs/adr/**` only.

1. **Add the orchestrator's duty list and boundary to `CLAUDE.md`, not only `README.md`'s diagram.**
   `README.md:150` is where a human reads the definition; `CLAUDE.md` is where the orchestrator itself
   reads it, every session. Until this lands, the definition this ADR states is reachable by a human
   reviewing the repo and **not** reachable by the actor it describes in a fresh session — the same gap
   ADR-0010/0011 priced for persona preloads, here applied to the one actor that has no preload mechanism
   at all and depends entirely on CLAUDE.md.
2. **Close, or explicitly re-affirm as an accepted-but-unclosed cost, the `gh issue edit` / `gh label`
   scoping gap.** This record names the gap; it does not decide whether it is worth closing. That is a
   which-layer-carries-this-control question (ADR-0008), not a naming one, and belongs in its own record
   once someone picks it up — most plausibly `tech-lead` at a future intake, or `harness-reviewer` if it
   is scoped as a harness change.
3. **Add "(via orchestrator)" to the `MR --> QA` edge label in `README.md:177`.** The diagram's
   no-peer-talk invariant is already stated in prose (`README.md:193`) and the diagram admits drawing it
   once for readability; this one edge reads as a direct developer→gate handoff even under that stated
   admission. A one-word fix, not a re-draw.

None of the three is done in this MR — they are named as the obligations this record creates, the same
way ADR-0004 and ADR-0005 book obligations onto later work rather than discharging them inline.

## Consequences

**Good**
- One term (`orchestrator`) is now the recorded name for an actor that had five, matching what `ADR-0012`
  and the diagram already leaned toward.
- The duties already being performed (labels, commit/push, the dispatch-omission judgment) are listed
  together for the first time, instead of being reconstructable only by grepping five files.
- The part of the boundary that is mechanically true (merge, trunk push) is stated with its evidence,
  correcting a suspicion that the guard might be blind to the orchestrator for irreversible acts — it is
  not, and has not been since 2026-08-03.
- The part of the boundary that is **not** enforced (label scoping) and the part that is a different
  failure shape entirely (dispatch omission) are named as such, rather than silently absorbed into the
  existing one-line sentence — avoiding the exact failure ADR-0008 exists to catch: a record asserting a
  control is stronger than it is.

**Bad / accepted costs**
- This ADR renames nothing in the existing tree — the four other spellings (`main agent`, `main loop`,
  `main session`, `invoking context`) remain live in `hooks/scripts/permission-guard.sh`,
  `permission-guard.test.sh`, `docs/dev-loop-design.md`, and several `agents/*.md` files. "Orchestrator"
  is the term for **new** writing; a sweep of the old terms is not scoped here and would be its own
  slice.
- The label-scoping gap (Consequences #2 above) is named, not closed. Anyone relying on this ADR to mean
  "the orchestrator is now the exclusive, gated actor for `ready`/routing labels" would be reading a
  claim this record explicitly does not make.
- The dispatch-omission blind spot has no gate proposed here either — naming it does not make it
  detectable. `README.md:259`'s own admission stands: an undispatched lens (or an undispatched-anything
  decision by the orchestrator) still looks identical to a clean run.
- The CLAUDE.md addition, without which this record's boundary is decorative to the very actor it
  describes, is deferred to a follow-up MR rather than landing with the definition itself — a real gap
  between "decided" and "reachable" that this record accepts rather than closes, consistent with the
  `docs/adr/**`-only write scope this ADR is authored under.
- The naming-safety check (above) was run against two test suites, not against the whole tree; a
  prose-scraping test elsewhere in the repo, if one is ever added, was not ruled out.

## Links
- [ADR-0002](./0002-agentic-dev-loop-architecture.md) — cited, not amended: the actor this record names
  is the one ADR-0002 calls "the main loop" (`ADR-0002:812` uses "main agent"); this record narrows
  nothing ADR-0002 decided, it converges the vocabulary ADR-0002 helped originate.
- [ADR-0006](./0006-a-verdict-owed-to-another-persona-is-an-artifact.md) — cited: its own measured
  evidence (`-io`#338, `:523`) is the real instance — not a hypothetical — of the orchestrator omitting a
  dispatch that this record's fifth duty and boundary discussion rely on.
- [ADR-0008](./0008-which-layer-carries-a-control.md) — cited: the discipline of stating what a layer
  actually enforces versus what it is assumed to enforce, applied here to the orchestrator's boundary.
- [ADR-0010](./0010-a-personas-startup-context-is-a-curated-preload.md) and
  [ADR-0011](./0011-a-skill-exists-to-be-assigned-to-a-profile.md) — cited: the "a definition that is not
  loaded is decorative" standard, applied here to CLAUDE.md/README.md rather than to a persona preload.
- [ADR-0012](./0012-issue-type-is-the-routing-axis-and-is-exclusive.md) — cited: already names the
  ungated-relabeling question as open, and already uses "orchestrator" in prose (`:39`); this record does
  not re-decide either point.
- `README.md:150,177,193,259` · `docs/adr/0006-a-verdict-owed-to-another-persona-is-an-artifact.md:523`
  · `hooks/scripts/permission-guard.sh:118` · `hooks/scripts/permission-guard.test.sh:143,221-228,336` ·
  `.claude/settings.json:51,54` · `hooks/scripts/inventory-counts.test.sh:1397` — the measurements this
  record is built on, each cited at the site it was verified.
- Driven by a `harness-reviewer` pre-implementation stress test (six scenarios; no Issue — filed and
  closed within tier 1 as a methodology-library decision).
