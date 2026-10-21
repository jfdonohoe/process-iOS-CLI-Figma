---
name: ios-project-standard
description: An iOS project best-practices standard (Figma-driven development, the baseline and project-specific reviewer agents, SwiftData persistence, testing, and device/release checklists). Use when starting a new iOS app project, when a project turns into an iOS app (an Xcode project or iOS target appears, or the developer says it's becoming an app), when a new subsystem appears that may need a specialist reviewer agent (BLE, HealthKit, StoreKit, sync, ML, widgets), before a first device install or a release, or when the developer asks how a project measures up against the iOS standard. Args: `check` (default, the Day one gap check), `figma`, `agents`, `device`, `release`.
---

# iOS project standard

The standard is in **`~/.claude/ios-project-standard.md`**. That file is the single source of truth: read the sections the argument needs (table below) plus `## How Claude uses this`, not the whole file. Don't work from memory of it, and don't copy its contents into this skill. Find section line ranges with `grep -n '^## \|^### '` and read just those ranges.

## Procedure

1. **Read** only the sections the argument picks (step 3), by line range. Read the whole file only for `check` on a brand-new project.
2. **Inspect the current project** read-only: git state, `.gitignore`, Xcode project or `project.yml`, the folder layout, `CLAUDE.md`, `.claude/agents/`, `_reports/`, `design/`, the schema/persistence files, the test target and the Figma file key.
3. **Check it against the section the argument picks:**

   | Arg | Sections |
   |---|---|
   | `check` (default) | §1, §2.1, §3.1–3.2 (the Day one items) |
   | `figma` | §2 |
   | `cost` | §12 |
   | `guardrails` | §13 (hooks, spec-before-code, modern Swift) |
   | `evaluate` | §14 (how to measure the process) |
   | `agents` | §3, including a §3.4 scan for subsystems that would justify a project-specific agent |
   | `device` | §8 and the sections it references |
   | `release` | §9 and the sections it references |

4. **Report a gap table** in the terminal with these columns: item · status (✅ in place / ⚠️ partial / ❌ missing / n/a) · evidence (file:line, or what you looked at) · proposed action. Cite evidence for every ✅ and ⚠️. Mark anything you couldn't verify as unverified.
5. **Ask which gaps to set up.** Don't create files, agents, Figma pages or commits until the developer picks them. This is a recommendation, not an installer.
6. When setting up agents, don't copy them: the iOS agents are user-level (`~/.claude/agents/ios/`). Give the app what they read instead: product rules and build commands in the README, and `.claude/agent-context.md` from `standard/agent-context.template.md` (preserve list, domain terms, pitfalls, stop conditions). Flag any old agent copies in the app's `.claude/agents/`, since they shadow the shared ones. Propose a project-specific agent only for a subsystem with its own failure modes (§3.4); offer a benchmark with `review-agent-evaluator` for any new one.

## Keeping it current

When the developer sets a new iOS-wide practice, or a lesson from any app should apply to all of them, propose an edit to `~/.claude/ios-project-standard.md`, tagged [Sets], [Breathe], [RingKit], [general] or [suggested]. Don't edit this skill.
