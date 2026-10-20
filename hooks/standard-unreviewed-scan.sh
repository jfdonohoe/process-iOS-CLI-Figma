#!/bin/bash
# SessionStart: list agents and skills (user-level, plus this project's) that are
# neither described in the iOS project standard nor recorded in its ledger. This
# catches ones John made himself (e.g. through /agents), which no write hook sees.

STANDARD="$HOME/.claude/ios-project-standard.md"
LEDGER="$HOME/.claude/ios-project-standard.ledger"
dir=$(jq -r '.cwd // empty' 2>/dev/null); [ -n "$dir" ] || dir="$PWD"

new=()
check() { # kind name path
  grep -qF -- "$2" "$STANDARD" 2>/dev/null && return
  grep -qE "^$1:$2 " "$LEDGER" 2>/dev/null && return
  new+=("$1 '$2' ($3)")
}
for f in "$HOME"/.claude/agents/*.md "$dir"/.claude/agents/*.md; do
  [ -f "$f" ] && [ "$(basename "$f")" != README.md ] || continue
  n=$(sed -n 's/^name:[[:space:]]*//p' "$f" | head -1); check agent "${n:-$(basename "$f" .md)}" "$f"
done
for f in "$HOME"/.claude/skills/*/SKILL.md "$dir"/.claude/skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  case "$f" in */skills/synced/*) continue ;; esac
  n=$(sed -n 's/^name:[[:space:]]*//p' "$f" | head -1); check skill "${n:-$(basename "$(dirname "$f")")}" "$f"
done
[ ${#new[@]} -gt 0 ] || exit 0

list=$(printf -- '- %s\n' "${new[@]}" | sort -u)
msg="These agents/skills haven't been reviewed for John's iOS project standard (~/.claude/ios-project-standard.md):
$list
At a natural pause early in this session (not before John's first request is handled), ask him once, in one short question, which of them to add, giving the section and tag for each. Add only what he says yes to. Record every answer, yes or no, in $LEDGER as '<kind>:<name> added|declined YYYY-MM-DD', so none of them is raised again."
jq -n --arg m "$msg" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $m}}'
