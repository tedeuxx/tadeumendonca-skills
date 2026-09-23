# The native Codex hook seam — what is measured, and what nothing yet carries

**Nothing in this document is enforcement, and no artifact it describes refuses anything.**
`scripts/codex-hook-probe.py` is an instrument. It measures the seam a preventive bridge would
have to sit on; it is not that bridge, and a green run of it protects nobody. Read every sentence
below as *this is what the runtime does*, never as *this is what the harness now stops*.

The measurements were taken on **`codex-cli 0.151.0-alpha.7.2`**, the executable inside the
desktop application bundle. Re-run the probe rather than inheriting any number here.

**Sections 13 and 14 are the exception and they are a THIRD build.** The owner's two native runs —
2026-09-15 and 2026-09-16 — were **`codex-cli 0.154.0-alpha.6.2`**, running as the VS Code
extension's app-server: a different version, a different bundle and a different host process from
everything above. Read their findings as evidence about a runtime no other section exercised,
never as confirmation of one.

**The version is published with the command that reads it**, because it was asserted on three
surfaces and verified on none until a third party ran it:

```sh
~/.vscode/extensions/openai.chatgpt-26.908.40401-darwin-arm64/bin/macos-aarch64/codex --version
# -> codex-cli 0.154.0-alpha.6.2
```

**One machine, one install, and the extension directory is version-stamped** — so this path rots
on the next extension update while the string it prints is what identifies the build. Re-run it
rather than trusting the number here.

**Read section 13's strike list before quoting anything about Codex activation from this page.**
The first run's findings were **written on this branch and withdrawn by the second before either
reached `main`**; what survives is discovery and promptless trust, and **no claim that the floor
fires on Codex survives at all.**

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
| ~~whether `permission_mode` ever reads anything but `default`~~ | **MEASURED 2026-09-21 on `0.151.0-alpha.7.2`, section 15.3: it reads `default` under `:workspace` AND under `:read-only`, while the parameter itself IS validated. The field is not a readback of the requested profile and nothing may branch on it.** Struck rather than deleted: this row is what told a reader the domain was open, and the answer is a negative one that a blank line would not carry | ~~any branch on the permission mode~~ — **nothing, and that IS the answer** |
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
  command is found* is not.~~

  **STRUCK 2026-09-22, and the two halves went false on different days.** *The question:* §15
  measured a relative command resolving against the session's cwd, and §16 measured the shipped
  registration producing **zero** adapter invocations for exactly that reason — so it was answered
  before this slice began. *The registration:* §17 repairs it, and the carrier now registers
  `python3 ${PLUGIN_ROOT}/scripts/codex-hook-adapter.py` — **so this clause was falsified by the
  very slice that is striking it.** Struck rather than edited because it is the sentence that told
  a reader the question was open, and it sits in the section titled *what is NOT settled*, which is
  the section a reader planning Codex work opens first.

  **This blocks any claim the floor is active on Codex.** That conclusion is **UNCHANGED** and is
  deliberately left outside the strike, because it is still true. What moved is its *reason*:
  §17.3 now carries it, for three reasons that have nothing to do with a relative path. **A wrong
  reason for a right answer is the harder of the two to notice**, which is why this sentence says
  so rather than quietly re-basing.

  ~~One trusted turn against a carrier-registered relative command settles it; this slice is not
  authorised for a model turn.~~

  **The REMEDY is struck 2026-09-16 as KNOWN-INSUFFICIENT,** ~~while the question above stands OPEN.~~
  **The question is CLOSED as of 2026-09-22 — see §17.** The remainder of this paragraph is kept
  as the record of two turns that did not settle it, which is still worth having.
  Two such turns have now been run and neither settled it: the first appeared to and was
  withdrawn, the second probed where this harness's two Codex layers disagree and found the floor
  not acting at all. **A third turn buys nothing, and a standing sentence saying otherwise sends
  the next reader to spend one.** What would settle it is in section 13 and is a **build** rather
  than a turn — the adapter recording its own invocations, so *"the hook did not fire"* stops
  being the same observation as *"the hook fired and abstained"*.

  ~~**SETTLED 2026-09-15 by the owner's native run, and it resolved against the SESSION's working
  directory.** The hook was found, trusted and executed; `git push origin main` was blocked by
  `PreToolUse` upstream of Git, the remote and branch protection.~~ **THAT DISCHARGE IS WITHDRAWN
  2026-09-16** ~~and the bullet above stands OPEN again.~~ **— the WITHDRAWAL stands; the REOPENING
  does not.** The bullet above is struck and the question is closed (§17). This clause was true from
  2026-09-16 and went false on 2026-09-21; it is struck rather than deleted because it is a **third**
  carrier of the same falsehood, and it was found only by running a selector keyed on *stands OPEN*
  beside the two keyed on the registration and on the word *relative* — **neither of which reaches
  this sentence.** A second native run found that the command
  the first one used to prove the hook — `git push origin main` — is forbidden by this
  repository's *other* Codex containment layer, so the refusal was never attributable; re-probed
  with a command the two layers disagree on, the floor did **not** act. **The strike is kept
  visible rather than deleted because it was this branch's own earlier head** — `a0d9fd46`, which
  never reached `main` — **and a reader of this merge request's history meets it there.** It is
  not kept because it was published; it was not. **Section 13 carries what survives; section 14
  carries why the first run could not have seen what it claimed to see.**
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

## 13 · What the two native runs established — and what the second one WITHDREW

**This section was rewritten on 2026-09-16 and it is not an edit of what stood here.** The version
written at this branch's earlier head asserted that the carrier's hook was *found, trusted and
executed*, that the floor was *active for a session rooted in this checkout*, and that a session
started elsewhere *fails closed*. **A second native run falsified all three.**

**They are struck below in place rather than deleted, and the reason is narrower than it first
read here.** These claims were authored on this branch and **never merged** — they reached neither
`main` nor any published plugin version:

```sh
git merge-base --is-ancestor a0d9fd46 origin/main   # -> exit 1, NOT an ancestor
git grep -c 'SETTLED 2026-09-15' origin/main -- docs/codex-hook-bridge.md   # -> no match, exit 1
git grep -c 'SETTLED 2026-09-15' v2.0.47   -- docs/codex-hook-bridge.md   # -> no match, exit 1
# CALIBRATION — the same selector at the head that carried them, so the two zeros are real:
git grep -c 'SETTLED 2026-09-15' a0d9fd46  -- docs/codex-hook-bridge.md   # -> 1
```

So the strike is kept for the reason that actually applies: **this merge request's own history
carries `a0d9fd46`, a reviewer walks it, and a claim that vanishes between two heads of one branch
is harder to audit than one struck in place.**

**Earlier drafts of THIS SECTION AND OF THIS DOCUMENT'S HEADER justified the strike by saying the
claims had *"shipped in a published plugin version"* and been *"published here"*. They had not,
and the error ran in the flattering direction** — inventing a publication makes the correction
look more consequential than it was, which is the exact bias the strike list below warns about two
screens down, pointed at the author instead of at the system. It is recorded here rather than
quietly fixed, because a page about withdrawn claims is the worst possible place to withdraw one
silently.

**And HOW the header's copy survived the first repair is worth more than the repair.** That sweep
searched for the **phrasings** already known to be wrong — `merged commit`, `published plugin
version`, `marketplace-published` — and the header used none of them. Swept for the **claim**
instead, every `publish` form in the file, it was the only survivor:

```sh
git grep -n -iE 'publish' -- docs/codex-hook-bridge.md
# CALIBRATION — an absent selector over the same object, so the set above is a real set:
git grep -n -iE 'zzznotpresent' -- docs/codex-hook-bridge.md   # -> no match, exit 1
```

**An enumeration of known-bad spellings is not a sweep for a claim**, and two independent readers
made that identical instrument error on this document one round apart. It is the same shape this
repository has recorded before at a different grain — a selector that was correct about the sample
its author had in mind and wrong about the class.

**Both runs are the owner's, on `codex-cli 0.154.0-alpha.6.2` running as the VS Code extension's
app-server** — a different version, bundle and host process from every other section of this
document. Read section 14 first if you only read one: it is why the first run could not have
observed what it reported, and it is the transferable part.

### What STANDS — reproduced on two separate days, by two different write endpoints

**1 · The carrier is DISCOVERED.** Codex reads `.codex-plugin/plugin.json` and resolves its
`hooks` value `./codex-hooks.json`; a `[hooks.state…]` entry keyed on that carrier is written for
it. Measured first against a disposable `CODEX_HOME` in slice A, then twice on the live install.

**2 · Trust is granted by an API call with NO human prompt.** This is the best-supported finding
on `#455` and the one with the most consequence for anyone building a bridge on this runtime. Two
days, two endpoints — `config/batchWrite` and `config/value/write` — no prompt shown, no human
confirmation, and the runtime reported `trustStatus: "trusted"` afterwards. The entry both times:

```
[hooks.state."tadeumendonca-skills@tadeumendonca:codex-hooks.json:pre_tool_use:0:0"]
trusted_hash = "sha256:bf622f99b01e22b3df393094f5b959d28c590a9f4753777ed4808ebd04dbac92"
```

**The hash is byte-identical across the two registrations**, which is consistent with slice A's
separate finding that **Codex hook trust binds a PATH, not a FILE** — rewriting the script's bytes
afterwards leaves the hash unmoved, the status `trusted`, and the rewritten script executing.

> **The rule that follows, and it is not a Codex detail: a bridge must not treat Codex hook trust
> as a human checkpoint.** `AC2` of `#455` was written on the premise that it is one. That premise
> was falsified against a fixture and has now reproduced on a real install twice.

**The owner removed the trust entry after each run.** `~/.codex/config.toml` is at its pre-run
digest and carries no entry for this carrier — verified 2026-09-16 rather than asserted:

```sh
shasum -a 256 ~/.codex/config.toml
# -> d3d390731089c913042141cf9ec2e3c305fb4954cc3d890c44cdf756357d23bf
grep -c 'tadeumendonca-skills@tadeumendonca:codex-hooks.json' ~/.codex/config.toml
# -> 0   (exit 1)
```

### What FELL — withdrawn, not merely qualified

- ~~**"execution: ran."**~~ **Registration and trust are not firing.** No run has shown the
  carrier's hook acting on a tool call.
- ~~**"`git push origin main` was blocked by `PreToolUse` before reaching Git."**~~ **The same
  command is refused by this repository's execpolicy, which names itself in the refusal.** See
  section 14; the attribution cannot be sustained.
- ~~**"The control fired and returned no decision."**~~ **An executed command is indistinguishable
  from an unhooked one.** That was the hazard the measurement was designed around, and the block
  half — the only half that could discriminate — turned out to be the other layer.
- ~~**"The floor is ACTIVE for a session rooted in this checkout."**~~ **No wording asserting
  activity is supportable today**, in any scope. *Available* is what the carrier and the adapter
  support; *active* is not.
- ~~**"The hook command is a relative path resolved against the SESSION's working directory, and a
  session started elsewhere fails closed."**~~ **BOTH HALVES WITHDRAWN.** The affirmative half
  rested on the withdrawn execution claim. The fail-closed half came from a session in
  `tadeumendonca-io` that ran with **no hook registered at all** — the trust key was absent and
  `~/.codex/config.toml` sat at the digest above — so that run measured the **no-hook** case, not
  the **not-found** case. **Not-found behaviour is UNMEASURED IN BOTH DIRECTIONS**, and no claim
  about portability to a second repository follows from anything here.

**This last one is the strike worth pausing on, because it was the more attractive of the two
claims.** *"It fails closed"* is the direction this platform's failures usually do not run, so it
read as the reassuring half of a defect report — and it was the half with no evidence behind it at
all. **A finding that flatters the system it describes deserves the same probe as one that does
not.**

### ~~The FIRING question is OPEN, and the standing explanation is a HYPOTHESIS~~

~~**Why a registered and trusted `PreToolUse` hook did not act on a `Bash`-shaped tool call, in the
plugin's own checkout, is not answered here and is not guessed at.**~~

~~**The standing hypothesis, labelled as one:** the adapter's own header records the structural gap
this document measured in section 3 — `command/exec`, `process/spawn` and `thread/shellCommand`
each fired **zero** hooks against a trusted registration, all three succeeding. So the leading
explanation is that the runtime ran these commands through one of those unhooked routes rather
than through the hooked one. **Nothing here tests that.**~~

~~**What would settle it, and it is a build rather than a measurement:** the adapter recording its
own invocations, so *"the hook did not fire"* and *"the hook fired and abstained"* stop being the
same observation from outside. **That instrument is deliberately not built in this slice** — it
is a mechanism with its own predicate, its own test file and its own decision about where a
side-effecting log may live, and folding it into a correction of this page would price two
decisions as one.~~

**STRUCK 2026-09-21. The instrument was built, the turn was run, and THE HOOK FIRES — see
section 15.** Struck rather than deleted because this paragraph is what told every reader the
question was open and named the hypothesis they would have reasoned from; the hypothesis is
**narrowed rather than confirmed**, and a reader who arrives at it deserves to find what
narrowed it rather than an absence.

### What the ADAPTER does, which is a different claim and still holds

**Fed a native Codex `PreToolUse` payload directly, the adapter decides correctly.** That is a
fact about this repository's own code and it survives every strike above — what is unproven is
that Codex ever hands it a payload. Re-derived at this head rather than pasted:

Save this as a file and run it with `python3 <file> <repo-root>`. **It is deliberately NOT written
as a heredoc**: its payload strings name acts this repository's own floor refuses, and the guard
does not parse shell — a heredoc body carrying `git push origin main` is denied as the act, which
is the friction this document would otherwise publish as a command nobody can run.

```python
import json, subprocess, sys
REPO = sys.argv[1]
for command in ["git status --short", "git push origin main",
                "gh pr merge 999999 --merge", "ls -la"]:
    payload = {"hook_event_name": "PreToolUse", "tool_name": "Bash",
               "tool_input": {"command": command},
               "agent_type": "codex-unidentified", "cwd": REPO}
    p = subprocess.run([sys.executable, REPO + "/scripts/codex-hook-adapter.py"],
                       input=json.dumps(payload), capture_output=True, text=True, cwd=REPO)
    out = (p.stdout or "").strip()
    print(command, "exit=%d" % p.returncode,
          json.loads(out)["decision"] if out else "(none)")
# git status --short           exit=0 (none)
# git push origin main         exit=0 block    "Blocked: pushing to the trunk…"
# gh pr merge 999999 --merge   exit=0 block    "Blocked: merging a PR is the deploy…"
# ls -la                       exit=0 (none)
```

**The two abstentions are a real zero and not a dead selector** — the same harness, the same
payload shape and the same caller return `block` on the other two. And `999999` is not a pull
request, so nothing could have been merged either way.

### What holds any of this

**Nothing.** No gate in this repository can observe a Codex session, which directory it started
in, whether a registration was trusted, or whether a hook fired. `scripts/codex-hook-adapter.py
--selfcheck` reports that the adapter can be found and run; **it says nothing about whether Codex
ever calls it**, and by construction it cannot — if the check is executing, the resolution it
would be reporting on already succeeded.

## 14 · TWO containment layers ship here for Codex, the cheaper one answers first, and that is why the first run was wrong

**This is the most reusable thing on this page and it is not about Codex.** It is about probing a
system that has more than one layer covering the same act.

### The two layers, and neither document mentions the other

| layer | file | verb | what it reads |
|---|---|---|---|
| **execpolicy** | `.codex/rules/claude-command-policy.rules` | `forbidden` / `allow` | literal argv prefixes, `argv[0]` onwards |
| **hook bridge** | `.codex-plugin/plugin.json` → `codex-hooks.json` → `scripts/codex-hook-adapter.py` → `hooks/scripts/permission-guard.sh` | `block` | the whole command string, plus caller identity |

**Nothing in this repository documented them as coexisting layers, and that is measured rather
than asserted.** **The commands below are pinned to `origin/main` on purpose**, because this
section is itself the change that moves the figure — a number whose base sits inside its own diff
is not a measurement of anything. At that base, of the ten tracked files naming either mechanism,
**one** names both, and inside it the occurrences are ~1,160 lines apart in amendments written six
days apart, neither referencing the other:

```sh
git grep -l 'claude-command-policy' origin/main -- . | grep -v ':powers/'
# -> origin/main:docs/adr/0004-controls-and-enforcement.md
#    origin/main:hooks/scripts/codex-rules.test.sh        (the gate, which names no adapter)
git grep -n 'claude-command-policy' origin/main -- docs/adr/0004-controls-and-enforcement.md
# -> 5015        (the #419 amendment, 2026-09-08)
git grep -n 'codex-hook-adapter'   origin/main -- docs/adr/0004-controls-and-enforcement.md
# -> 5934 6175 6307                                       (the #455 amendments, 2026-09-14)

# CALIBRATION — the denominator, so "one of ten" is read against a non-empty set:
git grep -l 'claude-command-policy\|codex-hook-adapter' origin/main -- . | grep -v ':powers/' | wc -l
# -> 10
```

**And this page named the execpolicy ZERO times at that base** —
`git grep -c 'claude-command-policy' origin/main -- docs/codex-hook-bridge.md` emits nothing and
exits 1. **This section is what changes that**, and it is the whole of the change: nothing here
makes the two layers move together, and no gate asserts that either document still mentions the
other.

### The overlap is BROAD — 61 of 64, measured rather than estimated

Every `prefix_rule` in the execpolicy, with the command its pattern names fed to the adapter as a
native `PreToolUse` payload:

```sh
python3 scratch/overlap-sweep.py <repo-root> codex-unidentified   # the script is below
```

|  | floor says **block** | floor **abstains** |
|---|---|---|
| execpolicy **`forbidden`** (64) | **61 — OVERLAP** | 3 |
| execpolicy **`allow`** (230) | **3 — DISAGREEMENT** | 227 |

```sh
# the denominators, each derived separately:
grep -c 'decision="forbidden"' .codex/rules/claude-command-policy.rules   # -> 64
grep -c 'decision="allow"'     .codex/rules/claude-command-policy.rules   # -> 230
grep -c '^prefix_rule'         .codex/rules/claude-command-policy.rules   # -> 294
```

**Both off-diagonal cells are non-empty, which is what makes the two large cells readable rather
than arithmetic:**

- **execpolicy only (3):** `claude mcp` · `gh api` · `npm run e2e:production`. The floor abstains
  on all three.
- **DISAGREEMENT — `allow` in the execpolicy, `block` in the floor (3):** `gh pr merge` ·
  `gh pr comment` · `gh issue comment`. **These are the only probes on this harness that can see
  the hook layer at all**, and the set is caller-robust: re-running the sweep with `agents-lead`
  in place of `codex-unidentified` returns the same three.

**The 61 are every irreversible act this floor exists to refuse** — trunk push in all four
spellings, force-push, tag push, `git clean -f`, `git reset --hard`, `rm -rf` in six spellings,
`terraform apply`/`destroy`, secret writes, `gh repo delete`/`archive`/`rename`, release
create/delete, `gh workflow run`, `--dangerously-skip-permissions`. **Every one of them is
untestable through the hook, by construction.**

### The rule this yields

> **A probe inside the overlap cannot observe the layer it is testing — and it does not return a
> null result, it returns a CONFIDENT POSITIVE, which is strictly worse.** The act is refused, the
> refusal looks like proof, and the layer that actually answered is the one nobody was testing.
>
> **So: pick the probe where the layers DISAGREE, and make the disagreement visible in the refusal
> text.** A refusal that names its own layer is what turned this from a belief into a measurement.

The first run picked `git push origin main` — line 317 of the execpolicy, `forbidden`, and
therefore the single most over-covered act in the whole matrix. Re-run, Codex refused it and
**named the layer**: *"rejected: policy forbids commands starting with `git push origin main`"*,
explicitly *"Refused by Codex policy, not by a hook."*

```sh
grep -n 'push", "origin", "main"' .codex/rules/claude-command-policy.rules   # -> 317: forbidden
grep -n 'pattern=\["gh", "pr", "merge"\]' .codex/rules/claude-command-policy.rules
# -> 99: allow      <- the disagreement the second run probed with
```

**A sharper sub-case, because it shows the trap is finer than one command:** `gh pr merge` sits in
the disagreement cell, and `gh pr merge --squash` sits in the **overlap** — the execpolicy
forbids the squash spelling and the floor blocks it too. **The same subcommand straddles both
cells depending on a flag.** A probe is not chosen by naming an act; it is chosen by checking the
act's exact spelling against both layers.

### The sweep instrument

It is not a gate and is not committed as one — it reads a vendor-independent pair of this
repository's own files and answers one question, which is the shape this repository's own rule
says to discard rather than persist. Reproduced here so the numbers above are re-derivable:

```python
import json, re, subprocess, sys
from collections import Counter
REPO, CALLER = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else "agents-lead")
RULE = re.compile(r'^prefix_rule\(pattern=\[(.*?)\],\s*decision="(\w+)"\)')
rows = []
for line in open(REPO + "/.codex/rules/claude-command-policy.rules", encoding="utf-8"):
    m = RULE.match(line.strip())
    if m:
        rows.append((" ".join(re.findall(r'"([^"]*)"', m.group(1))), m.group(2)))
cells = Counter()
for command, decision in rows:
    payload = {"hook_event_name": "PreToolUse", "tool_name": "Bash",
               "tool_input": {"command": command}, "agent_type": CALLER, "cwd": REPO}
    p = subprocess.run([sys.executable, REPO + "/scripts/codex-hook-adapter.py"],
                       input=json.dumps(payload), capture_output=True, text=True, cwd=REPO)
    out = (p.stdout or "").strip()
    cells[decision + "/" + (json.loads(out)["decision"] if out else "none")] += 1
print(len(rows), dict(cells))
# -> 294 {'allow/none': 227, 'forbidden/block': 61, 'allow/block': 3, 'forbidden/none': 3}
```

### One stale sentence found by the sweep and NOT repaired here

The execpolicy's own header, written 2026-09-08, says of this harness's hook layer that *"the
whole-command-string guard that backs the Claude floor was simply never written for it."* **That
is false at head** — `scripts/codex-hook-adapter.py` landed 2026-09-14 and is exactly that. It
errs by **understating** coverage, which is the safe direction for a floor, and repairing it means
editing a tracked permission layer under its own gate for a prose reason. **Named here rather than
fixed, and it is a finding rather than a note:** the file that a Codex operator would read to
learn what contains them says the other containment layer does not exist.

### What holds sections 13 and 14

**Nothing mechanical, and the shape of the gap differs between them.** Section 13's claims are
about a runtime no gate here can reach. Section 14's two figures — the overlap matrix and the
one-file coexistence count — are re-derivable from this repository's own tracked files by the
commands printed beside them, **and no gate re-derives either**, so both go stale silently the
next time a rule is added to the execpolicy or a rule is added to the guard. That is stated rather
than mitigated: an arm pinning the matrix would pin two files' current contents against each
other and redden on honest work in either.

## 15 · THE HOOK FIRES — measured 2026-09-21 on `0.151.0-alpha.7.2`, and AC7's evidence with it

**Two turns, on the build this machine actually has. Both phases are in
`scripts/codex-hook-probe.py` and both require `--allow-model-turn`, because both spend the
operator's own tokens.**

**Read the version first, because it is the whole frame.** Section 13's withdrawn claims were
taken on **`codex-cli 0.154.0-alpha.6.2`**, and the shell CLI **`0.153.4`** named in AC1 has never
been present here. The binary at `/Applications/ChatGPT.app/Contents/Resources/codex` reports
**`0.151.0-alpha.7.2`**. So **everything below is a measurement on a third build**, and where it
disagrees with section 13 the honest reading is *does not reproduce on 0.151*, never *section 13
was false*. Dated negative measurements are not permanent vendor limits, and that cuts both ways.

### 15.1 · The firing question — THREE readings, separated in one turn

```
python3 scripts/codex-hook-probe.py \
  /Applications/ChatGPT.app/Contents/Resources/codex --phase firing --allow-model-turn
```

Three `PreToolUse` registrations in one `config.toml`, all trusted, differing in exactly the
dimensions the three candidate readings differed in; one model tool call; the act chosen where
**this harness's two Codex layers disagree** (`gh pr merge` is `allow` in the execpolicy and
`deny` in the guard), so a refusal can only have come from the hook. The `touch` is a chained
head, not decoration: the guard refuses the whole composition, so the marker is a crisp binary.

| registration | invocations | what it settles |
|---|---|---|
| an **absolute** recorder | **1** | this route IS hooked — the positive control |
| `bash scripts/firing-rel.sh`, **relative** | **1** | a relative command **resolves**, and against the **session's cwd** |
| `python3 <abs>/codex-hook-adapter.py` | **1**, logged by the adapter itself | the floor was **invoked** and **decided** |

```
hook_run_count      3
hook_run_statuses   ["completed", "completed", "blocked"]
adapter_decisions   ["block"]
marker_created      false          <- the act did NOT happen
feedback_entries    the guard's own reason text, verbatim, reaching the runtime
```

**So on this build: the carrier's floor is FOUND, INVOKED, DECIDES, and the DECISION TAKES
EFFECT.** All three hooks ran even though one blocked.

**What this does NOT say, and the discipline matters more than the result.** It does **not**
overturn the 2026-09-16 non-firing. Two differences survive between that run and this one and
neither is tested here:

- **the build** — `0.154.0-alpha.6.2` there, `0.151.0-alpha.7.2` here;
- **the registration route** — that run registered through the **plugin carrier**
  (`.codex-plugin/plugin.json` → `codex-hooks.json`, trust key
  `tadeumendonca-skills@tadeumendonca:codex-hooks.json:pre_tool_use:0:0`); this one registers
  `[[hooks.PreToolUse]]` directly in a disposable `config.toml`.

**What IS settled is that the standing hypothesis does not explain it as stated.** *"The runtime
ran the command through an unhooked route"* is refuted **for a model tool call on this build** —
the model's tool call fired every registration. The hypothesis survives only in the narrower form
*that particular act was not a model tool call*, which is a claim about how the 09-16 command was
issued and is not recorded anywhere. **Three readings became two, and the surviving pair is
`build` versus `registration route`.**

**And a third thing falls out that nobody had measured: a relative command RESOLVES, against the
session's cwd.** The adapter's own log records
`process_cwd = <the project the session was started in>`. AC1's un-struck limb — *the manifest is
read* is measured, *the command is found* is not — is **met for a config registration** and still
open for a plugin-carrier one. The cwd-binding consequence #468 documents is therefore **supported
as a mechanism** on this build, by a route that is not the carrier's.

### 15.2 · The invocation log — where a side-effecting write inside a preventive floor may live

**`CODEX_HOOK_ADAPTER_LOG`. Off unless an operator names an ABSOLUTE path; one JSON object per
line; a write failure never changes a verdict.** The three constraints that picked that design,
each eliminating the obvious answer, are written out in the adapter's own source rather than here.
The short form:

- **a repo-relative default is the defect this Issue found, one layer down** — so a relative value
  is **refused, not resolved**;
- **a fixed absolute default under the repo root writes into a tracked tree on every tool call**,
  which is a new side effect of a preventive control nobody asked for;
- **a default-on log of every command a model runs is a TRANSCRIPT.** This adapter sits on the one
  route that sees every shell act, so writing one by default would make the floor a surveillance
  surface as a side effect of being a floor.

**It records the ABSTENTIONS and the unparseable payloads too**, which is half the point: a floor
that logs only its refusals cannot tell *"it ran and said nothing"* from *"it never ran"*, and that
is exactly the pair this Issue could not separate.

### 15.3 · AC7 — the native permission evidence, and what it changed

```
python3 scripts/codex-hook-probe.py \
  /Applications/ChatGPT.app/Contents/Resources/codex --phase friction --allow-model-turn
```

One turn, a hook that is a **pure recorder** — it refuses nothing, so nothing observed is
attributable to this harness. Every fixture harmless and inside a disposable project.

| fixture | class | act completed? |
|---|---|---|
| `touch <proj>/F-CONTROL` | control | **yes** |
| `touch <proj>/F-SUBST-$(echo ok)` | command substitution | **yes** |
| `FOO=1 touch <proj>/F-ENVVAR` | env-var prefix | **yes** |
| `echo hi > <proj>/F-REDIR` | stdout redirection | **yes** |
| `touch <disposable-home>/F-OUTSIDE` | outside the workspace | **yes** |
| **`touch <proj>/F-SECOND` under `permissions: ":read-only"`** | **calibration** | **NO** — observed by the hook, never executed |

**The calibration is what makes the five `yes` readable.** Under `:read-only` an identical plain
`touch` was seen by the recorder and did not happen, so a permission layer was in force and *can*
stop an act. **It stopped none of the three convenience classes.**

**`permission_mode` read `"default"` under BOTH `:workspace` and `:read-only`** — the field does
not move. And the parameter **is** validated: `permissions: ":not-a-real-preset"` returns
`-32600 failed to load configuration: default_permissions refers to unknown built-in profile`.
So the field is **not a readback of the requested profile**, its observed domain on this build is
the single value `default`, and **nothing may branch on it.** Section 10's row is discharged in
the negative rather than in the affirmative, which is a smaller answer than it looks and is the
one that is true.

**One reading nobody had recorded: `:workspace` did not confine the write.** `F-OUTSIDE` landed in
the disposable home, outside the project. That is a fact about this build and is reported rather
than built on.

#### What was DONE about it, because AC7 is a criterion and not a question

AC7 requires each translated convenience refusal to ship **only after** evidence shows the same
stopped subset. **The stopped subset is EMPTY on this runtime**, and Codex's measured hook
vocabulary has one refusal verb and no prompt rung — so there is no prompt for these rules to be
avoiding. `/shell`'s own governing rule says a friction rule *"must fire on a SUBSET of what the
runtime stops for, never on more"*; on Codex these fired on **more**.

~~**So the three are narrowed out of the Codex path, and the classification lives in the GUARD.**
`deny_convenience()` … wraps exactly three call sites — rule 3 (command substitution), rule 8
(env-var prefix) and rule 8b (redirection).~~

**STRUCK 2026-09-21, in the same slice, on the merge gate's BLOCKING finding — and the strike is
worth more than the correction.** Two things were wrong and they compound:

- **"rule 3" named a FLOOR rule.** Rule 3 in that file is irreversible git history and ref
  rewrites. The substitution branch never had a number of its own; it is a branch of rule 8.
  **A comment misnaming a floor rule as a convenience rule, inside the helper whose whole
  purpose is that distinction.**
- **The substitution branch must not be switchable at all**, and routing it through the helper
  opened the floor.

### Why the substitution branch is different in kind — it MANUFACTURES a token

**Every floor rule in that file matches on tokens.** A substitution produces a token that is not
in the string the guard reads, so where the floor-matching word is the substitution's *output*,
**there is nothing left for those rules to recognise** — and this branch was the only thing
catching it. Measured at the blocked head, both spellings, against plain-spelling controls:

| | `on` | `off` |
|---|---|---|
| `rm -rf /some/dir` · IaC mutation · `gh secret set …` · `gh repo delete …` · `git reset --hard …` (plain) | deny | **deny** |
| the same six with the matching token manufactured — `` `echo rm` -rf /some/dir ``, `terraform $(echo apply)`, ``gh `echo secret` set …`` | deny | **ABSTAIN** |

**13 of 20 fixtures flipped, against six plain-spelling controls that denied in both columns.**
**The execpolicy does not cover it either** — it forbids token *sequences*, which a manufactured
token does not produce.

**So: `deny_convenience()` wraps TWO call sites — rule 8's env-var branch and rule 8b.** The
adapter sets `PERMISSION_GUARD_CONVENIENCE_RULES=off` and **authors no rule of its own**, which is
the whole of its thesis.

| | `on` (unset, and every other value) | `off` |
|---|---|---|
| `FOO=1 ls` · `ls > out.txt` | **deny** | **abstain** |
| `echo $(date)` · ``echo `date` `` | **deny** | **deny** — not switchable |
| an IaC mutation · a trunk push, plain **or manufactured**, either spelling | **deny** | **deny** |

**The two survivors are measured, not reasoned.** Neither manufactures anything: both sit *beside*
a command whose own tokens are intact. **Seventy wrapped floor acts** — ten irreparable commands
across four env-var wrappers and three redirect wrappers — **released ZERO under `off`**, with all
seven wrappers confirmed flipping on a harmless command so the zero is a real zero.

### The native measurement is KEPT, and it LOST

**Codex stops the substitution spelling no more than the other two** — the table above is unchanged
and the row is not deleted. What changed is that it is **outweighed**: switching the branch off
opens the floor on the harness this repository actually runs, which costs more than an over-block
on the harness it is being ported to. **A measurement can be sound and still not carry the
decision.** Deleting the row would hide that trade; reading it as licence to re-route the branch
would repeat it.

**The cost, stated as a cost rather than as a win:** on Codex the substitution refusal fires on more
than the runtime was measured stopping — the very thing AC7 forbids. It is the same over-block
posture this floor already accepts for rule 8's `VAR=x` case on the Claude side, and it is the safe
direction.

### The arm that should have caught this was GREEN, and that is the transferable part

The blocked round carried `off: a trunk push carrying a substitution is STILL a trunk push`, using
the **`$( )`** spelling — which rule 7 rescues through its own fail-closed *"could not resolve which
repository"* limb. **That limb does not match a backtick, and no other floor rule has an
equivalent.** So the arm passed **for a reason unrelated to its name**, on the one spelling in the
class that has a rescue, while asserting a property that did not hold.

**Not vacuous, not crashing — green for the wrong reason**, which is the hardest of the three to
see. Re-planting the defect against the repaired arms shows the asymmetry directly: **6 of 6
backtick arms redden and only 5 of 6 dollar arms do**, the survivor being exactly the trunk-push
row. **Every arm involving a substitution now asserts both spellings and calibrates each
separately.**

**The Claude path is byte-identical, envelope included** — nothing sets the variable there.
**A model cannot reach it**: a hook's environment is inherited from the host process, and a `Bash`
tool call is a fresh shell whose exports do not survive it.

**AC7 also requires these measurements be kept SEPARATE from the mandatory floor assertions, and
they are.** The friction phase's fixtures touch no floor rule; the floor arms live in
`permission-guard.test.sh` under `deny_convenience` and assert the opposite direction — ten
irreparable acts still denying under `off`, **twelve manufactured-token acts** (six commands ×
two spellings) still denying, and representative env-var and redirect wrappers on floor acts still
denying. **The narrowing is about the rule and never about the spelling**, which is precisely the
sentence the blocked round asserted and did not hold.

### One positional dependency, which nothing asserts

**`deny_convenience` abstains with `exit 0`, so it is safe only while every floor rule runs BEFORE
its call sites.** They do today — the floor occupies the `# 1.` through `# 7b.` blocks and both
remaining call sites are in rules 8 and 8b at the end of the file. **A floor rule added BELOW them
would be silently unreachable under `off`, with every arm still green**, because the arms check
verdicts for acts spelled today rather than the ordering. Recorded in the helper's own header;
**no gate holds it.**

### An advisory, recorded and not repaired here

`scripts/codex-hook-adapter.test.py` reads a log file without guarding the path in one arm, so a
defect that stops the file being created kills the suite before its summary prints. **The suite
exits 1, so it reads as RED rather than as a false green** — an unreadable red, not a hole, which
is why it is named rather than fixed in a slice about the floor.

### What holds section 15

**The same nothing that holds sections 13 and 14, and one thing more.** No gate here starts a
Codex process, so 15.1 and 15.3's runtime readings are held by **re-running the two phases on a
machine that has a binary** — and *which* binary is now part of the claim rather than a footnote.
What CI does hold is the **instruments**: `codex-hook-probe.test.py` gates that both phases
discriminate (their controls, their calibrations, and that the friction phase does not assert the
conclusion it measures), `codex-hook-adapter.test.py` gates the log's behaviour on every reachable
path including the unwritable one, and `permission-guard.test.sh` gates that exactly three rules
are switchable and that the floor is not.

**The count of three is itself an arm**, because a fourth call site is how this narrowing would
widen in silence.

## 16 · THE CARRIER ROUTE — installed, trusted, FIRING, and the shipped registration still does not run

**One turn, on `codex-cli 0.151.0-alpha.7.2`, through the vendor's own installer.**

```
python3 scripts/codex-hook-probe.py \
  /Applications/ChatGPT.app/Contents/Resources/codex --phase carrierfire --allow-model-turn
```

**What this phase varies is exactly one thing.** Section 15 measured a `config.toml`
registration firing on this build. Section 13's non-firing differed in **two** dimensions at
once — the **build** (`0.154.0-alpha.6.2`) and the **registration route** (the plugin carrier).
This phase holds the build at what is installed here and moves the route, which is the only one
of the two this machine can move.

### 16.1 · The install path EXISTS and is reachable — the earlier read was about READ-ONLY reachability

**`plugin/install` is a real method in this binary's own dispatch table**, and it takes the same
parameter shape `plugin/read` already uses:

```
strings -a /Applications/ChatGPT.app/Contents/Resources/codex \
  | grep -oE 'plugin/[a-zA-Z_/-]{2,30}' | sort -u | grep -E 'install|uninstall'
# plugin/install
# plugin/installed
# plugin/installedfs/readDirectoryplugi      <- a run-on, not a method
# plugin/installturn/startturn/settings      <- a run-on
# plugin/installturn/startturn/steertur      <- a run-on
# plugin/share/deleteapp/installedfs/re      <- a run-on
# plugin/uninstall
```

**The output is printed in full, including the run-ons, because the method table is one
unseparated string run in this binary and `strings` cannot see the boundaries.** Four of the
seven lines are adjacent methods glued together. **The method names are therefore read out of
the run rather than off these lines** — and the one that matters is not inferred from strings at
all: `plugin/install` was **called** below, and it returned a result.

It is **not** an emulation and nothing is hand-placed: the call copies the package into
`<CODEX_HOME>/plugins/cache/<marketplace>/<plugin>/<version>/`, and every file the runtime then
reads was put there by the vendor's installer. Measured on this run, installing **this
checkout** as the package:

```
installed_file_count        157
installed_adapter_paths     …/plugins/cache/carrierprobe-market/tadeumendonca-skills/2.0.65/scripts/codex-hook-adapter.py
installed_guard_paths       …/plugins/cache/carrierprobe-market/tadeumendonca-skills/2.0.65/hooks/scripts/permission-guard.sh
```

**The guard travels with the adapter**, so the adapter's `REPO_ROOT = Path(__file__).parent.parent`
resolution is satisfied from the installed cache. That limb of AC1 is closed.

**Two mechanical notes an operator needs and no other surface carries.** A marketplace entry's
`source` is resolved **relative to the marketplace file**, so an absolute `source` is rejected with
*"plugin … was not found in marketplace"* — the probe reaches this checkout through a symlinked
sibling. And the package's `.git` is copied when it is a **file** (a linked worktree's pointer);
no `.git/` directory was copied.

### 16.2 · THE ENABLEMENT TRAP — a config rewrite silently disables the carrier

**`plugin/install` writes the plugin's enablement into the disposable `config.toml`:**

```
[plugins."tadeumendonca-skills@carrierprobe-market"]
enabled = true
```

Granting hook trust means writing a `[hooks.state."<key>"] trusted_hash = …` table into that same
file. **Overwriting it to add the trust block removes the enablement key, and the carrier's hooks
then vanish from `hooks/list` entirely** — no error, no warning, an empty list **indistinguishable
from a package that was never installed**. Measured directly, four states on one home:

| `config.toml` | `hooks/list` |
|---|---|
| as the installer left it | the registration, **untrusted** |
| installer's block **+ appended** trust | the registration, **trusted** |
| trust block only, **enablement dropped** | **empty** |
| restored | the registration, **trusted** |

**The third row is the calibration and it is the finding.** A probe that rewrote the config would
have measured a **disabled** plugin and reported it as a **non-firing route** — the same
right-answer-wrong-reason trap this document already records for the execpolicy layer, one layer
further out. The phase therefore appends, and refuses to continue if the installer wrote no
enablement block at all.

### 16.3 · The result — the route fires, and the shipped command is not found

Three registrations, one turn, one act, differing in **route** and in nothing else. The act is
section 15's: `touch <marker> && gh pr merge 999999 --merge`, chosen where **this harness's two
Codex layers disagree**, so a refusal is attributable to the hook rather than to the execpolicy.

| # | route | command | invocations |
|---|---|---|---|
| R1 | **`config.toml`** (`source: user`) | an **absolute** recorder | **1** — the positive control |
| R2 | **plugin carrier** (`source: plugin`) | an **absolute** recorder | **1** |
| R3 | **plugin carrier** — *the shipped registration* | `python3 scripts/codex-hook-adapter.py` | **0** |

```
hook_run_count      3
hook_run_statuses   ["completed", "completed", "blocked"]
adapter_log_entries 0          <- the adapter NEVER RAN
adapter_decisions   []
marker_created      false      <- and yet the act did NOT happen
feedback_entries    "/Library/Developer/CommandLineTools/usr/bin/python3: can't open file
                     '<PROJECT>/scripts/codex-hook-adapter.py': [Errno 2] No such file or directory"
```

**R2 is what settles the route question: a registration carried by an INSTALLED PLUGIN fires on
this build.** So *"the plugin carrier route is not hooked"* is **refuted on 0.151**, and the route
is not the cause here.

**R3 is the defect.** The shipped carrier's **relative** command resolves against the **session's
cwd**, exactly as section 15 measured for a config-registered relative command — and for an
**installed** plugin that is the wrong directory by construction: the adapter sits in the plugin
cache, and the runtime looked for it under the project. The payload the carrier's own hook captured
confirms which directory that is:

```
"cwd": "<PROJECT>"        not the plugin root
```

### 16.4 · The trap in the result — `marker_created false` is NOT the floor working

**Read that line and stop, and you conclude the carrier blocked the act. The guard never ran.**

`hook_run_statuses` reads `blocked` for R3, and it reads `blocked` in section 15.1 too — where the
adapter genuinely decided. **The status field does not discriminate a floor decision from a hook
whose command could not be launched.** The only thing that separates them is the adapter's own
invocation log: **one** entry in 15.1, **zero** here. That is precisely the pair section 13 could
not separate, and it is the argument for the log having been built at all.

**Two consequences, and the second is the one that outlives this slice.**

- **On this route a broken registration DENIES rather than abstains.** ADR-0004's general contract
  is that guard failure is deliberately **fail-open**; here the failure is one layer above the
  guard, in the runtime, and it is **fail-closed** — and since a `PreToolUse` hook sees every model
  tool call, an unresolvable command is a **blanket session denial**. AC6 names that shape by name:
  *do not convert an observer failure into a blanket session denial, or claim silent hook failure
  as enforcement.* **No ADR amendment is owed for it** — no decision changed; this is a measured
  property of a vendor runtime, and its home is this document.
- **It fails in the SAFE direction, which is why it survived.** Nothing escapes; the session simply
  stops. An operator sees a refusal and a python error in feedback, and the refusal looks like the
  floor doing its job.

### 16.5 · What this closes, and what it explicitly does not

**Closed:** the install path is reachable and is the vendor's own · the installed package carries
both the adapter and the guard · a plugin-carrier registration **fires** on `0.151` · the shipped
carrier's registration **does not execute**, for a named and reproducible reason · a config rewrite
silently disables an installed carrier.

**NOT closed, and none of it is inferred from the above.** This does **not** reproduce the
2026-09-16 run and does not refute it: that measurement is attributed to
`0.154.0-alpha.6.2`, which is not on this machine, and the honest form is *does not reproduce on
0.151*. **Because the carrier route fires here, ROUTE is eliminated as the cause on this build —
which leaves BUILD as the surviving explanation for 09-16 and leaves it UNVERIFIED.** Nor does R3
explain 09-16 by itself: that session ran in the library working directory, where a relative
`scripts/codex-hook-adapter.py` **would** have resolved. Two things are now known to be able to
produce a silent floor on this carrier, and which one produced 09-16 is not decided here.

~~**So *available, never active* remains the right wording for the carrier's own route** — and for a
**measured** reason now rather than an unproven one. Nothing in this section licenses dropping it.~~
**Struck 2026-09-22: section 18 records installed-carrier execution on both builds.**

### 16.6 · ~~The mitigation, named and NOT measured~~ — MEASURED 2026-09-22, see section 17

**Struck in place rather than edited away: this is the section a reader would have taken
*"the repair rests on nothing"* from**, and it stood while the measurement that settles it
had already landed in this tree's own instrument. The strings read below is unchanged and is
still correct about what it establishes; what is false is the conclusion at the end of it.

The obvious repair is to stop registering a relative command. The bundle carries a token group that
looks like the intended mechanism:

```
strings -a /Applications/ChatGPT.app/Contents/Resources/codex \
  | grep -oE 'PLUGIN_ROOT[A-Z_]*|CLAUDE_PLUGIN_ROOT|PLUGIN_DATA[A-Z_]*' | sort -u
# PLUGIN_DATA
# PLUGIN_ROOT
# PLUGIN_ROOTCLAUDE_PLUGIN_ROOTPLUGIN_DATACLAUDE_PLUGIN_DATA   <- a run-on of four names
# PLUGIN_ROOTPLUGIN_DATAA                                      <- a run-on
```

**Printed in full, and the run-ons are why this is weaker than it looks.** `CLAUDE_PLUGIN_ROOT`
occurs **only inside a concatenated run**, never as a line of its own, so what is established is
that these four names exist **somewhere in the binary's string table** — not that any of them is
an environment variable, not that any is a substitution token, and not that a hook process ever
sees one.

~~**That is a read of strings in a binary and NOTHING MORE.** Whether the runtime exposes them as
environment variables to a hook process, as `${…}` substitution inside a registered command, or in
neither form, **is not measured** — and the difference decides whether the repair is one character
of `codex-hooks.json` or a bootstrap script. **What would settle it: one turn with a carrier-
registered recorder that dumps its own environment and its argv**, which is a second measurement and
is deliberately not taken here.~~

**STRUCK 2026-09-22.** The turn it names was run — a carrier-registered recorder that dumped
its own environment and its argv — and the answer is **BOTH mechanisms, not one**: the four
names are injected as environment variables AND the token expands inside the declared command.
**Section 17 carries the readings, the repair, and what the repair still does not make true.**
The strike is kept because this paragraph is the one that told a reader the question was open.

### 16.7 · Containment

```
real_config_sha256_before  d3d390731089c913042141cf9ec2e3c305fb4954cc3d890c44cdf756357d23bf
real_config_sha256_after   d3d390731089c913042141cf9ec2e3c305fb4954cc3d890c44cdf756357d23bf
real_config_unchanged      true
credential_copies_made 1 · removed 1 · left_behind []
```

Every install, every trust write and the turn itself ran against a **disposable `CODEX_HOME`**. **No
global permission was changed and nothing was marked trusted outside that home.** The act is a
`touch` in a temporary directory chained to `gh pr merge 999999`, which names a pull request that
does not exist; no real destructive command, private content, secret store, infrastructure change or
forge publication was a test effect.

### 16.8 · What holds section 16

**Nothing in CI starts a Codex process**, so 16.3's readings are held by re-running the phase on a
machine that has a binary, and **which** binary is part of the claim. What CI holds is the
**instrument**: `codex-hook-probe.test.py` gates that the phase is a paid phase unreachable from
`--phase all`, that its fixture's command stays **absolute** (the property that keeps *the route was
silent* and *the command was not found* two observations rather than one), that the trust block
appends rather than replaces, that the config control is pinned by source **name**, and — the arm
that matters most — **that the phase does not assert the carrier route fired**, which is the
measurement it exists to take.

## 17 · THE REPAIR — `${PLUGIN_ROOT}` is measured, and the shipped registration now uses it

**Section 16.6 said the mitigation was not measured. It is, and this section is where that stops
being true.** The `carrierroot` phase was run on 2026-09-22 against `codex-cli 0.151.0-alpha.7.2`
and its readings are pinned in the instrument that took them, `scripts/codex-hook-probe.py`'s
`ROOT_MEASURED`. **16.6 is struck in place rather than edited away** — it is the sentence a reader
would have taken *"this repair rests on nothing"* from, and it stood while a commit in this same
tree had already settled it.

### 17.1 · What was measured, and the shape of the reading

```
python3 -c "
import importlib.util as i
s = i.spec_from_file_location('p', 'scripts/codex-hook-probe.py')
m = i.module_from_spec(s); s.loader.exec_module(m)
print(m.ROOT_MEASURED)"
```

| reading | value |
|---|---|
| environment names injected on the **plugin** route | `CLAUDE_PLUGIN_DATA` · `CLAUDE_PLUGIN_ROOT` · `PLUGIN_DATA` · `PLUGIN_ROOT` |
| environment names injected on the **config** route | **none** |
| `${…}` expansion inside the declared command | **observed**, in both the `${X}` and the bare `$X` spelling |
| values are **per plugin** | yes — packages A and B received four different values each |
| `CODEX_PLUGIN_ROOT` | **does not exist**, under either mechanism |
| an **unset** name | **removes its whole argument** — 9 declared arrived as 7, every later index shifted, no error raised |
| `cwd` | the **session's** project directory on both routes |

**Two mechanisms, not one, and they are available at different moments.** A hook process can read
the value out of its own environment *after* it starts, and the runtime also expands the token
*before* it starts. Only the second can decide where the interpreter looks for a file, which is why
the repair is a token in the command string rather than a bootstrap script that reads `os.environ`.

### 17.2 · The repair, and the one thing it deliberately does not do

```
- "command": "python3 scripts/codex-hook-adapter.py"
+ "command": "python3 ${PLUGIN_ROOT}/scripts/codex-hook-adapter.py"
```

**`PLUGIN_ROOT` rather than `CLAUDE_PLUGIN_ROOT`, and the reason is a rule rather than a
measurement.** Both were injected and both expand, so nothing separates them mechanically. What
separates them is this repository's own portable-brief rule: an artifact addressed to other
machinery names no harness-specific token. `codex-hooks.json` is a Codex config, and spelling a
Claude-shaped name inside it is the same mistake `AGENTS.md` exists to prevent, one layer down.

**It is UNQUOTED, and that is a residual rather than a decision.** Expansion here was measured to
behave as shell word-splitting — an unset name does not arrive empty, it *vanishes* — so the
expansion is unquoted by the runtime. **Whether a quoted token survives, and whether a quoted value
carrying a space survives, is NOT MEASURED**: settling it costs another Codex turn and that spend
was declined. So the shipped form is the one directly measured to expand, and **the cost is stated
rather than guarded: a plugin-cache path containing a space would word-split and the launch would
fail.** On this machine it does not — the cache path is
`<CODEX_HOME>/plugins/cache/<marketplace>/<plugin>/<version>/` and every segment is an identifier —
but that is a fact about this installation, not about the runtime.

**And `CODEX_PLUGIN_ROOT` is the plausible spelling that would have been wrong.** It is the name a
reader invents from the harness's own vocabulary, it was measured not to exist, and an unset name
here does not fail loudly: `${CODEX_PLUGIN_ROOT}/scripts/…` collapses to `/scripts/…`, an absolute
path at the filesystem root, the launch fails, and section 16.4's trap fires — the runtime's
blanket denial is indistinguishable from the floor holding. `codex-hook-adapter.test.py` asserts
membership in the measured set for exactly that reason, and derives the set from `ROOT_MEASURED`
rather than restating it.

### 17.3 · What this does NOT make true

~~**It does not make the floor active on Codex, and no sentence here may be read that way.** Three
things stand between this commit and a held floor, and **none of them is in this repository**:~~

1. ~~**The plugin must be updated on the Codex side.** Measured 2026-09-22, the installed cache is at
   a version that still carries the relative command, so the repair is not live there until the
   owner updates.~~
2. ~~**The registration must be TRUSTED.** Trust is a `[hooks.state."…"] trusted_hash` table in the
   invoking user's own `config.toml`, and none of this carrier's registrations has one.~~
3. ~~**The route is measured firing on ONE build.** `0.151.0-alpha.7.2` is what this machine has;
   the 2026-09-16 non-firing on `0.154.0-alpha.6.2` is neither reproduced nor refuted, and section
   16.5's *build is the surviving explanation, unverified* is untouched by this slice.~~

**Struck 2026-09-22: all three conditions were subsequently discharged for installed `2.0.71`,
within the bounds in section 18.** The historical claim stays visible because it was correct for
this slice and is false as a current activation statement.

~~**So the wording does not move to *active*.** What moves is narrower and worth saying exactly: the
carrier's registration was *known not to execute*, for a named reason, and that reason is repaired.
Whether it now executes is **unverified** — no turn was run in this slice — and a repair verified
only by its own test suite is a repair, not an observation.~~

**Struck with the block above, for the same reason: it was true of this slice, where no turn ran,
and is false as a current statement.** Execution of the installed `2.0.71` `PreToolUse` registration
is observed on two builds — see section 18.1 for the evidence and its bounds. What stays true is the
general point: a repair verified only by its own test suite is a repair, not an observation — which
is why section 18.4 still lists the carrier's own `UserPromptSubmit` registration as **owed**.

### 17.4 · What holds this section

**The repair itself is gated:** `scripts/codex-hook-adapter.test.py` asserts the argument opens with
a `${NAME}/` expansion, that the name is one measured as injected *and ends `_ROOT`* (`PLUGIN_DATA`
expands cleanly and points at the wrong directory), and that the argument carries the token, the
in-package path and nothing else. Every arm was calibrated by mutating the **source** — the relative
form, `CODEX_PLUGIN_ROOT`, `PLUGIN_DATA`, a quoted token, a mid-word token and a trailing argument
each redden at least one arm, and the file re-greens on restore.

**What no arm can assert is that the repaired command LAUNCHES**, because nothing in CI starts a
Codex process. That is `codex-hook-probe.py`'s subject and needs a binary. The honest state is:
the spelling is pinned to the measurement, and the execution is owed a turn.

## 18 · INSTALLED AND BLOCKING on two builds; native preflight supported; semantic coverage still open

### 18.1 · The installed carrier evidence, dated and bounded

The owner authorised trust only where necessary for the preventive floor the loop already requires.
Through the native TUI, the operator trusted the **individual displayed `PreToolUse` registration**
for installed `tadeumendonca-skills@tadeumendonca` `2.0.71`; no trust-all action, bypass flag,
manual hash write or permission override was used. The UI moved from one installed/zero active to
one installed/one active and displayed `Trusted`.

On Desktop `0.151.0-alpha.7.2`, session `01a0cb98-754c-7a22-b033-f64e97ecb832`, the installed
adapter invocation log records three real model `Bash` events. An allowed `printf` executed. An
unquoted command substitution produced `decision:block`, the native UI reported the
`PreToolUse` block, and the shell did not execute. A quoted harmless substitution abstained and
executed. This is installed-carrier invocation plus one positive and one negative effect control;
it is not a claim about all shell spellings.

Independent QA then ran installed `2.0.71` from the product repository through the VS Code binary
`0.154.0-alpha.6.2`, session `01a0cbdf-c528-7641-99b0-6ef808ecb7e3`. The allowed call executed
and the unquoted substitution was blocked and suppressed. Its payload reported ambient
`permission_mode=bypassPermissions`; QA used no bypass flag, trust mutation or config mutation.
The honest conclusion is carrier blocking on that runtime. The Desktop run separately provides the
default-mode reading.

These two runs refute the earlier surviving build hypothesis for the measured `PreToolUse`/`Bash`
route. They do **not** authenticate `agent_type`, cover host/IDE shell routes, close the
`write_stdin` gap, or turn installed trust into script-content integrity.

### 18.2 · The quoted nested-operation gap ~~is observed, not repaired here~~ — observed at `2.0.71`, repaired in the shared guard's source at #497

QA fed strings to the adapter without executing them. The quoted fixture
`printf "%s" "$(gh secret set PROBE --body value)"` abstained; its unquoted sibling blocked as a
secret write. Combined with the harmless native quoted substitution above, this proves a gap in the
shared guard's quote-collapse semantics. No secret write was attempted.

That finding blocks a complete AC4/AC7 coverage claim even though invocation itself is proven. The
repair changes the shared Claude/Codex floor and its regression contract, so it is outside this
Codex-only slice and has been authorised as a separate follow-up. This section does not claim that
trust or carrier activation repaired it.

**AMENDED 2026-09-23 (#497) — the follow-up landed in the SHARED guard, and the adapter gained no
policy.** Rule 8 of `hooks/scripts/permission-guard.sh` now also runs a substitution-specific scanner
(`subst_active`) over the original command and each unwrapped `-c` payload, so an active `$(…)` or
backtick inside double quotes, escaped surrounding quotes, mixed quote concatenation or an unquoted
heredoc body denies with its own reason, whatever `PERMISSION_GUARD_CONVENIENCE_RULES` says.
**These spellings, not the class** — round 2 (#500's lens) added a heredoc whose quoted delimiter
carries a blank or `;&|<>()`, which had hidden every later line, and `$\<NL>(…)` line continuation;
process substitution `<(…)` is not covered. A command too large to scan inside the guard's time
budget is denied with its own reason, ~~never left to the adapter's 4.0 s timeout, where it abstains~~
(struck at the gate, #500 B1: false at `e3b466f1` — 4,000 heredoc openers took 5.02 s and the adapter
abstained; the queue is now popped by index and each opener is charged to the budget). What is
measured, not guaranteed: the worst of nine operation-heavy shapes answered in 0.91 s and that
24 KB input is blocked through the adapter in 0.27 s, asserted in its suite. **Not covered either:** a
`-c` wrapper followed by more text — `bash -c '…' _`, `sh -c '…'; true` — is never unwrapped, so a
substitution in that payload is not seen; ALLOW before #497 and after it.
The scanner is **additive** to the old `$bare` predicate, so nothing that predicate denied can
reach ALLOW, and every other rule still reads `$bare` unchanged. Through this adapter the QA fixture
above now returns `block` — asserted, as data and never executed, in
`scripts/codex-hook-adapter.test.py`'s AC7 section beside two inert twins (a single-quoted literal and
an escaped dollar) that must still pass. **Three layers, kept apart:** the guard's DECISION is
proven by `hooks/scripts/permission-guard.test.sh`; the adapter's TRANSLATION of it by the adapter
suite; the native RUNTIME effect is **not** re-measured — installed `2.0.71` predates the repair, so
a native run on an installed release carrying it is owed. The executable/literal table, the measured
shells and the bounds are in ADR-0004's 2026-09-23 amendment.

### 18.3 · `UserPromptSubmit` can carry the Codex-native preflight

The new `preflight` probe phase used a disposable Codex home and project, trusted exactly one
disposable `UserPromptSubmit` command, then started one authorised model turn. The hook captured one
real prompt payload, the host reported it blocked, and the requested marker was absent. The invoking
user's real `config.toml` hash was identical before and after, and the copied credential was shredded.
Measured on Desktop `0.151.0-alpha.7.2`, this settles the layer question: the event can prevent a
degraded turn before tool dispatch.

The implementation is intentionally smaller than Claude's `preflight.sh`. `codex-hooks.json`
registers the same root-anchored adapter on `UserPromptSubmit`, and the adapter checks only the local
dependencies of the activated Codex floor: `bash`, `jq`, and the shared guard file. Python and the
adapter already exist if that code is executing; missing `git` or `gh` retain the guard's own
per-branch degradation posture and stay selfcheck notes. Dependencies of Claude-only observers are
not imported merely because the Claude registry declares them.

### 18.4 · What is proven, what is still owed

| claim | state |
|---|---|
| installed `2.0.71` carrier invokes `PreToolUse` and blocks the unquoted fixture on Desktop `0.151` | **observed** |
| same installed carrier effect on VS Code `0.154` | **independently observed**, with the ambient permission-mode qualification above |
| `UserPromptSubmit` can block a turn | **observed through a disposable native registration** |
| the new carrier's `UserPromptSubmit` registration fires after release/install | **owed** — CI cannot start Codex, and the installed package predates this change |
| quoted nested irreversible operations are covered | ~~**false at the measured shared guard** — separate repair required~~ **false at installed `2.0.71`; the shared guard's source denies ~~the class~~ the measured spellings listed in ADR-0004's 2026-09-23 amendment since #497 — not the class, and not process substitution** (guard decision and adapter translation asserted in CI; native effect on an installed release carrying it **owed**) |
| authenticated caller identity or whole-harness support | **not claimed** |

The carrier and adapter suites pin the two-event registration, the shared command, the no-matcher
shape, the exact local blocker set and its healthy abstention. Mutation removes `jq` and the guard in
turn and makes the prompt block. Those checks prove the implementation can go red; only the opt-in
native probe proves vendor routing.
