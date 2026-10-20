#!/usr/bin/env python3
"""Run a custom agent headless against one benchmark case, N times.

Each run gets a fresh copy of <case>/repo in a system temp dir (outside the
benchmark tree, so the agent under test can never see expected.json), turned
into a git repo so git log/blame work. If the case has history.json, the repo
gets that commit history (for rules about recently added code); otherwise one
commit. The agent runs via `claude -p --agent <name>` with only the tools its
frontmatter grants.

--context user      (default) the agent sees the user's global CLAUDE.md, as in real use
--context isolated  CLAUDE.md loading disabled, to attribute behavior to the agent definition alone

Writes, per run, under --out/<case>/run<i>/:
  result.md     the agent's final text
  raw.json      the final result event
  tools.jsonl   every tool call the agent made (name + input)
  modified/     copies of any files the agent created or changed in the workspace
  meta.json     cost, turns, duration, permission denials, modified/deleted files, context
"""
import argparse
import concurrent.futures as cf
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

AGENTS_DIR = Path.home() / ".claude" / "agents"


def load_agent(path):
    """Frontmatter + prompt body of an agent .md file."""
    import yaml
    text = Path(path).read_text()
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    if not m:
        sys.exit(f"{path} has no frontmatter")
    fm = yaml.safe_load(m.group(1)) or {}
    tools = fm.get("tools")
    if isinstance(tools, str):
        tools = [t.strip() for t in tools.split(",") if t.strip()]
    return fm, m.group(2), tools  # tools None = inherits all tools


def tree_hashes(root):
    out = {}
    for p in sorted(Path(root).rglob("*")):
        if ".git" in p.relative_to(root).parts or not p.is_file():
            continue
        out[str(p.relative_to(root))] = hashlib.sha256(p.read_bytes()).hexdigest()
    return out


def git(repo, *args, days_ago=None):
    env = dict(os.environ)
    if days_ago is not None:
        stamp = time.strftime("%Y-%m-%dT%H:%M:%S", time.localtime(time.time() - days_ago * 86400))
        env.update(GIT_AUTHOR_DATE=stamp, GIT_COMMITTER_DATE=stamp)
    subprocess.run(
        ["git", "-c", "user.name=agent-eval", "-c", "user.email=agent-eval@localhost", *args],
        cwd=repo, env=env, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )


def build_history(repo, case_dir):
    git(repo, "init", "-q")
    hist_file = case_dir / "history.json"
    if not hist_file.exists():
        git(repo, "add", "-A")
        git(repo, "commit", "-q", "-m", "fixture", days_ago=0)
        return
    hist = json.loads(hist_file.read_text())
    later = [p for c in hist["commits"] for p in c["paths"]]
    git(repo, "add", "-A")
    for p in later:
        git(repo, "reset", "-q", "--", p)
    git(repo, "commit", "-q", "-m", hist.get("base_message", "initial"), days_ago=hist.get("base_days_ago", 365))
    for c in hist["commits"]:
        git(repo, "add", "--", *c["paths"])
        git(repo, "commit", "-q", "-m", c["message"], days_ago=c["days_ago"])


def one_run(agent, case_dir, prompt, run_dir, tools, timeout, keep, context, inline_agents=None):
    if run_dir.exists():
        shutil.rmtree(run_dir)
    run_dir.mkdir(parents=True)
    tmp = Path(tempfile.mkdtemp(prefix="agent-eval-"))
    repo = tmp / "repo"
    shutil.copytree(case_dir / "repo", repo)
    build_history(repo, case_dir)
    before = tree_hashes(repo)

    cmd = [
        "claude", "-p", "--agent", agent, "--verbose",
        "--no-session-persistence",
        "--output-format", "stream-json",
        "--permission-mode", "dontAsk",
        "--settings", json.dumps({"disableAllHooks": True}),
    ]
    if inline_agents:
        cmd += ["--agents", json.dumps(inline_agents)]
    if tools:
        cmd += ["--allowedTools", ",".join(tools)]
    env = dict(os.environ)
    if context == "isolated":
        env["CLAUDE_CODE_DISABLE_CLAUDE_MDS"] = "1"

    start = time.time()
    timed_out = False
    try:
        proc = subprocess.run(cmd, cwd=repo, env=env, input=prompt, capture_output=True, text=True, timeout=timeout)
        stdout = proc.stdout
    except subprocess.TimeoutExpired as e:
        stdout = e.stdout.decode() if isinstance(e.stdout, bytes) else (e.stdout or "")
        timed_out = True
    duration = time.time() - start

    raw, tool_calls = None, []
    for line in stdout.splitlines():
        try:
            ev = json.loads(line)
        except json.JSONDecodeError:
            continue
        if ev.get("type") == "assistant":
            for b in ev.get("message", {}).get("content", []):
                if b.get("type") == "tool_use":
                    tool_calls.append({"name": b.get("name"), "input": b.get("input")})
        elif ev.get("type") == "result":
            raw = ev
    if raw is None:
        raw = {"is_error": True, "result": "", "unparsed_stdout_tail": stdout[-4000:]}

    after = tree_hashes(repo)
    modified = sorted(k for k in after if before.get(k) != after[k])
    deleted = sorted(k for k in before if k not in after)
    for rel in modified:
        dest = run_dir / "modified" / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(repo / rel, dest)

    (run_dir / "raw.json").write_text(json.dumps(raw, indent=2))
    (run_dir / "result.md").write_text(raw.get("result") or "")
    (run_dir / "tools.jsonl").write_text("".join(json.dumps(t) + "\n" for t in tool_calls))
    meta = {
        "agent": agent,
        "case": case_dir.name,
        "context": context,
        "agent_source": "inline snapshot" if inline_agents else "installed",
        "run_dir": str(run_dir),
        "workspace": str(repo) if keep else None,
        "timed_out": timed_out,
        "is_error": bool(raw.get("is_error")),
        "duration_s": round(duration, 1),
        "cost_usd": raw.get("total_cost_usd"),
        "num_turns": raw.get("num_turns"),
        "models": sorted((raw.get("modelUsage") or {}).keys()),
        "tool_calls": len(tool_calls),
        "permission_denials": raw.get("permission_denials", []),
        "modified_files": modified,
        "deleted_files": deleted,
        "allowed_tools": tools,
    }
    (run_dir / "meta.json").write_text(json.dumps(meta, indent=2))
    if not keep:
        shutil.rmtree(tmp, ignore_errors=True)
    return meta


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--agent", required=True)
    ap.add_argument("--case", required=True, help="path to a case dir containing repo/ and expected.json")
    ap.add_argument("--runs", type=int, default=3)
    ap.add_argument("--out", required=True)
    ap.add_argument("-j", "--concurrency", type=int, default=3)
    ap.add_argument("--timeout", type=int, default=900)
    ap.add_argument("--context", choices=["user", "isolated"], default="user")
    ap.add_argument("--agent-file", help="evaluate this .md snapshot instead of the installed ~/.claude/agents/<agent>.md "
                    "(e.g. a baseline copy, or a candidate before installing it)")
    ap.add_argument("--keep", action="store_true", help="keep temp workspaces for debugging")
    args = ap.parse_args()

    case_dir = Path(args.case).expanduser().resolve()
    expected = json.loads((case_dir / "expected.json").read_text())
    agent_path = Path(args.agent_file).expanduser() if args.agent_file else AGENTS_DIR / f"{args.agent}.md"
    fm, body, tools = load_agent(agent_path)
    run_agent, inline = args.agent, None
    if args.agent_file:
        # distinct name so it can't collide with the installed agent of the same name
        run_agent = f"{args.agent}__snapshot"
        spec = {"description": fm.get("description", ""), "prompt": body}
        if tools:
            spec["tools"] = tools
        if fm.get("model"):
            spec["model"] = fm["model"]
        inline = {run_agent: spec}
    out = Path(args.out).expanduser() / case_dir.name

    with cf.ThreadPoolExecutor(max_workers=max(1, args.concurrency)) as ex:
        futures = [
            ex.submit(one_run, run_agent, case_dir, expected["prompt"], out / f"run{i}", tools,
                      args.timeout, args.keep, args.context, inline)
            for i in range(1, args.runs + 1)
        ]
        metas = [f.result() for f in futures]

    for m in metas:
        flag = " TIMEOUT" if m["timed_out"] else (" ERROR" if m["is_error"] else "")
        mod = f" MODIFIED={m['modified_files']}" if m["modified_files"] else ""
        dele = f" DELETED={m['deleted_files']}" if m["deleted_files"] else ""
        print(f"{m['case']} {Path(m['run_dir']).name} [{m['context']}]: {m['duration_s']}s ${m['cost_usd']} "
              f"turns={m['num_turns']} tools={m['tool_calls']}{flag}{mod}{dele}")


if __name__ == "__main__":
    main()
