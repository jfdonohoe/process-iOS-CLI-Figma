#!/bin/bash
# PostToolUse (Edit|Write|MultiEdit) — standard §13.2. Opt-in per project: runs only when the repo
# root has a .swift-format config, so a project without one gets no noise. Lints the edited .swift
# file and feeds back at most 12 findings (token-cheap).
f=$(jq -r '.tool_input.file_path // empty' 2>/dev/null); case "$f" in *.swift) ;; *) exit 0 ;; esac
[ -f "$f" ] || exit 0
root=$(git -C "$(dirname "$f")" rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -f "$root/.swift-format" ] || exit 0
res=$(xcrun swift-format lint --configuration "$root/.swift-format" "$f" 2>&1 | head -12)
[ -n "$res" ] || exit 0
jq -n --arg m "swift-format findings in $(basename "$f") (fix in this change if they're yours):
$res" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$m}}'
