#!/usr/bin/env python3
"""Build complete canonical personas for explicit native Codex session registration.

Python 3.11+, standard library only. Generated snapshots are local, never canonical.
"""

import argparse
import hashlib
import json
import os
import queue
import re
import subprocess
import sys
import tempfile
import threading
import tomllib
from pathlib import Path


class BuildError(Exception):
    """An actionable source, snapshot, or registration error."""


def digest(data):
    return hashlib.sha256(data).hexdigest()


def read_source(root, path):
    if not path.resolve().is_relative_to(root):
        raise BuildError(f"source escapes selected root: {path}")
    try:
        return path.read_bytes().decode("utf-8")
    except (OSError, UnicodeError) as error:
        raise BuildError(f"cannot read UTF-8 source {path}: {error}") from error


def scalar(value, context):
    value = value.strip()
    if value.startswith('"'):
        try:
            result, end = json.JSONDecoder().raw_decode(value)
        except ValueError as error:
            raise BuildError(f"invalid quoted scalar in {context}: {value}") from error
        suffix = value[end:].strip()
        if not isinstance(result, str) or (suffix and not suffix.startswith("#")):
            raise BuildError(f"invalid scalar suffix in {context}: {value}")
        return result
    if value.startswith("'"):
        match = re.fullmatch(r"'((?:[^']|'')*)'\s*(?:#.*)?", value)
        if not match:
            raise BuildError(f"invalid quoted scalar in {context}: {value}")
        return match[1].replace("''", "'")
    value = re.split(r"\s+#", value, maxsplit=1)[0].strip()
    if not value or value[0] in "|>{[&*!":
        raise BuildError(f"unsupported or empty scalar in {context}: {value!r}")
    return value


def flow_items(value, context):
    # Canonical preloads are scalar IDs, never arbitrary YAML. Reject other YAML
    # constructs instead of silently treating a partial parse as a complete list.
    match = re.fullmatch(r"\[(.*)\]\s*(?:#.*)?", value.strip())
    if not match:
        raise BuildError(f"invalid skills flow list in {context}")
    body = match[1].strip()
    if not body:
        return []
    parts = re.findall(r'''(?:"(?:\\.|[^"\\])*"|'(?:''|[^'])*'|[^,])+''', body)
    if ",".join(parts) != body or any(not part.strip() for part in parts):
        raise BuildError(f"invalid skills flow list in {context}")
    return [scalar(part, context) for part in parts]


def persona_metadata(text, context):
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        raise BuildError(f"missing frontmatter: {context}")
    try:
        end = lines.index("---", 1)
    except ValueError as error:
        raise BuildError(f"unterminated frontmatter: {context}") from error
    fields = {}
    current = None
    for line in lines[1:end]:
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        match = re.fullmatch(r"([a-zA-Z][a-zA-Z_-]*):\s*(.*)", line)
        if match:
            current, value = match.groups()
            if current in fields:
                raise BuildError(f"duplicate frontmatter key {current}: {context}")
            fields[current] = [value]
        elif current and line[0].isspace():
            fields[current].append(line)
        else:
            raise BuildError(f"unsupported frontmatter line: {context}: {line}")
    for required in ("name", "description", "skills"):
        if required not in fields:
            raise BuildError(f"missing {required}: {context}")
    for key in ("name", "description"):
        if len(fields[key]) != 1:
            raise BuildError(f"unsupported multiline {key}: {context}")
    name = scalar(fields["name"][0], context)
    description = scalar(fields["description"][0], context)
    values = fields["skills"]
    if values[0].strip():
        if len(values) != 1:
            raise BuildError(f"mixed skills list forms: {context}")
        skills = flow_items(values[0], context)
    else:
        skills = []
        for line in values[1:]:
            match = re.fullmatch(r"\s+-\s+(.+)", line)
            if not match:
                raise BuildError(f"unsupported skills entry: {context}: {line}")
            skills.append(scalar(match[1], context))
        if not skills:
            raise BuildError(f"empty skills must be explicit []: {context}")
    return name, description, skills


def resolve_preloads(root, identifiers, context):
    paths = []
    seen_ids = set()
    for identifier in identifiers:
        if identifier in seen_ids:
            raise BuildError(f"duplicate preload {identifier}: {context}")
        seen_ids.add(identifier)
        stem = identifier.removeprefix("plugin:").removeprefix("tadeumendonca-skills:")
        if not re.fullmatch(r"[a-zA-Z0-9_-]+", stem):
            raise BuildError(f"unsupported preload identifier {identifier}: {context}")
        matches = [path for path in (root / "skills" / stem / "SKILL.md", root / "commands" / f"{stem}.md") if path.is_file()]
        if len(matches) != 1:
            cause = "missing" if not matches else "ambiguous"
            raise BuildError(f"{cause} preload {identifier}: {context}")
        if matches[0] in paths:
            raise BuildError(f"duplicate resolved preload {identifier}: {context}: {matches[0]}")
        paths.append(matches[0])
    return paths


def json_bytes(value):
    return (json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode()


def snapshot(source, output):
    root = source.resolve()
    version = read_source(root, root / "VERSION").strip()
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        raise BuildError(f"invalid source VERSION: {version!r}")
    files = sorted((root / "agents").glob("*.md"))
    if not files:
        raise BuildError(f"no canonical personas: {root / 'agents'}")
    revision = None
    if (root / ".git").exists():
        result = subprocess.run(["git", "-C", str(root), "rev-parse", "HEAD"], capture_output=True, text=True, check=False)
        if result.returncode:
            raise BuildError(f"cannot identify selected checkout revision: {result.stderr.strip()}")
        revision = result.stdout.strip()
    # Hash the whole resolution inventory as well as the selected bodies: a new
    # command can make yesterday's unambiguous skill name ambiguous.
    inputs = {"VERSION": digest((root / "VERSION").read_bytes())}
    for path in files + sorted((root / "skills").glob("*/SKILL.md")) + sorted((root / "commands").glob("*.md")):
        body = read_source(root, path)
        inputs[str(path.relative_to(root))] = digest(body.encode())
    builder_hash = digest(Path(__file__).read_bytes())
    generated = {}
    roles = {}
    for path in files:
        brief = read_source(root, path)
        name, description, identifiers = persona_metadata(brief, str(path.relative_to(root)))
        if name != path.stem or not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", name):
            raise BuildError(f"persona name must match canonical filename: {path}: {name}")
        role = "tadeumendonca_" + name.replace("-", "_")
        if role in roles:
            raise BuildError(f"duplicate native role: {role}")
        preloads = resolve_preloads(root, identifiers, name)
        ordered = [path] + preloads
        instructions = (
            f"Canonical persona: {name}. Native Codex role: {role}.\n"
            f"Selected source root: {root}\nSource version: {version}; checkout revision: {revision or 'unavailable (installed/exported source)'}.\n"
            "The complete canonical brief and every declared preload follow verbatim. Source paths below resolve against the selected source root, not the consuming project. Project AGENTS.md and higher-priority runtime instructions still apply.\n"
            "Canonical frontmatter is preserved as source text. Its tools and model fields do not configure Codex tool restrictions or establish hook authorization identity. Native role selection proves profile selection only. Keep all actual permission checks, review separation, and the prohibition on the author merging their work.\n"
        )
        for item in ordered:
            relative = str(item.relative_to(root))
            body = read_source(root, item)
            instructions += f"\n--- BEGIN CANONICAL SOURCE {relative} sha256={digest(body.encode())} ---\n"
            instructions += body
            instructions += f"\n--- END CANONICAL SOURCE {relative} ---\n"
        profile = "# Generated by scripts/codex-agent-build.py; edit canonical sources, then rebuild.\n"
        for key, value in (("name", role), ("description", description), ("developer_instructions", instructions)):
            profile += f"{key} = {json.dumps(value, ensure_ascii=False)}\n"
        # Parse exactly what will be handed to the native loader.
        if tomllib.loads(profile)["developer_instructions"] != instructions:
            raise BuildError(f"profile serialization changed source bytes: {role}")
        relative_profile = f"profiles/{role}.toml"
        generated[relative_profile] = profile.encode()
        roles[role] = {"persona": str(path.relative_to(root)), "preloads": [str(item.relative_to(root)) for item in preloads], "profile": relative_profile, "instruction_bytes": len(instructions.encode())}
    registration = "# Explicit native session registration; this file is not auto-loaded.\n"
    for role, metadata in roles.items():
        registration += f"\n[agents.{role}]\nconfig_file = {json.dumps(str(output.resolve() / metadata['profile']), ensure_ascii=False)}\n"
        # The selector catalog needs a description even on native builds that
        # do not use the description from the role's config file.
        description = tomllib.loads(generated[metadata["profile"]].decode())["description"]
        registration += f"description = {json.dumps(description, ensure_ascii=False)}\n"
    generated["registration.toml"] = registration.encode()
    generated["source-manifest.json"] = json_bytes({"schema": 1, "source_root": str(root), "version": version, "revision": revision, "builder_sha256": builder_hash, "inputs": inputs, "roles": roles, "outputs": {name: digest(data) for name, data in generated.items()}})
    return generated


def check_snapshot(output, generated):
    if not output.is_dir():
        raise BuildError(f"snapshot is missing: {output}; build it first")
    actual = {str(path.relative_to(output)) for path in output.rglob("*") if path.is_file() or path.is_symlink()}
    if actual != set(generated):
        raise BuildError(f"snapshot inventory drift: missing={sorted(set(generated) - actual)}, unexpected={sorted(actual - set(generated))}")
    for name, expected in generated.items():
        path = output / name
        if path.is_symlink() or path.read_bytes() != expected:
            raise BuildError(f"snapshot content/source drift: {name}; rebuild into a new empty output directory")


def build_snapshot(output, generated):
    if output.exists() and any(output.iterdir()):
        # Never overwrite user files or a prior snapshot: explicit new output is
        # cheap, and it preserves the revision an in-flight review is using.
        check_snapshot(output, generated)
        return
    output.mkdir(parents=True, exist_ok=True)
    for name, data in generated.items():
        path = output / name
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("xb") as handle:
            handle.write(data)


def config_flags(generated):
    registration = tomllib.loads(generated["registration.toml"].decode())
    flags = []
    for role, settings in registration["agents"].items():
        for key, value in settings.items():
            flags.extend(["-c", f"agents.{role}.{key}={json.dumps(value, ensure_ascii=False)}"])
    return flags


def install_config(config, backup, generated):
    """Replace only a verified owned block in an already-ignored project config."""
    config = config.absolute()
    if config.is_symlink() or config.parent.is_symlink() or not config.is_file() or config.parts[-2:] != (".codex", "config.toml"):
        raise BuildError("--install-config requires an existing regular project .codex/config.toml")
    project = config.parent.parent.resolve()
    relative = ".codex/config.toml"
    tracked = subprocess.run(["git", "-C", str(project), "ls-files", "--error-unmatch", relative], capture_output=True, check=False)
    ignored = subprocess.run(["git", "-C", str(project), "check-ignore", "-q", relative], capture_output=True, check=False)
    if tracked.returncode == 0 or ignored.returncode != 0:
        raise BuildError("project config must already be ignored and untracked; tracked library config uses --exec")
    original = config.read_bytes()
    begin = b"# BEGIN tadeumendonca native personas sha256="
    end = b"# END tadeumendonca native personas\n"
    before, after = original, b""
    previous_roles = {}
    if begin in original or end in original:
        if original.count(begin) != 1 or original.count(end) != 1:
            raise BuildError("ambiguous managed registration block; preserve and inspect the config")
        start = original.index(begin)
        finish = original.index(end, start) + len(end)
        block = original[start:finish]
        header, content = block.split(b"\n", 1)
        content = content[:-len(end)]
        if header != begin + digest(content).encode():
            raise BuildError("managed registration block changed; refusing to overwrite it")
        previous_roles = tomllib.loads(content.decode()).get("agents", {})
        before, after = original[:start], original[finish:]
    parsed = tomllib.loads((before + after).decode())
    if any(role.startswith("tadeumendonca_") for role in parsed.get("agents", {})):
        raise BuildError("existing project role collides with agents.tadeumendonca_ namespace")
    registration = generated["registration.toml"]
    separator = b"" if not before or before.endswith(b"\n") else b"\n"
    updated = before + separator + begin + digest(registration).encode() + b"\n" + registration + end + after
    updated_values = tomllib.loads(updated.decode())
    original_values = tomllib.loads(original.decode())
    actual_previous = {key: value for key, value in original_values.get("agents", {}).items() if key.startswith("tadeumendonca_")}
    if actual_previous != previous_roles:
        raise BuildError("managed roles changed outside the owned block; refusing to overwrite their settings")
    for values in (updated_values, original_values):
        if isinstance(values.get("agents"), dict):
            values["agents"] = {key: value for key, value in values["agents"].items() if not key.startswith("tadeumendonca_")}
            if not values["agents"]:
                del values["agents"]
    if updated_values != original_values:
        raise BuildError("registration would change unrelated parsed configuration values")
    if updated == original:
        return False
    if backup is None:
        raise BuildError("--install-config requires --backup to a new file outside the project")
    backup = backup.absolute()
    if backup.resolve().is_relative_to(project):
        raise BuildError("backup must be outside the consuming project")
    # Exclusive, private backup. Temporary replacement stays in the harness's
    # scratch space; cross-device rename fails without touching the config.
    with open(backup, "xb", opener=lambda path, flags: os.open(path, flags, 0o600)) as handle:
        handle.write(original)
    with tempfile.TemporaryDirectory(prefix="codex-persona-config-") as temporary:
        replacement = Path(temporary) / "config.toml"
        replacement.write_bytes(updated)
        replacement.chmod(config.stat().st_mode & 0o777)
        if config.is_symlink() or config.read_bytes() != original:
            raise BuildError("project config changed during registration; backup retained, config not replaced")
        os.replace(replacement, config)
    return True


def inspect_session_roles(command, generated):
    """Read effective native settings before adding session role overrides."""
    overrides = []
    cwd = Path.cwd()
    arguments = iter(command[1:])
    for argument in arguments:
        if argument == "--":
            break
        if argument in ("-p", "--profile") or argument.startswith("--profile=") or (argument.startswith("-p") and not argument.startswith("--")):
            raise BuildError("--exec does not inspect named configuration profiles; use explicit project registration for --profile")
        if argument in ("-c", "--config", "-C", "--cd"):
            value = next(arguments, None)
            if value is None:
                raise BuildError(f"missing value for {argument}")
            if argument in ("-C", "--cd"):
                cwd = Path(value).resolve()
            else:
                overrides.extend(["-c", value])
        elif argument.startswith("--config="):
            overrides.extend(["-c", argument.split("=", 1)[1]])
        elif argument.startswith("-c") and not argument.startswith("--"):
            overrides.extend(["-c", argument[2:]])
        elif argument.startswith("--cd="):
            cwd = Path(argument.split("=", 1)[1]).resolve()
        elif argument.startswith("-C") and not argument.startswith("--"):
            cwd = Path(argument[2:]).resolve()
    expected = tomllib.loads(generated["registration.toml"].decode())["agents"]
    process = subprocess.Popen([command[0], "app-server", "--stdio", *overrides], cwd=cwd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    messages = queue.Queue()

    def receive():
        for line in process.stdout:
            try:
                messages.put(json.loads(line))
            except ValueError:
                messages.put(None)
        messages.put(None)

    threading.Thread(target=receive, daemon=True).start()

    def call(identifier, method, params):
        process.stdin.write(json.dumps({"id": identifier, "method": method, "params": params}) + "\n")
        process.stdin.flush()
        # Bounded independently of notification traffic from the local process.
        import time
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            try:
                response = messages.get(timeout=max(0.01, deadline - time.monotonic()))
            except queue.Empty as error:
                raise BuildError("effective configuration inspection timed out; no session launched") from error
            if response is None:
                raise BuildError("native app-server ended before configuration inspection; no session launched")
            if response.get("id") == identifier and "method" not in response:
                if "error" in response:
                    raise BuildError(f"native {method} failed; no session launched")
                return response.get("result", {})
        raise BuildError("effective configuration inspection timed out; no session launched")

    try:
        call(1, "initialize", {"clientInfo": {"name": "codex-persona-registration", "version": "1"}})
        result = call(2, "config/read", {"cwd": str(cwd), "includeLayers": False})
        if not isinstance(result.get("config"), dict):
            raise BuildError("native config/read returned no effective configuration; no session launched")
        roles = result["config"].get("agents") or {}
        if not isinstance(roles, dict):
            raise BuildError("native config/read returned an unsupported agents shape; no session launched")
        for role, settings in roles.items():
            if not role.startswith("tadeumendonca_"):
                continue
            if role not in expected or not isinstance(settings, dict) or any(settings.get(key) != value for key, value in expected[role].items()):
                raise BuildError(f"effective native role collision: {role}; choose the intended project registration before launching")
    finally:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
        process.stdin.close()
        process.stdout.close()


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True, help="explicit library checkout or installed plugin root")
    parser.add_argument("--output", type=Path, required=True, help="dedicated local snapshot directory outside the source tree")
    parser.add_argument("--check", action="store_true", help="check source and all output bytes without writing")
    parser.add_argument("--install-config", type=Path, help="explicitly register snapshot in an existing ignored project .codex/config.toml")
    parser.add_argument("--backup", type=Path, help="new private backup file outside the consuming project, required when config changes")
    parser.add_argument("--exec", dest="command", nargs=argparse.REMAINDER, help="check snapshot, then launch CODEX [arguments...] with native session registrations")
    args = parser.parse_args(argv)
    try:
        source, output = args.source.resolve(), args.output.absolute()
        if output.is_symlink() or output.resolve().is_relative_to(source) or source.is_relative_to(output.resolve()):
            raise BuildError("output must be a dedicated non-symlink directory outside the selected source tree")
        generated = snapshot(source, output)
        if args.check and args.install_config:
            raise BuildError("--check cannot mutate project configuration")
        if args.install_config and args.command is not None:
            raise BuildError("choose --install-config or --exec in one invocation")
        if args.backup and not args.install_config:
            raise BuildError("--backup requires --install-config")
        if args.check or args.command is not None or args.install_config:
            check_snapshot(output, generated)
        else:
            build_snapshot(output, generated)
        if args.install_config:
            changed = install_config(args.install_config, args.backup, generated)
            print(f"{'Registered' if changed else 'Already registered'} native profiles: {args.install_config}")
            return 0
        if args.command is not None:
            if not args.command:
                raise BuildError("--exec requires the Codex executable and optional arguments")
            # Namespaced registrations are explicit session overrides. Refuse a
            # caller-supplied override of this namespace rather than masking it.
            if any("agents.tadeumendonca_" in argument for argument in args.command[1:]):
                raise BuildError("caller arguments collide with the generated agents.tadeumendonca_ namespace")
            inspect_session_roles(args.command, generated)
            return subprocess.run([args.command[0], *config_flags(generated), *args.command[1:]], check=False).returncode
        print(f"{'Checked' if args.check else 'Built'} {len(tomllib.loads(generated['registration.toml'].decode())['agents'])} native profiles: {output}")
        return 0
    except (BuildError, OSError, tomllib.TOMLDecodeError) as error:
        print(f"codex-agent-build: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
