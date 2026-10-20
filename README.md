# iOS best practices: Claude Code CLI with Figma, Xcode and agents

John's working standard for designing and building iOS apps with Claude Code from the terminal: Figma-driven design (WIP → Approved → build → Production → Archive), Xcode builds and tests through XcodeBuildMCP and `xcodebuild`, simulator demo state for accurate screenshots, specialist reviewer agents with measured benchmarks, and the practices that keep token cost down.

Proven on two apps: **Sets** (WorkoutApp) and **Breathe** (Senstream Meditation). Tags in the standard say where each practice came from: [Sets], [Breathe], [Senstream], [general], [suggested].

## Layout

| Path | What it is |
|---|---|
| `standard/ios-project-standard.md` | The standard. Single source of truth. §2 Figma loop, §3 agents, §4 SwiftData, §6 testing, §8–9 device and release checklists, §10 versioning, §11 project wiki, §12 token cost |
| `standard/ios-splash-standard.md` | Splash and launch-screen rules and the verification procedure |
| `standard/splitaudit.md` | The deep multi-area audit procedure (keyword `splitaudit`) |
| `standard/ios-project-standard.ledger` | Every candidate practice John was asked about, with his answer |
| `claude/CLAUDE.md` | Global rules loaded in every session (kept short; procedures live in the files above) |
| `skills/ios-project-standard/` | `/ios-project-standard [check\|figma\|agents\|device\|release\|cost]`: gap check, reads only the sections it needs |
| `skills/ios-version/` | `/ios-version`: suggests the next SemVer number before a release |
| `hooks/` | SessionStart and PostToolUse hooks that keep the standard in view; `settings-hooks.json` is the settings fragment |
| `tools/` | Simulator driver and SF Symbol vector pipeline (see `tools/README.md`) |
| `agents/global/` | Cross-project agents: `dead-code-finder`, `review-agent-evaluator` |
| `agents/ios-baseline/` | The §3.1 baseline reviewer set to copy into a new app's `.claude/agents/` |
| `agent-evals/` | Seeded-defect benchmarks for the agents (run outputs are not committed) |

## Install

```bash
./install.sh
```

It symlinks everything into `~/.claude` (backing up real files it replaces) and builds the Swift tools. Then merge `hooks/settings-hooks.json` into `~/.claude/settings.json`.

## Working cheaply (standard §12)

1. One session per piece of work; `/clear` once the memory note is written.
2. Figma screens from Components only; check by measurement, screenshot sparingly at half scale.
3. Quiet builds: fix warnings when they appear; run tests into a result bundle and read only the summary.
4. Reuse `tools/` instead of rewriting helpers.
5. Read only the standard sections a task needs; keep always-loaded CLAUDE.md files to rules and pointers.
6. Sonnet or lower effort for mechanical work; Opus for design, diagnosis and data-safety calls.
7. A Figma approval is not a build order (§2.3).
8. `splitaudit`: one round by default.
