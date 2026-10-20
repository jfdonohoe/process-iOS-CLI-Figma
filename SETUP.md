# Fresh setup

Everything the process in `standard/ios-project-standard.md` runs on, in install order, so a new Mac can be set up from this file. Each item is marked **Required** (the process breaks or a gate goes silent without it), **Situational** (needed only for the step named) or **Optional**.

Usage figures come from the Claude Code session transcripts in `~/.claude/projects/` on 2026-10-20, which reach back to 2026-09-16. "Calls" are tool calls; "sessions" are distinct transcripts.

## 1. Accounts

| Account | Needed for | Status |
|---|---|---|
| Anthropic (Claude Max or API) | Claude Code itself; Opus is the default model (`"model": "opus"` in `~/.claude/settings.json`) | Required |
| GitHub, `jfdonohoe` | This repo (private, `jfdonohoe/ios-best-practices`) and every app repo; GitHub wikis for public repos (§11.1) | Required |
| Figma, with edit access to each app's file | Figma-driven development (§2) | Required |
| Google (Drive and Docs) | Private-repo wikis, including this repo's wiki (§11.1) | Required |
| Apple Developer Program | Signing, device installs (§8), TestFlight and App Store (§9) | Required for device and release; the simulator works without it |

## 2. Mac applications

| App | Needed for | Status |
|---|---|---|
| Xcode 26 (26.5 in use) | `xcodebuild`, Simulator, `xcrun simctl`, `xcrun devicectl` (device installs and the §8 bundle check), `xcrun xcresulttool` (test summaries, §12), `xcrun swift-format` (the lint hook, §13.2), `swiftc` (building `tools/`) | Required. Run it once to accept the licence and install an iOS simulator runtime |
| SF Symbols (the beta is installed) | The SF Symbol vector pipeline in `tools/` reads its `SFSymbolsFallback.otf` (§2.4) | Situational: icons in Figma |
| Figma desktop | Editing the files by hand. Claude uses the remote Figma MCP server, not the desktop app | Optional for Claude |

## 3. Command-line tools

| Tool | Needed for | Status |
|---|---|---|
| Claude Code CLI | Everything | Required |
| `git` (comes with Xcode) | Every repo | Required |
| `gh`, signed in with `gh auth login` | Repo and PR work (211 calls in 27 sessions) | Required |
| `jq` 1.6 or later | Every hook in `hooks/` parses its input with `jq`; without it the guard, lint, build gate and preview tracker do nothing | Required |
| Node.js with `npx` (22 in use) | Starts the XcodeBuildMCP server (and the Optional `npx` servers below) | Required |
| `python3` | `agent-evals/bin/` (the benchmark harness, run before any reviewer agent is trusted, §3.2), `tools/sim-drive.py`, `tools/sf-symbolset-extract.py` | Required for agent benchmarks |
| XcodeGen | Every app here is generated from a `project.yml` (WorkoutApp, Breathe `_Pilot`, Neuromarketing `App`, SenstreamRingKit2 `DemoApp`); `ios-guard.sh` blocks hand edits to `project.pbxproj` in those projects (§13.1) | Required |

Install the non-Apple ones with Homebrew: `brew install gh jq node python xcodegen`.

## 4. MCP servers (in `~/.claude.json`, user scope)

| Server | Entry | Needed for | Use | Status |
|---|---|---|---|---|
| `xcodebuildmcp` | `npx -y xcodebuildmcp@latest mcp`, env `XCODEBUILDMCP_ENABLED_WORKFLOWS=simulator,ui-automation` | Builds, tests and simulator UI automation (§2.6, §12) | 253 calls, 14 sessions | Required, with both workflows |
| `figma` | HTTP `https://mcp.figma.com/mcp`, signed in through `/mcp` | The whole Figma loop and `tools/figma-frame-spec.js` (§2, §3.3) | 767 calls, 11 sessions | Required |
| `context7` | `npx -y @upstash/context7-mcp` | Looking up current library docs (it was used to find how to enable XcodeBuildMCP's UI automation) | 3 calls, 1 session | Optional |

```bash
claude mcp add -s user xcodebuildmcp -e XCODEBUILDMCP_ENABLED_WORKFLOWS=simulator,ui-automation -- npx -y xcodebuildmcp@latest mcp
claude mcp add -s user --transport http figma https://mcp.figma.com/mcp
claude mcp add -s user context7 -- npx -y @upstash/context7-mcp   # optional
```

The Figma skills (`figma-use`, `figma-generate-design` and the rest) come from the Figma MCP server's resources; no Figma plugin is installed. Load `figma-use` before any `use_figma` call.

## 5. claude.ai connectors

Turned on at claude.ai → Settings → Connectors; Claude Code picks them up when signed in to the same account.

| Connector | Needed for | Use | Status |
|---|---|---|---|
| Google Docs | Writing the wiki Docs (§11.2) | 51 calls, 9 sessions | Required |
| Google Drive | Finding and placing the wiki Docs | 36 calls, 13 sessions | Required |
| Claude in Chrome (extension) | Viewing a finished wiki page (Google Doc or GitHub wiki) in the browser | 88 calls, 3 sessions | Optional: the Docs connector does the writing |
| Google Sheets | WorkoutApp's routine data, not the process | 55 calls, 3 sessions | Not part of the process (project data) |

## 6. Plugins

None are needed. Both installed plugins are disabled: `swift-lsp` (its `LSP` tool was never called in the transcript window; disabled 2026-10-20) and `frontend-design` (web work).

## 7. This repo

```bash
git clone https://github.com/jfdonohoe/ios-best-practices.git ~/Documents/Claude/Projects/ios-best-practices
cd ~/Documents/Claude/Projects/ios-best-practices && ./install.sh
```

`install.sh` first checks the prerequisites in §2–3 and warns about any that are missing. It then links into `~/.claude`: the standard, splash standard, ledger and `splitaudit.md`; `CLAUDE.md`; the two skills (`/ios-project-standard`, `/ios-version`); `hooks/`; `tools/`; `agent-evals/`; the global agents (`dead-code-finder`, `review-agent-evaluator`); and the four built §3.3 reviewers (`schema-migration-reviewer`, `design-sync-reviewer`, `release-readiness-checker`, `accessibility-reviewer`). It builds `tools/sf-symbol-match` and `tools/sf-symbol-export`.

The rest of `agents/ios-baseline/` (`swift-reviewer`, `ios-codebase-auditor`, `ios-codebase-refactorer`, `regression-reviewer`) is copied into each app's `.claude/agents/` and adapted (§3.1). The installer does not touch settings or MCP servers.

## 8. Settings (`~/.claude/settings.json`)

1. **Hooks.** Merge `hooks/settings-hooks.json` into `"hooks"`. Its paths are absolute (`/Users/john/.claude/hooks/…`): change them if the home folder differs. Then run `tests/hooks-test.sh`; all 18 checks must pass.

   | Hook | Event | State |
   |---|---|---|
   | `ios-guard.sh` | PreToolUse | Always on |
   | `ios-standard-check.sh`, `standard-unreviewed-scan.sh`, `next-session.sh` | SessionStart | Always on |
   | `standard-candidate.sh`, `preview-candidate.sh` | PostToolUse | Always on |
   | `swift-lint.sh` | PostToolUse | Opt-in per repo (`.swift-format`). No repo has opted in yet |
   | `build-gate.sh` | Stop | Opt-in per repo (`.claude/build-gate`). No repo has opted in yet |

2. **Permissions.** Allow `Bash(xcodebuild *)`, `Bash(xcrun simctl *)`, `Bash(xcrun devicectl *)` and `mcp__xcodebuildmcp`, so builds and simulator work don't prompt.
3. **Model.** `"model": "opus"`; mechanical work drops to Sonnet or lower effort per §12.

## 9. macOS permissions

- **Accessibility** for the terminal app (System Settings → Privacy & Security → Accessibility), only if `tools/sim-drive.py` is needed: it drives the Simulator through System Events. Situational, since XcodeBuildMCP's `ui-automation` workflow comes first (§2.6).
- **Developer Mode** on each test iPhone, and the phone paired with Xcode, before the first device install (§8).

## 10. Check it worked

1. `claude mcp list` shows `xcodebuildmcp` and `figma` connected.
2. `tests/hooks-test.sh` passes.
3. A session started in an app folder gets the `ios-standard-check` reminder if its CLAUDE.md doesn't mention the standard.
4. `/ios-project-standard check` runs in an app and reports a gap table.

## Inventory: what is installed now and why

Everything still configured on the current Mac after the 2026-10-20 clean-up, with its purpose. "Process" means the iOS process needs it; anything else is kept for its own reason and is not part of a fresh process setup.

**MCP servers** (`~/.claude.json`)

| Server | Scope | Purpose | Process? |
|---|---|---|---|
| `xcodebuildmcp` | user | Build, test, run and drive the simulator (§2.6, §12) | Yes |
| `figma` | user | Read and edit the Figma files (§2) | Yes |
| `context7` | user | Current library and tool documentation | Optional |
| `vectorcraft` | Artcraft project only | The Artcraft project's own vector tool | No (Artcraft) |

**claude.ai connectors** (shared with the claude.ai account)

| Connector | Purpose | Process? |
|---|---|---|
| Google Docs | Write the private-repo wikis (§11) | Yes |
| Google Drive | Find and place the wiki Docs (§11) | Yes |
| Google Sheets | WorkoutApp's routine data | No (project data) |
| Claude Docs | Shareable docs written from Claude | No (general use) |
| Gmail, Google Calendar | Personal mail and calendar, e.g. the morning brief | No (personal) |
| Spotify | Personal | No (personal) |
| Claude in Chrome (browser extension) | Viewing pages, including finished wiki pages | Optional |

**Plugins:** `swift-lsp` and `frontend-design`, both installed and disabled (§6).

**Agents** (`~/.claude/agents/`)

| Agent | Source | Purpose | Process? |
|---|---|---|---|
| `dead-code-finder` | repo `agents/global/` | Whole-codebase dead-code sweep in audits | Yes |
| `review-agent-evaluator` | repo `agents/global/` | Benchmarks every custom reviewer (§3.2) | Yes |
| `schema-migration-reviewer` | repo `agents/ios-baseline/` | SwiftData schema and migration safety (§4) | Yes |
| `design-sync-reviewer` | repo `agents/ios-baseline/` | Built SwiftUI against the Figma frame spec (§2.3) | Yes |
| `release-readiness-checker` | repo `agents/ios-baseline/` | The §9 release gate | Yes |
| `accessibility-reviewer` | repo `agents/ios-baseline/` | The accessibility pass before a full release (§9) | Yes |
| `senstream-ringkit2-*` (6) | Real files, not in the repo | SenstreamRingKit2's specialist reviewers (§3.4 examples) | No (that project) |

**Skills** (`~/.claude/skills/`): `ios-project-standard` and `ios-version` (repo links, process); `synced/` holds skills synced from the claude.ai account (not the process).

**Hooks** (`~/.claude/settings.json`)

| Hook | Event | Purpose | Process? |
|---|---|---|---|
| `ios-guard.sh` | PreToolUse | Asks before `git push` and `@Model` edits; denies `project.pbxproj` edits in XcodeGen projects (§13.1) | Yes |
| `ios-standard-check.sh` | SessionStart | Recommends the standard in an iOS project that doesn't mention it | Yes |
| `standard-unreviewed-scan.sh` | SessionStart | Lists agents and skills not yet in the standard or ledger | Yes |
| `next-session.sh` | SessionStart | Delivers a one-shot hand-off note to the next session | Yes |
| `standard-candidate.sh` | PostToolUse | Asks whether a newly written agent, skill or hook belongs in the standard | Yes |
| `preview-candidate.sh` | PostToolUse | Logs simulator runs a `#Preview` could have replaced (§13.6) | Yes |
| `swift-lint.sh` | PostToolUse | swift-format findings, in repos with `.swift-format` (§13.2) | Yes, opt-in |
| `build-gate.sh` | Stop | Blocks finishing on a failing build, in repos with `.claude/build-gate` (§13.3) | Yes, opt-in |
| vibesignal (7 entries: prompt, tool use, notifications, stop, session start and end) | several | Drives the vibesignal status light (`jfdonohoe/utility-vibesignal`) | No (personal) |
| approval log (`jq` into `~/.claude/approval-log.jsonl`) | PermissionRequest | Records every permission prompt under `~/Documents/Claude` | No (personal record) |

**Other settings:** `claude-quota-statusline.sh` as the status line (personal); `CLAUDE_CODE_DISABLE_MOUSE=1`; light theme; the `autoMode` environment notes written for SenstreamRingKit2. `~/.claude/settings.local.json` keeps one rule, `Bash(python3 *)`, which the benchmark harness relies on.

## Removed 2026-10-20

Backups of the three files changed are in `~/.claude/backups/cleanup-20261020/`.

| Item | Where it was | Why |
|---|---|---|
| `playwright` MCP | `~/.claude.json`, user scope | 0 calls in the transcript window; the standard doesn't refer to it |
| `chrome-devtools` MCP | `~/.claude.json`, user scope | 0 calls; not referred to |
| `figma-desktop` MCP (`http://127.0.0.1:3845/mcp`, the Figma desktop app's local server) | `~/.claude.json`, home-folder project | 0 calls; the remote `figma` server replaced it. The Figma app itself is untouched |
| `flaude` MCP | `~/.claude.json`, `~/flaude/flaude-mcp` project | Its path was the placeholder `/path/to/flaude-mcp/dist/index.js`, and the project folder no longer exists |
| `swift-lsp` plugin | `enabledPlugins` | Disabled, not uninstalled: enabled but never called |
| 18 allow rules in `~/.claude/settings.local.json` | `~/.claude` | One-off commands and lovable-to-figma and Python-project leftovers |
| Apple's Xcode MCP (`xcrun mcpbridge`) | Removed earlier on 2026-10-20 | Re-asked for access every session and was never called (§6) |
