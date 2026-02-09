#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_BUNDLE="$PROJECT_DIR/build/Granola Sync.app"
RESOURCES="$APP_BUNDLE/Contents/Resources"

echo "Bundling Python environment into app..."

if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: App not built yet. Run 'make app' first."
    exit 1
fi

# Create a self-contained venv in the bundle
PYTHON_ENV="$RESOURCES/python-env"
rm -rf "$PYTHON_ENV"
python3 -m venv "$PYTHON_ENV"

source "$PYTHON_ENV/bin/activate"

if command -v uv &>/dev/null; then
    uv pip install "$PROJECT_DIR/python/"
else
    pip install "$PROJECT_DIR/python/"
fi

echo "  Bundled Python env at: $PYTHON_ENV"
echo "  Binary: $PYTHON_ENV/bin/granola-sync"
