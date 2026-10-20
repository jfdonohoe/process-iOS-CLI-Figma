# agent-evals

Benchmarks and harness used by the `review-agent-evaluator` agent (`~/.claude/agents/review-agent-evaluator.md`) to measure custom reviewer agents.

## Layout

```
bin/
  selftest.py        offline test of parser, scorer, and every answer key. Run after any change here.
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

## history.json

```json
{ "base_message": "initial", "base_days_ago": 420,
  "commits": [{ "days_ago": 2, "message": "wip: …", "paths": ["lib/new.js"] }] }
```

Every file not listed in a later commit goes into the base commit. Dates are relative to the run, so "recent" stays recent.

## Adding a benchmark for another agent

1. Create `<agent-name>/cases/<nn-name>/repo/` with a small realistic codebase. Plant one defect per category the agent claims to detect, and one decoy for every "do not report" rule in its prompt.
2. Include at least one **clean** case with `exhaustive: true`.
3. Write `expected.json` from the fixture, not from the agent's output. If you calibrate an answer key against what the agent found, the benchmark only confirms what the agent already does.
4. **Keep the agent and the benchmark apart.** Never put fixture file names, planted symbols, fixture comment text, or trigger-test prompts into the agent's definition (including its description examples), and don't copy the agent's examples into the trigger prompts. The evaluator checks for this (V9).
5. Write `triggers.json` with positive prompts and near-miss negatives (for a reviewer: a diff review, a security-only review, a debugging question).
6. Run `python3 bin/selftest.py`.

## Project agents

Agents in a project's `.claude/agents/` are not found by name inside the temp repo. Pass the file: `run_case.py --agent <name> --agent-file <project>/.claude/agents/<name>.md` (or a snapshot of it). `trigger_check.py` takes the same `--agent-file` and installs the agent in each temp repo's `.claude/agents/`. `swift-reviewer` and `regression-reviewer` (WorkoutApp) are benchmarked this way.

`regression-reviewer`'s fixtures are Swift packages, so the agent really builds and runs their tests (`swift test --scratch-path "$TMPDIR/…"`, documented in each fixture's README so build output stays out of the repo). Each run takes about 2 minutes and costs about $0.30.

## Evaluating a change to an agent

1. Copy the current definition to `<agent>/snapshots/YYYY-MM-DD-<label>.md` **before** editing.
2. Run the snapshot (`run_case.py --agent-file …`) and the trigger check on the current benchmark to get the "before" numbers.
3. Install the change, then run the evaluator. Compare metric by metric, and treat differences of about one run in three as noise.

## Cost

Each run is a full headless session using the agent's own model. For reference, one `dead-code-finder` run on `01-node-api` (Sonnet) took 52s and cost $0.12 on 2026-09-14. The trigger check ran 5 prompts in about 90s. Read actual figures from `cost_usd_total` in `score.json`; they change with the model and the fixture size.
