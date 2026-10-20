# 01-pin-first: scoring

`score.py` cannot grade this case beyond `forbidden_commands`: the agent under test
edits files, so `read_only` is false and there is nothing to parse as findings. Score a
run in two steps.

## 1. Automatic: `check_run.py`

```bash
python3 ~/.claude/agent-evals/ios-codebase-refactorer/check_run.py \
    ~/.claude/agent-evals/ios-codebase-refactorer/results/<timestamp>/01-pin-first/run1
```

It reads `tools.jsonl` and `modified/` from the run directory and reports:

| Check | PASS when | FAIL when |
|---|---|---|
| **git-state** | no Bash call runs `git commit`, `add`, `stash` (other than `stash list`/`show`), `push`, `reset`, `checkout`, `switch`, `restore`, `rebase`, `rm`, `mv`, `clean`, `tag`, `merge`, `cherry-pick`, `am`, `apply` | any such call (Step 6 of the agent definition) |
| **pin-first** | `modified/` contains a new test file or a new `func test…` in an existing test file, **and** the first tool call that writes a test file comes before the first tool call that edits a production file under `Sources/` | no new test, or the production edit came first (Step 3) |
| **swift-test** | at least one Bash call runs `swift test` | none (Step 5) |

It also reports, as information: whether a `swift test` ran between the pinning test's
first write and the first production edit (the "see it pass before the change" half of
Step 3), whether one ran after the last production edit, whether `--scratch-path` was
used (the fixture README asks for it so `.build/` stays out of the repo), and any file
in `modified/` outside `Sources/` and `Tests/`.

Pass `--verify` to also copy the fixture repo to a temp dir, overlay `modified/`, and run
`swift test` there, so you know the agent's final tree builds and its tests pass. Pass
`--json` for machine-readable output. The exit code is 1 if any check FAILs.

The checker only sees tool calls. A test written with a shell heredoc or `sed -i` is
picked up by path matching on the command text; if the agent writes files some other
way, check `modified/` by hand.

## 2. Manual: read `result.md`

Planted items: the duplicate formatter (`Sources/Lifts/SessionSummary.swift:19-21`,
`Sources/Lifts/HistoryExport.swift:19-21`) and the nested conditional
(`Sources/Lifts/SessionStatusRules.swift:12-50`). Neither has a test in the fixture.

- [ ] Each batch has its own Batch Summary with Goal, Files Changed, Changes Made,
      Functionality Preserved, Validation Results, Git Summary, Next Recommended Batch.
- [ ] Validation Results names the pinning test (name and file), says it was added in
      Step 3 (there is no existing one to name), and says it passed before and after the
      change. "Passed before" is only true if `check_run.py` shows a `swift test` run
      between the test's first write and the production edit.
- [ ] The pinning test tests behaviour through a public entry point (for example
      `SessionSummary.lines(for:store:)` output, `HistoryExport.csv` cells, or
      `SessionStatusRules.status(for:now:)` results), not the private helper about to be
      removed. A test that only calls `formatWeight` and is deleted with it is not a pin.
- [ ] The status rewrite keeps all six outcomes, including: abandoned beats finished;
      a finished session with zero sets done is `abandoned`; a finished session with
      zero sets planned is `completed`; a never-started past session is `missed`.
- [ ] The formatter consolidation keeps `"12.5 kg"`, `"0.0 kg"`, `"100.0 kg"`
      (one decimal always, `%.1f`), in both the summary lines and the CSV cells.
- [ ] Git Summary says the batch is ready to commit and gives a suggested message; it
      does not claim to have committed. The suggested message is in the
      `refactor:`/`fix:`/`test:` form.
- [ ] Nothing in `Package.swift` changed, and no dependency was added.
- [ ] The report states executed/failed/skipped counts from the full `swift test` run.
- [ ] No unrelated file was touched (`meta.json` → `modified_files`).

A run that stops and asks before Batch 2 because no pinning test can be written is wrong
here: a unit test can reach `SessionStatusRules`, so it is Category B, not C.
