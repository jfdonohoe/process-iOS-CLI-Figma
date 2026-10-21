#!/usr/bin/env python3
"""PreToolUse hook for the ios-codebase-refactorer subagent.

Blocks any Bash call that would change Git state (commit, add, stash, push,
reset, checkout, ...). The agent's prompt already forbids these; this is the
second line of defence, because the prompt is only text. Exit 2 blocks the
call and shows the message to the agent; exit 0 lets it through.

Reads the hook JSON on stdin (hooks.md "Common input fields"):
  {"tool_name": "Bash", "tool_input": {"command": "..."}}
"""
import json
import shlex
import sys

GIT_WRITES = {
    "commit", "add", "stash", "push", "reset", "checkout", "restore", "rebase",
    "merge", "cherry-pick", "switch", "rm", "mv", "tag", "clean", "am", "apply",
    "revert",
}
# git options that take a value before the subcommand: git -C <dir> commit …
GIT_OPTS_WITH_VALUE = {"-C", "-c", "--git-dir", "--work-tree", "--namespace"}
SEPARATORS = {";", "&&", "||", "|", "&"}


# Read-only forms of otherwise state-changing subcommands.
READ_ONLY_FORMS = {("stash", "list"), ("stash", "show"), ("tag", "-l"), ("tag", "--list")}


def git_subcommand(tokens):
    """The git subcommand in one shell segment, or None for a read."""
    if "git" not in tokens:
        return None
    i = tokens.index("git") + 1
    while i < len(tokens):
        t = tokens[i]
        if t in GIT_OPTS_WITH_VALUE:
            i += 2
            continue
        if t.startswith("-"):
            i += 1
            continue
        nxt = tokens[i + 1] if i + 1 < len(tokens) else None
        if (t, nxt) in READ_ONLY_FORMS:
            return None
        return t
    return None


def offending(command):
    try:
        tokens = shlex.split(command, posix=True)
    except ValueError:
        tokens = command.split()
    segment = []
    for tok in tokens + [";"]:
        if tok in SEPARATORS:
            sub = git_subcommand(segment)
            if sub in GIT_WRITES:
                return sub
            segment = []
        else:
            segment.append(tok)
    return None


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0
    if payload.get("tool_name") != "Bash":
        return 0
    command = (payload.get("tool_input") or {}).get("command", "")
    sub = offending(command)
    if sub is None:
        return 0
    sys.stderr.write(
        f"Blocked: `git {sub}` changes Git state. The refactorer never commits, "
        "stages, stashes or resets; report the batch as ready and leave the "
        "commit to the user.\n"
    )
    return 2


if __name__ == "__main__":
    sys.exit(main())
