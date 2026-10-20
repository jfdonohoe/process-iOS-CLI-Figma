# Kestrel: project notes

Trail log for iOS 17+ (SwiftUI + SwiftData). Follows `~/.claude/ios-project-standard.md`.

## Figma
Figma file "Kestrel – App Screens". Production is synced from simulator captures, never edited by hand.

## Versioning
Semantic Versioning (standard §10). Run `/ios-version` before every release. Approved numbers go in both build
configurations, CHANGELOG.md and an annotated `vX.Y.Z` tag on the release commit.

## Release push: include the Figma file
A release commit includes a fresh export at `design/Kestrel-App-Screens.fig` (File → Save local copy… in the Figma
app). Before staging, check that it exists, is under an hour old, starts with `fig-kiwi` or `PK`, and warn above 50 MB.
