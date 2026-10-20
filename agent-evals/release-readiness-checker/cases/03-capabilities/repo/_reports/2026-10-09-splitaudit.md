# Split audit (2026-10-09)

`splitaudit 3`: three rounds, four areas each, plus a boundary run per round.

## Verified priority list

| ID | P | Finding | Where | Rounds |
|---|---|---|---|---|
| O-001 | P2 | Session list re-sorts on every heart-rate sample | `Views/SessionListView.swift` | 2/3 |
| O-002 | P1 | Average BPM includes samples from before the session | `Services/HeartRateReader.swift` | 3/3 |
