#!/bin/bash
set -e

# ============================================================
# ClippyBar — Mac App Store Build & Upload Script
# ============================================================
#
# Prerequisites:
#   1. "Apple Distribution" certificate installed in Keychain
#   2. "Mac Installer Distribution" certificate installed in Keychain
#   3. Mac App Store provisioning profile installed
#   4. App created in App Store Connect
#
# Usage:
#   ./scripts/build_appstore.sh
# ============================================================

APP_NAME="ClippyBar"
BUNDLE_ID="com.clipbar.app"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG_DIR="$ROOT/mac-app/ClippyBar"
BUILD_DIR="$ROOT/build/appstore"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
PKG_PATH="$BUILD_DIR/$APP_NAME.pkg"
ENTITLEMENTS="$PKG_DIR/ClippyBar.entitlements"
INFO_PLIST="$PKG_DIR/Resources/Info.plist"
ICON="$PKG_DIR/Resources/AppIcon.icns"

echo ""
echo "  Building ClippyBar for App Store"
echo ""

# ── Find signing identities ──
APP_IDENTITY=$(security find-identity -v -p codesigning | grep "Apple Distribution" | head -1 | awk -F'"' '{print $2}')
INSTALLER_IDENTITY=$(security find-identity -v | grep "3rd Party Mac Developer Installer\|Mac Installer Distribution" | head -1 | awk -F'"' '{print $2}')

if [ -z "$APP_IDENTITY" ]; then
  echo "Error: No 'Apple Distribution' certificate found."
  security find-identity -v -p codesigning
  exit 1
fi

if [ -z "$INSTALLER_IDENTITY" ]; then
  echo "Error: No 'Mac Installer Distribution' certificate found."
  exit 1
fi

echo "  App signing:       $APP_IDENTITY"
echo "  Installer signing: $INSTALLER_IDENTITY"

# ── Clean ──
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# ── Build ──
echo "  Building (release, universal)..."
cd "$PKG_DIR"
swift build -c release --arch arm64 --arch x86_64 2>&1 | tail -3
BIN_PATH=$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path 2>/dev/null)
BINARY="$BIN_PATH/$APP_NAME"
cd "$ROOT"

if [ ! -f "$BINARY" ]; then
  echo "Error: Build failed — binary not found at $BINARY"
  exit 1
fi

# ── Assemble .app bundle ──
echo "  Assembling app bundle..."
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

cp "$BINARY" "$APP_PATH/Contents/MacOS/$APP_NAME"
cp "$INFO_PLIST" "$APP_PATH/Contents/Info.plist"
cp "$ICON" "$APP_PATH/Contents/Resources/"

# ── Asset catalog ──
echo "  Creating asset catalog..."
TMPASSETS="/tmp/ClippyBarAssets.xcassets"
rm -rf "$TMPASSETS"
mkdir -p "$TMPASSETS/AppIcon.appiconset"

for SIZE in 16 32 64 128 256 512 1024; do
  sips -s format png --resampleWidth $SIZE "$ICON" --out "/tmp/icon_${SIZE}.png" >/dev/null 2>&1
done
cp /tmp/icon_*.png "$TMPASSETS/AppIcon.appiconset/"

cat > "$TMPASSETS/AppIcon.appiconset/Contents.json" << 'ICONJSON'
{
  "images" : [
    { "filename" : "icon_16.png", "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
    { "filename" : "icon_32.png", "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
    { "filename" : "icon_32.png", "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
    { "filename" : "icon_64.png", "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
    { "filename" : "icon_128.png", "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "filename" : "icon_256.png", "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "filename" : "icon_256.png", "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "filename" : "icon_512.png", "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
    { "filename" : "icon_512.png", "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "filename" : "icon_1024.png", "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
ICONJSON

if ! xcrun actool "$TMPASSETS" \
  --compile "$APP_PATH/Contents/Resources" \
  --platform macosx \
  --minimum-deployment-target 13.0 \
  --app-icon AppIcon \
  --output-partial-info-plist /tmp/assetcat_info.plist \
  >/dev/null 2>&1; then
  echo "  Warning: Asset catalog compilation failed — icon may be missing"
fi

# ── Provisioning profile ──
PROFILE_PATH=$(ls ~/Library/MobileDevice/Provisioning\ Profiles/*.provisionprofile 2>/dev/null | head -1)
if [ -n "$PROFILE_PATH" ]; then
  cp "$PROFILE_PATH" "$APP_PATH/Contents/embedded.provisionprofile"
  echo "  Provisioning profile embedded"
else
  echo "  Warning: No provisioning profile found — App Store upload will fail without one"
fi

# ── Strip quarantine ──
find "$APP_PATH" -exec xattr -c {} \; 2>/dev/null

# ── Sign ──
echo "  Signing..."
codesign --force --deep --options runtime \
  --identifier "$BUNDLE_ID" \
  --entitlements "$ENTITLEMENTS" \
  --sign "$APP_IDENTITY" \
  "$APP_PATH" 2>&1

codesign --verify --deep --strict "$APP_PATH" 2>&1 && echo "  Signature valid"

# ── Package ──
echo "  Building package..."
productbuild --component "$APP_PATH" /Applications \
  --sign "$INSTALLER_IDENTITY" \
  "$PKG_PATH" 2>&1

xattr -c "$PKG_PATH" 2>/dev/null

echo ""
echo "  Done: $PKG_PATH"
ls -lh "$PKG_PATH"
echo ""
echo "  Upload via Transporter or: xcrun altool --upload-app --type macos --file $PKG_PATH"
