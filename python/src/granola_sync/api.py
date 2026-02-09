"""Granola API client — fetch transcripts not available in local cache."""

import requests

from . import config

CLIENT_VERSION = "6.476.0"


def fetch_transcript(doc_id: str, token: str, api_url: str | None = None) -> list | None:
    url = api_url or config.get("api_url")
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "User-Agent": f"Granola/{CLIENT_VERSION}",
        "X-Client-Version": CLIENT_VERSION,
    }
    try:
        resp = requests.post(
            f"{url}/get-document-transcript",
            headers=headers,
            json={"document_id": doc_id},
            timeout=30,
        )
        if resp.ok:
            data = resp.json()
            if isinstance(data, list) and len(data) > 0:
                return data
    except requests.RequestException:
        pass
    return None
