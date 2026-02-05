#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Arrange Windows
# @raycast.mode silent
# @raycast.icon 🪟
# @raycast.packageName Window Manager

# Arrange windows to their designated workspaces based on config files
# Sources ~/.aerospace-arrangement (base config)
# Sources ~/.aerospace-arrangement.local if exists (machine-specific override)
#
# Configuration format: "APP_NAME|FILTER|WORKSPACE"
#   APP_NAME: Application name as shown in aerospace (e.g., "Google Chrome", "Slack")
#   FILTER:   Optional window title filter - only moves windows whose title contains this text
#             Leave empty (||) to move ALL windows from the app
#   WORKSPACE: Target workspace letter (e.g., "B", "S", "T")
#
# Examples:
#   "Google Chrome||B"                  - Move ALL Chrome windows to workspace B
#   "Google Chrome|stripe.com|B"        - Move only Chrome windows with "stripe.com" in title to B
#   "Google Chrome|Personal|P"          - Move only Chrome windows with "Personal" in title to P
#   "Slack||S"                          - Move ALL Slack windows to workspace S
#
# Use case: Separating Chrome profiles
#   "Google Chrome|stripe.com|B"        - Work profile windows go to B
#   "Google Chrome|Personal|P"          - Personal profile windows go to P
#   (Chrome shows profile name in window title, e.g., "Gmail - Personal" or "Jira - Jack (stripe.com)")

do shell script "
# Source base arrangement config (always exists)
if [ -f ~/.aerospace-arrangement ]; then
    source ~/.aerospace-arrangement
fi

# Source local arrangement config if it exists (overrides base)
if [ -f ~/.aerospace-arrangement.local ]; then
    source ~/.aerospace-arrangement.local
fi

# Get all windows as JSON
windows=$(aerospace list-windows --all --json)

# Process each arrangement rule
for arrangement in \"${AEROSPACE_ARRANGEMENTS[@]}\"; do
    # Parse the pipe-delimited format: APP|FILTER|WORKSPACE
    IFS='|' read -r app_name filter workspace <<< \"$arrangement\"

    # Build jq filter based on whether we have a title filter
    if [ -z \"$filter\" ]; then
        # No filter: match all windows from this app
        jq_filter=\".[] | select(.[\\\"app-name\\\"] == \\\"$app_name\\\") | .[\\\"window-id\\\"]\"
    else
        # With filter: match windows with filter text in title
        jq_filter=\".[] | select(.[\\\"app-name\\\"] == \\\"$app_name\\\" and (.[\\\"window-title\\\"] | contains(\\\"$filter\\\"))) | .[\\\"window-id\\\"]\"
    fi

    # Move matching windows to workspace
    echo \"$windows\" | jq -r \"$jq_filter\" | while read -r window_id; do
        if [ -n \"$window_id\" ]; then
            aerospace move-node-to-workspace \"$workspace\" --window-id \"$window_id\" 2>/dev/null || true
        fi
    done
done
"

return
