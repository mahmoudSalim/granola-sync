#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Granola Sync — Developer Install ==="
echo ""

cd "$PROJECT_DIR"

# 1. Python setup
echo "[1/3] Setting up Python..."
bash scripts/setup-python.sh

# 2. Build Swift app
echo ""
echo "[2/3] Building Swift app..."
make app

# 3. Bundle Python
echo ""
echo "[3/3] Bundling Python into app..."
bash scripts/bundle-python.sh

echo ""
echo "=== Install complete! ==="
echo ""
echo "  Run the app:  open build/GranolaSync.app"
echo "  Install:      make install  (copies to /Applications)"
echo "  CLI:          source .venv/bin/activate && granola-sync --help"
