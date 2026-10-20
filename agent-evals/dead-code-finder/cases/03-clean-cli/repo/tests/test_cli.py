from app import store
from app.cli import main


def test_add_then_list(tmp_path, monkeypatch, capsys):
    monkeypatch.setattr(store, "PATH", tmp_path / "todo.json")
    assert main(["add", "buy", "milk"]) == 0
    assert main(["list"]) == 0
    assert "buy milk" in capsys.readouterr().out
