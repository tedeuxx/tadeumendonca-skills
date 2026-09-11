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
the precise snapshot used by an in-flight review.

## Activate a session without changing configuration

Run the launcher from the project being worked on, with the Codex executable and its ordinary
arguments after `--exec`:

```sh
python3 /path/to/library/scripts/codex-agent-build.py --source /path/to/library --output /path/to/local-storage/personas-v1 --exec codex
```

The launcher checks the snapshot and reads the native effective configuration through `config/read`
before supplying explicit native session configuration flags. A conflicting role in its namespace
causes refusal; an identical existing registration is allowed. It keeps
the caller's working directory and arguments. It writes no user or project configuration, changes no
MCP settings or permission settings, and adds no hook trust. The same command works with an explicitly
selected installed plugin root as `--source` and the builder shipped in that version. The source may
be outside the consuming repository. Existing profiles in other namespaces are unaffected;
`tadeumendonca_` is this adapter's reserved role namespace. Caller flags attempting to overwrite that
namespace are refused. Session registration is limited to the session launched this way. `-c`/`--config`
and `-C`/`--cd` are included in the effective-configuration inspection. Named configuration selection
through `-p`/`--profile` is refused by the launcher because that selection is not inspected here;
use explicit project registration for those sessions. A failed native inspection launches no session.

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

The opt-in transport probe uses an installed executable and a generated profile. Its fresh case
requires the full profile and no parent history; its unknown-role case requires a native rejection
and no child; its inherited-history control requires the parent marker to reach the child:

```sh
python3 scripts/codex-agent-probe.py codex /path/to/local-storage/personas-v1/profiles/tadeumendonca_quality_assurance.toml fresh --cwd /path/to/project
python3 scripts/codex-agent-probe.py codex /path/to/local-storage/personas-v1/profiles/tadeumendonca_quality_assurance.toml unknown --cwd /path/to/project
python3 scripts/codex-agent-probe.py codex /path/to/local-storage/personas-v1/profiles/tadeumendonca_quality_assurance.toml inherit --cwd /path/to/project
```

Repeat with the other installed executable and every generated profile for a full transport matrix.
Each run prints its temporary artifact directory and returns nonzero when its expectation fails.
The inherited-history control creates a durable diagnostic thread because the measured builds cannot
fork an ephemeral parent's history. Other cases are ephemeral. Request captures remain local; they
can include the project's loaded instructions and should be reviewed before sharing.

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
