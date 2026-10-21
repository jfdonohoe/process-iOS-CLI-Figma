# iOS agents

The agents every iOS app project gets (standard §3). `install.sh` links each one into
`~/.claude/agents/ios/`, so they are available in every project without copying. Their
descriptions limit them to iOS app projects.

| Agent | Role | When it runs | Writes? |
|---|---|---|---|
| `swift-reviewer` | A change, for correctness, the standard SwiftUI pitfalls and the project's rules | Proactively after `.swift` edits | No |
| `regression-reviewer` | Build, full suite, regression registry, product rules, launch-path wiring | Proactively after revisions, before calling work done | No |
| `ios-codebase-auditor` | Whole-app architecture, data integrity, performance, duplication, test gaps | Audits and `splitaudit` area runs | No (plan mode) |
| `ios-codebase-refactorer` | Applies approved audit findings conservatively | Only after the developer approves specific findings | Yes (never git) |
| `schema-migration-reviewer` | A change's effect on data already on disk | Proactively after `Models/` or `Persistence/` edits | No |
| `design-sync-reviewer` | Built screens against their Figma frame spec | After building an Approved section, before syncing Production | No |
| `release-readiness-checker` | The §9 release checklist | Before a release push | No |
| `accessibility-reviewer` | VoiceOver, Dynamic Type, contrast, targets, motion | Before a full (X.0.0) release | No |

## What a project provides

The agents carry method only. Project facts come from the project at run time:

- `README.md`: the product rules (a "Product rules", "Design principles" or "Protecting
  trust in the data" section), the features, and the build and test commands.
- `.claude/agent-context.md` (optional; template in `standard/agent-context.template.md`):
  the preserve list, domain terms, known pitfalls, extra stop conditions, and where the
  project's Claude Code memory lives.
- `_reports/regression-registry.md`: the fixed bugs, each with its fixed shape and
  pinning test (standard §3.2).
- `CLAUDE.md` and, once the app is big enough, `FEATURES.md` and `BUGS.md`.

A file the project doesn't have is never a finding.

## Replacing one for a project

A project agent with the same `name` in the project's `.claude/agents/` (or in a folder
linked there) replaces the user-level one inside that project. Use this deliberately, for
a project family whose rules differ (for example a family that forbids removing code,
where the generic refactorer removes dead code). Don't keep stale copies: a copy left in
a project silently shadows every later improvement here.

## Shared finding scheme

Every reviewer rates findings the same way, so reports in `_reports/` can be compared:

- **Severity:** P0 stability or data integrity · P1 wrong behaviour or material
  performance · P2 limited impact · P3 cosmetic. Never High/Medium/Low.
- **Verdict:** `CONFIRMED` (checked in the code) or `PLAUSIBLE` (not provable
  statically, with how to check it).

The global `dead-code-finder` emits `CONFIRMED`/`PLAUSIBLE` but no severity. When merging
its findings into a report, keep its verdict and rate them P2 by default (P3 for unused
imports and the like).

## Regression checks

`regression-reviewer` is the regression test after any revision to the app. It changes
nothing, the registry included. When a fix lands, the main session adds a row to the
registry: the fix, its fixed shape, its location, and the pinning test. When a pinning
test is renamed, the main session updates the row.

## Changing an agent

Snapshot it in `agent-evals/<agent>/snapshots/` first, then run the evaluator against
its benchmark (standard §3.2, §14.1).
