# Split audit (2026-10-11)

`splitaudit 3`: three rounds, four areas each, plus a boundary run per round.

## Verified priority list

| ID | P | Finding | Where | Rounds |
|---|---|---|---|---|
| O-001 | P1 | Deleting from a filtered list deletes by index in the unfiltered list | `Views/HikeListView.swift` `delete(at:)` | 3/3 |
| O-002 | P2 | The elevation chart recomputes its samples on every body pass | `Views/TrailDetailView.swift` | 2/3 |
| O-003 | P3 | "Hikes" title isn't localized | `Views/HikeListView.swift` | 1/3 |
