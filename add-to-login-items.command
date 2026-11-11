#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_PATH="$DIR/BrandItStats.app"

echo "=========================================="
echo "  Setting BrandIt Stats as a Login Item"
echo "=========================================="

osascript -e "tell application \"System Events\" to delete login item \"BrandIt Stats\"" 2>/dev/null || true
osascript -e "tell application \"System Events\" to delete login item \"BrandItStats\"" 2>/dev/null || true

osascript -e "tell application \"System Events\" to make login item at end with properties {name:\"BrandIt Stats\", path:\"$APP_PATH\", hidden:false}"

echo "✅ Success! BrandIt Stats will now automatically start every time you log in to your Mac."
echo "You can manage this anytime in: System Settings > General > Login Items."
echo ""
