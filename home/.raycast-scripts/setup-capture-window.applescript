#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Setup Capture Window
# @raycast.mode silent
# @raycast.icon 📸
# @raycast.packageName Window Manager

# Setup the focused window for screenshots, recordings, and screensharing.

try
    set focusedWindowJson to do shell script "aerospace list-windows --focused --json"
    set windowId to do shell script "printf %s " & quoted form of focusedWindowJson & " | jq -r '.[0].[\"window-id\"] // empty'"
    set appName to do shell script "printf %s " & quoted form of focusedWindowJson & " | jq -r '.[0].[\"app-name\"] // empty'"

    if windowId is "" or appName is "" then
        error "No focused window found. Please focus a window and try again."
    end if

    do shell script "aerospace layout floating --window-id " & windowId
    delay 0.1

    set targetWidth to 1512
    set targetHeight to 982

    tell application "Finder"
        set screenBounds to bounds of window of desktop
        set screenWidth to item 3 of screenBounds
        set screenHeight to item 4 of screenBounds
    end tell

    set centerX to (screenWidth - targetWidth) / 2
    set centerY to (screenHeight - targetHeight) / 2

    if centerX < 0 then
        set centerX to 0
    end if

    if centerY < 25 then
        set centerY to 25
    end if

    tell application "System Events"
        if not (exists process appName) then
            error appName & " is not running"
        end if

        tell process appName
            set frontmost to true
            tell front window
                set position to {centerX, centerY}
                set size to {targetWidth, targetHeight}
            end tell
        end tell
    end tell

on error errMsg
    return "Error: " & errMsg
end try
