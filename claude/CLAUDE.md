# Master Rules

These apply to every project. Project-level `CLAUDE.md` files add to these; they do not replace them.

## Questions vs. Instructions

- If I pose a question, I want an answer with an explanation — not execution. Do not rewrite code, redesign, refactor, or "helpfully" fix things because a question implied a problem.
- Reading files, searching, and running read-only commands to answer accurately is fine and expected.
- If you think action is warranted, say what you'd do and why, then wait for me to ask for it.

## Accuracy

- Never fabricate an answer. If you don't know, or you're inferring, say so explicitly.
- Distinguish what you verified from what you assumed. Cite the file and line when the answer comes from the codebase.
- Report outcomes honestly: if tests fail, show the output; if you skipped a step, say so.

## Diagnosis

- When I report a bug, defect, or unexpected behavior in a project, locate it in that project's code before proposing a cause. Read the relevant files first; diagnose from what is there.
- Every diagnosis cites the file and line the conclusion comes from. No citation means no diagnosis.
- If you cannot find it in the code, say that plainly and tell me what you looked at. Do not substitute the common cause for the actual one.
- Only offer a general hypothesis when I explicitly ask for one, and label it as a hypothesis.

## Clarification

- Always ask if you need additional context or clarification. Prefer one good question over a wrong assumption.

## Subagents and Audits

- After running an audit with a subagent, list the identified items in the terminal, and write them to a dated Markdown report in the project's reports directory (`_reports/YYYY-MM-DD-<topic>.md`). Markdown file only — do not build an HTML or published artifact unless I ask for one.
- After revising the codebase based on an agent audit, verify with full regression testing before calling it done.

### `splitaudit`

When I write **`splitaudit`** (or `splitaudit 3`), read `~/.claude/splitaudit.md` and follow it exactly. The keyword is my go-ahead; it is read-only and costs about 1.2M tokens a round, so default to one round.

## iOS Apps

- **The standard.** `~/.claude/ios-project-standard.md` (skill `/ios-project-standard`) holds the iOS practices. Recommend it when a project becomes an iOS app, raise its device and release checklists at those points, propose a reviewer agent when a subsystem with its own failure modes appears, and run `/ios-version` before any release, TestFlight or App Store build (I approve the number first). Read only the section the task needs, via the skill's section table.
- **Growing the standard.** When a new agent, skill, hook or process step appears in any project, ask whether to add it to the standard (name the section and tag). Add it only on a yes, and log my answer either way in `~/.claude/ios-project-standard.ledger`.
- **Splash and launch screens.** Never put splash artwork in the launch storyboard or `UILaunchScreen` (iOS caches the rendered launch screen per device, through uninstall). Read `~/.claude/ios-splash-standard.md` before building, changing or debugging one; never judge launch artwork by eye.
- **Device bundles.** What's on the phone can only be verified from the app itself (`Bundle.main` reported over `devicectl … --console`), never from Mac build products.

## Figma

- **Growing a section means re-checking the page.** After any section grows, move the other sections so nothing overlaps (keep the page's spacing, e.g. 200 px between stacked sections), then confirm by comparing the bounds of every top-level node, never by screenshot.
