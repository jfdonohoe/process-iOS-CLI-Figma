# Project subagents

Project-scoped Claude Code subagents for **<App>** live in this folder
(`.claude/agents/`). They are available whenever Claude Code / Cowork runs inside
this project, and (when a name collides) take precedence over user-level agents in
`~/.claude/agents/`.

## File format

Each subagent is a Markdown file with YAML frontmatter:

```markdown
---
name: my-agent              # unique, lowercase-with-hyphens
description: When this subagent should be invoked (be specific — this is how it
             gets auto-selected). Add "use PROACTIVELY" to encourage delegation.
tools: Read, Grep, Glob     # optional; omit to inherit all available tools
model: sonnet               # optional: sonnet | opus | haiku | inherit
---

The subagent's system prompt — its role, instructions, and constraints.
```

- `name` and `description` are required; `tools` and `model` are optional.
- Omitting `tools` inherits every tool the main session has.
- Each subagent runs in its own context window — good for focused, read-heavy,
  or verification tasks you don't want cluttering the main thread.

## Shared finding scheme

Every reviewer agent here rates findings the same way, so reports in `_reports/`
can be compared:

- **Severity:** P0 stability or data integrity · P1 wrong behaviour or material
  performance · P2 limited impact · P3 cosmetic. Never High/Medium/Low.
- **Verdict:** `CONFIRMED` (checked in the code) or `PLAUSIBLE` (not provable
  statically, with how to check it).

The global `dead-code-finder` already emits `CONFIRMED`/`PLAUSIBLE` but no
severity. When merging its findings into a report, keep its verdict as-is and rate
them P2 by default (P3 for unused imports and the like).

## Regression checks

`regression-reviewer` is the regression test after any revision to the app. Run it
after the last batch of fixes, before calling the work done. It runs:
- the build and the full test suite
- `_reports/regression-registry.md`: every fixed bug is still fixed and pinned by
  a test that actually runs
- the README's product rules
- launch-path wiring

It changes nothing, the registry included. When a fix lands, the main session adds
a row to the registry: the fix, its fixed shape, its location, and the pinning
test. When a pinning test is renamed, the main session updates the row.

## Adding one

Drop a new `*.md` file in this folder (or run `/agents` in Claude Code to create
one interactively), then commit it so the team shares it.

See `swift-reviewer.md` for a working example.
