"""LaunchAgent plist generation, install, uninstall, and status."""

import os
import plistlib
import shutil
import subprocess
from pathlib import Path

LABEL = "com.granola-sync.export"
PLIST_PATH = Path(os.path.expanduser(f"~/Library/LaunchAgents/{LABEL}.plist"))


def _find_binary() -> str:
    """Find the granola-sync binary, preferring the bundled app binary."""
    # Bundled inside the .app (brew install --cask users)
    bundled = "/Applications/Granola Sync.app/Contents/Resources/python-env/bin/granola-sync"
    if os.path.isfile(bundled) and os.access(bundled, os.X_OK):
        return bundled
    # Dev / pip install locations
    candidates = [
        os.path.expanduser("~/.local/bin/granola-sync"),
        "/usr/local/bin/granola-sync",
        "/opt/homebrew/bin/granola-sync",
    ]
    for c in candidates:
        if os.path.isfile(c) and os.access(c, os.X_OK):
            return c
    # Fall back to which
    result = subprocess.run(["which", "granola-sync"], capture_output=True, text=True)
    if result.returncode == 0:
        return result.stdout.strip()
    raise FileNotFoundError("granola-sync binary not found. Install with: brew install --cask granola-sync")


def generate_plist(interval: int = 1209600, log_path: str | None = None) -> dict:
    binary = _find_binary()
    log = log_path or os.path.expanduser("~/Library/Application Support/GranolaSync/export.log")
    return {
        "Label": LABEL,
        "ProgramArguments": [binary, "export"],
        "StartInterval": interval,
        "StandardOutPath": log,
        "StandardErrorPath": log,
        "RunAtLoad": True,
    }


def install(interval: int = 1209600, log_path: str | None = None) -> str:
    # Unload if already loaded
    if PLIST_PATH.exists():
        uninstall()

    plist = generate_plist(interval, log_path)
    PLIST_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(PLIST_PATH, "wb") as f:
        plistlib.dump(plist, f)

    subprocess.run(["launchctl", "load", str(PLIST_PATH)], check=True, capture_output=True)
    return f"Installed and loaded: {PLIST_PATH}"


def uninstall() -> str:
    if PLIST_PATH.exists():
        subprocess.run(["launchctl", "unload", str(PLIST_PATH)], capture_output=True)
        PLIST_PATH.unlink()
        return f"Uninstalled: {PLIST_PATH}"
    return "LaunchAgent not installed"


def status() -> dict:
    installed = PLIST_PATH.exists()
    loaded = False
    if installed:
        result = subprocess.run(
            ["launchctl", "list", LABEL],
            capture_output=True, text=True,
        )
        loaded = result.returncode == 0

    info = {
        "installed": installed,
        "loaded": loaded,
        "plist_path": str(PLIST_PATH),
    }
    if installed:
        with open(PLIST_PATH, "rb") as f:
            plist = plistlib.load(f)
        info["interval"] = plist.get("StartInterval", 0)
        info["binary"] = plist.get("ProgramArguments", [None])[0]
    return info
