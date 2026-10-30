#!/bin/sh
# Builds dist/ClaudeLanes.app from the Swift package (no Xcode needed).
set -eu

cd "$(dirname "$0")/.."
VERSION="${VERSION:-0.1.1}"
BUILD="${BUILD:-$(git rev-list --count HEAD 2>/dev/null || echo 1)}"

swift build -c release --product ClaudeLanes
swift build -c release --product LanesLauncher
BIN="$(swift build -c release --show-bin-path)"

APP="dist/ClaudeLanes.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN/ClaudeLanes" "$APP/Contents/MacOS/ClaudeLanes"
cp "$BIN/LanesLauncher" "$APP/Contents/MacOS/claudelanes-launcher"
sed -e "s/__VERSION__/$VERSION/" -e "s/__BUILD__/$BUILD/" Packaging/Info.plist > "$APP/Contents/Info.plist"
"$APP/Contents/MacOS/claudelanes-launcher" --write-app-icon "$APP/Contents/Resources/AppIcon.icns"

codesign --force --deep --sign - "$APP"
echo "Built $APP ($VERSION, build $BUILD)"
