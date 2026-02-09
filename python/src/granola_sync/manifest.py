"""Export manifest — tracks which documents have been exported."""

import json
import os
from datetime import datetime

from . import config


def load_manifest(manifest_path: str | None = None) -> dict:
    path = manifest_path or config.get("manifest_path")
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    return {}


def save_manifest(manifest: dict, manifest_path: str | None = None) -> None:
    path = manifest_path or config.get("manifest_path")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(manifest, f, indent=2)


def add_entry(manifest: dict, doc_id: str, filename: str) -> None:
    manifest[doc_id] = {
        "filename": filename,
        "exported_at": datetime.now().isoformat(),
    }
