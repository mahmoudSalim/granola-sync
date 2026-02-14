SHELL := /bin/bash
APP_NAME := GranolaSync
DISPLAY_NAME := Granola Sync
BUNDLE := $(APP_NAME).app
BUILD_DIR := build
SWIFT_FILES := $(shell find app/GranolaSync -name '*.swift' -type f)
TARGET := arm64-apple-macosx14.0

.PHONY: all app clean install dev-install python-install python-test

all: app

# ── Swift App ──────────────────────────────────────────────────────────────

app: $(SWIFT_FILES)
	@mkdir -p "$(BUILD_DIR)/$(BUNDLE)/Contents/MacOS"
	@mkdir -p "$(BUILD_DIR)/$(BUNDLE)/Contents/Resources"
	swiftc -O -parse-as-library \
		-o "$(BUILD_DIR)/$(BUNDLE)/Contents/MacOS/$(APP_NAME)" \
		$(SWIFT_FILES) \
		-target $(TARGET) \
		-framework SwiftUI \
		-framework AppKit
	@# Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleName string $(APP_NAME)" "$(BUILD_DIR)/$(BUNDLE)/Contents/Info.plist" 2>/dev/null || true
	@/usr/libexec/PlistBuddy -c "Set :CFBundleName $(APP_NAME)" "$(BUILD_DIR)/$(BUNDLE)/Contents/Info.plist"
	@/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.granola-sync.app" "$(BUILD_DIR)/$(BUNDLE)/Contents/Info.plist" 2>/dev/null || true
	@/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string $(APP_NAME)" "$(BUILD_DIR)/$(BUNDLE)/Contents/Info.plist" 2>/dev/null || true
	@/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string 1.1.2" "$(BUILD_DIR)/$(BUNDLE)/Contents/Info.plist" 2>/dev/null || true
	@/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 1.1.2" "$(BUILD_DIR)/$(BUNDLE)/Contents/Info.plist" 2>/dev/null || true
	@/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string '$(DISPLAY_NAME)'" "$(BUILD_DIR)/$(BUNDLE)/Contents/Info.plist" 2>/dev/null || true
	@/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$(BUILD_DIR)/$(BUNDLE)/Contents/Info.plist" 2>/dev/null || true
	@/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$(BUILD_DIR)/$(BUNDLE)/Contents/Info.plist" 2>/dev/null || true
	@# Copy app icon
	@cp app/GranolaSync/Resources/AppIcon.icns "$(BUILD_DIR)/$(BUNDLE)/Contents/Resources/AppIcon.icns"
	@# Clean resource forks and .DS_Store before signing
	@xattr -cr "$(BUILD_DIR)/$(BUNDLE)"
	@find "$(BUILD_DIR)/$(BUNDLE)" -name '.DS_Store' -delete 2>/dev/null || true
	@# Code sign
	codesign --force --sign - "$(BUILD_DIR)/$(BUNDLE)"
	@# Rename to display name (space in name for Finder/Spotlight)
	@rm -rf "$(BUILD_DIR)/$(DISPLAY_NAME).app"
	@mv "$(BUILD_DIR)/$(BUNDLE)" "$(BUILD_DIR)/$(DISPLAY_NAME).app"
	@echo "Built: $(BUILD_DIR)/$(DISPLAY_NAME).app"

# ── Python Package ─────────────────────────────────────────────────────────

python-install:
	@echo "Creating Python venv..."
	python3 -m venv .venv
	source .venv/bin/activate && uv pip install -e python/
	@echo "Installed: granola-sync CLI"

python-test:
	source .venv/bin/activate && python -m pytest python/tests/ -v

# ── Combined Install ───────────────────────────────────────────────────────

dev-install: python-install app
	@echo ""
	@echo "Development install complete!"
	@echo "  CLI: source .venv/bin/activate && granola-sync --help"
	@echo "  App: open '$(BUILD_DIR)/$(DISPLAY_NAME).app'"

install: app
	@echo "Installing to /Applications..."
	@pkill -9 $(APP_NAME) 2>/dev/null || true
	@rm -rf "/Applications/$(DISPLAY_NAME).app"
	@rm -rf "/Applications/$(BUNDLE)"
	cp -R "$(BUILD_DIR)/$(DISPLAY_NAME).app" /Applications/
	@# Register with Launch Services for Spotlight indexing
	@/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/$(DISPLAY_NAME).app"
	@echo "Installed: /Applications/$(DISPLAY_NAME).app"

# ── Cleanup ────────────────────────────────────────────────────────────────

clean:
	rm -rf $(BUILD_DIR)
	rm -rf .venv
	find . -name __pycache__ -type d -exec rm -rf {} + 2>/dev/null || true
