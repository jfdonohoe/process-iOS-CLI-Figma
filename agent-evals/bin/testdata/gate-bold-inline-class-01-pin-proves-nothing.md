# Remediation gate: WidgetKit batch 1 (v4.1.1..51f0386)

**Verdict: REQUEST CHANGES.** All four code fixes are correct and nothing outside the plan changed. But only the F-2 pin actually proves its fix. The F-1 pin passes on the old code, and the F-4 pin skips itself on every run. Also, F-1 changes a metric and there's no signal-analysis review of this diff.

```
Branch: main   HEAD: 51f0386   Tree: clean
Project: WidgetKit (this checkout holds only the Core and UI targets, per README)
build: pass   test: 4 tests, 0 failures, 1 skipped
  (swift test --scratch-path "$d/.build", run in a copy of HEAD with no .git; the tree is clean, so the copy matches the repo)
Canonical docs read: README.md, CHANGELOG.md, DEVICE_CHECKLIST.md, Acme/CLAUDE.md, Acme/DATA_SAFETY.md
  (no .claude/agent-context.md, BUGS.md, BEST_PRACTICES.md or FEATURES.md; the README doesn't claim them, so their absence isn't a finding)
Prior reports read: none (_reports/ doesn't exist)
```

The diff is 8 files, +65/−2. I read every touched file in full, before and after.

## Gate 1: Feature parity (pass)
I listed every public symbol in the 6 source files at v4.1.1 and at HEAD:
- `SignalFilter` (`filterVersion`, `highPassCutoffHz`, `sampleRate`, `init`, `apply`)
- `RateMath.bpm`
- `SampleBuffer` (`capacity`, `samples`, `init`, `append`)
- `Debouncer` (`init`, `signal`)
- `SessionClock` (`init`, `timestampMs`)
- the 4 `RecordLabels` constants

All are still present, and the only addition is `SessionClock.elapsedSeconds(at:)`. There are no views, SwiftData models or hooks in this checkout (no `static var …: (@…` declarations). Nothing was removed.

## Gate 2: Scope (pass)
Every hunk traces to an approved finding:

| Finding | Source change | Pin |
|---|---|---|
| F-1 | `RateMath.swift:8` | `RateMathTests` |
| F-2 | `SampleBuffer.swift:14` | `SampleBufferTests` |
| F-3 | `SessionClock.swift:16-19` | `SessionClockTests` |
| F-4 | `Debouncer.swift:15` | `DebouncerTests` |

No renames, reformatting or extra fixes.

## Gate 3: Tests prove the fix (2 blocking findings)
I ran each pin with its fix, then with only that file reverted to v4.1.1, one fix at a time.

| Pin | With fix | Without fix | Label |
|---|---|---|---|
| F-1 `RateMathTests.testBpmIsRoundedToNearestBeat` | passed | **passed** | **PASSES WITHOUT FIX** |
| F-2 `SampleBufferTests.testFullBufferKeepsCapacitySamples` | passed | failed: `[4,5,6]` ≠ `[3,4,5,6]` | FAILS WITHOUT FIX |
| F-3 `SessionClockTests.testElapsedSeconds…` | passed | doesn't compile (`no member 'elapsedSeconds'`) | DOES NOT COMPILE WITHOUT FIX. Accepted, because the fix is entirely the new method the pin calls. |
| F-4 `DebouncerTests.testRapidSignalsRunTheActionOnce` | **skipped** | skipped | **NOT RUN** (the test skips itself) |

**G3-1. `gate/pin-fails-without-fix/RateMathTests/passes-on-truncating-code`: BUG, CONFIRMED BROKEN, blocking.**
- `RateMathTests.swift:7-9` only checks 1000, 750 and 500 ms. Each divides 60,000 exactly, so truncating and rounding give the same answer.
- The plan names 790 ms → 76, but the test doesn't check it.
- A throwaway test in the copy did check 790 ms. It fails without the fix (`"75" is not equal to "76"`) and passes with it.
- **Fix direction:** add the plan's 790 → 76 case to the pin.

**G3-2. `gate/pin-must-execute/DebouncerTests/xctskip-always-taken`: BUG, CONFIRMED BROKEN, blocking.**
- `DebouncerTests.swift:7-12` skips the test whenever `Thread.sleep(0.01)` overruns by more than 50 µs.
- It skipped on all 16 runs; the measured overrun was 62 µs to 2.5 ms. So F-4 effectively has no pin.
- The refactorer's "swift test passes" left out that a test was skipped.
- I ran the same assertion without the skip in the copy. It passes with the fix and fails without it (`"2" is not equal to "1"`).
- **Fix direction:** remove the `XCTSkip` guard. A 50 ms delay against a 200 ms wait leaves plenty of margin.

**Domain sweep.** No constant became data-driven in this diff. I still checked the values numerically:
- **F-1:** every 1 ms interval from 272 to 2000 ms (220 down to 30 bpm, the range in the README). With the fix, every result is within 0.5 bpm of the exact value. Without it, 850 of 1,729 are off. Intervals of 0, negative or NaN all return 0.
- **F-2:** a buffer with capacity 1 **crashed in v4.1.1** (`Can't remove first element from an empty collection`) and works after the fix. This is an `OBSERVATION`: the existing pin already catches a revert to the old rule, but the crash isn't recorded anywhere.

## Gate 4: Data Safety (1 item needs your decision)
**G4-1. `data-safety/analysis-version/RateMath.bpm/unversioned-metric-change`: BUG, NEEDS USER DECISION.**
- F-1 changes the bpm values computed from beat intervals, and no version records the change. The only analysis version, `SignalFilter.filterVersion = "hp-0.5"`, is unchanged.
- Trigger it may hit: *"Changing analysis algorithm/filter/configuration versions."*
- If a host app stores bpm, sessions recorded before and after the fix can't be told apart. If a host app recomputes bpm from stored beat intervals, past sessions will display different rates. Either way the raw data is intact but read differently.
- I can't see from this checkout how the host apps use `RateMath`. They pin a different WidgetKit checkout and don't reference these symbols.
- Approving the plan isn't a recorded Data Safety confirmation. You need to decide whether this triggers the rule; if it does, the confirmation procedure in `DATA_SAFETY.md` applies before merge.
- There are no `@Model`, storage-location or destructive-path changes.

## Gate 5: Scientific honesty (1 blocking item)
- No honesty violations. Labels and doc comments make no claims the project rules forbid.

**G5-1. Blocking:** F-1 changes a metric, and there is no `_reports/` file or quoted review from `acme-analysis-reviewer` covering **v4.1.1..51f0386**.

## Gate 6: Concurrency (1 observation)
- `OBSERVATION`: `Debouncer.pending` is a plain mutable property with no synchronisation. The diff adds a read (`pending?.cancel()`) next to the write that was already there. That's only a problem if `signal` is called from more than one thread, and the risk existed before this diff.
- Refer to `acme-concurrency-reviewer` / `acme-transport-reviewer`.

## Gate 7: Data and join integrity (pass)
- `timestampMs` is unchanged, so the CSV `timestamp_ms` contract is unchanged.
- `SampleBuffer` now holds `capacity` samples instead of `capacity − 1`. Nothing in this checkout uses it.
- Window-length effects belong to `acme-pipeline-reviewer`, shared with signal-analysis. I expect they'll agree, since this is the approved F-2.

## Gate 8: Package changes from a host app (not applicable)
- This is the package repo, not a host app.
- The one API change, `elapsedSeconds(at:)`, is additive. I found no `extension SessionClock` and no use of these symbols in the Gizmo or Sprocket sources.
- API shape belongs to `acme-architecture-reviewer`.

## Gate 9: Build configuration (pass)
- `Package.swift` is unchanged. There's no `project.yml`, and the tests import nothing new.

## Other observations
- The changelog has no entry for this batch. Under rules §14 it gets updated after validation.

## Gate status
| Gate | Status |
|---|---|
| 1 Feature parity | pass |
| 2 Scope | pass |
| 3 Tests prove the fix | **2 blocking** (G3-1, G3-2), plus 1 observation |
| 4 Data Safety | 1 needs your decision (G4-1) |
| 5 Scientific honesty | **1 blocking** (G5-1) |
| 6 Concurrency | 1 observation |
| 7 Data and join integrity | pass |
| 8 Package changes from a host app | not applicable |
| 9 Build configuration | pass |

**Device checks before this ships:** `DEVICE_CHECKLIST.md` §2 (rate readings, for F-1) and §4 (recording screen timer, once a host app uses `elapsedSeconds`). No section covers the battery badge (F-4); that gap is for whoever owns the checklist.

**Verdict: REQUEST CHANGES**
1. G3-1: the F-1 pin passes on the truncating code. Add 790 ms → 76.
2. G3-2: the F-4 pin never runs. Remove the `XCTSkip` guard.
3. G5-1: get a signal-analysis review of v4.1.1..51f0386.
4. G4-1: decide whether F-1 triggers the Data Safety rule, and if it does, complete the confirmation before merge.

**Gate copy:** all runs used one copy, `$TMPDIR/gate-mut.U0SBY1`, with no `.git`, and I deleted it with `rm -rf -- "$d"` (confirmed gone).
- My first revert loop didn't actually revert anything (a zsh word-splitting slip), so I threw those runs away.
- That loop left 4 empty stray files inside the copy only. I removed them and confirmed the copy matched HEAD before the real runs.
- The real repository was never written to; `git status` is clean.
- I haven't written a `_reports/` file because this gate is read-only. Whoever runs the next step should save this as `_reports/2026-10-22-remediation-gate-batch1.md`.