#!/bin/bash
# Links this repo into ~/.claude so Claude Code uses it directly. The repo is the source of truth:
# edits made through ~/.claude paths land here and show up in `git status`.
# Safe to re-run. Existing real files are moved to ~/.claude/.pre-repo-backup/<timestamp>/ first.
set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"; C="$HOME/.claude"; B="$C/.pre-repo-backup/$(date +%Y%m%d-%H%M%S)"
# Prerequisites (SETUP.md §2–3): warn, don't stop, so a partial machine still gets linked.
missing=()
for t in jq gh node npx python3 xcodegen git; do command -v "$t" >/dev/null || missing+=("$t"); done
for t in xcodebuild swiftc swift-format xcresulttool devicectl; do xcrun --find "$t" >/dev/null 2>&1 || missing+=("xcrun $t"); done
if [ ${#missing[@]} -gt 0 ]; then echo "WARNING missing: ${missing[*]} (see SETUP.md)"; else echo "prerequisites ok"; fi
link() { local src="$REPO/$1" dst="$C/$2"; mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then rm "$dst"; elif [ -e "$dst" ]; then mkdir -p "$B/$(dirname "$2")"; mv "$dst" "$B/$2"; fi
  ln -s "$src" "$dst"; echo "linked ~/.claude/$2"; }
for f in ios-project-standard.md ios-splash-standard.md ios-project-standard.ledger splitaudit.md; do link "standard/$f" "$f"; done
link claude/CLAUDE.md CLAUDE.md
link skills/ios-project-standard skills/ios-project-standard
link skills/ios-version skills/ios-version
link hooks hooks
link tools tools
link agent-evals agent-evals
for f in agents/global/*.md; do link "$f" "agents/$(basename "$f")"; done
# The built §3.3 additions are user-level; the rest of agents/ios-baseline is copied per app (§3.1).
for a in schema-migration-reviewer design-sync-reviewer release-readiness-checker accessibility-reviewer; do link "agents/ios-baseline/$a.md" "agents/$a.md"; done
(cd "$REPO/tools" && swiftc -O -o sf-symbol-match sf-symbol-match.swift && swiftc -O -o sf-symbol-export sf-symbol-export.swift) && echo "built tools"
echo "Hooks: merge hooks/settings-hooks.json into ~/.claude/settings.json if they aren't there yet."
