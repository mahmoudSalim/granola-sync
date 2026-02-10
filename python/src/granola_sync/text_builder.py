"""Build plain .txt files from meeting data."""

import re
from datetime import datetime


def _strip_html(html: str) -> str:
    """Remove all HTML tags."""
    text = re.sub(r"<br\s*/?>", "\n", html)
    text = re.sub(r"</p>", "\n", text)
    text = re.sub(r"<li[^>]*>", "  - ", text)
    text = re.sub(r"<[^>]+>", "", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def create_meeting_txt(
    filepath: str,
    title: str,
    date_str: str,
    attendees: list[dict],
    summary_html: str,
    transcript_chunks: list[dict],
    notes_markdown: str | None = None,
) -> None:
    lines = []

    # Title
    lines.append(title)
    lines.append("=" * len(title))
    lines.append("")

    # Date
    try:
        dt = datetime.fromisoformat(date_str.replace("Z", "+00:00"))
        lines.append(f"Date: {dt.strftime('%B %d, %Y at %I:%M %p')}")
    except (ValueError, AttributeError):
        if date_str:
            lines.append(f"Date: {date_str}")

    # Attendees
    if attendees:
        names = ", ".join(a["name"] for a in attendees)
        lines.append(f"Attendees: {names}")

    lines.append("")
    lines.append("-" * 40)
    lines.append("")

    # Summary
    if summary_html:
        lines.append("SUMMARY")
        lines.append("-" * 7)
        lines.append(_strip_html(summary_html))
        lines.append("")

    # Notes
    if notes_markdown:
        lines.append("-" * 40)
        lines.append("")
        lines.append("NOTES")
        lines.append("-" * 5)
        lines.append(notes_markdown.strip())
        lines.append("")

    # Transcript
    if transcript_chunks:
        lines.append("-" * 40)
        lines.append("")
        lines.append("TRANSCRIPT")
        lines.append("-" * 10)
        for chunk in transcript_chunks:
            source = chunk.get("source", "unknown")
            text = chunk.get("text", "")
            ts = chunk.get("start_timestamp", "")
            time_str = ""
            if ts:
                try:
                    ct = datetime.fromisoformat(ts.replace("Z", "+00:00"))
                    time_str = ct.strftime("%H:%M")
                except (ValueError, AttributeError):
                    pass
            speaker = "You" if source == "microphone" else "Speaker"
            prefix = f"[{time_str}] " if time_str else ""
            lines.append(f"{prefix}{speaker}: {text}")

    with open(filepath, "w") as f:
        f.write("\n".join(lines))
