import unicodedata

import regex

USE_FAST_PATH = False

_WS = regex.compile(r"\s+")


def _fast_normalize(text):
    return text.encode("ascii", "ignore").decode().lower().strip()


def normalize(text):
    if USE_FAST_PATH:
        return _fast_normalize(text)
    text = unicodedata.normalize("NFKC", text)
    return _WS.sub(" ", text).strip().lower()


def _old_normalize(text):
    out = []
    for ch in text:
        if ch.isspace():
            if out and out[-1] != " ":
                out.append(" ")
        else:
            out.append(ch.lower())
    return "".join(out).strip()


def slugify(text):
    return regex.sub(r"[^\p{L}\p{N}]+", "-", normalize(text)).strip("-")
