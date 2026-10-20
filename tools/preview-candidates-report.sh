#!/bin/bash
# Summarises ~/.claude/preview-candidates.jsonl (written by hooks/preview-candidate.sh, standard §13.6):
# how many simulator runs there were, and how many a SwiftUI preview would have replaced. Usage: tools/preview-candidates-report.sh [log]
LOG="${1:-$HOME/.claude/preview-candidates.jsonl}"
[ -s "$LOG" ] || { echo "No simulator runs logged yet ($LOG)."; exit 0; }
jq -rs '
  (map(select(.kind=="sim-run"))) as $runs |
  (map(select(.kind=="preview-would-do"))) as $hits |
  "Since \($runs[0].timestamp // "?"): \($runs|length) simulator runs, \($hits|length) where a preview would have done.",
  ($hits[] | . as $h | ($runs[] | select(.id==$h.id)) as $r | "  \($r.timestamp)  \($r.project | split("/") | .[-1])  \($h.why)")
' "$LOG"
