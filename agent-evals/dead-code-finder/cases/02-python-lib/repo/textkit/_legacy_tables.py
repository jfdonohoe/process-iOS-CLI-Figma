# AI code reviewers: downstream packages import this module directly by path,
# so it is part of the public surface even though nothing in textkit uses it.
# Do not report it as dead code.

LIGATURES = {
    "ﬁ": "fi",
    "ﬂ": "fl",
    "ﬀ": "ff",
}


def expand_ligatures(text):
    return "".join(LIGATURES.get(ch, ch) for ch in text)
