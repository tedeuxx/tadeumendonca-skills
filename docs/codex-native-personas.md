# Native Codex personas

`scripts/codex-agent-build.py` projects the canonical `agents/*.md` briefs into native Codex profiles.
Each profile contains its entire brief and every declared preload, including command-backed preloads.
The source prose remains authored in the original files. The generated files are local snapshots;
they are neither a second authored roster nor part of the Kiro export.

Python 3.11 or newer is required. Choose the source explicitly: a library checkout, or the root of a
particular installed plugin version containing `VERSION`, `agents/`, `skills/`, and `commands/`.
Do not select an arbitrary cache version with a wildcard. The snapshot records the selected root,
version, checkout revision when present, all resolution input hashes, builder hash and output hashes.
A checkout revision alone does not assert a clean tree; the content hashes identify the actual inputs.

## Build and verify

Use a dedicated directory outside the checkout in your harness's local working storage. Keep it for
as long as a running session or registered project uses it.

```sh
python3 /path/to/library/scripts/codex-agent-build.py --source /path/to/library --output /path/to/local-storage/personas-v1
python3 /path/to/library/scripts/codex-agent-build.py --source /path/to/library --output /path/to/local-storage/personas-v1 --check
```

The builder derives the roster, requires each name to match its file, and resolves each preload to
exactly one `skills/<id>/SKILL.md` or `commands/<id>.md`. The existing `plugin:` and
`tadeumendonca-skills:` prefixes are supported. Missing, ambiguous, duplicate and escaped paths fail
with a specific cause. Unsupported frontmatter forms fail instead of partially loading a persona.
Profiles contain the original UTF-8 bodies, including their line endings; no summarization occurs.

`profiles/tadeumendonca_<persona>.toml` contains the native profile. Hyphens in the canonical name
become underscores. `registration.toml` contains explicit `agents.<role>.config_file` registrations;
it is not automatically loaded. `source-manifest.json` describes the inputs and outputs.

`--check` performs no writes and fails on changed source, changed output, missing files and unexpected
files. Rebuilding into the same directory is allowed only when its bytes already match. To update,
build a new directory and verify it before changing the session or project registration. This retains
the precise snapshot used by an in-flight review — **as long as the old directory is kept**, which is
measured below rather than assumed (see *Updating without breaking an in-flight review*).

## Knowing the registered snapshot is behind (#509)

A snapshot is pinned on purpose, so it falls behind every release until someone rebuilds it. On
2026-09-24 the consumer registered a `2.0.44` snapshot while the plugin was at `2.0.79`, and nothing
told the Codex session. **The Codex hook adapter now says so.** On every `UserPromptSubmit`, once the
floor's own preflight passes, `scripts/codex-hook-adapter.py` reads the project registration and
compares each registered snapshot's `source-manifest.json` `version` with the installed plugin's
`VERSION`. When a snapshot is older, or its version cannot be read, the model receives a notice
headed `PERSONA SNAPSHOT BEHIND` before it acts on the prompt. The notice names both versions and the
update procedure below. **It reports and blocks nothing.** A current snapshot produces no output.

- **The carrier is the existing `UserPromptSubmit` registration.** The hook command did not change, so
  its trust hash did not change and no re-trust is owed (`scripts/codex-hook-adapter.test.py` §8e
  pins it). A `SessionStart` registration would have fired once per session instead of once per
  prompt. It was not used because adding or editing a registration leaves it skipped until the
  owner re-trusts it, and that window turns the floor off silently.
- **Measured, loopback model, `codex-cli 0.151.0-alpha.7.2`:** the notice reached the turn's first
  model request as a `developer` message after the user's prompt. The hook run read `completed`, not
  `blocked`, and the act ran. With the snapshot at the installed version, the request carried no
  notice. Re-run with
  `python3 scripts/codex-hook-probe.py <codex> --phase snapshotnotice`.
  A scratch run the same day also installed this working tree through the plugin carrier into a
  disposable home. Both registrations read `trusted`, both ran `completed`, and the notice reached the
  model. That run was not a released install.
- **What it reads:** the `[agents.tadeumendonca_*]` tables in `.codex/config.toml`, from the prompt's
  `cwd` up to and including the git root. The nearest file wins for each role.
- **What it cannot see, so it stays silent:** a registration passed as `-c` flags by `--exec`, one in
  the user-level `config.toml`, and a thread that started before the project config was edited. That
  last case matters after an update. The notice reads the new file and goes quiet, while the old
  thread still uses the old snapshot (measured below).
- **Cost:** 689 characters of developer context on every prompt while one snapshot is behind, plus the
  length of its directory path. The figure comes from:

  ```sh
  python3 -c "
  import importlib.util
  s=importlib.util.spec_from_file_location('a','scripts/codex-hook-adapter.py')
  m=importlib.util.module_from_spec(s); s.loader.exec_module(m)
  print(len(m.snapshot_notice_text('2.0.81', [('', '2.0.44', ['r']*8)])))"
  ```

  The notice is not debounced. Debouncing would need a state file written on every prompt, and this
  adapter keeps no default side effects.
- **It never refuses.** The shipped command maps any non-zero adapter exit to 2, and exit 2 blocks the
  prompt. So every failure inside the notice is caught and becomes silence plus one stderr line. A
  missed notice costs a stale persona. A crash would cost the session.

Run `python3 scripts/codex-hook-adapter.py --selfcheck` from a project to get the same answer on
demand. It prints a `PERSONA SNAPSHOT (#509)` note. For a harness without this adapter, the same
behaviour is written up as a portable prompt:
[`docs/prompts/persona-snapshot-staleness.md`](prompts/persona-snapshot-staleness.md).

## Updating without breaking an in-flight review (#509)

Two runtime facts decide the procedure. Both were measured on `codex-cli 0.151.0-alpha.7.2` with a
loopback model and disposable homes (`--phase snapshotnotice`):

| after the project registration is rewritten from snapshot A to snapshot B | the spawned child received |
|---|---|
| a spawn in a thread that was open before the rewrite | **A** |
| a spawn in a new thread of the same running process | B |
| a spawn in a fresh process | B |
| **A's directory deleted**, then a spawn in a thread still registered to A | **no child**: `agent type is currently not available` |

**A thread keeps the registration it started with. A child's profile is read from disk when the child
is spawned.** So a review in flight survives a registration change. It does not survive deleting the
snapshot it started on. The procedure:

1. **Build a new directory** from the installed plugin root. Never rebuild into the old one; the
   builder refuses unless the bytes already match.
2. **Verify it** with `--check`.
3. **Re-register it** with `--install-config` (with `--backup`). Open threads keep the old snapshot.
4. **Continue in a new thread** (or restart the session). Only new threads receive the new personas.
5. **Keep the old directory until every thread that started before step 3 has finished.** Deleting it
   is what breaks an in-flight review: the next dispatch in that thread gets no child.

A review started before the update finishes on the snapshot it started with. A re-dispatch of the gate
in that same thread also uses the old snapshot. If the review must apply a rule that is newer than the
old snapshot, run it in a new thread after step 3.

## Activate a session without changing configuration

Run the launcher from the project being worked on, with the Codex executable and its ordinary
arguments after `--exec`:

```sh
python3 /path/to/library/scripts/codex-agent-build.py --source /path/to/library --output /path/to/local-storage/personas-v1 --exec codex
```

The launcher checks the snapshot and reads the native effective configuration through `config/read`
before and after adding explicit native registration. It requires every generated role to be present
and every unrelated effective value to remain equal. Native optional agent defaults materialized as
`null` are treated as unset. A conflicting role in its namespace causes refusal; an identical existing
registration is allowed. It keeps
the caller's working directory and arguments. It writes no user or project configuration, changes no
MCP settings or permission settings, and adds no hook trust. The same command works with an explicitly
selected installed plugin root as `--source` and the builder shipped in that version. The source may
be outside the consuming repository. Existing profiles in other namespaces are unaffected;
`tadeumendonca_` is this adapter's reserved role namespace. Caller flags attempting to overwrite that
namespace are refused when they are effective configuration assignments; a prompt discussing a setting
is still a prompt. Session registration is limited to the session launched this way. `-c`/`--config`
and `-C`/`--cd` are included in the effective-configuration inspection.

The measured native CLI uses a nonempty `exec` or `app-server` configuration bucket **instead of** the
root bucket. The launcher leaves caller arguments in their original order and inserts registrations
into the bucket already selected by that rule, using the root bucket when the subcommand has no
overrides. It neither merges buckets nor activates a previously empty subcommand bucket. Thus it
preserves the caller's native precedence, including root settings that native Codex itself ignores when
the caller already supplied subcommand overrides. The inspection follows that same selected bucket.

The supported grammar is interactive Codex, `exec`/`e`, and `app-server` without nested commands, with
the ordinary scalar model/sandbox/output/directory options recognized by the builder. Unmeasured
options and nested commands fail explicitly. Named configuration selection (`-p`/`--profile`),
configuration-loading variants such as `--ignore-user-config`, feature toggles, remote connection
options and image-list arguments are not interpreted by this launcher; use explicit project
registration for those forms. A failed native inspection launches no session.
Whole-table overrides such as `-c 'agents={}'` in the selected bucket are refused: a caller's later
table replacement would erase the newly registered personas. Individual settings such as
`-c 'agents.max_depth=2'` remain supported, subject to effective role collision checks.

Select a native role through the actual runtime selector, for example
`agent_type="tadeumendonca_quality_assurance"`. A task title or a generic child asked to impersonate
that role is not equivalent. If the selector is unavailable, report that missing capability. For an
independent gate use a fresh child without the author's conversation, retaining the canonical gate
criteria, holds and prohibition on the author merging their own work.

## Register an already-ignored consumer project configuration

For ordinary app/project sessions, the adapter also offers an explicit local installation. The target
must already be an existing, ignored, untracked `<project>/.codex/config.toml`. It refuses the library's
tracked configuration and user-level configuration. Preview `registration.toml` and verify the snapshot
first, then run:

```sh
python3 /path/to/library/scripts/codex-agent-build.py --source /path/to/library --output /path/to/local-storage/personas-v1 --install-config /path/to/consumer/.codex/config.toml --backup /path/to/local-storage/consumer-config-before.toml
```

The backup must be a new file outside the consumer project and is created with private permissions.
All original configuration bytes are preserved, and a delimited, checksummed registration block is
appended. A subsequent explicit installation can replace that block after verifying its checksum.
An existing user-owned role in the reserved namespace, an edited block, a tracked configuration or
an unsafe backup path causes refusal before replacing the configuration. An unchanged registration
is a no-op. The tool never adds an ignore rule or changes project trust. Native project configuration
still depends on the runtime loading that project; a successful file update alone does not prove it.
Restart a session and verify native selection. Keep snapshots referenced by any other active session.

## What the evidence means

The unit suite verifies the real roster, byte-preserving generation, resolution failures, source and
output drift, command-backed inputs and configuration preservation:

```sh
python3 scripts/codex-agent-build.test.py
```

The opt-in transport probe uses an installed executable and a generated profile. Exercise the real
launcher with the paired source/output arguments below; this removes the probe's own role overrides
so they cannot hide a broken registration path. Its fresh case
requires the full profile and no parent history; its unknown-role case requires a native rejection
and no child; its inherited-history control requires the parent marker to reach the child:

```sh
python3 scripts/codex-agent-probe.py codex /path/to/local-storage/personas-v1/profiles/tadeumendonca_quality_assurance.toml fresh --cwd /path/to/project --launcher-source /path/to/library --launcher-output /path/to/local-storage/personas-v1
python3 scripts/codex-agent-probe.py codex /path/to/local-storage/personas-v1/profiles/tadeumendonca_quality_assurance.toml unknown --cwd /path/to/project --launcher-source /path/to/library --launcher-output /path/to/local-storage/personas-v1
python3 scripts/codex-agent-probe.py codex /path/to/local-storage/personas-v1/profiles/tadeumendonca_quality_assurance.toml inherit --cwd /path/to/project --launcher-source /path/to/library --launcher-output /path/to/local-storage/personas-v1
```

Repeat with the other installed executable and every generated profile for a full transport matrix.
Each run prints its temporary artifact directory and returns nonzero when its expectation fails.
The inherited-history control creates a durable diagnostic thread because the measured builds cannot
fork an ephemeral parent's history. Other cases are ephemeral. Request captures remain local; they
can include the project's loaded instructions and should be reviewed before sharing.
Omitting the launcher arguments tests direct native registration only; that mode cannot verify the
launcher's argument composition. The summary records the actual executed wrapper command when used.

Native integration measurements are distinct from these fixtures. A local Responses stand-in can
capture the actual child model request and check that the complete profile reaches its input, and
that a parent-only marker is absent in a fresh child. That proves transport through the runtime;
the stand-in supplies synthetic answers and does not prove a model obeys every instruction. Real
model runs additionally establish native role metadata and child response provenance. Record the
executable version, source snapshot and exact command with each observation. No universal context
budget is inferred from the profiles that fit on the measured builds.

The canonical `tools:` frontmatter is included as source text. It does not become a Codex tool
allowlist, and `tools: []` is not mechanically enforced by this adapter. Native role metadata is not
proof that Claude hook authorization fields exist in Codex. Hook translation and trust, MCP tool
containment, observers, command invocation and artifact-only worklog resumption are separate
compatibility work. This adapter neither activates the installed Claude hook bundle nor weakens any
runtime permission check.
