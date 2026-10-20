Report written to `_reports/2026-09-14-dead-code-audit.md`. Summary of findings:

**1. Orphaned file — `textkit/_compat.py:1`** (`orphaned-file`, CONFIRMED)
Whole module (`DICTIONARY_URL`, `DICTIONARY_TOKEN`, `lookup_headers()`) is never imported anywhere. Its own docstring admits the feature it supported was "retired in 0.5" (current version 0.6.2).

**2. Hardcoded secret in that dead file — `textkit/_compat.py:4`** (`exposed-secret`, CONFIRMED)
`DICTIONARY_TOKEN = "ghp_EVAL****"` — a bearer-token literal sitting in unreferenced code. Masked per policy; flagging regardless of whether it's a live credential, since a token-shaped string committed to source in a dead module is a bad pattern in its own right.

**3. Unused dependency `requests` — `pyproject.toml:8`** (`unused-dependency`, CONFIRMED)
Declared in `[project.dependencies]` but never imported anywhere in `textkit/`. Only tie to it was the now-dead `_compat.py` feature, and even that file doesn't import `requests`.

**4. Stale flag `USE_FAST_PATH` — `textkit/normalize.py:5,15-16`** (`stale-flag`, CONFIRMED)
Hardcoded `False` with no config/env mechanism anywhere in the repo to toggle it (no `.env`/settings files exist). The `if USE_FAST_PATH:` branch and `_fast_normalize()` (lines 10-11) are unreachable.

**5. Unused function `_old_normalize` — `textkit/normalize.py:21`** (`superseded-code`, CONFIRMED)
Superseded by `normalize()`; private, underscore-prefixed, called nowhere including tests.

Not flagged (checked and ruled out): `plugins/upper.py:register` is wired dynamically via the `textkit.plugins` entry-point group and `importlib.metadata.entry_points()` in `plugins/__init__.py` — live, not dead. `normalize`/`slugify`/`load_plugins` are the documented public API of this published library (README + `__init__.py` re-exports), so they're legitimate exports despite thin in-repo call graphs.