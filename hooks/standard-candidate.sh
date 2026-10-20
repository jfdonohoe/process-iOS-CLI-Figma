#!/bin/bash
# PostToolUse (Write|Edit): when Claude writes an agent, skill, hook or CLAUDE.md,
# remind it to ask the developer whether the change belongs in the iOS project standard.
# Silent for every other file, and for items already in the standard or the ledger.

STANDARD="$HOME/.claude/ios-project-standard.md"
LEDGER="$HOME/.claude/ios-project-standard.ledger"
LOCAL_LEDGER="$HOME/.claude/ios-project-standard.local.ledger"  # private answers, not in the repo

f=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' 2>/dev/null)
[ -n "$f" ] || exit 0

known() { grep -qF -- "$1" "$STANDARD" 2>/dev/null || grep -qE "^$2:$1 " "$LEDGER" "$LOCAL_LEDGER" 2>/dev/null; }
say() { jq -n --arg m "$1" '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $m}}'; exit 0; }
tail_rule="Ask the developer in one short question, giving the section and tag you'd file it under ([Sets]/[Breathe]/[RingKit]/[general]/[suggested]). Add it only on a yes. Either way, append one line to $LEDGER: '<kind>:<name> added|declined YYYY-MM-DD'."

case "$f" in
  "$STANDARD" | "$LEDGER" | "$LOCAL_LEDGER") exit 0 ;;
  */.claude/agents/README.md) exit 0 ;;
  */.claude/agents/*.md)
    name=$(sed -n 's/^name:[[:space:]]*//p' "$f" 2>/dev/null | head -1); [ -n "$name" ] || name=$(basename "$f" .md)
    if known "$name" agent; then
      grep -qF -- "$name" "$STANDARD" && say "You edited agent '$name', which ~/.claude/ios-project-standard.md describes. If the edit changed what it does or when it runs, tell the developer and offer to update its description there. Otherwise do nothing."
      exit 0
    fi
    say "New agent '$name' ($f) isn't in ~/.claude/ios-project-standard.md. Before finishing, ask the developer whether to add it: §3.1 baseline, §3.3 suggested, or §3.4 as a project-specific specialist example. $tail_rule" ;;
  */skills/synced/*) exit 0 ;;
  */skills/*/SKILL.md)
    name=$(sed -n 's/^name:[[:space:]]*//p' "$f" 2>/dev/null | head -1); [ -n "$name" ] || name=$(basename "$(dirname "$f")")
    known "$name" skill && exit 0
    say "New skill '$name' ($f) isn't in ~/.claude/ios-project-standard.md. Before finishing, ask the developer whether it belongs in the standard. $tail_rule" ;;
  "$HOME"/.claude/hooks/*)
    name=$(basename "$f")
    known "$name" hook && exit 0
    say "New hook script '$name' isn't in ~/.claude/ios-project-standard.md. If it automates part of the iOS workflow, ask the developer whether to record it in the standard. $tail_rule" ;;
  */CLAUDE.md | */CLAUDE.local.md)
    say "You edited $f. If this edit adds a new process step or rule (release, review, Figma, testing, versioning, agents), ask the developer whether it should become part of ~/.claude/ios-project-standard.md, so future apps get it too. Skip the question for project-specific facts such as file keys or ids, and for wording-only edits. If you ask, record the answer in $LEDGER as 'process:<short-slug> added|declined YYYY-MM-DD'." ;;
esac
exit 0
