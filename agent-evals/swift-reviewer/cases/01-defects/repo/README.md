# Lifts

A local-first workout log for iPhone. SwiftUI and SwiftData; no server, no accounts.

## Protecting trust in the data

- A session is recorded history once it is locked (`lockedAt` is set). Its stored values
  are never overwritten. A fix is appended as a correction and shown on top of the
  logged value.
- Weights are stored in kilograms and converted for display only.

## Build and test

```bash
xcodegen generate
xcodebuild test -scheme Lifts -destination 'platform=iOS Simulator,name=iPhone 17'
```
