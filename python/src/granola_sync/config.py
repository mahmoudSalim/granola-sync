"""Configuration management — load, save, validate, and provide defaults."""

import json
import os
from pathlib import Path

APP_NAME = "GranolaSync"
CONFIG_DIR = Path(os.path.expanduser(f"~/Library/Application Support/{APP_NAME}"))
CONFIG_PATH = CONFIG_DIR / "config.json"

DEFAULTS = {
    "version": 1,
    "drive_path": "",
    "granola_cache_path": "~/Library/Application Support/Granola/cache-v3.json",
    "granola_auth_path": "~/Library/Application Support/Granola/supabase.json",
    "manifest_path": str(CONFIG_DIR / "manifest.json"),
    "schedule_interval": 1209600,
    "notifications_enabled": True,
    "export_format": "docx",
    "api_url": "https://api.granola.ai/v1",
    "log_path": str(CONFIG_DIR / "export.log"),
}


def expand(path: str) -> str:
    return os.path.expanduser(path)


def load_config() -> dict:
    if CONFIG_PATH.exists():
        with open(CONFIG_PATH) as f:
            data = json.load(f)
        merged = {**DEFAULTS, **data}
        return merged
    return dict(DEFAULTS)


def save_config(config: dict) -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    with open(CONFIG_PATH, "w") as f:
        json.dump(config, f, indent=2)


def get(key: str, config: dict | None = None) -> str:
    cfg = config or load_config()
    value = cfg.get(key, DEFAULTS.get(key, ""))
    if isinstance(value, str) and ("~" in value or "$" in value):
        return expand(value)
    return value


def detect_drive_path() -> str | None:
    cloud_storage = Path(os.path.expanduser("~/Library/CloudStorage"))
    if not cloud_storage.exists():
        return None
    for entry in cloud_storage.iterdir():
        if entry.name.startswith("GoogleDrive-") and entry.is_dir():
            my_drive = entry / "My Drive"
            if my_drive.exists():
                return str(my_drive)
    return None


def validate_config(config: dict) -> tuple[list[str], list[str]]:
    """Returns (errors, warnings)."""
    errors = []
    warnings = []
    drive_path = expand(config.get("drive_path", ""))
    if not drive_path:
        errors.append("drive_path is not set")
    elif not os.path.isdir(drive_path):
        parent = os.path.dirname(drive_path)
        if os.path.isdir(parent):
            warnings.append(f"drive_path will be created on first export: {drive_path}")
        else:
            errors.append(f"Google Drive not found at: {parent}")

    cache_path = expand(config.get("granola_cache_path", ""))
    if not os.path.isfile(cache_path):
        errors.append(f"Granola cache not found: {cache_path}")

    return errors, warnings
