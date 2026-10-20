# Lifts

A local-first workout log. The logic lives in a Swift package so the product rules can be tested without the UI.

## Product rules

| Rule | What the code does |
|---|---|
| History reflects what was planned then | A session keeps its own snapshot of the routine taken when it started |
| Routine edits affect the future only | Editing a routine adds a new version; old versions are never changed |
| Finished workouts don't change | `finish` locks a session; nothing can be logged into a locked session |
| Corrections preserve what happened | A correction is appended; the logged value is never overwritten |
| Demo content never touches real history | Deleting demo data removes only demo routines and sessions |
| A workout is done if anything was logged | Reps, weight or distance each count |

## Features

- **Stats.** The Stats screen's completed-workout total updates as soon as a workout is finished. `StatsService` listens for locked sessions; `AppEnvironment.make()` wires it up at launch.
- **Plan import.** Paste `name,sets,reps` lines to build a routine.

## Build and test

```bash
swift build --scratch-path "$TMPDIR/lifts-build"
swift test --scratch-path "$TMPDIR/lifts-build"
```

Build output goes outside the repo. Fixed bugs and the tests that pin them are tracked in `_reports/regression-registry.md`.
