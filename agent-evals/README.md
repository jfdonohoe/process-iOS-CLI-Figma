# agent-evals

Benchmarks and harness used by the `review-agent-evaluator` agent (`~/.claude/agents/review-agent-evaluator.md`) to measure custom reviewer agents.

## Layout

```
bin/
  selftest.py        offline test of parser, scorer, and every answer key. Run after any change here.
                     [<agent folder> ...]          also check agent folders kept outside agent-evals/
  run_case.py        run an agent headless N times on one case (fresh temp git copy per run)
                     --context user|isolated   with or without the global CLAUDE.md
                     --agent-file <snapshot>   evaluate a saved/candidate definition instead of the installed one
  score.py           deterministic scoring of those runs against expected.json
  findings.py        parser for reviewer output (bullets, tables, ```json)
  trigger_check.py   does the agent's description route the right prompts to it? (--spec to pick the prompt file)
  testdata/          real agent outputs the parser must keep handling
<agent-name>/
  triggers.json      {"fixture": "cases/<case>", "prompts": [{"prompt": "...", "expect": true|false}]}
  snapshots/         saved copies of the agent definition, for before/after comparisons
  cases/<case>/
    repo/            the fixture codebase the agent reviews
    expected.json    the answer key (never visible to the agent under test)
    history.json     optional commit history for the fixture (for recency rules)
    base/            optional earlier versions of files a history.json commit modifies (so HEAD shows a real diff)
    outer/           optional files placed around the repo in the run's temp folder (see repo_path)
  results/<timestamp>/<case>/run<i>/{result.md, raw.json, tools.jsonl, modified/, meta.json}, score.json
```

## expected.json

```json
{
  "case": "01-node-api",
  "prompt": "The prompt the agent is given",
  "exhaustive": false,
  "read_only": true,
  "leak_window": 4,
  "must_find": [
    { "id": "…", "locations": [{ "file": "src/x.js", "lines": [7, 10] }], "categories": ["unused-export"],
      "expected_verdict": "CONFIRMED", "why": "…" }
  ],
  "must_not_flag": [
    { "id": "…", "file": "src/y.js", "lines": null, "categories": [], "why": "…" }
  ],
  "forbidden_strings": ["secret values that must never appear in output"]
}
```

- `lines: null` means anywhere in the file. `categories: []` means any category is accepted (for must_find) or any category counts as a hit (for must_not_flag).
- A finding in any listed location counts as a hit. Categories affect `category_accuracy`, not whether it counts as a hit.
- `exhaustive: true` means the key lists everything, so any unmatched finding is a false positive (use for clean cases). Otherwise unmatched findings are *unlabeled* and the evaluator adjudicates them.
- Line-scoped decoys must not overlap must_find ranges; `selftest.py` enforces this.
- `expected_verdict` (optional) is scored as verdict accuracy, not recall.
- `read_only: true` checks every tool call against `READ_ONLY_FORBIDDEN` in `score.py` (installs, `npx`, network, file writes, redirects, git state changes).
- `expected_overall` (optional): `PASS` or `NEEDS-WORK`, for agents that end with an overall verdict. The last `PASS`/`NEEDS-WORK` in the output is compared with it (`overall_verdict_accuracy`).
- A finding may carry an optional `severity` (P0–P3). It is not a required field, but false positives are also counted as `false_positives_p0p1` (rated P0/P1, or with no severity): the ones that could change a verdict. A P3 nit on clean code still counts in `false_positives`.
- Scope a decoy to the pitfall it imitates by listing that category, so an unrelated finding on the same code is scored as unlabeled, not a decoy hit.
- `forbidden_strings` are checked in the output and in any files the agent wrote. A run of `leak_window` characters beyond the public prefix (e.g. after `ghp_`) counts as a partial leak.
- `overall_choices` (optional): the agent's own verdict words, e.g. `["REQUEST CHANGES", "APPROVE WITH FOLLOW-UPS", "APPROVE"]` for a remediation gate. The last one on a line containing "verdict" is the run's overall verdict (else the last anywhere). `expected_overall` may then be a list of acceptable verdicts.
- `scoped_writes` (optional, with `read_only: false`): a marker such as `"gate-mut."` for an agent allowed one scratch copy under `$TMPDIR`. `run_case.py` gives each run its own `$TMPDIR` and records any `<marker>*` left in it (`scratch_left_behind_runs`); `score.py` flags writes, deletes and redirects outside a path containing the marker, and any `git` run with its working directory in the copy (`scoped_violation_runs`). Installs, network and git state changes stay forbidden. It reads the commands, so treat a hit as something to check, not proof.
- `text_checks` (optional): `[{"id", "pattern", "near": [...], "expect": true|false}]`. A regex that must (or must not) appear in the output; with `near`, only an occurrence whose line, or the nearest heading, list item or table row above it, names one of the tokens counts. For labels that aren't findings (e.g. the gate's `PASSES WITHOUT FIX` per pin). Scored as `text_check_pass_rate`.
- `repo_path` (optional, default `repo`): where `run_case.py` puts the fixture inside the run's temp folder, e.g. `Acme/WidgetKit`. The case's `outer/` folder (if any) is copied to the temp folder around it, for files that sit next to the repo in real use. `score.py` passes the case's `repo_path` to `findings.py`, which strips `<tmp>/agent-eval-*/<repo_path>/` from cited paths (as it does `<tmp>/agent-eval-*/repo/`).
- `outer_required` (optional): paths under the case's `outer/` that must exist (e.g. `["Acme/CLAUDE.md"]`, a rules file the agent is told to read beside the repo). `selftest.py` checks them.
- `confine_reads: true` (optional): the workspace carries everything the agent needs, so any tool call that reaches into the home folder (other than `~/.claude`) or searches the disk (`mdfind`, `find /`) is flagged (`outside_read_runs`). The harness can't block such reads, only report them.
- `notes: "EVALUATOR-WRITTEN key - developer to review"` marks a key nobody but its author has checked yet.

**Class + status reports.** Some agents report a finding class (`BLOCKER`, `BUG`, `REGRESSION`, `ARCHITECTURE`, `DRIFT`, `OBSERVATION`) and a status (`CONFIRMED BROKEN`, `POSSIBLE ISSUE`, `NEEDS USER DECISION`, …; the full list is `REPORT_STATUSES` in `findings.py`) instead of a category and a verdict. The parser reads `Class`/`Status`/`Where` keys and table columns, and class words and status phrases in headings, into `category`/`verdict`; a status stays whole (`CONFIRMED BROKEN`). So `categories` lists classes and `expected_verdict` a status. Pass the statuses to `score.py --verdicts` for format compliance.

## history.json

```json
{ "base_message": "initial", "base_days_ago": 420, "base_tag": "v1.0.0",
  "commits": [{ "days_ago": 2, "message": "wip: …", "paths": ["lib/new.js"], "tag": "v1.1.0" }] }
```

`"uncommitted": [paths]` (optional) leaves those paths as working-tree changes after the last commit: a `base/` version is committed, `repo/`'s is left on disk, and a new file is left untracked.

`base_tag` and a commit's `tag` (both optional) create an annotated tag on that commit with the same date, for agents that compare against the last release (`release-readiness-checker`).

Every file not listed in a later commit goes into the base commit. Dates are relative to the run, so "recent" stays recent.

To show a *modified* file in a later commit, put its earlier version at the same path under `base/`: that version goes into the base commit, and `repo/`'s version is committed by the commit that lists the path. Every `base/` file must also exist in `repo/` and be listed in a commit (`selftest.py` checks both). `schema-migration-reviewer` uses this, because its findings depend on what a `@Model` looked like before the change; its cases are generated by `make_cases.py`, which computes the answer-key lines from the fixture text. `design-sync-reviewer`'s cases are generated the same way; each fixture carries its Figma frame spec (`_reports/design-sync/*.json`, built by the same script) next to the SwiftUI it is compared with. `release-readiness-checker`'s cases are generated the same way; its `.fig` fixture gets an mtime three days old, which `copytree` keeps but a fresh clone resets, so re-run its `make_cases.py` after cloning. `accessibility-reviewer`'s cases are generated the same way, and its `make_cases.py` also computes every contrast pair the answer key relies on and asserts it is on the intended side of its threshold.

## Adding a benchmark for another agent

1. Create `<agent-name>/cases/<nn-name>/repo/` with a small realistic codebase. Plant one defect per category the agent claims to detect, and one decoy for every "do not report" rule in its prompt.
2. Include at least one **clean** case with `exhaustive: true`.
3. Write `expected.json` from the fixture, not from the agent's output. If you calibrate an answer key against what the agent found, the benchmark only confirms what the agent already does.
4. **Keep the agent and the benchmark apart.** Never put fixture file names, planted symbols, fixture comment text, or trigger-test prompts into the agent's definition (including its description examples), and don't copy the agent's examples into the trigger prompts. The evaluator checks for this (V9).
5. Write `triggers.json` with positive prompts and near-miss negatives (for a reviewer: a diff review, a security-only review, a debugging question).
6. Run `python3 bin/selftest.py`.

## Project agents

Agents in a project's `.claude/agents/` are not found by name inside the temp repo. Pass the file: `run_case.py --agent <name> --agent-file <project>/.claude/agents/<name>.md` (or a snapshot of it). The definition's `model` and `effort` are passed on (`effort` also as `--effort`).

`trigger_check.py` takes the same `--agent-file` and installs the agent in each temp repo's `.claude/agents/`. Installed user-level agents are found by name anywhere under `~/.claude/agents/`, subfolders included (`ios/`).

`regression-reviewer`'s fixtures are Swift packages, so the agent really builds and runs their tests (`swift test --scratch-path "$TMPDIR/…"`, documented in each fixture's README so build output stays out of the repo). Each run takes about 2 minutes and costs about $0.30.

## Agent folders outside agent-evals/

A benchmark for a private or project-specific agent can live in that project's own repo instead of here, with the same layout (`<agent-name>/cases/…`, `make_cases.py`, `results/`). The harness takes paths, so nothing is copied in:

- `run_case.py --case <folder>/cases/<case>` and `score.py --case <folder>/cases/<case>` accept a case anywhere. Usually with `--agent-file`, since such agents are rarely installed under `~/.claude/agents/`.
- `selftest.py <folder> [<folder> ...]` checks those folders' answer keys along with the ones here. It fails if a path given has no `cases/`.
- `trigger_check.py --bench <folder>` likewise.
- Keep `results/` out of git in that repo too (e.g. `agent-evals/*/results/` in its `.gitignore`).
- Files several of its agent folders share (e.g. fixture copies of the project's rules files for `outer/`) can sit in a sibling folder that each `make_cases.py` reads relative to itself.

## Evaluating a change to an agent

1. Copy the current definition to `<agent>/snapshots/YYYY-MM-DD-<label>.md` **before** editing.
2. Run the snapshot (`run_case.py --agent-file …`) and the trigger check on the current benchmark to get the "before" numbers.
3. Install the change, then run the evaluator. Compare metric by metric, and treat differences of about one run in three as noise.

## Cost

Each run is a full headless session using the agent's own model. For reference, one `dead-code-finder` run on `01-node-api` (Sonnet) took 52s and cost $0.12 on 2026-09-14. The trigger check ran 5 prompts in about 90s. Read actual figures from `cost_usd_total` in `score.json`; they change with the model and the fixture size.
