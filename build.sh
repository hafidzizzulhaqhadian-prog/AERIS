#!/bin/bash
set -euo pipefail
APP_NAME="AERIS"
ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/build"
APP="$OUT/$APP_NAME.app"

if ! command -v swiftc >/dev/null 2>&1; then
  echo "ERROR: Swift compiler (swiftc) is not available."
  exit 1
fi
SDK="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
if [[ -z "$SDK" ]]; then
  echo "ERROR: macOS SDK not found. Check Command Line Tools installation."
  exit 1
fi
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc \
  -parse-as-library \
  -sdk "$SDK" \
  -target x86_64-apple-macosx14.0 \
  "$ROOT/Sources/AERIS.swift" \
  -framework AppKit \
  -framework SwiftUI \
  -framework IOKit \
  -o "$APP/Contents/MacOS/AERIS"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>AERIS</string>
    <key>CFBundleIdentifier</key><string>org.aeris.virtualisland</string>
    <key>CFBundleName</key><string>AERIS</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.3.2</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>LSUIElement</key><true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>AERIS membaca informasi lagu dan mengontrol pemutaran Apple Music atau Spotify.</string>
</dict>
</plist>
PLIST
echo "Build complete: $APP"
echo "To launch: open \"$APP\""
