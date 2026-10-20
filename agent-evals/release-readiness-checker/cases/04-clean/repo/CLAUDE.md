# Wren: project notes

Voice journal for iOS 17+ (SwiftUI + SwiftData). Follows `~/.claude/ios-project-standard.md`.

## Release rules
- `/ios-version` before each release. Approved numbers go in both build configurations, CHANGELOG.md, and an annotated
  `vX.Y.Z` tag on the release commit.
- The Settings footer reads the version and build from `Bundle.main`.
