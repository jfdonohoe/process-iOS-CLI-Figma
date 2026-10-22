# Puffin

A reading tracker: the books you're reading, your shelf, and reading goals. iOS 17+, SwiftUI + SwiftData,
local only. Colours live in `Theme.swift` and `Assets.xcassets`.

## Declined accessibility items

Visual accessibility fixes the developer looked at in Figma and decided not to make. Their WIP sections are in Archive as `Not approved - …`.

| ID | What | Where | Declined |
|----|------|-------|----------|
| A11Y-3 | Page-count footnote in `Color.mist` on white, 2.47:1 | Now Reading, `NowReadingView` | 2026-10-14 |
| A11Y-4 | "Log Reading" capsule: white label on Apricot, 3.10:1 | Now Reading, `NowReadingView` | 2026-10-14 |
| A11Y-5 | Finished seal symbol is read aloud next to "Finished" | Now Reading, `NowReadingView` | 2026-10-14 |
