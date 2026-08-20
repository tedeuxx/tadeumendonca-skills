# 0018. Permission entries have three states, and absent is not one of them

- **Capability:** permissions
- **Status:** accepted
- **Date:** 2026-08-13
- **Deciders:** owner (decision), harness-lead (record — bootstrapping note below)
- **Supersedes / superseded by:** —
- **Driven by:** #163

## Context & problem

The owner asked for AWS exception commands to be "always unitarily permitted" — read as: move a subset
of the AWS `deny` entries in `permission-guard`'s floor to some state that stops prompting, without
opening them to a blanket `allow`. The obvious spelling is to delete the `deny` entry and leave the
command **absent** from every list — no `allow`, no `deny`, nothing.

Measuring the request surfaced a larger question underneath it: this repo's permission floor already
has a spelling for "prompt, don't auto-decide" (`permissions.ask` in Claude Code's settings schema,
and a now-struck `ask()` helper in `permission-guard.sh`), and neither this repo nor any prior record
had stated whether "absent" is a legitimate fourth state alongside `allow`/`deny`/`ask`, or whether it
collapses into one of the other three by default. Without that vocabulary settled, every future request
shaped like this one — "let this specific case through without opening the whole class" — has no shared
language to be decided in.

## Decision drivers

- ADR-0004 already recorded, on unrelated evidence (`gh api` being unlisted rather than denied), that
  *"a control expressed as absence is not a control"* — this decision either confirms that principle
  generalizes or finds a reason it doesn't.
- A state that cannot survive an unreviewed `settings.local.json` overlay is not a control a public,
  portfolio-facing harness can rely on.
- Whatever is decided has to be checkable, not asserted — #163 ran the actual test rather than reasoning
  about the schema.

## Considered options

1. **Three real states — `deny` / `ask` / `allow` — and absent is not a fourth one; it resolves to
   whatever the nearest broader `allow` pattern says, silently.** *Trade-off:* nothing new to build; the
   cost is that "unitary" cannot be spelled as "remove the deny and stop there" — it has to land in one
   of the three real states or it isn't a decision at all, just an omission that reads like one.
2. **A fourth state, "absent," used deliberately for the unitary case** — rejected. Three properties
   `absent` lacks that `deny` has, all measured or reasoned in #163: it is erasable by a broader `allow`
   added anywhere, silently (this workspace already carries 15 such unreviewed entries in local
   overlays); a removed `deny` and an entry that never existed are indistinguishable in the file, so the
   decision leaves no record that it was made; and it does not survive `settings.local.json`, which
   accumulates by clicking and is never reviewed. *Why not:* all three are the same property from
   different angles — absence is not observable as a decision, so it cannot be audited as one.
3. **Migrate the unitary case into `permissions.ask`** — tested directly rather than assumed. #163's
   one-minute test (§6 of the Issue, executed 2026-08-13): move `Bash(aws cloudfront
   create-invalidation:*)` from `deny` to a `settings.local.json` `"ask"` entry in both the committed
   project file and the global user-scope file, then run the command as a live tool call. **Result: no
   permission prompt — the command executed directly**, reaching real AWS auth and failing only on an
   expired session token, meaning no permission layer intercepted the call at all. *Why not:* it does
   not work, in this Claude Code version, through this configuration surface. This is a measured
   negative, not a decision against the option on principle — it is falsified until re-measured against
   a newer version.

## Decision outcome

Chosen: **Option 1 — three real states, and absent is not one of them**, because it is the only option
still standing once Option 3 is measured false and Option 2 fails the same audit test ADR-0004 already
applied elsewhere. A permission entry is `deny` (never at any price), `ask` (not without me — currently
non-functional in this harness, pending re-measurement), or `allow` (pre-authorised). Anything else is
not a fourth state; it is the absence of a decision, and this repo does not treat that as one.

**Practical consequence for #163's original request**: "unitary" cannot be spelled by deleting a `deny`
entry and stopping. It has to become an actual `allow` (if the class is judged safe to pre-authorise
unconditionally) or stay `deny` (if it isn't) — there is no third resting place that also counts as a
decision.

## Consequences

**Good**
- Closes the exact gap ADR-0004 named on `gh api` and this Issue re-found independently on the AWS
  floor: an entry that quietly stops being denied is indistinguishable, in the file, from one that was
  never reviewed.
- Gives future permission requests a vocabulary to be decided in, rather than each one re-deriving
  whether "just remove the deny" is safe.
- The `ask()` falsification is now a citable, dated measurement rather than a live open question the
  next permission Issue would have to re-ask from scratch.

**Bad / accepted costs**
- `ask` is currently vocabulary with no working implementation in this harness — a real state exists in
  the model, but not in the tooling, until re-measured against a newer Claude Code version. Any decision
  that would have used `ask` is stuck choosing between `deny` and `allow` in the meantime.
- This does not resolve #163's remaining concrete action (removing the 35 duplicated AWS `deny` entries
  from the unversioned, self-protected global `~/.claude/settings.json`) — that is an owner-executed
  step with no PR, gate, or record, orthogonal to the vocabulary this ADR settles.

## Links
- #163 — the Issue that measured all three options and ratified the owner's decisions this ADR records.
- ADR-0004 — the earlier, narrower precedent (*"a control expressed as absence is not a control"*) this
  decision generalizes from one measured case to a stated principle.
- ADR-0008 — decides which *layer* carries a control; this ADR decides which *state* a permission entry
  can be in, and is orthogonal to it (0008 already carries four amendments on the layer question alone).

## Bootstrapping note

Per ADR-0017, a permission-floor state vocabulary is loop/harness machinery — `harness-lead`'s domain to
author, not `tech-lead`'s. It is recorded here directly, in the same session as #163's own measurement,
because no persona was dispatched (plugin disabled for this phase — see #165/#221 context). Flagged so a
future `harness-lead` review of this record knows why the byline reads this way.
