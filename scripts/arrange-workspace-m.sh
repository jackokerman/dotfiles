#!/bin/bash
# Phase 4: Arrange Workspace M - Messaging with custom layout
# Layout: Slack on left, Gmail + Calendar in vertical accordion on right

echo "Arranging Workspace M (Messaging)..."

# Find and move Slack
SLACK_ID=$(/opt/homebrew/bin/aerospace list-windows --all --format '%{window-id}|%{app-name}' | grep "Slack" | head -1 | cut -d'|' -f1)
if [ -n "$SLACK_ID" ]; then
    echo "Found Slack (window ID: $SLACK_ID)"
    /opt/homebrew/bin/aerospace move-node-to-workspace --window-id $SLACK_ID M
else
    echo "⚠️  Slack not found (skipping)"
fi

# Find and move Gmail
GMAIL_ID=$(/opt/homebrew/bin/aerospace list-windows --all --format '%{window-id}|%{app-name}' | grep "Gmail" | head -1 | cut -d'|' -f1)
if [ -n "$GMAIL_ID" ]; then
    echo "Found Gmail (window ID: $GMAIL_ID)"
    /opt/homebrew/bin/aerospace move-node-to-workspace --window-id $GMAIL_ID M
else
    echo "⚠️  Gmail not found (skipping)"
fi

# Find and move Google Calendar
CAL_ID=$(/opt/homebrew/bin/aerospace list-windows --all --format '%{window-id}|%{app-name}' | grep "Google Calendar" | head -1 | cut -d'|' -f1)
if [ -n "$CAL_ID" ]; then
    echo "Found Google Calendar (window ID: $CAL_ID)"
    /opt/homebrew/bin/aerospace move-node-to-workspace --window-id $CAL_ID M
else
    echo "⚠️  Google Calendar not found (skipping)"
fi

# Apply custom layout if we have any windows
if [ -n "$SLACK_ID" ] || [ -n "$GMAIL_ID" ] || [ -n "$CAL_ID" ]; then
    echo ""
    echo "=== BEFORE layout changes ==="
    /opt/homebrew/bin/aerospace list-windows --workspace M --format '%{window-id}|%{app-name}|%{workspace}'
    echo ""
    echo "Current focus:"
    /opt/homebrew/bin/aerospace list-windows --focused --format '%{window-id}|%{app-name}'
    
    echo ""
    echo "Applying custom layout (Slack left, Gmail+Calendar accordion right)..."
    /opt/homebrew/bin/aerospace workspace M
    
    # Flatten everything - all windows at root level
    /opt/homebrew/bin/aerospace flatten-workspace-tree
    echo "Step 1: Flattened - all windows at root"
    
    # Set root to horizontal tiles FIRST (all 3 windows side-by-side)
    /opt/homebrew/bin/aerospace layout tiles horizontal
    echo "Step 2: Root is horizontal tiles (all 3 windows side-by-side)"
    
    # Now join Gmail and Calendar - this will create a vertical container due to normalization
    if [ -n "$GMAIL_ID" ] && [ -n "$CAL_ID" ]; then
        # Focus Gmail
        /opt/homebrew/bin/aerospace focus --window-id $GMAIL_ID
        echo "Step 3: Focused Gmail"
        
        # Focus Calendar  
        /opt/homebrew/bin/aerospace focus --window-id $CAL_ID
        echo "Step 4: Focused Calendar"
        
        # Join with Gmail (which should be to the left in horizontal layout)
        /opt/homebrew/bin/aerospace join-with left
        echo "Step 5: Joined Calendar with Gmail - creates vertical container"
        
        # Set accordion on the vertical container
        /opt/homebrew/bin/aerospace layout accordion vertical
        echo "Step 6: Set Gmail+Calendar container to accordion vertical"
    fi
    
    echo ""
    echo "=== AFTER layout changes ==="
    /opt/homebrew/bin/aerospace list-windows --workspace M --format '%{window-id}|%{app-name}|%{workspace}'
    echo ""
    echo "Final focus:"
    /opt/homebrew/bin/aerospace list-windows --focused --format '%{window-id}|%{app-name}'
    
    echo ""
    echo "✓ Done! Check workspace M layout"
else
    echo "❌ No messaging apps found to arrange"
    exit 1
fi

