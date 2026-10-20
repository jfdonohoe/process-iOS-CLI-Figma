---
name: ios-version
description: Suggests the next version number for one of the developer's iOS apps by evaluating what changed since the last release and classifying it as a full (major X.0.0), point (minor x.Y.0) or dot (patch x.y.Z) release under Semantic Versioning, plus the build number. Use PROACTIVELY before any release push, TestFlight or App Store build, or when the developer asks what version this should be, to bump the version, or to cut or tag a release. Read-only until the developer approves the number; then it applies the number everywhere it's set, updates CHANGELOG.md and tags the release commit.
---

# iOS version suggestion

The scheme is §10 of `~/.claude/ios-project-standard.md`. Read that section first; it holds the rules. This skill is the procedure.

## 1. Gather the facts (read-only)

Run `~/.claude/skills/ios-version/version-facts.sh <project-dir>`. It prints:
- the current version and build, and every place they're set (flagging values that disagree)
- the release baseline: the last `v*` tag, or failing that the last commit that changed `MARKETING_VERSION`
- the commits and changed files since the baseline, committed and uncommitted
- signals: new or deleted files, schema and model-property changes, backup-format changes, deployment-target changes, Info.plist/entitlement/privacy changes

Then read enough of the actual diff to judge what the signals mean. A new file can be a feature or a refactor; read it before deciding. Also read `CHANGELOG.md`, the README's product rules and recent `_reports/` if they help.

## 2. Classify

Sort each user-visible change into a level using §10.2 of the standard. **The highest level present wins.** Keep internal-only changes in their own list; on their own they justify a dot release at most.

## 3. Propose (don't apply)

Show the developer:

```
Current:   1.1 (build 4)  ·  baseline: <tag or commit, date>
Suggested: 1.2.0 (build 5)  ·  POINT release

Why point, not dot:  <the 1–3 changes that set the level, with file or commit evidence>
Why not full:        <what would have made it full, and why this doesn't qualify>

Changes by level
  Point:  - …
  Dot:    - …
  Internal (no user-visible effect): - …

Draft CHANGELOG entry
  ## [1.2.0] - YYYY-MM-DD
  ### Added …  ### Changed …  ### Fixed …  ### Removed …

Also: <normalise a two-part version, values that disagree across configurations, missing CHANGELOG, etc.>
```

Say plainly where the judgement is close (e.g. "a large fix set; dot is right by the rules, but you could market it as a point release"). The developer decides; the suggestion isn't binding.

## 4. Apply (only after the developer approves the number)

1. Set `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in **every** build configuration of every target in `project.pbxproj`, and in `project.yml` if there is one. Re-run the facts script and confirm there's exactly one value of each.
2. Add the approved entry to the top of `CHANGELOG.md`, creating the file if it doesn't exist.
3. Commit as part of the release commit (the project's release rules apply, e.g. the `.fig` export).
4. After the release commit, create an annotated tag `vX.Y.Z` with the changelog entry as its message. Push the tag only when the developer pushes the release.

For a build-only bump (another TestFlight or device build of the same version), change only `CURRENT_PROJECT_VERSION`. No changelog entry, no tag.
