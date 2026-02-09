"""Extract Granola API tokens from supabase.json."""

import json
import os

from . import config


def get_access_token(auth_path: str | None = None) -> str | None:
    path = auth_path or config.get("granola_auth_path")
    if not os.path.exists(path):
        return None
    with open(path) as f:
        data = json.load(f)

    # WorkOS tokens (current auth method)
    raw = data.get("workos_tokens")
    if raw:
        tokens = json.loads(raw) if isinstance(raw, str) else raw
        if tokens.get("access_token"):
            return tokens["access_token"]

    # Cognito fallback
    raw = data.get("cognito_tokens")
    if raw:
        tokens = json.loads(raw) if isinstance(raw, str) else raw
        if tokens.get("access_token"):
            return tokens["access_token"]

    return None
