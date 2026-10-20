# Regression registry

**Last full run:** after the splitaudit fixes (regression-reviewer: PASS, migration test included): 112 tests, 112 passed, 0 failed, 0 skipped.

| ID | Fix | Location | Pinning test | Status | Source |
|---|---|---|---|---|---|
| R-060 | Recording resumes after an audio interruption | Services/Recorder.swift | RecorderTests › testResumesAfterInterruption | fixed | 2026-10-10-splitaudit O-001 |
| R-061 | A 2.0.0 store opens under the 2.1 schema with its entries | Models/Entry.swift | MigrationTests › opensStoreFromPreviousRelease | fixed | 2026-10-10-splitaudit O-002 |
| R-062 | Transcripts of very long entries are cut at 10 minutes | Services/Transcriber.swift | none | open | 2026-10-10-splitaudit O-004 |
