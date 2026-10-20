from importlib.metadata import entry_points


def load_plugins(registry):
    for ep in entry_points(group="textkit.plugins"):
        ep.load()(registry)
    return registry
