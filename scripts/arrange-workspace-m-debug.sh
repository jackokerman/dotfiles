#!/bin/bash
# Debug version of arrange-workspace-m.sh
# Layout: Slack on left, Gmail + Calendar in vertical accordion on right

echo "=========================================="
echo "Arranging Workspace M (Messaging) - DEBUG"
echo "=========================================="

# Find windows
SLACK_ID=$(/opt/homebrew/bin/aerospace list-windows --all --format '%{window-id}|%{app-name}' | grep "Slack" | head -1 | cut -d'|' -f1)
GMAIL_ID=$(/opt/homebrew/bin/aerospace list-windows --all --format '%{window-id}|%{app-name}' | grep "Gmail" | head -1 | cut -d'|' -f1)
CAL_ID=$(/opt/homebrew/bin/aerospace list-windows --all --format '%{window-id}|%{app-name}' | grep "Google Calendar" | head -1 | cut -d'|' -f1)

echo "Found windows:"
echo "  Slack:    $SLACK_ID"
echo "  Gmail:    $GMAIL_ID"
echo "  Calendar: $CAL_ID"
echo ""

if [ -z "$SLACK_ID" ] || [ -z "$GMAIL_ID" ] || [ -z "$CAL_ID" ]; then
    echo "❌ Not all windows found!"
    exit 1
fi

# Clear workspace M first
echo "Clearing workspace M..."
for win in $(/opt/homebrew/bin/aerospace list-windows --workspace M --format "%{window-id}"); do
    /opt/homebrew/bin/aerospace move-node-to-workspace --window-id "$win" S
done

# Move windows to workspace M
echo "Moving windows to workspace M..."
/opt/homebrew/bin/aerospace move-node-to-workspace --window-id $SLACK_ID M
/opt/homebrew/bin/aerospace move-node-to-workspace --window-id $GMAIL_ID M
/opt/homebrew/bin/aerospace move-node-to-workspace --window-id $CAL_ID M

echo ""
echo "=== INITIAL STATE (after moving) ==="
/opt/homebrew/bin/aerospace list-windows --workspace M --format '%{app-name} [%{window-id}]'
echo ""

# Switch to workspace
/opt/homebrew/bin/aerospace workspace M
sleep 0.2

# Step 1: Flatten
echo "STEP 1: Flattening workspace..."
/opt/homebrew/bin/aerospace flatten-workspace-tree
sleep 0.2
echo "After flatten:"
/opt/homebrew/bin/aerospace list-windows --workspace M --format '%{app-name} [%{window-id}]'
echo ""

# Step 2: Set horizontal tiles
echo "STEP 2: Setting root to horizontal tiles..."
/opt/homebrew/bin/aerospace layout tiles horizontal
sleep 0.2
echo "After setting horizontal tiles:"
/opt/homebrew/bin/aerospace list-windows --workspace M --format '%{app-name} [%{window-id}]'
echo ""

# Test what's actually adjacent
echo "VISUAL POSITION TEST:"
echo "  From Slack, what's to the right?"
/opt/homebrew/bin/aerospace focus --window-id $SLACK_ID
/opt/homebrew/bin/aerospace focus right 2>/dev/null && echo "    → $(/opt/homebrew/bin/aerospace list-windows --focused --format '%{app-name}')" || echo "    → (nothing)"

echo "  From Gmail, what's to the left and right?"
/opt/homebrew/bin/aerospace focus --window-id $GMAIL_ID
/opt/homebrew/bin/aerospace focus left 2>/dev/null && echo "    LEFT: $(/opt/homebrew/bin/aerospace list-windows --focused --format '%{app-name}')" || echo "    LEFT: (nothing)"
/opt/homebrew/bin/aerospace focus --window-id $GMAIL_ID
/opt/homebrew/bin/aerospace focus right 2>/dev/null && echo "    RIGHT: $(/opt/homebrew/bin/aerospace list-windows --focused --format '%{app-name}')" || echo "    RIGHT: (nothing)"

echo "  From Calendar, what's to the left?"
/opt/homebrew/bin/aerospace focus --window-id $CAL_ID
/opt/homebrew/bin/aerospace focus left 2>/dev/null && echo "    LEFT: $(/opt/homebrew/bin/aerospace list-windows --focused --format '%{app-name}')" || echo "    LEFT: (nothing)"
echo ""

# Step 3: Focus Gmail
echo "STEP 3: Focusing Gmail..."
/opt/homebrew/bin/aerospace focus --window-id $GMAIL_ID
echo "Focused: $(/opt/homebrew/bin/aerospace list-windows --focused --format '%{app-name}')"
echo ""

# Step 4: Focus Calendar
echo "STEP 4: Focusing Calendar..."
/opt/homebrew/bin/aerospace focus --window-id $CAL_ID
echo "Focused: $(/opt/homebrew/bin/aerospace list-windows --focused --format '%{app-name}')"
echo ""

# Step 5: Join with left
echo "STEP 5: Executing 'join-with left' (Calendar joins with window to its left)..."
/opt/homebrew/bin/aerospace join-with left
sleep 0.2
echo "After join:"
/opt/homebrew/bin/aerospace list-windows --workspace M --format '%{app-name} [%{window-id}]'
echo "Focused: $(/opt/homebrew/bin/aerospace list-windows --focused --format '%{app-name}')"
echo ""

# Step 6: Set accordion vertical
echo "STEP 6: Setting to accordion vertical..."
/opt/homebrew/bin/aerospace layout accordion vertical
sleep 0.2
echo "After setting accordion:"
/opt/homebrew/bin/aerospace list-windows --workspace M --format '%{app-name} [%{window-id}]'
echo ""

echo "=========================================="
echo "✓ Script complete!"
echo "=========================================="
echo ""
echo "Please describe what you see visually in workspace M:"
echo "  - What's on the left side?"
echo "  - What's on the right side?"
echo "  - Is anything in an accordion?"
