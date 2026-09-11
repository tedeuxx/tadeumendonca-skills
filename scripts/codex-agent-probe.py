#!/usr/bin/env python3
"""Opt-in native input transport check using a loopback Responses stand-in.

Synthetic replies verify runtime transport, not model judgment or tool containment.
No API credentials, hook trust changes, or remote model requests are needed.
"""

import argparse
import http.server
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import threading
import tomllib
import uuid


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("binary", help="installed Codex executable")
    parser.add_argument("profile", type=Path, help="generated native profile TOML")
    parser.add_argument("mode", choices=("fresh", "inherit", "unknown"), nargs="?", default="fresh")
    parser.add_argument("--cwd", type=Path, default=Path.cwd(), help="explicit project directory for the diagnostic")
    parser.add_argument("--launcher-source", type=Path, help="exercise the shipped launcher from this source instead of direct role flags")
    parser.add_argument("--launcher-output", type=Path, help="checked snapshot for --launcher-source")
    args = parser.parse_args()
    if bool(args.launcher_source) != bool(args.launcher_output):
        parser.error("--launcher-source and --launcher-output are required together")
    binary = shutil.which(args.binary) or args.binary
    profile = args.profile.resolve()
    data = tomllib.loads(profile.read_text())
    role, instructions = data["name"], data["developer_instructions"]
    if not instructions or not role.startswith("tadeumendonca_"):
        parser.error("use a nonempty generated tadeumendonca_ profile")
    if args.launcher_output and profile != (args.launcher_output / "profiles" / f"{role}.toml").resolve():
        parser.error("profile must belong to the launcher snapshot")
    work = Path(tempfile.mkdtemp(prefix="codex-input-capture-")).resolve()
    requests, observations = [], []
    child_seen = threading.Event()
    lock = threading.Lock()
    parent_stage = 0
    parent_marker = "PARENT_HISTORY_" + uuid.uuid4().hex

    class Handler(http.server.BaseHTTPRequestHandler):
        def log_message(self, *unused):
            pass

        def do_POST(self):
            nonlocal parent_stage
            request = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
            with lock:
                requests.append(request)
                (work / f"request-{len(requests)}.json").write_text(json.dumps(request, indent=2))
            item = {"type": "message", "id": "msg_" + uuid.uuid4().hex, "role": "assistant", "status": "completed", "content": [{"type": "output_text", "text": "CAPTURE_COMPLETE", "annotations": []}]}
            texts = [part.get("text", "") for entry in request.get("input", []) for part in entry.get("content", []) if isinstance(part, dict)]
            serialized = json.dumps(request)
            is_child = any(instructions in text for text in texts)
            is_parent = parent_marker in serialized
            if is_child:
                observations.append({"full_profile": True, "parent_history_seen": is_parent})
                child_seen.set()
            elif is_parent and parent_stage == 0:
                parent_stage = 1
                item = {"type": "function_call", "id": "fc_native_capture", "call_id": "call_native_capture", "name": "spawn_agent", "namespace": "collaboration", "arguments": json.dumps({"task_name": "capture_reader", "agent_type": role if args.mode != "unknown" else "missing_profile_control", "fork_turns": "all" if args.mode == "inherit" else "none", "message": "Return CAPTURE_COMPLETE without tools."})}
            elif is_parent and args.mode != "unknown":
                child_seen.wait(timeout=20)
            response = {"id": "resp_" + uuid.uuid4().hex, "object": "response", "status": "completed", "output": [item], "usage": {"input_tokens": 1, "output_tokens": 1, "total_tokens": 2}}
            events = [{"type": "response.output_item.added", "output_index": 0, "item": item}, {"type": "response.output_item.done", "output_index": 0, "item": item}, {"type": "response.completed", "response": response}]
            payload = "".join("event: " + event["type"] + "\ndata: " + json.dumps(event) + "\n\n" for event in events).encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)

    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    overrides = ['model_provider="compat_capture"', 'model_providers.compat_capture.name="Local capture diagnostic"', "model_providers.compat_capture.base_url=" + json.dumps(f"http://127.0.0.1:{server.server_port}/v1"), 'model_providers.compat_capture.wire_api="responses"', 'model_providers.compat_capture.requires_openai_auth=false', 'developer_instructions="This is a local input-capture diagnostic. Only one harmless native delegation is authorized."', "agents." + role + '.description="Diagnostic reader"', "agents." + role + ".config_file=" + json.dumps(str(profile))]
    if args.launcher_source:
        # Direct role flags would hide a broken launcher, so none are retained.
        overrides = [setting for setting in overrides if not setting.startswith("agents.")]
    command = [binary, "exec", "--json", "--sandbox", "read-only", "--cd", str(args.cwd.resolve())]
    # A positive inherited-history control needs a durable native parent thread;
    # these builds cannot fork history from an ephemeral parent. All other runs
    # are ephemeral. No existing thread or configuration is modified.
    if args.mode != "inherit":
        command.append("--ephemeral")
    for setting in overrides:
        command.extend(["-c", setting])
    command.append("Delegate one child to the configured profile, then finish. Do not pass this parent-only history marker to the child: " + parent_marker)
    if args.launcher_source:
        import sys
        command = [sys.executable, str(args.launcher_source.resolve() / "scripts/codex-agent-build.py"), "--source", str(args.launcher_source.resolve()), "--output", str(args.launcher_output.resolve()), "--exec", *command]
    print(json.dumps({"artifacts": str(work), "binary": binary}), flush=True)
    try:
        version = subprocess.run([binary, "--version"], text=True, capture_output=True, timeout=10, check=True).stdout.strip()
        result = subprocess.run(command, text=True, capture_output=True, timeout=90, check=False)
        (work / "events.jsonl").write_text(result.stdout)
        (work / "stderr").write_text(result.stderr)
        unknown_rejected = "unknown agent_type 'missing_profile_control'" in json.dumps(requests)
        passed = result.returncode == 0 and parent_stage == 1
        if args.mode == "unknown":
            passed = passed and not observations and unknown_rejected
        else:
            passed = passed and len(observations) == 1 and observations[0]["parent_history_seen"] == (args.mode == "inherit")
        summary = {"passed": passed, "exit": result.returncode, "version": version, "command": command, "requests": len(requests), "child_full_profile_captured": child_seen.is_set(), "profile_characters": len(instructions), "profile_bytes": len(instructions.encode()), "role": role, "mode": args.mode, "child_observations": observations, "unknown_role_rejected": unknown_rejected, "evidence": "native model-input transport; synthetic Responses replies"}
        (work / "summary.json").write_text(json.dumps(summary, indent=2))
        print(json.dumps(summary), flush=True)
        return 0 if passed else 1
    except (OSError, subprocess.SubprocessError) as error:
        (work / "error.txt").write_text(str(error))
        print(json.dumps({"passed": False, "error": str(error), "artifacts": str(work)}), flush=True)
        return 1
    finally:
        server.shutdown()
        server.server_close()


if __name__ == "__main__":
    raise SystemExit(main())
