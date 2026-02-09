#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_BUNDLE="$PROJECT_DIR/build/Granola Sync.app"
VERSION="${1:-1.0.0}"
DMG_NAME="GranolaSync-${VERSION}.dmg"
DMG_PATH="$PROJECT_DIR/build/$DMG_NAME"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: App not built. Run 'make app' first."
    exit 1
fi

echo "Creating DMG (v${VERSION})..."

# Create a temporary directory for DMG contents
STAGING="$PROJECT_DIR/build/dmg-staging"
rm -rf "$STAGING"
mkdir -p "$STAGING"

cp -R "$APP_BUNDLE" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# Clean resource forks before creating DMG
xattr -cr "$STAGING" 2>/dev/null || true

# Create the DMG
rm -f "$DMG_PATH"
hdiutil create -volname "Granola Sync" \
    -srcfolder "$STAGING" \
    -ov -format UDZO \
    "$DMG_PATH"

rm -rf "$STAGING"

echo "Created: $DMG_PATH"
echo "SHA256: $(shasum -a 256 "$DMG_PATH" | cut -d' ' -f1)"
