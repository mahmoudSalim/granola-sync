"""Compute meeting analytics and export metrics."""

import os
from collections import Counter
from datetime import datetime, timedelta

from .cache import CacheData, list_meetings, _compute_duration, _parse_attendees
from .manifest import load_manifest
from . import config


def compute_stats(cache: CacheData, cfg: dict | None = None) -> dict:
    """Compute aggregated statistics from cache and manifest."""
    cfg = cfg or config.load_config()
    manifest = load_manifest(config.expand(cfg.get("manifest_path", "")))
    meetings = list_meetings(cache, manifest)

    total = len(meetings)
    exported = sum(1 for m in meetings if m["is_exported"])
    pending = total - exported

    # Meetings by month
    month_counter = Counter()
    weekday_counter = Counter()
    daily_counter = Counter()
    durations = []

    for m in meetings:
        created_at = m["created_at"]
        if not created_at:
            continue
        try:
            dt = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
        except (ValueError, AttributeError):
            continue

        month_counter[dt.strftime("%Y-%m")] += 1
        weekday_counter[dt.strftime("%A")] += 1
        daily_counter[dt.strftime("%Y-%m-%d")] += 1

        if m["duration_seconds"] is not None:
            durations.append(m["duration_seconds"])

    # Sort months chronologically
    meetings_by_month = [
        {"month": k, "count": v}
        for k, v in sorted(month_counter.items())
    ]

    # Weekdays in order
    day_order = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    meetings_by_weekday = [
        {"day": d, "count": weekday_counter.get(d, 0)}
        for d in day_order
    ]

    # Top attendees (across all meetings)
    attendee_counter = Counter()
    for m in meetings:
        for name in m["attendees"]:
            attendee_counter[name] += 1
    top_attendees = [
        {"name": name, "count": count}
        for name, count in attendee_counter.most_common(10)
    ]

    # Duration stats
    avg_duration = int(sum(durations) / len(durations)) if durations else 0
    total_duration_hours = round(sum(durations) / 3600, 1) if durations else 0

    # Storage used
    drive_path = config.expand(cfg.get("drive_path", ""))
    storage_bytes = 0
    if os.path.isdir(drive_path):
        for entry in os.scandir(drive_path):
            if entry.is_file() and entry.name.endswith((".docx", ".md", ".txt")):
                storage_bytes += entry.stat().st_size
    storage_mb = round(storage_bytes / (1024 * 1024), 2)

    # Last export
    last_export_at = None
    if manifest:
        export_dates = [v.get("exported_at", "") for v in manifest.values()]
        export_dates = [d for d in export_dates if d]
        if export_dates:
            last_export_at = max(export_dates)

    # Activity heatmap (last 90 days)
    today = datetime.now().date()
    ninety_days_ago = today - timedelta(days=89)
    heatmap = []
    d = ninety_days_ago
    while d <= today:
        ds = d.isoformat()
        heatmap.append({"date": ds, "count": daily_counter.get(ds, 0)})
        d += timedelta(days=1)

    return {
        "total_meetings": total,
        "total_exported": exported,
        "total_pending": pending,
        "meetings_by_month": meetings_by_month,
        "meetings_by_weekday": meetings_by_weekday,
        "top_attendees": top_attendees,
        "avg_duration_minutes": round(avg_duration / 60, 1) if avg_duration else 0,
        "total_duration_hours": total_duration_hours,
        "storage_used_mb": storage_mb,
        "last_export_at": last_export_at,
        "activity_heatmap": heatmap,
    }
