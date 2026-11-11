#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP="$DIR/BrandItStats.app"

echo "=========================================="
echo "  Launching BrandIt Stats..."
echo "=========================================="
open "$APP"
echo "✅ BrandIt Stats is now running!"
echo "Check your top macOS menu bar for the ▶ icon."
echo ""
