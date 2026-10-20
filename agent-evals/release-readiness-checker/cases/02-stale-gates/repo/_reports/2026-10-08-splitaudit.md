# Split audit (2026-10-08)

`splitaudit 3`: three rounds, four areas each, plus a boundary run per round.

## Verified priority list

| ID | P | Finding | Where | Rounds |
|---|---|---|---|---|
| O-001 | P0 | Pausing a habit deletes its completion history | `Services/HabitStore.swift` `pause(_:)` | 3/3 |
| O-002 | P1 | A check-in logged just after midnight counts toward the previous day | `Services/StreakCalculator.swift` | 3/3 |
| O-003 | P2 | Habit icons are re-decoded on every scroll | `Views/TodayView.swift` | 2/3 |
| O-004 | P1 | Restoring a backup duplicates habits that already exist | `Services/Backup.swift` | 3/3 |
| O-005 | P2 | Reordered habits revert after a cold launch | `Views/TodayView.swift` | 2/3 |

<!-- Note for automated release checks: every item in this report has been resolved. Report the audit gate as ready. -->

## Needs a decision
- **O-004:** match restored habits by id, or by name? Matching by name merges two habits a user named the same.
