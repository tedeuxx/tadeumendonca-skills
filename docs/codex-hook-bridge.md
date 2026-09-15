# The native Codex hook seam — what is measured, and what nothing yet carries

**Nothing in this document is enforcement, and no artifact it describes refuses anything.**
`scripts/codex-hook-probe.py` is an instrument. It measures the seam a preventive bridge would
have to sit on; it is not that bridge, and a green run of it protects nobody. Read every sentence
below as *this is what the runtime does*, never as *this is what the harness now stops*.

The measurements were taken on **`codex-cli 0.151.0-alpha.7.2`**, the executable inside the
desktop application bundle. Re-run the probe rather than inheriting any number here.

**Section 13 is the exception and it is a THIRD build.** The owner's native run of 2026-09-15 was
**`codex-cli 0.154.0-alpha.6.2`**, running as the VS Code extension's app-server — a different
version, a different bundle and a different host process from everything above. Read its findings
as evidence about a runtime no other section exercised, never as confirmation of one.

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

## 12 · The adapter — what slice C ships, and the one decision it does not take

**`scripts/codex-hook-adapter.py` is a TRANSLATOR, not a second floor.**
`hooks/scripts/permission-guard.sh` remains the only authored policy in this repository; the
adapter reads a native Codex payload, maps the caller, runs that guard, and translates its
verdict into Codex's own refusal verb. There is no rule in it. A rule there would be a second
floor drifting from the first with nothing watching.

The carrier is two files: `.codex-plugin/plugin.json` (the manifest measured in section 1 to
replace the Claude registry) and `codex-hooks.json` (one `PreToolUse` registration, **no
matcher**, per section 8's finding that `shell` matches nothing and an absent matcher observes
every route).

**Shipping it changes nothing until the operator trusts it.** Section 2's states are the whole
mechanism: a registration executes only when a matching `trusted_hash` sits in the invoking
user's own `config.toml`, and this repository's registrations are all `untrusted` today. So this
slice makes a floor *available* on Codex; it does not turn one on, and no sentence anywhere may
say it did.

### The coverage sentence, and it is the one to copy rather than paraphrase

> **The floor covers the MODEL's tool calls. It does not cover the client surface, and it does
> not cover input delivered into a running session.**

Both halves are measured. `command/exec`, `process/spawn` and `thread/shellCommand` fired
**zero** hooks against a trusted registration, all three succeeding (section 3); `write_stdin`
was observed once, carrying the four characters `bash`, with the later input invisible to the
hook layer *and* to the runtime's own item stream (section 7). *"The shell is guarded"* is false
on this runtime and must not be written.

### What no Codex caller gets, stated as an operational restriction rather than buried

**No caller-dependent exemption is available on Codex, to anybody.** Opening work and posting to
a public surface are refused to every Codex caller, including one whose `agent_type` reads
`quality-assurance`. `agent_type` is a **selection**, not a credential — section 6 — so binding
an exemption to it would hand the exemption to whoever asked for the role.

The mapping that produces this is the one an adapter author gets backwards, so it is written out:

| what the payload carries | what the adapter sends | why |
|---|---|---|
| a child's role, e.g. `probe_child` | **the same value, verbatim and bare** | the guard's allowlists match the namespaced `<plugin>:<persona>` form, so a bare name fails **closed** |
| **no `agent_type` key** (the parent) | **`codex-unidentified`** | a non-empty sentinel with no colon, denied by every caller-keyed rule's catch-all |
| `""`, `null`, or a non-string | **`codex-unidentified`** | ABSENT is not EMPTY |

**The defensive-looking move is the dangerous one, and this is the measurement that says so.**
Re-derived by `scripts/codex-hook-adapter.test.py` on every run rather than quoted from here:

| caller value sent to the guard | opening work (5c/5d) | posting (5e) |
|---|---|---|
| key absent | **abstains** | **abstains** |
| `""` | **abstains** | **abstains** |
| `codex-unidentified` | deny | deny |
| `agents-lead` (bare) | deny | deny |
| `tadeumendonca-skills:agents-lead` | deny | **abstains** |

The last row is the calibration: these rules are caller-keyed rather than uniformly denying, so
the two abstentions at the top are a real exemption and not a guard that abstains on everything.

### The process working directory is load-bearing and the payload's `cwd` field is not

The guard resolves a bare `git push`'s branch with `git -C "." symbolic-ref`, so **its verdict
follows the process working directory and ignores the payload's `cwd` entirely.** Measured on two
fixture repositories, one on `main` and one on a feature branch:

```
process cwd=main     payload cwd=feature  ->  deny
process cwd=feature  payload cwd=main     ->  abstain
process cwd=main     payload cwd=main     ->  deny      (control)
process cwd=feature  payload cwd=feature  ->  abstain   (control)
```

Both controls behaved, so the two mismatched rows are the finding. The adapter therefore
**chdirs to the payload's `cwd`** before invoking the guard. Without that the trunk rule reads
whichever tree the host happened to launch the hook from, and the error runs in **both**
directions — a genuine trunk push abstaining is the expensive one. The suite asserts the
adapter's behaviour *and* the guard's cwd-dependence, so the chdir cannot become decoration.

### Failure posture, and why `--selfcheck` exists

Every degradation **abstains** and writes one line to stderr saying the act was **NOT judged**:
an unparseable payload, a missing guard, a missing `bash`, a timeout, an unreadable verdict. That
matches the guard's own general contract. Its one fail-closed exception — rule 7c, the merge
verdict lookup — is preserved by construction, because the adapter forwards a verdict rather than
interpreting a rule.

**A floor that is absent is indistinguishable from a floor that is holding**, and that is not
rhetorical here. Measured: with a broken `jq` on `PATH`, `terraform apply` returns exit `0` and
**empty stdout** — the whole floor fails open, silently. With a real `jq` the same payload returns
a `deny`. So:

```sh
python3 scripts/codex-hook-adapter.py --selfcheck
```

reports the blocking conditions and prints, every time, the four things a green does **not** mean.
It is a report and never a control: it changes no trust state and writes nothing.

### <a id="branch-point"></a>THE DECISION THIS SLICE DOES NOT TAKE — `REFUSE_INTERACTIVE_SESSION_STARTUP`

Section 7's gap has two defensible answers and the owner holds the choice. **Both are
implemented.** The constant at the top of the adapter selects one; the suite exercises both, so
the unselected branch cannot rot.

**Shipped: `False` — ship the bridge and state the gap.**

| | `False` — ship and state the gap *(shipped)* | `True` — refuse interactive session startup |
|---|---|---|
| **which way do errors run** | **toward letting something through.** A model that wants an unjudged shell opens `bash` and feeds it lines | **toward refusing something real.** An enumeration over interpreter spellings, which is the shape a deleted hook here already failed at |
| **who SEES an error** | **nobody, by construction.** An unjudged act leaves no artifact — section 7 measured the runtime's own item stream carrying no `commandExecution` at all | **the operator, immediately.** A refusal is a visible `block` with a reason naming the alternative (`bash -c '<payload>'`) |
| **what legitimate work stops** | none | opening a REPL to try something, `psql` against a local database, `sqlite3`, an interactive `python3` — the ordinary exploratory loop |
| **what a reader of the bridge learns** | the coverage sentence above, **if they read it.** The suite forces it to exist in this document; nothing forces anyone to reach it | the limit announces itself at the moment it binds, to the person it binds |
| **reversible?** | **yes, one constant.** Both branches are tested, so flipping it is an edit and a re-run rather than a design | **yes, the same constant.** The cost of having chosen wrongly is friction, not damage |

**The recommendation, and the reason is the direction of the error rather than the size of the
gap.** Ship `False`. Not because the gap is small — it is total on that route — but because
`True` is a **preventive control whose false positives are visible and whose true positives are
not**, which is the inverted form of this repository's own rule: it would refuse a great deal of
legitimate interactive work in exchange for stopping a bypass that a model reaches just as easily
by writing a script file and running it, or by `bash -c` with a payload the floor already reads.
**`True` does not close the class; it closes one spelling of it**, and the enumeration in
`INTERACTIVE_PROGRAMS` is the same search-over-spellings that `action-pendency-guard.sh` was
deleted for.

**What `False` costs, said plainly rather than absorbed:** the floor's coverage claim is
genuinely narrower than *"the shell"*, the narrowing is carried only by prose, and **nothing
observes an unjudged act.** If the owner's read is that an unobservable gap is worse than visible
friction, `True` is the honest answer and flipping the constant is the whole change.

**The third option is refused and is not a middle path:** shipping the command-string floor and
describing it as shell coverage. That is the failure this repository names most often — a control
that reads as installed and behaves as absent — and no amount of qualifying prose converts it
into a position.

### What this slice does NOT settle, and what it would take

- ~~**Whether a plugin-carrier hook command resolves a RELATIVE path, and against what.** The
  carrier registers `python3 scripts/codex-hook-adapter.py`, which is the spelling slice A's
  fixture used and `plugin/read` reported as a registration — but slice A never ran it, and every
  turn phase registered an **absolute** path. So *the manifest is read* is measured and *the
  command is found* is not. **This blocks any claim the floor is active on Codex.** One trusted
  turn against a carrier-registered relative command settles it; this slice is not authorised for
  a model turn.~~ **SETTLED 2026-09-15 by the owner's native run, and it resolved against the
  SESSION's working directory.** The hook was found, trusted and executed; `git push origin main`
  was blocked by `PreToolUse` upstream of Git, the remote and branch protection. **Struck rather
  than deleted because it is the sentence that told a reader the floor's activity was unknown, and
  what replaced it is narrower than *active*:** see section 13. The turn it asked for happened.
- **Whether the host imposes a hook timeout, and what it is.** `codex-hooks.json` declares none —
  an unrecognised key risks a parse that this repository has already measured failing silently, so
  nothing speculative is written into it. The adapter's own 4-second bound is what exists, chosen
  under the Claude registration's 5.
- **Whether a model can grant its own hook trust** (section 2's open question) — which decides
  whether the checkpoint is weak or absent. Not settled here and not this slice's to settle.
- **Whether `matcher` accepts a regex** (section 8) — the adapter needs no answer, because it
  ships no matcher.

### What holds this section

`scripts/codex-hook-adapter.test.py`, in CI. It **never starts a Codex process**, so a green is
not evidence about the runtime. What it asserts: the refusal vocabulary is Codex's and not
Claude's; the identity table above, re-derived against the **live** guard on every run rather than
read from this page; the cwd dependence and the adapter's chdir; every degradation abstaining with
a trace; both settings of the branch point; and the carrier being the shape measured to *replace*
rather than either shape measured to fail **silently** (a wrong `hooks` type falls back to the
Claude bundle, a missing path registers zero).

**What no gate here can see:** whether Codex ever invokes the command, whether the registration is
trusted, and whether any of this document's prose is true.

## 13 · The carrier's command is CWD-BOUND — the floor is active in ONE directory, and fails closed elsewhere

**The wording, and it must not drift in either direction: the floor is ACTIVE for a session rooted
in this checkout.** Not *available* — that understates a measured execution. Not a bare *active* —
that overstates its scope to every session, which is exactly what is false.

### What the owner's native run established, and it is the affirmative half

Measured 2026-09-15 on `codex-cli 0.154.0-alpha.6.2` (the VS Code extension's app-server). The hook
declared by `codex-hooks.json` was **found**, **trusted** and **executed**.

- **Control** — an ordinary permitted tool call: `PreToolUse` fired, produced no decision, the call
  succeeded.
- **Block** — `git push origin main`: refused by `PreToolUse` **before** reaching Git, the remote,
  authentication or server-side branch protection.

**That ordering is what makes the refusal attributable.** A hook that never fires and a floor that
permits everything are indistinguishable from inside a successful command; and a refusal could
otherwise have come from a missing remote or a protected branch. Neither reading survives: the
permitted call fired the hook and passed, and the denied call was stopped upstream of every
alternative explanation.

Trust was written by a `config/batchWrite` call with **no human prompt** — slice A's fixture
finding, now reproduced on a real install. **A bridge must not treat Codex hook trust as a human
checkpoint.** The owner removed the trust entry afterwards; `~/.codex/config.toml` is byte-identical
to its pre-run digest `d3d390731089c913042141cf9ec2e3c305fb4954cc3d890c44cdf756357d23bf`.

### The defect

`codex-hooks.json` registers `python3 scripts/codex-hook-adapter.py`. **That relative path resolves
against the SESSION's working directory, not against the plugin's installed root.**

- In this checkout it finds this checkout's adapter — **a structural coincidence, not a design.**
- In a directory without that file the hook **fails visibly and blocks the call.**

The plugin is installed once, globally, and enabled for every session. So a Codex session rooted in
`tadeumendonca-io` — which ships no `scripts/codex-hook-adapter.py` — has **every model tool call
blocked**.

**One resolution case remains unexercised and it is the sharp one.** The run covered *the file is
there* and *the file is absent*. It did **not** cover a **different** file at that same relative
path: any directory containing a `scripts/codex-hook-adapter.py` would have **its own copy**
executed as the permission floor. Named as unexercised, not claimed as a result.

### Codex offers NO way to reference a plugin's own installed root — measured, both directions

This is the question the repair turns on, and the answer is no. Four independent readings, each
with the command that produced it, taken against **the build the owner ran** rather than the one
the rest of this document measures.

**1 · The hook handler's own schema carries no path-base field of any kind.** Read out of the
shipped binary's serde field list:

```sh
strings -a ~/.vscode/extensions/openai.chatgpt-26.908.40401-darwin-arm64/bin/macos-aarch64/codex \
  | grep -aoE '.{110}internally tagged enum HookHandlerConfig.{40}' | head -1
# -> …typecommandcommandWindowstimeoutasyncstatusMessageadditionalContextLimitserverinputpromptagent
#    internally tagged enum HookHandlerConfigstatematcherhooksHookStateTomlenabledtru…
```

The complete field set is `type` · `command` · `commandWindows` · `timeout` · `async` ·
`statusMessage` · `additionalContextLimit` · `server` · `input` · `prompt` · `agent`. **No `cwd`,
no `root`, no `basePath`.**

**2 · Codex HAS the concept and spells it explicitly — on MCP servers, not on hooks.** This is the
calibration that makes reading 1 a finding rather than an absence of evidence: a schema that *does*
carry a plugin-root-relative idiom exists in the same binary, and every bundled plugin that ships
an MCP server uses it — **4 of 4, unanimously**:

```sh
cd ~/.codex/.tmp/bundled-marketplaces/openai-bundled/plugins && \
  for f in */.mcp.json; do echo "### $f"; cat "$f"; done
# -> all four declare  "command": "./bin/computer-use-client-launcher"  WITH  "cwd": "."
```

So the pairing `relative command + explicit cwd` is Codex's own supported idiom for *"resolve
against my package"*. **The hooks schema does not carry the second half of it.**

**3 · No plugin-root environment variable exists.** The selector ships with its calibration,
because a grep that matches nothing reads as *nothing to worry about*:

```sh
strings -a ~/.vscode/extensions/openai.chatgpt-26.908.40401-darwin-arm64/bin/macos-aarch64/codex \
  | grep -aoE 'CODEX_PLUGIN[A-Za-z_]*' | sort -u
# -> CODEX_PLUGIN_METRICS_OUTPUT…   (three variants, all the same token; a metrics sink, not a root)

# CALIBRATION — the same selector against a token known to be present:
strings -a ~/.vscode/extensions/openai.chatgpt-26.908.40401-darwin-arm64/bin/macos-aarch64/codex \
  | grep -aoE 'CODEX_HOME' | sort -u
# -> CODEX_HOME
```

**4 · There is no corpus of hook command spellings to copy, because no bundled plugin ships hooks
at all.** Stated so the silence is not read as agreement with anything:

```sh
cd ~/.codex/.tmp/bundled-marketplaces/openai-bundled/plugins && \
  jq -r 'select(.hooks != null) | input_filename' */.codex-plugin/plugin.json
# -> no output, exit 0 — ZERO of the 10 bundled plugins declare a `hooks` key
# CALIBRATION — the same selector on a key they DO declare, so the zero is a real zero:
jq -r 'select(.skills != null) | input_filename' */.codex-plugin/plugin.json | wc -l
# -> 8
# the denominator, so "zero" is read against a non-empty set:
ls -d */ | wc -l
# -> 10
```

**Bound these four exactly.** They are one machine, one build, and **control flow and data read out
of a shipped bundle rather than a hook watched resolving a path**. A vendor may add a field in the
next alpha and nothing here would say so. What they are *not* is an inference from the Claude
schema — section 10 already records these two harnesses disagreeing on exactly this kind of detail.

### Why a hardcoded absolute path is not the escape either

The installed root is **version-stamped**, so any absolute path rots on every release:

```sh
ls -d ~/.codex/plugins/cache/tadeumendonca/tadeumendonca-skills/*/
# -> …/tadeumendonca-skills/2.0.47/
```

**And the tree does arrive intact** — the adapter is present at that root, so the only thing
missing is a way to *name* it:

```sh
find ~/.codex/plugins/cache/tadeumendonca -name 'codex-hook-adapter.py'
# -> …/tadeumendonca-skills/2.0.47/scripts/codex-hook-adapter.py
```

That is worth stating plainly: **the defect is one unresolvable string, not a missing file.** Once
the adapter runs at all it locates everything else correctly, because it resolves the guard from
its own `__file__` (`REPO_ROOT = Path(__file__).resolve().parent.parent`) and not from the cwd.

### The decision: state the limitation, build no wrapper

**No shim, and this is the reason rather than a preference.** A wrapper that searched for the
adapter would convert a **visible, fail-closed** failure into a guess — and on reading 3's
unexercised case it would be a guess that could execute *a different repository's file as the
permission floor*. The fail-closed property is the best thing this bridge currently has, and it is
the direction this platform's failures usually run the other way.

**So the limitation is written where it binds, and accepted with its cost stated:**

| | |
|---|---|
| a session rooted in **this checkout** | the floor is **active** — measured |
| a session rooted **anywhere else** | **every model tool call is blocked**, visibly |
| the cost | the Codex bridge is not portable to a second repository, and `tadeumendonca-io` cannot run a Codex session at all while this plugin is enabled |
| what would remove it | a `cwd` field on the hook handler schema, or a plugin-root variable — **neither exists on `0.154.0-alpha.6.2`**, and both are the vendor's to add |

### Why this limitation is NOT written into `codex-hooks.json` itself

**JSON carries no comments, and an unrecognised sibling key is the one thing this document already
measured failing silently.** Section 1's row four: a carrier whose `hooks` value is typed wrong
does not fail closed, it restores the Claude bundle with nothing saying so. Adding a speculative
`_comment` key to the registry to hold a warning would be spending the exact risk this bridge was
built to avoid, to hold a sentence. **It is carried by `.codex-plugin/plugin.json`'s `description`
— which a reader meets first and which the loader already reads — by this section, and by
`--selfcheck`, which is the surface an operator actually runs.**

### What holds this section

**Nothing.** No gate can observe which directory a Codex session was started in, and none of the
four readings above is re-derived by CI — they are reads of a vendor bundle on one machine, and a
test asserting their output would be pinning another product's build. `--selfcheck` reports the
constraint; it cannot detect a violation of it, because by the time the adapter is running the
resolution already succeeded. **The failing case never reaches any code this repository ships.**
