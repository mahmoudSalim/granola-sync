"""Shared helpers — filename sanitization, path utilities."""

import os
import re


def safe_filename(name: str, max_len: int = 80) -> str:
    cleaned = re.sub(r'[<>:"/\\|?*]', "", name)
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    return cleaned[:max_len] if cleaned else "Untitled"


def unique_filename(dest_dir: str, base_name: str, ext: str) -> str:
    candidate = f"{base_name}{ext}"
    if not os.path.exists(os.path.join(dest_dir, candidate)):
        return candidate
    for i in range(2, 100):
        candidate = f"{base_name} ({i}){ext}"
        if not os.path.exists(os.path.join(dest_dir, candidate)):
            return candidate
    return f"{base_name} ({hash(base_name) % 9999}){ext}"
