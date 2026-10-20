#!/usr/bin/env python3
"""Count which MCP servers, skills and process tools Claude Code actually used (SETUP.md, "Audit your own machine").

Reads the session transcripts in ~/.claude/projects/ (Claude Code keeps about 30 days of them) and prints, per item:
calls, distinct sessions and the last date used. Read-only.

    tools/tool-usage-report.py [--projects DIR]
"""
import argparse, collections, json, pathlib

# Bash commands worth counting: the process's own tools and the CLIs SETUP.md lists.
BASH = ["xcodegen", "swift-format", "xcresulttool", "devicectl", "gh ", "osascript", "sim-drive.py", "sf-symbol-match",
        "sf-symbol-export", "sf-symbolset-extract", "contrast-ratio", "figma-frame-spec", "preview-candidates-report",
        "hooks-test.sh", "run_case.py"]

ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
ap.add_argument("--projects", default=str(pathlib.Path.home() / ".claude/projects"))
root = pathlib.Path(ap.parse_args().projects)

calls, sessions, last = collections.Counter(), collections.defaultdict(set), {}
oldest = None
for f in root.rglob("*.jsonl"):
    for line in f.open(errors="ignore"):
        if '"tool_use"' not in line:
            continue
        try:
            d = json.loads(line)
        except ValueError:
            continue
        ts = d.get("timestamp", "")[:10]
        oldest = min(oldest or ts, ts) if ts else oldest
        for b in (d.get("message") or {}).get("content") or []:
            if not isinstance(b, dict) or b.get("type") != "tool_use":
                continue
            name, inp = b.get("name", ""), b.get("input") or {}
            keys = []
            if name.startswith("mcp__"):
                keys = ["mcp: " + name.split("__")[1]]
            elif name == "Skill":
                keys = ["skill: " + str(inp.get("skill"))]
            elif name == "LSP":
                keys = ["plugin: LSP"]
            elif name == "Bash":
                keys = ["bash: " + t.strip() for t in BASH if t in inp.get("command", "")]
            for k in keys:
                calls[k] += 1
                sessions[k].add(f.stem)
                last[k] = max(last.get(k, ""), ts)

print(f"transcripts in {root} since {oldest or 'n/a'}")
print(f"{'calls':>6} {'sessions':>8}  {'last':10}  item")
for k, n in calls.most_common():
    print(f"{n:6} {len(sessions[k]):8}  {last[k]:10}  {k}")
print("\nAnything configured (claude mcp list, enabledPlugins) but missing here was not called in this window.")
