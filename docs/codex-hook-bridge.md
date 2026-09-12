# The native Codex hook seam — what is measured, and what nothing yet carries

**Nothing in this document is enforcement, and no artifact it describes refuses anything.**
`scripts/codex-hook-probe.py` is an instrument. It measures the seam a preventive bridge would
have to sit on; it is not that bridge, and a green run of it protects nobody. Read every sentence
below as *this is what the runtime does*, never as *this is what the harness now stops*.

The measurements were taken on **`codex-cli 0.151.0-alpha.7.2`**, the executable inside the
desktop application bundle. Re-run the probe rather than inheriting any number here.

```sh
python3 scripts/codex-hook-probe.py /Applications/ChatGPT.app/Contents/Resources/codex
```

Every phase builds its own disposable `CODEX_HOME` in a new temporary directory. The probe reads no
credential, starts no model turn, and never writes to the invoking user's real `~/.codex`.

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

## 2 · Trust — a hash written into the user's own `config.toml`, and there is no API for it

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

**There is no app-server method that grants trust.** The server enumerates its methods in the error
it returns for an unknown one; across **93** methods there is no trust call. `hooks/list` reads
state and `config/value/write` edits configuration, but the activation itself is a human act
against the user's own file.

```sh
# the enumeration is the discovery channel: ask for a method that cannot exist
python3 scripts/codex-hook-probe.py <codex-executable> --phase trust
```

**This harness's own hooks are already discovered by Codex, and all of them are untrusted.** The
installed plugin cache exposes every registration in `hooks/hooks.json` with `enabled: true` and
`trustStatus: "untrusted"`. Discovery is not execution, and nothing here changes that. **Do not
close the gap by trusting the existing bundle**: those scripts are written against a different
harness's payloads and event semantics, and one of them posts unattended.

## 3 · Routes — `command/exec` does not fire a `PreToolUse` hook, even when trusted

With a `PreToolUse` hook in the `trusted` state, two `command/exec` calls that **succeeded** —
exit code `0`, real stdout — produced **zero** hook invocations.

The positive control is inside the arm: it fails if no case succeeds, because a zero invocation
count over a refused command cannot distinguish an unobserved route from an act that never
happened. An earlier run of this measurement was confounded exactly that way — the command was
refused by the runtime sandbox, and the zero meant nothing until commands that succeed were
substituted. The counter itself is calibrated separately: invoking the recorder directly takes it
from `0` to `1`.

**The consequence is the one that bounds the next slice.** The route that fires a `PreToolUse` hook
is a model tool call, which requires starting a turn. So the hook payload — its fields, its event
mapping, and whether any caller identity appears in it — is not reachable from the read-only
app-server surface at all.

## 4 · The config schema — twelve PascalCase events, and a spelling that fails silently

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

## 5 · What is NOT measured, and why each one blocks something

| unmeasured | why it could not be taken here | what it blocks |
|---|---|---|
| the `PreToolUse` payload shape | no read-only route fires a hook; a model turn is required | the adapter's event and field mapping |
| whether a hook decision **blocks** an act | same | every claim that the bridge prevents anything |
| caller identity at the decision point | same | any caller-dependent exemption |
| later `write_stdin` / PTY input | same | the claim that intercepting a command covers what follows it |
| the shell CLI `0.153.4` | not present on this machine's `PATH`; only the desktop binary resolved | any "both binaries" claim |

**Nothing above may be filled in by analogy with the Claude payloads.** The event vocabulary is
already a superset with different names, and the config spelling already diverges from the key
spelling, so the two harnesses have been measured disagreeing on exactly the kind of detail an
analogy would paper over.

## 6 · What holds each statement in this document

**Nothing mechanical holds the prose.** `scripts/codex-hook-probe.test.py` runs in CI and gates the
**instrument**: that the expectation table still discriminates three outcomes, that the fixtures are
built as described, that this repository's registered events remain expressible, and that the
recorder the route arm counts can write. It never starts a Codex process, so **a green from it is
not evidence about the runtime** — it is evidence that the thing which measures the runtime is well
formed and capable of failing.

The runtime claims in sections 1–4 are held by re-running the probe on a machine that has the
binary. They are dated observations of a vendor surface, not invariants.
