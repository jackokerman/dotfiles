#!/bin/bash
# Phase 3: Move Chrome work profile to workspace B
# Tests identifying Chrome windows by profile pattern

echo "Arranging Workspace B (Browser - Work)..."

# Find Chrome window with "(Stripe)" in title
WINDOW_ID=$(/opt/homebrew/bin/aerospace list-windows --all --format '%{window-id}|%{app-name}|%{window-title}' | \
    grep "Google Chrome" | \
    grep "(Stripe)" | \
    head -1 | \
    cut -d'|' -f1)

if [ -z "$WINDOW_ID" ]; then
    echo "❌ Error: Chrome work profile window not found"
    echo "   Make sure Chrome is open with your Stripe/work profile"
    exit 1
fi

echo "Found Chrome (Stripe) (window ID: $WINDOW_ID)"
echo "Moving to workspace B..."

# Move to workspace B
/opt/homebrew/bin/aerospace move-node-to-workspace --window-id $WINDOW_ID B

echo "✓ Done! Check if Chrome (Stripe) moved to workspace B"

