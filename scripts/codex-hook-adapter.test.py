#!/usr/bin/env python3
"""Gate for the Codex floor adapter and its carrier.

WHAT A GREEN HERE MEANS, AND IT IS NARROWER THAN IT LOOKS. This suite never starts a
Codex process — no CI runner has one — so nothing here is evidence about the runtime.
It asserts three things:

  1. the TRANSLATION is correct against the LIVE guard, not against a transcript of it.
     Every identity row below is re-derived by piping a payload into
     `hooks/scripts/permission-guard.sh` on this machine, so a change to the guard's
     caller rules reddens here rather than silently changing what Codex is exempted from;
  2. the CARRIER is the shape measured to replace the Claude registry, and is not one of
     the two shapes measured to fail SILENTLY (a wrong `hooks` type falls back to the
     Claude bundle; a missing path registers zero);
  3. the BRANCH POINT is real — both settings of
     `REFUSE_INTERACTIVE_SESSION_STARTUP` are exercised, so the unselected one cannot rot
     into something that no longer works when the owner rules.

WHAT IT CANNOT SEE: whether Codex ever invokes the registered command, whether a
relative path resolves from a plugin carrier, and whether the registration is trusted.
All three are runtime facts and all three are named in `docs/codex-hook-bridge.md`.

Run: python3 scripts/codex-hook-adapter.test.py
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ADAPTER = ROOT / "scripts" / "codex-hook-adapter.py"
GUARD = ROOT / "hooks" / "scripts" / "permission-guard.sh"
CARRIER = ROOT / ".codex-plugin" / "plugin.json"
HOOKS = ROOT / "codex-hooks.json"

PASS = 0
FAIL = 0


def ok(msg):
    global PASS
    PASS += 1
    print("PASS  " + msg)


def bad(msg):
    global FAIL
    FAIL += 1
    print("FAIL  " + msg)


def check(cond, msg):
    ok(msg) if cond else bad(msg)


# ── helpers ───────────────────────────────────────────────────────────────────────────

def run_adapter(payload, cwd=None, env=None, source=None):
    """Run the adapter as a subprocess, optionally from a MUTATED copy of its source.

    A mutated copy rather than an import: the branch point is a module constant, and
    re-importing a module to flip a constant tests the import system. Rewriting the
    source and running it is what a reader would do."""
    script = str(source) if source else str(ADAPTER)
    e = dict(os.environ)
    if env:
        e.update(env)
    p = subprocess.run([sys.executable, script],
                       input=json.dumps(payload) if not isinstance(payload, str) else payload,
                       capture_output=True, text=True,
                       cwd=cwd or str(ROOT), env=e)
    return p


def decision_of(p):
    out = (p.stdout or "").strip()
    if not out:
        return None
    try:
        return json.loads(out)
    except ValueError:
        return {"decision": "UNPARSEABLE", "reason": out[:120]}


def guard_verdict(command, caller, cwd=None):
    """The live guard's own verdict, so the identity table below is measured rather than
    copied out of a document."""
    payload = {"hook_event_name": "PreToolUse", "tool_name": "Bash",
               "tool_input": {"command": command}, "cwd": cwd or str(ROOT)}
    if caller is not None:
        payload["agent_type"] = caller
    p = subprocess.run(["bash", str(GUARD)], input=json.dumps(payload),
                       capture_output=True, text=True, cwd=cwd or str(ROOT))
    out = (p.stdout or "").strip()
    if not out:
        return None
    try:
        return json.loads(out)["hookSpecificOutput"]["permissionDecision"]
    except (ValueError, KeyError, TypeError):
        return "UNPARSEABLE"


def codex_payload(command, **extra):
    payload = {"hook_event_name": "PreToolUse", "tool_name": "Bash",
               "tool_input": {"command": command}, "cwd": str(ROOT)}
    payload.update(extra)
    return payload


class MutationTargetMissing(Exception):
    """Raised rather than exiting: a suite that dies before its summary reports no totals,
    which reads differently from a red and hid two failures during this file's own
    mutation calibration."""


def mutated_adapter(work, replacements):
    src = ADAPTER.read_text()
    for old, new in replacements:
        if old not in src:
            raise MutationTargetMissing(old)
        src = src.replace(old, new, 1)
    target = Path(work) / "mutated-adapter.py"
    target.write_text(src)
    return target


# ── 1 · the refusal vocabulary is Codex's, not Claude's ───────────────────────────────
# Measured in bridge section 5: `{"decision":"block","reason":...}` on stdout, exit 0.
# There is no hookSpecificOutput envelope, no permissionDecision key and no exit-code-2
# channel. A Claude-shaped output here would be a hook the runtime ignores.

p = run_adapter(codex_payload("terraform apply"))
d = decision_of(p)
check(p.returncode == 0, "vocabulary — a refusal exits 0 (Codex reads stdout, not the code)")
check(d is not None and d.get("decision") == "block",
      "vocabulary — the verb is `block`" + ("" if d else " (nothing was printed)"))
check(d is not None and isinstance(d.get("reason"), str) and d["reason"].strip(),
      "vocabulary — `reason` is present and non-empty (the runtime errors without it)")
check(d is not None and "hookSpecificOutput" not in d and "permissionDecision" not in d,
      "vocabulary — no Claude envelope leaks through")
check(d is not None and set(d) == {"decision", "reason"},
      "vocabulary — exactly the two measured keys, nothing invented")

# CALIBRATION: the same adapter must be able to say nothing at all, or the four checks
# above are measuring a script that always blocks.
p = run_adapter(codex_payload("ls -la"))
check((p.stdout or "").strip() == "" and p.returncode == 0,
      "vocabulary (calibration) — a permitted act produces NO decision, so `block` is a "
      "real verdict rather than this adapter's only output")

# ── 2 · identity — measured against the live guard, and the hazard is re-derived ──────
# The naive mapping is the safe one. This is asserted by MEASURING both, not by trusting
# the adapter's comment.

OPEN_WORK = ("gh issue create --repo tedeuxx/tadeumendonca-skills "
             "--title x --body-file /dev/null")
POST = "gh pr comment 999999 --repo tedeuxx/tadeumendonca-skills --body-file /dev/null"

absent = guard_verdict(OPEN_WORK, None)
empty = guard_verdict(OPEN_WORK, "")
# ~~identity (hazard) — … normalising absence to "" is the fail-open move this adapter
# must not make~~ — the MEASUREMENT is kept and its reading changed (#501): the owner chose
# role parity, and the root session was measured to be the only keyless payload, so "" is
# now what the ROOT is deliberately sent. What this arm still proves is that "" and absent
# are the same caller to the guard, so the adapter's choice is the whole decision.
check(absent is None and empty is None,
      "identity (was: hazard) — an ABSENT agent_type and an EMPTY one are the same caller "
      "to the guard: both ABSTAIN on opening work, so sending \"\" for the root is the "
      "orchestrator's position, chosen deliberately under #501 rather than by accident")

import importlib.util
spec = importlib.util.spec_from_file_location("cha", ADAPTER)
cha = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cha)

sentinel = cha.UNIDENTIFIED_CALLER
check(":" not in sentinel and sentinel.strip(),
      "identity — the sentinel is non-empty and carries NO colon, so it cannot match the "
      "guard's namespaced `<plugin>:<persona>` allowlists")
check(guard_verdict(OPEN_WORK, sentinel) == "deny",
      "identity — the sentinel is DENIED opening work where absence abstains")
check(guard_verdict(POST, sentinel) == "deny",
      "identity — the sentinel is DENIED posting to a public surface")
check(guard_verdict("ls -la", sentinel) is None,
      "identity (calibration) — the sentinel still ABSTAINS on a read, so it is a caller "
      "the guard judges rather than a value that denies everything")

# The bare-name finding: a bare persona name fails CLOSED where the namespaced one is
# exempt. Codex's own value is bare, which is why pass-through is the closed mapping.
check(guard_verdict(POST, "agents-lead") == "deny"
      and guard_verdict(POST, "tadeumendonca-skills:agents-lead") is None,
      "identity — a BARE persona name is denied by 5e while the namespaced form abstains, "
      "so passing Codex's bare value through verbatim fails closed")

# And the mapping itself: what does the adapter actually send?
# ~~a missing key maps to the sentinel~~ — struck #501: it maps to the ROOT caller.
check(cha.ROOT_CALLER == "" and cha.map_caller({}) == cha.ROOT_CALLER,
      "identity — a MISSING key (the Codex root session) maps to \"\", the orchestrator "
      "(#501 role parity)")
check(cha.map_caller({"agent_type": ""}) == sentinel,
      "identity — an EMPTY value is NOT the root: it maps to the sentinel, so absent and "
      "empty still map to different values")
check(cha.map_caller({"agent_type": None}) == sentinel,
      "identity — a null value maps to the sentinel")
check(cha.map_caller({"agent_type": 7}) == sentinel,
      "identity — a non-string value maps to the sentinel")
check(cha.map_caller({"agent_type": "probe_child"}) == "probe_child",
      "identity — a real child role is passed through VERBATIM, un-namespaced")
# ~~a build role id is passed through VERBATIM; the GUARD translates it~~ — struck at QA gate
# round 1 on #502: a guard-side rewrite also fired on Claude Code for a local agent file named
# `tadeumendonca_<persona>`. The rewrite is HERE, on the Codex-only route.
check(cha.map_caller({"agent_type": "tadeumendonca_quality_assurance"})
      == "tadeumendonca-skills:quality-assurance",
      "identity — a build role id is REWRITTEN by the adapter into its Claude Code form, so the "
      "shared guard reads the raw field on both harnesses")
# (Named `malformed`, not `bad`: `bad()` is this suite's failure reporter, and shadowing it
# turned the first red here into a crash with no summary — found by the widened-case mutant.)
for malformed in ("tadeumendonca_", "tadeumendonca__developer", "tadeumendonca_Developer",
                  "xtadeumendonca_developer", "tadeumendonca_developer "):
    check(cha.map_caller({"agent_type": malformed}) == malformed,
          "identity — a malformed build id %r is passed through UNCHANGED, so it falls to the "
          "catch-all rather than being coerced into a persona" % malformed)

# The four child payload shapes measured on 2026-09-23 (codex-cli 0.151.0-alpha.7.2,
# disposable home, loopback model; docs/codex-hook-bridge.md section 19). Every one
# CARRIES the key, which is the premise that makes ABSENT -> "" the root alone. They are
# pinned as payloads so a change to the mapping that would hand one of them "" reddens.
for shape, value in (("a registered role at depth 1", "probe_child"),
                     ("a spawn with agent_type OMITTED", "default"),
                     ("a full-history FORK with agent_type omitted", "default"),
                     ("a grandchild at max_depth = 2", "probe_grand")):
    check(cha.map_caller({"agent_type": value}) not in ("", None),
          "identity (measured shape) — %s carries %r and is never sent as the root"
          % (shape, value))

# End to end: a Codex ROOT payload (no agent_type key at all) takes the orchestrator's
# arm. ~~must be BLOCKED on an act that an empty caller would have been allowed~~ — struck
# #501. It must now be ALLOWED to post (5e's "" arm) and still BLOCKED from merging (7b).
p = run_adapter(codex_payload(POST))
check((p.stdout or "").strip() == "",
      "identity (end to end) — a payload with NO agent_type key may POST, as the "
      "orchestrator may on Claude Code")
p = run_adapter(codex_payload("gh pr merge 999999 --merge --repo tedeuxx/tadeumendonca-skills"))
d = decision_of(p)
check(d is not None and d.get("decision") == "block",
      "identity (end to end, calibration) — the same keyless root is still REFUSED the "
      "merge, so the orchestrator's position is not a blanket allow")
p = run_adapter(codex_payload(POST, agent_type="tadeumendonca_agents_lead"))
check((p.stdout or "").strip() == "",
      "identity (end to end) — a Codex agents-lead child may post its lens marker (the "
      "#498 refusal this Issue exists for)")
p = run_adapter(codex_payload(POST, agent_type="tadeumendonca_product_lead"))
d = decision_of(p)
check(d is not None and d.get("decision") == "block"
      and "`product-lead` writes nothing" in d.get("reason", ""),
      "identity (end to end) — a Codex product-lead child is refused by product-lead's "
      "NAMED arm, not the catch-all")

# ── 3 · routes — an untranslated route abstains and says so ───────────────────────────

for tool in cha.UNTRANSLATED_ROUTES:
    p = run_adapter({"hook_event_name": "PreToolUse", "tool_name": tool,
                     "tool_input": {"command": "terraform apply"}, "cwd": str(ROOT)})
    check((p.stdout or "").strip() == "" and "carries no floor" in (p.stderr or ""),
          "routes — %s abstains and NAMES itself on stderr rather than being silently "
          "treated as covered" % tool)

p = run_adapter({"hook_event_name": "SessionStart", "cwd": str(ROOT)})
check((p.stdout or "").strip() == "",
      "routes — an event outside the two native control routes is not answered; the "
      "observer half is not smuggled in by accepting events silently")

p = run_adapter({"hook_event_name": "UserPromptSubmit", "prompt": "safe probe",
                 "cwd": str(ROOT)})
check((p.stdout or "").strip() == "" and p.returncode == 0,
      "preflight — a healthy checkout abstains, so UserPromptSubmit is not a blanket "
      "prompt denial")

with tempfile.TemporaryDirectory() as work:
    only_bash = Path(work) / "bin"
    only_bash.mkdir()
    os.symlink("/bin/bash", only_bash / "bash")
    p = run_adapter({"hook_event_name": "UserPromptSubmit", "prompt": "probe",
                     "cwd": str(ROOT)}, env={"PATH": str(only_bash)})
    d = decision_of(p)
    check(d is not None and d.get("decision") == "block" and "jq is not on PATH" in d.get("reason", ""),
          "preflight — a missing jq refuses the prompt with the concrete dependency, "
          "rather than letting the floor fail open later")

with tempfile.TemporaryDirectory() as work:
    only_jq = Path(work) / "bin"
    only_jq.mkdir()
    jq_path = shutil.which("jq")
    if jq_path:
        os.symlink(jq_path, only_jq / "jq")
    p = run_adapter({"hook_event_name": "UserPromptSubmit", "prompt": "probe",
                     "cwd": str(ROOT)}, env={"PATH": str(only_jq)})
    d = decision_of(p)
    check(d is not None and d.get("decision") == "block"
          and "bash is not on PATH" in d.get("reason", ""),
          "preflight — a missing bash refuses the prompt before the adapter can reach "
          "the command-floor subprocess")

with tempfile.TemporaryDirectory() as work:
    src = mutated_adapter(work, [("GUARD = REPO_ROOT / \"hooks\" / \"scripts\" / \"permission-guard.sh\"",
                                  "GUARD = REPO_ROOT / \"missing-guard.sh\"")])
    p = run_adapter({"hook_event_name": "UserPromptSubmit", "prompt": "probe",
                     "cwd": str(ROOT)}, source=src)
    d = decision_of(p)
    check(d is not None and d.get("decision") == "block"
          and "guard is missing" in d.get("reason", ""),
          "preflight — a missing shared guard refuses the prompt; the check is against "
          "the activated Codex path, not the Claude observer registry")

# ── 3b · the persona-snapshot notice (#509) — a REPORT, never a refusal ────────────────
# The notice rides the EXISTING UserPromptSubmit registration so the trusted command
# string does not move (8e). Its channel — additionalContext, reaching the model as a
# developer message — was measured by `codex-hook-probe.py --phase snapshotnotice`; these
# arms prove the file produces that shape, silence when current, and never a `block`.

INSTALLED = (ROOT / "VERSION").read_text().strip()


def snapshot_dir(base, name, version, manifest=True, roles=("tadeumendonca_quality_assurance",)):
    d = Path(base) / name
    (d / "profiles").mkdir(parents=True)
    for role in roles:
        (d / "profiles" / (role + ".toml")).write_text('name = "%s"\n' % role)
    if manifest:
        (d / "source-manifest.json").write_text(json.dumps({"schema": 1, "version": version}))
    return d


def register(project, snapshot, roles=("tadeumendonca_quality_assurance",), quoted=False,
             literal=False, extra=""):
    cfg = Path(project) / ".codex" / "config.toml"
    cfg.parent.mkdir(parents=True, exist_ok=True)
    body = 'model = "x"\n' + extra
    for role in roles:
        header = '[agents."%s"]' % role if quoted else "[agents.%s]" % role
        path = str(Path(snapshot) / "profiles" / (role + ".toml"))
        value = ("'%s'" % path) if literal else json.dumps(path)
        body += "\n%s\nconfig_file = %s\ndescription = \"d\"\n" % (header, value)
    cfg.write_text(body)
    return cfg


def prompt_at(cwd, env=None, source=None):
    return run_adapter({"hook_event_name": "UserPromptSubmit", "prompt": "p", "cwd": str(cwd)},
                       env=env, source=source)


def context_of(p):
    d = decision_of(p) or {}
    return ((d.get("hookSpecificOutput") or {}).get("additionalContext") or ""), d


with tempfile.TemporaryDirectory() as work:
    proj = Path(work) / "proj"
    (proj / ".git").mkdir(parents=True)
    stale = snapshot_dir(work, "snap-old", "0.0.1")
    register(proj, stale)
    p = prompt_at(proj)
    text, d = context_of(p)
    check(p.returncode == 0 and "decision" not in d
          and (d.get("hookSpecificOutput") or {}).get("hookEventName") == "UserPromptSubmit"
          and cha.SNAPSHOT_TAG in text and "0.0.1" in text and INSTALLED in text,
          "snapshot notice — a registered snapshot BEHIND the installed plugin is reported "
          "as additionalContext naming both versions, exit 0 and no `decision` key")
    check("--install-config" in text and "NEW thread" in text
          and "keep the old directory" in text and "blocks nothing" in text,
          "snapshot notice — it carries the update procedure the in-flight measurement "
          "supports: new directory, re-register, new thread, keep the old directory")

    # Calibration: the SAME tree with the snapshot at the installed version is silent, so
    # the arm above is a version comparison and not a constant.
    current = snapshot_dir(work, "snap-now", INSTALLED)
    register(proj, current)
    p = prompt_at(proj)
    check(p.returncode == 0 and (p.stdout or "").strip() == "",
          "snapshot notice — calibration: a snapshot AT the installed version is silent")
    newer = snapshot_dir(work, "snap-new", "999.0.0")
    register(proj, newer)
    check((prompt_at(proj).stdout or "").strip() == "",
          "snapshot notice — a snapshot NEWER than the plugin is not reported as behind")

    nomanifest = snapshot_dir(work, "snap-bare", None, manifest=False)
    register(proj, nomanifest)
    text, d = context_of(prompt_at(proj))
    check("UNREADABLE" in text and cha.SNAPSHOT_TAG in text,
          "snapshot notice — a snapshot whose version cannot be read is REPORTED, because "
          "unknown is not current")

    register(proj, stale, quoted=True, literal=True)
    check("0.0.1" in context_of(prompt_at(proj))[0],
          "snapshot notice — a quoted table header and a literal-string path are read too")

    register(proj, stale, roles=("somebody_else",))
    check((prompt_at(proj).stdout or "").strip() == "",
          "snapshot notice — a role outside the tadeumendonca_ namespace is not this "
          "notice's business")

    # Nearest config wins per role; the walk stops at the git root.
    sub = proj / "apps" / "fed"
    sub.mkdir(parents=True)
    register(proj, stale)
    check("0.0.1" in context_of(prompt_at(sub))[0],
          "snapshot notice — from a subdirectory, the project root's registration is found")
    register(sub, current)
    check((prompt_at(sub).stdout or "").strip() == "",
          "snapshot notice — the NEAREST registration wins per role, as a project layer does")
    outer = Path(work) / "outer"
    inner = outer / "repo"
    (inner / ".git").mkdir(parents=True)
    register(outer, stale)
    check((prompt_at(inner).stdout or "").strip() == "",
          "snapshot notice — a config ABOVE the git root is not read")

    (proj / ".codex" / "config.toml").unlink()
    (sub / ".codex" / "config.toml").unlink()
    check((prompt_at(proj).stdout or "").strip() == "",
          "snapshot notice — no registration, no notice")

    # A failing preflight still BLOCKS, and the notice does not displace it.
    register(proj, stale)
    only_bash = Path(work) / "bin"
    only_bash.mkdir()
    os.symlink("/bin/bash", only_bash / "bash")
    d = decision_of(prompt_at(proj, env={"PATH": str(only_bash)})) or {}
    check(d.get("decision") == "block" and "jq is not on PATH" in d.get("reason", ""),
          "snapshot notice — a missing floor dependency still refuses the prompt; the "
          "notice is reached only on a healthy floor")

    # NEVER A REFUSAL, even when the notice's own code raises: the shipped resolver maps
    # any non-zero exit to 2, and 2 blocks the prompt, so a crash here would be a denial.
    # The copy lives outside the checkout, so its REPO_ROOT is pinned back to the checkout;
    # otherwise the guard is "missing" and the preflight blocks before the notice runs.
    src = mutated_adapter(work, [(
        "REPO_ROOT = Path(__file__).resolve().parent.parent",
        "REPO_ROOT = Path(%r)" % str(ROOT)), (
        '    installed = (REPO_ROOT / "VERSION").read_text(encoding="utf-8").strip()\n',
        '    raise RuntimeError("probe")\n')])
    p = prompt_at(proj, source=src)
    check(p.returncode == 0 and (p.stdout or "").strip() == ""
          and "could not be computed" in (p.stderr or ""),
          "snapshot notice — an exception inside it degrades to silence with exit 0 and a "
          "stderr line, never to exit 1 (which the shipped command would turn into a block)")

    p = subprocess.run([sys.executable, str(ADAPTER), "--selfcheck"],
                       capture_output=True, text=True, cwd=str(proj))
    check(p.returncode == 0 and "PERSONA SNAPSHOT (#509): " + cha.SNAPSHOT_TAG in p.stdout,
          "snapshot notice — selfcheck reports it for the current directory as a NOTE, and "
          "a stale snapshot does not turn selfcheck into NOT ACTIVE")

check(cha.SHELL_TOOL == "Bash",
      "routes — the shell route is `Bash`; `shell` matches nothing and would register a "
      "hook that reads as installed and never fires")

# ── 4 · the process cwd is load-bearing and the payload field is not ──────────────────
# The guard resolves a bare `git push`'s branch with `git -C "."`, so the verdict follows
# the PROCESS cwd. The adapter chdirs to the payload's cwd; without that, the trunk rule
# reads whichever tree the host launched the hook from.

with tempfile.TemporaryDirectory() as work:
    trees = {}
    for branch in ("main", "feature"):
        d = Path(work) / branch
        d.mkdir()
        subprocess.run(["git", "init", "-q", str(d)], check=True,
                       capture_output=True)
        subprocess.run(["git", "-C", str(d), "-c", "user.email=a@b", "-c", "user.name=a",
                        "commit", "-q", "--allow-empty", "-m", "init"], check=True,
                       capture_output=True)
        subprocess.run(["git", "-C", str(d), "branch", "-M", branch], check=True,
                       capture_output=True)
        trees[branch] = str(d)

    # Run the adapter FROM the main tree with a payload naming the feature tree.
    p = run_adapter(codex_payload("git push", cwd=trees["feature"]), cwd=trees["main"])
    check((p.stdout or "").strip() == "",
          "cwd — a payload naming a FEATURE tree is not refused even when the adapter "
          "process starts in a trunk checkout: the payload's cwd is what decides")
    # And the converse: a payload naming the trunk IS refused from a feature checkout.
    p = run_adapter(codex_payload("git push", cwd=trees["main"]), cwd=trees["feature"])
    d = decision_of(p)
    check(d is not None and d.get("decision") == "block",
          "cwd — a payload naming the TRUNK is refused even when the adapter process "
          "starts in a feature checkout, which is the direction that would fail OPEN")

    # CALIBRATION: the guard itself follows the process cwd, so the two rows above are a
    # property of the adapter's chdir and not of the guard being cwd-blind.
    check(guard_verdict("git push", None, cwd=trees["main"]) == "deny"
          and guard_verdict("git push", None, cwd=trees["feature"]) is None,
          "cwd (calibration) — the guard's own verdict DOES depend on its process cwd, "
          "so the adapter's chdir is doing the work rather than being decoration")

# ── 5 · failure posture — every degradation abstains, and says so on stderr ───────────

p = run_adapter("{not json")
check((p.stdout or "").strip() == "" and p.returncode == 0 and "NOT judged" in p.stderr,
      "failure — an unparseable payload abstains and says the act was NOT judged")

p = run_adapter("[1,2,3]")
check((p.stdout or "").strip() == "" and "NOT judged" in p.stderr,
      "failure — a payload that is not an object abstains with the same sentence")

with tempfile.TemporaryDirectory() as work:
    src = mutated_adapter(work, [('GUARD = REPO_ROOT / "hooks" / "scripts" / "permission-guard.sh"',
                                  'GUARD = REPO_ROOT / "hooks" / "scripts" / "no-such-guard.sh"')])
    p = run_adapter(codex_payload("terraform apply"), source=src)
    check((p.stdout or "").strip() == "" and "NOT judged" in p.stderr,
          "failure — a MISSING guard fails OPEN with a stderr line, matching the guard's "
          "own general contract rather than wedging the session")

p = run_adapter(codex_payload("terraform apply"), env={"CODEX_HOOK_ADAPTER_TIMEOUT": "0.001"})
check((p.stdout or "").strip() == "" and "did not answer" in p.stderr,
      "failure — a guard that does not answer in time abstains WITH a trace, rather than "
      "being killed by the host and leaving none")

# ── 5b · A MALFORMED TUNABLE IS A CONFIGURATION DEFECT, NOT A CRASH (#455, AC6) ───────
# The read was `float(os.environ.get(...))` at module scope, so a non-numeric value raised
# before `main` was reached: a traceback, exit 1, and NOTHING on stdout — which this
# runtime reports as a hook ERROR rather than as the abstention AC6 names. It failed in
# BOTH modes, `--selfcheck` included, so the one route an operator has to tell an inert
# floor from a holding one was itself the route that crashed.
#
# The three malformed classes are asserted separately because they fail differently, and
# the two that PARSE are the dangerous ones: a non-positive value makes `subprocess.run`
# time out on EVERY call, which is the whole floor off SILENTLY with a value that looks
# deliberate; an infinite one defeats the reason the constant is short in the first place.
for badval, why in (("notanumber", "non-numeric"), ("", "empty"), ("0", "zero"),
                 ("-1", "negative"), ("nan", "NaN"), ("inf", "infinite")):
    p = run_adapter(codex_payload("wc -l README.md"),
                    env={"CODEX_HOOK_ADAPTER_TIMEOUT": badval})
    check(p.returncode == 0 and "Traceback" not in p.stderr
          and (p.stdout or "").strip() == "" and "MIS-SET" in p.stderr,
          "timeout tunable — a %s CODEX_HOOK_ADAPTER_TIMEOUT abstains and reports the "
          "knob as MIS-SET, rather than crashing with a traceback and no decision" % why)

    # Selfcheck mode is asserted separately because the crash was identical in both and a
    # fix landing in only one of them would still read as a fix.
    p = subprocess.run([sys.executable, str(ADAPTER), "--selfcheck"],
                       capture_output=True, text=True, cwd=str(ROOT),
                       env=dict(os.environ, CODEX_HOOK_ADAPTER_TIMEOUT=badval))
    check("Traceback" not in p.stderr and "MIS-SET" in p.stdout,
          "timeout tunable — `--selfcheck` reports a %s value as a MIS-SET note rather "
          "than crashing" % why)
    # It is a NOTE and never a BLOCK: the floor runs at the default, so reporting NOT
    # ACTIVE over a working floor would be a false claim in the alarming direction.
    check("BLOCK: GUARD TIMEOUT" not in p.stdout,
          "timeout tunable — a %s value is a selfcheck NOTE, never a BLOCK, because the "
          "floor still runs at the default" % why)

    # AND THE FLOOR IS STILL CARRIED. The fallback must RUN the guard, not merely avoid
    # crashing — a fix that abstained on everything would pass every arm above.
    p = run_adapter(codex_payload("terraform apply"),
                    env={"CODEX_HOOK_ADAPTER_TIMEOUT": badval})
    d = decision_of(p)
    check(d is not None and d.get("decision") == "block",
          "timeout tunable — under a %s value the floor STILL blocks, so the fallback "
          "runs the guard rather than degrading into a blanket abstention" % why)

# The UNSET control, so "reports MIS-SET" is not a constant: a correctly-set knob and an
# unset one must both be SILENT on stderr, which is what makes the line above a signal.
for good in (None, "2.5"):
    env = {"CODEX_HOOK_ADAPTER_TIMEOUT": good} if good else {}
    p = run_adapter(codex_payload("wc -l README.md"), env=env)
    check("MIS-SET" not in p.stderr,
          "timeout tunable — a %s knob is SILENT on stderr, which is what makes the "
          "mis-set line distinguishable from an unset one"
          % ("valid" if good else "an unset"))

# ── 6 · `ask` becomes a block, because Codex has no prompt rung ───────────────────────
# Unreachable at head — the guard defines ask() and has zero call sites — so it is
# exercised against a STUB guard rather than left untested until the day it fires.

with tempfile.TemporaryDirectory() as work:
    stub = Path(work) / "ask-guard.sh"
    stub.write_text(
        "#!/usr/bin/env bash\n"
        "cat >/dev/null\n"
        "printf '%s' '{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\","
        "\"permissionDecision\":\"ask\",\"permissionDecisionReason\":\"stub asked\"}}'\n")
    src = mutated_adapter(work, [('GUARD = REPO_ROOT / "hooks" / "scripts" / "permission-guard.sh"',
                                  'GUARD = Path(%r)' % str(stub))])
    p = run_adapter(codex_payload("anything"), source=src)
    d = decision_of(p)
    check(d is not None and d.get("decision") == "block" and "no prompt" in d.get("reason", ""),
          "ask — an `ask` verdict becomes a BLOCK, because Codex's measured vocabulary has "
          "one refusal verb and no prompt: an act the floor would not pass unattended must "
          "not pass because the destination harness is missing a rung")

    # And the guard at head really does emit no `ask`, so the branch above is currently
    # unreachable rather than merely untriggered — stated as a fact with its command.
    src_text = GUARD.read_text()
    import re
    ask_calls = len(re.findall(r'(?m)^[^#\n]*(?:^|[^#\w])ask\s+"', src_text))
    deny_calls = len(re.findall(r'(?m)^[^#\n]*(?:^|[^#\w])deny\s+"', src_text))
    check(ask_calls == 0 and deny_calls > 20,
          "ask (reachability) — the guard has %d `ask` call site(s) against %d `deny`, so "
          "the branch above is unreachable at head rather than untested" % (ask_calls, deny_calls))

# ── 7 · the branch point is REAL — both settings are exercised ────────────────────────

check(cha.REFUSE_INTERACTIVE_SESSION_STARTUP is False,
      "branch point — the shipped setting is SHIP-AND-STATE-THE-GAP (False). This "
      "assertion is the tripwire: flipping the constant must be a deliberate edit that "
      "also edits this line and every coverage sentence in the bridge document")

p = run_adapter(codex_payload("bash"))
check((p.stdout or "").strip() == "",
      "branch point (False) — a bare interpreter is PERMITTED, and the write_stdin gap is "
      "therefore open: the hook sees the four characters `bash` and nothing after")

with tempfile.TemporaryDirectory() as work:
    try:
        src = mutated_adapter(work, [("REFUSE_INTERACTIVE_SESSION_STARTUP = False",
                                      "REFUSE_INTERACTIVE_SESSION_STARTUP = True")])
    except MutationTargetMissing:
        src = ADAPTER  # already True; exercise it as shipped rather than skipping
    for cmd, expect_block, why in [
        ("bash", True, "a bare shell opens a session"),
        ("python3", True, "so does a bare REPL"),
        ("/bin/zsh", True, "an absolute path is the same act"),
        ("bash -c 'echo hi'", False, "a command string attaches work"),
        ("python3 script.py", False, "a script argument attaches work"),
        ("python3 -m mod", False, "a module argument attaches work"),
        ("ls -la", False, "an ordinary command is untouched"),
        ("git status", False, "so is an ordinary read"),
    ]:
        p = run_adapter(codex_payload(cmd), source=src)
        got = decision_of(p)
        blocked = got is not None and got.get("decision") == "block"
        check(blocked == expect_block,
              "branch point (True) — %-24r %s (%s)"
              % (cmd, "blocked" if expect_block else "permitted", why))

# ── 8 · the carrier is the shape measured to REPLACE, not either silent-failure shape ──

check(CARRIER.is_file(), "carrier — .codex-plugin/plugin.json exists")
manifest = json.loads(CARRIER.read_text()) if CARRIER.is_file() else {}
check(isinstance(manifest.get("hooks"), str),
      "carrier — `hooks` is a PATH STRING. A wrong TYPE was measured falling back to the "
      "Claude bundle SILENTLY, so the carrier would read as installed and behave as absent")
declared = manifest.get("hooks")
check(HOOKS.is_file() and isinstance(declared, str)
      and declared.lstrip("./") == HOOKS.name,
      "carrier — the declared path RESOLVES. A missing path was measured registering ZERO "
      "hooks, also silently")
check(manifest.get("skills") == "./skills/",
      "carrier — the skill library is declared, or adopting the carrier would silently "
      "drop skill discovery that the Claude manifest was providing")
check(manifest.get("mcpServers") == "./.mcp.json" and (ROOT / ".mcp.json").is_file(),
      "carrier — the canonical MCP source is declared and resolves")

hooks_doc = json.loads(HOOKS.read_text()) if HOOKS.is_file() else {}
event_regs = hooks_doc.get("hooks", {})
check(set(event_regs) == {"PreToolUse", "UserPromptSubmit"},
      "carrier — exactly the two native control events are registered; no Claude observer "
      "route is imported")
commands = []
for event in ("PreToolUse", "UserPromptSubmit"):
    regs = event_regs.get(event, [])
    check(len(regs) == 1 and len(regs[0].get("hooks", [])) == 1,
          "carrier — %s has exactly one registration" % event)
    check("matcher" not in regs[0] if regs else False,
          "carrier — %s has NO matcher; dispatch happens visibly in the adapter" % event)
    cmd = regs[0]["hooks"][0]["command"] if regs else ""
    commands.append(cmd)
    check(("scripts/" + ADAPTER.name) in cmd and 'python3 "$r/$a"; s=$?;' in cmd,
          "carrier — %s names the adapter through an explicit interpreter" % event)
    check(set(regs[0]["hooks"][0]) == {"type", "command"} if regs else False,
          "carrier — %s uses only the two measured hook keys" % event)
check(len(set(commands)) == 1,
      "carrier — both events invoke the same root-anchored adapter; preflight cannot "
      "drift onto a second implementation")

# ── 8b · the adapter path is ROOT-ANCHORED, and the anchor is a MEASURED name ──────────
#
# WHY THIS BLOCK EXISTS. The shipped registration carried `python3 scripts/codex-hook-
# adapter.py` and was measured NOT EXECUTING through the plugin carrier: a relative command
# resolves against the SESSION's cwd, which for an installed plugin is the wrong directory
# by construction — the adapter sits in the plugin cache and the runtime looked for it under
# the project (bridge document, section 16.3).
#
# AND THE FAILURE IS WORSE THAN AN ABSENT FLOOR, which is what makes these arms mandatory
# rather than tidy. When a hook's command cannot be launched this runtime denies ONE LAYER
# ABOVE the guard — `hook_run_statuses` reads `blocked`, the SAME status a real floor
# decision produces. So a broken carrier reads, to anyone watching, exactly like the
# permission floor working correctly. Nothing downstream can tell the two apart except the
# adapter's own invocation log, and by then the session is already stopped.
#
# THE ALLOWED NAMES ARE DERIVED, NEVER RESTATED. `scripts/codex-hook-probe.py` carries the
# measurement (`ROOT_MEASURED`) in the artifact that took it; hardcoding a second copy here
# would make this arm a check of one string against another string rather than against the
# evidence. If a later build re-runs the phase and the injected set moves, these arms move
# with it.

probe_mod = None
probe_err = ""
try:
    import importlib.util as _ilu
    _spec = _ilu.spec_from_file_location(
        "codex_hook_probe_for_adapter_test", str(ROOT / "scripts" / "codex-hook-probe.py"))
    probe_mod = _ilu.module_from_spec(_spec)
    _spec.loader.exec_module(probe_mod)
except Exception as exc:                                      # pragma: no cover
    probe_err = repr(exc)

# A failure to import is asserted on rather than skipped. A skip here is a vacuous green —
# exactly the shape this repository keeps paying for — because every arm below would simply
# stop running and the totals would still look plausible.
check(probe_mod is not None and isinstance(
          getattr(probe_mod, "ROOT_MEASURED", None), dict),
      "carrier root — the measurement artifact imports and carries ROOT_MEASURED, or the "
      "arms below assert nothing at all %s" % probe_err)

measured = getattr(probe_mod, "ROOT_MEASURED", {}) or {}
injected = set(measured.get("env_names_injected_on_plugin_route") or [])
# ROOT names only. PLUGIN_DATA and CLAUDE_PLUGIN_DATA were injected too and point at a
# DIFFERENT directory, so an arm that accepted any injected name would wave through a
# command that expands cleanly and still cannot find the adapter.
root_names = {n for n in injected if n.endswith("_ROOT")}

check(bool(root_names),
      "carrier root — at least one injected name ends _ROOT, or the allowed set is empty "
      "and the membership arm below could never fail")

# ── 8c · the registration SURVIVES A RELEASE (#508) ────────────────────────────────────
#
# WHY THE SHAPE CHANGED. A running Codex process resolves ${PLUGIN_ROOT} ONCE and keeps
# it: measured on 0.151.0-alpha.7.2 against a loopback model (bridge document, section
# 20), an update installed by ANOTHER process deletes the old version directory, and every
# later tool call in the running process — same thread or a new one — launched the
# vanished path and was blocked. A merge PUBLISHES a patch; it does not install one. A
# running session strands only when a process OTHER than itself installs the update (an
# install through the running process refreshes it — probe `legacy_same_process`), and
# whether Codex ever installs a plugin update by itself is UNMEASURED. So the outage rate
# is one per out-of-process update per open session, which equals one per merge only if
# such an update follows every merge. The registration therefore resolves the adapter AT
# CALL TIME: the registered root if it still holds the adapter, otherwise the ONE sibling
# version directory that does, otherwise a refusal.
#
# WHY /bin/sh IS PINNED. The hook command runs in the user's LOGIN shell (measured: $0 was
# /bin/zsh even with SHELL=/bin/bash in the app-server's environment), and in zsh a glob
# that matches nothing is an ERROR with exit 1 — which this runtime treats as a FAILED
# hook and lets the act through. Only exit 2 blocks (measured: exit 1 and exit 127 both
# read `failed` and the act executed; exit 2 read `blocked`). Wrapping the script in one
# single-quoted `/bin/sh -c` argument means the login shell expands nothing and a POSIX
# shell makes every refusal an exit 2, whatever the user's shell is.

SH_PREFIX = "/bin/sh -c '"
check(cmd.startswith(SH_PREFIX) and cmd.endswith("'")
      and "'" not in cmd[len(SH_PREFIX):-1],
      "carrier root — the whole resolver is ONE single-quoted argument to /bin/sh, so the "
      "user's login shell (zsh here) expands nothing and cannot turn a no-match glob into "
      "an exit 1 that this runtime reads as a failed hook and lets through")
inner = cmd[len(SH_PREFIX):-1] if cmd.startswith(SH_PREFIX) else ""

check(not inner.startswith("scripts/") and "python3 scripts/" not in inner,
      "carrier root — the adapter is NOT the bare relative path measured failing to launch "
      "through the installed carrier (section 16.3)")

import re as _re
_tok = _re.search(r"\br=\$\{([A-Z_]+):-\}", inner)
check(_tok is not None,
      "carrier root — the registered root is read from an environment variable with an "
      "explicit empty default, so an unset name is DETECTED and refused rather than "
      "collapsing the path to the filesystem root")
token_name = _tok.group(1) if _tok else ""
check(token_name in root_names,
      "carrier root — the root variable is one MEASURED as injected on the plugin route "
      "(%s). CODEX_PLUGIN_ROOT is the plausible spelling and was measured NOT TO EXIST "
      "under either mechanism. Got %r" % (",".join(sorted(root_names)) or "<none>", token_name))
check("a=scripts/%s;" % ADAPTER.name in inner,
      "carrier root — the in-package path is the adapter's, relative to the resolved root")


def run_registration(command, plugin_root, payload='{"probe": 1}'):
    """Execute the registered command the way the runtime does: through a shell, with
    PLUGIN_ROOT in the environment and the payload on stdin. `bash -c` stands in for the
    login shell, which only has to parse one single-quoted word."""
    env = dict(os.environ)
    env.pop("PLUGIN_ROOT", None)
    env.pop("CLAUDE_PLUGIN_ROOT", None)
    if plugin_root is not None:
        env[token_name or "PLUGIN_ROOT"] = str(plugin_root)
    return subprocess.run(["bash", "-c", command], input=payload, env=env,
                          capture_output=True, text=True, timeout=30)


STUB = ("import sys\nfrom pathlib import Path\n"
        "data = sys.stdin.read()\n"
        "print('RAN ' + Path(__file__).resolve().parent.parent.name + ' ' + str(len(data)))\n")


def version_dir(base, version, with_adapter=True):
    d = base / version
    (d / "scripts").mkdir(parents=True)
    if with_adapter:
        (d / "scripts" / ADAPTER.name).write_text(STUB)
    return d


with tempfile.TemporaryDirectory() as work:
    cache = Path(work) / "cache" / "market" / "tadeumendonca-skills"

    # 1. the registered root still holds the adapter: it runs, and stdin reaches it
    live = version_dir(cache, "9.0.0")
    p = run_registration(cmd, live)
    check(p.returncode == 0 and p.stdout.strip() == "RAN 9.0.0 12",
          "survives a release — a live root runs ITS OWN adapter and the payload reaches "
          "it on stdin (rc=%s out=%r err=%r)" % (p.returncode, p.stdout, p.stderr[-200:]))

    # 2. the registered root is gone and exactly one installed version replaced it
    shutil.rmtree(live)
    version_dir(cache, "9.0.1")
    p = run_registration(cmd, live)
    check(p.returncode == 0 and p.stdout.strip() == "RAN 9.0.1 12",
          "survives a release — a VANISHED root falls through to the one version that "
          "replaced it, which is what keeps a running session alive across a merge "
          "(rc=%s out=%r err=%r)" % (p.returncode, p.stdout, p.stderr[-200:]))

    # 3. a sibling that does not carry the adapter is not a candidate
    version_dir(cache, "not-a-release", with_adapter=False)
    p = run_registration(cmd, live)
    check(p.returncode == 0 and p.stdout.strip() == "RAN 9.0.1 12",
          "survives a release — a sibling directory WITHOUT the adapter is not counted "
          "(rc=%s out=%r)" % (p.returncode, p.stdout))

    # 4. two candidates: ambiguous, so it refuses — and refuses with the BLOCKING code
    version_dir(cache, "9.0.2")
    p = run_registration(cmd, live)
    check(p.returncode == 2 and "RAN" not in p.stdout and "refusing" in p.stderr,
          "fail-closed — TWO candidate versions is ambiguous and exits 2, the only code "
          "this runtime reads as `blocked` (rc=%s out=%r)" % (p.returncode, p.stdout))

    # 5. no candidate at all: the plugin is gone
    shutil.rmtree(cache)
    cache.mkdir(parents=True)
    p = run_registration(cmd, live)
    check(p.returncode == 2 and "RAN" not in p.stdout and "no longer exists" in p.stderr,
          "fail-closed — a vanished root with NO replacement exits 2, preserving section "
          "16.4's blocking posture instead of degrading to exit 1 or 127, which this "
          "runtime lets through (rc=%s err=%r)" % (p.returncode, p.stderr[-200:]))

    # 6. the root variable is absent altogether
    p = run_registration(cmd, None)
    check(p.returncode == 2 and "RAN" not in p.stdout and "unset" in p.stderr,
          "fail-closed — an UNSET root exits 2 rather than globbing the filesystem root "
          "(rc=%s err=%r)" % (p.returncode, p.stderr[-200:]))

    # 7. a cache path containing a space: the resolver quotes every expansion
    spaced = Path(work) / "a cache" / "market" / "tadeumendonca-skills"
    s_live = version_dir(spaced, "9.1.0")
    p = run_registration(cmd, s_live)
    check(p.returncode == 0 and p.stdout.strip() == "RAN 9.1.0 12",
          "quoting — a plugin-cache path containing a space launches, which the former "
          "UNQUOTED form could not (rc=%s err=%r)" % (p.returncode, p.stderr[-200:]))
    shutil.rmtree(s_live)
    version_dir(spaced, "9.1.1")
    p = run_registration(cmd, s_live)
    check(p.returncode == 0 and p.stdout.strip() == "RAN 9.1.1 12",
          "quoting — the fallback also survives a space in the path (rc=%s err=%r)"
          % (p.returncode, p.stderr[-200:]))

# ── 8d · ANY adapter failure is exit 2, through the shipped command (#508) ─────────────
#
# The resolver's own refusals were exit 2, but the process it launched was not: under
# `exec python3 …` an uncaught exception or a SyntaxError exited 1 and a missing python3
# exited 127, and this runtime reads both as a FAILED hook and lets the act run
# (probe STALE_MEASURED["exit_status"]). The shipped command runs the adapter WITHOUT exec
# and maps every non-zero status to 2. The adapter's own intended outcomes are unaffected:
# a block is JSON on stdout with exit 0, an abstention is empty stdout with exit 0, and the
# only non-zero `return` in it belongs to `--selfcheck`, which no hook passes. The same
# mapping was read through the RUNTIME by the probe's `stalepath` phase
# (STALE_MEASURED["shipped_adapter_failure"]); these arms hold the command's half in CI.

FAILING = {
    "an uncaught exception (exit 1)":
        "import sys\nsys.stdin.read()\nraise RuntimeError('boom')\n",
    "a SyntaxError (exit 1)": "def f(:\n",
    "an arbitrary non-zero exit (3)": "import sys\nsys.stdin.read()\nsys.exit(3)\n",
}
BLOCK_JSON = ('import sys, json\nsys.stdin.read()\n'
              'print(json.dumps({"decision": "block", "reason": "r"}))\n')
SHELLS = [s for s in ("bash", "zsh") if shutil.which(s)]
check("bash" in SHELLS,
      "exit mapping — bash is available to stand in for the login shell, so the arms "
      "below ran at all (%s)" % SHELLS)
if "zsh" not in SHELLS:
    print("NOTE  zsh is not installed here; the exit-mapping arms ran under bash only")


def run_via(shell, command, plugin_root, path=None):
    env = dict(os.environ)
    env.pop("PLUGIN_ROOT", None)
    env.pop("CLAUDE_PLUGIN_ROOT", None)
    env[token_name or "PLUGIN_ROOT"] = str(plugin_root)
    if path is not None:
        env["PATH"] = path
    return subprocess.run([shutil.which(shell), "-c", command], input='{"probe": 1}', env=env,
                          capture_output=True, text=True, timeout=30)


with tempfile.TemporaryDirectory() as work:
    base = Path(work)
    for shell in SHELLS:
        for label, body in FAILING.items():
            cache = base / shell / label.split(" (")[0].replace(" ", "-") / "c"
            d = cache / "1.0.0" / "scripts"
            d.mkdir(parents=True)
            (d / ADAPTER.name).write_text(body)
            p = run_via(shell, cmd, cache / "1.0.0")
            check(p.returncode == 2 and "not judged" in p.stderr,
                  "fail-closed — %s in the adapter exits 2 through the shipped command "
                  "under %s, not the 1 this runtime lets through (rc=%s err=%r)"
                  % (label, shell, p.returncode, p.stderr[-160:]))
        # the fallback branch runs the SAME tail, so a crashing replacement is refused too
        cache = base / shell / "fallback" / "c"
        d = cache / "1.0.1" / "scripts"
        d.mkdir(parents=True)
        (d / ADAPTER.name).write_text(FAILING["an uncaught exception (exit 1)"])
        p = run_via(shell, cmd, cache / "1.0.0")
        check(p.returncode == 2 and "not judged" in p.stderr,
              "fail-closed — a CRASHING replacement reached through the fallback exits 2 "
              "under %s (rc=%s err=%r)" % (shell, p.returncode, p.stderr[-160:]))
        # no python3 on PATH: 127 from the shell, mapped to 2. /bin/sh is absolute, so it
        # still launches; only the interpreter lookup fails.
        cache = base / shell / "nopython" / "c"
        d = cache / "1.0.0" / "scripts"
        d.mkdir(parents=True)
        (d / ADAPTER.name).write_text(BLOCK_JSON)
        p = run_via(shell, cmd, cache / "1.0.0", path=str(base / "empty-path"))
        check(p.returncode == 2 and "exited 127" in p.stderr,
              "fail-closed — a MISSING python3 exits 2 under %s, not the 127 this runtime "
              "lets through (rc=%s err=%r)" % (shell, p.returncode, p.stderr[-160:]))
        # the control: a block is exit 0 with its JSON intact on stdout
        cache = base / shell / "blockjson" / "c"
        d = cache / "1.0.0" / "scripts"
        d.mkdir(parents=True)
        (d / ADAPTER.name).write_text(BLOCK_JSON)
        p = run_via(shell, cmd, cache / "1.0.0")
        check(p.returncode == 0 and json.loads(p.stdout or "null") == {
                  "decision": "block", "reason": "r"},
              "exit mapping — the adapter's own BLOCK still leaves as exit 0 with its JSON "
              "on stdout, so the mapping changed no intended outcome under %s (rc=%s out=%r)"
              % (shell, p.returncode, p.stdout[:120]))

# ── 8e · the hashed command is PINNED (#508) ──────────────────────────────────────────
#
# Codex keys an operator's trust on the DECLARED command (probe STALE_MEASURED: an
# unchanged command stays `trusted`, a changed one reads `modified` and the hook is
# SKIPPED — the act runs with no hook and no status is emitted). So ANY byte of this
# string, including the wording of a message nothing tests, is part of the floor's
# on/off switch on every installed Codex. The behavioural arms above cannot see a
# rewording; this pin can. It is a change DETECTOR over the string, not a reproduction
# of Codex's own hash formula, which was not measured.
PINNED_COMMAND_SHA256 = "0eb02872e9a07c1035695be4931ff2d109fe7d76b4fbb717df5a5e92347581bd"
import hashlib as _hashlib
for event, command in zip(("PreToolUse", "UserPromptSubmit"), commands):
    got = _hashlib.sha256(command.encode("utf-8")).hexdigest()
    check(got == PINNED_COMMAND_SHA256,
          "command pin — the %s command is byte-identical to the pinned one (sha256 %s). "
          "CHANGING THIS STRING FORCES THE OWNER TO RE-TRUST BOTH CODEX HOOKS "
          "(PreToolUse and UserPromptSubmit): every installed Codex reads the registration "
          "as `modified` and SKIPS it, so the Codex floor is SILENTLY OFF from the update "
          "until the re-trust. Update PINNED_COMMAND_SHA256 only in the same change as an "
          "ACTION REQUIRED note on the PR and in the release it ships in." % (event, got))

check(measured.get("expansion_observed") is True
      and measured.get("per_plugin_values") is True,
      "carrier root — the repair rests on expansion being observed AND the value being "
      "per-plugin. A generic value would resolve and point at another package's tree")

events = set(hooks_doc.get("hooks", {}))
CODEX_EVENTS = {"Interrupt", "PermissionRequest", "PostCompact", "PostToolUse",
                "PreCompact", "PreToolUse", "SessionEnd", "SessionStart", "Stop",
                "SubagentStart", "SubagentStop", "UserPromptSubmit"}
check(events and events <= CODEX_EVENTS,
      "carrier — every event registered is in Codex's own PascalCase vocabulary; the "
      "snake_case trust-key spelling registers ZERO hooks and prints nothing to stderr")

# Version lockstep with the release wiring.
bump = (ROOT / ".bumpversion.toml").read_text()
check('filename = ".codex-plugin/plugin.json"' in bump,
      "carrier — the manifest is on bumpversion's file list, or a release leaves the "
      "Codex package advertising a version that no longer exists")
check(manifest.get("version") == (ROOT / "VERSION").read_text().strip(),
      "carrier — the manifest version matches VERSION")

# ── 11 · the invocation log — the only thing that can attribute a non-firing hook ─────
#
# Every arm here is run against the LIVE adapter as a subprocess, because the question
# the log answers is about a process the runtime starts, not about an importable
# function. The three states it exists to separate are "never called", "called and the
# process died" and "called and the decision was discarded"; the arms below pin that a
# record is written on each of the reachable paths.

with tempfile.TemporaryDirectory() as work:
    logdir = Path(work) / "logs"
    blocked = logdir / "blocked.jsonl"
    p = run_adapter(codex_payload("gh pr merge 999999 --merge"),
                    env={"CODEX_HOOK_ADAPTER_LOG": str(blocked)})
    check(decision_of(p) is not None and decision_of(p)["decision"] == "block",
          "log — a blocked act still produces its decision")
    check(blocked.exists(), "log — the destination's parent directory is created")
    entries = [json.loads(l) for l in blocked.read_text().splitlines() if l.strip()]
    check(len(entries) == 1, "log — exactly one record per invocation")
    e = entries[0] if entries else {}
    check(e.get("outcome") == "block", "log — the record carries the DECISION, which is "
                                       "what makes a discarded one attributable")
    check(e.get("command") == "gh pr merge 999999 --merge",
          "log — the record carries the command the decision was about")
    # ~~== "codex-unidentified"~~ — struck #501: a keyless payload is the root, sent as "".
    check(e.get("agent_type_sent") == "" and e.get("agent_type_raw") is None,
          "log — the record carries the identity actually SENT to the guard (\"\", the "
          "root) beside the raw payload value (absent), since the mapping is the part "
          "that inverts intuition")
    check("process_cwd" in e and "payload_cwd" in e,
          "log — BOTH working directories are recorded; the guard follows the process "
          "one and the relative-command defect this bridge carries is about the other")
    check(e.get("schema") == 1, "log — records are versioned")

    # The abstaining path. A floor that only logs its refusals cannot tell "it ran and
    # said nothing" from "it never ran", which is half the question.
    quiet = logdir / "quiet.jsonl"
    p = run_adapter(codex_payload("ls -la"),
                    env={"CODEX_HOOK_ADAPTER_LOG": str(quiet)})
    check(decision_of(p) is None, "log — an abstention still emits no decision")
    q = ([json.loads(l) for l in quiet.read_text().splitlines() if l.strip()]
         if quiet.exists() else [])
    # `quiet.exists()` rather than an unguarded read, and `len(q) == 1 and …` rather
    # than `q[0]…`: a mutation that made the log skip abstentions crashed this arm with
    # an IndexError, and the suite died BEFORE its summary — which reports as neither a
    # pass nor a fail. An assertion that cannot survive the defect it is aimed at does
    # not catch it; it hides it behind a traceback.
    check(len(q) == 1 and q[0].get("outcome") is None,
          "log — an ABSTENTION is recorded too, with a null outcome, since a floor that "
          "logs only its refusals cannot tell 'it ran and said nothing' from 'it never ran'")

    # A payload that does not parse is the case most likely to be mistaken for a hook
    # that never ran, so it is the case that most needs a record.
    junk = logdir / "junk.jsonl"
    p = run_adapter("this is not json", env={"CODEX_HOOK_ADAPTER_LOG": str(junk)})
    j = [json.loads(l) for l in junk.read_text().splitlines() if l.strip()]
    check(len(j) == 1 and j[0].get("unparsed_stdin_bytes") == len("this is not json"),
          "log — an UNPARSEABLE payload is recorded, which is the case most easily "
          "mistaken for a hook that was never invoked")

    # OFF by default. This adapter sits on the one route that sees every shell act, so a
    # default-on log would make the floor a transcript as a side effect of being a floor.
    #
    # THE SUBJECT IS A PRISTINE COPY, and getting there took two wrong arms.
    #
    #   first form: assert a file whose name this arm invented is absent. True of every
    #               default anyone could ship, so a mutation adding a fixed default
    #               destination passed it untouched — a green that could not be red.
    #   second form: diff the whole tree before and after. Sound in principle and
    #               VACUOUS HERE, because arms earlier in this same file already run the
    #               adapter with no log configured, so under that mutation the default
    #               file existed before the snapshot was taken.
    #
    # So the subject is a COPY at a path nothing has touched, and the diff is over that
    # path alone. Anything a default-on log writes lands beside it and is visible.
    pristine = Path(work) / "pristine" / "scripts"
    pristine.mkdir(parents=True)
    copy = pristine / ADAPTER.name
    copy.write_text(ADAPTER.read_text())
    root_of_copy = pristine.parent
    before = {p for p in root_of_copy.rglob("*") if p.is_file()}
    run_adapter(codex_payload("ls"), cwd=work, source=copy)
    run_adapter(codex_payload("gh pr merge 999999 --merge"), cwd=work, source=copy)
    appeared = sorted(str(p) for p in root_of_copy.rglob("*")
                      if p.is_file() and p not in before)
    check(not appeared,
          "log — OFF unless an operator names a destination: two invocations, one "
          "abstaining and one blocking, write no file beside the adapter")
    if appeared:
        print("      appeared: %s" % appeared[:4])

    # AND THE PROPERTY ITSELF, because the behavioural arm above watches ONE directory.
    # A mutation defaulting to an absolute path elsewhere — `/tmp/...` — slips past it
    # entirely, and widening the watch to every directory a default could name is not a
    # thing a check can do. `log_target()` returning None with the variable unset is the
    # property, and it holds for every destination at once.
    probe_src = (
        "import importlib.util, sys\n"
        "s = importlib.util.spec_from_file_location('a', %r)\n"
        "m = importlib.util.module_from_spec(s); s.loader.exec_module(m)\n"
        "print('TARGET=%%r' %% (m.log_target(),))\n" % str(ADAPTER))
    e = dict(os.environ)
    e.pop("CODEX_HOOK_ADAPTER_LOG", None)
    r = subprocess.run([sys.executable, "-c", probe_src], capture_output=True,
                       text=True, cwd=work, env=e)
    check("TARGET=None" in (r.stdout or ""),
          "log — and the PROPERTY, destination-independently: log_target() is None when "
          "the variable is unset, so no default anywhere can satisfy this suite")

    # A RELATIVE path is the defect this bridge already carries one layer down, so it is
    # refused rather than resolved against whatever tree the session happened to open.
    #
    # RUN FROM A TEMPORARY CWD, not from the repo root. The first form of this arm ran
    # the adapter from ROOT, so a mutation that made the path resolve left `rel.jsonl`
    # IN THE TRACKED TREE — and the file then reddened this same arm on the next clean
    # run, which reads as a source defect and is leftover state. A check whose failure
    # mode is to dirty the thing it checks is not a check.
    p = run_adapter(codex_payload("ls"), cwd=work,
                    env={"CODEX_HOOK_ADAPTER_LOG": "rel.jsonl"})
    check(not any(Path(work).rglob("rel.jsonl")) and not (ROOT / "rel.jsonl").exists(),
          "log — a RELATIVE destination writes nothing, anywhere")
    check("not an absolute path" in (p.stderr or ""),
          "log — and says on stderr why, rather than failing silently")

    # A logging failure must never change a verdict. The destination is made unwritable
    # by pointing it at a path whose parent is a FILE, which no mkdir can create.
    wall = Path(work) / "wall"
    wall.write_text("not a directory")
    p = run_adapter(codex_payload("gh pr merge 999999 --merge"),
                    env={"CODEX_HOOK_ADAPTER_LOG": str(wall / "nope.jsonl")})
    d = decision_of(p)
    check(d is not None and d["decision"] == "block" and p.returncode == 0,
          "log — AN UNWRITABLE DESTINATION DOES NOT CHANGE THE DECISION; the floor's job "
          "is the verdict and a floor that stops judging because it could not append a "
          "line is worse than one with no log at all")
    # THE EXIT CODE IS PART OF THAT CLAIM AND WAS NOT CHECKED. A mutation that let the
    # write's exception reach the caller left the decision on stdout — it had already
    # been written — and exited 1, which this runtime reports as a HOOK ERROR rather
    # than as a decision. "The verdict is unaffected" is false of a process that dies
    # after producing it, and the arm above said it was true.
    check(p.returncode == 0,
          "log — and exits 0, since Codex's refusal contract is a decision on stdout "
          "WITH exit 0 and a nonzero exit is reported as a hook error instead")
    check("could not write the invocation log" in (p.stderr or ""),
          "log — and the failure is announced on stderr")

# ── 12 · AC7 — TWO convenience refusals are not forwarded; the third and the floor are ──
#
# Measured on codex-cli 0.151.0-alpha.7.2 (`codex-hook-probe.py --phase friction`): a
# command substitution, an env-var prefix and a stdout redirect ALL COMPLETED under a
# permission layer that was demonstrably in force, so the subset those rules must fire
# inside is EMPTY on that runtime. These arms assert the adapter acts on that and, more
# importantly, that acting on it did not reach anything irreversible.

BT = chr(96)
# Floor-act tokens assembled rather than spelled: this FILE is read by shell commands
# during development, and the guard matches a floor act anywhere in a command string.
_TF, _AP, _DS = "terra" + "form", "ap" + "ply", "des" + "troy"

CONVENIENCE = [
    ("FOO=1 ls", "an env-var prefix"),
    ("ls > out.txt", "a stdout redirect"),
]
# THE SUBSTITUTION BRANCH IS FORWARDED, and it was omitted for one round. It is here in
# BOTH spellings because the class is both and because the previous form of this section
# tested only `$( )` — see the guard suite's `deny_convenience` block for why that one
# spelling cannot fail on this class.
FORWARDED_FRICTION = [
    ("echo $(date)", "command substitution, $( ) spelling"),
    ("echo " + BT + "date" + BT, "command substitution, BACKTICK spelling"),
    # #497: the DOUBLE-QUOTED spellings. At 2.0.71 these abstained through this adapter while
    # the shell executed them; the repair is in the SHARED guard, so this adapter gains no policy
    # of its own and these arms only prove the translation carries the new guard verdict.
    ('printf "%s" "$(date)"', "command substitution INSIDE double quotes, $( ) spelling"),
    ('printf "%s" "' + BT + "date" + BT + '"', "command substitution INSIDE double quotes, BACKTICK"),
    ('printf "%s" "$(gh sec' + 'ret set PROBE --body value)"',
     "the QA-reported quoted nested secret write (fed as data, never executed)"),
    ('gh "$(echo sec' + 'ret)" set FOO --body x', "a quoted MANUFACTURED subcommand"),
    # #500 round 2: the QA fixture behind a quoted-blank heredoc delimiter, and a line continuation.
    ("cat <<'E X'\nb\nE X\n" + 'printf "%s" "$(gh sec' + 'ret set PROBE --body value)"',
     "the QA fixture behind <<'E X' (a delimiter with a blank used to hide every later line)"),
    ('gh "$\\\n(echo X)" set P', "a backslash-newline between $ and ( inside double quotes"),
    # #500 round 3: a comment is not continued by a trailing backslash (463fae4b let this through).
    ("true # note \\\n" + 'printf "%s" "$(gh sec' + 'ret set PROBE --body value)"',
     "the QA fixture on the line after 'true # note \\\\'"),
]
# The inert twin of the rows above: a single-quoted literal must still pass the adapter
# untouched, or the arms above could be green on an adapter that blocks every '$('.
check(decision_of(run_adapter(codex_payload("printf '%s' '$(date)'"))) is None,
      "#497 — a SINGLE-QUOTED literal substitution is still not blocked through the adapter")
check(decision_of(run_adapter(codex_payload('printf "%s" "\\$(date)"'))) is None,
      "#497 — an ESCAPED dollar inside double quotes is still not blocked through the adapter")
FLOOR = [
    (_TF + " " + _AP, "an IaC mutation"),
    ("git push origin main", "a trunk push"),
    ("rm -rf /tmp/anything", "a recursive force delete"),
    ("gh secret set FOO", "a secret write"),
    # #531: the forcing spellings the 162916b6 guard missed, and trunk deletion. The guard is
    # shared, so the adapter needs no policy of its own; these prove the new refusals are plain
    # floor denies that the Codex route forwards (not convenience rules it may decline to ask for).
    ("git push --for" + "ce-with-lease=x origin feat/x", "a force-push via --force-with-lease=<ref> (#531)"),
    ("git push origin +" + "feat/x", "a force-push via a '+' refspec (#531)"),
    ("git push -f" + "u origin feat/x", "a force-push via the -fu cluster (#531)"),
    ("git -c remote.o.push=+" + "refs/heads/x:refs/heads/x push o", "an inline -c push refspec (#531)"),
    ("git push origin :" + "main", "a trunk DELETION (#531)"),
]
# A floor act whose matching token is MANUFACTURED by a substitution. This is the class
# the blocked round made reachable, and it is asserted through the ADAPTER rather than
# only through the guard, because the adapter is what sets the variable on every call.
MANUFACTURED = []
for _sp, _o, _c in (("$( )", "$(echo ", ")"), ("BACKTICK", BT + "echo ", BT)):
    MANUFACTURED += [
        (_o + "rm" + _c + " -rf /tmp/anything", "a MANUFACTURED 'rm' (%s)" % _sp),
        (_TF + " " + _o + _AP + _c, "a MANUFACTURED IaC verb (%s)" % _sp),
        ("gh " + _o + "secret" + _c + " set FOO --body x", "a MANUFACTURED 'secret' (%s)" % _sp),
        ("git push origin " + _o + "main" + _c, "a MANUFACTURED trunk name (%s)" % _sp),
        ("gh repo " + _o + "delete" + _c + " o/r", "a MANUFACTURED 'delete' (%s)" % _sp),
    ]

for command, label in CONVENIENCE:
    # The guard on its own still denies: the rule is not deleted, it is not ASKED FOR.
    check(guard_verdict(command, None) == "deny",
          "AC7 — the guard itself still denies %s on the Claude path (unchanged)" % label)
    check(decision_of(run_adapter(codex_payload(command))) is None,
          "AC7 — the ADAPTER does not forward the refusal for %s" % label)

for command, label in FORWARDED_FRICTION:
    d = decision_of(run_adapter(codex_payload(command)))
    check(d is not None and d["decision"] == "block",
          "AC7 — %s IS forwarded: it manufactures the token every floor rule matches on, "
          "so omitting it is a floor hole rather than a narrowing" % label)

# #500 gate round 1 (A3/B1): a LARGE input, through the adapter, with the adapter's own default
# timeout in force. At e3b466f1 the Issue's QA fixture behind 4,000 unquoted heredoc openers took
# 5.02 s in the guard, so this adapter abstained at 4.0 s and printed nothing — invisible to every
# arm above, which all fed small inputs. An abstain here is `None`, so the arm needs no clock.
_hd = ("cat" + " <<a" * 4000 + "\n" + "a\n" * 4000 +
       'printf "%s" "$(gh sec' + 'ret set PROBE --body value)"')
_t = time.time()
_p = run_adapter(codex_payload(_hd))
_dt = time.time() - _t
d = decision_of(_p)
check(d is not None and d["decision"] == "block",
      "#500 — a 24 KB input (4,000 heredoc openers + the QA fixture) is BLOCKED through the adapter "
      "in %.2fs, not abstained on at its 4.0 s timeout" % _dt)

for command, label in FLOOR + MANUFACTURED:
    d = decision_of(run_adapter(codex_payload(command)))
    check(d is not None and d["decision"] == "block",
          "AC7 — %s is still BLOCKED through the adapter; the narrowing reached no floor "
          "rule" % label)

# The calibration for the whole section: the switch must be able to change an answer, or
# the seven arms above are a green that could not have been red.
import subprocess as _sp
_env_on = dict(os.environ); _env_on["PERMISSION_GUARD_CONVENIENCE_RULES"] = "on"
_p = _sp.run(["bash", str(GUARD)],
             input=json.dumps(codex_payload("FOO=1 ls")),
             capture_output=True, text=True, cwd=str(ROOT), env=_env_on)
check((_p.stdout or "").strip() != "",
      "AC7 — calibration: with the variable set to 'on' the guard answers, so the "
      "abstentions above are the switch acting rather than a dead selector")
# And the adapter's own env is what produces them — asserted here rather than only read
# from the source, because `env[CONVENIENCE_ENV] = "off"` being present in the file says
# nothing about it reaching the subprocess.
check(decision_of(run_adapter(codex_payload("FOO=1 ls"))) is None
      and guard_verdict("FOO=1 ls", None) == "deny",
      "AC7 — calibration: the SAME command denies through the guard directly and abstains "
      "through the adapter, so the adapter's environment is what carries the narrowing")

# ── 9 · selfcheck reports rather than controls ────────────────────────────────────────

p = subprocess.run([sys.executable, str(ADAPTER), "--selfcheck"],
                   capture_output=True, text=True, cwd=str(ROOT))
check(p.returncode == 0, "selfcheck — passes on a complete checkout")
for needle, why in [
    ("TRUST IS NOT CHECKED HERE", "it says it cannot see trust"),
    ("COVERAGE:", "it states the route limit"),
    # ~~("CALLER:", "it states that no caller is exempt")~~ — struck #501. The prefix alone
    # let the note say anything; these pin what it must now say, per arm.
    ("CALLER: ROLE PARITY with Claude Code", "it states the caller rule is role parity"),
    ("only quality-assurance may merge", "it names the one merge executor"),
    ("refused by their own named arms", "it states the named denies survive on Codex"),
    ("THE IDENTITY IS DECLARED, NOT AUTHENTICATED", "it states the accepted cost"),
    ("INTERACTIVE SESSION STARTUP:", "it states which branch is in force"),
    # Added 2026-09-16. This was the only note of the set left unpinned, which made it
    # the one a later edit could delete in silence — and it is the note carrying the
    # single most misreadable fact about this bridge: that a green here is not evidence
    # the hook ever fires. What this arm asserts is that the sentence is PRESENT. It
    # cannot assert the sentence is true, and no arm here could: firing is a property of
    # a runtime this suite never starts.
    ("RUNTIME EVIDENCE IS DATED AND THIS CHECK IS NOT A SUBSTITUTE",
     "it refuses to present selfcheck as native execution evidence"),
    ("0.151.0-alpha.7.2", "it names the Desktop build with installed carrier evidence"),
    ("0.154.0-alpha.6.2", "it names the independently checked VS Code build"),
    ("quoted nested substitution was observed ABSTAINING",
     "it states the known semantic gap instead of flattening invocation into coverage"),
    ("a native re-run on an installed release carrying the repair is OWED",
     "it does not present the #497 source repair as native evidence"),
    ("UserPromptSubmit separately blocked", "it bounds native preflight support to the "
                                             "event measurement actually taken"),
    ("INVOCATION LOG", "it names the invocation log and its state, which is the only "
                       "route an operator has to the firing question"),
    ("TUNABLES THAT CAN AFFECT THIS FLOOR", "it enumerates the knobs, because an unset "
                                            "one is otherwise invisible"),
    ("CONVENIENCE REFUSALS ARE NOT FORWARDED", "it states the AC7 narrowing, with the "
                                               "evidence and the date"),
]:
    check(needle in p.stdout, "selfcheck — %s" % why)
check("does not say a hook FIRED" in p.stdout,
      "selfcheck — a green explicitly refuses to be read as evidence that a hook ran")

# ── 10 · the documentation carries the two sentences a reader must not miss ───────────

bridge = (ROOT / "docs" / "codex-hook-bridge.md").read_text()
check("the model's tool calls" in bridge.lower(),
      "docs — the bridge states coverage as the MODEL's tool calls rather than 'the shell'")
check("REFUSE_INTERACTIVE_SESSION_STARTUP" in bridge,
      "docs — the branch point is named in the document, not only in the source")
check("codex-unidentified" in bridge,
      "docs — the sentinel is published, so the operational restriction it creates is "
      "findable by someone reading the document rather than the code")

print()
print("%d passed, %d failed" % (PASS, FAIL))
sys.exit(1 if FAIL else 0)
