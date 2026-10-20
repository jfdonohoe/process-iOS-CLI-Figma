#!/usr/bin/env python3
"""Check whether an agent's `description` makes the main session delegate to it.

For each prompt in <agent>/triggers.json, starts a headless main session in a
copy of a fixture repo and watches the stream for Agent tool calls. The Agent
tool is deliberately NOT allowed (dontAsk mode denies it), so nothing actually
spawns: the model's choice is recorded from its tool_use, then the session is
killed. Cost is one or two main-session turns per prompt.

triggers.json: {"fixture": "cases/01-node-api", "prompts": [{"prompt": "...", "expect": true}, ...]}
"""
import argparse
import json
import shutil
import subprocess
import tempfile
import threading
import time
from pathlib import Path

AGENT_TOOL_NAMES = {"Agent", "Task"}


def check(agent, prompt, fixture, timeout, agent_file=None):
    tmp = Path(tempfile.mkdtemp(prefix="agent-trigger-"))
    repo = tmp / "repo"
    shutil.copytree(fixture / "repo", repo)
    if agent_file:
        # project agents live in the repo's .claude/agents/, which the fixture doesn't have
        (repo / ".claude" / "agents").mkdir(parents=True, exist_ok=True)
        shutil.copy(agent_file, repo / ".claude" / "agents" / f"{agent}.md")
    subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
    # stage everything so "review my staged changes" prompts have a real diff to look at
    subprocess.run(["git", "add", "-A"], cwd=repo, check=True)
    cmd = [
        "claude", "-p", "--verbose", "--output-format", "stream-json",
        "--no-session-persistence", "--permission-mode", "dontAsk",
        "--allowedTools", "Read,Glob,Grep",
        "--settings", json.dumps({"disableAllHooks": True}),
    ]
    proc = subprocess.Popen(cmd, cwd=repo, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                            stderr=subprocess.DEVNULL, text=True)
    proc.stdin.write(prompt)
    proc.stdin.close()
    fired = threading.Event()

    def on_timeout():
        fired.set()
        proc.kill()

    killer = threading.Timer(timeout, on_timeout)
    killer.start()

    spawned, agent_ids, other_tools, reason = [], set(), [], "session ended"
    usage = {"input_tokens": 0, "cache_read_input_tokens": 0, "cache_creation_input_tokens": 0, "output_tokens": 0}
    seen_msgs, cost = set(), None
    try:
        for line in proc.stdout:
            try:
                ev = json.loads(line)
            except json.JSONDecodeError:
                continue
            if ev.get("type") == "assistant":
                msg = ev.get("message", {})
                if msg.get("id") not in seen_msgs:  # one message can arrive split across events
                    seen_msgs.add(msg.get("id"))
                    for k in usage:
                        usage[k] += (msg.get("usage") or {}).get(k, 0) or 0
                for block in ev.get("message", {}).get("content", []):
                    if block.get("type") != "tool_use":
                        continue
                    if block.get("name") in AGENT_TOOL_NAMES:
                        spawned.append(block.get("input", {}).get("subagent_type") or "general-purpose")
                        agent_ids.add(block.get("id"))
                    else:
                        other_tools.append(block.get("name"))
                if agent in spawned:
                    reason = "target agent requested"
                    break
            elif ev.get("type") == "user" and agent_ids:
                results = [b for b in ev.get("message", {}).get("content", []) if b.get("type") == "tool_result"]
                if any(b.get("tool_use_id") in agent_ids for b in results):
                    reason = "first delegation round complete (target not among them)"
                    break
            elif ev.get("type") == "result":
                cost = ev.get("total_cost_usd")
                break
    finally:
        killer.cancel()
        if proc.poll() is None:
            proc.kill()
        proc.wait()
        shutil.rmtree(tmp, ignore_errors=True)
    if fired.is_set() and reason == "session ended":
        reason = "timeout"
    # cost is only reported when the session ends on its own; killed sessions report token usage instead
    return {"spawned": spawned, "other_tools": other_tools[:10], "reason": reason, "cost_usd": cost, "usage": usage}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--agent", required=True)
    ap.add_argument("--bench", required=True, help="benchmark dir for the agent (contains triggers.json)")
    ap.add_argument("--out", required=True)
    ap.add_argument("--timeout", type=int, default=240)
    ap.add_argument("--spec", default="triggers.json", help="prompt file inside --bench")
    ap.add_argument("--agent-file", help="install this .md as a project agent in each temp repo (for agents in a project's .claude/agents/)")
    args = ap.parse_args()

    bench = Path(args.bench).expanduser()
    spec = json.loads((bench / args.spec).read_text())
    fixture = bench / spec["fixture"]
    results = []
    for p in spec["prompts"]:
        start = time.time()
        r = check(args.agent, p["prompt"], fixture, args.timeout, args.agent_file)
        triggered = args.agent in r["spawned"]
        r.update(prompt=p["prompt"], expect=p["expect"], triggered=triggered,
                 correct=triggered == p["expect"], duration_s=round(time.time() - start, 1))
        results.append(r)
        print(f"[{'PASS' if r['correct'] else 'FAIL'}] expect={p['expect']} triggered={triggered} "
              f"spawned={r['spawned']} ({r['reason']}, {r['duration_s']}s, "
              f"out_tokens={r['usage']['output_tokens']}, cost={r['cost_usd']}) :: {p['prompt']}")

    out = Path(args.out).expanduser()
    out.mkdir(parents=True, exist_ok=True)
    (out / "triggers.json").write_text(json.dumps(results, indent=2))
    print(f"\n{sum(r['correct'] for r in results)}/{len(results)} correct; written to {out / 'triggers.json'}")


if __name__ == "__main__":
    main()
