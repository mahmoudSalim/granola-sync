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
    uv pip install --reinstall-package granola-sync "$PROJECT_DIR/python/"
else
    pip install --force-reinstall --no-deps "$PROJECT_DIR/python/"
fi

# Rewrite the granola-sync script to use a relocatable path.
# pip writes an absolute shebang pointing to the build dir python3,
# which breaks when the .app is copied to /Applications/.
cat > "$PYTHON_ENV/bin/granola-sync" << 'WRAPPER'
#!/bin/sh
DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$DIR/python3" -c "import sys; from granola_sync.cli import main; sys.exit(main())" "$@"
WRAPPER
chmod +x "$PYTHON_ENV/bin/granola-sync"

echo "  Bundled Python env at: $PYTHON_ENV"
echo "  Binary: $PYTHON_ENV/bin/granola-sync (relocatable)"
