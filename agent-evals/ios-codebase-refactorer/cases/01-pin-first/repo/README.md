# Lifts

A local-first workout log. The logic lives in a Swift package so the product rules
can be tested without the UI.

## Design principles

- One source of truth: the store. Views derive what they show from it.
- Keep it boring: straightforward Swift and Foundation over clever abstractions.
- Small files, one responsibility each.

## Protecting trust in the data

| Rule | What the code does |
|---|---|
| History reflects what was planned then | A session keeps its own snapshot of the routine taken when it started |
| Routine edits affect the future only | Editing a routine adds a new version; old versions are never changed |
| Finished workouts don't change | `finish` locks a session; nothing can be logged into a locked session |
| Corrections preserve what happened | A correction is appended; the logged value is never overwritten |
| Weights are shown the same everywhere | Kilograms, one decimal, `kg` suffix |

## Features

- **Session summary.** One line per logged set, shown when a workout is finished.
- **History export.** All finished sessions as CSV.
- **Status.** A session is scheduled, started, completed, partial, missed or abandoned,
  worked out from its dates and its sets.

## Build and test

```bash
swift build --scratch-path "$TMPDIR/lifts-build"
swift test --scratch-path "$TMPDIR/lifts-build"
```

Build output goes outside the repo. Tests live in `Tests/LiftsTests/`.
