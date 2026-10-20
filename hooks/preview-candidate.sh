#!/bin/bash
# PostToolUse (XcodeBuildMCP build_run_sim): tracks whether removing Apple's Xcode MCP (RenderPreview) costs anything.
# Logs every simulator build-and-run to ~/.claude/preview-candidates.jsonl, then asks Claude to judge whether a
# SwiftUI preview of one view would have done the job; Claude appends that verdict and tells John. Standard §13.6.

LOG="${PREVIEW_CANDIDATE_LOG:-$HOME/.claude/preview-candidates.jsonl}"
in=$(cat)
id=$(date -u +%Y%m%dT%H%M%SZ)-$$
jq -c --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg id "$id" \
  '{kind:"sim-run", id:$id, timestamp:$ts, project:(.cwd // ""), launchArgs:(.tool_input.launchArgs // []), session_id:(.session_id // null)}' \
  <<<"$in" >> "$LOG" 2>/dev/null || exit 0

msg="Preview tracker (standard §13.6): this simulator run was logged as $id in $LOG. Decide whether its purpose was only to check how one view looks, so that a SwiftUI #Preview rendered by Xcode MCP RenderPreview (removed 2026-10-20) would have been enough. If yes, append one line with Bash: jq -nc --arg id $id --arg why '<one-line reason>' '{kind:\"preview-would-do\",id:\$id,why:\$why}' >> $LOG, and say so to John in one line in your reply (e.g. 'Preview tracker: a preview would have done this run.'). If the run needed real state, a flow, logs or the device, do nothing and say nothing."
jq -n --arg m "$msg" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$m}}'
exit 0
