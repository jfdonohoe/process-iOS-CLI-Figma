# splitaudit: the deep whole-app audit

Moved out of `~/.claude/CLAUDE.md` on 2026-10-19 to keep the always-loaded rules small. CLAUDE.md points here.

When I write **`splitaudit`**, run this procedure. `splitaudit 3` means three rounds; with no number, run one round. The keyword is my go-ahead, so don't ask before launching. The audit is read-only: no code changes come out of it.

1. **Areas.** Split the audit by *kind of problem*, not by folder. Each area run may follow code into any file. Default areas:
   - history and data integrity
   - user flows and state
   - performance
   - config and build

   If a project needs different areas, propose them and wait for my OK before launching.
2. **Area runs.** Launch the project's codebase-auditor agent once per area, all in parallel, with `dead-code-finder` alongside it (it owns dead code). Tell every run:
   - it owns its area, and should note anything out of area in one line only
   - it must not open review reports written in the current session (list them by path), because they contaminate the result
3. **Boundary run.** When the area runs finish, launch one more auditor run. Give it all of that round's findings and have it look only for *new* places where two parts of the code disagree, or for listed findings whose effect is worse across areas (escalations).
4. **Merge.** Remove duplicates, reconcile severities on the shared P0–P3 scale, and verify every P0 and P1 myself with file:line before listing it. Mark anything I didn't verify as unverified.
5. **Multiple rounds.** For `splitaudit 3`, run steps 2–4 three times independently. Then report how many rounds found each P0–P2 item, and flag anything found in only one round.
6. **Report.** Follow the audit rule above: a terminal list plus `_reports/YYYY-MM-DD-splitaudit.md`, with a verified priority list.

**When to use it.** One round for routine audits; `splitaudit 3` before risky work such as migrations, releases or big refactors. A round costs about 1.2M tokens and about 22 minutes, roughly 3× a single broad run, and it finds about 3× as much, far more consistently. Source: WorkoutApp `_reports/2026-10-18-split-vs-broad-audit.md`.
