#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"
BUILD_DIR=".build/arm64-apple-macosx/release"
APP="dist/MacAICleaner.app"
swift build -c release
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BUILD_DIR/MacAICleaner" "$APP/Contents/MacOS/MacAICleaner"
cp Resources/MacAICleanerLogo.png "$APP/Contents/Resources/MacAICleanerLogo.png"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>CFBundleName</key><string>Mac AI Cleaner</string><key>CFBundleDisplayName</key><string>Mac AI Cleaner</string><key>CFBundleIdentifier</key><string>com.cetrinw.mac-ai-cleaner</string><key>CFBundleVersion</key><string>0.2.0</string><key>CFBundleShortVersionString</key><string>0.2.0</string><key>CFBundleExecutable</key><string>MacAICleaner</string><key>CFBundlePackageType</key><string>APPL</string><key>LSMinimumSystemVersion</key><string>14.0</string><key>NSHighResolutionCapable</key><true/><key>LSApplicationCategoryType</key><string>public.app-category.utilities</string></dict></plist>
PLIST
chmod +x "$APP/Contents/MacOS/MacAICleaner"
codesign --force --deep --sign - "$APP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "dist/MacAICleaner-0.2.0-macos-arm64.zip"
printf '%s\n' "Created $APP" "Created dist/MacAICleaner-0.2.0-macos-arm64.zip"
