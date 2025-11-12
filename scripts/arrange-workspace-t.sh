#!/bin/bash
# Arrange Workspace T - Tasks (Godspeed PWA)

echo "Arranging Workspace T (Tasks)..."

# Find Godspeed window
WINDOW_ID=$(/opt/homebrew/bin/aerospace list-windows --all --format '%{window-id}|%{app-name}' | \
    grep "Godspeed" | \
    head -1 | \
    cut -d'|' -f1)

if [ -z "$WINDOW_ID" ]; then
    echo "❌ Error: Godspeed not found. Is it open?"
    exit 1
fi

echo "Found Godspeed (window ID: $WINDOW_ID)"
echo "Moving to workspace T..."

# Move to workspace T
/opt/homebrew/bin/aerospace move-node-to-workspace --window-id $WINDOW_ID T

echo "✓ Done! Godspeed moved to workspace T"

