# process-ios-cli-figma

A working process for designing and building iOS apps with Claude Code from the terminal, with Figma as the design source: Figma-driven design (WIP → Approved → build → Production → Archive), Xcode builds and tests through XcodeBuildMCP and `xcodebuild`, simulator demo state for accurate screenshots, specialist reviewer agents with measured benchmarks, hooks that enforce the rules that must always hold, and the practices that keep token cost down.

It was built and proven on three projects, which the standard cites as case studies: **Sets** (a workout tracker), **Breathe** (a meditation app) and **RingKit** (a Bluetooth wearable SDK with signal processing and on-device ML). Tags in the standard say where each practice came from: [Sets], [Breathe], [RingKit], [general], [suggested].

## Wiki

The [project wiki](../../wiki) is a readable synthesis of this repository. Every change merged to `main` updates the pages it touches, re-derived from these files, and restamps the commit on the Home page (standard §11).

## Layout

| Path | What it is |
|---|---|
| `standard/ios-project-standard.md` | The standard. Single source of truth. §2 Figma loop, §3 agents, §4 SwiftData, §6 testing, §8–9 device and release checklists, §10 versioning, §11 project wiki, §12 token cost, §13 guardrails, §14 evaluating the process |
| `standard/ios-splash-standard.md` | Splash and launch-screen rules and the verification procedure |
| `standard/splitaudit.md` | The deep multi-area audit procedure (keyword `splitaudit`) |
| `standard/ios-setup.template.md` | The per-developer values (bundle prefix, projects folder, apps, wiki locations); `install.sh` copies it to `~/.claude/ios-setup.local.md` |
| `standard/ios-project-standard.ledger` | Every candidate practice the developer was asked about, with the answer |
| `SETUP.md` | What a fresh Mac needs for the process, and how to audit an existing setup |
| `CHANGELOG.md` | What each merge to `main` changed, dated and naming its commits; the wiki's Changelog page is derived from it (§11.2) |
| `claude/CLAUDE.md` | An example global CLAUDE.md, the reference developer's own rules (kept short; procedures live in the files above) |
| `skills/ios-project-standard/` | `/ios-project-standard [check\|figma\|agents\|device\|release\|cost]`: gap check, reads only the sections it needs |
| `skills/ios-version/` | `/ios-version`: suggests the next SemVer number before a release |
| `hooks/` | SessionStart, PreToolUse, PostToolUse and Stop hooks that keep the standard in view and enforce its gates (§13); `settings-hooks.json` is the settings fragment |
| `tools/` | Simulator driver, SF Symbol vector pipeline, the Figma frame-spec export for `design-sync-reviewer`, the contrast-ratio helper for `accessibility-reviewer`, the preview-tracker report and the tool-usage audit (see `tools/README.md`) |
| `agents/global/` | Cross-project agents: `dead-code-finder`, `review-agent-evaluator` |
| `agents/ios-baseline/` | The §3.1 baseline reviewer set to copy into a new app's `.claude/agents/`, plus the built §3.3 additions (`schema-migration-reviewer`, `design-sync-reviewer`, `release-readiness-checker`, `accessibility-reviewer`) |
| `agent-evals/` | Seeded-defect benchmarks for the agents (run outputs are not committed) |
| `tests/hooks-test.sh` | Fixed-input tests for every hook (standard §14.1) |

## Install

Start with [`SETUP.md`](SETUP.md): the accounts, apps, command-line tools, MCP servers, connectors and settings the process needs. Then:

```bash
git clone https://github.com/<owner>/process-ios-cli-figma.git
cd process-ios-cli-figma && ./install.sh
```

`install.sh` checks the prerequisites, symlinks everything into `~/.claude` (backing up real files it replaces), builds the Swift tools and creates `~/.claude/ios-setup.local.md` for your own values. Then merge `hooks/settings-hooks.json` into `~/.claude/settings.json` and run `tests/hooks-test.sh`. Because `~/.claude` points into your clone, edits made there show up in `git status`.

Note that it links `claude/CLAUDE.md` over your global `~/.claude/CLAUDE.md` (the old one is backed up). Read it first and make it yours, or remove that line from `install.sh`.

## Working cheaply (standard §12)

1. One session per piece of work; `/clear` once the memory note is written.
2. Figma screens from Components only; check by measurement, screenshot sparingly at half scale.
3. Quiet builds: fix warnings when they appear; run tests into a result bundle and read only the summary.
4. Reuse `tools/` instead of rewriting helpers.
5. Read only the standard sections a task needs; keep always-loaded CLAUDE.md files to rules and pointers.
6. Sonnet or lower effort for mechanical work; Opus for design, diagnosis and data-safety calls.
7. A Figma approval is not a build order (§2.3).
8. `splitaudit`: one round by default.

## Guardrails and evaluation

Standard §13 turns the must-always rules into hooks (`ios-guard.sh` always on; `swift-lint.sh` and `build-gate.sh` opt in per project) and adds spec-before-code and modern-Swift preferences. §14 is how the process itself is measured: hook tests, a per-task log, a benchmark task and a monthly review.
