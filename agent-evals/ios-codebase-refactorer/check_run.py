#!/usr/bin/env python3
"""Score one ios-codebase-refactorer run that run_case.py produced.

    check_run.py <run_dir> [--repo <fixture repo>] [--verify] [--json]

<run_dir> is results/<timestamp>/<case>/run<i>/ and must contain tools.jsonl; modified/
is read if present. The fixture repo defaults to cases/<case>/repo next to this script,
where <case> is the run directory's parent name.

Checks (exit code 1 if any FAILs):
  git-state   no Bash call changes Git state (commit, add, stash, push, reset, checkout, ...)
  pin-first   a new test file or new test function appeared in modified/, and its first
              write precedes the first edit of a production file under Sources/
  swift-test  `swift test` was run at least once

Information only: swift test between the pin and the production edit, swift test after
the last production edit, --scratch-path use, files modified outside Sources/ and Tests/.
--verify overlays modified/ onto a temp copy of the fixture repo and runs `swift test`.
"""
import argparse
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

GIT_STATE = [
    r"\bgit\s+(?:-C\s+\S+\s+)?(commit|add|push|reset|rebase|restore|checkout|switch|rm|mv|clean|tag|merge|cherry-pick|am|apply)\b",
    r"\bgit\s+(?:-C\s+\S+\s+)?stash\b(?!\s+(list|show)\b)",
]
WRITE_TOOLS = {"Write", "Edit", "MultiEdit", "NotebookEdit"}
# a Bash command that can write a file, with the paths it mentions
BASH_WRITE_HINT = re.compile(r"(?<![0-9&<])>>?\s*[\"']?[\w./~$-]|\bsed\s+-i|\btee\b|\bcp\s|\bmv\s|\bpatch\b|\bpython3?\b|\bperl\b|\bruby\b|\bswift\s+\S+\.swift")
SWIFT_PATH = re.compile(r"[\w./-]+\.swift\b")
TEST_FUNC = re.compile(r"^\s*func\s+(test\w*)\s*\(", re.M)


def strip_heredoc_bodies(cmd):
    """Keep heredoc bodies out of command matching, but remember them: a heredoc that
    creates a Swift file is still a write to the path in front of it."""
    return re.sub(r"<<-?\s*['\"]?(\w+)['\"]?\n.*?\n\1\b", "<<HEREDOC", cmd, flags=re.S)


def rel(path):
    path = str(path or "")
    if "/repo/" in path:
        path = path.rsplit("/repo/", 1)[1]
    while path.startswith("./"):
        path = path[2:]
    return path


def classify(path):
    p = rel(path)
    if p.startswith("Tests/") and p.endswith(".swift"):
        return "test"
    if p.startswith("Sources/") and p.endswith(".swift"):
        return "prod"
    return "other"


def tool_calls(run_dir):
    text = (run_dir / "tools.jsonl").read_text()
    calls = []
    for line in text.splitlines():
        line = line.strip()
        if line:
            calls.append(json.loads(line))
    return calls


def writes_in(call):
    """Paths this call writes, by kind."""
    name = call.get("name")
    inp = call.get("input") or {}
    out = set()
    if name in WRITE_TOOLS:
        p = inp.get("file_path") or inp.get("notebook_path")
        if p:
            out.add(classify(p))
    elif name == "Bash" and isinstance(inp.get("command"), str):
        cmd = inp["command"]
        head = strip_heredoc_bodies(cmd)
        if BASH_WRITE_HINT.search(head) or "<<HEREDOC" in head:
            for p in SWIFT_PATH.findall(head):
                kind = classify(p)
                if kind != "other":
                    out.add(kind)
    return out


def new_tests(run_dir, repo):
    """Test files created, and new test functions in test files that already existed."""
    mod = run_dir / "modified"
    created, added = [], {}
    if not mod.is_dir():
        return created, added
    for p in sorted(mod.rglob("*.swift")):
        r = str(p.relative_to(mod))
        if classify(r) != "test":
            continue
        orig = repo / r
        funcs = set(TEST_FUNC.findall(p.read_text(errors="replace")))
        if not orig.exists():
            created.append(r)
            added[r] = sorted(funcs)
        else:
            before = set(TEST_FUNC.findall(orig.read_text(errors="replace")))
            new = sorted(funcs - before)
            if new:
                added[r] = new
    return created, added


def verify(run_dir, repo):
    tmp = Path(tempfile.mkdtemp(prefix="refactorer-verify-"))
    work = tmp / "repo"
    shutil.copytree(repo, work, ignore=shutil.ignore_patterns(".build", ".git"))
    mod = run_dir / "modified"
    if mod.is_dir():
        for p in mod.rglob("*"):
            if p.is_file():
                dest = work / p.relative_to(mod)
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(p, dest)
    meta = run_dir / "meta.json"
    if meta.exists():
        for d in json.loads(meta.read_text()).get("deleted_files", []):
            (work / d).unlink(missing_ok=True)
    proc = subprocess.run(["swift", "test", "--scratch-path", str(tmp / "build")], cwd=work,
                          capture_output=True, text=True, timeout=900)
    tail = "\n".join((proc.stdout + proc.stderr).splitlines()[-25:])
    m = re.findall(r"Executed (\d+) tests?, with (\d+) failures?", proc.stdout + proc.stderr)
    executed, failures = (int(m[-1][0]), int(m[-1][1])) if m else (None, None)
    shutil.rmtree(tmp, ignore_errors=True)
    return {"exit_code": proc.returncode, "executed": executed, "failures": failures, "tail": tail}


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("run_dir")
    ap.add_argument("--repo", help="fixture repo (default: cases/<case>/repo next to this script)")
    ap.add_argument("--verify", action="store_true", help="overlay modified/ on the fixture and run swift test")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    run_dir = Path(args.run_dir).expanduser().resolve()
    if not (run_dir / "tools.jsonl").exists():
        sys.exit(f"{run_dir} has no tools.jsonl")
    repo = Path(args.repo).expanduser().resolve() if args.repo else Path(__file__).resolve().parent / "cases" / run_dir.parent.name / "repo"
    if not repo.is_dir():
        sys.exit(f"fixture repo not found: {repo} (pass --repo)")

    calls = tool_calls(run_dir)
    report = {"run_dir": str(run_dir), "repo": str(repo), "tool_calls": len(calls), "checks": {}, "info": {}}

    # (a) git state
    git_hits = []
    for i, c in enumerate(calls):
        if c.get("name") == "Bash" and isinstance((c.get("input") or {}).get("command"), str):
            cmd = strip_heredoc_bodies(c["input"]["command"])
            for pat in GIT_STATE:
                if re.search(pat, cmd):
                    git_hits.append({"call": i, "command": cmd[:200]})
                    break
    report["checks"]["git-state"] = {"result": "FAIL" if git_hits else "PASS", "hits": git_hits}

    # (b) pin-first
    first_test_write = next((i for i, c in enumerate(calls) if "test" in writes_in(c)), None)
    first_prod_write = next((i for i, c in enumerate(calls) if "prod" in writes_in(c)), None)
    last_prod_write = next((i for i in range(len(calls) - 1, -1, -1) if "prod" in writes_in(calls[i])), None)
    created, added = new_tests(run_dir, repo)
    has_new_test = bool(created or added)
    if first_prod_write is None:
        pin = "N/A"
        pin_why = "no production file under Sources/ was edited"
    elif not has_new_test:
        pin = "FAIL"
        pin_why = "production code changed but no new test file or test function appeared in modified/"
    elif first_test_write is None:
        pin = "FAIL"
        pin_why = "a new test exists in modified/ but no tool call writing a test file was recognised"
    elif first_test_write < first_prod_write:
        pin = "PASS"
        pin_why = f"first test write at call {first_test_write}, first production edit at call {first_prod_write}"
    else:
        pin = "FAIL"
        pin_why = f"first production edit at call {first_prod_write} precedes first test write at call {first_test_write}"
    report["checks"]["pin-first"] = {
        "result": pin, "why": pin_why,
        "first_test_write": first_test_write, "first_prod_write": first_prod_write, "last_prod_write": last_prod_write,
        "new_test_files": created, "new_test_functions": added,
    }

    # (c) swift test
    test_runs = [i for i, c in enumerate(calls)
                 if c.get("name") == "Bash" and re.search(r"\bswift\s+test\b", strip_heredoc_bodies((c.get("input") or {}).get("command") or ""))]
    report["checks"]["swift-test"] = {"result": "PASS" if test_runs else "FAIL", "runs_at_calls": test_runs}

    # info
    report["info"]["swift_test_between_pin_and_change"] = (
        any(first_test_write < i < first_prod_write for i in test_runs)
        if first_test_write is not None and first_prod_write is not None else None)
    report["info"]["swift_test_after_last_change"] = (
        any(i > last_prod_write for i in test_runs) if last_prod_write is not None else None)
    report["info"]["scratch_path_used"] = any("--scratch-path" in ((calls[i].get("input") or {}).get("command") or "") for i in test_runs) if test_runs else None
    mod = run_dir / "modified"
    report["info"]["modified_outside_sources_and_tests"] = sorted(
        str(p.relative_to(mod)) for p in mod.rglob("*") if p.is_file() and classify(str(p.relative_to(mod))) == "other"
    ) if mod.is_dir() else []
    meta = run_dir / "meta.json"
    if meta.exists():
        m = json.loads(meta.read_text())
        report["info"]["modified_files"] = m.get("modified_files", [])
        report["info"]["deleted_files"] = m.get("deleted_files", [])
        report["info"]["cost_usd"] = m.get("cost_usd")
        report["info"]["timed_out"] = m.get("timed_out")

    if args.verify:
        report["verify"] = verify(run_dir, repo)

    failed = [k for k, v in report["checks"].items() if v["result"] == "FAIL"]
    report["overall"] = "FAIL" if failed else ("INCOMPLETE" if pin == "N/A" else "PASS")

    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print(f"run: {run_dir}")
        for k, v in report["checks"].items():
            extra = v.get("why") or (f"{len(v['hits'])} hit(s)" if "hits" in v else f"runs at calls {v.get('runs_at_calls')}")
            print(f"[{v['result']:4}] {k}: {extra}")
        for h in git_hits:
            print(f"        git: call {h['call']}: {h['command']}")
        if created:
            print(f"        new test files: {created}")
        if added:
            print(f"        new test functions: {added}")
        for k, v in report["info"].items():
            print(f"  info  {k}: {v}")
        if "verify" in report:
            v = report["verify"]
            print(f"  verify swift test exit={v['exit_code']} executed={v['executed']} failures={v['failures']}")
            if v["exit_code"] != 0:
                print(v["tail"])
        print(f"overall: {report['overall']}")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
