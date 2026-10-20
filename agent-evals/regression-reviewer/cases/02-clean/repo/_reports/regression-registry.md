# Regression registry

Every fixed bug, the shape the fix must keep, and the test that pins it. Update this file whenever a fix lands or a pinning test is renamed.

**Last full run:** 16 tests: 15 passed, 1 skipped (R-007). 0 failures.

| ID | Fix | Fixed shape | Location | Pinning test | Status |
|---|---|---|---|---|---|
| R-001 | A session keeps its own plan when the routine is edited later | `start` copies `routine.exercises` into `snapshot` | `Sources/Lifts/SessionStore.swift` `start` | `HistoryTests › testSessionKeepsSnapshotWhenRoutineEdited` | fixed |
| R-002 | A distance-only workout finishes as completed | `isDone` counts `distanceKm` | `Sources/Lifts/SessionStore.swift` `isDone` | `HistoryTests › testDistanceOnlyFinishesCompleted` | fixed |
| R-003 | Editing a routine adds a version instead of changing it | `editRoutine` appends a new `Routine` with `version + 1` | `Sources/Lifts/SessionStore.swift` `editRoutine` | `HistoryTests › testEditCreatesNewVersion` | fixed |
| R-004 | Deleting demo data keeps the user's workouts | `deleteDemoData` removes only `isDemo` items | `Sources/Lifts/SessionStore.swift` `deleteDemoData` | `DemoTests › testDeleteDemoKeepsUserSessions` | fixed |
| R-005 | Nothing can be logged into a finished workout | `log` throws `.locked` when `lockedAt` is set | `Sources/Lifts/SessionStore.swift` `log` | `HistoryTests › testLockedSessionRejectsNewSets` | fixed |
| R-006 | Soft-deleted routines still count as the user's own data, so demo data is never cleared for a user who deleted their only routine | — | `Sources/Lifts/SessionStore.swift` `hasUserData` | — | open |
| R-007 | A pasted plan that starts with a byte-order mark keeps the mark in the first exercise name | — | `Sources/Lifts/PlanImport.swift` | `ImportTests › testImportWithByteOrderMark` (skipped on purpose) | accepted |
