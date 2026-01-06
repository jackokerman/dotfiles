#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title New Ghostty Window
# @raycast.mode silent
# @raycast.icon /Applications/Ghostty.app/Contents/Resources/Ghostty.icns
# @raycast.packageName Window Manager

try
    # Save current focused workspace before switching to Ghostty
    set currentWorkspace to do shell script "aerospace list-workspaces --focused"

    # Check if Ghostty is running
    tell application "System Events"
        set isGhosttyRunning to exists (processes where name is "Ghostty")
    end tell

    # Create new Ghostty window
    if not isGhosttyRunning then
        tell application "Ghostty" to activate
    else
        tell application "Ghostty" to activate
        tell application "System Events"
            tell process "Ghostty"
                keystroke "n" using {command down}
            end tell
        end tell
    end if

    # Wait for the new window to be created and focused
    delay 0.2

    # Move the new window to the original workspace
    do shell script "aerospace move-node-to-workspace " & currentWorkspace

on error errMsg
    return "Error: " & errMsg
end try

return
