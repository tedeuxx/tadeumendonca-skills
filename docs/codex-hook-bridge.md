# The native Codex hook seam — what is measured, and what nothing yet carries

**Nothing in this document is enforcement, and no artifact it describes refuses anything.**
`scripts/codex-hook-probe.py` is an instrument. It measures the seam a preventive bridge would
have to sit on; it is not that bridge, and a green run of it protects nobody. Read every sentence
below as *this is what the runtime does*, never as *this is what the harness now stops*.

The measurements were taken on **`codex-cli 0.151.0-alpha.7.2`**, the executable inside the
desktop application bundle. Re-run the probe rather than inheriting any number here.

**The phases split in two, and the second half spends the operator's own tokens.** The offline
phases — `carrier`, `trust`, `routes` — cost nothing and are what a bare invocation runs. The turn
phases — `payload`, `block`, `identity`, `stdin`, `matcher` — each start a real model turn and are
refused without an explicit flag, which is not a courtesy: a probe that could start a paid turn by
default is one nobody can run to check the offline claims.

```sh
# offline only — the default, and free
python3 scripts/codex-hook-probe.py /Applications/ChatGPT.app/Contents/Resources/codex

# the five turn phases — sections 4 to 8 — one model turn each, on the operator's account
python3 scripts/codex-hook-probe.py /Applications/ChatGPT.app/Contents/Resources/codex \
  --phase turn --allow-model-turn
```

Every phase builds its own disposable `CODEX_HOME` in a new temporary directory.

~~The probe reads no credential, starts no model turn, and never writes to the invoking user's real
`~/.codex`.~~ **Two of those three are false since 2026-09-14, and the sentence is struck rather
than edited because it is what a reader used to decide it was safe to run.** The turn phases COPY
`~/.codex/auth.json` into the disposable home and DO start model turns, and they must: the owner
authorised exactly that on this Issue, because no read-only route reaches a hook. **The write half
is unchanged and is now asserted rather than promised.**

**That containment was a property of the design, checked by someone other than its author, and is
now a check the probe runs on itself.** The independent gate on slice A ran the vendor binary on the
owner's machine **six times** and checksummed `~/.codex/config.toml` before and after:
**byte-identical**. Slice B takes the same reading **inside the probe**, on every run, before and
after, **and fails on any difference — including on the error path**, where a half-finished phase is
likeliest to have left a write. It matters because the trust and block phases deliberately write a
`trusted_hash` — the one write here that would be dangerous outside a disposable home.

~~and nothing mechanical prevents it~~ — **struck: something does now**, for this file. **What it
does not prevent**: the check watches one path, so a write anywhere else under `~/.codex` — a
session rollout, a cache, `auth.json` — passes it, and **the credential is deliberately read from
the real home**. A phase that reaches for the ambient `CODEX_HOME` instead of its own remains the
failure this paragraph exists to make visible; it is now caught in the one place it would do the
most damage and nowhere else.

## 1 · The carrier seam — a `.codex-plugin` manifest replaces the Claude hook set

A plugin may ship a second manifest at `.codex-plugin/plugin.json`. Its `hooks` value selects which
registry the Codex loader reads. Measured over five fixtures that differ only in that manifest:

| fixture | `.codex-plugin/plugin.json` | registrations reported |
|---|---|---|
| `claude-only` | absent | the full Claude set |
| `codex-path` | `"hooks": "./codex-hooks.json"` | **only** the Codex set |
| `codex-missing-file` | `"hooks": "./absent.json"` | **zero** |
| `codex-invalid-type` | `"hooks": 37` | the full Claude set |
| `codex-no-hooks-key` | no `hooks` key | the full Claude set |

The probe expresses those counts relative to `hooks/hooks.json` rather than as literals, so the
table does not rot when this repository registers another hook. It also refuses to run if the two
fixture sizes ever coincide, because replacement and fallback would then be indistinguishable by
count — that guard was confirmed to trip by making them coincide on purpose.

**The hazard is row four, and it is the reason a carrier needs a gate rather than only a file.**
A malformed `hooks` value does not fail closed. It silently restores the exact registry the carrier
existed to replace, and nothing in the loader's output says a fallback occurred. A carrier shipped
with a typed-wrong `hooks` value would read as installed and behave as absent — this repository's
own named failure shape. Row three is the mirror: a path pointing at nothing registers nothing, also
silently.

## 2 · Trust — a hash in the user's own `config.toml`, and anything that can write it confers trust

Every registration carries a `currentHash`. A hook executes only when a matching `trusted_hash` is
recorded under `[hooks.state."<key>"]` in `config.toml`. Three states were observed:

| `trusted_hash` | `trustStatus` |
|---|---|
| absent | `untrusted` |
| equal to `currentHash` | `trusted` |
| present but different | `modified` |

The third is a distinct state, not a synonym for untrusted, and the probe asserts it — a check that
only compared against `trusted` would pass while measuring the presence of the key rather than the
match.

**No method is NAMED for trust — and trust is still not a human hold.** The server enumerates its
methods in the error it returns for an unknown one; across **93** methods none is a trust call. It
does not follow that activation is a human act, and the probe asserts the opposite because the
comfortable reading is the one a bridge design would lean on:

```
config/value/write  keyPath="hooks.state"  mergeStrategy="replace"
                    value={<registration key>: {trusted_hash: <currentHash>}}
→ {"status": "ok"}   and the registration reports `trusted` on the next hooks/list
```

**Trust is file state.** Anything that can write the user's `config.toml` can grant it — that
method, or an ordinary shell redirect, since a Codex agent's shell runs as the user. The probe's
trust phase fails if this ever stops working, so the claim cannot quietly go stale in the
permissive direction.

**What this does NOT establish, stated because the gap is the interesting part.** It was done over
the app-server surface, which is the *client's*, not the model's. Whether a model inside a turn can
reach `config/value/write`, and whether the runtime sandbox refuses a shell write to
`~/.codex/config.toml`, are both **unmeasured here**. The sandbox did refuse writes elsewhere, so
that question is live rather than rhetorical. What is settled is narrower and still load-bearing:
**a design may not treat hook trust as an authenticated human checkpoint**, because nothing in the
mechanism authenticates anybody.

```sh
# reproduces all four trust findings: the default, the match, the `modified` state,
# and the config/value/write grant. The 93-method enumeration is read separately, by
# asking the server for a method that cannot exist — its error names every one it has.
python3 scripts/codex-hook-probe.py <codex-executable> --phase trust
```

**This harness's own hooks are already discovered by Codex, and all of them are untrusted.** The
installed plugin cache exposes every registration in `hooks/hooks.json` with `enabled: true` and
`trustStatus: "untrusted"`. Discovery is not execution, and nothing here changes that. **Do not
close the gap by trusting the existing bundle**: those scripts are written against a different
harness's payloads and event semantics, and one of them posts unattended.

## 3 · Routes — only a MODEL tool call fires a hook; every client route is unobserved

**The rule, and it is sharper than the earlier `command/exec` finding it replaces: a
`PreToolUse` hook observes tool calls the MODEL makes inside a turn, and nothing else.** Four
client-driven routes were exercised against a `trusted` registration, every one of them
succeeding, and not one produced a hook invocation:

| route | outcome | hook invocations |
|---|---|---|
| `command/exec` | exit `0`, real stdout | **0** |
| `process/spawn` | process started, `process/exited` observed | **0** |
| `thread/shellCommand` | ran **inside a thread**, emitted `turn/started` … `turn/completed`, created its file | **0** |
| a model tool call (`turn/start`) | created its file | **1** |

**The third row is the one worth reading twice.** `thread/shellCommand` is wrapped in the
runtime's own turn notifications, so a design that keyed on *"is a turn running"* would
conclude it is covered. It is not, and the surrounding `turn/started` is exactly what makes
that mistake available.

The positive control is the fourth row: the same counter, the same session shape, reaching
`1`. A zero here is therefore an unobserved route rather than a counter that cannot move.

**The consequence for a bridge.** Anything that reaches the shell through the client surface —
an IDE's own terminal, a host feature, any caller of the app-server — passes no hook. A Codex
carrier can cover the model, and only the model. Say that in those words wherever coverage is
claimed; *"the shell is guarded"* is false on this runtime.

## 4 · The `PreToolUse` payload — Claude-shaped in its load-bearing fields

Captured from a real turn. A parent-thread shell call carries exactly ten keys:

```json
{
  "session_id": "01a0a018-67fc-7d01-96c0-77bbaf21346b",
  "turn_id": "01a0a018-6811-7be0-a730-d9a8ded54d7e",
  "transcript_path": "…/sessions/2026/09/14/rollout-….jsonl",
  "cwd": "…/payload-project",
  "hook_event_name": "PreToolUse",
  "model": "gpt-5.6-sol",
  "permission_mode": "default",
  "tool_name": "Bash",
  "tool_input": { "command": "touch …/PAYLOAD_MARKER" },
  "tool_use_id": "exec-13c51cab-7ff7-4a65-9b82-5cc44afac955"
}
```

**`hook_event_name`, `tool_name`, `tool_input.command`, `cwd`, `session_id`,
`transcript_path` and `tool_use_id` are the Claude spellings**, so the shell half of an
existing guard needs no field translation. **That is a measured coincidence on one vendor
build and it is not a contract.** Section 8's rule stands: nothing here may be filled in by
analogy, and the probe re-derives the whole key set on every run rather than checking the
fields it happens to use.

**Three keys are Codex's own**: `turn_id`, `model`, `permission_mode`. `permission_mode` read
`default` on a turn started with `permissions: ":workspace"`, so **it is not a readback of the
requested profile** and nothing should branch on it until that is measured.

**`hook_event_name` is `PreToolUse` in the payload and `preToolUse` on the runtime's own
`hook/started` / `hook/completed` notifications.** Three spellings of one event now exist —
that pair plus the `pre_tool_use` trust key — and section 6 already records what the third one
costs.

**The routes, by `tool_name`.** The shell route is `Bash`. A file edit is `apply_patch`, with
the patch envelope in `tool_input.command`:

```
*** Begin Patch
*** Add File: EDITED.txt
+hello
*** End Patch
```

so **file edits are observable**, under a different name and a different payload grammar.
Delegation carries two more: `collaborationspawn_agent` and `collaborationwait_agent`.

## 5 · A decision BLOCKS — and the rewritten bytes that emit it DO execute

**One turn answers both questions, and it is deliberately one turn.** A trusted recorder was
rewritten in place into a blocker — **the config untouched, no re-trust, only the script's
bytes changed** — and the turn was run again.

**The refusal vocabulary is Codex's own, not Claude's.** A hook writes to stdout and exits
`0`:

```json
{"decision": "block", "reason": "codex-hook-probe refuses this act"}
```

There is no `hookSpecificOutput`, no `permissionDecision` and no exit-code-2 channel in what
was measured. The runtime's own error string for the degenerate case —
`hook returned decision:block without a non-empty reason` — is why `reason` is not optional,
and the probe asserts the reason reaches the runtime rather than only that the act stopped.

**What happened:**

| observation | value |
|---|---|
| `currentHash` after the rewrite | **unchanged** |
| `trustStatus` after the rewrite | **`trusted`** |
| payloads written by the rewritten script | **1** — the new bytes ran |
| `hook/completed` `status` | **`blocked`** |
| `hook/completed` `entries` | `[{"kind": "feedback", "text": "codex-hook-probe refuses this act"}]` |
| the fixture marker the command would have created | **absent** |

**So the `currentHash` exploit is confirmed end to end, and it is no longer a shape.** Slice
A established that trust survives a script rewrite; this establishes that **the rewritten
bytes then run with full authority to refuse or permit**. Combined with section 2 — anything
that can write the user's `config.toml` confers trust in the first place — the honest summary
is that **Codex hook trust binds a path, never content, and authenticates nobody.**

**The one favourable half, stated so the risk is not read as symmetric.** The same property
is what makes a bridge *updatable*: a carrier whose adapter is fixed under an update does not
need re-trusting. **That is convenience bought with the integrity of the checkpoint**, and a
design may not take the convenience while describing the checkpoint as a control.

**A behavioural note that is not enforcement.** After the refusal the model replied `DONE`.
The feedback reached the runtime; the act did not happen; the transcript nevertheless claims
success. **A bridge's refusals are not self-reporting, so nothing downstream may treat a
model's own account of a turn as evidence that a control did or did not fire.**

## 6 · Caller identity — present for a native child, ABSENT for the parent, and not an authority

**The finding in one line: `agent_type` exists, it is the registered role name, and the
parent's payload does not carry the key at all.** Measured by delegating one shell command to
a role registered as `[agents.probe_child]`. Four payloads, one turn:

| # | `tool_name` | `agent_type` | `agent_id` |
|---|---|---|---|
| 1 | `collaborationspawn_agent` | **key absent** | absent |
| 2 | `collaborationwait_agent` | **key absent** | absent |
| 3 | `Bash` (the child's act) | **`probe_child`** | present |

**ABSENT is not EMPTY, and an adapter that conflates them inverts this repository's own
floor.** A translation that defaults a missing key to `""` hands the Codex parent thread the
orchestrator's exemptions by accident — the Issue names this hazard, and this is the
measurement that makes it concrete rather than anticipated.

~~`permission-guard.sh` reads an *empty* `agent_type` as the orchestrator and grants it the
orchestrator's position in rules 7 and 7b.~~ **Struck: the ruling is right and the evidence was
INVERTED, in the permissive direction.** In 7 and 7b an empty value is what **denies** — it is
the *orchestrator* those two rules exist to refuse. The exemptions live in **5c/5d** (opening
work) and **5e** (posting to a public surface), and an adapter author who checked the cited
rules would have found them denying and concluded the hazard was theoretical. **It is larger
than the struck sentence said, not smaller**, because the two acts actually exempted are
*opening work* and *publishing*.

Measured against the live guard — four acts, four caller values, the verdict read off the
hook's own JSON:

| act | rule | `""` | `agents-lead` | `plugin:agents-lead` | `plugin:developer` |
|---|---|---|---|---|---|
| `gh pr merge 999999 --merge --repo …` | 7b | **deny** | deny | deny | deny |
| `git push origin main` | 7 | **deny** | deny | deny | deny |
| `gh issue create --repo … --title x --body-file /dev/null` | 5c/5d | **abstains** | deny | deny | **abstains** |
| `gh issue comment 999999 --repo … --body-file /dev/null` | 5e | **abstains** | deny | **abstains** | abstains |

```sh
# each payload is {"hook_event_name":"PreToolUse","tool_name":"Bash",
#                  "tool_input":{"command":<act>},"agent_type":<caller>,"cwd":<cwd>}
# piped to: bash hooks/scripts/permission-guard.sh
```

Every act names a nonexistent pull request or Issue, so nothing executed. **The two right-hand
columns are the calibration**: `plugin:developer` abstaining on 5d and `plugin:agents-lead`
abstaining on 5e show these rules are caller-keyed rather than uniformly denying, so the
`""` column is a real exemption and not a hook that abstains on everything.

**One detail an adapter would trip on.** The bare spelling `agents-lead` is **denied** by 5e
while `plugin:agents-lead` abstains, because the allowlist matches the namespaced form. So a
synthesised identity fails on its spelling as well as on its authority — one more reason the
answer is *do not synthesise one*.

**And identity here is a SELECTION, not an authority.** Payload 1 shows why: the parent's own
`tool_input` carries `{"agent_type": "probe_child", "task_name": …}`. **The parent names the
role.** Whatever roles a workspace registers, a model that can call the spawn tool can request
any of them, so `agent_type` at the decision point authenticates *which role config was
selected* and never *that the selector was entitled to select it*.

**The operative rule for slice C, unchanged by this measurement having found a field:**

> A caller-dependent exemption may not be bound to `agent_type`. It is a routing signal and
> never a credential, and the direction of its error is the wrong one — the value a bridge
> would most want to trust (`quality-assurance`, say) is exactly the one a model would name to
> obtain the exemption.

**What that leaves available, and it is not nothing.** The ABSENCE of the key is not
model-chosen — a parent cannot make itself a child. So *"deny everything caller-dependent to
every caller"* is implementable, and *"recognise that this is a child"* is implementable;
*"recognise WHICH child"* is not, in any sense a floor may rely on.

**Bound this to what was exercised.** One role, registered by the operator, one delegation
depth. Whether a child can itself spawn a grandchild, and what `agent_type` reads there, was
not measured.

## 7 · `write_stdin` — intercepting the command does NOT cover what is fed to it afterwards

**This is the sharpest route gap, and AC3 asks for it by name.** The model was asked to open a
persistent interactive session and then, as a separate call, send input into it:

| observation | value |
|---|---|
| `PreToolUse` payloads | **1** |
| the observed `tool_input.command` | **`"bash"`** |
| `item/completed` types for the whole turn | `userMessage`, `agentMessage` — **no `commandExecution` at all** |
| the file the later input creates | **present** |

**The act happened and no layer named it.** Not the hook, and not the runtime's own item
stream. The only thing a guard saw was the four-character string `bash`, which carries no
information whatever about what the session would go on to run.

The positive control is inside the same run: the startup **did** fire, so the counter can
reach a non-zero value, and the file's existence proves the second delivery really occurred.
The earlier turn where the model ran `touch` as an ordinary command is the contrasting
control — there, one payload named the command in full.

**The consequence is structural and a bridge cannot engineer around it at this layer.** A
semantic floor over command strings is defeated by opening a bare interpreter and feeding it
lines. The only enforceable point is the startup command, so the choices are:

- **refuse interactive session startup outright** — a real control with a real cost, and the
  cost is that ordinary interactive work stops; or
- **state the gap** — the floor covers commands issued as tool calls and does not cover input
  delivered into a running session.

**What must not happen is the third option:** shipping the command-string floor and describing
it as covering the shell. Slice C owes whichever of the two it picks, in the carrier's own
words, and this section is the evidence either choice is made against.

## 8 · The matcher is compared against `tool_name`, and a wrong spelling fails SILENTLY

Three registrations differing only in `matcher`, one turn exercising a shell call and a file
edit:

| `matcher` | invocations | `tool_name`s observed |
|---|---|---|
| `"shell"` | **0** | — |
| `"Bash"` | 1 | `Bash` |
| absent | 2 | `apply_patch`, `Bash` |

**`"shell"` matches nothing**, and the registration is reported by `hooks/list` as present,
enabled and trusted while never firing. That is this repository's own named failure shape — a
control that reads as installed and behaves as absent — reachable through a single misspelled
string.

**It was live in this repository.** `CODEX_HOOKS_FIXTURE` in `scripts/codex-hook-probe.py`
carried `"matcher": "shell"` from slice A until this measurement. It is a probe fixture and
shipped no enforcement, so nothing was unguarded; what it would have cost is a carrier design
copied from a fixture that could not fire. It now reads `"Bash"`, and the offline suite pins
it to the measured `tool_name` rather than to a literal, so the two cannot drift apart.

**An absent matcher is the safe default** and is what an adapter should ship: it observes every
route, and the adapter dispatches on `tool_name` itself, where a wrong value is a visible
branch rather than a silent non-registration.

**Not measured: whether `matcher` accepts a regex or an alternation.** The runtime's config
struct names `regex` in a neighbouring context, which is a reading and not a measurement. Do
not write `"Bash|apply_patch"` on the strength of it.

## 9 · The config schema — twelve PascalCase events, and a spelling that fails silently

`config/read` reports the accepted `HooksToml` shape. The event vocabulary is:

```
Interrupt · PermissionRequest · PostCompact · PostToolUse · PreCompact · PreToolUse
SessionEnd · SessionStart · Stop · SubagentStart · SubagentStop · UserPromptSubmit
```

Twelve, a superset of the six this repository registers. The offline suite asserts that every event
in `hooks/hooks.json` appears in that list, so an event this harness uses that Codex cannot express
would redden rather than be discovered later.

**The spelling trap, recorded because it cost two probe rounds.** Trust keys normalise the event to
snake_case (`config.toml:pre_tool_use:0:0`). That is the key form, **not** the config form. A
config written with `[[hooks.pre_tool_use]]` registers **zero** hooks and prints **nothing** to
stderr — it is accepted and ignored. Anyone reading the trust keys and inferring the config schema
from them writes a file that looks right, parses, and does nothing.

## 10 · What is NOT measured, and why each one blocks something

| unmeasured | why it could not be taken here | what it blocks |
|---|---|---|
| the shell CLI `0.153.4` | not present on this machine's `PATH`; only the desktop binary resolved | any "both binaries" claim |
| whether `matcher` accepts a regex or alternation | one turn per hypothesis, and an absent matcher makes it unnecessary | a multi-route matcher spelling |
| whether `permission_mode` ever reads anything but `default` | it read `default` under `:workspace`, so the field's domain is unknown | any branch on the permission mode |
| whether a model can reach `config/value/write`, or write `~/.codex/config.toml` through its shell | the app-server surface is the client's, not the model's | whether a model can grant its own hook trust |
| grandchild delegation, and `agent_type` at depth 2 | one role, one depth exercised | any claim about nested caller identity |
| `PostToolUse`, `SessionStart`, `SubagentStart` payloads | only `PreToolUse` was exercised | translating the observer half of this harness |
| whether a `PermissionRequest` hook can ASK rather than block | the vocabulary measured has one refusal verb | a prompt-shaped control on Codex |

### Discharged since slice A

~~the `PreToolUse` payload shape · whether a hook decision **blocks** · caller identity at the
decision point · later `write_stdin` / PTY input · whether `currentHash` covers the SCRIPT
BYTES~~ — **all five measured 2026-09-14 and recorded in sections 4 to 7.** The rows are
struck rather than deleted because slice A published them as the reason no adapter could be
written, and a reader arriving at that argument should find what discharged it rather than an
absence.

**Nothing above may be filled in by analogy with the Claude payloads.** The event vocabulary
is a superset with different names, the config spelling diverges from the key spelling, the
refusal verb is `block` rather than `deny`, and one event now has three spellings — so the two
harnesses have been measured disagreeing on exactly the kind of detail an analogy would paper
over. That section 4 then found the field names matching is **not** a licence to stop
measuring; it is one more dated observation of a vendor surface.

## 11 · What holds each statement in this document

**Nothing mechanical holds the prose**, and the split between what CI can hold and what it
cannot moved with this slice rather than staying where slice A left it.

`scripts/codex-hook-probe.test.py` runs in CI and gates the **instrument**: the expectation
table's discriminating power, fixture construction, the recorded event vocabulary, the
offline/turn phase partition, the pinned payload and identity shapes, the refusal vocabulary,
and that the hook builder emits a parseable decision on stdout with exit `0`. **It never starts
a Codex process**, so a green from it is not evidence about the runtime — it is evidence that
the thing which measures the runtime is well formed and capable of failing. Five source
mutations were confirmed to redden it and to re-green on restoration.

The runtime claims in sections 1 to 8 are held by **re-running the probe on a machine that has
the binary**, and the turn phases additionally require `--allow-model-turn` because they spend
the operator's own tokens. They are dated observations of a vendor surface, not invariants.

**Containment is now asserted rather than promised.** Every run records the SHA-256 of the
invoking user's `~/.codex/config.toml` before and after and **fails on any difference** — on
the error path too, where a half-finished phase is most likely to have left a write. Slice A
said in this document that a phase reaching the ambient home was the failure it existed to
surface and that *"nothing mechanical prevents it"*; that second clause is now false for this
file, and it remains true of anything a later phase does outside it.

**What the containment check still cannot see.** It watches one file. A phase that wrote
anywhere else under `~/.codex` — a session rollout, a cache, `auth.json` — passes it. The
credential itself is **read** from the real home by every turn phase, which is a deliberate
exception stated in the probe's own docstring and struck through the sentence that used to
deny it.

**The copy is removed, and that is a repair rather than a property it always had.** The turn
phases write a credential copy into each disposable home, and the first delivery of this slice
left them there — **15** across the scratch rounds and the instrument's own runs, found by
`find <tmp> -maxdepth 4 -name auth.json -path '*codex*'`. Mode `0600` inside a `0700` per-user
root, so the exposure is low and no marginal privilege is gained; it is still a credential copy
accumulating in a directory nobody sweeps. **Every copy the probe makes is now removed at the
end of the run, on the failing path too**, the made/removed counts are reported, and a copy
that cannot be removed **fails the run** rather than being noted. The 15 were deleted; the same
`find` returns **0**, against a selector that had just returned 15, so the zero is a real zero.

**The fixture trees are still left behind on purpose** — they are the artifacts an operator
inspects. A credential copy is not one of them, which is the whole of the distinction.
