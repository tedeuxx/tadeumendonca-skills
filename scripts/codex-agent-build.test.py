#!/usr/bin/env python3
"""Source/generation/activation contracts; no model or native runtime simulated as proof."""

import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import tomllib
import unittest


sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("builder", ROOT / "scripts/codex-agent-build.py")
BUILDER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BUILDER)


class Profiles(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="codex-personas-")
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name)
        self.source = self.base / "source"
        self.output = self.base / "snapshot"
        self.source.mkdir()
        self.write("VERSION", "1.2.3\n")
        self.write("skills/knowledge/SKILL.md", "---\nname: knowledge\n---\nFull knowledge café\r\nTail marker.\n")
        self.persona()

    def write(self, path, body):
        target = self.source / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(body.encode())

    def persona(self, skills="[knowledge]"):
        self.write("agents/reader.md", f'---\nname: reader\ndescription: "Read complete sources."\ntools: []\nskills: {skills}\n---\nCanonical body.\n')

    def snapshot(self):
        return BUILDER.snapshot(self.source, self.output)

    def fails(self, message):
        with self.assertRaisesRegex(BUILDER.BuildError, message):
            self.snapshot()

    def test_complete_exact_sources_and_determinism(self):
        first = self.snapshot()
        self.assertEqual(first, self.snapshot())
        profile = tomllib.loads(first["profiles/tadeumendonca_reader.toml"].decode())
        self.assertEqual(set(profile), {"name", "description", "developer_instructions"})
        for relative in ("agents/reader.md", "skills/knowledge/SKILL.md"):
            body = (self.source / relative).read_bytes().decode()
            self.assertIn(body, profile["developer_instructions"])
        self.assertIn("do not configure Codex tool restrictions", profile["developer_instructions"])
        manifest = json.loads(first["source-manifest.json"])
        self.assertEqual(manifest["version"], "1.2.3")
        self.assertIsNone(manifest["revision"])
        BUILDER.build_snapshot(self.output, first)
        BUILDER.check_snapshot(self.output, first)
        BUILDER.build_snapshot(self.output, first)

    def test_entire_live_roster_and_resolution_inventory(self):
        generated = BUILDER.snapshot(ROOT, self.output)
        manifest = json.loads(generated["source-manifest.json"])
        canonical = sorted(ROOT.glob("agents/*.md"))
        self.assertGreater(len(canonical), 0)
        self.assertEqual(len(canonical), len(manifest["roles"]))
        for role, metadata in manifest["roles"].items():
            instructions = tomllib.loads(generated[metadata["profile"]].decode())["developer_instructions"]
            for relative in [metadata["persona"], *metadata["preloads"]]:
                self.assertIn((ROOT / relative).read_bytes().decode(), instructions, (role, relative))
            self.assertEqual(len(instructions.encode()), metadata["instruction_bytes"])
        expected = {str(path.relative_to(ROOT)) for pattern in ("agents/*.md", "skills/*/SKILL.md", "commands/*.md") for path in ROOT.glob(pattern)} | {"VERSION"}
        self.assertEqual(expected, set(manifest["inputs"]))

    def test_command_and_supported_prefixes(self):
        self.write("commands/action.md", "Entire command.\n")
        self.persona('\n  - "plugin:knowledge"\n  - \'tadeumendonca-skills:action\' # comment')
        manifest = json.loads(self.snapshot()["source-manifest.json"])
        self.assertEqual(manifest["roles"]["tadeumendonca_reader"]["preloads"], ["skills/knowledge/SKILL.md", "commands/action.md"])
        self.persona('["plugin:tadeumendonca-skills:knowledge", action]')
        self.snapshot()

    def test_empty_preload_is_explicit(self):
        self.persona("[]")
        self.snapshot()
        self.persona("")
        self.fails("empty skills must be explicit")

    def test_missing_ambiguous_and_duplicate_preloads(self):
        self.persona("[absent]")
        self.fails("missing preload absent")
        self.persona("[knowledge, knowledge]")
        self.fails("duplicate preload knowledge")
        self.persona("[knowledge, plugin:knowledge]")
        self.fails("duplicate resolved preload")
        self.persona()
        self.write("commands/knowledge.md", "Collision.")
        self.fails("ambiguous preload knowledge")

    def test_reject_unresolved_yaml_and_identifier_forms(self):
        for skills in ("[old:knowledge]", "[../knowledge]", "[knowledge/*]", "[knowledge,,knowledge]", "[knowledge,]", "&anchor [knowledge]"):
            with self.subTest(skills=skills):
                self.persona(skills)
                self.fails("unsupported|invalid")
        self.write("agents/reader.md", "---\nname: reader\ndescription: hi\n---\nBody")
        self.fails("missing skills")
        self.write("agents/reader.md", "---\nname: reader\nname: reader\ndescription: hi\nskills: []\n---\n")
        self.fails("duplicate frontmatter key")

    def test_roster_name_and_symlink_sources(self):
        self.write("agents/renamed.md", (self.source / "agents/reader.md").read_text())
        self.fails("name must match canonical filename")
        (self.source / "agents/renamed.md").unlink()
        external = self.base / "external.md"
        external.write_text("Outside source")
        skill = self.source / "skills/knowledge/SKILL.md"
        skill.unlink()
        skill.symlink_to(external)
        self.fails("source escapes selected root")

    def test_drift_detects_source_output_inventory_and_new_ambiguity(self):
        generated = self.snapshot()
        BUILDER.build_snapshot(self.output, generated)
        self.write("skills/knowledge/SKILL.md", "Changed last line.")
        with self.assertRaisesRegex(BUILDER.BuildError, "drift"):
            BUILDER.check_snapshot(self.output, self.snapshot())
        with self.assertRaisesRegex(BUILDER.BuildError, "drift"):
            BUILDER.build_snapshot(self.output, self.snapshot())
        profile = self.output / "profiles/tadeumendonca_reader.toml"
        profile.write_text(profile.read_text() + "# mutation\n")
        with self.assertRaisesRegex(BUILDER.BuildError, "drift"):
            BUILDER.check_snapshot(self.output, generated)
        (self.output / "unexpected").write_text("preserve me")
        with self.assertRaisesRegex(BUILDER.BuildError, "inventory drift"):
            BUILDER.check_snapshot(self.output, generated)
        self.assertEqual((self.output / "unexpected").read_text(), "preserve me")
        self.write("commands/knowledge.md", "New resolution collision")
        self.fails("ambiguous preload")

    def test_launcher_changes_no_configuration_or_source(self):
        generated = self.snapshot()
        BUILDER.build_snapshot(self.output, generated)
        consumer = self.base / "consumer"
        (consumer / ".codex").mkdir(parents=True)
        config = consumer / ".codex/config.toml"
        original = b'# Keep whitespace and comments.\n[mcp_servers.example]\ncommand = "original"\n[agents.other]\ndescription = "keep"\n'
        config.write_bytes(original)
        fake = self.base / "capture-codex"
        fake.write_text(f"#!{sys.executable}\nimport json, sys, pathlib, tomllib\nif 'app-server' in sys.argv:\n for line in sys.stdin:\n  request=json.loads(line)\n  result={{}} if request['id']==1 else {{'config':tomllib.loads(pathlib.Path('.codex/config.toml').read_text())}}\n  print(json.dumps({{'id':request['id'],'result':result}}),flush=True)\nelse:\n print(json.dumps(sys.argv[1:]))\n")
        fake.chmod(0o700)
        command = [sys.executable, str(ROOT / "scripts/codex-agent-build.py"), "--source", str(self.source), "--output", str(self.output), "--exec", str(fake), "exec", "--sandbox", "read-only", "message"]
        result = subprocess.run(command, cwd=consumer, capture_output=True, text=True, check=True)
        arguments = json.loads(result.stdout)
        self.assertIn('agents.tadeumendonca_reader.config_file=' + json.dumps(str(self.output.resolve() / "profiles/tadeumendonca_reader.toml")), arguments)
        self.assertEqual(arguments[-4:], ["exec", "--sandbox", "read-only", "message"])
        self.assertEqual(config.read_bytes(), original)
        self.assertEqual(self.snapshot(), generated)
        result = subprocess.run(command + ["-c", 'agents.tadeumendonca_reader.description="collision"'], capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("collide", result.stderr)
        config.write_bytes(original + b'\n[agents.tadeumendonca_reader]\nconfig_file="other.toml"\ndescription="user-owned"\n')
        result = subprocess.run(command, cwd=consumer, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("effective native role collision", result.stderr)
        config.write_bytes(original)
        result = subprocess.run(command + ["--profile=other"], cwd=consumer, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("named configuration profiles", result.stderr)

    def test_cli_check_does_not_create_missing_snapshot(self):
        status = BUILDER.main(["--source", str(self.source), "--output", str(self.output), "--check"])
        self.assertEqual(status, 1)
        self.assertFalse(self.output.exists())

    def consumer_config(self):
        consumer = self.base / "consumer"
        consumer.mkdir()
        subprocess.run(["git", "init", "-q", str(consumer)], check=True)
        (consumer / ".gitignore").write_text(".codex/config.toml\n")
        (consumer / ".codex").mkdir()
        config = consumer / ".codex/config.toml"
        config.write_bytes(b'# Keep this exact byte sequence.\r\ndeveloper_instructions = "operating entry"\r\n[mcp_servers.existing]\r\ncommand = "unchanged"\r\n[agents.unrelated]\r\ndescription = "keep"\r\n')
        return config

    def test_ignored_consumer_install_update_and_backup_preserve_original(self):
        config = self.consumer_config()
        original = config.read_bytes()
        generated = self.snapshot()
        backup = self.base / "config-before.toml"
        self.assertTrue(BUILDER.install_config(config, backup, generated))
        self.assertEqual(backup.read_bytes(), original)
        self.assertEqual(backup.stat().st_mode & 0o777, 0o600)
        self.assertTrue(config.read_bytes().startswith(original))
        parsed = tomllib.loads(config.read_text())
        self.assertEqual(parsed["developer_instructions"], "operating entry")
        self.assertEqual(parsed["agents"]["unrelated"]["description"], "keep")
        self.assertFalse(BUILDER.install_config(config, None, generated))
        previous = config.read_bytes()
        self.output = self.base / "new-snapshot"
        self.assertTrue(BUILDER.install_config(config, self.base / "config-update-backup.toml", self.snapshot()))
        self.assertEqual((self.base / "config-update-backup.toml").read_bytes(), previous)
        self.assertTrue(config.read_bytes().startswith(original))
        self.assertEqual(config.read_bytes().count(b"# BEGIN tadeumendonca"), 1)
        self.assertIn("new-snapshot", config.read_text())

    def test_config_registration_refuses_tracked_colliding_and_edited_blocks(self):
        config = self.consumer_config()
        original = config.read_bytes()
        generated = self.snapshot()
        config.write_bytes(original + b'\n[agents.tadeumendonca_reader]\ndescription="user-owned"\n')
        with self.assertRaisesRegex(BUILDER.BuildError, "collides"):
            BUILDER.install_config(config, self.base / "no-backup", generated)
        self.assertFalse((self.base / "no-backup").exists())
        config.write_bytes(original)
        subprocess.run(["git", "-C", str(config.parent.parent), "add", "-f", ".codex/config.toml"], check=True)
        with self.assertRaisesRegex(BUILDER.BuildError, "ignored and untracked"):
            BUILDER.install_config(config, self.base / "no-backup", generated)
        subprocess.run(["git", "-C", str(config.parent.parent), "rm", "--cached", "-q", ".codex/config.toml"], check=True)
        BUILDER.install_config(config, self.base / "before", generated)
        config.write_text(config.read_text().replace("Read complete sources.", "Manually changed."))
        with self.assertRaisesRegex(BUILDER.BuildError, "block changed"):
            BUILDER.install_config(config, self.base / "no-backup", generated)

    def test_registration_requires_safe_backup_without_writing_config(self):
        config = self.consumer_config()
        original = config.read_bytes()
        for backup in (None, config.parent / "backup"):
            with self.assertRaisesRegex(BUILDER.BuildError, "backup"):
                BUILDER.install_config(config, backup, self.snapshot())
            self.assertEqual(config.read_bytes(), original)

    def test_managed_block_cannot_capture_later_table_scoped_user_settings(self):
        config = self.consumer_config()
        generated = self.snapshot()
        BUILDER.install_config(config, self.base / "before", generated)
        config.write_bytes(config.read_bytes() + b'nickname_candidates=["private choice"]\n')
        original = config.read_bytes()
        with self.assertRaisesRegex(BUILDER.BuildError, "outside the owned block"):
            BUILDER.install_config(config, self.base / "no-backup", generated)
        self.assertEqual(config.read_bytes(), original)

    def test_registration_cannot_change_unrelated_parsed_values(self):
        config = self.consumer_config()
        original = config.read_bytes()
        generated = self.snapshot()
        generated["registration.toml"] += b'\n[unexpected_setting]\nvalue="mutation"\n'
        with self.assertRaisesRegex(BUILDER.BuildError, "unrelated parsed"):
            BUILDER.install_config(config, self.base / "no-backup", generated)
        self.assertEqual(config.read_bytes(), original)


if __name__ == "__main__":
    unittest.main()
