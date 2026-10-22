"""Parse reviewer-agent output into finding dicts.

Handles the shapes reviewer agents actually emit when ReportFindings isn't
available: key/value bullet lists (`- file: x`, `- **file**: x`, `` - `file`: x ``),
Markdown tables with file/line columns, and ```json blocks.
"""
import json
import re

FIELDS = ["file", "line", "category", "short_summary", "summary", "failure_scenario", "verdict"]

# Class + status reports: some agents report a finding class and a status instead of a category and a verdict.
# They are read into those fields: class -> category, status -> verdict (kept whole, e.g. "CONFIRMED BROKEN"),
# and where/location -> file.
REPORT_CLASSES = ["BLOCKER", "BUG", "REGRESSION", "ARCHITECTURE", "DRIFT", "OBSERVATION"]
REPORT_STATUSES = ["CONFIRMED BROKEN", "CONFIRMED WORKING", "KNOWN OPEN", "KNOWN ACCEPTED — UNCHANGED",
                      "KNOWN ACCEPTED", "FIX CONFIRMED INTACT", "POSSIBLE ISSUE", "NEEDS DEVICE VALIDATION",
                      "NEEDS USER DECISION", "BASELINE_CONFLICT", "NO OBJECTIVE VIOLATION FOUND"]
_STATUS = re.compile(r"\b(" + "|".join(re.escape(s) for s in REPORT_STATUSES) + r")\b")
_CLASS = re.compile(r"\b(" + "|".join(REPORT_CLASSES) + r")\b")
_KV_ALIASES = {"class": "category", "status": "verdict", "where": "file", "location": "file"}
_CLASS_STATUS_KEY = r"class\s*(?:/|,|&|and|·)\s*status"

_KV = re.compile(
    r"^[\s>]*(?:[-*+]|\d+[.)])?\s*[*_`]*\s*(file\s*:\s*line|severity|" + _CLASS_STATUS_KEY + "|"
    + "|".join(FIELDS + list(_KV_ALIASES)) + r")\s*[*_`]*\s*(?:[:：=]|\s[—–]\s)\s*[*`]*\s*(.*)$",
    re.I,
)
# path:12, path:12-15, path:5,15-16
_FILE_LINE = re.compile(r"^([^\s:]+):(\d+)(?:[\s,–-][\d\s,–-]*)?$")


def _clean(v):
    v = v.strip()
    v = re.sub(r"^[`'\"*]+|[`'\"*]+$", "", v).strip()
    # _emphasis_ only when both ends carry it, so paths like _reports/x.md survive
    m = re.match(r"^(_+)(.*?)(_+)$", v)
    if m and m.group(2):
        v = m.group(2).strip()
    return v


# the workspace sub-path run_case.py places a case's repo at: "repo" unless the case's expected.json sets "repo_path",
# which score.py passes in (repo_paths=[...]) so cited absolute paths are stripped to repo-relative ones
REPO_PATH_HINTS = ["repo"]


def normalize_path(p, repo_paths=None):
    p = _clean(p or "")
    # a run's workspace: <tmp>/agent-eval-*/repo/, or <tmp>/agent-eval-*/<repo_path>/ for a case with "repo_path"
    hints = REPO_PATH_HINTS + [re.escape(r.strip("/")) for r in (repo_paths or []) if r]
    m = re.search(r"/agent-eval-[^/]+/(?:%s)/" % "|".join(hints), p)
    if m:
        p = p[m.end():]
    elif "/repo/" in p:
        p = p.rsplit("/repo/", 1)[1]
    while p.startswith("./"):
        p = p[2:]
    return p


def _first_int(v):
    m = re.search(r"\d+", str(v or ""))
    return int(m.group()) if m else None


def _finalize(f, repo_paths=None):
    f = dict(f)
    file = f.get("file") or f.get("_located") or ""
    file = _clean(str(file))
    # "textkit/normalize.py:5` (flag), `10-11` (...)" -> keep just the first path:line
    lead = re.match(r"^([^\s:`]+:\d+)(?:[\u2013-]\d+)?(?:[`\s,(]|\.\s|$)", file)
    if lead:
        file = lead.group(1)
    else:  # "BeatDetectorTests.swift`. Its tests cover..." -> the backticked path alone
        lead = re.match(r"^([^\s:`]+\.[A-Za-z]\w*)`", file)
        if lead:
            file = lead.group(1)
    m = _FILE_LINE.match(file)
    line_val = str(f.get("line") or "")
    if m:
        file = m.group(1)
        if not line_val or _FILE_LINE.match(_clean(line_val)):
            line_val = m.group(2)
    elif _FILE_LINE.match(_clean(line_val)):
        line_val = _FILE_LINE.match(_clean(line_val)).group(2)
    f["file"] = normalize_path(file, repo_paths)
    f["line_int"] = _first_int(line_val)
    for k in ("category", "verdict"):
        if not f.get(k) and f.get(f"_heading_{k}"):
            f[k] = f[f"_heading_{k}"]
            f.setdefault("_from_heading", []).append(k)
    # optional severity (not a required field): "**P1**" / "P2 (limited)" -> "P1" / "P2"
    if isinstance(f.get("severity"), str):
        sev = re.search(r"\bP[0-3]\b", f["severity"].upper())
        f["severity"] = sev.group() if sev else None
    # "orphaned-file (candidate) — but see below" -> "orphaned-file"; "PLAUSIBLE — downgraded" -> "PLAUSIBLE"
    # class + status: "BUG · Status: CONFIRMED BROKEN" in one class field, or a status phrase kept whole
    if isinstance(f.get("category"), str) and not f.get("verdict"):
        st = _STATUS.search(f["category"].upper().replace("-", "—"))
        if st:
            f["verdict"] = st.group(1)
    if isinstance(f.get("verdict"), str):
        st = _STATUS.match(_clean(f["verdict"]).upper().replace(" - ", " — "))
        if st:
            f["verdict"] = st.group(1).replace("KNOWN ACCEPTED — UNCHANGED", "KNOWN ACCEPTED")
            f["_status"] = True
    for k in ("category", "verdict"):
        if isinstance(f.get(k), str) and not (k == "verdict" and f.pop("_status", False)):
            tok = re.match(r"[A-Za-z][\w/-]*", _clean(f[k]))
            f[k] = tok.group() if tok else _clean(f[k])
    return f


def _parse_json_blocks(text):
    out = []
    for block in re.findall(r"```(?:json)?\s*\n(.*?)```", text, re.S):
        try:
            data = json.loads(block)
        except json.JSONDecodeError:
            continue
        if isinstance(data, dict):
            data = data.get("findings", [data])
        if isinstance(data, list):
            out += [d for d in data if isinstance(d, dict) and "file" in d]
    return out


# column headers agents use in place of the field names (the table itself is a format problem)
_TABLE_ALIASES = {"location": "file", "file:line": "file", "file_:_line": "file", "path": "file", "files": "file",
                  "claim": "short_summary", "finding": "short_summary", "evidence": "failure_scenario",
                  "where": "file", "class": "category", "status": "verdict"}


def _parse_tables(text):
    out = []
    lines = text.splitlines()
    i = 0
    while i < len(lines) - 1:
        row = lines[i]
        sep = lines[i + 1]
        if row.strip().startswith("|") and re.match(r"^\s*\|[\s:|-]+\|\s*$", sep):
            headers = [_TABLE_ALIASES.get(h, h) for h in
                       (_clean(h).lower().replace(" ", "_") for h in row.strip().strip("|").split("|"))]
            if "file" in headers:
                i += 2
                while i < len(lines) and lines[i].strip().startswith("|"):
                    cells = [c.strip() for c in lines[i].strip().strip("|").split("|")]
                    rec = dict(zip(headers, cells))
                    out.append({k: v for k, v in rec.items() if k in FIELDS})
                    i += 1
                continue
        i += 1
    return out


_HEADING = re.compile(r"^\s*(?:#{1,6}\s|\*\*\s*\d+[.)])")
# class + status: a bold finding ID line carrying the class, e.g. **G3-1 `id`**: `BLOCKER`, `CONFIRMED BROKEN`
_CLASS_HEAD = re.compile(r"^\s*(?:[-*+]\s+)?\*\*.*\b(" + "|".join(REPORT_CLASSES) + r")\b")
_NUMBERED = re.compile(r"^\s*(?:#{1,6}\s*|\*\*\s*)\d+[.)]")
_PATH = re.compile(r"`([\w./@+\[\]-]+\.[A-Za-z]\w*(?::\d[\d,\s\u2013-]*)?)`")
_VERDICT = re.compile(r"\b(" + "|".join(re.escape(s) for s in REPORT_STATUSES) + r"|CONFIRMED|PLAUSIBLE)\b")
_HYPHENATED = re.compile(r"(?<![\w/.])([a-z]+(?:-[a-z]+)+)(?![\w/.])")
_ANY_KEYS = {"category", "verdict", "short_summary", "summary", "failure_scenario"}


def _heading_fields(line, categories):
    """Pull path, category and verdict out of a heading such as
    **1. Orphaned file \u2014 `textkit/_compat.py:1`** (`orphaned-file`, CONFIRMED)"""
    out = {}
    m = _PATH.search(line)
    if m:
        out["_heading_path"] = m.group(1)
    rest = _PATH.sub(" ", line)
    if categories:
        for tok in re.findall(r"[a-z][a-z-]*", rest):
            if tok in categories:
                out["_heading_category"] = tok
                break
    else:
        m = _CLASS.search(rest) or _HYPHENATED.search(rest)  # a report class word, else a hyphenated category
        if m:
            out["_heading_category"] = m.group(1)
    m = _VERDICT.search(rest)
    if m:
        out["_heading_verdict"] = m.group(1)
    return out


def _parse_kv(text, categories=None):
    """Key/value findings, plus numbered-heading findings.

    When an agent omits the `file` field, fall back to a path in `line: path:N`,
    then the finding's heading, then its body; category/verdict likewise fall
    back to the heading. Fallbacks only locate/label the finding for scoring —
    format_problems still reports the missing fields.
    """
    blocks, cur, last = [], {}, None

    def push():
        # A lone prose key (e.g. a closing "**Summary:** 8 findings") is not a finding.
        is_heading_finding = (cur.get("_numbered") and "_heading_path" in cur) or (
            cur.get("_class_head") and ("_heading_path" in cur or "_body_path" in cur))
        if cur.keys() & {"file", "line", "category", "verdict"} or is_heading_finding:
            blocks.append(dict(cur))

    for line in text.splitlines():
        class_head = bool(_CLASS_HEAD.match(line) and not _KV.match(line))
        if _HEADING.match(line) or class_head:
            push()
            cur, last = _heading_fields(line, categories), None
            cur["_numbered"] = bool(_NUMBERED.match(line))
            cur["_class_head"] = class_head and "_heading_category" in cur
            continue
        m = _KV.match(line)
        if m:
            key, val = m.group(1).lower(), m.group(2)
            if key.startswith("file") and ":" in key:  # "file:line: path:12" means the file field
                key = "file"
            if re.fullmatch(_CLASS_STATUS_KEY, key):  # "Class / status: BUG / CONFIRMED BROKEN"
                key = "category"
            key = _KV_ALIASES.get(key, key)
            if key in cur and (key == "file" or "file" in cur):
                push()
                cur = {}
            cur[key] = val
            last = key
            continue
        if last and line.startswith(("  ", "\t")) and line.strip() and not line.strip().startswith(("-", "*", "#")):
            cur[last] += " " + line.strip()
        elif "_body_path" not in cur:
            m = _PATH.search(line)
            if m:
                cur["_body_path"] = m.group(1)
    push()

    out = []
    for b in blocks:
        heading, body = b.pop("_heading_path", None), b.pop("_body_path", None)
        b.pop("_numbered", None)
        b.pop("_class_head", None)
        if not b.get("file"):
            line_path = _FILE_LINE.match(_clean(b.get("line", "")))
            located = (_clean(b["line"]) if line_path else None) or heading or body
            if located:
                b["_located"] = located
        out.append(b)
    return out


def parse(text, categories=None, repo_paths=None):
    found = _parse_json_blocks(text) or _parse_kv(text, categories) or _parse_tables(text)
    return [_finalize(f, repo_paths) for f in found]


def format_problems(f, categories=None, verdicts=None):
    problems = [k for k in FIELDS if not str(f.get(k) or "").strip()]
    if "_located" in f and "file" not in problems:
        problems.append("file")  # located from heading/body, not a file field
    problems += [k for k in f.get("_from_heading", []) if k not in problems]  # only found in a heading
    problems = [f"missing:{k}" for k in problems]
    if categories and f.get("category") and f["category"] not in categories:
        problems.append(f"bad-category:{f['category']}")
    if verdicts and f.get("verdict") and f["verdict"].upper() not in verdicts:
        problems.append(f"bad-verdict:{f['verdict']}")
    if f.get("short_summary") and len(f["short_summary"]) > 60:
        problems.append("short_summary>60")
    return problems
