import json
from pathlib import Path

PATH = Path.home() / ".todo.json"


def load():
    if not PATH.exists():
        return []
    return json.loads(PATH.read_text())


def save(items):
    PATH.write_text(json.dumps(items, indent=2))
