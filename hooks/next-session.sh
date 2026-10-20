#!/bin/bash
# SessionStart (startup) — one-shot hand-off. If ~/.claude/next-session.md exists, inject it as
# instructions for the new session. The session archives the file once it starts the work, so it runs once.
F="$HOME/.claude/next-session.md"; [ -f "$F" ] || exit 0
jq -n --rawfile m "$F" --arg h "NEXT-SESSION INSTRUCTIONS left by the previous session (one-shot). Carry them out with the first user message, whatever it says (e.g. \"go\"):" \
  '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:($h + "\n\n" + $m)}}'
