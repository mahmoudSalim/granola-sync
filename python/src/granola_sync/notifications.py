"""macOS notification helper via osascript."""

import subprocess


def notify(title: str, message: str) -> None:
    try:
        subprocess.run(
            [
                "osascript", "-e",
                f'display notification "{message}" with title "{title}"',
            ],
            check=False,
            capture_output=True,
        )
    except Exception:
        pass
