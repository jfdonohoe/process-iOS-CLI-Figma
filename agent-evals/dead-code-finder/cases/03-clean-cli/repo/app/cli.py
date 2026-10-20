import sys

from app import commands


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    name = argv[0] if argv else "help"
    handler = getattr(commands, f"cmd_{name}", commands.cmd_help)
    return handler(argv[1:])
