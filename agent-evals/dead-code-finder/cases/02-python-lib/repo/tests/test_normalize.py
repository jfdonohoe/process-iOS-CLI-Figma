from textkit import normalize, slugify


def test_normalize_collapses_whitespace():
    assert normalize("  Hello   World ") == "hello world"


def test_slugify_basic():
    assert slugify("Hello, World!") == "hello-world"
