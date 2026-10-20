# Regression registry

**Last full run:** after the O-001 fix (regression-reviewer: PASS): 58 tests, 58 passed, 0 failed, 0 skipped.

| ID | Fix | Location | Pinning test | Status | Source |
|---|---|---|---|---|---|
| R-013 | A streak counts today only once, however many check-ins | Services/StreakCalculator.swift | StreakTests › testTodayCountsOnce | fixed | 2026-09-20-streak-review |
| R-014 | Pausing a habit keeps its completions | Services/HabitStore.swift `pause(_:)` | HabitStoreTests › pauseKeepsCompletions | fixed | 2026-10-08-splitaudit O-001 |
| R-015 | Reordered habits revert after a cold launch | Views/TodayView.swift | none | open | 2026-10-08-splitaudit O-005 |
