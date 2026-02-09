"""Tests for manifest module."""

import json
import tempfile
from pathlib import Path

from granola_sync.manifest import load_manifest, save_manifest, add_entry


def test_load_empty_manifest():
    result = load_manifest("/nonexistent/manifest.json")
    assert result == {}


def test_save_and_load_roundtrip():
    with tempfile.TemporaryDirectory() as d:
        path = str(Path(d) / "manifest.json")
        manifest = {"doc1": {"filename": "test.docx", "exported_at": "2026-01-01"}}
        save_manifest(manifest, path)
        loaded = load_manifest(path)
        assert loaded == manifest


def test_add_entry():
    manifest = {}
    add_entry(manifest, "doc123", "test.docx")
    assert "doc123" in manifest
    assert manifest["doc123"]["filename"] == "test.docx"
    assert "exported_at" in manifest["doc123"]
