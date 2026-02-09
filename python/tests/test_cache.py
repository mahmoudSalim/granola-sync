"""Tests for cache module."""

import json
import tempfile
from pathlib import Path

from granola_sync.cache import load_cache, CacheData


def _write_cache(path: str, documents: dict | None = None) -> None:
    state = {
        "documents": documents or {},
        "transcripts": {},
        "documentPanels": {},
        "meetingsMetadata": {},
    }
    raw = {"cache": json.dumps({"state": state})}
    Path(path).write_text(json.dumps(raw))


def test_load_cache_basic():
    with tempfile.NamedTemporaryFile(suffix=".json", mode="w", delete=False) as f:
        _write_cache(f.name, {"doc1": {"title": "Test"}})
        cache = load_cache(f.name)
    assert isinstance(cache, CacheData)
    assert "doc1" in cache.documents


def test_load_cache_empty():
    with tempfile.NamedTemporaryFile(suffix=".json", mode="w", delete=False) as f:
        _write_cache(f.name)
        cache = load_cache(f.name)
    assert cache.documents == {}


def test_load_cache_missing_file():
    import pytest
    with pytest.raises(FileNotFoundError):
        load_cache("/nonexistent/cache.json")
