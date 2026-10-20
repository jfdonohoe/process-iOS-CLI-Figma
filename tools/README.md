# ~/.claude/tools

Reusable helpers referenced by `~/.claude/ios-project-standard.md`. Use these instead of rewriting them per session.

| Tool | What it does | Standard |
|---|---|---|
| `sim-drive.py` | Fallback only: tap, drag-scroll and screenshot the Simulator when XcodeBuildMCP's `ui-automation` workflow can't be enabled (check and enable that first, §2.6) | §2.6 |
| `sf-symbol-match.swift` | Finds an SF Symbol's private-use code point by rendering `NSImage(systemSymbolName:)` and matching it against every glyph in `SFSymbolsFallback.otf` (the SF Symbols app ships no name table). Prints `name<TAB>HEX<TAB>score`; lower score is better, under ~65 was always correct | §2.4 |
| `sf-symbol-export.swift` | Exports glyph outlines by code point as SVG at a chosen weight (400 regular, 590 semibold) | §2.4 |
| `sf-symbolset-extract.py` | Pulls one weight layer out of a custom `.symbolset` SVG | §2.4 |
| `figma-frame-spec.js` | Read-only `use_figma` script: set `TARGET` to a section id (or frame ids) and it returns a `figma-frame-spec/1` JSON (copy, order by `y`, fills with variable bindings or hex, type sizes, component variants and props; system chrome collapsed). Save it to `_reports/design-sync/<date>-<topic>.json` for `design-sync-reviewer` | §2.3, §3.3 |
| `contrast-ratio.sh` | WCAG contrast between a foreground and background: `#RRGGBB` or colorset components (`0.247,0.490,0.306`, `0x3F,…`, `63,…`), optional foreground opacity. Prints the ratio and pass/fail at 4.5:1 and 3:1. Read-only; used by `accessibility-reviewer` | §3.3 |
| `preview-candidates-report.sh` | Totals `~/.claude/preview-candidates.jsonl` (written by `hooks/preview-candidate.sh`): simulator runs logged, and the ones a SwiftUI preview would have replaced, with reasons. Read-only; for the monthly review | §13.6, §14.4 |

Build the Swift tools once: `swiftc -O -o sf-symbol-match sf-symbol-match.swift` (same for export). Font: `/Applications/SF Symbols*.app/Contents/Resources/Fonts/SFSymbolsFallback.otf`.
Figma import: upload the SVGs with `upload_assets` (multipart, filename = layer name; the first URL of a batch often 404s, so request one spare), then move each vector into its icon component.
