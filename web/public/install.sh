#!/bin/bash
set -e

# ClippyBar installer (direct download — also available on the Mac App Store)
# Usage: curl -fsSL https://clipbar.co/install.sh | bash

APP_NAME="ClippyBar"
TMP_DMG="/tmp/ClippyBar.dmg"
MOUNT_DIR="/tmp/clipbar_mount_$$"
INSTALL_DIR="/Applications"

echo ""
echo "  ╭──────────────────────────────╮"
echo "  │   Installing $APP_NAME...       │"
echo "  ╰──────────────────────────────╯"
echo ""

# Clean up any previous attempts
rm -f "$TMP_DMG"
hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true

# Download via GitHub API (avoids redirect issues)
echo "  ↓ Downloading $APP_NAME..."
DMG_URL=$(curl -fsSL "https://api.github.com/repos/panayar/Clippy/releases/latest" \
  | grep -o '"browser_download_url":\s*"[^"]*\.dmg"' \
  | head -1 \
  | sed 's/"browser_download_url":\s*"//;s/"$//')

if [ -z "$DMG_URL" ]; then
  echo "  ✗ Error: Could not find download URL."
  echo "    Check https://github.com/panayar/Clippy/releases"
  exit 1
fi

curl -L --progress-bar -o "$TMP_DMG" "$DMG_URL"

# Verify download
if [ ! -s "$TMP_DMG" ]; then
  echo "  ✗ Error: Download failed."
  exit 1
fi

echo "  ↓ Mounting disk image..."
hdiutil attach "$TMP_DMG" -nobrowse -quiet -mountpoint "$MOUNT_DIR"

# Remove old installation if present
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
  echo "  ↻ Removing previous version..."
  rm -rf "$INSTALL_DIR/$APP_NAME.app" 2>/dev/null || sudo rm -rf "$INSTALL_DIR/$APP_NAME.app"
fi

echo "  → Installing to $INSTALL_DIR..."
cp -R "$MOUNT_DIR/$APP_NAME.app" "$INSTALL_DIR/" 2>/dev/null || {
  echo "  ⚠ Need permission to install to /Applications"
  sudo cp -R "$MOUNT_DIR/$APP_NAME.app" "$INSTALL_DIR/"
}

# Remove quarantine attribute — required for unsigned/ad-hoc signed apps.
# Without this, macOS Gatekeeper blocks the app with "damaged" or
# "unidentified developer" errors since it's not notarized by Apple.
echo "  → Clearing macOS Gatekeeper quarantine..."
xattr -cr "$INSTALL_DIR/$APP_NAME.app" 2>/dev/null || \
  sudo xattr -cr "$INSTALL_DIR/$APP_NAME.app" 2>/dev/null || true

# Cleanup
hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true
rm -f "$TMP_DMG"

echo ""
echo "  ✓ ClippyBar installed successfully!"
echo ""
echo "  Opening ClippyBar..."
open "$INSTALL_DIR/$APP_NAME.app"
echo ""
echo "  Tip: ClippyBar lives in your menu bar. Press ⌥V to open the picker."
echo ""
