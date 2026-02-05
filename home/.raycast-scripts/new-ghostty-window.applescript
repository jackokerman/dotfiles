#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title New Ghostty Window
# @raycast.mode silent
# @raycast.icon /Applications/Ghostty.app/Contents/Resources/Ghostty.icns
# @raycast.packageName Window Manager

# Creates a new Ghostty window on the current workspace.
# Works whether Ghostty is already running or not.

try
    set targetWorkspace to do shell script "aerospace list-workspaces --focused"

    tell application "System Events"
        set isRunning to exists (processes where name is "Ghostty")
    end tell

    if isRunning then
        # Use menu click to create window (avoids activating existing windows)
        tell application "System Events"
            tell process "Ghostty"
                click menu item "New Window" of menu "File" of menu bar 1
            end tell
        end tell
    else
        # Launch in background
        do shell script "open -gja Ghostty"
    end if

    delay 0.3

    # Move the new window (now focused) to target workspace
    set windowId to do shell script "aerospace list-windows --focused --format '%{window-id}'"
    do shell script "aerospace move-node-to-workspace --window-id " & windowId & " " & targetWorkspace & " && aerospace focus --window-id " & windowId

on error errMsg
    return "Error: " & errMsg
end try
