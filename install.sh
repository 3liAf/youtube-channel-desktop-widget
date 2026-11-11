#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEST="$HOME/Applications"

mkdir -p "$DEST"
echo "📦 Copying BrandItStats.app to $DEST..."
rm -rf "$DEST/BrandItStats.app"
cp -R "$DIR/BrandItStats.app" "$DEST/"

echo "🚀 Launching BrandItStats..."
open "$DEST/BrandItStats.app"

echo "✨ BrandItStats is now installed in $DEST and running in your menu bar!"
