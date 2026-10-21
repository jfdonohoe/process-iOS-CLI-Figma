# Agent context: <App>

Copy to `<repo>/.claude/agent-context.md`, and make sure git tracks it (a `.gitignore` that
excludes `.claude/*` needs `!.claude/agent-context.md`). The user-level iOS agents read it at
run time (`agents/ios/README.md`). Keep it to facts agents need that the README doesn't already
state, and keep project *state* (bug statuses, test counts, versions) out of it: those
belong in `_reports/regression-registry.md`, `BUGS.md` and `CHANGELOG.md`.

## Preserve list

Behaviour that must survive any cleanup, beyond the README's features and product rules.

- …

## Domain terms

Words that mean something specific in this codebase.

- …

## Known pitfalls

Shapes of bugs this project has had, for `swift-reviewer` to check every change for.

- …

## Extra stop conditions

Changes the refactorer must stop and ask about, beyond its own list.

- …

## Claude Code memory

The project's standing design and implementation rules, if kept in Claude Code memory:
`~/.claude/projects/<project path, with / replaced by ->/memory/MEMORY.md`.
