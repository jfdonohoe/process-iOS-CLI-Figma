# Split audit (2026-10-10)

`splitaudit 3`: three rounds, four areas each, plus a boundary run per round.

## Verified priority list

| ID | P | Finding | Where | Rounds |
|---|---|---|---|---|
| O-001 | P1 | A notification arriving mid-recording stops the recording | `Services/Recorder.swift` | 3/3 |
| O-002 | P1 | No test opens a 2.0.0 store under the new schema | `Models/Entry.swift` | 3/3 |
| O-003 | P2 | Today list fetches transcripts it doesn't show | `Views/TodayView.swift` | 2/3 |
| O-004 | P2 | Transcripts of entries over 10 minutes are cut off | `Services/Transcriber.swift` | 2/3 |
