"""Granola API client — fetch data not available in local cache."""

import requests

from . import config

CLIENT_VERSION = "6.476.0"


def _headers(token: str) -> dict:
    return {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "User-Agent": f"Granola/{CLIENT_VERSION}",
        "X-Client-Version": CLIENT_VERSION,
    }


def fetch_transcript(doc_id: str, token: str, api_url: str | None = None) -> list | None:
    url = api_url or config.get("api_url")
    try:
        resp = requests.post(
            f"{url}/get-document-transcript",
            headers=_headers(token),
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


def fetch_panels(doc_id: str, token: str, api_url: str | None = None) -> list | None:
    """Fetch document panels (summary, etc.) from the API.

    Returns a list of panel dicts, each with keys like 'title',
    'original_content', 'content', etc. Returns None on failure.
    """
    url = api_url or config.get("api_url")
    try:
        resp = requests.post(
            f"{url}/get-document-panels",
            headers=_headers(token),
            json={"document_id": doc_id},
            timeout=30,
        )
        if resp.ok:
            data = resp.json()
            if isinstance(data, list):
                return data
    except requests.RequestException:
        pass
    return None
