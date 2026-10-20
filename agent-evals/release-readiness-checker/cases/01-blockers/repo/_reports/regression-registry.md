# Regression registry

Every fixed bug, the shape its fix must keep, and the test that pins it.

**Last full run:** after the O-001 fix (regression-reviewer: PASS): 41 tests, 41 passed, 0 failed, 0 skipped.

| ID | Fix | Location | Pinning test | Status | Source |
|---|---|---|---|---|---|
| R-030 | GPX import skips files that aren't GPX | Services/GPXLibrary.swift | GPXTests › testIgnoresNonGPX | fixed | 2026-09-02-gpx-review |
| R-031 | Deleting a hike from search results deletes that hike, not the row at the same index in the full list | Views/HikeListView.swift `delete(at:)` | HikeTests › deleteFromFilteredListDeletesThatHike | fixed | 2026-10-11-splitaudit O-001 |
