#!/bin/bash
# Arrange Workspace P - Personal browser (Chrome with Personal profile)

echo "Arranging Workspace P (Personal Browser)..."

# Find Chrome window with "(Personal)" in title
WINDOW_ID=$(/opt/homebrew/bin/aerospace list-windows --all --format '%{window-id}|%{app-name}|%{window-title}' | \
    grep "Google Chrome" | \
    grep "(Personal)" | \
    head -1 | \
    cut -d'|' -f1)

if [ -z "$WINDOW_ID" ]; then
    echo "❌ Error: Chrome personal profile window not found"
    echo "   Make sure Chrome is open with your Personal profile"
    exit 1
fi

echo "Found Chrome (Personal) (window ID: $WINDOW_ID)"
echo "Moving to workspace P..."

# Move to workspace P
/opt/homebrew/bin/aerospace move-node-to-workspace --window-id $WINDOW_ID P

echo "✓ Done! Chrome (Personal) moved to workspace P"

