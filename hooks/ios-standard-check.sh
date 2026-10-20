#!/bin/bash
# SessionStart hook: if the session's folder is an iOS project whose CLAUDE.md
# doesn't mention ios-project-standard yet, tell Claude to recommend the standard.
# Silent (no output) in every other case.

input=$(cat)
dir=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$dir" ] || dir="$PWD"
[ -d "$dir" ] || exit 0

# Never fire in the home folder or in ~/.claude itself.
case "$dir" in
  "$HOME" | "$HOME/.claude" | "$HOME/.claude/"*) exit 0 ;;
esac

# Already adopted (or deliberately declined): CLAUDE.md mentions the standard.
for f in "$dir/CLAUDE.md" "$dir/.claude/CLAUDE.md" "$dir/CLAUDE.local.md"; do
  [ -f "$f" ] && grep -q "ios-project-standard" "$f" && exit 0
done

# Detect an iOS project, looking at most two levels deep so this stays fast.
evidence=""
xcodeproj=$(find "$dir" -maxdepth 2 \( -name "*.xcodeproj" -o -name "*.xcworkspace" \) \
  -not -path "*/.build/*" -not -path "*/DerivedData/*" -not -path "*/Pods/*" \
  -not -name "project.xcworkspace" -print -quit 2>/dev/null)
if [ -n "$xcodeproj" ]; then
  evidence="${xcodeproj#$dir/}"
elif [ -f "$dir/project.yml" ] && grep -qiE "platform:[[:space:]]*iOS|iOS:" "$dir/project.yml"; then
  evidence="project.yml (iOS target)"
elif [ -f "$dir/Package.swift" ] && grep -q "\.iOS" "$dir/Package.swift"; then
  evidence="Package.swift (.iOS platform)"
fi
[ -n "$evidence" ] || exit 0

msg="iOS project detected ($evidence), and its CLAUDE.md doesn't mention ios-project-standard. Per the iOS Apps rule in ~/.claude/CLAUDE.md, recommend John's iOS project standard early in this session: offer to run the /ios-project-standard skill (Day one gap check) before or alongside the task. Don't set anything up without asking. Once John adopts or declines it, offer to add a line mentioning ios-project-standard to the project's CLAUDE.md, which stops this reminder."

jq -n --arg m "$msg" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $m}}'
