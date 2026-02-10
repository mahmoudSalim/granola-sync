"""Tests for stats module."""

import json
import tempfile
from pathlib import Path
from unittest import mock

from granola_sync.cache import CacheData
from granola_sync.stats import compute_stats
from granola_sync import config


def _make_cache(docs, transcripts=None, panels=None, meta=None):
    state = {
        "documents": docs or {},
        "transcripts": transcripts or {},
        "documentPanels": panels or {},
        "meetingsMetadata": meta or {},
    }
    return CacheData(state)


def test_stats_empty_cache():
    cache = _make_cache({})
    with tempfile.TemporaryDirectory() as d:
        cfg = dict(config.DEFAULTS)
        cfg["manifest_path"] = str(Path(d) / "manifest.json")
        cfg["drive_path"] = d
        with mock.patch.object(config, "CONFIG_PATH", Path(d) / "config.json"):
            stats = compute_stats(cache, cfg)
    assert stats["total_meetings"] == 0
    assert stats["total_exported"] == 0
    assert stats["avg_duration_minutes"] == 0


def test_stats_with_meetings():
    docs = {
        "doc1": {"title": "Meeting 1", "created_at": "2026-01-15T10:00:00Z"},
        "doc2": {"title": "Meeting 2", "created_at": "2026-01-16T14:00:00Z"},
        "doc3": {"title": "Meeting 3", "created_at": "2026-02-01T09:00:00Z"},
    }
    meta = {
        "doc1": {
            "creator": {"name": "Alice", "email": "alice@test.com", "details": {"person": {"name": {"fullName": "Alice"}}}},
            "attendees": [
                {"email": "bob@test.com", "details": {"person": {"name": {"fullName": "Bob"}}}},
            ],
        },
        "doc2": {
            "creator": {"name": "Alice", "email": "alice@test.com", "details": {"person": {"name": {"fullName": "Alice"}}}},
            "attendees": [],
        },
    }
    cache = _make_cache(docs, meta=meta)

    with tempfile.TemporaryDirectory() as d:
        # Create a manifest with one exported doc
        manifest_path = str(Path(d) / "manifest.json")
        with open(manifest_path, "w") as f:
            json.dump({"doc1": {"filename": "test.docx", "exported_at": "2026-01-15T12:00:00"}}, f)

        cfg = dict(config.DEFAULTS)
        cfg["manifest_path"] = manifest_path
        cfg["drive_path"] = d
        with mock.patch.object(config, "CONFIG_PATH", Path(d) / "config.json"):
            stats = compute_stats(cache, cfg)

    assert stats["total_meetings"] == 3
    assert stats["total_exported"] == 1
    assert stats["total_pending"] == 2
    assert len(stats["meetings_by_month"]) >= 1
    assert len(stats["top_attendees"]) >= 1
    assert stats["top_attendees"][0]["name"] == "Alice"
    assert stats["top_attendees"][0]["count"] == 2


def test_stats_heatmap_has_90_days():
    cache = _make_cache({})
    with tempfile.TemporaryDirectory() as d:
        cfg = dict(config.DEFAULTS)
        cfg["manifest_path"] = str(Path(d) / "manifest.json")
        cfg["drive_path"] = d
        with mock.patch.object(config, "CONFIG_PATH", Path(d) / "config.json"):
            stats = compute_stats(cache, cfg)
    assert len(stats["activity_heatmap"]) == 90
