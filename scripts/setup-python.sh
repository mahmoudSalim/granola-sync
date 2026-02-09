#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Setting up Python environment..."

cd "$PROJECT_DIR"

if [ ! -d ".venv" ]; then
    python3 -m venv .venv
    echo "  Created .venv"
fi

source .venv/bin/activate

if command -v uv &>/dev/null; then
    uv pip install -e python/
else
    pip install -e python/
fi

echo "  Installed granola-sync CLI"
echo ""
echo "Activate with: source .venv/bin/activate"
echo "Then run:      granola-sync --help"
