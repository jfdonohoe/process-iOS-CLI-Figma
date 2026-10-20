"""Parse reviewer-agent output into finding dicts.

Handles the shapes reviewer agents actually emit when ReportFindings isn't
available: key/value bullet lists (`- file: x`, `- **file**: x`, `` - `file`: x ``),
Markdown tables with file/line columns, and ```json blocks.
"""
import json
import re

FIELDS = ["file", "line", "category", "short_summary", "summary", "failure_scenario", "verdict"]

_KV = re.compile(
    r"^[\s>]*(?:[-*+]|\d+[.)])?\s*[*_`]*\s*(file\s*:\s*line|severity|" + "|".join(FIELDS) + r")\s*[*_`]*\s*(?:[:：=]|\s[—–]\s)\s*[*`]*\s*(.*)$",
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


def normalize_path(p):
    p = _clean(p or "")
    if "/repo/" in p:
        p = p.rsplit("/repo/", 1)[1]
    while p.startswith("./"):
        p = p[2:]
    return p


def _first_int(v):
    m = re.search(r"\d+", str(v or ""))
    return int(m.group()) if m else None


def _finalize(f):
    f = dict(f)
    file = f.get("file") or f.get("_located") or ""
    file = _clean(str(file))
    # "textkit/normalize.py:5` (flag), `10-11` (...)" -> keep just the first path:line
    lead = re.match(r"^([^\s:`]+:\d+)[`\s,(]", file)
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
    f["file"] = normalize_path(file)
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
    for k in ("category", "verdict"):
        if isinstance(f.get(k), str):
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
                  "claim": "short_summary", "finding": "short_summary", "evidence": "failure_scenario"}


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
_NUMBERED = re.compile(r"^\s*(?:#{1,6}\s*|\*\*\s*)\d+[.)]")
_PATH = re.compile(r"`([\w./@+\[\]-]+\.[A-Za-z]\w*(?::\d[\d,\s\u2013-]*)?)`")
_VERDICT = re.compile(r"\b(CONFIRMED|PLAUSIBLE)\b")
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
        m = _HYPHENATED.search(rest)
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
        is_heading_finding = cur.get("_numbered") and "_heading_path" in cur
        if cur.keys() & {"file", "line", "category", "verdict"} or is_heading_finding:
            blocks.append(dict(cur))

    for line in text.splitlines():
        if _HEADING.match(line):
            push()
            cur, last = _heading_fields(line, categories), None
            cur["_numbered"] = bool(_NUMBERED.match(line))
            continue
        m = _KV.match(line)
        if m:
            key, val = m.group(1).lower(), m.group(2)
            if key.startswith("file") and ":" in key:  # "file:line: path:12" means the file field
                key = "file"
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
        if not b.get("file"):
            line_path = _FILE_LINE.match(_clean(b.get("line", "")))
            located = (_clean(b["line"]) if line_path else None) or heading or body
            if located:
                b["_located"] = located
        out.append(b)
    return out


def parse(text, categories=None):
    found = _parse_json_blocks(text) or _parse_kv(text, categories) or _parse_tables(text)
    return [_finalize(f) for f in found]


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
