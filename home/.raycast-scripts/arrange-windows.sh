#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Arrange Windows
# @raycast.mode silent
# @raycast.icon 🪟
# @raycast.packageName Window Manager

# Arrange windows to their designated workspaces based on the
# $AEROSPACE_ARRANGEMENTS env var (comma-separated entries).
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

[[ -z "$AEROSPACE_ARRANGEMENTS" ]] && exit 0

IFS=',' read -rA arrangements <<< "$AEROSPACE_ARRANGEMENTS"

windows=$(aerospace list-windows --all --json)

for arrangement in "${arrangements[@]}"; do
    IFS='|' read -r app_name filter workspace <<< "$arrangement"

    if [[ -z "$filter" ]]; then
        jq_filter=".[] | select(.[\"app-name\"] == \"$app_name\") | .[\"window-id\"]"
    else
        jq_filter=".[] | select(.[\"app-name\"] == \"$app_name\" and (.[\"window-title\"] | contains(\"$filter\"))) | .[\"window-id\"]"
    fi

    echo "$windows" | jq -r "$jq_filter" | while read -r window_id; do
        [[ -n "$window_id" ]] && aerospace move-node-to-workspace "$workspace" --window-id "$window_id" 2>/dev/null || true
    done
done
