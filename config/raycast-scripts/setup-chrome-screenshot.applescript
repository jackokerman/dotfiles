#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Setup Chrome Screenshot
# @raycast.mode silent
# @raycast.icon 📸
# @raycast.packageName Window Manager

# Setup Chrome window for screenshots by making it floating and resizing to 14" MacBook resolution (1512x982)

try
    # Check if Chrome is running
    tell application "System Events"
        if not (exists process "Google Chrome") then
            error "Google Chrome is not running"
        end if
    end tell

    # Get focused window ID from aerospace
    set windowId to do shell script "aerospace list-windows --focused --json | jq -r '.[].[\"window-id\"]'"

    if windowId is "" then
        error "No focused window found. Please focus a Chrome window and try again."
    end if

    # Verify the focused window is Chrome
    set windowInfo to do shell script "aerospace list-windows --focused --json | jq -r '.[].[\"app-name\"]'"

    if windowInfo is not "Google Chrome" then
        error "Focused window is not Chrome. Current app: " & windowInfo
    end if

    # Make window floating using aerospace
    do shell script "aerospace layout floating --window-id " & windowId

    # Give aerospace a moment to apply floating layout
    delay 0.1

    # Target dimensions for 14" MacBook Pro (default scaled resolution)
    set targetWidth to 1512
    set targetHeight to 982

    # Get main display bounds
    tell application "Finder"
        set screenBounds to bounds of window of desktop
        set screenWidth to item 3 of screenBounds
        set screenHeight to item 4 of screenBounds
    end tell

    # Calculate center position
    set centerX to (screenWidth - targetWidth) / 2
    set centerY to (screenHeight - targetHeight) / 2

    # Ensure minimum position values (account for menu bar)
    if centerY < 25 then
        set centerY to 25
    end if

    # Set window size and position
    tell application "System Events"
        tell process "Google Chrome"
            set frontmost to true
            tell front window
                set position to {centerX, centerY}
                set size to {targetWidth, targetHeight}
            end tell
        end tell
    end tell

    # Success - no output needed in silent mode

on error errMsg
    # In silent mode, errors will still be shown to the user
    return "Error: " & errMsg
end try
