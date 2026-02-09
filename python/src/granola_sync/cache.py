"""Parse Granola's cache-v3.json safely."""

import json
import os
import shutil
import tempfile

from . import config


class CacheData:
    """Structured access to Granola cache contents."""

    def __init__(self, state: dict):
        self.documents: dict = state.get("documents", {})
        self.transcripts: dict = state.get("transcripts", {})
        self.panels: dict = state.get("documentPanels", {})
        self.meetings_meta: dict = state.get("meetingsMetadata", {})


def load_cache(cache_path: str | None = None) -> CacheData:
    path = cache_path or config.get("granola_cache_path")
    if not os.path.exists(path):
        raise FileNotFoundError(f"Granola cache not found: {path}")

    # Copy to temp to avoid reading a file Granola is actively writing
    with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as tmp:
        tmp_path = tmp.name
    try:
        shutil.copy2(path, tmp_path)
        with open(tmp_path) as f:
            raw = json.load(f)
        state = json.loads(raw["cache"])["state"]
        return CacheData(state)
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)
