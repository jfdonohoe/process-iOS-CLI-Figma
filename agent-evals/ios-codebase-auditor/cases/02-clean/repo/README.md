# Lifts

A local-first workout log for iPhone. SwiftUI and SwiftData; no server, no accounts.

## Design principles

- One source of truth: the SwiftData models. Views derive what they show from them.
- Keep it boring: straightforward Swift, Foundation and SwiftUI over clever abstractions.
- Small files, one responsibility each.

## Protecting trust in the data

- A session that has been finished is history. Its sets are never rewritten; the
  History screen only reads them.
- Weights are stored in kilograms and converted for display only.

## Features

- Live sessions: tick sets off; the header shows how many are done.
- History grouped by month with a per-exercise set count, and a "this week"
  section. Training weeks are 7-day blocks counted from the first session ever
  scheduled, so a block boundary never moves when the user travels or the
  clocks change.

## Build and test

The Xcode project is generated from `project.yml` by XcodeGen in CI and is not
checked in. Locally:

```bash
xcodegen generate
xcodebuild test -scheme Lifts -destination 'platform=iOS Simulator,name=iPhone 17'
```

Unit tests live in `LiftsTests/`.
