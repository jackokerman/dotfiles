#!/bin/bash
# Phase 2: Move Obsidian to workspace N
# This moves ONE window to test the basic moving functionality

echo "Arranging Workspace N (Notes)..."

# Find Obsidian window ID
WINDOW_ID=$(/opt/homebrew/bin/aerospace list-windows --all --format '%{window-id}|%{app-name}' | grep "Obsidian" | head -1 | cut -d'|' -f1)

if [ -z "$WINDOW_ID" ]; then
    echo "❌ Error: Obsidian not found. Is it open?"
    exit 1
fi

echo "Found Obsidian (window ID: $WINDOW_ID)"
echo "Moving to workspace N..."

# Move to workspace N
/opt/homebrew/bin/aerospace move-node-to-workspace --window-id $WINDOW_ID N

echo "✓ Done! Check if Obsidian moved to workspace N"

