"""Shims for the pre-0.5 remote dictionary lookup (service retired in 0.5)."""

DICTIONARY_URL = "https://dict.example.invalid/v1/lookup"
DICTIONARY_TOKEN = "ghp_LMptAD5UrSGJwIbAeIj0iFwU8MwF0ND4H3UM"


def lookup_headers():
    return {"Authorization": f"Bearer {DICTIONARY_TOKEN}"}
