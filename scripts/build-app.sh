#!/bin/sh
# Builds dist/Lanes.app from the Swift package (no Xcode needed).
set -eu

cd "$(dirname "$0")/.."
VERSION="${VERSION:-0.1.0}"
BUILD="${BUILD:-$(git rev-list --count HEAD 2>/dev/null || echo 1)}"

swift build -c release --product Lanes
swift build -c release --product LanesLauncher
BIN="$(swift build -c release --show-bin-path)"

APP="dist/Lanes.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN/Lanes" "$APP/Contents/MacOS/Lanes"
cp "$BIN/LanesLauncher" "$APP/Contents/MacOS/lanes-launcher"
sed -e "s/__VERSION__/$VERSION/" -e "s/__BUILD__/$BUILD/" Packaging/Info.plist > "$APP/Contents/Info.plist"
"$APP/Contents/MacOS/lanes-launcher" --write-app-icon "$APP/Contents/Resources/AppIcon.icns"

codesign --force --deep --sign - "$APP"
echo "Built $APP ($VERSION, build $BUILD)"
