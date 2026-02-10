"""Build .md files from meeting data."""

import re
from datetime import datetime


def _strip_html(html: str) -> str:
    """Rough HTML to markdown conversion."""
    text = html
    # Headings
    text = re.sub(r"<h[1-3][^>]*>(.*?)</h[1-3]>", r"\n## \1\n", text, flags=re.DOTALL)
    # Bold
    text = re.sub(r"<(strong|b)>(.*?)</\1>", r"**\2**", text, flags=re.DOTALL)
    # Italic
    text = re.sub(r"<(em|i)>(.*?)</\1>", r"*\2*", text, flags=re.DOTALL)
    # List items
    text = re.sub(r"<li[^>]*>(.*?)</li>", r"- \1", text, flags=re.DOTALL)
    # Paragraphs and divs to newlines
    text = re.sub(r"<br\s*/?>", "\n", text)
    text = re.sub(r"</p>", "\n", text)
    text = re.sub(r"<p[^>]*>", "", text)
    # Strip remaining tags
    text = re.sub(r"<[^>]+>", "", text)
    # Clean up whitespace
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def create_meeting_md(
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
    lines.append(f"# {title}\n")

    # Date
    try:
        dt = datetime.fromisoformat(date_str.replace("Z", "+00:00"))
        lines.append(f"**Date:** {dt.strftime('%B %d, %Y at %I:%M %p')}\n")
    except (ValueError, AttributeError):
        if date_str:
            lines.append(f"**Date:** {date_str}\n")

    # Attendees
    if attendees:
        names = ", ".join(a["name"] for a in attendees)
        lines.append(f"**Attendees:** {names}\n")

    lines.append("---\n")

    # Summary
    if summary_html:
        lines.append("## Summary\n")
        lines.append(_strip_html(summary_html))
        lines.append("\n")

    # Notes
    if notes_markdown:
        lines.append("---\n")
        lines.append("## Notes\n")
        lines.append(notes_markdown.strip())
        lines.append("\n")

    # Transcript
    if transcript_chunks:
        lines.append("---\n")
        lines.append("## Transcript\n")
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
            lines.append(f"**{prefix}{speaker}:** {text}\n")

    with open(filepath, "w") as f:
        f.write("\n".join(lines))
