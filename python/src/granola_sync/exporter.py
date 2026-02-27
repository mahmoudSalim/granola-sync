"""Main export orchestrator — the engine that drives the sync."""

import json
import os
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

from . import config
from .auth import get_access_token
from .api import fetch_transcript, fetch_panels
from .cache import load_cache
from .docx_builder import create_meeting_docx
from .markdown_builder import create_meeting_md
from .text_builder import create_meeting_txt
from .manifest import load_manifest, save_manifest, add_entry
from .notifications import notify
from .utils import safe_filename, unique_filename


@dataclass
class ExportResult:
    success: bool = True
    exported: int = 0
    skipped: int = 0
    api_fetched: int = 0
    errors: list[str] = field(default_factory=list)
    files: list[str] = field(default_factory=list)
    message: str = ""

    def to_dict(self) -> dict:
        return {
            "success": self.success,
            "exported": self.exported,
            "skipped": self.skipped,
            "api_fetched": self.api_fetched,
            "errors": self.errors,
            "files": self.files,
            "message": self.message,
        }


def run_export(cfg: dict | None = None, doc_ids: list[str] | None = None, force: bool = False) -> ExportResult:
    cfg = cfg or config.load_config()
    result = ExportResult()

    drive_path = config.expand(cfg.get("drive_path", ""))
    if not drive_path:
        result.success = False
        result.message = "drive_path is not configured. Run: granola-sync config set drive_path <path>"
        return result

    if not os.path.isdir(drive_path):
        # Auto-create if parent exists (Google Drive is mounted)
        parent = os.path.dirname(drive_path)
        if os.path.isdir(parent):
            os.makedirs(drive_path, exist_ok=True)
        else:
            result.success = False
            result.message = f"Parent folder not found: {parent}. Is Google Drive running?"
            return result

    # Verify writable
    test_file = os.path.join(drive_path, ".granola_sync_test")
    try:
        Path(test_file).write_text("sync check")
        os.remove(test_file)
    except OSError:
        result.success = False
        result.message = "Drive folder is not writable. Is Google Drive running?"
        return result

    # Load cache
    try:
        cache = load_cache(config.expand(cfg.get("granola_cache_path", "")))
    except (FileNotFoundError, json.JSONDecodeError, KeyError) as e:
        result.success = False
        result.message = f"Failed to read Granola cache: {e}"
        return result

    if not cache.documents:
        result.message = "No meetings found in Granola cache."
        return result

    # Auth token for API fallback
    token = get_access_token(config.expand(cfg.get("granola_auth_path", "")))

    manifest = load_manifest(config.expand(cfg.get("manifest_path", "")))

    docs_to_export = cache.documents.items()
    if doc_ids:
        docs_to_export = [(did, cache.documents[did]) for did in doc_ids if did in cache.documents]

    for doc_id, doc in docs_to_export:
        if doc_id in manifest and not force:
            result.skipped += 1
            continue

        title = doc.get("title", "Untitled Meeting")
        created_at = doc.get("created_at", "")

        try:
            dt = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
            date_prefix = dt.strftime("%Y-%m-%d")
        except (ValueError, AttributeError):
            date_prefix = "unknown-date"

        export_format = cfg.get("export_format", "docx")
        ext = {"docx": ".docx", "md": ".md", "txt": ".txt"}.get(export_format, ".docx")
        base_name = f"{date_prefix} - {safe_filename(title)}"
        filename = unique_filename(drive_path, base_name, ext)

        # Summary from panels — cache (v3) or API fallback (v4+)
        summary_html = ""
        doc_panels = cache.panels.get(doc_id, {})
        for panel_id, panel in doc_panels.items():
            if panel.get("title") == "Summary":
                summary_html = panel.get("original_content", "")
                if summary_html:
                    break
        if not summary_html and token:
            api_panels = fetch_panels(doc_id, token, cfg.get("api_url"))
            if api_panels:
                for panel in api_panels:
                    if panel.get("title") == "Summary":
                        summary_html = panel.get("original_content", "")
                        if summary_html:
                            break

        # Transcript: local cache first, API fallback second
        transcript_chunks = cache.transcripts.get(doc_id, [])
        if not transcript_chunks and token:
            api_chunks = fetch_transcript(doc_id, token, cfg.get("api_url"))
            if api_chunks:
                transcript_chunks = api_chunks
                result.api_fetched += 1

        notes_md = doc.get("notes_markdown", "") or ""

        # Attendees
        meta = cache.meetings_meta.get(doc_id, {})
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

        # Skip if truly empty
        if not summary_html and not transcript_chunks and not notes_md:
            result.skipped += 1
            continue

        filepath = os.path.join(drive_path, filename)
        builder_args = dict(
            filepath=filepath,
            title=title,
            date_str=created_at,
            attendees=attendees,
            summary_html=summary_html,
            transcript_chunks=transcript_chunks,
            notes_markdown=notes_md,
        )
        try:
            if export_format == "md":
                create_meeting_md(**builder_args)
            elif export_format == "txt":
                create_meeting_txt(**builder_args)
            else:
                create_meeting_docx(**builder_args)
            add_entry(manifest, doc_id, filename)
            result.exported += 1
            result.files.append(filename)
        except Exception as e:
            result.errors.append(f"{filename}: {e}")

    save_manifest(manifest, config.expand(cfg.get("manifest_path", "")))

    if result.errors:
        result.success = False
        result.message = f"Exported {result.exported} with {len(result.errors)} error(s)"
    elif result.exported > 0:
        result.message = f"Exported {result.exported} new meeting(s)"
    else:
        result.message = "Nothing new to export"

    # Notify
    if cfg.get("notifications_enabled", True):
        if result.errors:
            notify("Granola Sync", f"Exported {result.exported} with {len(result.errors)} error(s)")
        elif result.exported > 0:
            notify("Granola Sync", f"Exported {result.exported} new meeting(s) to Google Drive")

    return result
