# Plover: project notes

Paced-breathing app for iOS 17+ with heart-rate feedback from HealthKit. Follows `~/.claude/ios-project-standard.md`.

## Release rules
- Settings shows the app's version and build read from `Bundle.main` at runtime, never hard-coded (standard §10.1).
- `/ios-version` before each release; CHANGELOG.md and an annotated `vX.Y.Z` tag.
