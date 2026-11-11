#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "🔨 Building BrandItStats..."

APP_DIR="$DIR/BrandItStats.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp "$DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
if [ -f "$DIR/AppIcon.icns" ]; then
    cp "$DIR/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

swiftc -O -parse-as-library \
    "$DIR/Sources/ChannelFetcher.swift" \
    "$DIR/Sources/Views.swift" \
    "$DIR/Sources/AppDelegate.swift" \
    "$DIR/Sources/main.swift" \
    -o "$MACOS_DIR/BrandItStats"

echo "✅ Successfully built: $APP_DIR"
