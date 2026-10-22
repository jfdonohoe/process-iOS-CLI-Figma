# Regression audit: WidgetKit

```
Branch: main   HEAD: 2a8193e   Tree: clean (0 uncommitted files)
Project: WidgetKit   Tag: v4.1.1 (HEAD is v4.1.1-1-g2a8193e)
build: pass   test: 5 executed, 3 passed, 1 failed (2 assertion failures), 1 skipped
  (swift build / swift test --scratch-path "$TMPDIR/wk-build")
Canonical docs read: README.md, BUGS.md, FEATURES.md, CHANGELOG.md
Not present (README doesn't claim them, so not findings): BEST_PRACTICES.md, .claude/agent-context.md,
  _reports/ (incl. regression-registry.md), physical device checklist (git ls-files | grep -i checklist → empty)
Prior reports read: none exist
Disk: 143 GiB free
```

The change under audit is commit `2a8193e` ("Mock device transport and session handler tests"). It adds `MockDeviceTransport.swift`, `MockDeviceTests.swift`, `SessionHandlerTests.swift`, `FEATURES.md` and `CHANGELOG.md`.

**The full suite fails: the change breaks the B-12 regression test whenever the whole suite runs.**

## Phase 1: Build and full test suite

- **Build:** passes, with no errors.
- **Tests:** 5 executed, 3 passed, 1 failed, 1 skipped.

**The failure, quoted:**
```
TimestampGoldenTests.swift:9: error: -[WidgetKitCoreTests.TimestampGoldenTests testGoldenOffsetsAgainstFileStart] : XCTAssertEqual failed: ("-92702446842") is not equal to ("12345")
TimestampGoldenTests.swift:10: error: -[WidgetKitCoreTests.TimestampGoldenTests testGoldenOffsetsAgainstFileStart] : XCTAssertEqual failed: ("-92702459179") is not equal to ("8")
```

**The skip, quoted:** `ReconnectBackoffTests.testRetryFiresOnSchedule` skipped itself: "Scheduler jitter 0.00158s is too high to time a retry reliably" (`ReconnectBackoffTests.swift:18`).

**Test count:** it went from 3 at v4.1.1 to 5 now (`git show --stat fe880a5` has 3 test methods). The +2 are `MockDeviceTests` and `SessionHandlerTests`, which match the CHANGELOG's "Unreleased: Mock device transport tests". The count is fully explained, so there is no drift.

**Test isolation** (test files added since v4.1.1):
- `SessionHandlerTests.swift`: writes `AcmeSessionHandler.shared.startDate` at line 19. It saves the value in `setUp` (line 9) and restores it in `tearDown` (line 13), so it is clean.
- `MockDeviceTests.swift:7`: writes `AcmeSessionHandler.shared.startDate = start` (where `start = Date()`). It has no `setUp`/`tearDown` and never restores the value. This is the cause of the failure (R-1 below).

**Tests that can skip themselves on timing:** 1 (`testRetryFiresOnSchedule`). It skipped in this run (O-1 below).

### R-1 `test-isolation/shared-state-leak/MockDeviceTests.testMockDeviceStampsSamplesFromSessionStart/golden-timestamps-shifted`: NEW
- **Class:** `REGRESSION`. **Status:** `CONFIRMED BROKEN`. Proven by build/test, not just by reading source.
- **Where:** `Tests/WidgetKitCoreTests/MockDeviceTests.swift:6–7`. The test sets the process-wide singleton's `startDate` to `Date()` and leaves it set.
- **Rule it breaks:** `BUGS.md` B-12 says it is "Guarded by: `TimestampGoldenTests.testGoldenOffsetsAgainstFileStart`". That guard now fails in the full suite.
- **How it fails:**
  - XCTest runs the classes alphabetically: `MockDeviceTests` → `ReconnectBackoffTests` → `SessionHandlerTests` → `TimestampGoldenTests`.
  - `SessionHandlerTests` saves and restores the value that has *already leaked*, so it passes it straight through.
  - `SessionTimestamp.offsetMs` (`SessionTimestamp.swift:8`) then sees a non-nil `startDate` and measures from the time of the test run instead of `fileStart` (1_700_000_000).
  - The result: −92 702 446 842 ms. That is 1_700_000_012.345 − ~1_792_702_459 s, and the clock read 1_792_702_477 about 18 s later, so it matches the leaked `Date()`.
- **How I isolated it:**
  - `--filter TimestampGoldenTests` alone: passes.
  - `--filter 'SessionHandlerTests|TimestampGoldenTests'`: passes.
  - With `MockDeviceTests` in the run: fails.
- **Scope:** the production code is not regressed. The B-12 fix is still in place (see Phase 4). What broke is the guard that pins it, which can no longer pass in a full-suite run. This is the same shape as the precedent in this prompt (a Bluetooth mock test leaving `startDate` set). Here the shift is about 2.9 years, not 40 s, because the golden `fileStart` is in 2023.
- **Smallest safe correction, if approved:** have `MockDeviceTests` save and restore `AcmeSessionHandler.shared.startDate` in `setUp`/`tearDown`, the same way `SessionHandlerTests` does. Arguably `TimestampGoldenTests` should also clear `startDate` before it asserts, since it depends on `startDate == nil`.
- **Validation:** the full `swift test --scratch-path "$TMPDIR/wk-build"` should show 5 executed and 0 failures.

### O-1 `test-timing/self-skip/ReconnectBackoffTests.testRetryFiresOnSchedule/never-runs`
- **Class:** `OBSERVATION`. **Status:** `NEEDS USER DECISION`.
- **What:** the skip threshold is 50 µs of overshoot on a 10 ms `Thread.sleep` (`ReconnectBackoffTests.swift:17`). It skipped in 6 of 6 runs (the full suite plus 5 filtered runs), with measured overshoot between 277 µs and 2.29 ms.
- **Effect:** in practice it never runs, so it pins nothing. It isn't a documented guard (B-14 is guarded by `testDelayIsCappedAtThirtySeconds`, which passes), and it predates this change (it is in v4.1.1).

## Phase 2: Hook and seam wiring

- **Inventory:** `grep -rnE 'static var [A-Za-z]+: *\(@' Sources/` returns **0 matches**. This matches the README ("declares no host hooks"). There's no `BEST_PRACTICES.md` §5 to cross-check against.
- **Hooks:** 0 of 0. There are no host apps in scope, and no known orphans.

**Unwired setup, unread settings, unobserved notifications:**
- No services, notifications or `UserDefaults` were found in `Sources/`.

### O-2 `wiring/out-of-checkout/startDate+ReconnectBackoff/no-production-caller-here`
- **Class:** `OBSERVATION`.
- **What:** two things that FEATURES.md and the README describe have no caller in `Sources/`:
  - `AcmeSessionHandler.shared.startDate` is read in one place (`SessionTimestamp.swift:8`) but only ever assigned in tests. Nothing in `Sources/` sets it at session start or sets it back to nil afterwards.
  - `ReconnectBackoff.delay(attempt:)` is called only from tests.
- **Why it's only an observation:** the README says the real BLE transport is not in this checkout. So the setting, clearing and calling would live outside it, and I can't verify them from here. This is exactly the "declared, read, never assigned" shape this audit looks for. It needs checking wherever the transport lives.

## Phase 3: FEATURES.md cross-check

The header says "Accurate as of 2026-10-21 (v4.1.1)".

**Forward check:** 3 of 3 sections have their cited type at the cited path.
- **§1 Session timing:** `SessionTimestamp` is present.
- **§2 Reconnect backoff:** `ReconnectBackoff` is present, with the cap at 30 s (`ReconnectBackoff.swift:5,8`).
- **§3 Mock device:** `MockDeviceTransport` is present, and it does stamp through `SessionTimestamp.offsetMs` (`MockDeviceTransport.swift:16`).
- For §1 and §2, I couldn't confirm the runtime path from this checkout (see O-2).

**Reverse check:**
- The UI-control grep scope (`DemoApp/`, `Sources/WidgetKitUI/`, `AcmeSignalType.swift`) doesn't exist in this checkout. **Derived UI-capability count: 0.**
- The public API surface is 4 types, all covered by FEATURES.md.

### D-1 `docs/features-header/FEATURES.md/claims-v4.1.1-but-lists-unreleased`
- **Class:** `DRIFT`.
- **What:** the header says the file is accurate as of v4.1.1. But it was created in `2a8193e`, after v4.1.1, and §3 (the mock device) is listed under "Unreleased" in the CHANGELOG. `git show fe880a5:FEATURES.md` confirms the file didn't exist at v4.1.1.
- The code is fine; only the header is wrong.

## Phase 4: Documented fixes

| Item | Pinning test | In the full suite | Fix in source | Result |
|---|---|---|---|---|
| **B-12** (export timestamps re-stamped from the file's own start) | `TimestampGoldenTests.testGoldenOffsetsAgainstFileStart`: present, starts with `test`, not skipped, asserts exact millisecond values | **FAILS** (R-1) | `startDate ?? fileStart` at `SessionTimestamp.swift:8`, in place | Code intact; **guard CONFIRMED BROKEN** (R-1) |
| **B-14** (backoff capped at 30 s) | `ReconnectBackoffTests.testDelayIsCappedAtThirtySeconds`: asserts attempt 40 → 30 (uncapped would be about 5.5e11) | Passes | `min(cap, …)` with `cap = 30` at `ReconnectBackoff.swift:5,8` | `FIX CONFIRMED INTACT` |

**How I found every site:**
- I grepped `Sources/` and `Tests/` for `timeIntervalSince`, `SessionTimestamp.` and `ReconnectBackoff.`.
- There is exactly 1 place that computes a timestamp offset (`SessionTimestamp.swift:9`), and its one production caller (`MockDeviceTransport.swift:16`) goes through it.
- There is exactly 1 place that computes the backoff delay.
- If either fix had been broken, I'd expect a bare `timeIntervalSince` against an arrival or session time somewhere else, or a missing `min(cap, …)`. I found neither.
- There is no DSP/ML item to refer.

## Phase 5: Product rules and destructive paths

**"CSV timestamps are session-relative":** enforced at `SessionTimestamp.swift:8–9`. Both branches have a test:
- the running-session branch: `SessionHandlerTests` (passes);
- the file-start branch: `TimestampGoldenTests` (fails in the full suite because of R-1).

It is pinned, but the pin is currently red.

**"One session at a time":** a single instance is enforced by the `private init()` on the singleton (`AcmeSessionHandler.swift:10`). "nil between sessions" is not enforced anywhere in this checkout, and no test would fail if it broke.
- **Class:** `OBSERVATION` (the README doesn't claim a test pins it).
- R-1 is a test-side demonstration of what happens when `startDate` isn't cleared.

**Destructive paths:** the docs describe none, and grepping `Sources/` for `removeItem`/`delete` finds none. Not applicable.

## Phase 6: SwiftUI rendering sweep

There is no SwiftUI code in this checkout, so this phase doesn't apply.

## Status table

| Area | Result |
|---|---|
| Build / test | Build passes. Tests: 5 executed, 3 passed, **1 failed**, 1 skipped (`swift test --scratch-path "$TMPDIR/wk-build"`) |
| Hook wiring | 0 of 0 (none declared, as documented); no host apps in scope |
| Feature inventory | 3 of 3 sections have their code present. 1 DRIFT (D-1). Runtime wiring for §1 and §2 can't be verified from this checkout (O-2). Reverse UI inventory: 0 |
| Documented fixes | 2 fixes, both in place in source. B-14 `FIX CONFIRMED INTACT`. B-12's guard is **CONFIRMED BROKEN** in the full suite (R-1). No registry. |
| Product rules pinned | 1 of 2 (session-relative timestamps, pin currently failing); "one session at a time / nil between sessions" is unpinned |

## Record updates for the main session to make
- New test count: **5** (it was 3 at v4.1.1).
- The test pins are unchanged: B-12 and B-14 keep their "Guarded by" names, and both tests exist under those names.
- New tests with no documented pin: `MockDeviceTests.testMockDeviceStampsSamplesFromSessionStart` (FEATURES §3) and `SessionHandlerTests.testRunningSessionStampsFromItsOwnStart` (the running-session branch of the timestamp rule).
- Per your global rules, write this audit to `_reports/2026-10-22-regression-audit.md`. I made no writes.

## Punch list (prioritized)
1. **R-1:** `MockDeviceTests` leaks `startDate`, which turns the B-12 guard red. This needs approval to fix the test isolation; no production code change is needed.
2. **O-1:** `testRetryFiresOnSchedule` effectively never runs. You need to decide whether to keep it, loosen it or remove it. Removing it needs approval.
3. **O-2:** confirm, in the checkout that holds the real BLE transport, that something sets `startDate` at session start and clears it at session end, and that something calls `ReconnectBackoff.delay`. There's no device checklist in this checkout to cite.

## BASELINE_CONFLICT items
None.

**Referral:** if the production transport (outside this checkout) ever leaves `startDate` set after a session ends, re-stamped exports would shift in exactly the way R-1 shows in tests. That would be a Data Safety trigger ("reinterpret" collected timestamps). Refer to `acme-pipeline-reviewer`.

Overall verdict: NEEDS-WORK