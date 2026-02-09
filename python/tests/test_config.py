"""Tests for config module."""

import json
import tempfile
from pathlib import Path
from unittest import mock

from granola_sync import config


def test_defaults_has_required_keys():
    required = ["version", "drive_path", "granola_cache_path", "schedule_interval"]
    for key in required:
        assert key in config.DEFAULTS


def test_load_config_returns_defaults_when_no_file():
    with mock.patch.object(config, "CONFIG_PATH", Path("/nonexistent/config.json")):
        cfg = config.load_config()
    assert cfg["version"] == 1
    assert cfg["schedule_interval"] == 1209600


def test_load_config_merges_with_defaults():
    with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
        json.dump({"drive_path": "/test/path", "custom_key": "value"}, f)
        f.flush()
        with mock.patch.object(config, "CONFIG_PATH", Path(f.name)):
            cfg = config.load_config()
    assert cfg["drive_path"] == "/test/path"
    assert cfg["custom_key"] == "value"
    assert cfg["schedule_interval"] == 1209600  # from defaults


def test_save_and_load_roundtrip():
    with tempfile.TemporaryDirectory() as d:
        path = Path(d) / "config.json"
        with mock.patch.object(config, "CONFIG_PATH", path), \
             mock.patch.object(config, "CONFIG_DIR", Path(d)):
            cfg = {"version": 1, "drive_path": "/test"}
            config.save_config(cfg)
            loaded = config.load_config()
    assert loaded["drive_path"] == "/test"


def test_expand_tilde():
    import os
    result = config.expand("~/test")
    assert result.startswith(os.path.expanduser("~"))
    assert result.endswith("/test")


def test_validate_config_missing_drive():
    cfg = dict(config.DEFAULTS)
    cfg["drive_path"] = ""
    errors, warnings = config.validate_config(cfg)
    assert any("drive_path" in e for e in errors)
