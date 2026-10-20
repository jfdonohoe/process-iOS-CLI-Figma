# iOS project standard

**Applies to:** every iOS app John builds. That covers a new app project, and an existing project that becomes one (a web prototype, script or package that turns into an iPhone app).
**Established:** 2026-10-18, mostly from lessons on WorkoutApp ("Sets").
**Status:** recommended default. Claude proposes it and John picks what to adopt for each app.

The two practices to replicate first are **Figma-driven development (§2)** and **the agent setup (§3)**. Everything else supports them.

Each item is tagged with where it comes from:
- **[Sets]**: learned on WorkoutApp, with the evidence named.
- **[Senstream]**: from the SenstreamRingKit2 agent setup.
- **[general]**: standard practice, not yet tested on one of John's apps.
- **[suggested]**: an idea that hasn't been built or benchmarked yet.

---

## How Claude uses this

1. When a new iOS app project starts, or a project turns into one, read this file.
2. Check the project against the **Day one** items (§1, §2.1, §3.1) and report what is missing.
3. Ask which items to set up. Don't apply them unasked.
4. As the project grows, propose project-specific agents (§3.4) when a subsystem appears that has its own failure modes.
5. Bring up the device-install and release checklists (§8, §9) when the project reaches those points.
6. **When a new agent, skill, hook or process step appears, ask John whether to add it here.** Don't add it without a yes. Record the answer either way in `~/.claude/ios-project-standard.ledger` (`<kind>:<name> added|declined YYYY-MM-DD`), so nothing is asked about twice.

### Automation
| Piece | What it does |
|---|---|
| `/ios-project-standard` skill | Gap check of a project against this file (`check`, `figma`, `agents`, `device`, `release`) |
| `/ios-version` skill and `version-facts.sh` | Suggests the next version (§10) |
| `~/.claude/hooks/ios-standard-check.sh` (SessionStart) | Recommends this standard in an iOS project whose CLAUDE.md doesn't mention it yet |
| `~/.claude/hooks/standard-unreviewed-scan.sh` (SessionStart) | Lists agents and skills that are neither in this file nor in the ledger, so Claude can ask about them once |
| `~/.claude/hooks/standard-candidate.sh` (PostToolUse on Write/Edit) | After Claude writes an agent, skill, hook or CLAUDE.md, reminds it to ask whether that belongs here |
| `~/.claude/ios-project-standard.ledger` | Every candidate John has been asked about, with his answer |
| Git repo `~/Documents/Claude/Projects/ios-best-practices` | Source of truth for this standard, its skills, hooks, tools, global agents and evals. `~/.claude` paths are symlinks into it (`install.sh`), so every edit shows in `git status`. Commit changes to the standard there |
| `~/.claude/tools/` | Simulator driver and SF Symbol vector pipeline (§2.4, §2.6) |

---

## 1. Day one: repo and Xcode project

### Repo
- **`git init` before the first line of code.** Commit small and often, and commit before every major change. [Sets] At one point WorkoutApp had 120+ uncommitted files, spread across many sessions.
- **`.gitignore`:** Xcode user data, DerivedData, build products, secrets.
  - **Don't ignore `.claude/` as a whole.** Ignore only `.claude/settings.local.json`, so the project's agents are versioned with the code. [Sets] WorkoutApp ignores all of `.claude/`.
- **Standard top-level folders:**
  - `_reports/`: dated reviews, audits and the regression registry
  - `design/`: the `.fig` export
  - `images/`: source artwork
- **A project wiki** exists from day one and is kept in step with `main` (§11): a GitHub wiki when the repository is public, a Google Doc in Drive when it is private.

### Xcode project
- **One source of truth for project settings:** either an XcodeGen `project.yml` or the `.xcodeproj`, never both drifting apart. [Sets] In WorkoutApp, `project.yml` and `project.pbxproj` disagree on the bundle ID.
- **Pick the bundle ID once:** `com.donohoeux.<app>`. Changing it later makes a new app on the phone, and the old data container stays behind with the old app. [general]
- **Write down the platform decisions in CLAUDE.md:** deployment target, device family, orientation, display name.
- **Swift 6 language mode with strict concurrency, from the start.** [general]
- **Folder layout:** `App/ Models/ Persistence/ Services/ Views/` plus a unit-test target. [Sets]
- **Versioning:** Semantic Versioning (§10), starting at `1.0.0` (or `0.1.0` before the first real release), with a `CHANGELOG.md` from the first release. [general]

### Project CLAUDE.md
- The stack, the exact build and test command, and the simulator name.
- The Figma file key and the release steps (§2.5).
- A **known pitfalls** list that grows as bugs are found. It also feeds the `swift-reviewer` checklist (§3.1).

---

## 2. Figma-driven development [Sets]

Figma is where a screen is decided. Code builds what was approved, and Figma is then synced to match what was built. Nothing gets built from a conversation alone if it changes how a screen looks.

### 2.1 Day one: the file
One Figma file per app, named `<App> – App Screens`. Record its file key in the project CLAUDE.md. It has five pages, in this order:

| Page | Holds | Rule |
|---|---|---|
| 🛳️ **Production** | The screens as they're currently built, grouped in sections by area | Never edited directly. It changes only in the sync step (2.3) |
| ✅ **Approved** | Designs signed off and waiting to be built | Sections named `Approved - <topic> (YYYY-MM-DD)` |
| 🚧 **WIP** | All exploration and iteration | Sections named `WIP - <topic> (YYYY-MM-DD)`, one per piece of work |
| 🗄️ **Archive** | WIP and Approved sections after they've been built and synced | Kept, never deleted, so design history survives |
| 🧱 **Components** | The component library and its variants | Bound to variables that mirror `Theme.swift` |

### 2.2 Conventions
- **Claude works only on the WIP page** unless John names another page. Don't create new files or pages. [Sets] A mockup once had to be moved from a standalone file.
- **Stack sections vertically** at x = 0 with a 200 px gap. Screens are frames at device width (393 for iPhone).
- **Revise existing WIP frames in place.** Don't make a new section for every round of feedback.
- **Base edits to Production screens on clones,** placed in a WIP section.
- **Use Inter for text.** SF Pro doesn't render in Figma screenshots.
- **List pages through `use_figma`** (`figma.root.children`), not `get_metadata`, which can miss pages. [Sets] This once led to a duplicate WIP page.
- **When a section grows, check the whole page for overlaps,** comparing node bounds rather than judging a screenshot. This is the global Figma rule.
- **Build screens from Components only.** Once the library exists, a screen is component instances with properties set: a 1–2 KB `use_figma` script. Don't paste hand-built helper code into every call; if a screen needs a new building block, add it to Components first. [Breathe]
- **Check cheaply.** Verify positions and sizes with a read-only bounds/measurement script (text). Screenshot only to confirm, one screen at half scale, not whole sections, and never again when nothing changed. [Breathe]
- **Instance-swap gotchas.** A swapped nested instance keeps the slot's size and can't be resized or moved from the API, so make swappable icons square 24 × 24 canvases (glyph centred at native size), and use variants (not swaps) when the icon size must differ. `maxWidth` can't be overridden on instances, so set it in the component. [Breathe]

### 2.3 The loop
1. **Explore** on WIP: a new dated section built from Components and theme variables.
2. **Approve:** John signs off, and the section moves to Approved as `Approved - …`. Any standard it sets is recorded as a memory or a CLAUDE.md rule (e.g. "green = actionable", "the exercise sheet header shows the type").
   - **Approval is visual only. It is not an instruction to code.** "Approved" moves the section from WIP to Approved and stops there. Approved sections are allowed to stack up. Don't edit code, sync Production or archive anything because something was approved. [Breathe] (2026-10-19: two approvals were built, synced and archived without being asked, then undone.)
3. **Build** in SwiftUI from the Approved frames, with tokens taken from `Theme.swift`, never hard-coded. **Only when John explicitly says to code it** (e.g. "code the approved changes"). That instruction covers everything on Approved unless he names specific sections, and it runs steps 3–6 for them: build, verify, sync to Production, archive.
4. **Verify** in the running app, not just in tests.
5. **Sync:** replace the matching Production frames with the built design, matching real copy and real states. Re-stack Production and check for overlaps.
6. **Archive** the Approved section. Approved goes back to holding only what is still waiting to be built.

### 2.4 Design system
- **`Theme.swift` ⇄ Figma variables, one to one.** A new token is added to both in the same piece of work.
- **Colour meanings are rules,** recorded the first time they come up, with exceptions written down (e.g. green is also allowed for pass states).
- **Changing components safely:** before restructuring components, take a render signature of every Production screen. Diff it after each step and throw inside `use_figma` to roll back on any difference. Known traps (variant bindings, `removeOverrides`, deleting component properties) are in the WorkoutApp memory `figma-plugin-api-lessons`.
- **Splash screen:** follow `~/.claude/ios-splash-standard.md`.
- **Icons are SF Symbol vectors,** never screenshot crops. Get them with `~/.claude/tools/sf-symbol-match` (finds the code point) and `sf-symbol-export` (outline SVG at weight 400, 590 for tab icons); custom symbols come from the app's `.symbolset` via `sf-symbolset-extract.py`. See `~/.claude/tools/README.md`. [Breathe]

### 2.5 Release
A full release commit includes a fresh `.fig` export at `design/<App>-App-Screens.fig`. Only the Figma app can make it (File → Save local copy…), so Claude asks for it. Before staging, check that it exists, is less than an hour old, has the `fig-kiwi` or `PK` signature, and is a sensible size: warn above 50 MB, use LFS above 100 MB. Copy WorkoutApp's CLAUDE.md section with the names changed.

### 2.6 Simulator demo state for screenshots [Breathe]
Production screens are captured from the real app running in the simulator, in every state the app can be in. Empty screens and hand-drawn mockups are not an accurate record of what was built, so every app keeps a simulator-only demo mode ready from day one. (Added 2026-10-19, Breathe.)

- **A sample-data seeder**, compiled only for `DEBUG` simulator builds and run only when the app is launched with `-<App>SampleData`. It fills the persistent store with a realistic spread of records: every entity type, every status, quality, type and condition variant the UI distinguishes, several weeks of history so grouped lists and trend charts have shape, and at least one in-progress or abandoned item. It writes any files those records reference (audio, images, exports), and fakes hardware and account state (paired, connected, charging and past devices; a signed-in profile) so gated UI such as start buttons, badges and status rows shows its ready state as well as its blocked state.
- **A flow harness**, `-<App>SampleFlow=<screen>`, renders the screens that need live hardware or a running process (preparing, in-session, complete) from the real views with synthetic state.
- **Clearly marked and safe.** Sample IDs carry a `sample-` prefix and derived rows carry a `sample` version string, so they can never be mistaken for real data. The seeder is idempotent, never compiled for device builds, and never touches an existing store on a device.
- **Capture procedure.** Build and launch with the launch argument on the standard simulator (iPhone 16, 393 pt). Screenshot with `xcrun simctl io <udid> screenshot`. When the UI-automation tools are not enabled, drive navigation with System Events clicks on the Simulator window. Capture the empty states too, by launching without the argument. Build Production screens in Figma from these captures (status bar and tab bar from the iOS library, real copy and real values).
- **Keep it current.** When a screen or model gains a new state, add that state to the seeder in the same piece of work, the way a new token goes into both `Theme.swift` and the Figma variables.
- **Tools.** Drive taps, scrolls and screenshots with `~/.claude/tools/sim-drive.py`; don't rewrite a driver per session.
- **Tests run on a clean simulator.** Seeded data persists across launches and breaks UI tests that expect empty states. Uninstall the app (`xcrun simctl uninstall <udid> <bundle id>`) before a test run, and re-seed afterwards only when capturing. [Breathe]
- **Record it.** The project CLAUDE.md names the launch arguments, the seeder file and the capture steps.

---

## 3. Agents

### 3.1 Baseline set: every iOS app [Sets]
These live in the project's `.claude/agents/`, copied from WorkoutApp and adapted (app name, README rules, pitfalls).

| Agent | Role | When it runs | Writes? |
|---|---|---|---|
| `swift-reviewer` | Reviews a change for correctness and the project's known pitfalls | **Proactively** after every `.swift` edit | No |
| `ios-codebase-auditor` | Architecture, data integrity, performance, duplication and test gaps across the whole app | Audits and `splitaudit` area runs | No (plan mode) |
| `ios-codebase-refactorer` | Applies approved audit findings conservatively, preserving behaviour | Only after John approves specific findings | Yes |
| `regression-reviewer` | Four phases: (0) branch, HEAD and registry; (1) build and run the **whole** suite, comparing the count with the last run; (2) every **fixed** registry row is still in place and pinned by a test that runs and asserts it; (3) the README product rules still hold and are pinned; (4) documented features are wired up from the `@main` launch path. Returns PASS or NEEDS-WORK | **Proactively** after code revisions, before calling work done. This *is* "full regression testing" | No |

`regression-reviewer` is benchmarked in `~/.claude/agent-evals/regression-reviewer/` (v2, 2026-10-18), with a regressions case and a clean case.

Global agents that come along automatically:
- `dead-code-finder`: owns dead code. It runs alongside every whole-app audit.
- `review-agent-evaluator`: benchmarks a reviewer agent after it is created or edited.

### 3.2 Infrastructure that makes agents work
- **Shared finding scheme:** P0–P3 severity and a CONFIRMED/PLAUSIBLE verdict, using the same keys in every agent. Reports from different agents and different apps then merge and compare. Write it in `.claude/agents/README.md`. [Sets]
- **Clear ownership:** each concern has one owner, and the others refer to it in one line rather than reporting it (dead code → `dead-code-finder`, style and performance → the auditor). This avoids duplicate findings. [Sets]
- **Audit, then fix, as separate steps.** Auditors are read-only and stop at the report. Fixes happen in a separate run, after approval. [Sets, Senstream]
- **No project state in agent prompts.** Prompts hold method and the shapes of past failures. Test counts, bug statuses and versions are worked out at run time or read from the project's documents. If a prompt and the source disagree, the agent reports it and trusts the source. [Senstream] (`~/.claude/senstream-agent-rules.md` §2–4)
- **Documents the agents read** (the project's single source of current state):
  - `README.md`: product rules and testing
  - `_reports/regression-registry.md`, maintained by the main session; the agent reports updates and never edits it:
    - one row per bug (`R-nnn`): the fix's shape, its location, its pinning test (`File › testName`), a status (**fixed** / **open** / **accepted** / **superseded**), and its source report
    - a "Last full run" line: HEAD, tests run, passed and failed, and the verdict
    - add a row when a fix lands, update it when a test is renamed, and update the count after each run
    - start it with the first fixed bug. For an existing app, seed it from `_reports/`, as WorkoutApp did on 2026-10-18 (169 lines)
  - Optionally `FEATURES.md` and `BUGS.md` once the app is big enough. [Senstream]
- **Benchmarks:** every custom reviewer gets a seeded-defect benchmark in `~/.claude/agent-evals/<agent>/`. Snapshot the agent before editing it, and re-run the old snapshot on the same day, because model updates move the scores. [Sets]
- **Audit procedure:** `splitaudit` (global CLAUDE.md). Reports go in `_reports/YYYY-MM-DD-<topic>.md`.

### 3.3 Suggested additions to the baseline [suggested]
None of these has been built or benchmarked. Each fills a gap the current four leave open. They're listed in the order I'd add them:

| Agent | Gap it fills | Trigger |
|---|---|---|
| `design-sync-reviewer` | Nothing checks built SwiftUI against the Approved/Production Figma frames: copy, order, tokens, states. Today that's done by hand in steps 2.3.4–5 | After building an Approved section, and before the sync step |
| `schema-migration-reviewer` | Any change to a `@Model`: is it a new `VersionedSchema`, is there a migration stage, does the export DTO cover the new fields, is there a test that opens the previous store? (Audit H1 and the export data-loss report were both this class of bug) | Proactively when a file in `Models/` or `Persistence/` changes |
| `release-readiness-checker` | Runs the §9 checklist: the version from `/ios-version` (§10), privacy manifest, usage strings, entitlements, `.fig` export checks, registry count, a clean `regression-reviewer` result | When John asks for a release push |
| `accessibility-reviewer` | Dynamic Type, VoiceOver labels on icon-only buttons, hit targets, contrast against the theme tokens | Before release, and on new screens |

### 3.4 Project-specific specialists
When a project grows a subsystem with its own ways of failing, propose a specialist reviewer for it instead of stretching the baseline agents. [Senstream] SenstreamRingKit2 has six, covering BLE/concurrency, the capture pipeline, DSP/ML, architecture/API, regression, and upstream sync.

**Signs a specialist is warranted:**

| Subsystem appears | Possible specialist |
|---|---|
| CoreBluetooth or other hardware I/O | BLE lifecycle, reconnect and concurrency reviewer |
| High-rate data, signal processing, Core ML | Pipeline and numerical-safety reviewer |
| HealthKit, CloudKit, or sync with a server | Sync, conflict and permission reviewer |
| StoreKit or subscriptions | Purchase-state and receipt-edge reviewer |
| Widgets, Live Activities, App Intents, watchOS | Extension and shared-container reviewer |
| A package or app extracted from another codebase | Upstream-sync reconciliation agent |
| A shared Swift package with public API | Architecture and public-API reviewer |

**How Senstream builds them:**
- One shared rules file (read-only contract, truth-source precedence, output scheme), read first by every specialist.
- Each specialist is narrow, read-only, and owns its own known bugs and accepted limitations.
- A regression agent per project, plus a physical-device checklist for whatever static review can't prove.
- Higher model and effort settings for the deep specialists.

Name specialists `<project>-<area>-reviewer`. Benchmark each one before relying on it.

---

## 4. Data and persistence (SwiftData)

- **`VersionedSchema` + `SchemaMigrationPlan` from day one.** Each shipped schema change gets a new version. Don't keep adding fields in place to V1. [Sets] (audit 2026-10-17, H1)
- **Never `fatalError` when the store fails to open.** Show a recovery screen that offers export or a reset. [Sets]
- **Migration test:** open a store created by the last released build, using the current code. [Sets]
- **Recorded history is append-only.** A correction is a new record; a locked record is never overwritten. [Sets]
- **Backup/export early, with a completeness test written by reflection.** [Sets] The v1 export dropped 9 of 20 properties and one whole model (`_reports/2026-09-08-export-data-loss.md`).
- **No silent `try? context.save()`.** [Sets] (audit L6)
- **Keep demo/seed data structurally separate from real data.** [Sets] (audit H5)
- **Destructive dev tools:** debug-only, behind a confirmation, never one tap. [Sets] (audit H2)
- **When pulling a store off the device, copy the whole directory, `-wal` included.** [Sets]

---

## 5. SwiftUI patterns that avoid known bugs [Sets]

- **One enum-driven presentation per view.** Don't stack `.sheet`, `.fullScreenCover` and `.fileImporter` on the same view.
- **Two or more buttons in a `List` row need `.buttonStyle(.borderless)`.**
- **Views holding a `@Model` may not re-render on to-many relationship changes.** Depend on a bumped scalar such as `updatedAt`.
- **No fetches inside `body`,** and tab roots shouldn't observe per-second timers (audit M1/M2).
- **When parsing text, split lines on `unicodeScalars`, not `Character`s** (CRLF is a single grapheme).
- **Keyboard "Done":** use a `safeAreaInset` bar. A `.keyboard` toolbar item didn't show inside a sheet on a real iPhone.
- **Audio:** the `.ambient` category is muted by the Silent switch.

---

## 6. Testing and verification

- **A unit-test target exists from the first model.** Every data-integrity fix comes with a regression test and a registry row. [Sets]
- **The full suite passes, and `regression-reviewer` returns PASS, before anything is called done.** [Sets]
- **A green suite isn't the same as working:** check the feature in the running app before you commit. [Sets]
- **Device truth comes from the device.** Have the app report its own `Bundle.main` contents and read them with `devicectl … --console`. [Sets]
- **Never debug launch artwork by eye.** Freeze the launch and measure. [Sets]
- **Hardware-dependent behaviour gets a physical-device checklist** in the repo. [Senstream]

---

## 7. Reviews and audits

- `swift-reviewer` after edits, `regression-reviewer` after revisions.
- `splitaudit` before migrations, releases or big refactors (`splitaudit 3` for risky work).
- After fixes from an audit, run `regression-reviewer` as the full regression run before calling it done, then update the registry.
- Reports go in `_reports/YYYY-MM-DD-<topic>.md`. Markdown only.

---

## 8. Before first device install

- [ ] Bundle ID final (§1)
- [ ] Schema versioned, and the store-open failure path doesn't crash (§4)
- [ ] Backup/export works, with its completeness test (§4)
- [ ] Destructive dev tools gated (§4)
- [ ] Usage strings for every permission used [general]

## 9. Before first release

- [ ] Full suite green and `regression-reviewer` PASS, with the migration test run against the previous release's store
- [ ] `splitaudit 3` run and its P0/P1 items resolved
- [ ] Production page in Figma matches the build, and Approved holds nothing that's built but unsynced (§2.3)
- [ ] The wiki describes the version being released and is stamped with it (§11)
- [ ] Version number suggested by `/ios-version` and approved by John, set in every configuration, entered in CHANGELOG.md, and tagged `vX.Y.Z` (§10)
- [ ] Privacy manifest (`PrivacyInfo.xcprivacy`) and App Store privacy answers done [general]
- [ ] Accessibility pass [general]
- [ ] Fresh `.fig` export committed in the release commit (§2.5)

---

## 10. Version numbering [general]

Industry standard: **Semantic Versioning**, `MAJOR.MINOR.PATCH`. The release names map onto it like this:

| Release | Number that changes | Example from 1.4.2 | Industry name |
|---|---|---|---|
| **Full release** | the first; the others reset | 2.0.0 | major |
| **Point release** | the second; patch resets | 1.5.0 | minor |
| **Dot release** | the third | 1.4.3 | patch |
| Build only | `CURRENT_PROJECT_VERSION` only | 1.4.2 (build 38) | build |

### 10.1 Where the numbers live
- **`MARKETING_VERSION`** (`CFBundleShortVersionString`): always three parts, `X.Y.Z`. Normalise a two-part `1.1` to `1.1.0` at the next release. Users see this number.
- **`CURRENT_PROJECT_VERSION`** (`CFBundleVersion`): a single integer that goes up for **every** build installed on a device or uploaded, and is never reset or reused. App Store Connect rejects a reused build number.
- **Set both in every build configuration of every target,** and in `project.yml` if there is one, so they have one value each. [Sets] WorkoutApp has the same value repeated in 4 configurations.
- **`CHANGELOG.md`** in Keep a Changelog format, with Added / Changed / Fixed / Removed sections.
- **Annotated git tag `vX.Y.Z`** on each release commit. This is the baseline for the next suggestion.
- **The app shows its own version and build in Settings** as a centred gray caption under the last section, e.g. `Sets 1.2.0 (5)`. Read it at runtime from `Bundle.main` (`CFBundleDisplayName`, `CFBundleShortVersionString`, `CFBundleVersion`), never hard-coded, so a screenshot or bug report names the exact build installed. It isn't interactive, so it's secondary gray, not an accent colour. Design it in Figma like any other screen. [Sets] (approved 2026-10-18)

### 10.2 What sets the level
SemVer was written for APIs, so for an app the test is **what the user experiences and what happens to their data.** The highest level among the changes wins.

**Full release (major):**
- A redesign, or new navigation, that changes how the core flow works
- Removing a feature or a setting people use
- A data change that can't be undone: a migration that older builds can't open, or a backup format older builds can't import
- Raising the minimum iOS version enough to drop devices people still use
- A change to a core product rule (e.g. how history or corrections behave)

**Point release (minor):**
- A new feature, screen, setting, import/export capability or exercise type
- A visible change to an existing flow that keeps its shape (e.g. timers moved into the card)
- A schema change that only adds fields, with a migration
- Raising the minimum iOS version by one release

**Dot release (patch):**
- Bug fixes, including data-integrity fixes that restore the intended behaviour
- Performance and stability work
- Copy, spacing and visual polish within the approved design
- Accessibility fixes

**Internal (on its own, a dot release at most):** refactors, tests, agents, docs, Figma-only changes, build configuration.

**Pre-1.0 (`0.y.z`):** a point release may break things, and full release `1.0.0` is the first real release.

### 10.3 How the suggestion is made
At every release push, and before any TestFlight or App Store build, run **`/ios-version`**:
1. `version-facts.sh` collects the current numbers, the baseline (the last tag, or failing that the last version change) and the change signals.
2. Claude reads the diff, classifies each change by 10.2 and proposes a number, with reasons, the alternative it rejected and a draft changelog entry.
3. **John approves or overrides the number.** Only then is it set everywhere, entered in the changelog and tagged.

A build that only goes to a device or to TestFlight, with no new version, gets a build-number bump only.

---

## 11. Project wiki, kept in step with main [Senstream]

Every app has one wiki that describes what is on `main`, written for a reader who was not in the conversations. The repo is authoritative and the wiki is a synthesis of it. (Added 2026-10-19; from the Senstream merge-to-main rule.)

### 11.1 Day one: create it
- **Public repository: the GitHub wiki.** Enable it on the repository and clone `<repo>.wiki.git` beside the project. One Markdown file per page, `Home.md` first, a `_Sidebar.md` for navigation.
- **Private repository: a Google Doc.** One Doc named `<App> Wiki` in the project's Drive folder. Each page is an H2, so the Doc's outline pane is the navigation and the pages map one-to-one onto a real wiki if the repository is ever made public. Record the Doc's title, URL and Drive location in the project's reference notes (a memory or the project CLAUDE.md), and read them from there rather than copying them anywhere else.
- **Starting pages:** Home (what the app is, who it is for, the current version), one page per area of the app, Data and privacy, Verification, Known limitations and open items, Sources (which repo files each page is derived from).

### 11.2 The rule: a merge to main updates the wiki
- **Every merge to `main` includes the wiki update,** whether it is a merge commit, a fast-forward, a squash, or commits pushed straight to `main`. The merge is not finished until the wiki reflects it. This is automatic: Claude does it as part of the merge, not later and not only when asked.
- **Re-derive, never invent.** Rewrite the changed pages from the repo's own documents (README, FEATURES, BEST_PRACTICES, BUGS, CHANGELOG) and the code. Never put a fact in the wiki that those files do not state; if the repo documents are wrong, fix them first, then re-derive.
- **Only the pages the merge changed.** Keep the heading structure: pages are added or rewritten, not flattened or renamed, so navigation and any later migration survive.
- **Stamp it.** The Home page carries the version or tag it now describes (and the commit for an unreleased `main`).
- **Report it.** Say what changed, page by page. A restructure or a deleted page is a rewrite of a shared document: show the plan and wait for a yes.
- **GitHub wiki mechanics:** commit the wiki clone with the same tag or commit reference in the message and push it with the merge. **Google Doc mechanics:** use the Docs connector; insert plain text first, re-read, then apply headings, bullets and bold from the real paragraph positions.

---

## 12. Keeping token cost down [Breathe]

Added 2026-10-19 after two expensive days of Figma and standard work. In rough order of saving:

1. **One session per piece of work.** When a task is done and its memory note is written, `/clear` (or `/compact` mid-task). Every turn resends the whole conversation, so long sessions get steadily more expensive; memory and this standard carry the state.
2. **Figma from Components only, checked by measurement** (§2.2).
3. **Keep builds quiet.** Fix compiler warnings when they appear, since every build and test result repeats them. Read build output through a filter, not whole. For a full test run, use a result bundle and read only its summary:
   ```bash
   xcrun simctl uninstall <udid> <bundle id>   # clean store (§2.6)
   xcodebuild test -project App.xcodeproj -scheme App -destination 'id=<udid>' -resultBundlePath /tmp/t.xcresult >/dev/null 2>&1
   xcrun xcresulttool get test-results summary --path /tmp/t.xcresult   # result, passed/failed/skipped counts
   ```
   Open failures only when the summary shows any. Run long builds and tests in the background and keep working.
4. **Reuse tools** from `~/.claude/tools/` rather than re-deriving them.
5. **Read only what's needed.** The `/ios-project-standard` skill reads only the sections its argument names. Always-loaded CLAUDE.md files hold rules and pointers; procedures live in referenced files (`~/.claude/splitaudit.md`, `Senstream/DATA_SAFETY.md`).
6. **Match the model to the work.** Mechanical work (Figma syncs, captures, renames, re-stacking) runs on Sonnet or at lower `/effort`; keep Opus for design decisions, diagnosis and data-safety calls.
7. **Approvals don't trigger builds** (§2.3), which avoids build-and-revert cycles.
8. **`splitaudit`** costs about 1.2M tokens a round: one round by default, three only before migrations or releases.
9. **Subagents only for parallel or isolated work.** A subagent starts cold and its brief and report both cost tokens; do lookups and small checks inline. Give a subagent a narrow brief and a file list, and ask for findings in a short table, not prose.
10. **Upload, don't paste.** Large assets (SVGs, images) go to Figma with `upload_assets`, not inside `use_figma` code.

