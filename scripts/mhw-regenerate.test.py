#!/usr/bin/env python3
# purpose: gate every transform of scripts/mhw-regenerate.py on a fixture, so a regeneration cannot silently overwrite a plugin-owned file, lose a transform or stop being reproducible from its tag
"""Tests for scripts/mhw-regenerate.py, against a throwaway mhw repository with real tags.

Each test names the intake row (mhw#191) it covers. Run: python3 scripts/mhw-regenerate.test.py
"""

import importlib.util
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("mhw_regenerate", HERE / "mhw-regenerate.py")
regen = importlib.util.module_from_spec(spec)
spec.loader.exec_module(regen)

GIT_ENV = dict(os.environ, GIT_AUTHOR_NAME="t", GIT_AUTHOR_EMAIL="t@t", GIT_COMMITTER_NAME="t",
               GIT_COMMITTER_EMAIL="t@t", GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1")

SKILL = '''---
name: "alpha"
description: "Apply alpha in any `<project>` repo. Use when alpha. Not for beta (see beta)."
purpose: "keep alpha in one place, because a copy in every brief rots"
---

Body of alpha. Run `python3 {{method-scripts}}/tool.py` and read `{{method-scripts}}/tool-contract/README.md`.
`{{method-scripts}}` is the directory.
'''
AGENT = '''---
name: "lead"
description: "The pair: it names scenarios"
purpose: "give the owner a pair on the machinery, so effects are named before they ship"
tools: "Read, Grep, Bash"
skills:
  - alpha
---

Agent body.
'''
COMMAND = '''---
name: "go"
description: "Run the go rite end to end. Use when the owner types it."
purpose: "put the go rite behind one command so it cannot be entered by accident"
argument-hint: "on [repo] | off [repo]"
---

Command body, calling {{method-scripts}}/tool.py for {{agent-harness}}.
'''


def git(cwd, *args):
    return subprocess.run(["git", "-C", str(cwd), *args], check=True, capture_output=True, env=GIT_ENV).stdout.decode()


class Fixture:
    """A fake mhw source repository and a fake plugin target, in one temporary directory."""

    def __init__(self, root):
        self.root = Path(root)
        self.source = self.root / "mhw"
        self.target = self.root / "plugin"
        self.files = {
            "method/README.md": "method readme, not carried\n",
            "method/skills/alpha/SKILL.md": SKILL,
            "method/agents/lead.md": AGENT,
            "method/commands/go.md": COMMAND,
            "method/scripts/tool.py": "print('tool')\n",
            "method/scripts/tool.test.py": "print('mhw test, not carried')\n",
            "method/scripts/tool-contract/README.md": "contract\n",
            "method/scripts/fixtures/sample.tsv": "fixture, not carried\n",
        }
        self.source.mkdir()
        git(self.source, "init", "-q", "-b", "main")
        self.tag("v1.0.0")
        self.make_target()

    def write_source(self):
        for rel, text in self.files.items():
            path = self.source / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")
        (self.source / "method/scripts/tool.py").chmod(0o755)

    def tag(self, name):
        for path in (self.source / "method").rglob("*") if (self.source / "method").exists() else []:
            if path.is_file():
                path.unlink()
        self.write_source()
        git(self.source, "add", "-A")
        git(self.source, "commit", "-q", "-m", name, "--allow-empty")
        git(self.source, "tag", name)
        return git(self.source, "rev-parse", "HEAD").strip()

    def make_target(self):
        t = self.target
        for rel, text in {
            "skills/devops/SKILL.md": "---\ndescription: plugin-owned\n---\nkeep me\n",
            "skills/backend/SKILL.md": "---\ndescription: plugin-owned\n---\nkeep me too\n",
            "scripts/codex-thing.py": "plugin-only script\n",
            "README.md": "plugin readme\n",
            ".claude-plugin/marketplace.json": '{"description": "and 2 generic skills"}\n',
        }.items():
            (t / rel).parent.mkdir(parents=True, exist_ok=True)
            (t / rel).write_text(text, encoding="utf-8")
        manifest = {"name": "p", "description": "1 subagent personas and 2 generic skills",
                    "skills": ["./skills/backend", "./skills/devops"]}
        (t / ".claude-plugin/plugin.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        (t / "agents").mkdir()
        (t / "commands").mkdir()

    def run(self, tag="v1.0.0"):
        return regen.regenerate(self.source, tag, self.target, powers=False)

    def snapshot(self):
        return {str(p.relative_to(self.target)): p.read_bytes() for p in self.target.rglob("*") if p.is_file()}


class RegenerateTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.fx = Fixture(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def read(self, rel):
        return (self.fx.target / rel).read_text(encoding="utf-8")

    # AC1 · the source is a tag, read from git objects
    def test_refuses_a_missing_tag(self):
        with self.assertRaises(regen.RegenError) as ctx:
            self.fx.run("v9.9.9")
        self.assertEqual(ctx.exception.code, 2)

    def test_refuses_a_branch_or_non_semver_name(self):
        for name in ("main", "HEAD", "v1.0"):
            with self.assertRaises(regen.RegenError) as ctx:
                self.fx.run(name)
            self.assertEqual(ctx.exception.code, 2, name)

    def test_refuses_a_branch_named_like_a_release(self):
        git(self.fx.source, "branch", "v3.0.0")
        with self.assertRaises(regen.RegenError) as ctx:
            self.fx.run("v3.0.0")
        self.assertEqual(ctx.exception.code, 2)

    def test_reads_the_tag_not_the_working_tree(self):
        (self.fx.source / "method/agents/lead.md").write_text(AGENT.replace("Agent body.", "DIRTY EDIT"))
        self.fx.run()
        self.assertIn("Agent body.", self.read("agents/lead.md"))
        self.assertNotIn("DIRTY EDIT", self.read("agents/lead.md"))

    # M1 · `name:` dropped from skills and commands, kept on agents
    def test_m1_name_key(self):
        self.fx.run()
        self.assertNotIn("\nname:", self.read("skills/alpha/SKILL.md"))
        self.assertNotIn("\nname:", self.read("commands/go.md"))
        self.assertIn("\nname: lead\n", self.read("agents/lead.md"))

    # M2 · bare scalars where YAML allows, quoted where it does not, argument-hint always quoted
    def test_m2_scalars(self):
        self.fx.run()
        skill = self.read("skills/alpha/SKILL.md")
        self.assertIn("\ndescription: Apply alpha in any `<project>` repo.", skill)
        self.assertIn("\npurpose: keep alpha in one place, because a copy in every brief rots\n", skill)
        agent = self.read("agents/lead.md")
        self.assertIn('\ndescription: "The pair: it names scenarios"\n', agent)
        self.assertIn("\ntools: Read, Grep, Bash\n", agent)
        self.assertIn("\nskills:\n  - alpha\n", agent)
        self.assertIn('\nargument-hint: "on [repo] | off [repo]"\n', self.read("commands/go.md"))

    def test_m2_plain_safe(self):
        for value in ("a: b", "an sp:N weight", "x #1", "-lead", "`code` first", "true", "123", "trailing:", " pad"):
            self.assertFalse(regen.plain_safe(value), value)
        for value in ("Apply it — any repo's `<project>`", "Read, Grep", "issue#12 and more"):
            self.assertTrue(regen.plain_safe(value), value)

    # M3 · tokens rendered, and a dangling target refuses the run
    def test_m3_tokens(self):
        self.fx.run()
        skill = self.read("skills/alpha/SKILL.md")
        self.assertNotIn("{{method-scripts}}", skill)
        self.assertIn("`python3 scripts/tool.py`", skill)
        self.assertIn("`scripts/tool-contract/README.md`", skill)
        self.assertIn("\n`scripts` is the directory.", skill)
        self.assertIn("calling scripts/tool.py", self.read("commands/go.md"))

    # M3 · {{agent-harness}} rendered to claude-code in a command body (mhw#198), refused elsewhere
    def test_m3_agent_harness_in_a_command(self):
        self.fx.run()
        command = self.read("commands/go.md")
        self.assertNotIn("{{agent-harness}}", command)
        self.assertIn("calling scripts/tool.py for claude-code.", command)

    def test_m3_agent_harness_outside_a_command_refuses_before_writing(self):
        for tag, rel, text in (("v1.0.2", "method/agents/lead.md", AGENT),
                               ("v1.0.3", "method/skills/alpha/SKILL.md", SKILL)):
            self.fx.files[rel] = text + "For {{agent-harness}}.\n"
            self.fx.tag(tag)
            before = self.fx.snapshot()
            with self.assertRaises(regen.RegenError) as ctx:
                self.fx.run(tag)
            self.assertEqual(ctx.exception.code, 4, rel)
            self.assertEqual(self.fx.snapshot(), before, rel)
            self.fx.files[rel] = text

    def test_m3_dangling_target_refuses_before_writing(self):
        self.fx.files["method/commands/go.md"] = COMMAND.replace("tool.py", "missing.py")
        self.fx.tag("v1.0.1")
        before = self.fx.snapshot()
        with self.assertRaises(regen.RegenError) as ctx:
            self.fx.run("v1.0.1")
        self.assertEqual(ctx.exception.code, 4)
        self.assertEqual(self.fx.snapshot(), before)

    # S1 · scripts and contract directories carried; tests and fixtures not; exec bit kept
    def test_s1_scripts(self):
        self.fx.run()
        t = self.fx.target
        self.assertTrue((t / "scripts/tool.py").exists())
        self.assertTrue(os.access(t / "scripts/tool.py", os.X_OK))
        self.assertTrue((t / "scripts/tool-contract/README.md").exists())
        self.assertFalse((t / "scripts/tool.test.py").exists())
        self.assertFalse((t / "scripts/fixtures").exists())
        self.assertFalse((t / "method").exists())
        self.assertFalse((t / "README.md").read_text().startswith("method readme"))

    # Q1 / S2 · a file outside the carrier map is never written or deleted
    def test_plugin_owned_files_untouched(self):
        before = self.fx.snapshot()
        self.fx.run()
        after = self.fx.snapshot()
        for rel in ("skills/devops/SKILL.md", "skills/backend/SKILL.md", "scripts/codex-thing.py", "README.md"):
            self.assertEqual(after[rel], before[rel], rel)

    def test_first_run_refuses_to_overwrite_a_declared_plugin_owned_path(self):
        self.fx.files["method/skills/devops/SKILL.md"] = SKILL.replace('"alpha"', '"devops"', 1)
        self.fx.tag("v1.0.1")
        before = self.fx.snapshot()
        with self.assertRaises(regen.RegenError) as ctx:
            self.fx.run("v1.0.1")
        self.assertEqual(ctx.exception.code, 3)
        self.assertEqual(self.fx.snapshot(), before)

    def test_later_run_refuses_to_overwrite_any_path_it_did_not_generate(self):
        self.fx.run()
        (self.fx.target / "commands/stop.md").write_text("plugin-authored command\n")
        self.fx.files["method/commands/stop.md"] = COMMAND.replace('"go"', '"stop"', 1)
        self.fx.tag("v1.1.0")
        with self.assertRaises(regen.RegenError) as ctx:
            self.fx.run("v1.1.0")
        self.assertEqual(ctx.exception.code, 3)
        self.assertEqual(self.read("commands/stop.md"), "plugin-authored command\n")

    # The one deletion: a path the previous watermark generated and the new tag dropped
    def test_deletes_only_what_it_generated(self):
        self.fx.run()
        del self.fx.files["method/commands/go.md"]
        self.fx.files["method/skills/alpha/SKILL.md"] = SKILL.replace(
            "Run `python3 {{method-scripts}}/tool.py` and", "Read")
        self.fx.tag("v2.0.0")
        _, report = self.fx.run("v2.0.0")
        self.assertEqual(report["deleted"], ["commands/go.md"])
        self.assertFalse((self.fx.target / "commands/go.md").exists())
        self.assertTrue((self.fx.target / "skills/devops/SKILL.md").exists())
        self.assertTrue((self.fx.target / "scripts/codex-thing.py").exists())

    # AC3 · idempotent
    def test_idempotent(self):
        self.fx.run()
        first = self.fx.snapshot()
        _, report = self.fx.run()
        self.assertEqual(report["written"], [])
        self.assertEqual(report["deleted"], [])
        self.assertEqual(self.fx.snapshot(), first)

    # M4 · manifest skills array and counts
    def test_m4_manifest(self):
        self.fx.run()
        manifest = json.loads(self.read(".claude-plugin/plugin.json"))
        self.assertEqual(manifest["skills"], ["./skills/backend", "./skills/devops", "./skills/alpha"])
        self.assertIn("1 subagent personas and 3 generic skills", manifest["description"])
        self.assertIn("and 3 generic skills", self.read(".claude-plugin/marketplace.json"))

    # M9 · watermark
    def test_m9_watermark(self):
        commit, _ = self.fx.run()
        mark = self.read(".mhw-regenerated")
        self.assertIn("\ntag: v1.0.0\n", mark)
        self.assertIn("\ncommit: %s\n" % commit, mark)
        self.assertIn("\n  agents/lead.md\n", mark)
        self.assertNotIn("skills/devops", mark)

    # An unknown source layout refuses rather than being silently skipped
    def test_unmapped_source_refuses(self):
        self.fx.files["method/hooks/x.sh"] = "echo\n"
        self.fx.tag("v1.0.1")
        with self.assertRaises(regen.RegenError) as ctx:
            self.fx.run("v1.0.1")
        self.assertEqual(ctx.exception.code, 4)

    def test_cli_exit_code(self):
        proc = subprocess.run(["python3", str(HERE / "mhw-regenerate.py"), "--source", str(self.fx.source),
                               "--tag", "v9.9.9", "--target", str(self.fx.target)], capture_output=True)
        self.assertEqual(proc.returncode, 2)


if __name__ == "__main__":
    unittest.main(verbosity=1)
