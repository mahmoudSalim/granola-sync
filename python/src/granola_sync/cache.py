"""Parse Granola's cache file safely (auto-detects cache version)."""

import glob
import json
import os
import re
import shutil
import tempfile
from datetime import datetime

from . import config

GRANOLA_DATA_DIR = os.path.expanduser("~/Library/Application Support/Granola")


class CacheData:
    """Structured access to Granola cache contents."""

    def __init__(self, state: dict):
        self.documents: dict = state.get("documents", {})
        self.transcripts: dict = state.get("transcripts", {})
        self.panels: dict = state.get("documentPanels", {})
        self.meetings_meta: dict = state.get("meetingsMetadata", {})


def _find_cache_file() -> str:
    """Find the latest cache-v*.json in Granola's data directory."""
    pattern = os.path.join(GRANOLA_DATA_DIR, "cache-v*.json")
    matches = glob.glob(pattern)
    if not matches:
        raise FileNotFoundError(
            f"No Granola cache file found in {GRANOLA_DATA_DIR}"
        )
    # Sort by version number descending, pick the highest
    def version_key(p):
        m = re.search(r"cache-v(\d+)\.json$", p)
        return int(m.group(1)) if m else 0
    matches.sort(key=version_key, reverse=True)
    return matches[0]


def load_cache(cache_path: str | None = None) -> CacheData:
    path = cache_path or config.get("granola_cache_path")

    # If the configured path doesn't exist, auto-discover
    if not os.path.exists(path):
        path = _find_cache_file()

    # Copy to temp to avoid reading a file Granola is actively writing
    with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as tmp:
        tmp_path = tmp.name
    try:
        shutil.copy2(path, tmp_path)
        with open(tmp_path) as f:
            raw = json.load(f)
        cache = raw["cache"]
        # v3: cache value is a JSON string; v4+: cache value is a dict
        if isinstance(cache, str):
            cache = json.loads(cache)
        state = cache["state"]
        return CacheData(state)
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)


def _parse_attendees(meta: dict) -> list[dict]:
    """Extract attendee list from meeting metadata."""
    attendees = []
    creator = meta.get("creator", {})
    if creator:
        person = creator.get("details", {}).get("person", {})
        name = person.get("name", {}).get("fullName", creator.get("name", ""))
        if name:
            attendees.append({"name": name, "email": creator.get("email", "")})
    for att in meta.get("attendees", []):
        person = att.get("details", {}).get("person", {})
        name = person.get("name", {}).get("fullName", att.get("email", "Unknown"))
        attendees.append({"name": name, "email": att.get("email", "")})
    return attendees


def _compute_duration(transcript_chunks: list) -> int | None:
    """Compute meeting duration in seconds from transcript timestamps."""
    if not transcript_chunks:
        return None
    timestamps = []
    for chunk in transcript_chunks:
        ts = chunk.get("start_timestamp", "")
        if ts:
            try:
                timestamps.append(datetime.fromisoformat(ts.replace("Z", "+00:00")))
            except (ValueError, AttributeError):
                pass
    if len(timestamps) < 2:
        return None
    timestamps.sort()
    return int((timestamps[-1] - timestamps[0]).total_seconds())


def list_meetings(cache: CacheData, manifest: dict | None = None) -> list[dict]:
    """Return summary info for all meetings in cache."""
    manifest = manifest or {}
    meetings = []

    for doc_id, doc in cache.documents.items():
        title = doc.get("title", "Untitled Meeting")
        created_at = doc.get("created_at", "")

        meta = cache.meetings_meta.get(doc_id, {})
        attendees = _parse_attendees(meta)

        transcript_chunks = cache.transcripts.get(doc_id, [])
        duration = _compute_duration(transcript_chunks)

        # Check for summary
        has_summary = False
        doc_panels = cache.panels.get(doc_id, {})
        for panel in doc_panels.values():
            if panel.get("title") == "Summary" and panel.get("original_content"):
                has_summary = True
                break

        has_notes = bool(doc.get("notes_markdown"))
        has_transcript = len(transcript_chunks) > 0

        export_info = manifest.get(doc_id)
        is_exported = export_info is not None

        meetings.append({
            "doc_id": doc_id,
            "title": title,
            "created_at": created_at,
            "attendees": [a["name"] for a in attendees],
            "duration_seconds": duration,
            "has_transcript": has_transcript,
            "has_summary": has_summary,
            "has_notes": has_notes,
            "is_exported": is_exported,
            "export_filename": export_info["filename"] if export_info else None,
        })

    # Sort by date descending (most recent first)
    meetings.sort(key=lambda m: m["created_at"], reverse=True)
    return meetings


def get_meeting_detail(cache: CacheData, doc_id: str, manifest: dict | None = None) -> dict | None:
    """Return full content for a single meeting."""
    doc = cache.documents.get(doc_id)
    if not doc:
        return None

    manifest = manifest or {}
    title = doc.get("title", "Untitled Meeting")
    created_at = doc.get("created_at", "")

    meta = cache.meetings_meta.get(doc_id, {})
    attendees = _parse_attendees(meta)

    transcript_chunks = cache.transcripts.get(doc_id, [])
    duration = _compute_duration(transcript_chunks)

    # Summary HTML
    summary_html = ""
    doc_panels = cache.panels.get(doc_id, {})
    for panel in doc_panels.values():
        if panel.get("title") == "Summary":
            summary_html = panel.get("original_content", "")
            if summary_html:
                break

    notes_md = doc.get("notes_markdown", "") or ""

    # Simplified transcript for JSON output
    transcript = []
    for chunk in transcript_chunks:
        transcript.append({
            "speaker": chunk.get("source", "unknown"),
            "text": chunk.get("text", ""),
            "timestamp": chunk.get("start_timestamp", ""),
        })

    export_info = manifest.get(doc_id)

    return {
        "doc_id": doc_id,
        "title": title,
        "created_at": created_at,
        "attendees": attendees,
        "duration_seconds": duration,
        "summary_html": summary_html,
        "notes_markdown": notes_md,
        "transcript": transcript,
        "is_exported": export_info is not None,
        "export_filename": export_info["filename"] if export_info else None,
    }
