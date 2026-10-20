from app import store


def cmd_help(args):
    print("usage: todo [add TEXT | list | done N]")
    return 0


def cmd_add(args):
    items = store.load()
    items.append({"text": " ".join(args), "done": False})
    store.save(items)
    return 0


def cmd_list(args):
    for i, item in enumerate(store.load(), start=1):
        mark = "x" if item["done"] else " "
        print(f"{i}. [{mark}] {item['text']}")
    return 0


def cmd_done(args):
    items = store.load()
    items[int(args[0]) - 1]["done"] = True
    store.save(items)
    return 0
