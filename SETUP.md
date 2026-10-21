# Fresh setup

Everything the process in `standard/ios-project-standard.md` runs on, in install order, so a new Mac can be set up from this file. Each item is marked **Required** (the process breaks or a gate goes silent without it), **Situational** (needed only for the step named) or **Optional**.

The usage figures are from the reference setup: the Claude Code session transcripts of one developer running the process on three apps for a month (2026-09-16 to 2026-10-20). "Calls" are tool calls; "sessions" are distinct transcripts. Measure your own with `tools/tool-usage-report.py` (see Audit your own machine).

## 1. Accounts

| Account | Needed for | Status |
|---|---|---|
| Anthropic (Claude subscription or API) | Claude Code itself; the reference setup uses Opus as the default model | Required |
| GitHub | This repository and every app repository; GitHub wikis for public repositories (§11.1) | Required |
| Figma, with edit access to each app's file | Figma-driven development (§2) | Required |
| Google (Drive and Docs) | Wikis for apps whose repository is private (§11.1) | Situational |
| Apple Developer Program | Signing, device installs (§8), TestFlight and the App Store (§9) | Required for device and release; the simulator works without it |

## 2. Mac applications

| App | Needed for | Status |
|---|---|---|
| Xcode 26 | `xcodebuild`, Simulator, `xcrun simctl`, `xcrun devicectl` (device installs and the §8 bundle check), `xcrun xcresulttool` (test summaries, §12), `xcrun swift-format` (the lint hook, §13.2), `swiftc` (building `tools/`) | Required. Open it once to accept the licence and install an iOS simulator runtime |
| SF Symbols | The SF Symbol vector pipeline in `tools/` reads its `SFSymbolsFallback.otf` (§2.4) | Situational: icons in Figma |
| Figma desktop | Editing files by hand. Claude uses the remote Figma MCP server, not the desktop app | Optional for Claude |

## 3. Command-line tools

| Tool | Needed for | Status |
|---|---|---|
| Claude Code CLI | Everything | Required |
| `git` (comes with Xcode) | Every repository | Required |
| `gh`, signed in with `gh auth login` | Repository, PR and wiki work (215 calls in 27 sessions) | Required |
| `jq` 1.6 or later | Every hook in `hooks/` parses its input with `jq`; without it the guard, lint, build gate and preview tracker do nothing | Required |
| Node.js with `npx` | Starts the XcodeBuildMCP server (and the optional `npx` servers below) | Required |
| `python3` | `agent-evals/bin/` (the benchmark harness, run before any reviewer agent is trusted, §3.2), `tools/sim-drive.py`, `tools/sf-symbolset-extract.py`, `tools/tool-usage-report.py` | Required for agent benchmarks |
| XcodeGen | Apps generated from a `project.yml` (every app on the reference setup); `ios-guard.sh` blocks hand edits to `project.pbxproj` in those projects (§13.1) | Required if your apps use XcodeGen |

Install the non-Apple ones with Homebrew: `brew install gh jq node python xcodegen`.

## 4. MCP servers (user scope, in `~/.claude.json`)

| Server | Needed for | Reference use | Status |
|---|---|---|---|
| `xcodebuildmcp`, with the `simulator` and `ui-automation` workflows | Builds, tests and simulator UI automation (§2.6, §12) | 261 calls, 14 sessions | Required |
| `figma` (remote, `https://mcp.figma.com/mcp`) | The whole Figma loop and `tools/figma-frame-spec.js` (§2, §3.3) | 767 calls, 11 sessions | Required |
| `context7` | Current library and tool documentation | 3 calls, 1 session | Optional |

```bash
claude mcp add -s user xcodebuildmcp -e XCODEBUILDMCP_ENABLED_WORKFLOWS=simulator,ui-automation -- npx -y xcodebuildmcp@latest mcp
claude mcp add -s user --transport http figma https://mcp.figma.com/mcp   # then sign in through /mcp
claude mcp add -s user context7 -- npx -y @upstash/context7-mcp           # optional
```

The Figma skills (`figma-use`, `figma-generate-design` and the rest) come from the Figma MCP server's resources, so no Figma plugin is needed. Load `figma-use` before any `use_figma` call.

## 5. claude.ai connectors

Turned on at claude.ai → Settings → Connectors; Claude Code picks them up when signed in to the same account.

| Connector | Needed for | Reference use | Status |
|---|---|---|---|
| Google Docs | Writing private-repository wikis (§11.2) | 51 calls, 9 sessions | Situational: private repositories |
| Google Drive | Finding and placing those wiki Docs | 36 calls, 13 sessions | Situational: private repositories |
| Claude in Chrome (browser extension) | Viewing a finished wiki page in the browser | 88 calls, 3 sessions | Optional |

## 6. Plugins

None are needed.

## 7. This repository

```bash
git clone https://github.com/<owner>/process-ios-cli-figma.git
cd process-ios-cli-figma && ./install.sh
```

Clone it anywhere. `install.sh` first checks the prerequisites in §2–3 and warns about any that are missing. It then links into `~/.claude`: the standard, splash standard, ledger and `splitaudit.md`; `CLAUDE.md`; the two skills (`/ios-project-standard`, `/ios-version`); `hooks/`; `tools/`; `agent-evals/`; the global agents (`dead-code-finder`, `review-agent-evaluator`) into `~/.claude/agents/`; and every iOS agent in `agents/ios/` into `~/.claude/agents/ios/`, removing any older flat links to them. It builds `tools/sf-symbol-match` and `tools/sf-symbol-export`, and creates `~/.claude/ios-setup.local.md` from `standard/ios-setup.template.md` if you don't have one.

**`claude/CLAUDE.md` replaces your global `~/.claude/CLAUDE.md`** (the old one is backed up to `~/.claude/.pre-repo-backup/`). It is written in the first person, as the reference developer's own rules; edit it into yours, or skip that link and copy the iOS lines you want into your own file.

Nothing is copied into apps: each app gives the agents its facts through its README and an optional `.claude/agent-context.md` (template in `standard/agent-context.template.md`; §3.1). If an app still has its own copies of these agents in `.claude/agents/`, delete them, or they silently replace the shared ones. The installer does not touch settings or MCP servers.

## 8. Your setup

Fill in `~/.claude/ios-setup.local.md`: your bundle ID prefix, projects folder, apps, GitHub owner and private-wiki location (standard, "Your setup"). It stays outside the repository, as does `~/.claude/ios-project-standard.local.ledger` for answers you'd rather not publish.

## 9. Settings (`~/.claude/settings.json`)

1. **Hooks.** Merge `hooks/settings-hooks.json` into `"hooks"`, then run `tests/hooks-test.sh`; all 18 checks must pass.

   | Hook | Event | State |
   |---|---|---|
   | `ios-guard.sh` | PreToolUse | Always on |
   | `ios-standard-check.sh`, `standard-unreviewed-scan.sh`, `next-session.sh` | SessionStart | Always on |
   | `standard-candidate.sh`, `preview-candidate.sh` | PostToolUse | Always on |
   | `swift-lint.sh` | PostToolUse | Opt-in per repository (`.swift-format`) |
   | `build-gate.sh` | Stop | Opt-in per repository (`.claude/build-gate`) |

2. **Permissions.** Allow `Bash(xcodebuild *)`, `Bash(xcrun simctl *)`, `Bash(xcrun devicectl *)` and `mcp__xcodebuildmcp`, so builds and simulator work don't prompt. Allow `Bash(python3 *)` too if you run the agent benchmarks.
3. **Model.** The reference setup uses `"model": "opus"`; mechanical work drops to Sonnet or lower effort (§12).

## 10. macOS permissions

- **Accessibility** for the terminal app (System Settings → Privacy & Security → Accessibility), only if `tools/sim-drive.py` is needed: it drives the Simulator through System Events. Situational, since XcodeBuildMCP's `ui-automation` workflow comes first (§2.6).
- **Developer Mode** on each test iPhone, and the phone paired with Xcode, before the first device install (§8).

## 11. Check it worked

1. `claude mcp list` shows `xcodebuildmcp` and `figma` connected.
2. `tests/hooks-test.sh` passes.
3. A session started in an app folder gets the `ios-standard-check` reminder if its CLAUDE.md doesn't mention the standard.
4. `/ios-project-standard check` runs in an app and reports a gap table.

## Audit your own machine

An existing Claude Code setup usually carries servers and plugins from other work. To decide what to keep:

1. Run `tools/tool-usage-report.py`. It counts the tool calls in your session transcripts (about the last 30 days) per MCP server, skill, plugin and process tool.
2. Compare it with `claude mcp list`, `enabledPlugins` in `~/.claude/settings.json` and the hooks there. Anything configured that never shows up in the report wasn't used in that window.
3. For each item, record its purpose and whether the process needs it in the inventory section of `~/.claude/ios-setup.local.md`: required by this file, kept for another project or personal use, or removable.
4. Back up `~/.claude.json`, `~/.claude/settings.json` and `~/.claude/settings.local.json`, then remove what isn't needed (`claude mcp remove -s user <name>`; `false` in `enabledPlugins`).

What the reference setup found unused and removed:

| Item | Why it wasn't needed |
|---|---|
| `playwright` and `chrome-devtools` MCP servers | No calls in a month; the process does no browser testing |
| `figma-desktop` MCP (`http://127.0.0.1:3845/mcp`, the Figma desktop app's local server) | No calls; the remote `figma` server does everything the process needs |
| An MCP entry whose command was still a placeholder path | It could never start |
| `swift-lsp` plugin | Enabled, never called |
| Apple's Xcode MCP (`xcrun mcpbridge`) | Asked for access again every session and was never called (§6) |
| Old one-off allow rules in `settings.local.json` | Left over from earlier projects |
