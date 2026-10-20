# Changelog

Every merge to `main` adds an entry here, in the same merge, and the wiki's Changelog page is re-derived from it (standard §11.2). This repository has no releases, so entries are dated and name their commits; sections follow Keep a Changelog (Added / Changed / Fixed / Removed).

## 2026-10-20

### Added
- `tools/tool-usage-report.py`: counts what a Claude Code setup actually uses, from its session transcripts.
- `SETUP.md`: everything a fresh Mac needs for the process (accounts, apps, CLI tools, MCP servers, claude.ai connectors, plugins, hooks, permissions), each marked required, situational or optional from transcript usage. Linked from the README. (7495f4d)
- `install.sh` checks the prerequisites and warns about missing ones, and links the four built §3.3 reviewers into `~/.claude/agents/` (they had been linked by hand). (7495f4d)
- `CHANGELOG.md`, and a Changelog page in the wiki derived from it; standard §11 now gives every app's wiki one.
- `hooks/preview-candidate.sh` (§13.6): logs each XcodeBuildMCP simulator run and flags the ones a SwiftUI `#Preview` would have replaced; `tools/preview-candidates-report.sh` totals the log for the monthly review (§14.4). `tests/hooks-test.sh` now has 18 checks. (38b799c, ba9b48d)
- `release-readiness-checker` (4-case benchmark), a static §9 release gate, and `accessibility-reviewer` (6-case benchmark), with `tools/contrast-ratio.sh`. Visual accessibility fixes go through a Figma before/after WIP section first (§2.3). (4c77595)
- `design-sync-reviewer` (6-case benchmark), which compares built SwiftUI with a Figma frame spec, and `tools/figma-frame-spec.js`, the read-only export it reads (§2.3 step 4). (d8f6575)

### Changed
- Made public as `process-ios-cli-figma` (renamed from `ios-best-practices`). Every file now speaks of "the developer" rather than a named person, and says they/them; per-developer values (bundle prefix, projects folder, apps, GitHub owner, wiki location) move to a `Your setup` block in the standard, kept in `~/.claude/ios-setup.local.md` from `standard/ios-setup.template.md`. The case-study apps are Sets, Breathe and RingKit, a Bluetooth wearable SDK (tag `[RingKit]`).
- The wiki moved from a Google Doc to the GitHub wiki (§11.1: public repository).
- `SETUP.md` describes a generic fresh setup with the reference setup's usage figures, and a procedure for auditing an existing machine; the reference machine's own inventory moved to its private setup file.
- `hooks/settings-hooks.json` uses `$HOME` paths; the `make_cases.py` benchmark builders find their folder themselves; the ledger hooks also read a private `~/.claude/ios-project-standard.local.ledger`.
- The wiki uses no names: "the developer" for the person running the process, "the author" for the standard's owner (§11.2).
- `README.md` and `tools/README.md` list the preview-tracker report and all four hook events. (ba9b48d)
- Simulator UI automation (§2.6): check XcodeBuildMCP's `ui-automation` workflow first and lead the developer through enabling it; `tools/sim-drive.py` only as a fallback. (d4e070d)
- Accessibility reviews run only before a full (major) release, including the first; point and dot releases and new screens skip them (§3.3, §9, §12). (2741807)
- `accessibility-reviewer` checks dark appearance only when the project states it supports dark mode. (7d63bd4)

### Removed
- Unused MCP servers `playwright`, `chrome-devtools`, `figma-desktop` and `flaude` (broken placeholder path); the `swift-lsp` plugin disabled; stale allow rules in `settings.local.json`. (7495f4d)
- Apple's Xcode MCP (`xcrun mcpbridge`, `RenderPreview`): Xcode re-asked for access every Claude Code session and the server had never been called. The cheapest-visual-check rule (§6) no longer names it. (38b799c)

## 2026-10-19

### Added
- `schema-migration-reviewer` (5-case benchmark) for SwiftData model, schema, migration, container and export changes. (b4a1b68)
- One-shot next-session hand-off hook, `hooks/next-session.sh`. (c872f89)
- §13 guardrails as hooks (`ios-guard`, opt-in `swift-lint`, opt-in build gate), spec before code for non-UI work, modern Swift preferences; §14 evaluating the process; `tests/hooks-test.sh` (16 checks). Also §2.4 iOS semantic colours, §3.2 finding triage, §6 cheapest visual check first, §12 MCP builds and parallel sessions. (fa86dd7)
- The project wiki link in the README. (6a85509)
- Initial import from `~/.claude`: the standard, skills, hooks, tools, agents and evals, with `install.sh` linking them back. (5c7bb8c)
